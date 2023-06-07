/****** Object:  Procedure [dbo].[s_GetFocasHourwiseLiveDetails]    Committed by VersionSQL https://www.versionsql.com ******/

/***************************************************************************************************
--NR0098 - SwathiKS - 26/Dec/2013 :: Created New Procedure to Get Hourwise Powerontime,Operatingtime and Cuttingtime for the selected Machine and Day.
--vasavi-15/Apr/2015::To introduce new parameter-'Summary' to get machineid,programno and partscount.  
-- DR0363-Vasavi-06/Jun/2015 ::To Optimize the proc and to remove passing 'Summary' parameter.
--DR0364-Vasavi-28/Jun/2015 :: machineStatus = 'In Cycle' and MachineMode = 'MEM' while calculating parts count in Summary.
SwathiKS - 29/Jul/2015 :: To calculate Programwise Partscount for the given Machine and Time Period Level.
--[dbo].[s_GetFocasHourwiseLiveDetails] '2016-04-06','','CNC GRINDING','','hour'  
*****************************************************************************************************/

CREATE procedure [dbo].[s_GetFocasHourwiseLiveDetails]    
 @Starttime datetime,    
 @PlantID nvarchar(50),    
 @Machine nvarchar(50),    
 @prgno int,    
 @Param nvarchar(20)=''   

WITH RECOMPILE 
AS    
BEGIN    

	SET NOCOUNT ON;

if (@startTime>getdate())
Begin
set @startTime=getdate()
End

Create Table #LiveDetails    
(    
 [Sl No] Bigint Identity(1,1) Not Null,    
 [Machineid] nvarchar(50),    
 [From Time] datetime,    
 [To time] datetime,    
 [Powerontime] float,    
 [Cutting time] float,    
 [Operating time] float,
 [ProgramNo] nvarchar(100), --vas
 [PartsCount] int   --vas 
)    
--DR0363 added from here.
Create Table #LiveDetails1  
(    
 [Sl No] Bigint Identity(1,1) Not Null,    
 [Machineid] nvarchar(50),    
 [From Time] datetime,    
 [To time] datetime,    
 [Powerontime] float,    
 [Cutting time] float,    
 [Operating time] float,
 [ProgramNo] nvarchar(100), --vas
 [PartsCount] int   --vas 
)    
 -- DR0363 till from here.  
Create table #Day    
(    
 [From Time] datetime,    
 [To time] datetime    
)    
    
declare @startdate as datetime    
select @startdate = @starttime    
Declare @Endtime as datetime    
  
Set @StartTime =dbo.f_GetLogicalDayStart (@StartTime)
Set @EndTime = DATEADD(HOUR,24,@StartTime)    
    
while @StartTime<@EndTime    
BEGIN    
 Insert into #LiveDetails([Machineid],[From Time],[To time],[Powerontime],[Cutting time],[Operating time])    
 Select @Machine,@StartTime,DATEADD(HOUR,1,@StartTime),0,0,0    
 SELECT @StartTime=DATEADD(HOUR,1,@StartTime)    
END    
  
Update #LiveDetails set [Powerontime]  = Isnull([Powerontime],0) + ISNULL(T1.PTime,0),    
[Cutting time]  = Isnull([Cutting time],0) + ISNULL(T1.CTime,0),    
[Operating time] = Isnull([Operating time],0) + ISNULL(T1.OTime,0) from     
(Select F.machineid,L.[From Time] as Fromtime,L.[To time] as Totime,Max(F.Powerontime) - Min(F.Powerontime) as Ptime,    
Max(F.CutTime)- Min(F.CutTime) as CTime,Max(F.OperatingTime)- Min(F.OperatingTime) as OTime from dbo.Focas_LiveData F    
inner join #LiveDetails L on L.machineid=F.machineid and F.cnctimestamp>=L.[From Time] and F.cnctimestamp<=L.[To Time]    
where F.machineid=@Machine   
---and (F.Powerontime>0 and F.CutTime>0 and F.operatingTime>0)   
group by F.machineid,L.[From Time],L.[To time])T1    
inner join #LiveDetails on #LiveDetails.[From Time] = T1.Fromtime and #LiveDetails.Machineid = T1.MachineID    
    
Update #LiveDetails Set [Cutting time] = [Cutting time]/60 where [Cutting time]>0     
Update #LiveDetails Set [Operating time] = [Operating time] /60 where [Operating time]>0    
  
If @param = '' or @param='Summary'
Begin  
	Select [Sl No],[From Time],[To time],Round([Powerontime],2) as [Powerontime],Round([Cutting time],2) as [Cutting time],    
	Round([Operating time],2) as  [Operating time] From #LiveDetails Order by [From Time]    
End 
  
/*    
Create Table #LiveDetails    
(    
 [Sl No] Bigint Identity(1,1) Not Null,    
 [Machineid] nvarchar(50),    
 [From Time] datetime,    
 [To time] datetime,    
 [Min Powerontime] float,    
 [Max Powerontime] float,    
 [Powerontime] float,    
 [Min Cutting time] float,    
 [Max Cutting time] float,    
 [col1_id] INT,    
 [col2_ID] INT,    
 [Cutting time] float,    
 [CycleCount] int,    
 [Prog No] int,    
 [Tool No] int,    
 [BatchID] int    
)    
    
create table #tooldetails    
(    
 [Sl No] Bigint,    
 [Machineid] nvarchar(50),    
 [From Time] datetime,    
 [Prog No] int,    
 [Tool No] int,    
 [TotalCutting time] float    
)    
    
    
create table #Cuttingdetails    
(    
 [From Time] datetime,    
 [Machineid] nvarchar(50),    
 [col1_id] INT,    
 [col2_ID] INT,    
 [BatchID] int    
)    
    
Create table #Day    
(    
 [From Time] datetime,    
 [To time] datetime    
)    
    
declare @startdate as datetime    
select @startdate = @starttime    
Declare @Endtime as datetime    
Set @StartTime = dbo.f_GetLogicalDay(@StartTime,'start')    
Set @EndTime = DATEADD(HOUR,24,@StartTime)    
    
If @param = 'powerontime' or @param = 'Cuttingtime' or @param = 'CycleCount' or @param='Programdetails'    
BEGIN    
 while @StartTime<@EndTime    
 BEGIN    
  Insert into #LiveDetails([Machineid],[From Time],[To time])    
  Select @Machine,@StartTime,DATEADD(HOUR,1,@StartTime)    
  SELECT @StartTime=DATEADD(HOUR,1,@StartTime)    
 END    
END    
    
If @param = 'powerontime'    
BEGIN    
    
 Update #LiveDetails set [Min Powerontime]  = isnull([Min Powerontime],0) + Isnull(T2.Powerontime,0)  From    
 (select T1.TS,F.Powerontime from    
 (select L.[From Time] as TS,F.machineid,Min(F.cnctimestamp) as CNCTS from dbo.Focas_LiveData F    
 inner join #LiveDetails L on L.machineid=F.machineid and F.cnctimestamp>=L.[From Time] and F.cnctimestamp<=L.[To Time]    
 where F.machineid=@Machine and F.Powerontime>0 group by F.machineid,L.[From Time]    
 )T1 inner join dbo.Focas_LiveData F on F.machineid=T1.machineid and F.CNCtimestamp=T1.CNCTS    
 )T2 inner join #LiveDetails on #LiveDetails.[From Time] = T2.TS    
    
 Update #LiveDetails set [Max Powerontime]  = isnull([Max Powerontime] ,0) + Isnull(T2.Powerontime,0)  From    
 (select T1.TS,F.Powerontime from    
 (select L.[From Time] as TS,F.machineid,Max(F.cnctimestamp) as CNCTS from dbo.Focas_LiveData F    
 inner join #LiveDetails L on L.machineid=F.machineid and F.cnctimestamp>=L.[From Time] and F.cnctimestamp<=L.[To Time]    
 where F.machineid=@Machine and F.Powerontime>0 group by F.machineid,L.[From Time]    
 )T1 inner join dbo.Focas_LiveData F on F.machineid=T1.machineid and F.CNCtimestamp=T1.CNCTS    
 )T2 inner join #LiveDetails on #LiveDetails.[From Time] = T2.TS    
    
 Update #LiveDetails set [Powerontime]  = Isnull([Powerontime],0) + ISNULL(T1.PTime,0) from     
 (Select [From Time] as TS,[To time],[Max Powerontime] - [Min Powerontime] as Ptime from #LiveDetails)T1    
 inner join #LiveDetails on #LiveDetails.[From Time] = T1.TS    
     
 Select [Sl No],[From Time],[To time],Isnull(Round([Powerontime],4),0) as [Powerontime] From #LiveDetails    
END    
    
    
If @param = 'Cuttingtime'    
BEGIN    
     
 Update #LiveDetails set [Min Cutting time]  = isnull([Min Cutting time] ,0) + Isnull(T2.Cuttingtime,0)  From    
 (select T1.TS,F.Cuttingtime from    
 (select L.[From Time]  as TS,F.machineid,Min(machinetimestamp) as MachineTS from dbo.Focas_ToolOffsetHistory F    
 inner join #LiveDetails L on L.machineid=F.machineid and F.machinetimestamp>=L.[From Time]  and F.machinetimestamp<=L.[To Time]     
 where F.machineid=@Machine and  Cuttingtime>0 group by F.machineid,L.[From Time]     
 )T1 inner join dbo.Focas_ToolOffsetHistory F on F.machineid=T1.machineid and F.machinetimestamp=T1.MachineTS    
 )T2 inner join #LiveDetails on #LiveDetails.[From Time] = T2.TS    
    
 Update #LiveDetails set [Max Cutting time]  = isnull([Max Cutting time] ,0) + isnull(T2.Cuttingtime,0)  From    
 (select T1.TS,F.Cuttingtime from    
 (select L.[From Time]  as TS,F.machineid,Max(machinetimestamp) as MachineTS from dbo.Focas_ToolOffsetHistory F    
 inner join #LiveDetails L on L.machineid=F.machineid and F.machinetimestamp>=L.[From Time]  and F.machinetimestamp<=L.[To Time]     
 where F.machineid=@Machine and Cuttingtime>0 group by F.machineid,L.[From Time]     
 )T1 inner join dbo.Focas_ToolOffsetHistory F on F.machineid=T1.machineid and F.machinetimestamp=T1.MachineTS    
 )T2 inner join #LiveDetails on #LiveDetails.[From Time] = T2.TS    
    
 Update #LiveDetails set [Cutting time]  = Isnull([Cutting time],0) + ISNULL(T1.CTime,0) from     
 (Select [From Time] as TS,[To time],[Max Cutting time]- [Min Cutting time] as Ctime from #LiveDetails    
  where [Max Cutting time]- [Min Cutting time]>4)T1    
 inner join #LiveDetails on #LiveDetails.[From Time] = T1.TS    
     
 Select [Sl No],[From Time],[To time],Isnull(Round([Cutting time]/60,4),0) as [Cutting time] From #LiveDetails    
END    
    
    
If @param = 'CycleCount'    
BEGIN    
    
    
 Update #Livedetails set CycleCount = isnull(Cyclecount,0) + isnull(T.cycle,0) from    
 ( Select mc,L.[From Time] as TS,Sum(Partscount) as cycle from Autodata A    
   inner join Machineinformation M on M.interfaceid=A.mc    
   inner join #LiveDetails L on L.machineid=M.machineid     
   inner join (Select Distinct F.machineid,F.Programnumber from Focas_ToolOffsetHistory F inner join #LiveDetails L on L.machineid=F.machineid     
   where F.machinetimestamp>=L.[From Time] and F.machinetimestamp<=L.[To Time]) F     
   on F.machineid=M.machineid and F.ProgramNumber = A.comp     
   Where F.machineid=@machine and A.ndtime>L.[From Time] and A.ndtime<=L.[To Time]    
   Group by mc,L.[From Time]    
 ) T inner join #Livedetails on #LiveDetails.[From Time] = T.TS    
    
 Select [Sl No],[From Time],[To time],Isnull([CycleCount],0) as [CycleCount] From #LiveDetails    
END    
    
If @param='ProgramDetails'    
BEGIN    
    
 while @StartTime<@EndTime    
 BEGIN    
  Insert into #day([From Time],[To time])    
  Select  @StartTime,DATEADD(HOUR,1,@StartTime)    
  SELECT @StartTime=DATEADD(HOUR,1,@StartTime)    
 END    
    
/*    
 Insert into #Cuttingdetails([col1_id],[col2_ID],[From Time])    
 select S1.id as s1id,min(S2.id) as s2id,C.[From Time]    
 from Focas_ToolOffsetHistory s1,Focas_ToolOffsetHistory s2, #day C    
 where s1.id<s2.id and S1.Programnumber<>0 and S1.Programnumber<9000 and s1.toolno<>0 and s1.cuttingtime>0 and s1.machinetimestamp>=C.[From Time] and S1.Machinetimestamp<=C.[To time]    
 and S2.Programnumber<>0 and S2.Programnumber<9000 and s2.toolno<>0 and s2.cuttingtime>0 and S1.Programnumber<>S2.Programnumber and s2.machinetimestamp>=C.[From Time] and S2.Machinetimestamp<=C.[To time]    
    and S1.machineid=@machine and S2.machineid=@machine group by S1.id,C.[From Time]    
    
 Declare @Col1ID int,@Col2ID int,@Col2ID_prev int    
 Declare @BatchID int,@BatchID_Prev int    
 Declare @GetBatchID CURSOR     
 set @GetBatchID = CURSOR FOR    
 select [col1_id],Col2_id from #Cuttingdetails order by [col2_id]    
 OPEN @GetBatchID    
    
 FETCH NEXT FROM @GetBatchID INTO @Col1ID,@Col2ID    
    
 set @BatchID_Prev =1    
 set @Col2ID_prev = @Col2ID    
    
 WHILE @@FETCH_STATUS = 0    
 BEGIN    
  If  @Col2ID_prev=@Col2ID    
  BEGIN    
   Update #Cuttingdetails set [BatchID] = @BatchID_Prev where [col1_id]=@Col1ID    
  END    
  Else    
  BEGIN    
   set @BatchID_Prev = @BatchID_Prev + 1    
   set @Col2ID_prev = @Col2ID    
   Update #Cuttingdetails set [BatchID] = @BatchID_Prev where [col1_id]=@Col1ID     
  end    
    
 FETCH NEXT FROM @GetBatchID INTO @Col1ID,@Col2ID    
    
 END    
    
 CLOSE @GetBatchID;    
 DEALLOCATE @GetBatchID;    
  
 Insert into #Livedetails(Machineid,[From Time],[To time],[col1_id],[Col2_id],[BatchID],[Prog No] )    
 select T1.Machine,T1.[From Time],T1.[To time],T1.C1ID,T1.C2ID,T1.BID,0 from    
 (    
 select @Machine as Machine,D.[From Time],D.[To time],min([col1_id]) as C1ID,max([Col2_id]) as C2ID,[BatchID] as BID from #Cuttingdetails     
 right outer join #day D on D.[From Time] =#Cuttingdetails.[From Time] group by [BatchID],D.[From Time],D.[To time]    
 )T1 Order by T1.[From Time]    
    
    
 Update #Livedetails set CycleCount = isnull(Cyclecount,0) + isnull(T.cycle,0) from    
 ( Select mc,comp,L.[From Time] as TS,Sum(Partscount) as cycle from Autodata A    
   inner join Machineinformation M on M.interfaceid=A.mc    
   inner join dbo.Focas_ToolOffsetHistory F on F.machineid=M.machineid and F.ProgramNumber = A.comp    
   inner join #LiveDetails L on L.machineid=F.machineid and L.[prog no]=F.Programnumber and F.machinetimestamp>=L.[From Time] and F.machinetimestamp<=L.[To Time]    
   Where F.machineid=@machine and (A.ndtime>L.[From Time] and A.ndtime<=L.[To Time])    
   Group by mc,comp,L.[From Time]    
 ) T inner join #Livedetails on #LiveDetails.[From Time] = T.TS and #LiveDetails.[Prog No] = T.comp    
    
 Update #LiveDetails set [Min Cutting time]  = isnull([Min Cutting time],0) + Isnull(T2.Cuttingtime,0),[Prog No] = isnull([Prog No],0) + isnull(T2.ProgramNumber,0)  From    
 (select F.ProgramNumber,F.Cuttingtime,L.[col1_id] as ID from dbo.Focas_ToolOffsetHistory F    
 inner join #LiveDetails L on L.[col1_id]=F.ID     
 )T2 inner join #LiveDetails on #LiveDetails.[col1_id] = T2.ID    
     
 Update #LiveDetails set [Max Cutting time]  = isnull([Max Cutting time],0) + Isnull(T2.Cuttingtime,0) From    
 (select F.ProgramNumber,F.Cuttingtime,L.[col2_id] as ID from dbo.Focas_ToolOffsetHistory F    
 inner join #LiveDetails L on L.[col2_id]=F.ID     
 )T2 inner join #LiveDetails on #LiveDetails.[col2_id] = T2.ID    
    
 Update #LiveDetails set [Cutting time] = isnull([Cutting time],0) + isnull(T1.Ctime,0) from    
 ( select [From Time] as TS,[Prog No] as comp,[Max Cutting time]- [Min Cutting time] as Ctime,[col1_id],[col2_id] from #LiveDetails    
 where [Max Cutting time]- [Min Cutting time]>4 )T1    
 inner join #LiveDetails on #LiveDetails.[From Time] = T1.TS and #LiveDetails.[Prog No] = T1.comp and #LiveDetails.[col1_id] = T1.[col1_id] and #LiveDetails.[col2_id] = T1.[col2_id]    
*/    
    
 Insert into #LiveDetails(Machineid,[Prog No],[From Time],[To time])    
 Select Distinct F.Machineid,F.ProgramNumber,L.[From Time],L.[To Time]  from dbo.Focas_ToolOffsetHistory F    
 inner join #LiveDetails L on L.machineid=F.machineid and F.machinetimestamp>=L.[From Time] and F.machinetimestamp<=L.[To Time]     
 where F.machineid=@Machine and Programnumber>0 and Programnumber<9000 and Cuttingtime>0    
    
 Update #LiveDetails set [Min Cutting time]  = isnull([Min Cutting time],0) + Isnull(T3.Cuttingtime,0) From    
 (Select T2.Fromtime as Fromtime,F.Cuttingtime,F.ProgramNumber from    
  (select L.[From Time] as fromtime,Min(Machinetimestamp) as ts from dbo.Focas_ToolOffsetHistory F    
   inner join #LiveDetails L on L.machineid=F.machineid and F.Programnumber=L.[Prog No]    
   where F.machinetimestamp>=L.[From Time] and F.machinetimestamp<=L.[To Time] group by  L.[From Time]    
  )T2 inner join Focas_ToolOffsetHistory F on F.Machinetimestamp= T2.TS    
 )T3 inner join #LiveDetails on #LiveDetails.[From Time] = T3.Fromtime and #LiveDetails.[Prog No]=T3.ProgramNumber    
    
 Update #LiveDetails set [Max Cutting time]  = isnull([Max Cutting time],0) + Isnull(T3.Cuttingtime,0) From    
 (Select T2.Fromtime as Fromtime,F.Cuttingtime,F.ProgramNumber from    
  (select L.[From Time] as fromtime,Max(Machinetimestamp) as ts from dbo.Focas_ToolOffsetHistory F    
   inner join #LiveDetails L on L.machineid=F.machineid and F.Programnumber=L.[Prog No]    
   where F.machinetimestamp>=L.[From Time] and F.machinetimestamp<=L.[To Time] group by  L.[From Time]    
  )T2 inner join Focas_ToolOffsetHistory F on F.Machinetimestamp= T2.TS    
 )T3 inner join #LiveDetails on #LiveDetails.[From Time] = T3.Fromtime and #LiveDetails.[Prog No]=T3.ProgramNumber    
    
 Update #LiveDetails set [Cutting time] = isnull([Cutting time],0) + isnull(T1.Ctime,0) from    
 ( select [From Time] as TS,[Prog No] as comp,[Max Cutting time]- [Min Cutting time] as Ctime from #LiveDetails    
 where [Max Cutting time]- [Min Cutting time]>4 )T1    
 inner join #LiveDetails on #LiveDetails.[From Time] = T1.TS and #LiveDetails.[Prog No] = T1.comp     
    
 Update #Livedetails set CycleCount = isnull(Cyclecount,0) + isnull(T.cycle,0) from    
 ( Select mc,L.[From Time] as TS,Sum(Partscount) as cycle,comp from Autodata A    
   inner join Machineinformation M on M.interfaceid=A.mc    
   inner join #LiveDetails L on L.machineid=M.machineid and L.[Prog No]=A.comp    
   Where L.machineid=@machine and A.ndtime>L.[From Time] and A.ndtime<=L.[To Time]    
   Group by mc,L.[From Time],comp    
 ) T inner join #Livedetails on #LiveDetails.[From Time] = T.TS and #LiveDetails.[Prog No] = T.comp     
    
    
 Select  ROW_NUMBER() OVER (ORDER BY [From Time]  asc) AS [Sl No],[From Time],[Prog No] ,Isnull([CycleCount],0) as [CycleCount],dbo.f_FormatTime(isnull(Round([Cutting time],4),0),'hh:mm:ss') as [Cutting time] From #LiveDetails    
 where [Cutting time] >0   Order by [From Time]     
    
END    
    
If @param='ToolDetails'    
BEGIN    
    
 select @EndTime = DATEADD(HOUR,1,@startdate)    
    
 while @Startdate<@EndTime    
 BEGIN    
  Insert into #day([From Time],[To time])    
  Select @Startdate,DATEADD(HOUR,1,@Startdate)    
  SELECT @Startdate=DATEADD(HOUR,1,@Startdate)    
 END    
    
 Insert into #Cuttingdetails([col1_id],[col2_ID],[From Time])    
 select S1.id as s1id,min(S2.id) as s2id,C.[From Time]    
 from Focas_ToolOffsetHistory s1,Focas_ToolOffsetHistory s2, #day C    
 where s1.id<s2.id and S1.Programnumber<>0 and s1.toolno<>0 and s1.cuttingtime>0 and s1.machinetimestamp>=C.[From Time] and S1.Machinetimestamp<=C.[To time]    
 and S2.Programnumber<>0 and s2.toolno<>0 and s2.cuttingtime>0 and (S1.Programnumber<>S2.Programnumber or s1.toolno<>s2.toolno) and s2.machinetimestamp>=C.[From Time] and S2.Machinetimestamp<=C.[To time]    
    and S1.machineid=@machine and S2.machineid=@machine and S1.Programnumber=@prgno  group by S1.id,C.[From Time]    
    
    Declare @Col1ID int,@Col2ID int,@Col2ID_prev int    
 Declare @BatchID int,@BatchID_Prev int    
 Declare @GetBatchID CURSOR     
 set @GetBatchID = CURSOR FOR    
 select [col1_id],Col2_id from #Cuttingdetails order by [col2_id]    
 OPEN @GetBatchID    
    
 FETCH NEXT FROM @GetBatchID INTO @Col1ID,@Col2ID    
    
 set @BatchID_Prev =1    
 set @Col2ID_prev = @Col2ID    
    
 WHILE @@FETCH_STATUS = 0    
 BEGIN    
  If  @Col2ID_prev=@Col2ID    
  BEGIN    
   Update #Cuttingdetails set [BatchID] = @BatchID_Prev where [col1_id]=@Col1ID    
  END    
  Else    
  BEGIN    
   set @BatchID_Prev = @BatchID_Prev + 1    
   set @Col2ID_prev = @Col2ID    
   Update #Cuttingdetails set [BatchID] = @BatchID_Prev where [col1_id]=@Col1ID     
  end    
    
 FETCH NEXT FROM @GetBatchID INTO @Col1ID,@Col2ID    
    
 END    
    
 CLOSE @GetBatchID;    
 DEALLOCATE @GetBatchID;    
    
 Insert into #Livedetails(Machineid,[From Time],[To time],[col1_id],[Col2_id],[BatchID],[Prog No],[Tool No])    
 select T1.Machine,T1.[From Time],T1.[To time],T1.C1ID,T1.C2ID,T1.BID,0,0 from    
 (    
 select @Machine as Machine,D.[From Time],D.[To time],min([col1_id]) as C1ID,max([Col2_id]) as C2ID,[BatchID] as BID from #Cuttingdetails     
 right outer join #day D on D.[From Time] =#Cuttingdetails.[From Time] group by [BatchID],D.[From Time],D.[To time]    
 )T1 Order by T1.[From Time]    
    
 Update #LiveDetails set [Min Cutting time]  = isnull([Min Cutting time],0) + Isnull(T2.Cuttingtime,0),[Prog No] = isnull([Prog No],0) + isnull(T2.ProgramNumber,0)    
 ,[Tool No] = isnull([Tool No],0) + isnull(T2.ToolNo,0)  From    
 (select F.ProgramNumber,F.ToolNo,F.Cuttingtime,L.[col1_id] as ID from dbo.Focas_ToolOffsetHistory F    
 inner join #LiveDetails L on L.[col1_id]=F.ID     
 )T2 inner join #LiveDetails on #LiveDetails.[col1_id] = T2.ID    
     
 Update #LiveDetails set [Max Cutting time]  = isnull([Max Cutting time],0) + Isnull(T2.Cuttingtime,0) from    
 (select F.ProgramNumber,F.ToolNo,F.Cuttingtime,L.[col2_id] as ID from dbo.Focas_ToolOffsetHistory F    
 inner join #LiveDetails L on L.[col2_id]=F.ID     
 )T2 inner join #LiveDetails on #LiveDetails.[col2_id] = T2.ID    
    
 Update #LiveDetails set [Cutting time] = isnull([Cutting time],0) + isnull(T1.Ctime,0) from    
 ( select [From Time] as TS,[Prog No] as comp,[Tool No] as tool,[Max Cutting time]- [Min Cutting time] as Ctime,[col1_id],[col2_id] from #LiveDetails    
 where [Max Cutting time]- [Min Cutting time] >4)T1    
 inner join #LiveDetails on #LiveDetails.[From Time] = T1.TS and #LiveDetails.[Prog No] = T1.comp and #LiveDetails.[Tool No] = T1.Tool    
 and #LiveDetails.[col1_id] = T1.[col1_id] and #LiveDetails.[col2_id] = T1.[col2_id]    
    
 Insert into #Tooldetails([Machineid],[From Time],[Prog No],[Tool No],[TotalCutting time])    
 Select Machineid,[From Time],[Prog No],[Tool No],SUM([Cutting time]) From #LiveDetails    
 Group by Machineid,[From Time],[Prog No] ,[Tool No]    
    
 Select ROW_NUMBER() OVER (ORDER BY [From Time]  asc) as [Sl No],[From Time],[Prog No] ,[Tool No],dbo.f_FormatTime(isnull(Round([TotalCutting time],4),0),'hh:mm:ss') as [Cutting time] From #Tooldetails    
 Order by [From Time]     
   
END    
*/    
  
-- if @Param='summary'  --DR0363 Commented
if @param='Summary'
Begin    

    Insert into #LiveDetails1([Machineid],[From Time],[To time],[Powerontime],[Cutting time],[Operating time])  
    Select @Machine,dbo.f_GetLogicalDayStart(@startdate),dbo.f_GetLogicalDayEnd(@startdate),0,0,0    
   
    update #LiveDetails1 set [To time]=(case when [To time]>getdate() then getdate()  
    else [To time]  
    end)  

	declare @DataStart as datetime
	declare @DataEnd as datetime

	select @DataStart= (select top 1 [From Time] from #LiveDetails1 order by [From Time])
	select @DataEnd = (select top 1 [To Time] from #LiveDetails1 order by [From Time] desc)

	select MachineID, MachineStatus, MachineMode, ProgramNo, PowerOnTime, OperatingTime, CutTime, CNCTimeStamp, PartsCount, BatchTS, MachineUpDownStatus, MachineUpDownBatchTS,ProgramBlock
	into #FocasLivedata from dbo.focas_livedata with(NOLOCK) where cnctimestamp>=@DataStart and cnctimestamp<=@DataEnd

	  
	Update #LiveDetails1 set [Powerontime]  = Isnull([Powerontime],0) + ISNULL(T1.PTime,0),    
	[Cutting time]  = Isnull([Cutting time],0) + ISNULL(T1.CTime,0),    
	[Operating time] = Isnull([Operating time],0) + ISNULL(T1.OTime,0) from     
	(Select F.machineid,L.[From Time] as Fromtime,L.[To time] as Totime,Max(F.Powerontime) - Min(F.Powerontime) as Ptime,    
	Max(F.CutTime)- Min(F.CutTime) as CTime,Max(F.OperatingTime)- Min(F.OperatingTime) as OTime from #FocasLivedata F    
	inner join #LiveDetails1 L on L.machineid=F.machineid and F.cnctimestamp>=L.[From Time] and F.cnctimestamp<=L.[To Time]    
	where F.machineid=@Machine   	  
	group by F.machineid,L.[From Time],L.[To time])T1    
	inner join #LiveDetails1 on #LiveDetails1.[From Time] = T1.Fromtime and #LiveDetails1.Machineid = T1.MachineID    
	    
	Update #LiveDetails1 Set [Cutting time] = [Cutting time]/60 where [Cutting time]>0     
	Update #LiveDetails1 Set [Operating time] = [Operating time] /60 where [Operating time]>0    
	    
	Select [Sl No],[From Time],[To time],Round([Powerontime],2) as [Powerontime],Round([Cutting time],2) as [Cutting time],  
	DATEDIFF( MINUTE,[From Time],[To time]) as [TotalTime],round(([Operating time]-[Cutting time]),2) as OperatingWithoutCutting,  
	Round(([Powerontime]-[Operating time]),2) as NonOperatingTime,round(((DATEDIFF( MINUTE,[From Time],[To time])-[Powerontime]) ),2) as PowerOffTime,
	Round([Operating time],2) as  [Operating time] From #LiveDetails1 Order by [From Time] 

	--SV From Here
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
	Batchts datetime
)



truncate table #GetParts
truncate table #TempGetParts

Insert into #tempGetParts(Machineid,ProgramNo,Batchts,Partscount)
select F.machineid,min(F.Programno) as ProgramNo,F.Batchts,0 from #FocasLivedata F
			 inner join #LiveDetails1 L on L.machineid=F.machineid and F.cnctimestamp>=L.[From Time] and F.cnctimestamp<L.[To Time] and F.partscount is not null    
			where exists
			(
				select liv.ProgramNo From #FocasLivedata liv with(NOLOCK)
				inner join #LiveDetails1 L1 on L1.machineid=liv.machineid and liv.cnctimestamp>=L1.[From Time] and liv.cnctimestamp<L1.[To Time]    
				where liv.MachineMode = 'MEM' --and liv.MachineStatus = 'In Cycle'  
				and liv.machineid=@machine  and liv.batchts is not null 
				and F.Programno=liv.programno and F.machineid=liv.machineid and F.Batchts=liv.Batchts 
				group by liv.ProgramNo
			 )
			group by F.Machineid,F.BatchTs order by F.batchts 


Insert into #GetParts(Machineid,Fromtime,Totime,ProgramNo,Batchts,Partscount,cnctimestamp)
select T.Machineid,L1.[From Time],L1.[To Time],T.ProgramNo,T.Batchts,Max(F.Partscount)-Min(F.Partscount),min(F.cnctimestamp) from #FocasLivedata F
inner join #tempGetParts T on T.Programno=F.programno and T.machineid=F.machineid and T.Batchts=F.Batchts
inner join #LiveDetails1 L1 on L1.machineid=T.machineid and F.cnctimestamp>=L1.[From Time] and F.CNCTimeStamp<L1.[To Time] 
where F.MachineMode = 'MEM' --and F.MachineStatus = 'In Cycle' 
and F.batchts is not null 
group by T.Machineid,L1.[From Time],L1.[To Time],T.ProgramNo,T.Batchts
order by T.Machineid,L1.[From Time],T.Batchts

--To get last recorded partscount for the previous batchtime
update #getparts set Prevcount=T1.Partscount from
(Select T.machineid,f.Partscount,T.fromtime,T.cnctimestamp from focas_livedata f inner join
	   (Select g.fromtime,g.machineid,g.cnctimestamp,Max(f.id) as idd from focas_livedata f with(NOLOCK) 
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


/*
--Logic to consider Partcount : if Prevcount<Curcount then 1 elseif Prevcount>Curcount or Prevcount=CurCount then 0 and add it to the existing Partscount and Prevcount SHOULD NOT BE NULL.
update #getparts set Partscount=isnull(Partscount,0)  + isnull(T1.Pcount,0) from
(Select machineid,fromtime,cnctimestamp,case
when Prevcount>=Currentcount then 0  
when PrevCount<CurrentCount THEN 1  
when Prevcount is null then 1 end as Pcount from #getparts
)T1
inner join #getparts on #getparts.machineid=T1.Machineid and #GetParts.Fromtime=T1.Fromtime and #GetParts.cnctimestamp=T1.cnctimestamp
*/

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


	Create table #Totalgetparts
	(
		id bigint,
		Machineid nvarchar(50),
		Fromtime datetime,
		Totime datetime,
		ProgramNo nvarchar(50),
		Partscount int,
		Total int,
	    Partnumber nvarchar(4000)
	)

--To Sum up all the Parts at ProgramNo Level for the given Machine and time Period.
Insert into #Totalgetparts(id,Machineid,Fromtime,Totime,ProgramNo,Partscount,total)
--Select row_number() over(order by Machineid) as id, Machineid,Fromtime,Totime,ProgramNo,isnull(Sum(Partscount),0)as Partscount,0 as total into #Totalgetparts from #getparts
--group by Machineid,Fromtime,Totime,ProgramNo order by Machineid,Fromtime
Select row_number() over(order by Machineid) as id, Machineid,Fromtime,Totime,ProgramNo,isnull(Sum(Partscount),0)as Partscount,0 as total from #getparts
group by Machineid,Fromtime,Totime,ProgramNo order by Machineid,Fromtime


update #Totalgetparts set Partnumber = T1.Programblock from
(select F.Programblock,FD.ProgramNo from #Totalgetparts  FD
inner join #FocasLivedata F on FD.ProgramNo=F.ProgramNo)T1 inner join #Totalgetparts F on T1.ProgramNo=F.ProgramNo

select T1.Machineid as [Machineid],T1.ProgramNo,Sum(T1.Partscount) as Partscount,T1.Partnumber from #Totalgetparts T1
 group by T1.Machineid,T1.Programno,T1.Partnumber
--SV till Here


 
  End  
End    
    
	
-- if @param='PartsCountSummary'  
--BEGIN
--	truncate table  #LiveDetails  

--	Insert into #LiveDetails([Machineid],[From Time],[To time],[Powerontime],[Cutting time],[Operating time],[ProgramNo],[PartsCount])  
--	Select @Machine,dbo.f_GetLogicalDayStart(@startdate),dbo.f_GetLogicalDayEnd(@startdate),0,0,0,0,0 
	
--	--Update #LiveDetails set ProgramNo  = Isnull(T1.ProgramNo,0), 
--	--[PartsCount]  = Isnull(T1.[PartsCount],0)  from     
--	--(Select F.machineid,L.[From Time] as Fromtime,L.[To time] as Totime,F.[ProgramNo],F.[PartsCount]
--	-- from dbo.Focas_LiveData F    
--	--inner join #LiveDetails L on L.machineid=F.machineid and F.cnctimestamp>=L.[From Time] and F.cnctimestamp<=L.[To Time]    
--	--where F.machineid=@Machine   )T1    
--	--inner join #LiveDetails on #LiveDetails.[From Time] = T1.Fromtime and #LiveDetails.Machineid = T1.MachineID  
	    
--	select [Machineid],programNo, max(PartsCount) - min(PartsCount) + 1 as PartsCount
--	from (
--		select f.[Machineid], f.programNo,f.PartsCount, row_number() over(order by f.[Machineid]) - row_number() over(order by f.programNo, f.[Machineid]) as grp
--		from dbo.Focas_LiveData F    
--		inner join #LiveDetails L on L.machineid=F.machineid and F.cnctimestamp>=L.[From Time] and F.cnctimestamp<=L.[To Time]    
--		where F.machineid=@Machine and f.PartsCount is not null
--		)		
--	as T
--	group by  [Machineid],programNo
--	order by programNo
--end
