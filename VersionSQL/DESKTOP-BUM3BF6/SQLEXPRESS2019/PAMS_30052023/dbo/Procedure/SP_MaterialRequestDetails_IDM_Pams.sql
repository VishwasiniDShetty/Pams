/****** Object:  Procedure [dbo].[SP_MaterialRequestDetails_IDM_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

/*
SP_MaterialRequestDetails_IDM_Pams @Fromdate=N'2022-12-28 00:00:00.000',@Todate=N'2023-12-28 00:00:00.000',@RequestFromDepartment=N'',@ItemCategory=N'',@ItemName=N'',@Param=N'MaterialRequestView'
SP_MaterialRequestDetails_IDM_Pams @RequestToDepartment=N'Stores',@ItemCategory=N'''Gauges''',@Param=N'MaterialIssueView'

*/
CREATE procedure [dbo].[SP_MaterialRequestDetails_IDM_Pams]
@RequestFromDepartment nvarchar(2000)='',
@ItemDescription nvarchar(100)='',
@ItemCategory varchar(max)='',
@ItemName nvarchar(50)='',
@RequestedBy nvarchar(50)='',
@RequestedTS datetime='',
@RequestedQty float=0,
@IssuedQty float=0,
@IssuedBy nvarchar(50)='',
@Fromdate datetime='',
@Todate datetime='',
@IssuedLocation nvarchar(50)='',
@Remarks nvarchar(2000)='',
@ApprovedBy nvarchar(50)='',
@AutoID NVARCHAR(MAX)='',
@Param nvarchar(50)='',
@RequestToDepartment nvarchar(50)='',
@IDMType nvarchar(50)='',
@IDMItemType nvarchar(50)='',
@size nvarchar(50)='',
@issuedts datetime='',
@Issuedstatus nvarchar(50)='',
@PartID nvarchar(50)=''
as
begin

create table #IssueData
(
RequestFromDepartment nvarchar(50),
RequestToDepartment nvarchar(50),
ItemCategory nvarchar(50),
IDMType nvarchar(50),
IDMItemType nvarchar(50),
RequestRemarks nvarchar(2000),
RequestedBy nvarchar(50),
RequestedQty float,
RequestedTS datetime,
IssuedQty float,
IssuedTS DATETIME,
IssuedBy nvarchar(50),
IssuedLocation nvarchar(50),
IssueRemarks nvarchar(2000),
IssuedStatus nvarchar(50)
)


declare @StrFromDepartment nvarchar(2000)
declare @StrToDepartment nvarchar(2000)
declare @StrItemCategory nvarchar(max)
declare @StrIDMType nvarchar(max)
declare @StrAutoID nvarchar(max)
declare @StrSql nvarchar(max)

select @StrFromDepartment=''
select @StrToDepartment=''
select @StrItemCategory=''
select @StrIDMType=''
SELECT @StrAutoID=''
select @StrSql=''


IF @Param='MaterialRequestView'
begin
	if isnull(@RequestFromDepartment,'')<>''
	begin
		select @StrFromDepartment='And i1.RequestFromDepartment =N'''+@RequestFromDepartment+''''
	end

	if isnull(@ItemCategory,'')<>''
	begin
		select @StrItemCategory='And i1.ItemCategory =N'''+@ItemCategory+''''
	end

	if isnull(@ItemName,'')<>''
	begin
		select @IDMItemType='And i1.IDMItemType =N'''+@ItemName+''''
	end



		select @StrSql=''
		select @StrSql=@StrSql+'select distinct i1.*,isnull(m2.IssuedQty,''0'') as IssuedQty,IssuedBy,IssuedTS,IssuedLocation,IssuedRemarks,isnull(IssuedStatus,''Pending'')as IssuedStatus,IssuedLocation  from MaterialRequestDetails_IDM_PAMS i1
		left join MaterialIssueDetails_IDM_Pams m2 on i1.RequestFromDepartment=m2.RequestFromDepartment and i1.ItemCategory=m2.ItemCategory and i1.IDMType=m2.IDMType and i1.IDMItemType=m2.IDMItemType and i1.RequestToDepartment=m2.RequestToDepartment and i1.RequestedTS=m2.RequestedTS
		where (convert(nvarchar(10),i1.RequestedTS,126)>='''+convert(nvarchar(10),@Fromdate,126)+'''  and convert(nvarchar(10),i1.requestedts,126)<='''+convert(nvarchar(10),@todate,126)+''') and  1=1 '
		select @StrSql=@StrSql+@StrFromDepartment+@StrItemCategory+@IDMItemType
		print(@strsql)
		exec(@strsql)

END
IF @Param='MaterialRequestSave'
begin
	select @idmtype=''
	select @idmtype=(select distinct idmtype from IDMTypeMaster_IDM_Pams where ItemCategory=@ItemCategory and IDMItemType=@IDMItemType )

	if not exists(select * from MaterialRequestDetails_IDM_PAMS where RequestFromDepartment=@RequestFromDepartment and ItemCategory=@ItemCategory and IDMType=@IDMType and IDMItemType=@IDMItemType and RequestToDepartment=@RequestToDepartment and RequestedTS=@RequestedTS)
	begin
		insert into MaterialRequestDetails_IDM_PAMS(ItemCategory,idmtype,idmitemtype,RequestfromDepartment,RequestToDepartment,RequestedBy,RequestedQty,RequestedTS,size,Remarks,PartID)
		values(@ItemCategory,@idmtype,@idmitemtype,@RequestfromDepartment,@RequestToDepartment,@RequestedBy,@RequestedQty,@RequestedTS,@size,@Remarks,@PartID)
	end
	else
	begin
		update MaterialRequestDetails_IDM_PAMS set RequestedQty=@RequestedQty,size=@size,Remarks=@Remarks
		where RequestFromDepartment=@RequestFromDepartment and ItemCategory=@ItemCategory and IDMType=@IDMType and IDMItemType=@IDMItemType and RequestToDepartment=@RequestToDepartment and RequestedTS=@RequestedTS	
	end
	
end


if @Param='MaterialIssueView'
begin
		if isnull(@RequestToDepartment,'')<>''		
		begin
			select @StrToDepartment='And i1.RequesttoDepartment =N'''+@RequestToDepartment+''' '
		end

		if isnull(@ItemCategory,'')<>''
		begin
			select @StrItemCategory='And i1.ItemCategory in ('+@ItemCategory+')'
		end



		select @StrSql=''
		select @StrSql=@StrSql+'Insert into #IssueData(RequestFromDepartment,RequestToDepartment,ItemCategory,IDMType,IDMItemType,RequestedBy,RequestedQty,RequestedTS,IssuedQty,IssuedTS,IssuedBy,IssuedLocation,
		IssueRemarks,IssuedStatus,RequestRemarks) '
		select @StrSql=@StrSql+'select distinct I1.requestfromdepartment,I1.RequestToDepartment, I1.ItemCategory,i1.IDMType,I1.IDMItemType,I1.RequestedBy,i1.RequestedQty,i1.RequestedTS,m1.IssuedQty,m1.IssuedTS,m1.IssuedBy,M1.IssuedLocation,m1.IssuedRemarks,m1.IssuedStatus,i1.Remarks from MaterialRequestDetails_IDM_PAMS i1
		LEFT JOIN MaterialIssueDetails_IDM_Pams M1 ON I1.RequestfromDEpartment=M1.RequestfromDepartment AND I1.ItemCategory=M1.ItemCategory AND I1.IDMType=M1.IDMType and i1.IDMItemType=m1.IDMItemType and i1.RequesttoDEpartment=m1.RequesttoDEpartment and i1.RequestedTS=m1.RequestedTS
		where 1=1  '
		select @StrSql=@StrSql+@StrToDepartment+@StrItemCategory
		print(@strsql)
		exec(@strsql)


		select RequestFromDepartment,RequestToDepartment,ItemCategory,IDMType,IDMItemType,RequestedBy,isnull(RequestedQty,0) as RequestedQty,RequestedTS,RequestRemarks,isnull(IssuedQty,0) as IssuedQty,
		Case when isnull(IssuedQty,0)< isnull(RequestedQty,0) then isnull(RequestedQty,0)-isnull(IssuedQty,'') else 0 end as PendingQtyToIssue,IssuedTS,IssuedBy,IssuedLocation ,IssueRemarks,IssuedStatus 
		from #IssueData order by RequestedTS desc

end

IF @Param='MaterialIssueSave'
begin
	select @idmtype=''
	select @idmtype=(select distinct idmtype from IDMTypeMaster_IDM_Pams where ItemCategory=@ItemCategory and IDMItemType=@IDMItemType)

	if not exists(select * from MaterialIssueDetails_IDM_Pams where RequestFromDepartment=@RequestFromDepartment and ItemCategory=@ItemCategory and IDMItemType=@ItemName and RequesttoDEpartment=@RequesttoDEpartment and RequestedTS=@RequestedTS and IssuedTS=@issuedts)
	begin
		insert into MaterialIssueDetails_IDM_Pams(ItemCategory,IDMType,IDMItemType,RequestFromDepartment,RequesttoDEpartment,RequestedBy,RequestedQty,RequestedTS,IssuedQty,IssuedBy,IssuedTS,IssuedLocation,IssuedRemarks,Issuedstatus)
		values(@ItemCategory,@IDMType,@IDMItemType,@RequestFromDepartment,@RequesttoDEpartment,@RequestedBy,@RequestedQty,@RequestedTS,@IssuedQty,@IssuedBy,@issuedts,@IssuedLocation,@Remarks,@Issuedstatus)
	end
	else
	begin
		update MaterialIssueDetails_IDM_Pams set IssuedQty=@IssuedQty,IssuedBy=@IssuedBy,IssuedLocation=@IssuedLocation,IssuedRemarks=@Remarks
		where RequestFromDepartment=@RequestFromDepartment and ItemCategory=@ItemCategory and IDMItemType=@ItemName and RequesttoDEpartment=@RequesttoDEpartment and RequestedTS=@RequestedTS and IssuedTS=@issuedts
	end

end
	


end
