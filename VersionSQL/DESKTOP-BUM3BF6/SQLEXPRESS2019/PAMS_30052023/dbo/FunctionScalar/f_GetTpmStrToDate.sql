/****** Object:  Function [dbo].[f_GetTpmStrToDate]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE       Function [dbo].[f_GetTpmStrToDate] (@startdate nvarchar(12),@TodayDate datetime)
RETURNS nvarchar(12)
AS
BEGIN
	IF Len(@startdate) = 6 	SET @startdate = SUBSTRING(@startdate, 1, 4) + '-' + SUBSTRING(@startdate, 5, 1) + '-' + SUBSTRING(@startdate, 6, 1)
	ELSE if Len(@startdate) = 7
		If MONTH(@TodayDate) < 10 SET @startdate = SUBSTRING(@startdate, 1, 4) + '-' + SUBSTRING(@startdate, 5, 1) + '-' + SUBSTRING(@startdate, 6, 2)
	        Else SET @startdate = SUBSTRING(@startdate, 1, 4) + '-' + SUBSTRING(@startdate, 5, 2) + '-' + SUBSTRING(@startdate, 7, 1)
	ELSE IF Len(@startdate) =  8 SET @startdate = SUBSTRING(@startdate, 1, 4) + '-' + SUBSTRING(@startdate, 5, 2) + '-' + SUBSTRING(@startdate, 7, 2)       
	RETURN @startdate
END
