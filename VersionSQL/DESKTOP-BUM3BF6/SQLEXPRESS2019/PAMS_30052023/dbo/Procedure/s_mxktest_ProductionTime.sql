/****** Object:  Procedure [dbo].[s_mxktest_ProductionTime]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE           PROCEDURE [dbo].[s_mxktest_ProductionTime]
	@StartTime as DateTime ,
	@EndTime as DateTime, 
	@MachineID as nvarchar(50) = '',
	@ComponentID nvarchar(50) = '',
	@OperatorID nvarchar(50) = ''
AS
BEGIN
declare @strsql nvarchar(2000)
declare @strMachine nvarchar(255)
declare @strOperator nvarchar(255)
declare @strcomponent nvarchar(255)

CREATE TABLE #ProductionTime( ProductionTime float, pComponentID nvarchar(50) PRIMARY KEY)

INSERT INTO #ProductionTime(pComponentID, ProductionTime)
SELECT DISTINCT ComponentID,0
FROM workorderheader
		INNER JOIN workorderproductiondetail
		ON workorderheader.workorderno = workorderproductiondetail.workorderno
WHERE
	(
		(workorderproductiondetail.timefrom >=@StartTime)
		AND (workorderproductiondetail.timeto <= @EndTime)
	)
OR
	(
		(workorderproductiondetail.timefrom < @StartTime)
		AND (workorderproductiondetail.timeto > @StartTime)
		AND (workorderproductiondetail.timeto <= @EndTime)
	)
OR
	(
		(workorderproductiondetail.timefrom >= @StartTime)
		AND (workorderproductiondetail.timefrom < @EndTime)
		AND (workorderproductiondetail.timeto > @EndTime)
	)
OR
	(
		(workorderproductiondetail.timefrom < @StartTime)
		AND
		(workorderproductiondetail.timeto > @EndTime)
	)
-- set machine and operator filters where required
select @strmachine = ''
select @stroperator = ''
select @strcomponent = ''
if isnull(@machineid, '') <> ''
	begin
	select @strmachine =  ' and ( workorderheader.machineid = ''' + @machineid + ''')'
	end
if isnull(@componentid, '') <> ''
	begin
	select @strcomponent =  ' and ( workorderheader.componentid = ''' + @componentid + ''')'
	end
if isnull(@operatorid,'')  <> ''
	BEGIN
	select @stroperator = ' and ( workorderproductiondetail.employeeid = ''' + @OperatorID +''')'
	END
select @strsql =''
-- Type 1 - Sum of all records within the given time period
select @strsql = 'UPDATE #ProductionTime SET ProductionTime = ProductionTime +  '
select @strsql = @strsql + ' isnull( (SELECT sum(datediff(second,workorderproductiondetail.timefrom, '
select @strsql = @strsql + 'workorderproductiondetail.timeto)) FROM workorderheader  '
select @strsql = @strsql + ' INNER JOIN workorderproductiondetail '
select @strsql = @strsql + ' ON workorderheader.workorderno = workorderproductiondetail.workorderno WHERE '
select @strsql = @strsql + ' (workorderproductiondetail.timefrom>= ''' + convert(nvarchar(20),@StartTime) + ''') AND '
select @strsql = @strsql + ' (workorderproductiondetail.timeto<= ''' + convert(nvarchar(20),@EndTime) + ''') AND '
select @strsql = @strsql + ' ( workorderheader.componentid  = pComponentID ) '
select @strsql = @strsql + @strmachine + @strcomponent + @stroperator
select @strsql = @strsql + ' GROUP BY workorderheader.ComponentID ),0)'
exec (@strsql)
--SELECT top 54 pcomponentID, productiontime FROM #ProductionTime
--drop table #productiontime
--return
-- Type 2
select @strsql =''
select @strsql = 'UPDATE #ProductionTime SET ProductionTime = ProductionTime +  '
select @strsql = @strsql + ' isnull((SELECT sum(datediff(second,''' + convert(nvarchar(20),@StartTime) + ''''
select @strsql = @strsql + ',workorderproductiondetail.timeto)) FROM workorderheader  '
select @strsql = @strsql + ' INNER JOIN workorderproductiondetail '
select @strsql = @strsql + ' ON workorderheader.workorderno = workorderproductiondetail.workorderno WHERE '
select @strsql = @strsql + ' (workorderproductiondetail.timefrom < ''' + convert(nvarchar(20),@StartTime) + ''') AND '
select @strsql = @strsql + ' (workorderproductiondetail.timeto <= ''' + convert(nvarchar(20),@EndTime) + ''') AND '
select @strsql = @strsql + ' (workorderproductiondetail.timeto > ''' + convert(nvarchar(20),@StartTime) + ''') AND '
select @strsql = @strsql + ' (workorderheader.componentid  = pComponentID ) '
select @strsql = @strsql + @strmachine + @strcomponent + @stroperator
select @strsql = @strsql + ' GROUP BY workorderheader.ComponentID ),0)'
exec (@strsql)

-- Type 3
SELECT @strsql = ''
select @strsql = 'UPDATE #ProductionTime SET ProductionTime = ProductionTime +  '
select @strsql = @strsql + ' isnull( (SELECT sum(datediff(second,workorderproductiondetail.timefrom,''' + convert(nvarchar(20),@EndTime) + ''''
select @strsql = @strsql + ')) FROM workorderheader  '
select @strsql = @strsql + ' INNER JOIN workorderproductiondetail '
select @strsql = @strsql + ' ON workorderheader.workorderno = workorderproductiondetail.workorderno WHERE '
select @strsql = @strsql + ' (workorderproductiondetail.timefrom >= ''' + convert(nvarchar(20),@StartTime) + ''') AND '
select @strsql = @strsql + ' (workorderproductiondetail.timefrom < ''' + convert(nvarchar(20),@EndTime) + ''') AND '
select @strsql = @strsql + ' (workorderproductiondetail.timeto > ''' + convert(nvarchar(20),@EndTime) + ''') AND '
select @strsql = @strsql + ' ( workorderheader.componentid  = pComponentID ) '
select @strsql = @strsql + @strmachine + @strcomponent + @stroperator
select @strsql = @strsql + ' GROUP BY workorderheader.ComponentID ),0)'
exec (@strsql)
-- Type 4
SELECT @strsql = ''
select @strsql = 'UPDATE #ProductionTime SET ProductionTime = ProductionTime +  '
select @strsql = @strsql + ' isnull( (SELECT sum(datediff(second,''' + convert(nvarchar(20),@StartTime) + '''  ,''' + convert(nvarchar(20),@EndTime) + ''''
select @strsql = @strsql + ')) FROM workorderheader  '
select @strsql = @strsql + ' INNER JOIN workorderproductiondetail '
select @strsql = @strsql + ' ON workorderheader.workorderno = workorderproductiondetail.workorderno WHERE '
select @strsql = @strsql + ' (workorderproductiondetail.timefrom < ''' + convert(nvarchar(20),@StartTime) + ''') AND '
select @strsql = @strsql + ' (workorderproductiondetail.timeto > ''' + convert(nvarchar(20),@EndTime) + ''') AND '
select @strsql = @strsql + ' ( workorderheader.componentid  = pComponentID ) '
select @strsql = @strsql + @strmachine + @strcomponent + @stroperator
select @strsql = @strsql + ' GROUP BY workorderheader.ComponentID ),0)'
exec (@strsql)

SELECT pcomponentID, productiontime FROM #ProductionTime
drop table #productiontime

END
