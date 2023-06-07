/****** Object:  Procedure [dbo].[s_GetMachineCycleTimeMonitor]    Committed by VersionSQL https://www.versionsql.com ******/

--ER0399 - SwathiKS - 26/Dec/2014 :: Created New Procedure To Show Machinewise Component, Operation, StdM/cTime, MinValue,
-- MaxValue, Interlocktime for BoschCycleTimeMonitor.
--[dbo].[s_GetMachineCycleTimeMonitor] 'ECONO-3'
CREATE  PROCEDURE [dbo].[s_GetMachineCycleTimeMonitor]
@Machineid as nvarchar(50) 
AS
BEGIN

create table #CycletimeMonitor
(
	Machineid nvarchar(50),
	Componentid nvarchar(50),
	Operationno nvarchar(50),
	Mc nvarchar(50),
	Comp nvarchar(50),
	Opn nvarchar(50),
	StdMachiningTime float,
	MinValue float,
	MaxValue float,
	InterlockTime int
)

Insert into #CycletimeMonitor(Machineid,Componentid,Operationno,mc,comp,opn)
select top 1 M.Machineid,C.Componentid,O.Operationno,M.interfaceid,C.interfaceid,O.interfaceid from Autodatadetails A
inner join Machineinformation M on A.machine=M.interfaceid
inner join Componentinformation C on A.CompInterfaceID=C.interfaceid
inner join Componentoperationpricing O on A.OpnInterfaceID=O.interfaceid and 
O.Machineid=M.machineid and O.Componentid=C.componentid
where A.RecordType='8' and M.machineid=@Machineid and A.endtime is null
Order by id desc

Update #CycletimeMonitor set InterlockTime = T1.InterlockTime from
(Select top 1 isnull(ValueInint,0) as InterlockTime from Shopdefaults where parameter='MachineInterLockTime')T1

update #CycletimeMonitor set StdMachiningTime=isnull(T1.StdMachiningTime,0),MinValue=isnull(T1.MinValue,0),MaxValue=isnull(T1.MaxValue,0) from
(Select CM.machineid,CM.componentid,CM.operationno,COP.machiningtime as StdMachiningTime,
 (COP.machiningtime*(isnull(COP.McTimeMonitorLThreshold,0)/100)) as MinValue, (COP.machiningtime*(isnull(COP.McTimeMonitorUThreshold,0)/100)) as MaxValue from #CycletimeMonitor CM
inner join Componentoperationpricing COP on COP.Machineid=CM.machineid and COP.Componentid=CM.Componentid and COP.Operationno=CM.Operationno
)T1 inner join #CycletimeMonitor on T1.Machineid=#CycletimeMonitor.machineid and T1.Componentid=#CycletimeMonitor.Componentid and T1.Operationno=#CycletimeMonitor.Operationno

select * from #CycletimeMonitor

END
