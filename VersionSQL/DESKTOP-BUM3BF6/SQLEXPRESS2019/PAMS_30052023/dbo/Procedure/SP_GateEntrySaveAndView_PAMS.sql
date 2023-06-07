/****** Object:  Procedure [dbo].[SP_GateEntrySaveAndView_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE procedure [dbo].[SP_GateEntrySaveAndView_PAMS]
@Vendor nvarchar(50)='',
@PamsDCNo nvarchar(50)='',
@VendorDCNo nvarchar(50)='',
@MaterialID NVARCHAR(50)='',
@partid NVARCHAR(50)='',
@GRNNo NVARCHAR(50)='',
@Qty_KG FLOAT=0,
@Qty_Numbers FLOAT=0,
@EndBitAllowances FLOAT=0,
@PartingAllowances FLOAT=0,
@VendorDCDate DATETIME='',
@VehicleNumber NVARCHAR(50)='',
@Param nvarchar(50)=''
AS
BEGIN

	CREATE TABLE #Temp
	(
	GRNNo nvarchar(50),
	Vendor nvarchar(50),
	PamsDCNo nvarchar(50),
	MaterialID NVARCHAR(50),
	FGNumber nvarchar(50)
	)


	declare @strsql nvarchar(max)
	declare @StrVendor nvarchar(2000)
	DECLARE @StrMaterialID NVARCHAR(2000)
	declare @StrPamsDCNo nvarchar(2000)
	select @strsql=''
	select @StrVendor=''
	select @StrMaterialID=''
	select @StrPamsDCNo=''

	if isnull(@vendor,'')<>''
	begin
		select @StrVendor='And Vendor = N'''+@Vendor+''' '
	end

	IF ISNULL(@MaterialID,'')<>''
	BEGIN
		SELECT @StrMaterialID= 'And materialid= N'''+@MaterialID+''' '
	END

	if isnull(@PamsDCNo,'')<>''
	begin
		select @StrPamsDCNo='And Pams_DCNo =N'''+@PamsDCNo+''' '
	END

if @param='View'
begin
	SELECT @strsql=''
	select @strsql=@strsql+'Insert into #Temp(Vendor,PamsDCNo,MaterialID,FGNumber,GRNNo) '
	select @strsql=@strsql+'select distinct Vendor,PamsDCNo,MaterialID,Partid,GRNNo from DCNoGeneration_PAMS where 1=1 '
	select @strsql=@strsql+@StrVendor+@StrMaterialID+@StrPamsDCNo
	print(@strsql)
	exec(@strsql)
end

if @Param='Save'
begin
	if not exists(select * from DCGateEntryDetails_PAMS where Vendor=@Vendor and MaterialID=@MaterialID and partid=@partid and pamsdcno=@PamsDCNo and VendorDCNo=@VendorDCNo)
	begin
		insert into DCGateEntryDetails_PAMS(Vendor,GRNNo,MaterialID,PartID,Qty_KG,Qty_Numbers,EndBitAllowances,PartingAllowances,PamsDCNo,VendorDCNo,VendorDCDate)
		values(@Vendor,@GRNNo,@MaterialID,@PartID,@Qty_KG,@Qty_Numbers,@EndBitAllowances,@PartingAllowances,@PamsDCNo,@VendorDCNo,@VendorDCDate)
	END
	ELSE
	BEGIN
		UPDATE DCGateEntryDetails_PAMS SET Qty_KG=@Qty_KG,Qty_Numbers=@Qty_Numbers,EndBitAllowances=@EndBitAllowances,PartingAllowances=@PartingAllowances,VendorDCNo=@VendorDCNo
		WHERE Vendor=@Vendor and MaterialID=@MaterialID and partid=@partid and pamsdcno=@PamsDCNo and VendorDCNo=@VendorDCNo
	END

end

END	
