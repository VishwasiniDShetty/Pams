/****** Object:  Procedure [dbo].[s_InsertMachineMaster]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE       PROCEDURE [dbo].[s_InsertMachineMaster]
@Param nvarchar(50)='',
@machineid nvarchar(50),
@description nvarchar(150)='',
@status smallint=0,
@mchrrate float=0,
@portno smallint=0,
@settings nvarchar(50)='',
@InterfaceID nvarchar(4)='',
@IP nvarchar(20)='',
@IPPortNO nvarchar(10)='',
@mode smallint=0,
@autoload smallint =0,
@TPMTrakEnabled smallint=0,
@PEGreen smallint=85,
@PERed smallint=70,
@AEGreen smallint=95,
@AERed smallint=85,
@OEGreen smallint=80,
@OERed smallint=65,
@BulkDataTransferPortNo nvarchar(50)='',
@MultiSpindleFlag [bit]=0,
@DeviceType smallint =2,
@PPTransferEnabled bit =0,
@SmartTransEnabled bit=0,
@IgnoreCoFromMach nvarchar(10)='',
@AutoSetupchangeDown nvarchar(25)='N',
@MachinewiseOwner nvarchar(50)='',
@CriticalMachineEnabled bit='',
@DAPEnabled smallint=0,
@Lowerpowerthreshold float='' ,
@upperpowerthreshold float='',
@QERED smallint='',
@QEGreen smallint='',
@EthernetEnabled bit=0,
@Nto1Device bit=0,
@TargetAE float='', 
@TargetPE float='', 
@TargetQE float='', 
@TargetOE float='',
@StartDate Datetime='',
@EndDate Datetime='',
@ControlName nvarchar(50)='',
@pStartId NVARCHAR(10)='',
@pEndId NVARCHAR(10)='',
@FileNameFrom NVARCHAR(50)='',
@ReceiveAtMachineFilePath NVARCHAR(500)='', 
@SentFromMachineFilePath nvarchar(500)='',
@NodeInterface nvarchar(50)='', 
@NodeId nvarchar(50)='', 
@SortOrder int='',
@manufacturer nvarchar(100)='', 
@dateofmanufacture smallDatetime='',
@address nvarchar(100)='',
@place nvarchar(100)='',
@phone nvarchar(50)='',
@contactperson nvarchar(100)='',
@MobileEnabled bit=0

AS
BEGIN

	If @param='InsertMachineInfo'
	Begin

		If EXISTS(select * from machineinformation where interfaceid=@InterfaceID and machineid <>@Machineid)
		BEGIN
			RAISERROR('This interfaceID already exists for another machine',16,1)
			return -1;
		END

		If EXISTS(select * from machineinformation where IP=@IP and machineid <>@Machineid)
		BEGIN
			RAISERROR('This IPaddress already exists for another machine',16,1)
			return -1;
		END

		IF EXISTS(select * from machineinformation where (Mode=1 OR Mode=0) AND portno=@IPPortNO and machineid <> @Machineid)
		begin
			RAISERROR('This Portnumber already exists',16,1)
			return -1;
		END

		If EXISTS(select * from onlinemachinelist where Machineid=@Machineid )
		BEGIN
			RAISERROR('When machine is online you cannot change the setup',16,1)
			return -1;
		END


		Declare @NoOfMachineLicensed as int
		select @NoOfMachineLicensed = noofmachine from company
		select @NoOfMachineLicensed 
		
		Declare @NoOfMachines as int
		SELECT @NoOfMachines = COUNT(*)FROM machineinformation WHERE TPMTrakEnabled = 1
		SELECT @NoOfMachines
		

		If @NoOfMachineLicensed < @NoOfMachines
		Begin
			RAISERROR('You have used up your TPM-Trak licenses.To enable TPM-Trak on more machines, Please contact AMIT Pvt.Ltd',16,1)
			Return -1;
		END
		ELSE
		BEGIN

			If NOT EXISTS(select * from machineinformation where machineid =@Machineid)--interfaceid<>@InterfaceID and machineid =@Machineid and portno<>@IPPortNO)
			BEGIN
			
					Insert Into machineinformation(machineid, description, status, mchrrate, portno, settings, InterfaceID, IP, IPPortNO, mode, autoload, TPMTrakEnabled,  
					 BulkDataTransferPortNo, MultiSpindleFlag, DeviceType, PPTransferEnabled, SmartTransEnabled, IgnoreCoFromMach, AutoSetupchangeDown, 
					MachinewiseOwner, CriticalMachineEnabled, DAPEnabled, Lowerpowerthreshold, upperpowerthreshold,  EthernetEnabled, Nto1Device,MobileEnabled)
					SELECT @machineid, @description, @status, @mchrrate, @portno, @settings, @InterfaceID, @IP, @IPPortNO, @mode, @autoload, @TPMTrakEnabled,  
					 @BulkDataTransferPortNo, @MultiSpindleFlag, @DeviceType, @PPTransferEnabled, @SmartTransEnabled, @IgnoreCoFromMach, @AutoSetupchangeDown, 
					@MachinewiseOwner, @CriticalMachineEnabled, @DAPEnabled, @Lowerpowerthreshold, @upperpowerthreshold, @EthernetEnabled, @Nto1Device,@MobileEnabled

			END
			ELSE
			BEGIN
		
		
			if not  exists(select * from onlinemachinelist where machineid=@machineid)
			BEGIN
			Update Machineinformation SET description=@description, status=@status, mchrrate=@mchrrate, settings=@settings, InterfaceID=@InterfaceID, 
			mode=@mode, autoload=@autoload, TPMTrakEnabled=@TPMTrakEnabled, 
			MultiSpindleFlag=@MultiSpindleFlag, DeviceType=@DeviceType, PPTransferEnabled=@PPTransferEnabled, 
			SmartTransEnabled=@SmartTransEnabled, IgnoreCoFromMach=@IgnoreCoFromMach, AutoSetupchangeDown=@AutoSetupchangeDown, 
			MachinewiseOwner=@MachinewiseOwner, CriticalMachineEnabled=@CriticalMachineEnabled, DAPEnabled=@DAPEnabled, Lowerpowerthreshold=@Lowerpowerthreshold, 
			upperpowerthreshold=@upperpowerthreshold, EthernetEnabled=@EthernetEnabled, Nto1Device=@Nto1Device,MobileEnabled=@MobileEnabled
			Where machineid=@Machineid
			END
			else
			BEGIN
			
			Update Machineinformation SET description=@description, status=@status, mchrrate=@mchrrate, portno=@portno, settings=@settings, InterfaceID=@InterfaceID, 
			IP=@IP, IPPortNO=@IPPortNO, mode=@mode, autoload=@autoload, TPMTrakEnabled=@TPMTrakEnabled, BulkDataTransferPortNo=@BulkDataTransferPortNo, MultiSpindleFlag=@MultiSpindleFlag, DeviceType=@DeviceType, PPTransferEnabled=@PPTransferEnabled,
			SmartTransEnabled=@SmartTransEnabled, IgnoreCoFromMach=@IgnoreCoFromMach, AutoSetupchangeDown=@AutoSetupchangeDown, 
			MachinewiseOwner=@MachinewiseOwner, CriticalMachineEnabled=@CriticalMachineEnabled, DAPEnabled=@DAPEnabled, Lowerpowerthreshold=@Lowerpowerthreshold, 
			upperpowerthreshold=@upperpowerthreshold,  EthernetEnabled=@EthernetEnabled, Nto1Device=@Nto1Device,MobileEnabled=@MobileEnabled
			Where machineid=@Machineid

			END



			END

		END

	END

	If @param='EffColorCode'
	Begin

		If EXISTS(select * from machineinformation where machineid=@Machineid)
		BEGIN
			Update Machineinformation SET PEGreen=@PEGreen, PERed=@PERed, AEGreen=@AEGreen, AERed=@AERed, 
			OEGreen=@OEGreen,OERed=@OERed,QERED=@QERED, QEGreen=@QEGreen Where machineid=@Machineid
		END

	End

	If @param = 'InsertMachineMakeInfo'
	Begin

		If EXISTS(select machineid from machinemakeinformation where machineid=@Machineid)
		BEGIN
			update machinemakeinformation set manufacturer=@manufacturer,dateofmanufacture=@dateofmanufacture,address=@address,place=@place,phone=@phone,
			contactperson=@contactperson  where machineid=@machineid
			return -1;
		END

		If NOT EXISTS(select machineid from machinemakeinformation where machineid=@Machineid)
		BEGIN
			insert into machinemakeinformation (machineid,manufacturer,dateofmanufacture,address,place,phone,contactperson)
			Select @machineid,@manufacturer,@dateofmanufacture,@address,@place,@phone,@contactperson
			return -1;
		END
	End

	If @param = 'InsertEffTarget'
	BEGIN

	   IF Not Exists(select * from EfficiencyTarget where datepart(year,StartDate)=datepart(year,@StartDate))
	   Begin
			declare @Sofmonth as datetime
			declare @Eofmonth as datetime
			Select @Sofmonth=cast(datepart(year,@StartDate) as nvarchar(4))+'-'+'01'+'-'+'01'
			Select @Eofmonth=cast(datepart(year,@StartDate) as nvarchar(4))+'-'+'12'+'-'+'01'

			While @Sofmonth<=@Eofmonth
			Begin
			Insert into EfficiencyTarget(MachineID, StartDate, EndDate, AE, PE, QE, OE, LogicalDayStart, LogicalDayEnd, TargetLevel)
			SELECT MachineID, [dbo].[f_GetPhysicalMonth](@Sofmonth,'Start'), [dbo].[f_GetPhysicalMonth](@Sofmonth,'End'), 90, 100, 100, 85, NULL, NULL, 'MONTH' from machineinformation
			select @Sofmonth=dateadd(month,1,@Sofmonth)
			End
	   End
	
		IF NOT EXISTS(select machineid from EfficiencyTarget where MachineID = @MachineID and Targetlevel = 'MONTH' and DatePart(Month, startdate) = DatePart(Month, @startdate) And DatePart(Year, startdate) = DatePart(YEAR, @startdate))
		BEGIN
			Insert into EfficiencyTarget(MachineID, StartDate, EndDate, AE, PE, QE, OE, LogicalDayStart, LogicalDayEnd, TargetLevel)
			SELECT @MachineID, @StartDate, @EndDate, @TargetAE, @TargetPE, @TargetQE, @TargetOE, NULL, NULL, 'MONTH'

		END
		ELSE
		BEGIN
			Update EfficiencyTarget SET AE= case when isnull(@TargetAE,'')<>'' then @TargetAE else AE End, 
			PE=case when isnull(@TargetPE,'')<>'' then @TargetPE else PE End, 
			QE=case when isnull(@TargetQE,'')<>'' then @TargetQE else QE End, 
			OE=case when isnull(@TargetOE,'')<>'' then @TargetOE else OE End
			where MachineID = @MachineID and StartDate=@StartDate and Targetlevel = 'MONTH'
		END

		IF EXISTS(select machineid from machineinformation where machineid=@MachineID)
		BEGIN
			Update machineinformation SET MachinewiseOwner=@MachinewiseOwner, CriticalMachineEnabled=@CriticalMachineEnabled Where machineid=@Machineid
		END

	END

	If @Param = 'InsertMachineControlInfo'
	Begin
	
		IF NOT EXISTS(select machineid from MachineControlInformation where MachineID = @MachineID)
		BEGIN
			INSERT INTO MachineControlInformation(MachineId, ControlName, pStartId, pEndId, FileNameFrom, ReceiveAtMachineFilePath, SentFromMachineFilePath)
			SELECT @MachineId, @ControlName, @pStartId, @pEndId, @FileNameFrom, @ReceiveAtMachineFilePath, @SentFromMachineFilePath
		END
		ELSE
		BEGIN
			UPDATE MachineControlInformation SET ControlName=@ControlName, pStartId=@pStartId, pEndId=@pEndId, FileNameFrom=@FileNameFrom, ReceiveAtMachineFilePath=@ReceiveAtMachineFilePath, SentFromMachineFilePath=@SentFromMachineFilePath
			where MachineID = @MachineID
		enD

	ENd


	If @Param = 'InsertNodeInfo'
	BEGIN

		If EXISTS(select * from MachineNodeInformation where Machineid=@Machineid and Nodeid=@NodeId)
		BEGIN
			RAISERROR('This node already exists',16,1)
			return -1;
		End 

		If NOT EXISTS(select * from MachineNodeInformation where Machineid=@Machineid and Nodeid=@NodeId)
		BEGIN
			insert into machinenodeinformation( MachineId, NodeInterface, NodeId, SortOrder)
			Select  @MachineId, @NodeInterface, @NodeId, @SortOrder
		END
	END


	If @Param = 'DeleteNodeInfo'
	BEGIN

		Create table #Machine
		(
			Slno int identity(1,1) NOT NULL,
			MachineID nvarchar(50)
		)

		Declare @i as int
		Declare @CountOFMachines as int
		Declare @MachineName as nvarchar(50)

		Insert into #Machine(MachineID)
		Select Item from SplitStrings(@MachineID,',')


		Select @i=1
		Select @CountOFMachines=Count(*) from #Machine


		While @i<=@CountOFMachines
		BEGIN
			Select @MachineName = Machineid from #Machine where SlNo=@i
			Delete From machinenodeinformation Where Machineid=@MachineName
			Select @i = @i + 1
		END
	END

END
