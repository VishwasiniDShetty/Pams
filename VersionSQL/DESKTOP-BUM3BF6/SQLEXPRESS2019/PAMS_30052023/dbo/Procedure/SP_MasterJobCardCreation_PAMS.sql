/****** Object:  Procedure [dbo].[SP_MasterJobCardCreation_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

/*
SP_MasterJobCardCreation_PAMS @GRNno=N'RM/GRN/1/2023-24',@FromDate=N'2023-01-03 00:00:00.000',@Materialid=N'M7070120',@ToDate=N'2023-12-03 00:00:00.000',@MJCNo=N'RM/GRN/1/2023-24',
@Param=N'ViewGRNForMasterJobCard'
SP_MasterJobCardCreation_PAMS @MJCNo=N'RM/GRN/1/2023-24',@Param=N'ViewProcessJobCardAfterFirstProcessDetails'
SP_MasterJobCardCreation_PAMS @MJCNo=N'RM/GRN/3/2023-24',@Param=N'ViewProcessJobCardBeforeFirstProcessDetails'


*/
CREATE PROCEDURE [dbo].[SP_MasterJobCardCreation_PAMS]
@Param NVARCHAR(50)='',
@FromDate datetime='',
@ToDate datetime='',
@GRNno nvarchar(50)='',
@MJCNo nvarchar(50)='',
@PJCYear nvarchar(4)='',
@IssuedQty float=0,
@UpdatedBy nvarchar(50)='',
@DCNo nvarchar(50)='',
@PartID nvarchar(50)='',
@PJCNo nvarchar(50)='',
@Materialid nvarchar(50)=''
AS
BEGIN

DECLARE @STRSQL NVARCHAR(MAX)
SELECT @STRSQL=''
create table #TempMasterJobCard
(
GRNNo nvarchar(50),
GRNID INT,
GRNDate datetime,
Materialid nvarchar(50),
UOM NVARCHAR(50),
invoicenumber nvarchar(50),
ReceivedQty float,
QualityApprovalStatus nvarchar(50),
MasterJobCardNo nvarchar(50),
Pams_DCNo nvarchar(50),
TotalAssignedPJC FLOAT,
TotalClosedPJC FLOAT,
RM_DCCount float,
ClosedRM_DCCount float,
ShowMJCClosure int default 0,
MJCStatus nvarchar(50),
MJCCloseRemarks nvarchar(max)
)

--create table #TempProcessJobCard
--(
--GRNNo nvarchar(50),
--Pams_DCNo nvarchar(50),
--MJCNo nvarchar(50),
--PJCNo nvarchar(50),
--IssuedPJCQty float,
--ReceivedPJCQty float,
--PendingPJCQty float
--)

CREATE TABLE #TempProcessJobCard
(
MasterJobCardNo nvarchar(50),
GRNNo nvarchar(50),
PartID NVARCHAR(50),
TotalRM_Pams nvarchar(50),
TotalRM_PAMS_KG float,
TotalRM_PAMS_Numbers float,
TotalRM_Pams_UOM NVARCHAR(50),
Available_kg float,
Available_Numbers float,
InwardedQty_InKG float,
InwardedQty_InNumbers float,
Received_uom nvarchar(50),
PJCID INT,
PJCNo nvarchar(50),
PJCIssuedQty float,
TotalPJCIssuedQty float,
PJCYear nvarchar(50),
PJCDate datetime,
MaxAllowedQty float,
MaxPJCNoAllowed float,
IssuedPJCCount float,
FinancialYear nvarchar(10),
DefaultPartbit int default 0,
RMBalanceQty_Numbers float
)




if @Param='ViewGRNForMasterJobCard'
BEGIN
	SELECT @STRSQL=''
	SELECT @STRSQL='insert into #TempMasterJobCard(GRNID,GRNNo,GRNDate,Materialid,invoicenumber,UOM,ReceivedQty,QualityApprovalStatus)
	SELECT G1.GRNID,g1.GRNNo,g1.GRNDate,g1.Materialid,G1.invoicenumber,R1.UOM,case when g1.uom=''NO.'' then G1.ReceivedQty_Numbers else ReceivedQty end as ReceivedQty,isnull(Qualitystatus,''Inspection Pending'') 
	FROM GrnNoGeneration_PAMS G1 LEFT JOIN  FinalInspectionTransaction_PAMS f1 on f1.MaterialID=G1.MaterialID and f1.InvoiceNumber=G1.Invoicenumber and f1.GRNNo=G1.GRNNo
	LEFT JOIN RawMaterialDetails_PAMS R1 ON R1.MaterialID=G1.MaterialID '
	SELECT @STRSQL=@STRSQL+'where (convert(nvarchar(10),g1.grndate,126)>='''+convert(nvarchar(10),@FromDate,126)+''' and convert(nvarchar(10),g1.grndate,126)<='''+convert(nvarchar(10),@ToDate,126)+''')
	or (g1.MaterialID like '''+'%'+@Materialid+'%'+''') or (g1.GrnNo like '''+'%'+@GRNno+'%'+''') '
	PRINT(@STRSQL)
	EXEC(@STRSQL)
	
	update #TempMasterJobCard set MasterJobCardNo=isnull(t1.MasterJobCardNo,'')
	from
	(select distinct m1.grnno,m1.MJCNo as MasterJobCardNo from MasterJobCardHeaderCreation_PAMS m1 
	inner join #TempMasterJobCard t1 on m1.GRNNo=t1.GRNNo
	)t1 inner join #TempMasterJobCard t2 on t1.grnno=t2.GRNNo
	
	update #TempMasterJobCard set Pams_DCNo=isnull(t2.Pams_DCNo,'')
	from
	(
	select distinct d1.GRNNo,d1.Materialid,d1.pams_dcno from DCNoGeneration_PAMS d1
	inner join #TempMasterJobCard t1 on t1.GRNNo=d1.GRNNo and t1.Materialid=d1.Materialid
	)t2 inner join #TempMasterJobCard t3 on t2.GRNNo=t3.grnno and t2.Materialid=t3.Materialid
	

	----------------------------------------------------------------------------MJC Closure logic starts -------------------------------------------------------------------------------------------------------

	update #TempMasterJobCard set TotalAssignedPJC=isnull(t1.TotalAssignedPJC,0)
	from
	(
	select distinct MJCNo,count(pjcno) as TotalAssignedPJC from ProcessJobCardHeaderCreation_PAMS
	group by MJCNo
	) t1 inner join #TempMasterJobCard t2 on t1.MJCNo=t2.MasterJobCardNo

		update #TempMasterJobCard set TotalClosedPJC=isnull(t1.TotalClosedPJC,0)
	from
	(
	select distinct MJCNo,count(pjcno) as TotalClosedPJC from ProcessJobCardHeaderCreation_PAMS
	where isnull(pjcstatus,'')='Closed'
	group by MJCNo
	) t1 inner join #TempMasterJobCard t2 on t1.MJCNo=t2.MasterJobCardNo

	update #TempMasterJobCard set RM_DCCount=isnull(t1.RM_DCCount,0)
	from
	(
		select distinct MJCNo, count(Pams_DCNo) as RM_DCCount from DCNoGeneration_PAMS d1 inner join ProcessAndFGAssociation_PAMS d2 on d1.PartID=d2.PartID and d1.Process=d2.Process
		where d2.Sequence=1
		group by MJCNo
	) t1 inner join #TempMasterJobCard t2 on t1.MJCNo=t2.MasterJobCardNo

	update #TempMasterJobCard set ClosedRM_DCCount=isnull(t1.RM_DCCount,0)
	from
	(
		select distinct MJCNo, count(Pams_DCNo) as RM_DCCount from DCNoGeneration_PAMS d1 inner join ProcessAndFGAssociation_PAMS d2 on d1.PartID=d2.PartID and d1.Process=d2.Process
		where d2.Sequence=1 and isnull(dcclosestatus,'')='Closed'
		group by MJCNo
	) t1 inner join #TempMasterJobCard t2 on t1.MJCNo=t2.MasterJobCardNo

	update #TempMasterJobCard set MJCStatus=isnull(t1.MJCStatus,'')
	from
	(
		select distinct MJCNo,isnull(MJCStatus,'') as MJCStatus from MasterJobCardHeaderCreation_PAMS
	) t1 inner join #TempMasterJobCard t2 on t1.MJCNo=t2.MasterJobCardNo

		update #TempMasterJobCard set MJCCloseRemarks=isnull(t1.MJCCloseRemarks,'')
	from
	(
		select distinct MJCNo,isnull(MJCCloseRemarks,'') as MJCCloseRemarks from MasterJobCardHeaderCreation_PAMS
	) t1 inner join #TempMasterJobCard t2 on t1.MJCNo=t2.MasterJobCardNo


		----------------------------------------------------------------------------MJC Closure logic starts -------------------------------------------------------------------------------------------------------

	select GRNNo,GRNDate,Materialid,ReceivedQty as ActualQty,uom,MasterJobCardNo,isnull(TotalAssignedPJC,0) as TotalAssignedPJC,isnull(TotalClosedPJC,0) as TotalClosedPJC,isnull(RM_DCCount,0) as RM_DCCount,isnull(ClosedRM_DCCount,0) as ClosedRM_DCCount,
	case when ((isnull(TotalClosedPJC,0)>=isnull(TotalAssignedPJC,0)) and (isnull(ClosedRM_DCCount,0)>=isnull(RM_DCCount,0))
	and (isnull(TotalAssignedPJC,0)<>0 and isnull(TotalClosedPJC,0)<>0 and isnull(RM_DCCount,0)<>0 and isnull(ClosedRM_DCCount,0)<>0) ) then 1 else 0 end as ShowMJCClose,isnull(MJCStatus,'Open') as MJCStatus,MJCCloseRemarks from #TempMasterJobCard where QualityApprovalStatus='Inspection Completed'  order by GRNID ASC


	return
END

if @Param='ViewProcessJobCardAfterFirstProcessDetails'
begin
	insert into #TempProcessJobCard(MasterJobCardNo,PartID,GRNNo,TotalRM_Pams_UOM)
	select MJCNo,PartID,GrnNo,UOM from DCNoGeneration_PAMS where MJCNo=@MJCNo AND (PartID=@PartID OR ISNULL(@PartID,'')='') and DCStatus='DC No. generated and confirmed' and isnull(pjcno,'')=''
	GROUP BY MJCNo,PartID,GrnNo,UOM

	update #TempProcessJobCard set TotalRM_PAMS_KG=isnull(t1.TotalRM_PAMS_KG,0),TotalRM_PAMS_Numbers=isnull(t1.TotalRM_PAMS_Numbers,0),TotalRM_Pams_UOM=isnull(t1.uom,'')
	from
	(
	select distinct GrnNo,sum(ReceivedQty) as TotalRM_PAMS_KG,sum(ReceivedQty_NUmbers) as TotalRM_PAMS_Numbers,uom from GrnNoGeneration_PAMS where GrnNo=@MJCNo and isnull(QualityStatus,'')='Inspection Completed'
	group by GrnNo,uom
	)t1 inner join #TempProcessJobCard t2 on t1.GrnNo=t2.GRNNo 

	update #TempProcessJobCard set PJCIssuedQty=isnull(t1.IssuedQty,0)
	from
	(
	select distinct GRNNo,PartID,MJCNo,sum(IssuedQty) as IssuedQty from ProcessJobCardHeaderCreation_PAMS
	group by GRNNo,PartID,MJCNo
	)
	t1 inner join #TempProcessJobCard m1 on m1.GRNNo=t1.GRNNo and m1.MasterJobCardNo=t1.MJCNo  and m1.PartID=t1.PartID

	--	update #TempProcessJobCard set TotalPJCIssuedQty=isnull(t1.IssuedQty,0)
	--from
	--(
	--select distinct GRNNo,MJCNo,sum(IssuedQty) as IssuedQty from ProcessJobCardHeaderCreation_PAMS
	--group by GRNNo,MJCNo
	--)
	--t1 inner join #TempProcessJobCard m1 on m1.GRNNo=t1.GRNNo and m1.MasterJobCardNo=t1.MJCNo  

	
		update #TempProcessJobCard set TotalPJCIssuedQty=isnull(t1.IssuedQty,0)
	from
	(
	select distinct GRNNo,MasterJobCardNo,sum(PJCIssuedQty) as IssuedQty from #TempProcessJobCard
	group by GRNNo,MasterJobCardNo
	)
	t1 inner join #TempProcessJobCard m1 on m1.GRNNo=t1.GRNNo and m1.MasterJobCardNo=t1.MasterJobCardNo  


	--update #TempProcessJobCard set Available_kg=isnull(t1.Available_kg,''),Available_Numbers=isnull(t1.Available_Numbers,''),Received_uom=isnull(t1.uom,'')
	--from
	--(
	--select distinct GRNNo,MJCNo,PartID,SUM(QTY_KG) AS Available_KG,SUM(Qty_Numbers) AS Available_Numbers,uom from DCStoresDetails_PAMS WHERE DC_Stores_Status='Ready To Issue'
	--AND ISNULL(PJCNO,'')<>''
	--GROUP BY GRNNo,MJCNo,PartID,UOM
	--)T1 INNER JOIN #TempProcessJobCard T2 ON T1.GRNNo=T2.GRNNo AND T1.MJCNo=T2.MasterJobCardNo AND T1.PartID=T2.PartID 

	UPDATE #TempProcessJobCard SET MaxAllowedQty=ISNULL(T1.MaxAllowedQty,0),MaxPJCNoAllowed=isnull(t1.MaxPJCNoAllowed,0)
	FROM
	(SELECT DISTINCT PartID,MaxAllowedQty,MaxPJCNoAllowed FROM FGDetails_PAMS
	)T1 INNER JOIN #TempProcessJobCard T2  ON T1.PartID=T2.PartID

	update #TempProcessJobCard set InwardedQty_InKG=isnull(T1.InwardedQty_InKG,0),InwardedQty_InNumbers=isnull(T1.InwardedQty_InNumbers,0),Received_uom=isnull(t1.uom,'')
	from
	(
	select distinct MJCNo,PartID,GrnNo,sum(Qty_KG) as InwardedQty_InKG,(sum(isnull(Qty_Numbers,0))-(sum(isnull(RejQty,0))+sum(isnull(settingscrap,0)))) as InwardedQty_InNumbers,UOM from DCStoresDetails_PAMS where MJCNo=@MJCNo and isnull(pjcno,'')='' and DC_Stores_Status='Ready To Issue'
	GROUP BY GRNNo,MJCNo,PartID,UOM
	) T1 INNER JOIN #TempProcessJobCard T2 ON T1.MJCNo=T2.MasterJobCardNo AND T1.PartID=T2.PartID AND T1.GRNNo=T2.GRNNo


	update #TempProcessJobCard set IssuedPJCCount=isnull(t1.IssuedPJCCount,0)
	from
	(
	select distinct GRNNo,PartID,MJCNo,count(distinct PJCNo) as IssuedPJCCount from ProcessJobCardHeaderCreation_PAMS where MJCNo=@MJCNo
	group by GRNNo,PartID,MJCNo
	)t1 inner join #TempProcessJobCard t2  on t1.GRNNo=t2.GRNNo and t1.PartID=t2.PartID and t1.MJCNo=t2.MasterJobCardNo


	update #TempProcessJobCard set Available_Numbers=isnull(t1.Available_Numbers,0)
	from
	(
	select distinct MasterJobCardNo,GRNNo,partid, case when  ISNULL(InwardedQty_InNumbers,0)>=ISNULL(PJCIssuedQty,0) 
	then  ISNULL(InwardedQty_InNumbers,0)-ISNULL(PJCIssuedQty,0)  else 0 end as Available_Numbers from #TempProcessJobCard
	) t1 inner join #TempProcessJobCard t2 on t1.MasterJobCardNo=t2.MasterJobCardNo and t1.GRNNo=t2.GRNNo and t1.PartID=t2.PartID

	update #TempProcessJobCard set DefaultPartbit=isnull(t1.DefaultPartbit,0)
	from
	(
	select distinct GRNNo,PartID,1 as DefaultPartbit  from GrnNoGeneration_PAMS
	) t1 inner join #TempProcessJobCard t2 on t1.GrnNo=t2.GRNNo and t1.PartID=t2.PartID
		
	--	update #TempProcessJobCard set RMBalanceQty_Numbers=isnull(t1.RMBalanceQty_Numbers,0)
	--from
	--(
	--select distinct MasterJobCardNo,GRNNo,case when (sum(distinct TotalRM_PAMS_Numbers)>sum(ISNULL(InwardedQty_InNumbers,0))) then 
	--(sum(distinct TotalRM_PAMS_Numbers)-sum(ISNULL(InwardedQty_InNumbers,0))) else 0 end as RMBalanceQty_Numbers from #TempProcessJobCard
	--group by MasterJobCardNo,GRNNo
	--) t1 inner join #TempProcessJobCard t2 on t1.MasterJobCardNo=t2.MasterJobCardNo and t1.GRNNo=t2.GRNNo

			update #TempProcessJobCard set RMBalanceQty_Numbers=isnull(t1.RMBalanceQty_Numbers,0)
	from
	(
	select distinct MasterJobCardNo,GRNNo,case when (sum(distinct TotalRM_PAMS_Numbers)>sum(distinct ISNULL(TotalPJCIssuedQty,0))) then 
	(sum(distinct isnull(TotalRM_PAMS_Numbers,0))-sum(distinct ISNULL(TotalPJCIssuedQty,0))) else 0 end as RMBalanceQty_Numbers from #TempProcessJobCard
	group by MasterJobCardNo,GRNNo
	) t1 inner join #TempProcessJobCard t2 on t1.MasterJobCardNo=t2.MasterJobCardNo and t1.GRNNo=t2.GRNNo





	select distinct MasterJobCardNo,GRNNo,TotalRM_PAMS_KG,TotalRM_PAMS_Numbers,TotalRM_Pams_UOM,PartID,PJCIssuedQty,InwardedQty_InKG,InwardedQty_InNumbers AS InwardedMJCQty_InNumbers,Available_Numbers,TotalPJCIssuedQty,
	Received_uom,MaxAllowedQty,MaxPJCNoAllowed,IssuedPJCCount,DefaultPartbit,RMBalanceQty_Numbers from #TempProcessJobCard
	where isnull(InwardedQty_InNumbers,0)<>0
	order by DefaultPartbit desc

end

if @Param='ViewProcessJobCardBeforeFirstProcessDetails'
begin
	insert into #TempProcessJobCard(MasterJobCardNo,PartID,GRNNo)
	select @MJCNo,PartID,@MJCNo from RawMaterialAndFGAssociation_PAMS where  (PartID=@PartID OR ISNULL(@PartID,'')='') and MaterialID=@Materialid

	update #TempProcessJobCard set TotalRM_PAMS_KG=isnull(t1.TotalRM_PAMS_KG,0),TotalRM_PAMS_Numbers=isnull(t1.TotalRM_PAMS_Numbers,0),TotalRM_Pams_UOM=isnull(t1.uom,'')
	from
	(
	select distinct GrnNo,sum(ReceivedQty) as TotalRM_PAMS_KG,sum(ReceivedQty_NUmbers) as TotalRM_PAMS_Numbers,uom from GrnNoGeneration_PAMS where GrnNo=@MJCNo and isnull(QualityStatus,'')='Inspection Completed'
	group by GrnNo,uom
	)t1 inner join #TempProcessJobCard t2 on t1.GrnNo=t2.GRNNo 

	update #TempProcessJobCard set PJCIssuedQty=isnull(t1.IssuedQty,0)
	from
	(
	select distinct GRNNo,MJCNo,partid, sum(IssuedQty) as IssuedQty from ProcessJobCardHeaderCreation_PAMS
	group by GRNNo,MJCNo,partid
	)
	t1 inner join #TempProcessJobCard m1 on m1.GRNNo=t1.GRNNo and m1.MasterJobCardNo=t1.MJCNo AND M1.PartID=T1.PARTID

	--update #TempProcessJobCard set TotalPJCIssuedQty=isnull(t1.IssuedQty,0)
	--from
	--(
	--select distinct GRNNo,MJCNo, sum(IssuedQty) as IssuedQty from ProcessJobCardHeaderCreation_PAMS
	--group by GRNNo,MJCNo
	--)
	--t1 inner join #TempProcessJobCard m1 on m1.GRNNo=t1.GRNNo and m1.MasterJobCardNo=t1.MJCNo 

	update #TempProcessJobCard set TotalPJCIssuedQty=isnull(t1.IssuedQty,0)
	from
	(
	select distinct GRNNo,MasterJobCardNo, sum(PJCIssuedQty) as IssuedQty from #TempProcessJobCard
	group by GRNNo,MasterJobCardNo
	)
	t1 inner join #TempProcessJobCard m1 on m1.GRNNo=t1.GRNNo and m1.MasterJobCardNo=t1.MasterJobCardNo 


	UPDATE #TempProcessJobCard SET MaxAllowedQty=ISNULL(T1.MaxAllowedQty,0),MaxPJCNoAllowed=isnull(t1.MaxPJCNoAllowed,0)
	FROM
	(SELECT DISTINCT PartID,MaxAllowedQty,MaxPJCNoAllowed FROM FGDetails_PAMS
	)T1 INNER JOIN #TempProcessJobCard T2  ON T1.PartID=T2.PartID

	declare @FirstProcess nvarchar(50)
	select @FirstProcess=''
	select @FirstProcess=(select process from ProcessAndFGAssociation_PAMS where PartID=(select top(1) partid from #TempProcessJobCard ) and Sequence=1)

	update #TempProcessJobCard set InwardedQty_InKG=isnull(T1.InwardedQty_InKG,0),InwardedQty_InNumbers=isnull(T1.InwardedQty_InNumbers,0),Received_uom=isnull(t1.uom,'')
	from
	(
	select distinct MJCNo,PartID,GrnNo,sum(Qty_KG) as InwardedQty_InKG,(sum(isnull(Qty_Numbers,0))-(sum(isnull(RejQty,0))+sum(isnull(settingscrap,0)))) as InwardedQty_InNumbers,UOM from DCStoresDetails_PAMS where MJCNo=@MJCNo and Process=@FirstProcess and DC_Stores_Status='Ready To Issue' --and isnull(pjcno,'')='' and DC_Stores_Status='Ready To Issue'
	GROUP BY GRNNo,MJCNo,PartID,UOM
	) T1 INNER JOIN #TempProcessJobCard T2 ON T1.MJCNo=T2.MasterJobCardNo AND T1.PartID=T2.PartID AND T1.GRNNo=T2.GRNNo


	--update #TempProcessJobCard set InwardedQty_InKG=isnull(T1.InwardedQty_InKG,0),InwardedQty_InNumbers=isnull(T1.InwardedQty_InNumbers,0),Received_uom=isnull(t1.uom,'')
	--from
	--(
	--select distinct GrnNo,sum(ReceivedQty) as InwardedQty_InKG,sum(ReceivedQty_NUmbers) as InwardedQty_InNumbers,uom from GrnNoGeneration_PAMS where GrnNo=@MJCNo
	--group by GrnNo,uom
	--) T1 INNER JOIN #TempProcessJobCard T2 ON  T1.GRNNo=T2.GRNNo

	update #TempProcessJobCard set IssuedPJCCount=isnull(t1.IssuedPJCCount,0)
	from
	(
	select distinct GRNNo,PartID,MJCNo,count(distinct PJCNo) as IssuedPJCCount from ProcessJobCardHeaderCreation_PAMS where MJCNo=@MJCNo
	group by GRNNo,PartID,MJCNo
	)t1 inner join #TempProcessJobCard t2  on t1.GRNNo=t2.GRNNo and t1.PartID=t2.PartID and t1.MJCNo=t2.MasterJobCardNo



	--update #TempProcessJobCard set Available_Numbers=isnull(t1.Available_Numbers,0)
	--from
	--(
	--select distinct MasterJobCardNo,GRNNo,case when  max(ISNULL(InwardedQty_InNumbers,0))>=max(ISNULL(TotalPJCIssuedQty,0) ) 
	--then  max(ISNULL(InwardedQty_InNumbers,0))-max(ISNULL(TotalPJCIssuedQty,0) ) else 0 end as Available_Numbers from #TempProcessJobCard
	--group by MasterJobCardNo,GRNNo
	--) t1 inner join #TempProcessJobCard t2 on t1.MasterJobCardNo=t2.MasterJobCardNo and t1.GRNNo=t2.GRNNo


	update #TempProcessJobCard set Available_Numbers=isnull(t1.Available_Numbers,0)
	from
	(
	select distinct MasterJobCardNo,GRNNo,partid, case when  max(ISNULL(TotalRM_PAMS_Numbers,0))>=max(ISNULL(PJCIssuedQty,0) ) 
	then  max(ISNULL(TotalRM_PAMS_Numbers,0))-max(ISNULL(PJCIssuedQty,0) ) else 0 end as Available_Numbers from #TempProcessJobCard
	group by MasterJobCardNo,GRNNo,PartID
	) t1 inner join #TempProcessJobCard t2 on t1.MasterJobCardNo=t2.MasterJobCardNo and t1.GRNNo=t2.GRNNo and t1.PartID=t2.PartID


	--select distinct MasterJobCardNo,GRNNo,TotalRM_PAMS_KG,TotalRM_PAMS_Numbers,TotalRM_Pams_UOM,PartID,PJCIssuedQty,InwardedQty_InKG,InwardedQty_InNumbers AS InwardedMJCQty_InNumbers,ISNULL(InwardedQty_InNumbers,0)-ISNULL(PJCIssuedQty,0) AS Available_Numbers,
	--Received_uom,MaxAllowedQty,MaxPJCNoAllowed,IssuedPJCCount from #TempProcessJobCard
	--where isnull(InwardedQty_InNumbers,0)<>0

	update #TempProcessJobCard set DefaultPartbit=isnull(t1.DefaultPartbit,0)
	from
	(
	select distinct GRNNo,PartID,1 as DefaultPartbit from GrnNoGeneration_PAMS
	) t1 inner join #TempProcessJobCard t2 on t1.GrnNo=t2.GRNNo and t1.PartID=t2.PartID

	--update #TempProcessJobCard set RMBalanceQty_Numbers=isnull(t1.RMBalanceQty_Numbers,0)
	--from
	--(
	--select distinct MasterJobCardNo,GRNNo,case when (sum(distinct TotalRM_PAMS_Numbers)>sum(ISNULL(InwardedQty_InNumbers,0))) then (sum(distinct TotalRM_PAMS_Numbers)-sum(ISNULL(InwardedQty_InNumbers,0))) else 0 end as RMBalanceQty_Numbers from #TempProcessJobCard
	--group by MasterJobCardNo,GRNNo
	--) t1 inner join #TempProcessJobCard t2 on t1.MasterJobCardNo=t2.MasterJobCardNo and t1.GRNNo=t2.GRNNo

		update #TempProcessJobCard set RMBalanceQty_Numbers=isnull(t1.RMBalanceQty_Numbers,0)
	from
	(
	select distinct MasterJobCardNo,GRNNo,case when (sum(distinct TotalRM_PAMS_Numbers)>sum(distinct ISNULL(TotalPJCIssuedQty,0))) 
	then (sum(distinct TotalRM_PAMS_Numbers)-sum(distinct ISNULL(TotalPJCIssuedQty,0))) else 0 end as RMBalanceQty_Numbers from #TempProcessJobCard
	group by MasterJobCardNo,GRNNo
	) t1 inner join #TempProcessJobCard t2 on t1.MasterJobCardNo=t2.MasterJobCardNo and t1.GRNNo=t2.GRNNo

	

		select distinct MasterJobCardNo,GRNNo,TotalRM_PAMS_KG,TotalRM_PAMS_Numbers,TotalRM_Pams_UOM,PartID,PJCIssuedQty,
		InwardedQty_InKG,InwardedQty_InNumbers AS InwardedMJCQty_InNumbers,Available_Numbers,TotalPJCIssuedQty,
	Received_uom,MaxAllowedQty,MaxPJCNoAllowed,IssuedPJCCount,DefaultPartbit,RMBalanceQty_Numbers from #TempProcessJobCard
	order by DefaultPartbit desc
	--where isnull(InwardedQty_InNumbers,0)<>0

end



if @Param='ViewJobCardHistory'
begin

	select p1.*,case when isnull(p2.PJCNo,'')<>'' then '1' else '0' end as InwardBit from ProcessJobCardHeaderCreation_PAMS p1 
	left join (select distinct GRNNo,PartID,MJCNo,PJCNo,PJCYear from DCStoresDetails_PAMS where MJCNo=@MJCNo and PartID=@PartID)
	p2 on p1.GRNNo=p2.GRNNo and p1.PartID=p2.PartID and p1.MJCNo=p2.MJCNo and p1.PJCNo=p2.PJCNo and p1.PJCYear=p2.PJCYear
	where p1.MJCNo=@MJCNo and p1.PartID=@PartID

END

end
