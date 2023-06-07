/****** Object:  Procedure [dbo].[s_mxktest_Componentwisereport]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE    PROCEDURE [dbo].[s_mxktest_Componentwisereport]
	@StartTime as DateTime ,
	@EndTime as DateTime, 
	@MachineID as nvarchar(50) = '',
	@ComponentID as nvarchar(50) = '',
	@OperatorID as nvarchar(50) = '',
	@MachineIDLabel as nvarchar(50) = 'ALL',
	@ComponentIDLabel as nvarchar(50) = 'ALL',
	@OperatorIDLabel as nvarchar(50) = 'ALL'
AS
BEGIN
declare @strsql nvarchar(2000)
declare @strMachine nvarchar(255)
declare @strOperator nvarchar(255)
declare @strcomponent nvarchar(255)

CREATE TABLE #ProductionTime( ProductionTime float, pComponentID nvarchar(50) primary key)
CREATE TABLE #DownTime ( DownTime float, AvailEffyLoss float, pComponentID nvarchar(50) primary key)
CREATE TABLE #ProductionData (
	MachineID nvarchar(50),
	OperatorID nvarchar(50),
	ComponentID nvarchar(50) primary key,
	Production float,
	Rejection float,
	CN float,
	TurnOver float,
	ProductionTime float,
	DownTime float,
	AvailabilityEfficiency float,
	ProductionEfficiency float,
	QualityEfficiency float,
	OverAllEfficiency float,	
	AvailabilityEfficiencyLoss float	
	)

----BEGIN PRODUCTION TIME CALCULATIONS-------

INSERT INTO #ProductionTime(pComponentID, ProductionTime)
SELECT DISTINCT ComponentID,0
FROM workorderheader
		INNER JOIN workorderproductiondetail
		ON workorderheader.workorderno = workorderproductiondetail.workorderno
WHERE
	(
		(workorderproductiondetail.timefrom >=@StartTime)
		AND (workorderproductiondetail.timeto <= @EndTime)
	)
OR
	(
		(workorderproductiondetail.timefrom < @StartTime)
		AND (workorderproductiondetail.timeto > @StartTime)
		AND (workorderproductiondetail.timeto <= @EndTime)
	)
OR
	(
		(workorderproductiondetail.timefrom >= @StartTime)
		AND (workorderproductiondetail.timefrom < @EndTime)
		AND (workorderproductiondetail.timeto > @EndTime)
	)
OR
	(
		(workorderproductiondetail.timefrom < @StartTime)
		AND
		(workorderproductiondetail.timeto > @EndTime)
	)
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
	select @stroperator = ' and ( workorderproductiondetail.employeeid = ''' + @OperatorID +''')'
	END
select @strsql =''
-- Type 1 - Sum of all records within the given time period
select @strsql = 'UPDATE #ProductionTime SET ProductionTime = ProductionTime +  '
select @strsql = @strsql + ' isnull( (SELECT sum(datediff(second,workorderproductiondetail.timefrom, '
select @strsql = @strsql + 'workorderproductiondetail.timeto)) FROM workorderheader  '
select @strsql = @strsql + ' INNER JOIN workorderproductiondetail '
select @strsql = @strsql + ' ON workorderheader.workorderno = workorderproductiondetail.workorderno WHERE '
select @strsql = @strsql + ' (workorderproductiondetail.timefrom>= ''' + convert(nvarchar(20),@StartTime) + ''') AND '
select @strsql = @strsql + ' (workorderproductiondetail.timeto<= ''' + convert(nvarchar(20),@EndTime) + ''') AND '
select @strsql = @strsql + ' ( workorderheader.componentid  = pComponentID ) '
select @strsql = @strsql + @strmachine + @strcomponent + @stroperator
select @strsql = @strsql + ' GROUP BY workorderheader.ComponentID ),0)'
exec (@strsql)
--SELECT top 54 pcomponentID, productiontime FROM #ProductionTime
--drop table #productiontime
--return
-- Type 2
select @strsql =''
select @strsql = 'UPDATE #ProductionTime SET ProductionTime = ProductionTime +  '
select @strsql = @strsql + ' isnull((SELECT sum(datediff(second,''' + convert(nvarchar(20),@StartTime) + ''''
select @strsql = @strsql + ',workorderproductiondetail.timeto)) FROM workorderheader  '
select @strsql = @strsql + ' INNER JOIN workorderproductiondetail '
select @strsql = @strsql + ' ON workorderheader.workorderno = workorderproductiondetail.workorderno WHERE '
select @strsql = @strsql + ' (workorderproductiondetail.timefrom < ''' + convert(nvarchar(20),@StartTime) + ''') AND '
select @strsql = @strsql + ' (workorderproductiondetail.timeto <= ''' + convert(nvarchar(20),@EndTime) + ''') AND '
select @strsql = @strsql + ' (workorderproductiondetail.timeto > ''' + convert(nvarchar(20),@StartTime) + ''') AND '
select @strsql = @strsql + ' (workorderheader.componentid  = pComponentID ) '
select @strsql = @strsql + @strmachine + @strcomponent + @stroperator
select @strsql = @strsql + ' GROUP BY workorderheader.ComponentID ),0)'
exec (@strsql)

-- Type 3
SELECT @strsql = ''
select @strsql = 'UPDATE #ProductionTime SET ProductionTime = ProductionTime +  '
select @strsql = @strsql + ' isnull( (SELECT sum(datediff(second,workorderproductiondetail.timefrom,''' + convert(nvarchar(20),@EndTime) + ''''
select @strsql = @strsql + ')) FROM workorderheader  '
select @strsql = @strsql + ' INNER JOIN workorderproductiondetail '
select @strsql = @strsql + ' ON workorderheader.workorderno = workorderproductiondetail.workorderno WHERE '
select @strsql = @strsql + ' (workorderproductiondetail.timefrom >= ''' + convert(nvarchar(20),@StartTime) + ''') AND '
select @strsql = @strsql + ' (workorderproductiondetail.timefrom < ''' + convert(nvarchar(20),@EndTime) + ''') AND '
select @strsql = @strsql + ' (workorderproductiondetail.timeto > ''' + convert(nvarchar(20),@EndTime) + ''') AND '
select @strsql = @strsql + ' ( workorderheader.componentid  = pComponentID ) '
select @strsql = @strsql + @strmachine + @strcomponent + @stroperator
select @strsql = @strsql + ' GROUP BY workorderheader.ComponentID ),0)'
exec (@strsql)
-- Type 4
SELECT @strsql = ''
select @strsql = 'UPDATE #ProductionTime SET ProductionTime = ProductionTime +  '
select @strsql = @strsql + ' isnull( (SELECT sum(datediff(second,''' + convert(nvarchar(20),@StartTime) + '''  ,''' + convert(nvarchar(20),@EndTime) + ''''
select @strsql = @strsql + ')) FROM workorderheader  '
select @strsql = @strsql + ' INNER JOIN workorderproductiondetail '
select @strsql = @strsql + ' ON workorderheader.workorderno = workorderproductiondetail.workorderno WHERE '
select @strsql = @strsql + ' (workorderproductiondetail.timefrom < ''' + convert(nvarchar(20),@StartTime) + ''') AND '
select @strsql = @strsql + ' (workorderproductiondetail.timeto > ''' + convert(nvarchar(20),@EndTime) + ''') AND '
select @strsql = @strsql + ' ( workorderheader.componentid  = pComponentID ) '
select @strsql = @strsql + @strmachine + @strcomponent + @stroperator
select @strsql = @strsql + ' GROUP BY workorderheader.ComponentID ),0)'
exec (@strsql)
--SELECT * FROM #ProductionTime
--drop table #ProductionTime

--**************END: PRODUCTION TIME CALCULATIONS************


--****************BEGIN: DOWNTIME CALCULATIONS***************

INSERT INTO #DownTime (pComponentID, DownTime, AvailEffyLoss)
SELECT Distinct ComponentID, 0,0
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

select @strsql =''
--Type 1
select @strsql = @strsql + 'UPDATE #DownTime SET DownTime = DownTime + '
select @strsql = @strsql + ' isnull((SELECT sum(datediff(second,workorderDownTimedetail.timefrom, workorderDownTimedetail.timeto))'
select @strsql = @strsql + ' FROM workorderheader INNER JOIN workorderDownTimedetail ON workorderheader.workorderno = workorderDownTimedetail.workorderno'
select @strsql = @strsql + ' WHERE ( workorderheader.componentid = pComponentID ) 	AND'
select @strsql = @strsql + ' (workorderDownTimedetail.timefrom>=''' + convert(nvarchar(20),@StartTime) + ''')'
select @strsql = @strsql + ' AND (workorderDownTimedetail.timeto<=''' + convert(nvarchar(20),@EndTime) + ''')'
select @strsql = @strsql + @strmachine + @strcomponent + @stroperator
select @strsql = @strsql + ' GROUP BY workorderheader.ComponentID),0)'
exec (@strsql)

-- Update the Availability Efficiency Losses
-- Type 1
select @strsql = ''
select @strsql = @strsql + ' UPDATE #DownTime SET AvailEffyLoss = AvailEffyLoss + '
select @strsql = @strsql + ' isnull((SELECT sum(datediff(second,workorderDownTimedetail.timefrom,  workorderDownTimedetail.timeto))'
select @strsql = @strsql + ' FROM workorderheader INNER JOIN workorderDownTimedetail ON workorderheader.workorderno = workorderDownTimedetail.workorderno '
select @strsql = @strsql + ' INNER JOIN downcodeinformation on workorderDownTimedetail.downid = downcodeinformation.downid '
select @strsql = @strsql + ' WHERE ( workorderheader.componentid = pComponentID )'
select @strsql = @strsql + ' AND (workorderDownTimedetail.timefrom>=''' + convert(nvarchar(20),@StartTime) + ''')'
select @strsql = @strsql + ' AND (workorderDownTimedetail.timeto<=''' + convert(nvarchar(20),@StartTime) + ''') AND (downcodeinformation.availeffy = 1)'
select @strsql = @strsql + @strmachine + @strcomponent + @stroperator
select @strsql = @strsql + ' GROUP BY workorderheader.ComponentID ), 0)'
exec (@strsql)

--SELECT * FROM #DownTime
--drop table #Downtime

--******************* END: DOWNTIME CALCULATIONS **************

--******************* BEGIN: PRODUCTION DATA *******************
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
select @strsql = 'INSERT INTO #ProductionData (ComponentID, Production, Rejection, CN, TurnOver)'
select @strsql = @strsql + ' SELECT  workorderheader.ComponentID, SUM(workorderproductiondetail.production) AS Production, '
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
select @strsql = @strsql + ' GROUP BY workorderheader.ComponentID'
exec (@strsql)

--UPDATE PRODUCTION TIME
UPDATE #productiondata 
   SET #productiondata.productiontime = isnull(#productiontime.productiontime,0)
  FROM #productiondata INNER JOIN #productiontime ON #productiondata.componentid = #productiontime.pcomponentid

DROP TABLE #productionTime

--UPDATE DOWN TIME
UPDATE #ProductionData 
   SET #productiondata.DownTime = isNull(#downtime.downtime,0),
	#productionData.AvailabilityEfficiencyLoss = isnull (#downtime.AvailEffyLoss,0)
  FROM #ProductionData INNER JOIN #DownTime on #ProductionData.ComponentID = #DownTime.pComponentID

DROP TABLE #DownTime

-- Calculate Availability Efficiency
UPDATE #ProductionData
SET 	AvailabilityEfficiency = isNull(((ProductionTime - AvailabilityEfficiencyLoss)- (DownTime- AvailabilityEfficiencyLoss))/(ProductionTime - AvailabilityEfficiencyLoss),0)
WHERE	ProductionTime > DownTime

-- Calculate Production Efficiency
UPDATE #ProductionData
SET ProductionEfficiency = CN/(ProductionTime - DownTime)
WHERE CN > 0 and ProductionTime > DownTime

-- Calculate Quality Efficiency
UPDATE #ProductionData
SET QualityEfficiency = (Production - Rejection)/Production
WHERE Production > 0

-- Calculate Overall Efficiency
UPDATE #ProductionData
SET OverAllEfficiency = isNull((AvailabilityEfficiency * ProductionEfficiency * QualityEfficiency),0),
ProductionTime = case when (ProductionTime - DownTime) < 0 then 0 else (productiontime - downtime) end -- (this is for displaying the actual production time only, not used by calculations)

SELECT MachineID,
	OperatorID,
	ComponentID,
	Production,
	Rejection,
	CN,
	TurnOver ,
	convert(nvarchar(6),convert(integer, ProductionTime)/3600) + ':' + convert(nvarchar(2), (convert(integer, ProductionTime)%3600)/60) + ':' + convert(nvarchar(2), convert(integer, ProductionTime)%60)  as ProductionTime,
	convert(nvarchar(6),convert(integer, DownTime)/3600) + ':' + convert(nvarchar(2), (convert(integer, DownTime)%3600)/60) + ':' + convert(nvarchar(2), convert(integer, DownTime)%60)  as DownTime,
	AvailabilityEfficiency*100 as AvailabilityEfficiency ,
	ProductionEfficiency*100 as ProductionEfficiency,
	QualityEfficiency*100 as QualityEfficiency ,
	OverAllEfficiency*100 as OverAllEfficiency ,
	@MachineIDLabel as MachineIDLabel,
	@OperatorIDLabel as OperatorIDLabel,
	@ComponentIDLabel as ComponentIDLabel,
	@StartTime as StartTime,
	@EndTime as EndTime
FROM #productiondata


drop table #productiondata

--*******************END: PRODUCTION DATA ***************


END
