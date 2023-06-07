/****** Object:  Procedure [dbo].[s_ViewMOQuantity]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[s_ViewMoQuantitytest] 'CT-27','340855','496-708-3001-01','1',''
CREATE PROCEDURE [dbo].[s_ViewMOQuantity]
@machineid nvarchar(50),
@MoNumber nvarchar(50),
@ItemNo nvarchar(50),
@operationNo nvarchar(50),
@Param nvarchar(50)=''
WITH RECOMPILE
AS	
BEGIN
	
SET NOCOUNT ON;


Select MS.Machineid,MS.PartID,MS.OperationNo,MS.MONumber,
SUM(Partscount) as Qty from Autodata A
Inner join Machineinformation M on M.interfaceID = A.mc
Inner join componentinformation C on A.Comp=C.interfaceid
Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineID = M.MachineID
inner join MOSchedule MS on O.Machineid=MS.Machineid and O.componentid=MS.PartID and O.interfaceid=MS.OperationNo
and A.WorkOrderNumber=MS.MONumber
where MS.MachineID=@Machineid and MS.PartID=@ItemNo and MS.OperationNo=@operationNo and MS.MONumber=@MoNumber
group by MS.Machineid,MS.PartID,MS.OperationNo,MS.MONumber


END
