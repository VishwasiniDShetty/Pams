/****** Object:  Procedure [dbo].[s_GetVendorWorkOrderDetail]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE      PROCEDURE [dbo].[s_GetVendorWorkOrderDetail]
	@FromDate as datetime,
	@ToDate as datetime,
	@VendorName as nvarchar(50)
AS
BEGIN
	DECLARE @StrSql as NVarChar(4000)
	DECLARE @StrVendorName as NVarChar(50)
	select @FromDate=convert(datetime, cast(DATEPART(yyyy,@FromDate)as nvarchar(4))+'-'+cast(datepart(mm,@FromDate)as nvarchar(2))+'-'+cast(datepart(dd,@FromDate)as nvarchar(2)) +' 00:00:00.000')
	select @ToDate=convert(datetime, cast(DATEPART(yyyy,@ToDate)as nvarchar(4))+'-'+cast(datepart(mm,@ToDate)as nvarchar(2))+'-'+cast(datepart(dd,@ToDate)as nvarchar(2)) +' 00:00:00.000')

/*	Create table #Temp
	(
	 	VendorName  nvarchar(50),
		OrderNumber  nvarchar(50),
		LineItem  nvarchar(50),
	 	DCnumber  nvarchar(50),
		VendorDCnumber  nvarchar(50),
		CompanyDCdate  DateTime,
		VendorDCdate DateTime,
		TotalQuantity nvarchar(50),
		Accepted nvarchar(50),
		Rejected nvarchar(50),
		Rework nvarchar(50),
		Remarks nvarchar(100)
	)
*/
	Select @StrVendorName = ''
	IF IsNull(@VendorName,'')<>'ALL'
	BEGIN
		SELECT @StrVendorName=' and w.Vendorname='''+ @VendorName +''''
	END
	

	select @StrSql = ''
	select @StrSql = '
	Select w.Vendorname,w.OrderNumber,w.LineItem,r.Dcnumber,VendorDcnumber,DCdate As CompanyDCdate,
	VendorDCdate,r.TotalQuantity,AcceptedQuantity,RejectedQuantity,ReworkQuantity,r.Remarks 
	From ItemsReceivedFromVendor r Inner join ItemsSentToVendor s 
	on r.Vendorname = s.Vendorname and r.OrderNumber = s.OrderNumber and
	r.LineItem = s.LineItem and r.DCnumber = s.DCnumber inner join VendorWorkOrder w
	on r.Vendorname = w.Vendorname and r.OrderNumber = w.OrderNumber and r.LineItem = w.LineItem
	where w.OrderDate >= '''+ Convert(Nvarchar(20),@FromDate)+''' and w.OrderDate <= '''+ Convert(Nvarchar(20),@ToDate)+''''+ @StrVendorName +'
	Order By r.Vendorname,r.OrderNumber,r.LineItem,r.Dcnumber,VendorDcnumber,DCdate,VendorDcdate'
--	print @StrSql
	exec (@StrSql)

--select * from #Temp
--s_GetVendorWorkOrderDetail '2008-01-01 12:00:00 AM','2008-01-01 08:00:00 AM','All'
END
