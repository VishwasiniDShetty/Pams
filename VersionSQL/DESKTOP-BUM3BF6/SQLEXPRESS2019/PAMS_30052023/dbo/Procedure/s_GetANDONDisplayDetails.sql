/****** Object:  Procedure [dbo].[s_GetANDONDisplayDetails]    Committed by VersionSQL https://www.versionsql.com ******/

/***********************************************************************************************************
---NR0090 - SwathiKS - 2013-Jul-19 :: created New procedure to show OEE,Actual,Target,Downtime and Plantwise Actual in Graph for Bosch.
-- Applied Prediction Logic to show Colorcode for Downtime.Refering to Rawdata Table.
---If LastRecord is Type 1 then Upto threshold time from endtime show 'White' Color Else 'Red'
---If LastRecord is Type 11 then Upto threshold time from starttime show 'White' Color Else 'Red'
---If LastRecord is Type 40 then Upto threshold time from starttime show 'White' Color Else 'Red'
---If LastRecord is Type 2 or 42 then show 'Red'
When PDT Applied,
For Type 1, Curtime-ndtime-PDT> TH. Show 'Blue' 
For Type 11, Curtime-sttime-PDT>TH. show 'Blue'
For Type 40, Curtime-sttime-PDT>TH. show 'Blue'
For Type 2 or 42, Curtime-ndtime-PDT>0 then Show 'Blue'
--Provided Option to set Thresholds For Type 1,11,40 in Shopdefaults.
ER0363 - SwathiKS - 12/Aug/2013 :: To Calculate Target at Date-Shift-Machine Level.
s_GetANDONDisplayDetails '2015-07-12 02:00:00 PM','2015-07-12 10:00:00 PM','','Line-2','B','Total'
************************************************************************************************************/
CREATE PROCEDURE [dbo].[s_GetANDONDisplayDetails]
	@StartTime datetime,
	@EndTime datetime,
	@MachineID nvarchar(50) = '',
	@PlantID nvarchar(50)='',
	@shift nvarchar(20),
	@Param nvarchar(20)= ''

with recompile
AS
BEGIN


SET NOCOUNT ON;

Declare @strPlantID as nvarchar(255)
Declare @strSql as nvarchar(4000)
Declare @strMachine as nvarchar(255)
Declare @StrTPMMachines as nvarchar(255)
				
SELECT @strMachine = ''
SELECT @strPlantID = ''
select @StrTPMMachines=''

CREATE TABLE #CockPitData 
(
	MachineID nvarchar(50),
	MachineDescription nvarchar(50),
	MachineInterface nvarchar(50) PRIMARY KEY,
	ProductionEfficiency float,
	AvailabilityEfficiency float,
	OverallEfficiency float,
	Components float,
	UtilisedTime float,
	ManagementLoss float,
	MLDown float,
	DownTime float,
	CN float,
	TargetCount int default 0,
	ColorCode varchar(50),
	OEGreen smallint,
	OERed smallint
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
	MachineID nvarchar(50),
	MachineInterface nvarchar(50),
	StartTime DateTime,
	EndTime DateTime
)

CREATE TABLE #MachineRunningStatus
	(
		MachineID NvarChar(50),
		MachineInterface nvarchar(50),
		Machinedescription nvarchar(50),
		sttime Datetime,
		ndtime Datetime,
		DataType smallint,
		ColorCode varchar(10),
		DownTime Int,
		lastDownstart datetime,
		PDT int
	)

Create table #Cockpittotal
(
	Lineid nvarchar(50),
	MachineDescription nvarchar(50),
	Components int	
)

--ER0363 ADDED FROM HERE
CREATE TABLE #ShiftDefn
(
	ShiftDate DateTime,		
	Shiftname nvarchar(20),
	ShftSTtime DateTime,
	ShftEndTime DateTime	
)

CREATE TABLE #TargetDefn
(
	ShiftDate DateTime,		
	Shiftname nvarchar(20),
	ShftSTtime DateTime,
	ShftEndTime DateTime,
	Machine nvarchar(50),
	Target int
)

create table #TotalTarget
(
	TotalTarget int
)

Create table #consoleTarget
(
Machine nvarchar(50),	
TargetDate datetime,
Target int
)

declare @startdate as datetime
declare @enddate as datetime
select @startdate = dbo.f_GetLogicalDay(@StartTime,'start')
select @enddate = dbo.f_GetLogicalDay(@endtime,'start')

while @startdate<=@enddate
Begin
	INSERT INTO #ShiftDefn(ShiftDate,Shiftname,ShftSTtime,ShftEndTime)
	Exec s_GetShiftTime @startdate,@shift
	Select @startdate = dateadd(d,1,@startdate)
END


create table #shift
(
	shiftname nvarchar(20),
	shiftid int IDENTITY (1, 1) NOT NULL
)

declare @i int
declare @shiftcount int

Insert into #shift (shiftname)
select shiftname from #ShiftDefn where ShftSTtime>=@StartTime and ShftEndTime<=@endtime
select @shiftcount = 0
select @shiftcount = count(*) from  #shift
print @shiftcount
set @i = 1
--ER0363 ADDED TILL HERE

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


Declare @CurrTime as DateTime
select @CurrTime =convert(nvarchar(20),getdate(),120)
print @CurrTime

SET @strSql = 'INSERT INTO #CockpitData (
	MachineID ,
	MachineDescription,
	MachineInterface,
	ProductionEfficiency ,
	AvailabilityEfficiency ,
	OverallEfficiency ,
	Components ,
	UtilisedTime ,	
	ManagementLoss,
	MLDown,
	DownTime ,
	CN,	
	TargetCount,
	OEGreen ,
	OERed
	) '
SET @strSql = @strSql + ' SELECT MachineInformation.MachineID, MachineInformation.Description,MachineInformation.interfaceid ,0,0,0,0,0,0,0,0,0,0,OEGreen ,OERed FROM MachineInformation
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


If @param = '' ---ER0363 
Begin   ---ER0363 

			/*******************************      Utilised Calculation Starts ***************************************************/
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
				When autodata.sttime >= @StartTime AND autodata.ndtime <= @EndTime Then datediff(s , autodata.sttime,autodata.ndtime)
				When autodata.sttime < @StartTime AND autodata.ndtime > @StartTime AND autodata.ndtime<=@EndTime Then datediff(s, @StartTime,autodata.ndtime )
				When autodata.sttime>=@StartTime And autodata.sttime < @EndTime AND autodata.ndtime > @EndTime Then datediff(s,autodata.sttime, @EndTime )
				When autodata.sttime<@StartTime AND autodata.ndtime>@EndTime   Then datediff(s , @StartTime,@EndTime)
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

			--mod 4:Get utilised time over lapping with PDT.
			If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
			BEGIN
				UPDATE #PLD set pPlannedDT =isnull(pPlannedDT,0) + isNull(TT.PPDT ,0)
				FROM(
					--Production Time in PDT
					SELECT autodata.MC,SUM
						(CASE
						--WHEN autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.cycletime+autodata.loadunload) --DR0325 Commented
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
				
			END

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
						) AND (downcodeinformation.availeffy = 0)
					group by autodata.mc
				) as TT INNER JOIN #PLD ON TT.mc = #PLD.MachineInterface

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
					group by autodata.mc
				) as TT INNER JOIN #PLD ON TT.mc = #PLD.MachineInterface
			END

			--************************************ Down and Management  Calculation Ends ******************************************

			---mod 4
			-- Get the value of CN
			-- Type 1
			UPDATE #CockpitData SET CN = isnull(CN,0) + isNull(t2.C1N1,0)
			from
			(select mc,
			SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))* autodata.partscount) C1N1
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
				AvailabilityEfficiency = (UtilisedTime)/(UtilisedTime + DownTime - ManagementLoss)
			WHERE UtilisedTime <> 0


			UPDATE #CockpitData
			SET
				OverAllEfficiency = (ProductionEfficiency * AvailabilityEfficiency)*100,
				ProductionEfficiency = ProductionEfficiency * 100 ,
				AvailabilityEfficiency = AvailabilityEfficiency * 100

END ---ER0363 


IF @param='' or @param='Total' ---ER0363 
BEGIN  ---ER0363 

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
END ---ER0363 

---ER0363 Commented From here
--select @strSql=''
-- select @strSql='update #CockpitData set Targetcount= ISNULL(targetcount,0) + ISNULL(t1.idealcount,0) from
--( select Max(date) as date,shift,machine,idealcount from loadschedule
--  where shift= ''' + @shift + ''' group by shift,machine,idealcount 
--) as T1 inner join #CockpitData on T1.machine = #CockpitData.machineid '
--print @strsql
--exec(@strSql)	
---ER0363 Commented Till here


-------------------------------------- ER0363 Added From Here -----------------------------------------
IF @param = 'MachinewiseTarget'
BEGIN
	----------------------------------- To Get Target at Machine Level------------------------------------
	INSERT INTO #TargetDefn(ShiftDate,Shiftname,ShftSTtime,ShftEndTime,Machine,target)
	select ShiftDate,Shiftname,ShftSTtime,ShftEndTime,#Cockpitdata.machineid,0 from #ShiftDefn
	cross join #Cockpitdata where ShftSTtime>=@StartTime and ShftEndTime<=@endtime

	Update #TargetDefn set Target = isnull(Target,0) + T1.IdealCount from
	(select Targetshift,TargetDate,machine,sum(target) as IdealCount from ANDONTarget where targetDate in (SELECT Shiftdate FROM #TargetDefn) and targetSHIFT in (SELECT ShiftName FROM #TargetDefn)
	 group by Targetshift,TargetDate,machine)T1 inner join #TargetDefn T on 
	T1.TargetDate=T.shiftdate and T.machine=T1.machine and T.Shiftname=T1.Targetshift


	while @i <= @shiftcount
	begin
		Update #TargetDefn set Target = isnull(Target,0) + T1.IdealCount from
		(select machine,sum(target) as idealcount,Targetshift from andontarget where targetdate in (select top 1 targetdate from
		andontarget where targetdate < dbo.f_GetLogicalDay(@StartTime,'start') and targetshift in (select top 1 shiftname from #shift where shiftid = @i) order by targetdate desc) 
		group by machine,Targetshift)T1 inner join #TargetDefn T on T.machine=T1.machine and T.Shiftname=T1.Targetshift and T.target=0
		select @i = @i + 1
	end

	update #cockpitdata set Targetcount=ISNULL(targetcount,0) + ISNULL(t1.idealcount,0) from
	( select Machine,Sum(Target)as IdealCount from #TargetDefn group by machine)T1
	inner join #CockpitData on T1.machine = #CockpitData.machineid

	Select MachineID,Machinedescription,TargetCount FROM #CockpitData order by machineid asc
	----------------------------------- To Get Target at Machine Level------------------------------------
END


If @param='TotalTarget'
BEGIN

	INSERT INTO #TargetDefn(ShiftDate,Shiftname,ShftSTtime,ShftEndTime,machine,target)
	select ShiftDate,Shiftname,ShftSTtime,ShftEndTime,'TOTAL',0 from #ShiftDefn
	 where ShftSTtime>=@StartTime and ShftEndTime<=@endtime

	Update #TargetDefn set Target = isnull(Target,0) + T1.IdealCount from
	(select targetshift as shift,targetDate,machine,sum(target) as IdealCount from ANDONTarget where targetDate in (SELECT Shiftdate FROM #TargetDefn) and targetSHIFT in (SELECT ShiftName FROM #TargetDefn)
	 and machine='TOTAL' group by targetshift,targetDate,machine)T1 inner join #TargetDefn T on 
	T1.targetdate=T.shiftdate and T.machine=T1.machine and T.Shiftname=T1.shift


	while @i <= @shiftcount
	begin
		Update #TargetDefn set Target = isnull(Target,0) + T1.IdealCount from
		(select machine,sum(target) as idealcount,Targetshift from andontarget where targetdate in (select top 1 targetdate from
		andontarget where targetdate < dbo.f_GetLogicalDay(@StartTime,'start') and targetshift in (select top 1 shiftname from #shift where shiftid = @i) and machine='TOTAL' order by targetdate desc) 
		group by machine,Targetshift)T1 inner join #TargetDefn T on T.machine=T1.machine and T.Shiftname=T1.Targetshift and T.target=0
		select @i = @i + 1
	end

	Insert into #TotalTarget
	select Isnull(Sum(Target),0) from #TargetDefn

	Select * FROM #TotalTarget 

END

IF @param = 'ConsoleTarget'
BEGIN


	If isnull(@PlantID,'') <> 'IB-PLANT 106'
	BEGIN

		Insert into #ConsoleTarget(Machine,TargetDate,Target)
		Select Machineid,'1900-01-01','0' from #CockpitData

		Update #ConsoleTarget set Targetdate = isnull(T.Targetdate,'1900-01-01') + T1.Targetdate,Target = isnull(target,0) + T1.IdealCount from
	    (select Targetshift,TargetDate,machine,sum(target) as IdealCount from ANDONTarget where targetDate = dbo.f_GetLogicalDay(@StartTime,'start')  and targetSHIFT = @shift
		 and plant=@plantid group by Targetshift,TargetDate,machine)T1 inner join #ConsoleTarget T on T.machine=T1.machine		

		Update #ConsoleTarget set Targetdate = isnull(T.Targetdate,'1900-01-01') + T1.Targetdate,Target = isnull(target,0) + T1.IdealCount from
		(select machine,sum(target) as idealcount,Targetshift,TargetDate from andontarget where targetdate in (select top 1 targetdate from
		 andontarget where targetdate < dbo.f_GetLogicalDay(@StartTime,'start') and targetshift = @shift and plant=@plantid order by targetdate desc) 
		 and targetshift = @shift and plant=@plantid group by machine,Targetshift,TargetDate)T1 inner join #ConsoleTarget T on T.machine=T1.machine and T.target=0
	END
	else if isnull(@PlantID,'') = 'IB-PLANT 106'
	BEGIN

		Insert into #ConsoleTarget(Machine,TargetDate,Target)
		Select 'TOTAL','1900-01-01','0' 

		Update #ConsoleTarget set Targetdate = isnull(T.Targetdate,'1900-01-01') + T1.Targetdate,Target = isnull(target,0) + T1.IdealCount from
	    (select Targetshift,TargetDate,machine,sum(target) as IdealCount from ANDONTarget where targetDate = dbo.f_GetLogicalDay(@StartTime,'start')  and targetSHIFT = @shift
		 and plant='IB-PLANT 106' group by Targetshift,TargetDate,machine)T1 inner join #ConsoleTarget T on T.machine=T1.machine
		
		Update #ConsoleTarget set Targetdate = isnull(T.Targetdate,'1900-01-01') + T1.Targetdate,Target = isnull(target,0) + T1.IdealCount from
		(select machine,sum(target) as idealcount,Targetshift,TargetDate from andontarget where targetdate in (select top 1 targetdate from
		 andontarget where targetdate < dbo.f_GetLogicalDay(@StartTime,'start') and targetshift = @shift and plant='IB-PLANT 106'  order by targetdate desc) 
		  and targetshift = @shift and plant='IB-PLANT 106'  group by machine,Targetshift,TargetDate)T1 inner join #ConsoleTarget T on T.machine=T1.machine and T.target=0
	END


	Select * from #ConsoleTarget
END
------------------------------------- ER0363 Added Till Here ---------------------------------------

If @param = ''
Begin
---ER0363 Added From Here
--	SELECT MachineID,Machinedescription,Round(OverAllEfficiency,1) as OEE,TargetCount,Components as Quantity,dbo.f_FormatTime(DownTime,'hh:mm') as Downtime,OEGreen ,OERed FROM #CockpitData 
--	order by machineid asc
	SELECT MachineID,Machinedescription,Round(OverAllEfficiency,1) as OEE,Components as Quantity,dbo.f_FormatTime(DownTime,'hh:mm') as Downtime,OEGreen ,OERed FROM #CockpitData 
	order by machineid asc
---ER0363 Added Till Here
END

IF @param='Total'
BEGIN

	Insert into #Cockpittotal
	SELECT P.Plantid,'ACE FT',sum(C.Components) as Quantity FROM #CockpitData C
	inner join Plantmachine P on P.machineid=C.Machineid
	where C.Machinedescription like ('%FT%')
	group by P.Plantid

	Insert into #Cockpittotal
	SELECT P.Plantid,'ACE ST',sum(C.Components) as Quantity FROM #CockpitData C
	inner join Plantmachine P on P.machineid=C.Machineid
	where C.Machinedescription like ('%ST%')
	group by P.Plantid

	Insert into #Cockpittotal
	SELECT P.Plantid,'AMS A',sum(C.Components) as Quantity FROM #CockpitData C
	inner join Plantmachine P on P.machineid=C.Machineid
	where C.Machinedescription like ('A%')
	group by P.Plantid

	Insert into #Cockpittotal
	SELECT P.Plantid,'AMS B',sum(C.Components) as Quantity FROM #CockpitData C
	inner join Plantmachine P on P.machineid=C.Machineid
	where C.Machinedescription like ('%B%')
	group by P.Plantid

	Insert into #Cockpittotal
	SELECT P.Plantid,'KM DIA 6',sum(C.Components) as Quantity FROM #CockpitData C
	inner join Plantmachine P on P.machineid=C.Machineid
	where C.Machinedescription like ('KM DIA 6')
	group by P.Plantid

	Insert into #Cockpittotal
	SELECT P.Plantid,'KM DIA 1.43',sum(C.Components) as Quantity FROM #CockpitData C
	inner join Plantmachine P on P.machineid=C.Machineid
	where C.Machinedescription like ('KM DIA 1.43')
	group by P.Plantid

	Insert into #Cockpittotal
	SELECT P.Plantid,'KM DIA 2.2',sum(C.Components) as Quantity FROM #CockpitData C
	inner join Plantmachine P on P.machineid=C.Machineid
	where C.Machinedescription like ('KM DIA 2.2')
	group by P.Plantid

	Insert into #Cockpittotal
	SELECT P.Plantid,'KM A/F MILLING',sum(C.Components) as Quantity FROM #CockpitData C
	inner join Plantmachine P on P.machineid=C.Machineid
	where C.Machinedescription like ('KM A/F MILLING')
	group by P.Plantid

	select * from #Cockpittotal order by Lineid,machinedescription
END

If @param='MachineDownstatus'
Begin

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
	select fd.MachineID,fd.MachineInterface,fd.MachineDescription,sttime,ndtime,datatype,'White',0,'1900-01-01',0 from rawdata
	inner join (select mc,max(slno) as slno from rawdata WITH (NOLOCK) where sttime<@currtime and isnull(ndtime,'1900-01-01')<@currtime
	and datatype in(2,42,40,41,1,11) group by mc ) t1 on t1.mc=rawdata.mc and t1.slno=rawdata.slno
	right outer join #CockpitData fd on fd.MachineInterface = rawdata.mc
	order by rawdata.mc

	update #machineRunningStatus set ColorCode = 'White' where datatype in (11) and (datediff(second,sttime,@CurrTime)- @Type11Threshold)>0
	update #machineRunningStatus set ColorCode = 'White' where datatype in (41)
	update #machineRunningStatus set ColorCode = 'Red' where datatype in (42,2)

	update #machineRunningStatus set ColorCode = t1.ColorCode from (
	Select mrs.MachineID,Case when (
	case when datatype = 40 then datediff(second,sttime,@CurrTime)- @Type40Threshold
	when datatype = 1 then datediff(second,ndtime,@CurrTime)- @Type1Threshold
	end) > 0 then 'Red' else 'White' end as ColorCode
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

	update #machineRunningStatus set ColorCode ='White' where isnull(sttime,'1900-01-01')='1900-01-01'

	select * from #machineRunningStatus order by machineid

End

END
