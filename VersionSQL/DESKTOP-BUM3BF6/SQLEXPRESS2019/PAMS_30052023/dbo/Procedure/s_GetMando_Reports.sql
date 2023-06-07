/****** Object:  Procedure [dbo].[s_GetMando_Reports]    Committed by VersionSQL https://www.versionsql.com ******/

/*
Procedure created by Karthik G on 26-Nov-07 : Mando report
mod1:- Procedure modified by Mrudula on 11-dec-2007
mod 2 :- ER0181 By Kusuma M.H on 12-May-2009.2) Modify all the procedures accordingly. Qualify machine wherever we are making use of component and opeartion no.
mod 3 :- ER0182 By Kusuma M.H on 12-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
mod 4 :-By Mrudula M. Rao on 15-feb-2009.ER0210 Introduce PDT on 5150. 1) Handle PDT at Machine Level. 
			2) Handle interaction between PDT and Mangement Loss. Also handle interaction InCycleDown And PDT.
			3) Improve the performance.
			4) Handle intearction between ICD and PDT for type 1 production record for the selected time period.
-- [s_GetMando_Reports] '2019-03-20 07:00:00','2019-03-21 07:00:00','','','','1','2',1

			Exec s_GetMando_Reports '2022-03-20 06:00:00.000','2022-03-21 06:00:00.000','','WFL M80 Mill Turn','','1','2',2

*/
CREATE                    procedure [dbo].[s_GetMando_Reports]
	@StartDate DateTime,
	@EndDate DateTime,
---mod 3
---Replaced varchar with nvarchar to support unicode characters.
--	@Plant varchar(50) = '',
	@Plant nvarchar(50) = '',
--	@Machine  varchar(50) = '',
	@Machine  nvarchar(max) = '',
	@GroupID nvarchar(max)='',
--	@ShiftID varchar(50) = '',
	@ShiftID nvarchar(50) = '',
---mod 3
	@SheetNo int,
	@Format int
as
begin
Declare @StrSql as Nvarchar(4000)
Declare @TempDate as dateTime
Declare @StartTime as DateTime
Declare @EndTime as DateTime
Declare @mc as nvarchar(50)
Declare @comp as nvarchar(50)
Declare @opn as nvarchar(50)
Declare @counter as int
declare @strmachine as nvarchar(max)
declare @StrGroupID as nvarchar(max)
declare @StrMCJoined as nvarchar(max)
declare @StrGroupJoined as nvarchar(max)
declare @strPlantID as nvarchar(250)
declare @ShiftStartDay  nvarchar(50)
------------------------------------------Common to all sheets-------------------------------------------------------
	---Create Table #MachineID(Machine nvarchar(50),MachineId nvarchar(50))
Create Table #MachineID
	(
		Machine nvarchar(50),
		MachineId nvarchar(50),
		Component nvarchar(50),
		ComponentID nvarchar(50),
		Operation nvarchar(50),
		OperationID nvarchar(50),
		Operator nvarchar(50),
		OperatorID nvarchar(50)
	)
	Create Table #ComponentID(Component nvarchar(50),ComponentID nvarchar(50))
	Create Table #OperationID(Operation nvarchar(50),OperationID nvarchar(50))
	Create Table #OperatorID(Operator nvarchar(50),OperatorID nvarchar(50))
	Create Table #GetShiftTime(StartDateTime datetime,Shiftname NvarChar(50),StartTime datetime,EndTime datetime)
	Create table #Ratio ([ID] int IDENTITY(1,1),EndTime Datetime)


---mod 4 : To store PDTs
CREATE TABLE #PlannedDownTimesShift
	(
		SlNo int not null identity(1,1),
		Starttime datetime,
		EndTime datetime,
		DownReason nvarchar(50),
		ShiftSt datetime,
		Machine nvarchar(50)
	)
---mod 4
  
CREATE TABLE #T_autodata(  
 [mc] [nvarchar](50)not NULL,  
 [comp] [nvarchar](50) NULL,  
 [opn] [nvarchar](50) NULL,  
 [opr] [nvarchar](50) NULL,  
 [dcode] [nvarchar](50) NULL,  
 [sttime] [datetime] not NULL,  
 [ndtime] [datetime] not NULL,  
 [datatype] [tinyint] NULL ,  
 [cycletime] [int] NULL,  
 [loadunload] [int] NULL ,  
 [msttime] [datetime] not NULL,  
 [PartsCount] decimal(18,5) NULL ,  
 id  bigint not null  
)  
  
ALTER TABLE #T_autodata  
  
ADD PRIMARY KEY CLUSTERED  
(  
 mc,sttime,ndtime,msttime ASC  
)ON [PRIMARY]  
  
 Declare @T_ST AS Datetime 
Declare @T_ED AS Datetime 
Select @T_ST=dbo.f_GetLogicalDay(@StartDate,'START')
Select @T_ED=dbo.f_GetLogicalDay(@EndDate,'END')

  
Select @strsql=''  
select @strsql ='insert into #T_autodata '  
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'  
 select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'  
select @strsql = @strsql + ' from autodata where (( sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_ED,120)+''' ) OR '  
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' )OR '  
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ST,120)+'''  
     and ndtime<='''+convert(nvarchar(25),@T_ED,120)+''' )'  
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' and sttime<'''+convert(nvarchar(25),@T_ED,120)+''' ) )'  
print @strsql  
exec (@strsql)  

select @strmachine=''
select @strPlantID=''
select @StrGroupID=''

Declare @StrTPMMachines AS nvarchar(500) 
SELECT @StrTPMMachines=''

IF ( SELECT TOP 1 ValueInText FROM  CockpitDefaults WHERE Parameter='TpmEnbMac')='E'  
BEGIN  
 SET  @StrTPMMachines = ' AND MachineInformation.TPMTrakEnabled = 1 '  
END  
ELSE  
BEGIN  
 SET  @StrTPMMachines = ' '  
END 

If isnull(@Machine,'') <> ''
BEGIN
	---mod 3
--	SELECT @strmachine = ' AND ( Machineinformation.machineid = ''' + @Machine+ ''')'
	select @StrMCJoined =  (case when (coalesce( +@StrMCJoined + ',''', '''')) = ''''  then 'N''' else @StrMCJoined+',N''' end) +item+'''' from [SplitStrings](@Machine, ',')    
	if @StrMCJoined = 'N'''''  
	set @StrMCJoined = '' 
	select @Machine = @StrMCJoined

	SELECT @strmachine = ' AND ( Machineinformation.machineid in (' + @Machine+ '))'
	---mod 3
END
--print @strmachine
IF isnull(@Plant,'') <> ''
BEGIN
	---mod 3
--	SELECT @strPlantID = ' AND ( P.PlantID = ''' + @Plant+ ''')'
	SELECT @strPlantID = ' AND ( P.PlantID = N''' + @Plant+ ''')'
	---mod 3
END

if isnull(@GroupID,'')<> ''
Begin
	select @StrGroupJoined =  (case when (coalesce( +@StrGroupJoined + ',''', '''')) = ''''  then 'N''' else @StrGroupJoined+',N''' end) +item+'''' from [SplitStrings](@GroupID, ',')    
	if @StrGroupJoined = 'N'''''  
	set @StrGroupJoined = '' 
	select @GroupID = @StrGroupJoined

	SET @strGroupID = ' AND PlantMachineGroups.GroupID in (' + @GroupID +')'
End


if @Format = 1
Begin
	Select @StartDate = Convert(Nvarchar(5),Datepart(yyyy,@StartDate))+'-'+Convert(Nvarchar(5),Datepart(mm,@StartDate))+'-'+Convert(Nvarchar(5),Datepart(dd,@StartDate))
	Select @EndDate = Convert(Nvarchar(5),Datepart(yyyy,@EndDate))+'-'+Convert(Nvarchar(5),Datepart(mm,@EndDate))+'-'+Convert(Nvarchar(5),Datepart(dd,@EndDate))
	Select @TempDate = @StartDate
	while @TempDate <= @EndDate
	Begin
		Insert #GetShiftTime exec s_GetShiftTime @TempDate,@ShiftID	
		Select @TempDate = @TempDate + 1		
	End	
	
	select @StartTime=(select top 1 StartTime from #GetShiftTime order by  StartTime asc)
	select @EndTime=(select top 1 EndTime from #GetShiftTime order by  StartTime desc)
	
End

if @Format = 2
Begin
	select @StartTime=@StartDate
	select @EndTime=@EndDate
end
select @Strsql=''
select @Strsql='Insert #MachineID(ComponentID,Component,OperationID,Operation,OperatorID,Operator,Machine ,MachineID )
		select distinct autodata.comp,componentinformation.Componentid, autodata.opn,componentoperationpricing.OperationNO,
		autodata.opr,employeeinformation.employeeID,machineinformation.machineID,autodata.mc
		from #T_autodata autodata  inner join machineinformation on machineinformation.interfaceid=autodata.mc inner join
		componentinformation on autodata.comp=componentinformation.interfaceid
		inner join componentoperationpricing on componentoperationpricing.interfaceid=autodata.opn and
		componentinformation.componentid=componentoperationpricing.componentid '
		---mod 2
		select @Strsql= @Strsql +' and componentoperationpricing.machineid=machineinformation.machineid '
		---mod 2
		select @Strsql= @Strsql +'inner join employeeinformation  on employeeinformation.interfaceid=autodata.opr 
		left outer join PlantMachine P on machineinformation.machineid = P.MachineID
		LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = p.PlantID and PlantMachineGroups.machineid = p.MachineID
		where sttime >= ''' +convert(varchar(20),@T_ST,120)+ ''' and ndtime <= ''' + convert(varchar(20),@T_ED,120)+ ''''
		select @Strsql=@Strsql+@StrMachine + @StrTPMMachines + @strPlantID + @StrGroupID 
exec(@Strsql)
---------------------------------------------------------------------------------------------------------------------

IF @Format = 1
Begin
	
/*********************By Mrudula
	If @SheetNo = 2---------Major Break Downs > 30 minutes
	Begin
	Create table #GetCockpitData
	(
		Machine nvarchar(50),
		ProductionEfficiency float,
		AvailabilityEfficiency float,
		overAllEfficiency float,
		Components float,
		CN float,
		UtilisedTime float,
		TurnOver float,
		StrUtilisedtime nvarchar(50),
		Managementloss nvarchar(50),
		DownTime nvarchar(50),
		TotalTime nvarchar(50),
		ReturnPerHour float,
		ReturnPerHourTotal float,
		Remarks nvarchar(100),
		PEGreen int,
		PERed int,
		AEGreen int,
		AERed int,
		OEGreen int,
		OERed int,
		StartTime DateTime,
		EndTime DateTime,
		MaxReasonTime nvarchar(50)
	)****************/
	/*Create table #GetCockpitData
	(	Cday nvarchar(50),
		Shift nvarchar(50),
		Pdt datetime,
		Shiftnm nvarchar(50),
		StartTime DateTime,
		EndTime DateTime,
		Machine nvarchar(50),
		AvailabilityEfficiency float,
		ProductionEfficiency float,
		overAllEfficiency float,
		Components float,
		Rejection float
		
	)*/
	
	/***************Create table #Efficiency
		(
		[ID] int IDENTITY(1,1),
		[Date] DateTime,
		ShiftName nvarchar(50),
		StartTime DateTime,
		EndTime DateTime,
		Machine nvarchar(50),
		MachineID nvarchar(50)
		)
	
	
	Insert into #Efficiency select distinct  #GetShiftTime.StartDateTime,#GetShiftTime.Shiftname,#GetShiftTime.StartTime,
	#GetShiftTime.EndTime,#MachineID.Machine,#MachineID.MachineID from #GetShiftTime cross join #MachineID
	
	--select * from #GetCockpitData
	 --exec s_GetEfficiencyFromAutodata @StartDate,@EndDate,@Machine,@Plant,'','shift',@ShiftID,'cockpit'
	---Insert into #GetCockpitData(Cday,Shift,	Pdt ,Shiftnm ,StartTime ,EndTime ,Machine,AvailabilityEfficiency ,
		--ProductionEfficiency ,overAllEfficiency ,Components ,Rejection )
	  --exec s_GetEfficiencyFromAutodata @StartDate,@EndDate,'5b01',@Plant,'','shift','1','console'
	
--select 's_GetEfficiencyFromAutodata ''' + convert(nvarchar(20),@StartDate) + ''',''' +convert(nvarchar(20), @EndDate) + ''',''' +convert(nvarchar(50), @Machine) + ''',''' + convert(nvarchar(50),@Plant) + ''','',''shift'',''' + convert(nvarchar(50),@ShiftID) + ''',''console'''
	select @counter = (select max([ID]) from #Efficiency)
		--select * from #Efficiency
		
		While @counter >= (select min([ID]) from #Efficiency)
		Begin
			Select @StartTime='',@EndTime='',@Machine=''
			Select @StartTime=StartTime,@EndTime=EndTime,@Machine=Machine from #Efficiency Where [ID]=@counter
			print '@StartTime'
			print @StartTime
			print '@EndTime'
			print @EndTime
			print '@Machine'
			print @Machine
			Insert #GetCockpitData exec s_GetCockpitData @StartTime,@EndTime,@Machine,''
			Select @counter = @counter-1
		End
	
	
	--select * from #GetCockpitData
	--Select a.[Date],a.ShiftName,a.Machine,b.DownID,dbo.f_FormatTime(b.DownTime,'hh:mm:ss') as DownTime from #MajorBreakDowns a join #GetDownTimeMatrixfromAutoData b on a.StartTime=b.StartTime and a.Machine=b.MachineID order by a.[Date],a.ShiftName,a.Machine,b.DownID
	select a.[Date],a.ShiftName,a.Machine,b.AvailabilityEfficiency,b.ProductionEfficiency,b.overAllEfficiency from #Efficiency a join #GetCockpitData b on a.StartTime=b.StartTime and a.Machine=b.Machine order by a.[Date],a.ShiftName,a.Machine
	--s_GetCockpitData '2007-08-18','2007-08-19','MC01',''
	--s_GetCockpitData 'Aug 16 2007 10:00PM','Aug 17 2007  6:00AM','MC01',''
	--s_GetMando_Reports '2007-08-16','2007-08-18','','MC01','',2,1
	End****************************************/
	---------------------------------------------------------------------------------------------------------------------
	If @SheetNo = 3---------Major Break Downs > 30 minutes
	Begin
		
		Create table #MajorBreakDowns
		(
		[ID] int IDENTITY(1,1),
		[Date] DateTime,
		ShiftName nvarchar(50),
		StartTime DateTime,
		EndTime DateTime,
		Machine nvarchar(50),
		MachineID nvarchar(50),
		DownTime float default 0,
		DownID nvarchar(200),
		DownInt nvarchar(50)
		)
		
		Create table #MAchDwn
		(	
			DownID nvarchar(200),
			DownInt nvarchar(50)			
		)
	
		
		Insert into #MAchDwn(DownID,DownInt)
		SELECT distinct downcodeinformation.downid,downcodeinformation.InterfaceID   FROM  downcodeinformation
		
	
		insert into #MajorBreakDowns([Date],ShiftName,StartTime,EndTime,Machine,MachineID,DownID,DownInt)   select distinct
		 #GetShiftTime.StartDateTime,#GetShiftTime.Shiftname,#GetShiftTime.StartTime,
		#GetShiftTime.EndTime,#MachineID.Machine,#MachineID.MachineID,#MAchDwn.DownID,#MAchDwn.DownInt from #GetShiftTime cross join #MachineID cross join #MAchDwn
		
	
		update #MajorBreakDowns set DownTime=isnull(DownTime,0) + isnull(t2.down,0) from
		(SELECT #MajorBreakDowns.MachineID as mach,#MajorBreakDowns.DownInt as dwnInt,
		sum(case when (autodata.sttime>=#MajorBreakDowns.StartTime and autodata.ndtime<=#MajorBreakDowns.EndTime)
			 then loadunload
		     when  (autodata.sttime<#MajorBreakDowns.StartTime and autodata.ndtime>#MajorBreakDowns.StartTime and autodata.ndtime<=#MajorBreakDowns.EndTime)
			then DateDiff(second,#MajorBreakDowns.StartTime, ndtime)
		     when (autodata.sttime>=#MajorBreakDowns.StartTime and autodata.sttime<#MajorBreakDowns.EndTime and autodata.ndtime>#MajorBreakDowns.EndTime)		         then DateDiff(second,sttime, #MajorBreakDowns.EndTime)
		     when (autodata.sttime<#MajorBreakDowns.StartTime and autodata.ndtime>#MajorBreakDowns.EndTime)
		         then DateDiff(second,#MajorBreakDowns.StartTime, #MajorBreakDowns.EndTime) end )as down,
		 #MajorBreakDowns.StartTime as strt,#MajorBreakDowns.EndTime as ndtime from #T_autodata autodata INNER JOIN #MajorBreakDowns
		on #MajorBreakDowns.MachineID=autodata.mc and #MajorBreakDowns.DownInt=autodata.dcode where
		((autodata.sttime>=#MajorBreakDowns.StartTime and autodata.ndtime<=#MajorBreakDowns.EndTime)
		or (autodata.sttime<#MajorBreakDowns.StartTime and autodata.ndtime>#MajorBreakDowns.StartTime and autodata.ndtime<=#MajorBreakDowns.EndTime)
		 or (autodata.sttime>=#MajorBreakDowns.StartTime and autodata.sttime<#MajorBreakDowns.EndTime and autodata.ndtime>#MajorBreakDowns.EndTime)
		 or (autodata.sttime<#MajorBreakDowns.StartTime and autodata.ndtime>#MajorBreakDowns.EndTime)) and autodata.datatype=2
		group by #MajorBreakDowns.MachineID,#MajorBreakDowns.DownInt,#MajorBreakDowns.StartTime,#MajorBreakDowns.EndTime
		)as t2 inner join #MajorBreakDowns on #MajorBreakDowns.MachineID=t2.mach and #MajorBreakDowns.DownInt=T2.dwnInt
		and #MajorBreakDowns.StartTime=T2.strt and #MajorBreakDowns.EndTime=T2.ndtime
		
		
		
		---mod 4: Ignore PDT if Ignore Dtime is equal to yes
		if (select valueintext from cockpitdefaults  where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
		BEGIN
			
			-- Get the PlannedDwnTImes
			select @strsql=' insert INTO #PlannedDownTimesShift(StartTime,EndTime,Downreason,Shiftst,Machine)
			SELECT 
			CASE When P.StartTime<S.StartTime Then S.StartTime  Else P.StartTime End As StartTime,
			CASE When P.EndTime>S.EndTime  Then S.EndTime  Else P.EndTime End As EndTime,DownReason,S.StartTime,Machine
			FROM PlannedDownTimes P
			inner join machineinformation on p.Machine=machineinformation.machineid
			LEFT OUTER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID
			LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID
			cross join #GetShiftTime S
			WHERE P.Pdtstatus=1 and  (
			(P.StartTime >= S.StartTime  AND P.EndTime <=S.EndTime) 
			OR ( P.StartTime < S.StartTime  AND P.EndTime <= S.EndTime AND P.EndTime > S.StartTime )
			OR ( P.StartTime >= S.StartTime   AND P.StartTime <S.EndTime AND P.EndTime > S.EndTime )
			OR ( P.StartTime < S.StartTime  AND P.EndTime >S.EndTime) )'
			--if isnull(@Machine,'')<>''
			--begin
			--	select @strsql=@strsql+' AND (P.machine =N'''+@Machine+''') ' 
			--ENd
			if isnull(@Machine,'')<>''
			begin
				select @strsql=@strsql + @strmachine 
			ENd
			if isnull(@GroupID,'')<>''
			begin
				select @strsql=@strsql + @StrGroupID
			ENd
			select @strsql=@strsql+ @StrTPMMachines + ' ORDER BY P.StartTime'
			print @strsql
			exec (@strsql)

			Select @strsql=''
			Select @strsql= 'UPDATE #MajorBreakDowns SET downtime = isnull(downtime,0) - isNull(t2.PldDown,0) '
			Select @strsql= @strsql+ 'from(
						select T.Shiftst  as intime,machineinformation.Machineid as machine,Downcodeinformation.DownID as inDwn,SUM
						       (CASE
							WHEN (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN autodata.loadunload
							WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
							WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
							WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
							END ) as PldDown
						from #T_autodata autodata  
						INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID
						INNER JOIN machineinformation  ON autodata.mc = machineinformation.InterfaceID
						LEFT OUTER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID
						 LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID
						INNER jOIN #PlannedDownTimesShift T  on T.Machine=machineinformation.MachineID
						WHERE autodata.DataType=2  AND( 
						(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime) 
						OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
						OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
						OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime) 
						) '
					If isnull(@Machine,'') <> ''
					BEGIN
						select @strsql = @strsql  + @strmachine 
					END

					if isnull(@GroupID,'')<>''
					begin
						select @strsql=@strsql + @StrGroupID
					ENd


					if isnull(@Plant,'') <> ''
					BEGIN
						Select @strsql = @strsql + @StrTPMMachines +  ' ANd PlantMachine.Plantid='''+ @Plant +''' ' 
					END
			
				
					If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y' AND (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' 
					BEGIN
						Select @strsql = @strsql  +' AND Downcodeinformation.DownID=(SELECT ValueInText From CockpitDefaults Where Parameter =''Ignore_Dtime_4m_PLD'')'
					END
					
					Select @strsql = @strsql  +' group by machineinformation.Machineid,T.ShiftSt,Downcodeinformation.DownID ) as t2 inner join 
					#MajorBreakDowns S on t2.intime=S.StartTime and t2.machine=S.machine and t2.inDwn=S.DownID '

			exec (@strsql)
			print @strsql

		END
		---mod 4
		
		delete from #MajorBreakDowns where DownTime < 1800
		select a.[Date],a.ShiftName,a.Machine,a.DownID,dbo.f_FormatTime(a.DownTime,'hh:mm:ss') as DownTime  from  #MajorBreakDowns a
		
		
		
	End
	----------------------------End of Sheet 3-----------------------------------------------------------------------------------------
	If @SheetNo = 4----------EndTime to Endtime Ratio (MCO Level)		
	Begin
	
		create Table #AvgCompTime
		(	[ID] int IDENTITY(1,1),
			[Date] Datetime,
			ShiftName  nvarchar(50),
			StartTime Datetime,
			EndTime Datetime,
			Machine nvarchar(50),
			MachineID nvarchar(50),
			Component nvarchar(50),
			ComponentID nvarchar(50),
			Operation nvarchar(50),
			OperationID nvarchar(50),
			Ratio float
		)
		if @StartDate = @EndDate
		Begin
		select @EndDate = @StartDate + 2
		End
	
		Insert into #AvgCompTime ([Date],ShiftName,StartTime,EndTime,Machine,MachineID,Component,ComponentID,Operation,OperationID)
		
		  select distinct
		 #GetShiftTime.StartDateTime,#GetShiftTime.Shiftname,#GetShiftTime.StartTime,
		#GetShiftTime.EndTime,#MachineID.Machine,#MachineID.MachineID,#MachineID.Component,
		#MachineID.ComponentID,#MachineID.Operation,#MachineID.OperationID from #GetShiftTime cross join #MachineID
	--	select * from #GetShiftTime	
	
	
		select @counter = (select max([ID]) from #AvgCompTime)
	
		While @counter >= (select min([ID]) from #AvgCompTime)
		Begin
			Select @StartTime='',@EndTime='',@mc='',@comp='',@opn=''
			
			Select @StartTime=StartTime,@EndTime=EndTime,@mc=MachineID,@comp=ComponentID,@opn=OperationID from #AvgCompTime where [ID] = @counter
			
			delete from #Ratio
			
			insert into #Ratio (EndTime) select ndtime from #T_autodata autodata where mc = @mc
			and comp = @comp and opn = @opn and ndtime >= @StartTime and ndtime <= @EndTime and datatype = 1 order by ndtime
			Update #AvgCompTime set Ratio = IsNull((select sum(Datediff(ss,b.Endtime,a.Endtime))/count(*) from #Ratio
			a join #Ratio b on a.[ID] = b.[ID]+1),0) where [ID]=@counter
			
			select @counter = @counter -1
		End
	
		Select [Date],ShiftName,
		Machine,Component,Operation,Ratio from #AvgCompTime
	
	End
End
IF @Format = 2 And @SheetNo =1
Begin
	CREATE TABLE #Exceptions
	(
		HrStart datetime,
		HrEnd datetime,
		MachineID NVarChar(50),
		ComponentID Nvarchar(50),
		OperationNo Int,
		StartTime DateTime,
		EndTime DateTime,
		IdealCount Int,
		ActualCount Int,
		ExCount Int
	)
	Create Table #Date(
				[ID] int IDENTITY(1,1),
				[Date] DateTime
			  )
	Create Table #Time
	(
	     [ID] int IDENTITY(1,1),
	     StartTime DateTime,
	     EndTime DateTime,
	     RowHeader nvarchar(50),
	     RowValue nvarchar(50)
	)
	--Select @TempDate = @StartDate
	--While @TempDate <= @EndDate
	--Begin
	--	Insert #Date Select @TempDate
	--	Select @TempDate = DateAdd(hh,1,@TempDate)
	--End
	--select * from #Date
	Create Table #FinalOutput(
				[ID] int IDENTITY(1,1),
				TimeID int,
				StartTime DateTime,
				EndTime DateTime,
				Machine nvarchar(50),
				MachineID nvarchar(50),
				Component nvarchar(50),
				ComponentID nvarchar(50),
				Operation nvarchar(50),
				OperationID nvarchar(50),
				Operator nvarchar(50),
				OperatorID nvarchar(50),
				RowHeader nvarchar(50),
				RowValue nvarchar(50)
				)
--Insert #Time (StartTime,EndTime)Select a.[Date],b.[Date] from #Date a join #Date b on a.[ID]=b.[ID]-1
Select @TempDate = @StartDate
print @enddate
	While @TempDate < @EndDate
	Begin
	print '-------while ----'
	print @TempDate
		select @ShiftStartDay = CAST(datePart(yyyy,@TempDate) AS nvarchar(4)) + '-' + CAST(datePart(mm,@TempDate) AS nvarchar(2)) + '-' + CAST(datePart(dd,@TempDate) AS nvarchar(2)) 
		Insert #Time (StartTime,EndTime)
		select 
		dateadd(day,SH.Fromday,(convert(datetime, @ShiftStartDay + ' ' + CAST(datePart(hh,SH.HourStart) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourStart) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourStart) as nvarchar(2))))),
		dateadd(day,SH.Today,(convert(datetime, @ShiftStartDay + ' ' + CAST(datePart(hh,SH.HourEnd) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourEnd) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourEnd) as nvarchar(2)))))
		from (Select * from shiftdetails where running=1) S inner join Shifthourdefinition SH on SH.shiftid=S.Shiftid
		order by S.Shiftid,SH.Hourid
	  Select @TempDate = DateAdd(day,1,@TempDate)
 End
	Insert #Time (StartTime,EndTime,RowHeader) Select min(StartTime),max(EndTime),'Total Output' from #Time
	Insert #Time (StartTime,EndTime,RowHeader) Select min(StartTime),max(EndTime),'DownTime' from #Time

	declare @strXmachine as nvarchar(200)
	select @strXmachine=''
	if isnull(@machine,'') <> ''
	begin
		---mod 2
--		select @strXmachine = ' and ( EX.MachineID = ''' + @Machine + ''')'
		--select @strXmachine = ' and ( EX.MachineID = N''' + @Machine + ''')'
		select @strXmachine = ' and ( EX.MachineID in (' + @Machine+ '))'
		
		---mod 2
	end
	declare @rcount as integer
	declare @tcount as integer
	declare @CountStart as  datetime
	declare @CountEnd as datetime
	declare @MCID as nvarchar(50)
	declare @CompID as nvarchar(50)
	declare @OpnNO as integer
	select @tcount=(select top 1 [ID] from #Time order by [ID] desc)
	select @rcount=1
	
	while @rcount<=(@tcount-2)
	begin
		select @CountStart=(select StartTime from #Time where [ID]=@rcount)
		select @CountEnd=(select EndTime from #Time where [ID]=@rcount)
		select @StrSql=''
		SELECT @StrSql = 'INSERT INTO #Exceptions(HrStart,HrEnd,MachineID ,ComponentID,OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,ExCount )
			SELECT ''' + convert(nvarchar(20),@CountStart,120)+''',''' + convert(nvarchar(20),@CountEnd,120)+''',Ex.MachineID ,Ex.ComponentID,Ex.OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,0
			From ProductionCountException Ex
			Inner Join MachineInformation M ON Ex.MachineID=M.MachineID
			Inner Join ComponentInformation C ON Ex.ComponentID=C.ComponentID
			Inner Join Componentoperationpricing O ON Ex.OperationNo=O.OperationNo AND C.ComponentID=O.ComponentID '
			---mod 2
			select @Strsql=@Strsql+' and O.machineid=M.machineid'
			---mod 2
			select @Strsql=@Strsql+' WHERE  M.MultiSpindleFlag=1 AND
			((Ex.StartTime>=  ''' + convert(nvarchar(20),@CountStart,120)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@CountEnd,120)+''' )
			OR (Ex.StartTime< ''' + convert(nvarchar(20),@CountStart,120)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@CountStart,120)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@CountEnd,120)+''')
			OR(Ex.StartTime>= ''' + convert(nvarchar(20),@CountStart,120)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@CountEnd,120)+''' AND Ex.StartTime< ''' + convert(nvarchar(20),@CountEnd,120)+''')
			OR(Ex.StartTime< ''' + convert(nvarchar(20),@CountStart,120)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@CountEnd,120)+''' ))'
		SELECT @StrSql =@StrSql+@strXmachine
		Exec (@strsql)

		select @rcount=@rcount+1
	end
		

	--mod 4:Get the PlannedDwnTImes
	select @strsql=' insert INTO #PlannedDownTimesShift(StartTime,EndTime,Downreason,Shiftst,Machine)
	SELECT 
	CASE When P.StartTime<S.StartTime Then S.StartTime  Else P.StartTime End As StartTime,
	CASE When P.EndTime>S.EndTime  Then S.EndTime  Else P.EndTime End As EndTime,DownReason,S.StartTime,Machine
	FROM PlannedDownTimes P Cross join  #Time  S 
	WHERE P.Pdtstatus=1 and  (
	(P.StartTime >= S.StartTime  AND P.EndTime <=S.EndTime) 
	OR ( P.StartTime < S.StartTime  AND P.EndTime <= S.EndTime AND P.EndTime > S.StartTime )
	OR ( P.StartTime >= S.StartTime   AND P.StartTime <S.EndTime AND P.EndTime > S.EndTime )
	OR ( P.StartTime < S.StartTime  AND P.EndTime >S.EndTime) ) and S.RowHeader is null '
	if isnull(@Machine,'')<>''
	begin
		--select @strsql=@strsql+' AND (P.machine =N'''+@Machine+''') ' 
		select @strsql=@strsql+' AND (P.machine in (' + @Machine+ ')) ' 
		
	ENd
	select @strsql=@strsql+' ORDER BY P.StartTime'
	print @strsql
	exec (@strsql)
	
	
	---mod 4
	
	IF (SELECT Count(*) from #Exceptions) <> 0
	BEGIN
		UPDATE #Exceptions SET StartTime=HrStart WHERE (StartTime<HrStart)AND EndTime>HrStart
		UPDATE #Exceptions SET EndTime=HrEnd WHERE (EndTime>HrEnd AND StartTime<HrEnd )
				
		Update #Exceptions set ExCount = t1.Tcount from (
		select CAST(CEILING(CAST(sum(autodata.partscount)AS Float)/ISNULL(componentoperationpricing.SubOperations,1)) AS INTEGER) as Tcount,
		#Exceptions.MachineID as machid,#Exceptions.ComponentID as compID,
		#Exceptions.OperationNo as opnID, #Exceptions.StartTime as strt,#Exceptions.EndTime as endt,
		#Exceptions.HrStart as HourStart,#Exceptions.HrEnd as HourEnd
		 from #T_autodata autodata inner join machineinformation on autodata.mc=machineinformation.interfaceid inner join  componentinformation on autodata.comp=componentinformation.interfaceid
		inner join  componentoperationpricing on componentinformation.componentid=componentoperationpricing.componentid and
		componentoperationpricing.interfaceid=autodata.opn and componentoperationpricing.machineID=machineinformation.machineid
		inner join #Exceptions on machineinformation.machineid=#Exceptions.MachineID
		and  componentinformation.componentid=#Exceptions.componentID
		and componentoperationpricing.operationno=#Exceptions.OperationNo
		where  (autodata.ndtime > #Exceptions.StartTime)AND (autodata.ndtime <= #Exceptions.EndTime )
		 group by componentoperationpricing.SubOperations
		,#Exceptions.MachineID,#Exceptions.ComponentID,#Exceptions.OperationNo,#Exceptions.StartTime,#Exceptions.EndTime,#Exceptions.HrStart,#Exceptions.HrEnd) as T1 inner join
		#Exceptions on #Exceptions.StartTime=T1.strt and #Exceptions.EndTime=T1.endt and
		#Exceptions.MachineID=T1.machid  and #Exceptions.ComponentID =T1.compID and
		#Exceptions.OperationNo=T1.opnID and #Exceptions.HrStart=T1.HourStart and #Exceptions.HrEnd=T1.HourEnd

		
		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
		BEGIN
		
		Select @StrSql =''
		Select @StrSql ='UPDATE #Exceptions SET ExCount=ISNULL(ExCount,0) - ISNULL(T3.Comp,0)
		From
		(
			SELECT T2.shst as shiftst,T2.MachineID AS MachineID,T2.ComponentID,T2.OperationNo,T2.StartTime AS StartTime,T2.EndTime AS EndTime,
			SUM(CEILING (CAST(T2.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp 
			From 
			(
				select T1.strtshift as  shst,MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,comp,opn,
				Max(T1.XStartTime)StartTime,Max(T1.XEndTime)EndTime,T1.PLD_StartTime,T1.PLD_EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from #T_autodata autodata 
				Inner Join MachineInformation   ON autodata.MC=MachineInformation.InterfaceID 
				LEFT OUTER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID
				LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID
				Inner Join ComponentInformation  ON autodata.Comp = ComponentInformation.InterfaceID
				Inner Join ComponentOperationPricing on autodata.Opn=ComponentOperationPricing.InterfaceID And ComponentInformation.ComponentID=ComponentOperationPricing.ComponentID
				Inner Join	
				(
					SELECT Td.Shiftst as strtshift,MachineID,ComponentID,OperationNo,Ex.StartTime As XStartTime, Ex.EndTime AS XEndTime,
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
		
					From #Exceptions AS Ex inner  JOIN #PlannedDownTimesShift AS Td on Td.Shiftst=Ex.HrStart and Td.Machine=Ex.MachineID
					Where ((Td.StartTime>=Ex.StartTime And Td.EndTime <=Ex.EndTime)OR
					(Td.StartTime< Ex.StartTime And Td.EndTime<=Ex.EndTime AND Td.EndTime>Ex.StartTime)OR
					(Td.StartTime>= Ex.StartTime And Td.StartTime <Ex.EndTime AND Td.EndTime>Ex.EndTime)OR
					(Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime))'
			Select @StrSql = @StrSql + @strXmachine + @StrGroupID
			Select @StrSql = @StrSql + ' )AS T1 ON T1.MachineID=MachineInformation.MachineID AND T1.ComponentID = ComponentInformation.ComponentID AND T1.OperationNo= ComponentOperationPricing.OperationNo and T1.MachineID=ComponentOperationPricing.MachineID
				Where (autodata.ndtime>T1.PLD_StartTime AND autodata.ndtime<=T1.PLD_EndTime) and (autodata.datatype=1) '
			Select @StrSql = @StrSql + @StrMachine + @StrTPMMachines + @StrGroupID
			Select @StrSql = @StrSql+' Group by MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,T1.PLD_StartTime,T1.PLD_EndTime,comp,opn,T1.strtshift
			)AS T2 
			Inner join componentinformation C on T2.Comp=C.interfaceid 
			Inner join ComponentOperationPricing O ON T2.Opn=O.interfaceid and C.Componentid=O.componentid  and O.MachineID=T2.MachineID
			GROUP BY T2.MachineID,T2.ComponentID,T2.OperationNo,T2.StartTime,t2.EndTime,T2.shst
		)As T3
		WHERE  #Exceptions.StartTime=T3.StartTime AND #Exceptions.EndTime=T3.EndTime 
		AND #Exceptions.MachineID=T3.MachineID AND #Exceptions.ComponentID = T3.ComponentID AND #Exceptions.OperationNo=T3.OperationNo
		and #Exceptions.HrStart=T3.shiftst'
		PRINT @StrSql
		EXEC(@StrSql)
		
		END 

		UPDATE #Exceptions SET ExCount=ExCount-((ExCount * ActualCount)/ISNULL(IdealCount,0))
		
	END
	
	
		-- select * from #Time

	Insert #FinalOutput(TimeID,StartTime,EndTime,RowHeader,RowValue,Machine,MachineID,Component,ComponentID,Operation,OperationID,Operator,OperatorID)
	Select t.[ID],t.StartTime,t.EndTime,t.RowHeader,t.RowValue,m.Machine,m.MachineId,m.Component,
	m.ComponentID,m.Operation,m.OperationID,m.Operator,m.OperatorID from #Time t cross join #MachineID m
	

	

	Update #FinalOutput Set RowHeader =
	Case Len(convert(Nvarchar(2),Datepart(hh,StartTime))) When 1 then '0'+convert(Nvarchar(2),Datepart(hh,StartTime))Else convert(Nvarchar(2),Datepart(hh,StartTime)) End +':'+
	Case Len(convert(Nvarchar(2),Datepart(n,StartTime))) When 1 then '0'+convert(Nvarchar(2),Datepart(n,StartTime))Else convert(Nvarchar(2),Datepart(n,StartTime)) End+' - '+
	Case Len(convert(Nvarchar(2),Datepart(hh,EndTime))) When 1 then '0'+convert(Nvarchar(2),Datepart(hh,EndTime))Else convert(Nvarchar(2),Datepart(hh,EndTime)) End +':'+
	Case Len(convert(Nvarchar(2),Datepart(n,EndTime))) When 1 then '0'+convert(Nvarchar(2),Datepart(n,EndTime))Else convert(Nvarchar(2),Datepart(n,EndTime)) End where RowHeader is Null
	
	Update #FINALOUTPUT set RowValue = t1.Tcount from (select CAST(CAST(sum(autodata.partscount)AS Float)/ISNULL(componentoperationpricing.SubOperations,1) AS float) as Tcount,
	#FINALOUTPUT.MachineID as machid,#FINALOUTPUT.OperatorID as oprID,#FINALOUTPUT.ComponentID as compID,
	#FINALOUTPUT.OperationID as opnID, #FINALOUTPUT.StartTime as strt,#FINALOUTPUT.EndTime as endt
	 from #T_autodata autodata inner join  #FINALOUTPUT on autodata.mc=#FINALOUTPUT.MachineID
	and autodata.opr=#FINALOUTPUT.OperatorID and autodata.comp= #FINALOUTPUT.ComponentID and
	autodata.opn= #FINALOUTPUT.OperationID inner join componentinformation on autodata.comp=componentinformation.interfaceid
	and componentinformation.componentid=#FINALOUTPUT.component
	inner join  componentoperationpricing on componentinformation.componentid=componentoperationpricing.componentid and
	Componentoperationpricing.interfaceid=autodata.opn and componentoperationpricing.operationno=#FINALOUTPUT.operation
	---mod 2
	inner join machineinformation on #FINALOUTPUT.machineid=machineinformation.interfaceid
	and Componentoperationpricing.machineid=machineinformation.machineid
	---mod 2
	where  (autodata.ndtime > #FINALOUTPUT.StartTime)AND (autodata.ndtime <= #FINALOUTPUT.EndTime ) and
	#FINALOUTPUT.RowHeader not in('Total Output','DownTime')
	 group by componentoperationpricing.SubOperations
	,#FINALOUTPUT.MachineID,#FINALOUTPUT.OperatorID,#FINALOUTPUT.ComponentID,#FINALOUTPUT.OperationID,#FINALOUTPUT.StartTime,#FINALOUTPUT.EndTime ) as T1 inner join
	#FINALOUTPUT on #FINALOUTPUT.StartTime=T1.strt and #FINALOUTPUT.EndTime=T1.endt and
	#FINALOUTPUT.MachineID=T1.machid and #FINALOUTPUT.OperatorID =T1.oprID and #FINALOUTPUT.ComponentID =T1.compID and
	#FINALOUTPUT.OperationID=T1.opnID where #FINALOUTPUT.RowHeader not in('Total Output','DownTime')
	
	
	
	---mod 4:Correct Exception Count Calculation
	/*UPDATE #FINALOUTPUT SET RowValue=isnull(RowValue,0)-ISNULL(T1.Xcount,0)
	From(
		SELECT HrStart as HourStart,HrEnd as HourEnd,Min(StartTime)StartTime,Max(EndTime)EndTime,MachineID,ComponentID,OperationNo,SUM(ExCount)Xcount
		FROM #Exceptions
			GROUP BY MachineID,ComponentID,OperationNo,HrStart,HrEnd
	)T1 Inner Join #FINALOUTPUT ON
	T1.MachineID=#FINALOUTPUT.machine AND T1.ComponentID=#FINALOUTPUT.component
	AND T1.OperationNo=#FINALOUTPUT.operation AND #FINALOUTPUT.StartTime=T1.HourStart and
	#FINALOUTPUT.EndTime= T1.HourEnd where #FINALOUTPUT.RowHeader not in('Total Output','DownTime')*/
	
		

	

	---mod 4:Correct Exception Count Calculation
	
	---mod 4: Negelect count from PDT
	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
	BEGIN
		



		UPDATE #FINALOUTPUT SET RowValue = ISNULL(RowValue,0) - ISNULL(T2.compcnt,0)
		from
		( select T.Shiftst as hrst ,#FINALOUTPUT.MachineID as mach,CAST(CAST(sum(autodata.partscount)AS Float)/ISNULL(O.SubOperations,1) AS float) as compcnt ,
		#FINALOUTPUT.ComponentID as compn,#FINALOUTPUT.OperationID as oprn,#FINALOUTPUT.OperatorID as oprd from #T_autodata autodata 
		inner join machineinformation M on M.Interfaceid=autodata.mc
		Inner join componentinformation C on autodata.Comp=C.interfaceid 
		   Inner join ComponentOperationPricing O ON autodata.Opn=O.interfaceid and C.Componentid=O.componentid  and O.Machineid=M.Machineid 
		Inner jOIN #PlannedDownTimesShift T on T.Machine=M.MachineID inner join #FINALOUTPUT on #FINALOUTPUT.MachineID=autodata.mc and #FINALOUTPUT.OperatorID=autodata.opr and
		#FINALOUTPUT.ComponentID=autodata.comp and #FINALOUTPUT.OperationID=autodata.opn and T.Shiftst=#FINALOUTPUT.StartTime 
		WHERE autodata.DataType=1 
			AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime) 
			AND (autodata.ndtime > #FINALOUTPUT.StartTime  AND autodata.ndtime <=#FINALOUTPUT.EndTime) 
			and #FINALOUTPUT.RowHeader not in('Total Output','DownTime')
		   Group by #FINALOUTPUT.MachineID,#FINALOUTPUT.ComponentID,#FINALOUTPUT.OperationID,#FINALOUTPUT.OperatorID,T.Shiftst,O.SubOperations
	  
		) as T2 inner join #FINALOUTPUT on T2.mach = #FINALOUTPUT.machineiD and #FINALOUTPUT.StartTime=T2.hrst and
		#FINALOUTPUT.componentID=T2.compn and #FINALOUTPUT.OperatorID=T2.oprd and #FINALOUTPUT.OperationID=T2.oprn
		where #FINALOUTPUT.RowHeader not in('Total Output','DownTime')--and #FINALOUTPUT.RowValue>0
	END



	Update #FINALOUTPUT SET RowValue=isnull(RowValue,0)-ISNULL(Tt.Xcount,0)
       FROM
      (	SELECT #FINALOUTPUT.Machine as machid,#FINALOUTPUT.Operator as oprID,#FINALOUTPUT.Component as compID,
	#FINALOUTPUT.Operation as opnID, #FINALOUTPUT.StartTime as strt,#FINALOUTPUT.EndTime as endt ,(cast(RowValue as float)-(cast(RowValue as float)*(Ti.Ratio)))AS Xcount
	FROM #FINALOUTPUT Left Outer Join
	(
		SELECT HrStart as HourStart,HrEnd as HourEnd,Min(StartTime)StartTime,Max(EndTime)EndTime,#Exceptions.MachineID,#Exceptions.ComponentID,#Exceptions.OperationNo,CAST(CAST (SUM(ExCount) AS FLOAT)/CAST(Max(T1.tCount)AS FLOAT )AS FLOAT) AS Ratio
		FROM #Exceptions
			 Inner Join ( select 
				#FINALOUTPUT.Machine as machid,#FINALOUTPUT.Component as compID,
				#FINALOUTPUT.Operation as opnID, #FINALOUTPUT.StartTime as strt,#FINALOUTPUT.EndTime as endt, SUM(convert(float,RowValue)) AS tCount
				FROM #FINALOUTPUT  where #FINALOUTPUT.RowHeader not in('Total Output','DownTime') 
				Group By #FINALOUTPUT.Machine  ,#FINALOUTPUT.Component ,#FINALOUTPUT.Operation, #FINALOUTPUT.StartTime,#FINALOUTPUT.EndTime 
				)T1 ON  T1.machid=#Exceptions.MachineID AND T1.compID=#Exceptions.Componentid AND T1.opnID=#Exceptions.OperationNo and  #Exceptions.HrStart=T1.strt
		GROUP BY MachineID,ComponentID,OperationNo,HrStart,HrEnd
	)Ti ON Ti.MachineID=#FINALOUTPUT.Machine AND Ti.Componentid=#FINALOUTPUT.Component AND Ti.OperationNo=#FINALOUTPUT.Operation and Ti.HourStart=#FINALOUTPUT.StartTime
	where #FINALOUTPUT.RowHeader not in('Total Output','DownTime')
)AS Tt inner join #FINALOUTPUT on #FINALOUTPUT.StartTime=Tt.strt and #FINALOUTPUT.EndTime=Tt.endt and
	#FINALOUTPUT.Machine=Tt.machid and #FINALOUTPUT.Operator =Tt.oprID and #FINALOUTPUT.Component =Tt.compID and
	#FINALOUTPUT.Operation=Tt.opnID where #FINALOUTPUT.RowHeader not in('Total Output','DownTime')
	and cast(RowValue as float)>0

	---mod 4
	
	
	Update #FinalOutput Set RowValue = t1.TotOutput from
	(select machine,component,operation,operator,sum(convert(float,rowvalue)) as TotOutput from #FinalOutput group by machine,component,operation,operator)
	as t1 inner join #FinalOutput fo on t1.machine=fo.Machine and t1.component=fo.Component and t1.operation=fo.Operation and t1.operator=fo.operator where RowHeader='Total Output'
	

	Update #FinalOutput Set RowValue =isnull(t1.DownTime,0) from
	(select mc,sum(case
	when sttime<@T_ST and sttime<@EndDate and ndtime>@T_ST and ndtime<@EndDate  then datediff(second,@T_ST,ndtime)
	when sttime>=@T_ST and sttime<@EndDate and ndtime>@T_ST and ndtime<=@EndDate  then datediff(second,sttime,ndtime)
	when sttime>@T_ST and sttime<@EndDate and ndtime>@T_ST and ndtime>@EndDate  then datediff(second,sttime,@EndDate)
	when sttime<@T_ST and sttime<@EndDate and ndtime>@T_ST and ndtime>@EndDate  then datediff(second,@T_ST,@EndDate)
	else 0 end)as DownTime  from #T_autodata autodata where (datatype = 2 ) and (sttime<@EndDate and ndtime>@T_ST)
	group by mc) as t1 inner join #FinalOutput on t1.mc=#FinalOutput.MachineID where Rowheader='DownTime'

		
	---Ignore Pld from DownTime based on the settings
	if (select valueintext from cockpitdefaults where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
	BEGIN
		
		Select @strsql=''
		Select @strsql= 'UPDATE #FinalOutput Set RowValue = isnull(RowValue,0) - isNull(t2.PldDown,0) '
		Select @strsql= @strsql+ 'from(
						select M.InterfaceId as machine,SUM
						       (CASE
							WHEN (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN autodata.loadunload
							WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
							WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
							WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
							END ) as PldDown
						from #T_autodata autodata 
						INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID
						INNER JOIN machineinformation M ON autodata.mc = M.InterfaceID 
						Inner jOIN #PlannedDownTimesShift T on T.Machine=M.MachineId
						Left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
						WHERE autodata.DataType=2  AND( 
						(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime) 
						OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
						OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
						OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime) 
						) '
		If isnull(@Machine,'') <> ''
		BEGIN
			--select @strsql = @strsql  + ' AND ( M.machineid = ''' + @Machine+ ''')'
			select @strsql = @strsql  + ' AND ( M.machineid in (' + @Machine+ '))'
			
		END
		if isnull(@Plant,'') <> ''
		BEGIN
			Select @strsql = @strsql  +  ' ANd PlantMachine.Plantid='''+ @Plant +''' ' 
		END
		
			
		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y' AND (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' 
		BEGIN
			Select @strsql = @strsql  +' AND Downcodeinformation.DownID=(SELECT ValueInText From CockpitDefaults Where Parameter =''Ignore_Dtime_4m_PLD'')'
		END
		
		

		Select @strsql = @strsql  +' group by M.InterfaceId) as t2 inner join 
		#FinalOutput S on   S.machineID=T2.machine  Where S.Rowheader=''DownTime'''

		exec (@strsql)
		print @strsql

			
	END

	
	
	Update #FinalOutput Set RowValue =dbo.f_FormatTime(isnull(RowValue,0),'hh:mm:ss') where RowHeader='DownTime'
	
	Update #FinalOutput Set RowValue = isnull(RowValue,0)
	
	Select StartTime,EndTime,Machine,Component,Operation,operator,TimeID,RowHeader,RowValue from #FinalOutput order by Machine,Component,operation,operator,TimeID,StartTime
End
End
