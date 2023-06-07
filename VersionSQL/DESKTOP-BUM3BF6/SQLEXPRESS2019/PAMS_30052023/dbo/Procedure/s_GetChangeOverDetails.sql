/****** Object:  Procedure [dbo].[s_GetChangeOverDetails]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[s_GetChangeOverDetails] '2015-09-01 17:54:00.120','2015-10-30 17:54:00.120','ACE VTL-06','month','summary'
CREATE PROCEDURE [dbo].[s_GetChangeOverDetails]
@StartTime datetime,
@Endtime datetime,
@Machineid nvarchar(50),
@Interval nvarchar(50),
@Param nvarchar(50)=''

WITH RECOMPILE
AS
BEGIN

SET NOCOUNT ON;

Create table #ChangeOverDetails
(
	Startdate datetime,
	Enddate datetime,
	Weekno nvarchar(50),
	NoOfChangeOvers int default 0,
	ChangeOverMinutes float
)

Declare @Startdate as datetime
Declare @Enddate as datetime


If @Interval='Day' and @param=''
BEGIN

		Select @Startdate = dbo.f_GetLogicalDay(@StartTime,'start')
		Select @Enddate = dbo.f_GetLogicalDay(@Endtime,'start')

		While @Startdate<=@Enddate
		BEGIN
			Insert into  #ChangeOverDetails(Startdate,Enddate,NoOfChangeOvers,ChangeOverMinutes)
			Select Convert(nvarchar(20),dbo.f_GetLogicalDay(@Startdate,'start'),120),Convert(nvarchar(20),dbo.f_GetLogicalDay(@Startdate,'End'),120),0,0
			Select @Startdate = Dateadd(Day,1,@Startdate)
		END

		Update #ChangeOverDetails set NoOfChangeOvers = T1.RecCount,ChangeOverMinutes=T1.down from
		(select C.Startdate,C.Enddate,D.Catagory,Count(D.downid) as RecCount,sum(
		CASE
		WHEN  autodata.msttime>=C.Startdate  and  autodata.ndtime<=C.Enddate  THEN  loadunload
		WHEN (autodata.sttime<C.Startdate and  autodata.ndtime>C.Startdate and autodata.ndtime<=C.Enddate)  THEN DateDiff(second, C.Startdate, ndtime)
		WHEN (autodata.msttime>=C.Startdate  and autodata.sttime<C.Enddate  and autodata.ndtime>C.Enddate)  THEN DateDiff(second, stTime, C.Enddate)
		WHEN autodata.msttime<C.Startdate and autodata.ndtime>C.Enddate   THEN DateDiff(second, C.Startdate, C.Enddate)
		END
		)AS down
		from autodata 
		inner join machineinformation M ON autodata.mc = M.InterfaceID 
		left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
		inner join downcodeinformation D on autodata.dcode=D.interfaceid
		inner join DownCategoryInformation DCI on D.Catagory=DCI.DownCategory
		Cross join #ChangeOverDetails C
		--where autodata.datatype=2 AND M.Machineid=@Machineid and D.interfaceid in('201','211','212') and
		where autodata.datatype=2 AND M.Machineid=@Machineid and D.interfaceid in('201','202','203') and
		(
		(autodata.msttime>=C.Startdate  and  autodata.ndtime<=C.Enddate)
		OR (autodata.sttime<C.Startdate and  autodata.ndtime>C.Startdate and autodata.ndtime<=C.Enddate)
		OR (autodata.msttime>=C.Startdate  and autodata.sttime<C.Enddate  and autodata.ndtime>C.Enddate)
		OR (autodata.msttime<C.Startdate and autodata.ndtime>C.Enddate)
		) 
		group by C.Startdate,C.Enddate,D.Catagory)T1 inner join #ChangeOverDetails on #ChangeOverDetails.Startdate=T1.Startdate
		and #ChangeOverDetails.Enddate=T1.Enddate


		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
		BEGIN

			Update #ChangeOverDetails set ChangeOverMinutes=Isnull(ChangeOverMinutes,0) - Isnull(T1.down,0) from
			(select C.Startdate,C.Enddate,D.Catagory,sum(
			CASE
			WHEN  autodata.msttime>=T.StartTime  and  autodata.ndtime<=T.EndTime  THEN  loadunload
			WHEN (autodata.sttime<T.StartTime and  autodata.ndtime>T.StartTime and autodata.ndtime<=T.EndTime)  THEN DateDiff(second, T.StartTime, ndtime)
			WHEN (autodata.msttime>=T.StartTime  and autodata.sttime<T.EndTime  and autodata.ndtime>T.EndTime)  THEN DateDiff(second, stTime, T.EndTime)
			WHEN autodata.msttime<T.StartTime and autodata.ndtime>T.EndTime  THEN DateDiff(second, T.StartTime, T.EndTime)
			END
			)AS down
			from autodata CROSS JOIN PlannedDownTimes T 
			inner join machineinformation M ON autodata.mc = M.InterfaceID 
			left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
			inner join downcodeinformation D on autodata.dcode=D.interfaceid
			inner join DownCategoryInformation DCI on D.Catagory=DCI.DownCategory
			cross join #ChangeOverDetails C 
			--where autodata.datatype=2 AND M.Machineid=@Machineid and T.Machine=M.Machineid and D.interfaceid in('201','211','212') and
			where autodata.datatype=2 AND M.Machineid=@Machineid and T.Machine=M.Machineid and D.interfaceid in('201','202','203') and
			(
			(autodata.msttime>=T.StartTime  and  autodata.ndtime<=T.EndTime)
			OR (autodata.sttime<T.StartTime and  autodata.ndtime>T.StartTime and autodata.ndtime<=T.EndTime)
			OR (autodata.msttime>=T.StartTime  and autodata.sttime<T.EndTime  and autodata.ndtime>T.EndTime)
			OR (autodata.msttime<T.StartTime and autodata.ndtime>T.EndTime)
			) and
			(
			(T.Starttime >= C.Startdate  AND T.Endtime <=C.Enddate)
			OR ( T.Starttime < C.Startdate  AND T.Endtime <= C.Enddate AND T.Endtime > C.Startdate )
			OR ( T.Starttime >=C.Startdate   AND T.Starttime <C.Enddate AND T.Endtime > C.Enddate )
			OR ( T.Starttime < C.Startdate  AND T.Endtime >C.Enddate) )
			group by C.Startdate,C.Enddate,D.Catagory)T1 inner join #ChangeOverDetails on #ChangeOverDetails.Startdate=T1.Startdate
			and #ChangeOverDetails.Enddate=T1.Enddate

		END

		Select Startdate,Enddate,Convert(nvarchar(2),datepart(day,Startdate)) + '-' + Convert(nvarchar(3),datename(month,Startdate)) as DisplayDate,NoOfChangeOvers,[dbo].[f_FormatTime](ChangeOverMinutes,'mm') as  ChangeOverMinutes from #ChangeOverDetails
END


If @Interval='Month'  and @param=''
BEGIN


		Select @Startdate = dbo.f_GetLogicalMonth(@StartTime,'Start')
		Select @Enddate=dbo.f_GetLogicalMonth(@Endtime,'start')

		While @Startdate<=@Enddate
		BEGIN
			Insert into  #ChangeOverDetails(Startdate,Enddate,NoOfChangeOvers,ChangeOverMinutes)
			Select Convert(nvarchar(20),dbo.f_GetLogicalMonth(@Startdate,'Start'),120),Convert(nvarchar(20),dbo.f_GetLogicalMonth(@Startdate,'End'),120),0,0
			Select @Startdate = Dateadd(month,1,@Startdate)
		END

		Update #ChangeOverDetails set NoOfChangeOvers = T1.RecCount,ChangeOverMinutes=T1.down from
		(select C.Startdate,C.Enddate,D.Catagory,Count(D.downid) as RecCount,sum(
		CASE
		WHEN  autodata.msttime>=C.Startdate  and  autodata.ndtime<=C.Enddate  THEN  loadunload
		WHEN (autodata.sttime<C.Startdate and  autodata.ndtime>C.Startdate and autodata.ndtime<=C.Enddate)  THEN DateDiff(second, C.Startdate, ndtime)
		WHEN (autodata.msttime>=C.Startdate  and autodata.sttime<C.Enddate  and autodata.ndtime>C.Enddate)  THEN DateDiff(second, stTime, C.Enddate)
		WHEN autodata.msttime<C.Startdate and autodata.ndtime>C.Enddate   THEN DateDiff(second, C.Startdate, C.Enddate)
		END
		)AS down
		from autodata 
		inner join machineinformation M ON autodata.mc = M.InterfaceID 
		left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
		inner join downcodeinformation D on autodata.dcode=D.interfaceid
		inner join DownCategoryInformation DCI on D.Catagory=DCI.DownCategory
		Cross join #ChangeOverDetails C
		--where autodata.datatype=2 AND M.Machineid=@Machineid and D.interfaceid in('201','211','212')  and
		where autodata.datatype=2 AND M.Machineid=@Machineid and D.interfaceid in('201','202','203')  and
		(
		(autodata.msttime>=C.Startdate  and  autodata.ndtime<=C.Enddate)
		OR (autodata.sttime<C.Startdate and  autodata.ndtime>C.Startdate and autodata.ndtime<=C.Enddate)
		OR (autodata.msttime>=C.Startdate  and autodata.sttime<C.Enddate  and autodata.ndtime>C.Enddate)
		OR (autodata.msttime<C.Startdate and autodata.ndtime>C.Enddate)
		) 
		group by C.Startdate,C.Enddate,D.Catagory)T1 inner join #ChangeOverDetails on #ChangeOverDetails.Startdate=T1.Startdate
		and #ChangeOverDetails.Enddate=T1.Enddate

		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
		BEGIN

			Update #ChangeOverDetails set ChangeOverMinutes=Isnull(ChangeOverMinutes,0) - Isnull(T1.down,0) from
			(select C.Startdate,C.Enddate,D.Catagory,sum(
			CASE
			WHEN  autodata.msttime>=T.StartTime  and  autodata.ndtime<=T.EndTime  THEN  loadunload
			WHEN (autodata.sttime<T.StartTime and  autodata.ndtime>T.StartTime and autodata.ndtime<=T.EndTime)  THEN DateDiff(second, T.StartTime, ndtime)
			WHEN (autodata.msttime>=T.StartTime  and autodata.sttime<T.EndTime  and autodata.ndtime>T.EndTime)  THEN DateDiff(second, stTime, T.EndTime)
			WHEN autodata.msttime<T.StartTime and autodata.ndtime>T.EndTime  THEN DateDiff(second, T.StartTime, T.EndTime)
			END
			)AS down
			from autodata CROSS JOIN PlannedDownTimes T 
			inner join machineinformation M ON autodata.mc = M.InterfaceID 
			left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
			inner join downcodeinformation D on autodata.dcode=D.interfaceid
			inner join DownCategoryInformation DCI on D.Catagory=DCI.DownCategory
			cross join #ChangeOverDetails C 
			--where autodata.datatype=2 AND M.Machineid=@Machineid and T.Machine=M.Machineid and D.interfaceid in('201','211','212') and
			where autodata.datatype=2 AND M.Machineid=@Machineid and T.Machine=M.Machineid and D.interfaceid in('201','202','203') and
			(
			(autodata.msttime>=T.StartTime  and  autodata.ndtime<=T.EndTime)
			OR (autodata.sttime<T.StartTime and  autodata.ndtime>T.StartTime and autodata.ndtime<=T.EndTime)
			OR (autodata.msttime>=T.StartTime  and autodata.sttime<T.EndTime  and autodata.ndtime>T.EndTime)
			OR (autodata.msttime<T.StartTime and autodata.ndtime>T.EndTime)
			) and
			(
			(T.Starttime >= C.Startdate  AND T.Endtime <=C.Enddate)
			OR ( T.Starttime < C.Startdate  AND T.Endtime <= C.Enddate AND T.Endtime > C.Startdate )
			OR ( T.Starttime >=C.Startdate   AND T.Starttime <C.Enddate AND T.Endtime > C.Enddate )
			OR ( T.Starttime < C.Startdate  AND T.Endtime >C.Enddate) )
			group by C.Startdate,C.Enddate,D.Catagory)T1 inner join #ChangeOverDetails on #ChangeOverDetails.Startdate=T1.Startdate
			and #ChangeOverDetails.Enddate=T1.Enddate

		END

		Select Startdate,Enddate,Convert(nvarchar(3),datename(month,Startdate)) as DisplayDate,NoOfChangeOvers,[dbo].[f_FormatTime](ChangeOverMinutes,'mm') as  ChangeOverMinutes from #ChangeOverDetails

END


If @Interval='Week'  and @param=''
BEGIN

		Insert into  #ChangeOverDetails(Startdate,Enddate,Weekno,NoOfChangeOvers,ChangeOverMinutes)
		select min(weekdate),Max(weekdate),weeknumber,0,0 from calender where weekdate>=@StartTime and weekdate<=@Endtime
		group by weeknumber 


		Update #ChangeOverDetails set NoOfChangeOvers = T1.RecCount,ChangeOverMinutes=T1.down from
		(select C.Startdate,C.Enddate,D.Catagory,Count(D.downid) as RecCount,sum(
		CASE
		WHEN  autodata.msttime>=C.Startdate  and  autodata.ndtime<=C.Enddate  THEN  loadunload
		WHEN (autodata.sttime<C.Startdate and  autodata.ndtime>C.Startdate and autodata.ndtime<=C.Enddate)  THEN DateDiff(second, C.Startdate, ndtime)
		WHEN (autodata.msttime>=C.Startdate  and autodata.sttime<C.Enddate  and autodata.ndtime>C.Enddate)  THEN DateDiff(second, stTime, C.Enddate)
		WHEN autodata.msttime<C.Startdate and autodata.ndtime>C.Enddate   THEN DateDiff(second, C.Startdate, C.Enddate)
		END
		)AS down
		from autodata 
		inner join machineinformation M ON autodata.mc = M.InterfaceID 
		left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
		inner join downcodeinformation D on autodata.dcode=D.interfaceid
		inner join DownCategoryInformation DCI on D.Catagory=DCI.DownCategory
		Cross join #ChangeOverDetails C
		--where autodata.datatype=2 AND M.Machineid=@Machineid and D.interfaceid in('201','211','212')  and
		where autodata.datatype=2 AND M.Machineid=@Machineid and D.interfaceid in('201','202','203')  and
		(
		(autodata.msttime>=C.Startdate  and  autodata.ndtime<=C.Enddate)
		OR (autodata.sttime<C.Startdate and  autodata.ndtime>C.Startdate and autodata.ndtime<=C.Enddate)
		OR (autodata.msttime>=C.Startdate  and autodata.sttime<C.Enddate  and autodata.ndtime>C.Enddate)
		OR (autodata.msttime<C.Startdate and autodata.ndtime>C.Enddate)
		) 
		group by C.Startdate,C.Enddate,D.Catagory)T1 inner join #ChangeOverDetails on #ChangeOverDetails.Startdate=T1.Startdate
		and #ChangeOverDetails.Enddate=T1.Enddate



		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
		BEGIN

			Update #ChangeOverDetails set ChangeOverMinutes=Isnull(ChangeOverMinutes,0) - Isnull(T1.down,0) from
			(select C.Startdate,C.Enddate,D.Catagory,sum(
			CASE
			WHEN  autodata.msttime>=T.StartTime  and  autodata.ndtime<=T.EndTime  THEN  loadunload
			WHEN (autodata.sttime<T.StartTime and  autodata.ndtime>T.StartTime and autodata.ndtime<=T.EndTime)  THEN DateDiff(second, T.StartTime, ndtime)
			WHEN (autodata.msttime>=T.StartTime  and autodata.sttime<T.EndTime  and autodata.ndtime>T.EndTime)  THEN DateDiff(second, stTime, T.EndTime)
			WHEN autodata.msttime<T.StartTime and autodata.ndtime>T.EndTime  THEN DateDiff(second, T.StartTime, T.EndTime)
			END
			)AS down
			from autodata CROSS JOIN PlannedDownTimes T 
			inner join machineinformation M ON autodata.mc = M.InterfaceID 
			left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
			inner join downcodeinformation D on autodata.dcode=D.interfaceid
			inner join DownCategoryInformation DCI on D.Catagory=DCI.DownCategory
			cross join #ChangeOverDetails C 
			--where autodata.datatype=2 AND M.Machineid=@Machineid and T.Machine=M.Machineid and D.interfaceid in('201','211','212') and
			where autodata.datatype=2 AND M.Machineid=@Machineid and T.Machine=M.Machineid and D.interfaceid in('201','202','203') and
			(
			(autodata.msttime>=T.StartTime  and  autodata.ndtime<=T.EndTime)
			OR (autodata.sttime<T.StartTime and  autodata.ndtime>T.StartTime and autodata.ndtime<=T.EndTime)
			OR (autodata.msttime>=T.StartTime  and autodata.sttime<T.EndTime  and autodata.ndtime>T.EndTime)
			OR (autodata.msttime<T.StartTime and autodata.ndtime>T.EndTime)
			) and
			(
			(T.Starttime >= C.Startdate  AND T.Endtime <=C.Enddate)
			OR ( T.Starttime < C.Startdate  AND T.Endtime <= C.Enddate AND T.Endtime > C.Startdate )
			OR ( T.Starttime >=C.Startdate   AND T.Starttime <C.Enddate AND T.Endtime > C.Enddate )
			OR ( T.Starttime < C.Startdate  AND T.Endtime >C.Enddate) )
			group by C.Startdate,C.Enddate,D.Catagory)T1 inner join #ChangeOverDetails on #ChangeOverDetails.Startdate=T1.Startdate
			and #ChangeOverDetails.Enddate=T1.Enddate

		END

		Select Startdate,Enddate,'Week' + Weekno as DisplayDate,NoOfChangeOvers,[dbo].[f_FormatTime](ChangeOverMinutes,'mm') as  ChangeOverMinutes from #ChangeOverDetails

END

If @param='Summary'  
Begin
	
Create table #Summary
(
Projectcode nvarchar(50),
ProjectCodeinterface nvarchar(50),
Prodqty int,
NoOfChangeOvers int,
ChangeOverMinutes float
)

If @Interval='Day'
BEGIN
	Select @Startdate = dbo.f_GetLogicalDay(@StartTime,'start')
	Select @Enddate = dbo.f_GetLogicalDay(@Endtime,'End')
END

If @Interval='Month'
BEGIN
	Select @Startdate = dbo.f_GetLogicalMonth(@StartTime,'Start')
	Select @Enddate=dbo.f_GetLogicalMonth(@Endtime,'end')
END


If @Interval='Week'
BEGIN

	Select @Startdate = dbo.f_GetLogicalDay(@StartTime,'start')
	Select @Enddate = dbo.f_GetLogicalDay(@Endtime,'End')
END

Insert into #summary(Projectcode,ProjectCodeinterface,NoOfChangeOvers)
SELECT distinct componentinformation.componentid,componentinformation.Interfaceid,0
from  autodata  
INNER JOIN  machineinformation on machineinformation.interfaceid=autodata.mc
INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID 
INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID
AND componentinformation.componentid = componentoperationpricing.componentid and componentoperationpricing.machineid=machineinformation.machineid 
INNER JOIN employeeinformation on autodata.opr=employeeinformation.interfaceid
Left Outer Join PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID 
where machineinformation.machineid=@Machineid and 
(( sttime >= @Startdate and ndtime <= @Enddate ) OR 
( sttime < @Startdate and ndtime > @Enddate )OR 
( sttime < @Startdate and ndtime > @Startdate and ndtime<=@Enddate)OR
( sttime >= @Startdate and ndtime > @Enddate and sttime<@Enddate)) 

Update #summary set Prodqty = Isnull(Prodqty,0) + Isnull(T1.Comp,0) from  
(Select T.ProjectCode,SUM(Isnull(A.partscount,1)/ISNULL(O.SubOperations,1)) As Comp
from autodata A
Inner join machineinformation M on M.interfaceid=A.mc
Inner join #summary T on T.ProjectCodeinterface=A.comp
Inner join componentinformation C ON A.Comp=C.interfaceid
Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID
WHERE A.DataType=1 and M.machineid=@Machineid
AND(A.ndtime > @Startdate  AND A.ndtime <=@Enddate) 
Group by T.ProjectCode)T1 inner join #summary on #summary.ProjectCode=T1.ProjectCode 


If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN

	Update #summary set Prodqty = Isnull(Prodqty,0) - Isnull(T2.Comp,0) from  (
	select T1.ProjectCode,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp From 
	( 
		select mc,S.ProjectCode,Sum(ISNULL(PartsCount,1))AS OrginalCount,comp,opn from autodata
		Inner join machineinformation M on M.interfaceid=autodata.mc
		Inner join #summary S on S.ProjectCodeinterface=autodata.comp
		CROSS JOIN PlannedDownTimes T
		WHERE autodata.DataType=1 And T.Machine = M.Machineid and M.Machineid=@Machineid
		AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)
		AND (autodata.ndtime > @StartTime  AND autodata.ndtime <=@EndTime)
		Group by s.ProjectCode,comp,mc,opn
	) as T1
	Inner join Machineinformation M on M.interfaceID = T1.mc
	Inner join componentinformation C on T1.Comp=C.interfaceid
	Inner join #summary T on T.ProjectCodeinterface=T1.comp
	Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineID = M.MachineID
	GROUP BY T1.ProjectCode
	) as T2 inner join #summary on #summary.ProjectCode=T2.ProjectCode 

END

Update #summary set NoOfChangeOvers = T1.RecCount,ChangeOverMinutes=T1.down from
(select T.ProjectCode,Count(D.downid) as RecCount,sum(
CASE
WHEN  autodata.msttime>=@Startdate  and  autodata.ndtime<=@Enddate  THEN  loadunload
WHEN (autodata.sttime<@Startdate and  autodata.ndtime>@Startdate and autodata.ndtime<=@Enddate)  THEN DateDiff(second, @Startdate, ndtime)
WHEN (autodata.msttime>=@Startdate  and autodata.sttime<@Enddate and autodata.ndtime>@Enddate)  THEN DateDiff(second, stTime,@Enddate)
WHEN autodata.msttime<@Startdate and autodata.ndtime>@Enddate   THEN DateDiff(second, @Startdate, @Enddate)
END
)AS down
from autodata 
inner join machineinformation M ON autodata.mc = M.InterfaceID 
left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
inner join downcodeinformation D on autodata.dcode=D.interfaceid
inner join DownCategoryInformation DCI on D.Catagory=DCI.DownCategory
Inner join #summary T on T.ProjectCodeinterface=autodata.comp
--where autodata.datatype=2 AND M.Machineid=@Machineid and D.interfaceid in('201','211','212') and
where autodata.datatype=2 AND M.Machineid=@Machineid and D.interfaceid in('201','202','203') and
(
(autodata.msttime>=@Startdate  and  autodata.ndtime<=@Enddate)
OR (autodata.sttime<@Startdate and  autodata.ndtime>@Startdate and autodata.ndtime<=@Enddate)
OR (autodata.msttime>=@Startdate  and autodata.sttime<@Enddate  and autodata.ndtime>@Enddate)
OR (autodata.msttime<@Startdate and autodata.ndtime>@Enddate)
) 
group by T.ProjectCode)T1 inner join #summary on #summary.ProjectCode=T1.ProjectCode 

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN

	UPDATE #summary set ChangeOverMinutes =isnull(ChangeOverMinutes,0) - isNull(TT.DPDT ,0)
	FROM(
		SELECT s.ProjectCode,SUM
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
		Inner join #summary s on s.ProjectCodeinterface=autodata.comp
		--where autodata.datatype=2 AND M.Machineid=@Machineid and  D.interfaceid in('201','211','212') and
		where autodata.datatype=2 AND M.Machineid=@Machineid and  D.interfaceid in('201','202','203') and
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
			) 
	group by s.ProjectCode
	) as TT inner join #summary on #summary.ProjectCode=TT.ProjectCode 
END

Select Projectcode,Prodqty,NoOfChangeOvers,[dbo].[f_FormatTime](ChangeOverMinutes,'mm') as  ChangeOverMinutes from #Summary
order by Prodqty desc
END

END
