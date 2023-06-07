/****** Object:  Function [dbo].[f_GetLogicalDay]    Committed by VersionSQL https://www.versionsql.com ******/

/*
DR0115 - Altered By KarthikG on 16-Jun-2008 :: "and running = 1" has been added in outer query
*/



CREATE         Function [dbo].[f_GetLogicalDay](@FromDate datetime,@Format as nvarchar(8))
RETURNS nvarchar(20)
AS
BEGIN
DECLARE @StartDate as nvarchar(20)
DECLARE @ST as datetime
  if ISDATE(@FromDate) = 1 
  BEGIN
	 SELECT @StartDate = CAST(datePart(yyyy,@FromDate) AS nvarchar(4)) + '-' + 
			    SUBSTRING(DATENAME(MONTH,@FromDate),1,3) + '-' + 
		            CAST(datePart(dd,@FromDate) AS nvarchar(2))
         
	if (@Format = 'start')
	Begin
		SELECT @ST = ISNULL(Dateadd(DAY,FromDay,(convert(datetime, @StartDate + ' ' + CAST(datePart(hh,FromTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,FromTime) as nvarchar(2))+ ':' + CAST(datePart(ss,FromTime) as nvarchar(2))))),(@StartDate + ' 00:00:00'))
		FROM shiftdetails								--DR0115
		WHERE (shiftid =(SELECT     min(shiftID)FROM  shiftdetails WHERE  running = 1)) and running = 1
	end
	if (@Format = 'end')
	Begin
		SELECT @ST = ISNULL(Dateadd(DAY,ToDay,(convert(datetime, @StartDate + ' ' + CAST(datePart(hh,ToTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,ToTime) as nvarchar(2))+ ':' + CAST(datePart(ss,ToTime) as nvarchar(2))))),(@StartDate + ' 23:59:59'))
		FROM  shiftdetails								--DR0115
		WHERE  (shiftid =(SELECT     Max(shiftID)FROM  shiftdetails WHERE running = 1)) and running = 1
	end
  END
  RETURN CAST(datePart(yyyy,@ST) AS nvarchar(4)) + '-' + 
	 SUBSTRING(DATENAME(MONTH,@ST),1,3) + '-' + 
	 CAST(datePart(dd,@ST) AS nvarchar(2)) + ' ' +
	 CAST(datePart(hh,@ST) AS nvarchar(2)) + ':' + 
	 CAST(datePart(mi,@ST) as nvarchar(2))+ ':' + 
         CAST(datePart(ss,@ST) as nvarchar(2))

END
/*
ALTER   Function dbo.f_GetLogicalDay(@FromDate datetime,@Format as nvarchar(8))
RETURNS datetime
AS
BEGIN
DECLARE @StartDate as nvarchar(20)
DECLARE @ST as datetime
DECLARE @ND as datetime
SELECT @StartDate = CAST(datePart(yyyy,@FromDate) AS nvarchar(4)) + '-' + CAST(datePart(mm,@FromDate) AS nvarchar(2)) + '-' +CAST(datePart(dd,@FromDate) AS nvarchar(2))
if (@Format = 'start')
Begin
	SELECT @ST = ISNULL(Dateadd(DAY,FromDay,(convert(datetime, @StartDate + ' ' + CAST(datePart(hh,FromTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,FromTime) as nvarchar(2))+ ':' + CAST(datePart(ss,FromTime) as nvarchar(2))))),(@StartDate + ' 00:00:00'))
	FROM shiftdetails
	WHERE (shiftid =(SELECT     min(shiftID)FROM  shiftdetails WHERE  running = 1))
	RETURN @ST
end
if (@Format = 'end')
Begin
	SELECT @ST = ISNULL(Dateadd(DAY,ToDay,(convert(datetime, @StartDate + ' ' + CAST(datePart(hh,ToTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,ToTime) as nvarchar(2))+ ':' + CAST(datePart(ss,ToTime) as nvarchar(2))))),(@StartDate + ' 23:59:59'))
	FROM  shiftdetails
	WHERE  (shiftid =(SELECT     Max(shiftID)FROM  shiftdetails WHERE running = 1))
	RETURN @ST
end
RETURN @StartDate
END

*/
