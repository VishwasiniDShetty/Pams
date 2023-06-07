/****** Object:  Procedure [dbo].[s_GetOperatorProductionData]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE   PROCEDURE [dbo].[s_GetOperatorProductionData]
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
	workorderno nvarchar(50),
	OperatorID nvarchar(50),
	Production float,
	Rejection float,
	CN float,
	TurnOver float
	CONSTRAINT ProdData_key PRIMARY KEY (workorderno, operatorid))

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

select @strsql = 'INSERT INTO #ProdData (workorderno, operatorID, Production, Rejection, CN, TurnOver)'
select @strsql = @strsql + ' SELECT  workorderheader.workorderno, workorderproductiondetail.employeeID, SUM(workorderproductiondetail.production) AS Production, '
select @strsql = @strsql + ' ISNULL(SUM(workorderproductiondetail.rejection), 0) AS Rejection, '
select @strsql = @strsql + ' SUM(workorderheader.cycletime * workorderproductiondetail.production) AS CN, '
select @strsql = @strsql + ' SUM(workorderheader.price * (workorderproductiondetail.production - workorderproductiondetail.rejection)) AS TurnOver'
select @strsql = @strsql + ' FROM workorderheader INNER JOIN workorderproductiondetail ON workorderheader.workorderno = workorderproductiondetail.workorderno'
select @strsql = @strsql + ' WHERE (('
select @strsql = @strsql + ' (workorderproductiondetail.timefrom>=''' + convert(nvarchar(20),@StartTime) + ''') AND'
select @strsql = @strsql + ' (workorderproductiondetail.timeto<=''' + convert(nvarchar(20),@EndTime) + ''')'
select @strsql = @strsql + '  ) OR ( '
select @strsql = @strsql + ' (workorderproductiondetail.timefrom<''' + convert(nvarchar(20),@StartTime) + ''') AND'
select @strsql = @strsql + ' (workorderproductiondetail.timeto<=''' + convert(nvarchar(20),@EndTime) + ''') AND'
select @strsql = @strsql + ' (workorderproductiondetail.timeto>''' + convert(nvarchar(20),@StartTime) + ''')))'
select @strsql = @strsql + @strmachine + @stroperator + @strcomponent
select @strsql = @strsql + ' GROUP BY workorderheader.workorderno, workorderproductiondetail.employeeid'
exec (@strsql)

/*
INSERT INTO #ProductionData (OperatorID, Production, Rejection, CN, TurnOver)
SELECT  workorderproductiondetail.employeeid,
	SUM(workorderproductiondetail.production) AS Production,
	ISNULL(SUM(workorderproductiondetail.rejection), 0) AS Rejection,
	SUM(workorderheader.cycletime * workorderproductiondetail.production) AS CN,
	SUM(workorderheader.price * (workorderproductiondetail.production - workorderproductiondetail.rejection)) AS TurnOver
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
GROUP BY workorderproductiondetail.employeeid, workorderheader.workorderno
*/
-- Load the rejection count from the Work Order Rejection Details
--UPDATE #ProductionData
--SET Rejection = Rejection + isnull((

--	SELECT SUM(workorderrejectiondetail.Quantity)
--	FROM         workorderheader	
--	     INNER JOIN workorderrejectiondetail ON
--			workorderheader.workorderno = workorderrejectiondetail.workorderno
--	WHERE 	
--		( workorderheader.machineid LIKE '%'+@MachineID+'%')
--		AND
--		( workorderheader.componentid LIKE '%'+@ComponentID+'%' )
--		AND
--		( workorderrejectiondetail.employeeid LIKE '%'+#ProductionData.OperatorID+'%' )
--		AND
--		(workorderrejectiondetail.rejectiondate>=@StartTime)
--		AND
--		(workorderrejectiondetail.rejectiondate<=@EndTime)
--	GROUP BY workorderrejectiondetail.employeeid, workorderheader.workorderno
--	),0)
-- Return the totals for each operator
SELECT
	OperatorID,
	Sum(Production) as Production,
	SUM(Rejection) as Rejection,
	SUM(CN) as CN,
	SUM(TurnOver) as TurnOver
FROM #ProdData
GROUP BY OperatorID
END
