/****** Object:  Procedure [dbo].[s_InsertComponentMaster]    Committed by VersionSQL https://www.versionsql.com ******/

--exec s_InsertComponentMaster @Param=N'DeleteOpnInfo',@Componentid=N'ZTXAlpha',@CompInterfaceID=N'25',@OpnInterfaceID=N'1',@operationno=N'1',@machineid=N'ACE-02'
--[dbo].[s_InsertComponentMaster] 'DeleteOpnInfo','AMIT-1','TESTComp-1','ACE','','102','','','1','ACE VTL-01,ACE VTL-02','','150','','1','300','100','','','','','','','','','','','','','','','',''
CREATE       PROCEDURE [dbo].[s_InsertComponentMaster]
@Param nvarchar(50)='',
@Componentid nvarchar(50)='',
@description nvarchar(100)='',
@customerid nvarchar(50)='',
@basicvalue float=0,
@CompInterfaceID nvarchar(50)='',
@InputWeight float='',
@ForegingWeight float='',
@operationno int=1,
@machineid nvarchar(4000)='',
@price float=1,
@cycletime float='',
@drawingno nvarchar(50)='1',
@OpnInterfaceID nvarchar(4)='',
@loadunload bigint=0,
@machiningtime float='',
@SubOperations int=1,
@StdSetupTime float='',
@MachiningTimeThreshold int=0,
@TargetPercent int=100,
@UpdatedBy nvarchar(50)='',
@UpdatedTS datetime='',
@LowerEnergyThreshold float='',
@UpperEnergyThreshold float='',
@SCIThreshold float='',
@DCLThreshold float='',
@McTimeMonitorLThreshold float='',
@McTimeMonitorUThreshold float='',
@StdDieCloseTime float='',
@StdPouringTime float='',
@StdSolidificationTime float='',
@StdDieOpenTime float='',
@FinishedOperation int='',
@MinLoadUnloadThreshold float='',
@Process nvarchar(50)=''
AS
BEGIN

Create table #Machine
(
	Slno int identity(1,1) NOT NULL,
	MachineID nvarchar(50),
	Interfaceid nvarchar(50)
)

Declare @i as int
Declare @CountOFMachines as int
Declare @MachineName as nvarchar(50)
Declare @Curtime as datetime
Select @Curtime = Getdate()

Declare @TimeFormat as nvarchar(20)
Select @TimeFormat = ISNULL(valueintext,'ss')  from shopdefaults where parameter='TimeInFormat'

If @Param = 'InsertCompInfo'
BEGIN

		IF EXISTS(select * from ComponentInformation where Componentid<>@Componentid and interfaceid=@CompInterfaceID)
		BEGIN
			RAISERROR('This interfaceID already exists for another component',16,1)
			return -1;
		END


		IF NOT EXISTS(select * from ComponentInformation where Componentid=@Componentid)
		BEGIN
			Insert InTo ComponentInformation(Componentid, description, customerid, basicvalue, InterfaceID, InputWeight, ForegingWeight)
			SELECT @Componentid, @description, @customerid, @basicvalue, @CompInterfaceID, @InputWeight, @ForegingWeight
			Return
		END

		IF EXISTS(select * from ComponentInformation where Componentid=@Componentid)
		BEGIN
			Update ComponentInformation SET description=@description, customerid=@customerid, basicvalue=@basicvalue, InterfaceID=@CompInterfaceID, InputWeight=@InputWeight, ForegingWeight=@ForegingWeight
			where Componentid=@Componentid
			Return
		END
END

If @param = 'DeleteCompInfo'
BEGIN
	Declare @CountOfComp as int
	Select @CountOfComp = ISNULL(Count(*),0) from Autodata where Comp = @CompInterfaceID

	If @CountOfComp > 0
	Begin
		RAISERROR('Component is in use.You are not allowed to delete this component',16,1)
		Return -1;
	end
	ELSE
	Begin
		delete from componentoperationpricing where componentid=@Componentid
		delete from componentinformation where interfaceid=@CompInterfaceID
	END
END


If @Param = 'InsertCompOpnInfo'
BEGIN

		Insert into #Machine(MachineID)
		Select Item from SplitStrings(@MachineID,',')


		IF NOT EXISTS(select * from componentinformation where componentid=@Componentid)
		BEGIN
			RAISERROR('Select an existing component or first save the component',16,1)
			return -1;
		END


		IF EXISTS(select * from  componentoperationpricing where componentid = @Componentid and interfaceid=@OpnInterfaceID and operationno <>@operationno)
		BEGIN
			RAISERROR('This interfaceid  already exists for another Operation',16,1)
			return -1;
		END

		Select @i=1
		Select @CountOFMachines=Count(*) from #Machine


		While @i<=@CountOFMachines
		BEGIN
			Select @MachineName = Machineid from #Machine where SlNo=@i
			
			If @TimeFormat = 'ss'
			BEGIN

				IF EXISTS(select * from componentoperationpricing where Machineid=@MachineName and Componentid=@Componentid and Operationno=@operationno)
				BEGIN
					Update componentoperationpricing 
					SET InterfaceID=@OpnInterfaceID,description=@description,price=@price, cycletime=@cycletime, drawingno=@drawingno,loadunload=@loadunload, machiningtime=@machiningtime, SubOperations=@SubOperations, StdSetupTime=@StdSetupTime, 
					MachiningTimeThreshold=@MachiningTimeThreshold, TargetPercent=@TargetPercent, UpdatedBy=@UpdatedBy, UpdatedTS=@Curtime, LowerEnergyThreshold=@LowerEnergyThreshold, UpperEnergyThreshold=@UpperEnergyThreshold, SCIThreshold=@SCIThreshold, DCLThreshold=@DCLThreshold, 
					McTimeMonitorLThreshold=@McTimeMonitorLThreshold, McTimeMonitorUThreshold=@McTimeMonitorUThreshold, StdDieCloseTime=@StdDieCloseTime, StdPouringTime=@StdPouringTime, StdSolidificationTime=@StdSolidificationTime, StdDieOpenTime=@StdDieOpenTime,FinishedOperation=@FinishedOperation,MinLoadUnloadThreshold=@MinLoadUnloadThreshold,Process=@Process
					where Machineid=@MachineName and Componentid=@Componentid and Operationno=@operationno
				END

				IF NOT EXISTS(select * from componentoperationpricing where Machineid=@MachineName and Componentid=@Componentid and Operationno=@operationno)
				BEGIN
					Insert Into componentoperationpricing( componentid, operationno, description, machineid, price, cycletime, drawingno, InterfaceID, loadunload, machiningtime, SubOperations, StdSetupTime, 
						  MachiningTimeThreshold, TargetPercent, UpdatedBy, UpdatedTS, LowerEnergyThreshold, UpperEnergyThreshold, SCIThreshold, DCLThreshold, 
						  McTimeMonitorLThreshold, McTimeMonitorUThreshold, StdDieCloseTime, StdPouringTime, StdSolidificationTime, StdDieOpenTime,FinishedOperation,MinLoadUnloadThreshold,Process)
					Select  @componentid, @operationno, @description, @MachineName, @price, @cycletime, @drawingno, @OpnInterfaceID, @loadunload, @machiningtime, @SubOperations, @StdSetupTime, 
						  @MachiningTimeThreshold, @TargetPercent, @UpdatedBy, @Curtime, @LowerEnergyThreshold, @UpperEnergyThreshold, @SCIThreshold, @DCLThreshold, 
						  @McTimeMonitorLThreshold, @McTimeMonitorUThreshold, @StdDieCloseTime, @StdPouringTime, @StdSolidificationTime, @StdDieOpenTime,@FinishedOperation,@MinLoadUnloadThreshold,@Process
				END

			END
			ELSE
			BEGIN

				IF EXISTS(select * from componentoperationpricing where Machineid=@MachineName and Componentid=@Componentid and Operationno=@operationno)
				BEGIN
					Update componentoperationpricing 
					SET InterfaceID=@OpnInterfaceID,description=@description,price=@price, cycletime=Round(@cycletime*60,2), drawingno=@drawingno,loadunload=Round(@loadunload*60,2), machiningtime=Round(@machiningtime*60,2), SubOperations=@SubOperations, StdSetupTime=Round(@StdSetupTime*60,2), 
					MachiningTimeThreshold=@MachiningTimeThreshold, TargetPercent=@TargetPercent, UpdatedBy=@UpdatedBy, UpdatedTS=@Curtime, LowerEnergyThreshold=@LowerEnergyThreshold, UpperEnergyThreshold=@UpperEnergyThreshold, SCIThreshold=@SCIThreshold, DCLThreshold=@DCLThreshold, 
					McTimeMonitorLThreshold=@McTimeMonitorLThreshold, McTimeMonitorUThreshold=@McTimeMonitorUThreshold, StdDieCloseTime=@StdDieCloseTime, StdPouringTime=@StdPouringTime, StdSolidificationTime=@StdSolidificationTime, StdDieOpenTime=@StdDieOpenTime,FinishedOperation=@FinishedOperation,MinLoadUnloadThreshold=@MinLoadUnloadThreshold,Process=@Process
					where Machineid=@MachineName and Componentid=@Componentid and  Operationno=@operationno
				END

				IF NOT EXISTS(select * from componentoperationpricing where Machineid=@MachineName and Componentid=@Componentid and Operationno=@operationno)
				BEGIN
					Insert Into componentoperationpricing( componentid, operationno, description, machineid, price, cycletime, drawingno, InterfaceID, loadunload, machiningtime, SubOperations, StdSetupTime, 
						  MachiningTimeThreshold, TargetPercent, UpdatedBy, UpdatedTS, LowerEnergyThreshold, UpperEnergyThreshold, SCIThreshold, DCLThreshold, 
						  McTimeMonitorLThreshold, McTimeMonitorUThreshold, StdDieCloseTime, StdPouringTime, StdSolidificationTime, StdDieOpenTime,FinishedOperation,MinLoadUnloadThreshold,Process)
					Select  @componentid, @operationno, @description, @MachineName, @price, Round(@cycletime*60,2), @drawingno, @OpnInterfaceID, Round(@loadunload*60,2), Round(@machiningtime*60,2), @SubOperations, Round(@StdSetupTime*60,2), 
						  @MachiningTimeThreshold, @TargetPercent, @UpdatedBy, @Curtime, @LowerEnergyThreshold, @UpperEnergyThreshold, @SCIThreshold, @DCLThreshold, 
						  @McTimeMonitorLThreshold, @McTimeMonitorUThreshold, @StdDieCloseTime, @StdPouringTime, @StdSolidificationTime, @StdDieOpenTime,@FinishedOperation,@MinLoadUnloadThreshold,@Process
				END
			END
		Select @i= @i + 1
		END
		
END

If @param = 'DeleteOpnInfo'
BEGIN

	Insert into #Machine(MachineID)
	Select Item from SplitStrings(@MachineID,',')

	Update #Machine set interfaceid = T1.interfaceid from
	(Select distinct Machineid,interfaceid from Machineinformation)T1 inner join #Machine on #Machine.MachineID=T1.MachineID

	Declare @CountOfOpn as int
	Select @CountOfOpn = ISNULL(Count(*),0) from Autodata where Opn =@OpnInterfaceID and Comp = @CompInterfaceID and mc in(Select distinct interfaceid from #Machine) 

	If @CountOfOpn > 0
	Begin
		RAISERROR('Operation is in use.You are not allowed to delete this Operation',16,1)
		Return -1;
	end
	ELSE
	Begin
		Select @i=1
		Select @CountOFMachines=Count(*) from #Machine

		While @i<=@CountOFMachines
		BEGIN
			Select @MachineName = Machineid from #Machine where SlNo=@i
			Delete from componentoperationpricing where componentid=@Componentid and Machineid=@MachineName and interfaceid=@OpnInterfaceID
			Select @i = @i + 1
		END

	END
END


END
