/****** Object:  Procedure [dbo].[s_GetDownTimeReport_OperatorWise]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE   PROCEDURE [dbo].[s_GetDownTimeReport_OperatorWise]
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
	EmployeeID nvarchar(50) PRIMARY KEY,
	DownTime float
)
declare @strsql nvarchar(2000)
declare @strmachine nvarchar(255)
declare @stremployee nvarchar(255)
declare @strworkorder nvarchar(255)
declare @strcomponent nvarchar(255)
declare @strdown nvarchar(255)

select @strsql = ''
select @stremployee = ''
if isnull(@operatorid,'') <> ''
	begin
	select @stremployee = ' WHERE ( employeeinformation.employeeid = ''' + @operatorid + ''')'
	end

select @strsql = 'INSERT INTO #DownTimeData (EmployeeID, DownTime) '
select @strsql = @strsql +  ' SELECT     Employeeinformation.EmployeeID ,0'
select @strsql = @strsql +  ' FROM         	Employeeinformation'				
select @strsql = @strsql +  @stremployee
select @strsql = @strsql +  ' ORDER BY Employeeinformation.EmployeeID'
exec (@strsql)

select @strsql = ''
select @strmachine = ''
select @strworkorder = ''
select @strcomponent = ''
select @strdown = ''

if isnull(@machineid,'') <> ''
	begin
	select @strmachine = ' and ( workorderheader.MachineID = ''' + @MachineID + ''')'
	end
if isnull(@workorderno,'') <> ''
	begin
	select @strworkorder = ' AND ( workorderheader.workorderno = ''' + @WorkOrderNo + ''')'
	end
if isnull(@componentid, '') <> ''
	begin
	select @strcomponent = ' AND ( workorderheader.componentid = ''' +@ComponentID +''')'
	end
if isnull(@downid,'')  <> ''
	BEGIN
	select @strdown = ' AND ( workorderdowntimedetail.downid = ''' + @Downid +''')'
	END

-- Get Down Time Details
-- Type 1
	select @strsql = @strsql + 'UPDATE #DownTimeData SET DownTime = isnull(DownTime,0) + isnull(t2.totaltime,0)'
	select @strsql = @strsql + ' from '
	select @strsql = @strsql + ' (SELECT workorderdowntimedetail.employeeid, sum(datediff(second,workorderDownTimedetail.timefrom, workorderDownTimedetail.timeto))'
	select @strsql = @strsql + ' as totaltime FROM workorderheader INNER JOIN workorderDownTimedetail ON workorderheader.workorderno = workorderDownTimedetail.workorderno where'
	select @strsql = @strsql + ' (workorderDownTimedetail.timefrom>=''' + convert(nvarchar(20),@StartTime) + ''')'
	select @strsql = @strsql + ' AND (workorderDownTimedetail.timeto<=''' + convert(nvarchar(20),@EndTime) + ''')'
	select @strsql = @strsql + @strmachine + @strworkorder + @strcomponent + @strdown
	select @strsql = @strsql + ' GROUP BY workorderdowntimedetail.employeeID ) as t2 inner join #downtimedata on t2.employeeid = #downtimedata.employeeid'
	exec (@strsql)

/*
	select @strsql = 'UPDATE #DownTimeData '
	select @strsql = @strsql +  ' SET DownTime = DownTime + '	
	select @strsql = @strsql + ' isnull((SELECT sum(datediff(second,workorderDownTimedetail.timefrom, workorderDownTimedetail.timeto)) '
	select @strsql = @strsql + ' FROM workorderheader INNER JOIN workorderDownTimedetail ON workorderheader.workorderno = workorderDownTimedetail.workorderno '
	select @strsql = @strsql + ' WHERE ( workorderdowntimedetail.employeeid  = #DownTimeData.EmployeeID )	'
	select @strsql = @strsql + ' AND (workorderDownTimedetail.timefrom >= ''' + convert(nvarchar(20),@StartTime) + ''')'
	select @strsql = @strsql + ' AND (workorderDownTimedetail.timeto <= ''' + convert(nvarchar(20),@EndTime) + ''')'
	select @strsql = @strsql + @strmachine + @strworkorder + @strcomponent
	select @strsql = @strsql + ' GROUP BY workorderdowntimedetail.employeeid), 0)'
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
			( workorderheader.componentid LIKE '%'+@ComponentID+'%')
			AND
			( workorderDownTimedetail.EmployeeID  = #DownTimeData.EmployeeID )				
			AND
			(workorderDownTimedetail.timefrom<@StartTime)
			AND
			(workorderDownTimedetail.timeto<=@EndTime)
			AND
			(workorderDownTimedetail.timeto>@StartTime)
		GROUP BY workorderdowntimedetail.employeeid
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
			( workorderheader.componentid LIKE '%'+@ComponentID+'%')
			AND
			( workorderDownTimedetail.EmployeeID  = #DownTimeData.EmployeeID )		
			AND
			(workorderDownTimedetail.timefrom>=@StartTime)
			AND
			(workorderDownTimedetail.timefrom<@EndTime)
			AND
			(workorderDownTimedetail.timeto>@EndTime)
		GROUP BY workorderdowntimedetail.employeeid
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
			( workorderheader.componentid LIKE '%'+@ComponentID+'%')
			AND
			( workorderDownTimedetail.EmployeeID  = #DownTimeData.EmployeeID )
			AND
			(workorderDownTimedetail.timefrom<@StartTime)
			AND
			(workorderDownTimedetail.timeto>@EndTime)
		GROUP BY workorderdowntimedetail.employeeid
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
