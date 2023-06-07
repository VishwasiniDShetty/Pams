/****** Object:  Procedure [dbo].[s_GetMICOWeekly_Shift_ProductionReport]    Committed by VersionSQL https://www.versionsql.com ******/

/************************************************************************************************************
used in report :- SM_Mico_weekly_Production_Down.rpt
mod 1:- By Mrudula M. Rao on 01-apr-2009. For DR0179.Getting negetive value for non reported down time
mod 2:- optimization by Mrudula.	
mod 3 :- ER0181 By Kusuma M.H on 15-May-2009.2) Modify all the procedures accordingly. Qualify machine wherever we are making use of component and opeartion no.
mod 4 :- ER0182 By Kusuma M.H on 15-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
ER0210 By Karthikg on 25/Feb/2010 :: Introduce PDT on 5150. Handle PDT at Machine Level.
s_GetMICOWeekly_Shift_ProductionReport '2009-12-01','2009-12-03','MCV 400','A_Machining  Center VMC','','','','','','','','','',0
DR0236 - By SwathiKS on 23-Jun-2010 :: Use proper conditions in case statements to remove icd's from type 4 production records.
DR0292 - KarthikR - 31/Aug/2011 :: Use Proper Join Conditions While Fetching ICD Records From Autodata To Handle Negative Production Efficiency in
 SMARTMANAGER->ANALYSIS REPORT STANDARD->PRODUCTION AND DOWNTIME REPORT-WEEKLY BY DAY -> SM_Mico_weekly_Production_Down.rpt
************************************************************************************************************/
---s_GetMICOWeekly_Shift_ProductionReport '2011-06-04','2011-06-10','IN2101-ACE1','','','','','','','','','','','0'
CREATE                  procedure [dbo].[s_GetMICOWeekly_Shift_ProductionReport]
	@StartDate datetime,
	@EndDate datetime,
	@MachineID nvarchar(50) = '',
	@PlantID  nvarchar(50) = '',
	@ComponentID nvarchar(50) = '',
	@OperationNo nvarchar(50) = '',
	@Reptype nvarchar(20) = '',
	@OperatorID  nvarchar(50) = '',
	@MachineIDLabel nvarchar(50) ='ALL',
	@OperatorIDLabel nvarchar(50) = 'ALL',
	@DownIDLabel nvarchar(50) = 'ALL',
	@ComponentIDLabel nvarchar(50) = 'ALL',
	@DownID  nvarchar(4000) = '',
	@ExcludeParam int
AS
BEGIN
Declare @strsql nvarchar(4000)
Declare @strmachine nvarchar(50)
Declare @strplant nvarchar(50)
Declare @StartTime DateTime
Declare @EndTime DateTime
declare @Targetsource nvarchar(50)
select @Targetsource=ValueInText from Shopdefaults where Parameter='TargetFrom'
Select @strsql = ''
Select @strmachine = ''
Select @strplant = ''
if isnull(@machineid,'') <> ''
Begin
	Select @strmachine = ' and M.MachineID = N''' + @MachineID + ''' '
End
if isnull(@PlantID,'') <> ''
Begin
	Select @strplant = ' and P.PlantID = N''' + @PlantID + ''' '
End
CREATE TABLE #WeekShiftDetails (
	DDate datetime,
	Shift nvarchar(20),
	StartTime datetime,
	EndTime datetime
)
CREATE TABLE #UtilisedTimeDay (
	Date1 datetime,
	MachineID nvarchar(50),
	machineinterface nvarchar(50),
	StartTime datetime,
	EndTime datetime,
	utilisedTime float,
	Idealtarget int default 0,
	MachineTime int default 0
)
CREATE TABLE #FinalData (
	Date1 datetime,
	MachineID nvarchar(50),
	machineinterface nvarchar(50),
	ShiftID nvarchar(20),
	StartTime datetime,
	EndTime datetime,
	Components int default 0,
	utilisedTime float,
	Idealtarget int default 0,
	TotMachinehour float
)
CREATE TABLE #Exceptions
(
	MachineID NVarChar(50),
	ComponentID Nvarchar(50),
	OperationNo Int,
	ShiftStartTime DateTime,
	ShiftEndTime DateTime,
	StartTime DateTime,
	EndTime DateTime,
	IdealCount Int,
	ActualCount Int,
	ExCount Int
)
Create table #PlannedDownTimes
(
	MachineID nvarchar(50),
	MachineInterface nvarchar(50),
	StartTime DateTime,
	EndTime DateTime
)
while @StartDate<=@EndDate
BEGIN
	insert into #WeekShiftDetails (DDate,Shift,StartTime,EndTime)
	EXEC s_GetShiftTime @StartDate
	select @StartDate=dateadd(day,1,@StartDate)
END
select @StartTime = min(StartTime) from #WeekShiftDetails
select @EndTime = max(EndTime) from #WeekShiftDetails
Select @strsql = @strsql + 'insert into #FinalData (Date1,MachineID,machineinterface,ShiftID,StartTime,EndTime)'
Select @strsql = @strsql + 'Select W.DDate,M.MachineID,M.InterfaceID,W.Shift,W.StartTime,W.EndTime from #WeekShiftDetails W '
Select @strsql = @strsql + 'inner join machineinformation M on 1=1 ' + @strmachine
Select @strsql = @strsql + 'inner join plantmachine P on P.MachineID=M.MachineID ' + @strplant
exec(@strsql)
SET @strSql = ''
SELECT @StrSql = 'INSERT INTO #Exceptions(MachineID ,ComponentID,OperationNo,ShiftStartTime,ShiftEndTime,StartTime,EndTime,IdealCount ,ActualCount ,ExCount )
		SELECT Ex.MachineID ,Ex.ComponentID,Ex.OperationNo,F.StartTime,F.EndTime,
		Case When Ex.StartTime>=F.StartTime then Ex.StartTime else F.StartTime end as StartTime,
		Case When Ex.EndTime<=F.EndTime then Ex.EndTime else F.EndTime end as EndTime,
		IdealCount,ActualCount,0
		From ProductionCountException Ex
		Inner Join MachineInformation M ON Ex.MachineID=M.MachineID
		Inner Join ComponentInformation C ON Ex.ComponentID=C.ComponentID
		Inner Join Componentoperationpricing O ON Ex.OperationNo=O.OperationNo AND C.ComponentID=O.ComponentID
		Inner join #FinalData F on F.MachineID = Ex.MachineID'
SELECT @StrSql = @StrSql + ' and O.MachineId=Ex.MachineId '
SELECT @StrSql = @StrSql + ' WHERE  M.MultiSpindleFlag=1 '
SELECT @StrSql = @StrSql + @strmachine
SELECT @StrSql = @StrSql +
		'AND ((Ex.StartTime>=F.StartTime AND Ex.EndTime<= F.EndTime )
		OR (Ex.StartTime<F.StartTime AND Ex.EndTime>F.StartTime AND Ex.EndTime<= F.EndTime)
		OR(Ex.StartTime>=F.StartTime AND Ex.EndTime> F.EndTime AND Ex.StartTime< F.EndTime)
		OR(Ex.StartTime<F.StartTime AND Ex.EndTime> F.EndTime ))'
Exec (@strsql)
SET @strSql = ''
SET @strSql = 'Insert into #PlannedDownTimes
	SELECT M.MachineID,M.InterfaceID,
		CASE When StartTime<''' + convert(nvarchar(20),@StartTime,120)+''' Then ''' + convert(nvarchar(20),@StartTime,120)+''' Else StartTime End As StartTime,
		CASE When EndTime>''' + convert(nvarchar(20),@EndTime,120)+''' Then ''' + convert(nvarchar(20),@EndTime,120)+''' Else EndTime End As EndTime
	FROM PlannedDownTimes inner join MachineInformation M on PlannedDownTimes.machine = M.MachineID
	WHERE PDTstatus =1 and(
	(StartTime >= ''' + convert(nvarchar(20),@StartTime,120)+''' AND EndTime <=''' + convert(nvarchar(20),@EndTime,120)+''')
	OR ( StartTime < ''' + convert(nvarchar(20),@StartTime,120)+'''  AND EndTime <= ''' + convert(nvarchar(20),@EndTime,120)+''' AND EndTime > ''' + convert(nvarchar(20),@StartTime,120)+''' )
	OR ( StartTime >= ''' + convert(nvarchar(20),@StartTime,120)+'''   AND StartTime <''' + convert(nvarchar(20),@EndTime,120)+''' AND EndTime > ''' + convert(nvarchar(20),@EndTime,120)+''' )
	OR ( StartTime < ''' + convert(nvarchar(20),@StartTime,120)+'''  AND EndTime > ''' + convert(nvarchar(20),@EndTime,120)+''')) '
SET @strSql =  @strSql + @strMachine + ' ORDER BY M.MachineID,StartTime'
EXEC(@strSql)


INSERT INTO #UtilisedTimeDay
select min(Date1),MachineID,machineinterface,min(StartTime),max(EndTime),0,0,0 from #FinalData group by MachineID,machineinterface,Date1
-- Get the utilised time



update #UtilisedTimeDay set UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
from(
	select mc, SUM(CASE
			WHEN (autodata.msttime>=D.StartTime)and (autodata.ndtime<=D.EndTime) then (autodata.cycletime+autodata.loadunload)
			WHEN (autodata.msttime<D.StartTime)and (autodata.ndtime>D.StartTime) and (autodata.ndtime<=D.EndTime) then DateDiff(second,D.StartTime,ndtime)
			WHEN (autodata.msttime>=D.StartTime) and (autodata.msttime<D.EndTime) and (autodata.ndtime>D.EndTime) then DateDiff(second,mstTime,D.EndTime)
			WHEN (autodata.msttime<D.StartTime) and (autodata.ndtime>D.EndTime) then DateDiff(second, D.StartTime, D.EndTime)
			END) as cycle,D.Date1 from autodata inner join #UtilisedTimeDay D on autodata.mc=D.machineinterface
			WHERE (autodata.datatype=1) AND
			(((autodata.msttime>=D.StartTime) and (autodata.ndtime<=D.EndTime))
			OR ((autodata.msttime<D.StartTime)and (autodata.ndtime>D.StartTime) and (autodata.ndtime<=D.EndTime))
			OR ((autodata.msttime>=D.StartTime) and (autodata.msttime<D.EndTime) and (autodata.ndtime>D.EndTime))
			OR ((autodata.msttime<D.StartTime) and (autodata.ndtime>D.EndTime)))
			group by autodata.mc,D.Date1
) As t2 inner join #UtilisedTimeDay on t2.mc = #UtilisedTimeDay.machineinterface and t2.date1=#UtilisedTimeDay.Date1




/* DR0292 Commented From here.
UPDATE  #UtilisedTimeDay SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0) FROM (
	Select D.date1,AutoData.mc,
	SUM(
	CASE
		When autodata.sttime <= D.StartTime Then datediff(s, D.StartTime,autodata.ndtime )
		When autodata.sttime > D.StartTime Then datediff(s , autodata.sttime,autodata.ndtime)
	END) as Down
	From AutoData inner join #UtilisedTimeDay D on autodata.mc=D.machineinterface INNER Join
		(Select mc,Sttime,NdTime From AutoData inner join #UtilisedTimeDay D on autodata.mc=D.machineinterface
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(msttime < D.StartTime)And (ndtime > D.StartTime) AND (ndtime <= D.EndTime)) as T1
	ON AutoData.mc=T1.mc
	Where AutoData.DataType=2
	And ( autodata.Sttime > T1.Sttime )
	And ( autodata.ndtime <  T1.ndtime )
	AND ( autodata.ndtime >  D.StartTime )
	GROUP BY AUTODATA.mc,D.date1
)AS t2 Inner Join #UtilisedTimeDay on t2.mc = #UtilisedTimeDay.machineinterface and t2.date1=#UtilisedTimeDay.Date1

UPDATE  #UtilisedTimeDay SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
FROM
(Select D.date1,AutoData.mc ,
SUM(CASE
	When autodata.ndtime > D.EndTime Then datediff(s,autodata.sttime, D.EndTime )
	When autodata.ndtime <=D.EndTime Then datediff(s , autodata.sttime,autodata.ndtime)
END) as Down
From AutoData inner join #UtilisedTimeDay D on autodata.mc=D.machineinterface INNER Join
	(Select mc,Sttime,NdTime From AutoData inner join #UtilisedTimeDay D on autodata.mc=D.machineinterface
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(sttime >= D.StartTime)And (ndtime > D.EndTime) and (sttime<D.EndTime) ) as T1
ON AutoData.mc=T1.mc
Where AutoData.DataType=2
And (T1.Sttime < autodata.sttime  )
And ( T1.ndtime >  autodata.ndtime)
AND (autodata.sttime  <  D.EndTime)
GROUP BY AUTODATA.mc,D.date1)AS T2 Inner Join #UtilisedTimeDay on t2.mc = #UtilisedTimeDay.machineinterface and t2.date1=#UtilisedTimeDay.Date1

UPDATE  #UtilisedTimeDay SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
FROM
(Select D.date1,AutoData.mc ,
--DR0236 - By SwathiKS on 23-Jun-2010 from here
--SUM(CASE
--	When autodata.sttime < D.StartTime AND autodata.ndtime<=D.EndTime Then datediff(s, D.StartTime,autodata.ndtime )
--	When autodata.ndtime >= D.EndTime AND autodata.sttime>D.StartTime Then datediff(s,autodata.sttime, D.EndTime )
--	When autodata.sttime >= D.StartTime AND
--       autodata.ndtime <= D.EndTime Then datediff(s , autodata.sttime,autodata.ndtime)
--	When autodata.sttime<D.StartTime AND autodata.ndtime>D.EndTime   Then datediff(s , D.StartTime,D.EndTime)
--END) as Down
SUM(CASE
	When autodata.sttime >= D.StartTime AND autodata.ndtime <= D.EndTime Then datediff(s , autodata.sttime,autodata.ndtime) --Type1
	When autodata.sttime < D.StartTime AND autodata.ndtime> D.StartTime AND autodata.ndtime<=D.EndTime Then datediff(s, D.StartTime,autodata.ndtime ) --Type2
	When autodata.sttime>=D.StartTime AND autodata.sttime<D.EndTime AND autodata.ndtime>D.EndTime   Then datediff(s,autodata.sttime, D.EndTime ) --Type3
	When autodata.sttime<D.StartTime AND autodata.ndtime >D.EndTime  Then datediff(s , D.StartTime,D.EndTime)--Type4
END) as Down
--DR0236 - By SwathiKS on 23-Jun-2010 till here

From AutoData inner join #UtilisedTimeDay D on autodata.mc=D.machineinterface INNER Join
	(Select mc,Sttime,NdTime From AutoData inner join #UtilisedTimeDay D on autodata.mc=D.machineinterface
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(msttime < D.StartTime)And (ndtime > D.EndTime) ) as T1
ON AutoData.mc=T1.mc
Where AutoData.DataType=2
And (T1.Sttime < autodata.sttime  )
And ( T1.ndtime >  autodata.ndtime)
AND (autodata.ndtime  >  D.StartTime)
AND (autodata.sttime  <  D.EndTime)
GROUP BY AUTODATA.mc,D.date1
)AS T2 Inner Join #UtilisedTimeDay on t2.mc = #UtilisedTimeDay.machineinterface and t2.date1=#UtilisedTimeDay.Date1
DR0292 Commented Till Here. */

--DR0292 Changes From Here.
/* Fetching Down Records from Production Cycle  */
/* If Down Records of TYPE-2*/
UPDATE  #UtilisedTimeDay SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0) FROM (
	Select D.date1,AutoData.mc,
	SUM(
	CASE
		When autodata.sttime <= D.StartTime Then datediff(s, D.StartTime,autodata.ndtime )
		When autodata.sttime > D.StartTime Then datediff(s , autodata.sttime,autodata.ndtime)
	END) as Down
	From AutoData inner join #UtilisedTimeDay D on autodata.mc=D.machineinterface INNER Join
		(Select mc,Sttime,NdTime,D.StartTime,D.endtime From AutoData inner join #UtilisedTimeDay D on autodata.mc=D.machineinterface
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(msttime < D.StartTime)And (ndtime > D.StartTime) AND (ndtime <= D.EndTime)) as T1
	ON AutoData.mc=T1.mc and T1.StartTime=D.StartTime and t1.endTime=D.endTime
	Where AutoData.DataType=2
	And ( autodata.Sttime > T1.Sttime )
	And ( autodata.ndtime <  T1.ndtime )
	AND ( autodata.ndtime >  D.StartTime )
	GROUP BY AUTODATA.mc,D.date1
)AS t2 Inner Join #UtilisedTimeDay on t2.mc = #UtilisedTimeDay.machineinterface and t2.date1=#UtilisedTimeDay.Date1


/* If Down Records of TYPE-3*/
UPDATE  #UtilisedTimeDay SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
FROM
(Select D.date1,AutoData.mc ,
SUM(CASE
	When autodata.ndtime > D.EndTime Then datediff(s,autodata.sttime, D.EndTime )
	When autodata.ndtime <=D.EndTime Then datediff(s , autodata.sttime,autodata.ndtime)
END) as Down
From AutoData inner join #UtilisedTimeDay D on autodata.mc=D.machineinterface INNER Join
	(Select mc,Sttime,NdTime,D.StartTime,D.endtime From AutoData inner join #UtilisedTimeDay D on autodata.mc=D.machineinterface
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(sttime >= D.StartTime)And (ndtime > D.EndTime) and (sttime<D.EndTime) ) as T1
ON AutoData.mc=T1.mc and T1.StartTime=D.StartTime and t1.endTime=D.endTime
Where AutoData.DataType=2
And (T1.Sttime < autodata.sttime)
And ( T1.ndtime >  autodata.ndtime)
AND (autodata.sttime  <  D.EndTime)
GROUP BY AUTODATA.mc,D.date1)AS T2 Inner Join #UtilisedTimeDay on t2.mc = #UtilisedTimeDay.machineinterface and t2.date1=#UtilisedTimeDay.Date1


/* If Down Records of TYPE-4*/
UPDATE  #UtilisedTimeDay SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
FROM
(Select D.date1,AutoData.mc ,
--DR0236 - By SwathiKS on 23-Jun-2010 from here
--SUM(CASE
--	When autodata.sttime < D.StartTime AND autodata.ndtime<=D.EndTime Then datediff(s, D.StartTime,autodata.ndtime )
--	When autodata.ndtime >= D.EndTime AND autodata.sttime>D.StartTime Then datediff(s,autodata.sttime, D.EndTime )
--	When autodata.sttime >= D.StartTime AND
--       autodata.ndtime <= D.EndTime Then datediff(s , autodata.sttime,autodata.ndtime)
--	When autodata.sttime<D.StartTime AND autodata.ndtime>D.EndTime   Then datediff(s , D.StartTime,D.EndTime)
--END) as Down
SUM(CASE
	When autodata.sttime >= D.StartTime AND autodata.ndtime <= D.EndTime Then datediff(s , autodata.sttime,autodata.ndtime) --Type1
	When autodata.sttime < D.StartTime AND autodata.ndtime> D.StartTime AND autodata.ndtime<=D.EndTime Then datediff(s, D.StartTime,autodata.ndtime ) --Type2
	When autodata.sttime>=D.StartTime AND autodata.sttime<D.EndTime AND autodata.ndtime>D.EndTime   Then datediff(s,autodata.sttime, D.EndTime ) --Type3
	When autodata.sttime<D.StartTime AND autodata.ndtime >D.EndTime  Then datediff(s , D.StartTime,D.EndTime)--Type4
END) as Down
--DR0236 - By SwathiKS on 23-Jun-2010 till here

From AutoData inner join #UtilisedTimeDay D on autodata.mc=D.machineinterface INNER Join
	(Select mc,Sttime,NdTime,D.StartTime,D.endtime From AutoData inner join #UtilisedTimeDay D on autodata.mc=D.machineinterface
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(msttime < D.StartTime)And (ndtime > D.EndTime) ) as T1
ON AutoData.mc=T1.mc and T1.StartTime=D.StartTime and t1.endTime=D.endTime
Where AutoData.DataType=2
And (T1.Sttime < autodata.sttime  )
And ( T1.ndtime >  autodata.ndtime)
AND (autodata.ndtime  >  D.StartTime)
AND (autodata.sttime  <  D.EndTime)
GROUP BY AUTODATA.mc,D.date1
)AS T2 Inner Join #UtilisedTimeDay on t2.mc = #UtilisedTimeDay.machineinterface and t2.date1=#UtilisedTimeDay.Date1
--DR0292 Changes Till Here.


If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
BEGIN
	--Get utilised time over lapping with PDT.
	UPDATE #UtilisedTimeDay set UtilisedTime =isnull(#UtilisedTimeDay.UtilisedTime,0) - isNull(TT.PPDT ,0) FROM(
			--Production Time in PDT
			SELECT autodata.MC,D.date1,SUM
				(CASE
				WHEN autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.cycletime+autodata.loadunload)
				WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
				WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )
				WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
				END)  as PPDT
			FROM AutoData CROSS jOIN #PlannedDownTimes T
			inner join #UtilisedTimeDay D on autodata.mc=D.machineinterface and D.StartTime<=T.StartTime and D.EndTime>=T.EndTime
			WHERE autodata.DataType=1 And T.MachineInterface=AutoData.mc AND
				(
				(autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
				OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
				OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )
				OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )
			group by autodata.MC,D.date1
	)as TT INNER JOIN #UtilisedTimeDay ON TT.mc = #UtilisedTimeDay.MachineInterface and TT.date1 = #UtilisedTimeDay.date1
	--Handle intearction between ICD and PDT for type 1 production record for the selected time period.
		UPDATE  #UtilisedTimeDay set UtilisedTime =isnull(#UtilisedTimeDay.UtilisedTime,0) + isNull(TT.IPDT ,0) 	FROM	(
			Select AutoData.mc,D.date1,
			SUM(
			CASE 	
				When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
				When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
				When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
				when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
			END) as IPDT
			From AutoData INNER Join
				(Select mc,Sttime,NdTime From AutoData inner join #UtilisedTimeDay D on autodata.mc=D.machineinterface
					Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
					(msttime >= D.StartTime) AND (ndtime <= D.EndTime)) as T1
			ON AutoData.mc=T1.mc CROSS jOIN #PlannedDownTimes T
			inner join #UtilisedTimeDay D on autodata.mc=D.machineinterface and D.StartTime<=T.StartTime and D.EndTime>=T.EndTime
			Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc
			And (( autodata.Sttime > T1.Sttime )
			And ( autodata.ndtime <  T1.ndtime )
			)
			AND
			((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
			or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
			or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
			or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )
			GROUP BY AUTODATA.mc,D.date1
		)as TT INNER JOIN #UtilisedTimeDay ON TT.mc = #UtilisedTimeDay.MachineInterface and TT.date1 = #UtilisedTimeDay.date1
	
/* Fetching Down Records from Production Cycle  */
	/* If production  Records of TYPE-2*/
	UPDATE  #UtilisedTimeDay set UtilisedTime =isnull(#UtilisedTimeDay.UtilisedTime,0) + isNull(TT.IPDT ,0) 	FROM	(
		Select AutoData.mc,D.date1,
		SUM(
		CASE 	
			When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
			When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
			When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
			when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		From AutoData INNER Join
			(Select mc,Sttime,NdTime From AutoData inner join #UtilisedTimeDay D on autodata.mc=D.machineinterface
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(msttime < D.StartTime)And (ndtime > D.StartTime) AND (ndtime <= D.EndTime)) as T1
		ON AutoData.mc=T1.mc CROSS jOIN #PlannedDownTimes T
		inner join #UtilisedTimeDay D on autodata.mc=D.machineinterface and D.StartTime<=T.StartTime and D.EndTime>=T.EndTime
		Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc
		And (( autodata.Sttime > T1.Sttime )
		And ( autodata.ndtime <  T1.ndtime )
		AND ( autodata.ndtime >  D.StartTime ))
		AND
		(( T.StartTime >= D.StartTime )
		And ( T.StartTime <  T1.ndtime ) )
		GROUP BY AUTODATA.mc,D.date1
	)as TT INNER JOIN #UtilisedTimeDay ON TT.mc = #UtilisedTimeDay.MachineInterface and TT.date1 = #UtilisedTimeDay.date1
	
	/* If production Records of TYPE-3*/
	UPDATE  #UtilisedTimeDay set UtilisedTime =isnull(#UtilisedTimeDay.UtilisedTime,0) + isNull(TT.IPDT ,0) 	FROM	(
		Select AutoData.mc ,D.date1,
		SUM(
		CASE 	
			When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
			When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
			When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
			when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		From AutoData INNER Join
			(Select mc,Sttime,NdTime From AutoData inner join #UtilisedTimeDay D on autodata.mc=D.machineinterface
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(sttime >= D.StartTime)And (ndtime > D.EndTime) and autodata.sttime <D.EndTime) as T1
		ON AutoData.mc=T1.mc CROSS jOIN #PlannedDownTimes T
		inner join #UtilisedTimeDay D on autodata.mc=D.machineinterface and D.StartTime<=T.StartTime and D.EndTime>=T.EndTime
		Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc
		And ((T1.Sttime < autodata.sttime  )
		And ( T1.ndtime >  autodata.ndtime)
		AND (autodata.msttime  <  D.EndTime))
		AND
		(( T.EndTime > T1.Sttime )
		And ( T.EndTime <=D.EndTime ) )
		GROUP BY AUTODATA.mc,D.date1
	)as TT INNER JOIN #UtilisedTimeDay ON TT.mc = #UtilisedTimeDay.MachineInterface and TT.date1 = #UtilisedTimeDay.date1
	
	
	/* If production Records of TYPE-4*/
	UPDATE  #UtilisedTimeDay set UtilisedTime =isnull(#UtilisedTimeDay.UtilisedTime,0) + isNull(TT.IPDT ,0) 	FROM	(
		Select AutoData.mc ,D.date1,
		SUM(
		CASE 	
			When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
			When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
			When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
			when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		From AutoData INNER Join
			(Select mc,Sttime,NdTime From AutoData inner join #UtilisedTimeDay D on autodata.mc=D.machineinterface
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(msttime < D.StartTime)And (ndtime > D.EndTime)) as T1
		ON AutoData.mc=T1.mc CROSS jOIN #PlannedDownTimes T
		inner join #UtilisedTimeDay D on autodata.mc=D.machineinterface and D.StartTime<=T.StartTime and D.EndTime>=T.EndTime
		Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc
		And ( (T1.Sttime < autodata.sttime  )
			And ( T1.ndtime >  autodata.ndtime)
			AND (autodata.ndtime  >  D.StartTime)
			AND (autodata.sttime  <  D.EndTime))
		AND
		(( T.StartTime >=D.StartTime)
		And ( T.EndTime <=D.EndTime ) )
		GROUP BY AUTODATA.mc,D.date1
	)as TT INNER JOIN #UtilisedTimeDay ON TT.mc = #UtilisedTimeDay.MachineInterface and TT.date1 = #UtilisedTimeDay.date1
End
--Following IF condition is added to get the exception count if there are any exception rule defined.
if (select count(*) from #Exceptions)> 0
Begin
	update #Exceptions set ExCount = isnull(#Exceptions.ExCount,0) + isnull(T1.components,0) from(
		select M.machineid,C.ComponentID,O.OperationNo,#Exceptions.StartTime,#Exceptions.EndTime,sum(A.partscount/O.suboperations) as components
		from autodata A
		inner join machineinformation M on M.interfaceid=A.mc
		inner join componentinformation C on C.interfaceid=A.comp
		inner join componentoperationpricing O on O.interfaceid=A.opn and C.componentid=O.componentid and O.MachineID = M.MachineID
		inner join #Exceptions on #Exceptions.machineid=M.Machineid and #Exceptions.ComponentID=C.ComponentID and #Exceptions.OperationNo=O.OperationNo
		where A.datatype=1 and A.ndtime>#Exceptions.StartTime and A.ndtime<=#Exceptions.EndTime
		group by M.machineid,C.ComponentID,O.OperationNo,#Exceptions.StartTime,#Exceptions.EndTime
	) as T1 inner join #Exceptions on #Exceptions.machineid=T1.machineid
	and #Exceptions.ComponentID=T1.ComponentID and #Exceptions.OperationNo=T1.OperationNo
	and #Exceptions.StartTime=T1.StartTime and #Exceptions.EndTime=T1.EndTime
		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
		BEGIN
				UPDATE #Exceptions SET ExCount=ISNULL(ExCount,0) - ISNULL(T3.compCount,0)
				From
				(
					SELECT T2.MachineID AS MachineID,T2.ComponentID,T2.OperationNo,T2.StartTime AS StartTime,T2.EndTime AS EndTime,
					SUM(CEILING (CAST(T2.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as compCount
					From
					(
						select M.MachineID,C.ComponentID,COP.OperationNo,mc,comp,opn,
						Max(T1.XStartTime)StartTime,Max(T1.XEndTime)EndTime,T1.PLD_StartTime,T1.PLD_EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from autodata
						Inner Join MachineInformation M ON autodata.MC=M.InterfaceID
						Inner Join ComponentInformation C ON autodata.Comp = C.InterfaceID
						Inner Join ComponentOperationPricing COP on autodata.Opn=COP.InterfaceID And C.ComponentID=COP.ComponentID And COP.MachineID = M.MachineID
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
							(Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime))
						 )AS T1 ON T1.MachineID=M.MachineID AND T1.ComponentID = C.ComponentID AND T1.OperationNo= COP.OperationNo and T1.Machineid=COP.MachineID
						Where (autodata.ndtime>T1.PLD_StartTime AND autodata.ndtime<=T1.PLD_EndTime) and (autodata.datatype=1)
						 Group by M.MachineID,C.ComponentID,COP.OperationNo,T1.PLD_StartTime,T1.PLD_EndTime,mc,comp,opn
					)AS T2
					Inner join MachineInformation M on T2.mc=M.interfaceid
					Inner join componentinformation C on T2.Comp=C.interfaceid
					Inner join ComponentOperationPricing O ON T2.Opn=O.interfaceid and C.Componentid=O.componentid and T2.MachineID = O.MachineID
					GROUP BY T2.MachineID,T2.ComponentID,T2.OperationNo,T2.StartTime,t2.EndTime
				)As T3
				WHERE  #Exceptions.StartTime=T3.StartTime AND #Exceptions.EndTime=T3.EndTime
				AND #Exceptions.MachineID=T3.MachineID AND #Exceptions.ComponentID = T3.ComponentID AND #Exceptions.OperationNo=T3.OperationNo
				
		
		END
		UPDATE #Exceptions SET ExCount=ExCount-((ExCount * ActualCount)/ISNULL(IdealCount,0))
End
update #FinalData set components = isnull(#FinalData.components,0) + isnull(T1.components,0) from(
	select M.machineid,F.StartTime,F.EndTime,sum(A.partscount/O.suboperations) as components
	from autodata A
	inner join machineinformation M on M.interfaceid=A.mc
	inner join componentinformation C on C.interfaceid=A.comp
	inner join componentoperationpricing O on O.interfaceid=A.opn and C.componentid=O.componentid and O.MachineID = M.MachineID
	inner join #FinalData F on M.Machineid= F.machineid
	where A.datatype=1 and A.ndtime>F.StartTime and A.ndtime<=F.EndTime
	group by M.machineid,F.StartTime,F.EndTime
) as T1 inner join #FinalData on #FinalData.machineid=T1.machineid and #FinalData.StartTime=T1.StartTime and #FinalData.EndTime=T1.EndTime
update #FinalData set components = isnull(#FinalData.components,0) - isnull(T1.comp,0) from(
	select MachineID,ShiftStartTime,ShiftEndTime,SUM(ExCount) as comp From #Exceptions
	GROUP BY MachineID,ShiftStartTime,ShiftEndTime
) as T1 inner join #FinalData on #FinalData.machineid=T1.machineid
and #FinalData.StartTime=T1.ShiftStartTime and #FinalData.EndTime=T1.ShiftEndTime
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	UPDATE #FinalData SET components = ISNULL(#FinalData.components,0) - ISNULL(T2.CompCount,0) from(
		select M.MachineID,F.StartTime,F.EndTime,SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as CompCount
		From (
			select mc,comp,opn,StartTime,EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from autodata
			CROSS JOIN #PlannedDownTimes T
			WHERE autodata.DataType=1 And T.MachineInterface = autodata.mc
			AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)
		    Group by mc,comp,opn,StartTime,EndTime
		) as T1
		Inner join Machineinformation M on M.interfaceID = T1.mc
		Inner join componentinformation C on T1.Comp=C.interfaceid
		Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineID = M.MachineID
		Inner join #FinalData F on F.MachineID=M.MachineID and F.StartTime<=T1.StartTime and F.EndTime>=T1.EndTime
		GROUP BY M.MachineID,F.StartTime,F.EndTime
	) as T2 inner join #FinalData on T2.MachineID = #FinalData.MachineID and T2.StartTime=#FinalData.StartTime and T2.EndTime=#FinalData.EndTime
END
update #UtilisedTimeDay set MachineTime=datediff(second,StartTime,EndTime)*(select count(*) from #UtilisedTimeDay)
update #UtilisedTimeDay set MachineTime=ceiling(MachineTime/3600)
update #FinalData set #FinalData.Utilisedtime = t1.Utilisedtime,#FinalData.TotMachinehour = t1.MachineTime from (
	select * from #UtilisedTimeDay
) as t1 inner join #FinalData  on t1.MachineID=#FinalData.MachineID and t1.Date1=#FinalData.Date1
if isnull(@Targetsource,'')='Exact Schedule'
BEGIN
	update #FinalData set IdealTarget = t1.IdealTarget from (
		Select loadschedule.date,loadschedule.Machine,sum(idealCount) as IdealTarget from loadschedule
		inner join #UtilisedTimeDay on loadschedule.date = #UtilisedTimeDay.Date1
		and loadschedule.Machine = #UtilisedTimeDay.MachineID
		Group by loadschedule.date,loadschedule.Machine
	) as t1 inner join #FinalData  on t1.Machine=#FinalData.MachineID and t1.Date=#FinalData.Date1
End
if isnull(@Targetsource,'')='Default Target per CO'
BEGIN
	update #FinalData set IdealTarget = t1.IdealTarget from (
		select distinct #UtilisedTimeDay.MachineID,idealCount as IdealTarget,t1.date from loadschedule inner join
		(select Machine,max(date) as date from loadschedule group by Machine) as t1
		on loadschedule.Machine=t1.Machine and loadschedule.date=t1.date
		inner join #UtilisedTimeDay on loadschedule.Machine = #UtilisedTimeDay.MachineID
	) as t1 inner join #FinalData  on t1.MachineID=#FinalData.MachineID
End
if isnull(@Targetsource,'')='% Ideal'
BEGIN
	update #FinalData set IdealTarget= isnull(#FinalData.IdealTarget,0)+ ISNULL(t2.tarcount,0) from (
		Select T1.mc,sum(T1.tcount) as tarcount,T1.StartTime as ShiftStart from(
			select distinct mc,comp,opn,tcount=((datediff(second,#FinalData.StartTime,#FinalData.EndTime)*CO.suboperations)/CO.cycletime)*isnull(CO.targetpercent,100)/100,
			#FinalData.StartTime from autodata
			inner join componentinformation C on autodata.comp=C.interfaceid
			inner join componentoperationpricing CO on autodata.opn=CO.interfaceid and C.componentId=CO.componentID
			inner join machineinformation M on M.machineid= CO.machineid
			inner join  #FinalData on autodata.mc=#FinalData.MachineInterface where autodata.datatype=1 and autodata.ndtime>#FinalData.StartTime and autodata.ndtime<=#FinalData.EndTime
		) as t1 group by T1.mc,T1.StartTime
	) as t2 inner join #FinalData  on t2.mc=#FinalData.MachineInterface
End
update #FinalData set utilisedTime=ceiling(utilisedTime/3600)
Select Date1,MachineID as Machine,ShiftID,StartTime as ShiftStart,EndTime as ShiftEnd,Components as CompCount,UtilisedTime,IdealTarget,TotMachineHour from #FinalData
order by ShiftID,Date1,Machine,ShiftStart asc
END
