/****** Object:  Procedure [dbo].[SP_InspectionDetailsSaveAndView_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

/*
SP_InspectionDetailsSaveAndView_PAMS @Param=N'View',@PartID=N'N6070010',@FromDate=N'2023-02-01 14:59:21.000',@ToDate=N'2023-02-06 14:59:21.000'
*/
CREATE procedure [dbo].[SP_InspectionDetailsSaveAndView_PAMS]
@PJCNo nvarchar(50)='',
@PJCYear nvarchar(10)='',
@PartID NVARCHAR(50)='',
@OperationNo nvarchar(50)='',
@AcceptedQty nvarchar(50)='',
@RejQty nvarchar(50)='',
@ReworkQty nvarchar(50)='',
@UpdatedByProduction nvarchar(50)='',
@UpdatedTSProduction datetime='',
@UpdatedByQuality nvarchar(50)='',
@UpdatedTSQuality nvarchar(50)='',
@AcptQtyForInspection float=0,
@PendingQtyForInspection float=0,
@FromDate datetime='',
@ToDate datetime='',
@BatchBit int=0,
@Param nvarchar(50)='',
@MJCNo nvarchar(50)='',
@ReworkReason nvarchar(500)='',
@UpdatedBy nvarchar(50)='',
@RejectionReason nvarchar(500)='',
@AcceptedQtyFromInspection float=0,
@UpdatedTS datetime='',
@ConfirmedReceiveQty  float=0,
@PJCAutoID bigint=0,
@OfferToFG  float=0,
@process nvarchar(50)='',
@Rework_Rej_Bit bit =0,
@ReworkDate datetime='',
@ReworkShift nvarchar(50)='',
@ReworkOperator nvarchar(50)='',
@ReworkMachine nvarchar(50)=''

as
begin

create table #QualityView
(
AutoID BIGINT,
PartID NVARCHAR(50),
OperationNo nvarchar(50),
MJCNo nvarchar(50),
PJCNo nvarchar(50),
PJCYear nvarchar(50),
ProdAcceptedQty float,
MarkedForReworkQty float,
ReworkOk float,
RejQty float,
AcceptedQty float,
UpdatedByProduction NVARCHAR(50),
UpdatedTSProduction datetime,
UpdatedByQuality nvarchar(50),
UpdatedTSQuality datetime,
BatchBit int,
SentQtyForInspection float,
AcceptedQtyFromInspection float,
PendingQtyForInspection float,
PJCStatus nvarchar(50),
ConfirmedReceiveQty float,
PJCAutoID bigint,
OfferedToFGQty float,
InspectionSaveBit int

)

create table #SentForInspection
(
PartID NVARCHAR(50),
OperationNo nvarchar(50),
MJCNo nvarchar(50),
PJCNo nvarchar(50),
PJCYear nvarchar(50),
SavedBatchBits nvarchar(max),
Status nvarchar(50)
)

	if isnull(@ReworkDate,'')=''
	begin
		set @ReworkDate=null
	end


	if @Param='Save'
	begin
		if not exists(select * from InspectionReadyDetailsSave_Pams WHERE UpdatedTSProduction=@UpdatedTSProduction AND  PartID=@PartID AND OperationNo=@OperationNo and PJCNo=@PJCNo and PJCYear=@PJCYear and BatchBit=@BatchBit)
		begin
			insert into InspectionReadyDetailsSave_Pams(PartID,OperationNo,PJCNo ,PJCYear ,AcceptedQty ,RejQty ,ReworkQty ,UpdatedByProduction,UpdatedTSProduction,BatchBit,AcptQtyForInspection,PendingQtyForInspection,AcceptedQtyFromInspection,MJCNo,ConfirmedReceiveQty,PJCAutoID )
			values(@PartID,@OperationNo,@PJCNo,@PJCYear,@AcceptedQty,@RejQty,@ReworkQty,@UpdatedByProduction,@UpdatedTSProduction,@BatchBit,@AcptQtyForInspection,@PendingQtyForInspection,@AcceptedQtyFromInspection,@MJCNo,@ConfirmedReceiveQty,@PJCAutoID )
		end
		else
		begin
			update InspectionReadyDetailsSave_Pams set UpdatedByQuality=@UpdatedByQuality,UpdatedTSQuality=@UpdatedTSQuality,AcptQtyForInspection=@AcptQtyForInspection,PendingQtyForInspection=@PendingQtyForInspection,AcceptedQtyFromInspection=@AcceptedQtyFromInspection --,ConfirmedReceiveQty=@ConfirmedReceiveQty
			 WHERE UpdatedTSProduction=@UpdatedTSProduction AND  PartID=@PartID AND OperationNo=@OperationNo and PJCNo=@PJCNo and PJCYear=@PJCYear and BatchBit=@BatchBit and MJCNo=@MJCNo
		end
	end

		if @Param='ConfirmReceiveQty'
	begin
		if exists(select * from InspectionReadyDetailsSave_Pams WHERE UpdatedTSProduction=@UpdatedTSProduction AND  PartID=@PartID AND OperationNo=@OperationNo and PJCNo=@PJCNo and PJCYear=@PJCYear and BatchBit=@BatchBit)
		begin
			update InspectionReadyDetailsSave_Pams set UpdatedByQuality=@UpdatedByQuality,UpdatedTSQuality=@UpdatedTSQuality,ConfirmedReceiveQty=@ConfirmedReceiveQty,PendingQtyForInspection=@PendingQtyForInspection
			 WHERE UpdatedTSProduction=@UpdatedTSProduction AND  PartID=@PartID AND OperationNo=@OperationNo and PJCNo=@PJCNo and PJCYear=@PJCYear and BatchBit=@BatchBit and MJCNo=@MJCNo
		end
	end

		if @Param='UpdateOfferedToFG'
	begin
		if exists(select * from InspectionReadyDetailsSave_Pams WHERE UpdatedTSProduction=@UpdatedTSProduction AND  PartID=@PartID AND OperationNo=@OperationNo and PJCNo=@PJCNo and PJCYear=@PJCYear and BatchBit=@BatchBit)
		begin
			update InspectionReadyDetailsSave_Pams set OfferedToFGQty= isnull(OfferedToFGQty,0)+ isnull(@OfferToFG,0)
			 WHERE UpdatedTSProduction=@UpdatedTSProduction AND  PartID=@PartID AND OperationNo=@OperationNo and PJCNo=@PJCNo and PJCYear=@PJCYear and BatchBit=@BatchBit and MJCNo=@MJCNo
		end
	end


	if @param='View'
	begin
		insert into #QualityView(AutoID,PartID,OperationNo,MJCNo,PJCNo,PJCYear,ProdAcceptedQty,UpdatedByProduction,
		UpdatedTSProduction,UpdatedByQuality,UpdatedTSQuality,BatchBit,SentQtyForInspection,AcceptedQtyFromInspection,PendingQtyForInspection,ConfirmedReceiveQty,PJCAutoID,OfferedToFGQty)
		select I1.AutoID,i1.PartID,i1.OperationNo,i1.MJCNo,i1.PJCNo,i1.PJCYear,i1.AcceptedQty,i1.UpdatedByProduction,i1.UpdatedTSProduction,i1.UpdatedByQuality,i1.UpdatedTSQuality,i1.BatchBit,
		i1.AcptQtyForInspection,i1.AcceptedQtyFromInspection,i1.PendingQtyForInspection,i1.ConfirmedReceiveQty,i1.PJCAutoID,i1.OfferedToFGQty from InspectionReadyDetailsSave_Pams i1
		--left join FinalInspectionTransactionFGLevel_PAMS f1 on i1.partid=f1.componentid and i1.operationno=f1.operationno and i1.pjcno=f1.pjcno and i1.pjcyear=f1.pjcyear 
		where partid like '%'+@partid+'%' and
		(convert(nvarchar(10),UpdatedTSProduction,126)>=convert(nvarchar(10),@fromdate,126) and convert(nvarchar(10),UpdatedTSProduction,126)<=convert(nvarchar(10),@todate,126))
		order by i1.UpdatedTSProduction ASC, i1.BatchBit ASC


		update #QualityView set MarkedForReworkQty=isnull(t1.MarkedForReworkQty,0)
		from
		(
		select distinct partid,OperationNo,MJCNo,PJCNo,PJCYear,UpdatedTSProduction,BatchBit,sum(MarkedForReworkQty) as MarkedForReworkQty from QualityReworkDetails_Pams
		group by partid,OperationNo,MJCNo,PJCNo,PJCYear,UpdatedTSProduction,BatchBit
		) t1 inner join #QualityView t2 on t1.PartID=t2.PartID and t1.OperationNo=t2.OperationNo and t1.MJCNo=t2.MJCNo and t1.PJCNo=t2.PJCNo and t1.PJCYear=t2.PJCYear and t1.UpdatedTSProduction=t2.UpdatedTSProduction
		and t1.BatchBit=t2.BatchBit


		----------------------------------------------------------------------------Calc of ReworkRejection begins-------------------------------------------------------------------------------------------------
	
		update #QualityView set ReworkOk=isnull(t1.ReworkOk,0)
		from
		(
		select distinct  partid,OperationNo,MJCNo,PJCNo,PJCYear,UpdatedTSProduction,BatchBit,sum(ReworkPerformed_Ok) as ReworkOk  from QualityReworkPerformedDetails_Pams
		group by partid,OperationNo,MJCNo,PJCNo,PJCYear,UpdatedTSProduction,BatchBit
		) t1 inner join #QualityView t2 on t1.PartID=t2.PartID and t1.OperationNo=t2.OperationNo and t1.MJCNo=t2.MJCNo and t1.PJCNo=t2.PJCNo and t1.PJCYear=t2.PJCYear and t1.UpdatedTSProduction=t2.UpdatedTSProduction
		and t1.BatchBit=t2.BatchBit
		----------------------------------------------------------------------------Calc of ReworkRejection ends-------------------------------------------------------------------------------------------------

		update #QualityView set RejQty=isnull(t1.RejQty,0)
		from
		(
		select distinct  partid,OperationNo,MJCNo,PJCNo,PJCYear,UpdatedTSProduction,BatchBit,sum(RejectionQty) as RejQty  from QualityRejectionDetails_Pams
		group by partid,OperationNo,MJCNo,PJCNo,PJCYear,UpdatedTSProduction,BatchBit
		) t1 inner join #QualityView t2 on t1.PartID=t2.PartID and t1.OperationNo=t2.OperationNo and t1.MJCNo=t2.MJCNo and t1.PJCNo=t2.PJCNo and t1.PJCYear=t2.PJCYear and t1.UpdatedTSProduction=t2.UpdatedTSProduction
		and t1.BatchBit=t2.BatchBit


		UPDATE #QualityView SET PJCStatus=ISNULL(T1.PJCStatus,'')
		FROM
		(
		SELECT DISTINCT PartID,MJCNo,PJCNo, pjcyear,PJCStatus FROM ProcessJobCardHeaderCreation_PAMS
		) T1 INNER JOIN #QualityView T2 ON T1.PartID=T2.PartID AND T1.MJCNo=T2.MJCNo AND T1.PJCNo=T2.PJCNo AND T1.PJCYear=('20'+T2.PJCYear)

		UPDATE #QualityView SET InspectionSaveBit=ISNULL(T1.InspectionSaveBit,0)
		FROM
		(
		SELECT DISTINCT ComponentID,OperationNo,PJCNo,PJCYear,date,BatchBit,1 as InspectionSaveBit FROM InspectionTransactionFinalFGLevel_PAMS
		) T1 INNER JOIN #QualityView T2 ON T1.ComponentID=T2.PartID AND T1.OperationNo=T2.OperationNo AND T1.PJCNo=T2.PJCNo AND  T1.PJCYear=t2.PJCYear and t1.Date=t2.UpdatedTSProduction --and t1.BatchBit=t2.BatchBit

		--update #QualityView set AcceptedQtyFromInspection=isnull(t1.AcceptedQtyFromInspection,0)
		--from
		--(
		-- select distinct  partid,OperationNo,MJCNo,PJCNo,PJCYear,UpdatedTSProduction,BatchBit,(isnull(SentQtyForInspection,0)-(isnull(MarkedForReworkQty,0)-isnull(ReworkOk,0))-isnull(RejQty,0)) as AcceptedQtyFromInspection from #QualityView
		--) t1 inner join #QualityView t2 on t1.partid=t2.partid  and t1.OperationNo= t2.OperationNo and t1.MJCNo=t2.MJCNo and t1.PJCNo=t2.PJCNo  and t1.PJCYear=t2.PJCYear and t1.UpdatedTSProduction=t2.UpdatedTSProduction  and t1.BatchBit=t2.BatchBit


		select  distinct * from #QualityView order by UpdatedTSProduction asc,BatchBit,PartID,PJCNo

		insert into #SentForInspection(PartID,PJCNo,PJCYear,OperationNo,MJCNo,SavedBatchBits)
		select distinct q1.partid,q1.pjcno,q1.PJCYear,q1.OperationNo,q1.MJCNo,q2.BatchBit from #QualityView q1 left join (select distinct ComponentID,PJCNo,PJCYear,BatchBit from InspectionTransactionFinalFGLevel_PAMS)q2
		on q1.PartID=q2.ComponentID and q1.PJCNo=q2.PJCNo and q1.PJCYear=q2.PJCYear

		update #SentForInspection set Status=isnull(t1.status,'')
		from
		(
		select distinct ComponentID,PJCNo,PJCYear,BatchBit, isnull(status,'Pending') as  status from FinalInspectionTransactionFGLevel_PAMS
		) t1 inner join #SentForInspection t2 on t1.ComponentID=t2.PartID and t1.PJCNo=t2.PJCNo AND T1.PJCYear=T2.PJCYear AND T1.BatchBit=T2.SavedBatchBits




		SELECT * FROM #SentForInspection

	end

	if @Param='QualityRejectionSave'
	begin
		if not exists(select * from QualityRejectionDetails_Pams where PartID=@PartID and OperationNo=@OperationNo and MJCNo=@MJCNo and PJCNo=@PJCNo and PJCYear=@pjcyear and UpdatedTSProduction=@UpdatedTSProduction and BatchBit=@BatchBit and UpdatedTS=@UpdatedTS)
		begin
			insert into QualityRejectionDetails_Pams(PartID,OperationNo,MJCNo,PJCNo,PJCYear,RejectionQty,RejectionReason,UpdatedTSProduction,UpdatedBy,UpdatedTS,BatchBit,Rework_Rej_Bit)
			values(@PartID,@OperationNo,@MJCNo,@PJCNo,@PJCYear,@RejQty,@RejectionReason,@UpdatedTSProduction,@UpdatedBy,getdate(),@BatchBit,@Rework_Rej_Bit)
		end
		else
		begin
			update QualityRejectionDetails_Pams set RejectionQty=@RejQty,RejectionReason=@RejectionReason,UpdatedBy=@UpdatedBy,UpdatedTS=getdate()
			where PartID=@PartID and OperationNo=@OperationNo and MJCNo=@MJCNo and PJCNo=@PJCNo and PJCYear=@PJCYear and UpdatedTSProduction=@UpdatedTSProduction and BatchBit=@BatchBit
		end

		update InspectionReadyDetailsSave_Pams set AcceptedQtyFromInspection=@AcceptedQtyFromInspection 
		WHERE UpdatedTSProduction=@UpdatedTSProduction AND  PartID=@PartID AND OperationNo=@OperationNo and PJCNo=@PJCNo and PJCYear=@PJCYear and BatchBit=@BatchBit 
	end

	if @Param='QualityReworkSave'
	begin
		if not exists(select  * from QualityReworkDetails_Pams where PartID=@PartID and OperationNo=@OperationNo and MJCNo=@MJCNo and PJCNo=@PJCNo and PJCYear=@pjcyear and UpdatedTSProduction=@UpdatedTSProduction and BatchBit=@BatchBit and UpdatedTS=@UpdatedTS)
		begin
			insert into QualityReworkDetails_Pams(PartID,OperationNo,MJCNo,PJCNo,PJCYear,MarkedForReworkQty,ReworkReason,RejectionQty,OkQty,UpdatedTSProduction,UpdatedBy,UpdatedTS,BatchBit,process)
			values(@PartID,@OperationNo,@MJCNo,@PJCNo,@PJCYear,@ReworkQty,@ReworkReason,@RejQty,@AcceptedQty,@UpdatedTSProduction,@UpdatedBy,GETDATE(),@BatchBit,@process)
		end
		else
		begin
			update QualityReworkDetails_Pams set MarkedForReworkQty=@ReworkQty,ReworkReason=@ReworkReason,RejectionQty=@RejQty,OkQty=@AcceptedQty,UpdatedBy=@UpdatedBy,UpdatedTS=getdate()
			where PartID=@PartID and OperationNo=@OperationNo and MJCNo=@MJCNo and PJCNo=@PJCNo and PJCYear=@pjcyear and UpdatedTSProduction=@UpdatedTSProduction and BatchBit=@BatchBit
		end

		update InspectionReadyDetailsSave_Pams set AcceptedQtyFromInspection=@AcceptedQtyFromInspection 
		WHERE UpdatedTSProduction=@UpdatedTSProduction AND  PartID=@PartID AND OperationNo=@OperationNo and PJCNo=@PJCNo and PJCYear=@PJCYear and BatchBit=@BatchBit 

	end


	if @Param='SaveReworkPerformedQty'
	begin
		if not exists(select  * from QualityReworkPerformedDetails_Pams where PartID=@PartID and OperationNo=@OperationNo and MJCNo=@MJCNo and PJCNo=@PJCNo and PJCYear=@pjcyear and UpdatedTSProduction=@UpdatedTSProduction and BatchBit=@BatchBit and UpdatedTS=@UpdatedTS
		AND ReworkDate=@ReworkDate and ReworkShift=@ReworkShift and ReworkOperator=@ReworkOperator and ReworkMachine=@ReworkMachine)
		begin
			insert into QualityReworkPerformedDetails_Pams(PartID,OperationNo,MJCNo,PJCNo,PJCYear,ReworkPerformed_Ok,UpdatedTSProduction,UpdatedBy,UpdatedTS,BatchBit,ReworkDate,ReworkShift,ReworkOperator,ReworkMachine,ReworkPerformed_Qty)
			values(@PartID,@OperationNo,@MJCNo,@PJCNo,@PJCYear,@AcceptedQty,@UpdatedTSProduction,@UpdatedBy,GETDATE(),@BatchBit,@ReworkDate,@ReworkShift,@ReworkOperator,@ReworkMachine,@ReworkQty)
		end
		else
		begin
			update QualityReworkPerformedDetails_Pams set ReworkPerformed_Ok=@AcceptedQty,UpdatedBy=@UpdatedBy,UpdatedTS=getdate(),ReworkPerformed_Qty=@ReworkQty
			where PartID=@PartID and OperationNo=@OperationNo and MJCNo=@MJCNo and PJCNo=@PJCNo and PJCYear=@pjcyear and UpdatedTSProduction=@UpdatedTSProduction and BatchBit=@BatchBit
			AND ReworkDate=@ReworkDate and ReworkShift=@ReworkShift and ReworkOperator=@ReworkOperator and ReworkMachine=@ReworkMachine
		end
	end

	if @Param='ReworkDetails'
	begin
		select * from QualityReworkDetails_Pams where PartID=@PartID and OperationNo=@OperationNo and MJCNo=@MJCNo and PJCNo=@PJCNo and PJCYear=@pjcyear and UpdatedTSProduction=@UpdatedTSProduction and BatchBit=@BatchBit

		select * from QualityRejectionDetails_Pams where PartID=@PartID and OperationNo=@OperationNo and MJCNo=@MJCNo and PJCNo=@PJCNo and PJCYear=@pjcyear and UpdatedTSProduction=@UpdatedTSProduction and BatchBit=@BatchBit and isnull(Rework_Rej_Bit,0)=1

		select * from QualityReworkPerformedDetails_Pams where PartID=@PartID and OperationNo=@OperationNo and MJCNo=@MJCNo and PJCNo=@PJCNo and PJCYear=@pjcyear and UpdatedTSProduction=@UpdatedTSProduction and BatchBit=@BatchBit

	end

		if @Param='RejectionDetails'
	begin

		select * from QualityRejectionDetails_Pams where PartID=@PartID and OperationNo=@OperationNo and MJCNo=@MJCNo and PJCNo=@PJCNo and PJCYear=@pjcyear and UpdatedTSProduction=@UpdatedTSProduction and BatchBit=@BatchBit and isnull(Rework_Rej_Bit,0)=0

	

	end
end
