/****** Object:  Procedure [dbo].[s_GetNODataAlerts]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[s_GetNODataAlerts] 'LP LINE-1','600KVA AI BUTTWELDER'
--[dbo].[s_GetNODataAlerts] '',''
CREATE PROCEDURE [dbo].[s_GetNODataAlerts]
@Plantid nvarchar(50)='',
@Machineid nvarchar(50)=''

AS
BEGIN

CREATE TABLE #MachineRunningStatus
(
	MachineID NvarChar(50),
	MachineInterface nvarchar(50),
	sttime Datetime,
	ndtime Datetime,
	DataType smallint,
	ColorCode varchar(10),
	Remarks1 nvarchar(50),
	LastdataArrivalTime datetime,
	LastDataArrivalTimeinMin int,
	LastCompOpn nvarchar(50),
	ConnectionTimestamp datetime,
	ConnectionStatus nvarchar(50),
	PingTimestamp datetime,
	PingStatus nvarchar(50),
	comp nvarchar(50),
	opn nvarchar(50),
	PLCTimestamp datetime,
	PLCStatus nvarchar(50),
	MachineLiveStatus nvarchar(50),
	MachineLiveStatusColor nvarchar(50)

)

Create table #MachineOnlineStatus
(
Machineid nvarchar(50),
LastConnectionOKTime datetime,
LastConnectionFailedTime datetime,
LastPingFailedTime datetime,
LastPingOkTime datetime,
LastPLCCommunicationOK datetime,
LastPLCCommunicationFailed datetime
)

CREATE TABLE #Focas_MachineRunningStatus
(
	[Machineid] [nvarchar](50) NULL,
	[Datatype] [nvarchar](50) NULL,
	[LastCycleTS] [datetime] NULL,
	[AlarmStatus] [nvarchar](50) NULL,
	[SpindleStatus] [int] NULL,
	[SpindleCycleTS] [datetime] NULL,
	[PowerOnOrOff] [int] NULL,
	Machinestatus nvarchar(50),
	MachineLiveStatusColor nvarchar(50)

)

Declare @CurrTime as DateTime
SET @CurrTime = convert(nvarchar(20),getdate(),120)
print @CurrTime


Declare @strPlantID as nvarchar(255)
Declare @strSql as nvarchar(4000)
Declare @strMachine as nvarchar(255)

Select @strsql = ''
SELECT @strMachine = ''
SELECT @strPlantID = ''

if isnull(@machineid,'')<> ''
begin
	SET @strMachine = ' AND MachineInformation.MachineID = N''' + @machineid + ''''
end

if isnull(@PlantID,'')<> ''
Begin
	SET @strPlantID = ' AND PlantMachine.PlantID = N''' + @PlantID + ''''
End

Declare @Type40Threshold int
Declare @Type1Threshold int
Declare @Type11Threshold int

Set @Type40Threshold =0
Set @Type1Threshold = 0
Set @Type11Threshold = 0

Set @Type40Threshold = (Select isnull(Valueintext2,5)*60 from shopdefaults where parameter='ANDONStatusThreshold' and valueintext = 'Type40Threshold')
Set @Type1Threshold = (Select isnull(Valueintext2,5)*60 from shopdefaults where parameter='ANDONStatusThreshold' and valueintext = 'Type1Threshold')
Set @Type11Threshold = (Select isnull(Valueintext2,5)*60 from shopdefaults where parameter='ANDONStatusThreshold' and valueintext = 'Type11Threshold')
print @Type40Threshold
print @Type1Threshold
print @Type11Threshold

Select @strsql= ''
Select @strsql = @strsql + '
Insert into #machineRunningStatus(MachineID,MachineInterface,sttime,ndtime,DataType,ColorCode,Remarks1,LastCompOpn,comp,opn)
select machineinformation.MachineID,machineinformation.interfaceid,sttime,ndtime,datatype,''White'',''Stopped'',Case when datatype=''40'' or datatype=''41'' then ''NA'' else comp+ '' | '' + opn end,comp,opn from rawdata
inner join (select mc,max(slno) as slno from rawdata WITH (NOLOCK) where sttime< ''' + convert(nvarchar(20),@currtime,120) + ''' and isnull(ndtime,''1900-01-01'')<''' + convert(nvarchar(20),@currtime,120) + '''
and datatype in(2,42,40,41,1,11) group by mc ) t1 on t1.mc=rawdata.mc and t1.slno=rawdata.slno
inner join machineinformation on machineinformation.interfaceid = rawdata.mc 
inner join plantmachine on machineinformation.machineid=plantmachine.machineid
where machineinformation.TPMTrakEnabled=1 and machineinformation.DNCTransferEnabled=0 '
SET @strSql =  @strSql + @strMachine + @strPlantID
SET @strSql =  @strSql + ' order by rawdata.mc'
EXEC(@strSql)

update #machineRunningStatus set LastCompOpn= ''  from(
Select EX.MachineID,Ex.LastCompOpn as lastco from #machineRunningStatus ex
Inner Join MachineInformation M ON Ex.MachineID=M.machineid
Inner Join ComponentInformation C ON Ex.comp=C.InterfaceID
Inner Join Componentoperationpricing O ON Ex.opn=O.InterfaceID AND C.ComponentID=O.ComponentID  and O.MachineId=Ex.MachineId 
)T1  inner join #machineRunningStatus on t1.MachineID = #machineRunningStatus.MachineID

update #machineRunningStatus set ColorCode = case when (datediff(second,sttime,@CurrTime)- @Type11Threshold)>0  then 'Red' else 'Green' end where datatype in (11)
update #machineRunningStatus set ColorCode = 'Green' where datatype in (41)
update #machineRunningStatus set ColorCode = 'Red' where datatype in (42,2)

update #machineRunningStatus set ColorCode = t1.ColorCode from (
Select mrs.MachineID,Case when (
case when datatype = 40 then datediff(second,sttime,@CurrTime)- @Type40Threshold
when datatype = 1 then datediff(second,ndtime,@CurrTime)- @Type1Threshold
end) > 0 then 'Red' else 'Green' end as ColorCode
from #machineRunningStatus mrs 
where  datatype in (40,1)
) as t1 inner join #machineRunningStatus on t1.MachineID = #machineRunningStatus.MachineID

update #machineRunningStatus set ColorCode ='Red' where isnull(sttime,'1900-01-01')='1900-01-01'

update #machineRunningStatus set Remarks1 = T1.MCStatus from 
(select Machineid,
Case when Colorcode='White' then 'NOT OK'
when Colorcode='Red' then 'NOT OK'
when Colorcode='Green' then 'OK' end as MCStatus from #machineRunningStatus)T1
inner join #machineRunningStatus on T1.MachineID = #machineRunningStatus.MachineID

update #machineRunningStatus SET LastdataArrivalTime=T1.LastArrival from
(Select Machineid,Case when ndtime IS NULL then sttime else ndtime end as LastArrival
from #machineRunningStatus
)T1 inner join #machineRunningStatus on T1.MachineID = #machineRunningStatus.MachineID

update #machineRunningStatus SET LastDataArrivalTimeinMin = datediff(minute,LastdataArrivalTime,@CurrTime)


Select @strsql=''
Select @strsql = @strsql + 'Insert into  #MachineOnlineStatus(Machineid,LastConnectionOKTime,LastConnectionFailedTime,LastPingFailedTime,LastPingOkTime,LastPLCCommunicationOK,LastPLCCommunicationFailed)
select MachineOnlineStatus.Machineid,Max(LastConnectionOKTime) as LastConnectionOKTime,Max(LastConnectionFailedTime) as LastConnectionFailedTime,
Max(LastPingFailedTime) as LastPingFailedTime,Max(LastPingOkTime)as LastPingOkTime,
MAX(LastPLCCommunicationOK),MAX(LastPLCCommunicationFailed) from MachineOnlineStatus
inner join machineinformation on machineinformation.machineid = MachineOnlineStatus.machineid 
inner join plantmachine on machineinformation.machineid=plantmachine.machineid
where machineinformation.TPMTrakEnabled=1 and machineinformation.DNCTransferEnabled=0 '
SET @strSql =  @strSql + @strMachine + @strPlantID
SET @strSql =  @strSql + ' group by MachineOnlineStatus.MachineID'
EXEC(@strSql)


update #MachineRunningStatus set ConnectionTimestamp = T1.ConnectionTS,ConnectionStatus = T1.Connectionstatus from
(select Machineid,
Case when ISNULL(LastConnectionOKTime,'1900-01-01')>ISNULL(LastConnectionFailedTime,'1900-01-01') then LastConnectionOKTime else LastConnectionFailedTime end as ConnectionTS ,
Case when ISNULL(LastConnectionOKTime,'1900-01-01')>ISNULL(LastConnectionFailedTime,'1900-01-01') then 'OK' else 'NOT OK' end as Connectionstatus
from #MachineOnlineStatus
)T1 inner join #machineRunningStatus on T1.MachineID = #machineRunningStatus.MachineID

update #MachineRunningStatus set PingTimestamp = T1.PingTimestamp,PingStatus = T1.PingStatus from
(select Machineid,
Case when ISNULL(LastPingOkTime,'1900-01-01')>ISNULL(LastPingFailedTime,'1900-01-01') then LastPingOkTime else LastPingFailedTime end as PingTimestamp ,
Case when ISNULL(LastPingOkTime,'1900-01-01')>ISNULL(LastPingFailedTime,'1900-01-01') then 'OK' else 'NOT OK' end as PingStatus
from #MachineOnlineStatus
)T1 inner join #machineRunningStatus on T1.MachineID = #machineRunningStatus.MachineID


update #MachineRunningStatus set PLCTimestamp = T1.PLCTimestamp,PLCStatus = T1.PLCStatus from
(select Machineid,
Case when ISNULL(LastPLCCommunicationOK,'1900-01-01')>ISNULL(LastPLCCommunicationFailed,'1900-01-01') then LastPLCCommunicationOK else LastPLCCommunicationFailed end as PLCTimestamp ,
Case when ISNULL(LastPLCCommunicationOK,'1900-01-01')>ISNULL(LastPLCCommunicationFailed,'1900-01-01') then 'OK' else 'NOT OK' end as PLCStatus
from #MachineOnlineStatus
)T1 inner join #machineRunningStatus on T1.MachineID = #machineRunningStatus.MachineID

---------------------------------- Added to handle Machine Status for Focas Machines ----------------------------------
insert into #Focas_MachineRunningStatus(Machineid,Datatype,LastCycleTS,AlarmStatus,SpindleCycleTS,SpindleStatus,PowerOnOrOff)
select distinct machineinformation.machineid,Datatype,LastCycleTS,AlarmStatus,SpindleCycleTS,SpindleStatus,PowerOnOrOff from machineinformation 
left join Focas_MachineRunningStatus F on machineinformation.machineid=F.machineid
inner join plantmachine on machineinformation.machineid=plantmachine.machineid
where machineinformation.TPMTrakEnabled=1 and machineinformation.DNCTransferEnabled=1

update #Focas_MachineRunningStatus set Machinestatus=T.Machinestatus from
(select machineid, 
Case 
when AlarmStatus not in('Alarm','Emergency') and PowerOnOrOff=1 and Datatype=1 and datediff(second,LastCycleTS,@CurrTime)- @Type1Threshold>0 then 'Down'
when AlarmStatus not in('Alarm','Emergency') and PowerOnOrOff=1 and Datatype=2 then 'Down'
when AlarmStatus not in('Alarm','Emergency') and PowerOnOrOff=1 and Datatype=11 and SpindleStatus=2 and datediff(second,SpindleCycleTS,@CurrTime)- @Type40Threshold>0  and datediff(second,LastCycleTS,@CurrTime)>10 then 'ICD'
when AlarmStatus not in('Alarm','Emergency') and PowerOnOrOff=1 and Datatype=11 and datediff(second,LastCycleTS,@CurrTime)<=10 then 'Running'
when AlarmStatus not in('Alarm','Emergency') and PowerOnOrOff=1 and Datatype=11 and SpindleStatus=1 then 'Running'
when AlarmStatus in('Alarm') and PowerOnOrOff=1 then 'Alarm'
when AlarmStatus in('Emergency') and PowerOnOrOff=1 then 'Emergency'
when AlarmStatus not in('Alarm','Emergency') and PowerOnOrOff=1 and Datatype=1 and datediff(second,LastCycleTS,@CurrTime)<@Type1Threshold then 'Load Unload'
when AlarmStatus not in('Alarm','Emergency') and PowerOnOrOff=2 then 'Disconnected'
END as Machinestatus
from #Focas_MachineRunningStatus
)T inner join #Focas_MachineRunningStatus on T.Machineid=#Focas_MachineRunningStatus.Machineid

update #MachineRunningStatus set MachineLiveStatus=T.Machinestatus from
(select machineid, 
Case 
when Datatype in(2,42,22) then 'Down'
when Datatype=40 and datediff(second,sttime,@CurrTime)- @Type40Threshold>0 then 'ICD'
when Datatype=11 and (datediff(second,sttime,@CurrTime)<=@Type11Threshold) then 'Running' 
when Datatype=41 then 'Running'
when Datatype=1 and datediff(second,ndtime,@CurrTime)<@Type1Threshold then 'Load Unload'
when PingStatus='NOT OK' then 'Disconnected'
END as Machinestatus
from #MachineRunningStatus
)T inner join #MachineRunningStatus on T.Machineid=#MachineRunningStatus.Machineid

Insert into #MachineRunningStatus(MachineID,MachineLiveStatus)
select Machineid,machinestatus from #Focas_MachineRunningStatus
---------------------------------- Added to handle Machine Status for Focas Machines ----------------------------------

update #machineRunningStatus set MachineLiveStatusColor=T.Colorcode from
(select Status,Colorcode from Focas_MachineColorcode
)T inner join #machineRunningStatus on T.Status=#machineRunningStatus.MachineLiveStatus

select MachineID,LastCompOpn,LastdataArrivalTime,LastDataArrivalTimeinMin,Remarks1 as LastArrivalStatus,ConnectionTimestamp,ConnectionStatus,PingTimestamp,PingStatus,PLCTimestamp,PLCStatus,
Case when (Remarks1 ='OK' and  ConnectionStatus='OK' and PingStatus='OK' and PLCStatus='OK') then 'OK' else 'NOT OK' end as MachineStatus,
ISNULL(MachineLiveStatus,'NoData') as MachineLiveStatus,ISNULL(MachineLiveStatusColor,'Black') as MachineLiveStatusColor
from #machineRunningStatus order by machineid

 
END
