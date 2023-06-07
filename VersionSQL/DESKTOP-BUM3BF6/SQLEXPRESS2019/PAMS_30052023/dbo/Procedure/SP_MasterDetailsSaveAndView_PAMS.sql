/****** Object:  Procedure [dbo].[SP_MasterDetailsSaveAndView_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[SP_MasterDetailsSaveAndView_PAMS]
@CustomerID NVARCHAR(4000)='',
@CustomerName nvarchar(4000)='',
@Address nvarchar(max)='',
@Place nvarchar(100)='',
@State nvarchar(50)='',
@Country nvarchar(50)='',
@PIN nvarchar(50)='',
@ContactNumber nvarchar(50)='',
@Email nvarchar(max)='',
@Autoid int=0,
@PartID nvarchar(50)='',
@PartDescription nvarchar(2000)='',
@MaterialID nvarchar(50)='',
@MaterialDescription nvarchar(2000)='',
@SupplierID nvarchar(50)='',
@SupplierName nvarchar(100)='',
@VendorID nvarchar(50)='',
@VendorName nvarchar(100)='',
@UOM nvarchar(50)='',
@Specification nvarchar(50)='',
@ContactPerson NVARCHAR(50)='',
@unitrate nvarchar(50)='',
@MaterialType nvarchar(50)='',
@IsActive bit=0,
@HSNCode nvarchar(50)='',
@MaxAllowedQty float=0,
@supplierType nvarchar(50)='',
@Param nvarchar(50)='',
@MaxPJCNoAllowed int=0,
@PJCProcessType NVARCHAR(100)='',
@Approval nvarchar(50)='',
@Website nvarchar(2000)='',
@Email_SysCapacity_Size nvarchar(100)='',
@Total_ManufacturingSpace nvarchar(50)='',
@Company_Status nvarchar(50)='',
@NumberOfSites nvarchar(50)='',
@Supplier_Rep nvarchar(50)='',
@DateOfAudit datetime=null,
@AnnualSales_Value nvarchar(50)='',
@Curency nvarchar(50)='',
@PaymentTerms nvarchar(2000)='',
@ShipmentTerms nvarchar(2000)='',
@MajorCustomers nvarchar(100)='',
@gstnumber nvarchar(50)='',
@Pannumber nvarchar(100)='',
@Filename nvarchar(50)='',
@File1 varbinary(max)=null,
@PhoneNumber nvarchar(50)='',
@Position nvarchar(50)='',
@VendorType nvarchar(50)=''
AS
BEGIN

/************************************************************************Customer Master**********************************************************************************************************/
	
	if @Param='CustomerView'
	begin
		select * from CustomerInfo_PAMS where (CustomerID=@CustomerID or isnull(@CustomerID,'')='')
	END
	if @Param='CustomerSave'
	begin
		if not exists(select * from CustomerInfo_PAMS where CustomerID=@CustomerID)
		begin
			insert into CustomerInfo_PAMS(CustomerID,CustomerName,Address,Place,State,Country,PIN,ContactNumber,Email,ContactPerson)
			values(@CustomerID,@CustomerName,@Address,@Place,@State,@Country,@PIN,@ContactNumber,@Email,@ContactPerson)
		end
		else
		begin
			update CustomerInfo_PAMS set CustomerName=@CustomerName,Address=@Address,Place=@Place,State=@State,Country=@Country,
			PIN=@PIN,ContactNumber=@ContactNumber,Email=@Email,ContactPerson=@ContactPerson
			where CustomerID=@CustomerID
		end
	end
	if @Param='CustomerDelete'
	begin
		delete from customerinformation where customerid=@CustomerID
	end

/************************************************************************Customer Master**********************************************************************************************************/

/************************************************************************FG (Part) Master**********************************************************************************************************/
	
	if @Param='FGView'
	begin
		select PartID,PartDescription,CustomerID,CustomerName,MaxAllowedQty,MaxPJCNoAllowed from FGDetails_PAMS where (PartID=@PartID or isnull(@PartID,'')='')
	END
	if @Param='FGSave'
	begin
		if not exists(select * from FGDetails_PAMS where PartID=@PartID)
		begin
			insert into FGDetails_PAMS(PartID,PartDescription,CustomerID,CustomerName,MaxAllowedQty,MaxPJCNoAllowed)
			values(@PartID,@PartDescription,@CustomerID,@CustomerName,@MaxAllowedQty,@MaxPJCNoAllowed)
		end
		else
		begin
			update FGDetails_PAMS set PartDescription=@PartDescription,CustomerID=@CustomerID,CustomerName=@CustomerName,MaxAllowedQty=@MaxAllowedQty,MaxPJCNoAllowed=@MaxPJCNoAllowed
			WHERE PartID=@PartID
		end

		if not exists(select * from componentinformation where componentid=@PartID)
		begin
			declare @CompInterface nvarchar(50)
			select @CompInterface=''
			select @CompInterface=(select (isnull(max(cast(InterfaceID as int)),0))+1 from componentinformation)

			insert into componentinformation(componentid,InterfaceID,CustomerID,description)
			values(@PartID,@CompInterface,@CustomerID,@PartDescription)
		end
		else
		begin
			update componentinformation set description=@PartDescription,CustomerID=@CustomerID
			WHERE componentid=@PartID
		end
	end
	if @Param='FGDelete'
	begin
		delete from FGDetails_PAMS where PartID=@PartID
		DELETE FROM componentinformation WHERE componentid=@PartID
	end

/************************************************************************FG (Part) Master**********************************************************************************************************/


/************************************************************************Material (RM) Master**********************************************************************************************************/
	
	if @Param='MaterialView'
	begin
		select MaterialID,MaterialDescription,UOM,Specification,unitrate,MaterialType,HSNCode,PJCProcessType from RawMaterialDetails_PAMS where (MaterialID=@MaterialID or isnull(@MaterialID,'')='')
	END
	if @Param='MaterialSave'
	begin
		if not exists(select * from RawMaterialDetails_PAMS where MaterialID=@MaterialID)
		begin
			insert into RawMaterialDetails_PAMS(MaterialID,MaterialDescription,UOM,Specification,unitrate,MaterialType,HSNCode,PJCProcessType)
			values(@MaterialID,@MaterialDescription,@UOM,@Specification,@unitrate,@MaterialType,@HSNCode,@PJCProcessType)
		end
		else
		begin
			update RawMaterialDetails_PAMS set MaterialDescription=@MaterialDescription,UOM=@UOM,Specification=@Specification,unitrate=@unitrate,MaterialType=@MaterialType,HSNCode=@HSNCode,PJCProcessType=@PJCProcessType
			WHERE MaterialID=@MaterialID
		end
	end
	if @Param='MaterialDelete'
	begin
		delete from RawMaterialDetails_PAMS where MaterialID=@MaterialID
	end

/************************************************************************Material (RM) Master**********************************************************************************************************/


/************************************************************************Supplier (Vendor) Master**********************************************************************************************************/
	
	if @Param='SupplierView'
	begin
		select SupplierID,SupplierName,Address,Place,ContactNumber,State,Country,PIN,Email,ContactPerson,IsActive,supplierType,Approval,
		Website,Email_SysCapacity_Size,Total_ManufacturingSpace,Company_Status,NumberOfSites,Supplier_Rep,DateOfAudit,AnnualSales_Value,
		Cuurency,PaymentTerms,ShipmentTerms,MajorCustomers,gstnumber,Pannumber,FileName,File1,PhoneNumber,Position from SupplierDetails_PAMS where (SupplierID=@SupplierID or isnull(@SupplierID,'')='') and Approval='Ok'
	END
	if @Param='SupplierSave'
	begin
		if not exists(select * from SupplierDetails_PAMS where SupplierID=@SupplierID)
		begin
			if isnull(@dateofaudit,'')=''
			begin
				set @dateofaudit=null
			end
			insert into SupplierDetails_PAMS(SupplierID,SupplierName,Address,Place,ContactNumber,State,Country,PIN,Email,ContactPerson,supplierType,Approval,Website,Email_SysCapacity_Size,Total_ManufacturingSpace,Company_Status,NumberOfSites,Supplier_Rep,DateOfAudit,AnnualSales_Value,Cuurency,PaymentTerms,ShipmentTerms,MajorCustomers,gstnumber,Pannumber,FileName,File1,PhoneNumber,Position,IsActive)
			values(@SupplierID,@SupplierName,@Address,@Place,@ContactNumber,@State,@Country,@PIN,@Email,@ContactPerson,@supplierType,@Approval,@Website,@Email_SysCapacity_Size,@Total_ManufacturingSpace,@Company_Status,@NumberOfSites,@Supplier_Rep,@DateOfAudit,@AnnualSales_Value,@Curency,@PaymentTerms,@ShipmentTerms,@MajorCustomers,@gstnumber,@Pannumber,@Filename,@File1,@PhoneNumber,@Position,@IsActive)
		end
		else
		begin
			if isnull(@dateofaudit,'')=''
			begin
				set @dateofaudit=null
			end
			update SupplierDetails_PAMS set SupplierName=@SupplierName,Address=@Address,Place=@Place,ContactNumber=@ContactNumber,State=@State,Country=@Country,PIN=@PIN,Email=@Email,ContactPerson=@ContactPerson,supplierType=@supplierType,
			Website=@Website,Email_SysCapacity_Size=@Email_SysCapacity_Size,Total_ManufacturingSpace=@Total_ManufacturingSpace,Company_Status=@Company_Status ,NumberOfSites=@NumberOfSites,Supplier_Rep=@Supplier_Rep,DateOfAudit=@DateOfAudit,
			AnnualSales_Value=@AnnualSales_Value,Cuurency=@Curency,PaymentTerms=@PaymentTerms,ShipmentTerms=@ShipmentTerms,MajorCustomers=@MajorCustomers,gstnumber=@gstnumber,Pannumber=@Pannumber,Filename=@Filename,file1=@File1,PhoneNumber=@PhoneNumber,Position=@Position,IsActive=@IsActive
			WHERE SupplierID=@SupplierID
		end
	end
	if @Param='SupplierDelete'
	begin
		delete from SupplierDetails_PAMS where SupplierID=@SupplierID
	end

/************************************************************************Supplier (Vendor) Master**********************************************************************************************************/

/************************************************************************Vendor Master**********************************************************************************************************/
	
	if @Param='VendorView'
	begin
		select VendorID,VendorName,Address,Place,ContactNumber,State,Country,PIN,Email,ContactPerson,IsActive,Approval,Website,Email_SysCapacity_Size,Total_ManufacturingSpace,
			Company_Status,NumberOfSites,Supplier_Rep,DateOfAudit,AnnualSales_Value,Cuurency,PaymentTerms,ShipmentTerms,MajorCustomers,gstnumber,Pannumber,FileName,File1,PhoneNumber,Position,VendorType from VendorDetails_PAMS where (vendorid=@VendorID or isnull(@VendorID,'')='') and Approval='Ok'
	END
	if @Param='VendorSave'
	begin
		if not exists(select * from VendorDetails_PAMS where VendorID=@VendorID)
		begin
			if isnull(@dateofaudit,'')=''
			begin
				set @dateofaudit=null
			end
			insert into VendorDetails_PAMS(VendorID,VendorName,Address,Place,ContactNumber,State,Country,PIN,Email,ContactPerson,IsActive,Approval,Website,Email_SysCapacity_Size,Total_ManufacturingSpace,
			Company_Status,NumberOfSites,Supplier_Rep,DateOfAudit,AnnualSales_Value,Cuurency,PaymentTerms,ShipmentTerms,MajorCustomers,gstnumber,Pannumber,FileName,File1,PhoneNumber,Position,VendorType)
			values(@VendorID,@VendorName,@Address,@Place,@ContactNumber,@State,@Country,@PIN,@Email,@ContactPerson,@IsActive,@Approval,@Website,@Email_SysCapacity_Size,@Total_ManufacturingSpace,
			@Company_Status,@NumberOfSites,@Supplier_Rep,@DateOfAudit,@AnnualSales_Value,@Curency,@PaymentTerms,@ShipmentTerms,@MajorCustomers,@gstnumber,@Pannumber,@Filename,@File1,@PhoneNumber,@Position,@VendorType)
		end
		else
		begin
			if isnull(@dateofaudit,'')=''
			begin
				set @dateofaudit=null
			end
			update VendorDetails_PAMS set VendorName=@VendorName,Address=@Address,Place=@Place,ContactNumber=@ContactNumber,State=@State,Country=@Country,PIN=@PIN,Email=@Email,ContactPerson=@ContactPerson,IsActive=@IsActive,
			Website=@Website,Email_SysCapacity_Size=@Email_SysCapacity_Size,Total_ManufacturingSpace=@Total_ManufacturingSpace,
			Company_Status=@Company_Status,NumberOfSites=@NumberOfSites,Supplier_Rep=@Supplier_Rep,DateOfAudit=@DateOfAudit,AnnualSales_Value=@AnnualSales_Value,Cuurency=@Curency,PaymentTerms=@PaymentTerms,
			ShipmentTerms=@ShipmentTerms,MajorCustomers=@MajorCustomers,gstnumber=@gstnumber,Pannumber=@Pannumber,Filename=@Filename,File1=@File1,PhoneNumber=@PhoneNumber,Position=@Position,VendorType=@VendorType
			WHERE VendorID=@VendorID
		end
	end
	if @Param='VendorDelete'
	begin
		delete from VendorDetails_PAMS where VendorID=@VendorID
	end

/************************************************************************Vendor Master**********************************************************************************************************/





end
