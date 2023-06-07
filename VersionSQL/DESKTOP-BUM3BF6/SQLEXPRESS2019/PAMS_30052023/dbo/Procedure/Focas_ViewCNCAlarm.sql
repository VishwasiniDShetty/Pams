/****** Object:  Procedure [dbo].[Focas_ViewCNCAlarm]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[Focas_ViewCNCAlarm]   
 @AlarmNo bigint,
 @param nvarchar(50) = '',
 @Machineid nvarchar(50) = '' 

AS  
BEGIN  
If @Param = 'ACE'
Begin 
	SELECT row_number() over (order by F.alarmno) as slno, F.AlarmNo,  F.FilePath, F.Description, F.Cause, F.Solution
	FROM Focas_AlarmMaster F --Inner Join Machineinformation M on F.MTB=M.MachineMTB
	where F.MTB='ACE' AND F.AlarmNo=@AlarmNo --and M.Machineid=@Machineid
ENd

If @Param = 'AMS'
Begin 

	SELECT row_number() over (order by F.alarmno) as slno, F.AlarmNo,  F.FilePath, F.Description, F.Cause, F.Solution,F.AddressTag,F.AlarmAddress
	FROM Focas_AlarmMaster F 
	where F.MTB='AMS' AND F.AlarmNo=@AlarmNo 
--SELECT 
--   Row_number() over (order by F1.alarmno) as slno,F1.AlarmNo,F1.Cause,F1.AddressTag,F1.AlarmAddress,
--   STUFF((SELECT '^ ' + F2.Solution
--          FROM Focas_AlarmMaster F2 Inner Join Machineinformation M on F2.MTB=M.MachineMTB
--          WHERE F2.MTB='AMS' and F2.AlarmNo=@AlarmNo and M.Machineid=@Machineid and F1.AlarmNo=F2.AlarmNo and F1.Cause=F2.Cause 
--          ORDER BY F1.AlarmNo
--          FOR XML PATH('')), 1, 1, '') Solution
--FROM Focas_AlarmMaster F1  Inner Join Machineinformation M on F1.MTB=M.MachineMTB 
--where F1.MTB='AMS' AND F1.AlarmNo=@AlarmNo and M.Machineid=@Machineid
--GROUP BY F1.AlarmNo,F1.Cause,F1.MTB,F1.AddressTag,F1.AlarmAddress

ENd

If @Param = 'MGTL'
Begin 
	SELECT row_number() over (order by F.alarmno) as slno, F.AlarmNo,  F.FilePath, F.Description, F.Cause, F.Solution
	FROM Focas_AlarmMaster F --Inner Join Machineinformation M on F.MTB=M.MachineMTB
	where F.MTB='MGTL' AND F.AlarmNo=@AlarmNo
ENd

End  
