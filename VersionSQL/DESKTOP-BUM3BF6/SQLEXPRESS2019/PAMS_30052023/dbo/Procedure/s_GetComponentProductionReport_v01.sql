/****** Object:  Procedure [dbo].[s_GetComponentProductionReport_v01]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE  PROCEDURE [dbo].[s_GetComponentProductionReport_v01]
	@StartTime DateTime,
	@EndTime DateTime,
	@MachineID  nvarchar(50) = '',
	@ComponentID  nvarchar(50) = '',
	@OperatorID  nvarchar(50) = '',
	@MachineIDLabel nvarchar(50) ='ALL',
	@OperatorIDLabel nvarchar(50) = 'ALL',
	@ComponentIDLabel nvarchar(50) = 'ALL'
AS
BEGIN
-- Create temporary table to store the report data
CREATE TABLE #ProductionData (
	MachineID nvarchar(50),
	OperatorID nvarchar(50),
	ComponentID nvarchar(50) primary key,
	Production float,
	Rejection float,
	CN float,
	TurnOver float,
	ProductionTime float,
	DownTime float,
	AvailabilityEfficiency float,
	ProductionEfficiency float,
	QualityEfficiency float,
	OverAllEfficiency float,	
	AvailabilityEfficiencyLoss float	
	)
-- Temporary Table For Loading the Production and Down Time Data
CREATE TABLE #Time ( tTime float, ComponentID nvarchar(50) primary key)
-- Load the production details into the table
INSERT #ProductionData (ComponentID , Production, Rejection, CN, TurnOver)
EXEC s_GetComponentProductionData @StartTime, @EndTime, @MachineID, @ComponentID, @OperatorID
-- Load Production Time Data
INSERT #Time (tTime, ComponentID ) EXEC s_GetComponentProductionTime @StartTime, @EndTime, @MachineID, @ComponentID, @OperatorID
UPDATE #productiondata SET #productiondata.productiontime = isnull(#time.ttime,0)
FROM #productiondata INNER JOIN #time ON #productiondata.componentid = #time.componentid
DROP TABLE #Time
-- Load Down Time Data
CREATE TABLE #DTime ( tTime float, AvailabilityEfficiencyLoss float, ComponentID nvarchar(50) primary key)
INSERT #DTime (tTime, AvailabilityEfficiencyLoss , ComponentID ) EXEC s_GetComponentDownTime @StartTime, @EndTime, @MachineID, @ComponentID, @OperatorID
UPDATE #ProductionData SET #productiondata.DownTime = isNull(#dtime.tTime,0),
				#productionData.AvailabilityEfficiencyLoss = isnull (#dtime.AvailabilityEfficiencyLoss,0)
FROM #ProductionData INNER JOIN #DTime on #ProductionData.ComponentID = #DTime.ComponentID
DROP TABLE #DTime
-- Calculate Availability Efficiency
UPDATE #ProductionData
SET 	AvailabilityEfficiency = isNull(((ProductionTime - AvailabilityEfficiencyLoss)- (DownTime- AvailabilityEfficiencyLoss))/(ProductionTime - AvailabilityEfficiencyLoss),0)
WHERE	ProductionTime > DownTime
-- Calculate Production Efficiency
UPDATE #ProductionData
SET ProductionEfficiency = CN/(ProductionTime - DownTime)
WHERE CN > 0 and ProductionTime > DownTime
-- Calculate Quality Efficiency
UPDATE #ProductionData
SET QualityEfficiency = (Production - Rejection)/Production
WHERE Production > 0
-- Calculate Overall Efficiency
UPDATE #ProductionData
SET OverAllEfficiency = isNull((AvailabilityEfficiency * ProductionEfficiency * QualityEfficiency),0),
ProductionTime = case when (ProductionTime - DownTime) < 0 then 0 else (productiontime - downtime) end -- (this is for displaying the actual production time only, not used by calculations)
SELECT MachineID,
	OperatorID,
	ComponentID,
	Production,
	Rejection,
	CN,
	TurnOver ,
	convert(nvarchar(6),convert(integer, ProductionTime)/3600) + ':' + convert(nvarchar(2), (convert(integer, ProductionTime)%3600)/60) + ':' + convert(nvarchar(2), convert(integer, ProductionTime)%60)  as ProductionTime,
	convert(nvarchar(6),convert(integer, DownTime)/3600) + ':' + convert(nvarchar(2), (convert(integer, DownTime)%3600)/60) + ':' + convert(nvarchar(2), convert(integer, DownTime)%60)  as DownTime,
	AvailabilityEfficiency*100 as AvailabilityEfficiency ,
	ProductionEfficiency*100 as ProductionEfficiency,
	QualityEfficiency*100 as QualityEfficiency ,
	OverAllEfficiency*100 as OverAllEfficiency ,
	@MachineIDLabel as MachineIDLabel,
	@OperatorIDLabel as OperatorIDLabel,
	@ComponentIDLabel as ComponentIDLabel,
	@StartTime as StartTime,
	@EndTime as EndTime
FROM #productiondata
END
