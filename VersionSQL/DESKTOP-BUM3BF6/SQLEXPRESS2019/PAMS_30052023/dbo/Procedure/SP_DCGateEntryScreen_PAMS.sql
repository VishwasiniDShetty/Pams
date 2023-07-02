/****** Object:  Procedure [dbo].[SP_DCGateEntryScreen_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

/*
exec SP_DCGateEntryScreen_PAMS @Param=N'GateEntryView'

exec SP_DCGateEntryScreen_PAMS @Vendor=N'',@Pamsdcno=N'',@VendorDCNo=N'',@Param=N'GateEntryAddView'
exec SP_DCGateEntryScreen_PAMS @param=N'GateEntryEditView'
exec SP_DCGateEntryScreen_PAMS @Vendor=N'V1',@Pamsdcno=N'DC/22-23/12/0001',@VendorDCNo=N'VDC1',@Param=N'GateEntryEditView'
	exec SP_DCGateEntryScreen_PAMS @Vendor=N'V1',@Pamsdcno=N'DC/22-23/12/0001', @Param='GateEntryView'
	SP_DCGateEntryScreen_PAMS @FromDate=N'2023-02-20 15:17:13.000',@ToDate=N'2023-02-25 15:17:13.000',@Vendor=N'''PAMS Internal''',@MaterialID=N'',@Param=N'QualityView'

*/
CREATE procedure [dbo].[SP_DCGateEntryScreen_PAMS]
@FromDate datetime='',
@ToDate datetime='',
@Vendor nvarchar(2000)='',
@MaterialID NVARCHAR(50)='',
@autoid nvarchar(50)='',
@Qty_InKG float=0,
@Qty_InNumbers float=0,
@UpdatedBy_Gate nvarchar(50)='',
@UpdatedTS_Gate datetime='',
@PartID NVARCHAR(50)='',
@DC_Stores_Status nvarchar(50)='',
@Pamsdcno nvarchar(50)='',
@GRNNo nvarchar(50)='',
@VendorDCNo nvarchar(50)='',
@endbitallowances float=0,
@partingallowances float=0,
@vehiclenumber nvarchar(50)='',
@vendordcdate datetime='',
@materialtype nvarchar(50)='',
@UpdatedBy_Stores nvarchar(50)='',
@UpdatedTS_Stores datetime='',
@updatedby nvarchar(50)='',
@file1 varbinary(MAX)=null,
@File1Name nvarchar(50)='',
@Supplier_Report varbinary(MAX)=null,
@Supplier_ReportName nvarchar(100)='',
@Param nvarchar(50)='',
@UpdatedBy_Quality nvarchar(50)='',
@UpdatedTS_Quality datetime='',
@Quality_Status nvarchar(50)='',
@MJCNo nvarchar(50)='',
@PJCNo nvarchar(50)='',
@Qty_KG float=0,
@Qty_Numbers float=0,
@UOM NVARCHAR(50)='',
@rejqty NVARCHAR(50)='',
@PJCYear nvarchar(10)='',
@process nvarchar(2000)='',
@PJCQty float=0,
@Remarks nvarchar(2000)='',
@SettingScrap float=0,
@FromProcess nvarchar(2000)='',
@GateID INT=0,
@DCGateEntryNumber NVARCHAR(50)='',
@OldVendorDCNo nvarchar(50)='',
@DCCloseStatus nvarchar(50)='',
@DCCloseRemarks nvarchar(max)='',
@FileID NVARCHAR(50)='',
@ReworkQty float=0
AS
BEGIN
	declare @strsql nvarchar(max)
	DECLARE @StrVendor nvarchar(2000)
	DECLARE @StrVendor1 nvarchar(2000)
	declare @StrPamsDCNo nvarchar(2000)
	declare @StrPamsDCNo1 nvarchar(2000)
	declare @StrMaterialID nvarchar(2000)
	declare @strVendorDCNo nvarchar(2000)
	declare @strVendorDCNo1 nvarchar(2000)
	declare @strAutoid nvarchar(max)
	declare @StrMaterialType nvarchar(2000)
	select @strsql=''
	select @StrVendor=''
	select @StrMaterialID=''
	select @strVendorDCNo=''
	SELECT @StrPamsDCNo=''
	select @StrPamsDCNo1=''
	select @strVendorDCNo1=''
	select @strAutoid=''
	select @StrVendor1=''
	select @StrMaterialType=''


	create table #AddTemp
	(
	Vendor nvarchar(50),
	GRNNo nvarchar(50),
	MJCNo nvarchar(50),
	Pams_DCNo nvarchar(50),
	MaterialID nvarchar(50),
	PartID nvarchar(50),
	Qty_KG float,
	Qty_Numbers float,
	UOM NVARCHAR(50),
	MaterialUOM NVARCHAR(50),
	ReceivedQty_KG FLOAT,
	ReceivedQty_Numbers float
	)

	create table #EditTemp
	(
	autoid int,
	vendor nvarchar(50),
	grnno nvarchar(50),
	MJCNo nvarchar(50),
	PamsDCNo nvarchar(50),
	materialid nvarchar(50),
	partid nvarchar(50),
	Ordered_qty_kg float,
	Ordered_qty_numbers float,
	OrderedQty_UOM nvarchar(50),
	qty_kg float,
	qty_numbers float,
	ReceivedQty_KG FLOAT,
	ReceivedQty_Numbers FLOAT,
	ReceivedQty_UOM nvarchar(50),
	Endbitallowances float,
	SettingScrap float,
	partingallowances float,
	vendordcno nvarchar(50),
	vendordcdate datetime,
	vehicleno nvarchar(50),
	riseissue int,
	updatedby_gate nvarchar(50),
	updatedts_gate datetime,
	DC_Stores_Status nvarchar(50),
	MaterialUOM nvarchar(50)
	)

	create table #ViewTemp
	(
	Autoid nvarchar(50),
	Vendor nvarchar(50),
	GRNNo nvarchar(50),
	MJCNo nvarchar(50),
	MaterialID NVARCHAR(50),
	PartID NVARCHAR(50),
	OrderedQty_kg float,
	OrderedQty_Numbers float,
	OrderedQty_UOM NVARCHAR(50),
	HSNCode nvarchar(50),
	Qty_InKG FLOAT,
	Qty_InNumbers float,
	ReceivedQty_UOM NVARCHAR(50),
	EndBitAllowances float,
	SettingScrap float,
	PartingAllowances float,
	PAMS_DCNo nvarchar(50),
	VendorDCNo nvarchar(50),
	VendorDCDate datetime,
	VehicleNumber nvarchar(50),
	UpdatedBy_Gate nvarchar(50),
	UpdatedTS_Gate datetime,
	RiseIssue bit default 0,
	DCStores_Status nvarchar(50),
	MaterialUOM nvarchar(50),
	GateID INT,
	DCGateEntryNumber nvarchar(50),
	WithoutOperationQty_KG float,
	WithoutOperationQty_Numbers float,
	WithoutOperationQty_UOM nvarchar(50)
	)

		create table #TempStores
	(
	Autoid nvarchar(50),
	Vendor nvarchar(50),
	GRNNo nvarchar(50),
	MJCNo nvarchar(50),
	PJCNo nvarchar(50),
	PJCYear nvarchar(50),
	PJCQty float,
	Process nvarchar(2000),
	MaterialID NVARCHAR(50),
	PartID NVARCHAR(50),
	OrderedQty_kg float,
	OrderedQty_Numbers float,
	OrderedQty_UOM NVARCHAR(50),
	HSNCode nvarchar(50),
	Qty_InKG FLOAT,
	Qty_InNumbers float,
	ReceivedQty_UOM NVARCHAR(50),
	EndBitAllowances float,
	SettingScrap float,
	PartingAllowances float,
	PAMS_DCNo nvarchar(50),
	VendorDCNo nvarchar(50),
	VendorDCDate datetime,
	VehicleNumber nvarchar(50),
	UpdatedBy_Stores nvarchar(50),
	UpdatedTS_Stores datetime,
	UpdatedBy_Gate nvarchar(50),
	UpdatedTS_Gate datetime,
	RiseIssue bit default 0,
	DCStores_Status nvarchar(50) default 'Pending',
	Quality_Status nvarchar(50),
	RejQty float default 0,
	ReworkQty float default 0,
	Remarks nvarchar(2000),
	MaterialUOM nvarchar(50),
	FromProcess nvarchar(2000),
	ReworkDCQty float
	)

	create table #TempQuality
	(
	Autoid nvarchar(50),
	Vendor nvarchar(50),
	GRNNo nvarchar(50),
	MJCNo nvarchar(50),
	PJCNo nvarchar(50),
	PJCYear nvarchar(50),
	PJCQty float,
	Process nvarchar(2000),
	MaterialID NVARCHAR(50),
	PartID NVARCHAR(50),
	OrderedQty_kg float,
	OrderedQty_Numbers float,
	OrderedQty_UOM NVARCHAR(50),
	UOM NVARCHAR(50),
	HSNCode nvarchar(50),
	Qty_InKG FLOAT,
	Qty_InNumbers float,
	ReceivedQty_UOM NVARCHAR(50),
	EndBitAllowances float,
	SettingScrap float,
	PartingAllowances float,
	PAMS_DCNo nvarchar(50),
	VendorDCNo nvarchar(50),
	VendorDCDate datetime,
	VehicleNumber nvarchar(50),
	UpdatedBy_Quality nvarchar(50),
	UpdatedTS_Quality datetime,
	RiseIssue bit default 0,
	DCStores_Status nvarchar(50),
	Quality_Status nvarchar(50),
	RejQty float default 0,
	ReworkQty float default 0,
	Remarks nvarchar(2000),
	FromProcess nvarchar(2000),
	UpdatedTS_Stores datetime,
	Supplier_Report varbinary(MAX) default null,
	Supplier_ReportName nvarchar(2000),
	InspectionTS DATETIME,
	ReworkDCQty float
	)


	create table #TempInternalStores
	(
	Autoid nvarchar(50),
	Vendor nvarchar(50),
	GRNNo nvarchar(50),
	MJCNo nvarchar(50),
	PJCNo nvarchar(50),
	PJCYear nvarchar(50),
	Process nvarchar(2000),
	MaterialID NVARCHAR(50),
	PartID NVARCHAR(50),
	OrderedQty_kg float,
	OrderedQty_Numbers float,
	OrderedQty_UOM NVARCHAR(50),
	HSNCode nvarchar(50),
	Qty_InKG FLOAT,
	Qty_InNumbers float,
	ReceivedQty_UOM NVARCHAR(50),
	EndBitAllowances float,
	SettingScrap float,
	PartingAllowances float,
	PAMS_DCNo nvarchar(50),
	UpdatedBy_Stores nvarchar(50),
	UpdatedTS_Stores datetime,
	RiseIssue bit default 0,
	DCStores_Status nvarchar(50) default 'Pending',
	Remarks nvarchar(2000),
	MaterialUOM nvarchar(50),
	FromProcess nvarchar(2000),
	RequestNo nvarchar(50),
	RequestDate datetime,
	RequestedBy nvarchar(50),
	RequestedDepartment nvarchar(50)
	)

	if isnull(@vendordcdate,'')=''
	begin
	select @vendordcdate=null
	end

	if isnull(@materialtype,'')<>''
	begin
		select @StrMaterialType='And d1.MaterialType IN ('+@materialtype+')'
	END

	if isnull(@Vendor,'')<>''
	begin
		select @StrVendor='And d1.vendor =N'''+@Vendor+''' '
	end

		if isnull(@Vendor,'')<>''
	begin
		select @StrVendor1='And d1.vendor in ('+@Vendor+')'
	end

	if isnull(@MaterialID,'')<>''
	begin
		select @StrMaterialID='And d1.MaterialID =N'''+@MaterialID+''' '
	end

		if isnull(@Pamsdcno,'')<>''
	begin
		select @StrPamsDCNo='And d1.PAMS_DCNo =N'''+@Pamsdcno+''' '
	end

			if isnull(@Pamsdcno,'')<>''
	begin
		select @StrPamsDCNo1='And d1.PAMSDCNo =N'''+@Pamsdcno+''' '
	end


	if isnull(@VendorDCNo,'')<>''
	begin
		select @strVendorDCNo='And d1.vendordcno=N'''+@VendorDCNo+''' '
	END

	if isnull(@VendorDCNo,'')<>''
	begin
		select @strVendorDCNo1='And d1.vendordcno in ('+@VendorDCNo+') '
	END

	if isnull(@autoid,'')<>''
	BEGIN
		SELECT @strAutoid='And autoid in ('+@autoid+')'
	end
		


	if @Param='GateEntryAddView'
	begin
		select @strsql=''
		select @strsql=@strsql+'Insert into #AddTemp(Vendor,GRNNo,MJCNo,Pams_DCNo ,MaterialID ,PartID ,Qty_KG,Qty_Numbers) '
		select @strsql=@strsql+'select distinct d1.Vendor,d1.GRNNo,d1.MJCNo,d1.Pams_DCNo,d1.MaterialID,d1.PartID,sum(d1.Qty_KG) as Qty_KG,SUM(D1.Qty_Numbers) as Qty_Numbers from DCNoGeneration_PAMS d1 
		where 1=1 and dcstatus=''DC No. generated and confirmed'' and d1.vendor='''+@vendor+''' and  d1.PAMS_DCNo='''+@Pamsdcno+''''
		--select @strsql=@strsql+@StrVendor+@StrPamsDCNo
		select @strsql=@strsql+'group by  d1.Vendor,d1.GRNNo,d1.MJCNo,d1.Pams_DCNo,d1.MaterialID,d1.PartID '
		print(@strsql)
		exec(@strsql)

		update  #AddTemp set uom=isnull(t1.uom,'') 
		from
		(
		select distinct d1.Vendor,d1.GRNNo,d1.MJCNo,d1.Pams_DCNo,d1.MaterialID,d1.PartID,D1.UOM FROM DCNoGeneration_PAMS D1
		) T1 INNER JOIN #AddTemp T2 ON T1.Vendor=t2.Vendor and t1.GRNNo=t2.GRNNo and t1.MJCNo=t2.MJCNo and t1.Pams_DCNo=t2.Pams_DCNo and t1.MaterialID=t2.MaterialID and t1.PartID=t2.PartID

		update #AddTemp set MaterialUOM=rw.UOM
		from  RawMaterialDetails_PAMS rw
		where rw.MaterialID= #AddTemp.MaterialID

		UPDATE #AddTemp SET ReceivedQty_KG=isnull(t1.TotalQty_KG,''),ReceivedQty_Numbers=isnull(t1.TotalQty_No,'')
		from
		(
		select distinct Vendor,GRNNo,MJCNo,PamsDCNo,MaterialID,PartID,sum(Qty_KG) as TotalQty_KG,sum(Qty_Numbers) AS TotalQty_No from DCGateEntryDetails_PAMS 
		group by Vendor,GRNNo,MJCNo,PamsDCNo,MaterialID,PartID
		) t1 inner join #AddTemp t2 on t1.Vendor=t2.Vendor and t1.GRNNo=t2.GRNNo and t1.MJCNo=t2.MJCNo and 
		t1.PamsDCNo=t2.Pams_DCNo and t1.MaterialID=t2.MaterialID and t1.PartID=t2.PartID

		select a1.Vendor,a1.GRNNo,a1.MJCNo,a1.Pams_DCNo ,a1.MaterialID ,a1.PartID ,a1.Qty_KG,a1.Qty_Numbers,a1.UOM,a1.MaterialUOM,a1.ReceivedQty_KG,
		a1.ReceivedQty_Numbers,t1.MaterialDescription,t2.PartDescription,
		CASE WHEN a1.Qty_Numbers>A1.ReceivedQty_Numbers THEN (A1.Qty_Numbers-A1.ReceivedQty_Numbers) END AS PendingQty,
		case when (a1.Qty_Numbers<=a1.ReceivedQty_Numbers) then '0' else '1'end as ShowBit from #AddTemp a1 
		left join(select distinct materialid,MaterialDescription from RawMaterialDetails_PAMS) t1 on a1.MaterialID=t1.MaterialID
		left join (select distinct partid,PartDescription from FGDetails_PAMS) t2 on a1.PartID=t2.PartID where Vendor=@Vendor
	end

	if @Param='GateEntryEditView'
	begin
		select @strsql=''
		select @strsql=@strsql+'Insert into #EditTemp(autoid,vendor,grnno,MJCNo,PamsDCNo,materialid ,partid ,qty_kg,qty_numbers ,ReceivedQty_UOM ,Endbitallowances,partingallowances,vendordcno ,
		vendordcdate,vehicleno,riseissue,updatedby_gate ,updatedts_gate,SettingScrap )'
		select @strsql=@strsql+'select 	autoid,vendor,grnno,MJCNo,PamsDCNo,materialid ,partid ,qty_kg,qty_numbers ,uom ,Endbitallowances,partingallowances,vendordcno ,
		vendordcdate,vehicleno,riseissue,updatedby_gate,updatedts_gate,SettingScrap from DCGateEntryDetails_PAMS d1 where 1=1 And d1.PAMSDCNo='''+@Pamsdcno+'''
		And d1.vendor='''+@vendor+''' '
		select @strsql=@strsql+@strVendorDCNo
		print(@strsql)
		exec(@strsql)

		update  #EditTemp set Ordered_qty_kg=isnull(t1.Qty_KG,0) , Ordered_qty_numbers=isnull(t1.Qty_Numbers,0)
		from
		(
		select distinct d1.Vendor,d1.GRNNo,d1.MJCNo,d1.Pams_DCNo,d1.MaterialID,d1.PartID,sum(d1.Qty_KG) as Qty_KG,SUM(D1.Qty_Numbers) as Qty_Numbers from DCNoGeneration_PAMS d1
		group by d1.Vendor,d1.GRNNo,d1.MJCNo,d1.Pams_DCNo,d1.MaterialID,d1.PartID
		)t1 inner join #EditTemp t2 on t1.Vendor=t2.vendor and t1.GRNNo=t2.grnno and t1.MJCNo=t2.MJCNo and t1.Pams_DCNo=t2.PamsDCNo and t1.MaterialID=t2.materialid and t1.PartID=t2.partid

		update #EditTemp set OrderedQty_UOM=isnull(t1.OrderedQty_UOM,'')
		from
		(
			select distinct d1.Vendor,d1.GRNNo,d1.MJCNo,d1.Pams_DCNo,d1.MaterialID,d1.PartID,d1.uom as OrderedQty_UOM from DCNoGeneration_PAMS d1
		) t1 inner join #EditTemp t2 on t1.Vendor=t2.vendor and t1.GRNNo=t2.grnno and t1.MJCNo=t2.MJCNo and t1.Pams_DCNo=t2.PamsDCNo and t1.MaterialID=t2.materialid and t1.PartID=t2.partid

		UPDATE #EditTemp SET ReceivedQty_KG=isnull(t1.TotalQty_KG,''),ReceivedQty_Numbers=isnull(t1.TotalQty_No,'')
		from
		(
		select distinct Vendor,GRNNo,MJCNo,PamsDCNo,MaterialID,PartID,sum(Qty_KG) as TotalQty_KG,sum(Qty_Numbers) AS TotalQty_No from DCGateEntryDetails_PAMS 
		group by Vendor,GRNNo,MJCNo,PamsDCNo,MaterialID,PartID
		) t1 inner join #EditTemp t2 on t1.Vendor=t2.Vendor and t1.GRNNo=t2.GRNNo and t1.MJCNo=t2.MJCNo and 
		t1.PamsDCNo=t2.PamsDCNo and t1.MaterialID=t2.MaterialID and t1.PartID=t2.PartID
	
		update #EditTemp set DC_Stores_Status=isnull(t1.DC_Stores_Status,'')
		from
		(
		select distinct  d1.Vendor,d1.GRNNo,d1.MJCNo,d1.PamsDCNo,d1.MaterialID,d1.PartID,d1.DC_Stores_Status from DCStoresDetails_PAMS d1
		) t1 inner join #EditTemp t2 on t1.Vendor=t2.Vendor AND t1.GRNNo=t2.GRNNo AND t1.MJCNo=t2.MJCNo and T1.PamsDCNo=T2.PamsDCNo AND T1.MaterialID=T2.materialid and t1.PartID=t2.partid

		update #EditTemp set MaterialUOM=rw.UOM
		from  RawMaterialDetails_PAMS rw
		where rw.MaterialID= #EditTemp.MaterialID

		select 	e1.autoid,e1.vendor,e1.grnno,e1.MJCNo,e1.PamsDCNo,e1.materialid,e1.partid,e1.Ordered_qty_kg,e1.Ordered_qty_numbers,e1.OrderedQty_UOM ,
		e1.qty_kg,e1.qty_numbers,e1.ReceivedQty_UOM,e1.Endbitallowances,e1.SettingScrap,e1.partingallowances,e1.vendordcno ,e1.vendordcdate,
		e1.vehicleno,e1.riseissue,e1.updatedby_gate,e1.updatedts_gate,e1.DC_Stores_Status,e1.MaterialUOM ,t1.MaterialDescription,t2.PartDescription,
		CASE WHEN e1.Ordered_qty_numbers >e1.ReceivedQty_Numbers THEN (e1.Ordered_qty_numbers-e1.ReceivedQty_Numbers) END AS PendingQty
		from #EditTemp e1
		left join(select distinct materialid,MaterialDescription from RawMaterialDetails_PAMS) t1 on e1.MaterialID=t1.MaterialID
		left join (select distinct partid,PartDescription from FGDetails_PAMS) t2 on e1.PartID=t2.PartID

	end

	if @Param='GateEntryView'
	begin
		SELECT @strsql=''
		select @strsql=@strsql+'Insert into #ViewTemp(Autoid,Vendor,GRNNo,MJCNo,MaterialID,PartID ,ReceivedQty_UOM,HSNCode,Qty_InKG,Qty_InNumbers,EndBitAllowances,PartingAllowances,PAMS_DCNo,
		VendorDCNo,VendorDCDate,VehicleNumber,UpdatedBy_Gate,UpdatedTS_Gate,RiseIssue,DCStores_Status,MaterialUOM,SettingScrap,GateID,DCGateEntryNumber)'
		select @strsql=@strsql+'Select distinct d1.Autoid,d1.Vendor,d1.GRNNo,d1.MJCNo,d1.MaterialID,d1.PartID ,d1.uom,r1.HSNCode,d1.Qty_KG,d1.Qty_Numbers,d1.EndBitAllowances,d1.PartingAllowances,d1.PAMSDCNo,
		d1.VendorDCNo,d1.VendorDCDate,d1.VehicleNo,d1.UpdatedBy_Gate,d1.UpdatedTS_Gate,d1.RiseIssue,d2.DC_Stores_Status,r1.UOM,d1.SettingScrap,d1.GateID,d1.DCGateEntryNumber from DCGateEntryDetails_PAMS d1
		left join DCStoresDetails_PAMS d2 on d1.Vendor=d2.Vendor and d1.GRNNo=d2.GRNNo and d1.MaterialID=d2.MaterialID and d1.partid=d2.partid and  d1.VendorDCNo=d2.VendorDCNo and d1.PAMSDCNo=d2.PAMSDCNo and isnull(d1.MJCNo,'''')=isnull(d2.mjcno,'''')  
		left join RawMaterialDetails_PAMS r1 on r1.materialid=d1.materialid
		where 1=1
		and convert(nvarchar(10),d1.UpdatedTS_Gate,126)>='''+convert(nvarchar(10),@fromdate,126)+''' and convert(nvarchar(10),d1.UpdatedTS_Gate,126)<='''+convert(nvarchar(10),@ToDate,126)+''''
		select @strsql=@strsql+@StrMaterialID+@StrVendor1
		print(@strsql)
		exec(@strsql)

		update #ViewTemp set OrderedQty_kg=isnull(t1.ordqty,0),OrderedQty_Numbers=isnull(t1.OrderQtyInNumbers,0),WithoutOperationQty_KG=isnull(t1.WithoutOperationQty_KG,0),WithoutOperationQty_Numbers=isnull(t1.WithoutOperationQty_Numbers,0)
		from
		(select distinct Vendor,GRNNo,MJCNo,Pams_DCNo,MaterialID,PartID,sum(Qty_KG) as ordqty,sum(Qty_Numbers) AS OrderQtyInNumbers,
		sum(WithoutOperationQty_KG) as WithoutOperationQty_KG,sum(WithoutOperationQty_Numbers) as WithoutOperationQty_Numbers from DCNoGeneration_PAMS where DCStatus not in ('Discarded')
		group by Vendor,GRNNo,MJCNo,Pams_DCNo,MaterialID,PartID
		)t1 inner join #ViewTemp t2 on t1.Vendor=t2.Vendor and t1.Pams_DCNo=t2.PAMS_DCNo and t1.MaterialID=t2.MaterialID and t1.PartID=t2.PartID and t1.GRNNo=t2.GRNNo and t1.MJCNo=t2.MJCNo

		update #ViewTemp set OrderedQty_UOM=isnull(t1.OrderedQty_UOM,0),WithoutOperationQty_UOM=isnull(t1.WithoutOperationQty_UOM,'')
		from
		(
		select distinct  Vendor,GRNNo,MJCNo,Pams_DCNo,MaterialID,PartID,uom as OrderedQty_UOM,WithoutOperationQty_UOM  from DCNoGeneration_PAMS
		) t1 inner join #ViewTemp t2 on t1.Vendor=t2.Vendor and t1.GRNNo=t2.GRNNo and t1.MJCNo=t2.MJCNo and t1.Pams_DCNo=t2.PAMS_DCNo and t1.MaterialID=t2.MaterialID and t1.PartID=t2.PartID

		select * from #ViewTemp order by GateID desc

		select * from VendorDCDetails_PAMS
		return
	end


	if @Param='GateEntrySave'
	begin
		if not exists(select * from VendorDCDetails_PAMS where vendor=@Vendor and Pams_dcno=@Pamsdcno and materialtype=@materialtype and Vendordcno=@VendorDCNo)
		begin
			insert into VendorDCDetails_PAMS(vendor,Pams_dcno,materialtype,Vendordcno,File1,File1Name,Updatedby,updatedts,FileID)
			values(@Vendor,@Pamsdcno,@materialtype,@VendorDCNo,@file1,@File1Name,@updatedby,getdate(),@FileID)
		end
		else
		begin
			update VendorDCDetails_PAMS set File1=@file1,File1Name=@File1Name,FileID=@FileID,UpdatedBy=@updatedby,UpdatedTS=GETDATE() where vendor=@Vendor and Pams_dcno=@Pamsdcno and materialtype=@materialtype and Vendordcno=@VendorDCNo
		end

		if not exists(select * from DCGateEntryDetails_PAMS where Vendor=@Vendor and MaterialID=@MaterialID and PartID=@PartID and GRNNo=@GRNNo and PamsDCNo=@Pamsdcno and VendorDCNo=@VendorDCNo and MJCNo=@MJCNo)
		begin
			insert into DCGateEntryDetails_PAMS(Vendor,GRNNo,MaterialID,PartID,Qty_KG,Qty_Numbers,EndBitAllowances,PartingAllowances,PamsDCNo,
			VendorDCNo,VendorDCDate,VehicleNo,UpdatedBy_Gate,UpdatedTS_Gate,MJCNo,UOM,SettingScrap,GateID,DCGateEntryNumber)
			values (@Vendor,@GRNNo,@MaterialID,@PartID,@Qty_InKG,@Qty_InNumbers,@EndBitAllowances,@PartingAllowances,@Pamsdcno,@VendorDCNo,
			@VendorDCDate,@VehicleNumber,@UpdatedBy_Gate,@UpdatedTS_Gate,@MJCNo,@UOM,@SettingScrap,@GateID,@DCGateEntryNumber)
		end
		else
		begin
			update DCGateEntryDetails_PAMS set Qty_KG=@Qty_InKG,Qty_Numbers=@Qty_InNumbers,EndBitAllowances=@endbitallowances,SettingScrap=@SettingScrap,PartingAllowances=@partingallowances,UpdatedBy_Gate=@UpdatedBy_Gate,UpdatedTS_Gate=@UpdatedTS_Gate	
			where Vendor=@Vendor and MaterialID=@MaterialID and PartID=@PartID and PamsDCNo=@Pamsdcno and VendorDCNo=@VendorDCNo and GRNNo=@GRNNo and MJCNo=@MJCNo
		end
	end



		if @Param='StoresView'
		begin
			SELECT @strsql=''
			select @strsql=@strsql+'Insert into #TempStores(Autoid,Vendor,GRNNo,MJCNo,PJCNo,PJCYear,PJCQty, MaterialID,PartID,ReceivedQty_UOM,HSNCode,Qty_InKG,Qty_InNumbers,EndBitAllowances,PartingAllowances,PAMS_DCNo,
			VendorDCNo,VendorDCDate,VehicleNumber,DCStores_Status,UpdatedBy_Gate,UpdatedTS_Gate,UpdatedBy_Stores,UpdatedTS_Stores,RiseIssue,Quality_Status,RejQty,ReworkQty,Remarks,MaterialUOM,SettingScrap,FromProcess,process)'
			select @strsql=@strsql+'Select distinct d1.Autoid,d1.Vendor,d1.GRNNo,d1.MJCNo,d2.PJCNo,d2.PJCYear,d2.PJCQty,d1.MaterialID,d1.PartID ,d1.UOM,r1.HSNCode,d1.Qty_KG,d1.Qty_Numbers,d1.EndBitAllowances,d1.PartingAllowances,d1.PAMSDCNo,
			d1.VendorDCNo,d1.VendorDCDate,d1.VehicleNo,CASE WHEN ISNULL(d2.DC_Stores_Status,'''')='''' THEN ''Pending'' ELSE d2.DC_Stores_Status END,D1.UpdatedBy_Gate,D1.UpdatedTS_Gate, d2.UpdatedBy_Stores,d2.UpdatedTS_Stores,
			d1.RiseIssue,isnull(d2.Quality_Status,''Pending''),d2.RejQty,d2.ReworkQty,d2.remarks,r1.UOM,d1.SettingScrap,d2.FromProcess,d2.process from DCGateEntryDetails_PAMS d1
			left join DCStoresDetails_PAMS d2 on d1.Vendor=d2.vendor and d1.GRNNo=d2.GRNNo and d1.MJCNo=d2.MJCNo and d1.MaterialID=d2.MaterialID and d1.PartID=d2.PartID and d1.PamsDCNo=d2.PamsDCNo and d1.VendorDCNo=d2.VendorDCNo
			left join RawMaterialDetails_PAMS r1 on r1.materialid=d1.materialid
			where 1=1
			and convert(nvarchar(10),d1.UpdatedTS_Gate,126)>='''+convert(nvarchar(10),@fromdate,126)+''' and convert(nvarchar(10),d1.UpdatedTS_Gate,126)<='''+convert(nvarchar(10),@ToDate,126)+'''
			AND D1.PAMSDCNo LIKE '''+'%'+@Pamsdcno+'%'+''' AND D1.MaterialID LIKE '''+'%'+@MaterialID+'%'+''''
			select @strsql=@strsql+@StrVendor1
			print(@strsql)
			exec(@strsql)


			update #TempStores set EndBitAllowances=isnull(t1.EndBitAllowances,0),PartingAllowances=isnull(t1.PartingAllowances,0),SettingScrap=isnull(t1.SettingScrap,0)
			from
			(
			select distinct Vendor,GRNNo,MJCNo,PJCNo,PJCYear,MaterialID,PartID,PamsDCNo,VendorDCNo,PartingAllowances,EndBitAllowances,SettingScrap from DCStoresDetails_PAMS
			) t1 inner join #TempStores t2 on t1.Vendor=t2.Vendor and t1.GRNNo=t2.GRNNo and isnull(t1.MJCNo,'')=isnull(t2.MJCNo,'') and isnull(t1.PJCNo,'')=isnull(t2.PJCNo,'') 
			AND ISNULL(T1.Pjcyear,'')=isnull(t2.Pjcyear,'') and t1.MaterialID=t2.MaterialID and t1.PamsDCNo=t2.PAMS_DCNo and t1.VendorDCNo=t2.VendorDCNo

			--update #TempStores set EndBitAllowances=isnull(t1.EndBitAllowances,0),PartingAllowances=isnull(t1.PartingAllowances,0)
			--from
			--(
			--select distinct Vendor,GRNNo,MJCNo,PJCNo,PJCYear,MaterialID,PartID,PamsDCNo,VendorDCNo,PartingAllowances,EndBitAllowances from DCStoresDetails_PAMS
			--) t1 inner join #TempStores t2 on t1.Vendor=t2.Vendor and t1.GRNNo=t2.GRNNo and t1.MJCNo=t2.MJCNo and t1.PJCNo=t2.PJCNo and t1.MaterialID=t2.MaterialID and t1.PamsDCNo=t2.PAMS_DCNo and t1.VendorDCNo=t2.VendorDCNo


			update #TempStores set OrderedQty_kg=isnull(t1.ordqty,0),OrderedQty_Numbers=isnull(t1.OrderQtyInNumbers,0)
			from
			(select distinct Pams_DCNo,MaterialID,PartID,Vendor,MJCNo, sum(Qty_KG) as ordqty,sum(Qty_Numbers) AS OrderQtyInNumbers from DCNoGeneration_PAMS where DCStatus not in ('Discarded')
			group by Pams_DCNo,MaterialID,PartID,Vendor,MJCNo
			)t1 inner join #TempStores t2 on t1.Vendor=t2.Vendor and t1.Pams_DCNo=t2.PAMS_DCNo and t1.MaterialID=t2.MaterialID and t1.PartID=t2.PartID and t1.MJCNo=t2.MJCNo

			update #TempStores set OrderedQty_UOM=isnull(t1.UOM,'')
			from
			(select distinct Pams_DCNo,MaterialID,PartID,Vendor,MJCNo, UOM from DCNoGeneration_PAMS where DCStatus not in ('Discarded')
			)t1 inner join #TempStores t2 on t1.Vendor=t2.Vendor and t1.Pams_DCNo=t2.PAMS_DCNo and t1.MaterialID=t2.MaterialID and t1.PartID=t2.PartID and t1.MJCNo=t2.MJCNo


			update #TempStores set  OrderedQty_kg=isnull(t1.ordqty,0),OrderedQty_Numbers=isnull(t1.OrderQtyInNumbers,0)
			from
			(
			select distinct Pams_DCNo,GRNNo,MaterialID,PartID,Vendor,MJCNo,pjcno,pjcyear, sum(Qty_KG) as ordqty,sum(Qty_Numbers) AS OrderQtyInNumbers from DCNoGeneration_PAMS d1 where DCStatus not in ('Discarded')
			and  exists(select Pams_DCNo,GRNNo,MaterialID,PartID,Vendor,MJCNo,pjcno,pjcyear from DCStoresDetails_PAMS d2 where d1.Pams_DCNo=d2.PamsDCNo and d1.GRNNo=d2.GRNNo and d1.MaterialID=d2.MaterialID and d1.PartID=d2.PartID
			and d1.Vendor=d2.Vendor and d1.MJCNo=d2.MJCNo and d1.PJCNo=d2.PJCNo and d1.PJCYear=d2.PJCYear)
			group by Pams_DCNo,GRNNo,MaterialID,PartID,Vendor,MJCNo,pjcno,pjcyear
			)t1 inner join #TempStores t2 on t1.Pams_DCNo=t2.PAMS_DCNo and t1.GRNNo=t2.GRNNo and t1.MaterialID=t2.MaterialID and t1.PartID=t2.PartID and t1.Vendor=t2.Vendor and t1.MJCNo=t2.MJCNo and t1.PJCNo=t2.PJCNo

			
			update #TempStores set ReworkDCQty =isnull(t1.RequestedQty,0)
			from
			(	
				select distinct  Vendor,PamsDCNo,MaterialID,PartID,VendorDCNo,MJCNo,Process,isnull(PJCNo,0) as PJCNo ,sum(RequestedQty) as RequestedQty from ReworkDcDetailsForSFG_Pams
				group by  Vendor,PamsDCNo,MaterialID,PartID,VendorDCNo,MJCNo,Process,PJCNo
			) t1 inner join #TempStores t2 on t1.vendor=t2.vendor and t1.PamsDCNo=t2.PAMS_DCNo and t1.MaterialID=t2.MaterialID and t1.PartID=t2.PartID and t1.VendorDCNo=t2.VendorDCNo 
			and t1.MJCNo=t2.MJCNo and isnull(t1.pjcno,0)=isnull(t2.pjcno,0) and t1.process=t2.Process

			select 	Autoid,Vendor,GRNNo,MJCNo,PJCNo,PJCYear,PJCQty,Process,MaterialID ,PartID ,OrderedQty_kg,OrderedQty_Numbers,OrderedQty_UOM ,HSNCode,Qty_InKG,
			case when isnull(ReworkQty,0)>0 then (isnull(Qty_InNumbers,0)-isnull(ReworkQty,0)) else Qty_InNumbers end as Qty_InNumbers,
			ReceivedQty_UOM ,EndBitAllowances,SettingScrap,PartingAllowances,PAMS_DCNo ,VendorDCNo ,VendorDCDate ,VehicleNumber,
			UpdatedBy_Stores,UpdatedTS_Stores ,UpdatedBy_Gate ,UpdatedTS_Gate ,RiseIssue ,DCStores_Status ,
			Quality_Status,RejQty ,ReworkQty ,Remarks,MaterialUOM,FromProcess,ReworkDCQty 
			from #TempStores order by UpdatedTS_Gate desc

			select * from VendorDCDetails_PAMS
			return
		end


		if @Param='StoresSave'
		begin	
			if not exists(select * from DCStoresDetails_PAMS where Vendor=@Vendor and PamsDCNo=@Pamsdcno and MaterialID=@MaterialID and PartID=@PartID and GRNNo=@GRNNo and VendorDCNo=@VendorDCNo and isnull(mjcno,'')=isnull(@mjcno,'') and isnull(pjcno,'')=isnull(@pjcno,'') and isnull(pjcyear,'')=isnull(@pjcyear,''))
			begin
				insert into DCStoresDetails_PAMS(Vendor,GRNNo,MaterialID,PartID,Qty_KG,Qty_Numbers,EndBitAllowances,PartingAllowances,PamsDCNo,VendorDCNo,VendorDCDate,VehicleNo,DC_Stores_Status,
				UpdatedBy_Stores,UpdatedTS_Stores,MJCNo,PJCNo,PJCYear,Process,PJCQty,uom,Remarks,SettingScrap,FromProcess)
				values(@Vendor,@GRNNo,@MaterialID,@PartID,@Qty_KG,@Qty_Numbers,@EndBitAllowances,@PartingAllowances,@PamsDCNo,@VendorDCNo,@VendorDCDate,@vehiclenumber,@DC_Stores_Status,@UpdatedBy_Stores,
				@UpdatedTS_Stores,@MJCNo,@PJCNo,@PJCYear,@process,@PJCQty, @UOM,@Remarks,@SettingScrap,@FromProcess)
			END
			ELSE
			BEGIN
				UPDATE DCStoresDetails_PAMS SET EndBitAllowances=@endbitallowances,PartingAllowances=@partingallowances,PJCQty=@PJCQty, UpdatedBy_Stores=@UpdatedBy_Stores,UpdatedTS_Stores=@UpdatedTS_Stores,Remarks=@Remarks,SettingScrap=@SettingScrap,FromProcess=@FromProcess
				WHERE Vendor=@Vendor and PamsDCNo=@Pamsdcno and MaterialID=@MaterialID and PartID=@PartID and GRNNo=@GRNNo and VendorDCNo=@VendorDCNo and isnull(mjcno,'')=isnull(@mjcno,'') and isnull(pjcno,'')=isnull(@pjcno,'') and isnull(pjcyear,'')=isnull(@pjcyear,'')
			END
		end


		if @Param='UpdateIssueRised'
		begin
			update DCGateEntryDetails_PAMS set RiseIssue=1 where Vendor=@Vendor and GRNNo=@GRNNo and MJCNo=@MJCNo and PamsDCNo=@Pamsdcno and VendorDCNo=@VendorDCNo and MaterialID=@MaterialID and PartID=@PartID
		end


		if @Param='UpdateStoresApprovalStatus'
		begin

			update DCGateEntryDetails_PAMS set RiseIssue=0 where Vendor=@Vendor and GRNNo=@GRNNo and MJCNo=@MJCNo and PamsDCNo=@Pamsdcno and VendorDCNo=@VendorDCNo and MaterialID=@MaterialID and PartID=@PartID
			
			if isnull(@DCCloseStatus,'')<>''
			begin
				update DCNoGeneration_PAMS set DCCloseStatus=@DCCloseStatus,DCCloseRemarks =@DCCloseRemarks 
				where vendor=@Vendor and GRNNo=@Grnno and MaterialID=@MaterialID and PartID=@partid and process=@Process AND Pams_DCNo=@Pamsdcno and isnull(mjcno,'')=isnull(@mjcno,'') and isnull(pjcno,'')=isnull(@pjcno,'')
			end

			select @strsql=''
			select @strsql=@strsql+'update DCStoresDetails_PAMS set dc_stores_status='''+@DC_Stores_Status+''',updatedby_stores='''+@UpdatedBy_Stores+''',
			updatedts_stores='''+convert(nvarchar(20),@UpdatedTS_Stores,126)+''' where 1=1 and  Vendor='''+@Vendor+''' and GRNNo='''+@GRNNo+'''
			and MJCNo='''+@MJCNo+''' and PamsDCNo='''+@Pamsdcno+''' and VendorDCNo='''+@VendorDCNo+''' and MaterialID='''+@MaterialID+''' and PartID='''+@PartID+''' and isnull(pjcno,'''')='''+isnull(@pjcno,'')+''' and isnull(pjcyear,'''')='''+isnull(@PJCYear,'')+''' '
			select @strsql=@strsql+@strAutoid
			print(@strsql)
			exec(@strsql)
		end

		if @Param='internalStoresView'
		begin
			SELECT @strsql=''
			select @strsql=@strsql+'Insert into #TempInternalStores(Autoid,Vendor,GRNNo,MJCNo,PJCNo,PJCYear, MaterialID,PartID,ReceivedQty_UOM,HSNCode,Qty_InKG,Qty_InNumbers,EndBitAllowances,PartingAllowances,PAMS_DCNo,
			DCStores_Status,UpdatedBy_Stores,UpdatedTS_Stores,Remarks,MaterialUOM,SettingScrap,FromProcess,RequestNo,Process,requestedby)'
			select @strsql=@strsql+'Select distinct d2.Autoid,d1.Vendor,d1.GRNNo,d1.MJCNo,d1.PJCNo,d1.PJCYear,d1.MaterialID,d1.PartID ,D2.UOM,r1.HSNCode,d2.Qty_KG,d2.Qty_Numbers,d2.EndBitAllowances,d2.PartingAllowances,d1.PAMS_DCNo,
			isnull(d2.DC_Stores_Status,''Pending''),d2.UpdatedBy_Stores,d2.UpdatedTS_Stores,d2.remarks,r1.UOM,d2.SettingScrap,d2.FromProcess,d1.MaterialRequestNo,d1.process,d1.requestedby from DCNoGeneration_PAMS d1
			left join RawMaterialDetails_PAMS r1 on r1.materialid=d1.materialid
			left join DCStoresDetails_PAMS d2 on d1.Vendor=d2.vendor and d1.GRNNo=d2.GRNNo and d1.MJCNo=d2.MJCNo and d1.MaterialID=d2.MaterialID and d1.PartID=d2.PartID and d1.Pams_DCNo=d2.PamsDCNo 
			where 1=1 and dcstatus=''DC No. generated and confirmed''
			and convert(nvarchar(10),Dcdate,126)>='''+convert(nvarchar(10),@fromdate,126)+''' and convert(nvarchar(10),Dcdate,126)<='''+convert(nvarchar(10),@ToDate,126)+'''
			AND D1.PAMS_DCNo LIKE '''+'%'+@Pamsdcno+'%'+''' AND D1.MaterialID LIKE '''+'%'+@MaterialID+'%'+''''
			select @strsql=@strsql+@StrVendor1
			print(@strsql)
			exec(@strsql)

			update #TempInternalStores set requestdate=isnull(t1.RequestedTS,''),RequestedDepartment=isnull(t1.Department,'')
			from
			(
			select distinct Vendor,Process,MaterialID,PartID,cast(RequestedTS as date) as RequestedTS,Department from RequestDetails_Pams where Vendor='PAMS Internal'
			)t1 inner join #TempInternalStores t2 on t1.Vendor=t2.Vendor and t1.Process=t2.Process and t1.MaterialID=t2.MaterialID and t1.PartID=t2.PartID

			update #TempInternalStores set OrderedQty_kg=isnull(t1.ordqty,0),OrderedQty_Numbers=isnull(t1.OrderQtyInNumbers,0)
			from
			(select distinct Pams_DCNo,MaterialID,PartID,Vendor,MJCNo, sum(Qty_KG) as ordqty,sum(Qty_Numbers) AS OrderQtyInNumbers from DCNoGeneration_PAMS where DCStatus not in ('Discarded')
			group by Pams_DCNo,MaterialID,PartID,Vendor,MJCNo
			)t1 inner join #TempInternalStores t2 on t1.Vendor=t2.Vendor and t1.Pams_DCNo=t2.PAMS_DCNo and t1.MaterialID=t2.MaterialID and t1.PartID=t2.PartID and t1.MJCNo=t2.MJCNo


			update #TempInternalStores set OrderedQty_UOM=isnull(t1.UOM,'')
			from
			(select distinct Pams_DCNo,MaterialID,PartID,Vendor,MJCNo, UOM from DCNoGeneration_PAMS where DCStatus not in ('Discarded')
			)t1 inner join #TempInternalStores t2 on t1.Vendor=t2.Vendor and t1.Pams_DCNo=t2.PAMS_DCNo and t1.MaterialID=t2.MaterialID and t1.PartID=t2.PartID and t1.MJCNo=t2.MJCNo

			update #TempInternalStores set  OrderedQty_kg=isnull(t1.ordqty,0),OrderedQty_Numbers=isnull(t1.OrderQtyInNumbers,0)
			from
			(
			select distinct Pams_DCNo,GRNNo,MaterialID,PartID,Vendor,MJCNo,pjcno,pjcyear, sum(Qty_KG) as ordqty,sum(Qty_Numbers) AS OrderQtyInNumbers from DCNoGeneration_PAMS d1 where DCStatus not in ('Discarded')
			and  exists(select Pams_DCNo,GRNNo,MaterialID,PartID,Vendor,MJCNo,pjcno,pjcyear from DCStoresDetails_PAMS d2 where d1.Pams_DCNo=d2.PamsDCNo and d1.GRNNo=d2.GRNNo and d1.MaterialID=d2.MaterialID and d1.PartID=d2.PartID
			and d1.Vendor=d2.Vendor and d1.MJCNo=d2.MJCNo and d1.PJCNo=d2.PJCNo and d1.PJCYear=d2.PJCYear)
			group by Pams_DCNo,GRNNo,MaterialID,PartID,Vendor,MJCNo,pjcno,pjcyear
			)t1 inner join #TempInternalStores t2 on t1.Pams_DCNo=t2.PAMS_DCNo and t1.GRNNo=t2.GRNNo and t1.MaterialID=t2.MaterialID and t1.PartID=t2.PartID and t1.Vendor=t2.Vendor and t1.MJCNo=t2.MJCNo and t1.PJCNo=t2.PJCNo 

			select * from #TempInternalStores
			return
		end

		if @Param='InternalStoresSave'
		begin	
			if not exists(select * from DCStoresDetails_PAMS where Vendor=@Vendor and PamsDCNo=@Pamsdcno and MaterialID=@MaterialID and PartID=@PartID and GRNNo=@GRNNo and VendorDCNo=@VendorDCNo and isnull(mjcno,'')=isnull(@mjcno,'') and isnull(pjcno,'')=isnull(@pjcno,''))
			begin
				insert into DCStoresDetails_PAMS(Vendor,GRNNo,MaterialID,PartID,Qty_KG,Qty_Numbers,EndBitAllowances,PartingAllowances,PamsDCNo,VendorDCNo,VendorDCDate,VehicleNo,DC_Stores_Status,
				UpdatedBy_Stores,UpdatedTS_Stores,MJCNo,PJCNo,PJCYear,Process,PJCQty,uom,Remarks,SettingScrap,FromProcess)
				values(@Vendor,@GRNNo,@MaterialID,@PartID,@Qty_KG,@Qty_Numbers,@EndBitAllowances,@PartingAllowances,@PamsDCNo,@VendorDCNo,@VendorDCDate,@vehiclenumber,@DC_Stores_Status,@UpdatedBy_Stores,
				@UpdatedTS_Stores,@MJCNo,@PJCNo,@PJCYear,@process,@PJCQty, @UOM,@Remarks,@SettingScrap,@FromProcess)
			END
			ELSE
			BEGIN
				UPDATE DCStoresDetails_PAMS SET Qty_KG=@Qty_KG,Qty_Numbers=@Qty_Numbers,EndBitAllowances=@endbitallowances,PartingAllowances=@partingallowances,PJCQty=@PJCQty, UpdatedBy_Stores=@UpdatedBy_Stores,UpdatedTS_Stores=@UpdatedTS_Stores,Remarks=@Remarks,SettingScrap=@SettingScrap,FromProcess=@FromProcess
				WHERE Vendor=@Vendor and PamsDCNo=@Pamsdcno and MaterialID=@MaterialID and PartID=@PartID and GRNNo=@GRNNo and VendorDCNo=@VendorDCNo and isnull(mjcno,'')=isnull(@mjcno,'') and isnull(pjcno,'')=isnull(@pjcno,'') and isnull(pjcyear,'')=isnull(@pjcyear,'')
			END
		end

		if @Param='QualityView'
		begin
			SELECT @strsql=''
			select @strsql=@strsql+'Insert into #TempQuality(Autoid,Vendor,GRNNo,MJCNo,PJCNo,PJCYear,PJCQty,MaterialID,PartID ,ReceivedQty_UOM,HSNCode,Qty_InKG,Qty_InNumbers,EndBitAllowances,PartingAllowances,PAMS_DCNo,
			VendorDCNo,VendorDCDate,VehicleNumber,DCStores_Status,UpdatedBy_Quality,UpdatedTS_Quality,Quality_Status,RejQty,ReworkQty,Process,Remarks,SettingScrap,UpdatedTS_Stores,Supplier_Report,Supplier_ReportName)'
			select @strsql=@strsql+'Select distinct d1.Autoid,d1.Vendor,d1.GRNNo,d1.MJCNo,d1.PJCNo,d1.pjcyear,d1.pjcqty, d1.MaterialID,d1.PartID ,d1.UOM,r1.HSNCode,d1.Qty_KG,d1.Qty_Numbers,d1.EndBitAllowances,d1.PartingAllowances,PAMSDCNo,
			d1.VendorDCNo,d1.VendorDCDate,d1.VehicleNo,isnull(d1.DC_Stores_Status,''Pending''),d1.UpdatedBy_Quality,d1.UpdatedTS_Quality,isnull(d1.Quality_Status,''Pending''),d1.RejQty,d1.ReworkQty,d1.process,d1.Remarks,d1.SettingScrap,d1.UpdatedTS_Stores,d1.Supplier_Report,d1.Supplier_ReportName from DCStoresDetails_PAMS d1
			left join RawMaterialDetails_PAMS r1 on r1.materialid=d1.materialid
			where 1=1
			and convert(nvarchar(10),UpdatedTS_Stores,126)>='''+convert(nvarchar(10),@fromdate,126)+''' and convert(nvarchar(10),UpdatedTS_Stores,126)<='''+convert(nvarchar(10),@ToDate,126)+'''
			AND D1.PAMSDCNo LIKE '''+'%'+@Pamsdcno+'%'+''' AND D1.MaterialID LIKE '''+'%'+@MaterialID+'%'+''' and ISNULL(d1.DC_Stores_Status,'''')<>'''' '
			select @strsql=@strsql+@StrVendor1
			print(@strsql)
			exec(@strsql)

			UPDATE #TempQuality SET InspectionTS=ISNULL(UpdatedTS,'')
			FROM
			(
				select distinct Pams_DCNo,ComponentID,process,MJCNo,PJCNo,VendorDCNo,UpdatedTS  from FinalInspectionTransactionFG_PAMS
			) T1 INNER JOIN #TempQuality T2 ON T1.Pams_DCNo=T2.PAMS_DCNo AND T1.ComponentID=T2.PARTID and t1.Process=t2.Process and t1.MJCNo=t2.MJCNo 
			and isnull(t1.PJCNo,'')=isnull(t2.PJCNo,'') and t1.VendorDCNo=t2.VendorDCNo

			update #TempQuality set OrderedQty_kg=isnull(t1.ordqty,0),OrderedQty_Numbers=isnull(t1.OrderQtyInNumbers,0)
			from
			(select distinct Pams_DCNo,MaterialID,PartID,Vendor,MJCNo,isnull(pjcno,'') as pjcno,isnull(pjcyear,'') as pjcyear, sum(Qty_KG) as ordqty,sum(Qty_Numbers) AS OrderQtyInNumbers from DCNoGeneration_PAMS where DCStatus not in ('Discarded')
			group by Pams_DCNo,MaterialID,PartID,Vendor,MJCNo,isnull(pjcno,''),isnull(pjcyear,'')
			)t1 inner join #TempQuality t2 on t1.Vendor=t2.Vendor and t1.Pams_DCNo=t2.PAMS_DCNo and t1.MaterialID=t2.MaterialID and t1.PartID=t2.PartID and t1.MJCNo=t2.MJCNo and isnull(t1.pjcno,'')=isnull(t2.PJCNo,'') and isnull(t1.pjcyear,'')=isnull(t2.pjcyear,'')

			update #TempQuality set OrderedQty_UOM=isnull(t1.UOM,'')
			from
			(select distinct Pams_DCNo,MaterialID,PartID,Vendor,MJCNo,isnull(pjcno,'') as pjcno,isnull(pjcyear,'') as pjcyear, UOM from DCNoGeneration_PAMS where DCStatus not in ('Discarded')
			)t1 inner join #TempQuality t2 on t1.Vendor=t2.Vendor and t1.Pams_DCNo=t2.PAMS_DCNo and t1.MaterialID=t2.MaterialID and t1.PartID=t2.PartID and t1.MJCNo=t2.MJCNo and  isnull(t1.pjcno,'')=isnull(t2.PJCNo,'') and  isnull(t1.pjcyear,'')=isnull(t2.pjcyear,'')

			update #TempQuality set ReworkDCQty =isnull(t1.RequestedQty,0)
			from
			(	
				select distinct  Vendor,PamsDCNo,MaterialID,PartID,VendorDCNo,MJCNo,Process,isnull(PJCNo,0) as PJCNo ,sum(RequestedQty) as RequestedQty from ReworkDcDetailsForSFG_Pams
				group by  Vendor,PamsDCNo,MaterialID,PartID,VendorDCNo,MJCNo,Process,PJCNo
			) t1 inner join #TempQuality t2 on t1.vendor=t2.vendor and t1.PamsDCNo=t2.PAMS_DCNo and t1.MaterialID=t2.MaterialID and t1.PartID=t2.PartID and t1.VendorDCNo=t2.VendorDCNo 
			and t1.MJCNo=t2.MJCNo and isnull(t1.pjcno,0)=isnull(t2.pjcno,0) and t1.process=t2.Process
		
			select 	Autoid,Vendor,GRNNo ,MJCNo,PJCNo ,PJCYear,PJCQty,Process ,MaterialID,PartID ,OrderedQty_kg,OrderedQty_Numbers,OrderedQty_UOM ,UOM,HSNCode ,Qty_InKG,
			case when isnull(ReworkQty,0)>0 then (isnull(Qty_InNumbers,0)-isnull(ReworkQty,0)) else Qty_InNumbers end as Qty_InNumbers,ReceivedQty_UOM ,
			EndBitAllowances,SettingScrap,PartingAllowances,PAMS_DCNo,VendorDCNo,VendorDCDate,VehicleNumber,UpdatedBy_Quality,UpdatedTS_Quality,RiseIssue,DCStores_Status,
			Quality_Status ,RejQty ,ReworkQty ,Remarks ,FromProcess,UpdatedTS_Stores,Supplier_Report ,Supplier_ReportName,InspectionTS,ReworkDCQty from #TempQuality  order by UpdatedTS_Stores desc

			select * from VendorDCDetails_PAMS
			return
		end


		if @Param='UpdateQualityApprovalStatus'
		begin
			--select @strsql=''
			--select @strsql=@strsql+'update DCStoresDetails_PAMS set RejQty='''+@rejqty+''',Supplier_Report='''+@Supplier_Report+''',Supplier_ReportName='''+@Supplier_ReportName+''', updatedby_quality='''+@UpdatedBy_Quality+''',
			--updatedts_Quality='''+convert(nvarchar(20),@UpdatedTS_Quality,126)+''' where 1=1 '
			--select @strsql=@strsql+@strAutoid
			--print(@strsql)
			--exec(@strsql)
			if isnull(@reworkqty,0)<>0
			begin
				update DCStoresDetails_PAMS set ReworkQty=@ReworkQty,Supplier_Report=@Supplier_Report,Supplier_ReportName=@Supplier_ReportName, updatedby_quality=@UpdatedBy_Quality,
				updatedts_Quality=convert(nvarchar(20),@UpdatedTS_Quality,126) where 1=1 AND AutoID=@autoid
			end
			else
			begin
				update DCStoresDetails_PAMS set RejQty=@rejqty,Supplier_Report=@Supplier_Report,Supplier_ReportName=@Supplier_ReportName, updatedby_quality=@UpdatedBy_Quality,
				updatedts_Quality=convert(nvarchar(20),@UpdatedTS_Quality,126) where 1=1 AND AutoID=@autoid
			end

		end

		IF @Param='UpdateVendorDCNo'
		begin
			update DCGateEntryDetails_PAMS set VendorDCNo=@VendorDCNo where 
			Vendor=@Vendor and PamsDCNo=@Pamsdcno and  VendorDCNo=@OldVendorDCNo

			update VendorDCDetails_PAMS set VendorDCNo=@VendorDCNo where
			Vendor=@Vendor and Pams_DcNo=@Pamsdcno and  VendorDCNo=@OldVendorDCNo
		end


		if @Param='ForceDCClose'
		begin

			declare @DCOrderedQty_KG float
			declare @DCOrderedQty_Numbers float
			declare @DCReceivedQty_KG float
			declare @DCReceivedQty_Numbers float

			select @DCOrderedQty_KG=''
			select @DCOrderedQty_Numbers=''
			select @DCReceivedQty_KG=''
			select @DCReceivedQty_Numbers=''

			select @DCOrderedQty_KG=(select sum(cast(Qty_KG as int)) from DCNoGeneration_PAMS where Pams_DCNo=@Pamsdcno)
			select @DCOrderedQty_Numbers=(select sum(cast(Qty_Numbers as int)) from DCNoGeneration_PAMS where Pams_DCNo=@Pamsdcno)
			select @DCReceivedQty_KG=(select sum(cast(Qty_KG as int)) from DCStoresDetails_PAMS where PamsDCNo=@Pamsdcno)
			select @DCReceivedQty_Numbers=(select sum(cast(PJCQty as int)) from DCStoresDetails_PAMS where PamsDCNo=@Pamsdcno)

			if (isnull(@DCReceivedQty_Numbers,0)>=isnull(@DCOrderedQty_Numbers,0))
			begin
				update DCNoGeneration_PAMS set DCCloseStatus='Closed' where Pams_DCNo=@Pamsdcno
			end
			else
			begin
				return
			end
		end

		--if @Param='UpdateStoresStatus'
	--begin
		
	--	--if not exists(select * from DCGateEntryDetails_PAMS where Vendor=@Vendor and PamsDCNo=@Pamsdcno)
	--	--begin
	--	--	--insert into DCGateEntryDetails_PAMS(vendor
	--	update DCGateEntryDetails_PAMS set EndBitAllowances=@endbitallowances,PartingAllowances=@partingallowances,UpdatedBy_Stores=@UpdatedBy_Stores,UpdatedTS_Stores=@UpdatedTS_Stores where AutoID=@autoid
	--end

	--if @Param='UpdateStoresApprovalStatus'
	--begin
	--	select @strsql=''
	--	select @strsql=@strsql+'update DCGateEntryDetails_PAMS set dc_stores_status='''+@DC_Stores_Status+''',updatedby_stores='''+@UpdatedBy_Stores+''',
	--	updatedts_stores='''+convert(nvarchar(20),@UpdatedTS_Stores,126)+''',RiseIssue=''0'' where 1=1 '
	--	select @strsql=@strsql+@strAutoid
	--	print(@strsql)
	--	exec(@strsql)
	--end

	--if @Param='UpdateQualityApprovalStatus'
	--begin
	--	select @strsql=''
	--	select @strsql=@strsql+'update DCGateEntryDetails_PAMS set RejQty='''+@rejqty+''',updatedby_quality='''+@UpdatedBy_Quality+''',
	--	updatedts_Quality='''+convert(nvarchar(20),@UpdatedTS_Quality,126)+''' where 1=1 '
	--	select @strsql=@strsql+@strAutoid
	--	print(@strsql)
	--	exec(@strsql)
	--end

	--if @Param='UpdateIssueRised'
	--begin
	--	update DCGateEntryDetails_PAMS set RiseIssue=1 where AutoID=@autoid
	--end



			--if @Param='InternalStoresSave'
	--begin	
	--	if not exists(select * from DCGateEntryDetails_PAMS where Vendor=@Vendor and PamsDCNo=@Pamsdcno and MaterialID=@MaterialID and PartID=@PartID)
	--	begin
	--		insert into DCGateEntryDetails_PAMS(Vendor,GRNNo,MaterialID,PartID,Qty_KG,Qty_Numbers,EndBitAllowances,PartingAllowances,PamsDCNo,RiseIssue,UpdatedBy_Stores,
	--		UpdatedTS_Stores,MJCNo,PJCNo,UOM)
	--		values(@Vendor,@GRNNo,@MaterialID,@PartID,@Qty_KG,@Qty_Numbers,@EndBitAllowances,@PartingAllowances,@PamsDCNo,0,@UpdatedBy_Stores,@UpdatedTS_Stores,@MJCNo,@PJCNo,@UOM)
	--	END
	--	ELSE
	--	BEGIN
	--		UPDATE DCGateEntryDetails_PAMS SET UOM=@UOM,Qty_KG=@Qty_KG,Qty_Numbers=@Qty_Numbers,EndBitAllowances=@endbitallowances,PartingAllowances=@partingallowances,UpdatedBy_Stores=@UpdatedBy_Stores,UpdatedTS_Stores=@UpdatedTS_Stores
	--		WHERE AutoID=@autoid
	--	END
	--end




END
