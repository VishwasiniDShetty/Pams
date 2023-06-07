/****** Object:  Procedure [dbo].[Focas_PushTempToHistory]    Committed by VersionSQL https://www.versionsql.com ******/

--select * from [Focas_ToolOffsetHistoryTemp]
--[dbo].[Focas_PushTempToHistory] 'AMIT-02','OffsetHistory'
CREATE PROCEDURE [dbo].[Focas_PushTempToHistory]
@MachineID nvarchar(50)='',
@Parameter nvarchar(50)=''  --offsetHistory,Predictive
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

if @parameter='OffsetHistory'
BEGIN
SELECT [MachineID],[ProgramNo],[OffsetNo],[WearOffsetX],[WearOffsetZ],[WearOffsetR],[WearOffsetT],[CNCTimeStamp],[MachineMode],[ToolNo]
into #FTOT  FROM [dbo].[Focas_ToolOffsetHistoryTemp] where (MachineID is not null) and ([ProgramNo] is not null) and (MachineID=@machineid)

--BEGIN TRY
--For inserting into main table.

--Insert into [dbo].[Focas_ToolOffsetHistory](Machineid,[ProgramNumber],[OffsetNo],[WearOffsetX],[WearOffsetZ],[WearOffsetR],[WearOffsetT],[MachineTimeStamp],[MachineMode],[ToolNo])
--Select #MO.Machineid,#MO.[ProgramNo],#MO.[OffsetNo],#MO.[WearOffsetX],#MO.[WearOffsetZ],#MO.[WearOffsetR],#MO.[WearOffsetT],#MO.[CNCTimeStamp],#MO.[MachineMode],#MO.[ToolNo]
-- from [dbo].[Focas_ToolOffsetHistoryTemp] #MO
--where not exists(select * from  [dbo].[Focas_ToolOffsetHistory] MO where MO.MachineID=#MO.MachineID and MO.[OffsetNo]=#Mo.[OffsetNo] and MO.[ProgramNumber]=#MO.[ProgramNo] )
 
 Insert into [dbo].[Focas_ToolOffsetHistory](Machineid,[ProgramNumber],[OffsetNo],[WearOffsetX],[WearOffsetZ],[WearOffsetR],[WearOffsetT],[MachineTimeStamp],[MachineMode],[ToolNo])
Select #FTOT.Machineid,#FTOT.[ProgramNo],#FTOT.[OffsetNo],#FTOT.[WearOffsetX],#FTOT.[WearOffsetZ],#FTOT.[WearOffsetR],#FTOT.[WearOffsetT],#FTOT.[CNCTimeStamp],#FTOT.[MachineMode],
#FTOT.[ToolNo] from #FTOT 
where not exists(select * from  [dbo].[Focas_ToolOffsetHistory] MO where MO.MachineID=#FTOT.MachineID and MO.[OffsetNo]=#FTOT.[OffsetNo] and MO.[ProgramNumber]=#FTOT.[ProgramNo] )
 
Insert into [dbo].[Focas_ToolOffsetHistory](Machineid,[ProgramNumber],[OffsetNo],[WearOffsetX],[WearOffsetZ],[WearOffsetR],[WearOffsetT],[MachineTimeStamp],[MachineMode],[ToolNo])
select T2.Machineid,T2.programNo,T2.offsetNo,T2.WearoffsetX,T2.WearoffsetZ,T2.WearoffsetR,T2.WearoffsetT,T2.CNCTimeSTamp,T2.MachineMode,T2.ToolNo from 
(select FTHP.* from 
(select   FTH.machineID,FTH.[ProgramNumber],FTH.offsetNO,max(FTH.MachineTimeStamp) as MachineTimeStamp from 
  [Focas_ToolOffsetHistory] FTH
group by FTH.machineID,FTH.[ProgramNumber],FTH.offsetNO)T inner join [Focas_ToolOffsetHistory] FTHP 
on T.MachineID=FTHP.MachineID and T.[OffsetNo]=FTHP.[OffsetNo] and T.[ProgramNumber]=FTHP.[ProgramNumber] and T.MachineTimeStamp=FTHP.MachineTimeStamp) T1
 inner join #FTOT T2 on T1.MachineID=t2.MachineID and T1.[OffsetNo]=t2.[OffsetNo] and T1.[ProgramNumber]=t2.[ProgramNo]
where  (T1.[WearOffsetX] <>T2.[WearOffsetX] or T1.[WearOffsetZ]<>T2.[WearOffsetZ] or T1.[WearOffsetR]<>T2.[WearOffsetR] or  T1.[WearOffsetR]<>T2.[WearOffsetR] )

--END TRY

--BEGIN CATCH

--END CATCH

END

if @Parameter='Predictive'

BEGIN

SELECT Machineid,AlarmNo,TargetValue,ActualValue,[TimeStamp]
into #FPMT  FROM [Focas_PredictiveMaintenanceTemp] where (MachineID is not null) and (AlarmNo is not null) and (MachineID=@machineid)
--For inserting into main table.  
BEGIN TRY

Insert into [dbo].[Focas_PredictiveMaintenance](Machineid,AlarmNo,TargetValue,ActualValue,[TimeStamp])
Select #FPMT.Machineid,#FPMT.AlarmNo,#FPMT.TargetValue,#FPMT.ActualValue,#FPMT.[TimeStamp] from #FPMT
where not exists(select * from  [dbo].[Focas_PredictiveMaintenance] MO where MO.MachineID=#FPMT.MachineID and MO.AlarmNo=#FPMT.AlarmNo )

Insert into [dbo].[Focas_PredictiveMaintenance](Machineid,AlarmNo,TargetValue,ActualValue,[TimeStamp])
select T2.MachineID, T2.AlarmNo,T2.TargetValue,T2.ActualValue,T2.[Timestamp] from 
(select FTHP.* from 
(select    FPM.machineID,FPM.AlarmNo,max(FPM.[Timestamp]) as [Timestamp]  from 
  [Focas_PredictiveMaintenance] FPM
group by FPM.machineID,FPM.AlarmNo)T inner join [Focas_PredictiveMaintenance] FTHP 
on T.MachineID=FTHP.MachineID and T.AlarmNo=FTHP.AlarmNo  and T.[Timestamp]=FTHP.[Timestamp]) T1
 inner join #FPMT T2 on T1.MachineID=t2.MachineID and T1.AlarmNo=t2.AlarmNo 
where  (T1.TargetValue <>T2.TargetValue or T1.ActualValue<>T2.ActualValue  )

END TRY

BEGIN CATCH

END CATCH

END

END
