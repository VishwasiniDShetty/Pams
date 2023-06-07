/****** Object:  Procedure [dbo].[Focas_WearOffsetCorrectionMasterView]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[Focas_WearOffsetCorrectionMasterView] '111','1','1','1','1','0','0','0','0','0','0','insert'
CREATE PROCEDURE [dbo].[Focas_WearOffsetCorrectionMasterView]
	@machineID nvarchar(50)='',
	@programNumber nvarchar(50)='',
	@ToolNumber nvarchar(50)=0,
	@WearOffsetNumber nvarchar(50)=0,
	@offsetLocation int=0,
	@GaugeID nvarchar(50)=0,
	@DimensionId nvarchar(50)=0,
	@NominalDimension float=0,
	@LowerLimit float=0,
	@upperLimit float=0,
	@DefaultWearOffsetValue float=0,
	@param nvarchar(20)=''

AS
BEGIN
	
	SET NOCOUNT ON;

IF @param='View'    
Begin  
select ROW_NUMBER() OVER(ORDER BY ID DESC) as ID,MachineID,ProgramNumber,ToolNumber,WearOffsetNumber,[OffsetLocation],[GaugeID]
,[DimensionId],[NominalDimension],[LowerLimit],[UpperLimit],[DefaultWearOffsetValue] from [dbo].[Focas_WearOffsetCorrectionMaster]
  where (@machineID is null or machineId=@machineID) and (@programNumber is null OR ProgramNumber=@programNumber)
END

IF @param='Insert'    
Begin  
Insert  into [dbo].[Focas_WearOffsetCorrectionMaster]([MachineId],[ProgramNumber],[ToolNumber],[WearOffsetNumber],[OffsetLocation],[GaugeID],[DimensionId],[NominalDimension],[LowerLimit],[UpperLimit],[DefaultWearOffsetValue])    
values(@machineID,@programNumber,@ToolNumber,@WearOffsetNumber,@offsetLocation,@GaugeID,@DimensionId,@NominalDimension,@LowerLimit,@upperLimit,@DefaultWearOffsetValue)
End


IF @param = 'Update'
Begin
 update [dbo].[Focas_WearOffsetCorrectionMaster] set LastUpdatedTime=GETDATE(),OffsetLocation=@offsetLocation,GaugeID=@GaugeID,DimensionId=@DimensionId,NominalDimension=@NominalDimension,LowerLimit=@LowerLimit,UpperLimit=@upperLimit,DefaultWearOffsetValue=@DefaultWearOffsetValue
 where machineID=@machineID and ProgramNumber=@programNumber and ToolNumber = @ToolNumber and WearOffsetNumber = @WearOffsetNumber
 select * from [Focas_WearOffsetCorrectionMaster]
End


END
