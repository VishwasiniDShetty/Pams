/****** Object:  Procedure [dbo].[Focas_GetLiveData]    Committed by VersionSQL https://www.versionsql.com ******/

--Focas_GetLiveData 'ACE-02'  
 CREATE PROCEDURE [dbo].[Focas_GetLiveData]  
 @MachineID nvarchar(50) = 'ACE-01'  
AS  
BEGIN  
 

SELECT TOP 1 [ID]
      ,[MachineID]
      ,[MachineStatus]
      ,[MachineMode]
      ,[ProgramNo]
      ,[ToolNo]
      ,[OffsetNo]
      ,[SpindleStatus]
      ,[SpindleSpeed]
      ,[SpindleLoad]
      ,[Temperature]
      ,[SpindleTarque]
      ,[FeedRate]      
      ,[PowerOnTime]
      ,[OperatingTime]
      ,[CutTime]
      ,[ServoLoad_XYZ]
      ,[CNCTimeStamp]
      ,c.Name as Alarm
      ,AxisPosition
  FROM [dbo].[Focas_LiveData] left outer join Focas_AlarmCategory c 
       on Focas_LiveData.AlarmNo = c.AlarmNo  
  Where MachineID = @MachineID order by ID Desc  
  
End  
  
