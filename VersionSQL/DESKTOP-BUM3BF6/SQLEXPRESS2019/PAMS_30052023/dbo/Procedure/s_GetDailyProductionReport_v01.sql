/****** Object:  Procedure [dbo].[s_GetDailyProductionReport_v01]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE  PROCEDURE [dbo].[s_GetDailyProductionReport_v01]
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
declare @strsql nvarchar(2000)
declare @strmachine nvarchar(255)
declare @stroperator nvarchar(255)
declare @strcomponent nvarchar(255)
-- Create temporary table to store the report data
CREATE TABLE #ProductionData ( 	
	CN float,
	production float,
	rejection float,
	Turnover float,
	ProductionTime float,
	DownTime float,
	ProductionEfficiency float,	
	dDate smalldatetime,
	StartTime datetime,
	EndTime datetime,
	MachineIDLabel nvarchar(50),
	OperatorIDLabel nvarchar(50),
	ComponentIDLabel nvarchar(50),
	)
-- Load the Production, Rejection, CN and Turnover from Work Order Production Details
select @strsql = ''
select @strmachine = ''
select @strcomponent = ''
select @stroperator = ''
if isnull(@machineid,'') <> ''
	begin
	select @strmachine = ' AND ( workorderheader.machineid = ''' + @MachineID+ ''')'
	end
if isnull(@componentid, '') <> ''
	begin
	select @strcomponent = ' AND ( workorderheader.componentid = ''' + @ComponentID+ ''')'
	end
if isnull(@operatorid, '') <> ''
	begin
	select @stroperator = ' AND ( workorderproductiondetail.employeeid = ''' + @operatorid + ''')'
	end
--get CN by date
select @strsql = 'INSERT INTO #ProductionData (dDate, production, rejection, CN, TurnOver, ProductionTime, DownTime)'
select @strsql = @strsql + ' SELECT  workorderproductiondetail.productiondate, SUM(workorderproductiondetail.production) AS Production, '
select @strsql = @strsql + ' ISNULL(SUM(workorderproductiondetail.rejection), 0) AS Rejection, '
select @strsql = @strsql + ' SUM(workorderheader.cycletime * workorderproductiondetail.production) AS CN, '
select @strsql = @strsql + ' SUM(workorderheader.price * (workorderproductiondetail.production -
workorderproductiondetail.rejection)) AS TurnOver,0,0'
select @strsql = @strsql + ' FROM workorderheader INNER JOIN workorderproductiondetail ON workorderheader.workorderno =
workorderproductiondetail.workorderno'
select @strsql = @strsql + ' WHERE (('
select @strsql = @strsql + ' (workorderproductiondetail.timefrom>=''' + convert(nvarchar(20),@StartTime) + ''') AND'
select @strsql = @strsql + ' (workorderproductiondetail.timeto<=''' + convert(nvarchar(20),@EndTime) + ''')'
select @strsql = @strsql + '  ) OR ( '
select @strsql = @strsql + ' (workorderproductiondetail.timefrom<''' + convert(nvarchar(20),@StartTime) + ''') AND'
select @strsql = @strsql + ' (workorderproductiondetail.timeto<=''' + convert(nvarchar(20),@EndTime) + ''') AND'
select @strsql = @strsql + ' (workorderproductiondetail.timeto>''' + convert(nvarchar(20),@StartTime) + ''')))'
select @strsql = @strsql + @strmachine + @stroperator + @strcomponent
select @strsql = @strsql + ' GROUP BY workorderproductiondetail.productiondate'
exec (@strsql)
/*
	INSERT INTO #ProductionData (dDate, CN, ProductionTime, DownTime)
	SELECT     workorderproductiondetail.productiondate,
		   SUM(workorderheader.cycletime * workorderproductiondetail.production) AS CN, 0,0 		
	  FROM      workorderheader INNER JOIN
	            workorderproductiondetail ON workorderheader.workorderno = 				            workorderproductiondetail.workorderno
	 WHERE     (workorderproductiondetail.timefrom >= @StartTime)
AND (workorderproductiondetail.timeto <= @EndTime) OR
	                      (workorderproductiondetail.timefrom < @StartTime) AND (workorderproductiondetail.timeto <= @EndTime) AND
	                      (workorderproductiondetail.timeto > @StartTime)
	GROUP BY workorderproductiondetail.productiondate
*/
	UPDATE #ProductionData
	SET 		
		StartTime = @StartTime,
		EndTime = @EndTime,
		MachineIDLabel = @MachineIDLabel,
		OperatorIDLabel = @OperatorIDLabel,
		ComponentIDLabel = @ComponentIDLabel
-- Get Production Time
-- Type 1 - Sum of all records within the given time period
select @strsql = 'UPDATE #ProductionData SET ProductionTime = ProductionTime +  '
select @strsql = @strsql + ' isnull( (SELECT sum(datediff(second,workorderproductiondetail.timefrom, '
select @strsql = @strsql + 'workorderproductiondetail.timeto)) FROM workorderheader  '
select @strsql = @strsql + ' INNER JOIN workorderproductiondetail '
select @strsql = @strsql + ' ON workorderheader.workorderno = workorderproductiondetail.workorderno WHERE '
select @strsql = @strsql + ' (workorderproductiondetail.timefrom>= ''' + convert(nvarchar(20),@StartTime) + ''') AND '
select @strsql = @strsql + ' (workorderproductiondetail.timeto<= ''' + convert(nvarchar(20),@EndTime) + ''') AND '
select @strsql = @strsql + ' ( workorderproductiondetail.productiondate = #ProductionData.dDate ) '
select @strsql = @strsql + @strmachine + @strcomponent + @stroperator
select @strsql = @strsql + ' GROUP BY workorderproductiondetail.productiondate ),0)'
exec (@strsql)
/*
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
			(workorderproductiondetail.timefrom>=@StartTime)
			AND
			(workorderproductiondetail.timeto<=@EndTime)
		GROUP BY workorderproductiondetail.productiondate
		), 0)
*/
-- Type 2
select @strsql =''
select @strsql = 'UPDATE #ProductionData SET ProductionTime = ProductionTime +  '
select @strsql = @strsql + ' isnull((SELECT sum(datediff(second,''' + convert(nvarchar(20),@StartTime) + ''''
select @strsql = @strsql + ',workorderproductiondetail.timeto)) FROM workorderheader  '
select @strsql = @strsql + ' INNER JOIN workorderproductiondetail '
select @strsql = @strsql + ' ON workorderheader.workorderno = workorderproductiondetail.workorderno WHERE '
select @strsql = @strsql + ' (workorderproductiondetail.timefrom < ''' + convert(nvarchar(20),@StartTime) + ''') AND '
select @strsql = @strsql + ' (workorderproductiondetail.timeto <= ''' + convert(nvarchar(20),@EndTime) + ''') AND '
select @strsql = @strsql + ' (workorderproductiondetail.timeto > ''' + convert(nvarchar(20),@StartTime) + ''') AND '
select @strsql = @strsql + ' (workorderproductiondetail.productiondate = #ProductionData.dDate ) '
select @strsql = @strsql + @strmachine + @strcomponent + @stroperator
select @strsql = @strsql + ' GROUP BY workorderproductiondetail.productiondate
),0)'
exec (@strsql)
/*
-- Type 2
	UPDATE #ProductionData
	SET ProductionTime = ProductionTime +
	isnull(	
		(SELECT sum(datediff(second,@StartTime, workorderproductiondetail.timeto))
		FROM workorderheader
			INNER JOIN workorderproductiondetail
				ON workorderheader.workorderno = workorderproductiondetail.workorderno
		WHERE
			( workorderproductiondetail.productiondate = #ProductionData.dDate)
			AND
			(workorderproductiondetail.timefrom<@StartTime)
			AND
			(workorderproductiondetail.timeto<=@EndTime)
			AND
			(workorderproductiondetail.timeto>@StartTime)
		GROUP BY workorderproductiondetail.productiondate
		), 0)
*/
-- Type 3
SELECT @strsql = ''
select @strsql = 'UPDATE #ProductionData SET ProductionTime = ProductionTime +  '
select @strsql = @strsql + ' isnull( (SELECT sum(datediff(second,workorderproductiondetail.timefrom,''' +
convert(nvarchar(20),@EndTime) + ''''
select @strsql = @strsql + ')) FROM workorderheader  '
select @strsql = @strsql + ' INNER JOIN workorderproductiondetail '
select @strsql = @strsql + ' ON workorderheader.workorderno = workorderproductiondetail.workorderno WHERE '
select @strsql = @strsql + ' (workorderproductiondetail.timefrom >= ''' + convert(nvarchar(20),@StartTime) + ''') AND '
select @strsql = @strsql + ' (workorderproductiondetail.timefrom < ''' + convert(nvarchar(20),@EndTime) + ''') AND '
select @strsql = @strsql + ' (workorderproductiondetail.timeto > ''' + convert(nvarchar(20),@EndTime) + ''') AND '
select @strsql = @strsql + ' ( workorderproductiondetail.productiondate = #ProductionData.dDate ) '
select @strsql = @strsql + @strmachine + @strcomponent + @stroperator
select @strsql = @strsql + ' GROUP BY  workorderproductiondetail.productiondate ),0)'
exec (@strsql)
/*
-- Type 3
	UPDATE #ProductionData
	SET ProductionTime = ProductionTime +
	isNull(
		(SELECT sum(datediff(second, workorderproductiondetail.timefrom, @EndTime))
		FROM workorderheader
			INNER JOIN workorderproductiondetail
				ON workorderheader.workorderno = workorderproductiondetail.workorderno
		WHERE
			( workorderproductiondetail.productiondate = #ProductionData.dDate)
			AND
			(workorderproductiondetail.timefrom>=@StartTime)
			AND
			(workorderproductiondetail.timefrom<@EndTime)
			AND
			(workorderproductiondetail.timeto>@EndTime)
		GROUP BY workorderproductiondetail.productiondate
		), 0)
*/
-- Type 4
SELECT @strsql = ''
select @strsql = 'UPDATE #ProductionData SET ProductionTime = ProductionTime +  '
select @strsql = @strsql + ' isnull( (SELECT sum(datediff(second,''' + convert(nvarchar(20),@StartTime) + '''  ,''' +
convert(nvarchar(20),@EndTime) + ''''
select @strsql = @strsql + ')) FROM workorderheader  '
select @strsql = @strsql + ' INNER JOIN workorderproductiondetail '
select @strsql = @strsql + ' ON workorderheader.workorderno = workorderproductiondetail.workorderno WHERE '
select @strsql = @strsql + ' (workorderproductiondetail.timefrom < ''' + convert(nvarchar(20),@StartTime) + ''') AND '
select @strsql = @strsql + ' (workorderproductiondetail.timeto > ''' + convert(nvarchar(20),@EndTime) + ''') AND '
select @strsql = @strsql + ' ( workorderproductiondetail.productiondate = #ProductionData.dDate ) '
select @strsql = @strsql + @strmachine + @strcomponent + @stroperator
select @strsql = @strsql + ' GROUP BY workorderproductiondetail.productiondate
),0)'
exec (@strsql)
/*
-- Type 4
	UPDATE #ProductionData
	SET ProductionTime = ProductionTime +
	isNull(
		(SELECT datediff(second, @StartTime, @EndTime)*Count(*)
		FROM workorderheader
			INNER JOIN workorderproductiondetail
				ON workorderheader.workorderno = workorderproductiondetail.workorderno
		WHERE
			( workorderproductiondetail.productiondate = #ProductionData.dDate)
			AND 		
			(workorderproductiondetail.timefrom<@StartTime)
			AND
			(workorderproductiondetail.timeto>@EndTime)
		GROUP BY workorderproductiondetail.productiondate
		), 0)
*/
-- DownTime Calculations
--redefine the operator part of the query
if isnull(@operatorid, '') <> ''
	begin
	select @stroperator = ' AND ( workorderdowntimedetail.employeeid = ''' + @operatorid + ''')'
	end
select @strsql =''
select @strsql = @strsql + 'UPDATE #ProductionData SET DownTime = DownTime + '
select @strsql = @strsql + ' isnull((SELECT sum(datediff(second,workorderDownTimedetail.timefrom, workorderDownTimedetail.timeto))'
select @strsql = @strsql + ' FROM workorderheader INNER JOIN workorderDownTimedetail ON workorderheader.workorderno = workorderDownTimedetail.workorderno'
select @strsql = @strsql + ' WHERE ( workorderDownTimedetail.downdate = #ProductionData.dDate) 	AND'
select @strsql = @strsql + ' (workorderDownTimedetail.timefrom>=''' + convert(nvarchar(20),@StartTime) + ''')'
select @strsql = @strsql + ' AND (workorderDownTimedetail.timeto<=''' + convert(nvarchar(20),@EndTime) + ''')'
select @strsql = @strsql + @strmachine + @strcomponent + @stroperator
select @strsql = @strsql + ' GROUP BY workorderDownTimedetail.downdate
),0)'
exec (@strsql)
/*
-- Type 1
	UPDATE #ProductionData
	SET DownTime = DownTime +
	isnull(	
		(SELECT sum(datediff(second,workorderDownTimedetail.timefrom, workorderDownTimedetail.timeto))
		FROM workorderheader
			INNER JOIN workorderDownTimedetail
				ON workorderheader.workorderno = workorderDownTimedetail.workorderno
		WHERE
			( workorderDownTimedetail.downdate = #ProductionData.dDate)
			AND
			(workorderDownTimedetail.timefrom>=@StartTime)
			AND
			(workorderDownTimedetail.timeto<=@EndTime)
		GROUP BY workorderDownTimedetail.downdate
		), 0)
-- Type 2
	UPDATE #ProductionData
	SET DownTime = DownTime +
	isnull(	
		(SELECT sum(datediff(second,@StartTime, workorderDownTimedetail.timeto))
		FROM workorderheader
			INNER JOIN workorderDownTimedetail
				ON workorderheader.workorderno = workorderDownTimedetail.workorderno
		WHERE
			( workorderDownTimedetail.downdate = #ProductionData.dDate)
			AND
			(workorderDownTimedetail.timefrom<@StartTime)
			AND
			(workorderDownTimedetail.timeto<=@EndTime)
			AND
			(workorderDownTimedetail.timeto>@StartTime)
		GROUP BY workorderDownTimedetail.downdate
		), 0)
-- Type 3
	UPDATE #ProductionData
	SET DownTime = DownTime +
	isNull(
		(SELECT sum(datediff(second, workorderDownTimedetail.timefrom, @EndTime))
		FROM workorderheader
			INNER JOIN workorderDownTimedetail
				ON workorderheader.workorderno = workorderDownTimedetail.workorderno
		WHERE
			( workorderDownTimedetail.downdate = #ProductionData.dDate)
			AND
			(workorderDownTimedetail.timefrom>=@StartTime)
			AND
			(workorderDownTimedetail.timefrom<@EndTime)
			AND
			(workorderDownTimedetail.timeto>@EndTime)
		GROUP BY workorderDownTimedetail.downdate
		), 0)
-- Type 4
	UPDATE #ProductionData
	SET DownTime = DownTime +
	isNull(
		(SELECT datediff(second, @StartTime, @EndTime)*Count(*)
		FROM workorderheader
			INNER JOIN workorderDownTimedetail
				ON workorderheader.workorderno = workorderDownTimedetail.workorderno
		WHERE
			( workorderDownTimedetail.downdate = #ProductionData.dDate)
			AND 		
			(workorderDownTimedetail.timefrom<@StartTime)
			AND
			(workorderDownTimedetail.timeto>@EndTime)
		GROUP BY workorderDownTimedetail.downdate
		), 0)
*/
-- Calculate Production Efficiency
	UPDATE #ProductionData
	SET ProductionEfficiency = (CN/(ProductionTime - DownTime)) * 100
	WHERE (CN > 0) AND ( ProductionTime > DownTime)
	SELECT * FROM #ProductionData
END
