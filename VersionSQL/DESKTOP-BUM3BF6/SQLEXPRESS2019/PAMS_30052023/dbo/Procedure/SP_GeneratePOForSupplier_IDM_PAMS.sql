/****** Object:  Procedure [dbo].[SP_GeneratePOForSupplier_IDM_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

/*
exec SP_GeneratePOForSupplier_IDM_PAMS '1','1','1','''M 1'',''M2''','','','','','','','View',''
go
exec SP_GeneratePOForSupplier_IDM_PAMS '','1','','','','','','','','','View'

exec SP_GeneratePOForSupplier_IDM_PAMS '1','p1','''M 1'',''M2''','V1','POGenerated','','GeneratePO'


*/
CREATE procedure [dbo].[SP_GeneratePOForSupplier_IDM_PAMS]
@MPRNo nvarchar(100)='',
@PONumber nvarchar(50)='',
@POid nvarchar(50)='',
@ItemName NVARCHAR(MAX)='',
@ItemCategory nvarchar(50)='',
@department nvarchar(50)='',
@Supplier nvarchar(500)='',
@Status nvarchar(100)='',
@Parameter nvarchar(100)='',
@DisplayText nvarchar(2000)='',
@DisplayType nvarchar(100)='',
@Value nvarchar(100)='',
@Param nvarchar(50)='',
@unitrate float=0,
@Remarks nvarchar(2000)='',
@QuotationDate datetime=null,
@QuotationRefNo nvarchar(50)='',
@PoDate datetime=null
as
begin
declare @strItemName nvarchar(max)
declare @StrDepartmentName nvarchar(max)
declare @strMprNo nvarchar(max)
declare @strItemCategory nvarchar(2000)
declare @strsql nvarchar(max)
select @strMprNo=''
select @strItemName=''
select @StrDepartmentName=''
select @strsql=''
select @strItemCategory=''

create table #MPRTemp
(
MPRNo nvarchar(100),
MPRDate datetime,
ItemName nvarchar(50),
Department nvarchar(50),
ItemCategory nvarchar(50),
QTY float,
uom nvarchar(100),
unitrate float,
Remarks nvarchar(50),
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
ItemName nvarchar(50),
Department nvarchar(50),
ItemCategory nvarchar(50),
QTY float,
uom nvarchar(100),
unitrate float,
Remarks nvarchar(50),
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
			set @strMprNo= ' and r1.mprno =N'''+@MPRNo+''''
		end


		if isnull(@ItemName,'')<>''
		begin
			set @strItemName= ' and r1.ItemName in ('+@ItemName+')'
		end

		--if isnull(@department,'')<>''
		--begin
		--	select @StrDepartmentName='And r1.department IN ('+@department+')'
		--END

		--if isnull(@ItemCategory,'')<>''
		--begin
		--	select @strItemCategory='And r1.ItemCategory in ('+@ItemCategory+')'
		--end

			select @strsql=''
			select @strsql='select distinct r1.Supplierid,r1.Suppliername,r1.address,r1.contactnumber,r1.state,r1.country,r1.pin,r1.email,r1.contactperson,r1.gstnumber,r1.pannumber from SupplierDetails_PAMS r1 where SupplierType=''IDM'' and isnull(approval,''NotOk'')=''Ok'' and isactive=1 '
			select @strsql=@strsql
			print(@strsql)
			exec(@strsql)


			select @strsql=''
			select @strsql=@strsql+'Insert into #MPRTemp(MPRNo,ItemName,QTY) '
			select @strsql=@strsql+'select distinct r1.MPRNo,r1.ItemName,sum(r1.poqty) as QTY from GeneratePODetails_IDM_PAMS r1 
			left join IDMGeneralMaster_PAMS r2 on r1.Itemname=r2.Itemname  where 1=1 and isnull(ponumber,'''')='''' '
			select @strsql=@strsql+@strMprNo+@strItemName
			select @strsql= @strsql+' group by r1.MPRNo,r1.ItemName'
			print(@strsql)
			exec(@strsql)

			update #MPRTemp set MPRDate=(t1.mprdate)
			from
			(select distinct mprno,mprdate from MPRDetailsTransaction_PPC_PAMS
			) t1 inner join #MPRTemp on #MPRTemp.MPRNo=t1.MPRNo

			select @strsql=''
			select @strsql=@strsql+'update #MPRTemp set uom=(t1.uom) from ( '
			select @strsql=@strsql+'select distinct ItemName,uom from IDMGeneralMaster_PAMS r1 where 1=1 '
			select @strsql=@strsql+@strItemName
			select @strsql=@strsql+')t1 inner join #MPRTemp on #MPRTemp.ItemName=t1.ItemName '
			print(@strsql)
			exec(@strsql)

			update #MPRTemp set unitrate=(t1.unitrate),Remarks=(t1.Remarks),QuotationDate=isnull(t1.QuotationDate,''),QuotationRefNo=(t1.QuotationRefNo)
			from
			(
			select distinct MPRNo,ItemName,isnull(ponumber,'') as ponumber,unitrate ,Remarks,QuotationDate,QuotationRefNo from GeneratePODetails_IDM_PAMS
			) t1 inner join #MPRTemp1 t2 on t1.MPRNo=t2.MPRNo and t1.ItemName=t2.ItemName and isnull(t1.PONumber,'')=isnull(t2.PONumber,'')


			update #MPRTemp set Total=case when isnull(unitrate,0)>0 then qty*unitrate else qty end

			select DISTINCT m1.MPRNo,m1.MPRDate,'' as PONumber,'' as POID,'' as podate,m1.ItemName,m2.ItemDescription,m1.qty,m1.uom,unitrate,total,status,Remarks,QuotationDate,QuotationRefNo from #MPRTemp m1
			left join (select distinct itemname,ItemDescription from IDMGeneralMaster_PAMS i1 ) m2 on m1.ItemName=m2.ItemName


			select Parameter,DisplayText,DisplayType,SortOrder,'' as Value from ValidationDetails_PAMS
			order by SortOrder
	end

	if isnull(@PONumber,'')<>''
	begin

		select distinct r1.Supplier AS SupplierID,v1.SupplierName,v1.address,v1.contactnumber,v1.state,v1.country,v1.pin,v1.email,v1.contactperson,v1.GSTNumber,v1.PanNumber from GeneratePODetails_IDM_PAMS r1
		inner join SupplierDetails_PAMS v1 on r1.Supplier=v1.SupplierID
		WHERE R1.PONumber=@PONumber

		Insert into #MPRTemp1(MPRNo,PONumber,POID,PODate,ItemName,Department,ItemCategory,QTY) 
		select distinct Mprno,@PONumber,r1.poid,r1.PODate,r1.ItemName,r1.Department,r1.ItemCategory, sum(r1.poqty) as QTY from GeneratePODetails_IDM_PAMS r1 
		left join IDMGeneralMaster_PAMS r2 on r1.ItemName=r2.ItemName and r1.Department=r2.Department and r1.ItemCategory=r2.ItemCategory 
		where 1=1  and r1.ponumber=@PONumber 
		group by r1.ItemName,r1.Department,r1.ItemCategory,r1.PODate,r1.POId,r1.MPRNo 


		update #MPRTemp1 set uom=(t1.uom) from
		( 
		select distinct ItemName,uom from IDMGeneralMaster_PAMS r1 
		where 1=1  
		)t1 inner join #MPRTemp1 on #MPRTemp1.ItemName=t1.ItemName 

		update #MPRTemp1 set unitrate=(t1.unitrate),Remarks=(t1.Remarks),QuotationDate=(t1.QuotationDate),QuotationRefNo=(t1.QuotationRefNo)
		from
		(
		select distinct MPRNo,ItemName,ponumber,unitrate ,Remarks,QuotationDate,QuotationRefNo from GeneratePODetails_IDM_PAMS
		) t1 inner join #MPRTemp1 t2 on t1.MPRNo=t2.MPRNo and t1.ItemName=t2.ItemName and t1.PONumber=t2.PONumber


		update #MPRTemp1 set Total=case when isnull(unitrate,0)>0 then qty*unitrate else qty end

		update #MPRTemp1 set status=(t1.sts)
		from
		(select distinct PONumber, status as sts from GeneratePODetails_IDM_PAMS where PONumber=@PONumber
		) t1 inner join #MPRTemp1 on #MPRTemp1.PONumber=T1.PONumber

		update #MPRTemp1 set MPRDate=(t1.mprdate)
		from
		(select distinct mprno,mprdate from MPRDetailsTransaction_PPC_IDM_PAMS
		) t1 inner join #MPRTemp1 on #MPRTemp1.MPRNo=t1.MPRNo


		select DISTINCT m1.MPRNo,m1.MPRDate,m1.PONumber,m1.POID,m1.podate,m1.ItemName,m2.ItemDescription,m1.qty,m1.uom,unitrate,total,status,Remarks,QuotationDate,QuotationRefNo from #MPRTemp1 m1
		left join (select distinct itemname,ItemDescription from IDMGeneralMaster_PAMS i1 ) m2 on m1.ItemName=m2.ItemName


		select p1.Parameter,p1.DisplayText,v1.DisplayType,v1.sortorder,Value from PODetailsTransactionSave_IDM_PAMS p1
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


	if isnull(@ItemName,'')<>''
	begin
		set @strItemName= ' and ItemName in ('+@ItemName+')'
	end

	--if isnull(@department,'')<>''
	--begin
	--	select @StrDepartmentName='And department IN ('+@department+')'
	--END

	--if isnull(@ItemCategory,'')<>''
	--begin
	--	select @strItemCategory='And ItemCategory in ('+@ItemCategory+')'
	--end
	update GeneratePODetails_IDM_PAMS set unitrate=@unitrate,Remarks=@Remarks,QuotationRefNo=@QuotationRefNo,
	QuotationDate=@QuotationDate,Supplier=@Supplier,PONumber=@PONumber,POId=@POid,Status=@Status,PODate=@PoDate
	where MPRNo=@MPRNo and ItemName=@ItemName and  ISNULL(PONUMBER,'')=''

	--SELECT @strsql=''
	--SELECT @strsql=@strsql+'Update GeneratePODetails_IDM_PAMS set  supplier='''+@Supplier+''',ponumber='''+@ponumber+''',POID='''+@POid+''',status='''+@status+''',podate='''+convert(nvarchar(20),@PoDate,120)+''' '
	--SELECT @strsql=@strsql+'WHERE ISNULL(PONUMBER,'''')='''' AND 1=1 '
	--SELECT @strsql=@strsql+@strMprNo+@strItemName
	--PRINT(@strsql)
	--exec(@strsql)

end

	if isnull(@Param,'')='TermsAndConditionsSave'
	begin
		if not exists(select * from PODetailsTransactionSave_IDM_PAMS where PONumber=@PONumber and Parameter=@Parameter and DisplayText=@DisplayText)
		begin
			insert into PODetailsTransactionSave_IDM_PAMS(PONumber,parameter,displaytext,DisplayType,value)
			values(@PONumber,@Parameter,@DisplayText,@DisplayType,@Value)
		end
		else
		begin
			update PODetailsTransactionSave_IDM_PAMS set value=@value
			where PONumber=@PONumber and Parameter=@Parameter and DisplayText=@DisplayText
		end


	END


	if @Param='SaveAfterGeneratePO'
	BEGIN

			update GeneratePODetails_IDM_PAMS set  unitrate=@unitrate,Remarks=@Remarks,QuotationRefNo=@QuotationRefNo,
			QuotationDate=@QuotationDate where ItemName=@ItemName AND PONumber=@PONumber

	END




end
