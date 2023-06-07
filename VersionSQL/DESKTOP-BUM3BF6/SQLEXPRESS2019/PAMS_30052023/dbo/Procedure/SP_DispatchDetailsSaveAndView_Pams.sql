/****** Object:  Procedure [dbo].[SP_DispatchDetailsSaveAndView_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

/*
SP_DispatchDetailsSaveAndView_Pams @FromDate=N'2023-02-01 00:00:00.000',@ToDate=N'2023-02-28 00:00:00.000',@Param=N'View'
*/
CREATE procedure [dbo].[SP_DispatchDetailsSaveAndView_Pams]
@FromDate datetime='',
@ToDate datetime='',
@PartID NVARCHAR(50)='',
@PJCNo nvarchar(50)='',
@PJCYear NVARCHAR(50)='',
@DispatchQty FLOAT=0,
@Date DATETIME='',
@UpdatedBy NVARCHAR(50)='',
@UpdatedTS DATETIME='',
@InvoiceNo NVARCHAR(50)='',
@Param nvarchar(50)='',
@BatchBit int=0,
@Remarks nvarchar(50)='',
@CustomerID NVARCHAR(50)=''
as
begin

create table #Dispatch
(
PartID nvarchar(50),
pjcno nvarchar(50),
PJCYear nvarchar(50),
FinalInspectedQty float,
IssuedQty float,
DispatchQty FLOAT,
PendingQtyForDispatch float,
CustomerID NVARCHAR(50)
)

	if @Param='Save'
	begin
		if not exists(select * from DispatchDetails_Pams where PartID=@PartID AND pjcno=@PJCNo AND PJCYear=@PJCYear AND BatchBit=@BatchBit and CustomerID=@CustomerID)
		begin
			insert into DispatchDetails_Pams(PartID,pjcno,PJCYear,DispatchQty,InvoiceNo,Date,UpdatedBy,UpdatedTS,BatchBit,Remarks,CustomerID)
			VALUES(@PartID,@PJCNo,@PJCYear,@DispatchQty,@InvoiceNo,@Date,@UpdatedBy,@UpdatedTS,@BatchBit,@Remarks,@CustomerID)
		END
		ELSE
		BEGIN
			UPDATE DispatchDetails_Pams SET DispatchQty=@DispatchQty,InvoiceNo=@InvoiceNo,Date=@Date,UpdatedBy=@UpdatedBy,UpdatedTS=@UpdatedTS,Remarks=@Remarks
			WHERE PartID=@PartID AND pjcno=@PJCNo AND PJCYear=@PJCYear AND BatchBit=@BatchBit and CustomerID=@CustomerID
		END
	END

	IF @Param='View'
	begin
		insert into #Dispatch(PartID,pjcno,PJCYear,FinalInspectedQty)
		select f1.PartID,f1.PJCNo,f1.PJCYear,sum(f1.FinalReceivedFGQty) from FinalFGReceivedDetails_Pams f1 
		group by f1.PartID,f1.PJCNo,f1.PJCYear


		update #Dispatch set DispatchQty=isnull(t1.DispatchQty,0)
		from
		(
			select distinct partid,PJCNo,pjcyear,sum(dispatchqty) as DispatchQty from  DispatchDetails_Pams
			group by partid,PJCNo,pjcyear
		)t1 inner join #Dispatch t2 on t1.partid=t2.partid and t1.PJCNo=t2.PJCNo and t1.pjcyear=t2.pjcyear

		update #Dispatch set IssuedQty=isnull(t1.IssuedQty,0)
		from
		(
			select distinct partid,PJCNo,IssuedQty from ProcessJobCardHeaderCreation_PAMS
		) t1 inner join #Dispatch t2 on t1.partid=t2.PartID and t1.PJCNo=t2.pjcno 

		select PartID,pjcno ,PJCYear ,FinalInspectedQty,DispatchQty, case when (isnull(FinalInspectedQty,0)>isnull(DispatchQty,0)) then (isnull(FinalInspectedQty,0)-isnull(DispatchQty,0))  end as PendingQtyForDispatch,issuedqty
		 from #Dispatch
	end


	if @Param='DispatchHistory'
	begin
		select * from DispatchDetails_Pams where (CONVERT(NVARCHAR(10),date,126)>=CONVERT(NVARCHAR(10),@FromDate,126) AND CONVERT(NVARCHAR(10),date,126)<=CONVERT(NVARCHAR(10),@ToDate,126))
	end


END
