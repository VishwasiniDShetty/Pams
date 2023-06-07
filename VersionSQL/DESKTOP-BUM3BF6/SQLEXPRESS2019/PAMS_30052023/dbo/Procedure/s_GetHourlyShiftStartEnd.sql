/****** Object:  Procedure [dbo].[s_GetHourlyShiftStartEnd]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		G
-- Create date: 05-Feb-2018
-- Description: Fetch Start and End time from ShiftHourDefinition
-- =============================================
CREATE PROCEDURE [dbo].[s_GetHourlyShiftStartEnd]
	@dt datetime
/*
-- may have some problem when hour start and end are like 23:30:00 and 00:30:00 and the proc parameter is like '2018-03-01 00:15:00'
exec s_GetHourlyShiftStartEnd '2018-02-28 23:45:00'
exec s_GetHourlyShiftStartEnd '2018-03-01 01:45:00'
exec s_GetHourlyShiftStartEnd '2018-03-01 01:05:00'
*/
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	select DATEADD(dd, 0, DATEDIFF(dd, 0, @dt))+ convert(varchar(8), HourStart, 108) HourStart, DATEADD(dd, case when datepart(hour, HourEnd) = 0 then 1 else 0 end, DATEDIFF(dd, 0, @dt))+ convert(varchar(8), HourEnd, 108) HourEnd
	from shifthourdefinition
	where @dt >= DATEADD(dd, 0, DATEDIFF(dd, 0, @dt))+ convert(varchar(8), HourStart, 108) and
	@dt <= DATEADD(dd, case when datepart(hour, HourEnd) = 0 then 1 else 0 end, DATEDIFF(dd, 0, @dt))+ convert(varchar(8), HourEnd, 108) 
END
