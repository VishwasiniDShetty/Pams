/****** Object:  Procedure [dbo].[SP_COScheduleDetails_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

/*
SP_COScheduleDetails_Pams @MachineID=N'M2'
*/
CREATE procedure [dbo].[SP_COScheduleDetails_Pams]
@MachineID NVARCHAR(50)=''
AS
BEGIN
declare @NoOfPallets nvarchar(50)
select @NoOfPallets=(select distinct top(1) NoOfPallets from machineinformation where machineid=@MachineID)


if @NoOfPallets=1
begin
	print @NoOfPallets 
	SELECT r1.MachineID,r1.MachineInterface,r1.ComponentID,r1.CompInterface,r1.OperationNo,r1.OpnInterface,r1.EmployeeID,r1.OprInterfaceID,r1.PJCNo,r1.PJCYear,
	r1.UpdatedBy,c1.machiningtime,c1.loadunload,c1.cycletime,r1.UpdatedTS,r1.PalletNo,r1.SyncedStatus,p1.IssuedQty as PJCQty,r1.PalletPartsCount FROM RunningMachineDetails_PAMS r1
	inner join componentoperationpricing c1  on c1.machineid=r1.MachineID and c1.componentid=r1.ComponentID and c1.operationno=r1.OperationNo
	inner join ProcessJobCardHeaderCreation_PAMS p1 on r1.ComponentID=p1.PartID and r1.PJCNo=p1.PJCNo and r1.PJCYear=p1.PJCYear
	WHERE r1.MachineID=@MachineID and syncedstatus=2

	SELECT P1.Year,P1.MonthValue,P1.WeekNumber,P1.Date,P1.MachineID,M1.InterfaceID AS MCInterfaceID,P1.PartID,C1.InterfaceID AS CompInterfaceID,P1.Operationno,C2.InterfaceID AS OpnInterfaceid,P1.PlanQty,
	c2.machiningtime,c2.loadunload,c2.cycletime,c2.description as OpnDescription FROM MachineWisePlnQtyDetails_PAMS P1
	INNER JOIN machineinformation M1 ON M1.machineid=P1.MachineID
	INNER JOIN componentinformation C1 ON C1.componentid=P1.PartID
	INNER JOIN componentoperationpricing C2 ON P1.MachineID=C2.machineid AND P1.PartID=C2.componentid AND P1.Operationno=C2.operationno
	WHERE P1.MachineID=@MachineID AND CONVERT(NVARCHAR(10),DATE,126)=CONVERT(NVARCHAR(10),GETDATE(),126) 
	and not exists(select * from RunningMachineDetails_PAMS t1 where t1.machineid=p1.MachineID and  t1.componentid=p1.PartID and t1.OperationNo=p1.Operationno and t1.SyncedStatus =2)
end
else
begin
	print @NoOfPallets 
	SELECT r1.MachineID,r1.MachineInterface,r1.ComponentID,r1.CompInterface,r1.OperationNo,r1.OpnInterface,r1.EmployeeID,r1.OprInterfaceID,r1.PJCNo,r1.PJCYear,
	r1.UpdatedBy,c1.machiningtime,c1.loadunload,c1.cycletime,r1.UpdatedTS,r1.PalletNo,r1.SyncedStatus,p1.IssuedQty as PJCQty,r1.PalletPartsCount FROM RunningMachineDetails_PAMS r1
	inner join componentoperationpricing c1  on c1.machineid=r1.MachineID and c1.componentid=r1.ComponentID and c1.operationno=r1.OperationNo
	inner join ProcessJobCardHeaderCreation_PAMS p1 on r1.ComponentID=p1.PartID and r1.PJCNo=p1.PJCNo and r1.PJCYear=p1.PJCYear
	WHERE r1.MachineID=@MachineID and syncedstatus=2

	SELECT P1.Year,P1.MonthValue,P1.WeekNumber,P1.Date,P1.MachineID,M1.InterfaceID AS MCInterfaceID,P1.PartID,C1.InterfaceID AS CompInterfaceID,P1.Operationno,C2.InterfaceID AS OpnInterfaceid,P1.PlanQty,
	c2.machiningtime,c2.loadunload,c2.cycletime,c2.description as OpnDescription FROM MachineWisePlnQtyDetails_PAMS P1
	INNER JOIN machineinformation M1 ON M1.machineid=P1.MachineID
	INNER JOIN componentinformation C1 ON C1.componentid=P1.PartID
	INNER JOIN componentoperationpricing C2 ON P1.MachineID=C2.machineid AND P1.PartID=C2.componentid AND P1.Operationno=C2.operationno
	WHERE P1.MachineID=@MachineID AND CONVERT(NVARCHAR(10),DATE,126)=CONVERT(NVARCHAR(10),GETDATE(),126) 
end
END
