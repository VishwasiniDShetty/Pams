/****** Object:  Procedure [dbo].[s_GetDailyProductionReport]    Committed by VersionSQL https://www.versionsql.com ******/

/*
 Procedure altered by SSK on 15-July-2006
 To get OEE from this Procedure
*/
CREATE        PROCEDURE [dbo].[s_GetDailyProductionReport]
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
	AvailabilityEfficiency float,
	QualityEfficiency Float,
	AvailEffyLoss float,
	dDate smalldatetime PRIMARY KEY,
	StartTime datetime,
	EndTime datetime,
	MachineIDLabel nvarchar(50),
	OperatorIDLabel nvarchar(50),
	ComponentIDLabel nvarchar(50)
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
select @strsql =''
select @strsql = 'UPDATE #ProductionData SET ProductionTime = isnull(ProductionTime,0) + isnull(t2.totaltime,0) '
select @strsql = @strsql + ' from '
select @strsql = @strsql + '  (SELECT productiondate, sum(datediff(second,workorderproductiondetail.timefrom, '
select @strsql = @strsql + 'workorderproductiondetail.timeto))as totaltime FROM workorderheader  '
select @strsql = @strsql + ' INNER JOIN workorderproductiondetail '
select @strsql = @strsql + ' ON workorderheader.workorderno = workorderproductiondetail.workorderno WHERE '
select @strsql = @strsql + ' (workorderproductiondetail.timefrom>= ''' + convert(nvarchar(20),@StartTime) + ''') AND '
select @strsql = @strsql + ' (workorderproductiondetail.timeto<= ''' + convert(nvarchar(20),@EndTime) + ''')'
select @strsql = @strsql + @strmachine + @strcomponent + @stroperator
select @strsql = @strsql + ' GROUP BY workorderproductiondetail.productiondate ) as t2 inner join #productiondata on t2.productiondate = #productiondata.ddate'
exec (@strsql)
/*
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
*/
-- Type 2
select @strsql =''
select @strsql = 'UPDATE #ProductionData SET ProductionTime = isnull(ProductionTime,0) + isnull(t2.totaltime,0) '
select @strsql = @strsql + ' from '
select @strsql = @strsql + ' (SELECT productiondate, sum(datediff(second,''' + convert(nvarchar(20),@StartTime) + ''''
select @strsql = @strsql + ',workorderproductiondetail.timeto)) as totaltime FROM workorderheader  '
select @strsql = @strsql + ' INNER JOIN workorderproductiondetail '
select @strsql = @strsql + ' ON workorderheader.workorderno = workorderproductiondetail.workorderno WHERE '
select @strsql = @strsql + ' (workorderproductiondetail.timefrom < ''' + convert(nvarchar(20),@StartTime) + ''') AND '
select @strsql = @strsql + ' (workorderproductiondetail.timeto <= ''' + convert(nvarchar(20),@EndTime) + ''') AND '
select @strsql = @strsql + ' (workorderproductiondetail.timeto > ''' + convert(nvarchar(20),@StartTime) + ''')'
select @strsql = @strsql + @strmachine + @strcomponent + @stroperator
select @strsql = @strsql + ' GROUP BY workorderproductiondetail.productiondate)as t2 inner join #productiondata on t2.productiondate = #productiondata.ddate'
exec (@strsql)
/*
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
*/
-- Type 3
SELECT @strsql = ''
select @strsql = 'UPDATE #ProductionData SET ProductionTime = isnull(ProductionTime,0) + isnull(t2.totaltime,0) '
select @strsql = @strsql + ' from '
select @strsql = @strsql + ' (SELECT productiondate, sum(datediff(second,workorderproductiondetail.timefrom,''' + convert(nvarchar(20),@EndTime) + ''''
select @strsql = @strsql + ')) as totaltime FROM workorderheader  '
select @strsql = @strsql + ' INNER JOIN workorderproductiondetail '
select @strsql = @strsql + ' ON workorderheader.workorderno = workorderproductiondetail.workorderno WHERE '
select @strsql = @strsql + ' (workorderproductiondetail.timefrom >= ''' + convert(nvarchar(20),@StartTime) + ''') AND '
select @strsql = @strsql + ' (workorderproductiondetail.timefrom < ''' + convert(nvarchar(20),@EndTime) + ''') AND '
select @strsql = @strsql + ' (workorderproductiondetail.timeto > ''' + convert(nvarchar(20),@EndTime) + ''') '
select @strsql = @strsql + @strmachine + @strcomponent + @stroperator
select @strsql = @strsql + ' GROUP BY workorderproductiondetail.productiondate) as t2 inner join #productiondata on t2.productiondate = #productiondata.ddate'
exec (@strsql)
/*
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
*/
-- Type 4
SELECT @strsql = ''
select @strsql = 'UPDATE #ProductionData SET ProductionTime = isnull(ProductionTime,0) + isnull(t2.totaltime,0)'
select @strsql = @strsql + ' from '
select @strsql = @strsql + ' (SELECT productiondate, sum(datediff(second,''' + convert(nvarchar(20),@StartTime) + '''  ,''' + convert(nvarchar(20),@EndTime) + ''''
select @strsql = @strsql + ')) as totaltime FROM workorderheader  '
select @strsql = @strsql + ' INNER JOIN workorderproductiondetail '
select @strsql = @strsql + ' ON workorderheader.workorderno = workorderproductiondetail.workorderno WHERE '
select @strsql = @strsql + ' (workorderproductiondetail.timefrom < ''' + convert(nvarchar(20),@StartTime) + ''') AND '
select @strsql = @strsql + ' (workorderproductiondetail.timeto > ''' + convert(nvarchar(20),@EndTime) + ''') '
select @strsql = @strsql + @strmachine + @strcomponent + @stroperator
select @strsql = @strsql + ' GROUP BY workorderproductiondetail.productiondate ) as t2 inner join #productiondata on t2.productiondate = #productiondata.ddate'
exec (@strsql)
/*
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
*/
-- DownTime Calculations
--redefine the operator part of the query
if isnull(@operatorid, '') <> ''
	begin
	select @stroperator = ' AND ( workorderdowntimedetail.employeeid = ''' + @operatorid + ''')'
	end
select @strsql = ''
select @strsql = @strsql + 'UPDATE #ProductionData SET DownTime = isnull(DownTime,0) + isnull(t2.totaltime,0)'
select @strsql = @strsql + ' from '
select @strsql = @strsql + ' (SELECT downdate, sum(datediff(second,workorderDownTimedetail.timefrom, workorderDownTimedetail.timeto))'
select @strsql = @strsql + ' as totaltime FROM workorderheader INNER JOIN workorderDownTimedetail ON workorderheader.workorderno = workorderDownTimedetail.workorderno where'
select @strsql = @strsql + ' (workorderDownTimedetail.timefrom>=''' + convert(nvarchar(20),@StartTime) + ''')'
select @strsql = @strsql + ' AND (workorderDownTimedetail.timeto<=''' + convert(nvarchar(20),@EndTime) + ''')'
select @strsql = @strsql + @strmachine + @strcomponent + @stroperator
select @strsql = @strsql + ' GROUP BY workorderdowntimedetail.downdate) as t2 inner join #productiondata on t2.downdate = #productiondata.ddate'
exec (@strsql)

/*
*/
/*
-- Type 1
--Type 2,3,4 calculations are deleted by SSK
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
	
-- Type 3
	
-- Type 4
	
*/
-- Calculate Production Efficiency
	UPDATE #ProductionData
	SET ProductionEfficiency = (CN/(ProductionTime - DownTime)) * 100
	WHERE (CN > 0) AND ( ProductionTime > DownTime)

-- Update the Availability Efficiency Losses
select @strsql = ''
select @strsql = @strsql + ' UPDATE #productiondata SET AvailEffyLoss = isnull(AvailEffyLoss,0) + isnull(t2.totaltime,0)'
select @strsql = @strsql + ' from '
select @strsql = @strsql + ' (SELECT downdate, sum(datediff(second,workorderDownTimedetail.timefrom,  workorderDownTimedetail.timeto))'
select @strsql = @strsql + ' as totaltime FROM workorderheader INNER JOIN workorderDownTimedetail ON workorderheader.workorderno = workorderDownTimedetail.workorderno '
select @strsql = @strsql + ' INNER JOIN downcodeinformation on workorderDownTimedetail.downid = downcodeinformation.downid '
select @strsql = @strsql + ' where (workorderDownTimedetail.timefrom>=''' + convert(nvarchar(20),@StartTime) + ''')'
select @strsql = @strsql + ' AND (workorderDownTimedetail.timeto<=''' + convert(nvarchar(20),@EndTime) + ''') AND (downcodeinformation.availeffy = 1)'
select @strsql = @strsql + @strmachine + @strcomponent + @stroperator
select @strsql = @strsql + ' GROUP BY workorderdowntimedetail.downdate) as t2 inner join #productiondata on t2.downdate = #productiondata.ddate'
exec (@strsql)

-- Calculate Availability Efficiency
UPDATE #ProductionData
SET 	AvailabilityEfficiency = (((ProductionTime - AvailEffyLoss)- (DownTime- AvailEffyLoss))/(ProductionTime - AvailEffyLoss)) * 100
WHERE	ProductionTime > DownTime and ProductionTime  >  AvailEffyLoss

-- Calculate Quality Efficiency

	UPDATE #ProductionData
	SET QualityEfficiency=((production-rejection)/production)*100

SELECT  
	CN ,
	production ,
	rejection ,
	Turnover ,
	ProductionTime ,
	DownTime ,
	ProductionEfficiency ,
	AvailabilityEfficiency ,
	((ProductionEfficiency* QualityEfficiency* AvailabilityEfficiency )/10000)AS OverAllEfficiency,
	AvailEffyLoss ,
	dDate   ,
	StartTime ,
	EndTime ,
	MachineIDLabel ,
	OperatorIDLabel ,
	ComponentIDLabel 
FROM #ProductionData
END
