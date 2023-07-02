/****** Object:  Procedure [dbo].[SP_PJCReportDetails_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

/*
exec SP_PJCReportDetails_Pams @MJCNo=N'RM/GRN/13/2023-24',@PJCNo=N'14'
*/
CREATE procedure [dbo].[SP_PJCReportDetails_Pams]
@MJCNo nvarchar(50)='',
@PJCNo nvarchar(50)=''
as
begin
	create table #PJCProcessList
	(
	AutoID BIGINT IDENTITY(1,1),
	MJCNo nvarchar(50),
	PJCNo nvarchar(50),
	PJCYear nvarchar(50),
	PartID NVARCHAR(50),
	Process nvarchar(2000),
	ProcessType nvarchar(50),
	Sequence int
	)

	Create table #FinalResult
	(
	MJCNo nvarchar(50),
	PJCNo nvarchar(50),
	PJCYear nvarchar(50),
	PartID NVARCHAR(50),
	Process nvarchar(2000),
	ProcessType nvarchar(50),
	Sequence int,
	Date datetime,
	Shift nvarchar(50),
	DCIssued_ProdQty float default 0,
	RejQty float default 0,
	ReworkQty float default 0,
	AcceptedQty float default 0,
	QualityPerson nvarchar(50) default '',
	QualityTs datetime default '',
	Stores_LineInchargeName nvarchar(50) default '',
	Stores_LineInchargeTS DATETIME default '',
	dcPJCBit nvarchar(50),
	PamsDC_NO NVARCHAR(50)
	)

	CREATE TABLE #FinalInspection
	(
	MJCNo nvarchar(50),
	PJCNo nvarchar(50),
	PJCYear nvarchar(50),
	PartID NVARCHAR(50),
	ProductionDate datetime,
	QualityDate datetime,
	QtyOfferedForInspection float,
	ReworkQty float,
	RejQty float,
	AcceptedQty float,
	UpdatedBy_Quality nvarchar(50),
	BatchBit int
	)


	create table #pamsdcno
	(
	AutoID bigint identity(1,1),
	PamsDCNo nvarchar(max)
	)
	


	insert into #PJCProcessList(MJCNo,PJCNo,PJCYear, PartID,Process,Sequence,ProcessType)
	select distinct p1.MJCNo,p1.PJCNo,p1.PJCYear,p1.PartID,p2.Process,p2.Sequence,p2.DCType from ProcessJobCardHeaderCreation_PAMS p1 
	inner join ProcessAndFGAssociation_PAMS p2 on p1.PartID=p2.PartID
	where MJCNo=@MJCNo and PJCNo=@PJCNo
	ORDER BY Sequence

	declare @PartID NVARCHAR(50)
	declare @PJCYear NVARCHAR(50)
	declare @MaterialID NVARCHAR(50)
	DECLARE @PartDescription nvarchar(50)

	SELECT @PartID=(SELECT distinct  PartID FROM #PJCProcessList)
	select @PJCYear=(select distinct PJCYear from #PJCProcessList)
	SELECT @MaterialID=(SELECT DISTINCT MATERIALID FROM RawMaterialAndFGAssociation_PAMS WHERE PartID=@PartID)
	select @PartDescription=(select distinct MaterialDescription from RawMaterialDetails_PAMS where MaterialID=@MaterialID)

	declare @i int
	declare @MaxCount int

	select @i=1
	select @MaxCount=(select isnull(max(autoid),0) as rowid from #PJCProcessList)


	WHILE(@I<=@MaxCount)
	BEGIN
		declare @CurrentProcessType nvarchar(50)
		declare @CurrentProcess nvarchar(50)
		select @CurrentProcessType=(select processtype from #PJCProcessList where AutoID=@i)
		select @CurrentProcess=(select process from #PJCProcessList where AutoID=@i)
		print @i


		if @CurrentProcessType='VendoredOut'
		begin
			print @CurrentProcessType
			print @CurrentProcess
			INSERT INTO #FinalResult(MJCNo,PJCNo,PJCYear,PartID,Process,ProcessType,Sequence,Date,DCIssued_ProdQty,RejQty,ReworkQty,AcceptedQty ,QualityPerson ,QualityTs,Stores_LineInchargeName ,Stores_LineInchargeTS,PamsDC_NO)
			select distinct p1.MJCNo,p1.PJCNo,p1.pjcyear,p1.PartID,p1.Process,p1.ProcessType,p1.Sequence,d1.DCDate,d1.Qty_Numbers,D2.RejQty,'' AS ReworkQty,(ISNULL(D2.Qty_Numbers,0)-ISNULL(D2.RejQty,0)) AS AcceptedQty,
			d2.UpdatedBy_Quality,d2.UpdatedTS_Quality,d2.UpdatedBy_Stores,d2.UpdatedTS_Stores,D1.Pams_DCNo from #PJCProcessList p1
			left join DCNoGeneration_PAMS d1 on isnull(p1.MJCNo,'')=isnull(d1.MJCNo,'') and isnull(p1.PJCNo,'')=isnull(d1.PJCNo,'') and isnull(p1.PJCYear,'')=isnull(d1.PJCYear,'') and p1.PartID=d1.PartID and p1.Process=d1.Process
			left join DCStoresDetails_PAMS d2 on d1.MaterialID=D2.MaterialID AND D1.PartID=D2.PartID AND D1.Pams_DCNo=D2.PamsDCNo AND D1.Process=D2.Process AND isnull(D1.MJCNo,'')=isnull(D2.MJCNo,'') AND isnull(D1.PJCNo,'')=isnull(D2.PJCNo,'') AND isnull(D1.PJCYear,'')=isnull(D2.PJCYear,'')
			where p1.AutoID=@i

			update #FinalResult set dcPJCBit=isnull(t1.pjcno,'')
			from
			(
			select distinct MJCNo,PJCNo,PJCYear,Process,dcdate,MaterialID,PartID,Pams_DCNo from DCNoGeneration_PAMS
			) T1 INNER JOIN #FinalResult T2 ON ISNULL(T1.MJCNo,'')=ISNULL(T2.MJCNo,'') AND ISNULL(T1.PJCNo,'')=ISNULL(T2.PJCNo,'') AND  ISNULL(T1.PJCYear,'')=ISNULL(T2.PJCYear,'') AND 
			ISNULL(T1.Process,'')=ISNULL(T2.Process,'') AND ISNULL(T1.dcdate,'')=ISNULL(T2.Date,'') AND  ISNULL(T1.PartID,'')=ISNULL(T2.PartID,'') AND ISNULL(T1.Pams_DCNo,'')=ISNULL(T2.PamsDC_NO,'')
		end
		else
		begin
			print @CurrentProcessType
			print @CurrentProcess

			INSERT INTO #FinalResult(MJCNo,PJCNo,PJCYear,PartID,Process,ProcessType,Sequence,Date,Shift,DCIssued_ProdQty,AcceptedQty,QualityPerson,QualityTs,Stores_LineInchargeName,Stores_LineInchargeTS)
			select distinct p1.MJCNo,p1.PJCNo,p1.PJCYear,p1.PartID,p1.Process,p1.ProcessType,p1.Sequence,d1.Date,d1.Shift,sum(d1.Prod_Qty),sum(d1.AcceptedQty),max(qualityincharge),max(quality_ts),max(lineincharge),max(lineincharge_ts)  from #PJCProcessList p1
			left join PJCProductionEditedDetails_PAMS d1 on p1.MJCNo=d1.MJCNo and p1.PJCNo=d1.PJCNo and p1.PartID=d1.PartID and p1.Process=d1.Process AND P1.PJCYear=('20'+D1.PJCYear)
			where p1.AutoID=@i
			group by p1.MJCNo,p1.PJCNo,p1.PJCYear,p1.PartID,p1.Process,p1.ProcessType,p1.Sequence,d1.date,d1.shift

			update #FinalResult set RejQty=isnull(t1.RejQty,0)
			from
			(
			select distinct p1.date,p1.shift,p1.partid,p1.MjcNo,p1.PJCNo,p1.PJCYear,p1.process,sum(p1.RejectionQty) as  rejqty from PJCRejectionDetails_PAMS p1
			inner join #FinalResult p2 on p1.Date=p2.date and p1.Shift=p2.Shift and p1.partid=p2.partid and p1.MjcNo=p2.MjcNo and p1.PJCNo=p2.PJCNo and ('20'+p1.PJCYear)=p2.PJCYear and p1.process=p2.process
			group by p1.date,p1.shift,p1.partid,p1.MjcNo,p1.PJCNo,p1.PJCYear,p1.process
			) t1 inner join #FinalResult p2 on t1.Date=p2.Date and t1.Shift=p2.Shift and t1.PartID=p2.PartID and t1.MjcNo=p2.MJCNo and t1.PJCNo=p2.PJCNo and ('20'+t1.PJCYear)=p2.PJCYear and t1.Process=p2.Process

			update #FinalResult set ReworkQty=isnull(t1.ReworkQty,0)
			from
			(
			select distinct p1.date,p1.shift,p1.partid,p1.MjcNo,p1.PJCNo,p1.PJCYear,p1.process,sum(p1.MarkedForReworkQty)-(sum(RejectionQty)+sum(OKQty)) as  ReworkQty from PJCMarkedForReworkDetails_PAMS p1
			inner join #FinalResult p2 on p1.Date=p2.date and p1.Shift=p2.Shift and p1.partid=p2.partid and p1.MjcNo=p2.MjcNo and p1.PJCNo=p2.PJCNo and ('20'+p1.PJCYear)=p2.PJCYear and p1.process=p2.process
			group by p1.date,p1.shift,p1.partid,p1.MjcNo,p1.PJCNo,p1.PJCYear,p1.process
			) t1 inner join #FinalResult p2 on t1.Date=p2.Date and t1.Shift=p2.Shift and t1.PartID=p2.PartID and t1.MjcNo=p2.MJCNo and t1.PJCNo=p2.PJCNo and ('20'+t1.PJCYear)=p2.PJCYear and t1.Process=p2.Process
			

		end

	SELECT @I=@I+1
	END


	UPDATE #FinalResult SET dcPJCBit='WithoutPJC' WHERE ProcessType='VendoredOut' and isnull(dcPJCBit,0)=0

	select MJCNo,PJCNo,PJCYear,PartID ,Process ,ProcessType ,Sequence,Date,isnull(Shift,'') as Shift ,isnull(DCIssued_ProdQty,0) as DCIssued_ProdQty ,isnull(RejQty,0) as  RejQty,isnull(ReworkQty,0) as  ReworkQty,
	isnull(AcceptedQty,0) as AcceptedQty ,isnull(QualityPerson,'') as  QualityPerson,isnull(Stores_LineInchargeName,'') as  Stores_LineInchargeName,QualityTs ,
	Stores_LineInchargeTS,dcPJCBit from #FinalResult where ISNULL(process,'')<>'FG' and isnull(process,'')<>'Rework And Return' and isnull(dcPJCBit,0)<>'WithoutPJC' order by Sequence asc
end

	insert into #FinalInspection(MJCNo,PJCNo,PJCYear,PartID,ProductionDate,QualityDate,QtyOfferedForInspection,AcceptedQty,UpdatedBy_Quality,BatchBit)
	SELECT DISTINCT p1.MJCNo,p1.PJCNo,p1.PJCYear,p1.PartID,p2.UpdatedTSProduction,p2.UpdatedTSQuality,p2.AcptQtyForInspection,p2.AcceptedQtyFromInspection,p2.UpdatedByQuality,p2.batchbit  FROM #PJCProcessList P1 INNER JOIN 
	(SELECT DISTINCT MJCNo,PJCNo,PJCYear,PartID,UpdatedTSProduction,UpdatedTSQuality,BatchBit, sum(AcptQtyForInspection) as AcptQtyForInspection,sum(AcceptedQtyFromInspection) as AcceptedQtyFromInspection, max(UpdatedByQuality) as UpdatedByQuality FROM InspectionReadyDetailsSave_Pams
	group by MJCNo,PJCNo,PJCYear,PartID,UpdatedTSProduction,UpdatedTSQuality,BatchBit) p2 
	on p1.MJCNo=p2.MJCNo and p1.PJCNo=p2.PJCNo and p1.PJCYear=('20'+p2.PJCYear) and p1.PartID=p2.PartID

	update #FinalInspection set RejQty=isnull(t1.RejQty,0)
	from
	(
	select distinct q1.PartID,q1.MJCNo,q1.PJCNo,q1.PJCYear,q1.UpdatedTSProduction,q1.BatchBit, sum(RejectionQty) as RejQty  from QualityRejectionDetails_Pams q1
	inner join #FinalInspection f2 on q1.PartID=f2.PartID and q1.MJCNo=f2.MJCNo and q1.PJCNo=f2.PJCNo and ('20'+q1.PJCYear)=f2.PJCYear and q1.UpdatedTSProduction=f2.ProductionDate and q1.BatchBit=f2.BatchBit
	group by q1.PartID,q1.MJCNo,q1.PJCNo,q1.PJCYear,q1.UpdatedTSProduction,q1.BatchBit
	) t1 inner join #FinalInspection  t2 on t1.PartID=t2.PartID and t1.MJCNo=t2.MJCNo and t1.PJCNo=t2.PJCNo and ('20'+t1.PJCYear)=t2.PJCYear and t1.UpdatedTSProduction=t2.ProductionDate and t1.BatchBit=t2.BatchBit


		update #FinalInspection set ReworkQty=isnull(t1.ReworkQty,0)
	from
	(
	select distinct q1.PartID,q1.MJCNo,q1.PJCNo,q1.PJCYear,q1.UpdatedTSProduction,q1.BatchBit, sum(distinct q1.MarkedForReworkQty)-(sum(q1.RejectionQty)+sum(OkQty)) as ReworkQty  from QualityReworkDetails_Pams q1
	inner join #FinalInspection f2 on q1.PartID=f2.PartID and q1.MJCNo=f2.MJCNo and q1.PJCNo=f2.PJCNo and ('20'+q1.PJCYear)=f2.PJCYear and q1.UpdatedTSProduction=f2.ProductionDate and q1.BatchBit=f2.BatchBit
	group by q1.PartID,q1.MJCNo,q1.PJCNo,q1.PJCYear,q1.UpdatedTSProduction,q1.BatchBit
	) t1 inner join #FinalInspection  t2 on t1.PartID=t2.PartID and t1.MJCNo=t2.MJCNo and t1.PJCNo=t2.PJCNo and ('20'+t1.PJCYear)=t2.PJCYear and t1.UpdatedTSProduction=t2.ProductionDate and t1.BatchBit=t2.BatchBit


	select 'Final Inspection' as Process, MJCNo,PJCNo,PJCYear,PartID,QualityDate,isnull(QtyOfferedForInspection,0) as QtyOfferedForInspection,isnull(ReworkQty,0) as ReworkQty ,isnull(RejQty,0) as RejQty,isnull(AcceptedQty,0) as AcceptedQty,UpdatedBy_Quality from #FinalInspection

	select 'Dispatch' as Process, d1.* from DispatchDetails_Pams d1 where PartID=@PartID and PJCNo=@PJCNo and ('20'+PJCYear)=@PJCYear

	select * from ProcessJobCardHeaderCreation_PAMS where PartID=@PartID and MJCNo=@MJCNo and PJCNo=@PJCNo and PJCYear=@PJCYear


	---------------------------------------------------------------------Show coma seperated Pams_DCNo-----------------------------------------------------------------------------------------------------------------------------
	insert into #pamsdcno(PamsDCNo)
	select distinct Pams_DCNo FROM DCNoGeneration_PAMS d1 
	inner join ProcessAndFGAssociation_PAMS d2 on d1.PartID=d2.PartID and d1.Process=d2.Process
	where MJCNo=@MJCNo and PJCNo=@PJCNo  and isnull(d2.DisplayPamsDCNo,0)=1



	declare @StrPamsDC nvarchar(max)
	declare @query nvarchar(max)
	select @StrPamsDC=COALESCE(@StrPamsDC+',','')+(PamsDCNo) 
	from (select distinct(PamsDCNo) from #pamsdcno ) as d 

	select @StrPamsDC AS Pams_DCNo
