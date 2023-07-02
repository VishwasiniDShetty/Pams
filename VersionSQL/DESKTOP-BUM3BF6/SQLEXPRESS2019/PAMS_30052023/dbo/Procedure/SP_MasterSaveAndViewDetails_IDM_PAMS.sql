/****** Object:  Procedure [dbo].[SP_MasterSaveAndViewDetails_IDM_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[SP_MasterSaveAndViewDetails_IDM_PAMS]
@Item nvarchar(50)='',
@Param nvarchar(50)='',
@ID nvarchar(50)='',
@Make nvarchar(50)='',
@RangeMin nvarchar(50)='',
@RangeMax nvarchar(50)='',
@LeastCount float=0,
@PutToUseOn datetime='',
@Remarks nvarchar(max)='',
@Location nvarchar(50)='',
@Instrument_Range nvarchar(50)='',
@Instrument_LSL nvarchar(50)='',
@Instrument_USL nvarchar(50)='',
@Category nvarchar(50)='',
@Operating_MinValue float=0,
@Operating_MaxValue float=0,
@Tolerance nvarchar(50)='',
@AcceptableCriteria nvarchar(50)='',
@RequiredLeastCount float=0,
@ActualLeastCount float=0,
@Calibration_Freq nvarchar(50)='',
@ErrorObserved nvarchar(100)='',
@Status nvarchar(50)='',
@PartID nvarchar(50)='',
@Stage nvarchar(50)='',
@GuageSize nvarchar(50)='',
@GuageSizeMin nvarchar(50)='',
@GuageSizeMax nvarchar(50)='',
@GOSide nvarchar(50)='',
@AttributeType nvarchar(50)='',
@NoGoSide nvarchar(50)='',
@Specification nvarchar(50)='',
@itemcategory nvarchar(50)='',
@IDMType nvarchar(50)='',
@IDMItemtype nvarchar(50)='',
@ObservedReadings nvarchar(100)='',
@Error nvarchar(50)='',
@DateOfCalibration date='',
@Next_CalibrationDueOn date='',
@CheckedBy nvarchar(50)='',
@CheckedtS datetime='',
@InstrumentName nvarchar(50)='',
@InstrumentNo nvarchar(50)='',
@CertificateNo nvarchar(100)='',
@SetNo nvarchar(50)='',
@MinimumOrderQty float=0,
@ShelfLife float=0,
@Uom nvarchar(50)='',
@Type nvarchar(50)=''

as
begin

if isnull(@PutToUseOn,'')=''
begin
	set @PutToUseOn=null
end


	------------------------------------------------------------------------MeasuringInstrument Master---------------------------------------------------------------------------------------------------------
	if @Param='MeasuringInstrumentMasterView'
	begin
		select m1.*,c3.DateOfCalibration,c3.Next_CalibrationDueOn,c3.status,c3.remarks,c3.Checkedby,c3.CheckedTS,c3.CertificateNo from MeasuringInstrumentMaster_IDM_Pams m1
		left join (select distinct c1.ItemCategory,c1.IDMType,c1.IDMItemType,c1.ID_No,c1.DateOfCalibration,c1.Next_CalibrationDueOn,c1.Checkedby,c1.Checkedts,c1.status,c1.remarks,c1.CertificateNo from CalibrationHistoryDetails_IDM_Pams c1 inner join 
		(select distinct ItemCategory,IDMType,IDMItemType,ID_No,MAX(Checkedts) AS Checkedts from CalibrationHistoryDetails_IDM_Pams group by
		 ItemCategory,IDMType,IDMItemType,ID_No) C2  ON c1.ItemCategory=c2.ItemCategory and c1.IDMItemType=c2.IDMItemType and c1.IDMType=c2.IDMType and C1.ID_No=C2.ID_NO AND C1.Checkedts=C2.Checkedts) c3
		on m1.ID_No=c3.id_no and m1.ItemCategory=c3.ItemCategory and m1.IDMType=c3.IDMType and m1.IDMItemType=c3.IDMItemType 
	END
	if @Param='MeasuringInstrumentMasterSave'
	begin
		if not exists(select * from MeasuringInstrumentMaster_IDM_Pams where ID_No=@ID)
		begin
			insert into MeasuringInstrumentMaster_IDM_Pams(ID_No,Item,Make,RangeMin,RangeMax,LeastCount,CalibrationFreq,PutToUseOn,Remarks,ItemCategory,IDMType,IDMItemType,PartID,Location)
			values(@ID,@Item,@Make,@RangeMin,@RangeMax,@LeastCount,@Calibration_Freq,@PutToUseOn,@Remarks,@ItemCategory,@IDMType,@IDMItemtype,@PartID,@Location)
		end
		else
		begin
			update MeasuringInstrumentMaster_IDM_Pams set Item=@Item,Make=@Make,RangeMin=@RangeMin,RangeMax=@RangeMax,LeastCount=@LeastCount,location=@Location,
			CalibrationFreq=@Calibration_Freq,PutToUseOn=@PutToUseOn,Remarks=@Remarks
			where ID_No=@ID
		end
	end
	if @Param='MeasuringInstrumentMasterDelete'
	begin
		delete from MeasuringInstrumentMaster_IDM_Pams where ID_No=@ID
	end

	------------------------------------------------------------------------MeasuringInstrument Master--------------------------------------------------------------------------------------------------------


		------------------------------------------------------------------------PressureGuagesMaster starts---------------------------------------------------------------------------------------------------------
	if @Param='PressureGuagesMasterView'
	begin
		select m1.*,c3.DateOfCalibration,c3.Next_CalibrationDueOn,c3.status,c3.remarks,c3.Checkedby,c3.Checkedts,c3.CertificateNo from PressureGuagesMaster_IDM_Pams m1
		left join (select distinct c1.ItemCategory,c1.IDMType,c1.IDMItemType, c1.ID_No,c1.DateOfCalibration,c1.Next_CalibrationDueOn,c1.Checkedby,c1.Checkedts,c1.status,c1.remarks,c1.CertificateNo from CalibrationHistoryDetails_IDM_Pams c1 inner join 
		(select distinct ItemCategory,IDMType,IDMItemType, ID_No,MAX(Checkedts) AS Checkedts from CalibrationHistoryDetails_IDM_Pams group by 
		ID_No,ItemCategory,IDMType,IDMItemType) C2 ON c1.ItemCategory=c2.ItemCategory and c1.IDMType=c2.IDMType and c1.IDMItemType=c2.IDMItemType and C1.ID_No=C2.ID_NO AND C1.Checkedts=C2.Checkedts) c3
		on m1.ID_No=c3.id_no and m1.ItemCategory=c3.ItemCategory and m1.IDMType=c3.IDMType and m1.IDMItemType=c3.IDMItemType
	END
	if @Param='PressureGuagesMasterSave'
	begin
		if not exists(select * from PressureGuagesMaster_IDM_Pams where ID_No=@ID)
		begin
			insert into PressureGuagesMaster_IDM_Pams(ID_No,make,Location,Instrument_Range,Instrument_LSL,Instrument_USL,Category,Operating_MinValue,Operating_MaxValue,
			Tolerance,AcceptableCriteria,RequiredLeastCount,ActualLeastCount,Calibration_Freq,ErrorObserved,Status,PartID,PutToUseOn,ItemCategory,IDMType,IDMItemType)
			values(@ID,@make,@Location,@Instrument_Range,@Instrument_LSL,@Instrument_USL,@Category,@Operating_MinValue,@Operating_MaxValue,
			@Tolerance,@AcceptableCriteria,@RequiredLeastCount,@ActualLeastCount,@Calibration_Freq,@ErrorObserved,@Status,@PartID,@PutToUseOn,@itemcategory,@IDMType,@IDMItemtype)
		end
		else
		begin
			update PressureGuagesMaster_IDM_Pams set make=@Make,Location=@Location,Instrument_Range=@Instrument_Range,Instrument_LSL=@Instrument_LSL,
			Instrument_USL=@Instrument_USL,Category=@Category,Operating_MinValue=@Operating_MinValue,Operating_MaxValue=@Operating_MaxValue,
			Tolerance=@Tolerance,AcceptableCriteria=@AcceptableCriteria,RequiredLeastCount=@RequiredLeastCount,ActualLeastCount=@ActualLeastCount,
			Calibration_Freq=@Calibration_Freq,ErrorObserved=@ErrorObserved,Status=@Status,PartID=@PartID,PutToUseOn=@PutToUseOn
			where ID_No=@ID
		end
	end
	if @Param='PressureGuagesMasterDelete'
	begin
		delete from PressureGuagesMaster_IDM_Pams where ID_No=@ID
	end

	------------------------------------------------------------------------PressureGuagesMaster ends---------------------------------------------------------------------------------------------------------

	------------------------------------------------------------------------ARGMPG_APGMRG Master starts---------------------------------------------------------------------------------------------------------
	
	if @Param='ARGMPG_APGMRGView'
	begin

		select m1.*,c3.DateOfCalibration,c3.Next_CalibrationDueOn,c3.status,c3.remarks,c3.Checkedby,c3.Checkedts,c3.CertificateNo from ARGMPG_APGMRG_IDM_Pams m1
		left join (select distinct c1.ItemCategory,c1.IDMType,c1.IDMItemType,c1.ID_No,c1.DateOfCalibration,c1.Next_CalibrationDueOn,c1.Checkedby,c1.Checkedts,c1.status,c1.remarks,c1.CertificateNo from CalibrationHistoryDetails_IDM_Pams c1 inner join 
		(select distinct ItemCategory,IDMType,IDMItemType,ID_No,MAX(Checkedts) AS Checkedts from CalibrationHistoryDetails_IDM_Pams 
		group by ID_No,ItemCategory,IDMType,IDMItemType) C2 ON c1.ItemCategory=c2.ItemCategory and c1.IDMItemType=c2.IDMItemType and c1.IDMType=c2.IDMType and C1.ID_No=C2.ID_NO AND C1.Checkedts=C2.Checkedts) c3
		on m1.ID_No=c3.id_no and m1.ItemCategory=c3.ItemCategory and m1.IDMType=c3.IDMType and m1.IDMItemType=c3.IDMItemType

	END

	if @Param='ARGMPG_APGMRGSave'
	begin
		if not exists(select * from ARGMPG_APGMRG_IDM_Pams where ID_No=@ID and PartID=@PartID and setno=@setno)
		begin
			insert into ARGMPG_APGMRG_IDM_Pams(ID_No,Make,Stage,GuageSize,GuageSizeMin,GuageSizeMax,CalibrationFreq,PartID,PutToUseOn,Remarks,ItemCategory,IDMType,IDMItemType,Location,SetNo,MinimumOrderQty,ShelfLife,Uom,Type)
			values(@id,@Make,@Stage,@GuageSize,@GuageSizeMin,@GuageSizeMax,@Calibration_Freq,@PartID,@PutToUseOn,@Remarks,@itemcategory,@IDMType,@IDMItemtype,@Location,@SetNo,@MinimumOrderQty,@ShelfLife,@Uom,@Type)
		end
		else
		begin
			update ARGMPG_APGMRG_IDM_Pams set Make=@Make,Stage=@Stage,GuageSize=@GuageSize,GuageSizeMin=@GuageSizeMin,GuageSizeMax=@GuageSizeMax,location=@Location,
			CalibrationFreq=@Calibration_Freq,PartID=@PartID,PutToUseOn=@PutToUseOn,Remarks=@Remarks,MinimumOrderQty=@MinimumOrderQty,ShelfLife=@ShelfLife,Uom=@Uom,Type=@Type
			where  ID_No=@ID and PartID=@PartID and setno=@setno
		end
	end
	if @Param='ARGMPG_APGMRGDelete'
	begin
		delete from ARGMPG_APGMRG_IDM_Pams where ID_No=@ID and PartID=@PartID and setno=@setno
	end

	------------------------------------------------------------------------ARGMPG_APGMRG Master ends---------------------------------------------------------------------------------------------------------
	------------------------------------------------------------------------AttributeType Master starts---------------------------------------------------------------------------------------------------------
	
	if @Param='AttributeTypeMasterView'
	begin
		--select *  from AttributeTypeMaster_IDM_Pams 		
		select m1.*,c3.DateOfCalibration,c3.Next_CalibrationDueOn,c3.status,c3.remarks,c3.Checkedby,c3.Checkedts,c3.CertificateNo from AttributeTypeMaster_IDM_Pams m1
		left join (select distinct c1.ID_No,c1.DateOfCalibration,c1.Next_CalibrationDueOn,c1.Checkedby,c1.Checkedts,c1.status,c1.remarks,c1.CertificateNo from CalibrationHistoryDetails_IDM_Pams c1 inner join 
		(select distinct ID_No,MAX(Checkedts) AS Checkedts from CalibrationHistoryDetails_IDM_Pams group by ID_No) C2 ON C1.ID_No=C2.ID_NO AND C1.Checkedts=C2.Checkedts) c3
		on m1.ID_No=c3.id_no
		where m1.AttributeType=@AttributeType

	END
	if @Param='AttributeTypeMasterSave'
	begin
		if not exists(select * from AttributeTypeMaster_IDM_Pams where ID_No=@ID)
		begin
			insert into AttributeTypeMaster_IDM_Pams(ID_No,AttributeType,Range_Min,Range_Max,GOSide,Tolerance,NoGoSide,Specification,CalibrationFreq,PartID,PutToUseOn,Remarks,ItemCategory,IDMType,IDMItemType,Location)
			values(@id,@AttributeType,@RangeMin,@RangeMax,@GOSide,@Tolerance,@NoGoSide,@Specification,@Calibration_Freq,@PartID,@PutToUseOn,@Remarks,@itemcategory,@IDMType,@IDMItemtype,@Location)
		end
		else
		begin
			update AttributeTypeMaster_IDM_Pams set AttributeType=@AttributeType,Range_Min=@RangeMin,Range_Max=@RangeMax,
			GOSide=@GOSide,Tolerance=@Tolerance,NoGoSide=@NoGoSide,Specification=@Specification,CalibrationFreq=@Calibration_Freq,PartID=@PartID,PutToUseOn=@PutToUseOn,Remarks=@Remarks,Location=@Location
			where  ID_No=@ID
		end
	end
	if @Param='AttributeTypeMasterDelete'
	begin
		delete from AttributeTypeMaster_IDM_Pams where ID_No=@ID
	end

	------------------------------------------------------------------------AttributeType Master ends---------------------------------------------------------------------------------------------------------

	--------------------------------------------------------Calibration save-------------------------------------------------------------
	if @Param='CalibrationView'
	begin
		select * from CalibrationHistoryDetails_IDM_Pams where  ID_No=@ID
	end

	if @Param='CalibrationSave'
	begin
		if not exists(select * from CalibrationHistoryDetails_IDM_Pams where ID_No=@ID and InstrumentName=@InstrumentName and InstrumentNo=@InstrumentNo and CertificateNo=@CertificateNo)
		BEGIN
			INSERT INTO CalibrationHistoryDetails_IDM_Pams(itemcategory,IDMType,IDMItemtype,ID_No,InstrumentName,InstrumentNo,CertificateNo, Partname,ObservedReadings,Error,DateOfCalibration,Next_CalibrationDueOn,Status,remarks,CheckedBy,CheckedtS)
			VALUES(@itemcategory,@IDMType,@IDMItemtype,@ID,@InstrumentName,@InstrumentNo,@CertificateNo, @partid,@ObservedReadings,@Error,@DateOfCalibration,@Next_CalibrationDueOn,@Status,@remarks,@CheckedBy,@CheckedtS)
		end
		else
		begin
			update CalibrationHistoryDetails_IDM_Pams set ObservedReadings=@ObservedReadings,Error=@Error,DateOfCalibration=@DateOfCalibration,Next_CalibrationDueOn=@Next_CalibrationDueOn,
			Status=@Status,remarks=@Remarks,CheckedBy=@CheckedBy,CheckedtS=@CheckedtS
			where ID_No=@ID and InstrumentName=@InstrumentName and InstrumentNo=@InstrumentNo and CertificateNo=@CertificateNo
		end
	end
end
