/****** Object:  Procedure [dbo].[Focas_WearOffsetCorrectionCalculations]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[Focas_WearOffsetCorrectionCalculations] '20'
CREATE PROCEDURE [dbo].[Focas_WearOffsetCorrectionCalculations]
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
OffsetLocation decimal(18,3),
WearOffsetCorrection decimal(18,3)
)

insert into #Correction(machine,component,operation,featureID,MeasuredValue,OffsetLocation,WearOffsetCorrection)
select MC,comp,opn,FeatureID,MAX(ActualValue),0,0
from InspectionAutodata a
where a.MC = '20' and a.SampleID = ( select MAX(SampleID) from InspectionAutodata where MC = '20') 
and a.IsProcessed = 0
group by MC,comp,opn,FeatureID
having COUNT(*) > 1

--get the offset location value form Focas_WearOffsetCorrectionMaster
declare @offsetLoctaion  nvarchar(50)

select @offsetLoctaion= w.OffsetLocation from Focas_WearOffsetCorrectionMaster as w where w.DimensionId = (select FeatureID as ActualValue
from InspectionAutodata a
where a.MC = @machineID and a.SampleID = ( select MAX(SampleID) from InspectionAutodata where MC = @machineId) 
and a.IsProcessed = 0
group by MC,comp,FeatureID
having COUNT(*) > 1)

update #Correction set OffsetLocation=@offsetLoctaion

--to get the WearOffsetCorrection (Calculation)
	declare @upperLimit float
	declare @lowerLimit float
	declare @nominalValue float
	declare @measuredValue float
	declare @upperLimitTolerance float
	declare @lowerLimitTolerance float
	declare @wearOffsetcorrection float
--to get upperlimit value from Focas_WearOffsetCorrectionMaster 
	select @upperLimit= w.UpperLimit from Focas_WearOffsetCorrectionMaster as w where w.DimensionId = (select FeatureID as ActualValue
	from InspectionAutodata a
	where a.MC = @machineId and a.SampleID = ( select MAX(SampleID) from InspectionAutodata where MC = @machineId) 
	and a.IsProcessed = 0
	group by MC,comp,FeatureID
	having COUNT(*) > 1)
--to get lowerlimit value from Focas_WearOffsetCorrectionMaster 
	select @lowerLimit= w.LowerLimit from Focas_WearOffsetCorrectionMaster as w where w.DimensionId = (select FeatureID as ActualValue
	from InspectionAutodata a
	where a.MC = @machineId and a.SampleID = ( select MAX(SampleID) from InspectionAutodata where MC = @machineId) 
	and a.IsProcessed = 0
	group by MC,comp,FeatureID
	having COUNT(*) > 1)
--to calculate nomialvalue
	select @nominalValue= w.NominalDimension from Focas_WearOffsetCorrectionMaster as w where w.DimensionId = (select FeatureID as ActualValue
	from InspectionAutodata a
	where a.MC = @machineId and a.SampleID = ( select MAX(SampleID) from InspectionAutodata where MC = @machineId) 
	and a.IsProcessed = 0
	group by MC,comp,FeatureID
	having COUNT(*) > 1)

--to calculate @upperlimitTolerance and  @lowerLimitTolerance
	select @upperLimitTolerance=@upperlimit+((75*( @upperLimit-@nominalValue))/100)
	select @lowerLimitTolerance=@lowerLimit+((75*( @lowerLimit-@nominalValue))/100)

-- to calcuate @wearOffsetcorrection
select @measuredValue= measuredvalue from #Correction
select @wearOffsetcorrection=((@nominalValue-@measuredValue)/2)


if (@measuredValue>=@lowerLimitTolerance and @measuredValue<=@upperLimitTolerance)
	Begin
	update #Correction set wearOffsetcorrection=@wearOffsetcorrection
	End
else 
	Begin
	update #Correction set wearOffsetcorrection=NULL
	End
 
select * from #Correction
	

END
