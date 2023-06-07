/****** Object:  Procedure [dbo].[S_GetExportData]    Committed by VersionSQL https://www.versionsql.com ******/

/****** Object:  StoredProcedure [dbo].[S_GetExportData]    Script Date: 07/29/2010 09:51:40 ******/

/*******************************************************
DR0241 Created By Karthick R on 27-jul-2010.To export production data,Down Data and Production and down data.
ER0379 - SwathiKS - 10/Apr/2014 :: To include New column Partcount and Multiplying Partscount with Std.Machiningtime and std.cycletime.
vasavi-14/apr/2015:: To include workOrderNumber 
select * from machineinformation
---S_GetExportdata '2015-01-01','2016-09-02','''ACE-01''','PRD_DownData','BID'
*******************************************************/
CREATE  PROCEDURE [dbo].[S_GetExportData]
    @StartDate datetime,
	@EndDate Datetime,
	@MachineID nvarchar(500),
	@Type  nvarchar(50),
	@Format nvarchar(20)='BID'
AS
BEGIN
Declare @strsql nvarchar(4000)
		

	SET NOCOUNT ON;
	if @Type='ProdData' and @Format='BID'--Production Data with BusinessID
	Begin
		Select @strsql='SELECT  autodata.mc AS [Machine ID],T1.machineid as [Machine Name],
		autodata.comp AS [Component ID],t1.componentid as [Component Name],
		autodata.opn AS [Operation ID],T1.operationno as [Operation No],
		autodata.opr AS [Operator ID],employeeinformation.employeeid as [Operator Name],
		autodata.stdate AS [Start Date],autodata.sttime AS [Start Time],autodata.nddate AS [End Date],
		autodata.ndtime AS EndTime,autodata.cycletime AS [A.Cycle Time],autodata.loadunload As [A.LoadUnload Time],
		autodata.Remarks ,round((t1.machiningtime*autodata.Partscount),2) as [I.MachiningTime] , --ER0379
		round(t1.cycletime,2) as [I.CycleTime], --ER0379
		(t1.cycletime - t1.machiningtime) as [I.loadunload],round(autodata.Partscount,2) as [Partscount], --ER0379
		autodata.WorkOrderNumber AS WorkOrderNumber --Vasavi
		 From (Select mc,comp,opn,opr,stdate,ndtime,sttime,nddate,dcode,datatype,loadunload,remarks,cycletime,Partscount,WorkOrderNumber from autodata --SV --vasavi
				inner join machineinformation on interfaceID=autodata.mc
				where autodata.sttime >= '''+convert(nvarchar(25),@StartDate,120)+''' and autodata.sttime<=  '''+convert(nvarchar(25),@EndDate,120)+'''  and
				machineinformation.machineID in ('+@MachineID+')
				and
				datatype=1) autodata
		inner JOIN machineinformation ON autodata.mc = machineinformation.InterfaceID 
		left outer join ( Select	machineinformation.interfaceID as MC,machineinformation.machineid,componentinformation.Interfaceid as cmpinterfaceID,
					componentinformation.componentid,componentoperationpricing.InterfaceID,
					componentoperationpricing.machiningtime,componentoperationpricing.cycletime
					,componentoperationpricing.operationno
				From componentinformation 
				inner join componentoperationpricing on componentinformation.componentiD=componentoperationpricing.componentiD
				inner join machineinformation on machineinformation.machineid=componentoperationpricing.machineid
					Where machineinformation.machineID in ('+@MachineID+')
				)T1 on  autodata.comp=T1.cmpinterfaceID and autodata.opn=T1.interfaceid and T1.mc=autodata.mc
	left outer join employeeinformation on autodata.opr= employeeinformation.InterfaceID 
ORDER BY autodata.mc,autodata.sttime'
		print(@strsql)
		Exec(@strsql)
		Return
 End
if @Type='ProdData' and @Format='IID'--Production Data with InterfaceID
	Begin
		Select @strsql='SELECT autodata.mc AS [Machine ID], autodata.comp AS [Component ID],
						autodata.opn AS [Operation ID], autodata.opr AS [Operator ID],
						autodata.stdate AS [Start Date], autodata.sttime AS [Start Time],
						autodata.nddate AS [End Date], autodata.ndtime AS EndTime
						,autodata.cycletime AS [Cycle Time],autodata.loadunload As [LoadUnload Time], 
						autodata.Remarks , autodata.msttime,autodata.WorkOrderNumber --vasavi
						FROM autodata 
						INNER JOIN machineinformation ON autodata.mc = machineinformation.InterfaceID
						Where autodata.sttime >= '''+convert(nvarchar(25),@StartDate,120)+''' and 
						autodata.sttime<= '''+convert(nvarchar(25),@EndDate,120)+'''
						And autodata.datatype = 1 and machineinformation.machineID in ('+@machineiD +') 
						ORDER BY autodata.mc,autodata.sttime'
		print(@strsql)
		Exec(@strsql)
		return
 End
if @Type='DownData' and @Format='BID'--Production Data with InterfaceID
	Begin
		Select @strsql='SELECT   autodata.mc AS [Machine ID],T1.machineid as [Machine Name],
						autodata.comp AS [Component ID],t1.componentid as [Component Name],
						autodata.opn AS [Operation ID],T1.operationno as [Operation No],
						autodata.opr AS [Operator ID],employeeinformation.employeeid as [Operator Name],
						autodata.dcode AS [Down Code],downcodeinformation.downid as [Down Reason],
						autodata.stdate AS [Start Date],autodata.sttime AS [Start Time],
						autodata.nddate AS [End Date],autodata.ndtime AS EndTime,autodata.datatype AS [Prod/Down Code],
						autodata.cycletime AS [A.Cycle Time],autodata.loadunload As [A.LoadUnload Time]
						,autodata.Remarks,autodata.WorkOrderNumber 
						From (Select mc,comp,opn,opr,stdate,ndtime,sttime,nddate,dcode,datatype,loadunload,remarks,cycletime,WorkOrderNumber from autodata
									inner join machineinformation on machineinformation.interfaceid=autodata.mc
				where autodata.sttime >= '''+convert(nvarchar(25),@StartDate,120)+''' and autodata.sttime<=  '''+convert(nvarchar(25),@EndDate,120)+'''  and
				(datatype=2) and machineinformation.MachineiD in ('+@machineiD+'))autodata
			 left outer JOIN  ( Select	machineinformation.interfaceID as MC,machineinformation.machineid,componentinformation.Interfaceid as cmpinterfaceID,
					componentinformation.componentid,componentoperationpricing.InterfaceID,
					componentoperationpricing.machiningtime,componentoperationpricing.cycletime
					,componentoperationpricing.operationno
				From componentinformation 
				inner join componentoperationpricing on componentinformation.componentiD=componentoperationpricing.componentiD
				inner join machineinformation on machineinformation.machineid=componentoperationpricing.machineid
					Where machineinformation.machineID in ('+@machineiD+')
				)T1 on  autodata.comp=T1.cmpinterfaceID and autodata.opn=T1.interfaceid and T1.mc=autodata.mc
						left outer join downcodeinformation on autodata.dcode=downcodeinformation.InterfaceID
						left outer join employeeinformation on autodata.opr= employeeinformation.InterfaceID 
						ORDER BY autodata.mc,autodata.sttime'
		print(@strsql)
		Exec(@strsql)
		return
 End
if @Type='DownData' and @Format='IID'--Production Data with InterfaceID
	Begin
		Select @strsql='SELECT autodata.mc AS [Machine ID], autodata.comp AS [Component ID],
						autodata.opn AS [Operation ID], autodata.opr AS [Operator ID], 
						autodata.dcode AS [Down Code], autodata.stdate AS [Start Date], 
						autodata.sttime AS [Start Time],autodata.nddate AS [End Date],
						autodata.ndtime AS EndTime,autodata.cycletime AS [Cycle Time],
						autodata.loadunload As [LoadUnload Time], autodata.Remarks 
						,autodata.msttime,autodata.WorkOrderNumber  --vasavi
						FROM autodata 
						INNER JOIN machineinformation ON autodata.mc = machineinformation.InterfaceID
						Where autodata.sttime >= '''+convert(nvarchar(25),@StartDate,120)+''' and 
						autodata.sttime<= '''+convert(nvarchar(25),@EndDate,120)+'''
						And autodata.datatype = 2 and machineinformation.machineID in ('+@machineiD +') 
						ORDER BY autodata.mc,autodata.sttime'
		print(@strsql)
		Exec(@strsql)
		return
 End
if @Type='PRD_DownData' and @Format='BID'--Production Data with InterfaceID
	Begin

	if  exists(select * from company where companyName like '%SHANTALA%')
	BEGIN
		Select @strsql='SELECT   autodata.mc AS [Machine ID],t1.machineid as [Machine Name],
						autodata.comp AS [Drawing No],T1.componentid as [Component Name],
						autodata.opn AS [Program No],t1.operationno as [Operation No],
						autodata.opr AS [Operator ID],employeeinformation.employeeid as [Operator Name]
						,autodata.dcode AS [Down Code],downcodeinformation.downid as [Down Reason],
						autodata.stdate AS [Start Date],autodata.sttime AS [Start Time],autodata.nddate AS [End Date],
						autodata.ndtime AS EndTime,autodata.datatype AS [Prod/Down Code],autodata.cycletime AS [A.Cycle Time],
						autodata.loadunload As [A.LoadUnload Time],
						autodata.Remarks,Round((t1.machiningtime*autodata.Partscount),2) as [I.MachiningTime] ,  --ER0379
						Round((t1.cycletime*autodata.Partscount),2) as [I.CycleTime], --ER0379
						(t1.cycletime - t1.machiningtime) as [I.loadunload],
						Round(autodata.Partscount,2) as [Partscount] , --ER0379
						autodata.WorkOrderNumber as WorkOrderNumber --Vasavi
						From (Select mc,comp,opn,opr,stdate,ndtime,sttime,nddate,dcode,datatype,loadunload,remarks,cycletime,Partscount,WorkOrderNumber from autodata --SV --Vasavi
									inner join machineinformation on machineinformation.interfaceid=autodata.mc
				where autodata.sttime >='''+convert(nvarchar(25),@StartDate,120)+''' and autodata.sttime<= '''+convert(nvarchar(25),@EndDate,120)+'''  and
				(datatype=1 or datatype=2) and machineinformation.MachineiD in ('+ @machineID+'))autodata
			 left outer JOIN  ( Select	machineinformation.interfaceID as MC,machineinformation.machineid,componentinformation.Interfaceid as cmpinterfaceID,
					componentinformation.componentid,componentoperationpricing.InterfaceID,
					componentoperationpricing.machiningtime,componentoperationpricing.cycletime
					,componentoperationpricing.operationno
				From componentinformation 
				inner join componentoperationpricing on componentinformation.componentiD=componentoperationpricing.componentiD
				inner join machineinformation on machineinformation.machineid=componentoperationpricing.machineid
					Where machineinformation.machineID in ('+@MachineID+')
				)T1 on  autodata.comp=T1.cmpinterfaceID and autodata.opn=T1.interfaceid and T1.mc=autodata.mc
						left outer join downcodeinformation on autodata.dcode=downcodeinformation.InterfaceID
						left outer join employeeinformation on autodata.opr= employeeinformation.InterfaceID 
						ORDER BY autodata.mc,autodata.sttime'
		print(@strsql)
		Exec(@strsql)
		return
	END
	else
	begin
		Select @strsql='SELECT   autodata.mc AS [Machine ID],t1.machineid as [Machine Name],
						autodata.comp AS [Component ID],T1.componentid as [Component Name],
						autodata.opn AS [Operation ID],t1.operationno as [Operation No],
						autodata.opr AS [Operator ID],employeeinformation.employeeid as [Operator Name]
						,autodata.dcode AS [Down Code],downcodeinformation.downid as [Down Reason],
						autodata.stdate AS [Start Date],autodata.sttime AS [Start Time],autodata.nddate AS [End Date],
						autodata.ndtime AS EndTime,autodata.datatype AS [Prod/Down Code],autodata.cycletime AS [A.Cycle Time],
						autodata.loadunload As [A.LoadUnload Time],
						autodata.Remarks,Round((t1.machiningtime*autodata.Partscount),2) as [I.MachiningTime] ,  --ER0379
						Round((t1.cycletime*autodata.Partscount),2) as [I.CycleTime], --ER0379
						(t1.cycletime - t1.machiningtime) as [I.loadunload],
						Round(autodata.Partscount,2) as [Partscount] , --ER0379
						autodata.WorkOrderNumber as WorkOrderNumber --Vasavi
						From (Select mc,comp,opn,opr,stdate,ndtime,sttime,nddate,dcode,datatype,loadunload,remarks,cycletime,Partscount,WorkOrderNumber from autodata --SV --Vasavi
									inner join machineinformation on machineinformation.interfaceid=autodata.mc
				where autodata.sttime >='''+convert(nvarchar(25),@StartDate,120)+''' and autodata.sttime<= '''+convert(nvarchar(25),@EndDate,120)+'''  and
				(datatype=1 or datatype=2) and machineinformation.MachineiD in ('+ @machineID+'))autodata
			 left outer JOIN  ( Select	machineinformation.interfaceID as MC,machineinformation.machineid,componentinformation.Interfaceid as cmpinterfaceID,
					componentinformation.componentid,componentoperationpricing.InterfaceID,
					componentoperationpricing.machiningtime,componentoperationpricing.cycletime
					,componentoperationpricing.operationno
				From componentinformation 
				inner join componentoperationpricing on componentinformation.componentiD=componentoperationpricing.componentiD
				inner join machineinformation on machineinformation.machineid=componentoperationpricing.machineid
					Where machineinformation.machineID in ('+@MachineID+')
				)T1 on  autodata.comp=T1.cmpinterfaceID and autodata.opn=T1.interfaceid and T1.mc=autodata.mc
						left outer join downcodeinformation on autodata.dcode=downcodeinformation.InterfaceID
						left outer join employeeinformation on autodata.opr= employeeinformation.InterfaceID 
						ORDER BY autodata.mc,autodata.sttime'
		print(@strsql)
		Exec(@strsql)
		return



	end

 End
if @Type='PRD_DownData' and @Format='IID'--Production Data with InterfaceID
	Begin

	
	if  exists(select * from company where companyName like '%SHANTALA%')
	BEGIN
		Select @strsql='SELECT	 autodata.mc AS [Machine ID], autodata.comp AS [Drawing No.], autodata.opn AS [Program No.],
								 autodata.opr AS [Operator ID], autodata.dcode AS [Down Code], autodata.stdate AS [Start Date],
								 autodata.sttime AS [Start Time], autodata.nddate AS [End Date], autodata.ndtime AS EndTime,
								 autodata.datatype AS [Prod/Down Record], autodata.cycletime AS [Cycle Time],autodata.loadunload As [LoadUnload Time],
								 autodata.Remarks , autodata.msttime,autodata.WorkOrderNumber 
						FROM autodata 
						INNER JOIN machineinformation ON autodata.mc = machineinformation.InterfaceID
						Where autodata.sttime >= '''+convert(nvarchar(25),@StartDate,120)+''' and 
						autodata.sttime<= '''+convert(nvarchar(25),@EndDate,120)+'''
						And (autodata.datatype = 1 or autodata.datatype = 2) and machineinformation.machineID in ('+@machineiD +') 
						ORDER BY autodata.mc,autodata.sttime'
		print(@strsql)
		Exec(@strsql)
		return
	END
	else
	BEGIN
		Select @strsql='SELECT	 autodata.mc AS [Machine ID], autodata.comp AS [Component ID], autodata.opn AS [Operation ID],
								 autodata.opr AS [Operator ID], autodata.dcode AS [Down Code], autodata.stdate AS [Start Date],
								 autodata.sttime AS [Start Time], autodata.nddate AS [End Date], autodata.ndtime AS EndTime,
								 autodata.datatype AS [Prod/Down Record], autodata.cycletime AS [Cycle Time],autodata.loadunload As [LoadUnload Time],
								 autodata.Remarks , autodata.msttime,autodata.WorkOrderNumber 
						FROM autodata 
						INNER JOIN machineinformation ON autodata.mc = machineinformation.InterfaceID
						Where autodata.sttime >= '''+convert(nvarchar(25),@StartDate,120)+''' and 
						autodata.sttime<= '''+convert(nvarchar(25),@EndDate,120)+'''
						And (autodata.datatype = 1 or autodata.datatype = 2) and machineinformation.machineID in ('+@machineiD +') 
						ORDER BY autodata.mc,autodata.sttime'
		print(@strsql)
		Exec(@strsql)
		return

	END

 End


END
