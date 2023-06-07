/****** Object:  Procedure [dbo].[s_TargetVsPerformace_DailyCumulative]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE  PROCEDURE [dbo].[s_TargetVsPerformace_DailyCumulative]
	@StartDate as datetime,
	@EndDate as datetime,
	@MachineID as nvarchar(50) = '',
	@MachineIDLabel as nvarchar(50) = 'ALL'
AS
BEGIN
-- Create temporary table to store the report data
CREATE TABLE #CumulativeData (
	dDate datetime,
	ActualTurnOver float,
	ExpectedTurnOver float,
	TargetTurnOver float,
	CumulativeActualTurnOver float,
	CumulativeExpectedTurnOver float,
	CumulativeTargetTurnOver float
	)
-- Get The Daily Data
INSERT INTO #CumulativeData (dDate, TargetTurnOver, ExpectedTurnOver, ActualTurnOver)
EXEC s_TargetVsPerformace_Daily @StartDate, @EndDate, @MachineID, @MachineIDLabel
-- Set all the cumulative data = 0
UPDATE #CumulativeData
SET 	CumulativeActualTurnOver =0,
	CumulativeExpectedTurnOver =0,
	CumulativeTargetTurnOver =0
-- Insert for the first date
UPDATE #CumulativeData
SET 	CumulativeActualTurnOver =ActualTurnOver,
	CumulativeExpectedTurnOver = ExpectedTurnOver,
	CumulativeTargetTurnOver =TargetTurnOver
WHERE #CumulativeData.dDate = @StartDate
UPDATE #CumulativeData
SET
	CumulativeTargetTurnOver = (SELECT SUM(TargetTurnOver) FROM #CumulativeData as CD WHERE CD.dDate <= #CumulativeData.dDate),
	CumulativeExpectedTurnOver = ExpectedTurnOver + (SELECT SUM(ExpectedTurnOver) FROM #CumulativeData as CD WHERE CD.dDate < #CumulativeData.dDate),
	CumulativeActualTurnOver = ActualTurnOver + (SELECT SUM(ActualTurnOver) FROM #CumulativeData as CD WHERE CD.dDate < #CumulativeData.dDate)
WHERE #CumulativeData.dDate > @StartDate
SELECT  dDate as Date,
	ActualTurnOver ,
	ExpectedTurnOver ,
	TargetTurnOver ,
	CumulativeTargetTurnOver as CTargetTurnOver,
	CumulativeActualTurnOver as CActualTurnOver,
	CumulativeExpectedTurnOver as CExpectedTurnOver
FROM #CumulativeData
END
