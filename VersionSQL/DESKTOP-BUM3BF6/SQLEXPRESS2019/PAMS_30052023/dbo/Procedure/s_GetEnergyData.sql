/****** Object:  Procedure [dbo].[s_GetEnergyData]    Committed by VersionSQL https://www.versionsql.com ******/

      
/****************************************************************************************************************      
--Procedure Created by Karthikg on 29/Oct/2009.      
--ER0206-KarthikG-02/Nov/2009 :: New procedure 's_GetEnergyData' to populate first screen of energy cockpit dynamically.      
ER0383 - SwathiKS - 29/May/2014 :: Performance Optimization.      
DR0359 - satya - 18-March-2015 :: Getting negative value for KWH because of missing machine join      
NR0117(SV) - SwathiKS (SV) - 28/Jul/2015 :: Techno - a> Dashboard To Show Min. and Max. Voltage1, Voltage2 and Voltage3 in the output along with Utilisedtime,PF,Cost and Energy.      
b> Livescreen - To show Live Values for  V1,V2,V3,AR,AY,AB,KVA and KW i.e Last Recorded Value in the given Period for the given Machine.      
ER0454 - Gopinath - 14/Oct/2017 :: To Introduce EnergySource in the Output For Techno To hold EB/DG Values.
ER0502:SwathiKS:12/Mar/2021::To Use EM_MachineInformation instead of Machineinformation.
Going forward we will store Machines in EM_MachineInformation Table which are enabled for Energy Data Collection instead of Machineinformation. 
Machines which are Enabled For OEE & Energy both, Should be stored in both the tables with same Machineid & interfaceid.  
Enery Related Info we can get From EM_Machineinformation and tcs_EnergyConsumption Tables
OEE Related Info from Mahcineinformation and Autodata Tables.

exec s_GetEnergyData @dDate=N'2021-03-10',@Shift=N'',@Parameter=N'Shift',@MachineID=N'SQF 1',@PlantID=N'',@View=N'',@MachineType=N'Non-Machine EM',@HistoryLive=N'History'

[s_GetEnergyData] '2021-04-10','','MC BA-1','','Shift','','TechnoDashboard','Machine EM'    

exec s_GetEnergyData @dDate=N'',@Shift=N'',@MachineID=N'',@PlantID=N'',@Parameter=N'day',@View=N'Technolivescreen',@HistoryLive=N'live',@MachineType=N''

*****************************************************************************************************************/      
      
CREATE procedure [dbo].[s_GetEnergyData]      -- testing for multiple shifts, using kwh1 and gtime1
 @dDate datetime ,      
 @Shift nvarchar(50) = '',      
 @MachineID nvarchar(50) = '',      
 @PlantID nvarchar(50)='',      
 @Parameter nvarchar(50)='',--'Day','Shift','hour'      
 @HistoryLive nvarchar(50)='', --History,Live, --NR0117      
 @View nvarchar(50)='', --NR0117 
 @MachineType nvarchar(50)=''

as      
begin      
      
SET NOCOUNT ON; --ER0383      

if @HistoryLive = 'History'      
Begin      
 if @Parameter = 'Day'      
 Begin      
  if isnull(@machineid,'')<>''      
  Begin      
   select EM_Machineinformation.MachineID,dbo.f_FormatTime(Sum(prodTime),'HH:MM:SS') as UtilisedTime,sum(pcount) as Components,Round(Avg(PF),2) as PF,Round(sum(Cost),2) as Cost,(Round(sum(Energy),2)) as  Energy from EnergyCockpit      
   inner join EM_Machineinformation on EM_Machineinformation.MachineID = EnergyCockpit.Machineid      
   inner join EM_PlantMachine on EM_PlantMachine.Machineid = EM_Machineinformation.MachineID      
   where EM_PlantMachine.Machineid = @machineid and EnergyCockpit.dDate = @dDate      
   and (EM_Machineinformation.MachineType = @MachineType or isnull(@MachineType,'')='') and EM_Machineinformation.MachineID in (select distinct MachineID from EnergyCockpit)      
   group by EM_Machineinformation.MachineID     
  End      
  else      
  Begin      
   if isnull(@PlantID,'')<>''      
   Begin      
    select EM_Machineinformation.MachineID,dbo.f_FormatTime(Sum(prodTime),'HH:MM:SS') as UtilisedTime,sum(pcount) as Components,Round(Avg(PF),2) as PF,Round(sum(Cost),2) as Cost,(Round(sum(Energy),2)) as  Energy from EnergyCockpit      
    inner join EM_Machineinformation on EM_Machineinformation.MachineID = EnergyCockpit.Machineid      
    inner join EM_PlantMachine on EM_PlantMachine.Machineid = EM_Machineinformation.MachineID      
    where EM_PlantMachine.PlantId = @PlantID and EnergyCockpit.dDate = @dDate      
    and (EM_Machineinformation.MachineType = @MachineType or isnull(@MachineType,'')='') and EM_Machineinformation.MachineID in (select distinct MachineID from EnergyCockpit)      
    group by EM_Machineinformation.MachineID      
   End      
   Else      
   Begin      
    select EM_Machineinformation.MachineID,dbo.f_FormatTime(Sum(prodTime),'HH:MM:SS') as UtilisedTime,sum(pcount) as Components,Round(Avg(PF),2) as PF,Round(sum(Cost),2) as Cost,(Round(sum(Energy),2)) as  Energy from EnergyCockpit      
    inner join EM_Machineinformation on EM_Machineinformation.MachineID = EnergyCockpit.Machineid      
    inner join EM_PlantMachine on EM_PlantMachine.Machineid = EM_Machineinformation.MachineID      
    Where EnergyCockpit.dDate = @dDate and EM_Machineinformation.MachineID in (select distinct MachineID from EnergyCockpit) and (EM_Machineinformation.MachineType = @MachineType  or isnull(@MachineType,'')='')
    group by EM_Machineinformation.MachineID      
   End      
  End      
 End      
       
 if @Parameter = 'Shift'      
 Begin    
  select @machineid as MachineID,ShiftName as ShiftHourID,dbo.f_FormatTime(UtilisedTime,'HH:MM:SS') as UtilisedTime,      
  Isnull(Components,0) as Components,Isnull(PF,0) as PF,      
  IsNull(Cost,0) as Cost,IsNull(Energy,0) as Energy from shiftdetails left outer join      
  (select dShift,Isnull(Sum(prodTime),0) as UtilisedTime,sum(pcount) as Components,Round(Avg(PF),2) as PF,Round(sum(Cost),2) as Cost,(Round(sum(Energy),2)) as  Energy from energyCockpit where machineid = @machineid and EnergyCockpit.dDate = @dDate group by dShift)      
  as t1 on t1.dShift=shiftdetails.shiftID where running = 1      
  order by ShiftID      
 End      
--select * from EnergyCockpit
 if @Parameter = 'hour'      
 Begin      
  select IsNull(MachineID,@machineid) as machineID,      
  --HourName as ShiftHourID,HourID,Isnull(ProdTime,0) as utilisedTime, --Swathi commented      
  HourName as ShiftHourID,HourID,dbo.f_FormatTime(Isnull(ProdTime,0),'HH:MM:SS') as utilisedTime,      
  --isnull(pCount,0) as Components,isnull(PF,0) as PF,isnull(Cost,0) as Cost,      
  --isnull(Energy,0) as Energy from shiftdetails inner join      
  isnull(pCount,0) as Components,round(isnull(PF,0),2) as PF,round(isnull(Cost,0),2) as Cost,      
  round(isnull(Energy,0),2) as Energy from shiftdetails inner join      
  ShiftHourDefinition on shiftdetails.ShiftID = ShiftHourDefinition.ShiftID      
  left outer join (select MachineID,dhour,dshift,ProdTime,pCount,PF,Cost,Energy from energyCockpit      
  where machineid = @machineid and ddate = @dDate) as t1 on t1.dShift = ShiftHourDefinition.ShiftID      
  and t1.dHour = ShiftHourDefinition.hourID      
  where running = 1 and ShiftName = @Shift      
  order by HourID   
  
 End      
 Return      
End   

CREATE TABLE #Exceptions      
(      
 MachineID NVarChar(50),      
 ComponentID Nvarchar(50),      
 OperationNo Int,      
 StartTime DateTime,      
 EndTime DateTime,      
 ExStartTime DateTime,      
 ExEndTime DateTime,      
 ExCount Int,      
 ActualCount Int,      
 IdealCount Int      
)      
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
 ShiftHourID NvarChar(50),      
 StartTime DateTime,      
 EndTime DateTime,      
 UtilisedTime float,      
 components int,      
 PF float,      
 Cost float,      
 Energy float,   
 DGEnergy float, --ER0454
 EBEnergy float, --ER0454  
 Maxenergy float,      
 Minenergy float,      
 MinVolt1 float, --NR0117      
 MinVolt2 float, --NR0117      
 MinVolt3 float,  --NR0117    
 MinVolt4 float,
 MinVolt5 float,
 MinVolt6 float,
 MaxVolt1 float, --NR0117      
 MaxVolt2 float, --NR0117      
 MaxVolt3 float,  --NR0117 
 MaxVolt4 float,
 MaxVolt5 float,
 MaxVolt6 float,
 Instantaneousvolt1 float, --NR0117      
 Instantaneousvolt2 float, --NR0117      
 Instantaneousvolt3 float,  --NR0117      
 LastArrivalTime datetime, --NR0117      
 Ampere1 float,--NR0117      
 Ampere2 float, --NR0117      
 Ampere3 float, --NR0117      
 KW float, --NR0117      
 KVA float, --NR0117      
 LivePF float, --NR0117     
 Target float DEFAULT 0, --NR0117  
 KWH float --NR0117    
)      
      
insert into #GetShiftTime Exec s_GetShiftTime @dDate,@Shift      
      
 if @Parameter = 'Day'      
 Begin      
  if isnull(@machineid,'')<>''      
  Begin      
   insert into #FinalData(MachineID,MachineInterface,ShiftHourID,StartTime,EndTime,UtilisedTime,components,PF,Cost,Energy,Maxenergy,Minenergy)      
   Select EM_PlantMachine.Machineid,EM_Machineinformation.Interfaceid,0,      
   (select min(StartTime) from #GetShiftTime),(select max(EndTime) from #GetShiftTime),0,0,0,0,0,0,0 --NR0117      
   from EM_Machineinformation inner join EM_PlantMachine on EM_Machineinformation.Machineid = EM_PlantMachine.Machineid      
   where EM_PlantMachine.Machineid = @machineid and (EM_Machineinformation.MachineType = @MachineType or isnull(@MachineType,'')='') --and EM_Machineinformation.devicetype=5      
   --and machineinformation.MachineID in (select distinct MachineID from tcs_energyconsumption) --Swathi Commented      
   --(select distinct MachineID from machineinformation where  devicetype=5) --Swathi Commented      
  End      
  else      
  Begin      
   if isnull(@PlantID,'')<>''      
   Begin      
    insert into #FinalData(MachineID,MachineInterface,ShiftHourID,StartTime,EndTime,UtilisedTime,components,PF,Cost,Energy,Maxenergy,Minenergy)      
    select EM_Machineinformation.Machineid,EM_Machineinformation.Interfaceid,0,      
    (select min(StartTime) from #GetShiftTime),(select max(EndTime) from #GetShiftTime),0,0,0,0,0,0,0 --NR0117      
    from EM_Machineinformation inner join EM_PlantMachine on EM_Machineinformation.Machineid = EM_PlantMachine.Machineid      
    where EM_PlantMachine.PlantId = @PlantID and (EM_Machineinformation.MachineType = @MachineType or isnull(@MachineType,'')='') --and EM_Machineinformation.devicetype=5      
    --machineinformation.MachineID in (select distinct MachineID from tcs_energyconsumption)      
          
   End      
   Else      
   Begin      
    insert into #FinalData(MachineID,MachineInterface,ShiftHourID,StartTime,EndTime,UtilisedTime,components,PF,Cost,Energy,Maxenergy,Minenergy)      
    select EM_Machineinformation.Machineid,EM_Machineinformation.Interfaceid,0,      
    (select min(StartTime) from #GetShiftTime),(select max(EndTime) from #GetShiftTime),0,0,0,0,0,0,0 --NR0117      
    from EM_Machineinformation inner join EM_PlantMachine on EM_Machineinformation.Machineid = EM_PlantMachine.Machineid  
	where (EM_Machineinformation.MachineType = @MachineType or isnull(@MachineType,'')='')
    --and machineinformation.MachineID in (select distinct MachineID from tcs_energyconsumption)      
    --where machineinformation.devicetype=5      
   End      
  End      
 End      
 if @Parameter = 'Shift'      
 Begin      
  ----NR0117 commented From here      
--  insert into #FinalData      
--  Select machineinformation.MachineID,machineinformation.interfaceid,Shiftdetails.ShiftName,      
--  #GetShiftTime.StartTime,#GetShiftTime.EndTime,0,0,0,0,0,0,0,0,0,0,0,0,0 --NR0117      
--  from #GetShiftTime      
--  inner join machineinformation on Machineinformation.MachineID = @MachineID      
--  inner join Shiftdetails on #GetShiftTime.ShiftName = Shiftdetails.ShiftName and running = 1      
--  order by Shiftdetails.ShiftID      
  --NR0117 Commented Till Here      
      
  --NR0117 Added From Here      
  if isnull(@machineid,'')<>''      
  Begin      
  select * from #GetShiftTime --rem
   insert into #FinalData(MachineID,MachineInterface,ShiftHourID,StartTime,EndTime,UtilisedTime,components,PF,Cost,Energy,Maxenergy,Minenergy)      
   Select EM_PlantMachine.Machineid,EM_Machineinformation.Interfaceid,#GetShiftTime.ShiftName,      
   #GetShiftTime.StartTime,#GetShiftTime.EndTime,0,0,0,0,0,0,0      
   from EM_Machineinformation cross join  #GetShiftTime       
   inner join EM_PlantMachine on EM_Machineinformation.Machineid = EM_PlantMachine.Machineid      
   where EM_PlantMachine.Machineid = @machineid and (EM_Machineinformation.MachineType = @MachineType or isnull(@MachineType,'')='')--and EM_Machineinformation.devicetype=5      
  End      
  else      
  Begin      
   if isnull(@PlantID,'')<>''      
   Begin  
   select * from #GetShiftTime --rem    
    insert into #FinalData(MachineID,MachineInterface,ShiftHourID,StartTime,EndTime,UtilisedTime,components,PF,Cost,Energy,Maxenergy,Minenergy)      
    select EM_Machineinformation.Machineid,EM_Machineinformation.Interfaceid,#GetShiftTime.ShiftName,      
    #GetShiftTime.StartTime,#GetShiftTime.EndTime,0,0,0,0,0,0,0      
    from EM_Machineinformation cross join #GetShiftTime       
    inner join EM_PlantMachine on EM_Machineinformation.Machineid = EM_PlantMachine.Machineid      
    where EM_PlantMachine.PlantId = @PlantID and (EM_Machineinformation.MachineType = @MachineType or isnull(@MachineType,'')='') --and EM_Machineinformation.devicetype=5      
          
   End      
   Else      
   Begin      
   --g shiftname instead of 0
    insert into #FinalData(MachineID,MachineInterface,ShiftHourID,StartTime,EndTime,UtilisedTime,components,PF,Cost,Energy,Maxenergy,Minenergy)      
    select EM_Machineinformation.Machineid,EM_Machineinformation.Interfaceid,#GetShiftTime.ShiftName,      
    #GetShiftTime.StartTime,#GetShiftTime.EndTime,0,0,0,0,0,0,0      
    from EM_Machineinformation cross join #GetShiftTime       
    inner join EM_PlantMachine on EM_Machineinformation.Machineid = EM_PlantMachine.Machineid
	where (EM_Machineinformation.MachineType = @MachineType or isnull(@MachineType,'')='')
    --where EM_Machineinformation.devicetype=5      
   End      
  End      
  --NR0117 Added Till here      
 End      
 if @Parameter = 'hour'      
 Begin      
 --select 'hour' meh   
  insert into #FinalData(MachineID,MachineInterface,ShiftHourID,StartTime,EndTime,UtilisedTime,components,PF,Cost,Energy,Maxenergy,Minenergy)      
  select EM_Machineinformation.MachineID,EM_Machineinformation.interfaceid,HourName,      
  case when fromday = 0 then cast((cast(datepart(yyyy,@dDate) as nvarchar(20))+'-'+cast(datepart(m,@dDate) as nvarchar(20))+'-'+cast(datepart(dd,@dDate) as nvarchar(20))+' '+cast(datepart(hh,hourStart) as nvarchar(20))+':'+cast(datepart(n,hourStart) as nvarchar(20))+':'+cast(datepart(s,hourStart) as nvarchar(20))) as DateTime)      
    when fromday = 1 then cast((cast(datepart(yyyy,@dDate) as nvarchar(20))+'-'+cast(datepart(m,@dDate) as nvarchar(20))+'-'+cast(datepart(dd,@dDate) as nvarchar(20))+' '+cast(datepart(hh,hourStart) as nvarchar(20))+':'+cast(datepart(n,hourStart) as nvarchar(20))+':'+cast(datepart(s,hourStart) as nvarchar(20))) as DateTime)+1      
  end as FromTime,      
  case when today = 0 then cast((cast(datepart(yyyy,@dDate) as nvarchar(20))+'-'+cast(datepart(m,@dDate) as nvarchar(20))+'-'+cast(datepart(dd,@dDate) as nvarchar(20))+' '+cast(datepart(hh,hourEnd) as nvarchar(20))+':'+cast(datepart(n,hourEnd) as nvarchar(20))+':'+cast(datepart(s,hourEnd) as nvarchar(20))) as DateTime)      
    when today = 1 then cast((cast(datepart(yyyy,@dDate) as nvarchar(20))+'-'+cast(datepart(m,@dDate) as nvarchar(20))+'-'+cast(datepart(dd,@dDate) as nvarchar(20))+' '+cast(datepart(hh,hourEnd) as nvarchar(20))+':'+cast(datepart(n,hourEnd) as nvarchar(20))+':'+cast(datepart(s,hourEnd) as nvarchar(20))) as DateTime)+1      
  end as ToTime,0,0,0,0,0,0,0 --NR0117      
  From Shifthourdefinition cross join EM_Machineinformation      
  where shiftid in (select shiftid from shiftdetails where running = 1 and shiftname = @Shift) and      
  machineid = @MachineID  and (EM_Machineinformation.MachineType = @MachineType  or isnull(@MachineType,'')='')
  order by Shifthourdefinition.HourID      
 End      
      
---ER0383 from Here      
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
 [PartsCount] [int] NULL ,      
 id  bigint not null      
)      
      
ALTER TABLE #T_autodata      
      
ADD PRIMARY KEY CLUSTERED      
(      
 mc,sttime,ndtime,msttime ASC      
)ON [PRIMARY]      
      

CREATE TABLE #T_tcs_energyconsumption(
	[MachineID] [nvarchar](50) NULL,
	[gtime] [datetime] NOT NULL,
	[ampere] [float] NOT NULL,
	[watt] [float] NOT NULL,
	[pf] [float] NOT NULL,
	[idd] [int] NOT NULL,
	[KWH] [float] NULL,
	[gtime1] [datetime] NULL,
	[ampere1] [float] NULL,
	[KWH1] [float] NULL,
	[Volt1] [int] NULL,
	[Volt2] [int] NULL,
	[Volt3] [int] NULL,
	[AmpereR] [float] NULL,
	[AmpereY] [float] NULL,
	[AmpereB] [float] NULL,
	[KVA] [float] NULL,
	[EnergySource] [smallint] NULL
) ON [PRIMARY]

Declare @strSql as nvarchar(4000)      
Declare @T_ST AS Datetime       
Declare @T_ED AS Datetime       
      
select @strsql = ''      
--select count(*) from tcs_energyconsumption where gtime >= '2018-01-01 08:00:00.000' and gtime <= '2018-06-26 08:00:00.000'
--s_GetEnergyDataTest3 '2018-01-30','','','','day','','Technolivescreen'
--s_GetEnergyDataTest3 '2018-01-30','','','','day','','TechnoDashboard'
--update #FinalData set StartTime = '2018-01-01 08:00:00.000', Endtime='2018-06-26 08:00:00.000' --remove
--update #FinalData set StartTime = '2019-01-01 08:00:00.000', Endtime='2019-01-20 08:00:00.000' --remove
Select @T_ST=min(StartTime) from #FinalData      
Select @T_ED=max(EndTime)from #FinalData      
      
Select @strsql=''      
select @strsql ='insert into #T_autodata '      
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'      
 select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'      
select @strsql = @strsql + ' from autodata WITH(NOLOCK) where (( sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_ED,120)+''' ) OR ' ---ER0383      
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' )OR '      
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ST,120)+'''      
     and ndtime<='''+convert(nvarchar(25),@T_ED,120)+''' )'      
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' and sttime<'''+convert(nvarchar(25),@T_ED,120)+''' ) )'      
print @strsql      
exec (@strsql)      
--ER0383 till Here      

print @T_ST
print @T_ED
--g
--insert into #T_tcs_energyconsumption(machineid, ampere, gtime, watt, pf, idd, KWH, gtime1, ampere1, kwh1, Volt1, Volt2, Volt3, AmpereR, AmpereY, AmpereB, KVA, EnergySource)
--select machineid, ampere, gtime, watt, pf, idd, KWH, gtime1, ampere1, kwh1, Volt1, Volt2, Volt3, AmpereR, AmpereY, AmpereB, KVA, EnergySource
--from tcs_energyconsumption
--where gtime >= @T_ST and gtime <= @T_ED
--print 'hello'
--select *
-- Type 1      
UPDATE #FinalData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t1.cycle,0) from(      
 select mc,#FinalData.StartTime,#FinalData.EndTime,sum(cycletime+loadunload) as cycle      
 from #T_autodata autodata inner join #FinalData on autodata.mc = #FinalData.machineinterface --ER0383      
 where (autodata.msttime>=#FinalData.StartTime) and (autodata.ndtime<=#FinalData.EndTime)and (autodata.datatype=1)      
 group by autodata.mc,#FinalData.StartTime,#FinalData.EndTime      
) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime      
-- Type 2      
UPDATE #FinalData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t1.cycle,0) from(      
 select mc,#FinalData.StartTime,#FinalData.EndTime,sum(DateDiff(second, #FinalData.StartTime, ndtime)) as cycle      
 from #T_autodata autodata inner join #FinalData on autodata.mc = #FinalData.machineinterface --ER0383      
 where (autodata.msttime<#FinalData.StartTime) and (autodata.ndtime>#FinalData.StartTime) and (autodata.ndtime<=#FinalData.EndTime) and (autodata.datatype=1)      
 group by autodata.mc,#FinalData.StartTime,#FinalData.EndTime      
) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime      
-- Type 3      
UPDATE #FinalData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t1.cycle,0) from(      
 select mc,#FinalData.StartTime,#FinalData.EndTime,sum(DateDiff(second, mstTime, #FinalData.EndTime)) as cycle      
 from #T_autodata autodata inner join #FinalData on autodata.mc = #FinalData.machineinterface--ER0383      
 where (autodata.msttime>=#FinalData.StartTime) and (autodata.msttime<#FinalData.EndTime) and (autodata.ndtime>#FinalData.EndTime) and (autodata.datatype=1)      
 group by autodata.mc,#FinalData.StartTime,#FinalData.EndTime      
) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime      
-- Type 4      
UPDATE #FinalData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t1.cycle,0) from(      
 select mc,#FinalData.StartTime,#FinalData.EndTime,sum(DateDiff(second, #FinalData.StartTime, #FinalData.EndTime)) as cycle      
 from #T_autodata autodata inner join #FinalData on autodata.mc = #FinalData.machineinterface --ER0383      
 where (autodata.msttime<#FinalData.StartTime) and (autodata.ndtime>#FinalData.EndTime) and (autodata.datatype=1)      
 group by autodata.mc,#FinalData.StartTime,#FinalData.EndTime      
) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime      
      
      
----/* Fetching Down Records from Production Cycle  */      
----/* If Down Records of TYPE-2*/      
UPDATE #FinalData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t1.Down,0) from(      
 select A1.mc,#FinalData.StartTime,#FinalData.EndTime,      
 case      
  When A2.sttime >= #FinalData.StartTime AND A2.ndtime <= #FinalData.EndTime Then datediff(s, A2.sttime,A2.ndtime)      
  When A2.sttime < #FinalData.StartTime And A2.ndtime > #FinalData.StartTime AND A2.ndtime<=#FinalData.EndTime Then datediff(s, #FinalData.StartTime,A2.ndtime )      
 end as Down      
 from #T_autodata A1 cross join #T_autodata A2 cross join #FinalData --ER0383      
 where A1.datatype = 1 and A2.datatype = 2      
 and A1.mc = #FinalData.machineinterface and A1.mc = A2.mc      
 and A2.sttime > A1.sttime and A2.ndtime < A1.ndtime      
 and A1.sttime < #FinalData.StartTime      
 and A1.ndtime > #FinalData.StartTime      
 and A1.ndtime <= #FinalData.EndTime      
 and DateDiff(Second,A1.sttime,A1.ndtime)>A1.CycleTime      
) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime      
      
----/* If Down Records of TYPE-3*/      
UPDATE #FinalData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t1.Down,0) from(      
 select A1.mc,#FinalData.StartTime,#FinalData.EndTime,      
 case      
  When A2.sttime >= #FinalData.StartTime AND A2.ndtime <= #FinalData.EndTime Then datediff(s, A2.sttime,A2.ndtime)      
  When A2.sttime>=#FinalData.StartTime And A2.sttime < #FinalData.EndTime and A2.ndtime > #FinalData.EndTime Then datediff(s,A2.sttime, #FinalData.EndTime )      
 end as Down      
 from #T_autodata A1 cross join #T_autodata A2 cross join #FinalData --ER0383      
 where A1.datatype = 1 and A2.datatype = 2      
 and A1.mc = #FinalData.machineinterface and A1.mc = A2.mc      
 and A2.sttime > A1.sttime and A2.ndtime < A1.ndtime      
 and A1.sttime >= #FinalData.StartTime      
 and A1.sttime < #FinalData.EndTime      
 and A1.ndtime > #FinalData.EndTime      
 and DateDiff(Second,A1.sttime,A1.ndtime)>A1.CycleTime      
) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime      
      
----/* If Down Records of TYPE-4*/      
UPDATE #FinalData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t1.Down,0) from(      
 select A1.mc,#FinalData.StartTime,#FinalData.EndTime,      
 case      
  When A2.sttime >= #FinalData.StartTime AND A2.ndtime <= #FinalData.EndTime Then datediff(s, A2.sttime,A2.ndtime)      
  When A2.sttime < #FinalData.StartTime And A2.ndtime > #FinalData.StartTime AND A2.ndtime<=#FinalData.EndTime Then datediff(s, #FinalData.StartTime,A2.ndtime )      
  When A2.sttime>=#FinalData.StartTime And A2.sttime < #FinalData.EndTime and A2.ndtime > #FinalData.EndTime Then datediff(s,A2.sttime, #FinalData.EndTime )      
  When A2.sttime<#FinalData.StartTime AND A2.ndtime>#FinalData.EndTime   Then datediff(s, #FinalData.StartTime,#FinalData.EndTime)      
 end as Down      
 from #T_autodata A1 cross join #T_autodata A2 cross join #FinalData --ER0383      
 where A1.datatype = 1 and A2.datatype = 2      
 and A1.mc = #FinalData.machineinterface and A1.mc = A2.mc      
 and A2.sttime > A1.sttime and A2.ndtime < A1.ndtime      
 and A1.sttime < #FinalData.StartTime      
 and A1.ndtime > #FinalData.EndTime      
 and DateDiff(Second,A1.sttime,A1.ndtime)>A1.CycleTime      
) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime      
      
UPDATE #FinalData SET components = ISNULL(components,0) + ISNULL(t2.comp,0)From(      
 select Autodata.mc,#FinalData.StartTime,#FinalData.EndTime,      
 SUM(CEILING(CAST(autodata.partscount AS Float)/ISNULL(O.SubOperations,1))) as comp      
 from #T_autodata autodata --ER0383      
 inner join #FinalData on autodata.mc = #FinalData.machineinterface      
 Inner join componentinformation C on autodata.Comp = C.interfaceid      
 Inner join ComponentOperationPricing O ON  autodata.Opn = O.interfaceid and C.Componentid=O.componentid      
 inner join Machineinformation on Machineinformation.machineid =O.machineid and autodata.mc=Machineinformation.interfaceid      
 Where Autodata.datatype = 1   
 and Autodata.ndtime > #FinalData.StartTime and Autodata.ndtime <= #FinalData.EndTime      
 Group by Autodata.mc,#FinalData.StartTime,#FinalData.EndTime      
) As T2 Inner join #FinalData on T2.mc = #FinalData.machineinterface and T2.StartTime = #FinalData.StartTime and T2.EndTime = #FinalData.EndTime      
  

 Insert into #Exceptions      
 select Machineinformation.MachineID,C.componentid,O.operationNo,      
 #FinalData.StartTime,#FinalData.EndTime,--pce.StartTime,pce.EndTime,      
 Case when pce.StartTime <= #FinalData.StartTime then #FinalData.StartTime else pce.StartTime End as ExStartTime,      
 Case when pce.EndTime >= #FinalData.EndTime then #FinalData.EndTime else pce.EndTime End as ExEndTime,0,      
 isnull(ActualCount,0),Isnull(IdealCount,1)      
 from #FinalData      
 Inner join Machineinformation on #FinalData.MachineID = Machineinformation.machineid      
 Inner join ComponentOperationPricing O ON  Machineinformation.machineid=O.machineid      
 Inner join componentinformation C on C.Componentid=O.componentid      
 Inner join ProductionCountException pce on pce.machineID = #FinalData.MachineID and pce.ComponentID = C.Componentid and pce.OperationNo = O.OperationNo      
 Where ((#FinalData.StartTime >= pce.StartTime and #FinalData.EndTime <= pce.EndTime)or      
 (#FinalData.StartTime < pce.StartTime and #FinalData.EndTime > pce.StartTime and #FinalData.EndTime <=pce.EndTime)or      
 (#FinalData.StartTime >= pce.StartTime and #FinalData.StartTime <pce.EndTime and #FinalData.EndTime > pce.EndTime) or      
 (#FinalData.StartTime < pce.StartTime and #FinalData.EndTime > pce.EndTime)      
 )--Validate if required. Group by machineinformation.MachineID,C.componentid,O.operationNo,#FinalData.StartTime,#FinalData.EndTime,pce.StartTime,pce.EndTime,IdealCount,ActualCount      
 if (select count(*) from #Exceptions) > 0      
 Begin      
  UPDATE #Exceptions SET ExCount = ISNULL(ExCount,0) + (floor(ISNULL(t2.comp,0) * ISNULL(ActualCount,0))/ISNULL(IdealCount,0)) From(      
   select M.MachineID,C.componentid,O.operationNo,#Exceptions.ExStartTime,#Exceptions.ExEndTime,      
   SUM(CEILING(CAST(autodata.partscount AS Float)/ISNULL(O.SubOperations,1))) as comp      
   from autodata      
   inner join Machineinformation M on autodata.mc=M.interfaceid      
   Inner join componentinformation C on autodata.Comp = C.interfaceid      
   Inner join ComponentOperationPricing O ON  autodata.Opn = O.interfaceid and C.Componentid=O.componentid and M.MachineID = O.MachineID      
   inner join #Exceptions on  #Exceptions.machineId = M.MachineID and #Exceptions.Componentid = C.componentid and #Exceptions.OperationNo = O.OperationNo      
   Where Autodata.datatype = 1 and Autodata.ndtime > #Exceptions.ExStartTime and Autodata.ndtime <= #Exceptions.ExEndTime      
   Group by M.MachineID,C.componentid,O.operationNo,#Exceptions.ExStartTime,#Exceptions.ExEndTime      
  ) As T2 Inner join #Exceptions on T2.MachineID = #Exceptions.MachineID and T2.componentid = #Exceptions.componentid      
  and T2.operationNo = #Exceptions.operationNo and T2.ExStartTime = #Exceptions.ExStartTime and T2.ExEndTime = #Exceptions.ExEndTime    


  Update #FinalData set components = ISNULL(components,0) - ISNULL(ExCount,0) from (      
   Select machineid,StartTime,EndTime,sum(ExCount) as ExCount from #Exceptions      
   group by machineid,StartTime,EndTime      
  ) as t1 inner join #FinalData on t1.machineid = #FinalData.MachineID and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime      
 End      

      
--update #FinalData set StartTime='2018-01-26 08:00:00.000', EndTime='2017-03-28 08:00:00.000' --remove --g


Update #FinalData      
set #FinalData.PF = ISNULL(#FinalData.PF,0)+ISNULL(t1.PF,0)      
--#FinalData.Energy = ISNULL(#FinalData.Energy,0)+ISNULL(t1.kwh,0), --Swathi      
--#FinalData.Cost = ISNULL(#FinalData.Cost,0)+ISNULL(t1.kwh * (Select max(Valueintext) from shopdefaults where Parameter = 'CostPerKWH'),0)      
from (      
 select tcs_energyconsumption.MachineiD,StartTime,EndTime,      
 --avg(tcs_energyconsumption.pf) as PF,      
 --avg(case when tcs_energyconsumption.pf>=0 then tcs_energyconsumption.pf end) as PF, --Swathi      
 avg(Abs(tcs_energyconsumption.pf)) as PF --Swathi      
 --max(kwh)-min(kwh) as kwh --Swathi      
    from tcs_energyconsumption WITH(NOLOCK) inner join #FinalData on --ER0383      
 tcs_energyconsumption.machineID = #FinalData.MachineID and tcs_energyconsumption.gtime >= #FinalData.StartTime      
 and tcs_energyconsumption.gtime <= #FinalData.EndTime --And tcs_energyconsumption.pf >= 0      
 group by tcs_energyconsumption.MachineiD,StartTime,EndTime      
) as t1 inner join #FinalData on t1.machineiD = #FinalData.machineID and      
t1.StartTime = #FinalData.StartTime and t1.endTime = #FinalData.EndTime      
      
Update #FinalData      
set #FinalData.MinEnergy = ISNULL(#FinalData.MinEnergy,0)+ISNULL(t1.kwh,0) from       
(      
select T.MachineiD,T.StartTime,T.EndTime,round(kwh,2) as kwh from       
 (      
 select  tcs_energyconsumption.MachineiD,StartTime,EndTime,      
 min(gtime) as mingtime      
 from tcs_energyconsumption WITH(NOLOCK) inner join #FinalData on ---ER0383      
 tcs_energyconsumption.machineID = #FinalData.MachineID and tcs_energyconsumption.gtime >= #FinalData.StartTime      
 and tcs_energyconsumption.gtime <= #FinalData.EndTime      
 where tcs_energyconsumption.kwh>0 --Swathi Added 07/Jun/2013      
 group by  tcs_energyconsumption.MachineiD,StartTime,EndTime)T      
 inner join tcs_energyconsumption on tcs_energyconsumption.gtime=T.mingtime       
 AND tcs_energyconsumption.MachineID = T.MachineID --DR0359      
 ) as t1       
inner join #FinalData on t1.machineiD = #FinalData.machineID and      
t1.StartTime = #FinalData.StartTime and t1.endTime = #FinalData.EndTime      
      
Update #FinalData      
set #FinalData.MaxEnergy = ISNULL(#FinalData.MaxEnergy,0)+ISNULL(t1.kwh,0) from       
(      
select T.MachineiD,T.StartTime,T.EndTime,round(kwh,2)as kwh from       
 (      
 select  tcs_energyconsumption.MachineiD,StartTime,EndTime,      
 max(gtime) as maxgtime      
 from tcs_energyconsumption WITH(NOLOCK) inner join #FinalData on ----ER0383      
 tcs_energyconsumption.machineID = #FinalData.MachineID and tcs_energyconsumption.gtime >= #FinalData.StartTime      
 and tcs_energyconsumption.gtime <= #FinalData.EndTime      
 group by  tcs_energyconsumption.MachineiD,StartTime,EndTime)T      
 inner join tcs_energyconsumption on tcs_energyconsumption.gtime=T.maxgtime        
 AND tcs_energyconsumption.MachineID = T.MachineID --DR0359      
 ) as t1       
inner join #FinalData on t1.machineiD = #FinalData.machineID and      
t1.StartTime = #FinalData.StartTime and t1.endTime = #FinalData.EndTime      
      
Update #FinalData      
set #FinalData.Energy = ISNULL(#FinalData.Energy,0)+ISNULL(t1.kwh,0),       
#FinalData.Cost = ISNULL(#FinalData.Cost,0)+ISNULL(t1.kwh * (Select max(Valueintext) from shopdefaults where Parameter = 'CostPerKWH'),0)      
from       
(      
 select MachineiD,StartTime,EndTime,round((MaxEnergy - MinEnergy),2) as kwh from #FinalData       
) as t1 inner join #FinalData on t1.machineiD = #FinalData.machineID and      
t1.StartTime = #FinalData.StartTime and t1.endTime = #FinalData.EndTime      

--ER0454
Update #FinalData 
set #FinalData.DGEnergy = isnull(t2.TotalEnergy, 0)
from 
(
SELECT t1.machineid, sum(t1.kwh1-t1.kwh) TotalEnergy, EnergySource, fd.ShiftHourID shiftname
from tcs_energyconsumption t1 inner join #FinalData fd on fd.MachineID = t1.machineid
where t1.gtime >= fd.Starttime and t1.gtime1 <= fd.EndTime and fd.MachineID = t1.machineid
group by t1.machineid, EnergySource, fd.ShiftHourID
)  t2 
inner join #FinalData on t2.machineiD = #FinalData.machineID and t2.EnergySource = 2 and t2.shiftname = #FinalData.ShiftHourID


Update #FinalData 
set #FinalData.EBEnergy = isnull(t2.TotalEnergy, 0)
from 
(
SELECT t1.machineid, sum(t1.kwh1-t1.kwh) TotalEnergy, EnergySource, fd.ShiftHourID shiftname
from tcs_energyconsumption t1 inner join #FinalData fd on fd.MachineID = t1.machineid
where t1.gtime >= fd.Starttime and t1.gtime1 <= fd.EndTime and fd.MachineID = t1.machineid
group by t1.machineid, EnergySource, fd.ShiftHourID
)  t2 
inner join #FinalData on t2.machineiD = #FinalData.machineID and t2.EnergySource = 1 and t2.shiftname = #FinalData.ShiftHourID
--ER0454


---NR0117 From Here  

      
If @View='TechnoLiveScreen'      
Begin 

	Update #Finaldata set InstantaneousVolt1=isnull(#Finaldata.InstantaneousVolt1,0) + isnull(T1.V1,0),InstantaneousVolt2=isnull(#Finaldata.InstantaneousVolt2,0) + isnull(T1.V2,0),      
	InstantaneousVolt3=isnull(#Finaldata.InstantaneousVolt3,0) + isnull(T1.V3,0),Ampere1=isnull(#Finaldata.Ampere1,0)+isnull(T1.A1,0),      
	Ampere2=isnull(#Finaldata.Ampere2,0)+isnull(T1.A2,0),Ampere3=isnull(#Finaldata.Ampere3,0)+isnull(T1.A3,0),KW = isnull(#Finaldata.KW,0)+isnull(T1.KW,0),      
	KVA=isnull(#Finaldata.KVA,0)+isnull(T1.KVA,0),LastArrivalTime=isnull(#Finaldata.LastArrivalTime,'1900-01-01')+ isnull(T1.Lastarrival,'1900-01-01'),      
	LivePF=isnull(#FinalData.LivePF,0)+isnull(T1.PF,0),KWH=isnull(#Finaldata.KWH,0)+isnull(T1.KWH,0) from      
	(      
	select T.MachineiD,T.StartTime,T.EndTime,Volt1 as V1,Volt2 as V2,Volt3 as V3,      
	round(AmpereR,2) as A1,Round(AmpereY,2) as A2,Round(AmpereB,2) as A3,Round(KVA,2) as KVA,Round(watt,2) as KW,      
	maxgtime as LastArrival,round(PF,2) as PF,Round(KWH,2) as KWH from       
	 (      
	 select  TCS.MachineiD,F.StartTime,F.EndTime,max(gtime) as maxgtime      
	 from tcs_energyconsumption TCS WITH(NOLOCK) inner join #FinalData F on       
	 TCS.machineID = F.MachineID       
	 group by  TCS.MachineiD,F.StartTime,F.EndTime)T      
	 inner join tcs_energyconsumption on tcs_energyconsumption.gtime=T.maxgtime        
	 AND tcs_energyconsumption.MachineID = T.MachineID       
	 ) as t1       
	inner join #FinalData on t1.machineiD = #FinalData.machineID and      
	t1.StartTime = #FinalData.StartTime and t1.endTime = #FinalData.EndTime   
END
If @View = 'TechnoDashboard'  
Begin
	Update #Finaldata set Ampere1=isnull(#Finaldata.Ampere1,0)+isnull(T1.A1,0),      
	Ampere2=isnull(#Finaldata.Ampere2,0)+isnull(T1.A2,0),Ampere3=isnull(#Finaldata.Ampere3,0)+isnull(T1.A3,0) from      
	(      
	select T.MachineiD,T.StartTime,T.EndTime,round(AmpereR,2) as A1,Round(AmpereY,2) as A2,Round(AmpereB,2) as A3 from       
	 (      
	 select  TCS.MachineiD,F.StartTime,F.EndTime,Max(gtime) as Maxgtime      
	 from tcs_energyconsumption TCS WITH(NOLOCK) inner join #FinalData F on       
	 TCS.machineID = F.MachineID and TCS.gtime >= F.StartTime and TCS.gtime <= F.EndTime      
	 group by  TCS.MachineiD,F.StartTime,F.EndTime)T      
	 inner join tcs_energyconsumption on tcs_energyconsumption.gtime=T.Maxgtime        
	 AND tcs_energyconsumption.MachineID = T.MachineID       
	 ) as T1       
	inner join #FinalData on t1.machineiD = #FinalData.machineID and      
	t1.StartTime = #FinalData.StartTime and t1.endTime = #FinalData.EndTime    
End


/*      
Update #Finaldata set MinVolt1=isnull(#Finaldata.MinVolt1,0) + isnull(T1.V1,0),MinVolt2=isnull(#Finaldata.MinVolt2,0) + isnull(T1.V2,0)      
,minVolt3=isnull(#Finaldata.minVolt3,0) + isnull(T1.V3,0) from      
(      
select T.MachineiD,T.StartTime,T.EndTime,Volt1 as V1,Volt2 as V2,Volt3 as V3 from       
 (      
 select  TCS.MachineiD,F.StartTime,F.EndTime,min(gtime) as mingtime      
 from tcs_energyconsumption TCS WITH(NOLOCK) inner join #FinalData F on       
 TCS.machineID = F.MachineID and TCS.gtime >= F.StartTime and TCS.gtime <= F.EndTime      
 group by  TCS.MachineiD,F.StartTime,F.EndTime)T      
 inner join tcs_energyconsumption on tcs_energyconsumption.gtime=T.mingtime        
 AND tcs_energyconsumption.MachineID = T.MachineID       
 ) as T1       
inner join #FinalData on t1.machineiD = #FinalData.machineID and      
t1.StartTime = #FinalData.StartTime and t1.endTime = #FinalData.EndTime      
      
Update #Finaldata set MaxVolt1=isnull(#Finaldata.maxVolt1,0) + isnull(T1.V1,0),MaxVolt2=isnull(#Finaldata.MaxVolt2,0) + isnull(T1.V2,0)      
,MaxVolt3=isnull(#Finaldata.MaxVolt3,0) + isnull(T1.V3,0) from      
(      
select T.MachineiD,T.StartTime,T.EndTime,Volt1 as V1,Volt2 as V2,Volt3 as V3 from       
 (      
 select  TCS.MachineiD,F.StartTime,F.EndTime,Max(gtime) as Maxgtime      
 from tcs_energyconsumption TCS WITH(NOLOCK) inner join #FinalData F on       
 TCS.machineID = F.MachineID and TCS.gtime >= F.StartTime and TCS.gtime <= F.EndTime      
 group by  TCS.MachineiD,F.StartTime,F.EndTime)T      
 inner join tcs_energyconsumption on tcs_energyconsumption.gtime=T.Maxgtime        
 AND tcs_energyconsumption.MachineID = T.MachineID       
 ) as T1       
inner join #FinalData on t1.machineiD = #FinalData.machineID and      
t1.StartTime = #FinalData.StartTime and t1.endTime = #FinalData.EndTime      
--NR0117 Till Here      
*/



Update #Finaldata set MinVolt1=isnull(#Finaldata.MinVolt1,0) + isnull(T1.V1,0),MinVolt2=isnull(#Finaldata.MinVolt2,0) + isnull(T1.V2,0)
,minVolt3=isnull(#Finaldata.minVolt3,0) + isnull(T1.V3,0), MinVolt4 = isnull(#Finaldata.MinVolt4,0) + isnull(T1.V4,0), MinVolt5 = isnull(#Finaldata.MinVolt5,0) + isnull(T1.V5,0), MinVolt6 = isnull(#Finaldata.MinVolt6,0) + isnull(T1.V6,0) from
(
	select  TCS.MachineiD,F.StartTime,F.EndTime,min(volt1) as V1,min(volt2) as V2,min(volt3) as V3,min(Volt4) as V4,min(Volt5) as V5,min(Volt6) as V6
	from tcs_energyconsumption TCS WITH(NOLOCK) inner join #FinalData F on 
	TCS.machineID = F.MachineID and TCS.gtime >= F.StartTime and TCS.gtime <= F.EndTime
	group by  TCS.MachineiD,F.StartTime,F.EndTime
) as T1 
inner join #FinalData on t1.machineiD = #FinalData.MachineID and
t1.StartTime = #FinalData.StartTime and t1.endTime = #FinalData.EndTime

Update #Finaldata set MaxVolt1=isnull(#Finaldata.maxVolt1,0) + isnull(T1.V1,0),MaxVolt2=isnull(#Finaldata.MaxVolt2,0) + isnull(T1.V2,0)
,MaxVolt3=isnull(#Finaldata.MaxVolt3,0) + isnull(T1.V3,0),MaxVolt4=isnull(#Finaldata.MaxVolt4,0) + isnull(T1.V4,0),MaxVolt5=isnull(#Finaldata.MaxVolt5,0) + isnull(T1.V5,0),MaxVolt6=isnull(#Finaldata.MaxVolt6,0) + isnull(T1.V6,0) from
(
	select  TCS.MachineiD,F.StartTime,F.EndTime,max(volt1) as V1,max(volt2) as V2,max(volt3) as V3, max(volt4) as V4,max(volt5) as V5,max(volt6) as V6
	from tcs_energyconsumption TCS WITH(NOLOCK) inner join #FinalData F on 
	TCS.machineID = F.MachineID and TCS.gtime >= F.StartTime and TCS.gtime <= F.EndTime
	group by  TCS.MachineiD,F.StartTime,F.EndTime
) as T1 
inner join #FinalData on t1.machineiD = #FinalData.MachineID and
t1.StartTime = #FinalData.StartTime and t1.endTime = #FinalData.EndTime
   
      
If @View = '' --NR0117      
Begin --NR0117      
 Select      
 MachineID,      
 ShiftHourID,      
 StartTime,      
 EndTime,      
 dbo.f_FormatTime(UtilisedTime,'HH:MM:SS') as UtilisedTime,      
 Components,      
 round(PF,2) as PF,      
 round(Energy * (Select top 1 valueintext from shopdefaults where parameter = 'CostPerKWH'),2) as Cost,      
 round(Energy,2)as Energy,
 round(EBEnergy, 2) as EBEnergy, --ER0454
 round(DGEnergy, 2) as DGEnergy  --ER0454
 --round(Energy,2)* 100 as Energy      
 from #FinalData order by MachineID      
end --NR0117      
  
  
Update  #FinalData set target = isnull(#FinalData.target,0) + isnull(T1.target,0) from    
(Select #Finaldata.Machineid,#Finaldata.Starttime,case when @Parameter = 'Day' then E.Target else ((E.Target*Datediff(HOUR,Starttime,Endtime))/24) end as target from    
#Finaldata inner join Energy_Target E on #finaldata.machineid=E.Machineid)T1 inner join  #FinalData on #FinalData.Machineid=T1.Machineid    
 and #FinalData.Starttime=T1.Starttime  
  
--NR0117 Added From here      
If @View = 'TechnoDashboard'      
Begin      
 Select      
 MachineID,      
 ShiftHourID,      
 StartTime,      
 EndTime,      
 dbo.f_FormatTime(UtilisedTime,'HH:MM:SS') as ProductionTime,      
 Components as ProductionCount,      
 round(PF,2) as PowerFactor,      
 round(Energy * (Select top 1 valueintext from shopdefaults where parameter = 'CostPerKWH'),2) as Cost,      
 round(Energy,2)as Energy,      
 round(DGEnergy, 2) as DGEnergy, --ER0454
 round(EBEnergy, 2) as EBEnergy, --ER0454
 cast(MinVolt1 as nvarchar(50))+ ' \ ' + cast(MaxVolt1 as nvarchar(50)) as Volt1,
 cast(MinVolt2 as nvarchar(50))+ ' \ ' + cast(MaxVolt2 as nvarchar(50)) as Volt2,      
 cast(MinVolt3 as nvarchar(50))+ ' \ ' + cast(MaxVolt3 as nvarchar(50)) as Volt3,    
 Round(Target,0) as Target,
 round(Ampere1,2) as AmpereR,
 round(Ampere2,2) as AmpereB,
 round(Ampere3,2) as AmpereY,
 cast(MinVolt4 as nvarchar(50))+ ' \ ' + cast(MaxVolt4 as nvarchar(50)) as Volt4,
 cast(MinVolt5 as nvarchar(50))+ ' \ ' + cast(MaxVolt5 as nvarchar(50)) as Volt5,      
 cast(MinVolt6 as nvarchar(50))+ ' \ ' + cast(MaxVolt6 as nvarchar(50)) as Volt6
 from #FinalData order by MachineID      
end      
      
If @View='TechnoLiveScreen'      
Begin    
 Select      
 MachineID,LastArrivalTime,InstantaneousVolt1 as V1,InstantaneousVolt2 as V2,InstantaneousVolt3 as V3,Ampere1 as AR ,Ampere2 as AY,Ampere3 as AB ,      
 KW,KWH,KVA,round(LivePF,2) as PF,Round(Target,0) as Target, round(Energy,2)as Energy, round(DGEnergy, 2) as DGEnergy, round(EBEnergy, 2) as EBEnergy --ER0454
  from #Finaldata order by Machineid,Lastarrivaltime   
End      
--NR0117 Added till Here      

end 
