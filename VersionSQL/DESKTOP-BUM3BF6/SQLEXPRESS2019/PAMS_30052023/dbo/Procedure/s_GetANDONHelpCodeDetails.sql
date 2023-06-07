/****** Object:  Procedure [dbo].[s_GetANDONHelpCodeDetails]    Committed by VersionSQL https://www.versionsql.com ******/

/***************************************      History     *******************************************
NR0095 - SwathiKS - 20/Nov/2013 :: Created New Procedure for Wipro ANDON Display for Current Day -> Current Shift. i.e Shiftstart to Current time.

1st Screen : To Show Machinewise Running Status, HelpCode Raised, AE, PE, QE, Planned and Actual Count, Top 3 Leading and Lagging Machines based on OE.
Proc Inputs Required For 1st screen: i.e FROM SHIFTSTART TO CURR. TIME
[dbo].[s_GetANDONHelpCodeDetails] '2013-11-22 06:30:00 AM','2013-11-22 03:00:00 PM','','','Win Chennai - LCC','1st Screen'
[dbo].[s_GetANDONHelpCodeDetails] '2013-11-22 06:30:00 AM','2013-11-22 03:00:00 PM','','','Win Chennai - LCC','1st ScreenOEE'

2nd Screen : To Show Machinewise Running Status, HelpCode Raised, AE, PE, QE. Hourwise Planned and actual Count for each Machine for each Plant.
Proc Inputs Required For 2nd screen: i.e FROM SHIFTSTART TO CURR. TIME
[dbo].[s_GetANDONHelpCodeDetails] '2013-11-22 06:30:00 AM','2013-11-22 03:00:00 PM','','','Win Chennai - SCP','2nd Screen'

3rd Screen : To Show Machinewise Running Status, HelpCode Raised. Plantwise Downcode v/s Downtime Pareto and Plantwise OEE at Month Level.
Proc Inputs Required For 3rd screen LEFT PART: i.e FROM SHIFTSTART TO CURR. TIME
[dbo].[s_GetANDONHelpCodeDetails] '2013-11-22 06:30:00 AM','2013-11-22 03:00:00 PM','','','','3rd Screen'

Proc Inputs Required For 3rd screen LEFT PART: i.e FROM MONTH START TO CURR. TIME
[dbo].[s_GetANDONHelpCodeDetails] '2013-11-22 06:30:00 AM','2013-11-22 03:00:00 PM','','','','3rd Screen PlantOEE' 

Proc Inputs Required For 3rd screen LEFT PART: i.e FROM MONTH START TO CURR. TIME
[dbo].[s_GetANDONHelpCodeDetails] '2013-11-22 06:30:00 AM','2013-11-22 03:00:00 PM','','','','3rd Screen DownPareto'

To Show RunningCOO
[dbo].[s_GetANDONHelpCodeDetails] '','','','','','RunningCO'

ER0377 - 01/Mar/2014 - SwathiKS   :: Performace Optimization.
a> Index on #PlannedDownTimes Table.
b> Logic change while handling ICD-PDT Interaction as per cockpit.
c> Removed temp table concept for Month wise Plant Level OEE.
d> Retained Temp table concept for Small period i.e. current day – current Shift in Wipro.
e> Introduced WITH(NOLOCK) in Select queries.
f> Introduced SET NOCOUNT to prevent extra result sets from interfering with SELECT statements.
g> Index on Helpcodedetails table.
h> Optimize parameter usage to select only required information and not all.
i> In 2nd Screen, show cumulative hours data. (i.e. 1+2,3+4,5+6,7+8,9)

exec s_GetAndonHelpcodeDetails @StartTime=N'2021-10-05 07:01:00',@EndTime=N'2021-10-06 07:01:00',@SHIFTNAME=N'',@MachineID=N'',@PlantID=N'AAAPL',@Param=N'3rd Screen PlantOEEShiftwise'

exec s_GetAndonHelpcodeDetails @StartTime=N'2021-10-10 07:01:00',@EndTime=N'2021-10-10 15:01:00',@SHIFTNAME=N'',@MachineID=N'',@PlantID=N'AAAPL',@Param=N'3rd Screen PlantOEEShiftwise'

****************************************************************************************************/
--[dbo].[s_GetANDONHelpCodeDetails] '2019-03-03 06:00:00 AM','2019-03-04 06:00:00 AM','','','','1st Screen'
--[dbo].[s_GetANDONHelpCodeDetails] '2019-03-03 06:00:00 AM','2019-03-04 06:00:00 AM','','VMC-01','','2nd Screen'
--[dbo].[s_GetANDONHelpCodeDetails] '2019-03-03 06:00:00 AM','2019-03-04 06:00:00 AM','','','','3rd Screen'
--[dbo].[s_GetANDONHelpCodeDetails] '2019-03-03 06:00:00 AM','2019-03-04 06:00:00 AM','','','','3rd Screen PlantOEE'
--[dbo].[s_GetANDONHelpCodeDetails] '2019-03-03 06:00:00 AM','2019-03-04 06:00:00 AM','','','','3rd Screen DownPareto'
--[dbo].[s_GetANDONHelpCodeDetails] '2019-03-01 06:00:00 AM','2019-03-02 02:00:00 PM','','VMC-01','','RunningCO'
--[dbo].[s_GetANDONHelpCodeDetails] '2019-03-03 06:00:00 AM','2019-03-04 02:00:00 PM','','','','3rd Screen PlantOEEShiftwise'
--[dbo].[s_GetANDONHelpCodeDetails] '2019-03-03 06:00:00 AM','2019-03-03 02:00:00 PM','','','','3rd Screen DownParetoShiftwise'

CREATE                 PROCEDURE [dbo].[s_GetANDONHelpCodeDetails]
	@StartTime datetime output,
	@EndTime datetime output,
	@SHIFTNAME nvarchar(50),
	@MachineID nvarchar(50) = '',
	@PlantID nvarchar(50)='',
	@Param nvarchar(50)=''

WITH RECOMPILE
AS
BEGIN

SET NOCOUNT ON; --ER0377

Declare @strPlantID as nvarchar(255)
Declare @strSql as nvarchar(4000)
Declare @strMachine as nvarchar(255)
declare @timeformat as nvarchar(2000)
Declare @StrTPMMachines AS nvarchar(500)	
SELECT @StrTPMMachines=''				
SELECT @strMachine = ''
SELECT @strPlantID = ''
SELECT @timeformat ='ss'

Select @timeformat = isnull((select valueintext from cockpitdefaults where parameter='timeformat'),'ss')
if (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')
begin
	select @timeformat = 'ss'
end

CREATE TABLE #CockPitData 
(
	Plantid nvarchar(50),
	MachineID nvarchar(50),
	MachineInterface nvarchar(50) PRIMARY KEY,
	ProductionEfficiency float,
	AvailabilityEfficiency float,
	OverallEfficiency float,
	Components float,
	Target float,
	TotalTime float,
	UtilisedTime float,
	ManagementLoss float,
	DownTime float,
	CN float,
	PEGreen smallint,
	PERed smallint,
	AEGreen smallint,
	AERed smallint,
	OEGreen smallint,
	OERed smallint,
	MaxDownReason nvarchar(50) DEFAULT (''),
	MaxDowntime float ,
	MLDown float,
	Operatorid nvarchar(50),
	HelpCode1 nvarchar(10),
	HelpCode2 nvarchar(10),
	HelpCode3 nvarchar(10),
	HelpCode4 nvarchar(10),
	HelpCode1TS nvarchar(10),
	HelpCode2TS nvarchar(10),
	HelpCode3TS nvarchar(10),
	HelpCode4TS nvarchar(10),
	ColorCode nvarchar(50)
)

CREATE TABLE #PLD
(
	MachineID nvarchar(50),
	MachineInterface nvarchar(50),
	pPlannedDT float Default 0,
	dPlannedDT float Default 0,
	MPlannedDT float Default 0,
	IPlannedDT float Default 0,
	DownID nvarchar(50)
)
Create table #PlannedDownTimes
(
	MachineID nvarchar(50) NOT NULL, --ER0377
	MachineInterface nvarchar(50) NOT NULL, --ER0377
	StartTime DateTime NOT NULL, --ER0377
	EndTime DateTime NOT NULL, --ER0377
)
--mod 4

--ER0377 From here
ALTER TABLE #PlannedDownTimes
	ADD PRIMARY KEY CLUSTERED
		(   [MachineInterface],
			[StartTime],
			[EndTime]
						
		) ON [PRIMARY]

--ER0377 Till Here

create table #Runningpart_Part
(  
 Machineid nvarchar(50),  
 Operatorid nvarchar(50),
 StTime Datetime 
)  

create table #HelpCode
(
	Machineid nvarchar(50), 
	HelpDescription nvarchar(50), 
	HelpCode nvarchar(50),
	Action1 nvarchar(10),
	Action2 nvarchar(10),
	Starttime Datetime,
	Endtime Datetime
)

CREATE TABLE #MachineRunningStatus
(
	MachineID NvarChar(50),
	MachineInterface nvarchar(50),
	sttime Datetime,
	ndtime Datetime,
	DataType smallint,
	ColorCode varchar(10),
	DownTime Int,
	lastDownstart datetime,
	PDT int
)

Create table #HourlyData1
	(
		 Machineid nvarchar(50),  
		 FromTime datetime,  
		 ToTime Datetime,  
		 Actual float,  
		 Target float Default 0,
		 ActualTotal float Default 0,
		 TargetTotal float Default 0
	)

Create table #HourlyData
	(
		 Machineid nvarchar(50),  
		 FromTime datetime,  
		 ToTime Datetime,  
		 Actual float,  
		 Target float Default 0,
		 ActualTotal float Default 0,
		 TargetTotal float Default 0
	)

	Create Table #ShiftTemp  
	 (  
	  PDate datetime,  
	  ShiftName nvarchar(20),  
	  FromTime datetime,  
	  ToTime Datetime,  
	 ) 

	CREATE TABLE #Target  
	(

		MachineID nvarchar(50) NOT NULL,
		machineinterface nvarchar(50),
		Compinterface nvarchar(50),
		OpnInterface nvarchar(50),
		Component nvarchar(50) NOT NULL,
		Operation nvarchar(50) NOT NULL,
		msttime datetime,
		ndtime datetime,
		FromTm datetime,
		ToTm datetime,   
		runtime int,   
		Targetpercent float,
		batchid int,
		autodataid bigint,
		Suboperation int,
		StdCycletime float
	)

	CREATE TABLE #FinalTarget  
	(

		MachineID nvarchar(50) NOT NULL,
		Component nvarchar(50) NOT NULL,
		Operation nvarchar(50) NOT NULL,
		machineinterface nvarchar(50),
		Compinterface nvarchar(50),
		OpnInterface nvarchar(50),
		msttime datetime,
		ndtime datetime,
		FromTm datetime,
		ToTm datetime,   
		runtime int,   
		Targetpercent float,
		batchid int,
		Suboperation int,
		StdCycletime float,
		Target float Default 0
	)

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

CREATE TABLE #DownTimeData
(
	MachineID nvarchar(50) NOT NULL,
	McInterfaceid nvarchar(4),
	DownID nvarchar(50) NOT NULL,
	DownTime float,
	DownFreq int
)

ALTER TABLE #DownTimeData
	ADD PRIMARY KEY CLUSTERED
	(
		[MachineId], [DownID]
	)ON [PRIMARY]


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

IF ( SELECT TOP 1 ValueInText FROM  CockpitDefaults WHERE Parameter='TpmEnbMac')='E'
BEGIN
	SET  @StrTPMMachines = 'AND MachineInformation.TPMTrakEnabled = 1'
END
ELSE
BEGIN
	SET  @StrTPMMachines = ' '
END

if isnull(@machineid,'')<> ''
begin
	SET @strMachine = ' AND MachineInformation.MachineID = N''' + @machineid + ''''
end

if isnull(@PlantID,'')<> ''
Begin
	SET @strPlantID = ' AND PlantMachine.PlantID = N''' + @PlantID + ''''
End

Declare @T_ST AS Datetime 
Declare @T_ED AS Datetime
Declare @CurrTime as DateTime
Declare @Enddate as datetime

SET @Enddate = @Endtime
SET @CurrTime = convert(nvarchar(20),getdate(),120)
print @CurrTime

IF @Endtime > @CurrTime  
BEGIN  
	SET @Endtime = @CurrTime
End  

If @Param='RunningCO'
BEgin
	  select Top 1 CO.Componentid,CO.Operationno,E.Employeeid,E.Name as EmployeeName from Autodata A  
	  inner join Machineinformation on A.mc=Machineinformation.interfaceid  
	  inner join Componentinformation C on A.comp=C.interfaceid  
	  inner join Componentoperationpricing CO on A.opn=CO.interfaceid  
	  and Machineinformation.Machineid=CO.Machineid and C.Componentid=CO.Componentid  
	  Left Outer join employeeinformation E on A.opr=E.interfaceid
	  Where machineinformation.machineid=@MachineID and (sttime>=@StartTime and ndtime<=@EndTime) Order by sttime desc
Return;
END

IF @Param='3rd Screen PlantOEEShiftwise' OR  @param= '3rd Screen DownParetoShiftwise'
Begin
	Select @StartTime=@StartTime	
END

If @Param='3rd Screen PlantOEE' OR  @param= '3rd Screen DownPareto'  
BEGIN
	Select @StartTime = [dbo].[f_GetLogicalMonth](@starttime,'Start')
END

Declare @T_Start AS Datetime 
Declare @T_End AS Datetime
Select @T_Start=dbo.f_GetLogicalDay(@starttime,'start')
Select @T_End=dbo.f_GetLogicalDay(@Endtime,'End')

IF @param = '1st screen' OR @Param='1st screenOEE' OR @Param='2nd Screen' OR @param= '3rd Screen DownPareto' or @param='3rd Screen DownParetoShiftwise' --ER0377 Added
or @param='3rd Screen PlantOEE' or @Param='3rd Screen PlantOEEShiftwise'
Begin --ER0377 Added

Select @strsql=''
select @strsql ='insert into #T_autodata '
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'
 select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'
select @strsql = @strsql + ' from autodata WITH (NOLOCK) where (( sttime >='''+ convert(nvarchar(25),@T_Start,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_End,120)+''' ) OR ' ----ER0377 Added LOCK
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_Start,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_End,120)+''' )OR '
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_Start,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_Start,120)+'''
				 and ndtime<='''+convert(nvarchar(25),@T_End,120)+''' )'
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_Start,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_End,120)+''' and sttime<'''+convert(nvarchar(25),@T_End,120)+''' ) )'
print @strsql
exec (@strsql)

end --ER0377 Added


Select @strsql=''
SET @strSql = 'INSERT INTO #CockpitData (
	Plantid,
	MachineID ,
	MachineInterface,
	ProductionEfficiency ,
	AvailabilityEfficiency,
	OverallEfficiency,
	Components ,
	TotalTime ,
	UtilisedTime ,	
	ManagementLoss,
	DownTime ,
	CN,
	PEGreen ,
	PERed,
	AEGreen ,
	AERed ,
	OEGreen ,
	OERed,
	HelpCode1,
	HelpCode2,
	HelpCode3,
	HelpCode4,
	MaxDowntime,
	Target
	) '
SET @strSql = @strSql + ' SELECT PlantMachine.Plantid,MachineInformation.MachineID, MachineInformation.interfaceid ,0,0,0,0,0,0,0,0,0,PEGreen ,PERed,AEGreen ,AERed ,OEGreen ,OERed,''White'',''White'',''White'',''White'',0,0 FROM MachineInformation 
			  LEFT OUTER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID WHERE MachineInformation.interfaceid > ''0'' '
SET @strSql =  @strSql + @strMachine + @strPlantID + @StrTPMMachines
EXEC(@strSql)

SET @strSql = ''
SET @strSql = 'INSERT INTO #PLD(MachineID,MachineInterface,pPlannedDT,dPlannedDT)
	SELECT MachineID ,Interfaceid,0  ,0 FROM MachineInformation WHERE  MachineInformation.interfaceid > ''0'' '
SET @strSql =  @strSql + @strMachine + @StrTPMMachines
EXEC(@strSql)

/* Planned Down times for the given time period */

SET @strSql = ''
SET @strSql = 'Insert into #PlannedDownTimes
	SELECT distinct Machine,InterfaceID,
		CASE When StartTime<''' + convert(nvarchar(20),@StartTime,120)+''' Then ''' + convert(nvarchar(20),@StartTime,120)+''' Else StartTime End As StartTime,
		CASE When EndTime>''' + convert(nvarchar(20),@EndTime,120)+''' Then ''' + convert(nvarchar(20),@EndTime,120)+''' Else EndTime End As EndTime
	FROM PlannedDownTimes inner join MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID
	WHERE PDTstatus =1 and(
	(StartTime >= ''' + convert(nvarchar(20),@StartTime,120)+''' AND EndTime <=''' + convert(nvarchar(20),@EndTime,120)+''')
	OR ( StartTime < ''' + convert(nvarchar(20),@StartTime,120)+'''  AND EndTime <= ''' + convert(nvarchar(20),@EndTime,120)+''' AND EndTime > ''' + convert(nvarchar(20),@StartTime,120)+''' )
	OR ( StartTime >= ''' + convert(nvarchar(20),@StartTime,120)+'''   AND StartTime <''' + convert(nvarchar(20),@EndTime,120)+''' AND EndTime > ''' + convert(nvarchar(20),@EndTime,120)+''' )
	OR ( StartTime < ''' + convert(nvarchar(20),@StartTime,120)+'''  AND EndTime > ''' + convert(nvarchar(20),@EndTime,120)+''')) '
SET @strSql =  @strSql + @strMachine + @StrTPMMachines + ' ORDER BY Machine,StartTime'
EXEC(@strSql)



--IF @param = '1st screen' OR @Param='1st screenOEE' OR @Param='2nd screen' OR @Param='3rd Screen PlantOEE' ----ER0377 Added
IF @param = '1st screen' OR @Param='1st screenOEE' ----ER0377 Added
BEGIN
		/*******************************      Utilised Calculation Starts ***************************************************/
		UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
		from
		(select      mc,sum(cycletime+loadunload) as cycle
		from #T_autodata autodata
		where (autodata.msttime>=@StartTime)
		and (autodata.ndtime<=@EndTime)
		and (autodata.datatype=1)
		group by autodata.mc
		) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface
		-- Type 2
		UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
		from
		(select  mc,SUM(DateDiff(second, @StartTime, ndtime)) cycle
		from #T_autodata autodata
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
		from #T_autodata autodata
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
		sum(DateDiff(second, @StartTime, @EndTime)) cycle from #T_autodata autodata
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
		From #T_autodata AutoData INNER Join
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
		From #T_autodata AutoData INNER Join
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

		------------------------------------ ER0377 Added From Here ---------------------------------
			UPDATE #PLD set pPlannedDT =isnull(pPlannedDT,0) + isNull(TT.PPDT ,0)
			FROM(
				--Production Time in PDT
				SELECT autodata.MC,SUM
					(CASE
		--			WHEN autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.cycletime+autodata.loadunload) --DR0325 Commented
					WHEN autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN DateDiff(second,autodata.msttime,autodata.ndtime) --DR0325 Added
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
					(B.sttime < A.sttime) AND (B.ndtime > A.ndtime) 
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
		--		Inner join #PlannedDownTimes T
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
		  ------------------------------------ ER0377 Added Till Here ---------------------------------

		  /******************************************** ER0377 *************************************************
			UPDATE #PLD set pPlannedDT =isnull(pPlannedDT,0) + isNull(TT.PPDT ,0)
			FROM(
				SELECT autodata.MC,SUM
					(CASE
					WHEN autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN DateDiff(second,autodata.msttime,autodata.ndtime) --DR0325 Added
					WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
					WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )
					WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
					END)  as PPDT
				FROM #T_autodata AutoData CROSS jOIN #PlannedDownTimes T
				WHERE autodata.DataType=1 And T.MachineInterface=AutoData.mc AND
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
				Select AutoData.mc,
				SUM(
				CASE 	
					When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
					When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
					When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
					when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
				END) as IPDT
				From #T_autodata AutoData INNER Join
					(Select mc,Sttime,NdTime From #T_autodata AutoData
						Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
						(msttime >= @StartTime) AND (ndtime <= @EndTime)) as T1
				ON AutoData.mc=T1.mc CROSS jOIN #PlannedDownTimes T
				Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc
				And (( autodata.Sttime > T1.Sttime )
				And ( autodata.ndtime <  T1.ndtime )
				)
				AND
				((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
				or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
				or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
				or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )
				GROUP BY AUTODATA.mc
				)AS T2  INNER JOIN #PLD ON T2.mc = #PLD.MachineInterface
			---mod 4(4)
			
			/* Fetching Down Records from Production Cycle  */
			/* If production  Records of TYPE-2*/
			UPDATE  #PLD set IPlannedDT =isnull(IPlannedDT,0) + isNull(T2.IPDT ,0) 	FROM	(
				Select AutoData.mc,
				SUM(
				CASE 	
					When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
					When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
					When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
					when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
				END) as IPDT
				From #T_autodata AutoData INNER Join
					(Select mc,Sttime,NdTime From #T_autodata AutoData
						Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
						(msttime < @StartTime)And (ndtime > @StartTime) AND (ndtime <= @EndTime)) as T1
				ON AutoData.mc=T1.mc CROSS jOIN #PlannedDownTimes T
				Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc
				And (( autodata.Sttime > T1.Sttime )
				And ( autodata.ndtime <  T1.ndtime )
				AND ( autodata.ndtime >  @StartTime ))
				AND
				(( T.StartTime >= @StartTime )
				And ( T.StartTime <  T1.ndtime ) )
				GROUP BY AUTODATA.mc
			)AS T2  INNER JOIN #PLD ON T2.mc = #PLD.MachineInterface
			
			/* If production Records of TYPE-3*/
			UPDATE  #PLD set IPlannedDT =isnull(IPlannedDT,0) + isNull(T2.IPDT ,0)
			FROM
			(Select AutoData.mc ,
			SUM(
			CASE 	
				When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
				When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
				When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
				when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
			END) as IPDT
			From #T_autodata AutoData INNER Join
				(Select mc,Sttime,NdTime From #T_autodata AutoData
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(sttime >= @StartTime)And (ndtime > @EndTime) and autodata.sttime <@EndTime) as T1
			ON AutoData.mc=T1.mc CROSS jOIN #PlannedDownTimes T
			Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc
			And ((T1.Sttime < autodata.sttime  )
			And ( T1.ndtime >  autodata.ndtime)
			AND (autodata.msttime  <  @EndTime))
			AND
			(( T.EndTime > T1.Sttime )
			And ( T.EndTime <=@EndTime ) )
			GROUP BY AUTODATA.mc)AS T2  INNER JOIN #PLD ON T2.mc = #PLD.MachineInterface
			
			
			/* If production Records of TYPE-4*/
			UPDATE  #PLD set IPlannedDT =isnull(IPlannedDT,0) + isNull(T2.IPDT ,0)
			FROM
			(Select AutoData.mc ,
			SUM(
			CASE 	
				When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
				When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
				When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
				when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
			END) as IPDT
			From #T_autodata AutoData INNER Join
				(Select mc,Sttime,NdTime From #T_autodata AutoData
					Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
					(msttime < @StartTime)And (ndtime > @EndTime)) as T1
			ON AutoData.mc=T1.mc CROSS jOIN #PlannedDownTimes T
			Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc
			And ( (T1.Sttime < autodata.sttime  )
				And ( T1.ndtime >  autodata.ndtime)
				AND (autodata.ndtime  >  @StartTime)
				AND (autodata.sttime  <  @EndTime))
			AND
			(( T.StartTime >=@StartTime)
			And ( T.EndTime <=@EndTime ) )
			GROUP BY AUTODATA.mc)AS T2  INNER JOIN #PLD ON T2.mc = #PLD.MachineInterface
			******************************************** ER0377 *************************************************/
			
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
				from #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
				where (autodata.msttime>=@StartTime)
				and (autodata.ndtime<=@EndTime)
				and (autodata.datatype=2)
				and (downcodeinformation.availeffy = 1)
				group by autodata.mc) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface
				-- Type 2
				UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
				from
				(select      mc,sum(
				CASE WHEN DateDiff(second, @StartTime, ndtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
				then isnull(downcodeinformation.Threshold,0)
				ELSE DateDiff(second, @StartTime, ndtime)
				END)loss
				from #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
				where (autodata.sttime<@StartTime)
				and (autodata.ndtime>@StartTime)
				and (autodata.ndtime<=@EndTime)
				and (autodata.datatype=2)
				and (downcodeinformation.availeffy = 1)
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
				from #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
				where (autodata.msttime>=@StartTime)
				and (autodata.sttime<@EndTime)
				and (autodata.ndtime>@EndTime)
				and (autodata.datatype=2)
				and (downcodeinformation.availeffy = 1)
				group by autodata.mc
				) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface
				-- Type 4
				UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
				from
				(select mc,sum(
				CASE WHEN DateDiff(second, @StartTime, @Endtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
				then isnull(downcodeinformation.Threshold,0)
				ELSE DateDiff(second, @StartTime, @Endtime)
				END)loss
				from #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
				where autodata.msttime<@StartTime
				and autodata.ndtime>@EndTime
				and (autodata.datatype=2)
				and (downcodeinformation.availeffy = 1)
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
				from #T_autodata autodata inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
				where autodata.datatype=2 AND
				(
				(autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)
				OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
				OR (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
				OR (autodata.msttime<@StartTime and autodata.ndtime>@EndTime )
				)
				group by autodata.mc
				) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface
		End

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
			from #T_autodata autodata inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
			where autodata.datatype=2 AND
			(
			(autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)
			OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
			OR (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
			OR (autodata.msttime<@StartTime and autodata.ndtime>@EndTime )
			) AND (downcodeinformation.availeffy = 0)
			group by autodata.mc
			) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface

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
				FROM #T_autodata AutoData CROSS jOIN #PlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
				WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
					(
					(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
					OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
					OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
					OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
					)AND (downcodeinformation.availeffy = 0)
				group by autodata.mc
			) as TT INNER JOIN #PLD ON TT.mc = #PLD.MachineInterface

			---step 3
			---Management loss calculation
			---IN T1 Select get all the downtimes which is of type management loss
			---IN T2  get the time to be deducted from the cycle if the cycle is overlapping with the PDT. And it should be ML record
			---In T3 Get the real management loss , and time to be considered as real down for each cycle(by comaring with the ML threshold)
			---In T4 consolidate everything at machine level and update the same to #CockpitData for ManagementLoss and MLDown
			
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
				from #T_autodata autodata
				inner join downcodeinformation D
				on autodata.dcode=D.interfaceid where autodata.datatype=2 AND
				(
				(autodata.sttime>=@StartTime  and  autodata.ndtime<=@EndTime)
				OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
				OR (autodata.sttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
				OR (autodata.sttime<@StartTime and autodata.ndtime>@EndTime )
				) AND (D.availeffy = 1)) as T1 	
			left outer join
			(SELECT autodata.id,
					   sum(CASE
					WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
					WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
					WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
					WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
					END ) as PPDT
				FROM #T_autodata AutoData CROSS jOIN #PlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
				WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
					(
					(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
					OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
					OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
					OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
					)
					AND (downcodeinformation.availeffy = 1) group  by autodata.id ) as T2 on T1.id=T2.id ) as T3  group by T3.mc
			) as t4 inner join #CockpitData on t4.mc = #CockpitData.machineinterface
			UPDATE #CockpitData SET downtime = isnull(downtime,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)
		END

		---mod 4: Till here Handling interaction between PDT and downtime . Also interaction between PDT and Management Loss
		---mod 4:If Ignore_Dtime_4m_PLD<> Y and Ignore_Dtime_4m_PLD<> N
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
				FROM #T_autodata AutoData CROSS jOIN #PlannedDownTimes T
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

		--************************************ Down and Management  Calculation Ends ******************************************
		---mod 4
		-- Get the value of CN
		-- Type 1
		/* Changed by SSK to Combine SubOperations*/
		UPDATE #CockpitData SET CN = isnull(CN,0) + isNull(t2.C1N1,0)
		from
		(select mc,
		SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))* autodata.partscount) C1N1
		FROM #T_autodata autodata INNER JOIN
		componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
		componentinformation ON autodata.comp = componentinformation.InterfaceID AND
		componentoperationpricing.componentid = componentinformation.componentid
		--mod 2
		inner join machineinformation on machineinformation.interfaceid=autodata.mc
		and componentoperationpricing.machineid=machineinformation.machineid
		--mod 2
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

		--Calculation of PartsCount Begins..
		UPDATE #CockpitData SET components = ISNULL(components,0) + ISNULL(t2.comp,0)
		From
		(
			Select mc,SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp
				   From (select mc,SUM(autodata.partscount)AS OrginalCount,comp,opn from #T_autodata autodata
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
				select mc,SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp From (
					select mc,Sum(ISNULL(PartsCount,1))AS OrginalCount,comp,opn from #T_autodata autodata
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

		UPDATE #CockpitData
			SET UtilisedTime=(UtilisedTime-ISNULL(#PLD.pPlannedDT,0)+isnull(#PLD.IPlannedDT,0)),
				DownTime=(DownTime-ISNULL(#PLD.dPlannedDT,0))
			From #CockpitData Inner Join #PLD on #PLD.Machineid=#CockpitData.Machineid

		-- Calculate efficiencies
		UPDATE #CockpitData
		SET
			ProductionEfficiency = (CN/UtilisedTime) ,
			AvailabilityEfficiency = (UtilisedTime)/(UtilisedTime + DownTime - ManagementLoss),
			TotalTime = DateDiff(second, @StartTime, @EndTime)
		WHERE UtilisedTime <> 0

		UPDATE #CockpitData
		SET
			OverAllEfficiency = Round((ProductionEfficiency * AvailabilityEfficiency)*100,0),
			ProductionEfficiency = Round(ProductionEfficiency * 100,0) ,
			AvailabilityEfficiency = Round(AvailabilityEfficiency * 100,0)


		-------------------------------------------------------------------------------------------------------------------
		/* Maximum Down Reason Time ,Calculation as goes down*/
		---Irrespective of whether the down is management loss or genuine down we are considering the down reason which is the largest
		----------------------------------------------------------------------------------------------------------------------


		--mod 4 commented till here  for Optimization
		select @strsql = ''
		select @strsql = 'INSERT INTO #DownTimeData (MachineID,McInterfaceid, DownID, DownTime,DownFreq) SELECT Machineinformation.MachineID AS MachineID,Machineinformation.interfaceid, downcodeinformation.downid AS DownID, 0,0'
		select @strsql = @strsql+' FROM Machineinformation CROSS JOIN downcodeinformation LEFT OUTER JOIN PlantMachine ON PlantMachine.MachineID=Machineinformation.MachineID '
		select @strsql = @strsql+' Where MachineInformation.interfaceid > ''0'' '
		select @strsql = @strsql + @strPlantID +@strmachine + @StrTPMMachines + ' ORDER BY  downcodeinformation.downid, Machineinformation.MachineID'
		exec (@strsql)
		--********************************************* Get Down Time Details *******************************************************
		--Type 1,2,3 and 4.
		select @strsql = ''
		select @strsql = @strsql + 'UPDATE #DownTimeData SET downtime = isnull(DownTime,0) + isnull(t2.down,0) '
		select @strsql = @strsql + ' FROM'
		select @strsql = @strsql + ' (SELECT mc,--count(mc)as dwnfrq,
		SUM(CASE
		WHEN (autodata.sttime>='''+convert(varchar(20),@starttime)+''' and autodata.ndtime<='''+convert(varchar(20),@endtime)+''' ) THEN loadunload
		WHEN (autodata.sttime<'''+convert(varchar(20),@starttime)+''' and autodata.ndtime>'''+convert(varchar(20),@starttime)+'''and autodata.ndtime<='''+convert(varchar(20),@endtime)+''') THEN DateDiff(second, '''+convert(varchar(20),@StartTime)+''', ndtime)
		WHEN (autodata.sttime>='''+convert(varchar(20),@starttime)+'''and autodata.sttime<'''+convert(varchar(20),@endtime)+''' and autodata.ndtime>'''+convert(varchar(20),@endtime)+''') THEN DateDiff(second, stTime, '''+convert(varchar(20),@Endtime)+''')
		ELSE DateDiff(second,'''+convert(varchar(20),@starttime)+''','''+convert(varchar(20),@endtime)+''')
		END) as down
		,downcodeinformation.downid as downid'
		select @strsql = @strsql + ' from'
		select @strsql = @strsql + '  #T_autodata autodata INNER JOIN'
		select @strsql = @strsql + ' machineinformation ON autodata.mc = machineinformation.InterfaceID Left Outer Join PlantMachine ON PlantMachine.MachineID=machineinformation.MachineID INNER JOIN'
		select @strsql = @strsql + ' componentinformation ON autodata.comp = componentinformation.InterfaceID INNER JOIN'
		select @strsql = @strsql + ' employeeinformation ON autodata.opr = employeeinformation.interfaceid INNER JOIN'
		select @strsql = @strsql + ' downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid'
		select @strsql = @strsql + ' where  datatype=2 AND ((autodata.sttime>='''+convert(varchar(20),@starttime)+''' and autodata.ndtime<='''+convert(varchar(20),@endtime)+''' )OR
		(autodata.sttime<'''+convert(varchar(20),@starttime)+''' and autodata.ndtime>'''+convert(varchar(20),@starttime)+'''and autodata.ndtime<='''+convert(varchar(20),@endtime)+''')OR
		(autodata.sttime>='''+convert(varchar(20),@starttime)+'''and autodata.sttime<'''+convert(varchar(20),@endtime)+''' and autodata.ndtime>'''+convert(varchar(20),@endtime)+''')OR
		(autodata.sttime<'''+convert(varchar(20),@starttime)+''' and autodata.ndtime>'''+convert(varchar(20),@endtime)+'''))'
		select @strsql = @strsql  + @strPlantID + @strmachine
		select @strsql = @strsql + ' group by autodata.mc,downcodeinformation.downid )'
		select @strsql = @strsql + ' as t2 inner join #DownTimeData on t2.mc=#DownTimeData.McInterfaceid and t2.downid=#DownTimeData.downid'
		exec (@strsql)
		--*********************************************************************************************************************
		--mod 4
		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
		BEGIN
			UPDATE #DownTimeData set DownTime =isnull(DownTime,0) - isNull(TT.PPDT ,0)
			FROM(
				--Production PDT
				SELECT autodata.MC,DownID, SUM
					   (CASE
					WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
					WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
					WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
					WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
					END ) as PPDT
				FROM #T_autodata AutoData CROSS jOIN #PlannedDownTimes T
				Inner Join DownCodeInformation On AutoData.DCode=DownCodeInformation.InterfaceID
				WHERE autodata.DataType=2 AND T.MachineInterface = AutoData.mc And
					(
					(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
					OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
					OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
					OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
					)
				group by autodata.mc,DownID
			) as TT INNER JOIN #DownTimeData ON TT.mc = #DownTimeData.McInterfaceid AND #DownTimeData.DownID=TT.DownId
			Where #DownTimeData.DownTime>0
		END

		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y' AND (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
		BEGIN
			UPDATE #DownTimeData set DownTime =isnull(DownTime,0) - isNull(TT.PPDT ,0)
			FROM(
				--Production PDT
				SELECT autodata.MC,DownId, SUM
					   (CASE
					WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
					WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
					WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
					WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
					END ) as PPDT
				FROM #T_autodata AutoData CROSS jOIN #PlannedDownTimes T
				Inner Join DownCodeInformation D ON AutoData.DCode = D.InterfaceID
				WHERE autodata.DataType=2 And T.MachineInterface = AutoData.mc AND D.DownID=(SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD') AND
					(
					(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
					OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
					OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
					OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
					)
				group by autodata.mc,DownId
			) as TT INNER JOIN #DownTimeData ON TT.mc = #DownTimeData.McInterfaceid AND #DownTimeData.DownID=TT.DownId
			Where #DownTimeData.DownTime>0
		END

		--mod 4 commented till here for Optimization
		---mod 4 Update for MaxDownReasonTime
		Update #CockpitData SET MaxDownReason = MaxDReason,MaxDowntime=MaxDTime
		From (select A.MachineID as MachineID,
		A.DownID as MaxDReason,A.DownTime as MaxDTime
		FROM #DownTimeData A
		INNER JOIN (SELECT B.machineid,MAX(B.DownTime)as DownTime FROM #DownTimeData B group by machineid) as T2
		ON A.MachineId = T2.MachineId and A.DownTime = t2.DownTime
		Where A.DownTime > 0
		)as T3 inner join #CockpitData on T3.MachineID = #CockpitData.MachineID


		select @strsql=''
		SELECT @strsql= @strsql + 'insert into #Runningpart_Part(Machineid,Operatorid,StTime)  
		  select Machineinformation.machineid,E.Employeeid,Max(A.StTime) as Sttime from #T_autodata A  
		  inner join Machineinformation on A.mc=Machineinformation.interfaceid  
		  inner join Employeeinformation E on A.Opr=E.interfaceid  
		  where ndtime>'''+convert(nvarchar(20),@starttime)+''' and ndtime<='''+convert(nvarchar(20),@endtime)+'''   '  
		SELECT @strsql = @strsql + @strmachine  
		SELECT @strsql = @strsql +'group by Machineinformation.Machineid,E.Employeeid Order by Machineinformation.machineid'
		print @strsql
		exec (@strsql) 

		Update #CockpitData SET Operatorid = isnull(#CockpitData.Operatorid,'') + isnull(T1.Operatorid,'') from
		(Select Machineid,Operatorid from #Runningpart_Part)T1
		inner join #CockpitData on T1.MachineID = #CockpitData.MachineID

		select @strsql=''
		SELECT @strsql= @strsql + 'insert into #HelpCode(Machineid,HelpDescription,HelpCode,Action1,Action2,Starttime,Endtime)  
		Select T.Machineid,T.Help_Description,T.HelpCode,H.Action1,H.Action2,H.Starttime,H.Endtime from(
		select Machineinformation.Machineid,Max(HD.ID) as ID,HM.Help_Description
		,HD.HelpCode from helpcodedetails HD WITH (NOLOCK)' -- ----ER0377 Added LOCK
		SELECT @strsql= @strsql + ' Inner join HelpCodeMaster HM on HD.HelpCode=HM.Help_code
		Inner join Machineinformation on HD.Machineid=Machineinformation.interfaceid '
		SELECT @strsql = @strsql + @strmachine  
	    SELECT @strsql = @strsql +  ' group by Machineinformation.Machineid,HM.Help_Description,HD.HelpCode)T 
		inner join helpcodedetails H on T.ID = H.ID
		where isnull(H.Action2,''a'') <> ''04'''
		print @strsql
		exec (@strsql) 
	

		Update #Cockpitdata set HelpCode1 = T1.Val1,HelpCode1TS=T1.ActionTS from 
		(Select Machineid,
		 Case when Action1 = '01' and  Isnull(Action2,'a')='a' then 'Red'
		 when Action1 = '01' and  Action2 ='02' then 'Yellow'
		 when Action1 = '01' and  Action2 ='03' then 'Green'
		 when Action1 = '01' and  Action2 ='04' then 'White' end as Val1,
		 Case when Action1 = '01' and  Isnull(Action2,'a')='a' then datediff(second,starttime,@CurrTime)
		 when Action1 = '01' and  Action2 in('02','03','04') then datediff(second,starttime,case when endtime>@CurrTime then @CurrTime else endtime end) END as ActionTS
		 from #HelpCode
		 Where  HelpCode = '01')T1
		inner join #CockpitData on T1.MachineID = #CockpitData.MachineID

		Update #Cockpitdata set HelpCode2=T1.Val2,HelpCode2TS=T1.ActionTS from
		(Select Machineid,
		 Case when Action1 = '01' and  Isnull(Action2,'a')='a' then 'Red'
		 when Action1 = '01' and  Action2 ='02' then 'Yellow'
		 when Action1 = '01' and  Action2 ='03' then 'Green'
		 when Action1 = '01' and  Action2 ='04' then 'White' end as Val2,
		 Case when Action1 = '01' and  Isnull(Action2,'a')='a' then datediff(second,starttime,@CurrTime)
		 when Action1 = '01' and  Action2 in('02','03','04') then datediff(second,starttime,case when endtime>@CurrTime then @CurrTime else endtime end) END as ActionTS from #HelpCode
		 Where  HelpCode = '02')T1
		inner join #CockpitData on T1.MachineID = #CockpitData.MachineID

		Update #Cockpitdata set HelpCode3=T1.Val3,HelpCode3TS=T1.ActionTS from
		(Select Machineid,
		 Case when Action1 = '01' and  Isnull(Action2,'a')='a' then 'Red'
		 when Action1 = '01' and  Action2 ='02' then 'Yellow'
		 when Action1 = '01' and  Action2 ='03' then 'Green'
		 when Action1 = '01' and  Action2 ='04' then 'White' end as  Val3,
		 Case when Action1 = '01' and  Isnull(Action2,'a')='a' then datediff(second,starttime,@CurrTime)
		 when Action1 = '01' and  Action2 in('02','03','04') then datediff(second,starttime,case when endtime>@CurrTime then @CurrTime else endtime end) END as ActionTS from #HelpCode
		 Where  HelpCode = '03')T1
		inner join #CockpitData on T1.MachineID = #CockpitData.MachineID

		Update #Cockpitdata set HelpCode4=T1.Val4,HelpCode4TS=T1.ActionTS from
		(Select Machineid,
		 Case when Action1 = '01' and  Isnull(Action2,'a')='a' then 'Red'
		  when Action1 = '01' and  Action2 ='02' then 'Yellow'
		  when Action1 = '01' and  Action2 ='03' then 'Green'
		  when Action1 = '01' and  Action2 ='04' then 'White' end as Val4,
		  Case when Action1 = '01' and  Isnull(Action2,'a')='a' then datediff(second,starttime,@CurrTime)
		 when Action1 = '01' and  Action2 in('02','03','04') then datediff(second,starttime,case when endtime>@CurrTime then @CurrTime else endtime end) END as ActionTS from #HelpCode
		 Where  HelpCode = '04')T1
		inner join #CockpitData on T1.MachineID = #CockpitData.MachineID


		Declare @Type40Threshold int
		Declare @Type1Threshold int
		Declare @Type11Threshold int

		Set @Type40Threshold = (Select isnull(Valueintext2,5)*60 from shopdefaults where parameter='ANDONStatusThreshold' and valueintext = 'Type40Threshold')
		Set @Type1Threshold = (Select isnull(Valueintext2,5)*60 from shopdefaults where parameter='ANDONStatusThreshold' and valueintext = 'Type1Threshold')
		Set @Type11Threshold = (Select isnull(Valueintext2,5)*60 from shopdefaults where parameter='ANDONStatusThreshold' and valueintext = 'Type11Threshold')
		print @Type40Threshold
		print @Type1Threshold
		print @Type11Threshold

		Insert into #machineRunningStatus
		select fd.MachineID,fd.MachineInterface,sttime,ndtime,datatype,'White',0,'1900-01-01',0 from rawdata
		inner join (select mc,max(slno) as slno from rawdata WITH (NOLOCK) where sttime<@currtime and isnull(ndtime,'1900-01-01')<@currtime
		and datatype in(2,42,40,41,1,11) group by mc ) t1 on t1.mc=rawdata.mc and t1.slno=rawdata.slno
		right outer join #CockpitData fd on fd.MachineInterface = rawdata.mc
		order by rawdata.mc

		update #machineRunningStatus set ColorCode = case when (datediff(second,sttime,@CurrTime)- @Type11Threshold)>0  then 'Red' else 'Green' end where datatype in (11)
		update #machineRunningStatus set ColorCode = 'Green' where datatype in (41)
		update #machineRunningStatus set ColorCode = 'Red' where datatype in (42,2)

		update #machineRunningStatus set ColorCode = t1.ColorCode from (
		Select mrs.MachineID,Case when (
		case when datatype = 40 then datediff(second,sttime,@CurrTime)- @Type40Threshold
		when datatype = 1 then datediff(second,ndtime,@CurrTime)- @Type1Threshold
		end) > 0 then 'Red' else 'Green' end as ColorCode
		from #machineRunningStatus mrs 
		where  datatype in (40,1)
		) as t1 inner join #machineRunningStatus on t1.MachineID = #machineRunningStatus.MachineID

		Update #machineRunningStatus set DownTime = Isnull(#machineRunningStatus.DownTime,0) + Isnull(t2.DownTime,0)
		,lastDownstart=t2.LastRecord
		from (
			Select mrs.MachineID,
			dateDiff(second,t1.LastRecord,@CurrTime) as DownTime,t1.LastRecord
			from #machineRunningStatus mrs 
			inner join (
				Select mrs.MachineID,
				case when (datatype = 1) then dateadd(s,@Type1Threshold,ndtime)
				when (datatype = 2)or(datatype = 42) then ndtime
				when datatype = 40 then dateadd(s,@Type40Threshold,sttime)
				when datatype=11 then dateadd(s,@Type11Threshold,sttime)
				when datatype=41 then sttime end as LastRecord
				from #machineRunningStatus mrs
			) as t1 on t1.machineID = mrs.machineID 
		) as t2 inner join #machineRunningStatus on t2.MachineID = #machineRunningStatus.MachineID


		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' 
		BEGIN
			update #machineRunningStatus set PDT = Isnull(fd.PDT,0) + isnull(T2.pdt,0)
			from
			(
			Select T1.machineid,sum(datediff(ss,T1.StartTime,t1.EndTime)) as pdt 
			from (
			select fD.machineid,
			Case when  fd.lastDownstart <= pdt.StartTime then pdt.StartTime else  lastDownstart End as StartTime,
			Case when @currtime >= pdt.EndTime then pdt.EndTime else @currtime End as EndTime
			From Planneddowntimes pdt
			inner join #machineRunningStatus fD on fd.machineid=Pdt.machine
			where PDTstatus = 1  and 
			((pdt.StartTime >= fd.lastDownstart and pdt.EndTime <= @currtime)or
			(pdt.StartTime < fd.lastDownstart and pdt.EndTime > fd.lastDownstart and pdt.EndTime <=@currtime)or
			(pdt.StartTime >= fd.lastDownstart and pdt.StartTime <@currtime and pdt.EndTime >@currtime) or
			(pdt.StartTime <  fd.lastDownstart and pdt.EndTime >@currtime))
			)T1  group by T1.machineid )T2 inner join #machineRunningStatus fd on fd.machineid=t2.machineid	
				
			update #machineRunningStatus set ColorCode = Case when Downtime-PDT=0 then 'Blue' else Colorcode end 
		end

		update #machineRunningStatus set ColorCode ='Red' where isnull(sttime,'1900-01-01')='1900-01-01'
	
		Update #CockpitData set Colorcode = Isnull(#CockpitData.Colorcode,'') +  isnull(T1.Color,'') from
		(select Machineid,Colorcode as color from #machineRunningStatus)T1
		inner join #CockpitData on T1.MachineID = #CockpitData.MachineID

--		Update #Cockpitdata set colorcode='Yellow' from
--		(select Machineid from #cockpitdata where HelpCode1 in ('Red','Green','Yellow') or HelpCode2 in ('Red','Green','Yellow') or HelpCode3 in ('Red','Green','Yellow') or HelpCode4 in ('Red','Green','Yellow'))T1
--		inner join #CockpitData on T1.MachineID = #CockpitData.MachineID
END
	
		
IF @param = '1st screen'
BEGIN

	Select @T_ST=convert(nvarchar(25),@Starttime,120)
	Select @T_ED=convert(nvarchar(25),@currtime,120)

	Select @strsql=''
	select @strsql ='insert into #T_autodataforDown '
	select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'
	 select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'
	select @strsql = @strsql + ' from #T_autodata autodata inner join Machineinformation on Machineinformation.interfaceid=Autodata.mc 
	inner join Plantmachine on Plantmachine.machineid=Machineinformation.machineid
	where (datatype=1) and (( sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_ED,120)+''' ) OR '
	select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' )OR '
	select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ST,120)+'''
					 and ndtime<='''+convert(nvarchar(25),@T_ED,120)+''' )'
	select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' and sttime<'''+convert(nvarchar(25),@T_ED,120)+''' ) )'
	select @strsql = @strsql + @strmachine + @strPlantID
	print @strsql
	exec (@strsql)

	Select @strsql=''
	select @strsql ='insert into #T_autodataforDown '
	select @strsql = @strsql + 'SELECT A1.mc, A1.comp, A1.opn, A1.opr, A1.dcode,A1.sttime,'
	 select @strsql = @strsql + 'A1.ndtime, A1.datatype, A1.cycletime, A1.loadunload, A1.msttime, A1.PartsCount,A1.id'
	select @strsql = @strsql + ' from #T_autodata A1 inner join Machineinformation on Machineinformation.interfaceid=A1.mc 
    inner join Plantmachine on Plantmachine.machineid=Machineinformation.machineid
	where A1.datatype=2 and
	(( A1.sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and A1.ndtime <= '''+convert(nvarchar(25),@T_ED,120)+'''  ) OR
	 ( A1.sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and A1.ndtime >'''+convert(nvarchar(25),@T_ED,120)+'''  )OR 
	 (A1.sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and A1.ndtime >'''+ convert(nvarchar(25),@T_ST,120)+''' and A1.ndtime<='''+convert(nvarchar(25),@T_ED,120)+'''  ) or
	 (A1.sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and A1.ndtime >'''+convert(nvarchar(25),@T_ED,120)+'''  and A1.sttime<'''+convert(nvarchar(25),@T_ED,120)+'''  ) )
	and NOT EXISTS ( select * from #T_autodata A2 
	inner join Machineinformation on Machineinformation.interfaceid=A2.mc
    inner join Plantmachine on Plantmachine.machineid=Machineinformation.machineid
	 where  A2.datatype=1 and  ((  A2.sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and  A2.ndtime <= '''+convert(nvarchar(25),@T_ED,120)+'''  ) OR
	 (A2.sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and  A2.ndtime >'''+convert(nvarchar(25),@T_ED,120)+'''  )OR 
	 (A2.sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and  A2.ndtime >'''+ convert(nvarchar(25),@T_ST,120)+''' and  A2.ndtime<='''+convert(nvarchar(25),@T_ED,120)+'''  ) 
	OR (A2.sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and  A2.ndtime >'''+convert(nvarchar(25),@T_ED,120)+'''  and  A2.sttime<'''+convert(nvarchar(25),@T_ED,120)+'''  ) )
	and A2.sttime<=A1.sttime and A2.ndtime>A1.ndtime and A1.mc=A2.mc'
	select @strsql = @strsql + @strmachine+ @strPlantID
	select @strsql = @strsql + ' )'
	select @strsql = @strsql + @strmachine+ @strPlantID
	print @strsql
	exec (@strsql)

	Select @strsql=''	
	Select @strsql= 'insert into #Target(MachineID,machineinterface,Component,Compinterface,Operation,Opninterface,
	msttime,ndtime,batchid,runtime,autodataid,Targetpercent,Suboperation,StdCycletime)'
	select @strsql = @strsql + ' SELECT machineinformation.machineid, machineinformation.interfaceid,componentinformation.componentid, componentinformation.interfaceid,
	componentoperationpricing.operationno, componentoperationpricing.interfaceid,
	Case when autodata.msttime< '''+ convert(nvarchar(25),@T_ST,120)+''' then '''+ convert(nvarchar(25),@T_ST,120)+''' else autodata.msttime end, 
	Case when autodata.ndtime> '''+convert(nvarchar(25),@T_ED,120)+''' then '''+convert(nvarchar(25),@T_ED,120)+''' else autodata.ndtime end,
	0,0,autodata.id,isnull(componentoperationpricing.Targetpercent,100)
	,isnull(componentoperationpricing.Suboperations,1),isnull(componentoperationpricing.Cycletime,0) FROM #T_autodataforDown  autodata
	INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID 
    INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID  
	INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID
	AND componentinformation.componentid = componentoperationpricing.componentid
	and componentoperationpricing.machineid=machineinformation.machineid 
	Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid 
	Left Outer Join Employeeinformation EI on EI.interfaceid=autodata.opr 
	Left Outer Join downcodeinformation DI on DI.interfaceid=autodata.dcode 
	WHERE ((autodata.msttime >= '''+ convert(nvarchar(25),@T_ST,120)+'''  AND autodata.ndtime <= '''+convert(nvarchar(25),@T_ED,120)+''')
	OR ( autodata.msttime < '''+ convert(nvarchar(25),@T_ST,120)+'''  AND autodata.ndtime <= '''+convert(nvarchar(25),@T_ED,120)+''' AND autodata.ndtime >'''+ convert(nvarchar(25),@T_ST,120)+''' )
	OR ( autodata.msttime >= '''+ convert(nvarchar(25),@T_ST,120)+'''   AND autodata.msttime <'''+convert(nvarchar(25),@T_ED,120)+''' AND autodata.ndtime > '''+convert(nvarchar(25),@T_ED,120)+''' )
	OR ( autodata.msttime < '''+ convert(nvarchar(25),@T_ST,120)+'''  AND autodata.ndtime > '''+convert(nvarchar(25),@T_ED,120)+''' ))'
	select @strsql = @strsql + @strmachine + @strPlantID
	select @strsql = @strsql + ' order by autodata.msttime'
	print @strsql
	exec (@strsql)



	declare @mc_prev nvarchar(50),@comp_prev nvarchar(50),@opn_prev nvarchar(50)
	declare @mc nvarchar(50),@comp nvarchar(50),@opn nvarchar(50),@id nvarchar(50)
	declare @batchid int
	Declare @autodataid bigint,@autodataid_prev bigint
	declare @setupcursor  cursor
	set @setupcursor=cursor for
	select autodataid,MachineID ,Component ,Operation  from #Target order by machineid,msttime
	open @setupcursor
	fetch next from @setupcursor into @autodataid,@mc,@comp,@opn
	set @autodataid_prev=@autodataid
	set @mc_prev = @mc
	set @comp_prev = @comp
	set @opn_prev = @opn

	set @batchid =1

	while @@fetch_status = 0
	begin
	If @mc_prev=@mc and @comp_prev=@comp and @opn_prev=@opn	
		begin		
			update #Target set batchid = @batchid where autodataid=@autodataid and MachineID=@mc and Component=@comp and Operation=@opn 
			print @batchid
		end
		else
		begin	
			  set @batchid = @batchid+1        
			  update #Target set batchid = @batchid where autodataid=@autodataid and MachineID=@mc and Component=@comp and Operation=@opn
			  set @autodataid_prev=@autodataid 
			  set @mc_prev=@mc 	
			  set @comp_prev=@comp
			  set @opn_prev=@opn	

		end	
		fetch next from @setupcursor into @autodataid,@mc,@comp,@opn
		
	end
	close @setupcursor
	deallocate @setupcursor


	insert into #FinalTarget (MachineID,Component,operation,machineinterface,Compinterface,Opninterface,Runtime,batchid,msttime,ndtime,Targetpercent,Suboperation,StdCycletime) 
	Select MachineID,Component,operation,machineinterface,Compinterface,Opninterface,datediff(s,min(msttime),max(ndtime)),batchid,min(msttime),max(ndtime),Targetpercent,Suboperation,StdCycletime from #Target 
	group by MachineID,Component,operation,batchid,Targetpercent,machineinterface,Compinterface,Opninterface,Suboperation,StdCycletime order by batchid 
	

	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y' --ER0363 Added
	BEGIN
			UPDATE #FinalTarget set Runtime =isnull(Runtime,0) - isNull(T1.PPDT ,0)
			FROM(
				Select A.machineinterface,A.Compinterface,A.Opninterface,A.msttime,A.ndtime,Sum
				(CASE
				WHEN A.msttime >= T.StartTime  AND A.ndtime <=T.EndTime  THEN DateDiff(second,A.msttime,A.ndtime) --DR0325 added
				WHEN ( A.msttime < T.StartTime  AND A.ndtime <= T.EndTime  AND A.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,A.ndtime)
				WHEN ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime  AND A.ndtime > T.EndTime  ) THEN DateDiff(second,A.msttime,T.EndTime )
				WHEN ( A.msttime < T.StartTime  AND A.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
				END)  as PPDT
				From #FinalTarget A
				CROSS jOIN PlannedDownTimes T 
				WHERE T.Machine=A.MachineID AND 
				((A.msttime >= T.StartTime  AND A.ndtime <=T.EndTime)
				OR ( A.msttime < T.StartTime  AND A.ndtime <= T.EndTime AND A.ndtime > T.StartTime )
				OR ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime AND A.ndtime > T.EndTime )
				OR ( A.msttime < T.StartTime  AND A.ndtime > T.EndTime) ) 		
			 group by A.machineinterface,A.Compinterface,A.Opninterface,A.msttime,A.ndtime
		)
		as T1 inner join  #FinalTarget on  T1.machineinterface=#FinalTarget.machineinterface and T1.Compinterface=#FinalTarget.Compinterface
			and T1.Opninterface=#FinalTarget.Opninterface and T1.msttime=#FinalTarget.msttime and T1.ndtime=#FinalTarget.ndtime
	END


	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
	BEGIN	
		Update #FinalTarget set Runtime = Isnull(Runtime,0) - Isnull(T3.MLDown,0) from
		(
		Select T1.machineinterface,T1.Compinterface,T1.Opninterface,T1.msttime,T1.ndtime,SUM(DateDiff(second,T1.Asttime,T1.Andtime))-isnull(SUM(T2.PPDT),0) as MLDown from	
			(select Autodata.id,T.machineinterface,T.Compinterface,T.Opninterface,T.FromTm,T.ToTm,T.msttime,T.ndtime,
			case when autodata.sttime<T.msttime then T.msttime else autodata.sttime end as Asttime,
			case when autodata.ndtime>T.ndtime then T.ndtime else autodata.ndtime end as Andtime
						from #T_autodata autodata  
						INNER JOIN #FinalTarget T on T.machineinterface=Autodata.mc and T.Compinterface=Autodata.comp
						and T.Opninterface = Autodata.opn
						INNER JOIN DownCodeInformation ON AutoData.DCode = DownCodeInformation.InterfaceID
						WHERE autodata.DataType=2 AND
						((autodata.sttime >= T.msttime  AND autodata.ndtime <=T.ndtime)
						OR ( autodata.sttime < T.msttime  AND autodata.ndtime <= T.ndtime AND autodata.ndtime > T.msttime )
						OR ( autodata.sttime >= T.msttime   AND autodata.sttime <T.ndtime AND autodata.ndtime > T.ndtime )
						OR ( autodata.sttime < T.msttime  AND autodata.ndtime > T.ndtime))
						AND (downcodeinformation.availeffy = 1)
			  ) AS T1
			Left Outer join
			(
					SELECT autodata.id
					,F.msttime,F.ndtime,F.machineinterface,F.Compinterface,F.Opninterface,
					SUM
					(CASE
					WHEN (autodata.sttime >= F.msttime  AND autodata.ndtime <=F.ndtime)  THEN autodata.loadunload
					WHEN ( autodata.sttime < F.msttime  AND autodata.ndtime <= F.ndtime  AND autodata.ndtime > F.msttime ) THEN DateDiff(second,F.msttime,autodata.ndtime)
					WHEN ( autodata.sttime >= F.msttime   AND autodata.sttime <F.ndtime  AND autodata.ndtime > F.ndtime  ) THEN DateDiff(second,autodata.sttime,F.ndtime )
					WHEN ( autodata.sttime < F.msttime  AND autodata.ndtime > F.ndtime ) THEN DateDiff(second,F.msttime,F.ndtime )
					END ) as PPDT
					FROM #T_autodata AutoData
					CROSS jOIN #PlannedDownTimes T
					 INNER JOIN #FinalTarget F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn
					 inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
					WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
					((autodata.sttime >= F.msttime  AND autodata.ndtime <=F.ndtime)
						OR ( autodata.sttime < F.msttime  AND autodata.ndtime <= F.ndtime AND autodata.ndtime > F.msttime )
						OR ( autodata.sttime >= F.msttime   AND autodata.sttime <F.ndtime AND autodata.ndtime > F.ndtime )
						OR ( autodata.sttime < F.msttime  AND autodata.ndtime > F.ndtime))
						AND
						((autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
						OR (autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
						OR (autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )
						OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )
						AND
							((F.msttime >= T.StartTime  AND F.ndtime <=T.EndTime)
							OR ( F.msttime < T.StartTime  AND F.ndtime <= T.EndTime AND f.ndtime > T.StartTime )
							OR ( F.msttime >= T.StartTime   AND F.msttime <T.EndTime AND F.ndtime > T.EndTime )
							OR ( F.msttime < T.StartTime  AND f.ndtime > T.EndTime) )  AND (downcodeinformation.availeffy = 1) 
						group  by autodata.id,F.msttime,F.ndtime,F.machineinterface,F.Compinterface,F.Opninterface			
				) As T2 on T1.id=T2.id and T1.msttime=T2.msttime and T1.ndtime=T2.ndtime and T1.machineinterface=T2.machineinterface 
				and T1.Compinterface=T2.Compinterface and T1.Opninterface=T2.Opninterface
				 group by T1.msttime,T1.ndtime,T1.machineinterface,T1.Compinterface,T1.Opninterface)T3  inner join  #FinalTarget on  T3.machineinterface=#FinalTarget.machineinterface and T3.Compinterface=#FinalTarget.Compinterface
		and T3.Opninterface=#FinalTarget.Opninterface and T3.msttime=#FinalTarget.msttime and T3.ndtime=#FinalTarget.ndtime
	END


					
	--If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
	--BEGIN

	--	Update #FinalTarget set Runtime = Isnull(Runtime,0) - Isnull(T1.MLDown,0) from
	--	(
	--		select T.machineinterface,T.Compinterface,T.Opninterface,T.msttime,T.ndtime,SUM
	--			(CASE
	--			WHEN (autodata.sttime >= T.msttime  AND autodata.ndtime <=T.ndtime)  THEN autodata.loadunload
	--			WHEN ( autodata.sttime < T.msttime  AND autodata.ndtime <= T.ndtime  AND autodata.ndtime > T.msttime ) THEN DateDiff(second,T.msttime,autodata.ndtime)
	--			WHEN ( autodata.sttime >= T.msttime   AND autodata.sttime <T.ndtime  AND autodata.ndtime > T.ndtime  ) THEN DateDiff(second,autodata.sttime,T.ndtime )
	--			WHEN ( autodata.sttime < T.msttime  AND autodata.ndtime > T.ndtime ) THEN DateDiff(second,T.msttime,T.ndtime )
	--			END ) as MLDown
	--		from autodata  
	--		INNER JOIN #FinalTarget T on T.machineinterface=Autodata.mc and T.Compinterface=Autodata.comp
	--		and T.Opninterface = Autodata.opn
	--		INNER JOIN DownCodeInformation ON AutoData.DCode = DownCodeInformation.InterfaceID
	--		WHERE autodata.DataType=2 AND
	--		((autodata.sttime >= T.msttime  AND autodata.ndtime <=T.ndtime)
	--		OR ( autodata.sttime < T.msttime  AND autodata.ndtime <= T.ndtime AND autodata.ndtime > T.msttime )
	--		OR ( autodata.sttime >= T.msttime   AND autodata.sttime <T.ndtime AND autodata.ndtime > T.ndtime )
	--		OR ( autodata.sttime < T.msttime  AND autodata.ndtime > T.ndtime))
	--		AND (downcodeinformation.availeffy = 1)
	--		group by T.machineinterface,T.Compinterface,T.Opninterface,T.msttime,T.ndtime
	--	)T1 inner join  #FinalTarget on  T1.machineinterface=#FinalTarget.machineinterface and T1.Compinterface=#FinalTarget.Compinterface
	--	and T1.Opninterface=#FinalTarget.Opninterface and T1.msttime=#FinalTarget.msttime and T1.ndtime=#FinalTarget.ndtime
	--	and #FinalTarget.runtime>=Isnull(T1.MLDown,0)
	--END

	Update #FinalTarget set Target = Isnull(Target,0) + isnull(T1.targetcount,0) from
	(Select machineinterface,Compinterface,Opninterface,msttime,ndtime,sum(((Runtime*suboperation)/stdcycletime)*isnull(targetpercent,100) /100) as targetcount
	 from #FinalTarget group by machineinterface,Compinterface,Opninterface,msttime,ndtime)T1 inner join #FinalTarget on  T1.machineinterface=#FinalTarget.machineinterface and T1.Compinterface=#FinalTarget.Compinterface
	and T1.Opninterface=#FinalTarget.Opninterface  and T1.msttime=#FinalTarget.msttime and T1.ndtime=#FinalTarget.ndtime


	Update #CockpitData set Target = Isnull(Target,0) + isnull(T1.TCount,0) from 
	(Select machineid,Sum(Target) as Tcount from #FinalTarget
	 Group by machineid)T1 inner join #CockpitData on #CockpitData.machineid=T1.machineid 


		SELECT
		Plantid,
		MachineID,
		ColorCode,
		HelpCode1,HelpCode2,HelpCode3,HelpCode4,
		Utilisedtime,
		ProductionEfficiency,
		AvailabilityEfficiency,
		OverAllEfficiency,
		Components,
		Round(Target,0) as Planned,
		PEGreen,
		PERed,
		AEGreen,
		AERed,
		OEGreen,
		OERed,
		dbo.f_FormatTime(ISNULL(HelpCode1TS,'60'),'hh:mm') as HelpCode1TS,
		dbo.f_FormatTime(ISNULL(HelpCode2TS,'60'),'hh:mm') as HelpCode2TS,dbo.f_FormatTime(ISNULL(HelpCode3TS,'60'),'hh:mm') as HelpCode3TS,dbo.f_FormatTime(ISNULL(HelpCode4TS,'60'),'hh:mm') as HelpCode4TS
		FROM #CockpitData
		order by Plantid,machineid asc
END


If @Param='1st screenOEE'
BEGIN

		SELECT
		Plantid,
		MachineID,
		OverAllEfficiency,
		Components,
		Utilisedtime,
		Operatorid,
		MaxDownReason,
		Case when MaxDownReason = '' then ''
		when substring(dbo.f_FormatTime(MaxDowntime,'hh:mm'),1,charindex(':',dbo.f_FormatTime(MaxDowntime,'hh:mm'))-1) = '0' 
		then substring(dbo.f_FormatTime(MaxDowntime,'hh:mm'),charindex(':',dbo.f_FormatTime(MaxDowntime,'hh:mm'))+1,len(dbo.f_FormatTime(MaxDowntime,'hh:mm'))) + ' mins ' 
		when substring(dbo.f_FormatTime(MaxDowntime,'hh:mm'),charindex(':',dbo.f_FormatTime(MaxDowntime,'hh:mm'))+1,len(dbo.f_FormatTime(MaxDowntime,'hh:mm')))= '0'
		then substring(dbo.f_FormatTime(MaxDowntime,'hh:mm'),1,charindex(':',dbo.f_FormatTime(MaxDowntime,'hh:mm'))-1) + ' hrs '
		else substring(dbo.f_FormatTime(MaxDowntime,'hh:mm'),1,charindex(':',dbo.f_FormatTime(MaxDowntime,'hh:mm'))-1) + ' hrs ' +
		substring(dbo.f_FormatTime(MaxDowntime,'hh:mm'),charindex(':',dbo.f_FormatTime(MaxDowntime,'hh:mm'))+1,len(dbo.f_FormatTime(MaxDowntime,'hh:mm'))) + ' mins ' 
		end as MaxDowntime
		FROM #CockpitData where OverAllEfficiency>0
		order by OverAllEfficiency desc
END


If @Param= '2nd Screen'
BEGIN
		declare @curstarttime as datetime  
		Declare @curendtime as datetime  
		declare @curstart as datetime  
		declare @hourid nvarchar(50)  
		Declare @StrDiv int  
		Declare @counter as datetime  	


	  select @counter=convert(datetime, cast(DATEPART(yyyy,@StartTime)as nvarchar(4))+'-'+cast(datepart(mm,@StartTime)as nvarchar(2))+'-'+cast(datepart(dd,@StartTime)as nvarchar(2)) +' 00:00:00.000')  
        
      select @counter=  CASE  
      WHEN FROMDAY=1 AND TODAY=1 THEN dbo.f_GetLogicalDayStart(@counter)  
      WHEN FROMDAY=0 AND TODAY=1 THEN @COUNTER  
      WHEN FROMDAY=0 AND TODAY=0 THEN @COUNTER  
      END FROM SHIFTDETAILS WHERE RUNNING=1 AND SHIFTNAME=@SHIFTNAME  

      Insert into #ShiftTemp(PDate,ShiftName, FromTime, ToTime)  
      Exec s_GetShiftTime @counter,@ShiftName  
    
      SELECT TOP 1 @counter=FromTime FROM #ShiftTemp ORDER BY FromTime ASC  
      SELECT TOP 1 @Enddate=ToTime FROM #ShiftTemp ORDER BY FromTime DESC
	  

			--select @StrDiv=cast (ceiling (cast(datediff(second,@counter,@Enddate)as float ) /7200) as int)   --ER0377

			--While(@counter < @Enddate)  
			--BEGIN  
			--SELECT @curstarttime=@counter  
			--SELECT @curendtime=DATEADD(Second,7200,@counter)  --ER0377
			--if @curendtime >= @Enddate  
			--Begin  
			--set @curendtime = @Enddate  
			--End  

			--Select @strsql=''
			--select @strsql ='Insert into #HourlyData1(Machineid,FromTime,ToTime,Actual,Target,TargetTotal,ActualTotal)'
			--select @strsql = @strsql + ' Select Machineinformation.Machineid, ''' + convert(nvarchar(20),@curstarttime) + ''', ''' + convert(nvarchar(20),@curendtime) + ''',0,0,0,0
			--from Machineinformation inner join Plantmachine on Plantmachine.machineid=Machineinformation.machineid'
			--select @strsql = @strsql + @strmachine + @strPlantID
			--print @strsql
			--exec (@strsql)

			--SELECT @counter = DATEADD(Second,7200,@counter)  --ER0377
			--END  
		

			select @StrDiv=cast (ceiling (cast(datediff(second,@counter,@Enddate)as float ) /3600) as int)   --ER0377

			While(@counter < @Enddate)  
			BEGIN  
			SELECT @curstarttime=@counter  
			SELECT @curendtime=DATEADD(Second,3600,@counter)  --ER0377
			if @curendtime >= @Enddate  
			Begin  
			set @curendtime = @Enddate  
			End  

			Select @strsql=''
			select @strsql ='Insert into #HourlyData1(Machineid,FromTime,ToTime,Actual,Target,TargetTotal,ActualTotal)'
			select @strsql = @strsql + ' Select Machineinformation.Machineid, ''' + convert(nvarchar(20),@curstarttime) + ''', ''' + convert(nvarchar(20),@curendtime) + ''',0,0,0,0
			from Machineinformation inner join Plantmachine on Plantmachine.machineid=Machineinformation.machineid'
			select @strsql = @strsql + @strmachine + @strPlantID
			print @strsql
			exec (@strsql)

			SELECT @counter = DATEADD(Second,3600,@counter)  --ER0377
			END  


	Update #HourlyData1 set Totime = Case When T.Totim>@CurrTime then @CurrTime Else T.Totim end from
	(select Machineid,Fromtime,Totime as totim from #HourlyData1 where @CurrTime between Fromtime and Totime)T 
	inner join #HourlyData1 H on T.Machineid=H.Machineid and t.Fromtime=H.Fromtime

	Insert into #HourlyData(Machineid,FromTime,ToTime,Actual,Target,TargetTotal,ActualTotal)
	select Machineid,FromTime,ToTime,Actual,Target,TargetTotal,ActualTotal from #HourlyData1
	Where Totime<=@CurrTime


	Select @T_ST=min(FromTime) from #HourlyData 
	Select @T_ED=max(Totime) from #HourlyData 

	Select @strsql=''
	select @strsql ='insert into #T_autodataforDown '
	select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'
	 select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'
	select @strsql = @strsql + ' from #T_autodata autodata WITH (NOLOCK) inner join Machineinformation on Machineinformation.interfaceid=Autodata.mc   ----ER0377 Added LOCK
	inner join Plantmachine on Plantmachine.machineid=Machineinformation.machineid
	where (datatype=1) and (( sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_ED,120)+''' ) OR '
	select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' )OR '
	select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ST,120)+'''
					 and ndtime<='''+convert(nvarchar(25),@T_ED,120)+''' )'
	select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' and sttime<'''+convert(nvarchar(25),@T_ED,120)+''' ) )'
	select @strsql = @strsql + @strmachine + @strPlantID
	print @strsql
	exec (@strsql)

	Select @strsql=''
	select @strsql ='insert into #T_autodataforDown '
	select @strsql = @strsql + 'SELECT A1.mc, A1.comp, A1.opn, A1.opr, A1.dcode,A1.sttime,'
	 select @strsql = @strsql + 'A1.ndtime, A1.datatype, A1.cycletime, A1.loadunload, A1.msttime, A1.PartsCount,A1.id'
	select @strsql = @strsql + ' from #T_autodata A1 WITH (NOLOCK) inner join Machineinformation on Machineinformation.interfaceid=A1.mc   ----ER0377 Added LOCK
    inner join Plantmachine on Plantmachine.machineid=Machineinformation.machineid
	where A1.datatype=2 and
	(( A1.sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and A1.ndtime <= '''+convert(nvarchar(25),@T_ED,120)+'''  ) OR
	 ( A1.sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and A1.ndtime >'''+convert(nvarchar(25),@T_ED,120)+'''  )OR 
	 (A1.sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and A1.ndtime >'''+ convert(nvarchar(25),@T_ST,120)+''' and A1.ndtime<='''+convert(nvarchar(25),@T_ED,120)+'''  ) or
	 (A1.sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and A1.ndtime >'''+convert(nvarchar(25),@T_ED,120)+'''  and A1.sttime<'''+convert(nvarchar(25),@T_ED,120)+'''  ) )
	and NOT EXISTS ( select * from #T_autodata A2 WITH (NOLOCK)  ----ER0377 Added LOCK
	inner join Machineinformation on Machineinformation.interfaceid=A2.mc
    inner join Plantmachine on Plantmachine.machineid=Machineinformation.machineid
	 where  A2.datatype=1 and  ((  A2.sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and  A2.ndtime <= '''+convert(nvarchar(25),@T_ED,120)+'''  ) OR
	 (A2.sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and  A2.ndtime >'''+convert(nvarchar(25),@T_ED,120)+'''  )OR 
	 (A2.sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and  A2.ndtime >'''+ convert(nvarchar(25),@T_ST,120)+''' and  A2.ndtime<='''+convert(nvarchar(25),@T_ED,120)+'''  ) 
	OR (A2.sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and  A2.ndtime >'''+convert(nvarchar(25),@T_ED,120)+'''  and  A2.sttime<'''+convert(nvarchar(25),@T_ED,120)+'''  ) )
	and A2.sttime<=A1.sttime and A2.ndtime>A1.ndtime and A1.mc=A2.mc'
	select @strsql = @strsql + @strmachine+ @strPlantID
	select @strsql = @strsql + ' )'
	select @strsql = @strsql + @strmachine+ @strPlantID
	print @strsql
	exec (@strsql)

	Select @strsql=''
	select @strsql =' Update #HourlyData set Actual = Isnull(Actual,0) + Isnull(T1.Comp,0) from '
	select @strsql = @strsql + '(Select machineinformation.machineid,T.FromTime,T.ToTime,SUM(Isnull(A.partscount,1)/ISNULL(O.SubOperations,1)) As Comp
	from #T_autodata A WITH (NOLOCK)  ----ER0377 Added LOCK
	Inner join machineinformation on machineinformation.interfaceid=A.mc
	inner join Plantmachine on Plantmachine.machineid=Machineinformation.machineid
	Inner join #HourlyData T on T.machineid=machineinformation.machineid
	Inner join componentinformation C ON A.Comp=C.interfaceid
	Inner join ComponentOperationPricing O WITH (NOLOCK) ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = machineinformation.MachineID
	WHERE A.DataType=1 AND (A.ndtime > T.FromTime  AND A.ndtime <=T.ToTime)'
	select @strsql = @strsql + @strmachine + @strPlantID
	select @strsql = @strsql + ' Group by machineinformation.machineid,T.FromTime,T.ToTime)T1 inner join #HourlyData on #HourlyData.FromTime=T1.FromTime
	and #HourlyData.ToTime=T1.ToTime and #HourlyData.machineid=T1.machineid'
	print @strsql
	exec (@strsql)

	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
	BEGIN
		
		Select @strsql=''
		select @strsql =' Update #HourlyData set Actual = Isnull(Actual,0) - Isnull(T1.Comp,0) from '
		select @strsql = @strsql + '(Select machineinformation.machineid,T1.FromTime,T1.ToTime,SUM(Isnull(A.partscount,1)/ISNULL(O.SubOperations,1)) As Comp
		from #T_autodata A WITH (NOLOCK)  ----ER0377 Added LOCK
		Inner join machineinformation on machineinformation.interfaceid=A.mc
		inner join Plantmachine on Plantmachine.machineid=Machineinformation.machineid
		Inner join #HourlyData T1 on T1.machineid=machineinformation.machineid
		Inner join componentinformation C ON A.Comp=C.interfaceid
		Inner join ComponentOperationPricing O WITH (NOLOCK) ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = machineinformation.MachineID
		CROSS jOIN PlannedDownTimes T
		WHERE A.DataType=1 and T.machine=T1.Machineid
		AND(A.ndtime > T1.FromTime  AND A.ndtime <=T1.ToTime)
		AND(A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)'
		select @strsql = @strsql + @strmachine+ @strPlantID		
		select @strsql = @strsql + ' Group by machineinformation.machineid,T1.FromTime,T1.ToTime)T1 inner join #HourlyData on #HourlyData.FromTime=T1.FromTime
		and #HourlyData.ToTime=T1.ToTime and #HourlyData.machineid=T1.machineid	'
		print @strsql
		exec (@strsql)

	END

	Select @strsql=''	
	Select @strsql= 'insert into #Target(MachineID,machineinterface,Component,Compinterface,Operation,Opninterface,
	msttime,ndtime,FromTm,ToTm,batchid,runtime,autodataid,Targetpercent,Suboperation,StdCycletime)'
	select @strsql = @strsql + ' SELECT machineinformation.machineid, machineinformation.interfaceid,componentinformation.componentid, componentinformation.interfaceid,
	componentoperationpricing.operationno, componentoperationpricing.interfaceid,
	Case when autodata.msttime< T.fromtime then T.fromtime else autodata.msttime end, 
	Case when autodata.ndtime> T.totime then T.totime else autodata.ndtime end,
	T.fromtime,T.totime,0,0,autodata.id,isnull(componentoperationpricing.Targetpercent,100)
	,isnull(componentoperationpricing.Suboperations,1),isnull(componentoperationpricing.Cycletime,0) FROM #T_autodataforDown  autodata WITH (NOLOCK)  ----ER0377 Added LOCK
	INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID 
    INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID  
	INNER JOIN componentoperationpricing WITH (NOLOCK) ON autodata.opn = componentoperationpricing.InterfaceID  ----ER0377 Added LOCK
	AND componentinformation.componentid = componentoperationpricing.componentid
	and componentoperationpricing.machineid=machineinformation.machineid 
	Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid 
	Left Outer Join Employeeinformation EI on EI.interfaceid=autodata.opr 
	Left Outer Join downcodeinformation DI on DI.interfaceid=autodata.dcode 
	Cross join #HourlyData T
	WHERE ((autodata.msttime >= T.fromtime  AND autodata.ndtime <= T.totime)
	OR ( autodata.msttime < T.fromtime  AND autodata.ndtime <= T.totime AND autodata.ndtime >T.fromtime )
	OR ( autodata.msttime >= T.fromtime   AND autodata.msttime <T.totime AND autodata.ndtime > T.totime )
	OR ( autodata.msttime < T.fromtime  AND autodata.ndtime > T.totime ))'
	select @strsql = @strsql + @strmachine + @strPlantID
	select @strsql = @strsql + ' order by autodata.msttime'
	print @strsql
	exec (@strsql)


--	declare @mc_prev nvarchar(50),@comp_prev nvarchar(50),@opn_prev nvarchar(50),@From_Prev datetime
--	declare @mc nvarchar(50),@comp nvarchar(50),@opn nvarchar(50),@Fromtime datetime,@id nvarchar(50)
--	declare @batchid int
--	Declare @autodataid bigint,@autodataid_prev bigint
--	declare @setupcursor  cursor

	declare @From_Prev datetime
	declare @Fromtime datetime
	set @setupcursor=cursor for
	select autodataid,FromTm,MachineID ,Component ,Operation  from #Target order by machineid,msttime
	open @setupcursor
	fetch next from @setupcursor into @autodataid,@Fromtime,@mc,@comp,@opn
	set @autodataid_prev=@autodataid
	set @mc_prev = @mc
	set @comp_prev = @comp
	set @opn_prev = @opn
	SET @From_Prev = @Fromtime
	set @batchid =1

	while @@fetch_status = 0
	begin
	If @mc_prev=@mc and @comp_prev=@comp and @opn_prev=@opn	and @From_Prev = @Fromtime
		begin		
			update #Target set batchid = @batchid where autodataid=@autodataid and MachineID=@mc and Component=@comp and Operation=@opn and FromTm=@Fromtime
			print @batchid
		end
		else
		begin	
			  set @batchid = @batchid+1        
			  update #Target set batchid = @batchid where autodataid=@autodataid and MachineID=@mc and Component=@comp and Operation=@opn and FromTm=@Fromtime
			  set @autodataid_prev=@autodataid 
			  set @mc_prev=@mc 	
			  set @comp_prev=@comp
			  set @opn_prev=@opn	
			  SET @From_Prev = @Fromtime
		end	
		fetch next from @setupcursor into @autodataid,@Fromtime,@mc,@comp,@opn
		
	end
	close @setupcursor
	deallocate @setupcursor

	insert into #FinalTarget (MachineID,Component,operation,machineinterface,Compinterface,Opninterface,Runtime,batchid,msttime,ndtime,FromTm,ToTm,Targetpercent,Suboperation,StdCycletime) 
	Select MachineID,Component,operation,machineinterface,Compinterface,Opninterface,datediff(s,min(msttime),max(ndtime)),batchid,min(msttime),max(ndtime),FromTm,ToTm,Targetpercent,Suboperation,StdCycletime from #Target WITH (NOLOCK)
	group by MachineID,Component,operation,batchid,FromTm,ToTm,Targetpercent,machineinterface,Compinterface,Opninterface,Suboperation,StdCycletime order by batchid 

	
	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y' --ER0363 Added
	BEGIN
			UPDATE #FinalTarget set Runtime =isnull(Runtime,0) - isNull(T1.PPDT ,0)
			FROM(
				Select A.machineinterface,A.Compinterface,A.Opninterface, T.StartTime,T.EndTime ,A.msttime,A.ndtime,Sum
				(CASE
				WHEN A.msttime >= T.StartTime  AND A.ndtime <=T.EndTime  THEN DateDiff(second,A.msttime,A.ndtime) --DR0325 added
				WHEN ( A.msttime < T.StartTime  AND A.ndtime <= T.EndTime  AND A.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,A.ndtime)
				WHEN ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime  AND A.ndtime > T.EndTime  ) THEN DateDiff(second,A.msttime,T.EndTime )
				WHEN ( A.msttime < T.StartTime  AND A.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
				END)  as PPDT
				From #FinalTarget A WITH (NOLOCK)  ----ER0377 Added LOCK
				CROSS jOIN PlannedDownTimes T 
				WHERE T.Machine=A.MachineID AND 
				((A.msttime >= T.StartTime  AND A.ndtime <=T.EndTime)
				OR ( A.msttime < T.StartTime  AND A.ndtime <= T.EndTime AND A.ndtime > T.StartTime )
				OR ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime AND A.ndtime > T.EndTime )
				OR ( A.msttime < T.StartTime  AND A.ndtime > T.EndTime) ) 		
			 group by A.machineinterface,A.Compinterface,A.Opninterface,T.StartTime,T.EndTime,A.msttime,A.ndtime
		)
		as T1 inner join  #FinalTarget on  T1.machineinterface=#FinalTarget.machineinterface and T1.Compinterface=#FinalTarget.Compinterface
			and T1.Opninterface=#FinalTarget.Opninterface and T1.msttime=#FinalTarget.msttime and #FinalTarget.ndtime=T1.ndtime
	END


	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
	BEGIN	
		Update #FinalTarget set Runtime = Isnull(Runtime,0) - Isnull(T3.MLDown,0) from
		(
		Select T1.machineinterface,T1.Compinterface,T1.Opninterface,T1.msttime,T1.ndtime,SUM(DateDiff(second,T1.Asttime,T1.Andtime))-isnull(SUM(T2.PPDT),0) as MLDown from	
			(select Autodata.id,T.machineinterface,T.Compinterface,T.Opninterface,T.FromTm,T.ToTm,T.msttime,T.ndtime,
			case when autodata.sttime<T.msttime then T.msttime else autodata.sttime end as Asttime,
			case when autodata.ndtime>T.ndtime then T.ndtime else autodata.ndtime end as Andtime
						from #T_autodata autodata  WITH (NOLOCK)  ----ER0377 Added LOCK
						INNER JOIN #FinalTarget T WITH (NOLOCK) on T.machineinterface=Autodata.mc and T.Compinterface=Autodata.comp  ----ER0377 Added LOCK
						and T.Opninterface = Autodata.opn
						INNER JOIN DownCodeInformation ON AutoData.DCode = DownCodeInformation.InterfaceID
						WHERE autodata.DataType=2 AND
						((autodata.sttime >= T.msttime  AND autodata.ndtime <=T.ndtime)
						OR ( autodata.sttime < T.msttime  AND autodata.ndtime <= T.ndtime AND autodata.ndtime > T.msttime )
						OR ( autodata.sttime >= T.msttime   AND autodata.sttime <T.ndtime AND autodata.ndtime > T.ndtime )
						OR ( autodata.sttime < T.msttime  AND autodata.ndtime > T.ndtime))
						AND (downcodeinformation.availeffy = 1)
			  ) AS T1
			Left Outer join
			(
					SELECT autodata.id
					,F.msttime,F.ndtime,F.machineinterface,F.Compinterface,F.Opninterface,
					SUM
					(CASE
					WHEN (autodata.sttime >= F.msttime  AND autodata.ndtime <=F.ndtime)  THEN autodata.loadunload
					WHEN ( autodata.sttime < F.msttime  AND autodata.ndtime <= F.ndtime  AND autodata.ndtime > F.msttime ) THEN DateDiff(second,F.msttime,autodata.ndtime)
					WHEN ( autodata.sttime >= F.msttime   AND autodata.sttime <F.ndtime  AND autodata.ndtime > F.ndtime  ) THEN DateDiff(second,autodata.sttime,F.ndtime )
					WHEN ( autodata.sttime < F.msttime  AND autodata.ndtime > F.ndtime ) THEN DateDiff(second,F.msttime,F.ndtime )
					END ) as PPDT
					FROM #T_autodata AutoData WITH (NOLOCK)  ----ER0377 Added LOCK
					CROSS jOIN #PlannedDownTimes T
					 INNER JOIN #FinalTarget F WITH (NOLOCK) on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn  ----ER0377 Added LOCK
					 inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
					WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
					((autodata.sttime >= F.msttime  AND autodata.ndtime <=F.ndtime)
						OR ( autodata.sttime < F.msttime  AND autodata.ndtime <= F.ndtime AND autodata.ndtime > F.msttime )
						OR ( autodata.sttime >= F.msttime   AND autodata.sttime <F.ndtime AND autodata.ndtime > F.ndtime )
						OR ( autodata.sttime < F.msttime  AND autodata.ndtime > F.ndtime))
						AND
							((F.msttime >= T.StartTime  AND F.ndtime <=T.EndTime)
							OR ( F.msttime < T.StartTime  AND F.ndtime <= T.EndTime AND f.ndtime > T.StartTime )
							OR ( F.msttime >= T.StartTime   AND F.msttime <T.EndTime AND F.ndtime > T.EndTime )
							OR ( F.msttime < T.StartTime  AND f.ndtime > T.EndTime) )  AND (downcodeinformation.availeffy = 1) 
						group  by autodata.id,F.msttime,F.ndtime,F.machineinterface,F.Compinterface,F.Opninterface			
				) As T2 on T1.id=T2.id and T1.msttime=T2.msttime and T1.ndtime=T2.ndtime and T1.machineinterface=T2.machineinterface 
				and T1.Compinterface=T2.Compinterface and T1.Opninterface=T2.Opninterface
				 group by T1.msttime,T1.ndtime,T1.machineinterface,T1.Compinterface,T1.Opninterface)T3  inner join  #FinalTarget on  T3.machineinterface=#FinalTarget.machineinterface and T3.Compinterface=#FinalTarget.Compinterface
		and T3.Opninterface=#FinalTarget.Opninterface and T3.msttime=#FinalTarget.msttime and T3.ndtime=#FinalTarget.ndtime

END


	--If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
	--BEGIN

	--	Update #FinalTarget set Runtime = Isnull(Runtime,0) - Isnull(T1.MLDown,0) from
	--	(
	--		select T.machineinterface,T.Compinterface,T.Opninterface,T.FromTm,T.ToTm,T.msttime,T.ndtime,SUM
	--			(CASE
	--			WHEN (autodata.sttime >= T.msttime  AND autodata.ndtime <=T.ndtime)  THEN autodata.loadunload
	--			WHEN ( autodata.sttime < T.msttime  AND autodata.ndtime <= T.ndtime  AND autodata.ndtime > T.msttime ) THEN DateDiff(second,T.msttime,autodata.ndtime)
	--			WHEN ( autodata.sttime >= T.msttime   AND autodata.sttime <T.ndtime  AND autodata.ndtime > T.ndtime  ) THEN DateDiff(second,autodata.sttime,T.ndtime )
	--			WHEN ( autodata.sttime < T.msttime  AND autodata.ndtime > T.ndtime ) THEN DateDiff(second,T.msttime,T.ndtime )
	--			END ) as MLDown
	--		from autodata  
	--		INNER JOIN #FinalTarget T on T.machineinterface=Autodata.mc and T.Compinterface=Autodata.comp
	--		and T.Opninterface = Autodata.opn
	--		INNER JOIN DownCodeInformation ON AutoData.DCode = DownCodeInformation.InterfaceID
	--		WHERE autodata.DataType=2 AND
	--		((autodata.sttime >= T.msttime  AND autodata.ndtime <=T.ndtime)
	--		OR ( autodata.sttime < T.msttime  AND autodata.ndtime <= T.ndtime AND autodata.ndtime > T.msttime )
	--		OR ( autodata.sttime >= T.msttime   AND autodata.sttime <T.ndtime AND autodata.ndtime > T.ndtime )
	--		OR ( autodata.sttime < T.msttime  AND autodata.ndtime > T.ndtime))
	--		AND (downcodeinformation.availeffy = 1)
	--		group by T.machineinterface,T.Compinterface,T.Opninterface,T.FromTm,T.ToTm,T.msttime,T.ndtime
	--	)T1 inner join  #FinalTarget on  T1.machineinterface=#FinalTarget.machineinterface and T1.Compinterface=#FinalTarget.Compinterface
	--	and T1.Opninterface=#FinalTarget.Opninterface and T1.FromTm=#FinalTarget.FromTm and #FinalTarget.ToTm=T1.ToTm
	--	and T1.msttime=#FinalTarget.msttime and T1.ndtime=#FinalTarget.ndtime and #FinalTarget.Runtime>=Isnull(T1.MLDown,0)
	--END

	Update #FinalTarget set Target = Isnull(Target,0) + isnull(T1.targetcount,0) from
	(Select machineinterface,Compinterface,Opninterface,msttime,ndtime,sum(((Runtime*suboperation)/stdcycletime)*isnull(targetpercent,100) /100) as targetcount
	 from #FinalTarget group by machineinterface,Compinterface,Opninterface,msttime,ndtime)T1 inner join #FinalTarget on  T1.machineinterface=#FinalTarget.machineinterface and T1.Compinterface=#FinalTarget.Compinterface
	and T1.Opninterface=#FinalTarget.Opninterface and T1.msttime=#FinalTarget.msttime and #FinalTarget.ndtime=T1.ndtime

	Update #HourlyData set Target = Isnull(Target,0) + isnull(T1.TCount,0) from 
	(Select machineid,FromTm,ToTm,Sum(Target) as Tcount from #FinalTarget
	 Group by machineid,FromTm,ToTm)T1 inner join #HourlyData on #HourlyData.machineid=T1.machineid and
	 #HourlyData.Fromtime=T1.FromTm and  #HourlyData.Totime=T1.ToTm

	Update #HourlyData set TargetTotal = Isnull(TargetTotal,0) + isnull(T1.TCount,0),ActualTotal= Isnull(ActualTotal,0) + isnull(T1.ACount,0) from 
	(Select machineid,Sum(Target) as Tcount,Sum(Actual) as Acount from #HourlyData
	 Group by machineid)T1 inner join #HourlyData on #HourlyData.machineid=T1.machineid

/* ER0377
	SELECT
	Plantid,
	#CockpitData.machineid,
	ColorCode,
	HelpCode1,HelpCode2,HelpCode3,HelpCode4,
	ProductionEfficiency,
	AvailabilityEfficiency,
	OverAllEfficiency,
	Components,
	Utilisedtime,
	PEGreen,
	PERed,
	AEGreen,
	AERed,
	OEGreen,
	OERed,
	Fromtime,
	Totime,
	Round(#HourlyData.Target,0) as Rated,
	Actual,
	Round(TargetTotal,0) as TargetTotal,
	ActualTotal
	FROM #CockpitData inner join #HourlyData on #HourlyData.machineid=#CockpitData.machineid
	order by Plantid,#HourlyData.machineid,#HourlyData.Fromtime,#HourlyData.Totime
ER0377 */

--ER0377
	SELECT
	Plantid,
	#CockpitData.machineid,
	Fromtime,
	Totime,
	Round(#HourlyData.Target,0) as Rated,
	Actual,
	Round(TargetTotal,0) as TargetTotal,
	ActualTotal
	FROM #CockpitData inner join #HourlyData on #HourlyData.machineid=#CockpitData.machineid
	order by Plantid,#HourlyData.machineid,#HourlyData.Fromtime,#HourlyData.Totime
--ER0377

End



If @param = '3rd Screen'
BEGIN

		select @strsql=''
		SELECT @strsql= @strsql + 'insert into #HelpCode(Machineid,HelpDescription,HelpCode,Action1,Action2,Starttime,Endtime)  
		Select T.Machineid,T.Help_Description,T.HelpCode,H.Action1,H.Action2,H.Starttime,H.Endtime from(
		select Machineinformation.Machineid,Max(HD.ID) as ID,HM.Help_Description
		,HD.HelpCode from helpcodedetails HD WITH (NOLOCK)' -- ----ER0377 Added LOCK
		SELECT @strsql= @strsql + ' Inner join HelpCodeMaster HM on HD.HelpCode=HM.Help_code
		Inner join Machineinformation on HD.Machineid=Machineinformation.interfaceid '
		SELECT @strsql = @strsql + @strmachine  
	    SELECT @strsql = @strsql +  ' group by Machineinformation.Machineid,HM.Help_Description,HD.HelpCode)T 
		inner join helpcodedetails H on T.ID = H.ID
		where isnull(H.Action2,''a'') <> ''04'''
		print @strsql
		exec (@strsql) 
	

		Update #Cockpitdata set HelpCode1 = T1.Val1,HelpCode1TS=T1.ActionTS from
		(Select Machineid,
		 Case when Action1 = '01' and  Isnull(Action2,'a')='a' then 'Red'
		 when Action1 = '01' and  Action2 ='02' then 'Yellow'
		 when Action1 = '01' and  Action2 ='03' then 'Green'
		 when Action1 = '01' and  Action2 ='04' then 'White' end as Val1,
		 Case when Action1 = '01' and  Isnull(Action2,'a')='a' then datediff(second,starttime,@CurrTime)
		 when Action1 = '01' and  Action2 in('02','03','04') then datediff(second,starttime,case when endtime>@CurrTime then @CurrTime else endtime end) END as ActionTS
		 from #HelpCode
		 Where  HelpCode = '01')T1
		inner join #CockpitData on T1.MachineID = #CockpitData.MachineID

		Update #Cockpitdata set HelpCode2=T1.Val2,HelpCode2TS=T1.ActionTS from
		(Select Machineid,
		 Case when Action1 = '01' and  Isnull(Action2,'a')='a' then 'Red'
		 when Action1 = '01' and  Action2 ='02' then 'Yellow'
		 when Action1 = '01' and  Action2 ='03' then 'Green'
		 when Action1 = '01' and  Action2 ='04' then 'White' end as Val2,
		 Case when Action1 = '01' and  Isnull(Action2,'a')='a' then datediff(second,starttime,@CurrTime)
		 when Action1 = '01' and  Action2 in('02','03','04') then datediff(second,starttime,case when endtime>@CurrTime then @CurrTime else endtime end) END as ActionTS from #HelpCode
		 Where  HelpCode = '02')T1
		inner join #CockpitData on T1.MachineID = #CockpitData.MachineID

		Update #Cockpitdata set HelpCode3=T1.Val3,HelpCode3TS=T1.ActionTS from
		(Select Machineid,
		 Case when Action1 = '01' and  Isnull(Action2,'a')='a' then 'Red'
		 when Action1 = '01' and  Action2 ='02' then 'Yellow'
		 when Action1 = '01' and  Action2 ='03' then 'Green'
		 when Action1 = '01' and  Action2 ='04' then 'White' end as  Val3,
		 Case when Action1 = '01' and  Isnull(Action2,'a')='a' then datediff(second,starttime,@CurrTime)
		 when Action1 = '01' and  Action2 in('02','03','04') then datediff(second,starttime,case when endtime>@CurrTime then @CurrTime else endtime end) END as ActionTS from #HelpCode
		 Where  HelpCode = '03')T1
		inner join #CockpitData on T1.MachineID = #CockpitData.MachineID

		Update #Cockpitdata set HelpCode4=T1.Val4,HelpCode4TS=T1.ActionTS from
		(Select Machineid,
		 Case when Action1 = '01' and  Isnull(Action2,'a')='a' then 'Red'
		  when Action1 = '01' and  Action2 ='02' then 'Yellow'
		  when Action1 = '01' and  Action2 ='03' then 'Green'
		  when Action1 = '01' and  Action2 ='04' then 'White' end as Val4,
		  Case when Action1 = '01' and  Isnull(Action2,'a')='a' then datediff(second,starttime,@CurrTime)
		 when Action1 = '01' and  Action2 in('02','03','04') then datediff(second,starttime,case when endtime>@CurrTime then @CurrTime else endtime end) END as ActionTS from #HelpCode
		 Where  HelpCode = '04')T1
		inner join #CockpitData on T1.MachineID = #CockpitData.MachineID


		Set @Type40Threshold = (Select isnull(Valueintext2,5)*60 from shopdefaults where parameter='ANDONStatusThreshold' and valueintext = 'Type40Threshold')
		Set @Type1Threshold = (Select isnull(Valueintext2,5)*60 from shopdefaults where parameter='ANDONStatusThreshold' and valueintext = 'Type1Threshold')
		Set @Type11Threshold = (Select isnull(Valueintext2,5)*60 from shopdefaults where parameter='ANDONStatusThreshold' and valueintext = 'Type11Threshold')
		print @Type40Threshold
		print @Type1Threshold
		print @Type11Threshold

		Insert into #machineRunningStatus
		select fd.MachineID,fd.MachineInterface,sttime,ndtime,datatype,'White',0,'1900-01-01',0 from rawdata
		inner join (select mc,max(slno) as slno from rawdata WITH (NOLOCK) where sttime<@currtime and isnull(ndtime,'1900-01-01')<@currtime
		and datatype in(2,42,40,41,1,11) group by mc ) t1 on t1.mc=rawdata.mc and t1.slno=rawdata.slno
		right outer join #CockpitData fd on fd.MachineInterface = rawdata.mc
		order by rawdata.mc

		update #machineRunningStatus set ColorCode = case when (datediff(second,sttime,@CurrTime)- @Type11Threshold)>0  then 'Red' else 'Green' end where datatype in (11)
		update #machineRunningStatus set ColorCode = 'Green' where datatype in (41)
		update #machineRunningStatus set ColorCode = 'Red' where datatype in (42,2)

		update #machineRunningStatus set ColorCode = t1.ColorCode from (
		Select mrs.MachineID,Case when (
		case when datatype = 40 then datediff(second,sttime,@CurrTime)- @Type40Threshold
		when datatype = 1 then datediff(second,ndtime,@CurrTime)- @Type1Threshold
		end) > 0 then 'Red' else 'Green' end as ColorCode
		from #machineRunningStatus mrs 
		where  datatype in (40,1)
		) as t1 inner join #machineRunningStatus on t1.MachineID = #machineRunningStatus.MachineID

		Update #machineRunningStatus set DownTime = Isnull(#machineRunningStatus.DownTime,0) + Isnull(t2.DownTime,0)
		,lastDownstart=t2.LastRecord
		from (
			Select mrs.MachineID,
			dateDiff(second,t1.LastRecord,@CurrTime) as DownTime,t1.LastRecord
			from #machineRunningStatus mrs 
			inner join (
				Select mrs.MachineID,
				case when (datatype = 1) then dateadd(s,@Type1Threshold,ndtime)
				when (datatype = 2)or(datatype = 42) then ndtime
				when datatype = 40 then dateadd(s,@Type40Threshold,sttime)
				when datatype=11 then dateadd(s,@Type11Threshold,sttime)
				when datatype=41 then sttime end as LastRecord
				from #machineRunningStatus mrs
			) as t1 on t1.machineID = mrs.machineID 
		) as t2 inner join #machineRunningStatus on t2.MachineID = #machineRunningStatus.MachineID


		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' 
		BEGIN
			update #machineRunningStatus set PDT = Isnull(fd.PDT,0) + isnull(T2.pdt,0)
			from
			(
			Select T1.machineid,sum(datediff(ss,T1.StartTime,t1.EndTime)) as pdt 
			from (
			select fD.machineid,
			Case when  fd.lastDownstart <= pdt.StartTime then pdt.StartTime else  lastDownstart End as StartTime,
			Case when @currtime >= pdt.EndTime then pdt.EndTime else @currtime End as EndTime
			From Planneddowntimes pdt
			inner join #machineRunningStatus fD on fd.machineid=Pdt.machine
			where PDTstatus = 1  and 
			((pdt.StartTime >= fd.lastDownstart and pdt.EndTime <= @currtime)or
			(pdt.StartTime < fd.lastDownstart and pdt.EndTime > fd.lastDownstart and pdt.EndTime <=@currtime)or
			(pdt.StartTime >= fd.lastDownstart and pdt.StartTime <@currtime and pdt.EndTime >@currtime) or
			(pdt.StartTime <  fd.lastDownstart and pdt.EndTime >@currtime))
			)T1  group by T1.machineid )T2 inner join #machineRunningStatus fd on fd.machineid=t2.machineid	
				
			update #machineRunningStatus set ColorCode = Case when Downtime-PDT=0 then 'Blue' else Colorcode end 
		end

		update #machineRunningStatus set ColorCode ='Red' where isnull(sttime,'1900-01-01')='1900-01-01'
	
		Update #CockpitData set Colorcode = Isnull(#CockpitData.Colorcode,'') +  isnull(T1.Color,'') from
		(select Machineid,Colorcode as color from #machineRunningStatus)T1
		inner join #CockpitData on T1.MachineID = #CockpitData.MachineID

		SELECT
		Plantid,
		MachineID,
		ColorCode,
		HelpCode1,HelpCode2,HelpCode3,HelpCode4,dbo.f_FormatTime(HelpCode1TS,'hh:mm') as HelpCode1TS,
		dbo.f_FormatTime(HelpCode2TS,'hh:mm') as HelpCode2TS,dbo.f_FormatTime(HelpCode3TS,'hh:mm') as HelpCode3TS,dbo.f_FormatTime(HelpCode4TS,'hh:mm') as HelpCode4TS
		FROM #CockpitData
		order by Plantid,machineid asc
END

If @Param='3rd Screen PlantOEE' or @Param='3rd Screen PlantOEEShiftwise'
BEGIN

/*******************************      Utilised Calculation Starts ***************************************************/
		UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
		from
		(select      mc,sum(cycletime+loadunload) as cycle
		from #T_autodata autodata WITH (NOLOCK) -- ----ER0377 Added LOCK
		where (autodata.msttime>=@StartTime)
		and (autodata.ndtime<=@EndTime)
		and (autodata.datatype=1)
		group by autodata.mc
		) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface
		-- Type 2
		UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
		from
		(select  mc,SUM(DateDiff(second, @StartTime, ndtime)) cycle
		from #T_autodata autodata WITH (NOLOCK) -- ----ER0377 Added LOCK
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
		from #T_autodata autodata WITH (NOLOCK) -- ----ER0377 Added LOCK
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
		sum(DateDiff(second, @StartTime, @EndTime)) cycle from #T_autodata autodata WITH (NOLOCK) -- ----ER0377 Added LOCK
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
		From #T_autodata AutoData WITH (NOLOCK) INNER Join -- ----ER0377 Added LOCK
			(Select mc,Sttime,NdTime From #T_autodata  AutoData
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
		From #T_autodata AutoData WITH (NOLOCK) INNER Join -- ----ER0377 Added LOCK
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
		From #T_autodata AutoData WITH (NOLOCK) INNER Join -- ----ER0377 Added LOCK
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

		------------------------------------  ----ER0377 Added  From Here ---------------------------------
			UPDATE #PLD set pPlannedDT =isnull(pPlannedDT,0) + isNull(TT.PPDT ,0)
			FROM(
				--Production Time in PDT
				SELECT autodata.MC,SUM
					(CASE
		--			WHEN autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.cycletime+autodata.loadunload) --DR0325 Commented
					WHEN autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN DateDiff(second,autodata.msttime,autodata.ndtime) --DR0325 Added
					WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
					WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )
					WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
					END)  as PPDT
					FROM (select M.machineid,mc,msttime,ndtime from #T_autodata autodata WITH (NOLOCK) -- ----ER0377 Added LOCK
						inner join machineinformation M on M.interfaceid=Autodata.mc
						 where autodata.DataType=1 And 
						((autodata.msttime >= @starttime  AND autodata.ndtime <=@Endtime)
						OR ( autodata.msttime < @starttime  AND autodata.ndtime <= @Endtime AND autodata.ndtime > @starttime )
						OR ( autodata.msttime >= @starttime   AND autodata.msttime <@Endtime AND autodata.ndtime > @Endtime )
						OR ( autodata.msttime < @starttime  AND autodata.ndtime > @Endtime))
						)
				AutoData  inner jOIN #PlannedDownTimes T on T.Machineid=AutoData.machineid -- ----ER0377 Added LOCK
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
				(Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, 
				A.datatype from #T_autodata A WITH (NOLOCK) -- ----ER0377 Added LOCK
				Where A.DataType=2
				and exists 
					(
					Select B.Sttime,B.NdTime,B.mc From #T_autodata B WITH (NOLOCK) -- ----ER0377 Added LOCK
					Where B.mc = A.mc and
					B.DataType=1 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And
					(B.msttime >= @starttime AND B.ndtime <= @Endtime) and
					(B.sttime < A.sttime) AND (B.ndtime > A.ndtime) 
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
				(Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, 
				A.datatype from #T_autodata A WITH (NOLOCK) -- ----ER0377 Added LOCK
				Where A.DataType=2
				and exists 
				(
				Select B.Sttime,B.NdTime From #T_autodata B WITH (NOLOCK) -- ----ER0377 Added LOCK
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
				(Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine,
				 A.sttime, ndtime, A.datatype from #T_autodata A WITH (NOLOCK) -- ----ER0377 Added LOCK
				Where A.DataType=2
				and exists 
				(
				Select B.Sttime,B.NdTime From #T_autodata B WITH (NOLOCK) -- ----ER0377 Added LOCK
				Where B.mc = A.mc and
				B.DataType=1 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And
				(B.sttime >= @StartTime And B.ndtime > @EndTime and B.sttime <@EndTime) and
				((B.Sttime < A.sttime  )And ( B.ndtime > A.ndtime) AND (A.msttime < @EndTime))
				)
				)as T1 inner join
		--		Inner join #PlannedDownTimes T
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
			(Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime,
			 A.datatype from #T_autodata A WITH (NOLOCK) -- ----ER0377 Added LOCK
			Where A.DataType=2
			and exists 
			(
			Select B.Sttime,B.NdTime From #T_autodata B WITH (NOLOCK) -- ----ER0377 Added LOCK
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
		  ------------------------------------  ----ER0377 Added Till Here --------------------------------
			
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
				from #T_autodata autodata WITH (NOLOCK) -- ----ER0377 Added LOCK 
				INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
				where (autodata.msttime>=@StartTime)
				and (autodata.ndtime<=@EndTime)
				and (autodata.datatype=2)
				and (downcodeinformation.availeffy = 1)
				group by autodata.mc) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface
				-- Type 2
				UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
				from
				(select      mc,sum(
				CASE WHEN DateDiff(second, @StartTime, ndtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
				then isnull(downcodeinformation.Threshold,0)
				ELSE DateDiff(second, @StartTime, ndtime)
				END)loss
				from #T_autodata autodata WITH (NOLOCK) -- ----ER0377 Added LOCK
				INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
				where (autodata.sttime<@StartTime)
				and (autodata.ndtime>@StartTime)
				and (autodata.ndtime<=@EndTime)
				and (autodata.datatype=2)
				and (downcodeinformation.availeffy = 1)
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
				from #T_autodata autodata WITH (NOLOCK) -- ----ER0377 Added LOCK
				INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
				where (autodata.msttime>=@StartTime)
				and (autodata.sttime<@EndTime)
				and (autodata.ndtime>@EndTime)
				and (autodata.datatype=2)
				and (downcodeinformation.availeffy = 1)
				group by autodata.mc
				) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface
				-- Type 4
				UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
				from
				(select mc,sum(
				CASE WHEN DateDiff(second, @StartTime, @Endtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
				then isnull(downcodeinformation.Threshold,0)
				ELSE DateDiff(second, @StartTime, @Endtime)
				END)loss
				from #T_autodata autodata WITH (NOLOCK) -- ----ER0377 Added LOCK
				INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
				where autodata.msttime<@StartTime
				and autodata.ndtime>@EndTime
				and (autodata.datatype=2)
				and (downcodeinformation.availeffy = 1)
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
				from #T_autodata autodata WITH (NOLOCK) -- ----ER0377 Added LOCK
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
		End

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
			from #T_autodata autodata WITH (NOLOCK) -- ----ER0377 Added LOCK
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
				FROM #T_autodata AutoData WITH (NOLOCK) -- ----ER0377 Added LOCK
				CROSS jOIN #PlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
				WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
					(
					(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
					OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
					OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
					OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
					)AND (downcodeinformation.availeffy = 0)
				group by autodata.mc
			) as TT INNER JOIN #PLD ON TT.mc = #PLD.MachineInterface

			---step 3
			---Management loss calculation
			---IN T1 Select get all the downtimes which is of type management loss
			---IN T2  get the time to be deducted from the cycle if the cycle is overlapping with the PDT. And it should be ML record
			---In T3 Get the real management loss , and time to be considered as real down for each cycle(by comaring with the ML threshold)
			---In T4 consolidate everything at machine level and update the same to #CockpitData for ManagementLoss and MLDown
			
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
				from #T_autodata autodata WITH (NOLOCK) -- ----ER0377 Added LOCK
				inner join downcodeinformation D
				on autodata.dcode=D.interfaceid where autodata.datatype=2 AND
				(
				(autodata.sttime>=@StartTime  and  autodata.ndtime<=@EndTime)
				OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
				OR (autodata.sttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
				OR (autodata.sttime<@StartTime and autodata.ndtime>@EndTime )
				) AND (D.availeffy = 1)) as T1 	
			left outer join
			(SELECT autodata.id,
					   sum(CASE
					WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
					WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
					WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
					WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
					END ) as PPDT
				FROM #T_autodata AutoData WITH (NOLOCK) -- ----ER0377 Added LOCK
				CROSS jOIN #PlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
				WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
					(
					(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
					OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
					OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
					OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
					)
					AND (downcodeinformation.availeffy = 1) group  by autodata.id ) as T2 on T1.id=T2.id ) as T3  group by T3.mc
			) as t4 inner join #CockpitData on t4.mc = #CockpitData.machineinterface
			UPDATE #CockpitData SET downtime = isnull(downtime,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)
		END

		---mod 4: Till here Handling interaction between PDT and downtime . Also interaction between PDT and Management Loss
		---mod 4:If Ignore_Dtime_4m_PLD<> Y and Ignore_Dtime_4m_PLD<> N
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
				FROM  #T_autodata AutoData WITH (NOLOCK) -- ----ER0377 Added LOCK
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

		--************************************ Down and Management  Calculation Ends ******************************************
		---mod 4
		-- Get the value of CN
		-- Type 1
		/* Changed by SSK to Combine SubOperations*/
		UPDATE #CockpitData SET CN = isnull(CN,0) + isNull(t2.C1N1,0)
		from
		(select mc,
		SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))* autodata.partscount) C1N1
		FROM #T_autodata autodata WITH (NOLOCK) -- ----ER0377 Added LOCK
		INNER JOIN
		componentoperationpricing WITH (NOLOCK) ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN ----ER0377 Added LOCK
		componentinformation ON autodata.comp = componentinformation.InterfaceID AND
		componentoperationpricing.componentid = componentinformation.componentid
		--mod 2
		inner join machineinformation on machineinformation.interfaceid=autodata.mc
		and componentoperationpricing.machineid=machineinformation.machineid
		--mod 2
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
				From #T_autodata A WITH (NOLOCK) -- ----ER0377 Added LOCK
				Inner join machineinformation M on M.interfaceid=A.mc
				Inner join componentinformation C ON A.Comp=C.interfaceid
				Inner join ComponentOperationPricing O WITH (NOLOCK) ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID ----ER0377 Added LOCK
				Cross jOIN #PlannedDownTimes T
				WHERE A.DataType=1 AND T.MachineInterface=A.mc
				AND(A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)
				AND(A.ndtime > @StartTime  AND A.ndtime <=@EndTime)
				Group by mc
			) as T2
			inner join #CockpitData  on t2.mc = #CockpitData.machineinterface
		END

		--Calculation of PartsCount Begins..
		UPDATE #CockpitData SET components = ISNULL(components,0) + ISNULL(t2.comp,0)
		From
		(
			Select mc,SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp
				   From (select mc,SUM(autodata.partscount)AS OrginalCount,comp,opn from  #T_autodata autodata WITH (NOLOCK) -- ----ER0377 Added LOCK
				   where (autodata.ndtime>@StartTime) and (autodata.ndtime<=@EndTime) and (autodata.datatype=1)
				   Group By mc,comp,opn) as T1
			Inner join componentinformation C on T1.Comp = C.interfaceid
			Inner join ComponentOperationPricing O WITH (NOLOCK) ON  T1.Opn = O.interfaceid and C.Componentid=O.componentid ----ER0377 Added LOCK
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
				select mc,SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp From (
					select mc,Sum(ISNULL(PartsCount,1))AS OrginalCount,comp,opn from #T_autodata autodata WITH (NOLOCK) -- ----ER0377 Added LOCK
					CROSS JOIN #PlannedDownTimes T
					WHERE autodata.DataType=1 And T.MachineInterface = autodata.mc
					AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)
					AND (autodata.ndtime > @StartTime  AND autodata.ndtime <=@EndTime)
					Group by mc,comp,opn
				) as T1
			Inner join Machineinformation M on M.interfaceID = T1.mc
			Inner join componentinformation C on T1.Comp=C.interfaceid
			Inner join ComponentOperationPricing O WITH (NOLOCK) ON T1.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineID = M.MachineID ----ER0377 Added LOCK
			GROUP BY MC
			) as T2 inner join #CockpitData on T2.mc = #CockpitData.machineinterface
		END

		UPDATE #CockpitData
			SET UtilisedTime=(UtilisedTime-ISNULL(#PLD.pPlannedDT,0)+isnull(#PLD.IPlannedDT,0)),
				DownTime=(DownTime-ISNULL(#PLD.dPlannedDT,0))
			From #CockpitData Inner Join #PLD on #PLD.Machineid=#CockpitData.Machineid

		-- Calculate efficiencies
		UPDATE #CockpitData
		SET
			ProductionEfficiency = (CN/UtilisedTime) ,
			AvailabilityEfficiency = (UtilisedTime)/(UtilisedTime + DownTime - ManagementLoss),
			TotalTime = DateDiff(second, @StartTime, @EndTime)
		WHERE UtilisedTime <> 0

		UPDATE #CockpitData
		SET
			OverAllEfficiency = Round((ProductionEfficiency * AvailabilityEfficiency)*100,0),
			ProductionEfficiency = Round(ProductionEfficiency * 100,0) ,
			AvailabilityEfficiency = Round(AvailabilityEfficiency * 100,0)


	select  Plantinformation.PlantID,Round(isnull(T.OEE,0.00),0) as OEE,Round(isnull(T.AE,0.00),0) as AE,Round(isnull(T.PE,0.00),0) as PE from
	(select plantmachine.PlantID,
	Avg(E.OverallEfficiency) as OEE,
	Avg(E.AvailabilityEfficiency) as AE,
	Avg(E.ProductionEfficiency) as PE from #CockpitData E
	inner join plantmachine
	on  E.MachineID = plantmachine.MachineID
	group by plantmachine.PlantID
	)as T Right outer Join Plantinformation on T.PlantID = plantinformation.PlantID
	order by plantinformation.PlantID

END

If @param= '3rd Screen DownPareto' or @Param='3rd Screen DownParetoShiftwise'
BEGIN

		select @strsql = ''
		select @strsql = 'INSERT INTO #DownTimeData (MachineID,McInterfaceid, DownID, DownTime,DownFreq) SELECT Machineinformation.MachineID AS MachineID,Machineinformation.interfaceid, downcodeinformation.downid AS DownID, 0,0'
		select @strsql = @strsql+' FROM Machineinformation CROSS JOIN downcodeinformation LEFT OUTER JOIN PlantMachine ON PlantMachine.MachineID=Machineinformation.MachineID '
		select @strsql = @strsql+' Where MachineInformation.interfaceid > ''0'' '
		select @strsql = @strsql + @strPlantID +@strmachine + @StrTPMMachines + ' ORDER BY  downcodeinformation.downid, Machineinformation.MachineID'
		exec (@strsql)
		--********************************************* Get Down Time Details *******************************************************
		--Type 1,2,3 and 4.
		select @strsql = ''
		select @strsql = @strsql + 'UPDATE #DownTimeData SET downtime = isnull(DownTime,0) + isnull(t2.down,0) '
		select @strsql = @strsql + ' FROM'
		select @strsql = @strsql + ' (SELECT mc,--count(mc)as dwnfrq,
		SUM(CASE
		WHEN (autodata.sttime>='''+convert(varchar(20),@starttime)+''' and autodata.ndtime<='''+convert(varchar(20),@endtime)+''' ) THEN loadunload
		WHEN (autodata.sttime<'''+convert(varchar(20),@starttime)+''' and autodata.ndtime>'''+convert(varchar(20),@starttime)+'''and autodata.ndtime<='''+convert(varchar(20),@endtime)+''') THEN DateDiff(second, '''+convert(varchar(20),@StartTime)+''', ndtime)
		WHEN (autodata.sttime>='''+convert(varchar(20),@starttime)+'''and autodata.sttime<'''+convert(varchar(20),@endtime)+''' and autodata.ndtime>'''+convert(varchar(20),@endtime)+''') THEN DateDiff(second, stTime, '''+convert(varchar(20),@Endtime)+''')
		ELSE DateDiff(second,'''+convert(varchar(20),@starttime)+''','''+convert(varchar(20),@endtime)+''')
		END) as down
		,downcodeinformation.downid as downid'
		select @strsql = @strsql + ' from'
		select @strsql = @strsql + '  #T_autodata autodata INNER JOIN'
		select @strsql = @strsql + ' machineinformation ON autodata.mc = machineinformation.InterfaceID Left Outer Join PlantMachine ON PlantMachine.MachineID=machineinformation.MachineID INNER JOIN'
		select @strsql = @strsql + ' componentinformation ON autodata.comp = componentinformation.InterfaceID INNER JOIN'
		select @strsql = @strsql + ' employeeinformation ON autodata.opr = employeeinformation.interfaceid INNER JOIN'
		select @strsql = @strsql + ' downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid'
		select @strsql = @strsql + ' where  datatype=2 AND ((autodata.sttime>='''+convert(varchar(20),@starttime)+''' and autodata.ndtime<='''+convert(varchar(20),@endtime)+''' )OR
		(autodata.sttime<'''+convert(varchar(20),@starttime)+''' and autodata.ndtime>'''+convert(varchar(20),@starttime)+'''and autodata.ndtime<='''+convert(varchar(20),@endtime)+''')OR
		(autodata.sttime>='''+convert(varchar(20),@starttime)+'''and autodata.sttime<'''+convert(varchar(20),@endtime)+''' and autodata.ndtime>'''+convert(varchar(20),@endtime)+''')OR
		(autodata.sttime<'''+convert(varchar(20),@starttime)+''' and autodata.ndtime>'''+convert(varchar(20),@endtime)+'''))'
		select @strsql = @strsql  + @strPlantID + @strmachine
		select @strsql = @strsql + ' group by autodata.mc,downcodeinformation.downid )'
		select @strsql = @strsql + ' as t2 inner join #DownTimeData on t2.mc=#DownTimeData.McInterfaceid and t2.downid=#DownTimeData.downid'
		exec (@strsql)
		--*********************************************************************************************************************
		--mod 4
		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
		BEGIN
			UPDATE #DownTimeData set DownTime =isnull(DownTime,0) - isNull(TT.PPDT ,0)
			FROM(
				--Production PDT
				SELECT autodata.MC,DownID, SUM
					   (CASE
					WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
					WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
					WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
					WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
					END ) as PPDT
				FROM #T_autodata AutoData CROSS jOIN #PlannedDownTimes T
				Inner Join DownCodeInformation On AutoData.DCode=DownCodeInformation.InterfaceID
				WHERE autodata.DataType=2 AND T.MachineInterface = AutoData.mc And
					(
					(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
					OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
					OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
					OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
					)
				group by autodata.mc,DownID
			) as TT INNER JOIN #DownTimeData ON TT.mc = #DownTimeData.McInterfaceid AND #DownTimeData.DownID=TT.DownId
			Where #DownTimeData.DownTime>0
		END

		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y' AND (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
		BEGIN
			UPDATE #DownTimeData set DownTime =isnull(DownTime,0) - isNull(TT.PPDT ,0)
			FROM(
				--Production PDT
				SELECT autodata.MC,DownId, SUM
					   (CASE
					WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
					WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
					WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
					WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
					END ) as PPDT
				FROM #T_autodata AutoData CROSS jOIN #PlannedDownTimes T
				Inner Join DownCodeInformation D ON AutoData.DCode = D.InterfaceID
				WHERE autodata.DataType=2 And T.MachineInterface = AutoData.mc AND D.DownID=(SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD') AND
					(
					(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
					OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
					OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
					OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
					)
				group by autodata.mc,DownId
			) as TT INNER JOIN #DownTimeData ON TT.mc = #DownTimeData.McInterfaceid AND #DownTimeData.DownID=TT.DownId
			Where #DownTimeData.DownTime>0
		END


	Select T.DownID,T.Downtime From
	(select DownID,Sum(Downtime)/60 as Downtime from #Downtimedata where downtime>0
	Group by DownID)T Order By T.Downtime desc

END


END
