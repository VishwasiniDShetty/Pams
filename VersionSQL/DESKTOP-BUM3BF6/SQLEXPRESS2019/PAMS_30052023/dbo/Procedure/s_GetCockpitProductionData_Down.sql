/****** Object:  Procedure [dbo].[s_GetCockpitProductionData_Down]    Committed by VersionSQL https://www.versionsql.com ******/

/***************************************************************************************
Used in vdg for BOSCH in SmartCockpit
Used in Export option in VDG4bosch
Procedure created by Mrudula for Bosch customization on 17-sep-2008
ER0154:KarthikG:04-Dec-2008::Need one more column in production tab showing No of Events
and should reflect in the export report also.
DR0153:KarthikG:04-Dec-2008::Displaying * in place of Events Count and avoid using recordcount property
mod 1 :- For ER0161 to get optional stop counts for the cycle
mod 2 :- ER0181 By Kusuma M.H on 11-May-2009.2) Modify all the procedures accordingly. Qualify machine wherever we are making use of component and opeartion no.
mod 3 :- ER0182 By Kusuma M.H on 11-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
mod 4 :- By Mrudula M. Rao on 30-jan-2010.ER0210 Introduce PDT on 5150. 1) Handle PDT at Machine Level. 
ER0396 - SwathiKS - 30/Oct/2014 :: To handle error 'Cannot insert value NULL into SerialNo table #TempCockpitProductionData'.
**************************************************************************************/
--s_GetCockpitProductionData_Down '2014-10-01 06:38:02 AM','2014-10-02 07:05:15 AM','HBM'
CREATE           PROCEDURE [dbo].[s_GetCockpitProductionData_Down]
	@StartTime datetime,
	@EndTime datetime,
	@MachineID nvarchar(50)
AS
BEGIN
-- 05/14/2004 satyendra included serialNo, Remarks, ID and create aTemp Table and time comparision
--- 16-Dec-2004 sjaiswal , include OpearatorName

--ER0396 From Here
create table #TempCockpitProductionData
(
SerialNo int,
ComponentID nvarchar(50),
OperationNo nvarchar(50),
OperatorID nvarchar(50),
OperatorName nvarchar(50),
StartTime datetime,
EndTime datetime,
Msttime datetime,
CycleTime int,
LoadUnloadTime int,
Remarks nvarchar(255),
StdCycleTime float,
StdMachiningTime float,
id bigint,
In_Cycle_DownTime int,
datatype int, 
EventsCount int,
OptStop int
)
--ER0396 From Here

declare @valueintext as nvarchar(50)
Select @valueintext= ValueInText + ' Time' FROM Cockpitdefaults where Parameter= 'ShowDownTimeAs'

If @valueintext=''
Begin 
 SET @valueintext = 'DownTime'
End

Insert into #TempCockpitProductionData --ER0396 Added
SELECT
---mod 4
--IDENTITY(int, 1, 1) AS SerialNo,
0 AS SerialNo,
---mod 4
CASE WHEN autodata.datatype=1 then
--componentinformation.componentid when autodata.datatype=2 then 'Downtime' end --SV
componentinformation.componentid when autodata.datatype=2 then @valueintext end --SV
AS ComponentID,
CASE WHEN autodata.datatype=1 then convert(nvarchar(50),componentoperationpricing.operationno)
when autodata.datatype=2 then downcodeinformation.downdescription end AS OperationNo,
employeeinformation.Employeeid AS OperatorID,
employeeinformation.[name]
AS OperatorName,
autodata.sttime AS StartTime,
autodata.ndtime AS EndTime,
autodata.msttime AS Msttime,
autodata.cycletime AS CycleTime,
ISNULL(autodata.loadunload,0) AS LoadUnloadTime,
autodata.Remarks,
--ISNULL(autodata.loadunload,0)-(ISNULL(componentoperationpricing.cycletime,0) - ISNULL(componentoperationpricing.machiningtime,0)) AS LULoss,--SSK:ER0025:25/07/07
ISNULL(componentoperationpricing.cycletime,0)StdCycleTime,
ISNULL(componentoperationpricing.machiningtime,0)StdMachiningTime,--SSK:DR0040:21/08/07
autodata.id,
CASE
WHEN DATEDIFF(SECOND,autodata.sttime,autodata.ndtime)>autodata.cycletime and autodata.datatype=1
THEN DATEDIFF(SECOND,autodata.sttime,autodata.ndtime)-autodata.cycletime
ELSE  0
END  AS  In_Cycle_DownTime,
autodata.datatype as datatype,0 as EventsCount
---mod 1
,0 as OptStop
---mod 1
--INTO #TempCockpitProductionData --ER0396 Commented
FROM         autodata INNER JOIN
machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID INNER JOIN
componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID
AND componentinformation.componentid =  componentoperationpricing.componentid
---mod 2
and componentoperationpricing.machineid=machineinformation.machineid
---mod 2
INNER JOIN employeeinformation ON autodata.opr = employeeinformation.interfaceid left outer join downcodeinformation
on downcodeinformation.interfaceid=autodata.dcode
WHERE
(autodata.sttime >= @StartTime )
AND
(autodata.sttime < @EndTime)
AND
---mod 3
--(machineinformation.machineid = @MachineID)
(machineinformation.machineid = N'' + @MachineID + '')
---mod 3
--AND
--(autodata.datatype = 1)
ORDER BY autodata.sttime


--mod 4: Get the planned down times defined for the machine
If ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N') OR ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y')
BEGIN
	Insert Into #TempCockpitProductionData(StartTime,EndTime,ComponentID,OperationNo,LoadUnloadTime,datatype) 
	SELECT case when StartTime<@StartTime then @StartTime else StartTime End as StartTime,
	case when EndTime> @EndTime then @EndTime else EndTime End as EndTime,'PDT',Downreason,
	CASE
	WHEN (StartTime >= @StartTime  AND EndTime <=@EndTime)  THEN DateDiff(second,StartTime,EndTime)
	WHEN ( StartTime < @StartTime  AND EndTime <= @EndTime AND EndTime > @StartTime ) THEN DateDiff(second,@StartTime,EndTime)
	WHEN ( StartTime >= @StartTime   AND StartTime <@EndTime AND EndTime > @EndTime ) THEN DateDiff(second,StartTime,@EndTime)
	ELSE DateDiff(second,@StartTime,@EndTime)
	END as LoadUnloadTime ,2
	From PlannedDownTimes Where(
		   (StartTime >= @StartTime  AND EndTime <=@EndTime) 
		OR ( StartTime < @StartTime  AND EndTime <= @EndTime AND EndTime > @StartTime )
		OR ( StartTime >= @StartTime   AND StartTime <@EndTime AND EndTime > @EndTime )
		OR ( StartTime < @StartTime  AND EndTime > @EndTime) ) and pdtstatus=1 
		and PlannedDownTimes.Machine=N''+@MachineID+''
END
--mod 4


---events for the cycle
update #TempCockpitProductionData set EventsCount = t1.EventsCount from (
select msttime,Endtime,count(autodataalarms.machineid) as EventsCount from #TempCockpitProductionData inner join autodataalarms on
alarmtime > msttime and alarmtime <= Endtime
---mod 3
--where machineid = (select interfaceid from machineinformation where machineid = @MachineID) and
where machineid = (select interfaceid from machineinformation where machineid = N'' + @MachineID + '') and
---mod 3
recordtype = '16'
group by msttime,Endtime
) as t1 inner join #TempCockpitProductionData on
t1.msttime = #TempCockpitProductionData.msttime and t1.Endtime = #TempCockpitProductionData.endtime
--update #TempCockpitProductionData set EventsCount = (select * from autodataalarms)
---mod 1

---optional stops for cycle
update #TempCockpitProductionData set OptStop = t1.OptStop from (
select #TempCockpitProductionData.StartTime,#TempCockpitProductionData.Endtime,count(autodatadetails.machine) as OptStop from #TempCockpitProductionData inner join autodatadetails on
autodatadetails.StartTime >#TempCockpitProductionData.StartTime and autodatadetails.StartTime < #TempCockpitProductionData.Endtime
---mod 3
--where machine = (select interfaceid from machineinformation where machineid = @MachineID) and
where machine = (select interfaceid from machineinformation where machineid = N'' + @MachineID + '') and
---mod 3
recordtype = '70'
group by #TempCockpitProductionData.StartTime,#TempCockpitProductionData.Endtime
) as t1 inner join #TempCockpitProductionData on
t1.StartTime = #TempCockpitProductionData.StartTime and t1.Endtime = #TempCockpitProductionData.endtime
---mod 1
---       Select * from #TempCockpitProductionData order by SerialNo



select  IDENTITY(int, 1, 1) AS SerialNo,ComponentID,
OperationNo,
OperatorID,
OperatorName,
StartTime,
EndTime,
Msttime,
CycleTime,
LoadUnloadTime,
Remarks,
StdCycleTime,
StdMachiningTime,--SSK:DR0040:21/08/07
id,
In_Cycle_DownTime,
datatype, EventsCount
,OptStop into #TempCockpitProductionData_int from #TempCockpitProductionData order by Starttime

truncate table  #TempCockpitProductionData

insert into #TempCockpitProductionData
select *  from #TempCockpitProductionData_int

declare @strsql as nvarchar(4000)
declare @TimeFormat as nvarchar(50)
SELECT @TimeFormat = ''
SELECT @TimeFormat = (SELECT  ValueInText  FROM CockpitDefaults WHERE Parameter = 'TimeFormat')
if (ISNULL(@TimeFormat,'')) = ''
	SELECT @TimeFormat = 'ss'
SELECT @strsql = 'SELECT SerialNo,ComponentID,OperationNo,OperatorID,OperatorName,StartTime,EndTime,'
if (@TimeFormat = 'hh:mm:ss'or @TimeFormat = 'hh' or @TimeFormat = 'mm' or @TimeFormat = 'ss' )
BEGIN
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(CycleTime,''' + @TimeFormat + ''') as CycleTime,'
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(LoadUnloadTime,''' + @TimeFormat + ''') as LoadUnloadTime,'
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(In_Cycle_DownTime,''' + @TimeFormat + ''') as In_Cycle_DownTime,'
	SELECT @strsql =  @strsql  +'case when datatype=1 then dbo.f_FormatTime(LoadUnloadTime-(StdCycleTime-StdMachiningTime),''' + @TimeFormat + ''') end AS LULoss,'
END
SELECT @strsql =  @strsql  + ' Remarks,id,CycleTime as SortCycleTime,LoadUnloadTime as SortLoadUnloadTime,datatype'
SELECT @strsql =  @strsql  + ', case when datatype=1 then dbo.f_FormatTime(CycleTime-(StdMachiningTime),''' + @TimeFormat + ''') end AS MachineTimeLoss
			      ,case when datatype=1 and (CycleTime-(StdMachiningTime))>0 then 1
else 0 End as MachinetimeLossFlag
			      ,case when datatype=1 and (LoadUnloadTime-(StdCycleTime-StdMachiningTime))>0 then 1
else 0 End as LULossFlag,EventsCount,OptStop
		 FROM #TempCockpitProductionData order by SerialNo'
--print @strsql
EXEC (@strsql)
END
