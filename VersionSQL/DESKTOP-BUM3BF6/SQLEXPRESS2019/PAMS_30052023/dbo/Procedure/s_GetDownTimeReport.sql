/****** Object:  Procedure [dbo].[s_GetDownTimeReport]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE       PROCEDURE [dbo].[s_GetDownTimeReport]
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
declare @strsql nvarchar(2000)
declare @strdown nvarchar(255)
declare @strMachine nvarchar(255)
declare @strworkorder nvarchar(255)
declare @strcomponent nvarchar(255)
declare @strOperator nvarchar(255)
-- Temporary Table
CREATE TABLE #DownTimeData
(
	MachineID nvarchar(50),
	DownID nvarchar(50),
	DownTime float
	CONSTRAINT downtimedata_key PRIMARY KEY (MachineId, DownID)
)
CREATE TABLE #FinalData
(
	MachineID nvarchar(50),
	DownID nvarchar(50),
	DownTime float,
	TotalMachine float,
	TotalDown float
	CONSTRAINT finaldata_key PRIMARY KEY (MachineID, DownID)
)
select @strsql = ''
select @strsql = 'INSERT INTO #DownTimeData (MachineID, DownID, DownTime) SELECT Machineinformation.MachineID AS MachineID, downcodeinformation.downid AS DownID, 0 FROM Machineinformation CROSS JOIN downcodeinformation'
if isnull(@downid, '') <> '' and isnull(@machineid,'') <> ''
	begin
	select @strsql =  @strsql + ' where ( downcodeinformation.downid = ''' + @downid + ''')'
	select @strsql =  @strsql + ' and ( machineinformation.machineid = ''' + @machineid + ''')'
	end
if isnull(@downid, '') <> '' and isnull(@machineid,'') = ''
	begin
	select @strsql =  @strsql + ' where ( downcodeinformation.downid = ''' + @downid + ''')'
	end
if isnull(@downid, '') = '' and isnull(@machineid,'') <> ''
	begin
	select @strsql =  @strsql + ' where ( machineinformation.machineid = ''' + @machineid + ''')'
	end
select @strsql = @strsql + ' ORDER BY  downcodeinformation.downid, Machineinformation.MachineID'
exec (@strsql)
/*
INSERT INTO #DownTimeData (MachineID, DownID, DownTime)
SELECT     Machineinformation.MachineID AS MachineID, downcodeinformation.downid AS DownID, 0
FROM       	Machineinformation CROSS JOIN                       	
		downcodeinformation			
WHERE   (Machineinformation.MachineID LIKE '%'+@MachineID+'%')
	AND
	(downcodeinformation.downid LIKE '%'+@DownID+'%' )
ORDER BY  downcodeinformation.downid, Machineinformation.MachineID
*/
select @strdown = ''
select @strmachine = ''
select @stroperator = ''
select @strcomponent = ''
select @strworkorder = ''
if isnull(@machineid, '') <> ''
	begin
	select @strmachine =  ' and ( workorderheader.machineid = ''' + @machineid + ''')'
	end
if isnull(@workorderno, '') <> ''
	begin
	select @strworkorder =  ' and ( workorderheader.workorderno = ''' + @workorderno + ''')'
	end
if isnull(@componentid, '') <> ''
	begin
	select @strcomponent =  ' and ( workorderheader.componentid = ''' + @componentid + ''')'
	end
if isnull(@operatorid,'')  <> ''
	BEGIN
	select @stroperator = ' and ( workorderdowntimedetail.employeeid = ''' + @OperatorID +''')'
	END
if isnull(@downid,'')  <> ''
	BEGIN
	select @strdown = ' and ( workorderdowntimedetail.downid = ''' + @Downid +''')'
	END
-- Get Down Time Details
select @strsql = ''
select @strsql = @strsql + 'UPDATE #DownTimeData SET DownTime = isnull(DownTime,0) + isnull(t2.totaltime,0)'
select @strsql = @strsql + ' from '
select @strsql = @strsql + ' (SELECT workorderheader.machineid, workorderdowntimedetail.downid, sum(datediff(second,workorderDownTimedetail.timefrom, workorderDownTimedetail.timeto))'
select @strsql = @strsql + ' as totaltime FROM workorderheader INNER JOIN workorderDownTimedetail ON workorderheader.workorderno = workorderDownTimedetail.workorderno where'
select @strsql = @strsql + ' (workorderDownTimedetail.timefrom>=''' + convert(nvarchar(20),@StartTime) + ''')'
select @strsql = @strsql + ' AND (workorderDownTimedetail.timeto<=''' + convert(nvarchar(20),@EndTime) + ''')'
select @strsql = @strsql + @strworkorder + @strmachine + @strcomponent + @strdown + @stroperator
select @strsql = @strsql + ' GROUP BY workorderheader.MachineID, workorderDownTimedetail.downid ) as t2 inner join #downtimedata on t2.machineid = #downtimedata.machineid and t2.downid = #downtimedata.downid'
exec (@strsql)
/*
select @strsql = ''
select @strsql = 'UPDATE #DownTimeData SET DownTime = DownTime +  '
select @strsql = @strsql + ' isnull( (SELECT sum(datediff(second,workorderDownTimedetail.timefrom, '
select @strsql = @strsql + 'workorderDownTimedetail.timeto)) FROM workorderheader  '
select @strsql = @strsql + ' INNER JOIN workorderDownTimedetail '
select @strsql = @strsql + ' ON workorderheader.workorderno = workorderdowntimedetail.workorderno WHERE '
select @strsql = @strsql + ' ( workorderheader.machineid  = #DownTimeData.MachineID ) '
select @strsql = @strsql + @strworkorder + @strcomponent
select @strsql = @strsql + ' and ( workorderDownTimedetail.downid = #DownTimeData.DownID ) '
select @strsql = @strsql + @stroperator
select @strsql = @strsql + ' and ( workorderdowntimedetail.timefrom>= ''' + convert(nvarchar(20),@StartTime) + ''')'
select @strsql = @strsql + ' and ( workorderdowntimedetail.timeto<= ''' + convert(nvarchar(20),@EndTime) + ''')'
select @strsql = @strsql + ' GROUP BY workorderheader.MachineID, workorderDownTimedetail.downid ),0)'
--print @strsql
exec (@strsql)
*/
/*
-- Type 1
	UPDATE #DownTimeData
	SET DownTime = DownTime + 	
	isnull(	
		(SELECT sum(datediff(second,workorderDownTimedetail.timefrom, workorderDownTimedetail.timeto))
		FROM workorderheader
			INNER JOIN workorderDownTimedetail
				ON workorderheader.workorderno = workorderDownTimedetail.workorderno
		WHERE
			( workorderheader.MachineID = #DownTimeData.MachineID)
			AND
			( workorderheader.workorderno LIKE '%'+@WorkOrderNo+'%')
			AND
			( workorderDownTimedetail.downid = #DownTimeData.DownID )
			AND			
			( workorderheader.componentid LIKE '%'+@ComponentID+'%')
			AND
			( workorderDownTimedetail.EmployeeID LIKE '%'+@OperatorID+'%' )	
			AND			
			(workorderDownTimedetail.timefrom>=@StartTime)
			AND
			(workorderDownTimedetail.timeto<=@EndTime)
		GROUP BY workorderheader.MachineID, workorderDownTimedetail.downid
		), 0)
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
			( workorderheader.MachineID = #DownTimeData.MachineID)
			AND
			( workorderheader.workorderno LIKE '%'+@WorkOrderNo+'%')
			AND
			( workorderDownTimedetail.downid = #DownTimeData.DownID )
			AND			
			( workorderheader.componentid LIKE '%'+@ComponentID+'%')
			AND
			( workorderDownTimedetail.EmployeeID LIKE '%'+@OperatorID+'%' )				
			AND
			(workorderDownTimedetail.timefrom<@StartTime)
			AND
			(workorderDownTimedetail.timeto<=@EndTime)
			AND
			(workorderDownTimedetail.timeto>@StartTime)
		GROUP BY workorderheader.MachineID, workorderDownTimedetail.downid
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
			( workorderheader.MachineID = #DownTimeData.MachineID)
			AND
			( workorderheader.workorderno LIKE '%'+@WorkOrderNo+'%')
			AND
			( workorderDownTimedetail.downid = #DownTimeData.DownID )
			AND			
			( workorderheader.componentid LIKE '%'+@ComponentID+'%')
			AND
			( workorderDownTimedetail.EmployeeID LIKE '%'+@OperatorID+'%' )		
			AND
			(workorderDownTimedetail.timefrom>=@StartTime)
			AND
			(workorderDownTimedetail.timefrom<@EndTime)
			AND
			(workorderDownTimedetail.timeto>@EndTime)
		GROUP BY workorderheader.MachineID, workorderDownTimedetail.downid
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
			( workorderheader.MachineID = #DownTimeData.MachineID)
			AND
			( workorderheader.workorderno LIKE '%'+@WorkOrderNo+'%')
			AND
			( workorderDownTimedetail.downid = #DownTimeData.DownID )
			AND			
			( workorderheader.componentid LIKE '%'+@ComponentID+'%')
			AND
			( workorderDownTimedetail.EmployeeID LIKE '%'+@OperatorID+'%' )
			AND
			(workorderDownTimedetail.timefrom<@StartTime)
			AND
			(workorderDownTimedetail.timeto>@EndTime)
		GROUP BY workorderheader.MachineID, workorderDownTimedetail.downid
		), 0)
*/
INSERT INTO #FinalData (MachineID, DownID, DownTime, TotalMachine, TotalDown)
select MachineID, DownID, DownTime, 0,0
from #DownTimeData
UPDATE #FinalData
SET
TotalMachine = (SELECT SUM(DownTime) FROM #FinalData as FD WHERE Fd.machineID = #FinalData.machineid),
TotalDown = (SELECT SUM(DownTime) FROM #FinalData as FD WHERE Fd.DownID = #FinalData.DownID)
--select output
select 	MachineID,
	#FinalData.DownID as DownCode,
	DownDescription as DownID,
	DownTime as DownTime,
	TotalMachine as TotalMachine,
	TotalDown as TotalDown,
	DownTime/3600 as Hours,
	@MachineIDLabel as MachineIDLabel ,
	@OperatorIDLabel  as OperatorIDLabel,
	@DownIDLabel  as DownIDLabel ,
	@ComponentIDLabel as ComponentIDLabel,
	@WorkOrderNoLabel as WorkOrderNoLabel ,
	@StartTime as StartTime,
	@EndTime as EndTime
FROM #FinalData
INNER JOIN downcodeinformation on #FinalData.DownID = Downcodeinformation.downid
WHERE (TotalDown > 0) and (TotalMachine > 0)
Order By  TotalDown desc,downcodeinformation.DownID, TotalMachine desc, machineid
END
