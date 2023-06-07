/****** Object:  Procedure [dbo].[s_GetDownCategorywiseLosses]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[s_GetDownCategorywiseLosses] '2015-10-20','2015-10-20','ACE VTL-06',''
CREATE PROCEDURE [dbo].[s_GetDownCategorywiseLosses]
@StartTime datetime,
@Endtime datetime,
@Machineid nvarchar(50),
@Param nvarchar(50)=''

WITH RECOMPILE
AS
BEGIN

SET NOCOUNT ON;

Create table #Loss
(
	DownCategory nvarchar(50),
	Downid nvarchar(50),
	Downtime float
)

select @StartTime = dbo.f_GetLogicalDay(@StartTime,'Start')
Select @Endtime = dbo.f_GetLogicalDay(@Endtime,'End')

Insert into #Loss(downCategory,Downid,Downtime)
select D.Catagory,D.downid,sum(
CASE
WHEN  autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime  THEN  loadunload
WHEN (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  THEN DateDiff(second, @StartTime, ndtime)
WHEN (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)  THEN DateDiff(second, stTime, @Endtime)
WHEN autodata.msttime<@StartTime and autodata.ndtime>@EndTime   THEN DateDiff(second, @StartTime, @EndTime)
END
)AS down
from autodata 
inner join machineinformation M ON autodata.mc = M.InterfaceID 
left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
inner join downcodeinformation D on autodata.dcode=D.interfaceid
inner join DownCategoryInformation DCI on D.Catagory=DCI.DownCategory
where autodata.datatype=2 AND M.Machineid=@Machineid and
(
(autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)
OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
OR (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
OR (autodata.msttime<@StartTime and autodata.ndtime>@EndTime )
) and D.catagory Not in('Not Reported')
group by D.Catagory,D.downid

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN
UPDATE #Loss set Downtime =isnull(Downtime,0) - isNull(TT.DPDT ,0)
FROM(
	SELECT D.Catagory,D.downid, SUM
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
group by D.Catagory,D.downid
) as TT INNER JOIN #Loss ON TT.Catagory = #Loss.downCategory and TT.downid=#Loss.Downid
END


select T.DownCategory,
       T.Downid,Round([dbo].[f_FormatTime](T.Downtime,'mm'),2) as Downtime
from (
     select T.DownCategory,
            T.Downid,
            T.Downtime,
            row_number() over(partition by T.DownCategory order by T.downtime desc) as rn
     from #Loss as T where downtime>0
     ) as T
where T.rn <= 5
order by T.DownCategory,T.Downtime desc

END
