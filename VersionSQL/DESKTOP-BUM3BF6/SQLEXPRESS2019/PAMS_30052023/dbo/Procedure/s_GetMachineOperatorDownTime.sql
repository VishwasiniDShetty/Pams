/****** Object:  Procedure [dbo].[s_GetMachineOperatorDownTime]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE    PROCEDURE [dbo].[s_GetMachineOperatorDownTime]
	@StartTime as DateTime,
	@EndTime as DateTime,
	@MachineID as nvarchar(50) = '',
	@ComponentID nvarchar(50) = '',
	@OperatorID nvarchar(50) = '',
	@DownID nvarchar(50) = '',
	@MachineIDLabel as nvarchar(50) = 'ALL',
	@ComponentIDLabel nvarchar(50) = 'ALL',
	@OperatorIDLabel nvarchar(50) = 'ALL',
	@DownIDLabel nvarchar(50) = 'ALL'
AS
BEGIN
declare @strsql nvarchar(2000)
declare @strmachine nvarchar(255)
declare @stroperator nvarchar(255)
declare @strcomponent nvarchar(255)
declare @strdown nvarchar(255)

CREATE TABLE #DownTime ( pMachineID nvarchar(50), pOperatorID nvarchar(50), DownTime float)

--INSERT INTO #DownTime ( pMachineID, pOperatorID, DownTime )
--SELECT  MachineID ,0,0,0 FROM MachineInformation

-- set machine and operator filters where required
select @strmachine = ''
select @stroperator = ''
select @strcomponent = ''
select @strdown = ''

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
if isnull(@downid,'')  <> ''
	BEGIN
	select @strdown = ' and ( workorderdowntimedetail.downid = ''' + @downid +''')'
	END


--Type 1
select @strsql =''
select @strsql = @strsql + 'insert #DownTime( pMachineID, pOperatorID, DownTime ) '
select @strsql = @strsql + ' (SELECT workorderheader.machineid, workorderdowntimedetail.employeeid, sum(datediff(second,workorderDownTimedetail.timefrom, workorderDownTimedetail.timeto))'
select @strsql = @strsql + ' as totaltime FROM workorderheader INNER JOIN workorderDownTimedetail ON workorderheader.workorderno = workorderDownTimedetail.workorderno where'
select @strsql = @strsql + ' (workorderDownTimedetail.timefrom>=''' + convert(nvarchar(20),@StartTime) + ''')'
select @strsql = @strsql + ' AND (workorderDownTimedetail.timeto<=''' + convert(nvarchar(20),@EndTime) + ''')'
select @strsql = @strsql + @strmachine + @strcomponent + @stroperator + @strdown
select @strsql = @strsql + ' GROUP BY workorderheader.machineID, workorderdowntimedetail.employeeid )'
exec (@strsql)


SELECT pmachineid, poperatorid, downtime, downtime/3600 as hours, @starttime as starttime, @endtime as endtime, @machineidlabel as machineidlabel, @componentidlabel as componentidlabel, @operatoridlabel as operatoridlabel, @downidlabel as downidlabel FROM #DownTime where downtime > 0 order by pmachineid, poperatorid 
END
