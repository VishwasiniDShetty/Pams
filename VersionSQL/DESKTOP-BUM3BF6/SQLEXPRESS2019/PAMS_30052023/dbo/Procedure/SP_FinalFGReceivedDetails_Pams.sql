/****** Object:  Procedure [dbo].[SP_FinalFGReceivedDetails_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

/*
SP_FinalFGReceivedDetails_Pams @FromDate=N'2023-01-31',@ToDate=N'2023-03-31', @Param=N'View1'
SP_FinalFGReceivedDetails_Pams @Param=N'View2'

*/
CREATE procedure [dbo].[SP_FinalFGReceivedDetails_Pams]
@FromDate datetime='',
@ToDate datetime='',
@PartID NVARCHAR(50)='',
@PJCNo nvarchar(50)='',
@PJCYear NVARCHAR(50)='',
@FinalreceivedFGQty FLOAT=0,
@Date DATETIME='',
@UpdatedBy NVARCHAR(50)='',
@UpdatedTS DATETIME='',
@Param nvarchar(50)='',
@Remarks nvarchar(50)=''

AS


create table #FG
(
Date date,
PartID nvarchar(50),
pjcno nvarchar(50),
PJCYear nvarchar(50),
QtyOfferedByInspection float,
FGStores FLOAT,
InspectionCompletedNoTakenForFG float,
CustomerID NVARCHAR(50),
Remarks nvarchar(2000)
)

create table #view2
(
PartID nvarchar(50),
TotalFGStores nvarchar(50),
LatestUpdatedTS datetime,
LatestUpdatedBy nvarchar(50)
)


BEGIN
		if @Param='Save'
		begin	
			insert into FinalFGReceivedDetails_Pams(PartID,pjcno,PJCYear,FinalreceivedFGQty,Date,UpdatedBy,UpdatedTS,Remarks)
			VALUES(@PartID,@PJCNo,@PJCYear,@FinalreceivedFGQty,@Date,@UpdatedBy,@UpdatedTS,@Remarks)
		END

		IF @Param='View1'
		begin
			insert into #FG(Date,PartID,pjcno,PJCYear,QtyOfferedByInspection)
			select F1.OfferedDate, f1.PartID,f1.PJCNo,f1.PJCYear,sum(f1.Qty_OfferedToFG) from FGOfferedQtyDetails_Pams f1 
			WHERE (CONVERT(NVARCHAR(10),F1.OfferedDate,126)>= CONVERT(NVARCHAR(10),@FromDate,126) 
			AND CONVERT(NVARCHAR(10),F1.OfferedDate,126)<=CONVERT(NVARCHAR(10),@ToDate,126))
			group by F1.OfferedDate, f1.PartID,f1.PJCNo,f1.PJCYear


			update #FG set FGStores=isnull(t1.FinalreceivedFGQty,0)
			from
			(
				select distinct Date,partid,PJCNo,pjcyear,sum(FinalreceivedFGQty) as FinalreceivedFGQty from  FinalFGReceivedDetails_Pams
				group by Date, partid,PJCNo,pjcyear
			)t1 inner join #FG t2 on t1.Date=t2.Date and t1.partid=t2.partid and t1.PJCNo=t2.PJCNo and t1.pjcyear=t2.pjcyear

			update #FG set Remarks=(t1.Rmrs)
			from
			(
			select distinct Date,partid,PJCNo,pjcyear,STUFF((SELECT distinct ',' + L2.Remarks
				 from FinalFGReceivedDetails_Pams L2 
				 where l2.Date=l3.Date and l2.PartID=l3.PartID and l2.PjcNo=l3.pjcno and l2.PJCYear=l3.PJCYear
					FOR XML PATH(''), TYPE
					).value('.', 'NVARCHAR(MAX)') 
				,1,1,'') Rmrs from #FG l3 
			) t1 inner join #FG on #fg.Date=t1.Date and #FG.PartID=t1.PartID and #FG.pjcno =t1.pjcno and #FG.PJCYear=t1.pjcyear




			select Date,PartID,pjcno ,PJCYear ,QtyOfferedByInspection,FGStores, case when (isnull(QtyOfferedByInspection,0)>isnull(FGStores,0))
			then (isnull(QtyOfferedByInspection,0)-isnull(FGStores,0))  end as InspectionCompletedNotTakenForFG,Remarks
			 from #FG
		end

			if @Param='View2'
			begin
				insert into #view2(PartID,TotalFGStores,LatestUpdatedTS)
				select PartID,SUM(FinalReceivedFGQty) AS TotalFGStores,max(UpdatedTS) LatestUpdatedTS from FinalFGReceivedDetails_Pams f1 
				group by PartID

				UPDATE #view2 SET LatestUpdatedBy=ISNULL(T1.UpdatedBy,'')
				FROM
				(
				select distinct partid,UpdatedBy,ROW_NUMBER() over (partition by partid order by updatedts desc) as RN FROM FinalFGReceivedDetails_Pams
				) T1 INNER JOIN #view2 T2 ON T1.PartID=T2.PartID AND T1.RN='1'

				SELECT * FROM #view2
			end



END
