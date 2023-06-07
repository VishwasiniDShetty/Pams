/****** Object:  Procedure [dbo].[s_InsertUpdate_JobCard]    Committed by VersionSQL https://www.versionsql.com ******/

--select * from Production_Summary_Jina
--delete from Production_Summary_Jina
--[dbo].[s_InsertUpdate_JobCard]'1156','2015-07-07 00:00:00.000','A','CNC-16','LA38BWD27A','2','109','1111','600','XYZ','save'
CREATE PROCEDURE [dbo].[s_InsertUpdate_JobCard]
@id nvarchar(50)='',
@date datetime='',
@Shift nvarchar(50)='',
@machine nvarchar(50)='',
@Component nvarchar(50)='',
@operation nvarchar(50)='',
@operator nvarchar(100)='',
@WorkOrderNum nvarchar(50)='',
@qty nvarchar(50)='',
@UpdatedBy nvarchar(50)='',
@param nvarchar(50)=''

AS
BEGIN

	SET NOCOUNT ON;


if @param='Save'

begin
if @id=''
Begin
if not exists(select * from Production_Summary_Jina a where a.[Date]=@date and a.[Shift]=@Shift and a.Machine=@machine and a.[WorkOrderNumber]=@WorkOrderNum and a.[Component]=@Component and a.Operation=@operation and a.[Operator]=@operator)
		Begin
		
			insert into Production_Summary_Jina([Date],[Shift],[Machine],[WorkOrderNumber],[Component],[Operation],[Operator],[Qty],CreatedDate,ModifiedDate,UpdatedBy)
			values(@date,@Shift,@machine,@WorkOrderNum,@Component,@operation,@operator,@qty,getdate(),getdate(),@UpdatedBy)
		End
else	
		Begin
			
			RAISERROR('Data Already Exists',11,1,'')    
			return -1;  
		End
End
  
if exists(select * from Production_Summary_Jina a where a.[Date]=@date and a.[Shift]=@Shift and a.Machine =@machine and a.id=@id)
Begin
	update Production_Summary_Jina  set Qty=@Qty ,UpdatedBy=@UpdatedBy,ModifiedDate=GETDATE()
	where  [Date]=@date and [Shift]=@Shift and Machine=@machine and [WorkOrderNumber]=@WorkOrderNum  and Operation=@operation and [Operator]=@operator and Component=@Component and ID=@id
	update Production_Summary_Jina set  [WorkOrderNumber]=@WorkOrderNum  , Operation=@operation , [Operator]=@operator , Component=@Component 
	where id=@id
End


End
if @param='delete'
Begin
delete from Production_Summary_Jina where  [Date]=@date and [Shift]=@Shift and Machine=@machine and [WorkOrderNumber]=@WorkOrderNum  and Operation=@operation and [Operator]=@operator and Component=@Component and ID=@id
End




END
