/****** Object:  Procedure [dbo].[s_GetAndonUISettings]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE  [dbo].[s_GetAndonUISettings]
	@FormFontSize nvarchar(50)='',
	@AndonTitle nvarchar(100)='',
	@PlantToDisplay nvarchar(50)='',
	@DataDisplayInterval nvarchar(50)='',
	@ScreenFlipInterval nvarchar(50)='',
	@ShowSmileyBlock int ='0',
	@MsgBlockEnabled int='0',
	@ShowFooterBlock int='0',
	@FontFamily nvarchar(50)='',
	@FontStyle nvarchar(50)='',
	@ShowSmileyBlockSize nvarchar(50)='',
	@ImageFilePath nvarchar(200)='',
	@EnableImage int='0',
	@EnableVideo int='0',
	@videoFilePath nvarchar(200)='0',
	@ImageFlipInterval nvarchar(50)='',
	@ShowCurvedBox int ='0',
	@DateFormatForHeader nvarchar(50)='',
	@TimeFormatForHeader nvarchar(50)='',
	@Orderby nvarchar(50)='',
	@primaryScreen nvarchar(50)='',
	
	@param nvarchar(50)=''

AS
BEGIN

	SET NOCOUNT ON;

If @param='Update'

Begin

Update ShopDefaults set ValueInText2 = isnull(@FormFontSize,'5') where ValueInText = 'FormFontSize' and Parameter = 'AndonCockpitAppSettings'
Update ShopDefaults set ValueInText2 = isnull(@AndonTitle,'') where ValueInText = 'AndonTitle' and Parameter = 'AndonCockpitAppSettings'
Update ShopDefaults set ValueInText2 = isnull(@PlantToDisplay,'') where ValueInText = 'PlantToDisplay' and Parameter = 'AndonCockpitAppSettings'
Update ShopDefaults set ValueInText2 = @DataDisplayInterval where ValueInText = 'DataDisplayInterval' and Parameter = 'AndonCockpitAppSettings'
Update ShopDefaults set ValueInText2 = @ScreenFlipInterval where ValueInText = 'ScreenFlipInterval' and Parameter = 'AndonCockpitAppSettings'
Update ShopDefaults set ValueInText2 = @FontFamily where ValueInText = 'FontFamily' and Parameter = 'AndonCockpitAppSettings'
Update ShopDefaults set ValueInText2 = @FontStyle where ValueInText = 'FontStyle' and Parameter = 'AndonCockpitAppSettings'
Update ShopDefaults set ValueInText2 = @ShowSmileyBlockSize where ValueInText = 'ShowSmileyBlockSize' and Parameter = 'AndonCockpitAppSettings'
update Shopdefaults set ValueInInt = @ShowSmileyBlock where ValueInText='ShowSmileyBlock'and Parameter = 'AndonCockpitAppSettings'
update Shopdefaults set ValueInInt = @MsgBlockEnabled where ValueInText='MsgBlockEnabled'and Parameter = 'AndonCockpitAppSettings'
update Shopdefaults set ValueInInt = @ShowFooterBlock where ValueInText='ShowFooterBlock'and Parameter = 'AndonCockpitAppSettings'
Update ShopDefaults set ValueInText2 = @ImageFilePath where ValueInText = 'ImageFilePath' and Parameter = 'AndonCockpitAppSettings'	
update Shopdefaults set ValueInInt = @EnableImage where ValueInText='EnableImage'and Parameter = 'AndonCockpitAppSettings'
update ShopDefaults set ValueInInt = @EnableVideo where ValueInText='EnableVideo' and  Parameter = 'AndonCockpitAppSettings'
update ShopDefaults set ValueInText2= @VideoFilePath where ValueInText = 'VideoFilePath' and Parameter = 'AndonCockpitAppSettings'	
update ShopDefaults set ValueInText2 = @ImageFlipInterval where ValueInText = 'ImageFlipInterval' and Parameter = 'AndonCockpitAppSettings'
update ShopDefaults set ValueInInt = @ShowCurvedBox where ValueInText = 'ShowCurvedBox' and Parameter = 'AndonCockpitAppSettings'
update ShopDefaults set ValueInText2 = @DateFormatForHeader where ValueInText =  'DateFormatForHeader' and Parameter = 'AndonCockpitAppSettings'
update ShopDefaults set ValueInText2 = @TimeFormatForHeader where ValueInText = 'TimeFormatForHeader' and Parameter = 'AndonCockpitAppSettings'
update ShopDefaults set ValueInText2 = @Orderby where ValueInText ='OrderBy' and Parameter = 'AndonCockpitAppSettings'
update ShopDefaults set ValueInText2 = @primaryScreen where ValueInText ='PrimaryScreen' and Parameter = 'AndonCockpitAppSettings'

END



If @param='View'
Begin
	select * from ShopDefaults where Parameter = 'AndonCockpitAppSettings'
END

if @param ='Colors'
BEGIN
select * from CockpitDefaults where Parameter='CockpitBackColor'
END
	
END
