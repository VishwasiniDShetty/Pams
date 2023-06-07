/****** Object:  Procedure [dbo].[s_GetShiftTimeSA]    Committed by VersionSQL https://www.versionsql.com ******/

/****** Object:  StoredProcedure [dbo].[s_GetShiftTimeSA]    Script Date: 06/06/2009 15:50:25 ******/

--PROCEDURE CREATED BY G.KARTHIGEYAN 
--TO GET SHIFT START TIME BY GIVING CURRENT DATE AND TIME



CREATE          PROCEDURE [dbo].[s_GetShiftTimeSA]
	@StartDateTime as datetime = '2005-1-1'
	
AS
BEGIN
declare @startdate nvarchar(20)
declare @maxdate datetime
select @startdate = CAST(datePart(yyyy,@startdatetime) AS nvarchar(4)) + '-' +
	     CAST(datePart(mm,@startdatetime) AS nvarchar(2)) + '-' +
	     CAST(datePart(dd,@startdatetime) AS nvarchar(2))
create table #temptable
(
startdatetime datetime,
ShiftName varchar(50),
StartTime datetime,
EndTime datetime
)
insert into #temptable
	select @startdatetime as startdatetime,ShiftName,
	Dateadd(DAY,FromDay,(convert(datetime, @StartDate + ' ' + CAST(datePart(hh,FromTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,FromTime) as nvarchar(2))+ ':' + CAST(datePart(ss,FromTime) as nvarchar(2))))) as StartTime,
	DateAdd(Day,ToDay,(convert(datetime, @StartDate + ' ' + CAST(datePart(hh,ToTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,ToTime) as nvarchar(2))+ ':' + CAST(datePart(ss,ToTime) as nvarchar(2))))) as EndTime
	from shiftdetails where running = 1 order by shiftid


select top 1 @maxdate = startTime from #temptable

--select StartTime from #temptable
--select * from #temptable

if  @maxdate > @StartDateTime
begin
--print 'in if'
update #temptable
set StartTime =  StartTime - 1,EndTime = EndTime   - 1

end

select * from #temptable
END
