/****** Object:  Function [dbo].[f_GetLogicalMonth]    Committed by VersionSQL https://www.versionsql.com ******/

--SangeetaKallur on 30th Sep 2005
CREATE       Function [dbo].[f_GetLogicalMonth](@InDate datetime,@Format nvarchar(5)) RETURNS Datetime
AS

BEGIN


DECLARE @TDate AS DateTime
DECLARE @Res as Datetime


IF @Format='End'
BEGIN
SELECT @TDate=dbo.f_GetPhysicalMonth(@InDate,'End')
SELECT @Res=dbo.f_GetLogicalDay(@TDate,'End')
END

IF @Format='Start'
BEGIN
SELECT @TDate=dbo.f_GetPhysicalMonth(@InDate,'Start')
SELECT @Res=dbo.f_GetLogicalDay(@TDate,'Start')	
END

RETURN @Res
END
