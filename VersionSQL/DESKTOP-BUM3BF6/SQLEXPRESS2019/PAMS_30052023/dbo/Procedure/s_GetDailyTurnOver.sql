/****** Object:  Procedure [dbo].[s_GetDailyTurnOver]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[s_GetDailyTurnOver]
	@StartTime as DateTime,
	@EndTime as DateTime,
	@MachineID as nvarchar(50) = '',
	@ComponentID nvarchar(50) = '',
	@OperatorID nvarchar(50) = '',
	@MachineIDLabel nvarchar(50) ='ALL',
	@OperatorIDLabel nvarchar(50) = 'ALL',
	@ComponentIDLabel nvarchar(50) = 'ALL'
AS
BEGIN
declare @strsql nvarchar(2000)
declare @strmachine nvarchar(255)
declare @stroperator nvarchar(255)
declare @strcomponent nvarchar(255)
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
select @strsql = @strsql + ' SELECT  workorderproductiondetail.productiondate as Date,'
select @strsql = @strsql + ' SUM(workorderheader.price * (workorderproductiondetail.production -
workorderproductiondetail.rejection)) AS TurnOver,'''
select @strsql = @strsql + @MachineIDLabel + ''' as MachineIDLabel,'''
select @strsql = @strsql + @OperatorIDLabel + ''' as OperatorIDLabel,'''
select @strsql = @strsql + @ComponentIDLabel + ''' as ComponentIDLabel,'''
select @strsql = @strsql + convert(nvarchar(20),@StartTime) + ''' as StartTime,'''
select @strsql = @strsql + convert(nvarchar(20),@EndTime) + ''' as EndTime'
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
print @strsql
/*
SELECT  workorderproductiondetail.productiondate as Date,
	SUM(workorderheader.price * (workorderproductiondetail.production - workorderproductiondetail.rejection)) AS TurnOver,
	@MachineIDLabel as MachineIDLabel,
	@OperatorIDLabel as OperatorIDLabel,
	@ComponentIDLabel as ComponentIDLabel,
	@StartTime as StartTime,
	@EndTime as EndTime
FROM         workorderheader
	     INNER JOIN workorderproductiondetail ON
			workorderheader.workorderno = workorderproductiondetail.workorderno
WHERE 	
	( workorderheader.machineid LIKE '%'+@MachineID+'%')
	AND
	( workorderheader.componentid LIKE '%'+@ComponentID+'%' )
	AND
	( workorderproductiondetail.employeeid LIKE '%'+@OperatorID+'%' )
	AND
	((
		(workorderproductiondetail.timefrom>=@StartTime)
		AND
		(workorderproductiondetail.timeto<=@EndTime)
	)
	OR 	
	(
		(workorderproductiondetail.timefrom<@StartTime)
		AND
		(workorderproductiondetail.timeto<= @EndTime)
		AND
		(workorderproductiondetail.timeto>@StartTime)
	))
GROUP BY workorderproductiondetail.productiondate
*/
END
