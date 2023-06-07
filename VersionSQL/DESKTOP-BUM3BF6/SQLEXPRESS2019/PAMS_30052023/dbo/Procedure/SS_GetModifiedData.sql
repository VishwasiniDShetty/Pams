/****** Object:  Procedure [dbo].[SS_GetModifiedData]    Committed by VersionSQL https://www.versionsql.com ******/

--exec SS_GetModifiedData @Machineid=N'236',@StartTime='2017-01-26 13:04:00',@EndTime='2017-01-28 13:04:00',@param=N'Production Data'
--select distinct Interfaceid from componentinformation
--select * from employeeinformation
--select * from AutodataRejections
CREATE PROCEDURE [dbo].[SS_GetModifiedData]
	@StartTime datetime,
	@EndTime datetime,
	@MachineID nvarchar(50) = '',
	@param nvarchar(50)=''

AS
BEGIN

SET NOCOUNT ON;
if(@param = 'Production Data')
BEGIN
	select id,mc,WorkOrderNumber as WorkOrderNo,comp as ComponentInterfaceid,isnull(CI.Componentid ,comp) as  Component,opn as Operation, 
	opr as OperatorInterfaceid,isnull(EI.Employeeid,opr) as Operator ,Partscount as PartsCount,dcode as DownId, compslno as SerialNo, --g:
	sttime as [TimeFrom],ndtime as [TimeTo]  from autodata left outer join componentinformation CI on  CI.Interfaceid = autodata.comp 
	left outer join Employeeinformation EI on EI.Interfaceid= autodata.opr
	where datatype=1 and mc=@machineid  and sttime >= @StartTime
	and ndtime <= @EndTime  order by sttime asc
END

if(@param = 'Down Data')
BEGIN
	select  WorkOrderNumber as WorkOrderNo,comp as ComponentInterfaceid,isnull(CI.Componentid ,comp) as  Component,
	opn as Operation,opr as OperatorInterfaceid,isnull(EI.Employeeid,opr) as Operator ,A.dcode as DownId,isnull(DCI.downid, A.dcode) as downcode, compslno as SerialNo, --g:
	sttime as [TimeFrom],ndtime as [TimeTo],id from autodata A left outer join downcodeinformation DCI on A.dcode=DCI.Interfaceid 
	left outer join componentinformation CI on  CI.Interfaceid = A.comp
	left outer join Employeeinformation EI on EI.Interfaceid= A.opr
	where   datatype= 2 and mc=@machineid and sttime >= @StartTime and ndtime <= @EndTime
	order by sttime asc
END

if(@param = 'Machine Events')
BEGIN
	select M.alarmnumber as Eventnumber ,A.alarmtime as Eventtime from autodataalarms  A 
	inner join machineAlarminformation M on A.Alarmnumber=M.alarmnumber_Binary where recordtype='16'  
	and A.machineid=@MachineID  and A.alarmtime>=@StartTime and A.alarmtime <= @EndTime order by A.alarmtime asc
END

if(@param = 'Rejection Data')
BEGIN
	select id,mc,comp as ComponentInterfaceid,isnull(CI.Componentid ,comp) as  Component,opn as Operation,opr as OperatorInterfaceid,isnull(EI.Employeeid,opr) as Operator ,Rejection_code as RejectionCode ,rejection_qty as RejectionQty,createdTs,id as CreatedTimeStamp,Rejdate as RejectionDate, --compslno as SerialNo, --g:
	RejShift as RejectionShift from AutodataRejections left outer join componentinformation CI on  CI.Interfaceid = AutodataRejections.comp
	left outer join Employeeinformation EI on EI.Interfaceid= AutodataRejections.opr
	where mc=@MachineID  
	and  createdts between @StartTime and @EndTime order by createdts asc
END


if(@param = 'OperatorInconsistencyInProd')
BEGIN
	select  id,WorkOrderNumber as WorkOrderNo,comp as ComponentInterfaceid,isnull(CI.Componentid ,comp) as  Component,opn as Operation,opr as OperatorInterfaceid,isnull(EI.Employeeid,opr) as Operator ,
	Partscount as PartsCount,sttime as [TimeFrom],ndtime as [TimeTo], compslno as SerialNo --g:
	from autodata  left outer join Employeeinformation EI on EI.Interfaceid= autodata.opr 
	left outer join componentinformation CI on  CI.Interfaceid = autodata.comp 
	where mc=@machineid and  datatype= 1  and
	sttime >= @StartTime and ndtime <= @EndTime and ( opr in (select interfaceid from employeeinformation where company_default = 1) 
	or opr is null or opr not in (select interfaceid from employeeinformation ))
END


if(@param = 'OperatorInconsistencyInDown')
BEGIN
	select id, WorkOrderNumber as WorkOrderNo,comp as ComponentInterfaceid,isnull(CI.Componentid ,comp) as  Component,opn as Operation,opr as OperatorInterfaceid,isnull(EI.Employeeid,opr) as Operator ,Partscount as PartsCount,sttime as [TimeFrom],ndtime as [TimeTo], compslno as SerialNo --g: 
	from autodata left outer join Employeeinformation EI on EI.Interfaceid= autodata.opr 
	left outer join componentinformation CI on  CI.Interfaceid = autodata.comp
	 where mc=@machineid and  datatype= 2  and
	sttime >= @StartTime and ndtime <= @EndTime and ( opr in (select interfaceid from employeeinformation where company_default = 1) 
	or opr is null or opr not in (select interfaceid from employeeinformation ))
END


if(@param = 'Component-OperationInconsistencyInProd')
BEGIN
	select id,comp as ComponentInterfaceid,isnull(CI.Componentid ,comp) as  Component,opn as Operation,opr as OperatorInterfaceid,isnull(EI.Employeeid,opr) as Operator,dcode as DownId,sttime as [TimeFrom],ndtime as [TimeTo],Partscount as PartsCount, compslno as SerialNo, --g:
	WorkOrderNumber as WorkOrderNo from autodata 
		left outer join componentinformation CI on  CI.Interfaceid = autodata.comp
		left outer join Employeeinformation EI on EI.Interfaceid= autodata.opr 
	where   datatype= 1 
	and mc=@MachineID  and  sttime >= @StartTime and ndtime <= @EndTime
	AND (mc+' '+comp+' '+ opn not in (select m.interfaceid+' '+c.interfaceid+' '+o.interfaceid from componentinformation C
	inner join  componentoperationpricing O on O.componentid=C.componentid inner join machineinformation m on m.machineid=o.machineid where
	m.interfaceid+' '+c.interfaceid+' '+o.interfaceid is not null )  OR mc is null or comp is null  or opn is null  )  
END


if(@param = 'Component-OperationInconsistencyInDown')
BEGIN
	select id,comp as ComponentInterfaceid,isnull(CI.Componentid ,comp) as  Component,Partscount as PartsCount,opn as Operation,opr as OperatorInterfaceid,isnull(EI.Employeeid,opr) as Operator,dcode as DownId,sttime as [TimeFrom],ndtime as [TimeTo],WorkOrderNumber as WorkOrderNo, compslno as SerialNo --g:
	 from autodata left outer join componentinformation CI on  CI.Interfaceid = autodata.comp
	 left outer join Employeeinformation EI on EI.Interfaceid= autodata.opr
	  where datatype= 2 
	and mc=@MachineID  and  sttime >= @StartTime and ndtime <= @EndTime
	AND (mc+' '+comp+' '+ opn not in (select m.interfaceid+' '+c.interfaceid+' '+o.interfaceid from componentinformation C
	inner join  componentoperationpricing O on O.componentid=C.componentid inner join machineinformation m on m.machineid=o.machineid where
	m.interfaceid+' '+c.interfaceid+' '+o.interfaceid is not null )  OR mc is null or comp is null  or opn is null  )  
END


if(@param = 'downIDInconsistencyInProd')
BEGIN
select id,comp as ComponentInterfaceid,isnull(CI.Componentid ,comp) as  Component,Partscount as PartsCount,opn as Operation,opr as OperatorInterfaceid,isnull(EI.Employeeid,opr) as Operator, dcode as DownId ,sttime as [TimeFrom],ndtime as [TimeTo], compslno as SerialNo, --g:
WorkOrderNumber as WorkOrderNo from autodata left outer join componentinformation CI on  CI.Interfaceid = autodata.comp
	 left outer join Employeeinformation EI on EI.Interfaceid= autodata.opr
  where  datatype=1  and mc=@MachineID and  sttime >=@StartTime and ndtime <= @EndTime  
 and (dcode in('unknown','NO_DATA','  ') or dcode is null  or dcode not in(select interfaceid from downcodeinformation))
END


if(@param = 'downIDInconsistencyInDown')
BEGIN
select id,comp as ComponentInterfaceid,isnull(CI.Componentid ,comp) as  Component,Partscount as PartsCount,opn as Operation,opr as OperatorInterfaceid,isnull(EI.Employeeid,opr) as Operator, dcode as DownId ,sttime as [TimeFrom],ndtime as [TimeTo], compslno as SerialNo, --g:
WorkOrderNumber as WorkOrderNo from autodata  left outer join componentinformation CI on  CI.Interfaceid = autodata.comp
	 left outer join Employeeinformation EI on EI.Interfaceid= autodata.opr
  where  datatype=2  and mc=@Machineid and  sttime >= @StartTime and ndtime <= @EndTime  
 and (dcode in('unknown','NO_DATA','  ') or dcode is null  or dcode not in(select interfaceid from downcodeinformation))

END
END
