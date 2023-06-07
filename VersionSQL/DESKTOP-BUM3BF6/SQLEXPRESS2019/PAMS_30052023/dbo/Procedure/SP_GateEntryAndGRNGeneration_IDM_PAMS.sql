/****** Object:  Procedure [dbo].[SP_GateEntryAndGRNGeneration_IDM_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

/*
SP_GateEntryAndGRNGeneration_IDM_PAMS @Supplier=N'''V1''',@POnumber=N'3',@Type=N'GateEntryScreen', @Param=N'GateEntryViewScreen'

SP_GateEntryAndGRNGeneration_IDM_PAMS @Param=N'GateEntryAddScreen'
go
SP_GateEntryAndGRNGeneration_IDM_PAMS @Param=N'GateEntryEditSceen'
go
SP_GateEntryAndGRNGeneration_IDM_PAMS @Param=N'GateEntryDetailsSave'
go
SP_GateEntryAndGRNGeneration_IDM_PAMS @Param=N'GateEntryViewScreen'
go
SP_GateEntryAndGRNGeneration_IDM_PAMS @Param=N'StoresGrnViewScreen'
go
SP_GateEntryAndGRNGeneration_IDM_PAMS @Param=N'StoresGRNoSave'

*/
CREATE procedure [dbo].[SP_GateEntryAndGRNGeneration_IDM_PAMS]
@Supplier nvarchar(max)='',
@POnumber nvarchar(100)='',
@Poid int=0,
@ItemName nvarchar(50)='',
@receivedqty float=0,
@invoiceNumber nvarchar(50)='',
@InvoiceDate datetime='',
@Remarks nvarchar(50)='',
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
@OldInvoiceNumber nvarchar(100)='',
@postatus nvarchar(50)=''


as
begin
CREATE TABLE #GateEntry
(
Supplier nvarchar(max) DEFAULT '',
PONumber nvarchar(100) DEFAULT '',
POId int,
ItemName nvarchar(50) DEFAULT '',
ItemDescription nvarchar(500),
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
Supplier NVARCHAR(max),
PONumber NVARCHAR(50),
ItemName NVARCHAR(50),
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
Location nvarchar(500)
)


create table #GateEntryEditScreen
(
Supplier nvarchar(max),
POId int,
ponumber nvarchar(50),
ItemName nvarchar(50),
ItemDescription nvarchar(500),
OrderedQty nvarchar(50),
ReceivedQty float,
PendingQty float,
grnno nvarchar(50),
MaterialLevelPOQty float,
MaterialLevelReceivedQty float

)



declare @strSupplier nvarchar(max)
declare @strPONumber nvarchar(4000)
declare @strItemName nvarchar(4000)
declare @strInvoiceNumber nvarchar(4000)
declare @strsql nvarchar(max)
declare @strMaterialType nvarchar(4000)
declare @strGateNo nvarchar(4000)

select @strsql=''
select @strSupplier=''
select @strPONumber=''
select @strItemName=''
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

if isnull(@ItemName,'')<>''
begin
	select @strItemName='And g1.itemname like ''%'+@ItemName+'%'' '
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
	insert into #GateEntryEditScreen(Supplier ,POId,ponumber,ItemName,OrderedQty,ReceivedQty,grnno,ItemDescription)
	select g1.Supplier as Supplier,g1.POId as POId,g1.ponumber as PONumber,g1.ItemName,g1.OrderedQty, g1.ReceivedQty,g2.grnno,t3.ItemDescription from GateEntryScreenDetails_IDM_PAMS g1
	left join GrnNoGeneration_IDM_PAMS g2 on g1.Supplier=g2.Supplier and g1.PONumber=g2.PONumber and g1.ItemName=g2.ItemName and g1.InvoiceNumber=g2.InvoiceNumber
	left join (select distinct ItemName,ItemDescription from IDMGeneralMaster_PAMS) t3 on g1.ItemName=t3.ItemName
	where g1.Supplier=@Supplier and g1.PONumber=@POnumber and g1.InvoiceNumber=@invoiceNumber

	update #GateEntryEditScreen set MaterialLevelPOQty=isnull(t1.RECEIVED,0)
	from
	(	select g1.Supplier as Supplier,g1.POId,g1.PONumber,g1.ItemName, SUM(ISNULL(g1.POQty,0)) AS RECEIVED from GeneratePODetails_IDM_PAMS G1 
	group by  g1.Supplier ,g1.POId,g1.PONumber,g1.ItemName 
	)t1 inner join #GateEntryEditScreen on #GateEntryEditScreen.Supplier=t1.Supplier and #GateEntryEditScreen.PONumber=t1.PONumber and #GateEntryEditScreen.ItemName=t1.ItemName


	update #GateEntryEditScreen set MaterialLevelReceivedQty=isnull(t1.RECEIVED,0)
	from
	(	select g1.Supplier as Supplier,g1.POId,g1.PONumber,g1.ItemName, SUM(ISNULL(g1.ReceivedQty,0)) AS RECEIVED from GateEntryScreenDetails_IDM_PAMS G1 
	group by  g1.Supplier ,g1.POId,g1.PONumber,g1.ItemName 
	)t1 inner join #GateEntryEditScreen on #GateEntryEditScreen.Supplier=t1.Supplier and #GateEntryEditScreen.PONumber=t1.PONumber and #GateEntryEditScreen.ItemName=t1.ItemName

	select Supplier,POId,ponumber,ItemName,ItemDescription,OrderedQty ,ReceivedQty ,case when  (isnull(MaterialLevelPOQty,0)-isnull(MaterialLevelReceivedQty,0))>=0 then (isnull(MaterialLevelPOQty,0)-isnull(MaterialLevelReceivedQty,0))
	else '0' end as PendingQty,grnno from #GateEntryEditScreen 

end

if @Param='GateEntryAddScreen' 
begin
	insert into #GateEntry(Supplier,POId,PONumber,ItemName,POQty,ReceivedQty,PendingQty,uom,ShowBit,ItemDescription)
	select distinct g1.Supplier as Supplier,g1.POId,g1.PONumber,g1.ItemName,sum(g1.POQTY) as POQTY,SUM(ISNULL(g2.ReceivedQty,0)) as ReceivedQty, (sum(g1.POQTY)-SUM(ISNULL(g2.ReceivedQty,0))) AS PendingQty,r1.UOM,
	case when SUM(ISNULL(g2.ReceivedQty,0))>=sum(isnull(g1.POQTY,0)) then 0 else 1 end ShowBit,r1.ItemDescription from GeneratePODetails_IDM_PAMS G1
	LEFT JOIN (SELECT DISTINCT Supplier,PONumber,ItemName,SUM(ReceivedQty) AS ReceivedQty FROM GateEntryScreenDetails_IDM_PAMS GROUP BY Supplier,PONumber,ItemName) G2 ON G1.Supplier=G2.Supplier AND G1.PONumber=G2.PONumber AND G1.ItemName=G2.itemname
	left join IDMGeneralMaster_PAMS r1 on r1.ItemName=g1.ItemName and r1.Department=G1.Department and r1.ItemCategory=G1.ItemCategory
	where g1.Supplier=@Supplier and g1.PONumber=@POnumber
	group by  g1.Supplier ,g1.POId,g1.PONumber,g1.ItemName,R1.UOM,r1.ItemDescription


	SELECT Supplier,POId,PONumber,Itemname,ItemDescription,POQty AS OrderedQty,case when  PendingQty>=0 then PendingQty else '0' end as PendingQty,uom FROM #GateEntry where ShowBit=1
	RETURN
end

if @Param='GateEntryDetailsSave'
begin
	if not exists(select * from InvoiceFileDetails_PAMS where supplier=@Supplier and POnumber=@POnumber and MaterialType=@MaterialType and invoicenumber=@invoiceNumber)
	begin
		insert into InvoiceFileDetails_PAMS(supplier,POnumber,MaterialType,invoicenumber,InvoiceDate,File1,File1name)
		values(@Supplier,@POnumber,@MaterialType,@invoiceNumber,@InvoiceDate,@File1,@file1Name)
	end
	else
	begin
		update InvoiceFileDetails_PAMS set File1=@file1,File1Name=@File1Name where supplier=@Supplier and POnumber=@POnumber and MaterialType=@MaterialType and invoicenumber=@invoiceNumber
	end
	
	if not exists(select * from GateEntryScreenDetails_IDM_PAMS where POnumber=@POnumber and ItemName=@ItemName and invoiceNumber=@invoiceNumber)
	begin
		insert into GateEntryScreenDetails_IDM_PAMS(Supplier,poid,ponumber,ItemName,receivedqty,invoiceNumber,gateid,gateentrynumber,updatedts,vehicle,OrderedQty,[type],UpdatedBy,GateEntryDate,InvoiceDate,Remarks)
		values(@Supplier,@poid,@ponumber,@ItemName,@receivedqty,@invoiceNumber,@gateid,@gatentrynumber,getdate(),@vehicle,@OrderedQty,@MaterialType,@UpdatedBy,@GateEntryDate,@InvoiceDate,@Remarks)
	end
	else
	begin
		update GateEntryScreenDetails_IDM_PAMS set receivedqty=@receivedqty,UpdatedTS=@updatedts where POnumber=@POnumber and ItemName=@ItemName and invoiceNumber=@invoiceNumber
	end
end

if @Param='GateEntryViewScreen'
begin
	select @strsql=''
	select @strsql=@strsql+'Insert into #GateEntryViewForGatePerson(Supplier,PONumber,Itemname,Invoicenumber,InvoiceDate,Remarks,GateEntryNumber,Vehicle,OrderedQty,receivedQty,UpdatedBy,UpdatedTS,GrnID,G2.GRNNo,RiseIssue, MaterialType,UOM,GateEntryDate,GRNDate,StoresPerson,InspectionStatus,Location)'
	select @strsql=@strsql+'select distinct g1.Supplier,g1.PONumber,g1.Itemname,g1.Invoicenumber,g1.InvoiceDate,g1.Remarks,g1.GateEntryNumber,g1.Vehicle,g1.OrderedQty,g1.receivedQty,g1.UpdatedBy,g1.UpdatedTS,g2.GrnID,G2.GRNNo,g1.RiseIssue,G1.Type as MaterialType,r1.uom,g1.GateEntryDate,g2.grndate,
	g2.updatedby,isnull(g2.QualityStatus,''Inspection Pending''),g2.Location from GateEntryScreenDetails_IDM_PAMS g1
	left join GrnNoGeneration_IDM_PAMS g2 on g1.Supplier=g2.Supplier and g1.ponumber=g2.ponumber and g1.itemname=g2.itemname and g1.invoicenumber=g2.invoicenumber
	left join IDMGeneralMaster_PAMS r1 on r1.itemname=g1.itemname
	where convert(nvarchar(10),GateEntryDate,126)>='''+convert(nvarchar(10),@FromDate,126)+''' and convert(nvarchar(10),GateEntryDate,126)<='''+convert(nvarchar(10),@ToDate,126)+''' and 1=1'
	select @strsql=@strsql+@strSupplier+@strPONumber+@strItemName+@strInvoiceNumber+@strMaterialType
	print(@strsql)
	exec(@strsql)

	
	update #GateEntryViewForGatePerson set MaterialLevelPOQty=isnull(t1.RECEIVED,0)
	from
	(select g1.Supplier as Supplier,g1.POId,g1.PONumber,g1.ItemName, SUM(ISNULL(g1.POQty,0)) AS RECEIVED from GeneratePODetails_IDM_PAMS G1 
	group by  g1.Supplier ,g1.POId,g1.PONumber,g1.ItemName 
	)t1 inner join #GateEntryViewForGatePerson on #GateEntryViewForGatePerson.Supplier=t1.Supplier and #GateEntryViewForGatePerson.PONumber=t1.PONumber and #GateEntryViewForGatePerson.ItemName=t1.ItemName


	update #GateEntryViewForGatePerson set MaterialLevelReceivedQty=isnull(t1.RECEIVED,0)
	from
	(	select g1.Supplier as Supplier,g1.POId,g1.PONumber,g1.ItemName, SUM(ISNULL(g1.ReceivedQty,0)) AS RECEIVED from GateEntryScreenDetails_IDM_PAMS G1 
	group by  g1.Supplier ,g1.POId,g1.PONumber,g1.ItemName 
	)t1 inner join #GateEntryViewForGatePerson on #GateEntryViewForGatePerson.Supplier=t1.Supplier and #GateEntryViewForGatePerson.PONumber=t1.PONumber and #GateEntryViewForGatePerson.ItemName=t1.itemname


	select Supplier,PONumber,G1.ItemName,round(isnull(Qty,0),2) as Qty,G1.Invoicenumber ,GateEntryNumber,Vehicle,OrderedQty ,receivedQty ,
	CASE WHEN ((isnull(MaterialLevelPOQty,0)- isnull(MaterialLevelReceivedQty,0)))>=0 THEN ((isnull(MaterialLevelPOQty,0)- isnull(MaterialLevelReceivedQty,0))) ELSE 0 END as PendingQty,
	GrnID , G1.GRNNo ,RiseIssue ,UOM ,MaterialType,GateEntryDate,G1.UpdatedBy as GatePerson,GrnDate,StoresPerson,InspectionStatus,g1.Location,g1.InvoiceDate,g1.Remarks from #GateEntryViewForGatePerson G1
	order by GateEntryNumber,Supplier,PONumber,ItemName

	select * from InvoiceFileDetails_PAMS --where Supplier=@Supplier and PONumber=@POnumber and InvoiceNumber=@invoiceNumber


end


if @Param='StoresGRNoSave'
begin
	if not exists(select * from GrnNoGeneration_IDM_PAMS  where Supplier=@Supplier and POnumber=@POnumber and ItemName=@ItemName and invoiceNumber=@invoiceNumber)
	begin

		if isnull(@postatus,'')<>''
		begin
			update GeneratePODetails_IDM_PAMS set Status=@postatus where PONumber=@POnumber and ItemName=@ItemName
		end

		if not exists(select * from ItemStockDetails_IDM_Pams where itemname=@ItemName)
		begin
			insert into ItemStockDetails_IDM_Pams(itemname,InwardedQty) values(@ItemName,@receivedqty)
		end
		else
		begin
			update ItemStockDetails_IDM_Pams set InwardedQty=isnull(InwardedQty,0)+isnull(@receivedqty,0)
		end
		update GateEntryScreenDetails_IDM_PAMS set RiseIssue=0 where Supplier=@Supplier and POnumber=@POnumber and ItemName=@ItemName and invoiceNumber=@invoiceNumber

		insert into GrnNoGeneration_IDM_PAMS(Supplier,poid,ponumber,itemname,receivedqty,invoiceNumber,GrnID,GrnNo,updatedts,UpdatedBy,[type],GRNDate,OrderedQty,GRNStatus,Location)
		values(@Supplier,@poid,@ponumber,@ItemName,@receivedqty,@invoiceNumber,@GrnID,@GrnNo,getdate(),@UpdatedBy,@MaterialType,@GrnDate,@OrderedQty,'Open',@Location)
	end
	else
	begin
		update GrnNoGeneration_IDM_PAMS set Location=@Location  where Supplier=@Supplier and POnumber=@POnumber and ItemName=@ItemName and invoiceNumber=@invoiceNumber
	end


end

if @Param='UpdateIssueRised'
begin
	update GateEntryScreenDetails_IDM_PAMS set RiseIssue=1 where Supplier=@Supplier and POnumber=@POnumber and ItemName=@ItemName and invoiceNumber=@invoiceNumber
end


IF @Param='UpdateInvoice'
begin
	update GateEntryScreenDetails_IDM_PAMS set InvoiceNumber=@invoiceNumber where 
	Supplier=@Supplier and PONumber=@POnumber and Type=@MaterialType and InvoiceNumber=@OldInvoiceNumber

	update InvoiceFileDetails_PAMS set InvoiceNumber=@invoiceNumber
	where Supplier=@Supplier and PONumber=@POnumber and MaterialType=@MaterialType and InvoiceNumber=@OldInvoiceNumber
end
end
