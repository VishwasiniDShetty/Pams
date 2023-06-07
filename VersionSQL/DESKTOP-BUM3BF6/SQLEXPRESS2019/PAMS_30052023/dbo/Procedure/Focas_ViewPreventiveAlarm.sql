/****** Object:  Procedure [dbo].[Focas_ViewPreventiveAlarm]    Committed by VersionSQL https://www.versionsql.com ******/

--Focas_ViewPreventiveAlarm '2016-02-08','2016-02-09','fier-h',''    
CREATE PROCEDURE [dbo].[Focas_ViewPreventiveAlarm]  
 @StartTime datetime,  
 @EndTime datetime,  
 @MachineID nvarchar(50) = '',  
 @AlarmGroup nvarchar(20)='ALL' 
AS  
BEGIN  
  
--IF isnull(@AlarmGroup,'ALL')= 'ALL' or @AlarmGroup=''  
-- Begin  
--  select ROW_NUMBER() OVER (ORDER BY AlarmTime desc) AS ID,  a.*,isnull(c.Name,'') as AlarmCategory  
--     from Focas_AlarmHistory a left outer join Focas_AlarmCategory c  
--     on  a.AlarmGroupNo = c.AlarmNo  
--     where AlarmTime between @StartTime and  @EndTime  
--  and machineId=@MachineID  
--  and ( a.AlarmNo >= 1100  and a.AlarmNo <= 1115 )  
--  order by AlarmTime desc  
-- End  
  
--ELSE  
  
-- Begin  
--  Select   ROW_NUMBER() OVER (ORDER BY AlarmTime desc) AS ID,a.*, isnull(c.Name,'') as AlarmCategory  
--        from Focas_AlarmHistory  a left outer join Focas_AlarmCategory c  
--        on  a.AlarmGroupNo = c.AlarmNo  
--        where AlarmGroupNo =  @AlarmGroup and  
--  machineId=@MachineID and (AlarmTime between @StartTime and @EndTime)  
--  and ( a.AlarmNo >= 1100  and a.AlarmNo <= 1115 )  
--  order by AlarmTime desc  
-- End  
Declare @Curtime as datetime
select @curtime= getdate()

 IF isnull(@AlarmGroup,'ALL')= 'ALL' or @AlarmGroup=''    
 Begin    

   --Select ROW_NUMBER() OVER (ORDER BY T.MaxAlarmtime desc) AS ID,T.AlarmNo,T.AlarmMessage,T.NOofOccurences,T.MinAlarmTime,T.MaxAlarmtime, 'D:\Images\abc.png' as DocPath
	Select ROW_NUMBER() OVER (ORDER BY T.MaxAlarmtime desc) AS ID,T.AlarmNo,T.AlarmMessage,T.NOofOccurences,T.MinAlarmTime,T.MaxAlarmtime,T.filePath as DocPath,
	T.Colorcode as color
   from (     
   select A.Alarmno as AlarmNo,A.AlarmMSG as AlarmMessage,Count(distinct A.AlarmNo) as NOofOccurences,Min(A.AlarmTime) as MinAlarmTime,Max(A.AlarmTime) as MaxAlarmtime,F.filePath,
   Case when (Max(A.AlarmTime) between dateadd(minute,-15,@curtime) and @curtime) and A.Ackstatus IS NULL then '1' else '0' end as colorcode  
   from Focas_AlarmHistory a 
   left outer join Focas_AlarmCategory c on  a.AlarmGroupNo = c.AlarmNo
   left outer join Focas_AlarmMaster F on A.Alarmno=F.AlarmNo        
   where (AlarmTime between @StartTime and  @EndTime) and 
    ( a.AlarmNo >= 1150  and a.AlarmNo <= 1172 ) 
   and machineId=@MachineID Group by A.Alarmno,A.AlarmMSG,F.filePath,A.Ackstatus)T    
   Order by T.MaxAlarmtime desc  
  
 End       
 ELSE    
 Begin   
 
  --Select ROW_NUMBER() OVER (ORDER BY T.MaxAlarmtime desc) AS ID,T.AlarmNo,T.AlarmMessage,T.NOofOccurences,T.MinAlarmTime,T.MaxAlarmtime, 'D:\Images\ abc.png' as DocPath from (     
	Select ROW_NUMBER() OVER (ORDER BY T.MaxAlarmtime desc) AS ID,T.AlarmNo,T.AlarmMessage,T.NOofOccurences,T.MinAlarmTime,T.MaxAlarmtime, T.filePath as DocPath,T.Colorcode as color from 
	(     
	  select A.Alarmno as AlarmNo,A.AlarmMSG as AlarmMessage,Count(distinct A.AlarmNo) as NOofOccurences,Min(A.AlarmTime) as MinAlarmTime,Max(A.AlarmTime) as MaxAlarmtime,F.filePath,  
	     Case when (max(A.AlarmTime) between dateadd(minute,-15,@curtime) and @curtime) and A.Ackstatus IS NULL then '1' else '0' end as colorcode   
			from Focas_AlarmHistory  a 
			left outer join Focas_AlarmCategory c on  a.AlarmGroupNo = c.AlarmNo
			left outer join Focas_AlarmMaster F on A.Alarmno=F.AlarmNo       
			where AlarmGroupNo =  @AlarmGroup and    
	  machineId=@MachineID and (AlarmTime between @StartTime and @EndTime)   and ( a.AlarmNo >= 1150  and a.AlarmNo <= 1172 )  
	  Group by A.Alarmno,A.AlarmMSG,F.filePath,A.Ackstatus)T Order by T.MaxAlarmtime desc  
  
 End    

End  
 
