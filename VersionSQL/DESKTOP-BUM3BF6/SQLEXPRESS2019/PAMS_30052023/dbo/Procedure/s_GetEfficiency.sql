/****** Object:  Procedure [dbo].[s_GetEfficiency]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[s_GetEfficiency]'2015-03-11','','','OEE','Day','','Console'
CREATE PROCEDURE [dbo].[s_GetEfficiency]
	@StartTime datetime ,
	@MachineID nvarchar(50) = '',
	@PlantID nvarchar(50)='',
	@ComparisonParam as nvarchar(20)='',
	@TimeAxis as nvarchar(20)='', --'Month','Day','Shift','Hour'
	@ShiftName as nvarchar(20)='',
	@Type as NVarchar(20)='Console'
	
AS
BEGIN
	
	SET NOCOUNT ON;


	CREATE TABLE #efficiency (
	[Shift] datetime,
	PDT datetime,
	shftnm nvarchar(50),
	strttm datetime,
	ndtime datetime,
	MachineID nvarchar(50),
	AE float,
	PE float,
	OE float,
	Components float,
	totalcomp float,
	ManagementLoss float,
	DownTime nvarchar(50),--vasavi
	TurnOver Float default 0--vasavi
	
)

exec  [s_GetEfficiencyFromAutodata_Shanthi] @StartTime,@StartTime,@MachineID,@PlantID,@ComparisonParam,'Shift',@ShiftName,@Type
exec  [s_GetEfficiencyFromAutodata_Shanthi] @StartTime,@StartTime,@MachineID,@PlantID,@ComparisonParam,'Day',@ShiftName,@Type
exec  [s_GetEfficiencyFromAutodata_Shanthi] @StartTime,@StartTime,@MachineID,@PlantID,@ComparisonParam,'Month',@ShiftName,@Type
   
    End
