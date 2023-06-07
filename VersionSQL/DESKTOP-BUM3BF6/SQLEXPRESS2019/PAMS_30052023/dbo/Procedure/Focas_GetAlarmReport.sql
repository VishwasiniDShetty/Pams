/****** Object:  Procedure [dbo].[Focas_GetAlarmReport]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[Focas_GetAlarmReport]  '2019-04-15','2019-04-16','','','Summary','day'  
CREATE PROCEDURE [dbo].[Focas_GetAlarmReport]      
 @StartTime datetime,      
 @EndTime datetime,      
 @MachineID nvarchar(50) = '',      
 @AlarmGroup nvarchar(20)='ALL',      
 @Param nvarchar(20)= 'Summary',  
 @ShiftName nvarchar(50)='',
 @AlarmFilter nvarchar(50) = ''   
       
AS      
BEGIN   
  
Declare @Curtime as datetime  
Declare @T_ST AS Datetime
Declare @T_ED AS Datetime 


select @curtime= getdate()  
  
Declare @Counter as datetime  
select @counter=convert(datetime, cast(DATEPART(yyyy,@StartTime)as nvarchar(4))+'-'+cast(datepart(mm,@StartTime)as nvarchar(2))+'-'+cast(datepart(dd,@StartTime)as nvarchar(2)) +' 00:00:00.000')  
--if ( @ShiftName<>'DAY' and  @ShiftName<>'')  
--BEGIN  
 CREATE TABLE #ShiftTemp     
 (    
 PDate datetime,    
 ShiftName nvarchar(20),    
 FromTime datetime,    
 ToTime datetime    
 )    
 if ( @ShiftName<>'DAY' and  @ShiftName<>'')  
BEGIN  
  
 While(@counter <= @EndTime)  
 BEGIN  
 Insert into #ShiftTemp(PDate,ShiftName, FromTime, ToTime)  
 Exec s_GetShiftTime @counter,@ShiftName  
 SELECT @counter = Dateadd(Day,1,@counter)  
 END  

 If @Param = 'Summary'      
 Begin      
 IF isnull(@AlarmGroup,'ALL')= 'ALL' or @AlarmGroup=''      
 Begin    
    
  Select ROW_NUMBER() OVER (ORDER BY T.MaxAlarmtime desc) AS ID,T.MachineID,T.FromTime,T.ToTime,T.ShiftName,T.AlarmNo,T.AlarmMessage,T.NOofOccurences,T.MinAlarmTime,T.MaxAlarmtime, T.FilePath as DocPath,T.Colorcode as color  
  from (       
  select A.MachineID,S.ShiftName as ShiftName, S.FromTime as FromTime,S.ToTime as ToTime,A.Alarmno as AlarmNo,A.AlarmMSG as AlarmMessage,Count(A.AlarmNo) as NOofOccurences,Min(A.AlarmTime) as MinAlarmTime,Max(A.AlarmTime) as MaxAlarmtime,F.FilePath,  
  Case when (max(A.AlarmTime) between dateadd(minute,-15,@curtime) and @curtime) and A.Ackstatus IS NULL then '1' else '0' end as colorcode     
  from Focas_AlarmHistory a cross join #ShiftTemp S  
  left outer join Focas_AlarmCategory c on  a.AlarmGroupNo = c.AlarmNo     
  left outer join (SELECT DISTINCT Alarmno,FilePath from Focas_AlarmMaster) F on A.Alarmno=F.AlarmNo     
  where (AlarmTime between FromTime and  ToTime)        
  and (machineId=@machineid or ISNULL(@machineid,'')='')
  AND (A.AlarmMSG LIKE '%'+@AlarmFilter+'%' OR ISNULL(@AlarmFilter,'') = '')
  Group by A.MachineID,A.Alarmno,A.AlarmMSG,F.FilePath,A.Ackstatus, S.ShiftName, S.FromTime,S.ToTime)T     
  Order by T.MaxAlarmtime desc    
 End          
 ELSE      
 Begin   
  Select ROW_NUMBER() OVER (ORDER BY T.MaxAlarmtime desc) AS ID,T.MachineID,T.FromTime,T.ToTime,T.ShiftName,T.AlarmNo,T.AlarmMessage,T.NOofOccurences,T.MinAlarmTime,T.MaxAlarmtime, T.FilePath as DocPath,T.Colorcode as color  
  from (       
  select A.MachineID,S.ShiftName as ShiftName, S.FromTime as FromTime,S.ToTime as ToTime,A.Alarmno as AlarmNo,A.AlarmMSG as AlarmMessage,Count(A.AlarmNo) as NOofOccurences,Min(A.AlarmTime) as MinAlarmTime,Max(A.AlarmTime) as MaxAlarmtime,F.FilePath,  
  Case when (max(A.AlarmTime) between dateadd(minute,-15,@curtime) and @curtime) and A.Ackstatus IS NULL then '1' else '0' end as colorcode     
  from Focas_AlarmHistory a cross join #ShiftTemp S  
  left outer join Focas_AlarmCategory c on  a.AlarmGroupNo = c.AlarmNo     
  left outer join (SELECT DISTINCT Alarmno,FilePath from Focas_AlarmMaster) F on A.Alarmno=F.AlarmNo     
  where (AlarmTime between @StartTime and @EndTime)  
  and   
   ( a.AlarmNo < 1150  OR a.AlarmNo > 1172 )   
  and AlarmGroupNo =  @AlarmGroup and (machineId=@machineid or ISNULL(@machineid,'')='')
  AND (A.AlarmMSG LIKE '%'+@AlarmFilter+'%' OR ISNULL(@AlarmFilter,'') = '')
  Group by A.MachineID,A.Alarmno,A.AlarmMSG,F.FilePath,A.Ackstatus, S.ShiftName, S.FromTime,S.ToTime)T     
  Order by T.MaxAlarmtime desc   
 End       
 End      
      
 if (@Param = 'Details')  
 Begin      
 IF isnull(@AlarmGroup,'ALL')= 'ALL' or @AlarmGroup=''      
 Begin      
  select distinct ROW_NUMBER() OVER (ORDER BY A.AlarmTime desc) AS ID,A.MachineID,S.FromTime,S.ToTime,S.ShiftName, A.Alarmno,A.AlarmGroupNo,C.name as AlarmCategory,A.AlarmMSG,A.AlarmTime,       
  Case when F.flag='1' then 'User Serviceable'       
  when F.flag='2' then 'MTB Serviceable' End as ServiceFlag,A.Endtime,dbo.f_FormatTime(Datediff(Second,A.AlarmTime,A.endtime),'hh:mm:ss') as AlarmDuration      
  from Focas_AlarmHistory a  cross join   #ShiftTemp S   
  left outer join (
  SELECT DISTINCT Alarmno,flag from Focas_AlarmMaster
  ) F on A.Alarmno=F.AlarmNo      
  left outer join Focas_AlarmCategory c on  a.AlarmGroupNo = c.AlarmNo      
  where (AlarmTime between FromTime and  ToTime) 
  and (machineId=@machineid or ISNULL(@machineid,'')='')   
    AND (A.AlarmMSG LIKE '%'+@AlarmFilter+'%' OR ISNULL(@AlarmFilter,'') = '')
  order by AlarmTime desc      
 End      
      
 ELSE      
 Begin      
  select distinct ROW_NUMBER() OVER (ORDER BY A.AlarmTime desc) AS ID,A.MachineID,S.FromTime,S.ToTime,S.ShiftName, A.Alarmno,A.AlarmGroupNo,C.name as AlarmCategory,A.AlarmMSG,A.AlarmTime,       
  Case when F.flag='1' then 'User Serviceable'       
  when F.flag='2' then 'MTB Serviceable' End as ServiceFlag      
  from Focas_AlarmHistory a  cross join   #ShiftTemp S      
  left outer join (SELECT DISTINCT Alarmno,flag from Focas_AlarmMaster) F 
  on A.Alarmno=F.AlarmNo      
  left outer join Focas_AlarmCategory c on  a.AlarmGroupNo = c.AlarmNo      
  where AlarmGroupNo =  @AlarmGroup and (machineId=@machineid 
  or ISNULL(@machineid,'')='') and (AlarmTime between FromTime and ToTime) 
   AND (A.AlarmMSG LIKE '%'+@AlarmFilter+'%' OR ISNULL(@AlarmFilter,'') = '')
  order by AlarmTime desc      
 End      
 End      
      
 if (@Param = 'Userservice')      
 Begin      
 IF isnull(@AlarmGroup,'ALL')= 'ALL' or @AlarmGroup=''      
 Begin      
  select ROW_NUMBER() OVER (ORDER BY A.AlarmTime desc) AS ID,A.MachineID,S.FromTime,S.ToTime,S.ShiftName, A.Alarmno,A.AlarmGroupNo,C.name as AlarmCategory,A.AlarmMSG,A.AlarmTime      
  ,'User Serviceable' as ServiceFlag from Focas_AlarmHistory a  cross join #ShiftTemp S     
  inner join (SELECT DISTINCT Alarmno,flag from Focas_AlarmMaster where Flag='1') F on A.Alarmno=F.AlarmNo      
  left outer join Focas_AlarmCategory c on  a.AlarmGroupNo = c.AlarmNo      
  where (AlarmTime between FromTime and  ToTime) and (machineId=@machineid or ISNULL(@machineid,'')='') and F.flag='1' 
    AND (A.AlarmMSG LIKE '%'+@AlarmFilter+'%' OR ISNULL(@AlarmFilter,'') = '')    
  order by AlarmTime desc      
 End      
      
 ELSE      
 Begin      
  select ROW_NUMBER() OVER (ORDER BY A.AlarmTime desc) AS ID,A.MachineID,S.FromTime,S.ToTime,S.ShiftName, A.Alarmno,A.AlarmGroupNo,C.name as AlarmCategory,A.AlarmMSG,A.AlarmTime      
  ,'User Serviceable' as ServiceFlag from Focas_AlarmHistory a   cross join #ShiftTemp S     
  inner join (SELECT DISTINCT Alarmno,flag from Focas_AlarmMaster where Flag='1') F on A.Alarmno=F.AlarmNo      
  left outer join Focas_AlarmCategory c on  a.AlarmGroupNo = c.AlarmNo      
  where AlarmGroupNo =  @AlarmGroup and (machineId=@machineid or ISNULL(@machineid,'')='') and (AlarmTime between FromTime and ToTime)      
  AND A.AlarmMSG LIKE '%'+@AlarmFilter+'%'  AND (A.AlarmMSG LIKE '%'+@AlarmFilter+'%' OR ISNULL(@AlarmFilter,'') = '')

  and F.flag='1' order by AlarmTime desc      
  End      
 End      
      
 if (@Param = 'MTBService')      
 Begin      
 IF isnull(@AlarmGroup,'ALL')= 'ALL' or @AlarmGroup=''      
 Begin      
  select ROW_NUMBER() OVER (ORDER BY A.AlarmTime desc) AS ID,A.MachineID,S.FromTime,S.ToTime,S.ShiftName, A.Alarmno,A.AlarmGroupNo,C.name as AlarmCategory,A.AlarmMSG,A.AlarmTime      
  ,'MTB Serviceable' as ServiceFlag from Focas_AlarmHistory a cross join #ShiftTemp S      
  inner join (SELECT DISTINCT Alarmno,flag from Focas_AlarmMaster where Flag='2') F on A.Alarmno=F.AlarmNo      
  left outer join Focas_AlarmCategory c on  a.AlarmGroupNo = c.AlarmNo      
  where (AlarmTime between FromTime and  ToTime)and (machineId=@machineid or ISNULL(@machineid,'')='') and F.flag='2'   
    AND (A.AlarmMSG LIKE '%'+@AlarmFilter+'%' OR ISNULL(@AlarmFilter,'') = '')
  order by AlarmTime desc      
 End      
      
 ELSE      
 Begin      
  select ROW_NUMBER() OVER (ORDER BY A.AlarmTime desc) AS ID,A.MachineID,S.FromTime,S.ToTime,S.ShiftName, A.Alarmno,A.AlarmGroupNo,C.name as AlarmCategory,A.AlarmMSG,A.AlarmTime      
  ,'MTB Serviceable' as ServiceFlag from Focas_AlarmHistory a cross join #ShiftTemp S          
  inner join (SELECT DISTINCT Alarmno,flag from Focas_AlarmMaster where Flag='2') F on A.Alarmno=F.AlarmNo      
  left outer join Focas_AlarmCategory c on  a.AlarmGroupNo = c.AlarmNo      
  where AlarmGroupNo =  @AlarmGroup and (machineId=@machineid or ISNULL(@machineid,'')='') and (AlarmTime between FromTime and ToTime)      
    AND (A.AlarmMSG LIKE '%'+@AlarmFilter+'%' OR ISNULL(@AlarmFilter,'') = '')
  and F.flag='2' order by AlarmTime desc      
 End      
 End      
 ------------------------------------ ER0376 Added Till here -------------------------------------      
 END    
  
  
if (@ShiftName='DAY' or @ShiftName='')  
BEGIN  
  
  
 While(@counter <= @EndTime)  
 BEGIN  
 Insert into #ShiftTemp(PDate,ShiftName, FromTime, ToTime)  
 Exec s_GetShiftTime @counter,'' 
 SELECT @counter = Dateadd(Day,1,@counter)  
 END  
 
Select @T_ST=min(FromTime) from #ShiftTemp
Select @T_ED=max(ToTime) from #ShiftTemp 

 If @Param = 'Summary'      
 Begin      
   IF isnull(@AlarmGroup,'ALL')= 'ALL' or @AlarmGroup=''      
   Begin    
   --Select ROW_NUMBER() OVER (ORDER BY T.MaxAlarmtime desc) AS ID,T.AlarmNo,T.AlarmMessage,T.NOofOccurences,T.MinAlarmTime,T.MaxAlarmtime, 'D:\Images\abc.pdf' as DocPath  
   Select ROW_NUMBER() OVER (ORDER BY T.MaxAlarmtime desc) AS ID,T.MachineID,T.AlarmNo,T.AlarmMessage,T.NOofOccurences,T.MinAlarmTime,T.MaxAlarmtime, T.FilePath as DocPath,T.Colorcode as color  
   from (       
   select A.MachineID,A.Alarmno as AlarmNo,A.AlarmMSG as AlarmMessage,Count(A.AlarmNo) as NOofOccurences,Min(A.AlarmTime) as MinAlarmTime,Max(A.AlarmTime) as MaxAlarmtime,F.FilePath,  
   Case when (max(A.AlarmTime) between dateadd(minute,-15,@curtime) and @curtime) and A.Ackstatus IS NULL then '1' else '0' end as colorcode     
   from Focas_AlarmHistory a   
   left outer join Focas_AlarmCategory c on  a.AlarmGroupNo = c.AlarmNo     
   left outer join (SELECT DISTINCT Alarmno,FilePath from Focas_AlarmMaster) F on A.Alarmno=F.AlarmNo     
  -- where (AlarmTime between @StartTime and @EndTime)  and   
    where (AlarmTime between @T_ST and @T_ED)  and  
   ( a.AlarmNo < 1150  OR a.AlarmNo > 1172 )   
   and (machineId=@machineid or ISNULL(@machineid,'')='') 
     AND (A.AlarmMSG LIKE '%'+@AlarmFilter+'%' OR ISNULL(@AlarmFilter,'') = '')
   Group by A.MachineID,A.Alarmno,A.AlarmMSG,F.FilePath,A.Ackstatus)T     
   Order by T.MaxAlarmtime desc  
   End          
   ELSE      
   Begin       
   --Select ROW_NUMBER() OVER (ORDER BY T.MaxAlarmtime desc) AS ID,T.AlarmNo,T.AlarmMessage,T.NOofOccurences,T.MinAlarmTime,T.MaxAlarmtime, 'D:\Images\abc.pdf' as DocPath from (       
   Select ROW_NUMBER() OVER (ORDER BY T.MaxAlarmtime desc) AS ID,T.MachineID,T.AlarmNo,T.AlarmMessage,T.NOofOccurences,T.MinAlarmTime,T.MaxAlarmtime, T.FilePath as DocPath,T.Colorcode as color from (       
   select A.MachineID,A.Alarmno as AlarmNo,A.AlarmMSG as AlarmMessage,Count(A.AlarmNo) as NOofOccurences,Min(A.AlarmTime) as MinAlarmTime,Max(A.AlarmTime) as MaxAlarmtime,F.FilePath ,  
   Case when (max(A.AlarmTime) between dateadd(minute,-15,@curtime) and @curtime) and A.Ackstatus IS NULL then '1' else '0' end as colorcode     
   from Focas_AlarmHistory  a  
   left outer join Focas_AlarmCategory c on  a.AlarmGroupNo = c.AlarmNo      
   left outer join (SELECT DISTINCT Alarmno,FilePath from Focas_AlarmMaster) F on A.Alarmno=F.AlarmNo    
   where AlarmGroupNo =  @AlarmGroup      
   and (machineId=@machineid or ISNULL(@machineid,'')='') 
   --and (AlarmTime between @StartTime and @EndTime)     
   and (AlarmTime between @T_ST and @T_ED)  
   and ( a.AlarmNo < 1150  OR a.AlarmNo > 1172 )
     AND (A.AlarmMSG LIKE '%'+@AlarmFilter+'%' OR ISNULL(@AlarmFilter,'') = '')
   Group by A.MachineID,A.Alarmno,A.AlarmMSG,F.FilePath,A.Ackstatus)T Order by T.MaxAlarmtime desc      
   End       
 End      
      
if (@Param = 'Details')      
Begin      
IF isnull(@AlarmGroup,'ALL')= 'ALL' or @AlarmGroup=''      
 Begin      
   select distinct ROW_NUMBER() OVER (ORDER BY A.AlarmTime desc) AS ID,A.MachineID, A.Alarmno,A.AlarmGroupNo,C.name as AlarmCategory,A.AlarmMSG,A.AlarmTime,       
   Case when F.flag='1' then 'User Serviceable'       
   when F.flag='2' then 'MTB Serviceable' End as ServiceFlag,A.Endtime,dbo.f_FormatTime(Datediff(Second,A.AlarmTime,A.endtime),'hh:mm:ss') as AlarmDuration    
   from Focas_AlarmHistory a       
   left outer join (SELECT DISTINCT Alarmno,flag from Focas_AlarmMaster) F on A.Alarmno=F.AlarmNo      
   left outer join Focas_AlarmCategory c on  a.AlarmGroupNo = c.AlarmNo      
   --where (AlarmTime between @StartTime and  @EndTime) 
    where (AlarmTime between @T_ST and @T_ED)    
   and (machineId=@machineid or ISNULL(@machineid,'')='')    
     AND (A.AlarmMSG LIKE '%'+@AlarmFilter+'%' OR ISNULL(@AlarmFilter,'') = '')
   order by AlarmTime desc      
 End      
      
ELSE      
 Begin      
  select distinct ROW_NUMBER() OVER (ORDER BY A.AlarmTime desc) AS ID, A.MachineID,A.Alarmno,A.AlarmGroupNo,C.name as AlarmCategory,A.AlarmMSG,A.AlarmTime,       
  Case when F.flag='1' then 'User Serviceable'       
  when F.flag='2' then 'MTB Serviceable' End as ServiceFlag      
  from Focas_AlarmHistory a       
  left outer join (SELECT DISTINCT Alarmno,flag from Focas_AlarmMaster) F on A.Alarmno=F.AlarmNo      
  left outer join Focas_AlarmCategory c on  a.AlarmGroupNo = c.AlarmNo      
  where AlarmGroupNo =  @AlarmGroup and (machineId=@machineid or ISNULL(@machineid,'')='') and (AlarmTime between @T_ST and @T_ED)      
    AND (A.AlarmMSG LIKE '%'+@AlarmFilter+'%' OR ISNULL(@AlarmFilter,'') = '')
  order by AlarmTime desc      
 End      
End      
      
if (@Param = 'Userservice')      
Begin      
IF isnull(@AlarmGroup,'ALL')= 'ALL' or @AlarmGroup=''      
 Begin      
   select ROW_NUMBER() OVER (ORDER BY A.AlarmTime desc) AS ID, A.MachineID,A.Alarmno,A.AlarmGroupNo,C.name as AlarmCategory,A.AlarmMSG,A.AlarmTime      
   ,'User Serviceable' as ServiceFlag from Focas_AlarmHistory a       
   inner join (SELECT DISTINCT Alarmno,flag from Focas_AlarmMaster where flag='1') F on A.Alarmno=F.AlarmNo      
   left outer join Focas_AlarmCategory c on  a.AlarmGroupNo = c.AlarmNo      
  -- where (AlarmTime between @StartTime and  @EndTime) 
   where (AlarmTime between @T_ST and @T_ED)    
   and (machineId=@machineid or ISNULL(@machineid,'')='') and F.flag='1'    
    AND (A.AlarmMSG LIKE '%'+@AlarmFilter+'%' OR ISNULL(@AlarmFilter,'') = '')
   order by AlarmTime desc      
 End      
      
ELSE      
 Begin      
  select ROW_NUMBER() OVER (ORDER BY A.AlarmTime desc) AS ID,A.MachineID, A.Alarmno,A.AlarmGroupNo,C.name as AlarmCategory,A.AlarmMSG,A.AlarmTime      
  ,'User Serviceable' as ServiceFlag from Focas_AlarmHistory a       
  inner join (SELECT DISTINCT Alarmno,flag from Focas_AlarmMaster where flag='1') F on A.Alarmno=F.AlarmNo      
  left outer join Focas_AlarmCategory c on  a.AlarmGroupNo = c.AlarmNo      
  where AlarmGroupNo =  @AlarmGroup and (machineId=@machineid or ISNULL(@machineid,'')='') 
  --and (AlarmTime between @StartTime and @EndTime) 
  and (AlarmTime between @T_ST and @T_ED)   
    AND (A.AlarmMSG LIKE '%'+@AlarmFilter+'%' OR ISNULL(@AlarmFilter,'') = '') 
  and F.flag='1' order by AlarmTime desc      
 End      
End      
      
if (@Param = 'MTBService')      
Begin      
IF isnull(@AlarmGroup,'ALL')= 'ALL' or @AlarmGroup=''      
 Begin      
   select ROW_NUMBER() OVER (ORDER BY A.AlarmTime desc) AS ID,A.MachineID, A.Alarmno,A.AlarmGroupNo,C.name as AlarmCategory,A.AlarmMSG,A.AlarmTime      
   ,'MTB Serviceable' as ServiceFlag from Focas_AlarmHistory a       
   inner join (SELECT DISTINCT Alarmno,flag from Focas_AlarmMaster where flag='2') F on A.Alarmno=F.AlarmNo      
   left outer join Focas_AlarmCategory c on  a.AlarmGroupNo = c.AlarmNo      
   --where (AlarmTime between @StartTime and  @EndTime) 
   where (AlarmTime between @T_ST and @T_ED)  
   and (machineId=@machineid or ISNULL(@machineid,'')='') and F.flag='2'  
   AND (A.AlarmMSG LIKE '%'+@AlarmFilter+'%' OR ISNULL(@AlarmFilter,'') = '')  
   order by AlarmTime desc      
 End      
      
ELSE      
 Begin      
  select ROW_NUMBER() OVER (ORDER BY A.AlarmTime desc) AS ID,A.MachineID, A.Alarmno,A.AlarmGroupNo,C.name as AlarmCategory,A.AlarmMSG,A.AlarmTime      
  ,'MTB Serviceable' as ServiceFlag from Focas_AlarmHistory a       
  inner join (SELECT DISTINCT Alarmno,flag from Focas_AlarmMaster where flag='2') F on A.Alarmno=F.AlarmNo      
  left outer join Focas_AlarmCategory c on  a.AlarmGroupNo = c.AlarmNo      
  where AlarmGroupNo =  @AlarmGroup and (machineId=@machineid or ISNULL(@machineid,'')='') 
  --and (AlarmTime between @StartTime and @EndTime)      
  and  (AlarmTime between @T_ST and @T_ED)  
  and F.flag='2' 
    AND (A.AlarmMSG LIKE '%'+@AlarmFilter+'%' OR ISNULL(@AlarmFilter,'') = '')
  order by AlarmTime desc      
 End      
End    
 END   
End      
