/****** Object:  Procedure [dbo].[SP_PreviousProcessQtyCalculation_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE procedure [dbo].[SP_PreviousProcessQtyCalculation_PAMS]
@MJCNo nvarchar(50)='',
@PJCNo nvarchar(50)='',
@PJCYear nvarchar(50)='',
@Process nvarchar(2000)='',
@PartID NVARCHAR(50)='',
@PJCProcessType nvarchar(50)='',
@MaterialID nvarchar(50)=''
AS
BEGIN

create table #COPData
(
PJCNo nvarchar(50),
PJCYear nvarchar(50),
MachineID NVARCHAR(50),
PartID NVARCHAR(50),
OperationNo nvarchar(50),
Process nvarchar(2000)
)

create table #PJCListForMJC
(
PartID NVARCHAR(50),
PJCNo nvarchar(50),
PJCYear nvarchar(50),
PJCFirstProcess nvarchar(2000),
DCType nvarchar(50),
PJCQty_Numbers float
)

create table #FindPJCLevelFirstProcess
(
PartID NVARCHAR(50),
PJCNo nvarchar(50),
PJCYear nvarchar(50),
Process nvarchar(2000),
Sequence nvarchar(50),
DCType nvarchar(50),
RowNum int
)

create table #InhousePreviousQty
(
Qty float
)

DECLARE @Sequence float
declare @PreviousSequence float
declare @PreviousProcess nvarchar(2000)
declare @PreProcessDCType nvarchar(50)
declare @PendingProcessQty_KG float
declare @PendingProcessQty_Numbers float

select @Sequence=''
select @PreviousSequence=''
select @PreviousProcess=''
select @PreProcessDCType=''
select @PendingProcessQty_KG=''
select @PendingProcessQty_Numbers=''

select @Sequence=(select Sequence from ProcessAndFGAssociation_PAMS where PartID=@PartID and Process=@Process)
select @PreviousSequence=(select top(1) sequence from ProcessAndFGAssociation_PAMS where PartID=@PartID and Sequence<@Sequence order by Sequence desc)
select @PreviousProcess=(select process from ProcessAndFGAssociation_PAMS where PartID=@PartID and Sequence=@PreviousSequence)
select @PreProcessDCType=(select dctype from  ProcessAndFGAssociation_PAMS where PartID=@PartID and Process=@PreviousProcess)

print @PreviousProcess
print @PreProcessDCType

DECLARE @PJCInwardedQty_Numbers float
	declare @GRNQty_Numbers float
	select @GRNQty_Numbers=0


	declare @TotalIssuedQty float
	select @TotalIssuedQty=0

	--if exists(select * from DCNoGeneration_PAMS where MaterialID=@MaterialID and PartID=@PartID and MJCNo=@MJCNo and  Process=@Process and PJCNo=@PJCNo and PJCYear=@PJCYear and DCStatus='DC No. generated and confirmed')
	--begin
	--	select 0 AS PendingProcessQty_Numbers,0 as TotalIssuedQty
	--	return
	--end



	-------------------------------- LOGIC TO CHECK WHETHER PJC IS OPENED OR NOT TO CALCULATE TOTALISSUEDQTY(15000-inwarded from first process (after first process case) , for next process pjc opened for 100000 , whenever they are doing the next process for the same pjc , pjc level issuedqty will be displayed--------------------------------------------------------------------------


	if exists(select * from DCNoGeneration_PAMS where MaterialID=@MaterialID and PartID=@PartID and MJCNo=@MJCNo and Process=@PreviousProcess and  PJCNo=@PJCNo and PJCYear=@PJCYear and DCStatus='DC No. generated and confirmed')
	begin
		select @TotalIssuedQty=(select SUM(Qty_Numbers) from DCNoGeneration_PAMS where MaterialID=@MaterialID and PartID=@PartID and MJCNo=@MJCNo and  Process=@Process and isnull(pjcno,'')=isnull(@pjcno,'')  and DCStatus='DC No. generated and confirmed')
	end
	else
	begin
		select @TotalIssuedQty=(select SUM(Qty_Numbers) from DCNoGeneration_PAMS where MaterialID=@MaterialID and PartID=@PartID and MJCNo=@MJCNo and  Process=@Process and  DCStatus='DC No. generated and confirmed')--If pjc is not opened already
	END

		-------------------------------- LOGIC TO CHECK WHETHER PJC IS OPENED OR NOT TO CALCULATE TOTALISSUEDQTY--------------------------------------------------------------------------

if isnull(@PreviousProcess,'')<>''
begin
	select @GRNQty_Numbers=(select sum(ReceivedQty_NUmbers) from GrnNoGeneration_PAMS where GrnNo=@MJCNo)

	if not exists(select * from DCStoresDetails_PAMS where MJCNo=@MJCNo and PJCNo=@PJCNo and PJCYear=@PJCYear and PartID=@PartID and Process=@PreviousProcess)
	begin
		insert into #PJCListForMJC(PJCNo,PJCYear,PartID)
		select distinct PJCNo,PJCYear,PartID from ProcessJobCardHeaderCreation_PAMS WHERE MJCNo=@MJCNo AND PartID=@PartID AND PJCNo<>@PJCNo
	end


	IF EXISTS(SELECT * FROM #PJCListForMJC)
	BEGIN

		insert into #FindPJCLevelFirstProcess(PartID,PJCNo,PJCYear,Process,Sequence,DCType,RowNum)
		select distinct D1.PARTID,d1.PJCNo,d1.PJCYear,d1.process,p2.sequence,p2.DCType, ROW_NUMBER() over (order by sequence asc) from DCNoGeneration_PAMS d1 
		inner join ProcessAndFGAssociation_PAMS p2 on d1.PartID=p2.PartID and d1.Process=p2.Process where d1.MJCNo=@MJCNo and d1.PartID=@PartID  and isnull(PJCNo,'')<>''
		order by Sequence asc

		update #PJCListForMJC set PJCFirstProcess=isnull(t1.pjcfirstprocess,''),DCType=isnull(t1.dctype,'')
		from
		(
		select distinct D1.PartID,d1.PJCNo,d1.PJCYear,d1.process as pjcfirstprocess,d1.dctype  from #FindPJCLevelFirstProcess d1 
		where rownum=1
		)t1 inner join  #PJCListForMJC t2 on T1.PartID=T2.PartID AND t1.PJCNo=t2.PJCNo and t1.PJCYear=t2.PJCYear


		UPDATE #PJCListForMJC SET PJCQty_Numbers=ISNULL(T1.AcceptedParts,0)
		FROM
		(
		select DISTINCT P1.PartID,p1.PJCNo,p1.PJCYear,p1.PJCFirstProcess,SUM(S1.Prod_Qty) AS AcceptedParts from #PJCListForMJC p1 
		INNER JOIN componentoperationpricing C1 ON C1.componentid=P1.PartID AND C1.Process=P1.PJCFirstProcess
		INNER JOIN ShiftProductionDetails S1 ON S1.MachineID=C1.machineid AND S1.ComponentID=C1.componentid AND S1.OperationNo=C1.operationno AND S1.WorkOrderNumber=P1.PJCNo AND S1.PJCYear=P1.PJCYear
		group by P1.PartID,p1.PJCNo,p1.PJCYear,p1.PJCFirstProcess
		)T1 INNER JOIN #PJCListForMJC T2 ON T1.PartID=T2.PartID AND T1.PJCNo=T2.PJCNo AND T1.PJCYear=T2.PJCYear AND T1.PJCFirstProcess=T2.PJCFirstProcess AND T2.DCType='Inhouse'

		UPDATE #PJCListForMJC SET PJCQty_Numbers=ISNULL(T1.AcceptedParts,0)
		FROM
		(
		select DISTINCT P1.PartID,p1.PJCNo,p1.PJCYear,p1.PJCFirstProcess,SUM(c1.Qty_Numbers) AS AcceptedParts from #PJCListForMJC p1 
		INNER JOIN DCStoresDetails_PAMS C1 ON C1.PartID=P1.PartID AND C1.PJCNo=P1.PJCNo and c1.PJCYear=p1.PJCYear and c1.Process=p1.PJCFirstProcess
		where c1.DC_Stores_Status='Ready To Issue'
		group by P1.PartID,p1.PJCNo,p1.PJCYear,p1.PJCFirstProcess
		)T1 INNER JOIN #PJCListForMJC T2 ON T1.PartID=T2.PartID AND T1.PJCNo=T2.PJCNo AND T1.PJCYear=T2.PJCYear AND T1.PJCFirstProcess=T2.PJCFirstProcess AND T2.DCType='VendoredOut'

		--UPDATE #PJCListForMJC SET PJCQty_Numbers=ISNULL(T1.AcceptedParts,0)
		--FROM
		--(
		--select DISTINCT P1.PartID,p1.PJCNo,p1.PJCYear,p1.PJCFirstProcess,SUM(c1.Qty_Numbers) AS AcceptedParts from #PJCListForMJC p1 
		--INNER JOIN DCNoGeneration_PAMS C1 ON C1.PartID=P1.PartID AND C1.PJCNo=P1.PJCNo and c1.PJCYear=p1.PJCYear and c1.Process=p1.PJCFirstProcess
		--where c1.DCStatus='DC No. generated and confirmed'
		--group by P1.PartID,p1.PJCNo,p1.PJCYear,p1.PJCFirstProcess
		--)T1 INNER JOIN #PJCListForMJC T2 ON T1.PartID=T2.PartID AND T1.PJCNo=T2.PJCNo AND T1.PJCYear=T2.PJCYear AND T1.PJCFirstProcess=T2.PJCFirstProcess AND T2.DCType='Outside'


		select @PJCInwardedQty_Numbers=(select sum(PJCQty_Numbers) from #PJCListForMJC )
	end
	if @PreProcessDCType='Inhouse'
	begin
		print 'previous process was done inside (Inhouse)'

		INSERT INTO #COPData(MachineID,PartID,OperationNo,Process,PJCNo,PJCYear)
		SELECT DISTINCT MachineID,componentid,operationno,Process,@PJCNo,@PJCYear FROM componentoperationpricing WHERE componentid=@PartID AND Process=@PreviousProcess

		--select @PendingProcessQty_Numbers=(select sum(AcceptedParts) as acceptedqty from ShiftProductionDetails t1 
		--where exists(select * from #COPData t2 where t1.MachineID=t2.MachineID and t1.ComponentID=t2.PartID and t1.OperationNo=t2.OperationNo and t1.WorkOrderNumber=t2.PJCNo and ('20'+t1.PJCYear)=t2.PJCYear))

		--insert into #InhousePreviousQty(Qty)
		--select @PendingProcessQty_Numbers
		

		select @PendingProcessQty_Numbers=(select sum(AcceptedQty) as Qty from PJCProductionEditedDetails_PAMS where PartID=@PartID and PJCNo=@PJCNo and Process=@PreviousProcess)

		print @PendingProcessQty_Numbers 
		--print @PJCInwardedQty_Numbers

		--select @PendingProcessQty_Numbers=case when  isnull(@PendingProcessQty_Numbers,0)<=0 then @GRNQty_Numbers else @PendingProcessQty_Numbers end 
		--select @PendingProcessQty_Numbers=(isnull(@PendingProcessQty_Numbers,0)-isnull(@PJCInwardedQty_Numbers,0))  
		select @PendingProcessQty_Numbers=(isnull(@PendingProcessQty_Numbers,0))  
		select @PendingProcessQty_Numbers AS PendingProcessQty_Numbers,@TotalIssuedQty as TotalIssuedQty
		return
		
	end
	else
	begin	
		print 'previous process was done in Vendor Place or Both places'
		if @PJCProcessType='PJC before first process'
		begin
			--select @PendingProcessQty_Numbers=(select (sum(ISNULL(Qty_Numbers,0))-(sum(ISNULL(RejQty,0))+sum(isnull(settingscrap,0)))) as PendingProcessQty_Numbers from DCStoresDetails_PAMS where MJCNo=@MJCNo and PJCNo=isnull(@pjcno,'')  AND Process=@PreviousProcess and  DC_Stores_Status='Ready To Issue')
			select @PendingProcessQty_Numbers=(select (sum(ISNULL(Qty_Numbers,0))-(sum(ISNULL(RejQty,0)))) as PendingProcessQty_Numbers from DCStoresDetails_PAMS where MJCNo=@MJCNo and PJCNo=isnull(@pjcno,'')  AND Process=@PreviousProcess and  DC_Stores_Status='Ready To Issue')

		end
		if @PJCProcessType='PJC after first process'
		begin
			if not exists (select ISNULL(pjcno,'') from DCStoresDetails_PAMS where MJCNo=@MJCNo AND ISNULL(PJCNO,'')<>'' and Process=@PreviousProcess)
			begin
				PRINT 'YES'
				select @PendingProcessQty_Numbers=(select (sum(ISNULL(Qty_Numbers,0))-(sum(ISNULL(RejQty,0)))) as PendingProcessQty_Numbers from DCStoresDetails_PAMS where 
				MJCNo=@MJCNo   AND Process=@PreviousProcess and PartID=@PartID and  DC_Stores_Status='Ready To Issue')
				
			end
			else
			begin
				select @PendingProcessQty_Numbers=(select (sum(ISNULL(Qty_Numbers,0))-(sum(ISNULL(RejQty,0)))) 
				as PendingProcessQty_Numbers from DCStoresDetails_PAMS where MJCNo=@MJCNo and PJCNo=isnull(@pjcno,'')  AND Process=@PreviousProcess and PartID=@PartID and
				DC_Stores_Status='Ready To Issue')
			end
		end

			
		print  @PendingProcessQty_Numbers 
		--print  @PJCInwardedQty_Numbers

		--select @PendingProcessQty_Numbers=case when  isnull(@PendingProcessQty_Numbers,0)<=0 then @GRNQty_Numbers else @PendingProcessQty_Numbers end 
		--select @PendingProcessQty_Numbers=(isnull(@PendingProcessQty_Numbers,0)-isnull(@PJCInwardedQty_Numbers,0))  
		select @PendingProcessQty_Numbers=(isnull(@PendingProcessQty_Numbers,0))  
		select @PendingProcessQty_Numbers AS PendingProcessQty_Numbers,@TotalIssuedQty as TotalIssuedQty


		return
	end


end
else
begin
	print 'It is assumed that whatever process currently doing is first process for that PJC'
	--declare @GRNQty_Numbers float
	--select @GRNQty_Numbers=0
	--select @PJCInwardedQty_Numbers=0
	select @GRNQty_Numbers=(select sum(ReceivedQty_NUmbers) from GrnNoGeneration_PAMS where GrnNo=@MJCNo)


	insert into #PJCListForMJC(PJCNo,PJCYear,PartID)
	select distinct PJCNo,PJCYear,PartID from ProcessJobCardHeaderCreation_PAMS WHERE MJCNo=@MJCNo AND PartID=@PartID AND PJCNo<>@PJCNo

	IF EXISTS(SELECT * FROM #PJCListForMJC)
	BEGIN

		insert into #FindPJCLevelFirstProcess(PartID,PJCNo,PJCYear,Process,Sequence,DCType,RowNum)
		select distinct D1.PARTID,d1.PJCNo,d1.PJCYear,d1.process,p2.sequence,p2.DCType, ROW_NUMBER() over (order by sequence asc) from DCNoGeneration_PAMS d1 
		inner join ProcessAndFGAssociation_PAMS p2 on d1.PartID=p2.PartID and d1.Process=p2.Process where d1.MJCNo=@MJCNo and d1.PartID=@PartID  
		order by Sequence asc

		update #PJCListForMJC set PJCFirstProcess=isnull(t1.pjcfirstprocess,''),DCType=isnull(t1.dctype,'')
		from
		(
		select distinct D1.PartID,d1.PJCNo,d1.PJCYear,d1.process as pjcfirstprocess,d1.dctype  from #FindPJCLevelFirstProcess d1 
		where rownum=1
		)t1 inner join  #PJCListForMJC t2 on T1.PartID=T2.PartID AND t1.PJCNo=t2.PJCNo and t1.PJCYear=t2.PJCYear

		UPDATE #PJCListForMJC SET PJCQty_Numbers=ISNULL(T1.AcceptedParts,0)
		FROM
		(
		select DISTINCT P1.PartID,p1.PJCNo,p1.PJCYear,p1.PJCFirstProcess,SUM(S1.AcceptedParts) AS AcceptedParts from #PJCListForMJC p1 
		INNER JOIN componentoperationpricing C1 ON C1.componentid=P1.PartID AND C1.Process=P1.PJCFirstProcess
		INNER JOIN ShiftProductionDetails S1 ON S1.MachineID=C1.machineid AND S1.ComponentID=C1.componentid AND S1.OperationNo=C1.operationno AND S1.WorkOrderNumber=P1.PJCNo AND ('20'+s1.PJCYear)=P1.PJCYear
		group by P1.PartID,p1.PJCNo,p1.PJCYear,p1.PJCFirstProcess
		)T1 INNER JOIN #PJCListForMJC T2 ON T1.PartID=T2.PartID AND T1.PJCNo=T2.PJCNo AND T1.PJCYear=T2.PJCYear AND T1.PJCFirstProcess=T2.PJCFirstProcess AND T2.DCType='Inhouse'

		UPDATE #PJCListForMJC SET PJCQty_Numbers=ISNULL(T1.AcceptedParts,0)
		FROM
		(
		select DISTINCT P1.PartID,p1.PJCNo,p1.PJCYear,p1.PJCFirstProcess,SUM(c1.Qty_Numbers) AS AcceptedParts from #PJCListForMJC p1 
		INNER JOIN DCStoresDetails_PAMS C1 ON C1.PartID=P1.PartID AND C1.PJCNo=P1.PJCNo and c1.PJCYear=p1.PJCYear and c1.Process=p1.PJCFirstProcess
		where c1.DC_Stores_Status='Ready To Issue'
		group by P1.PartID,p1.PJCNo,p1.PJCYear,p1.PJCFirstProcess
		)T1 INNER JOIN #PJCListForMJC T2 ON T1.PartID=T2.PartID AND T1.PJCNo=T2.PJCNo AND T1.PJCYear=T2.PJCYear AND T1.PJCFirstProcess=T2.PJCFirstProcess AND T2.DCType='VendoredOut'

		--select @PJCInwardedQty_Numbers=(select sum(PJCQty_Numbers) from #PJCListForMJC )

	end

	print @GRNQty_Numbers 
	--print @PJCInwardedQty_Numbers
	--select @PendingProcessQty_Numbers=isnull(@GRNQty_Numbers,0)-isnull(@PJCInwardedQty_Numbers,0)

	select @PendingProcessQty_Numbers=isnull(@GRNQty_Numbers,0)

	SELECT @PendingProcessQty_Numbers AS PendingProcessQty_Numbers,@TotalIssuedQty as TotalIssuedQty
end
end
