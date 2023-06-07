/****** Object:  Function [dbo].[f_IsLeapYear]    Committed by VersionSQL https://www.versionsql.com ******/

--Sangeeta Kallur on 30th Sep-2005

CREATE   Function [dbo].[f_IsLeapYear](@InDate datetime) RETURNS int
AS
BEGIN

DECLARE @Res as INTEGER 

SELECT @Res=0

	
		
		SET @Res= ISDATE(CAST(YEAR(@InDate)AS NVARCHAR(4))+ '-02-29 00:00:00.000')
		
RETURN @Res
END
