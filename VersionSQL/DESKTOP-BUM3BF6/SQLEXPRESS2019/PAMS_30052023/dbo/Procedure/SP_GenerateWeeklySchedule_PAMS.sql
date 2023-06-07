/****** Object:  Procedure [dbo].[SP_GenerateWeeklySchedule_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

/*
SP_GenerateWeeklySchedule_PAMS 'T4010760','2023','03','',''
*/
CREATE PROCEDURE [dbo].[SP_GenerateWeeklySchedule_PAMS]
@PartID NVARchar(50)='',
@Year nvarchar(4)='',
@MonthValue nvarchar(4)='',
@WeekNumber nvarchar(10)='',
@Param nvarchar(50)=''
as
begin
declare @strsql nvarchar(max)
declare @strPartID nvarchar(max)
declare @strYear nvarchar(2000)
declare @strMonthValue nvarchar(2000)
declare @strWeekNumber nvarchar(2000)

select @strsql=''
select @strPartID=''
select @strYear=''
select @strMonthValue=''
select @strWeekNumber=''

if isnull(@PartID,'')<>''
begin
	select @strPartID='And Partid=N'''+@PartID+''''
end

if isnull(@Year,'')<>''
begin
	select @strYear='And YearNo=N'''+@Year+''''
end

if isnull(@MonthValue,'')<>''
begin
	select @strMonthValue='And MonthVal=N'''+@MonthValue+''''
end

if isnull(@WeekNumber,'')<>''
begin
	select @strWeekNumber='And WeekNumber=N'''+@WeekNumber+''''
end

create table #CalenderTemp
(
Year NVARCHAR(4),
MonthValue nvarchar(4),
WeekNumber nvarchar(10),
Date datetime
)

create table #MonthlyScheduleTemp
(
CustomerID NVARCHAR(50),
PartID NVARCHAR(50),
Year nvarchar(4),
MonthValue nvarchar(10),
MonthlyPlannedQty float
)

create table #DayWisePlanQty
(
CustomerID nvarchar(50),
PartID NVARCHAR(50),
YearNo nvarchar(4),
MonthValue nvarchar(4),
WeekNumber nvarchar(4),
Date datetime,
Holiday nvarchar(50),
CountOfWeeksInMonth float,
CountOfDaysInmOnth float,
MonthlyPlnQty float,
WeeklyPlnQty float,
DayWisePlnqty float,
)

-----------------------------------------------------------------Generate Calender table starts-----------------------------------------------------------------------------
	
	select @strsql=''
	select @strsql=@strsql+'Insert into #CalenderTemp(Year,MonthValue,WeekNumber,Date) '
	select @strsql=@strsql+'select distinct YearNo,MonthVal,WeekNumber,weekDate from calender where 1=1  '
	select @strsql=@strsql+@strYear+@strMonthValue
	print(@strsql)
	exec(@strsql)

	select @strsql=''
	select @strsql=@strsql+'Insert into #MonthlyScheduleTemp(CustomerID,PartID,Year,MonthValue,MonthlyPlannedQty) '
	select @strsql=@strsql+'select distinct CustomerID,PartID,YearNo,MonthVal,PlannedQty from MonthlyScheduleDetails_Pams where 1=1 '
	select @strsql=@strsql+@strYear+@strMonthValue
	print(@strsql)
	exec(@strsql)


	insert into #DayWisePlanQty(CustomerID,PartID,YearNo,MonthValue,WeekNumber,Date,MonthlyPlnQty)
	select distinct M1.CustomerID,M1.PartID,M1.Year,M1.MonthValue,C1.WeekNumber,C1.Date,M1.MonthlyPlannedQty from #MonthlyScheduleTemp m1 
	cross join #CalenderTemp c1 
	where C1.Year=M1.Year AND('0'+c1.MonthValue)=M1.MonthValue


	update #DayWisePlanQty set Holiday=isnull(t1.Reason,'')
	from
	(select distinct holiday,'Holiday' as Reason from HolidayList_PAMS 
	)t1 inner join #DayWisePlanQty on #DayWisePlanQty.Date=t1.holiday


	update #DayWisePlanQty set Holiday=isnull(t1.Reason,'')
	from
	(select distinct date, 'Holiday' as Reason from #DayWisePlanQty where datename(weekday,Date)='Sunday'
	)t1 inner join #DayWisePlanQty on #DayWisePlanQty.Date=t1.Date



	update #DayWisePlanQty set CountOfDaysInmOnth=isnull(t1.countinno,'')
	from
	(select distinct CustomerID,PartID,YearNo,MonthValue,count(distinct date) as countinno  from #DayWisePlanQty
	where isnull(Holiday,'')<>'Holiday'
	group by CustomerID,PartID,YearNo,MonthValue
	)t1 inner join #DayWisePlanQty on #DayWisePlanQty.CustomerID=t1.CustomerID and #DayWisePlanQty.PartID=t1.PartID and #DayWisePlanQty.YearNo=t1.YearNo and 
	#DayWisePlanQty.MonthValue=t1.MonthValue 

	update #DayWisePlanQty set CountOfWeeksInMonth=isnull(t1.countinno,'')
	from
	(select distinct CustomerID,PartID,YearNo,MonthValue,count(distinct weekNumber) as countinno  from #DayWisePlanQty
	group by CustomerID,PartID,YearNo,MonthValue
	)t1 inner join #DayWisePlanQty on #DayWisePlanQty.CustomerID=t1.CustomerID and #DayWisePlanQty.PartID=t1.PartID and #DayWisePlanQty.YearNo=t1.YearNo and 
	#DayWisePlanQty.MonthValue=t1.MonthValue


	update #DayWisePlanQty set WeeklyPlnQty=(t1.weeklyplnqty)
	from
	(select distinct CustomerID,PartID,YearNo,MonthValue, case when isnull(CountOfWeeksInMonth,0)>0 then (MonthlyPlnQty/CountOfWeeksInMonth) else '0' end as weeklyplnqty from #DayWisePlanQty
	) t1 inner join #DayWisePlanQty on #DayWisePlanQty.CustomerID=t1.CustomerID and #DayWisePlanQty.PartID=t1.PartID and  #DayWisePlanQty.YearNo=t1.YearNo 
	and #DayWisePlanQty.MonthValue=t1.MonthValue 



	--update #DayWisePlanQty set DayWisePlnqty=(t1.DayWisePlanqty)
	--from
	--(select distinct CustomerID,PartID,YearNo,MonthValue,WeekNumber,date, case when isnull(CountOfDaysInWeek,0)>0 then (WeeklyPlnQty/CountOfDaysInWeek) else '0' end as DayWisePlanqty from #DayWisePlanQty
	--) t1 inner join #DayWisePlanQty on #DayWisePlanQty.CustomerID=t1.CustomerID and #DayWisePlanQty.PartID=t1.PartID and  #DayWisePlanQty.YearNo=t1.YearNo 
	--and #DayWisePlanQty.MonthValue=t1.MonthValue and #DayWisePlanQty.WeekNumber=t1.WeekNumber and #DayWisePlanQty.Date=t1.Date


		update #DayWisePlanQty set DayWisePlnqty=(t1.DayWisePlanqty)
	from
	(select distinct CustomerID,PartID,YearNo,MonthValue, case when isnull(CountOfDaysInmOnth,0)>0 then (MonthlyPlnQty/CountOfDaysInmOnth) else '0' end as DayWisePlanqty from #DayWisePlanQty
	) t1 inner join #DayWisePlanQty on #DayWisePlanQty.CustomerID=t1.CustomerID and #DayWisePlanQty.PartID=t1.PartID and  #DayWisePlanQty.YearNo=t1.YearNo 
	and #DayWisePlanQty.MonthValue=t1.MonthValue 



	delete from #DayWisePlanQty where isnull(Holiday,'')='Holiday'



	INSERT INTO DayWiseScheduleDetails_PAMS(CustomerID,PartID,Year,MonthValue,WeekNumber,Date,PlannedQty,UpdatedBy,UpdatedTS)
	select CustomerID ,PartID ,YearNo,MonthValue,WeekNumber,Date,DayWisePlnqty as DayWisePlanqty,'AutoSchedule' as UpdatedBy,getdate() from #DayWisePlanQty d1
	where not exists(select CustomerID ,PartID ,YearNo,MonthValue,WeekNumber,Date from DayWiseScheduleDetails_PAMS d2 where d1.CustomerID=d2.CustomerID and d1.PartID=d2.PartID
	and d1.YearNo=d2.Year and d1.MonthValue=d2.MonthValue and d1.WeekNumber=d2.WeekNumber and d1.Date=d2.Date)

end
