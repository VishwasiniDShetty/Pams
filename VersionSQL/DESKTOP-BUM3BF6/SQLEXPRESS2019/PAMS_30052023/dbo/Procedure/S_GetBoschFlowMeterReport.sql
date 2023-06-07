/****** Object:  Procedure [dbo].[S_GetBoschFlowMeterReport]    Committed by VersionSQL https://www.versionsql.com ******/

/****************************************************************************************************************
-- Author:		Anjana C V
-- Create date: 10 Oct 2019
-- Modified date: 10 Oct 2019
-- Description: Get flow meter report data for Bosch
-- [dbo].[S_GetBoschFlowMeterReport] '2019-10-01 00:00:00.000','2019-10-11 00:00:00.000'
*****************************************************************************************************************/
CREATE procedure [dbo].[S_GetBoschFlowMeterReport]
	@StartDate datetime,
	@EndDate datetime,
	@PlantId  nvarchar(50) ='',
	@Mc nvarchar(50) =''
AS 
BEGIN
	SELECT DISTINCT F.StartTime,F.Endtime,P.PlantID,M.machineid,C.componentid,COP.operationno,F.Flowvalue1,F.Flowvalue2 from Bosch_FlowMeter F
	INNER JOIN machineinformation M  On M.InterfaceID = F.mc
	INNER JOIN PlantMachine P ON M.machineid = P.MachineID
	INNER JOIN componentinformation C ON C.InterfaceID = F.Comp
	INNER JOIN componentoperationpricing COP ON COP.InterfaceID = F.Opn AND  COP.machineid = M.machineid AND COP.componentid = C.componentid 
	Where F.Starttime >= @StartDate and F.EndTime <= @EndDate
	AND (ISNULL(@Mc,'') = '' OR M.machineid  = @Mc)
	AND (ISNULL(@PlantId,'') = '' OR P.PlantID  = @PlantId)
	ORDER BY P.PlantID,M.machineid,C.componentid,F.Starttime
END
