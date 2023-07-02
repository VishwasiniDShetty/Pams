/****** Object:  Procedure [dbo].[SP_RequestDetailsSaveAndView_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

/*
SP_RequestDetailsSaveAndView_Pams @Vendor=N'',@Department=N'',@FromDate=N'2022-01-01',@ToDate=N'2023-12-01', @Param=N'StoresView'
SP_RequestDetailsSaveAndView_Pams @Vendor=N'''C 3001''',@Department=N'''Management''', @Param=N'EditView'

*/
CREATE procedure [dbo].[SP_RequestDetailsSaveAndView_Pams]
@Department nvarchar(max)='',
@Vendor nvarchar(2000)='',
@Process nvarchar(2000)='',
@MaterialID NVARCHAR(50)='',
@PartID NVARCHAR(50)='',
@RequestedID INT=0,
@RequestedNo nvarchar(50)='',
@RequestedQty float=0,
@RequestedBy nvarchar(50)='',
@RequestedTS DATETIME='',
@ApprovedBy nvarchar(50)='',
@ApprovedTS DATETIME='',
@Status nvarchar(50)='',
@FromDate datetime='',
@ToDate datetime='',
@Param nvarchar(50)='',
@Remarks nvarchar(2000)='',
@uom nvarchar(50)='',
@HoldRemarks nvarchar(2000)='',
@RequestStatus nvarchar(2000)='',
@AutoID nvarchar(50)='',
@ReworkQty float=0,
@MJCNo nvarchar(50)='',
@PJCNo nvarchar(50)=''
as
begin
	declare @StrSql nvarchar(max)
	declare @StrVendor nvarchar(2000)
	declare @StrDepartment nvarchar(max)
	declare @StrRequest nvarchar(max)

	select  @StrSql=''
	select @StrVendor=''
	select @StrDepartment=''

	if isnull(@vendor,'')<>''
	begin
		select @StrVendor='And R1.Vendor in ('+@Vendor+')'
	end

	
	if isnull(@Department,'')<>''
	begin
		select @StrDepartment='And R1.Department in ('+@Department+')'
	end


		if isnull(@RequestStatus,'')<>''
	begin
		select @StrRequest='And R1.status in ('+@RequestStatus+')'
	end
	create table #Temp
	(
	AutoID INT,
	Department nvarchar(50),
	Vendor nvarchar(50),
	Process nvarchar(50),
	MaterialID NVARCHAR(50),
	PartID NVARCHAR(50),
	RquestedID INT,
	RequestedNo nvarchar(50),
	RequestedQty float,
	IssuedQty_KG float default 0,
	IssuedQty_No float default 0,
	PendingQty float default 0,
	RequestedBy nvarchar(50),
	RequestedTS DATETIME,
	ApprovedBy nvarchar(50),
	ApprovedTS DATETIME,
	Status nvarchar(50),
	Remarks nvarchar(2000),
	UOM NVARCHAR(50),
	HoldRemarks nvarchar(2000),
	IssuedBit nvarchar(50),
	PartDescription nvarchar(2000),
	ClosedRemarks nvarchar(2000),
	MJCNo nvarchar(50),
	PJCNo nvarchar(50),
	ReworkQty float default 0
	)



	if @param='View'
	begin


		select @strsql=''
		select @strsql=@strsql+'select r1.*,isnull(t1.IssuedBit,''0'') as IssuedBit, f1.PartDescription from RequestDetails_Pams r1 left join (select distinct vendor,process,MaterialID,PartID,MaterialRequestNo,''1'' as IssuedBit from DCNoGeneration_PAMS) t1 on r1.vendor=t1.vendor
		and r1.process=t1.process and r1.MaterialID=t1.MaterialID and r1.PartID=t1.PartID and r1.RequestedNo=t1.MaterialRequestNo left join FGDetails_PAMS f1 on r1.PartID=f1.PartID where (convert(nvarchar(10),r1.RequestedTS,126)>='''+convert(nvarchar(10),@FromDate,126)+''' and convert(nvarchar(10),r1.RequestedTS,126)<='''+convert(nvarchar(10),@ToDate,126)+''') and  1=1 '
		select @StrSql=@StrSql+@StrVendor+@StrDepartment
		select @StrSql=@StrSql+'Order by r1.RquestedID desc '
		print(@strsql)
		exec(@strsql)

		--select @strsql=''
		--select @StrSql=@StrSql+'Insert into #Temp(AutoID,Department,Vendor,Process,MaterialID,PartID ,RquestedID,RequestedNo,RequestedQty,RequestedBy,
		--RequestedTS,ApprovedBy,ApprovedTS,Status,Remarks,UOM,HoldRemarks,IssuedBit,PartDescription ) '
		--select @strsql=@strsql+'select r1.*,isnull(t1.IssuedBit,''0'') as IssuedBit, f1.PartDescription from RequestDetails_Pams r1 left join (select distinct vendor,process,MaterialID,PartID,MaterialRequestNo,''1'' as IssuedBit from DCNoGeneration_PAMS) t1 on r1.vendor=t1.vendor
		--and r1.process=t1.process and r1.MaterialID=t1.MaterialID and r1.PartID=t1.PartID and r1.RequestedNo=t1.MaterialRequestNo left join FGDetails_PAMS f1 on r1.PartID=f1.PartID where (convert(nvarchar(10),r1.RequestedTS,126)>='''+convert(nvarchar(10),@FromDate,126)+''' and convert(nvarchar(10),r1.RequestedTS,126)<='''+convert(nvarchar(10),@ToDate,126)+''') and  1=1 '
		--select @StrSql=@StrSql+@StrVendor+@StrDepartment
		--select @StrSql=@StrSql+'Order by r1.RquestedID desc '
		--print(@strsql)
		--exec(@strsql)

		--update #Temp set IssuedQty_KG=isnull(t1.Qty_KG,0),IssuedQty_No=isnull(t1.Qty_Numbers,0)
		--from
		--(
		--	select distinct MaterialRequestNo,Vendor,Process,MaterialID,PartID,sum(qty_kg) as Qty_KG,SUM(Qty_Numbers) AS Qty_Numbers from DCNoGeneration_PAMS
		--	group by MaterialRequestNo,Vendor,Process,MaterialID,PartID
		--) t1 inner join #Temp t2 on t1.MaterialRequestNo=t2.RequestedNo and t1.Vendor=t2.Vendor and t1.Process=t2.Process and t1.MaterialID=t2.MaterialID and t1.PartID=t2.PartID
		
		--select AutoID,Department,Vendor,Process,MaterialID,PartID,RquestedID,RequestedNo,uom, RequestedQty,IssuedQty_KG,IssuedQty_No,case when UOM='NO.' then (isnull(RequestedQty,0)-isnull(IssuedQty_No,0))
		--when UOM='Kg'then (isnull(RequestedQty,0)-isnull(IssuedQty_KG,0)) else 0 end as PendingQty,RequestedBy ,
		--RequestedTS,ApprovedBy ,ApprovedTS,Status ,Remarks  ,HoldRemarks ,IssuedBit ,PartDescription  from #Temp
	end

	if @Param='EditView'
	begin
		select r1.* , f1.PartDescription from  RequestDetails_Pams r1 left join FGDetails_PAMS f1 on r1.PartID=f1.PartID    where RequestedNo=@RequestedNo
	end

	if @Param='Save'
	begin
		if (isnull(@MJCNo,'')<>'' and isnull(@PJCNo,'')='')
		BEGIN
			SELECT @PJCNo=(select top(1) PJCNo from ProcessJobCardHeaderCreation_PAMS where MJCNo=@MJCNo and PartID=@PartID)
		end

		if (isnull(@PJCNo,'')<>'' and isnull(@MJCNo,'')='')
		BEGIN
			SELECT @MJCNo=(select top(1)  MJCNo from ProcessJobCardHeaderCreation_PAMS where PJCNo=@PJCNo)
		end


		if not exists(select * from RequestDetails_Pams where vendor=@Vendor and process=@Process and MaterialID=@MaterialID AND PartID=@PartID AND Department=@Department and RequestedNo=@RequestedNo)
		begin
			insert into RequestDetails_Pams(Department,vendor,process,MaterialID,PartID,RquestedID,RequestedQty,RequestedNo,RequestedBy,RequestedTS,Remarks,uom,MJCNo,PJCNo,ReworkQty)
			VALUES(@Department,@vendor,@process,@MaterialID,@PartID,@RequestedID,@RequestedQty,@RequestedNo,@RequestedBy,@RequestedTS,@Remarks,@uom,@MJCNo,@PJCNo,@ReworkQty)
		END
		ELSE
		BEGIN
			UPDATE RequestDetails_Pams SET RequestedQty=@RequestedQty,RequestedBy=@RequestedBy,RequestedTS=@RequestedTS,Remarks=@Remarks,uom=@uom,ReworkQty=@ReworkQty
			where vendor=@Vendor and process=@Process and MaterialID=@MaterialID AND PartID=@PartID AND Department=@Department and RequestedNo=@RequestedNo
		end
	end

	if @Param='StoresView'
	begin

		insert into #Temp(AutoID, Department,Vendor,Process,MaterialID,PartID,RquestedID,RequestedQty,RequestedNo,RequestedBy,RequestedTS,ApprovedBy,ApprovedTS,Status,Remarks,UOM,HoldRemarks,ClosedRemarks,MJCNo,
	PJCNo,ReworkQty)
		select r1.AutoID,r1.Department,r1.vendor,r1.process,r1.MaterialID,r1.PartID,r1.RquestedID,r1.RequestedQty,r1.RequestedNo,r1.RequestedBy,r1.RequestedTS,r1.ApprovedBy,r1.ApprovedTS,isnull(r1.Status,'') as Status,r1.Remarks,r1.uom,r1.HoldRemarks,r1.ClosedRemarks,r1.MJCNo,
	r1.PJCNo,r1.ReworkQty from RequestDetails_Pams r1 
		where  (convert(nvarchar(10),r1.RequestedTS,126)>=convert(nvarchar(10),@FromDate,126) and convert(nvarchar(10),r1.RequestedTS,126)<=convert(nvarchar(10),@ToDate,126))
		
		update #Temp set IssuedQty_KG=isnull(t1.Qty_KG,0),IssuedQty_No=isnull(t1.Qty_Numbers,0)
		from
		(
		select distinct MaterialRequestNo,Vendor,Process,MaterialID,PartID,sum(qty_kg) as Qty_KG,SUM(Qty_Numbers) AS Qty_Numbers from DCNoGeneration_PAMS
		group by MaterialRequestNo,Vendor,Process,MaterialID,PartID
		) t1 inner join #Temp t2 on t1.MaterialRequestNo=t2.RequestedNo and t1.Vendor=t2.Vendor and t1.Process=t2.Process and t1.MaterialID=t2.MaterialID and t1.PartID=t2.PartID


		if isnull(@RequestStatus,'')='Open'
		begin
			select r1.AutoID,r1.Department,r1.vendor,r1.process,r1.MaterialID,r1.PartID,r1.RquestedID,r1.RequestedQty,IssuedQty_KG,IssuedQty_No,case when (UOM='NO.' and isnull(RequestedQty,0)> isnull(IssuedQty_No,0)) then (isnull(RequestedQty,0)-isnull(IssuedQty_No,0))
			when (UOM='Kg' and isnull(RequestedQty,0)>isnull(IssuedQty_KG,0)) then (isnull(RequestedQty,0)-isnull(IssuedQty_KG,0)) else 0 end as PendingQty,r1.RequestedNo,r1.RequestedBy,r1.RequestedTS,r1.ApprovedBy,r1.ApprovedTS,isnull(r1.Status,'') as Status,r1.Remarks,r1.uom,r1.HoldRemarks,r1.ClosedRemarks,r1.MJCNo,r1.PJCNo,isnull(r1.ReworkQty,0) as ReworkQty
			from #Temp r1 where isnull(r1.status,'')<>'Closed'		
			order by RquestedID desc
		end

		else if isnull(@RequestStatus,'')='Close'
		begin
			select r1.AutoID,r1.Department,r1.vendor,r1.process,r1.MaterialID,r1.PartID,r1.RquestedID,r1.RequestedQty,IssuedQty_KG,IssuedQty_No,case when (UOM='NO.' and isnull(RequestedQty,0)> isnull(IssuedQty_No,0)) then (isnull(RequestedQty,0)-isnull(IssuedQty_No,0))
			when (UOM='Kg' and isnull(RequestedQty,0)>isnull(IssuedQty_KG,0)) then (isnull(RequestedQty,0)-isnull(IssuedQty_KG,0)) else 0 end as PendingQty,r1.RequestedNo,r1.RequestedBy,r1.RequestedTS,r1.ApprovedBy,r1.ApprovedTS,isnull(r1.Status,'') as Status,r1.Remarks,r1.uom,r1.HoldRemarks,r1.ClosedRemarks,r1.MJCNo,r1.PJCNo,isnull(r1.ReworkQty,0) as ReworkQty
			from #Temp r1 where isnull(r1.status,'')='Closed'		
			order by RquestedID desc
		end
		else
		begin
			select r1.AutoID,r1.Department,r1.vendor,r1.process,r1.MaterialID,r1.PartID,r1.RquestedID,r1.RequestedQty,IssuedQty_KG,IssuedQty_No,case when (UOM='NO.' and isnull(RequestedQty,0)> isnull(IssuedQty_No,0)) then (isnull(RequestedQty,0)-isnull(IssuedQty_No,0))
			when (UOM='Kg' and isnull(RequestedQty,0)>isnull(IssuedQty_KG,0)) then (isnull(RequestedQty,0)-isnull(IssuedQty_KG,0)) else 0 end as PendingQty,r1.RequestedNo,r1.RequestedBy,r1.RequestedTS,r1.ApprovedBy,r1.ApprovedTS,isnull(r1.Status,'') as Status,r1.Remarks,r1.uom,r1.HoldRemarks,r1.ClosedRemarks,r1.MJCNo,r1.PJCNo,isnull(r1.ReworkQty,0) as ReworkQty
			from #Temp r1	
			order by RquestedID desc
		end
	end

		--(R1.status IN (SELECT ITEM FROM SplitString(@RequestStatus,',')) OR  isnull(@RequestStatus,'')='') 

		--select r1.Department,r1.vendor,r1.process,r1.MaterialID,r1.PartID,r1.RquestedID,r1.RequestedQty,r1.RequestedNo,r1.RequestedBy,r1.RequestedTS,r1.ApprovedBy,r1.ApprovedTS,isnull(r1.Status,'') as Status,r1.Remarks,r1.uom,r1.HoldRemarks from RequestDetails_Pams r1 
		--where  (convert(nvarchar(10),r1.RequestedTS,126)>=convert(nvarchar(10),@FromDate,126) and convert(nvarchar(10),r1.RequestedTS,126)<=convert(nvarchar(10),@ToDate,126))
		--and not exists(select distinct vendor,process,MaterialID,PartID from DCNoGeneration_PAMS T1 WHERE T1.Vendor=R1.Vendor and t1.Process=r1.Process and t1.MaterialID=r1.MaterialID and t1.PartID=r1.PartID and t1.MaterialRequestNo=r1.RequestedNo)

	

	if @Param='UpdateStatus'
	begin
		update RequestDetails_Pams set ApprovedBy=@ApprovedBy,ApprovedTS=@ApprovedTS,Status=@Status,HoldRemarks=@HoldRemarks
		where AutoID=@AutoID
	end

end
