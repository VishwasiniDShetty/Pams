/****** Object:  Procedure [dbo].[S_GetShiftWiseOEEReport_Trellborg]    Committed by VersionSQL https://www.versionsql.com ******/

/*
exec [dbo].[S_GetShiftWiseOEEReport_Trellborg] '2022-07-11 06:00:00','2022-07-13 06:00:00','','','',''
exec [dbo].[S_GetShiftWiseOEEReport_Trellborg] '2022-07-11 06:00:00','2022-07-13 06:00:00','1st SHIFT','','',''
exec [dbo].[S_GetShiftWiseOEEReport_Trellborg] '2022-07-11 06:00:00','2022-07-13 06:00:00','2nd SHIFT','','',''
exec [dbo].[S_GetShiftWiseOEEReport_Trellborg] '2022-07-11 06:00:00','2022-07-13 06:00:00','3rd SHIFT','','',''

*/
CREATE procedure [dbo].[S_GetShiftWiseOEEReport_Trellborg]
@StartTime datetime='',
@EndTime datetime='',
@Shift nvarchar(50)='',
@PlantID  Nvarchar(50) = '',
@GroupID As nvarchar(50) = '',
@MachineID nvarchar(50) = '',
@param nvarchar(50)=''
as
begin

Declare @strSql as nvarchar(4000)
Declare @strmachine nvarchar(255)
Declare @shiftin  nvarchar(255)
declare @StrTPMMachines nvarchar(500)
Declare @StrPlantid NVarChar(255)
Declare @timeformat as nvarchar(12)
Declare @Start as datetime
Declare @End as datetime
Declare @StrGroupID AS NVarchar(255)
declare @StrMCJoined as nvarchar(max)
declare @StrGroupJoined as nvarchar(max)

select @strSql=''
select @strmachine=''
select @StrPlantid=''
select @StrGroupID=''
select @Start=@StartTime
select @End=@EndTime
select @shiftin='3rd SHIFT'
--select @shiftin='C'


if isnull(@PlantID,'') <> ''
Begin
	---mod 2
	Select @StrPlantid = ' and ( PlantMachine.PlantID = N''' + @PlantID + ''')'
End

if isnull(@machineid,'') <> ''
Begin
	select @StrMCJoined =  (case when (coalesce( +@StrMCJoined + ',''', '''')) = ''''  then 'N''' else @StrMCJoined+',N''' end) +item+'''' from [SplitStrings](@MachineID, ',')    
	if @StrMCJoined = 'N'''''  
	set @StrMCJoined = '' 
	select @MachineID = @StrMCJoined

	Select @strmachine = ' and ( Machineinformation.MachineID in (' + @MachineID +') )'
end

If isnull(@GroupID ,'') <> ''
Begin
	select @StrGroupJoined =  (case when (coalesce( +@StrGroupJoined + ',''', '''')) = ''''  then 'N''' else @StrGroupJoined+',N''' end) +item+'''' from [SplitStrings](@GroupID, ',')    
	if @StrGroupJoined = 'N'''''  
	set @StrGroupJoined = '' 
	select @GroupID = @StrGroupJoined
	
	Select @StrGroupID = ' And ( PlantMachineGroups.GroupID in (' + @GroupID +') )'
End

IF ( SELECT TOP 1 ValueInText FROM  CockpitDefaults WHERE Parameter='TpmEnbMac')='E'
BEGIN
	SET  @StrTPMMachines = ' AND MachineInformation.TPMTrakEnabled = 1 '
END
ELSE
BEGIN
	SET  @StrTPMMachines = ' '
END

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


create table #ShiftProductionFromAutodataT1
(
	machineid nvarchar(50) not null,
	MachineInterface nvarchar(150),
	UstartShift datetime not null,
	UEndShift datetime not null,
	ShiftDate datetime,	
	shiftid nvarchar(20),
	UtilisedTime float
)

	CREATE TABLE #Shift2
	(
		ShiftDate DateTime,		
		Shiftname nvarchar(20),
		ShftSTtime DateTime,
		ShftEndTime DateTime,
		shiftid int
	)



WHILE @Start<@End
BEGIN
	INSERT INTO #Shift2(ShiftDate,Shiftname,ShftSTtime,ShftEndTime)
	Exec s_GetShiftTime @Start,@shiftin
	SELECT @Start = DATEADD(DAY,1,@Start)
end

Update #Shift2 Set shiftid = isnull(#Shift2.Shiftid,0) + isnull(T1.shiftid,0) from
(Select SD.shiftid ,SD.shiftname from shiftdetails SD
inner join #Shift2 S on SD.shiftname=S.shiftname where
running=1 )T1 inner join #Shift2 on  T1.shiftname=#Shift2.shiftname

create table #OEE
(
	MachineID Nvarchar(50),
	MachineInterface nvarchar(50),
	Sdate datetime,
	StartDate datetime,
	EndDate datetime,
	TotalTime float,
	NonWorking float,
	LunchDinner float,
	SettingTime float,
	NoofSettings float,
	OperatingTime float,
	DownTime float,
	ManagementLoss FLOAT,
	MLDown float,
	PlannedLoss float,
	SummationofStandardTime float,
	OEEExclusionTime float,
	SupervisorCategoryDowntime float,
	OperatorCategoryDowntime float,
	FromTime datetime,
	ToTime datetime,
	QualityEfficiency float,
	Components float,
	RejCount float,
	MLThresholdSetting float,
	TimeAsPerBOM FLOAT,
	MLThresholdOperatorCat float,
	UtilisedTime3rdShift float
)

CREATE TABLE #PLD
(
	MachineID nvarchar(50),
	--MachineInterface nvarchar(50), --ER0374
	MachineInterface nvarchar(50) NOT NULL, --ER0374
	Sdate datetime NOT NULL,
	StartDate datetime,
	EndDate datetime,
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
	Sdate datetime NOT NULL,
	StartDate datetime,
	EndDate datetime,
	StartTime DateTime NOT NULL, --ER0374
	EndTime DateTime NOT NULL --ER0374
)
--mod 4

--ER0374 From here
ALTER TABLE #PLD
	ADD PRIMARY KEY CLUSTERED
		(   [MachineInterface],
			Sdate
						
		) ON [PRIMARY]


ALTER TABLE #PlannedDownTimes
	ADD PRIMARY KEY CLUSTERED
		(   [MachineInterface],
			Sdate,
			[StartTime],
			[EndTime]
						
		) ON [PRIMARY]


CREATE TABLE #ShiftDefn
(
	ShiftDate datetime,		
	Shiftname nvarchar(20),
	ShftSTtime datetime,
	ShftEndTime datetime	
)

declare @startdate1 as datetime
declare @enddate1 as datetime
declare @startdatetime nvarchar(20)

--ER0374 From Here
--select @startdate = dbo.f_GetLogicalDay(@StartTime,'start')
--select @enddate = dbo.f_GetLogicalDay(@endtime,'start')
--select @startdate1 = dbo.f_GetLogicalDaystart(@StartTime)
----select @enddate1 = dbo.f_GetLogicalDaystart(@endtime)
--select @enddate1 = dbo.f_GetLogicalDayEnd(@endtime)

select @startdate1 = dbo.f_GetLogicalDay(@StartTime,'start')
select @enddate1 = dbo.f_GetLogicalDay(@endtime,'end')


--ER0374 Till Here

while @startdate1<=@enddate1
Begin

	select @startdatetime = CAST(datePart(yyyy,@startdate1) AS nvarchar(4)) + '-' + 
     CAST(datePart(mm,@startdate1) AS nvarchar(2)) + '-' + 
     CAST(datePart(dd,@startdate1) AS nvarchar(2))

	INSERT INTO #ShiftDefn(ShiftDate,Shiftname,ShftSTtime,ShftEndTime)
	select @startdate1,ShiftName,
	Dateadd(DAY,FromDay,(convert(datetime, @startdatetime + ' ' + CAST(datePart(hh,FromTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,FromTime) as nvarchar(2))+ ':' + CAST(datePart(ss,FromTime) as nvarchar(2))))) as StartTime,
	DateAdd(Day,ToDay,(convert(datetime, @startdatetime + ' ' + CAST(datePart(hh,ToTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,ToTime) as nvarchar(2))+ ':' + CAST(datePart(ss,ToTime) as nvarchar(2))))) as EndTime
	from shiftdetails where running = 1 order by shiftid
	Select @startdate1 = dateadd(d,1,@startdate1)
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
--select convert(nvarchar(10),ShiftDate,126),shiftname,ShftSTtime,ShftEndTime from #ShiftDefn where ShftSTtime>=@StartTime and ShftEndTime<=@endtime --DR0333
select convert(nvarchar(10),ShiftDate,126),shiftname,ShftSTtime,ShftEndTime from #ShiftDefn --where ShftSTtime>=@StartTime and ShftSTtime<=@endtime --DR0333

Update #shift Set shiftid = isnull(#shift.Shiftid,0) + isnull(T1.shiftid,0) from
(Select SD.shiftid ,SD.shiftname from shiftdetails SD
inner join #shift S on SD.shiftname=S.shiftname where
running=1 )T1 inner join #shift on  T1.shiftname=#shift.shiftname

DELETE FROM #shift WHERE Shiftstart>=@EndTime



Create Table #DayShiftDetails
(
	Sdate datetime,
	StartDate datetime,
	EndDate datetime 
)

IF (isnull(@Shift,'')<>'')
Begin
	Insert into #DayShiftDetails(Sdate,StartDate,EndDate)
	select ShiftDate,Shiftstart,Shiftend from #shift where shiftname=@Shift
END
IF (isnull(@Shift,'')='')
Begin
	Insert into #DayShiftDetails(Sdate,StartDate,EndDate)
	select ShiftDate,min(Shiftstart),max(Shiftend) from #shift group by ShiftDate
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
	mc,sttime,ndtime,msttime ASC
)ON [PRIMARY]

Declare @T_ST AS Datetime 
Declare @T_ED AS Datetime 

--Select @T_ST=dbo.f_GetLogicalDaystart(@StartTime)
--Select @T_ED=dbo.f_GetLogicalDayend(@EndTime)

select @T_ST = dbo.f_GetLogicalDay(@StartTime,'start')
select @T_ED = dbo.f_GetLogicalDay(@EndTime,'end')

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

SET @strSql = 'INSERT INTO #OEE (	
MachineID ,
MachineInterface ,
SDate ,
StartDate,
EndDate,
TotalTime ,
NonWorking ,
LunchDinner,
SettingTime,
NoofSettings ,
OperatingTime ,
DownTime,
ManagementLoss,
MLDown ,
PlannedLoss ,
SummationofStandardTime ,
OEEExclusionTime ,
SupervisorCategoryDowntime ,
OperatorCategoryDowntime,
FromTime,
ToTime,
Components, 
RejCount,
QualityEfficiency,
MLThresholdSetting,
MLThresholdOperatorCat,
UtilisedTime3rdShift
	) '
SET @strSql = @strSql + ' SELECT MachineInformation.MachineID, MachineInformation.interfaceid,DS.Sdate,DS.StartDate,DS.EndDate, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,
DS.StartDate,DS.EndDate,0,0,0,0,0,0 FROM MachineInformation 
	Cross join #DayShiftDetails DS
			  LEFT OUTER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID
			  LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID
 WHERE MachineInformation.interfaceid > ''0'' '
SET @strSql =  @strSql + @strMachine + @StrTPMMachines + @strPlantID + @StrGroupID
print(@strsql)
EXEC(@strSql)


SET @strSql = ''
SET @strSql = 'INSERT INTO #PLD(MachineID,MachineInterface,pPlannedDT,dPlannedDT,SDate ,StartDate,EndDate)
	SELECT machineinformation.MachineID ,Interfaceid,0  ,0 ,DS.Sdate,DS.StartDate,DS.EndDate FROM MachineInformation
	Cross join #DayShiftDetails DS
		LEFT OUTER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID 
    LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID
	 WHERE  MachineInformation.interfaceid > ''0'' '
SET @strSql =  @strSql + @strMachine + @StrTPMMachines + @strPlantID + @StrGroupID
EXEC(@strSql)



SET @strSql = ''
SET @strSql = 'Insert into #PlannedDownTimes
	SELECT Machine,InterfaceID,DS.Sdate,DS.StartDate,DS.EndDate,
		CASE When StartTime<DS.StartDate  Then DS.StartDate Else StartTime End As StartTime,
		CASE When EndTime>DS.StartDate  Then DS.EndDate  Else EndTime End As EndTime
	FROM PlannedDownTimes inner join MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID
	LEFT OUTER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID 
    LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID 
	and PlantMachineGroups.machineid = PlantMachine.MachineID
	Cross join #DayShiftDetails DS
	WHERE PDTstatus =1 and(
	(StartTime >= DS.StartDate AND EndTime <=DS.EndDate)
	OR ( StartTime < DS.StartDate  AND EndTime <= DS.EndDate AND EndTime > DS.StartDate )
	OR ( StartTime >= DS.StartDate   AND StartTime < DS.EndDate  AND EndTime > DS.StartDate )
	OR ( StartTime < DS.StartDate  AND EndTime > DS.EndDate)) '
SET @strSql =  @strSql + @strMachine + @StrGroupID + @StrTPMMachines + @strPlantID + ' ORDER BY Machine,StartTime'
EXEC(@strSql)


-----------------------------------------------------------Totaltime cal starts-----------------------------------------------------------------------------------------------------

UPDATE #OEE SET TotalTime = DateDiff(second, StartDate, EndDate)

-----------------------------------------------------------Totaltime cal ends-----------------------------------------------------------------------------------------------------

-----------------------------------------------------------pdt cal starts-----------------------------------------------------------------------------------------------------

UPDATE #OEE SET NonWorking=ISNULL(NonWorking,0)+T1.PDT
FROM
(
SELECT MACHINEID,Sdate,StartDate,EndDate,SUM(DATEDIFF(ss,StartTime,EndTime)) AS PDT FROM #PlannedDownTimes
GROUP BY MACHINEID,Sdate,StartDate,EndDate
) T1 INNER JOIN #OEE ON T1.MachineID=#OEE.MachineID and T1.Sdate=#OEE.Sdate and t1.StartDate=#OEE.StartDate and t1.EndDate=#OEE.EndDate

-----------------------------------------------------------pdt cal ends-----------------------------------------------------------------------------------------------------

-----------------------------------------------------------Threshold for lunch and dinner cal starts-------------------------------------------------------------------------


		UPDATE #OEE SET LunchDinner = isnull(LunchDinner,0) + isNull(t2.loss,0)
		from
		(select mc,Sdate,StartDate,EndDate,sum(
		CASE
		WHEN (loadunload) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
		THEN isnull(downcodeinformation.Threshold,0)
		ELSE loadunload
		END) AS LOSS
		from #T_autodata autodata  --ER0374
		INNER JOIN #OEE T on T.MachineInterface=autodata.mc
		INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
		where (autodata.msttime>=T.StartDate)
		and (autodata.ndtime<=T.EndDate)
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1) 
		and downcodeinformation.downid in ('BREAKFAST / LANCH')
		and (downcodeinformation.ThresholdfromCO <>1) --NR0097
		group by autodata.mc,Sdate,StartDate,EndDate) as t2 inner join #OEE on t2.mc = #OEE.machineinterface and t2.Sdate=#OEE.Sdate
		and t2.StartDate=#OEE.StartDate and t2.EndDate=#OEE.EndDate

		-- Type 2
		UPDATE #OEE SET LunchDinner = isnull(LunchDinner,0) + isNull(t2.loss,0)
		from
		(select      mc,Sdate,StartDate,EndDate,sum(
		CASE WHEN DateDiff(second, T.StartDate, ndtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
		then isnull(downcodeinformation.Threshold,0)
		ELSE DateDiff(second, T.StartDate, ndtime)
		END)loss
		from #T_autodata autodata  --ER0374
		INNER JOIN #OEE T on T.MachineInterface=autodata.mc
		INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
		where (autodata.sttime<T.StartDate)
		and (autodata.ndtime>T.StartDate)
		and (autodata.ndtime<=T.EndDate)
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1)
		and downcodeinformation.downid in ('BREAKFAST / LANCH')
		and (downcodeinformation.ThresholdfromCO <>1) --NR0097
		group by autodata.mc,Sdate,StartDate,EndDate
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface and t2.Sdate=#OEE.Sdate
		and t2.StartDate=#OEE.StartDate and t2.EndDate=#OEE.EndDate

		-- Type 3
		UPDATE #OEE SET LunchDinner = isnull(LunchDinner,0) + isNull(t2.loss,0)
		from
		(select      mc,Sdate,StartDate,EndDate,SUM(
		CASE WHEN DateDiff(second,stTime, T.EndDate) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
		then isnull(downcodeinformation.Threshold,0)
		ELSE DateDiff(second, stTime, T.EndDate)
		END)loss
		from #T_autodata autodata --ER0374
		INNER JOIN #OEE T on T.MachineInterface=autodata.mc
		INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
		where (autodata.msttime>=T.StartDate)
		and (autodata.sttime<T.EndDate)
		and (autodata.ndtime>T.EndDate)
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1)
		and (downcodeinformation.ThresholdfromCO <>1) --NR0097
		and downcodeinformation.downid in ('BREAKFAST / LANCH')
		group by autodata.mc,Sdate,StartDate,EndDate
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface and t2.Sdate=#OEE.Sdate
		and t2.StartDate=#OEE.StartDate and t2.EndDate=#OEE.EndDate

		-- Type 4
		UPDATE #OEE SET LunchDinner = isnull(LunchDinner,0) + isNull(t2.loss,0)
		from
		(select mc,Sdate,StartDate,EndDate,sum(
		CASE WHEN DateDiff(second, T.StartDate, T.EndDate) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
		then isnull(downcodeinformation.Threshold,0)
		ELSE DateDiff(second, T.StartDate, T.EndDate)
		END)loss
		from #T_autodata autodata --ER0374
		INNER JOIN #OEE T on T.MachineInterface=autodata.mc
		INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
		where autodata.msttime<T.StartDate
		and autodata.ndtime>T.EndDate
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1)
		and downcodeinformation.downid in ('BREAKFAST / LANCH')
		and (downcodeinformation.ThresholdfromCO <>1) --NR0097
		group by autodata.mc,Sdate,StartDate,EndDate
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface	and t2.Sdate=#OEE.Sdate
		and t2.StartDate=#OEE.StartDate and t2.EndDate=#OEE.EndDate

-----------------------------------------------------------------------ML Threshold for settings time cal starts (Time AsPer BOM)----------------------------------------------------------------------------------------
		UPDATE #OEE SET TimeAsPerBOM = isnull(TimeAsPerBOM,0) + isNull(t2.loss,0)
		from
		(select mc,Sdate,StartDate,EndDate,sum(
		CASE
		WHEN (loadunload) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
		THEN isnull(downcodeinformation.Threshold,0)
		ELSE loadunload
		END) AS LOSS
		from #T_autodata autodata  --ER0374
		INNER JOIN #OEE T on T.MachineInterface=autodata.mc
		INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
		where (autodata.msttime>=T.StartDate)
		and (autodata.ndtime<=T.EndDate)
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1) 
		and downcodeinformation.downid like '%SETUP%'
		and (downcodeinformation.ThresholdfromCO <>1) --NR0097
		group by autodata.mc,Sdate,StartDate,EndDate) as t2 inner join #OEE on t2.mc = #OEE.machineinterface and t2.Sdate=#OEE.Sdate
		and t2.StartDate=#OEE.StartDate and t2.EndDate=#OEE.EndDate

		-- Type 2
		UPDATE #OEE SET TimeAsPerBOM = isnull(TimeAsPerBOM,0) + isNull(t2.loss,0)
		from
		(select      mc,Sdate,StartDate,EndDate,sum(
		CASE WHEN DateDiff(second, T.StartDate, ndtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
		then isnull(downcodeinformation.Threshold,0)
		ELSE DateDiff(second, T.StartDate, ndtime)
		END)loss
		--DateDiff(second, T.StartDate, ndtime)
		from #T_autodata autodata  --ER0374
		INNER JOIN #OEE T on T.MachineInterface=autodata.mc
		INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
		where (autodata.sttime<T.StartDate)
		and (autodata.ndtime>T.StartDate)
		and (autodata.ndtime<=T.EndDate)
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1)
		and downcodeinformation.downid  like '%SETUP%'
		and (downcodeinformation.ThresholdfromCO <>1) --NR0097
		group by autodata.mc,Sdate,StartDate,EndDate
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface and t2.Sdate=#OEE.Sdate
		and t2.StartDate=#OEE.StartDate and t2.EndDate=#OEE.EndDate

		-- Type 3
		UPDATE #OEE SET TimeAsPerBOM = isnull(TimeAsPerBOM,0) + isNull(t2.loss,0)
		from
		(select      mc,Sdate,StartDate,EndDate,SUM(
		CASE WHEN DateDiff(second,stTime, T.EndDate) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
		then isnull(downcodeinformation.Threshold,0)
		ELSE DateDiff(second, stTime, T.EndDate)
		END)loss
		-- sum(DateDiff(second, stTime, T.EndDate)) loss
		from #T_autodata autodata --ER0374
		INNER JOIN #OEE T on T.MachineInterface=autodata.mc
		INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
		where (autodata.msttime>=T.StartDate)
		and (autodata.sttime<T.EndDate)
		and (autodata.ndtime>T.EndDate)
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1)
		and (downcodeinformation.ThresholdfromCO <>1) --NR0097
		and downcodeinformation.downid like '%SETUP%'
		group by autodata.mc,Sdate,StartDate,EndDate
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface and t2.Sdate=#OEE.Sdate
		and t2.StartDate=#OEE.StartDate and t2.EndDate=#OEE.EndDate

		-- Type 4
		UPDATE #OEE SET TimeAsPerBOM = isnull(TimeAsPerBOM,0) + isNull(t2.loss,0)
		from
		(select mc,Sdate,StartDate,EndDate,sum(
		CASE WHEN DateDiff(second, T.StartDate, T.EndDate) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
		then isnull(downcodeinformation.Threshold,0)
		ELSE DateDiff(second, T.StartDate, T.EndDate)
		END)loss
		--sum(DateDiff(second, T.StartDate, T.EndDate)) loss
		from #T_autodata autodata --ER0374
		INNER JOIN #OEE T on T.MachineInterface=autodata.mc
		INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
		where autodata.msttime<T.StartDate
		and autodata.ndtime>T.EndDate
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1)
		and downcodeinformation.downid like '%SETUP%'
		and (downcodeinformation.ThresholdfromCO <>1) --NR0097
		group by autodata.mc,Sdate,StartDate,EndDate
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface	and t2.Sdate=#OEE.Sdate
		and t2.StartDate=#OEE.StartDate and t2.EndDate=#OEE.EndDate

------------------------------------------------------------------------ML Threshold for settings time cal ENDS (Time AsPer BOM) ---------------------------------------------------------------- 

----------------------------------------------------------------------setting time cal STARTS- -------------------------------------------------------------------------------------------------------------			
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N'
BEGIN
		UPDATE #OEE SET SettingTime = isnull(SettingTime,0) + isNull(t2.down,0)
		from
		(select mc,Sdate,StartDate,EndDate,sum(
				CASE
				WHEN  autodata.msttime>=T.StartDate  and  autodata.ndtime<=T.EndDate  THEN  loadunload
				WHEN (autodata.sttime<T.StartDate and  autodata.ndtime>T.StartDate and autodata.ndtime<=T.EndDate)  THEN DateDiff(second, T.StartDate, ndtime)
				WHEN (autodata.msttime>=T.StartDate  and autodata.sttime<T.EndDate  and autodata.ndtime>T.EndDate)  THEN DateDiff(second, stTime, T.EndDate)
				WHEN autodata.msttime<T.StartDate and autodata.ndtime>T.EndDate   THEN DateDiff(second, T.StartDate, T.EndDate)
				END
			)AS down
		from #T_autodata autodata --ER0374
		INNER JOIN #OEE T on T.MachineInterface=autodata.mc
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		where autodata.datatype=2 AND
		(
		(autodata.msttime>=T.StartDate  and  autodata.ndtime<=T.EndDate)
		OR (autodata.sttime<T.StartDate and  autodata.ndtime>T.StartDate and autodata.ndtime<=T.EndDate)
		OR (autodata.msttime>=T.StartDate  and autodata.sttime<T.EndDate  and autodata.ndtime>T.EndDate)
		OR (autodata.msttime<T.StartDate and autodata.ndtime>T.EndDate )
		) and downid like '%SETUP%'
		group by autodata.mc,Sdate,StartDate,EndDate
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface and t2.Sdate=#OEE.Sdate
		and t2.StartDate=#OEE.StartDate and t2.EndDate=#OEE.EndDate
end


If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN
		UPDATE #OEE SET SettingTime = isnull(SettingTime,0) + isNull(t2.down,0)
		from
		(select mc,Sdate,StartDate,EndDate,sum(
				CASE
				WHEN  autodata.msttime>=T.StartDate  and  autodata.ndtime<=T.EndDate  THEN  loadunload
				WHEN (autodata.sttime<T.StartDate and  autodata.ndtime>T.StartDate and autodata.ndtime<=T.EndDate)  THEN DateDiff(second, T.StartDate, ndtime)
				WHEN (autodata.msttime>=T.StartDate  and autodata.sttime<T.EndDate  and autodata.ndtime>T.EndDate)  THEN DateDiff(second, stTime, T.EndDate)
				WHEN autodata.msttime<T.StartDate and autodata.ndtime>T.EndDate   THEN DateDiff(second, T.StartDate, T.EndDate)
				END
			)AS down
		from #T_autodata autodata --ER0374
		INNER JOIN #OEE T on T.MachineInterface=autodata.mc
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		where autodata.datatype=2 AND
		(
		(autodata.msttime>=T.StartDate  and  autodata.ndtime<=T.EndDate)
		OR (autodata.sttime<T.StartDate and  autodata.ndtime>T.StartDate and autodata.ndtime<=T.EndDate)
		OR (autodata.msttime>=T.StartDate  and autodata.sttime<T.EndDate  and autodata.ndtime>T.EndDate)
		OR (autodata.msttime<T.StartDate and autodata.ndtime>T.EndDate )
		) and downid  like '%SETUP%'
		group by autodata.mc,Sdate,StartDate,EndDate
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface and t2.Sdate=#OEE.Sdate
		and t2.StartDate=#OEE.StartDate and t2.EndDate=#OEE.EndDate

	

	UPDATE #OEE set SettingTime =isnull(SettingTime,0) - isNull(TT.PPDT ,0)
	FROM(
		SELECT autodata.MC,Sdate,StartDate,EndDate,SUM
		   (CASE
			WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PPDT
		from  #T_autodata autodata 
		CROSS jOIN #PlannedDownTimes T
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)and downcodeinformation.downid  like '%SETUP%'
		group by autodata.MC,Sdate,StartDate,EndDate
	) as TT INNER JOIN #OEE ON TT.mc = #OEE.MachineInterface and tt.Sdate=#OEE.Sdate
		and tt.StartDate=#OEE.StartDate and tt.EndDate=#OEE.EndDate

end

---------------------------------------------------------- Setting time calculation ends--------------------------------------------------------------------------------------------

------------------------------------------------------------NoOf SettingTime (Frequency) starts------------------------------------------------------------------------------------
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N'
begin
		UPDATE #OEE SET NoofSettings = isnull(NoofSettings,0) + isNull(t2.frequency,0)
		from
		(select mc,Sdate,StartDate,EndDate,count(dcode) AS frequency
		from #T_autodata autodata --ER0374
		INNER JOIN #OEE T on T.MachineInterface=autodata.mc
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		where autodata.datatype=2 AND
		(
		(autodata.msttime>=T.StartDate  and  autodata.ndtime<=T.EndDate)
		OR (autodata.sttime<T.StartDate and  autodata.ndtime>T.StartDate and autodata.ndtime<=T.EndDate)
		OR (autodata.msttime>=T.StartDate  and autodata.sttime<T.EndDate  and autodata.ndtime>T.EndDate)
		OR (autodata.msttime<T.StartDate and autodata.ndtime>T.EndDate )
		) and downid  like '%SETUP%'
		group by autodata.mc,Sdate,StartDate,EndDate
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface and t2.Sdate=#OEE.Sdate
		and t2.StartDate=#OEE.StartDate and t2.EndDate=#OEE.EndDate
end



If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='y'
begin
		UPDATE #OEE SET NoofSettings = isnull(NoofSettings,0) + isNull(t2.frequency,0)
		from
		(select mc,Sdate,StartDate,EndDate,count(dcode) AS frequency
		from #T_autodata autodata --ER0374
		INNER JOIN #OEE T on T.MachineInterface=autodata.mc
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		where autodata.datatype=2 AND
		(
		(autodata.msttime>=T.StartDate  and  autodata.ndtime<=T.EndDate)
		OR (autodata.sttime<T.StartDate and  autodata.ndtime>T.StartDate and autodata.ndtime<=T.EndDate)
		OR (autodata.msttime>=T.StartDate  and autodata.sttime<T.EndDate  and autodata.ndtime>T.EndDate)
		OR (autodata.msttime<T.StartDate and autodata.ndtime>T.EndDate )
		) and downid  like '%SETUP%'
		group by autodata.mc,Sdate,StartDate,EndDate
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface and t2.Sdate=#OEE.Sdate
		and t2.StartDate=#OEE.StartDate and t2.EndDate=#OEE.EndDate


		UPDATE #OEE SET NoofSettings = isnull(NoofSettings,0) - isNull(tt.frequency,0)
		from
		(select mc,Sdate,StartDate,EndDate,count(dcode) AS frequency
		from  #T_autodata autodata CROSS jOIN #PlannedDownTimes T
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)and downcodeinformation.downid  like '%SETUP%'
		group by autodata.MC,Sdate,StartDate,EndDate
		) as TT INNER JOIN #OEE ON TT.mc = #OEE.MachineInterface and tt.Sdate=#OEE.Sdate
		and tt.StartDate=#OEE.StartDate and tt.EndDate=#OEE.EndDate



end

------------------------------------------------------------------No of Setting time calc ends----------------------------------------------------------------------------------------------

----------------------------------------------------------------Operating time (utilised time) --------------------------------------------------------------------------------
UPDATE #OEE SET OperatingTime = isnull(OperatingTime,0) + isNull(t2.cycle,0)
from
(select      mc,Sdate,StartDate,EndDate,sum(cycletime+loadunload) as cycle
from #T_autodata autodata --ER0374
INNER JOIN #OEE T on T.MachineInterface=autodata.mc
where (autodata.msttime>=T.StartDate)
and (autodata.ndtime<=T.EndDate)
and (autodata.datatype=1)
group by autodata.mc,Sdate,StartDate,EndDate
) as t2 inner join #OEE on t2.mc = #OEE.machineinterface and t2.Sdate=#OEE.Sdate
and t2.StartDate=#OEE.StartDate and t2.EndDate=#OEE.EndDate


-- Type 2
UPDATE #OEE SET OperatingTime = isnull(OperatingTime,0) + isNull(t2.cycle,0)
from
(select  mc,Sdate,StartDate,EndDate,SUM(DateDiff(second, T.StartDate, ndtime)) cycle
from #T_autodata autodata --ER0374
INNER JOIN #OEE T on T.MachineInterface=autodata.mc
where (autodata.msttime<T.StartDate)
and (autodata.ndtime>T.StartDate)
and (autodata.ndtime<=T.EndDate)
and (autodata.datatype=1)
group by autodata.mc,Sdate,StartDate,EndDate
) as t2 inner join #OEE on t2.mc = #OEE.machineinterface and t2.Sdate=#OEE.Sdate
and t2.StartDate=#OEE.StartDate and t2.EndDate=#OEE.EndDate

-- Type 3
UPDATE  #OEE SET OperatingTime = isnull(OperatingTime,0) + isNull(t2.cycle,0)
from
(select  mc,Sdate,StartDate,EndDate,sum(DateDiff(second, mstTime, T.EndDate)) cycle
from #T_autodata autodata --ER0374
INNER JOIN #OEE T on T.MachineInterface=autodata.mc
where (autodata.msttime>=T.StartDate)
and (autodata.msttime<T.EndDate)
and (autodata.ndtime>T.EndDate)
and (autodata.datatype=1)
group by autodata.mc,Sdate,StartDate,EndDate
) as t2 inner join #OEE on t2.mc = #OEE.machineinterface and t2.Sdate=#OEE.Sdate
and t2.StartDate=#OEE.StartDate and t2.EndDate=#OEE.EndDate

-- Type 4
UPDATE #OEE SET OperatingTime = isnull(OperatingTime,0) + isnull(t2.cycle,0)
from
(select mc,Sdate,StartDate,EndDate,
sum(DateDiff(second, T.StartDate, T.EndDate)) cycle from #T_autodata autodata --ER0374
INNER JOIN #OEE T on T.MachineInterface=autodata.mc
where (autodata.msttime<T.StartDate)
and (autodata.ndtime>T.EndDate)
and (autodata.datatype=1)
group by autodata.mc,Sdate,StartDate,EndDate
)as t2 inner join #OEE on t2.mc = #OEE.machineinterface and t2.Sdate=#OEE.Sdate
and t2.StartDate=#OEE.StartDate and t2.EndDate=#OEE.EndDate


/* Fetching Down Records from Production Cycle  */
/* If Down Records of TYPE-2*/
UPDATE  #OEE SET OperatingTime = isnull(OperatingTime,0) - isNull(t2.Down,0)
FROM
(Select AutoData.mc ,T.Sdate,T.StartDate,T.EndDate,
SUM(
CASE
	When autodata.sttime <= T.StartDate Then datediff(s, T.StartDate,autodata.ndtime )
	When autodata.sttime > T.StartDate Then datediff(s , autodata.sttime,autodata.ndtime)
END) as Down
From #T_autodata AutoData 
INNER JOIN #OEE T on T.MachineInterface=autodata.mc
INNER Join --ER0374
	(Select mc,Sttime,NdTime,Sdate,StartDate,EndDate From #T_autodata AutoData
	INNER JOIN #OEE T on T.MachineInterface=autodata.mc
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(msttime < T.StartDate)And (ndtime > T.StartDate) AND (ndtime <= T.EndDate)) as T1
ON AutoData.mc=T1.mc and T.Sdate=T1.Sdate AND T.StartDate=T1.StartDate AND T.EndDate=T1.EndDate
Where AutoData.DataType=2
And ( autodata.Sttime > T1.Sttime )
And ( autodata.ndtime <  T1.ndtime )
AND ( autodata.ndtime >  T.StartDate )
GROUP BY AUTODATA.mc,T.Sdate,T.StartDate,T.EndDate)AS T2 Inner Join #OEE on t2.mc = #OEE.machineinterface and t2.Sdate=#OEE.Sdate
and t2.StartDate=#OEE.StartDate and t2.EndDate=#OEE.EndDate

/* If Down Records of TYPE-3*/
UPDATE  #OEE SET OperatingTime = isnull(OperatingTime,0) - isNull(t2.Down,0)
FROM
(Select AutoData.mc ,T.Sdate,T.StartDate,T.EndDate,
SUM(CASE
	When autodata.ndtime > T.EndDate Then datediff(s,autodata.sttime, T.EndDate )
	When autodata.ndtime <=T.EndDate Then datediff(s , autodata.sttime,autodata.ndtime)
END) as Down 
From #T_autodata AutoData 
INNER JOIN #OEE T on T.MachineInterface=autodata.mc
INNER Join --ER0374
	(Select mc,Sttime,NdTime,Sdate,StartDate,EndDate From #T_autodata AutoData
	INNER JOIN #OEE T on T.MachineInterface=autodata.mc
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(sttime >= T.StartDate)And (ndtime > T.EndDate) and (sttime<T.EndDate) ) as T1
ON AutoData.mc=T1.mc and T.Sdate=T1.Sdate AND T.StartDate=T1.StartDate AND T.EndDate=T1.EndDate
Where AutoData.DataType=2
And (T1.Sttime < autodata.sttime  )
And ( T1.ndtime >  autodata.ndtime)
AND (autodata.sttime  <  T.EndDate)
GROUP BY AUTODATA.mc,T.Sdate,T.StartDate,T.EndDate)AS T2 Inner Join #OEE on t2.mc = #OEE.machineinterface and t2.Sdate=#OEE.Sdate
and t2.StartDate=#OEE.StartDate and t2.EndDate=#OEE.EndDate

/* If Down Records of TYPE-4*/
UPDATE  #OEE SET OperatingTime = isnull(OperatingTime,0) - isNull(t2.Down,0)
FROM
(Select AutoData.mc ,T.Sdate,T.StartDate,T.EndDate,
SUM(CASE
	When autodata.sttime >= T.StartDate AND autodata.ndtime <= T.EndDate Then datediff(s , autodata.sttime,autodata.ndtime)
	When autodata.sttime < T.StartDate AND autodata.ndtime > T.StartDate AND autodata.ndtime<=T.EndDate Then datediff(s, T.StartDate,autodata.ndtime )
	When autodata.sttime>=T.StartDate And autodata.sttime < T.EndDate AND autodata.ndtime > T.EndDate Then datediff(s,autodata.sttime, T.EndDate )
	When autodata.sttime<T.StartDate AND autodata.ndtime>T.EndDate   Then datediff(s , T.StartDate,T.EndDate)
--DR0236 - KarthikG - 19/Jun/2010 :: Till Here
END) as Down
From #T_autodata AutoData 
INNER JOIN #OEE T on T.MachineInterface=autodata.mc
INNER Join --ER0374
	(Select mc,Sttime,NdTime,Sdate,StartDate,EndDate From #T_autodata AutoData
	INNER JOIN #OEE T on T.MachineInterface=autodata.mc
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(msttime < T.StartDate)And (ndtime > T.EndDate) ) as T1
ON AutoData.mc=T1.mc and T.Sdate=T1.Sdate AND T.StartDate=T1.StartDate AND T.EndDate=T1.EndDate
Where AutoData.DataType=2
And (T1.Sttime < autodata.sttime  )
And ( T1.ndtime >  autodata.ndtime)
AND (autodata.ndtime  >  T.StartDate)
AND (autodata.sttime  <  T.EndDate)
GROUP BY AUTODATA.mc,T.Sdate,T.StartDate,T.EndDate
)AS T2 Inner Join #OEE on t2.mc = #OEE.machineinterface and t2.Sdate=#OEE.Sdate
and t2.StartDate=#OEE.StartDate and t2.EndDate=#OEE.EndDate


--mod 4:Get utilised time over lapping with PDT.
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
BEGIN

	UPDATE #PLD set pPlannedDT =isnull(pPlannedDT,0) + isNull(TT.PPDT ,0)
	FROM(
		--Production Time in PDT
		SELECT autodata.MC,T.Sdate,T.StartDate,T.EndDate,SUM
			(CASE
--			WHEN autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.cycletime+autodata.loadunload) --DR0325 Commented
			WHEN autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN DateDiff(second,autodata.msttime,autodata.ndtime) --DR0325 Added
			WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )
			WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END)  as PPDT
			FROM (select M.machineid,mc,msttime,ndtime,Sdate,StartDate,EndDate from #T_autodata autodata
				INNER JOIN #OEE T on T.MachineInterface=autodata.mc
				inner join machineinformation M on M.interfaceid=Autodata.mc
				 where autodata.DataType=1 And 
				((autodata.msttime >= T.StartDate  AND autodata.ndtime <=T.EndDate)
				OR ( autodata.msttime < T.StartDate  AND autodata.ndtime <= T.EndDate AND autodata.ndtime > T.StartDate )
				OR ( autodata.msttime >= T.StartDate   AND autodata.msttime <T.EndDate AND autodata.ndtime > T.EndDate )
				OR ( autodata.msttime < T.StartDate  AND autodata.ndtime > T.EndDate))
				)
		AutoData inner jOIN #PlannedDownTimes T on T.Machineid=AutoData.machineid and T.Sdate=autodata.Sdate AND T.StartDate=autodata.StartDate AND T.EndDate=autodata.EndDate
		WHERE 
			(
			(autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )
		group by autodata.mc,T.Sdate,T.StartDate,T.EndDate
	)
	 as TT INNER JOIN #PLD ON TT.mc = #PLD.MachineInterface and tt.Sdate=#PLD.Sdate
	and tt.StartDate=#PLD.StartDate and tt.EndDate=#PLD.EndDate


		--mod 4(4):Handle intearction between ICD and PDT for type 1 production record for the selected time period.
		UPDATE  #PLD set IPlannedDT =isnull(IPlannedDT,0) + isNull(T2.IPDT ,0) 	FROM	(
		Select T1.mc,T1.Sdate,T1.StartDate,T1.EndDate,SUM(
			CASE 	
				When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1
				When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2
				When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3
				when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4
			END) as IPDT from
		(Select A.mc,Sdate,StartDate,EndDate,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype from #T_autodata A
		INNER JOIN #OEE T on T.MachineInterface=A.mc
		Where A.DataType=2
		and exists 
			(
			Select B.Sttime,B.NdTime,B.mc From #T_autodata B
			INNER JOIN #OEE T on T.MachineInterface=b.mc
			Where B.mc = A.mc and
			B.DataType=1 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And
			(B.msttime >= T.StartDate AND B.ndtime <= T.EndDate) and
			--(B.sttime < A.sttime) AND (B.ndtime > A.ndtime) --DR0339
			  (B.sttime <= A.sttime) AND (B.ndtime >= A.ndtime) --DR0339
			)
		 )as T1 
		 inner join
		(select  machine,T.Sdate,T.StartDate,T.EndDate,Case when starttime<T.StartDate then T.StartDate else starttime end as starttime, 
		case when endtime> T.EndDate then T.EndDate else endtime end as endtime from dbo.PlannedDownTimes 
				 INNER JOIN #OEE T on T.MachineID=PlannedDownTimes.Machine
		where ((( StartTime >=T.StartDate) And ( EndTime <=T.EndDate))
		or (StartTime < T.StartDate  and  EndTime <= T.EndDate AND EndTime > T.StartDate)
		or (StartTime >= T.StartDate  AND StartTime <T.EndDate AND EndTime > T.EndDate)
		or (( StartTime <T.StartDate) And ( EndTime >T.EndDate )) )
		)T
		on T1.machine=T.machine AND  T1.Sdate=T.Sdate AND T1.StartDate=T.StartDate AND T1.EndDate=T.EndDate AND
		((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
		or (T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
		or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
		or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) 
		)group by T1.mc,T1.Sdate,T1.StartDate,T1.EndDate
		)AS T2  INNER JOIN #PLD ON T2.mc = #PLD.MachineInterface and T2.Sdate=#PLD.Sdate
		and T2.StartDate=#PLD.StartDate and T2.EndDate=#PLD.EndDate
		---mod 4(4)

		UPDATE  #PLD set IPlannedDT =isnull(IPlannedDT,0) + isNull(T2.IPDT ,0) 	FROM	(
		Select T1.mc,T1.Sdate,T1.StartDate,T1.EndDate,SUM(
		CASE 	
			When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1
			When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2
			When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3
			when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT from
		(Select A.mc,Sdate,StartDate,EndDate,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype from #T_autodata A
		INNER JOIN #OEE T on T.MachineInterface=A.mc
		Where A.DataType=2
		and exists 
		(
		Select B.Sttime,B.NdTime From #T_autodata B
		INNER JOIN #OEE T on T.MachineInterface=B.mc
		Where B.mc = A.mc and
		B.DataType=1 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And
		(B.msttime < T.StartDate And B.ndtime > T.StartDate AND B.ndtime <= T.EndDate) 
		And ((A.Sttime > B.Sttime) And ( A.ndtime < B.ndtime) AND ( A.ndtime > T.StartDate ))
		)
		)as T1
		inner join
		(select  machine,T.Sdate,T.StartDate,T.EndDate,Case when starttime<t.StartDate then T.StartDate else starttime end as starttime, 
		case when endtime> T.EndDate then T.EndDate else endtime end as endtime from dbo.PlannedDownTimes 
		INNER JOIN #OEE T on T.MachineID=PlannedDownTimes.Machine
		where ((( StartTime >=T.StartDate) And ( EndTime <=T.EndDate))
		or (StartTime < T.StartDate  and  EndTime <= T.EndDate AND EndTime > T.StartDate)
		or (StartTime >= T.StartDate  AND StartTime <T.EndDate AND EndTime > T.EndDate)
		or (( StartTime <T.StartDate) And ( EndTime >T.EndDate )) )
		)T
		on T1.machine=T.machine AND  T1.Sdate=T.Sdate AND T1.StartDate=T.StartDate AND T1.EndDate=T.EndDate AND
		(( T.StartTime >= T1.StartDate ) And ( T.StartTime <  T1.ndtime )) group by T1.mc,T1.Sdate,T1.StartDate,T1.EndDate
		)AS T2  INNER JOIN #PLD ON T2.mc = #PLD.MachineInterface and T2.Sdate=#PLD.Sdate
		and T2.StartDate=#PLD.StartDate and T2.EndDate=#PLD.EndDate
	
		/* If production Records of TYPE-3*/
		UPDATE  #PLD set IPlannedDT =isnull(IPlannedDT,0) + isNull(T2.IPDT ,0)FROM (
		Select T1.mc,T1.Sdate,T1.StartDate,T1.EndDate,SUM(
		CASE 	
			When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1
			When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2
			When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3
			when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT from
		(Select A.mc,Sdate,StartDate,EndDate,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype from #T_autodata A
		INNER JOIN #OEE T on T.MachineInterface=A.mc
		Where A.DataType=2
		and exists 
		(
		Select B.Sttime,B.NdTime From #T_autodata B
		INNER JOIN #OEE T on T.MachineInterface=B.mc
		Where B.mc = A.mc and
		B.DataType=1 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And
		(B.sttime >= T.StartDate And B.ndtime > T.EndDate and B.sttime <T.EndDate) and
		((B.Sttime < A.sttime  )And ( B.ndtime > A.ndtime) AND (A.msttime < T.EndDate))
		)
		)as T1 
		inner join
		(select  machine,T.Sdate,T.StartDate,T.EndDate,Case when starttime<T.StartDate then T.StartDate else starttime end as starttime, 
		case when endtime> T.EndDate then T.EndDate else endtime end as endtime from dbo.PlannedDownTimes 
		INNER JOIN #OEE T on T.MachineID=PlannedDownTimes.Machine
		where ((( StartTime >=T.StartDate) And ( EndTime <=T.EndDate))
		or (StartTime < T.StartDate  and  EndTime <= T.EndDate AND EndTime > T.StartDate)
		or (StartTime >= T.StartDate  AND StartTime <T.EndDate AND EndTime > T.EndDate)
		or (( StartTime <T.StartDate) And ( EndTime >T.EndDate )) )
		)T
		on T1.machine=T.machine AND  T1.Sdate=T.Sdate AND T1.StartDate=T.StartDate AND T1.EndDate=T.EndDate 
		AND (( T.EndTime > T1.Sttime )And ( T.EndTime <=T1.EndDate )) group by T1.mc,T1.Sdate,T1.StartDate,T1.EndDate
		)AS T2  INNER JOIN #PLD ON T2.mc = #PLD.MachineInterface and T2.Sdate=#PLD.Sdate
		and T2.StartDate=#PLD.StartDate and T2.EndDate=#PLD.EndDate
	
	
	/* If production Records of TYPE-4*/
	UPDATE  #PLD set IPlannedDT =isnull(IPlannedDT,0) + isNull(T2.IPDT ,0)FROM (
	Select T1.mc,T1.Sdate,T1.StartDate,T1.EndDate,SUM(
	CASE 	
		When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1
		When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2
		When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3
		when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT from
	(Select A.mc,Sdate,StartDate,EndDate,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype from #T_autodata A
	INNER JOIN #OEE T on T.MachineInterface=A.mc
	Where A.DataType=2
	and exists 
	(
	Select B.Sttime,B.NdTime From #T_autodata B
	INNER JOIN #OEE T on T.MachineInterface=B.mc
	Where B.mc = A.mc and
	B.DataType=1 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And
	(B.msttime < T.StartDate And B.ndtime > T.EndDate)
	And ((B.Sttime < A.sttime)And ( B.ndtime >  A.ndtime)AND (A.ndtime  >  T.StartDate) AND (A.sttime  <  T.EndDate))
	)
	)as T1 
	inner join
		(select  machine,T.Sdate,T.StartDate,T.EndDate,Case when starttime<T.StartDate then T.StartDate else starttime end as starttime, 
		case when endtime> T.EndDate then T.EndDate else endtime end as endtime from dbo.PlannedDownTimes 
		INNER JOIN #OEE T on T.MachineID=PlannedDownTimes.Machine
		where ((( StartTime >=T.StartDate) And ( EndTime <=T.EndDate))
		or (StartTime < T.StartDate  and  EndTime <= T.EndDate AND EndTime > T.StartDate)
		or (StartTime >= T.StartDate  AND StartTime <T.EndDate AND EndTime > T.EndDate)
		or (( StartTime <T.StartDate) And ( EndTime >T.EndDate )) )
		)T
		on T1.machine=T.machine AND  T1.Sdate=T.Sdate AND T1.StartDate=T.StartDate AND T1.EndDate=T.EndDate  AND
	(( T.StartTime >=T1.StartDate) And ( T.EndTime <=T1.EndDate )) group by T1.mc,T1.Sdate,T1.StartDate,T1.EndDate
	)AS T2  INNER JOIN #PLD ON T2.mc = #PLD.MachineInterface and T2.Sdate=#PLD.Sdate
		and T2.StartDate=#PLD.StartDate and T2.EndDate=#PLD.EndDate
  ------------------------------------ ER0374 Added Till Here ---------------------------------


END


-----------------------------------------------------------------------Utilization time (Operation time) ends-----------------------------------------------------------------------------------------

----------------------------------------------------------------------- ManagementLoss and Downtime Calculation Starts -------------------------------------------------------------------------------#
---Below IF condition added by Mrudula for mod 4. TO get the ML if 'Ignore_Dtime_4m_PLD'<>"Y"
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y')
BEGIN
		-- Type 1
		UPDATE #OEE SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
		from
		(select mc,Sdate,StartDate,EndDate,sum(
		CASE
		WHEN (loadunload) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
		THEN isnull(downcodeinformation.Threshold,0)
		ELSE loadunload
		END) AS LOSS
		from #T_autodata autodata  --ER0374
		INNER JOIN #OEE T on T.MachineInterface=autodata.mc
		INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
		where (autodata.msttime>=T.StartDate)
		and (autodata.ndtime<=T.EndDate)
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1) 
		and (downcodeinformation.ThresholdfromCO <>1) --NR0097
		group by autodata.mc,Sdate,StartDate,EndDate) as t2 inner join #OEE on t2.mc = #OEE.machineinterface AND T2.Sdate=#OEE.Sdate
		AND T2.StartDate=#OEE.StartDate AND T2.EndDate=#OEE.EndDate

		-- Type 2
		UPDATE #OEE SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
		from
		(select      mc,Sdate,StartDate,EndDate,sum(
		CASE WHEN DateDiff(second, T.StartDate, ndtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
		then isnull(downcodeinformation.Threshold,0)
		ELSE DateDiff(second, T.StartDate, ndtime)
		END)loss
		from #T_autodata autodata  --ER0374
		INNER JOIN #OEE T on T.MachineInterface=autodata.mc
		INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
		where (autodata.sttime<T.StartDate)
		and (autodata.ndtime>T.StartDate)
		and (autodata.ndtime<=T.EndDate)
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1)
		and (downcodeinformation.ThresholdfromCO <>1) --NR0097
		group by autodata.mc,Sdate,StartDate,EndDate
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface AND T2.Sdate=#OEE.Sdate
		AND T2.StartDate=#OEE.StartDate AND T2.EndDate=#OEE.EndDate

		-- Type 3
		UPDATE #OEE SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
		from
		(select      mc,Sdate,StartDate,EndDate,SUM(
		CASE WHEN DateDiff(second,stTime, T.EndDate) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
		then isnull(downcodeinformation.Threshold,0)
		ELSE DateDiff(second, stTime, T.EndDate)
		END)loss
		from #T_autodata autodata --ER0374
		INNER JOIN #OEE T on T.MachineInterface=autodata.mc
		INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
		where (autodata.msttime>=T.StartDate)
		and (autodata.sttime<T.EndDate)
		and (autodata.ndtime>T.EndDate)
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1)
		and (downcodeinformation.ThresholdfromCO <>1) --NR0097
		group by autodata.mc,Sdate,StartDate,EndDate
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface AND T2.Sdate=#OEE.Sdate
		AND T2.StartDate=#OEE.StartDate AND T2.EndDate=#OEE.EndDate

		-- Type 4
		UPDATE #OEE SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
		from
		(select mc,Sdate,StartDate,EndDate,sum(
		CASE WHEN DateDiff(second, T.StartDate, T.EndDate) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
		then isnull(downcodeinformation.Threshold,0)
		ELSE DateDiff(second, T.StartDate, T.EndDate)
		END)loss
		from #T_autodata autodata --ER0374
		INNER JOIN #OEE T on T.MachineInterface=autodata.mc
		INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
		where autodata.msttime<T.StartDate
		and autodata.ndtime>T.EndDate
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1)
		and (downcodeinformation.ThresholdfromCO <>1) --NR0097
		group by autodata.mc,Sdate,StartDate,EndDate
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface AND T2.Sdate=#OEE.Sdate
		AND T2.StartDate=#OEE.StartDate AND T2.EndDate=#OEE.EndDate

		---get the downtime for the time period
		UPDATE #OEE SET downtime = isnull(downtime,0) + isNull(t2.down,0)
		from
		(select mc,Sdate,StartDate,EndDate,sum(
				CASE
				WHEN  autodata.msttime>=T.StartDate  and  autodata.ndtime<=T.EndDate  THEN  loadunload
				WHEN (autodata.sttime<T.StartDate and  autodata.ndtime>T.StartDate and autodata.ndtime<=T.EndDate)  THEN DateDiff(second, T.StartDate, ndtime)
				WHEN (autodata.msttime>=T.StartDate  and autodata.sttime<T.EndDate  and autodata.ndtime>T.EndDate)  THEN DateDiff(second, stTime, T.EndDate)
				WHEN autodata.msttime<T.StartDate and autodata.ndtime>T.EndDate   THEN DateDiff(second, T.StartDate, T.EndDate)
				END
			)AS down
		from #T_autodata autodata --ER0374
		INNER JOIN #OEE T on T.MachineInterface=autodata.mc
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		where autodata.datatype=2 AND
		(
		(autodata.msttime>=T.StartDate  and  autodata.ndtime<=T.EndDate)
		OR (autodata.sttime<T.StartDate and  autodata.ndtime>T.StartDate and autodata.ndtime<=T.EndDate)
		OR (autodata.msttime>=T.StartDate  and autodata.sttime<T.EndDate  and autodata.ndtime>T.EndDate)
		OR (autodata.msttime<T.StartDate and autodata.ndtime>T.EndDate )
		)
		group by autodata.mc,Sdate,StartDate,EndDate
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface  AND T2.Sdate=#OEE.Sdate
		AND T2.StartDate=#OEE.StartDate AND T2.EndDate=#OEE.EndDate
--mod 4
End
--mod 4
---mod 4: Handling interaction between PDT and downtime . Also interaction between PDT and Management Loss
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN
	---step 1
	
	UPDATE #OEE SET downtime = isnull(downtime,0) + isNull(t2.down,0)
	from
	(select mc,Sdate,StartDate,EndDate,sum(
			CASE
	        WHEN  autodata.msttime>=T.StartDate  and  autodata.ndtime<=T.EndDate  THEN  loadunload
			WHEN (autodata.sttime<T.StartDate and  autodata.ndtime>T.StartDate and autodata.ndtime<=T.EndDate)  THEN DateDiff(second, T.StartDate, ndtime)
			WHEN (autodata.msttime>=T.StartDate  and autodata.sttime<T.EndDate  and autodata.ndtime>T.EndDate)  THEN DateDiff(second, stTime, T.EndDate)
			WHEN autodata.msttime<T.StartDate and autodata.ndtime>T.EndDate   THEN DateDiff(second, T.StartDate, T.EndDate)
			END
		)AS down
	from #T_autodata autodata --ER0374
	INNER JOIN #OEE T on T.MachineInterface=autodata.mc
	inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
	where autodata.datatype=2 AND
	(
	(autodata.msttime>=T.StartDate  and  autodata.ndtime<=T.EndDate)
	OR (autodata.sttime<T.StartDate and  autodata.ndtime>T.StartDate and autodata.ndtime<=T.EndDate)
	OR (autodata.msttime>=T.StartDate  and autodata.sttime<T.EndDate  and autodata.ndtime>T.EndDate)
	OR (autodata.msttime<T.StartDate and autodata.ndtime>T.EndDate )
	) AND (downcodeinformation.availeffy = 0)
	group by autodata.mc,Sdate,StartDate,EndDate
	) as t2 inner join #OEE on t2.mc = #OEE.machineinterface AND T2.Sdate=#OEE.Sdate
		AND T2.StartDate=#OEE.StartDate AND T2.EndDate=#OEE.EndDate

	---step 2
	---mod 4 checking for (downcodeinformation.availeffy = 0) to get the overlapping PDT and Downs which is not ML
	UPDATE #PLD set dPlannedDT =isnull(dPlannedDT,0) + isNull(TT.PPDT ,0)
	FROM(
		--Production PDT
		SELECT autodata.MC,T.Sdate,T.StartDate,T.EndDate, SUM
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
			) AND (downcodeinformation.availeffy = 0)
		group by autodata.mc,T.Sdate,T.StartDate,T.EndDate
	) as TT INNER JOIN #PLD ON TT.mc = #PLD.MachineInterface AND TT.Sdate=#PLD.Sdate
		AND TT.StartDate=#PLD.StartDate AND TT.EndDate=#PLD.EndDate

	---step 3
	---Management loss calculation
	---IN T1 Select get all the downtimes which is of type management loss
	---IN T2  get the time to be deducted from the cycle if the cycle is overlapping with the PDT. And it should be ML record
	---In T3 Get the real management loss , and time to be considered as real down for each cycle(by comaring with the ML threshold)
	---In T4 consolidate everything at machine level and update the same to #OEE for ManagementLoss and MLDown
	
	UPDATE #OEE SET  ManagementLoss = isnull(ManagementLoss,0) + isNull(t4.Mloss,0),MLDown=isNull(MLDown,0)+isNull(t4.Dloss,0)
	from
	(select T3.mc,T3.Sdate,T3.StartDate,T3.EndDate,sum(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss from (
	select   t1.id,T1.mc,T1.Threshold,T1.Sdate,T1.StartDate,T1.EndDate,
	case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0
	then DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)- isnull(T1.Threshold ,0)
	else 0 End  as Dloss,
	case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0
	then isnull(T1.Threshold,0)
	else (DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)) End  as Mloss
	 from
	
	(   select id,mc,comp,opn,opr,D.threshold,T.Sdate,T.StartDate,T.EndDate,
		case when autodata.sttime<T.StartDate then T.StartDate else sttime END as sttime,
	       	case when ndtime>T.EndDate then T.EndDate else ndtime END as ndtime
		from #T_autodata autodata --ER0374
		INNER JOIN #OEE T on T.MachineInterface=autodata.mc
		inner join downcodeinformation D
		on autodata.dcode=D.interfaceid where autodata.datatype=2 AND
		(
		(autodata.sttime>=T.StartDate  and  autodata.ndtime<=T.EndDate)
		OR (autodata.sttime<T.StartDate and  autodata.ndtime>T.StartDate and autodata.ndtime<=T.EndDate)
		OR (autodata.sttime>=T.StartDate  and autodata.sttime<T.EndDate  and autodata.ndtime>T.EndDate)
		OR (autodata.sttime<T.StartDate and autodata.ndtime>T.EndDate )
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
			AND (downcodeinformation.availeffy = 1) 
			AND (downcodeinformation.ThresholdfromCO <>1) --NR0097 
			group  by autodata.id ) as T2 on T1.id=T2.id ) as T3  group by T3.mc,T3.Sdate,T3.StartDate,T3.EndDate
	) as t4 inner join #OEE on t4.mc = #OEE.machineinterface AND T4.Sdate=#OEE.Sdate AND T4.StartDate=T4.StartDate AND T4.EndDate=#OEE.EndDate


	---mod 4 checking for (downcodeinformation.availeffy = 1) to get the overlapping PDT and Downs which is ML
	UPDATE #PLD set MPlannedDT =isnull(MPlannedDT,0) + isNull(TT.PPDT ,0)
	FROM(
		--Production PDT
		SELECT autodata.MC,T.Sdate,T.StartDate,T.EndDate, SUM
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
			)  AND (downcodeinformation.availeffy = 1) 
			AND (downcodeinformation.ThresholdfromCO <>1) --NR0097 
		group by autodata.mc,T.Sdate,T.StartDate,T.EndDate
	) as TT INNER JOIN #PLD ON TT.mc = #PLD.MachineInterface AND TT.Sdate=#PLD.Sdate AND TT.StartDate=#PLD.StartDate AND TT.EndDate=#PLD.EndDate



		UPDATE #OEE SET downtime = isnull(downtime,0)+isNull(MLDown,0)

	
END

----------------------------- NR0097 Added From here ----------------------------------------------
select autodata.id,autodata.mc,autodata.comp,autodata.opn,
isnull(CO.Stdsetuptime,0)AS Stdsetuptime ,T.Sdate,T.StartDate,T.EndDate, 
sum(case
when autodata.sttime>=T.StartDate and autodata.ndtime<=T.EndDate then autodata.loadunload
when autodata.sttime<T.StartDate and autodata.ndtime>T.StartDate and autodata.ndtime<=T.EndDate then Datediff(s,T.StartDate,ndtime)
when autodata.sttime>=T.StartDate and autodata.sttime<T.EndDate and autodata.ndtime>T.EndDate then  datediff(s,sttime,T.EndDate)
when autodata.sttime<T.StartDate and autodata.ndtime>T.EndDate then  datediff(s,T.StartDate,T.EndDate)
end) as setuptime,0 as ML,0 as Downtime
into #setuptime
from #T_autodata autodata --ER0374
INNER JOIN #OEE T on T.MachineInterface=autodata.mc
inner join machineinformation M on autodata.mc = M.interfaceid
inner join downcodeinformation D on autodata.dcode=D.interfaceid
left outer join componentinformation CI on autodata.comp = CI.interfaceid
left outer join componentoperationpricing CO on autodata.opn =  CO.interfaceid and CI.componentid = CO.componentid and CO.machineid = M.machineid
where autodata.datatype=2 and D.ThresholdfromCO = 1
And
((autodata.sttime>=T.StartDate and autodata.ndtime<=T.EndDate) or
 (autodata.sttime<T.StartDate and autodata.ndtime>T.StartDate and autodata.ndtime<=T.EndDate)or
 (autodata.sttime>=T.StartDate and autodata.sttime<T.EndDate and autodata.ndtime>T.EndDate)or
 (autodata.sttime<T.StartDate and autodata.ndtime>T.EndDate))
group by autodata.id,autodata.mc,autodata.comp,autodata.opn,CO.Stdsetuptime,T.Sdate,T.StartDate,T.EndDate

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN
	update #setuptime set setuptime = isnull(setuptime,0) - isnull(t1.setuptime_pdt,0) from 
	(
		select autodata.id,autodata.mc,autodata.comp,autodata.opn,T.Sdate,T.StartDate,T.EndDate,
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
		((autodata.sttime>=T.StartDate and autodata.ndtime<=T.EndDate) or
		 (autodata.sttime<T.StartDate and autodata.ndtime>T.StartDate and autodata.ndtime<=T.EndDate)or
		 (autodata.sttime>=T.StartDate and autodata.sttime<T.EndDate and autodata.ndtime>T.EndDate)or
		 (autodata.sttime<T.StartDate and autodata.ndtime>T.EndDate))
		group by autodata.id,autodata.mc,autodata.comp,autodata.opn,T.Sdate,T.StartDate,T.EndDate
	) as t1 inner join #setuptime on t1.id=#setuptime.id and t1.mc = #setuptime.mc and #setuptime.comp = t1.comp and #setuptime.opn = t1.opn
	AND T1.Sdate=#setuptime.Sdate AND T1.StartDate=#setuptime.StartDate AND T1.EndDate=#setuptime.EndDate


	Update #setuptime set Downtime = isnull(Downtime,0) + isnull(T1.Setupdown,0) from
	(Select id,mc,comp,opn,Sdate,StartDate,EndDate,
	Case when setuptime>stdsetuptime then setuptime-stdsetuptime else 0 end as Setupdown
	from #setuptime)T1  inner join #setuptime on t1.id=#setuptime.id and t1.mc = #setuptime.mc and #setuptime.comp = t1.comp and #setuptime.opn = t1.opn
	AND T1.Sdate=#setuptime.Sdate AND T1.StartDate=#setuptime.StartDate AND T1.EndDate=#setuptime.EndDate
End

Update #setuptime set ML = Isnull(ML,0) + isnull(T1.SetupML,0) from
(Select id,mc,comp,opn,Sdate,StartDate,EndDate,
Case when setuptime<stdsetuptime then setuptime else stdsetuptime end as SetupML
from #setuptime)T1  inner join #setuptime on t1.id=#setuptime.id and t1.mc = #setuptime.mc and #setuptime.comp = t1.comp and #setuptime.opn = t1.opn
AND T1.Sdate=#setuptime.Sdate AND T1.StartDate=#setuptime.StartDate AND T1.EndDate=#setuptime.EndDate

----------------------------- NR0097 Added Till here ----------------------------------------------


---mod 4: Till here Handling interaction between PDT and downtime . Also interaction between PDT and Management Loss
---mod 4:If Ignore_Dtime_4m_PLD<> Y and Ignore_Dtime_4m_PLD<> N
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y' AND (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
BEGIN
	UPDATE #PLD set dPlannedDT =isnull(dPlannedDT,0) + isNull(TT.PPDT ,0)
	FROM(
		--Production PDT
		SELECT autodata.MC,T.Sdate,T.StartDate,T.EndDate, SUM
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
		group by autodata.mc,T.Sdate,T.StartDate,T.EndDate
	) as TT INNER JOIN #PLD ON TT.mc = #PLD.MachineInterface AND TT.Sdate=#PLD.Sdate AND TT.StartDate=#PLD.StartDate AND TT.EndDate=#PLD.EndDate

END
---mod 4:If Ignore_Dtime_4m_PLD<> Y and Ignore_Dtime_4m_PLD<> N

--UPDATE #OEE
--	SET OperatingTime=(OperatingTime-ISNULL(#PLD.pPlannedDT,0)+isnull(#PLD.IPlannedDT,0)),
--	   DownTime=(DownTime-ISNULL(#PLD.dPlannedDT,0)) 
--	From #OEE Inner Join #PLD on #PLD.Machineid=#OEE.Machineid

UPDATE #OEE SET OperatingTime=ISNULL(T1.OT,0),
DownTime=ISNULL(T1.DT,0)
FROM(
SELECT O.MachineID,O.Sdate,O.StartDate,O.EndDate,(OperatingTime-ISNULL(P.pPlannedDT,0)+isnull(P.IPlannedDT,0)) AS OT,
(DownTime-ISNULL(P.dPlannedDT,0)) AS DT From #OEE O
Inner Join #PLD P on P.Machineid=O.Machineid AND P.Sdate=O.Sdate AND P.StartDate=O.StartDate AND P.EndDate=O.EndDate
)T1 INNER JOIN #OEE T2 ON T1.MachineID=T2.MachineID AND T1.Sdate=T2.Sdate AND T1.StartDate=T2.StartDate AND T1.EndDate=T2.EndDate

-------------------------------------------------------------------Down and Management  Calculation Ends-----------------------------------------------------------------------


---------------------------------------------------------------------Planned Loss Calculation starts----------------------------------------------------------------------------

update #OEE set PlannedLoss=isnull(PlannedLoss,0)+t1.plndloss
from
(
select MachineID,Sdate,StartDate,EndDate,(TotalTime-(OperatingTime+DownTime)) as plndloss from #OEE
)t1 inner join #OEE T2 on t1.MachineID=T2.MachineID AND T1.Sdate=T2.Sdate AND T1.StartDate=T2.StartDate AND T1.EndDate=T2.EndDate

---------------------------------------------------------------------Planned Loss Calculation ends----------------------------------------------------------------------------

 --------------------------------------------------------------------OEE EXCLUSION Time cal starts----------------------------------------------------------------------------
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N'
BEGIN
	UPDATE #OEE SET OEEExclusionTime = isnull(OEEExclusionTime,0) + isNull(t2.oeedown,0)
		from
		(select mc,T.Sdate,T.StartDate,T.EndDate,sum(
				CASE
				WHEN  autodata.msttime>=T.StartDate  and  autodata.ndtime<=T.EndDate  THEN  loadunload
				WHEN (autodata.sttime<T.StartDate and  autodata.ndtime>T.StartDate and autodata.ndtime<=T.EndDate)  THEN DateDiff(second, T.StartDate, ndtime)
				WHEN (autodata.msttime>=T.StartDate  and autodata.sttime<T.EndDate  and autodata.ndtime>T.EndDate)  THEN DateDiff(second, stTime, T.EndDate)
				WHEN autodata.msttime<T.StartDate and autodata.ndtime>T.EndDate   THEN DateDiff(second, T.StartDate, T.EndDate)
				END
			)AS oeedown
		from #T_autodata autodata --ER0374
		INNER JOIN #OEE T on T.MachineInterface=autodata.mc
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		where autodata.datatype=2 AND
		(
		(autodata.msttime>=T.StartDate  and  autodata.ndtime<=T.EndDate)
		OR (autodata.sttime<T.StartDate and  autodata.ndtime>T.StartDate and autodata.ndtime<=T.EndDate)
		OR (autodata.msttime>=T.StartDate  and autodata.sttime<T.EndDate  and autodata.ndtime>T.EndDate)
		OR (autodata.msttime<T.StartDate and autodata.ndtime>T.EndDate )
		) and Catagory in ('OEE EXCLUSION')
		--)and Catagory in ('Operator')
		group by autodata.mc,T.Sdate,T.StartDate,T.EndDate
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface AND T2.Sdate=#OEE.Sdate AND T2.StartDate=#OEE.StartDate AND T2.EndDate=#OEE.EndDate
end


If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN
	UPDATE #OEE SET OEEExclusionTime = isnull(OEEExclusionTime,0) + isNull(t2.oeedown,0)
		from
		(select mc,T.Sdate,T.StartDate,T.EndDate,sum(
				CASE
				WHEN  autodata.msttime>=T.StartDate  and  autodata.ndtime<=T.EndDate  THEN  loadunload
				WHEN (autodata.sttime<T.StartDate and  autodata.ndtime>T.StartDate and autodata.ndtime<=T.EndDate)  THEN DateDiff(second, T.StartDate, ndtime)
				WHEN (autodata.msttime>=T.StartDate  and autodata.sttime<T.EndDate  and autodata.ndtime>T.EndDate)  THEN DateDiff(second, stTime, T.EndDate)
				WHEN autodata.msttime<T.StartDate and autodata.ndtime>T.EndDate   THEN DateDiff(second, T.StartDate, T.EndDate)
				END
			)AS oeedown
		from #T_autodata autodata --ER0374
		INNER JOIN #OEE T on T.MachineInterface=autodata.mc
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		where autodata.datatype=2 AND
		(
		(autodata.msttime>=T.StartDate  and  autodata.ndtime<=T.EndDate)
		OR (autodata.sttime<T.StartDate and  autodata.ndtime>T.StartDate and autodata.ndtime<=T.EndDate)
		OR (autodata.msttime>=T.StartDate  and autodata.sttime<T.EndDate  and autodata.ndtime>T.EndDate)
		OR (autodata.msttime<T.StartDate and autodata.ndtime>T.EndDate )
		) and Catagory in ('OEE EXCLUSION')
		--)and Catagory in ('Operator')
		group by autodata.mc,T.Sdate,T.StartDate,T.EndDate
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface AND T2.Sdate=#OEE.Sdate AND T2.StartDate=#OEE.StartDate AND T2.EndDate=#OEE.EndDate

	UPDATE #OEE set OEEExclusionTime =isnull(OEEExclusionTime,0) - isNull(TT.PPDT ,0)
	FROM(
		SELECT autodata.MC,T.Sdate,T.StartDate,T.EndDate,SUM
		   (CASE
			WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PPDT
		from  #T_autodata autodata CROSS jOIN #PlannedDownTimes T
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)and downcodeinformation.Catagory in ('OEE EXCLUSION')
			--)and downcodeinformation.Catagory in ('Operator')
		group by autodata.MC,T.Sdate,T.StartDate,T.EndDate
	) as TT INNER JOIN #OEE ON TT.mc = #OEE.MachineInterface AND TT.Sdate=#OEE.Sdate AND TT.StartDate=#OEE.StartDate AND TT.EndDate=#OEE.EndDate
end
 --------------------------------------------------------------------OEE EXCLUSION Time cal ends----------------------------------------------------------------------

  --------------------------------------------------------------------SuperViser down cal starts----------------------------------------------------------------------------
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N'
BEGIN
	UPDATE #OEE SET SupervisorCategoryDowntime = isnull(SupervisorCategoryDowntime,0) + isNull(t2.oeedown,0)
		from
		(select mc,T.Sdate,T.StartDate,T.EndDate,sum(
				CASE
				WHEN  autodata.msttime>=T.StartDate  and  autodata.ndtime<=T.EndDate  THEN  loadunload
				WHEN (autodata.sttime<T.StartDate and  autodata.ndtime>T.StartDate and autodata.ndtime<=T.EndDate)  THEN DateDiff(second, T.StartDate, ndtime)
				WHEN (autodata.msttime>=T.StartDate  and autodata.sttime<T.EndDate  and autodata.ndtime>T.EndDate)  THEN DateDiff(second, stTime, T.EndDate)
				WHEN autodata.msttime<T.StartDate and autodata.ndtime>T.EndDate   THEN DateDiff(second, T.StartDate, T.EndDate)
				END
			)AS oeedown
		from #T_autodata autodata --ER0374
		INNER JOIN #OEE T on T.MachineInterface=autodata.mc
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		where autodata.datatype=2 AND
		(
		(autodata.msttime>=T.StartDate  and  autodata.ndtime<=T.EndDate)
		OR (autodata.sttime<T.StartDate and  autodata.ndtime>T.StartDate and autodata.ndtime<=T.EndDate)
		OR (autodata.msttime>=T.StartDate  and autodata.sttime<T.EndDate  and autodata.ndtime>T.EndDate)
		OR (autodata.msttime<T.StartDate and autodata.ndtime>T.EndDate )
		) and Catagory in ('SuperViser')
		group by autodata.mc,T.Sdate,T.StartDate,T.EndDate
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface AND T2.Sdate=#OEE.Sdate AND T2.StartDate=#OEE.StartDate AND T2.EndDate=#OEE.EndDate
end


If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN
	UPDATE #OEE SET SupervisorCategoryDowntime = isnull(SupervisorCategoryDowntime,0) + isNull(t2.oeedown,0)
		from
		(select mc,T.Sdate,T.StartDate,T.EndDate,sum(
				CASE
				WHEN  autodata.msttime>=T.StartDate  and  autodata.ndtime<=T.EndDate  THEN  loadunload
				WHEN (autodata.sttime<T.StartDate and  autodata.ndtime>T.StartDate and autodata.ndtime<=T.EndDate)  THEN DateDiff(second, T.StartDate, ndtime)
				WHEN (autodata.msttime>=T.StartDate  and autodata.sttime<T.EndDate  and autodata.ndtime>T.EndDate)  THEN DateDiff(second, stTime, T.EndDate)
				WHEN autodata.msttime<T.StartDate and autodata.ndtime>T.EndDate   THEN DateDiff(second, T.StartDate, T.EndDate)
				END
			)AS oeedown
		from #T_autodata autodata --ER0374
		INNER JOIN #OEE T on T.MachineInterface=autodata.mc
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		where autodata.datatype=2 AND
		(
		(autodata.msttime>=T.StartDate  and  autodata.ndtime<=T.EndDate)
		OR (autodata.sttime<T.StartDate and  autodata.ndtime>T.StartDate and autodata.ndtime<=T.EndDate)
		OR (autodata.msttime>=T.StartDate  and autodata.sttime<T.EndDate  and autodata.ndtime>T.EndDate)
		OR (autodata.msttime<T.StartDate and autodata.ndtime>T.EndDate )
		) and Catagory in ('SuperViser')
		group by autodata.mc,T.Sdate,T.StartDate,T.EndDate
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface AND T2.Sdate=#OEE.Sdate AND T2.StartDate=#OEE.StartDate AND T2.EndDate=#OEE.EndDate


	UPDATE #OEE set SupervisorCategoryDowntime =isnull(SupervisorCategoryDowntime,0) - isNull(TT.PPDT ,0)
	FROM(
		SELECT autodata.MC,T.Sdate,T.StartDate,T.EndDate,SUM
		   (CASE
			WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PPDT
		from  #T_autodata autodata CROSS jOIN #PlannedDownTimes T
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)and downcodeinformation.Catagory in ('SuperViser')
		group by autodata.MC,T.Sdate,T.StartDate,T.EndDate
	) as TT INNER JOIN #OEE ON TT.mc = #OEE.MachineInterface AND TT.Sdate=#OEE.Sdate AND TT.StartDate=#OEE.StartDate AND TT.EndDate=#OEE.EndDate
end
 --------------------------------------------------------------------SuperViser down Time cal ends----------------------------------------------------------------------

   --------------------------------------------------------------------Operator category down cal starts----------------------------------------------------------------------------
		UPDATE #OEE SET MLThresholdOperatorCat = isnull(MLThresholdOperatorCat,0) + isNull(t2.loss,0)
		from
		(select mc,T.Sdate,T.StartDate,T.EndDate,sum(
		CASE
		WHEN (loadunload) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
		THEN isnull(downcodeinformation.Threshold,0)
		ELSE loadunload
		END) AS LOSS
		from #T_autodata autodata  --ER0374
		INNER JOIN #OEE T on T.MachineInterface=autodata.mc
		INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
		where (autodata.msttime>=T.StartDate)
		and (autodata.ndtime<=T.EndDate)
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1) 
		and downcodeinformation.Catagory in ('Operator')
		and (downcodeinformation.ThresholdfromCO <>1) --NR0097
		group by autodata.mc,T.Sdate,T.StartDate,T.EndDate) as t2 inner join #OEE on t2.mc = #OEE.machineinterface AND T2.Sdate=#OEE.Sdate AND T2.StartDate=#OEE.StartDate AND T2.EndDate=#OEE.EndDate

		-- Type 2
		UPDATE #OEE SET MLThresholdOperatorCat = isnull(MLThresholdOperatorCat,0) + isNull(t2.loss,0)
		from
		(select      mc,T.Sdate,T.StartDate,T.EndDate,sum(
		CASE WHEN DateDiff(second, T.StartDate, ndtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
		then isnull(downcodeinformation.Threshold,0)
		ELSE DateDiff(second, T.StartDate, ndtime)
		END)loss
		--DateDiff(second, T.StartDate, ndtime)
		from #T_autodata autodata  --ER0374
		INNER JOIN #OEE T on T.MachineInterface=autodata.mc
		INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
		where (autodata.sttime<T.StartDate)
		and (autodata.ndtime>T.StartDate)
		and (autodata.ndtime<=T.EndDate)
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1)
		and downcodeinformation.Catagory in ('Operator')
		and (downcodeinformation.ThresholdfromCO <>1) --NR0097
		group by autodata.mc,T.Sdate,T.StartDate,T.EndDate
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface AND T2.Sdate=#OEE.Sdate AND T2.StartDate=#OEE.StartDate AND T2.EndDate=#OEE.EndDate

		-- Type 3
		UPDATE #OEE SET MLThresholdOperatorCat = isnull(MLThresholdOperatorCat,0) + isNull(t2.loss,0)
		from
		(select      mc,T.Sdate,T.StartDate,T.EndDate,SUM(
		CASE WHEN DateDiff(second,stTime, T.EndDate) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
		then isnull(downcodeinformation.Threshold,0)
		ELSE DateDiff(second, stTime, T.EndDate)
		END)loss
		-- sum(DateDiff(second, stTime, T.EndDate)) loss
		from #T_autodata autodata --ER0374
		INNER JOIN #OEE T on T.MachineInterface=autodata.mc
		INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
		where (autodata.msttime>=T.StartDate)
		and (autodata.sttime<T.EndDate)
		and (autodata.ndtime>T.EndDate)
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1)
		and (downcodeinformation.ThresholdfromCO <>1) --NR0097
		and downcodeinformation.Catagory in ('Operator')
		group by autodata.mc,T.Sdate,T.StartDate,T.EndDate
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface AND T2.Sdate=#OEE.Sdate AND T2.StartDate=#OEE.StartDate AND T2.EndDate=#OEE.EndDate

		-- Type 4
		UPDATE #OEE SET MLThresholdOperatorCat = isnull(MLThresholdOperatorCat,0) + isNull(t2.loss,0)
		from
		(select mc,T.Sdate,T.StartDate,T.EndDate,sum(
		CASE WHEN DateDiff(second, T.StartDate, T.EndDate) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
		then isnull(downcodeinformation.Threshold,0)
		ELSE DateDiff(second, T.StartDate, T.EndDate)
		END)loss
		--sum(DateDiff(second, T.StartDate, T.EndDate)) loss
		from #T_autodata autodata --ER0374
		INNER JOIN #OEE T on T.MachineInterface=autodata.mc
		INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
		where autodata.msttime<T.StartDate
		and autodata.ndtime>T.EndDate
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1)
		and downcodeinformation.Catagory in ('Operator')
		and (downcodeinformation.ThresholdfromCO <>1) --NR0097
		group by autodata.mc,T.Sdate,T.StartDate,T.EndDate
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface AND T2.Sdate=#OEE.Sdate AND T2.StartDate=#OEE.StartDate AND T2.EndDate=#OEE.EndDate


If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N'
BEGIN
	UPDATE #OEE SET OperatorCategoryDowntime = isnull(OperatorCategoryDowntime,0) + isNull(t2.oeedown,0)
		from
		(select mc,T.Sdate,T.StartDate,T.EndDate,sum(
				CASE
				WHEN  autodata.msttime>=T.StartDate  and  autodata.ndtime<=T.EndDate  THEN  loadunload
				WHEN (autodata.sttime<T.StartDate and  autodata.ndtime>T.StartDate and autodata.ndtime<=T.EndDate)  THEN DateDiff(second, T.StartDate, ndtime)
				WHEN (autodata.msttime>=T.StartDate  and autodata.sttime<T.EndDate  and autodata.ndtime>T.EndDate)  THEN DateDiff(second, stTime, T.EndDate)
				WHEN autodata.msttime<T.StartDate and autodata.ndtime>T.EndDate   THEN DateDiff(second, T.StartDate, T.EndDate)
				END
			)AS oeedown
		from #T_autodata autodata --ER0374
		INNER JOIN #OEE T on T.MachineInterface=autodata.mc
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		where autodata.datatype=2 AND
		(
		(autodata.msttime>=T.StartDate  and  autodata.ndtime<=T.EndDate)
		OR (autodata.sttime<T.StartDate and  autodata.ndtime>T.StartDate and autodata.ndtime<=T.EndDate)
		OR (autodata.msttime>=T.StartDate  and autodata.sttime<T.EndDate  and autodata.ndtime>T.EndDate)
		OR (autodata.msttime<T.StartDate and autodata.ndtime>T.EndDate )
		) and Catagory in ('Operator')
		--) and downcodeinformation.Catagory in ('Operator')
		group by autodata.mc,T.Sdate,T.StartDate,T.EndDate
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface AND T2.Sdate=#OEE.Sdate AND T2.StartDate=#OEE.StartDate AND T2.EndDate=#OEE.EndDate

		UPDATE #OEE SET OperatorCategoryDowntime=isnull(OperatorCategoryDowntime,0)-isnull(MLThresholdOperatorCat,0)

end


If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN
	UPDATE #OEE SET OperatorCategoryDowntime = isnull(OperatorCategoryDowntime,0) + isNull(t2.oeedown,0)
		from
		(select mc,T.Sdate,T.StartDate,T.EndDate,sum(
				CASE
				WHEN  autodata.msttime>=T.StartDate  and  autodata.ndtime<=T.EndDate  THEN  loadunload
				WHEN (autodata.sttime<T.StartDate and  autodata.ndtime>T.StartDate and autodata.ndtime<=T.EndDate)  THEN DateDiff(second, T.StartDate, ndtime)
				WHEN (autodata.msttime>=T.StartDate  and autodata.sttime<T.EndDate  and autodata.ndtime>T.EndDate)  THEN DateDiff(second, stTime, T.EndDate)
				WHEN autodata.msttime<T.StartDate and autodata.ndtime>T.EndDate   THEN DateDiff(second, T.StartDate, T.EndDate)
				END
			)AS oeedown
		from #T_autodata autodata --ER0374
		INNER JOIN #OEE T on T.MachineInterface=autodata.mc
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		where autodata.datatype=2 AND
		(
		(autodata.msttime>=T.StartDate  and  autodata.ndtime<=T.EndDate)
		OR (autodata.sttime<T.StartDate and  autodata.ndtime>T.StartDate and autodata.ndtime<=T.EndDate)
		OR (autodata.msttime>=T.StartDate  and autodata.sttime<T.EndDate  and autodata.ndtime>T.EndDate)
		OR (autodata.msttime<T.StartDate and autodata.ndtime>T.EndDate )
		) and Catagory in ('Operator')
		--)and downcodeinformation.Catagory in ('Operator')
		group by autodata.mc,T.Sdate,T.StartDate,T.EndDate
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface AND T2.Sdate=#OEE.Sdate AND T2.StartDate=#OEE.StartDate AND T2.EndDate=#OEE.EndDate

	UPDATE #OEE set OperatorCategoryDowntime =isnull(OperatorCategoryDowntime,0) - isNull(TT.PPDT ,0)
	FROM(
		SELECT autodata.MC,T.Sdate,T.StartDate,T.EndDate,SUM
		   (CASE
			WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PPDT
		from  #T_autodata autodata CROSS jOIN #PlannedDownTimes T
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)and downcodeinformation.Catagory in ('Operator')
			--)and downcodeinformation.Catagory in ('Operator')
		group by autodata.MC,T.Sdate,T.StartDate,T.EndDate
	) as TT INNER JOIN #OEE ON TT.mc = #OEE.MachineInterface AND TT.Sdate=#OEE.Sdate AND TT.StartDate=#OEE.StartDate AND TT.EndDate=#OEE.EndDate


	UPDATE #OEE SET OperatorCategoryDowntime=isnull(OperatorCategoryDowntime,0)-isnull(MLThresholdOperatorCat,0)

end
 --------------------------------------------------------------------Operator category down Time cal ends----------------------------------------------------------------------

-- --------------------------------------------------------------------Quality efficicency cal starts---------------------------------------------------------------------------
 UPDATE #OEE SET components = ISNULL(components,0) + ISNULL(t2.comp,0)
From
(
	--Select mc,SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp --NR0097
	  Select mc,Sdate,StartDate,EndDate,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp --NR0097
		   From (select mc,SUM(autodata.partscount)AS OrginalCount,comp,opn,T.Sdate,T.StartDate,T.EndDate 
			from #T_autodata autodata --ER0374
			INNER JOIN #OEE T on T.MachineInterface=autodata.mc
		   where (autodata.ndtime>T.StartDate) and (autodata.ndtime<=T.EndDate) and (autodata.datatype=1)
		   Group By mc,comp,opn,T.Sdate,T.StartDate,T.EndDate) as T1
	Inner join componentinformation C on T1.Comp = C.interfaceid
	Inner join ComponentOperationPricing O ON  T1.Opn = O.interfaceid and C.Componentid=O.componentid
	---mod 2
	inner join machineinformation on machineinformation.machineid =O.machineid
	and T1.mc=machineinformation.interfaceid
	---mod 2
	GROUP BY mc,Sdate,StartDate,EndDate
) As T2 Inner join #OEE on T2.mc = #OEE.machineinterface  AND T2.Sdate=#OEE.Sdate AND T2.StartDate=#OEE.StartDate AND T2.EndDate=#OEE.EndDate

--Apply Exception on Count..


--Mod 4 Apply PDT for calculation of Count
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	UPDATE #OEE SET components = ISNULL(components,0) - ISNULL(T2.comp,0) from(
		--select mc,SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp From ( --NR0097
		select mc,Sdate,StartDate,EndDate,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp From ( --NR0097
			select mc,Sum(ISNULL(PartsCount,1))AS OrginalCount,comp,opn ,T.Sdate,T.StartDate,T.EndDate 
			from #T_autodata autodata --ER0374
			INNER JOIN #OEE T1 on T1.MachineInterface=autodata.mc
			CROSS JOIN #PlannedDownTimes T
			WHERE autodata.DataType=1 And T.MachineInterface = autodata.mc
			AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)
			AND (autodata.ndtime > T1.StartDate  AND autodata.ndtime <=T1.EndDate)
		    Group by mc,comp,opn
		) as T1
	Inner join Machineinformation M on M.interfaceID = T1.mc
	Inner join componentinformation C on T1.Comp=C.interfaceid
	Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineID = M.MachineID
	GROUP BY MC,Sdate,StartDate,EndDate
	) as T2 inner join #OEE on T2.mc = #OEE.machineinterface  AND T2.Sdate=#OEE.Sdate AND T2.StartDate=#OEE.StartDate AND T2.EndDate=#OEE.EndDate
END


Update #OEE set RejCount = isnull(RejCount,0) + isnull(T1.RejQty,0)
From
( Select A.mc,#OEE.Sdate,#OEE.StartDate,#OEE.EndDate,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A
inner join Machineinformation M on A.mc=M.interfaceid
inner join #OEE on #OEE.machineid=M.machineid 
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
where A.CreatedTS>=#OEE.StartDate and A.CreatedTS<#OEE.EndDate and A.flag = 'Rejection'
and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000'
group by A.mc,M.Machineid,#OEE.Sdate,#OEE.StartDate,#OEE.EndDate
)T1 inner join #OEE B on B.Machineid=T1.Machineid AND B.Sdate=T1.Sdate AND B.StartDate=T1.StartDate AND B.EndDate=T1.EndDate

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	Update #OEE set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from
	(Select A.mc,#OEE.Sdate,#OEE.StartDate,#OEE.EndDate,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A
	inner join Machineinformation M on A.mc=M.interfaceid
	inner join #OEE on #OEE.machineid=M.machineid 
	inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
	Cross join Planneddowntimes P
	where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid 
	and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000' and
	A.CreatedTS>=#OEE.StartDate and A.CreatedTS<#OEE.EndDate And
	A.CreatedTS>=P.Starttime and A.CreatedTS<P.endtime
	group by A.mc,M.Machineid,#OEE.Sdate,#OEE.StartDate,#OEE.EndDate)T1 inner join #OEE B on B.Machineid=T1.Machineid 
	AND B.Sdate=T1.Sdate AND B.StartDate=T1.StartDate AND B.EndDate=T1.EndDate
END

Update #OEE set RejCount = isnull(RejCount,0) + isnull(T1.RejQty,0)
From
( Select A.mc,#OEE.Sdate,#OEE.StartDate,#OEE.EndDate,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A
inner join Machineinformation M on A.mc=M.interfaceid
inner join #OEE on #OEE.machineid=M.machineid 
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
inner join #shift S on convert(nvarchar(10),(A.RejDate),126)=S.shiftdate and A.RejShift=S.shiftid --DR0333
where A.flag = 'Rejection' and A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (S.shiftdate) and  --DR0333
Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
group by A.mc,M.Machineid,#OEE.Sdate,#OEE.StartDate,#OEE.EndDate
)T1 inner join #OEE B on B.Machineid=T1.Machineid AND B.Sdate=T1.Sdate AND B.StartDate=T1.StartDate AND B.EndDate=T1.EndDate

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	Update #OEE set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from
	(Select A.mc,#OEE.Sdate,#OEE.StartDate,#OEE.EndDate,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A
	inner join Machineinformation M on A.mc=M.interfaceid
	inner join #OEE on #OEE.machineid=M.machineid 
	inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
	inner join #shift S on convert(nvarchar(10),(A.RejDate),126)=S.shiftdate and A.RejShift=S.shiftid --DR0333
	Cross join Planneddowntimes P
	where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid and
	A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (S.shiftdate) and --DR0333
	Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
	and P.starttime>=S.Shiftstart and P.Endtime<=S.shiftend
	group by A.mc,M.Machineid,#OEE.Sdate,#OEE.StartDate,#OEE.EndDate)T1 inner join #OEE B on B.Machineid=T1.Machineid 
	AND B.Sdate=T1.Sdate AND B.StartDate=T1.StartDate AND B.EndDate=T1.EndDate
END

UPDATE #OEE SET QualityEfficiency= ISNULL(QualityEfficiency,1) + IsNull(T1.QE,1) 
FROM(Select MachineID,Sdate,StartDate,EndDate,
CAST((Sum(Components))As Float)/CAST((Sum(IsNull(Components,0))+Sum(IsNull(RejCount,0))) AS Float)As QE
From #OEE Where Components<>0 Group By MachineID,Sdate,StartDate,EndDate
)AS T1 Inner Join #OEE ON  #OEE.MachineID=T1.MachineID
AND #OEE.Sdate=T1.Sdate AND #OEE.StartDate=T1.StartDate AND #OEE.EndDate=T1.EndDate
 -----------------------------------------------------------------------------CAL OF QUALITY EFFICIENCY ENDS-----------------------------------------------------------------------------------

 -----------------------------------------------------------------------------Cal of Summation of standard time (cn) starts--------------------------------------------------------------------

 
UPDATE #OEE SET SummationofStandardTime = isnull(SummationofStandardTime,0) + isNull(t2.C1N1,0)
from
(select mc,t.Sdate,T.StartDate,T.EndDate,
SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))* autodata.partscount) C1N1
--SUM(componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1)) C1N1
FROM #T_autodata autodata --ER0374
INNER JOIN #OEE T on T.MachineInterface=autodata.mc
INNER JOIN
componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID AND
componentoperationpricing.componentid = componentinformation.componentid
--mod 2
inner join machineinformation on machineinformation.interfaceid=autodata.mc
and componentoperationpricing.machineid=machineinformation.machineid
--mod 2
where (((autodata.sttime>=T.StartDate)and (autodata.ndtime<=T.EndDate)) or
((autodata.sttime<T.StartDate)and (autodata.ndtime>T.StartDate)and (autodata.ndtime<=T.EndDate)) )
and (autodata.datatype=1)
group by autodata.mc,t.Sdate,T.StartDate,T.EndDate
) as t2 inner join #OEE on t2.mc = #OEE.machineinterface AND T2.Sdate=#OEE.Sdate AND T2.StartDate=#OEE.StartDate AND T2.EndDate=#OEE.EndDate

-- mod 4 Ignore count from CN calculation which is over lapping with PDT
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	UPDATE #OEE SET SummationofStandardTime = isnull(SummationofStandardTime,0) - isNull(t2.C1N1,0)
	From
	(
		select mc,T.Sdate,T.StartDate,T.EndDate,SUM((O.cycletime * ISNULL(A.PartsCount,1))/ISNULL(O.SubOperations,1))  C1N1
		From #T_autodata A --ER0374
		Inner join machineinformation M on M.interfaceid=A.mc
		Inner join componentinformation C ON A.Comp=C.interfaceid
		Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID
		Cross jOIN #PlannedDownTimes T
		WHERE A.DataType=1 AND T.MachineInterface=A.mc
		AND(A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)
		AND(A.ndtime > T.StartDate  AND A.ndtime <=T.EndDate)
		Group by mc,T.Sdate,T.StartDate,T.EndDate
	) as T2
	inner join #OEE  on t2.mc = #OEE.machineinterface AND T2.Sdate=#OEE.Sdate AND T2.StartDate=#OEE.StartDate AND T2.EndDate=#OEE.EndDate
END


-------------------------------------------------------------------------------------calculation of cn ends ------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------Calculation of third shift utilised time Starts---------------------------------------------------------------------------------
		insert INTO #PlannedDownTimesShift(StartTime,EndTime,Machine,MachineInterface,Downreason,Shiftst)
		select
		CASE When StartTime<T1.ShftSTtime Then T1.ShftSTtime Else StartTime End,
		case When EndTime>T1.ShftEndTime Then T1.ShftEndTime Else EndTime End,
		Machine,M.InterfaceID,
		DownReason,T1.ShftSTtime
		FROM PlannedDownTimes cross join #Shift2 T1
		inner join MachineInformation M on PlannedDownTimes.machine = M.MachineID
		WHERE PDTstatus =1 and (
		(StartTime >= T1.ShftSTtime  AND EndTime <=T1.ShftEndTime)
		OR ( StartTime < T1.ShftSTtime  AND EndTime <= T1.ShftEndTime AND EndTime > T1.ShftSTtime )
		OR ( StartTime >= T1.ShftSTtime   AND StartTime <T1.ShftEndTime AND EndTime > T1.ShftEndTime )
		OR ( StartTime < T1.ShftSTtime  AND EndTime > T1.ShftEndTime) )
		and machine in (select distinct machine from #OEE)
		ORDER BY StartTime

insert into #ShiftProductionFromAutodataT1(machineid,MachineInterface,ShiftDate,UstartShift,UEndShift,UtilisedTime,shiftid)
select distinct #OEE.machineid,#OEE.MachineInterface,convert(nvarchar(10),s.ShiftDate,120),s.ShftSTtime,s.ShftEndTime,0,s.shiftid
from #OEE cross join #shift2 s

		-----------------------------------ER0324 added From Here------------------------------------------------
		 Print  '----UPDATE  #ShiftProductionFromAutodataT1 SET UtilisedTime------'
         print getdate() 
		-------For Type2
		UPDATE  #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
		FROM
		(Select AutoData.mc ,
		SUM(
		CASE
			When autodata.sttime <= T1.UstartShift Then datediff(s, T1.UstartShift,autodata.ndtime )
			When autodata.sttime > T1.UstartShift Then datediff(s , autodata.sttime,autodata.ndtime)
		END) as Down,t1.UstartShift as ShiftStart,T1.shiftdate as shiftdate
		From #T_autodata  AutoData INNER Join
			(Select mc,Sttime,NdTime,UstartShift,UEndShift,shiftdate From #T_autodata AutoData
				inner join #ShiftProductionFromAutodataT1 ST1 ON ST1.MachineInterface=Autodata.mc
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(msttime < UstartShift)And (ndtime > UstartShift) AND (ndtime <= UEndShift)
		) as T1 on t1.mc=autodata.mc
		Where AutoData.DataType=2
		And ( autodata.Sttime > T1.Sttime )
		And ( autodata.ndtime <  T1.ndtime )
		AND ( autodata.ndtime >  T1.UstartShift )
		GROUP BY AUTODATA.mc,T1.UstartShift,T1.shiftdate)AS T2 Inner Join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
		and T2.shiftdate = #ShiftProductionFromAutodataT1.shiftdate and t2.ShiftStart=#ShiftProductionFromAutodataT1.UstartShift
		--For Type4
		UPDATE  #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
		FROM
		(Select AutoData.mc ,
		SUM(CASE
			When autodata.sttime >= T1.UstartShift AND autodata.ndtime <= T1.UEndShift Then datediff(s , autodata.sttime,autodata.ndtime)
			When autodata.sttime < T1.UstartShift And autodata.ndtime >T1.UstartShift AND autodata.ndtime<=T1.UEndShift Then datediff(s, T1.UstartShift,autodata.ndtime )
			When autodata.sttime >= T1.UstartShift AND autodata.sttime<T1.UEndShift AND autodata.ndtime>T1.UEndShift Then datediff(s,autodata.sttime, T1.UEndShift )
			When autodata.sttime<T1.UstartShift AND autodata.ndtime>T1.UEndShift   Then datediff(s , T1.UstartShift,T1.UEndShift)
		END) as Down,T1.UstartShift as ShiftStart,T1.shiftdate as shiftdate
		From #T_autodata AutoData INNER Join
			(Select mc,Sttime,NdTime,UstartShift,UEndShift,shiftdate From #T_autodata AutoData
				inner join #ShiftProductionFromAutodataT1 ST1 ON ST1.MachineInterface =Autodata.mc
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(msttime < UstartShift)And (ndtime >UEndShift)
			
		 ) as T1
		ON AutoData.mc=T1.mc
		Where AutoData.DataType=2
		And (T1.Sttime < autodata.sttime  )
		And ( T1.ndtime >  autodata.ndtime)
		AND (autodata.ndtime  >  T1.UstartShift)
		AND (autodata.sttime  <  T1.UEndShift)
		GROUP BY AUTODATA.mc,T1.UstartShift,T1.shiftdate
		 )AS T2 Inner Join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
		and T2.shiftdate = #ShiftProductionFromAutodataT1.shiftdate and t2.ShiftStart=#ShiftProductionFromAutodataT1.UstartShift
		--Type 3
		UPDATE  #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
		FROM
		(Select AutoData.mc ,
		SUM(CASE
			When autodata.ndtime > T1.UEndShift Then datediff(s,autodata.sttime, T1.UEndShift )
			When autodata.ndtime <=T1.UEndShift Then datediff(s , autodata.sttime,autodata.ndtime)
		END) as Down,T1.UstartShift as ShiftStart,T1.shiftdate as shiftdate
		From #T_autodata AutoData INNER Join
			(Select mc,Sttime,NdTime,ustartshift,uendshift,shiftdate From #T_autodata AutoData
				inner join #ShiftProductionFromAutodataT1 ST1 ON ST1.MachineInterface =Autodata.mc
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(sttime >= UstartShift)And (ndtime >UEndShift) and (sttime< UEndShift)
		 ) as T1
		ON AutoData.mc=T1.mc
		Where AutoData.DataType=2
		And (T1.Sttime < autodata.sttime  )
		And ( T1.ndtime >  autodata.ndtime)
		AND (autodata.sttime  <  T1.UEndShift)
		GROUP BY AUTODATA.mc,T1.UstartShift,T1.shiftdate )AS T2 Inner Join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
		and t2.shiftdate=#ShiftProductionFromAutodataT1.shiftdate and t2.ShiftStart=#ShiftProductionFromAutodataT1.UstartShift

		-----------------------------------ER0324 added till Here------------------------------------------------

		UPDATE #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
		from
		(select      mc,
			sum(case when ( (autodata.msttime>=S.UstartShift) and (autodata.ndtime<=S.UEndShift)) then  (cycletime+loadunload)
				 when ((autodata.msttime<S.UstartShift)and (autodata.ndtime>S.UstartShift)and (autodata.ndtime<=S.UEndShift)) then DateDiff(second, S.UstartShift, ndtime)
				 when ((autodata.msttime>=S.UstartShift)and (autodata.msttime<S.UEndShift)and (autodata.ndtime>S.UEndShift)) then DateDiff(second, mstTime, S.UEndShift)
				 when ((autodata.msttime<S.UstartShift)and (autodata.ndtime>S.UEndShift)) then DateDiff(second, S.UstartShift, S.UEndShift) END ) as cycle,S.UstartShift as ShiftStart
		from #T_autodata autodata inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface --ER0324 Added
		where (autodata.datatype=1) AND(( (autodata.msttime>=S.UstartShift) and (autodata.ndtime<=S.UEndShift))
		OR ((autodata.msttime<S.UstartShift)and (autodata.ndtime>S.UstartShift)and (autodata.ndtime<=S.UEndShift))
		OR ((autodata.msttime>=S.UstartShift)and (autodata.msttime<S.UEndShift)and (autodata.ndtime>S.UEndShift))
		OR((autodata.msttime<S.UstartShift)and (autodata.ndtime>S.UEndShift)))
		group by autodata.mc,S.UstartShift
		) as t2 inner join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
		and t2.ShiftStart=#ShiftProductionFromAutodataT1.UstartShift





If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
BEGIN
	
	--get the utilised time overlapping with PDT and negate it from UtilisedTime
	UPDATE  #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.PlanDT,0)
	from( select T.ShiftSt as intime,T.Machine as machine,sum (CASE
	--WHEN (autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN (cycletime+loadunload) --DR0325 Commented
	WHEN (autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN DateDiff(second,autodata.msttime,autodata.ndtime) --DR0325 Added
	WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
	WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )
	WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
	END ) as PlanDT
	from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T --ER0324 Added
	WHERE autodata.DataType=1   and T.MachineInterface=autodata.mc AND(
	(autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
	OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
	OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )
	OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime)
	)
	group by T.Machine,T.ShiftSt ) as t2 inner join #ShiftProductionFromAutodataT1 S on t2.intime=S.UstartShift and t2.machine=S.machineId
	

	---mod 12:Add ICD's Overlapping  with PDT to UtilisedTime
	/* Fetching Down Records from Production Cycle  */
	 ---mod 12(4):Handle intearction between ICD and PDT for type 1 production record for the selected time period.
		UPDATE  #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)
		FROM	(
		Select T.ShiftSt as intime,AutoData.mc,
		SUM(
		CASE 	
			When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
			When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
			When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
			when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		from #T_autodata autodata INNER Join --ER0324 Added
			(Select mc,Sttime,NdTime,S.UstartShift as StartTime from #T_autodata autodata inner join #ShiftProductionFromAutodataT1 S on S.MachineInterface=autodata.mc
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(msttime >= S.UstartShift) AND (ndtime <= S.UEndShift)) as T1
		ON AutoData.mc=T1.mc CROSS jOIN #PlannedDownTimesShift T
		Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc
		And (( autodata.Sttime >= T1.Sttime ) --DR0339
		And ( autodata.ndtime <= T1.ndtime ) --DR0339
		)
		AND
		((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
		or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
		or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
		or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )
		GROUP BY AUTODATA.mc,T.ShiftSt
		)AS T2  INNER JOIN #ShiftProductionFromAutodataT1 ON
	T2.mc = #ShiftProductionFromAutodataT1.MachineInterface and  t2.intime=#ShiftProductionFromAutodataT1.UstartShift
	

	---mod 12(4)
	/* If production  Records of TYPE-2*/
	UPDATE  #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)
	FROM
	(Select T.ShiftSt as intime,AutoData.mc ,
	SUM(
	CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT
	from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join --ER0324 Added
		(Select mc,Sttime,NdTime,S.UstartShift as StartTime from #T_autodata autodata inner join #ShiftProductionFromAutodataT1 S on S.MachineInterface=autodata.mc
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(msttime < S.UstartShift)And (ndtime > S.UstartShift) AND (ndtime <= S.UEndShift)) as T1
	ON AutoData.mc=T1.mc  and T1.StartTime=T.ShiftSt
	Where AutoData.DataType=2  and T.MachineInterface=autodata.mc
	And (( autodata.Sttime > T1.Sttime )
	And ( autodata.ndtime <  T1.ndtime )
	AND ( autodata.ndtime >  T1.StartTime ))
	AND
	(( T.StartTime >= T1.StartTime )
	And ( T.StartTime <  T1.ndtime ) )
	GROUP BY AUTODATA.mc,T.ShiftSt )AS T2  INNER JOIN #ShiftProductionFromAutodataT1 ON
	T2.mc = #ShiftProductionFromAutodataT1.MachineInterface and  t2.intime=#ShiftProductionFromAutodataT1.UstartShift

	

	/* If production Records of TYPE-3*/
	UPDATE  #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)
	FROM
	(Select T.ShiftSt as intime,AutoData.mc ,
	SUM(
	CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT
	from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join --ER0324 Added
		(Select mc,Sttime,NdTime,S.UstartShift as StartTime,S.UEndShift as EndTime from #T_autodata autodata inner join #ShiftProductionFromAutodataT1 S on S.MachineInterface=autodata.mc
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(sttime >= S.UstartShift)And (ndtime > S.UEndShift) and autodata.sttime <S.UEndShift) as T1
	ON AutoData.mc=T1.mc and T1.StartTime=T.ShiftSt
	Where AutoData.DataType=2  and T.MachineInterface=autodata.mc
	And ((T1.Sttime < autodata.sttime  )
	And ( T1.ndtime >  autodata.ndtime)
	AND (autodata.sttime  <  T1.EndTime))
	AND
	(( T.EndTime > T1.Sttime )
	And ( T.EndTime <=T1.EndTime ) )
	GROUP BY AUTODATA.mc,T.ShiftSt)AS T2   INNER JOIN #ShiftProductionFromAutodataT1 ON
	T2.mc = #ShiftProductionFromAutodataT1.MachineInterface and  t2.intime=#ShiftProductionFromAutodataT1.UstartShift
	

	
	/* If production Records of TYPE-4*/
	UPDATE  #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)
	FROM
	(Select T.ShiftSt as intime,AutoData.mc ,
	SUM(
	CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT
	from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join --ER0324 Added
		(Select mc,Sttime,NdTime,S.UstartShift as StartTime,S.UEndShift as EndTime from #T_autodata autodata inner join #ShiftProductionFromAutodataT1 S on S.MachineInterface=autodata.mc
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(msttime < S.UstartShift)And (ndtime > S.UEndShift)) as T1
	ON AutoData.mc=T1.mc and T1.StartTime=T.ShiftSt
	Where AutoData.DataType=2 and T.MachineInterface=autodata.mc
	And ( (T1.Sttime < autodata.sttime  )
		And ( T1.ndtime >  autodata.ndtime)
		AND (autodata.ndtime  >  T1.StartTime)
		AND (autodata.sttime  <  T1.EndTime))
	AND
	(( T.StartTime >=T1.StartTime)
	And ( T.EndTime <=T1.EndTime ) )
	GROUP BY AUTODATA.mc,T.ShiftSt)AS T2  INNER JOIN #ShiftProductionFromAutodataT1 ON
	T2.mc = #ShiftProductionFromAutodataT1.MachineInterface and  t2.intime=#ShiftProductionFromAutodataT1.UstartShift
	
END

-------------------------------------------------------------------------------Calculation of third shift utilised time ends---------------------------------------------------------------------------------

----------------------------------------------------------------------------  update Calculation of third shift utilised time to #oee---------------------------------------------------------------------------------

update #OEE set  UtilisedTime3rdShift=isnull(t1.utilisedTimepershift,0)
from
(
select machineid,ShiftDate,sum(UtilisedTime) as utilisedTimepershift   from #ShiftProductionFromAutodataT1    
group by machineid,ShiftDate
)t1 inner join #oee on t1.machineid=#OEE.MachineID AND T1.ShiftDate=#OEE.Sdate

--update #OEE set NonWorking=isnull((isnull(NonWorking,0)-isnull(UtilisedTime3rdShift,0)),0)

UPDATE #OEE SET NonWorking=ISNULL(T1.NW,0)
FROM(
SELECT MachineID,Sdate,StartDate,EndDate,isnull((isnull(NonWorking,0)-isnull(UtilisedTime3rdShift,0)),0) AS NW FROM #OEE
)T1 INNER JOIN #OEE T2 ON T1.MachineID=T2.MachineID AND T1.Sdate=T2.Sdate AND T1.StartDate=T2.StartDate AND T1.EndDate=T2.EndDate

--select * from #OEE

select Sdate,MachineID,MachineInterface,ISNULL(round((TotalTime/60),2),0) as TotalTime,ISNULL(round((NonWorking/60),2),0) as NonWorking,ISNULL(round((LunchDinner/60),2),0) as LunchDinner,
ISNULL(round((SettingTime/60),2),0) as SettingTime,ISNULL(NoofSettings,0) AS NoofSettings,ISNULL(round((OperatingTime/60),2),0) as OperatingTime,ISNULL(round((downtime/60),2),0) as downtime,
ISNULL(round((ManagementLoss/60),2),0) as managemntloss, ISNULL(round((PlannedLoss/60),2),0) as PlannedLoss,ISNULL(round((SummationofStandardTime)/60,2),0) as SummationofStandardTime,
ISNULL(round((OEEExclusionTime/60),2),0) as OEEExclusionTime,ISNULL(round((SupervisorCategoryDowntime/60),2),0) as SupervisorCategoryDowntime,ISNULL(round((OperatorCategoryDowntime/60),2),0) as OperatorCategoryDowntime,
ISNULL(ROUND((QualityEfficiency*100),1),0) as QualityEfficiency,ISNULL(ROUND((TIMEASPERBOM/3600),1),0) AS Time_Per_BOM,isnull((UtilisedTime3rdShift/60),0) as UtilisedTime3rdShift 
from #OEE
Order by Sdate,len(MachineInterface),MachineInterface

end
