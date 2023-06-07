/****** Object:  Procedure [dbo].[SP_DCGateExitScreen_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

/*
exec SP_DCGateExitScreen_PAMS @Vendor=N'D.M. Engineering',@PamsDCNumber=N'RDC/2/2023-24',@Param=N'View'
*/
CREATE procedure [dbo].[SP_DCGateExitScreen_PAMS]
@Vendor nvarchar(50)='',
@PamsDCNumber nvarchar(50)='',
@VehicleNumber nvarchar(50)='',
@Driverphonenumber nvarchar(500)='',
@SecurityName nvarchar(50)='',
@DriverName nvarchar(50)='',
@UpdatedBy nvarchar(50)='',
@UpdatedTS datetime='',
@Status nvarchar(50)='',
@Param nvarchar(50)=''
AS
BEGIN
if @Param='View'
begin
	select d1.Vendor,d1.Pams_DCNo,d1.GRNNo,d1.MaterialID,d1.PartID,d1.Process,d1.Qty_KG,d1.Qty_Numbers,d1.UOM,d1.HSNCode,d1.Bin,d1.Value,d1.DCDate,d1.DCStatus,d2.VehicleNumber,
	d2.DriverName,d2.Driverphonenumber,d2.SecurityName,d2.UpdatedBy as ExitUpdatedBy,d2.UpdatedTS as ExitTimeStamp , e1.VehicleNo, e1.NatureOfTransport, e1.AccountSatus from DCNoGeneration_PAMS d1 left join DCGateExitDetails_PAMS d2 on d1.Vendor=d2.Vendor and d1.Pams_DCNo=d2.PamsDCNumber
	left join EWayBillDetails_Pams e1 on e1.Pams_DCNo=d1.Pams_DCNo
	where (d1.Vendor=@Vendor) and (d1.Pams_DCNo=@PamsDCNumber)
end

if @Param='Save'
begin
	if not exists(select * from DCGateExitDetails_PAMS where  vendor=@vendor and PamsDCNumber=@PamsDCNumber)
	begin
		insert into DCGateExitDetails_PAMS(Vendor,PamsDCNumber,VehicleNumber,UpdatedBy,UpdatedTS,Driverphonenumber,SecurityName,DriverName)
		values(@Vendor,@PamsDCNumber,@VehicleNumber,@UpdatedBy,@UpdatedTS,@Driverphonenumber,@SecurityName,@DriverName)
	end
	else
	begin
		update DCGateExitDetails_PAMS set VehicleNumber=@VehicleNumber,UpdatedBy=@UpdatedBy,UpdatedTS=@UpdatedTS,Driverphonenumber=@Driverphonenumber,SecurityName=@SecurityName,DriverName=@DriverName
		where  vendor=@vendor and PamsDCNumber=@PamsDCNumber
	end
end

if @Param='GateUpdate'
	begin
		update EWayBillDetails_Pams set AccountSatus=@Status
		where pams_dcno=@PamsDCNumber
	end
END
