/****** Object:  Procedure [dbo].[s_GetEnery_Datagrid]    Committed by VersionSQL https://www.versionsql.com ******/

/********************************************************************
NR0152:- By Mrudula M. Rao on 16-jan-2009, to get energy level statistics.
**********************************************************************/
CREATE          PROCEDURE [dbo].[s_GetEnery_Datagrid]
	@StartTime datetime,
	@EndTime datetime,
	@MachineID nvarchar(50)
AS
BEGIN
Select identity(int,1,1) as SLNo,ComponentID,OperationNo,Employeeid as Operator,StartTime,EndTime,
Energy,PF
into #EnergyGrid
from CycleEnergyConsumption
WHERE       Starttime >= @StartTime
	AND Endtime<= @EndTime
	AND MachineID = @MachineID order by starttime asc
select * from #EnergyGrid
	
END
