/****** Object:  Procedure [dbo].[SP_GeneratePOForSupplier_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

/*
exec SP_GeneratePOForSupplier_PAMS '1','1','1','','','','','','','','View',''
go
exec SP_GeneratePOForSupplier_PAMS '','1','','','','','','','','','View'

exec SP_GeneratePOForSupplier_PAMS '1','p1','''M 1'',''M2''','V1','POGenerated','','GeneratePO'


*/
CREATE procedure [dbo].[SP_GeneratePOForSupplier_PAMS]
@MPRNo nvarchar(100)='',
@PONumber nvarchar(50)='',
@POid nvarchar(50)='',
@MaterialID NVARCHAR(MAX)='',
@Supplier nvarchar(500)='',
@Status nvarchar(100)='',
@Parameter nvarchar(100)='',
@DisplayText nvarchar(2000)='',
@DisplayType nvarchar(100)='',
@Value nvarchar(100)='',
@Param nvarchar(50)='',
@unitrate float=0,
@Remarks nvarchar(2000)='',
@QuotationDate datetime=NULL,
@QuotationRefNo nvarchar(50)='',
@PoDate datetime=null,
@POAddOnID NVARCHAR(50)=''
as
begin
declare @strMaterialID nvarchar(max)
declare @strMprNo nvarchar(max)
declare @strsql nvarchar(max)
select @strMprNo=''
select @strMaterialID=''
select @strsql=''

create table #MPRTemp
(
MPRNo nvarchar(100),
MPRDate datetime,
Materialid nvarchar(50),
MaterialDescription nvarchar(100),
QTY float,
uom nvarchar(100),
Specification nvarchar(100),
unitrate float,
Remarks nvarchar(2000),
QuotationRefNo nvarchar(50),
QuotationDate nvarchar(50),
Total float,
Status nvarchar(50)
)

create table #MPRTemp1
(
MPRNo nvarchar(100),
MPRDate datetime,
PONumber nvarchar(100),
PODate datetime,
POID NVARCHAR(100),
Materialid nvarchar(50),
MaterialDescription nvarchar(100),
QTY float,
uom nvarchar(100),
Specification nvarchar(100),
unitrate float,
Remarks nvarchar(2000),
QuotationRefNo nvarchar(50),
QuotationDate nvarchar(50),
Total float,
Status nvarchar(50)

)

if isnull(@QuotationDate,'')=''
begin
	set  @QuotationDate=null
end


if isnull(@Param,'')='View'
begin
	if isnull(@MPRNo,'')<>''
	begin

		if isnull(@MPRNo,'')<>''
		begin
			set @strMprNo= ' and r1.mprno = N'''+@MPRNo+''''
		end


		if isnull(@MaterialID,'')<>''
		begin
			set @strMaterialID= ' and r1.MaterialID in ('+@MaterialID+')'
		end
			select @strsql=''
			select @strsql='select distinct r1.Supplierid,v1.Suppliername,v1.address,v1.contactnumber,v1.state,v1.country,v1.pin,v1.email,v1.contactperson,v1.GSTNumber,v1.PanNumber from RawMaterialAndSupplierAssociation_PAMS r1
			inner join SupplierDetails_PAMS v1 on r1.supplierid=v1.supplierid
			inner join RawMaterialDetails_PAMS r2 on r2.materialid=r1.materialid where 1=1 and v1.approval=''Ok'' and Isactive=1 '
			select @strsql=@strsql+@strMaterialID
			print(@strsql)
			exec(@strsql)

			select @strsql=''
			select @strsql=@strsql+'Insert into #MPRTemp(MPRNo,Materialid,QTY) '
			select @strsql=@strsql+'select distinct r1.MPRNo,r1.Materialid,sum(r1.poqty) as QTY from GeneratePODetails_PAMS r1 
			left join RawMaterialDetails_PAMS r2 on r1.materialid=r2.materialid where 1=1 and isnull(ponumber,'''')='''' '
			select @strsql=@strsql+@strMprNo+@strMaterialID
			select @strsql= @strsql+' group by r1.Materialid,r1.MPRNo '
			print(@strsql)
			exec(@strsql)

			update #MPRTemp set MPRDate=(t1.mprdate)
			from
			(select distinct mprno,mprdate from MPRDetailsTransaction_PPC_PAMS
			) t1 inner join #MPRTemp on #MPRTemp.MPRNo=t1.MPRNo

			select @strsql=''
			select @strsql=@strsql+'update #MPRTemp set Specification=(t1.specification), uom=(t1.uom),MaterialDescription=isnull(t1.MaterialDescription,'''') from ( '
			select @strsql=@strsql+'select distinct materialid,uom,MaterialDescription,specification from RawMaterialDetails_PAMS r1 where 1=1 '
			select @strsql=@strsql+@strMaterialID
			select @strsql=@strsql+')t1 inner join #MPRTemp on #MPRTemp.Materialid=t1.Materialid '
			print(@strsql)
			exec(@strsql)

			update #MPRTemp set unitrate=(t1.unitrate),Remarks=(t1.Remarks),QuotationDate=isnull(t1.QuotationDate,''),QuotationRefNo=(t1.QuotationRefNo)
			from
			(
			select distinct MPRNo,materialid,isnull(ponumber,'') as ponumber,unitrate ,Remarks,QuotationDate,QuotationRefNo from GeneratePODetails_PAMS
			) t1 inner join #MPRTemp1 t2 on t1.MPRNo=t2.MPRNo and t1.MaterialID=t2.Materialid and isnull(t1.PONumber,'')=isnull(t2.PONumber,'')

			update #MPRTemp set Total=case when isnull(unitrate,0)>0 then qty*unitrate else qty end

			select DISTINCT MPRNo,MPRDate,'' as PONumber,'' as POID,'' as podate,Materialid,MaterialDescription, qty,uom,unitrate,total,status,Remarks,QuotationDate,QuotationRefNo,Specification from #MPRTemp


			select Parameter,DisplayText,DisplayType,SortOrder,'' as Value from ValidationDetails_PAMS
			order by SortOrder
	end

	if isnull(@PONumber,'')<>''
	begin

		select distinct r1.Supplier AS SupplierID,v1.SupplierName,v1.address,v1.contactnumber,v1.state,v1.country,v1.pin,v1.email,v1.contactperson,v1.GSTNumber,v1.PanNumber from GeneratePODetails_PAMS r1
		inner join SupplierDetails_PAMS v1 on r1.Supplier=v1.SupplierID
		WHERE R1.PONumber=@PONumber

		Insert into #MPRTemp1(MPRNo,PONumber,POID,PODate,Materialid,QTY) 
		select distinct Mprno,@PONumber,r1.poid,r1.PODate,r1.Materialid,sum(r1.poqty) as QTY from GeneratePODetails_PAMS r1 
		left join RawMaterialDetails_PAMS r2 on r1.materialid=r2.materialid 
		where 1=1  and r1.ponumber=@PONumber 
		group by r1.Materialid,r1.PODate,r1.POId,r1.MPRNo 


		update #MPRTemp1 set Specification=(t1.Specification),uom=(t1.uom),MaterialDescription=isnull(t1.MaterialDescription,'') from
		( 
		select distinct materialid,uom,MaterialDescription,Specification from RawMaterialDetails_PAMS r1 
		where 1=1  
		)t1 inner join #MPRTemp1 on #MPRTemp1.Materialid=t1.Materialid 

		update #MPRTemp1 set status=(t1.sts)
		from
		(select distinct PONumber, status as sts from GeneratePODetails_PAMS where PONumber=@PONumber
		) t1 inner join #MPRTemp1 on #MPRTemp1.PONumber=T1.PONumber

		update #MPRTemp1 set MPRDate=(t1.mprdate)
		from
		(select distinct mprno,mprdate from MPRDetailsTransaction_PPC_PAMS
		) t1 inner join #MPRTemp1 on #MPRTemp1.MPRNo=t1.MPRNo

		update #MPRTemp1 set unitrate=(t1.unitrate),Remarks=(t1.Remarks),QuotationDate=(t1.QuotationDate),QuotationRefNo=(t1.QuotationRefNo)
		from
		(
		select distinct MPRNo,materialid,ponumber,unitrate ,Remarks,QuotationDate,QuotationRefNo from GeneratePODetails_PAMS
		) t1 inner join #MPRTemp1 t2 on t1.MPRNo=t2.MPRNo and t1.MaterialID=t2.Materialid and t1.PONumber=t2.PONumber

		update #MPRTemp1 set Total=case when isnull(unitrate,0)>0 then qty*unitrate else qty end


		select DISTINCT MPRNo,MPRDate,PONumber,POID,podate,Materialid,MaterialDescription,qty,uom,unitrate,total,status,Remarks,QuotationDate,QuotationRefNo,Specification from #MPRTemp1

		select p1.Parameter,p1.DisplayText,v1.DisplayType,v1.sortorder,Value from PODetailsTransactionSave_PAMS p1
		left join ValidationDetails_PAMS v1 on p1.Parameter=v1.Parameter and p1.DisplayText=v1.DisplayText
		where PONumber=@PONumber
		order by SortOrder
	end

end

if isnull(@Param,'')='GeneratePOTransactions'
begin

	if isnull(@MPRNo,'')<>''
	begin
		set @strMprNo= ' and mprno =N'''+@MPRNo+''''
	end


	if isnull(@MaterialID,'')<>''
	begin
		set @strMaterialID= ' and MaterialID in ('+@MaterialID+')'
	end

	update GeneratePODetails_PAMS set  unitrate=@unitrate,Remarks=@Remarks,QuotationRefNo=@QuotationRefNo,
	QuotationDate=@QuotationDate,supplier=@Supplier,PONumber=@PONumber,POId=@POid,POAddOnID=@POAddOnID,Status=@Status,PODate=@PoDate where MPRNo=@MPRNo and MaterialID=@MaterialID  and  ISNULL(PONUMBER,'')=''


	--SELECT @strsql=''
	--SELECT @strsql=@strsql+'Update GeneratePODetails_PAMS set supplier='''+@Supplier+''',ponumber='''+@ponumber+''',POID='''+@POid+''',status='''+@status+''',podate='''+convert(nvarchar(20),@PoDate,120)+''' '
	--SELECT @strsql=@strsql+'WHERE ISNULL(PONUMBER,'''')='''' AND 1=1 '
	--SELECT @strsql=@strsql+@strMprNo+@strMaterialID
	--PRINT(@strsql)
	--exec(@strsql)

end

if isnull(@Param,'')='TermsAndConditionsSave'
begin
	if not exists(select * from PODetailsTransactionSave_PAMS where PONumber=@PONumber and Parameter=@Parameter and DisplayText=@DisplayText)
	begin
		insert into PODetailsTransactionSave_PAMS(PONumber,parameter,displaytext,DisplayType,value)
		values(@PONumber,@Parameter,@DisplayText,@DisplayType,@Value)
	end
	else
	begin
		update PODetailsTransactionSave_PAMS set value=@value
		where PONumber=@PONumber and Parameter=@Parameter and DisplayText=@DisplayText
	end


end

	if @Param='SaveAfterGeneratePO'
	BEGIN
			update GeneratePODetails_PAMS set  unitrate=@unitrate,Remarks=@Remarks,QuotationRefNo=@QuotationRefNo,
			QuotationDate=@QuotationDate where MaterialID=@MaterialID AND  PONumber=@PONumber

	END



end
