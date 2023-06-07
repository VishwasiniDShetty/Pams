/****** Object:  Procedure [dbo].[s_CheckProductionData_Jina]    Committed by VersionSQL https://www.versionsql.com ******/

--s_GetProductionData '2015-07-01','A','cnc-15','',''
CREATE PROCEDURE [dbo].[s_CheckProductionData_Jina]
	@Date datetime,
	@Shift nvarchar(50),
	@Machine nvarchar(50),
	@Component nvarchar(50)='',
	@WorkOrderNum nvarchar(50)=''
	
	
AS
BEGIN
	
	SET NOCOUNT ON;

   
  select count(*) AS [count] from Production_Summary_Jina Where [Date]=@Date and [Shift]=@Shift and [Machine]=@Machine and
 (WorkOrderNumber=@WorkOrderNum or @WorkOrderNum='') and (Component=@Component or @Component= '')

END
