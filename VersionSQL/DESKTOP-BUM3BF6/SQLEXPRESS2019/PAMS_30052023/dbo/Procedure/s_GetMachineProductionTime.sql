/****** Object:  Procedure [dbo].[s_GetMachineProductionTime]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE   PROCEDURE [dbo].[s_GetMachineProductionTime]
	@StartTime as DateTime,
	@EndTime as DateTime,
	@MachineID as nvarchar(50) = '',
	@ComponentID nvarchar(50)= '',
	@OperatorID nvarchar(50)= ''
AS
BEGIN
declare @strsql nvarchar(2000)
declare @strMachine nvarchar(255)
declare @strOperator nvarchar(255)
declare @strcomponent nvarchar(255)

CREATE TABLE #ProductionTime ( pMachineID nvarchar(50) PRIMARY KEY, ProductionTime float)
INSERT INTO #ProductionTime(pMachineID, ProductionTime)
SELECT MachineID, 0 FROM MachineInformation

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

-- Type 1 - Sum of all records within the given time period
select @strsql =''
select @strsql = 'UPDATE #ProductionTime SET ProductionTime = isnull(ProductionTime,0) + isnull(t2.totaltime,0) '
select @strsql = @strsql + ' from '
select @strsql = @strsql + '  (SELECT machineid, sum(datediff(second,workorderproductiondetail.timefrom, '
select @strsql = @strsql + 'workorderproductiondetail.timeto))as totaltime FROM workorderheader  '
select @strsql = @strsql + ' INNER JOIN workorderproductiondetail '
select @strsql = @strsql + ' ON workorderheader.workorderno = workorderproductiondetail.workorderno WHERE '
select @strsql = @strsql + ' (workorderproductiondetail.timefrom>= ''' + convert(nvarchar(20),@StartTime) + ''') AND '
select @strsql = @strsql + ' (workorderproductiondetail.timeto<= ''' + convert(nvarchar(20),@EndTime) + ''')'
select @strsql = @strsql + @strmachine + @strcomponent + @stroperator
select @strsql = @strsql + ' GROUP BY workorderheader.machineID ) as t2 inner join #productiontime on t2.machineid = #productiontime.pmachineid'
exec (@strsql)

-- Type 2
select @strsql =''
select @strsql = 'UPDATE #ProductionTime SET ProductionTime = isnull(ProductionTime,0) + isnull(t2.totaltime,0) '
select @strsql = @strsql + ' from '
select @strsql = @strsql + ' (SELECT machineid, sum(datediff(second,''' + convert(nvarchar(20),@StartTime) + ''''
select @strsql = @strsql + ',workorderproductiondetail.timeto)) as totaltime FROM workorderheader  '
select @strsql = @strsql + ' INNER JOIN workorderproductiondetail '
select @strsql = @strsql + ' ON workorderheader.workorderno = workorderproductiondetail.workorderno WHERE '
select @strsql = @strsql + ' (workorderproductiondetail.timefrom < ''' + convert(nvarchar(20),@StartTime) + ''') AND '
select @strsql = @strsql + ' (workorderproductiondetail.timeto <= ''' + convert(nvarchar(20),@EndTime) + ''') AND '
select @strsql = @strsql + ' (workorderproductiondetail.timeto > ''' + convert(nvarchar(20),@StartTime) + ''')'
select @strsql = @strsql + @strmachine + @strcomponent + @stroperator
select @strsql = @strsql + ' GROUP BY workorderheader.machineID )as t2 inner join #productiontime on t2.machineid = #productiontime.pmachineid'
exec (@strsql)

-- Type 3
SELECT @strsql = ''
select @strsql = 'UPDATE #ProductionTime SET ProductionTime = isnull(ProductionTime,0) + isnull(t2.totaltime,0) '
select @strsql = @strsql + ' from '
select @strsql = @strsql + ' (SELECT machineid, sum(datediff(second,workorderproductiondetail.timefrom,''' + convert(nvarchar(20),@EndTime) + ''''
select @strsql = @strsql + ')) as totaltime FROM workorderheader  '
select @strsql = @strsql + ' INNER JOIN workorderproductiondetail '
select @strsql = @strsql + ' ON workorderheader.workorderno = workorderproductiondetail.workorderno WHERE '
select @strsql = @strsql + ' (workorderproductiondetail.timefrom >= ''' + convert(nvarchar(20),@StartTime) + ''') AND '
select @strsql = @strsql + ' (workorderproductiondetail.timefrom < ''' + convert(nvarchar(20),@EndTime) + ''') AND '
select @strsql = @strsql + ' (workorderproductiondetail.timeto > ''' + convert(nvarchar(20),@EndTime) + ''') '
select @strsql = @strsql + @strmachine + @strcomponent + @stroperator
select @strsql = @strsql + ' GROUP BY workorderheader.machineID ) as t2 inner join #productiontime on t2.machineid = #productiontime.pmachineid'
exec (@strsql)

-- Type 4
SELECT @strsql = ''
select @strsql = 'UPDATE #ProductionTime SET ProductionTime = isnull(ProductionTime,0) + isnull(t2.totaltime,0)'
select @strsql = @strsql + ' from '
select @strsql = @strsql + ' (SELECT machineid, sum(datediff(second,''' + convert(nvarchar(20),@StartTime) + '''  ,''' + convert(nvarchar(20),@EndTime) + ''''
select @strsql = @strsql + ')) as totaltime FROM workorderheader  '
select @strsql = @strsql + ' INNER JOIN workorderproductiondetail '
select @strsql = @strsql + ' ON workorderheader.workorderno = workorderproductiondetail.workorderno WHERE '
select @strsql = @strsql + ' (workorderproductiondetail.timefrom < ''' + convert(nvarchar(20),@StartTime) + ''') AND '
select @strsql = @strsql + ' (workorderproductiondetail.timeto > ''' + convert(nvarchar(20),@EndTime) + ''') '
select @strsql = @strsql + @strmachine + @strcomponent + @stroperator
select @strsql = @strsql + ' GROUP BY workorderheader.machineID ) as t2 inner join #productiontime on t2.machineid = #productiontime.pmachineid'
exec (@strsql)

/*
--Type 4
	UPDATE #ProductionTime
	SET ProductionTime = ProductionTime +
	isNull(
		(SELECT datediff(second, @StartTime, @EndTime)*Count(*)
		FROM workorderheader
			INNER JOIN workorderproductiondetail
				ON workorderheader.workorderno = workorderproductiondetail.workorderno
		WHERE
			(workorderheader.machineid LIKE '%'+pMachineID+'%')
			AND
			( workorderheader.componentid LIKE '%'+@ComponentID+'%' )
			AND
			( workorderproductiondetail.employeeid LIKE '%'+@OperatorID+'%' )	
			AND 		
			(workorderproductiondetail.timefrom<@StartTime)
			AND
			(workorderproductiondetail.timeto>@EndTime)
		GROUP BY workorderheader.MachineID
		), 0)
*/
SELECT * FROM #ProductionTime
END
