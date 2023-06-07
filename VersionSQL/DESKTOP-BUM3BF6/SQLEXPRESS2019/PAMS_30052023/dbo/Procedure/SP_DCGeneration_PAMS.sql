/****** Object:  Procedure [dbo].[SP_DCGeneration_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

/*
SP_DCGeneration_PAMS @Grnno=N'RM/22-23/11/0001',@MaterialID=N'M1',@Vendor=N'V1', @Param=N'DCNoDetailsView_NewTemp'
SP_DCGeneration_PAMS @date=N'2023-01-09 00:00:00.000',@toprows=N'5', @vENDOR=N'C 3000',@Param='Viewtop10Records'
SP_DCGeneration_PAMS  @toprows=N'5',@Param='Viewtop10Records',@Vendor=N'C 3000'
SP_DCGeneration_PAMS  @Pams_DCNo=N'DC/22-23/12/0001',@Param='GRNPendingQty'

*/
CREATE procedure [dbo].[SP_DCGeneration_PAMS]
@FromDate datetime='',
@Todate datetime='',
@date datetime='',
@MaterialID nvarchar(50)='',
@Grnno nvarchar(50)='',
@partid nvarchar(50)='',
@Process nvarchar(2000)='',
@Vendor nvarchar(50)='',
@toprows nvarchar(2000)='',
@HSNCode nvarchar(50)='',
@UOM NVARCHAR(50)='',
@Bin nvarchar(50)='',
@Value nvarchar(50)='',
@DCNo nvarchar(50)='',
@DCDate datetime='',
@MaterialType nvarchar(50)='',
@Qty_KG float=0,
@Qty_Numbers float=0,
@AutoID NVARCHAR(MAX)='',
@Pams_DCNo nvarchar(50)='',
@Pams_DCID INT=0,
@DCStatus nvarchar(50)='',
@UpdatedBy nvarchar(50)='',
@UpdatedTS datetime='',
@DocumentType nvarchar(50)='',
@DCType nvarchar(50)='',
@JobCardType nvarchar(50)='',
@MJCNo nvarchar(50)='',
@PJCNo nvarchar(50)='',
@PJCYear nvarchar(50)='',
@Employee nvarchar(50)='',
@MaterialRequestNo nvarchar(50)='',
@RequestedBy nvarchar(50)='',
@Param nvarchar(50)='',
@NewPartID nvarchar(50)='',
@NewProcess nvarchar(50)='',
@NewQty_KG float=0,
@NewQty_Numbers float=0,
@NewPJCNo nvarchar(50)='',
@NewPJCYear nvarchar(50)='',
@UserID NVARCHAR(50)=''
as
begin
	declare @StrVendor nvarchar(2000)
	declare @strsql nvarchar(max)
	DECLARE @StrMaterialID NVARCHAR(2000)
	Declare @StrGrnNo nvarchar(2000)
	declare @StrPartID NVARCHAR(2000)
	DECLARE @StrProcess nvarchar(max)
	DECLARE @StrAutoID NVARCHAR(MAX)
	declare @strtoprows nvarchar(max)
	declare @strPamsDCNo nvarchar(50)
	SELECT @StrPartID=''
	select @StrGrnNo=''
	SELECT @StrMaterialID=''
	select @StrVendor=''
	select @strsql=''
	SELECT @StrAutoID=''
	select @StrProcess=''
	select @strtoprows=''
	select @strPamsDCNo=''

	create table #Temp
	(
	 Vendor NVARCHAR(50),
	 GRNNo NVARCHAR(50),
	 MaterialID NVARCHAR(50),
	 PartID NVARCHAR(50),
	 process NVARCHAR(2000),
	 Qty_KG FLOAT,
	 Qty_Numbers FLOAT,
	 HSNCode NVARCHAR(50),
	 uom NVARCHAR(50),
	 bin nvarchar(50),
	 Value float,
	Pams_DCNo nvarchar(50),
	DCDate datetime,
	Pams_DCID int,
	dcstatus nvarchar(50),
	UpdatedBy nvarchar(50),
	UpdatedTS datetime,
	DCType nvarchar(50),
	JobCardType nvarchar(50),
	MJCNo nvarchar(50),
	PJCNo nvarchar(50),
	PJCYear nvarchar(50),
	employee nvarchar(50),
	RequestedBy nvarchar(50),
	MaterialRequestNo nvarchar(50)
	)

	CREATE TABLE #GRNPendingQty
	(
	uom NVARCHAR(50),
	DCNO NVARCHAR(50),
	GRNNo nvarchar(50),
	OrderedQty float,
	OrderedQty_Numbers float,
	IssuedQty_kg float,
	IssuedQty_Numbers float,
		MaterialUOM NVARCHAR(50),
	--PendingQty float
	)

	if isnull(@vendor,'')<>''
	begin
		select @StrVendor='And Vendor = N'''+@Vendor+''' '
	end

	if isnull(@Grnno,'')<>''
	begin
		select @StrGrnNo='And GRNNo = N'''+@Grnno+''' '
	end

	IF ISNULL(@MaterialID,'')<>''
	BEGIN
		SELECT @StrMaterialID= 'And d1.materialid= N'''+@MaterialID+''' '
	END

	IF ISNULL(@partid,'')<>''
	BEGIN
		SELECT @StrPartID= 'And PartID= N'''+@partid+''' '
	END

	IF ISNULL(@Process,'')<>''
	BEGIN
		SELECT @StrProcess= 'And process= N'''+@Process+''' '
	END

	IF ISNULL(@AutoID,'')<>''
	BEGIN
		SELECT @StrAutoID='And Autoid in ('+@AutoID+')'
	end

	if isnull(@toprows,'')<>''
	begin
		select @strtoprows='top ('+@toprows+')'
	end

	if isnull(@Pams_DCNo,'')<>''
	begin
		select @strPamsDCNo='And Pams_DCNo =N'''+@Pams_DCNo+''' '
	END

	if @Param='OpenGRNView'
	begin
		select distinct g1.AutoID,g1.POId,g1.PONumber,g1.MaterialID,g1.InvoiceNumber,CASE WHEN G1.UOM='NO.' then g1.ReceivedQty_NUmbers else g1.ReceivedQty end as ReceivedQty,g1.GrnNo,
		g1.grnid,g1.GRNDate,g1.UpdatedTS,g1.type,g1.UpdatedBy,g1.Supplier,g1.OrderedQty,g1.GRNStatus,t1.UOM,m1.MJCNo as MJCNo,m1.UpdatedTS as MJCDate from MasterJobCardHeaderCreation_PAMS m1 
		left join   GrnNoGeneration_PAMS g1 on m1.GRNNo=g1.GrnNo
		left join (select distinct materialid,uom from RawMaterialDetails_PAMS)t1 on g1.MaterialID=t1.MaterialID
		WHERE g1.MaterialID=@MaterialID 
		AND (m1.GrnNo=@Grnno OR ISNULL(@Grnno,'')='') AND GRNStatus='Open' and qualitystatus='Inspection Completed'

		--select distinct g1.AutoID,g1.POId,g1.PONumber,g1.MaterialID,g1.InvoiceNumber,g1.ReceivedQty,g1.GrnNo,
		--g1.grnid,g1.GRNDate,g1.UpdatedTS,g1.type,g1.UpdatedBy,g1.Supplier,g1.OrderedQty,g1.GRNStatus,t1.UOM from GrnNoGeneration_PAMS  g1 
		--left join (select distinct materialid,uom from RawMaterialDetails_PAMS)t1 on g1.MaterialID=t1.MaterialID
		--WHERE g1.MaterialID=@MaterialID  AND (GrnNo=@Grnno OR ISNULL(@Grnno,'')='') AND GRNStatus='Open' --and qualitystatus='Inspection Completed'
	end

	--if @Param='GRNPendingQty'
	--BEGIN
	--	select @strsql=''
	--	select @strsql=@strsql+'Insert into #GRNPendingQty(GRNNo,OrderedQty,OrderedQty_Numbers) '
	--	SELECT @strsql=@strsql+'SELECT DISTINCT GRNNo,SUM(receivedqty),sum(ReceivedQty_NUmbers) FROM GrnNoGeneration_PAMS WHERE 1=1 '
	--	SELECT @strsql=@strsql+@StrGrnNo
	--	SELECT @strsql=@strsql+'Group BY GRNNo '
	--	PRINT(@STRSQL)
	--	EXEC(@STRSQL)

	--	UPDATE #GRNPendingQty SET IssuedQty_kg=isnull(T1.IssuedQty_kg,0),IssuedQty_Numbers=isnull(t1.IssuedQty_Numbers,0),uom=isnull(t1.uom,'')
	--	from
	--	(select distinct uom, GRNNO,SUM(Qty_KG) as IssuedQty_kg,sum(qty_numbers) as IssuedQty_Numbers FROM DCNoGeneration_PAMS where 
	--	DCStatus not in ('Discarded') and isnull(pjcno,'')='' group by GRNNO,uom
	--	) t1 inner join #GRNPendingQty g1 on g1.GRNNo=t1.GRNNo

	--	--UPDATE #GRNPendingQty SET IssuedQty_kg=isnull(T1.IssuedQty_kg,0),IssuedQty_Numbers=isnull(t1.IssuedQty_Numbers,0)
	--	--from
	--	--(select distinct  GRNNO,SUM(Qty_KG) as IssuedQty_kg,sum(qty_numbers) as IssuedQty_Numbers FROM DCNoGeneration_PAMS where 
	--	--DCStatus not in ('Discarded') and isnull(pjcno,'')='' group by GRNNO,uom
	--	--) t1 inner join #GRNPendingQty g1 on g1.GRNNo=t1.GRNNo


	--	--select distinct GRNNo,OrderedQty, case when uom='KG' THEN (OrderedQty-IssuedQty_kg) when uom is null then OrderedQty ELSE (OrderedQty-IssuedQty_Numbers) END as PendingQty from #GRNPendingQty
	--	select distinct GRNNo,OrderedQty, (OrderedQty-isnull(IssuedQty_kg,0)) as PendingQty_KG,(OrderedQty_Numbers-isnull(IssuedQty_Numbers,0)) as PendingQty_No from #GRNPendingQty

	--end

	if @Param='GRNPendingQty'
	BEGIN
		select @strsql=''
		select @strsql=@strsql+'Insert into #GRNPendingQty(GRNNo,OrderedQty,OrderedQty_Numbers) '
		SELECT @strsql=@strsql+'SELECT DISTINCT GRNNo,SUM(receivedqty),sum(ReceivedQty_NUmbers) FROM GrnNoGeneration_PAMS WHERE 1=1 '
		SELECT @strsql=@strsql+@StrGrnNo
		SELECT @strsql=@strsql+'Group BY GRNNo '
		PRINT(@STRSQL)
		EXEC(@STRSQL)

		UPDATE #GRNPendingQty SET IssuedQty_kg=isnull(T1.IssuedQty_kg,0),IssuedQty_Numbers=isnull(t1.IssuedQty_Numbers,0),uom=isnull(t1.uom,'')
		from
		(select distinct R.UOM, GRNNO,SUM(Qty_KG) as IssuedQty_kg,sum(qty_numbers) as IssuedQty_Numbers FROM DCNoGeneration_PAMS
		inner join RawMaterialDetails_PAMS R on DCNoGeneration_PAMS.MaterialID=R.MaterialID where 
		(DCStatus not in ('Discarded') and isnull(pjcno,'')='' and DCStatus in ('DC No. generated and confirmed'))
		group by GRNNO,R.UOM
		) t1 inner join #GRNPendingQty g1 on g1.GRNNo=t1.GRNNo

		UPDATE #GRNPendingQty SET MaterialUOM=t1.UOM
		from
		(select R.UOM FROM GrnNoGeneration_PAMS grn
		inner join RawMaterialDetails_PAMS R on grn.MaterialID=R.MaterialID and grn.GrnNo=@Grnno
		) t1

		--select distinct GRNNo,OrderedQty, case when uom='KG' THEN (OrderedQty-IssuedQty_kg) when uom is null then OrderedQty ELSE (OrderedQty-IssuedQty_Numbers) END as PendingQty from #GRNPendingQty
		select distinct GRNNo,OrderedQty, (OrderedQty-isnull(IssuedQty_kg,0)) as PendingQty_KG,(OrderedQty_Numbers-isnull(IssuedQty_Numbers,0)) as PendingQty_No, MaterialUOM as uom from #GRNPendingQty

	end

	if @Param='GRNConfirmedPendingQty'
	BEGIN
		select @strsql=''
		select @strsql=@strsql+'Insert into #GRNPendingQty(DCNO,GRNNo,OrderedQty,uom) '
		SELECT @strsql=@strsql+'SELECT DISTINCT D1.Pams_DCNo,D2.GRNNo,SUM(D2.receivedqty),d1.uom FROM DCNoGeneration_PAMS d1 inner join GrnNoGeneration_PAMS d2 on d1.GRNNo=d2.grnno WHERE 1=1 '
		SELECT @strsql=@strsql+@strPamsDCNo
		SELECT @strsql=@strsql+'Group BY D1.Pams_DCNo,D2.GRNNo,d1.uom '
		PRINT(@STRSQL)
		EXEC(@STRSQL)

		UPDATE #GRNPendingQty SET IssuedQty_kg=isnull(T1.IssuedQty,0),IssuedQty_Numbers=ISNULL(T1.IssuedQty_Numbers,0)
		from
		(select distinct GRNNO,SUM(Qty_KG) as IssuedQty,SUM(qty_numbers) AS IssuedQty_Numbers,UOM FROM DCNoGeneration_PAMS 
		where DCStatus  in ('DC No. generated and confirmed') 
		group by GRNNO,UOM
		) t1 inner join #GRNPendingQty g1 on g1.GRNNo=t1.GRNNo

		

		UPDATE #GRNPendingQty SET IssuedQty_kg=ISNULL(IssuedQty_kg,0)+ISNULL(t1.ISUQty_kg,0),IssuedQty_Numbers=isnull(IssuedQty_Numbers,0)+isnull(t1.ISUQty_Numbers,0)
		from
		(
		select distinct Pams_DCNo,GRNNo,sum(Qty_KG) as ISUQty_kg,sum(qty_numbers) as ISUQty_Numbers from DCNoGeneration_PAMS
		group by Pams_DCNo,GRNNo
		)t1 inner join #GRNPendingQty g2 on t1.Pams_DCNo=g2.DCNO and t1.GRNNo=g2.GRNNo


		select distinct GRNNo,OrderedQty,IssuedQty_kg,IssuedQty_Numbers,uom  from #GRNPendingQty
	end

	if @param='DCIssueDetailsView'
	begin
		select @strsql=''
		select @strsql=@strsql+'insert into #Temp( Vendor,GRNNo,MaterialID,PartID,process,Qty_KG,Qty_Numbers,HSNCode,uom,bin,Value,
		Pams_DCNo,DCDate,Pams_DCID,UpdatedBy,UpdatedTS,DCType,JobCardType,MJCNo,PJCNo,employee,MaterialRequestNo,RequestedBy,PJCYear) '
		select @strsql=@strsql+'select distinct d1.Vendor,d1.GRNNo,d1.MaterialID,d1.PartID,d1.process,d1.Qty_KG,d1.Qty_Numbers,r1.HSNCode,d1.uom,d1.bin,d1.Value,
		d1.Pams_DCNo,d1.DCDate,d1.Pams_DCID,d1.UpdatedBy,d1.UpdatedTS,d1.DCType,d1.JobCardType,d1.MJCNo,d1.PJCNo,d1.employee,d1.MaterialRequestNo,d1.RequestedBy,d1.PJCYear from DCNoGeneration_PAMS d1  left join RawMaterialDetails_PAMS r1 on d1.MaterialID=r1.MaterialID where 1=1 '
		select @strsql=@strsql+@StrVendor+@StrGrnNo+@StrMaterialID+@StrPartID+@StrProcess+@strPamsDCNo
		print(@strsql)
		exec(@strsql)

		select  Vendor,GRNNo,MaterialID, PartID ,process,Qty_KG, Qty_Numbers,HSNCode,uom ,bin ,Value,Pams_DCNo,DCDate ,Pams_DCID ,UpdatedBy,UpdatedTS ,
		DCType,JobCardType,MJCNo,PJCNo,employee,MaterialRequestNo,RequestedBy,PJCYear from #Temp	
	end

	IF @Param='DCHistoryView'
	begin

		select @strsql=''
		select @strsql=@strsql+'select * from DCGateEntryDetails_PAMS where 1=1 '
		select @strsql=@strsql+@StrGrnNo
		print(@strsql)
		exec(@strsql)

		select @strsql=''
		select @strsql=@strsql+'insert into #Temp( Vendor,GRNNo,MaterialID,PartID,process,Qty_KG,Qty_Numbers,HSNCode,uom,bin,Value,
		Pams_DCNo,DCDate,Pams_DCID,UpdatedBy,UpdatedTS,dcstatus,DCType,JobCardType,MJCNo,PJCNo,MaterialRequestNo,RequestedBy,PJCYear) '
		select @strsql=@strsql+'select distinct d1.Vendor,d1.GRNNo,d1.MaterialID,d1.PartID,d1.process,d1.Qty_KG,d1.Qty_Numbers,r1.HSNCode,d1.uom,d1.bin,d1.Value,
		d1.Pams_DCNo,d1.DCDate,d1.Pams_DCID,d1.UpdatedBy,d1.UpdatedTS,d1.dcstatus,d1.DCType,d1.JobCardType,d1.MJCNo,d1.PJCNo,d1.MaterialRequestNo,d1.RequestedBy,d1.PJCYear from DCNoGeneration_PAMS d1  left join RawMaterialDetails_PAMS r1 on d1.MaterialID=r1.MaterialID 
		where 1=1 and dcstatus=''DC No. generated and confirmed'' '
		select @strsql=@strsql+@StrVendor+@StrGrnNo+@StrMaterialID+@StrPartID+@StrProcess
		print(@strsql)
		exec(@strsql)

		select  Vendor,GRNNo,MaterialID, PartID ,process,Qty_KG, Qty_Numbers,HSNCode,uom ,bin ,Value,Pams_DCNo,DCDate ,Pams_DCID ,UpdatedBy,UpdatedTS,DCType,JobCardType,MJCNo,PJCNo,MaterialRequestNo,RequestedBy,PJCYear from #Temp

	end


	if @Param='DCDetailsSave'
	begin
		if not exists(select * from DCNoGeneration_PAMS where vendor=@Vendor and GRNNo=@Grnno and MaterialID=@MaterialID and PartID=@partid and process=@Process AND Pams_DCNo=@Pams_DCNo and isnull(mjcno,'')=isnull(@mjcno,'') and isnull(pjcno,'')=isnull(@pjcno,''))
		BEGIN
		--if not exists(select * from DCNoGenerationTemp_PAMS where Pams_DCNo=@Pams_DCNo)
		--begin
		--	insert into DCNoGenerationTemp_PAMS(DocumentType,Pams_DCNo,JobCardType,DCType,UpdatedBy,UpdatedTS)values(@DocumentType,@Pams_DCNo,@JobCardType,@DCType,@UpdatedBy,@UpdatedTS)
		--end
			INSERT INTO DCNoGeneration_PAMS(Vendor,GRNNo,MaterialID,PartID,process,Qty_KG,Qty_Numbers,HSNCode,uom,bin,Value,UpdatedBy,UpdatedTS,Pams_DCNo,DCDate,Pams_DCID,dcstatus,JobCardType,DCType,MJCNo,PJCNo,Employee,MaterialRequestNo,RequestedBy,PJCYear)
			VALUES(@Vendor,@Grnno,@MaterialID,@partid,@Process,@Qty_KG,@Qty_Numbers,@HSNCode,@uom,@bin,@Value,@UpdatedBy,@UpdatedTS,@Pams_DCNo,@DCDate,@Pams_DCID,case when isnull(@DCStatus,'')='' then 'DCIssued' else @DCStatus end,@JobCardType,@DCType,@MJCNo,@PJCNo,@Employee,@MaterialRequestNo,@RequestedBy,@PJCYear)
		end
		else
		begin
			update DCNoGeneration_PAMS set Qty_KG=@Qty_KG,Qty_Numbers=@Qty_Numbers,UpdatedBy=@UpdatedBy,UpdatedTS=@UpdatedTS,bin=@Bin,Value=@Value,RequestedBy=@RequestedBy,MaterialRequestNo=@MaterialRequestNo
			where vendor=@Vendor and GRNNo=@Grnno and MaterialID=@MaterialID and PartID=@partid and process=@Process AND Pams_DCNo=@Pams_DCNo and isnull(mjcno,'')=isnull(@mjcno,'') and isnull(pjcno,'')=isnull(@pjcno,'')
		end
	end


	if @Param='DCNoDetailsView'
	begin
		select distinct * from DCNoGeneration_PAMS where Vendor=@Vendor and Pams_DCNo=@Pams_DCNo 
	end

	if @param='Viewtop10Records'
	begin
		select @strsql=''
		select @strsql=@strsql+'select distinct '+@strtoprows +'Pams_DCID,Pams_dcno,convert(nvarchar(10),DCDate,126) as DCDate,DCStatus,updatedby from DCNoGeneration_PAMS where Vendor='''+@Vendor+''' and 
		(convert(nvarchar(10),DCDate,126)='''+convert(nvarchar(10),@date,126)+''') and dcstatus not in (''Discarded'')
		order by Dcdate asc '
		print(@strsql)
		exec(@strsql)
	end

	if @Param='DeleteDC'
	BEGIN
		DELETE FROM DCNoGeneration_PAMS WHERE AutoID=@AutoID
	end

	if @Param='UpdatePamsDCStatus'
	begin
		SELECT @strsql=''
		SELECT @strsql=@strsql+'UPDATE DCNoGeneration_PAMS set DCStatus='''+@DCStatus+''' where 1=1 '
		select @strsql=@strsql+@strPamsDCNo
		print(@strsql)
		exec(@strsql)

		UPDATE EWayBillDetails_Pams set DCStatus=@DCStatus
		where Pams_DCNO=@Pams_DCNO
		
	end

	if @Param='DCSplitSave'
	begin
		update DCNoGeneration_PAMS set Qty_KG=@Qty_KG, Qty_Numbers=@Qty_Numbers where Vendor=@Vendor and Pams_DCNo=@Pams_DCNo and MaterialID=@MaterialID 
		and PartID=@partid and process=@Process and MJCNo=@MJCNo and isnull(pjcno,'')=isnull(@pjcno,'') 

		insert into DCNoGeneration_PAMS(Vendor,GRNNo,MaterialID,PartID,Process,Qty_KG,Qty_Numbers,HSNCode,uom,bin,Value,Pams_DCNo,DCDate,UpdatedBy,UpdatedTS,Pams_DCID,DCStatus,DCType,MJCNo,PJCNo,PJCYear,Price)
		select Vendor,GRNNo,MaterialID,@NewPartID,@NewProcess,@NewQty_KG,@NewQty_Numbers,HSNCode,uom,@Bin,@Value,Pams_DCNo,DCDate,@UpdatedBy,@UpdatedTS,Pams_DCID,DCStatus,@DCType,MJCNo,@NewPJCNo,@NewPJCYear,Price from DCNoGeneration_PAMS
		where Vendor=@Vendor and Pams_DCNo=@Pams_DCNo and MaterialID=@MaterialID and PartID=@partid and process=@Process and isnull(pjcno,'')=isnull(@pjcno,'') and isnull(PJCYear,'')=isnull(@PJCYear,'')
	end


	---------------------------------------------------------------------Adding into new temp table before generating pams_dcno logic starts------------------------------------------------------------------------------------------

		if @Param='DCDetailsSave_NewTemp'
		begin
			if not exists(select * from DCNoGeneration_NewTemp_PAMS where vendor=@Vendor and GRNNo=@Grnno and MaterialID=@MaterialID and PartID=@partid and process=@Process AND UserID=@UserID and isnull(mjcno,'')=isnull(@mjcno,'') and isnull(pjcno,'')=isnull(@pjcno,''))
			BEGIN
				INSERT INTO DCNoGeneration_NewTemp_PAMS(Vendor,GRNNo,MaterialID,PartID,process,Qty_KG,Qty_Numbers,HSNCode,uom,bin,Value,UpdatedBy,UpdatedTS,dcstatus,JobCardType,DCType,MJCNo,PJCNo,Employee,MaterialRequestNo,RequestedBy,PJCYear,UserID)
				VALUES(@Vendor,@Grnno,@MaterialID,@partid,@Process,@Qty_KG,@Qty_Numbers,@HSNCode,@uom,@bin,@Value,@UpdatedBy,@UpdatedTS,case when isnull(@DCStatus,'')='' then 'DCIssued' else @DCStatus end,@JobCardType,@DCType,@MJCNo,@PJCNo,@Employee,@MaterialRequestNo,@RequestedBy,@PJCYear,@UserID)
			end
			else
			begin
				update DCNoGeneration_NewTemp_PAMS set Qty_KG=@Qty_KG,Qty_Numbers=@Qty_Numbers,UpdatedBy=@UpdatedBy,UpdatedTS=@UpdatedTS,bin=@Bin,Value=@Value,RequestedBy=@RequestedBy,MaterialRequestNo=@MaterialRequestNo
				where vendor=@Vendor and GRNNo=@Grnno and MaterialID=@MaterialID and PartID=@partid and process=@Process AND UserID=@UserID and isnull(mjcno,'')=isnull(@mjcno,'') and isnull(pjcno,'')=isnull(@pjcno,'')
			end
		end

		if @Param='DCNoDetailsView_NewTemp'
		begin
			select distinct * from DCNoGeneration_NewTemp_PAMS where Vendor=@Vendor and UserID=@UserID
		end

		if @param='DCIssueDetailsView_NewTemp'
		begin
			select @strsql=''
			select @strsql=@strsql+'insert into #Temp( Vendor,GRNNo,MaterialID,PartID,process,Qty_KG,Qty_Numbers,HSNCode,uom,bin,Value,
			UpdatedBy,UpdatedTS,DCType,JobCardType,MJCNo,PJCNo,employee,MaterialRequestNo,RequestedBy,PJCYear) '
			select @strsql=@strsql+'select distinct d1.Vendor,d1.GRNNo,d1.MaterialID,d1.PartID,d1.process,d1.Qty_KG,d1.Qty_Numbers,r1.HSNCode,d1.uom,d1.bin,d1.Value,
			d1.UpdatedBy,d1.UpdatedTS,d1.DCType,d1.JobCardType,d1.MJCNo,d1.PJCNo,d1.employee,d1.MaterialRequestNo,d1.RequestedBy,d1.PJCYear from DCNoGeneration_NewTemp_PAMS d1  left join RawMaterialDetails_PAMS r1 on d1.MaterialID=r1.MaterialID where 1=1 and d1.userid='''+@UserID+''' '
			select @strsql=@strsql+@StrVendor+@StrGrnNo+@StrMaterialID+@StrPartID+@StrProcess
			print(@strsql)
			exec(@strsql)

			select  Vendor,GRNNo,MaterialID, PartID ,process,Qty_KG, Qty_Numbers,HSNCode,uom ,bin ,Value,Pams_DCNo,DCDate ,Pams_DCID ,UpdatedBy,UpdatedTS ,
			DCType,JobCardType,MJCNo,PJCNo,employee,MaterialRequestNo,RequestedBy,PJCYear from #Temp	
		end

		if @param='DCDetailsPushToMain_NewTemp'
		begin
		
			INSERT INTO DCNoGeneration_PAMS(Vendor,GRNNo,MaterialID,PartID,process,Qty_KG,Qty_Numbers,HSNCode,uom,bin,Value,UpdatedBy,UpdatedTS,Pams_DCNo,DCDate,Pams_DCID,dcstatus,JobCardType,DCType,MJCNo,PJCNo,Employee,MaterialRequestNo,RequestedBy,PJCYear)
			select distinct @Vendor,GRNNo,MaterialID,PartID,process,Qty_KG,Qty_Numbers,HSNCode,uom,bin,Value,@UpdatedBy,@UpdatedTS,@Pams_DCNo,@DCDate,@Pams_DCID,@dcstatus,JobCardType,DCType,MJCNo,PJCNo,Employee,MaterialRequestNo,RequestedBy,PJCYear  from DCNoGeneration_NewTemp_PAMS
			where Autoid in (select item from SplitString(@autoid,','))

			DELETE FROM DCNoGeneration_NewTemp_PAMS WHERE Autoid in (select item from SplitString(@autoid,','))

		end

		if @Param='DeleteDC_NewTemp'
		BEGIN
			DELETE FROM DCNoGeneration_NewTemp_PAMS WHERE AutoID=@AutoID
		end

	---------------------------------------------------------------------Adding into new temp table before generating pams_dcno logic ends------------------------------------------------------------------------------------------

end
