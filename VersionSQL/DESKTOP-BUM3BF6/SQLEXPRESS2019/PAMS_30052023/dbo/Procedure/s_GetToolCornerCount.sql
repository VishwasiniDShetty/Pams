/****** Object:  Procedure [dbo].[s_GetToolCornerCount]    Committed by VersionSQL https://www.versionsql.com ******/

/************************************************************************************************************
Procedure name s_GetToolCornerCount,written by Mrudula on 03-August-2007 for NR0012 . Used in SM_PerCornerInsert.rpt
mod 1 :-modified by Mrudula on 28-aug-2007 
mod 2:-by Mrudula on 13-sep-2007
mod 3:- By Mrudula on 14-nov-2007 to avoid suppression of columns in between the hours.
mod 4 :- ER0181 By Kusuma M.H on 28-May-2009.2) Modify all the procedures accordingly. Qualify machine wherever we are making use of component and opeartion no.
mod 5 :- ER0182 By Kusuma M.H on 28-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
************************************************************************************************************/
CREATE                procedure [dbo].[s_GetToolCornerCount]
	@StartDate datetime,
	@EndDate datetime,
	@ShiftID nvarchar(50),
	@PlantID Nvarchar(50)='',
	@MachineID nvarchar(50)= '',
	@ComponentID nvarchar(50)='',
	@Operationno as nvarchar(20)=''
AS
BEGIN
print @Startdate
---mod 5
---Replaced varchar with nvarchar to support unicode characters.
--DECLARE @StrSql as varchar(4000)
DECLARE @StrSql as nvarchar(4000)
---mod 5
DECLARE @StrMachine as nvarchar(200)
declare @strcomponentid nvarchar(255)
declare @stroperation nvarchar(255)
declare @strPlant as nvarchar(200)
Declare @strXoperation AS NVarchar(255)
Declare @strXcomponent AS NVarchar(255)
Declare @strXmachine AS NVarchar(255)
declare @Counter as datetime
declare @EndTime as datetime
declare @curstarttime as datetime
declare @curendtime as datetime
declare @Fstart as datetime
declare @lastend as datetime
declare @CountStart as datetime
declare @CountEnd as datetime
declare @curmach as nvarchar(50)
declare @Curcomp as nvarchar(50)
declare @curop as int
declare @curtool as nvarchar(50)
declare @PrevStart as datetime


select @strsql = ''
select @strcomponentid = ''
select @stroperation = ''
select @strmachine = ''
select @strXmachine = ''
select @strXcomponent = ''
select @strXoperation = ''
select @strPlant=''

if isnull(@PlantID,'') <> ''
begin
	---mod 5
--	select @strPlant = ' and ( PlantMachine.PlantID = ''' + @PlantID + ''' )'
	select @strPlant = ' and ( PlantMachine.PlantID = N''' + @PlantID + ''' )'
	---mod 5
end

if isnull(@machineid,'') <> ''
begin
	---mod 5
--	select @strmachine = ' and ( machineinformation.MachineID = ''' + @MachineID + ''')'
--	select @strXmachine = ' and ( EX.MachineID = ''' + @MachineID + ''')'
	select @strmachine = ' and ( machineinformation.MachineID = N''' + @MachineID + ''')'
	select @strXmachine = ' and ( EX.MachineID = N''' + @MachineID + ''')'
	---mod 5
end

if isnull(@componentid,'') <> ''
begin
	---mod 5
--	select @strcomponentid = ' AND ( componentinformation.componentid = ''' + @componentid + ''')'
--	select @strXcomponent = ' AND ( EX.componentid = ''' + @componentid + ''')'
	select @strcomponentid = ' AND ( componentinformation.componentid = N''' + @componentid + ''')'
	select @strXcomponent = ' AND ( EX.componentid = N''' + @componentid + ''')'
	---mod 5
end

if isnull(@operationno, '') <> ''
begin
	---mod 5
--	select @stroperation = ' AND ( componentoperationpricing.operationno = ' + @OperationNo +')'
--	select @strXoperation = ' AND ( EX.operationno = ' + @OperationNo +')'
	select @stroperation = ' AND ( componentoperationpricing.operationno = N''' + @OperationNo +''')'
	select @strXoperation = ' AND ( EX.operationno = N''' + @OperationNo +''')'
	---mod 5
end

select @counter=convert(datetime, cast(DATEPART(yyyy,@StartDate)as nvarchar(4))+'-'+cast(datepart(mm,@StartDate)as nvarchar(2))+'-'+cast(datepart(dd,@StartDate)as nvarchar(2)) +' 00:00:00.000')

CREATE TABLE #Exceptions
	(
		MachineID NVarChar(50),
		ComponentID Nvarchar(50),
		OperationNo Int,
		OperatorID Nvarchar(50),
		StartTime DateTime,
		EndTime DateTime,
		IdealCount Int,
		ActualCount Int,
		ExCount Int
	)
Create Table #ShiftTemp
	(
		PDate datetime,
		ShiftName nvarchar(20),
		FromTime datetime,
		ToTime Datetime
	)
create table #Toolcorner
	(
		Tdate datetime,
		ShiftID nvarchar(20),
		ShiftFrm datetime,
		ShiftTo datetime,
		Machine nvarchar(50),
		CompID nvarchar(50),
		OpnNO int,
		ToolNo nvarchar(50),
		ToolCount int default 0,
		Target int default 0,
		TchDwn nvarchar(50),
		change int default 0,
		ProdCOunt int default 0,
		CStart datetime default '1900-01-01 00:00:00.000',
		Cend datetime,
		Exc int default 0,
		totalcount int default null
	)
Create Table #toolRecord
(	
	Inserts nvarchar(50),
	MinStartTime DateTime,
	MaxEndTime DateTime,
	NoOfInserts bigint,
	Machid nvarchar(50),
	Compid nvarchar(150),
	Opnno int,
	ShiftStart datetime
)
CREATE TABLE #Header1
	(
		RowHeader NVarChar(100),
	)

create table #TempStart
	(
	   TempStart datetime,
	   TempEnd datetime,
	   CurrentShift datetime,
	   tempMach nvarchar(50),
	   TempComp nvarchar(50),
	   TempOpn int,
	   TempTchDwn nvarchar(50)
	)
--mod 3
create table #MCOTcomb
	(
		Machinetemp nvarchar(50),
		CompIDtemp nvarchar(50),
		OpnNOtemp int,
		TchDwntemp nvarchar(50),
		ToolNTemp nvarchar(50),
		TargetTem int default 0		
	)

--mod 3
insert into #ShiftTemp (PDate,ShiftName,FromTime,ToTime)
exec s_GetShiftTime @counter,@ShiftID

SELECT TOP 1 @counter=FromTime FROM #ShiftTemp ORDER BY FromTime ASC
SELECT TOP 1 @Fstart=FromTime FROM #ShiftTemp ORDER BY FromTime ASC
SELECT TOP 1 @EndTime=ToTime FROM #ShiftTemp ORDER BY FromTime DESC

--mod 3
---Get all the machine,component and operation from autodata for the selected shift
select @StrSql=''
select @StrSql='insert into #MCOTcomb(Machinetemp,CompIDtemp ,OpnNOtemp,TchDwntemp,ToolNTemp,TargetTem)
		select distinct machineinformation.machineid,componentinformation.componentid,
		componentoperationpricing.operationno,downcodeinformation.downid ,
		toolsequence.Toolno,toolsequence.targetcount
		from autodata inner join machineinformation on
		machineinformation.interfaceid=autodata.mc
		left outer join plantmachine on  machineinformation.machineid = plantmachine.machineid inner join componentinformation on
		autodata.comp=componentinformation.InterfaceID inner join componentoperationpricing on autodata.opn=componentoperationpricing.interfaceid and
		componentoperationpricing.componentid=componentinformation.componentid '
---mod 4
select @StrSql = @StrSql + ' and machineinformation.machineid = componentoperationpricing.machineid ' 
---mod 4
select @StrSql = @StrSql + ' inner join downcodeinformation on downcodeinformation.interfaceid=autodata.dcode left outer join toolsequence on 
		componentinformation.componentid=toolsequence.componentid and 
		toolsequence.operationno =componentoperationpricing.operationno
		and ToolSequence.downcode=downcodeinformation.downid
		WHERE (autodata.sttime >=''' + convert(nvarchar(20),@counter,120)+''')AND (autodata.sttime <= ''' + convert(nvarchar(20),@EndTime,120)+''' )  AND downcodeinformation.downid like ''TCH%'''
	SELECT @StrSql=@StrSql+@strmachine+@strcomponentid+@stroperation+@strPlant
	--print @StrSql
	exec (@StrSql)

--mod 3

--select * from #Toolcorner

----for mod 3
SELECT TOP 1 @counter=FromTime FROM #ShiftTemp ORDER BY FromTime ASC
SELECT TOP 1 @Fstart=FromTime FROM #ShiftTemp ORDER BY FromTime ASC
SELECT TOP 1 @EndTime=ToTime FROM #ShiftTemp ORDER BY FromTime DESC
--for mod 3

---select * from #ShiftTemp

while @counter<=@EndTime
BEGIN --WHILE
	SELECT @curstarttime=@counter
	SELECT @curendtime=DATEADD(Second,3600,@counter)
	if @curendtime >= @EndTime
	Begin
		set @curendtime = @EndTime
	end
	select @lastend = (select top 1 case when Cend <> ' ' then  Cend else @Fstart end    from #Toolcorner where change>0
		order by ShiftFrm desc)

	

	insert into #Toolcorner(Tdate,ShiftID,ShiftFrm,ShiftTo,Machine,CompID,
				OpnNO,ToolCount,ToolNo,Target,TchDwn,ProdCOunt,cstart,cend)
	select @StartDate,@ShiftID,@curstarttime,@curendtime,
		#MCOTcomb.Machinetemp,#MCOTcomb.CompIDtemp ,#MCOTcomb.OpnNOtemp,0,#MCOTcomb.ToolNTemp,#MCOTcomb.TargetTem,#MCOTcomb.TchDwntemp,0,' ',' '
		from  #MCOTcomb order by #MCOTcomb.Machinetemp asc,#MCOTcomb.CompIDtemp asc,#MCOTcomb.OpnNOtemp asc,#MCOTcomb.TchDwntemp asc


	--select @curstarttime
 	/*-- for  mod 3 
	SELECT @StrSql=''
	SELECT @StrSql='insert into #Toolcorner(Tdate,ShiftID,ShiftFrm,ShiftTo,Machine,CompID,
				OpnNO,ToolCount,ToolNo,Target,TchDwn,ProdCOunt,cstart,cend)
			select distinct ''' + convert(nvarchar(20),@StartDate,120)+''',''' +convert(nvarchar(20),@ShiftID)+ ''',
			 ''' + convert(nvarchar(20),@curstarttime,120)+''',
			''' + convert(nvarchar(20),@curendtime,120)+''',machineinformation.machineid,
			componentinformation.componentid,componentoperationpricing.operationno,0,0,0,'
			--case when downcodeinformation.downid<>'' '' and downcodeinformation.downid is not null and downcodeinformation.downid like ''TCH%'' then downcodeinformation.downid
	
			--else '' '' end ,0
	SELECT @StrSql= @StrSql+'downcodeinformation.downid,0
			,'' '','' ''
			from autodata inner join machineinformation on
			machineinformation.interfaceid=autodata.mc
			left outer join plantmachine on  machineinformation.machineid = plantmachine.machineid inner join componentinformation on
				 autodata.comp=componentinformation.InterfaceID inner join componentoperationpricing on autodata.opn=componentoperationpricing.interfaceid and
				 componentoperationpricing.componentid=componentinformation.componentid inner join 
				downcodeinformation on downcodeinformation.interfaceid=autodata.dcode 
			WHERE     (autodata.sttime >=''' + convert(nvarchar(20),@curstarttime,120)+''')AND (autodata.sttime <= ''' + convert(nvarchar(20),@curendtime,120)+''' ) '
	SELECT @StrSql=@StrSql+@strmachine+@strcomponentid+@stroperation+@strPlant
	---SELECT @StrSql=@StrSql+'group by machineinformation.machineid,componentinformation.componentid,componentoperationpricing.operationno,componentoperationpricing.SubOperations ' 
	print @StrSql
	exec (@StrSql) for mod 3*/

	
	
		
	--
	--select * from #Toolcorner
			
	/*SELECT @StrSql=''
	
	SELECT @StrSql='update  #Toolcorner set Target=T1.target,ToolNo=T1.Tool FROM 
			(select  toolsequence.targetcount target,toolsequence.Toolno as Tool,
			ToolSequence.downcode as dwnid,toolsequence.componentid as compn,toolsequence.operationno as opno from toolsequence
			) as T1 inner join #Toolcorner on T1.Compn=#Toolcorner.compid
			and T1.opno=#Toolcorner.opnno and T1.dwnid=#Toolcorner.TchDwn where #Toolcorner.ShiftFrm=''' + convert(nvarchar(20),@curstarttime,120)+'''
			and #Toolcorner.ShiftTo= ''' + convert(nvarchar(20),@curendtime,120)+''''
	exec (@StrSql)*/

	
	--- get the maximum number of changes for the tool for the current hour. and get the sttime and ndtime of the tool change record
	SELECT @StrSql=''
	SELECT @StrSql='Insert Into #toolRecord(ShiftStart,Inserts,MinStartTime,MaxEndTime,NoOfInserts,machid,compid,opnno)
			SELECT ''' + convert(nvarchar(20),@curstarttime,120)+''',downcodeinformation.downid ,
			max(autodata.sttime),
			max(autodata.ndtime),
			COUNT(downcodeinformation.downid),
			machineinformation.machineid,
			componentinformation.componentid,
			componentoperationpricing.operationno
			FROM
			autodata INNER JOIN downcodeinformation
			ON autodata.dcode = downcodeinformation.interfaceid
			INNER JOIN machineinformation
			ON autodata.mc = machineinformation.InterfaceID
			left outer join plantmachine on  machineinformation.machineid = plantmachine.machineid
			inner join componentinformation on
			autodata.comp=componentinformation.InterfaceID inner join componentoperationpricing on autodata.opn=componentoperationpricing.interfaceid and
			componentoperationpricing.componentid=componentinformation.componentid '
	---mod 4
	SELECT @StrSql = @StrSql + ' and machineinformation.machineid = componentoperationpricing.machineid '
	---mod 4
	SELECT @StrSql = @StrSql + ' WHERE (autodata.sttime >= ''' + convert(nvarchar(20),@curstarttime,120)+''')AND (autodata.sttime <= ''' + convert(nvarchar(20),@curendtime,120)+''' )
			AND (downcodeinformation.downid LIKE ''TCH%'') AND (autodata.datatype = 2)'
	SELECT @StrSql=@StrSql+@strmachine+@strcomponentid+@stroperation+@strPlant
	SELECT @StrSql=@StrSql+ ' Group by downcodeinformation.downid,machineinformation.machineid,componentinformation.componentid,componentoperationpricing.operationno'
--	print @StrSql
	exec (@StrSql)
	
	
	SELECT @StrSql=''

	--get the last tool change's end time in #TempStart for the MCOT combination
	
	insert into #TempStart ( TempStart,CurrentShift,tempMach, TempComp, TempOpn , TempTchDwn)
	select distinct case when max(Cend) <> '1900-01-01 00:00:00.000' then max(cend) end 
	       ,@curstarttime,Machine,compid,opnno,TchDwn from #Toolcorner  where ShiftFrm<=@PrevStart
		group by #Toolcorner.Machine,#Toolcorner.compid,#Toolcorner.opnno,#Toolcorner.TchDwn

		
	---UPdate the starttime for the tool change record in #Toolcorner
	---set its value to end time of the last tool change for the same MCO combination
	Update #Toolcorner set CStart=T1.Cntnd from (Select TempStart as Cntnd,
	CurrentShift as shft,tempMach as  mach, TempComp as Cmp, TempOpn as operation
	 , TempTchDwn as Dwn from #TempStart
	) as T1 inner join #Toolcorner  on T1.mach=#Toolcorner.machine and T1.cmp=#Toolcorner.compid
	and T1.operation=#Toolcorner.opnno and T1.Dwn=#Toolcorner.TchDwn 
	and T1.Shft=#Toolcorner.ShiftFrm where #Toolcorner.ShiftFrm=@curstarttime
	
	
	---update #Toolcorner for number of changes in an hour for MCOT combination
	SELECT @StrSql=''
	SELECT @StrSql='Update #Toolcorner set change=T1.cont from (select ShiftStart as shiftst,NoOfInserts as cont,machid,compid,opnno,Inserts from
			#toolRecord )as T1 inner join #Toolcorner on T1.machid=#Toolcorner.machine and T1.compid=#Toolcorner.compid
				and T1.opnno=#Toolcorner.opnno and T1.Inserts=#Toolcorner.TchDwn and T1.shiftst=#Toolcorner.ShiftFrm  
			where #Toolcorner.ShiftFrm=''' + convert(nvarchar(20),@curstarttime,120)+ ''' '

		exec(@StrSql)
		
		 SELECT @StrSql=''
	/*SELECT @StrSql='Update #Toolcorner set Cend=T1.Cntst from (select ShiftStart as shiftst,MaxEndTime as Cntst ,machid,compid,opnno,Inserts from
	#toolRecord  )as T1 inner join #Toolcorner on T1.machid=#Toolcorner.machine and T1.compid=#Toolcorner.compid
	and T1.opnno=#Toolcorner.opnno and T1.Inserts=#Toolcorner.TchDwn and T1.shiftst=#Toolcorner.ShiftFrm
	 '*/
	--- update end time to Starttime of the tool change
	SELECT @StrSql='Update #Toolcorner set Cend=T1.Cntst from (select ShiftStart as shiftst,MinStartTime as Cntst ,machid,compid,opnno,Inserts from
			#toolRecord  )as T1 inner join #Toolcorner on T1.machid=#Toolcorner.machine and T1.compid=#Toolcorner.compid
			and T1.opnno=#Toolcorner.opnno and T1.Inserts=#Toolcorner.TchDwn and T1.shiftst=#Toolcorner.ShiftFrm
			'
		exec(@StrSql)
	--- if it is a first tool change in the shift set the start time to the shift start time
		update #Toolcorner set Cstart=@Fstart where (Cstart='1900-01-01 00:00:00.000' or Cstart is null)  and change>0
			and ShiftFrm=@curstarttime
	
	
		
	SELECT @StrSql=''
	
	
	delete from #TempStart
	select @PrevStart=@counter
	SELECT @counter = DATEADD(Second,3600,@counter)
	--select * from #Toolcorner
END --WHILE



DECLARE @Curopn int 
DECLARE @CurTch nvarchar(50)
DECLARE @shiftvalue datetime 
DECLARE @ChangeVal int 


 Declare RptShiftCursor CURSOR FOR
	SELECT 	#Toolcorner.MACHINE,
		#Toolcorner.compid,
		#Toolcorner.opnno,
		#Toolcorner.tchdwn,
		#Toolcorner.ShiftFrm,
		#Toolcorner.Cstart,
		#Toolcorner.Cend,
		#Toolcorner.change
		
	from 	#Toolcorner
	order by ShiftFrm,Cstart
	OPEN RptShiftCursor
	FETCH NEXT FROM RptShiftCursor INTO @CurMach,@Curcomp,@Curopn,@CurTch,@shiftvalue, @Countstart, @Countend,@ChangeVal
	 WHILE (@@fetch_status = 0)
	  BEGIN

		if @ChangeVal>0  
		begin
		
			select @StrSql=''
			SELECT @StrSql='UPDATE #Toolcorner SET ToolCount=T2.counttool from(
				select  T1.Shft as shift1,''' +convert(nvarchar(50),@CurTch)+ ''' as tool,T1.mach as machid,T1.compn as compid,
				T1.opno as opid,T1.Count1 as Counttool from #Toolcorner inner join(
				select  ''' + convert(nvarchar(20),@shiftvalue,120)+''' as Shft,
				''' + convert(nvarchar(20),@CountStart,120)+''' as ToolSt,
				''' + convert(nvarchar(20),@CountEnd,120)+''' as ToolEnd,
				machineinformation.machineid as mach,componentinformation.componentid as 
				compn ,componentoperationpricing.operationno as opno,
				CAST(CEILING(CAST(sum(autodata.partscount)AS Float)/ISNULL(componentoperationpricing.SubOperations,1)) AS INTEGER) 
				as count1
				from autodata inner join machineinformation on
				machineinformation.interfaceid=autodata.mc  inner join componentinformation on
					 autodata.comp=componentinformation.InterfaceID inner join componentoperationpricing on autodata.opn=componentoperationpricing.interfaceid and
					 componentoperationpricing.componentid=componentinformation.componentid '
			---mod 4 
			SELECT @StrSql = @StrSql + ' and machineinformation.machineid = componentoperationpricing.machineid '		
			---mod 4
			SELECT @StrSql = @StrSql + ' WHERE (autodata.ndtime > ''' + convert(nvarchar(20),@CountStart,120)+''')AND (autodata.ndtime <= ''' + convert(nvarchar(20),@CountEnd,120)+''' ) '
			SELECT @StrSql=@StrSql+ 'and machineinformation.machineid=''' + convert(nvarchar(50),@CurMach)+ ''' 
					and componentinformation.componentid=''' + Convert(nvarchar(50),@Curcomp)+ ''' 
					and componentoperationpricing.operationno=''' +convert(nvarchar(20),@Curopn)+''' '
			SELECT @StrSql=@StrSql+'group by machineinformation.machineid,componentinformation.componentid,componentoperationpricing.operationno,componentoperationpricing.SubOperations ) as T1
				on #Toolcorner.machine= T1.mach and  #Toolcorner.compid=T1.compn and  #Toolcorner.opnno=t1.opno where #Toolcorner.ShiftFrm=''' + convert(nvarchar(20),@shiftvalue,120)+''' and change >0
				) as T2
				inner join #Toolcorner on T2.machid=#Toolcorner.machine and  T2.compid=#Toolcorner.compid and  t2.opid=#Toolcorner.opnno and T2.shift1=#Toolcorner.ShiftFrm
				and T2.Tool=#Toolcorner.TchDwn where #Toolcorner.machine=''' + convert(nvarchar(50),@CurMach)+ ''' and 
				#Toolcorner.compid=''' + Convert(nvarchar(50),@Curcomp)+ ''' and 
				#Toolcorner.opnno=''' +convert(nvarchar(20),@Curopn)+''' and 
				#Toolcorner.TchDwn=''' +convert(nvarchar(50),@CurTch)+ ''' and 
				#Toolcorner.ShiftFrm=''' + convert(nvarchar(20),@shiftvalue,120)+''' and 
				#Toolcorner.Cstart=''' + convert(nvarchar(20),@CountStart,120)+''' and 
				#Toolcorner.Cend=''' + convert(nvarchar(20),@CountEnd,120)+'''
				'
--			print @StrSql
			exec(@StrSql)
	
	
	
			select @StrSql=''
			SELECT @StrSql = 'INSERT INTO #Exceptions(MachineID ,ComponentID,OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,ExCount )
				SELECT Ex.MachineID ,Ex.ComponentID,Ex.OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,0
				From ProductionCountException Ex
				Inner Join MachineInformation M ON Ex.MachineID=M.MachineID
				Inner Join ComponentInformation C ON Ex.ComponentID=C.ComponentID
				Inner Join Componentoperationpricing O ON Ex.OperationNo=O.OperationNo AND C.ComponentID=O.ComponentID '
			---mod 4
			SELECT @StrSql = @StrSql + ' and M.machineid = O.machineid '
			---mod 4
			SELECT @StrSql = @StrSql + ' WHERE  M.MultiSpindleFlag=1 AND
				((Ex.StartTime>=  ''' + convert(nvarchar(20),@CountStart,120)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@CountEnd,120)+''' )
				OR (Ex.StartTime< ''' + convert(nvarchar(20),@CountStart,120)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@CountStart,120)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@CountEnd,120)+''')
				OR(Ex.StartTime>= ''' + convert(nvarchar(20),@CountStart,120)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@CountEnd,120)+''' AND Ex.StartTime< ''' + convert(nvarchar(20),@CountEnd,120)+''')
				OR(Ex.StartTime< ''' + convert(nvarchar(20),@CountStart,120)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@CountEnd,120)+''' ))'
			SELECT @StrSql = @StrSql + @StrxMachine + @strXcomponent + @strXoperation
			Exec (@strsql)
			SELECT @strsql=''
			
			
			IF (SELECT Count(*) from #Exceptions) <> 0
			BEGIN
				UPDATE #Exceptions SET StartTime=@CountStart WHERE (StartTime<@CountStart)AND EndTime>@CountStart
				UPDATE #Exceptions SET EndTime=@CountEnd WHERE (EndTime>@CountEnd AND StartTime<@CountEnd )
				
				SELECT @StrSql=''
				Select @StrSql = 'UPDATE #Exceptions SET ExCount=ISNULL(T2.Comp,0) From
				(
					SELECT T1.MachineID AS MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime AS StartTime,T1.EndTime AS EndTime,
					SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp
				 	From (
						select MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,comp,opn,Tt1.StartTime,Tt1.EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from autodata
						Inner Join MachineInformation   ON autodata.MC=MachineInformation.InterfaceID
						Inner Join ComponentInformation   ON autodata.Comp = ComponentInformation.InterfaceID
						Inner Join ComponentOperationPricing  on autodata.Opn=ComponentOperationPricing.InterfaceID And ComponentInformation.ComponentID=ComponentOperationPricing.ComponentID '
				---mod 4
				SELECT @StrSql = @StrSql + ' and machineinformation.machineid = O.machineid '
				---mod 4
				SELECT @StrSql = @StrSql + ' Inner Join (
							Select MachineID,ComponentID,OperationNo,StartTime,EndTime From #Exceptions
							)AS Tt1 ON Tt1.MachineID=MachineInformation.MachineID AND Tt1.ComponentID = ComponentInformation.ComponentID AND Tt1.OperationNo= ComponentOperationPricing.OperationNo
						Where (autodata.sttime>=Tt1.StartTime) AND (autodata.ndtime<=Tt1.EndTime) and (autodata.datatype=1) '
				Select @StrSql = @StrSql+ @strmachine + @strcomponentID + @stroperation
				Select @StrSql = @StrSql+' Group by MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,Tt1.StartTime,Tt1.EndTime,comp,opn
					) as T1
				   	Inner join componentinformation C on T1.Comp=C.interfaceid
				   	Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid '
				---mod 4
				Select @StrSql = @StrSql+' Inner join machineinformation M on T1.machineid = M.machineid '
				---mod 4
				Select @StrSql = @StrSql+' GROUP BY T1.MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime,t1.EndTime
				)AS T2
				WHERE  #Exceptions.StartTime=T2.StartTime AND #Exceptions.EndTime=T2.EndTime
				AND #Exceptions.MachineID=T2.MachineID AND #Exceptions.ComponentID = T2.ComponentID AND #Exceptions.OperationNo=T2.OperationNo'
				Exec(@StrSql)
				UPDATE #Exceptions SET ExCount=ExCount-((ExCount * ActualCount)/ISNULL(IdealCount,0))
				
				UPDATE #Toolcorner SET Exc=ISNULL(T1.Xcount,0)
				From(
					SELECT Min(StartTime)StartTime,Max(EndTime)EndTime,MachineID,ComponentID,OperationNo,SUM(ExCount)Xcount
					FROM #Exceptions
						GROUP BY MachineID,ComponentID,OperationNo
				)T1 Inner Join #Toolcorner ON
				T1.MachineID=#Toolcorner.machine AND T1.ComponentID=#Toolcorner.compid
				AND T1.OperationNo=#Toolcorner.opnno AND #Toolcorner.ShiftFrm=@shiftvalue and 
				#Toolcorner.Cstart= @Countstart and  #Toolcorner.Cend =@Countend 
			
			END

		end
		
		DELETE FROM #Exceptions

		FETCH NEXT FROM RptShiftCursor INTO @CurMach,@Curcomp,@Curopn,@CurTch,@shiftvalue, @Countstart, @Countend,@ChangeVal

	
		
	  end --wHILE
CLOSE RptShiftCursor
DEALLOCATE RptShiftCursor

Insert Into #Header1 Values('Hours')
Insert Into #Header1 Values('Total')
update #Toolcorner set ToolCount=Toolcount-Exc where change>0
update #Toolcorner set totalcount=T1.Count1 from (select machine as mach,compid as compn,opnno as opno,sum(ToolCount) as count1,
					TchDwn as Tdwn  from #Toolcorner where change>0 group by machine,compid,opnno,TchDwn) as T1 left outer join #Toolcorner
					on T1.mach=#Toolcorner.machine AND T1.compn=#Toolcorner.compid AND T1.opno=#Toolcorner.opnno 
					and T1.Tdwn=#Toolcorner.TchDwn
					where change>0
--update #Toolcorner set change=2 where change>0
--select * from #toolRecord
SELECT	cast(cast(DateName(month,T.Tdate)as nvarchar(3))+'-'+cast(datepart(dd,T.Tdate)as nvarchar(2))+'-'+ cast(T.ShiftID as nvarchar(20))+' '+CASE WHEN DATALENGTH(Cast(datepart(hh,T.ShiftFrm)as nvarchar))=2 THEN '0'+cast(datepart(hh,T.ShiftFrm)as nvarchar(2)) ELSE cast(datepart(hh,T.ShiftFrm)as nvarchar(2))END +':'+CASE WHEN DATALENGTH(Cast(datepart(n,T.ShiftFrm)as nvarchar))=2 THEN '0'+cast(datepart(n,T.ShiftFrm)as nvarchar(2)) ELSE cast(datepart(n,T.ShiftFrm)as nvarchar(2))END +' To '+CASE WHEN DATALENGTH(Cast(datepart(hh,T.ShiftTO)as nvarchar))=2 THEN '0'+cast(datepart(hh,T.ShiftTO)as nvarchar(2)) ELSE cast(datepart(hh,T.ShiftTO)as nvarchar(2))END+':'+CASE WHEN DATALENGTH(Cast(datepart(n,T.ShiftTO)as nvarchar))=2 THEN '0'+cast(datepart(n,T.ShiftTO)as nvarchar(2)) ELSE cast(datepart(n,T.ShiftTO)as nvarchar(2))END  as nvarchar(50)) as Day,
		Cast(CAST(YEAR(T.ShiftFrm)as nvarchar(4))+case when datalength(CAST(Month(T.ShiftFrm)as nvarchar(2)))=2 then '0'+CAST(Month(T.ShiftFrm)as nvarchar(2)) else CAST(Month(T.ShiftFrm)as nvarchar(2)) end+case when datalength(CAST(Day(T.ShiftFrm)as nvarchar(2)))=2 then '0'+CAST(Day(T.ShiftFrm)as nvarchar(2)) else CAST(Day(T.ShiftFrm)as nvarchar(2)) end +CASE WHEN DATALENGTH(Cast(datepart(hh,T.ShiftFrm)as nvarchar))=2 THEN '0'+cast(datepart(hh,T.ShiftFrm)as nvarchar(2)) ELSE cast(datepart(hh,T.ShiftFrm)as nvarchar(2))END +':'+CASE WHEN DATALENGTH(Cast(datepart(n,T.ShiftFrm)as nvarchar))=2 THEN '0'+cast(datepart(n,T.ShiftFrm)as nvarchar(2)) ELSE cast(datepart(n,T.ShiftFrm)as nvarchar(2))END+' To '+CASE WHEN DATALENGTH(Cast(datepart(hh,T.ShiftTO)as nvarchar))=2 THEN '0'+cast(datepart(hh,T.ShiftTO)as nvarchar(2)) ELSE cast(datepart(hh,T.ShiftTO)as nvarchar(2))END+':'+CASE WHEN DATALENGTH(Cast(datepart(n,T.ShiftTO)as nvarchar))=2 THEN '0'+cast(datepart(n,T.ShiftTO)as nvarchar(2)) ELSE cast(datepart(n,T.ShiftTO)as nvarchar(2))END  as NVarchar(50)) as Shift,
		T.ShiftFrm,
		T.ShiftTO,
		T.Cstart,
		T.Cend,
		T.Machine as MachineID,	
		T.CompID AS CompID,
		cast(T.Opnno as nvarchar(5))  AS opnno,
		T.ToolNo as tool,
		case when T.change>0 then toolsequence.ToolDEscription end as ToolDesc,
		T.ToolCount ,
		T.Target ,
		T.TchDwn ,
		T.change,
		case RowHeader
			WHEN 'TOTAL'   THEN 'TOTAL'
			else
			Cast(CAST(YEAR(T.ShiftFrm)as nvarchar(4))+case when datalength(CAST(Month(T.ShiftFrm)as nvarchar(2)))=2 then '0'+CAST(Month(T.ShiftFrm)as nvarchar(2)) else CAST(Month(T.ShiftFrm)as nvarchar(2)) end+case when datalength(CAST(Day(T.ShiftFrm)as nvarchar(2)))=2 then '0'+CAST(Day(T.ShiftFrm)as nvarchar(2)) else CAST(Day(T.ShiftFrm)as nvarchar(2)) end +CASE WHEN DATALENGTH(Cast(datepart(hh,T.ShiftFrm)as nvarchar))=2 THEN '0'+cast(datepart(hh,T.ShiftFrm)as nvarchar(2)) ELSE cast(datepart(hh,T.ShiftFrm)as nvarchar(2))END +':'+CASE WHEN DATALENGTH(Cast(datepart(n,T.ShiftFrm)as nvarchar))=2 THEN '0'+cast(datepart(n,T.ShiftFrm)as nvarchar(2)) ELSE cast(datepart(n,T.ShiftFrm)as nvarchar(2))END+' To '+CASE WHEN DATALENGTH(Cast(datepart(hh,T.ShiftTO)as nvarchar))=2 THEN '0'+cast(datepart(hh,T.ShiftTO)as nvarchar(2)) ELSE cast(datepart(hh,T.ShiftTO)as nvarchar(2))END+':'+CASE WHEN DATALENGTH(Cast(datepart(n,T.ShiftTO)as nvarchar))=2 THEN '0'+cast(datepart(n,T.ShiftTO)as nvarchar(2)) ELSE cast(datepart(n,T.ShiftTO)as nvarchar(2))END  as NVarchar(50))  end as RowHeader,
		case RowHeader
			WHEN 'TOTAL'   THEn cast(T.totalcount as nvarchar(5))
			else
				case when T.change>1 and ToolCount >0 then cast(T.ToolCount as nvarchar(5))+'('+cast(T.Change as nvarchar(2))+')'
				when change=1 and ToolCount>0 then  cast(T.ToolCount as nvarchar(5))
				end
			end as Rowvalue
		--case when T.change>1 and ToolCount >0 then cast(T.ToolCount as nvarchar(5))+'('+cast(T.Change as nvarchar(2))+')'
			--when change=1 and ToolCount>0 then  cast(T.ToolCount as nvarchar(5))
			--end as Cornercount
		 from #Toolcorner T CROSS JOIN #Header1
		left outer join toolsequence on toolsequence.componentid=T.compId and
		toolsequence.Operationno=T.opnno and  toolsequence.toolNo=T.ToolNo   order by RowHeader asc
		
		
	
--select * from #Toolcorner
--select * from #toolRecord
END ---for procedure
	
