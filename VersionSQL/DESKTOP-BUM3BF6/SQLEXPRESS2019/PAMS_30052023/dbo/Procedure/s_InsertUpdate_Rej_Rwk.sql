/****** Object:  Procedure [dbo].[s_InsertUpdate_Rej_Rwk]    Committed by VersionSQL https://www.versionsql.com ******/

--select * from Rejection_Rework_Details_Jina
--select * from Production_Summary_Jina
--[s_InsertUpdate_Rej_Rwk] '2015-06-30 00:00:00.000','A','CNC-15','LA25BWD03-LKD','2','108','444','2','Rejection','Operator','6','Vasavi','Save'
CREATE PROCEDURE [dbo].[s_InsertUpdate_Rej_Rwk]

@date datetime='',
@Shift nvarchar(50)='',
@machine nvarchar(50)='',
@Component nvarchar(50)='',
@operation nvarchar(50)='',
@operator nvarchar(100)='',
@WorkOrderNum nvarchar(50)='',
@code nvarchar(50)='',
@Rejection_Rework_flag nvarchar(50)='',--Rejection,ReworkPerformed,MarkedForRework
@Person_Flag nvarchar(50)='',  --Operator,Supervisor,QualityInspector
@rejection_Rework_Qty int='',
@updatedBy nvarchar(50)='',
@param nvarchar(50)=''

AS
BEGIN
	
	SET NOCOUNT ON;

if @param='Save'
if not exists(select * from Rejection_Rework_Details_Jina where [date]=@date and [Shift]=@shift and Machine=@Machine and WorkOrderNumber=@WorkOrderNum and Component=@component and Operation=@operation and Operator=@operator and  Rejection_Rework_flag=@Rejection_Rework_flag and Person_flag=@Person_Flag and Code=@code )
		Begin
			insert into Rejection_Rework_Details_Jina([Date],[Shift],Machine,WorkOrderNumber,Component,Operation,Operator,Rejection_Rework_flag,Person_flag,Code,Rejection_Rework_Qty,CreatedDate,ModifiedDate,UpdatedBy)
			values(@date,@Shift,@Machine,@WorkOrderNum,@Component,@operation,@operator,@Rejection_Rework_flag,@Person_Flag,@code,@rejection_Rework_Qty,getdate(),getdate(),@updatedBy)
		End  
 else
		Begin
			update Rejection_Rework_Details_Jina set Rejection_Rework_Qty=@rejection_Rework_Qty,ModifiedDate=getdate(),UpdatedBy=@updatedBy
			where Rejection_Rework_flag=@Rejection_Rework_flag and Person_flag=@Person_Flag and Code=@code and [date]=@date and [Shift]=@shift and Machine=@Machine and WorkOrderNumber=@WorkOrderNum and Component=@component and Operation=@operation and Operator=@operator
		End

if @param='delete'
Begin
delete  from Rejection_Rework_Details_Jina 
where Rejection_Rework_flag=@Rejection_Rework_flag and Person_flag=@Person_Flag and Code=@code and [date]=@date and [Shift]=@shift and Machine=@Machine and WorkOrderNumber=@WorkOrderNum and Component=@component and Operation=@operation and Operator=@operator
End

END
