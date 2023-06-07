/****** Object:  Procedure [dbo].[s_GetAndonDetails_Pooja]    Committed by VersionSQL https://www.versionsql.com ******/

/*
Created By: Raksha R
Created Date: 07-Sep-2022

Exec [dbo].[s_GetAndonDetails_Pooja]  '2022-09-03 14:00:00','FIRST','','','NPD',''
Exec [dbo].[s_GetAndonDetails_Pooja]  '2022-09-10 10:00:00','FIRST','','','',''
Exec [dbo].[s_GetAndonDetails_Pooja]  '2022-09-07 14:00:00','Second','','PC VMC 436','NPD',''
exec [s_GetAndonDetails_Pooja] @Date=N'2022-11-18 07:00:00',@Shift=N'FIRST',@PlantID=N'POOJA CASTING',@GroupID=N'MACHINE SHOP'

*/
CREATE     PROCEDURE [dbo].[s_GetAndonDetails_Pooja]  
 @Date datetime,
 @Shift nvarchar(50),
 @PlantID nvarchar(50)='',
 @MachineID nvarchar(max) = '',  
 @GroupID nvarchar(max)='',
 @param nvarchar(50)=''

AS  
BEGIN  

Declare @strsql as nvarchar(max)
Declare @StrPlantid as nvarchar(1000)  
Declare @strMachine as nvarchar(max)
declare @StrGroupID as nvarchar(max)
Declare @StrExMachine As Nvarchar(max)
Declare @StrTPMMachines AS nvarchar(500)
declare @timeformat as nvarchar(2000)
declare @StrMCJoined as nvarchar(max)
declare @StrGroupJoined as nvarchar(max)

SELECT @StrTPMMachines=''
select @StrExMachine=''
select @strPlantID = '' 
SELECT @strMachine = ''
select @StrGroupID=''
SELECT @timeformat ='ss'

Select @timeformat = isnull((select valueintext from cockpitdefaults where parameter='timeformat'),'ss')
if (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')
begin
	select @timeformat = 'ss'
end

if isnull(@PlantID,'')<> ''  
Begin   
 SET @strPlantID = ' AND PlantMachine.PlantID = N''' + @PlantID + '''  '  
End  

IF ( SELECT TOP 1 ValueInText FROM  CockpitDefaults WHERE Parameter='TpmEnbMac')='E'
BEGIN
	SET  @StrTPMMachines = ' AND MachineInformation.TPMTrakEnabled = 1 '
END
ELSE
BEGIN
	SET  @StrTPMMachines = ' '
END
if isnull(@machineid,'')<> ''
begin
	select @StrMCJoined =  (case when (coalesce( +@StrMCJoined + ',''', '''')) = ''''  then 'N''' else @StrMCJoined+',N''' end) +item+'''' from [SplitStrings](@MachineID, ',')    
	if @StrMCJoined = 'N'''''  
	set @StrMCJoined = '' 
	select @MachineID = @StrMCJoined

	SET @strMachine = ' AND Machineinformation.machineid in (' + @MachineID +')'
	SELECT @StrExMachine=' AND Ex.machineid in (' + @MachineID +')'
end
if isnull(@GroupID,'')<> ''
Begin
	select @StrGroupJoined =  (case when (coalesce( +@StrGroupJoined + ',''', '''')) = ''''  then 'N''' else @StrGroupJoined+',N''' end) +item+'''' from [SplitStrings](@GroupID, ',')    
	if @StrGroupJoined = 'N'''''  
	set @StrGroupJoined = '' 
	select @GroupID = @StrGroupJoined

	SET @strGroupID = ' AND PlantMachineGroups.GroupID in (' + @GroupID +')'
End

CREATE TABLE #ShiftDefn  
(  
 ShiftDate datetime,    
 Shiftname nvarchar(20),  
 ShftSTtime datetime,  
 ShftEndTime datetime   
) 

INSERT INTO #ShiftDefn(ShiftDate,Shiftname,ShftSTtime,ShftEndTime) 
Exec s_GetShiftTime @Date,@Shift

create table #shift  
(  
 ShiftDate nvarchar(10), --DR0333  
 shiftname nvarchar(20),  
 Shiftstart datetime,  
 Shiftend datetime,  
 shiftid int  
)  
  
Insert into #shift (ShiftDate,shiftname,Shiftstart,Shiftend)  
select convert(nvarchar(10),ShiftDate,126),shiftname,ShftSTtime,ShftEndTime from #ShiftDefn 
  
Update #shift Set shiftid = isnull(#shift.Shiftid,0) + isnull(T1.shiftid,0) from  
(Select SD.shiftid ,SD.shiftname from shiftdetails SD  
inner join #shift S on SD.shiftname=S.shiftname where  
running=1 )T1 inner join #shift on  T1.shiftname=#shift.shiftname  

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
  

CREATE TABLE #CockPitData   
(  
	MachineID nvarchar(50),  
	MachineInterface nvarchar(50) PRIMARY KEY,  
	ProductionEfficiency float,  
	AvailabilityEfficiency float,  
	QualityEfficiency float, --ER0368  
	OverallEfficiency float,  
	Components float,  
	RejCount float,  --ER0368  
	TotalTime float,  
	UtilisedTime float,  
	ManagementLoss float,  
	DownTime float,  
	TurnOver float,  
	ReturnPerHour float,  
	ReturnPerHourtotal float,  
	CN float,    
	Remarks nvarchar(1000),
	Remarks1 nvarchar(50), --ER0368  
	Remarks2 nvarchar(50), --ER0368  
	LastCycleTime datetime,  
	PEGreen smallint,  
	PERed smallint,  
	AEGreen smallint,  
	AERed smallint,  
	OEGreen smallint,  
	OERed smallint,  
	QEGreen smallint, --ER0368  
	QERed smallint, --ER0368  
	MaxDownReason nvarchar(50) DEFAULT ('')  
	,MLDown float,    
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
	OperatorName nvarchar(50),
	MachineLiveStatus nvarchar(50),
    MachineLiveStatusColor nvarchar(50),
	LastCycleCO nvarchar(100) DEFAULT (''),  
	LastCycleCompInterface nvarchar(100) DEFAULT (''),  
	LastCycleCompDescription nvarchar(100) DEFAULT (''),
	LastCycleOperation nvarchar(50) DEFAULT (''),
	LastCycleOpnInterface nvarchar(100) DEFAULT (''),  
	LastCycleOpnDescription nvarchar(100) DEFAULT (''),
	LastCycleOpr nvarchar(50) DEFAULT (''),
	LastCycleOprName nvarchar(50) DEFAULT (''),
	LastCompletedDowntime nvarchar(500),
	CurrentDowntime nvarchar(50),
	RunningCycleStdTime float,
    RunningComponentBoxColor nvarchar(50),
    ReworkCount float,
	StatusColor nvarchar(50) DEFAULT ('Red'),
	ProductionTarget Float default 0,
	ActualParts float default 0
)  

CREATE TABLE #Exceptions  
(  
 MachineID NVarChar(50),  
 ComponentID Nvarchar(50),  
 OperationNo Int,  
 StartTime DateTime,  
 EndTime DateTime,  
 IdealCount Int,  
 ActualCount Int,  
 ExCount float --NR0097  
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
 MachineID nvarchar(50) NOT NULL, --ER0374  
 MachineInterface nvarchar(50) NOT NULL, --ER0374  
 StartTime DateTime NOT NULL, --ER0374  
 EndTime DateTime NOT NULL --ER0374  
)  

ALTER TABLE #PlannedDownTimes  
 ADD PRIMARY KEY CLUSTERED  
  (   [MachineInterface],  
   [StartTime],  
   [EndTime]  
        
  ) ON [PRIMARY]  

create table #Runningpart_Part  
(    
 Machineid nvarchar(50),    
 Componentid nvarchar(50),  
 StTime Datetime,
 OperatorName nvarchar(50)  
)   

CREATE TABLE #MachineRunningStatus  
(  
 MachineID NvarChar(50),  
 MachineInterface nvarchar(50),  
 sttime Datetime,  
 ndtime Datetime,  
 DataType smallint,  
 ColorCode varchar(10),  
 Comp NvarChar(50), ----ER0466  
 Opn NvarChar(50), ----ER0466  
 StartTime datetime, ----ER0466  
 Downtime float, ----ER0466  
 Totaltime int, ----ER0466  
 ManagementLoss float, ----ER0466  
 UT float,----ER0466  
 PDT float,----ER0466  
 LastRecorddatatype int, --ER0466  
 AutodataMaxtime datetime, --er0466  
 PingStatus nvarchar(50)

)  
 
 create table #PDT
(
machine nvarchar(50),
StartTime datetime
)

create table #Timeinfo
(
id int identity(1,1) NOT NULL,
machine nvarchar(50),
StartTime datetime,
endtime datetime,
ISICD int
)

CREATE TABLE #PlantCellwiseSummary
(
	Plantid nvarchar(50),
	Groupid nvarchar(50),
	MachineID nvarchar(50),
	MachineInterface nvarchar(50),
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
	CN float,
	MaxDownReason nvarchar(50) DEFAULT (''),
	GroupDescription nvarchar(150),
	PlantDescription nvarchar(150),
	ReworkCount float

)
 
Declare @CurrTime as DateTime  
SET @CurrTime = convert(nvarchar(20),getdate(),120)  
--SET @CurrTime = @Date
print @CurrTime  
 
 CREATE TABLE #Focas_MachineRunningStatus
(
	[Machineid] [nvarchar](50) NULL,
	[Datatype] [nvarchar](50) NULL,
	[LastCycleTS] [datetime] NULL,
	[AlarmStatus] [nvarchar](50) NULL,
	[SpindleStatus] [int] NULL,
	[SpindleCycleTS] [datetime] NULL,
	[PowerOnOrOff] [int] NULL,
	Machinestatus nvarchar(50)
)

Create table #MachineOnlineStatus
(
Machineid nvarchar(50),
LastConnectionOKTime datetime,
LastConnectionFailedTime datetime,
LastPingFailedTime datetime,
LastPingOkTime datetime,
LastPLCCommunicationOK datetime,
LastPLCCommunicationFailed datetime
)

Create table #MasterTemp
(
	MachineID nvarchar(50),
	MachineInt nvarchar(50),
	MachineDescription nvarchar(250),
	ComponentID nvarchar(50),
	ComponentInt nvarchar(50),
	OperationNo nvarchar(50),
	OperationInt int,
	OperatorID nvarchar(50),
	OperatorInt nvarchar(50),
	stdTime float,
	SubOperations int
)

CREATE TABLE #RunTime    
(  
  
MachineID nvarchar(50) NOT NULL,  
machineinterface nvarchar(50),  
Compinterface nvarchar(50),  
OpnInterface nvarchar(50), 
Component nvarchar(50) NOT NULL,  
Operation nvarchar(50) NOT NULL,  
OperatorID nvarchar(50) ,
OperatorInt nvarchar(50) ,
FromTm datetime,  
ToTm datetime,     
msttime datetime,  
ndtime datetime,  
batchid int,  
autodataid bigint ,
stdTime float,
SubOperations int,
PartsCount float
)  

CREATE TABLE #FinalRunTime  
(  
	
	MachineID nvarchar(50) NOT NULL,  
	machineinterface nvarchar(50),  
	Component nvarchar(50) NOT NULL,  
	Compinterface nvarchar(50),  
	Operation nvarchar(50) NOT NULL,  
	OpnInterface nvarchar(50),  
	OperatorID nvarchar(50) ,
	OperatorInt nvarchar(50) ,
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
	PartsCount float
)  

Declare @T_ST AS Datetime   
Declare @T_ED AS Datetime   
Declare @StartTime AS Datetime   
Declare @EndTime AS Datetime 

Select @T_ST=(select min(Shiftstart) from #shift )  
Select @T_ED=(select max(Shiftend) from #shift)  

Select @StartTime=(select min(Shiftstart) from #shift )  
Select @EndTime=(select max(Shiftend) from #shift)  
  
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
 
 
Set @strSql=''
Set @strSql = '
insert into #MasterTemp(MachineID,MachineInt,MachineDescription,ComponentID,ComponentInt,OperationNo,OperationInt,OperatorID,OperatorInt,stdTime,SubOperations)
select distinct machineinformation.machineid,machineinformation.InterfaceID,machineinformation.Description,componentinformation.componentid,componentinformation.InterfaceID,
componentoperationpricing.operationno,componentoperationpricing.InterfaceID,Ei.employeeid,EI.interfaceid,componentoperationpricing.Cycletime,
componentoperationpricing.SubOperations from (select distinct mc,comp,opn,opr from #T_autodata) autodata
INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID   
INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID    
INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID  
AND componentinformation.componentid = componentoperationpricing.componentid  
and componentoperationpricing.machineid=machineinformation.machineid   
inner Join Employeeinformation EI on EI.interfaceid=autodata.opr 
LEFT OUTER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID
LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID	
where 1=1 '
SET @strSql =  @strSql + @strMachine  + @StrTPMMachines  + @StrGroupID + @strPlantID
print @strsql
exec (@strsql)

SET @strSql = 'INSERT INTO #CockpitData (  
 MachineID ,  
 MachineInterface,  
 ProductionEfficiency ,  
 AvailabilityEfficiency,  
 QualityEfficiency, --ER0368  
 OverallEfficiency,  
 Components ,  
 RejCount, --ER0368  
 TotalTime ,  
 UtilisedTime ,   
 ManagementLoss,  
 DownTime ,  
 TurnOver ,  
 ReturnPerHour ,  
 ReturnPerHourtotal,  
 CN,  
 PEGreen ,  
 PERed,  
 AEGreen ,  
 AERed ,  
 OEGreen ,  
 OERed,  
 QERed,  --ER0368  
 QEGreen, --ER0368   
 Remarks2 --ER0368  
 ) '  
SET @strSql = @strSql + ' SELECT MachineInformation.MachineID, MachineInformation.interfaceid ,0,0,0,0,0,0,0,0,0,0,0,0,0,PEGreen ,PERed,AEGreen ,AERed ,OEGreen ,OERed,isnull(QERed,0),isnull(QEGreen,0),0,PlantMachine.PlantID FROM MachineInformation --ER0368  
     LEFT OUTER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID
	 LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID	 
	  WHERE MachineInformation.interfaceid > ''0'' '  
SET @strSql =  @strSql + @strMachine  + @StrTPMMachines  + @StrGroupID + @strPlantID
EXEC(@strSql) 

SET @strSql = ''  
SET @strSql = 'INSERT INTO #PLD(MachineID,MachineInterface,pPlannedDT,dPlannedDT)  
 SELECT machineinformation.MachineID ,Interfaceid,0  ,0 FROM MachineInformation
 	LEFT OUTER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID 
    LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID
	 WHERE  MachineInformation.interfaceid > ''0'' '  
SET @strSql =  @strSql + @strMachine + @StrTPMMachines  + @StrGroupID + @strPlantID
EXEC(@strSql) 

SET @strSql = ''  
SET @strSql = 'Insert into #PlannedDownTimes  
 SELECT Machine,InterfaceID,  
  CASE When StartTime<''' + convert(nvarchar(20),@StartTime,120)+''' Then ''' + convert(nvarchar(20),@StartTime,120)+''' Else StartTime End As StartTime,  
  CASE When EndTime>''' + convert(nvarchar(20),@EndTime,120)+''' Then ''' + convert(nvarchar(20),@EndTime,120)+''' Else EndTime End As EndTime  
 FROM PlannedDownTimes 
 inner join MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID  
 	LEFT OUTER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID 
    LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID 
	and PlantMachineGroups.machineid = PlantMachine.MachineID
 WHERE PDTstatus =1 and(  
 (StartTime >= ''' + convert(nvarchar(20),@StartTime,120)+''' AND EndTime <=''' + convert(nvarchar(20),@EndTime,120)+''')  
 OR ( StartTime < ''' + convert(nvarchar(20),@StartTime,120)+'''  AND EndTime <= ''' + convert(nvarchar(20),@EndTime,120)+''' AND EndTime > ''' + convert(nvarchar(20),@StartTime,120)+''' )  
 OR ( StartTime >= ''' + convert(nvarchar(20),@StartTime,120)+'''   AND StartTime <''' + convert(nvarchar(20),@EndTime,120)+''' AND EndTime > ''' + convert(nvarchar(20),@EndTime,120)+''' )  
 OR ( StartTime < ''' + convert(nvarchar(20),@StartTime,120)+'''  AND EndTime > ''' + convert(nvarchar(20),@EndTime,120)+''')) '  
SET @strSql =  @strSql + @strMachine + @StrTPMMachines + @StrGroupID + @strPlantID +  ' ORDER BY Machine,StartTime'  
EXEC(@strSql)  
--mod 4  
SET @strSql = ''  
SELECT @StrSql = 'INSERT INTO #Exceptions(MachineID ,ComponentID,OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,ExCount )  
  SELECT Ex.MachineID ,Ex.ComponentID,Ex.OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,0  
  From ProductionCountException Ex  
  Inner Join MachineInformation M ON Ex.MachineID=M.MachineID  
  Inner Join ComponentInformation C ON Ex.ComponentID=C.ComponentID  
  Inner Join Componentoperationpricing O ON Ex.OperationNo=O.OperationNo AND C.ComponentID=O.ComponentID '  
---mod 2    
SELECT @StrSql = @StrSql + ' and O.MachineId=Ex.MachineId '  
---mod 2  
SELECT @StrSql = @StrSql + ' WHERE  M.MultiSpindleFlag=1 '  
SELECT @StrSql = @StrSql + @StrExMachine  
SELECT @StrSql = @StrSql +  
  'AND ((Ex.StartTime>=  ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@EndTime)+''' )  
  OR (Ex.StartTime< ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@EndTime)+''')  
  OR(Ex.StartTime>= ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@EndTime)+''' AND Ex.StartTime< ''' + convert(nvarchar(20),@EndTime)+''')  
  OR(Ex.StartTime< ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@EndTime)+''' ))'  
print @strsql  
Exec (@strsql)

  
/*******************************      Utilised Calculation Starts ***************************************************/  

-- Type 1  
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
 (Select mc,Sttime,NdTime From AutoData  
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
 (Select mc,Sttime,NdTime From AutoData  
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
 (Select mc,Sttime,NdTime From AutoData  
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
  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'  
BEGIN  
  
 ------------------------------------ ER0374 Added Till Here ---------------------------------  
 UPDATE #PLD set pPlannedDT =isnull(pPlannedDT,0) + isNull(TT.PPDT ,0)  
 FROM(  
  --Production Time in PDT  
  SELECT autodata.MC,SUM  
   (CASE  
--   WHEN autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.cycletime+autodata.loadunload) --DR0325 Commented  
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
  UPDATE  #PLD set IPlannedDT =isnull(IPlannedDT,0) + isNull(T2.IPDT ,0)  FROM (  
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
 UPDATE  #PLD set IPlannedDT =isnull(IPlannedDT,0) + isNull(T2.IPDT ,0)  FROM (  
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
--  Inner join #PlannedDownTimes T  
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

 ---step 2  
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
  and (D.ThresholdfromCO <>1)) as T1   --NR0097  
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
   FROM  #T_autodata AutoData --ER0374  
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
  
------------------------------------------------------------------------------------------------------------------------------------------------------------
select autodata.id,autodata.mc,autodata.comp,autodata.opn,  
isnull(CO.Stdsetuptime,0)AS Stdsetuptime ,   
sum(case  
when autodata.sttime>=@starttime and autodata.ndtime<=@endtime then autodata.loadunload  
when autodata.sttime<@starttime and autodata.ndtime>@starttime and autodata.ndtime<=@endtime then Datediff(s,@starttime,ndtime)  
when autodata.sttime>=@starttime and autodata.sttime<@endtime and autodata.ndtime>@endtime then  datediff(s,sttime,@endtime)  
when autodata.sttime<@starttime and autodata.ndtime>@endtime then  datediff(s,@starttime,@endtime)  
end) as setuptime,0 as ML,0 as Downtime  
into #setuptime  
from #T_autodata autodata  
inner join machineinformation M on autodata.mc = M.interfaceid  
inner join downcodeinformation D on autodata.dcode=D.interfaceid  
left outer join componentinformation CI on autodata.comp = CI.interfaceid  
left outer join componentoperationpricing CO on autodata.opn =  CO.interfaceid and CI.componentid = CO.componentid and CO.machineid = M.machineid  
where autodata.datatype=2 and D.ThresholdfromCO = 1  
And  
((autodata.sttime>=@starttime and autodata.ndtime<=@endtime) or  
 (autodata.sttime<@starttime and autodata.ndtime>@starttime and autodata.ndtime<=@endtime)or  
 (autodata.sttime>=@starttime and autodata.sttime<@endtime and autodata.ndtime>@endtime)or  
 (autodata.sttime<@starttime and autodata.ndtime>@endtime))  
group by autodata.id,autodata.mc,autodata.comp,autodata.opn,CO.Stdsetuptime  
  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
BEGIN  
 update #setuptime set setuptime = isnull(setuptime,0) - isnull(t1.setuptime_pdt,0) from   
 (  
  select autodata.id,autodata.mc,autodata.comp,autodata.opn,  
  sum(datediff(s,CASE WHEN autodata.sttime >= T.StartTime THEN autodata.sttime else T.StartTime End,  
  CASE WHEN autodata.ndtime <= T.EndTime THEN autodata.ndtime else T.EndTime End))  
  as setuptime_pdt  
  from #T_autodata autodata  
  inner join machineinformation M on autodata.mc = M.interfaceid  
  inner join componentinformation CI on autodata.comp = CI.interfaceid  
  inner join componentoperationpricing CO on autodata.opn =  CO.interfaceid and CI.componentid = CO.componentid and CO.machineid = M.machineid  
  inner join downcodeinformation D on autodata.dcode=D.interfaceid  
  CROSS jOIN #PlannedDownTimes T  
  where datatype=2 and T.MachineInterface=AutoData.mc   
  and D.ThresholdfromCO = 1 And  
  ((autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
    OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
    OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )  
    OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  
  )AND  
  ((autodata.sttime>=@starttime and autodata.ndtime<=@endtime) or  
   (autodata.sttime<@starttime and autodata.ndtime>@starttime and autodata.ndtime<=@endtime)or  
   (autodata.sttime>=@starttime and autodata.sttime<@endtime and autodata.ndtime>@endtime)or  
   (autodata.sttime<@starttime and autodata.ndtime>@endtime))  
  group by autodata.id,autodata.mc,autodata.comp,autodata.opn  
 ) as t1 inner join #setuptime on t1.id=#setuptime.id and t1.mc = #setuptime.mc and #setuptime.comp = t1.comp and #setuptime.opn = t1.opn  
  
 Update #setuptime set Downtime = isnull(Downtime,0) + isnull(T1.Setupdown,0) from  
 (Select id,mc,comp,opn,  
 Case when setuptime>stdsetuptime then setuptime-stdsetuptime else 0 end as Setupdown  
 from #setuptime)T1  inner join #setuptime on t1.id=#setuptime.id and t1.mc = #setuptime.mc and #setuptime.comp = t1.comp and #setuptime.opn = t1.opn  
End  
  
Update #setuptime set ML = Isnull(ML,0) + isnull(T1.SetupML,0) from  
(Select id,mc,comp,opn,  
Case when setuptime<stdsetuptime then setuptime else stdsetuptime end as SetupML  
from #setuptime)T1  inner join #setuptime on t1.id=#setuptime.id and t1.mc = #setuptime.mc and #setuptime.comp = t1.comp and #setuptime.opn = t1.opn  

--------------------------------------------------------------------------------------------------------------------------------------------------------------

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
---mod 4:If Ignore_Dtime_4m_PLD<> Y and Ignore_Dtime_4m_PLD<> N  
--************************************ Down and Management  Calculation Ends ******************************************  


UPDATE #CockpitData SET CN = isnull(CN,0) + isNull(t2.C1N1,0)  
from  
(select mc,  
SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))* autodata.partscount) C1N1  
--SUM(componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1)) C1N1  
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
  From #T_autodata  A  
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

if (select count(*) from #Exceptions)> 0  
Begin  
 UPDATE #Exceptions SET StartTime=@StartTime WHERE (StartTime<@StartTime)AND EndTime>@StartTime  
 UPDATE #Exceptions SET EndTime=@EndTime WHERE (EndTime>@EndTime AND StartTime<@EndTime )  
 Select @StrSql = 'UPDATE #Exceptions SET ExCount=ISNULL(T2.Comp,0) From  
  (  
   SELECT T1.MachineID AS MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime AS StartTime,T1.EndTime AS EndTime,  
   --SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp --NR0097  
   SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp --NR0097  
    From (  
    select MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,comp,opn,Tt1.StartTime,Tt1.EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from #T_autodata autodata  
    Inner Join MachineInformation  ON autodata.MC=MachineInformation.InterfaceID  
    Inner Join ComponentInformation  ON autodata.Comp = ComponentInformation.InterfaceID  
    Inner Join ComponentOperationPricing on autodata.Opn=ComponentOperationPricing.InterfaceID And ComponentInformation.ComponentID=ComponentOperationPricing.ComponentID'  
   Select @StrSql = @StrSql +' and ComponentOperationPricing.machineid=machineinformation.machineid'  
  Select @StrSql = @StrSql +' Inner Join (  
     Select MachineID,ComponentID,OperationNo,StartTime,EndTime From #Exceptions Ex Where OperationNo<>0 '  
  Select @StrSql = @StrSql + @StrExMachine  
  Select @StrSql = @StrSql +')AS Tt1 ON Tt1.MachineID=MachineInformation.MachineID AND Tt1.ComponentID = ComponentInformation.ComponentID AND Tt1.OperationNo= ComponentOperationPricing.OperationNo  
     and Tt1.MachineID=ComponentOperationPricing.MachineID  
    Where (autodata.ndtime>Tt1.StartTime) AND (autodata.ndtime<=Tt1.EndTime) and (autodata.datatype=1)'  
  Select @StrSql = @StrSql + @StrMachine  
  Select @StrSql = @StrSql+' Group by MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,Tt1.StartTime,Tt1.EndTime,comp,opn  
   ) as T1  
      Inner join componentinformation C on T1.Comp=C.interfaceid  
      Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineID = T1.machineID '  
   Select @StrSql = @StrSql +' Inner join machineinformation M on T1.machineid = M.machineid '  
     Select @StrSql = @StrSql +' GROUP BY T1.MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime,t1.EndTime  
  )AS T2  
  WHERE  #Exceptions.StartTime=T2.StartTime AND #Exceptions.EndTime=T2.EndTime  
  AND #Exceptions.MachineID=T2.MachineID AND #Exceptions.ComponentID = T2.ComponentID AND #Exceptions.OperationNo=T2.OperationNo'  
  print @StrSql  
  Exec(@StrSql)  
  If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
  BEGIN  
    Select @StrSql =''  
    Select @StrSql ='UPDATE #Exceptions SET ExCount=ISNULL(ExCount,0) - ISNULL(T3.compCount,0)  
    From  
    (  
     SELECT T2.MachineID AS MachineID,T2.ComponentID,T2.OperationNo,T2.StartTime AS StartTime,T2.EndTime AS EndTime,  
     --SUM(CEILING (CAST(T2.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as compCount --NR0097  
     SUM((CAST(T2.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as compCount --NR0097  
     From  
     (  
      select MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,comp,opn,  
      Max(T1.XStartTime)StartTime,Max(T1.XEndTime)EndTime,T1.PLD_StartTime,T1.PLD_EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from #T_autodata autodata  
      Inner Join MachineInformation ON autodata.MC=MachineInformation.InterfaceID  
      Inner Join ComponentInformation ON autodata.Comp = ComponentInformation.InterfaceID  
      Inner Join ComponentOperationPricing on autodata.Opn=ComponentOperationPricing.InterfaceID And ComponentInformation.ComponentID=ComponentOperationPricing.ComponentID And ComponentOperationPricing.MachineID = MachineInformation.MachineID  
      Inner Join   
      (  
       SELECT Ex.MachineID,Ex.ComponentID,Ex.OperationNo,Ex.StartTime As XStartTime, Ex.EndTime AS XEndTime,  
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
       From #Exceptions AS Ex inner JOIN #PlannedDownTimes AS Td on Ex.MachineID = Td.MachineID  
       Where ((Td.StartTime>=Ex.StartTime And Td.EndTime <=Ex.EndTime)OR  
       (Td.StartTime< Ex.StartTime And Td.EndTime<=Ex.EndTime AND Td.EndTime>Ex.StartTime)OR  
       (Td.StartTime>= Ex.StartTime And Td.StartTime <Ex.EndTime AND Td.EndTime>Ex.EndTime)OR  
       (Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime))'  
     Select @StrSql = @StrSql + @StrExMachine  
     Select @StrSql = @StrSql + ' )AS T1 ON T1.MachineID=MachineInformation.MachineID AND T1.ComponentID = ComponentInformation.ComponentID AND T1.OperationNo= ComponentOperationPricing.OperationNo and T1.Machineid=ComponentOperationPricing.MachineID  
      Where (autodata.ndtime>T1.PLD_StartTime AND autodata.ndtime<=T1.PLD_EndTime) and (autodata.datatype=1)  
     AND (autodata.ndtime > ''' + convert(nvarchar(20),@StartTime)+''' AND autodata.ndtime<=''' + convert(nvarchar(20),@EndTime)+''' )'  
     Select @StrSql = @StrSql + @StrMachine  
     Select @StrSql = @StrSql+' Group by MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,T1.PLD_StartTime,T1.PLD_EndTime,comp,opn  
     )AS T2  
     Inner join componentinformation C on T2.Comp=C.interfaceid  
     Inner join ComponentOperationPricing O ON T2.Opn=O.interfaceid and C.Componentid=O.componentid and T2.MachineID = O.MachineID  
     GROUP BY T2.MachineID,T2.ComponentID,T2.OperationNo,T2.StartTime,t2.EndTime  
    )As T3  
    WHERE  #Exceptions.StartTime=T3.StartTime AND #Exceptions.EndTime=T3.EndTime  
    AND #Exceptions.MachineID=T3.MachineID AND #Exceptions.ComponentID = T3.ComponentID AND #Exceptions.OperationNo=T3.OperationNo'  
    --PRINT @StrSql  
    EXEC(@StrSql)  
    
  END  
  UPDATE #Exceptions SET ExCount=ExCount-((ExCount * ActualCount)/ISNULL(IdealCount,0))  
End

UPDATE #CockpitData SET turnover = isnull(turnover,0) + isNull(t2.revenue,0)  
from  
(select mc,  
SUM((componentoperationpricing.price/ISNULL(ComponentOperationPricing.SubOperations,1))* ISNULL(autodata.partscount,1)) revenue  
FROM #T_autodata autodata  
INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID  
INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID AND componentoperationpricing.componentid = componentinformation.componentid  
inner join machineinformation on componentoperationpricing.machineid=machineinformation.machineid  
AND autodata.mc = machineinformation.interfaceid  
where (  
(autodata.sttime>=@StartTime and autodata.ndtime<=@EndTime)OR  
(autodata.sttime<@StartTime and autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime))and (autodata.datatype=1)  
group by autodata.mc  
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface 

--Excluding Exception count from turnover calculation  
UPDATE #CockpitData SET Turnover = ISNULL(Turnover,0) - ISNULL(t2.xTurnover,0)  
from  
( select Ex.MachineID,  
SUM((O.price)* ISNULL(ExCount,0)) as xTurnover  
From #Exceptions Ex  
INNER JOIN ComponentInformation C ON Ex.ComponentID=C.ComponentID  
INNER JOIN ComponentOperationPricing O ON Ex.OperationNO=O.OperationNO AND C.ComponentID=O.ComponentID  
and O.machineid = Ex.machineid  
GROUP BY Ex.MachineID) as T2  
Inner join #CockpitData on T2.MachineID = #CockpitData.MachineID  

--Mod 4 Apply PDT for TurnOver Calculation.  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
BEGIN  
 UPDATE #CockpitData SET turnover = isnull(turnover,0) - isNull(t2.revenue,0)  
 From  
 (  
  select mc,SUM((O.price * ISNULL(A.PartsCount,1))/ISNULL(O.SubOperations,1))as revenue  
  From #T_autodata A  
  Inner join machineinformation M on M.interfaceid=A.mc  
  Inner join componentinformation C ON A.Comp=C.interfaceid  
  Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID  
  CROSS jOIN #PlannedDownTimes T  
  WHERE A.DataType=1 And T.MachineInterface = A.mc  
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
 --Select mc,SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp --NR0097  
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
 
--Apply Exception on Count..  
UPDATE #CockpitData SET components = ISNULL(components,0) - ISNULL(t2.comp,0)  
from  
( select MachineID,SUM(ExCount) as comp  
 From #Exceptions GROUP BY MachineID) as T2  
Inner join #CockpitData on T2.MachineID = #CockpitData.MachineID

--Mod 4 Apply PDT for calculation of Count  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
BEGIN  
 UPDATE #CockpitData SET components = ISNULL(components,0) - ISNULL(T2.comp,0) from(  
  --select mc,SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp From ( --NR0097  
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
  
---------------------------------- NR0097 From Here -------------------------------------------  
Update #CockpitData SET downtime = isnull(downtime,0)+ isnull(T1.down,0)  , ManagementLoss = isnull(ManagementLoss,0)+isnull(T1.ML,0) from  
(Select mc,Sum(ML) as ML,Sum(Downtime) as Down from #setuptime Group By mc)T1  
inner join #CockpitData on T1.mc = #CockpitData.machineinterface  
---------------------------------- NR0097 Till Here -------------------------------------------  
  

UPDATE #CockpitData  
SET  
 ProductionEfficiency = (CN/UtilisedTime) ,   
 AvailabilityEfficiency = (UtilisedTime)/(UtilisedTime + DownTime - ManagementLoss),   
 TotalTime = DateDiff(second, @StartTime, @EndTime),  
 ReturnPerHour = (TurnOver/UtilisedTime)*3600,  
 ReturnPerHourtotal = (TurnOver/DateDiff(second, @StartTime, @EndTime))*3600,  
 Remarks = ' '  
WHERE UtilisedTime <> 0  
  
--NR0090 From Here  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='DisplayTTFormat')='Display TotalTime - Less PDT'   
BEGIN  
----------------------------------- DR0330 From Here -----------------------------------------------------  

UPDATE #CockpitData SET TotalTime = Totaltime - isnull(T1.PDT,0)   
 from  
 (Select Machine,SUM(datediff(S,Starttime,endtime))as PDT from Planneddowntimes  
  where starttime>=@starttime and endtime<=@endtime group by machine)T1  
  Inner Join #CockpitData on T1.Machine=#CockpitData.Machineid WHERE UtilisedTime <> 0   
----------------------------------- DR0330 Till Here -----------------------------------------------------  
End  
 

select @strsql=''
SELECT @strsql= @strsql + 'insert into #Runningpart_Part(Machineid,Componentid,OperatorName,Sttime)
	select Machineinformation.machineid,C.Componentid,E.Name,Max(A.Sttime) from 
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
SELECT @strsql = @strsql +'group by Machineinformation.machineid,C.Componentid,E.Name'
print @strsql
exec (@strsql)  

Update #Cockpitdata Set OperatorName = isnull(T1.opr,0) from
(Select T.Machineid,T.opr from
	(select Machineid,OperatorName as opr,sttime,
	row_number() over(partition by Machineid,OperatorName order by sttime desc) as rn
	From #Runningpart_Part 
	)T where T.rn <= 1
) as T1 inner join #Cockpitdata on #Cockpitdata.machineid=T1.machineid 
  

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
inner join #shift S on convert(nvarchar(10),(A.RejDate),126)=S.shiftdate and A.RejShift=S.shiftid --DR0333  
where A.flag = 'Rejection' and A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (S.shiftdate) and  --DR0333  
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
 inner join #shift S on convert(nvarchar(10),(A.RejDate),126)=S.shiftdate and A.RejShift=S.shiftid --DR0333  
 Cross join Planneddowntimes P  
 where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid and  
 A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (S.shiftdate) and --DR0333  
 Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'  
 and P.starttime>=S.Shiftstart and P.Endtime<=S.shiftend  
 group by A.mc,M.Machineid)T1 inner join #Cockpitdata B on B.Machineid=T1.Machineid   
END  

Update #Cockpitdata set ReworkCount = isnull(B.ReworkCount,0) + isnull(T1.ReworkCount,0)
From
( Select A.mc,SUM(A.Rejection_Qty) as ReworkCount,M.Machineid from AutodataRejections A
inner join Machineinformation M on A.mc=M.interfaceid
inner join #Cockpitdata on #Cockpitdata.machineid=M.machineid 
inner join Reworkinformation R on A.Rejection_code=R.Reworkinterfaceid
where A.CreatedTS>=@StartTime and A.CreatedTS<@Endtime and A.flag = 'MarkedforRework'
and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000'
group by A.mc,M.Machineid
)T1 inner join #Cockpitdata B on B.Machineid=T1.Machineid 

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	Update #Cockpitdata set ReworkCount = isnull(B.ReworkCount,0) - isnull(T1.ReworkCount,0) from
	(Select A.mc,SUM(A.Rejection_Qty) as ReworkCount,M.Machineid from AutodataRejections A
	inner join Machineinformation M on A.mc=M.interfaceid
	inner join #Cockpitdata on #Cockpitdata.machineid=M.machineid 
	inner join Reworkinformation R on A.Rejection_code=R.Reworkinterfaceid
	Cross join Planneddowntimes P
	where P.PDTStatus =1 and A.flag = 'MarkedforRework' and P.machine=M.Machineid 
	and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000' and
	A.CreatedTS>=@StartTime and A.CreatedTS<@Endtime And
	A.CreatedTS>=P.Starttime and A.CreatedTS<P.endtime
	group by A.mc,M.Machineid)T1 inner join #Cockpitdata B on B.Machineid=T1.Machineid 
END

Update #Cockpitdata set ReworkCount = isnull(B.ReworkCount,0) + isnull(T1.ReworkCount,0)
From
( Select A.mc,SUM(A.Rejection_Qty) as ReworkCount,M.Machineid from AutodataRejections A
inner join Machineinformation M on A.mc=M.interfaceid
inner join #Cockpitdata on #Cockpitdata.machineid=M.machineid 
inner join Reworkinformation R on A.Rejection_code=R.Reworkinterfaceid
inner join #shift S on convert(nvarchar(10),(A.RejDate),126)=S.shiftdate and A.RejShift=S.shiftid --DR0333
where A.flag = 'MarkedforRework' and A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (S.shiftdate) and  --DR0333
Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
group by A.mc,M.Machineid
)T1 inner join #Cockpitdata B on B.Machineid=T1.Machineid 

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	Update #Cockpitdata set ReworkCount = isnull(B.ReworkCount,0) - isnull(T1.ReworkCount,0) from
	(Select A.mc,SUM(A.Rejection_Qty) as ReworkCount,M.Machineid from AutodataRejections A
	inner join Machineinformation M on A.mc=M.interfaceid
	inner join #Cockpitdata on #Cockpitdata.machineid=M.machineid 
	inner join Reworkinformation R on A.Rejection_code=R.Reworkinterfaceid
	inner join #shift S on convert(nvarchar(10),(A.RejDate),126)=S.shiftdate and A.RejShift=S.shiftid --DR0333
	Cross join Planneddowntimes P
	where P.PDTStatus =1 and A.flag = 'MarkedforRework' and P.machine=M.Machineid and
	A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (S.shiftdate) and --DR0333
	Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
	and P.starttime>=S.Shiftstart and P.Endtime<=S.shiftend
	group by A.mc,M.Machineid)T1 inner join #Cockpitdata B on B.Machineid=T1.Machineid 
END
  
UPDATE #Cockpitdata SET QualityEfficiency= ISNULL(QualityEfficiency,0) + IsNull(T1.QE,0)   
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
--ER0368 Till here  
  
 
--ER0385 From Here  
Declare @Type40Threshold int  
Declare @Type1Threshold int  
Declare @Type11Threshold int  
  
Set @Type40Threshold =0  
Set @Type1Threshold = 0  
Set @Type11Threshold = 0  
  
Set @Type40Threshold = (Select isnull(Valueintext2,5)*60 from shopdefaults where parameter='ANDONStatusThreshold' and valueintext = 'Type40Threshold')  
Set @Type1Threshold = (Select isnull(Valueintext2,5)*60 from shopdefaults where parameter='ANDONStatusThreshold' and valueintext = 'Type1Threshold')  
Set @Type11Threshold = (Select isnull(Valueintext2,5)*60 from shopdefaults where parameter='ANDONStatusThreshold' and valueintext = 'Type11Threshold')  
print @Type40Threshold  
print @Type1Threshold  
print @Type11Threshold  
  

Insert into #machineRunningStatus(MachineID,MachineInterface,sttime,ndtime,datatype,Colorcode)       
select fd.MachineID,fd.MachineInterface,sttime,ndtime,datatype,ColorCode from MachineRunningStatus mr      
right outer join #CockpitData fd on fd.MachineInterface = mr.MachineInterface  
where sttime>@StartTime and sttime<@currtime and isnull(ndtime,'1900-01-01')<@currtime  
order by fd.MachineInterface  
  
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
 

update #machineRunningStatus set ColorCode = t1.ColorCode from (
Select Rawdata.*,(Case when (RawData.DataType=22  and D.interfaceid in (1000)) Then 'Blue' Else 'Red' End) as ColorCode
From Rawdata 
inner join (select mc,max(slno) as slno from rawdata WITH (NOLOCK)   
where Rawdata.sttime<@currtime and rawdata.datatype in(11,1,2,22,42) and rawdata.[status] in (1,15)
group by mc
) A  on A.mc=rawdata.mc and A.slno=rawdata.slno  
left join downcodeinformation D on RawData.splstring2=D.interfaceid 
where RawData.DataType=22  
) as t1 inner join #machineRunningStatus on t1.mc = #machineRunningStatus.MachineInterface  
  
    
update #machineRunningStatus set ColorCode ='Red' where isnull(sttime,'1900-01-01')='1900-01-01'  
  
update #CockpitData set Remarks1 = T1.MCStatus from   
(select Machineid,  
Case when Colorcode='White' then 'Stopped'  
when Colorcode='Red' then 'Stopped'  
when Colorcode='Green' then 'Running' end as MCStatus from #machineRunningStatus)T1  
inner join #CockpitData on T1.MachineID = #CockpitData.MachineID  


update #CockPitData set MachineLiveStatus=T.Machinestatus from
(select #MachineRunningStatus.Machineid, 
Case 
when Datatype in(2,42,22) then 'Down'
when Datatype=40 and datediff(second,sttime,@CurrTime)- @Type40Threshold>0 then 'ICD'
when Datatype=11 and (datediff(second,sttime,@CurrTime)<=@Type11Threshold) then 'Running' 
when Datatype=41 then 'Running'
when Datatype=1 and datediff(second,ndtime,@CurrTime)<@Type1Threshold then 'Load Unload'
when PingStatus='NOT OK' then 'Disconnected'
END as Machinestatus
from #MachineRunningStatus
inner join Machineinformation on  machineinformation.machineid=#MachineRunningStatus.machineid
where machineinformation.TPMTrakEnabled=1 and machineinformation.DNCTransferEnabled=0
)T inner join #CockPitData on T.Machineid=#CockPitData.Machineid

update #CockpitData set StatusColor = T1.ColorCode from   
(select distinct Machineid, ColorCode from #machineRunningStatus)T1  
inner join #CockpitData on T1.MachineID = #CockpitData.MachineID  


Update #CockpitData Set Lastcycletime = T1.LastCycle  from   
(  
 Select A.Machineid,A.Endtime as LastCycle from Autodata_MaxTime A  
) T1 inner join #CockpitData on T1.MachineID = #CockpitData.MachineInterface 

Update #CockpitData Set LastCycleCO=T1.Comp,
LastCycleCompDescription=T1.Compdes,LastCycleOperation=T1.Opn,LastCycleOpnDescription=T1.Opndes,
LastCycleDatatype=T1.datatype,RunningCycleStdTime=T1.Cycletime,
LastCycleOpr=T1.Opr, LastCycleOprName=T1.OprName,
LastCycleCompInterface=T1.CompInt, LastCycleOpnInterface=T1.OpnInt
from   
(  
Select A.mc,rawdata.datatype,C.Componentid as Comp,RawData.Comp as CompInt,cast(C.description as nvarchar(50))  as Compdes,
cast(CO.operationno as nvarchar(50)) as Opn,RawData.opn as OpnInt,cast(CO.description as nvarchar(50)) as Opndes,Co.cycletime,
RawData.Opr,E.Name as OprName
From Rawdata 
inner join (select mc,max(slno) as slno from rawdata WITH (NOLOCK)   
where (RawData.Sttime>@StartTime and Rawdata.sttime<@currtime) and rawdata.datatype in(11,1,2,22,42) and rawdata.[status] in (1,15)
group by mc
) A  on A.mc=rawdata.mc and A.slno=rawdata.slno  
inner join Machineinformation on A.mc=Machineinformation.interfaceid    
left outer join Componentinformation C on rawdata.comp=C.interfaceid    
left outer join Componentoperationpricing CO on rawdata.opn=CO.interfaceid    
and Machineinformation.Machineid=CO.Machineid and C.Componentid=CO.Componentid    
left join employeeinformation E on RawData.Opr=E.interfaceid
) T1 inner join #CockpitData on T1.mc = #CockpitData.MachineInterface   
-----------------------------------------------ER0455 Logic For Metso -------------------------------------------------------------------------  
 
  
   ---Query to get Machinewise Last Record from Rawdata where Datatype in 11,1,2,22,42 for peekay  
Update #CockpitData Set MachineStatus=T1.DownStatus From
(select RawData.mc,
Case when rawdata.datatype in(11,41) then 'Cycle Started'
When rawdata.datatype=1 then 'Cycle Ended'
When rawdata.datatype in(22,42) then  'Stopped ' + D.Downid 
When rawdata.datatype in(2,40) then 'Stopped' 
END as DownStatus from Rawdata
inner join (select mc,max(slno) as slno from rawdata WITH (NOLOCK)   
where Rawdata.sttime<@currtime and rawdata.datatype in(11,1,2,22,42) and rawdata.[status] in (1,15)
group by mc) t1 on t1.mc=rawdata.mc and t1.slno=rawdata.slno  
Left Outer join Downcodeinformation D on rawdata.splstring2=D.interfaceid
) T1 inner join #CockpitData on T1.mc = #CockpitData.MachineInterface  
  ---Query to get Machinewise Last Record from Rawdata where Datatype in 11,1,2,22,42 for peekay   

Update #CockpitData Set LastCompletedDowntime=T1.LastDown From
(select RawData.mc,ISNULL(D.Downid,'Unknown') + ' ['+ case when Rawdata.ndtime<>'' then Substring(CONVERT(varchar,Rawdata.ndtime,106),1,2)+ '-' +  
	substring(CONVERT(varchar,Rawdata.ndtime,106),4,3)+ ' ' +  
	RIGHT('0'+LTRIM(RIGHT(CONVERT(varchar,Rawdata.ndtime,100),8)),7) + ']' End as LastDown from Rawdata
	inner join 
	(select mc,max(slno) as slno from rawdata WITH (NOLOCK)   
	inner join Autodata_maxtime A on rawdata.mc=A.machineid where (Rawdata.sttime>=A.Endtime and Rawdata.sttime<@currtime) and rawdata.datatype in(2,42) and rawdata.[status] in (1,15)
	group by mc
	) t1 on t1.mc=rawdata.mc and t1.slno=rawdata.slno  
Left Outer join Downcodeinformation D on rawdata.splstring2=D.interfaceid
) T1 inner join #CockpitData on T1.mc = #CockpitData.MachineInterface 

Update #CockpitData Set CurrentDowntime=T1.CurrentDown From
(select RawData.mc,ISNULL(D.Downid,'Unknown') + ' ['+ case when Rawdata.Sttime<>'' then Substring(CONVERT(varchar,Rawdata.Sttime,106),1,2)+ '-' +  
	substring(CONVERT(varchar,Rawdata.Sttime,106),4,3)+ ' ' +  
	RIGHT('0'+LTRIM(RIGHT(CONVERT(varchar,Rawdata.Sttime,100),8)),7) + ']' End as CurrentDown from Rawdata
	inner join 
	(select mc,max(slno) as slno from rawdata WITH (NOLOCK)   
	inner join Autodata_maxtime A on rawdata.mc=A.machineid where (Rawdata.sttime>A.Endtime and Rawdata.sttime<@currtime) and rawdata.datatype=22 and rawdata.[status] in (1,15)
	group by mc
	) t1 on t1.mc=rawdata.mc and t1.slno=rawdata.slno  
Left Outer join Downcodeinformation D on rawdata.splstring2=D.interfaceid
) T1 inner join #CockpitData on T1.mc = #CockpitData.MachineInterface  

update #CockPitData set RunningComponentBoxColor=
case when RunningCycleUT<=RunningCycleStdTime then 'Green'
when RunningCycleUT>RunningCycleStdTime then 'Red' else 'White'
End

----------------------- RunTime calculaion start-----------------------------------------------------------------------------------------------------------------------------------------------------------------

		Select @strsql=''   
		Select @strsql= 'insert into #RunTime(MachineID,machineinterface,Component,Compinterface,Operation,Opninterface, OperatorID,  OperatorInt,
		msttime,ndtime,FromTm,Totm,batchid,autodataid,stdtime,SubOperations)'  
		select @strsql = @strsql + ' SELECT A3.machineid, autodata.mc,A3.componentid, autodata.comp,  
		A3.operationno, autodata.opn,A3.OperatorID,autodata.opr,
		Case when autodata.msttime<  T.Shiftstart then T.Shiftstart else autodata.msttime end,   
		Case when autodata.ndtime> T.Shiftend  then T.Shiftend else autodata.ndtime end,     
		T.Shiftstart,T.Shiftend,0,autodata.id,A3.StdCycleTime,A3.SubOperations FROM #T_autodata autodata  with(nolock)
		inner join (select distinct MachineID,MachineInt,ComponentID,ComponentInt,OperationNo,OperationInt,OperatorID,OperatorInt,
		stdTime as StdCycleTime,SubOperations from #MasterTemp) A3 
		on autodata.mc=A3.MachineInt and autodata.comp=A3.ComponentInt and autodata.opn=A3.OperationInt and autodata.opr=A3.OperatorInt
		cross join(select distinct Shiftstart,Shiftend from #Shift) as T
		WHERE ((autodata.msttime>=T.Shiftstart  and  autodata.ndtime<=T.Shiftend ) 
			OR ( autodata.sttime<T.Shiftstart  and  autodata.ndtime>T.Shiftstart  and autodata.ndtime<=T.Shiftend ) --SV Added 
			or (autodata.msttime>=T.Shiftstart  and autodata.sttime<T.Shiftend  and autodata.ndtime>T.Shiftend)
			OR ( autodata.msttime < T.Shiftstart  AND autodata.ndtime > T.Shiftend) )' --SV Added 
		select @strsql = @strsql + ' order by autodata.msttime'  
		print @strsql  
		exec (@strsql)

		insert into #FinalRunTime(MachineID,Component,operation,machineinterface,Compinterface,Opninterface,OperatorID,OperatorInt,batchid,BatchStart,BatchEnd,FromTm,ToTm,stdtime,Actual,Target,Runtime,SubOperations) 
		select MachineID,Component,operation,machineinterface,Compinterface,Opninterface,OperatorID,OperatorInt,batchid,min(msttime),max(ndtime),FromTm,ToTm,stdtime,0,0,0,SubOperations
		from
		(
		select MachineID,Component,operation,machineinterface,Compinterface,Opninterface,msttime,ndtime,FromTm,ToTm,stdtime,SubOperations,OperatorID,OperatorInt,
		RANK() OVER (
		PARTITION BY t.machineid
		order by t.machineid, t.msttime
		) -
		RANK() OVER (
		PARTITION BY  t.machineid, t.component, t.operation,t.OperatorID,t.fromtm 
		order by t.machineid, t.fromtm, t.msttime
		) AS batchid
		from #RunTime t 
		) tt
		group by MachineID,Component,operation,machineinterface,Compinterface,Opninterface,batchid,FromTm,ToTm,stdtime,SubOperations,OperatorID,OperatorInt
		order by tt.batchid

		Update #FinalRunTime Set BatchEnd=T1.BE
		From(
			Select A1.machineinterface,A1.FromTm,A2.BatchStart,(Case when A2.BatchEnd<A1.ToTm Then A1.ToTm else A2.BatchEnd end) as BE from #FinalRunTime A1
			inner join (select machineinterface,Convert(nvarchar(10),FromTm,120) as Date1,FromTm,Max(BatchStart) as BatchStart,Max(BatchEnd) as BatchEnd from #FinalRunTime
			group by machineinterface,Convert(nvarchar(10),FromTm,120),FromTm) A2
			on A1.machineinterface=A2.machineinterface and Convert(nvarchar(10),A1.FromTm,120)=Convert(nvarchar(10),A2.Date1,120) and A1.FromTm=A2.FromTm and A1.BatchStart=A2.BatchStart
		)T1 inner join #FinalRunTime T2 on T1.machineinterface=T2.machineinterface and T1.FromTm=T2.FromTm and T1.BatchStart=T2.BatchStart

		--Update #FinalRunTime Set BatchStart=T1.BS
		--From(
		--	Select A1.machineinterface,A1.FromTm,A2.BatchStart,(Case when A1.FromTm<A2.BatchStart Then A1.FromTm else A2.BatchStart end) as BS from #FinalRunTime A1
		--	inner join (select machineinterface,Convert(nvarchar(10),FromTm,120) as Date1,FromTm,min(BatchStart) as BatchStart,Min(BatchEnd) as BatchEnd from #FinalRunTime
		--	group by machineinterface,Convert(nvarchar(10),FromTm,120),FromTm) A2
		--	on A1.machineinterface=A2.machineinterface and Convert(nvarchar(10),A1.FromTm,120)=Convert(nvarchar(10),A2.Date1,120) and A1.FromTm=A2.FromTm and A1.BatchStart=A2.BatchStart
		--)T1 inner join #FinalRunTime T2 on T1.machineinterface=T2.machineinterface and T1.FromTm=T2.FromTm and T1.BatchStart=T2.BatchStart

		update #FinalRunTime set Runtime=datediff(SECOND,BatchStart,BatchEnd)


		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')<>'N'
		BEGIN
			Update #FinalRunTime set Runtime=Isnull(Runtime,0) - Isnull(T3.pdt,0) 
			from (
			Select t2.machineinterface,T2.Machine,T2.BatchStart,T2.BatchEnd,T2.Fromtm,T2.ToTm,sum(datediff(ss,T2.StartTimepdt,t2.EndTimepdt))as pdt
			from
				(
				Select T1.machineinterface,T1.Compinterface,T1.Opninterface,T1.BatchStart,T1.BatchEnd,T1.FromTm,ToTm,Pdt.machine,
				Case when  T1.BatchStart <= pdt.StartTime then pdt.StartTime else T1.BatchStart End as StartTimepdt,
				Case when  T1.BatchEnd >= pdt.EndTime then pdt.EndTime else T1.BatchEnd End as EndTimepdt
				from #FinalRunTime T1
				inner join Planneddowntimes pdt on t1.machineid=Pdt.machine
				where PDTstatus = 1  and
				((pdt.StartTime >= t1.BatchStart and pdt.EndTime <= t1.BatchEnd)or
				(pdt.StartTime < t1.BatchStart and pdt.EndTime > t1.BatchStart and pdt.EndTime <=t1.BatchEnd)or
				(pdt.StartTime >= t1.BatchStart and pdt.StartTime <t1.BatchEnd and pdt.EndTime >t1.BatchEnd) or
				(pdt.StartTime <  t1.BatchStart and pdt.EndTime >t1.BatchEnd))
				)T2 group by  t2.machineinterface,T2.Machine,T2.BatchStart,T2.BatchEnd,T2.Fromtm,T2.ToTm
			) T3 inner join #FinalRunTime T on T.machineinterface=T3.machineinterface and T.BatchStart=T3.BatchStart and  T.BatchEnd=T3.BatchEnd and T.Fromtm=T3.Fromtm and T.ToTm=T3.ToTm
		ENd

Update #CockpitData Set ActualParts=T1.Comp From
(Select mc,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp --NR0097  
	From(select mc,comp,opn,opr,SUM(autodata.partscount)AS OrginalCount from #T_autodata autodata
		inner join (Select A1.* from #FinalRunTime A1
			inner join (select MachineID,machineinterface,max(BatchStart) as BS,Max(BatchEnd) as BE from #FinalRunTime
			Group by MachineID,machineinterface
			)A2 on A1.machineinterface=A2.machineinterface and A1.BatchStart=A2.BS and A1.BatchEnd=A2.BE
		)T on T.machineinterface=autodata.mc and T.Compinterface=autodata.comp and T.OpnInterface=autodata.opn and T.OperatorInt=autodata.opr
		where (autodata.ndtime>T.BatchStart) and (autodata.ndtime<=T.BatchEnd) and (autodata.datatype=1)  
		Group By mc,comp,opn,opr
	) as T1  
	Inner join componentinformation C on T1.Comp = C.interfaceid  
	Inner join ComponentOperationPricing O ON  T1.Opn = O.interfaceid and C.Componentid=O.componentid  
	inner join machineinformation on machineinformation.machineid =O.machineid  
	and T1.mc=machineinformation.interfaceid  
	GROUP BY mc  
) T1 inner join #CockpitData on T1.mc = #CockpitData.MachineInterface  

Update #CockpitData Set ProductionTarget=T1.ProdTarget From
(Select A1.machineinterface as MC,(Runtime/stdTime) as ProdTarget from #FinalRunTime A1
	inner join (select MachineID,machineinterface,max(BatchStart) as BS,Max(BatchEnd) as BE from #FinalRunTime
	Group by MachineID,machineinterface
	)A2 on A1.machineinterface=A2.machineinterface and A1.BatchStart=A2.BS and A1.BatchEnd=A2.BE
	where stdTime>0
) T1 inner join #CockpitData on T1.mc = #CockpitData.MachineInterface  

----------------------- RunTime calculaion end-----------------------------------------------------------------------------------------------------------------------------------------------------------------



--select * from #CockPitData
--select * from #shift

select MachineID,MachineInterface,isnull(LastCycleCO,'') as RunningComp,LastCycleCompInterface as RunningCompInt,isnull(LastCycleCompDescription,'') as RunningCompDescription,
isnull(LastCycleOperation,'') as RunningOpn,LastCycleOpnInterface as RunningOpnInt,isnull(LastCycleOpnDescription,'') as RunningOpnDescription,
isnull(LastCycleOprName,'') as LatestOprName,LastCycleOpr as LatestOprID,ROUND(OverAllEfficiency,2) as OEE,
dbo.f_FormatTime(DownTime,'hh:mm:ss') as DownTime,Round(ProductionTarget,2) as ProductionTarget,ActualParts,--ROUND(Components,2) as Components,
Remarks1 as MachineStatus,MachineLiveStatus,StatusColor from #CockPitData
--where LastCycleCompInterface is not NULL
order by machineinterface

END  
  
    

 
