/****** Object:  Procedure [dbo].[util_DeleteMachine]    Committed by VersionSQL https://www.versionsql.com ******/

--select * from machineinformation
-- =============================================
-- Author:		Satyendraj
-- Create date: 2-DEC-2013
-- Description:	To delete the input Machine
-- exec util_DeleteMachine 'MCV-ACER-07-29'
--ER402-Vasavi-29/Dec/2014::To include tables-HelpCodeDetails,HelpRequestRule,MessageHistory for Wipro.
-- =============================================
CREATE PROCEDURE [dbo].[util_DeleteMachine]
	@MachineID  nvarchar(100) = ''
AS
BEGIN

SET NOCOUNT ON
DECLARE @delete_count int
DECLARE @ErrorCode  int  
DECLARE @ErrorStep  varchar(200)
DECLARE @Return_Message VARCHAR(1024)
SET @Return_Message = ''
SET @ErrorCode = @@ERROR

	IF (@MachineID = '') Begin print 'ERROR - Plant id not provided'; return -1; end
	BEGIN TRY
	BEGIN TRAN

		SELECT @ErrorStep = 'Error in Deleting from RawData';
		DELETE RawData FROM RawData rd
		INNER JOIN machineinformation mi on mi.InterfaceID = rd.Mc
		Inner join PlantMachine pm on pm.MachineID = mi.machineid
		INNER JOIN PlantInformation pi on pi.PlantID = pm.PlantID
		where mi.MachineID = @MachineID
		SET @delete_count = @@ROWCOUNT
		IF @delete_count > 0
		print 'Deleted ' + CONVERT(varchar, @delete_count) + ' records from table RawData'
		SET @delete_count = 0

		SELECT @ErrorStep = 'Error in Deleting from autodata';
		DELETE autodata FROM autodata ad
		INNER JOIN machineinformation mi on mi.InterfaceID = ad.mc
		Inner join PlantMachine pm on pm.MachineID = mi.machineid
		INNER JOIN PlantInformation pi on pi.PlantID = pm.PlantID
		where mi.MachineID  = @MachineID
		SET @delete_count = @@ROWCOUNT
		IF @delete_count > 0
		print 'Deleted ' + CONVERT(varchar, @delete_count) + ' records from table autodata'
		SET @delete_count = 0
         

		SELECT @ErrorStep = 'Error in Deleting from autodata_ICD';
		DELETE autodata_ICD FROM autodata_ICD ad
		INNER JOIN machineinformation mi on mi.InterfaceID = ad.mc
		Inner join PlantMachine pm on pm.MachineID = mi.machineid
		INNER JOIN PlantInformation pi on pi.PlantID = pm.PlantID
		where mi.MachineID  = @MachineID
		SET @delete_count = @@ROWCOUNT
		IF @delete_count > 0
		print 'Deleted ' + CONVERT(varchar, @delete_count) + ' records from table autodata_ICD'
		SET @delete_count = 0
		
		SELECT @ErrorStep = 'Error in Deleting from Autodata_MaxTime';
		DELETE Autodata_MaxTime FROM Autodata_MaxTime ad
		INNER JOIN machineinformation mi on mi.InterfaceID = ad.Machineid
		Inner join PlantMachine pm on pm.MachineID = mi.machineid
		INNER JOIN PlantInformation pi on pi.PlantID = pm.PlantID
		where mi.MachineID  = @MachineID
		SET @delete_count = @@ROWCOUNT
		IF @delete_count > 0
		print 'Deleted ' + CONVERT(varchar, @delete_count) + ' records from table Autodata_MaxTime'
		SET @delete_count = 0

        --ER402 From Here
--		SELECT @ErrorStep = 'Error in Deleting from HelpCodeDetails';
--		DELETE HelpCodeDetails FROM HelpCodeDetails hcd
--		INNER JOIN machineinformation mi on mi.InterfaceID = hcd.machineid
--		Inner join PlantMachine pm on pm.MachineID = mi.machineid
--		INNER JOIN PlantInformation pi on pi.PlantID = pm.PlantID
--		where mi.MachineID  = @MachineID
--		SET @delete_count = @@ROWCOUNT
--		IF @delete_count > 0
--		print 'Deleted ' + CONVERT(varchar, @delete_count) + ' records from table HelpCodeDetails'
--		SET @delete_count = 0
--	
--         SELECT @ErrorStep = 'Error in Deleting from HelpRequestRule';
--		DELETE  HelpRequestRule FROM [dbo].[HelpRequestRule] Where MachineID = @MachineID
--		SET @delete_count = @@ROWCOUNT
--		IF @delete_count > 0
--		print 'Deleted ' + CONVERT(varchar, @delete_count) + ' records from table [HelpRequestRule]'
--		SET @delete_count = 0
--
--         SELECT @ErrorStep = 'Error in Deleting from MessageHistory';
--         DELETE  MessageHistory  FROM [dbo].[MessageHistory] Where MachineID = @MachineID
--		SET @delete_count = @@ROWCOUNT
--		IF @delete_count > 0
--		print 'Deleted ' + CONVERT(varchar, @delete_count) + ' records from table [MessageHistory]'
--		SET @delete_count = 0
        --ER402 Till Here



		SELECT @ErrorStep = 'Error in Deleting from ShiftDownTimeDetails';
		DELETE  ShiftDownTimeDetails FROM [dbo].[ShiftDownTimeDetails] Where MachineID = @MachineID
		SET @delete_count = @@ROWCOUNT
		IF @delete_count > 0
		print 'Deleted ' + CONVERT(varchar, @delete_count) + ' records from table [ShiftDownTimeDetails]'
		SET @delete_count = 0

		SELECT @ErrorStep = 'Error in Deleting from ShiftProductionDetails';
		DELETE  ShiftProductionDetails  FROM [dbo].[ShiftProductionDetails] Where MachineID = @MachineID
		SET @delete_count = @@ROWCOUNT
		IF @delete_count > 0
		print 'Deleted ' + CONVERT(varchar, @delete_count) + ' records from table [ShiftProductionDetails]'
		SET @delete_count = 0

		SET @ErrorStep = 'Error in Deleting from AutoDataAlarms';
		delete AutoDataAlarms FROM AutoDataAlarms ada
		INNER JOIN machineinformation mi on mi.InterfaceID = ada.MachineID
		Inner join PlantMachine pm on pm.MachineID = mi.machineid
		INNER JOIN PlantInformation pi on pi.PlantID = pm.PlantID
		where mi.machineid = @MachineID
		SET @delete_count = @@ROWCOUNT
		IF @delete_count > 0
		print 'Deleted ' + CONVERT(varchar, @delete_count) + ' records from table [AutoDataAlarms]'
		SET @delete_count = 0

		
		SET @ErrorStep = 'Error in Deleting from AutodataRejections';
		DELETE AutodataRejections FROM AutodataRejections adr
		INNER JOIN machineinformation mi on mi.InterfaceID = adr.mc
		Inner join PlantMachine pm on pm.MachineID = mi.machineid
		INNER JOIN PlantInformation pi on pi.PlantID = pm.PlantID
		where mi.machineid = @MachineID
		SET @delete_count = @@ROWCOUNT
		IF @delete_count > 0
		print 'Deleted ' + CONVERT(varchar, @delete_count) + ' records from table AutodataRejections'
		SET @delete_count = 0


		SET @ErrorStep = 'Error in Deleting from MachineControlInformation';
		DELETE MachineControlInformation FROM MachineControlInformation mc
		INNER JOIN machineinformation mi on mi.machineid = mc.MachineId
		Inner join PlantMachine pm on pm.MachineID = mi.machineid
		INNER JOIN PlantInformation pi on pi.PlantID = pm.PlantID
		where mi.machineid = @MachineID
		SET @delete_count = @@ROWCOUNT
		IF @delete_count > 0
		print 'Deleted ' + CONVERT(varchar, @delete_count) + ' records from table MachineControlInformation'
		SET @delete_count = 0

		SET @ErrorStep = 'Error in Deleting from SmartDataModbusRegisterInfo';
		DELETE SmartDataModbusRegisterInfo FROM SmartDataModbusRegisterInfo mc
		INNER JOIN machineinformation mi on mi.machineid = mc.MachineId
		Inner join PlantMachine pm on pm.MachineID = mi.machineid
		INNER JOIN PlantInformation pi on pi.PlantID = pm.PlantID
		where mi.machineid = @MachineID
		SET @delete_count = @@ROWCOUNT
		IF @delete_count > 0
		print 'Deleted ' + CONVERT(varchar, @delete_count) + ' records from table SmartDataModbusRegisterInfo'
		SET @delete_count = 0

		SET @ErrorStep = 'Error in Deleting from [machinefinanceinformation]';
		DELETE [machinefinanceinformation] FROM [dbo].[machinefinanceinformation] mf
		INNER JOIN machineinformation mi on mi.machineid = mf.MachineId
		Inner join PlantMachine pm on pm.MachineID = mi.machineid
		INNER JOIN PlantInformation pi on pi.PlantID = pm.PlantID
		where mi.machineid = @MachineID
		SET @delete_count = @@ROWCOUNT
		IF @delete_count > 0
		print 'Deleted ' + CONVERT(varchar, @delete_count) + ' records from table [machinefinanceinformation]'
		SET @delete_count = 0

		SET @ErrorStep = 'Error in Deleting from [machinemakeinformation]';
		DELETE [machinemakeinformation] FROM [dbo].[machinemakeinformation] mm
		INNER JOIN machineinformation mi on mi.machineid = mm.MachineId
		Inner join PlantMachine pm on pm.MachineID = mi.machineid
		INNER JOIN PlantInformation pi on pi.PlantID = pm.PlantID
		where mi.machineid = @MachineID
		SET @delete_count = @@ROWCOUNT
		IF @delete_count > 0
		print 'Deleted ' + CONVERT(varchar, @delete_count) + ' records from table [machinemakeinformation]'
		SET @delete_count = 0

		SET @ErrorStep = 'Error in Deleting from machineserviceinformation';
		DELETE machineserviceinformation FROM machineserviceinformation ms
		INNER JOIN machineinformation mi on mi.machineid = ms.MachineId
		Inner join PlantMachine pm on pm.MachineID = mi.machineid
		INNER JOIN PlantInformation pi on pi.PlantID = pm.PlantID
		where mi.machineid = @MachineID
		SET @delete_count = @@ROWCOUNT
		IF @delete_count > 0
		print 'Deleted ' + CONVERT(varchar, @delete_count) + ' records from table machineserviceinformation'
		SET @delete_count = 0


		SET @ErrorStep = 'Error in Deleting from EventCategoryInformation';
		DELETE EventCategoryInformation FROM  [dbo].[EventCategoryInformation] me
		INNER JOIN machineinformation mi on mi.machineid = me.MachineId
		Inner join PlantMachine pm on pm.MachineID = mi.machineid
		INNER JOIN PlantInformation pi on pi.PlantID = pm.PlantID
		where mi.machineid = @MachineID
		SET @delete_count = @@ROWCOUNT
		IF @delete_count > 0
		print 'Deleted ' + CONVERT(varchar, @delete_count) + ' records from table EventCategoryInformation'
		SET @delete_count = 0
		
		SET @ErrorStep = 'Error in Deleting from MachineAlarmInformation';
		DELETE EventCategoryInformation FROM   [dbo].[MachineAlarmInformation] mai
		INNER JOIN machineinformation mi on mi.machineid = mai.MachineId
		Inner join PlantMachine pm on pm.MachineID = mi.machineid
		INNER JOIN PlantInformation pi on pi.PlantID = pm.PlantID
		where mi.machineid = @MachineID
		SET @delete_count = @@ROWCOUNT
		IF @delete_count > 0
		print 'Deleted ' + CONVERT(varchar, @delete_count) + ' records from table MachineAlarmInformation'
		SET @delete_count = 0


		SET @ErrorStep = 'Error in Deleting from PlannedDownTimes';
		DELETE  PlannedDownTimes FROM [dbo].[PlannedDownTimes] pd
		INNER JOIN machineinformation mi on mi.machineid = pd.Machine
		Inner join PlantMachine pm on pm.MachineID = mi.machineid
		INNER JOIN PlantInformation pi on pi.PlantID = pm.PlantID
		where mi.machineid = @MachineID
		SET @delete_count = @@ROWCOUNT
		IF @delete_count > 0
		print 'Deleted ' + CONVERT(varchar, @delete_count) + ' records from table [PlannedDownTimes]'
		SET @delete_count = 0

		
		SET @ErrorStep = 'Error in Deleting from EfficiencyTarget';
		delete EfficiencyTarget from dbo.EfficiencyTarget et
		inner join machineinformation mi on mi.machineid = et.MachineID
		inner join PlantMachine pm on pm.MachineID = mi.machineid
		inner join PlantInformation pi on pi.PlantID = pm.PlantID
		where mi.machineid = @MachineID
		SET @delete_count = @@ROWCOUNT
		IF @delete_count > 0
		print 'Deleted ' + CONVERT(varchar, @delete_count) + ' records from table [EfficiencyTarget]'
		SET @delete_count = 0


		SET @ErrorStep = 'Error in Deleting from machineinformation';
		DELETE machineinformation FROM machineinformation mi
		Inner join PlantMachine pm on pm.MachineID = mi.machineid
		INNER JOIN PlantInformation pi on pi.PlantID = pm.PlantID
		where mi.machineid = @MachineID
		SET @delete_count = @@ROWCOUNT
		IF @delete_count > 0
		print 'Deleted ' + CONVERT(varchar, @delete_count) + ' records from table [machineinformation]'
		SET @delete_count = 0

		SET @ErrorStep = 'Error in Deleting from PlantMachine';
		DELETE PlantMachine FROM [dbo].[PlantMachine] pm
		INNER JOIN PlantInformation pi on pi.PlantID = pm.PlantID
		where pm.MachineID = @MachineID
		SET @delete_count = @@ROWCOUNT
		IF @delete_count > 0
		print 'Deleted ' + CONVERT(varchar, @delete_count) + ' records from table [PlantMachine]'
		SET @delete_count = 0
		
	COMMIT TRAN
    	SET  @ErrorCode  = 0
	Print 'All data was deleted for Machine ='  + @MachineID
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
