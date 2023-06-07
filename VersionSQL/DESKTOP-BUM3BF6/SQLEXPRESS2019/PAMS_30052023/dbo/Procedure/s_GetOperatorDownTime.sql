/****** Object:  Procedure [dbo].[s_GetOperatorDownTime]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE    PROCEDURE [dbo].[s_GetOperatorDownTime]
	@StartTime as DateTime,
	@EndTime as DateTime,
	@MachineID as nvarchar(50) = '',
	@ComponentID nvarchar(50) = '',
	@OperatorID nvarchar(50) = ''
AS
BEGIN
CREATE TABLE #DownTime ( DownTime float, AvailEffyLoss float, pOperatorID nvarchar(50) PRIMARY KEY)
declare @strsql nvarchar(2000)
declare @strmachine nvarchar(255)
declare @strcomponent nvarchar(255)
declare @stroperator nvarchar(255)

INSERT #DownTime (pOperatorID, DownTime, AvailEffyLoss)
SELECT DISTINCT employeeID,0,0
  FROM workorderheader
 INNER JOIN workorderDownTimedetail
    ON workorderheader.workorderno = workorderDownTimedetail.workorderno
 WHERE
	((workorderdowntimedetail.timefrom >=@StartTime) and (workorderdowntimedetail.timeto <=@EndTime))
	OR
	((workorderdowntimedetail.timefrom < @StartTime) and (workorderdowntimedetail.timeto <=@EndTime) and (workorderdowntimedetail.timeto > @StartTime))
	or	
	((workorderdowntimedetail.timefrom >= @StartTime) and (workorderdowntimedetail.timeto > @EndTime) and (workorderdowntimedetail.timeFROM < @EndTime))
	OR
	((workorderdowntimedetail.timefrom < @StartTime) AND (workorderdowntimedetail.timeto > @EndTime))

--SELECT EmployeeID,0,0 FROM EmployeeInformation

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
	select @strmachine =  ' and ( workorderheader.componentid = ''' + @ComponentID + ''')'
	end
if isnull(@operatorid,'')  <> ''
	BEGIN
	select @stroperator = ' and ( workorderdowntimedetail.employeeid = ''' + @OperatorID +''')'
	END

select @strsql = ''
select @strsql = @strsql + 'UPDATE #DownTime SET DownTime = isnull(DownTime,0) + isnull(t2.totaltime,0)'
select @strsql = @strsql + ' from '
select @strsql = @strsql + ' (SELECT employeeid, sum(datediff(second,workorderDownTimedetail.timefrom, workorderDownTimedetail.timeto))'
select @strsql = @strsql + ' as totaltime FROM workorderheader INNER JOIN workorderDownTimedetail ON workorderheader.workorderno = workorderDownTimedetail.workorderno where'
select @strsql = @strsql + ' (workorderDownTimedetail.timefrom>=''' + convert(nvarchar(20),@StartTime) + ''')'
select @strsql = @strsql + ' AND (workorderDownTimedetail.timeto<=''' + convert(nvarchar(20),@EndTime) + ''')'
select @strsql = @strsql + @strmachine + @strcomponent + @stroperator
select @strsql = @strsql + ' GROUP BY workorderdowntimedetail.employeeID ) as t2 inner join #downtime on t2.employeeid = #downtime.poperatorid'
exec (@strsql)

/*

-- Type 2
	UPDATE #DownTime
	SET DownTime = DownTime +
	isnull(	
		(SELECT sum(datediff(second,@StartTime, workorderDownTimedetail.timeto))
		FROM workorderheader
			INNER JOIN workorderDownTimedetail
				ON workorderheader.workorderno = workorderDownTimedetail.workorderno
		WHERE
			( workorderheader.machineid LIKE '%'+@MachineID+'%')
			AND
			( workorderheader.componentid LIKE '%'+@ComponentID+'%' )
			AND
			( workorderDownTimedetail.employeeid = pOperatorID )	
			AND
			(workorderDownTimedetail.timefrom<@StartTime)
			AND
			(workorderDownTimedetail.timeto<=@EndTime)
			AND
			(workorderDownTimedetail.timeto>@StartTime)
		GROUP BY workorderDownTimedetail.employeeid
		), 0)
-- Type 3
	UPDATE #DownTime
	SET DownTime = DownTime +
	isNull(
		(SELECT sum(datediff(second, workorderDownTimedetail.timefrom, @EndTime))
		FROM workorderheader
			INNER JOIN workorderDownTimedetail
				ON workorderheader.workorderno = workorderDownTimedetail.workorderno
		WHERE
			( workorderheader.machineid LIKE '%'+@MachineID+'%')
			AND
			( workorderheader.componentid LIKE '%'+@ComponentID+'%' )
			AND
			( workorderDownTimedetail.employeeid = pOperatorID )	
			AND
			(workorderDownTimedetail.timefrom>=@StartTime)
			AND
			(workorderDownTimedetail.timefrom<@EndTime)
			AND
			(workorderDownTimedetail.timeto>@EndTime)
		GROUP BY workorderDownTimedetail.employeeid
		), 0)
-- Type 4
	UPDATE #DownTime
	SET DownTime = DownTime +
	isNull(
		(SELECT datediff(second, @StartTime, @EndTime)*Count(*)
		FROM workorderheader
			INNER JOIN workorderDownTimedetail
				ON workorderheader.workorderno = workorderDownTimedetail.workorderno
		WHERE
			(workorderheader.machineid LIKE '%'+@MachineID+'%')
			AND
			( workorderheader.componentid LIKE '%'+@ComponentID+'%' )
			AND
			( workorderDownTimedetail.employeeid = pOperatorID )	
			AND 		
			(workorderDownTimedetail.timefrom<@StartTime)
			AND
			(workorderDownTimedetail.timeto>@EndTime)
		GROUP BY workorderDownTimedetail.employeeid
		), 0)
*/
-- Update the Availability Efficiency Losses
-- Type 1
select @strsql = ''
select @strsql = @strsql + ' UPDATE #DownTime SET AvailEffyLoss = isnull(AvailEffyLoss,0) + isnull(t2.totaltime,0)'
select @strsql = @strsql + ' from '
select @strsql = @strsql + ' (SELECT employeeid, sum(datediff(second,workorderDownTimedetail.timefrom,  workorderDownTimedetail.timeto))'
select @strsql = @strsql + ' as totaltime FROM workorderheader INNER JOIN workorderDownTimedetail ON workorderheader.workorderno = workorderDownTimedetail.workorderno '
select @strsql = @strsql + ' INNER JOIN downcodeinformation on workorderDownTimedetail.downid = downcodeinformation.downid '
select @strsql = @strsql + ' where (workorderDownTimedetail.timefrom>=''' + convert(nvarchar(20),@StartTime) + ''')'
select @strsql = @strsql + ' AND (workorderDownTimedetail.timeto<=''' + convert(nvarchar(20),@StartTime) + ''') AND (downcodeinformation.availeffy = 1)'
select @strsql = @strsql + @strmachine + @strcomponent + @stroperator
select @strsql = @strsql + ' GROUP BY workorderdowntimedetail.employeeID )as t2 inner join #downtime on t2.employeeid = #downtime.poperatorid'
exec (@strsql)

/*
	UPDATE #DownTime
	SET AvailEffyLoss = AvailEffyLoss +
	isnull(	
	(SELECT sum(datediff(second,workorderDownTimedetail.timefrom, workorderDownTimedetail.timeto))
	FROM workorderheader
		INNER JOIN workorderDownTimedetail
		ON workorderheader.workorderno = workorderDownTimedetail.workorderno
		INNER JOIN downcodeinformation on workorderDownTimedetail.downid = downcodeinformation.downid
	WHERE
		( workorderheader.machineid LIKE '%'+@MachineID+'%')
		AND
		( workorderheader.componentid LIKE '%'+@ComponentID+'%' )
		AND
		( workorderDownTimedetail.employeeid = pOperatorID)	
		AND
		(workorderDownTimedetail.timefrom>=@StartTime)
		AND
		(workorderDownTimedetail.timeto<=@EndTime)
		AND
		(downcodeinformation.availeffy = 1)
	GROUP BY workorderDownTimedetail.employeeid
	), 0)
-- Type 2
	UPDATE #DownTime
	SET AvailEffyLoss = AvailEffyLoss +
	isnull(	
		(SELECT sum(datediff(second,@StartTime, workorderDownTimedetail.timeto))
		FROM workorderheader
			INNER JOIN workorderDownTimedetail
				ON workorderheader.workorderno = workorderDownTimedetail.workorderno
		INNER JOIN downcodeinformation on workorderDownTimedetail.downid = downcodeinformation.downid
		WHERE
			( workorderheader.machineid LIKE '%'+@MachineID+'%')
			AND
			( workorderheader.componentid LIKE '%'+@ComponentID+'%' )
			AND
			( workorderDownTimedetail.employeeid = pOperatorID)	
			AND
			(workorderDownTimedetail.timefrom<@StartTime)
			AND
			(workorderDownTimedetail.timeto<=@EndTime)
			AND
			(workorderDownTimedetail.timeto>@StartTime)
			AND
			(downcodeinformation.availeffy = 1)
		GROUP BY workorderDownTimedetail.employeeid
		), 0)
-- Type 3
	UPDATE #DownTime
	SET AvailEffyLoss = AvailEffyLoss +
	isNull(
		(SELECT sum(datediff(second, workorderDownTimedetail.timefrom, @EndTime))
		FROM workorderheader
			INNER JOIN workorderDownTimedetail
				ON workorderheader.workorderno = workorderDownTimedetail.workorderno
		INNER JOIN downcodeinformation on workorderDownTimedetail.downid = downcodeinformation.downid

		WHERE
			( workorderheader.machineid LIKE '%'+@MachineID+'%')
			AND
			( workorderheader.componentid LIKE '%'+@ComponentID+'%' )
			AND
			( workorderDownTimedetail.employeeid = pOperatorID)	
			AND
			(workorderDownTimedetail.timefrom>=@StartTime)
			AND
			(workorderDownTimedetail.timefrom<@EndTime)
			AND
			(workorderDownTimedetail.timeto>@EndTime)
			AND
			(downcodeinformation.availeffy = 1)
		GROUP BY workorderDownTimedetail.employeeid
		), 0)
-- Type 4
	UPDATE #DownTime
	SET AvailEffyLoss = AvailEffyLoss +
	isNull(
		(SELECT datediff(second, @StartTime, @EndTime)*Count(*)
		FROM workorderheader
			INNER JOIN workorderDownTimedetail
				ON workorderheader.workorderno = workorderDownTimedetail.workorderno
		INNER JOIN downcodeinformation on workorderDownTimedetail.downid = downcodeinformation.downid
		WHERE
			(workorderheader.machineid LIKE '%'+@MachineID+'%')
			AND
			( workorderheader.componentid LIKE '%'+@ComponentID+'%' )
			AND
			( workorderDownTimedetail.employeeid = pOperatorID)	
			AND 		
			(workorderDownTimedetail.timefrom<@StartTime)
			AND
			(workorderDownTimedetail.timeto>@EndTime)
			AND
			(downcodeinformation.availeffy = 1)
		GROUP BY workorderDownTimedetail.employeeid
		), 0)
*/
SELECT * FROM #DownTime
END
