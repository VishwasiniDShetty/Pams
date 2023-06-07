/****** Object:  Function [dbo].[f_GetTpmStrToTime]    Committed by VersionSQL https://www.versionsql.com ******/

--mod 1: ER0185 . to process milliseconds by Mrudula on 04-jun-2009
--mod 1
---ALTER       Function f_GetTpmStrToTime (@starttime nvarchar(10))
CREATE         Function [dbo].[f_GetTpmStrToTime] (@starttime nvarchar(12))
--mod 1 
RETURNS nvarchar(12)
AS
BEGIN
  ---mod 1: to process milliseconds
   /* If Len(@starttime) = 0 SET @starttime = '00:00:00'
    ELSE If Len(@starttime) = 1 SET   @starttime = '00:00:0' + SUBSTRING(@starttime, 1, 1)
    ELSE If Len(@starttime) = 2 SET   @starttime = '00:00' + ':' + SUBSTRING(@starttime, 1, 2)
    ELSE If Len(@starttime) = 3 SET  @starttime = '00:0' + SUBSTRING(@starttime, 1, 1) + ':' + SUBSTRING(@starttime, 2, 2)
    ELSE If Len(@starttime) = 4 SET  @starttime = '00' + ':' + SUBSTRING(@starttime, 1, 2) + ':' + SUBSTRING(@starttime, 3, 2)
    ELSE If Len(@starttime) = 5 SET   @starttime = '0' + SUBSTRING(@starttime, 1, 1) + ':' + SUBSTRING(@starttime, 2, 2) + ':' + SUBSTRING(@starttime, 4, 2)
    ELSE If Len(@starttime) = 6 SET  @starttime = SUBSTRING(@starttime, 1, 2) + ':' + SUBSTRING(@starttime, 3, 2) + ':' + SUBSTRING(@starttime, 5, 2)
    RETURN @starttime */
   If Len(@starttime) = 0 SET @starttime = '00:00:00.000'
    ELSE If Len(@starttime) = 1 SET   @starttime = '00:00:0' + SUBSTRING(@starttime, 1, 1)+'.000'
    ELSE If Len(@starttime) = 2 SET   @starttime = '00:00' + ':' + SUBSTRING(@starttime, 1, 2)+'.000'
    ELSE If Len(@starttime) = 3 SET  @starttime = '00:0' + SUBSTRING(@starttime, 1, 1) + ':' + SUBSTRING(@starttime, 2, 2)+'.000'
    ELSE If Len(@starttime) = 4 SET  @starttime = '00' + ':' + SUBSTRING(@starttime, 1, 2) + ':' + SUBSTRING(@starttime, 3, 2)+'.000'
    ELSE If Len(@starttime) = 5 SET   @starttime = '0' + SUBSTRING(@starttime, 1, 1) + ':' + SUBSTRING(@starttime, 2, 2) + ':' + SUBSTRING(@starttime, 4, 2)+'.000'
    ELSE If Len(@starttime) = 6 SET  @starttime = SUBSTRING(@starttime, 1, 2) + ':' + SUBSTRING(@starttime, 3, 2) + ':' + SUBSTRING(@starttime, 5, 2)+'.000'
    ELSE If Len(@starttime) = 7 SET   @starttime = SUBSTRING(@starttime, 1, 2) + ':' + SUBSTRING(@starttime, 3, 2) + ':' + SUBSTRING(@starttime, 5, 2)+'.'+SUBSTRING(@starttime, 7, 1)+'00'
    ELSE If Len(@starttime) = 8 SET   @starttime = SUBSTRING(@starttime, 1, 2) + ':' + SUBSTRING(@starttime, 3, 2) + ':' + SUBSTRING(@starttime, 5, 2)+'.'+SUBSTRING(@starttime, 7, 1)+SUBSTRING(@starttime, 8, 1)+'0'
    ELSE If Len(@starttime) = 9 SET  @starttime = SUBSTRING(@starttime, 1, 2) + ':' + SUBSTRING(@starttime, 3, 2) + ':' + SUBSTRING(@starttime, 5, 2)+'.'+SUBSTRING(@starttime, 7, 1)+SUBSTRING(@starttime, 8, 1)+SUBSTRING(@starttime, 9, 1)
    
    RETURN @starttime
END
