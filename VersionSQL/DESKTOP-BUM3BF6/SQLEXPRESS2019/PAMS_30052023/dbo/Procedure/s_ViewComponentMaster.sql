/****** Object:  Procedure [dbo].[s_ViewComponentMaster]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[s_ViewComponentMaster] '','','ViewCompOpnInfo'
--[dbo].[s_ViewComponentMaster] '','E'
CREATE  PROCEDURE [dbo].[s_ViewComponentMaster]
@Componentid nvarchar(max)='',
@interfaceid nvarchar(50)='',
@Param nvarchar(50)='' 
AS
BEGIN


Create table #Component
(
	Slno int identity(1,1) NOT NULL,
	Componentid nvarchar(50)
	
)

Declare @TimeFormat as nvarchar(20)
Select @TimeFormat = ISNULL(valueintext,'ss')  from shopdefaults where parameter='TimeInFormat'

If @Param = 'ViewComponentInfo'
Begin

	If @Componentid <> ''
	BEGIN
	SELECT  CI.componentid, CI.description, CI.customerid, CI.basicvalue, CI.InterfaceID, CI.InputWeight, CI.ForegingWeight
	FROM Componentinformation CI where CI.Componentid like  @Componentid + '%'
	Order by CI.componentid
	END


	If @Componentid = ''
	BEGIN
	SELECT  CI.componentid, CI.description, CI.customerid, CI.basicvalue, CI.InterfaceID, CI.InputWeight, CI.ForegingWeight
	FROM Componentinformation CI
	Order by CI.componentid
	END
ENd


if @param='ViewComponentInfoBasedOnInterfaceid'
BEGIN
if @interfaceid<> ''
	BEGIN
		SELECT  CI.componentid, CI.description, CI.customerid, CI.basicvalue, CI.InterfaceID, CI.InputWeight, CI.ForegingWeight
		FROM Componentinformation CI where CI.Interfaceid like  @interfaceid + '%'
		Order by CI.InterfaceID
	END
	else
	BEGIN
		SELECT  CI.componentid, CI.description, CI.customerid, CI.basicvalue, CI.InterfaceID, CI.InputWeight, CI.ForegingWeight
		FROM Componentinformation CI 
		Order by CI.InterfaceID
	END
END

If @Param = 'ViewCompOpnInfo'
Begin

	If @TimeFormat = 'ss'
	BEGIN
		If @Componentid <> ''
		BEGIN
		SELECT COP.componentid,COP.operationno, COP.description, COP.machineid, COP.price, COP.cycletime, COP.drawingno, COP.InterfaceID, COP.slno, (COP.cycletime-COP. machiningtime) as loadunload,COP.loadunload as LoadUnloadThreshold,
		COP. machiningtime, COP.SubOperations, COP.StdSetupTime, COP.MachiningTimeThreshold, COP.TargetPercent, COP.UpdatedBy, COP.UpdatedTS, 
		COP.LowerEnergyThreshold, COP.UpperEnergyThreshold, COP.SCIThreshold,COP.DCLThreshold,COP.McTimeMonitorLThreshold,COP.McTimeMonitorUThreshold, 
		COP.StdDieCloseTime, COP.StdPouringTime, COP.StdSolidificationTime, COP.StdDieOpenTime,COP.FinishedOperation,COP.MinLoadUnloadThreshold,cop.Process
		FROM Componentoperationpricing COP where COP.componentid like  @Componentid + '%'
		Order by COP.componentid
		END


		If @Componentid = ''
		BEGIN
		SELECT COP.componentid,COP.operationno, COP.description, COP.machineid, COP.price, COP.cycletime, COP.drawingno, COP.InterfaceID, COP.slno, (COP.cycletime-COP. machiningtime) as loadunload,COP.loadunload as LoadUnloadThreshold,
		COP. machiningtime, COP.SubOperations, COP.StdSetupTime, COP.MachiningTimeThreshold, COP.TargetPercent, COP.UpdatedBy, COP.UpdatedTS, 
		COP.LowerEnergyThreshold, COP.UpperEnergyThreshold, COP.SCIThreshold,COP.DCLThreshold,COP.McTimeMonitorLThreshold,COP.McTimeMonitorUThreshold, 
		COP.StdDieCloseTime, COP.StdPouringTime, COP.StdSolidificationTime, COP.StdDieOpenTime,COP.FinishedOperation,COP.MinLoadUnloadThreshold,cop.Process
		FROM Componentoperationpricing COP Order by COP.componentid
		END
	END
	ELSE
	Begin
		If @Componentid <> ''
		BEGIN
		SELECT COP.componentid,COP.operationno, COP.description, COP.machineid, COP.price, (COP.cycletime/60) as cycletime, COP.drawingno, COP.InterfaceID, COP.slno, (COP.cycletime-COP. machiningtime)/60 as loadunload,COP.loadunload/60 as LoadUnloadThreshold,
		(COP. machiningtime/60) as machiningtime, COP.SubOperations, (COP.StdSetupTime/60) as StdSetupTime, COP.MachiningTimeThreshold, COP.TargetPercent, COP.UpdatedBy, COP.UpdatedTS, 
		COP.LowerEnergyThreshold, COP.UpperEnergyThreshold, COP.SCIThreshold,COP.DCLThreshold,COP.McTimeMonitorLThreshold,COP.McTimeMonitorUThreshold, 
		COP.StdDieCloseTime, COP.StdPouringTime, COP.StdSolidificationTime, COP.StdDieOpenTime,COP.FinishedOperation,COP.MinLoadUnloadThreshold,cop.Process
		FROM Componentoperationpricing COP where COP.componentid like  @Componentid + '%'
		Order by COP.componentid
		END


		If @Componentid = ''
		BEGIN
		SELECT COP.componentid,COP.operationno, COP.description, COP.machineid, COP.price, (COP.cycletime/60) as cycletime, COP.drawingno, COP.InterfaceID, COP.slno, (COP.cycletime-COP. machiningtime)/60 as loadunload,COP.loadunload/60 as LoadUnloadThreshold,
		(COP. machiningtime/60) as machiningtime, COP.SubOperations, (COP.StdSetupTime/60) as StdSetupTime, COP.MachiningTimeThreshold, COP.TargetPercent, COP.UpdatedBy, COP.UpdatedTS, 
		COP.LowerEnergyThreshold, COP.UpperEnergyThreshold, COP.SCIThreshold,COP.DCLThreshold,COP.McTimeMonitorLThreshold,COP.McTimeMonitorUThreshold, 
		COP.StdDieCloseTime, COP.StdPouringTime, COP.StdSolidificationTime, COP.StdDieOpenTime,COP.FinishedOperation,COP.MinLoadUnloadThreshold,cop.Process
		FROM Componentoperationpricing COP Order by COP.componentid
		END
	END

ENd



if @param = 'EXPORT'
BEGIN

	Insert into #Component(Componentid)
	Select Item from SplitStrings(@Componentid,',')

	If @TimeFormat = 'ss'
	BEGIN
	select C.ComponentID as ItemNumber,C.InterfaceID as ItemInterfaceId,C.[Description] as ItemDescription,COP.OperationNo,
	COP.[Description] as OperationDescription,COP.MachineID as CNCMachine,COP.InterfaceID as OpnInterfaceId,(COP.CycleTime - COP.MachiningTime) as  LoadingUnloading,COP.CycleTime,COP.Price,
	COP.DrawingNo,COP.SubOperations,COP.StdSetupTime,COP.MachiningTimeThreshold,COP.TargetPercent,COP.LoadUnload as LoadUnloadTimeThreshold,C.CustomerID,COP.SCIThreshold ,COP.DCLThreshold  from 
	ComponentInformation C left  join ComponentOperationPricing COP on C.ComponentID= COP.ComponentID where  Cop.ComponentID in (select componentID from #component)
	END
	ELSE
	BEGIN
	select C.ComponentID as ItemNumber,C.InterfaceID as ItemInterfaceId,C.[Description] as ItemDescription,COP.OperationNo,
	COP.[Description] as OperationDescription,COP.MachineID as CNCMachine,COP.InterfaceID as OpnInterfaceId,(COP.CycleTime - COP.MachiningTime)/60 as  LoadingUnloading,(COP.CycleTime/60) as CycleTime,COP.Price,
	COP.DrawingNo,COP.SubOperations,(COP.StdSetupTime/60) as StdSetupTime,COP.MachiningTimeThreshold,COP.TargetPercent,(COP.LoadUnload/60) as LoadUnloadTimeThreshold,C.CustomerID,COP.SCIThreshold ,COP.DCLThreshold  from 
	ComponentInformation C left  join ComponentOperationPricing COP on C.ComponentID= COP.ComponentID where  Cop.ComponentID in (select componentID from #component)
	END

END
END
