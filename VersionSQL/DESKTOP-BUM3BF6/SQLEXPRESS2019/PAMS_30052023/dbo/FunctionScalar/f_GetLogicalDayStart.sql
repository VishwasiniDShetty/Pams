/****** Object:  Function [dbo].[f_GetLogicalDayStart]    Committed by VersionSQL https://www.versionsql.com ******/

--NR0082 - KarthikR/Geetha - 10/Sep/12 :: Created New function to find logicalday start for the given timeperiod for Cummins.
create Function [dbo].[f_GetLogicalDayStart](@FromDate datetime)
RETURNS datetime
AS
BEGIN
DECLARE @StartDate as nvarchar(20)
DECLARE @ST as datetime
DECLARE @DT as datetime
if ISDATE(@FromDate) = 1
BEGIN
	 SELECT @StartDate = CAST(datePart(yyyy,@FromDate) AS nvarchar(4)) + '-' +
			    SUBSTRING(DATENAME(MONTH,@FromDate),1,3) + '-' +
		            CAST(datePart(dd,@FromDate) AS nvarchar(2))
	
		SELECT @ST = ISNULL(Dateadd(DAY,FromDay,(convert(datetime, @StartDate + ' ' + CAST(datePart(hh,FromTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,FromTime) as nvarchar(2))+ ':' + CAST(datePart(ss,FromTime) as nvarchar(2))))),(@StartDate + ' 00:00:00'))
		FROM shiftdetails								--DR0115
		WHERE (shiftid =(SELECT     min(shiftID)FROM  shiftdetails WHERE  running = 1)) and running = 1
SELECT @DT = ISNULL(Dateadd(DAY,ToDay,(convert(datetime, @StartDate + ' ' + CAST(datePart(hh,ToTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,ToTime) as nvarchar(2))+ ':' + CAST(datePart(ss,ToTime) as nvarchar(2))))),(@StartDate + ' 00:00:00'))
		FROM shiftdetails								--DR0115
		WHERE (shiftid =(SELECT     max(shiftID)FROM  shiftdetails WHERE  running = 1)) and running = 1
	 if @st>=@FromDate
begin
set @st=dateadd(day,-1,@st)
End
if @dt<@FromDate
begin
set @st=dateadd(day,1,@st)
end	
END
return @st
END
