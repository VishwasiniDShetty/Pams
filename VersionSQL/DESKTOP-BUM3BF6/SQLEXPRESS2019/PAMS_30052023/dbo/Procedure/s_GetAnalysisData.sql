/****** Object:  Procedure [dbo].[s_GetAnalysisData]    Committed by VersionSQL https://www.versionsql.com ******/

/*
----------------------------------------------------------------------------------------------------------------------------------------------------------------
--ER0176-10/Mar/2009 :: procedure created by KarthikG to get data from autodata and rawdata
	--for analysis. The data is showed in the screen which popups from VDG of TableCockpit.
---mod 1:- By Kusuma M.H for ER0192 on 25-Aug-2009.b)Add machine qualification in the procedure 's_GetAnalysisData'. If CO is not defined show the column blank.
--ER0203-26/Oct/2009-Karthik G :: SmartCockpit->VDG->Analysis. Show IncycleDown in raw data tab and count of IncycleDown in the top region. DataType for icd is 42.
----------------------------------------------------------------------------------------------------------------------------------------------------------------
--s_GetAnalysisData '2008-07-01','2008-07-05','asdasd','autodata'
--s_GetAnalysisData '2009-03-01 09:00:00','2009-03-10 20:29:56.000','LT 25 1','autodata'

exec s_GetAnalysisData @StartTime=N'2021-06-19 08:30:00',@EndTime=N'2021-06-20 08:30:00',@MachineId=N'Cleaning Shuttle-1',@Param=N'statistics'
exec s_GetAnalysisData @StartTime=N'2021-06-21 08:30:00',@EndTime=N'2021-06-22 08:30:00',@MachineId=N'Cleaning Shuttle-1',@Param=N'statistics'

*/

CREATE                 PROCEDURE [dbo].[s_GetAnalysisData]
		@StartTime as Datetime,
		@EndTime as datetime,
		@MachineID as nvarchar(50),
		@Param as nvarchar(20) -- rawdata / autodata / statistics
AS
BEGIN
declare @tempCount as int

If isnull(@Param,'') = 'rawdata'
BEGIN
	---mod 1		
--	select machineinformation.machineID,componentinformation.ComponentID,componentOperationPricing.operationno,
	select machineinformation.machineID,componentinformation.ComponentID,comp,componentOperationPricing.operationno,opn,
	---mod 1
	--MC,Comp,Opn,
	Sttime,Ndtime,DataType from rawdata
	---mod 1
--	inner join machineinformation on machineinformation.interfaceid=rawdata.mc inner join
	FULL OUTER JOIN machineinformation on machineinformation.interfaceid=rawdata.mc FULL OUTER JOIN
	---mod 1
	componentinformation on rawdata.comp=componentinformation.interfaceid
	---mod 1
--	inner join componentoperationpricing on componentoperationpricing.interfaceid=rawdata.opn and
	FULL OUTER JOIN componentoperationpricing on componentoperationpricing.interfaceid=rawdata.opn and
	---mod 1
	componentinformation.componentid=componentoperationpricing.componentid
	---mod 1
	AND componentoperationpricing.machineid = machineinformation.machineid
	---mod 1
	where machineinformation.machineID = @MachineID and (
	(DataType = 11 and sttime >= @StartTime and sttime < @EndTime) or
	(DataType = 1 and ndtime > @StartTime and ndtime <= @EndTime) or
	(DataType = 42 and ndtime > @StartTime and ndtime <= @EndTime) or	--ER0203-26/Oct/2009-Karthik G
	(DataType = 2 and ndtime > @StartTime and ndtime <= @EndTime))
	order by sttime,rawdata.Slno
END
else if isnull(@Param,'') = 'autodata'
BEGIN
	---mod 1
--	select machineinformation.machineID,componentinformation.ComponentID,componentOperationPricing.operationno,
	select machineinformation.machineID,componentinformation.ComponentID,comp,componentOperationPricing.operationno,opn,
	---mod 1
	--MC,Comp,Opn,
	Sttime,Ndtime,DataType from autodata
	---mod 1
--	inner join machineinformation on machineinformation.interfaceid=autodata.mc inner join
	FULL OUTER JOIN machineinformation on machineinformation.interfaceid=autodata.mc FULL OUTER JOIN
	---mod 1
	componentinformation on autodata.comp=componentinformation.interfaceid
	---mod 1
--	inner join componentoperationpricing on componentoperationpricing.interfaceid=autodata.opn and
	FULL OUTER JOIN componentoperationpricing on componentoperationpricing.interfaceid=autodata.opn and
	---mod 1
	componentinformation.componentid=componentoperationpricing.componentid
	---mod 1
	AND componentoperationpricing.machineid = machineinformation.machineid
	---mod 1
	where machineinformation.machineID = @MachineID and (
	(DataType = 1 and ndtime > @StartTime and ndtime <= @EndTime) or
	(DataType = 2 and ndtime > @StartTime and ndtime <= @EndTime and autodata.dcode not in ('NO_DATA','McTI','CyCTI')))
	order by sttime,autodata.[id]
END
else if isnull(@Param,'') = 'statistics'
BEGIN
CREATE TABLE #statistic
(
	Parameter NVarChar(50),
	pCount Int
)
	select @tempCount = count(distinct Sttime) from rawdata
	inner join machineinformation on machineinformation.interfaceid=rawdata.mc inner join
	componentinformation on rawdata.comp=componentinformation.interfaceid
	inner join componentoperationpricing on componentoperationpricing.interfaceid=rawdata.opn and
	componentinformation.componentid=componentoperationpricing.componentid
	---mod 1
	AND componentoperationpricing.machineid = machineinformation.machineid
	---mod 1
	where machineinformation.machineID = @MachineID and DataType = 11 and sttime >= @StartTime and sttime < @EndTime

	insert into #statistic (Parameter,pcount) values('ProgramStart',@tempCount)

	select @tempCount = count(distinct Sttime) from rawdata
	inner join machineinformation on machineinformation.interfaceid=rawdata.mc inner join
	componentinformation on rawdata.comp=componentinformation.interfaceid
	inner join componentoperationpricing on componentoperationpricing.interfaceid=rawdata.opn and
	componentinformation.componentid=componentoperationpricing.componentid
	---mod 1
	AND componentoperationpricing.machineid = machineinformation.machineid
	---mod 1
	where machineinformation.machineID = @MachineID and DataType = 1 and ndtime > @StartTime and ndtime <= @EndTime

	insert into #statistic (Parameter,pcount) values('ProductionRecord',@tempCount)

	select @tempCount = count(distinct Sttime) from rawdata
	inner join machineinformation on machineinformation.interfaceid=rawdata.mc inner join
	componentinformation on rawdata.comp=componentinformation.interfaceid
	inner join componentoperationpricing on componentoperationpricing.interfaceid=rawdata.opn and
	componentinformation.componentid=componentoperationpricing.componentid
	---mod 1
	AND componentoperationpricing.machineid = machineinformation.machineid
	---mod 1
	where machineinformation.machineID = @MachineID and DataType = 2 and ndtime > @StartTime and ndtime <= @EndTime
	
	insert into #statistic (Parameter,pcount) values('DownRecord',@tempCount)

	--ER0203-26/Oct/2009-Karthik G
	select @tempCount = count(distinct Sttime) from rawdata
	inner join machineinformation on machineinformation.interfaceid=rawdata.mc inner join
	componentinformation on rawdata.comp=componentinformation.interfaceid
	inner join componentoperationpricing on componentoperationpricing.interfaceid=rawdata.opn and
	componentinformation.componentid=componentoperationpricing.componentid
	---mod 1
	AND componentoperationpricing.machineid = machineinformation.machineid
	---mod 1
	where machineinformation.machineID = @MachineID and DataType = 42 and ndtime > @StartTime and ndtime <= @EndTime
	
	insert into #statistic (Parameter,pcount) values('InCycleDownRecord',@tempCount)
	--ER0203-26/Oct/2009-Karthik G

	select @tempCount = count(*) from autodata
	inner join machineinformation on machineinformation.interfaceid=autodata.mc inner join
	componentinformation on autodata.comp=componentinformation.interfaceid
	inner join componentoperationpricing on componentoperationpricing.interfaceid=autodata.opn and
	componentinformation.componentid=componentoperationpricing.componentid
	---mod 1
	AND componentoperationpricing.machineid = machineinformation.machineid
	---mod 1
	where machineinformation.machineID = @MachineID and DataType = 1 and sttime >= @StartTime and sttime < @EndTime

	insert into #statistic (Parameter,pcount) values('ProductionRecordStarted',@tempCount)
	
	select @tempCount = count(*) from autodata
	inner join machineinformation on machineinformation.interfaceid=autodata.mc inner join
	componentinformation on autodata.comp=componentinformation.interfaceid
	inner join componentoperationpricing on componentoperationpricing.interfaceid=autodata.opn and
	componentinformation.componentid=componentoperationpricing.componentid
	---mod 1
	AND componentoperationpricing.machineid = machineinformation.machineid
	---mod 1
	where machineinformation.machineID = @MachineID and DataType = 1 and ndtime > @StartTime and ndtime <= @EndTime

	insert into #statistic (Parameter,pcount) values('ProductionRecordEnded',@tempCount)
	
	select @tempCount = count(*) from autodata
	inner join machineinformation on machineinformation.interfaceid=autodata.mc inner join
	componentinformation on autodata.comp=componentinformation.interfaceid
	inner join componentoperationpricing on componentoperationpricing.interfaceid=autodata.opn and
	componentinformation.componentid=componentoperationpricing.componentid
	---mod 1
	AND componentoperationpricing.machineid = machineinformation.machineid
	---mod 1
	where machineinformation.machineID = @MachineID and DataType = 2 and sttime >= @StartTime and sttime < @EndTime
	and autodata.dcode not in ('NO_DATA','McTI','CyCTI')
	
	insert into #statistic (Parameter,pcount) values('DownRecordStarted',@tempCount)
	
	select @tempCount = count(*) from autodata
	inner join machineinformation on machineinformation.interfaceid=autodata.mc inner join
	componentinformation on autodata.comp=componentinformation.interfaceid
	inner join componentoperationpricing on componentoperationpricing.interfaceid=autodata.opn and
	componentinformation.componentid=componentoperationpricing.componentid
	---mod 1
	AND componentoperationpricing.machineid = machineinformation.machineid
	---mod 1
	where machineinformation.machineID = @MachineID and DataType = 2 and ndtime > @StartTime and ndtime <= @EndTime
	and autodata.dcode not in ('NO_DATA','McTI','CyCTI')	

	insert into #statistic (Parameter,pcount) values('DownRecordEnded',@tempCount)

	select * from #statistic
END
END
