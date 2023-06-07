/****** Object:  Procedure [dbo].[s_GetFocasComponentInformation]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[s_GetFocasComponentInformation]
@ComponentId  nvarchar(100)='',
@ComponentDescription  nvarchar(50)='',
@Operation  int='',
@ProgramNumber  int='',
@CycleTime  float='',
@LoadUnloadTime float='',
@TotalTime float='',
@param nvarchar(50)=''

WITH RECOMPILE
AS
BEGIN

SET NOCOUNT ON;

If @param='Insert'
Begin


	If Not Exists(select * from [FocasComponentInformation] where componentId = @componentId)

		Begin
				INSERT INTO [dbo].[FocasComponentInformation] ([ComponentId],[ComponentDescription],[Operation],[ProgramNumber],[CycleTime],[LoadUnloadTime],[TotalTime])
				VALUES (@ComponentId,@ComponentDescription,@Operation ,@ProgramNumber,@CycleTime,@LoadUnloadTime,@TotalTime )   
		END
	else
		Begin
			Update FocasComponentInformation set ComponentDescription =  @ComponentDescription , Operation = @Operation , ProgramNumber = @ProgramNumber , Cycletime = @Cycletime , LoadUnloadTime = @LoadUnloadTime, TotalTime = @TotalTime 
			where ComponentId = @ComponentId	
		END
	

END

If @param='ViewAll'
Begin
	select * from FocasComponentInformation 
END

If @param='ViewOne'
Begin
	select * from FocasComponentInformation where ComponentId = @ComponentId
END


END
