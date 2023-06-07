/****** Object:  Procedure [dbo].[s_GetESHOPxDocumentsDetail]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[s_GetESHOPxDocumentsDetail] 'ECONO-3','PP9983','2','33','3','33','aaa','read'


CREATE PROCEDURE [dbo].[s_GetESHOPxDocumentsDetail]
	@machineid nvarchar(50)='',
	@ComponentId nvarchar(50)='',
	@operationNo nvarchar(50)='',
	@DocumentType nvarchar(4000)='',
	@DocumentPath nvarchar(500)='',
	@DocumentName nvarchar(50)='',
	@UpdatedBy nvarchar(50)='',
    @Param nvarchar(50)=''
AS
BEGIN
	
	SET NOCOUNT ON;
	
IF @param='Read'    
Begin  
	select MachineID,ComponentID,OperationNo,DocumentType,DocumentPath,DocumentName,UpdatedBy,updated_TS
	from [dbo].[ESHOPxDocuments]
	where (@machineID is null or machineId=@machineID) and (@ComponentID is null OR ComponentID=@ComponentID) and (@OperationNo is null OR OperationNo=@OperationNo)and (@DocumentType is null OR DocumentType=@DocumentType)
END

if @param ='Save' 
Begin  
IF EXISTS( Select * from ESHOPxDocuments where MachineId = @machineId AND ComponentID = @ComponentID and OperationNo =@OperationNo and DocumentType=@DocumentType)
	BEGIN
	Update ESHOPxDocuments SET DocumentType = @DocumentType, DocumentPath = @DocumentPath,DocumentName=@DocumentName,Updated_TS=getdate()
	where MachineId = @machineId AND ComponentID = @ComponentID and OperationNo =@OperationNo and DocumentType=@DocumentType
	END
ELSE
	BEGIN
	 insert into ESHOPxDocuments(MachineID,ComponentID,OperationNo,DocumentType,DocumentPath,DocumentName,UpdatedBy,Updated_TS)VALUES
	 (@MachineID,@ComponentID,@OperationNo,@DocumentType,@DocumentPath,@DocumentName,@UpdatedBy,getdate())
	END

End



END
