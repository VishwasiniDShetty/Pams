/****** Object:  Procedure [dbo].[SP_InspectionMasterSaveAndView_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE procedure [dbo].[SP_InspectionMasterSaveAndView_PAMS]
@Process nvarchar(2000)='',
@ReportType nvarchar(2000)='',
@ProcessType nvarchar(100)='',
@ComponentID NVARCHAR(50)='',
@OperationNo nvarchar(50)='',
@RawMaterial nvarchar(50)='',
@SpecialCharacteristic nvarchar(100)='',
@CharacteristicID INT=0,
@CharacteristicCode nvarchar(2000)='',
@Specification nvarchar(100)='',
@MeasuringMethod nvarchar(50)='',
@RevID int=0,
@RevNo nvarchar(50)='',
@RevDate datetime='',
@NoOfSamples nvarchar(50)='',
@MeasuringInstrument nvarchar(50)='',
@MeasuredValue nvarchar(100)='',
@ControlType nvarchar(50)='',
@ControlValue nvarchar(50)='',
@LSL nvarchar(50)='',
@USL nvarchar(50)='',
@SortOrder int=0,
@NewRevDate datetime='',
@NewRevNo nvarchar(50)='',
@NewRevID NVARCHAR(50)='',
@IsMandatory bit=0,
@Param nvarchar(50)='',
@RowID nvarchar(50)=''
as
begin

if @Param='Save'
begin
if @ProcessType='RM'
BEGIN
	if not exists(select * from InspectionMasterRMLevel_PAMS where process=@Process and reporttype=@ReportType and ProcessType=@ProcessType AND Rawmaterial=@Rawmaterial and  revno=@revno and CharacteristicCode=@CharacteristicCode)
	begin
		insert into InspectionMasterRMLevel_PAMS(Process,ReportType,ProcessType,RawMaterial,SpecialCharacteristic,CharacteristicCode,Specification,MeasuringMethod,
		RevID,RevNo,RevDate,NoOfSamples,MeasuringInstrument,MeasuredValue,ControlType,ControlValue,LSL,USL,SortOrder,IsMandatory)
		values(@Process,@ReportType,@ProcessType,@RawMaterial,@SpecialCharacteristic,@CharacteristicCode,@Specification,@MeasuringMethod,@RevID,@RevNo,@RevDate,
		@NoOfSamples,@MeasuringInstrument,@MeasuredValue,@ControlType,@ControlValue,@LSL,@USL,@SortOrder,@IsMandatory)
	end
	else
	begin
		update InspectionMasterRMLevel_PAMS set SpecialCharacteristic=@SpecialCharacteristic,Specification=@Specification,MeasuringMethod=@MeasuringMethod,NoOfSamples=@NoOfSamples,
		MeasuringInstrument=@MeasuringInstrument,MeasuredValue=@MeasuredValue,ControlType=@ControlType,ControlValue=@ControlValue,LSL=@LSL,USL=@USL,SortOrder=@SortOrder,IsMandatory=@IsMandatory
		where process=@Process and reporttype=@ReportType and ProcessType=@ProcessType AND Rawmaterial=@Rawmaterial and  revno=@revno and CharacteristicCode=@CharacteristicCode
	end
END
ELSE
BEGIN
	if not exists(select * from InspectionMasterFG_PAMS where process=@Process and reporttype=@ReportType and ProcessType=@ProcessType and isnull(componentid,'')=isnull(@componentid,'')
	and isnull(OperationNo,'')=isnull(@OperationNo,'')  and  revno=@revno and CharacteristicCode=@CharacteristicCode)
	begin
		insert into InspectionMasterFG_PAMS(Process,ReportType,ProcessType,ComponentID,OperationNo,SpecialCharacteristic,CharacteristicCode,Specification,MeasuringMethod,
		RevID,RevNo,RevDate,NoOfSamples,MeasuringInstrument,MeasuredValue,ControlType,ControlValue,LSL,USL,SortOrder,IsMandatory)
		values(@Process,@ReportType,@ProcessType,@ComponentID,@OperationNo,@SpecialCharacteristic,@CharacteristicCode,@Specification,@MeasuringMethod,@RevID,@RevNo,@RevDate,
		@NoOfSamples,@MeasuringInstrument,@MeasuredValue,@ControlType,@ControlValue,@LSL,@USL,@SortOrder,@IsMandatory)
	end
	else
	begin
		update InspectionMasterFG_PAMS set SpecialCharacteristic=@SpecialCharacteristic,Specification=@Specification,MeasuringMethod=@MeasuringMethod,NoOfSamples=@NoOfSamples,
		MeasuringInstrument=@MeasuringInstrument,MeasuredValue=@MeasuredValue,ControlType=@ControlType,ControlValue=@ControlValue,LSL=@LSL,USL=@USL,SortOrder=@SortOrder,IsMandatory=@IsMandatory
		where process=@Process and reporttype=@ReportType and ProcessType=@ProcessType and isnull(componentid,'')=isnull(@componentid,'')
		and isnull(OperationNo,'')=isnull(@OperationNo,'')  and  revno=@revno and CharacteristicCode=@CharacteristicCode
	end
END
end

if @Param='View'
begin
	if @ProcessType='RM'
	BEGIN
		SELECT * FROM InspectionMasterRMLevel_PAMS WHERE Process=@Process AND ReportType=@ReportType and ProcessType=@ProcessType
		AND (RawMaterial=@RawMaterial) and (RevNo=@RevNo) 
		order by SortOrder,CharacteristicCode
	END
	ELSE
	BEGIN
		SELECT * FROM InspectionMasterFG_PAMS WHERE Process=@Process AND ReportType=@ReportType and ProcessType=@ProcessType
		 and (componentid=@ComponentID ) AND (OperationNo=@OperationNo or isnull(@OperationNo,'')='') 
		and (RevNo=@RevNo)
		order by SortOrder,CharacteristicCode
	END
	 
end

if @Param='MasterCopy'
begin
	if @ProcessType='RM'
	BEGIN
		if not exists(select * from InspectionMasterRMLevel_PAMS where process=@Process and reporttype=@ReportType and ProcessType=@ProcessType and RawMaterial=@RawMaterial
		and CharacteristicCode=@CharacteristicCode and  revno=@NewRevNo)
		begin
			insert into InspectionMasterRMLevel_PAMS(Process,ReportType,ProcessType,RawMaterial,SpecialCharacteristic,CharacteristicCode,Specification,MeasuringMethod,
			RevID,RevNo,RevDate,NoOfSamples,MeasuringInstrument,MeasuredValue,ControlType,ControlValue,LSL,USL,SortOrder,IsMandatory)
			select Process,ReportType,ProcessType,RawMaterial,SpecialCharacteristic,CharacteristicCode,Specification,MeasuringMethod,
			@NewRevID,@NewRevNo,@NewRevDate,NoOfSamples,MeasuringInstrument,MeasuredValue,ControlType,ControlValue,LSL,USL,SortOrder,IsMandatory from InspectionMasterRMLevel_PAMS 
			where process=@Process and reporttype=@ReportType and ProcessType=@ProcessType and (RawMaterial=@RawMaterial or isnull(@RawMaterial,'')='') and CharacteristicCode=@CharacteristicCode and  revno=@RevNo
		END
    END
	ELSE
	BEGIN
		if not exists(select * from InspectionMasterFG_PAMS where process=@Process and reporttype=@ReportType and ProcessType=@ProcessType and ComponentID=@ComponentID 
		AND OperationNo=@OperationNo and CharacteristicCode=@CharacteristicCode and  revno=@NewRevNo)
		begin
			insert into InspectionMasterFG_PAMS(Process,ReportType,ProcessType,ComponentID,OperationNo,SpecialCharacteristic,CharacteristicCode,Specification,MeasuringMethod,
			RevID,RevNo,RevDate,NoOfSamples,MeasuringInstrument,MeasuredValue,ControlType,ControlValue,LSL,USL,SortOrder,IsMandatory)
			select Process,ReportType,ProcessType,ComponentID,OperationNo,SpecialCharacteristic,CharacteristicCode,Specification,MeasuringMethod,
			@NewRevID,@NewRevNo,@NewRevDate,NoOfSamples,MeasuringInstrument,MeasuredValue,ControlType,ControlValue,LSL,USL,SortOrder,IsMandatory from InspectionMasterFG_PAMS 
			where process=@Process and reporttype=@ReportType and ProcessType=@ProcessType and  ComponentID=@ComponentID AND OperationNo=@OperationNo
			and CharacteristicCode=@CharacteristicCode and  revno=@RevNo
		END
	END

end

if @Param='ValidateRevNo'
begin
	if @ProcessType='RM'
	BEGIN
		if  exists(select * from InspectionMasterRMLevel_PAMS where process=@Process and reporttype=@ReportType and ProcessType=@ProcessType and RawMaterial=@RawMaterial
		and  revno=@NewRevNo)
		begin
			select 'Exists' as Flag
		end
		else
		begin
			SELECT MAX(REVID) as Flag FROM InspectionMasterRMLevel_PAMS WHERE Process=@Process AND ReportType=@ReportType AND  ProcessType=@ProcessType and (RawMaterial=@RawMaterial or isnull(@RawMaterial,'')='')
		end
	 end
	 else
	 begin
		 if  exists(select * from InspectionMasterFG_PAMS where process=@Process and reporttype=@ReportType and ProcessType=@ProcessType  and ComponentID=@ComponentID
		AND OperationNo=@OperationNo and  revno=@NewRevNo)
		begin
			select 'Exists' as Flag
		end
		else
		begin
			SELECT MAX(REVID) as Flag FROM InspectionMasterFG_PAMS WHERE Process=@Process AND ReportType=@ReportType and ProcessType=@ProcessType AND (ComponentID=@ComponentID or isnull(@ComponentID,'')='') AND (OperationNo=@OperationNo or isnull(@OperationNo,'')='')
		end
	 end
end

if @Param='ListRevNo'
begin
	if @ProcessType='RM'
	BEGIN
		select distinct revno,revid from InspectionMasterRMLevel_PAMS WHERE Process=@Process AND ReportType=@ReportType AND  ProcessType=@ProcessType and (RawMaterial=@RawMaterial or isnull(@RawMaterial,'')='')
		order by revid desc
	end
	else
	begin
		select distinct revno,revid from InspectionMasterFG_PAMS WHERE Process=@Process AND ReportType=@ReportType AND  ProcessType=@ProcessType and (ComponentID=@ComponentID or isnull(@ComponentID,'')='')
		AND (OperationNo=@OperationNo or isnull(@OperationNo,'')='')
		order by revid desc
	END


END

if @Param='Delete'
begin
	if @ProcessType='RM'
	BEGIN
		delete from InspectionMasterRMLevel_PAMS where RowID=@RowID
	end
	else
	begin
		delete from InspectionMasterFG_PAMS where RowID=@RowID
	end

end

end
