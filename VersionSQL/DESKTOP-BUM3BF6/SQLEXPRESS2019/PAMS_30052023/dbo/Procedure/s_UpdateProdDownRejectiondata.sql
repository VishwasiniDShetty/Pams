/****** Object:  Procedure [dbo].[s_UpdateProdDownRejectiondata]    Committed by VersionSQL https://www.versionsql.com ******/

--select * from autodata

--select * from autodatarejections
CREATE PROCEDURE [dbo].[s_UpdateProdDownRejectiondata]
@StartTime datetime = '',
@EndTime datetime ='', 
@machineid nvarchar(50)='',
@FromComponent nvarchar(50)='',
@ToComponent nvarchar(50)='',
@FromOperation nvarchar(50)='',
@ToOperation nvarchar(50)='',
@Fromoperator nvarchar(50)='',
@Tooperator nvarchar(50)='',
@FromWorkOrder nvarchar(50)='',
@ToWorkOrder nvarchar(50)='',
@FromPartsCount decimal(18,3) ='',
@ToPartsCount decimal(18,3) ='',
@downid nvarchar(50)='',
@FromdownCode nvarchar(50)='',
@TodownCode nvarchar(50)='',
@RejectionID nvarchar(50)='',
@FromRejectionCode nvarchar(50)='',
@ToRejectionCode nvarchar(50)='',
@Datatype nvarchar(50)='',
@param nvarchar(50)='',
@id bigint='',
@RejectionQty int=''


AS
BEGIN
	
	SET NOCOUNT ON;

if(@param ='GridProductionData')
BEGIN
Update autodata set opr=@Fromoperator ,comp=@FromComponent, opn=@FromOperation ,WorkorderNumber=@FromWorkOrder ,partsCount=@FromPartsCount  where id=@id
END
if(@param ='GridDownData')
BEGIN
Update autodata set opr=@Fromoperator ,comp=@FromComponent, opn=@FromOperation ,WorkorderNumber=@FromWorkOrder ,dcode=@FromdownCode  where id=@id
END
if(@param ='GridRejectionData')
BEGIN
update autodatarejections set comp=@FromComponent,opn=@FromOperation,opr=@Fromoperator,Rejection_Qty = @RejectionQty where id=@id
END

if (@Datatype='Production Data' and @param = 'Operator')
BEGIN
Update autodata set opr=@Tooperator where opr=@Fromoperator  and mc=@machineid and  datatype=1 and sttime >= @StartTime and ndtime <= @EndTime       
END
else if(@Datatype='Down Data' and @param = 'Operator')
BEGIN
Update autodata set opr=@Tooperator where opr=@Fromoperator   and  mc=@machineid and  datatype=2 and sttime >= @StartTime and ndtime <= @EndTime             
END
else if (@Datatype='Rejection Data' and @param = 'Operator')
BEGIN
Update AutodataRejections set opr=@Tooperator where opr=@Fromoperator   and mc=@machineid and createdts between @StartTime and  @EndTime           
END


if(@Datatype='Production Data' and @param = 'ComponentOperation')
BEGIN
Update autodata set comp = @ToComponent ,opn=@ToOperation where comp = @FromComponent  and opn=@FromOperation and  mc=@machineid and  datatype=1 and sttime >= @StartTime and ndtime <= @EndTime       
END
else if(@Datatype='Down Data' and @param = 'ComponentOperation')
BEGIN
Update autodata set comp = @ToComponent ,opn=@ToOperation where comp = @FromComponent and opn=@FromOperation and mc=@machineid and  datatype=1 and sttime >= @StartTime and ndtime <= @EndTime             
END
else if (@Datatype='Rejection Data' and @param = 'ComponentOperation')
BEGIN
Update AutodataRejections set comp = @ToComponent ,opn=@ToOperation where comp = @FromComponent and opn=@FromOperation and mc=@machineid  and createdts between @StartTime and @EndTime        
END


if(@Datatype='Production Data' and @param = 'PartsCount')
BEGIN
update autodata set partscount =@ToPartsCount  where mc=@machineid and comp = @FromComponent and opn=@FromOperation and  datatype=1  and partscount=@FromPartsCount  and sttime >= @StartTime and ndtime <= @EndTime    
END


if(@Datatype='Rejection Data' and @param = 'RejectionCode')
BEGIN
update AutodataRejections set rejection_code=@ToRejectionCode   where rejection_code=@FromRejectionCode  and mc=@machineid and createdts between @StartTime and  @EndTime 
END

if (@Datatype='Production Data' and @param = 'WorkOrder')
BEGIN
Update autodata set WorkOrderNumber=@ToWorkOrder where WorkOrderNumber=@FromWorkOrder  and mc=@machineid and  datatype=1 and sttime >= @StartTime and ndtime <= @EndTime       
END
else if(@Datatype='Down Data' and @param = 'WorkOrder')
BEGIN
Update autodata set WorkOrderNumber=@ToWorkOrder where WorkOrderNumber=@FromWorkOrder   and  mc=@machineid and  datatype=2 and sttime >= @StartTime and ndtime <= @EndTime             
END


if(@Datatype ='Down Data' and @param ='Downid')
BEGIN
Update autodata set dcode=@TodownCode where dcode=@FromdownCode   and  mc=@machineid and  datatype=2 and sttime >= @StartTime and ndtime <= @EndTime     

END

END
