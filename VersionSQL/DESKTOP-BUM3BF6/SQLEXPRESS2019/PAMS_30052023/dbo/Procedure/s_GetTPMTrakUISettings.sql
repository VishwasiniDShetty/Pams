/****** Object:  Procedure [dbo].[s_GetTPMTrakUISettings]    Committed by VersionSQL https://www.versionsql.com ******/

 --[dbo].[s_GetTPMTrakUISettings] 'sss','reg','8','12','ad','da','dd','view'
 
CREATE  PROCEDURE [dbo].[s_GetTPMTrakUISettings]
@FontFamily nvarchar(50)='',
@FontStyle nvarchar(50)='', 
@FormFontSize nvarchar(50)='', 
@HeaderFontSize nvarchar(50) ='', 
@FormHeaderBackColor nvarchar(50)='', 
@FormBackColor nvarchar(50)='', 
@FormTextColor nvarchar(50)='', 
@param nvarchar(50)=''

WITH RECOMPILE
AS
BEGIN

SET NOCOUNT ON;

If @param='Update'
Begin
	Update ShopDefaults set ValueInText2 = @FontFamily where ValueInText = 'FontFamily' and Parameter = 'TPMTrakAppSettings'
	Update ShopDefaults set ValueInText2 = @FontStyle where ValueInText = 'FontStyle' and Parameter = 'TPMTrakAppSettings'
	Update ShopDefaults set ValueInText2 = @FormFontSize where ValueInText = 'FormFontSize' and Parameter = 'TPMTrakAppSettings'
	Update ShopDefaults set ValueInText2 = @HeaderFontSize where ValueInText = 'HeaderFontSize' and Parameter = 'TPMTrakAppSettings'
	Update ShopDefaults set ValueInText2 = @FormHeaderBackColor where ValueInText = 'FormHeaderBackColor' and Parameter = 'TPMTrakAppSettings'
	Update ShopDefaults set ValueInText2 = @FormBackColor where ValueInText = 'FormBackColor' and Parameter = 'TPMTrakAppSettings'
	Update ShopDefaults set ValueInText2 = @FormTextColor where ValueInText = 'FormTextColor' and Parameter = 'TPMTrakAppSettings'
END

If @param='View'
Begin
	select * from ShopDefaults where Parameter = 'TPMTrakAppSettings'
END

END
