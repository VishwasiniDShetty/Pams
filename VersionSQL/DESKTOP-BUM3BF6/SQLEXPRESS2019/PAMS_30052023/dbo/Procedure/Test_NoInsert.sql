/****** Object:  Procedure [dbo].[Test_NoInsert]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE  PROCEDURE [dbo].[Test_NoInsert]
	@StartTime DateTime,
	@EndTime DateTime,
	@MachineID  nvarchar(50) = '',
	@ComponentID  nvarchar(50) = '',
	@OperatorID  nvarchar(50) = '',
	@MachineIDLabel nvarchar(50) ='ALL',
	@OperatorIDLabel nvarchar(50) = 'ALL',
	@ComponentIDLabel nvarchar(50) = 'ALL'
AS
BEGIN
CREATE TABLE #venkatrao ( pComponentID nvarchar(50),  tTime float)
EXEC s_GetComponentProductionTime  @StartTime, @EndTime, @MachineID, @ComponentID, @OperatorID
--select * from #venkatrao
drop table #venkatrao
END
