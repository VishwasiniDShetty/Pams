/****** Object:  Procedure [dbo].[s_GetShiftTime]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE     PROCEDURE [dbo].[s_GetShiftTime]
	@StartDateTime as datetime = '2005-1-1',
	@Shift as nvarchar(20) = ''
AS
BEGIN
declare @startdate nvarchar(20)
select @startdate = CAST(datePart(yyyy,@startdatetime) AS nvarchar(4)) + '-' + 
	     CAST(datePart(mm,@startdatetime) AS nvarchar(2)) + '-' + 
	     CAST(datePart(dd,@startdatetime) AS nvarchar(2))

     if ISNULL(@Shift,'') = '' 
	select @startdatetime as startdatetime,ShiftName,
	Dateadd(DAY,FromDay,(convert(datetime, @StartDate + ' ' + CAST(datePart(hh,FromTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,FromTime) as nvarchar(2))+ ':' + CAST(datePart(ss,FromTime) as nvarchar(2))))) as StartTime,
	DateAdd(Day,ToDay,(convert(datetime, @StartDate + ' ' + CAST(datePart(hh,ToTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,ToTime) as nvarchar(2))+ ':' + CAST(datePart(ss,ToTime) as nvarchar(2))))) as EndTime
	from shiftdetails where running = 1 order by shiftid
     ELSE
	select @startdatetime as startdatetime,ShiftName,
	Dateadd(DAY,FromDay,(convert(datetime, @StartDate + ' ' + CAST(datePart(hh,FromTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,FromTime) as nvarchar(2))+ ':' + CAST(datePart(ss,FromTime) as nvarchar(2))))) as StartTime,
	DateAdd(Day,ToDay,(convert(datetime, @StartDate + ' ' + CAST(datePart(hh,ToTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,ToTime) as nvarchar(2))+ ':' + CAST(datePart(ss,ToTime) as nvarchar(2))))) as EndTime
	from shiftdetails where running = 1 and shiftName = @Shift order by shiftid
END
