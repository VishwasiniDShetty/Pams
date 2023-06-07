/****** Object:  Procedure [dbo].[s_GetDownTimeReport_ComponentWise]    Committed by VersionSQL https://www.versionsql.com ******/

/****** Object:  Stored Procedure dbo.s_GetDownTimeReport_ComponentWise    Script Date: 6/14/2004 2:18:07 PM ******/
CREATE   PROCEDURE [dbo].[s_GetDownTimeReport_ComponentWise]
	@StartTime DateTime,
	@EndTime DateTime,
	@MachineID  nvarchar(50) = '',
	@DownID  nvarchar(50) = '',
	@OperatorID  nvarchar(50) = '',
	@ComponentID  nvarchar(50) = '',
	@WorkOrderNo nvarchar(50) = '',
	@MachineIDLabel nvarchar(50) ='ALL',
	@OperatorIDLabel nvarchar(50) = 'ALL',
	@DownIDLabel nvarchar(50) = 'ALL',
	@ComponentIDLabel nvarchar(50) = 'ALL',
	@WorkOrderNoLabel nvarchar(50) = 'ALL'
AS
BEGIN
-- Temporary Table
CREATE TABLE #DownTimeData
(
	ComponentID nvarchar(50) PRIMARY KEY,
	DownTime float
)
declare @strsql nvarchar(2000)
declare @strmachine nvarchar(255)
declare @stremployee nvarchar(255)
declare @strworkorder nvarchar(255)
declare @strcomponentid nvarchar(255)

select @strsql = ''
select @strcomponentid = ''
if isnull(@componentid,'') <> ''
	begin
	select @strcomponentid = ' WHERE ( componentinformation.componentid = ''' + @componentid + ''')'
	end
select @strsql = 'INSERT INTO #DownTimeData (ComponentID, DownTime) '
select @strsql = @strsql +  ' SELECT Componentinformation.ComponentID ,0'
select @strsql = @strsql +  ' FROM   Componentinformation '			
select @strsql = @strsql +  @strcomponentid
select @strsql = @strsql +  ' ORDER BY  Componentinformation.ComponentID'
exec (@strsql)
select @strsql = ''

select @strmachine = ''
select @strworkorder = ''
select @stremployee = ''
if isnull(@machineid,'') <> ''
	begin
	select @strmachine = ' and ( workorderheader.MachineID = ''' + @MachineID + ''')'
	end
if isnull(@workorderno,'') <> ''
	begin
	select @strworkorder = ' AND ( workorderheader.workorderno = ''' + @WorkOrderNo + ''')'
	end
if isnull(@operatorid, '') <> ''
	begin
	select @stremployee = ' AND ( workorderdowntimedetail.employeeid = ''' +@OperatorID +''')'
	end
-- Get Down Time Details
-- Type 1
	select @strsql = @strsql + 'UPDATE #DownTimeData SET DownTime = isnull(DownTime,0) + isnull(t2.totaltime,0)'
	select @strsql = @strsql + ' from '
	select @strsql = @strsql + ' (SELECT componentid, sum(datediff(second,workorderDownTimedetail.timefrom, workorderDownTimedetail.timeto))'
	select @strsql = @strsql + ' as totaltime FROM workorderheader INNER JOIN workorderDownTimedetail ON workorderheader.workorderno = workorderDownTimedetail.workorderno where'
	select @strsql = @strsql + ' (workorderDownTimedetail.timefrom>=''' + convert(nvarchar(20),@StartTime) + ''')'
	select @strsql = @strsql + ' AND (workorderDownTimedetail.timeto<=''' + convert(nvarchar(20),@EndTime) + ''')'
	select @strsql = @strsql + @strmachine + @strworkorder + @stremployee
	select @strsql = @strsql + ' GROUP BY workorderheader.ComponentID ) as t2 inner join #downtimedata on t2.componentid = #downtimedata.componentid'
	exec (@strsql)


/*
	select @strsql = 'UPDATE #DownTimeData '
	select @strsql = @strsql +  ' SET DownTime = DownTime + '	
	select @strsql = @strsql + ' isnull((SELECT sum(datediff(second,workorderDownTimedetail.timefrom, workorderDownTimedetail.timeto)) '
	select @strsql = @strsql + ' FROM workorderheader INNER JOIN workorderDownTimedetail ON workorderheader.workorderno = workorderDownTimedetail.workorderno '
	select @strsql = @strsql + ' WHERE ( workorderheader.componentid  = #DownTimeData.ComponentID )	'
	select @strsql = @strsql + ' AND (workorderDownTimedetail.timefrom >= ''' + convert(nvarchar(20),@StartTime) + ''')'
	select @strsql = @strsql + ' AND (workorderDownTimedetail.timeto <= ''' + convert(nvarchar(20),@EndTime) + ''')'
	select @strsql = @strsql + @strmachine + @strworkorder + @stremployee
	select @strsql = @strsql + ' GROUP BY workorderheader.componentid), 0)'
	exec (@strsql)
*/
/*
-- Type 2
	UPDATE #DownTimeData
	SET DownTime = DownTime +
	isnull(	
		(SELECT sum(datediff(second,@StartTime, workorderDownTimedetail.timeto))
		FROM workorderheader
			INNER JOIN workorderDownTimedetail
				ON workorderheader.workorderno = workorderDownTimedetail.workorderno
		WHERE
			( workorderheader.MachineID LIKE '%'+@MachineID+'%' )
			AND
			( workorderheader.workorderno LIKE '%'+@WorkOrderNo+'%')
			AND
			( workorderdowntimedetail.employeeid LIKE '%'+@OperatorID+'%')
			AND
			( workorderheader.componentid  = #DownTimeData.ComponentID )				
			AND
			(workorderDownTimedetail.timefrom<@StartTime)
			AND
			(workorderDownTimedetail.timeto<=@EndTime)
			AND
			(workorderDownTimedetail.timeto>@StartTime)
		GROUP BY workorderheader.componentid
		), 0)
-- Type 3
	UPDATE #DownTimeData
	SET DownTime = DownTime +
	isNull(
		(SELECT sum(datediff(second, workorderDownTimedetail.timefrom, @EndTime))
		FROM workorderheader
			INNER JOIN workorderDownTimedetail
				ON workorderheader.workorderno = workorderDownTimedetail.workorderno
		WHERE
			( workorderheader.MachineID LIKE '%'+@MachineID+'%' )
			AND
			( workorderheader.workorderno LIKE '%'+@WorkOrderNo+'%')
			AND			
			( workorderdowntimedetail.employeeid LIKE '%'+@OperatorID+'%')
			AND
			( workorderheader.componentid  = #DownTimeData.ComponentID )		
			AND
			(workorderDownTimedetail.timefrom>=@StartTime)
			AND
			(workorderDownTimedetail.timefrom<@EndTime)
			AND
			(workorderDownTimedetail.timeto>@EndTime)
		GROUP BY workorderheader.componentid
		), 0)
-- Type 4
	UPDATE #DownTimeData
	SET DownTime = DownTime +
	isNull(
		(SELECT datediff(second, @StartTime, @EndTime)*Count(*)
		FROM workorderheader
			INNER JOIN workorderDownTimedetail
				ON workorderheader.workorderno = workorderDownTimedetail.workorderno
		WHERE
			( workorderheader.MachineID LIKE '%'+@MachineID+'%' )
			AND
			( workorderheader.workorderno LIKE '%'+@WorkOrderNo+'%')
			AND
			( workorderdowntimedetail.employeeid LIKE '%'+@OperatorID+'%')
			AND
			( workorderheader.componentid  = #DownTimeData.ComponentID )
			AND
			(workorderDownTimedetail.timefrom<@StartTime)
			AND
			(workorderDownTimedetail.timeto>@EndTime)
		GROUP BY workorderheader.componentid
		), 0)
*/
select *,
	dateadd(second, DownTime, '1900-1-1 00:00:00') as Time,
	(DownTime/3600) as Hours ,
	@StartTime  as StartTime,
	@EndTime as EndTime,
	@MachineIDLabel as MachineIDLabel,
	@OperatorIDLabel as OperatorIDLabel,
	@DownIDLabel as DownIDLabel,
	@ComponentIDLabel as ComponentIDLabel,
	@WorkOrderNoLabel as WorkOrderNoLabel
from #DownTimeData
where downtime <> 0
order by downtime
END
