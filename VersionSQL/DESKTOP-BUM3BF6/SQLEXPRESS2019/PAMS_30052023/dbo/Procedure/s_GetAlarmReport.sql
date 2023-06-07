/****** Object:  Procedure [dbo].[s_GetAlarmReport]    Committed by VersionSQL https://www.versionsql.com ******/

--ER0376 - SwathiKS - 18/Feb/2014 :: To show Summary, Details, User Serviceable and MTB Serviceable.
--s_GetAlarmReport'2014-01-17 06:00:00 AM','2014-01-18 06:00:00 AM','DNM-04','','MTBservice'

CREATE PROCEDURE [dbo].[s_GetAlarmReport]
	@StartTime datetime,
	@EndTime datetime,
	@MachineID nvarchar(50) = '',
	@AlarmGroup nvarchar(20)='ALL',
	@Param nvarchar(20)= 'Summary'
	
AS
BEGIN

/* ER0376 Commented From here
if (@Param = 'Summary')
Begin
IF isnull(@AlarmGroup,'ALL')= 'ALL' or @AlarmGroup=''
	Begin
	 select ROW_NUMBER() OVER (ORDER BY AlarmTime desc) AS ID,  a.*, c.Name as AlarmCategory, c.Name as ServiceFlag
     from Focas_AlarmHistory a left outer join Focas_AlarmCategory c
     on  a.AlarmGroupNo = c.AlarmNo
     where (AlarmTime between @StartTime and  @EndTime)
	 and machineId=@MachineID
	 order by AlarmTime desc
	End

ELSE

	Begin
		Select   ROW_NUMBER() OVER (ORDER BY AlarmTime desc) AS ID,a.*, c.Name as AlarmCategory,c.Name as ServiceFlag
        from Focas_AlarmHistory  a left outer join Focas_AlarmCategory c
        on  a.AlarmGroupNo = c.AlarmNo
        where AlarmGroupNo =  @AlarmGroup and
		machineId=@MachineID and (AlarmTime between @StartTime and @EndTime)
		order by AlarmTime desc
	End
End
 ER0376 Commented Till here */


------------------------------------ ER0376 Added From here -------------------------------------
If @Param = 'Summary'
Begin
	IF isnull(@AlarmGroup,'ALL')= 'ALL' or @AlarmGroup=''
	Begin
		 Select ROW_NUMBER() OVER (ORDER BY T.MaxAlarmtime desc) AS ID,T.AlarmNo,T.AlarmMessage,T.NOofOccurences,T.MinAlarmTime,T.MaxAlarmtime from ( 
		 select A.Alarmno as AlarmNo,A.AlarmMSG as AlarmMessage,Count(A.AlarmNo) as NOofOccurences,Min(A.AlarmTime) as MinAlarmTime,Max(A.AlarmTime) as MaxAlarmtime
		 from Focas_AlarmHistory a left outer join Focas_AlarmCategory c on  a.AlarmGroupNo = c.AlarmNo
		 where (AlarmTime between @StartTime and  @EndTime)
		 and machineId=@MachineID Group by A.Alarmno,A.AlarmMSG)T Order by T.MaxAlarmtime desc
	End

	ELSE
	Begin
		Select ROW_NUMBER() OVER (ORDER BY T.MaxAlarmtime desc) AS ID,T.AlarmNo,T.AlarmMessage,T.NOofOccurences,T.MinAlarmTime,T.MaxAlarmtime from ( 
		select A.Alarmno as AlarmNo,A.AlarmMSG as AlarmMessage,Count(A.AlarmNo) as NOofOccurences,Min(A.AlarmTime) as MinAlarmTime,Max(A.AlarmTime) as MaxAlarmtime
        from Focas_AlarmHistory  a left outer join Focas_AlarmCategory c on  a.AlarmGroupNo = c.AlarmNo
        where AlarmGroupNo =  @AlarmGroup and
		machineId=@MachineID and (AlarmTime between @StartTime and @EndTime)
		Group by A.Alarmno,A.AlarmMSG)T Order by T.MaxAlarmtime desc
	End	
End

if (@Param = 'Details')
Begin
IF isnull(@AlarmGroup,'ALL')= 'ALL' or @AlarmGroup=''
	Begin
		 select ROW_NUMBER() OVER (ORDER BY A.AlarmTime desc) AS ID, A.Alarmno,A.AlarmGroupNo,C.name as AlarmCategory,A.AlarmMSG,A.AlarmTime, 
		 Case when F.flag='1' then 'User Serviceable' 
		 when F.flag='2' then 'MTB Serviceable' End as ServiceFlag
		 from Focas_AlarmHistory a 
		 left outer join Focas_AlarmMaster F on A.Alarmno=F.AlarmNo
		 left outer join Focas_AlarmCategory c on  a.AlarmGroupNo = c.AlarmNo
		 where (AlarmTime between @StartTime and  @EndTime) and machineId=@MachineID
		 order by AlarmTime desc
	End

ELSE
	Begin
		select ROW_NUMBER() OVER (ORDER BY A.AlarmTime desc) AS ID, A.Alarmno,A.AlarmGroupNo,C.name as AlarmCategory,A.AlarmMSG,A.AlarmTime, 
		Case when F.flag='1' then 'User Serviceable' 
		when F.flag='2' then 'MTB Serviceable' End as ServiceFlag
		from Focas_AlarmHistory a 
		left outer join Focas_AlarmMaster F on A.Alarmno=F.AlarmNo
		left outer join Focas_AlarmCategory c on  a.AlarmGroupNo = c.AlarmNo
		where AlarmGroupNo =  @AlarmGroup and machineId=@MachineID and (AlarmTime between @StartTime and @EndTime)
		order by AlarmTime desc
	End
End

if (@Param = 'Userservice')
Begin
IF isnull(@AlarmGroup,'ALL')= 'ALL' or @AlarmGroup=''
	Begin
		 select ROW_NUMBER() OVER (ORDER BY A.AlarmTime desc) AS ID, A.Alarmno,A.AlarmGroupNo,C.name as AlarmCategory,A.AlarmMSG,A.AlarmTime
		 ,'User Serviceable' as ServiceFlag from Focas_AlarmHistory a 
		 inner join Focas_AlarmMaster F on A.Alarmno=F.AlarmNo
		 left outer join Focas_AlarmCategory c on  a.AlarmGroupNo = c.AlarmNo
		 where (AlarmTime between @StartTime and  @EndTime) and machineId=@MachineID and F.flag='1'
		 order by AlarmTime desc
	End

ELSE
	Begin
		select ROW_NUMBER() OVER (ORDER BY A.AlarmTime desc) AS ID, A.Alarmno,A.AlarmGroupNo,C.name as AlarmCategory,A.AlarmMSG,A.AlarmTime
		,'User Serviceable' as ServiceFlag from Focas_AlarmHistory a 
		inner join Focas_AlarmMaster F on A.Alarmno=F.AlarmNo
		left outer join Focas_AlarmCategory c on  a.AlarmGroupNo = c.AlarmNo
		where AlarmGroupNo =  @AlarmGroup and machineId=@MachineID and (AlarmTime between @StartTime and @EndTime)
		and F.flag='1' order by AlarmTime desc
	End
End

if (@Param = 'MTBService')
Begin
IF isnull(@AlarmGroup,'ALL')= 'ALL' or @AlarmGroup=''
	Begin
		 select ROW_NUMBER() OVER (ORDER BY A.AlarmTime desc) AS ID, A.Alarmno,A.AlarmGroupNo,C.name as AlarmCategory,A.AlarmMSG,A.AlarmTime
		 ,'MTB Serviceable' as ServiceFlag from Focas_AlarmHistory a 
		 inner join Focas_AlarmMaster F on A.Alarmno=F.AlarmNo
		 left outer join Focas_AlarmCategory c on  a.AlarmGroupNo = c.AlarmNo
		 where (AlarmTime between @StartTime and  @EndTime) and machineId=@MachineID and F.flag='2'
		 order by AlarmTime desc
	End

ELSE
	Begin
		select ROW_NUMBER() OVER (ORDER BY A.AlarmTime desc) AS ID, A.Alarmno,A.AlarmGroupNo,C.name as AlarmCategory,A.AlarmMSG,A.AlarmTime
		,'MTB Serviceable' as ServiceFlag from Focas_AlarmHistory a 
		inner join Focas_AlarmMaster F on A.Alarmno=F.AlarmNo
		left outer join Focas_AlarmCategory c on  a.AlarmGroupNo = c.AlarmNo
		where AlarmGroupNo =  @AlarmGroup and machineId=@MachineID and (AlarmTime between @StartTime and @EndTime)
		and F.flag='2' order by AlarmTime desc
	End
End
------------------------------------ ER0376 Added Till here -------------------------------------

End
 
