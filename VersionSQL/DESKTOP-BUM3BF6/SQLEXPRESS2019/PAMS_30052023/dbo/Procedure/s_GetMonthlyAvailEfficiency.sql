/****** Object:  Procedure [dbo].[s_GetMonthlyAvailEfficiency]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE  PROCEDURE [dbo].[s_GetMonthlyAvailEfficiency]
	@StartTime DateTime,
	@EndTime DateTime,
	@MachineID  nvarchar(50) = '',
	@ComponentID  nvarchar(50) = '',
	@OperatorID  nvarchar(50) = '',
	@MachineIDLabel nvarchar(50) ='ALL',
	@ComponentIDLabel nvarchar(50) = 'ALL',
	@OperatorIDLabel nvarchar(50) = 'ALL'
AS
BEGIN

declare @strsql nvarchar(2000)
declare @strmachine nvarchar(255)
declare @stremployee nvarchar(255)
declare @strcomponentid nvarchar(255)
 
select @strsql = ''
select @strmachine = ''
select @strcomponentid = ''
select @stremployee = ''
if isnull(@machineid,'') <> ''
	begin
	select @strmachine = ' and ( workorderheader.MachineID = ''' + @MachineID + ''')'
	end
if isnull(@componentid,'') <> ''
	begin
	select @strcomponentid = ' AND ( workorderheader.componentid = ''' + @componentid + ''')'
	end
if isnull(@operatorid, '') <> ''
	begin
	select @stremployee = ' AND ( workorderproductiondetail.employeeid = ''' +@OperatorID +''')'
	end

-- Create temporary table to store the report data
CREATE TABLE #DownTimeData ( 	
	dyear int,
	dmonth int,
	ProdTime float,
	DownTime float,
        ML float,
	Availeffy decimal(6,2)
	CONSTRAINT DownTimeData_key PRIMARY KEY (dyear,dmonth))

-- ProductionTime 
-- Type 1
select @strsql = 'INSERT INTO  #DownTimeData (dyear,dmonth,ProdTime,Downtime,ML,Availeffy) '
select @strsql = @strsql +  ' SELECT year(productiondate), month(productiondate), isnull(sum(datediff(second,workorderproductiondetail.timefrom, workorderproductiondetail.timeto)), 0), 0, 0,0'
select @strsql = @strsql +  ' FROM workorderheader INNER JOIN workorderProductiondetail ON workorderheader.workorderno = workorderProductiondetail.workorderno'
select @strsql = @strsql +  ' WHERE '
select @strsql = @strsql +  ' (workorderProductiondetail.timefrom >= ''' + convert(varchar(20),@StartTime) + ''')   AND (workorderProductiondetail.timeto <= ''' + convert(varchar(20),@EndTime) + ''')'
select @strsql = @strsql + @strmachine  + @strcomponentid + @stremployee
select @strsql = @strsql +  ' GROUP BY year(workorderProductiondetail.ProductionDate), month(workorderProductiondetail.ProductionDate)'
--print @strsql
exec (@strsql)



--DownTime
--redefine operator part
if isnull(@operatorid, '') <> ''
	begin
	select @stremployee = ' AND ( workorderdowntimedetail.employeeid = ''' +@OperatorID +''')'
	end

select @strsql =''
select @strsql = 'UPDATE #DownTimeData SET DownTime = isnull(DownTime,0) + isnull(t2.totaltime,0)'
select @strsql = @strsql + ' from '
select @strsql = @strsql + ' (SELECT year(downdate) dyear, month(downdate) dmonth, isnull(sum(datediff(second,workorderDownTimedetail.timefrom, workorderDownTimedetail.timeto)),0)'
select @strsql = @strsql + ' totaltime FROM workorderheader INNER JOIN workorderDownTimedetail ON workorderheader.workorderno = workorderDownTimedetail.workorderno where'
select @strsql = @strsql + ' (workorderDownTimedetail.timefrom>=''' + convert(nvarchar(20),@StartTime) + ''')'
select @strsql = @strsql + ' AND (workorderDownTimedetail.timeto<=''' + convert(nvarchar(20),@EndTime) + ''')'
select @strsql = @strsql + @strmachine + @strcomponentid + @stremployee
select @strsql = @strsql + ' GROUP BY year(workorderDownTimedetail.DownDate), month(workorderDownTimedetail.DownDate )) as t2 inner join #downtimedata on t2.dyear = #downtimedata.dyear and t2.dmonth = #downtimedata.dmonth'
--print @strsql
exec (@strsql)


-- Management Losses 
-- Type 1
select @strsql =''
select @strsql = 'Update #DownTimeData SET ML = isnull(ML,0) + isnull(t2.totaltime,0) '
select @strsql = @strsql + ' from '
select @strsql = @strsql +  ' (SELECT year(downdate) dyear, month(downdate) dmonth, isnull(sum(datediff(second,workorderdowntimedetail.timefrom, workorderDownTimedetail.timeto)),0)'
select @strsql = @strsql +  ' totaltime FROM workorderheader INNER JOIN workorderDownTimedetail ON workorderheader.workorderno = workorderDownTimedetail.workorderno'
select @strsql = @strsql +  ' INNER JOIN downcodeinformation ON workorderDownTimedetail.downid = downcodeinformation.downid'
select @strsql = @strsql +  ' WHERE '
select @strsql = @strsql +  ' (workorderDownTimedetail.timefrom >= ''' + convert(varchar(20),@StartTime) + ''')   AND 	(workorderDownTimedetail.timeto <= ''' + convert(varchar(20),@EndTime) + ''')'
select @strsql = @strsql +  ' AND (downcodeinformation.availeffy = 1)'
select @strsql = @strsql + @strmachine  + @strcomponentid + @stremployee
select @strsql = @strsql +  ' GROUP BY year(workorderDownTimedetail.DownDate), month(workorderDownTimedetail.DownDate)) as t2 inner join #downtimedata on t2.dyear = #downtimedata.dyear and t2.dmonth = #downtimedata.dmonth'
--print @strsql
exec (@strsql)

--calculate Availeffy
UPDATE #DownTimeData
SET 	AvailEffy = ((ProdTime - ML)- (DownTime - ML))*100/(ProdTime - ML)
WHERE	ProdTime > DownTime


select *, datename(month,convert(datetime, '2004-'+convert(char,dmonth)+'-01', 120)) as PlotMonth,
	convert(datetime, convert(char,dyear)+ '-' + convert(char,dmonth)+'-'+'01',120) as PlotDate,
	@MachineIDLabel as MachineIDLabel,
	@ComponentIDLabel as ComponentIDLabel,
	@OperatorIDLabel as OperatorIDLabel
 from #downtimedata
--return

/*
select 	dateadd(second, DownTime, '1900-1-1 00:00:00') as Time,
	(DownTime/3600) as Hours ,
	@StartTime as StartTime,
	@EndTime as EndTime,
       	@MachineIDLabel as MachineIDLabel,
	@OperatorIDLabel as OperatorIDLabel,
	@ComponentIDLabel as ComponentIDLabel
	from #DownTimeData
where downtime <> 0
order by dDate
*/

END
