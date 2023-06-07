/****** Object:  Procedure [dbo].[Focas_AlertMachinewiseAlarm]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[Focas_AlertMachinewiseAlarm]       
CREATE PROCEDURE [dbo].[Focas_AlertMachinewiseAlarm]           
AS          
BEGIN          
          
      
create table #Alarm      
(      
 MachineId nvarchar(50),      
 MINCNCTS datetime,       
 MAXCNCTS datetime,      
 Duration int,      
 MachineStatus nvarchar(50),      
 AlarmNo nvarchar(4000),      
 MaxOperatingTS float      
)      
   
create table #AlarmHistory
(
	Machineid nvarchar(50),
	AlarmNo nvarchar(1000),
	MINCNCTS datetime
)

Declare @AlarmThreshold as int      --INMINUTES
select @AlarmThreshold= ISNULL(Valueintext,5) from  Focas_Defaults where Parameter='Focas_AlertAlarmThreshold'      

   
Declare @Curtime as datetime      
Select @Curtime=Getdate()      
      
Declare @ThresholdINMinutes as int      
select @ThresholdINMinutes= ISNULL(Valueintext,3) from  Focas_Defaults where Parameter='Focas_AlertThreshold'      
      
declare @param as nvarchar(50)      
select @param = ISNULL(Valueintext,'ByMachineStatus') from  Focas_Defaults where Parameter='Focas_AlertMachinewiseAlarm'    
      

 
Insert into #Alarm(MachineId,Duration)      
select distinct machineid,0 from Machineinformation      
      
If @param = 'ByMachineStatus'      
Begin      
    
  Update #Alarm set MINCNCTS=T1.CNCTS,MAXCNCTS=T1.CNCTS,Duration=ISNULL(T1.Duration,0),MachineStatus=T1.MachineStatus from      
  (      
   select FL.Machineid,FL.CNCtimestamp  as CNCTS,Datediff(Minute,FL.CNCtimestamp,@Curtime)as Duration,'Machine Not Running/No_Data'  as MachineStatus    
   from Focas_livedata FL Inner Join      
   (      
    select F.Machineid,MAX(F.id) as id from Focas_livedata F inner join #Alarm A on F.Machineid=A.Machineid      
    where F.CNCtimestamp<@Curtime group by F.Machineid      
   )T on FL.id=T.id and FL.Machineid=T.Machineid  where-- FL.MachineStatus IN('STOP','EMERGENCY','ALARM') and 
	Datediff(Minute,FL.CNCtimestamp,@Curtime)>@ThresholdINMinutes   
  )T1 inner join #Alarm on #Alarm.Machineid=T1.Machineid      
 

     
  insert into #AlarmHistory    
  Select T1.Machineid,T1.AlarmNo,T1.MINCNCTS from(
  select T.Machineid,T.AlarmNo,T.MINCNCTS,row_number() over(partition by T.machineid,T.AlarmNo order by T.AlarmTime desc) as rn from
		(select distinct F.Machineid,cast(F.AlarmNo as nvarchar(50)) + ' (' + Substring(F.AlarmMSG,1,30) + ')' as AlarmNo,A.MINCNCTS,MAX(F.AlarmTime) as AlarmTime from Focas_AlarmHistory F 
	  --inner join Focas_AlarmMaster FA on F.AlarmNo=FA.AlarmNo
	  inner join #Alarm A on F.Machineid=A.Machineid and (F.AlarmTime between A.MINCNCTS and @Curtime) where A.Duration>=@AlarmThreshold
	  group by  F.Machineid,F.AlarmNo,F.AlarmMSG,A.MINCNCTS
	  )T )T1  where T1.rn <= 4  
      
  Update #Alarm set MAXCNCTS=T1.CNCTS from      
  (      
   select FL.Machineid,FL.CNCtimestamp as CNCTS      
    from Focas_livedata FL Inner Join      
   (select F.Machineid,MAX(F.id) as id from Focas_livedata F inner join #Alarm A on F.Machineid=A.Machineid      
   where F.CNCtimestamp<@Curtime group by F.Machineid)T on FL.id=T.id and FL.Machineid=T.Machineid   
	where FL.MachineStatus IN('STOP','EMERGENCY','ALARM') and Datediff(Minute,FL.CNCtimestamp,@Curtime)<@ThresholdINMinutes   
  )T1 inner join #Alarm on #Alarm.Machineid=T1.Machineid where #Alarm.Duration=0      
  
      
  Update #Alarm set #Alarm.MINCNCTS=T1.CNCTS,#Alarm.Duration=ISNULL(T1.Duration,0),#Alarm.MachineStatus=T1.MachineStatus from      
  (      
   select T.MAXCNCTS,FL.Machineid,FL.CNCtimestamp as CNCTS,Datediff(Minute,FL.CNCtimestamp,@Curtime) as Duration,'Alarm' as MachineStatus--FL.MachineStatus 
   from Focas_livedata FL Inner Join      
   (select A.MAXCNCTS,F.Machineid,MAX(F.id) as id from Focas_livedata F inner join #Alarm A on F.Machineid=A.Machineid      
   where F.CNCtimestamp<A.MAXCNCTS and F.MachineStatus IN('In Cycle') and datediff(HOUR,F.CNCtimestamp,@Curtime)<=24 group by F.Machineid,A.MAXCNCTS)T on FL.id=T.id and FL.Machineid=T.Machineid      
  )T1 inner join #Alarm on #Alarm.Machineid=T1.Machineid and #Alarm.MAXCNCTS=T1.MAXCNCTS where #Alarm.Duration=0      


     
  insert into #AlarmHistory    
  Select T1.Machineid,T1.AlarmNo,T1.MINCNCTS from(
  select T.Machineid,T.AlarmNo,T.MINCNCTS,row_number() over(partition by T.machineid,T.AlarmNo order by T.AlarmTime desc) as rn from
		(select distinct F.Machineid,cast(F.AlarmNo as nvarchar(50)) + ' (' + Substring(F.AlarmMSG,1,30) + ')' as AlarmNo,A.MINCNCTS,MAX(F.AlarmTime) as AlarmTime from Focas_AlarmHistory F 
	  --inner join Focas_AlarmMaster FA on F.AlarmNo=FA.AlarmNo
	  inner join #Alarm A on F.Machineid=A.Machineid and (F.AlarmTime between A.MINCNCTS and A.MAXCNCTS) where A.Duration>=@AlarmThreshold
	  group by  F.Machineid,F.AlarmNo,F.AlarmMSG,A.MINCNCTS
	  )T )T1  where T1.rn <= 4  
      
  Update #Alarm set #Alarm.Alarmno=T1.Alarmno from      
  (      
  SELECT A2.Machineid,A2.MINCNCTS,       
      Stuff((SELECT ',' + cast(A1.AlarmNo as nvarchar(100))       
       FROM  #AlarmHistory A1       
       WHERE  A1.Machineid = A2.Machineid and A1.MINCNCTS=A2.MINCNCTS      
       FOR xml path ('')), 1, 1, '') as Alarmno      
  FROM  #AlarmHistory A2       
  group by A2.Machineid,A2.MINCNCTS)T1 inner join #Alarm on #Alarm.Machineid=T1.Machineid and #Alarm.MINCNCTS=T1.MINCNCTS      
END      
      
     
If @param = 'ByOperatingTime'      
Begin      
    
  Update #Alarm set MINCNCTS=T1.CNCTS, MAXCNCTS=T1.CNCTS,Duration=ISNULL(T1.Duration,0),MachineStatus=T1.MachineStatus from    
  (      
   select FL.Machineid,FL.CNCtimestamp as CNCTS,Datediff(Minute,FL.CNCtimestamp,@Curtime) as Duration,'Machine Not Running/No_Data' as MachineStatus       
   from Focas_livedata FL Inner Join      
   (      
    select F.Machineid,MAX(F.id) as id from Focas_livedata F inner join #Alarm A on F.Machineid=A.Machineid      
    where F.CNCtimestamp<@Curtime group by F.Machineid      
   )T on FL.id=T.id and FL.Machineid=T.Machineid where Datediff(Minute,FL.CNCtimestamp,@Curtime)>@ThresholdINMinutes      
  )T1 inner join #Alarm on #Alarm.Machineid=T1.Machineid      
 


     
  insert into #AlarmHistory    
  Select T1.Machineid,T1.AlarmNo,T1.MINCNCTS from(
  select T.Machineid,T.AlarmNo,T.MINCNCTS,row_number() over(partition by T.machineid,T.AlarmNo order by T.AlarmTime desc) as rn from
		(select distinct F.Machineid,cast(F.AlarmNo as nvarchar(50)) + ' (' + Substring(F.AlarmMSG,1,30) + ')' as AlarmNo,A.MINCNCTS,MAX(F.AlarmTime) as AlarmTime from Focas_AlarmHistory F 
	  --inner join Focas_AlarmMaster FA on F.AlarmNo=FA.AlarmNo
	  inner join #Alarm A on F.Machineid=A.Machineid and (F.AlarmTime between A.MINCNCTS and @Curtime) where A.Duration>=@AlarmThreshold
	  group by  F.Machineid,F.AlarmNo,F.AlarmMSG,A.MINCNCTS
	  )T )T1  where T1.rn <= 4  
     
      
  Update #Alarm set MAXCNCTS=T1.CNCTS,MaxOperatingTS=T1.OT from      
  (      
   select FL.Machineid,FL.CNCtimestamp as CNCTS,      
    OperatingTime as OT from Focas_livedata FL Inner Join      
   (select F.Machineid,MAX(F.id) as id from Focas_livedata F inner join #Alarm A on F.Machineid=A.Machineid      
   where F.CNCtimestamp<@Curtime group by F.Machineid)T on FL.id=T.id and FL.Machineid=T.Machineid 
   where Datediff(Minute,FL.CNCtimestamp,@Curtime)<@ThresholdINMinutes     
  )T1 inner join #Alarm on #Alarm.Machineid=T1.Machineid where #Alarm.Duration=0      
      
      
  Update #Alarm set #Alarm.MINCNCTS=T1.CNCTS,#Alarm.Duration=ISNULL(T1.Duration,0),#Alarm.MachineStatus=T1.MachineStatus from       
  (      
   select T.MAXCNCTS,FL.Machineid,FL.CNCtimestamp as CNCTS,Datediff(Minute,FL.CNCtimestamp,@Curtime) as Duration,'Alarm' as MachineStatus from Focas_livedata FL Inner Join      
   (select A.MAXCNCTS,F.Machineid,MAX(F.id) as id from Focas_livedata F inner join #Alarm A on F.Machineid=A.Machineid      
   where F.CNCtimestamp<A.MAXCNCTS and F.OperatingTime<>A.MaxOperatingTS and datediff(HOUR,F.CNCtimestamp,@Curtime)<=24 group by F.Machineid,A.MAXCNCTS)T on FL.id=T.id and FL.Machineid=T.Machineid      
  )T1 inner join #Alarm on #Alarm.Machineid=T1.Machineid and #Alarm.MAXCNCTS=T1.MAXCNCTS where #Alarm.Duration=0      
      
     
     
  insert into #AlarmHistory    
  Select T1.Machineid,T1.AlarmNo,T1.MINCNCTS from(
  select T.Machineid,T.AlarmNo,T.MINCNCTS,row_number() over(partition by T.machineid,T.AlarmNo order by T.AlarmTime desc) as rn from
		(select distinct F.Machineid,cast(F.AlarmNo as nvarchar(50)) + ' (' + Substring(F.AlarmMSG,1,30) + ')' as AlarmNo,A.MINCNCTS,MAX(F.AlarmTime) as AlarmTime from Focas_AlarmHistory F 
	  --inner join Focas_AlarmMaster FA on F.AlarmNo=FA.AlarmNo
	  inner join #Alarm A on F.Machineid=A.Machineid and (F.AlarmTime between A.MINCNCTS and A.MAXCNCTS) where A.Duration>=@AlarmThreshold
	  group by  F.Machineid,F.AlarmNo,F.AlarmMSG,A.MINCNCTS
	  )T )T1  where T1.rn <= 4  
      
  Update #Alarm set #Alarm.Alarmno=T1.Alarmno from      
  (      
  SELECT A2.Machineid,A2.MINCNCTS,       
      Stuff((SELECT ',' + cast(A1.AlarmNo as nvarchar(100))       
       FROM  #AlarmHistory A1       
       WHERE  A1.Machineid = A2.Machineid and A1.MINCNCTS=A2.MINCNCTS      
       FOR xml path ('')), 1, 1, '') as Alarmno      
  FROM  #AlarmHistory A2       
  group by A2.Machineid,A2.MINCNCTS)T1 inner join #Alarm on #Alarm.Machineid=T1.Machineid and #Alarm.MINCNCTS=T1.MINCNCTS      
END      
      
      
SELECT * from #Alarm where duration>0    
        
End          
         
