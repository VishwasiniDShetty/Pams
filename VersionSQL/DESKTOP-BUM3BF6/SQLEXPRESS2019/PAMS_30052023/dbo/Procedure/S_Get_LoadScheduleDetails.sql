/****** Object:  Procedure [dbo].[S_Get_LoadScheduleDetails]    Committed by VersionSQL https://www.versionsql.com ******/

/*
EXEC [dbo].[S_Get_LoadScheduleDetails] '2020-08-01','2020-08-01','HMC-13','''3906749-DX04'',''5687341-DX02''','''20''','','','','','','View'
exec S_Get_LoadScheduleDetails @StartDate=N'2020-08-03',@EndDate=N'2020-08-04',@MachineId=N'',@ComponentId=N'''''',@OperationId=N'''20''',@Param=N'view'

exec S_Get_LoadScheduleDetails @StartDate=N'2021-07-31',@EndDate=N'2021-08-01',@MachineId=N'Cleaning Shuttle-1',@ComponentId=N'',@OperationId=N'',@Param=N'View'

*/

CREATE PROCEDURE [dbo].[S_Get_LoadScheduleDetails]
@StartDate DateTime,
@EndDate DateTime,

@MachineId nvarchar(50)='',
@ComponentId nvarchar(max)='',
@OperationId nvarchar(max)='',
@Shift nvarchar(50)='',
@PDT int=0,
@StdCycleTime float=0,
@ShiftTarget float=0,
@IdealCount float=0,
@Param nvarchar(50)=''

AS
Begin
Declare @Strsql nvarchar(4000),   
	 @Strmachine nvarchar(255),
	 @StrmachineID nvarchar(255), 
	 @StrComponent as nvarchar(max),
	 @StrOperation as nvarchar(max)
    
Select @Strsql = ''      
Select @Strmachine = '' 
Select @StrmachineID = ''
Select @StrComponent=''
Select @StrOperation=''


IF @Param = 'View'
BEGIN

		If isnull(@MachineId,'') <> ''    
		Begin    
		 Select @Strmachine = ' and ( mi.MachineID = N''' + @MachineID + ''')'  
		 print @Strmachine
		End 

		If isnull(@MachineId,'') <> ''    
		Begin    
		 Select @StrmachineID = ' And ( MachineInformation.MachineID = N''' + @MachineID + ''')'    
		End 

		If isnull(@ComponentId,'') <> ''    
		Begin    
		 Select @StrComponent = ' And ( c2.componentid in (' + @ComponentId + '))' 
		 print @StrComponent
		End  

		If isnull(@OperationId,'') <> ''    
		Begin    
		 Select @StrOperation = ' And ( c1.operationno in (' + @OperationId + '))' 
		 print @StrOperation
		End 

		CREATE TABLE #Target
		(
			MachineId nvarchar(50),
			ComponentId nvarchar(50),
			OperationId int,
			FromDate DateTime,
			ToDate DateTime,
			Shift nvarchar(50),
			PDT int default 0,
			StdCycleTime float,
			ShiftTarget float,
			Target float,
			TotalTarget float,
			dDate DateTime,
			SubOperations nvarchar(50),
			TargetPercent nvarchar(50),
		)

		CREATE TABLE #ShiftDetails
		( 
			dDate datetime,
			Shift nvarchar(50),
			Starttime datetime ,
			Endtime datetime,
			Shiftid int 
		)  
	
		Create table #PlannedDownTimes
		(
			MachineID nvarchar(50) NOT NULL,
			MachineInterface nvarchar(50) NOT NULL, 
			StartTime DateTime NOT NULL, 
			EndTime DateTime NOT NULL 
		)
		
		ALTER TABLE #PlannedDownTimes
			ADD PRIMARY KEY CLUSTERED
				(   [MachineInterface],
					[StartTime],
					[EndTime]
						
				) ON [PRIMARY]

	CREATE TABLE #PlannedDownTimesShift
	(
		SlNo int not null identity(1,1),
		Starttime datetime,
		EndTime datetime,
		Machine nvarchar(50),
		MachineInterface nvarchar(50),
		DownReason nvarchar(50),
		ShiftSt datetime
	)
		Declare @ST datetime
		Select @ST =@StartDate

		while @ST<=@Enddate
		Begin
			INSERT INTO #ShiftDetails(dDate,Shift,Starttime,Endtime)
			EXEC s_GetShiftTime @ST
			select @ST=DATEADD(day,1,@ST)
		END


		SET @strSql = ''
		SET @strSql = 'Insert into #PlannedDownTimes
			SELECT distinct Machine,InterfaceID,
				CASE When StartTime<''' + convert(nvarchar(20),@StartDate,120)+''' Then ''' + convert(nvarchar(20),@StartDate,120)+''' Else StartTime End As StartTime,
				CASE When EndTime>''' + convert(nvarchar(20),@EndDate,120)+''' Then ''' + convert(nvarchar(20),@EndDate,120)+''' Else EndTime End As EndTime
			FROM PlannedDownTimes inner join MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID
			LEFT OUTER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID 
			LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID 
			and PlantMachineGroups.machineid = PlantMachine.MachineID
			WHERE PDTstatus =1 and(
			(StartTime >= ''' + convert(nvarchar(20),@StartDate,120)+''' AND EndTime <=''' + convert(nvarchar(20),@EndDate,120)+''')
		OR ( StartTime < ''' + convert(nvarchar(20),@StartDate,120)+'''  AND EndTime <= ''' + convert(nvarchar(20),@EndDate,120)+''' AND EndTime > ''' + convert(nvarchar(20),@StartDate,120)+''' )
		OR ( StartTime >= ''' + convert(nvarchar(20),@StartDate,120)+'''   AND StartTime <''' + convert(nvarchar(20),@EndDate,120)+''' AND EndTime > ''' + convert(nvarchar(20),@EndDate,120)+''' )
		OR ( StartTime < ''' + convert(nvarchar(20),@StartDate,120)+'''  AND EndTime > ''' + convert(nvarchar(20),@EndDate,120)+''')) '
		SET @strSql =  @strSql + @StrmachineID  + ' ORDER BY Machine,StartTime'
		print (@strSql)
		EXEC(@strSql)


		Select @Strsql =''    
		Select @Strsql ='Insert into #Target(MachineId,ComponentId, OperationId,FromDate,ToDate,Shift,StdCycleTime,SubOperations,TargetPercent,dDate)
						select mi.machineid, c2.componentid, c1.operationno,sd.Starttime,sd.Endtime,sd.Shift,c1.machiningtime,c1.SubOperations, c1.TargetPercent,sd.dDate
						from machineinformation mi 
						inner join componentoperationpricing c1 on mi.machineid = c1.machineid
						inner join componentinformation  c2 on c2.componentid = c1.componentid
						cross join #ShiftDetails sd where mi.interfaceid <> 0'
		
		Select @Strsql =@Strsql + @Strmachine + @StrComponent + @StrOperation
		print @Strsql
		Exec(@Strsql) 
	
		insert INTO #PlannedDownTimesShift(StartTime,EndTime,Machine,MachineInterface,Downreason,Shiftst)
		select
		CASE When T.StartTime<T1.Starttime Then T1.Starttime Else T.StartTime End,
		case When T.EndTime>T1.Endtime Then T1.Endtime Else T.EndTime End,
		Machine,M.InterfaceID,
		DownReason,T1.Starttime
		FROM PlannedDownTimes T cross join #ShiftDetails T1
		inner join MachineInformation M on T.machine = M.MachineID
		WHERE T.PDTstatus =1 and (
		(T.StartTime >= T1.Starttime  AND T.EndTime <=T1.Endtime)
		OR ( T.StartTime < T1.Starttime  AND T.EndTime <= T1.Endtime AND T.EndTime > T1.Starttime )
		OR ( T.StartTime >= T1.Starttime   AND T.StartTime <T1.Endtime AND T.EndTime > T1.Endtime )
		OR ( T.StartTime < T1.Starttime  AND T.EndTime > T1.Endtime) )
		and machine in (select distinct machine from #Target)
		ORDER BY StartTime

		--UPDATE #Target set PDT =isnull(PDT,0) + isnull(TT.PPDT ,0)
		--FROM(
		--	SELECT #Target.machineID,SUM
		--	(CASE
		--	WHEN #Target.FromDate >= T.StartTime AND #Target.ToDate <=T.EndTime THEN DateDiff(second,#Target.fromdate,#Target.todate)
		--	WHEN ( #Target.FromDate < T.StartTime AND #Target.ToDate <= T.EndTime AND #Target.ToDate > T.StartTime ) THEN DateDiff(second,T.StartTime,#Target.todate)
		--	WHEN ( #Target.FromDate >= T.StartTime AND #Target.FromDate <T.EndTime AND #Target.ToDate > T.EndTime ) THEN DateDiff(second,#Target.fromdate,T.EndTime )
		--	WHEN ( #Target.FromDate < T.StartTime AND #Target.ToDate > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
		--	END) as PPDT
		--	FROM #Target 
		--	Inner join machineinformation M ON #Target.MachineID = M.machineid
		--	inner jOIN #PlannedDownTimes T on T.MachineInterface=M.InterfaceID
		--	WHERE
		--	(
		--	(#Target.fromdate >= T.StartTime AND #Target.todate <=T.EndTime)
		--	OR ( #Target.fromdate < T.StartTime AND #Target.todate <= T.EndTime AND #Target.todate > T.StartTime )
		--	OR ( #Target.fromdate >= T.StartTime AND #Target.fromdate <T.EndTime AND #Target.todate > T.EndTime )
		--	OR ( #Target.fromdate < T.StartTime AND #Target.todate > T.EndTime) )
		--	group by #Target.machineID
		--)as TT  INNER JOIN #Target ON TT.machineID = #Target.MachineId


		UPDATE #Target set PDT =isnull(PDT,0) + isnull(TT.PPDT ,0)
		FROM(

			SELECT #Target.machineID,#Target.ComponentId,#Target.OperationId,#Target.FromDate,SUM
			(CASE
			WHEN #Target.FromDate >= T.StartTime AND #Target.ToDate <=T.EndTime THEN DateDiff(second,#Target.fromdate,#Target.todate)
			WHEN ( #Target.FromDate < T.StartTime AND #Target.ToDate <= T.EndTime AND #Target.ToDate > T.StartTime ) THEN DateDiff(second,T.StartTime,#Target.todate)
			WHEN ( #Target.FromDate >= T.StartTime AND #Target.FromDate <T.EndTime AND #Target.ToDate > T.EndTime ) THEN DateDiff(second,#Target.fromdate,T.EndTime )
			WHEN ( #Target.FromDate < T.StartTime AND #Target.ToDate > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END) as PPDT
			FROM #Target 
			Inner join machineinformation M ON #Target.MachineID = M.machineid
			inner jOIN #PlannedDownTimesShift T on T.MachineInterface=M.InterfaceID and #Target.FromDate=T.ShiftSt
			WHERE
			(
			(#Target.fromdate >= T.StartTime AND #Target.todate <=T.EndTime)
			OR ( #Target.fromdate < T.StartTime AND #Target.todate <= T.EndTime AND #Target.todate > T.StartTime )
			OR ( #Target.fromdate >= T.StartTime AND #Target.fromdate <T.EndTime AND #Target.todate > T.EndTime )
			OR ( #Target.fromdate < T.StartTime AND #Target.todate > T.EndTime) )
			group by #Target.machineID,#Target.ComponentId,#Target.OperationId,#Target.FromDate
		)as TT  INNER JOIN #Target ON TT.machineID = #Target.MachineId and TT.FromDate=#Target.FromDate

		UPDATE #Target set ShiftTarget =Round(isNull(TT.tcount ,0),0)
		From(
		SELECT T.machineID,T.ComponentId,T.OperationId,T.Ddate,
			(((datediff(second,T.FromDate,T.ToDate)-T.PDT)*T.SubOperations)/T.StdCycleTime)*isnull(T.TargetPercent,100) /100 as tcount
			FROM #Target  T
		) TT inner join #Target on TT.MachineId = #Target.MachineId and TT.ComponentId=#Target.ComponentId and TT.OperationId=#Target.OperationId and TT.dDate=#Target.dDate

		update #Target set Target = Isnull(T.IdealCount,0)
		From(
		select T1.MachineId,T1.ComponentId,T1.OperationId,T1.dDate,T1.Shift,L.IdealCount  from  #Target T1
		left join  LoadSchedule L on L.Machine = T1.MachineId and  L.Component = T1.componentid and L.Operation = T1.OperationId and L.date = T1.dDate and L.Shift = T1.Shift
		) T inner join #Target  on  T.MachineId = #Target.MachineId  and  T.ComponentId = #Target.componentid and T.OperationId = #Target.OperationId and T.dDate = #Target.dDate and T.Shift = #Target.Shift

		update #Target set TotalTarget = isnull(T.TotalTarget,0)
		From(
		select T1.MachineId,T1.ComponentId,T1.OperationId,T1.dDate, sum(isnull(Target,0)) as ToTalTarget from  #Target T1
		group by T1.MachineId,T1.ComponentId,T1.OperationId,T1.dDate
		) T inner join #Target  on  T.MachineId = #Target.MachineId  and  T.ComponentId = #Target.componentid and T.OperationId = #Target.OperationId and T.dDate = #Target.dDate

		select MachineId,ComponentId,OperationId,FromDate,ToDate,Shift,StdCycleTime,dbo.f_FormatTime(PDT,'mm') as PDT,ShiftTarget,Target,TotalTarget from #Target

		--Declare 
		--	@columns NVARCHAR(MAX) = '',
		--	@sql     NVARCHAR(MAX) = '';

		--SELECT @columns = @columns + QUOTENAME(T.Shift) + ',' FROM #Target T group by T.Shift
		--SET @columns = LEFT(@columns, LEN(@columns) - 1);

		--print @columns

		--set @sql = ''
		--SET @sql ='
		--SELECT MachineId,ComponentId,OperationId,FromDate,ToDate,StdCycleTime,'+ @columns +',ShiftTarget,Target FROM   
		--(
		--	SELECT MachineId,ComponentId,OperationId,FromDate,ToDate,StdCycleTime,PDT as s1,ShiftTarget,Target,Shift
		--	FROM #Target 
		--) AS t 
		--PIVOT(max(s1) FOR Shift IN ('+ @columns + ')) AS pivot_table
		--order by  FromDate,MachineId,ComponentId,OperationId'

		--EXECUTE sp_executesql @sql;

		--set @sql =''
		--SET @sql ='
		--SELECT MachineId,ComponentId,OperationId,FromDate,ToDate,StdCycleTime,PDT,ShiftTarget,'+ @columns +' FROM   
		--(
		--	SELECT MachineId,ComponentId,OperationId,FromDate,ToDate,StdCycleTime,PDT,ShiftTarget,Target as s1,Shift
		--	FROM #Target 
		--) AS t 
		--PIVOT(max(s1) FOR Shift IN ('+ @columns + ')) AS pivot_table
		--order by  FromDate,MachineId,ComponentId,OperationId'

		--EXECUTE sp_executesql @sql;

		--set @sql =''
		--SET @sql ='
		--SELECT MachineId,ComponentId,OperationId,FromDate,ToDate,StdCycleTime,PDT,'+ @columns +',Target FROM   
		--(
		--	SELECT MachineId,ComponentId,OperationId,FromDate,ToDate,StdCycleTime,PDT,ShiftTarget as s1,Target,Shift
		--	FROM #Target 
		--) AS t 
		--PIVOT(max(s1) FOR Shift IN ('+ @columns + ')) AS pivot_table
		--order by  FromDate,MachineId,ComponentId,OperationId'

		--EXECUTE sp_executesql @sql;

END
    
IF @Param = 'Save'
BEGIN
		IF NOT EXISTS (SELECT * FROM LoadSchedule WHERE Machine=@MachineId AND Component=@ComponentId AND Operation=@OperationId AND date=@StartDate AND Shift=@Shift)
		BEGIN
			Insert into LoadSchedule(Machine,Component,Operation,date,Shift,IdealCount,PDT,StdCycleTime,ShiftTarget)
			Values (@MachineId,@ComponentId,@OperationId,@StartDate,@Shift,@IdealCount,@PDT,@StdCycleTime,@ShiftTarget)
		END
		ELSE
		BEGIN 
			Update LoadSchedule set PDT=@PDT, StdCycleTime=@StdCycleTime, ShiftTarget=@ShiftTarget, IdealCount=@IdealCount
			where Machine=@MachineId AND Component=@ComponentId AND Operation=@OperationId AND date=@StartDate AND Shift=@Shift
		END

END

ELSE IF @Param = 'Delete'
BEGIN
	Delete from LoadSchedule where Machine=@MachineId AND Component=@ComponentId AND Operation=@OperationId AND date=@StartDate AND Shift=@Shift
END

END
