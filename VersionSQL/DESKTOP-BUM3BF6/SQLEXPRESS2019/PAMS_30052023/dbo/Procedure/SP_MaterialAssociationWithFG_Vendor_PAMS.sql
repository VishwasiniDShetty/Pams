/****** Object:  Procedure [dbo].[SP_MaterialAssociationWithFG_Vendor_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

/*
SP_MaterialAssociationWithFG_Vendor_PAMS 'Part 2','','','FGMaterialAssociationView'
SP_MaterialAssociationWithFG_Vendor_PAMS '','','V1','VendorMaterialAssociationView'

SP_MaterialAssociationWithFG_Vendor_PAMS 'Part 2','M 1','','','','','','FGMaterialAssociationSave'
SP_MaterialAssociationWithFG_Vendor_PAMS '','M 1','V1','VendorMaterialAssociationSave'

SP_MaterialAssociationWithFG_Vendor_PAMS 'Part 2','M 1','','FGMaterialAssociationDelete'
SP_MaterialAssociationWithFG_Vendor_PAMS '','M 1','V1','VendorMaterialAssociationDelete'


*/
CREATE procedure [dbo].[SP_MaterialAssociationWithFG_Vendor_PAMS]
@PartID NVARCHAR(50)='',
@MaterialID NVARCHAR(50)='',
@VendorID NVARCHAR(50)='',
@SupplierID NVARCHAR(50)='',
@PartLength_mm float=0,
@TotalLength float=0,
@ConversionKGTo_1M float=0,
@MaterialWeight_KG float=0,
@CuttingAllowance float=0,
@MaterialType nvarchar(50)='',
@EndBitAllowance float=0,
@remarks nvarchar(2000)='',
@Param nvarchar(50)=''
AS
BEGIN

IF @Param='FGMaterialAssociationView'
begin
	select @PartID as PartID,F2.PartDescription AS PartDescription, r1.MaterialID,MaterialDescription,r1.Specification,r1.UOM,f1.ConversionKGTo_1M,round(f1.MaterialWeight_KG,3) as MaterialWeight_KG,f1.CuttingAllowance,
	round(f1.TotalLength,3) as TotalLength,f1.PartLength_mm,f1.EndBitAllowance,r1.MaterialType,f1.Remarks, 
	ISNULL(ISENABLE,0) AS IsEnable,r1.HSNCode,r1.UnitRate  from RawMaterialDetails_PAMS r1
	left join RawMaterialAndFGAssociation_PAMS f1 on @PartID=f1.PartID and r1.MaterialID=f1.MaterialID
	LEFT JOIN FGDetails_PAMS F2 ON @PartID=F2.PartID
end

IF @Param='FGMaterialAssociationSave'
begin
	if not exists(select * from RawMaterialAndFGAssociation_PAMS where PartID=@PartID and MaterialID=@MaterialID)
	BEGIN
		INSERT INTO RawMaterialAndFGAssociation_PAMS(PartID,MaterialID,PartLength_mm,CuttingAllowance,TotalLength,ConversionKGTo_1M,MaterialWeight_KG,EndBitAllowance,MaterialType,Remarks)
		VALUES(@PartID,@MaterialID,@PartLength_mm,@CuttingAllowance,@TotalLength, @ConversionKGTo_1M,@MaterialWeight_KG,@EndBitAllowance,@MaterialType,@remarks)
	end
	else
	begin
		update RawMaterialAndFGAssociation_PAMS set PartLength_mm=@PartLength_mm,CuttingAllowance=@CuttingAllowance,TotalLength=@TotalLength,ConversionKGTo_1M=@ConversionKGTo_1M ,MaterialWeight_KG=@MaterialWeight_KG,
		EndBitAllowance=@EndBitAllowance,remarks=@remarks
		where PartID=@PartID and MaterialID=@MaterialID 
	end
end

IF @Param='FGMaterialAssociationDelete'
begin
	delete from RawMaterialAndFGAssociation_PAMS where PartID=@PartID and MaterialID=@MaterialID
end


IF @Param='VendorMaterialAssociationView'
begin
	select @VendorID as VendorID,v1.VendorName,r1.MaterialID,MaterialDescription,r1.Specification,r1.UOM ,ISNULL(ISENABLE,0) AS IsEnable from RawMaterialDetails_PAMS r1
	left join RawMaterialAndVendorAssociation_PAMS f1 on @VendorID=f1.VendorID and r1.MaterialID=f1.MaterialID
	left join VendorDetails_PAMS v1 on @VendorID=v1.VendorID
end

IF @Param='VendorMaterialAssociationSave'
begin
	if not exists(select * from RawMaterialAndVendorAssociation_PAMS where vendorid=@VendorID and MaterialID=@MaterialID)
	BEGIN
		INSERT INTO RawMaterialAndVendorAssociation_PAMS(vendorid,MaterialID)
		VALUES(@VendorID,@MaterialID)
	end
end

IF @Param='VendorMaterialAssociationDelete'
begin
	delete from RawMaterialAndVendorAssociation_PAMS where VendorID=@VendorID and MaterialID=@MaterialID
end

IF @Param='SupplierMaterialAssociationView'
begin
	select @SupplierID as SupplierID,v1.SupplierName,r1.MaterialID,MaterialDescription,r1.Specification,r1.UOM ,ISNULL(ISENABLE,0) AS IsEnable from RawMaterialDetails_PAMS r1
	left join RawMaterialAndSupplierAssociation_PAMS f1 on @SupplierID=f1.SupplierID and r1.MaterialID=f1.MaterialID
	left join SupplierDetails_PAMS v1 on @SupplierID=v1.SupplierID
end

IF @Param='SupplierMaterialAssociationSave'
begin
	if not exists(select * from RawMaterialAndSupplierAssociation_PAMS where SupplierID=@SupplierID and MaterialID=@MaterialID)
	BEGIN
		INSERT INTO RawMaterialAndSupplierAssociation_PAMS(SupplierID,MaterialID)
		VALUES(@SupplierID,@MaterialID)
	end
end

IF @Param='SupplierMaterialAssociationDelete'
begin
	delete from RawMaterialAndSupplierAssociation_PAMS where SupplierID=@SupplierID and MaterialID=@MaterialID
end


if @Param='NormView'
begin
	select distinct r1.AutoID,r1.PartID,f1.PartDescription,r1.MaterialID,r2.MaterialDescription,r2.Specification,r2.UOM,round(r1.PartLength_mm,3) as PartLength_mm,
	round(r1.ConversionKGTo_1M,3) as ConversionKGTo_1M,round(r1.MaterialWeight_KG,3) as MaterialWeight_KG,round(r1.CuttingAllowance,3) as CuttingAllowance,round(r1.EndBitAllowance,3) as EndBitAllowance,round(r1.TotalLength,3) as TotalLength,r2.MaterialType,r1.Remarks,r2.HSNCode,r2.UnitRate,f1.MaxAllowedQty from RawMaterialAndFGAssociation_PAMS r1
	left join FGDetails_PAMS f1 on r1.PartID=f1.PartID
	left join RawMaterialDetails_PAMS r2 on r1.MaterialID=r2.MaterialID
	where (r1.PartID=@PartID or isnull(@partid,'')='') and (r1.MaterialID=@MaterialID or isnull(@MaterialID,'')='')
END

end
