/****** Object:  Procedure [dbo].[Test_using_single_table]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE     PROCEDURE [dbo].[Test_using_single_table]
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

-- Load the production details into the table
EXEC s_GetComponentProductionData @StartTime, @EndTime, @MachineID, @ComponentID, @OperatorID

-- Load Production Time Data
EXEC s_GetComponentProductionTime @StartTime, @EndTime, @MachineID, @ComponentID, @OperatorID

/*
-- Load Down Time Data
INSERT #DTime (tTime, AvailabilityEfficiencyLoss , ComponentID ) EXEC s_GetComponentDownTime @StartTime, @EndTime, @MachineID, @ComponentID, @OperatorID
*/
select * FROM #productiondata
drop table #productiondata
END
