/****** Object:  Procedure [dbo].[Focas_PushOperationTempToHistory]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[Focas_PushOperationTempToHistory] 
@machineid nvarchar(50)='ACE-02'
AS
BEGIN

insert into Focas_OperationHistory (OperationType,OperationValue,ODateTime,MachineID) 
select  distinct OperationType,OperationValue,ODateTime,MachineID
 from Focas_OperationHistoryTemp 
 where isdate(OdateTime)=1 and
	   OdateTime > (select isnull(max(ODateTime),'1900-01-01 00:00:00.000') 
							from Focas_OperationHistory
							where MachineID=@machineid
							) 
and OdateTime is not null and MachineID = @machineid order by ODateTime asc

END
