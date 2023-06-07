/****** Object:  Procedure [dbo].[s_GetCockpitMachineEventsData]    Committed by VersionSQL https://www.versionsql.com ******/

/***************************************************************************************
NR0118 - SwathiKS - 27/Oct/2015 ::Specific To Shriram pistons :: New Procedure to show InCyclestages in Cockpit- VDG.
s_GetCockpitMachineEventsData '2015-11-16 06:00:00 AM','2015-11-17 06:00:00 AM','Metal','Grid'
s_GetCockpitMachineEventsData '2015-11-16 06:00:00 AM','2015-11-17 06:00:00 AM','Metal','ALL'
s_GetCockpitMachineEventsData '2015-11-16 06:00:00 AM','2015-11-17 06:00:00 AM','Metal','DieCloseTime'
s_GetCockpitMachineEventsData '2015-11-16 06:00:00 AM','2015-11-17 06:00:00 AM','Metal','PouringTime'
s_GetCockpitMachineEventsData '2015-11-16 06:00:00 AM','2015-11-17 06:00:00 AM','Metal','SolidificationTime'
s_GetCockpitMachineEventsData '2015-11-16 06:00:00 AM','2015-11-17 06:00:00 AM','Metal','DieOpenTime'
**************************************************************************************/
CREATE PROCEDURE [dbo].[s_GetCockpitMachineEventsData]
	@StartTime datetime,
	@EndTime datetime,
	@MachineID nvarchar(50),
	@Param nvarchar(50)
AS
BEGIN

SELECT
IDENTITY(int, 1, 1) AS SerialNo,
componentinformation.componentid AS ComponentID,
componentinformation.description AS description, 
componentoperationpricing.operationno AS OperationNo,
Isnull(employeeinformation.Employeeid,autodata.opr) AS OperatorID,
Isnull(employeeinformation.[name],'---') AS OperatorName,
autodata.sttime AS StartTime,
autodata.ndtime AS EndTime,
autodata.cycletime AS CycleTime,
autodata.mc as MachineInterface,
autodata.comp as CompInterface,
autodata.opn as OpnInterface,
ISNULL(componentoperationpricing.StdDieCloseTime,0) as StdDieCloseTime,
ISNULL(componentoperationpricing.StdPouringTime,0)as StdPouringTime,
ISNULL(componentoperationpricing.StdSolidificationTime,0)as StdSolidificationTime,
ISNULL(componentoperationpricing.StdDieOpenTime,0)as StdDieOpenTime,
0 as ActualDieCloseTime,
0 as ActualPouringTime,
0 as ActualSolidificationTime,
0 as ActualDieOpenTime,
autodata.id
INTO #TempCockpitProductionData
FROM         autodata 
INNER JOIN machineinformation ON autodata.mc = machineinformation.InterfaceID 
INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID 
INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID
AND componentinformation.componentid =  componentoperationpricing.componentid
and componentoperationpricing.machineid=machineinformation.machineid
LEFT OUTER JOIN employeeinformation ON autodata.opr = employeeinformation.interfaceid 
WHERE
(autodata.sttime >= @StartTime )
AND
(autodata.sttime < @EndTime )
AND
(machineinformation.machineid = N'' + @MachineID + '')
AND
(autodata.datatype = 1)
ORDER BY autodata.sttime

Update #TempCockpitProductionData set ActualDieCloseTime = T1.Dieclose from
(Select T.machineinterface,T.StartTime,
Sum(datediff(s,M.starttime,M.endtime)) as dieclose from Machineeventsautodata M 
INNER JOIN machineinformation ON M.machineinterface = machineinformation.InterfaceID 
INNER JOIN #TempCockpitProductionData T on M.machineinterface=T.MachineInterface and M.sttime=T.StartTime
where machineinformation.machineid = N'' + @MachineID + '' and M.Eventid='100' 
Group by T.machineinterface,T.StartTime)T1 inner join #TempCockpitProductionData T on T1.machineinterface=T.MachineInterface and T1.StartTime=T.StartTime

Update #TempCockpitProductionData set ActualPouringTime = T1.PouringTime from
(Select T.machineinterface,T.StartTime,
Sum(datediff(s,M.starttime,M.endtime)) as PouringTime from Machineeventsautodata M 
INNER JOIN machineinformation ON M.machineinterface = machineinformation.InterfaceID 
INNER JOIN #TempCockpitProductionData T on M.machineinterface=T.MachineInterface and M.sttime=T.StartTime
where machineinformation.machineid = N'' + @MachineID + '' and M.Eventid='101' 
Group by T.machineinterface,T.StartTime)T1 inner join #TempCockpitProductionData T on T1.machineinterface=T.MachineInterface and T1.StartTime=T.StartTime

Update #TempCockpitProductionData set ActualSolidificationTime = T1.SolidificationTime from
(Select T.machineinterface,T.StartTime,
Sum(datediff(s,M.starttime,M.endtime)) as SolidificationTime from Machineeventsautodata M 
INNER JOIN machineinformation ON M.machineinterface = machineinformation.InterfaceID 
INNER JOIN #TempCockpitProductionData T on M.machineinterface=T.MachineInterface and M.sttime=T.StartTime
where machineinformation.machineid = N'' + @MachineID + '' and M.Eventid='102' 
Group by T.machineinterface,T.StartTime)T1 inner join #TempCockpitProductionData T on T1.machineinterface=T.MachineInterface and T1.StartTime=T.StartTime

Update #TempCockpitProductionData set ActualDieOpenTime = T1.DieOpenTime from
(Select T.machineinterface,T.StartTime,
Sum(datediff(s,M.starttime,M.endtime)) as DieOpenTime from Machineeventsautodata M 
INNER JOIN machineinformation ON M.machineinterface = machineinformation.InterfaceID 
INNER JOIN #TempCockpitProductionData T on M.machineinterface=T.MachineInterface and M.sttime=T.StartTime
where machineinformation.machineid = N'' + @MachineID + '' and M.Eventid='103' 
Group by T.machineinterface,T.StartTime)T1 inner join #TempCockpitProductionData T on T1.machineinterface=T.MachineInterface and T1.StartTime=T.StartTime

--ER0295 Modified From here.
If ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y' and
(SELECT ValueInInt From CockpitDefaults Where Parameter ='VDG-CycleDefinition')=2)
BEGIN

set ansi_warnings off
UPDATE #TempCockpitProductionData set  CycleTime=isnull(CycleTime,0) - isNull(TT.PPDT ,0)
	FROM(
		--Production Time in PDT
	Select A.mc,A.comp,A.Opn,A.sttime,A.ndtime,A.msttime,Sum
			(CASE
			WHEN A.sttime >= T.StartTime  AND A.ndtime <=T.EndTime  THEN (A.cycletime)
			WHEN ( A.sttime < T.StartTime  AND A.ndtime <= T.EndTime  AND A.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,A.ndtime)
			WHEN ( A.sttime >= T.StartTime   AND A.sttime <T.EndTime  AND A.ndtime > T.EndTime  ) THEN DateDiff(second,A.sttime,T.EndTime )
			WHEN ( A.sttime < T.StartTime  AND A.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END)  as PPDT,
			sum(case
			WHEN A.msttime >= T.StartTime  AND A.sttime <=T.EndTime  THEN DateDiff(second,A.msttime,A.sttime)
			WHEN ( A.msttime < T.StartTime  AND A.sttime <= T.EndTime  AND A.sttime > T.StartTime ) THEN DateDiff(second,T.StartTime,A.sttime)
			WHEN ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime  AND A.sttime > T.EndTime  ) THEN DateDiff(second,A.msttime,T.EndTime )
			WHEN ( A.msttime < T.StartTime  AND A.sttime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END)  as LD
	From
			
		(
			SELECT M.Machineid,
			autodata.MC,autodata.comp,autodata.Opn,autodata.sttime,autodata.ndtime,autodata.Cycletime,
			autodata.msttime,autodata.loadunload
			FROM AutoData inner join Machineinformation M on M.interfaceid=Autodata.mc
			--where autodata.DataType=1 And autodata.msttime >=@StartTime  AND autodata.msttime < @EndTime)A --DR0309 Swathi 21/Jun/12
			where autodata.DataType=1 And autodata.sttime >=@StartTime  AND autodata.sttime < @EndTime)A --DR0309 Swathi 21/Jun/12
			CROSS jOIN PlannedDownTimes T
			WHERE T.Machine=A.Machineid AND
			
			((A.msttime >= T.StartTime  AND A.ndtime <=T.EndTime)
			OR ( A.msttime < T.StartTime  AND A.ndtime <= T.EndTime AND A.ndtime > T.StartTime )
			OR ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime AND A.ndtime > T.EndTime )
			OR ( A.msttime < T.StartTime  AND A.ndtime > T.EndTime) )
			and T.PDTStatus = 1   
		group by A.mc,A.comp,A.Opn,A.sttime,A.ndtime,A.msttime
	)
	as TT INNER JOIN #TempCockpitProductionData ON TT.mc = #TempCockpitProductionData.MachineInterface
		and TT.comp = #TempCockpitProductionData.CompInterface
			and TT.opn = #TempCockpitProductionData.OPNInterface and tt.sttime=#TempCockpitProductionData.StartTime
and #TempCockpitProductionData.EndTime=TT.ndtime
--ER0295 Modified Till here.

 
		/********************************* DR0349 Added From here ************************************/
		--Handle intearction between ICD and PDT for type 1 production record for the selected time period.
		UPDATE  #TempCockpitProductionData set CycleTime =isnull(CycleTime,0) + isNull(T2.IPDT ,0) 	FROM	
		(
		Select T1.mc,T1.comp,T1.opn,T1.sttime,T1.ndtime,T1.cyclestart,T1.Cycleend,SUM(
			CASE 	
				When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1
				When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2
				When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3
				when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4
			END) as IPDT from
		(Select A.mc,A.comp,A.opn,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime,A.ndtime, A.datatype,
		 B.Sttime as CycleStart,B.ndtime as CycleEnd from autodata A inner join AutoData B on B.mc = A.mc
		 Where A.DataType=2 and B.DataType=1
			And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And
			(B.msttime >= @starttime AND B.ndtime <= @Endtime) and
			(B.sttime < A.sttime) AND (B.ndtime > A.ndtime) 
			
		 )as T1 inner join
		(select  machine,Case when starttime<@starttime then @starttime else starttime end as starttime, 
		case when endtime> @Endtime then @Endtime else endtime end as endtime from dbo.PlannedDownTimes 
		where PDTStatus = 1 and ((( StartTime >=@starttime) And ( EndTime <=@Endtime))
		or (StartTime < @starttime  and  EndTime <= @Endtime AND EndTime > @starttime)
		or (StartTime >= @starttime  AND StartTime <@Endtime AND EndTime > @Endtime)
		or (( StartTime <@starttime) And ( EndTime >@Endtime )) )
		)T
		on T1.machine=T.machine AND
		((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
		or (T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
		or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
		or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )group by T1.mc,T1.comp,T1.opn,T1.sttime,T1.ndtime,T1.cyclestart,T1.Cycleend
		)AS T2  INNER JOIN #TempCockpitProductionData ON T2.mc = #TempCockpitProductionData.MachineInterface
				and T2.comp = #TempCockpitProductionData.CompInterface
			and T2.opn = #TempCockpitProductionData.OPNInterface and t2.cyclestart=#TempCockpitProductionData.StartTime
		and #TempCockpitProductionData.EndTime=T2.Cycleend
		/********************************* DR0349 Added Till here ************************************/
set ansi_warnings ON
End


declare @strsql as nvarchar(4000)

Declare @VDGComp as nvarchar(50)
Select @VDGComp=''
Select @VDGComp=(Select ValueInText From CockpitDefaults WHERE Parameter ='VDG-ComponentSetting')

declare @TimeFormat as nvarchar(50)
SELECT @TimeFormat = ''
SELECT @TimeFormat = (SELECT  ValueInText  FROM CockpitDefaults WHERE Parameter = 'TimeFormat')
if (ISNULL(@TimeFormat,'')) = ''
	SELECT @TimeFormat = N'ss'

If @param= 'Grid'
Begin
	SELECT @strsql = 'SELECT SerialNo, '

	If @VDGComp = 'In VDG Grid - ComponentID without Description' 
	Begin
	SELECT @strsql = @strsql +'Componentid as Componentid, '
	End

	if @VDGComp = 'In VDG Grid - ComponentID with Description'
	Begin
	SELECT @strsql = @strsql +'Componentid + ''(''+ Description + '')'' as ''Componentid'', '
	End

	SELECT @strsql = @strsql +'OperationNo,OperatorID,OperatorName,convert(nvarchar(20),StartTime,120) as StartTime,convert(nvarchar(20),EndTime,120) as EndTime, '

	if (@TimeFormat = 'hh:mm:ss'or @TimeFormat = 'hh' or @TimeFormat = 'mm' or @TimeFormat = 'ss' )
	BEGIN
		SELECT @strsql =  @strsql  +'dbo.f_FormatTime(CycleTime,''' + @TimeFormat + ''') as CycleTime,'
		SELECT @strsql =  @strsql  +'dbo.f_FormatTime(StdDieCloseTime,''' + @TimeFormat + ''') as StdDieCloseTime,'
		SELECT @strsql =  @strsql  +'dbo.f_FormatTime(ActualDieCloseTime,''' + @TimeFormat + ''') as ActualDieCloseTime,'
		SELECT @strsql =  @strsql  +'dbo.f_FormatTime(StdPouringTime,''' + @TimeFormat + ''') as StdPouringTime,'
		SELECT @strsql =  @strsql  +'dbo.f_FormatTime(ActualPouringTime,''' + @TimeFormat + ''') as ActualPouringTime,'
		SELECT @strsql =  @strsql  +'dbo.f_FormatTime(StdSolidificationTime,''' + @TimeFormat + ''') as StdSolidificationTime,'
		SELECT @strsql =  @strsql  +'dbo.f_FormatTime(ActualSolidificationTime,''' + @TimeFormat + ''') as ActualSolidificationTime,'
		SELECT @strsql =  @strsql  +'dbo.f_FormatTime(StdDieOpenTime,''' + @TimeFormat + ''') as StdDieOpenTime,'
		SELECT @strsql =  @strsql  +'dbo.f_FormatTime(ActualDieOpenTime,''' + @TimeFormat + ''') as ActualDieOpenTime,'
	ENd

	SELECT @strsql =  @strsql  + 'id FROM #TempCockpitProductionData order by SerialNo'
	print @strsql
	EXEC (@strsql)
END


If @param= 'ALL'
Begin
	
	SELECT @TimeFormat = N'ss'

	SELECT @strsql = 'SELECT '

	if (@TimeFormat = 'hh:mm:ss'or @TimeFormat = 'hh' or @TimeFormat = 'mm' or @TimeFormat = 'ss' )
	BEGIN
		SELECT @strsql =  @strsql  +'dbo.f_FormatTime(StdDieCloseTime,''' + @TimeFormat + ''') as StdDieCloseTime,'
		SELECT @strsql =  @strsql  +'dbo.f_FormatTime(ActualDieCloseTime,''' + @TimeFormat + ''') as ActualDieCloseTime,'
		SELECT @strsql =  @strsql  +'dbo.f_FormatTime(StdPouringTime,''' + @TimeFormat + ''') as StdPouringTime,'
		SELECT @strsql =  @strsql  +'dbo.f_FormatTime(ActualPouringTime,''' + @TimeFormat + ''') as ActualPouringTime,'
		SELECT @strsql =  @strsql  +'dbo.f_FormatTime(StdSolidificationTime,''' + @TimeFormat + ''') as StdSolidificationTime,'
		SELECT @strsql =  @strsql  +'dbo.f_FormatTime(ActualSolidificationTime,''' + @TimeFormat + ''') as ActualSolidificationTime,'
		SELECT @strsql =  @strsql  +'dbo.f_FormatTime(StdDieOpenTime,''' + @TimeFormat + ''') as StdDieOpenTime,'
		SELECT @strsql =  @strsql  +'dbo.f_FormatTime(ActualDieOpenTime,''' + @TimeFormat + ''') as ActualDieOpenTime'
	ENd

	SELECT @strsql =  @strsql  + '  ,SerialNo FROM #TempCockpitProductionData order by SerialNo'
	print @strsql
	EXEC (@strsql)
END

If @param= 'DieCloseTime'
Begin

	SELECT @TimeFormat = N'ss'

	SELECT @strsql = 'SELECT '

	if (@TimeFormat = 'hh:mm:ss'or @TimeFormat = 'hh' or @TimeFormat = 'mm' or @TimeFormat = 'ss' )
	BEGIN
		SELECT @strsql =  @strsql  +'dbo.f_FormatTime(StdDieCloseTime,''' + @TimeFormat + ''') as StdDieCloseTime,'
		SELECT @strsql =  @strsql  +'dbo.f_FormatTime(ActualDieCloseTime,''' + @TimeFormat + ''') as ActualDieCloseTime'
	ENd

	SELECT @strsql =  @strsql  + ',SerialNo FROM #TempCockpitProductionData order by SerialNo'
	print @strsql
	EXEC (@strsql)
END

If @param= 'PouringTime'
Begin

	SELECT @TimeFormat = N'ss'

	SELECT @strsql = 'SELECT '


	if (@TimeFormat = 'hh:mm:ss'or @TimeFormat = 'hh' or @TimeFormat = 'mm' or @TimeFormat = 'ss' )
	BEGIN
		SELECT @strsql =  @strsql  +'dbo.f_FormatTime(StdPouringTime,''' + @TimeFormat + ''') as StdPouringTime,'
		SELECT @strsql =  @strsql  +'dbo.f_FormatTime(ActualPouringTime,''' + @TimeFormat + ''') as ActualPouringTime'
	ENd

	SELECT @strsql =  @strsql  + ',SerialNo FROM #TempCockpitProductionData order by SerialNo'
	print @strsql
	EXEC (@strsql)
END

If @param= 'SolidificationTime'
Begin
	SELECT @TimeFormat = N'ss'

	SELECT @strsql = 'SELECT '

	if (@TimeFormat = 'hh:mm:ss'or @TimeFormat = 'hh' or @TimeFormat = 'mm' or @TimeFormat = 'ss' )
	BEGIN
		SELECT @strsql =  @strsql  +'dbo.f_FormatTime(StdSolidificationTime,''' + @TimeFormat + ''') as StdSolidificationTime,'
		SELECT @strsql =  @strsql  +'dbo.f_FormatTime(ActualSolidificationTime,''' + @TimeFormat + ''') as ActualSolidificationTime'
	ENd

	SELECT @strsql =  @strsql  + ',SerialNo FROM #TempCockpitProductionData order by SerialNo'
	print @strsql
	EXEC (@strsql)
END

If @param= 'DieOpenTime'
Begin
	SELECT @TimeFormat = N'ss'

	SELECT @strsql = 'SELECT '

	if (@TimeFormat = 'hh:mm:ss'or @TimeFormat = 'hh' or @TimeFormat = 'mm' or @TimeFormat = 'ss' )
	BEGIN
		SELECT @strsql =  @strsql  +'dbo.f_FormatTime(StdDieOpenTime,''' + @TimeFormat + ''') as StdDieOpenTime,'
		SELECT @strsql =  @strsql  +'dbo.f_FormatTime(ActualDieOpenTime,''' + @TimeFormat + ''') as ActualDieOpenTime'
	ENd

	SELECT @strsql =  @strsql  + ',SerialNo FROM #TempCockpitProductionData order by SerialNo'
	print @strsql
	EXEC (@strsql)
END


END
