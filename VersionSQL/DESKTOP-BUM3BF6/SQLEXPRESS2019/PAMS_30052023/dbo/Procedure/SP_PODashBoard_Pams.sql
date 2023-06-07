/****** Object:  Procedure [dbo].[SP_PODashBoard_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

/*
SP_PODashBoard_Pams '2022-01-01','2023-02-28','',''
*/
CREATE procedure [dbo].[SP_PODashBoard_Pams]
@FromDate datetime='',
@ToDate datetime='',
@Supplier nvarchar(50)='',
@PONumber nvarchar(50)=''
as
begin
	create table #Temp
	(
	MPRNo nvarchar(50),
	MPRDate datetime,
	PoNumber nvarchar(50),
	MaterialID NVARCHAR(50),
	MaterialDescription nvarchar(500),
	MPRQty float,
	POQty float,
	RequiredDate datetime,
	Supplier nvarchar(50),
	InvoiceNumber nvarchar(50),
	InvoiceDate datetime,
	ReceivedQty float default 0,
	Balance float,
	Remarks nvarchar(max),
	POStatus nvarchar(50),
	POCloseRemarks nvarchar(max)
	)

	declare @StrSupplier nvarchar(500)
	declare @StrSQL NVARCHAR(MAX)
	DECLARE @StrPONumber nvarchar(500)

	select @StrSupplier=''
	select @StrSQL=''
	select @StrPONumber=''

	if isnull(@Supplier,'')<>''
	begin
		select @StrSupplier='And Supplier like ''%'+@Supplier+'%'' '
	end

	if isnull(@PONumber,'')<>''
	begin
		select @StrPONumber='And PoNumber like ''%'+@PONumber+'%'' '
	end


	select @StrSQL=''
	select @StrSQL=@StrSQL+'Insert into #Temp(MPRNo,MPRDate,PoNumber,MaterialID,MaterialDescription,Supplier,Remarks,InvoiceDate,InvoiceNumber,POStatus,POCloseRemarks )'
	select @StrSQL=@StrSQL+'Select distinct g1.MPRNo,g3.MPRDate,g1.PoNumber,g1.MaterialID,g2.MaterialDescription,g1.Supplier,g1.Remarks,g4.InvoiceDate,g4.InvoiceNumber,g1.Status,g1.POCloseRemarks from GeneratePODetails_PAMS  g1
	left join (select distinct materialid,materialDescription from RawMaterialDetails_PAMS)g2 on g1.materialid=g2.materialid
	left join (select distinct mprno,materialid,mprdate from MPRDetailsTransaction_PPC_PAMS ) g3 on g1.MPRNo=g3.MPRNo and g1.materialid=g3.materialid
	left join (	select DISTINCT Supplier,PONumber,MaterialID,InvoiceDate,InvoiceNumber from GateEntryScreenDetails_PAMS) G4 ON G1.SUPPLIER=G4.Supplier and g1.PoNumber=g4.PoNumber and g1.MaterialID=g4.MaterialID
	where convert(nvarchar(10),podate,126)>='''+convert(nvarchar(10),@FromDate,126)+''' and convert(nvarchar(10),podate,126)<='''+convert(nvarchar(10),@ToDate,126)+''' and isnull(g1.PoNumber,'''')<>'''' and 1=1 '
	select @StrSQL=@StrSQL+@StrSupplier+@StrPONumber
	print(@strsql)
	exec(@strsql)


	update #Temp set MPRQty=isnull(t1.MPRQty,0),POQty= isnull(t1.poqty,0)
	from
	(
	select distinct supplier,MPRNo,PONumber,MaterialID,sum(orderedqty) as MPRQty,sum(poqty)  as poqty from GeneratePODetails_PAMS where isnull(PONumber,'')<>''
	group by  MPRNo,PONumber,MaterialID,supplier
	) t1 inner join #Temp t2 on t1.Supplier=t2.Supplier and t1.MPRNo=t2.MPRNo and t1.PONumber=t2.PONumber and t1.MaterialID=t2.MaterialID


	update #Temp set ReceivedQty=isnull(t1.ReceivedQty,0)
	from
	(
	select distinct Supplier,PONumber,MaterialID,sum(ReceivedQty) as ReceivedQty from GateEntryScreenDetails_PAMS
	group by Supplier,PONumber,MaterialID
	) t1 inner join #Temp t2 on t1.Supplier=t2.Supplier and  t1.PONumber=t2.PONumber and t1.MaterialID=t2.MaterialID


	update #Temp set RequiredDate=isnull(t1.RequiredDate,'')
	from
	(
	select distinct MPRNo,MaterialID,RequiredDate from MPRDetailsTransaction_PPC_PAMS
	) t1 inner join #Temp t2 on t1.MPRNo=t2.MPRNo and t1.MaterialID=t2.MaterialID 


	select MPRNo,MPRDate,PoNumber,MaterialID ,MaterialDescription ,MPRQty,POQty,RequiredDate ,Supplier ,InvoiceNumber,InvoiceDate,ReceivedQty , case when isnull(POQty,0)>=isnull(ReceivedQty,0) then (POQty-ReceivedQty) else 0 end as Balance,POStatus   from #Temp
	 
	
end
