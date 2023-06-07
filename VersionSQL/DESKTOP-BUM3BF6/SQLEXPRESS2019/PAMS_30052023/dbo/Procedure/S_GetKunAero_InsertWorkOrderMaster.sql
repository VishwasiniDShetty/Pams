/****** Object:  Procedure [dbo].[S_GetKunAero_InsertWorkOrderMaster]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[S_GetKunAero_InsertWorkOrderMaster]   
AS

BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	SET NOCOUNT ON;


	SELECT MONumber,PartID,Quantity,DateOfRequirement,FileName,FileModifiedDate into #MO FROM MOscheduleTemp 
	where (MOscheduleTemp.MONumber is not null) and (MOscheduleTemp.PartID is not null)

	update MOSchedule set MOSchedule.Quantity=T.Quantity,MOSchedule.DateOfRequirement=T.DateOfRequirement,FileName=T.FileName,FileModifiedDate=T.FileModifiedDate from MOschedule inner join 
	(select MONumber,PartID,Quantity,DateOfRequirement,FileName,FileModifiedDate from #MO)T on MOSchedule.MONumber=T.MONumber and MOSchedule.PartID=T.PartID

	Insert into MOschedule(MONumber,Machineid,Operationno,PartID,Quantity,DateOfRequirement,FileName,FileModifiedDate)
	Select #MO.MONumber,'All','All',#MO.PartID,#MO.Quantity,#MO.DateOfRequirement,#MO.FileName,#MO.FileModifiedDate from #MO  
	where not exists(select * from  MOSchedule MO where MO.MONumber=#MO.MONumber and MO.PartID=#MO.PartID)
	 

END
