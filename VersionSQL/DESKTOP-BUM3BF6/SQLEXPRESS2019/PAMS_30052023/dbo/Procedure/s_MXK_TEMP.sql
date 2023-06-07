/****** Object:  Procedure [dbo].[s_MXK_TEMP]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE  PROCEDURE [dbo].[s_MXK_TEMP]
	@StartTime datetime output,
	@EndTime datetime output,
	@MachineID nvarchar(50) = ''
AS
BEGIN
CREATE TABLE #CockPitData (
	MachineID nvarchar(50),
	MachineInterface nvarchar(50),
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
	CN float,
	Remarks nvarchar(40)
)
if isnull(@machineid,'')<> ''
begin
	INSERT INTO #CockpitData (
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
	CN
	)
	SELECT MachineID, interfaceid ,0,0,0,0,0,0,0,0,0,0,0
	FROM MachineInformation WHERE MachineID = @machineid
end
else
begin
	INSERT INTO #CockpitData (
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
	CN
	)
	SELECT MachineID, interfaceid ,0,0,0,0,0,0,0,0,0,0,0
	FROM MachineInformation
end

-- Get the utlised time
-- Type 1
UPDATE #CockpitData SET UtilisedTime = UtilisedTime +
isNull((select
	sum(cycletime+loadunload)
from autodata
where
	(autodata.mc = #CockpitData.machineinterface)
and (autodata.msttime>=@StartTime)
and (autodata.ndtime<=@EndTime)
and (autodata.datatype=1)
),0)

-- Type 2
UPDATE #CockpitData SET UtilisedTime = UtilisedTime +
isNull((
select
	sum(DateDiff(second, @StartTime, ndtime))	
from autodata
where
	(autodata.mc = #CockpitData.machineinterface)
and (autodata.msttime<@StartTime)
and (autodata.ndtime>@StartTime)
and (autodata.ndtime<=@EndTime)
and (autodata.datatype=1)
),0)


-- Type 3
UPDATE #CockpitData SET UtilisedTime = UtilisedTime +
isNull((
select
	sum(DateDiff(second, mstTime, @Endtime))
from autodata
where


	(autodata.mc = #CockpitData.machineinterface)
and (autodata.msttime>=@StartTime)
and (autodata.msttime<@EndTime)
and (autodata.ndtime>@EndTime)
and (autodata.datatype=1)
),0)

-- Type 4
UPDATE #CockpitData SET UtilisedTime = UtilisedTime +
isNull((
select
	sum(DateDiff(second, @StartTime, @EndTime))
from autodata
where
	(autodata.mc = #CockpitData.machineinterface)
and (autodata.msttime<@StartTime)
and (autodata.ndtime>@EndTime)
and (autodata.datatype=1)
),0)



SELECT
MachineID ,
UtilisedTime,
Convert(nvarchar(4), convert(bigint, UtilisedTime)/3600) + ':' + convert(nvarchar(2), (convert(bigint, UtilisedTime)%3600)/60) + ':' + convert(nvarchar(2), (convert(bigint, UtilisedTime)%60)) as UtilisedTimeHHMMSS,
@StartTime as StartTime,
@EndTime as EndTime
FROM #CockpitData
END
