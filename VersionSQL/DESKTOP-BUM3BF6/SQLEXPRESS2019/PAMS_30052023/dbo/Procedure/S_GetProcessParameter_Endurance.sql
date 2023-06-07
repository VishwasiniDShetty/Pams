/****** Object:  Procedure [dbo].[S_GetProcessParameter_Endurance]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE	[dbo].[S_GetProcessParameter_Endurance]	 

AS

BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	SET NOCOUNT ON;

Insert into  Process_Parameter_Main_Endurance(MachineId, DateTime, Cycle, Status, Lo_V, Hi_V, V_rise, Intensify, P_rise, Biscuit_Thick, Cast_Pressure, StatusFlag)      
select MachineId, DateTime, Cycle, Status, Lo_V, Hi_V, V_rise, Intensify, P_rise, Biscuit_Thick, Cast_Pressure,0
FROM Process_Parameter_temp_Endurance 
where datetime>(Select ISNULL(max(datetime),'2019-01-01') from Process_Parameter_Main_Endurance)
Order by Cycle


END
