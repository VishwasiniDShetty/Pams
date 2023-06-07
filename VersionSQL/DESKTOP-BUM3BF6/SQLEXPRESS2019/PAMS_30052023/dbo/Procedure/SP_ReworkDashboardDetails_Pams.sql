/****** Object:  Procedure [dbo].[SP_ReworkDashboardDetails_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

/*
exec SP_ReworkDashboardDetails_Pams @PJCNo=N'9',@Stage=N'Inprocess,FinalInspection', @process=N'',@Param=N'View1'
exec SP_ReworkDashboardDetails_Pams @partid=N'T4010760',@MJCNo=N'RM/GRN/12/2023-24',@PJCNo=N'12',@OperationNo=N'60',@process=N'PRE OD GRINDING', @Stage=N'FinalInspection',@Param=N'View2'
exec SP_ReworkDashboardDetails_Pams @partid=N'N5080530',@MJCNo=N'RM/GRN/5/2023-24',@PJCNo=N'7',@OperationNo=N'40',@process=N'FINISH OD GRINDING', @Stage=N'Inprocess',@Param=N'View3'
exec SP_ReworkDashboardDetails_Pams @partid=N'T4010760',@MJCNo=N'RM/GRN/12/2023-24',@PJCNo=N'12',@OperationNo=N'60',@process=N'PRE OD GRINDING', @Stage=N'FinalInspection',@Param=N'View4'


*/
CREATE procedure [dbo].[SP_ReworkDashboardDetails_Pams]
@PJCNo NVARCHAR(MAX)='',
@PJCYear nvarchar(50)='',
@Stage nvarchar(1000)='',
@process nvarchar(50)='',
@PartID nvarchar(50)='',
@MJCNo nvarchar(50)='',
@OperationNo nvarchar(50)='',
@Param nvarchar(50)=''
as
begin
create table #ReworkTemp
(
PartID NVARCHAR(50),
MJCNo nvarchar(50),
PJCNo nvarchar(50),
PJCYear nvarchar(50),
OperationNo nvarchar(50),
Process nvarchar(50),
Stage nvarchar(50),
ReworkReason nvarchar(2000),
ProductionQty float,
MarkedForReworkQty float,
ReworkOkQty float,
ReworkRejQty float,
DCType nvarchar(50),
ReworkTS DATETIME,
DCGenerationBit bit default 0,
ReworkDCQty float
)

--create table #ReworkOkTemp
--(
--PJCNo nvarchar(50),
--Process nvarchar(50),
--Stage nvarchar(50),
--Date nvarchar(50),
--Shift nvarchar(50),
--Machineid nvarchar(50),
--OkQty float,
--RejQty float,
--UpdatedBy nvarchar(50),
--Remarks nvarchar(2000),
--)

	--insert into #ReworkTemp(PartID,MJCNo,PJCNo,OperationNo,Process,Stage,ReworkReason,MarkedForReworkQty,DCType)
	--select distinct p1.PartID,p1.MJCNo,p1.PJCNo,p1.OperationNo,p1.Process,'Inprocess', p1.ReworkReason,p1.MarkedForReworkQty,p2.DCType from PJCMarkedForReworkDetails_PAMS p1
	--left join (select distinct PartID,Process,DCType from ProcessAndFGAssociation_PAMS) p2 on p1.PartID=p2.PartID and p1.Process=p2.Process
	--where (p1.PJCNo in (select item from SplitStrings(@PJCNo,','))  or ISNULL(@PJCNo,'')='')
	--union
	--select distinct p1.PartID,p1.MJCNo,p1.PJCNo,p1.OperationNo,p1.Process,'FinalInspection', p1.ReworkReason,p1.MarkedForReworkQty,p2.DCType from QualityReworkDetails_Pams p1
	--left join (select distinct PartID,Process,DCType from ProcessAndFGAssociation_PAMS) p2 on p1.PartID=p2.PartID and p1.Process=p2.Process
	--where (p1.PJCNo in (select item from SplitStrings(@PJCNo,',')) or isnull(@PJCNo,'')='')

	insert into #ReworkTemp(PartID,MJCNo,PJCNo,OperationNo,Process,Stage,ReworkReason,MarkedForReworkQty,DCType,ReworkTS,PJCYear)
	select  p1.PartID,p1.MJCNo,p1.PJCNo,p1.OperationNo,p1.Process,'Inprocess',p1.ReworkReason,p1.MarkedForReworkQty,p2.DCType,P1.UpdatedTS,p1.PJCYear from PJCMarkedForReworkDetails_PAMS p1
	left join (select distinct PartID,Process,DCType from ProcessAndFGAssociation_PAMS) p2 on p1.PartID=p2.PartID and p1.Process=p2.Process
	where (p1.PJCNo in (select item from SplitStrings(@PJCNo,','))  or ISNULL(@PJCNo,'')='')
	union all
	select  p1.PartID,p1.MJCNo,p1.PJCNo,p1.OperationNo,p1.Process,'FinalInspection', p1.ReworkReason,p1.MarkedForReworkQty,p2.DCType,P1.UpdatedTS,p1.PJCYear from QualityReworkDetails_Pams p1
	left join (select distinct PartID,Process,DCType from ProcessAndFGAssociation_PAMS) p2 on p1.PartID=p2.PartID and p1.Process=p2.Process
	where (p1.PJCNo in (select item from SplitStrings(@PJCNo,',')) or isnull(@PJCNo,'')='')


	if @Param='View1'
	begin

		update #ReworkTemp set ProductionQty=isnull(t1.Prod_Qty,0)
		from
		(
					select distinct partid,MjcNo,PJCNo,PJCYear,OperationNo,process,sum(Prod_Qty) as Prod_Qty from PJCProductionEditedDetails_PAMS
					group by partid,MjcNo,PJCNo,OperationNo,process,PJCYear
		) t1 inner join #ReworkTemp t2 on t1.PartID=t2.PartID and t1.MJCNo=t2.MJCNo and t1.PJCNo=t2.PJCNo and t1.PJCYear=t2.PJCYear and t1.OperationNo=t2.OperationNo and t1.Process=t2.Process and t2.Stage='Inprocess'
		

		update #ReworkTemp set MarkedForReworkQty=isnull(t1.MarkedForReworkQty,0)
		from
		(
			select distinct partid,MjcNo,PJCNo,PJCYear,OperationNo,process,stage,sum(MarkedForReworkQty) as MarkedForReworkQty from #ReworkTemp
			group by partid,MjcNo,PJCNo,PJCYear,OperationNo,process,stage
		) t1 inner join #ReworkTemp t2 on t1.PartID=t2.PartID and t1.MJCNo=t2.MJCNo and t1.PJCNo=t2.PJCNo and t1.PJCYear=t2.PJCYear and t1.OperationNo=t2.OperationNo and t1.Process=t2.Process and t2.Stage=t1.Stage


		update #ReworkTemp set ReworkOkQty=isnull(t1.OkQty,0)
		from
		(
			select  partid,MjcNo,PJCNo,PJCYear,OperationNo,process,sum(ReworkPerformed_Ok) as OkQty from PJCReworkPerformedDetails_PAMS
			group by partid,MjcNo,PJCNo,PJCYear,OperationNo,process
		) t1 inner join #ReworkTemp t2 on t1.PartID=t2.PartID and t1.MJCNo=t2.MJCNo and t1.PJCNo=t2.PJCNo and t1.PJCYear=t2.PJCYear and t1.OperationNo=t2.OperationNo and t1.Process=t2.Process and t2.Stage='Inprocess'

			update #ReworkTemp set ReworkRejQty=isnull(t1.RejectionQty,0)
		from
		(
			select  partid,MjcNo,PJCNo,PJCYear,OperationNo,process,sum(RejectionQty) as RejectionQty from PJCRejectionDetails_PAMS where Rework_Rej_Bit=1
			group by partid,MjcNo,PJCNo,PJCYear,OperationNo,process
		) t1 inner join #ReworkTemp t2 on t1.PartID=t2.PartID and t1.MJCNo=t2.MJCNo and t1.PJCNo=t2.PJCNo and t1.PJCYear=t2.PJCYear and t1.OperationNo=t2.OperationNo and t1.Process=t2.Process and t2.Stage='Inprocess'

		update #ReworkTemp set ProductionQty=isnull(t1.Prod_Qty,0)
		from
		(
					select distinct partid,MjcNo,PJCNo,PJCYear,OperationNo,sum(AcceptedQtyFromInspection) as Prod_Qty from InspectionReadyDetailsSave_Pams
					group by partid,MjcNo,PJCNo,PJCYear,OperationNo
		) t1 inner join #ReworkTemp t2 on t1.PartID=t2.PartID and t1.MJCNo=t2.MJCNo and t1.PJCNo=t2.PJCNo and t1.PJCYear=t2.PJCYear and t1.OperationNo=t2.OperationNo and t2.Stage='FinalInspection'
		
			
			update #ReworkTemp set ReworkOkQty=isnull(t1.OkQty,0)
		from
		(
			select  partid,MjcNo,PJCNo,PJCYear,OperationNo,sum(ReworkPerformed_Ok) as OkQty from QualityReworkPerformedDetails_Pams
			group by partid,MjcNo,PJCNo,PJCYear,OperationNo
		) t1 inner join #ReworkTemp t2 on t1.PartID=t2.PartID and t1.MJCNo=t2.MJCNo and t1.PJCNo=t2.PJCNo and t1.PJCYear=t2.PJCYear and t1.OperationNo=t2.OperationNo and  t2.Stage='FinalInspection'

			update #ReworkTemp set ReworkRejQty=isnull(t1.RejectionQty,0)
		from
		(
			select  partid,MjcNo,PJCNo,PJCYear,OperationNo,sum(RejectionQty) as RejectionQty from QualityRejectionDetails_Pams 
			group by partid,MjcNo,PJCNo,PJCYear,OperationNo
		) t1 inner join #ReworkTemp t2 on t1.PartID=t2.PartID and t1.MJCNo=t2.MJCNo and t1.PJCNo=t2.PJCNo and t1.PJCYear=t2.PJCYear and t1.OperationNo=t2.OperationNo  and t2.Stage='FinalInspection'
	
		UPDATE #ReworkTemp SET DCGenerationBit=isnull(t1.DCGenerationBit,0)
		from
		(select distinct PartID ,MJCNo ,PJCNo, OperationNo,Process ,Stage,1 as DCGenerationBit from ReworkDcDetails_Pams
		) t1 inner join #ReworkTemp t2 on t1.PartID=t2.PartID and t1.MJCNo=t2.MJCNo and t1.PJCNo=t2.PJCNo and t1.OperationNo=t2.OperationNo and t1.Process=t2.Process and t1.Stage=t2.Stage

		UPDATE #ReworkTemp SET ReworkDCQty=isnull(t1.ReworkDCQty,0)
		from
		(select distinct PartID ,MJCNo ,PJCNo,PJCYear,OperationNo,Process ,Stage,sum(Qty) as ReworkDCQty from ReworkDcDetails_Pams
		group by  PartID ,MJCNo ,PJCNo,PJCYear,OperationNo,Process ,Stage
		) t1 inner join #ReworkTemp t2 on t1.PartID=t2.PartID and t1.MJCNo=t2.MJCNo and t1.PJCNo=t2.PJCNo and t1.PJCYear=t2.PJCYear and t1.OperationNo=t2.OperationNo and t1.Process=t2.Process and t1.Stage=t2.Stage

		select distinct  PartID ,MJCNo ,PJCNo,PJCYear,OperationNo ,Process,Stage,DCType,ProductionQty,MarkedForReworkQty,ReworkOkQty,ReworkRejQty,DCType,DCGenerationBit,isnull(ReworkDCQty,0) as ReworkDCQty
		from #ReworkTemp where  (Stage in (select item from SplitStrings(@Stage,','))  or ISNULL(@Stage,'')='')
	end

	if @Param='View2'
	begin
		select  ReworkReason,MarkedForReworkQty,ReworkTS from #ReworkTemp
		where PartID=@PartID and MJCNo=@MJCNo and PJCNo=@PJCNo and PJCYear=@PJCYear and OperationNo=@OperationNo and process=@process and stage=@stage
	end

	IF @Param='View3'
	begin
			if @Stage='Inprocess'
			begin
				select  p1.RejectionReason,p1.RejectionQty,P1.UpdatedTS from PJCRejectionDetails_PAMS p1 
				 where PartID=@PartID and MJCNo=@MJCNo and PJCNo=@PJCNo and PJCYear=@PJCYear and OperationNo=@OperationNo and process=@process and Rework_Rej_Bit=1
			end
			else
			begin
				select  p1.RejectionReason,p1.RejectionQty,P1.UpdatedTS from QualityRejectionDetails_Pams p1 
				 where PartID=@PartID and MJCNo=@MJCNo and PJCNo=@PJCNo and PJCYear=@PJCYear and OperationNo=@OperationNo and Rework_Rej_Bit=1
			end
	end 


	IF @Param='View4'
	begin
			if @Stage='Inprocess'
			begin
				select  p1.ReworkPerformed_Ok,P1.UpdatedTS from PJCReworkPerformedDetails_PAMS p1 
				 where PartID=@PartID and MJCNo=@MJCNo and PJCNo=@PJCNo and PJCYear=@PJCYear and OperationNo=@OperationNo and process=@process 
			end
			else
			begin
				select  p1.ReworkPerformed_Ok,P1.UpdatedTS from QualityReworkPerformedDetails_Pams p1 
				 where PartID=@PartID and MJCNo=@MJCNo and PJCNo=@PJCNo and PJCYear=@PJCYear and OperationNo=@OperationNo 
			end
	end

--if @Param='View2'
--begin
--	if @stage='Inprocess'
--	begin
--		insert into #ReworkOkTemp(PJCNo,Process,Stage, Date,Shift,Machineid,OkQty)
--		select distinct PJCNo,process,'Inprocess',date,shift,Machineid,sum(OKQty) from PJCMarkedForReworkDetails_PAMS
--		where pjcno=@pjcno and process=@process
--		group by date,shift,Machineid,PJCNo,process

--		update #ReworkOkTemp set RejQty=isnull(t1.RejQty,0)
--		from
--		(
--			select distinct PJCNo,Process,date,shift,Machineid,sum(RejectionQty) as RejQty  from PJCRejectionDetails_PAMS
--			where Rework_Rej_Bit=1 and PJCNo=@PJCNo and process=@process
--			group by PJCNo,Process,date,shift,Machineid
--		) t1 inner join #ReworkOkTemp t2 on t1.PJCNo=t2.PJCNo and t1.Process=t2.Process and t1.Date=t2.date and t1.Shift=t2.Shift and t1.Machineid=t2.Machineid

--		update #ReworkOkTemp set UpdatedBy=isnull(t1.UpdatedBy,0),Remarks=isnull(t1.remarks,'')
--		from
--		(
--			select distinct PJCNo,Process,date,shift,Machineid,UpdatedBy,remarks  from PJCReworkPerformedDetails_PAMS
--			where  PJCNo=@PJCNo and process=@process
--		) t1 inner join #ReworkOkTemp t2 on t1.PJCNo=t2.PJCNo and t1.Process=t2.Process and t1.Date=t2.date and t1.Shift=t2.Shift and t1.Machineid=t2.Machineid


--		select * from #ReworkOkTemp
--	end
--	else
--	begin
--		insert into #ReworkOkTemp(PJCNo,Process,Stage, OkQty)
--		select distinct PJCNo,process,'FinalInspection',sum(OKQty) from QualityReworkDetails_Pams
--		where pjcno=@pjcno and process=@process
--		group by PJCNo,process

--		update #ReworkOkTemp set RejQty=isnull(t1.RejQty,0)
--		from
--		(
--			select distinct PJCNo,sum(RejectionQty) as RejQty  from QualityRejectionDetails_Pams
--			where Rework_Rej_Bit=1 and PJCNo=@PJCNo
--			group by PJCNo
--		) t1 inner join #ReworkOkTemp t2 on t1.PJCNo=t2.PJCNo 

--		update #ReworkOkTemp set UpdatedBy=isnull(t1.UpdatedBy,0),Remarks=isnull(t1.remarks,'')
--		from
--		(
--			select distinct PJCNo,UpdatedBy,remarks  from QualityReworkPerformedDetails_Pams
--			where  PJCNo=@PJCNo  
--		) t1 inner join #ReworkOkTemp t2 on t1.PJCNo=t2.PJCNo  


--		select * from #ReworkOkTemp
--	end

--end
end
