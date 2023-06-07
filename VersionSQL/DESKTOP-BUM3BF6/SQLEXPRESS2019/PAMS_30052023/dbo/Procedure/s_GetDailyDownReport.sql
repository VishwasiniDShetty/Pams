/****** Object:  Procedure [dbo].[s_GetDailyDownReport]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE    PROCEDURE [dbo].[s_GetDailyDownReport]
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
-- Create temporary table to store the report data
declare @strsql nvarchar(2000)
declare @strmachine nvarchar(255)
declare @stremployee nvarchar(255)
declare @strworkorder nvarchar(255)
declare @strcomponentid nvarchar(255)
declare @strdown nvarchar(255)
select @strsql = ''
select @strcomponentid = ''
select @strdown = ''
select @strmachine = ''
select @strworkorder = ''
select @stremployee = ''
if isnull(@componentid,'') <> ''
	begin
	select @strcomponentid = ' AND ( workorderheader.componentid = ''' + @componentid + ''')'
	end
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
if isnull(@downid, '') <> ''
	begin
	select @strdown = ' AND ( workorderdowntimedetail.downid = ''' +@DownID +''')'
	end
CREATE TABLE #DownTimeData ( 	
	dDate smalldatetime,
	DownTime float,
	)
-- DownTime Time
-- Type 1
select @strsql = 'INSERT INTO  #DownTimeData (dDate, DownTime) '
select @strsql = @strsql +  ' SELECT downdate, isnull(sum(datediff(second,workorderdowntimedetail.timefrom, workorderDownTimedetail.timeto)) , 0)'
select @strsql = @strsql +  ' FROM workorderheader INNER JOIN workorderDownTimedetail ON workorderheader.workorderno = workorderDownTimedetail.workorderno '
select @strsql = @strsql +  ' WHERE '
select @strsql = @strsql +  ' (workorderDownTimedetail.timefrom >= ''' + convert(varchar(20),@StartTime) + ''')'
select @strsql = @strsql +  ' AND 	(workorderDownTimedetail.timeto <= ''' + convert(varchar(20),@EndTime) + ''')'
select @strsql = @strsql + @strmachine + @strworkorder + @stremployee + @strcomponentid + @strdown
select @strsql = @strsql +  ' GROUP BY workorderDownTimedetail.DownDate '
--print @strsql

exec (@strsql)
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
			( workorderheader.machineid LIKE '%'+@MachineID+'%')
			AND
			( workorderheader.workorderno LIKE '%'+@WorkOrderNo+'%')
			AND
			( workorderDownTimedetail.downid LIKE '%'+@DownID+'%')
			AND
			( workorderheader.componentid LIKE '%'+@ComponentID+'%')
			AND
			( workorderDownTimedetail.employeeid LIKE '%'+@OperatorID+'%' )	
			AND
			( workorderDownTimedetail.DownDate = #DownTimeData.dDate)
			AND
			(workorderDownTimedetail.timefrom<@StartTime)
			AND
			(workorderDownTimedetail.timeto<=@EndTime)
			AND
			(workorderDownTimedetail.timeto>@StartTime)
		GROUP BY workorderDownTimedetail.DownDate
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
			( workorderheader.machineid LIKE '%'+@MachineID+'%')
			AND
			( workorderheader.workorderno LIKE '%'+@WorkOrderNo+'%')
			AND
			( workorderDownTimedetail.downid LIKE '%'+@DownID+'%')
			AND
			( workorderheader.componentid LIKE '%'+@ComponentID+'%')
			AND
			( workorderDownTimedetail.employeeid LIKE '%'+@OperatorID+'%' )	
			AND
			( workorderDownTimedetail.DownDate = #DownTimeData.dDate)
			AND
			(workorderDownTimedetail.timefrom>=@StartTime)
			AND
			(workorderDownTimedetail.timefrom<@EndTime)
			AND
			(workorderDownTimedetail.timeto>@EndTime)
		GROUP BY workorderDownTimedetail.DownDate
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
			( workorderheader.machineid LIKE '%'+@MachineID+'%')
			AND
			( workorderheader.workorderno LIKE '%'+@WorkOrderNo+'%')
			AND
			( workorderDownTimedetail.downid LIKE '%'+@DownID+'%')
			AND			
			( workorderheader.componentid LIKE '%'+@ComponentID+'%')
			AND
			( workorderDownTimedetail.employeeid LIKE '%'+@OperatorID+'%' )	
			AND
			( workorderDownTimedetail.DownDate = #DownTimeData.dDate)
			AND 		
			(workorderDownTimedetail.timefrom<@StartTime)
			AND
			(workorderDownTimedetail.timeto>@EndTime)
		GROUP BY workorderDownTimedetail.DownDate
		), 0)
*/
select *,
	dateadd(second, DownTime, '1900-1-1 00:00:00') as Time,
	(DownTime/3600) as Hours ,
	@StartTime as StartTime,
	@EndTime as EndTime,
	@MachineIDLabel as MachineIDLabel,
	@OperatorIDLabel as OperatorIDLabel,
	@DownIDLabel as DownIDLabel,
	@ComponentIDLabel as ComponentIDLabel,
	@WorkOrderNoLabel as WorkOrderNoLabel
	from #DownTimeData
where downtime <> 0
order by dDate
END
