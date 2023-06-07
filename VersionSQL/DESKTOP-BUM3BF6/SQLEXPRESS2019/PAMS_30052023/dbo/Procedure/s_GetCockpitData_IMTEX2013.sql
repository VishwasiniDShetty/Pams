/****** Object:  Procedure [dbo].[s_GetCockpitData_IMTEX2013]    Committed by VersionSQL https://www.versionsql.com ******/

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
s_GetCockpitData_IMTEX2013 '2011-sep-03 00:00:00','2011-sep-03 08:00:00','LT 20-2',''
****************************************************************************************************/
CREATE              PROCEDURE [dbo].[s_GetCockpitData_IMTEX2013]
	@StartTime datetime output,
	@EndTime datetime output,
	@MachineID nvarchar(50) = '',
	@PlantID nvarchar(50)=''
AS
--s_GetCockpitData '01-DEC-2009 03:00:00','05-DEC-2009 03:00:00','',''
BEGIN
Declare @strPlantID as nvarchar(255)
Declare @strSql as nvarchar(4000)
Declare @strMachine as nvarchar(255)
declare @timeformat as nvarchar(2000)
Declare @StrTPMMachines AS nvarchar(500)		--karthik 21 feb 07
Declare @StrExMachine As Nvarchar(255)
SELECT @StrTPMMachines=''					--karthik 21 feb 07
SELECT @strMachine = ''
SELECT @strPlantID = ''
SELECT @timeformat ='ss'
--DR0175
select @StrExMachine=''
--DR0175
Select @timeformat = isnull((select valueintext from cockpitdefaults where parameter='timeformat'),'ss')
if (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')
begin
	select @timeformat = 'ss'
end
CREATE TABLE #CockPitData (
	MachineID nvarchar(50),
	MachineInterface nvarchar(50) PRIMARY KEY,
	ProductionEfficiency float,
	AvailabilityEfficiency float,
	OverallEfficiency float,
	Components float,
	TotalTime float,
	UtilisedTime float,
	ManagementLoss float,
	DownTime float,
	TurnOver float,
	ReturnPerHour float,
	ReturnPerHourtotal float,
	CN float,
	Remarks nvarchar(40),
	PEGreen smallint,
	PERed smallint,
	AEGreen smallint,
	AERed smallint,
	OEGreen smallint,
	OERed smallint,
	MaxDownReason nvarchar(50) DEFAULT ('')
	---mod 4 Added MLDown to store genuine downs which is contained in Management loss
	,MLDown float
	---mod 4
--CONSTRAINT CockpitData1_key PRIMARY KEY (machineinterface) : Commented By SSK On 06-Dec-2006
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
	ExCount Int
)
--mod 4
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
	MachineID nvarchar(50),
	MachineInterface nvarchar(50),
	StartTime DateTime,
	EndTime DateTime
)
--mod 4
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
	---mod 3
--	SET @strMachine = ' AND MachineInformation.MachineID = ''' + @machineid + ''''
--	SELECT @StrExMachine=' AND Ex.MachineID = ''' + @Machineid + ''' '
	SET @strMachine = ' AND MachineInformation.MachineID = N''' + @machineid + ''''
	SELECT @StrExMachine=' AND Ex.MachineID = N''' + @Machineid + ''' '
	---mod 3
end
if isnull(@PlantID,'')<> ''
Begin
	---mod 3
--	SET @strPlantID = ' AND PlantMachine.PlantID = ''' + @PlantID + ''''
	SET @strPlantID = ' AND PlantMachine.PlantID = N''' + @PlantID + ''''
	---mod 3
End
SET @strSql = 'INSERT INTO #CockpitData (
	MachineID ,
	MachineInterface,
	ProductionEfficiency ,
	AvailabilityEfficiency ,
	OverallEfficiency ,
	Components ,
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
	OERed
	) '
SET @strSql = @strSql + ' SELECT MachineInformation.MachineID, MachineInformation.interfaceid ,0,0,0,0,0,0,0,0,0,0,0,0,PEGreen ,PERed,AEGreen ,AERed ,OEGreen ,OERed FROM MachineInformation
			  LEFT OUTER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID WHERE MachineInformation.interfaceid > ''0'' '
SET @strSql =  @strSql + @strMachine + @strPlantID + @StrTPMMachines
EXEC(@strSql)
--mod 4 Get the Machines into #PLD
SET @strSql = ''
SET @strSql = 'INSERT INTO #PLD(MachineID,MachineInterface,pPlannedDT,dPlannedDT)
	SELECT MachineID ,Interfaceid,0  ,0 FROM MachineInformation WHERE  MachineInformation.interfaceid > ''0'' '
SET @strSql =  @strSql + @strMachine + @StrTPMMachines
EXEC(@strSql)
/* Planned Down times for the given time period */
SET @strSql = ''
SET @strSql = 'Insert into #PlannedDownTimes
	SELECT Machine,InterfaceID,
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
from autodata
where (autodata.msttime>=@StartTime)
and (autodata.ndtime<=@EndTime)
and (autodata.datatype=1)
group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface
-- Type 2
UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
from
(select  mc,SUM(DateDiff(second, @StartTime, ndtime)) cycle
from autodata
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
from autodata
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
sum(DateDiff(second, @StartTime, @EndTime)) cycle from autodata
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
From AutoData INNER Join
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
From AutoData INNER Join
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
From AutoData INNER Join
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
--select UtilisedTime from #CockpitData
--select * from #CockpitData
--mod 4:Get utilised time over lapping with PDT.
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
BEGIN
	UPDATE #PLD set pPlannedDT =isnull(pPlannedDT,0) + isNull(TT.PPDT ,0)
	FROM(
		--Production Time in PDT
		SELECT autodata.MC,SUM
			(CASE
			WHEN autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.cycletime+autodata.loadunload)
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
--select * from #PLD
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
		from autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
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
		--DateDiff(second, @StartTime, ndtime)
		from autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
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
		-- sum(DateDiff(second, stTime, @Endtime)) loss
		from autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
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
		--sum(DateDiff(second, @StartTime, @Endtime)) loss
		from autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
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
		from autodata inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
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
	from autodata inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
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
		FROM AutoData CROSS jOIN #PlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
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
		from autodata
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
		FROM AutoData CROSS jOIN #PlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
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
		FROM AutoData CROSS jOIN #PlannedDownTimes T
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
/* Changed by SSK to Combine SubOperations
*/
UPDATE #CockpitData SET CN = isnull(CN,0) + isNull(t2.C1N1,0)
from
(select mc,
SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))* autodata.partscount) C1N1
--SUM(componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1)) C1N1
FROM autodata INNER JOIN
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
		From autodata A
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
			SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp
	 		From (
				select MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,comp,opn,Tt1.StartTime,Tt1.EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from autodata
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
					SUM(CEILING (CAST(T2.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as compCount
					From
					(
						select MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,comp,opn,
						Max(T1.XStartTime)StartTime,Max(T1.XEndTime)EndTime,T1.PLD_StartTime,T1.PLD_EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from autodata
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
--TYPE1,TYPE2
UPDATE #CockpitData SET turnover = isnull(turnover,0) + isNull(t2.revenue,0)
from
(select mc,
SUM((componentoperationpricing.price/ISNULL(ComponentOperationPricing.SubOperations,1))* ISNULL(autodata.partscount,1)) revenue
FROM autodata
INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID
INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID AND componentoperationpricing.componentid = componentinformation.componentid
---mod 2
inner join machineinformation on componentoperationpricing.machineid=machineinformation.machineid
--mod 2 :- ER0181 By Kusuma M.H on 15-Sep-2009.
AND autodata.mc = machineinformation.interfaceid
--mod 2 :- ER0181 By Kusuma M.H on 15-Sep-2009.
---mod 2
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
		From autodata A
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
	Select mc,SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp
		   From (select mc,SUM(autodata.partscount)AS OrginalCount,comp,opn from autodata
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
--Select * from #Exceptions
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
		select mc,SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp From (
			select mc,Sum(ISNULL(PartsCount,1))AS OrginalCount,comp,opn from autodata
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
-- Calculate efficiencies
UPDATE #CockpitData
SET
	ProductionEfficiency = (CN/UtilisedTime) ,
	AvailabilityEfficiency = (UtilisedTime)/(UtilisedTime + DownTime - ManagementLoss),
	TotalTime = DateDiff(second, @StartTime, @EndTime),
	ReturnPerHour = (TurnOver/UtilisedTime)*3600,
	ReturnPerHourtotal = (TurnOver/DateDiff(second, @StartTime, @EndTime))*3600,
	Remarks = ' '
WHERE UtilisedTime <> 0
--UPDATE #CockpitData
--SET
--	ManagementLoss = ((TotalTime - ManagementLoss)- (DownTime- ManagementLoss))/(TotalTime-ManagementLoss)	
--WHERE UtilisedTime <> 0
UPDATE #CockpitData
SET
	OverAllEfficiency = (ProductionEfficiency * AvailabilityEfficiency)*100,
	ProductionEfficiency = ProductionEfficiency * 100 ,
	AvailabilityEfficiency = AvailabilityEfficiency * 100
UPDATE #CockpitData
SET Remarks = 'Machine Not In Production'
WHERE UtilisedTime = 0
-------------------------------------------------------------------------------------------------------------------
					/* Maximum Down Reason Time ,Calculation as goes down*/
---Irrespective of whether the down is management loss or genuine down we are considering the down reason which is the largest
----------------------------------------------------------------------------------------------------------------------
CREATE TABLE #DownTimeData
(
	MachineID nvarchar(50) NOT NULL,
	McInterfaceid nvarchar(4),
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
select @strsql = @strsql + '  autodata INNER JOIN'
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
		FROM AutoData CROSS jOIN #PlannedDownTimes T
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
		FROM AutoData CROSS jOIN #PlannedDownTimes T
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

/*
SELECT
MachineID,
ProductionEfficiency,
AvailabilityEfficiency,
OverAllEfficiency,
Components,
CN,
UtilisedTime,
TurnOver,
dbo.f_FormatTime(UtilisedTime,@timeformat) as StrUtilisedTime,
dbo.f_FormatTime(ManagementLoss,@timeformat) as ManagementLoss,
dbo.f_FormatTime(DownTime,@timeformat) as DownTime,
dbo.f_FormatTime(TotalTime,@timeformat) as TotalTime,
ReturnPerHour,
ReturnPerHourTOTAL,
Remarks,
PEGreen,
PERed,
AEGreen,
AERed,
OEGreen,
OERed,
@StartTime as StartTime,
@EndTime as EndTime,
MaxDownReason as MaxReasonTime
FROM #CockpitData
order by machineid asc
*/

SELECT
MachineID,
round(ProductionEfficiency,2) as PE,
round(OverAllEfficiency,2) as OEE,
case when right('00'+ convert(nvarchar,datepart(hour,dbo.f_formattime(DownTime, 'hh:mm:ss'))),2)= '00' 
then  right('00' + convert(nvarchar(2),datepart(minute,dbo.f_formattime(DownTime, 'hh:mm:ss'))),2) + ' min ' 
when right('00' + convert(nvarchar(2),datepart(minute,dbo.f_formattime(DownTime, 'hh:mm:ss'))),2)= '00'
then right('00'+ convert(nvarchar,datepart(hour,dbo.f_formattime(DownTime, 'hh:mm:ss'))),2) + ' hr '
else
right('00'+ convert(nvarchar,datepart(hour,dbo.f_formattime(DownTime, 'hh:mm:ss'))),2) + ' hr ' +  right('00' + convert(nvarchar(2),datepart(minute,dbo.f_formattime(DownTime, 'hh:mm:ss'))),2) + ' min '
end as downtime,OEGreen,
OERed
FROM #CockpitData


END
