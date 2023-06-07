/****** Object:  Procedure [dbo].[s_GetExportDataToExcel]    Committed by VersionSQL https://www.versionsql.com ******/

--NRO115-Vasavi-08/Jun/2015::To get Export Proddata,DownData,ProdAndDown to Excel for multple machines.
--dbo.[s_GetExportDataToExcel] '2015-01-01 06:00:00.000','2015-02-03 06:00:00.000','ACE-01,ace-02','ProdAndDown'
CREATE PROCEDURE [dbo].[s_GetExportDataToExcel]
@StartDate datetime,
@EndDate Datetime,
@machineid nvarchar(50)='',
@param nvarchar(50)=''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

create table #machines
( Machine nvarchar(50)
)


if isnull(@machineid,'') <> ''
begin
		--SELECT @strmachine = ' and ( machineinformation.MachineID = N''' + @MachineID + ''')'
		insert into #machines(machine)
		exec dbo.Split @machineid, ','
end

if @param='DownData'
Begin
SELECT   autodata.mc AS [Machine ID],T1.machineid as [Machine Name],autodata.comp AS [Component ID],t1.componentid as [Component Name],
autodata.opr AS [Operator ID],employeeinformation.employeeid as [Operator Name],
autodata.dcode AS [Down Code],downcodeinformation.downid as [Down Reason],
autodata.sttime AS [Start Time],
autodata.ndtime AS EndTime,autodata.datatype AS [Prod/Down Code],
autodata.cycletime AS [ActualCycle Time],autodata.loadunload As [ActualLoadUnload Time]
,autodata.Remarks,autodata.WorkOrderNumber 
From (Select mc,comp,opn,opr,stdate,ndtime,sttime,nddate,dcode,datatype,loadunload,remarks,cycletime,WorkOrderNumber from autodata
inner join machineinformation on machineinformation.interfaceid=autodata.mc
where autodata.sttime >= convert(nvarchar(25),@StartDate,120) and autodata.sttime<=  convert(nvarchar(25),@EndDate,120) and
(datatype=2) and machineinformation.MachineiD in (select machine from #machines))autodata
left outer JOIN  ( Select	machineinformation.interfaceID as MC,machineinformation.machineid,componentinformation.Interfaceid as cmpinterfaceID,
componentinformation.componentid,componentoperationpricing.InterfaceID,
componentoperationpricing.machiningtime,componentoperationpricing.cycletime
,componentoperationpricing.operationno
From componentinformation 
inner join componentoperationpricing on componentinformation.componentiD=componentoperationpricing.componentiD
inner join machineinformation on machineinformation.machineid=componentoperationpricing.machineid
Where machineinformation.machineID in (select machine from #machines)
)T1 on  autodata.comp=T1.cmpinterfaceID and autodata.opn=T1.interfaceid and T1.mc=autodata.mc
left outer join downcodeinformation on autodata.dcode=downcodeinformation.InterfaceID
left outer join employeeinformation on autodata.opr= employeeinformation.InterfaceID 
ORDER BY autodata.mc,autodata.sttime
End


if @param='Proddata'
Begin
SELECT  autodata.mc AS [Machine ID],T1.machineid as [Machine Name],	autodata.comp AS [Component ID],t1.componentid as [Component Name],
autodata.opr AS [Operator ID],employeeinformation.employeeid as [Operator Name],
autodata.sttime AS [Start Time],autodata.ndtime AS EndTime,autodata.cycletime AS [ActualCycle Time],autodata.loadunload As [ActualLoadUnload Time],
autodata.Remarks ,round((t1.machiningtime*autodata.Partscount),2) as [IdealMachiningTime] ,round(t1.cycletime,2) as [IdealCycleTime],
(t1.cycletime - t1.machiningtime) as [Idealloadunload],round(autodata.Partscount,2) as [Partscount],autodata.WorkOrderNumber AS WorkOrderNumber 
From (Select mc,comp,opn,opr,stdate,ndtime,sttime,nddate,dcode,datatype,loadunload,remarks,cycletime,Partscount,WorkOrderNumber from autodata
inner join machineinformation on interfaceID=autodata.mc where autodata.sttime >= convert(nvarchar(25),@StartDate,120) and 
autodata.sttime<=  convert(nvarchar(25),@EndDate,120)  and machineinformation.machineID in (select machine from #machines)	and	datatype=1) autodata inner JOIN machineinformation ON autodata.mc = machineinformation.InterfaceID 
left outer join ( Select	machineinformation.interfaceID as MC,machineinformation.machineid,componentinformation.Interfaceid as cmpinterfaceID,
componentinformation.componentid,componentoperationpricing.InterfaceID,
componentoperationpricing.machiningtime,componentoperationpricing.cycletime	,componentoperationpricing.operationno
From componentinformation inner join 
componentoperationpricing on componentinformation.componentiD=componentoperationpricing.componentiD inner join machineinformation
on machineinformation.machineid=componentoperationpricing.machineid	
Where machineinformation.machineID in (select machine from #machines))T1 on  autodata.comp=T1.cmpinterfaceID 
and autodata.opn=T1.interfaceid and T1.mc=autodata.mc left outer join 
employeeinformation on autodata.opr= employeeinformation.InterfaceID 	ORDER BY autodata.mc,autodata.sttime
End


if @param='ProdAndDown'
Begin
SELECT   autodata.mc AS [Machine ID],t1.machineid as [Machine Name],
autodata.comp AS [Component ID],T1.componentid as [Component Name],
autodata.opr AS [Operator ID],employeeinformation.employeeid as [Operator Name]
,autodata.dcode AS [Down Code],downcodeinformation.downid as [Down Reason],
autodata.sttime AS [Start Time],
autodata.ndtime AS EndTime,autodata.datatype AS [Prod/Down Code],autodata.cycletime AS [ActualCycleTime],
autodata.loadunload As [LoadUnloadTime],
autodata.Remarks,Round((t1.machiningtime*autodata.Partscount),2) as [IdealMachiningTime] ,  
Round((t1.cycletime*autodata.Partscount),2) as [IdealCycleTime], 
(t1.cycletime - t1.machiningtime) as [Idealloadunload],
Round(autodata.Partscount,2) as [Partscount] , 
autodata.WorkOrderNumber as WorkOrderNumber 
From (Select mc,comp,opn,opr,stdate,ndtime,sttime,nddate,dcode,datatype,loadunload,remarks,cycletime,Partscount,WorkOrderNumber from autodata 
inner join machineinformation on machineinformation.interfaceid=autodata.mc
where autodata.sttime >= convert(nvarchar(25),@StartDate,120) and 
autodata.sttime<=  convert(nvarchar(25),@EndDate,120) and
(datatype=1 or datatype=2) and machineinformation.MachineiD in (select machine from #machines))autodata
left outer JOIN  ( Select	machineinformation.interfaceID as MC,machineinformation.machineid,componentinformation.Interfaceid as cmpinterfaceID,
componentinformation.componentid,componentoperationpricing.InterfaceID,
componentoperationpricing.machiningtime,componentoperationpricing.cycletime
,componentoperationpricing.operationno
From componentinformation 
inner join componentoperationpricing on componentinformation.componentiD=componentoperationpricing.componentiD
inner join machineinformation on machineinformation.machineid=componentoperationpricing.machineid
Where machineinformation.machineID in (select machine from #machines)
)T1 on  autodata.comp=T1.cmpinterfaceID and autodata.opn=T1.interfaceid and T1.mc=autodata.mc
left outer join downcodeinformation on autodata.dcode=downcodeinformation.InterfaceID
left outer join employeeinformation on autodata.opr= employeeinformation.InterfaceID 
ORDER BY autodata.mc,autodata.sttime

End

END
