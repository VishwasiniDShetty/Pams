/****** Object:  Procedure [dbo].[Focas_PredictiveMaintenanceReport]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[Focas_PredictiveMaintenanceReport] '2017-09-06 16:44:59.000','ACE-01'
CREATE PROCEDURE [dbo].[Focas_PredictiveMaintenanceReport] 
 @Date datetime,      
 @MachineID nvarchar(50) = '',        
 @Param nvarchar(20)= ''
AS    
BEGIN 

select FM.AlarmNo, T1.AlarmDesc,FM.TargetValue,FM.ActualValue,T1.DurationIn,
(FM.TargetValue-FM.ActualValue) as Hoursleft from
	(select FM1.AlarmNo,Max(FM1.Timestamp) as TS,FMaster.AlarmDesc,FMaster.DurationIn from Focas_PredictiveMaintenance FM1 
	inner join dbo.Focas_PredictiveMaintenanceMaster FMaster on FM1.AlarmNo=FMaster.AlarmNo
	inner join Machineinformation M on M.MachineMTB=FMaster.MTB and M.Machineid=FM1.Machineid
	where FM1.Timestamp<=@Date and M.machineid = @machineid  and FMaster.IsEnabled=1 
	group by FM1.AlarmNo,FMaster.DurationIn ,FMaster.AlarmDesc
	)T1
inner join dbo.Focas_PredictiveMaintenance FM on T1.AlarmNo=FM.AlarmNo and T1.TS=FM.Timestamp

End    
