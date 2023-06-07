/****** Object:  Procedure [dbo].[SP_EwayBillDetailsSaveAndView_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE procedure [dbo].[SP_EwayBillDetailsSaveAndView_Pams]
@Pams_DCNo nvarchar(50)='',
@RequestDepartment nvarchar(50)='',
@RequestNo nvarchar(50)='',
@RequestedBy nvarchar(50)='',
@VehicleNo nvarchar(50)='',
@NatureOfTransport nvarchar(50)='',
@ValidUpTo nvarchar(50)='',
@PreparedBy nvarchar(50)='',
@UpdatedVy nvarchar(50)='',
@UpdatedTS DATETIME='',
@EwayBillNo nvarchar(50)='',
@Value nvarchar(50)='',
@DCStatus nvarchar(50)='',
@AccountsUpdatedBy nvarchar(50)='',
@AccountsUpdatedTS DATETIME='',
@AccountStatus nvarchar(50)='',
@updatedby nvarchar(50)='',
@FromDate datetime='',
@ToDate datetime='',
@price nvarchar(50)='',
@MaterialID nvarchar(50)='',
@PartID nvarchar(50)='',
@Process nvarchar(2000)='',
@MJCNo nvarchar(50)='',
@PJCNo nvarchar(50)='',
@Param nvarchar(50)=''
as
begin
	if @Param='StoresEditView'
	begin
		select * from EWayBillDetails_Pams where pams_dcno=@Pams_DCNo
	end

	if @Param='EwaySave'
	begin
		if not exists(select * from EWayBillDetails_Pams where pams_dcno=@Pams_DCNo)
		begin
			insert into EWayBillDetails_Pams(pams_dcno,requestDepartment,requestNo,requestedby,vehicleno,natureoftransport,preparedby,updatedby,updatedts,DCStatus)
			values(@pams_dcno,@requestDepartment,@requestNo,@requestedby,@vehicleno,@natureoftransport,@preparedby,@updatedby,@updatedts,@DCStatus)
		end
		else
		begin
			update EWayBillDetails_Pams set requestDepartment=@RequestDepartment,requestNo=@RequestNo,requestedby=@RequestedBy,vehicleno=@VehicleNo,natureoftransport=@NatureOfTransport,validupto=@ValidUpTo,
			preparedby=@PreparedBy,updatedby=@updatedby,updatedts=@UpdatedTS
			where pams_dcno=@Pams_DCNo
		end
	end

	if @Param='PrintView'
	begin
		select e1.*,D1.GRNNO,d1.MaterialID,d1.PartID,f1.PartDescription,r2.MaterialDescription,d1.Process,d1.Vendor,d1.HSNCode,d1.UOM,d1.Qty_KG,d1.Qty_Numbers,d1.DCDate,d1.Bin,d1.Value as DCValue,D1.DCType,R3.PartLength_mm,R3.CuttingAllowance,R3.EndBitAllowance,d1.MJCNo,d1.PJCNo,d1.price from EWayBillDetails_Pams e1 
		left join DCNoGeneration_PAMS d1 on d1.Pams_DCNo=e1.Pams_DCNo
		left join FGDetails_PAMS f1 on f1.PartID=d1.PartID
		left join RawMaterialDetails_PAMS r2 on d1.MaterialID=r2.MaterialID
		LEFT JOIN RawMaterialAndFGAssociation_PAMS R3 ON D1.MaterialID=R3.MaterialID AND D1.PartID=R3.PartID
		where e1.pams_dcno=@Pams_DCNo	and d1.Vendor<>'PAMS Internal'
	end

	if @Param='AccountsView'
	begin
		select e1.*, d1.Vendor,v1.GSTNumber from EWayBillDetails_Pams e1
		inner join (select distinct Pams_DCNo,vendor from DCNoGeneration_PAMS) d1 on e1.Pams_DCNo=d1.Pams_DCNo
		left join VendorDetails_PAMS v1 on d1.Vendor=v1.VendorID where-- pams_dcno=@Pams_DCNo and  
		(convert(nvarchar(10),updatedts,126)>=@FromDate and  convert(nvarchar(10),updatedts,126)<=@ToDate) and dcstatus='DC No. generated and confirmed' and d1.Vendor<>'PAMS Internal'
	end


	if @Param='AccountsUpdate'
	begin
		update EWayBillDetails_Pams set ValidUpTo=@ValidUpTo,Value=@Value,EwayBillNo=@EwayBillNo,AccountsUpdatedBy=@AccountsUpdatedBy,AccountsUpdatedTS=@AccountsUpdatedTS,AccountSatus=@AccountStatus,vehicleno=@VehicleNo,natureoftransport=@NatureOfTransport
		where pams_dcno=@Pams_DCNo
	end

	if @Param='MaterialPriceUpdate'
	begin	
		update DCNoGeneration_PAMS set price=@price where Pams_DCNo=@Pams_DCNo and MaterialID=@MaterialID and PartID=@PartID and Process=@Process and (MJCNo=@MJCNo or isnull(@MJCNo,'')='') and (PJCNo=@PJCNo or isnull(@PJCNo,'')='')		
	end

	if @Param='GateUpdate'
	begin
		update EWayBillDetails_Pams set AccountSatus=@AccountStatus
		where pams_dcno=@Pams_DCNo
	end
end
