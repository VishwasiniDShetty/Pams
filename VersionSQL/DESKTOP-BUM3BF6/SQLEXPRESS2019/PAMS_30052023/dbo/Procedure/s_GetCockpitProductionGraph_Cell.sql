/****** Object:  Procedure [dbo].[s_GetCockpitProductionGraph_Cell]    Committed by VersionSQL https://www.versionsql.com ******/

--------------------------------------------------
--Procedure to populate the Production Graph in Cell View
--Original Author: Satyen Jaiswal
--Date: 09th feb 2005
--------------------------------------------------
CREATE    PROCEDURE [dbo].[s_GetCockpitProductionGraph_Cell]
	@StartTime datetime,
	@EndTime datetime,
	@CellID nvarchar(50)
AS
BEGIN
SELECT  DATEDIFF(second, autodata.msttime, autodata.ndtime) AS [Act TAKT Time],
	CellFinishOperation.Yield as [Ideal TAKT Time]
FROM    autodata INNER JOIN
machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN
CellHistory ON machineinformation.machineid = CellHistory.MachineId INNER JOIN
componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID AND
componentoperationpricing.componentid = componentinformation.componentid INNER JOIN
CellFinishOperation ON componentoperationpricing.componentid = CellFinishOperation.ComponentId AND
componentoperationpricing.operationno = CellFinishOperation.OperationNo AND CellFinishOperation.CellId = CellHistory.CellId
WHERE
(autodata.sttime >= @StartTime )
AND
(autodata.sttime < @EndTime )
AND
(CellHistory.CellID = @CellID)
AND
(autodata.datatype = 1)
	
ORDER BY autodata.sttime
END
