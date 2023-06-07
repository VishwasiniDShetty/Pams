/****** Object:  Procedure [dbo].[SP_MasterSaveAndViewDetails_IDM_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[SP_MasterSaveAndViewDetails_IDM_PAMS]
@Item nvarchar(50)='',
@Param nvarchar(50)='',
@ID nvarchar(50)='',
@Make nvarchar(50)='',
@RangeMin nvarchar(50)='',
@RangeMax nvarchar(50)='',
@LeastCount float=0,
@PutToUseOn nvarchar(50)='',
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
@CertificateNo nvarchar(100)=''

as
begin




	------------------------------------------------------------------------MeasuringInstrument Master---------------------------------------------------------------------------------------------------------
	if @Param='MeasuringInstrumentMasterView'
	begin
		select m1.*,c3.DateOfCalibration,c3.Next_CalibrationDueOn,c3.status,c3.remarks,c3.Checkedby,c3.CheckedTS,c3.CertificateNo from MeasuringInstrumentMaster_IDM_Pams m1
		left join (select distinct c1.ID_No,c1.DateOfCalibration,c1.Next_CalibrationDueOn,c1.Checkedby,c1.Checkedts,c1.status,c1.remarks,c1.CertificateNo from CalibrationHistoryDetails_IDM_Pams c1 inner join 
		(select distinct ID_No,MAX(Checkedts) AS Checkedts from CalibrationHistoryDetails_IDM_Pams group by ID_No) C2 ON C1.ID_No=C2.ID_NO AND C1.Checkedts=C2.Checkedts) c3
		on m1.ID_No=c3.id_no
	END
	if @Param='MeasuringInstrumentMasterSave'
	begin
		if not exists(select * from MeasuringInstrumentMaster_IDM_Pams where ID_No=@ID)
		begin
			insert into MeasuringInstrumentMaster_IDM_Pams(ID_No,Item,Make,RangeMin,RangeMax,LeastCount,CalibrationFreq,PutToUseOn,Remarks)
			values(@ID,@Item,@Make,@RangeMin,@RangeMax,@LeastCount,@Calibration_Freq,@PutToUseOn,@Remarks)
		end
		else
		begin
			update MeasuringInstrumentMaster_IDM_Pams set Item=@Item,Make=@Make,RangeMin=@RangeMin,RangeMax=@RangeMax,LeastCount=@LeastCount,
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
		left join (select distinct c1.ID_No,c1.DateOfCalibration,c1.Next_CalibrationDueOn,c1.Checkedby,c1.Checkedts,c1.status,c1.remarks,c1.CertificateNo from CalibrationHistoryDetails_IDM_Pams c1 inner join 
		(select distinct ID_No,MAX(Checkedts) AS Checkedts from CalibrationHistoryDetails_IDM_Pams group by ID_No) C2 ON C1.ID_No=C2.ID_NO AND C1.Checkedts=C2.Checkedts) c3
		on m1.ID_No=c3.id_no
	END
	if @Param='PressureGuagesMasterSave'
	begin
		if not exists(select * from PressureGuagesMaster_IDM_Pams where ID_No=@ID)
		begin
			insert into PressureGuagesMaster_IDM_Pams(ID_No,make,Location,Instrument_Range,Instrument_LSL,Instrument_USL,Category,Operating_MinValue,Operating_MaxValue,
			Tolerance,AcceptableCriteria,RequiredLeastCount,ActualLeastCount,Calibration_Freq,ErrorObserved,Status,PartID,PutToUseOn)
			values(@ID,@make,@Location,@Instrument_Range,@Instrument_LSL,@Instrument_USL,@Category,@Operating_MinValue,@Operating_MaxValue,
			@Tolerance,@AcceptableCriteria,@RequiredLeastCount,@ActualLeastCount,@Calibration_Freq,@ErrorObserved,@Status,@PartID,@PutToUseOn)
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
		left join (select distinct c1.ID_No,c1.DateOfCalibration,c1.Next_CalibrationDueOn,c1.Checkedby,c1.Checkedts,c1.status,c1.remarks,c1.CertificateNo from CalibrationHistoryDetails_IDM_Pams c1 inner join 
		(select distinct ID_No,MAX(Checkedts) AS Checkedts from CalibrationHistoryDetails_IDM_Pams group by ID_No) C2 ON C1.ID_No=C2.ID_NO AND C1.Checkedts=C2.Checkedts) c3
		on m1.ID_No=c3.id_no

	END

	if @Param='ARGMPG_APGMRGSave'
	begin
		if not exists(select * from ARGMPG_APGMRG_IDM_Pams where ID_No=@ID)
		begin
			insert into ARGMPG_APGMRG_IDM_Pams(ID_No,Make,Stage,GuageSize,GuageSizeMin,GuageSizeMax,CalibrationFreq,PartID,PutToUseOn,Remarks)
			values(@id,@Make,@Stage,@GuageSize,@GuageSizeMin,@GuageSizeMax,@Calibration_Freq,@PartID,@PutToUseOn,@Remarks)
		end
		else
		begin
			update ARGMPG_APGMRG_IDM_Pams set Make=@Make,Stage=@Stage,GuageSize=@GuageSize,GuageSizeMin=@GuageSizeMin,GuageSizeMax=@GuageSizeMax,
			CalibrationFreq=@Calibration_Freq,PartID=@PartID,PutToUseOn=@PutToUseOn,Remarks=@Remarks
			where  ID_No=@ID
		end
	end
	if @Param='ARGMPG_APGMRGDelete'
	begin
		delete from ARGMPG_APGMRG_IDM_Pams where ID_No=@ID
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

	END
	if @Param='AttributeTypeMasterSave'
	begin
		if not exists(select * from AttributeTypeMaster_IDM_Pams where ID_No=@ID)
		begin
			insert into AttributeTypeMaster_IDM_Pams(ID_No,AttributeType,Range_Min,Range_Max,GOSide,Tolerance,NoGoSide,Specification,CalibrationFreq,PartID,PutToUseOn,Remarks)
			values(@id,@AttributeType,@RangeMin,@RangeMax,@GOSide,@Tolerance,@NoGoSide,@Specification,@Calibration_Freq,@PartID,@PutToUseOn,@Remarks)
		end
		else
		begin
			update AttributeTypeMaster_IDM_Pams set AttributeType=@AttributeType,Range_Min=@RangeMin,Range_Max=@RangeMax,
			GOSide=@GOSide,Tolerance=@Tolerance,NoGoSide=@NoGoSide,Specification=@Specification,CalibrationFreq=@Calibration_Freq,PartID=@PartID,PutToUseOn=@PutToUseOn,Remarks=@Remarks
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
