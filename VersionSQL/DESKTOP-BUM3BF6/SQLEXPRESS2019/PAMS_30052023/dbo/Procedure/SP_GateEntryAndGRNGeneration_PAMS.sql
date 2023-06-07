/****** Object:  Procedure [dbo].[SP_GateEntryAndGRNGeneration_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

/*
SP_GateEntryAndGRNGeneration_PAMS @Supplier=N'''V1''',@POnumber=N'3',@Type=N'GateEntryScreen', @Param=N'GateEntryViewScreen'

SP_GateEntryAndGRNGeneration_PAMS @Param=N'GateEntryAddScreen'
go
SP_GateEntryAndGRNGeneration_PAMS @Param=N'GateEntryEditSceen'
go
SP_GateEntryAndGRNGeneration_PAMS @Param=N'GateEntryDetailsSave'
go
SP_GateEntryAndGRNGeneration_PAMS @Param=N'GateEntryViewScreen'
go
SP_GateEntryAndGRNGeneration_PAMS @Param=N'StoresGrnViewScreen'
go
SP_GateEntryAndGRNGeneration_PAMS @Param=N'StoresGRNoSave'

*/
CREATE procedure [dbo].[SP_GateEntryAndGRNGeneration_PAMS]
@Supplier nvarchar(max)='',
@POnumber nvarchar(100)='',
@Poid int=0,
@materialid nvarchar(50)='',
@receivedqty float=0,
@invoiceNumber nvarchar(50)='',
@InvoiceDate datetime='',
@gateid int=0,
@gatentrynumber nvarchar(50)='',
@vehicle nvarchar(50)='',
@GrnID INT=0,
@GrnNo NVARCHAR(50)='',
@OrderedQty float=0,
@MaterialType nvarchar(50)='',
@FromDate datetime='',
@ToDate datetime='',
@GateEntryDate datetime='',
@GrnDate datetime='',
@updatedts datetime='',
@UpdatedBy NVARCHAR(50)='',
@Param nvarchar(100)='',
@Type nvarchar(100)='',
@file1 varbinary(MAX)=null,
@File1Name nvarchar(50)='',
@Location nvarchar(50)='',
@Remarks nvarchar(50)='',
@ReceivedQty_NUmbers FLOAT=0,
@UOM NVARCHAR(50)='',
@OldInvoiceNumber nvarchar(2000)='',
@postatus nvarchar(50)='',
@PartID nvarchar(50)='',
@FileID NVARCHAR(50)=''
as
begin
CREATE TABLE #GateEntry
(
Supplier nvarchar(500) DEFAULT '',
POId int DEFAULT 0,
PONumber nvarchar(100) DEFAULT '',
MaterialID nvarchar(50) DEFAULT '',
MaterialDescription nvarchar(2000),
FGNumber nvarchar(50),
UOM NVARCHAR(50),
POQty float default 0,
ReceivedQty float default 0,
PendingQty float default 0,
InvoiceNumber nvarchar(50) DEFAULT '',
InvoiceDate nvarchar(50),
Remarks nvarchar(2000),
VehicleNumber nvarchar(50),
GateID INT,
GateEntryNumber nvarchar(100),
ShowBit int
)

create table #GateEntryViewForGatePerson
(
Supplier NVARCHAR(50),
PONumber NVARCHAR(50),
MaterialID NVARCHAR(50),
FGNumber NVARCHAR(50),
Invoicenumber NVARCHAR(50),
InvoiceDate nvarchar(50),
Remarks nvarchar(2000),
gateid int,
GateEntryNumber NVARCHAR(50),
Vehicle NVARCHAR(50),
OrderedQty FLOAT,
receivedQty FLOAT,
PendingQty float,
UpdatedBy NVARCHAR(50),
UpdatedTS DATETIME DEFAULT GETDATE(),
GrnID INT, 
GRNNo nvarchar(50),
RiseIssue bit default 0,
UOM NVARCHAR(50),
MaterialType nvarchar(50),
MaterialLevelPOQty float,
MaterialLevelReceivedQty float,
GatePerson varchar(50),
GateEntryDate datetime,
GRNDate datetime,
StoresPerson nvarchar(50),
Qty float,
InspectionStatus nvarchar(50),
Location nvarchar(500),
ReceivedQty_NUmbers FLOAT,
)

create table #GateEntryViewForGRNPerson
(
Supplier NVARCHAR(50),
PONumber NVARCHAR(50),
MaterialID NVARCHAR(50),
FGNumber NVARCHAR(50),
Invoicenumber NVARCHAR(50),
InvoiceDate nvarchar(50),
Remarks nvarchar(2000),
GateEntryNumber NVARCHAR(50),
Vehicle NVARCHAR(50),
OrderedQty FLOAT,
receivedQty FLOAT,
PendingQty float,
UpdatedBy NVARCHAR(50),
UpdatedTS DATETIME DEFAULT GETDATE(),
GrnID INT, 
GRNNo nvarchar(50),
RiseIssue bit default 0,
MaterialType nvarchar(50),
UOM NVARCHAR(50),
)

create table #GateEntryEditScreen
(
AutoID BIGINT,
Supplier nvarchar(50),
POId int,
ponumber nvarchar(50),
MaterialID nvarchar(50),
OrderedQty nvarchar(50),
ReceivedQty float,
PendingQty float,
grnno nvarchar(50),
MaterialLevelPOQty float,
MaterialLevelReceivedQty float,
Remarks nvarchar(2000),
InvoiceDate nvarchar(50)
)



declare @strSupplier nvarchar(4000)
declare @strPONumber nvarchar(4000)
declare @strMaterial nvarchar(4000)
declare @strInvoiceNumber nvarchar(4000)
declare @strsql nvarchar(max)
declare @strMaterialType nvarchar(4000)
declare @strGateNo nvarchar(4000)

select @strsql=''
select @strSupplier=''
select @strPONumber=''
select @strMaterial=''
select @strInvoiceNumber=''
select @strMaterialType=''
select @strGateNo=''

if isnull(@Supplier,'')<>''
begin
	select @strSupplier='And g1.supplier in (' + @Supplier + ')'
end

if isnull(@POnumber,'')<>''
begin
	select @strPONumber='And g1.ponumber like ''%'+@POnumber+'%'' '
END

if isnull(@materialid,'')<>''
begin
	select @strMaterial='And g1.Materialid like ''%'+@materialid+'%'' '
END

if isnull(@invoiceNumber,'')<>''
begin
	select @strInvoiceNumber='And g1.invoicenumber= N''' + @invoiceNumber +''' '
END

if isnull(@MaterialType,'')<>''
begin
	select @strMaterialType='And g1.type in (' + @MaterialType + ')'
END

if isnull(@gatentrynumber,'')<>''
begin
	select @strGateNo='And g1.gatentrynumber like ''%'+@gatentrynumber+'%'' '
end

 -----------------------------------------------------------------------------GateEntryScreenDetails---------------------------------------------------------------------------------------------------------

 IF @Param='GateEntryEditSceen'
begin
	insert into #GateEntryEditScreen(AutoID,Supplier ,POId,ponumber,MaterialID,OrderedQty,ReceivedQty,grnno,Remarks,InvoiceDate)
	select g1.AutoID,g1.Supplier as Supplier,g1.POId as POId,g1.ponumber as PONumber,g1.MaterialID,g1.OrderedQty, g1.ReceivedQty,g2.grnno,g1.remarks,g1.InvoiceDate from GateEntryScreenDetails_PAMS g1
	left join GrnNoGeneration_PAMS g2 on g1.Supplier=g2.Supplier and g1.PONumber=g2.PONumber and g1.MaterialID=g2.MaterialID and g1.InvoiceNumber=g2.InvoiceNumber
	where g1.Supplier=@Supplier and g1.PONumber=@POnumber and g1.InvoiceNumber=@invoiceNumber

	update #GateEntryEditScreen set MaterialLevelPOQty=isnull(t1.RECEIVED,0)
	from
	(	select g1.Supplier as Supplier,g1.POId,g1.PONumber,g1.MaterialID, SUM(ISNULL(g1.POQty,0)) AS RECEIVED from GeneratePODetails_PAMS G1 
	group by  g1.Supplier ,g1.POId,g1.PONumber,g1.MaterialID 
	)t1 inner join #GateEntryEditScreen on #GateEntryEditScreen.Supplier=t1.Supplier and #GateEntryEditScreen.PONumber=t1.PONumber and #GateEntryEditScreen.MaterialID=t1.MaterialID


	update #GateEntryEditScreen set MaterialLevelReceivedQty=isnull(t1.RECEIVED,0)
	from
	(	select g1.Supplier as Supplier,g1.POId,g1.PONumber,g1.MaterialID, SUM(ISNULL(g1.ReceivedQty,0)) AS RECEIVED from GateEntryScreenDetails_PAMS G1 
	group by  g1.Supplier ,g1.POId,g1.PONumber,g1.MaterialID 
	)t1 inner join #GateEntryEditScreen on #GateEntryEditScreen.Supplier=t1.Supplier and #GateEntryEditScreen.PONumber=t1.PONumber and #GateEntryEditScreen.MaterialID=t1.MaterialID

	select g1.AutoID,G1.Supplier,G1.POId,G1.ponumber,G1.MaterialID,r1.MaterialDescription, G1.OrderedQty ,G1.ReceivedQty ,case when (isnull(G1.MaterialLevelPOQty,0)-isnull(G1.MaterialLevelReceivedQty,0)) >=0 then (isnull(G1.MaterialLevelPOQty,0)-isnull(G1.MaterialLevelReceivedQty,0))
	else 0 end  as PendingQty,G1.grnno,R1.UOM,g1.Remarks,g1.InvoiceDate from #GateEntryEditScreen G1
	LEFT JOIN (SELECT DISTINCT MATERIALID,UOM,MaterialDescription FROM RawMaterialDetails_PAMS)R1 ON R1.MaterialID=G1.MaterialID

end

if @Param='GateEntryAddScreen'
begin
	insert into #GateEntry(Supplier,POId,PONumber,MaterialID,POQty,ReceivedQty,PendingQty,uom,ShowBit,MaterialDescription)
	select g1.Supplier as Supplier,g1.POId,g1.PONumber,g1.MaterialID,sum(g1.POQTY) as POQTY,SUM(ISNULL(g2.ReceivedQty,0)) as ReceivedQty, (sum(g1.POQTY)-SUM(ISNULL(g2.ReceivedQty,0))) AS PendingQty,r1.UOM,
	case when SUM(ISNULL(g2.ReceivedQty,0))>=sum(isnull(g1.POQTY,0)) then 0 else 1 end ShowBit,r1.MaterialDescription from GeneratePODetails_PAMS G1
	LEFT JOIN (SELECT DISTINCT Supplier,PONumber,MaterialID,SUM(ReceivedQty) AS ReceivedQty FROM GateEntryScreenDetails_PAMS GROUP BY Supplier,PONumber,MaterialID) G2 ON G1.Supplier=G2.Supplier AND G1.PONumber=G2.PONumber AND G1.MaterialID=G2.MaterialID
	left join RawMaterialDetails_PAMS r1 on r1.MaterialID=g1.MaterialID
	where g1.Supplier=@Supplier and g1.PONumber=@POnumber
	group by  g1.Supplier ,g1.POId,g1.PONumber,g1.MaterialID,R1.UOM,r1.MaterialDescription


	SELECT Supplier,POId,PONumber,MaterialID,MaterialDescription,POQty AS OrderedQty,case when PendingQty>=0 then PendingQty else 0 end as PendingQty,uom,ShowBit FROM #GateEntry where ShowBit=1
	RETURN
end

if @Param='GateEntryDetailsSave'
begin
	if not exists(select * from InvoiceFileDetails_PAMS where supplier=@Supplier and POnumber=@POnumber and MaterialType=@MaterialType and invoicenumber=@invoiceNumber)
	begin
		insert into InvoiceFileDetails_PAMS(supplier,POnumber,MaterialType,invoicenumber,InvoiceDate,File1,File1name,FileID)
		values(@Supplier,@POnumber,@MaterialType,@invoiceNumber,@InvoiceDate,@File1,@file1Name,@FileID)
	end
	else
	begin
		update InvoiceFileDetails_PAMS set File1=@file1,File1Name=@File1Name,FileID=@FileID,UpdatedBy=@UpdatedBy,UpdatedTS=GETDATE() where supplier=@Supplier and POnumber=@POnumber and MaterialType=@MaterialType and invoicenumber=@invoiceNumber 
	end
	
	if not exists(select * from GateEntryScreenDetails_PAMS where POnumber=@POnumber and materialid=@materialid and invoiceNumber=@invoiceNumber)
	begin
		insert into GateEntryScreenDetails_PAMS(Supplier,poid,ponumber,materialid,receivedqty,invoiceNumber,gateid,gateentrynumber,updatedts,vehicle,OrderedQty,[type],UpdatedBy,GateEntryDate,InvoiceDate,Remarks)
		values(@Supplier,@poid,@ponumber,@materialid,@receivedqty,@invoiceNumber,@gateid,@gatentrynumber,getdate(),@vehicle,@OrderedQty,@MaterialType,@UpdatedBy,@GateEntryDate,@InvoiceDate,@Remarks)
	end
	else
	begin
		update GateEntryScreenDetails_PAMS set receivedqty=@receivedqty,UpdatedTS=@updatedts where POnumber=@POnumber and materialid=@materialid and invoiceNumber=@invoiceNumber
	end
end

if @Param='GateEntryViewScreen'
begin
	select @strsql=''
	select @strsql=@strsql+'Insert into #GateEntryViewForGatePerson(Supplier,PONumber,MaterialID,Invoicenumber,InvoiceDate,Remarks,gateid,GateEntryNumber,Vehicle,OrderedQty,receivedQty,UpdatedBy,UpdatedTS,GrnID,G2.GRNNo,RiseIssue, MaterialType,UOM,GateEntryDate,GRNDate,StoresPerson,InspectionStatus,Location,ReceivedQty_NUmbers)'
	select @strsql=@strsql+'select distinct g1.Supplier,g1.PONumber,g1.MaterialID,g1.Invoicenumber,g1.InvoiceDate,g1.Remarks,g1.gateid,g1.GateEntryNumber,g1.Vehicle,g1.OrderedQty,g1.receivedQty,g1.UpdatedBy,g1.UpdatedTS,g2.GrnID,G2.GRNNo,g1.RiseIssue,G1.Type as MaterialType,r1.uom,g1.GateEntryDate,g2.grndate,
	g2.updatedby,isnull(g2.QualityStatus,''Inspection Pending''),g2.Location,G2.ReceivedQty_NUmbers from GateEntryScreenDetails_PAMS g1
	left join GrnNoGeneration_PAMS g2 on g1.Supplier=g2.Supplier and g1.ponumber=g2.ponumber and g1.materialid=g2.materialid and g1.invoicenumber=g2.invoicenumber
	left join RawMaterialDetails_PAMS r1 on r1.MaterialID=g1.MaterialID
	where convert(nvarchar(10),GateEntryDate,126)>='''+convert(nvarchar(10),@FromDate,126)+''' and convert(nvarchar(10),GateEntryDate,126)<='''+convert(nvarchar(10),@ToDate,126)+''' and 1=1'
	select @strsql=@strsql+@strSupplier+@strPONumber+@strMaterial+@strInvoiceNumber+@strMaterialType
	print(@strsql)
	exec(@strsql)

	
	update #GateEntryViewForGatePerson set MaterialLevelPOQty=isnull(t1.RECEIVED,0)
	from
	(select g1.Supplier as Supplier,g1.POId,g1.PONumber,g1.MaterialID, SUM(ISNULL(g1.POQty,0)) AS RECEIVED from GeneratePODetails_PAMS G1 
	group by  g1.Supplier ,g1.POId,g1.PONumber,g1.MaterialID 
	)t1 inner join #GateEntryViewForGatePerson on #GateEntryViewForGatePerson.Supplier=t1.Supplier and #GateEntryViewForGatePerson.PONumber=t1.PONumber and #GateEntryViewForGatePerson.MaterialID=t1.MaterialID


	update #GateEntryViewForGatePerson set MaterialLevelReceivedQty=isnull(t1.RECEIVED,0)
	from
	(	select g1.Supplier as Supplier,g1.POId,g1.PONumber,g1.MaterialID, SUM(ISNULL(g1.ReceivedQty,0)) AS RECEIVED from GateEntryScreenDetails_PAMS G1 
	group by  g1.Supplier ,g1.POId,g1.PONumber,g1.MaterialID 
	)t1 inner join #GateEntryViewForGatePerson on #GateEntryViewForGatePerson.Supplier=t1.Supplier and #GateEntryViewForGatePerson.PONumber=t1.PONumber and #GateEntryViewForGatePerson.MaterialID=t1.MaterialID

	--update #GateEntryViewForGatePerson set FGNumber=(t2.PartID)
	--from
	--(
	--select distinct G1.MPRNo,G1.PONumber,G1.MaterialID,G1.PartID from GeneratePODetails_PAMS g1
	--inner join (select distinct MPRNo,PONumber,MaterialID,max(autoid) as autoid from GeneratePODetails_PAMS
	--group by MPRNo,PONumber,MaterialID) 
	--t1 on g1.MPRNo=t1.MPRNo and g1.PONumber=t1.PONumber and g1.MaterialID=t1.MaterialID AND G1.AutoID=T1.autoid

	--update #GateEntryViewForGatePerson set FGNumber=(t2.PartID)
	--from
	--(
	--select distinct g1.MaterialID,g1.PartID from RawMaterialAndFGAssociation_PAMS g1
	--inner join #GateEntryViewForGatePerson g2 on g1.MaterialID=g2.MaterialID
	--where isnull(g1.DefaultPartBit,0)=1
	--)T2 INNER JOIN #GateEntryViewForGatePerson ON	 T2.MaterialID=#GateEntryViewForGatePerson.MaterialID

	update #GateEntryViewForGatePerson set FGNumber=(t2.PartID)
	from
	(
	select distinct g1.MaterialID,g1.PartID from GrnNoGeneration_PAMS g1
	)T2 INNER JOIN #GateEntryViewForGatePerson ON	 T2.MaterialID=#GateEntryViewForGatePerson.MaterialID



	update #GateEntryViewForGatePerson set Qty=(t1.qty)
	from
	(
	select distinct MaterialID,PartID,case when PartLength_mm>0 then ((TotalLength-(CuttingAllowance+EndBitAllowance))/PartLength_mm) else 0 end as Qty from RawMaterialAndFGAssociation_PAMS
	) t1 inner join #GateEntryViewForGatePerson on #GateEntryViewForGatePerson.MaterialID=t1.MaterialID and #GateEntryViewForGatePerson.FGNumber=t1.PartID


	select Supplier,PONumber,G1.MaterialID ,FGNumber,case when round(isnull(Qty,0),2)>0 then Qty else receivedQty end as Qty,G1.Invoicenumber ,GateEntryNumber,Vehicle,OrderedQty ,receivedQty ,
	CASE WHEN ((isnull(MaterialLevelPOQty,0)- isnull(MaterialLevelReceivedQty,0)))>=0 THEN ((isnull(MaterialLevelPOQty,0)- isnull(MaterialLevelReceivedQty,0))) ELSE 0 END as PendingQty,
	GrnID , G1.GRNNo ,RiseIssue ,UOM ,MaterialType,GateEntryDate,G1.UpdatedBy as GatePerson,GrnDate,StoresPerson,InspectionStatus,g1.location,f1.Status as InspectionApprovalStatus,g1.InvoiceDate,g1.Remarks,G1.ReceivedQty_NUmbers from #GateEntryViewForGatePerson G1
	left join FinalInspectionTransaction_PAMS f1 on f1.MaterialID=G1.MaterialID and f1.InvoiceNumber=G1.Invoicenumber and f1.GRNNo=G1.GRNNo
	order by gateid desc

	select * from InvoiceFileDetails_PAMS  --where Supplier=@Supplier and PONumber=@POnumber and InvoiceNumber=@invoiceNumber


end


if @Param='StoresGRNoSave'
begin
	if not exists(select * from GrnNoGeneration_PAMS  where Supplier=@Supplier and POnumber=@POnumber and materialid=@materialid and invoiceNumber=@invoiceNumber)
	begin

		update GateEntryScreenDetails_PAMS set RiseIssue=0 where Supplier=@Supplier and POnumber=@POnumber and materialid=@materialid and invoiceNumber=@invoiceNumber

		if isnull(@postatus,'')<>''
		begin
			update GeneratePODetails_PAMS set Status=@postatus where PONumber=@POnumber and MaterialID=@materialid
		end

		insert into GrnNoGeneration_PAMS (Supplier,poid,ponumber,materialid,receivedqty,invoiceNumber,GrnID,GrnNo,updatedts,UpdatedBy,[type],GRNDate,OrderedQty,GRNStatus,Location,ReceivedQty_NUmbers,UOM,PartID)
		values(@Supplier,@poid,@ponumber,@materialid,@receivedqty,@invoiceNumber,@GrnID,@GrnNo,getdate(),@UpdatedBy,@MaterialType,@GrnDate,@OrderedQty,'Open',@Location,@ReceivedQty_NUmbers,@UOM,@PartID)
	end
	else
	begin
		update GrnNoGeneration_PAMS set Location=@Location where Supplier=@Supplier and POnumber=@POnumber and materialid=@materialid and invoiceNumber=@invoiceNumber
	end
	-------------------------------------------------------------------------------------Generate MJC While generating GRNNo-------------------------------------------------------------------------------------------------------
	
	if not exists(select * from MasterJobCardHeaderCreation_PAMS where GRNNo=@GrnNo and MJCNo=@GrnNo)
	begin
		insert into MasterJobCardHeaderCreation_PAMS(GRNNo,MJCNo,UpdatedBy,UpdatedTS,MJCStatus)
		values(@GrnNo,@GrnNo,@UpdatedBy,getdate(),'Open')
	end

end

if @Param='UpdateIssueRised'
begin
	update GateEntryScreenDetails_PAMS set RiseIssue=1 where Supplier=@Supplier and POnumber=@POnumber and materialid=@materialid and invoiceNumber=@invoiceNumber
end

IF @Param='UpdateInvoice'
begin
	update GateEntryScreenDetails_PAMS set InvoiceNumber=@invoiceNumber where 
	Supplier=@Supplier and PONumber=@POnumber and Type=@MaterialType and InvoiceNumber=@OldInvoiceNumber

	update InvoiceFileDetails_PAMS set InvoiceNumber=@invoiceNumber
	where Supplier=@Supplier and PONumber=@POnumber and MaterialType=@MaterialType and InvoiceNumber=@OldInvoiceNumber
end
end
