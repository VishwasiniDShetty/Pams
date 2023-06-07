/****** Object:  Procedure [dbo].[S_Get_SPCSummaryReport]    Committed by VersionSQL https://www.versionsql.com ******/

/*
CreatedBy: Raksha R
CreatedDate: 18-Oct-2022

exec [dbo].[S_Get_SPCSummaryReport] '2022-09-01 06:00:00.000','2022-09-14 06:00:00.000','SHANKAR FORGING','','HUB 30128,GEAR 91002',''
exec [dbo].[S_Get_SPCSummaryReport] '2022-09-05 06:00:00.000','2022-09-06 06:00:00.000','SHANKAR FORGING','',''

exec [dbo].[S_Get_SPCSummaryReport] '2022-09-13 06:00:00.000','2022-09-14 06:00:00.000','SHANKAR FORGING','',''
*/
CREATE procedure [dbo].[S_Get_SPCSummaryReport]
@StartDate datetime='',
@EndDate datetime='',
@PlantID nvarchar(50) = '', 
@MachineID nvarchar(max)='',
@ComponentID nvarchar(max)='',
@ShiftName nvarchar(50)=''

With recompile

AS
BEGIN

  
CREATE TABLE #ShiftDetails     
(    
 PDate datetime,    
 Shift nvarchar(20),    
 ShiftStart datetime,    
 ShiftEnd datetime    
)    
    
CREATE TABLE #T_autodata    
(    
 [mc] [nvarchar](50)not NULL,    
 [comp] [nvarchar](50) NULL,    
 [opn] [nvarchar](50) NULL,    
 [opr] [nvarchar](50) NULL,    
 [dcode] [nvarchar](50) NULL,    
 [sttime] [datetime] not NULL,    
 [ndtime] [datetime] NULL,    
 [datatype] [tinyint] NULL ,    
 [cycletime] [int] NULL,    
 [loadunload] [int] NULL ,    
 [msttime] [datetime] NULL,      
 [PartsCount] decimal(18,5) NULL ,  
 id  bigint not null    
)    
    
ALTER TABLE #T_autodata    
    
ADD PRIMARY KEY CLUSTERED    
(    
 mc,sttime ASC    
)ON [PRIMARY]    

    
CREATE TABLE #Target      
(    
    
MachineID nvarchar(50) NOT NULL,    
machineinterface nvarchar(50),    
Compinterface nvarchar(50),    
CompDescription nvarchar(100),  
Component nvarchar(50) NOT NULL,   
[opn] [nvarchar](50) NULL,  
FromTm datetime,    
ToTm datetime,       
msttime datetime,    
ndtime datetime,    
batchid int,    
autodataid bigint ,  
stdTime float,  
Shift nvarchar(20),  
Pdate datetime  
)    
    
CREATE TABLE #FinalTarget      
(    
 Pdate datetime,  
 Shift nvarchar(20),  
 MachineID nvarchar(50) NOT NULL,    
 machineinterface nvarchar(50),    
 Component nvarchar(50) NOT NULL,    
 Compinterface nvarchar(50),    
 CompDescription nvarchar(100),        
 FromTm datetime,    
 ToTm datetime,       
 ShiftStart datetime,    
 ShiftEnd datetime,    
 batchid int,    
 Utilisedtime float,    
 Components float,    
 Downtime float,    
 ManagementLoss float,    
 MLDown float,  
 stdTime float,  
 CN float default 0,  
 ProductionEfficiency float,  
 AvailabilityEfficiency float,  
 OverallEfficiency float,  
 Downtimecode nvarchar(4000),  
 DowntimeDescription nvarchar(4000),  
 Target float default 0,  
 TotalDowntime float default 0,  
 Runtime float default 0  ,
 SPCRejectionCount int default 0,
 AcceptedQty float default 0
)    
    
    
CREATE TABLE #PlannedDownTimesShift    
(    
 SlNo int not null identity(1,1),    
 Starttime datetime,    
 EndTime datetime,    
 Machine nvarchar(50),    
 MachineInterface nvarchar(50),    
 DownReason nvarchar(50),    
 ShiftSt datetime    
)    
    
Declare @strsql nvarchar(4000)    
Declare @StrPlantid as nvarchar(1000)   
Declare @strmachine nvarchar(max)  
Declare @strComponent nvarchar(max) 
Declare @StrTPMMachines AS nvarchar(1000) 
declare @StrMCJoined as nvarchar(max)  
declare @StrCompJoined as nvarchar(max)  
Declare @CurStrtTime as datetime    
Declare @CurEndTime as datetime    
Declare @T_Start AS Datetime     
Declare @T_End AS Datetime 
declare @timeformat as nvarchar(2000)  

Select @strsql = ''    
select @strPlantID = ''  
Select @StrTPMMachines = ''    
Select @strmachine = ''
Select @strComponent = ''
SELECT @timeformat ='ss'  

Select @timeformat = isnull((select valueintext from cockpitdefaults where parameter='timeformat'),'ss')  
if (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')  
begin  
 select @timeformat = 'ss'  
end  

IF ( SELECT TOP 1 ValueInText FROM  CockpitDefaults WHERE Parameter='TpmEnbMac')='E'    
BEGIN    
	SET  @StrTPMMachines = 'AND MachineInformation.TPMTrakEnabled = 1'    
END    
ELSE    
BEGIN    
	SET  @StrTPMMachines = ' '    
END    
    
if isnull(@machineid,'') <> ''    
Begin    
 --Select @strmachine = ' and ( Machineinformation.MachineID = N''' + @MachineID + ''')'    
	select @StrMCJoined =  (case when (coalesce( +@StrMCJoined + ',''', '''')) = ''''  then 'N''' else @StrMCJoined+',N''' end) +item+'''' from [SplitStrings](@MachineID, ',')    
	if @StrMCJoined = 'N'''''  
		set @StrMCJoined = '' 
	select @MachineID = @StrMCJoined

	SET @strMachine = ' AND Machineinformation.machineid in (' + @MachineID +')'
End   

if isnull(@ComponentID,'') <> ''    
Begin    
	select @StrCompJoined =  (case when (coalesce( +@StrCompJoined + ',''', '''')) = ''''  then 'N''' else @StrCompJoined+',N''' end) +item+'''' from [SplitStrings](@ComponentID, ',')    
	if @StrCompJoined = 'N'''''  
		set @StrCompJoined = '' 
	select @ComponentID = @StrCompJoined

	SET @strComponent = ' AND componentinformation.componentid in (' + @ComponentID +')'
End 

if isnull(@PlantID,'') <> ''    
Begin    
 Select @strPlantID = ' and ( PlantMachine.PlantID = N''' + @PlantID + ''')'    
End    

Select @CurStrtTime=@StartDate    
Select @CurEndTime=@EndDate    
    
    
while @CurStrtTime<=@CurEndTime    
BEGIN    
 INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)    
 EXEC s_GetShiftTime @CurStrtTime,@ShiftName    
 SELECT @CurStrtTime=DATEADD(DAY,1,@CurStrtTime)    
END    

    
delete from #ShiftDetails where ShiftStart>=@EndDate

Select @T_Start=dbo.f_GetLogicalDay(@StartDate,'start')    
Select @T_End=dbo.f_GetLogicalDay(@EndDate,'End')    
    
  
/* Planned Down times for the given time period */    
Select @strsql=''    
select @strsql = 'insert INTO #PlannedDownTimesShift(StartTime,EndTime,Machine,MachineInterface,Downreason,Shiftst)'    
select @strsql = @strsql + 'select    
CASE When StartTime<T1.ShiftStart Then T1.ShiftStart Else StartTime End,    
case When EndTime>T1.ShiftEnd Then T1.ShiftEnd Else EndTime End,    
Machine,MachineInformation.InterfaceID,    
DownReason,T1.ShiftStart    
FROM PlannedDownTimes cross join #ShiftDetails T1    
inner join MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID    
WHERE PDTstatus =1 and (    
(StartTime >= T1.ShiftStart  AND EndTime <=T1.ShiftEnd)    
OR ( StartTime < T1.ShiftStart  AND EndTime <= T1.ShiftEnd AND EndTime > T1.ShiftStart )    
OR ( StartTime >= T1.ShiftStart   AND StartTime <T1.ShiftEnd AND EndTime > T1.ShiftEnd )    
OR ( StartTime < T1.ShiftStart  AND EndTime > T1.ShiftEnd) )'    
select @strsql = @strsql + @strmachine     
select @strsql = @strsql + 'ORDER BY StartTime'    
print @strsql    
exec (@strsql)    
    
    
    
Select @strsql=''    
select @strsql ='insert into #T_autodata '    
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'    
 select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'    
select @strsql = @strsql + ' from autodata where (( sttime >='''+ convert(nvarchar(25),@T_Start,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_End,120)+''' ) OR '    
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_Start,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_End,120)+''' )OR '    
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_Start,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_Start,120)+'''    
     and ndtime<='''+convert(nvarchar(25),@T_End,120)+''' )'    
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_Start,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_End,120)+''' and sttime<'''+convert(nvarchar(25),@T_End,120)+''' ) )'    
print @strsql    
exec (@strsql)    
    
   
    
Select @strsql=''     
Select @strsql= 'insert into #Target(MachineID,machineinterface,Component,CompDescription,Compinterface,opn,Pdate,Shift,FromTm,Totm,stdtime)'    
select @strsql = @strsql + ' SELECT distinct machineinformation.machineid, machineinformation.interfaceid,componentinformation.componentid, componentinformation.Description,
componentinformation.interfaceid, componentoperationpricing.interfaceid,    
T.Pdate,T.Shift,T.shiftstart,T.Shiftend,componentoperationpricing.Cycletime FROM #T_autodata autodata    
INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID     
INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID      
INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID    
AND componentinformation.componentid = componentoperationpricing.componentid    
and componentoperationpricing.machineid=machineinformation.machineid     
inner Join Employeeinformation EI on EI.interfaceid=autodata.opr     
Left Outer Join downcodeinformation DI on DI.interfaceid=autodata.dcode    
Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid     
Cross join #ShiftDetails T    
WHERE ((autodata.msttime >= T.Shiftstart  AND autodata.ndtime <= T.ShiftEnd)    
OR ( autodata.msttime < T.Shiftstart  AND autodata.ndtime <= T.ShiftEnd AND autodata.ndtime >T.Shiftstart )    
OR ( autodata.msttime >= T.Shiftstart AND autodata.msttime <T.ShiftEnd AND autodata.ndtime > T.ShiftEnd)    
OR ( autodata.msttime < T.Shiftstart AND autodata.ndtime > T.ShiftEnd))'    
select @strsql = @strsql + @strmachine + @strPlantID + @strComponent 
--select @strsql = @strsql + ' order by autodata.msttime'    
print @strsql    
exec (@strsql)    



insert into #FinalTarget (MachineID,Component,CompDescription,machineinterface,Compinterface,batchid,ShiftStart,ShiftEnd,Pdate,shift,FromTm,ToTm,stdtime,Utilisedtime,Downtime,Components,ManagementLoss,MLDown)  
select distinct MachineID,Component,CompDescription,machineinterface,Compinterface,batchid,FromTm,ToTm,Pdate,shift,FromTm,ToTm,stdtime,0,0,0,0,0
from #Target t

--For Prodtime    
UPDATE #FinalTarget SET Utilisedtime = isnull(Utilisedtime,0) + isNull(t2.cycle,0)    
from    
(select S.MachineID,S.Component,S.ShiftStart,S.ShiftEnd,    
 sum(case when ((autodata.msttime>=S.ShiftStart) and (autodata.ndtime<=S.ShiftEnd)) then  (autodata.cycletime+autodata.loadunload)    
   when ((autodata.msttime<S.ShiftStart)and (autodata.ndtime>S.ShiftStart)and (autodata.ndtime<=S.ShiftEnd)) then DateDiff(second, S.ShiftStart, autodata.ndtime)    
   when ((autodata.msttime>=S.ShiftStart)and (autodata.msttime<S.ShiftEnd)and (autodata.ndtime>S.ShiftEnd)) then DateDiff(second, autodata.mstTime, S.ShiftEnd)    
   when ((autodata.msttime<S.ShiftStart)and (autodata.ndtime>S.ShiftEnd)) then DateDiff(second, S.ShiftStart, S.ShiftEnd) END ) as cycle    
from #T_autodata autodata     
inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface   
where (autodata.datatype=1) AND(( (autodata.msttime>=S.ShiftStart) and (autodata.ndtime<=S.ShiftEnd))    
OR ((autodata.msttime<S.ShiftStart)and (autodata.ndtime>S.ShiftStart)and (autodata.ndtime<=S.ShiftEnd))    
OR ((autodata.msttime>=S.ShiftStart)and (autodata.msttime<S.ShiftEnd)and (autodata.ndtime>S.ShiftEnd))    
OR((autodata.msttime<S.ShiftStart)and (autodata.ndtime>S.ShiftEnd)))    
group by S.MachineID,S.Component,S.ShiftStart,S.ShiftEnd    
) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component      
and t2.ShiftStart=#FinalTarget.ShiftStart and t2.ShiftEnd=#FinalTarget.ShiftEnd    
    
    
--Type 2    
UPDATE  #FinalTarget SET Utilisedtime = isnull(Utilisedtime,0) - isNull(t2.Down,0)    
FROM    
(Select T1.mc,T1.comp,T1.ShiftStart,T1.ShiftEnd,    
SUM(    
CASE    
 When autodata.sttime <= T1.ShiftStart Then datediff(s, T1.ShiftStart,autodata.ndtime )    
 When autodata.sttime > T1.ShiftStart Then datediff(s,autodata.sttime,autodata.ndtime)    
END) as Down    
From #T_autodata AutoData INNER Join    
 (Select AutoData.mc,AutoData.comp,AutoData.Sttime as sttime,AutoData.NdTime as ndtime,    
  ST1.ShiftStart as ShiftStart,ST1.ShiftEnd as ShiftEnd From #T_autodata AutoData    
  inner join #FinalTarget ST1 ON ST1.MachineInterface=Autodata.mc and ST1.CompInterface=Autodata.Comp   
  Where DataType=1 And DateDiff(Second,AutoData.sttime,AutoData.ndtime)>CycleTime And    
  (AutoData.msttime < ST1.ShiftStart)And (AutoData.ndtime > ST1.ShiftStart) AND (AutoData.ndtime <= ST1.ShiftEnd)    
 ) as T1 on t1.mc=autodata.mc and t1.comp=autodata.comp 
Where AutoData.DataType=2    
And ( autodata.Sttime > T1.Sttime )    
And ( autodata.ndtime <  T1.ndtime )    
AND ( autodata.ndtime >  T1.ShiftStart )    
GROUP BY T1.mc,T1.comp,T1.ShiftStart,T1.ShiftEnd)AS T2 Inner Join #FinalTarget on t2.mc = #FinalTarget.machineinterface and    
t2.comp = #FinalTarget.compinterface 
and t2.ShiftStart=#FinalTarget.ShiftStart and t2.ShiftEnd=#FinalTarget.ShiftEnd    
    
    
    
--Type 3    
UPDATE  #FinalTarget SET Utilisedtime = isnull(Utilisedtime,0) - isNull(t2.Down,0)    
FROM    
(Select T1.mc,T1.comp,T1.ShiftStart,T1.ShiftEnd,    
SUM(CASE    
 When autodata.ndtime > T1.ShiftEnd Then datediff(s,autodata.sttime, T1.ShiftEnd )    
 When autodata.ndtime <= T1.ShiftEnd Then datediff(s , autodata.sttime,autodata.ndtime)    
END) as Down    
From #T_autodata AutoData INNER Join    
 (Select AutoData.mc,AutoData.comp,AutoData.Sttime as sttime,AutoData.NdTime as ndtime,    
  ST1.ShiftStart as ShiftStart,ST1.ShiftEnd as ShiftEnd From #T_autodata AutoData    
  inner join #FinalTarget ST1 ON ST1.MachineInterface=Autodata.mc and ST1.CompInterface=Autodata.Comp 
  Where DataType=1 And DateDiff(Second,AutoData.sttime,AutoData.ndtime)>CycleTime And    
  (AutoData.sttime >= ST1.ShiftStart)And (AutoData.ndtime > ST1.ShiftEnd) and (AutoData.sttime< ST1.ShiftEnd)    
   ) as T1    
ON t1.mc=autodata.mc and t1.comp=autodata.comp    
Where AutoData.DataType=2    
And (T1.Sttime < autodata.sttime)    
And ( T1.ndtime > autodata.ndtime)    
AND (autodata.sttime  <  T1.ShiftEnd)    
GROUP BY T1.mc,T1.comp,T1.ShiftStart,T1.ShiftEnd )AS T2 Inner Join #FinalTarget on t2.mc = #FinalTarget.machineinterface and    
t2.comp = #FinalTarget.compinterface   
and t2.ShiftStart=#FinalTarget.ShiftStart and t2.ShiftEnd=#FinalTarget.ShiftEnd    
    
    
--For Type4    
UPDATE  #FinalTarget SET Utilisedtime = isnull(Utilisedtime,0) - isNull(t2.Down,0)    
FROM    
(Select T1.mc,T1.comp,T1.ShiftStart,T1.ShiftEnd,    
SUM(CASE    
 When autodata.sttime >= T1.ShiftStart AND autodata.ndtime <= T1.ShiftEnd Then datediff(s , autodata.sttime,autodata.ndtime)    
 When autodata.sttime < T1.ShiftStart And autodata.ndtime >T1.ShiftStart AND autodata.ndtime<=T1.ShiftEnd Then datediff(s, T1.ShiftStart,autodata.ndtime )    
 When autodata.sttime >= T1.ShiftStart AND autodata.sttime<T1.ShiftEnd AND autodata.ndtime>T1.ShiftEnd Then datediff(s,autodata.sttime, T1.ShiftEnd )    
 When autodata.sttime<T1.ShiftStart AND autodata.ndtime>T1.ShiftEnd   Then datediff(s , T1.ShiftStart,T1.ShiftEnd)    
END) as Down    
From #T_autodata AutoData INNER Join    
 (Select AutoData.mc,AutoData.comp,AutoData.Sttime as sttime,AutoData.NdTime as ndtime,    
  ST1.ShiftStart as ShiftStart,ST1.ShiftEnd as ShiftEnd  From #T_autodata AutoData    
  inner join #FinalTarget ST1 ON ST1.MachineInterface=Autodata.mc and ST1.CompInterface=Autodata.Comp  
  where DataType=1 And DateDiff(Second,AutoData.sttime,AutoData.ndtime)>CycleTime And     
  (AutoData.msttime <  ST1.ShiftStart) And (AutoData.ndtime > ST1.ShiftEnd)    
 ) as T1    
on t1.mc=autodata.mc and t1.comp=autodata.comp    
Where AutoData.DataType=2    
And (T1.Sttime < autodata.sttime  )    
And ( T1.ndtime >  autodata.ndtime)    
AND (autodata.ndtime  >  T1.ShiftStart)    
AND (autodata.sttime  <  T1.ShiftEnd)    
GROUP BY T1.mc,T1.comp,T1.ShiftStart,T1.ShiftEnd    
 )AS T2 Inner Join #FinalTarget on t2.mc = #FinalTarget.machineinterface and    
t2.comp = #FinalTarget.compinterface   
and t2.ShiftStart=#FinalTarget.ShiftStart and t2.ShiftEnd=#FinalTarget.ShiftEnd    
    
      
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'    
BEGIN    
     
 --Get the utilised time overlapping with PDT and negate it from UtilisedTime    
  UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) - isNull(T2.PPDT ,0)    
  FROM(    
  SELECT F.ShiftStart,F.ShiftEnd,F.machineinterface,F.Compinterface,   
     SUM    
     (CASE    
     WHEN autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN DateDiff(second,autodata.msttime,autodata.ndtime) --DR0325 Added    
     WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)    
     WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )    
     WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )    
     END ) as PPDT    
     FROM #T_autodata AutoData    
     CROSS jOIN #PlannedDownTimesShift T    
     INNER JOIN #FinalTarget F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp     
     WHERE autodata.DataType=1 AND T.MachineInterface=autodata.mc AND    
      ((autodata.msttime >= F.ShiftStart  AND autodata.ndtime <=F.ShiftEnd)    
      OR ( autodata.msttime < F.ShiftStart  AND autodata.ndtime <= F.ShiftEnd AND autodata.ndtime > F.ShiftStart )    
      OR ( autodata.msttime >= F.ShiftStart   AND autodata.msttime <F.ShiftEnd AND autodata.ndtime > F.ShiftEnd )    
      OR ( autodata.msttime < F.ShiftStart  AND autodata.ndtime > F.ShiftEnd))    
      AND    
      ((autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)    
      OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )    
      OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )    
      OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )     
      AND    
      ((F.ShiftStart >= T.StartTime  AND F.ShiftEnd <=T.EndTime)    
      OR ( F.ShiftStart < T.StartTime  AND F.ShiftEnd <= T.EndTime AND F.ShiftEnd > T.StartTime )    
      OR ( F.ShiftStart >= T.StartTime   AND F.ShiftStart <T.EndTime AND F.ShiftEnd > T.EndTime )    
      OR ( F.ShiftStart < T.StartTime  AND F.ShiftEnd > T.EndTime) )     
      group  by F.ShiftStart,F.ShiftEnd,F.machineinterface,F.Compinterface 
  )AS T2  Inner Join #FinalTarget on t2.machineinterface = #FinalTarget.machineinterface and    
  t2.compinterface = #FinalTarget.compinterface   
  and t2.ShiftStart=#FinalTarget.ShiftStart and t2.ShiftEnd=#FinalTarget.ShiftEnd    
    
 ---mod 12:Add ICD's Overlapping  with PDT to Prodtime    
 /* Fetching Down Records from Production Cycle  */    
  ---mod 12(4):Handle intearction between ICD and PDT for type 1 production record for the selected time period.    
  UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)    
  FROM(    
  Select T1.ShiftStart,T1.ShiftEnd,autodata.mc,autodata.comp,   
  SUM(    
  CASE      
   When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1    
   When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2    
   When (autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3    
   when (autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4    
  END) as IPDT    
  from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join     
   (    
    Select autodata.mc,autodata.comp,autodata.Sttime,autodata.NdTime,S.ShiftStart,S.ShiftEnd,S.FromTm     
     from #T_autodata autodata inner join #FinalTarget S on S.MachineInterface=Autodata.mc and S.CompInterface=Autodata.Comp  
    Where DataType=1 And DateDiff(Second, autodata.sttime, autodata.ndtime)>CycleTime And    
    ( autodata.msttime >= S.ShiftStart) AND ( autodata.ndtime <= S.ShiftEnd)    
   ) as T1    
  ON AutoData.mc=T1.mc and autodata.comp=T1.comp  and T.ShiftSt=T1.FromTm     
  Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc    
  And (( autodata.Sttime > T1.Sttime )    
  And ( autodata.ndtime <  T1.ndtime ))    
  AND    
  ((T.StartTime >=T1.Sttime And T.EndTime <=T1.ndtime )    
  or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)    
  or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )    
  or ( T.StartTime <T1.Sttime And T.EndTime >T1.ndtime ))    
  GROUP BY T1.ShiftStart,T1.ShiftEnd,autodata.mc,autodata.comp
  )AS T2  Inner Join #FinalTarget on t2.mc = #FinalTarget.machineinterface and    
  t2.comp = #FinalTarget.compinterface   
  and t2.ShiftStart=#FinalTarget.ShiftStart and t2.ShiftEnd=#FinalTarget.ShiftEnd    
    
  ---mod 12(4)    
  /* If production  Records of TYPE-2*/    
  UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)    
  FROM    
  (Select T1.ShiftStart,T1.ShiftEnd,autodata.mc,autodata.comp,
  SUM(    
  CASE      
   When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1    
   When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2    
   When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3    
   when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4    
  END) as IPDT    
  from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join     
   (    
     Select autodata.mc,autodata.comp,autodata.Sttime,autodata.NdTime,S.ShiftStart,S.ShiftEnd,S.FromTm     
     from #T_autodata autodata inner join #FinalTarget S on S.MachineInterface=Autodata.mc and S.CompInterface=Autodata.Comp   
     Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And    
     (msttime < S.ShiftStart)And (ndtime > S.ShiftStart) AND (ndtime <= S.ShiftEnd)    
    ) as T1    
  ON AutoData.mc=T1.mc and autodata.comp=T1.comp and T.ShiftSt=T1.FromTm     
  Where AutoData.DataType=2  and T.MachineInterface=autodata.mc    
  And (( autodata.Sttime > T1.Sttime )    
  And ( autodata.ndtime <  T1.ndtime )    
  AND ( autodata.ndtime >  T1.ShiftStart ))    
  AND    
  (( T.StartTime >= T1.ShiftStart )    
  And ( T.StartTime <  T1.ndtime ) )    
  GROUP BY T1.ShiftStart,T1.ShiftEnd,autodata.mc,autodata.comp)AS T2 Inner Join #FinalTarget on t2.mc = #FinalTarget.machineinterface and    
  t2.comp = #FinalTarget.compinterface   
  and t2.ShiftStart=#FinalTarget.ShiftStart and t2.ShiftEnd=#FinalTarget.ShiftEnd    
    
     
    
 /* If production Records of TYPE-3*/    
 UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)    
 FROM    
 (Select T1.ShiftStart,T1.ShiftEnd,autodata.mc,autodata.comp,    
 SUM(    
 CASE      
  When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1    
  When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2    
  When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3    
  when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4    
 END) as IPDT    
 from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join    
  (    
   Select autodata.mc,autodata.comp,autodata.Sttime,autodata.NdTime,S.ShiftStart,S.ShiftEnd,S.FromTm     
   from #T_autodata autodata inner join #FinalTarget S on S.MachineInterface=Autodata.mc and S.CompInterface=Autodata.Comp   
   Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And    
   (sttime >= S.ShiftStart And ndtime > S.ShiftEnd and autodata.sttime <S.ShiftEnd)     
  )as T1    
 ON AutoData.mc=T1.mc and autodata.comp=T1.comp and T.ShiftSt=T1.FromTm     
 Where AutoData.DataType=2  and T.MachineInterface=autodata.mc    
 And ((T1.Sttime < autodata.sttime  )    
 And ( T1.ndtime >  autodata.ndtime)    
 AND (autodata.sttime  <  T1.ShiftEnd))    
 AND    
 (( T.EndTime > T1.Sttime )    
 And ( T.EndTime <=T1.ShiftEnd ) )    
 GROUP BY T1.ShiftStart,T1.ShiftEnd,autodata.mc,autodata.comp)AS T2 Inner Join #FinalTarget on t2.mc = #FinalTarget.machineinterface and    
 t2.comp = #FinalTarget.compinterface   
 and t2.ShiftStart=#FinalTarget.ShiftStart and t2.ShiftEnd=#FinalTarget.ShiftEnd    
    
     
 /* If production Records of TYPE-4*/    
 UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)    
 FROM    
 (Select T1.ShiftStart,T1.ShiftEnd,autodata.mc,autodata.comp,
 SUM(    
 CASE      
  When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1    
  When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2    
  When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3    
  when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4    
 END) as IPDT    
 from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join     
  (    
   Select autodata.mc,autodata.comp,autodata.Sttime,autodata.NdTime,S.ShiftStart,S.ShiftEnd,S.FromTm     
   from #T_autodata autodata inner join #FinalTarget S on S.MachineInterface=Autodata.mc and S.CompInterface=Autodata.Comp 
   Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And    
   (msttime < S.ShiftStart)And (ndtime > S.ShiftEnd)    
  ) as T1    
 ON AutoData.mc=T1.mc and autodata.comp=T1.comp and T.ShiftSt=T1.FromTm     
 Where AutoData.DataType=2 and T.MachineInterface=autodata.mc    
 And ( (T1.Sttime < autodata.sttime  )    
  And ( T1.ndtime >  autodata.ndtime)    
  AND (autodata.ndtime  >  T1.ShiftStart)    
  AND (autodata.sttime  <  T1.ShiftEnd))    
 AND    
 (( T.StartTime >=T1.ShiftStart)    
 And ( T.EndTime <=T1.ShiftEnd ) )    
 GROUP BY T1.ShiftStart,T1.ShiftEnd,autodata.mc,autodata.comp)AS T2  Inner Join #FinalTarget on t2.mc = #FinalTarget.machineinterface and    
 t2.comp = #FinalTarget.compinterface  
 and t2.ShiftStart=#FinalTarget.ShiftStart and t2.ShiftEnd=#FinalTarget.ShiftEnd    
    
END    
    
    
    
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or 
((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y')    
BEGIN    
    
 --Type 1    
 UPDATE #FinalTarget SET downtime = isnull(downtime,0) + isNull(t2.down,0)    
 from    
 (select S.MachineID,S.Component,S.ShiftStart,S.ShiftEnd,    
 sum(loadunload) as down    
 from #T_autodata autodata     
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface    
 where (autodata.msttime>=S.ShiftStart)    
 and (autodata.ndtime<= S.ShiftEnd)    
 and (autodata.datatype=2)    
 group by S.MachineID,S.Component,S.ShiftStart,S.ShiftEnd    
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and     
t2.ShiftStart=#FinalTarget.ShiftStart and t2.ShiftEnd=#FinalTarget.ShiftEnd    
     
 -- Type 2    
 UPDATE #FinalTarget SET downtime = isnull(downtime,0) + isNull(t2.down,0)    
 from    
 (select S.MachineID,S.Component,S.ShiftStart,S.ShiftEnd,    
 sum(DateDiff(second, S.ShiftStart, ndtime)) down    
 from #T_autodata autodata     
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface 
 where (autodata.sttime<S.ShiftStart)    
 and (autodata.ndtime>S.ShiftStart)    
 and (autodata.ndtime<= S.ShiftEnd)    
 and (autodata.datatype=2)    
 group by S.MachineID,S.Component,S.ShiftStart,S.ShiftEnd    
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and     
t2.ShiftStart=#FinalTarget.ShiftStart and t2.ShiftEnd=#FinalTarget.ShiftEnd    
     
 -- Type 3    
 UPDATE #FinalTarget SET downtime = isnull(downtime,0) + isNull(t2.down,0)    
 from    
 (select S.MachineID,S.Component,S.ShiftStart,S.ShiftEnd,    
 sum(DateDiff(second, stTime,  S.ShiftEnd)) down    
 from #T_autodata autodata    
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface 
 where (autodata.msttime>=S.ShiftStart)    
 and (autodata.sttime< S.ShiftEnd)    
 and (autodata.ndtime> S.ShiftEnd)    
 and (autodata.datatype=2)group by S.MachineID,S.Component,S.ShiftStart,S.ShiftEnd    
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and     
t2.ShiftStart=#FinalTarget.ShiftStart and t2.ShiftEnd=#FinalTarget.ShiftEnd    
     
     
 -- Type 4    
 UPDATE #FinalTarget SET downtime = isnull(downtime,0) + isNull(t2.down,0)    
 from    
 (select S.MachineID,S.Component,S.ShiftStart,S.ShiftEnd,    
 sum(DateDiff(second, S.ShiftStart,  S.ShiftEnd)) down    
 from #T_autodata autodata     
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface  
 where autodata.msttime<S.ShiftStart    
 and autodata.ndtime> S.ShiftEnd    
 and (autodata.datatype=2)group by S.MachineID,S.Component,S.ShiftStart,S.ShiftEnd    
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and     
t2.ShiftStart=#FinalTarget.ShiftStart and t2.ShiftEnd=#FinalTarget.ShiftEnd    
     
    
 ---Management Loss-----    
 -- Type 1    
 UPDATE #FinalTarget SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)    
 from    
 (select S.MachineID,S.Component,S.ShiftStart,S.ShiftEnd,    
 sum(CASE    
 WHEN loadunload >ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)    
 ELSE loadunload    
 END) loss    
 from #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid     
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface   
 where (autodata.msttime>=S.ShiftStart)    
 and (autodata.ndtime<=S.ShiftEnd)    
 and (autodata.datatype=2)    
 and (downcodeinformation.availeffy = 1)    
    and (downcodeinformation.ThresholdfromCO <>1) --NR0097    
 group by  S.MachineID,S.Component,S.ShiftStart,S.ShiftEnd    
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and     
t2.ShiftStart=#FinalTarget.ShiftStart and t2.ShiftEnd=#FinalTarget.ShiftEnd    
    
 -- Type 2    
 UPDATE #FinalTarget SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)    
 from    
 (select S.MachineID,S.Component,S.ShiftStart,S.ShiftEnd,    
  sum(CASE    
 WHEN DateDiff(second, S.ShiftStart, ndtime)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)    
 ELSE DateDiff(second, S.ShiftStart, ndtime)    
 end) loss    
 from #T_autodata autodata     
  INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid     
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface   
 where (autodata.sttime<S.ShiftStart)    
 and (autodata.ndtime>S.ShiftStart)    
 and (autodata.ndtime<=S.ShiftEnd)    
 and (autodata.datatype=2)    
 and (downcodeinformation.availeffy = 1)    
 and (downcodeinformation.ThresholdfromCO <>1) --NR0097    
 group by S.MachineID,S.Component,S.ShiftStart,S.ShiftEnd    
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component
 and t2.ShiftStart=#FinalTarget.ShiftStart and t2.ShiftEnd=#FinalTarget.ShiftEnd    
    
 -- Type 3    
 UPDATE #FinalTarget SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)    
 from    
 (select S.MachineID,S.Component,S.ShiftStart,S.ShiftEnd,    
 sum(CASE    
 WHEN DateDiff(second, stTime, S.ShiftEnd)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)    
 ELSE DateDiff(second, stTime, S.ShiftEnd)    
 END) loss    
 from #T_autodata autodata      
 INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid     
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface    
 where (autodata.msttime>=S.ShiftStart)    
 and (autodata.sttime<S.ShiftEnd)    
 and (autodata.ndtime>S.ShiftEnd)    
 and (autodata.datatype=2)    
 and (downcodeinformation.availeffy = 1)    
 and (downcodeinformation.ThresholdfromCO <>1) --NR0097    
 group by S.MachineID,S.Component,S.ShiftStart,S.ShiftEnd    
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component
 and t2.ShiftStart=#FinalTarget.ShiftStart and t2.ShiftEnd=#FinalTarget.ShiftEnd    
    
 -- Type 4    
 UPDATE #FinalTarget SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)    
 from    
 (select S.MachineID,S.Component,S.ShiftStart,S.ShiftEnd,    
 sum(CASE    
 WHEN DateDiff(second, S.ShiftStart, S.ShiftEnd)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)    
 ELSE DateDiff(second, S.ShiftStart, S.ShiftEnd)    
 END) loss    
 from #T_autodata autodata     
 INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid     
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface 
 where autodata.msttime<S.ShiftStart    
 and autodata.ndtime>S.ShiftEnd    
 and (autodata.datatype=2)    
 and (downcodeinformation.availeffy = 1)    
 and (downcodeinformation.ThresholdfromCO <>1) --NR0097    
 group by S.MachineID,S.Component,S.ShiftStart,S.ShiftEnd    
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component 
 and t2.ShiftStart=#FinalTarget.ShiftStart and t2.ShiftEnd=#FinalTarget.ShiftEnd    
END    
    
  
  
    
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'    
BEGIN    
    
 ---Get the down times which are not of type Management Loss    
 UPDATE #FinalTarget SET downtime = isnull(downtime,0) + isNull(t2.down,0)    
 from    
 (select  F.ShiftStart,F.ShiftEnd,F.machineinterface,F.Compinterface,  
  sum (CASE    
    WHEN (autodata.msttime >= F.ShiftStart  AND autodata.ndtime <=F.ShiftEnd)  THEN autodata.loadunload    
    WHEN ( autodata.msttime < F.ShiftStart  AND autodata.ndtime <= F.ShiftEnd  AND autodata.ndtime > F.ShiftStart ) THEN DateDiff(second,F.ShiftStart,autodata.ndtime)    
    WHEN ( autodata.msttime >= F.ShiftStart   AND autodata.msttime <F.ShiftEnd  AND autodata.ndtime > F.ShiftEnd  ) THEN DateDiff(second,autodata.msttime,F.ShiftEnd )    
    WHEN ( autodata.msttime < F.ShiftStart  AND autodata.ndtime > F.ShiftEnd ) THEN DateDiff(second,F.ShiftStart,F.ShiftEnd )    
    END ) as down    
    from #T_autodata autodata     
    inner join #FinalTarget F on autodata.mc = F.Machineinterface and autodata.comp=F.Compinterface    
    inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid    
  where (autodata.datatype=2) AND    
    (( (autodata.msttime>=F.ShiftStart) and (autodata.ndtime<=F.ShiftEnd))    
       OR ((autodata.msttime<F.ShiftStart)and (autodata.ndtime>F.ShiftStart)and (autodata.ndtime<=F.ShiftEnd))    
       OR ((autodata.msttime>=F.ShiftStart)and (autodata.msttime<F.ShiftEnd)and (autodata.ndtime>F.ShiftEnd))    
       OR((autodata.msttime<F.ShiftStart)and (autodata.ndtime>F.ShiftEnd)))     
    AND (downcodeinformation.availeffy = 0)    
       group by F.ShiftStart,F.ShiftEnd,F.machineinterface,F.Compinterface
 ) as t2 Inner Join #FinalTarget on t2.machineinterface = #FinalTarget.machineinterface and    
 t2.compinterface = #FinalTarget.compinterface   
 and t2.ShiftStart=#FinalTarget.ShiftStart and t2.ShiftEnd=#FinalTarget.ShiftEnd    
 
 UPDATE  #FinalTarget SET Downtime = isnull(Downtime,0) - isNull(T2.PPDT ,0)    
 FROM(    
 SELECT F.ShiftStart,F.ShiftEnd,F.machineinterface,F.Compinterface,  
    SUM    
    (CASE    
    WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)    
    WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)    
    WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )    
    WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )    
    END ) as PPDT    
    FROM #T_autodata AutoData    
 CROSS jOIN #PlannedDownTimesShift T    
    INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID    
    INNER JOIN #FinalTarget F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp    
    WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND (downcodeinformation.availeffy = 0)     
     AND    
     ((autodata.sttime >= F.ShiftStart  AND autodata.ndtime <=F.ShiftEnd)    
     OR ( autodata.sttime < F.ShiftStart  AND autodata.ndtime <= F.ShiftEnd AND autodata.ndtime > F.ShiftStart )    
     OR ( autodata.sttime >= F.ShiftStart   AND autodata.sttime <F.ShiftEnd AND autodata.ndtime > F.ShiftEnd )    
     OR ( autodata.sttime < F.ShiftStart  AND autodata.ndtime > F.ShiftEnd))    
     AND    
     ((autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)    
     OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )    
     OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )    
     OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )     
     AND    
     ((F.ShiftStart >= T.StartTime  AND F.ShiftEnd <=T.EndTime)    
     OR ( F.ShiftStart < T.StartTime  AND F.ShiftEnd <= T.EndTime AND F.ShiftEnd > T.StartTime )    
     OR ( F.ShiftStart >= T.StartTime   AND F.ShiftStart <T.EndTime AND F.ShiftEnd > T.EndTime )    
     OR ( F.ShiftStart < T.StartTime  AND F.ShiftEnd > T.EndTime) )     
     group  by F.ShiftStart,F.ShiftEnd,F.machineinterface,F.Compinterface
 )AS T2  Inner Join #FinalTarget on t2.machineinterface = #FinalTarget.machineinterface and    
 t2.compinterface = #FinalTarget.compinterface     
 and t2.ShiftStart=#FinalTarget.ShiftStart and t2.ShiftEnd=#FinalTarget.ShiftEnd    
    
 UPDATE #FinalTarget SET ManagementLoss = isnull(ManagementLoss,0)+ isNull(t4.Mloss,0),MLDown=isNull(MLDown,0)+isNull(t4.Dloss,0)    
 from    
 (select T3.mc,T3.comp,T3.ShiftStart as ShiftStart,T3.ShiftEnd as ShiftEnd,sum(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss from    
  (    
 select   T1.id,T1.mc,T1.comp,T1.Threshold,T1.ShiftStart as ShiftStart,T1.ShiftEnd as ShiftEnd,    
 case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0) > 0    
 then DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)- isnull(T1.Threshold ,0)    
 else 0 End  as Dloss,    
 case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0) > 0    
 then isnull(T1.Threshold,0)    
 else DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0) End  as Mloss    
  from    
     
  (       
   select id,mc,comp,D.threshold,S.ShiftStart as ShiftStart,S.ShiftEnd as ShiftEnd,    
   case when autodata.sttime<S.ShiftStart then S.ShiftStart else sttime END as sttime,    
   case when ndtime>S.ShiftEnd then S.ShiftEnd else ndtime END as ndtime    
   from #T_autodata autodata     
   inner join downcodeinformation D on autodata.dcode=D.interfaceid     
   INNER JOIN #FinalTarget S on S.machineinterface=Autodata.mc and S.Compinterface=Autodata.comp  
   where autodata.datatype=2 AND    
   (    
   (autodata.msttime>=S.ShiftStart  and  autodata.ndtime<=S.ShiftEnd)    
   OR (autodata.sttime<S.ShiftStart and  autodata.ndtime>S.ShiftStart and autodata.ndtime<=S.ShiftEnd)    
   OR (autodata.msttime>=S.ShiftStart  and autodata.sttime<S.ShiftEnd  and autodata.ndtime>S.ShiftEnd)    
   OR (autodata.msttime<S.ShiftStart and autodata.ndtime>S.ShiftEnd )    
   ) AND (D.availeffy = 1)    
    and (D.ThresholdfromCO <>1) --NR0097    
  ) as T1      
  left outer join    
  (    
   SELECT id,F.ShiftStart,F.ShiftEnd,mc,comp, 
   SUM    
   (CASE    
   WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)    
   WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)    
   WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )    
   WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )    
   END ) as PPDT    
   FROM #T_autodata AutoData    
   CROSS jOIN #PlannedDownTimesShift T    
   INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID    
   INNER JOIN #FinalTarget F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp   
   WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND     
   (downcodeinformation.availeffy = 1)     
    AND    
    ((autodata.sttime >= F.ShiftStart  AND autodata.ndtime <=F.ShiftEnd)    
    OR ( autodata.sttime < F.ShiftStart  AND autodata.ndtime <= F.ShiftEnd AND autodata.ndtime > F.ShiftStart )    
    OR ( autodata.sttime >= F.ShiftStart   AND autodata.sttime <F.ShiftEnd AND autodata.ndtime > F.ShiftEnd )    
    OR ( autodata.sttime < F.ShiftStart  AND autodata.ndtime > F.ShiftEnd))    
    AND    
    ((autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)    
    OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )    
    OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )    
    OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )     
    AND    
    ((F.ShiftStart >= T.StartTime  AND F.ShiftEnd <=T.EndTime)    
    OR ( F.ShiftStart < T.StartTime  AND F.ShiftEnd <= T.EndTime AND F.ShiftEnd > T.StartTime )    
    OR ( F.ShiftStart >= T.StartTime   AND F.ShiftStart <T.EndTime AND F.ShiftEnd > T.EndTime )    
    OR ( F.ShiftStart < T.StartTime  AND F.ShiftEnd > T.EndTime) )     
    and (DownCodeInformation.ThresholdfromCO <>1) --NR0097    
    group  by id,F.ShiftStart,F.ShiftEnd,mc,comp   
  ) as T2 on T1.id=T2.id and T1.mc=T2.mc and T1.comp=T2.comp and T1.ShiftStart=T2.ShiftStart and T1.ShiftEnd=T2.ShiftEnd ) as T3  group by T3.mc,T3.comp,T3.ShiftStart,T3.ShiftEnd    
 ) as t4 Inner Join #FinalTarget on t4.mc = #FinalTarget.machineinterface and    
 t4.comp = #FinalTarget.compinterface  
 and t4.ShiftStart=#FinalTarget.ShiftStart and t4.ShiftEnd=#FinalTarget.ShiftEnd    
    
 UPDATE #FinalTarget  set downtime = isnull(downtime,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)    
END    
   
--Calculation of PartsCount Begins..    
UPDATE #FinalTarget SET components = ISNULL(components,0) + ISNULL(t2.comp1,0),CN = isnull(CN,0) + isNull(t2.C1N1,0)    
From    
(    
 Select T1.mc,T1.comp,T1.ShiftStart,T1.ShiftEnd,  
 SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp1,  
SUM((O.cycletime/ISNULL(O.SubOperations,1))* T1.OrginalCount) C1N1 
     From (select mc,comp,autodata.opn,F.ShiftStart,F.ShiftEnd,SUM(autodata.partscount)AS OrginalCount from #T_autodata autodata    
     Cross join #ShiftDetails F
     where (autodata.ndtime>F.ShiftStart) and (autodata.ndtime<=F.ShiftEnd) and (autodata.datatype=1)    
     Group By mc,comp,autodata.opn,ShiftStart,ShiftEnd) as T1    
 INNER JOIN #FinalTarget F on F.machineinterface=T1.mc and F.Compinterface=T1.comp 
 and F.FromTm=T1.ShiftStart and F.ToTm=T1.ShiftEnd  
 inner join machineinformation on  F.machineinterface=machineinformation.interfaceid
 Inner join componentinformation C on F.Compinterface = C.interfaceid    
 Inner join ComponentOperationPricing O ON  machineinformation.machineid =O.machineid and C.Componentid=O.componentid 
 --and T1.opn = O.interfaceid    
 GROUP BY T1.mc,T1.comp,T1.ShiftStart,T1.ShiftEnd,O.cycletime,O.SubOperations
) As T2 Inner Join #FinalTarget on T2.mc = #FinalTarget.machineinterface and    
T2.comp = #FinalTarget.compinterface 
and T2.ShiftStart=#FinalTarget.ShiftStart and T2.ShiftEnd=#FinalTarget.ShiftEnd    


If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'    
BEGIN    
      
 UPDATE #FinalTarget SET components=ISNULL(components,0)- isnull(t2.PlanCt,0) ,CN = isnull(CN,0) - isNull(t2.C1N1,0)   
  FROM ( select autodata.mc,autodata.comp,F.ShiftStart,F.ShiftEnd,  
  ((CAST(Sum(ISNULL(PartsCount,1)) AS Float)/ISNULL(CO.SubOperations,1))) as PlanCt,  
 SUM((CO.cycletime * ISNULL(PartsCount,1))/ISNULL(CO.SubOperations,1))  C1N1  
   from #T_autodata autodata     
     INNER JOIN #FinalTarget F on F.machineinterface=autodata.mc and F.Compinterface=autodata.comp 
  Inner jOIN #PlannedDownTimesShift T on T.MachineInterface=autodata.mc      
  inner join machineinformation M on autodata.mc=M.Interfaceid    
  Inner join componentinformation CI on autodata.comp=CI.interfaceid     
  inner join componentoperationpricing CO on autodata.opn=CO.interfaceid and    
  CI.componentid=CO.componentid  and CO.machineid=M.machineid    
  WHERE autodata.DataType=1 and    
  (autodata.ndtime>F.ShiftStart) and (autodata.ndtime<=F.ShiftEnd)     
  AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)    
   Group by autodata.mc,autodata.comp,F.ShiftStart,F.ShiftEnd,CO.SubOperations     
 ) as T2 Inner Join #FinalTarget on T2.mc = #FinalTarget.machineinterface and    
 T2.comp = #FinalTarget.compinterface
 and T2.ShiftStart=#FinalTarget.ShiftStart and T2.ShiftEnd=#FinalTarget.ShiftEnd    
     
END    
 

UPDATE #FinalTarget  
SET Runtime = (UtilisedTime + DownTime - ManagementLoss)   
    
UPDATE #FinalTarget  
SET  
 ProductionEfficiency = (CN/UtilisedTime) ,  
 AvailabilityEfficiency = (UtilisedTime)/(UtilisedTime + DownTime - ManagementLoss) WHERE UtilisedTime <> 0  
  
UPDATE #FinalTarget  
SET  
 OverAllEfficiency = (ProductionEfficiency * AvailabilityEfficiency)*100,   
 ProductionEfficiency = ProductionEfficiency * 100 ,  
 AvailabilityEfficiency = AvailabilityEfficiency * 100  


/*********************************************************** SPC rejection MeasuredOK calculation ************************************************************************************************************/

CREATE TABLE #SPCAutodata
(
mc NVARCHAR(50),
comp NVARCHAR(50),
opn NVARCHAR(50),
opr NVARCHAR(50),
TimeStamp DATETIME, 
Dimension nvarchar(50),
WearOffsetNumber NVARCHAR(50),
value FLOAT,
correctionvalue NVARCHAR(50),
Measuredimension NVARCHAR(50),
OvalityMax nvarchar(50),
OvalityMin nvarchar(50),
ToolChangeTime datetime,
IgnoreForCPCPK Bit
)

Select @strsql=''     
Select @strsql= '
 INSERT INTO #SPCAutodata(mc,comp,opn,opr,TimeStamp,Dimension,WearOffsetNumber,value,correctionvalue,Measuredimension,OvalityMax,OvalityMin,ToolChangeTime,IgnoreForCPCPK)
 SELECT mc,comp,opn,opr,Timestamp,Dimension,WearOffSetNumber,Value,CorrectionValue,MeasureDimension,OvalityMax,OvalityMin,S.ToolChangeTime,S.IgnoreForCPCPK  FROM dbo.SPCAutodata s
 INNER JOIN dbo.machineinformation  ON machineinformation.InterfaceID=s.Mc
 WHERE  (TimeStamp>= ''' +convert(nvarchar(20),@T_Start,120)+''' AND TimeStamp<= '''+convert(nvarchar(20),@T_End,120)+'''  ) '    
select @strsql = @strsql + @strmachine  
print @strsql    
exec (@strsql) 

 Create Table #TempSPCAutodata
 (
	IDD bigint identity(1,1),
	MachineID nvarchar(50),
	ComponentID nvarchar(50),
	Pdate datetime,
	Shift nvarchar(50),
	TimeStamp datetime,
	Dimension nvarchar(50),
	WearOffsetNumber nvarchar(50),
	Value float,
	CorrectionValue nvarchar(50),
	MeasureDimension nvarchar(50),
	Employeeid nvarchar(50),
	LSL nvarchar(50),
	USL nvarchar(50),
	ValueOutOfRange int,
	ToolChangeTime datetime,
	IgnoreForCPCPK bit,
	OvalityMax nvarchar(50),
	OvalityMin nvarchar(50),
	Ovality nvarchar(50)
 )


 if (select isnull(valueintext,'N') from ShopDefaults where Parameter='EnableOvality')='Y'
BEGIN
	if  ((select ValueInText FROM ShopDefaults WHERE Parameter = 'SPCCompOpnSet') = 'SPCMaster')
	BEGIN
		 Select @strsql=''     
		Select @strsql= 'Insert into #TempSPCAutodata(MachineID,ComponentID,Pdate,Shift,TimeStamp,Dimension,WearOffsetNumber,Value,CorrectionValue,MeasureDimension,Employeeid,LSL,USL,ValueOutOfRange,ToolChangeTime,
				IgnoreForCPCPK,OvalityMax,OvalityMin,Ovality)
			SELECT  machineinformation.machineid,sp.ComponentID,S.PDate,S.Shift,A.TimeStamp as MeasuredTime, A.Dimension,A.WearOffsetNumber,
			A.Value ,A.CorrectionValue,A.MeasureDimension ,E.Employeeid,
			SP.LSL,SP.USL,(Case When A.Value >= SP.LSL and A.value <= SP.USL then 0
								when A.Value < SP.LSL and A.value > SP.USL Then 1
								else 1
							END) as ValueOutOfRange,A.ToolChangeTime,A.IgnoreForCPCPK,A.OvalityMax AS MaxVal,a.OvalityMin as MinVal,
							round((cast(A.OvalityMax as float)-cast(a.OvalityMin as float)),2) as Ovality
			from #spcautodata A
			inner join Machineinformation on A.mc=Machineinformation.interfaceid
			Left Outer join Employeeinformation E on A.opr=E.interfaceid --Added For Autotech
			inner join SPC_Characteristic SP on Machineinformation.machineid=SP.machineid and A.opn=SP.operationno and A.Dimension=SP.CharacteristicID
			and A.Comp=SP.ComponentID
			CRoss join #ShiftDetails S
			where 1=1 
			and (timestamp >= S.ShiftStart and timestamp <= S.ShiftEnd)  '    
		select @strsql = @strsql + @strmachine  
		select @strsql = @strsql + '  order by TimeStamp desc '    
		print @strsql    
		exec (@strsql) 
	END
	ELSE
	BEGIN
		 Select @strsql=''     
		Select @strsql= 'Insert into #TempSPCAutodata(MachineID,ComponentID,Pdate,Shift,TimeStamp,Dimension,WearOffsetNumber,Value,CorrectionValue,MeasureDimension,Employeeid,LSL,USL,ValueOutOfRange,ToolChangeTime,
				IgnoreForCPCPK,OvalityMax,OvalityMin,Ovality)
			SELECT  machineinformation.machineid,sp.ComponentID, S.PDate,S.Shift,A.TimeStamp as MeasuredTime, A.Dimension,A.WearoffSetNumber,
			A.Value ,A.CorrectionValue,A.MeasureDimension ,E.Employeeid,
			SP.LSL,SP.USL,(Case When A.Value >= SP.LSL and A.value <= SP.USL then 0
								when A.Value < SP.LSL and A.value > SP.USL Then 1
								else 1
							END) as ValueOutOfRange,A.ToolChangeTime,A.IgnoreForCPCPK,A.OvalityMax AS MaxVal,a.OvalityMin as MinVal,
							round((cast(A.OvalityMax as float)-cast(a.OvalityMin as float)),2) as Ovality
			from #spcautodata A
			inner join Machineinformation on A.mc=Machineinformation.interfaceid
			Left Outer join Employeeinformation E on A.opr=E.interfaceid --Added For Autotech
			inner join Componentinformation  on Componentinformation.interfaceid=A.comp
			inner join Componentoperationpricing CO on CO.interfaceid=A.opn and CO.machineid=Machineinformation.machineid and CO.componentid=Componentinformation.Componentid
			inner join SPC_Characteristic SP on CO.machineid=SP.machineid and CO.operationno=SP.operationno and A.Dimension=SP.CharacteristicID
			and SP.ComponentID=Componentinformation.componentid
			CRoss join #ShiftDetails S
			where 1=1 
			and (timestamp >= S.ShiftStart and timestamp <= S.ShiftEnd)  '    
		select @strsql = @strsql + @strmachine  + @strComponent
		select @strsql = @strsql + '  order by TimeStamp desc '    
		print @strsql    
		exec (@strsql) 
	end
END

if (select isnull(valueintext,'N') from ShopDefaults where Parameter='EnableOvality')='N'
BEGIN
	if  ((select ValueInText FROM ShopDefaults WHERE Parameter = 'SPCCompOpnSet') = 'SPCMaster')
	BEGIN
		 Select @strsql=''     
		Select @strsql= 'Insert into #TempSPCAutodata(MachineID,ComponentID,Pdate,Shift,TimeStamp,Dimension,WearOffsetNumber,Value,CorrectionValue,MeasureDimension,Employeeid,LSL,USL,ValueOutOfRange,ToolChangeTime,
				IgnoreForCPCPK)
			SELECT machineinformation.machineid,sp.ComponentID,S.PDate,S.Shift,A.TimeStamp as MeasuredTime, A.Dimension,A.WearOffsetNumber,
			A.Value ,A.CorrectionValue,A.MeasureDimension ,E.Employeeid,
			SP.LSL,SP.USL,(Case When A.Value >= SP.LSL and A.value <= SP.USL then 0
								when A.Value < SP.LSL and A.value > SP.USL Then 1
								else 1
							END) as ValueOutOfRange,A.ToolChangeTime,A.IgnoreForCPCPK
			from #spcautodata A
			inner join Machineinformation on A.mc=Machineinformation.interfaceid
			Left Outer join Employeeinformation E on A.opr=E.interfaceid --Added For Autotech
			inner join SPC_Characteristic SP on Machineinformation.machineid=SP.machineid and A.opn=SP.operationno and A.Dimension=SP.CharacteristicID
			and A.Comp=SP.ComponentID
			CRoss join #ShiftDetails S
			where 1=1 
			and (timestamp >= S.ShiftStart and timestamp <= S.ShiftEnd)  '    
		select @strsql = @strsql + @strmachine  
		select @strsql = @strsql + '  order by TimeStamp desc '    
		print @strsql    
		exec (@strsql) 
	END
	ELSE
	BEGIN
		 Select @strsql=''     
		Select @strsql= 'Insert into #TempSPCAutodata(MachineID,ComponentID,Pdate,Shift,TimeStamp,Dimension,WearOffsetNumber,Value,CorrectionValue,MeasureDimension,Employeeid,LSL,USL,ValueOutOfRange,ToolChangeTime,
				IgnoreForCPCPK)
			SELECT machineinformation.machineid,sp.ComponentID, S.PDate,S.Shift,A.TimeStamp as MeasuredTime, A.Dimension,A.WearoffSetNumber,
			A.Value ,A.CorrectionValue,A.MeasureDimension ,E.Employeeid,
			SP.LSL,SP.USL,(Case When A.Value >= SP.LSL and A.value <= SP.USL then 0
								when A.Value < SP.LSL and A.value > SP.USL Then 1
								else 1
							END) as ValueOutOfRange,A.ToolChangeTime,A.IgnoreForCPCPK
			from #spcautodata A
			inner join Machineinformation on A.mc=Machineinformation.interfaceid
			Left Outer join Employeeinformation E on A.opr=E.interfaceid --Added For Autotech
			inner join Componentinformation  on Componentinformation.interfaceid=A.comp
			inner join Componentoperationpricing CO on CO.interfaceid=A.opn and CO.machineid=Machineinformation.machineid and CO.componentid=Componentinformation.Componentid
			inner join SPC_Characteristic SP on CO.machineid=SP.machineid and CO.operationno=SP.operationno and A.Dimension=SP.CharacteristicID
			and SP.ComponentID=Componentinformation.componentid
			CRoss join #ShiftDetails S
			where 1=1 
			and  (timestamp >= S.ShiftStart and timestamp <= S.ShiftEnd)  '    
		select @strsql = @strsql + @strmachine + @strComponent 
		select @strsql = @strsql + '  order by TimeStamp desc '    
		print @strsql    
		exec (@strsql) 
	end
end

Update #FinalTarget set SPCRejectionCount=isnull(T1.cnt,0)
FROm (
select MachineID,ComponentID,convert(nvarchar(10),Pdate,120) as PDate,Shift,Count(*) as cnt from #TempSPCAutodata 
where ValueOutOfRange=1
Group by MachineID,ComponentID,convert(nvarchar(10),Pdate,120),Shift
) T1 inner join #FinalTarget T2 on T1.MachineID=T2.MachineID and t1.ComponentID=T2.Component and convert(nvarchar(10),T1.Pdate,120)=convert(nvarchar(10),T2.Pdate,120) and T1.Shift=T2.Shift

Update #FinalTarget set AcceptedQty= isnull(Components,0) - isnull(SPCRejectionCount,0)
where isnull(Components,0) > isnull(SPCRejectionCount,0)

/*********************************************************** SPC rejection MeasuredOK calculation ************************************************************************************************************/

select convert(nvarchar(10),Pdate,120) as PDate,[Shift],MachineID,MachineInterface,Component as ComponentID,CompInterface,CompDescription,ShiftStart,ShiftEnd,
dbo.f_formattime(UtilisedTime,@timeformat) as UtilisedTime,isnull(Round(Components,2),0)as ProducedQty,SPCRejectionCount,AcceptedQty,dbo.f_formattime(Downtime,@timeformat) as DownTime,
dbo.f_formattime(isnull(ManagementLoss,0),@timeformat) as ManagementLoss,dbo.f_formattime(isnull(MLDown,0),@timeformat) as MLDown,
dbo.f_formattime(isnull(stdTime,0),@timeformat) as stdTime,CN,dbo.f_formattime(isnull(Runtime,0),@timeformat) as Runtime,
ISNULL(ROUND(ProductionEfficiency,2),0) as ProductionEfficiency,
ISNULL(ROUND(AvailabilityEfficiency,2),0) as AvailabilityEfficiency,
ISNULL(ROUND(OverallEfficiency,2),0) as OverallEfficiency from #FinalTarget
where isnull(Components,0)>0
order by Pdate ,[Shift],MachineID,Component

END
