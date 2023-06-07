/****** Object:  Procedure [dbo].[SS_getJobCardDetails]    Committed by VersionSQL https://www.versionsql.com ******/

--select * from shiftdetails

--exec SS_getJobCardDetails @pDate='2017-01-02 15:23:03',@Shift=N'A',@Plantid=N'',@Machineid=N'IG - 1500',@Componentid=N'',@operationNo=N'',@operatorID=N'',@AcceptedParts=0,@RepeatCycles=0,@dummyCycles=0,@ReworkPerformed=0,@markedforrework=0,@rejection=0,@updatedBy=N'',@UpdateTS='2017-06-30 15:28:38.737',@downid=N'',@id=0,@param=N'ViewProductionData'
CREATE PROCEDURE [dbo].[SS_getJobCardDetails]
@pDate  datetime='',
@Shift nvarchar(50)='',
@PlantID nvarchar(50)='',
@Machineid nvarchar(50)='',
@Componentid nvarchar(50)='',
@OperationNo nvarchar(50)='',
@OperatorID nvarchar(50)='',
@AcceptedParts int='',
@RepeatCycles int='',
@dummyCycles int='',
@ReworkPerformed int='',
@MarkedForRework int='',
@rejection int='',
@updatedBy nvarchar(50)='',
@UpdateTS datetime ='',
@downid nvarchar(100)='',
@id int='',
@RejectionRework_Qty int='',
@RejectionRework_Reason nvarchar(50)='',
@RejectionReworkSlno int='',
@param nvarchar(50)=''

AS
BEGIN

	SET NOCOUNT ON;

if(@param='ViewProductionData')
BEGIN
SELECT  distinct   SPD.ID, pDate, PlantID, MachineID, [Shift], ComponentID, OperationNo, OperatorID, ISNULL(AcceptedParts, 0) AS AcceptedParts, ISNULL(Repeat_Cycles, 0) AS Repeat_Cycles, 
ISNULL(Dummy_Cycles, 0) AS Dummy_Cycles, ISNULL(Rework_Performed, 0) AS Rework_Performed,ISNULL(Marked_for_Rework, 0) As Marked_for_Rework, 
isnull(WorkOrderNumber,0) as WorkOrderNumber 
FROM ShiftProductionDetails  SPD  where (PlantID= @PlantID or @plantid='') AND machineid= @Machineid and [shift]=@Shift and Pdate=  convert(nvarchar(10),@pDate,120)  


END

if(@param='ViewDownData')
BEGIN
select * from ShiftDownTimeDetails where  (PlantID= @PlantID or @plantid='') AND machineid= @Machineid  and [shift]=@Shift  and
  ddate=convert(nvarchar(10),@pDate,120)   order by starttime asc 
END

if(@param = 'UpdateProductionData')
BEGIN
declare @AcceptedQty  int;
declare @DBRejQty int;

 set @AcceptedQty = isnull(@RepeatCycles,0) + isnull(@dummyCycles,0) + isnull(@rejection,0) + isnull(@MarkedForRework,0) - isnull(@ReworkPerformed,0)
 set @DBRejQty = isnull(@rejection,0)
UPDATE ShiftProductionDetails SET OperatorID =@OperatorID, Repeat_Cycles = @RepeatCycles, Dummy_Cycles =@dummyCycles, 
Rework_Performed = @ReworkPerformed,Marked_for_Rework = @MarkedForRework ,  AcceptedParts=isnull(AcceptedParts,0)+isnull(Marked_for_Rework,0)+isnull(Repeat_Cycles,0)+isnull(Dummy_Cycles,0)-isnull(Rework_Performed,0)-(@AcceptedQty)+(@DBRejQty),--(" & AcceptedQty & ")+(" & DBRejQty & ")
UpdatedBy= @updatedBy ,UpdatedTS= @UpdateTS
 Where (id = @id)  and (isnull(AcceptedParts,0)+ isnull(Marked_for_Rework,0)+ isnull(Repeat_Cycles,0)+isnull(Dummy_Cycles,0)-isnull(Rework_Performed,0)-(@AcceptedQty)+(@DBRejQty))>=0
END

if(@param = 'UpdateDownData')
BEGIN
UPDATE ShiftDownTimeDetails SET OperatorID = @OperatorID, DownID = @downid,
ML_flag=(select availeffy from downcodeinformation where downid=@downid ),
downcategory=(select catagory from downcodeinformation where downid= @downid),
threshold=(select threshold from downcodeinformation where downid= @downid),
PE_Flag = (Select ProdEffy from downcodeinformation where downid = @downid),
UpdatedBy=@updatedBy,UpdatedTS=@UpdateTS Where (id =@id)
END

if(@param = 'RejectionQty')
BEGIN
SELECT SUM(Rejection_Qty) as result FROM ShiftRejectionDetails GROUP BY ID HAVING (ID = @ID)
END

if(@param = 'Rework_Qty')
BEGIN
select SUM(Rework_Qty) as result  FROM ShiftReworkDetails GROUP BY ID HAVING (ID = @ID)
END


if(@param = 'ShiftRejectionDetails')
BEGIN
Select * from ShiftRejectionDetails where id=@id  order by Rejection_reason
END

if(@param = 'ShiftreworkDetails')
BEGIN
select * from ShiftreworkDetails where id=@id order by Rework_reason
END


if(@param = 'SaveRejections')
BEGIN
if not exists(select * from Shiftrejectiondetails where Slno=@RejectionReworkSlno )
BEGIN
insert into Shiftrejectiondetails(id,Rejection_Qty,Rejection_Reason,UpdatedBy,UpdatedTS)
values (@id,@RejectionRework_Qty,@RejectionRework_Reason,@updatedBy,@UpdateTS)
END
else
BEGIN
update Shiftrejectiondetails set Rejection_Qty=@RejectionRework_Qty ,Rejection_Reason=@RejectionRework_Reason where Slno=@RejectionReworkSlno
END
END


if(@param = 'SaveRework')
BEGIN
if not exists(select * from ShiftReworkDetails where Slno=@RejectionReworkSlno )
BEGIN
insert into ShiftReworkDetails(id,Rework_Qty,Rework_Reason,UpdatedBy,UpdatedTS)
values (@id,@RejectionRework_Qty,@RejectionRework_Reason,@updatedBy,@UpdateTS)
END
else
BEGIN
update ShiftReworkDetails set Rework_Qty=@RejectionRework_Qty ,Rework_Reason=@RejectionRework_Reason where Slno=@RejectionReworkSlno
END
END



if(@param = 'deleteRejection')
BEGIN
delete from ShiftRejectionDetails where  slno=@id
END

if(@param = 'deleteRwk')
BEGIN


delete from shiftreworkdetails where slno=@id
END







END
