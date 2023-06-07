/****** Object:  Procedure [dbo].[Focas_PushAlarmTempToHistory]    Committed by VersionSQL https://www.versionsql.com ******/

--
--[dbo].[Focas_PushAlarmTempToHistory]  'VMC-06F'
CREATE PROCEDURE [dbo].[Focas_PushAlarmTempToHistory] 
@machineid nvarchar(50)=''
AS
BEGIN

insert into Focas_AlarmHistory (AlarmNo,AlarmGroupNo,AlarmMSG,AlarmAxisNo,
AlarmTotAxisNo,AlarmGCode,AlarmOtherCode,AlarmMPos,AlarmAPos,AlarmTime,MachineID)
select distinct * from Focas_AlarmTemp where MachineID=@machineid and
AlarmTime > 
			(select isnull(max(AlarmTime),'1900-01-01 00:00:00.000') 
			from focas_AlarmHistory
			where MachineID=@machineid
			) 
and AlarmTime is not null order by AlarmTime asc

END
