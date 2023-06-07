/****** Object:  Procedure [dbo].[util_RenamePlantName]    Committed by VersionSQL https://www.versionsql.com ******/

-- ===================================================================================================
-- Description:	To update the Plant
-- util_RenamePlantName  @PlantIDOld = 'CNC SHOP1', @PlantIDNew = 'CNC SHOPNew'
--- Vasavi - 15/Sep/2017 To rename the Plant
-- =======================================================================================================
CREATE PROCEDURE [dbo].[util_RenamePlantName]
	@PlantIDOld  nvarchar(200),
	@PlantIDNew  nvarchar(200)
AS
BEGIN
SET NOCOUNT ON
DECLARE @update_count int
DECLARE @ErrorCode  int  
DECLARE @ErrorStep  varchar(200)
DECLARE @Return_Message VARCHAR(4000) 
SET @ErrorCode = @@ERROR
SET @Return_Message = ''

	IF (@PlantIDOld = '' or @PlantIDNew = '') print 'ERROR - Plant id not provided' 
	if(select count(*) from Plantinformation where Plantid = @PlantIDOld) = 0 
	Begin
	print 'ERROR - Plant id to be change does not exists' 
	return -1;
	End
	if(select count(*) from Plantinformation where Plantid = @PlantIDNew) > 0 
	Begin
	print 'ERROR - New Plant id already exists' 
	return -1;
	End

BEGIN TRY
	BEGIN TRAN
	
	SET @ErrorStep = 'Error in updating  [AndonTarget]';
	update [dbo].AndonTarget set Plant=@PlantIDNew where Plant= @PlantIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table AndonTarget'

	--remove constraint for plant	
	SET @ErrorStep = 'Error in updating  [PlantEmployee]';	
	ALTER TABLE PlantEmployee NOCHECK CONSTRAINT FK_PlantEmployee_PlantInformation
	SET @ErrorStep = 'Error in updating [PlantMachine]';
	ALTER TABLE PlantMachine NOCHECK CONSTRAINT FK_PlantMachine_PlantInformation1
	SET @ErrorStep = 'Error in updating [EM_PlantMachine]';
	ALTER TABLE EM_PlantMachine NOCHECK CONSTRAINT FK_EM_PlantMachine_PlantInformation1


	--------------------

	SET @ErrorStep = 'Error in updating  [PlantEmployee]';
	update [dbo].[PlantEmployee] set PlantID=@PlantIDNew where PlantID  = @PlantIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table PlantEmployee'

	SET @ErrorStep = 'Error in updating  [PlantMachine]';
	update [dbo].PlantMachine set PlantID=@PlantIDNew where PlantID  = @PlantIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table PlantMachine'

	SET @ErrorStep = 'Error in updating  [EM_PlantMachine]';
	update [dbo].EM_PlantMachine set PlantID=@PlantIDNew where PlantID  = @PlantIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table EM_PlantMachine'

	SET @ErrorStep = 'Error in updating  [PlantInformation]';
	update [dbo].[PlantInformation] set PlantID=@PlantIDNew,Description=@PlantIDNew where PlantID  = @PlantIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table PlantInformation'

	---------------

	--add constraint for plant
	ALTER TABLE PlantEmployee WITH CHECK CHECK CONSTRAINT FK_PlantEmployee_PlantInformation
	ALTER TABLE PlantMachine  WITH CHECK CHECK CONSTRAINT FK_PlantMachine_PlantInformation1
	ALTER TABLE EM_PlantMachine  WITH CHECK CHECK CONSTRAINT FK_EM_PlantMachine_PlantInformation1


	SET @ErrorStep = 'Error in updating  [PlantMachineGroups]';
	update [dbo].[PlantMachineGroups] set PlantID=@PlantIDNew where PlantID  = @PlantIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table PlantMachineGroups'

	SET @ErrorStep = 'Error in updating  [ShiftProductionDetails]';
	update [dbo].[ShiftProductionDetails] set PlantID=@PlantIDNew where PlantID  = @PlantIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table ShiftProductionDetails'

	SET @ErrorStep = 'Error in updating  [ShiftDownTimeDetails]';
	update [dbo].[ShiftDownTimeDetails] set PlantID=@PlantIDNew where PlantID  = @PlantIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table ShiftDownTimeDetails'

	SET @ErrorStep = 'Error in updating  [Alert_Consumers]';
	update [dbo].[Alert_Consumers] set PlantID=@PlantIDNew where PlantID  = @PlantIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table Alert_Consumers'

	SET @ErrorStep = 'Error in updating  [Bosch_AccessRights]';
	update [dbo].[Bosch_AccessRights] set PlantID=@PlantIDNew where PlantID  = @PlantIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table Bosch_AccessRights'

	SET @ErrorStep = 'Error in updating  [Cell]';
	update [dbo].[Cell] set PlantID=@PlantIDNew where PlantID  = @PlantIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table Cell'

	SET @ErrorStep = 'Error in updating  [CellHistory]';
	update [dbo].[CellHistory] set PlantID=@PlantIDNew where PlantID  = @PlantIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table CellHistory'

	SET @ErrorStep = 'Error in updating  [FocasWeb_DownFreq]';
	update [dbo].[FocasWeb_DownFreq] set PlantID=@PlantIDNew where PlantID  = @PlantIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table FocasWeb_DownFreq'

	IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FocasWeb_FrequencyWiseData]') AND type in (N'U'))
	begin
	SET @ErrorStep = 'Error in updating  [FocasWeb_FrequencyWiseData]';
	update [dbo].[FocasWeb_FrequencyWiseData] set PlantID=@PlantIDNew where PlantID  = @PlantIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table FocasWeb_FrequencyWiseData'
	end

	SET @ErrorStep = 'Error in updating  [FocasWeb_HourwiseCycles]';
	update [dbo].[FocasWeb_HourwiseCycles] set PlantID=@PlantIDNew where PlantID  = @PlantIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table FocasWeb_HourwiseCycles'

	SET @ErrorStep = 'Error in updating  [FocasWeb_HourwiseTimeInfo]';
	update [dbo].[FocasWeb_HourwiseTimeInfo] set PlantID=@PlantIDNew where PlantID  = @PlantIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table FocasWeb_HourwiseTimeInfo'

	SET @ErrorStep = 'Error in updating  [FocasWeb_ShiftwiseCockpit]';
	update [dbo].[FocasWeb_ShiftwiseCockpit] set PlantID=@PlantIDNew where PlantID  = @PlantIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table FocasWeb_ShiftwiseCockpit'

	IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[FocasWeb_ShiftwiseRejection]') AND type in (N'U'))
	begin
	SET @ErrorStep = 'Error in updating  [FocasWeb_ShiftwiseRejection]';
	update [dbo].[FocasWeb_ShiftwiseRejection] set PlantID=@PlantIDNew where PlantID  = @PlantIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table FocasWeb_ShiftwiseRejection'
	end

	SET @ErrorStep = 'Error in updating  [FocasWeb_ShiftwiseStoppages]';
	update [dbo].[FocasWeb_ShiftwiseStoppages] set PlantID=@PlantIDNew where PlantID  = @PlantIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table FocasWeb_ShiftwiseStoppages'

	SET @ErrorStep = 'Error in updating  [FocasWeb_ShiftwiseSummary]';
	update [dbo].[FocasWeb_ShiftwiseSummary] set PlantID=@PlantIDNew where PlantID  = @PlantIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table FocasWeb_ShiftwiseSummary'

	SET @ErrorStep = 'Error in updating  [FocasWeb_Statistics]';
	update [dbo].[FocasWeb_Statistics] set PlantID=@PlantIDNew where PlantID  = @PlantIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table FocasWeb_Statistics'

	SET @ErrorStep = 'Error in updating  [HelpRequestShiftEmployee]';
	update [dbo].[HelpRequestShiftEmployee] set PlantID=@PlantIDNew where PlantID  = @PlantIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table HelpRequestShiftEmployee'

	SET @ErrorStep = 'Error in updating  [mxk_temp_machinelevelinfo]';
	update [dbo].[mxk_temp_machinelevelinfo] set PlantID=@PlantIDNew where PlantID  = @PlantIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table mxk_temp_machinelevelinfo'

	SET @ErrorStep = 'Error in updating  [ScheduledReports]';
	update [dbo].[ScheduledReports] set PlantID=@PlantIDNew where PlantID  = @PlantIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table ScheduledReports'

	COMMIT TRAN
    SET  @ErrorCode  = 0
	Print 'Plant name changed for plant = '  + @PlantIDOld
    RETURN @ErrorCode  

END TRY
BEGIN CATCH    
	PRINT 'Exception happened. Rolling back the transaction'  
    SET @ErrorCode = ERROR_NUMBER() 
	SET @Return_Message = @ErrorStep + ' '
							+ cast(isnull(ERROR_NUMBER(),-1) as varchar(20)) + ' line: '
							+ cast(isnull(ERROR_LINE(),-1) as varchar(20)) + ' ' 
							+ isnull(ERROR_MESSAGE(),'') + ' > ' 
							+ isnull(ERROR_PROCEDURE(),'')
	PRINT @Return_Message
	IF @@TRANCOUNT > 0 ROLLBACK
    RETURN @ErrorCode 
END CATCH
END
