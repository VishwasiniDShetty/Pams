/****** Object:  Procedure [dbo].[s_GetFocasAppSettings]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[s_GetFocasAppSettings]

@StoppagesThreshold  nvarchar(50)='',
@HideDashboardSummaryOrAnalytics  nvarchar(50)='',
@AutoRefreshInterval  nvarchar(50)='',
@OperationHistoryPath  nvarchar(50)='',
@ProgramsPath  nvarchar(50)='',
@AllGridLastColumnSetting  nvarchar(50)='',
@AllFormsBackcolor  nvarchar(50)='',
@OperationHistoryTextAreaSetting  nvarchar(50)='',
@ProgramFileExtention nvarchar(50)='.TXT',
@param nvarchar(50)=''

WITH RECOMPILE
AS
BEGIN

SET NOCOUNT ON;

If @param='Update'
Begin
    Update Focas_Defaults set ValueInText =  @StoppagesThreshold where Parameter = 'DowntimeThreshold'
	Update Focas_Defaults set ValueInText2 = @HideDashboardSummaryOrAnalytics where ValueInText = 'HideDashboardSummaryOrAnalytics' and Parameter = 'FocasAppSettings'
	Update Focas_Defaults set ValueInText2 = @AutoRefreshInterval where ValueInText = 'AutoRefreshInterval' and Parameter = 'FocasAppSettings'
	Update Focas_Defaults set ValueInText2 = @OperationHistoryPath where ValueInText = 'OperationHistoryPath' and Parameter = 'FocasAppSettings'
	Update Focas_Defaults set ValueInText2 = @ProgramsPath where ValueInText = 'ProgramsPath' and Parameter = 'FocasAppSettings'
	Update Focas_Defaults set ValueInText2 = @AllFormsBackColor where ValueInText = 'AllFormsBackColor' and Parameter = 'FocasAppSettings'
	Update Focas_Defaults set ValueInText2 = @AllGridLastColumnSetting where ValueInText = 'AllGridLastColumnSetting' and Parameter = 'FocasAppSettings'
	Update Focas_Defaults set ValueInText2 = @OperationHistoryTextAreaSetting where ValueInText = 'OperationHistoryTextAreaSetting' and Parameter = 'FocasAppSettings'
	Update Focas_Defaults set ValueInText2 = @ProgramFileExtention where ValueInText = 'ProgramFileExtention' and Parameter = 'FocasAppSettings'
END

If @param='View'
Begin
	select * from Focas_Defaults where Parameter = 'FocasAppSettings' OR Parameter = 'DowntimeThreshold'
END

END
