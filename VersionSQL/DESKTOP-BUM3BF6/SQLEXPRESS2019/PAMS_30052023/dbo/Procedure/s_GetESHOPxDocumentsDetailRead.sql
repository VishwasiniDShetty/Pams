/****** Object:  Procedure [dbo].[s_GetESHOPxDocumentsDetailRead]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[s_GetESHOPxDocumentsDetailRead]
	@machineid nvarchar(50)='',
	@ComponentId nvarchar(50)='',
	@operationNo nvarchar(50)=''
AS
BEGIN
	
	SET NOCOUNT ON;

  
select MachineID,ComponentID,OperationNo,DocumentType,DocumentPath,DocumentName,UpdatedBy,updated_TS
 from [dbo].[ESHOPxDocuments]
  where (@machineID is null or machineId=@machineID) and (@ComponentID is null OR ComponentID=@ComponentID) and (@OperationNo is null OR OperationNo=@OperationNo)

END
