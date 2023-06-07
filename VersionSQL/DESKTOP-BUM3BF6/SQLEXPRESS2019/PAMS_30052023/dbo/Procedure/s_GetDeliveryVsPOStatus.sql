/****** Object:  Procedure [dbo].[s_GetDeliveryVsPOStatus]    Committed by VersionSQL https://www.versionsql.com ******/

/*  ****** History *******
Author - Sangeeta Kallur
Date   - 04/Nov/2006
This is Wrt Delivery against PO status monitor
To see all the parts that have their need by dates within 5 days  
*/



CREATE   PROCEDURE [dbo].[s_GetDeliveryVsPOStatus]
	@StartTime datetime 
	
AS
BEGIN
	Create Table #TmpPO_DelDetails
	(
	 CustomerID NVarChar(50),
	 ItemID     NVarChar(50),
	 PONo 	    NVarChar(50),
	 ReqDate    DateTime,
	 ReqQty     Int,
	 DCNumber   NVarChar(50),
	 DelDate    DateTime,
	 DelQty     Int
	)
	INSERT INTO #TmpPO_DelDetails(CustomerID,ItemID,PONo,ReqDate,ReqQty,DCNumber,DelDate,DelQty)
	SELECT P.CustomerID,P.ComponentID,P.PONumber,ReqDate,ReqQty,
	DCNumber,Delivery_Date,ISNULL(Delivery_Qty,0)
	From
	PurchaseOrder P Left Outer Join DeliveryChallan D ON 
	P.CustomerID=D.CustomerID AND P.ComponentID=D.ComponentID AND P.PONumber=D.PONumber
	Where ReqDate>=DATEADD(DAY,-2,@StartTime) AND ReqDate<=DATEADD(DAY,5,@StartTime)
		
	SELECT * FROM #TmpPO_DelDetails Order By ReqDate
END
