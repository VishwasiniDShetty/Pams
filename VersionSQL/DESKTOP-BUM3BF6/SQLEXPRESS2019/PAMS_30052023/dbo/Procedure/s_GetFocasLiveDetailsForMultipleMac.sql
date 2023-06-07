/****** Object:  Procedure [dbo].[s_GetFocasLiveDetailsForMultipleMac]    Committed by VersionSQL https://www.versionsql.com ******/

              
 --[dbo].[s_GetFocasLiveDetailsForMultipleMac]'2019-04-13 06:00:00','','','J300-1','summary',''            
 --[dbo].[s_GetFocasLiveDetailsForMultipleMac]'2016-02-08 13:00:00','','','FIER-H','Alarmcount'              
 --[dbo].[s_GetFocasLiveDetailsForMultipleMac]'2016-05-05 15:00:00','B','','Jobber-01','summary'              
 --[dbo].[s_GetFocasLiveDetailsForMultipleMac]'2015-09-08','day','','TURN MILL-02','Alarmcount'              
 --[dbo].[s_GetFocasLiveDetailsForMultipleMac]'2015-10-08 06:00:00','day','','TURN MILL-02','stoppages'              
 --[dbo].[s_GetFocasLiveDetailsForMultipleMac]'2015-09-08','day','','CNC GRINDING','PreventiveAlarmcount'    
-- exec [dbo].[s_GetFocasLiveDetailsForMultipleMac] @date=N'2020-04-07',@ShiftName=N'',@plantId=N'',@MachineId=N'',@param=N''                 
CREATE PROCEDURE [dbo].[s_GetFocasLiveDetailsForMultipleMac]                
 @Date datetime ='',              
 @Shiftname nvarchar(50)='',                
 @PlantID nvarchar(50),                
 @Machineid nvarchar(1000)='',                
 @Param nvarchar(50)='',              
 @type nvarchar(50)=''              
              
WITH RECOMPILE              
AS              
BEGIN              
               
 SET NOCOUNT ON;              
              
if (@Date>getdate())              
Begin              
set @Date=getdate()              
End              
Create Table #LiveDetails                
(                
 [Sl No] Bigint Identity(1,1) Not Null,                
 [Machineid] nvarchar(50),                
 [MachineStatus] nvarchar(100),              
 [RunningProgram] nvarchar(100),              
 [ShiftDate] datetime,                
 [ShiftName] nvarchar(50),                
 [From time] datetime,                
 [To Time] datetime,                
 [TotalTime] float,              
 [Powerontime] float,                
 [Cutting time] float,                
 [Operating time] float,              
 [PartsCount] int,               
 [ProgramNo] nvarchar(50),              
 [TotalTimeInPer] float,              
 [PowerontimeInPer] float,                
 [Cutting timeInPer] float,              
 [OperatingtimeInPer] float,            
 [Target] float,            
 [OEE] float              
)                
              
CREATE TABLE #ShiftDetails                 
(                
 SlNo bigint identity(1,1) NOT NULL,              
 PDate datetime,                
 Shift nvarchar(20),                
 ShiftStart datetime,                
 ShiftEnd datetime                
)                
              
Create table #Day              
(              
[From Time] datetime,              
[To time] datetime              
)                
              
CREATE TABLE #HourDetails                 
(                
 PDate datetime,                
 Shift nvarchar(20),                
 HourStart datetime,                
 HourEnd datetime                
)               
              
CREATE TABLE #MachinewiseStoppages              
(              
 id bigint identity(1,1),              
 Machineid nvarchar(50),              
 Fromtime datetime,              
 Totime datetime,              
 BatchTS datetime,              
 BatchStart datetime,              
 BatchEnd datetime,              
 Stoppagetime int,              
 MachineStatus nvarchar(50),              
 Reason nvarchar(50),              
 AlarmStatus nvarchar(50),
 TotalStoppage float              
)              
 
 CREATE TABLE #AlarmCount
(
	MachineId nvarchar(100),
	TotalCNCAlarms int default 0,
	NewCNCAlarms int default 0,
	TotalPreventiveAlerts int default 0,
	NewPreventiveAlerts int default 0,
	TotalPredictiveAlerts int default 0,
	NewPredictiveAlerts int default 0
)

INSERT INTO #AlarmCount(MachineId)
select distinct Machineid from machineinformation


Declare @strsql nvarchar(4000)                
Declare @strmachine nvarchar(2000)                
Declare @StrPlantid as nvarchar(1000)                
Declare @CurStrtTime as datetime                
declare @shift as nvarchar(1000)                
                
Select @strsql = ''                
Select @strmachine = ''                
select @strPlantID = ''                
Select @shift =''                
                
   DEclare @CurrDate datetime
 SET @CurrDate = convert(nvarchar(20),getdate(),120)            
                
if isnull(@PlantID,'') <> ''                
Begin                
 Select @strPlantID = ' and ( PlantMachine.PlantID = N''' + @PlantID + ''')'                
End              
              
If @param = 'AlarmCount'              
Begin              
              
   Declare @StartTime as datetime              
   Declare @EndTime as datetime              
   Declare @Curtime as datetime              
              
 select @curtime= getdate()              
 select @StartTime = dateadd(minute,-15,@curtime)              
 Select @endtime = @curtime       
              
   Select sum(T.NOofOccurences) NOofOccurences              
   from (                   
   select A.Alarmno as AlarmNo,A.AlarmMSG as AlarmMessage,Count(A.AlarmNo) as NOofOccurences,Min(A.AlarmTime) as MinAlarmTime,Max(A.AlarmTime) as MaxAlarmtime                  
   from Focas_AlarmHistory a left outer join Focas_AlarmCategory c on  a.AlarmGroupNo = c.AlarmNo                  
   where (a.AlarmTime between @StartTime and  @EndTime) and  a.AckStatus IS NULL              
   and a.machineId=@MachineID  and ( a.AlarmNo < 1150  OR a.AlarmNo > 1172 ) Group by A.Alarmno,A.AlarmMSG)T               
                 
 return              
End              
              
If @param = 'PreventiveAlarmCount'              
Begin              
              
              
 select @curtime= getdate()              
 select @StartTime = dateadd(minute,-15,@curtime)              
 Select @endtime = @curtime              
              
   Select sum(T.NOofOccurences) NOofOccurences              
   from (                   
   select A.Alarmno as AlarmNo,A.AlarmMSG as AlarmMessage,Count(A.AlarmNo) as NOofOccurences,Min(A.AlarmTime) as MinAlarmTime,Max(A.AlarmTime) as MaxAlarmtime                  
   from Focas_AlarmHistory a left outer join Focas_AlarmCategory c on  a.AlarmGroupNo = c.AlarmNo                  
   where (AlarmTime between @StartTime and  @EndTime)    and ( a.AlarmNo >= 1150  and a.AlarmNo <= 1172 ) and  a.AckStatus IS NULL              
   and machineId=@MachineID Group by A.Alarmno,A.AlarmMSG)T               
                 
 return              
End              
              
              
Select @CurStrtTime=@Date              
              
INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)                 
EXEC s_GetShiftTime @CurStrtTime,@Shiftname                
              
              
If (@Shiftname<>'DAY') and @param<>'Summary' and @param<>'OEMSummary' and @type<>'OEMHour'               
Begin                
 Insert into #LiveDetails (Machineid,ShiftDate,[From time],[To Time],ShiftName,[Cutting time],Powerontime,[Operating Time],[PartsCount],[ProgramNo],[PowerontimeInPer])   --SV              
 SELECT distinct Machineinformation.machineid,S.PDate,S.shiftstart,S.shiftend,S.Shift,0,0,0,0,0,0 FROM dbo.Machineinformation                
 left outer join dbo.Plantmachine on Machineinformation.machineid=Plantmachine.machineid                
 Cross join #ShiftDetails S where (@machineid='' or MachineInformation.MachineID=@machineid) and (@PlantID='' or PlantMachine.PlantID=@PlantID)              
        
		 Update #AlarmCount set TotalCNCAlarms=T1.TatalCnt
		 from(select FA.MachineID,Count( FA.AlarmNo) as TatalCnt from Focas_AlarmHistory FA
			cross JOIN #ShiftDetails S 
			Where (FA.AlarmTime between S.ShiftStart and S.ShiftEnd) and ( FA.AlarmNo < 1150  or FA.AlarmNo > 1172 )
		group by FA.MachineID)T1 inner join #AlarmCount on #AlarmCount.MachineId=T1.MachineID

		 Update #AlarmCount set NewCNCAlarms=T1.TatalCnt
		 from(select FA.MachineID,Count(FA.AlarmNo) as TatalCnt from Focas_AlarmHistory FA
		 inner join AlarmLastSyncDateTime ALT on FA.MachineID=ALT.MachineID and FA.AlarmTime between ALT.AlarmLastSyncTime and @CurrDate
			--Where FA.AlarmTime between (select ValueInText from Focas_Defaults where Parameter='FocasAlarmLastRefreshedTime') and @CurrDate
			where  ( FA.AlarmNo < 1150  or FA.AlarmNo > 1172 )
		group by FA.MachineID)T1 inner join #AlarmCount on #AlarmCount.MachineId=T1.MachineID

		 Update #AlarmCount set TotalPreventiveAlerts=T1.TatalCnt
		 from(select FA.MachineID,Count(FA.AlarmNo) as TatalCnt from Focas_AlarmHistory FA
			cross JOIN #ShiftDetails S 
			Where (FA.AlarmTime between S.ShiftStart and S.ShiftEnd)
			and ( FA.AlarmNo >= 1150  and FA.AlarmNo <= 1172 ) 
		group by FA.MachineID)T1 inner join #AlarmCount on #AlarmCount.MachineId=T1.MachineID

		 Update #AlarmCount set NewPreventiveAlerts=T1.TatalCnt
		 from(select FA.MachineID,Count(FA.AlarmNo) as TatalCnt from Focas_AlarmHistory FA
		 inner join AlarmLastSyncDateTime ALT on FA.MachineID=ALT.MachineID and FA.AlarmTime between ALT.PreventiveLastSyncTime and @CurrDate
			Where --(FA.AlarmTime between (select ValueInText from Focas_Defaults where Parameter='FocasPreventiveLastRefreshedTime') and @CurrDate) and
			 ( FA.AlarmNo >= 1150  and FA.AlarmNo <= 1172 )
		group by FA.MachineID)T1 inner join #AlarmCount on #AlarmCount.MachineId=T1.MachineID

		 Update #AlarmCount set TotalPredictiveAlerts=T1.TatalCnt
		 from(select FA.MachineID,Count( FA.AlarmNo) as TatalCnt from Focas_PredictiveMaintenance FA
			cross JOIN #ShiftDetails S 
			Where FA.TimeStamp between S.ShiftStart and S.ShiftEnd
		group by FA.MachineID)T1 inner join #AlarmCount on #AlarmCount.MachineId=T1.MachineID

		 Update #AlarmCount set NewPredictiveAlerts=T1.TatalCnt
		 from(select FA.MachineID,Count( FA.AlarmNo) as TatalCnt from Focas_PredictiveMaintenance FA
		 inner join AlarmLastSyncDateTime ALT on FA.MachineID=ALT.MachineID and FA.TimeStamp between ALT.PredictiveLastSyncTime and @CurrDate
			--Where FA.TimeStamp between (select ValueInText from Focas_Defaults where Parameter='FocasPredictiveLastRefreshedTime') and @CurrDate
		group by FA.MachineID)T1 inner join #AlarmCount on #AlarmCount.MachineId=T1.MachineID

End              
              
              
              
if (@Shiftname='DAY') and @param<>'Summary' and @param<>'OEMSummary' and @type<>'OEMHour'               
BEGIN              
              
 Insert into #day([From Time],[To time])              
 Select dbo.f_GetLogicalDay(@Date,'start'),dbo.f_GetLogicalDay(@Date,'End')              
              
 Insert into #LiveDetails (Machineid,ShiftDate,[From time],[To Time],ShiftName,[Cutting time],Powerontime,[Operating Time],[PartsCount],[ProgramNo])  --SV              
 SELECT distinct Machineinformation.machineid,0,s.[From Time],s.[To time],0,0,0,0,0,0 FROM dbo.Machineinformation  --SV              
 left outer join dbo.Plantmachine on Machineinformation.machineid=Plantmachine.machineid                
 Cross join #day S where (@machineid='' or MachineInformation.MachineID=@machineid) and (@PlantID='' or PlantMachine.PlantID=@PlantID)              
      
	  	 Update #AlarmCount set TotalCNCAlarms=T1.TatalCnt
		 from(select FA.MachineID,Count( FA.AlarmNo) as TatalCnt from Focas_AlarmHistory FA
			cross JOIN #day S 
			Where (FA.AlarmTime between S.[From Time] and S.[To time]) and ( FA.AlarmNo < 1150  or FA.AlarmNo > 1172 )
		group by FA.MachineID)T1 inner join #AlarmCount on #AlarmCount.MachineId=T1.MachineID

		 Update #AlarmCount set NewCNCAlarms=T1.TatalCnt
		 from(select FA.MachineID,Count( FA.AlarmNo) as TatalCnt from Focas_AlarmHistory FA
		 inner join AlarmLastSyncDateTime ALT on FA.MachineID=ALT.MachineID and FA.AlarmTime between ALT.AlarmLastSyncTime and @CurrDate
			--Where FA.AlarmTime between (select ValueInText from Focas_Defaults where Parameter='FocasAlarmLastRefreshedTime') and @CurrDate
			where  ( FA.AlarmNo < 1150  or FA.AlarmNo > 1172 )
		group by FA.MachineID)T1 inner join #AlarmCount on #AlarmCount.MachineId=T1.MachineID

		 Update #AlarmCount set TotalPreventiveAlerts=T1.TatalCnt
		 from(select FA.MachineID,Count( FA.AlarmNo) as TatalCnt from Focas_AlarmHistory FA
			cross JOIN #day S 
			Where FA.AlarmTime between S.[From Time] and S.[To time]
			and ( FA.AlarmNo >= 1150  and FA.AlarmNo <= 1172 )
		group by FA.MachineID)T1 inner join #AlarmCount on #AlarmCount.MachineId=T1.MachineID

		 Update #AlarmCount set NewPreventiveAlerts=T1.TatalCnt
		 from(select FA.MachineID,Count( FA.AlarmNo) as TatalCnt from Focas_AlarmHistory FA
		 inner join AlarmLastSyncDateTime ALT on FA.MachineID=ALT.MachineID and FA.AlarmTime between ALT.PreventiveLastSyncTime and @CurrDate
			Where --(FA.AlarmTime between (select ValueInText from Focas_Defaults where Parameter='FocasPreventiveLastRefreshedTime') and @CurrDate) and
			 ( FA.AlarmNo >= 1150  and FA.AlarmNo <= 1172 )
		group by FA.MachineID)T1 inner join #AlarmCount on #AlarmCount.MachineId=T1.MachineID

		 Update #AlarmCount set TotalPredictiveAlerts=T1.TatalCnt
		 from(select FA.MachineID,Count( FA.AlarmNo) as TatalCnt from Focas_PredictiveMaintenance FA
			cross JOIN #day S 
			Where FA.TimeStamp between S.[From Time] and S.[To time]
		group by FA.MachineID)T1 inner join #AlarmCount on #AlarmCount.MachineId=T1.MachineID

		 Update #AlarmCount set NewPredictiveAlerts=T1.TatalCnt
		 from(select FA.MachineID,Count( FA.AlarmNo) as TatalCnt from Focas_PredictiveMaintenance FA
		 inner join AlarmLastSyncDateTime ALT on FA.MachineID=ALT.MachineID and FA.TimeStamp between ALT.PredictiveLastSyncTime and @CurrDate
			--Where FA.TimeStamp between (select ValueInText from Focas_Defaults where Parameter='FocasPredictiveLastRefreshedTime') and @CurrDate
		group by FA.MachineID)T1 inner join #AlarmCount on #AlarmCount.MachineId=T1.MachineID
end              
              
if @Param='Summary'              
BEGIN              
 Declare  @CountOfRows as int              
 Declare @i as int              
 Declare @Shiftstart as datetime              
 Declare @shiftend as datetime              
 Declare @Pdate as datetime              
 Declare @sname as nvarchar(20)              
 Select @i = 1              
              
 Select @CountOfRows = Count(*) from #ShiftDetails              
 Select @Pdate=Pdate,@sname=Shift,@shiftstart = ShiftStart,@shiftend = shiftend from #ShiftDetails where slno=@i              
              
 While @i <= @CountOfRows              
 Begin              
   While @shiftstart<@shiftend              
   Begin              
   INSERT #HourDetails(Pdate, Shift, HourStart, HourEnd)                
   Select @Pdate, @sname, @shiftstart,case when DATEADD(HOUR,1,@shiftstart)>@shiftend then @shiftend else DATEADD(HOUR,1,@shiftstart) end               
   SELECT @shiftstart=DATEADD(HOUR,1,@shiftstart)                
   End              
   Select @i = @i + 1              
   Select @Pdate=Pdate,@sname=Shift,@shiftstart = ShiftStart,@shiftend = shiftend from #ShiftDetails where slno=@i              
   END              
              
 Insert into #LiveDetails (Machineid,ShiftDate,[From time],[To Time],ShiftName,[Cutting time],Powerontime,[Operating Time],[PartsCount],[ProgramNo])               
 SELECT distinct Machineinformation.machineid,S.PDate,S.Hourstart,S.Hourend,S.Shift,0,0,0,0,0 FROM dbo.Machineinformation                
 left outer join dbo.Plantmachine on Machineinformation.machineid=Plantmachine.machineid                
 Cross join #HourDetails S where (MachineInformation.MachineID=@machineid) and (@PlantID='' or PlantMachine.PlantID=@PlantID)              
              
END              
              
              
if @Param='OEMSummary' or  @type='OEMHour'               
BEGIN              
               
              
              
 Declare @Refshiftstart as datetime       declare @Refshiftend as datetime              
              
 IF @type = 'OEMHour'              
 Begin              
              
--   Select @shiftstart = Dateadd(hour,-23,@date)              
--   Select @Shiftend = dateadd(hour,1,@date)              
  Select @shiftstart = dbo.f_GetLogicalDay(@Date,'start')              
  Select @Shiftend = dbo.f_GetLogicalDay(@Date,'End')              
              
  While @shiftstart<@shiftend              
  Begin              
   INSERT #HourDetails(HourStart, HourEnd)                
   Select @shiftstart,case when DATEADD(HOUR,1,@shiftstart)>@shiftend then @shiftend else DATEADD(HOUR,1,@shiftstart) end               
   SELECT @shiftstart=DATEADD(HOUR,1,@shiftstart)                
  End              
                
 End              
              
 If @param='OEMSummary'               
 Begin              
              
              
--  Select @shiftstart = Dateadd(hour,-23,@date)              
--   Select @Shiftend = dateadd(hour,1,@date)              
              
  Select @shiftstart = dbo.f_GetLogicalDay(@Date,'start')              
  Select @Shiftend = dbo.f_GetLogicalDay(@Date,'End')              
              
              
  --Select @shiftstart = Min(cnctimestamp) from dbo.focas_livedata with(NOLOCK) where (@machineid='' or MachineID=@machineid) and cnctimestamp>=Dateadd(hour,-23,@date) and cnctimestamp<=DATEADD(HOUR,1,@date )              
     Select @Refshiftstart = @shiftstart              
  --Select @Shiftend = Max(cnctimestamp) from dbo.focas_livedata with(NOLOCK) where (@machineid='' or MachineID=@machineid) and cnctimestamp>=Dateadd(hour,-23,@date) and cnctimestamp<=DATEADD(HOUR,1,@date )              
  Select @Refshiftend = @Shiftend              
              
              
--  INSERT #HourDetails(HourStart, HourEnd)                
--  Select @Refshiftstart,@Refshiftend              
 End              
              
 Insert into #LiveDetails (Machineid,[From time],[To Time],[Cutting time],Powerontime,[Operating Time],[PartsCount],[ProgramNo])               
 SELECT distinct Machineinformation.machineid,S.Hourstart,S.Hourend,0,0,0,0,0 FROM dbo.Machineinformation                
 left outer join dbo.Plantmachine on Machineinformation.machineid=Plantmachine.machineid                
 Cross join #HourDetails S where (MachineInformation.MachineID=@machineid) and (@PlantID='' or PlantMachine.PlantID=@PlantID)              
END              
              
declare @DataStart as datetime              
declare @DataEnd as datetime              
              
select @DataStart= (select top 1 [From Time] from #LiveDetails order by [From Time])              
select @DataEnd = (select top 1 [To Time] from #LiveDetails order by [From Time] desc)              
              
select MachineID, MachineStatus, MachineMode, ProgramNo, PowerOnTime, OperatingTime, CutTime, CNCTimeStamp, PartsCount, BatchTS, MachineUpDownStatus, MachineUpDownBatchTS              
into #FocasLivedata from dbo.focas_livedata with(NOLOCK) where cnctimestamp>=@DataStart and cnctimestamp<=@DataEnd              
              
              
declare @threshold as int              
Select @threshold = isnull(ValueInText,10) from Focas_Defaults where parameter='DowntimeThreshold'              
              
              
If @threshold = '' or @threshold is NULL              
Begin              
 select @threshold='10'              
End              
              
if @param='Stoppages' or @param='RuntimeandDowntime'              
Begin              
  insert into #MachinewiseStoppages(Machineid,fromtime,totime,BatchTS,Batchstart,BatchEnd,MachineStatus)              
  select L1.Machineid,L1.[From Time],L1.[To Time],F.machineupdownbatchts,min(F.cnctimestamp),max(F.cnctimestamp)              
  ,case when F.machineupdownstatus=0 then 'Down'              
  when F.machineupdownstatus=1 then 'Prod' end from #FocasLivedata F with(NOLOCK)              
  inner join #LiveDetails L1 on L1.machineid=F.machineid and F.cnctimestamp>=L1.[From Time] and F.cnctimestamp<=L1.[To Time]              
  where F.machineupdownbatchts is not null              
  group by L1.Machineid,L1.[From Time],L1.[To Time],F.machineupdownbatchts,F.machineupdownstatus              
  order by L1.Machineid,L1.[From Time],F.machineupdownbatchts              
              
  update #MachinewiseStoppages set Stoppagetime = datediff(s,Batchstart,BatchEnd)              
    
  update #MachinewiseStoppages set TotalStoppage = T1.TotalStoppage from
  (Select Machineid,SUM(Stoppagetime) as TotalStoppage from  #MachinewiseStoppages 
   where Stoppagetime>(@threshold) and MachineStatus='Down' Group by Machineid)T1 
  inner join #MachinewiseStoppages on #MachinewiseStoppages.Machineid=T1.Machineid
          
  if @param='Stoppages'              
  Begin              
   --select Machineid,Batchstart,BatchEnd,dbo.f_FormatTime(Stoppagetime,'hh:mm:ss') as Stoppagetime,Reason from #MachinewiseStoppages               
   select Machineid,Batchstart,BatchEnd,dbo.f_FormatTime(Stoppagetime,'hh:mm:ss') as Stoppagetime,Reason,dbo.f_FormatTime(TotalStoppage,'hh:mm:ss') as TotalStoppage from #MachinewiseStoppages               
   where Stoppagetime>(@threshold) and MachineStatus='Down' order by Machineid,Batchstart              
   return              
  End              
              
  if @param='RuntimeandDowntime'              
  Begin              
              
   select M1.fromtime,M1.totime,M1.machineid,max(M1.batchend) as starttime,M2.batchstart as endtime into #NOdata from #MachinewiseStoppages M1               
   inner join #MachinewiseStoppages M2 on M1.machineid=M2.machineid              
   where M1.id<M2.id group by M1.fromtime,M1.totime,M1.machineid,M2.batchstart              
              
   Insert into #MachinewiseStoppages(Machineid,fromtime,totime,Batchstart,BatchEnd,Stoppagetime,MachineStatus)              
   select Machineid,fromtime,totime,starttime,endtime,datediff(s,starttime,endtime),'NO_DATA' from #NOdata where datediff(n,starttime,endtime)>1              
   order by Machineid,fromtime,starttime              
              
   select Machineid,Batchstart,BatchEnd,dbo.f_FormatTime(Stoppagetime,'hh:mm:ss') as Stoppagetime,MachineStatus as Reason from #MachinewiseStoppages               
   order by Machineid,Batchstart              
   return              
  End              
END              
              
              
if @param='OEMStoppages' or @param='OEMRuntimeandDowntime' or @param='OEMRuntimechart'              
Begin              
                
  delete from #livedetails              
  delete from #day              
              
  If @param='OEMStoppages'              
  Begin              
              
      Insert into #day([From Time],[To time])           
--      Select dateadd(hour,-23,@Date),dateadd(hour,1,@date)              
   Select dbo.f_GetLogicalDay(@Date,'start'),dbo.f_GetLogicalDay(@Date,'End')              
              
  End              
              
  If @param='OEMRuntimeandDowntime'              
  Begin              
              
      Insert into #day([From Time],[To time])              
      Select dateadd(hour,-3,@Date),dateadd(hour,1,@date)              
              
  End              
              
  If @param='OEMRuntimechart'              
  Begin              
              
      Insert into #day([From Time],[To time])              
      Select @Date,dateadd(hour,4,@date)              
              End              
              
  Insert into #LiveDetails (Machineid,ShiftDate,[From time],[To Time],ShiftName,[Cutting time],Powerontime,[Operating Time],[PartsCount],[ProgramNo])  --SV              
  SELECT distinct Machineinformation.machineid,0,s.[From Time],s.[To time],0,0,0,0,0,0 FROM dbo.Machineinformation  --SV              
  left outer join dbo.Plantmachine on Machineinformation.machineid=Plantmachine.machineid                
  Cross join #day S where (@machineid='' or MachineInformation.MachineID=@machineid) and (@PlantID='' or PlantMachine.PlantID=@PlantID)              
              
              
  select @DataStart= (select top 1 [From Time] from #LiveDetails order by [From Time])              
select @DataEnd = (select top 1 [To Time] from #LiveDetails order by [From Time] desc)              
              
  select MachineID, MachineStatus, MachineMode, ProgramNo, PowerOnTime, OperatingTime, CutTime, CNCTimeStamp, PartsCount, BatchTS, MachineUpDownStatus, MachineUpDownBatchTS              
  into #FocasLivedata1 from dbo.focas_livedata with(NOLOCK) where cnctimestamp>=@DataStart and cnctimestamp<=@DataEnd              
              
              
  Select @threshold = isnull(ValueInText,10) from Focas_Defaults where parameter='DowntimeThreshold'              
              
              
  If @threshold = '' or @threshold is NULL              
  Begin              
   select @threshold='10'              
  End              
              
  insert into #MachinewiseStoppages(Machineid,fromtime,totime,BatchTS,Batchstart,BatchEnd,MachineStatus)              
  select L1.Machineid,L1.[From Time],L1.[To Time],F.machineupdownbatchts,min(F.cnctimestamp),max(F.cnctimestamp)              
  ,case when F.machineupdownstatus=0 then 'Down'              
  when F.machineupdownstatus=1 then 'Prod' end from #FocasLivedata1 F with(NOLOCK)              
  inner join #LiveDetails L1 on L1.machineid=F.machineid and F.cnctimestamp>=L1.[From Time] and F.cnctimestamp<=L1.[To Time]              
  where F.machineupdownbatchts is not null              
  group by L1.Machineid,L1.[From Time],L1.[To Time],F.machineupdownbatchts,F.machineupdownstatus              
  order by L1.Machineid,L1.[From Time],F.machineupdownbatchts              
              
  update #MachinewiseStoppages set Stoppagetime = datediff(s,Batchstart,BatchEnd)              
              
  if @param='OEMStoppages'              
  Begin              
              
   update #MachinewiseStoppages set AlarmStatus = T.Status from              
   (select M.Machineid,M.Batchstart,M.BatchEnd,'Red' as status from #MachinewiseStoppages M              
   inner join Focas_AlarmHistory A on  M.Machineid=A.machineid              
   left outer join Focas_AlarmMaster F on A.Alarmno=F.AlarmNo                  
   left outer join Focas_AlarmCategory c on  a.AlarmGroupNo = c.AlarmNo              
    where (A.AlarmTime between M.Batchstart and M.BatchEnd) and M.MachineStatus='Down')T inner join #MachinewiseStoppages M on T.Machineid=M.Machineid and M.Batchstart=T.Batchstart              
   and M.BatchEnd=T.BatchEnd              
              
   select Machineid,Batchstart,BatchEnd,dbo.f_FormatTime(Stoppagetime,'hh:mm:ss') as Stoppagetime,Reason from #MachinewiseStoppages               
   where Stoppagetime>(@threshold) and MachineStatus='Down' order by Machineid,Batchstart              
   return              
  End              
              
  if @param='OEMRuntimeandDowntime' or  @param='OEMRuntimechart'              
  Begin              
              
   select M1.fromtime,M1.totime,M1.machineid,max(M1.batchend) as starttime,M2.batchstart as endtime into #NOdata1 from #MachinewiseStoppages M1               
   inner join #MachinewiseStoppages M2 on M1.machineid=M2.machineid              
   where M1.id<M2.id group by M1.fromtime,M1.totime,M1.machineid,M2.batchstart              
              
   Insert into #MachinewiseStoppages(Machineid,fromtime,totime,Batchstart,BatchEnd,Stoppagetime,MachineStatus)              
   select Machineid,fromtime,totime,starttime,endtime,datediff(s,starttime,endtime),'NO_DATA' from #NOdata1 where datediff(minute,starttime,endtime)>1              
   order by Machineid,fromtime,starttime              
              
   select Machineid,Batchstart,BatchEnd,dbo.f_FormatTime(Stoppagetime,'hh:mm:ss') as Stoppagetime,MachineStatus as Reason from #MachinewiseStoppages               
   order by Machineid,Batchstart              
   return              
  End              
END              
              
If @param<>'Summary' and @param<>'OEMSummary' and @type<>'OEMHour'               
Begin              
              
 Update #LiveDetails Set [RunningProgram] = t.RunningProgram from              
  (SELECT  X.RunningProgram,X.MachineID from               
 (              
 SELECT  t.Programno as RunningProgram,t.MachineID, RANK() OVER(PARTITION BY t.MachineID  ORDER BY t.CNCTimeStamp desc) num              
 FROM focas_livedata t with(NOLOCK)              
 ) X           
 WHERE num = 1)t inner join #LiveDetails              
 on t.MachineId=#LiveDetails.MachineID              
              
              
              
 Update #LiveDetails Set [MachineStatus] = t.[MachineStatus] from              
  (SELECT  X.MachineStatus,X.MachineID from               
 (              
 SELECT  t.MachineStatus,t.MachineID, RANK() OVER(PARTITION BY t.MachineID  ORDER BY t.CNCTimeStamp desc) num              
 FROM focas_livedata t with(NOLOCK)              
 ) X              
 WHERE num = 1)t inner join #LiveDetails              
 on t.MachineId=#LiveDetails.MachineID              
              
END              
              
Update #LiveDetails set [Powerontime]  = isnull(#LiveDetails.[Powerontime] ,0) + isnull(T2.Powerontime,0),              
[Cutting time]  = isnull([Cutting time] ,0) + isnull(T2.Cuttingtime,0),                
[Operating time]  = isnull([Operating time] ,0) + isnull(T2.Operatingtime,0)  From                
(select L.[From Time]  as TS,F.machineid,Max(F.Powerontime)-Min(F.Powerontime) as Powerontime,              
Max(Cuttime)-Min(Cuttime) as Cuttingtime,Max(Operatingtime)-Min(Operatingtime) as Operatingtime from #FocasLivedata F  with(NOLOCK)              
inner join #LiveDetails L on L.machineid=F.machineid and F.cnctimestamp>=L.[From Time]  and F.cnctimestamp<=L.[To Time]                 
where (F.Powerontime>0 or F.CutTime>0 or F.OperatingTime>0) group by F.machineid,L.[From Time]                 
)T2 inner join #LiveDetails on #LiveDetails.[From Time] = T2.TS and #LiveDetails.Machineid=T2.MachineID                
               
Update #LiveDetails Set [Cutting time] = round([Cutting time]/60,0) where [Cutting time]>0                 
Update #LiveDetails Set [Operating time] = round([Operating time] /60,0) where [Operating time]>0               
              
update #LiveDetails set [TotalTime]=DATEDIFF( MINUTE,[From Time],[To time]) from #LiveDetails              
              
update #LiveDetails set [TotalTimeInPer]='100'              
              
update #Livedetails set [PowerontimeInPer]=round(([Powerontime]/[TotalTime])*100,0);              
              
update #Livedetails set [Cutting timeInPer]=round(([Cutting time]/[TotalTime])*100,0);              
update #Livedetails set [OperatingtimeInPer]=round(([Operating time]/[TotalTime])*100,0);              
             
Create table #GetParts              
(              
 id bigint identity(1,1),              
 Machineid nvarchar(50),              
 Fromtime datetime,              
 Totime datetime,              
 ProgramNo nvarchar(50),              
 Partscount int,              
 Batchts datetime,              
 PrevBatchts datetime,              
 PrevCount int,              
 CurrentCount int,              
 cnctimestamp datetime              
)              
                            
Create table #TempGetParts              
(              
 id bigint identity(1,1),              
 Machineid nvarchar(50),              
 ProgramNo nvarchar(50),              
 Partscount int,              
 Batchts datetime,              
 cnctimestamp datetime              
)              
              
Create Table #LiveDetails1                
(                  
 [Sl No] Bigint Identity(1,1) Not Null,                  
 [Machineid] nvarchar(50),                  
 [From Time] datetime,                  
 [To time] datetime,                  
 [Powerontime] float,                  
 [Cutting time] float,                  
 [Operating time] float,              
 [ProgramNo] nvarchar(100),               
 [PartsCount] int,              
[Totaltime] float,              
[Totalhours] float                 
)               
              
truncate table #GetParts              
truncate table #TempGetParts              
      
              
              
if @param<>'Summary' and @param<>'OEMSummary' and @type<>'OEMHour'               
BEGIN              
select @strsql=''              
select @strsql = @strsql + 'Insert into #tempGetParts(Machineid,ProgramNo,Batchts,Partscount)              
select F.machineid,min(F.Programno) as ProgramNo,F.Batchts,0 from #FocasLivedata F with(NOLOCK)              
    inner join #LiveDetails L on L.machineid=F.machineid and F.cnctimestamp>=L.[From Time] and F.cnctimestamp<=L.[To Time] and F.partscount is not null                  
   where exists              
   (              
    select liv.ProgramNo From #FocasLivedata liv with(NOLOCK)              
    inner join #LiveDetails L1 on L1.machineid=liv.machineid 
	--and liv.cnctimestamp>=L1.[From Time] and liv.cnctimestamp<=L1.[To Time]   --Commented and added for China for count mismatch  
	and liv.cnctimestamp>L1.[From Time] and liv.cnctimestamp<=L1.[To Time]   --Commented and added for China for count mismatch  
    where liv.MachineMode = ''MEM'' --and liv.MachineStatus = ''In Cycle'' 
	and liv.batchts is not null               
    and F.Programno=liv.programno and F.machineid=liv.machineid and F.Batchts=liv.Batchts '              
    Select @strsql = @strsql + 'group by liv.ProgramNo              
    )              
   group by F.Machineid,F.BatchTs order by F.batchts '              
print @strsql              
exec(@strsql)              
              
              
Insert into #GetParts(Machineid,Fromtime,Totime,ProgramNo,Batchts,Partscount,cnctimestamp)              
select T.Machineid,L1.[From Time],L1.[To Time],T.ProgramNo,T.Batchts,Max(F.Partscount)-Min(F.Partscount),min(F.cnctimestamp) from #FocasLivedata F with(NOLOCK)              
inner join #tempGetParts T on T.Programno=F.programno and T.machineid=F.machineid and T.Batchts=F.Batchts              
inner join #LiveDetails L1 on L1.machineid=T.machineid 
--and F.cnctimestamp>=L1.[From Time] and F.CNCTimeStamp<=L1.[To Time]               
and F.cnctimestamp>L1.[From Time] and F.CNCTimeStamp<=L1.[To Time]    --Commented and added for China for count mismatch           
where F.MachineMode = 'MEM' --and F.MachineStatus = 'In Cycle'  -- ACV commented for China
and F.batchts is not null               
group by T.Machineid,L1.[From Time],L1.[To Time],T.ProgramNo,T.Batchts              
order by T.Machineid,L1.[From Time],T.Batchts              
              
      
  select * into #Focas_Getparts from focas_livedata f with(NOLOCK)  where cnctimestamp>=Dateadd(day,-2,@DataStart) and cnctimestamp<=@DataEnd    
              
--To get last recorded partscount for the previous batchtime              
update #getparts set Prevcount=T1.Partscount from              
(Select T.machineid,f.Partscount,T.fromtime,T.cnctimestamp from #Focas_Getparts f inner join              
    (Select g.fromtime,g.machineid,g.cnctimestamp,Max(f.id) as idd from     
 #Focas_Getparts f    
    inner join #getparts g on f.machineid=g.machineid               
    where f.cnctimestamp<g.cnctimestamp and f.MachineMode = 'MEM' --and f.MachineStatus = 'In Cycle' 
	group by g.machineid,g.fromtime,g.cnctimestamp              
    )T on F.id=T.idd               
)T1 inner join #getparts on #getparts.machineid=T1.machineid and #GetParts.Fromtime=T1.fromtime and #GetParts.cnctimestamp=T1.cnctimestamp              
              
              
              
--To get first recorded partscount for the current batchtime              
update #getparts set currentcount=T1.Partscount from              
(Select g.fromtime,g.machineid,g.cnctimestamp,f.partscount as Partscount from #FocasLivedata f with(NOLOCK)               
inner join #getparts g on f.machineid=g.machineid and g.cnctimestamp=f.cnctimestamp              
where f.MachineMode = 'MEM' --and f.MachineStatus = 'In Cycle'               
)T1 inner join #getparts on #getparts.machineid=T1.machineid and #GetParts.Fromtime=T1.fromtime and #GetParts.cnctimestamp=T1.cnctimestamp              
              
END              
              
              
 IF @Param='Summary' or @param='OEMSummary' or @type='OEMHour'               
 BEGIN              
   --Logic to consider Partcount : if Prevcount<Curcount then 1 elseif Prevcount>Curcount or Prevcount=CurCount then 0 and add it to the existing Partscount and Prevcount SHOULD NOT BE NULL.              
    update #getparts set Partscount=isnull(Partscount,0)  + isnull(T1.Pcount,0) from              
    (SELECT machineid,fromtime,cnctimestamp,case              
    when Prevcount>=Currentcount then 0               
    when PrevCount<CurrentCount THEN 1               
 when Prevcount is null then 1 end as Pcount              
 FROM              
 (              
  SELECT *, ROW_NUMBER() OVER(PARTITION BY machineid ORDER BY cnctimestamp) rn               
  FROM #getparts r              
 ) r              
 WHERE r.rn =1              
    )T1 inner join #getparts on #getparts.machineid=T1.Machineid and #GetParts.Fromtime=T1.Fromtime and #GetParts.cnctimestamp=T1.cnctimestamp              
              
              
   --Logic to consider Partcount : if Prevcount<Curcount then 1 elseif Prevcount>Curcount or Prevcount=CurCount then 0 and add it to the existing Partscount and Prevcount SHOULD NOT BE NULL.              
    update #getparts set Partscount=isnull(Partscount,0)  + isnull(T1.Pcount,0) from              
    (SELECT machineid,fromtime,cnctimestamp,case              
    when Prevcount>=Currentcount then 0               
    when PrevCount<CurrentCount THEN currentcount-prevcount              
 when Prevcount is null then 1 end as Pcount              
 FROM              
 (              
  SELECT *, ROW_NUMBER() OVER(PARTITION BY machineid ORDER BY cnctimestamp) rn               
  FROM #getparts r              
 ) r              
 WHERE r.rn >1              
    )T1 inner join #getparts on #getparts.machineid=T1.Machineid and #GetParts.Fromtime=T1.Fromtime and #GetParts.cnctimestamp=T1.cnctimestamp              
              
END              
              
              
 IF @Param<>'Summary' and @param<>'OEMSummary' and @type<>'OEMHour'               
 BEGIN  
 
 	--Commented and added below logic For China For Count Mismatch from here----------------------            
            
    ----Logic to consider Partcount : if Prevcount<Curcount then 1 elseif Prevcount>Curcount or Prevcount=CurCount then 0 and add it to the existing Partscount and Prevcount SHOULD NOT BE NULL.              
    --update #getparts set Partscount=isnull(Partscount,0)  + isnull(T1.Pcount,0) from              
    --(Select machineid,fromtime,cnctimestamp,case              
    --when Prevcount>=Currentcount then 0                
    --when PrevCount<CurrentCount THEN 1                
    --when Prevcount is null then 1 end as Pcount from #getparts              
    --)T1              
    --inner join #getparts on #getparts.machineid=T1.Machineid and #GetParts.Fromtime=T1.Fromtime and #GetParts.cnctimestamp=T1.cnctimestamp 
	 
	--Logic to consider Partcount : if Prevcount<Curcount then 1 elseif Prevcount>Curcount or Prevcount=CurCount then 0 and add it to the existing Partscount and Prevcount SHOULD NOT BE NULL.              
	update #getparts set Partscount=isnull(Partscount,0)  + isnull(T1.Pcount,0) from              
	(SELECT machineid,fromtime,cnctimestamp,case              
	when Prevcount>=Currentcount then 0               
	when PrevCount<CurrentCount THEN 1               
	when Prevcount is null then 1 end as Pcount              
	FROM              
	(              
	SELECT *, ROW_NUMBER() OVER(PARTITION BY machineid ORDER BY cnctimestamp) rn               
	FROM #getparts r              
	) r              
	WHERE r.rn =1              
	)T1 inner join #getparts on #getparts.machineid=T1.Machineid and #GetParts.Fromtime=T1.Fromtime and #GetParts.cnctimestamp=T1.cnctimestamp              
              
              
	--Logic to consider Partcount : if Prevcount<Curcount then 1 elseif Prevcount>Curcount or Prevcount=CurCount then 0 and add it to the existing Partscount and Prevcount SHOULD NOT BE NULL.              
	update #getparts set Partscount=isnull(Partscount,0)  + isnull(T1.Pcount,0) from              
	(SELECT machineid,fromtime,cnctimestamp,case              
	when Prevcount>=Currentcount then 0               
	when PrevCount<CurrentCount THEN currentcount-prevcount              
	when Prevcount is null then 1 end as Pcount              
	FROM              
	(              
	SELECT *, ROW_NUMBER() OVER(PARTITION BY machineid ORDER BY cnctimestamp) rn               
	FROM #getparts r              
	) r              
	WHERE r.rn >1              
	)T1 inner join #getparts on #getparts.machineid=T1.Machineid and #GetParts.Fromtime=T1.Fromtime and #GetParts.cnctimestamp=T1.cnctimestamp      
	--Commented and added below logic For China For Count Mismatch till here----------------------            
END              
              
 create table  #Totalgetparts          
(          
 id bigint,          
 Machineid nvarchar(50),          
 Fromtime datetime,          
 Totime datetime,          
 ProgramNo nvarchar(50),          
 Partscount float,          
 total float,          
 Target float,          
 OEE float,
 TotalPartsCount float,
 AvgOEE float          
)          
    
declare @CurrentTime as datetime    
Select @CurrentTime = getdate()    
          
        
         
--To Sum up all the Parts at ProgramNo Level for the given Machine and time Period.              
insert into #Totalgetparts          
Select row_number() over(order by Machineid) as id, Machineid,Fromtime,Totime,ProgramNo,isnull(Sum(Partscount),0)as Partscount,0 as total,0 as Target,0 as OEE,0,0 from #getparts              
group by Machineid,Fromtime,Totime,ProgramNo order by Machineid,Fromtime              
              
              
update #Totalgetparts set Total= T.Total from               
(select Machineid,Fromtime,Totime,isnull(Sum(Partscount),0)as total from #Totalgetparts group by Machineid,Fromtime,Totime)T inner join              
#totalgetparts on #totalgetparts.machineID=T.MachineID              
          
--update #Totalgetparts set Target= T.Target from               
--(select T.Machineid,T.Fromtime,T.ProgramNo,ROUND((ISNULL(cast(T.Partscount as float),0)*(60/Isnull(cast(F.Target as float),0))),2) as Target from #Totalgetparts T          
--inner join Focas_ProgramwiseTarget F on F.Machineid=T.Machineid and F.ProgramNo=T.ProgramNo)T inner join              
--#totalgetparts on #totalgetparts.machineID=T.MachineID and #totalgetparts.ProgramNo=T.ProgramNo and #totalgetparts.Fromtime=T.Fromtime          
--        
--    
--update #Totalgetparts set OEE= T.OEE from               
--(select T.Machineid,T.Fromtime,T.Totime,ROUND((ISNULL(cast(SUM(T.Target) as float),0)/cast(Datediff(minute,T.Fromtime,case when T.Totime>@CurrentTime then @CurrentTime else T.Totime END) as float))*100,2) as OEE from #Totalgetparts T          
--Group by T.Machineid,T.Fromtime,T.Totime)T inner join              
--#totalgetparts on #totalgetparts.machineID=T.MachineID and #totalgetparts.Fromtime=T.Fromtime          
 
--update #Totalgetparts set Target= T.Target from               
--(select T.Machineid,T.Fromtime,T.ProgramNo,Isnull(F.Target,0) as Target from #Totalgetparts T          
--inner join Focas_ProgramwiseTarget F on F.Machineid=T.Machineid and F.ProgramNo=T.ProgramNo)T inner join              
--#totalgetparts on #totalgetparts.machineID=T.MachineID and #totalgetparts.ProgramNo=T.ProgramNo and #totalgetparts.Fromtime=T.Fromtime          
 
----------------------- --COMMENTED FOR CHINA---------------------------       
--update #Totalgetparts set Target= T.Target from               
--(select Machineid,OEETarget as Target from machineinformation)T inner join              
--#totalgetparts on #totalgetparts.machineID=T.MachineID 
    
--update #Totalgetparts set OEE= T.OEE*100 from               
--(
--select T.Machineid,T.Fromtime,T.Totime,ROUND(ISNULL(cast(SUM(T.Partscount) as float),0)/ISNULL(cast(SUM(T.Target) as float),0),2) as OEE from #Totalgetparts T          
--where T.Target>0 Group by T.Machineid,T.Fromtime,T.Totime,T.Target
--)T inner join #totalgetparts on #totalgetparts.machineID=T.MachineID and #totalgetparts.Fromtime=T.Fromtime  
 --------------------------COMMENTED FOR CHINA--------------------------    

 update #Totalgetparts set Target= T.Target from               
(select T.Machineid,T.Fromtime,T.ProgramNo,ROUND((ISNULL(cast(T.Partscount as float),0)*(Isnull(cast(F.Cycletime as float),0))),2) as Target from #Totalgetparts T          
inner join Focas_ProgramwiseTarget F on F.Machineid=T.Machineid and F.ProgramNo=T.ProgramNo)T inner join              
#totalgetparts on #totalgetparts.machineID=T.MachineID and #totalgetparts.ProgramNo=T.ProgramNo and #totalgetparts.Fromtime=T.Fromtime          

--update #Totalgetparts set OEE= T1.OEE from  
--(select T.Machineid,T.Fromtime,T.Totime,ROUND((ISNULL(cast(T.Target as float),0)/cast(Datediff(second,T.Fromtime,case when T.Totime>@CurrentTime then @CurrentTime else T.Totime END) as float))*100,2) as OEE from                  
--	(select T.Machineid,T.Fromtime,T.Totime,ISNULL(cast(SUM(T.Target) as float),0) as Target from #Totalgetparts T          
--	Group by T.Machineid,T.Fromtime,T.Totime
--	)T 
--)T1 inner join #totalgetparts on #totalgetparts.machineID=T1.MachineID and #totalgetparts.Fromtime=T1.Fromtime          

update #Totalgetparts set OEE= T1.OEE from  
(select T.Machineid,T.Fromtime,T.Totime,ROUND((ISNULL(cast(T.Target as float),0)/Isnull([Operating time]*60,0))*100,2) as OEE from                  
	(select T.Machineid,T.Fromtime,T.Totime,ISNULL(cast(SUM(T.Target) as float),0) as Target from #Totalgetparts T          
	Group by T.Machineid,T.Fromtime,T.Totime
	)T inner join #LiveDetails L on L.Machineid=T.Machineid and L.[From Time]=T.Fromtime and L.[To Time]=T.Totime    
	where Isnull([Operating time],0)<>0	                      
)T1 inner join #totalgetparts on #totalgetparts.machineID=T1.MachineID and #totalgetparts.Fromtime=T1.Fromtime
  
update #Totalgetparts set TotalPartsCount = T1.Parts from        
(select Machineid,isnull(sum(Partscount),0) as Parts from  #Totalgetparts where PartsCount>0 group by machineid)T1 
inner join #Totalgetparts on T1.machineid=#Totalgetparts.machineid  

  --COMMENTED FOR CHINA-----            
-- update #Totalgetparts set AvgOEE= T.AvgOEE from                 
--(select ROUND(AVG(OEE),0) as AvgOEE from #Totalgetparts)T           
 --COMMENTED FOR CHINA-----  
 
             
if @param='Summary' or @param='OEMSummary' or @type='OEMHour'               
BEGIN              
          
 Insert into #LiveDetails1([Machineid],[From Time],[To time],[Powerontime],[Cutting time],[Operating time],[ProgramNo],[Partscount])                
 Select Machineid,min([From time]),Max([To time]),0,0,0,0,0  from #Livedetails group by Machineid-- order by machineid,[From time]               
              
              
 Update #LiveDetails1 set [Powerontime]  = Isnull([Powerontime],0) + ISNULL(T1.PTime,0),                  
 [Cutting time]  = Isnull([Cutting time],0) + ISNULL(T1.CTime,0),                  
 [Operating time] = Isnull([Operating time],0) + ISNULL(T1.OTime,0) from                   
 (Select F.machineid,L.[From Time] as Fromtime,L.[To time] as Totime,Max(F.Powerontime) - Min(F.Powerontime) as Ptime,                  
 Max(F.CutTime)- Min(F.CutTime) as CTime,Max(F.OperatingTime)- Min(F.OperatingTime) as OTime from dbo.Focas_LiveData F                  
 inner join #LiveDetails1 L on L.machineid=F.machineid and F.cnctimestamp>=L.[From Time] and F.cnctimestamp<=L.[To Time]                       
 group by F.machineid,L.[From Time],L.[To time])T1                  
 inner join #LiveDetails1 on #LiveDetails1.[From Time] = T1.Fromtime and #LiveDetails1.Machineid = T1.MachineID                  
                   
 Update #LiveDetails1 Set [Cutting time] = [Cutting time]/60 where [Cutting time]>0                   
 Update #LiveDetails1 Set [Operating time] = [Operating time] /60 where [Operating time]>0                  
              
 --Update #LiveDetails1 set [Powerontime] = [Powerontime]/60 where [Powerontime]>0              
 --Update #LiveDetails1 Set [Cutting time] = [Cutting time]/3600 where [Cutting time]>0                   
 --Update #LiveDetails1 Set [Operating time] = [Operating time] /3600 where [Operating time]>0                  
              
              
 update #LiveDetails1 set [PartsCount] = T1.Parts from              
 (select Machineid,isnull(sum(Partscount),0) as Parts from  #Totalgetparts group by machineid)T1 inner join #livedetails1 on T1.machineid=#livedetails1.machineid              
              
 update #LiveDetails1 set ProgramNo = T1.ProgramNo from              
 (select Machineid,ProgramNo as ProgramNo from  #Totalgetparts)T1 inner join #livedetails1 on T1.machineid=#livedetails1.machineid              
END              
              
              
If  (@Shiftname<>'DAY') and  (@Param<>'Summary') and (@param<>'OEMSummary') and (@type<>'OEMHour' )              
Begin              
          
SELECT L.Machineid as MachineID,L.MachineStatus as MachineStatus,L.[RunningProgram] as RunningProgram,L.ShiftDate as ShiftDate,L.ShiftName  as ShiftName,               
CAST(TotalTime AS varchar(10))+' '+'('+ RIGHT ('   ' + cast([TotalTimeInPer]  AS varchar(7)),3)+'%'+')' as TotalTime,P.Total as Total,              
CAST([Powerontime] AS varchar(10))+' '+'('+ RIGHT ('   ' + cast([PowerontimeInPer]  AS varchar(7)),3)+'%'+')'  as [Powerontime],              
CAST([Cutting time] AS varchar(10))+' '+'('+ RIGHT ('   ' + cast([Cutting timeInPer] AS varchar(7)),3)+'%'+')' as [Cutting time],              
CAST([Operating time] AS varchar(10))+' '+'('+ RIGHT ('   ' + cast([OperatingtimeInPer] AS varchar(7)),3)+'%'+')' as [Operating time],              
P.ProgramNo as ProgramNo,P.PartsCount as PartsCount,Round(P.OEE,2) as OEE,P.AvgOEE,P.TotalPartsCount             
into #temp from #LiveDetails L left outer join #Totalgetparts P              
on L.Machineid=P.Machineid and L.[From Time]=P.Fromtime and L.[To Time]=P.Totime               
Order by L.Machineid,L.ShiftDate,L.shiftname,PartsCount desc              
          
            
SELECT ShiftDate,Shiftname,TotalTime,[Powerontime],[Operating time], [Cutting time],Machineid,Total,RunningProgram,MachineStatus,OEE,AvgOEE,TotalPartsCount,              
STUFF((SELECT top 4 ', ' + Programno+' '+'('+ RIGHT ('   ' + cast([PartsCount]  AS varchar(7)),4)+')'              
FROM #temp                
WHERE MachineID = t.MachineID order by [PartsCount] desc              
FOR XML PATH('')), 1, 2,'')Programs              
into #Live FROM #temp t              
GROUP BY Machineid, ShiftDate,Shiftname,TotalTime,[Powerontime],[Operating time], [Cutting time],MachineStatus,Total,RunningProgram ,OEE,AvgOEE,TotalPartsCount            
              

select  ShiftDate,Shiftname,MachineStatus,RunningProgram,TotalTime,[Powerontime],[Operating time], [Cutting time],Machineid,OEE,AvgOEE,Total,TotalPartsCount,              
parsename(Programs,1) as ProgramNo1              
,parsename(Programs,2) as ProgramNo2              
,parsename(Programs,3) as ProgramNo3,              
parsename(Programs,4) as ProgramNo4            
FROM (Select ShiftDate,Shiftname,MachineStatus,RunningProgram,TotalTime,Total,[Powerontime],[Operating time], [Cutting time],Machineid,OEE,TotalPartsCount,
AvgOEE,replace(Programs,',','.') Programs from #Live) t              
   
  	select AC.MachineId,Concat(TotalCNCAlarms,'/',NewCNCAlarms) as [Total/NewCNCAlarm],Concat(TotalPreventiveAlerts,'/',NewPreventiveAlerts) as [Total/NewPreventiveAlerts],
	Concat(TotalPredictiveAlerts,'/',NewPredictiveAlerts) as [Total/NewPredictiveAlerts],
	[Powerontime],[Operating time],MachineStatus
	from #AlarmCount AC
	inner join #Live L on AC.MachineId=L.Machineid
END              
              
              
If @Shiftname='DAY' and  (@Param<>'Summary') and (@param<>'OEMSummary') and (@type<>'OEMHour' )              
Begin              
              
SELECT L.Machineid as MachineID,L.MachineStatus as MachineStatus,L.RunningProgram as RunningProgram,L.[From Time] as [From Time] ,L.[To Time] as [To Time],               
CAST(TotalTime AS varchar(10))+' '+'('+ RIGHT ('   ' + cast([TotalTimeInPer]  AS varchar(7)),3)+'%'+')' as TotalTime,P.Total as Total,              
CAST([Powerontime] AS varchar(10))+' '+'('+ RIGHT ('   ' + cast([PowerontimeInPer]  AS varchar(7)),3)+'%'+')'  as [Powerontime],              
CAST([Cutting time] AS varchar(10))+' '+'('+ RIGHT ('   ' + cast([Cutting timeInPer] AS varchar(7)),3)+'%'+')' as [Cutting time],              
CAST([Operating time] AS varchar(10))+' '+'('+ RIGHT ('   ' + cast([OperatingtimeInPer] AS varchar(7)),3)+'%'+')' as [Operating time],              
P.ProgramNo as ProgramNo,P.PartsCount as PartsCount,Round(P.OEE,2) as OEE,P.AvgOEE,P.TotalPartsCount              
 into #temp1 from #LiveDetails L left outer join #Totalgetparts P              
on L.Machineid=P.Machineid and L.[From Time]=P.Fromtime and L.[To Time]=P.Totime               
Order by L.Machineid,L.[From Time],PartsCount desc        
     
              
              
SELECT [From Time],[To Time],MachineStatus,TotalTime,[Powerontime],[Operating time], Total, [Cutting time],Machineid,RunningProgram,OEE,AvgOEE,TotalPartsCount ,            
STUFF((SELECT top 4 ', ' + Programno+' '+'('+ RIGHT ('   ' + cast([PartsCount]  AS varchar(7)),4)+')'              
FROM #temp1                
WHERE MachineID = t.MachineID  order by [PartsCount] desc              
FOR XML PATH('')), 1, 2,'')Programs              
into #Live1  FROM #temp1 t              
GROUP BY Machineid,[From Time],[To Time],MachineStatus,TotalTime,[Powerontime],[Operating time], [Cutting time] ,Total,RunningProgram,OEE ,AvgOEE,TotalPartsCount    

    
              
select [From Time],[To Time],MachineStatus,RunningProgram,TotalTime,[Powerontime],[Operating time], [Cutting time],Machineid,Total,              
parsename(Programs,1) as ProgramNo1              
,parsename(Programs,2) as ProgramNo2              
,parsename(Programs,3) as ProgramNo3,              
parsename(Programs,4) as ProgramNo4,OEE,AvgOEE,TotalPartsCount           
FROM (Select  [From Time],[To Time],MachineStatus,RunningProgram,TotalTime,[Powerontime],[Operating time], Total,[Cutting time],Machineid,OEE,AvgOEE,
TotalPartsCount,replace(Programs,',','.') Programs from #Live1) t              
  
 	select AC.MachineId,Concat(TotalCNCAlarms,'/',NewCNCAlarms) as [Total/NewCNCAlarm],Concat(TotalPreventiveAlerts,'/',NewPreventiveAlerts) as [Total/NewPreventiveAlerts],
	Concat(TotalPredictiveAlerts,'/',NewPredictiveAlerts) as [Total/NewPredictiveAlerts],
	[Powerontime],[Operating time],MachineStatus
	from #AlarmCount AC
	inner join #Live1 L on AC.MachineId=L.Machineid

END              
              
              
              
              
if @param='Summary'            
BEGIN              
                
 select @curtime= getdate()              
              
 SELECT L.Machineid as MachineID,L.[From Time],L.[To Time], TotalTime ,              
 [Powerontime],              
 [Cutting time],              
 Round(L.[Operating time],2) as [Operating time]              
 from #LiveDetails L               
              
-- Select sum(Round([Powerontime],2)) as [Powerontime],sum(Round([Cutting time],2)) as [Cutting time],                
-- sum(DATEDIFF( MINUTE,[From Time],[To time])) as [TotalTime],sum(round(([Operating time]-[Cutting time]),2)) as OperatingWithoutCutting,                
-- sum(Round(([Powerontime]-[Operating time]),2)) as NonOperatingTime,sum(round(((DATEDIFF( MINUTE,[From Time],[To time])-[Powerontime]) ),2)) as PowerOffTime,              
-- sum(Round([Operating time],2)) as  [Operating time],              
-- sum([PartsCount]) as [PartsCount]              
-- From #LiveDetails1              
              
 --Select sum(Round([Powerontime],2)) as [Powerontime],sum(Round([Cutting time],2)) as [Cutting time],                
 --sum(DATEDIFF( hour,[From Time],[To time])) as [TotalTime],sum(round(([Operating time]-[Cutting time]),2)) as OperatingWithoutCutting,                
 --sum(Round(([Powerontime]-[Operating time]),2)) as NonOperatingTime,sum(round(((DATEDIFF( hour,[From Time],[To time])-[Powerontime]) ),2)) as PowerOffTime,              
 --sum(Round([Operating time],2)) as  [Operating time],              
 --sum([PartsCount]) as [PartsCount],Sum(Datediff(hour,@Refshiftstart,@shiftend)) as TotalHours              
 --From #LiveDetails1              
              
 Update #LiveDetails1 set [Powerontime] = [Powerontime]/60.00 where [Powerontime]>0              
 Update #LiveDetails1 Set [Cutting time] = [Cutting time]/60.00 where [Cutting time]>0                   
 Update #LiveDetails1 Set [Operating time] = [Operating time] /60.00 where [Operating time]>0                 
 --update #LiveDetails1 set [TotalTime]=DATEDIFF( MINUTE,[From Time],[To time])/60.00              
 --update #LiveDetails1 set [TotalTime]=case when [From Time]<@curtime then  DATEDIFF( MINUTE,[From Time],case when [To time]>@curtime then @curtime else [To time] end)/60.00 else 0 end              
 --update #LiveDetails1 set [TotalHours]=case when [From Time]<@curtime then  DATEDIFF( MINUTE,[From Time],case when [To time]>@curtime then @curtime else [To time] end)/60.00 else 0 end              
   update #LiveDetails1 set [TotalTime]=case when [From Time]<@curtime then  DATEDIFF( MINUTE,[From Time],[To time])/60.00 else 0 end              
 update #LiveDetails1 set [TotalHours]=case when [From Time]<@curtime then  DATEDIFF( MINUTE,[From Time],[To time])/60.00 else 0 end             
              
 Select Round(sum([Powerontime]),2) as [Powerontime],Round(sum([Cutting time]),2) as [Cutting time],                
 round(sum([TotalTime]),2) as [TotalTime],round(sum(([Operating time]-[Cutting time])),2) as OperatingWithoutCutting,                
 Round(sum(([Powerontime]-[Operating time])),2) as NonOperatingTime,round(sum(([TotalTime]-[Powerontime])),2) as PowerOffTime,              
 Round(sum([Operating time]),2) as  [Operating time],              
 sum([PartsCount]) as [PartsCount],round(Sum([TotalHours]),2) as TotalHours              
 From #LiveDetails1               
              
END              
              
              
if @param='OEMSummary' and @type='OEMHour'              
BEGIN              
          
          
 SELECT L.Machineid as MachineID,L.[From Time],L.[To Time], TotalTime ,              
 [Powerontime],              
 [Cutting time],              
 Round(L.[Operating time],2) as [Operating time]              
 from #LiveDetails L --where (L.[From Time]<> @Refshiftstart and L.[To Time]<>@Refshiftend)              
              
 Update #LiveDetails1 set [Powerontime] = [Powerontime]/60.00 where [Powerontime]>0              
 Update #LiveDetails1 Set [Cutting time] = [Cutting time]/60.00 where [Cutting time]>0                   
 Update #LiveDetails1 Set [Operating time] = [Operating time] /60.00 where [Operating time]>0                 
 update #LiveDetails1 set [TotalTime]=DATEDIFF( MINUTE,@Refshiftstart,@Refshiftend)/60.00              
 update #LiveDetails1 set [TotalHours]=DATEDIFF( MINUTE,@Refshiftstart,@Refshiftend)/60.00              
              
              
 Select Round(sum([Powerontime]),2) as [Powerontime],Round(sum([Cutting time]),2) as [Cutting time],                
 round(sum([TotalTime]),2) as [TotalTime],round(sum(([Operating time]-[Cutting time])),2) as OperatingWithoutCutting,                
 Round(sum(([Powerontime]-[Operating time])),2) as NonOperatingTime,round(sum(([TotalTime]-[Powerontime])),2) as PowerOffTime,              
 Round(sum([Operating time]),2) as  [Operating time],              
 sum([PartsCount]) as [PartsCount],round(Sum([TotalHours]),2) as TotalHours              
 From #LiveDetails1 --where ([From Time]<> @Refshiftstart and [To Time]<>@Refshiftend)              
              
              
END              
              
              
END 
