/****** Object:  Procedure [dbo].[s_GetCockpitProductionData_Cell]    Committed by VersionSQL https://www.versionsql.com ******/

-------------------------------------------
--Procedure to populate the production grid in view data graph - Cell view
--Original author - satyen jaiswal
--Date - 09th feb 2005
-------------------------------------------
CREATE  PROCEDURE [dbo].[s_GetCockpitProductionData_Cell]
	@StartTime datetime,
	@EndTime datetime,
	@CellID nvarchar(50)
AS
BEGIN
SELECT
	IDENTITY(int, 1, 1) AS SerialNo,
	componentinformation.componentid AS ComponentID,
	componentoperationpricing.operationno AS OperationNo,
	employeeinformation.Employeeid AS OperatorID,
	employeeinformation.Name AS OperatorName,
	autodata.sttime AS stTime,
	autodata.ndtime AS EndTime,
	autodata.loadunload as LoadUnload,
	DATEDIFF(second, autodata.msttime, autodata.ndtime) AS [Act TAKT Time],
	autodata.Remarks,
	autodata.id
INTO    #TempCockpitProductionData_Cell
FROM  autodata INNER JOIN
machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN
CellHistory ON machineinformation.machineid = CellHistory.MachineId INNER JOIN
componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID AND
componentoperationpricing.componentid = componentinformation.componentid INNER JOIN
CellFinishOperation ON componentoperationpricing.componentid = CellFinishOperation.ComponentId AND
componentoperationpricing.operationno = CellFinishOperation.OperationNo AND
		      CellFinishOperation.CellId = CellHistory.CellId INNER JOIN
employeeinformation ON autodata.opr = employeeinformation.interfaceid
WHERE
(autodata.sttime >= @StartTime )
AND
(autodata.sttime < @EndTime )
AND
(CellHistory.CellID = @CellID)
AND
(autodata.datatype = 1)
ORDER BY autodata.sttime
Select * from #TempCockpitProductionData_Cell order by SerialNo
END
