/****** Object:  Function [dbo].[s_FunCurrentShiftTime]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE FUNCTION [dbo].[s_FunCurrentShiftTime]
(
@startdatetime as datetime,
@Shift as nvarchar(20) = ''
)
 returns @temp table
(startdatetime datetime, ShiftName nvarchar(101), StartTime datetime,EndTime datetime)
AS
BEGIN
	declare @startdate nvarchar(20)
	SET @startdate = CAST(datePart(yyyy,@startdatetime) AS nvarchar(4)) + '-' + 
	     CAST(datePart(mm,@startdatetime) AS nvarchar(2)) + '-' + 
	     CAST(datePart(dd,@startdatetime) AS nvarchar(2))



     if ISNULL(@Shift,'') = '' 
		insert @temp(startdatetime,ShiftName,StartTime,EndTime)
		select @startdatetime as startdatetime,ShiftName,
		Dateadd(DAY,FromDay,(convert(datetime, @StartDate + ' ' + CAST(datePart(hh,FromTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,FromTime) as nvarchar(2))+ ':' + CAST(datePart(ss,FromTime) as nvarchar(2))))) as StartTime,
		DateAdd(Day,ToDay,(convert(datetime, @StartDate + ' ' + CAST(datePart(hh,ToTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,ToTime) as nvarchar(2))+ ':' + CAST(datePart(ss,ToTime) as nvarchar(2))))) as EndTime
		from shiftdetails where running = 1 order by shiftid
     ELSE
		insert @temp(startdatetime,ShiftName,StartTime,EndTime)
		select @startdatetime as startdatetime,ShiftName,
		Dateadd(DAY,FromDay,(convert(datetime, @StartDate + ' ' + CAST(datePart(hh,FromTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,FromTime) as nvarchar(2))+ ':' + CAST(datePart(ss,FromTime) as nvarchar(2))))) as StartTime,
		DateAdd(Day,ToDay,(convert(datetime, @StartDate + ' ' + CAST(datePart(hh,ToTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,ToTime) as nvarchar(2))+ ':' + CAST(datePart(ss,ToTime) as nvarchar(2))))) as EndTime
		from shiftdetails where running = 1 and shiftName = @Shift order by shiftid

  return;
end
