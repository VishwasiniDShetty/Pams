/****** Object:  Procedure [dbo].[Focas_WearOffsetCorrectionValue]    Committed by VersionSQL https://www.versionsql.com ******/

--select * from inspectionAutodata order by id desc
--exec s_GetProcessDataString 'START-37-1-O4567-T1-DiaId1-C02-<40.06>-20150223-21212125-END','172.1.0.0',1,1
--exec s_GetProcessDataString 'START-37-1-O4567-T1-DiaId1-C02-<40.06>-20150223-21212125-END','172.1.0.0',1,1
--[dbo].[Focas_WearOffsetCorrectionValue] '1'

CREATE PROCEDURE [dbo].[Focas_WearOffsetCorrectionValue]
	@machineID nvarchar(50)=''	
AS
BEGIN
	
	SET NOCOUNT ON;		
   
   	CREATE TABLE #Correction
	(
		machine nvarchar(50),
		Component nvarchar(50),
		Operation nvarchar(50),
		featureID nvarchar(50),
		MeasuredValue decimal(18,3),
		OffsetLocation decimal(18,0),
		WearOffsetCorrection decimal(18,3),
		OffsetMasterDataID int,
		SampleId int,
		Result int,
		ResultText nvarchar(1000),
	)
	
	declare @SampleID int;
	declare @FeatureID nvarchar(50);
	declare @upperLimit decimal(18,3)
	declare @lowerLimit decimal(18,3)
	declare @nominalValue decimal(18,3)
	declare @measuredValue decimal(18,3)
	
	declare @wearOffsetcorrection decimal(18,3)
	declare @offsetLoctaion  nvarchar(50)	
	declare @OffsetMasterDataID int;
	
	declare @rowCount int;
	SET @rowCount = 0;
	
	select top 1 @SampleID = SampleID, @FeatureID = FeatureID from InspectionAutodata where MC = @machineid order by ID desc

	select @rowCount = COUNT(*) from InspectionAutodata where MC = @machineid and SampleID = @SampleID

	if(@rowCount <= 1) return 0;
	
	--get the maste data required to calulate the offset correction
	select @nominalValue= w.NominalDimension
	from Focas_WearOffsetCorrectionMaster as w where w.DimensionId = @FeatureID
	
	insert into #Correction(machine,component,operation,featureID,MeasuredValue,OffsetLocation,WearOffsetCorrection,SampleId)
	select top 1 MC,comp,opn,FeatureID,ActualValue,0,abs(@nominalValue - ActualValue) as OffsetCorrection,SampleID
	from InspectionAutodata a
	where a.MC = @machineid and a.SampleID = @SampleID
	and a.IsProcessed = 0 order by OffsetCorrection desc

    select @upperLimit= w.UpperLimit,@lowerLimit= w.LowerLimit, @nominalValue= w.NominalDimension, @offsetLoctaion= w.OffsetLocation , @OffsetMasterDataID = w.ID
	from Focas_WearOffsetCorrectionMaster as w where w.DimensionId = (Select FeatureID from #Correction)

	--get the maste data required to calulate the offset correction
	update #Correction set OffsetLocation=@offsetLoctaion,OffsetMasterDataID = @OffsetMasterDataID


	-- to calcuate @wearOffsetcorrection
	select @measuredValue= measuredvalue from #Correction	
	select @wearOffsetcorrection=((@nominalValue-@measuredValue))

if (@measuredValue>=@lowerLimit and @measuredValue<=@upperLimit)
	Begin
	update #Correction set wearOffsetcorrection=@wearOffsetcorrection,Result = 1,ResultText = 'Offset correction Value ' + CAST(@wearOffsetcorrection as NVarchar(50)) + ' will be update to Machine by FOCAS.'
	End
else 
	Begin
	update #Correction set wearOffsetcorrection='0',Result = 2,
	ResultText = 'Measured Value ' + CAST(@measuredValue as Nvarchar(50)) + ' is NOT in range. UpperLimit =' + CAST(@upperLimit as nvarchar(50)) + '; LowerLimit = ' + CAST( @lowerLimit as NVarchar(50))
	End
End
select * from #Correction
