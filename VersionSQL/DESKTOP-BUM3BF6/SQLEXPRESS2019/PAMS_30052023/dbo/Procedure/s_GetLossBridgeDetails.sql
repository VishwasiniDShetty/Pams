/****** Object:  Procedure [dbo].[s_GetLossBridgeDetails]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[s_GetLossBridgeDetails] '2015-01-01','2015-01-20','ACE VTL-01',''
CREATE PROCEDURE [dbo].[s_GetLossBridgeDetails]
@StartTime datetime,
@Endtime datetime,
@Machineid nvarchar(50),
@Param nvarchar(50)=''

WITH RECOMPILE
AS
BEGIN

SET NOCOUNT ON;

Create table #Lossbridge
(
Slno int identity(1,1) NOT NULL,
Reason nvarchar(50),
Downtime float
)

Declare @mc as nvarchar(50)
Select @mc=interfaceid from Machineinformation where machineid=@machineid
 
select @StartTime = dbo.f_GetLogicalDay(@StartTime,'Start')
Select @Endtime = dbo.f_GetLogicalDay(@Endtime,'End')

Insert into #Lossbridge(Reason,Downtime)
select 'Available Minutes',datediff(s,@StartTime,@Endtime)

/* Commented To Show Utilised instead of Std.Production Minutes for Unitta

Insert into #Lossbridge(Reason,Downtime)
select 'Standard Production Minutes','0'



UPDATE #Lossbridge SET Downtime = isnull(Downtime,0) + isNull(t2.C1N1,0)
from
(select
SUM((COP.cycletime/ISNULL(COP.SubOperations,1))* A.partscount) C1N1
FROM autodata A
INNER JOIN componentoperationpricing COP ON A.opn = COP.InterfaceID 
INNER JOIN componentinformation CI ON A.comp = CI.InterfaceID AND COP.componentid = CI.componentid
inner join machineinformation M on M.interfaceid=A.mc and COP.machineid=M.machineid
where ((A.sttime>=@StartTime and A.ndtime<=@EndTime) or
(A.sttime<@StartTime and A.ndtime>@StartTime and A.ndtime<=@EndTime))
and (A.datatype=1) AND M.Machineid=@Machineid
) as t2 where #Lossbridge.Reason='Standard Production Minutes'

-- mod 4 Ignore count from CN calculation which is over lapping with PDT
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN

	UPDATE #Lossbridge SET Downtime = isnull(Downtime,0) - isNull(t2.C1N1,0)
	From
	(
		select SUM((O.cycletime * ISNULL(A.PartsCount,1))/ISNULL(O.SubOperations,1))  C1N1
		From autodata A
		Inner join machineinformation M on M.interfaceid=A.mc
		Inner join componentinformation C ON A.Comp=C.interfaceid
		Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID
		Cross jOIN PlannedDownTimes T
		WHERE M.Machineid=@Machineid and A.DataType=1 AND T.Machine=M.Machineid
		AND (A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)
		AND (A.ndtime > @StartTime  AND A.ndtime <=@EndTime)
	) as T2 where #Lossbridge.Reason='Standard Production Minutes'


END

*/

Insert into #Lossbridge(Reason,Downtime)
select 'Utilised Time','0'

-- Type 1
UPDATE #Lossbridge SET Downtime = isnull(Downtime,0) + isNull(t2.cycle,0)
from
(select      mc,sum(cycletime+loadunload) as cycle
from autodata
where (autodata.msttime>=@StartTime)
and (autodata.ndtime<=@EndTime)
and (autodata.datatype=1) and mc=@mc
group by autodata.mc
) as T2 where #Lossbridge.Reason='Utilised Time'

-- Type 2
UPDATE #Lossbridge SET Downtime = isnull(Downtime,0) + isNull(t2.cycle,0)
from
(select  mc,SUM(DateDiff(second, @StartTime, ndtime)) cycle
from autodata
where (autodata.msttime<@StartTime)
and (autodata.ndtime>@StartTime)
and (autodata.ndtime<=@EndTime)
and (autodata.datatype=1)and mc=@mc
group by autodata.mc
) as T2 where #Lossbridge.Reason='Utilised Time'

-- Type 3
UPDATE #Lossbridge SET Downtime = isnull(Downtime,0) + isNull(t2.cycle,0)
from
(select  mc,sum(DateDiff(second, mstTime, @Endtime)) cycle
from autodata
where (autodata.msttime>=@StartTime)
and (autodata.msttime<@EndTime)
and (autodata.ndtime>@EndTime)
and (autodata.datatype=1) and mc=@mc
group by autodata.mc
) as T2 where #Lossbridge.Reason='Utilised Time'

-- Type 4
UPDATE #Lossbridge SET Downtime = isnull(Downtime,0) + isNull(t2.cycle,0)
from
(select mc,
sum(DateDiff(second, @StartTime, @EndTime)) cycle from autodata
where (autodata.msttime<@StartTime)
and (autodata.ndtime>@EndTime)
and (autodata.datatype=1) and mc=@mc
group by autodata.mc
) as T2 where #Lossbridge.Reason='Utilised Time'


/* Fetching Down Records from Production Cycle  */
/* If Down Records of TYPE-2*/
UPDATE #Lossbridge SET Downtime = isnull(Downtime,0) - isNull(t2.Down,0)
FROM
(Select AutoData.mc ,
SUM(
CASE
	When autodata.sttime <= @StartTime Then datediff(s, @StartTime,autodata.ndtime )
	When autodata.sttime > @StartTime Then datediff(s , autodata.sttime,autodata.ndtime)
END) as Down
From AutoData INNER Join
	(Select mc,Sttime,NdTime From AutoData
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime and mc=@mc And
		(msttime < @StartTime)And (ndtime > @StartTime) AND (ndtime <= @EndTime)) as T1
ON AutoData.mc=T1.mc
Where AutoData.DataType=2 and AutoData.mc=@mc
And ( autodata.Sttime > T1.Sttime )
And ( autodata.ndtime <  T1.ndtime )
AND ( autodata.ndtime >  @StartTime )
GROUP BY AUTODATA.mc)AS T2 where #Lossbridge.Reason='Utilised Time'

/* If Down Records of TYPE-3*/
UPDATE #Lossbridge SET Downtime = isnull(Downtime,0) - isNull(t2.Down,0)
FROM
(Select AutoData.mc ,
SUM(CASE
	When autodata.ndtime > @EndTime Then datediff(s,autodata.sttime, @EndTime )
	When autodata.ndtime <=@EndTime Then datediff(s , autodata.sttime,autodata.ndtime)
END) as Down
From AutoData INNER Join
	(Select mc,Sttime,NdTime From AutoData
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime and mc=@mc And
		(sttime >= @StartTime)And (ndtime > @EndTime) and (sttime<@EndTime) ) as T1
ON AutoData.mc=T1.mc
Where AutoData.DataType=2 and AutoData.mc=@mc
And (T1.Sttime < autodata.sttime  )
And ( T1.ndtime >  autodata.ndtime)
AND (autodata.sttime  <  @EndTime)
GROUP BY AUTODATA.mc)AS T2 where #Lossbridge.Reason='Utilised Time'

/* If Down Records of TYPE-4*/
UPDATE #Lossbridge SET Downtime = isnull(Downtime,0) - isNull(t2.Down,0)
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
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime and mc=@mc And
		(msttime < @StartTime)And (ndtime > @EndTime) ) as T1
ON AutoData.mc=T1.mc
Where AutoData.DataType=2 and AutoData.mc=@mc
And (T1.Sttime < autodata.sttime  )
And ( T1.ndtime >  autodata.ndtime)
AND (autodata.ndtime  >  @StartTime)
AND (autodata.sttime  <  @EndTime)
GROUP BY AUTODATA.mc
)AS T2 where #Lossbridge.Reason='Utilised Time'



--mod 4:Get utilised time over lapping with PDT.
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
BEGIN


	------------------------------------ ER0374 Added Till Here ---------------------------------
	UPDATE #Lossbridge SET Downtime = isnull(Downtime,0) - isNull(TT.PPDT,0)
	FROM(
		--Production Time in PDT
		SELECT autodata.MC,SUM
			(CASE
			WHEN autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN DateDiff(second,autodata.msttime,autodata.ndtime) --DR0325 Added
			WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )
			WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END)  as PPDT
			FROM (select M.machineid,mc,msttime,ndtime from autodata
				inner join machineinformation M on M.interfaceid=Autodata.mc
				 where autodata.DataType=1 and mc=@mc And 
				((autodata.msttime >= @starttime  AND autodata.ndtime <=@Endtime)
				OR ( autodata.msttime < @starttime  AND autodata.ndtime <= @Endtime AND autodata.ndtime > @starttime )
				OR ( autodata.msttime >= @starttime   AND autodata.msttime <@Endtime AND autodata.ndtime > @Endtime )
				OR ( autodata.msttime < @starttime  AND autodata.ndtime > @Endtime))
				)
		AutoData inner jOIN dbo.PlannedDownTimes T on T.Machine=AutoData.machineid
		WHERE 
			(
			(autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )
		group by autodata.mc
	)
	 as TT where #Lossbridge.Reason='Utilised Time'

		--mod 4(4):Handle intearction between ICD and PDT for type 1 production record for the selected time period.
	UPDATE #Lossbridge SET Downtime = isnull(Downtime,0) + isNull(t2.IPDT,0) from (
		Select T1.mc,SUM(
			CASE 	
				When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1
				When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2
				When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3
				when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4
			END) as IPDT from
		(Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype from autodata A
		Where A.DataType=2 and A.mc=@mc
		and exists 
			(
			Select B.Sttime,B.NdTime,B.mc From AutoData B
			Where B.mc = A.mc and B.mc=@mc and 
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
		)AS T2  where #Lossbridge.Reason='Utilised Time'
		---mod 4(4)
	
	/* Fetching Down Records from Production Cycle  */
	/* If production  Records of TYPE-2*/
	UPDATE #Lossbridge SET Downtime = isnull(Downtime,0) + isNull(t2.IPDT,0) from (
		Select T1.mc,SUM(
		CASE 	
			When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1
			When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2
			When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3
			when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT from
		(Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype from autodata A
		Where A.DataType=2 and A.mc=@mc
		and exists 
		(
		Select B.Sttime,B.NdTime From AutoData B
		Where B.mc = A.mc and B.mc=@mc and
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
	)AS T2  where #Lossbridge.Reason='Utilised Time'

	/* If production Records of TYPE-3*/
	UPDATE #Lossbridge SET Downtime = isnull(Downtime,0) + isNull(t2.IPDT,0) from (
	Select T1.mc,SUM(
		CASE 	
			When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1
			When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2
			When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3
			when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT from
		(Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype from autodata A
		Where A.DataType=2 and A.mc=@mc
		and exists 
		(
		Select B.Sttime,B.NdTime From AutoData B
		Where B.mc = A.mc and B.mc=@mc and
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
		)AS T2  where #Lossbridge.Reason='Utilised Time'
	
	
	/* If production Records of TYPE-4*/
	UPDATE #Lossbridge SET Downtime = isnull(Downtime,0) + isNull(t2.IPDT,0) from (
	Select T1.mc,SUM(
	CASE 	
		When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1
		When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2
		When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3
		when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT from
	(Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype from autodata A
	Where A.DataType=2 and A.mc=@mc
	and exists 
	(
	Select B.Sttime,B.NdTime From AutoData B
	Where B.mc = A.mc and B.mc=@mc and
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
	)AS T2  where #Lossbridge.Reason='Utilised Time'

END


Insert into #Lossbridge(Reason,Downtime)
select distinct catagory,'0' from downcodeinformation where catagory Not in('Not Reported') order by catagory

Insert into #Lossbridge(Reason,Downtime)
select 'Not Reported','0'

Update #Lossbridge set Downtime = T1.down from
(select L.Reason,sum(
CASE
WHEN  autodata.msttime>=@StartTime  and  autodata.ndtime<=@Endtime  THEN  loadunload
WHEN (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@Endtime)  THEN DateDiff(second, @StartTime, ndtime)
WHEN (autodata.msttime>=@StartTime  and autodata.sttime<@Endtime  and autodata.ndtime>@Endtime)  THEN DateDiff(second, stTime, @Endtime)
WHEN autodata.msttime<@StartTime and autodata.ndtime>@Endtime   THEN DateDiff(second, @StartTime, @Endtime)
END
)AS down
from autodata 
inner join machineinformation M ON autodata.mc = M.InterfaceID 
left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
inner join downcodeinformation D on autodata.dcode=D.interfaceid
inner join DownCategoryInformation DCI on D.Catagory=DCI.DownCategory
inner join #Lossbridge L on L.Reason = DCI.DownCategory
where autodata.datatype=2 AND M.Machineid=@Machineid and
(
(autodata.msttime>=@StartTime  and  autodata.ndtime<=@Endtime)
OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@Endtime)
OR (autodata.msttime>=@StartTime  and autodata.sttime<@Endtime  and autodata.ndtime>@Endtime)
OR (autodata.msttime<@StartTime and autodata.ndtime>@Endtime)
) and D.catagory Not in('Not Reported')
group by L.Reason)T1 inner join #Lossbridge on #Lossbridge.Reason=T1.Reason

Update #Lossbridge set Downtime = T1.down from
(select L.Reason,sum(
CASE
WHEN  autodata.msttime>=@StartTime  and  autodata.ndtime<=@Endtime  THEN  loadunload
WHEN (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@Endtime)  THEN DateDiff(second, @StartTime, ndtime)
WHEN (autodata.msttime>=@StartTime  and autodata.sttime<@Endtime  and autodata.ndtime>@Endtime)  THEN DateDiff(second, stTime, @Endtime)
WHEN autodata.msttime<@StartTime and autodata.ndtime>@Endtime   THEN DateDiff(second, @StartTime, @Endtime)
END
)AS down
from autodata 
inner join machineinformation M ON autodata.mc = M.InterfaceID 
left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
inner join downcodeinformation D on autodata.dcode=D.interfaceid
inner join DownCategoryInformation DCI on D.Catagory=DCI.DownCategory
inner join #Lossbridge L on L.Reason = DCI.DownCategory
where autodata.datatype=2 AND M.Machineid=@Machineid and
(
(autodata.msttime>=@StartTime  and  autodata.ndtime<=@Endtime)
OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@Endtime)
OR (autodata.msttime>=@StartTime  and autodata.sttime<@Endtime  and autodata.ndtime>@Endtime)
OR (autodata.msttime<@StartTime and autodata.ndtime>@Endtime)
) and D.catagory in('Not Reported')
group by L.Reason)T1 inner join #Lossbridge on #Lossbridge.Reason=T1.Reason


If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN

	UPDATE #Lossbridge set Downtime =isnull(Downtime,0) - isNull(TT.DPDT ,0)
	FROM(
		SELECT L.Reason, SUM
		   (CASE
			WHEN (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN (autodata.loadunload)
			WHEN (autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN (autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN (autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as DPDT
		FROM AutoData CROSS JOIN PlannedDownTimes T 
		inner join machineinformation M ON autodata.mc = M.InterfaceID 
		left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
		inner join downcodeinformation D on autodata.dcode=D.interfaceid
		inner join DownCategoryInformation DCI on D.Catagory=DCI.DownCategory
		inner join #Lossbridge L on L.Reason = DCI.DownCategory
		WHERE autodata.DataType=2 AND M.Machineid=@Machineid AND T.Machine=M.Machineid and
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR (autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR (autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR (autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			) AND
			(
			(T.StartTime>=@StartTime  and  T.EndTime<=@EndTime)
			OR (T.StartTime<@StartTime and  T.EndTime>@StartTime and T.EndTime<=@EndTime)
			OR (T.StartTime>=@StartTime  and T.StartTime<@EndTime  and T.EndTime>@EndTime)
			OR (T.StartTime<@StartTime and T.EndTime>@EndTime )
			) and D.catagory Not in('Not Reported')
	group by L.Reason
	) as TT inner join #Lossbridge on #Lossbridge.Reason=TT.Reason

	UPDATE #Lossbridge set Downtime =isnull(Downtime,0) - isNull(TT.DPDT ,0)
	FROM(
		SELECT L.Reason, SUM
		   (CASE
			WHEN (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN (autodata.loadunload)
			WHEN (autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN (autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN (autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as DPDT
		FROM AutoData CROSS JOIN PlannedDownTimes T 
		inner join machineinformation M ON autodata.mc = M.InterfaceID 
		left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
		inner join downcodeinformation D on autodata.dcode=D.interfaceid
		inner join DownCategoryInformation DCI on D.Catagory=DCI.DownCategory
		inner join #Lossbridge L on L.Reason = DCI.DownCategory
		WHERE autodata.DataType=2 AND M.Machineid=@Machineid AND T.Machine=M.Machineid and
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR (autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR (autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR (autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			) AND
			(
			(T.StartTime>=@StartTime  and  T.EndTime<=@EndTime)
			OR (T.StartTime<@StartTime and  T.EndTime>@StartTime and T.EndTime<=@EndTime)
			OR (T.StartTime>=@StartTime  and T.StartTime<@EndTime  and T.EndTime>@EndTime)
			OR (T.StartTime<@StartTime and T.EndTime>@EndTime )
			) and D.catagory in('Not Reported')
	group by L.Reason
	) as TT inner join #Lossbridge on #Lossbridge.Reason=TT.Reason

END


--Update #Lossbridge set Downtime = isnull(#Lossbridge.Downtime,0) + Isnull(T1.Down,0)
--from(Select Downtime as down from #Lossbridge where Reason='Available Minutes') T1 where #Lossbridge.Reason='Not Reported'

--Update #Lossbridge set Downtime = isnull(#Lossbridge.Downtime,0) - Isnull(T1.Down,0)
--from(Select Sum(Downtime) as down from #Lossbridge where Reason Not in ('Available Minutes','Not Reported')) T1 where #Lossbridge.Reason='Not Reported'

select Reason,Round(dbo.f_FormatTime(Downtime,'mm'),2) as Downtime from #Lossbridge where downtime>0 order by slno

END
