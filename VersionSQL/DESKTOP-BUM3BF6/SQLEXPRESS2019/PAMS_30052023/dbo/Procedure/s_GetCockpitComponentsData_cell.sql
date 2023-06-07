/****** Object:  Procedure [dbo].[s_GetCockpitComponentsData_cell]    Committed by VersionSQL https://www.versionsql.com ******/

/**************************************************************************
Procedure to populate Min Takt time, Max Takt Time, Ave Takt Time
Ideal Takt Time and Cell Output
Original Author - MKestur
Date - 09-Feb-2005

Removed unwanted comments by SSK on 10-July-2006
Procedure Altered By SSK on 10-July-2006 :- To consider Suboperations at CO Level .
Changed Min,Max,Avg,Count Calns
***************************************************************************/

CREATE      PROCEDURE [dbo].[s_GetCockpitComponentsData_cell]
	@StartTime datetime,
	@EndTime datetime,
	@CellID nvarchar(50),
	@ComponentID nvarchar(50) = '',
	@OperationNo nvarchar(50) = ''
AS
BEGIN

	select  min(isnull(autodata.cycletime,0) + isnull(autodata.loadunload,0))* ISNULL(componentoperationpricing.SubOperations,1) as TAKT_min,
		max(isnull(autodata.cycletime,0) + isnull(autodata.loadunload,0))* ISNULL(componentoperationpricing.SubOperations,1) as TAKT_max,
		avg(isnull(autodata.cycletime,0) + isnull(autodata.loadunload,0))* ISNULL(componentoperationpricing.SubOperations,1) as TAKT_ave,
		CAST(CEILING(CAST(Count(*) AS Float)/ISNULL(componentoperationpricing.SubOperations,1))AS Integer) as celloutput,
		cellfinishoperation.yield as IdealTaktTime
FROM  autodata 
INNER JOIN Machineinformation ON autodata.mc = machineinformation.InterfaceID
INNER JOIN CellHistory ON machineinformation.machineid = CellHistory.MachineId 
INNER JOIN Componentoperationpricing ON autodata.opn = Componentoperationpricing.InterfaceID 
INNER JOIN Componentinformation ON autodata.comp = Componentinformation.InterfaceID AND
Componentoperationpricing.Componentid = componentinformation.componentid 
INNER JOIN CellFinishOperation ON componentoperationpricing.componentid = CellFinishOperation.ComponentId AND
Componentoperationpricing.operationno = CellFinishOperation.OperationNo AND CellFinishOperation.CellId = CellHistory.CellId

	Where autodata.ndtime > @starttime
	AND   autodata.ndtime <= @endtime
	AND   autodata.datatype = 1
	AND   cellhistory.cellid = @cellid
	AND   componentinformation.componentid = @componentid
	AND   componentoperationpricing.operationno = @OperationNo
	Group By cellfinishoperation.yield,componentoperationpricing.SubOperations
END
