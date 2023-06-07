/****** Object:  Procedure [dbo].[SP_WIPScreenDetails_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

/*
SP_WIPScreenDetails_Pams @CustomerID=N'TVSM',@Date=N'2023-04-18 00:00:00.000'
*/
CREATE procedure [dbo].[SP_WIPScreenDetails_Pams]
@CustomerID nvarchar(50)='',
@Date datetime=''
as
begin

create table #PartDetails
(
AutoID BIGINT IDENTITY(1,1),
PartID NVARCHAR(50),
PartDescription nvarchar(2000),
CustomerID NVARCHAR(100)
)

CREATE TABLE #WIPDetails
(
MaterialID NVARCHAR(50),
PartID NVARCHAR(50),
PartDescription nvarchar(2000),
Process nvarchar(50),
SortOrder int,
DCType nvarchar(50),
Customer nvarchar(100),
RMQty float default 0,
DCIssuedQty float default 0,
DCReceivedQty float default 0,
Qty float default 0,
RejectionQty float default 0,
ReworkQty float default 0,
StoreQty float default 0,
MarkedForReworkSum float default 0,
MarkedForOKSum FLOAT DEFAULT 0,
MarkedForRejectSum float default 0,
Qty_Sum float default 0,
ReadyToIssueQty float default 0,
InwardInspectionTotal float default 0
)



INSERT INTO #PartDetails (PartID,PartDescription,CustomerID)
SELECT DISTINCT F1.PartID,PartDescription,CustomerID FROM FGDetails_PAMS F1
INNER JOIN (SELECT DISTINCT PARTID FROM RawMaterialAndFGAssociation_PAMS ) F2  ON F1.PartID=F2.PartID WHERE CustomerID LIKE '%'+@CustomerID+'%'


DECLARE @I INT
DECLARE @Count int

select @I=1
select @Count=0

select @Count=(select max(AutoID) from #PartDetails)

while (@i<=@Count)
begin
	declare @Partid nvarchar(50)
	select @Partid=''
	declare @PartDescription nvarchar(50)
	select @PartDescription=''
	SELECT @Partid=(SELECT PARTID FROM #PartDetails WHERE AutoID=@I)

	insert into #WIPDetails (PartID,PartDescription,Process,SortOrder,Customer,DCType)
	select distinct PartID,PartDescription,'RM',0,CustomerID,'VendoredOut' from #PartDetails WHERE PartID=@Partid

	INSERT INTO #WIPDetails(PartID,PartDescription,Process,SortOrder,Customer,DCType)
	select distinct P1.PartID,P1.PartDescription,P2.PROCESS,P2.SEQUENCE,CustomerID,p2.DCType from #PartDetails P1
	INNER JOIN (SELECT DISTINCT PARTID,PROCESS,Sequence,DCType FROM ProcessAndFGAssociation_PAMS WHERE PartID=@Partid) P2 ON P1.PartID=P2.PartID
	WHERE P1.PartID=@Partid AND P2.Process<>'fg'

	insert into #WIPDetails (PartID,PartDescription,Process,SortOrder,Customer,DCType)
	select distinct PartID,PartDescription,'Under Inspection',100,CustomerID,'VendoredOut' from #PartDetails WHERE PartID=@Partid

	
	insert into #WIPDetails (PartID,PartDescription,Process,SortOrder,Customer,DCType)
	select distinct PartID,PartDescription,'FG',101,CustomerID,'Inhouse' from #PartDetails WHERE PartID=@Partid

	SET @I=@I+1
END

UPDATE #WIPDetails SET MaterialID=ISNULL(T1.MaterialID,'')
FROM
(
	SELECT DISTINCT R1.MaterialID,R1.PartID FROM RawMaterialAndFGAssociation_PAMS R1
	INNER JOIN #PartDetails R2 ON R1.PartID=R2.PartID
) T1 INNER JOIN #WIPDetails ON #WIPDetails.PartID=T1.PartID


update #WIPDetails set RMQty=isnull(t1.qty,0)
from
(
select distinct MaterialID,sum(ReceivedQty_NUmbers) AS Qty from GrnNoGeneration_PAMS where QualityStatus='Inspection Completed' and GRNStatus='Open' and (convert(nvarchar(10),GRNDate,126)<=convert(nvarchar(10),@date,126))
GROUP BY MaterialID
) t1 inner join #WIPDetails  t2 on t1.MaterialID=t2.MaterialID and t2.Process='RM'


update #WIPDetails set Qty=isnull(t1.qty,0)
from
(
select distinct MaterialID,sum(ReceivedQty_NUmbers) AS Qty from GrnNoGeneration_PAMS where QualityStatus='Inspection Completed' and GRNStatus='Open' and (convert(nvarchar(10),GRNDate,126)<=convert(nvarchar(10),@date,126))
GROUP BY MaterialID
) t1 inner join #WIPDetails  t2 on t1.MaterialID=t2.MaterialID and t2.Process='RM'

UPDATE #WIPDetails set DCIssuedQty=isnull(t1.IssuedQty,0)
from
(
select distinct partid,process,sum(Qty_Numbers) as IssuedQty from DCNoGeneration_PAMS where DCStatus='DC No. generated and confirmed'
and (convert(nvarchar(10),dcdate,126)<=convert(nvarchar(10),@date,126))
group by PartID,process
) t1 inner join #WIPDetails t2 on t1.PartID=t2.Partid and t1.Process=t2.Process

UPDATE #WIPDetails set ReadyToIssueQty=isnull(t1.receivedQty,0)
from
(
select distinct partid,process,sum(Qty_Numbers) as receivedQty from DCStoresDetails_PAMS where DC_Stores_Status='Ready To Issue'
and (convert(nvarchar(10),vendordcdate,126)<=convert(nvarchar(10),@date,126))
group by PartID,process
) t1 inner join #WIPDetails t2 on t1.PartID=t2.Partid and t1.Process=t2.Process  and t2.Process not in ('RM','FG','Under Inspection')


UPDATE #WIPDetails set DCReceivedQty=isnull(t1.receivedQty,0)
from
(
select distinct partid,process,sum(Qty_Numbers) as receivedQty from DCStoresDetails_PAMS where DC_Stores_Status='Ready To Issue'
and (convert(nvarchar(10),vendordcdate,126)<=convert(nvarchar(10),@date,126))
group by PartID,process
) t1 inner join #WIPDetails t2 on t1.PartID=t2.Partid and t1.Process=t2.Process AND T2.DCType='VendoredOut'

UPDATE #WIPDetails set DCReceivedQty=isnull(t1.receivedQty,0)
from
(
select distinct partid,process,sum(AcceptedQty) as receivedQty from PJCProductionEditedDetails_PAMS P1
INNER JOIN (SELECT DISTINCT PJCNo,PJCStatus FROM ProcessJobCardHeaderCreation_PAMS) P2 ON P1.PJCNo=P2.PJCNo
WHERE P2.PJCStatus='Open' and (isnull(p1.LineInchargeStatus,'')<>'Approved' and isnull(p1.QualityStatus,'')<>'Approved')
and (convert(nvarchar(10),date,126)<=convert(nvarchar(10),@date,126))
group by PartID,process
) t1 inner join #WIPDetails t2 on t1.PartID=t2.Partid and t1.Process=t2.Process AND T2.DCType='Inhouse'

update  #WIPDetails set Qty=isnull(DCIssuedQty,0)-isnull(DCReceivedQty,0) where process not in ('RM','FG','Under Inspection') and DCType not in ('Inhouse')

update  #WIPDetails set Qty=isnull(DCReceivedQty,0) where process not in ('RM','FG','Under Inspection') and DCType in ('Inhouse')


update #WIPDetails set Qty=isnull(t1.Qty,0)
from
(
	select distinct i1.partid,(sum(distinct isnull(AcceptedQtyFromInspection,0))-SUM(distinct isnull(f2.FinalReceivedFGQty,0))) as Qty from InspectionReadyDetailsSave_Pams i1 
	inner join (select distinct pjcno,PJCStatus from ProcessJobCardHeaderCreation_PAMS ) i2 on i1.PJCNo=i2.PJCNo
	left join(select distinct PartID, FinalReceivedFGQty from FinalFGReceivedDetails_Pams) f2 on i1.PartID=f2.PartID
	where i2.PJCStatus='Open' and isnull(i1.UpdatedTSQuality,'')<>''
	group by i1.partid
) t1 inner join #WIPDetails t2 on t1.PartID=t2.PartID and t2.Process='Under Inspection'


update #WIPDetails set Qty=isnull(t1.Qty,0)
from
(
	select distinct i1.partid,(sum(distinct isnull(i1.FinalReceivedFGQty,0))-sum(distinct isnull(f2.DispatchQty,0))) as Qty from FinalFGReceivedDetails_Pams i1 
	inner join (select distinct pjcno,PJCStatus from ProcessJobCardHeaderCreation_PAMS ) i2 on i1.PJCNo=i2.PJCNo
	left join(select distinct PartID, DispatchQty from DispatchDetails_Pams) f2 on i1.PartID=f2.PartID
	where i2.PJCStatus='Open'
	group by i1.partid
) t1 inner join #WIPDetails t2 on t1.PartID=t2.PartID and t2.Process='FG'

-------------------------------------------------------------Rejection Qty Calc Starts---------------------------------------------------------------------------

update #WIPDetails set RejectionQty=isnull(t1.RejectionQty,0)
from
(
	select distinct PartID,sum(rejqty) as RejectionQty from DCStoresDetails_PAMS where DC_Stores_Status='Ready To Issue'
	group by PartID
) t1 inner join #WIPDetails t2 on t1.PartID=t2.PartID and t2.Process='RM'


update #WIPDetails set RejectionQty=isnull(RejectionQty,0)+isnull(t1.SettingScrap,0)
from
(	
	select distinct PartID,sum(SettingScrap) as SettingScrap from DCStoresDetails_PAMS where DC_Stores_Status='Ready To Issue'
	group by PartID
) t1 inner join #WIPDetails t2 on t1.PartID=t2.PartID AND t2.Process='RM'

update #WIPDetails set RejectionQty=isnull(RejectionQty,0)+isnull(t1.rejQty,0)
from
(
	select distinct partid,sum(RejectionQty) as rejQty from PJCRejectionDetails_PAMS
	group by partid
) t1 inner join #WIPDetails t2 on t1.partid=t2.partid and t2.Process='RM'

update #WIPDetails set RejectionQty=isnull(RejectionQty,0)+isnull(t1.rejQty,0)
from
(
	select distinct partid,sum(RejectionQty) as rejQty from QualityRejectionDetails_Pams
	group by partid
) t1 inner join #WIPDetails t2 on t1.partid=t2.partid and t2.Process='RM'

-------------------------------------------------------------Rejection Qty Calc ends---------------------------------------------------------------------------

-------------------------------------------------------------Rejection Qty Calc Starts---------------------------------------------------------------------------

update #WIPDetails set RejectionQty=isnull(t1.RejectionQty,0)
from
(
	select distinct PartID,sum(rejqty) as RejectionQty from DCStoresDetails_PAMS where DC_Stores_Status='Ready To Issue'
	group by PartID
) t1 inner join #WIPDetails t2 on t1.PartID=t2.PartID and t2.Process='RM'


update #WIPDetails set RejectionQty=isnull(RejectionQty,0)+isnull(t1.SettingScrap,0)
from
(	
	select distinct PartID,sum(SettingScrap) as SettingScrap from DCStoresDetails_PAMS where DC_Stores_Status='Ready To Issue'
	group by PartID
) t1 inner join #WIPDetails t2 on t1.PartID=t2.PartID AND t2.Process='RM'

update #WIPDetails set RejectionQty=isnull(RejectionQty,0)+isnull(t1.rejQty,0)
from
(
	select distinct partid,sum(RejectionQty) as rejQty from PJCRejectionDetails_PAMS
	group by partid
) t1 inner join #WIPDetails t2 on t1.partid=t2.partid and t2.Process='RM'

update #WIPDetails set RejectionQty=isnull(RejectionQty,0)+isnull(t1.rejQty,0)
from
(
	select distinct partid,sum(RejectionQty) as rejQty from QualityRejectionDetails_Pams
	group by partid
) t1 inner join #WIPDetails t2 on t1.partid=t2.partid and t2.Process='RM'

-------------------------------------------------------------MarkedForReworkSum Qty Calc ends---------------------------------------------------------------------------
update #WIPDetails set MarkedForReworkSum=isnull(MarkedForReworkSum,0)+isnull(t1.markedforreworkqty,0)
from
(
	select distinct partid,sum(t1.markedforreworkqty) as markedforreworkqty 
	from
	(select distinct date,shift,partid,operationno,mjcno,pjcno,markedforreworkqty from PJCMarkedForReworkDetails_PAMS)
	t1
	group by partid
) t1 inner join #WIPDetails t2 on t1.partid=t2.partid and t2.Process='RM'

update #WIPDetails set MarkedForReworkSum=isnull(MarkedForReworkSum,0)+isnull(t1.markedforreworkqty,0)
from
(
	select distinct partid,sum(t1.markedforreworkqty) as markedforreworkqty 
	from
	(select distinct updatedtsproduction,partid,operationno,mjcno,pjcno,markedforreworkqty from QualityReworkDetails_Pams)
	t1
	group by partid
) t1 inner join #WIPDetails t2 on t1.partid=t2.partid and t2.Process='RM'

-------------------------------------------------------------MarkedForReworkSum Qty Calc ends---------------------------------------------------------------------------

-------------------------------------------------------------Update ReworkQty Qty Calc ends---------------------------------------------------------------------------
update #WIPDetails set markedforoksum=isnull(markedforoksum,0)+isnull(t1.okqty,0),MarkedForRejectSum=isnull(MarkedForRejectSum,0)+isnull(t1.RejSum,0)
from
(
	select distinct partid,sum(okqty) as okqty,sum(rejectionqty) as RejSum from PJCMarkedForReworkDetails_PAMS
	group by partid
) t1 inner join #WIPDetails t2 on t1.partid=t2.partid and t2.Process='RM'

update #WIPDetails set markedforoksum=isnull(markedforoksum,0)+isnull(t1.okqty,0),MarkedForRejectSum=isnull(MarkedForRejectSum,0)+isnull(t1.RejSum,0)
from
(
	select distinct partid,sum(okqty) as okqty,sum(rejectionqty) as RejSum from QualityReworkDetails_Pams
	group by partid
) t1 inner join #WIPDetails t2 on t1.partid=t2.partid and t2.Process='RM'

-------------------------------------------------------------update ReworkQty Qty Calc ends---------------------------------------------------------------------------

update #WIPDetails set ReworkQty=isnull(MarkedForReworkSum,0)-(isnull(markedforoksum,0)+isnull(MarkedForRejectSum,0)) where Process='RM'

update #WIPDetails set Qty_Sum=isnull(t1.qty,0)
from
(
	select distinct partid,sum(QTY) AS Qty FROM #WIPDetails where process<>'RM'
	GROUP BY partid
) T1 INNER JOIN #WIPDetails T2 ON T1.PARTID=T2.PARTID AND T2.PROCESS='RM'

update #WIPDetails set Qty_Sum=ISNULL(Qty_Sum,0)+isnull(t1.qty,0)
from
(
	select distinct partid,sum(REJECTIONQTY) AS Qty FROM #WIPDetails 
	GROUP BY partid
) T1 INNER JOIN #WIPDetails T2 ON T1.PARTID=T2.PARTID AND T2.PROCESS='RM'

update #WIPDetails set StoreQty=case when (ISNULL(rmqty,0)>=isnull(Qty_Sum,0)) then (ISNULL(rmqty,0)-isnull(Qty_Sum,0)) else 0 end where process='RM'

UPDATE #WIPDetails SET InwardInspectionTotal=isnull(t1.InwardInspectionTotal,0)
from
(
select distinct partid,sum(Qty_Numbers) as InwardInspectionTotal from DCStoresDetails_PAMS where isnull(DC_Stores_Status,'')='Offered To Inspection' and isnull(Quality_Status,'')=''
group by partid
) t1 inner join #WIPDetails t2 on t1.PartID=t2.PartID and t2.Process='RM'


SELECT MaterialID,PartID,PartDescription,Process,SortOrder,DCType,Customer ,RMQty,Qty_Sum, DCIssuedQty ,DCReceivedQty ,Qty,RejectionQty ,ReworkQty ,StoreQty,ReadyToIssueQty,InwardInspectionTotal  FROM #WIPDetails
order by partid,sortorder

end
