/****** Object:  Procedure [dbo].[s_GetShiftwiseComponentOperations]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE  PROCEDURE [dbo].[s_GetShiftwiseComponentOperations]
	@PDate as smalldatetime,
	@shift as nvarchar(50),
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
CREATE TABLE #ProdData (
	MachineID nvarchar(50),
	ComponentID nvarchar(50),
	Operationno smallint,
	OperatorID nvarchar(50),
	Production float,
	Rejection float,
	Downtime float
	)
--CONSTRAINT ProdData_key PRIMARY KEY (ProductionDate, Machineid,Componentid,Operationid)
-- Load the Production, Rejection, CN and Turnover from Work Order Production Details
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
select @strsql = 'INSERT INTO #ProdData (ComponentID,Operationno, OperatorID, Production, Rejection)'
select @strsql = @strsql + ' SELECT  workorderheader.componentid, workorderheader.operationno, workorderproductiondetail.employeeid,'
select @strsql = @strsql + 'isnull(sum(workorderproductiondetail.production),0) AS Production, '
select @strsql = @strsql + ' ISNULL(sum(workorderproductiondetail.rejection),0) AS Rejection '
select @strsql = @strsql + ' FROM workorderheader INNER JOIN workorderproductiondetail ON
workorderheader.workorderno = workorderproductiondetail.workorderno'
select @strsql = @strsql + ' WHERE (('
select @strsql = @strsql + ' (workorderproductiondetail.timefrom>=''' + convert(nvarchar(20),@StartTime) + ''')
AND'
select @strsql = @strsql + ' (workorderproductiondetail.timeto<=''' + convert(nvarchar(20),@EndTime) + ''')'
select @strsql = @strsql + '  ) OR ( '
select @strsql = @strsql + ' (workorderproductiondetail.timefrom<''' + convert(nvarchar(20),@StartTime) + ''')
AND'
select @strsql = @strsql + ' (workorderproductiondetail.timeto<=''' + convert(nvarchar(20),@EndTime) + ''')
AND'
select @strsql = @strsql + ' (workorderproductiondetail.timeto>''' + convert(nvarchar(20),@StartTime) + ''')))'
select @strsql = @strsql + @strmachine + @stroperator + @strcomponent
select @strsql = @strsql + ' GROUP BY workorderheader.componentid, workorderheader.operationno, workorderproductiondetail.employeeid '
--print @strsql
exec (@strsql)
--String the Operators together
DECLARE CurEnames CURSOR FOR
SELECT DISTINCT operatorid
FROM #ProdData
OPEN CurEnames
DECLARE @ename nvarchar(10)
DECLARE @shift_ename nvarchar(50)
SET @ename = ' '
SET @shift_ename = ''
FETCH NEXT FROM CurEnames INTO @ename
WHILE @@FETCH_STATUS = 0
BEGIN
if @shift_ename = ''
	select @shift_ename = @ename
else
	select @shift_ename = @shift_ename + '-' + @ename
-- This is executed as long as the previous fetch succeeds.
FETCH NEXT FROM CurEnames INTO @ename
END
CLOSE CurEnames
DEALLOCATE CurEnames
Update #ProdData set operatorid = isnull(@shift_ename,'-')
--DOWNTIME
Declare @Downtime float
if isnull(@operatorid, '') <> ''
	begin
	select @stroperator = ' AND ( workorderdowntimedetail.employeeid = ''' + @operatorid + ''')'
	end
select @strsql = ''
select @strsql = @strsql + 'insert #downdata(downtime) SELECT isnull(sum(datediff(s, workorderDownTimedetail.timefrom, workorderDownTimedetail.timeto)),0)'
select @strsql = @strsql + ' FROM workorderheader INNER JOIN workorderDownTimedetail ON workorderheader.workorderno = workorderDownTimedetail.workorderno where'
select @strsql = @strsql + ' (workorderDownTimedetail.timefrom>=''' + convert(nvarchar(20),@StartTime) + ''')'
select @strsql = @strsql + ' AND (workorderDownTimedetail.timeto<=''' + convert(nvarchar(20),@EndTime) + ''')'
select @strsql = @strsql + @strmachine + @strcomponent + @stroperator
CREATE TABLE #Downdata (
	Downtime float
)
--insert #Downdata(Downtime)
exec(@strsql)
update #ProdData set downtime = (select isnull(downtime,0) from #downdata)
drop table #Downdata
select @Pdate , @shift, componentid, operationno,
	Sum(Production) as Production,
	SUM(Rejection) as Rejection,
	OperatorID,
	Downtime
FROM #ProdData
GROUP BY Componentid, Operationno, Operatorid, Downtime
Drop table #ProdData
END
