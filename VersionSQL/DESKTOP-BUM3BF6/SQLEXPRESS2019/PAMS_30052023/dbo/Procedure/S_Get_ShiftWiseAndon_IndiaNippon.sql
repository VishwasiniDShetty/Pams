/****** Object:  Procedure [dbo].[S_Get_ShiftWiseAndon_IndiaNippon]    Committed by VersionSQL https://www.versionsql.com ******/

/*

[dbo].[S_Get_ShiftWiseAndon_IndiaNippon] '2021-01-11 09:00:00.000','2021-01-12 04:00:00.000','VULKAN','','1','MachineWise',''
[dbo].[S_Get_ShiftWiseAndon_IndiaNippon] '2021-04-08 06:00:00.000','2021-04-08 11:00:00.000','VULKAN','','1','MachineWise',''
[dbo].[S_Get_ShiftWiseAndon_IndiaNippon] '2021-04-16 15:00:00','2021-04-16 23:45:00','','','','MachineWise',''
exec [S_Get_ShiftWiseAndon_IndiaNippon] @StartTime=N'2021-09-07 06:30:00',@EndTime=N'2021-09-07 15:00:00',@GroupID=N'CNC CELL',@Param=N'MachineWise'
*/
CREATE procedure [dbo].[S_Get_ShiftWiseAndon_IndiaNippon]

@StartTime datetime='',
	@EndTime datetime='',
	@PlantID nvarchar(50)='',
	@SortOrder nvarchar(50)='',
	@GroupID nvarchar(50)='',
	@param nvarchar(50)='',
	@Shift nvarchar(50)=''
as
begin
/*Declare Variables*/
Declare @strPlantID as nvarchar(255)
Declare @strSql as nvarchar(4000)
Declare @StrTPMMachines AS nvarchar(500)		
declare @StrGroupID as nvarchar(255)

SELECT @StrTPMMachines=''					
SELECT @strPlantID = ''
select @StrGroupID=''
select @strSql=''
If ISNULL(@SortOrder,'')='' and (ISNULL(@param,'')='' or @param='Machinewise')
BEGIN
	SET @SortOrder = 'MachineID ASC'
END
Declare @Strsortorder as nvarchar(max)
Select @Strsortorder= 'order by C.' + @SortOrder + ' '
Declare @CurrTime as DateTime
SET @CurrTime =	convert(nvarchar(20),getdate(),120)	
--SET @CurrTime =	'2021-09-06 11:00:00'		
print @CurrTime




CREATE TABLE #CockPitData 
(
	MachineID nvarchar(50),
	MachineInterface nvarchar(50) PRIMARY KEY,
	ProductionEfficiency float,
	AvailabilityEfficiency float,
	QualityEfficiency float, 
	OverallEfficiency float,
	Components float,
	RejCount float, 
	TotalTime float,
	UtilisedTime float,
	ManagementLoss float,
	DownTime float,
	TurnOver float,
	ReturnPerHour float,
	ReturnPerHourtotal float,
	CN float,
	Lastcycletime datetime,
	MaxDownReason nvarchar(50) DEFAULT ('')
	,MLDown float,
	LastCycleCO nvarchar(100),
	LastCycleStart Datetime,
	LastCycleEnd Datetime,
	ElapsedTime int,
	LastCycleSpindleRunTime int,
	LastCycleDatatype nvarchar(50),
	RunningCycleUT float,
	RunningCycleDT float,
	RunningCyclePDT float,
	RunningCycleML float,
	RunningCycleAE float,
	MachineStatus nvarchar(100),
	MachineLiveStatus nvarchar(50),
	MachineLiveStatusColor nvarchar(50),
	LastCycleCompDescription nvarchar(100),
	LastCycleOperation nvarchar(50),
	LastCycleOpnDescription nvarchar(100),
    LastCompletedDowntime nvarchar(50),
	CurrentDowntime nvarchar(50),
	RunningCycleStdTime float,
    RunningComponentBoxColor nvarchar(50),
    ReworkCount float,
	WorkOrder nvarchar(50),

	Target int default 0
)

CREATE TABLE #PLD
(
	MachineID nvarchar(50),
	MachineInterface nvarchar(50) NOT NULL,
	pPlannedDT float Default 0,
	dPlannedDT float Default 0,
	MPlannedDT float Default 0,
	IPlannedDT float Default 0,
	DownID nvarchar(50)
)


CREATE TABLE #BatchPLD
(
	MachineID nvarchar(50),
	MachineInterface nvarchar(50) NOT NULL,
	pPlannedDT float Default 0,
	dPlannedDT float Default 0,
	MPlannedDT float Default 0,
	IPlannedDT float Default 0,
	DownID nvarchar(50),
	StartTime datetime,
	EndTime datetime
)

Create table #PlannedDownTimes
(
	MachineID nvarchar(50) NOT NULL, 
	MachineInterface nvarchar(50) NOT NULL, 
	StartTime DateTime NOT NULL,
	EndTime DateTime NOT NULL 
)

Create table #BatchPlannedDownTimes
(
	MachineID nvarchar(50) NOT NULL, 
	MachineInterface nvarchar(50) NOT NULL, 
	StartTime DateTime NOT NULL,
	EndTime DateTime NOT NULL 
)

create table #Shift2
(
[ShiftID] [int] NOT NULL,
	[HourName] [nvarchar](50) NULL,
	[HourID] [int] NOT NULL,
	[FromDay] [int] NULL,
	[ToDay] [int] NULL,
	[FromTime] [datetime] NULL,
	[ToTime] [datetime] NULL,
	[Minutes] [int] NULL,
	[IsEnable] [bit] NULL
)

ALTER TABLE #PLD
	ADD PRIMARY KEY CLUSTERED
		(   [MachineInterface]
						
		) ON [PRIMARY]

	ALTER TABLE #BatchPLD
ADD PRIMARY KEY CLUSTERED
	(   [MachineInterface]
						
	) ON [PRIMARY]

ALTER TABLE #PlannedDownTimes
	ADD PRIMARY KEY CLUSTERED
		(   [MachineInterface],
			[StartTime],
			[EndTime]
						
		) ON [PRIMARY]

ALTER TABLE #BatchPlannedDownTimes
	ADD PRIMARY KEY CLUSTERED
		(   [MachineInterface],
			[StartTime],
			[EndTime]
						
		) ON [PRIMARY]

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

Create Table #Shift
(	
	[ShiftID] [int] NOT NULL,
	[HourName] [nvarchar](50) NULL,
	[HourID] [int] NOT NULL,
	[FromDay] [int] NULL,
	[ToDay] [int] NULL,
	[FromTime] [datetime] NULL,
	[ToTime] [datetime] NULL,
	[Minutes] [int] NULL,
	[IsEnable] [bit] NULL	
)

CREATE TABLE #Target    
(  
  
MachineID nvarchar(50) NOT NULL,  
machineinterface nvarchar(50),  
Compinterface nvarchar(50),  
OpnInterface nvarchar(50), 
Component nvarchar(50) NOT NULL,  
Operation nvarchar(50) NOT NULL,  
FromTm datetime,  
ToTm datetime,     
msttime datetime,  
ndtime datetime,  
batchid int,  
autodataid bigint ,
stdTime float,
SubOperations int
)  
  
CREATE TABLE #FinalTarget    
(  
	
	MachineID nvarchar(50) NOT NULL,  
	machineinterface nvarchar(50),  
	Component nvarchar(50) NOT NULL,  
	Compinterface nvarchar(50),  
	Operation nvarchar(50) NOT NULL,  
	OpnInterface nvarchar(50),  
	FromTm datetime,  
	ToTm datetime,     
	BatchStart datetime,  
	BatchEnd datetime,  
	batchid int,  
	stdTime float,
	Target int default 0,
	Actual int default 0,
	Runtime float default 0,
	SubOperations int,

	OverAllEfficiency float default 0
)  

CREATE TABLE #FinalTarget1  
(  
	
	MachineID nvarchar(50) NOT NULL,  
	machineinterface nvarchar(50),       
	BatchStart datetime,  
	BatchEnd datetime,  

	UtilisedTime float,
	ManagementLoss float,
	downtime float,
	MLDown float,
	components float,
	CN float,
	ProductionEfficiency float,
	AvailabilityEfficiency float,
	RejCount float,
	QualityEfficiency float,
	OverAllEfficiency float default 0
)  

CREATE TABLE #ShiftTarget    
(  
  
MachineID nvarchar(50) NOT NULL,  
machineinterface nvarchar(50),  
Compinterface nvarchar(50),  
OpnInterface nvarchar(50), 
Component nvarchar(50) NOT NULL,  
Operation nvarchar(50) NOT NULL,  
FromTm datetime,  
ToTm datetime,     
msttime datetime,  
ndtime datetime,  
batchid int,  
autodataid bigint ,
stdTime float,
SubOperations int
)  
  
CREATE TABLE #ShiftFinalTarget    
(  
	
	MachineID nvarchar(50) NOT NULL,  
	machineinterface nvarchar(50),  
	Component nvarchar(50) NOT NULL,  
	Compinterface nvarchar(50),  
	Operation nvarchar(50) NOT NULL,  
	OpnInterface nvarchar(50),  
	FromTm datetime,  
	ToTm datetime,     
	BatchStart datetime,  
	BatchEnd datetime,  
	batchid int,  
	stdTime float,
	Target int default 0,
	Actual int default 0,
	Runtime float default 0,
	SubOperations int,
)  


CREATE TABLE #ShiftDefn
(
	ShiftDate datetime,		
	Shiftname nvarchar(20),
	ShftSTtime datetime,
	ShftEndTime datetime	
)

declare @startdate as datetime
declare @enddate as datetime
declare @startdatetime nvarchar(20)

--ER0374 From Here
--select @startdate = dbo.f_GetLogicalDay(@StartTime,'start')
--select @enddate = dbo.f_GetLogicalDay(@endtime,'start')
select @startdate = dbo.f_GetLogicalDaystart(@StartTime)
select @enddate = dbo.f_GetLogicalDaystart(@endtime)
--ER0374 Till Here

while @startdate<=@enddate
Begin

	select @startdatetime = CAST(datePart(yyyy,@startdate) AS nvarchar(4)) + '-' + 
     CAST(datePart(mm,@startdate) AS nvarchar(2)) + '-' + 
     CAST(datePart(dd,@startdate) AS nvarchar(2))

	INSERT INTO #ShiftDefn(ShiftDate,Shiftname,ShftSTtime,ShftEndTime)
	select @startdate,ShiftName,
	Dateadd(DAY,FromDay,(convert(datetime, @startdatetime + ' ' + CAST(datePart(hh,FromTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,FromTime) as nvarchar(2))+ ':' + CAST(datePart(ss,FromTime) as nvarchar(2))))) as StartTime,
	DateAdd(Day,ToDay,(convert(datetime, @startdatetime + ' ' + CAST(datePart(hh,ToTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,ToTime) as nvarchar(2))+ ':' + CAST(datePart(ss,ToTime) as nvarchar(2))))) as EndTime
	from shiftdetails where running = 1 order by shiftid
	Select @startdate = dateadd(d,1,@startdate)
END

create table #shift1
(
	--ShiftDate Datetime, --DR0333
	ShiftDate nvarchar(10), --DR0333
	shiftname nvarchar(20),
	Shiftstart datetime,
	Shiftend datetime,
	shiftid int
)

Insert into #shift1 (ShiftDate,shiftname,Shiftstart,Shiftend)
select convert(nvarchar(10),ShiftDate,126),shiftname,ShftSTtime,ShftEndTime from #ShiftDefn where ShftSTtime>=@StartTime and ShftEndTime<=@endtime --DR0333

Update #shift1 Set shiftid = isnull(#shift1.Shiftid,0) + isnull(T1.shiftid,0) from
(Select SD.shiftid ,SD.shiftname from shiftdetails SD
inner join #shift1 S on SD.shiftname=S.shiftname where
running=1 )T1 inner join #shift1 on  T1.shiftname=#shift1.shiftname


declare @stdate as nvarchar(20)
select @stdate = CAST(datePart(yyyy,@StartTime) AS nvarchar(4)) + '-' + CAST(datePart(mm,@StartTime) AS nvarchar(2)) + '-' + CAST(datePart(dd,@StartTime) AS nvarchar(2))


insert into #Shift(ShiftID,HourName,HourID,FromDay,ToDay,FromTime,ToTime,Minutes,IsEnable)
  select S.shiftid,SH.HourName,SH.HourID,SH.FromDay,SH.ToDay,              
  dateadd(day,SH.Fromday,(convert(datetime,@stdate + ' ' + CAST(datePart(hh,SH.HourStart) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourStart) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourStart) as nvarchar(2))))),              
  dateadd(day,SH.Today,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.HourEnd) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourEnd) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourEnd) as nvarchar(2))))),Minutes,IsEnable              
 from shiftdetails S inner join ShiftHourDefinition SH on SH.shiftid=S.Shiftid  where S.Running=1


Begin
	insert into #Shift2(ShiftID,HourName,HourID,FromDay,ToDay,FromTime,ToTime,Minutes,IsEnable)
	select * from #Shift where (@CurrTime> FromTime and @CurrTime<= ToTime)
End


Select @strsql=''
select @strsql ='insert into #T_autodata '
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'
	select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'
select @strsql = @strsql + ' from autodata where (( sttime >='''+ convert(nvarchar(25),@StartTime,120)+''' and ndtime <= '''+ convert(nvarchar(25),@EndTime,120)+''' ) OR '
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@StartTime,120)+''' and ndtime >'''+ convert(nvarchar(25),@EndTime,120)+''' )OR '
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@StartTime,120)+''' and ndtime >'''+ convert(nvarchar(25),@StartTime,120)+'''
					and ndtime<='''+convert(nvarchar(25),@EndTime,120)+''' )'
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@StartTime,120)+''' and ndtime >'''+ convert(nvarchar(25),@EndTime,120)+''' and sttime<'''+convert(nvarchar(25),@EndTime,120)+''' ) )'
print @strsql
exec (@strsql)



IF ( SELECT TOP 1 ValueInText FROM  CockpitDefaults WHERE Parameter='TpmEnbMac')='E'
BEGIN
	SET  @StrTPMMachines = 'AND MachineInformation.TPMTrakEnabled = 1'
END
ELSE
BEGIN
	SET  @StrTPMMachines = ' '
END

if isnull(@PlantID,'')<> ''
Begin
	
	SET @strPlantID = ' AND PlantMachine.PlantID = N''' + @PlantID + ''''
	
End
if isnull(@GroupID,'')<> ''
Begin
	SET @strGroupID = ' AND PlantMachineGroups.GroupID = N''' + @GroupID + ''''
End


SET @strSql = 'INSERT INTO #CockpitData (
	MachineID ,
	MachineInterface,
	ProductionEfficiency ,
	AvailabilityEfficiency,
	QualityEfficiency, 
	OverallEfficiency,
	Components ,
	RejCount, 
	TotalTime ,
	UtilisedTime ,	
	ManagementLoss,
	DownTime ,
	TurnOver ,
	ReturnPerHour ,
	ReturnPerHourtotal,
	CN 
	) '
SET @strSql = @strSql + ' SELECT MachineInformation.MachineID, MachineInformation.interfaceid ,0,0,0,0,0,0,0,0,0,0,0,0,0,0 FROM MachineInformation 
			  LEFT OUTER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID
			  LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID
 WHERE MachineInformation.interfaceid > ''0'' '
SET @strSql =  @strSql+ @strPlantID + @StrTPMMachines + @StrGroupID
EXEC(@strSql)

--Get the Machines into #PLD
SET @strSql = ''
SET @strSql = 'INSERT INTO #PLD(MachineID,MachineInterface,pPlannedDT,dPlannedDT)
	SELECT machineinformation.MachineID ,Interfaceid,0  ,0 FROM MachineInformation
		LEFT OUTER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID 
    LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID
	 WHERE  MachineInformation.interfaceid > ''0'' '
SET @strSql =  @strSql + @StrTPMMachines + @StrGroupID
EXEC(@strSql)

/* Planned Down times for the given time period */
SET @strSql = ''
SET @strSql = 'Insert into #PlannedDownTimes
	SELECT Machine,InterfaceID,
		CASE When StartTime<''' + convert(nvarchar(20),@StartTime,120)+''' Then ''' + convert(nvarchar(20),@StartTime,120)+''' Else StartTime End As StartTime,
		CASE When EndTime>''' + convert(nvarchar(20),@EndTime,120)+''' Then ''' + convert(nvarchar(20),@EndTime,120)+''' Else EndTime End As EndTime
	FROM PlannedDownTimes INNER JOIN MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID
	LEFT OUTER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID 
    LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID 
	and PlantMachineGroups.machineid = PlantMachine.MachineID
	WHERE PDTstatus =1 and(
	(StartTime >= ''' + convert(nvarchar(20),@StartTime,120)+''' AND EndTime <=''' + convert(nvarchar(20),@EndTime,120)+''')
	OR ( StartTime < ''' + convert(nvarchar(20),@StartTime,120)+'''  AND EndTime <= ''' + convert(nvarchar(20),@EndTime,120)+''' AND EndTime > ''' + convert(nvarchar(20),@StartTime,120)+''' )
	OR ( StartTime >= ''' + convert(nvarchar(20),@StartTime,120)+'''   AND StartTime <''' + convert(nvarchar(20),@EndTime,120)+''' AND EndTime > ''' + convert(nvarchar(20),@EndTime,120)+''' )
	OR ( StartTime < ''' + convert(nvarchar(20),@StartTime,120)+'''  AND EndTime > ''' + convert(nvarchar(20),@EndTime,120)+''')) '
SET @strSql =  @strSql+ @StrGroupID + @StrTPMMachines + ' ORDER BY Machine,StartTime'
EXEC(@strSql)


UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
from
(select      mc,sum(cycletime+loadunload) as cycle
from #T_autodata autodata --ER0374
where (autodata.msttime>=@StartTime)
and (autodata.ndtime<=@EndTime)
and (autodata.datatype=1)
group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface

-- Type 2
UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
from
(select  mc,SUM(DateDiff(second, @StartTime, ndtime)) cycle
from #T_autodata autodata --ER0374
where (autodata.msttime<@StartTime)
and (autodata.ndtime>@StartTime)
and (autodata.ndtime<=@EndTime)
and (autodata.datatype=1)
group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface


-- Type 3
UPDATE  #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
from
(select  mc,sum(DateDiff(second, mstTime, @Endtime)) cycle
from #T_autodata autodata --ER0374
where (autodata.msttime>=@StartTime)
and (autodata.msttime<@EndTime)
and (autodata.ndtime>@EndTime)
and (autodata.datatype=1)
group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface


-- Type 4
UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) + isnull(t2.cycle,0)
from
(select mc,
sum(DateDiff(second, @StartTime, @EndTime)) cycle from #T_autodata autodata --ER0374
where (autodata.msttime<@StartTime)
and (autodata.ndtime>@EndTime)
and (autodata.datatype=1)
group by autodata.mc
)as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface
/* Fetching Down Records from Production Cycle  */
/* If Down Records of TYPE-2*/
UPDATE  #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
FROM
(Select AutoData.mc ,
SUM(
CASE
	When autodata.sttime <= @StartTime Then datediff(s, @StartTime,autodata.ndtime )
	When autodata.sttime > @StartTime Then datediff(s , autodata.sttime,autodata.ndtime)
END) as Down
From #T_autodata AutoData INNER Join --ER0374
	(Select mc,Sttime,NdTime From #T_autodata AutoData
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(msttime < @StartTime)And (ndtime > @StartTime) AND (ndtime <= @EndTime)) as T1
ON AutoData.mc=T1.mc
Where AutoData.DataType=2
And ( autodata.Sttime > T1.Sttime )
And ( autodata.ndtime <  T1.ndtime )
AND ( autodata.ndtime >  @StartTime )
GROUP BY AUTODATA.mc)AS T2 Inner Join #CockpitData on t2.mc = #CockpitData.machineinterface
/* If Down Records of TYPE-3*/
UPDATE  #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
FROM
(Select AutoData.mc ,
SUM(CASE
	When autodata.ndtime > @EndTime Then datediff(s,autodata.sttime, @EndTime )
	When autodata.ndtime <=@EndTime Then datediff(s , autodata.sttime,autodata.ndtime)
END) as Down 
From #T_autodata AutoData INNER Join --ER0374
	(Select mc,Sttime,NdTime From #T_autodata AutoData
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(sttime >= @StartTime)And (ndtime > @EndTime) and (sttime<@EndTime) ) as T1
ON AutoData.mc=T1.mc
Where AutoData.DataType=2
And (T1.Sttime < autodata.sttime  )
And ( T1.ndtime >  autodata.ndtime)
AND (autodata.sttime  <  @EndTime)
GROUP BY AUTODATA.mc)AS T2 Inner Join #CockpitData on t2.mc = #CockpitData.machineinterface
/* If Down Records of TYPE-4*/
UPDATE  #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
FROM
(Select AutoData.mc ,
SUM(CASE

	When autodata.sttime >= @StartTime AND autodata.ndtime <= @EndTime Then datediff(s , autodata.sttime,autodata.ndtime)
	When autodata.sttime < @StartTime AND autodata.ndtime > @StartTime AND autodata.ndtime<=@EndTime Then datediff(s, @StartTime,autodata.ndtime )
	When autodata.sttime>=@StartTime And autodata.sttime < @EndTime AND autodata.ndtime > @EndTime Then datediff(s,autodata.sttime, @EndTime )
	When autodata.sttime<@StartTime AND autodata.ndtime>@EndTime   Then datediff(s , @StartTime,@EndTime)

END) as Down
From #T_autodata AutoData INNER Join 
	(Select mc,Sttime,NdTime From #T_autodata AutoData
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(msttime < @StartTime)And (ndtime > @EndTime) ) as T1
ON AutoData.mc=T1.mc
Where AutoData.DataType=2
And (T1.Sttime < autodata.sttime  )
And ( T1.ndtime >  autodata.ndtime)
AND (autodata.ndtime  >  @StartTime)
AND (autodata.sttime  <  @EndTime)
GROUP BY AUTODATA.mc
)AS T2 Inner Join #CockpitData on t2.mc = #CockpitData.machineinterface



--mod 4:Get utilised time over lapping with PDT.
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
BEGIN

	------------------------------------ ER0374 Added Till Here ---------------------------------
	UPDATE #PLD set pPlannedDT =isnull(pPlannedDT,0) + isNull(TT.PPDT ,0)
	FROM(
		--Production Time in PDT
		SELECT autodata.MC,SUM
			(CASE
			WHEN autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN DateDiff(second,autodata.msttime,autodata.ndtime) 
			WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )
			WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END)  as PPDT
			FROM (select M.machineid,mc,msttime,ndtime from #T_autodata autodata
				inner join machineinformation M on M.interfaceid=Autodata.mc
				 where autodata.DataType=1 And 
				((autodata.msttime >= @starttime  AND autodata.ndtime <=@Endtime)
				OR ( autodata.msttime < @starttime  AND autodata.ndtime <= @Endtime AND autodata.ndtime > @starttime )
				OR ( autodata.msttime >= @starttime   AND autodata.msttime <@Endtime AND autodata.ndtime > @Endtime )
				OR ( autodata.msttime < @starttime  AND autodata.ndtime > @Endtime))
				)
		AutoData inner jOIN #PlannedDownTimes T on T.Machineid=AutoData.machineid
		WHERE 
			(
			(autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )
		group by autodata.mc
	)
	 as TT INNER JOIN #PLD ON TT.mc = #PLD.MachineInterface


		--mod 4(4):Handle intearction between ICD and PDT for type 1 production record for the selected time period.
		UPDATE  #PLD set IPlannedDT =isnull(IPlannedDT,0) + isNull(T2.IPDT ,0) 	FROM	(
		Select T1.mc,SUM(
			CASE 	
				When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1
				When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2
				When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3
				when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4
			END) as IPDT from
		(Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype from #T_autodata A
		Where A.DataType=2
		and exists 
			(
			Select B.Sttime,B.NdTime,B.mc From #T_autodata B
			Where B.mc = A.mc and
			B.DataType=1 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And
			(B.msttime >= @starttime AND B.ndtime <= @Endtime) and
			  (B.sttime <= A.sttime) AND (B.ndtime >= A.ndtime) --DR0339
			)
		 )as T1 inner join
		(select  machine,Case when starttime<@starttime then @starttime else starttime end as starttime, 
		case when endtime> @Endtime then @Endtime else endtime end as endtime from dbo.PlannedDownTimes 
		where ((( StartTime >=@starttime) And ( EndTime <=@Endtime))
		or (StartTime < @starttime  and  EndTime <= @Endtime AND EndTime > @starttime)
		or (StartTime >= @starttime  AND StartTime <@Endtime AND EndTime > @Endtime)
		or (( StartTime <@starttime) And ( EndTime >@Endtime )) )
		)T
		on T1.machine=T.machine AND
		((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
		or (T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
		or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
		or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )group by T1.mc
		)AS T2  INNER JOIN #PLD ON T2.mc = #PLD.MachineInterface
		---mod 4(4)
	
	/* Fetching Down Records from Production Cycle  */
	/* If production  Records of TYPE-2*/
	UPDATE  #PLD set IPlannedDT =isnull(IPlannedDT,0) + isNull(T2.IPDT ,0) 	FROM	(
		Select T1.mc,SUM(
		CASE 	
			When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1
			When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2
			When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3
			when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT from
		(Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype from #T_autodata A
		Where A.DataType=2
		and exists 
		(
		Select B.Sttime,B.NdTime From #T_autodata B
		Where B.mc = A.mc and
		B.DataType=1 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And
		(B.msttime < @StartTime And B.ndtime > @StartTime AND B.ndtime <= @EndTime) 
		And ((A.Sttime > B.Sttime) And ( A.ndtime < B.ndtime) AND ( A.ndtime > @StartTime ))
		)
		)as T1 inner join
		(select  machine,Case when starttime<@starttime then @starttime else starttime end as starttime, 
		case when endtime> @Endtime then @Endtime else endtime end as endtime from dbo.PlannedDownTimes 
		where ((( StartTime >=@starttime) And ( EndTime <=@Endtime))
		or (StartTime < @starttime  and  EndTime <= @Endtime AND EndTime > @starttime)
		or (StartTime >= @starttime  AND StartTime <@Endtime AND EndTime > @Endtime)
		or (( StartTime <@starttime) And ( EndTime >@Endtime )) )
		)T
		on T1.machine=T.machine AND
		(( T.StartTime >= @StartTime ) And ( T.StartTime <  T1.ndtime )) group by T1.mc
	)AS T2  INNER JOIN #PLD ON T2.mc = #PLD.MachineInterface
	
	/* If production Records of TYPE-3*/
	UPDATE  #PLD set IPlannedDT =isnull(IPlannedDT,0) + isNull(T2.IPDT ,0)FROM (
	Select T1.mc,SUM(
		CASE 	
			When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1
			When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2
			When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3
			when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT from
		(Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype from #T_autodata A
		Where A.DataType=2
		and exists 
		(
		Select B.Sttime,B.NdTime From #T_autodata B
		Where B.mc = A.mc and
		B.DataType=1 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And
		(B.sttime >= @StartTime And B.ndtime > @EndTime and B.sttime <@EndTime) and
		((B.Sttime < A.sttime  )And ( B.ndtime > A.ndtime) AND (A.msttime < @EndTime))
		)
		)as T1 inner join
		(select  machine,Case when starttime<@starttime then @starttime else starttime end as starttime, 
		case when endtime> @Endtime then @Endtime else endtime end as endtime from dbo.PlannedDownTimes 
		where ((( StartTime >=@starttime) And ( EndTime <=@Endtime))
		or (StartTime < @starttime  and  EndTime <= @Endtime AND EndTime > @starttime)
		or (StartTime >= @starttime  AND StartTime <@Endtime AND EndTime > @Endtime)
		or (( StartTime <@starttime) And ( EndTime >@Endtime )) )
		)T
		on T1.machine=T.machine
		AND (( T.EndTime > T1.Sttime )And ( T.EndTime <=@EndTime )) group by T1.mc
		)AS T2  INNER JOIN #PLD ON T2.mc = #PLD.MachineInterface
	
	
	/* If production Records of TYPE-4*/
	UPDATE  #PLD set IPlannedDT =isnull(IPlannedDT,0) + isNull(T2.IPDT ,0)FROM (
	Select T1.mc,SUM(
	CASE 	
		When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1
		When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2
		When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3
		when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT from
	(Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype from #T_autodata A
	Where A.DataType=2
	and exists 
	(
	Select B.Sttime,B.NdTime From #T_autodata B
	Where B.mc = A.mc and
	B.DataType=1 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And
	(B.msttime < @StartTime And B.ndtime > @EndTime)
	And ((B.Sttime < A.sttime)And ( B.ndtime >  A.ndtime)AND (A.ndtime  >  @StartTime) AND (A.sttime  <  @EndTime))
	)
	)as T1 inner join
		(select  machine,Case when starttime<@starttime then @starttime else starttime end as starttime, 
		case when endtime> @Endtime then @Endtime else endtime end as endtime from dbo.PlannedDownTimes 
		where ((( StartTime >=@starttime) And ( EndTime <=@Endtime))
		or (StartTime < @starttime  and  EndTime <= @Endtime AND EndTime > @starttime)
		or (StartTime >= @starttime  AND StartTime <@Endtime AND EndTime > @Endtime)
		or (( StartTime <@starttime) And ( EndTime >@Endtime )) )
		)T
		on T1.machine=T.machine AND
	(( T.StartTime >=@StartTime) And ( T.EndTime <=@EndTime )) group by T1.mc
	)AS T2  INNER JOIN #PLD ON T2.mc = #PLD.MachineInterface
  ------------------------------------ ER0374 Added Till Here ---------------------------------


END



--mod 4
/*******************************      Utilised Calculation Ends ***************************************************/
/*******************************Down Record***********************************/
--**************************************** ManagementLoss and Downtime Calculation Starts **************************************
---Below IF condition added by Mrudula for mod 4. TO get the ML if 'Ignore_Dtime_4m_PLD'<>"Y"
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y')
BEGIN
		-- Type 1
		UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
		from
		(select mc,sum(
		CASE
		WHEN (loadunload) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
		THEN isnull(downcodeinformation.Threshold,0)
		ELSE loadunload 
		END) AS LOSS
		from #T_autodata autodata  
		INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
		where (autodata.msttime>=@StartTime)
		and (autodata.ndtime<=@EndTime)
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1) 
		and (downcodeinformation.ThresholdfromCO <>1) 
		group by autodata.mc) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface
		-- Type 2
		UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
		from
		(select      mc,sum(
		CASE WHEN DateDiff(second, @StartTime, ndtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
		then isnull(downcodeinformation.Threshold,0)
		ELSE DateDiff(second, @StartTime, ndtime)
		END)loss
		from #T_autodata autodata  
		INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
		where (autodata.sttime<@StartTime)
		and (autodata.ndtime>@StartTime)
		and (autodata.ndtime<=@EndTime)
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1)
		and (downcodeinformation.ThresholdfromCO <>1) 
		group by autodata.mc
		) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface
		-- Type 3
		UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
		from
		(select      mc,SUM(
		CASE WHEN DateDiff(second,stTime, @Endtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
		then isnull(downcodeinformation.Threshold,0)
		ELSE DateDiff(second, stTime, @Endtime)
		END)loss
		from #T_autodata autodata 
		INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
		where (autodata.msttime>=@StartTime)
		and (autodata.sttime<@EndTime)
		and (autodata.ndtime>@EndTime)
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1)
		and (downcodeinformation.ThresholdfromCO <>1) 
		group by autodata.mc
		) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface
		
		UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
		from
		(select mc,sum(
		CASE WHEN DateDiff(second, @StartTime, @Endtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
		then isnull(downcodeinformation.Threshold,0)
		ELSE DateDiff(second, @StartTime, @Endtime)
		END)loss
		from #T_autodata autodata 
		INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
		where autodata.msttime<@StartTime
		and autodata.ndtime>@EndTime
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1)
		and (downcodeinformation.ThresholdfromCO <>1)
		group by autodata.mc
		) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface
		---get the downtime for the time period
		UPDATE #CockpitData SET downtime = isnull(downtime,0) + isNull(t2.down,0)
		from
		(select mc,sum(
				CASE
				WHEN  autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime  THEN  loadunload
				WHEN (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  THEN DateDiff(second, @StartTime, ndtime)
				WHEN (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)  THEN DateDiff(second, stTime, @Endtime)
				WHEN autodata.msttime<@StartTime and autodata.ndtime>@EndTime   THEN DateDiff(second, @StartTime, @EndTime)
				END
			)AS down
		from #T_autodata autodata 
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		where autodata.datatype=2 AND
		(
		(autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)
		OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
		OR (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
		OR (autodata.msttime<@StartTime and autodata.ndtime>@EndTime )
		)
		group by autodata.mc
		) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface
--mod 4
End


--mod 4
---mod 4: Handling interaction between PDT and downtime . Also interaction between PDT and Management Loss
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN
	---step 1
	
	UPDATE #CockpitData SET downtime = isnull(downtime,0) + isNull(t2.down,0)
	from
	(select mc,sum(
			CASE
	        WHEN  autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime  THEN  loadunload
			WHEN (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  THEN DateDiff(second, @StartTime, ndtime)
			WHEN (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)  THEN DateDiff(second, stTime, @Endtime)
			WHEN autodata.msttime<@StartTime and autodata.ndtime>@EndTime   THEN DateDiff(second, @StartTime, @EndTime)
			END
		)AS down
	from #T_autodata autodata
	inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
	where autodata.datatype=2 AND
	(
	(autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)
	OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
	OR (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
	OR (autodata.msttime<@StartTime and autodata.ndtime>@EndTime )
	) AND (downcodeinformation.availeffy = 0)
	group by autodata.mc
	) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface
	--select * from #CockpitData
	---step 2
	---mod 4 checking for (downcodeinformation.availeffy = 0) to get the overlapping PDT and Downs which is not ML
	UPDATE #PLD set dPlannedDT =isnull(dPlannedDT,0) + isNull(TT.PPDT ,0)
	FROM(
		--Production PDT
		SELECT autodata.MC, SUM
		   (CASE
			WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PPDT
		FROM #T_autodata AutoData
		CROSS jOIN #PlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)
			 AND (downcodeinformation.availeffy = 0)
		group by autodata.mc
	) as TT INNER JOIN #PLD ON TT.mc = #PLD.MachineInterface
	
	UPDATE #CockpitData SET  ManagementLoss = isnull(ManagementLoss,0) + isNull(t4.Mloss,0),MLDown=isNull(MLDown,0)+isNull(t4.Dloss,0)
	from
	(select T3.mc,sum(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss from (
	select   t1.id,T1.mc,T1.Threshold,
	case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0
	then DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)- isnull(T1.Threshold ,0)
	else 0 End  as Dloss,
	case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0
	then isnull(T1.Threshold,0)
	else (DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)) End  as Mloss
	 from
	
	(   select id,mc,comp,opn,opr,D.threshold,
		case when autodata.sttime<@StartTime then @StartTime else sttime END as sttime,
	       	case when ndtime>@EndTime then @EndTime else ndtime END as ndtime
		from #T_autodata autodata --ER0374
		inner join downcodeinformation D
		on autodata.dcode=D.interfaceid where autodata.datatype=2 AND
		(
		(autodata.sttime>=@StartTime  and  autodata.ndtime<=@EndTime)
		OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
		OR (autodata.sttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
		OR (autodata.sttime<@StartTime and autodata.ndtime>@EndTime )
		) AND (D.availeffy = 1) 		
		and (D.ThresholdfromCO <>1)) as T1 	
	left outer join
	(SELECT autodata.id,
		       sum(CASE
			WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PPDT
		FROM #T_autodata AutoData 
		CROSS jOIN #PlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)
			AND (downcodeinformation.availeffy = 1) 
			AND (downcodeinformation.ThresholdfromCO <>1) --NR0097 
			group  by autodata.id ) as T2 on T1.id=T2.id ) as T3  group by T3.mc
	) as t4 inner join #CockpitData on t4.mc = #CockpitData.machineinterface


	---mod 4 checking for (downcodeinformation.availeffy = 1) to get the overlapping PDT and Downs which is ML
	UPDATE #PLD set MPlannedDT =isnull(MPlannedDT,0) + isNull(TT.PPDT ,0)
	FROM(
		--Production PDT
		SELECT autodata.MC, SUM
		   (CASE
			WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PPDT
		FROM #T_autodata AutoData --ER0374
		CROSS jOIN #PlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)
			 AND (downcodeinformation.availeffy = 1) 
			AND (downcodeinformation.ThresholdfromCO <>1) --NR0097 
		group by autodata.mc
	) as TT INNER JOIN #PLD ON TT.mc = #PLD.MachineInterface

	UPDATE #CockpitData SET downtime = isnull(downtime,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)
	
END



---mod 4: Till here Handling interaction between PDT and downtime . Also interaction between PDT and Management Loss
--mod 4:If Ignore_Dtime_4m_PLD<> Y and Ignore_Dtime_4m_PLD<> N
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y' AND (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
BEGIN
	UPDATE #PLD set dPlannedDT =isnull(dPlannedDT,0) + isNull(TT.PPDT ,0)
	FROM(
		--Production PDT
		SELECT autodata.MC, SUM
		       (CASE
			WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PPDT
		FROM #T_autodata AutoData  --ER0374
		CROSS jOIN #PlannedDownTimes T
		Inner Join DownCodeInformation D ON AutoData.DCode = D.InterfaceID
		WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND D.DownID=(SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD') AND
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)
		
		group by autodata.mc
	) as TT INNER JOIN #PLD ON TT.mc = #PLD.MachineInterface
END
---mod 4:If Ignore_Dtime_4m_PLD<> Y and Ignore_Dtime_4m_PLD<> N
--************************************ Down and Management  Calculation Ends ******************************************
---mod 4
-- Get the value of CN
-- Type 1*/


UPDATE #CockpitData SET CN = isnull(CN,0) + isNull(t2.C1N1,0)
from
(select mc,
SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))* autodata.partscount) C1N1
FROM #T_autodata autodata 
INNER JOIN
componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID AND
componentoperationpricing.componentid = componentinformation.componentid
inner join machineinformation on machineinformation.interfaceid=autodata.mc
and componentoperationpricing.machineid=machineinformation.machineid
where (((autodata.sttime>=@StartTime)and (autodata.ndtime<=@EndTime)) or
((autodata.sttime<@StartTime)and (autodata.ndtime>@StartTime)and (autodata.ndtime<=@EndTime)) )
and (autodata.datatype=1)
group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface

-- mod 4 Ignore count from CN calculation which is over lapping with PDT
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	UPDATE #CockpitData SET CN = isnull(CN,0) - isNull(t2.C1N1,0)
	From
	(
		select mc,SUM((O.cycletime * ISNULL(A.PartsCount,1))/ISNULL(O.SubOperations,1))  C1N1
		From #T_autodata A 
		Inner join machineinformation M on M.interfaceid=A.mc
		Inner join componentinformation C ON A.Comp=C.interfaceid
		Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID
		Cross jOIN #PlannedDownTimes T
		WHERE A.DataType=1 AND T.MachineInterface=A.mc
		AND(A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)
		AND(A.ndtime > @StartTime  AND A.ndtime <=@EndTime)
		Group by mc
	) as T2
	inner join #CockpitData  on t2.mc = #CockpitData.machineinterface
END


--Mod 4
--Calculation of PartsCount Begins..
UPDATE #CockpitData SET components = ISNULL(components,0) + ISNULL(t2.comp,0)
From
(
	  Select mc,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp 
		   From (select mc,SUM(autodata.partscount)AS OrginalCount,comp,opn 
			from #T_autodata autodata --ER0374
		   where (autodata.ndtime>@StartTime) and (autodata.ndtime<=@EndTime) and (autodata.datatype=1)
		   Group By mc,comp,opn) as T1
	Inner join componentinformation C on T1.Comp = C.interfaceid
	Inner join ComponentOperationPricing O ON  T1.Opn = O.interfaceid and C.Componentid=O.componentid
	---mod 2
	inner join machineinformation on machineinformation.machineid =O.machineid
	and T1.mc=machineinformation.interfaceid
	---mod 2
	GROUP BY mc
) As T2 Inner join #CockpitData on T2.mc = #CockpitData.machineinterface




--Mod 4 Apply PDT for calculation of Count
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	UPDATE #CockpitData SET components = ISNULL(components,0) - ISNULL(T2.comp,0) from(
		select mc,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp From ( 
			select mc,Sum(ISNULL(PartsCount,1))AS OrginalCount,comp,opn 
			from #T_autodata autodata 
			CROSS JOIN #PlannedDownTimes T
			WHERE autodata.DataType=1 And T.MachineInterface = autodata.mc
			AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)
			AND (autodata.ndtime > @StartTime  AND autodata.ndtime <=@EndTime)
		    Group by mc,comp,opn
		) as T1
	Inner join Machineinformation M on M.interfaceID = T1.mc
	Inner join componentinformation C on T1.Comp=C.interfaceid
	Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineID = M.MachineID
	GROUP BY MC
	) as T2 inner join #CockpitData on T2.mc = #CockpitData.machineinterface
END

--Mod 4
--Calculation of PartsCount Ends..
--mod 4: Update Utilised Time and Down time

UPDATE #CockpitData
	SET UtilisedTime=(UtilisedTime-ISNULL(#PLD.pPlannedDT,0)+isnull(#PLD.IPlannedDT,0)),
	   DownTime=(DownTime-ISNULL(#PLD.dPlannedDT,0)) 
	From #CockpitData Inner Join #PLD on #PLD.Machineid=#CockpitData.Machineid
---mod 4


---- Calculate efficiencies

UPDATE #CockpitData
SET
	TotalTime = DateDiff(second, @StartTime, @EndTime)

UPDATE #CockpitData
SET
	ProductionEfficiency = (CN/UtilisedTime) ,
	AvailabilityEfficiency = (UtilisedTime)/(UtilisedTime + DownTime - ManagementLoss), 
	ReturnPerHour = (TurnOver/UtilisedTime)*3600,
	ReturnPerHourtotal = (TurnOver/DateDiff(second, @StartTime, @EndTime))*3600
	
WHERE UtilisedTime <> 0



If (SELECT ValueInText From CockpitDefaults Where Parameter ='DisplayTTFormat')='Display TotalTime - Less PDT' 
BEGIN
	UPDATE #CockpitData SET TotalTime = Totaltime - isnull(T1.PDT,0) 
	from
	(Select Machine,SUM(datediff(S,Starttime,endtime))as PDT from Planneddowntimes
	 where starttime>=@starttime and endtime<=@endtime group by machine)T1
	 Inner Join #CockpitData on T1.Machine=#CockpitData.Machineid WHERE UtilisedTime <> 0	
End
----------------------------------------------------------------------------------------------------------------------





Update #Cockpitdata set RejCount = isnull(RejCount,0) + isnull(T1.RejQty,0)
From
( Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A
inner join Machineinformation M on A.mc=M.interfaceid
inner join #Cockpitdata on #Cockpitdata.machineid=M.machineid 
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
where A.CreatedTS>=@StartTime and A.CreatedTS<@Endtime and A.flag = 'Rejection'
and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000'
group by A.mc,M.Machineid
)T1 inner join #Cockpitdata B on B.Machineid=T1.Machineid 



If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	Update #Cockpitdata set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from
	(Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A
	inner join Machineinformation M on A.mc=M.interfaceid
	inner join #Cockpitdata on #Cockpitdata.machineid=M.machineid 
	inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
	Cross join Planneddowntimes P
	where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid 
	and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000' and
	A.CreatedTS>=@StartTime and A.CreatedTS<@Endtime And
	A.CreatedTS>=P.Starttime and A.CreatedTS<P.endtime
	group by A.mc,M.Machineid)T1 inner join #Cockpitdata B on B.Machineid=T1.Machineid 
END




Update #Cockpitdata set RejCount = isnull(RejCount,0) + isnull(T1.RejQty,0)
From
( Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A
inner join Machineinformation M on A.mc=M.interfaceid
inner join #Cockpitdata on #Cockpitdata.machineid=M.machineid 
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
where A.flag = 'Rejection'   --DR0333
and (A.RejDate between @StartTime and @EndTime) and
Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
group by A.mc,M.Machineid
)T1 inner join #Cockpitdata B on B.Machineid=T1.Machineid 



If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	Update #Cockpitdata set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from
	(Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A
	inner join Machineinformation M on A.mc=M.interfaceid
	inner join #Cockpitdata on #Cockpitdata.machineid=M.machineid 
	inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
	Cross join Planneddowntimes P
	where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid
	and (A.RejDate between @StartTime and @EndTime) and
	Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
	and P.starttime>=@StartTime and P.Endtime<=@EndTime
	group by A.mc,M.Machineid)T1 inner join #Cockpitdata B on B.Machineid=T1.Machineid 
END




UPDATE #Cockpitdata SET QualityEfficiency= ISNULL(QualityEfficiency,1) + IsNull(T1.QE,1) 
FROM(Select MachineID,
CAST((Sum(Components))As Float)/CAST((Sum(IsNull(Components,0))+Sum(IsNull(RejCount,0))) AS Float)As QE
From #Cockpitdata Where Components<>0 Group By MachineID
)AS T1 Inner Join #Cockpitdata ON  #Cockpitdata.MachineID=T1.MachineID

UPDATE #CockpitData
SET
	OverAllEfficiency = (ProductionEfficiency * AvailabilityEfficiency * ISNULL(QualityEfficiency,1))*100,
	ProductionEfficiency = ProductionEfficiency * 100 ,
	AvailabilityEfficiency = AvailabilityEfficiency * 100,
	QualityEfficiency = QualityEfficiency*100
	

	/*Shift Target Calculation*/


		Select @strsql=''   
		Select @strsql= 'insert into #ShiftTarget(MachineID,machineinterface,Component,Compinterface,Operation,Opninterface,  
		msttime,ndtime,FromTm,Totm,batchid,autodataid,stdtime,SubOperations)'  
		select @strsql = @strsql + ' SELECT machineinformation.machineid, machineinformation.interfaceid,componentinformation.componentid, componentinformation.interfaceid,  
		componentoperationpricing.operationno, componentoperationpricing.interfaceid,
		Case when autodata.msttime< T.Shiftstart then T.Shiftstart else autodata.msttime end,   
		Case when autodata.ndtime> T.Shiftend then T.Shiftend else autodata.ndtime end,     
		T.Shiftstart,T.Shiftend,0,autodata.id,componentoperationpricing.Cycletime,componentoperationpricing.SubOperations FROM #T_autodata autodata  with(nolock)
		INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID   
		INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID    
		INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID  
		AND componentinformation.componentid = componentoperationpricing.componentid  
		and componentoperationpricing.machineid=machineinformation.machineid   
		Left Outer Join downcodeinformation DI on DI.interfaceid=autodata.dcode  
		Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid
		cross join(select distinct Shiftstart,Shiftend from #shift1) as T
		WHERE (autodata.ndtime > T.Shiftstart and autodata.ndtime <=T.Shiftend)  '  
		select @strsql = @strsql +@strPlantID 
		select @strsql = @strsql + ' order by autodata.msttime'  
		print @strsql  
		exec (@strsql)


		insert into #ShiftFinalTarget(MachineID,Component,operation,machineinterface,Compinterface,Opninterface,batchid,BatchStart,BatchEnd,FromTm,ToTm,stdtime,Actual,Target,Runtime,SubOperations) 
		select MachineID,Component,operation,machineinterface,Compinterface,Opninterface,batchid,min(msttime),max(ndtime),FromTm,ToTm,stdtime,0,0,0,SubOperations
		from
		(
		select MachineID,Component,operation,machineinterface,Compinterface,Opninterface,msttime,ndtime,FromTm,ToTm,stdtime,SubOperations,
		RANK() OVER (
		PARTITION BY t.machineid
		order by t.machineid, t.msttime
		) -
		RANK() OVER (
		PARTITION BY  t.machineid, t.component, t.operation,t.fromtm 
		order by t.machineid, t.fromtm, t.msttime
		) AS batchid
		from #ShiftTarget t 
		) tt
		group by MachineID,Component,operation,machineinterface,Compinterface,Opninterface,batchid,FromTm,ToTm,stdtime,SubOperations
		order by tt.batchid

		update #ShiftFinalTarget set Runtime=datediff(s,BatchStart,BatchEnd)

		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')<>'N'
		BEGIN

			Update #ShiftFinalTarget set Runtime=Isnull(Runtime,0) - Isnull(T3.pdt,0) 
			from (
			Select t2.machineinterface,T2.Machine,T2.BatchStart,T2.BatchEnd,T2.Fromtm,sum(datediff(ss,T2.StartTimepdt,t2.EndTimepdt))as pdt
			from
				(
				Select T1.machineinterface,T1.Compinterface,T1.Opninterface,T1.BatchStart,T1.BatchEnd,T1.FromTm,Pdt.machine,
				Case when  T1.BatchStart <= pdt.StartTime then pdt.StartTime else T1.BatchStart End as StartTimepdt,
				Case when  T1.BatchEnd >= pdt.EndTime then pdt.EndTime else T1.BatchEnd End as EndTimepdt
				from #ShiftFinalTarget T1
				inner join Planneddowntimes pdt on t1.machineid=Pdt.machine
				where PDTstatus = 1  and
				((pdt.StartTime >= t1.BatchStart and pdt.EndTime <= t1.BatchEnd)or
				(pdt.StartTime < t1.BatchStart and pdt.EndTime > t1.BatchStart and pdt.EndTime <=t1.BatchEnd)or
				(pdt.StartTime >= t1.BatchStart and pdt.StartTime <t1.BatchEnd and pdt.EndTime >t1.BatchEnd) or
				(pdt.StartTime <  t1.BatchStart and pdt.EndTime >t1.BatchEnd))
				)T2 group by  t2.machineinterface,T2.Machine,T2.BatchStart,T2.BatchEnd,T2.Fromtm
			) T3 inner join #ShiftFinalTarget T on T.machineinterface=T3.machineinterface and T.BatchStart=T3.BatchStart and  T.BatchEnd=T3.BatchEnd and T.Fromtm=T3.Fromtm

		ENd

		--update #ShiftFinalTarget set Runtime=datediff(s,BatchStart,BatchEnd)

		--		select F.BatchStart,F.BatchEnd,F.Machineid, CO.componentid as component,CO.Operationno as operation,F.Runtime,CO.suboperations,CO.cycletime,
		--tcount=((F.Runtime*CO.suboperations)/CO.cycletime)*isnull(CO.targetpercent,100) /100
		--from componentoperationpricing CO
		--inner join #ShiftFinalTarget F on co.machineid=F.machineid and CO.Componentid=F.Component and Co.operationno=F.Operation  

		update #ShiftFinalTarget set Target= isnull(t2.tcount,0) from
		(
		select F.BatchStart,F.BatchEnd,F.Machineid, CO.componentid as component,CO.Operationno as operation,
		tcount=((F.Runtime*CO.suboperations)/CO.cycletime)*isnull(CO.targetpercent,100) /100
		from componentoperationpricing CO
		inner join #ShiftFinalTarget F on co.machineid=F.machineid and CO.Componentid=F.Component and Co.operationno=F.Operation  
		) as T2 Inner Join #ShiftFinalTarget on t2.Machineid = #ShiftFinalTarget.Machineid and  
		t2.component = #ShiftFinalTarget.component and t2.Operation = #ShiftFinalTarget.Operation   
		and t2.BatchStart=#ShiftFinalTarget.BatchStart and t2.BatchEnd=#ShiftFinalTarget.BatchEnd


		Update #CockPitData set Target=T1.Target
		from (
		select distinct MachineID,sum(Target) as Target from #ShiftFinalTarget group by MachineID
		)T1 inner join #CockPitData T2 on T1.MachineID=T2.MachineID

		---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

		Select @strsql=''   
		Select @strsql= 'insert into #Target(MachineID,machineinterface,Component,Compinterface,Operation,Opninterface,  
		msttime,ndtime,FromTm,Totm,batchid,autodataid,stdtime,SubOperations)'  
		select @strsql = @strsql + ' SELECT machineinformation.machineid, machineinformation.interfaceid,componentinformation.componentid, componentinformation.interfaceid,  
		componentoperationpricing.operationno, componentoperationpricing.interfaceid,
		Case when autodata.msttime< T.FromTime then T.FromTime else autodata.msttime end,   
		Case when autodata.ndtime> T.ToTime then T.ToTime else autodata.ndtime end,     
		T.FromTime,T.ToTime,0,autodata.id,componentoperationpricing.Cycletime,componentoperationpricing.SubOperations FROM #T_autodata autodata  with(nolock)
		INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID   
		INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID    
		INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID  
		AND componentinformation.componentid = componentoperationpricing.componentid  
		and componentoperationpricing.machineid=machineinformation.machineid   
		Left Outer Join downcodeinformation DI on DI.interfaceid=autodata.dcode  
		Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid
		cross join(select distinct FromTime,ToTime from #Shift2) as T
		WHERE (autodata.ndtime > T.FromTime and autodata.ndtime <=T.ToTime)  '  
		select @strsql = @strsql +@strPlantID 
		select @strsql = @strsql + ' order by autodata.msttime'  
		print @strsql  
		exec (@strsql)


		insert into #FinalTarget(MachineID,Component,operation,machineinterface,Compinterface,Opninterface,batchid,BatchStart,BatchEnd,FromTm,ToTm,stdtime,Actual,Target,Runtime,SubOperations) 
		select MachineID,Component,operation,machineinterface,Compinterface,Opninterface,batchid,min(msttime),max(ndtime),FromTm,ToTm,stdtime,0,0,0,SubOperations
		from
		(
		select MachineID,Component,operation,machineinterface,Compinterface,Opninterface,msttime,ndtime,FromTm,ToTm,stdtime,SubOperations,
		RANK() OVER (
		PARTITION BY t.machineid
		order by t.machineid, t.msttime
		) -
		RANK() OVER (
		PARTITION BY  t.machineid, t.component, t.operation,t.fromtm 
		order by t.machineid, t.fromtm, t.msttime
		) AS batchid
		from #Target t 
		) tt
		group by MachineID,Component,operation,machineinterface,Compinterface,Opninterface,batchid,FromTm,ToTm,stdtime,SubOperations
		order by tt.batchid


	    update #FinalTarget set Runtime=datediff(s,BatchStart,BatchEnd)


		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')<>'N'
		BEGIN
			Update #FinalTarget set Runtime=Isnull(Runtime,0) - Isnull(T3.pdt,0) 
			from (
			Select t2.machineinterface,T2.Machine,T2.BatchStart,T2.BatchEnd,T2.Fromtm,sum(datediff(ss,T2.StartTimepdt,t2.EndTimepdt))as pdt
			from
				(
				Select T1.machineinterface,T1.Compinterface,T1.Opninterface,T1.BatchStart,T1.BatchEnd,T1.FromTm,Pdt.machine,
				Case when  T1.BatchStart <= pdt.StartTime then pdt.StartTime else T1.BatchStart End as StartTimepdt,
				Case when  T1.BatchEnd >= pdt.EndTime then pdt.EndTime else T1.BatchEnd End as EndTimepdt
				from #FinalTarget T1
				inner join Planneddowntimes pdt on t1.machineid=Pdt.machine
				where PDTstatus = 1  and
				((pdt.StartTime >= t1.BatchStart and pdt.EndTime <= t1.BatchEnd)or
				(pdt.StartTime < t1.BatchStart and pdt.EndTime > t1.BatchStart and pdt.EndTime <=t1.BatchEnd)or
				(pdt.StartTime >= t1.BatchStart and pdt.StartTime <t1.BatchEnd and pdt.EndTime >t1.BatchEnd) or
				(pdt.StartTime <  t1.BatchStart and pdt.EndTime >t1.BatchEnd))
				)T2 group by  t2.machineinterface,T2.Machine,T2.BatchStart,T2.BatchEnd,T2.Fromtm
			) T3 inner join #FinalTarget T on T.machineinterface=T3.machineinterface and T.BatchStart=T3.BatchStart and  T.BatchEnd=T3.BatchEnd and T.Fromtm=T3.Fromtm

		ENd

		/* Actual Calculation*/

		UPDATE #FinalTarget SET Actual=isnull(t2.cnt,0) FROM 
		( select tt.machineid as machine,tt.BatchStart,tt.BatchEnd,
			((CAST(Sum(ISNULL(autodata.PartsCount,1)) AS Float)/ISNULL(tt.SubOperations,1))) as cnt, 
		 	tt.component as compid,tt.operation as opnno from #T_autodata autodata 
			inner join #FinalTarget tt on tt.machineinterface=autodata.mc AND tt.OpnInterface=autodata.opn and tt.Compinterface=autodata.comp  			
			WHERE autodata.DataType=1 and tt.machineinterface>0 
			--AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime) 			
			AND (autodata.ndtime >tt.BatchStart  AND autodata.ndtime <= tt.BatchEnd) 
			 Group by tt.machineid,tt.component ,tt.Operation,tt.SubOperations,tt.BatchStart,tt.BatchEnd
		) as T2 inner join #FinalTarget on T2.machine = #FinalTarget.machineid  and T2.compid=#FinalTarget.Component and   T2.opnno=#FinalTarget.Operation AND T2.BatchStart=#FinalTarget.BatchStart and T2.BatchEnd=#FinalTarget.BatchEnd

		
		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
		Begin

		UPDATE #FinalTarget SET Actual=isnull(actual,0)-isnull(t2.cnt,0) FROM 
		( select tt.machineid as machine,tt.BatchStart,tt.BatchEnd,
			((CAST(Sum(ISNULL(PartsCount,1)) AS Float)/ISNULL(tt.SubOperations,1))) as cnt, 
		 	tt.component as compid,tt.Operation as opnno from #T_autodata autodata --ER0324 Added
			Inner jOIN #PlannedDownTimes T on T.MachineInterface=autodata.mc
			inner join #FinalTarget tt on tt.machineinterface=autodata.mc AND tt.OpnInterface=autodata.opn and tt.Compinterface=autodata.comp  			
			WHERE autodata.DataType=1
			AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime) 			
			AND (autodata.ndtime >tt.BatchStart  AND autodata.ndtime <= tt.BatchEnd)
			 Group by tt.machineid,tt.component ,tt.Operation,tt.SubOperations,tt.BatchStart,tt.BatchEnd
		) as T2 inner join #FinalTarget on T2.machine = #FinalTarget.machineid  and T2.compid=#FinalTarget.Component and   T2.opnno=#FinalTarget.Operation AND T2.BatchStart=#FinalTarget.BatchStart and T2.BatchEnd=#FinalTarget.BatchEnd

		end

		/*Target Calculation*/

		update #FinalTarget set Target= isnull(t2.tcount,0) from
		(
		select F.BatchStart,F.BatchEnd,F.Machineid, CO.componentid as component,CO.Operationno as operation,
		tcount=((F.Runtime*CO.suboperations)/CO.cycletime)*isnull(CO.targetpercent,100) /100
		from componentoperationpricing CO
		inner join #FinalTarget F on co.machineid=F.machineid and CO.Componentid=F.Component and Co.operationno=F.Operation  
		) as T2 Inner Join #FinalTarget on t2.Machineid = #FinalTarget.Machineid and  
		t2.component = #FinalTarget.component and t2.Operation = #FinalTarget.Operation   
		and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

		Insert into #FinalTarget1(MachineID,machineinterface,BatchStart,BatchEnd)
		select distinct T1.MachineID,T1.machineinterface,T2.FromTime,T2.ToTime from #FinalTarget T1
		cross join #Shift2 T2

		/* Planned Down times for the given time period */
		SET @strSql = ''
		SET @strSql = 'Insert into #BatchPlannedDownTimes
		SELECT Machine,InterfaceID,
			CASE When StartTime<T2.BatchStart Then T2.BatchStart Else StartTime End As StartTime,
			CASE When EndTime>T2.BatchEnd Then T2.BatchEnd Else EndTime End As EndTime
		FROM PlannedDownTimes INNER JOIN MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID
		inner join #FinalTarget1 T2 on MachineInformation.InterfaceID=T2.machineinterface
		LEFT OUTER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID 
		LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID 
		and PlantMachineGroups.machineid = PlantMachine.MachineID
		WHERE PDTstatus =1 and(
		(StartTime >= T2.BatchStart AND EndTime <=T2.BatchEnd)
		OR ( StartTime < T2.BatchStart  AND EndTime <= T2.BatchEnd AND EndTime > T2.BatchStart )
		OR ( StartTime >= T2.BatchStart   AND StartTime <T2.BatchEnd AND EndTime > T2.BatchEnd )
		OR ( StartTime < T2.BatchStart  AND EndTime > T2.BatchEnd)) '
		SET @strSql =  @strSql+ @StrGroupID + @StrTPMMachines + ' ORDER BY Machine,StartTime'
		EXEC(@strSql)


		--Get the Machines into #BatchPLD
		SET @strSql = ''
		SET @strSql = 'INSERT INTO #BatchPLD(MachineID,MachineInterface,pPlannedDT,dPlannedDT,StartTime,EndTime)
			SELECT machineinformation.MachineID ,Interfaceid,0  ,0,S2.FromTime,S2.ToTime FROM MachineInformation
				LEFT OUTER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID 
			LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID
			Cross join #shift2 S2
			 WHERE  MachineInformation.interfaceid > ''0'' '
		SET @strSql =  @strSql + @StrTPMMachines + @StrGroupID
		EXEC(@strSql)

		--Type 1


		UPDATE #FinalTarget1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
		from
		(select      mc,BatchStart,Batchend,sum(cycletime+loadunload) as cycle
		from #T_autodata autodata 
		inner join #FinalTarget1 T2 on autodata.Mc=T2.machineinterface
		where (autodata.msttime>=T2.BatchStart)
		and (autodata.ndtime<=T2.BatchEnd)
		and (autodata.datatype=1)
		group by autodata.mc,BatchStart,BatchEnd
		) as t2 inner join #FinalTarget1 on t2.mc = #FinalTarget1.machineinterface and T2.BatchStart=#FinalTarget1.BatchStart and t2.batchend=#FinalTarget1.BatchEnd


		
		-- Type 2
		UPDATE #FinalTarget1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
		from
		(select  mc,BatchStart,SUM(DateDiff(second, BatchStart, ndtime)) cycle
		from #T_autodata autodata --ER0374
		inner join #FinalTarget1 T2 on autodata.Mc=T2.machineinterface
		where (autodata.msttime<T2.BatchStart)
		and (autodata.ndtime>T2.BatchStart)
		and (autodata.ndtime<=T2.BatchEnd)
		and (autodata.datatype=1)
		group by autodata.mc,BatchStart
		) as t2 inner join #FinalTarget1 on t2.mc = #FinalTarget1.machineinterface and T2.BatchStart=#FinalTarget1.BatchStart



		-- Type 3
		UPDATE  #FinalTarget1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
		from
		(select  mc,BatchStart,sum(DateDiff(second, mstTime, BatchEnd)) cycle
		from #T_autodata autodata --ER0374
		inner join #FinalTarget1 T2 on autodata.Mc=T2.machineinterface
		where (autodata.msttime>=T2.BatchStart)
		and (autodata.msttime<T2.BatchEnd)
		and (autodata.ndtime>T2.BatchEnd)
		and (autodata.datatype=1)
		group by autodata.mc,BatchStart
		) as t2 inner join #FinalTarget1 on t2.mc = #FinalTarget1.machineinterface and T2.BatchStart=#FinalTarget1.BatchStart


		-- Type 4
		UPDATE #FinalTarget1 SET UtilisedTime = isnull(UtilisedTime,0) + isnull(t2.cycle,0)
		from
		(select mc,BatchStart,
		sum(DateDiff(second, T2.BatchStart, T2.BatchEnd)) cycle from #T_autodata autodata --ER0374
		inner join #FinalTarget1 T2 on autodata.Mc=T2.machineinterface
		where (autodata.msttime<T2.BatchStart)
		and (autodata.ndtime>T2.BatchEnd)
		and (autodata.datatype=1)
		group by autodata.mc,BatchStart
		)as t2 inner join #FinalTarget1 on t2.mc = #FinalTarget1.machineinterface and T2.BatchStart=#FinalTarget1.BatchStart


		/* Fetching Down Records from Production Cycle  */
		/* If Down Records of TYPE-2*/
		UPDATE  #FinalTarget1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
		FROM
		(Select AutoData.mc ,T2.BatchStart,
		SUM(
		CASE
			When autodata.sttime <= T2.BatchStart Then datediff(s, T2.BatchStart,autodata.ndtime )
			When autodata.sttime > T2.BatchStart Then datediff(s , autodata.sttime,autodata.ndtime)
		END) as Down
		From #T_autodata AutoData 
		inner join #FinalTarget1 T2 on autodata.Mc=T2.machineinterface
		INNER Join --ER0374
			(Select mc,Sttime,NdTime From #T_autodata AutoData
			inner join #FinalTarget1 T2 on autodata.Mc=T2.machineinterface
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(msttime < T2.BatchStart)And (ndtime > T2.BatchStart) AND (ndtime <= T2.BatchEnd)
			) as T1
		ON AutoData.mc=T1.mc
		Where AutoData.DataType=2
		And ( autodata.Sttime > T1.Sttime )
		And ( autodata.ndtime <  T1.ndtime )
		AND ( autodata.ndtime >  T2.BatchStart )
		GROUP BY AUTODATA.mc,T2.BatchStart)AS T2 Inner Join #FinalTarget1 on t2.mc = #FinalTarget1.machineinterface and T2.BatchStart=#FinalTarget1.BatchStart

		/* If Down Records of TYPE-3*/
		UPDATE  #FinalTarget1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
		FROM
		(Select AutoData.mc ,T2.BatchStart,
		SUM(CASE
			When autodata.ndtime > T2.BatchEnd Then datediff(s,autodata.sttime, T2.BatchEnd )
			When autodata.ndtime <=T2.BatchEnd Then datediff(s , autodata.sttime,autodata.ndtime)
		END) as Down 
		From #T_autodata AutoData 
		inner join #FinalTarget1 T2 on autodata.Mc=T2.machineinterface
		INNER Join --ER0374
			(Select mc,Sttime,NdTime From #T_autodata AutoData
			inner join #FinalTarget1 T2 on autodata.Mc=T2.machineinterface
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(sttime >= T2.BatchStart)And (ndtime > T2.BatchEnd) and (sttime<T2.BatchEnd) ) as T1
		ON AutoData.mc=T1.mc
		Where AutoData.DataType=2
		And (T1.Sttime < autodata.sttime  )
		And ( T1.ndtime >  autodata.ndtime)
		AND (autodata.sttime  <  T2.BatchEnd)
		GROUP BY AUTODATA.mc,T2.BatchStart)AS T2 Inner Join #FinalTarget1 on t2.mc = #FinalTarget1.machineinterface and T2.BatchStart=#FinalTarget1.BatchStart

		/* If Down Records of TYPE-4*/
		UPDATE  #FinalTarget1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
		FROM
		(Select AutoData.mc ,T2.BatchStart,
		SUM(CASE

			When autodata.sttime >= T2.BatchStart AND autodata.ndtime <= T2.BatchEnd Then datediff(s , autodata.sttime,autodata.ndtime)
			When autodata.sttime < T2.BatchStart AND autodata.ndtime > T2.BatchStart AND autodata.ndtime<=T2.BatchEnd Then datediff(s, T2.BatchStart,autodata.ndtime )
			When autodata.sttime>=T2.BatchStart And autodata.sttime < T2.BatchEnd AND autodata.ndtime > T2.BatchEnd Then datediff(s,autodata.sttime, T2.BatchEnd )
			When autodata.sttime<T2.BatchStart AND autodata.ndtime>T2.BatchEnd   Then datediff(s , T2.BatchStart,T2.BatchEnd)

		END) as Down
		From #T_autodata AutoData 
		inner join #FinalTarget1 T2 on autodata.Mc=T2.machineinterface
		INNER Join 
			(Select mc,Sttime,NdTime From #T_autodata AutoData
			inner join #FinalTarget1 T2 on autodata.Mc=T2.machineinterface
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(msttime < T2.BatchStart)And (ndtime > T2.BatchEnd) ) as T1
		ON AutoData.mc=T1.mc
		Where AutoData.DataType=2
		And (T1.Sttime < autodata.sttime  )
		And ( T1.ndtime >  autodata.ndtime)
		AND (autodata.ndtime  >  T2.BatchStart)
		AND (autodata.sttime  <  T2.BatchEnd)
		GROUP BY AUTODATA.mc,T2.BatchStart
		)AS T2 Inner Join #FinalTarget1 on t2.mc = #FinalTarget1.machineinterface and T2.BatchStart=#FinalTarget1.BatchStart



		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
		BEGIN

			------------------------------------ ER0374 Added Till Here ---------------------------------
			UPDATE #BatchPLD set pPlannedDT =isnull(pPlannedDT,0) + isNull(TT.PPDT ,0)
			FROM(
				--Production Time in PDT
				SELECT autodata.MC,T2.BatchStart,SUM
					(CASE
					WHEN autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN DateDiff(second,autodata.msttime,autodata.ndtime) 
					WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
					WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )
					WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
					END)  as PPDT
					FROM (select M.machineid,mc,msttime,ndtime from #T_autodata autodata
					inner join #FinalTarget1 T2 on autodata.Mc=T2.machineinterface
						inner join machineinformation M on M.interfaceid=Autodata.mc
						 where autodata.DataType=1 And 
						((autodata.msttime >= T2.BatchStart  AND autodata.ndtime <=T2.BatchEnd)
						OR ( autodata.msttime < T2.BatchStart  AND autodata.ndtime <= T2.BatchEnd AND autodata.ndtime > T2.BatchStart )
						OR ( autodata.msttime >= T2.BatchStart   AND autodata.msttime <T2.BatchEnd AND autodata.ndtime > T2.BatchEnd )
						OR ( autodata.msttime < T2.BatchStart  AND autodata.ndtime > T2.BatchEnd))
						)
				AutoData 
				inner join #FinalTarget1 T2 on autodata.Mc=T2.machineinterface
				inner jOIN #BatchPlannedDownTimes T on T.Machineid=AutoData.machineid
				WHERE 
					(
					(autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
					OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
					OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )
					OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )
				group by autodata.mc,T2.BatchStart
			)
			 as TT INNER JOIN #BatchPLD ON TT.mc = #BatchPLD.MachineInterface and TT.BatchStart=#BatchPLD.StartTime


				--mod 4(4):Handle intearction between ICD and PDT for type 1 production record for the selected time period.
				UPDATE  #BatchPLD set IPlannedDT =isnull(IPlannedDT,0) + isNull(T2.IPDT ,0) 	FROM	(
				Select T1.mc,T2.BatchStart,SUM(
					CASE 	
						When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1
						When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2
						When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3
						when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4
					END) as IPDT from
				(Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype from #T_autodata A
				Where A.DataType=2
				and exists 
					(
					Select B.Sttime,B.NdTime,B.mc From #T_autodata B
					inner join #FinalTarget1 T2 on B.Mc=T2.machineinterface
					Where B.mc = A.mc and
					B.DataType=1 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And
					(B.msttime >= T2.BatchStart AND B.ndtime <= T2.BatchEnd) and
					  (B.sttime <= A.sttime) AND (B.ndtime >= A.ndtime) --DR0339
					)
				 )as T1
				 inner join #FinalTarget1 T2 on T1.Mc=T2.machineinterface
				 inner join
				(select  machine,Case when starttime<T2.BatchStart then T2.BatchStart else starttime end as starttime, 
				case when endtime> T2.BatchEnd then T2.BatchEnd else endtime end as endtime from dbo.PlannedDownTimes 
				inner join #FinalTarget1 T2 on PlannedDownTimes.Machine=T2.MachineID
				where ((( StartTime >=T2.BatchStart) And ( EndTime <=T2.BatchEnd))
				or (StartTime < T2.BatchStart  and  EndTime <= T2.BatchEnd AND EndTime > T2.BatchStart)
				or (StartTime >= T2.BatchStart  AND StartTime <T2.BatchEnd AND EndTime > T2.BatchEnd)
				or (( StartTime <T2.BatchStart) And ( EndTime >T2.BatchEnd )) )
				)T
				on T1.machine=T.machine AND
				((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
				or (T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
				or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
				or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )group by T1.mc,T2.BatchStart
				)AS T2  INNER JOIN #BatchPLD ON T2.mc = #BatchPLD.MachineInterface and T2.BatchStart=#BatchPLD.StartTime
				---mod 4(4)
	
			/* Fetching Down Records from Production Cycle  */
			/* If production  Records of TYPE-2*/
			UPDATE  #BatchPLD set IPlannedDT =isnull(IPlannedDT,0) + isNull(T2.IPDT ,0) 	FROM	(
				Select T1.mc,T2.BatchStart,SUM(
				CASE 	
					When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1
					When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2
					When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3
					when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4
				END) as IPDT from
				(Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype from #T_autodata A
				Where A.DataType=2
				and exists 
				(
				Select B.Sttime,B.NdTime From #T_autodata B
				inner join #FinalTarget1 T2 on B.Mc=T2.machineinterface
				Where B.mc = A.mc and
				B.DataType=1 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And
				(B.msttime < T2.BatchStart And B.ndtime > T2.BatchStart AND B.ndtime <= T2.BatchEnd) 
				And ((A.Sttime > B.Sttime) And ( A.ndtime < B.ndtime) AND ( A.ndtime > T2.BatchStart ))
				)
				)as T1 
				 inner join #FinalTarget1 T2 on T1.Mc=T2.machineinterface
				 inner join
				(select  machine,Case when starttime<T2.BatchStart then T2.BatchStart else starttime end as starttime, 
				case when endtime> T2.BatchEnd then T2.BatchEnd else endtime end as endtime from dbo.PlannedDownTimes 
				inner join #FinalTarget1 T2 on PlannedDownTimes.Machine=T2.MachineID
				where ((( StartTime >=T2.BatchStart) And ( EndTime <=T2.BatchEnd))
				or (StartTime < T2.BatchStart  and  EndTime <= T2.BatchEnd AND EndTime > T2.BatchStart)
				or (StartTime >= T2.BatchStart  AND StartTime <T2.BatchEnd AND EndTime > T2.BatchEnd)
				or (( StartTime <T2.BatchStart) And ( EndTime >T2.BatchEnd )) )
				)T
				on T1.machine=T.machine AND
				(( T.StartTime >= T2.BatchStart ) And ( T.StartTime <  T1.ndtime )) group by T1.mc,T2.BatchStart
			)AS T2  INNER JOIN #BatchPLD ON T2.mc = #BatchPLD.MachineInterface and T2.BatchStart=#BatchPLD.StartTime
	
			/* If production Records of TYPE-3*/
			UPDATE  #BatchPLD set IPlannedDT =isnull(IPlannedDT,0) + isNull(T2.IPDT ,0)FROM (
			Select T1.mc,T2.BatchStart,SUM(
				CASE 	
					When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1
					When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2
					When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3
					when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4
				END) as IPDT from
				(Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype from #T_autodata A
				Where A.DataType=2
				and exists 
				(
				Select B.Sttime,B.NdTime From #T_autodata B
				inner join #FinalTarget1 T2 on B.Mc=T2.machineinterface
				Where B.mc = A.mc and
				B.DataType=1 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And
				(B.sttime >= T2.BatchStart And B.ndtime > T2.BatchEnd and B.sttime <T2.BatchEnd) and
				((B.Sttime < A.sttime  )And ( B.ndtime > A.ndtime) AND (A.msttime < T2.BatchEnd))
				)
				)as T1 
				inner join #FinalTarget1 T2 on T1.Mc=T2.machineinterface
				inner join
				(select  machine,Case when starttime<T2.BatchStart then T2.BatchStart else starttime end as starttime, 
				case when endtime> T2.BatchEnd then T2.BatchEnd else endtime end as endtime from dbo.PlannedDownTimes 
				inner join #FinalTarget1 T2 on PlannedDownTimes.Machine=T2.MachineID
				where ((( StartTime >=T2.BatchStart) And ( EndTime <=T2.BatchEnd))
				or (StartTime < T2.BatchStart  and  EndTime <= T2.BatchEnd AND EndTime > T2.BatchStart)
				or (StartTime >= T2.BatchStart  AND StartTime <T2.BatchEnd AND EndTime > T2.BatchEnd)
				or (( StartTime <T2.BatchStart) And ( EndTime >T2.BatchEnd )) )
				)T
				on T1.machine=T.machine
				AND (( T.EndTime > T1.Sttime )And ( T.EndTime <=T2.BatchEnd )) group by T1.mc,T2.BatchStart
				)AS T2  INNER JOIN #BatchPLD ON T2.mc = #BatchPLD.MachineInterface and T2.BatchStart=#BatchPLD.StartTime
	
	
			/* If production Records of TYPE-4*/
			UPDATE  #BatchPLD set IPlannedDT =isnull(IPlannedDT,0) + isNull(T2.IPDT ,0)FROM (
			Select T1.mc,T2.BatchStart,SUM(
			CASE 	
				When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1
				When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2
				When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3
				when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4
			END) as IPDT from
			(Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype from #T_autodata A
			Where A.DataType=2
			and exists 
			(
			Select B.Sttime,B.NdTime From #T_autodata B
			inner join #FinalTarget1 T2 on B.Mc=T2.machineinterface
			Where B.mc = A.mc and
			B.DataType=1 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And
			(B.msttime < T2.BatchStart And B.ndtime > T2.BatchEnd)
			And ((B.Sttime < A.sttime)And ( B.ndtime >  A.ndtime)AND (A.ndtime  >  T2.BatchStart) AND (A.sttime  <  T2.BatchEnd))
			)
			)as T1 
			inner join #FinalTarget1 T2 on T1.Mc=T2.machineinterface
			inner join
				(select  machine,Case when starttime<T2.BatchStart then T2.BatchStart else starttime end as starttime, 
				case when endtime> T2.BatchEnd then T2.BatchEnd else endtime end as endtime from dbo.PlannedDownTimes 
				inner join #FinalTarget1 T2 on PlannedDownTimes.Machine=T2.MachineID
				where ((( StartTime >=T2.BatchStart) And ( EndTime <=T2.BatchEnd))
				or (StartTime < T2.BatchStart  and  EndTime <= T2.BatchEnd AND EndTime > T2.BatchStart)
				or (StartTime >= T2.BatchStart  AND StartTime <T2.BatchEnd AND EndTime > T2.BatchEnd)
				or (( StartTime <T2.BatchStart) And ( EndTime >T2.BatchEnd )) )
				)T
				on T1.machine=T.machine AND
			(( T.StartTime >=T2.BatchStart) And ( T.EndTime <=T2.BatchEnd )) group by T1.mc,T2.BatchStart
			)AS T2  INNER JOIN #BatchPLD ON T2.mc = #BatchPLD.MachineInterface and T2.BatchStart=#BatchPLD.StartTime
		  ------------------------------------ ER0374 Added Till Here ---------------------------------


		END

		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y')
		BEGIN
				-- Type 1
				UPDATE #FinalTarget1 SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
				from
				(select mc,T2.BatchStart,sum(
				CASE
				WHEN (loadunload) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
				THEN isnull(downcodeinformation.Threshold,0)
				ELSE loadunload 
				END) AS LOSS
				from #T_autodata autodata  
				inner join #FinalTarget1 T2 on autodata.Mc=T2.machineinterface
				INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
				where (autodata.msttime>=T2.BatchStart)
				and (autodata.ndtime<=T2.BatchEnd)
				and (autodata.datatype=2)
				and (downcodeinformation.availeffy = 1) 
				and (downcodeinformation.ThresholdfromCO <>1) 
				group by autodata.mc,T2.BatchStart) as t2 inner join #FinalTarget1 on t2.mc = #FinalTarget1.machineinterface and T2.BatchStart=#FinalTarget1.BatchStart

				-- Type 2
				UPDATE #FinalTarget1 SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
				from
				(select      mc,T2.BatchStart,sum(
				CASE WHEN DateDiff(second, @StartTime, ndtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
				then isnull(downcodeinformation.Threshold,0)
				ELSE DateDiff(second, @StartTime, ndtime)
				END)loss
				from #T_autodata autodata  
				inner join #FinalTarget1 T2 on autodata.Mc=T2.machineinterface
				INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
				where (autodata.sttime<T2.BatchStart)
				and (autodata.ndtime>T2.BatchStart)
				and (autodata.ndtime<=T2.BatchEnd)
				and (autodata.datatype=2)
				and (downcodeinformation.availeffy = 1)
				and (downcodeinformation.ThresholdfromCO <>1) 
				group by autodata.mc,T2.BatchStart
				) as t2 inner join #FinalTarget1 on t2.mc = #FinalTarget1.machineinterface and T2.BatchStart=#FinalTarget1.BatchStart

				-- Type 3
				UPDATE #FinalTarget1 SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
				from
				(select      mc,T2.BatchStart,SUM(
				CASE WHEN DateDiff(second,stTime, @Endtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
				then isnull(downcodeinformation.Threshold,0)
				ELSE DateDiff(second, stTime, @Endtime)
				END)loss
				from #T_autodata autodata 
				inner join #FinalTarget1 T2 on autodata.Mc=T2.machineinterface
				INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
				where (autodata.msttime>=T2.BatchStart)
				and (autodata.sttime<T2.BatchEnd)
				and (autodata.ndtime>T2.BatchEnd)
				and (autodata.datatype=2)
				and (downcodeinformation.availeffy = 1)
				and (downcodeinformation.ThresholdfromCO <>1) 
				group by autodata.mc,T2.BatchStart
				) as t2 inner join #FinalTarget1 on t2.mc = #FinalTarget1.machineinterface and T2.BatchStart=#FinalTarget1.BatchStart
		
				UPDATE #FinalTarget1 SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
				from
				(select mc,T2.BatchStart,sum(
				CASE WHEN DateDiff(second, T2.BatchStart, T2.BatchEnd) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
				then isnull(downcodeinformation.Threshold,0)
				ELSE DateDiff(second, T2.BatchStart, T2.BatchEnd)
				END)loss
				from #T_autodata autodata 
				inner join #FinalTarget1 T2 on autodata.Mc=T2.machineinterface
				INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
				where autodata.msttime<T2.BatchStart
				and autodata.ndtime>T2.BatchEnd
				and (autodata.datatype=2)
				and (downcodeinformation.availeffy = 1)
				and (downcodeinformation.ThresholdfromCO <>1)
				group by autodata.mc,T2.BatchStart
				) as t2 inner join #FinalTarget1 on t2.mc = #FinalTarget1.machineinterface and T2.BatchStart=#FinalTarget1.BatchStart

				---get the downtime for the time period
				UPDATE #FinalTarget1 SET downtime = isnull(downtime,0) + isNull(t2.down,0)
				from
				(select mc,T2.BatchStart,sum(
						CASE
						WHEN  autodata.msttime>=T2.BatchStart  and  autodata.ndtime<=T2.BatchEnd  THEN  loadunload
						WHEN (autodata.sttime<T2.BatchStart and  autodata.ndtime>T2.BatchStart and autodata.ndtime<=T2.BatchEnd)  THEN DateDiff(second, T2.BatchStart, ndtime)
						WHEN (autodata.msttime>=T2.BatchStart  and autodata.sttime<T2.BatchEnd  and autodata.ndtime>T2.BatchEnd)  THEN DateDiff(second, stTime, T2.BatchEnd)
						WHEN autodata.msttime<T2.BatchStart and autodata.ndtime>T2.BatchEnd   THEN DateDiff(second, T2.BatchStart, T2.BatchEnd)
						END
					)AS down
				from #T_autodata autodata 
				inner join #FinalTarget1 T2 on autodata.Mc=T2.machineinterface
				inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
				where autodata.datatype=2 AND
				(
				(autodata.msttime>=T2.BatchStart  and  autodata.ndtime<=T2.BatchEnd)
				OR (autodata.sttime<T2.BatchStart and  autodata.ndtime>T2.BatchStart and autodata.ndtime<=T2.BatchEnd)
				OR (autodata.msttime>=T2.BatchStart  and autodata.sttime<T2.BatchEnd  and autodata.ndtime>T2.BatchEnd)
				OR (autodata.msttime<T2.BatchStart and autodata.ndtime>T2.BatchEnd )
				)
				group by autodata.mc,T2.BatchStart
				) as t2 inner join #FinalTarget1 on t2.mc = #FinalTarget1.machineinterface and T2.BatchStart=#FinalTarget1.BatchStart
		--mod 4
		End

		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
		BEGIN
			---step 1
	
			UPDATE #FinalTarget1 SET downtime = isnull(downtime,0) + isNull(t2.down,0)
			from
			(select mc,T2.BatchStart,sum(
					CASE
					WHEN  autodata.msttime>=T2.BatchStart  and  autodata.ndtime<=T2.BatchEnd  THEN  loadunload
					WHEN (autodata.sttime<T2.BatchStart and  autodata.ndtime>T2.BatchStart and autodata.ndtime<=T2.BatchEnd)  THEN DateDiff(second, T2.BatchStart, ndtime)
					WHEN (autodata.msttime>=T2.BatchStart  and autodata.sttime<T2.BatchEnd  and autodata.ndtime>T2.BatchEnd)  THEN DateDiff(second, stTime, T2.BatchEnd)
					WHEN autodata.msttime<T2.BatchStart and autodata.ndtime>T2.BatchEnd   THEN DateDiff(second, T2.BatchStart, T2.BatchEnd)
					END
				)AS down
			from #T_autodata autodata
			inner join #FinalTarget1 T2 on autodata.Mc=T2.machineinterface
			inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
			where autodata.datatype=2 AND
			(
			(autodata.msttime>=T2.BatchStart  and  autodata.ndtime<=T2.BatchEnd)
			OR (autodata.sttime<T2.BatchStart and  autodata.ndtime>T2.BatchStart and autodata.ndtime<=T2.BatchEnd)
			OR (autodata.msttime>=T2.BatchStart  and autodata.sttime<T2.BatchEnd  and autodata.ndtime>T2.BatchEnd)
			OR (autodata.msttime<T2.BatchStart and autodata.ndtime>T2.BatchEnd )
			) AND (downcodeinformation.availeffy = 0)
			group by autodata.mc,T2.BatchStart
			) as t2 inner join #FinalTarget1 on t2.mc = #FinalTarget1.machineinterface and T2.BatchStart=#FinalTarget1.BatchStart


			---step 2
			---mod 4 checking for (downcodeinformation.availeffy = 0) to get the overlapping PDT and Downs which is not ML
			UPDATE #BatchPLD set dPlannedDT =isnull(dPlannedDT,0) + isNull(TT.PPDT ,0)
			FROM(
				--Production PDT
				SELECT autodata.MC,T2.BatchStart, SUM
				   (CASE
					WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
					WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
					WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
					WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
					END ) as PPDT
				FROM #T_autodata AutoData
				inner join #FinalTarget1 T2 on autodata.Mc=T2.machineinterface
				CROSS jOIN #BatchPlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
				WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
					(
					(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
					OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
					OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
					OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
					)
					 AND (downcodeinformation.availeffy = 0)
				group by autodata.mc,T2.BatchStart
			) as TT INNER JOIN #BatchPLD ON TT.mc = #BatchPLD.MachineInterface and TT.BatchStart=#BatchPLD.StartTime
	
			UPDATE #FinalTarget1 SET  ManagementLoss = isnull(ManagementLoss,0) + isNull(t4.Mloss,0),MLDown=isNull(MLDown,0)+isNull(t4.Dloss,0)
			from
			(select T3.mc,T3.BatchStart,sum(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss from (
			select   t1.id,T1.mc,T6.BatchStart,T1.Threshold,
			case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0
			then DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)- isnull(T1.Threshold ,0)
			else 0 End  as Dloss,
			case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0
			then isnull(T1.Threshold,0)
			else (DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)) End  as Mloss
			 from
	
			(   select id,mc,comp,opn,opr,D.threshold,
				case when autodata.sttime<T6.BatchStart then T6.BatchStart else sttime END as sttime,
	       			case when ndtime>T6.BatchEnd then T6.BatchEnd else ndtime END as ndtime
				from #T_autodata autodata --ER0374
				inner join #FinalTarget1 T6 on autodata.Mc=T6.machineinterface
				inner join downcodeinformation D
				on autodata.dcode=D.interfaceid where autodata.datatype=2 AND
				(
				(autodata.sttime>=T6.BatchStart  and  autodata.ndtime<=T6.BatchEnd)
				OR (autodata.sttime<T6.BatchStart and  autodata.ndtime>T6.BatchStart and autodata.ndtime<=T6.BatchEnd)
				OR (autodata.sttime>=T6.BatchStart  and autodata.sttime<T6.BatchEnd  and autodata.ndtime>T6.BatchEnd)
				OR (autodata.sttime<T6.BatchStart and autodata.ndtime>T6.BatchEnd )
				) AND (D.availeffy = 1) 		
				and (D.ThresholdfromCO <>1)) as T1 	
				inner join #FinalTarget1 T6 on T1.Mc=T6.machineinterface
			left outer join
			(SELECT autodata.id,
					   sum(CASE
					WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
					WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
					WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
					WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
					END ) as PPDT
				FROM #T_autodata AutoData 
				inner join #FinalTarget1 T6 on autodata.Mc=T6.machineinterface
				CROSS jOIN #BatchPlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
				WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
					(
					(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
					OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
					OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
					OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
					)
					AND (downcodeinformation.availeffy = 1) 
					AND (downcodeinformation.ThresholdfromCO <>1) --NR0097 
					group  by autodata.id ) as T2 on T1.id=T2.id ) as T3  group by T3.mc,T3.BatchStart
			) as t4 inner join #FinalTarget1 on t4.mc = #FinalTarget1.machineinterface and T4.BatchStart=#FinalTarget1.BatchStart


			---mod 4 checking for (downcodeinformation.availeffy = 1) to get the overlapping PDT and Downs which is ML
			UPDATE #BatchPLD set MPlannedDT =isnull(MPlannedDT,0) + isNull(TT.PPDT ,0)
			FROM(
				--Production PDT
				SELECT autodata.MC,T2.BatchStart, SUM
				   (CASE
					WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
					WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
					WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
					WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
					END ) as PPDT
				FROM #T_autodata AutoData --ER0374
				inner join #FinalTarget1 T2 on autodata.Mc=T2.machineinterface
				CROSS jOIN #BatchPlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
				WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
					(
					(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
					OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
					OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
					OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
					)
					 AND (downcodeinformation.availeffy = 1) 
					AND (downcodeinformation.ThresholdfromCO <>1) --NR0097 
				group by autodata.mc,T2.BatchStart
			) as TT INNER JOIN #BatchPLD ON TT.mc = #BatchPLD.MachineInterface and TT.BatchStart=#BatchPLD.StartTime

			UPDATE #FinalTarget1 SET downtime = isnull(downtime,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)
	
		END

		
		UPDATE #FinalTarget1 SET CN = isnull(CN,0) + isNull(t2.C1N1,0)
		from
		(select mc,T2.BatchStart,
		SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))* autodata.partscount) C1N1
		FROM #T_autodata autodata 
		inner join #FinalTarget1 T2 on autodata.Mc=T2.machineinterface
		INNER JOIN
		componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
		componentinformation ON autodata.comp = componentinformation.InterfaceID AND
		componentoperationpricing.componentid = componentinformation.componentid
		inner join machineinformation on machineinformation.interfaceid=autodata.mc
		and componentoperationpricing.machineid=machineinformation.machineid
		where (((autodata.sttime>=T2.BatchStart)and (autodata.ndtime<=T2.BatchEnd)) or
		((autodata.sttime<T2.BatchStart)and (autodata.ndtime>T2.BatchStart)and (autodata.ndtime<=T2.BatchEnd)) )
		and (autodata.datatype=1)
		group by autodata.mc,T2.BatchStart
		) as t2 inner join #FinalTarget1 on t2.mc = #FinalTarget1.machineinterface and T2.BatchStart=#FinalTarget1.BatchStart

		-- mod 4 Ignore count from CN calculation which is over lapping with PDT
		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
		BEGIN
			UPDATE #FinalTarget1 SET CN = isnull(CN,0) - isNull(t2.C1N1,0)
			From
			(
				select mc,T2.BatchStart,SUM((O.cycletime * ISNULL(A.PartsCount,1))/ISNULL(O.SubOperations,1))  C1N1
				From #T_autodata A 
				inner join #FinalTarget1 T2 on A.Mc=T2.machineinterface
				Inner join machineinformation M on M.interfaceid=A.mc
				Inner join componentinformation C ON A.Comp=C.interfaceid
				Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID
				Cross jOIN #BatchPlannedDownTimes T
				WHERE A.DataType=1 AND T.MachineInterface=A.mc
				AND(A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)
				AND(A.ndtime > T2.BatchStart  AND A.ndtime <=T2.BatchEnd)
				Group by mc,T2.BatchStart
			) as T2
			inner join #FinalTarget1  on t2.mc = #FinalTarget1.machineinterface and T2.BatchStart=#FinalTarget1.BatchStart
		END

		UPDATE #FinalTarget1 SET components = ISNULL(components,0) + ISNULL(t2.comp,0)
		From
		(
			  Select mc,T1.BatchStart,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp 
				   From (select mc,T2.BatchStart,SUM(autodata.partscount)AS OrginalCount,comp,opn 
					from #T_autodata autodata --ER0374
					inner join #FinalTarget1 T2 on autodata.Mc=T2.machineinterface
				   where (autodata.ndtime>T2.BatchStart) and (autodata.ndtime<=T2.BatchEnd) and (autodata.datatype=1)
				   Group By mc,T2.BatchStart,comp,opn) as T1
			Inner join componentinformation C on T1.Comp = C.interfaceid
			Inner join ComponentOperationPricing O ON  T1.Opn = O.interfaceid and C.Componentid=O.componentid
			---mod 2
			inner join machineinformation on machineinformation.machineid =O.machineid
			and T1.mc=machineinformation.interfaceid
			---mod 2
			GROUP BY mc,T1.BatchStart
		) As T2 Inner join #FinalTarget1 on T2.mc = #FinalTarget1.machineinterface and T2.BatchStart=#FinalTarget1.BatchStart


		--Mod 4 Apply PDT for calculation of Count
		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
		BEGIN
			UPDATE #FinalTarget1 SET components = ISNULL(components,0) - ISNULL(T2.comp,0) from(
				select mc,T1.BatchStart,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp From ( 
					select mc,T2.BatchStart,Sum(ISNULL(PartsCount,1))AS OrginalCount,comp,opn 
					from #T_autodata autodata 
					inner join #FinalTarget1 T2 on autodata.Mc=T2.machineinterface
					CROSS JOIN #BatchPlannedDownTimes T
					WHERE autodata.DataType=1 And T.MachineInterface = autodata.mc
					AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)
					AND (autodata.ndtime > @StartTime  AND autodata.ndtime <=@EndTime)
					Group by mc,T2.BatchStart,comp,opn
				) as T1
			Inner join Machineinformation M on M.interfaceID = T1.mc
			Inner join componentinformation C on T1.Comp=C.interfaceid
			Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineID = M.MachineID
			GROUP BY MC,T1.BatchStart
			) as T2 inner join #FinalTarget1 on T2.mc = #FinalTarget1.machineinterface and T2.BatchStart=#FinalTarget1.BatchStart
		END

		UPDATE #FinalTarget1
			SET UtilisedTime=(UtilisedTime-ISNULL(#BatchPLD.pPlannedDT,0)+isnull(#BatchPLD.IPlannedDT,0)),
			   DownTime=(DownTime-ISNULL(#BatchPLD.dPlannedDT,0)) 
			From #FinalTarget1 Inner Join #BatchPLD on #BatchPLD.Machineid=#FinalTarget1.Machineid and #BatchPLD.StartTime=#FinalTarget1.BatchStart
		---mod 4

		UPDATE #FinalTarget1
		SET
			ProductionEfficiency = (CN/UtilisedTime) ,
			AvailabilityEfficiency = (UtilisedTime)/(UtilisedTime + isnull(DownTime,0) - isnull(ManagementLoss,0))
		WHERE UtilisedTime <> 0	



		Update #FinalTarget1 set RejCount = isnull(RejCount,0) + isnull(T1.RejQty,0)
		From
		( Select A.mc,T2.BatchStart,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A
		inner join #FinalTarget1 T2 on A.Mc=T2.machineinterface
		inner join Machineinformation M on A.mc=M.interfaceid
		inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
		where A.CreatedTS>=T2.BatchStart and A.CreatedTS<T2.BatchEnd and A.flag = 'Rejection'
		and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000'
		group by A.mc,M.Machineid,T2.BatchStart
		)T1 inner join #FinalTarget1 B on B.Machineid=T1.Machineid and T1.BatchStart=B.BatchStart



		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
		BEGIN
			Update #FinalTarget1 set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from
			(Select A.mc,T2.BatchStart,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A
			inner join Machineinformation M on A.mc=M.interfaceid
			inner join #FinalTarget1 T2 on A.Mc=T2.machineinterface
			inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
			Cross join Planneddowntimes P
			where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid 
			and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000' and
			A.CreatedTS>=T2.BatchStart and A.CreatedTS<T2.BatchEnd And
			A.CreatedTS>=P.Starttime and A.CreatedTS<P.endtime
			group by A.mc,M.Machineid,T2.BatchStart)T1 inner join #FinalTarget1 B on B.Machineid=T1.Machineid and T1.BatchStart=B.BatchStart
		END

		Update #FinalTarget1 set RejCount = isnull(RejCount,0) + isnull(T1.RejQty,0)
		From
		( Select A.mc,T2.BatchStart,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A
		inner join Machineinformation M on A.mc=M.interfaceid
		inner join #FinalTarget1 T2 on A.Mc=T2.machineinterface
		inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
		where A.flag = 'Rejection'   --DR0333
		and (A.RejDate between T2.BatchStart and T2.BatchEnd) and
		Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
		group by A.mc,M.Machineid,T2.BatchStart
		)T1 inner join #FinalTarget1 B on B.Machineid=T1.Machineid  and T1.BatchStart=B.BatchStart



		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
		BEGIN
			Update #FinalTarget1 set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from
			(Select A.mc,T2.BatchStart,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A
			inner join Machineinformation M on A.mc=M.interfaceid
			inner join #FinalTarget1 T2 on A.Mc=T2.machineinterface
			inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
			Cross join Planneddowntimes P
			where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid
			and (A.RejDate between T2.BatchStart and T2.BatchEnd) and
			Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
			and P.starttime>=T2.BatchStart and P.Endtime<=T2.BatchEnd
			group by A.mc,M.Machineid,T2.BatchStart)T1 inner join #FinalTarget1 B on B.Machineid=T1.Machineid  and T1.BatchStart=B.BatchStart
		END

		UPDATE #FinalTarget1 SET QualityEfficiency= ISNULL(QualityEfficiency,0) + IsNull(T1.QE,1) 
		FROM(Select MachineID,BatchStart,
		CAST((Sum(Components))As Float)/CAST((Sum(IsNull(Components,0))+Sum(IsNull(RejCount,0))) AS Float)As QE
		From #FinalTarget1 Where Components<>0 Group By MachineID,BatchStart
		)AS T1 Inner Join #FinalTarget1 ON  #FinalTarget1.MachineID=T1.MachineID and T1.BatchStart=#FinalTarget1.BatchStart

		UPDATE #FinalTarget1
		SET
			OverAllEfficiency = (ProductionEfficiency * AvailabilityEfficiency * ISNULL(QualityEfficiency,1))*100,
			ProductionEfficiency = ProductionEfficiency * 100 ,
			AvailabilityEfficiency = AvailabilityEfficiency * 100,
			QualityEfficiency = QualityEfficiency*100

		Update #FinalTarget set OverAllEfficiency=isnull(T1.OverAllEfficiency,0)
		from(
		select distinct MachineID,OverAllEfficiency from #FinalTarget1
		)T1 inner join #FinalTarget T2 on T1.MachineID=T2.MachineID


	If @param='MachineWise'
	Begin


	Select @strsql=''  
	Select @strsql = '  
	SELECT 
	C.MachineID,  
	''' + Convert(nvarchar(20),@StartTime,120) + ''' as StartTime, 
	ROUND(C.AvailabilityEfficiency,0) as AvailabilityEfficiency,  
	ROUND(C.ProductionEfficiency,0) as ProductionEfficiency,  
	ROUND(C.QualityEfficiency,0) as QualityEfficiency,   
	ROUND(C.OverAllEfficiency,0) as OverAllEfficiency,  
	Round(C.Components,2) as Components,   
	C.RejCount,  
	C.CN,C.Target
	FROM #CockpitData C Inner Join #PLD on #PLD.Machineid=C.Machineid  '
	Select @strSql = @strSql + @Strsortorder
	print(@strsql)
	exec(@strsql)

	Select A1.MachineID,A2.machineinterface,A2.Component,A2.Operation,A2.BatchStart,A2.BatchEnd,ISNULL(A2.Actual,0) as Actual,ISNULL(A2.Target,0) as Target ,ROUND(isnull(A2.OverAllEfficiency,0),0) as OverAllEfficiency
	from #CockPitData A1
	left join #FinalTarget A2 on A1.MachineID=A2.MachineID

	--select MachineID,machineinterface,Component,Operation,BatchStart,BatchEnd,Actual,Target from #FinalTarget 
 
end
end

 
