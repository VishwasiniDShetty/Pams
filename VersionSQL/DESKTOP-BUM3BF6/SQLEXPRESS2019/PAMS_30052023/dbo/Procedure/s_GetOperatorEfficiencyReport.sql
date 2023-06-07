/****** Object:  Procedure [dbo].[s_GetOperatorEfficiencyReport]    Committed by VersionSQL https://www.versionsql.com ******/

/****************************************************************************************************
--NR0097 - SwathiKS - 10/Dec/2013 :: To Show Machine - Operator Level Prodtime,Downtime and Efficiency for Ace.
While Accounting ManagementLoss, To apply Threshold from Componentoperationprcing table for the Downs with "PickFomCO = 1" else apply threshold from Downcodeinformation tablw eith "Availeffy=1".
Since we are splitting Production and Down Cycle across shifts while showing partscount we have to consider decimal values instead whole Numbers.
--[dbo].[s_GetOperatorEfficiencyReport]  '2013-02-01','2013-02-09','','HENRY','summary'
***************************************************************************************************/
CREATE        PROCEDURE [dbo].[s_GetOperatorEfficiencyReport] 
	@StartDate as datetime,
	@EndDate as datetime,
	@ShiftName as nvarchar(20)='',
	@Operator as nvarchar(50)= '',
	@Param nvarchar(50) = ''
WITH RECOMPILE
AS
BEGIN

create table #OprDetails
(
	PDate datetime,
	shiftstart datetime,
	ShiftEnd Datetime,
	Shift nvarchar(10),
	Operator nvarchar(50),
	Oprinterface nvarchar(50),
	Machineinterface nvarchar(50),
	Machine nvarchar(50),
	ProdTime float,
	Downtime float,
	Others float,
	MLossforOthers float,
	MLDownOthers float,
	MLossforDowntime float,
	MLDown float,
	CN float,
	AE float,
	PE float,
	OE float
)

CREATE TABLE #ShiftDetails 
(
	PDate datetime,
	Shift nvarchar(20),
	ShiftStart datetime,
	ShiftEnd datetime
)

---Temp table to store PDT's at shift level
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


CREATE TABLE #T_autodata
(
	[mc] [nvarchar](50)not NULL,
	[comp] [nvarchar](50) NULL,
	[opn] [nvarchar](50) NULL,
	[opr] [nvarchar](50) NULL,
	[dcode] [nvarchar](50) NULL,
	[sttime] [datetime] not NULL,
	[ndtime] [datetime] NULL,
	[datatype] [tinyint] NULL ,
	[cycletime] [int] NULL,
	[loadunload] [int] NULL ,
	[msttime] [datetime] NULL,
	--[PartsCount] [int] NULL ,
	[PartsCount] decimal(18,5) NULL ,
	id  bigint not null
)

ALTER TABLE #T_autodata

ADD PRIMARY KEY CLUSTERED
(
	mc,sttime ASC
)ON [PRIMARY]

create table #Summary
(
	ProdTime float,
	Downtime float,
	Others float,
	CN float,
	AE float,
	PE float,
	OE float
)

Declare @T_ST AS Datetime 
Declare @T_ED AS Datetime 
Declare @CurStrtTime as datetime
Declare @CurEndTime as datetime
Declare @strsql as nvarchar(4000)
Declare @strOperator as nvarchar(1000)
Declare @StrPlant as nvarchar(1000)

IF ISNULL(@Operator,'')<>''
BEGIN
	SELECT @strOperator =' AND E.Employeeid = N'''+ @Operator +''''
END

Select @T_ST=dbo.f_GetLogicalDay(@StartDate,'start')
Select @T_ED=dbo.f_GetLogicalDay(@endDate,'End')

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

Select @CurStrtTime=@StartDate
Select @CurEndTime=@EndDate

If @ShiftName <> ''
BEGIN
	while @CurStrtTime<=@CurEndTime
	BEGIN
		INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)
		EXEC s_GetShiftTime @CurStrtTime,@ShiftName
		SELECT @CurStrtTime=DATEADD(DAY,1,@CurStrtTime)
	END
END

If @ShiftName = ''
BEGIN
	while @CurStrtTime<=@CurEndTime
	BEGIN
		INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)
		EXEC s_GetShiftTime @CurStrtTime,''
		SELECT @CurStrtTime=DATEADD(DAY,1,@CurStrtTime)
	END
END


	---mod 12 get the PDT's defined,at shift and Machine level
	insert INTO #PlannedDownTimesShift(StartTime,EndTime,Machine,MachineInterface,Downreason,Shiftst)
	select
	CASE When StartTime<T1.ShiftStart Then T1.ShiftStart Else StartTime End,
	case When EndTime>T1.ShiftEnd Then T1.ShiftEnd Else EndTime End,
	Machine,M.InterfaceID,DownReason,T1.ShiftStart
	FROM PlannedDownTimes cross join #ShiftDetails T1
	inner join MachineInformation M on PlannedDownTimes.machine = M.MachineID
	WHERE PDTstatus =1 and (
	(StartTime >= T1.ShiftStart  AND EndTime <=T1.ShiftEnd)
	OR ( StartTime < T1.ShiftStart  AND EndTime <= T1.ShiftEnd AND EndTime > T1.ShiftStart )
	OR ( StartTime >= T1.ShiftStart   AND StartTime <T1.ShiftEnd AND EndTime > T1.ShiftEnd )
	OR ( StartTime < T1.ShiftStart  AND EndTime > T1.ShiftEnd))
	ORDER BY StartTime

	Select @strsql = ''
	Select @strsql = @strsql + ' Insert into #OprDetails(PDate,ShiftStart,ShiftEnd,Shift,Operator,Machine,Oprinterface,Machineinterface,ProdTime,
	Downtime,Others,MLossforOthers,MLDownOthers,MLossforDowntime,MLDown,CN ,AE,Pe,OE)'
	Select @strsql = @strsql + 'Select distinct S.Pdate,S.ShiftStart,S.ShiftEnd,S.Shift,E.employeeid,M.machineid,E.interfaceid,M.interfaceid 
	,0,0,0,0,0 ,0,0,0,0,0,0 from #T_autodata autodata 
	inner join Machineinformation M on autodata.mc=M.interfaceid
	inner join Employeeinformation E on autodata.opr=E.interfaceid
	Left Outer Join PlantMachine P ON M.MachineID=P.MachineID 
	Cross Join #ShiftDetails S '
	Select @strsql = @strsql + 'Where 
	(autodata.msttime>=shiftstart and autodata.ndtime<=ShiftEnd
	OR autodata.msttime<shiftstart and autodata.ndtime>shiftstart and autodata.ndtime<=ShiftEnd
	OR autodata.msttime>=shiftstart and autodata.msttime<ShiftEnd and autodata.ndtime>ShiftEnd
	OR autodata.msttime<shiftstart and autodata.ndtime>ShiftEnd) '
	select @strsql = @strsql + @strOperator 
	select @strsql = @strsql + 'Order by S.Pdate,S.Shift,E.employeeid,M.machineid,E.interfaceid,M.interfaceid'
	Print @strsql
	Exec(@strsql)


	--For Prodtime
	UPDATE #OprDetails SET Prodtime = isnull(Prodtime,0) + isNull(t2.cycle,0)
	from
	(select ShiftStart,ShiftEnd,Operator,Machine,
		sum(case when ((autodata.msttime>=S.ShiftStart) and (autodata.ndtime<=S.ShiftEnd)) then  (cycletime+loadunload)
			 when ((autodata.msttime<S.ShiftStart)and (autodata.ndtime>S.ShiftStart)and (autodata.ndtime<=S.ShiftEnd)) then DateDiff(second, S.ShiftStart, ndtime)
			 when ((autodata.msttime>=S.ShiftStart)and (autodata.msttime<S.ShiftEnd)and (autodata.ndtime>S.ShiftEnd)) then DateDiff(second, mstTime, S.ShiftEnd)
			 when ((autodata.msttime<S.ShiftStart)and (autodata.ndtime>S.ShiftEnd)) then DateDiff(second, S.ShiftStart, S.ShiftEnd) END ) as cycle
	from #T_autodata autodata 
	inner join #OprDetails S on autodata.mc = S.Machineinterface and  autodata.opr = S.Oprinterface
	where (autodata.datatype=1) AND(( (autodata.msttime>=S.ShiftStart) and (autodata.ndtime<=S.ShiftEnd))
	OR ((autodata.msttime<S.ShiftStart)and (autodata.ndtime>S.ShiftStart)and (autodata.ndtime<=S.ShiftEnd))
	OR ((autodata.msttime>=S.ShiftStart)and (autodata.msttime<S.ShiftEnd)and (autodata.ndtime>S.ShiftEnd))
	OR((autodata.msttime<S.ShiftStart)and (autodata.ndtime>S.ShiftEnd)))
	group by ShiftStart,ShiftEnd,Operator,Machine
	) as t2 inner join #OprDetails on t2.Machine = #OprDetails.Machine and  t2.Operator = #OprDetails.Operator
	and t2.ShiftStart=#OprDetails.ShiftStart and t2.ShiftEnd=#OprDetails.ShiftEnd


	--Type 2
	UPDATE  #OprDetails SET Prodtime = isnull(Prodtime,0) - isNull(t2.Down,0)
	FROM
	(Select AutoData.mc,Autodata.opr,
	SUM(
	CASE
		When autodata.sttime <= T1.ShiftStart Then datediff(s, T1.ShiftStart,autodata.ndtime )
		When autodata.sttime > T1.ShiftStart Then datediff(s,autodata.sttime,autodata.ndtime)
	END) as Down,T1.ShiftStart as ShiftStart,T1.Pdate as Pdate
	From #T_autodata AutoData INNER Join
		(Select mc,opr,Sttime,NdTime,ShiftStart,ShiftEnd,Pdate From #T_autodata AutoData
			inner join #OprDetails ST1 ON ST1.MachineInterface=Autodata.mc and Autodata.opr = ST1.Oprinterface
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(msttime < ShiftStart)And (ndtime > ShiftStart) AND (ndtime <= ShiftEnd)
		) as T1 on t1.mc=autodata.mc and T1.opr=Autodata.opr
	Where AutoData.DataType=2
	And ( autodata.Sttime > T1.Sttime )
	And ( autodata.ndtime <  T1.ndtime )
	AND ( autodata.ndtime >  T1.ShiftStart )
	GROUP BY Autodata.mc,Autodata.opr,T1.ShiftStart,T1.Pdate)AS T2 Inner Join #OprDetails on t2.mc = #OprDetails.machineinterface
	and T2.Pdate = #OprDetails.Pdate and t2.ShiftStart=#OprDetails.ShiftStart and T2.opr = #OprDetails.Oprinterface


	--Type 3
	UPDATE  #OprDetails SET Prodtime = isnull(Prodtime,0) - isNull(t2.Down,0)
	FROM
	(Select AutoData.mc ,Autodata.opr,
	SUM(CASE
		When autodata.ndtime > T1.ShiftEnd Then datediff(s,autodata.sttime, T1.ShiftEnd )
		When autodata.ndtime <=T1.ShiftEnd Then datediff(s , autodata.sttime,autodata.ndtime)
	END) as Down,T1.ShiftStart as ShiftStart,T1.Pdate as Pdate
	From #T_autodata AutoData INNER Join
		(Select mc,opr,Sttime,NdTime,ShiftStart,ShiftEnd,Pdate From #T_autodata AutoData
			inner join #OprDetails ST1 ON ST1.MachineInterface =Autodata.mc and Autodata.opr = ST1.Oprinterface
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(sttime >= ShiftStart)And (ndtime >ShiftEnd) and (sttime< ShiftEnd)
	 ) as T1
	ON AutoData.mc=T1.mc and T1.opr=Autodata.opr
	Where AutoData.DataType=2
	And (T1.Sttime < autodata.sttime  )
	And ( T1.ndtime >  autodata.ndtime)
	AND (autodata.sttime  <  T1.ShiftEnd)
	GROUP BY Autodata.mc,Autodata.opr,T1.ShiftStart,T1.Pdate )AS T2 Inner Join #OprDetails on t2.mc = #OprDetails.machineinterface
	and t2.Pdate=#OprDetails.Pdate and t2.ShiftStart=#OprDetails.ShiftStart and T2.opr = #OprDetails.Oprinterface

	--For Type4
	UPDATE  #OprDetails SET Prodtime = isnull(Prodtime,0) - isNull(t2.Down,0)
	FROM
	(Select AutoData.mc,Autodata.opr,
	SUM(CASE
		When autodata.sttime >= T1.ShiftStart AND autodata.ndtime <= T1.ShiftEnd Then datediff(s , autodata.sttime,autodata.ndtime)
		When autodata.sttime < T1.ShiftStart And autodata.ndtime >T1.ShiftStart AND autodata.ndtime<=T1.ShiftEnd Then datediff(s, T1.ShiftStart,autodata.ndtime )
		When autodata.sttime >= T1.ShiftStart AND autodata.sttime<T1.ShiftEnd AND autodata.ndtime>T1.ShiftEnd Then datediff(s,autodata.sttime, T1.ShiftEnd )
		When autodata.sttime<T1.ShiftStart AND autodata.ndtime>T1.ShiftEnd   Then datediff(s , T1.ShiftStart,T1.ShiftEnd)
	END) as Down,T1.ShiftStart as ShiftStart,T1.Pdate as Pdate
	From #T_autodata AutoData INNER Join
		(Select mc,opr,Sttime,NdTime,ShiftStart,ShiftEnd,Pdate From #T_autodata AutoData
			inner join #OprDetails ST1 ON ST1.MachineInterface =Autodata.mc  and Autodata.opr = ST1.Oprinterface
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(msttime < ShiftStart)And (ndtime >ShiftEnd)
		) as T1
	ON AutoData.mc=T1.mc and T1.opr=Autodata.opr 
	Where AutoData.DataType=2
	And (T1.Sttime < autodata.sttime  )
	And ( T1.ndtime >  autodata.ndtime)
	AND (autodata.ndtime  >  T1.ShiftStart)
	AND (autodata.sttime  <  T1.ShiftEnd)
	GROUP BY Autodata.mc,Autodata.opr,T1.ShiftStart,T1.Pdate
	 )AS T2 Inner Join #OprDetails on t2.mc = #OprDetails.machineinterface
	and T2.Pdate = #OprDetails.Pdate and t2.ShiftStart=#OprDetails.ShiftStart and T2.opr = #OprDetails.Oprinterface


--Get the utilised time overlapping with PDT and negate it from Prodtime
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
BEGIN
	
	UPDATE  #OprDetails SET Prodtime = isnull(Prodtime,0) - isNull(t2.PlanDT,0)
	from( select T.ShiftSt as intime,T.Machine as machine,autodata.opr,
	sum (CASE
	WHEN (autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN DateDiff(second,autodata.msttime,autodata.ndtime) --DR0325 Added
	WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
	WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )
	WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
	END ) as PlanDT
	from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T 
	WHERE autodata.DataType=1   and T.MachineInterface=autodata.mc AND(
	(autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
	OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
	OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )
	OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime)
	)group by T.Machine,T.ShiftSt,autodata.opr ) as t2 inner join #OprDetails S on t2.intime=S.shiftstart and t2.machine=S.machine
	and T2.opr=S.oprinterface
	
	
	---mod 12:Add ICD's Overlapping  with PDT to Prodtime
	/* Fetching Down Records from Production Cycle  */
	 ---mod 12(4):Handle intearction between ICD and PDT for type 1 production record for the selected time period.
		UPDATE  #OprDetails SET Prodtime = isnull(Prodtime,0) + isNull(T2.IPDT ,0)
		FROM	(
		Select T.ShiftSt as intime,AutoData.mc,Autodata.opr,
		SUM(
		CASE 	
			When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
			When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
			When (autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
			when (autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join 
			(Select mc,opr,Sttime,NdTime,S.ShiftStart as StartTime from #T_autodata autodata 
			inner join #OprDetails S on S.MachineInterface=autodata.mc and S.Oprinterface=autodata.opr
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(msttime >= S.ShiftStart) AND (ndtime <= S.ShiftEnd)) as T1
		ON AutoData.mc=T1.mc and autodata.opr=T1.opr and T1.StartTime=T.ShiftSt 
		Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc
		And (( autodata.Sttime > T1.Sttime )
		And ( autodata.ndtime <  T1.ndtime ))
		AND
		((T.StartTime >=T1.Sttime And T.EndTime <=T1.ndtime )
		or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
		or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
		or ( T.StartTime <T1.Sttime And T.EndTime >T1.ndtime ))
		GROUP BY Autodata.mc,Autodata.opr,T.ShiftSt
		)AS T2  INNER JOIN #OprDetails ON T2.mc = #OprDetails.MachineInterface and  t2.intime=#OprDetails.ShiftStart
		and T2.Opr=#OprDetails.Oprinterface

	---mod 12(4)
	/* If production  Records of TYPE-2*/
	UPDATE  #OprDetails SET Prodtime = isnull(Prodtime,0) + isNull(T2.IPDT ,0)
	FROM
	(Select T.ShiftSt as intime,AutoData.mc,Autodata.opr,
	SUM(
	CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT
	from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join 
		(Select mc,opr,Sttime,NdTime,S.ShiftStart as StartTime from #T_autodata autodata 
		 inner join #OprDetails S on S.MachineInterface=autodata.mc and S.Oprinterface=autodata.opr
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(msttime < S.ShiftStart)And (ndtime > S.ShiftStart) AND (ndtime <= S.ShiftEnd)) as T1
	ON AutoData.mc=T1.mc and autodata.opr=T1.opr and T1.StartTime=T.ShiftSt
	Where AutoData.DataType=2  and T.MachineInterface=autodata.mc
	And (( autodata.Sttime > T1.Sttime )
	And ( autodata.ndtime <  T1.ndtime )
	AND ( autodata.ndtime >  T1.StartTime ))
	AND
	(( T.StartTime >= T1.StartTime )
	And ( T.StartTime <  T1.ndtime ) )
	GROUP BY Autodata.mc,Autodata.opr,T.ShiftSt )AS T2  INNER JOIN #OprDetails ON
	T2.mc = #OprDetails.MachineInterface and  t2.intime=#OprDetails.ShiftStart and T2.Opr=#OprDetails.Oprinterface

	

	/* If production Records of TYPE-3*/
	UPDATE  #OprDetails SET Prodtime = isnull(Prodtime,0) + isNull(T2.IPDT ,0)
	FROM
	(Select T.ShiftSt as intime,AutoData.mc ,Autodata.opr,
	SUM(
	CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT
	from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join
		(Select mc,opr,Sttime,NdTime,S.ShiftStart as StartTime,S.ShiftEnd as EndTime from #T_autodata autodata 
		inner join #OprDetails S on S.MachineInterface=autodata.mc and S.Oprinterface=autodata.opr
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(sttime >= S.ShiftStart)And (ndtime > S.ShiftEnd) and autodata.sttime <S.ShiftEnd) as T1
	ON AutoData.mc=T1.mc and Autodata.opr=T1.opr and T1.StartTime=T.ShiftSt
	Where AutoData.DataType=2  and T.MachineInterface=autodata.mc
	And ((T1.Sttime < autodata.sttime  )
	And ( T1.ndtime >  autodata.ndtime)
	AND (autodata.sttime  <  T1.EndTime))
	AND
	(( T.EndTime > T1.Sttime )
	And ( T.EndTime <=T1.EndTime ) )
	GROUP BY AUTODATA.mc,Autodata.opr,T.ShiftSt)AS T2   INNER JOIN #OprDetails ON
	T2.mc = #OprDetails.MachineInterface and  t2.intime=#OprDetails.ShiftStart and T2.Opr=#OprDetails.Oprinterface
	

	
	/* If production Records of TYPE-4*/
	UPDATE  #OprDetails SET Prodtime = isnull(Prodtime,0) + isNull(T2.IPDT ,0)
	FROM
	(Select T.ShiftSt as intime,AutoData.mc ,Autodata.opr,
	SUM(
	CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT
	from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join 
		(Select mc,opr,Sttime,NdTime,S.ShiftStart as StartTime,S.ShiftEnd as EndTime from #T_autodata autodata 
			inner join #OprDetails S on S.MachineInterface=autodata.mc and S.Oprinterface=autodata.opr
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(msttime < S.ShiftStart)And (ndtime > S.ShiftEnd)) as T1
	ON AutoData.mc=T1.mc and autodata.opr=T1.opr and T1.StartTime=T.ShiftSt
	Where AutoData.DataType=2 and T.MachineInterface=autodata.mc
	And ( (T1.Sttime < autodata.sttime  )
		And ( T1.ndtime >  autodata.ndtime)
		AND (autodata.ndtime  >  T1.StartTime)
		AND (autodata.sttime  <  T1.EndTime))
	AND
	(( T.StartTime >=T1.StartTime)
	And ( T.EndTime <=T1.EndTime ) )
	GROUP BY AUTODATA.mc,Autodata.opr,T.ShiftSt)AS T2  INNER JOIN #OprDetails ON
	T2.mc = #OprDetails.MachineInterface and  t2.intime=#OprDetails.ShiftStart and T2.Opr=#OprDetails.Oprinterface
	
END


If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y')
BEGIN
	--Type 1
	UPDATE #OprDetails SET Others = isnull(Others,0) + isNull(t2.down,0)
	from
	(select mc,autodata.opr,
	sum(loadunload) down,S.ShiftStart as ShiftStart
	from #T_autodata autodata 
	inner join #OprDetails S on autodata.mc=S.MachineInterface and autodata.opr=S.Oprinterface
	INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
	Inner join Downcategoryinformation DC on downcodeinformation.Catagory = DC.DownCategory
	where downcodeinformation.Catagory <> 'Operator' and (autodata.msttime>=S.ShiftStart)
	and (autodata.ndtime<= S.ShiftEnd)
	and (autodata.datatype=2)
	group by autodata.mc,autodata.opr,S.ShiftStart
	) as t2 inner join #OprDetails on t2.mc = #OprDetails.machineinterface
	and t2.ShiftStart=#OprDetails.ShiftStart and t2.opr=#OprDetails.oprinterface
	
	-- Type 2
	UPDATE #OprDetails SET Others = isnull(Others,0) + isNull(t2.down,0)
	from
	(select mc,autodata.opr,
		sum(DateDiff(second, S.ShiftStart, ndtime)) down,S.ShiftStart as ShiftStart
	from #T_autodata autodata 
	inner join #OprDetails S on autodata.mc=S.MachineInterface and autodata.opr=S.Oprinterface
	INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
	Inner join Downcategoryinformation DC on downcodeinformation.Catagory = DC.DownCategory
	where downcodeinformation.Catagory <> 'Operator' and (autodata.sttime<S.ShiftStart)
	and (autodata.ndtime>S.ShiftStart)
	and (autodata.ndtime<= S.ShiftEnd)
	and (autodata.datatype=2)
	group by autodata.mc,autodata.opr,S.ShiftStart
	) as t2 inner join #OprDetails on t2.mc = #OprDetails.machineinterface
	and t2.ShiftStart=#OprDetails.ShiftStart and t2.opr=#OprDetails.oprinterface
	
	
	-- Type 3
	UPDATE #OprDetails SET Others = isnull(Others,0) + isNull(t2.down,0)
	from
	(select mc,autodata.opr,
		sum(DateDiff(second, stTime,  S.ShiftEnd)) down,S.ShiftStart as ShiftStart
	from #T_autodata autodata 
	inner join #OprDetails S on autodata.mc=S.MachineInterface and autodata.opr=S.Oprinterface
	INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
	Inner join Downcategoryinformation DC on downcodeinformation.Catagory = DC.DownCategory
	where downcodeinformation.Catagory <> 'Operator' and  (autodata.msttime>=S.ShiftStart)
	and (autodata.sttime< S.ShiftEnd)
	and (autodata.ndtime> S.ShiftEnd)
	and (autodata.datatype=2)group by autodata.mc,autodata.opr,S.ShiftStart
	) as t2 inner join #OprDetails on t2.mc = #OprDetails.machineinterface
	and t2.ShiftStart=#OprDetails.ShiftStart and t2.opr=#OprDetails.oprinterface
	
	
	-- Type 4
	UPDATE #OprDetails SET Others = isnull(Others,0) + isNull(t2.down,0)
	from
	(select mc,autodata.opr,
		sum(DateDiff(second, S.ShiftStart,  S.ShiftEnd)) down,S.ShiftStart as ShiftStart
	from #T_autodata autodata
    inner join #OprDetails S on autodata.mc=S.MachineInterface and autodata.opr=S.Oprinterface
	INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
	Inner join Downcategoryinformation DC on downcodeinformation.Catagory = DC.DownCategory
	where downcodeinformation.Catagory <> 'Operator' and autodata.msttime<S.ShiftStart
	and autodata.ndtime> S.ShiftEnd
	and (autodata.datatype=2)
	group by autodata.mc,autodata.opr,S.ShiftStart
	) as t2 inner join #OprDetails on t2.mc = #OprDetails.machineinterface
	and t2.ShiftStart=#OprDetails.ShiftStart  and t2.opr=#OprDetails.oprinterface

	---Management Loss-----
	-- Type 1
	UPDATE #OprDetails SET MLossforOthers = isnull(MLossforOthers,0) + isNull(t2.loss,0)
	from
	(select mc,opr,
		sum(CASE
	WHEN loadunload >ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)
	ELSE loadunload
	END) loss,S.ShiftStart as ShiftStart
	from #T_autodata autodata 
	inner join #OprDetails S on autodata.mc=S.MachineInterface and autodata.opr=S.Oprinterface
	INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid 
	Inner join Downcategoryinformation DC on downcodeinformation.Catagory = DC.DownCategory
	where downcodeinformation.Catagory <> 'Operator' and (autodata.msttime>=S.ShiftStart)
	and (autodata.ndtime<=S.ShiftEnd)
	and (autodata.datatype=2)
	and (downcodeinformation.availeffy = 1)
	and (downcodeinformation.ThresholdfromCO <>1) --NR0097
	group by autodata.mc,opr,S.ShiftStart
	) as t2 inner join #OprDetails on t2.mc = #OprDetails.machineinterface
	and t2.ShiftStart=#OprDetails.ShiftStart  and t2.opr=#OprDetails.oprinterface

	-- Type 2
	UPDATE #OprDetails SET MLossforOthers = isnull(MLossforOthers,0) + isNull(t2.loss,0)
	from
	(select mc,opr,
		sum(CASE
	WHEN DateDiff(second, S.ShiftStart, ndtime)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)
	ELSE DateDiff(second, S.ShiftStart, ndtime)
	end) loss,S.ShiftStart as ShiftStart
	from #T_autodata autodata
    inner join #OprDetails S on autodata.mc=S.MachineInterface and autodata.opr=S.Oprinterface
	INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid 
	Inner join Downcategoryinformation DC on downcodeinformation.Catagory = DC.DownCategory
	where downcodeinformation.Catagory <> 'Operator'  and (autodata.sttime<S.ShiftStart)
	and (autodata.ndtime>S.ShiftStart)
	and (autodata.ndtime<=S.ShiftEnd)
	and (autodata.datatype=2)
	and (downcodeinformation.availeffy = 1)
	and (downcodeinformation.ThresholdfromCO <>1) --NR0097
	group by autodata.mc,opr,S.ShiftStart
	) as t2 inner join #OprDetails on t2.mc = #OprDetails.machineinterface
	and t2.ShiftStart=#OprDetails.ShiftStart and t2.opr=#OprDetails.oprinterface

	-- Type 3
	UPDATE #OprDetails SET MLossforOthers = isnull(MLossforOthers,0) + isNull(t2.loss,0)
	from
	(select      mc,opr,
		sum(CASE
	WHEN DateDiff(second, stTime, S.ShiftEnd)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)ELSE DateDiff(second, stTime, S.ShiftEnd)
	END) loss,S.ShiftStart as ShiftStart
	from #T_autodata autodata  
    inner join #OprDetails S on autodata.mc=S.MachineInterface and autodata.opr=S.Oprinterface
	INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid 
	Inner join Downcategoryinformation DC on downcodeinformation.Catagory = DC.DownCategory
	where  downcodeinformation.Catagory <> 'Operator' and (autodata.msttime>=S.ShiftStart)
	and (autodata.sttime<S.ShiftEnd)
	and (autodata.ndtime>S.ShiftEnd)
	and (autodata.datatype=2)
	and (downcodeinformation.availeffy = 1)
	and (downcodeinformation.ThresholdfromCO <>1) --NR0097
	group by autodata.mc,opr,S.ShiftStart
	) as t2 inner join #OprDetails on t2.mc = #OprDetails.machineinterface
	and t2.ShiftStart=#OprDetails.ShiftStart and t2.opr=#OprDetails.oprinterface

	-- Type 4
	UPDATE #OprDetails SET MLossforOthers = isnull(MLossforOthers,0) + isNull(t2.loss,0)
	from
	(select mc,opr,
		sum(CASE
	WHEN DateDiff(second, S.ShiftStart, S.ShiftEnd)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)
	ELSE DateDiff(second, S.ShiftStart, S.ShiftEnd)
	END) loss,S.ShiftStart as ShiftStart
	from #T_autodata autodata 
    inner join #OprDetails S on autodata.mc=S.MachineInterface and autodata.opr=S.Oprinterface
	INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid 
	Inner join Downcategoryinformation DC on downcodeinformation.Catagory = DC.DownCategory	
	where downcodeinformation.Catagory <> 'Operator' and autodata.msttime<S.ShiftStart
	and autodata.ndtime>S.ShiftEnd
	and (autodata.datatype=2)
	and (downcodeinformation.availeffy = 1)
	and (downcodeinformation.ThresholdfromCO <>1) --NR0097
	group by autodata.mc,opr,S.ShiftStart
	) as t2 inner join #OprDetails on t2.mc = #OprDetails.machineinterface
	and t2.ShiftStart=#OprDetails.ShiftStart and t2.opr=#OprDetails.oprinterface
END

---mod 12:Get the down time and Management loss when setting for 'Ignore_Dtime_4m_PLD'='Y'
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN

	---Get the down times which are not of type Management Loss
	UPDATE #OprDetails SET Others = isnull(Others,0) + isNull(t2.down,0)
	from
	(select      mc,opr,
		sum(case when ( (autodata.msttime>=S.ShiftStart) and (autodata.ndtime<=S.ShiftEnd)) then  loadunload
			 when ((autodata.sttime<S.ShiftStart)and (autodata.ndtime>S.ShiftStart)and (autodata.ndtime<=S.ShiftEnd)) then DateDiff(second, S.ShiftStart, ndtime)
			 when ((autodata.msttime>=S.ShiftStart)and (autodata.msttime<S.ShiftEnd)and (autodata.ndtime>S.ShiftEnd)) then DateDiff(second, stTime, S.ShiftEnd)
			 when ((autodata.msttime<S.ShiftStart)and (autodata.ndtime>S.ShiftEnd)) then DateDiff(second, S.ShiftStart, S.ShiftEnd) END ) as down,S.ShiftStart as ShiftStart
	   from #T_autodata autodata 
	   inner join #OprDetails S on autodata.mc=S.MachineInterface and autodata.opr=S.Oprinterface
	   inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
	   Inner join Downcategoryinformation DC on downcodeinformation.Catagory = DC.DownCategory	
	where downcodeinformation.Catagory <> 'Operator' and (autodata.datatype=2) AND(( (autodata.msttime>=S.ShiftStart) and (autodata.ndtime<=S.ShiftEnd))
	      OR ((autodata.msttime<S.ShiftStart)and (autodata.ndtime>S.ShiftStart)and (autodata.ndtime<=S.ShiftEnd))
	      OR ((autodata.msttime>=S.ShiftStart)and (autodata.msttime<S.ShiftEnd)and (autodata.ndtime>S.ShiftEnd))
	      OR((autodata.msttime<S.ShiftStart)and (autodata.ndtime>S.ShiftEnd))) AND (downcodeinformation.availeffy = 0)
	      group by autodata.mc,opr,S.ShiftStart
	) as t2 inner join #OprDetails on t2.mc = #OprDetails.machineinterface
	and t2.ShiftStart=#OprDetails.ShiftStart and t2.opr=#OprDetails.oprinterface
	
	UPDATE #OprDetails SET Others = isnull(Others,0) - isNull(t2.PldDown,0)
	from(
		select T.Shiftst as intime,T.Machine as machine,autodata.opr,SUM
		       (CASE
			WHEN (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN autodata.loadunload
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PldDown
		from #T_autodata autodata  
		CROSS jOIN #PlannedDownTimesShift T
		INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID
		Inner join Downcategoryinformation DC on downcodeinformation.Catagory = DC.DownCategory	
		WHERE downcodeinformation.Catagory <> 'Operator' and autodata.DataType=2  and T.MachineInterface=autodata.mc  
		AND(
		(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
		OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
		OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
		OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
		)
		AND (downcodeinformation.availeffy = 0)
		group by T.Machine,autodata.opr,T.ShiftSt ) as t2 inner join #OprDetails S on t2.intime=S.ShiftStart and t2.machine=S.machine
		and t2.opr=S.oprinterface
	
	UPDATE #OprDetails SET MLossforOthers = isnull(MLossforOthers,0)+ isNull(t4.Mloss,0),MLDownOthers=isNull(MLDownOthers,0)+isNull(t4.Dloss,0)
	from
	(select T3.mc,T3.opr,T3.StrtShft,sum(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss from
	 (
	select   t1.id,T1.mc,T1.opr,T1.Threshold,T1.StartShift as StrtShft,
	case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0) > 0
	then DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)- isnull(T1.Threshold ,0)
	else 0 End  as Dloss,
	case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0) > 0
	then isnull(T1.Threshold,0)
	else DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0) End  as Mloss
	 from
	
	(   select id,mc,comp,opn,opr,D.threshold,S.ShiftStart as StartShift,
		case when autodata.sttime<S.ShiftStart then S.ShiftStart else sttime END as sttime,
	       	case when ndtime>S.ShiftEnd then S.ShiftEnd else ndtime END as ndtime
		from #T_autodata autodata 
		inner join downcodeinformation D on autodata.dcode=D.interfaceid 
		Inner join Downcategoryinformation DC on D.Catagory = DC.DownCategory	
		inner join #OprDetails S on autodata.mc=S.MachineInterface and autodata.opr=S.Oprinterface
		where D.Catagory <> 'Operator' and autodata.datatype=2 AND
		(
		(autodata.msttime>=S.ShiftStart  and  autodata.ndtime<=S.ShiftEnd)
		OR (autodata.sttime<S.ShiftStart and  autodata.ndtime>S.ShiftStart and autodata.ndtime<=S.ShiftEnd)
		OR (autodata.msttime>=S.ShiftStart  and autodata.sttime<S.ShiftEnd  and autodata.ndtime>S.ShiftEnd)
		OR (autodata.msttime<S.ShiftStart and autodata.ndtime>S.ShiftEnd )
		) AND (D.availeffy = 1)
	   and (D.ThresholdfromCO <>1) ) as T1 	 --NR0097
	left outer join
	(SELECT T.Shiftst  as intime, autodata.id,
		       sum(CASE
			WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PPDT
		from #T_autodata autodata  
		CROSS jOIN #PlannedDownTimesShift T 
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		Inner join Downcategoryinformation DC on downcodeinformation.Catagory = DC.DownCategory	
		WHERE  downcodeinformation.Catagory <> 'Operator' and autodata.DataType=2 and T.MachineInterface=autodata.mc AND
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)
			 AND (downcodeinformation.availeffy = 1) 
	         and (downcodeinformation.ThresholdfromCO <>1) --NR0097
			group by autodata.id,T.Shiftst ) as T2 on T1.id=T2.id  and T1.StartShift=T2.intime ) as T3  group by T3.mc,T3.opr,T3.StrtShft
	) as t4 inner join #OprDetails S on t4.StrtShft=S.ShiftStart and t4.mc=S.MachineInterface and t4.opr=S.oprinterface

	UPDATE #OprDetails  set Others = isnull(Others,0)+isnull(MLossforOthers,0)+isNull(MLDownOthers,0)
	
END


----------------------------- NR0097 Added From here ----------------------------------------------
select S.ShiftStart,S.ShiftEnd,autodata.id,autodata.mc,autodata.comp,autodata.opn,autodata.opr,
isnull(CO.Stdsetuptime,0)AS Stdsetuptime,sum(
case 
when ((autodata.msttime>=S.ShiftStart) and (autodata.ndtime<=S.ShiftEnd)) then  autodata.loadunload
when ((autodata.sttime<S.ShiftStart)and (autodata.ndtime>S.ShiftStart)and (autodata.ndtime<=S.ShiftEnd)) then DateDiff(second, S.ShiftStart, ndtime)
when ((autodata.msttime>=S.ShiftStart)and (autodata.msttime<S.ShiftEnd)and (autodata.ndtime>S.ShiftEnd)) then DateDiff(second, stTime, S.ShiftEnd)
when ((autodata.msttime<S.ShiftStart)and (autodata.ndtime>S.ShiftEnd)) then DateDiff(second, S.ShiftStart, S.ShiftEnd) END ) 
as setuptime,0 as ML,0 as Downtime
into #setuptime
from #T_autodata autodata
inner join machineinformation M on autodata.mc = M.interfaceid
inner join downcodeinformation D on autodata.dcode=D.interfaceid
Inner join Downcategoryinformation DC on D.Catagory = DC.DownCategory
inner join #OprDetails S on autodata.mc=S.MachineInterface and autodata.opr=S.Oprinterface
left outer join componentinformation CI on autodata.comp = CI.interfaceid
left outer join componentoperationpricing CO on autodata.opn =  CO.interfaceid and CI.componentid = CO.componentid and CO.machineid = M.machineid
where D.Catagory <> 'Operator' and autodata.datatype=2 and D.ThresholdfromCO = 1
And
(((autodata.msttime>=S.ShiftStart) and (autodata.ndtime<=S.ShiftEnd))
  OR ((autodata.msttime<S.ShiftStart)and (autodata.ndtime>S.ShiftStart)and (autodata.ndtime<=S.ShiftEnd))
  OR ((autodata.msttime>=S.ShiftStart)and (autodata.msttime<S.ShiftEnd)and (autodata.ndtime>S.ShiftEnd))
  OR ((autodata.msttime<S.ShiftStart)and (autodata.ndtime>S.ShiftEnd)))
group by autodata.id,autodata.mc,autodata.comp,autodata.opn,CO.Stdsetuptime,autodata.opr,S.ShiftStart,S.ShiftEnd

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN
	update #setuptime set setuptime = isnull(setuptime,0) - isnull(t1.setuptime_pdt,0) from 
	(
		select autodata.id,autodata.mc,autodata.comp,autodata.opn,autodata.opr,S.ShiftStart,S.ShiftEnd,
		sum(datediff(s,CASE WHEN autodata.msttime >= T.StartTime THEN autodata.msttime else T.StartTime End,
		CASE WHEN autodata.ndtime <= T.EndTime THEN autodata.ndtime else T.EndTime End))
		as setuptime_pdt
		from #T_autodata autodata
		inner join machineinformation M on autodata.mc = M.interfaceid
		inner join componentinformation CI on autodata.comp = CI.interfaceid
		inner join componentoperationpricing CO on autodata.opn =  CO.interfaceid and CI.componentid = CO.componentid and CO.machineid = M.machineid
		inner join downcodeinformation D on autodata.dcode=D.interfaceid
		Inner join Downcategoryinformation DC on D.Catagory = DC.DownCategory
		inner join #OprDetails S on autodata.mc=S.MachineInterface and autodata.opr=S.Oprinterface
		CROSS jOIN #PlannedDownTimesShift T
		where D.Catagory <> 'Operator' and datatype=2 and T.MachineInterface=AutoData.mc 
		and D.ThresholdfromCO = 1 And
		((autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
		OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
		OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )
		OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime)
		)AND
		(((autodata.msttime>=S.ShiftStart) and (autodata.ndtime<=S.ShiftEnd))
		OR ((autodata.msttime<S.ShiftStart)and (autodata.ndtime>S.ShiftStart)and (autodata.ndtime<=S.ShiftEnd))
		OR ((autodata.msttime>=S.ShiftStart)and (autodata.msttime<S.ShiftEnd)and (autodata.ndtime>S.ShiftEnd))
		OR ((autodata.msttime<S.ShiftStart)and (autodata.ndtime>S.ShiftEnd))) AND
		((S.ShiftStart >= T.StartTime  AND S.ShiftEnd <=T.EndTime)
		OR ( S.ShiftStart < T.StartTime  AND S.ShiftEnd <= T.EndTime AND S.ShiftEnd > T.StartTime )
		OR ( S.ShiftStart >= T.StartTime   AND S.ShiftStart <T.EndTime AND S.ShiftEnd > T.EndTime )
		OR ( S.ShiftStart < T.StartTime  AND S.ShiftEnd > T.EndTime)
		)
		group by autodata.id,autodata.mc,autodata.comp,autodata.opn,autodata.opr,S.ShiftStart,S.ShiftEnd
	) as t1 inner join #setuptime on t1.id=#setuptime.id and t1.mc = #setuptime.mc and #setuptime.comp = t1.comp and #setuptime.opn = t1.opn and #setuptime.opr = t1.opr
	 and t1.ShiftStart=#setuptime.ShiftStart

	Update #setuptime set Downtime = isnull(Downtime,0) + isnull(T1.Setupdown,0) from
	(Select id,mc,comp,opn,opr,shiftstart,
	Case when setuptime>stdsetuptime then setuptime-stdsetuptime else 0 end as Setupdown
	from #setuptime)T1 inner join #setuptime on t1.id=#setuptime.id and t1.mc = #setuptime.mc and #setuptime.comp = t1.comp and #setuptime.opn = t1.opn and #setuptime.opr = t1.opr
	and t1.ShiftStart=#setuptime.ShiftStart
End

Update #setuptime set ML = Isnull(ML,0) + isnull(T1.SetupML,0) from
(Select id,mc,comp,opn,opr,shiftstart,
Case when setuptime<stdsetuptime then setuptime else stdsetuptime end as SetupML
from #setuptime)T1 inner join #setuptime on t1.id=#setuptime.id and t1.mc = #setuptime.mc and #setuptime.comp = t1.comp and #setuptime.opn = t1.opn and #setuptime.opr = t1.opr
and t1.ShiftStart=#setuptime.ShiftStart

Update #OprDetails SET Others = isnull(Others,0)+ isnull(T1.down,0)  , MLossforOthers = isnull(MLossforOthers,0)+isnull(T1.ML,0) from
(Select mc,opr,shiftstart,Sum(ML) as ML,Sum(Downtime) as Down from #setuptime Group By mc,opr,shiftstart)T1
inner join #OprDetails on t1.shiftstart=#OprDetails.ShiftStart and t1.mc=#OprDetails.MachineInterface and t1.opr=#OprDetails.oprinterface
----------------------------- NR0097 Added Till here ----------------------------------------------


If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y')
BEGIN
	--Type 1
	UPDATE #OprDetails SET Downtime = isnull(Downtime,0) + isNull(t2.down,0)
	from
	(select mc,autodata.opr,
	sum(loadunload) down,S.ShiftStart as ShiftStart
	from #T_autodata autodata 
	inner join #OprDetails S on autodata.mc=S.MachineInterface and autodata.opr=S.Oprinterface
	INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
	Inner join Downcategoryinformation DC on downcodeinformation.Catagory = DC.DownCategory
	where downcodeinformation.Catagory = 'Operator' and (autodata.msttime>=S.ShiftStart)
	and (autodata.ndtime<= S.ShiftEnd)
	and (autodata.datatype=2)
	group by autodata.mc,autodata.opr,S.ShiftStart
	) as t2 inner join #OprDetails on t2.mc = #OprDetails.machineinterface
	and t2.ShiftStart=#OprDetails.ShiftStart and t2.opr=#OprDetails.oprinterface
	
	-- Type 2
	UPDATE #OprDetails SET Downtime = isnull(Downtime,0) + isNull(t2.down,0)
	from
	(select mc,autodata.opr,
		sum(DateDiff(second, S.ShiftStart, ndtime)) down,S.ShiftStart as ShiftStart
	from #T_autodata autodata 
	inner join #OprDetails S on autodata.mc=S.MachineInterface and autodata.opr=S.Oprinterface
	INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
	Inner join Downcategoryinformation DC on downcodeinformation.Catagory = DC.DownCategory
	where downcodeinformation.Catagory= 'Operator' and (autodata.sttime<S.ShiftStart)
	and (autodata.ndtime>S.ShiftStart)
	and (autodata.ndtime<= S.ShiftEnd)
	and (autodata.datatype=2)
	group by autodata.mc,autodata.opr,S.ShiftStart
	) as t2 inner join #OprDetails on t2.mc = #OprDetails.machineinterface
	and t2.ShiftStart=#OprDetails.ShiftStart and t2.opr=#OprDetails.oprinterface
	
	
	-- Type 3
	UPDATE #OprDetails SET Downtime = isnull(Downtime,0) + isNull(t2.down,0)
	from
	(select mc,autodata.opr,
		sum(DateDiff(second, stTime,  S.ShiftEnd)) down,S.ShiftStart as ShiftStart
	from #T_autodata autodata 
	inner join #OprDetails S on autodata.mc=S.MachineInterface and autodata.opr=S.Oprinterface
	INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
	Inner join Downcategoryinformation DC on downcodeinformation.Catagory = DC.DownCategory
	where downcodeinformation.Catagory ='Operator' and  (autodata.msttime>=S.ShiftStart)
	and (autodata.sttime< S.ShiftEnd)
	and (autodata.ndtime> S.ShiftEnd)
	and (autodata.datatype=2)group by autodata.mc,autodata.opr,S.ShiftStart
	) as t2 inner join #OprDetails on t2.mc = #OprDetails.machineinterface
	and t2.ShiftStart=#OprDetails.ShiftStart and t2.opr=#OprDetails.oprinterface
	
	
	-- Type 4
	UPDATE #OprDetails SET Downtime = isnull(Downtime,0) + isNull(t2.down,0)
	from
	(select mc,autodata.opr,
		sum(DateDiff(second, S.ShiftStart,  S.ShiftEnd)) down,S.ShiftStart as ShiftStart
	from #T_autodata autodata
    inner join #OprDetails S on autodata.mc=S.MachineInterface and autodata.opr=S.Oprinterface
	INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
	Inner join Downcategoryinformation DC on downcodeinformation.Catagory = DC.DownCategory
	where downcodeinformation.Catagory = 'Operator' and autodata.msttime<S.ShiftStart
	and autodata.ndtime> S.ShiftEnd
	and (autodata.datatype=2)
	group by autodata.mc,autodata.opr,S.ShiftStart
	) as t2 inner join #OprDetails on t2.mc = #OprDetails.machineinterface
	and t2.ShiftStart=#OprDetails.ShiftStart  and t2.opr=#OprDetails.oprinterface

	---Management Loss-----
	-- Type 1
	UPDATE #OprDetails SET MLossforDowntime = isnull(MLossforDowntime,0) + isNull(t2.loss,0)
	from
	(select mc,opr,
		sum(CASE
	WHEN loadunload >ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)
	ELSE loadunload
	END) loss,S.ShiftStart as ShiftStart
	from #T_autodata autodata 
	inner join #OprDetails S on autodata.mc=S.MachineInterface and autodata.opr=S.Oprinterface
	INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid 
	Inner join Downcategoryinformation DC on downcodeinformation.Catagory = DC.DownCategory
	where downcodeinformation.Catagory = 'Operator' and (autodata.msttime>=S.ShiftStart)
	and (autodata.ndtime<=S.ShiftEnd)
	and (autodata.datatype=2)
	and (downcodeinformation.availeffy = 1)
	and (downcodeinformation.ThresholdfromCO <>1) --NR0097
	group by autodata.mc,opr,S.ShiftStart
	) as t2 inner join #OprDetails on t2.mc = #OprDetails.machineinterface
	and t2.ShiftStart=#OprDetails.ShiftStart  and t2.opr=#OprDetails.oprinterface

	-- Type 2
	UPDATE #OprDetails SET MLossforDowntime = isnull(MLossforDowntime,0) + isNull(t2.loss,0)
	from
	(select mc,opr,
		sum(CASE
	WHEN DateDiff(second, S.ShiftStart, ndtime)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)
	ELSE DateDiff(second, S.ShiftStart, ndtime)
	end) loss,S.ShiftStart as ShiftStart
	from #T_autodata autodata
    inner join #OprDetails S on autodata.mc=S.MachineInterface and autodata.opr=S.Oprinterface
	INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid 
	Inner join Downcategoryinformation DC on downcodeinformation.Catagory = DC.DownCategory
	where downcodeinformation.Catagory = 'Operator'  and (autodata.sttime<S.ShiftStart)
	and (autodata.ndtime>S.ShiftStart)
	and (autodata.ndtime<=S.ShiftEnd)
	and (autodata.datatype=2)
	and (downcodeinformation.ThresholdfromCO <>1) --NR0097
	and (downcodeinformation.availeffy = 1)
	group by autodata.mc,opr,S.ShiftStart
	) as t2 inner join #OprDetails on t2.mc = #OprDetails.machineinterface
	and t2.ShiftStart=#OprDetails.ShiftStart and t2.opr=#OprDetails.oprinterface

	-- Type 3
	UPDATE #OprDetails SET MLossforDowntime = isnull(MLossforDowntime,0) + isNull(t2.loss,0)
	from
	(select      mc,opr,
		sum(CASE
	WHEN DateDiff(second, stTime, S.ShiftEnd)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)ELSE DateDiff(second, stTime, S.ShiftEnd)
	END) loss,S.ShiftStart as ShiftStart
	from #T_autodata autodata  
    inner join #OprDetails S on autodata.mc=S.MachineInterface and autodata.opr=S.Oprinterface
	INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid 
	Inner join Downcategoryinformation DC on downcodeinformation.Catagory = DC.DownCategory
	where  downcodeinformation.Catagory = 'Operator' and (autodata.msttime>=S.ShiftStart)
	and (autodata.sttime<S.ShiftEnd)
	and (autodata.ndtime>S.ShiftEnd)
	and (autodata.datatype=2)
	and (downcodeinformation.availeffy = 1)
	and (downcodeinformation.ThresholdfromCO <>1) --NR0097
	group by autodata.mc,opr,S.ShiftStart
	) as t2 inner join #OprDetails on t2.mc = #OprDetails.machineinterface
	and t2.ShiftStart=#OprDetails.ShiftStart and t2.opr=#OprDetails.oprinterface

	-- Type 4
	UPDATE #OprDetails SET MLossforDowntime = isnull(MLossforDowntime,0) + isNull(t2.loss,0)
	from
	(select mc,opr,
		sum(CASE
	WHEN DateDiff(second, S.ShiftStart, S.ShiftEnd)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)
	ELSE DateDiff(second, S.ShiftStart, S.ShiftEnd)
	END) loss,S.ShiftStart as ShiftStart
	from #T_autodata autodata 
    inner join #OprDetails S on autodata.mc=S.MachineInterface and autodata.opr=S.Oprinterface
	INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid 
	Inner join Downcategoryinformation DC on downcodeinformation.Catagory = DC.DownCategory	
	where downcodeinformation.Catagory = 'Operator' and autodata.msttime<S.ShiftStart
	and autodata.ndtime>S.ShiftEnd
	and (autodata.datatype=2)
	and (downcodeinformation.availeffy = 1)
	and (downcodeinformation.ThresholdfromCO <>1) --NR0097
	group by autodata.mc,opr,S.ShiftStart
	) as t2 inner join #OprDetails on t2.mc = #OprDetails.machineinterface
	and t2.ShiftStart=#OprDetails.ShiftStart and t2.opr=#OprDetails.oprinterface
END

---mod 12:Get the down time and Management loss when setting for 'Ignore_Dtime_4m_PLD'='Y'
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN

	---Get the down times which are not of type Management Loss
	UPDATE #OprDetails SET Downtime = isnull(Downtime,0) + isNull(t2.down,0)
	from
	(select      mc,opr,
		sum(case when ( (autodata.msttime>=S.ShiftStart) and (autodata.ndtime<=S.ShiftEnd)) then  loadunload
			 when ((autodata.sttime<S.ShiftStart)and (autodata.ndtime>S.ShiftStart)and (autodata.ndtime<=S.ShiftEnd)) then DateDiff(second, S.ShiftStart, ndtime)
			 when ((autodata.msttime>=S.ShiftStart)and (autodata.msttime<S.ShiftEnd)and (autodata.ndtime>S.ShiftEnd)) then DateDiff(second, stTime, S.ShiftEnd)
			 when ((autodata.msttime<S.ShiftStart)and (autodata.ndtime>S.ShiftEnd)) then DateDiff(second, S.ShiftStart, S.ShiftEnd) END ) as down,S.ShiftStart as ShiftStart
	   from #T_autodata autodata 
	   inner join #OprDetails S on autodata.mc=S.MachineInterface and autodata.opr=S.Oprinterface
	   inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
	   Inner join Downcategoryinformation DC on downcodeinformation.Catagory = DC.DownCategory	
	where downcodeinformation.Catagory = 'Operator' and (autodata.datatype=2) AND(( (autodata.msttime>=S.ShiftStart) and (autodata.ndtime<=S.ShiftEnd))
	      OR ((autodata.msttime<S.ShiftStart)and (autodata.ndtime>S.ShiftStart)and (autodata.ndtime<=S.ShiftEnd))
	      OR ((autodata.msttime>=S.ShiftStart)and (autodata.msttime<S.ShiftEnd)and (autodata.ndtime>S.ShiftEnd))
	      OR((autodata.msttime<S.ShiftStart)and (autodata.ndtime>S.ShiftEnd))) AND (downcodeinformation.availeffy = 0)
	      group by autodata.mc,opr,S.ShiftStart
	) as t2 inner join #OprDetails on t2.mc = #OprDetails.machineinterface
	and t2.ShiftStart=#OprDetails.ShiftStart and t2.opr=#OprDetails.oprinterface
	
	UPDATE #OprDetails SET Downtime = isnull(Downtime,0) - isNull(t2.PldDown,0)
	from(
		select T.Shiftst as intime,T.Machine as machine,autodata.opr,SUM
		       (CASE
			WHEN (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN autodata.loadunload
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PldDown
		from #T_autodata autodata  
		CROSS jOIN #PlannedDownTimesShift T
		INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID
		Inner join Downcategoryinformation DC on downcodeinformation.Catagory = DC.DownCategory	
		WHERE downcodeinformation.Catagory = 'Operator' and autodata.DataType=2  and T.MachineInterface=autodata.mc  
		AND(
		(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
		OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
		OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
		OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
		)
		AND (downcodeinformation.availeffy = 0)
		group by T.Machine,autodata.opr,T.ShiftSt ) as t2 inner join #OprDetails S on t2.intime=S.ShiftStart and t2.machine=S.machine
		and t2.opr=S.oprinterface
	
	UPDATE #OprDetails SET MLossforDowntime = isnull(MLossforDowntime,0)+ isNull(t4.Mloss,0),MLDown=isNull(MLDown,0)+isNull(t4.Dloss,0)
	from
	(select T3.mc,T3.opr,T3.StrtShft,sum(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss from
	 (
	select   t1.id,T1.mc,T1.opr,T1.Threshold,T1.StartShift as StrtShft,
	case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0) > 0
	then DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)- isnull(T1.Threshold ,0)
	else 0 End  as Dloss,
	case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0) > 0
	then isnull(T1.Threshold,0)
	else DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0) End  as Mloss
	 from
	
	(   select id,mc,comp,opn,opr,D.threshold,S.ShiftStart as StartShift,
		case when autodata.sttime<S.ShiftStart then S.ShiftStart else sttime END as sttime,
	       	case when ndtime>S.ShiftEnd then S.ShiftEnd else ndtime END as ndtime
		from #T_autodata autodata 
		inner join downcodeinformation D on autodata.dcode=D.interfaceid 
		Inner join Downcategoryinformation DC on D.Catagory = DC.DownCategory	
		inner join #OprDetails S on autodata.mc=S.MachineInterface and autodata.opr=S.Oprinterface
		where D.Catagory = 'Operator' and autodata.datatype=2 AND
		(
		(autodata.msttime>=S.ShiftStart  and  autodata.ndtime<=S.ShiftEnd)
		OR (autodata.sttime<S.ShiftStart and  autodata.ndtime>S.ShiftStart and autodata.ndtime<=S.ShiftEnd)
		OR (autodata.msttime>=S.ShiftStart  and autodata.sttime<S.ShiftEnd  and autodata.ndtime>S.ShiftEnd)
		OR (autodata.msttime<S.ShiftStart and autodata.ndtime>S.ShiftEnd )
		) AND (D.availeffy = 1)
		AND (D.ThresholdfromCO <>1) --NR0097
		) as T1 	
	left outer join
	(SELECT T.Shiftst  as intime, autodata.id,
		       sum(CASE
			WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PPDT
		from #T_autodata autodata  
		CROSS jOIN #PlannedDownTimesShift T 
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		Inner join Downcategoryinformation DC on downcodeinformation.Catagory = DC.DownCategory	
		WHERE  downcodeinformation.Catagory = 'Operator' and autodata.DataType=2 and T.MachineInterface=autodata.mc AND
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)
			 AND (downcodeinformation.availeffy = 1) 
			 and (downcodeinformation.ThresholdfromCO <>1) --NR0097
		group by autodata.id,T.Shiftst ) as T2 on T1.id=T2.id  and T1.StartShift=T2.intime ) as T3  group by T3.mc,T3.opr,T3.StrtShft
	) as t4 inner join #OprDetails S on t4.StrtShft=S.ShiftStart and t4.mc=S.MachineInterface and t4.opr=S.oprinterface

	UPDATE #OprDetails  set Downtime = isnull(Downtime,0)+isnull(MLossforDowntime,0)+isNull(MLDown,0)
	
END

----------------------------- NR0097 Added From here ----------------------------------------------
select S.ShiftStart,S.ShiftEnd,autodata.id,autodata.mc,autodata.comp,autodata.opn,autodata.opr,
isnull(CO.Stdsetuptime,0)AS Stdsetuptime,sum(
case 
when ((autodata.msttime>=S.ShiftStart) and (autodata.ndtime<=S.ShiftEnd)) then  autodata.loadunload
when ((autodata.sttime<S.ShiftStart)and (autodata.ndtime>S.ShiftStart)and (autodata.ndtime<=S.ShiftEnd)) then DateDiff(second, S.ShiftStart, ndtime)
when ((autodata.msttime>=S.ShiftStart)and (autodata.msttime<S.ShiftEnd)and (autodata.ndtime>S.ShiftEnd)) then DateDiff(second, stTime, S.ShiftEnd)
when ((autodata.msttime<S.ShiftStart)and (autodata.ndtime>S.ShiftEnd)) then DateDiff(second, S.ShiftStart, S.ShiftEnd) END ) 
as setuptime,0 as ML,0 as Downtime
into #OprLevelsetuptime
from #T_autodata autodata
inner join machineinformation M on autodata.mc = M.interfaceid
inner join downcodeinformation D on autodata.dcode=D.interfaceid
Inner join Downcategoryinformation DC on D.Catagory = DC.DownCategory
inner join #OprDetails S on autodata.mc=S.MachineInterface and autodata.opr=S.Oprinterface
left outer join componentinformation CI on autodata.comp = CI.interfaceid
left outer join componentoperationpricing CO on autodata.opn =  CO.interfaceid and CI.componentid = CO.componentid and CO.machineid = M.machineid
where D.Catagory = 'Operator' and autodata.datatype=2 and D.ThresholdfromCO = 1
And
(((autodata.msttime>=S.ShiftStart) and (autodata.ndtime<=S.ShiftEnd))
  OR ((autodata.msttime<S.ShiftStart)and (autodata.ndtime>S.ShiftStart)and (autodata.ndtime<=S.ShiftEnd))
  OR ((autodata.msttime>=S.ShiftStart)and (autodata.msttime<S.ShiftEnd)and (autodata.ndtime>S.ShiftEnd))
  OR ((autodata.msttime<S.ShiftStart)and (autodata.ndtime>S.ShiftEnd)))
group by autodata.id,autodata.mc,autodata.comp,autodata.opn,CO.Stdsetuptime,autodata.opr,S.ShiftStart,S.ShiftEnd

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN
	update #OprLevelsetuptime set setuptime = isnull(setuptime,0) - isnull(t1.setuptime_pdt,0) from 
	(
		select autodata.id,autodata.mc,autodata.comp,autodata.opn,autodata.opr,S.ShiftStart,S.ShiftEnd,
		sum(datediff(s,CASE WHEN autodata.msttime >= T.StartTime THEN autodata.msttime else T.StartTime End,
		CASE WHEN autodata.ndtime <= T.EndTime THEN autodata.ndtime else T.EndTime End))
		as setuptime_pdt
		from #T_autodata autodata
		inner join machineinformation M on autodata.mc = M.interfaceid
		inner join componentinformation CI on autodata.comp = CI.interfaceid
		inner join componentoperationpricing CO on autodata.opn =  CO.interfaceid and CI.componentid = CO.componentid and CO.machineid = M.machineid
		inner join downcodeinformation D on autodata.dcode=D.interfaceid
		Inner join Downcategoryinformation DC on D.Catagory = DC.DownCategory
		inner join #OprDetails S on autodata.mc=S.MachineInterface and autodata.opr=S.Oprinterface
		CROSS jOIN #PlannedDownTimesShift T
		where D.Catagory = 'Operator' and datatype=2 and T.MachineInterface=AutoData.mc 
		and D.ThresholdfromCO = 1 And
		((autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
		OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
		OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )
		OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime)
		)AND
		(((autodata.msttime>=S.ShiftStart) and (autodata.ndtime<=S.ShiftEnd))
		OR ((autodata.msttime<S.ShiftStart)and (autodata.ndtime>S.ShiftStart)and (autodata.ndtime<=S.ShiftEnd))
		OR ((autodata.msttime>=S.ShiftStart)and (autodata.msttime<S.ShiftEnd)and (autodata.ndtime>S.ShiftEnd))
		OR ((autodata.msttime<S.ShiftStart)and (autodata.ndtime>S.ShiftEnd))) AND
		((S.ShiftStart >= T.StartTime  AND S.ShiftEnd <=T.EndTime)
		OR ( S.ShiftStart < T.StartTime  AND S.ShiftEnd <= T.EndTime AND S.ShiftEnd > T.StartTime )
		OR ( S.ShiftStart >= T.StartTime   AND S.ShiftStart <T.EndTime AND S.ShiftEnd > T.EndTime )
		OR ( S.ShiftStart < T.StartTime  AND S.ShiftEnd > T.EndTime)
		)
		group by autodata.id,autodata.mc,autodata.comp,autodata.opn,autodata.opr,S.ShiftStart,S.ShiftEnd
	) as t1 inner join #OprLevelsetuptime on t1.id=#OprLevelsetuptime.id and t1.mc = #OprLevelsetuptime.mc and #OprLevelsetuptime.comp = t1.comp and #OprLevelsetuptime.opn = t1.opn and #OprLevelsetuptime.opr = t1.opr
	 and t1.ShiftStart=#OprLevelsetuptime.ShiftStart

	Update #OprLevelsetuptime set Downtime = isnull(Downtime,0) + isnull(T1.Setupdown,0) from
	(Select id,mc,comp,opn,opr,shiftstart,
	Case when setuptime>stdsetuptime then setuptime-stdsetuptime else 0 end as Setupdown
	from #OprLevelsetuptime)T1 inner join #OprLevelsetuptime on t1.id=#OprLevelsetuptime.id and t1.mc = #OprLevelsetuptime.mc and #OprLevelsetuptime.comp = t1.comp and #OprLevelsetuptime.opn = t1.opn and #OprLevelsetuptime.opr = t1.opr
	and t1.ShiftStart=#OprLevelsetuptime.ShiftStart
End

Update #OprLevelsetuptime set ML = Isnull(ML,0) + isnull(T1.SetupML,0) from
(Select id,mc,comp,opn,opr,shiftstart,
Case when setuptime<stdsetuptime then setuptime else stdsetuptime end as SetupML
from #OprLevelsetuptime)T1 inner join #OprLevelsetuptime on t1.id=#OprLevelsetuptime.id and t1.mc = #OprLevelsetuptime.mc and #OprLevelsetuptime.comp = t1.comp and #OprLevelsetuptime.opn = t1.opn and #OprLevelsetuptime.opr = t1.opr
and t1.ShiftStart=#OprLevelsetuptime.ShiftStart

Update #OprDetails SET downtime = isnull(downtime,0)+ isnull(T1.down,0)  , MLossforDowntime = isnull(MLossforDowntime,0)+isnull(T1.ML,0) from
(Select mc,opr,shiftstart,Sum(ML) as ML,Sum(Downtime) as Down from #OprLevelsetuptime Group By mc,opr,shiftstart)T1
inner join #OprDetails on t1.shiftstart=#OprDetails.ShiftStart and t1.mc=#OprDetails.MachineInterface and t1.opr=#OprDetails.oprinterface
----------------------------- NR0097 Added Till here ----------------------------------------------


UPDATE #OprDetails SET CN = isnull(CN,0) + isNull(t2.C1N1,0)
from
(select mc,opr,
  SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))*autodata.partscount) C1N1,
	S.Pdate as date1,S.ShiftStart as ShiftStart
   from #T_autodata autodata 
INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID 
INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID AND
componentoperationpricing.componentid = componentinformation.componentid
inner join machineinformation on machineinformation.interfaceid=autodata.mc
and componentoperationpricing.machineid=machineinformation.machineid
inner join #OprDetails S on autodata.mc=S.MachineInterface and autodata.opr=S.Oprinterface
  where (autodata.ndtime>S.ShiftStart)
	and (autodata.ndtime<=S.shiftend)
	and (autodata.datatype=1)
  group by autodata.mc,opr,S.Pdate,S.ShiftStart
) as t2 inner join #OprDetails on t2.mc = #OprDetails.machineinterface and t2.opr = #OprDetails.oprinterface
and t2.date1=#OprDetails.Pdate and t2.ShiftStart=#OprDetails.ShiftStart
		

---Mod 12 Apply PDT for Utilized time and ICD's
---mod 12 Apply PDT for CN calculation
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	UPDATE #OprDetails SET CN = isnull(CN,0) - isNull(t2.C1N1,0)
	From
	(
		select M.Machineid as machine,A.opr,T.Shiftst as initime,SUM((O.cycletime * ISNULL(A.PartsCount,1))/ISNULL(O.SubOperations,1))  C1N1
		from #T_autodata  A inner join machineinformation M on A.mc=M.interfaceid 
		Inner join componentinformation C ON A.Comp=C.interfaceid
		Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid AND O.Machineid=M.Machineid --DR0299 Sneha K
		CROSS jOIN #PlannedDownTimesShift T
		WHERE A.DataType=1 and T.MachineInterface=A.mc
		AND(A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)
		Group by M.Machineid,T.shiftst,A.opr
	) as T2
	inner join #OprDetails S  on t2.initime=S.ShiftStart  and t2.machine = S.machine and t2.opr=S.Oprinterface
END

UPDATE #OprDetails
SET
	PE = (CN/Prodtime) ,
	AE = (Prodtime)/(Prodtime + DownTime - MLossforDowntime)
WHERE Prodtime <> 0

UPDATE #OprDetails
SET
	OE = Round((PE * AE)*100,2),
	PE = Round(PE * 100,2) ,
	AE = Round(AE * 100,2)

UPDATE #OprDetails set DownTime = DownTime - MLossforDowntime , Others = Others + MLossforDowntime


If @param = ''
BEGIN
	Select PDate,Shift,Machine,dbo.f_FormatTime(ProdTime,'mm') as ProdTime,dbo.f_FormatTime(Downtime,'mm') as Downtime,dbo.f_FormatTime(Others,'mm') as Others,
	Round(AE,1) as AE,Round(PE,1) as PE,Round(OE,1) as OE from #OprDetails where (isnull(Prodtime,'0')>0 OR isnull(Downtime,'0')>0 OR isnull(others,'0')>0)
	Order by Pdate,Shift,Machine
END

If @param = 'Summary'
BEGIN
	
	Insert into #Summary(ProdTime,Downtime,Others,CN,AE,PE,OE)
	select Sum(Prodtime),Sum(Downtime),Sum(Others),Sum(CN),0,0,0 from #OprDetails

		
	UPDATE #Summary SET PE = (CN/Prodtime) , AE = (Prodtime)/(Prodtime + DownTime)
	WHERE Prodtime <> 0

	UPDATE #Summary
	SET
		OE = Round((PE * AE)*100,2),
		PE = Round(PE * 100,2) ,
		AE = Round(AE * 100,2)

	Select ProdTime,Downtime,Others,Round(CN,2) as CN,AE,PE,OE from #Summary

END

END
