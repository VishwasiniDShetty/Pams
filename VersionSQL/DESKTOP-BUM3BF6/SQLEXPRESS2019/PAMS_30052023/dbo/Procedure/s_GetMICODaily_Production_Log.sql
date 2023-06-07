/****** Object:  Procedure [dbo].[s_GetMICODaily_Production_Log]    Committed by VersionSQL https://www.versionsql.com ******/

/*******************************************************************************************
Procedure created by Mrudula Rao To Get Daily ProductionLog
mod 1 :- ER0181 By Kusuma M.H on 14-May-2009.2) Modify all the procedures accordingly. Qualify machine wherever we are making use of component and opeartion no.
mod 2 :- ER0182 By Kusuma M.H on 14-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
mod 3 :-By Mrudula M. Rao on 04-feb-2009.ER0210 Introduce PDT on 5150. 1) Handle PDT at Machine Level.
			2) Handle interaction between PDT and Mangement Loss. Also handle interaction InCycleDown And PDT.
			3) Improve the performance.
			4) Handle intearction between ICD and PDT for type 1 production record for the selected time period.
mod 4 :- Optimize the procedure.
DR0251 - KarthikR - 26\Aug\2010 :: To handle error Incorrect syntax near ')'
								   @strXcomponent has been changed from nvarchar(50) to nvarchar(100)
s_GetMICODaily_Production_Log '2010-08-02','MLC PUMA 400 L','DC 5750-100','1','','pcount'
*****************************************************************************************/
CREATE                  Procedure [dbo].[s_GetMICODaily_Production_Log]
	@StartDate Datetime,
	@MachineID nvarchar(50),
	@ComponentID  nvarchar(50) = '',
	@OperationNo  nvarchar(50) = '',
	@PlantID nvarchar(50)='',
	@RepType nvarchar(50)
	--@RepTypeDown nvarchar(50)
AS
BEGIN
declare @strsql nvarchar(4000)
declare @strmachine nvarchar(255)
declare @stroperation nvarchar(255)
declare @strcomponent nvarchar(255)
declare @strPlantID nvarchar(255)
declare @Targetsource nvarchar(50)
declare @stroperation1 nvarchar(255)
declare @strcomponent1 nvarchar(255)
Create table #ShiftDetails(
	PDate smalldatetime,
	shiftName nvarchar(20),
	shiftStart datetime,
	shiftEnd datetime
)
CREATE TABLE #ProductionLog
	(
		PDate datetime,
		ShiftName nvarchar(20),
		FromTime datetime,
		ToTime Datetime,
		CompID Nvarchar(50),
		OpnID Nvarchar(20),
		CompCount  int default 0 ,
		Machine nvarchar(50),
		SumComp int,
		TrgtCt int Default 0,
		SumIdeal int default 0,
		SumActual int default 0
		 --mod 3
		 ,ShiftStart datetime,
		 ShiftEnd datetime
		---mod 3
		
		
	)
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
		ExCount Int,
		---mod 3
		HourStart datetime,
		HourEnd datetime
		---mod 3
	)
---mod 3: table to store Planned down times
CREATE TABLE #PlannedDownTimesCount
	(
		SlNo int not null identity(1,1),
		Starttime datetime,
		EndTime datetime,
		Machine nvarchar(50),
		DownReason nvarchar(50),
		PShiftName nvarchar(50),
		PHourStart datetime,
		PHourEnd datetime
	)
---mod 3
create table #hourdefini
	(start datetime,
	 hrend datetime,
	 Shift nvarchar(50)
	 --mod 3
	 ,ShiftStart datetime,
	 ShiftEnd datetime
	---mod 3
	)
--mod 3
/*create table #DownTimeData
(
StartTime datetime,
EndTime datetime,
machineid nvarchar(50),
McInterfaceid nvarchar(50),
downid nvarchar(50),
DownDescription nvarchar(50),
downtime float,
TotalDown float
--StdSetup float,
--SetupEff float
)*/
/*declare @TimeFormat as nvarchar(25)
SELECT @TimeFormat = ''
SELECT @TimeFormat = (SELECT  ValueInText  FROM CockpitDefaults WHERE Parameter = 'TimeFormat')
if (ISNULL(@TimeFormat,'')) = ''
BEGIN
	SELECT @TimeFormat = 'ss'
END*/
select @Targetsource=ValueInText from Shopdefaults where Parameter='TargetFrom'
insert into #ShiftDetails(Pdate,shiftName,shiftStart,shiftEnd)
	EXEC s_GetShiftTime @StartDate
Declare @strXmachine AS NvarChar(50)
--Declare @strXcomponent AS NvarChar(50) --DR0251 - KarthikR - 26\Aug\2010
Declare @strXcomponent AS NvarChar(100)
Declare @strXoperation AS NvarChar(50)
SELECT @strXmachine=''
SELECT @strXcomponent=''
SELECT @strXoperation=''
If isnull(@MachineID,'') <> ''
BEGIN
	---mod 2
--	SELECT @strXmachine = ' AND ( EX.machineid = ''' + @MachineID+ ''')'
	SELECT @strXmachine = ' AND ( EX.machineid = N''' + @MachineID+ ''')'
	---mod 2
END
	If isnull(@ComponentID, '') <> ''
BEGIN
	---mod 2
--	SELECT @strXcomponent = ' AND ( EX.componentid = ''' + @ComponentID+ ''')'
	SELECT @strXcomponent = ' AND ( EX.componentid = N''' + @ComponentID+ ''')'
	---mod 2
END
	If isnull(@OperationNo, '') <> ''
BEGIN
	---mod 2
--	SELECT @strXoperation = ' AND ( EX.Operationno = ''' + @OperationNo+ ''')'
	SELECT @strXoperation = ' AND ( EX.Operationno = N''' + @OperationNo+ ''')'
	---mod 2
END
SET @strPlantID = ''
set @strmachine=''
set @strcomponent=''
set @stroperation=''
If isnull(@MachineID,'') <> ''
BEGIN
	---mod 2
--	SELECT @strmachine = ' AND ( M.machineid = ''' + @MachineID+ ''')'
	SELECT @strmachine = ' AND ( M.machineid = N''' + @MachineID+ ''')'
	---mod 2
END
If isnull(@ComponentID, '') <> ''
BEGIN
	---mod 2
--	SELECT @strcomponent = ' AND ( C.componentid = ''' + @ComponentID+ ''')'
	SELECT @strcomponent = ' AND ( C.componentid = N''' + @ComponentID+ ''')'
	---mod 2
END
If isnull(@Operationno, '') <> ''
BEGIN
	---mod 2
--	SELECT @stroperation = ' AND ( O.Operationno = ''' + @OperationNo + ''')'
	SELECT @stroperation = ' AND ( O.Operationno = N''' + @OperationNo + ''')'
	---mod 2
END
if isnull(@PlantID,'') <> ''
BEGIN
	---mod 2
--	SELECT @strPlantID = ' AND ( P.PlantID = ''' + @PlantID+ ''')'
	SELECT @strPlantID = ' AND ( P.PlantID = N''' + @PlantID+ ''')'
	---mod 2
END
If isnull(@ComponentID, '') <> ''
BEGIN
	---mod 2
--	SELECT @strcomponent1 = ' AND ( component = ''' + @ComponentID+ ''')'
	SELECT @strcomponent1 = ' AND ( component = N''' + @ComponentID+ ''')'
	---mod 2
END
If isnull(@Operationno, '') <> ''
BEGIN
	---mod 2
--	SELECT @stroperation1 = ' AND ( Operation  = ''' + @OperationNo + ''')'
	SELECT @stroperation1 = ' AND ( Operation  = N''' + @OperationNo + ''')'
	---mod 2
END
Declare TmplogCursor1 Cursor For SELECT Pdate,shiftName,shiftStart,shiftEnd  from #ShiftDetails order by ShiftStart ASc
Declare @CurShift as nvarchar(50)
Declare @CurStart as datetime
Declare @CurEnd as datetime
Declare @PrevShift as nvarchar(50)
Declare @Counter as datetime
Declare @curstarttime as datetime
Declare @curendtime as datetime
Declare @Prevend as datetime
Declare @PrevStart as datetime
Declare @DiffTime as int
Declare @CurDate as datetime
declare @strShift nvarchar(200)
declare @TrSql nvarchar(2000)
Declare @strmachine2 nvarchar(255)
Declare @stroperation2 nvarchar(255)
Declare @strcomponent2 nvarchar(255)
Declare @CumIdeal as int
Declare @Cumactual as int
select @PrevStart=Getdate()
select @Prevend=@PrevStart
OPEN TmplogCursor1
FETCH NEXT FROM TmplogCursor1 INTO @CurDate,@CurShift,@CurStart,@CurEnd
WHILE @@FETCH_STATUS = 0
	BEGIN	
		--Print (@CurShift) print(@CurStart) print(@CurEnd)
		SELECT @strShift=''
		if isnull(@CurShift,'')<>''
		BEGIN
			---mod 2
--			SELECT @strShift=' AND (shift=''' +@CurShift+ ''' ) '
			SELECT @strShift=' AND (shift=N''' +@CurShift+ ''' ) '
			---mod 2
		END
		
		select @CumIdeal=0
		select @Cumactual=0
		select @Counter=@CurStart
		While (@Counter<@CurEnd)
		BEGIN
			SELECT @curstarttime=@counter
			if isnull(@Prevend,'')<>'' and isnull(@PrevStart,'')<>''
				Begin
				    if datediff(second,@PrevStart,@Prevend)<3600
				    Begin
					select @DiffTime=datediff(second,@PrevStart,@Prevend)
					Print (@DiffTime)
					select @curendtime=Dateadd(second,3600+(3600-@DiffTime),@counter)
				    END
				    Else
				    BEGIN
					 SELECT @curendtime=DATEADD(Second,3600,@counter)
				    END
				end
			--SELECT @curendtime=DATEADD(Second,3600,@counter)
			if @curendtime >= @CurEnd
			Begin
				set @curendtime = @CurEnd
			end
			
			if datediff(second,@curstarttime,@curendtime)>3600
			BEGIN
				select @curendtime=dateadd(second,-((datediff(second,@curstarttime,@curendtime))-3600),@curendtime)
			END
			---select @curstarttime as cstart,@curendtime as  Cend,@CurShift as  Cshift,@PrevStart as PShart,@Prevend as Pend
			insert into #hourdefini select @curstarttime,@curendtime,@CurShift,@CurStart,@CurEnd
	
			
			----------------------------------------------------------------------------------------------------
		---Commented for mod 4 : optimization Starts from here
		/*if isnull(@RepType,'')='Pcount'
		BEGIN
			
			SELECT @strsql=''
			--SELECT @strsql='INSERT INTO #ProductionLog(PDate,ShiftName,FromTime,ToTime,Machine,CompID,OpnID,CompCount)'
			SELECT @strsql='INSERT INTO #ProductionLog(PDate,ShiftName,FromTime,ToTime,Machine,CompID,OpnID)'
			SELECT @strsql = @strsql + ' SELECT  ''' +convert(nvarchar(20),@CurDate,20)+''',''' +convert(nvarchar(50),@CurShift)+''','''+convert(nvarchar(20),@curstarttime,20)+''','''+convert(nvarchar(20),@curendtime,20)+''',M.MachineID,C.componentid,O.operationno'
			--SELECT @strsql = @strsql +' CAST(CEILING(CAST(sum(A.partscount)AS Float)/ISNULL(O.SubOperations,1)) AS INTEGER)  '			
			SELECT @strsql = @strsql +' from autodata A '
			SELECT @strsql = @strsql +' inner join ComponentInformation C on A.comp=C.interfaceid '
			SELECT @strsql = @strsql +' inner join ComponentOperationPricing O on A.opn=O.interfaceid and C.componentid=O.componentid '
			SELECT @strsql = @strsql +' INNER JOIN machineinformation M on A.mc=M.interfaceid '
			SELECT @strsql = @strsql +' left OUTER Join PlantMachine P on m.machineid = P.machineid '
			--SELECT @strsql = @strsql +' WHERE A.DataType=1 And A.ndtime>'''+convert(nvarchar(20),@curstarttime)+'''  and A.Ndtime<='''+ convert(nvarchar(20),@curendtime)+''' '
			---mod 2
--			SELECT @strsql = @strsql + 'Where  M.machineid = ''' + @MachineID+ ''' '
			SELECT @strsql = @strsql + 'Where  M.machineid = N''' + @MachineID+ ''' '
			---mod 2
			SELECT @strsql = @strsql + @strcomponent + @stroperation + @strPlantID
			SELECT @strsql = @strsql + ' GROUP BY M.MachineID,C.componentid,O.operationno,O.SubOperations'
			print @strsql
			EXEC (@strsql)
			SELECT @strsql=''
			SELECT @strsql = 'update #ProductionLog set compCount=ISNULL(CompCount,0)+isnull(t1.Prdn,0) From
				(select M.MachineID as mach ,C.componentid as compn,O.operationno oprn,CAST(CEILING(CAST(sum(A.partscount)AS Float)/ISNULL(O.SubOperations,1)) AS INTEGER) as prdn
				 from autodata A inner join ComponentInformation C on A.comp=C.interfaceid
				inner join ComponentOperationPricing O on A.opn=O.interfaceid and C.componentid=O.componentid '
			SELECT @strsql = @strsql + 'INNER JOIN machineinformation M on A.mc=M.interfaceid  left OUTER Join PlantMachine P on m.machineid = P.machineid '
			---mod 1
			SELECT @strsql = @strsql + ' and M.machineid=O.machineid'
			---mod 1
			SELECT @strsql = @strsql +' WHERE A.DataType=1 And A.ndtime>'''+convert(nvarchar(20),@curstarttime,20)+'''  and A.Ndtime<='''+ convert(nvarchar(20),@curendtime,20)+''' '
			SELECT @strsql = @strsql +@strmachine+ @strcomponent + @stroperation + @strPlantID
			SELECT @strsql = @strsql + ' GROUP BY M.MachineID,C.componentid,O.operationno,O.SubOperations )'
			SELECT @strsql = @strsql + ' as T1 inner join #ProductionLog on  T1.mach=#ProductionLog.Machine and T1.compn=#ProductionLog.CompID and T1.oprn=#ProductionLog.OpnID '
			SELECT @strsql = @strsql + ' Where #ProductionLog.FromTime='''+convert(nvarchar(20),@curstarttime,20)+''' and #ProductionLog.ToTime='''+convert(nvarchar(20),@curendtime,20)+''' '
			EXEC (@strsql)
			SELECT @strsql=''
			SELECT @StrSql = 'INSERT INTO #Exceptions(MachineID ,ComponentID,OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,ExCount )
			SELECT Ex.MachineID ,Ex.ComponentID,Ex.OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,0
			From ProductionCountException Ex
			Inner Join MachineInformation M ON Ex.MachineID=M.MachineID
			Inner Join ComponentInformation C ON Ex.ComponentID=C.ComponentID
			Inner Join Componentoperationpricing O ON Ex.OperationNo=O.OperationNo AND C.ComponentID=O.ComponentID '
			---mod 1
			SELECT @strsql = @strsql + ' and O.machineid=Ex.machineid '
			---mod 1
			SELECT @strsql = @strsql + 'WHERE  M.MultiSpindleFlag=1 AND
			((Ex.StartTime>=  ''' + convert(nvarchar(20),@curstarttime,20)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@curendtime,20)+''' )
			OR (Ex.StartTime< ''' + convert(nvarchar(20),@curstarttime,20)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@curstarttime,20)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@curendtime,20)+''')
			OR(Ex.StartTime>= ''' + convert(nvarchar(20),@curstarttime,20)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@curendtime,20)+''' AND Ex.StartTime< ''' + convert(nvarchar(20),@curendtime,20)+''')
			OR(Ex.StartTime< ''' + convert(nvarchar(20),@curstarttime,20)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@curendtime,20)+''' ))'
			SELECT @StrSql = @StrSql + @StrxMachine + @strXcomponent + @strXoperation
			Exec (@strsql)
			SELECT @strsql=''
		IF (SELECT Count(*) from #Exceptions) <> 0
		BEGIN
			UPDATE #Exceptions SET StartTime=@curstarttime WHERE (StartTime<@curstarttime)AND EndTime>@curstarttime
			UPDATE #Exceptions SET EndTime=@curendtime WHERE (EndTime>@curendtime AND StartTime<@curendtime )
		
			Select @StrSql = '--UPDATE #Exceptions SET ExCount=ISNULL(T2.Comp,0) From
			--(
				SELECT T1.MachineID AS MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime AS StartTime,T1.EndTime AS EndTime,
				SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp
			 	From (
					select M.MachineID,C.ComponentID,O.OperationNo,comp,opn,Tt1.StartTime,Tt1.EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from autodata
					Inner Join MachineInformation M  ON autodata.MC=M.InterfaceID
					Inner Join ComponentInformation  C ON autodata.Comp = C.InterfaceID
					Inner Join ComponentOperationPricing O on autodata.Opn=O.InterfaceID And C.ComponentID=O.ComponentID '
					---mod 1
					Select @StrSql =@StrSql+' and O.machineid=M.machineid '
					---mod 1
					Select @StrSql =@StrSql+'Inner Join (
						Select MachineID,ComponentID,OperationNo,StartTime,EndTime From #Exceptions
						)AS Tt1 ON Tt1.MachineID=M.MachineID AND Tt1.ComponentID = C.ComponentID AND Tt1.OperationNo= O.OperationNo
					Where (autodata.sttime>=Tt1.StartTime) AND (autodata.ndtime<=Tt1.EndTime) and (autodata.datatype=1) '
			Select @StrSql = @StrSql+ @strmachine + @strcomponent + @stroperation
			Select @StrSql = @StrSql+' Group by M.MachineID,C.ComponentID,O.OperationNo,Tt1.StartTime,Tt1.EndTime,comp,opn
				) as T1
			   	Inner join componentinformation C on T1.Comp=C.interfaceid
			   	Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid '
			---mod 1
			Select @StrSql = @StrSql + ' Inner join machineinformation M on T1.machineID = M.machineid '
			---mod 1
			Select @StrSql = @StrSql + ' GROUP BY T1.MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime,t1.EndTime '
			--)AS T2
			--WHERE  #Exceptions.StartTime=T2.StartTime AND #Exceptions.EndTime=T2.EndTime
			--AND #Exceptions.MachineID=T2.MachineID AND #Exceptions.ComponentID = T2.ComponentID AND #Exceptions.OperationNo=T2.OperationNo
			Exec(@StrSql)
			UPDATE #Exceptions SET ExCount=ExCount-((ExCount * ActualCount)/ISNULL(IdealCount,0))
			
		END
			UPDATE #ProductionLog SET CompCount=ISNULL(CompCount,0)-ISNULL(T1.Xcount,0)
			From(
				SELECT Min(StartTime)StartTime,Max(EndTime)EndTime,MachineID,ComponentID,OperationNo,SUM(ExCount)Xcount
				FROM #Exceptions
					GROUP BY MachineID,ComponentID,OperationNo
			)T1 Inner Join #ProductionLog ON
				T1.MachineID=#ProductionLog.Machine AND T1.ComponentID=#ProductionLog.CompID
				AND T1.OperationNo=#ProductionLog.OpnId AND T1.StartTime>= #ProductionLog.FromTime And T1.EndTime<=#ProductionLog.ToTime
	
			DELETE FROM #Exceptions
			if isnull(@Targetsource,'')='Exact Schedule'
			BEGIN
				 select @TrSql=''
				 select @TrSql='update #ProductionLog set TrgtCt= isnull(TrgtCt,0)+ ISNULL(t1.tcount,0) from
						( select date as date1,machine,component,operation,sum(idealcount) as tcount from
					  	loadschedule where date>=''' +convert(nvarchar(20),@StartDate,20)+''' and date<=''' +convert(nvarchar(20),@StartDate,20)+ ''' '
				---mod 2
--			    select @TrSql= @TrSql + ' WHERE machine=''' +@MachineID+''' '
			    select @TrSql= @TrSql + ' WHERE machine= N''' +@MachineID+''' '
				---mod 2
				 select @TrSql= @TrSql + @strcomponent1 + @stroperation1 + @strShift
				 select @TrSql=@TrSql+ 'group by date,machine,component,operation ) as t1 inner join #ProductionLog on
					  	t1.date1=#ProductionLog.Pdate  and t1.machine=#ProductionLog.Machine and t1.component=#ProductionLog.CompID
					  	and t1.operation=#ProductionLog.OpnId
						  Where #ProductionLog.FromTime='''+convert(nvarchar(20),@curstarttime,20)+'''
						  and #ProductionLog.ToTime='''+convert(nvarchar(20),@curendtime,20)+''' '	
--				PRINT @TrSql
				EXEC (@TrSql)
				
				 UPDATE #ProductionLog SET TrgtCt=TrgtCt* datediff(second,@curstarttime,@curendtime)/Datediff(second,@CurStart,@CurEnd)	
					Where #ProductionLog.FromTime=convert(nvarchar(20),@curstarttime,20)
				        and #ProductionLog.ToTime=convert(nvarchar(20),@curendtime,20)
				
			END
			if isnull(@Targetsource,'')='Default Target per CO'
			BEGIN
				
				select @TrSql=''
				 select @TrSql='update #ProductionLog set TrgtCt= isnull(TrgtCt,0)+ ISNULL(t1.tcount,0) from
						( select DATE AS date1, machine,component,operation,sum(idealcount) as tcount from
					  	loadschedule where date=(SELECT TOP 1 DATE FROM LOADSCHEDULE ORDER BY DATE DESC) and SHIFT=(SELECT TOP 1 SHIFT FROM LOADSCHEDULE ORDER BY SHIFT DESC)'
				---mod 2
--			    select @TrSql= @TrSql + ' WHERE machine=''' +@MachineID+''' '
			    select @TrSql= @TrSql + ' WHERE machine= N''' +@MachineID+''' '
				---mod 2
				 select @TrSql= @TrSql + @strcomponent1 + @stroperation1 + @strShift
				 select @TrSql=@TrSql+ ' group by date,machine,component,operation ) as t1 inner join #ProductionLog on
					  	 t1.machine=#ProductionLog.Machine and t1.component=#ProductionLog.CompID
					  	and t1.operation=#ProductionLog.OpnId  Where #ProductionLog.FromTime='''+convert(nvarchar(20),@curstarttime,20)+'''
						  and #ProductionLog.ToTime='''+convert(nvarchar(20),@curendtime,20)+''' '	
				--PRINT @TrSql
				EXEC (@TrSql)
				
				 UPDATE #ProductionLog SET TrgtCt=TrgtCt* datediff(second,@curstarttime,@curendtime)/Datediff(second,@CurStart,@CurEnd)	
					Where #ProductionLog.FromTime=convert(nvarchar(20),@curstarttime,20)
				        and #ProductionLog.ToTime=convert(nvarchar(20),@curendtime,20)
				
			END
			IF ISNULL(@Targetsource,'')='% Ideal'
			BEGIN
	       			select @strmachine2=''
				if isnull(@MachineID,'') <> ''
				BEGIN
				---mod 2
--				SELECT @strmachine2 = ' AND ( CO.machineID = ''' + @MachineID+ ''')'
				SELECT @strmachine2 = ' AND ( CO.machineID = N''' + @MachineID+ ''')'
				---mod 2
				END
				select @strcomponent2=''
				if isnull(@ComponentID, '') <> ''
				BEGIN
				---mod 2
--				SELECT @strcomponent2 = ' AND (CO.componentID = ''' + @ComponentID+ ''')'
				SELECT @strcomponent2 = ' AND (CO.componentID = N''' + @ComponentID+ ''')'
				---mod 2
				END
				select @stroperation2=''
				if isnull(@OperationNo, '') <> ''
				BEGIN
				---mod 2
--				SELECT @stroperation2 = ' AND ( CO.operationno = ''' + @OperationNo + ''')'
				SELECT @stroperation2 = ' AND ( CO.operationno = N''' + @OperationNo + ''')'
				---mod 2
				END
				
			     select @TrSql=''
				--select @TrSql='update #DownTemp set TrgtCt= isnull(TrgtCt,0)+ ISNULL(t1.tcount,0) from
				select @TrSql='update #ProductionLog set TrgtCt= isnull(TrgtCt,0)+ ISNULL(t1.tcount,0) from
						( select CO.machineid,CO.componentid as component,CO.Operationno as operation, tcount=((datediff(second,#ProductionLog.Fromtime,#ProductionLog.Totime) * (CO.suboperations ))/cast(CO.cycletime as float )* (isnull(CO.targetpercent,100)) /100)
						from componentoperationpricing CO inner join #ProductionLog on CO.Componentid=#ProductionLog.CompID
						and Co.operationno=#ProductionLog.OpnID  '
				---mod 1
				select @TrSql=@TrSql+ ' and CO.Machineid = #ProductionLog.machine '
				---mod 1
				select @TrSql= @TrSql + @strmachine2 + @strcomponent2 + @stroperation2
				select @TrSql=@TrSql+ '  ) as t1 inner join #ProductionLog on
					  	  t1.component=#ProductionLog.CompID
					  	and t1.operation=#ProductionLog.OpnId  '
				---mod 1
				select @TrSql=@TrSql+ ' and t1.Machineid = #ProductionLog.machine '
				---mod 1
				select @TrSql=@TrSql+ ' Where #ProductionLog.FromTime='''+convert(nvarchar(20),@curstarttime,20)+'''
						  and #ProductionLog.ToTime='''+convert(nvarchar(20),@curendtime,20)+''' '	
				
				EXEC (@TrSql)
			END
		-------------------Cumulative ideal and actual counts--------
			--select sum(TrgtCt) from  #ProductionLog where #ProductionLog.fromTime<convert(nvarchar(20),@curstarttime,20)
			SELECT @strsql=''
			SELECT @strsql = 'update #ProductionLog set SumIdeal=isnull(t1.Idealcount,0) , sumActual=isnull(T1.Actualcount,0) from '
					--(select sum(TrgtCt) as Idealcount,sum(compcount) as Actualcount,FromTime as date1,machine,compID,opnID  from #ProductionLog where
			SELECT @strsql = @strsql+'(select sum(TrgtCt) as Idealcount,sum(compcount) as Actualcount,machine,compID,opnID from #ProductionLog where	
					 #ProductionLog.fromtime >=''' +convert(nvarchar(20),@CurStart,20)+ '''  and #ProductionLog.ToTime<='''+convert(nvarchar(20),@curend,20)+'''
					 and #ProductionLog.fromtime <=''' +convert(nvarchar(20),@curstarttime,20)+ '''  group by machine,compId,opnID ) as T1 inner join #ProductionLog on
					 t1.machine= #ProductionLog.machine and
					 t1.CompID=#ProductionLog.CompID
					 and t1.OpnId=#ProductionLog.OpnId Where #ProductionLog.FromTime='''+convert(nvarchar(20),@curstarttime,20)+'''
					 and #ProductionLog.ToTime='''+convert(nvarchar(20),@curendtime,20)+''' '	
			EXEC (@strsql)
		END */
		--commented till here for mod 4
		/*if isnull(@RepType,'')='DTime'
		BEGIN
			Select @strsql=''
			Select @strsql = 'INSERT INTO #DownTimeData (StartTime,EndTime,MachineID,McInterfaceid, DownID, DownTime)
		 			 SELECT '''+convert(nvarchar(20),@curstarttime,20)+''','''+convert(nvarchar(20),@curendtime)+''',Machineinformation.MachineID AS MachineID,Machineinformation.interfaceid, downcodeinformation.downid AS DownID, 0
					 FROM Machineinformation CROSS JOIN downcodeinformation LEFT OUTER JOIN PlantMachine ON PlantMachine.MachineID=Machineinformation.MachineID '
			
			if isnull(@machineid,'') <> ''
			begin
			select @strsql =  @strsql + ' where ( machineinformation.machineid = ''' + @machineid + ''')'
			end
		
			select @strsql = @strsql + @strPlantID + ' ORDER BY  downcodeinformation.downid, Machineinformation.MachineID'
			Exec (@strsql)
			
			--Get Down Time Details
			--TYPE1 i
			select @strsql = ''
			select @strsql = @strsql + 'UPDATE #DownTimeData SET downtime = isnull(DownTime,0) + isnull(t2.down,0) '
			--select @strsql = @strsql+' DownFreq = isNull(downfreq,0) + isNull(t2.dwnfrq,0) '
			select @strsql = @strsql + ' FROM'
			select @strsql = @strsql + ' (SELECT mc,sum(loadunload)as down,downcodeinformation.downid as downid'
			select @strsql = @strsql + ' from'
			select @strsql = @strsql + '  autodata INNER JOIN'
			select @strsql = @strsql + ' machineinformation M ON autodata.mc = M.InterfaceID Left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID INNER JOIN'
			select @strsql = @strsql + ' componentinformation ON autodata.comp = componentinformation.InterfaceID INNER JOIN'
			select @strsql = @strsql + ' downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid'
			select @strsql = @strsql + ' where  autodata.sttime>='''+convert(varchar(20),@curstarttime,20)+''' and autodata.ndtime<='''+convert(varchar(20),@curendtime,20)+''' and datatype=2 '
			select @strsql = @strsql  + @strmachine + @StrPlantID
			select @strsql = @strsql + ' group by autodata.mc,downcodeinformation.downid )'
			select @strsql = @strsql + ' as t2 inner join #DownTimeData on t2.mc=#DownTimeData.McInterfaceid and t2.downid=#DownTimeData.downid '
			select @strsql = @strsql + ' where #DownTimeData.StartTime='''+convert(nvarchar(20),@curstarttime)+''' and #DownTimeData.EndTime= '''+convert(nvarchar(20),@curendtime)+''' '
			exec (@strsql)
			print (@strsql)
			
			--TYPE2
			select @strsql = ''
			select @strsql = @strsql+' update #DownTimeData set downtime=isnull(DownTime,0) + isnull(t2.down,0)'
			--select @strsql = @strsql+' downfreq=isnull(downfreq,0)+isnull(t2.dwnfrq,0)'
			select @strsql = @strsql+' FROM'
			select @strsql = @strsql+' (SELECT mc,sum(DateDiff(second, '''+convert(varchar(20),@curstarttime,20)+''', ndtime))as down,downcodeinformation.downid as downid'
			select @strsql = @strsql+' from'
			select @strsql=@strsql+'  autodata INNER JOIN
			machineinformation  M ON autodata.mc = M.InterfaceID Left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID INNER JOIN
			componentinformation ON autodata.comp = componentinformation.InterfaceID INNER JOIN
			downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid'
			select @strsql=@strsql+' where  autodata.sttime<'''+convert(varchar(20),@curstarttime,20)+''' and autodata.ndtime>'''+convert(varchar(20),@curstarttime,20)+'''and autodata.ndtime<='''+convert(varchar(20),@curendtime,20)+''' and datatype=2'
			select @strsql = @strsql   + @strmachine+ @StrPlantID
			select @strsql=@strsql+' group by autodata.mc,downcodeinformation.downid )'
			select @strsql=@strsql+' as t2 inner join #DownTimeData on t2.mc=#DownTimeData.McInterfaceid and t2.downid=#DownTimeData.downid'
			select @strsql = @strsql + ' where #DownTimeData.StartTime='''+convert(nvarchar(20),@curstarttime)+''' and #DownTimeData.EndTime= '''+convert(nvarchar(20),@curendtime)+''' '
			exec (@strsql)
			print (@strsql)
			--TYPE3
			select @strsql = ''
			select @strsql = @strsql+' update #DownTimeData set downtime=isnull(DownTime,0) + isnull(t2.down,0)'
			--select @strsql = @strsql+' downfreq=isnull(downfreq,0)+isnull(t2.dwnfrq,0)'
			select @strsql = @strsql+' FROM'
			select @strsql = @strsql+' (SELECT mc,sum(DateDiff(second, stTime, '''+convert(varchar(20),@curendtime)+'''))as down,downcodeinformation.downid as downid'
			select @strsql = @strsql+' from'
			select @strsql = @strsql+'  autodata INNER JOIN
			machineinformation  M ON autodata.mc = M.InterfaceID Left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID INNER JOIN
			componentinformation ON autodata.comp = componentinformation.InterfaceID INNER JOIN
			employeeinformation ON autodata.opr = employeeinformation.interfaceid INNER JOIN
			downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid'
			select @strsql=@strsql+' where  autodata.sttime>='''+convert(varchar(20),@curstarttime)+'''and autodata.sttime<'''+convert(varchar(20),@curendtime)+''' and autodata.ndtime>'''+convert(varchar(20),@curendtime)+''' and datatype=2'
			select @strsql = @strsql  + @strmachine+ @StrPlantID
			select @strsql=@strsql+' group by autodata.mc,downcodeinformation.downid )'
			select @strsql=@strsql+' as t2 inner join #DownTimeData on t2.mc=#DownTimeData.McInterfaceid and t2.downid=#DownTimeData.downid'
			select @strsql = @strsql + ' where #DownTimeData.StartTime='''+convert(nvarchar(20),@curstarttime)+''' and #DownTimeData.EndTime= '''+convert(nvarchar(20),@curendtime)+''' '
			exec (@strsql)
			print (@strsql)
			--TYPE4
			select @strsql = ''
			select @strsql = @strsql+' update #DownTimeData set downtime=isnull(DownTime,0) + isnull(t2.down,0)'
			--select @strsql = @strsql+' downfreq=isnull(downfreq,0)+isnull(t2.dwnfrq,0)'
			select @strsql = @strsql+' FROM'
			select @strsql = @strsql+' (SELECT mc,sum(DateDiff(second, '''+convert(varchar(20),@curstarttime)+''', '''+convert(varchar(20),@curendtime)+'''))as down,downcodeinformation.downid as downid'
			select @strsql = @strsql+' from'
			select @strsql = @strsql+'  autodata INNER JOIN
			machineinformation M ON autodata.mc = M.InterfaceID Left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID  INNER JOIN
			componentinformation ON autodata.comp = componentinformation.InterfaceID INNER JOIN
			employeeinformation ON autodata.opr = employeeinformation.interfaceid INNER JOIN
			downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid'
			select @strsql=@strsql+' where  autodata.sttime<'''+convert(varchar(20),@curstarttime)+''' and autodata.ndtime>'''+convert(varchar(20),@curendtime)+''' and datatype=2'
			select @strsql = @strsql  +@strmachine + @StrPlantID
			select @strsql=@strsql+' group by autodata.mc,downcodeinformation.downid )'
			select @strsql=@strsql+' as t2 inner join #DownTimeData on t2.mc=#DownTimeData.McInterfaceid and t2.downid=#DownTimeData.downid'
			select @strsql = @strsql + ' where #DownTimeData.StartTime='''+convert(nvarchar(20),@curstarttime)+''' and #DownTimeData.EndTime='''+convert(nvarchar(20),@curendtime)+''' '
			exec (@strsql)
			print (@strsql)
			
		END */
			
			--Update #ProductionLog set DownTime=T1.Down From( select DownTime from  Exec s_GetDownTimeReportfromAutoData @curstarttime,@curendtime,@Machine,'','','','','','','','DTimeOnly',@PlantID,@Exclude
		-----------------------------------------------------------------------------------------------------
			select @PrevStart=@curstarttime
			select @Prevend=@curendtime
			select @Counter=dateadd(second,3600,@Counter)
			
		END
		
		FETCH NEXT FROM TmplogCursor1 INTO @CurDate,@CurShift,@CurStart,@CurEnd
		
	END
close TmplogCursor1
deallocate TmplogCursor1
/*if isnull(@RepType,'')='DTime'
BEGIN
	update #DownTimeData set DownTime=DownTime/60
	update #DownTimeData set TotalDown = (SELECT SUM(DownTime) FROM #DownTimeData as FD WHERE Fd.DownID = #DownTimeData.DownID)
END*/
---Commented for Mod 4
/*if isnull(@RepType,'')='Pcount'
BEGIN
	update #ProductionLog set sumcomp=(select sum(CompCount) from #ProductionLog as PL Where PL.Machine= #ProductionLog.Machine and PL.CompID=#ProductionLog.CompID and PL.OpnID=#ProductionLog.OpnID)
END  Commented till here  for mod 4*/
--mod 4 :Optimizar=tion and PDT.
IF isnull(@RepType,'')='Pcount'
BEGIN
	SELECT @strsql='INSERT INTO #ProductionLog(PDate,ShiftName,FromTime,ToTime,Machine,CompID,OpnID,shiftstart,shiftEnd)'
	SELECT @strsql = @strsql + ' SELECT  '''+Convert(nvarchar(20),@StartDate,120)+ ''',H.Shift,H.Start,H.Hrend,M.MachineID,C.componentid,O.operationno,H.shiftstart,H.shiftEnd'
	SELECT @strsql = @strsql +' from autodata A '
	SELECT @strsql = @strsql +' inner join ComponentInformation C on A.comp=C.interfaceid '
	SELECT @strsql = @strsql +' inner join ComponentOperationPricing O on A.opn=O.interfaceid and C.componentid=O.componentid '
	SELECT @strsql = @strsql +' INNER JOIN machineinformation M on A.mc=M.interfaceid '
	SELECT @strsql = @strsql +' left OUTER Join PlantMachine P on m.machineid = P.machineid '
	SELECT @strsql = @strsql +'  cross join #hourdefini H '
	SELECT @strsql = @strsql + 'Where  M.machineid = N''' + @MachineID+ ''' '
	SELECT @strsql = @strsql + @strcomponent + @stroperation + @strPlantID
	SELECT @strsql = @strsql + ' GROUP BY H.Shift,H.Start,H.Hrend,M.MachineID,C.componentid,O.operationno,O.SubOperations,H.shiftstart,H.shiftEnd'
	
	EXEC (@strsql)
	SELECT @strsql=''
	SELECT @strsql = 'update #ProductionLog set compCount=ISNULL(CompCount,0)+isnull(t1.Prdn,0) From
		(select PL.FromTime,PL.ToTime,M.MachineID as mach ,C.componentid as compn,O.operationno oprn,CAST(CEILING(CAST(sum(A.partscount)AS Float)/ISNULL(O.SubOperations,1)) AS INTEGER) as prdn
		 from autodata A inner join ComponentInformation C on A.comp=C.interfaceid
		inner join ComponentOperationPricing O on A.opn=O.interfaceid and C.componentid=O.componentid '
	SELECT @strsql = @strsql + 'INNER JOIN machineinformation M on A.mc=M.interfaceid  left OUTER Join PlantMachine P on m.machineid = P.machineid '
	---mod 1
	SELECT @strsql = @strsql + ' and M.machineid=O.machineid'
	---mod 1
	SELECT @strsql = @strsql + ' inner join #ProductionLog PL on M.MachineID=PL.Machine and C.componentid=PL.CompID
				    and O.operationno=PL.OpnID and PL.MAchine=O.machineid '
	SELECT @strsql = @strsql +' WHERE A.DataType=1 And A.ndtime>PL.FromTime  and A.Ndtime<=PL.ToTime '
	SELECT @strsql = @strsql +@strmachine+ @strcomponent + @stroperation + @strPlantID
	SELECT @strsql = @strsql + ' GROUP BY PL.FromTime,PL.ToTime,M.MachineID,C.componentid,O.operationno,O.SubOperations )'
	SELECT @strsql = @strsql + ' as T1 inner join #ProductionLog on  T1.mach=#ProductionLog.Machine and T1.compn=#ProductionLog.CompID and T1.oprn=#ProductionLog.OpnID '
	SELECT @strsql = @strsql + ' and  #ProductionLog.FromTime=T1.FromTime and #ProductionLog.ToTime=T1.ToTime '
print(@strsql)
	EXEC (@strsql)
	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
	BEGIN
		---get PDT
		insert INTO #PlannedDownTimesCount(StartTime,EndTime,Machine,Downreason,PShiftName,PHourStart,PHourEnd)
		select
		CASE When P.StartTime<T1.FromTime Then T1.FromTime Else P.StartTime End,
		case When P.EndTime>T1.ToTime Then T1.ToTime Else P.EndTime End,
		P.Machine,P.DownReason,T1.ShiftName,T1.FromTime,T1.ToTime
		FROM PlannedDownTimes P inner join
		(select distinct ShiftName,FromTime,ToTime,Machine from
		#ProductionLog )  T1 on T1.Machine=P.Machine
		WHERE P.PDTstatus =1 and (
		(P.StartTime >= T1.FromTime  AND P.EndTime <=T1.ToTime)
		OR ( P.StartTime < T1.FromTime  AND P.EndTime <= T1.ToTime AND P.EndTime > T1.FromTime )
		OR ( P.StartTime >= T1.FromTime   AND P.StartTime <T1.ToTime AND P.EndTime > T1.ToTime )
		OR ( P.StartTime < T1.FromTime  AND P.EndTime > T1.ToTime) )
		ORDER BY P.StartTime
		
		--Remove count overlapping with PDT
		UPDATE #ProductionLog SET CompCount = ISNULL(CompCount,0) - ISNULL(T2.Pcount,0)
		from
		(
		select P.Fromtime,P.Totime,M.machineid as machID,SUM(CEILING (CAST(PartsCount AS Float)/ISNULL(O.SubOperations,1))) as Pcount,C.Componentid as CompID,
		O.OperationNo as OpnNo from autodata
		inner join machineinformation M on autodata.mc=M.Interfaceid
		inner join ComponentInformation C on autodata.comp=C.interfaceid inner join
		Componentoperationpricing O on autodata.opn=O.interfaceid and C.Componentid=O.componentid  and O.MachineId=M.MachineId
		inner jOIN #PlannedDownTimesCount T  on T.Machine=M.MachineId
		inner join #ProductionLog P on P.Machine=M.MachineId and P.CompID=C.componentid and P.OpnId=O.Operationno
		and P.Fromtime=T.PhourStart and P.Totime=T.PhourEnd and P.Shiftname=T.PshiftName
		WHERE autodata.DataType=1 AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)
		Group by M.machineid,C.Componentid,O.OperationNo,P.Fromtime,P.Totime ) as T2
		inner join #ProductionLog on T2.machID = #ProductionLog.Machine and T2.CompID=#ProductionLog.CompID
		and T2.OpnNo=#ProductionLog.OpnId and t2.Fromtime=#ProductionLog.FromTime and T2.Totime=#ProductionLog.Totime
	
	END
	
	SELECT @strsql=''
	SELECT @StrSql = 'INSERT INTO #Exceptions(MachineID ,ComponentID,OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,ExCount ,HourStart,HourEnd)
	SELECT Ex.MachineID ,Ex.ComponentID,Ex.OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,0,H.Start,H.Hrend
	From ProductionCountException Ex
	Inner Join MachineInformation M ON Ex.MachineID=M.MachineID
	Inner Join ComponentInformation C ON Ex.ComponentID=C.ComponentID
	Inner Join Componentoperationpricing O ON Ex.OperationNo=O.OperationNo AND C.ComponentID=O.ComponentID '
	---mod 1
	SELECT @strsql = @strsql + ' and O.machineid=Ex.machineid '
	---mod 1
	SELECT @strsql = @strsql + 'Cross join  #hourdefini H '
	SELECT @strsql = @strsql + 'WHERE  M.MultiSpindleFlag=1 AND
	((Ex.StartTime>=  H.Start AND Ex.EndTime<= H.Hrend )
	OR (Ex.StartTime< H.Start AND Ex.EndTime> H.Start AND Ex.EndTime<= H.Hrend)
	OR(Ex.StartTime>= H.Start AND Ex.EndTime>H.Hrend AND Ex.StartTime< H.Hrend)
	OR(Ex.StartTime< H.Start AND Ex.EndTime> H.Hrend ))'
	SELECT @StrSql = @StrSql + @StrxMachine + @strXcomponent + @strXoperation
	Exec (@strsql)
	IF (SELECT Count(*) from #Exceptions) <> 0
	BEGIN
		UPDATE #Exceptions SET StartTime=HourStart WHERE (StartTime<HourStart)AND EndTime>HourStart
		UPDATE #Exceptions SET EndTime=HourEnd WHERE (EndTime>HourEnd AND StartTime<HourEnd )
	
		Select @StrSql = 'UPDATE #Exceptions SET ExCount=ISNULL(T2.Pcount,0) From
				( select Tt1.HourStart as Hrstart,Tt1.HourEnd as Hrend,M.MachineID,C.ComponentID,O.OperationNo,comp,opn,
				  Tt1.StartTime,Tt1.EndTime,CAST(CEILING(CAST(sum(partscount)AS Float)/ISNULL(O.SubOperations,1)) AS INTEGER) AS Pcount from autodata
				Inner Join MachineInformation M  ON autodata.MC=M.InterfaceID
				Inner Join ComponentInformation  C ON autodata.Comp = C.InterfaceID
				Inner Join ComponentOperationPricing O on autodata.Opn=O.InterfaceID And C.ComponentID=O.ComponentID '
				Select @StrSql =@StrSql+' and O.machineid=M.machineid '
				Select @StrSql =@StrSql+'Inner Join (
					Select  HourStart,HourEnd,MachineID,ComponentID,OperationNo,StartTime,EndTime From #Exceptions
					)AS Tt1 ON Tt1.MachineID=M.MachineID AND Tt1.ComponentID = C.ComponentID AND Tt1.OperationNo= O.OperationNo and Tt1.MachineID=O.MachineID
				Where (autodata.sttime>=Tt1.StartTime) AND (autodata.ndtime<=Tt1.EndTime) and (autodata.datatype=1) '
		Select @StrSql = @StrSql+ @strmachine + @strcomponent + @stroperation
		Select @StrSql = @StrSql+' Group by Tt1.HourStart ,Tt1.HourEnd,M.MachineID,C.ComponentID,O.OperationNo,Tt1.StartTime,Tt1.EndTime,comp,opn,O.SubOperations
		)AS T2 '
		Select @StrSql = @StrSql+ 'WHERE  #Exceptions.HourStart=T2.Hrstart and #Exceptions.HourEnd=T2.Hrend  and #Exceptions.StartTime=T2.StartTime AND #Exceptions.EndTime=T2.EndTime
		AND #Exceptions.MachineID=T2.MachineID AND #Exceptions.ComponentID = T2.ComponentID AND #Exceptions.OperationNo=T2.OperationNo'
		
		Exec(@StrSql)
		--return

		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
		BEGIN
			Select @StrSql =''
			Select @StrSql ='UPDATE #Exceptions SET ExCount=ISNULL(ExCount,0) - ISNULL(T3.Comp,0)
			From
			(
				SELECT T2.MachineID AS MachineID,T2.ComponentID,T2.OperationNo,T2.StartTime AS StartTime,T2.EndTime AS EndTime,
				SUM(CEILING (CAST(T2.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp,T2.HourStart,T2.HourEnd
				From
				(
					select M.MachineID,C.ComponentID,O.OperationNo,comp,opn,
					Max(T1.XStartTime)StartTime,Max(T1.XEndTime)EndTime,T1.PLD_StartTime,T1.PLD_EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount,
					T1.HourStart,T1.HourEnd from autodata
					Inner Join MachineInformation M   ON autodata.MC=M.InterfaceID
					Inner Join ComponentInformation C ON autodata.Comp = C.InterfaceID
					Inner Join ComponentOperationPricing O on autodata.Opn=O.InterfaceID And C.ComponentID=O.ComponentID
					and O.MachineId=M.MachineID
					Inner Join	
					(
						SELECT MachineID,ComponentID,OperationNo,Ex.StartTime As XStartTime, Ex.EndTime AS XEndTime,
						Ex.HourStart as HourStart,Ex.HourEnd as HourEnd,
						CASE
							WHEN (Td.StartTime< Ex.StartTime And Td.EndTime<=Ex.EndTime AND Td.EndTime>Ex.StartTime) THEN Ex.StartTime
							WHEN  (Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime) THEN Ex.StartTime
							ELSE Td.StartTime
						END AS PLD_StartTime,
						CASE
							WHEN (Td.StartTime>= Ex.StartTime And Td.StartTime <Ex.EndTime AND Td.EndTime>Ex.EndTime) THEN Ex.EndTime
							WHEN  (Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime) THEN Ex.EndTime
							ELSE  Td.EndTime
						END AS PLD_EndTime
			
						From #Exceptions AS Ex inner JOIN #PlannedDownTimesCount AS Td
						on Td.Machine=Ex.MachineID and Ex.HourStart=Td.PHourstart and Ex.HourEnd=Td.PHourEnd
						Where ((Td.StartTime>=Ex.StartTime And Td.EndTime <=Ex.EndTime)OR
						(Td.StartTime< Ex.StartTime And Td.EndTime<=Ex.EndTime AND Td.EndTime>Ex.StartTime)OR
						(Td.StartTime>= Ex.StartTime And Td.StartTime <Ex.EndTime AND Td.EndTime>Ex.EndTime)OR
						(Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime) )'
				Select @StrSql = @StrSql + ' )AS T1 ON T1.MachineID=M.MachineID AND T1.ComponentID = C.ComponentID AND T1.OperationNo= O.OperationNo and T1.MachineId=O.MachineId
						Where (autodata.ndtime>T1.PLD_StartTime AND autodata.ndtime<=T1.PLD_EndTime) and (autodata.datatype=1) '
				Select @StrSql = @StrSql + @strmachine + @strcomponent + @stroperation
				Select @StrSql = @StrSql+' Group by M.MachineID,C.ComponentID,O.OperationNo,T1.PLD_StartTime,T1.PLD_EndTime,comp,opn,T1.HourStart,T1.HourEnd
				)AS T2
				Inner join componentinformation C on T2.Comp=C.interfaceid
				Inner join ComponentOperationPricing O ON T2.Opn=O.interfaceid and C.Componentid=O.componentid
				GROUP BY T2.MachineID,T2.ComponentID,T2.OperationNo,T2.StartTime,t2.EndTime,T2.HourStart,T2.HourEnd
			)As T3
			WHERE  #Exceptions.StartTime=T3.StartTime AND #Exceptions.EndTime=T3.EndTime
			AND #Exceptions.MachineID=T3.MachineID AND #Exceptions.ComponentID = T3.ComponentID AND #Exceptions.OperationNo=T3.OperationNo
			and T3.HourStart=#Exceptions.HourStart and T3.HourEnd=#Exceptions.HourEnd '
			EXEC(@StrSql)
			
		END
		
		UPDATE #Exceptions SET ExCount=ExCount-((ExCount * ActualCount)/ISNULL(IdealCount,0))
	
	END
	--Apply exceptions on count
	UPDATE #ProductionLog SET CompCount=ISNULL(CompCount,0)-ISNULL(T1.Xcount,0)
	From(
		SELECT HourStart,HourEnd,Min(StartTime)StartTime,Max(EndTime)EndTime,MachineID,ComponentID,OperationNo,SUM(ExCount)Xcount
		FROM #Exceptions
			GROUP BY MachineID,ComponentID,OperationNo,HourStart,HourEnd
	)T1 Inner Join #ProductionLog ON
		T1.MachineID=#ProductionLog.Machine AND T1.ComponentID=#ProductionLog.CompID
		AND T1.OperationNo=#ProductionLog.OpnId AND T1.StartTime>= #ProductionLog.FromTime And T1.EndTime<=#ProductionLog.ToTime
		and T1.HourStart=#ProductionLog.FromTime and T1.HourEnd=#ProductionLog.ToTime
	
	update #ProductionLog set sumcomp=(select sum(CompCount) from #ProductionLog as PL Where PL.Machine= #ProductionLog.Machine and PL.CompID=#ProductionLog.CompID and PL.OpnID=#ProductionLog.OpnID)
	---target calculation
	
	if isnull(@Targetsource,'')='Exact Schedule'
	BEGIN
		 select @TrSql=''
		 select @TrSql='update #ProductionLog set TrgtCt= isnull(TrgtCt,0)+ ISNULL(t1.tcount,0) from
				( select date as date1,machine,component,operation,sum(idealcount) as tcount from
			  	loadschedule where date>=''' +convert(nvarchar(20),@StartDate,20)+''' and date<=''' +convert(nvarchar(20),@StartDate,20)+ ''' '
		 --select @TrSql= @TrSql + ' WHERE machine= N''' +@MachineID+''' ' --DR0251 - KarthikR - 26\Aug\2010
		 select @TrSql= @TrSql + ' and machine= N''' +@MachineID+''' '
		 select @TrSql= @TrSql + @strcomponent1 + @stroperation1 + @strShift
		 select @TrSql=@TrSql+ 'group by date,machine,component,operation ) as t1 inner join #ProductionLog on
			  	t1.date1=#ProductionLog.Pdate  and t1.machine=#ProductionLog.Machine and t1.component=#ProductionLog.CompID
			  	and t1.operation=#ProductionLog.OpnId
				'	
		EXEC (@TrSql)
		
		 UPDATE #ProductionLog SET TrgtCt=TrgtCt* datediff(second,Fromtime,Totime)/Datediff(second,ShiftStart,ShiftEnd)	
			
		
	END
	if isnull(@Targetsource,'')='Default Target per CO'
	BEGIN
		
		select @TrSql=''
		 select @TrSql='update #ProductionLog set TrgtCt= isnull(TrgtCt,0)+ ISNULL(t1.tcount,0) from
				( select DATE AS date1, machine,component,operation,sum(idealcount) as tcount from
			  	loadschedule where date=(SELECT TOP 1 DATE FROM LOADSCHEDULE ORDER BY DATE DESC) and SHIFT=(SELECT TOP 1 SHIFT FROM LOADSCHEDULE ORDER BY SHIFT DESC)'
		     --select @TrSql= @TrSql + ' where machine= N''' +@MachineID+''' '  --DR0251 - KarthikR - 26\Aug\2010
			 select @TrSql= @TrSql + ' and machine= N''' +@MachineID+''' '
			 select @TrSql= @TrSql + @strcomponent1 + @stroperation1 + @strShift
		     select @TrSql=@TrSql+ ' group by date,machine,component,operation ) as t1 inner join #ProductionLog on
			  	 t1.machine=#ProductionLog.Machine and t1.component=#ProductionLog.CompID
			  	and t1.operation=#ProductionLog.OpnId  '
		print(@TrSql)	
		EXEC (@TrSql)
		
		 UPDATE #ProductionLog SET TrgtCt=TrgtCt* datediff(second,Fromtime,Totime)/Datediff(second,ShiftStart,ShiftEnd)	
			
	END
print(@Targetsource)
	IF ISNULL(@Targetsource,'')='% Ideal'
	BEGIN
			select @strmachine2=''
		if isnull(@MachineID,'') <> ''
		BEGIN
			SELECT @strmachine2 = ' AND ( CO.machineID = N''' + @MachineID+ ''')'
		END
	
		select @strcomponent2=''
		if isnull(@ComponentID, '') <> ''
		BEGIN
			SELECT @strcomponent2 = ' AND (CO.componentID = N''' + @ComponentID+ ''')'
		END
	
		select @stroperation2=''
		if isnull(@OperationNo, '') <> ''
		BEGIN
			SELECT @stroperation2 = ' AND ( CO.operationno = N''' + @OperationNo + ''')'
		END
		
	     select @TrSql=''
		--select @TrSql='update #DownTemp set TrgtCt= isnull(TrgtCt,0)+ ISNULL(t1.tcount,0) from
		select @TrSql='update #ProductionLog set TrgtCt= isnull(TrgtCt,0)+ ISNULL(t1.tcount,0) from
				( select #ProductionLog.Fromtime as FromTime,#ProductionLog.Totime as Totime,
				CO.machineid,CO.componentid as component,CO.Operationno as operation, tcount=((datediff(second,#ProductionLog.Fromtime,#ProductionLog.Totime) * (CO.suboperations ))/cast(CO.cycletime as float )* (isnull(CO.targetpercent,100)) /100)
				from componentoperationpricing CO inner join #ProductionLog on CO.Componentid=#ProductionLog.CompID
				and Co.operationno=#ProductionLog.OpnID  '
		select @TrSql=@TrSql+ ' and CO.Machineid = #ProductionLog.machine '
		select @TrSql= @TrSql + @strmachine2 + @strcomponent2 + @stroperation2
		select @TrSql=@TrSql+ '  ) as t1 inner join #ProductionLog on
			  	  t1.component=#ProductionLog.CompID
			  	and t1.operation=#ProductionLog.OpnId  '
		select @TrSql=@TrSql+ ' and t1.Machineid = #ProductionLog.machine '
		select @TrSql=@TrSql+ ' and #ProductionLog.FromTime=T1.Fromtime
				  and #ProductionLog.ToTime=T1.Totime '	
		
		EXEC (@TrSql)
	END
	
	
	--Calculate cumulative actual and target count at shift,Machine , component and opn level
	update #ProductionLog set SumIdeal=isnull(t2.Idealcount,0) , sumActual=isnull(T2.Actualcount,0) from
	(select sum(T1.Idealcount) as Idealcount,sum(T1.Actualcount) as Actualcount ,P.machine,
	P.compID,P.opnID,P.fromtime as fromtime,P.ToTime ToTime,T1.ShiftEnd from #ProductionLog  P left outer  join
	
	(select TrgtCt as Idealcount,compcount as Actualcount,machine,compID,opnID,fromtime as PrevStart,
	 ToTime as PrevEnd,ShiftEnd from #ProductionLog )as  T1
	on T1.machine=P.machine and T1.compID=P.compID and T1.opnID=P.opnID
	where P.Fromtime>=T1.PrevStart and  P.Totime<=T1.ShiftEnd
	Group by P.machine,P.compID,P.opnID,P.fromtime,P.ToTime,T1.ShiftEnd)
	 T2  inner join #ProductionLog PL on
	T2.machine=PL.machine and T2.compID=PL.compID and T2.opnID=PL.opnID  and T2.Fromtime=PL.Fromtime and T2.ToTime=PL.ToTime
	and T2.shiftEnd=PL.Shiftend
END
---OutPut
if isnull(@RepType,'')='Pcount'
	
select 	PDate ,
	Cast(CAST(YEAR(FromTime)as nvarchar(4))+CAST(Month(FromTime)as nvarchar(2))+CAST(Day(FromTime)as nvarchar(2))+CASE WHEN DATALENGTH(Cast(datepart(hh,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,FromTime)as nvarchar(2)) ELSE cast(datepart(hh,FromTime)as nvarchar(2))END +':'+CASE WHEN DATALENGTH(Cast(datepart(n,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(n,FromTime)as nvarchar(2)) ELSE cast(datepart(n,FromTime)as nvarchar(2))END+' To '+CASE WHEN DATALENGTH(Cast(datepart(hh,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,ToTime)as nvarchar(2)) ELSE cast(datepart(hh,ToTime)as nvarchar(2))END+':'+CASE WHEN DATALENGTH(Cast(datepart(n,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(n,ToTime)as nvarchar(2)) ELSE cast(datepart(n,ToTime)as nvarchar(2))END  as NVarchar(50)) as Shift,
	ShiftName ,
	FromTime ,
	ToTime ,
	Machine,
	CompID ,
	OpnID,
	CompCount,
	TrgtCt,
	SumIdeal,
	SumActual
	from #ProductionLog
	where sumcomp>0 Group by Pdate,ShiftName,Fromtime,ToTime,Machine,CompID,OpnID,CompCount,
	TrgtCt,SumIdeal,SumActual Order by FromTime asc
/*else if isnull(@RepType,'')='DTime'
select StartTime,
	EndTime ,
	Cast(CAST(YEAR(StartTime)as nvarchar(4))+CAST(Month(StartTime)as nvarchar(2))+CAST(Day(StartTime)as nvarchar(2))+CASE WHEN DATALENGTH(Cast(datepart(hh,StartTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,StartTime)as nvarchar(2)) ELSE cast(datepart(hh,StartTime)as nvarchar(2))END +':'+CASE WHEN DATALENGTH(Cast(datepart(n,StartTime)as nvarchar))=2 THEN '0'+cast(datepart(n,StartTime)as nvarchar(2)) ELSE cast(datepart(n,StartTime)as nvarchar(2))END+' To '+CASE WHEN DATALENGTH(Cast(datepart(hh,EndTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,EndTime)as nvarchar(2)) ELSE cast(datepart(hh,EndTime)as nvarchar(2))END+':'+CASE WHEN DATALENGTH(Cast(datepart(n,EndTime)as nvarchar))=2 THEN '0'+cast(datepart(n,EndTime)as nvarchar(2)) ELSE cast(datepart(n,EndTime)as nvarchar(2))END  as NVarchar(50)) as Shift,
	machineid ,
	#DownTimeData.downid ,
	D.Downdescription as descrdown,
	downtime ,
	TotalDown from #DownTimeData INNER JOIN Downcodeinformation D ON #DownTimeData.downid=D.DownID
	where TotalDown>0  Group by #DownTimeData.downid,D.Downdescription ,machineid,StartTime,EndTime,downtime,TotalDown --order by StartTime asc--,TotalDown asc */
END
