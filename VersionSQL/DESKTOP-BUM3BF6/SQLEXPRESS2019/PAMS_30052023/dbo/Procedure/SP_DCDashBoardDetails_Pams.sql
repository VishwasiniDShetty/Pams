/****** Object:  Procedure [dbo].[SP_DCDashBoardDetails_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

/*
SP_DCDashBoardDetails_Pams @PamsDCNo=N'',@FromDate=N'2022-01-23 00:00:00.000',@ToDate=N'2023-05-24 00:00:00.000',@MaterialID=N'',@PartID=N'',@Type=N''
*/
CREATE procedure [dbo].[SP_DCDashBoardDetails_Pams]
@PamsDCNo nvarchar(50)='',
@FromDate datetime='',
@ToDate datetime='',
@MaterialID NVARCHAR(50)='',
@PartID NVARCHAR(50)='',
@Type nvarchar(50)='',
@Process nvarchar(50)='',
@Vendor nvarchar(50)=''
AS
BEGIN

	create table #Temp
	(
	DCDate datetime,
	PamsDCId INT,
	PamsDCNo nvarchar(50),
	VendorID NVARCHAR(50),
	VendorName nvarchar(50),
	PartID NVARCHAR(50),
	MaterialID NVARCHAR(50),
	MaterialDescription nvarchar(100),
	HSNCode nvarchar(50),
	Process nvarchar(2000),
	GRNNo nvarchar(2000),
	VendorDCNo NVARCHAR(100),
	VendorDCDate datetime,
	SentQty_Kg float,
	SentQty_No float,
	Balance float,
	DCQty_KG float,
	DCQty_No float,
	ReceivedQty_kg float,
	ReceivedQty_No float,
	MJCNo nvarchar(50),
	PJCNo nvarchar(50),
	Remarks nvarchar(2000),
	Specification nvarchar(50),
	Sent_Uom nvarchar(50),
	Received_UOM NVARCHAR(50),
	StoresTS DATETIME,
	QualityTS DATETIME,
	ReceivedQtySum_kg float,
	ReceivedQtySum_No float,
	DCStatus nvarchar(100),
	DCCloseStatus nvarchar(50),
	DCCloseRemarks  nvarchar(2000),
	DCGateExitBit int default 0,
	PJCQty float default 0
	)





	DECLARE @StrPamsDCNo nvarchar(3000)
	declare @StrMaterialID NVARCHAR(3000)
	DECLARE @StrPartID NVARCHAR(3000)
	DECLARE @StrVendorType NVARCHAR(3000)
	DECLARE @StrProcess NVARCHAR(3000)
	declare @StrVendor nvarchar(3000)
	DECLARE @Strsql nvarchar(max)

	select @StrPamsDCNo=''
	select @StrMaterialID=''
	select @StrPartID=''
	select @StrVendorType=''
	select @Strsql=''
	select @StrVendor=''
	select @StrProcess=''

	if isnull(@PamsDCNo,'')<>''
	begin
		select @StrPamsDCNo='And d1.PamsDCNo in ('+@PamsDCNo+')'
	end

	if isnull(@MaterialID,'')<>''
	begin
		select @StrMaterialID='And d1.MaterialID like ''%'+@MaterialID+'%'''
	END

	if isnull(@PartID,'')<>''
	begin
		select @StrPartID='And d1.PartID like ''%'+@PartID+'%'''
	END

	if isnull(@Type,'')='Internal'
	begin
		
		select @StrVendorType='And d1.vendor in (''PAMS Internal'') '
	end

	if isnull(@Type,'')='External'
	begin
		
		select @StrVendorType='And d1.vendor not in (''PAMS Internal'') '
	end
	if isnull(@process,'')<>''
	begin
		select @StrProcess='And d1.Process like ''%'+@Process+'%'''
	end
	if isnull(@vendor,'')<>''
	begin
		select @StrVendor='And d1.vendor like ''%'+@Vendor+'%'''
	end



	select @Strsql=''
	select @Strsql=@Strsql+'Insert into #Temp(DCDate,DCQty_KG,DCQty_No,SentQty_No,SentQty_Kg,PamsDCId, PamsDCNo,VendorID,VendorName,PartID,MaterialID,MaterialDescription,HSNCode,Process,GRNNo,PJCNo,Specification,MJCNo,Sent_Uom,VendorDCNo,
	VendorDCDate,ReceivedQty_kg,ReceivedQty_No,Remarks,Received_UOM,DCStatus,DCCloseStatus,DCCloseRemarks,DCGateExitBit,PJCQty )'
	select @Strsql=@Strsql+'select distinct d1.DCDate,d1.qty_kg,d1.Qty_Numbers,d1.Qty_Numbers,d1.qty_kg,D1.Pams_DCID,d1.Pams_DCNo,d1.Vendor,V1.Vendorname,d1.PartID,D1.MaterialID,R1.MaterialDescription,R1.HSNCode,D1.Process,D1.GRNNo,d1.pjcno,r1.Specification,d1.MJCNo,D1.Uom ,
	d2.VendorDCNo,d2.VendorDCDate,d2.ReceivedQty_kg,d2.ReceivedQty_No,d2.Remarks,d2.Received_UOM,d1.DCStatus,d1.DCCloseStatus,d1.DCCloseRemarks,d3.DCGateExitBit,pjcqty  from DCNoGeneration_PAMS D1 
	left join (select distinct PamsDCNo,MaterialID,PartID,Vendor,process,GRNNo,MJCNo,PJCNo,VendorDCNo,VendorDCDate,Qty_KG as ReceivedQty_kg,Qty_Numbers as ReceivedQty_No,Remarks,UOM as Received_UOM,pjcqty  from DCStoresDetails_PAMS) d2
	on  d1.Pams_DCNo=d2.PamsDCNo and d1.MaterialID=d2.MaterialID and d1.PartID=d2.PartID and d1.Vendor=d2.Vendor and d1.Process=d2.Process and d1.GRNNo=d2.GRNNo and isnull(d1.MJCNo,'''')=isnull(d2.MJCNo,'''') 
	and isnull(d1.PJCNo,'''')=isnull(d2.pjcno,'''')
	left join (select distinct PamsDCNumber,''1'' AS DCGateExitBit from DCGateExitDetails_PAMS) d3 on d1.Pams_DCNo=d3.PamsDCNumber
	LEFT JOIN RawMaterialDetails_PAMS R1 ON D1.MaterialID=R1.MaterialID
	left join VendorDetails_PAMS v1 on v1.vendorid=d1.vendor
	where 1=1 
	and convert(nvarchar(10),dcdate,126)>='''+convert(nvarchar(10),@FromDate,126)+''' and convert(nvarchar(10),dcdate,126)<='''+convert(nvarchar(10),@ToDate,126)+''' '
	select @Strsql=@Strsql+@StrPamsDCNo+@StrMaterialID+@StrPartID+@StrVendorType+@StrProcess+@StrVendor
	print(@strsql)
	exec(@strsql)


	UPDATE #Temp SET StoresTS=ISNULL(T1.UpdatedTS_Stores,'')
	from
	(
	select distinct PamsDCNo,MaterialID,PartID,process,GRNNo,MJCNo,PJCNo,VendorDCNo,VendorDCDate,UpdatedTS_Stores  from DCStoresDetails_PAMS
	) t1 inner join #Temp t2 on t1.PamsDCNo=t2.PamsDCNo and t1.MaterialID=t2.MaterialID and t1.PartID=t2.PartID and t1.Process=t2.Process and t1.MJCNo=t2.MJCNo and isnull(t1.PJCNo,'')=isnull(t2.PJCNo,'') and t1.VendorDCNo=t2.VendorDCNo


		UPDATE #Temp SET QualityTS=ISNULL(T1.UpdatedTS,'')
	from
	(
	select distinct Pams_DCNo,ComponentID,process,MJCNo,PJCNo,VendorDCNo,UpdatedTS  from FinalInspectionTransactionFG_PAMS
	) t1 inner join #Temp t2 on t1.Pams_DCNo=t2.PamsDCNo and  t1.ComponentID=t2.PartID and t1.Process=t2.Process and t1.MJCNo=t2.MJCNo and isnull(t1.PJCNo,'')=isnull(t2.PJCNo,'') and t1.VendorDCNo=t2.VendorDCNo


	update #Temp set ReceivedQtySum_kg=isnull(t1.ReceivedQtySum_kg,0),ReceivedQtySum_No=isnull(t1.ReceivedQtySum_No,0)
	from
	(
	select distinct PamsDCNo,Vendor,MaterialID,PartID,Process,GRNNo,MJCNo,isnull(pjcno,'') as Pjcnno,sum(Qty_KG) as ReceivedQtySum_kg,sum(Qty_Numbers) as ReceivedQtySum_No from DCStoresDetails_PAMS
	group by PamsDCNo,Vendor,MaterialID,PartID,Process,GRNNo,MJCNo,isnull(pjcno,'')
	) t1 inner join #Temp t2 on t1.PamsDCNo=t2.PamsDCNo and t1.Vendor=t2.VendorID and t1.MaterialID=t2.MaterialID and t1.PartID=t2.PartID and t1.Process=t2.Process 
	and t1.GRNNo=t2.GRNNo and t1.MJCNo=t2.MJCNo and isnull(t1.Pjcnno,'')=isnull(t2.pjcno,'')


		select 	t1.DCDate ,t1.PamsDCNo ,t1.VendorID ,t1.VendorName ,t1.PartID ,t1.MaterialID ,t1.MaterialDescription ,t1.HSNCode,t1.GRNNo,t1.SentQty_Kg,t1.SentQty_No,t1.Process,PJCNo,
		case when VendorDCDate='1900-01-01 00:00:00.000' then null else VendorDCDate end as VendorDCDate,VendorDCNo,DCQty_KG ,DCQty_No ,ReceivedQty_kg,
		case when isnull(pjcqty,'')<>'' then pjcqty else ReceivedQty_No end as ReceivedQty_No,
	case when isnull(DCQty_No,0)> =isnull(pjcqty,0) then (isnull(DCQty_No,0)-isnull(pjcqty,0))  else  (isnull(ReceivedQty_No,0)-isnull(DCQty_No,0)) end as Shortage_ExcessQty,
	isnull(SentQty_No,0)-isnull(DCQty_No,0) as Balance,
	Remarks ,Specification,Sent_Uom,Received_UOM,t2.Sequence,ReceivedQtySum_kg,ReceivedQtySum_No,StoresTS,QualityTS,DCStatus,DCCloseStatus,DCCloseRemarks,isnull(DCGateExitBit,0) as DCGateExitBit
	from #Temp t1
	left join (select distinct PartID,Process,Sequence from ProcessAndFGAssociation_PAMS ) t2 on t1.PartID=t2.PartID and t1.Process=t2.Process
	order by PamsDCId
	--order by t1.MaterialID,t1.PartID,t2.Sequence 
	return

	--select 	t1.DCDate ,t1.PamsDCNo ,t1.VendorID ,t1.VendorName ,t1.PartID ,t1.MaterialID ,t1.MaterialDescription ,t1.HSNCode,t1.GRNNo,t1.SentQty_Kg,t1.SentQty_No,t1.Process,PJCNo,case when VendorDCDate='1900-01-01 00:00:00.000' then null else VendorDCDate end as VendorDCDate,VendorDCNo,DCQty_KG ,DCQty_No ,ReceivedQty_kg ,ReceivedQty_No,
	--case when isnull(DCQty_No,0)> =isnull(ReceivedQty_No,0) then (isnull(DCQty_No,0)-isnull(ReceivedQty_No,0))  else  (isnull(ReceivedQty_No,0)-isnull(DCQty_No,0)) end as Shortage_ExcessQty,
	--isnull(SentQty_No,0)-isnull(DCQty_No,0) as Balance,
	--Remarks ,Specification,Sent_Uom,Received_UOM,t2.Sequence,ReceivedQtySum_kg,ReceivedQtySum_No,StoresTS,QualityTS,DCStatus,DCCloseStatus,DCCloseRemarks,isnull(DCGateExitBit,0) as DCGateExitBit
	--from #Temp t1
	--left join (select distinct PartID,Process,Sequence from ProcessAndFGAssociation_PAMS ) t2 on t1.PartID=t2.PartID and t1.Process=t2.Process
	--order by PamsDCId
	----order by t1.MaterialID,t1.PartID,t2.Sequence 
	--return


		--update #Temp set VendorDCNo=isnull(t1.VendorDCNo,''),VendorDCDate=isnull(t1.VendorDCDate,''),ReceivedQty_kg=isnull(t1.ReceivedQty_kg,''),ReceivedQty_No=isnull(t1.ReceivedQty_No,''),Remarks=isnull(t1.Remarks,''),Received_UOM=ISNULL(T1.Received_UOM,'')
	--from
	--(
	--select distinct PamsDCNo,MaterialID,PartID,Vendor,process,GRNNo,MJCNo,PJCNo,VendorDCNo,VendorDCDate,Qty_KG as ReceivedQty_kg,Qty_Numbers as ReceivedQty_No,Remarks,UOM as Received_UOM  from DCStoresDetails_PAMS
	--) t1 inner join #Temp t2 on t1.PamsDCNo=t2.PamsDCNo and t1.MaterialID=t2.MaterialID and t1.PartID=t2.PartID and t1.Vendor=t2.VendorID and t1.Process=t2.Process and t1.GRNNo=t2.GRNNo and isnull(t1.MJCNo,'')=isnull(t2.MJCNo,'') 
	--and isnull(t1.PJCNo,'')=isnull(t2.pjcno,'')



	--select @Strsql=''
	--select @Strsql=@Strsql+'Insert into #Temp(PamsDCNo,VendorID,VendorName,PartID,MaterialID,MaterialDescription,HSNCode,Process,GRNNo ,VendorDCNo,VendorDCDate,ReceivedQty_kg,ReceivedQty_No,PJCNo,Remarks,Specification,MJCNo,Received_UOM)'
	--select @Strsql=@Strsql+'select distinct PamsDCNo,d1.Vendor,V1.Vendorname,PartID,D1.MaterialID,R1.MaterialDescription,R1.HSNCode,D1.Process,D1.GRNNo,D1.VendorDCNo,D1.VendorDCDate,D1.Qty_KG,D1.Qty_Numbers,d1.pjcno, d1.remarks,r1.Specification,d1.MJCNo,D1.Uom from DCStoresDetails_PAMS D1 
	--						LEFT JOIN RawMaterialDetails_PAMS R1 ON D1.MaterialID=R1.MaterialID
	--						left join VendorDetails_PAMS v1 on v1.vendorid=d1.vendor
	--						where 1=1 
	--						and convert(nvarchar(10),VendorDCDate,126)>='''+convert(nvarchar(10),@FromDate,126)+''' and convert(nvarchar(10),VendorDCDate,126)<='''+convert(nvarchar(10),@ToDate,126)+''' '
	--select @Strsql=@Strsql+@StrPamsDCNo+@StrMaterialID+@StrPartID
	--print(@strsql)
	--exec(@strsql)


	--update #Temp set DCDate=isnull(t1.DCDate,''),DCQty_KG=isnull(t1.qty_kg,''),DCQty_No=isnull(Qty_Numbers,''),SentQty_No=isnull(t1.Qty_Numbers,''),SentQty_Kg=isnull(t1.qty_kg,''),Sent_Uom=ISNULL(T1.UOM,'')
	--from
	--(
	--select distinct DCDate,Pams_DCNo,MaterialID,PartID,Vendor,Process,GRNNo,isnull(MJCNo,'') as MJCNo,isnull(PJCNo,'') as PJCNo,sum(qty_kg) as qty_kg,sum(Qty_Numbers) as Qty_Numbers,UOM from DCNoGeneration_PAMS
	--group by DCDate,Pams_DCNo,MaterialID,PartID,Vendor,Process,GRNNo,MJCNo,PJCNo,UOM
	--) t1 inner join #Temp t2 on t1.Pams_DCNo=t2.PamsDCNo and t1.MaterialID=t2.MaterialID and t1.PartID=t2.PartID and t1.Vendor=t2.VendorID and t1.Process=t2.Process and t1.GRNNo=t2.GRNNo and isnull(t1.MJCNo,'')=isnull(t2.MJCNo,'') 
	--and isnull(t1.PJCNo,'')=isnull(t2.pjcno,'')

	--select 	DCDate ,PamsDCNo ,VendorID ,VendorName ,PartID ,MaterialID ,MaterialDescription ,HSNCode,GRNNo,SentQty_Kg,SentQty_No,Process,PJCNo,VendorDCDate,VendorDCNo,DCQty_KG ,DCQty_No ,ReceivedQty_kg ,ReceivedQty_No,
	--case when isnull(DCQty_No,0)> =isnull(ReceivedQty_No,0) then (isnull(DCQty_No,0)-isnull(ReceivedQty_No,0))  else  (isnull(ReceivedQty_No,0)-isnull(DCQty_No,0)) end as Shortage_ExcessQty,
	--isnull(SentQty_No,0)-isnull(DCQty_No,0) as Balance,
	--Remarks ,Specification,Sent_Uom,Received_UOM
	--from #Temp
	--order by PamsDCNo,DCDate,VendorDCDate
	--return









	--	select @Strsql=''
	--select @Strsql=@Strsql+'Insert into #Temp(PamsDCNo,VendorID,VendorName,PartID,MaterialID,MaterialDescription,HSNCode,Process)'
	--select @Strsql=@Strsql+'select distinct PamsDCNo,d1.Vendor,V1.Vendorname,PartID,D1.MaterialID,R1.MaterialDescription,R1.HSNCode,D1.Process from DCStoresDetails_PAMS D1 
	--						LEFT JOIN RawMaterialDetails_PAMS R1 ON D1.MaterialID=R1.MaterialID
	--						left join VendorDetails_PAMS v1 on v1.vendorid=d1.vendor
	--						where 1=1 
	--						and convert(nvarchar(10),VendorDCDate,126)>='''+convert(nvarchar(10),@FromDate,126)+''' and convert(nvarchar(10),VendorDCDate,126)<='''+convert(nvarchar(10),@ToDate,126)+''' '
	--select @Strsql=@Strsql+@StrPamsDCNo+@StrMaterialID+@StrPartID
	--print(@strsql)
	--exec(@strsql)

	--	update #Temp set ReceivedQty_No=isnull(t1.qty_kg,''),ReceivedQty_kg=isnull(t1.Qty_Numbers,'')
	--from
	--(
	--select distinct  PamsDCNo,MaterialID,PartID,Vendor,Process,sum(qty_kg) as qty_kg,sum(Qty_Numbers) as Qty_Numbers from DCStoresDetails_PAMS
	--group by PamsDCNo,MaterialID,PartID,Vendor,Process
	--) t1 inner join #Temp t2 on t1.PamsDCNo=t2.PamsDCNo and t1.MaterialID=t2.MaterialID and t1.PartID=t2.PartID and t1.Vendor=t2.VendorID and t1.Process=t2.Process 


	--	update #Temp set DCDate=isnull(t1.DCDate,''),DCQty_KG=isnull(t1.qty_kg,''),DCQty_No=isnull(Qty_Numbers,''),SentQty_No=isnull(t1.Qty_Numbers,''),SentQty_Kg=isnull(t1.qty_kg,'')
	--from
	--(
	--select distinct DCDate,Pams_DCNo,MaterialID,PartID,Vendor,Process,GRNNo,isnull(MJCNo,'') as MJCNo,isnull(PJCNo,'') as PJCNo,sum(qty_kg) as qty_kg,sum(Qty_Numbers) as Qty_Numbers from DCNoGeneration_PAMS
	--group by DCDate,Pams_DCNo,MaterialID,PartID,Vendor,Process,GRNNo,MJCNo,PJCNo
	--) t1 inner join #Temp t2 on t1.Pams_DCNo=t2.PamsDCNo and t1.MaterialID=t2.MaterialID and t1.PartID=t2.PartID and t1.Vendor=t2.VendorID and t1.Process=t2.Process and t1.GRNNo=t2.GRNNo and isnull(t1.MJCNo,'')=isnull(t2.MJCNo,'') 
	--and isnull(t1.PJCNo,'')=isnull(t2.pjcno,'')


	--update #Temp set GRNNo=isnull(t1.GRNNo,''),VendorDCNo=isnull(t1.VendorDCNo,''),PJCNo=isnull(t1.pjcno,''),VendorDCDate=isnull(t1.VendorDCDate,'')
	--from
	--(
	--select distinct t.PamsDCNo,t.vendor,t.MaterialID,t.PartID,t.process,STUFF((SELECT distinct ',' + a1.grnno
 --        from DCStoresDetails_PAMS a1 
	--	 where a1.PamsDCNo=t.PamsDCNo and a1.vendor=t.vendor and a1.MaterialID=t.MaterialID and a1.PartID=t.PartID and a1.Process=t.process
 --           FOR XML PATH(''), TYPE
 --           ).value('.', 'NVARCHAR(MAX)') 
 --       ,1,1,'') GRNNo,
	--	STUFF((SELECT distinct ',' + a1.PJCNo
 --        from DCStoresDetails_PAMS a1 
	--	 where a1.PamsDCNo=t.PamsDCNo and a1.vendor=t.vendor and a1.MaterialID=t.MaterialID and a1.PartID=t.PartID and a1.Process=t.process
 --           FOR XML PATH(''), TYPE
 --           ).value('.', 'NVARCHAR(MAX)') 
 --       ,1,1,'') PjcNo,
	--	STUFF((SELECT distinct ',' + a1.VendorDCNo
 --        from DCStoresDetails_PAMS a1 
	--	 where a1.PamsDCNo=t.PamsDCNo and a1.vendor=t.vendor and a1.MaterialID=t.MaterialID and a1.PartID=t.PartID and a1.Process=t.process
 --           FOR XML PATH(''), TYPE
 --           ).value('.', 'NVARCHAR(MAX)') 
 --       ,1,1,'') VendorDCNo,
	--			STUFF((SELECT distinct ',' + a1.VendorDCDate
 --        from DCStoresDetails_PAMS a1 
	--	 where a1.PamsDCNo=t.PamsDCNo and a1.vendor=t.vendor and a1.MaterialID=t.MaterialID and a1.PartID=t.PartID and a1.Process=t.process
 --           FOR XML PATH(''), TYPE
 --           ).value('.', 'NVARCHAR(MAX)') 
 --       ,1,1,'') VendorDCDate,
 --STUFF((SELECT distinct ',' + a1.Remarks
 --        from DCStoresDetails_PAMS a1 
	--	 where a1.PamsDCNo=t.PamsDCNo and a1.vendor=t.vendor and a1.MaterialID=t.MaterialID and a1.PartID=t.PartID and a1.Process=t.process
 --           FOR XML PATH(''), TYPE
 --           ).value('.', 'NVARCHAR(MAX)') 
 --       ,1,1,'') Remarks
	--	from DCStoresDetails_PAMS t 
	--	)t1 inner join #Temp t2 on t1.PamsDCNo=t2.PamsDCNo and t1.Vendor=t2.VendorID and t1.MaterialID=t2.MaterialID and t1.PartID=t2.PartID and t1.Process=t2.Process



END
