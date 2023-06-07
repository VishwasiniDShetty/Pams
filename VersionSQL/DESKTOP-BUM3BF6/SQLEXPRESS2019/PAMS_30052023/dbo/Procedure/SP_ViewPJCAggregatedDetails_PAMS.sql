/****** Object:  Procedure [dbo].[SP_ViewPJCAggregatedDetails_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

/*
SP_ViewPJCAggregatedDetails_PAMS @PartID=N'M7070120',@PJCNo=N'1',@PJCYear=N'2023',@OperationNo=N'50',@Date=N'2023-02-07 00:00:00.000',@Shift=N'A', @Param=N'View'

SP_ViewPJCAggregatedDetails_PAMS @PartID=N'M7070120',@PJCNo=N'1',@PJCYear=N'2023',@MJCNo=N'RM/GRN/1/2023-24',@Param=N'PJCLevelView'

exec [SP_ViewPJCAggregatedDetails_PAMS] @fromdate=N'2023-05-01 00:00:00.000',@Todate=N'2023-05-11 00:00:00.000',@MachineID=N'',@Shift=N'''A'',''b'',''c''',@Param=N'View'

*/
CREATE procedure [dbo].[SP_ViewPJCAggregatedDetails_PAMS]
@fromdate datetime='',
@Todate datetime='',
@MachineID NVARCHAR(MAX)='',
@Shift nvarchar(500)='',
@PartID NVARCHAR(50)='',
@MJCNo nvarchar(50)='',
@PJCNo nvarchar(50)='',
@PJCYear nvarchar(50)='',
@OperationNo nvarchar(50)='',
@Date datetime='',
@Prod_Qty float=0,
@ReworkQty float=0,
@RejQty float=0,
@AcceptedQty float=0,
@QualityIncharge nvarchar(50)='',
@LineIncharge nvarchar(50)='',
@FinishedOpn nvarchar(50)='',
@PendingQtyForInspection float=0,
@MarkedForReworkQty float=0,
@RejectionReason nvarchar(1000)='',
@ReworkReason nvarchar(1000)='',
@UpdatedBy nvarchar(50)='',
@OKQty float=0,
@UpdatedTS datetime='',
@Param nvarchar(50)='',
@LineInchargeStatus nvarchar(50)='',
@QualityStatus nvarchar(50)='',
@Process nvarchar(2000)='',
@PJCAutoID bigint=0,
@DummyCycle float=0,
@Rework_Rej_Bit bit=0,
@ReworkDate datetime='',
@ReworkShift nvarchar(50)='',
@ReworkOperator nvarchar(50)='',
@ReworkMachine nvarchar(50)=''
as
begin
create table #Temp
(
AutoID BIGINT DEFAULT 0,
PJCYear nvarchar(10),
MachineID NVARCHAR(50),
PartID NVARCHAR(50),
MJCNo nvarchar(50),
PJCNo nvarchar(50),
OperationNo nvarchar(50),
FinishedOpn nvarchar(50),
Date datetime,
Shift nvarchar(50),
ProductionQty float,
MarkedForReworkQty float,
ReworkOk float,
RejectionQty float,
AcceptedQty float,
QualityIncharge nvarchar(50),
Quality_TS DATETIME,
LineIncharge nvarchar(50),
LineIncharge_TS DATETIME,
PendingQtyForInspection float,
QualityStatus nvarchar(50),
LineInchargeStatus nvarchar(50),
PJCStatus nvarchar(50),
InprocessInspectionStatus nvarchar(50) default 'Pending',
Process nvarchar(2000),
AggregatedBit nvarchar(50) default '0',
DummyCycle float,
Cumulative float
)

create table #PJCHeaderDetails
(
partid nvarchar(50),
mjcno nvarchar(50),
PJCNo nvarchar(50),
PJCDate datetime,
PjcYear nvarchar(50),
IssuedQty float default 0,
ProducedQty float default 0,
RejQty float default 0,
AcceptedQty float default 0,
PJCStatus nvarchar(50),
QualityLevelBatchCount int,
InspectionLevelBatchCount int,
FinalInspectionStatus nvarchar(50)
)
select @Process=''
select  @Process=(select distinct process from componentoperationpricing where componentid=@PartID and operationno=@OperationNo and machineid=@MachineID)


declare @Strsql nvarchar(max)
declare @StrMachineID NVARCHAR(MAX)
declare @StrShift NVARCHAR(2000)
select @Strsql=''
SELECT @StrMachineID=''
select @StrShift=''

if isnull(@ReworkDate,'')=''
begin
		set @ReworkDate=null
end


IF ISNULL(@MachineID,'')<>''
BEGIN
	SELECT @StrMachineID='And MachineID IN ('+@MachineID+')'
END

IF ISNULL(@Shift,'')<>''
begin
	select @StrShift='And Shift in ('+@Shift+')'
end

if @Param='PJCLevelView'
begin
	insert into #PJCHeaderDetails (partid,mjcno,PJCNo,PJCDate,PjcYear,IssuedQty,PJCStatus)
	select PartID,MJCNo,PJCNo,PJCDate, pjcyear,IssuedQty,PJCStatus from ProcessJobCardHeaderCreation_PAMS where PJCYear=@PJCYear and PartID=@PartId and MJCNo=@MJCNo

	update #PJCHeaderDetails set RejQty=isnull(t1.RejectionQty,0)
	from
	(
	select distinct PartID,MjcNo,PJCNo,pjcyear,sum(RejectionQty) as RejectionQty from PJCRejectionDetails_PAMS
	group by PartID,MjcNo,PJCNo,pjcyear
	)t1 inner join #PJCHeaderDetails t2 on t1.PartID=t2.partid and t1.MjcNo=t2.mjcno and t1.PJCNo=t2.PJCNo and ('20'+t1.PJCYear)=t2.PjcYear

	update #PJCHeaderDetails set ProducedQty=isnull(t1.Prod_Qty,0)
	from
	(
	select distinct PartID,MjcNo,PJCNo,pjcyear,sum(Prod_Qty) as Prod_Qty from PJCProductionEditedDetails_PAMS
	--where FinishedOpn='1'
	group by PartID,MjcNo,PJCNo,pjcyear
	)t1 inner join #PJCHeaderDetails t2 on t1.PartID=t2.partid and t1.MjcNo=t2.mjcno and t1.PJCNo=t2.PJCNo and ('20'+t1.PJCYear)=t2.PjcYear



	update #PJCHeaderDetails set RejQty=isnull(RejQty,0)+isnull(t1.RejectionQty,0)
	from
	(
	select distinct PartID,MjcNo,PJCNo,pjcyear,sum(RejectionQty) as RejectionQty from QualityRejectionDetails_Pams
	group by PartID,MjcNo,PJCNo,pjcyear
	)t1 inner join #PJCHeaderDetails t2 on t1.PartID=t2.partid and t1.MjcNo=t2.mjcno and t1.PJCNo=t2.PJCNo and ('20'+t1.PJCYear)=t2.PjcYear

		update #PJCHeaderDetails set AcceptedQty=isnull(t1.AcceptedQty,0)
	from
	(
	select distinct PartID,MjcNo,PJCNo,pjcyear,sum(AcceptedQtyFromInspection) as AcceptedQty from InspectionReadyDetailsSave_Pams
	where isnull(UpdatedTSQuality,'')<>''
	group by PartID,MjcNo,PJCNo,pjcyear
	)t1 inner join #PJCHeaderDetails t2 on t1.PartID=t2.partid and t1.MjcNo=t2.mjcno and t1.PJCNo=t2.PJCNo and ('20'+t1.PJCYear)=t2.PjcYear


		update #PJCHeaderDetails set QualityLevelBatchCount=isnull(t1.QualityLevelBatchCount,0)
	from
	(
	select distinct partid,pjcno,pjcyear,mjcno, count( BatchBit) as QualityLevelBatchCount from InspectionReadyDetailsSave_Pams
	group by partid,pjcno,pjcyear,mjcno
	) t1 inner join #PJCHeaderDetails t2 on t1.PartID=t2.partid and t1.PJCNo=t2.PJCNo and ('20'+t1.PJCYear)=t2.PjcYear and t1.MJCNo=t2.mjcno

	update #PJCHeaderDetails set InspectionLevelBatchCount=isnull(t1.InspectionLevelBatchCount,0)
	from
	(
	select distinct ComponentID,pjcno,pjcyear, count(BatchBit) as InspectionLevelBatchCount from FinalInspectionTransactionFGLevel_PAMS
	group by ComponentID,pjcno,pjcyear
	) t1 inner join #PJCHeaderDetails t2 on t1.ComponentID=t2.partid and t1.PJCNo=t2.PJCNo and ('20'+t1.PJCYear)=t2.PjcYear


	update #PJCHeaderDetails set FinalInspectionStatus=(t1.sts)
	from
	(
	select distinct partid,PJCNo,PjcYear,STUFF((SELECT distinct ',' + L2.status
         from FinalInspectionTransactionFGLevel_PAMS L2 
		 where l2.ComponentID=l3.partid and l2.PJCNo=l3.PJCNo and ('20'+l2.PJCYear)=l3.PjcYear
            FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(MAX)') 
        ,1,1,'') sts from #PJCHeaderDetails l3 
	) t1 inner join #PJCHeaderDetails on #PJCHeaderDetails.partid=t1.partid and #PJCHeaderDetails.PJCNo=t1.PJCNo and #PJCHeaderDetails.PjcYear=t1.PjcYear

	select distinct * from  #PJCHeaderDetails

end

if @Param='View'
begin

	
	select @strsql=''
	select @strsql=@strsql+'insert into #Temp(MachineID,PJCYear,PartID,PJCNo,OperationNo,Date,Shift,ProductionQty,AcceptedQty,AggregatedBit) '
	select @strsql=@strsql+'select distinct s1.MachineID,s1.PJCYear,s1.ComponentID,s1.WorkOrderNumber,s1.OperationNo,s1.pDate,s1.shift,sum(Prod_Qty),sum(AcceptedParts),''1'' from ShiftProductionDetails s1
	INNER JOIN ProcessJobCardHeaderCreation_PAMS S2 ON S1.ComponentID=s2.partid and s1.WorkOrderNumber=s2.PJCNo and (''20''+s1.PJCYear)=s2.PJCYear
	where isnumeric(WorkOrderNumber)=''1'' and (convert(nvarchar(20),pdate,120)>='''+convert(nvarchar(20),@fromdate,120)+''' and convert(nvarchar(20),pdate,120)<='''+convert(nvarchar(20),@Todate,120)+''')'
	SELECT @Strsql=@Strsql+@StrMachineID+@StrShift
	select @Strsql=@Strsql+'group by s1.MachineID,s1.PJCYear,s1.ComponentID,s1.WorkOrderNumber,s1.OperationNo,s1.pDate,s1.shift '
	print(@strsql)
	exec(@strsql)

	select @Strsql=''
	select @strsql=@strsql+'insert into #Temp(MachineID,PJCYear,PartID,PJCNo,OperationNo,Date,Shift,AutoID,AggregatedBit) '
	select @strsql=@strsql+'select distinct MachineID,PJCYear,PartID,PJCNo,OperationNo,Date,Shift,AutoID,''0'' from PJCProductionEditedDetails_PAMS t2 
	where not exists (select machineid,PJCYear,PartID,PJCNo,OperationNo,Date,Shift from #Temp t1 where t1.machineid=t2.machineid and t1.PJCYear=t2.PJCYear and t1.PartID=t2.PartID 
	and t1.PJCNo=t2.PJCNo and t1.OperationNo=t2.OperationNo and t1.Date=t2.Date and t1.Shift=t2.Shift) and
	(convert(nvarchar(20),date,120)>='''+convert(nvarchar(20),@fromdate,120)+''' and convert(nvarchar(20),date,120)<='''+convert(nvarchar(20),@todate,120)+''') '
	select @Strsql=@Strsql+@StrMachineID+@StrShift
	print(@strsql)
	exec(@strsql)


	----------------------------------------------------------------------------------------update mjcno starts----------------------------------------------------------------------------------------------
	update #Temp set MjcNo=isnull(t1.MJCNo,'')
	from
	(
	select distinct PartID,MJCNo,PJCNo,PJCYear from ProcessJobCardHeaderCreation_PAMS
	) t1 inner join #Temp t2 on t1.PartID=t2.PartID and t1.PJCNo=t2.PJCNo and t1.PJCYear=('20'+t2.PJCYear)

	
	---------------------------------------------------------------------------------------process picking starts----------------------------------------------------------------------------------------------

	update #Temp set Process=isnull(t1.process,'')
	from
	(
	select distinct machineid,ComponentID,operationno,process from componentoperationpricing 
	) t1 inner join #Temp t2 on t1.machineid=t2.MachineID and t1.componentid=t2.PartID and t1.operationno=t2.OperationNo


	----------------------------------------------------------------------------Calc of OriginalMarkedForReworkQty begins-------------------------------------------------------------------------------------------------
	
	--UPDATE #Temp SET FinishedOpn=(T1.Finishopn)
	--from
	--(
	--select distinct MachineID,PJCYear,ComponentID,WorkOrderNumber,OperationNo,FinishedOperation as Finishopn from ShiftProductionDetails
	--)t1 inner join #Temp on t1.MachineID=#Temp.MachineID and  t1.PJCYear=#Temp.PJCYear and t1.ComponentID=#Temp.PartID and t1.WorkOrderNumber=#Temp.PJCNo and t1.OperationNo=#Temp.OperationNo

	--UPDATE #Temp SET FinishedOpn=(T1.Finishopn)
	--from
	--(
	--select distinct Machineid,PJCYear,PartID,PJCNo,OperationNo,FinishedOpn as Finishopn from PJCProductionEditedDetails_PAMS
	--)t1 inner join #Temp on t1.Machineid=#Temp.MachineID and t1.PJCYear=#Temp.PJCYear and t1.PartID=#Temp.PartID and t1.PJCNo=#Temp.PJCNo and t1.OperationNo=#Temp.OperationNo

	UPDATE #Temp SET FinishedOpn=(T1.Finishopn)
	from
	(
	select distinct Machineid,componentid,OperationNo,FinishedOperation as Finishopn from componentoperationpricing
	)t1 inner join #Temp on t1.Machineid=#Temp.MachineID and  t1.componentid=#Temp.PartID and  t1.OperationNo=#Temp.OperationNo


		-----------------------------------------------------------------------------Calc Of Rejection Qty begins----------------------------------------------------------------------------------------------
	
	update #Temp set RejectionQty=isnull(t1.RejectionQty,0)
	from
	(
	select distinct date,shift,Machineid,partid,MjcNo,PJCNo,PJCYear,OperationNo,sum(rejectionqty) as rejectionqty  from PJCRejectionDetails_PAMS
	group by date,shift,machineid,partid,MjcNo,PJCNo,PJCYear,OperationNo
	) t1 inner join #Temp t2 on t1.Date=t2.Date and t1.Shift=t2.Shift and t1.Machineid=t2.MachineID and t1.PartID=t2.PartID and t1.PJCNo=t2.PJCNo and t1.PJCYear=t2.PJCYear and t1.OperationNo=t2.OperationNo

	------------------------------------------------------------------------------Calc of ReworkRejection begins-------------------------------------------------------------------------------------------------
	
	update #Temp set MarkedForReworkQty=isnull(t1.MarkedForReworkQty,0)
	from
	(
	select distinct date,shift,Machineid,PartID,MjcNo,PJCNo,PJCYear,OperationNo,sum(MarkedForReworkQty) as MarkedForReworkQty from PJCMarkedForReworkDetails_PAMS
	group by date,shift,Machineid,PartID,MjcNo,PJCNo,PJCYear,OperationNo
	) t1 inner join #Temp t2 on t1.Machineid=t2.Machineid and t1.Date=t2.Date and t1.Shift=t2.Shift and t1.PartID=t2.PartID and t1.PJCNo=t2.PJCNo and t1.PJCYear=t2.PJCYear and t1.OperationNo=t2.OperationNo

	--	----------------------------------------------------------------------------Calc of OriginalMarkedForReworkQty ends-------------------------------------------------------------------------------------------------
	----------------------------------------------------------------------------Calc of ReworkOk begins-------------------------------------------------------------------------------------------------
	
	update #Temp set ReworkOk=isnull(t1.ReworkOk,0)
	from
	(
	select distinct date,shift,Machineid,partid,MjcNo,PJCNo,PJCYear,OperationNo,sum(ReworkPerformed_Ok) as ReworkOk  from PJCReworkPerformedDetails_PAMS
	group by date,shift,partid,Machineid, MjcNo,PJCNo,PJCYear,OperationNo
	) t1 inner join #Temp t2 on t1.Date=t2.Date and t1.Shift=t2.Shift and t1.machineid=t2.machineid and t1.PartID=t2.PartID and t1.PJCNo=t2.PJCNo and t1.PJCYear=t2.PJCYear and t1.OperationNo=t2.OperationNo

		----------------------------------------------------------------------------Calc of ReworkOk ends-------------------------------------------------------------------------------------------------



	UPDATE #Temp SET AggregatedBit='0', AutoID=(T1.AutoID),ProductionQty=(T1.Prod_Qty),AcceptedQty=(T1.AcceptedQty),QualityIncharge=(T1.QualityIncharge),
	Quality_TS=(T1.Quality_TS),LineIncharge=(T1.LineIncharge),LineIncharge_TS=(T1.LineIncharge_TS),PendingQtyForInspection=isnull(t1.PendingQtyForInspection,0),QualityStatus=isnull(t1.QualityStatus,''),LineInchargeStatus=isnull(t1.LineInchargeStatus,''),DummyCycle=isnull(t1.DummyCycle,'')
	FROM
	(SELECT DISTINCT AutoID,PartID ,OperationNo,PJCYear,PJCNo,Date,shift,machineid,Prod_Qty  ,AcceptedQty,QualityIncharge ,Quality_TS ,LineIncharge,LineIncharge_TS,PendingQtyForInspection,QualityStatus,LineInchargeStatus,DummyCycle FROM PJCProductionEditedDetails_PAMS 
	)T1 INNER JOIN #Temp ON t1.Machineid=#Temp.machineid and T1.PartID=#Temp.PartID AND T1.OperationNo=#Temp.OperationNo AND T1.PJCYear=#Temp.PJCYear AND T1.PJCNo=#Temp.PJCNo AND T1.Date=#Temp.Date and t1.shift=#Temp.shift


	UPDATE #Temp SET PJCStatus=ISNULL(T1.PJCStatus,'')
	FROM
	(
	SELECT DISTINCT PartID,MJCNo,PJCNo, pjcyear,PJCStatus FROM ProcessJobCardHeaderCreation_PAMS
	) T1 INNER JOIN #Temp T2 ON T1.PartID=T2.PartID AND  T1.PJCNo=T2.PJCNo AND T1.PJCYear=('20'+T2.PJCYear)

	
	

	
	update #Temp set InprocessInspectionStatus=isnull(t1.Status,'')
	from
	(
	select distinct date,shift,Machine,ComponentID,OperationNo,PJCNo,PJCYear,Status from FinalInspectionTransactionMCOLevel_PAMS where ReportType='Inprocess inspection report'
	) t1 inner join #Temp t2 on t1.date=t2.Date and t1.Shift=t2.Shift and t1.Machine=t2.MachineID and t1.ComponentID=t2.PartID and  t1.OperationNo=t2.OperationNo and t1.PJCNo=t2.PJCNo and  t1.PJCYear=t2.PJCYear


	--update #Temp set AcceptedQty=isnull(t1.AcceptedQty,0)
	--from
	--(
	--select distinct Date,Shift,MachineID,PartID,OperationNo,MJCNo,PJCNo,PJCYear, (isnull(ProductionQty,0)-(isnull(MarkedForReworkQty,0)-isnull(ReworkOk,0))-isnull(RejectionQty,0)) as AcceptedQty from #Temp
	--) t1 inner join #Temp t2 on t1.Date=t2.Date and t1.Shift=t2.Shift and t1.MachineID=t2.MachineID and t1.PartID=t2.PartID and t1.OperationNo=t2.OperationNo and t1.MJCNo=t2.MJCNo and t1.PJCNo=t2.PJCNo and t1.PJCYear=t2.PJCYear

	update #Temp set Cumulative=isnull(t1.cumulative,0)
	from
	(
		select distinct partid,PJCNo,OperationNo,sum(AcceptedQty) as cumulative from PJCProductionEditedDetails_PAMS
		where convert(nvarchar(20),date,120)<=convert(nvarchar(20),@Todate,120)
		group by partid,PJCNo,OperationNo
	) t1 inner join #Temp t2 on t1.PartID=t2.PartID and t1.PJCNo=t2.PJCNo and t1.OperationNo=t2.OperationNo

	select AutoID,MJCNo,PJCYear as PJCYear,PartID,PJCNo,OperationNo ,case when FinishedOpn='' then 0 else  FinishedOpn end as FinishedOpn ,Date,shift,MachineID,ProductionQty ,MarkedForReworkQty,ReworkOk ,RejectionQty,
	AcceptedQty , QualityIncharge ,Quality_TS ,LineIncharge ,LineIncharge_TS,PendingQtyForInspection,QualityStatus,LineInchargeStatus,PJCStatus,isnull(InprocessInspectionStatus,'Pending') as InprocessInspectionStatus,process,AggregatedBit,DummyCycle,Cumulative from #Temp
	WHERE (ISNULL(SHIFT,'')<>'C' AND ISNULL(ProductionQty,0)<>0)
	ORDER BY date,shift, MachineID,PartID,PJCNo

		--ORDER BY partid,pjcno,operationno



end



if @Param='QualitySave'
begin

	if not exists(select * from PJCProductionEditedDetails_PAMS where machineid=@MachineID and Date=@Date and PJCYear=@PJCYear and PartID=@PartID and OperationNo=@OperationNo and MJCNo=@MJCNo and PJCNo=@PJCNo and shift=@shift)
	begin
		insert into PJCRejectionDetails_PAMS(date,Shift,machineid,PartID,MjcNo,PJCNo,PJCYear,OperationNo,process,RejectionQty,RejectionReason,UpdatedBy,UpdatedTS,Rework_Rej_Bit)
		values(@Date,@shift,@MachineID,@PartID,@MJCNo,@PJCNo,@PJCYear,@OperationNo,@Process,@RejQty,@RejectionReason,@UpdatedBy,GETDATE(),@Rework_Rej_Bit)

		insert into PJCProductionEditedDetails_PAMS(Date,PartID,machineid,OperationNo,PJCYear,PJCNo,Prod_Qty,ReworkQty,RejQty,AcceptedQty,QualityIncharge,Quality_TS,FinishedOpn,shift,MJCNo,QualityStatus,process,DummyCycle)
		values(@Date,@PartID,@MachineID,@OperationNo,@PJCYear,@PJCNo,@Prod_Qty,@ReworkQty,@RejQty,@AcceptedQty,@QualityIncharge,getdate(),@FinishedOpn,@shift,@MJCNo,@QualityStatus,@Process,@DummyCycle)
	end
	else
	begin
		update PJCProductionEditedDetails_PAMS set DummyCycle= @DummyCycle,RejQty=@RejQty ,AcceptedQty=@AcceptedQty,ReworkQty=@ReworkQty,QualityIncharge=@QualityIncharge,Quality_TS=getdate()
		 where Date=@Date and PJCYear=@PJCYear and PartID=@PartID and OperationNo=@OperationNo and PJCNo=@PJCNo and shift=@shift  and MJCNo=@MJCNo and Machineid=@MachineID
	end

end

if @Param='LineInchargeSave'
begin

	if not exists(select * from PJCProductionEditedDetails_PAMS where Date=@Date and PJCYear=@PJCYear and Machineid=@MachineID and PartID=@PartID and OperationNo=@OperationNo and PJCNo=@PJCNo and shift=@shift and MJCNo=@MJCNo)
	begin

		insert into PJCProductionEditedDetails_PAMS(Date,PartID,Machineid,OperationNo,PJCYear,PJCNo,Prod_Qty,ReworkQty,RejQty,AcceptedQty,LineIncharge,LineIncharge_TS,FinishedOpn,shift,PendingQtyForInspection,MJCNo,LineInchargeStatus,process,DummyCycle)
		values(@Date,@PartID,@MachineID, @OperationNo,@PJCYear,@PJCNo,@Prod_Qty,@ReworkQty,@RejQty,@AcceptedQty,@LineIncharge,getdate(),@FinishedOpn,@shift,@PendingQtyForInspection,@MJCNo,@LineInchargeStatus,@Process,@DummyCycle)
	end
	else
	begin
		update PJCProductionEditedDetails_PAMS set Prod_Qty=@Prod_Qty,AcceptedQty=@AcceptedQty,LineIncharge=@LineIncharge,LineIncharge_TS=getdate(),DummyCycle=@DummyCycle
		 where Date=@Date and PJCYear=@PJCYear and PartID=@PartID and OperationNo=@OperationNo and PJCNo=@PJCNo and shift=@shift and MJCNo=@MJCNo and Machineid=@MachineID 
	end

end

IF @Param='UpdatePendingQty'
begin
	--UPDATE PJCProductionEditedDetails_PAMS SET PendingQtyForInspection=@PendingQtyForInspection WHERE Date=@Date and PJCYear=@PJCYear and PartID=@PartID and OperationNo=@OperationNo and PJCNo=@PJCNo and shift=@shift and MJCNo=@MJCNo and AutoID=@PJCAutoID

	UPDATE PJCProductionEditedDetails_PAMS SET PendingQtyForInspection=@PendingQtyForInspection WHERE AutoID=@PJCAutoID

end

IF @Param='UpdatePendingQtyFromFinalInspection'
begin
	--UPDATE PJCProductionEditedDetails_PAMS SET PendingQtyForInspection=@PendingQtyForInspection WHERE Date=@Date and PJCYear=@PJCYear and PartID=@PartID and OperationNo=@OperationNo and PJCNo=@PJCNo and shift=@shift and MJCNo=@MJCNo and AutoID=@PJCAutoID

	UPDATE PJCProductionEditedDetails_PAMS SET PendingQtyForInspection=isnull(PendingQtyForInspection,0)+isnull(@PendingQtyForInspection,0) WHERE AutoID=@PJCAutoID

end

if @Param='SaveRejectionQty'
begin
	if not exists(select * from PJCRejectionDetails_PAMS where Machineid=@MachineID and Date=@Date and Shift=@shift and PartID=@PartID and OperationNo=@OperationNo and PJCNo=@PJCNo and shift=@shift and MJCNo=@MJCNo and UpdatedTS=@UpdatedTS)
	begin
		insert into PJCRejectionDetails_PAMS(Date,Shift,Machineid,PartID,MjcNo,PJCNo,PJCYear,OperationNo,RejectionQty,RejectionReason,UpdatedBy,UpdatedTS,process,Rework_Rej_Bit)
		values(@Date,@shift,@MachineID,@PartID,@MJCNo,@PJCNo,@PJCYear,@OperationNo,@RejQty,@RejectionReason,@UpdatedBy,getdate(),@Process,@Rework_Rej_Bit)
	end
	else
	begin
		update PJCRejectionDetails_PAMS set RejectionQty=@RejQty , RejectionReason=@RejectionReason,UpdatedBy=@UpdatedBy,UpdatedTS=getdate()
		where Date=@Date and Shift=@shift and PartID=@PartID and OperationNo=@OperationNo and PJCNo=@PJCNo and shift=@shift and MJCNo=@MJCNo and Machineid=@MachineID
	end
end


if @Param='SaveMarkedForReworkQty'
begin
		if not exists(select * from PJCMarkedForReworkDetails_PAMS where Machineid=@MachineID and Date=@Date and Shift=@shift and PartID=@PartID and OperationNo=@OperationNo and PJCNo=@PJCNo and  MJCNo=@MJCNo and UpdatedTS=@UpdatedTS)
	begin
		insert into PJCMarkedForReworkDetails_PAMS(Date,Shift,Machineid,PartID,MjcNo,PJCNo ,PJCYear,OperationNo,MarkedForReworkQty,OKQty,RejectionQty,ReworkReason,UpdatedBy,UpdatedTS,Process)
		values(@Date,@shift,@Machineid,@PartID,@MJCNo,@PJCNo,@PJCYear,@OperationNo,@MarkedForReworkQty,@OKQty,@RejQty,@ReworkReason,@UpdatedBy,getdate(),@Process)
	end
	else
	begin
		update PJCMarkedForReworkDetails_PAMS set MarkedForReworkQty=@MarkedForReworkQty , OKQty=@OKQty,RejectionQty=@RejQty,ReworkReason=@ReworkReason,UpdatedBy=@UpdatedBy,UpdatedTS=getdate()
		where Date=@Date and Shift=@shift and PartID=@PartID and OperationNo=@OperationNo and PJCNo=@PJCNo and shift=@shift and MJCNo=@MJCNo and Machineid=@MachineID
	end
end



if @Param='SaveReworkPerformedQty'
begin
		if not exists(select * from PJCReworkPerformedDetails_PAMS where Machineid=@MachineID and Date=@Date and Shift=@shift and PartID=@PartID and OperationNo=@OperationNo and PJCNo=@PJCNo and  
		MJCNo=@MJCNo and UpdatedTS=@UpdatedTS and ReworkDate=@ReworkDate and ReworkShift=@ReworkShift and ReworkOperator=@ReworkOperator and ReworkMachine=@ReworkMachine)
	begin
		insert into PJCReworkPerformedDetails_PAMS(Date,Shift,Machineid,PartID,MjcNo,PJCNo ,PJCYear,OperationNo,ReworkPerformed_Ok, UpdatedBy,UpdatedTS,Process,ReworkDate,ReworkShift,ReworkOperator,ReworkMachine,ReworkPerformed_Qty)
		values(@Date,@shift,@Machineid,@PartID,@MJCNo,@PJCNo,@PJCYear,@OperationNo,@OKQty,@UpdatedBy,getdate(),@Process,@ReworkDate,@ReworkShift,@ReworkOperator,@ReworkMachine,@MarkedForReworkQty)
	end
	else
	begin
		update PJCReworkPerformedDetails_PAMS set ReworkPerformed_Ok=@OKQty,UpdatedBy=@UpdatedBy,ReworkPerformed_Qty=@MarkedForReworkQty
		where Date=@Date and Shift=@shift and PartID=@PartID and OperationNo=@OperationNo and PJCNo=@PJCNo and shift=@shift and MJCNo=@MJCNo and Machineid=@MachineID and 
		UpdatedTS=@UpdatedTS and ReworkDate=@ReworkDate and ReworkShift=@ReworkShift and ReworkOperator=@ReworkOperator and ReworkMachine=@ReworkMachine
	end
end


if @Param='UpdateQualityApprove'
begin
	--update PJCProductionEditedDetails_PAMS  set QualityStatus=@QualityStatus,PendingQtyForInspection=@PendingQtyForInspection where Date=@Date and Shift=@shift and PartID=@PartID and OperationNo=@OperationNo and MJCNo=@MJCNo and PJCNo=@PJCNo and PJCYear=@PJCYear 
	update PJCProductionEditedDetails_PAMS  set QualityStatus=@QualityStatus,PendingQtyForInspection=@PendingQtyForInspection where AutoID=@PJCAutoID
end

if @Param='UpdateLineInchargeApprove'
begin
	--update PJCProductionEditedDetails_PAMS  set LineInchargeStatus=@LineInchargeStatus,PendingQtyForInspection=@PendingQtyForInspection where Date=@Date and Shift=@shift and PartID=@PartID and OperationNo=@OperationNo and MJCNo=@MJCNo and PJCNo=@PJCNo and PJCYear=@PJCYear 
	update PJCProductionEditedDetails_PAMS  set LineInchargeStatus=@LineInchargeStatus,PendingQtyForInspection=@PendingQtyForInspection where AutoID=@PJCAutoID

end

if @Param='ReworkDetails'
begin
	select * from PJCMarkedForReworkDetails_PAMS where Date=@Date and Shift=@Shift and PartID=@PartID and MjcNo=@MJCNo and PJCNo=@PJCNo and OperationNo=@OperationNo and Machineid=@Machineid

	select * from PJCRejectionDetails_PAMS where Date=@Date and Shift=@Shift and PartID=@PartID and MjcNo=@MJCNo and PJCNo=@PJCNo and OperationNo=@OperationNo and Machineid=@Machineid and isnull(Rework_Rej_Bit,0)=1

	select * from PJCReworkPerformedDetails_PAMS where Date=@Date and Shift=@Shift and PartID=@PartID and MjcNo=@MJCNo and PJCNo=@PJCNo and OperationNo=@OperationNo and Machineid=@Machineid
end

if @Param='RejectionDetails'
begin
	select * from PJCRejectionDetails_PAMS where Date=@Date and Shift=@Shift and PartID=@PartID and MjcNo=@MJCNo and PJCNo=@PJCNo and OperationNo=@OperationNo and Machineid=@Machineid and isnull(Rework_Rej_Bit,0)=0
end


--if @Param='SaveMarkedForReworkQty'
--begin
--		if not exists(select * from PJCMarkedForReworkDetails_PAMS where Date=@Date and Shift=@shift and PartID=@PartID and OperationNo=@OperationNo and PJCNo=@PJCNo and shift=@shift and MJCNo=@MJCNo and UpdatedTS=@UpdatedTS)
--	begin
--		insert into PJCMarkedForReworkDetails_PAMS(Date,Shift,PartID,MjcNo,PJCNo ,PJCYear,OperationNo,MarkedForReworkQty,OKQty,RejectionQty,ReworkReason,UpdatedBy,UpdatedTS)
--		values(@Date,@shift,@PartID,@MJCNo,@PJCNo,@PJCYear,@OperationNo,@MarkedForReworkQty,@OKQty,@RejQty,@ReworkReason,@UpdatedBy,getdate())
--	end
--	else
--	begin
--		update PJCMarkedForReworkDetails_PAMS set MarkedForReworkQty=@MarkedForReworkQty , OKQty=@OKQty,RejectionQty=@RejQty,ReworkReason=@ReworkReason,UpdatedBy=@UpdatedBy,UpdatedTS=getdate()
--		where Date=@Date and Shift=@shift and PartID=@PartID and OperationNo=@OperationNo and PJCNo=@PJCNo and shift=@shift and MJCNo=@MJCNo

--		update PJCProductionEditedDetails_PAMS set AcceptedQty=isnull(AcceptedQty,0)+isnull(@OKQty,0),RejQty=isnull(RejQty,0)+isnull(@rejqty,0),@MarkedForReworkQty=@MarkedForReworkQty
--		where Date=@Date and Shift=@shift and PartID=@PartID and OperationNo=@OperationNo and PJCNo=@PJCNo and shift=@shift and MJCNo=@MJCNo

--		update PJCRejectionDetails_PAMS set RejectionQty=isnull(RejectionQty,0)+isnull(@RejQty,0) 	
--		where Date=@Date and Shift=@shift and PartID=@PartID and OperationNo=@OperationNo and PJCNo=@PJCNo and shift=@shift and MJCNo=@MJCNo
 
--	end
--end
end
