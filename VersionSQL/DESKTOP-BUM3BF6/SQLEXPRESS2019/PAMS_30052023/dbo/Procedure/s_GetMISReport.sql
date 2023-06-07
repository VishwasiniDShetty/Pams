/****** Object:  Procedure [dbo].[s_GetMISReport]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE       PROCEDURE [dbo].[s_GetMISReport]
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
	MachineID nvarchar(50) PRIMARY KEY,
	OperatorID nvarchar(50),
	ComponentID nvarchar(50),
	Production float,
	Rejection float,
	CN float,
	TurnOver float,
	ProductionTime float,
	DownTime float,
	ExpectedTurnOver float,
	AvailabilityEfficiency float,
	ProductionEfficiency float,
	TurnoverEfficiency float,
	QualityEfficiency float,
	OverAllEfficiency float,
	MachineRatePerHour  float,
	MachineRatePerUtilisedHour  float,
	MachineHourRate float,	
	AvailabilityEfficiencyLoss float,
	ReturnPerMachineHourLoss float
	)

-- Temporary Table For Loading the Production Time 
CREATE TABLE #PTime ( MachineID nvarchar(50) PRIMARY KEY, tTime float)

--Temporary Table For Loading the Down Time
CREATE TABLE #DTime ( MachineID nvarchar(50) PRIMARY KEY, tTime float, AvailabilityEfficiencyLoss float, ReturnPerMachineHourLoss float)

-- Load the production details into the table
INSERT #ProductionData (MachineID, Production, Rejection, CN, TurnOver)
EXEC s_GetMachineProductionData @StartTime, @EndTime, @MachineID, @ComponentID, @OperatorID

--Get the machine hour rate
UPDATE #ProductionData SET #productiondata.MachineHourRate = isnull(machineinformation.mchrrate,0)
FROM #productiondata INNER JOIN machineinformation ON #ProductionData.MachineID = Machineinformation.machineid

-- Load Production Time Data
INSERT #PTime (MachineID, ttime ) EXEC s_GetMachineProductionTime @StartTime, @EndTime, @MachineID, @ComponentID, @OperatorID
UPDATE #productiondata SET #productiondata.productiontime = isnull(#ptime.ttime,0)
FROM #productiondata INNER JOIN #Ptime ON #productiondata.machineid = #ptime.machineid
DROP TABLE #PTime

-- Load Down Time Data
INSERT #DTime (machineid, tTime, AvailabilityEfficiencyLoss , ReturnPerMachineHourLoss) EXEC s_GetMachineDownTime @StartTime, @EndTime, @MachineID, @ComponentID, @OperatorID
UPDATE #ProductionData SET #productiondata.DownTime = isNull(#dtime.tTime,0),
				#productionData.AvailabilityEfficiencyLoss = isnull(#dtime.AvailabilityEfficiencyLoss,0),
				#productiondata.ReturnPerMachineHourLoss = isnull(#dtime.ReturnPerMachineHourLoss,0)
FROM #ProductionData INNER JOIN #DTime on #ProductionData.machineID = #DTime.machineID
DROP TABLE #DTime

-- Calculate Availability Efficiency
UPDATE #ProductionData
SET 	AvailabilityEfficiency = ((ProductionTime - AvailabilityEfficiencyLoss)- (DownTime- AvailabilityEfficiencyLoss))/(ProductionTime - AvailabilityEfficiencyLoss)
WHERE	ProductionTime > DownTime

-- Calculate Production Efficiency, ETO and Turnover effy
UPDATE #ProductionData
SET ProductionEfficiency = CN/(ProductionTime - DownTime),
ExpectedTurnOver = (ProductionTime - DownTime) * MachineHourRate / 3600
WHERE CN > 0 and ProductionTime > Downtime

-- Calculate TurnOver Efficiency
UPDATE #ProductionData
SET TurnOverEfficiency = TurnOver/ExpectedTurnOver
WHERE  ExpectedTurnOver > 0

-- Calculate Quality Efficiency
UPDATE #ProductionData
SET QualityEfficiency = (Production - Rejection)/Production
WHERE Production > 0

-- Calculate Overall Efficiency
UPDATE #ProductionData
SET OverAllEfficiency = AvailabilityEfficiency * ProductionEfficiency * QualityEfficiency

-- Calculate MachineRatePerHour
UPDATE #ProductionData
SET MachineRatePerHour = TurnOver/((ProductionTime- ReturnPerMachineHourLoss)/3600)
WHERE (TurnOver > 0) AND ( ProductionTime > 0)

-- Calculate Machine Rate Per utilized Hour
UPDATE #ProductionData
SET MachineRatePerUtilisedHour = TurnOver/((ProductionTime - DownTime)/3600)
WHERE (TurnOver > 0) AND ( (ProductionTime - DownTime) > 0)

--Select MachineID, Op ID...
SELECT MachineID,
	OperatorID,
	ComponentID,
	Production,
	Rejection,
	CN,
	TurnOver ,
	convert(nvarchar(6),convert(integer, ProductionTime)/3600) + ':' + convert(nvarchar(2), (convert(integer, ProductionTime)%3600)/60) + ':' + convert(nvarchar(2), convert(integer, ProductionTime)%60)  as ProductionTime,
	convert(nvarchar(6),convert(integer, DownTime)/3600) + ':' + convert(nvarchar(2), (convert(integer, DownTime)%3600)/60) + ':' + convert(nvarchar(2), convert(integer, DownTime)%60)  as DownTime,
	ExpectedTurnOver ,
	AvailabilityEfficiency*100 as AvailabilityEfficiency ,
	ProductionEfficiency*100 as ProductionEfficiency,
	TurnoverEfficiency*100 as TurnoverEfficiency,
	QualityEfficiency*100 as QualityEfficiency ,
	OverAllEfficiency*100 as OverAllEfficiency ,
	MachineRatePerHour ,
	MachineRatePerUtilisedHour  ,
	MachineHourRate,
	ProductionTime as sProductionTime,
	DownTime as sDownTime,
	AvailabilityEfficiencyLoss
FROM #productiondata
END
