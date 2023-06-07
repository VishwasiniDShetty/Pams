/****** Object:  Procedure [dbo].[s_GetComfitValves_ANDONDetails]    Committed by VersionSQL https://www.versionsql.com ******/

--DR0379 - SwathiKS - 21/Nov/2017 :: Ignore Downtimes Which are "Zero" While Showing Down1,Down2,Down3 For SPF.
--ER0459 - SwathiKS - 05/Feb/2018 :: To handle Runtime Target for Devendra.
--ER0459 - SwathiKS - 23/Feb/2018 ::  Kun Aerospace - To Handle Machine Interfaceid>4 in Cockpit
--ER0460 - SwathiKS - 15/Feb/2018 :: To add PlantOEE in the o/p for Kranthi.
--ER0464 - Gopinath - 10/May/2018 :: To Display Machinewise Running Status Using New Table "MachineRunningStatus" Instead of "Rawdata" table for Performance Optimization.
--ER0466 - SwathiKS - 30/Jun/2018 :: Triveni :: a> To handle Single or All Shifts instead of current Shift
--b>Instead of Cursor using Partitionby to calculate Target --c>prediction Logic For Long Running Cycle 
--s_GetComfitValves_ANDONDetails '2021-01-02 12:54:00','','','','','machineid'

CREATE PROCEDURE [dbo].[s_GetComfitValves_ANDONDetails]
	@Startdate datetime,
	@SHIFT nvarchar(50)='',
	@MachineID nvarchar(50) = '',
	@PlantID nvarchar(50)='',
	@Param nvarchar(50)='', 
	@SortOrder nvarchar(100)=''
WITH RECOMPILE
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


SET NOCOUNT ON; 

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

if isnull(@machineid,'')<> ''
begin
	SET @strMachine = ' AND MachineInformation.MachineID = N''' + @machineid + ''''
end

if isnull(@PlantID,'')<> ''
Begin
	SET @strPlantID = ' AND PlantMachine.PlantID = N''' + @PlantID + ''''
End

IF ( SELECT TOP 1 ValueInText FROM  CockpitDefaults WHERE Parameter='TpmEnbMac')='E'
BEGIN
	SET  @StrTPMMachines = 'AND MachineInformation.TPMTrakEnabled = 1'
END
ELSE
BEGIN
	SET  @StrTPMMachines = ' '
END

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
	mc,sttime,ndtime--,msttime ASC ----ER0466 commented msttime
)ON [PRIMARY]


Declare @T_ST AS Datetime 
Declare @T_ED AS Datetime 
declare @counter as datetime
declare @stdate as nvarchar(20)


--Select @T_ST=dbo.f_GetLogicalDaystart(@StartDate)
--Select @T_ED=dbo.f_GetLogicalDayend(@StartDate)


--Select @strsql=''
--select @strsql ='insert into #T_autodata '
--select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'
--	select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'
--select @strsql = @strsql + ' from #T_autodata autodata where (( sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_ED,120)+''' ) OR '
--select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' )OR '
--select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ST,120)+'''
--					and ndtime<='''+convert(nvarchar(25),@T_ED,120)+''' )'
--select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' and sttime<'''+convert(nvarchar(25),@T_ED,120)+''' ) )
--order by mc,id'
--print @strsql
--exec (@strsql)


Create Table #Shift
(	
	Machineid nvarchar(50),
	PDate datetime,
	ShiftName nvarchar(20),
	ShiftID int,
	HourName nvarchar(50),
	HourID int,
	FromTime datetime,
	ToTime Datetime,
	Actual float,
	HourlyTarget float,
	shiftstart datetime,
	shiftend datetime
)



Create Table #ShiftTemp
(	
	Plantid nvarchar(50),
	Machineid nvarchar(50),
	machineinterface nvarchar(50),
	Component nvarchar(50),		
	CompInt nvarchar(50),	
	Operation nvarchar(50),	
	OpnInt nvarchar(50),	
	PDate datetime,
	ShiftName nvarchar(20),
	ShiftID int,
	HourName nvarchar(50),
	HourID int,
	FromTime datetime,
	ToTime Datetime,
	Actual float,
	HourlyTarget float,
	shiftstart datetime,
	shiftend datetime
)

/*  --ER0466
--If @SHIFT=''
--BEGIN
	INSERT INTO #Shifttemp(PDate,Shiftname,FromTime,ToTime,ShiftID)
	Exec [s_GetCurrentShiftTime] @Startdate,''  
--END
--
--If ISNULL(@SHIFT,'')<>''
--BEGIN
--	INSERT INTO #Shifttemp(PDate,Shiftname,FromTime,ToTime)
--	Exec [s_GetShiftTime] @Startdate,@SHIFT  
--
--	Update #Shifttemp set ShiftID = T1.ShiftID fr
--	(select shiftname,shiftid from shiftdetails where running=1)T1 
--	inner join #Shifttemp on #Shifttemp.Shiftname=T1.Shiftname
--
--END
 --ER0466*/

-----ER0466
If @SHIFT=''
BEGIN
	INSERT INTO #Shifttemp(PDate,Shiftname,FromTime,ToTime)
	Exec [s_GetShiftTime] @Startdate,''  
END

If ISNULL(@SHIFT,'')<>''
BEGIN
	INSERT INTO #Shifttemp(PDate,Shiftname,FromTime,ToTime)
	Exec [s_GetShiftTime] @Startdate,@SHIFT  
END

Update #Shifttemp set ShiftID = T1.ShiftID from
(select shiftname,shiftid from shiftdetails where running=1)T1 
inner join #Shifttemp on #Shifttemp.Shiftname=T1.Shiftname
-----ER0466


Declare @StartTime AS Datetime 
Declare @EndTime AS Datetime 
Declare @CurrTime as DateTime
Declare @Shiftname as nvarchar(50)
declare @Shiftend as DateTime
declare @ShiftStart as datetime

--select @CurrTime =@Startdate --convert(nvarchar(20),getdate(),120) ----ER0466 Commented and added below
select @CurrTime =convert(nvarchar(20),getdate(),120) ----ER0466 

Select @StartTime=min(fromtime) from #Shifttemp
Select @EndTime=max(totime) from #Shifttemp
Select @Shiftname = Shiftname from #Shifttemp

Select @EndTime= case when @CurrTime>@EndTime then @EndTime else @CurrTime end
Select @Shiftend= max(Totime) from #Shifttemp
select @ShiftStart = fromtime from #Shifttemp
 
Select @T_ST=@StartTime
Select @T_ED=@EndTime
  
Select @strsql=''
select @strsql ='insert into #T_autodata '
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'
	select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'
select @strsql = @strsql + ' from autodata where (( sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_ED,120)+''' ) OR '
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' )OR '
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ST,120)+'''
					and ndtime<='''+convert(nvarchar(25),@T_ED,120)+''' )'
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' and sttime<'''+convert(nvarchar(25),@T_ED,120)+''' ) )
order by mc,id'
print @strsql
exec (@strsql)


CREATE TABLE #CockPitData 
(
	PDate datetime,
	ShiftName nvarchar(20),
	FromTime datetime,
	Plantid nvarchar(50),
	ToTime Datetime,
	MachineID nvarchar(50),
	MachineDescription nvarchar(50),
	MachineInterface nvarchar(50),
	ProductionEfficiency float,
	AvailabilityEfficiency float,
	OverallEfficiency float,
	QualityEfficiency float,
	Components float,
	RejCount float,
	UtilisedTime float,
	ManagementLoss float,
	MLDown float,
	DownTime float,
	CN float,
	PEGreen smallint,
	PERed smallint,
	AEGreen smallint,
	AERed smallint,
	OEGreen smallint,
	OERed smallint,
	QEGreen smallint, 
	QERed smallint, 
	AEcolor nvarchar(50),
	PEColor nvarchar(50),
	OEColor nvarchar(50),
	QEColor nvarchar(50),
	LastCycleTime datetime,
	MachineStatus nvarchar(50),
	Down1 nvarchar(50) DEFAULT (''),
	Down2 nvarchar(50) DEFAULT (''),
	Down3 nvarchar(50) DEFAULT (''),
	Remarks nvarchar(50),
	Componentid nvarchar(50),
	CompDescription nvarchar(100),
	OperationNo nvarchar(50),
	OpnDescription nvarchar(100),
	OperatorName nvarchar(50),
	ShiftTarget float,
	PlantOEE float Default 0,--ER0460
	RunningCOActual float,
	RunningCOTarget float
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
	MachineID nvarchar(50) not null,
	MachineInterface nvarchar(50) not null,
	StartTime DateTime not null,
	EndTime DateTime not null,
	Actual float
)


ALTER TABLE #PlannedDownTimes
	ADD PRIMARY KEY CLUSTERED
		(   [MachineInterface],
			[StartTime],
			[EndTime]
						
		) ON [PRIMARY]


CREATE TABLE #MachineRunningStatus
(
	MachineID NvarChar(50),
	MachineInterface nvarchar(50),
	sttime Datetime,
	ndtime Datetime,
	DataType smallint,
	ColorCode varchar(10),
	StartTime datetime,
	Downtime float,
	Comp NvarChar(50), ----ER0466
	Opn NvarChar(50), ----ER0466
	Totaltime int, ----ER0466
	ManagementLoss float, ----ER0466
	UT float,----ER0466
	PDT float,----ER0466
	LastRecorddatatype int --ER0466
)


CREATE TABLE #DownTimeData
(
	MachineID nvarchar(50) NOT NULL,
	--McInterfaceid nvarchar(4), --ER0459
	McInterfaceid nvarchar(50), --ER0459
	DownID nvarchar(50) NOT NULL,
	DownTime float,
	DownFreq int
)

ALTER TABLE #DownTimeData
	ADD PRIMARY KEY CLUSTERED
	(
		[MachineId], [DownID]
	)ON [PRIMARY]


create table #Runningpart_Part
(  
 Machineid nvarchar(50),  
 Componentid nvarchar(50),
 CompDescription nvarchar(100),
 OperationNo nvarchar(50),
 OpnDescription nvarchar(100),
 OperatorName nvarchar(50),
 StTime Datetime
)  

--ER0459
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
Shift nvarchar(20),
Pdate datetime,
SubOperations int
)  
  
CREATE TABLE #FinalTarget    
(  
	Pdate datetime,
	Shift nvarchar(20),
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
	Target float default 0,
	Runtime float default 0,
	SubOperations int

)  
--ER0459

--mod 4 Get the Machines into #PLD
SET @strSql = ''
SET @strSql = 'INSERT INTO #PLD(MachineID,MachineInterface,pPlannedDT,dPlannedDT)
	SELECT distinct MachineID ,Interfaceid,0  ,0 FROM MachineInformation WHERE  MachineInformation.interfaceid > ''0'' '
SET @strSql =  @strSql + @strMachine + @StrTPMMachines
EXEC(@strSql)

/* Planned Down times for the given time period */
SET @strSql = ''
SET @strSql = 'Insert into #PlannedDownTimes
	SELECT distinct Machine,InterfaceID,
		CASE When StartTime<''' + convert(nvarchar(20),@StartTime,120)+''' Then ''' + convert(nvarchar(20),@StartTime,120)+''' Else StartTime End As StartTime,
		CASE When EndTime>''' + convert(nvarchar(20),@EndTime,120)+''' Then ''' + convert(nvarchar(20),@EndTime,120)+''' Else EndTime End As EndTime,0
	FROM PlannedDownTimes inner join MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID
	WHERE PDTstatus =1 and(
	(StartTime >= ''' + convert(nvarchar(20),@StartTime,120)+''' AND EndTime <=''' + convert(nvarchar(20),@EndTime,120)+''')
	OR ( StartTime < ''' + convert(nvarchar(20),@StartTime,120)+'''  AND EndTime <= ''' + convert(nvarchar(20),@EndTime,120)+''' AND EndTime > ''' + convert(nvarchar(20),@StartTime,120)+''' )
	OR ( StartTime >= ''' + convert(nvarchar(20),@StartTime,120)+'''   AND StartTime <''' + convert(nvarchar(20),@EndTime,120)+''' AND EndTime > ''' + convert(nvarchar(20),@EndTime,120)+''' )
	OR ( StartTime < ''' + convert(nvarchar(20),@StartTime,120)+'''  AND EndTime > ''' + convert(nvarchar(20),@EndTime,120)+''')) '
SET @strSql =  @strSql + @strMachine + @StrTPMMachines + ' ORDER BY Machine,StartTime'
print @Strsql
EXEC(@strSql)


Select @strsql=''
SET @strSql = 'INSERT INTO #CockpitData (
	PDate,
	ShiftName,
	FromTime,
	ToTime,
	Plantid,
	MachineID ,
	MachineDescription,
	MachineInterface,
	ProductionEfficiency ,
	AvailabilityEfficiency ,
	OverallEfficiency ,
	QualityEfficiency,
	Components ,
	RejCount,
	UtilisedTime ,	
	ManagementLoss,
	MLDown,
	DownTime ,
	CN,	
	PEGreen ,
	PERed ,
	AEGreen ,
	AERed ,
	OEGreen ,
	OERed ,
	QEGreen ,
	QERed ,
	AEcolor ,
	PEColor,
	OEColor,
	QEColor,
	ShiftTarget,
	RunningCOActual,
	RunningCOTarget
	) '
SET @strSql = @strSql + ' SELECT #Shifttemp.PDate,#Shifttemp.Shiftname,#Shifttemp.FromTime,#Shifttemp.ToTime,PlantMachine.PlantId,MachineInformation.MachineID, MachineInformation.Description,MachineInformation.interfaceid ,0,0,0,0,0,0,0,0,0,0,0,PEGreen ,PERed,AEGreen ,AERed ,OEGreen ,OERed,QEGreen,QERed,''white'',''white'',''white'',''white'',0,0,0 FROM MachineInformation
			  cross join #Shifttemp LEFT OUTER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID WHERE MachineInformation.interfaceid > ''0'' '
SET @strSql =  @strSql + @strMachine + @strPlantID + @StrTPMMachines
EXEC(@strSql)



select @stdate = CAST(datePart(yyyy,@StartTime) AS nvarchar(4)) + '-' + CAST(datePart(mm,@StartTime) AS nvarchar(2)) + '-' + CAST(datePart(dd,@StartTime) AS nvarchar(2))
select @counter=convert(datetime, cast(DATEPART(yyyy,@StartTime)as nvarchar(4))+'-'+cast(datepart(mm,@StartTime)as nvarchar(2))+'-'+cast(datepart(dd,@StartTime)as nvarchar(2)) +' 00:00:00.000')

/* --ER0466
insert  #Shift	(Machineid,PDate,ShiftName,ShiftID,HourName,HourID,FromTime,ToTime,Actual,HourlyTarget,shiftstart,shiftend)
select #CockpitData.MachineID,@counter,S.ShiftName,S.ShiftID,SH.Hourname,SH.HourID,
dateadd(day,SH.Fromday,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.HourStart) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourStart) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourStart) as nvarchar(2))))),
dateadd(day,SH.Today,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.HourEnd) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourEnd) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourEnd) as nvarchar(2)))))
,0,0,#CockpitData.fromtime,#CockpitData.totime from shiftdetails S inner join Shifthourdefinition SH on SH.shiftid=S.Shiftid
cross join #CockpitData
where S.running=1
and S.ShiftName = @Shiftname
 --ER0466 */

----ER0466 From here
If @Shift<>''
Begin       
insert  #Shift	(Machineid,PDate,ShiftName,ShiftID,HourName,HourID,FromTime,ToTime,Actual,HourlyTarget,shiftstart,shiftend)
select #CockpitData.MachineID,@counter,S.ShiftName,S.ShiftID,SH.Hourname,SH.HourID,
dateadd(day,SH.Fromday,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.HourStart) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourStart) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourStart) as nvarchar(2))))),
dateadd(day,SH.Today,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.HourEnd) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourEnd) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourEnd) as nvarchar(2)))))
,0,0,#CockpitData.fromtime,#CockpitData.totime from shiftdetails S inner join Shifthourdefinition SH on SH.shiftid=S.Shiftid
cross join #CockpitData
where S.running=1
and S.ShiftName = @Shiftname
END

If @Shift=''
Begin       
	insert  #Shift	(Machineid,PDate,ShiftName,ShiftID,shiftstart,shiftend,HourName,HourID,FromTime,ToTime,Actual,HourlyTarget)
  select #CockpitData.MachineID,@counter,S.ShiftName,S.ShiftID,#CockpitData.fromtime,#CockpitData.totime,SH.Hourname,SH.HourID,              
  dateadd(day,SH.Fromday,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.HourStart) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourStart) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourStart) as nvarchar(2))))),              
  dateadd(day,SH.Today,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.HourEnd) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourEnd) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourEnd) as nvarchar(2)))))              
  ,0,0 from shiftdetails S inner join Shifthourdefinition SH on SH.shiftid=S.Shiftid              
  inner join #CockpitData on #CockpitData.Shiftname=S.Shiftname            
  where S.running=1  
END
----ER0466 TIll Here



UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
from
(select mc,sum(cycletime+loadunload) as cycle from #T_autodata autodata
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
from #T_autodata autodata INNER Join
	(Select mc,Sttime,NdTime from #T_autodata autodata
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
from #T_autodata autodata INNER Join
	(Select mc,Sttime,NdTime from #T_autodata autodata
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
from #T_autodata autodata INNER Join
	(Select mc,Sttime,NdTime from #T_autodata autodata
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
			--(B.sttime < A.sttime) AND (B.ndtime > A.ndtime)  --DR0339
			  (B.sttime <= A.sttime) AND (B.ndtime >= A.ndtime)  --DR0339
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
  ------------------------------------ ER0374 Added Till Here ---------------------------------
END

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
		and (downcodeinformation.ThresholdfromCO <>1) --NR0097
		group by autodata.mc) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface

		-- Type 2
		UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
		from
		(select      mc,sum(
		CASE WHEN DateDiff(second, @StartTime, ndtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
		then isnull(downcodeinformation.Threshold,0)
		ELSE DateDiff(second, @StartTime, ndtime)
		END)loss
		--DateDiff(second, @StartTime, ndtime)
		from #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
		where (autodata.sttime<@StartTime)
		and (autodata.ndtime>@StartTime)
		and (autodata.ndtime<=@EndTime)
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1)
		and (downcodeinformation.ThresholdfromCO <>1) --NR0097
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
		-- sum(DateDiff(second, stTime, @Endtime)) loss
		from #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
		where (autodata.msttime>=@StartTime)
		and (autodata.sttime<@EndTime)
		and (autodata.ndtime>@EndTime)
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1)
		and (downcodeinformation.ThresholdfromCO <>1) --NR0097
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
		--sum(DateDiff(second, @StartTime, @Endtime)) loss
		from #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
		where autodata.msttime<@StartTime
		and autodata.ndtime>@EndTime
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1)
		and (downcodeinformation.ThresholdfromCO <>1) --NR0097
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
		from #T_autodata autodata CROSS jOIN #PlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
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
		) AND (D.availeffy = 1) 		
		and (D.ThresholdfromCO <>1)) as T1 	 --NR0097
	left outer join
	(SELECT autodata.id,
		       sum(CASE
			WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PPDT
		from #T_autodata autodata CROSS jOIN #PlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
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

	UPDATE #CockpitData SET downtime = isnull(downtime,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)
END


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
		from #T_autodata autodata CROSS jOIN #PlannedDownTimes T
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


UPDATE #CockpitData SET CN = isnull(CN,0) + isNull(t2.C1N1,0)
from
(select mc,
SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))* autodata.partscount) C1N1
from #T_autodata autodata INNER JOIN
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
		from #T_autodata A
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
	  Select mc,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp --NR0097
		   From (select mc,SUM(autodata.partscount)AS OrginalCount,comp,opn from #T_autodata autodata
		   where (autodata.ndtime>@StartTime) and (autodata.ndtime<=@EndTime) and (autodata.datatype=1)
		   Group By mc,comp,opn) as T1
	Inner join componentinformation C on T1.Comp = C.interfaceid
	Inner join ComponentOperationPricing O ON  T1.Opn = O.interfaceid and C.Componentid=O.componentid
	inner join machineinformation on machineinformation.machineid =O.machineid
	and T1.mc=machineinformation.interfaceid
	GROUP BY mc
) As T2 Inner join #CockpitData on T2.mc = #CockpitData.machineinterface

--Mod 4 Apply PDT for calculation of Count
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	UPDATE #CockpitData SET components = ISNULL(components,0) - ISNULL(T2.comp,0) from(
		select mc,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp From ( --NR0097
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

--Calculation of PartsCount Ends..
--mod 4: Update Utilised Time and Down time
UPDATE #CockpitData
	SET UtilisedTime=(UtilisedTime-ISNULL(#PLD.pPlannedDT,0)+isnull(#PLD.IPlannedDT,0)),
	    DownTime=(DownTime-ISNULL(#PLD.dPlannedDT,0))
	From #CockpitData Inner Join #PLD on #PLD.Machineid=#CockpitData.Machineid
---mod 4


------------------------------------------------ER0466 Added From Here Logic For Ae Prediction Triveni-------------------------------------------------------------

Declare @Type1Threshold int
Declare @Type11Threshold int
declare @Type40Threshold as int

Set @Type40Threshold =0
Set @Type1Threshold = 0
Set @Type11Threshold = 0

Set @Type40Threshold = (Select isnull(Valueintext2,5)*60 from shopdefaults where parameter='ANDONStatusThreshold' and valueintext = 'Type40Threshold')
Set @Type1Threshold = (Select isnull(Valueintext2,5)*60 from shopdefaults where parameter='ANDONStatusThreshold' and valueintext = 'Type1Threshold')
Set @Type11Threshold = (Select isnull(Valueintext2,5)*60 from shopdefaults where parameter='ANDONStatusThreshold' and valueintext = 'Type11Threshold')

Create table #AE
(
mc nvarchar(50),
dcode nvarchar(50),
sttime datetime,
ndtime datetime,
Loadunload float,
CycleStart datetime,
CycleEnd datetime,
TotalTime float,
UT float,
Downtime float,
PDT float,
ManagementLoss float,
MLDown float,
id bigint,
datatype nvarchar(50)
)


Delete From #machineRunningStatus

-----------------------------------------------ER0466 Prediction Logic From here For Metso----------------------------------------------------------------------------------------
Select @currtime=case when @CurrTime>@EndTime then @EndTime else @CurrTime end

---Query to get Machinewise Last Record from Rawdata where Datatype in 11
Insert into #machineRunningStatus(MachineID,MachineInterface,sttime,DataType,Comp,Opn,Totaltime,Downtime)
select fd.MachineID,fd.MachineInterface,sttime,datatype,comp,opn,0,0 from rawdata
inner join (select mc,max(slno) as slno from rawdata WITH (NOLOCK) 
inner join Autodata_maxtime A on rawdata.mc=A.machineid where (Rawdata.sttime>A.Endtime and Rawdata.sttime<@currtime) and rawdata.datatype=11 group by mc  ) t1 
on t1.mc=rawdata.mc and t1.slno=rawdata.slno
inner join Autodata_maxtime A on rawdata.mc=A.machineid
right outer join (select distinct machineid,MachineInterface from #CockpitData) fd on fd.MachineInterface = rawdata.mc
where (Rawdata.sttime>A.Endtime)  and rawdata.datatype=11 --and (Rawdata.sttime>=@Starttime and Rawdata.sttime<=@Endtime)
order by rawdata.mc

Update #machineRunningStatus set ndtime = T1.Endtime,LastRecorddatatype=T1.LastRecorddatatype from
(select rawdata.mc,rawdata.datatype,case when rawdata.datatype=40 then dateadd(second,@type40threshold,rawdata.sttime)
when rawdata.datatype=42 then rawdata.ndtime
when rawdata.datatype=41 then rawdata.sttime else @CurrTime end as endtime,case when rawdata.datatype in(40,41,42) then RawData.DataType else 11 end as LastRecorddatatype from
	(
		select rawdata.mc,max(rawdata.slno) as slno from rawdata 
		inner join #machineRunningStatus M on M.MachineInterface=rawdata.mc
		where rawdata.datatype in(40,41,42) and (rawdata.sttime>M.sttime and Rawdata.sttime<@currtime)  group by rawdata.mc
	)T1  inner join rawdata on rawdata.slno=t1.slno
	inner join #machineRunningStatus M on M.MachineInterface=rawdata.mc
)T1 inner join #machineRunningStatus on #machineRunningStatus.MachineInterface=T1.mc


Insert into #AE(mc,dcode,sttime,ndtime,Loadunload,CycleStart,CycleEnd,TotalTime,UT,Downtime,PDT,ManagementLoss,MLDown,id,datatype)
Select M.MachineInterface,A.dcode,A.sttime,A.ndtime,A.Loadunload,M.sttime,M.ndtime,M.Totaltime,0,0,0,0,0,A.id,A.datatype from Autodata_ICD A
right outer join #machineRunningStatus M On A.mc=M.MachineInterface
Where A.sttime>=M.sttime and A.ndtime<=M.ndtime
and M.datatype='11' and A.datatype='42' Order by A.mc,A.sttime

IF EXISTS(select * from #AE where datatype=42)
Begin

update #machineRunningStatus set Totaltime=Datediff(second,sttime,ndtime)

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y')
BEGIN
		UPDATE #AE SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
		from
		(select mc,sttime,
		CASE
		WHEN Datediff(second,sttime,ndtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
		THEN isnull(downcodeinformation.Threshold,0)
		ELSE Datediff(second,sttime,ndtime)
		END AS LOSS from #AE autodata  
		INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
		where (autodata.datatype=42) and (downcodeinformation.availeffy = 1)
		) as t2 inner join  #AE on t2.mc = #AE.mc and t2.sttime=#AE.Sttime

		UPDATE #AE SET downtime = isnull(downtime,0) + isNull(t2.down,0)
		from
		(select mc,Datediff(second,sttime,ndtime) AS down,sttime,ndtime
		from #AE autodata inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		) as t2 inner join #AE on t2.mc = #AE.mc and t2.sttime=#AE.Sttime
END

Delete From #PlannedDownTimes

SET @strSql = ''
SET @strSql = 'Insert into #PlannedDownTimes(machineid,machineinterface,starttime,endtime)
	SELECT distinct MachineInformation.Machineid,MachineInformation.InterfaceID,
		CASE When StartTime<#AE.CycleStart Then #AE.CycleStart Else StartTime End As StartTime,
		CASE When EndTime>#AE.CycleEnd Then #AE.CycleEnd Else EndTime End As EndTime
	FROM PlannedDownTimes inner join MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID
	inner join #AE on #AE.mc = MachineInformation.InterfaceID
	WHERE PDTstatus =1 and(
	(StartTime >= #AE.CycleStart AND EndTime <=#AE.CycleEnd)
	OR ( StartTime < #AE.CycleStart  AND EndTime <= #AE.CycleEnd AND EndTime > #AE.CycleStart )
	OR ( StartTime >= #AE.CycleStart   AND StartTime <#AE.CycleEnd AND EndTime > #AE.CycleEnd )
	OR ( StartTime < #AE.CycleStart  AND EndTime > #AE.CycleEnd)) '
SET @strSql =  @strSql + @strMachine + @StrTPMMachines + ' ORDER BY MachineInformation.Machineid'
EXEC(@strSql)

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN


		UPDATE #AE SET downtime = isnull(downtime,0) + isNull(t2.down,0)
		from
		(select mc,Datediff(second,sttime,ndtime) AS down,sttime,ndtime
		from #AE autodata inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		where (downcodeinformation.availeffy = 0)
		) as t2 inner join #AE on t2.mc = #AE.mc and t2.sttime=#AE.Sttime

		UPDATE #AE set DownTime =isnull(DownTime,0) - isNull(TT.PPDT ,0),PDT=isnull(PDT,0) + isNull(TT.PPDT ,0)
		FROM(
			--Down PDT
			SELECT autodata.MC,DownID,sttime, SUM
					(CASE
				WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
				WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
				WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
				WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
				END ) as PPDT
			FROM #AE AutoData --ER0374
			CROSS jOIN #PlannedDownTimes T
			Inner Join DownCodeInformation On AutoData.DCode=DownCodeInformation.InterfaceID
			WHERE autodata.DataType=42 AND (downcodeinformation.availeffy = 0) AND
			T.MachineInterface = AutoData.mc And
				(
				(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
				OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
				OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
				OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
				)
			group by autodata.mc,DownID,sttime
		) as TT INNER JOIN #AE ON TT.mc = #AE.mc and TT.sttime=#AE.Sttime


			UPDATE #AE SET  ManagementLoss = isnull(ManagementLoss,0) + isNull(t4.Mloss,0),MLDown=isNull(MLDown,0)+isNull(t4.Dloss,0),
			PDT=isnull(PDT,0) + isNull(t4.PPDT ,0)
			from
			(select T3.mc,T3.sttime,sum(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss,sum(T3.PPDT) as PPDT from (
			select T1.mc,T1.Threshold,T2.PPDT,T1.sttime,
			case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0
			then DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)- isnull(T1.Threshold ,0)
			else 0 End  as Dloss,
			case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0
			then isnull(T1.Threshold,0)
			else (DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)) End  as Mloss
			from

			( 
				select sttime,mc,D.threshold,ndtime
				from #AE autodata --ER0374
				inner join downcodeinformation D on autodata.dcode=D.interfaceid 
				where autodata.datatype=42 AND D.availeffy = 1 		
			) as T1 	 
			left outer join
			(
				SELECT autodata.sttime,autodata.ndtime,autodata.mc,
					sum(CASE
				WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
				WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
				WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
				WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
				END ) as PPDT
				FROM #AE AutoData 
				CROSS jOIN #PlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
				WHERE autodata.DataType=42 AND T.MachineInterface=autodata.mc AND
				(
				(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
				OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
				OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
				OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
				)
				AND (downcodeinformation.availeffy = 1) 
				group  by autodata.sttime,autodata.ndtime,autodata.mc) as T2 on T1.mc=T2.mc and T1.sttime=T2.sttime) as T3  group by T3.mc,T3.sttime
			) as t4 inner join #AE on t4.mc = #AE.mc and t4.sttime = #AE.sttime

			UPDATE #AE SET downtime = isnull(downtime,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)
		END

		Update #MachineRunningStatus SET downtime = isnull(downtime,0)+ isnull(T1.down,0),ManagementLoss = isnull(ManagementLoss,0)+isnull(T1.ML,0),
		UT = ISNULL(UT,0)+ (ISNULL(Totaltime,0)-ISNULL(T1.down,0))from
		(Select mc,Sum(ManagementLoss) as ML,Sum(Downtime) as Down from #AE Group By mc)T1
		inner join #MachineRunningStatus on T1.mc = #MachineRunningStatus.machineinterface

END


	--Update #MachineRunningStatus set DownTime = Isnull(#MachineRunningStatus.DownTime,0) + Isnull(t2.DownTime,0),StartTime=t2.endtime,UT=IsNUll(#MachineRunningStatus.UT,0)+ISNULL(t2.UT,0)
	--from (
	--	Select mrs.MachineID,mrs.datatype,case when t1.endtime<@CurrTime then datediff(second,t1.endtime,@CurrTime) else 0 end as Downtime,case when t1.endtime<@CurrTime then t1.endtime else @CurrTime end as endtime,
	--	case when t1.endtime<@CurrTime then datediff(second,mrs.ndtime,t1.endtime) 
	--	when t1.endtime>@CurrTime then datediff(second,mrs.ndtime,@CurrTime) else 0 end as UT
	--	from #machineRunningStatus mrs inner join
	--	(
	--		Select mrs.MachineID,O.cycletime,dateadd(second,O.cycletime,mrs.ndtime)  as endtime from #machineRunningStatus mrs
	--		inner join #AE on mrs.MachineInterface=#AE.mc
	--		Inner join Machineinformation M on M.interfaceID = mrs.MachineInterface
	--		Inner join componentinformation C on mrs.Comp=C.interfaceid
	--		Inner join ComponentOperationPricing O ON mrs.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineID = M.MachineID
	--	) as t1 on t1.machineID = mrs.machineID 
	--) as t2 inner join #MachineRunningStatus on t2.MachineID = #MachineRunningStatus.MachineID 

	Update #MachineRunningStatus set DownTime = Isnull(#MachineRunningStatus.DownTime,0) + Isnull(t2.DownTime,0),StartTime=t2.endtime
	from (
		Select mrs.MachineID,mrs.datatype,case when t1.endtime<@CurrTime then datediff(second,t1.endtime,@CurrTime) else 0 end as Downtime,case when t1.endtime<@CurrTime then t1.endtime else @CurrTime end as endtime
		from #machineRunningStatus mrs inner join
		(
			Select mrs.MachineID,mrs.ndtime as endtime from #machineRunningStatus mrs
			Inner join Machineinformation M on M.interfaceID = mrs.MachineInterface
		) as t1 on t1.machineID = mrs.machineID 
	) as t2 inner join #MachineRunningStatus on t2.MachineID = #MachineRunningStatus.MachineID where #MachineRunningStatus.LastRecorddatatype in(40,41,42)

	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y' 
	BEGIN
		--update #MachineRunningStatus set UT = Isnull(fd.UT,0) - isnull(T2.pdt,0)
		--from
		--(
		--Select T1.machineid,sum(datediff(ss,T1.StartTime,t1.EndTime)) as pdt 
		--from 
		--(
		--	select fD.machineid,
		--	Case when  fd.ndtime <= pdt.StartTime then pdt.StartTime else  fd.ndtime End as StartTime,
		--	Case when fd.starttime >= pdt.EndTime then pdt.EndTime else fd.starttime End as EndTime
		--	From Planneddowntimes pdt
		--	inner join #machineRunningStatus fD on fd.machineid=Pdt.machine
		--	inner join #AE on fd.MachineInterface=#AE.mc
		--	where PDTstatus = 1  and 
		--	((pdt.StartTime >= fd.ndtime and pdt.EndTime <= fd.starttime)or
		--	(pdt.StartTime < fd.ndtime and pdt.EndTime > fd.ndtime and pdt.EndTime <=fd.starttime)or
		--	(pdt.StartTime >= fd.ndtime and pdt.StartTime <fd.starttime and pdt.EndTime >fd.starttime) or
		--	(pdt.StartTime <  fd.ndtime and pdt.EndTime >fd.starttime))
		--)T1  group by T1.machineid 
		--)T2 inner join #MachineRunningStatus fd on fd.machineid=t2.machineid	

		update #MachineRunningStatus set Downtime = Isnull(fd.Downtime,0) - isnull(T2.pdt,0)
		from
		(
		Select T1.machineid,sum(datediff(ss,T1.StartTime,t1.EndTime)) as pdt 
		from 
		(
			select fD.machineid,
			Case when  fd.starttime <= pdt.StartTime then pdt.StartTime else  fd.starttime End as StartTime,
			Case when @Currtime >= pdt.EndTime then pdt.EndTime else @Currtime End as EndTime
			From Planneddowntimes pdt
			inner join #machineRunningStatus fD on fd.machineid=Pdt.machine
			inner join #AE on fd.MachineInterface=#AE.mc
			where PDTstatus = 1  and 
			((pdt.StartTime >= fd.starttime and pdt.EndTime <= @Currtime)or
			(pdt.StartTime < fd.starttime and pdt.EndTime > fd.starttime and pdt.EndTime <=@Currtime)or
			(pdt.StartTime >= fd.starttime and pdt.StartTime <@Currtime and pdt.EndTime >@Currtime) or
			(pdt.StartTime <  fd.starttime and pdt.EndTime >@Currtime))
		)T1  group by T1.machineid 
		)T2 inner join #MachineRunningStatus fd on fd.machineid=t2.machineid where fd.LastRecorddatatype in(40,41,42)
	end


	Update #MachineRunningStatus set DownTime = Isnull(#MachineRunningStatus.DownTime,0) + Isnull(t2.DownTime,0),StartTime=t2.endtime,UT=IsNUll(#MachineRunningStatus.UT,0)+ISNULL(t2.UT,0)
	from (
		Select mrs.MachineID,mrs.datatype,case when t1.endtime<@CurrTime then datediff(second,t1.endtime,@CurrTime) else 0 end as Downtime,case when t1.endtime<@CurrTime then t1.endtime else @CurrTime end as endtime,
		case when t1.endtime<@CurrTime then datediff(second,mrs.sttime,t1.endtime) 
		when t1.endtime>@CurrTime then datediff(second,mrs.sttime,@CurrTime) else 0 end as UT
		from #machineRunningStatus mrs inner join
		(
			Select mrs.MachineID,O.cycletime,dateadd(second,O.cycletime,mrs.sttime)  as endtime from #machineRunningStatus mrs
			Inner join Machineinformation M on M.interfaceID = mrs.MachineInterface
			Inner join componentinformation C on mrs.Comp=C.interfaceid
			Inner join ComponentOperationPricing O ON mrs.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineID = M.MachineID
			--where MachineInterface not in(select distinct mc from #AE)
			where mrs.LastRecorddatatype=11
		) as t1 on t1.machineID = mrs.machineID 
	) as t2 inner join #MachineRunningStatus on t2.MachineID = #MachineRunningStatus.MachineID where #MachineRunningStatus.LastRecorddatatype=11

	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y' 
	BEGIN
		update #MachineRunningStatus set UT = Isnull(fd.UT,0) - isnull(T2.pdt,0)
		from
		(
		Select T1.machineid,sum(datediff(ss,T1.StartTime,t1.EndTime)) as pdt 
		from 
		(
			select fD.machineid,
			Case when  fd.sttime <= pdt.StartTime then pdt.StartTime else  fd.sttime End as StartTime,
			Case when fd.starttime >= pdt.EndTime then pdt.EndTime else fd.starttime End as EndTime
			From Planneddowntimes pdt
			inner join #machineRunningStatus fD on fd.machineid=Pdt.machine
			where PDTstatus = 1  and  
			 --MachineInterface not in(select distinct mc from #AE) and
			fd.LastRecorddatatype=11 and
			((pdt.StartTime >= fd.ndtime and pdt.EndTime <= fd.starttime)or
			(pdt.StartTime < fd.ndtime and pdt.EndTime > fd.ndtime and pdt.EndTime <=fd.starttime)or
			(pdt.StartTime >= fd.ndtime and pdt.StartTime <fd.starttime and pdt.EndTime >fd.starttime) or
			(pdt.StartTime <  fd.ndtime and pdt.EndTime >fd.starttime))
		)T1  group by T1.machineid 
		)T2 inner join #MachineRunningStatus fd on fd.machineid=t2.machineid where fd.LastRecorddatatype=11

		update #MachineRunningStatus set Downtime = Isnull(fd.Downtime,0) - isnull(T2.pdt,0)
		from
		(
		Select T1.machineid,sum(datediff(ss,T1.StartTime,t1.EndTime)) as pdt 
		from 
		(
			select fD.machineid,
			Case when  fd.starttime <= pdt.StartTime then pdt.StartTime else  fd.starttime End as StartTime,
			Case when @Currtime >= pdt.EndTime then pdt.EndTime else @Currtime End as EndTime
			From Planneddowntimes pdt
			inner join #machineRunningStatus fD on fd.machineid=Pdt.machine
			where PDTstatus = 1  and --MachineInterface not in(select distinct mc from #AE) and
			fd.LastRecorddatatype=11 and
			((pdt.StartTime >= fd.starttime and pdt.EndTime <= @Currtime)or
			(pdt.StartTime < fd.starttime and pdt.EndTime > fd.starttime and pdt.EndTime <=@Currtime)or
			(pdt.StartTime >= fd.starttime and pdt.StartTime <@Currtime and pdt.EndTime >@Currtime) or
			(pdt.StartTime <  fd.starttime and pdt.EndTime >@Currtime))
		)T1  group by T1.machineid 
		)T2 inner join #MachineRunningStatus fd on fd.machineid=t2.machineid where fd.LastRecorddatatype=11
	end


UPDATE #CockpitData SET components = ISNULL(components,0) + ISNULL(t2.comp,0)
From
(
	Select MachineInterface,ROUND((ISNULL(UT,0)/ISNULL(cycletime,0)),2) As Comp 
	From #MachineRunningStatus T1
	Inner join componentinformation C on T1.Comp = C.interfaceid
	Inner join ComponentOperationPricing O ON  T1.Opn = O.interfaceid and C.Componentid=O.componentid
	inner join machineinformation on machineinformation.machineid =O.machineid
	and T1.MachineInterface=machineinformation.interfaceid where ISNULL(UT,0)>0
) As T2 Inner join #CockpitData on T2.MachineInterface = #CockpitData.machineinterface


Update #CockpitData SET UtilisedTime= isnull(UtilisedTime,0)+isnull(T.UT,0),Downtime=ISNULL(Downtime,0)+ISNULL(T.DT,0),
#CockpitData.ManagementLoss=ISNULL(#CockpitData.ManagementLoss,0)+ISNULL(T.ManagementLoss,0) from
(
	Select MachineInterface as mc,ISNULL(Downtime,0) as DT,ISNULL(UT,0) as UT,IsNULL(ManagementLoss,0) as ManagementLoss from #MachineRunningStatus
)T inner join #CockpitData on #CockpitData.MachineInterface=T.mc
-----------------------------------------------ER0466 Prediction Logic Till here For Metso----------------------------------------------------------------------------------------



-- Calculate efficiencies
UPDATE #CockpitData
SET
	ProductionEfficiency = (CN/UtilisedTime) ,
	AvailabilityEfficiency = (UtilisedTime)/(UtilisedTime + DownTime - ManagementLoss),
	 Remarks = ' '
WHERE UtilisedTime <> 0

--------------------- ER0466 Predicted PE -------------------------------------------
update #cockpitdata set ProductionEfficiency=ISNULL(ProductionEfficiency,0)*isnull(T.pe,0) from
(	
select machineinterface,
((componentoperationpricing.cycletime)* (M.UT/componentoperationpricing.cycletime))/M.UT as pe
FROM #MachineRunningStatus m INNER JOIN
componentoperationpricing ON M.opn = componentoperationpricing.InterfaceID INNER JOIN
componentinformation ON M.comp = componentinformation.InterfaceID AND
componentoperationpricing.componentid = componentinformation.componentid
inner join machineinformation on machineinformation.interfaceid=M.MachineInterface and componentoperationpricing.machineid=machineinformation.machineid
where M.UT>0
)T inner join #CockpitData on #CockpitData.MachineInterface=T.machineinterface
--------------------- ER0466 Predicted PE -------------------------------------------

UPDATE #CockpitData SET Remarks = 'Machine Not In Production' WHERE UtilisedTime = 0

UPDATE #CockpitData
SET
	OverAllEfficiency = (ProductionEfficiency * AvailabilityEfficiency)*100,
	ProductionEfficiency = ProductionEfficiency * 100 ,
	AvailabilityEfficiency = AvailabilityEfficiency * 100

--ER0368 From here
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
inner join #Shifttemp S on convert(nvarchar(10),(A.RejDate),126)=S.Pdate and A.RejShift=S.shiftid --DR0333
where A.flag = 'Rejection' and A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (S.Pdate) and  --DR0333
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
	inner join #Shifttemp S on convert(nvarchar(10),(A.RejDate),126)=S.Pdate and A.RejShift=S.shiftid --DR0333
	Cross join Planneddowntimes P
	where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid and
	A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (S.Pdate) and --DR0333
	Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
	and P.starttime>=S.fromtime and P.Endtime<=S.Totime
	group by A.mc,M.Machineid)T1 inner join #Cockpitdata B on B.Machineid=T1.Machineid 
END

UPDATE #Cockpitdata SET QualityEfficiency= ISNULL(QualityEfficiency,0) + IsNull(T1.QE,0) 
FROM(Select MachineID,
CAST((Sum(Components))As Float)/CAST((Sum(IsNull(Components,0))+Sum(IsNull(RejCount,0))) AS Float)As QE
From #Cockpitdata Where Components<>0 Group By MachineID
)AS T1 Inner Join #Cockpitdata ON  #Cockpitdata.MachineID=T1.MachineID

UPDATE #CockpitData
SET QualityEfficiency = QualityEfficiency*100 


Update #CockpitData Set Lastcycletime = T1.LastCycle  from 
(
	Select M.Machineid,convert(varchar,A.ndtime,120) as LastCycle from 
	(
		Select mc,max(id) as idd from #T_autodata autodata where datatype=1 group by mc
	)T inner join Autodata  A on A.mc=T.mc and A.id=T.idd inner join Machineinformation M on M.interfaceid=A.mc
) T1 inner join #CockpitData on T1.MachineID = #CockpitData.MachineID 

--ER0464 --g: using MachineRunningStatus table instead of rawdata

--Insert into #machineRunningStatus
--select fd.MachineID,fd.MachineInterface,sttime,ndtime,datatype,'White',@Endtime,0 from rawdata
--inner join (select mc,max(slno) as slno from rawdata WITH (NOLOCK) where sttime<@currtime and isnull(ndtime,'1900-01-01')<@currtime
--and datatype in(2,42,40,41,1,11) and datepart(year,sttime)>'2000' group by mc ) t1 on t1.mc=rawdata.mc and t1.slno=rawdata.slno --For SAF DR0370
--right outer join #CockpitData fd on fd.MachineInterface = rawdata.mc
--order by rawdata.mc

Insert into #machineRunningStatus (MachineID,MachineInterface,sttime,ndtime,datatype,ColorCode,StartTime,Downtime)   
select fd.MachineID,fd.MachineInterface,sttime,ndtime,datatype,ColorCode,@EndTime,0 from MachineRunningStatus mr    
right outer join #CockpitData fd on fd.MachineInterface = mr.MachineInterface
where sttime<@currtime and isnull(ndtime,'1900-01-01')<@currtime
order by fd.MachineInterface
--ER0464 --g: using MachineRunningStatus table instead of rawdata


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


update #machineRunningStatus set ColorCode ='Red' where isnull(sttime,'1900-01-01')='1900-01-01'

update #CockpitData set MachineStatus = T1.MCStatus from 
(select Machineid,
Case when Colorcode='White' then 'Stopped'
when Colorcode='Red' then 'Stopped'
when Colorcode='Green' then 'Running' end as MCStatus from #machineRunningStatus)T1
inner join #CockpitData on T1.MachineID = #CockpitData.MachineID


select @strsql = ''
select @strsql = 'INSERT INTO #DownTimeData (MachineID,McInterfaceid, DownID, DownTime,DownFreq) 
SELECT Machineinformation.MachineID AS MachineID,Machineinformation.interfaceid, downcodeinformation.downid AS DownID, 0,0'
select @strsql = @strsql+' FROM Machineinformation CROSS JOIN downcodeinformation LEFT OUTER JOIN PlantMachine ON PlantMachine.MachineID=Machineinformation.MachineID '
select @strsql = @strsql+' Where MachineInformation.interfaceid > ''0'' '
select @strsql = @strsql + @strPlantID +@strmachine + @StrTPMMachines + ' ORDER BY  downcodeinformation.downid, Machineinformation.MachineID'
exec (@strsql)



--Type 1,2,3 and 4.
select @strsql = ''
select @strsql = @strsql + 'UPDATE #DownTimeData SET downtime = isnull(DownTime,0) + isnull(t2.down,0) '
select @strsql = @strsql + ' FROM'
select @strsql = @strsql + ' (SELECT mc,
SUM(CASE
WHEN (autodata.sttime>='''+convert(varchar(20),@starttime)+''' and autodata.ndtime<='''+convert(varchar(20),@endtime)+''' ) THEN loadunload
WHEN (autodata.sttime<'''+convert(varchar(20),@starttime)+''' and autodata.ndtime>'''+convert(varchar(20),@starttime)+'''and autodata.ndtime<='''+convert(varchar(20),@endtime)+''') THEN DateDiff(second, '''+convert(varchar(20),@StartTime)+''', ndtime)
WHEN (autodata.sttime>='''+convert(varchar(20),@starttime)+'''and autodata.sttime<'''+convert(varchar(20),@endtime)+''' and autodata.ndtime>'''+convert(varchar(20),@endtime)+''') THEN DateDiff(second, stTime, '''+convert(varchar(20),@Endtime)+''')
ELSE DateDiff(second,'''+convert(varchar(20),@starttime)+''','''+convert(varchar(20),@endtime)+''')
END) as down
,downcodeinformation.downid as downid'
select @strsql = @strsql + ' from'
select @strsql = @strsql + '  autodata INNER JOIN'
select @strsql = @strsql + ' machineinformation ON autodata.mc = machineinformation.InterfaceID 
Left Outer Join PlantMachine ON PlantMachine.MachineID=machineinformation.MachineID INNER JOIN'
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
		from #T_autodata autodata CROSS jOIN #PlannedDownTimes T
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
		from #T_autodata autodata CROSS jOIN #PlannedDownTimes T
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


Update #CockpitData set Down1 = T1.Down1 from
(
select T.Machineid,T.McInterfaceid,T.DownID + '-'+ SUBSTRING(dbo.f_FormatTime(T.DownTime,'hh:mm:ss'),1,5) as down1
from (
     select S.Machineid,
            S.McInterfaceid,
            S.Downid,
			S.Downtime,
            row_number() over(partition by S.Machineid order by S.downtime desc) as rn
     from #downtimedata S where s.Downtime>0 --DR0379
     ) as T inner join #downtimedata H on T.Machineid=H.Machineid and T.Downid=H.Downid 
where T.rn=1)T1 inner join #CockpitData H on T1.Machineid=H.Machineid 

Update #CockpitData set Down2 = T1.Down2 from
(
select T.Machineid,T.McInterfaceid,T.DownID + '-'+ SUBSTRING(dbo.f_FormatTime(T.DownTime,'hh:mm:ss'),1,5) as down2
from (
     select S.Machineid,
            S.McInterfaceid,
            S.Downid,
			S.Downtime,
            row_number() over(partition by S.Machineid order by S.downtime desc) as rn
     from #downtimedata S where s.Downtime>0 --DR0379
     ) as T inner join #downtimedata H on T.Machineid=H.Machineid and T.Downid=H.Downid 
where T.rn=2)T1 inner join #CockpitData H on T1.Machineid=H.Machineid 

Update #CockpitData set Down3 = T1.Down3 from
(
select T.Machineid,T.McInterfaceid,T.DownID + '-'+ SUBSTRING(dbo.f_FormatTime(T.DownTime,'hh:mm:ss'),1,5) as down3
from (
     select S.Machineid,
            S.McInterfaceid,
            S.Downid,
			S.Downtime,
            row_number() over(partition by S.Machineid order by S.downtime desc) as rn
     from #downtimedata S where s.Downtime>0 --DR0379
     ) as T inner join #downtimedata H on T.Machineid=H.Machineid and T.Downid=H.Downid 
where T.rn=3)T1 inner join #CockpitData H on T1.Machineid=H.Machineid 


UPDATE #CockpitData SET AEColor = T1.Aecolor,PEColor=T1.Pecolor,OEColor=T1.Oecolor,QEColor=T1.Qecolor from
(Select machineinterface as mc,

case when OverAllEfficiency>=OEGreen then 'Green'
when OverAllEfficiency>=OERed and OverAllEfficiency<OEGreen then 'Yellow' 
when OverAllEfficiency>0 and OverAllEfficiency<OERed then 'Red' else 'white' end as Oecolor,

case when ProductionEfficiency>=PEGreen then 'Green'
when ProductionEfficiency>=PERed and ProductionEfficiency<PEGreen then 'Yellow' 
when ProductionEfficiency>0 and ProductionEfficiency<PERed then 'Red' else 'white' end as Pecolor,

case when AvailabilityEfficiency>=AEGreen then 'Green'
when AvailabilityEfficiency>=AERed and AvailabilityEfficiency<AEGreen then 'Yellow' 
when AvailabilityEfficiency>0 and AvailabilityEfficiency<AERed then 'Red'  else 'white' end as Aecolor,

case when QualityEfficiency>=QEGreen then 'Green'
when QualityEfficiency>=QERed and QualityEfficiency<QEGreen then 'Yellow' 
when QualityEfficiency>0 and QualityEfficiency<QEred then 'Red' 
else 'white' end as Qecolor from #CockpitData

) as T1 inner join #CockpitData on T1.mc = #CockpitData.machineinterface


	Delete from #shifttemp



	Select @strsql=''
	select @strsql ='insert into #ShiftTemp(Plantid,Machineid,MachineInterface,Component,CompInt,Operation,OpnInt,PDate,
					ShiftName,ShiftID,HourName,HourID,FromTime,ToTime,Actual,HourlyTarget,shiftstart,shiftend) '
	select @strsql = @strsql + 'SELECT distinct  plantmachine.Plantid,Machineinformation.Machineid,Machineinformation.interfaceid,
					componentinformation.componentid,componentinformation.interfaceid,componentoperationpricing.operationno,
					componentoperationpricing.interfaceid,S.PDate,S.ShiftName,S.ShiftID,S.HourName,S.HourID,S.FromTime,S.ToTime,
					(CAST(Sum(autodata.partscount)AS Float)/ISNULL(ComponentOperationPricing.SubOperations,1)),0,S.shiftstart,S.shiftend '
	select @strsql = @strsql + ' from #T_autodata autodata inner join machineinformation on machineinformation.interfaceid=autodata.mc inner join ' 
	select @strsql = @strsql + ' componentinformation ON autodata.comp = componentinformation.InterfaceID  INNER JOIN '
	select @strsql = @strsql + ' componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID)'
	select @strsql = @strsql + ' AND (componentinformation.componentid = componentoperationpricing.componentid) '
	select @strsql = @strsql + ' and componentoperationpricing.machineid=machineinformation.machineid '
	select @strsql = @strsql + ' Left Outer Join PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID '
	select @strsql = @strsql + ' inner join #shift S on S.Machineid=Machineinformation.Machineid where '
	select @strsql = @strsql + ' autodata.datatype=1 and (Autodata.ndtime>S.FromTime and Autodata.ndtime<=S.ToTime) and machineinformation.interfaceid>0 '
	select @strsql = @strsql + @strmachine+@strPlantID+@StrTPMMachines
	select @strsql = @strsql + ' Group by plantmachine.Plantid,Machineinformation.Machineid,Machineinformation.interfaceid,
					componentinformation.componentid,componentinformation.interfaceid,componentoperationpricing.operationno,ComponentOperationPricing.SubOperations,
					componentoperationpricing.interfaceid,S.PDate,S.ShiftName,S.ShiftID,S.HourName,S.HourID,S.FromTime,S.ToTime,S.shiftstart,S.shiftend order by Machineinformation.Machineid,S.Fromtime'
	print @strsql
	exec (@strsql)

	Delete from #PlannedDownTimes

	insert into #PlannedDownTimes
	select distinct  st.machineID,st.machineinterface,
	case when  st.FromTime > pdt.StartTime then st.FromTime else pdt.StartTime end,
	case when  st.ToTime < pdt.EndTime then st.ToTime else pdt.EndTime end,0
	from (Select distinct machineid,machineinterface,fromtime,totime from #ShiftTemp) st inner join PlannedDownTimes pdt
	on st.machineID = pdt.Machine and PDTstatus = 1 and
	((pdt.StartTime >= st.FromTime  AND pdt.EndTime <=st.ToTime)
	OR ( pdt.StartTime < st.FromTime  AND pdt.EndTime <= st.ToTime AND pdt.EndTime > st.FromTime )
	OR ( pdt.StartTime >= st.FromTime   AND pdt.StartTime <st.ToTime AND pdt.EndTime > st.ToTime )
	OR ( pdt.StartTime < st.FromTime  AND pdt.EndTime > st.ToTime))

	--ER0210-KarthikG-17/Dec/2009::From Here
	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
	BEGIN

		UPDATE #ShiftTemp SET Actual=ISNULL(Actual,0)- isnull(t2.cnt,0) FROM 
		( select S.Fromtime,Machineinformation.machineid as machine,
			((CAST(Sum(ISNULL(PartsCount,1)) AS Float)/ISNULL(Componentoperationpricing.SubOperations,1))) as cnt, --NR0097
		 	Componentinformation.componentid as compid,componentoperationpricing.Operationno as opnno from #T_autodata autodata --ER0324 Added
			inner join machineinformation on autodata.mc=machineinformation.Interfaceid
			Inner join componentinformation on autodata.comp=componentinformation.interfaceid 
			inner join componentoperationpricing on autodata.opn=componentoperationpricing.interfaceid and
			componentinformation.componentid=componentoperationpricing.componentid  and componentoperationpricing.machineid=machineinformation.machineid
			inner join #shift S on S.Machineid=Machineinformation.Machineid
			Inner jOIN #PlannedDownTimes T on T.MachineInterface=autodata.mc  			
			WHERE autodata.DataType=1
			AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime) 			
			AND (autodata.ndtime > S.Fromtime  AND autodata.ndtime <= S.Totime)
			 Group by Machineinformation.machineid,componentinformation.componentid ,componentoperationpricing.Operationno,componentoperationpricing.SubOperations,S.Fromtime
		) as T2 inner join #ShiftTemp S on T2.machine = S.machineid  and T2.compid=S.Component and   t2.opnno=S.Operation and  t2.fromtime=S.fromtime
		
	End

--ER0459
	declare @Targetdef as nvarchar(50)
	Select @Targetdef = isnull(valueintext,'ByTotalTime') from Shopdefaults where Parameter='%IdealTargetCalculation'

	If @Targetdef='ByTotalTime'
	Begin
		Select @strsql=''
		select @strsql='update #CockpitData set ShiftTarget= isnull(ShiftTarget,0)+ ISNULL(t1.tcount,0) from
		(select T.machineid,SUM(T.tcount) as tcount from
				 ( select CO.componentid as component,CO.Operationno as operation,CO.machineid,tcount=((datediff(second,#ShiftTemp.shiftstart,#ShiftTemp.shiftend)*CO.suboperations)/CO.cycletime)*isnull(CO.targetpercent,100) /100
				from componentoperationpricing CO inner join (select distinct machineid,component,operation,shiftstart,shiftend from #ShiftTemp) as #ShiftTemp on CO.Componentid=#ShiftTemp.Component
				and Co.operationno=#ShiftTemp.operation and #ShiftTemp.machineid=CO.machineid'
		select @strsql= @strsql +' inner join machineinformation on machineinformation.machineid=CO.machineid 
		Left Outer Join PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID where 1=1'
		select @strsql = @strsql + @strmachine+@strPlantID+@StrTPMMachines
		select @strsql=@strsql + '  ) as t group by T.machineid ) as T1 inner join #CockpitData on t1.machineid = #CockpitData.machineid '
		print @strsql
		EXEC (@strsql)

		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
		BEGIN
			update #CockpitData set ShiftTarget=ShiftTarget-((cast(t3.Totalpdt as float)/cast(t3.totaltime as float))*ShiftTarget) from
			(
			   Select Machineid,SUM(datediff(ss,Starttime,Endtime)) as totaltime,Sum(Datediff(ss,Starttimepdt,Endtimepdt))as TotalPDT From
			   (
					select fd.StartTime,fd.EndTime,Case when fd.StartTime <= pdt.StartTime then pdt.StartTime else fd.StartTime End as Starttimepdt
					,Case when fd.EndTime >= pdt.EndTime then pdt.EndTime else fd.EndTime End as Endtimepdt,fd.MachineID from
					(Select distinct Machineid,Shiftstart as StartTime ,shiftend as EndTime from #ShiftTemp) as fd
					cross join planneddowntimes pdt
					where PDTstatus = 1  and fd.machineID = pdt.Machine and 
					((pdt.StartTime >= fd.StartTime and pdt.EndTime <= fd.EndTime)or
					(pdt.StartTime < fd.StartTime and pdt.EndTime > fd.StartTime and pdt.EndTime <=fd.EndTime)or
					(pdt.StartTime >= fd.StartTime and pdt.StartTime <fd.EndTime and pdt.EndTime > fd.EndTime) or
					(pdt.StartTime < fd.StartTime and pdt.EndTime > fd.EndTime))
				)T2 group by Machineid
			)T3 inner join #CockpitData on T3.Machineid=#CockpitData.machineid
						
		End
	END


		Select @strsql=''   
		Select @strsql= 'insert into #Target(MachineID,machineinterface,Component,Compinterface,Operation,Opninterface,  
		msttime,ndtime,Pdate,Shift,FromTm,Totm,batchid,autodataid,stdtime,SubOperations)'  
		select @strsql = @strsql + ' SELECT machineinformation.machineid, machineinformation.interfaceid,componentinformation.componentid, componentinformation.interfaceid,  
		componentoperationpricing.operationno, componentoperationpricing.interfaceid,  
		Case when autodata.msttime< T.Shiftstart then T.Shiftstart else autodata.msttime end,   
		Case when autodata.ndtime> T.ShiftEnd then T.ShiftEnd else autodata.ndtime end,  
		T.Pdate,T.ShiftName,T.shiftstart,T.Shiftend,0,autodata.id,componentoperationpricing.Cycletime,componentoperationpricing.SubOperations FROM #T_autodata autodata  with(nolock)
		INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID   
		INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID    
		INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID  
		AND componentinformation.componentid = componentoperationpricing.componentid  
		and componentoperationpricing.machineid=machineinformation.machineid   
		Left Outer Join downcodeinformation DI on DI.interfaceid=autodata.dcode  
		Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid   
		Cross join (select distinct Pdate,ShiftName,shiftstart,Shiftend from #shifttemp) T  
		WHERE (autodata.ndtime > T.Shiftstart  AND autodata.ndtime <= T.ShiftEnd)  
		--OR ( autodata.msttime < T.Shiftstart  AND autodata.ndtime <= T.ShiftEnd AND autodata.ndtime >T.Shiftstart )  
		--OR ( autodata.msttime >= T.Shiftstart AND autodata.msttime <T.ShiftEnd AND autodata.ndtime > T.ShiftEnd)  
		--OR ( autodata.msttime < T.Shiftstart AND autodata.ndtime > T.ShiftEnd))'  
		select @strsql = @strsql + @strmachine + @strPlantID 
		select @strsql = @strsql + ' order by autodata.msttime'  
		print @strsql  
		exec (@strsql)  
  
  /* --------------------- ER0466 Performance Optimization From Here-------------------------------------------
			declare @mc_prev nvarchar(50),@comp_prev nvarchar(50),@opn_prev nvarchar(50),@From_Prev datetime  
			declare @mc nvarchar(50),@comp nvarchar(50),@opn nvarchar(50),@Fromtime datetime,@id nvarchar(50)  
			declare @batchid int  
			Declare @autodataid bigint,@autodataid_prev bigint  
  
			declare @setupcursor  cursor  
			set @setupcursor=cursor for  
			select autodataid,FromTm,MachineID,Component,Operation from #Target order by machineid,msttime  
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
			If @mc_prev=@mc and @comp_prev=@comp and @opn_prev=@opn and  @From_Prev = @Fromtime  
			begin    
			update #Target set batchid = @batchid where autodataid=@autodataid and MachineID=@mc and Component=@comp and Operation=@opn and  FromTm=@Fromtime   
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

			insert into #FinalTarget (MachineID,Component,operation,machineinterface,Compinterface,Opninterface,batchid,BatchStart,BatchEnd,Pdate,shift,FromTm,ToTm,stdtime,Runtime)   
			Select MachineID,Component,operation,machineinterface,Compinterface,Opninterface,batchid,min(msttime),max(ndtime),Pdate,shift,FromTm,ToTm,stdtime,0 from #Target   
			group by MachineID,Component,operation,machineinterface,Compinterface,Opninterface,batchid,Pdate,shift,FromTm,ToTm,stdtime order by batchid   
   */

		insert into #FinalTarget(MachineID,Component,operation,machineinterface,Compinterface,Opninterface,batchid,BatchStart,BatchEnd,Pdate,shift,FromTm,ToTm,stdtime,Runtime,SubOperations) 
		select MachineID,Component,operation,machineinterface,Compinterface,Opninterface,batchid,min(msttime),max(ndtime),Pdate,shift,FromTm,ToTm,stdtime,0,SubOperations
		from
		(
		select MachineID,Component,operation,machineinterface,Compinterface,Opninterface,msttime,ndtime,Pdate,shift,FromTm,ToTm,stdtime,SubOperations,
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
		group by MachineID,Component,operation,machineinterface,Compinterface,Opninterface,batchid,Pdate,FromTm,ToTm,stdtime,shift,SubOperations
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
 --------------------- ER0466 Performance Optimization Till Here------------------------------------------



		update #FinalTarget set Target= isnull(t2.tcount,0) from
		(
		select F.BatchStart,F.BatchEnd,F.Machineid, CO.componentid as component,CO.Operationno as operation,
		tcount=((F.Runtime*CO.suboperations)/CO.cycletime)*isnull(CO.targetpercent,100) /100
		from componentoperationpricing CO
		inner join #FinalTarget F on co.machineid=F.machineid and CO.Componentid=F.Component and Co.operationno=F.Operation  
		) as T2 Inner Join #FinalTarget on t2.Machineid = #FinalTarget.Machineid and  
		t2.component = #FinalTarget.component and t2.Operation = #FinalTarget.Operation   
		and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd 

		
		If @Targetdef='ByRunTime' 
		BEGIN
			update #CockpitData set ShiftTarget=ShiftTarget + isnull(t2.Target,0) from
			(Select machineid,SUM(Target) as target from #FinalTarget
			group by machineid)T2 inner join #CockpitData on #CockpitData.MachineID=T2.MachineID
		End
----ER0459


	update #CockpitData set RunningCOTarget=RunningCOTarget + isnull(t2.Target,0) from
	(
	select F.Machineid,((F.Runtime*CO.suboperations)/CO.cycletime)*isnull(CO.targetpercent,100)/100 as target from componentoperationpricing CO
	inner join
	( Select machineid,component,Operation,Runtime from 
		(Select machineid,component,Operation,SUM(Runtime) as Runtime,max(batchend) as batchend,ROW_NUMBER() over(Partition by machineid Order by machineid,batchend desc) as rn
		from #FinalTarget group by machineid,component,Operation,batchend
		)T where T.rn=1
	)F on co.machineid=F.machineid and co.componentid=F.component and co.operationno=F.operation
	) as T2 Inner Join #CockpitData on t2.Machineid = T2.Machineid 

	Select machineinterface,Compinterface,OpnInterface,SubOperations into #RunningCO from 
	(Select machineinterface,Compinterface,Opninterface,SubOperations,ROW_NUMBER() over(Partition by machineid Order by machineid,batchend desc) as rn
	from #FinalTarget
	)F where F.rn=1

	--Calculation of PartsCount Begins..
	UPDATE #CockpitData SET RunningCOActual = ISNULL(RunningCOActual,0) + ISNULL(t2.comp,0)
	From
	(
	Select mc,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(T1.SubOperations,1))) As Comp --NR0097
	From (select mc,SUM(autodata.partscount)AS OrginalCount,comp,opn,SubOperations from #T_autodata autodata
	inner join #RunningCO R on R.machineinterface=Autodata.mc and R.Compinterface=Autodata.comp and R.Opninterface = Autodata.opn
	where (autodata.ndtime>@StartTime) and (autodata.ndtime<=@EndTime) and (autodata.datatype=1)
	Group By mc,comp,opn,SubOperations) as T1
	GROUP BY mc
	) As T2 Inner join #CockpitData on T2.mc = #CockpitData.machineinterface

	--Mod 4 Apply PDT for calculation of Count
	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
	BEGIN

		UPDATE #CockpitData SET RunningCOActual = ISNULL(RunningCOActual,0) - ISNULL(T2.comp,0) from
		(
		Select mc,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(T1.SubOperations,1))) As Comp --NR0097
		From (select mc,SUM(autodata.partscount)AS OrginalCount,comp,opn,SubOperations from #T_autodata autodata
		cross join #PlannedDownTimes T
		inner join #RunningCO R on R.machineinterface=Autodata.mc and R.Compinterface=Autodata.comp and R.Opninterface = Autodata.opn
		WHERE autodata.DataType=1 And T.MachineInterface = autodata.mc    
		AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)    
		AND (autodata.ndtime > @StartTime  AND autodata.ndtime <=@EndTime)   and (autodata.datatype=1)
		Group By mc,comp,opn,SubOperations) as T1
		GROUP BY mc
		) as T2 inner join #CockpitData on T2.mc = #CockpitData.machineinterface
	END


	Declare @Keihin_AndonTarget as nvarchar(50)
	Select @Keihin_AndonTarget = Isnull(valueintext,'%Ideal') from Shopdefaults where parameter='Keihin_AndonTargetFrom'

	If @Keihin_AndonTarget = '%Ideal'
	Begin
	
			Select @strsql=''
			select @strsql='update #ShiftTemp set HourlyTarget= isnull(HourlyTarget,0)+ ISNULL(t1.tcount,0) from
					 ( select CO.componentid as component,CO.Operationno as operation,CO.machineid,tcount=((datediff(second,#ShiftTemp.fromtime,#ShiftTemp.totime)*CO.suboperations)/CO.cycletime)*isnull(CO.targetpercent,100) /100
					from componentoperationpricing CO inner join #ShiftTemp on CO.Componentid=#ShiftTemp.Component
					and Co.operationno=#ShiftTemp.operation and #ShiftTemp.machineid=CO.machineid'
			select @strsql= @strsql +' inner join machineinformation on machineinformation.machineid=CO.machineid 
			Left Outer Join PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID where 1=1'
			select @strsql = @strsql + @strmachine+@strPlantID+@StrTPMMachines
			select @strsql=@strsql + '  ) as t1 inner join #ShiftTemp on t1.component=#ShiftTemp.Component and t1.operation=#ShiftTemp.operation and t1.machineid = #ShiftTemp.machineid '
			print @strsql
			EXEC (@strsql)
			
			If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
			BEGIN
				update #ShiftTemp set HourlyTarget=HourlyTarget-((cast(t3.Totalpdt as float)/cast(datediff(ss,t3.Starttime,t3.Endtime) as float))*HourlyTarget) from
				(
				   Select Machineid,Starttime,Endtime,Sum(Datediff(ss,Starttimepdt,Endtimepdt))as TotalPDT From
				   (
						select fd.StartTime,fd.EndTime,Case when fd.StartTime <= pdt.StartTime then pdt.StartTime else fd.StartTime End as Starttimepdt
						,Case when fd.EndTime >= pdt.EndTime then pdt.EndTime else fd.EndTime End as Endtimepdt,fd.MachineID from
						(Select distinct Machineid,fromtime as StartTime ,totime as EndTime from #ShiftTemp) as fd
						cross join planneddowntimes pdt
						where PDTstatus = 1  and fd.machineID = pdt.Machine and 
						((pdt.StartTime >= fd.StartTime and pdt.EndTime <= fd.EndTime)or
						(pdt.StartTime < fd.StartTime and pdt.EndTime > fd.StartTime and pdt.EndTime <=fd.EndTime)or
						(pdt.StartTime >= fd.StartTime and pdt.StartTime <fd.EndTime and pdt.EndTime > fd.EndTime) or
						(pdt.StartTime < fd.StartTime and pdt.EndTime > fd.EndTime))
					)T2 group by Machineid,Starttime,Endtime
				)T3 inner join #ShiftTemp on T3.Machineid=#ShiftTemp.machineid and T3.Starttime=#ShiftTemp.fromtime and T3.Endtime= #ShiftTemp.totime
		   End



	END


	If @Keihin_AndonTarget = 'HourlyTargets'
	Begin

		Update #ShiftTemp set HourlyTarget = Isnull(ST.HourlyTarget,0) + Isnull(T1.Target,0) from
		(
		select T.Sdate,T.Machineid,T.Componentid,T.Operationno,T.Shiftid,T.hourid,T.Target
		from (
			 select S.Sdate,S.Machineid,S.Componentid,S.Operationno,S.Shiftid,S.hourid,S.Target,
			 row_number() over(partition by S.Machineid,S.Componentid,S.Operationno,S.shiftid,S.hourid order by S.Sdate desc) as rn
			 from Shifthourtargets S inner join #ShiftTemp T on T.Machineid=S.Machineid and T.Operation=S.Operationno and
			 T.Component=S.Componentid and T.Shiftid=S.Shiftid and T.Hourid=S.Hourid 
			 where S.Sdate<=T.Pdate) as T 
		where T.rn <= 1)T1 inner join #ShiftTemp ST on ST.Machineid=T1.Machineid and ST.Operation=T1.Operationno and
		T1.Componentid=ST.Component and ST.Shiftid=T1.Shiftid and ST.Hourid=T1.Hourid 
	END

	update #shift Set Actual=T1.Actual,HourlyTarget=T1.target from 
	(Select Machineid,fromtime,totime,Sum(Actual) as Actual,Sum(HourlyTarget) as Target from #Shifttemp
	group by Machineid,fromtime,totime)T1 inner join #shift on #shift.machineid=T1.machineid and #shift.fromtime=T1.fromtime and #shift.totime=T1.Totime


	select @strsql=''
	SELECT @strsql= @strsql + 'insert into #Runningpart_Part(Machineid,Componentid,CompDescription,OperationNo,OpnDescription,OperatorName,Sttime)
	  select Machineinformation.machineid,C.Componentid,C.Description,CO.operationNo,CO.Description,E.Name,Max(A.Sttime) from 
	  (
	   Select Mc,Comp,Opn,Opr,Max(sttime) as Sttime From #T_autodata A  
	   where sttime>='''+convert(nvarchar(20),@starttime)+''' and ndtime<='''+convert(nvarchar(20),@endtime)+'''
	   Group by Mc,Comp,Opn,Opr
	  ) as A
	  inner join Machineinformation on A.mc=Machineinformation.interfaceid  
	  inner join Componentinformation C on A.comp=C.interfaceid  
	  inner join Componentoperationpricing CO on A.opn=CO.interfaceid and Machineinformation.Machineid=CO.Machineid and C.Componentid=CO.Componentid 
	  inner join Employeeinformation E on A.Opr=E.interfaceid ' 
	SELECT @strsql = @strsql + @strmachine  
	SELECT @strsql = @strsql +'group by Machineinformation.machineid,C.Componentid,C.Description,CO.operationNo,CO.Description,E.Name'
	print @strsql
	exec (@strsql)  

--	Update #Cockpitdata Set Componentid = isnull(T.Comp,0),CompDescription = isnull(T.Cdes,0),
--	OperationNo = isnull(T.opn,0),OpnDescription = isnull(T.opndes,0),
--	OperatorName = isnull(T.opr,0) from
--	(select Machineid,Componentid as comp,CompDescription as Cdes,OperationNo as opn,OpnDescription as Opndes,OperatorName as opr,Max(Sttime) as sttime
--	From #Runningpart_Part group by Machineid,Componentid,CompDescription,OperationNo,OpnDescription,OperatorName
--	)T inner join #Cockpitdata on #Cockpitdata.machineid=T.machineid 

	Update #Cockpitdata Set Componentid = isnull(T1.Comp,0),CompDescription = isnull(T1.Cdes,0),
	OperationNo = isnull(T1.opn,0),OpnDescription = isnull(T1.opndes,0)
	from
	(Select T.Machineid,T.comp,T.Cdes,T.opn,T.Opndes from
		(select Machineid,Componentid as comp,CompDescription as Cdes,OperationNo as opn,OpnDescription as Opndes,sttime,
		row_number() over(partition by Machineid,Componentid,OperationNo order by sttime desc) as rn
		From #Runningpart_Part 
		)T where T.rn <= 1
	) as T1 inner join #Cockpitdata on #Cockpitdata.machineid=T1.machineid 


	Update #Cockpitdata Set OperatorName = isnull(T1.opr,0) from
	(Select T.Machineid,T.opr from
		(select Machineid,OperatorName as opr,sttime,
		row_number() over(partition by Machineid order by sttime desc) as rn
		From #Runningpart_Part 
		)T where T.rn <= 1
	) as T1 inner join #Cockpitdata on #Cockpitdata.machineid=T1.machineid 

	Update #Cockpitdata Set Remarks = Isnull(Remarks,0) + isnull(T.Comp,0) from
	(select top 1 componentid as Comp,isnull(machineid ,'') as machineid from #Runningpart_Part
	order by sttime desc)T inner join #Cockpitdata 
	on #Cockpitdata.machineid=T.machineid 

--	declare @SortOrder as nvarchar(100)
--	Select @SortOrder = Valueintext2 from Shopdefaults where ValueInText ='OrderBy' and parameter='AndonCockpitAppSettings'

	If ISNULL(@SortOrder,'')=''
	BEGIN
		SET @SortOrder = 'OverAllEfficiency DESC'
	END

--ER0460
If ISNULL(@machineid,'')='' 
Begin	
	Update #Cockpitdata Set PlantOEE = Isnull(PlantOEE,0) + isnull(T.POEE,0) from
	(select ST.PlantID,AVG(ST.OverAllEfficiency) as POEE from #Cockpitdata ST 
	Group by ST.PlantID)T inner join #Cockpitdata 
	on #Cockpitdata.PlantID=T.PlantID 
END
--ER0460

If @param = ''
Begin

	If @SHIFT<>''
	Begin
		Select @strsql=''
		Select @Strsql = @Strsql +
		'select ST.PlantID,ST.Machineid,ST.Shiftname,ST.AvailabilityEfficiency,ST.ProductionEfficiency,ST.OverAllEfficiency,ST.QualityEfficiency,
		dbo.f_FormatTime(ST.UtilisedTime,''' + @timeformat + ''') as UtilisedTime,dbo.f_FormatTime(ST.DownTime,''' + @timeformat + ''') as DownTime,
		dbo.f_FormatTime(ST.ManagementLoss,''' + @timeformat + ''') as ManagementLoss,
		ST.CN,ST.Components,ST.RejCount,
		Substring(CONVERT(varchar,ST.Lastcycletime,106),1,2)+ ''-'' + substring(CONVERT(varchar,ST.Lastcycletime,106),4,3)+ '' '' + RIGHT(''0''+LTRIM(RIGHT(CONVERT(varchar,ST.Lastcycletime,100),8)),7) as LastCycletime,
		MachineStatus,ST.Oecolor,ST.Pecolor,ST.Aecolor,ST.QeColor,ST.Down1,ST.Down2,ST.Down3,ST.Remarks,
		S.Hourid,S.Actual,S.Target
		,ST.Componentid + '' ('' + Substring(ST.CompDescription,1,12) + '')''  as CompAndDescription,ST.OperationNo + '' ('' + Substring(ST.OpnDescription,1,12) + '')'' as OpnAndDescription,ST.OperatorName --SV added For DevendraExport
		,ST.Shifttarget,ST.PlantOEE --ER0460
		,ST.RunningCOActual,ST.RunningCOTarget
		 from #Cockpitdata ST
		Left Outer join (Select Machineid,hourid,Actual,HourlyTarget as Target from #shift where  ''' + Convert(nvarchar(20),@CurrTime,120) + '''>Fromtime and ''' + Convert(nvarchar(20),@CurrTime,120) + '''<=Totime)S on S.Machineid=ST.Machineid 
		--order by ST.Plantid,ST.Machineid
		order by ST.' + @SortOrder + ''
		print @strsql
		exec(@strsql)
	END

	If @SHIFT=''
	Begin
		Select @strsql=''
		Select @Strsql = @Strsql +
		'select ST.PlantID,ST.Machineid,''ALL'' as Shiftname,ST.AvailabilityEfficiency,ST.ProductionEfficiency,ST.OverAllEfficiency,ST.QualityEfficiency,
		dbo.f_FormatTime(ST.UtilisedTime,''' + @timeformat + ''') as UtilisedTime,dbo.f_FormatTime(ST.DownTime,''' + @timeformat + ''') as DownTime,
		dbo.f_FormatTime(ST.ManagementLoss,''' + @timeformat + ''') as ManagementLoss,
		ST.CN,ST.Components,ST.RejCount,
		Substring(CONVERT(varchar,ST.Lastcycletime,106),1,2)+ ''-'' + substring(CONVERT(varchar,ST.Lastcycletime,106),4,3)+ '' '' + RIGHT(''0''+LTRIM(RIGHT(CONVERT(varchar,ST.Lastcycletime,100),8)),7) as LastCycletime,
		MachineStatus,ST.Oecolor,ST.Pecolor,ST.Aecolor,ST.QeColor,ST.Down1,ST.Down2,ST.Down3,ST.Remarks,
		S.Hourid,S.Actual,S.Target
		,ST.Componentid + '' ('' + Substring(ST.CompDescription,1,12) + '')''  as CompAndDescription,ST.OperationNo + '' ('' + Substring(ST.OpnDescription,1,12) + '')'' as OpnAndDescription,ST.OperatorName --SV added For DevendraExport
		,ST.Shifttarget,ST.PlantOEE --ER0460
		,ST.RunningCOActual,ST.RunningCOTarget		 
		from #Cockpitdata ST
		Left Outer join (Select Machineid,hourid,Actual,HourlyTarget as Target from #shift where  ''' + Convert(nvarchar(20),@CurrTime,120) + '''>Fromtime and ''' + Convert(nvarchar(20),@CurrTime,120) + '''<=Totime)S on S.Machineid=ST.Machineid 
		--order by ST.Plantid,ST.Machineid
		where St.Shiftname=(select Shiftname from shiftdetails where shiftid=1 and running=1)
		order by ST.' + @SortOrder + ''
		print @strsql
		exec(@strsql)
	END
End


If @param = 'DowntimePrediction'
Begin

	delete from #machineRunningStatus

--ER0464 --g: using MachineRunningStatus table instead of rawdata
	--Insert into #machineRunningStatus
	--select fd.MachineID,fd.MachineInterface,sttime,ndtime,datatype,'White',@Endtime,0 from rawdata
	--inner join (select mc,max(slno) as slno from rawdata WITH (NOLOCK) where sttime<@EndTime and isnull(ndtime,'1900-01-01')<@EndTime
	--and datatype in(2,42,40,41,1,11) and datepart(year,sttime)>'2000' group by mc ) t1 on t1.mc=rawdata.mc and t1.slno=rawdata.slno --For SAF DR0370
	--right outer join #CockpitData fd on fd.MachineInterface = rawdata.mc
	--order by rawdata.mc
	
	Insert into #machineRunningStatus(MachineID,MachineInterface,sttime,ndtime,datatype,ColorCode,StartTime,Downtime)
	select fd.MachineID,fd.MachineInterface,sttime,ndtime,datatype,ColorCode,@EndTime,0 from MachineRunningStatus mr    
	right outer join #CockpitData fd on fd.MachineInterface = mr.MachineInterface
	where sttime<@currtime and isnull(ndtime,'1900-01-01')<@currtime
order by fd.MachineInterface
--ER0464 --g: using MachineRunningStatus table instead of rawdata

--	update #machineRunningStatus Set Starttime=T2.StartDate
--	From #machineRunningStatus inner join
--	(Select R.Machineinterface,Case 
--	when R.Datatype=1 then Dateadd(second,@Type1Threshold,R.ndtime)  --Dateadd(n,10,ndtime) 
--	when R.datatype=40 then Dateadd(second,@Type40Threshold,R.sttime)--Dateadd(n,10,sttime)
--	when R.datatype=11 then Dateadd(second,@Type11Threshold,R.sttime)
--	when R.datatype=2 or R.datatype=42 then R.sttime
--	End as StartDate
--	from  #machineRunningStatus R)T2 On T2.Machineinterface=#machineRunningStatus.Machineinterface


	update #machineRunningStatus Set Starttime=T1.StartDate from (
	Select R.Machineinterface,Case when (
	case when R.datatype = 40 then datediff(second,R.sttime,@EndTime)- @Type40Threshold
	when R.datatype = 11 then datediff(second,R.sttime,@EndTime)- @Type11Threshold
	end) > 0 then R.sttime else @EndTime end as StartDate
	from #machineRunningStatus R
	where R.datatype in ('40','11')
	) as t1 inner join #machineRunningStatus on t1.Machineinterface = #machineRunningStatus.Machineinterface

	update #machineRunningStatus Set Starttime=t1.StartDate from (
	Select R.Machineinterface,Case when (
	case 
	when R.datatype = 1 then datediff(second,R.ndtime,@EndTime)- @Type1Threshold
	end) > 0 then R.ndtime else @EndTime end as StartDate
	from #machineRunningStatus R 
	where R.datatype in ('1')
	) as t1 inner join #machineRunningStatus on t1.Machineinterface = #machineRunningStatus.Machineinterface

	update #machineRunningStatus Set Starttime=t1.StartDate from (
	Select R.Machineinterface,case 
	when R.datatype=2 or R.datatype=42 then R.sttime end as StartDate
	from #machineRunningStatus R 
	where R.datatype in ('2','42')
	) as t1 inner join #machineRunningStatus on t1.Machineinterface = #machineRunningStatus.Machineinterface

	--update #machineRunningStatus Set Downtime=datediff(second,Starttime,@EndTime)  

	update #machineRunningStatus Set Downtime=datediff(second,Starttime,case when @EndTime<Starttime then Starttime else @EndTime end)  





	/*Appling PDT*/
	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
	BEGIN		
		update #machineRunningStatus set downtime=downtime-down from #machineRunningStatus
		inner join (
			Select t1.machineid,sum(isnull(datediff(ss,T1.StartTime,T1.EndTime),0))as down
			from
			(
			select D.machineid,
			Case when  D.Starttime <= pdt.StartTime then pdt.StartTime else  D.Starttime End as StartTime,
			Case when @Shiftend >= pdt.EndTime then pdt.EndTime else @Shiftend End as EndTime
			From Planneddowntimes pdt
			inner join #machineRunningStatus D on D.machineid=Pdt.machine
			where PDTstatus = 1  and --pdt.Machine=@machineid and
			((pdt.StartTime >= D.Starttime and pdt.EndTime <= @Shiftend)or
			(pdt.StartTime < D.Starttime and pdt.EndTime > D.Starttime and pdt.EndTime <=@Shiftend)or
			(pdt.StartTime >= D.Starttime and pdt.StartTime <@Shiftend and pdt.EndTime >@Shiftend) or
			(pdt.StartTime <  D.Starttime and pdt.EndTime >@Shiftend))
			) T1
			group by T1.machineid
		)t2 on t2.machineid=#machineRunningStatus.machineId
	End

	UPDATE #CockpitData SET Remarks = ' '
	UPDATE #CockpitData SET Remarks = 'Machine Not In Production' WHERE UtilisedTime = 0 and Downtime=0

   select ST.PlantID,ST.Machineid,ST.Shiftname,ISNULL(ST.Downtime,0)+ISNULL(M.DownTime,0) as DownTime,ST.Remarks from #Cockpitdata ST
   left outer join #machineRunningStatus M on ST.machineid=M.machineid
   Order by ST.PlantID,ST.Machineid
--
End


END
