/****** Object:  Procedure [dbo].[S_GetOEEReport_Trellborg]    Committed by VersionSQL https://www.versionsql.com ******/

/*
[dbo].[S_GetOEEReport_Trellborg] '2021-08-02 06:30:00','2021-08-03 06:30:00','INDIAN NIPPON P1','CNC CELL','',''
[dbo].[S_GetOEEReport_Trellborg] '2021-06-14 06:00:00','2021-06-15 06:00:00','CELL 11','','',''
[dbo].[S_GetOEEReport_Trellborg] '2021-08-04 06:00:00','2021-08-05 06:00:00','CELL 5','','',''
[dbo].[S_GetOEEReport_Trellborg] '2021-08-02 06:00:00','2021-08-03 06:00:00','CELL 5','','',''


*/
CREATE procedure [dbo].[S_GetOEEReport_Trellborg]
@StartTime datetime='',
@EndTime datetime='',
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

select @strSql=''
select @strmachine=''
select @StrPlantid=''
select @StrGroupID=''
select @Start=@StartTime
select @End=@EndTime
select @shiftin='third'


if isnull(@PlantID,'') <> ''
Begin
	---mod 2
	Select @StrPlantid = ' and ( PlantMachine.PlantID = N''' + @PlantID + ''')'
End

if isnull(@machineid,'') <> ''
Begin
	Select @strmachine = ' and ( Machineinformation.MachineID = N''' + @MachineID + ''')'
end
If isnull(@GroupID ,'') <> ''
Begin
Select @StrGroupID = ' And ( PlantMachineGroups.GroupID = N''' + @GroupID + ''')'
End
IF ( SELECT TOP 1 ValueInText FROM  CockpitDefaults WHERE Parameter='TpmEnbMac')='E'
BEGIN
	SET  @StrTPMMachines = 'AND MachineInformation.TPMTrakEnabled = 1'
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
		ShftEndTime DateTime	
	)

WHILE @Start<@End
BEGIN
INSERT INTO #Shift2(ShiftDate,Shiftname,ShftSTtime,ShftEndTime)
Exec s_GetShiftTime @Start,@shiftin
SELECT @Start = DATEADD(DAY,1,@Start)
end

--select * from #shift2
--return

create table #OEE
(
MachineID Nvarchar(50),
MachineInterface nvarchar(50),
Startdate datetime,
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
select @startdate1 = dbo.f_GetLogicalDaystart(@StartTime)
select @enddate1 = dbo.f_GetLogicalDaystart(@endtime)
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
select convert(nvarchar(10),ShiftDate,126),shiftname,ShftSTtime,ShftEndTime from #ShiftDefn where ShftSTtime>=@StartTime and ShftEndTime<=@endtime --DR0333

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

Declare @T_ST AS Datetime 
Declare @T_ED AS Datetime 

Select @T_ST=dbo.f_GetLogicalDaystart(@StartTime)
Select @T_ED=dbo.f_GetLogicalDayend(@EndTime)

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
StartDate ,
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
SET @strSql = @strSql + ' SELECT MachineInformation.MachineID, MachineInformation.interfaceid,'''+convert(nvarchar(20),@StartTime)+''', 0,0,0,0,0,0,0,0,0,0,0,0,0,0,
'''+convert(nvarchar(20),@StartTime)+''','''+convert(nvarchar(20),@EndTime)+''',0,0,0,0,0,0 FROM MachineInformation 
			  LEFT OUTER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID
			  LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID
 WHERE MachineInformation.interfaceid > ''0'' '
SET @strSql =  @strSql + @strMachine + @strPlantID + @StrGroupID
print(@strsql)
EXEC(@strSql)

SET @strSql = ''
SET @strSql = 'INSERT INTO #PLD(MachineID,MachineInterface,pPlannedDT,dPlannedDT)
	SELECT machineinformation.MachineID ,Interfaceid,0  ,0 FROM MachineInformation
		LEFT OUTER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID 
    LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID
	 WHERE  MachineInformation.interfaceid > ''0'' '
SET @strSql =  @strSql + @strMachine + @StrTPMMachines + @StrGroupID
EXEC(@strSql)


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

-----------------------------------------------------------Totaltime cal starts-----------------------------------------------------------------------------------------------------

--update #OEE set TotalTime=T.TotalTime
--from
--(
--select MachineID,datediff(ss,fromtime,ToTime) as TotalTime  from #OEE
--)T INNER JOIN #OEE ON T.MachineID=#OEE.MachineID 

UPDATE #OEE
SET
	TotalTime = DateDiff(second, @StartTime, @EndTime)

-----------------------------------------------------------Totaltime cal ends-----------------------------------------------------------------------------------------------------

-----------------------------------------------------------pdt cal starts-----------------------------------------------------------------------------------------------------

UPDATE #OEE SET NonWorking=ISNULL(NonWorking,0)+T1.PDT
FROM
(
SELECT MACHINEID,SUM(DATEDIFF(ss,StartTime,EndTime)) AS PDT FROM #PlannedDownTimes
GROUP BY MACHINEID
) T1 INNER JOIN #OEE ON T1.MachineID=#OEE.MachineID
-----------------------------------------------------------pdt cal ends-----------------------------------------------------------------------------------------------------

-----------------------------------------------------------Threshold for lunch and dinner cal starts-------------------------------------------------------------------------

--UPDATE #OEE SET LunchDinner = isnull(LunchDinner,0) + isNull(t2.lunchthreshold,0)
--		from
--		(
--		select sum(threshold) as lunchthreshold from downcodeinformation
--		--where downid in ('Dinner')
--		where downid in ('BREAKFAST / LANCH')
--		) as t2 
--If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N'
--begin
		UPDATE #OEE SET LunchDinner = isnull(LunchDinner,0) + isNull(t2.loss,0)
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
		and downcodeinformation.downid in ('BREAKFAST / LANCH')
		and (downcodeinformation.ThresholdfromCO <>1) --NR0097
		group by autodata.mc) as t2 inner join #OEE on t2.mc = #OEE.machineinterface
		-- Type 2
		UPDATE #OEE SET LunchDinner = isnull(LunchDinner,0) + isNull(t2.loss,0)
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
		and downcodeinformation.downid in ('BREAKFAST / LANCH')
		and (downcodeinformation.ThresholdfromCO <>1) --NR0097
		group by autodata.mc
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface
		-- Type 3
		UPDATE #OEE SET LunchDinner = isnull(LunchDinner,0) + isNull(t2.loss,0)
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
		and downcodeinformation.downid in ('BREAKFAST / LANCH')
		group by autodata.mc
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface
		-- Type 4
		UPDATE #OEE SET LunchDinner = isnull(LunchDinner,0) + isNull(t2.loss,0)
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
		and downcodeinformation.downid in ('BREAKFAST / LANCH')
		and (downcodeinformation.ThresholdfromCO <>1) --NR0097
		group by autodata.mc
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface	

--end

--If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
--begin
--	UPDATE #OEE SET  LunchDinner = isnull(ManagementLoss,0) + isNull(t4.Mloss,0)
--	from
--	(select T3.mc,sum(T3.Mloss) as Mloss from (
--	select   t1.id,T1.mc,T1.Threshold,
--	case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0
--	then DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)- isnull(T1.Threshold ,0)
--	else 0 End  as Dloss,
--	case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0
--	then isnull(T1.Threshold,0)
--	else (DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)) End  as Mloss
--	 from
	
--	(   select id,mc,comp,opn,opr,D.threshold,
--		case when autodata.sttime<@StartTime then @StartTime else sttime END as sttime,
--	       	case when ndtime>@EndTime then @EndTime else ndtime END as ndtime
--		from #T_autodata autodata --ER0374
--		inner join downcodeinformation D
--		on autodata.dcode=D.interfaceid where autodata.datatype=2 AND
--		(
--		(autodata.sttime>=@StartTime  and  autodata.ndtime<=@EndTime)
--		OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
--		OR (autodata.sttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
--		OR (autodata.sttime<@StartTime and autodata.ndtime>@EndTime )
--		) AND (D.availeffy = 1) 
--			and d.downid in ('BREAKFAST / LANCH')
--		and (D.ThresholdfromCO <>1)) as T1 	 --NR0097
--	left outer join
--	(SELECT autodata.id,
--		       sum(CASE
--			WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
--			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
--			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
--			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
--			END ) as PPDT
--		FROM #T_autodata AutoData --ER0374
--		CROSS jOIN #PlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
--		WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
--			(
--			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
--			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
--			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
--			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
--			)
----			AND
----			(
----			(autodata.sttime >= @StartTime  AND autodata.ndtime <=@EndTime)
----			OR ( autodata.sttime < @StartTime  AND autodata.ndtime <= @EndTime AND autodata.ndtime > @StartTime )
----			OR ( autodata.sttime >= @StartTime   AND autodata.sttime <@EndTime AND autodata.ndtime > @EndTime )
----			OR ( autodata.sttime < @StartTime  AND autodata.ndtime > @EndTime)
----			)
--			AND (downcodeinformation.availeffy = 1) 
--			and downcodeinformation.downid in ('BREAKFAST / LANCH')
--			AND (downcodeinformation.ThresholdfromCO <>1) --NR0097 
--			group  by autodata.id ) as T2 on T1.id=T2.id ) as T3  group by T3.mc
--	) as t4 inner join #OEE on t4.mc = #OEE.machineinterface
--end

-----------------------------------------------------------Threshold for lunch and dinner cal ends---------------------------------------------------------------------------
-----------------------------------------------------------Threshold for Settings cal starts---------------------------------------------------------------------------

--UPDATE #OEE SET MLThresholdSetting = isnull(MLThresholdSetting,0) + isNull(t2.settingthreshold,0)
--		from
--		(
--		select sum(threshold) as settingthreshold from downcodeinformation
--		where downid in ('SETUP TIME')
--		--where downid in ('BREAKFAST / LUNCH')
--		) as t2 

----------------------------------------------------------------------Threshold for Settings cal ends- -------------------------------------------------------------------------------------------------------------			

-----------------------------------------------------------------------ML Threshold for settings time cal starts (Time AsPer BOM)----------------------------------------------------------------------------------------
		UPDATE #OEE SET TimeAsPerBOM = isnull(TimeAsPerBOM,0) + isNull(t2.loss,0)
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
		and downcodeinformation.downid like '%SETUP%'
		and (downcodeinformation.ThresholdfromCO <>1) --NR0097
		group by autodata.mc) as t2 inner join #OEE on t2.mc = #OEE.machineinterface
		-- Type 2
		UPDATE #OEE SET TimeAsPerBOM = isnull(TimeAsPerBOM,0) + isNull(t2.loss,0)
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
		and downcodeinformation.downid  like '%SETUP%'
		and (downcodeinformation.ThresholdfromCO <>1) --NR0097
		group by autodata.mc
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface
		-- Type 3
		UPDATE #OEE SET TimeAsPerBOM = isnull(TimeAsPerBOM,0) + isNull(t2.loss,0)
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
		and downcodeinformation.downid like '%SETUP%'
		group by autodata.mc
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface
		-- Type 4
		UPDATE #OEE SET TimeAsPerBOM = isnull(TimeAsPerBOM,0) + isNull(t2.loss,0)
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
		and downcodeinformation.downid like '%SETUP%'
		and (downcodeinformation.ThresholdfromCO <>1) --NR0097
		group by autodata.mc
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface	
------------------------------------------------------------------------ML Threshold for settings time cal ENDS (Time AsPer BOM) ---------------------------------------------------------------- 

----------------------------------------------------------------------setting time cal STARTS- -------------------------------------------------------------------------------------------------------------			
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N'
BEGIN
UPDATE #OEE SET SettingTime = isnull(SettingTime,0) + isNull(t2.down,0)
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
		) and downid like '%SETUP%'
		group by autodata.mc
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface
end

--UPDATE #OEE SET SettingTime = isnull(SettingTime,0) + isnull(MLThresholdSetting,0)

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN
UPDATE #OEE SET SettingTime = isnull(SettingTime,0) + isNull(t2.down,0)
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
		) and downid  like '%SETUP%'
		group by autodata.mc
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface

	

	UPDATE #OEE set SettingTime =isnull(SettingTime,0) - isNull(TT.PPDT ,0)
	FROM(
		SELECT autodata.MC,SUM
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
			)and downcodeinformation.downid  like '%SETUP%'
		group by autodata.MC
	) as TT INNER JOIN #OEE ON TT.mc = #OEE.MachineInterface

end
--UPDATE #OEE SET SettingTime = isnull(SettingTime,0) + isnull(MLThresholdSetting,0)

---------------------------------------------------------- Setting time calculation ends--------------------------------------------------------------------------------------------

------------------------------------------------------------NoOf SettingTime (Frequency) starts------------------------------------------------------------------------------------
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N'
begin
UPDATE #OEE SET NoofSettings = isnull(NoofSettings,0) + isNull(t2.frequency,0)
		from
		(select mc,count(dcode) AS frequency
		from #T_autodata autodata --ER0374
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		where autodata.datatype=2 AND
		(
		(autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)
		OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
		OR (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
		OR (autodata.msttime<@StartTime and autodata.ndtime>@EndTime )
		) and downid  like '%SETUP%'
		group by autodata.mc
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface
end



If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='y'
begin
UPDATE #OEE SET NoofSettings = isnull(NoofSettings,0) + isNull(t2.frequency,0)
		from
		(select mc,count(dcode) AS frequency
		from #T_autodata autodata --ER0374
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		where autodata.datatype=2 AND
		(
		(autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)
		OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
		OR (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
		OR (autodata.msttime<@StartTime and autodata.ndtime>@EndTime )
		) and downid  like '%SETUP%'
		group by autodata.mc
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface


		UPDATE #OEE SET NoofSettings = isnull(NoofSettings,0) - isNull(tt.frequency,0)
		from
		(select mc,count(dcode) AS frequency
		from  #T_autodata autodata CROSS jOIN #PlannedDownTimes T
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)and downcodeinformation.downid  like '%SETUP%'
		group by autodata.MC
	) as TT INNER JOIN #OEE ON TT.mc = #OEE.MachineInterface



end

------------------------------------------------------------------No of Setting time calc ends----------------------------------------------------------------------------------------------

----------------------------------------------------------------Operating time (utilised time) --------------------------------------------------------------------------------
UPDATE #OEE SET OperatingTime = isnull(OperatingTime,0) + isNull(t2.cycle,0)
from
(select      mc,sum(cycletime+loadunload) as cycle
from #T_autodata autodata --ER0374
where (autodata.msttime>=@StartTime)
and (autodata.ndtime<=@EndTime)
and (autodata.datatype=1)
group by autodata.mc
) as t2 inner join #OEE on t2.mc = #OEE.machineinterface
-- Type 2
UPDATE #OEE SET OperatingTime = isnull(OperatingTime,0) + isNull(t2.cycle,0)
from
(select  mc,SUM(DateDiff(second, @StartTime, ndtime)) cycle
from #T_autodata autodata --ER0374
where (autodata.msttime<@StartTime)
and (autodata.ndtime>@StartTime)
and (autodata.ndtime<=@EndTime)
and (autodata.datatype=1)
group by autodata.mc
) as t2 inner join #OEE on t2.mc = #OEE.machineinterface
-- Type 3
UPDATE  #OEE SET OperatingTime = isnull(OperatingTime,0) + isNull(t2.cycle,0)
from
(select  mc,sum(DateDiff(second, mstTime, @Endtime)) cycle
from #T_autodata autodata --ER0374
where (autodata.msttime>=@StartTime)
and (autodata.msttime<@EndTime)
and (autodata.ndtime>@EndTime)
and (autodata.datatype=1)
group by autodata.mc
) as t2 inner join #OEE on t2.mc = #OEE.machineinterface
-- Type 4
UPDATE #OEE SET OperatingTime = isnull(OperatingTime,0) + isnull(t2.cycle,0)
from
(select mc,
sum(DateDiff(second, @StartTime, @EndTime)) cycle from #T_autodata autodata --ER0374
where (autodata.msttime<@StartTime)
and (autodata.ndtime>@EndTime)
and (autodata.datatype=1)
group by autodata.mc
)as t2 inner join #OEE on t2.mc = #OEE.machineinterface
/* Fetching Down Records from Production Cycle  */
/* If Down Records of TYPE-2*/
UPDATE  #OEE SET OperatingTime = isnull(OperatingTime,0) - isNull(t2.Down,0)
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
GROUP BY AUTODATA.mc)AS T2 Inner Join #OEE on t2.mc = #OEE.machineinterface
/* If Down Records of TYPE-3*/
UPDATE  #OEE SET OperatingTime = isnull(OperatingTime,0) - isNull(t2.Down,0)
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
GROUP BY AUTODATA.mc)AS T2 Inner Join #OEE on t2.mc = #OEE.machineinterface
/* If Down Records of TYPE-4*/
UPDATE  #OEE SET OperatingTime = isnull(OperatingTime,0) - isNull(t2.Down,0)
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
)AS T2 Inner Join #OEE on t2.mc = #OEE.machineinterface

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

-----------------------------------------------------------------------Utilization time (Operation time) ends-----------------------------------------------------------------------------------------

----------------------------------------------------------------------- ManagementLoss and Downtime Calculation Starts -------------------------------------------------------------------------------#
---Below IF condition added by Mrudula for mod 4. TO get the ML if 'Ignore_Dtime_4m_PLD'<>"Y"
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y')
BEGIN
		-- Type 1
		UPDATE #OEE SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
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
		group by autodata.mc) as t2 inner join #OEE on t2.mc = #OEE.machineinterface
		-- Type 2
		UPDATE #OEE SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
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
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface
		-- Type 3
		UPDATE #OEE SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
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
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface
		-- Type 4
		UPDATE #OEE SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
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
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface
		---get the downtime for the time period
		UPDATE #OEE SET downtime = isnull(downtime,0) + isNull(t2.down,0)
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
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface
--mod 4
End
--mod 4
---mod 4: Handling interaction between PDT and downtime . Also interaction between PDT and Management Loss
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN
	---step 1
	
	UPDATE #OEE SET downtime = isnull(downtime,0) + isNull(t2.down,0)
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
	) as t2 inner join #OEE on t2.mc = #OEE.machineinterface
	--select * from #OEE
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
	---In T4 consolidate everything at machine level and update the same to #OEE for ManagementLoss and MLDown
	
	UPDATE #OEE SET  ManagementLoss = isnull(ManagementLoss,0) + isNull(t4.Mloss,0),MLDown=isNull(MLDown,0)+isNull(t4.Dloss,0)
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
	) as t4 inner join #OEE on t4.mc = #OEE.machineinterface


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

	--UPDATE #OEE SET downtime = isnull(downtime,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)
		UPDATE #OEE SET downtime = isnull(downtime,0)+isNull(MLDown,0)

	
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

UPDATE #OEE
	SET OperatingTime=(OperatingTime-ISNULL(#PLD.pPlannedDT,0)+isnull(#PLD.IPlannedDT,0)),
	   DownTime=(DownTime-ISNULL(#PLD.dPlannedDT,0)) 
	From #OEE Inner Join #PLD on #PLD.Machineid=#OEE.Machineid

-------------------------------------------------------------------Down and Management  Calculation Ends-----------------------------------------------------------------------


---------------------------------------------------------------------Planned Loss Calculation starts----------------------------------------------------------------------------

update #OEE set PlannedLoss=isnull(PlannedLoss,0)+t1.plndloss
from
(
select MachineID,(TotalTime-(OperatingTime+DownTime)) as plndloss from #OEE
)t1 inner join #OEE on t1.MachineID=#OEE.MachineID

---------------------------------------------------------------------Planned Loss Calculation ends----------------------------------------------------------------------------

 --------------------------------------------------------------------OEE EXCLUSION Time cal starts----------------------------------------------------------------------------
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N'
BEGIN
UPDATE #OEE SET OEEExclusionTime = isnull(OEEExclusionTime,0) + isNull(t2.oeedown,0)
		from
		(select mc,sum(
				CASE
				WHEN  autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime  THEN  loadunload
				WHEN (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  THEN DateDiff(second, @StartTime, ndtime)
				WHEN (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)  THEN DateDiff(second, stTime, @Endtime)
				WHEN autodata.msttime<@StartTime and autodata.ndtime>@EndTime   THEN DateDiff(second, @StartTime, @EndTime)
				END
			)AS oeedown
		from #T_autodata autodata --ER0374
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		where autodata.datatype=2 AND
		(
		(autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)
		OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
		OR (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
		OR (autodata.msttime<@StartTime and autodata.ndtime>@EndTime )
		) and Catagory in ('OEE EXCLUSION')
		--)and Catagory in ('Operator')
		group by autodata.mc
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface
end


If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN
UPDATE #OEE SET OEEExclusionTime = isnull(OEEExclusionTime,0) + isNull(t2.oeedown,0)
		from
		(select mc,sum(
				CASE
				WHEN  autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime  THEN  loadunload
				WHEN (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  THEN DateDiff(second, @StartTime, ndtime)
				WHEN (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)  THEN DateDiff(second, stTime, @Endtime)
				WHEN autodata.msttime<@StartTime and autodata.ndtime>@EndTime   THEN DateDiff(second, @StartTime, @EndTime)
				END
			)AS oeedown
		from #T_autodata autodata --ER0374
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		where autodata.datatype=2 AND
		(
		(autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)
		OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
		OR (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
		OR (autodata.msttime<@StartTime and autodata.ndtime>@EndTime )
		) and Catagory in ('OEE EXCLUSION')
		--)and Catagory in ('Operator')
		group by autodata.mc
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface

	UPDATE #OEE set OEEExclusionTime =isnull(OEEExclusionTime,0) - isNull(TT.PPDT ,0)
	FROM(
		SELECT autodata.MC,SUM
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
		group by autodata.MC
	) as TT INNER JOIN #OEE ON TT.mc = #OEE.MachineInterface
end
 --------------------------------------------------------------------OEE EXCLUSION Time cal ends----------------------------------------------------------------------

  --------------------------------------------------------------------SuperViser down cal starts----------------------------------------------------------------------------
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N'
BEGIN
UPDATE #OEE SET SupervisorCategoryDowntime = isnull(SupervisorCategoryDowntime,0) + isNull(t2.oeedown,0)
		from
		(select mc,sum(
				CASE
				WHEN  autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime  THEN  loadunload
				WHEN (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  THEN DateDiff(second, @StartTime, ndtime)
				WHEN (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)  THEN DateDiff(second, stTime, @Endtime)
				WHEN autodata.msttime<@StartTime and autodata.ndtime>@EndTime   THEN DateDiff(second, @StartTime, @EndTime)
				END
			)AS oeedown
		from #T_autodata autodata --ER0374
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		where autodata.datatype=2 AND
		(
		(autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)
		OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
		OR (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
		OR (autodata.msttime<@StartTime and autodata.ndtime>@EndTime )
		) and Catagory in ('SuperViser')
		group by autodata.mc
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface
end


If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN
UPDATE #OEE SET SupervisorCategoryDowntime = isnull(SupervisorCategoryDowntime,0) + isNull(t2.oeedown,0)
		from
		(select mc,sum(
				CASE
				WHEN  autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime  THEN  loadunload
				WHEN (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  THEN DateDiff(second, @StartTime, ndtime)
				WHEN (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)  THEN DateDiff(second, stTime, @Endtime)
				WHEN autodata.msttime<@StartTime and autodata.ndtime>@EndTime   THEN DateDiff(second, @StartTime, @EndTime)
				END
			)AS oeedown
		from #T_autodata autodata --ER0374
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		where autodata.datatype=2 AND
		(
		(autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)
		OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
		OR (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
		OR (autodata.msttime<@StartTime and autodata.ndtime>@EndTime )
		) and Catagory in ('SuperViser')
		group by autodata.mc
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface


	UPDATE #OEE set SupervisorCategoryDowntime =isnull(SupervisorCategoryDowntime,0) - isNull(TT.PPDT ,0)
	FROM(
		SELECT autodata.MC,SUM
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
		group by autodata.MC
	) as TT INNER JOIN #OEE ON TT.mc = #OEE.MachineInterface
end
 --------------------------------------------------------------------SuperViser down Time cal ends----------------------------------------------------------------------

   --------------------------------------------------------------------Operator category down cal starts----------------------------------------------------------------------------
UPDATE #OEE SET MLThresholdOperatorCat = isnull(MLThresholdOperatorCat,0) + isNull(t2.loss,0)
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
		and downcodeinformation.Catagory in ('Operator')
		and (downcodeinformation.ThresholdfromCO <>1) --NR0097
		group by autodata.mc) as t2 inner join #OEE on t2.mc = #OEE.machineinterface
		-- Type 2
		UPDATE #OEE SET MLThresholdOperatorCat = isnull(MLThresholdOperatorCat,0) + isNull(t2.loss,0)
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
		and downcodeinformation.Catagory in ('Operator')
		and (downcodeinformation.ThresholdfromCO <>1) --NR0097
		group by autodata.mc
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface
		-- Type 3
		UPDATE #OEE SET MLThresholdOperatorCat = isnull(MLThresholdOperatorCat,0) + isNull(t2.loss,0)
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
		and downcodeinformation.Catagory in ('Operator')
		group by autodata.mc
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface
		-- Type 4
		UPDATE #OEE SET MLThresholdOperatorCat = isnull(MLThresholdOperatorCat,0) + isNull(t2.loss,0)
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
		and downcodeinformation.Catagory in ('Operator')
		and (downcodeinformation.ThresholdfromCO <>1) --NR0097
		group by autodata.mc
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface	


If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N'
BEGIN
UPDATE #OEE SET OperatorCategoryDowntime = isnull(OperatorCategoryDowntime,0) + isNull(t2.oeedown,0)
		from
		(select mc,sum(
				CASE
				WHEN  autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime  THEN  loadunload
				WHEN (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  THEN DateDiff(second, @StartTime, ndtime)
				WHEN (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)  THEN DateDiff(second, stTime, @Endtime)
				WHEN autodata.msttime<@StartTime and autodata.ndtime>@EndTime   THEN DateDiff(second, @StartTime, @EndTime)
				END
			)AS oeedown
		from #T_autodata autodata --ER0374
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		where autodata.datatype=2 AND
		(
		(autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)
		OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
		OR (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
		OR (autodata.msttime<@StartTime and autodata.ndtime>@EndTime )
		) and Catagory in ('Operator')
		--) and downcodeinformation.Catagory in ('Operator')
		group by autodata.mc
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface

				UPDATE #OEE SET OperatorCategoryDowntime=isnull(OperatorCategoryDowntime,0)-isnull(MLThresholdOperatorCat,0)

end


If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN
UPDATE #OEE SET OperatorCategoryDowntime = isnull(OperatorCategoryDowntime,0) + isNull(t2.oeedown,0)
		from
		(select mc,sum(
				CASE
				WHEN  autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime  THEN  loadunload
				WHEN (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  THEN DateDiff(second, @StartTime, ndtime)
				WHEN (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)  THEN DateDiff(second, stTime, @Endtime)
				WHEN autodata.msttime<@StartTime and autodata.ndtime>@EndTime   THEN DateDiff(second, @StartTime, @EndTime)
				END
			)AS oeedown
		from #T_autodata autodata --ER0374
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		where autodata.datatype=2 AND
		(
		(autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)
		OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
		OR (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
		OR (autodata.msttime<@StartTime and autodata.ndtime>@EndTime )
		) and Catagory in ('Operator')
		--)and downcodeinformation.Catagory in ('Operator')
		group by autodata.mc
		) as t2 inner join #OEE on t2.mc = #OEE.machineinterface

	UPDATE #OEE set OperatorCategoryDowntime =isnull(OperatorCategoryDowntime,0) - isNull(TT.PPDT ,0)
	FROM(
		SELECT autodata.MC,SUM
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
		group by autodata.MC
	) as TT INNER JOIN #OEE ON TT.mc = #OEE.MachineInterface


UPDATE #OEE SET OperatorCategoryDowntime=isnull(OperatorCategoryDowntime,0)-isnull(MLThresholdOperatorCat,0)

end
 --------------------------------------------------------------------Operator category down Time cal ends----------------------------------------------------------------------

-- --------------------------------------------------------------------Quality efficicency cal starts---------------------------------------------------------------------------
 UPDATE #OEE SET components = ISNULL(components,0) + ISNULL(t2.comp,0)
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
) As T2 Inner join #OEE on T2.mc = #OEE.machineinterface

--Apply Exception on Count..


--Mod 4 Apply PDT for calculation of Count
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	UPDATE #OEE SET components = ISNULL(components,0) - ISNULL(T2.comp,0) from(
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
	) as T2 inner join #OEE on T2.mc = #OEE.machineinterface
END


Update #OEE set RejCount = isnull(RejCount,0) + isnull(T1.RejQty,0)
From
( Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A
inner join Machineinformation M on A.mc=M.interfaceid
inner join #OEE on #OEE.machineid=M.machineid 
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
where A.CreatedTS>=@StartTime and A.CreatedTS<@Endtime and A.flag = 'Rejection'
and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000'
group by A.mc,M.Machineid
)T1 inner join #OEE B on B.Machineid=T1.Machineid 

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	Update #OEE set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from
	(Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A
	inner join Machineinformation M on A.mc=M.interfaceid
	inner join #OEE on #OEE.machineid=M.machineid 
	inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
	Cross join Planneddowntimes P
	where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid 
	and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000' and
	A.CreatedTS>=@StartTime and A.CreatedTS<@Endtime And
	A.CreatedTS>=P.Starttime and A.CreatedTS<P.endtime
	group by A.mc,M.Machineid)T1 inner join #OEE B on B.Machineid=T1.Machineid 
END

Update #OEE set RejCount = isnull(RejCount,0) + isnull(T1.RejQty,0)
From
( Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A
inner join Machineinformation M on A.mc=M.interfaceid
inner join #OEE on #OEE.machineid=M.machineid 
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
inner join #shift S on convert(nvarchar(10),(A.RejDate),126)=S.shiftdate and A.RejShift=S.shiftid --DR0333
where A.flag = 'Rejection' and A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (S.shiftdate) and  --DR0333
Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
group by A.mc,M.Machineid
)T1 inner join #OEE B on B.Machineid=T1.Machineid 

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	Update #OEE set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from
	(Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A
	inner join Machineinformation M on A.mc=M.interfaceid
	inner join #OEE on #OEE.machineid=M.machineid 
	inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
	inner join #shift S on convert(nvarchar(10),(A.RejDate),126)=S.shiftdate and A.RejShift=S.shiftid --DR0333
	Cross join Planneddowntimes P
	where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid and
	A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (S.shiftdate) and --DR0333
	Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
	and P.starttime>=S.Shiftstart and P.Endtime<=S.shiftend
	group by A.mc,M.Machineid)T1 inner join #OEE B on B.Machineid=T1.Machineid 
END

UPDATE #OEE SET QualityEfficiency= ISNULL(QualityEfficiency,1) + IsNull(T1.QE,1) 
FROM(Select MachineID,
CAST((Sum(Components))As Float)/CAST((Sum(IsNull(Components,0))+Sum(IsNull(RejCount,0))) AS Float)As QE
From #OEE Where Components<>0 Group By MachineID
)AS T1 Inner Join #OEE ON  #OEE.MachineID=T1.MachineID
 -----------------------------------------------------------------------------CAL OF QUALITY EFFICIENCY ENDS-----------------------------------------------------------------------------------

 -----------------------------------------------------------------------------Cal of Summation of standard time (cn) starts--------------------------------------------------------------------

 
UPDATE #OEE SET SummationofStandardTime = isnull(SummationofStandardTime,0) + isNull(t2.C1N1,0)
from
(select mc,
SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))* autodata.partscount) C1N1
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
) as t2 inner join #OEE on t2.mc = #OEE.machineinterface
-- mod 4 Ignore count from CN calculation which is over lapping with PDT
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	UPDATE #OEE SET SummationofStandardTime = isnull(SummationofStandardTime,0) - isNull(t2.C1N1,0)
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
	inner join #OEE  on t2.mc = #OEE.machineinterface
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



insert into #ShiftProductionFromAutodataT1(machineid,MachineInterface,ShiftDate,UstartShift,UEndShift,UtilisedTime)
select distinct #OEE.machineid,#OEE.MachineInterface,s.ShiftDate,s.ShftSTtime,s.ShftEndTime,0
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

--select machineid,MachineInterface,UstartShift,UEndShift,ShiftDate,UtilisedTime,UtilisedTime/60 from #ShiftProductionFromAutodataT1
--order by machineid

-------------------------------------------------------------------------------Calculation of third shift utilised time ends---------------------------------------------------------------------------------

----------------------------------------------------------------------------  update Calculation of third shift utilised time to #oee---------------------------------------------------------------------------------

update #OEE set  UtilisedTime3rdShift=isnull(t1.utilisedTimepershift,0)
from
(
select machineid,sum(UtilisedTime) as utilisedTimepershift   from #ShiftProductionFromAutodataT1    
group by machineid
)t1 inner join #oee on t1.machineid=#OEE.MachineID

update #OEE set NonWorking=isnull((isnull(NonWorking,0)-isnull(UtilisedTime3rdShift,0)),0)


select MachineID,MachineInterface,ISNULL(round((TotalTime/60),2),0) as TotalTime,ISNULL(round((NonWorking/60),2),0) as NonWorking,ISNULL(round((LunchDinner/60),2),0) as LunchDinner,ISNULL(round((SettingTime/60),2),0) as SettingTime,
ISNULL(NoofSettings,0) AS NoofSettings,ISNULL(round((OperatingTime/60),2),0) as OperatingTime,ISNULL(round((downtime/60),2),0) as downtime,ISNULL(round((ManagementLoss/60),2),0) as managemntloss, ISNULL(round((PlannedLoss/60),2),0) as PlannedLoss,ISNULL(round((SummationofStandardTime)/60,2),0) as SummationofStandardTime,ISNULL(round((OEEExclusionTime/60),2),0) as OEEExclusionTime,
ISNULL(round((SupervisorCategoryDowntime/60),2),0) as SupervisorCategoryDowntime,
ISNULL(round((OperatorCategoryDowntime/60),2),0) as OperatorCategoryDowntime,ISNULL(ROUND((QualityEfficiency*100),1),0) as QualityEfficiency,ISNULL(ROUND((TIMEASPERBOM/3600),1),0) AS Time_Per_BOM,isnull((UtilisedTime3rdShift/60),0) as UtilisedTime3rdShift from #OEE

end
