/****** Object:  Procedure [dbo].[s_GetDailyProdandDownReport_RuntimeByMCO]    Committed by VersionSQL https://www.versionsql.com ******/

/************************************************************************************************************
ER0364 - SwathiKS/GeetanjaliK - 19-Sep-013:: SM -> Production Report Machinewise - > Daily -> Format 3
New Excel Report to show MCO Level Production and Down Details.
ER0401 - SwathiKS - 29/Dec/2014 :: To Show All times in "hh" format.
ER0465 - Gopinath - 16/may/2018 :: Performance Optimization(Altered While loop logic).

--s_GetDailyProdandDownReport_RuntimeByMCO '2013-09-02','','','','','2013-09-02' - 2 min 17 sec
**************************************************************************************************************/
CREATE PROCEDURE [dbo].[s_GetDailyProdandDownReport_RuntimeByMCO]
	@StartDate datetime,
	@MachineID nvarchar(50) = '',
	@ComponentID nvarchar(50) = '',
	@OperationNo nvarchar(50) = '',
	@PlantID  Nvarchar(50) = '',
	@EndDate datetime

WITH RECOMPILE
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


Declare @strsql nvarchar(4000)
Declare @strmachine nvarchar(255)
Declare @strcomponentid nvarchar(255)
Declare @stroperation nvarchar(255)
Declare @StrTPMMachines AS nvarchar(500)
Declare @StrMPlantid NVarChar(255)
Declare @timeformat as nvarchar(12)
Declare @StartTime as datetime
Declare @EndTime as datetime

Select @strsql = ''
Select @strcomponentid = ''
Select @stroperation = ''
Select @StrTPMMachines = ''
Select @strmachine = ''
Select @StrMPlantid=''


IF ( SELECT TOP 1 ValueInText FROM  CockpitDefaults WHERE Parameter='TpmEnbMac')='E'
BEGIN
	SET  @StrTPMMachines = 'AND MachineInformation.TPMTrakEnabled = 1'
END
ELSE
BEGIN
	SET  @StrTPMMachines = ' '
END

if isnull(@PlantID,'') <> ''
Begin
	Select @StrMPlantid = ' and ( PlantMachine.PlantID = N''' + @PlantID + ''')'
End

if isnull(@machineid,'') <> ''
Begin
	Select @strmachine = ' and ( Machineinformation.MachineID = N''' + @MachineID + ''')'
End

if isnull(@componentid,'') <> ''
Begin
	Select @strcomponentid = '  AND ( Componentinformation.componentid = N''' + @componentid + ''')'
End

if isnull(@operationno, '') <> ''
Begin
	Select @stroperation = ' AND ( Componentoperationpricing.operationno = N''' + @OperationNo + ''')'
End


--Shift Details
CREATE TABLE #DailyProductionFromAutodataT0 (
	DDate datetime,
	Shift nvarchar(20),
	ShiftStart datetime,
	ShiftEnd datetime
)
--Machine level details
CREATE TABLE #DailyProductionFromAutodataT1 
(
	PlantID nvarchar(50),
	MachineID nvarchar(50) NOT NULL,
	MachineInterface nvarchar(50),
	ProductionEfficiency float,
	AvailabilityEfficiency float,
	OverallEfficiency float,
	UtilisedTime float,
	ManagementLoss float,
	DownTime float,
	CN float,
	Pdate datetime NOT NULL,
	FromTime datetime,
	ToTime datetime,
	MLDown float,
	Operator nvarchar(50),
	DownReason1 nvarchar(50),
	DownReason2 nvarchar(50),
	DownReason3 nvarchar(50)
)
ALTER TABLE #DailyProductionFromAutodataT1 ADD
	 PRIMARY KEY  CLUSTERED
	(       [Pdate],
		[MachineID]
	)  ON [PRIMARY]

--ComponentOperation level details
CREATE TABLE #DailyProductionFromAutodataT2 (
	Cdate datetime not null,
	MachineID nvarchar(50) NOT NULL,
	Component nvarchar(50) NOT NULL,
	Operation nvarchar(50) NOT NULL,
	machineinterface nvarchar(50),
	Compinterface nvarchar(50),
	OpnInterface nvarchar(50),
	CycleTime nvarchar(50),
	LoadUnload nvarchar(50),
	AvgCycleTime nvarchar(50),
	AvgLoadUnload nvarchar(50),
	CountShift1 int,
	CountShift2 int,
	CountShift3 int,
	NameShift1 nvarchar(20),
	NameShift2 nvarchar(20),
	NameShift3 nvarchar(20),
	Runtime float,
	TargetCount int Default 0,
	FromTm datetime,
	ToTm datetime
)
ALTER TABLE #DailyProductionFromAutodataT2 ADD
	 PRIMARY KEY  CLUSTERED
	(
		[Cdate],[MachineID],[Component],[Operation]
		
	)  ON [PRIMARY]


CREATE TABLE #DailyProductionFromAutodataT3 
(

	Cdate datetime NOT NULL,
	MachineID nvarchar(50) NOT NULL,
	machineinterface nvarchar(50),
	Compinterface nvarchar(50),
	OpnInterface nvarchar(50),
	Component nvarchar(50) NOT NULL,
	Operation nvarchar(50) NOT NULL,
	FromTm datetime,
	ToTm datetime,   
    runtime int,   
    plantid nvarchar(50),
	EmployeeName nvarchar(1000),
	Target float
)

CREATE TABLE #DailyProductionFromAutodataT4
(

	Cdate datetime NOT NULL,
	MachineID nvarchar(50) NOT NULL,
	machineinterface nvarchar(50),
	Compinterface nvarchar(50),
	OpnInterface nvarchar(50),
	Component nvarchar(50) NOT NULL,
	Operation nvarchar(50) NOT NULL,
	FromTm datetime,
	ToTm datetime,   
    runtime int,   
    plantid nvarchar(50),
	EmployeeName nvarchar(1000),
	Target float
)

Create table #PlannedDownTimes
(
	MachineID nvarchar(50),
	MachineInterface nvarchar(50),
	StartTime_LogicalDay DateTime,
	EndTime_LogicalDay DateTime,
	StartTime_PDT DateTime,
	EndTime_PDT DateTime,
	pPlannedDT float Default 0,
	dPlannedDT float Default 0,
	MPlannedDT float Default 0,
	IPlannedDT float Default 0,
	DownID nvarchar(50)
)


Create table #MachineLevelDown
(
	FromTime datetime,
	Totime datetime,
	MachineID nvarchar(50),
	MachineInterface nvarchar(50),
	DownID nvarchar(50),
	DownTime nvarchar(50) ,
	PDT int 
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
	[PartsCount] [int] NULL ,
	id  bigint not null
)

ALTER TABLE #T_autodata

ADD PRIMARY KEY CLUSTERED
(
	mc,sttime ASC
)ON [PRIMARY]

CREATE TABLE #T_autodataforDown
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
	[PartsCount] [int] NULL ,
	id  bigint not null
)

ALTER TABLE #T_autodataforDown

ADD PRIMARY KEY CLUSTERED
(
	mc,sttime ASC
)ON [PRIMARY]

Declare @T_ST AS Datetime 
Declare @T_ED AS Datetime
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

Select @strsql=''
select @strsql ='insert into #T_autodataforDown '
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'
 select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'
select @strsql = @strsql + ' from autodata where (datatype=1) and (( sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_ED,120)+''' ) OR '
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' )OR '
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ST,120)+'''
				 and ndtime<='''+convert(nvarchar(25),@T_ED,120)+''' )'
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' and sttime<'''+convert(nvarchar(25),@T_ED,120)+''' ) )'
print @strsql
exec (@strsql)

Select @strsql=''
select @strsql ='insert into #T_autodataforDown '
select @strsql = @strsql + 'SELECT A1.mc, A1.comp, A1.opn, A1.opr, A1.dcode,A1.sttime,'
 select @strsql = @strsql + 'A1.ndtime, A1.datatype, A1.cycletime, A1.loadunload, A1.msttime, A1.PartsCount,A1.id'
select @strsql = @strsql + ' from autodata A1 where A1.datatype=2 and
(( A1.sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and A1.ndtime <= '''+convert(nvarchar(25),@T_ED,120)+'''  ) OR
 ( A1.sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and A1.ndtime >'''+convert(nvarchar(25),@T_ED,120)+'''  )OR 
 (A1.sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and A1.ndtime >'''+ convert(nvarchar(25),@T_ST,120)+''' and A1.ndtime<='''+convert(nvarchar(25),@T_ED,120)+'''  ) or
 (A1.sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and A1.ndtime >'''+convert(nvarchar(25),@T_ED,120)+'''  and A1.sttime<'''+convert(nvarchar(25),@T_ED,120)+'''  ) )
and NOT EXISTS ( select * from Autodata A2 where  A2.datatype=1 and  ((  A2.sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and  A2.ndtime <= '''+convert(nvarchar(25),@T_ED,120)+'''  ) OR
 (A2.sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and  A2.ndtime >'''+convert(nvarchar(25),@T_ED,120)+'''  )OR 
 (A2.sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and  A2.ndtime >'''+ convert(nvarchar(25),@T_ST,120)+''' and  A2.ndtime<='''+convert(nvarchar(25),@T_ED,120)+'''  ) 
OR (A2.sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and  A2.ndtime >'''+convert(nvarchar(25),@T_ED,120)+'''  and  A2.sttime<'''+convert(nvarchar(25),@T_ED,120)+'''  ) )
and A2.sttime<=A1.sttime and A2.ndtime>A1.ndtime and A1.mc=A2.mc)'
print @strsql
exec (@strsql)

declare @Targetsource nvarchar(50)
select @Targetsource=ValueInText from Shopdefaults where Parameter='TargetFrom'
declare @lstart nvarchar(50) --ER0465
declare @lend nvarchar(50) --ER0465


select @StartTime=@StartDate
select @EndTime=@EndDate
while @StartTime<=@EndTime
BEGIN
	set @lstart = dbo.f_GetLogicalDay(@StartTime,'start') --ER0465
	set @lend = dbo.f_GetLogicalDay(@StartTime,'End') --ER0465

	If ISNULL(@PlantID,'')<>''
	BEGIN
		if isnull(@machineid,'')<> ''
		begin
			INSERT INTO #DailyProductionFromAutodataT1 (PlantID,MachineID,MachineInterface,ProductionEfficiency,
			AvailabilityEfficiency,OverallEfficiency,UtilisedTime,ManagementLoss,DownTime,CN,Pdate,FromTime,ToTime)
			SELECT PM.Plantid,M.MachineID, M.interfaceid ,0,0,0,0,0,0,0,convert(nvarchar(20),@StartTime),
			@lstart,@lend
			FROM MachineInformation M Inner Join PlantMachine PM ON PM.MachineID=M.MachineID
			WHERE M.MachineID = @machineid AND PM.PlantID=@PlantID

		end
		else
		begin
			INSERT INTO #DailyProductionFromAutodataT1 (PlantID,MachineID,MachineInterface,ProductionEfficiency,
			AvailabilityEfficiency,OverallEfficiency,UtilisedTime,ManagementLoss,DownTime,CN,Pdate,FromTime,ToTime)
			SELECT PM.Plantid,M.MachineID, M.interfaceid ,0,0,0,0,0,0,0,convert(nvarchar(20),@StartTime),
			@lstart,@lend
			FROM MachineInformation M Inner Join PlantMachine PM ON PM.MachineID=M.MachineID
			where interfaceid > '0' AND PM.PlantID=@PlantID
		end
	END
	ELSE
	BEGIN
		SELECT @StrSql=''
		SELECT @StrSql='INSERT INTO #DailyProductionFromAutodataT1 ('
		SELECT @StrSql=@StrSql+' PlantID,MachineID ,MachineInterface,ProductionEfficiency ,AvailabilityEfficiency ,'			
		SELECT @StrSql=@StrSql+' OverallEfficiency ,UtilisedTime ,ManagementLoss,DownTime ,CN,Pdate,FromTime,ToTime)'
		SELECT @StrSql=@StrSql+' SELECT PM.Plantid,MachineInformation.MachineID,MachineInformation.interfaceid ,0,0,0,0,0,0,0,''' +convert(nvarchar(20),@StartTime)+ ''', '
		SELECT @StrSql=@StrSql+' ''' +@lstart+ ''',''' +@lend+ ''' '
		SELECT @StrSql=@StrSql+' FROM MachineInformation Inner Join PlantMachine PM ON PM.MachineID=MachineInformation.MachineID where interfaceid >''0'''
		SELECT @StrSql=@StrSql+ @strmachine
		Exec(@StrSql)
		SELECT @StrSql=''

	END
	



	--mod 4 Get the Machines into #PLD
	Insert into #PlannedDownTimes
	Select machineinformation.MachineID,machineinformation.InterfaceID,@lstart,@lend,
	 Case When StartTime<@lstart Then @lstart Else StartTime End as StartTime, 	
	 Case When EndTime > @lend Then @lend Else EndTime End as EndTime,
	 0,0,0,0,PlannedDownTimes.DownReason
	 from PlannedDownTimes inner join machineinformation on PlannedDownTimes.machine=machineinformation.machineid
	      Where PlannedDownTimes.PDTstatus =1 AND (
		(StartTime >= @lstart and EndTime <= @lend) OR
		(StartTime < @lstart and EndTime <= @lend and EndTime > @lstart) OR
		(StartTime >= @lstart and EndTime > @lend and StartTime < @lend) OR
		(StartTime < @lstart and EndTime > @lend))
		And machineinformation.MachineID in (select distinct MachineID from #DailyProductionFromAutodataT1)
	--mod 4
	SELECT @StartTime=DATEADD(DAY,1,@StartTime)
END

-- Get the utilised time
-- Type 1
UPDATE #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0) from (
	select mc,sum(cycletime+loadunload) as cycle,D.Pdate as date1
	from #T_autodata autodata inner join #DailyProductionFromAutodataT1 D on autodata.mc=D.machineinterface
	where (autodata.msttime>=D.FromTime)and (autodata.ndtime<=D.ToTime)and (autodata.datatype=1)
	group by autodata.mc,D.Pdate
) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface
and t2.date1=#DailyProductionFromAutodataT1.Pdate
--Type 2
UPDATE #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0) from (
	select mc,sum(DateDiff(second, D.FromTime, ndtime)) cycle,D.Pdate as date1
	from #T_autodata autodata inner join #DailyProductionFromAutodataT1 D on autodata.mc=D.machineinterface
	where (autodata.msttime<D.FromTime)and (autodata.ndtime>D.FromTime)and (autodata.ndtime<=D.ToTime)
	and (autodata.datatype=1) group by autodata.mc,D.Pdate
) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface
and t2.date1=#DailyProductionFromAutodataT1.Pdate
-- Type 3
UPDATE #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0) from (
	select mc,sum(DateDiff(second, mstTime, D.ToTime)) cycle,D.Pdate as date1
	from #T_autodata autodata inner join #DailyProductionFromAutodataT1 D on autodata.mc=D.machineinterface
	where (autodata.msttime>=D.FromTime)and (autodata.msttime<D.ToTime)and (autodata.ndtime>D.ToTime)
	and (autodata.datatype=1)group by autodata.mc,D.Pdate
) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface
and t2.date1=#DailyProductionFromAutodataT1.Pdate
-- Type 4
UPDATE #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isnull(t2.cycle,0) from (
	select mc,sum(DateDiff(second, D.FromTime, D.ToTime)) cycle,D.Pdate as date1
	from #T_autodata autodata inner join #DailyProductionFromAutodataT1 D on autodata.mc=D.machineinterface
	where (autodata.msttime<D.FromTime)and (autodata.ndtime>D.ToTime)and (autodata.datatype=1)
	group by autodata.mc,D.Pdate
)as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface
and t2.date1=#DailyProductionFromAutodataT1.Pdate

/* Fetching Down Records from Production Cycle  */
/* If Down Records of TYPE-2*/
UPDATE  #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0) FROM (
	Select AutoData.mc,SUM(
		CASE
			When autodata.sttime <= D.FromTime Then datediff(s, D.FromTime,autodata.ndtime )
			When autodata.sttime > D.FromTime Then datediff(s , autodata.sttime,autodata.ndtime)
		END) as Down,D.Pdate as date1 From #T_autodata AutoData INNER Join (
			Select mc,Sttime,NdTime,D.Pdate From #T_autodata AutoData inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And (msttime < D.FromTime)And (ndtime > D.FromTime) AND (ndtime <= D.ToTime)
			) as T1
	ON AutoData.mc=T1.mc inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface And T1.Pdate=D.PDate
	Where AutoData.DataType=2
	And ( autodata.Sttime > T1.Sttime )And ( autodata.ndtime <  T1.ndtime )AND ( autodata.ndtime >  D.FromTime )
	GROUP BY AUTODATA.mc,D.Pdate
)AS T2 Inner Join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface 
and t2.date1=#DailyProductionFromAutodataT1.Pdate

/* If Down Records of TYPE-3*/
UPDATE  #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0) FROM (
	Select AutoData.mc,SUM(
		CASE
			When autodata.ndtime > D.ToTime Then datediff(s,autodata.sttime, D.ToTime )
			When autodata.ndtime <=D.ToTime Then datediff(s , autodata.sttime,autodata.ndtime)
		END) as Down,D.Pdate as date1 From #T_autodata AutoData INNER Join (
			Select mc,Sttime,NdTime,D.Pdate From #T_autodata AutoData inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And(sttime >= D.FromTime)And (ndtime > D.ToTime) And (sttime<D.ToTime)
			) as T1
	ON AutoData.mc=T1.mc inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface And T1.Pdate=D.PDate
	Where AutoData.DataType=2 And (T1.Sttime < autodata.sttime)And ( T1.ndtime >  autodata.ndtime)AND (autodata.sttime  <  D.ToTime)
	GROUP BY AUTODATA.mc,D.Pdate
)AS T2 Inner Join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface
 and t2.date1=#DailyProductionFromAutodataT1.Pdate

/* If Down Records of TYPE-4*/
UPDATE  #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0) FROM (
	Select AutoData.mc,
		SUM(CASE
			When autodata.sttime >= D.FromTime AND autodata.ndtime <=D.ToTime Then datediff(s ,autodata.sttime,autodata.ndtime) --Type1
			When autodata.sttime < D.FromTime AND autodata.ndtime>D.FromTime AND autodata.ndtime<=D.ToTime Then datediff(s, D.FromTime,autodata.ndtime ) --Type2
			When autodata.sttime>=D.FromTime AND autodata.sttime<D.ToTime AND autodata.ndtime > D.ToTime Then datediff(s,autodata.sttime, D.ToTime ) --Type3
			When autodata.sttime<D.FromTime AND autodata.ndtime>D.ToTime Then datediff(s ,D.FromTime,D.ToTime)--Type4
		END) as Down,
			D.Pdate as date1 From #T_autodata AutoData INNER Join (
			Select mc,Sttime,NdTime,D.Pdate From #T_autodata AutoData inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And(msttime < D.FromTime)And (ndtime > D.ToTime)
			) as T1
	ON AutoData.mc=T1.mc inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface And T1.Pdate=D.PDate
	Where AutoData.DataType=2 And (T1.Sttime < autodata.sttime)And
(T1.ndtime >  autodata.ndtime) AND (autodata.ndtime  >  D.FromTime) AND (autodata.sttime  <  D.ToTime)
	GROUP BY AUTODATA.mc,D.Pdate
)AS T2 Inner Join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface 
and t2.date1=#DailyProductionFromAutodataT1.Pdate

--mod 4:Get utilised time over lapping with PDT.
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
BEGIN
	--Detect Utilised Time over lapping with PDT
	UPDATE #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.cycle,0) from (
		select mc,StartTime_LogicalDay,EndTime_LogicalDay,
		sum(Case
--			When (autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) then (autodata.cycletime+autodata.loadunload) --DR0325 Commented
			When (autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) then Datediff(s,autodata.msttime,autodata.ndtime) --DR0325 added
			When (autodata.msttime < StartTime_PDT and autodata.ndtime <= EndTime_PDT and autodata.ndtime > StartTime_PDT) then Datediff(s,StartTime_PDT,autodata.ndtime)
			When (autodata.msttime >= StartTime_PDT and autodata.ndtime > EndTime_PDT and autodata.msttime < EndTime_PDT) then Datediff(s,autodata.msttime,EndTime_PDT)
			When (autodata.msttime < StartTime_PDT and autodata.ndtime > EndTime_PDT) then Datediff(s,StartTime_PDT,EndTime_PDT)
		End) as cycle
		from #T_autodata autodata inner join #PlannedDownTimes  on autodata.mc=#PlannedDownTimes.machineinterface
		where (autodata.datatype=1) AND
		((autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) or
		(autodata.msttime < StartTime_PDT and autodata.ndtime <= EndTime_PDT and autodata.ndtime > StartTime_PDT) or
		(autodata.msttime >= StartTime_PDT and autodata.ndtime > EndTime_PDT and autodata.msttime < EndTime_PDT) or
		(autodata.msttime < StartTime_PDT and autodata.ndtime > EndTime_PDT))
		group by autodata.mc,StartTime_LogicalDay,EndTime_LogicalDay
	) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface And
	t2.StartTime_LogicalDay=#DailyProductionFromAutodataT1.FromTime And t2.EndTime_LogicalDay=#DailyProductionFromAutodataT1.ToTime


	/* Fetching Down Records from Production Cycle  */
	/* If production  Records of TYPE-1*/
	--mod 4(4):Handle intearction between ICD and PDT for type 1 production record for the selected time period.
	UPDATE #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.icd,0) from (
		select autodata.mc,StartTime_LogicalDay,EndTime_LogicalDay,
		sum(Case
--			When (autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) then (autodata.cycletime+autodata.loadunload) --DR0325 Commented
			When (autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) then Datediff(s,autodata.msttime,autodata.ndtime) --DR0325 Added
			When (autodata.msttime < StartTime_PDT and autodata.ndtime <= EndTime_PDT and autodata.ndtime > StartTime_PDT) then Datediff(s,StartTime_PDT,autodata.ndtime)
			When (autodata.msttime >= StartTime_PDT and autodata.ndtime > EndTime_PDT and autodata.msttime < EndTime_PDT) then Datediff(s,autodata.msttime,EndTime_PDT)
			When (autodata.msttime < StartTime_PDT and autodata.ndtime > EndTime_PDT) then Datediff(s,StartTime_PDT,EndTime_PDT)
		End) as icd
		from #T_autodata autodata inner join
			(Select mc,sttime,ndtime,D.fromtime from #T_autodata autodata inner join #DailyProductionFromAutodataT1 D on autodata.mc = D.machineinterface
			 where datatype = 1 and Datediff(s,sttime,ndtime) > Cycletime and
			 (autodata.msttime >= D.fromtime and autodata.ndtime <= D.totime)
			 ) as t1 on (autodata.sttime > t1.sttime and autodata.ndtime < t1.ndtime) and Autodata.mc=t1.mc
		inner join 	#PlannedDownTimes  on autodata.mc=#PlannedDownTimes.machineinterface And t1.FromTime=#PlannedDownTimes.StartTime_LogicalDay
		where (autodata.datatype=2) AND
		((autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) or
		(autodata.msttime < StartTime_PDT and autodata.ndtime <= EndTime_PDT and autodata.ndtime > StartTime_PDT) or
		(autodata.msttime >= StartTime_PDT and autodata.ndtime > EndTime_PDT and autodata.msttime < EndTime_PDT) or
		(autodata.msttime < StartTime_PDT and autodata.ndtime > EndTime_PDT))
		group by autodata.mc,StartTime_LogicalDay,EndTime_LogicalDay
	) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface And
	t2.StartTime_LogicalDay=#DailyProductionFromAutodataT1.FromTime And t2.EndTime_LogicalDay=#DailyProductionFromAutodataT1.ToTime

	
	--mod 4(4):Handle intearction between ICD and PDT for type 1 production record for the selected time period.
	/* If production  Records of TYPE-2*/
	UPDATE #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.icd,0) from (
		select autodata.mc,StartTime_LogicalDay,EndTime_LogicalDay,
		sum(Case
--			When (autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) then (autodata.cycletime+autodata.loadunload) --DR0325 Commented
			When (autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) then  Datediff(s,autodata.msttime,autodata.ndtime) --DR0325 added
			When (autodata.msttime < StartTime_PDT and autodata.ndtime <= EndTime_PDT and autodata.ndtime > StartTime_PDT) then Datediff(s,StartTime_PDT,autodata.ndtime)
			When (autodata.msttime >= StartTime_PDT and autodata.ndtime > EndTime_PDT and autodata.msttime < EndTime_PDT) then Datediff(s,autodata.msttime,EndTime_PDT)
			When (autodata.msttime < StartTime_PDT and autodata.ndtime > EndTime_PDT) then Datediff(s,StartTime_PDT,EndTime_PDT)
		End) as icd
		from #T_autodata autodata inner join
			(Select mc,sttime,ndtime,D.fromtime from #T_autodata autodata inner join #DailyProductionFromAutodataT1 D on autodata.mc = D.machineinterface
			 where datatype = 1 and Datediff(s,sttime,ndtime) > Cycletime and
			 (autodata.msttime < D.fromtime and autodata.ndtime > D.totime and autodata.ndtime <= D.totime)
			 ) as t1 on (autodata.sttime > t1.sttime and autodata.ndtime < t1.ndtime) and Autodata.mc=t1.mc
		inner join 	#PlannedDownTimes  on autodata.mc=#PlannedDownTimes.machineinterface And t1.FromTime=#PlannedDownTimes.StartTime_LogicalDay
		where (autodata.datatype=2) AND
		((autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) or
		(autodata.msttime < StartTime_PDT and autodata.ndtime <= EndTime_PDT and autodata.ndtime > StartTime_PDT) or
		(autodata.msttime >= StartTime_PDT and autodata.ndtime > EndTime_PDT and autodata.msttime < EndTime_PDT) or
		(autodata.msttime < StartTime_PDT and autodata.ndtime > EndTime_PDT))
		And (autodata.ndtime > T1.FromTime) And (StartTime_PDT <  T1.ndtime)
		group by autodata.mc,StartTime_LogicalDay,EndTime_LogicalDay
	) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface And
	t2.StartTime_LogicalDay=#DailyProductionFromAutodataT1.FromTime And t2.EndTime_LogicalDay=#DailyProductionFromAutodataT1.ToTime

	/* If production  Records of TYPE-3*/
	UPDATE #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.icd,0) from (
		select autodata.mc,StartTime_LogicalDay,EndTime_LogicalDay,
		sum(Case
--			When (autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) then (autodata.cycletime+autodata.loadunload) --DR0325 Commented
			When (autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) then Datediff(s,autodata.msttime,autodata.ndtime) --DR0325 Added
			When (autodata.msttime < StartTime_PDT and autodata.ndtime <= EndTime_PDT and autodata.ndtime > StartTime_PDT) then Datediff(s,StartTime_PDT,autodata.ndtime)
			When (autodata.msttime >= StartTime_PDT and autodata.ndtime > EndTime_PDT and autodata.msttime < EndTime_PDT) then Datediff(s,autodata.msttime,EndTime_PDT)
			When (autodata.msttime < StartTime_PDT and autodata.ndtime > EndTime_PDT) then Datediff(s,StartTime_PDT,EndTime_PDT)
		End) as icd
		from #T_autodata autodata inner join
			(Select mc,sttime,ndtime,D.fromtime,D.ToTime from #T_autodata autodata inner join #DailyProductionFromAutodataT1 D on autodata.mc = D.machineinterface
			 where datatype = 1 and Datediff(s,sttime,ndtime) > Cycletime and
			 (autodata.sttime >= D.fromtime and autodata.ndtime > D.totime and autodata.sttime < D.totime)
			 ) as t1 on (autodata.sttime > t1.sttime and autodata.ndtime < t1.ndtime) and Autodata.mc=t1.mc
		inner join 	#PlannedDownTimes  on autodata.mc=#PlannedDownTimes.machineinterface And t1.FromTime=#PlannedDownTimes.StartTime_LogicalDay
		where (autodata.datatype=2) AND
		((autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) or
		(autodata.msttime < StartTime_PDT and autodata.ndtime <= EndTime_PDT and autodata.ndtime > StartTime_PDT) or
		(autodata.msttime >= StartTime_PDT and autodata.ndtime > EndTime_PDT and autodata.msttime < EndTime_PDT) or
		(autodata.msttime < StartTime_PDT and autodata.ndtime > EndTime_PDT))
		And (autodata.sttime < T1.ToTime) And (EndTime_PDT > t1.sttime)
		group by autodata.mc,StartTime_LogicalDay,EndTime_LogicalDay
	) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface And
	t2.StartTime_LogicalDay=#DailyProductionFromAutodataT1.FromTime And t2.EndTime_LogicalDay=#DailyProductionFromAutodataT1.ToTime


	/* If production  Records of TYPE-4*/
	UPDATE #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.icd,0) from (
		select autodata.mc,StartTime_LogicalDay,EndTime_LogicalDay,
		sum(Case
--			When (autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) then (autodata.cycletime+autodata.loadunload) --DR0325 Commented
			When (autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) then Datediff(s,autodata.msttime,autodata.ndtime) --DR0325 added
			When (autodata.msttime < StartTime_PDT and autodata.ndtime <= EndTime_PDT and autodata.ndtime > StartTime_PDT) then Datediff(s,StartTime_PDT,autodata.ndtime)
			When (autodata.msttime >= StartTime_PDT and autodata.ndtime > EndTime_PDT and autodata.msttime < EndTime_PDT) then Datediff(s,autodata.msttime,EndTime_PDT)
			When (autodata.msttime < StartTime_PDT and autodata.ndtime > EndTime_PDT) then Datediff(s,StartTime_PDT,EndTime_PDT)
		End) as icd
		from #T_autodata autodata inner join
			(Select mc,sttime,ndtime,D.fromtime,D.totime from #T_autodata autodata inner join #DailyProductionFromAutodataT1 D on autodata.mc = D.machineinterface
			 where datatype = 1 and Datediff(s,sttime,ndtime) > Cycletime and
			 (autodata.msttime < D.fromtime and autodata.ndtime > D.totime)
			 ) as t1 on (autodata.sttime > t1.sttime and autodata.ndtime < t1.ndtime) and Autodata.mc=t1.mc
		inner join 	#PlannedDownTimes  on autodata.mc=#PlannedDownTimes.machineinterface And t1.FromTime=#PlannedDownTimes.StartTime_LogicalDay
		where (autodata.datatype=2) AND
		((autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) or
		(autodata.msttime < StartTime_PDT and autodata.ndtime <= EndTime_PDT and autodata.ndtime > StartTime_PDT) or
		(autodata.msttime >= StartTime_PDT and autodata.ndtime > EndTime_PDT and autodata.msttime < EndTime_PDT) or
		(autodata.msttime < StartTime_PDT and autodata.ndtime > EndTime_PDT))
		And (autodata.ndtime>t1.FromTime and Autodata.sttime < t1.totime)
		group by autodata.mc,StartTime_LogicalDay,EndTime_LogicalDay
	) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface And
	t2.StartTime_LogicalDay=#DailyProductionFromAutodataT1.FromTime And t2.EndTime_LogicalDay=#DailyProductionFromAutodataT1.ToTime
END




--ManagementLoss and Downtime Calculation Starts
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y')
BEGIN
		--Down Time
		--Type 1
		UPDATE #DailyProductionFromAutodataT1 SET downtime = isnull(downtime,0) + isNull(t2.down,0)
		from
		(select mc,
			sum(loadunload) down,D.Pdate as date1
		from #T_autodata autodata inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface
		where (autodata.msttime>=D.FromTime)
		and (autodata.ndtime<=D.ToTime)
		and (autodata.datatype=2)
		group by autodata.mc,D.Pdate
		) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface
		and t2.date1=#DailyProductionFromAutodataT1.Pdate

		-- Type 2
		UPDATE #DailyProductionFromAutodataT1 SET downtime = isnull(downtime,0) + isNull(t2.down,0)
		from
		(select mc,
			sum(DateDiff(second, D.FromTime, ndtime)) down,D.Pdate as date1
		from #T_autodata autodata inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface
		where (autodata.sttime<D.FromTime)
		and (autodata.ndtime>D.FromTime)
		and (autodata.ndtime<=D.ToTime)
		and (autodata.datatype=2)
		group by autodata.mc,D.Pdate
		) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface
		and t2.date1=#DailyProductionFromAutodataT1.Pdate

		-- Type 3
		UPDATE #DailyProductionFromAutodataT1 SET downtime = isnull(downtime,0) + isNull(t2.down,0)
		from
		(select mc,
			sum(DateDiff(second, stTime, D.ToTime)) down,D.Pdate as date1
		from #T_autodata autodata inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface
		where (autodata.msttime>=D.FromTime)
		and (autodata.sttime<D.ToTime)
		and (autodata.ndtime>D.ToTime)
		and (autodata.datatype=2)group by autodata.mc,D.Pdate
		) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface
		and t2.date1=#DailyProductionFromAutodataT1.Pdate

		-- Type 4
		UPDATE #DailyProductionFromAutodataT1 SET downtime = isnull(downtime,0) + isNull(t2.down,0)
		from
		(select mc,
			sum(DateDiff(second, D.FromTime, D.ToTime)) down,D.Pdate as date1
		from #T_autodata autodata inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface
		where autodata.msttime<D.FromTime
		and autodata.ndtime>D.ToTime
		and (autodata.datatype=2)
		group by autodata.mc,D.Pdate
		) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface
		and t2.date1=#DailyProductionFromAutodataT1.Pdate

		--ManagementLoss Type 1
		UPDATE #DailyProductionFromAutodataT1 SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
		from
		(select      mc,
			sum(case
		when isnull(loadunload,0)>isnull(downcodeinformation.threshold,0) AND isnull(downcodeinformation.threshold,0) > 0 THEN isnull(downcodeinformation.threshold,0)
		ELSE loadunload
		END) loss,D.Pdate as date1
		from #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface
		where (autodata.msttime>=D.FromTime)
		and (autodata.ndtime<=D.ToTime)
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1)
		group by autodata.mc,D.Pdate
		) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface
		and t2.date1=#DailyProductionFromAutodataT1.Pdate

		-- Type 2
		UPDATE #DailyProductionFromAutodataT1 SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
		from
		(select      mc,
			sum(CASE
		WHEN DateDiff(second, D.FromTime, ndtime) >isnull(downcodeinformation.threshold,0) AND isnull(downcodeinformation.threshold,0) > 0 THEN isnull(downcodeinformation.threshold,0)
		ELSE DateDiff(second, D.FromTime, ndtime)
		END) loss,D.Pdate as date1
		from #T_autodata  autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface
		where (autodata.sttime<D.FromTime)
		and (autodata.ndtime>D.FromTime)
		and (autodata.ndtime<=D.ToTime)
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1)
		group by autodata.mc,D.Pdate
		) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface
		and t2.date1=#DailyProductionFromAutodataT1.Pdate

		-- Type 3
		UPDATE #DailyProductionFromAutodataT1 SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
		from
		(select      mc,
			sum(CASE
		WHEN DateDiff(second, stTime, D.ToTime) >isnull(downcodeinformation.threshold,0) AND isnull(downcodeinformation.threshold,0) > 0 THEN isnull(downcodeinformation.threshold,0)
		ELSE DateDiff(second, stTime, D.ToTime)
		END) loss,D.Pdate as date1
		from #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface
		where (autodata.msttime>=D.FromTime)
		and (autodata.sttime<D.ToTime)
		and (autodata.ndtime>D.ToTime)
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1)
		group by autodata.mc,D.Pdate
		) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface
		and t2.date1=#DailyProductionFromAutodataT1.Pdate

		-- Type 4
		UPDATE #DailyProductionFromAutodataT1 SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
		from
		(select mc,
			sum(CASE
		WHEN DateDiff(second, D.FromTime, D.ToTime)>isnull(downcodeinformation.threshold,0) AND isnull(downcodeinformation.threshold,0) > 0 THEN isnull(downcodeinformation.threshold,0)
		ELSE DateDiff(second, D.FromTime, D.ToTime)
		END ) loss,D.Pdate as date1
		from #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface
		where autodata.msttime<D.FromTime
		and autodata.ndtime>D.ToTime
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1)
		group by autodata.mc,D.Pdate
		) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface
		and t2.date1=#DailyProductionFromAutodataT1.Pdate
End


---mod 4: Handling interaction between PDT and downtime . Also interaction between PDT and Management Loss
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN
	---step 1
	UPDATE #DailyProductionFromAutodataT1 SET downtime = isnull(downtime,0) + isNull(t2.down,0)	from (
		select mc,D.FromTime,D.ToTime,sum(
			CASE
				WHEN  autodata.msttime>=D.FromTime  and  autodata.ndtime<=D.ToTime  THEN  loadunload
				WHEN (autodata.sttime<D.FromTime and  autodata.ndtime>D.FromTime and autodata.ndtime<=D.ToTime)  THEN DateDiff(second, D.FromTime, ndtime)
				WHEN (autodata.msttime>=D.FromTime  and autodata.sttime<D.ToTime  and autodata.ndtime>D.ToTime)  THEN DateDiff(second, stTime, D.ToTime)
				WHEN autodata.msttime<D.FromTime and autodata.ndtime>D.ToTime   THEN DateDiff(second, D.FromTime, D.ToTime)
			END
			)AS down
		from #T_autodata autodata inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		inner join #DailyProductionFromAutodataT1 D on autodata.mc = D.MachineInterface
		where autodata.datatype=2 AND
		(
		(autodata.msttime>=D.FromTime  and  autodata.ndtime<=D.ToTime)
		OR (autodata.sttime<D.FromTime and  autodata.ndtime>D.FromTime and autodata.ndtime<=D.ToTime)
		OR (autodata.msttime>=D.FromTime  and autodata.sttime<D.ToTime  and autodata.ndtime>D.ToTime)
		OR (autodata.msttime<D.FromTime and autodata.ndtime>D.ToTime )
		) AND (downcodeinformation.availeffy = 0)
		group by autodata.mc,D.FromTime,D.ToTime
	) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface
	And t2.FromTime = #DailyProductionFromAutodataT1.FromTime
	And t2.ToTime = #DailyProductionFromAutodataT1.ToTime

	--step 2
	---mod 4 checking for (downcodeinformation.availeffy = 0) to get the overlapping PDT and Downs which is not ML
	UPDATE #DailyProductionFromAutodataT1 set DownTime =isnull(DownTime,0) - isNull(TT.PPDT ,0)
	FROM(
		SELECT autodata.MC,StartTime_LogicalDay,EndTime_LogicalDay,SUM
		   (CASE
			WHEN autodata.sttime >= T.StartTime_PDT  AND autodata.ndtime <=T.EndTime_PDT  THEN (autodata.loadunload)
			WHEN ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime <= T.EndTime_PDT  AND autodata.ndtime > T.StartTime_PDT ) THEN DateDiff(second,T.StartTime_PDT,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime_PDT   AND autodata.sttime <T.EndTime_PDT  AND autodata.ndtime > T.EndTime_PDT  ) THEN DateDiff(second,autodata.sttime,T.EndTime_PDT )
			WHEN ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime > T.EndTime_PDT ) THEN DateDiff(second,T.StartTime_PDT,T.EndTime_PDT )
			END ) as PPDT
		FROM #T_autodata AutoData CROSS jOIN #PlannedDownTimes T
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
			(
			(autodata.sttime >= T.StartTime_PDT  AND autodata.ndtime <=T.EndTime_PDT)
			OR ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime <= T.EndTime_PDT AND autodata.ndtime > T.StartTime_PDT )
			OR ( autodata.sttime >= T.StartTime_PDT   AND autodata.sttime <T.EndTime_PDT AND autodata.ndtime > T.EndTime_PDT )
			OR ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime > T.EndTime_PDT)
			)
			AND (downcodeinformation.availeffy = 0)
		group by autodata.MC,StartTime_LogicalDay,EndTime_LogicalDay
	) as TT INNER JOIN #DailyProductionFromAutodataT1 ON TT.mc = #DailyProductionFromAutodataT1.MachineInterface And
	TT.StartTime_LogicalDay = #DailyProductionFromAutodataT1.FromTime and TT.EndTime_LogicalDay = #DailyProductionFromAutodataT1.ToTime
	---step 3
	---Management loss calculation
	---IN T1 Select get all the downtimes which is of type management loss
	---IN T2  get the time to be deducted from the cycle if the cycle is overlapping with the PDT. And it should be ML record
	---In T3 Get the real management loss , and time to be considered as real down for each cycle(by comaring with the ML threshold)
	---In T4 consolidate everything at machine level and update the same to #CockpitData for ManagementLoss and MLDown
	UPDATE #DailyProductionFromAutodataT1 SET  ManagementLoss = isnull(ManagementLoss,0) + isNull(t4.Mloss,0),MLDown=isNull(MLDown,0)+isNull(t4.Dloss,0) from (
			select T3.mc,T3.FromTime,T3.ToTime,sum(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss from (
	
				select  t1.id,T1.mc,T1.Threshold,T1.FromTime,T1.Totime,
				case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0
				then DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)- isnull(T1.Threshold ,0)
				else 0 End  as Dloss,
				case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0
				then isnull(T1.Threshold,0)
				else (DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)) End  as Mloss
				 from
				(   select id,mc,comp,opn,opr,DC.threshold,D.FromTime,D.ToTime,
						case when autodata.sttime<D.FromTime then D.FromTime else sttime END as sttime,
						case when ndtime>D.ToTime then D.ToTime else ndtime END as ndtime
					from #T_autodata autodata inner join downcodeinformation DC on autodata.dcode=DC.interfaceid
					CROSS jOIN #DailyProductionFromAutodataT1 D
					where autodata.datatype=2 And D.MachineInterface=autodata.mc and
					(
					(autodata.sttime>=D.FromTime  and  autodata.ndtime<=D.ToTime)
					OR (autodata.sttime<D.FromTime and  autodata.ndtime>D.FromTime and autodata.ndtime<=D.ToTime)
					OR (autodata.sttime>=D.FromTime  and autodata.sttime<D.ToTime  and autodata.ndtime>D.ToTime)
					OR (autodata.sttime<D.FromTime and autodata.ndtime>D.ToTime )
					) AND (DC.availeffy = 1)) as T1 	
				left outer join
				(SELECT autodata.id,T.StartTime_LogicalDay,T.EndTime_LogicalDay,
						   sum(CASE
						WHEN autodata.sttime >= T.StartTime_PDT  AND autodata.ndtime <=T.EndTime_PDT  THEN (autodata.loadunload)
						WHEN ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime <= T.EndTime_PDT  AND autodata.ndtime > T.StartTime_PDT ) THEN DateDiff(second,T.StartTime_PDT,autodata.ndtime)
						WHEN ( autodata.sttime >= T.StartTime_PDT   AND autodata.sttime <T.EndTime_PDT  AND autodata.ndtime > T.EndTime_PDT  ) THEN DateDiff(second,autodata.sttime,T.EndTime_PDT )
						WHEN ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime > T.EndTime_PDT ) THEN DateDiff(second,T.StartTime_PDT,T.EndTime_PDT )
						END ) as PPDT
					FROM #T_autodata AutoData CROSS jOIN #PlannedDownTimes T
					inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
					WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
						((autodata.sttime >= T.StartTime_PDT  AND autodata.ndtime <=T.EndTime_PDT)
						OR ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime <= T.EndTime_PDT AND autodata.ndtime > T.StartTime_PDT )
						OR ( autodata.sttime >= T.StartTime_PDT   AND autodata.sttime <T.EndTime_PDT AND autodata.ndtime > T.EndTime_PDT )
						OR ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime > T.EndTime_PDT))
						AND (downcodeinformation.availeffy = 1) group  by autodata.id,T.starttime_LogicalDay,T.EndTime_LogicalDay
					) as T2 on T1.id=T2.id and T2.starttime_LogicalDay=T1.FromTime and T2.EndTime_LogicalDay=T1.ToTime
			) as T3  group by T3.mc,T3.FromTime,T3.ToTime
		) as t4 inner join #DailyProductionFromAutodataT1 on t4.mc = #DailyProductionFromAutodataT1.machineinterface And
		t4.FromTime = #DailyProductionFromAutodataT1.FromTime and  t4.ToTime = #DailyProductionFromAutodataT1.ToTime
	UPDATE #DailyProductionFromAutodataT1 SET downtime = isnull(downtime,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)
End



If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y' AND (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
Begin
	UPDATE #DailyProductionFromAutodataT1 set downtime =isnull(downtime,0) - isNull(t1.PPDT ,0)
	FROM(
		--Production PDT
		SELECT autodata.MC,T.StartTime_LogicalDay,T.EndTime_LogicalDay, SUM
		       (CASE
			WHEN autodata.sttime >= T.StartTime_PDT  AND autodata.ndtime <=T.EndTime_PDT  THEN (autodata.loadunload)
			WHEN ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime <= T.EndTime_PDT  AND autodata.ndtime > T.StartTime_PDT ) THEN DateDiff(second,T.StartTime_PDT,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime_PDT   AND autodata.sttime <T.EndTime_PDT  AND autodata.ndtime > T.EndTime_PDT  ) THEN DateDiff(second,autodata.sttime,T.EndTime_PDT )
			WHEN ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime > T.EndTime_PDT ) THEN DateDiff(second,T.StartTime_PDT,T.EndTime_PDT )
			END ) as PPDT
		FROM #T_autodata AutoData CROSS jOIN #PlannedDownTimes T
		Inner Join DownCodeInformation D ON AutoData.DCode = D.InterfaceID
		WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND D.DownID=(SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD') AND
			((autodata.sttime >= T.StartTime_PDT  AND autodata.ndtime <=T.EndTime_PDT)
			OR ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime <= T.EndTime_PDT AND autodata.ndtime > T.StartTime_PDT )
			OR ( autodata.sttime >= T.StartTime_PDT   AND autodata.sttime <T.EndTime_PDT AND autodata.ndtime > T.EndTime_PDT )
			OR ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime > T.EndTime_PDT))group by autodata.mc,T.StartTime_LogicalDay,T.EndTime_LogicalDay
	) as t1 INNER JOIN #DailyProductionFromAutodataT1 ON t1.mc = #DailyProductionFromAutodataT1.MachineInterface And
	t1.StartTime_LogicalDay = #DailyProductionFromAutodataT1.FromTime and t1.EndTime_LogicalDay = #DailyProductionFromAutodataT1.ToTime
	
End
--BEGIN: CN
--Type 1 and Type 2
UPDATE #DailyProductionFromAutodataT1 SET CN = isnull(CN,0) + isNull(t2.C1N1,0) from (
	select mc,--SUM(componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1)) C1N1
	SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))*autodata.partscount) C1N1,D.Pdate as date1
	FROM #T_autodata autodata INNER JOIN
	componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
	componentinformation ON autodata.comp = componentinformation.InterfaceID AND
	componentoperationpricing.componentid = componentinformation.componentid
	inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface
	---mod 1
	inner join machineinformation on machineinformation.interfaceid=autodata.mc and componentoperationpricing.machineid=machineinformation.machineid
	---mod 1
	where (autodata.ndtime>D.FromTime)and (autodata.ndtime<=D.ToTime)and (autodata.datatype=1) group by autodata.mc,D.Pdate
) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface
and t2.date1=#DailyProductionFromAutodataT1.Pdate

-- mod 4 Ignore count from CN calculation which is over lapping with PDT
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	UPDATE #DailyProductionFromAutodataT1 SET CN = isnull(CN,0) - isNull(t1.C1N1,0)
	From
	(
		select mc,T.StartTime_LogicalDay,T.EndTime_LogicalDay,
		SUM((O.cycletime * ISNULL(autodata.PartsCount,1))/ISNULL(O.SubOperations,1)) as C1N1
		From #T_autodata autodata 
		Inner join machineinformation M on M.interfaceid=autodata.mc
		Inner join componentinformation C ON autodata.Comp=C.interfaceid
		Inner join ComponentOperationPricing O ON autodata.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID
		Cross jOIN #PlannedDownTimes T
		WHERE autodata.DataType=1 AND T.MachineInterface=autodata.mc AND (autodata.ndtime > T.StartTime_PDT AND autodata.ndtime <=T.EndTime_PDT)
		Group by mc,T.StartTime_LogicalDay,T.EndTime_LogicalDay
	) as t1
	inner join #DailyProductionFromAutodataT1 on t1.mc = #DailyProductionFromAutodataT1.machineinterface And
	t1.StartTime_LogicalDay = #DailyProductionFromAutodataT1.FromTime and t1.EndTime_LogicalDay = #DailyProductionFromAutodataT1.ToTime
END
-- mod 4

Declare @Fromdate as datetime
Declare @ToDate as Datetime
Select @Fromdate = @Startdate
Select @Todate = @Enddate

Create table #day
(
  Fromtime datetime,
  Totime datetime
)

While @Fromdate <= @Todate
BEGIN
	Insert into #day(FromTime,ToTime)
	Select Distinct dbo.f_GetLogicalDay(@Fromdate,'start'),dbo.f_GetLogicalDay(@Fromdate,'End')
	SELECT @Fromdate=DATEADD(DAY,1,@Fromdate)
end
 
 
Insert into #MachineLevelDown(MachineInterface,MachineID,FromTime,ToTime,DownTime,DownID)
select D1.MachineInterface,D1.Machineid,D.FromTime,D.ToTime,sum
(
CASE
	WHEN  autodata.msttime>=D.FromTime  and  autodata.ndtime<=D.ToTime  THEN  autodata.loadunload
	WHEN (autodata.msttime<D.FromTime and  autodata.ndtime>D.FromTime and autodata.ndtime<=D.ToTime)  THEN DateDiff(second, D.FromTime, ndtime)
	WHEN (autodata.msttime>=D.FromTime  and autodata.msttime<D.ToTime  and autodata.ndtime>D.ToTime)  THEN DateDiff(second, mstTime, D.ToTime)
	WHEN autodata.msttime<D.FromTime and autodata.ndtime>D.ToTime   THEN DateDiff(second, D.FromTime, D.ToTime)
END
)AS down,downcodeinformation.DownID
from #T_autodata autodata inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
inner join #DailyProductionFromAutodataT1 D1 on autodata.mc = D1.MachineInterface 
Cross join #Day D
where autodata.datatype=2 AND D.FromTime=D1.FromTime and D.ToTime=D1.ToTime and
(
(autodata.msttime>=D.FromTime  and  autodata.ndtime<=D.ToTime)
OR (autodata.msttime<D.FromTime and  autodata.ndtime>D.FromTime and autodata.ndtime<=D.ToTime)
OR (autodata.msttime>=D.FromTime  and autodata.msttime<D.ToTime  and autodata.ndtime>D.ToTime)
OR (autodata.msttime<D.FromTime and autodata.ndtime>D.ToTime )
) 
group by D1.MachineInterface,D1.Machineid,D.FromTime,D.ToTime,downcodeinformation.DownID


If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN
	UPDATE #MachineLevelDown set DownTime =isnull(DownTime,0) - isNull(TT.PPDT ,0)
	FROM(
		SELECT autodata.MC,StartTime_LogicalDay,EndTime_LogicalDay,SUM
		   (CASE
			WHEN autodata.sttime >= T.StartTime_PDT  AND autodata.ndtime <=T.EndTime_PDT  THEN (autodata.loadunload)
			WHEN ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime <= T.EndTime_PDT  AND autodata.ndtime > T.StartTime_PDT ) THEN DateDiff(second,T.StartTime_PDT,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime_PDT   AND autodata.sttime <T.EndTime_PDT  AND autodata.ndtime > T.EndTime_PDT  ) THEN DateDiff(second,autodata.sttime,T.EndTime_PDT )
			WHEN ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime > T.EndTime_PDT ) THEN DateDiff(second,T.StartTime_PDT,T.EndTime_PDT )
			END ) as PPDT,downcodeinformation.downid as dcode
		FROM #T_autodata AutoData CROSS jOIN #PlannedDownTimes T
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
			(
			(autodata.sttime >= T.StartTime_PDT  AND autodata.ndtime <=T.EndTime_PDT)
			OR ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime <= T.EndTime_PDT AND autodata.ndtime > T.StartTime_PDT )
			OR ( autodata.sttime >= T.StartTime_PDT   AND autodata.sttime <T.EndTime_PDT AND autodata.ndtime > T.EndTime_PDT )
			OR ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime > T.EndTime_PDT)
			)
		group by autodata.MC,StartTime_LogicalDay,EndTime_LogicalDay,downcodeinformation.downid
	) as TT INNER JOIN #MachineLevelDown ON TT.mc = #MachineLevelDown.MachineInterface And TT.dcode = #MachineLevelDown.DownID And
	TT.StartTime_LogicalDay = #MachineLevelDown.FromTime and TT.EndTime_LogicalDay = #MachineLevelDown.ToTime
END


	declare @machine nvarchar(50)
	declare @Start datetime,@End datetime
	declare @GetDowntime cursor
	set @getdowntime = Cursor for
	select T.machineinterface,T.Fromtime,T.Totime from
	(select distinct machineinterface,Fromtime,Totime,machineid from #MachineLevelDown)T order by T.machineid
	open @getdowntime
	
	Fetch next from @getdowntime into @machine,@Start,@End

	While @@Fetch_status = 0
	Begin

			Update #DailyProductionFromAutodataT1 set Downreason1 = isnull(Downreason1,'') + isnull(TT.Dreason1,'') from 
			(
			--select top 1 Machineinterface as mc,fromtime,Totime,DownID + '-' + dbo.f_formattime(Downtime,'hh:mm') as Dreason1  from #MachineLevelDown --ER0401
			select top 1 Machineinterface as mc,fromtime,Totime,DownID + '-' + dbo.f_formattime(Downtime,'hh') as Dreason1  from #MachineLevelDown --ER0401
			where Downtime>0 and machineinterface=@machine and fromtime=@Start and Totime=@End and DownID Not Like 'Set%'  
			--Order by dbo.f_formattime(Downtime,'hh:mm') desc --ER0401
			Order by dbo.f_formattime(Downtime,'hh') desc --ER0401
			) as TT INNER JOIN #DailyProductionFromAutodataT1 ON TT.mc = #DailyProductionFromAutodataT1.MachineInterface And
			TT.fromtime = #DailyProductionFromAutodataT1.FromTime and TT.Totime = #DailyProductionFromAutodataT1.ToTime

			Update #DailyProductionFromAutodataT1 set Downreason2 = isnull(Downreason2,'') + isnull(TT.Dreason2,'') from 
			(
			--select top 1 M.Machineinterface as mc,M.fromtime,M.Totime,M.DownID + '-' + dbo.f_formattime(M.Downtime,'hh:mm') as Dreason2  from #MachineLevelDown M --ER0401
			select top 1 M.Machineinterface as mc,M.fromtime,M.Totime,M.DownID + '-' + dbo.f_formattime(M.Downtime,'hh') as Dreason2  from #MachineLevelDown M --ER0401
			INNER JOIN #DailyProductionFromAutodataT1 ON M.Machineinterface = #DailyProductionFromAutodataT1.MachineInterface And
			#DailyProductionFromAutodataT1.fromtime = M.FromTime and #DailyProductionFromAutodataT1.Totime = M.ToTime
			--where M.Downtime>0 and M.DownID + '-' + dbo.f_formattime(M.Downtime,'hh:mm')<>#DailyProductionFromAutodataT1.Downreason1 and M.machineinterface=@machine and M.fromtime=@Start and M.Totime=@End --ER0401
			where M.Downtime>0 and M.DownID + '-' + dbo.f_formattime(M.Downtime,'hh')<>#DailyProductionFromAutodataT1.Downreason1 and M.machineinterface=@machine and M.fromtime=@Start and M.Totime=@End --ER0401
			and M.DownID Not Like 'Set%' 
			--Order by dbo.f_formattime(M.Downtime,'hh:mm') desc --ER0401
			Order by dbo.f_formattime(M.Downtime,'hh') desc --ER0401
			) as TT INNER JOIN #DailyProductionFromAutodataT1 ON TT.mc = #DailyProductionFromAutodataT1.MachineInterface And
			TT.fromtime = #DailyProductionFromAutodataT1.FromTime and TT.Totime = #DailyProductionFromAutodataT1.ToTime

			Update #DailyProductionFromAutodataT1 set Downreason3 = isnull(Downreason3,'') + isnull(TT.Dreason3,'') from 
			--(Select Machineinterface as mc,fromtime,Totime,'[Setting Time]' + '-' + dbo.f_formattime(Sum(Cast(Downtime as float)),'hh:mm') as Dreason3  --ER0401
			 (Select Machineinterface as mc,fromtime,Totime,'[Setting Time]' + '-' + dbo.f_formattime(Sum(Cast(Downtime as float)),'hh') as Dreason3  --ER0401
			 from #MachineLevelDown where Downtime>0 and machineinterface=@machine and fromtime=@Start and Totime=@End and DownID Like 'Set%' 
			 Group by  Machineinterface,fromtime,Totime) as TT INNER JOIN #DailyProductionFromAutodataT1 ON TT.mc = #DailyProductionFromAutodataT1.MachineInterface And
			TT.fromtime = #DailyProductionFromAutodataT1.FromTime and TT.Totime = #DailyProductionFromAutodataT1.ToTime

		Fetch next from @getdowntime into @machine,@Start,@End 

	end

	CLOSE @getdowntime;
	DEALLOCATE @getdowntime;


-- Calculate efficiencies
UPDATE #DailyProductionFromAutodataT1
SET
	ProductionEfficiency = (CN/UtilisedTime) ,
	AvailabilityEfficiency = (UtilisedTime)/(UtilisedTime + DownTime - ManagementLoss)
WHERE UtilisedTime <> 0
UPDATE #DailyProductionFromAutodataT1
SET
	OverAllEfficiency = (ProductionEfficiency * AvailabilityEfficiency)*100,
	ProductionEfficiency = ProductionEfficiency * 100 ,
	AvailabilityEfficiency = AvailabilityEfficiency * 100


-- Geeta Added from here

Declare @StartTime1 as datetime
Declare @EndTime1 as datetime
select @StartTime1=@StartDate
select @EndTime1=@EndDate
DECLARE @CurStart1 datetime
DECLARE @CurEndTime1 datetime
while @StartTime1<=@EndTime1
BEGIN
	select @CurStart1=dbo.f_GetLogicalDay(@StartTime1,'start')
	select @CurEndTime1=dbo.f_GetLogicalDay(@StartTime1,'End')
	select @strsql = 'insert into #DailyProductionFromAutodataT3 (Cdate,MachineID,machineinterface,Component,Compinterface,Operation,Opninterface,'
	select @strsql = @strsql + 'FromTm,ToTm,runtime,Plantid,EmployeeName,Target)'
	select @strsql = @strsql + '( SELECT ''' +convert(nvarchar(20),@StartTime1)+ ''', machineinformation.machineid,machineinformation.interfaceid,componentinformation.componentid,componentinformation.interfaceid,  '
	select @strsql = @strsql + ' componentoperationpricing.operationno,componentoperationpricing.interfaceid,'
	select @strsql = @strsql + '''' +convert(nvarchar(20),@CurStart1)+ ''',''' +convert(nvarchar(20),@CurEndTime1)+ ''','
	select @strsql = @strsql + ' Sum
			(CASE
			WHEN msttime >= ''' +convert(nvarchar(20),@CurStart1)+ '''  AND ndtime <=''' +convert(nvarchar(20),@CurEndTime1)+ '''  THEN DateDiff(second,msttime,ndtime) --DR0325 added
			WHEN ( msttime <''' +convert(nvarchar(20),@CurStart1)+ '''  AND ndtime <= ''' +convert(nvarchar(20),@CurEndTime1)+ '''  AND ndtime > ''' +convert(nvarchar(20),@CurStart1)+ ''' ) THEN DateDiff(second,''' +convert(nvarchar(20),@CurStart1)+ ''',ndtime)
			WHEN ( msttime >=''' + convert(nvarchar(20),@CurStart1)+ '''   AND msttime <''' +convert(nvarchar(20),@CurEndTime1)+ '''  AND ndtime >''' + convert(nvarchar(20),@CurEndTime1)+ '''  ) THEN DateDiff(second,msttime,''' +convert(nvarchar(20),@CurEndTime1)+ ''')
			WHEN ( msttime < ''' +convert(nvarchar(20),@CurStart1)+ '''  AND ndtime > ''' +convert(nvarchar(20),@CurEndTime1)+ ''' ) THEN DateDiff(second,''' +convert(nvarchar(20),@CurStart1)+ ''',''' +convert(nvarchar(20),@CurEndTime1)+ ''' )
			END) as runtime
	,PlantMachine.Plantid,EI.Employeeid,isnull(componentoperationpricing.Targetpercent,100)'
	select @strsql = @strsql + ' FROM #T_autodataforDown autodata INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN  '
	select @strsql = @strsql + ' componentinformation ON autodata.comp = componentinformation.InterfaceID  INNER JOIN '
	select @strsql = @strsql + ' componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID)'
	select @strsql = @strsql + ' AND (componentinformation.componentid = componentoperationpricing.componentid) '
	---mod 1
	select @strsql = @strsql + ' and componentoperationpricing.machineid=machineinformation.machineid '
	---mod 1
	select @strsql = @strsql + ' Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid '
	select @strsql = @strsql + ' Left Outer Join Employeeinformation EI on EI.interfaceid=autodata.opr '
	select @strsql = @strsql + ' Left Outer Join downcodeinformation DI on DI.interfaceid=autodata.dcode '

	select @strsql = @strsql + ' WHERE	((autodata.msttime >= ''' + convert(nvarchar(20),@CurStart1) + '''  AND autodata.ndtime <= ''' + convert(nvarchar(20),@CurEndTime1) + ''')'
	select @strsql = @strsql + '	OR ( autodata.msttime < ''' + convert(nvarchar(20),@CurStart1) + '''  AND autodata.ndtime <= ''' + convert(nvarchar(20),@CurEndTime1) + ''' AND autodata.ndtime >''' + convert(nvarchar(20),@CurStart1) + ''' )'
	select @strsql = @strsql + '	OR ( autodata.msttime >= ''' + convert(nvarchar(20),@CurStart1) + '''   AND autodata.msttime <''' + convert(nvarchar(20),@CurEndTime1) + ''' AND autodata.ndtime > ''' + convert(nvarchar(20),@CurEndTime1) + ''' )'
	select @strsql = @strsql + '	OR ( autodata.msttime < ''' + convert(nvarchar(20),@CurStart1) + '''  AND autodata.ndtime > ''' + convert(nvarchar(20),@CurEndTime1) + ''') )'
	select @strsql = @strsql + @StrMPlantid + @strmachine + @strcomponentid + @stroperation
	select @strsql = @strsql +  '   group by machineinformation.machineid, machineinformation.interfaceid,componentinformation.componentid,componentinformation.interfaceid,
     componentoperationpricing.operationno,componentoperationpricing.interfaceid,PlantMachine.Plantid,componentoperationpricing.Targetpercent,EI.Employeeid )order by machineinformation.machineid'
	print @strsql
	exec(@strsql)
	SELECT @StartTime1=DATEADD(DAY,1,@StartTime1)
End



declare @CurMachineID as Nvarchar(50)
declare @CurOperatorID as Nvarchar(50)
declare @CurMachineID_prev as Nvarchar(50)
declare @CurOperatorID_prev as Nvarchar(50)
Declare @Cdate as datetime
Declare @Cdate_prev as datetime
DECLARE @AllOprAtMachineLevel AS NVARCHAR(1000)
Declare TmpCursorsec Cursor For SELECT Cdate,Machineid,Employeename from #DailyProductionFromAutodataT3 order by Machineid--where SSession=@@SPID  order by MShiftStart
OPEN  TmpCursorsec
FETCH NEXT FROM TmpCursorsec INTO @Cdate,@CurMachineID,@CurOperatorID
set @CurMachineID_prev=@CurMachineID
set @CurOperatorID_prev=@CurOperatorID
set @Cdate_prev=@Cdate
set @AllOprAtMachineLevel=''

WHILE @@FETCH_STATUS=0
BEGIN

if @CurMachineID_prev=@CurMachineID and @Cdate_prev=@Cdate and @CurOperatorID_prev<>@CurOperatorID
begin
SELECT @AllOprAtMachineLevel=@CurOperatorID_prev + ' ; ' + @CurOperatorID

update #DailyProductionFromAutodataT3 set Employeename=@AllOprAtMachineLevel where Machineid=@CurMachineID and cdate =@Cdate
print (@AllOprAtMachineLevel)
End
set @AllOprAtMachineLevel=''

set @CurMachineID_prev=@CurMachineID	
set @CurOperatorID_prev=@CurOperatorID
set @Cdate_prev=@Cdate
FETCH NEXT FROM TmpCursorsec INTO @Cdate,@CurMachineID,@CurOperatorID

END
close TmpCursorsec
deallocate TmpCursorsec


Insert into #DailyProductionFromAutodataT4(Cdate,MachineID,machineinterface,Component,Compinterface,Operation,Opninterface,FromTm,ToTm,runtime,Plantid,EmployeeName,Target)
select Cdate,MachineID,machineinterface,Component,Compinterface,Operation,Opninterface,FromTm,ToTm,Sum(runtime),Plantid,EmployeeName,Target from #DailyProductionFromAutodataT3
group by Cdate,MachineID,machineinterface,Component,Compinterface,Operation,Opninterface,FromTm,ToTm,Plantid,EmployeeName,Target


If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y' --ER0363 Added
BEGIN
		UPDATE #DailyProductionFromAutodataT4 set Runtime =isnull(Runtime,0) - isNull(TT.PPDT ,0)
		FROM(
			Select A.mc,A.comp,A.Opn,A.MachineID,A.component,A.operation,A.FromTm,A.ToTm,Sum
			(CASE
			WHEN A.msttime >= T.StartTime  AND A.ndtime <=T.EndTime  THEN DateDiff(second,A.msttime,A.ndtime) --DR0325 added
			WHEN ( A.msttime < T.StartTime  AND A.ndtime <= T.EndTime  AND A.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,A.ndtime)
			WHEN ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime  AND A.ndtime > T.EndTime  ) THEN DateDiff(second,A.msttime,T.EndTime )
			WHEN ( A.msttime < T.StartTime  AND A.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END)  as PPDT
			From 			
			(
			SELECT M.MachineID,M.component,M.operation,M.FromTm,M.ToTm,
			autodata.MC,autodata.comp,autodata.Opn,
			cASE WHEN autodata.ndtime>M.ToTm then M.ToTm else autodata.ndtime end as ndtime ,
			Case when autodata.msttime<M.FromTm then M.FromTm else autodata.msttime end as msttime
			FROM #T_autodataforDown AutoData inner join (Select distinct MachineID,component,operation,FromTm,ToTm,
			machineinterface,CompInterface,OpnInterface from #DailyProductionFromAutodataT4) M on
			AutoData.mc=M.machineinterface and AutoData.comp=M.CompInterface and AutoData.opn=M.OpnInterface
			where ((autodata.ndtime >M.FromTm  AND autodata.ndtime <=M.ToTm) OR (autodata.msttime>=M.FromTm and autodata.msttime<M.ToTm and autodata.ndtime>M.ToTm) OR
			(autodata.msttime<M.FromTm and autodata.ndtime >M.ToTm))
			)A			
			CROSS jOIN PlannedDownTimes T 
			WHERE T.Machine=A.MachineID AND 
			((A.msttime >= T.StartTime  AND A.ndtime <=T.EndTime)
			OR ( A.msttime < T.StartTime  AND A.ndtime <= T.EndTime AND A.ndtime > T.StartTime )
			OR ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime AND A.ndtime > T.EndTime )
			OR ( A.msttime < T.StartTime  AND A.ndtime > T.EndTime) ) 
		
         group by A.mc,A.comp,A.Opn,A.MachineID,A.component,A.operation,A.FromTm,A.ToTm
	)
	as TT INNER JOIN #DailyProductionFromAutodataT4 ON TT.MachineID = #DailyProductionFromAutodataT4.MachineID
		and TT.component = #DailyProductionFromAutodataT4.component
		and TT.operation = #DailyProductionFromAutodataT4.operation 
		and TT.FromTm=#DailyProductionFromAutodataT4.FromTm and TT.ToTm= #DailyProductionFromAutodataT4.ToTm
END
--geeta Added till here



select @StartTime=@StartDate
select @EndTime=@EndDate
DECLARE @CurStart datetime
DECLARE @CurEndTime datetime
while @StartTime<=@EndTime
BEGIN
	select @CurStart=dbo.f_GetLogicalDay(@StartTime,'start')
	select @CurEndTime=dbo.f_GetLogicalDay(@StartTime,'End')
	select @strsql = 'insert into #DailyProductionFromAutodataT2 (Cdate,MachineID,Component,Operation,machineinterface,compinterface,opninterface,CycleTime,LoadUnload,AvgLoadUnload,AvgCycleTime,'
	select @strsql = @strsql + 'CountShift1,CountShift2,CountShift3,FromTm,ToTm)'
	select @strsql = @strsql + '( SELECT ''' +convert(nvarchar(20),@StartTime)+ ''', machineinformation.machineid, componentinformation.componentid, '
	select @strsql = @strsql + ' componentoperationpricing.operationno,machineinformation.interfaceid,componentinformation.interfaceid,componentoperationpricing.interfaceid, '
	select @strsql = @strsql + ' componentoperationpricing.machiningtime, '
	select @strsql = @strsql + ' (componentoperationpricing.cycletime - componentoperationpricing.machiningtime),0, '
	--select @strsql = @strsql + ' AVG(autodata.loadunload/autodata.partscount) * ISNULL(ComponentOperationPricing.SubOperations,1), ' ::DR0016
	--mod 5
	--select @strsql = @strsql + ' AVG(autodata.cycletime/autodata.partscount) * ISNULL(ComponentOperationPricing.SubOperations,1) ,'
	  select @strsql = @strsql + ' sum(isnull(autodata.cycletime,0)) ,'
	--mod 5
	select @strsql = @strsql + ' 0,0,0,''' +convert(nvarchar(20),@CurStart)+ ''',''' +convert(nvarchar(20),@CurEndTime)+ ''' '
	select @strsql = @strsql + ' FROM #T_autodata autodata INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN  '
	select @strsql = @strsql + ' componentinformation ON autodata.comp = componentinformation.InterfaceID  INNER JOIN '
	select @strsql = @strsql + ' componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID)'
	select @strsql = @strsql + ' AND (componentinformation.componentid = componentoperationpricing.componentid) '
	---mod 1
	select @strsql = @strsql + ' and componentoperationpricing.machineid=machineinformation.machineid '
	---mod 1
	select @strsql = @strsql + ' Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid'
	select @strsql = @strsql + ' WHERE (autodata.ndtime > ''' + convert(nvarchar(20),@CurStart) + ''')'
	select @strsql = @strsql + ' AND (autodata.ndtime <= ''' + convert(nvarchar(20),@CurEndTime) + ''')'
	select @strsql = @strsql + @StrMPlantid + @strmachine + @strcomponentid + @stroperation
	select @strsql = @strsql + ' AND (autodata.datatype = 1)'
	--mod 3
	select @strsql = @strsql + ' AND (autodata.partscount > 0 ) '
	--mod 3
	select @strsql = @strsql + ' GROUP BY machineinformation.machineid,componentinformation.componentid, componentoperationpricing.operationno,machineinformation.interfaceid,componentinformation.interfaceid,componentoperationpricing.interfaceid, '
	select @strsql = @strsql + ' componentoperationpricing.cycletime, componentoperationpricing.machiningtime ,ComponentOperationPricing.SubOperations)'
	print @strsql
	exec(@strsql)


	--********************* SSK:25/07/07 : DR0016  Starts Here
	select @strsql =''
	select @strsql = 'UPDATE #DailyProductionFromAutodataT2 SET AvgLoadUnload=ISNULL(T2.AvgLoadUnload,0)'
	select @strsql = @strsql + ' FROM('
	select @strsql = @strsql + ' SELECT ''' +convert(nvarchar(20),@StartTime)+ ''' AS Cdate, machineinformation.machineid AS Machineid, componentinformation.componentid AS Component, '
	select @strsql = @strsql + ' componentoperationpricing.operationno AS operation , '
--	select @strsql = @strsql + ' AVG(autodata.loadunload/autodata.partscount) * ISNULL(ComponentOperationPricing.SubOperations,1) AS AvgLoadUnload ' --DR0325 commented
	select @strsql = @strsql + ' SUM(autodata.loadunload) AS AvgLoadUnload ' --DR0325 Added
	select @strsql = @strsql + ' FROM #T_autodata autodata INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN  '
	select @strsql = @strsql + ' componentinformation ON autodata.comp = componentinformation.InterfaceID  INNER JOIN '
	select @strsql = @strsql + ' componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID)'
	select @strsql = @strsql + ' AND (componentinformation.componentid = componentoperationpricing.componentid) '
	---mod 1
	select @strsql = @strsql + ' and componentoperationpricing.machineid=machineinformation.machineid '
	---mod 1
	select @strsql = @strsql + ' Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid'
	select @strsql = @strsql + ' WHERE (autodata.ndtime > ''' + convert(nvarchar(20),@CurStart) + ''')'
	select @strsql = @strsql + ' AND (autodata.ndtime <= ''' + convert(nvarchar(20),@CurEndTime) + ''')'
	select @strsql = @strsql + @StrMPlantid + @strmachine + @strcomponentid + @stroperation
	select @strsql = @strsql + ' AND autodata.datatype = 1 AND autodata.loadunload>=(SELECT TOP 1 ISNULL(ValueInInt,0) From ShopDefaults Where Parameter=''MinLUForLR'')'
	--mod 3
	select @strsql = @strsql + ' AND (autodata.partscount > 0 )'
	--mod 3
	select @strsql = @strsql + ' GROUP BY machineinformation.machineid,componentinformation.componentid, componentoperationpricing.operationno,ComponentOperationPricing.SubOperations '
	select @strsql = @strsql + ' )AS T2 INNER JOIN #DailyProductionFromAutodataT2 ON T2.Cdate=#DailyProductionFromAutodataT2.Cdate AND T2.Machineid=#DailyProductionFromAutodataT2.Machineid
	AND T2.Component=#DailyProductionFromAutodataT2.Component AND T2.operation=#DailyProductionFromAutodataT2.operation'
	exec(@strsql)
	--********************* SSK:25/07/07 : DR0016  Ends Here


	--BEGIN: Update shift1, shift2, shift3 counts
	INSERT #DailyProductionFromAutodataT0(DDate,Shift, ShiftStart, ShiftEnd)
	EXEC s_GetShiftTime @StartTime
	
	SELECT @StartTime=DATEADD(DAY,1,@StartTime)
END



declare @Dateval datetime
declare @shiftstart datetime
declare @shiftend  datetime
declare @shiftid  nvarchar(20)
declare @shiftname  nvarchar(20)
declare @shiftnamevalue  nvarchar(20)
declare @recordcount smallint
declare @lastdate datetime
--Initialize values
select @shiftstart = @starttime
select @shiftend = @endtime
select @shiftid = 'CountShift'
select @shiftname = 'NameShift'
select @shiftnamevalue = 'Shift 1'
select @recordcount = 0
select @lastdate=@StartDate
Declare RptDailyCursor CURSOR FOR 	
		SELECT 	#DailyProductionFromAutodataT0.DDate,
				#DailyProductionFromAutodataT0.Shift,
				#DailyProductionFromAutodataT0.ShiftStart,
				#DailyProductionFromAutodataT0.ShiftEnd
		from 	#DailyProductionFromAutodataT0	order by Ddate,shift
OPEN RptDailyCursor
FETCH NEXT FROM RptDailyCursor INTO @Dateval,@shiftnamevalue, @shiftstart, @shiftend
while (@@fetch_status = 0)
Begin
	if @Dateval=dateadd(day,1,@lastdate)
	BEGIN
	      SELECT @lastdate=@Dateval
	      SELECT @recordcount=0
	END
	select @recordcount = @recordcount + 1
	select @shiftid = 'CountShift' + cast(@recordcount as nvarchar(1))
	select @shiftname = 'NameShift' + cast(@recordcount as nvarchar(1))
	--Mod 4(1)
		Delete #PlannedDownTimes
		Insert into #PlannedDownTimes
		Select machineinformation.MachineID,machineinformation.InterfaceID,@shiftstart,@shiftend,
		Case When StartTime<@shiftstart Then @shiftstart Else StartTime End as StartTime, 	
		Case When EndTime > @shiftend Then @shiftend Else EndTime End as EndTime,
		0,0,0,0,PlannedDownTimes.DownReason
		 from PlannedDownTimes	inner join machineinformation on PlannedDownTimes.machine=machineinformation.machineid
		 Where PlannedDownTimes.PDTstatus =1 And (
		(StartTime >= @shiftstart and EndTime <= @shiftend) OR
		(StartTime < @shiftstart and EndTime <= @shiftend and EndTime > @shiftstart) OR
		(StartTime >= @shiftstart and EndTime > @shiftend and StartTime < @shiftend) OR
		(StartTime < @shiftstart and EndTime > @shiftend))
		And machineinformation.MachineID in (select distinct MachineID from #DailyProductionFromAutodataT1)
	--Mod 4(1)
	select @strsql = ''
	select @strsql = 'UPDATE #DailyProductionFromAutodataT2 SET ' + @shiftid + '= isNull(t5.OperationCount,0), '
	select @strsql = @strsql + @shiftname + ' = ''' + @shiftNamevalue + ''''
	select @strsql = @strsql + ' from ( SELECT machineinformation.machineid, componentinformation.componentid, '
	select @strsql = @strsql + ' componentoperationpricing.operationno, '
	select @strsql = @strsql + ' CEILING(CAST(Sum(autodata.partscount)AS Float)/ISNULL(ComponentOperationPricing.SubOperations,1)) AS operationcount,D.Cdate as date1'		
	select @strsql = @strsql + ' FROM #T_autodata autodata INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN  '
	select @strsql = @strsql + ' componentinformation ON autodata.comp = componentinformation.InterfaceID  INNER JOIN '
	select @strsql = @strsql + ' componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID'
	select @strsql = @strsql + ' AND componentinformation.componentid = componentoperationpricing.componentid) '
	---mod 1
	select @strsql = @strsql + ' and componentoperationpricing.machineid=machineinformation.machineid '
	---mod 1
	select @strsql = @strsql + ' inner join #DailyProductionFromAutodataT2 D on Machineinformation.machineid=D.machineid
	AND componentinformation.componentid=D.Component AND componentoperationpricing.operationno=D.Operation '
	select @strsql = @strsql + ' Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid'
	select @strsql = @strsql + ' WHERE (autodata.ndtime > ''' + convert(nvarchar(20),@ShiftStart) + ''')'
	select @strsql = @strsql + ' AND (autodata.ndtime <= ''' + convert(nvarchar(20),@ShiftEnd) + ''') and D.Cdate=''' + convert(nvarchar(20),@Dateval) + ''' '
	select @strsql = @strsql + @StrMPlantid + @strmachine + @strcomponentid + @stroperation
	select @strsql = @strsql + ' AND (autodata.datatype = 1)'
	select @strsql = @strsql + ' GROUP BY machineinformation.machineid,componentinformation.componentid, componentoperationpricing.operationno,ComponentOperationPricing.SubOperations,D.Cdate ) '
	select @strsql = @strsql + ' as t5 inner join #DailyProductionFromAutodataT2 on (t5.machineid = #DailyProductionFromAutodataT2.machineid '
	select @strsql = @strsql + 'and t5.componentid = #DailyProductionFromAutodataT2.component '
	select @strsql = @strsql + 'and t5.operationno = #DailyProductionFromAutodataT2.operation and t5.date1=#DailyProductionFromAutodataT2.Cdate)'
	exec(@strsql)
	--Mod 4(1) Apply PDT
	If (select valueintext from cockpitdefaults where parameter='Ignore_Count_4m_Pld')='Y'
	Begin
		 Select @Strsql = 'Update #DailyProductionFromAutodataT2 Set '+ @Shiftid+'=(Isnull('+ @ShiftId +',0)-Isnull(T2.Count,0))'
	     Select @Strsql =@Strsql + ' from (Select machineinformation.machineid,Ceiling(cast(Sum(autodata.partscount) as float)/Isnull(Componentoperationpricing.Suboperations,1)) as Count,'
	     Select @Strsql =@Strsql + ' ComponentInformation.Componentid,Componentoperationpricing.operationno,D.Cdate as date1 from #T_autodata autodata
			     inner Join #PlannedDownTimes T  on T.machineinterface = autodata.mc
			     inner join machineinformation on machineinformation.interfaceid=autodata.mc
			     inner join ComponentInformation on ComponentInformation.Interfaceid=autodata.Comp
			     inner join Componentoperationpricing on Componentoperationpricing.Interfaceid=autodata.opn and Componentoperationpricing.componentid=ComponentInformation.componentid and Componentoperationpricing.machineID = machineinformation.MachineID
				 inner join #DailyProductionFromAutodataT2 D on Machineinformation.machineid=D.machineid AND componentinformation.componentid=D.Component AND componentoperationpricing.operationno=D.Operation
				 Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid --DR0296
			     Where autodata.datatype=1 and (autodata.ndtime> T.StartTime_PDT and autodata.ndtime <= T.EndTime_PDT) '
	     Select @Strsql = @Strsql + ' and (autodata.ndtime > ''' +Convert(nvarchar(20),@ShiftStart) + ''' and autodata.ndtime <= ''' + Convert(Nvarchar(20),@ShiftEnd) + ''') and D.Cdate=''' + convert(nvarchar(20),@Dateval) + ''''
	     select @strsql = @strsql + @StrMPlantid + @strmachine + @strcomponentid + @stroperation
	     Select @Strsql = @Strsql + ' Group by machineinformation.machineid,ComponentInformation.componentid,Componentoperationpricing.operationno,
			     Componentoperationpricing.Suboperations,D.Cdate) as T2 inner join #DailyProductionFromAutodataT2 on (T2.machineid = #DailyProductionFromAutodataT2.machineid
			     and T2.Componentid= #DailyProductionFromAutodataT2.Component and T2.operationno=#DailyProductionFromAutodataT2.operation and t2.date1 = #DailyProductionFromAutodataT2.cdate)' 		      	
	    --print @strsql
	    Exec(@strsql)
	End


	FETCH NEXT FROM RptDailyCursor INTO @Dateval,@shiftnamevalue, @shiftstart, @shiftend
End	


CLOSE RptDailyCursor
DEALLOCATE RptDailyCursor


--If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y' --ER0363 Commented
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_AvgCycletime_4m_PLD')='Y' --ER0363 Added
BEGIN


			------------------------------------------DR0325 added From Here-------------------------------------------
		UPDATE #DailyProductionFromAutodataT2 set AvgCycleTime =isnull(AvgCycleTime,0) - isNull(TT.PPDT ,0)
		,AvgLoadUnload = isnull(AvgLoadUnload,0) - isnull(LD,0)
		FROM(
		--Production Time in PDT
			Select A.mc,A.comp,A.Opn,A.MachineID,A.component,A.operation,A.FromTm,A.ToTm,Sum
			(CASE
--			WHEN A.sttime >= T.StartTime  AND A.ndtime <=T.EndTime  THEN (A.cycletime) --DR0325 Commented
			WHEN A.sttime >= T.StartTime  AND A.ndtime <=T.EndTime  THEN DateDiff(second,A.sttime,A.ndtime) --DR0325 added
			WHEN ( A.sttime < T.StartTime  AND A.ndtime <= T.EndTime  AND A.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,A.ndtime)
			WHEN ( A.sttime >= T.StartTime   AND A.sttime <T.EndTime  AND A.ndtime > T.EndTime  ) THEN DateDiff(second,A.sttime,T.EndTime )
			WHEN ( A.sttime < T.StartTime  AND A.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END)  as PPDT,
			sum(case
			WHEN A.msttime >= T.StartTime  AND A.sttime <=T.EndTime  THEN DateDiff(second,A.msttime,A.sttime)
			WHEN ( A.msttime < T.StartTime  AND A.sttime <= T.EndTime  AND A.sttime > T.StartTime ) THEN DateDiff(second,T.StartTime,A.sttime)
			WHEN ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime  AND A.sttime > T.EndTime  ) THEN DateDiff(second,A.msttime,T.EndTime )
			WHEN ( A.msttime < T.StartTime  AND A.sttime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END)  as LD
			From 
			
			(
--			SELECT M.MachineID,M.component,M.operation,M.FromTm,M.ToTm,
--			autodata.MC,autodata.comp,autodata.Opn,autodata.sttime,autodata.ndtime
--			,autodata.Cycletime,autodata.msttime--,M.ShftStrt,M.ShftND
--			FROM AutoData inner join Machineinformation on Machineinformation.interfaceid=Autodata.mc
--			inner join componentinformation on componentinformation.interfaceid=autodata.comp
--			inner join componentoperationpricing
--			ON (autodata.opn = componentoperationpricing.InterfaceID)
--			AND componentinformation.componentid = componentoperationpricing.componentid
--			and componentoperationpricing.machineid=machineinformation.machineid  
--			inner join (Select distinct MachineID,component,operation,FromTm,ToTm from #DailyProductionFromAutodataT2) M on M.Machineid=machineinformation.machineid 
--			and M.component=componentoperationpricing.componentid and M.operation=componentoperationpricing.Operationno
--			where autodata.DataType=1 And autodata.ndtime >M.FromTm  AND autodata.ndtime <=M.ToTm
			SELECT M.MachineID,M.component,M.operation,M.FromTm,M.ToTm,
			autodata.MC,autodata.comp,autodata.Opn,autodata.sttime,autodata.ndtime
			,autodata.Cycletime,autodata.msttime
			FROM #T_autodata AutoData inner join (Select distinct MachineID,component,operation,FromTm,ToTm,
			machineinterface,CompInterface,OpnInterface from #DailyProductionFromAutodataT2) M on
			AutoData.mc=M.machineinterface and AutoData.comp=M.CompInterface and AutoData.opn=M.OpnInterface
			where autodata.DataType=1 And autodata.ndtime >M.FromTm  AND autodata.ndtime <=M.ToTm
			)A
			CROSS jOIN PlannedDownTimes T 
			WHERE T.Machine=A.MachineID AND 
			((A.msttime >= T.StartTime  AND A.ndtime <=T.EndTime)
			OR ( A.msttime < T.StartTime  AND A.ndtime <= T.EndTime AND A.ndtime > T.StartTime )
			OR ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime AND A.ndtime > T.EndTime )
			OR ( A.msttime < T.StartTime  AND A.ndtime > T.EndTime) ) 
		group by A.mc,A.comp,A.Opn,A.MachineID,A.component,A.operation,A.FromTm,A.ToTm
	)
	as TT INNER JOIN #DailyProductionFromAutodataT2 ON TT.MachineID = #DailyProductionFromAutodataT2.MachineID
		and TT.component = #DailyProductionFromAutodataT2.component
			and TT.operation = #DailyProductionFromAutodataT2.operation and TT.FromTm=#DailyProductionFromAutodataT2.FromTm 
					and TT.ToTm= #DailyProductionFromAutodataT2.ToTm


	--Handle intearction between ICD and PDT for type 1 production record for the selected time period.
	UPDATE  #DailyProductionFromAutodataT2 set AvgCycleTime =isnull(AvgCycleTime,0) + isNull(T2.IPDT ,0) 	FROM	(
		Select T1.MachineID,T1.component,T1.operation,AutoData.mc,autodata.comp,autodata.Opn,T1.FromTm,T1.ToTm,
		SUM(
		CASE 	
			When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
			When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
			When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
			when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		From #T_autodata AutoData INNER Join
			(
--					Select M.MachineID,M.component,M.operation,mc,Sttime,NdTime,M.FromTm,M.ToTm From AutoData
--					inner join Machineinformation on Machineinformation.interfaceid=Autodata.mc
--					inner join componentinformation on componentinformation.interfaceid=autodata.comp
--					inner join componentoperationpricing
--					ON (autodata.opn = componentoperationpricing.InterfaceID)
--					AND componentinformation.componentid = componentoperationpricing.componentid
--					and componentoperationpricing.machineid=machineinformation.machineid  
--					inner join (Select distinct MachineID,component,operation,FromTm,ToTm from #DailyProductionFromAutodataT2) M on M.Machineid=machineinformation.machineid 
--					and M.component=componentoperationpricing.componentid and M.operation=componentoperationpricing.Operationno
--					Where DataType=1 And DateDiff(Second,sttime,ndtime)>AutoData.CycleTime And
--					(ndtime > M.FromTm) AND (ndtime <= M.ToTm)
					Select M.MachineID,M.component,M.operation,mc,Sttime,NdTime,M.FromTm,M.ToTm From #T_autodata AutoData
					inner join (Select distinct MachineID,component,operation,FromTm,ToTm,
					machineinterface,CompInterface,OpnInterface from #DailyProductionFromAutodataT2) M on
					AutoData.mc=M.machineinterface and AutoData.comp=M.CompInterface and AutoData.opn=M.OpnInterface
					Where DataType=1 And DateDiff(Second,sttime,ndtime)>AutoData.CycleTime And
				   (ndtime > M.FromTm) AND (ndtime <= M.ToTm)
		  ) as T1
		ON AutoData.mc=T1.mc 
		CROSS jOIN PlannedDownTimes T 
		Where AutoData.DataType=2 And 
		T.Machine=T1.MachineID 
		And (( autodata.Sttime > T1.Sttime )
		And ( autodata.ndtime <  T1.ndtime )
		)
		AND
		((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
		or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
		or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
		or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) ) 
		GROUP BY T1.MachineID,T1.component,T1.operation,AUTODATA.mc,autodata.comp,autodata.Opn,T1.FromTm,T1.ToTm
	)AS T2  INNER JOIN #DailyProductionFromAutodataT2 ON T2.MachineID = #DailyProductionFromAutodataT2.MachineID
				and T2.component = #DailyProductionFromAutodataT2.component
			and T2.operation = #DailyProductionFromAutodataT2.operation and T2.FromTm=#DailyProductionFromAutodataT2.FromTm 
				and T2.ToTm= #DailyProductionFromAutodataT2.ToTm
      ---------------------------------DR0325 Added Till Here---------------------------------------------
End


update #DailyProductionFromAutodataT2 set AvgCycleTime=AvgCycleTime/ case
	when isnull(#DailyProductionFromAutodataT2.CountShift1,0)
	+isnull(#DailyProductionFromAutodataT2.CountShift2,0)
	+isnull(#DailyProductionFromAutodataT2.CountShift3,0)>0 then isnull(#DailyProductionFromAutodataT2.CountShift1,0)
	+isnull(#DailyProductionFromAutodataT2.CountShift2,0)
	+isnull(#DailyProductionFromAutodataT2.CountShift3,0)
	else 1 end ,
	--DR0325 Added From Here
	Avgloadunload=Avgloadunload/ case
	when isnull(#DailyProductionFromAutodataT2.CountShift1,0)
	+isnull(#DailyProductionFromAutodataT2.CountShift2,0)
	+isnull(#DailyProductionFromAutodataT2.CountShift3,0)>0 then isnull(#DailyProductionFromAutodataT2.CountShift1,0)
	+isnull(#DailyProductionFromAutodataT2.CountShift2,0)
	+isnull(#DailyProductionFromAutodataT2.CountShift3,0)else 1 end
	--DR0325 Added Till Here

--mod 5
------------------------------------------------------
--Get preferred time format
select @timeformat ='ss'
select @timeformat = isnull((select valueintext from cockpitdefaults where parameter='timeformat'),'ss')
if (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')
begin
select @timeformat = 'ss'
end
--Output
declare @shiftname1 nvarchar(20)
declare @shiftname2 nvarchar(20)
declare @shiftname3 nvarchar(20)
select @shiftname1 = (select top 1 NameShift1 from #DailyProductionFromAutodataT2 where Nameshift1 > '')
select @shiftname2 = (select top 1 NameShift2 from #DailyProductionFromAutodataT2 where Nameshift2 > '')
select @shiftname3 = (select top 1 NameShift3 from #DailyProductionFromAutodataT2 where Nameshift3 > '')


select  #DailyProductionFromAutodataT4.Cdate as [Day],#DailyProductionFromAutodataT4.PlantID as Cell,
#DailyProductionFromAutodataT4.MachineID as Machine,
isnull(#DailyProductionFromAutodataT4.Component,'') as Component,
isnull(#DailyProductionFromAutodataT4.operation,'') as operation,
--dbo.f_formattime(#DailyProductionFromAutodataT4.Runtime, 'hh:mm:ss') as Runtime    --ER0401 
dbo.f_formattime(#DailyProductionFromAutodataT4.Runtime, 'hh') as Runtime  --ER0401     
,case when Cast(isnull(#DailyProductionFromAutodataT2.CycleTime,0) as float) + Cast(isnull(#DailyProductionFromAutodataT2.LoadUnload,0) as Float) > 0 then round((#DailyProductionFromAutodataT4.Runtime/(Cast(isnull(#DailyProductionFromAutodataT2.CycleTime,0) as float)+ Cast(isnull(#DailyProductionFromAutodataT2.LoadUnload,0)as float)))*#DailyProductionFromAutodataT4.Target/100,0)
else 0 end as Target,     
isnull(isnull(#DailyProductionFromAutodataT2.NameShift1,@shiftname1),'') as NameShift1,
isnull(#DailyProductionFromAutodataT2.CountShift1,0)as CountShift1,
isnull(isnull(#DailyProductionFromAutodataT2.NameShift2,@shiftname2),'') as NameShift2,
isnull(#DailyProductionFromAutodataT2.CountShift2,0)as CountShift2,
isnull(isnull(#DailyProductionFromAutodataT2.NameShift3,@shiftname3),'') as NameShift3, --g:
isnull(#DailyProductionFromAutodataT2.CountShift3,0)as CountShift3, -- g:
--dbo.f_formattime((Cast(isnull(#DailyProductionFromAutodataT2.CycleTime,0)as float)+ Cast(isnull(#DailyProductionFromAutodataT2.LoadUnload,0)as float)),'hh:mm:ss') as frmtStdCycletime, --ER0401
dbo.f_formattime((Cast(isnull(#DailyProductionFromAutodataT2.CycleTime,0)as float)+ Cast(isnull(#DailyProductionFromAutodataT2.LoadUnload,0)as float)),'hh') as frmtStdCycletime, --ER0401
--dbo.f_formattime((Cast(isnull(#DailyProductionFromAutodataT2.AvgCycleTime,0)as float) + Cast(isnull(#DailyProductionFromAutodataT2.AvgLoadUnload,0)as float)),'hh:mm:ss') as frmtActualCycletime,  --ER0401
dbo.f_formattime((Cast(isnull(#DailyProductionFromAutodataT2.AvgCycleTime,0)as float) + Cast(isnull(#DailyProductionFromAutodataT2.AvgLoadUnload,0)as float)),'hh') as frmtActualCycletime,  --ER0401
cyclefficiency =
CASE
when Cast(isnull(#DailyProductionFromAutodataT2.CycleTime,0) as float) + cast(isnull(#DailyProductionFromAutodataT2.LoadUnload,0)as float) > 0 and
Cast(isnull(#DailyProductionFromAutodataT2.AvgCycleTime,0) as float) + Cast(isnull(#DailyProductionFromAutodataT2.AvgLoadUnload,0) as float) > 0
then Round(( Cast(#DailyProductionFromAutodataT2.CycleTime as Float) + Cast(#DailyProductionFromAutodataT2.LoadUnload as float))/(cast(#DailyProductionFromAutodataT2.AvgCycleTime as float) + cast(#DailyProductionFromAutodataT2.AvgLoadUnload as float))*100,2)
else 0
END ,
--dbo.f_formattime(#DailyProductionFromAutodataT1.UtilisedTime, 'hh:mm') as ProdTime,--ER0401
dbo.f_formattime(#DailyProductionFromAutodataT1.UtilisedTime, 'hh') as ProdTime,--ER0401
--dbo.f_formattime(#DailyProductionFromAutodataT1.DownTime, 'hh:mm') as DownTime, --ER0401
dbo.f_formattime(#DailyProductionFromAutodataT1.DownTime, 'hh') as DownTime, --ER0401
isnull(#DailyProductionFromAutodataT1.DownReason3,'') as SettingTime,
isnull(round(#DailyProductionFromAutodataT1.OverallEfficiency,2),0.00) as OverallEfficiency
,Isnull(#DailyProductionFromAutodataT1.DownReason1,'') as DownReason1,isnull(#DailyProductionFromAutodataT1.DownReason2,'') as DownReason2
,#DailyProductionFromAutodataT4.EmployeeName as Operator
from #DailyProductionFromAutodataT4 left outer  JOIN #DailyProductionFromAutodataT1 ON
#DailyProductionFromAutodataT1.MachineID = #DailyProductionFromAutodataT4.MachineID
and #DailyProductionFromAutodataT1.Pdate=#DailyProductionFromAutodataT4.Cdate
left outer  join  #DailyProductionFromAutodataT2 ON
#DailyProductionFromAutodataT4.MachineID = #DailyProductionFromAutodataT2.MachineID
and #DailyProductionFromAutodataT4.Cdate=#DailyProductionFromAutodataT2.Cdate 
and #DailyProductionFromAutodataT4.Component=#DailyProductionFromAutodataT2.Component 
and #DailyProductionFromAutodataT4.operation=#DailyProductionFromAutodataT2.operation 
order by #DailyProductionFromAutodataT4.Cdate,#DailyProductionFromAutodataT4.PlantID,#DailyProductionFromAutodataT4.MachineID

END
