/****** Object:  Procedure [dbo].[SP_MPRDetailsTransactionSaveAndView_IDM_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

/*
SP_MPRDetailsTransactionSaveAndView_IDM_PAMS @MPRNo=N'',@MPRDate=N'',@PartID=N'',@MaterialID=N'',@Qty=N'',
@UOM=N'',@PO=N'',@Supplier=N'',@RequiredDate=N'',@UpdatedBy=N'',@ConfirmedBy=N'',@ConfirmedTS=N'',@ConfirmationStatus=N'',@Param=N'View',
@Type=N'',@AutoID=N''

exec [SP_MPRDetailsTransactionSaveAndView_IDM_PAMS] @MPRNo=N'',@Param=N'View',@FromDate=N'2023-03-10',@Todate=N'2023-03-11'
*/
CREATE procedure [dbo].[SP_MPRDetailsTransactionSaveAndView_IDM_PAMS]
@MPRNo nvarchar(max)='',
@MPRDate date='',
@Itemname nvarchar(max)='',
@Qty float=0,
@POQty FLOAT=0,
@UOM nvarchar(50)='',
@PO nvarchar(50)='',
@Supplier nvarchar(50)='',
@RequiredDate date='',
@UpdatedBy nvarchar(50)='',
@UpdatedTS DATETIME='',
@ConfirmedBy NVARCHAR(50)='',
@ConfirmedTS DATETIME='',
@ConfirmationStatus NVARCHAR(50)='',
@PONumber NVARCHAR(100)='',
@department nvarchar(50)='',
@Param nvarchar(50)='',
@Type nvarchar(50)='',
@ItemCategory nvarchar(50)='',
@AutoID INT=0,
@MPRId int=0,
@PPCRemarks NVARCHAR(2000)='',
@StoresRemarks NVARCHAR(2000)='',
@MRRemarks NVARCHAR(2000)='',
@PurchaseRemarks NVARCHAR(2000)='',
@MPRStatus nvarchar(50)='',
@FromDate datetime='',
@Todate datetime=''
AS
BEGIN

declare @StrItemName nvarchar(max)
declare @StrDepartmentName nvarchar(max)
declare @StrMprNo nvarchar(max)
declare @strsql nvarchar(max)
declare @StrDateCheck nvarchar(max)

select @StrDateCheck=''

if (isnull(@fromdate,'')<>'' and isnull(@todate,'')<>'')
begin
	select @StrDateCheck='And (MPRDate>='''+convert(nvarchar(20),@FromDate,120)+''' and MPRDate<='''+convert(nvarchar(20),@Todate,120)+''') '
end


CREATE TABLE #TEMP
(
AutoID INT,
MPRNo NVARCHAR(50),
MPRDate DATE,
ItemName NVARCHAR(50),
Department NVARCHAR(50),
ItemCategory nvarchar(50),
OrderedQty FLOAT,
PendingQty float,
POQty float,
UOM NVARCHAR(50),
PO NVARCHAR(50),
Supplier NVARCHAR(50),
RequiredDate DATE,
UpdatedBy_PPC  NVARCHAR(50),
UpdatedTs_PPC DATETIME,
Status_PPC NVARCHAR(50),
UpdatedBy_Stores  NVARCHAR(50),
UpdatedTs_Stores DATETIME,
Status_Stores NVARCHAR(50),
UpdatedBy_MR  NVARCHAR(50),
UpdatedTs_MR DATETIME,
Status_MR NVARCHAR(50),
UpdatedBy_Purchase  NVARCHAR(50),
UpdatedTs_Purchase DATETIME,
Status_Purchase NVARCHAR(50),
Status nvarchar(50),
PPCRemarks NVARCHAR(2000),
StoresRemarks NVARCHAR(2000),
MRRemarks NVARCHAR(2000),
PurchaseRemarks NVARCHAR(2000),
MPRStatus nvarchar(50) default ''
)


if @Param='PPCSave'
BEGIN	
	if not exists(select * from MPRDetailsTransaction_PPC_IDM_PAMS where MPRNo=@MPRNo and Itemname=@Itemname and department=@department and ItemCategory=@ItemCategory)
	begin
		insert into MPRDetailsTransaction_PPC_IDM_PAMS(MPRId,MPRNo,MPRDate,Itemname,department,ItemCategory,Qty,UOM,RequiredDate,UpdatedBy,UpdatedTs)
		values(@MPRId,@MPRNo,@MPRDate,@Itemname,@department,@ItemCategory,@Qty,@UOM,@RequiredDate,@UpdatedBy,@UpdatedTS)
	END
	ELSE
	BEGIN
		UPDATE MPRDetailsTransaction_PPC_IDM_PAMS SET Qty=@Qty,RequiredDate=@RequiredDate,UpdatedBy=@UpdatedBy,
		UpdatedTs=@UpdatedTS WHERE MPRNo=@MPRNo and Itemname=@Itemname and department=@department and ItemCategory=@ItemCategory
	END
end	

IF @Param='PPCConfirm'
begin
	if NOT exists(select * from MPRConfirmationStatus_PPC_IDM_PAMS where MPRNo=@MPRNo)
	begin
		INSERT INTO MPRConfirmationStatus_PPC_IDM_PAMS(MPRNo,ConfirmedBy,ConfirmedTS,ConfirmationStatus)
		VALUES(@MPRNo,@ConfirmedBy,@ConfirmedTS,@ConfirmationStatus)
	end
	else
	begin
		update MPRConfirmationStatus_PPC_IDM_PAMS set ConfirmedBy=@ConfirmedBy , ConfirmedTS=@ConfirmedTS , ConfirmationStatus=@ConfirmationStatus
		where MPRNo=@MPRNo
	end
end

IF @Param='PPCDelete'
begin
	delete from MPRDetailsTransaction_PPC_IDM_PAMS where AutoID=@AutoID
end

if @Param='StoreConfirm'
begin
	if NOT exists(select * from MPRConfirmationStatus_Store_IDM_PAMS where MPRNo=@MPRNo)
	begin
		INSERT INTO MPRConfirmationStatus_Store_IDM_PAMS(MPRNo,ConfirmedBy,ConfirmedTS,ConfirmationStatus)
		VALUES(@MPRNo,@ConfirmedBy,@ConfirmedTS,@ConfirmationStatus)
	end
	else
	begin
		update MPRConfirmationStatus_Store_IDM_PAMS set ConfirmedBy=@ConfirmedBy , ConfirmedTS=@ConfirmedTS , ConfirmationStatus=@ConfirmationStatus
		where MPRNo=@MPRNo
	END
END

if @Param='MRConfirm'
begin
	if NOT exists(select * from MPRConfirmationStatus_MR_IDM_PAMS where MPRNo=@MPRNo)
	begin
		INSERT INTO MPRConfirmationStatus_MR_IDM_PAMS(MPRNo,ConfirmedBy,ConfirmedTS,ConfirmationStatus)
		VALUES(@MPRNo,@ConfirmedBy,@ConfirmedTS,@ConfirmationStatus)
	end
	else
	begin
		update MPRConfirmationStatus_MR_IDM_PAMS set ConfirmedBy=@ConfirmedBy , ConfirmedTS=@ConfirmedTS , ConfirmationStatus=@ConfirmationStatus
		where MPRNo=@MPRNo
	END
END

if @Param='PurchaseConfirm'
begin
	if NOT exists(select * from MPRConfirmationStatus_Purchase_IDM_PAMS where MPRNo=@MPRNo)
	begin
		INSERT INTO MPRConfirmationStatus_Purchase_IDM_PAMS(MPRNo,ConfirmedBy,ConfirmedTS,ConfirmationStatus)
		VALUES(@MPRNo,@ConfirmedBy,@ConfirmedTS,@ConfirmationStatus)
	end
	else
	begin
		update MPRConfirmationStatus_Purchase_IDM_PAMS set ConfirmedBy=@ConfirmedBy , ConfirmedTS=@ConfirmedTS , ConfirmationStatus=@ConfirmationStatus
		where MPRNo=@MPRNo
	END
END

if @Param='GeneratePO'
begin
	if NOT exists(select * from GeneratePODetails_IDM_PAMS where MPRNo=@MPRNo AND  ItemName=@Itemname and department=@department and  ItemCategory=@ItemCategory AND ISNULL(PONumber,'')=ISNULL(@PONumber,''))
	begin
		INSERT INTO GeneratePODetails_IDM_PAMS(PONumber,MPRNo,ItemName,ItemCategory,department,OrderedQty,POQty,UpdatedBy,UpdatedTS)
		VALUES(@PONumber,@MPRNo,@Itemname,@ItemCategory,@department,@Qty,@POQty,@UpdatedBy,@UpdatedTS)
	end
	else
	begin
		update GeneratePODetails_IDM_PAMS set POQty=@POQty , UpdatedBy=@UpdatedBy , UpdatedTS=@UpdatedTS
		where MPRNo=@MPRNo AND  ItemName=@Itemname and department=@department and  ItemCategory=@ItemCategory AND ISNULL(PONumber,'')=ISNULL(@PONumber,'')
	END
END

if @Param='DeleteExistingMPRForUser'
begin

	delete from GeneratePODetails_IDM_PAMS where MPRNo=@MPRNo  AND ISNULL(PONumber,'')=ISNULL(@PONumber,'') and UpdatedBy=@UpdatedBy;

END


IF @Param='View'
begin

	select @StrItemName=''
	select @StrDepartmentName=''
	select @StrMprNo=''
	select @strsql=''

	if isnull(@Itemname,'')<>''
	begin
		select @StrItemName='And g1.ItemName like ''%'+@Itemname+'%'' ' 
	END

	if isnull(@department,'')<>''
	begin
		select @StrDepartmentName='And g1.department IN ('+@department+')'
	END

	if isnull(@MPRNo,'')<>''
	begin
		select @StrMprNo='And g1.MPRNo IN ('+@MPRNo+')'
	END


	select @strsql=''
	select @strsql=@strsql+'Insert into #TEMP(AutoID,MPRNo,MPRDate,ItemName,Department,ItemCategory,OrderedQty,UOM,RequiredDate,PPCRemarks,StoresRemarks,MRRemarks,PurchaseRemarks,MPRStatus) '
	select @strsql=@strsql+'select distinct AutoID,MPRNo,MPRDate,ItemName,Department,ItemCategory,Qty,UOM,RequiredDate,PPCRemarks,StoresRemarks,MRRemarks,PurchaseRemarks,MPRStatus from MPRDetailsTransaction_PPC_IDM_PAMS g1 where 1=1 '
	select @strsql=@strsql+@StrMprNo+@StrItemName+@StrDepartmentName
	print(@strsql)
	exec(@strsql)


	UPDATE #TEMP SET UpdatedBy_PPC=isnull(T1.CONFIRMEDBY,''),UpdatedTs_PPC=isnull(T1.ConfirmedTS,''),Status_PPC=isnull(T1.ConfirmationStatus,'')
	from
	(
	select distinct MPRNO,ConfirmedBy,ConfirmedTS,ConfirmationStatus FROM MPRConfirmationStatus_PPC_IDM_PAMS
	)
	T1 INNER JOIN #TEMP ON T1.MPRNo=#TEMP.MPRNo

	UPDATE #TEMP SET UpdatedBy_Stores=isnull(T1.CONFIRMEDBY,''),UpdatedTs_Stores=isnull(T1.ConfirmedTS,''),Status_Stores=isnull(T1.ConfirmationStatus,'')
	from
	(
	select distinct MPRNO,ConfirmedBy,ConfirmedTS,ConfirmationStatus FROM MPRConfirmationStatus_Store_IDM_PAMS
	)
	T1 INNER JOIN #TEMP ON T1.MPRNo=#TEMP.MPRNo

	UPDATE #TEMP SET UpdatedBy_MR=isnull(T1.CONFIRMEDBY,''),UpdatedTs_MR=isnull(T1.ConfirmedTS,''),Status_MR=isnull(T1.ConfirmationStatus,'')
	from
	(
	select distinct MPRNO,ConfirmedBy,ConfirmedTS,ConfirmationStatus FROM MPRConfirmationStatus_MR_IDM_PAMS
	)
	T1 INNER JOIN #TEMP ON T1.MPRNo=#TEMP.MPRNo


	UPDATE #TEMP SET UpdatedBy_Purchase=isnull(T1.CONFIRMEDBY,''),UpdatedTs_Purchase=isnull(T1.ConfirmedTS,''),Status_Purchase=isnull(T1.ConfirmationStatus,'')
	from
	(
	select distinct MPRNO,ConfirmedBy,ConfirmedTS,ConfirmationStatus FROM MPRConfirmationStatus_Purchase_IDM_PAMS
	)
	T1 INNER JOIN #TEMP ON T1.MPRNo=#TEMP.MPRNo

	UPDATE #TEMP SET POQty=isnull(T1.POQTY,'')
	FROM
	(
	SELECT DISTINCT MPRNo,Itemname,Department,ItemCategory,sum(POQty) as POQTY FROM GeneratePODetails_IDM_PAMS where Status<> 'PO Not Approved'
	group by MPRNo,Itemname,Department,ItemCategory
	) 
	T1 INNER JOIN #TEMP ON #TEMP.MPRNo=T1.MPRNO AND #TEMP.Itemname=T1.Itemname AND #TEMP.Department=T1.Department and #TEMP.ItemCategory=t1.ItemCategory

	UPDATE #TEMP SET Status=isnull(T1.Status,'')
	FROM
	(
	SELECT DISTINCT MPRNo,Itemname,Department,ItemCategory,Status as Status FROM GeneratePODetails_IDM_PAMS
	) 
	T1 INNER JOIN #TEMP ON #TEMP.MPRNo=T1.MPRNO AND #TEMP.Itemname=T1.Itemname AND #TEMP.Department=T1.Department and #TEMP.ItemCategory=t1.ItemCategory

	UPDATE #TEMP SET PendingQty=case when isnull(status,'')='' then ISNULL(OrderedQty,0) else ISNULL(OrderedQty,0)-ISNULL(POQTY,0) end

	SELECT @STRSQL=''
	SELECT @STRSQL=@STRSQL+'SELECT distinct T1.AutoID,MPRNo ,MPRDate ,T1.ItemName,r1.ItemDescription,t1.Department,t1.ItemCategory,R1.UOM,OrderedQty ,PendingQty ,POQty ,t1.UOM ,RequiredDate ,UpdatedBy_PPC,UpdatedTs_PPC ,Status_PPC ,
	UpdatedBy_Stores  ,UpdatedTs_Stores ,Status_Stores ,UpdatedBy_MR  ,UpdatedTs_MR ,Status_MR ,UpdatedBy_Purchase ,UpdatedTs_Purchase ,
	Status_Purchase,PPCRemarks,StoresRemarks,MRRemarks,PurchaseRemarks,isnull(MPRStatus,'''') as MPRStatus FROM #TEMP t1
	left join IDMGeneralMaster_PAMS r1 on r1.ItemName=t1.ItemName WHERE 1=1  '
	select @strsql=@strsql+@StrDateCheck
	select @strsql=@strsql+'ORDER BY mprdate desc,MPRNo '
	print(@strsql)
	exec(@strsql)

	SELECT @STRSQL=''
	SELECT @STRSQL=@STRSQL+'SELECT DISTINCT g1.Podate,g1.PONumber,g1.MPRNo,g1.ItemName,t2.ItemDescription,g1.department,g1.itemcategory,g1.Supplier,v1.suppliername as SupplierName,g1.OrderedQty,g1.POQty,g1.Status,g1.POAction,g1.POCloseRemarks,isnull(t3.GateEntryBit,0) as  GateEntryBit FROM GeneratePODetails_IDM_PAMS g1
	left join (select distinct itemname,itemdescription,department,itemcategory from IDMGeneralMaster_PAMS)t2 on g1.itemname=t2.itemname and g1.department=t2.department and g1.department=t2.department
	left join SupplierDetails_PAMS v1 on v1.Supplierid=g1.Supplier
	left join (select distinct PONumber,''1'' as GateEntryBit from GateEntryScreenDetails_IDM_PAMS) t3 on g1.PONumber=t3.PONumber
	WHERE 1=1'
	SELECT @strsql=@strsql+@StrMprNo+@StrItemName+@StrDepartmentName
	select @strsql=@strsql+'Order by MPRNo '
	print(@strsql)
	exec(@strsql)
	RETURN

END


if @Param='PPCRemarks_Update'
begin
	update MPRDetailsTransaction_PPC_IDM_PAMS set PPCRemarks=@PPCRemarks where MPRNo=@MPRNo
end

if @Param='StoresRemarks_Update'
begin
	update MPRDetailsTransaction_PPC_IDM_PAMS set StoresRemarks=@StoresRemarks where MPRNo=@MPRNo
end

if @Param='MRRemarks_Update'
begin
	update MPRDetailsTransaction_PPC_IDM_PAMS set MRRemarks=@MRRemarks where MPRNo=@MPRNo
end

if @Param='PurchaseRemarks_Update'
begin
	update MPRDetailsTransaction_PPC_IDM_PAMS set PurchaseRemarks=@PurchaseRemarks where MPRNo=@MPRNo
end

if @Param='MPRClose'
begin
	update MPRDetailsTransaction_PPC_IDM_PAMS set MPRStatus=@MPRStatus where MPRNo=@MPRNo
end



end
