/****** Object:  Procedure [dbo].[SP_MPRDetailsTransactionSaveAndView_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

/*
SP_MPRDetailsTransactionSaveAndView_PAMS @MPRNo=N'',@MPRDate=N'',@PartID=N'',@MaterialID=N'',@Qty=N'',
@UOM=N'',@PO=N'',@Supplier=N'',@RequiredDate=N'',@UpdatedBy=N'',@ConfirmedBy=N'',@ConfirmedTS=N'',@ConfirmationStatus=N'',@Param=N'View',
@Type=N'',@AutoID=N''

exec [SP_MPRDetailsTransactionSaveAndView_PAMS] @MPRNo=N'',@PartID=N'',@MaterialID=N'',@FromDate=N'',@Todate=N'',@Param=N'View'
*/
CREATE procedure [dbo].[SP_MPRDetailsTransactionSaveAndView_PAMS]
@MPRNo nvarchar(max)='',
@MPRDate date='',
@PartID nvarchar(max)='',
@MaterialID nvarchar(max)='',
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
@Param nvarchar(50)='',
@Type nvarchar(50)='',
@AutoID INT=0,
@MPRId int=0,
@PPCRemarks NVARCHAR(2000)='',
@StoresRemarks NVARCHAR(2000)='',
@MRRemarks NVARCHAR(2000)='',
@PurchaseRemarks NVARCHAR(2000)='',
@MPRStatus nvarchar(50)='',
@ItemLevelRemarks_PPC NVARCHAR(2000)='',
@ItemLevelRemarks_Stores NVARCHAR(2000)='',
@ItemLevelRemarks_MPR nvarchar(2000)='',
@ItemLevelRemarks_Purchase nvarchar(2000)='',
@Remarks_MPRClose nvarchar(2000)='',
@FromDate datetime='',
@Todate datetime=''

AS
BEGIN

declare @StrPartID nvarchar(max)
declare @Str@MaterialID nvarchar(max)
declare @StrMprNo nvarchar(max)
declare @strsql nvarchar(max)
declare @StrDateCheck nvarchar(max)

select @StrDateCheck=''

if (isnull(@fromdate,'')<>'' and isnull(@todate,'')<>'')
begin
	select @StrDateCheck='And (MPRDate>='''+convert(nvarchar(20),@FromDate,120)+''' and MPRDate<='''+convert(nvarchar(20),@Todate,120)+''') '
end

--select @StrPartID=''
--select @Str@MaterialID=''
--select @StrMprNo=''
--select @strsql=''

--if isnull(@PartID,'')<>''
--begin
--	select @StrPartID='And PartID IN ('+@PartID+')'
--END

--if isnull(@MaterialID,'')<>''
--begin
--	select @Str@MaterialID='And MaterialID IN ('+@MaterialID+')'
--END

--if isnull(@MPRNo,'')<>''
--begin
--	select @StrMprNo='And MPRNo IN ('+@MPRNo+')'
--END

CREATE TABLE #TEMP
(
AutoID INT,
MPRId int,
MPRNo NVARCHAR(50),
MPRDate DATE,
PartID NVARCHAR(50),
MaterialID NVARCHAR(50),
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
MPRStatus nvarchar(50) default '',
ItemLevelRemarks_PPC NVARCHAR(2000),
ItemLevelRemarks_Stores NVARCHAR(2000),
ItemLevelRemarks_MPR nvarchar(2000),
ItemLevelRemarks_Purchase nvarchar(2000),
Remarks_MPRClose nvarchar(2000),

)


if @Param='PPCSave'
BEGIN	
	if not exists(select * from MPRDetailsTransaction_PPC_PAMS where MPRNo=@MPRNo and PartID=@PartID and MaterialID=@MaterialID)
	begin
		insert into MPRDetailsTransaction_PPC_PAMS(MPRId,MPRNo,MPRDate,PartID,MaterialID,Qty,UOM,RequiredDate,UpdatedBy,UpdatedTs,ItemLevelRemarks_PPC)
		values(@MPRId,@MPRNo,@MPRDate,@PartID,@MaterialID,@Qty,@UOM,@RequiredDate,@UpdatedBy,@UpdatedTS,@ItemLevelRemarks_PPC)
	END
	ELSE
	BEGIN
		UPDATE MPRDetailsTransaction_PPC_PAMS SET Qty=@Qty,RequiredDate=@RequiredDate,UpdatedBy=@UpdatedBy,
		UpdatedTs=@UpdatedTS,ItemLevelRemarks_PPC=@ItemLevelRemarks_PPC WHERE MPRNo=@MPRNo and PartID=@PartID and MaterialID=@MaterialID
	END
end	

IF @Param='PPCConfirm'
begin
	if NOT exists(select * from MPRConfirmationStatus_PPC_PAMS where MPRNo=@MPRNo)
	begin
		INSERT INTO MPRConfirmationStatus_PPC_PAMS(MPRNo,ConfirmedBy,ConfirmedTS,ConfirmationStatus)
		VALUES(@MPRNo,@ConfirmedBy,@ConfirmedTS,@ConfirmationStatus)
	end
	else
	begin
		update MPRConfirmationStatus_PPC_PAMS set ConfirmedBy=@ConfirmedBy , ConfirmedTS=@ConfirmedTS , ConfirmationStatus=@ConfirmationStatus
		where MPRNo=@MPRNo
	end
end

IF @Param='PPCDelete'
begin
	delete from MPRDetailsTransaction_PPC_PAMS where AutoID=@AutoID
end

if @Param='StoreConfirm'
begin
	if NOT exists(select * from MPRConfirmationStatus_Store_PAMS where MPRNo=@MPRNo)
	begin
		INSERT INTO MPRConfirmationStatus_Store_PAMS(MPRNo,ConfirmedBy,ConfirmedTS,ConfirmationStatus)
		VALUES(@MPRNo,@ConfirmedBy,@ConfirmedTS,@ConfirmationStatus)
	end
	else
	begin
		update MPRConfirmationStatus_Store_PAMS set ConfirmedBy=@ConfirmedBy , ConfirmedTS=@ConfirmedTS , ConfirmationStatus=@ConfirmationStatus
		where MPRNo=@MPRNo
	END
END

if @Param='MRConfirm'
begin
	if NOT exists(select * from MPRConfirmationStatus_MR_PAMS where MPRNo=@MPRNo)
	begin
		INSERT INTO MPRConfirmationStatus_MR_PAMS(MPRNo,ConfirmedBy,ConfirmedTS,ConfirmationStatus)
		VALUES(@MPRNo,@ConfirmedBy,@ConfirmedTS,@ConfirmationStatus)
	end
	else
	begin
		update MPRConfirmationStatus_MR_PAMS set ConfirmedBy=@ConfirmedBy , ConfirmedTS=@ConfirmedTS , ConfirmationStatus=@ConfirmationStatus
		where MPRNo=@MPRNo
	END
END

if @Param='PurchaseConfirm'
begin
	if NOT exists(select * from MPRConfirmationStatus_Purchase_PAMS where MPRNo=@MPRNo)
	begin
		INSERT INTO MPRConfirmationStatus_Purchase_PAMS(MPRNo,ConfirmedBy,ConfirmedTS,ConfirmationStatus)
		VALUES(@MPRNo,@ConfirmedBy,@ConfirmedTS,@ConfirmationStatus)
	end
	else
	begin
		update MPRConfirmationStatus_Purchase_PAMS set ConfirmedBy=@ConfirmedBy , ConfirmedTS=@ConfirmedTS , ConfirmationStatus=@ConfirmationStatus
		where MPRNo=@MPRNo
	END
END

if @Param='GeneratePO'
begin
	if NOT exists(select * from GeneratePODetails_PAMS where MPRNo=@MPRNo AND  MaterialID=@MaterialID AND PartID=@PartID AND ISNULL(PONumber,'')=ISNULL(@PONumber,''))
	begin
		INSERT INTO GeneratePODetails_PAMS(PONumber,MPRNo,MaterialID,PartID,OrderedQty,POQty,UpdatedBy,UpdatedTS)
		VALUES(@PONumber,@MPRNo,@MaterialID,@PartID,@Qty,@POQty,@UpdatedBy,@UpdatedTS)
	end
	else
	begin
		update GeneratePODetails_PAMS set POQty=@POQty , UpdatedBy=@UpdatedBy , UpdatedTS=@UpdatedTS
		where MPRNo=@MPRNo AND  MaterialID=@MaterialID AND PartID=@PartID AND ISNULL(PONumber,'')=ISNULL(@PONumber,'')
	END
END

if @Param='DeleteExistingMPRForUser'
begin

	delete from GeneratePODetails_PAMS where MPRNo=@MPRNo  AND ISNULL(PONumber,'')=ISNULL(@PONumber,'') and UpdatedBy=@UpdatedBy;

END


IF @Param='View'
begin

	select @StrPartID=''
	select @Str@MaterialID=''
	select @StrMprNo=''
	select @strsql=''

	if isnull(@PartID,'')<>''
	begin
		select @StrPartID='And g1.PartID IN ('+@PartID+')'
	END

	if isnull(@MaterialID,'')<>''
	begin
		select @Str@MaterialID='And g1.MaterialID IN ('+@MaterialID+')'
	END

	if isnull(@MPRNo,'')<>''
	begin
		select @StrMprNo='And g1.MPRNo IN ('+@MPRNo+')'
	END


	select @strsql=''
	select @strsql=@strsql+'Insert into #TEMP(AutoID,MPRNo, MPRId,MPRDate,PartID,MaterialID,OrderedQty,UOM,RequiredDate,PPCRemarks,StoresRemarks,MRRemarks,PurchaseRemarks,MPRStatus,
	ItemLevelRemarks_PPC,ItemLevelRemarks_Stores,ItemLevelRemarks_MPR,ItemLevelRemarks_Purchase,Remarks_MPRClose) '
	select @strsql=@strsql+'select distinct AutoID,MPRNo,MPRId, MPRDate,PartID,MaterialID,Qty,UOM,RequiredDate,PPCRemarks,StoresRemarks,MRRemarks,PurchaseRemarks,MPRStatus,
	ItemLevelRemarks_PPC,ItemLevelRemarks_Stores,ItemLevelRemarks_MPR,ItemLevelRemarks_Purchase,Remarks_MPRClose from MPRDetailsTransaction_PPC_PAMS g1 where 1=1 '
	select @strsql=@strsql+@StrMprNo+@StrPartID+@Str@MaterialID
	print(@strsql)
	exec(@strsql)


	UPDATE #TEMP SET UpdatedBy_PPC=isnull(T1.CONFIRMEDBY,''),UpdatedTs_PPC=isnull(T1.ConfirmedTS,''),Status_PPC=isnull(T1.ConfirmationStatus,'')
	from
	(
	select distinct MPRNO,ConfirmedBy,ConfirmedTS,ConfirmationStatus FROM MPRConfirmationStatus_PPC_PAMS
	)
	T1 INNER JOIN #TEMP ON T1.MPRNo=#TEMP.MPRNo

	UPDATE #TEMP SET UpdatedBy_Stores=isnull(T1.CONFIRMEDBY,''),UpdatedTs_Stores=isnull(T1.ConfirmedTS,''),Status_Stores=isnull(T1.ConfirmationStatus,'')
	from
	(
	select distinct MPRNO,ConfirmedBy,ConfirmedTS,ConfirmationStatus FROM MPRConfirmationStatus_Store_PAMS
	)
	T1 INNER JOIN #TEMP ON T1.MPRNo=#TEMP.MPRNo

	UPDATE #TEMP SET UpdatedBy_MR=isnull(T1.CONFIRMEDBY,''),UpdatedTs_MR=isnull(T1.ConfirmedTS,''),Status_MR=isnull(T1.ConfirmationStatus,'')
	from
	(
	select distinct MPRNO,ConfirmedBy,ConfirmedTS,ConfirmationStatus FROM MPRConfirmationStatus_MR_PAMS
	)
	T1 INNER JOIN #TEMP ON T1.MPRNo=#TEMP.MPRNo


	UPDATE #TEMP SET UpdatedBy_Purchase=isnull(T1.CONFIRMEDBY,''),UpdatedTs_Purchase=isnull(T1.ConfirmedTS,''),Status_Purchase=isnull(T1.ConfirmationStatus,'')
	from
	(
	select distinct MPRNO,ConfirmedBy,ConfirmedTS,ConfirmationStatus FROM MPRConfirmationStatus_Purchase_PAMS
	)
	T1 INNER JOIN #TEMP ON T1.MPRNo=#TEMP.MPRNo

	UPDATE #TEMP SET POQty=isnull(T1.POQTY,'')
	FROM
	(
	SELECT DISTINCT MPRNo,MaterialID,PartID,sum(POQty) as POQTY FROM GeneratePODetails_PAMS WHERE status<>'PO Not Approved'
	group by MPRNo,MaterialID,PartID
	) 
	T1 INNER JOIN #TEMP ON #TEMP.MPRNo=T1.MPRNO AND #TEMP.MaterialID=T1.MaterialID AND #TEMP.PartID=T1.PartID 

	UPDATE #TEMP SET Status=isnull(T1.Status,'')
	FROM
	(
	SELECT DISTINCT MPRNo,MaterialID,PartID,Status as Status FROM GeneratePODetails_PAMS
	) 
	T1 INNER JOIN #TEMP ON #TEMP.MPRNo=T1.MPRNO AND #TEMP.MaterialID=T1.MaterialID AND #TEMP.PartID=T1.PartID 

	UPDATE #TEMP SET PendingQty=case when isnull(status,'')='' then ISNULL(OrderedQty,0) else ISNULL(OrderedQty,0)-ISNULL(POQTY,0) end

	select @strsql=''
	select @strsql=@strsql+'SELECT t1.MPRId, T1.AutoID,MPRNo ,MPRDate ,T1.PartID,F1.PartDescription,t1.MaterialID,R1.MaterialDescription,R1.UOM,R1.Specification,OrderedQty ,PendingQty ,POQty ,t1.UOM ,RequiredDate ,UpdatedBy_PPC,UpdatedTs_PPC ,Status_PPC ,
	UpdatedBy_Stores  ,UpdatedTs_Stores ,Status_Stores ,UpdatedBy_MR  ,UpdatedTs_MR ,Status_MR ,UpdatedBy_Purchase ,UpdatedTs_Purchase ,
	Status_Purchase,PPCRemarks,StoresRemarks,MRRemarks,PurchaseRemarks,isnull(MPRStatus,'''') as MPRStatus,ItemLevelRemarks_PPC,ItemLevelRemarks_Stores,ItemLevelRemarks_MPR,ItemLevelRemarks_Purchase,Remarks_MPRClose FROM #TEMP t1
	left join RawMaterialDetails_PAMS r1 on r1.MaterialID=t1.MaterialID
	LEFT JOIN FGDetails_PAMS F1 ON F1.PartID=T1.PartID where 1=1  '
	select @strsql=@strsql+@StrDateCheck
	select @strsql=@strsql+'ORDER BY MPRId  '
	print(@strsql)
	exec(@strsql)

	SELECT @STRSQL=''
	SELECT @STRSQL=@STRSQL+'SELECT DISTINCT g1.Podate,g1.PONumber,g1.MPRNo,g1.MaterialID,R1.MaterialDescription,g1.PartID,F1.PartDescription,g1.Supplier,v1.suppliername as SupplierName,g1.OrderedQty,g1.POQty,g1.Status,g1.POAction,g1.POCloseRemarks,isnull(t2.GateEntryBit,0) as GateEntryBit FROM GeneratePODetails_PAMS g1
	left join FGDetails_PAMS f1 on f1.partid=g1.PartID
	left join RawMaterialDetails_PAMS r1 on r1.MaterialID=g1.MaterialID
	left join SupplierDetails_PAMS v1 on v1.Supplierid=g1.Supplier
	left join (select distinct PONumber,''1'' as GateEntryBit from GateEntryScreenDetails_PAMS) t2 on g1.PONumber=t2.PONumber
	WHERE 1=1'
	SELECT @strsql=@strsql+@StrMprNo+@Str@MaterialID+@StrPartID
	select @strsql=@strsql+'Order by MPRNo '
	print(@strsql)
	exec(@strsql)
	RETURN

end

if @Param='PPCRemarks_Update'
begin
	update MPRDetailsTransaction_PPC_PAMS set PPCRemarks=@PPCRemarks where MPRNo=@MPRNo
end

if @Param='StoresRemarks_Update'
begin
	update MPRDetailsTransaction_PPC_PAMS set StoresRemarks=@StoresRemarks where MPRNo=@MPRNo
end

if @Param='MRRemarks_Update'
begin
	update MPRDetailsTransaction_PPC_PAMS set MRRemarks=@MRRemarks where MPRNo=@MPRNo
end

if @Param='PurchaseRemarks_Update'
begin
	update MPRDetailsTransaction_PPC_PAMS set PurchaseRemarks=@PurchaseRemarks where MPRNo=@MPRNo
end

if @Param='MPRClose'
begin
	update MPRDetailsTransaction_PPC_PAMS set MPRStatus=@MPRStatus,Remarks_MPRClose=@Remarks_MPRClose where MPRNo=@MPRNo
end

if @Param='ItemLevelRemarks_PPC'
begin
	update MPRDetailsTransaction_PPC_PAMS set ItemLevelRemarks_PPC=@ItemLevelRemarks_PPC where AutoID=@AutoID
end

if @Param='ItemLevelRemarks_Stores'
begin
	update MPRDetailsTransaction_PPC_PAMS set ItemLevelRemarks_Stores=@ItemLevelRemarks_Stores where AutoID=@AutoID
end

if @Param='ItemLevelRemarks_MPR'
begin
	update MPRDetailsTransaction_PPC_PAMS set ItemLevelRemarks_MPR=@ItemLevelRemarks_MPR where AutoID=@AutoID
end

if @Param='ItemLevelRemarks_Purchase'
begin
	update MPRDetailsTransaction_PPC_PAMS set ItemLevelRemarks_Purchase=@ItemLevelRemarks_Purchase where AutoID=@AutoID
end



end
