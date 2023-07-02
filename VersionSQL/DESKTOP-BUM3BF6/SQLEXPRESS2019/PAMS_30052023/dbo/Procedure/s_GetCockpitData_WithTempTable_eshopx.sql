/****** Object:  Procedure [dbo].[s_GetCockpitData_WithTempTable_eshopx]    Committed by VersionSQL https://www.versionsql.com ******/

/***************************************      History     *******************************************
Procedure altered by Satyan on 15-feb-06 To include down threshold in ManagementLoss calculation
Introduced PEGreen,PERed,AEGreen,AERed,OEGreen,OERed, Dec 4 2004 sjaiswal
Procedure Altred On top of 4.5.0.0 by Sangeeta Kallur On May-2006
[Originally this proc altered for testing]
To support the down within the production cycle as they appear.
Removed all the unwanted comments by SSK
Procedure Altered [Count ,CN,TurnOver Calculations ]by SSK on 06/July/2006
To combine SubOperations as One Cycle ie one component.
Procedure Changed By MRao ::New column 'partsCount' is added in autodata
which gives number of components in that cycle
Procedure Changed By SSK on 06-Dec-2006 : To remove constraint name.
Procedure Changed By Karthik G on 21-FEB-2007
	To include 'TPMTrakEnabled'{Based on user settings we
	will be considering only TPMTrakEnabled Machines or ALL} Concept.
Procedure Changed By Sangeeta Kallur on 23-FEB-2007 ::For MultiSpindle type of machines [MAINI Req].
mod 1:- DR0175, By Mrudula M. Rao on 13-mar-2009.Exception rule is not being applied when you select all machine
		Initialize "@StrExMachine"
mod 2 :- ER0181 By Kusuma M.H on 08-May-2009.2) Modify all the procedures accordingly. Qualify machine wherever we are making use of component and opeartion no.
mod 2 :- ER0181 By Kusuma M.H on 15-Sep-2009. MCO qualification has been done on turnover calculation.
mod 3 :- ER0182 By Kusuma M.H on 08-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
mod 4 :- ER0210 By KarthikG and Mrudula. Introduce PDT on 5150. 1) Handle PDT at Machine Level.
			2) Handle interaction between PDT and Mangement Loss. Also handle interaction InCycleDown And PDT.
			3) Improve the performance.
			4) Handle intearction between ICD and PDT for type 1 production record for the selected time period.
--dbcc freeproccache;dbcc dropcleanbuffers;
NOte :- Not introduced interaction between ML while getting maximum down reason
DR0236 - KarthikG - 19/Jun/2010 :: Use proper conditions in case statements to remove icd's from type 4 production records.
DR0325 - SwathiKS - 27/May/2013 :: For Utilised calculation To consider difference between Autodata msttime and ndtime instead NetCycletime for Tyep1 Record with PDT.
NR0090 - SwathiKS - 22/Jul/2013 :: To Display Totaltime Based on Setting in CockpitDefaults Table.
i.e. If Parameter="DisplayTTFormat" and Valueintext = "Display TotalTime" then Show Totaltime=Datediff(s,Start,End)
 If Parameter="DisplayTTFormat" and Valueintext = "Display TotalTime Less PDT" then Show Totaltime=Datediff(s,Start,End)-PDT
DR0330 - SwathiKS - 05/Aug/2013 :: To Consider Predefined Downtimes from Planned Downtimes table while Displaying Totaltime Less PDT.
NR0094 - SwathiKS - 27/Sep/2013 :: Based On setting in Cockpitdefaults Display ReturnPerHourUtilised OR LastPartID in Table and Iconic View.
ER0362 - SwathiKS - 01/Aug/2013 :: Altered Procedure S_GetCockpitdata to reuse 'Remarks' Column to get LastCycletime based on CompanyName.
ER0368 - SwathiKS - 23/Oct.2013 :: To Include QualityEficiency.
DR0333 - SwathiKS - 10/Dec/2013 :: For New Holland, Rejections were not associated properly when Rejdate and RejShift are not null while Calculating QE.
NR0097 - SwathiKS - 17/dec/2013 :: a> Ace - While Accounting ManagementLoss, To apply Threshold from Componentoperationprcing table for the Downs with "PickFomCO = 1" else apply threshold from Downcodeinformation tablw eith "Availeffy=1".
b> Since we are splitting Production and Down Cycle across shifts while showing partscount we have to consider decimal values instead whole Numbers.
ER0374 - SwathiKS/Satyen - 31/Jan/2014 :: a> Performance Optimization.
b> Used "dbo.f_GetLogicalDaystart" instead of "dbo.f_GetLogicalDay" because this function is not behaving properly in third shift condition.
select @enddate = dbo.f_GetLogicalDay(@endtime,'start')
DR0339 - SwathiKS - 25/Feb/2014 :: While handling ICD-PDT Interaction for Type-1,we have to pick cycles which has ProductionStart=ICDStart and ProductionEnd=ICDEnd.
ER0385 - SwathiKS - 04/Jul/2014 :: To Show Machine Status Running or Stopped in Iconic Cockpit.
ER0417 - Vasavi\SwathiKS - 10/Oct/2015 :: a> To Use "Remarks2" column to insert PlantID and Show Simple Average at Plant Level in TimeConsolidated Report.
b> Specific to Shanthi, kept Parameter Named Shanthi_TimeconsolidatedReport if Y then Use Returnperhour column to show MarkedForRework count and Consider OE as Ae*Pe*Qe and data will be refleted in Timeconsolidated Report.
DR0370 - SwathiKS - 24/Dec/2015 :: To Ignore bad Records from Rawdata while looking for Machine Running Status for SAF.   
ER0455 - SwathiKS - 23/Oct/2017 :: To implement AE Prediction Logic for Long Cycles and To Introduce New Columns in the Output LastCycleStart,LastCycleEnd,ElapsedTime,LastCycleSpindleRunTime,LastCycleDatatype For METSO.
ER0459 - SwathiKS - 23/Feb/2018 ::  Kun Aerospace - To Handle Machine Interfaceid>4 in Cockpit
ER0464 - Gopinath - 10/May/2018 :: To Display Machinewise Running Status Using New Table "MachineRunningStatus" Instead of "Rawdata" table for Performance Optimization.
ER0466 - SwathiKS - 30/Jun/2018 :: Altered prediction Logic For Long Running Cycle and calculate partscount and Pe
Anjana C V - 30/Jan/2019 :: To Introduce Group 

To Introduce New columns OperatorName,MachineLiveStatus,MachineLiveStatusColor for jagadeva
To Introduce New columns LastCycleCompDescription,LastCycleOperation,LastCycleOpnDescription for Globe
To Introduce New columns LastCompletedDowntime,CurrentDowntime,RunningCyclestdtime,RunningComponentBoxColor for L&T and Logic change for RunningCycleUT
To consider ICD or BCD record from rawdata for LastCompletedDowntime
exec s_GetCockpitData_WithTempTable_eshopx @StartTime=N'2022-01-01 06:00:00.000',@EndTime=N'2022-04-10 06:00:00.000',@MachineId=N'''30 Ton-Welding Machine-146'',''60 Ton-Welding Machine-155'',''SLT-08 LM195''',@PlantId=N'',@SortOrder=N'',
@GroupID=N'''Cell 1''',@param=N'' 

exec s_GetCockpitData_WithTempTable_eshopx @StartTime=N'2022-01-01 06:00:00.000',@EndTime=N'2022-04-10 06:00:00.000',
@MachineId=N'30 Ton-Welding Machine-146,60 Ton-Welding Machine-155,SLT-08 LM195',@PlantId=N'',@SortOrder=N'',
@GroupID=N'Cell 1',@param=N'' 
****************************************************************************************************/
CREATE                 PROCEDURE [dbo].[s_GetCockpitData_WithTempTable_eshopx]
	@StartTime datetime output,
	@EndTime datetime output,
	@MachineID nvarchar(max) = '',
	@PlantID nvarchar(50)='',
	@SortOrder nvarchar(50)='',
	@GroupID nvarchar(max)='',
	@SortType nvarchar(50)='',
	@param nvarchar(50)=''
	
AS
--s_GetCockpitData '01-DEC-2009 03:00:00','05-DEC-2009 03:00:00','',''
BEGIN
Declare @strPlantID as nvarchar(255)
Declare @strSql as nvarchar(4000)
Declare @strMachine as nvarchar(max)
declare @timeformat as nvarchar(2000)
Declare @StrTPMMachines AS nvarchar(500)		--karthik 21 feb 07
Declare @StrExMachine As Nvarchar(max)
declare @StrGroupID as nvarchar(max)
declare @StrMCJoined as nvarchar(max)
declare @StrGroupJoined as nvarchar(max)


--select @StrMCJoined =''
--select @StrGroupJoined=''
SELECT @StrTPMMachines=''					--karthik 21 feb 07
SELECT @strMachine = ''
SELECT @strPlantID = ''
SELECT @timeformat ='ss'
--DR0175
select @StrExMachine=''
select @StrGroupID=''
--DR0175
Select @timeformat = isnull((select valueintext from cockpitdefaults where parameter='timeformat'),'ss')
if (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')
begin
	select @timeformat = 'ss'
end

If ISNULL(@SortOrder,'')='' and (ISNULL(@param,'')='' or @param='Machinewise')
BEGIN
	SET @SortOrder = 'MachineID ASC'
END


Declare @CompanyName as nvarchar(50) --ER0362
Select @CompanyName = CompanyName from Company --ER0362

--ER0417 From Here
Declare @MarkedForRework as nvarchar(50)
Select @MarkedForRework = Isnull(valueintext,'N') from Shopdefaults where Parameter='Shanthi_TimeConsolidatedReport'
--ER0417 Till Here

Declare @Strsortorder as nvarchar(max)
Select @Strsortorder= ''
If @SortType='CustomSortorder'
Begin
	Select @Strsortorder= ' inner join MachinewiseSortOrder MS on C.Machineid=MS.Machineid Order By MS.SortOrder '
END
Else
Begin
	Select @Strsortorder= ' order by C.' + @SortOrder + ' '
END  

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
	--Remarks nvarchar(40),
	Remarks nvarchar(1000),
	Remarks1 nvarchar(50), --ER0368
	Remarks2 nvarchar(50), --ER0368
	Lastcycletime datetime,
	PEGreen smallint,
	PERed smallint,
	AEGreen smallint,
	AERed smallint,
	OEGreen smallint,
	OERed smallint,
	QEGreen smallint, --ER0368
	QERed smallint, --ER0368
	MaxDownReason nvarchar(50) DEFAULT ('')
	---mod 4 Added MLDown to store genuine downs which is contained in Management loss
	,MLDown float,
--ER0455
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
--ER0455
	OperatorName nvarchar(50),
	MachineLiveStatus nvarchar(50),
	MachineLiveStatusColor nvarchar(50),
	LastCycleCompDescription nvarchar(100),
	LastCycleOperation nvarchar(50),
	LastCycleOpnDescription nvarchar(100),
--CONSTRAINT CockpitData1_key PRIMARY KEY (machineinterface) : Commented By SSK On 06-Dec-2006
    --LastCompletedDowntime nvarchar(50),
	LastCompletedDowntime nvarchar(500),
	CurrentDowntime nvarchar(50),
	RunningCycleStdTime float,
    RunningComponentBoxColor nvarchar(50),
    ReworkCount float,
	SpindleRuntime float,
	SpindleCycleTime float,
	Target float,
	EndTimeForPDTCal datetime
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
	--ExCount Int --NR0097
	ExCount float --NR0097
)
--mod 4
CREATE TABLE #PLD
(
	MachineID nvarchar(50),
	--MachineInterface nvarchar(50), --ER0374
	MachineInterface nvarchar(50) NOT NULL, --ER0374
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
--mod 4

--ER0374 From here
ALTER TABLE #PLD
	ADD PRIMARY KEY CLUSTERED
		(   [MachineInterface]
						
		) ON [PRIMARY]


ALTER TABLE #PlannedDownTimes
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

Declare @T_ST AS Datetime 
Declare @T_ED AS Datetime 

---ER0374 from here
--Select @T_ST=dbo.f_GetLogicalDay(@StartTime,'start')
--Select @T_ED=dbo.f_GetLogicalDay(@EndTime,'End')
Select @T_ST=dbo.f_GetLogicalDaystart(@StartTime)
Select @T_ED=dbo.f_GetLogicalDayend(@EndTime)
---ER0374 Till here

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
--ER0374 Till Here


--NR0094 From Here
create table #Runningpart_Part
(  
 Machineid nvarchar(50),  
 Componentid nvarchar(50),
 StTime Datetime,
 OperatorName nvarchar(50)
)  

Declare @LastComp as nvarchar(100)
select @LastComp = Isnull(valueintext,'Display ReturnperHourUtilised') from cockpitdefaults where parameter='DisplayinIconicView'
--NR0094 Till Here

--ER0368 From here
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

create table #shift
(
	--ShiftDate Datetime, --DR0333
	ShiftDate nvarchar(10), --DR0333
	shiftname nvarchar(20),
	Shiftstart datetime,
	Shiftend datetime,
	shiftid int
)

Insert into #shift (ShiftDate,shiftname,Shiftstart,Shiftend)
--select ShiftDate,shiftname,ShftSTtime,ShftEndTime from #ShiftDefn where ShftSTtime>=@StartTime and ShftEndTime<=@endtime --DR0333
select convert(nvarchar(10),ShiftDate,126),shiftname,ShftSTtime,ShftEndTime from #ShiftDefn where ShftSTtime>=@StartTime and ShftEndTime<=@endtime --DR0333

Update #shift Set shiftid = isnull(#shift.Shiftid,0) + isnull(T1.shiftid,0) from
(Select SD.shiftid ,SD.shiftname from shiftdetails SD
inner join #shift S on SD.shiftname=S.shiftname where
running=1 )T1 inner join #shift on  T1.shiftname=#shift.shiftname

--ER0368 Till Here

--------ER0385 From Here
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
print @CurrTime
--------ER0385 Till Here


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
SubOperations int
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
	Target float default 0 ,
	Actual int default 0,
	Runtime float default 0,
	SubOperations int,
)

create table #spindledata
(
ID INT,
Mc nvarchar(50),
StartTime datetime,
Datatype nvarchar(50)
)

create table #TempSpindleData
(
Mc nvarchar(50),
SpindleStart datetime,
SpindleEnd datetime
)

create table #SpindleDataDetails
(
Mc nvarchar(50),
SpindleStart datetime,
SpindleEnd datetime,
SpindleCycleTime float,
)

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
	select @StrMCJoined =  (case when (coalesce( +@StrMCJoined + ',''', '''')) = ''''  then 'N''' else @StrMCJoined+',N''' end) +item+'''' from [SplitStrings](@MachineID, ',')    
	if @StrMCJoined = 'N'''''  
	set @StrMCJoined = '' 
	select @MachineID = @StrMCJoined

	SET @strMachine = ' AND Machineinformation.machineid in (' + @MachineID +')'
	SELECT @StrExMachine=' AND Ex.machineid in (' + @MachineID +')'
	---mod 3
end
if isnull(@PlantID,'')<> ''
Begin
	---mod 3
--	SET @strPlantID = ' AND PlantMachine.PlantID = ''' + @PlantID + ''''
	SET @strPlantID = ' AND PlantMachine.PlantID = N''' + @PlantID + ''''
	---mod 3
End
if isnull(@GroupID,'')<> ''
Begin
	select @StrGroupJoined =  (case when (coalesce( +@StrGroupJoined + ',''', '''')) = ''''  then 'N''' else @StrGroupJoined+',N''' end) +item+'''' from [SplitStrings](@GroupID, ',')    
	if @StrGroupJoined = 'N'''''  
	set @StrGroupJoined = '' 
	select @GroupID = @StrGroupJoined

	SET @strGroupID = ' AND PlantMachineGroups.GroupID in (' + @GroupID +')'
End


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
	Remarks1, --ER0368
	Remarks2, --ER0368
	SpindleRuntime,
	SpindleCycleTime
	) '
SET @strSql = @strSql + ' SELECT MachineInformation.MachineID, MachineInformation.interfaceid ,0,0,0,0,0,0,0,0,0,0,0,0,0,0,PEGreen ,PERed,AEGreen ,AERed ,OEGreen ,OERed,isnull(QERed,0),isnull(QEGreen,0),0,PlantMachine.PlantID,0,0 FROM MachineInformation --ER0368 --ER0417(To include Plantid in Remarks2 column)
			  LEFT OUTER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID
			  LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID
 WHERE MachineInformation.interfaceid > ''0'' '
SET @strSql =  @strSql + @strMachine + @strPlantID + @StrTPMMachines + @StrGroupID
EXEC(@strSql)

--mod 4 Get the Machines into #PLD
SET @strSql = ''
SET @strSql = 'INSERT INTO #PLD(MachineID,MachineInterface,pPlannedDT,dPlannedDT)
	SELECT machineinformation.MachineID ,Interfaceid,0  ,0 FROM MachineInformation
		LEFT OUTER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID 
    LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID
	 WHERE  MachineInformation.interfaceid > ''0'' '
SET @strSql =  @strSql + @strMachine + @StrTPMMachines + @StrGroupID
EXEC(@strSql)

/* Planned Down times for the given time period */
SET @strSql = ''
SET @strSql = 'Insert into #PlannedDownTimes
	SELECT Machine,InterfaceID,
		CASE When StartTime<''' + convert(nvarchar(20),@StartTime,120)+''' Then ''' + convert(nvarchar(20),@StartTime,120)+''' Else StartTime End As StartTime,
		CASE When EndTime>''' + convert(nvarchar(20),@EndTime,120)+''' Then ''' + convert(nvarchar(20),@EndTime,120)+''' Else EndTime End As EndTime
	FROM PlannedDownTimes inner join MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID
	LEFT OUTER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID 
    LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID 
	and PlantMachineGroups.machineid = PlantMachine.MachineID
	WHERE PDTstatus =1 and(
	(StartTime >= ''' + convert(nvarchar(20),@StartTime,120)+''' AND EndTime <=''' + convert(nvarchar(20),@EndTime,120)+''')
	OR ( StartTime < ''' + convert(nvarchar(20),@StartTime,120)+'''  AND EndTime <= ''' + convert(nvarchar(20),@EndTime,120)+''' AND EndTime > ''' + convert(nvarchar(20),@StartTime,120)+''' )
	OR ( StartTime >= ''' + convert(nvarchar(20),@StartTime,120)+'''   AND StartTime <''' + convert(nvarchar(20),@EndTime,120)+''' AND EndTime > ''' + convert(nvarchar(20),@EndTime,120)+''' )
	OR ( StartTime < ''' + convert(nvarchar(20),@StartTime,120)+'''  AND EndTime > ''' + convert(nvarchar(20),@EndTime,120)+''')) '
SET @strSql =  @strSql + @strMachine + @StrGroupID + @StrTPMMachines + ' ORDER BY Machine,StartTime'
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
--select * from #Exceptions
--return
/*******************************      Utilised Calculation Starts ***************************************************/
-- Get the utilised time
--Optimize with innerjoin - mkestur 08/16/2004
-- Type 1
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
--DR0236 - KarthikG - 19/Jun/2010 :: From Here
--	When autodata.sttime >= @StartTime AND autodata.ndtime <= @EndTime Then datediff(s , autodata.sttime,autodata.ndtime)
--	When autodata.sttime < @StartTime AND autodata.ndtime<=@EndTime Then datediff(s, @StartTime,autodata.ndtime )
--	When autodata.ndtime >= @EndTime AND autodata.sttime>@StartTime Then datediff(s,autodata.sttime, @EndTime )
--	When autodata.sttime<@StartTime AND autodata.ndtime>@EndTime   Then datediff(s , @StartTime,@EndTime)
	When autodata.sttime >= @StartTime AND autodata.ndtime <= @EndTime Then datediff(s , autodata.sttime,autodata.ndtime)
	When autodata.sttime < @StartTime AND autodata.ndtime > @StartTime AND autodata.ndtime<=@EndTime Then datediff(s, @StartTime,autodata.ndtime )
	When autodata.sttime>=@StartTime And autodata.sttime < @EndTime AND autodata.ndtime > @EndTime Then datediff(s,autodata.sttime, @EndTime )
	When autodata.sttime<@StartTime AND autodata.ndtime>@EndTime   Then datediff(s , @StartTime,@EndTime)
--DR0236 - KarthikG - 19/Jun/2010 :: Till Here
END) as Down
From #T_autodata AutoData INNER Join --ER0374
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


     /*************************** ER0374 Commented From Here **********************
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
		FROM AutoData CROSS jOIN #PlannedDownTimes T
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
		From AutoData INNER Join
			(Select mc,Sttime,NdTime From AutoData
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
		From AutoData INNER Join
			(Select mc,Sttime,NdTime From AutoData
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
	From AutoData INNER Join
		(Select mc,Sttime,NdTime From AutoData
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
	From AutoData INNER Join
		(Select mc,Sttime,NdTime From AutoData
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
     *************************** ER0374 Commented Till Here **********************/

	------------------------------------ ER0374 Added Till Here ---------------------------------
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
			--(B.sttime < A.sttime) AND (B.ndtime > A.ndtime) --DR0339
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
		from #T_autodata autodata  --ER0374
		INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
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
		from #T_autodata autodata  --ER0374
		INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
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
		from #T_autodata autodata --ER0374
		INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
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
		from #T_autodata autodata --ER0374
		INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
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
		from #T_autodata autodata --ER0374
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
	from #T_autodata autodata --ER0374
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
		FROM #T_autodata AutoData --ER0374
		CROSS jOIN #PlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)
			/*AND
			(
			(autodata.sttime >= @StartTime  AND autodata.ndtime <=@EndTime)
			OR ( autodata.sttime < @StartTime  AND autodata.ndtime <= @EndTime AND autodata.ndtime > @StartTime )
			OR ( autodata.sttime >= @StartTime   AND autodata.sttime <@EndTime AND autodata.ndtime > @EndTime )
			OR ( autodata.sttime < @StartTime  AND autodata.ndtime > @EndTime)
			) */ AND (downcodeinformation.availeffy = 0)
		group by autodata.mc
	) as TT INNER JOIN #PLD ON TT.mc = #PLD.MachineInterface
	--select * from #PLD
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
		from #T_autodata autodata --ER0374
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
		FROM #T_autodata AutoData --ER0374
		CROSS jOIN #PlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)
--			AND
--			(
--			(autodata.sttime >= @StartTime  AND autodata.ndtime <=@EndTime)
--			OR ( autodata.sttime < @StartTime  AND autodata.ndtime <= @EndTime AND autodata.ndtime > @StartTime )
--			OR ( autodata.sttime >= @StartTime   AND autodata.sttime <@EndTime AND autodata.ndtime > @EndTime )
--			OR ( autodata.sttime < @StartTime  AND autodata.ndtime > @EndTime)
--			)
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
			/*AND
			(
			(autodata.sttime >= @StartTime  AND autodata.ndtime <=@EndTime)
			OR ( autodata.sttime < @StartTime  AND autodata.ndtime <= @EndTime AND autodata.ndtime > @StartTime )
			OR ( autodata.sttime >= @StartTime   AND autodata.sttime <@EndTime AND autodata.ndtime > @EndTime )
			OR ( autodata.sttime < @StartTime  AND autodata.ndtime > @EndTime)
			) */ AND (downcodeinformation.availeffy = 1) 
			AND (downcodeinformation.ThresholdfromCO <>1) --NR0097 
		group by autodata.mc
	) as TT INNER JOIN #PLD ON TT.mc = #PLD.MachineInterface

	UPDATE #CockpitData SET downtime = isnull(downtime,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)
	
END

----------------------------- NR0097 Added From here ----------------------------------------------
select autodata.id,autodata.mc,autodata.comp,autodata.opn,
isnull(CO.Stdsetuptime,0)AS Stdsetuptime , 
sum(case
when autodata.sttime>=@starttime and autodata.ndtime<=@endtime then autodata.loadunload
when autodata.sttime<@starttime and autodata.ndtime>@starttime and autodata.ndtime<=@endtime then Datediff(s,@starttime,ndtime)
when autodata.sttime>=@starttime and autodata.sttime<@endtime and autodata.ndtime>@endtime then  datediff(s,sttime,@endtime)
when autodata.sttime<@starttime and autodata.ndtime>@endtime then  datediff(s,@starttime,@endtime)
end) as setuptime,0 as ML,0 as Downtime
into #setuptime
from #T_autodata autodata --ER0374
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
		from #T_autodata autodata --ER0374
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
----------------------------- NR0097 Added Till here ----------------------------------------------


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
--			AND
--			(
--			(autodata.sttime >= @StartTime  AND autodata.ndtime <=@EndTime)
--			OR ( autodata.sttime < @StartTime  AND autodata.ndtime <= @EndTime AND autodata.ndtime > @StartTime )
--			OR ( autodata.sttime >= @StartTime   AND autodata.sttime <@EndTime AND autodata.ndtime > @EndTime )
--			OR ( autodata.sttime < @StartTime  AND autodata.ndtime > @EndTime)
--			)--AND (D.availeffy = 0)
		group by autodata.mc
	) as TT INNER JOIN #PLD ON TT.mc = #PLD.MachineInterface
END
---mod 4:If Ignore_Dtime_4m_PLD<> Y and Ignore_Dtime_4m_PLD<> N
--************************************ Down and Management  Calculation Ends ******************************************
---mod 4
-- Get the value of CN
-- Type 1

--Commented & altered query for performance optimzation
--UPDATE #CockpitData SET CN = isnull(CN,0) + isNull(t2.C1N1,0)
--from
--(select mc,
--SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))* autodata.partscount) C1N1
----SUM(componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1)) C1N1
--FROM #T_autodata autodata --ER0374
--INNER JOIN
--componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
--componentinformation ON autodata.comp = componentinformation.InterfaceID AND
--componentoperationpricing.componentid = componentinformation.componentid
----mod 2
--inner join machineinformation on machineinformation.interfaceid=autodata.mc
--and componentoperationpricing.machineid=machineinformation.machineid
----mod 2
--where (((autodata.sttime>=@StartTime)and (autodata.ndtime<=@EndTime)) or
--((autodata.sttime<@StartTime)and (autodata.ndtime>@StartTime)and (autodata.ndtime<=@EndTime)) )
--and (autodata.datatype=1)
--group by autodata.mc
--) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface


UPDATE #CockpitData SET CN = isnull(CN,0) + isNull(t2.C1N1,0)
from
(select mc,
SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))* autodata.partscount) C1N1
FROM (Select distinct T.mc,T.comp,T.opn,sum(T.partscount) as partscount from #T_autodata T
where T.datatype=1 and ((T.sttime>=@StartTime and T.ndtime<=@EndTime) or
(T.sttime<@StartTime and T.ndtime>@StartTime and T.ndtime<=@EndTime))
 group by T.mc,T.comp,T.opn) autodata --ER0374
inner join machineinformation on autodata.mc = machineinformation.interfaceid
INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID
INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID
 AND componentoperationpricing.componentid = componentinformation.componentid and
 componentoperationpricing.machineid=machineinformation.machineid
 group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface
--Commented & altered query for performance optimzation

-- mod 4 Ignore count from CN calculation which is over lapping with PDT
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	UPDATE #CockpitData SET CN = isnull(CN,0) - isNull(t2.C1N1,0)
	From
	(
		select mc,SUM((O.cycletime * ISNULL(A.PartsCount,1))/ISNULL(O.SubOperations,1))  C1N1
		From #T_autodata A --ER0374
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
/*
UPDATE #CockpitData SET CN = isnull(CN,0) + isNull(t2.C1N1,0)
from
(select mc,
SUM((componentoperationpricing.cycletime/ISNULL(componentoperationpricing.SubOperations,1))* (autodata.partscount/ISNULL(componentoperationpricing.PalletCapacity,1))) C1N1  
--SUM(componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1)) C1N1
FROM #T_autodata autodata --ER0374
INNER JOIN
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
		select mc,SUM((O.cycletime * (ISNULL(A.PartsCount,1)/ISNULL(O.PalletCapacity,1)))/ISNULL(O.SubOperations,1))  C1N1 
		From #T_autodata A --ER0374
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
*/
-- mod 4
-- Get the TurnOver
-- Type 1
--*********************************************************************************
-- Following Code is added by Sangeeta K . Mutlistpindle Concept affects Count And TurnOvER--
--mod 4(3):Following IF condition is added to get the exception count if there are any exception rule defined.
if (select count(*) from #Exceptions)> 0
Begin
--mod 4(3)
	UPDATE #Exceptions SET StartTime=@StartTime WHERE (StartTime<@StartTime)AND EndTime>@StartTime
	UPDATE #Exceptions SET EndTime=@EndTime WHERE (EndTime>@EndTime AND StartTime<@EndTime )
	Select @StrSql = 'UPDATE #Exceptions SET ExCount=ISNULL(T2.Comp,0) From
		(
			SELECT T1.MachineID AS MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime AS StartTime,T1.EndTime AS EndTime,
			--SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp --NR0097
			SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp --NR0097
	 		From (
				select MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,comp,opn,Tt1.StartTime,Tt1.EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount 
				from #T_autodata autodata --ER0374
				Inner Join MachineInformation  ON autodata.MC=MachineInformation.InterfaceID
				Inner Join ComponentInformation  ON autodata.Comp = ComponentInformation.InterfaceID
				Inner Join ComponentOperationPricing on autodata.Opn=ComponentOperationPricing.InterfaceID And ComponentInformation.ComponentID=ComponentOperationPricing.ComponentID'
		---mod 2
			Select @StrSql = @StrSql +' and ComponentOperationPricing.machineid=machineinformation.machineid'
		---mod 2
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
		---mod 2
			Select @StrSql = @StrSql +' Inner join machineinformation M on T1.machineid = M.machineid '
		---mod 2
	  		Select @StrSql = @StrSql +' GROUP BY T1.MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime,t1.EndTime
		)AS T2
		WHERE  #Exceptions.StartTime=T2.StartTime AND #Exceptions.EndTime=T2.EndTime
		AND #Exceptions.MachineID=T2.MachineID AND #Exceptions.ComponentID = T2.ComponentID AND #Exceptions.OperationNo=T2.OperationNo'
		print @StrSql
		Exec(@StrSql)
--mod 4(1):Interaction with PDT
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
						Max(T1.XStartTime)StartTime,Max(T1.XEndTime)EndTime,T1.PLD_StartTime,T1.PLD_EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount 
						from #T_autodata autodata --ER0374
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
--mod 4(1):Interaction with PDT
		UPDATE #Exceptions SET ExCount=ExCount-((ExCount * ActualCount)/ISNULL(IdealCount,0))
--mod 4(3):Following End is wrt to get the exception count if there are any exception rule defined.
End
--mod 4(3):
--*********************************************************************************

--Commented & altered query for performance optimzation
--TYPE1,TYPE2
--UPDATE #CockpitData SET turnover = isnull(turnover,0) + isNull(t2.revenue,0)
--from
--(select mc,
--SUM((componentoperationpricing.price/ISNULL(ComponentOperationPricing.SubOperations,1))* ISNULL(autodata.partscount,1)) revenue
--FROM #T_autodata autodata --ER0374
--INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID
--INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID AND componentoperationpricing.componentid = componentinformation.componentid
-----mod 2
--inner join machineinformation on componentoperationpricing.machineid=machineinformation.machineid
----mod 2 :- ER0181 By Kusuma M.H on 15-Sep-2009.
--AND autodata.mc = machineinformation.interfaceid
----mod 2 :- ER0181 By Kusuma M.H on 15-Sep-2009.
-----mod 2
--where (
--(autodata.sttime>=@StartTime and autodata.ndtime<=@EndTime)OR
--(autodata.sttime<@StartTime and autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime))and (autodata.datatype=1)
--group by autodata.mc
--) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface

UPDATE #CockpitData SET turnover = isnull(turnover,0) + isNull(t2.revenue,0)
from
(select A.mc,
SUM((O.price/ISNULL(O.SubOperations,1))* ISNULL(A.partscount,1)) revenue
FROM (Select distinct T.mc,T.comp,T.opn,sum(T.partscount) as partscount from #T_autodata T
where ((T.sttime>=@StartTime and T.ndtime<=@EndTime) or
(T.sttime<@StartTime and T.ndtime>@StartTime and T.ndtime<=@EndTime))
and T.datatype=1 group by T.mc,T.comp,T.opn) A --ER0374
Inner join machineinformation M on M.interfaceid=A.mc
Inner join componentinformation C ON A.Comp=C.interfaceid
Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID
group by A.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface
--Commented & altered query for performance optimzation

--Excluding Exception count from turnover calculation
UPDATE #CockpitData SET Turnover = ISNULL(Turnover,0) - ISNULL(t2.xTurnover,0)
from
( select Ex.MachineID,
SUM((O.price)* ISNULL(ExCount,0)) as xTurnover
From #Exceptions Ex
INNER JOIN ComponentInformation C ON Ex.ComponentID=C.ComponentID
INNER JOIN ComponentOperationPricing O ON Ex.OperationNO=O.OperationNO AND C.ComponentID=O.ComponentID
---mod 2
and O.machineid = Ex.machineid
---mod 2
GROUP BY Ex.MachineID) as T2
Inner join #CockpitData on T2.MachineID = #CockpitData.MachineID

--Mod 4 Apply PDT for TurnOver Calculation.
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	UPDATE #CockpitData SET turnover = isnull(turnover,0) - isNull(t2.revenue,0)
	From
	(
		select mc,SUM((O.price * ISNULL(A.PartsCount,1))/ISNULL(O.SubOperations,1))as revenue
		From #T_autodata A --ER0374
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
--Mod 4
--Calculation of PartsCount Begins..
UPDATE #CockpitData SET components = ISNULL(components,0) + ISNULL(t2.comp,0)
From
(
	--Select mc,SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp --NR0097
	  Select mc,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp --NR0097
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
			select mc,Sum(ISNULL(PartsCount,1))AS OrginalCount,comp,opn 
			from #T_autodata autodata --ER0374
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

--calculation of airpressurecnt starts
update #CockPitData set SpindleRuntime= t.runtime
from(
select machineid,sum(runtime) as runtime from spindleruntimedatainfo
where  updatedts>=@StartTime and updatedts<=@EndTime
group by machineid
)t inner join #CockPitData on t.machineid=#CockPitData.MachineInterface
--calculation of airpressurecnt ends


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

---- Calculate efficiencies

UPDATE #CockpitData
SET
	TotalTime = DateDiff(second, @StartTime, @EndTime)

UPDATE #CockpitData
SET
	ProductionEfficiency = (CN/UtilisedTime) ,-----SV Commented and added below
	AvailabilityEfficiency = (UtilisedTime)/(UtilisedTime + DownTime - ManagementLoss), -----SV Commented and added below
	--TotalTime = DateDiff(second, @StartTime, @EndTime),
	ReturnPerHour = (TurnOver/UtilisedTime)*3600,
	ReturnPerHourtotal = (TurnOver/DateDiff(second, @StartTime, @EndTime))*3600,
	Remarks = ' '
WHERE UtilisedTime <> 0

/************commented here and added below******************/
----NR0090 From Here
--If (SELECT ValueInText From CockpitDefaults Where Parameter ='DisplayTTFormat')='Display TotalTime - Less PDT' 
--BEGIN
------------------------------------- DR0330 From Here -----------------------------------------------------
------	UPDATE #CockpitData SET TotalTime = Totaltime -ISNULL(#PLD.pPlannedDT,0)- isnull(#PLD.IPlannedDT,0)- ISNULL(#PLD.dPlannedDT,0)
----	UPDATE #CockpitData SET TotalTime = Totaltime -ISNULL(#PLD.pPlannedDT,0)-ISNULL(#PLD.dPlannedDT,0) + isnull(#PLD.IPlannedDT,0)
----	From #CockpitData Inner Join #PLD on #PLD.Machineid=#CockpitData.Machineid	

----	UPDATE #CockpitData SET TotalTime = Case when Remarks<>'Machine Not In Production' then Totaltime - isnull(T1.PDT,0) else isnull(T1.PDT,0) End
--	UPDATE #CockpitData SET TotalTime = Totaltime - isnull(T1.PDT,0) 
--	from
--	(Select Machine,SUM(datediff(S,Starttime,endtime))as PDT from Planneddowntimes
--	 where starttime>=@starttime and endtime<=@endtime group by machine)T1
--	 Inner Join #CockpitData on T1.Machine=#CockpitData.Machineid WHERE UtilisedTime <> 0	
------------------------------------- DR0330 Till Here -----------------------------------------------------
--End
----NR0090 Till Here

--UPDATE #CockpitData
--SET
--	ManagementLoss = ((TotalTime - ManagementLoss)- (DownTime- ManagementLoss))/(TotalTime-ManagementLoss)	
--WHERE UtilisedTime <> 0

-----SV Commented and Moved down
--UPDATE #CockpitData
--SET
--	OverAllEfficiency = (ProductionEfficiency * AvailabilityEfficiency)*100,
--	ProductionEfficiency = ProductionEfficiency * 100 ,
--	AvailabilityEfficiency = AvailabilityEfficiency * 100
-----SV Commented and Moved down

--NR0094 From Here
--UPDATE #CockpitData
--SET Remarks = 'Machine Not In Production'
--WHERE UtilisedTime = 0
--NR0094 Till Here
-------------------------------------------------------------------------------------------------------------------
					/* Maximum Down Reason Time ,Calculation as goes down*/
---Irrespective of whether the down is management loss or genuine down we are considering the down reason which is the largest
----------------------------------------------------------------------------------------------------------------------
CREATE TABLE #DownTimeData
(
	MachineID nvarchar(50) NOT NULL,
	--McInterfaceid nvarchar(4), --ER0459
	McInterfaceid nvarchar(50), --ER0459
	DownID nvarchar(50) NOT NULL,
	DownTime float,
	DownFreq int
	--CONSTRAINT downtimedata_key PRIMARY KEY (MachineId, DownID)
)
ALTER TABLE #DownTimeData
	ADD PRIMARY KEY CLUSTERED
	(
		[MachineId], [DownID]
	)ON [PRIMARY]
--mod 4 commented below tables  for Optimization
--CREATE TABLE #FinalData
--(
	--MachineID nvarchar(50) NOT NULL,
	--DownID nvarchar(50) NOT NULL,
	--DownTime float,
	--downfreq int,
	--TotalMachine float,
	--TotalDown float,
	--TotalMachineFreq float DEFAULT(0),
	--TotalDownFreq float DEFAULT(0)
	--CONSTRAINT finaldata_key PRIMARY KEY (MachineID, DownID)
--)
--ALTER TABLE #FinalData
	--ADD PRIMARY KEY CLUSTERED
	--(
	--	[MachineId], [DownID]
	--)ON [PRIMARY]
--CREATE TABLE #MAXDownReasonTime(
	--MachineID nvarchar(50),
	--MaxReasonTime nvarchar(50) Default('')
--)
--mod 4 commented till here  for Optimization
select @strsql = ''
select @strsql = 'INSERT INTO #DownTimeData (MachineID,McInterfaceid, DownID, DownTime,DownFreq) SELECT Machineinformation.MachineID AS MachineID,Machineinformation.interfaceid, downcodeinformation.downid AS DownID, 0,0'
select @strsql = @strsql+' FROM Machineinformation CROSS JOIN downcodeinformation LEFT OUTER JOIN PlantMachine ON PlantMachine.MachineID=Machineinformation.MachineID 
LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID '
select @strsql = @strsql+' Where MachineInformation.interfaceid > ''0'' '
select @strsql = @strsql + @strPlantID +@strmachine + @StrTPMMachines + @StrGroupID + ' ORDER BY  downcodeinformation.downid, Machineinformation.MachineID'
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
select @strsql = @strsql + ' #T_autodata autodata INNER JOIN' --ER0374
select @strsql = @strsql + ' machineinformation ON autodata.mc = machineinformation.InterfaceID 
Left Outer Join PlantMachine ON PlantMachine.MachineID=machineinformation.MachineID 
LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID
INNER JOIN'
select @strsql = @strsql + ' componentinformation ON autodata.comp = componentinformation.InterfaceID INNER JOIN'
select @strsql = @strsql + ' employeeinformation ON autodata.opr = employeeinformation.interfaceid INNER JOIN'
select @strsql = @strsql + ' downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid'
select @strsql = @strsql + ' where  datatype=2 AND ((autodata.sttime>='''+convert(varchar(20),@starttime)+''' and autodata.ndtime<='''+convert(varchar(20),@endtime)+''' )OR
(autodata.sttime<'''+convert(varchar(20),@starttime)+''' and autodata.ndtime>'''+convert(varchar(20),@starttime)+'''and autodata.ndtime<='''+convert(varchar(20),@endtime)+''')OR
(autodata.sttime>='''+convert(varchar(20),@starttime)+'''and autodata.sttime<'''+convert(varchar(20),@endtime)+''' and autodata.ndtime>'''+convert(varchar(20),@endtime)+''')OR
(autodata.sttime<'''+convert(varchar(20),@starttime)+''' and autodata.ndtime>'''+convert(varchar(20),@endtime)+'''))'
select @strsql = @strsql  + @strPlantID + @strmachine + @StrGroupID
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
		FROM #T_autodata AutoData --ER0374
		CROSS jOIN #PlannedDownTimes T
		Inner Join DownCodeInformation On AutoData.DCode=DownCodeInformation.InterfaceID
		WHERE autodata.DataType=2 AND T.MachineInterface = AutoData.mc And
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)
--			AND
--			(
--			(autodata.sttime >= @StartTime  AND autodata.ndtime <=@EndTime)
--			OR ( autodata.sttime < @StartTime  AND autodata.ndtime <= @EndTime AND autodata.ndtime > @StartTime )
--			OR ( autodata.sttime >= @StartTime   AND autodata.sttime <@EndTime AND autodata.ndtime > @EndTime )
--			OR ( autodata.sttime < @StartTime  AND autodata.ndtime > @EndTime)
--			)
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
		FROM #T_autodata AutoData --ER0374
		CROSS jOIN #PlannedDownTimes T
		Inner Join DownCodeInformation D ON AutoData.DCode = D.InterfaceID
		WHERE autodata.DataType=2 And T.MachineInterface = AutoData.mc AND D.DownID=(SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD') AND
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)
--			AND
--			(
--			(autodata.sttime >= @StartTime  AND autodata.ndtime <=@EndTime)
--			OR ( autodata.sttime < @StartTime  AND autodata.ndtime <= @EndTime AND autodata.ndtime > @StartTime )
--			OR ( autodata.sttime >= @StartTime   AND autodata.sttime <@EndTime AND autodata.ndtime > @EndTime )
--			OR ( autodata.sttime < @StartTime  AND autodata.ndtime > @EndTime)
--			)
		group by autodata.mc,DownId
	) as TT INNER JOIN #DownTimeData ON TT.mc = #DownTimeData.McInterfaceid AND #DownTimeData.DownID=TT.DownId
	Where #DownTimeData.DownTime>0
END
--mod 4
--mod 4 commented below queries for Optimization
/*INSERT INTO #FinalData (MachineID, DownID, DownTime)
	select MachineID, DownID, DownTime
	from #DownTimeData*/
/*INSERT INTO #MAXDownReasonTime (MachineID,MaxReasonTime)
select A.MachineID,
SUBSTRING(MAx(A.DownID),1,6)+ '-'+ SUBSTRING(dbo.f_FormatTime(A.DownTime,'hh:mm:ss'),1,5) as MaxDownReasonTime
FROM #FinalData A
INNER JOIN (SELECT B.machineid,MAX(B.DownTime)as DownTime FROM #FinalData B group by machineid) as T2
ON A.MachineId = T2.MachineId and A.DownTime = t2.DownTime
Where A.DownTime > 0
group by A.MachineId,A.DownTime
UPDATE #CockpitData
SET MaxDownReason = MaxReasonTime
From #MaxDownReasonTime
INNER JOIN #CockPitData
ON #MaxDownReasonTime.MachineID = #CockpitData.MachineID*/

--mod 4 commented till here for Optimization
---mod 4 Update for MaxDownReasonTime
Update #CockpitData SET MaxDownReason = MaxDownReasonTime
From (select A.MachineID as MachineID,
SUBSTRING(MAx(A.DownID),1,6)+ '-'+ SUBSTRING(dbo.f_FormatTime(A.DownTime,'hh:mm:ss'),1,5) as MaxDownReasonTime
FROM #DownTimeData A
INNER JOIN (SELECT B.machineid,MAX(B.DownTime)as DownTime FROM #DownTimeData B group by machineid) as T2
ON A.MachineId = T2.MachineId and A.DownTime = t2.DownTime
Where A.DownTime > 0
group by A.MachineId,A.DownTime)as T3 inner join #CockpitData on T3.MachineID = #CockpitData.MachineID
---mod 4

--Commented & Added for Nippon India for Performance optimization
--select @strsql=''
--SELECT @strsql= @strsql + 'insert into #Runningpart_Part(Machineid,Componentid,OperatorName,Sttime)
--	select Machineinformation.machineid,C.Componentid,E.Name,Max(A.Sttime) from 
--	(
--	Select Mc,Comp,Opn,Opr,Max(sttime) as Sttime From Autodata A  
--	where sttime>='''+convert(nvarchar(20),@starttime)+''' and ndtime<='''+convert(nvarchar(20),@endtime)+'''
--	Group by Mc,Comp,Opn,Opr
--	) as A
--	inner join Machineinformation on A.mc=Machineinformation.interfaceid  
--	inner join Componentinformation C on A.comp=C.interfaceid  
--	inner join Componentoperationpricing CO on A.opn=CO.interfaceid and Machineinformation.Machineid=CO.Machineid and C.Componentid=CO.Componentid 
--	inner join Employeeinformation E on A.Opr=E.interfaceid ' 
--SELECT @strsql = @strsql + @strmachine  
--SELECT @strsql = @strsql +'group by Machineinformation.machineid,C.Componentid,E.Name'
--print @strsql
--exec (@strsql)  



select @strsql=''
SELECT @strsql= @strsql + 'insert into #Runningpart_Part(Machineid,Componentid,OperatorName,Sttime)
	select Machineinformation.machineid,C.Componentid,E.Name,Max(A.Sttime) from 
	(
	Select Mc,Comp,Opn,Opr,Max(sttime) as Sttime From #T_Autodata A  
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
--Commented & Added for Nippon India for Performance optimization
Update #Cockpitdata Set OperatorName = isnull(T1.opr,0) from
(Select T.Machineid,T.opr from
	(select Machineid,OperatorName as opr,sttime,
	row_number() over(partition by Machineid,OperatorName order by sttime desc) as rn
	From #Runningpart_Part 
	)T where T.rn <= 1
) as T1 inner join #Cockpitdata on #Cockpitdata.machineid=T1.machineid 

--ER0362 From here
If @companyName = 'VISHWAKARMA'
Begin

	Update #CockpitData Set Remarks = T1.LastCycle from 
	(
		Select M.Machineid,convert(varchar,A.ndtime,120) as LastCycle from 
		(
			Select mc,max(id) as idd from autodata where datatype=1 group by mc
		)T inner join Autodata  A on A.mc=T.mc and A.id=T.idd inner join Machineinformation M on M.interfaceid=A.mc
	) T1 inner join #CockpitData on T1.MachineID = #CockpitData.MachineID 
END
--ER0362 Till here
--NR0094 From Here
ELSE If @companyName <> 'VISHWAKARMA' and @LastComp = 'Display JobCode'
Begin

	--select @strsql=''
	--SELECT @strsql= @strsql + 'insert into #Runningpart_Part(Machineid,Componentid,StTime)  
	--  select Machineinformation.machineid,C.Componentid,Max(A.StTime) as Sttime from Autodata A  
	--  inner join Machineinformation on A.mc=Machineinformation.interfaceid  
	--  LEFT OUTER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID 
	--  LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID
	--  inner join Componentinformation C on A.comp=C.interfaceid  
	--  inner join Componentoperationpricing CO on A.opn=CO.interfaceid  
	--  and Machineinformation.Machineid=CO.Machineid and C.Componentid=CO.Componentid  
	--  where sttime>='''+convert(nvarchar(20),@starttime)+''' and ndtime<='''+convert(nvarchar(20),@endtime)+'''   '  
	--SELECT @strsql = @strsql + @strmachine + @StrGroupID  
	--SELECT @strsql = @strsql +'group by Machineinformation.Machineid,C.Componentid Order by Machineinformation.machineid'
	--print @strsql
	--exec (@strsql)  

	--Update #Cockpitdata Set Remarks = Isnull(Remarks,0) + isnull(T.Comp,0) from
	--(select componentid as Comp,isnull(machineid ,'') as machineid from #Runningpart_Part)T inner join #Cockpitdata 
	--on #Cockpitdata.machineid=T.machineid 

	Update #Cockpitdata Set Remarks = isnull(T1.Comp,0)
	from
	(Select T.Machineid,T.comp from
	(select Machineid,Componentid as comp,sttime,
	row_number() over(partition by Machineid,Componentid order by sttime desc) as rn
	From #Runningpart_Part 
	)T where T.rn <= 1
	) as T1 inner join #Cockpitdata on #Cockpitdata.machineid=T1.machineid 

	Update #Cockpitdata Set Remarks = 0 where Isnull(Remarks,'a')='a'  or UtilisedTime = 0
END
Else If @companyName <> 'VISHWAKARMA' and @LastComp <> 'Display JobCode'
BEGIN
	UPDATE #CockpitData SET Remarks = 'Machine Not In Production' WHERE UtilisedTime = 0
END
--NR0094 Till Here

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

--UPDATE #Cockpitdata SET QualityEfficiency= ISNULL(QualityEfficiency,1) + IsNull(T1.QE,1) 
--FROM(Select MachineID,
--CAST((Sum(Components))As Float)/CAST((Sum(IsNull(Components,0))+Sum(IsNull(RejCount,0))) AS Float)As QE
--From #Cockpitdata Where Components<>0 Group By MachineID
--)AS T1 Inner Join #Cockpitdata ON  #Cockpitdata.MachineID=T1.MachineID

UPDATE #Cockpitdata SET QualityEfficiency= ISNULL(QualityEfficiency,1) + IsNull(T1.QE,1) 
FROM(Select MachineID,
cast((Sum(isnull(Components,0))-Sum(IsNull(RejCount,0))) as float)/CAST((Sum(IsNull(Components,0))) AS Float)As QE
From #Cockpitdata Where Components<>0 Group By MachineID
)AS T1 Inner Join #Cockpitdata ON  #Cockpitdata.MachineID=T1.MachineID

----SV Commented and added below
---SV Added From here
UPDATE #CockpitData
SET
	OverAllEfficiency = (ProductionEfficiency * AvailabilityEfficiency * ISNULL(QualityEfficiency,1))*100,
	ProductionEfficiency = ProductionEfficiency * 100 ,
	AvailabilityEfficiency = AvailabilityEfficiency * 100,
	QualityEfficiency = QualityEfficiency*100
---SV Added Till here
---SV Commented and added below

--UPDATE #CockpitData
--SET QualityEfficiency = QualityEfficiency*100 
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

-----ER0464 --g: using MachineRunningStatus table instead of rawdata
--Insert into #machineRunningStatus(MachineID,MachineInterface,sttime,ndtime,datatype,Colorcode)    
--select fd.MachineID,fd.MachineInterface,sttime,ndtime,datatype,'White' from rawdata    
--inner join (select mc,max(slno) as slno from rawdata WITH (NOLOCK) where sttime<@currtime and isnull(ndtime,'1900-01-01')<@currtime    
--and datatype in(2,42,40,41,1,11) and datepart(year,sttime)>'2000' group by mc ) t1 on t1.mc=rawdata.mc and t1.slno=rawdata.slno --For SAF DR0370    
--right outer join #CockpitData fd on fd.MachineInterface = rawdata.mc    
--order by rawdata.mc    


Insert into #machineRunningStatus(MachineID,MachineInterface,sttime,ndtime,datatype,Colorcode)     
select fd.MachineID,fd.MachineInterface,sttime,ndtime,datatype,ColorCode from MachineRunningStatus mr    
right outer join #CockpitData fd on fd.MachineInterface = mr.MachineInterface
where sttime<@currtime and isnull(ndtime,'1900-01-01')<@currtime
order by fd.MachineInterface
-----ER0464 --g: using MachineRunningStatus table instead of rawdata  


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

update #CockpitData set Remarks1 = T1.MCStatus from 
(select Machineid,
Case when Colorcode='White' then 'Stopped'
when Colorcode='Red' then 'Stopped'
when Colorcode='Green' then 'Running' end as MCStatus from #machineRunningStatus)T1
inner join #CockpitData on T1.MachineID = #CockpitData.MachineID
--ER0385 Till Here


---------------------------------- Added to handle Machine Status for Focas Machines ----------------------------------
Select @strsql=''
Select @strsql = @strsql + 'Insert into  #MachineOnlineStatus(Machineid,LastConnectionOKTime,LastConnectionFailedTime,LastPingFailedTime,LastPingOkTime,LastPLCCommunicationOK,LastPLCCommunicationFailed)
select MachineOnlineStatus.Machineid,Max(LastConnectionOKTime) as LastConnectionOKTime,Max(LastConnectionFailedTime) as LastConnectionFailedTime,
Max(LastPingFailedTime) as LastPingFailedTime,Max(LastPingOkTime)as LastPingOkTime,
MAX(LastPLCCommunicationOK),MAX(LastPLCCommunicationFailed) from MachineOnlineStatus
inner join machineinformation on machineinformation.machineid = MachineOnlineStatus.machineid 
inner join plantmachine on machineinformation.machineid=plantmachine.machineid
where machineinformation.TPMTrakEnabled=1 and machineinformation.DNCTransferEnabled=0 '
SET @strSql =  @strSql + @strMachine + @strPlantID
SET @strSql =  @strSql + ' group by MachineOnlineStatus.MachineID'
EXEC(@strSql)

update #MachineRunningStatus set PingStatus = T1.PingStatus from
(select Machineid,
Case when ISNULL(LastPingOkTime,'1900-01-01')>ISNULL(LastPingFailedTime,'1900-01-01') then 'OK' else 'NOT OK' end as PingStatus
from #MachineOnlineStatus
)T1 inner join #machineRunningStatus on T1.MachineID = #machineRunningStatus.MachineID

insert into #Focas_MachineRunningStatus(Machineid,Datatype,LastCycleTS,AlarmStatus,SpindleCycleTS,SpindleStatus,PowerOnOrOff)
select distinct machineinformation.machineid,Datatype,LastCycleTS,AlarmStatus,SpindleCycleTS,SpindleStatus,PowerOnOrOff from machineinformation 
left join Focas_MachineRunningStatus F on machineinformation.machineid=F.machineid
inner join plantmachine on machineinformation.machineid=plantmachine.machineid
where machineinformation.TPMTrakEnabled=1 and machineinformation.DNCTransferEnabled=1

update #Focas_MachineRunningStatus set Machinestatus=T.Machinestatus from
(select machineid, 
Case 
when AlarmStatus not in('Alarm','Emergency') and PowerOnOrOff=1 and Datatype=1 and datediff(second,LastCycleTS,@CurrTime)- @Type1Threshold>0 then 'Down'
when AlarmStatus not in('Alarm','Emergency') and PowerOnOrOff=1 and Datatype=2 then 'Down'
when AlarmStatus not in('Alarm','Emergency') and PowerOnOrOff=1 and Datatype=11 and SpindleStatus=2 and datediff(second,SpindleCycleTS,@CurrTime)- @Type40Threshold>0  and datediff(second,LastCycleTS,@CurrTime)>10 then 'ICD'
when AlarmStatus not in('Alarm','Emergency') and PowerOnOrOff=1 and Datatype=11 and datediff(second,LastCycleTS,@CurrTime)<=10 then 'Running'
when AlarmStatus not in('Alarm','Emergency') and PowerOnOrOff=1 and Datatype=11 and SpindleStatus=1 then 'Running'
when AlarmStatus in('Alarm') and PowerOnOrOff=1 then 'Alarm'
when AlarmStatus in('Emergency') and PowerOnOrOff=1 then 'Emergency'
when AlarmStatus not in('Alarm','Emergency') and PowerOnOrOff=1 and Datatype=1 and datediff(second,LastCycleTS,@CurrTime)<@Type1Threshold then 'Load Unload'
when AlarmStatus not in('Alarm','Emergency') and PowerOnOrOff=2 then 'Disconnected'
END as Machinestatus
from #Focas_MachineRunningStatus
)T inner join #Focas_MachineRunningStatus on T.Machineid=#Focas_MachineRunningStatus.Machineid

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

update #CockPitData set MachineLiveStatus=T.Machinestatus from
(select Machineid,machinestatus from #Focas_MachineRunningStatus
)T inner join #CockPitData on T.Machineid=#CockPitData.Machineid

update #CockPitData set MachineLiveStatusColor=T.Colorcode from
(select Status,Colorcode from Focas_MachineColorcode
)T inner join #CockPitData on T.Status=#CockPitData.MachineLiveStatus
---------------------------------- Added to handle Machine Status for Focas Machines ---------------------------------- 


--ER0417 Added From here

If @MarkedForRework='Y'
BEGIN

	Create table #MarkedForRework
	(
		MC nvarchar(50),
		Machineid nvarchar(50),
		Slno nvarchar(50),
		Qty int
	)



	Insert into #MarkedForRework(MC,Machineid,Slno,Qty)
	Select A.mc,#Cockpitdata.machineid,A.WorkOrderNumber,Count(*) from AutodataRejections A
	inner join Machineinformation M on A.mc=M.interfaceid
	inner join #Cockpitdata on #Cockpitdata.machineid=M.machineid 
	inner join Reworkinformation R on A.Rejection_code=R.Reworkinterfaceid
	inner join #shift S on convert(nvarchar(10),(A.RejDate),126)=S.shiftdate and A.RejShift=S.shiftid 
	where A.flag = 'MarkedforRework' and A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (S.shiftdate) and 
	Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
	group by A.mc,#Cockpitdata.machineid,A.WorkOrderNumber

	Update #MarkedForRework set Qty = T1.Qty from
	(Select M.Machineid,M.Slno,'0' as Qty from #MarkedForRework M 
	 inner join QualityInspectDetails QD on M.MC=QD.MachineId and M.Slno=QD.WorkOrderNo 
	 inner join #shift S on convert(nvarchar(10),(QD.Date),126)=S.shiftdate and QD.Shift=S.shiftname
	)T1 inner join #MarkedForRework on #MarkedForRework.Machineid=T1. Machineid and #MarkedForRework.Slno=T1.Slno

	Update #Cockpitdata set ReturnPerHour = 0

	Update #Cockpitdata set ReturnPerHour  = isnull(T1.MarkedForReworkQty,0)
	From
	( Select Machineid,Sum(Qty) as MarkedForReworkQty from #MarkedForRework group by Machineid
	)T1 inner join #Cockpitdata B on B.Machineid=T1.Machineid 

END
--ER0417 Added Till here


--ER0362 ADDED FROM HERE

--SELECT
--MachineID,
--ProductionEfficiency,
--AvailabilityEfficiency,
--OverAllEfficiency,
--Components,
--CN,
--UtilisedTime,
--TurnOver,
--dbo.f_FormatTime(UtilisedTime,@timeformat) as StrUtilisedTime,
--dbo.f_FormatTime(ManagementLoss,@timeformat) as ManagementLoss,
--dbo.f_FormatTime(DownTime,@timeformat) as DownTime,
--dbo.f_FormatTime(TotalTime,@timeformat) as TotalTime,
--ReturnPerHour,
--ReturnPerHourTOTAL,
--Remarks,
--PEGreen,
--PERed,
--AEGreen,
--AERed,
--OEGreen,
--OERed,
--@StartTime as StartTime,
--@EndTime as EndTime,
--MaxDownReason as MaxReasonTime
--FROM #CockpitData
--order by machineid asc

---ER0417 From here
--If @companyName = 'VISHWAKARMA'
--Begin
--
--	SELECT
--	MachineID,
--	ProductionEfficiency,
--	AvailabilityEfficiency,
--	QualityEfficiency, --ER0368
--	OverAllEfficiency,
--	--Components, --NR0097
--	Round(Components,2) as Components, --NR0097
--	RejCount, --ER0368
--	CN,
--	UtilisedTime,
--	TurnOver,
--	dbo.f_FormatTime(UtilisedTime,@timeformat) as StrUtilisedTime,
--	dbo.f_FormatTime(ManagementLoss,@timeformat) as ManagementLoss,
--	dbo.f_FormatTime(DownTime,@timeformat) as DownTime,
--	dbo.f_FormatTime(TotalTime,@timeformat) as TotalTime,
--	ReturnPerHour,
--	ReturnPerHourTOTAL,
--	case when Remarks = 'Machine Not In Production' then ' ' else Remarks end as Remarks,
--	PEGreen,
--	PERed,
--	AEGreen,
--	AERed,
--	OEGreen,
--	OERed,
--	QERed, --ER0368
--	QEGreen, --ER0368
--	@StartTime as StartTime,
--	@EndTime as EndTime,
--	MaxDownReason as MaxReasonTime
--	,Remarks1,  --ER0368
--	Remarks2  --ER0368
--	FROM #CockpitData
--	order by machineid asc
--END
--ELSE
--Begin
--	SELECT
--	MachineID,
--	ProductionEfficiency,
--	AvailabilityEfficiency,
--	QualityEfficiency, --ER0368
--	OverAllEfficiency,
--	--Components, --NR0097
--	Round(Components,2) as Components, --NR0097
--	RejCount, --ER0368
--	CN,
--	UtilisedTime,
--	TurnOver,
--	dbo.f_FormatTime(UtilisedTime,@timeformat) as StrUtilisedTime,
--	dbo.f_FormatTime(ManagementLoss,@timeformat) as ManagementLoss,
--	dbo.f_FormatTime(DownTime,@timeformat) as DownTime,
--	dbo.f_FormatTime(TotalTime,@timeformat) as TotalTime,
--	ReturnPerHour,
--	ReturnPerHourTOTAL,
--	Remarks,
--	PEGreen,
--	PERed,
--	AEGreen,
--	AERed,
--	OEGreen,
--	OERed,
--	QERed, --ER0368
--	QEGreen, --ER0368
--	@StartTime as StartTime,
--	@EndTime as EndTime,
--	MaxDownReason as MaxReasonTime
--	,Remarks1,  --ER0368
--	Remarks2  --ER0368
--	FROM #CockpitData
--	order by machineid asc
--END

----ER0362 ADDED TILL HERE
--If @companyName = 'VISHWAKARMA' and @MarkedForRework='N'
--Begin
--
--	SELECT
--	MachineID,
--	ProductionEfficiency,
--	AvailabilityEfficiency,
--	QualityEfficiency, --ER0368
--	OverAllEfficiency,
--	--Components, --NR0097
--	Round(Components,2) as Components, --NR0097
--	RejCount, --ER0368
--	CN,
--	UtilisedTime,
--	TurnOver,
--	dbo.f_FormatTime(UtilisedTime,@timeformat) as StrUtilisedTime,
--	dbo.f_FormatTime(ManagementLoss,@timeformat) as ManagementLoss,
--	dbo.f_FormatTime(DownTime,@timeformat) as DownTime,
--	dbo.f_FormatTime(TotalTime,@timeformat) as TotalTime,
--	ReturnPerHour,
--	ReturnPerHourTOTAL,
--	case when Remarks = 'Machine Not In Production' then ' ' else Remarks end as Remarks,
--	PEGreen,
--	PERed,
--	AEGreen,
--	AERed,
--	OEGreen,
--	OERed,
--	QERed, --ER0368
--	QEGreen, --ER0368
--	@StartTime as StartTime,
--	@EndTime as EndTime,
--	MaxDownReason as MaxReasonTime
--	,Remarks1,  --ER0368
--	Remarks2  --ER0368
--	FROM #CockpitData
--	order by machineid asc
--END
--ELSE If @companyName <> 'VISHWAKARMA' and @MarkedForRework='N'
--Begin
--	SELECT
--	MachineID,
--	ProductionEfficiency,
--	AvailabilityEfficiency,
--	QualityEfficiency, --ER0368
--	OverAllEfficiency,
--	--Components, --NR0097
--	Round(Components,2) as Components, --NR0097
--	RejCount, --ER0368
--	CN,
--	UtilisedTime,
--	TurnOver,
--	dbo.f_FormatTime(UtilisedTime,@timeformat) as StrUtilisedTime,
--	dbo.f_FormatTime(ManagementLoss,@timeformat) as ManagementLoss,
--	dbo.f_FormatTime(DownTime,@timeformat) as DownTime,
--	dbo.f_FormatTime(TotalTime,@timeformat) as TotalTime,
--	ReturnPerHour,
--	ReturnPerHourTOTAL,
--	Remarks,
--	PEGreen,
--	PERed,
--	AEGreen,
--	AERed,
--	OEGreen,
--	OERed,
--	QERed, --ER0368
--	QEGreen, --ER0368
--	@StartTime as StartTime,
--	@EndTime as EndTime,
--	MaxDownReason as MaxReasonTime
--	,Remarks1,  --ER0368
--	Remarks2  --ER0368
--	FROM #CockpitData
--	order by machineid asc
--END
--Else If @companyName <> 'VISHWAKARMA' and @MarkedForRework='Y'
--Begin
--	SELECT
--	MachineID,
--	ProductionEfficiency,
--	AvailabilityEfficiency,
--	QualityEfficiency, --ER0368
--	OverAllEfficiency,
--	--Components, --NR0097
--	Round(Components,2) as Components, --NR0097
--	RejCount, --ER0368
--	CN,
--	UtilisedTime,
--	TurnOver,
--	dbo.f_FormatTime(UtilisedTime,@timeformat) as StrUtilisedTime,
--	dbo.f_FormatTime(ManagementLoss,@timeformat) as ManagementLoss,
--	dbo.f_FormatTime(DownTime,@timeformat) as DownTime,
--	dbo.f_FormatTime(TotalTime,@timeformat) as TotalTime,
--	ReturnPerHour,
--	ReturnPerHourTOTAL,
--	Remarks,
--	PEGreen,
--	PERed,
--	AEGreen,
--	AERed,
--	OEGreen,
--	OERed,
--	QERed, --ER0368
--	QEGreen, --ER0368
--	@StartTime as StartTime,
--	@EndTime as EndTime,
--	MaxDownReason as MaxReasonTime
--	,Remarks1,  --ER0368
--	Remarks2  --ER0368
--	FROM #CockpitData
--	order by machineid asc
--END
--ER0362 ADDED TILL HERE
--ER0417 Added till here

--	UPDATE #CockpitData
--	SET 
--	DownTime=(DownTime-ManagementLoss)

	---ER0466 Commented and Added Below
--Update #CockpitData Set Lastcycletime = T1.LastCycle  from 
--(
--	Select M.Machineid,A.ndtime as LastCycle from 
--	(
--		Select mc,max(id) as idd from autodata where datatype=1 group by mc
--	)T inner join Autodata  A on A.mc=T.mc and A.id=T.idd inner join Machineinformation M on M.interfaceid=A.mc
--) T1 inner join #CockpitData on T1.MachineID = #CockpitData.MachineID 

Update #CockpitData Set Lastcycletime = T1.LastCycle  from 
(
	Select A.Machineid,A.Endtime as LastCycle from Autodata_MaxTime A
) T1 inner join #CockpitData on T1.MachineID = #CockpitData.machineinterface
---ER0466 Commented and Added 


---------------------------------------------ER0455 Logic For Ae Prediction Metso and ER0466 Logic Revised-------------------------------------------------------------  
Declare @PredictionForLongerCycles as nvarchar(50)  
select @PredictionForLongerCycles = ISNULL(Valueintext,'N') from CockpitDefaults where Parameter='PredictionForLongerCycles'  


If isnull(@PredictionForLongerCycles,'N')='Y'  
Begin  
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


  
Set @CurrTime = case when @CurrTime>@EndTime then @EndTime else @CurrTime end  
  
---Query to get Machinewise Last Record from Rawdata where Datatype in 11  
Insert into #machineRunningStatus(MachineID,MachineInterface,AutodataMaxtime,sttime,DataType,Comp,Opn,Totaltime,Downtime,UT)  
select fd.MachineID,fd.MachineInterface,A.Endtime,case when sttime<@StartTime then @StartTime else sttime end,datatype,comp,opn,0,0,0 from rawdata  
inner join (select mc,max(slno) as slno from rawdata WITH (NOLOCK)   
inner join Autodata_maxtime A on rawdata.mc=A.machineid where (Rawdata.sttime>A.Endtime and Rawdata.sttime<@currtime) and rawdata.datatype=11 group by mc  ) t1   
on t1.mc=rawdata.mc and t1.slno=rawdata.slno  
inner join Autodata_maxtime A on rawdata.mc=A.machineid  
right outer join (select distinct machineid,MachineInterface from #CockpitData) fd on fd.MachineInterface = rawdata.mc  
where (Rawdata.sttime>A.Endtime and Rawdata.sttime<@currtime) and rawdata.datatype=11   
order by rawdata.mc  

IF (Select isnull(valueintext2,'N') from ShopDefaults where Parameter='Cockpit_RunningCycleUT')='Y'
Begin
Update #machineRunningStatus set UT=ISNULL(T1.UT,0),Downtime=ISNULL(T1.Dt,0) from  
(Select MachineInterface,case when AutodataMaxtime<sttime then (O.cycletime-O.machiningtime) end as UT,  
case when dateadd(second,(O.cycletime-O.machiningtime),AutodataMaxtime)<sttime then datediff(second,dateadd(second,(O.cycletime-O.machiningtime),AutodataMaxtime),sttime) end as DT   
from #MachineRunningStatus  
inner join machineinformation M on #MachineRunningStatus.MachineInterface=M.InterfaceID   
inner join componentinformation C on C.InterfaceID=#MachineRunningStatus.Comp  
inner join componentoperationpricing O on O.componentid=C.componentid and M.machineid=O.machineid and   
#MachineRunningStatus.Opn=O.InterfaceID)T1 inner join #machineRunningStatus on T1.MachineInterface=#machineRunningStatus.MachineInterface  
End
 
Update #machineRunningStatus set ndtime = case when T1.Endtime>@CurrTime then @CurrTime else T1.Endtime end,LastRecorddatatype=T1.LastRecorddatatype from  
(select rawdata.mc,rawdata.datatype,case when rawdata.datatype=40 then dateadd(second,@type40threshold,rawdata.sttime)  
when rawdata.datatype=42 then dateadd(second,@type40threshold,rawdata.Ndtime)  
when rawdata.datatype=41 then rawdata.sttime  
when rawdata.datatype=11 then dateadd(second,@type11threshold,rawdata.sttime)   
else @CurrTime end as endtime,  
case when rawdata.datatype in(40,41,42) then RawData.DataType   
else 11 end as LastRecorddatatype from  
 (  
  select rawdata.mc,max(rawdata.slno) as slno from rawdata   
  inner join #machineRunningStatus M on M.MachineInterface=rawdata.mc  
  where rawdata.datatype in(40,41,42,11) and (rawdata.sttime>=M.sttime and ISNULL(Rawdata.ndtime,Rawdata.sttime)<@currtime)  group by rawdata.mc  
 )T1  inner join rawdata on rawdata.slno=t1.slno  
 inner join #machineRunningStatus M on M.MachineInterface=rawdata.mc  
)T1 inner join #machineRunningStatus on #machineRunningStatus.MachineInterface=T1.mc 
  
update  #machineRunningStatus set ndtime=@CurrTime,LastRecorddatatype=11 where ndtime IS NULL  
 
update #machineRunningStatus set UT=Datediff(second,sttime,ndtime),Totaltime=Datediff(second,sttime,ndtime)  --for L&T

Insert into #AE(mc,dcode,sttime,ndtime,Loadunload,CycleStart,CycleEnd,TotalTime,UT,Downtime,PDT,ManagementLoss,MLDown,id,datatype)  
Select M.MachineInterface,A.dcode,A.sttime,A.ndtime,A.Loadunload,M.sttime,M.ndtime,M.Totaltime,0,0,0,0,0,A.id,A.datatype from Autodata_ICD A  
right outer join #machineRunningStatus M On A.mc=M.MachineInterface  
Where A.sttime>=M.sttime and A.ndtime<=M.ndtime  
and M.datatype='11' and A.datatype='42' Order by A.mc,A.sttime  

insert into #PDT(machine,StartTime)
select MachineInterface,sttime from #MachineRunningStatus where DataType=11

insert into #PDT(machine,StartTime)
select mc,sttime from #AE

insert into #PDT(machine,StartTime)
select mc,ndtime from #AE 

insert into #PDT(machine,StartTime)
select mc,CycleEnd from #AE where CycleEnd>(select max(ndtime) from #AE)

--insert into #Timeinfo(machine,StartTime,endtime,ISICD)
--select t1.machine,t1.StartTime,LEAD(t1.StartTime)OVER(ORDER BY starttime) as endtime,0 from #PDT t1

;WITH cteMain
AS( SELECT machine, StartTime, ROW_NUMBER() OVER (ORDER BY StartTime) AS sn FROM #PDT )

insert into #Timeinfo(machine,StartTime,endtime,ISICD)
SELECT m.machine,m.StartTime,sLead.StartTime AS endtime,0 FROM cteMain AS m LEFT OUTER JOIN cteMain AS sLead ON sLead.sn = m.sn+1

update #Timeinfo set ISICD=1 where endtime in(select ndtime from #AE)
  
IF EXISTS(select * from #AE where datatype=42)  
Begin  
  
--update #machineRunningStatus set Totaltime=Datediff(second,sttime,ndtime)   --for L&T
  
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
 SELECT MachineInformation.Machineid,MachineInformation.InterfaceID,  
  CASE When StartTime<#AE.CycleStart Then #AE.CycleStart Else StartTime End As StartTime,  
  CASE When EndTime>#AE.CycleEnd Then #AE.CycleEnd Else EndTime End As EndTime  
 FROM PlannedDownTimes inner join MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID  
 inner join (Select distinct mc,CycleStart,CycleEnd from #AE) #AE on #AE.mc = MachineInformation.InterfaceID  
 WHERE PDTstatus =1 and(  
 (StartTime >= #AE.CycleStart AND EndTime <=#AE.CycleEnd)  
 OR ( StartTime < #AE.CycleStart  AND EndTime <= #AE.CycleEnd AND EndTime > #AE.CycleStart )  
 OR ( StartTime >= #AE.CycleStart   AND StartTime <#AE.CycleEnd AND EndTime > #AE.CycleEnd )  
 OR ( StartTime < #AE.CycleStart  AND EndTime > #AE.CycleEnd)) '  
SET @strSql =  @strSql + @strMachine + @StrTPMMachines + ' ORDER BY MachineInformation.Machineid,PlannedDownTimes.StartTime'  
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
  --UT = ISNULL(UT,0)+ (ISNULL(Totaltime,0)-ISNULL(T1.down,0)), --For L&T
  UT = (ISNULL(UT,0)-ISNULL(T1.down,0)), --For L&T
  #MachineRunningStatus.PDT=ISNULL(#MachineRunningStatus.PDT,0)+ ISNULL(T1.PDT,0) from  
  (Select mc,Sum(ManagementLoss) as ML,Sum(Downtime) as Down,SUM(PDT) as PDT from #AE Group By mc)T1  
  inner join #MachineRunningStatus on T1.mc = #MachineRunningStatus.machineinterface  
  
END  

 --Update #MachineRunningStatus set DownTime = Isnull(#MachineRunningStatus.DownTime,0) + Isnull(t2.DownTime,0),StartTime=t2.endtime  
 --Update #MachineRunningStatus set UT = Isnull(#MachineRunningStatus.UT,0) + Isnull(t2.DownTime,0),StartTime=t2.endtime  
 --from (  
 -- Select mrs.MachineID,mrs.datatype,case when t1.endtime<@CurrTime then datediff(second,t1.endtime,@CurrTime) else 0 end as Downtime,case when t1.endtime<@CurrTime then t1.endtime else @CurrTime end as endtime  
 -- from #machineRunningStatus mrs inner join  
 -- (  
 --  Select mrs.MachineID,case when mrs.LastRecorddatatype=11 then dateadd(second,@Type11Threshold,sttime) else mrs.ndtime end as endtime   
 --  from #machineRunningStatus mrs  
 --  Inner join Machineinformation M on M.interfaceID = mrs.MachineInterface  
 -- ) as t1 on t1.machineID = mrs.machineID   
 --) as t2 inner join #MachineRunningStatus on t2.MachineID = #MachineRunningStatus.MachineID   


 --If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'   
 --BEGIN  
 ---- update #MachineRunningStatus set Downtime = Isnull(#MachineRunningStatus.Downtime,0) - isnull(T2.pdt,0),#MachineRunningStatus.PDT=ISNULL(#MachineRunningStatus.PDT,0)+isnull(T2.pdt,0)
 -- update #MachineRunningStatus set UT = Isnull(#MachineRunningStatus.UT,0) - isnull(T2.pdt,0),#MachineRunningStatus.PDT=ISNULL(#MachineRunningStatus.PDT,0)+isnull(T2.pdt,0)
 -- from  
 -- (  
 -- Select T1.machineid,sum(datediff(ss,T1.StartTime,t1.EndTime)) as pdt   
 -- from   
 -- (  
 --  select fD.machineid,  
 --  Case when  fd.starttime <= pdt.StartTime then pdt.StartTime else  fd.starttime End as StartTime,  
 --  Case when @Currtime >= pdt.EndTime then pdt.EndTime else @Currtime End as EndTime  
 --  From Planneddowntimes pdt  
 --  inner join #machineRunningStatus fD on fd.machineid=Pdt.machine  
 --  inner join #AE on fd.MachineInterface=#AE.mc  
 --  where PDTstatus = 1  and   
 --  ((pdt.StartTime >= fd.starttime and pdt.EndTime <= @Currtime)or  
 --  (pdt.StartTime < fd.starttime and pdt.EndTime > fd.starttime and pdt.EndTime <=@Currtime)or  
 --  (pdt.StartTime >= fd.starttime and pdt.StartTime <@Currtime and pdt.EndTime >@Currtime) or  
 --  (pdt.StartTime <  fd.starttime and pdt.EndTime >@Currtime))  
 -- )T1  group by T1.machineid   
 -- )T2 inner join #MachineRunningStatus on #MachineRunningStatus.machineid=t2.machineid   
 --end  

 Update #MachineRunningStatus set UT = Isnull(#MachineRunningStatus.UT,0) + Isnull(t2.UT,0),StartTime=t2.endtime ,
 Downtime = Isnull(#MachineRunningStatus.Downtime,0) + Isnull(t2.Downtime,0)
from (  
Select mrs.MachineID,mrs.datatype,
case when t1.endtime<@CurrTime and (LastRecorddatatype in(40,42,11)) then datediff(second,t1.endtime,@CurrTime) else 0 end as Downtime,
case when t1.endtime<@CurrTime and (LastRecorddatatype=41) then datediff(second,t1.endtime,@CurrTime) else 0 end as UT,
case when t1.endtime<@CurrTime then t1.endtime else @CurrTime end as endtime  
from #machineRunningStatus mrs inner join  
(  
Select mrs.MachineID,case when mrs.LastRecorddatatype=11 then dateadd(second,@Type11Threshold,sttime) else mrs.ndtime end as endtime   
from #machineRunningStatus mrs  
Inner join Machineinformation M on M.interfaceID = mrs.MachineInterface  
) as t1 on t1.machineID = mrs.machineID   
) as t2 inner join #MachineRunningStatus on t2.MachineID = #MachineRunningStatus.MachineID   


If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'   
BEGIN  

  update #MachineRunningStatus set UT = Isnull(#MachineRunningStatus.UT,0) - isnull(T2.PPDT,0),#MachineRunningStatus.PDT=ISNULL(#MachineRunningStatus.PDT,0)+isnull(T2.PPDT,0)
  from  
  (  
   select M.machineid,  
	sum(CASE  
	WHEN (T.Starttime >= pdt.Starttime AND T.Endtime <=pdt.EndTime)  THEN DateDiff(second,T.Starttime,T.EndTime ) 
	WHEN ( T.Starttime < pdt.Starttime AND T.Endtime <= pdt.EndTime  AND T.Endtime > pdt.Starttime ) THEN DateDiff(second,pdt.Starttime,T.Endtime)  
	WHEN ( T.Starttime >= pdt.Starttime AND T.Starttime <pdt.EndTime  AND T.Endtime > pdt.EndTime  ) THEN DateDiff(second,T.Starttime,pdt.EndTime )  
	WHEN ( T.Starttime < pdt.Starttime AND T.Endtime > pdt.EndTime ) THEN DateDiff(second,pdt.Starttime,pdt.EndTime )  
	END ) as PPDT  
   From Planneddowntimes pdt  
   inner join #machineRunningStatus M on M.machineid=Pdt.machine  
   inner join #Timeinfo T on M.MachineInterface=T.machine  
   where PDTstatus = 1 and  (T.ISICD=0 and T.endtime IS NOT NULL) and
   ((T.Starttime >= pdt.Starttime AND T.Endtime <=pdt.EndTime) or  
	(T.Starttime < pdt.Starttime AND T.Endtime <= pdt.EndTime  AND T.Endtime > pdt.Starttime)OR
	(T.Starttime >= pdt.Starttime AND T.Starttime <pdt.EndTime  AND T.Endtime > pdt.EndTime) OR   
	(T.Starttime < pdt.Starttime AND T.Endtime > pdt.EndTime))  
  group by M.machineid   
  )T2 inner join #MachineRunningStatus on #MachineRunningStatus.machineid=t2.machineid   

  update #MachineRunningStatus set UT = Isnull(#MachineRunningStatus.UT,0) - isnull(T2.PPDT,0),#MachineRunningStatus.PDT=ISNULL(#MachineRunningStatus.PDT,0)+isnull(T2.PPDT,0)
  from  
  (  
   select M.machineid,  
	sum(CASE  
	WHEN (T.Starttime >= pdt.Starttime AND T.Endtime <=pdt.EndTime)  THEN DateDiff(second,T.Starttime,T.EndTime ) 
	WHEN ( T.Starttime < pdt.Starttime AND T.Endtime <= pdt.EndTime  AND T.Endtime > pdt.Starttime ) THEN DateDiff(second,pdt.Starttime,T.Endtime)  
	WHEN ( T.Starttime >= pdt.Starttime AND T.Starttime <pdt.EndTime  AND T.Endtime > pdt.EndTime  ) THEN DateDiff(second,T.Starttime,pdt.EndTime )  
	WHEN ( T.Starttime < pdt.Starttime AND T.Endtime > pdt.EndTime ) THEN DateDiff(second,pdt.Starttime,pdt.EndTime )  
	END ) as PPDT  
   From Planneddowntimes pdt  
   inner join #machineRunningStatus M on M.machineid=Pdt.machine  
   inner join #Timeinfo T on M.MachineInterface=T.machine  
   where PDTstatus = 1 and  (T.ISICD=0 and T.endtime IS NULL) and (M.LastRecorddatatype=41) and
   ((T.Starttime >= pdt.Starttime AND T.Endtime <=pdt.EndTime) or  
	(T.Starttime < pdt.Starttime AND T.Endtime <= pdt.EndTime  AND T.Endtime > pdt.Starttime)OR
	(T.Starttime >= pdt.Starttime AND T.Starttime <pdt.EndTime  AND T.Endtime > pdt.EndTime) OR   
	(T.Starttime < pdt.Starttime AND T.Endtime > pdt.EndTime))  
  group by M.machineid   
  )T2 inner join #MachineRunningStatus on #MachineRunningStatus.machineid=t2.machineid   
end  

 If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'   
BEGIN  
  update #MachineRunningStatus set Downtime = Isnull(#MachineRunningStatus.Downtime,0) - isnull(T2.PPDT,0),#MachineRunningStatus.PDT=ISNULL(#MachineRunningStatus.PDT,0)+isnull(T2.PPDT,0)
  from  
  (  
   select M.machineid,  
	sum(CASE  
	WHEN (T.Starttime >= pdt.Starttime AND T.Endtime <=pdt.EndTime)  THEN DateDiff(second,T.Starttime,T.EndTime ) 
	WHEN ( T.Starttime < pdt.Starttime AND T.Endtime <= pdt.EndTime  AND T.Endtime > pdt.Starttime ) THEN DateDiff(second,pdt.Starttime,T.Endtime)  
	WHEN ( T.Starttime >= pdt.Starttime AND T.Starttime <pdt.EndTime  AND T.Endtime > pdt.EndTime  ) THEN DateDiff(second,T.Starttime,pdt.EndTime )  
	WHEN ( T.Starttime < pdt.Starttime AND T.Endtime > pdt.EndTime ) THEN DateDiff(second,pdt.Starttime,pdt.EndTime )  
	END ) as PPDT  
   From Planneddowntimes pdt  
   inner join #machineRunningStatus M on M.machineid=Pdt.machine  
   inner join #Timeinfo T on M.MachineInterface=T.machine  
   where PDTstatus = 1 and (T.ISICD=0 and T.endtime IS NULL) and (M.LastRecorddatatype in(11,40,42)) and 
   ((T.Starttime >= pdt.Starttime AND T.Endtime <=pdt.EndTime) or  
	(T.Starttime < pdt.Starttime AND T.Endtime <= pdt.EndTime  AND T.Endtime > pdt.Starttime)OR
	(T.Starttime >= pdt.Starttime AND T.Starttime <pdt.EndTime  AND T.Endtime > pdt.EndTime) OR   
	(T.Starttime < pdt.Starttime AND T.Endtime > pdt.EndTime))  
  group by M.machineid   
  )T2 inner join #MachineRunningStatus on #MachineRunningStatus.machineid=t2.machineid   
 end  

 Update #CockpitData SET RunningCycleUT= isnull(RunningCycleUT,0)+isnull(T.UT,0),RunningCycleDT=ISNULL(RunningCycleDT,0)+ISNULL(T.DT,0),  
 RunningCycleML=ISNULL(#CockpitData.RunningCycleML,0)+ISNULL(T.ManagementLoss,0),RunningCyclePDT=ISNULL(RunningCyclePDT,0)+ISNULL(T.PDT,0) from  
 (  
 Select MachineInterface as mc,ISNULL(Downtime,0) as DT,ISNULL(UT,0) as UT,IsNULL(ManagementLoss,0) as ManagementLoss,ISNULL(PDT,0) as PDT from #MachineRunningStatus  
 )T inner join #CockpitData on #CockpitData.MachineInterface=T.mc  
  
END  

  
    

UPDATE #CockpitData  
SET 
--TotalTime = DateDiff(second, @StartTime, case when @endtime<@CurrTime then @endtime else @currtime end), --SV
RunningCycleAE = ((RunningCycleUT)/(RunningCycleUT + RunningCycleDT - RunningCycleML))*100 
where (RunningCycleUT + RunningCycleDT - RunningCycleML)>0

--SV 
Select @endtime = case when @endtime<@CurrTime then @endtime else @currtime end


UPDATE #CockpitData
SET
	TotalTime = DateDiff(second, @StartTime, case when T.Endtime IS NULL Then @EndTime else T.Endtime END) ,
	EndTimeForPDTCal = (case when T.Endtime IS NULL Then @EndTime else T.Endtime END)
	from
(Select mc,	CASE	
	when max(ndtime)>@starttime and max(ndtime)<@endtime then Max(ndtime)
	when max(ndtime)<@starttime and max(ndtime)<@endtime then @EndTime
	WHEN max(ndtime)>@starttime and max(ndtime)>@EndTime then @EndTime
	END as Endtime from #T_autodata Autodata
	Where ((autodata.msttime >= @starttime  AND autodata.ndtime <=@Endtime)
	OR ( autodata.msttime < @starttime  AND autodata.ndtime <= @Endtime AND autodata.ndtime > @starttime )
	OR ( autodata.msttime >= @starttime   AND autodata.msttime <@Endtime AND autodata.ndtime > @Endtime )
	OR ( autodata.msttime < @starttime  AND autodata.ndtime > @Endtime))
	Group by mc)T inner join #CockPitData on #CockPitData.MachineInterface=T.mc

UPDATE #CockpitData  
SET 
TotalTime = DateDiff(second, @StartTime, @endtime) Where ISNULL(TotalTime,0)=0




If (SELECT ValueInText From CockpitDefaults Where Parameter ='DisplayTTFormat')='Display TotalTime - Less PDT' 
BEGIN
----------------------------------- DR0330 From Here -----------------------------------------------------
----	UPDATE #CockpitData SET TotalTime = Totaltime -ISNULL(#PLD.pPlannedDT,0)- isnull(#PLD.IPlannedDT,0)- ISNULL(#PLD.dPlannedDT,0)
--	UPDATE #CockpitData SET TotalTime = Totaltime -ISNULL(#PLD.pPlannedDT,0)-ISNULL(#PLD.dPlannedDT,0) + isnull(#PLD.IPlannedDT,0)
--	From #CockpitData Inner Join #PLD on #PLD.Machineid=#CockpitData.Machineid	

--	UPDATE #CockpitData SET TotalTime = Case when Remarks<>'Machine Not In Production' then Totaltime - isnull(T1.PDT,0) else isnull(T1.PDT,0) End
	UPDATE #CockpitData SET TotalTime = Totaltime - isnull(T1.PDT,0) 
	from
	(Select Machine,SUM(datediff(S,Starttime,endtime))as PDT from Planneddowntimes P
	inner join #CockPitData C on P.Machine=C.MachineID
	 --where starttime>=@starttime and endtime<=@endtime group by machine)T1
	 where starttime>=@starttime and endtime<=C.EndTimeForPDTCal group by machine)T1
	 Inner Join #CockpitData on T1.Machine=#CockpitData.Machineid WHERE UtilisedTime <> 0	
----------------------------------- DR0330 Till Here -----------------------------------------------------
End


--NR0090 Till Here

-- Calculate efficiencies  
--If ISNULL(@PredictionForLongerCycles,'N') = 'Y'  
--BEGIN  
--UPDATE #CockpitData SET ProductionEfficiency = T1.Pe From  
--(Select #CockPitData.MachineInterface,  
--case when M.UT>0 then ((#CockPitData.CN+M.UT)/(#CockPitData.UtilisedTime+M.UT)) else CN/Utilisedtime end as pe from #MachineRunningStatus M  
--right outer join #CockPitData on M.MachineInterface=#CockPitData.MachineInterface  
--)T1 inner join #CockpitData on #CockpitData.MachineInterface=T1.MachineInterface  
--END  
  
-- Calculate efficiencies  
--UPDATE #CockpitData  
--SET  
-- --ProductionEfficiency = (CN/UtilisedTime) ,  
-- ProductionEfficiency = Case when ISNULL(@PredictionForLongerCycles,'N') = 'Y' then ProductionEfficiency else (CN/UtilisedTime) end,  
-- AvailabilityEfficiency = (UtilisedTime)/(UtilisedTime + DownTime - ManagementLoss)  
--WHERE UtilisedTime <> 0  
--  
--UPDATE #CockpitData  
--SET  
-- OverAllEfficiency = (ProductionEfficiency * AvailabilityEfficiency * (case when ISNULL(QualityEfficiency,0)=0 then 1 else QualityEfficiency end) )*100,  
-- ProductionEfficiency = ProductionEfficiency * 100,  
-- AvailabilityEfficiency = AvailabilityEfficiency * 100,  
-- QualityEfficiency = QualityEfficiency*100  
--------------------------------------------Logic For Ae Prediction Metso--------------------------------------------------------  
  
--------------------------------------------- --ER0455 Logic For Metso -------------------------------------------------------------------------  


--Query to get Machinewise Spindle records for each CycleStart and CycleEnd  
Delete From #machineRunningStatus  

create table #rawdata
(
slno nvarchar(50),
sttime datetime,
datatype nvarchar(50),
mc nvarchar(50),
comp nvarchar(50),
opn nvarchar(50)
)

create table #Running
(
mc nvarchar(50),
slno nvarchar(50)
)


insert into #rawdata(slno,sttime,datatype,mc,comp,opn)
select SlNo,Sttime,DataType,MC,comp,opn from rawdata
inner join Autodata_maxtime A on rawdata.mc=A.machineid  
where (Rawdata.sttime>A.Endtime and Rawdata.sttime<@currtime) and rawdata.datatype=11   



--insert into #Running(mc,slno)
--select mc,max(slno) as slno from rawdata WITH (NOLOCK)   
--inner join Autodata_maxtime A on rawdata.mc=A.machineid where (Rawdata.sttime>A.Endtime and Rawdata.sttime<@currtime) and rawdata.datatype=11 group by mc
  

--  Insert into #machineRunningStatus(MachineID,MachineInterface,sttime,ndtime,DataType,Downtime,comp,Opn)  
--select fd.MachineID,fd.MachineInterface,case when sttime<@StartTime then @StartTime else sttime end,@currtime,datatype,datediff(second,sttime,@currtime),comp,opn from rawdata  
--inner join (select mc,slno as slno from #Running) t1 
--on t1.mc=rawdata.mc and t1.slno=rawdata.slno  
--inner join Autodata_maxtime A on rawdata.mc=A.machineid  
--right outer join (select distinct machineid,MachineInterface from #CockpitData) fd on fd.MachineInterface = rawdata.mc  
--where (Rawdata.sttime>A.Endtime and Rawdata.sttime<@currtime) and rawdata.datatype=11   
--order by rawdata.mc   

---Query to get Machinewise Last Record from Rawdata where Datatype in 1,2,11  

Insert into #machineRunningStatus(MachineID,MachineInterface,sttime,ndtime,DataType,Downtime,comp,Opn)  
select fd.MachineID,fd.MachineInterface,case when sttime<@StartTime then @StartTime else sttime end,@currtime,datatype,datediff(second,sttime,@currtime),comp,opn from #rawdata  
inner join (select mc,max(slno) as slno from rawdata WITH (NOLOCK)   
inner join Autodata_maxtime A on rawdata.mc=A.machineid where (Rawdata.sttime>A.Endtime and Rawdata.sttime<@currtime) and rawdata.datatype=11 group by mc) t1 
on t1.mc=#rawdata.mc and t1.slno=#rawdata.slno  
right outer join (select distinct machineid,MachineInterface from #CockpitData) fd on fd.MachineInterface = #rawdata.mc  
order by #rawdata.mc   




--Query to get Machinewise Spindle records for each CycleStart and CycleEnd  
select R.slno,R.mc,R.sttime,R.ndtime,R.datatype INTO #Spindle from rawdata R  
inner join #machineRunningStatus M on M.MachineInterface=R.mc  
where R.sttime>=M.sttime and R.sttime<=M.ndtime  
and R.datatype in (40,41) order by R.mc,R.sttime  

--Query to get Spindlestart ans SpindleEnd for each Machine  
--Select S.mc,Min(S.Sttime) as SpindleStart,Max(S1.Sttime) as SpindleEnd INTO #TempSpindle from #Spindle S  
--inner join #Spindle S1 on S.mc=S1.mc  
--Where S.Slno<S1.Slno and S.datatype='41' and S1.Datatype='40'  
--Group by S.mc  
--Query to get Spindlestart ans SpindleEnd for each Machine  

Select S.mc,S.Sttime as SpindleStart,Min(S1.Sttime) as SpindleEnd INTO #TempSpindle from #Spindle S  
inner join #Spindle S1 on S.mc=S1.mc  
Where S.Slno<S1.Slno and S.datatype='41' and S1.Datatype='40'  
Group by S.mc,S.Sttime 

--Query to Get Finaldeatils into Temap table  
Select M.MachineInterface as mc,M.sttime,M.ndtime,M.datatype,M.ColorCode,SUM(Datediff(Second,T.SpindleStart,T.SpindleEnd)) as Spindleruntime,M.comp,M.opn INTO #SpindleDeatils  
From #TempSpindle T Right Outer join #machineRunningStatus M on M.MachineInterface=T.mc  
Group by M.MachineInterface,M.sttime,M.ndtime,M.datatype,M.ColorCode,M.comp,M.opn  


--Updating data to #cockpit table  
--Update #CockpitData Set LastCycleCO=T1.Comp,
--LastCycleCompDescription=T1.Compdes,LastCycleOperation=T1.Opn,LastCycleOpnDescription=T1.Opndes,
--LastCycleStart=T1.sttime,LastCycleSpindleRunTime=T1.Spindleruntime,  
--LastCycleDatatype=T1.datatype from   
--(  
--Select A.mc,CASE when A.datatype=11 then A.sttime else '' end AS STTIME,A.datatype,A.Spindleruntime,
----CO.Componentid + ' <' + cast(CO.Operationno as nvarchar(50)) + '>'  as CO 
--C.Componentid as Comp,cast(C.description as nvarchar(50))  as Compdes,
--cast(CO.operationno as nvarchar(50)) as Opn,cast(CO.description as nvarchar(50)) as Opndes
--From #SpindleDeatils A  
--inner join Machineinformation on A.mc=Machineinformation.interfaceid    
--left outer join Componentinformation C on A.comp=C.interfaceid    
--left outer join Componentoperationpricing CO on A.opn=CO.interfaceid    
--and Machineinformation.Machineid=CO.Machineid and C.Componentid=CO.Componentid    
--) T1 inner join #CockpitData on T1.mc = #CockpitData.MachineInterface   

--Updating data to #cockpit table  
Update #CockpitData Set 
LastCycleStart=T1.sttime,LastCycleSpindleRunTime=T1.Spindleruntime from   
(  
Select A.mc,CASE when A.datatype=11 then A.sttime else '' end AS STTIME,A.datatype,A.Spindleruntime
From #SpindleDeatils A  
inner join Machineinformation on A.mc=Machineinformation.interfaceid    
) T1 inner join #CockpitData on T1.mc = #CockpitData.MachineInterface   

Update #CockpitData Set LastCycleCO=T1.Comp,
LastCycleCompDescription=T1.Compdes,LastCycleOperation=T1.Opn,LastCycleOpnDescription=T1.Opndes,
LastCycleDatatype=T1.datatype,RunningCycleStdTime=T1.Cycletime from   
(  
Select A.mc,rawdata.datatype,C.Componentid as Comp,cast(C.description as nvarchar(50))  as Compdes,
cast(CO.operationno as nvarchar(50)) as Opn,cast(CO.description as nvarchar(50)) as Opndes,Co.cycletime
From Rawdata 
inner join (select mc,max(slno) as slno from rawdata WITH (NOLOCK)   
where Rawdata.sttime<@currtime and rawdata.datatype in(11,1,2,22,42) group by mc
) A  on A.mc=rawdata.mc and A.slno=rawdata.slno  
inner join Machineinformation on A.mc=Machineinformation.interfaceid    
left outer join Componentinformation C on rawdata.comp=C.interfaceid    
left outer join Componentoperationpricing CO on rawdata.opn=CO.interfaceid    
and Machineinformation.Machineid=CO.Machineid and C.Componentid=CO.Componentid    
) T1 inner join #CockpitData on T1.mc = #CockpitData.MachineInterface   
-----------------------------------------------ER0455 Logic For Metso -------------------------------------------------------------------------  


-----------------------------------------------------------------------------------------SpindleRuntime logic starts---------------------------------------------------------------------------------------

if (select isnull(valueintext,'N') from ShopDefaults where Parameter='EnableSpindleCycleTime')='Y'
BEGIN

	Select @strSql=''
	Select @strSql=@strSql+
	'insert into #spindledata(Mc,StartTime,Datatype)
	select R.Machine,R.Starttime,R.RecordType  from AutodataDetails R 
	inner join machineinformation on R.Machine=machineinformation.InterfaceID'
	Select @strsql=@strsql+ ' where (R.Starttime>=''' + Convert(Nvarchar(20),@StartTime,120) +''' and R.Starttime<= ''' + Convert(Nvarchar(20),@Endtime,120) +''')'
	Select @strSql = @strSql + @strMachine
	Select @strsql=@strsql+ ' and R.RecordType in (40,41) order by R.Machine,R.Starttime'
	exec(@strsql)

	---Logic to Predict Endtime, If machinewise last record is 41 then predict 41 Starttime to @Endtime as spindle running
	insert into #spindledata(Mc,StartTime,Datatype)
	Select mc,@EndTime,40 from
	(select s1.mc,s1.starttime,s1.datatype from #spindledata S1 
	inner join (Select mc,MAX(starttime) as StartTime from #spindledata group by mc)S2 on S1.mc=S2.mc and S1.StartTime=S2.StartTime
	)T where T.Datatype=41 and T.starttime<@EndTime

	---Logic to Predict starttime, If machinewise first record is 40 then predict @starttime to 40-->Starttime as spindle running
	insert into #spindledata(Mc,StartTime,Datatype)
	Select mc,@StartTime,41 from
	(select s1.mc,s1.starttime,s1.datatype from #spindledata S1 
	inner join (Select mc,min(starttime) as StartTime from #spindledata group by mc)S2 on S1.mc=S2.mc and S1.StartTime=S2.StartTime
	)T where T.Datatype=40 and T.StartTime<@StartTime

	insert into #TempSpindleData(Mc,SpindleStart,SpindleEnd)
	Select S.mc,S.StartTime as SpindleStart,Min(S1.StartTime) as SpindleEnd from #spindledata S  
	inner join #spindledata S1 on S.mc=S1.mc  
	Where S.StartTime<S1.StartTime and S.datatype='41' and S1.Datatype='40' 
	Group by S.mc,S.StartTime 

	insert into #SpindleDataDetails(Mc,SpindleStart,SpindleEnd,SpindleCycleTime)
	Select  t.Mc,t.SpindleStart,t.SpindleEnd,Datediff(Second,T.SpindleStart,T.SpindleEnd) as SpindleCycleTime
	From #TempSpindleData T  
	Group by t.mc ,t.SpindleStart,t.SpindleEnd


	update #CockPitData set SpindleCycleTime=(t1.spindlecycle)
	from
	(select distinct s1.mc,sum(s1.SpindleCycleTime) as spindlecycle  from #SpindleDataDetails s1
	inner join #CockPitData c1 on c1.MachineInterface=s1.Mc
	group by s1.Mc
	) t1 inner join #CockPitData on #CockPitData.MachineInterface=t1.Mc

end
-----------------------------------------------------------------------------------------SpindleRuntime logic ends---------------------------------------------------------------------------------------


   ---Query to get Machinewise Last Record from Rawdata where Datatype in 11,1,2,22,42 for peekay  
Update #CockpitData Set MachineStatus=T1.DownStatus From
(select RawData.mc,
Case when rawdata.datatype in(11,41) then 'Cycle Started'
When rawdata.datatype=1 then 'Cycle Ended'
When rawdata.datatype in(22,42) then  'Stopped ' + D.Downid 
When rawdata.datatype in(2,40) then 'Stopped' 
END as DownStatus from Rawdata
inner join (select mc,max(slno) as slno from rawdata WITH (NOLOCK)   
where Rawdata.sttime<@currtime and rawdata.datatype in(11,1,2,22,42) group by mc) t1 on t1.mc=rawdata.mc and t1.slno=rawdata.slno  
Left Outer join Downcodeinformation D on rawdata.splstring2=D.interfaceid
) T1 inner join #CockpitData on T1.mc = #CockpitData.MachineInterface  
  ---Query to get Machinewise Last Record from Rawdata where Datatype in 11,1,2,22,42 for peekay  

Update #CockpitData Set LastCompletedDowntime = T1.LastDown from 
(
Select M.Machineid,ISNULL(D.Downid,'Unknown') + ' ['+ case when A.ndtime<>'' then Substring(CONVERT(varchar,A.ndtime,106),1,2)+ '-' +  
	substring(CONVERT(varchar,A.ndtime,106),4,3)+ ' ' +  
	RIGHT('0'+LTRIM(RIGHT(CONVERT(varchar,A.ndtime,100),8)),7) + ']' End as LastDown from 
	(
	Select mc,max(id) as idd from #T_autodata 
	where datatype=2 and sttime>=@StartTime and ndtime<=@EndTime group by mc
	)T inner join #T_autodata A on A.mc=T.mc and A.id=T.idd 
	inner join Machineinformation M on M.interfaceid=A.mc
	Left Outer  join Downcodeinformation D on D.interfaceid=A.dcode 
) T1 inner join #CockpitData on T1.MachineID = #CockpitData.MachineID 

--Update #CockpitData Set LastCompletedDowntime = T1.LastDown from 
--(
--Select M.Machineid,ISNULL(D.Downid,'Unknown') + ' ['+ case when A.ndtime<>'' then Substring(CONVERT(varchar,A.ndtime,106),1,2)+ '-' +  
--	substring(CONVERT(varchar,A.ndtime,106),4,3)+ ' ' +  
--	RIGHT('0'+LTRIM(RIGHT(CONVERT(varchar,A.ndtime,100),8)),7) + ']' End as LastDown from 
--	(
--	Select mc,max(id) as idd from #T_autodata 
--	where datatype=2 and sttime>=@StartTime and ndtime<=@EndTime group by mc
--	)T inner join #T_autodata A on A.mc=T.mc and A.id=T.idd 
--	inner join Machineinformation M on M.interfaceid=A.mc
--	Left Outer  join Downcodeinformation D on D.interfaceid=A.dcode 
--) T1 inner join #CockpitData on T1.MachineID = #CockpitData.MachineID 

Update #CockpitData Set LastCompletedDowntime=T1.LastDown From
(select RawData.mc,ISNULL(D.Downid,'Unknown') + ' ['+ case when Rawdata.ndtime<>'' then Substring(CONVERT(varchar,Rawdata.ndtime,106),1,2)+ '-' +  
	substring(CONVERT(varchar,Rawdata.ndtime,106),4,3)+ ' ' +  
	RIGHT('0'+LTRIM(RIGHT(CONVERT(varchar,Rawdata.ndtime,100),8)),7) + ']' End as LastDown from Rawdata
	inner join 
	(select mc,max(slno) as slno from rawdata WITH (NOLOCK)   
	inner join Autodata_maxtime A on rawdata.mc=A.machineid where (Rawdata.sttime>=A.Endtime and Rawdata.sttime<@currtime) and rawdata.datatype in(2,42)
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
	inner join Autodata_maxtime A on rawdata.mc=A.machineid where (Rawdata.sttime>=A.Endtime and Rawdata.sttime<@currtime) and rawdata.datatype=22 
	group by mc
	) t1 on t1.mc=rawdata.mc and t1.slno=rawdata.slno  
Left Outer join Downcodeinformation D on rawdata.splstring2=D.interfaceid
) T1 inner join #CockpitData on T1.mc = #CockpitData.MachineInterface  

update #CockPitData set RunningComponentBoxColor=
case when RunningCycleUT<=RunningCycleStdTime then 'Green'
when RunningCycleUT>RunningCycleStdTime then 'Red' else 'White'
End 



   
/*
	Select @strsql=''
	Select @strsql = '
	SELECT
	#CockpitData.MachineID,
	ProductionEfficiency,
	AvailabilityEfficiency,
	QualityEfficiency, --ER0368
	OverAllEfficiency,
	Round(Components,2) as Components, --NR0097
	RejCount, --ER0368
	CN,
	dbo.f_FormatTime(TotalTime,''' + @timeformat + ''') as TotalTime,
	dbo.f_FormatTime(UtilisedTime,''' + @timeformat + ''') as NetUtilisedTime,
	dbo.f_FormatTime((DownTime-ManagementLoss),''' + @timeformat + ''') as NetDownTime,
	dbo.f_FormatTime(ManagementLoss,''' + @timeformat + ''') as NetManagementLoss,
	dbo.f_FormatTime(((#PLD.pPlannedDT-#PLD.IPlannedDT)+#PLD.DPlannedDT+#PLD.MPlannedDT),''' + @timeformat + ''') as TotalPDT,
	dbo.f_FormatTime((#PLD.pPlannedDT-#PLD.IPlannedDT),''' + @timeformat + ''') as ProdudctionPDT,
	dbo.f_FormatTime(#PLD.DPlannedDT,''' + @timeformat + ''') as DownPDT,
	dbo.f_FormatTime(#PLD.MPlannedDT,''' + @timeformat + ''') as MLPDT,
	UtilisedTime,
	TurnOver,
	ReturnPerHour,
	ReturnPerHourTOTAL,
	case when Remarks = ''Machine Not In Production'' then '' '' else Remarks end as Remarks,
	PEGreen,
	PERed,
	AEGreen,
	AERed,
	OEGreen,
	OERed,
	QERed, --ER0368
	QEGreen, --ER0368
	''' + Convert(nvarchar(20),@StartTime,120) + ''' as StartTime,
	''' + Convert(nvarchar(20),@EndTime,120) + ''' as EndTime,
	MaxDownReason as MaxReasonTime
	,Remarks1,  --ER0368
	Remarks2,  --ER0368
	dbo.f_FormatTime(DownTime,''' + @timeformat + ''') as DownTime
	,Substring(CONVERT(varchar,LastCycletime,106),1,2)+ ''-'' +
	substring(CONVERT(varchar,LastCycletime,106),4,3)+ '' '' +
	 RIGHT(''0''+LTRIM(RIGHT(CONVERT(varchar,LastCycletime,100),8)),7) as LastCycletime,
	LastCycleCO,
----ER0455
Substring(CONVERT(varchar,LastCycleStart,106),1,2)+ ''-'' +
	substring(CONVERT(varchar,LastCycleStart,106),4,3)+ '' '' +
	 RIGHT(''0''+LTRIM(RIGHT(CONVERT(varchar,LastCycleStart,100),8)),7) as LastCycleStart,
case when LastCycleEnd<>'''' then Substring(CONVERT(varchar,LastCycleEnd,106),1,2)+ ''-'' +
	substring(CONVERT(varchar,LastCycleEnd,106),4,3)+ '' '' +
	 RIGHT(''0''+LTRIM(RIGHT(CONVERT(varchar,LastCycleEnd,100),8)),7) end as LastCycleEnd,
	 dbo.f_FormatTime(ElapsedTime,''' + @timeformat + ''') as ElapsedTime,
	 dbo.f_FormatTime(LastCycleSpindleRunTime,''' + @timeformat + ''') as LastCycleSpindleRunTime,LastCycleDatatype
----ER0455
	FROM #CockpitData Inner Join #PLD on #PLD.Machineid=#CockpitData.Machineid
	order by #CockpitData.' + @SortOrder + ''
	exec(@strsql)
*/

---------------------------------------------------------------Target and Runtime cal begins-------------------------------------------------------------------------------------------------------------------------
	if DATEDIFF(day,@starttime,@endtime)<=3
	begin
	
	SELECT @strsql=''   
		Select @strsql= 'insert into #RunTime(MachineID,machineinterface,Component,Compinterface,Operation,Opninterface,
		msttime,ndtime,FromTm,Totm,batchid,autodataid,stdtime,SubOperations)'  
		select @strsql = @strsql + ' SELECT  machineinformation.machineid, machineinformation.interfaceid,componentinformation.componentid, componentinformation.interfaceid,  
		componentoperationpricing.operationno, componentoperationpricing.interfaceid,
		Case when autodata.msttime< '''+CONVERT(NVARCHAR(20),@StartTime,120)+''' then '''+CONVERT(NVARCHAR(20),@StartTime,120)+''' else autodata.msttime end,   
		Case when autodata.ndtime> '''+CONVERT(NVARCHAR(20),@EndTime,120)+''' then '''+CONVERT(NVARCHAR(20),@EndTime,120)+''' else autodata.ndtime end,     
		'''+CONVERT(NVARCHAR(20),@StartTime,120)+''','''+CONVERT(NVARCHAR(20),@EndTime,120)+''',0,autodata.id,componentoperationpricing.Cycletime,componentoperationpricing.SubOperations FROM #T_autodata autodata  with(nolock)
		INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID   
		INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID    
		INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID  
		AND componentinformation.componentid = componentoperationpricing.componentid  
		and componentoperationpricing.machineid=machineinformation.machineid  
		inner Join Employeeinformation EI on EI.interfaceid=autodata.opr 
		where 
		((autodata.msttime >= '''+CONVERT(NVARCHAR(20),@StartTime,120)+'''  AND autodata.ndtime <='''+CONVERT(NVARCHAR(20),@EndTime,120)+''')
		OR ( autodata.msttime < '''+CONVERT(NVARCHAR(20),@StartTime,120)+'''  AND autodata.ndtime <= '''+CONVERT(NVARCHAR(20),@EndTime,120)+''' AND autodata.ndtime > '''+CONVERT(NVARCHAR(20),@StartTime,120)+''' )
		OR ( autodata.msttime >= '''+CONVERT(NVARCHAR(20),@StartTime,120)+'''   AND autodata.msttime <'''+CONVERT(NVARCHAR(20),@EndTime,120)+''' AND autodata.ndtime > '''+CONVERT(NVARCHAR(20),@EndTime,120)+''' )
		OR ( autodata.msttime < '''+CONVERT(NVARCHAR(20),@StartTime,120)+'''  AND autodata.ndtime > '''+CONVERT(NVARCHAR(20),@EndTime,120)+''') ) '
		select @strsql = @strsql 
		select @strsql = @strsql + ' order by autodata.msttime'  
		print @strsql  
		exec (@strsql)



		insert into #FinalRunTime(MachineID,Component,operation,machineinterface,Compinterface,Opninterface,batchid,BatchStart,BatchEnd,FromTm,ToTm,stdtime,Actual,Target,Runtime,SubOperations) 
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
		from #RunTime t 
		) tt
		group by MachineID,Component,operation,machineinterface,Compinterface,Opninterface,batchid,FromTm,ToTm,stdtime,SubOperations
		order by tt.batchid



		update #FinalRunTime set Runtime=datediff(s,BatchStart,BatchEnd)


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

		END



--UPDATE #FinalRunTime SET Target=(Runtime/stdTime) WHERE stdTime<>0

update #FinalRunTime set target=isnull(t.tcount,0)
from
	(
		select F.BatchStart,F.BatchEnd,F.Machineid, CO.componentid as component,CO.Operationno as operation,
		tcount=((F.Runtime*CO.suboperations)/CO.cycletime)*isnull(CO.targetpercent,100) /100
		from componentoperationpricing CO
		inner join #FinalRunTime F on co.machineid=F.machineid and
		CO.Componentid=F.Component and Co.operationno=F.Operation where co.cycletime<>0
	)t INNER JOIN #FinalRunTime F ON F.MachineID=T.MachineID AND F.Component=T.component AND F.Operation=T.operation AND F.BatchStart=T.BatchStart AND F.BatchEnd=T.BatchEnd


UPDATE #CockPitData SET Target=ISNULL(t1.tgt,0)
FROM
(SELECT MachineID,MachineInterface,SUM(ISNULL(Target,0)) AS tgt FROM #FinalRunTime
GROUP BY MachineID,MachineInterface
)t1 INNER JOIN #CockPitData ON #CockPitData.MachineID = t1.MachineID AND #CockPitData.MachineInterface = t1.machineinterface

end



------------------------------------------------------------------------------------target Runtime Cal ends--------------------------------------------------------------------------------------------------------------------------



 IF @param='Plantwise'
Begin

		Select @strSql=''
		Select @strSql=@strSql+
		'Insert into #PlantCellwiseSummary(Plantid,Components,RejCount,UtilisedTime,DownTime,MaxDownReason,CN,ManagementLoss,PlantDescription,ReworkCount)
		Select PlantMachine.Plantid,Isnull(sum(Components),0),Isnull(sum(RejCount),0),
		isnull(sum(UtilisedTime),0),isnull(sum(DownTime),0),Max(MaxDownReason),ISNULL(SUM(CN),0),ISNULL(SUM(ManagementLoss),0),Plantinformation.Description,Isnull(sum(ReworkCount),0)
		From #CockPitData
		left outer join machineinformation on machineinformation.machineid=#CockPitData.MachineID
		Left Outer Join PlantMachine ON PlantMachine.MachineID=#CockPitData.MachineID
		Left Outer Join Plantinformation ON Plantinformation.Plantid=PlantMachine.Plantid
		LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID
		Where #CockPitData.MachineInterface>''0'''
		SELECT @StrSql=@StrSql+ @StrPlantID+ @Strmachine+@StrGroupID
		SELECT @StrSql=@StrSql+ ' group By PlantMachine.Plantid,Plantinformation.Description'
		Print @StrSql
		EXEC(@StrSql)

		UPDATE #PlantCellwiseSummary
		SET
			ProductionEfficiency = (CN/UtilisedTime) ,
			AvailabilityEfficiency = (UtilisedTime)/(UtilisedTime + DownTime - ManagementLoss)
		WHERE UtilisedTime <> 0
		
		--UPDATE #PlantCellwiseSummary SET QualityEfficiency= CAST(Components As Float)/CAST((IsNull(Components,0)+IsNull(RejCount,0)) AS Float)
		--Where Components<>0 

		UPDATE #PlantCellwiseSummary SET QualityEfficiency= CAST((IsNull(Components,0)-IsNull(RejCount,0)) AS Float)/CAST(IsNull(Components,0) AS Float)
		Where Components<>0 


		UPDATE #PlantCellwiseSummary
		SET
			OverAllEfficiency = (ProductionEfficiency * AvailabilityEfficiency * ISNULL(QualityEfficiency,1))*100,
			ProductionEfficiency = ProductionEfficiency * 100 ,
			AvailabilityEfficiency = AvailabilityEfficiency * 100,
			QualityEfficiency = QualityEfficiency*100

		Select @Strsortorder=''		
		If ISNULL(@SortOrder,'')=''
		BEGIN
			SET @SortOrder = ' Plantid ASC'
		END
		Select @Strsortorder= ' order by #PlantCellwiseSummary.' + @SortOrder + ' '

		select @strSql=''
		Select @strSql=@strSql+'
		Select
		Plantid,
		isnull(round(Components,2),0) as ProdCount,
		isnull(round((Isnull(Components,0)-Isnull(RejCount,0)),2),0) as AcceptedParts,
		Isnull(round(RejCount,2),0) as RejCount,
		Round(Isnull(AvailabilityEfficiency,0),2) as AEffy,
		Round(Isnull(ProductionEfficiency,0),2) as PEffy ,
		Round(Isnull(OverAllEfficiency,0),2) as OEffy,
		Round(Isnull(QualityEfficiency,0),2) as QEffy,
		dbo.f_formattime(isnull(UtilisedTime,0),'''+@timeformat+''') As UtilisedTime  ,
		dbo.f_formattime(isnull(DownTime,0),'''+@timeformat+''') As DownTime,
		dbo.f_formattime(isnull(ManagementLoss,0),'''+@timeformat+''') As ManagementLoss,
		PlantDescription as Description,MaxDownReason as MaxDownReasonTime,ISNULL(PEGreen,0) as PEGreen,ISNULL(PERed,0) as PERed,ISNULL(AEGreen,0) as AEGreen,isnull(AERed,0) as AERed,isnull(OEEGreen,0) as OEGreen,
		isnull(OEERed,0) as OERed,isnull(QERED,0) as QERED,isnull(QEGreen,0) as QEGreen,ReworkCount as Rework
		From #PlantCellwiseSummary,TPMWEB_EfficiencyColorCoding where TPMWEB_EfficiencyColorCoding.Type=''PlantID'' '
		Select @strSql=@strSql+@Strsortorder
		exec(@strsql)
End
ELSE IF @param='Cellwise'
Begin

		Select @strSql=''
		Select @strSql=@strSql+
		'Insert into #PlantCellwiseSummary(Plantid,Groupid,Components,RejCount,UtilisedTime,DownTime,MaxDownReason,CN,ManagementLoss,GroupDescription,ReworkCount)
		Select PlantMachine.Plantid,PlantMachineGroups.Groupid,Isnull(sum(Components),0),Isnull(sum(RejCount),0),
		isnull(sum(UtilisedTime),0),isnull(sum(DownTime),0),Max(MaxDownReason),ISNULL(SUM(CN),0),ISNULL(SUM(ManagementLoss),0),PlantMachineGroups.Description,Isnull(sum(ReworkCount),0)
		From #CockPitData 
		left outer join machineinformation on machineinformation.machineid=#CockPitData.MachineID
		Left Outer Join PlantMachine ON PlantMachine.MachineID=#CockPitData.MachineID
		LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID
		Where #CockPitData.MachineInterface>''0'''
		SELECT @StrSql=@StrSql+ @StrPlantID+ @Strmachine+@StrGroupID
		SELECT @StrSql=@StrSql+ ' group By PlantMachine.Plantid,PlantMachineGroups.Groupid,PlantMachineGroups.Description'
		Print @StrSql
		EXEC(@StrSql)

		UPDATE #PlantCellwiseSummary
		SET
			ProductionEfficiency = (CN/UtilisedTime) ,
			AvailabilityEfficiency = (UtilisedTime)/(UtilisedTime + DownTime - ManagementLoss)
		WHERE UtilisedTime <> 0
		
		--UPDATE #PlantCellwiseSummary SET QualityEfficiency= CAST(Components As Float)/CAST((IsNull(Components,0)+IsNull(RejCount,0)) AS Float)
		--Where Components<>0 

		UPDATE #PlantCellwiseSummary SET QualityEfficiency= CAST((IsNull(Components,0)-IsNull(RejCount,0)) AS Float)/CAST(IsNull(Components,0) AS Float)
		Where Components<>0 


		UPDATE #PlantCellwiseSummary
		SET
			OverAllEfficiency = (ProductionEfficiency * AvailabilityEfficiency * ISNULL(QualityEfficiency,1))*100,
			ProductionEfficiency = ProductionEfficiency * 100 ,
			AvailabilityEfficiency = AvailabilityEfficiency * 100,
			QualityEfficiency = QualityEfficiency*100

		If ISNULL(@SortOrder,'')=''
		BEGIN
			SET @SortOrder = 'Plantid,Groupid ASC'
		END
		Select @Strsortorder= ' order by #PlantCellwiseSummary.' + @SortOrder + ' '

		select @strSql=''
		Select @strSql=@strSql+'
		Select
		Plantid,Groupid,
		Isnull(round(Components,2),0) as ProdCount,
		isnull(round((Isnull(Components,0)-Isnull(RejCount,0)),2),0) as AcceptedParts,
		Isnull(round(RejCount,2),0) as RejCount,
		Round(Isnull(AvailabilityEfficiency,0),2) as AEffy,
		Round(Isnull(ProductionEfficiency,0),2) as PEffy ,
		Round(Isnull(OverAllEfficiency,0),2) as OEffy,
		Round(Isnull(QualityEfficiency,0),2) as QEffy,
		dbo.f_formattime(isnull(UtilisedTime,0),'''+@timeformat+''') As UtilisedTime  ,
		dbo.f_formattime(isnull(DownTime,0),'''+@timeformat+''') As DownTime,
		dbo.f_formattime(isnull(ManagementLoss,0),'''+@timeformat+''') As ManagementLoss,
		GroupDescription as Description,MaxDownReason as MaxDownReasonTime,ISNULL(PEGreen,0) as PEGreen,ISNULL(PERed,0) as PERed,ISNULL(AEGreen,0) as AEGreen,isnull(AERed,0) as AERed,isnull(OEEGreen,0) as OEGreen,
		isnull(OEERed,0) as OERed,isnull(QERED,0) as QERED,isnull(QEGreen,0) as QEGreen,ReworkCount as Rework
		From #PlantCellwiseSummary,TPMWEB_EfficiencyColorCoding where TPMWEB_EfficiencyColorCoding.Type=''CellID'' '
		Select @strSql=@strSql+@Strsortorder
		exec(@strsql)
End
Else
Begin
	Select @strsql=''  
	Select @strsql = '  
	SELECT  
	C.MachineID,  
	''' + Convert(nvarchar(20),@StartTime,120) + ''' as StartTime, --TimePeriodBegin 
	ROUND(C.AvailabilityEfficiency,2) as AvailabilityEfficiency,  
	ROUND(C.ProductionEfficiency,2) as ProductionEfficiency,  
	ROUND(C.QualityEfficiency,2) as QualityEfficiency, --ER0368  
	ROUND(C.OverAllEfficiency,2) as OverAllEfficiency,  
	Round(C.Components,2) as Components, --CompletedParts --NR0097  
	C.RejCount, --ER0368  
	C.CN,  
	dbo.f_FormatTime(C.TotalTime,''' + @timeformat + ''') as TotalTime,  
	dbo.f_FormatTime(C.UtilisedTime,''' + @timeformat + ''') as NetUtilisedTime, --CompletedCycleUT 
	dbo.f_FormatTime((DownTime-ManagementLoss),''' + @timeformat + ''') as NetDownTime, --CompletedCycleDT
	dbo.f_FormatTime(ManagementLoss,''' + @timeformat + ''') as NetManagementLoss, --CompletedCycleML 
	dbo.f_FormatTime(((#PLD.pPlannedDT-#PLD.IPlannedDT)+#PLD.DPlannedDT+#PLD.MPlannedDT),''' + @timeformat + ''') as TotalPDT, --CompletedCyclePDT
	dbo.f_FormatTime((#PLD.pPlannedDT-#PLD.IPlannedDT),''' + @timeformat + ''') as ProdudctionPDT, --CompletedCycleProdPDT
	dbo.f_FormatTime(#PLD.DPlannedDT,''' + @timeformat + ''') as DownPDT, --CompletedCycleDownPDT
	dbo.f_FormatTime(#PLD.MPlannedDT,''' + @timeformat + ''') as MLPDT, --CompletedCycleMLPDT  
	C.UtilisedTime,
	C.TurnOver,  
	C.ReturnPerHour,  
	C.ReturnPerHourTOTAL,  
	case when C.Remarks = ''Machine Not In Production'' then '' '' else C.Remarks end as Remarks,  
	C.PEGreen,  
	C.PERed,  
	C.AEGreen,  
	C.AERed,  
	C.OEGreen,  
	C.OERed,  
	C.QERed, --ER0368  
	C.QEGreen, --ER0368  
	''' + Convert(nvarchar(20),@EndTime,120) + ''' as EndTime,  
	C.MaxDownReason as MaxReasonTime,  
	C.Remarks1,  --ER0368  
	C.Remarks2,  --ER0368  
	dbo.f_FormatTime(DownTime,''' + @timeformat + ''') as DownTime, --CompletedCycleTotalDT  
	Substring(CONVERT(varchar,LastCycletime,106),1,2)+ ''-'' +  
	substring(CONVERT(varchar,LastCycletime,106),4,3)+ '' '' +  
	RIGHT(''0''+LTRIM(RIGHT(CONVERT(varchar,LastCycletime,100),8)),7) as LastCycletime, --CompletedCycletime  
	LastCycleCO  as LastCycleCO, --RunningCyclePart  
	----ER0455  
	Substring(CONVERT(varchar,LastCycleStart,106),1,2)+ ''-'' +  
	substring(CONVERT(varchar,LastCycleStart,106),4,3)+ '' '' +  
	RIGHT(''0''+LTRIM(RIGHT(CONVERT(varchar,LastCycleStart,100),8)),7) as LastCycleStart, -- RunningCycleStarttime
	case when LastCycleEnd<>'''' then Substring(CONVERT(varchar,LastCycleEnd,106),1,2)+ ''-'' +  
	substring(CONVERT(varchar,LastCycleEnd,106),4,3)+ '' '' +  
	RIGHT(''0''+LTRIM(RIGHT(CONVERT(varchar,LastCycleEnd,100),8)),7) end as LastCycleEnd,  
	dbo.f_FormatTime(ElapsedTime,''' + @timeformat + ''') as ElapsedTime,  
	dbo.f_FormatTime(LastCycleSpindleRunTime,''' + @timeformat + ''') as LastCycleSpindleRunTime,LastCycleDatatype,
	dbo.f_FormatTime(RunningCycleUT,''' + @timeformat + ''') as  RunningCycleUT,
	dbo.f_FormatTime(RunningCycleDT,''' + @timeformat + ''') as  RunningCycleDT,  
	dbo.f_FormatTime(RunningCyclePDT,''' + @timeformat + ''') as  RunningCyclePDT,  
	C.RunningCycleAE ,
	C.MachineStatus , M.Description as MachineDescription, C.OperatorName,ISNULL(C.MachineLivestatus,''NoData'') as MachineLiveStatus,
	ISNULL(C.MachineLiveStatusColor,''White'') as MachineLiveStatusColor,
	LastCycleCompDescription,LastCycleOperation,LastCycleOpnDescription,
	C.LastCompletedDowntime,C.CurrentDowntime,
	dbo.f_FormatTime(C.RunningCyclestdtime,''' + @timeformat + ''') as RunningCyclestdtime,
	C.RunningComponentBoxColor,G.Groupid,c.spindleruntime AS SpindleRuntimeinSec,dbo.f_FormatTime(C.spindleruntime,''' + @timeformat + ''') as SpindleRunTime,
	round(c.Target,0) as Target,
	case when isnull(Target,0)>''0'' then round((c.components/c.target)*100,2) else ''0'' end as Efficiency,
	c.SpindleCycletime AS SpindleCycletimeinSec,dbo.f_FormatTime(C.spindlecycletime,''' + @timeformat + ''') as SpindleCycletime
	FROM #CockpitData C Inner Join #PLD on #PLD.Machineid=C.Machineid 
	Inner join Machineinformation M on M.Machineid=C.Machineid 
	Left Outer Join PlantMachine P ON P.MachineID=C.MachineID
	LEFT OUTER JOIN PlantMachineGroups G ON G.PlantID = P.PlantID and G.machineid = P.MachineID '
	Select @strSql = @strSql + @Strsortorder
	print(@strsql)
	exec(@strsql)  
End 
 
END  
