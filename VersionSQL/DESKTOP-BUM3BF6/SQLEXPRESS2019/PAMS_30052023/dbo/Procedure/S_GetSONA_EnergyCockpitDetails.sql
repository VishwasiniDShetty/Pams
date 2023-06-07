/****** Object:  Procedure [dbo].[S_GetSONA_EnergyCockpitDetails]    Committed by VersionSQL https://www.versionsql.com ******/

/****************************************************************************************************************
--Procedure Created by Anjana C V on 29/Nov/2018.
--S_GetSONA_EnergyCockpitDetails '2018-11-13','2018-11-30','','','','',''
--S_GetSONA_EnergyCockpitDetails '2018-11-13','2018-11-30','','M02-001','','10','Day',''
--S_GetSONA_EnergyCockpitDetails '2018-11-13','2018-11-30','','M02-001','','50','Shift',''
--S_GetSONA_EnergyCockpitDetails '2018-11-13','2018-11-30','B','M02-001','','50','hour',''
*****************************************************************************************************************/

CREATE procedure [dbo].[S_GetSONA_EnergyCockpitDetails]
	@dDate datetime ,
	@Enddate datetime,
	@Shift nvarchar(50) = '',
	@MachineID nvarchar(50) = '',
	@PlantID nvarchar(50)='',
	@Node  nvarchar(50)='',
	@Parameter nvarchar(50)='',--'Day','Shift','hour'
	@View nvarchar(50)=''
AS 
BEGIN
SET NOCOUNT ON; 

declare @CurStrtTime as datetime
declare @ShiftStTime as datetime
select @CurStrtTime=@dDate
select @ShiftStTime=@dDate

Create table #GetShiftTime
(
dDate DateTime,
ShiftName NVarChar(50),
StartTime DateTime,
EndTime DateTime
)

CREATE TABLE #FinalData
(
	MachineID NvarChar(50),
	MachineInterface nvarchar(50),
	NodeID NvarChar(50),
	NodeInterface NvarChar(50), 
	ShiftHourID NvarChar(50),
	ShiftName NvarChar(50),
	StartTime DateTime,
	EndTime DateTime,
	PF float,
	Cost float,
	Energy float,
	Maxenergy float,
	Minenergy float,
	MinVolt1 float, 
	MinVolt2 float, 
	MinVolt3 float, 
	MaxVolt1 float, 
	MaxVolt2 float, 
	MaxVolt3 float,  
	InstantaneousVolt1 float, 
	InstantaneousVolt2 float, 
	InstantaneousVolt3 float,  
	LastArrivalTime datetime, 
	Ampere1 float,
	Ampere2 float, 
	Ampere3 float, 
	KW float, 
	KVA float, 
	LivePF float
)

--insert into #GetShiftTime Exec s_GetShiftTime @dDate,@Shift

if @Parameter = 'Day' 
	Begin
       create table #day
		(
			Starttime datetime,
			Endtime datetime
		)

    while @CurStrtTime<=@EndDate
	 BEGIN
	Insert into #day(Starttime,Endtime)
    Select dbo.f_GetLogicalDay(@CurStrtTime,'start'),dbo.f_GetLogicalDay(@CurStrtTime,'End')
	SELECT @CurStrtTime=DATEADD(DAY,1,@CurStrtTime)
END

END

if @Parameter = 'Shift' 
Begin
	while @ShiftStTime<=@EndDate
	BEGIN
		insert into #GetShiftTime (dDate, ShiftName, StartTime, EndTime)
		Exec s_GetShiftTime @ShiftStTime,@Shift
		SELECT @ShiftStTime=DATEADD(DAY,1,@ShiftStTime)
	END
END

if @Parameter = '' 
	Begin
	
		if isnull(@machineid,'')<>''
		Begin
			insert into #FinalData(MachineID,MachineInterface,NodeID,NodeInterface,ShiftHourID,StartTime,EndTime,PF,Cost,Energy,Maxenergy,Minenergy)--NR0117
			Select PlantMachine.Machineid,Machineinformation.Interfaceid,mn.NodeId,mn.NodeInterface,0,
			--(select min(StartTime) from #GetShiftTime),(select max(EndTime) from #GetShiftTime),0,0,0,0,0
			@dDate,@Enddate,0,0,0,0,0
			from Machineinformation inner join PlantMachine on machineinformation.Machineid = Plantmachine.Machineid
			inner join MachineNodeInformation mn on machineinformation.Machineid = mn.MachineId
			--cross join #day
			where PlantMachine.Machineid = @machineid and machineinformation.devicetype=5
		End
		else
		Begin
			if isnull(@PlantID,'')<>''
			Begin
				insert into #FinalData(MachineID,MachineInterface,NodeID,NodeInterface,ShiftHourID,StartTime,EndTime,PF,Cost,Energy,Maxenergy,Minenergy)--NR0117
				select Machineinformation.Machineid,Machineinformation.Interfaceid,mn.NodeId,mn.NodeInterface,0,
				--(select min(StartTime) from #GetShiftTime),(select max(EndTime) from #GetShiftTime),0,0,0,0,0
				@dDate,@Enddate,0,0,0,0,0
				from Machineinformation inner join PlantMachine on machineinformation.Machineid = Plantmachine.Machineid
				inner join MachineNodeInformation mn on machineinformation.Machineid = mn.MachineId
				--cross join #day
				where Plantmachine.PlantId = @PlantID and machineinformation.devicetype=5
				
			End
			Else
			Begin
				insert into #FinalData(MachineID,MachineInterface,NodeID,NodeInterface,ShiftHourID,StartTime,EndTime,PF,Cost,Energy,Maxenergy,Minenergy)--NR0117
				select Machineinformation.Machineid,Machineinformation.Interfaceid,mn.NodeId,mn.NodeInterface,0,
				--(select min(StartTime) from #GetShiftTime),(select max(EndTime) from #GetShiftTime),0,0,0,0,0
				@dDate,@Enddate,0,0,0,0,0
				from Machineinformation inner join PlantMachine on machineinformation.Machineid = Plantmachine.Machineid
				inner join MachineNodeInformation mn on machineinformation.Machineid = mn.MachineId
				--cross join #day
				where machineinformation.devicetype=5
			End
		End
	End


if @Parameter = 'Day' 
	Begin
	    
		

		if isnull(@machineid,'')<>''
		Begin
			if isnull(@Node,'')<>''
		Begin
			insert into #FinalData(MachineID,MachineInterface,NodeID,NodeInterface,ShiftHourID,StartTime,EndTime,PF,Cost,Energy,Maxenergy,Minenergy)--NR0117
			Select PlantMachine.Machineid,Machineinformation.Interfaceid,mn.NodeId,mn.NodeInterface,0,
			--(select min(StartTime) from #GetShiftTime),(select max(EndTime) from #GetShiftTime),0,0,0,0,0
			#day.StartTime,#day.EndTime,0,0,0,0,0
			from Machineinformation inner join PlantMachine on machineinformation.Machineid = Plantmachine.Machineid
			inner join MachineNodeInformation mn on machineinformation.Machineid = mn.MachineId
			cross join #day
			where PlantMachine.Machineid = @machineid  and mn.NodeId = @Node
			and machineinformation.devicetype=5
          End
		 else
		  Begin
			insert into #FinalData(MachineID,MachineInterface,NodeID,NodeInterface,ShiftHourID,StartTime,EndTime,PF,Cost,Energy,Maxenergy,Minenergy)--NR0117
			Select PlantMachine.Machineid,Machineinformation.Interfaceid,mn.NodeId,mn.NodeInterface,0,
			--(select min(StartTime) from #GetShiftTime),(select max(EndTime) from #GetShiftTime),0,0,0,0,0
			#day.StartTime,#day.EndTime,0,0,0,0,0
			from Machineinformation inner join PlantMachine on machineinformation.Machineid = Plantmachine.Machineid
			inner join MachineNodeInformation mn on machineinformation.Machineid = mn.MachineId
			cross join #day
			where PlantMachine.Machineid = @machineid   
			and machineinformation.devicetype=5
		end
		End
		
		else
		Begin
			if isnull(@PlantID,'')<>''
			Begin
				insert into #FinalData(MachineID,MachineInterface,NodeID,NodeInterface,ShiftHourID,StartTime,EndTime,PF,Cost,Energy,Maxenergy,Minenergy)--NR0117
				select Machineinformation.Machineid,Machineinformation.Interfaceid,mn.NodeId,mn.NodeInterface,0,
				--(select min(StartTime) from #GetShiftTime),(select max(EndTime) from #GetShiftTime),0,0,0,0,0
				#day.StartTime,#day.EndTime,0,0,0,0,0
				from Machineinformation inner join PlantMachine on machineinformation.Machineid = Plantmachine.Machineid
				inner join MachineNodeInformation mn on machineinformation.Machineid = mn.MachineId
				cross join #day
				where Plantmachine.PlantId = @PlantID and machineinformation.devicetype=5
				
			End
			Else
			Begin
				insert into #FinalData(MachineID,MachineInterface,NodeID,NodeInterface,ShiftHourID,StartTime,EndTime,PF,Cost,Energy,Maxenergy,Minenergy)--NR0117
				select Machineinformation.Machineid,Machineinformation.Interfaceid,mn.NodeId,mn.NodeInterface,0,
				--(select min(StartTime) from #GetShiftTime),(select max(EndTime) from #GetShiftTime),0,0,0,0,0
				#day.StartTime,#day.EndTime,0,0,0,0,0
				from Machineinformation inner join PlantMachine on machineinformation.Machineid = Plantmachine.Machineid
				inner join MachineNodeInformation mn on machineinformation.Machineid = mn.MachineId
				cross join #day
				where machineinformation.devicetype=5
			End
		End
	End


	if @Parameter = 'Shift'
	Begin


		if isnull(@machineid,'')<>''
		Begin

			if isnull(@node,'')<>''
			 Begin
				insert into #FinalData(MachineID,MachineInterface,NodeID,NodeInterface,ShiftHourID,StartTime,EndTime,PF,Cost,Energy,Maxenergy,Minenergy,ShiftName)
				Select PlantMachine.Machineid,Machineinformation.Interfaceid,mn.NodeId,mn.NodeInterface,0,
				#GetShiftTime.StartTime,#GetShiftTime.EndTime,0,0,0,0,0,#GetShiftTime.ShiftName
				from Machineinformation cross join  #GetShiftTime 
				inner join PlantMachine on machineinformation.Machineid = Plantmachine.Machineid
				inner join MachineNodeInformation mn on machineinformation.Machineid = mn.MachineId
				where PlantMachine.Machineid = @machineid and mn.NodeId = @Node
				and machineinformation.devicetype=5
			 End
			else
			 Begin
				insert into #FinalData(MachineID,MachineInterface,NodeID,NodeInterface,ShiftHourID,StartTime,EndTime,PF,Cost,Energy,Maxenergy,Minenergy,ShiftName)
				Select PlantMachine.Machineid,Machineinformation.Interfaceid,mn.NodeId,mn.NodeInterface,0,
				#GetShiftTime.StartTime,#GetShiftTime.EndTime,0,0,0,0,0,#GetShiftTime.ShiftName
				from Machineinformation cross join  #GetShiftTime 
				inner join PlantMachine on machineinformation.Machineid = Plantmachine.Machineid
				inner join MachineNodeInformation mn on machineinformation.Machineid = mn.MachineId
				where PlantMachine.Machineid = @machineid and machineinformation.devicetype=5
			 END
		End
		
		else
		
		Begin
			if isnull(@PlantID,'')<>''
			Begin
				insert into #FinalData(MachineID,MachineInterface,NodeID,NodeInterface,ShiftHourID,StartTime,EndTime,PF,Cost,Energy,Maxenergy,Minenergy,ShiftName)
				select Machineinformation.Machineid,Machineinformation.Interfaceid,mn.NodeId,mn.NodeInterface,0,
				#GetShiftTime.StartTime,#GetShiftTime.EndTime,0,0,0,0,0,#GetShiftTime.ShiftName
				from Machineinformation cross join #GetShiftTime 
				inner join PlantMachine on machineinformation.Machineid = Plantmachine.Machineid
				inner join MachineNodeInformation mn on machineinformation.Machineid = mn.MachineId
				where Plantmachine.PlantId = @PlantID and machineinformation.devicetype=5
				
			End
			Else
			Begin
				insert into #FinalData(MachineID,MachineInterface,NodeID,NodeInterface,ShiftHourID,StartTime,EndTime,PF,Cost,Energy,Maxenergy,Minenergy,ShiftName)
				select Machineinformation.Machineid,Machineinformation.Interfaceid,mn.NodeId,mn.NodeInterface,0,
				#GetShiftTime.StartTime,#GetShiftTime.EndTime,0,0,0,0,0,#GetShiftTime.ShiftName
				from Machineinformation cross join #GetShiftTime 
				inner join PlantMachine on machineinformation.Machineid = Plantmachine.Machineid
				inner join MachineNodeInformation mn on machineinformation.Machineid = mn.MachineId
				where machineinformation.devicetype=5
			End
		End
	End

	if @Parameter = 'hour'
	Begin
		insert into #FinalData(MachineID,MachineInterface,NodeID,NodeInterface,ShiftHourID,StartTime,EndTime,PF,Cost,Energy,Maxenergy,Minenergy)
		select machineinformation.MachineID,machineinformation.interfaceid,mn.NodeId,mn.NodeInterface,HourName,
		case when fromday = 0 then cast((cast(datepart(yyyy,@dDate) as nvarchar(20))+'-'+cast(datepart(m,@dDate) as nvarchar(20))+'-'+cast(datepart(dd,@dDate) as nvarchar(20))+' '+cast(datepart(hh,hourStart) as nvarchar(20))+':'+cast(datepart(n,hourStart) as nvarchar(20))+':'+cast(datepart(s,hourStart) as nvarchar(20))) as DateTime)
			 when fromday = 1 then cast((cast(datepart(yyyy,@dDate) as nvarchar(20))+'-'+cast(datepart(m,@dDate) as nvarchar(20))+'-'+cast(datepart(dd,@dDate) as nvarchar(20))+' '+cast(datepart(hh,hourStart) as nvarchar(20))+':'+cast(datepart(n,hourStart) as nvarchar(20))+':'+cast(datepart(s,hourStart) as nvarchar(20))) as DateTime)+1
		end as FromTime,
		case when today = 0 then cast((cast(datepart(yyyy,@dDate) as nvarchar(20))+'-'+cast(datepart(m,@dDate) as nvarchar(20))+'-'+cast(datepart(dd,@dDate) as nvarchar(20))+' '+cast(datepart(hh,hourEnd) as nvarchar(20))+':'+cast(datepart(n,hourEnd) as nvarchar(20))+':'+cast(datepart(s,hourEnd) as nvarchar(20))) as DateTime)
			 when today = 1 then cast((cast(datepart(yyyy,@dDate) as nvarchar(20))+'-'+cast(datepart(m,@dDate) as nvarchar(20))+'-'+cast(datepart(dd,@dDate) as nvarchar(20))+' '+cast(datepart(hh,hourEnd) as nvarchar(20))+':'+cast(datepart(n,hourEnd) as nvarchar(20))+':'+cast(datepart(s,hourEnd) as nvarchar(20))) as DateTime)+1
		end as ToTime,0,0,0,0,0
		From Shifthourdefinition cross join machineinformation
		inner join MachineNodeInformation mn on machineinformation.Machineid = mn.MachineId
		where shiftid in (select shiftid from shiftdetails where running = 1 and shiftname = @Shift) and
		machineinformation.machineid = @MachineID and mn.NodeId = @Node
		order by Shifthourdefinition.HourID
	End


Update #FinalData
set #FinalData.PF = ISNULL(#FinalData.PF,0)+ISNULL(t1.PF,0)
from (
	select tcs_energyconsumption.MachineiD,StartTime,EndTime,
	
	avg(Abs(tcs_energyconsumption.pf)) as PF 
    from tcs_energyconsumption WITH(NOLOCK) inner join #FinalData on 
	tcs_energyconsumption.machineID = #FinalData.NodeInterface and tcs_energyconsumption.gtime >= #FinalData.StartTime
	and tcs_energyconsumption.gtime <= #FinalData.EndTime 
	group by tcs_energyconsumption.MachineiD,StartTime,EndTime
) as t1 inner join #FinalData on t1.machineiD = #FinalData.NodeInterface and
t1.StartTime = #FinalData.StartTime and t1.endTime = #FinalData.EndTime

Update #FinalData
set #FinalData.MinEnergy = ISNULL(#FinalData.MinEnergy,0)+ISNULL(t1.kwh,0) from 
(
select T.MachineiD,T.StartTime,T.EndTime,round(kwh,2) as kwh from 
	(
	select  tcs_energyconsumption.MachineiD,StartTime,EndTime,
	min(gtime) as mingtime
	from tcs_energyconsumption WITH(NOLOCK) inner join #FinalData on 
	tcs_energyconsumption.machineID = #FinalData.NodeInterface and tcs_energyconsumption.gtime >= #FinalData.StartTime
	and tcs_energyconsumption.gtime <= #FinalData.EndTime
	where tcs_energyconsumption.kwh>0 
	group by  tcs_energyconsumption.MachineiD,StartTime,EndTime
	)T
	inner join tcs_energyconsumption on tcs_energyconsumption.gtime=T.mingtime 
	AND tcs_energyconsumption.MachineID = T.MachineID --DR0359
	) as t1 
inner join #FinalData on t1.machineiD = #FinalData.NodeInterface and
t1.StartTime = #FinalData.StartTime and t1.endTime = #FinalData.EndTime

Update #FinalData
set #FinalData.MaxEnergy = ISNULL(#FinalData.MaxEnergy,0)+ISNULL(t1.kwh,0) from 
(
select T.MachineiD,T.StartTime,T.EndTime,round(kwh,2)as kwh from 
	(
	select  tcs_energyconsumption.MachineiD,StartTime,EndTime,
	max(gtime) as maxgtime
	from tcs_energyconsumption WITH(NOLOCK) inner join #FinalData on 
	tcs_energyconsumption.machineID = #FinalData.NodeInterface and tcs_energyconsumption.gtime >= #FinalData.StartTime
	and tcs_energyconsumption.gtime <= #FinalData.EndTime
	where tcs_energyconsumption.kwh>0 
	group by  tcs_energyconsumption.MachineiD,StartTime,EndTime)T
	inner join tcs_energyconsumption on tcs_energyconsumption.gtime=T.maxgtime  
	AND tcs_energyconsumption.MachineID = T.MachineID 
	) as t1 
inner join #FinalData on t1.machineiD = #FinalData.NodeInterface and
t1.StartTime = #FinalData.StartTime and t1.endTime = #FinalData.EndTime


Update #FinalData
set #FinalData.Energy = ISNULL(#FinalData.Energy,0)+ISNULL(t1.kwh,0), 
#FinalData.Cost = ISNULL(#FinalData.Cost,0)+ISNULL(t1.kwh * (Select max(Valueintext) from shopdefaults where Parameter = 'CostPerKWH'),0)
from 
(
	select MachineiD,NodeInterface,StartTime,EndTime,round((MaxEnergy - MinEnergy),2) as kwh from #FinalData 
) as t1 inner join #FinalData on t1.NodeInterface = #FinalData.NodeInterface and
t1.StartTime = #FinalData.StartTime and t1.endTime = #FinalData.EndTime

Update #Finaldata set InstantaneousVolt1=isnull(#Finaldata.InstantaneousVolt1,0) + isnull(T1.V1,0),
InstantaneousVolt2=isnull(#Finaldata.InstantaneousVolt2,0) + isnull(T1.V2,0),
InstantaneousVolt3=isnull(#Finaldata.InstantaneousVolt3,0) + isnull(T1.V3,0),
Ampere1=isnull(#Finaldata.Ampere1,0)+isnull(T1.A1,0),
Ampere2=isnull(#Finaldata.Ampere2,0)+isnull(T1.A2,0),
Ampere3=isnull(#Finaldata.Ampere3,0)+isnull(T1.A3,0),KW = isnull(#Finaldata.KW,0)+isnull(T1.KW,0),
KVA=isnull(#Finaldata.KVA,0)+isnull(T1.KVA,0),
LastArrivalTime=isnull(#Finaldata.LastArrivalTime,'1900-01-01')+ isnull(T1.Lastarrival,'1900-01-01'),
LivePF=isnull(#FinalData.LivePF,0)+isnull(T1.PF,0) from
(
select T.MachineiD,T.StartTime,T.EndTime,Volt1 as V1,Volt2 as V2,Volt3 as V3,
round(AmpereR,2) as A1,Round(AmpereY,2) as A2,Round(AmpereB,2) as A3,Round(KVA,2) as KVA,Round(watt,2) as KW,
maxgtime as LastArrival,round(PF,2) as PF from 
	(
	select  TCS.MachineiD,F.StartTime,F.EndTime,max(gtime) as maxgtime
	from tcs_energyconsumption TCS WITH(NOLOCK) inner join #FinalData F on 
	TCS.machineID = F.NodeInterface 
	group by  TCS.MachineiD,F.StartTime,F.EndTime)T
	inner join tcs_energyconsumption on tcs_energyconsumption.gtime=T.maxgtime  
	AND tcs_energyconsumption.MachineID = T.MachineID 
	) as t1 
inner join #FinalData on t1.machineiD = #FinalData.NodeInterface and
t1.StartTime = #FinalData.StartTime and t1.endTime = #FinalData.EndTime

Update #Finaldata set MinVolt1=isnull(#Finaldata.MinVolt1,0) + isnull(T1.V1,0),
MinVolt2=isnull(#Finaldata.MinVolt2,0) + isnull(T1.V2,0),
minVolt3=isnull(#Finaldata.minVolt3,0) + isnull(T1.V3,0) from
(
	select  TCS.MachineiD,F.StartTime,F.EndTime,min(volt1) as V1,min(volt2) as V2,min(volt3) as V3
	from tcs_energyconsumption TCS WITH(NOLOCK) inner join #FinalData F on 
	TCS.machineID = F.NodeInterface and TCS.gtime >= F.StartTime and TCS.gtime <= F.EndTime
	group by  TCS.MachineiD,F.StartTime,F.EndTime
) as T1 
inner join #FinalData on t1.machineiD = #FinalData.NodeInterface and
t1.StartTime = #FinalData.StartTime and t1.endTime = #FinalData.EndTime

Update #Finaldata set MaxVolt1=isnull(#Finaldata.maxVolt1,0) + isnull(T1.V1,0),
MaxVolt2=isnull(#Finaldata.MaxVolt2,0) + isnull(T1.V2,0),
MaxVolt3=isnull(#Finaldata.MaxVolt3,0) + isnull(T1.V3,0) from
(
	select  TCS.MachineiD,F.StartTime,F.EndTime,max(volt1) as V1,max(volt2) as V2,max(volt3) as V3
	from tcs_energyconsumption TCS WITH(NOLOCK) inner join #FinalData F on 
	TCS.machineID = F.NodeInterface and TCS.gtime >= F.StartTime and TCS.gtime <= F.EndTime
	group by  TCS.MachineiD,F.StartTime,F.EndTime
) as T1 
inner join #FinalData on t1.machineiD = #FinalData.NodeInterface and
t1.StartTime = #FinalData.StartTime and t1.endTime = #FinalData.EndTime

--select * from #FinalData
/*
If @View = ''
Begin
	Select
	MachineID,
	NodeId,
	ShiftHourID,
	ShiftName,
	StartTime,
	EndTime,
	round(PF,2) as PF,
	round(Energy * (Select top 1 valueintext from shopdefaults where parameter = 'CostPerKWH'),2) as Cost,
	round(Energy,2)as Energy
	from #FinalData order by MachineID,NodeId,StartTime
end 
*/
If @View = ''
Begin

	Update #FinalData SET Cost = round(T1.Energy * (Select top 1 valueintext from shopdefaults where parameter = 'CostPerKWH'),2)from
	(Select Machineid,NodeID,StartTime,EndTime,Energy from #FinalData)T1 inner join #FinalData on #FinalData.Machineid=T1.Machineid and
	#FinalData.NodeID = T1.NodeID and
	t1.StartTime = #FinalData.StartTime and t1.endTime = #FinalData.EndTime

	IF @Parameter = ''
	BEGIN
		Select
		#FinalData.MachineID, 
		#FinalData.NodeID,
		--ShiftHourID,
		--ShiftName,
		#FinalData.StartTime,
		#FinalData.EndTime,
		round(PF,2) as PF,
		round(#FinalData.Energy * (Select top 1 valueintext from shopdefaults where parameter = 'CostPerKWH'),2) as Cost,
		round(#FinalData.Energy,2)as Energy
		,cast(MinVolt1 as nvarchar(50))+ ' \ ' + cast(MaxVolt1 as nvarchar(50)) as Volt1
		,cast(MinVolt2 as nvarchar(50))+ ' \ ' + cast(MaxVolt2 as nvarchar(50)) as Volt2
		,cast(MinVolt3 as nvarchar(50))+ ' \ ' + cast(MaxVolt3 as nvarchar(50)) as Volt3,
		LastArrivalTime,InstantaneousVolt1 as V1,InstantaneousVolt2 as V2,InstantaneousVolt3 as V3,Ampere1 as AR ,Ampere2 as AY,Ampere3 as AB ,
		KW,KVA
		from #FinalData  inner join Machineinformation on #FinalData.Machineid=Machineinformation.Machineid
		order by #FinalData.MachineID,#FinalData.NodeID,StartTime
	END 

   IF @Parameter = 'Day'
	BEGIN
		Select
		#FinalData.MachineID, 
		#FinalData.NodeID,
		ShiftHourID,
		ShiftName,
		#FinalData.StartTime,
		#FinalData.EndTime,
		round(PF,2) as PF,
		round(#FinalData.Energy * (Select top 1 valueintext from shopdefaults where parameter = 'CostPerKWH'),2) as Cost,
		round(#FinalData.Energy,2)as Energy
		,cast(MinVolt1 as nvarchar(50))+ ' \ ' + cast(MaxVolt1 as nvarchar(50)) as Volt1
		,cast(MinVolt2 as nvarchar(50))+ ' \ ' + cast(MaxVolt2 as nvarchar(50)) as Volt2
		,cast(MinVolt3 as nvarchar(50))+ ' \ ' + cast(MaxVolt3 as nvarchar(50)) as Volt3,
		LastArrivalTime,InstantaneousVolt1 as V1,InstantaneousVolt2 as V2,InstantaneousVolt3 as V3,Ampere1 as AR ,Ampere2 as AY,Ampere3 as AB ,
		KW,KVA
		from #FinalData  inner join Machineinformation on #FinalData.Machineid=Machineinformation.Machineid
		order by #FinalData.MachineID,#FinalData.NodeID,StartTime
	END

	   IF @Parameter = 'Shift' OR  @Parameter = 'Hour'
	BEGIN
		Select
		#FinalData.MachineID, 
		#FinalData.NodeID,
		ShiftHourID,
		ShiftName,
		#FinalData.StartTime,
		#FinalData.EndTime,
		round(PF,2) as PF,
		round(#FinalData.Energy * (Select top 1 valueintext from shopdefaults where parameter = 'CostPerKWH'),2) as Cost,
		round(#FinalData.Energy,2)as Energy
		,cast(MinVolt1 as nvarchar(50))+ ' \ ' + cast(MaxVolt1 as nvarchar(50)) as Volt1
		,cast(MinVolt2 as nvarchar(50))+ ' \ ' + cast(MaxVolt2 as nvarchar(50)) as Volt2
		,cast(MinVolt3 as nvarchar(50))+ ' \ ' + cast(MaxVolt3 as nvarchar(50)) as Volt3,
		LastArrivalTime,InstantaneousVolt1 as V1,InstantaneousVolt2 as V2,InstantaneousVolt3 as V3,Ampere1 as AR ,Ampere2 as AY,Ampere3 as AB ,
		KW,KVA
		from #FinalData  inner join Machineinformation on #FinalData.Machineid=Machineinformation.Machineid
		order by #FinalData.MachineID,#FinalData.NodeID,StartTime
	END
end
/*
If @View='TechnoLiveScreen'
Begin
	Select
	MachineID,NodeId,LastArrivalTime,InstantaneousVolt1 as V1,InstantaneousVolt2 as V2,InstantaneousVolt3 as V3,Ampere1 as AR ,Ampere2 as AY,Ampere3 as AB ,
	KW,KVA,round(LivePF,2) as PF from #Finaldata order by Machineid,NodeId,Lastarrivaltime
End
*/
END
