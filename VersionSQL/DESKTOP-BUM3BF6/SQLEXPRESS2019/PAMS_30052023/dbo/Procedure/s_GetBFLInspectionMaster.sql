/****** Object:  Procedure [dbo].[s_GetBFLInspectionMaster]    Committed by VersionSQL https://www.versionsql.com ******/

 --[dbo].[s_GetBFLInspectionMaster] 'Metal','83135','2','SIZE 1','','500.0210','500.0200','500.0220',' M-APG100220','XYC101','1','Insert'
 --[dbo].[s_GetBFLInspectionMaster] 'Metal','83135','2','SIZE 1','1','500.0225','500.0210','500.0250',' M-APG100220','XYC101','1','update'
 --[dbo].[s_GetBFLInspectionMaster] 'Metal','83135','2','','1','','','','','','','delete'

CREATE    PROCEDURE [dbo].[s_GetBFLInspectionMaster]
@MachineID nvarchar(50),
@ComponentID nvarchar(50), 
@OperationNo nvarchar(50), 
@CharacteristicCode nvarchar(50)='', 
@CharacteristicID int='', 
@SpecificationMean nvarchar(50)='', 
@LSL nvarchar(50)='', 
@USL nvarchar(50)='',
@UOM nvarchar(50)='',
@SampleSize nvarchar(50)='',
@InProcessInterval nvarchar(50)='',
@InstrumentType nvarchar(50)='',
@InspectionDrawing nvarchar(50)='',
@Datatype nvarchar(50)='',
@SetupApprovalInterval nvarchar(50)='',
@Interval  nvarchar(50)='',
@Specification nvarchar(50)='', 
@MacroLocation int='',
@Param nvarchar(50)

WITH RECOMPILE
AS
BEGIN

SET NOCOUNT ON;


If @param='Insert'
BEGIN

	Declare @NewCharacteristicID as nvarchar(50)
	Select @NewCharacteristicID = Isnull(Max(CharacteristicID),0) from SPC_Characteristic where machineid=@MachineID and ComponentID=@ComponentID and OperationNo=@OperationNo
	select @NewCharacteristicID = @NewCharacteristicID + 1

	Insert into SPC_Characteristic(MachineID, ComponentID, OperationNo, CharacteristicCode, CharacteristicID, SpecificationMean, LSL, USL, UOM, SampleSize, InProcessInterval, InstrumentType, 
    InspectionDrawing, Datatype, SetupApprovalInterval, Interval, Specification, MacroLocation)
	Select  @MachineID, @ComponentID, @OperationNo, @CharacteristicCode, @NewCharacteristicID, @SpecificationMean, @LSL, @USL, @UOM, @SampleSize, @InProcessInterval,@InstrumentType,
    @InspectionDrawing, @Datatype, @SetupApprovalInterval, @Interval, @Specification, @MacroLocation

END

If @param='Update'
Begin
	 update SPC_Characteristic set 	CharacteristicCode=@CharacteristicCode,SpecificationMean=@SpecificationMean,LSL=@LSL, USL=@USL,UOM=@UOM,SampleSize=@SampleSize,
	 InProcessInterval=@InProcessInterval,InstrumentType=@InstrumentType,Datatype=@Datatype,SetupApprovalInterval=@SetupApprovalInterval,Interval=@Interval,
     InspectionDrawing=@InspectionDrawing, Specification=@Specification, MacroLocation=@MacroLocation where MachineID=@MachineID and ComponentID=@ComponentID and OperationNo=@OperationNo and CharacteristicID=@CharacteristicID
END

If @param='Delete'
Begin
	Delete From SPC_Characteristic where MachineID=@MachineID and ComponentID=@ComponentID and OperationNo=@OperationNo and CharacteristicID=@CharacteristicID
END

END
