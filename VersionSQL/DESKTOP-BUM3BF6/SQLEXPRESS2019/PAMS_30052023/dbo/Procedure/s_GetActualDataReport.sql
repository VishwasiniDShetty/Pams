/****** Object:  Procedure [dbo].[s_GetActualDataReport]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE   PROCEDURE [dbo].[s_GetActualDataReport]
	@StartTime DateTime,
	@EndTime DateTime,
	@MachineID  nvarchar(50) = '',	
	@OperatorID  nvarchar(50) = '',
	@ComponentID  nvarchar(50) = '',
	@WorkOrderNo nvarchar(50) = ''
AS
BEGIN
declare @strsql nvarchar(2000)
declare @strMachine nvarchar(255)
declare @strworkorder nvarchar(255)
declare @strcomponent nvarchar(255)
declare @strOperator nvarchar(255)
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
	select @stroperator = ' and ( workorderproductiondetail.employeeid = ''' + @OperatorID +''')'
	END
CREATE TABLE #ActualData
(WorkOrderNo nvarchar(50),
	WorkOrderDate datetime,
	DataType nvarchar(50),
	TimeFrom datetime,
	TimeTo datetime,
	Production float,
	Rejection float,
	OperatorID nvarchar(50),
	DownID nvarchar(50),
	DownTime float,
	MachineID nvarchar(50) )
select @strsql = ''
select @strsql = 'INSERT INTO #ActualData (WorkOrderNo, WorkOrderDate, DataType, TimeFrom, TimeTo, Production, Rejection, OperatorID, MachineID)'
select @strsql = @strsql + ' SELECT workorderproductiondetail.workorderno, workorderproductiondetail.productiondate, '
select @strsql = @strsql + ' ''Production'',workorderproductiondetail.timefrom,workorderproductiondetail.timeto, '
select @strsql = @strsql + ' workorderproductiondetail.production, workorderproductiondetail.rejection, workorderproductiondetail.employeeid,'
select @strsql = @strsql + ' workorderheader.machineid FROM workorderproductiondetail INNER JOIN'
select @strsql = @strsql + ' workorderheader ON workorderproductiondetail.workorderno = workorderheader.workorderno'
select @strsql = @strsql + ' WHERE (workorderproductiondetail.timeto <= ''' + convert(varchar(20),@EndTime) + ''')'
select @strsql = @strsql + ' AND (workorderproductiondetail.timefrom >= ''' + convert(varchar(20),@StartTime) + ''')'
select @strsql = @strsql + @strmachine + @strworkorder + @strcomponent + @stroperator
exec (@strsql)
select @strsql = ''
select @stroperator = ''
if isnull(@operatorid,'')  <> ''
	BEGIN
	select @stroperator = ' and ( workorderdowntimedetail.employeeid = ''' + @OperatorID +''')'
	END
select @strsql = ''
select @strsql = 'INSERT INTO #ActualData (WorkOrderNo, WorkOrderDate, DataType, TimeFrom, TimeTo, OperatorID, DownID, DownTime, MachineID)'
select @strsql = @strsql + ' SELECT  workorderdowntimedetail.workorderno, '
select @strsql = @strsql + ' workorderdowntimedetail.downdate, '
select @strsql = @strsql + ' ''Down'' , workorderdowntimedetail.timefrom, '
select @strsql = @strsql + ' workorderdowntimedetail.timeto,'
select @strsql = @strsql + ' workorderdowntimedetail.employeeid, '
select @strsql = @strsql + ' workorderdowntimedetail.downid,'
select @strsql = @strsql + ' datediff(second,workorderdowntimedetail.timefrom, workorderdowntimedetail.timeto),'
select @strsql = @strsql + ' workorderheader.machineid'
select @strsql = @strsql + ' FROM         workorderheader '
select @strsql = @strsql + ' INNER JOIN workorderdowntimedetail ON '
select @strsql = @strsql + ' workorderheader.workorderno = workorderdowntimedetail.workorderno '
select @strsql = @strsql + ' WHERE (workorderdowntimedetail.timeto <= ''' + convert(varchar(20),@EndTime) + ''')'
select @strsql = @strsql + ' AND (workorderdowntimedetail.timefrom >= ''' + convert(varchar(20),@StartTime) + ''')'
select @strsql = @strsql + @strmachine + @strworkorder + @strcomponent + @stroperator
exec (@strsql)
select * from #ActualData Order by WorkOrderNo, WorkOrderDate, datatype desc, TimeFrom
END
