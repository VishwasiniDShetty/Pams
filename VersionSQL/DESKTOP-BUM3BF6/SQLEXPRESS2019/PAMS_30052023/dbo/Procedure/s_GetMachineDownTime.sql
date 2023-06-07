/****** Object:  Procedure [dbo].[s_GetMachineDownTime]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE  PROCEDURE [dbo].[s_GetMachineDownTime]
	@StartTime as DateTime,
	@EndTime as DateTime,
	@MachineID as nvarchar(50) = '',
	@ComponentID nvarchar(50) = '',
	@OperatorID nvarchar(50) = ''
AS
BEGIN
declare @strsql nvarchar(2000)
declare @strmachine nvarchar(255)
declare @stroperator nvarchar(255)
declare @strcomponent nvarchar(255)

CREATE TABLE #DownTime ( pMachineID nvarchar(50) PRIMARY KEY, DownTime float, AvailEffyLoss float, ReturnPerMCHourLoss float)
INSERT INTO #DownTime ( pMachineID, DownTime , AvailEffyLoss, ReturnPerMCHourLoss)
SELECT  MachineID ,0,0,0 FROM MachineInformation

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
	select @stroperator = ' and ( workorderdowntimedetail.employeeid = ''' + @OperatorID +''')'
	END

--Type 1
select @strsql =''
select @strsql = @strsql + 'UPDATE #DownTime SET DownTime = isnull(DownTime,0) + isnull(t2.totaltime,0)'
select @strsql = @strsql + ' from '
select @strsql = @strsql + ' (SELECT machineid, sum(datediff(second,workorderDownTimedetail.timefrom, workorderDownTimedetail.timeto))'
select @strsql = @strsql + ' as totaltime FROM workorderheader INNER JOIN workorderDownTimedetail ON workorderheader.workorderno = workorderDownTimedetail.workorderno where'
select @strsql = @strsql + ' (workorderDownTimedetail.timefrom>=''' + convert(nvarchar(20),@StartTime) + ''')'
select @strsql = @strsql + ' AND (workorderDownTimedetail.timeto<=''' + convert(nvarchar(20),@EndTime) + ''')'
select @strsql = @strsql + @strmachine + @strcomponent + @stroperator
select @strsql = @strsql + ' GROUP BY workorderheader.machineID ) as t2 inner join #downtime on t2.machineid = #downtime.pmachineid'
exec (@strsql)

/*
-- Type 1
	UPDATE #DownTime
	SET DownTime = DownTime +
	isnull(	
		(SELECT sum(datediff(second,workorderDownTimedetail.timefrom, workorderDownTimedetail.timeto))
		FROM workorderheader
			INNER JOIN workorderDownTimedetail
			ON workorderheader.workorderno = workorderDownTimedetail.workorderno
		WHERE
			(workorderheader.machineid = pMachineID)
			AND
			( workorderheader.componentid LIKE '%'+@ComponentID+'%' )
			AND
			( workorderDownTimedetail.employeeid LIKE '%'+@OperatorID+'%' )	
			AND
			(workorderDownTimedetail.timefrom>=@StartTime)
			AND
			(workorderDownTimedetail.timeto<=@EndTime)
		GROUP BY workorderheader.MachineID
		),0)
-- Type 2
	UPDATE #DownTime
	SET DownTime = DownTime +
	isnull(	
		(SELECT sum(datediff(second,@StartTime, workorderDownTimedetail.timeto))
		FROM workorderheader
			INNER JOIN workorderDownTimedetail
				ON workorderheader.workorderno = workorderDownTimedetail.workorderno
		WHERE
			(workorderheader.machineid = pMachineID)
			AND
			( workorderheader.componentid LIKE '%'+@ComponentID+'%' )
			AND
			( workorderDownTimedetail.employeeid LIKE '%'+@OperatorID+'%' )	
			AND
			(workorderDownTimedetail.timefrom<@StartTime)
			AND
			(workorderDownTimedetail.timeto<=@EndTime)
			AND
			(workorderDownTimedetail.timeto>@StartTime)
		GROUP BY workorderheader.MachineID
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
			(workorderheader.machineid = pMachineID)
			AND
			( workorderheader.componentid LIKE '%'+@ComponentID+'%' )
			AND
			( workorderDownTimedetail.employeeid LIKE '%'+@OperatorID+'%' )	
			AND
			(workorderDownTimedetail.timefrom>=@StartTime)
			AND
			(workorderDownTimedetail.timefrom<@EndTime)
			AND
			(workorderDownTimedetail.timeto>@EndTime)
		GROUP BY workorderheader.MachineID
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
			(workorderheader.machineid LIKE '%'+pMachineID+'%')
			AND
			( workorderheader.componentid LIKE '%'+@ComponentID+'%' )
			AND
			( workorderDownTimedetail.employeeid LIKE '%'+@OperatorID+'%' )	
			AND 		
			(workorderDownTimedetail.timefrom<@StartTime)
			AND
			(workorderDownTimedetail.timeto>@EndTime)
		GROUP BY workorderheader.MachineID
		), 0)
*/
-- Update the Availability Efficiency Losses
-- Type 1
select @strsql = ''
select @strsql = @strsql + ' UPDATE #DownTime SET AvailEffyLoss = isnull(AvailEffyLoss,0) + isnull(t2.totaltime,0)'
select @strsql = @strsql + ' from '
select @strsql = @strsql + ' (SELECT machineid, sum(datediff(second,workorderDownTimedetail.timefrom,  workorderDownTimedetail.timeto))'
select @strsql = @strsql + ' as totaltime FROM workorderheader INNER JOIN workorderDownTimedetail ON workorderheader.workorderno = workorderDownTimedetail.workorderno '
select @strsql = @strsql + ' INNER JOIN downcodeinformation on workorderDownTimedetail.downid = downcodeinformation.downid '
select @strsql = @strsql + ' where (workorderDownTimedetail.timefrom>=''' + convert(nvarchar(20),@StartTime) + ''')'
select @strsql = @strsql + ' AND (workorderDownTimedetail.timeto<=''' + convert(nvarchar(20),@EndTime) + ''') AND (downcodeinformation.availeffy = 1)'
select @strsql = @strsql + @strmachine + @strcomponent + @stroperator
select @strsql = @strsql + ' GROUP BY workorderheader.machineID )as t2 inner join #downtime on t2.machineid = #downtime.pmachineid'
exec (@strsql)

/*
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
			(workorderheader.machineid = pMachineID)
			AND
			( workorderheader.componentid LIKE '%'+@ComponentID+'%' )
			AND
			( workorderDownTimedetail.employeeid LIKE '%'+@OperatorID+'%' )	
			AND
			(workorderDownTimedetail.timefrom<@StartTime)
			AND
			(workorderDownTimedetail.timeto<=@EndTime)
			AND
			(workorderDownTimedetail.timeto>@StartTime)
			AND
			(downcodeinformation.availeffy = 1)
		GROUP BY workorderheader.MachineID
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
			(workorderheader.machineid = pMachineID)
			AND
			( workorderheader.componentid LIKE '%'+@ComponentID+'%' )
			AND
			( workorderDownTimedetail.employeeid LIKE '%'+@OperatorID+'%' )	
			AND
			(workorderDownTimedetail.timefrom>=@StartTime)
			AND
			(workorderDownTimedetail.timefrom<@EndTime)
			AND
			(workorderDownTimedetail.timeto>@EndTime)
			AND
			(downcodeinformation.availeffy = 1)
		GROUP BY workorderheader.MachineID
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
			(workorderheader.machineid LIKE '%'+pMachineID+'%')
			AND
			( workorderheader.componentid LIKE '%'+@ComponentID+'%' )
			AND
			( workorderDownTimedetail.employeeid LIKE '%'+@OperatorID+'%' )	
			AND 		
			(workorderDownTimedetail.timefrom<@StartTime)
			AND
			(workorderDownTimedetail.timeto>@EndTime)
			AND
			(downcodeinformation.availeffy = 1)
		GROUP BY workorderheader.MachineID
		), 0)
*/
-- Update the Return Per Machine Hour Losses
-- Type 1

select @strsql = ''
select @strsql = @strsql + ' UPDATE #DownTime SET ReturnPerMCHourLoss = isnull(ReturnPerMCHourLoss,0) + isnull(t2.totaltime,0)'
select @strsql = @strsql + ' from '
select @strsql = @strsql + ' (SELECT machineid, sum(datediff(second,workorderDownTimedetail.timefrom,  workorderDownTimedetail.timeto))'
select @strsql = @strsql + ' as totaltime FROM workorderheader INNER JOIN workorderDownTimedetail ON workorderheader.workorderno = workorderDownTimedetail.workorderno '
select @strsql = @strsql + ' INNER JOIN downcodeinformation on workorderDownTimedetail.downid = downcodeinformation.downid '
select @strsql = @strsql + ' where (workorderDownTimedetail.timefrom>=''' + convert(nvarchar(20),@StartTime) + ''')'
select @strsql = @strsql + ' AND (workorderDownTimedetail.timeto<=''' + convert(nvarchar(20),@EndTime) + ''') AND (downcodeinformation.retpermchour = 1)'
select @strsql = @strsql + @strmachine + @strcomponent + @stroperator
select @strsql = @strsql + ' GROUP BY workorderheader.machineID )as t2 inner join #downtime on t2.machineid = #downtime.pmachineid'
exec (@strsql)

/*
select @strsql = ''
select @strsql = @strsql + ' UPDATE #DownTime SET ReturnPerMCHourLoss = ReturnPerMCHourLoss + '
select @strsql = @strsql + ' isnull((SELECT sum(datediff(second,workorderDownTimedetail.timefrom,
workorderDownTimedetail.timeto))'
select @strsql = @strsql + ' FROM workorderheader INNER JOIN workorderDownTimedetail ON
workorderheader.workorderno = workorderDownTimedetail.workorderno '
select @strsql = @strsql + ' INNER JOIN downcodeinformation on workorderDownTimedetail.downid =
downcodeinformation.downid '
select @strsql = @strsql + ' WHERE ( workorderheader.Machineid = pMachineID )'
select @strsql = @strsql + ' AND (workorderDownTimedetail.timefrom>=''' + convert(nvarchar(20),@StartTime) +
''')'
select @strsql = @strsql + ' AND (workorderDownTimedetail.timeto<=''' + convert(nvarchar(20),@StartTime) + ''')
AND (downcodeinformation.retpermchour = 1)'
select @strsql = @strsql + @strmachine + @strcomponent + @stroperator
select @strsql = @strsql + ' GROUP BY workorderheader.MachineID ), 0)'
exec (@strsql)
*/

/*
-- Update the Return Per Machine Hour Losses
-- Type 2
	UPDATE #DownTime
	SET ReturnPerMCHourLoss = ReturnPerMCHourLoss +
	isnull(	
		(SELECT sum(datediff(second,@StartTime, workorderDownTimedetail.timeto))
		FROM workorderheader
			INNER JOIN workorderDownTimedetail
				ON workorderheader.workorderno = workorderDownTimedetail.workorderno
		INNER JOIN downcodeinformation on workorderDownTimedetail.downid = downcodeinformation.downid
		WHERE
			(workorderheader.machineid = pMachineID)
			AND
			( workorderheader.componentid LIKE '%'+@ComponentID+'%' )
			AND
			( workorderDownTimedetail.employeeid LIKE '%'+@OperatorID+'%' )	
			AND
			(workorderDownTimedetail.timefrom<@StartTime)
			AND
			(workorderDownTimedetail.timeto<=@EndTime)
			AND
			(workorderDownTimedetail.timeto>@StartTime)
			AND
			(downcodeinformation.retpermchour = 1)
		GROUP BY workorderheader.MachineID
		), 0)
-- Type 3
	UPDATE #DownTime
	SET ReturnPerMCHourLoss = ReturnPerMCHourLoss +
	isNull(
		(SELECT sum(datediff(second, workorderDownTimedetail.timefrom, @EndTime))
		FROM workorderheader
			INNER JOIN workorderDownTimedetail
				ON workorderheader.workorderno = workorderDownTimedetail.workorderno
		INNER JOIN downcodeinformation on workorderDownTimedetail.downid = downcodeinformation.downid
		WHERE
			(workorderheader.machineid = pMachineID)
			AND
			( workorderheader.componentid LIKE '%'+@ComponentID+'%' )
			AND
			( workorderDownTimedetail.employeeid LIKE '%'+@OperatorID+'%' )	
			AND
			(workorderDownTimedetail.timefrom>=@StartTime)
			AND
			(workorderDownTimedetail.timefrom<@EndTime)
			AND
			(workorderDownTimedetail.timeto>@EndTime)
			AND
			(downcodeinformation.retpermchour = 1)
		GROUP BY workorderheader.MachineID
		), 0)
-- Type 4
	UPDATE #DownTime
	SET ReturnPerMCHourLoss = ReturnPerMCHourLoss +
	isNull(
		(SELECT datediff(second, @StartTime, @EndTime)*Count(*)
		FROM workorderheader
			INNER JOIN workorderDownTimedetail
				ON workorderheader.workorderno = workorderDownTimedetail.workorderno
		INNER JOIN downcodeinformation on workorderDownTimedetail.downid = downcodeinformation.downid
		WHERE
			(workorderheader.machineid LIKE '%'+pMachineID+'%')
			AND
			( workorderheader.componentid LIKE '%'+@ComponentID+'%' )
			AND
			( workorderDownTimedetail.employeeid LIKE '%'+@OperatorID+'%' )	
			AND 		
			(workorderDownTimedetail.timefrom<@StartTime)
			AND
			(workorderDownTimedetail.timeto>@EndTime)
			AND
			(downcodeinformation.retpermchour = 1)
		GROUP BY workorderheader.MachineID
		), 0)
*/
SELECT * FROM #DownTime
END
