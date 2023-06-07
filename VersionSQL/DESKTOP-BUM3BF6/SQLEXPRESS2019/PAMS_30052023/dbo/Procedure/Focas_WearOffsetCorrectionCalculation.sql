/****** Object:  Procedure [dbo].[Focas_WearOffsetCorrectionCalculation]    Committed by VersionSQL https://www.versionsql.com ******/

--select * from inspectionAutodata order by id desc
--exec s_GetProcessDataString 'START-37-20-O4567-T1-DiaId1-C2-<40.06>-20150223-21212125-END','172.1.0.0',1,1
--[dbo].[Focas_WearOffsetCorrectionCalculation] '20'
CREATE PROCEDURE [dbo].[Focas_WearOffsetCorrectionCalculation]
	@machineID nvarchar(50)=''
	
AS
BEGIN
	
	SET NOCOUNT ON;
	declare @Threshold float
	declare @IGNORE_CORRECTION_FOR_DIFF_VALUE float
	--Change the below CONSTANTS value if required, FYI @Threshold in %
	set @IGNORE_CORRECTION_FOR_DIFF_VALUE=0.01
	set @Threshold=75
   


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
	declare @upperLimit decimal(18,3)
	declare @lowerLimit decimal(18,3)
	declare @nominalValue decimal(18,3)
	declare @measuredValue decimal(18,3)
	declare @upperLimitTolerance decimal(18,3)
	declare @lowerLimitTolerance decimal(18,3)
	declare @wearOffsetcorrection decimal(18,3)
	declare @offsetLoctaion  nvarchar(50)	
	declare @OffsetMasterDataID int;
	declare @previousWearOffsetCorrectionValue decimal(18,3);
	
	insert into #Correction(machine,component,operation,featureID,MeasuredValue,OffsetLocation,WearOffsetCorrection,SampleId)
	select MC,comp,opn,FeatureID,MAX(ActualValue),0,0,MAX(SampleID)
	from InspectionAutodata a
	where a.MC = @machineID and a.SampleID = ( select MAX(SampleID) from InspectionAutodata where MC = @machineid) 
	and a.IsProcessed = 0
	group by MC,comp,opn,FeatureID
	having COUNT(*) > 1

	--get the maste data required to calulate the offset correction
	select @upperLimit= w.UpperLimit,@lowerLimit= w.LowerLimit, @nominalValue= w.NominalDimension, @offsetLoctaion= w.OffsetLocation , @OffsetMasterDataID = w.ID
	from Focas_WearOffsetCorrectionMaster as w where w.DimensionId = (select featureID from #Correction)

	update #Correction set OffsetLocation=@offsetLoctaion,OffsetMasterDataID = @OffsetMasterDataID

	select top (1) @previousWearOffsetCorrectionValue= NewWearOffsetValue  from Focas_WearOffsetCorrection Where Focas_WearOffsetCorrectionID = @OffsetMasterDataID order by id desc
		 
    --to calculate @upperlimitTolerance and  @lowerLimitTolerance
	select @upperLimitTolerance=@upperlimit+((@Threshold*( @upperLimit-@nominalValue))/100.0)
	select @lowerLimitTolerance=@lowerLimit+((@Threshold*( @lowerLimit-@nominalValue))/100.0)

	-- to calcuate @wearOffsetcorrection
	select @measuredValue= measuredvalue from #Correction	
	select @wearOffsetcorrection=((@nominalValue-@measuredValue)/2.0)
	
	declare @diff float	
	select @diff=abs(abs(@previousWearOffsetCorrectionValue)-abs(@wearOffsetcorrection))


	if(@previousWearOffsetCorrectionValue is null)
	Begin
	  Begin 
	   if (@measuredValue>=@lowerLimitTolerance and @measuredValue<=@upperLimitTolerance)
		   Begin
		   update #Correction set wearOffsetcorrection=@wearOffsetcorrection,Result = 1,ResultText = 'wearOffsetcorrection Value ' + CAST(@wearOffsetcorrection as NVarchar(50)) + ' will update to Machine using FOCAS.'
		   End
	   else 
		   Begin
		   update #Correction set wearOffsetcorrection='0',Result = 2,
		   ResultText = 'Measured Value ' + CAST(@measuredValue as Nvarchar(50)) + ' is NOT in range. UpperLimit with Tolerance =' + CAST(@upperLimitTolerance as nvarchar(50)) + '; LowerLimit with Tolerance = ' + CAST( @lowerLimitTolerance as NVarchar(50))
		   End
	   End
    End
else
Begin
    if(@diff>@IGNORE_CORRECTION_FOR_DIFF_VALUE)
	  Begin 
	   if (@measuredValue>=@lowerLimitTolerance and @measuredValue<=@upperLimitTolerance)
		   Begin
		   update #Correction set wearOffsetcorrection=@wearOffsetcorrection,Result = 1,ResultText = 'wearOffsetcorrection Value ' + CAST(@wearOffsetcorrection as NVarchar(50)) + ' will update to Machine using FOCAS.'
		   End
	   else 
		   Begin
		   update #Correction set wearOffsetcorrection='0',Result = 2,
		   ResultText = 'Measured Value ' + CAST(@measuredValue as Nvarchar(50)) + ' is NOT in range. UpperLimit with Tolerance =' + CAST(@upperLimitTolerance as nvarchar(50)) + '; LowerLimit with Tolerance = ' + CAST( @lowerLimitTolerance as NVarchar(50))
		   End
	   End
    else
	    Begin
	    update #Correction set wearOffsetcorrection='0',Result = 3,
	    ResultText = 'Previous Offset Correction Value = ' + CAST(@previousWearOffsetCorrectionValue as Nvarchar(50))+ ' and Current Offset Correction =' + CAST(@wearOffsetcorrection as Nvarchar(50))+ '  Value difference is less then IGNORE_CORRECTION Thresold Value =  '  + CAST(@IGNORE_CORRECTION_FOR_DIFF_VALUE as Nvarchar(50))
	    End
End

select * from #Correction

END
