/****** Object:  Procedure [dbo].[SP_GrnStatusUpdateForQuality_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

/*
SP_GrnStatusUpdateForQuality_PAMS @FromDate=N'2023-01-11 00:00:00.000',@ToDate=N'2023-11-13 00:00:00.000', @Param=N'View'

*/
CREATE PROCEDURE [dbo].[SP_GrnStatusUpdateForQuality_PAMS]
@POnumber nvarchar(100)='',
@materialid nvarchar(50)='',
@invoiceNumber nvarchar(50)='',
@GrnID INT=0,
@GrnNo NVARCHAR(50)='',
@OrderedQty float=0,
@MaterialType nvarchar(50)='',
@FromDate datetime='',
@ToDate datetime='',
@GateEntryDate datetime='',
@updatedts datetime='',
@UpdatedBy NVARCHAR(50)='',
@ApprovedBy nvarchar(50)='',
@ApprovedTS DATETIME='',
@Supplier nvarchar(2000)='',
@file1 varbinary(MAX)=null,
@File2  varbinary(MAX)=null,
@File3 varbinary(MAX)=null,
@File4 varbinary(MAX)=null,
@File1Name nvarchar(50)='',
@File2Name nvarchar(50)='',
@File3Name nvarchar(50)='',
@File4Name nvarchar(50)='',
@TCNo nvarchar(50)='',
@Remarks nvarchar(2000)='',
@Param nvarchar(100)='',
@RejQty float=0
AS
BEGIN


declare @strSupplier nvarchar(4000)
declare @strPONumber nvarchar(4000)
declare @strMaterial nvarchar(4000)
declare @strInvoiceNumber nvarchar(4000)
declare @strsql nvarchar(max)
declare @strMaterialType nvarchar(4000)
declare @strGrnNo nvarchar(4000)

select @strsql=''
select @strSupplier=''
select @strPONumber=''
select @strMaterial=''
select @strInvoiceNumber=''
select @strMaterialType=''
select @strGrnNo=''

create table #temp
(
Supplier nvarchar(50),
PONumber nvarchar(50),
MaterialID nvarchar(50),
Invoicenumber nvarchar(50),
receivedQty float,
UpdatedBy nvarchar(50),
UpdatedTS datetime,
GRNId int,
GRNNo nvarchar(50),
MaterialType nvarchar(50),
File1 varbinary(MAX),
File2 varbinary(MAX),
File3 varbinary(MAX),
File4 varbinary(MAX),
File1Name nvarchar(50),
File2Name nvarchar(50),
File3Name nvarchar(50),
File4Name nvarchar(50),
TCNo nvarchar(50),
Status nvarchar(50),
Remarks nvarchar(2000),
approvedby nvarchar(50),
approvedts nvarchar(50),
RejQty float
)


if isnull(@Supplier,'')<>''
begin
	select @strSupplier='And g1.Supplier in (' + @Supplier + ')'
end

if isnull(@POnumber,'')<>''
begin
	select @strPONumber='And g1.ponumber like ''%'+@POnumber+'%'' '
END

if isnull(@materialid,'')<>''
begin
	select @strMaterial='And g1.Materialid like ''%'+@materialid+'%'' '
END

if isnull(@GrnNo,'')<>''
begin
	select @strGrnNo='And g1.Grnno in (' + @GrnNo + ')'
end

if isnull(@MaterialType,'')<>''
begin
	select @strMaterialType='And g1.type in (' + @MaterialType + ')'
END


if @Param='View'
begin
	--select @strsql=''
	--select @strsql='Insert into #temp(Supplier,PONumber,MaterialID,Invoicenumber,receivedQty,GRNNo,MaterialType) '
	--select @strsql=@strsql+'select distinct g1.Supplier,g1.PONumber,g1.MaterialID,g1.Invoicenumber,case when g1.uom=''NO.'' then receivedQty_Numbers else g1.receivedQty end as receivedQty,G1.GRNNo,g1.type as Materialtype from GrnNoGeneration_PAMS g1
	--where convert(nvarchar(10),g1.GRNDate,126)>='''+convert(nvarchar(10),@FromDate,126)+''' and convert(nvarchar(10),g1.grndate,126)<='''+convert(nvarchar(10),@ToDate,126)+''' and 1=1'
	--select @strsql=@strsql+@strSupplier+@strPONumber+@strMaterial+@strMaterialType+@strGrnNo
	--print(@strsql)
	--exec(@strsql)

	select @strsql=''
	select @strsql='Insert into #temp(Supplier,PONumber,MaterialID,Invoicenumber,receivedQty,GRNNo,GRNId, MaterialType) '
	select @strsql=@strsql+'select distinct g1.Supplier,g1.PONumber,g1.MaterialID,g1.Invoicenumber,case when g1.uom=''NO.'' then receivedQty_Numbers else g1.receivedQty end as receivedQty,G1.GRNNo,g1.GRNId,g2.type as Materialtype from GrnNoGeneration_PAMS g1
	left join GateEntryScreenDetails_PAMS g2 on g1.Supplier=g2.Supplier and g1.PONumber=g2.PONumber and g1.MaterialID=g2.MaterialID  and g1.Invoicenumber=g2.InvoiceNumber
	where convert(nvarchar(10),g1.GRNDate,126)>='''+convert(nvarchar(10),@FromDate,126)+''' and convert(nvarchar(10),g1.grndate,126)<='''+convert(nvarchar(10),@ToDate,126)+''' and 1=1'
	select @strsql=@strsql+@strSupplier+@strPONumber+@strMaterial+@strMaterialType+@strGrnNo
	print(@strsql)
	exec(@strsql)


	update #temp set File1=isnull(t1.File1,null),File2=isnull(t1.file2,null),file3=isnull(t1.file3,null),file4=isnull(t1.file4,null),
	File1Name=isnull(t1.File1Name,''),File2Name=isnull(t1.File2Name,''),File3Name=isnull(t1.File3Name,''),File4Name=isnull(t1.File4Name,''), TCNo=isnull(t1.TCNo,''),Status=isnull(t1.Status,''),
	UpdatedBy=ISNULL(T1.UpdatedBy,''),UpdatedTS=ISNULL(T1.UpdatedTS,''),Remarks=ISNULL(T1.Remarks,''),ApprovedBy=ISNULL(T1.ApprovedBy,''),ApprovedTS=isnull(t1.ApprovedTS,''),RejQty=isnull(t1.RejQty,0)
	from
	(
	select distinct PONumber,MaterialID,InvoiceNumber,GRNNo ,MaterialType , File1 ,File1Name, File2 ,File2Name,
	File3 ,File3Name,File4 ,File4Name,TCNo ,Status ,UpdatedBy ,UpdatedTS,Remarks,ApprovedBy,ApprovedTS,RejQty from QualityApprovalDetails_PAMS
	)t1 inner join #temp on #temp.PONumber=t1.PONumber and #temp.MaterialID=t1.MaterialID and #temp.InvoiceNumber=t1.InvoiceNumber and #temp.GRNNo=t1.GRNNo  

	--UPDATE #temp SET Status=(T1.STATUS)
	--FROM
	--(
	--	SELECT DISTINCT materialid,INVOICENUMBER,GrnNo,status,updatedby,updatedts FROM FinalInspectionTransaction_PAMS
	--)  t1 inner join #temp on #temp.MaterialID=t1.materialid and #temp.INVOICENUMBER=t1.INVOICENUMBER and #temp.GrnNo=t1.GrnNo

	--select #temp.Supplier,#temp.MaterialType,#temp.PONumber,#temp.MaterialID,#temp.Invoicenumber,#temp.receivedQty,#temp.GRNNo,#temp.Remarks,#temp.File1,#temp.File2,#temp.File3,#temp.File1Name,
	--#temp.File2Name,#temp.File3Name,#temp.TCNo,case when isnull(f1.Status,'')='Approved' then 'Inspection Completed' else 'Inspection Pending' end AS Status,isnull(#temp.UpdatedBy,'') as UpdatedBy,isnull(#temp.UpdatedTS,'') as UpdatedTS,
	--isnull(#temp.approvedby,'') as approvedby,isnull(#temp.approvedts,'') as approvedts from #temp
	--left join FinalInspectionTransaction_PAMS f1 on f1.MaterialID=#temp.MaterialID and f1.InvoiceNumber=#temp.Invoicenumber and f1.GRNNo=#temp.GRNNo

	
	select #temp.Supplier,#temp.MaterialType,#temp.PONumber,#temp.MaterialID,#temp.Invoicenumber,#temp.receivedQty,#temp.GRNNo,#temp.Remarks,#temp.File1,#temp.File2,#temp.File3,#temp.File4, #temp.File1Name,
	#temp.File2Name,#temp.File3Name,#temp.File4Name, #temp.TCNo,#Temp.RejQty,isnull(f1.Status,'') as InspectionApprovalStatus,case when isnull(f1.Status,'')<>'' then 'Inspection Completed' else 'Inspection Pending' end as Status,isnull(#temp.UpdatedBy,'') as UpdatedBy,isnull(#temp.UpdatedTS,'') as UpdatedTS,
	isnull(#temp.approvedby,'') as approvedby,isnull(#temp.approvedts,'') as approvedts from #temp
	left join FinalInspectionTransaction_PAMS f1 on f1.MaterialID=#temp.MaterialID and f1.InvoiceNumber=#temp.Invoicenumber and f1.GRNNo=#temp.GRNNo
	order by grnid desc

	select * from InvoiceFileDetails_PAMS 


end

IF @Param='Save'
begin
	if not exists(select * from QualityApprovalDetails_PAMS where PONumber=@POnumber and InvoiceNumber=@invoiceNumber and MaterialID=@materialid and grnno=@Grnno)
	begin
		insert into QualityApprovalDetails_PAMS(PONumber,MaterialID,InvoiceNumber,GRNNo,MaterialType, File1 ,File2,File3,File4,TCNo  ,UpdatedBy ,UpdatedTS,Remarks,File1Name,File2Name,File3Name,File4Name,RejQty)
		values(@POnumber,@materialid,@invoiceNumber,@GrnNo,@MaterialType,@file1,@File2,@File3,@File4,@TCNo,@UpdatedBy,@updatedts,@Remarks,@File1Name,@File2Name,@File3Name,@File4Name,@RejQty)
	end
	else
	begin
		update QualityApprovalDetails_PAMS set File1=@file1 ,File2=@File2,File3=@File3,File4=@File4,File1Name=@File1Name,File2Name=@File2Name,File3Name=@File3Name,File4Name=@File4Name,TCNo=@TCNo,UpdatedBy=@UpdatedBy ,UpdatedTS=@updatedts,Remarks=@Remarks,RejQty=@RejQty
		where PONumber=@POnumber and InvoiceNumber=@invoiceNumber and MaterialID=@materialid and grnno=@Grnno
	end
end

IF @Param='ApprovedStatus'
begin
	update QualityApprovalDetails_PAMS set ApprovedBy=@ApprovedBy,ApprovedTS=@ApprovedTS 
	where PONumber=@POnumber and InvoiceNumber=@invoiceNumber and MaterialID=@materialid and grnno=@Grnno
end

END
