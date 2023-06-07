/****** Object:  Procedure [dbo].[SP_MasterSaveAndViewDetails_IDM_PAMS_old]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[SP_MasterSaveAndViewDetails_IDM_PAMS_old]
@slno nvarchar(50)='',
@Description nvarchar(100)='',
@Supplier nvarchar(50)='',
@uom nvarchar(50)='',
@MinimumOrderQty float=0,
@ShelfLife nvarchar(50)='',
@AlertRequiredOrNot nvarchar(50)='',
@MinimumStockQty float=0,
@Section nvarchar(50)='',
@DepartmentID nvarchar(50)='',
@DepartmentName nvarchar(100)='',
@DepartmentIncharge nvarchar(50)='',
@Param nvarchar(50)='',
@ItemName nvarchar(50)='',
@GuageID nvarchar(50)='',
@toolid nvarchar(50)='',
@unitrate nvarchar(50)='',
@ItemCategory nvarchar(50)='',
@Location nvarchar(50)='',
@LeastCount decimal(18,4)=0,
@LSLval decimal(18,4)=0,
@USLval decimal(18,4)=0,
@GaugeOwner nvarchar(50)='',
@PurchaseDate datetime=null,
@FirstCalDate datetime=null,
@LastCalDate datetime=null,
@CalFrequency int=0,
@NextCalDue datetime=null,
@CalNotes nvarchar(100)='',
@ToolType nvarchar(500)='',
@MachineType nvarchar(500)=''
as
begin

------------------------------------------------------------------------DepartmentMaster starts---------------------------------------------------------------------------------------------------------
	if @Param='DepartmentView'
	begin
		select * from DepartmentMasterDetails_PAMS where (DepartmentID=@DepartmentID or isnull(@DepartmentID,'')='')
	END
	if @Param='DepartmentSave'
	begin
		if not exists(select * from DepartmentMasterDetails_PAMS where DepartmentID=@DepartmentID)
		begin
			insert into DepartmentMasterDetails_PAMS(DepartmentID,DepartmentName,DepartmentIncharge)
			values(@DepartmentID,@DepartmentName,@DepartmentIncharge)
		end
		else
		begin
			update DepartmentMasterDetails_PAMS set DepartmentName=@DepartmentName,DepartmentIncharge=@DepartmentIncharge
			where DepartmentID=@DepartmentID
		end
	end
	if @Param='DepartmentDelete'
	begin
		delete from DepartmentMasterDetails_PAMS where DepartmentID=@DepartmentID
	end

	------------------------------------------------------------------------DepartmentMaster ends---------------------------------------------------------------------------------------------------------

	------------------------------------------------------------------------General IDM Master starts---------------------------------------------------------------------------------------------------------
	if @Param='IDMGeneralMasterView'
	begin
		select * from IDMGeneralMaster_PAMS where (ItemName=@ItemName or isnull(@ItemName,'')='') 
		and (Department=@DepartmentName or isnull(@DepartmentName,'')='')
		and (ItemCategory=@ItemCategory or isnull(@ItemCategory,'')='')
		order by SLNo
	END
	if @Param='IDMGeneralMasterSave'
	begin
		if not exists(select * from IDMGeneralMaster_PAMS where ItemName=@ItemName and Department=@DepartmentName and ItemCategory=@ItemCategory)
		begin
			insert into IDMGeneralMaster_PAMS(slno,ItemName,ItemDescription,Supplier,uom,MinimumOrderQty,ShelfLife,AlertRequiredOrNot,Department,ItemCategory,unitrate,MinimumStockQty,Location,LeastCount,LSLval,USLval,GaugeOwner,PurchaseDate,
			FirstCalDate,LastCalDate,CalFrequency,NextCalDue,CalNotes,ToolType,MachineType)
			values(@slno,@ItemName,@Description,@Supplier,@uom,@MinimumOrderQty,@ShelfLife,@AlertRequiredOrNot,@DepartmentName,@ItemCategory,@unitrate,@MinimumStockQty,@Location,@LeastCount,@LSLval,@USLval,@GaugeOwner,@PurchaseDate,
			@FirstCalDate,@LastCalDate,@CalFrequency,@NextCalDue,@CalNotes,@ToolType,@MachineType)
		end
		else
		begin
			update IDMGeneralMaster_PAMS set slno=@slno,ItemDescription=@Description,Supplier=@Supplier,uom=@uom,MinimumOrderQty=@MinimumOrderQty,ShelfLife=@ShelfLife,
			AlertRequiredOrNot=@AlertRequiredOrNot,unitrate=@unitrate,MinimumStockQty=@MinimumStockQty,Location=@Location,LeastCount=@LeastCount,LSLval=@LSLval,USLval=@USLval,GaugeOwner=@GaugeOwner,PurchaseDate=@PurchaseDate,
			FirstCalDate=@FirstCalDate,LastCalDate=@LastCalDate,CalFrequency=@CalFrequency,NextCalDue=@NextCalDue,CalNotes=@CalNotes,ToolType=@ToolType,MachineType=@MachineType
			where ItemName=@ItemName and Department=@DepartmentName and ItemCategory=@ItemCategory
		end
	end
	if @Param='IDMGeneralMasterDelete'
	begin
		delete from IDMGeneralMaster_PAMS where ItemName=@ItemName and Department=@DepartmentName and ItemCategory=@ItemCategory 
	end

	------------------------------------------------------------------------General IDM Master ends---------------------------------------------------------------------------------------------------------


		------------------------------------------------------------------------Guage Master starts---------------------------------------------------------------------------------------------------------
	if @Param='GuageView'
	begin
		select * from GuageMaster_Pams where (GuageID=@GuageID or isnull(@GuageID,'')='')
	END
	if @Param='GuageSave'
	begin
		if not exists(select * from GuageMaster_Pams where GuageID=@GuageID)
		begin
			insert into GuageMaster_Pams(GuageID,Description,UOM)
			values(@GuageID,@Description,@uom)
		end
		else
		begin
			update GuageMaster_Pams set Description=@Description,UOM=@uom
			where GuageID=@GuageID
		end
	end
	if @Param='GuageDelete'
	begin
		delete from GuageMaster_Pams where GuageID=@GuageID
	end

	------------------------------------------------------------------------Guage Master ends---------------------------------------------------------------------------------------------------------

	------------------------------------------------------------------------Tool Master starts---------------------------------------------------------------------------------------------------------
	
	if @Param='ToolView'
	begin
		select *  from ToolMaster_PAMS where (toolid=@toolid or isnull(@toolid,'')='')
	END
	if @Param='ToolSave'
	begin
		if not exists(select * from ToolMaster_PAMS where toolid=@toolid)
		begin
			insert into ToolMaster_PAMS(toolid,ToolDescription,UOM)
			values(@toolid,@Description,@uom)
		end
		else
		begin
			update ToolMaster_PAMS set ToolDescription=@Description,UOM=@uom
			where toolid=@toolid
		end
	end
	if @Param='ToolDelete'
	begin
		delete from ToolMaster_PAMS where toolid=@toolid
	end

	------------------------------------------------------------------------Tool Master ends---------------------------------------------------------------------------------------------------------
end
