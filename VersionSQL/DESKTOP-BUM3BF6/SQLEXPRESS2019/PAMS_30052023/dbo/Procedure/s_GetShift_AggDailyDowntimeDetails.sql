/****** Object:  Procedure [dbo].[s_GetShift_AggDailyDowntimeDetails]    Committed by VersionSQL https://www.versionsql.com ******/

--=============================================
--NR0059 By Kusuma M.H. on 29-Jul-2009.Down time Report by Category.New report on aggregated data to display downs by Machine,shift,operator and down category.
--This Procedure is used in SmartManager->Shift Aggregated Reports -> Downtime Reports -> DownTime Report By Category (Shift_AggDailyDownTimeDetailsTemplate.xls).
--=============================================

CREATE PROCEDURE [dbo].[s_GetShift_AggDailyDowntimeDetails] 
	@ddate as datetime,
	@plantid as nvarchar(50),
	@downtimeformat as nvarchar(20)
AS
BEGIN
--Temporary tables.
create table #MacShiftOpr
(
 machineid nvarchar(50),
 shift nvarchar(50),
 operatorid nvarchar(50)
)

create table #details
(
 IDD INTEGER IDENTITY (1,1),
 Rowheader nvarchar(50)
)

create table #Finaldata
(
 machineid nvarchar(50),
 shift nvarchar(50),
 operatorid nvarchar(50),
 idd INTEGER,
 Rowheader nvarchar(50),
 Rowvalue nvarchar(50),
 unfrmtrowvalue bigint,
 Total nvarchar(50)
)
Declare @strsql as nvarchar(4000)
Declare @strplantid as nvarchar(255)
select @strsql = ''
select @strplantid = ''

if isnull(@plantid,'')<>''
begin
select @StrPlantID=' AND PlantID =''' + @plantid + ''''
end


--Inserting the distinct machine,shift and operator from the shiftproductiondetails.
select @strsql = ''
select @strsql = 'insert into #MacShiftOpr select distinct machineid,shift,operatorid '
select @strsql = @strsql + ' from shiftproductiondetails where pdate = ''' + convert(nvarchar(20),@dDate) + ''' '
select @strsql = @strsql + @strplantid
exec(@strsql)
select @strsql = ''
--Inserting the distinct machine,shift and operator from the shiftdowntimedetails.
select @strsql = 'insert into #MacShiftOpr select distinct machineid,shift,operatorid '
select @strsql = @strsql + ' from shiftdowntimedetails where ddate = ''' + convert(nvarchar(20),@dDate) + ''' ' 
select @strsql = @strsql + @strplantid
exec(@strsql)
print @strsql


--Inserting the rowheaders.
--First one the Prod_Qty
insert into #details(Rowheader) values('Prod_Qty') 
--Next the selected downcategories in the user preferred order.
insert into #details(Rowheader) select valueintext from shopdefaults 
where parameter = 'DownTimeReportByCategory' and valueinint > 0 order by valueinint

--Inserting the finaldata from the above temp tables.
insert into #Finaldata(machineid,shift,operatorid,idd,Rowheader)  
select distinct * from #MacShiftOpr cross join #details

--Updating the values for Prod_qty.
select @strsql = @strsql + 'update #Finaldata set Rowvalue = t1.Prod_qty, unfrmtrowvalue=t1.Prod_qty from (select machineid,shift,operatorid,sum(prod_qty) as Prod_qty '
select @strsql = @strsql + ' from shiftproductiondetails where pdate = ''' + convert(nvarchar(20),@dDate) + ''' '
select @strsql = @strsql + @strplantid
select @strsql = @strsql + ' group by machineid,shift,operatorid) as t1 inner join #Finaldata '
select @strsql = @strsql + ' on t1.machineid = #Finaldata.machineid and t1.shift = #Finaldata.shift and t1.operatorid = #Finaldata.operatorid '
select @strsql = @strsql + ' where Rowheader = ''Prod_Qty'' '
exec(@strsql)
select @strsql = ''


select @strsql = ''
--Updating the values for downcategories after formatting based on the downtime format.
select @strsql = @strsql + 'update #Finaldata set unfrmtrowvalue = isnull(t1.downtime,0),rowvalue = dbo.f_FormatTime(t1.downtime,''' + @downtimeformat + ''') from '
select @strsql = @strsql + '(select machineid,shift,operatorid,downcategory,sum(downtime) as downtime from shiftdowntimedetails '
select @strsql = @strsql + ' where ddate = ''' + convert(nvarchar(20),@dDate) + ''' '
select @strsql = @strsql + @strplantid
select @strsql = @strsql + ' group by machineid,shift,operatorid,downcategory) as t1 inner join #Finaldata ' 
select @strsql = @strsql + ' on t1.machineid = #Finaldata.machineid and t1.shift = #Finaldata.shift and t1.operatorid = #Finaldata.operatorid '
select @strsql = @strsql + ' and t1.downcategory = #Finaldata.Rowheader where Rowheader <> ''Prod_Qty'' '
exec(@strsql)
select @strsql = ''

--Updating the values for total for Prod_Qty and the downcategories.
UPDATE #FinalData
SET Total = (SELECT SUM(unfrmtrowvalue) FROM #FinalData as FD WHERE Fd.machineid = #FinalData.machineid 
and Fd.rowheader = #FinalData.rowheader)

select machineid,shift,operatorid,rowheader,isnull(rowvalue,0) as rowvalue,
isnull(case when rowheader = 'Prod_Qty' then Total else dbo.f_FormatTime(total,@downtimeformat) end,0) as total
from #Finaldata order by machineid,shift,operatorid,idd

END
