/****** Object:  Procedure [dbo].[s_TargetVsPerformace_Daily]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE   PROCEDURE [dbo].[s_TargetVsPerformace_Daily]
	@StartDate as datetime,
	@EndDate as datetime,
	@MachineID as nvarchar(50) = '',
	@MachineIDLabel as nvarchar(50) = 'ALL'
AS
BEGIN
declare @strsql nvarchar(4000)
declare @strmachine nvarchar(255)
-- Create temporary table to store the report data
CREATE TABLE #ProductionData (
	dDate datetime,
	ActualTurnOver float,
	ProductionTime float,	
	DownTime float,
	ExpectedTurnOver float,
	TargetTurnOver float,
	MachineHourRate float,
	MachineID nvarchar(50)
	)
select @strsql = ''
select @strmachine = ''
if isnull(@machineid,'') <> ''
	begin
	select @strmachine = ' AND ( workorderheader.machineid = ''' + @MachineID+ ''')'
	end
-- Get the ActualTurnOver
select @strsql = 'INSERT INTO #ProductionData (dDate, ActualTurnOver, ProductionTime, Downtime, Machineid)'
select @strsql = @strsql + ' SELECT  workorderproductiondetail.productiondate, '
select @strsql = @strsql + ' SUM(workorderheader.price * (workorderproductiondetail.production - workorderproductiondetail.rejection)) AS TurnOver,0,0,'
select @strsql = @strsql + ' workorderheader.machineid'
select @strsql = @strsql + ' FROM workorderheader INNER JOIN workorderproductiondetail ON workorderheader.workorderno = workorderproductiondetail.workorderno'
select @strsql = @strsql + ' WHERE (('
select @strsql = @strsql + ' (workorderproductiondetail.timefrom>=''' + convert(nvarchar(20),@StartDate) + ''') AND'
select @strsql = @strsql + ' (workorderproductiondetail.timeto<=''' + convert(nvarchar(20),@EndDate) + ''')'
select @strsql = @strsql + '  ) OR ( '
select @strsql = @strsql + ' (workorderproductiondetail.timefrom<''' + convert(nvarchar(20),@StartDate) + ''') AND'
select @strsql = @strsql + ' (workorderproductiondetail.timeto<=''' + convert(nvarchar(20),@EndDate) + ''') AND'
select @strsql = @strsql + ' (workorderproductiondetail.timeto>''' + convert(nvarchar(20),@StartDate) + ''')))'
select @strsql = @strsql + @strmachine
select @strsql = @strsql + ' GROUP BY workorderheader.machineid, workorderproductiondetail.productiondate'
exec (@strsql)
/*
INSERT INTO #ProductionData (dDate, ActualTurnOver, ProductionTime, DownTime, MachineID)
SELECT     workorderproductiondetail.productiondate,
	   SUM(workorderheader.price * (workorderproductiondetail.production - workorderproductiondetail.rejection)) AS TurnOver, 0,0,
	   workorderheader.machineid
FROM         workorderheader INNER JOIN
workorderproductiondetail ON workorderheader.workorderno = workorderproductiondetail.workorderno
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
GROUP BY workorderheader.machineid, workorderproductiondetail.productiondate
*/
-- Load the production time
-- Type 1
	UPDATE #ProductionData
	SET ProductionTime = ProductionTime +
	isnull(	
		(SELECT sum(datediff(second,workorderproductiondetail.timefrom, workorderproductiondetail.timeto))
		FROM workorderheader
			INNER JOIN workorderproductiondetail
				ON workorderheader.workorderno = workorderproductiondetail.workorderno
		WHERE
			( workorderproductiondetail.productiondate = #ProductionData.dDate)
			AND
			( workorderheader.machineid = #ProductionData.MachineID)
			AND
			(workorderproductiondetail.timefrom>=@StartDate)
			AND
			(workorderproductiondetail.timeto<=@EndDate)
		GROUP BY workorderproductiondetail.productiondate
		), 0)
-- Type 2
	UPDATE #ProductionData
	SET ProductionTime = ProductionTime +
	isnull(	
		(SELECT sum(datediff(second,@StartDate, workorderproductiondetail.timeto))
		FROM workorderheader
			INNER JOIN workorderproductiondetail
				ON workorderheader.workorderno = workorderproductiondetail.workorderno
		WHERE
			( workorderproductiondetail.productiondate = #ProductionData.dDate)
			AND
			( workorderheader.machineid = #ProductionData.MachineID)
			AND
			(workorderproductiondetail.timefrom<@StartDate)
			AND
			(workorderproductiondetail.timeto<=@EndDate)
			AND
			(workorderproductiondetail.timeto>@StartDate)
		GROUP BY workorderproductiondetail.productiondate
		), 0)
-- Type 3
	UPDATE #ProductionData
	SET ProductionTime = ProductionTime +
	isNull(
		(SELECT sum(datediff(second, workorderproductiondetail.timefrom, @EndDate))
		FROM workorderheader
			INNER JOIN workorderproductiondetail
				ON workorderheader.workorderno = workorderproductiondetail.workorderno
		WHERE
			( workorderproductiondetail.productiondate = #ProductionData.dDate)
			AND
			( workorderheader.machineid = #ProductionData.MachineID)
			AND
			(workorderproductiondetail.timefrom>=@StartDate)
			AND
			(workorderproductiondetail.timefrom<@EndDate)
			AND
			(workorderproductiondetail.timeto>@EndDate)
		GROUP BY workorderproductiondetail.productiondate
		), 0)
-- Type 4
	UPDATE #ProductionData
	SET ProductionTime = ProductionTime +
	isNull(
		(SELECT datediff(second, @StartDate, @EndDate)*Count(*)
		FROM workorderheader
			INNER JOIN workorderproductiondetail
				ON workorderheader.workorderno = workorderproductiondetail.workorderno
		WHERE
			( workorderproductiondetail.productiondate = #ProductionData.dDate)
			AND
			( workorderheader.machineid = #ProductionData.MachineID)
			AND 		
			(workorderproductiondetail.timefrom<@StartDate)
			AND
			(workorderproductiondetail.timeto>@EndDate)
		GROUP BY workorderproductiondetail.productiondate
		), 0)
-- Load the down time
UPDATE #ProductionData
SET DownTime =
isNULL (
(
SELECT     SUM(DATEDIFF(second, workorderdowntimedetail.timefrom, workorderdowntimedetail.timeto)) AS DownTime
FROM         workorderheader INNER JOIN
workorderdowntimedetail ON workorderheader.workorderno = workorderdowntimedetail.workorderno
WHERE 	
	( workorderheader.machineid = #ProductionData.MachineID)
	AND
	( workorderdowntimedetail.downdate = #ProductionData.dDate)
GROUP BY workorderdowntimedetail.downdate, workorderheader.machineid
),0)
-- Load Machine Hour Rate
UPDATE #productiondata SET #productiondata.MachineHourRate = isnull(machineinformation.mchrrate,0)
FROM #productiondata INNER JOIN machineinformation ON #productiondata.machineid = machineinformation.machineid
--UPDATE #ProductionData SET MachineHourRate = (SELECT mchrrate FROM machineinformation WHERE machineinformation.MachineID = #ProductionData.MachineID)
-- Calculate Expected Turnover
UPDATE #ProductionData
SET ExpectedTurnOver = (ProductionTime - DownTime) * MachineHourRate / 3600
--SELECT dDate, MachineID , ProductionTime, DownTime  FROM #ProductionData ORDER BY dDate
-- Calculate Target Turnover
UPDATE #ProductionData
SET TargetTurnOver =
isNull(
(
	SELECT     target/
		datediff(day, CONVERT(datetime, LEFT(financialyear, 4) + ' - ' + CONVERT(nvarchar(2), nmonth) + ' - ' + ' 1 ') ,
		CONVERT(datetime, LEFT(financialyear, 4) + ' - ' + CONVERT(nvarchar(2), (nmonth + 1)) + ' - ' + ' 1') )
	FROM         machinetargets
WHERE
	(nmonth = MONTH(#ProductionData.dDate))
	AND (financialyear = CONVERT(nvarchar(4), YEAR(#ProductionData.dDate)) + '-' + CONVERT(nvarchar(4), YEAR(#ProductionData.dDate) + 1))
	AND (machinetargets.machineid = #ProductionData.MachineID)
),0)
CREATE TABLE #FinalData (
	dDate datetime,
	ActualTurnOver float,
	ExpectedTurnOver float,
	TargetTurnOver float,
	)
DECLARE @dDate datetime
SELECT @dDate = @StartDate
WHILE @dDate  < @EndDate
BEGIN
	INSERT INTO #FinalData(dDate, ActualTurnOver, ExpectedTurnOver, TargetTurnOver) VALUES (@dDate, 0,0,0)
	SELECT @dDate = DateAdd(Day, 1, @dDate)
END
UPDATE #FinalData
SET ActualTurnOver =
	isNull((SELECT SUM(#ProductionData.ActualTurnOver)
	FROM #ProductionData
	WHERE  #FinalData.dDate = #ProductionData.dDate
	GROUP BY #ProductionData .dDate),0),
ExpectedTurnOver =
	isNull((SELECT SUM(#ProductionData.ExpectedTurnOver)
	FROM #ProductionData
	WHERE  #FinalData.dDate = #ProductionData.dDate
	GROUP BY #ProductionData .dDate),0),
TargetTurnOver =
	isNull((SELECT SUM(#ProductionData.TargetTurnOver)
	FROM #ProductionData
	WHERE  #FinalData.dDate = #ProductionData.dDate
	GROUP BY #ProductionData .dDate),0)
SELECT dDate,
	TargetTurnOver ,
	ExpectedTurnOver ,
	 ActualTurnOver
FROM #FinalData
END
