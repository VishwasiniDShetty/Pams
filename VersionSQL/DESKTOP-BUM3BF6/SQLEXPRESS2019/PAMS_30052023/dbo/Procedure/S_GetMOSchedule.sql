/****** Object:  Procedure [dbo].[S_GetMOSchedule]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[S_GetMOSchedule]   

AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	SET NOCOUNT ON;



    -- Insert statements for procedure here
	-- For MO Insert statements for procedure here  
	select MONumber,Max(MOModifiedDate) as UpdatedTS into #MAXMO from MOscheduleTemp 
	inner join machineinformation M on MOScheduleTemp.MachineID=M.machineid where M.TPMTrakEnabled=1 Group by MONumber 



	SELECT #MAXMO.MONumber,LinkNo,MOscheduleTemp.MachineID,PartID,OperationNo,Quantity,DateOfRequirement,LTRIM(RTRIM([MOStatus]))as MOStatus,[FileName],[FileModifiedDate],MOscheduleTemp.[Status],[DrawingNumber],ProgramNumber,ControlPlanning
	,#MAXMO.UpdatedTS,MOscheduleTemp.ProcessSheet into #MO FROM MOscheduleTemp 
	 inner join machineinformation M on MOScheduleTemp.MachineID=M.machineid  
	 inner join #MAXMO on MOscheduleTemp.MONumber=#MAXMO.MONumber and MOScheduleTemp.MOModifiedDate=#MAXMO.UpdatedTS
	 where M.TPMTrakEnabled=1 and (MOscheduleTemp.MONumber is not null) and (MOscheduleTemp.MachineID is not null) and (PartID is not null) and (OperationNo is not null) and (PartID not like 'MACHINEDOWNTIME%')


	update MOSchedule set MOSchedule.MachineID=T.MachineID,MOSchedule.PartID=T.PartID,MOSchedule.LinkNo=T.LinkNo,MOSchedule.OperationNo=T.OperationNo,MOSchedule.Quantity=T.Quantity,MOSchedule.DateOfRequirement=T.DateOfRequirement,
	MOSchedule.MOStatus=T.MOStatus,MOSchedule.FileName=T.FileName,MOSchedule.[FileModifiedDate]=T.[FileModifiedDate],MOSchedule.[Status]=T.[Status],MOSchedule.[DrawingNumber]=T.[DrawingNumber],MOSchedule.ProgramNumber=T.ProgramNumber,
	MOSchedule.ControlPlanning=T.ControlPlanning,MOSchedule.UpdatedTS=T.UpdatedTS,MOSchedule.ProcessSheet=T.ProcessSheet from MOschedule inner join 
	(select MONumber,LinkNo,MachineID,PartID,OperationNo,Quantity,DateOfRequirement,LTRIM(RTRIM([MOStatus]))as MOStatus,[FileName],[FileModifiedDate],[Status],[DrawingNumber],ProgramNumber,ControlPlanning,UpdatedTS,ProcessSheet
	from #MO)T  on MOSchedule.MONumber=T.MONumber 

	--For inserting into main table.  
	

	Insert into MOschedule(MONumber,LinkNo,MachineID,PartID,OperationNo,Quantity,DateOfRequirement,MOStatus,[FileName],[FileModifiedDate],[Status],[DrawingNumber],ProgramNumber,ControlPlanning,LastModifieddate,UpdatedTS,ProcessSheet)
	Select #MO.MONumber,#MO.LinkNo,#MO.MachineID,#MO.PartID,#MO.OperationNo,#MO.Quantity,#MO.DateOfRequirement,LTRIM(RTRIM(#MO.MOStatus)) as MOStatus,#MO.[FileName],#MO.[FileModifiedDate],#MO.[Status],#MO.[DrawingNumber],#MO.ProgramNumber,#MO.ControlPlanning,getdate(),UpdatedTS,ProcessSheet from #MO  
	where not exists(select * from  MOSchedule MO where MO.MONumber=#MO.MONumber )
	


  

END
