/****** Object:  Procedure [dbo].[TPMTrakMobile_ViewShift&HourwiseSummary]    Committed by VersionSQL https://www.versionsql.com ******/

/**********************************************************************************
--[dbo].[FocasWeb_ViewShift&HourwiseSummary]  '','Allplants'F
--[dbo].[FocasWeb_ViewShift&HourwiseSummary]  '','AllShifts'
--[dbo].[FocasWeb_ViewShift&HourwiseSummary]  '','AllMachines'

--[dbo].[FocasWeb_ViewShift&HourwiseSummary]  '2016-08-10','SHIFTWISESUMMARY'
--[dbo].[FocasWeb_ViewShift&HourwiseSummary]  '2016-08-10','Hourwisecycles'
--[dbo].[FocasWeb_ViewShift&HourwiseSummary]  '2016-08-10','HOURWISETIMEINFO'
--[dbo].[FocasWeb_ViewShift&HourwiseSummary]  '2016-08-10','SHIFTWISESTOPPAGES'


[dbo].[TPMTrakMobile_ViewShift&HourwiseSummary]     '2021-03-15 07:01:00',''
**********************************************************************************/


CREATE PROCEDURE [dbo].[TPMTrakMobile_ViewShift&HourwiseSummary]  
	@Date datetime ='', 
	@Param nvarchar(50)=''

WITH RECOMPILE
AS
BEGIN

create table #finaldata
(
Date datetime,
PlantCode nvarchar(50),
PlantID nvarchar(50),
GroupID nvarchar(50),
MCInterface nvarchar(50),
MachineId nvarchar(50),
DisplayOrder int,
ShiftID int,
ShiftName nvarchar(50),
ColumnName nvarchar(50),
DisplayName nvarchar(50),
ColumnValue float,
DayValue float,
Navid nvarchar(50)
)

Create table #Machine
(
PlantCode nvarchar(50),
PlantID nvarchar(50),
MCInterface nvarchar(50),
MachineId nvarchar(50),
GroupID nvarchar(50),
RunningPart nvarchar(50),
Partscount float,
Stoppages float,
McStatus nvarchar(50),
Color nvarchar(50),
MachineMTB nvarchar(50),
LastRecord datetime,
Reason nvarchar(50),
AE NVARCHAR(50),
PE NVARCHAR(50),
QE NVARCHAR(50),
OEE NVARCHAR(50),
Frequency nvarchar(50)
)

create table #Runningpart_Part
(  
 Machineid nvarchar(50),  
 Componentid nvarchar(50),
 StTime Datetime 
)

CREATE TABLE #T_autodata(  
 [mc] [nvarchar](50)not NULL,  
 [comp] [nvarchar](50) NULL,  
 [opn] [nvarchar](50) NULL,  
 [opr] [nvarchar](50) NULL,  
 [dcode] [nvarchar](50) NULL,  
 [sttime] [datetime] not NULL,  
 [ndtime] [datetime] not NULL,  
 [datatype] [tinyint] NULL ,  
 [cycletime] [int] NULL,  
 [loadunload] [int] NULL ,  
 [msttime] [datetime] not NULL,  
 [PartsCount] decimal(18,5) NULL ,  
 id  bigint not null  
)  
  
ALTER TABLE #T_autodata  
  
ADD PRIMARY KEY CLUSTERED  
(  
 mc,sttime,ndtime,msttime ASC  
)ON [PRIMARY]  
  
Declare @T_ST AS Datetime   
Declare @T_ED AS Datetime   
declare @strsql as nvarchar(4000)
declare @CurrentTime as datetime
Select @CurrentTime = min(fromtime) from shiftdetails where running = 1 
select @CurrentTime = Dateadd(second,1,convert(datetime, convert(nvarchar(10),@date,120) + ' ' + CAST(datePart(hh,@CurrentTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,@CurrentTime) as nvarchar(2))+ ':' + CAST(datePart(ss,@CurrentTime) as nvarchar(2))))

Select @T_ST=dbo.f_GetLogicalDaystart(@CurrentTime) 
Select @T_ED=dbo.f_GetLogicalDayEND(@CurrentTime)
  
Select @strsql=''  
select @strsql ='insert into #T_autodata '  
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'  
 select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'  
select @strsql = @strsql + ' from autodata where (( sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_ED,120)+''' ) OR '  
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' )OR '  
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ST,120)+'''  
     and ndtime<='''+convert(nvarchar(25),@T_ED,120)+''' )'  
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' and sttime<'''+convert(nvarchar(25),@T_ED,120)+''' ) )'  
print @strsql  
exec (@strsql)  


--If @param='AllShifts'
--Begin
	Select Distinct S.ShiftID,S.ShiftName from Shiftdetails S
	Where S.Running=1
	Order by S.ShiftID
--End

--If @param='AllPlants'
--Begin
	Select Distinct P.PlantCode,P.Plantid from PlantInformation P 
	Order by P.PlantID
--End

--if @param='AllGroups'
--Begin
	select Distinct PIN.PlantCode,P.Plantid,PG.GroupID
	FROM PlantInformation PIN
	Inner join PlantMachine P on P.PlantID=PIN.Plantid
	left outer join PlantMachineGroups PG ON P.PlantID=PG.PlantID AND P.MachineID=PG.MachineID
	ORDER BY P.PlantID,PG.GroupID
--END

--If @param='AllMachines'
--Begin
	--Insert into #Machine(PlantCode,PlantID,GroupID,MCInterface,MachineId,RunningPart,Partscount,Stoppages,McStatus,MachineMTB)
	--Select PIN.PlantCode,P.PlantID,P1.GroupID,M.Interfaceid,M.Machineid,0,0,0,0,M.MachineMTB from PlantInformation PIN
	--Inner join PlantMachine P on P.PlantID=PIN.Plantid
	--Inner Join Machineinformation M on P.Machineid=M.Machineid
	--left outer join PlantMachineGroups P1 ON P1.MachineID=P.MachineID AND P1.PlantID=P.PlantID
	--where M.TPMTrakenabled=1
	--Order by PIN.PlantID,M.MachineID

	--Update #Machine Set Partscount = T1.Parts From 
	--(Select Date,PlantID,MachineID,SUM(Partcount) as Parts from FocasWeb_ShiftwiseSummary where Convert(Nvarchar(10),Date,120)=Convert(Nvarchar(10),@Date,120)
	--Group By Date,PlantID,MachineID)T1 
	--inner join #Machine on #Machine.PlantID=T1.PlantID AND #Machine.MachineID=T1.MachineID 

	--Update #Machine Set Stoppages = T1.Stoppages From 
	--(Select Date,PlantID,MachineID,SUM(Stoppages) as Stoppages from FocasWeb_ShiftwiseSummary where Convert(Nvarchar(10),Date,120)=Convert(Nvarchar(10),@Date,120)
	--Group By Date,PlantID,MachineID)T1 
	--inner join #Machine on #Machine.PlantID=T1.PlantID AND #Machine.MachineID=T1.MachineID 

--	Update #Machine Set RunningPart=T.Programno From 
--	(Select T1.Plantid,T1.Machineid,L.Programno from
--	(Select P.PlantID,P.MachineID,Max(Cnctimestamp) as CTS
--	 from Focas_livedata L Inner Join PlantMachine P on P.machineid=L.Machineid
--	inner join Machineinformation M on L.Machineid=M.Machineid and P.Machineid=M.Machineid
--	where Convert(Nvarchar(10),L.cnctimestamp,120)=Convert(Nvarchar(10),@date,120)
--	Group By P.PlantID,P.MachineID)T1 inner join Focas_livedata L on T1.machineid=L.Machineid and T1.CTS=L.cnctimestamp
--	)T inner join #Machine on #Machine.PlantID=T.PlantID AND #Machine.MachineID=T.MachineID 


--	Update #Machine Set McStatus = T1.McStatus,Color=T1.Color From 
--	(Select T.PlantID,T.MachineID,
--	 Case 
--	 when MachineStatus='In Cycle' then 'Running'
--	 when MachineStatus='Alarm' then 'Alarm'
--	 when MachineStatus='Emergency' then 'Alarm'
--	 when MachineStatus='Idle' then 'Stopped'
--	 when MachineStatus='Feed Hold' then 'Stopped'
--	 when MachineStatus='STOP' then 'Stopped'
--	 when MachineStatus='Unavailable' then 'Stopped'
--	 when MachineStatus=NULL then 'Stopped'
--	End as McStatus,
--	 Case 
--	 when MachineStatus='In Cycle' then 'Green'
--	 when MachineStatus='Alarm' then 'Red'
--	 when MachineStatus='Emergency' then 'Red'
--	 when MachineStatus='Idle' then 'Yellow'
--	 when MachineStatus='Feed Hold' then 'Yellow'
--	 when MachineStatus='STOP' then 'Yellow'
--	 when MachineStatus='Unavailable' then 'Yellow'
--	 when MachineStatus=NULL then 'Yellow'
--
--	End as Color from 
--	(Select P.plantid,M.Machineid,Max(cnctimestamp) as cts from	Focas_livedata L 
--	Inner Join PlantMachine P on P.machineid=L.Machineid
--	inner join Machineinformation M on L.Machineid=M.Machineid and P.Machineid=M.Machineid
--	where Convert(Nvarchar(10),L.cnctimestamp,120)=Convert(Nvarchar(10),@Date,120)
--	Group By P.PlantID,M.MachineID)T inner join Focas_livedata L on L.machineid=T.Machineid and L.cnctimestamp=T.cts)T1 inner join #Machine on #Machine.PlantID=T1.PlantID AND #Machine.MachineID=T1.MachineID 
--
--	Update #Machine Set McStatus = 'Stopped',Color='Yellow' where  McStatus='0'

	Insert into #Machine(PlantCode,PlantID,GroupID,MCInterface,MachineId,RunningPart,Partscount,Stoppages,McStatus,MachineMTB,AE,PE,QE,OEE,Frequency)
	SELECT PIN.PlantCode,F.PlantID,P1.GroupID,M.Interfaceid,F.Machineid,0,F.Partscount,F.DownTime,0,M.MachineMTB,F.AvailabilityEfficiency,F.ProductionEfficiency,F.QualityEfficiency,F.OverallEfficiency,F.Frequency from 
	FocasWeb_FrequencyWiseData F inner join PlantInformation PIN on F.PlantID=PIN.PlantID
	Inner Join Machineinformation M on  F.Machineid=M.Machineid
	Inner join PlantMachine P on P.PlantID=PIN.Plantid AND P.MachineID=M.MachineID
	left outer join PlantMachineGroups P1 ON P1.MachineID=P.MachineID AND P1.PlantID=P.PlantID
	where M.TPMTrakenabled=1 and convert(nvarchar(10),F.Date,120) = Convert(Nvarchar(10),@Date,120)

	insert into #Runningpart_Part(Machineid,Componentid,StTime)  
	select Machineinformation.machineid,C.Componentid,Max(A.StTime) as Sttime from #T_autodata A  
	inner join Machineinformation on A.mc=Machineinformation.interfaceid  
	inner join Componentinformation C on A.comp=C.interfaceid  
	inner join Componentoperationpricing CO on A.opn=CO.interfaceid  
	and Machineinformation.Machineid=CO.Machineid and C.Componentid=CO.Componentid  	
	where sttime>=dbo.f_GetLogicalDaystart(@CurrentTime) and ndtime<=dbo.f_GetLogicalDayEND(@CurrentTime)
	group by Machineinformation.Machineid,C.Componentid Order by Machineinformation.machineid

	Update #Machine Set RunningPart=T.Comp From  
	(select R1.componentid as Comp,isnull(R.machineid ,'') as machineid from 
		(select machineid,max(sttime) as start from #Runningpart_Part group by machineid)R
	 inner join #Runningpart_Part R1 on R.machineid=R1.machineid and R.start=R1.sttime
	)T inner join #Machine on #Machine.MachineID=T.MachineID 


	CREATE TABLE #MachineRunningStatus
	(
		MachineID NvarChar(50),
		MachineInterface nvarchar(50),
		sttime Datetime,
		ndtime Datetime,
		DataType smallint,
		ColorCode varchar(10)
	)

	Declare @CurrTime as DateTime
	SET @CurrTime = convert(nvarchar(20),getdate(),120)
	print @CurrTime

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

	--Insert into #machineRunningStatus
	--select fd.MachineID,fd.interfaceid,sttime,ndtime,datatype,'White' from rawdata
	--inner join (select mc,max(slno) as slno from rawdata WITH (NOLOCK) where sttime<@currtime and isnull(ndtime,'1900-01-01')<@currtime
	--and datatype in(2,42,40,41,1,11) and datepart(year,sttime)>'2000' group by mc ) t1 on t1.mc=rawdata.mc and t1.slno=rawdata.slno --For SAF DR0370
	--right outer join Machineinformation fd on fd.interfaceid = rawdata.mc
	--order by rawdata.mc

	Insert into #machineRunningStatus(MachineID,MachineInterface,sttime,ndtime,DataType,ColorCode)   
	select fd.MachineID,fd.InterfaceID,sttime,ndtime,datatype,ColorCode from MachineRunningStatus mr    
	right outer join Machineinformation fd on fd.InterfaceID = mr.MachineInterface
	where sttime<@currtime and isnull(ndtime,'1900-01-01')<@currtime
	order by fd.InterfaceID

	update #machineRunningStatus set ColorCode = case when (datediff(second,sttime,@CurrTime)- @Type11Threshold)>0  then 'Red' else 'Green' end where datatype in (11)
	update #machineRunningStatus set ColorCode = 'Green' where datatype in (41)
	update #machineRunningStatus set ColorCode = 'Red' where datatype in (42,2,22)

	update #machineRunningStatus set ColorCode = t1.ColorCode from (
	Select mrs.MachineID,Case when (
	case when datatype = 40 then datediff(second,sttime,@CurrTime)- @Type40Threshold
	when datatype = 1 then datediff(second,ndtime,@CurrTime)- @Type1Threshold
	end) > 0 then 'Red' else 'Green' end as ColorCode
	from #machineRunningStatus mrs 
	where  datatype in (40,1)
	) as t1 inner join #machineRunningStatus on t1.MachineID = #machineRunningStatus.MachineID

	update #machineRunningStatus set ColorCode ='Red' where isnull(sttime,'1900-01-01')='1900-01-01'

	Update #Machine Set McStatus = T1.McStatus,Color=T1.Colorcode  from 
	(select Machineid,Colorcode,
	Case when Colorcode='White' then 'Stopped'
	when Colorcode='Red' then 'Stopped'
	when Colorcode='Green' then 'Running' end as MCStatus from #machineRunningStatus)T1
	inner join #Machine on T1.MachineID = #Machine.MachineID

	Update #Machine Set LastRecord=T1.lastrecord from
	(Select mrs.MachineID,Case 
	when datatype in(11,40,41) then sttime
	when datatype in(1,2,42,22) then ndtime
	end as Lastrecord from #machineRunningStatus mrs)T1
	inner join #Machine on T1.MachineID = #Machine.MachineID

	Update #Machine Set Reason=T1.DownStatus From
	(select mrs.MachineID,
	Case when mrs.datatype in(11,41) then 'Cycle Started'
	When mrs.datatype=1 then 'Cycle Ended'
	When mrs.datatype in(22,42) then  'Stopped ' + D.Downid 
	When mrs.datatype in(2,40) then 'Stopped' 
	END as DownStatus from #machineRunningStatus mrs
	inner join RawData on RawData.mc=mrs.MachineInterface and RawData.Sttime=mrs.sttime
	Left Outer join Downcodeinformation D on RawData.splstring2=D.interfaceid
	) T1 inner join #Machine on T1.MachineID = #Machine.MachineID

	Select PlantCode,PlantID,GroupID,MCInterface,MachineId,RunningPart,Round(Partscount,3) as Partscount,Stoppages as Downtime_Sec,dbo.f_FormatTime(Stoppages,'hh:mm:ss') as Stoppages,McStatus,color,MachineMTB,LastRecord,Reason,ISNULL(ROUND(AE,2),0) as AvailabilityEfficiency,ISNULL(ROUND(PE,2),0) as ProductionEfficiency,ISNULL(ROUND(QE,2),0) as QualityEfficiency,ISNULL(ROUND(OEE,2),0) as OverallEfficiency,Frequency from #Machine
	order by Frequency,PlantID,GroupID,MachineId
--End

--IF @Param = 'SHIFTWISESUMMARY'
--BEGIN

insert into #finaldata(Date,PlantCode,PlantID,GroupID,MCInterface,MachineID,DisplayOrder,ShiftID,ShiftName,ColumnName,DisplayName,Navid)
select F.Date,PIN.PlantCode,F.plantID,P1.GroupID,M.Interfaceid,F.MachineID,C.Sortorder,F.ShiftID,F.Shift,C.Rowheader,C.DisplayName,C.Navid from FocasWeb_ShiftwiseSummary F
inner join PlantInformation PIN on F.PlantID=PIN.PlantID
Inner join PlantMachine P on P.PlantID=PIN.Plantid
Inner Join Machineinformation M on P.Machineid=M.Machineid and F.Machineid=M.Machineid
left outer join PlantMachineGroups P1 ON P1.MachineID=P.MachineID AND P1.PlantID=P.PlantID
Cross Join FocasWeb_RowHeader C  
where M.TPMTrakenabled=1 and Convert(Nvarchar(10),F.Date,120)=Convert(Nvarchar(10),@Date,120) order By C.Sortorder,F.ShiftID

Update #finaldata Set ColumnValue = T1.TotalTime From 
(Select Date,PlantID,MachineID,Shift,TotalTime from FocasWeb_ShiftwiseSummary where Convert(Nvarchar(10),Date,120)=Convert(Nvarchar(10),@Date,120))T1 
inner join #finaldata on #finaldata.Date=T1.Date AND #finaldata.PlantID=T1.PlantID AND #finaldata.MachineID=T1.MachineID AND #finaldata.Shiftname=T1.Shift and #finaldata.ColumnName='Totaltime'


Update #finaldata Set ColumnValue = T1.Powerontime From 
(Select Date,PlantID,MachineID,Shift,Powerontime from FocasWeb_ShiftwiseSummary where Convert(Nvarchar(10),Date,120)=Convert(Nvarchar(10),@Date,120))T1 
inner join #finaldata on #finaldata.Date=T1.Date AND #finaldata.PlantID=T1.PlantID AND #finaldata.MachineID=T1.MachineID AND #finaldata.Shiftname=T1.Shift and #finaldata.ColumnName='Powerontime'

Update #finaldata Set ColumnValue = T1.OperatingTime From 
(Select Date,PlantID,MachineID,Shift,OperatingTime from FocasWeb_ShiftwiseSummary where Convert(Nvarchar(10),Date,120)=Convert(Nvarchar(10),@Date,120))T1 
inner join #finaldata on #finaldata.Date=T1.Date AND #finaldata.PlantID=T1.PlantID AND #finaldata.MachineID=T1.MachineID AND #finaldata.Shiftname=T1.Shift and #finaldata.ColumnName='Operatingtime'

Update #finaldata Set ColumnValue = T1.Cuttingtime From 
(Select Date,PlantID,MachineID,Shift,Cuttingtime from FocasWeb_ShiftwiseSummary where Convert(Nvarchar(10),Date,120)=Convert(Nvarchar(10),@Date,120))T1 
inner join #finaldata on #finaldata.Date=T1.Date AND #finaldata.PlantID=T1.PlantID AND #finaldata.MachineID=T1.MachineID AND #finaldata.Shiftname=T1.Shift and #finaldata.ColumnName='Cuttingtime'

Update #finaldata Set ColumnValue = T1.Stoppages From 
(Select Date,PlantID,MachineID,Shift,Stoppages from FocasWeb_ShiftwiseSummary where Convert(Nvarchar(10),Date,120)=Convert(Nvarchar(10),@Date,120))T1 
inner join #finaldata on #finaldata.Date=T1.Date AND #finaldata.PlantID=T1.PlantID AND #finaldata.MachineID=T1.MachineID AND #finaldata.Shiftname=T1.Shift and #finaldata.ColumnName='Stoppagetime'

Update #finaldata Set ColumnValue = T1.Partcount From 
(Select Date,PlantID,MachineID,Shift,round(Partcount,3) as Partcount from FocasWeb_ShiftwiseSummary where Convert(Nvarchar(10),Date,120)=Convert(Nvarchar(10),@Date,120))T1 
inner join #finaldata on #finaldata.Date=T1.Date AND #finaldata.PlantID=T1.PlantID AND #finaldata.MachineID=T1.MachineID AND #finaldata.Shiftname=T1.Shift and #finaldata.ColumnName='cycles'

Update #finaldata Set ColumnValue = T1.RejCount From 
(Select Date,PlantID,MachineID,Shift,RejCount from FocasWeb_ShiftwiseSummary where Convert(Nvarchar(10),Date,120)=Convert(Nvarchar(10),@Date,120))T1 
inner join #finaldata on #finaldata.Date=T1.Date AND #finaldata.PlantID=T1.PlantID AND #finaldata.MachineID=T1.MachineID AND #finaldata.Shiftname=T1.Shift and #finaldata.ColumnName='RejCount'

Update #finaldata Set ColumnValue = T1.QualityEfficiency From 
(Select Date,PlantID,MachineID,Shift,QualityEfficiency from FocasWeb_ShiftwiseSummary where Convert(Nvarchar(10),Date,120)=Convert(Nvarchar(10),@Date,120))T1 
inner join #finaldata on #finaldata.Date=T1.Date AND #finaldata.PlantID=T1.PlantID AND #finaldata.MachineID=T1.MachineID AND #finaldata.Shiftname=T1.Shift and #finaldata.ColumnName='QualityEfficiency'




Update #finaldata Set Dayvalue = T1.Stoppages From 
(Select Date,PlantID,MachineID,SUM(ColumnValue) as  Stoppages from #finaldata where #finaldata.ColumnName='Stoppagetime'
Group By Date,PlantID,MachineID)T1 
inner join #finaldata on #finaldata.Date=T1.Date AND #finaldata.PlantID=T1.PlantID AND #finaldata.MachineID=T1.MachineID and #finaldata.ColumnName='Stoppagetime'

Update #finaldata Set Dayvalue = T1.Parts From 
(Select Date,PlantID,MachineID,round(SUM(ColumnValue),3) as  Parts from #finaldata where #finaldata.ColumnName='cycles'
Group By Date,PlantID,MachineID)T1 
inner join #finaldata on #finaldata.Date=T1.Date AND #finaldata.PlantID=T1.PlantID AND #finaldata.MachineID=T1.MachineID  and #finaldata.ColumnName='cycles'

Update #finaldata Set Dayvalue = T1.Cuttingtime From 
(Select Date,PlantID,MachineID,ROUND(AVG(ColumnValue),0) as  Cuttingtime from #finaldata where #finaldata.ColumnName='Cuttingtime'
Group By Date,PlantID,MachineID)T1 
inner join #finaldata on #finaldata.Date=T1.Date AND #finaldata.PlantID=T1.PlantID AND #finaldata.MachineID=T1.MachineID  and #finaldata.ColumnName='Cuttingtime'

Update #finaldata Set Dayvalue = T1.Operatingtime From 
(Select Date,PlantID,MachineID,RounD(AVG(ColumnValue),0) as  Operatingtime from #finaldata where #finaldata.ColumnName='Operatingtime'
Group By Date,PlantID,MachineID)T1 
inner join #finaldata on #finaldata.Date=T1.Date AND #finaldata.PlantID=T1.PlantID AND #finaldata.MachineID=T1.MachineID and #finaldata.ColumnName='Operatingtime'

Update #finaldata Set Dayvalue = T1.Powerontime From 
(Select Date,PlantID,MachineID,ROUND(AVG(ColumnValue),0) as  Powerontime from #finaldata where #finaldata.ColumnName='Powerontime'
Group By Date,PlantID,MachineID)T1 
inner join #finaldata on #finaldata.Date=T1.Date AND #finaldata.PlantID=T1.PlantID AND #finaldata.MachineID=T1.MachineID and  #finaldata.ColumnName='Powerontime'

Update #finaldata Set Dayvalue = T1.Totaltime From 
(Select Date,PlantID,MachineID,SUM(ColumnValue) as  Totaltime from #finaldata where #finaldata.ColumnName='Totaltime'
Group By Date,PlantID,MachineID)T1 
inner join #finaldata on #finaldata.Date=T1.Date AND #finaldata.PlantID=T1.PlantID AND #finaldata.MachineID=T1.MachineID AND #finaldata.ColumnName='Totaltime'

Update #finaldata Set Dayvalue = T1.RejCount From 
(Select Date,PlantID,MachineID,SUM(ColumnValue) as  RejCount from #finaldata where #finaldata.ColumnName='RejCount'
Group By Date,PlantID,MachineID)T1 
inner join #finaldata on #finaldata.Date=T1.Date AND #finaldata.PlantID=T1.PlantID AND #finaldata.MachineID=T1.MachineID AND #finaldata.ColumnName='RejCount'

Update #finaldata Set Dayvalue = T1.QualityEfficiency From 
(Select Date,PlantID,MachineID,ROUND(AVG(ColumnValue),0) as  QualityEfficiency from #finaldata where #finaldata.ColumnName='QualityEfficiency'
Group By Date,PlantID,MachineID)T1 
inner join #finaldata on #finaldata.Date=T1.Date AND #finaldata.PlantID=T1.PlantID AND #finaldata.MachineID=T1.MachineID and  #finaldata.ColumnName='QualityEfficiency'



CREATE TABLE #t
(
PlantCode nvarchar(50),
PlantID nvarchar(50),
GroupID nvarchar(50),
MCInterface nvarchar(50),
MachineId nvarchar(50),
DisplayName nvarchar(50),
DisplayOrder int,
Navid nvarchar(50),
ColumnName1 nvarchar(50),
ColumnName2 nvarchar(50),
ColumnName3 nvarchar(50),
DayValue nvarchar(50)
)


declare @countofshift as int
select @countofshift=count(*) from Shiftdetails where running=1

INSERT INTO #t(PlantCode,PlantID,GroupID,MCInterface,Machineid,DisplayName,DisplayOrder,NavID,dayvalue,Columnname1)
SELECT PlantCode,PlantID,GroupID,MCInterface,Machineid,DisplayName,DisplayOrder,NavID,case when Columnname not in ('cycles','Powerontime','Operatingtime','Cuttingtime','RejCount','QualityEfficiency') then dbo.f_FormatTime(DayValue,'hh:mm') else cast(DayValue as nvarchar(50)) end
,case when Columnname not in ('cycles','Powerontime','Operatingtime','Cuttingtime','RejCount','QualityEfficiency') then dbo.f_FormatTime(SUM(ColumnValue),'hh:mm') else cast(SUM(ColumnValue) as nvarchar(50)) end  from #finaldata 
where shiftname=(select distinct shiftname from #finaldata where shiftid=1)
group by PlantCode,PlantID,GroupID,MCInterface,Machineid,DisplayName,DisplayOrder,NavID,Columnname,DayValue
order by PlantID,Machineid,DisplayOrder

UPDATE #t SET Columnname2=t.Columnname2 FROM
(SELECT PlantCode,PlantID,MCInterface,Machineid,DisplayName,DisplayOrder,NavID,case when Columnname not in ('cycles','Powerontime','Operatingtime','Cuttingtime','RejCount','QualityEfficiency') then dbo.f_FormatTime(SUM(ColumnValue),'hh:mm') else cast(SUM(ColumnValue) as nvarchar(50)) end as Columnname2 from #finaldata  
where shiftname=(select distinct shiftname from #finaldata where shiftid=2)
group by PlantCode,PlantID,MCInterface,Machineid,DisplayName,DisplayOrder,NavID,Columnname)T
INNER JOIN #T ON #T.MCInterface=T.MCInterface AND #T.DisplayName=t.DisplayName

declare @NameofShift as nvarchar(20)
select @NameofShift=''
SELECT @NameofShift = Shiftname from shiftdetails where Shiftid=1 and running=1
EXEC tempdb.sys.sp_rename N'[tempdb].[dbo].[#T].Columnname1', 
@NameofShift, N'COLUMN';

select @NameofShift=''
SELECT @NameofShift = Shiftname from shiftdetails where Shiftid=2 and running=1
EXEC tempdb.sys.sp_rename N'[tempdb].[dbo].[#T].Columnname2', 
@NameofShift, N'COLUMN';

If @countofshift=3
Begin
	UPDATE #t SET Columnname3=t.Columnname3 FROM
	(SELECT PlantCode,PlantID,MCInterface,Machineid,DisplayName,DisplayOrder,NavID,case when Columnname not in ('cycles','Powerontime','Operatingtime','Cuttingtime','RejCount','QualityEfficiency') then dbo.f_FormatTime(SUM(ColumnValue),'hh:mm') else cast(SUM(ColumnValue) as nvarchar(50)) end AS Columnname3 from #finaldata  
	where shiftname=(select distinct shiftname from #finaldata where shiftid=3)
	group by PlantCode,PlantID,MCInterface,Machineid,DisplayName,DisplayOrder,NavID,Columnname)T
	INNER JOIN #T ON #T.MCInterface=T.MCInterface AND #T.DisplayName=t.DisplayName

	select @NameofShift=''
	SELECT @NameofShift = Shiftname from shiftdetails where Shiftid=3 and running=1
	EXEC tempdb.sys.sp_rename N'[tempdb].[dbo].[#T].Columnname3', 
	@NameofShift, N'COLUMN';

End


SELECT * FROM #T order by PlantID,Machineid,GroupID,DisplayOrder





--DECLARE @cols AS NVARCHAR(MAX),@query  AS NVARCHAR(MAX),@MachineList as NVARCHAR(MAX)
--
--
--select @cols = STUFF((SELECT distinct ',' + QUOTENAME(Shiftname) 
--					from #finaldata
--                   
--			FOR XML PATH(''), TYPE
--			).value('.', 'NVARCHAR(MAX)') 
--		,1,1,'')
--

--set @query = 'SELECT PlantCode,PlantID,MCInterface,Machineid,DisplayName,DisplayOrder,NavID,case when Columnname<>''cycles'' then dbo.f_FormatTime(SUM([A]),''hh:mm'') else cast(SUM([A]) as nvarchar(50)) end as A,
--			 case when Columnname<>''cycles'' then dbo.f_FormatTime(SUM([B]),''hh:mm'') else cast(SUM([B]) as nvarchar(50)) end as B, 
--			 case when Columnname<>''cycles'' then dbo.f_FormatTime(SUM([C]),''hh:mm'') else cast(SUM([C]) as nvarchar(50)) end as C,
--			 case when Columnname<>''cycles'' then dbo.f_FormatTime(DayValue,''hh:mm'') else cast(DayValue as nvarchar(50)) end as DayValue  from 
--			 (
--				select PlantCode,PlantID,MCInterface,Machineid,DisplayOrder,DisplayName,Columnname,ColumnValue,Shiftname,ShiftId,
--				DayValue,NavID
--				from #finaldata 
--			) x
--			pivot 
--			(
--				SUM(ColumnValue)
--				for Shiftname in ([A],[B],[C])
--			) p1 group by PlantCode,PlantID,MCInterface,Machineid,displayname,Columnname,DisplayOrder,DayValue,NavID order by PlantID,Machineid,DisplayOrder
--			'
--
--execute(@query);
--END

----IF @PARAM = 'HOURWISECYCLES'
----BEGIN
--	Select PIN.PlantCode,F.PlantID, M.Interfaceid AS MCInterface,F.MachineID, F.Shiftid , F.Shift, F.HourID,F.HourStart, F.HourEnd, F.ProgramID + ' [' + F.Programblock +']' as ProgramID, Round(F.PartCount,3) as PartCount FROM FocasWeb_HourwiseCycles F
--	inner join PlantInformation PIN on F.PlantID=PIN.PlantID
--	Inner join PlantMachine P on P.PlantID=PIN.Plantid
--	Inner Join Machineinformation M on P.Machineid=M.Machineid and F.Machineid=M.Machineid
--	where M.TPMTrakenabled=1 and Convert(Nvarchar(10),Date,120)=Convert(Nvarchar(10),@Date,120) order By F.PlantID,F.MachineID,F.ShiftID,F.HourID
----END

--IF @PARAM = 'HOURWISECYCLES'
--BEGIN
	Select PIN.PlantCode,F.PlantID, M.Interfaceid AS MCInterface,F.MachineID,P1.GroupID,F.Shiftid , F.Shift, F.HourID,F.HourStart, F.HourEnd, F.ProgramID + ' [' + F.Programblock +']' as ProgramID, Round(F.PartCount,3) as PartCount FROM FocasWeb_HourwiseCycles F
	inner join PlantInformation PIN on F.PlantID=PIN.PlantID
	Inner Join Machineinformation M on  F.Machineid=M.Machineid
	Inner join PlantMachine P on P.PlantID=PIN.Plantid AND P.machineid=M.machineid
	left outer join PlantMachineGroups P1 ON P1.MachineID=P.MachineID AND P1.PlantID=P.PlantID
	where M.TPMTrakenabled=1 and Convert(Nvarchar(10),Date,120)=Convert(Nvarchar(10),@Date,120) order By F.PlantID,F.MachineID,F.ShiftID,F.HourID
--END

----IF @PARAM = 'HOURWISETIMEINFO'
----BEGIN

--	Select Convert(Nvarchar(10),F.Date,120) as Tdate,F.PlantID,F.MachineID, F.ShiftID, F.Shift,SUM(F.PowerOntime) as TotalPOT,
--	SUM(F.OperatingTime) as TotalOT,SUM(F.CuttingTime) as TotalCT Into #Times_Summary from FocasWeb_HourwiseTimeInfo F
--	Group by F.Date,F.PlantID,F.MachineID, F.ShiftID, F.Shift

--	SELECT PIN.PlantCode,F.PlantID,M.Interfaceid AS MCInterface,F.MachineID, F.ShiftID, F.Shift, F.HourID, F.HourStart, F.HourEnd, 
--	dbo.f_FormatTime(F.PowerOntime,'hh:mm') as PowerOntime, dbo.f_FormatTime(F.OperatingTime,'hh:mm') as OperatingTime,
--	dbo.f_FormatTime(F.CuttingTime,'hh:mm') as CuttingTime,round(F.PowerOntime/60,0) as PowerOntimeint,Round(F.OperatingTime/60,0) as Operatingtimeint,
--	Round(F.CuttingTime/60,0) AS Cuttingtimeint,dbo.f_FormatTime(T.TotalPOT,'hh:mm') as TotalPOT, dbo.f_FormatTime(T.TotalOT,'hh:mm') as TotalOT,
--	dbo.f_FormatTime(T.TotalCT,'hh:mm') as TotalCT
--	FROM FocasWeb_HourwiseTimeInfo F 
--	inner join PlantInformation PIN on F.PlantID=PIN.PlantID
--	Inner join PlantMachine P on P.PlantID=PIN.Plantid
--	Inner Join Machineinformation M on P.Machineid=M.Machineid and F.Machineid=M.Machineid
--	left outer join #Times_Summary T on Convert(Nvarchar(10),F.Date,120)=Convert(Nvarchar(10),T.TDate,120) and T.Plantid=F.Plantid and T.Machineid=F.Machineid and T.Shift=F.Shift
--	where M.TPMTrakenabled=1 and Convert(Nvarchar(10),Date,120)=Convert(Nvarchar(10),@Date,120) order By PlantID, MachineID, ShiftID , HourID

----END

--IF @PARAM = 'HOURWISETIMEINFO'
--BEGIN

	Select Convert(Nvarchar(10),F.Date,120) as Tdate,F.PlantID,F.MachineID,P1.GroupID,F.ShiftID, F.Shift,SUM(F.PowerOntime) as TotalPOT,
	SUM(F.OperatingTime) as TotalOT,SUM(F.CuttingTime) as TotalCT Into #Times_Summary from FocasWeb_HourwiseTimeInfo F
	inner join PlantInformation PIN on F.PlantID=PIN.PlantID
	Inner Join Machineinformation M on  F.Machineid=M.Machineid
	Inner join PlantMachine P on P.PlantID=PIN.Plantid AND P.machineid=M.machineid
	left outer join PlantMachineGroups P1 ON P1.MachineID=P.MachineID AND P1.PlantID=P.PlantID
	Group by F.Date,F.PlantID,F.MachineID, F.ShiftID, F.Shift,P1.GroupID

	SELECT PIN.PlantCode,F.PlantID,M.Interfaceid AS MCInterface,P1.GroupID,F.MachineID, F.ShiftID, F.Shift, F.HourID, F.HourStart, F.HourEnd, 
	dbo.f_FormatTime(F.PowerOntime,'hh:mm') as PowerOntime, dbo.f_FormatTime(F.OperatingTime,'hh:mm') as OperatingTime,
	dbo.f_FormatTime(F.CuttingTime,'hh:mm') as CuttingTime,round(F.PowerOntime/60,0) as PowerOntimeint,Round(F.OperatingTime/60,0) as Operatingtimeint,
	Round(F.CuttingTime/60,0) AS Cuttingtimeint,dbo.f_FormatTime(T.TotalPOT,'hh:mm') as TotalPOT, dbo.f_FormatTime(T.TotalOT,'hh:mm') as TotalOT,
	dbo.f_FormatTime(T.TotalCT,'hh:mm') as TotalCT
	FROM FocasWeb_HourwiseTimeInfo F 
	inner join PlantInformation PIN on F.PlantID=PIN.PlantID
	Inner Join Machineinformation M on  F.Machineid=M.Machineid
	Inner join PlantMachine P on P.PlantID=PIN.Plantid AND P.machineid=M.machineid
	left outer join PlantMachineGroups P1 ON P1.MachineID=P.MachineID AND P1.PlantID=P.PlantID
	left outer join #Times_Summary T on Convert(Nvarchar(10),F.Date,120)=Convert(Nvarchar(10),T.TDate,120) and T.Plantid=F.Plantid and T.Machineid=F.Machineid and T.Shift=F.Shift
	where M.TPMTrakenabled=1 and Convert(Nvarchar(10),Date,120)=Convert(Nvarchar(10),@Date,120) order By PlantID, MachineID, ShiftID , HourID

--END

----IF @PARAM = 'SHIFTWISESTOPPAGES'
----BEGIN

--	SELECT PIN.PlantCode,F.PlantID, M.Interfaceid AS MCInterface,F.MachineID,F.ShiftID, F.Shift, F.Batchstart, F.BatchEnd,
--    dbo.f_FormatTime(F.StoppageTime,'hh:mm')as StoppageTime, F.Reason
--	FROM  FocasWeb_ShiftwiseStoppages F
--	inner join PlantInformation PIN on F.PlantID=PIN.PlantID
--	Inner join PlantMachine P on P.PlantID=PIN.Plantid
--	Inner Join Machineinformation M on P.Machineid=M.Machineid and F.Machineid=M.Machineid
--	where M.TPMTrakenabled=1 and Convert(Nvarchar(10),Date,120)=Convert(Nvarchar(10),@Date,120) order By F.PlantID, F.MachineID,F.ShiftID,F.Batchstart

----END

--IF @PARAM = 'SHIFTWISESTOPPAGES'
--BEGIN

	SELECT PIN.PlantCode,F.PlantID, M.Interfaceid AS MCInterface,P1.GroupID,F.MachineID,F.ShiftID, F.Shift, F.Batchstart, F.BatchEnd,
    dbo.f_FormatTime(F.StoppageTime,'hh:mm')as StoppageTime, F.Reason
	FROM  FocasWeb_ShiftwiseStoppages F
	inner join PlantInformation PIN on F.PlantID=PIN.PlantID
	Inner Join Machineinformation M on  F.Machineid=M.Machineid
	Inner join PlantMachine P on P.PlantID=PIN.Plantid AND P.machineid=M.machineid
	left outer join PlantMachineGroups P1 ON P1.MachineID=P.MachineID AND P1.PlantID=P.PlantID
	where M.TPMTrakenabled=1 and Convert(Nvarchar(10),Date,120)=Convert(Nvarchar(10),@Date,120) order By F.PlantID, F.MachineID,F.ShiftID,F.Batchstart

--END

	--select PlantID,MachineID,Date,ShiftID,[Shift],DownID,DownReason,dbo.f_FormatTime(DownTime,'hh:mm')as DownTime, DownFreq FROM FocasWeb_downfreq
	--WHERE Convert(Nvarchar(10),Date,120)=Convert(Nvarchar(10),@Date,120) order By PlantID, MachineID,ShiftID,DownID

	select F.PlantID,F.MachineID,P1.GroupID,F.Date,F.ShiftID,F.[Shift],F.DownID,F.DownReason,dbo.f_FormatTime(F.DownTime,'hh:mm')as DownTime, F.DownFreq FROM FocasWeb_downfreq F
	inner join PlantInformation PIN on F.PlantID=PIN.PlantID
	Inner Join Machineinformation M on  F.Machineid=M.Machineid
	Inner join PlantMachine P on P.PlantID=PIN.Plantid AND P.MachineID=M.MachineID
	left outer join PlantMachineGroups P1 ON P1.MachineID=P.MachineID AND P1.PlantID=P.PlantID
	WHERE Convert(Nvarchar(10),Date,120)=Convert(Nvarchar(10),@Date,120) order By F.PlantID, F.MachineID,F.ShiftID,F.DownID


	--SELECT Plantid,Machineid,Date,ShiftID,Shift,component,operationNo,dbo.f_FormatTime(StdCycleTime,'hh:mm') as StdCycleTime ,dbo.f_FormatTime(AvgCycleTime,'hh:mm') as AvgCycleTime,
	--dbo.f_FormatTime(MinCycleTime,'hh:mm') as MinCycleTime,dbo.f_FormatTime(MaxCycleTime,'hh:mm') as MaxCycleTime,dbo.f_FormatTime(StdLoadUnload,'hh:mm') as StdLoadUnload,
	--dbo.f_FormatTime(AvgLoadUnload,'hh:mm')  as AvgLoadUnload,dbo.f_FormatTime(MinLoadUnload,'hh:mm') as MinLoadUnload,dbo.f_FormatTime(MaxLoadUnload,'hh:mm') as MaxLoadUnload
	--FROM FocasWeb_Statistics WHERE Convert(Nvarchar(10),Date,120)=Convert(Nvarchar(10),@Date,120) order By PlantID, MachineID,ShiftID,component

	SELECT F.Plantid,F.Machineid,P1.GroupID,F.Date,F.ShiftID,F.Shift,F.component,F.operationNo,dbo.f_FormatTime(StdCycleTime,'hh:mm') as StdCycleTime ,dbo.f_FormatTime(AvgCycleTime,'hh:mm') as AvgCycleTime,
	dbo.f_FormatTime(MinCycleTime,'hh:mm') as MinCycleTime,dbo.f_FormatTime(MaxCycleTime,'hh:mm') as MaxCycleTime,dbo.f_FormatTime(StdLoadUnload,'hh:mm') as StdLoadUnload,
	dbo.f_FormatTime(AvgLoadUnload,'hh:mm')  as AvgLoadUnload,dbo.f_FormatTime(MinLoadUnload,'hh:mm') as MinLoadUnload,dbo.f_FormatTime(MaxLoadUnload,'hh:mm') as MaxLoadUnload
	FROM FocasWeb_Statistics F
	inner join PlantInformation PIN on F.PlantID=PIN.PlantID
	Inner Join Machineinformation M on  F.Machineid=M.Machineid
	Inner join PlantMachine P on P.PlantID=PIN.Plantid AND P.MachineID=M.MachineID
	left outer join PlantMachineGroups P1 ON P1.MachineID=P.MachineID AND P1.PlantID=P.PlantID
	WHERE Convert(Nvarchar(10),Date,120)=Convert(Nvarchar(10),@Date,120) order By F.PlantID, F.MachineID,F.ShiftID,component

	--	SELECT PlantID, MachineID,MachineInterface, Date , ShiftID, Shift, Shiftstart as StartTime ,Shiftend,AvailabilityEfficiency,ProductionEfficiency, OverallEfficiency, QualityEfficiency,
	--cast(Components as decimal(18,3)) as Components,RejCount,
	--dbo.f_FormatTime(TotalTime,'hh:mm:ss') as TotalTime,
	--dbo.f_FormatTime(UtilisedTime,'hh:mm:ss') as NetUtilisedtime,
	--dbo.f_FormatTime(Downtime,'hh:mm:ss') as Downtime, dbo.f_FormatTime( NetDowntime,'hh:mm:ss') as NetDowntime,
	--dbo.f_FormatTime( ManagementLoss,'hh:mm:ss') as NetManagementLoss,MaxDownReason as MaxReasonTime,Lastcycletime,
	--LastCycleCO, LastCycleStart, dbo.f_FormatTime(RunningCycleUT,'hh:mm:ss') as RunningCycleUT,
	--dbo.f_FormatTime(LastCycleSpindleRunTime,'hh:mm:ss') as LastCycleSpindleRunTime, dbo.f_FormatTime(RunningCycleDT,'hh:mm:ss') as  RunningCycleDT,
	--RunningCycleAE,MachineStatus,PEGreen, PERed, AEGreen, AERed, OEGreen, OERed,QERed,QEGreen
	--FROM FocasWeb_ShiftwiseCockpit WHERE Convert(Nvarchar(10),Date,120)=Convert(Nvarchar(10),@Date,120) order By PlantID, MachineID,ShiftID 

	SELECT F.PlantID, F.MachineID,F.MachineInterface,P1.GroupID,F.Date , F.ShiftID, F.Shift, F.Shiftstart as StartTime ,F.Shiftend,F.AvailabilityEfficiency,F.ProductionEfficiency, F.OverallEfficiency, F.QualityEfficiency,
	cast(Components as decimal(18,3)) as Components,Operator as OperatorName, RejCount,
	dbo.f_FormatTime(TotalTime,'hh:mm:ss') as TotalTime,
	dbo.f_FormatTime(UtilisedTime,'hh:mm:ss') as NetUtilisedtime,
	dbo.f_FormatTime(Downtime,'hh:mm:ss') as Downtime, dbo.f_FormatTime( NetDowntime,'hh:mm:ss') as NetDowntime,
	dbo.f_FormatTime( ManagementLoss,'hh:mm:ss') as NetManagementLoss,MaxDownReason as MaxReasonTime,Lastcycletime,
	LastCycleCO, LastCycleStart, dbo.f_FormatTime(RunningCycleUT,'hh:mm:ss') as RunningCycleUT,
	dbo.f_FormatTime(LastCycleSpindleRunTime,'hh:mm:ss') as LastCycleSpindleRunTime, dbo.f_FormatTime(RunningCycleDT,'hh:mm:ss') as  RunningCycleDT,
	RunningCycleAE,MachineStatus,F.PEGreen, F.PERed, F.AEGreen, F.AERed, F.OEGreen, F.OERed,F.QERed,F.QEGreen
	FROM FocasWeb_ShiftwiseCockpit F
	inner join PlantInformation PIN on F.PlantID=PIN.PlantID
	Inner Join Machineinformation M on  F.Machineid=M.Machineid
	Inner join PlantMachine P on P.PlantID=PIN.Plantid AND P.MachineID=M.MachineID
	left outer join PlantMachineGroups P1 ON P1.MachineID=P.MachineID AND P1.PlantID=P.PlantID
	WHERE Convert(Nvarchar(10),Date,120)=Convert(Nvarchar(10),@Date,120) order By F.PlantID, F.MachineID,F.ShiftID 

----if @param='SHIFTWISEREJECTION'
----BEGIN
--	select F.PlantID,F.MachineID,M.InterfaceID as MachineInterface,F.Date,F.ShiftID,F.[Shift],F.Rejection_Reason AS RejectionID,F.Rejection_Qty as RejectionQty, F.Rejection_Freq as RejectionFreq FROM FocasWeb_ShiftwiseRejection F
--	INNER JOIN machineinformation M ON M.machineid=F.MachineID
--	WHERE Convert(Nvarchar(10),F.Date,120)=Convert(Nvarchar(10),@Date,120) order By F.Date,F.PlantID, F.MachineID,F.ShiftID
----END

--if @param='SHIFTWISEREJECTION'
--BEGIN
	select F.PlantID,F.MachineID,P1.GroupID,M.InterfaceID AS MachineInterface,F.Date,F.ShiftID,F.[Shift],F.Rejection_Reason AS RejectionID,F.Rejection_Qty as RejectionQty, F.Rejection_Freq as RejectionFreq FROM FocasWeb_ShiftwiseRejection F
	inner join PlantInformation PIN on F.PlantID=PIN.PlantID
	Inner Join Machineinformation M on  F.Machineid=M.Machineid
	Inner join PlantMachine P on P.PlantID=PIN.Plantid AND P.MachineID=M.MachineID
	left outer join PlantMachineGroups P1 ON P1.MachineID=P.MachineID AND P1.PlantID=P.PlantID
	WHERE Convert(Nvarchar(10),F.Date,120)=Convert(Nvarchar(10),@Date,120) order By F.Date, F.PlantID, F.MachineID,F.ShiftID
--END

----if @param='FrequencywiseData'
----BEGIN
--SELECT Date,PlantID,MachineID,Partscount,UtilisedTime,DownTime,
--	dbo.f_FormatTime(UtilisedTime,'hh:mm:ss') as UtilisedTime,  
--		dbo.f_FormatTime(DownTime,'hh:mm:ss') as DownTime,  
--	RejectionCount,AvailabilityEfficiency,ProductionEfficiency,QualityEfficiency,OverallEfficiency,Frequency FROM FocasWeb_FrequencyWiseData
--	WHERE Convert(Nvarchar(10),Date,120)=Convert(Nvarchar(10),@Date,120) --order By PlantID, MachineID,Frequency
----END
END
