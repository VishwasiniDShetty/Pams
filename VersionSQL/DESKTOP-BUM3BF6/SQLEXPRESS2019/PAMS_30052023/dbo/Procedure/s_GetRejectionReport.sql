/****** Object:  Procedure [dbo].[s_GetRejectionReport]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[s_GetRejectionReport]
	@StartTime DateTime,
	@EndTime DateTime, 
	@MachineID  nvarchar(50) = '',	
	@OperatorID  nvarchar(50) = '',
	@ComponentID  nvarchar(50) = '',
	@WorkOrderNo nvarchar(50) = '',
	@RejectionID nvarchar(50) = ''
AS
BEGIN
SELECT     
	workorderheader.componentid AS ComponentID, 
	componentinformation.description AS ComponentDescription, 
	workorderrejectiondetail.rejectionid AS RejectionID, 
	rejectioncodeinformation.rejectiondescription AS RejectionDescription, 
	workorderrejectiondetail.quantity AS Quantity, 
	workorderheader.operationno AS OperationNo,
	workorderrejectiondetail.employeeid AS OperatorID, 
        employeeinformation.Name AS EmployeeName, 
	componentoperationpricing.price AS Price, 
	workorderrejectiondetail.quantity * componentoperationpricing.price AS Amount,
	@StartTime as StartTime,
	@EndTime as EndTime	
FROM    
	  employeeinformation INNER JOIN
                      rejectioncodeinformation INNER JOIN
                      workorderrejectiondetail ON rejectioncodeinformation.rejectionid = workorderrejectiondetail.rejectionid ON 
                      employeeinformation.Employeeid = workorderrejectiondetail.employeeid CROSS JOIN
                      componentinformation INNER JOIN
                      workorderheader ON componentinformation.componentid = workorderheader.componentid INNER JOIN
                      componentoperationpricing ON workorderheader.componentid = componentoperationpricing.componentid AND 
                      workorderheader.operationno = componentoperationpricing.operationno
WHERE     
	(workorderheader.componentid LIKE '%'+@ComponentID+'%') 
	AND 
	(workorderrejectiondetail.rejectionid LIKE '%'+@RejectionID+'%') 
	AND 
	(workorderheader.machineid LIKE '%'+@MachineID+'%') 
	AND 
	(workorderheader.workorderno LIKE '%'+@WorkOrderNo+'%') 
	AND 
	(workorderrejectiondetail.employeeid LIKE '%'+@OperatorID+'%')
	AND 
	(workorderrejectiondetail.rejectiondate >= @StartTime)
	AND
	(workorderrejectiondetail.rejectiondate <= @EndTime)
END
