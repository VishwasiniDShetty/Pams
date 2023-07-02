/****** Object:  Procedure [dbo].[SP_MaterialRequestDetails_IDM_Pams_old]    Committed by VersionSQL https://www.versionsql.com ******/

/*
SP_MaterialRequestDetails_IDM_Pams_old @Fromdate=N'2022-12-28 00:00:00.000',@Todate=N'2023-12-28 00:00:00.000',@Department=N'',@ItemCategory=N'',@ItemName=N'',@Param=N'MaterialRequestView'
SP_MaterialRequestDetails_IDM_Pams_old @Fromdate=N'2023-02-23 00:00:00.000',@Todate=N'2023-02-28 00:00:00.000', @Department=N'',@ItemCategory=N'',@ItemName=N'',@Param=N'MaterialIssueView'

*/
CREATE procedure [dbo].[SP_MaterialRequestDetails_IDM_Pams_old]
@Department nvarchar(2000)='',
@ItemDescription nvarchar(100)='',
@ItemCategory varchar(max)='',
@ItemName nvarchar(50)='',
@UpdatedBy nvarchar(50)='',
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
@RequestToDepartment nvarchar(50)=''
as
begin

create table #IssueData
(
RequestDepartment nvarchar(50),
ItemCategory nvarchar(50),
ItemName nvarchar(50),
ItemDescription nvarchar(100),
RequestedBy nvarchar(50),
RequestedQty float,
RequestedTS datetime,
AvailableQty float,
IssuedQty float,
IssuedTS DATETIME,
IssuedBy nvarchar(50),
IssuedLocation nvarchar(50),
RequestRemarks nvarchar(2000),
IssueRemarks nvarchar(2000),
RequestToDepartment nvarchar(50)

)


declare @StrDepartment nvarchar(2000)
declare @StrItemCategory nvarchar(max)
declare @StrItemName nvarchar(max)
declare @StrAutoID nvarchar(max)
declare @StrSql nvarchar(max)

select @StrDepartment=''
select @StrItemCategory=''
select @StrItemName=''
SELECT @StrAutoID=''
select @StrSql=''


--IF @Param='MaterialRequestView'
--begin
--	if isnull(@Department,'')<>''
--	begin
--		select @StrDepartment='And i1.RequesttoDepartment in ('+@Department+')'
--	end

--	if isnull(@ItemCategory,'')<>''
--	begin
--		select @StrItemCategory='And i1.ItemCategory in ('+@ItemCategory+')'
--	end

--	if isnull(@ItemName,'')<>''
--	begin
--		select @StrItemName='And i1.itemname like ''%'+@ItemName+'%'' '
--	end



--		select @StrSql=''
--		select @StrSql=@StrSql+'select distinct i1.Autoid, i1.RequestDepartment,I1.ItemCategory,I1.ItemName,I1.ItemDescription,i1.RequestedQty,i1.RequestedTS,i1.Remarks as RequestRemarks,m2.Remarks as IssueRemarks,i1.RequestToDepartment,i2.uom from MaterialRequestDetails_IDM_PAMS i1
--		left join IDMGeneralMaster_PAMS i2 on i1.RequestToDepartment=i2.Department and i1.ItemCategory=i2.ItemCategory and i1.ItemName=i2.itemname
--		left join MaterialIssueDetails_IDM_Pams m2 on i1.RequestDepartment=m2.RequestDepartment and i1.ItemCategory=m2.ItemCategory and i1.ItemName=m2.ItemName and i1.RequestToDepartment=m2.RequestToDepartment and i1.RequestedTS=m2.RequestedTS
--		where (convert(nvarchar(10),i1.RequestedTS,126)>='''+convert(nvarchar(10),@Fromdate,126)+'''  and convert(nvarchar(10),i1.requestedts,126)<='''+convert(nvarchar(10),@todate,126)+''') and  1=1 '
--		select @StrSql=@StrSql+@StrDepartment+@StrItemCategory+@StrItemName
--		print(@strsql)
--		exec(@strsql)


--		--select @StrSql=''
--		--select @StrSql=@StrSql+'select distinct m1.Autoid, I1.Department,I1.ItemCategory,I1.ItemName,I1.ItemDescription,M1.RequestedQty,m1.RequestedTS,m1.Remarks as RequestRemarks,m2.Remarks as IssueRemarks,m1.ApprovedBy,m1.RequestDepartment from IDMGeneralMaster_PAMS i1
--		--LEFT JOIN MaterialRequestDetails_IDM_PAMS M1 ON I1.Department=M1.RequestToDepartment AND I1.ItemCategory=M1.ItemCategory AND I1.ItemName=M1.ItemName
--		--left join MaterialIssueDetails_IDM_Pams m2 on m1.RequestDepartment=m2.RequestDepartment and m1.ItemCategory=m2.ItemCategory and m1.ItemName=m2.ItemName
--		--where (convert(nvarchar(10),m1.RequestedTS,126)>='''+convert(nvarchar(10),@Fromdate,126)+'''  and convert(nvarchar(10),m1.requestedts,126)<='''+convert(nvarchar(10),@todate,126)+''') and  1=1 '
--		--select @StrSql=@StrSql+@StrDepartment+@StrItemCategory+@StrItemName
--		--print(@strsql)
--		--exec(@strsql)

--END
--IF @Param='MaterialRequestSave'
--begin
--	if not exists(select * from MaterialRequestDetails_IDM_PAMS where RequestDepartment=@Department and ItemCategory=@ItemCategory and ItemName=@ItemName and RequestToDepartment=@RequestToDepartment and RequestedTS=@RequestedTS)
--	begin
--		insert into MaterialRequestDetails_IDM_PAMS(RequestDepartment,InchargeName,ItemName,ItemDescription,RequestedQty,RequestedTS,itemCategory,Remarks,RequestToDepartment)
--		values(@Department,@UpdatedBy,@ItemName,@ItemDescription,@RequestedQty,getdate(),@itemCategory,@Remarks,@RequestToDepartment)
--	end
--	else
--	begin
--		update MaterialRequestDetails_IDM_PAMS set RequestedQty=@RequestedQty,Remarks=@Remarks
--		where RequestDepartment=@Department and ItemCategory=@ItemCategory and ItemName=@ItemName and RequestToDepartment=@RequestToDepartment and RequestedTS=@RequestedTS
--	end

--end

--if @Param='MaterialRequestApprove'
--begin

--	IF ISNULL(@AUTOID,'')<>''
--	BEGIN
--		SELECT @StrAutoID='And AutoID IN ('+@AutoID+')'
--	end

--	select @StrSql=''
--	select @StrSql=@StrSql+'Update MaterialRequestDetails_IDM_PAMS set ApprovedBy='''+@ApprovedBy+''' where 1=1 '
--	select @strsql=@StrSql+@StrAutoID
--	print(@strsql)
--	exec(@strsql)

--end

--if @Param='MaterialIssueView'
--begin
--		if isnull(@Department,'')<>''
--		begin
--			select @StrDepartment='And i1.RequesttoDepartment in ('+@Department+')'
--		end

--		if isnull(@ItemCategory,'')<>''
--		begin
--			select @StrItemCategory='And i1.ItemCategory in ('+@ItemCategory+')'
--		end

--		if isnull(@ItemName,'')<>''
--		begin
--			select @StrItemName='And i1.itemname like ''%'+@ItemName+'%'' '
--		end


--		select @StrSql=''
--		select @StrSql=@StrSql+'Insert into #IssueData(RequestDEpartment,ItemCategory,ItemName,ItemDescription,RequestedBy,RequestedQty,RequestedTS,IssuedQty,IssuedTS,IssuedBy,IssuedLocation,RequestRemarks,IssueRemarks,RequestToDepartment) '
--		select @StrSql=@StrSql+'select distinct I1.RequestDEpartment,I1.ItemCategory,I1.ItemName,I1.ItemDescription,I1.InchargeName,i1.RequestedQty,i1.RequestedTS,m1.IssuedQty,m1.IssuedTS,m1.IssuedBy,M1.IssuedLocation,i1.Remarks,m1.remarks,i1.RequestToDepartment from MaterialRequestDetails_IDM_PAMS i1
--		LEFT JOIN MaterialIssueDetails_IDM_Pams M1 ON I1.RequestDEpartment=M1.RequestDepartment AND I1.ItemCategory=M1.ItemCategory AND I1.ItemName=M1.ItemName and i1.RequesttoDEpartment=m1.RequesttoDEpartment and i1.RequestedTS=m1.RequestedTS
--		where (convert(nvarchar(10),i1.RequestedTS,126)>='''+convert(nvarchar(10),@Fromdate,126)+'''  and convert(nvarchar(10),i1.requestedts,126)<='''+convert(nvarchar(10),@todate,126)+''')  '
--		select @StrSql=@StrSql+@StrDepartment+@StrItemCategory+@StrItemName
--		print(@strsql)
--		exec(@strsql)

--		update #IssueData set AvailableQty=isnull(t1.AvailableQty,0)
--		from
--		(
--		select distinct ItemName,(isnull(InwardedQty,0)-isnull(IssuedQty,0)) as AvailableQty from ItemStockDetails_IDM_Pams
--		)
--		t1 inner join #IssueData on t1.ItemName=#IssueData.ItemName

--		select * from #IssueData

--end

--IF @Param='MaterialIssueSave'
--begin
--	if not exists(select * from MaterialIssueDetails_IDM_Pams where RequestDepartment=@Department and ItemCategory=@ItemCategory and ItemName=@ItemName and RequesttoDEpartment=@RequesttoDEpartment and RequestedTS=@RequestedTS)
--	begin
--		if exists(select * from ItemStockDetails_IDM_Pams where ItemName=@ItemName)
--		begin
--			update ItemStockDetails_IDM_Pams set IssuedQty=isnull(IssuedQty,0)+isnull(@IssuedQty,0) WHERE ItemName=@ItemName
--		end
--		insert into MaterialIssueDetails_IDM_Pams(RequestDepartment,InchargeName,itemCategory,ItemName,ItemDescription,RequestedQty,RequestedTS,IssuedQty,IssuedBy,IssuedTS,IssuedLocation,Remarks,RequesttoDEpartment)
--		values(@Department,@UpdatedBy,@itemCategory,@ItemName,@ItemDescription,@RequestedQty,@RequestedTS,@IssuedQty,@IssuedBy,getdate(),@IssuedLocation,@Remarks,@RequesttoDEpartment)
--	end
--	else
--	begin
--		update ItemStockDetails_IDM_Pams set IssuedQty=isnull(IssuedQty,0)+isnull(@IssuedQty,0) WHERE ItemName=@ItemName

--		update MaterialIssueDetails_IDM_Pams set IssuedQty=@IssuedQty,IssuedBy=@IssuedBy,IssuedTS=getdate(),IssuedLocation=@IssuedLocation,Remarks=@Remarks
--		where RequestDepartment=@Department and ItemCategory=@ItemCategory and ItemName=@ItemName and RequesttoDEpartment=@RequesttoDEpartment and RequestedTS=@RequestedTS
--	end

--end
	
end
