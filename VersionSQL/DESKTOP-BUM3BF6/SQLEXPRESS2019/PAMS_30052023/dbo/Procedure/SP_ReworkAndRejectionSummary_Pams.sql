/****** Object:  Procedure [dbo].[SP_ReworkAndRejectionSummary_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

/*
SP_ReworkAndRejectionSummary_Pams @PartID=N'',@Param=N'PJCDashboardSummary'
SP_ReworkAndRejectionSummary_Pams '2023-02-07 00:00:00.000','2023-03-20 00:00:00.000','RemworkRejectionSummary'

*/
CREATE procedure [dbo].[SP_ReworkAndRejectionSummary_Pams]
@StartDate datetime='',
@Enddate datetime='',
@Param nvarchar(50)='',
@PartID NVARCHAR(MAX)=''
as
begin

create table #PJCSummary
(
AutoID BIGINT IDENTITY(1,1),
PartID NVARCHAR(50),
PartDescription nvarchar(2000),
GRNID INT,
GRNNo nvarchar(50),
PJCNo nvarchar(50),
PJCYear nvarchar(50),
PJCIssuedQty float DEFAULT 0,
ProducedQty float DEFAULT 0,
AcceptedQty float DEFAULT 0,
RejectionQty float DEFAULT 0,
QualityIncharge nvarchar(50),
Quality_TS DATETIME,
LineIncharge nvarchar(50),
LineIncharge_TS DATETIME,
Status nvarchar(50)
)

--create table #ReworkRejTemp
--(
--date datetime,
--shift nvarchar(50),
--partid nvarchar(50),
--OperationNo nvarchar(50),
--mjcno nvarchar(50),
--PJCNo nvarchar(50),
--PJCYear nvarchar(50),
--RejectionQty nvarchar(50), 
--RejectionReason nvarchar(1000),
--MarkedForReworkQty float,
--ReworkReason nvarchar(1000)
--)

DECLARE @Strsql nvarchar(max)
declare @StrComponentID nvarchar(max)
select @Strsql=''
select @StrComponentID=''

if isnull(@PartID,'')<>''
begin
	select @StrComponentID='And P1.partid in ('+@PartID+')'
end


if @Param='RemworkRejectionSummary'	
begin
	select distinct p1.date,p1.shift,p1.partid,p1.OperationNo,p1.mjcno,p1.PJCNo,p1.PJCYear,p1.RejectionQty,p1.RejectionReason,p2.MarkedForReworkQty,p2.ReworkReason from PJCRejectionDetails_PAMS p1
	left join (select distinct date,shift,PartID,operationno,MjcNo,pjcno,pjcyear,MarkedForReworkQty,ReworkReason from PJCMarkedForReworkDetails_PAMS) p2 on p1.Date=p2.Date and p1.Shift=p2.Shift and p1.PartID=p2.PartID and p1.OperationNo=p2.OperationNo and p1.MjcNo=p2.MjcNo and p1.PJCNo=p2.PJCNo and p1.PJCYear=p2.PJCYear
	where (convert(nvarchar(10),p1.Date,126)>=convert(nvarchar(10),@startdate,126) and convert(nvarchar(10),p1.Date,126)<=convert(nvarchar(10),@enddate,126))
	and isnull(p1.RejectionQty,0)<>0
end

if @Param='PJCDashboardSummary'
begin
	SELECT @STRSQL=''
	SELECT @STRSQL=@STRSQL+'insert into #PJCSummary(PartID,PartDescription,GRNID,GRNNo,PJCNo,PJCYear, Status,PJCIssuedQty)
	SELECT DISTINCT P1.PartID,P2.PartDescription,t2.grnid,P1.MJCNo,P1.PJCNo,P1.PJCYear,p1.pjcstatus,p1.IssuedQty  FROM ProcessJobCardHeaderCreation_PAMS P1
	inner join (select distinct grnno,grnid from GrnNoGeneration_PAMS) t2 on p1.MJCNo=t2.grnno
	LEFT JOIN FGDetails_PAMS P2 ON P1.PartID=P2.PartID WHERE 1=1 '
	SELECT @STRSQL=@STRSQL+@StrComponentID
	PRINT(@STRSQL)
	EXEC(@STRSQL)

	update #PJCSummary set ProducedQty=isnull(t1.pRODQTY,0)
	from
	(SELECT DISTINCT PartID,MJCNo,PJCNo,PJCYear,SUM(ConfirmedReceiveQty) AS pRODQTY  FROM InspectionReadyDetailsSave_Pams
	where BatchBit=0
	GROUP BY PartID,MJCNo,PJCNo,PJCYear
	) T1 INNER JOIN #PJCSummary T2 ON T1.PartID=T2.PartID AND T1.MJCNo=T2.GRNNo AND T1.PJCNo=T2.PJCNo AND ('20'+T1.PJCYear)=T2.PJCYear

	update #PJCSummary set AcceptedQty=isnull(t1.pRODQTY,0)
	from
	(SELECT DISTINCT PartID,PJCNo,PJCYear,SUM(Qty_OfferedToFG) AS pRODQTY  FROM FGOfferedQtyDetails_Pams
	GROUP BY PartID,PJCNo,PJCYear
	) T1 INNER JOIN #PJCSummary T2 ON T1.PartID=T2.PartID AND T1.PJCNo=T2.PJCNo AND ('20'+T1.PJCYear)=T2.PJCYear



	--SELECT DISTINCT P1.PartID,P2.PartDescription,P1.MJCNo,P1.PJCNo,P1.PJCYear,SUM(P1.Prod_Qty),SUM(P1.AcceptedQty),MAX(P1.QualityIncharge),MAX(P1.Quality_TS),MAX(P1.LineIncharge),MAX(P1.LineIncharge_TS),max(P3.PJCStatus) as PJCStatus  FROM PJCProductionEditedDetails_PAMS P1
	--LEFT JOIN FGDetails_PAMS P2 ON P1.PartID=P2.PartID
	--LEFT JOIN ProcessJobCardHeaderCreation_PAMS P3 ON P1.PJCNo=P3.PJCNo
	--WHERE (CONVERT(NVARCHAR(10),DATE,126)>=CONVERT(NVARCHAR(10),@StartDate,126) AND CONVERT(NVARCHAR(10),DATE,126)<=CONVERT(NVARCHAR(10),@Enddate,126))
	--GROUP BY P1.PartID,P2.PartDescription,P1.MJCNo,P1.PJCNo,P1.PJCYear

	UPDATE #PJCSummary SET RejectionQty=ISNULL(T1.REJQTY,0)
	FROM
	(
	SELECT DISTINCT PartID,MjcNo,PJCNo,PJCYear,sum(RejectionQty) as REJQTY FROM PJCRejectionDetails_PAMS
	group by PartID,MjcNo,PJCNo,PJCYear
	)t1 inner join #PJCSummary t2 on t1.PartID=t2.PartID and t1.MjcNo=t2.GRNNo and t1.PJCNo=t2.PJCNo and t1.PJCYear=t2.PJCYear

	--UPDATE #PJCSummary SET GRNID=ISNULL(T1.GRNID

	select * from #PJCSummary order by GRNID,PJCNo

end
	
end
