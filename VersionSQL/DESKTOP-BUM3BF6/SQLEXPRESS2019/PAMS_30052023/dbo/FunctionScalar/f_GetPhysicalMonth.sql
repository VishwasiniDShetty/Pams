/****** Object:  Function [dbo].[f_GetPhysicalMonth]    Committed by VersionSQL https://www.versionsql.com ******/

--SangeetaKallur on 30th Sep 2005
CREATE     Function [dbo].[f_GetPhysicalMonth](@InDate datetime,@Format nvarchar(5)) RETURNS Datetime
AS

BEGIN

DECLARE @mMonth	AS INT
DECLARE @I AS INT
DECLARE @Res as Datetime

SELECT @mMonth=MONTH(@InDate)
IF @Format='End'
BEGIN

	IF @mMonth=1 OR @mMonth=3 OR @mMonth=5 OR @mMonth=7 OR @mMonth=8 OR @mMonth=10 OR @mMonth=12
		BEGIN
		SELECT @Res= CONVERT(DATETIME,CAST(DATEPART(YYYY,@InDate) AS NVARCHAR(4))+'-'+CAST(DATEPART(MM,@InDate)AS NVARCHAR(3))+'-31 00:00:00.000')
		END
	
	IF @mMonth=2
	BEGIN
	SELECT @I = dbo.f_IsLeapYear(@InDate)
		IF @I=1
		BEGIN
		SELECT @Res= CONVERT(DATETIME,CAST(DATEPART(YYYY,@InDate) AS NVARCHAR(4))+'-'+CAST(DATEPART(MM,@InDate)AS NVARCHAR(3))+'-29 00:00:00.000')
		END
		IF @I=0
		BEGIN
		SELECT @Res= CONVERT(DATETIME,CAST(DATEPART(YYYY,@InDate) AS NVARCHAR(4))+'-'+CAST(DATEPART(MM,@InDate)AS NVARCHAR(3))+'-28 00:00:00.000')
		END
	
	END
	
	
	
	IF @mMonth =4 OR @mMonth=6 OR @mMonth=9 OR @mMonth=11
		BEGIN
		SELECT @Res= CONVERT(DATETIME,CAST(DATEPART(YYYY,@InDate) AS NVARCHAR(4))+'-'+CAST(DATEPART(MM,@InDate)AS NVARCHAR(3))+'-30 00:00:00.000')
		END


END
IF @Format='Start'
BEGIN
	SELECT @Res= CONVERT(DATETIME,CAST(DATEPART(YYYY,@InDate) AS NVARCHAR(4))+'-'+CAST(DATEPART(MM,@InDate)AS NVARCHAR(3))+'-01 00:00:00.000')
END

RETURN @Res
END
