/****** Object:  Procedure [dbo].[util_RenameMachineName]    Committed by VersionSQL https://www.versionsql.com ******/

-- ===================================================================================================
-- Author:		Satyendraj
-- Create date: 2-DEC-2013
-- Description:	To update the Machine
-- util_RenameMachineName  @MachineIDOld = 'AMS', @MachineIDNew = 'SATYA'
-- util_RenameMachineName  @MachineIDOld = 'CNC-15', @MachineIDNew = 'NEWCNC-15'
--ER402 - Vasavi - 29/Dec/2014 To include tables-HelpCodeDetails,HelpRequestRule,MessageHistory for Wipro.
--ER463 - Gopinath - 05-Apr-2018 :: Check existence of table before updating, and including focas tables
-- =======================================================================================================
CREATE PROCEDURE [dbo].[util_RenameMachineName]
	@MachineIDOld  nvarchar(100),
	@MachineIDNew  nvarchar(100)
AS
BEGIN
SET NOCOUNT ON
DECLARE @update_count int
DECLARE @ErrorCode  int  
DECLARE @ErrorStep  varchar(200)
DECLARE @Return_Message VARCHAR(1024) 
SET @ErrorCode = @@ERROR
SET @Return_Message = ''

	IF (@MachineIDOld = '' or @MachineIDNew = '') print 'ERROR - Machine id not provided' 
	if(select count(*) from machineinformation where machineid = @MachineIDOld) = 0 
	Begin
	print 'ERROR - Machine id to be change does not exists' 
	return -1;
	End
	if(select count(*) from machineinformation where machineid = @MachineIDNew) > 0 
	Begin
	print 'ERROR - New Machine id already exists' 
	return -1;
	End


BEGIN TRY
	BEGIN TRAN

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='SmartDataModbusRegisterInfo')
	BEGIN
	SET @ErrorStep = 'Error in updating  SmartDataModbusRegisterInfo';
	update [dbo].[SmartDataModbusRegisterInfo] set machineid=@MachineIDNew where machineid= @MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table [SmartDataModbusRegisterInfo]'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='componentoperationpricing')
	BEGIN
	SET @ErrorStep = 'Error in updating  componentoperationpricing';
	update [dbo].[componentoperationpricing] set machineid=@MachineIDNew where machineid= @MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table componentoperationpricing'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='EventCategoryInformation')
	BEGIN
	SET @ErrorStep = 'Error in updating  EventCategoryInformation';
	update [dbo].[EventCategoryInformation] set machineid=@MachineIDNew where machineid= @MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table EventCategoryInformation'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='MachineAlarmInformation')
	BEGIN
	SET @ErrorStep = 'Error in updating  MachineAlarmInformation';
	update [dbo].[MachineAlarmInformation] set machineid=@MachineIDNew where machineid= @MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table MachineAlarmInformation'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='machinefinanceinformation')
	BEGIN
	SET @ErrorStep = 'Error in updating  machinefinanceinformation';
	update [dbo].[machinefinanceinformation] set machineid=@MachineIDNew where machineid= @MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table machinefinanceinformation'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='machinemakeinformation')
	BEGIN
	SET @ErrorStep = 'Error in updating  machinemakeinformation';
	update [dbo].[machinemakeinformation] set machineid=@MachineIDNew where machineid= @MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table machinemakeinformation'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='machineserviceinformation')
	BEGIN
	SET @ErrorStep = 'Error in updating  machineserviceinformation';
	update [dbo].[machineserviceinformation] set machineid=@MachineIDNew where machineid= @MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table machineserviceinformation'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='PlantMachine')
	BEGIN
	SET @ErrorStep = 'Error in updating  PlantMachine';
	update [dbo].[PlantMachine] set machineid=@MachineIDNew where machineid= @MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table PlantMachine'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='Shift_Proc')
	BEGIN
	SET @ErrorStep = 'Error in updating  Shift_Proc';
	update [dbo].[Shift_Proc] set machine=@MachineIDNew where machine= @MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table Shift_Proc'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='PlannedDownTimes')
	BEGIN
	SET @ErrorStep = 'Error in updating  PlannedDownTimes';
	update [dbo].[PlannedDownTimes] set machine=@MachineIDNew where machine= @MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table PlannedDownTimes'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='ShiftAggTrail')
	BEGIN
	SET @ErrorStep = 'Error in updating  ShiftAggTrail';	
	update ShiftAggTrail set Machineid = @MachineIDNew where machineid= @MachineIDOld	
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table ShiftAggTrail'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='ShiftProductionDetails')
	BEGIN
	SET @ErrorStep = 'Error in updating  ShiftProductionDetails';
	update ShiftProductionDetails set Machineid = @MachineIDNew where machineid= @MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table ShiftProductionDetails'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='ShiftDownTimeDetails')
	BEGIN
	SET @ErrorStep = 'Error in updating  ShiftDownTimeDetails';
	update  ShiftDownTimeDetails set Machineid = @MachineIDNew where machineid= @MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table ShiftDownTimeDetails'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='MachineControlInformation')
	BEGIN
	SET @ErrorStep = 'Error in updating  MachineControlInformation';	
	ALTER TABLE MachineControlInformation NOCHECK CONSTRAINT FK_MachineControlInformation_ControlInformation
	ALTER TABLE MachineControlInformation NOCHECK CONSTRAINT FK_MachineControlInformation_machineinformation
	END

	--dbo.EfficiencyTarget


	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='MachineControlInformation')
	BEGIN
	SET @ErrorStep = 'Error in updating  MachineControlInformation';	
--	ALTER TABLE MachineControlInformation NOCHECK CONSTRAINT FK_MachineControlInformation_ControlInformation
--	ALTER TABLE MachineControlInformation NOCHECK CONSTRAINT FK_MachineControlInformation_machineinformation
	update [dbo].[MachineControlInformation] set machineid=@MachineIDNew where machineid= @MachineIDOld	
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table MachineControlInformation'
--	ALTER TABLE MachineControlInformation WITH CHECK CHECK CONSTRAINT FK_MachineControlInformation_ControlInformation
--	ALTER TABLE MachineControlInformation WITH CHECK CHECK CONSTRAINT FK_MachineControlInformation_machineinformation
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='machineinformation')
	BEGIN
	SET @ErrorStep = 'Error in updating  machineinformation';	
	update [dbo].[machineinformation] set machineid=@MachineIDNew where machineid= @MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table machineinformation'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='EfficiencyTarget')
	BEGIN
	SET @ErrorStep = 'Error in updating  EfficiencyTarget';	
	ALTER TABLE EfficiencyTarget NOCHECK CONSTRAINT FK_EfficiencyTarget_machineinformation
	update [dbo].[EfficiencyTarget] set MachineID=@MachineIDNew where MachineID= @MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table EfficiencyTarget'
	ALTER TABLE EfficiencyTarget  WITH CHECK CHECK CONSTRAINT FK_EfficiencyTarget_machineinformation
--	ALTER TABLE EfficiencyTarget NOCHECK CONSTRAINT FK_EfficiencyTarget_machineinformation
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='machinetargets')
	BEGIN
	SET @ErrorStep = 'Error in updating  machinetargets';
	update machinetargets set Machineid = @MachineIDNew where machineid= @MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table machinetargets'
	END


	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='HolidayList')
	BEGIN
	SET @ErrorStep = 'Error in updating  HolidayList';
	update HolidayList set Machineid = @MachineIDNew where machineid= @MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table HolidayList'
	END


	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='LoadSchedule')
	BEGIN
	SET @ErrorStep = 'Error in updating  LoadSchedule';
	update LoadSchedule set Machine = @MachineIDNew where machine= @MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table LoadSchedule'
	END


	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='PlannedDownListforLday')
	BEGIN
	SET @ErrorStep = 'Error in updating  PlannedDownListforLday';
	update PlannedDownListforLday set Machineid = @MachineIDNew where machineid= @MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table PlannedDownListforLday'
	END


	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='tcs_energyconsumption')
	BEGIN
	SET @ErrorStep = 'Error in updating  tcs_energyconsumption';
	update tcs_energyconsumption set Machineid = @MachineIDNew where machineid= @MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table tcs_energyconsumption'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='tcs_energyconsumption_maxgtime')
	BEGIN
	SET @ErrorStep = 'Error in updating  tcs_energyconsumption_maxgtime';
	update tcs_energyconsumption_maxgtime set machine = @MachineIDNew where machine= @MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table tcs_energyconsumption_maxgtime'
	END
 
	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='HelpCodeDetails')
	BEGIN
    SET @ErrorStep = 'Error in updating  [HelpCodeDetails]';
	update HelpCodeDetails set Machineid = @MachineIDNew where machineid= @MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table HelpCodeDetails'
	END
                 
	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='HelpRequestRule')
	BEGIN			 
	SET @ErrorStep = 'Error in updating  [HelpRequestRule]';
	update HelpRequestRule set Machineid = @MachineIDNew where machineid= @MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table HelpRequestRule'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='MessageHistory')
	BEGIN
    SET @ErrorStep = 'Error in updating  [MessageHistory]';
	update MessageHistory set Machineid = @MachineIDNew where machineid= @MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table MessageHistory'
    END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='Alert_Notification_History')
	BEGIN
	SET @ErrorStep = 'Error in updating Alert_Notification_History'
	UPDATE Alert_Notification_History SET MachineID=@MachineIDNew WHERE MachineID=@MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table Alert_Notification_History'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='CompressData')
	BEGIN
	SET @ErrorStep = 'Error in updating CompressData'
	UPDATE CompressData SET Machine=@MachineIDNew WHERE Machine=@MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table CompressData'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='Focas_ToolLifeTemp')
	BEGIN
	SET @ErrorStep = 'Error in updating Focas_ToolLifeTemp'
	UPDATE Focas_ToolLifeTemp SET MachineID=@MachineIDNew WHERE MachineID=@MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table Focas_ToolLifeTemp'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='Focas_AlarmHistory')
	BEGIN
	SET @ErrorStep = 'Error in updating Focas_AlarmHistory'
	UPDATE Focas_AlarmHistory SET MachineID=@MachineIDNew WHERE MachineID=@MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table Focas_AlarmHistory'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='Focas_AlarmTemp')
	BEGIN
	SET @ErrorStep = 'Error in updating Focas_AlarmTemp'
	UPDATE Focas_AlarmTemp SET MachineId=@MachineIDNew WHERE MachineId=@MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table Focas_AlarmTemp'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='Focas_CoolentLubOilInfo')
	BEGIN
	SET @ErrorStep = 'Error in updating Focas_CoolentLubOilInfo'
	UPDATE Focas_CoolentLubOilInfo SET MachineId=@MachineIDNew WHERE MachineId=@MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table Focas_CoolentLubOilInfo'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='Focas_CycleDetails')
	BEGIN
	SET @ErrorStep = 'Error in updating Focas_CycleDetails'
	UPDATE Focas_CycleDetails SET MachineID=@MachineIDNew WHERE MachineID=@MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table Focas_CycleDetails'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='Focas_DailyMaintenance')
	BEGIN
	SET @ErrorStep = 'Error in updating Focas_DailyMaintenance'
	UPDATE Focas_DailyMaintenance SET Machineid=@MachineIDNew WHERE Machineid=@MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table Focas_DailyMaintenance'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='Focas_info')
	BEGIN
	SET @ErrorStep = 'Error in updating Focas_info'
	UPDATE Focas_info SET MachineId=@MachineIDNew WHERE MachineId=@MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table Focas_info'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='Focas_LiveData')
	BEGIN
	SET @ErrorStep = 'Error in updating Focas_LiveData'
	UPDATE Focas_LiveData SET MachineID=@MachineIDNew WHERE MachineID=@MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table Focas_LiveData'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='Focas_OffsetVariables')
	BEGIN
	SET @ErrorStep = 'Error in updating Focas_OffsetVariables'
	UPDATE Focas_OffsetVariables SET MachineID=@MachineIDNew WHERE MachineID=@MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table Focas_OffsetVariables'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='Focas_PartwiseRejectionInfo')
	BEGIN
	SET @ErrorStep = 'Error in updating Focas_PartwiseRejectionInfo'
	UPDATE Focas_PartwiseRejectionInfo SET Machine=@MachineIDNew WHERE Machine=@MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table Focas_PartwiseRejectionInfo'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='Focas_PMCSignalStatus')
	BEGIN
	SET @ErrorStep = 'Error in updating Focas_PMCSignalStatus'
	UPDATE Focas_PMCSignalStatus SET MachineID=@MachineIDNew WHERE MachineID=@MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table Focas_PMCSignalStatus'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='Focas_PredictiveMaintenance')
	BEGIN
	SET @ErrorStep = 'Error in updating Focas_PredictiveMaintenance'
	UPDATE Focas_PredictiveMaintenance SET MachineId=@MachineIDNew WHERE MachineId=@MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table Focas_PredictiveMaintenance'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='Focas_PredictiveMaintenanceTemp')
	BEGIN
	SET @ErrorStep = 'Error in updating Focas_PredictiveMaintenanceTemp'
	UPDATE Focas_PredictiveMaintenanceTemp SET MachineId=@MachineIDNew WHERE MachineId=@MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table Focas_PredictiveMaintenanceTemp'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='Focas_ProgramwiseTarget')
	BEGIN
	SET @ErrorStep = 'Error in updating Focas_ProgramwiseTarget'
	UPDATE Focas_ProgramwiseTarget SET MachineID=@MachineIDNew WHERE MachineID=@MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table Focas_ProgramwiseTarget'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='Focas_SpindleInfo')
	BEGIN
	SET @ErrorStep = 'Error in updating Focas_SpindleInfo'
	UPDATE Focas_SpindleInfo SET MachineId=@MachineIDNew WHERE MachineId=@MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table Focas_SpindleInfo'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='Focas_SpindleTrans_AMS')
	BEGIN
	SET @ErrorStep = 'Error in updating Focas_SpindleTrans_AMS'
	UPDATE Focas_SpindleTrans_AMS SET Machine=@MachineIDNew WHERE Machine=@MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table Focas_SpindleTrans_AMS'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='Focas_ToolLife')
	BEGIN
	SET @ErrorStep = 'Error in updating Focas_ToolLife'
	UPDATE Focas_ToolLife SET MachineID=@MachineIDNew WHERE MachineID=@MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table Focas_ToolLife'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='Focas_ToolOffsetHistory')
	BEGIN
	SET @ErrorStep = 'Error in updating Focas_ToolOffsetHistory'
	UPDATE Focas_ToolOffsetHistory SET MachineID=@MachineIDNew WHERE MachineID=@MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table Focas_ToolOffsetHistory'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='Focas_ToolOffsetHistoryTemp')
	BEGIN
	SET @ErrorStep = 'Error in updating Focas_ToolOffsetHistoryTemp'
	UPDATE Focas_ToolOffsetHistoryTemp SET MachineID=@MachineIDNew WHERE MachineID=@MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table Focas_ToolOffsetHistoryTemp'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='Focas_WearOffsetCorrectionMaster')
	BEGIN
	SET @ErrorStep = 'Error in updating Focas_WearOffsetCorrectionMaster'
	UPDATE Focas_WearOffsetCorrectionMaster SET MachineId=@MachineIDNew WHERE MachineId=@MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table Focas_WearOffsetCorrectionMaster'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='FocasWeb_HourwiseCycles')
	BEGIN
	SET @ErrorStep = 'Error in updating FocasWeb_HourwiseCycles'
	UPDATE FocasWeb_HourwiseCycles SET MachineID=@MachineIDNew WHERE MachineID=@MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table FocasWeb_HourwiseCycles'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='FocasWeb_HourwiseTimeInfo')
	BEGIN
	SET @ErrorStep = 'Error in updating FocasWeb_HourwiseTimeInfo'
	UPDATE FocasWeb_HourwiseTimeInfo SET MachineID=@MachineIDNew WHERE MachineID=@MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table FocasWeb_HourwiseTimeInfo'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='FocasWeb_ShiftwiseStoppages')
	BEGIN
	SET @ErrorStep = 'Error in updating FocasWeb_ShiftwiseStoppages'
	UPDATE FocasWeb_ShiftwiseStoppages SET MachineID=@MachineIDNew WHERE MachineID=@MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table FocasWeb_ShiftwiseStoppages'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='FocasWeb_ShiftwiseSummary')
	BEGIN
	SET @ErrorStep = 'Error in updating FocasWeb_ShiftwiseSummary'
	UPDATE FocasWeb_ShiftwiseSummary SET MachineID=@MachineIDNew WHERE MachineID=@MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table FocasWeb_ShiftwiseSummary'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='Inspection_MasterData')
	BEGIN
	SET @ErrorStep = 'Error in updating Inspection_MasterData'
	UPDATE Inspection_MasterData SET Machineid=@MachineIDNew WHERE Machineid=@MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table Inspection_MasterData'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='MachineElectricalInfo')
	BEGIN
	SET @ErrorStep = 'Error in updating MachineElectricalInfo'
	UPDATE MachineElectricalInfo SET MachineID=@MachineIDNew WHERE MachineID=@MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table MachineElectricalInfo'
	END


	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='onlinemachinelist')
	BEGIN
	SET @ErrorStep = 'Error in updating onlinemachinelist'
	UPDATE onlinemachinelist SET machineid=@MachineIDNew WHERE machineid=@MachineIDOld
	SET @update_count = @@ROWCOUNT
	print 'Updated ' + CONVERT(varchar, @update_count) + ' records in table onlinemachinelist'
	END

	IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='dbo' AND TABLE_NAME='MachineControlInformation')
	BEGIN
	SET @ErrorStep = 'Error in updating  MachineControlInformation(Check constraints)';	
	ALTER TABLE MachineControlInformation WITH CHECK CHECK CONSTRAINT FK_MachineControlInformation_ControlInformation
	ALTER TABLE MachineControlInformation WITH CHECK CHECK CONSTRAINT FK_MachineControlInformation_machineinformation
	END
	
	COMMIT TRAN
    SET  @ErrorCode  = 0
	Print 'Machine name chaned for Machine ='  + @MachineIDOld
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
