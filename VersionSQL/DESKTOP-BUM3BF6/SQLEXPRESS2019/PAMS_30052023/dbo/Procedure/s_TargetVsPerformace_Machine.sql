/****** Object:  Procedure [dbo].[s_TargetVsPerformace_Machine]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE       PROCEDURE [dbo].[s_TargetVsPerformace_Machine]
	@StartDate as datetime,
	@EndDate as datetime,
	@MachineID as nvarchar(50) = '',
	@MachineIDLabel as nvarchar(50) = 'ALL'
AS
BEGIN
declare @strsql nvarchar(2000)
declare @strmachine nvarchar(255)
-- Create temporary table to store the report data
CREATE TABLE #ProductionData (
	MachineID nvarchar(50),
	ActualTurnOver float,
	ProductionTime float,	
	DownTime float,
	ExpectedTurnOver float,
	TargetTurnOver float,
	MachineHourRate float
	)
select @strsql = ''
select @strmachine = ''
if isnull(@machineid,'') <> ''
	begin
	select @strmachine = ' AND ( workorderheader.machineid = ''' + @MachineID+ ''')'
	end
select @strsql = 'INSERT INTO #ProductionData (MachineID, ActualTurnOver, TargetTurnover)'
select @strsql = @strsql + ' SELECT  workorderheader.MachineID, '
select @strsql = @strsql + ' SUM(workorderheader.price * (workorderproductiondetail.production - workorderproductiondetail.rejection)) AS TurnOver,0'
select @strsql = @strsql + ' FROM workorderheader INNER JOIN workorderproductiondetail ON
workorderheader.workorderno = workorderproductiondetail.workorderno'
select @strsql = @strsql + ' WHERE (('
select @strsql = @strsql + ' (workorderproductiondetail.timefrom>=''' + convert(nvarchar(20),@StartDate) + ''') AND'
select @strsql = @strsql + ' (workorderproductiondetail.timeto<=''' + convert(nvarchar(20),@EndDate) + ''')'
select @strsql = @strsql + '  ) OR ( '
select @strsql = @strsql + ' (workorderproductiondetail.timefrom<''' + convert(nvarchar(20),@StartDate) + ''') AND'
select @strsql = @strsql + ' (workorderproductiondetail.timeto<=''' + convert(nvarchar(20),@EndDate) + ''') AND'
select @strsql = @strsql + ' (workorderproductiondetail.timeto>''' + convert(nvarchar(20),@StartDate) + ''')))'
select @strsql = @strsql + @strmachine
select @strsql = @strsql + ' GROUP BY workorderheader.MachineID'
exec (@strsql)
/*
INSERT INTO #ProductionData (MachineID, ActualTurnOver, TargetTurnOver)
SELECT  workorderheader.machineid,
	SUM(workorderheader.price * (workorderproductiondetail.production - workorderproductiondetail.rejection)) AS TurnOver, 0
FROM         workorderheader
	     INNER JOIN workorderproductiondetail ON
			workorderheader.workorderno = workorderproductiondetail.workorderno
WHERE 	
	( workorderheader.machineid LIKE '%'+@MachineID+'%')
	AND
	((
		(workorderproductiondetail.timefrom>=@StartDate)
		AND
		(workorderproductiondetail.timeto<=@EndDate)
	)
	OR 	
	(
		(workorderproductiondetail.timefrom<@StartDate)
		AND
		(workorderproductiondetail.timeto<= @EndDate)
		AND
		(workorderproductiondetail.timeto>@StartDate)
	))
GROUP BY workorderheader.MachineID
*/
-- Temporary Table For Loading the Production Data
CREATE TABLE #Time ( tTime float, MachineID nvarchar(50))
-- Load Production Time Data
INSERT #Time (MachineID, tTime ) EXEC s_GetMachineProductionTime @StartDate, @EndDate, @MachineID, '', ''
-- Update Total time
UPDATE #productiondata SET #productiondata.productiontime = isnull(#time.ttime,0)
FROM #productiondata INNER JOIN #time ON #productiondata.machineid = #time.machineid
--UPDATE #ProductionData SET ProductionTime = (SELECT tTime FROM #Time WHERE #Time.MachineID = #ProductionData.MachineID)
DROP TABLE  #Time
-- Temporary Table For Loading Down Time Data
CREATE TABLE #DTime ( tTime float,  AvailEffyLoss float, ReturnPerMachineHourLoss float, MachineID nvarchar(50))
-- Load Down Time Data
INSERT #DTime (MachineID, Availeffyloss, ReturnPerMachineHourLoss,tTime) EXEC s_GetMachineDownTime @StartDate, @EndDate, @MachineID,  '', ''
-- Update Down Time
UPDATE #productiondata SET #productiondata.DownTime = isnull(#Dtime.ttime,0)
FROM #productiondata INNER JOIN #Dtime ON #productiondata.machineid = #Dtime.machineid
--UPDATE #ProductionData SET DownTime = (SELECT tTime FROM #DTime WHERE #DTime.MachineID = #ProductionData.MachineID)
DROP TABLE #DTime
-- Load Machine Hour Rate
UPDATE #productiondata SET #productiondata.MachineHourRate = isnull(machineinformation.mchrrate,0)
FROM #productiondata INNER JOIN machineinformation ON #productiondata.machineid = machineinformation.machineid
--UPDATE #ProductionData SET MachineHourRate = (SELECT mchrrate FROM machineinformation WHERE machineinformation.MachineID = #ProductionData.MachineID)
-- Calculate Expected Turnover
UPDATE #ProductionData
SET ExpectedTurnOver = (ProductionTime - DownTime) * MachineHourRate / 3600
-- Calculate Target Turnover
DECLARE @Date as datetime
SELECT @Date = @StartDate
WHILE @Date <= @EndDate
begin
if month(@date) <= 3
begin
	UPDATE #ProductionData
	SET TargetTurnOver = TargetTurnOver + 	
	isNull(
	(SELECT     target/
		datediff(day, CONVERT(datetime, LEFT(financialyear, 4) + ' - ' + CONVERT(nvarchar(2), nmonth) + ' - ' + ' 1 ') ,
		CONVERT(datetime, LEFT(financialyear, 4) + ' - ' + CONVERT(nvarchar(2), (nmonth + 1)) + ' - ' + ' 1') )
	FROM         machinetargets
	WHERE     (nmonth = MONTH(@Date))
	AND (financialyear = CONVERT(nvarchar(4), YEAR(@Date) - 1) + '-' + CONVERT(nvarchar(4), YEAR(@Date)))
	AND (machinetargets.machineid = #ProductionData.MachineID)
	),0)
end
else if month(@date) = 12
begin
	UPDATE #ProductionData
	SET TargetTurnOver = TargetTurnOver + 	
	isNull(
	(SELECT     target/
		datediff(day, CONVERT(datetime, LEFT(financialyear, 4) + ' - ' + CONVERT(nvarchar(2), nmonth) + ' - ' + ' 1 ') ,
		CONVERT(datetime, convert(nvarchar(4),convert(int,LEFT(financialyear, 4))+ 1) + ' - ' + CONVERT(nvarchar(2), 1) + ' - ' + '1'))
	FROM         machinetargets
	WHERE     (nmonth = MONTH(@Date))
	AND (financialyear = CONVERT(nvarchar(4), YEAR(@Date)) + '-' + CONVERT(nvarchar(4), YEAR(@Date) + 1))
	AND (machinetargets.machineid = #ProductionData.MachineID)
	),0)
end
else
begin
	UPDATE #ProductionData
	SET TargetTurnOver = TargetTurnOver + 	
	isNull(
	(SELECT     target/
		datediff(day, CONVERT(datetime, LEFT(financialyear, 4) + ' - ' + CONVERT(nvarchar(2), nmonth) + ' - ' + ' 1 ') ,
		CONVERT(datetime, LEFT(financialyear, 4) + ' - ' + CONVERT(nvarchar(2), (nmonth + 1)) + ' - ' + ' 1') )
	FROM         machinetargets
	WHERE     (nmonth = MONTH(@Date))
	AND (financialyear = CONVERT(nvarchar(4), YEAR(@Date)) + '-' + CONVERT(nvarchar(4), YEAR(@Date) + 1))
	AND (machinetargets.machineid = #ProductionData.MachineID)
	),0)
end
	SELECT @Date = dateadd(day, 1, @Date)
END
SELECT MachineID, ProductionTime, DownTime, TargetTurnOver, ExpectedTurnOver, ActualTurnOver, @MachineIDLabel as MachineIDLabel, @StartDate as StartDate, @EndDate as EndDate FROM #ProductionData ORDER BY  MachineID
END
