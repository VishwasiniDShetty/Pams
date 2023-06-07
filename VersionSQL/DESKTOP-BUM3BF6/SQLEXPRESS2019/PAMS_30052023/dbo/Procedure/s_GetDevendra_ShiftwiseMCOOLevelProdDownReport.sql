/****** Object:  Procedure [dbo].[s_GetDevendra_ShiftwiseMCOOLevelProdDownReport]    Committed by VersionSQL https://www.versionsql.com ******/

  
  
/************************************************************************************************************    
ER0452 - swathiKS - 19/Jul/2017 :: Created New Procedure To show Shiftwise M-C-O-O Level Actual, RuntimeTarget, CommaSeparated Downcodes with Downtime and OEE details for Devendra. (Implemented Batching Concept)    
DR0379 - SwathiKS - 29/Nov/2017 :: Downcodes were not displaying If Sortorder IS NOT NULL For SPF.

exec [dbo].[s_GetDevendra_ShiftwiseMCOOLevelProdDownReport]   '2022-10-12 06:00:00','2022-10-13 06:00:00','','VMC-1'

exec [s_GetDevendra_ShiftwiseMCOOLevelProdDownReport] @StartDate=N'2022-12-07 08:00:00',@EndDate=N'2022-12-08 08:00:00',@MachineID=N'CNC-1,HMC-1,HMC-2,HT-1,HT-2,HT-3,VMC-1,VMC-2,VTL-1,VTL-2,VTL-3,VTL-4',@Shiftname=N'',@Plantid=N'',@Operatorid=N'',@param=N''

**************************************************************************************************************/    
CREATE PROCEDURE [dbo].[s_GetDevendra_ShiftwiseMCOOLevelProdDownReport]    
 @StartDate datetime,    
 @EndDate datetime,    
 @Shiftname nvarchar(50)='',    
 @MachineID nvarchar(max) = '',    
 @Plantid nvarchar(50) = '',  
 @Operatorid nvarchar(50)='',
 @param nvarchar(50) = ''    
WITH RECOMPILE    
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    
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
    
CREATE TABLE #T_autodataforDown    
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
 [PartsCount] decimal(18,5) NULL,  
 id  bigint not null    
)    
    
ALTER TABLE #T_autodataforDown    
    
ADD PRIMARY KEY CLUSTERED    
(    
 mc,sttime ASC    
)ON [PRIMARY]    
    
    
CREATE TABLE #Target      
(    
    
MachineID nvarchar(50) NOT NULL,    
machineinterface nvarchar(50),    
Compinterface nvarchar(50),    
OpnInterface nvarchar(50),   
CompDescription nvarchar(100),  
Component nvarchar(50) NOT NULL,    
Operation nvarchar(50) NOT NULL, 
OpnDescription nvarchar(100), 
Operator nvarchar(50),    
OprInterface nvarchar(50),    
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
 Operation nvarchar(50) NOT NULL,    
 OpnDescription nvarchar(100), 
 OpnInterface nvarchar(50),    
 Operator nvarchar(50),    
 OprInterface nvarchar(50),    
 FromTm datetime,    
 ToTm datetime,       
 BatchStart datetime,    
 BatchEnd datetime,    
 batchid int,    
 Utilisedtime float,    
 Components float,    
 Downtime float,    
 ManagementLoss float,    
 MLDown float,  
 stdTime float,  
 Avgcycletime float default 0,  
 CN float,  
 ProductionEfficiency float,  
 AvailabilityEfficiency float,  
 OverallEfficiency float,  
 Downtimecode nvarchar(max),  
 DowntimeDescription nvarchar(max),  
 Target float default 0,  
 TotalDowntime float default 0,  
 Runtime float default 0  
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
    
CREATE TABLE #Downcode    
(    
 Pdate datetime,  
 Shift nvarchar(20),  
 machineinterface nvarchar(50),    
 Compinterface nvarchar(50),    
 OpnInterface nvarchar(50),    
 OprInterface nvarchar(50),    
 FromTm datetime,    
 ToTm datetime,       
 BatchStart datetime,    
 BatchEnd datetime,  
 Downcode nvarchar(max),  
 DownDescription nvarchar(max),   
 Downtime float   
)    
  
declare @StrMCJoined as nvarchar(max)    
Declare @strsql nvarchar(4000)    
Declare @strmachine nvarchar(1000)    
Declare @StrTPMMachines AS nvarchar(1000)    
Declare @StrPlantid as nvarchar(1000)    
 declare @StrOpr as nvarchar(50)  
  
Declare @timeformat as nvarchar(12)    
Declare @CurStrtTime as datetime    
Declare @CurEndTime as datetime    
Declare @T_Start AS Datetime     
Declare @T_End AS Datetime    
    
Select @strsql = ''    
Select @StrTPMMachines = ''    
Select @strmachine = ''    
select @strPlantID = ''    
 select @StrOpr=''  
   
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
    
if isnull(@PlantID,'') <> ''    
Begin    
 Select @strPlantID = ' and ( PlantMachine.PlantID = N''' + @PlantID + ''')'    
End    
    
IF ISNULL(@Operatorid,'')<>''  
BEGIN  
	SELECT @StrOpr=' AND ( EI.Employeeid =  N'''+ @Operatorid +''' ) '  
END  
  
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
Select @strsql= 'insert into #Target(MachineID,machineinterface,Component,CompDescription,Compinterface,Operation,OpnDescription,Opninterface,    
Operator,Oprinterface,msttime,ndtime,Pdate,Shift,FromTm,Totm,batchid,autodataid,stdtime)'    
select @strsql = @strsql + ' SELECT machineinformation.machineid, machineinformation.interfaceid,componentinformation.componentid, componentinformation.Description,componentinformation.interfaceid,    
componentoperationpricing.operationno,componentoperationpricing.description as OpnDescription, componentoperationpricing.interfaceid,EI.Employeeid,EI.interfaceid,    
Case when autodata.msttime< T.Shiftstart then T.Shiftstart else autodata.msttime end,     
Case when autodata.ndtime> T.ShiftEnd then T.ShiftEnd else autodata.ndtime end,    
T.Pdate,T.Shift,T.shiftstart,T.Shiftend,0,autodata.id,componentoperationpricing.machiningtime FROM #T_autodata autodata    
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
select @strsql = @strsql + @strmachine + @strPlantID  + @stropr  
select @strsql = @strsql + ' order by autodata.msttime'    
print @strsql    
exec (@strsql)    
    
  
 -- ER0465 g:/    
--declare @mc_prev nvarchar(50),@comp_prev nvarchar(50),@opn_prev nvarchar(50),@opr_prev nvarchar(50),@From_Prev datetime    
--declare @mc nvarchar(50),@comp nvarchar(50),@opn nvarchar(50),@opr nvarchar(50),@Fromtime datetime,@id nvarchar(50)    
--declare @batchid int    
--Declare @autodataid bigint,@autodataid_prev bigint    
    
--declare @setupcursor  cursor    
--set @setupcursor=cursor for    
--select autodataid,FromTm,MachineID,Component,Operation,Operator from #Target order by machineid,msttime    
--open @setupcursor    
--fetch next from @setupcursor into @autodataid,@Fromtime,@mc,@comp,@opn,@opr    
    
--set @autodataid_prev=@autodataid    
--set @mc_prev = @mc    
--set @comp_prev = @comp    
--set @opn_prev = @opn    
--set @opr_prev = @opr    
--SET @From_Prev = @Fromtime    
--set @batchid =1    
    
--while @@fetch_status = 0    
--begin    
--If @mc_prev=@mc and @comp_prev=@comp and @opn_prev=@opn and @opr_prev=@opr and @From_Prev = @Fromtime    
-- begin      
--  update #Target set batchid = @batchid where autodataid=@autodataid and MachineID=@mc and Component=@comp and Operation=@opn and Operator=@opr and FromTm=@Fromtime    
--  print @batchid    
-- end    
-- else    
-- begin     
--    set @batchid = @batchid+1            
--    update #Target set batchid = @batchid where autodataid=@autodataid and MachineID=@mc and Component=@comp and Operation=@opn and Operator=@opr and FromTm=@Fromtime    
--    set @autodataid_prev=@autodataid     
--    set @mc_prev=@mc      
--    set @comp_prev=@comp    
--    set @opn_prev=@opn     
--    set @opr_prev = @opr    
--    SET @From_Prev = @Fromtime    
-- end     
-- fetch next from @setupcursor into @autodataid,@Fromtime,@mc,@comp,@opn,@Opr    
     
--end    
--close @setupcursor    
--deallocate @setupcursor    
    
--insert into #FinalTarget (MachineID,Component,CompDescription,operation,Operator,machineinterface,Compinterface,Opninterface,Oprinterface,batchid,BatchStart,BatchEnd,Pdate,shift,FromTm,ToTm,stdtime,Utilisedtime,Downtime,Components,ManagementLoss,MLDown)  
--Select MachineID,Component,CompDescription,operation,Operator,machineinterface,Compinterface,Opninterface,Oprinterface,batchid,min(msttime),max(ndtime),Pdate,shift,FromTm,ToTm,stdtime,0,0,0,0,0 from #Target     
--group by MachineID,Component,CompDescription,operation,Operator,machineinterface,Compinterface,Opninterface,Oprinterface,batchid,Pdate,shift,FromTm,ToTm,stdtime order by batchid     
    
  
  --g:
  
insert into #FinalTarget (MachineID,Component,CompDescription,operation,OpnDescription,Operator,machineinterface,Compinterface,Opninterface,Oprinterface,batchid,BatchStart,BatchEnd,Pdate,shift,FromTm,ToTm,stdtime,Utilisedtime,Downtime,Components,ManagementLoss,MLDown)  
select MachineID,Component,CompDescription,operation,OpnDescription,Operator,machineinterface,Compinterface,Opninterface,Oprinterface,batchid,min(msttime),max(ndtime),Pdate,shift,FromTm,ToTm,stdtime,0,0,0,0,0
from
(
select MachineID,Component,CompDescription,operation,OpnDescription,Operator,machineinterface,Compinterface,Opninterface,Oprinterface,msttime,ndtime,Pdate,FromTm,ToTm,stdtime,shift,
RANK() OVER (
  PARTITION BY t.machineid
  order by t.machineid, t.msttime
) -
RANK() OVER (
  PARTITION BY  t.machineid, t.component,t.CompDescription, t.operation,t.OpnDescription, t.operator, t.fromtm --autodataid=@autodataid and MachineID=@mc and Component=@comp and Operation=@opn and Operator=@opr and FromTm=@Fromtime 
  order by t.machineid, t.fromtm, t.msttime
) AS batchid
from #Target t 
) tt
group by MachineID,Component,CompDescription,operation,OpnDescription,Operator,machineinterface,Compinterface,Opninterface,Oprinterface,batchid,Pdate,shift,FromTm,ToTm,stdtime 
order by tt.batchid

-- ER0465 g:/
    
  
--For Prodtime    
UPDATE #FinalTarget SET Utilisedtime = isnull(Utilisedtime,0) + isNull(t2.cycle,0)    
from    
(select S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd,    
 sum(case when ((autodata.msttime>=S.BatchStart) and (autodata.ndtime<=S.BatchEnd)) then  (autodata.cycletime+autodata.loadunload)    
   when ((autodata.msttime<S.BatchStart)and (autodata.ndtime>S.BatchStart)and (autodata.ndtime<=S.BatchEnd)) then DateDiff(second, S.BatchStart, autodata.ndtime)    
   when ((autodata.msttime>=S.BatchStart)and (autodata.msttime<S.BatchEnd)and (autodata.ndtime>S.BatchEnd)) then DateDiff(second, autodata.mstTime, S.BatchEnd)    
   when ((autodata.msttime<S.BatchStart)and (autodata.ndtime>S.BatchEnd)) then DateDiff(second, S.BatchStart, S.BatchEnd) END ) as cycle    
from #T_autodata autodata     
inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface and autodata.opr = S.Oprinterface    
where (autodata.datatype=1) AND(( (autodata.msttime>=S.BatchStart) and (autodata.ndtime<=S.BatchEnd))    
OR ((autodata.msttime<S.BatchStart)and (autodata.ndtime>S.BatchStart)and (autodata.ndtime<=S.BatchEnd))    
OR ((autodata.msttime>=S.BatchStart)and (autodata.msttime<S.BatchEnd)and (autodata.ndtime>S.BatchEnd))    
OR((autodata.msttime<S.BatchStart)and (autodata.ndtime>S.BatchEnd)))    
group by S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd    
) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and     
t2.operation = #FinalTarget.operation and t2.Operator = #FinalTarget.Operator    
and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd    
    
    
--Type 2    
UPDATE  #FinalTarget SET Utilisedtime = isnull(Utilisedtime,0) - isNull(t2.Down,0)    
FROM    
(Select T1.mc,T1.comp,T1.opn,T1.opr,T1.BatchStart,T1.BatchEnd,    
SUM(    
CASE    
 When autodata.sttime <= T1.BatchStart Then datediff(s, T1.BatchStart,autodata.ndtime )    
 When autodata.sttime > T1.BatchStart Then datediff(s,autodata.sttime,autodata.ndtime)    
END) as Down    
From #T_autodata AutoData INNER Join    
 (Select AutoData.mc,AutoData.comp,AutoData.opn,AutoData.opr,AutoData.Sttime as sttime,AutoData.NdTime as ndtime,    
  ST1.BatchStart as BatchStart,ST1.BatchEnd as BatchEnd From #T_autodata AutoData    
  inner join #FinalTarget ST1 ON ST1.MachineInterface=Autodata.mc and ST1.CompInterface=Autodata.Comp and    
  ST1.opnInterface=Autodata.opn and Autodata.opr = ST1.Oprinterface    
  Where DataType=1 And DateDiff(Second,AutoData.sttime,AutoData.ndtime)>CycleTime And    
  (AutoData.msttime < ST1.BatchStart)And (AutoData.ndtime > ST1.BatchStart) AND (AutoData.ndtime <= ST1.BatchEnd)    
 ) as T1 on t1.mc=autodata.mc and t1.comp=autodata.comp and t1.opn=autodata.opn and T1.opr=Autodata.opr    
Where AutoData.DataType=2    
And ( autodata.Sttime > T1.Sttime )    
And ( autodata.ndtime <  T1.ndtime )    
AND ( autodata.ndtime >  T1.BatchStart )    
GROUP BY T1.mc,T1.comp,T1.opn,T1.opr,T1.BatchStart,T1.BatchEnd)AS T2 Inner Join #FinalTarget on t2.mc = #FinalTarget.machineinterface and    
t2.comp = #FinalTarget.compinterface and t2.opn = #FinalTarget.opninterface and  t2.opr = #FinalTarget.oprinterface     
and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd    
    
    
    
--Type 3    
UPDATE  #FinalTarget SET Utilisedtime = isnull(Utilisedtime,0) - isNull(t2.Down,0)    
FROM    
(Select T1.mc,T1.comp,T1.opn,T1.opr,T1.BatchStart,T1.BatchEnd,    
SUM(CASE    
 When autodata.ndtime > T1.BatchEnd Then datediff(s,autodata.sttime, T1.BatchEnd )    
 When autodata.ndtime <= T1.BatchEnd Then datediff(s , autodata.sttime,autodata.ndtime)    
END) as Down    
From #T_autodata AutoData INNER Join    
 (Select AutoData.mc,AutoData.comp,AutoData.opn,AutoData.opr,AutoData.Sttime as sttime,AutoData.NdTime as ndtime,    
  ST1.BatchStart as BatchStart,ST1.BatchEnd as BatchEnd From #T_autodata AutoData    
  inner join #FinalTarget ST1 ON ST1.MachineInterface=Autodata.mc and ST1.CompInterface=Autodata.Comp and    
  ST1.opnInterface=Autodata.opn and Autodata.opr = ST1.Oprinterface    
  Where DataType=1 And DateDiff(Second,AutoData.sttime,AutoData.ndtime)>CycleTime And    
  (AutoData.sttime >= ST1.BatchStart)And (AutoData.ndtime > ST1.BatchEnd) and (AutoData.sttime< ST1.BatchEnd)    
   ) as T1    
ON t1.mc=autodata.mc and t1.comp=autodata.comp and t1.opn=autodata.opn and T1.opr=Autodata.opr    
Where AutoData.DataType=2    
And (T1.Sttime < autodata.sttime)    
And ( T1.ndtime > autodata.ndtime)    
AND (autodata.sttime  <  T1.BatchEnd)    
GROUP BY T1.mc,T1.comp,T1.opn,T1.opr,T1.BatchStart,T1.BatchEnd )AS T2 Inner Join #FinalTarget on t2.mc = #FinalTarget.machineinterface and    
t2.comp = #FinalTarget.compinterface and t2.opn = #FinalTarget.opninterface and  t2.opr = #FinalTarget.oprinterface     
and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd    
    
    
--For Type4    
UPDATE  #FinalTarget SET Utilisedtime = isnull(Utilisedtime,0) - isNull(t2.Down,0)    
FROM    
(Select T1.mc,T1.comp,T1.opn,T1.opr,T1.BatchStart,T1.BatchEnd,    
SUM(CASE    
 When autodata.sttime >= T1.BatchStart AND autodata.ndtime <= T1.BatchEnd Then datediff(s , autodata.sttime,autodata.ndtime)    
 When autodata.sttime < T1.BatchStart And autodata.ndtime >T1.BatchStart AND autodata.ndtime<=T1.BatchEnd Then datediff(s, T1.BatchStart,autodata.ndtime )    
 When autodata.sttime >= T1.BatchStart AND autodata.sttime<T1.BatchEnd AND autodata.ndtime>T1.BatchEnd Then datediff(s,autodata.sttime, T1.BatchEnd )    
 When autodata.sttime<T1.BatchStart AND autodata.ndtime>T1.BatchEnd   Then datediff(s , T1.BatchStart,T1.BatchEnd)    
END) as Down    
From #T_autodata AutoData INNER Join    
 (Select AutoData.mc,AutoData.comp,AutoData.opn,AutoData.opr,AutoData.Sttime as sttime,AutoData.NdTime as ndtime,    
  ST1.BatchStart as BatchStart,ST1.BatchEnd as BatchEnd  From #T_autodata AutoData    
  inner join #FinalTarget ST1 ON ST1.MachineInterface=Autodata.mc and ST1.CompInterface=Autodata.Comp and    
  ST1.opnInterface=Autodata.opn and Autodata.opr = ST1.Oprinterface    
  where DataType=1 And DateDiff(Second,AutoData.sttime,AutoData.ndtime)>CycleTime And     
  (AutoData.msttime <  ST1.BatchStart) And (AutoData.ndtime > ST1.BatchEnd)    
 ) as T1    
on t1.mc=autodata.mc and t1.comp=autodata.comp and t1.opn=autodata.opn and T1.opr=Autodata.opr     
Where AutoData.DataType=2    
And (T1.Sttime < autodata.sttime  )    
And ( T1.ndtime >  autodata.ndtime)    
AND (autodata.ndtime  >  T1.BatchStart)    
AND (autodata.sttime  <  T1.BatchEnd)    
GROUP BY T1.mc,T1.comp,T1.opn,T1.opr,T1.BatchStart,T1.BatchEnd    
 )AS T2 Inner Join #FinalTarget on t2.mc = #FinalTarget.machineinterface and    
t2.comp = #FinalTarget.compinterface and t2.opn = #FinalTarget.opninterface and  t2.opr = #FinalTarget.oprinterface     
and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd    
    
      
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'    
BEGIN    
     
 --Get the utilised time overlapping with PDT and negate it from UtilisedTime    
  UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) - isNull(T2.PPDT ,0)    
  FROM(    
  SELECT F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.oprinterface,    
     SUM    
     (CASE    
     WHEN autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN DateDiff(second,autodata.msttime,autodata.ndtime) --DR0325 Added    
     WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)    
     WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )    
     WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )    
     END ) as PPDT    
     FROM #T_autodata AutoData    
     CROSS jOIN #PlannedDownTimesShift T    
     INNER JOIN #FinalTarget F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn and F.oprinterface=Autodata.opr    
     WHERE autodata.DataType=1 AND T.MachineInterface=autodata.mc AND    
      ((autodata.msttime >= F.BatchStart  AND autodata.ndtime <=F.BatchEnd)    
      OR ( autodata.msttime < F.BatchStart  AND autodata.ndtime <= F.BatchEnd AND autodata.ndtime > F.BatchStart )    
      OR ( autodata.msttime >= F.BatchStart   AND autodata.msttime <F.BatchEnd AND autodata.ndtime > F.BatchEnd )    
      OR ( autodata.msttime < F.BatchStart  AND autodata.ndtime > F.BatchEnd))    
      AND    
      ((autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)    
      OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )    
      OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )    
      OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )     
      AND    
      ((F.BatchStart >= T.StartTime  AND F.BatchEnd <=T.EndTime)    
      OR ( F.BatchStart < T.StartTime  AND F.BatchEnd <= T.EndTime AND F.BatchEnd > T.StartTime )    
      OR ( F.BatchStart >= T.StartTime   AND F.BatchStart <T.EndTime AND F.BatchEnd > T.EndTime )    
      OR ( F.BatchStart < T.StartTime  AND F.BatchEnd > T.EndTime) )     
      group  by F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.oprinterface    
  )AS T2  Inner Join #FinalTarget on t2.machineinterface = #FinalTarget.machineinterface and    
  t2.compinterface = #FinalTarget.compinterface and t2.opninterface = #FinalTarget.opninterface and  t2.oprinterface = #FinalTarget.oprinterface     
  and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd    
    
 ---mod 12:Add ICD's Overlapping  with PDT to Prodtime    
 /* Fetching Down Records from Production Cycle  */    
  ---mod 12(4):Handle intearction between ICD and PDT for type 1 production record for the selected time period.    
  UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)    
  FROM(    
  Select T1.BatchStart,T1.BatchEnd,autodata.mc,autodata.comp,autodata.opn,autodata.opr,    
  SUM(    
  CASE      
   When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1    
   When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2    
   When (autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3    
   when (autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4    
  END) as IPDT    
  from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join     
   (    
    Select autodata.mc,autodata.comp,autodata.opn,autodata.opr,autodata.Sttime,autodata.NdTime,S.Batchstart,S.BatchEnd,S.FromTm     
     from #T_autodata autodata inner join #FinalTarget S on S.MachineInterface=Autodata.mc and S.CompInterface=Autodata.Comp and    
    S.opnInterface=Autodata.opn and Autodata.opr = S.Oprinterface    
    Where DataType=1 And DateDiff(Second, autodata.sttime, autodata.ndtime)>CycleTime And    
    ( autodata.msttime >= S.Batchstart) AND ( autodata.ndtime <= S.BatchEnd)    
   ) as T1    
  ON AutoData.mc=T1.mc and autodata.comp=T1.comp and Autodata.opn=T1.opn and autodata.opr=T1.opr and T.ShiftSt=T1.FromTm     
  Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc    
  And (( autodata.Sttime > T1.Sttime )    
  And ( autodata.ndtime <  T1.ndtime ))    
  AND    
  ((T.StartTime >=T1.Sttime And T.EndTime <=T1.ndtime )    
  or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)    
  or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )    
  or ( T.StartTime <T1.Sttime And T.EndTime >T1.ndtime ))    
  GROUP BY T1.BatchStart,T1.BatchEnd,autodata.mc,autodata.comp,autodata.opn,autodata.opr    
  )AS T2  Inner Join #FinalTarget on t2.mc = #FinalTarget.machineinterface and    
  t2.comp = #FinalTarget.compinterface and t2.opn = #FinalTarget.opninterface and  t2.opr = #FinalTarget.oprinterface     
  and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd    
    
  ---mod 12(4)    
  /* If production  Records of TYPE-2*/    
  UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)    
  FROM    
  (Select T1.BatchStart,T1.BatchEnd,autodata.mc,autodata.comp,autodata.opn,autodata.opr,    
  SUM(    
  CASE      
   When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1    
   When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2    
   When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3    
   when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4    
  END) as IPDT    
  from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join     
   (    
     Select autodata.mc,autodata.comp,autodata.opn,autodata.opr,autodata.Sttime,autodata.NdTime,S.Batchstart,S.BatchEnd,S.FromTm     
     from #T_autodata autodata inner join #FinalTarget S on S.MachineInterface=Autodata.mc and S.CompInterface=Autodata.Comp and    
     S.opnInterface=Autodata.opn and Autodata.opr = S.Oprinterface    
     Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And    
     (msttime < S.Batchstart)And (ndtime > S.Batchstart) AND (ndtime <= S.BatchEnd)    
    ) as T1    
  ON AutoData.mc=T1.mc and autodata.comp=T1.comp and Autodata.opn=T1.opn and autodata.opr=T1.opr and T.ShiftSt=T1.FromTm     
  Where AutoData.DataType=2  and T.MachineInterface=autodata.mc    
  And (( autodata.Sttime > T1.Sttime )    
  And ( autodata.ndtime <  T1.ndtime )    
  AND ( autodata.ndtime >  T1.Batchstart ))    
  AND    
  (( T.StartTime >= T1.Batchstart )    
  And ( T.StartTime <  T1.ndtime ) )    
  GROUP BY T1.BatchStart,T1.BatchEnd,autodata.mc,autodata.comp,autodata.opn,autodata.opr )AS T2 Inner Join #FinalTarget on t2.mc = #FinalTarget.machineinterface and    
  t2.comp = #FinalTarget.compinterface and t2.opn = #FinalTarget.opninterface and  t2.opr = #FinalTarget.oprinterface     
  and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd    
    
     
    
 /* If production Records of TYPE-3*/    
 UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)    
 FROM    
 (Select T1.BatchStart,T1.BatchEnd,autodata.mc,autodata.comp,autodata.opn,autodata.opr,    
 SUM(    
 CASE      
  When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1    
  When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2    
  When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3    
  when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4    
 END) as IPDT    
 from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join    
  (    
   Select autodata.mc,autodata.comp,autodata.opn,autodata.opr,autodata.Sttime,autodata.NdTime,S.Batchstart,S.BatchEnd,S.FromTm     
   from #T_autodata autodata inner join #FinalTarget S on S.MachineInterface=Autodata.mc and S.CompInterface=Autodata.Comp and    
   S.opnInterface=Autodata.opn and Autodata.opr = S.Oprinterface    
   Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And    
   (sttime >= S.Batchstart And ndtime > S.BatchEnd and autodata.sttime <S.BatchEnd)     
  )as T1    
 ON AutoData.mc=T1.mc and autodata.comp=T1.comp and Autodata.opn=T1.opn and autodata.opr=T1.opr and T.ShiftSt=T1.FromTm     
 Where AutoData.DataType=2  and T.MachineInterface=autodata.mc    
 And ((T1.Sttime < autodata.sttime  )    
 And ( T1.ndtime >  autodata.ndtime)    
 AND (autodata.sttime  <  T1.BatchEnd))    
 AND    
 (( T.EndTime > T1.Sttime )    
 And ( T.EndTime <=T1.BatchEnd ) )    
 GROUP BY T1.BatchStart,T1.BatchEnd,autodata.mc,autodata.comp,autodata.opn,autodata.opr)AS T2 Inner Join #FinalTarget on t2.mc = #FinalTarget.machineinterface and    
 t2.comp = #FinalTarget.compinterface and t2.opn = #FinalTarget.opninterface and  t2.opr = #FinalTarget.oprinterface     
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd    
    
     
 /* If production Records of TYPE-4*/    
 UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)    
 FROM    
 (Select T1.BatchStart,T1.BatchEnd,autodata.mc,autodata.comp,autodata.opn,autodata.opr,    
 SUM(    
 CASE      
  When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1    
  When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2    
  When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3    
  when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4    
 END) as IPDT    
 from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join     
  (    
   Select autodata.mc,autodata.comp,autodata.opn,autodata.opr,autodata.Sttime,autodata.NdTime,S.Batchstart,S.BatchEnd,S.FromTm     
   from #T_autodata autodata inner join #FinalTarget S on S.MachineInterface=Autodata.mc and S.CompInterface=Autodata.Comp and    
   S.opnInterface=Autodata.opn and Autodata.opr = S.Oprinterface    
   Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And    
   (msttime < S.Batchstart)And (ndtime > S.BatchEnd)    
  ) as T1    
 ON AutoData.mc=T1.mc and autodata.comp=T1.comp and Autodata.opn=T1.opn and autodata.opr=T1.opr and T.ShiftSt=T1.FromTm     
 Where AutoData.DataType=2 and T.MachineInterface=autodata.mc    
 And ( (T1.Sttime < autodata.sttime  )    
  And ( T1.ndtime >  autodata.ndtime)    
  AND (autodata.ndtime  >  T1.Batchstart)    
  AND (autodata.sttime  <  T1.BatchEnd))    
 AND    
 (( T.StartTime >=T1.Batchstart)    
 And ( T.EndTime <=T1.BatchEnd ) )    
 GROUP BY T1.BatchStart,T1.BatchEnd,autodata.mc,autodata.comp,autodata.opn,autodata.opr)AS T2  Inner Join #FinalTarget on t2.mc = #FinalTarget.machineinterface and    
 t2.comp = #FinalTarget.compinterface and t2.opn = #FinalTarget.opninterface and  t2.opr = #FinalTarget.oprinterface     
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd    
    
END    
    
    
    
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or 
((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and 
(SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y')    
BEGIN    
    
 --Type 1    
 UPDATE #FinalTarget SET downtime = isnull(downtime,0) + isNull(t2.down,0)    
 from    
 (select S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd,    
 sum(loadunload) as down    
 from #T_autodata autodata     
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface and autodata.opr = S.Oprinterface    
 where (autodata.msttime>=S.BatchStart)    
 and (autodata.ndtime<= S.BatchEnd)    
 and (autodata.datatype=2)    
 group by S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd    
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and     
 t2.operation = #FinalTarget.operation and t2.Operator = #FinalTarget.Operator    
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd    
     
 -- Type 2    
 UPDATE #FinalTarget SET downtime = isnull(downtime,0) + isNull(t2.down,0)    
 from    
 (select S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd,    
 sum(DateDiff(second, S.BatchStart, ndtime)) down    
 from #T_autodata autodata     
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface and autodata.opr = S.Oprinterface    
 where (autodata.sttime<S.BatchStart)    
 and (autodata.ndtime>S.BatchStart)    
 and (autodata.ndtime<= S.BatchEnd)    
 and (autodata.datatype=2)    
 group by S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd    
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and     
 t2.operation = #FinalTarget.operation and t2.Operator = #FinalTarget.Operator    
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd    
     
 -- Type 3    
 UPDATE #FinalTarget SET downtime = isnull(downtime,0) + isNull(t2.down,0)    
 from    
 (select S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd,    
 sum(DateDiff(second, stTime,  S.BatchEnd)) down    
 from #T_autodata autodata    
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface and autodata.opr = S.Oprinterface    
 where (autodata.msttime>=S.BatchStart)    
 and (autodata.sttime< S.BatchEnd)    
 and (autodata.ndtime> S.BatchEnd)    
 and (autodata.datatype=2)group by S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd    
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and     
 t2.operation = #FinalTarget.operation and t2.Operator = #FinalTarget.Operator    
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd    
     
     
 -- Type 4    
 UPDATE #FinalTarget SET downtime = isnull(downtime,0) + isNull(t2.down,0)    
 from    
 (select S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd,    
 sum(DateDiff(second, S.BatchStart,  S.BatchEnd)) down    
 from #T_autodata autodata     
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface and autodata.opr = S.Oprinterface    
 where autodata.msttime<S.BatchStart    
 and autodata.ndtime> S.BatchEnd    
 and (autodata.datatype=2)group by S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd    
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and     
 t2.operation = #FinalTarget.operation and t2.Operator = #FinalTarget.Operator    
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd    
     
    
 ---Management Loss-----    
 -- Type 1    
 UPDATE #FinalTarget SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)    
 from    
 (select S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd,    
 sum(CASE    
 WHEN loadunload >ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)    
 ELSE loadunload    
 END) loss    
 from #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid     
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface and autodata.opr = S.Oprinterface    
 where (autodata.msttime>=S.BatchStart)    
 and (autodata.ndtime<=S.BatchEnd)    
 and (autodata.datatype=2)    
 and (downcodeinformation.availeffy = 1)    
    and (downcodeinformation.ThresholdfromCO <>1) --NR0097    
 group by  S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd    
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and     
 t2.operation = #FinalTarget.operation and t2.Operator = #FinalTarget.Operator    
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd    
    
 -- Type 2    
 UPDATE #FinalTarget SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)    
 from    
 (select S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd,    
  sum(CASE    
 WHEN DateDiff(second, S.BatchStart, ndtime)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)    
 ELSE DateDiff(second, S.BatchStart, ndtime)    
 end) loss    
 from #T_autodata autodata     
  INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid     
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface and autodata.opr = S.Oprinterface    
 where (autodata.sttime<S.BatchStart)    
 and (autodata.ndtime>S.BatchStart)    
 and (autodata.ndtime<=S.BatchEnd)    
 and (autodata.datatype=2)    
 and (downcodeinformation.availeffy = 1)    
 and (downcodeinformation.ThresholdfromCO <>1) --NR0097    
 group by S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd    
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and     
 t2.operation = #FinalTarget.operation and t2.Operator = #FinalTarget.Operator    
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd    
    
 -- Type 3    
 UPDATE #FinalTarget SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)    
 from    
 (select S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd,    
 sum(CASE    
 WHEN DateDiff(second, stTime, S.BatchEnd)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)    
 ELSE DateDiff(second, stTime, S.BatchEnd)    
 END) loss    
 from #T_autodata autodata      
 INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid     
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface and autodata.opr = S.Oprinterface    
 where (autodata.msttime>=S.BatchStart)    
 and (autodata.sttime<S.BatchEnd)    
 and (autodata.ndtime>S.BatchEnd)    
 and (autodata.datatype=2)    
 and (downcodeinformation.availeffy = 1)    
 and (downcodeinformation.ThresholdfromCO <>1) --NR0097    
 group by S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd    
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and     
 t2.operation = #FinalTarget.operation and t2.Operator = #FinalTarget.Operator    
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd    
    
 -- Type 4    
 UPDATE #FinalTarget SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)    
 from    
 (select S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd,    
 sum(CASE    
 WHEN DateDiff(second, S.BatchStart, S.BatchEnd)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)    
 ELSE DateDiff(second, S.BatchStart, S.BatchEnd)    
 END) loss    
 from #T_autodata autodata     
 INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid     
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface and autodata.opr = S.Oprinterface    
 where autodata.msttime<S.BatchStart    
 and autodata.ndtime>S.BatchEnd    
 and (autodata.datatype=2)    
 and (downcodeinformation.availeffy = 1)    
 and (downcodeinformation.ThresholdfromCO <>1) --NR0097    
 group by S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd    
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and     
 t2.operation = #FinalTarget.operation and t2.Operator = #FinalTarget.Operator    
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd    
END    
    
  

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'    
BEGIN    
    
 ---Get the down times which are not of type Management Loss    
 UPDATE #FinalTarget SET downtime = isnull(downtime,0) + isNull(t2.down,0)    
 from    
 (select  F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.oprinterface,    
  sum (CASE    
    WHEN (autodata.msttime >= F.BatchStart  AND autodata.ndtime <=F.BatchEnd)  THEN autodata.loadunload    
    WHEN ( autodata.msttime < F.BatchStart  AND autodata.ndtime <= F.BatchEnd  AND autodata.ndtime > F.BatchStart ) THEN DateDiff(second,F.BatchStart,autodata.ndtime)    
    WHEN ( autodata.msttime >= F.BatchStart   AND autodata.msttime <F.BatchEnd  AND autodata.ndtime > F.BatchEnd  ) THEN DateDiff(second,autodata.msttime,F.BatchEnd )    
    WHEN ( autodata.msttime < F.BatchStart  AND autodata.ndtime > F.BatchEnd ) THEN DateDiff(second,F.BatchStart,F.BatchEnd )    
    END ) as down    
    from #T_autodata autodata     
    inner join #FinalTarget F on autodata.mc = F.Machineinterface and autodata.comp=F.Compinterface and autodata.opn=F.Opninterface and autodata.opr = F.Oprinterface    
    inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid    
  where (autodata.datatype=2) AND    
    (( (autodata.msttime>=F.BatchStart) and (autodata.ndtime<=F.BatchEnd))    
       OR ((autodata.msttime<F.BatchStart)and (autodata.ndtime>F.BatchStart)and (autodata.ndtime<=F.BatchEnd))    
       OR ((autodata.msttime>=F.BatchStart)and (autodata.msttime<F.BatchEnd)and (autodata.ndtime>F.BatchEnd))    
       OR((autodata.msttime<F.BatchStart)and (autodata.ndtime>F.BatchEnd)))     
    AND (downcodeinformation.availeffy = 0)    
       group by F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.oprinterface    
 ) as t2 Inner Join #FinalTarget on t2.machineinterface = #FinalTarget.machineinterface and    
 t2.compinterface = #FinalTarget.compinterface and t2.opninterface = #FinalTarget.opninterface and  t2.oprinterface = #FinalTarget.oprinterface     
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd    
 
 
 UPDATE  #FinalTarget SET Downtime = isnull(Downtime,0) - isNull(T2.PPDT ,0)    
 FROM(    
 SELECT F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.oprinterface,    
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
    INNER JOIN #FinalTarget F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn and F.oprinterface=Autodata.opr    
    WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND (downcodeinformation.availeffy = 0)     
     AND    
     ((autodata.sttime >= F.BatchStart  AND autodata.ndtime <=F.BatchEnd)    
     OR ( autodata.sttime < F.BatchStart  AND autodata.ndtime <= F.BatchEnd AND autodata.ndtime > F.BatchStart )    
     OR ( autodata.sttime >= F.BatchStart   AND autodata.sttime <F.BatchEnd AND autodata.ndtime > F.BatchEnd )    
     OR ( autodata.sttime < F.BatchStart  AND autodata.ndtime > F.BatchEnd))    
     AND    
     ((autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)    
     OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )    
     OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )    
     OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )     
     AND    
     ((F.BatchStart >= T.StartTime  AND F.BatchEnd <=T.EndTime)    
     OR ( F.BatchStart < T.StartTime  AND F.BatchEnd <= T.EndTime AND F.BatchEnd > T.StartTime )    
     OR ( F.BatchStart >= T.StartTime   AND F.BatchStart <T.EndTime AND F.BatchEnd > T.EndTime )    
     OR ( F.BatchStart < T.StartTime  AND F.BatchEnd > T.EndTime) )     
     group  by F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.oprinterface    
 )AS T2  Inner Join #FinalTarget on t2.machineinterface = #FinalTarget.machineinterface and    
 t2.compinterface = #FinalTarget.compinterface and t2.opninterface = #FinalTarget.opninterface and  t2.oprinterface = #FinalTarget.oprinterface     
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd    
    
 UPDATE #FinalTarget SET ManagementLoss = isnull(ManagementLoss,0)+ isNull(t4.Mloss,0),MLDown=isNull(MLDown,0)+isNull(t4.Dloss,0)    
 from    
 (select T3.mc,T3.comp,T3.opn,T3.opr,T3.Batchstart as Batchstart,T3.Batchend as Batchend,sum(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss from    
  (    
 select   T1.id,T1.mc,T1.comp,T1.opn,T1.opr,T1.Threshold,T1.Batchstart as Batchstart,T1.Batchend as Batchend,    
 case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0) > 0    
 then DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)- isnull(T1.Threshold ,0)    
 else 0 End  as Dloss,    
 case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0) > 0    
 then isnull(T1.Threshold,0)    
 else DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0) End  as Mloss    
  from    
     
  (       
   select id,mc,comp,opn,opr,D.threshold,S.Batchstart as Batchstart,S.BatchEnd as BatchEnd,    
   case when autodata.sttime<S.Batchstart then S.Batchstart else sttime END as sttime,    
   case when ndtime>S.BatchEnd then S.BatchEnd else ndtime END as ndtime    
   from #T_autodata autodata     
   inner join downcodeinformation D on autodata.dcode=D.interfaceid     
   INNER JOIN #FinalTarget S on S.machineinterface=Autodata.mc and S.Compinterface=Autodata.comp and S.Opninterface = Autodata.opn and S.oprinterface=Autodata.opr    
   where autodata.datatype=2 AND    
   (    
   (autodata.msttime>=S.Batchstart  and  autodata.ndtime<=S.BatchEnd)    
   OR (autodata.sttime<S.Batchstart and  autodata.ndtime>S.Batchstart and autodata.ndtime<=S.BatchEnd)    
   OR (autodata.msttime>=S.Batchstart  and autodata.sttime<S.BatchEnd  and autodata.ndtime>S.BatchEnd)    
   OR (autodata.msttime<S.Batchstart and autodata.ndtime>S.BatchEnd )    
   ) AND (D.availeffy = 1)    
    and (D.ThresholdfromCO <>1) --NR0097    
  ) as T1      
  left outer join    
  (    
   SELECT id,F.BatchStart,F.BatchEnd,mc,comp,opr,opn,    
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
   INNER JOIN #FinalTarget F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn and F.oprinterface=Autodata.opr    
   WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND     
   (downcodeinformation.availeffy = 1)     
    AND    
    ((autodata.sttime >= F.BatchStart  AND autodata.ndtime <=F.BatchEnd)    
    OR ( autodata.sttime < F.BatchStart  AND autodata.ndtime <= F.BatchEnd AND autodata.ndtime > F.BatchStart )    
    OR ( autodata.sttime >= F.BatchStart   AND autodata.sttime <F.BatchEnd AND autodata.ndtime > F.BatchEnd )    
    OR ( autodata.sttime < F.BatchStart  AND autodata.ndtime > F.BatchEnd))    
    AND    
    ((autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)    
    OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )    
    OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )    
    OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )     
    AND    
    ((F.BatchStart >= T.StartTime  AND F.BatchEnd <=T.EndTime)    
    OR ( F.BatchStart < T.StartTime  AND F.BatchEnd <= T.EndTime AND F.BatchEnd > T.StartTime )    
    OR ( F.BatchStart >= T.StartTime   AND F.BatchStart <T.EndTime AND F.BatchEnd > T.EndTime )    
    OR ( F.BatchStart < T.StartTime  AND F.BatchEnd > T.EndTime) )     
    and (DownCodeInformation.ThresholdfromCO <>1) --NR0097    
    group  by id,F.BatchStart,F.BatchEnd,mc,comp,opr,opn    
  ) as T2 on T1.id=T2.id and T1.mc=T2.mc and T1.comp=T2.comp and T1.opn=T2.opn and T1.opr=T2.opr and T1.Batchstart=T2.Batchstart and T1.Batchend=T2.Batchend ) as T3  group by T3.mc,T3.comp,T3.opn,T3.opr,T3.Batchstart,T3.Batchend    
 ) as t4 Inner Join #FinalTarget on t4.mc = #FinalTarget.machineinterface and    
 t4.comp = #FinalTarget.compinterface and t4.opn = #FinalTarget.opninterface and  t4.opr = #FinalTarget.oprinterface     
 and t4.BatchStart=#FinalTarget.BatchStart and t4.BatchEnd=#FinalTarget.BatchEnd    
    
 UPDATE #FinalTarget  set downtime = isnull(downtime,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)    
END    
    
  
  
    
--Calculation of PartsCount Begins..    
UPDATE #FinalTarget SET components = ISNULL(components,0) + ISNULL(t2.comp1,0),CN = isnull(CN,0) + isNull(t2.C1N1,0)    
From    
(    
 Select T1.mc,T1.comp,T1.opn,T1.opr,T1.Batchstart,T1.Batchend,  
 SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp1,  
SUM((O.cycletime/ISNULL(O.SubOperations,1))* T1.OrginalCount) C1N1  
     From (select mc,comp,opn,opr,BatchStart,BatchEnd,SUM(autodata.partscount)AS OrginalCount from #T_autodata autodata    
     INNER JOIN #FinalTarget F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn and F.oprinterface=Autodata.opr    
     where (autodata.ndtime>F.BatchStart) and (autodata.ndtime<=F.BatchEnd) and (autodata.datatype=1)    
     Group By mc,comp,opn,opr,BatchStart,BatchEnd) as T1    
 INNER JOIN #FinalTarget F on F.machineinterface=T1.mc and F.Compinterface=T1.comp and F.Opninterface = T1.opn and F.oprinterface=T1.opr    
 and F.Batchstart=T1.Batchstart and F.Batchend=T1.Batchend  
 Inner join componentinformation C on F.Compinterface = C.interfaceid    
 Inner join ComponentOperationPricing O ON  F.Opninterface = O.interfaceid and C.Componentid=O.componentid    
 inner join machineinformation on machineinformation.machineid =O.machineid    
 and F.machineinterface=machineinformation.interfaceid    
 GROUP BY T1.mc,T1.comp,T1.opn,T1.opr,T1.Batchstart,T1.Batchend    
) As T2 Inner Join #FinalTarget on T2.mc = #FinalTarget.machineinterface and    
T2.comp = #FinalTarget.compinterface and T2.opn = #FinalTarget.opninterface and  T2.opr = #FinalTarget.oprinterface     
and T2.BatchStart=#FinalTarget.BatchStart and T2.BatchEnd=#FinalTarget.BatchEnd    
    
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'    
BEGIN    
      
 UPDATE #FinalTarget SET components=ISNULL(components,0)- isnull(t2.PlanCt,0) ,CN = isnull(CN,0) - isNull(t2.C1N1,0)   
  FROM ( select autodata.mc,autodata.comp,autodata.opn,autodata.opr,F.Batchstart,F.Batchend,  
  ((CAST(Sum(ISNULL(PartsCount,1)) AS Float)/ISNULL(CO.SubOperations,1))) as PlanCt,  
 SUM((CO.cycletime * ISNULL(PartsCount,1))/ISNULL(CO.SubOperations,1))  C1N1  
   from #T_autodata autodata     
     INNER JOIN #FinalTarget F on F.machineinterface=autodata.mc and F.Compinterface=autodata.comp and F.Opninterface = autodata.opn and F.oprinterface=autodata.opr    
  Inner jOIN #PlannedDownTimesShift T on T.MachineInterface=autodata.mc      
  inner join machineinformation M on autodata.mc=M.Interfaceid    
  Inner join componentinformation CI on autodata.comp=CI.interfaceid     
  inner join componentoperationpricing CO on autodata.opn=CO.interfaceid and    
  CI.componentid=CO.componentid  and CO.machineid=M.machineid    
  WHERE autodata.DataType=1 and    
  (autodata.ndtime>F.BatchStart) and (autodata.ndtime<=F.BatchEnd)     
  AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)    
   Group by autodata.mc,autodata.comp,autodata.opn,autodata.opr,F.Batchstart,F.Batchend,CO.SubOperations     
 ) as T2 Inner Join #FinalTarget on T2.mc = #FinalTarget.machineinterface and    
 T2.comp = #FinalTarget.compinterface and T2.opn = #FinalTarget.opninterface and  T2.opr = #FinalTarget.oprinterface     
 and T2.BatchStart=#FinalTarget.BatchStart and T2.BatchEnd=#FinalTarget.BatchEnd    
     
END    
   
  
 UPDATE #FinalTarget SET Avgcycletime = isnull(Avgcycletime,0) + isNull(t2.avgcycle,0)    
 from    
 (select S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd,    
 sum(cycletime) avgcycle    
 from #T_autodata autodata        
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface and autodata.opr = S.Oprinterface    
 where (autodata.ndtime>S.BatchStart and autodata.ndtime<=S.BatchEnd  )  
 and (autodata.datatype=1)    
 and (autodata.partscount>0)      
 group by S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd    
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and     
 t2.operation = #FinalTarget.operation and t2.Operator = #FinalTarget.Operator    
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd    
  
  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_AvgCycletime_4m_PLD')='Y' --ER0363 Added  
BEGIN  
  
  UPDATE #FinalTarget SET Avgcycletime = isnull(Avgcycletime,0) - isNull(t2.PPDT,0)    
  from  (  
 select A.MachineID,A.Component,A.operation,A.Operator,A.BatchStart,A.BatchEnd,Sum  
   (CASE  
   WHEN A.sttime >= T.StartTime  AND A.ndtime <=T.EndTime  THEN DateDiff(second,A.sttime,A.ndtime) --DR0325 Added  
   WHEN ( A.sttime < T.StartTime  AND A.ndtime <= T.EndTime  AND A.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,A.ndtime)  
   WHEN ( A.sttime >= T.StartTime   AND A.sttime <T.EndTime  AND A.ndtime > T.EndTime  ) THEN DateDiff(second,A.sttime,T.EndTime )  
   WHEN ( A.sttime < T.StartTime  AND A.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
   END)  as PPDT  
   From  
     
   (  
    select S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd,autodata.sttime,autodata.ndtime,autodata.msttime  
    from #T_autodata autodata        
    inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface and autodata.opr = S.Oprinterface    
    where (autodata.ndtime>S.BatchStart and autodata.ndtime<=S.BatchEnd)  
    and (autodata.datatype=1)    
   )A  
   CROSS jOIN PlannedDownTimes T   
   WHERE T.Machine=A.MachineID AND  
   ((A.msttime >= T.StartTime  AND A.ndtime <=T.EndTime)  
   OR ( A.msttime < T.StartTime  AND A.ndtime <= T.EndTime AND A.ndtime > T.StartTime )  
   OR ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime AND A.ndtime > T.EndTime )  
   OR ( A.msttime < T.StartTime  AND A.ndtime > T.EndTime) )   
  group by A.MachineID,A.Component,A.operation,A.Operator,A.BatchStart,A.BatchEnd  
 )  
 as T2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and     
  t2.operation = #FinalTarget.operation and t2.Operator = #FinalTarget.Operator    
  and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd    
  
 --Handle intearction between ICD and PDT for type 1 production record for the selected time period.  
   UPDATE #FinalTarget SET Avgcycletime = isnull(Avgcycletime,0) + isNull(T2.IPDT ,0)  FROM   
  (  
  Select T1.MachineID,T1.Component,T1.operation,T1.Operator,T1.BatchStart,T1.BatchEnd,  
  SUM(  
  CASE    
   When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1  
   When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2  
   When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3  
   when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4  
  END) as IPDT  
  from #T_autodata autodata INNER Join --ER0324 Added  
   ( select S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd,autodata.sttime,autodata.ndtime,autodata.msttime,  
    S.Compinterface,S.Opninterface,S.Oprinterface,autodata.mc  
    from #T_autodata autodata        
    inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface and autodata.opr = S.Oprinterface    
    where (autodata.ndtime>S.BatchStart and autodata.ndtime<=S.BatchEnd)  
    and (autodata.datatype=1) And DateDiff(Second,sttime,ndtime)>CycleTime   
   ) as T1  
  ON AutoData.mc=T1.mc and autodata.comp=T1.Compinterface and autodata.opn=T1.Opninterface and autodata.opr = T1.Oprinterface    
  CROSS jOIN PlannedDownTimes T   
  Where AutoData.DataType=2 And T.Machine=T1.Machineid  
  And (( autodata.Sttime >= T1.Sttime )   
  And ( autodata.ndtime <= T1.ndtime )  
  )  
  AND  
  ((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))  
  or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)  
  or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )  
  or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )))   
  GROUP BY T1.MachineID,T1.Component,T1.operation,T1.Operator,T1.BatchStart,T1.BatchEnd  
  )AS T2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and     
  t2.operation = #FinalTarget.operation and t2.Operator = #FinalTarget.Operator    
  and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd    
  
   
End  
  
Update #FinalTarget set avgCycletime=(isnull(avgCycletime,0)/isnull(components,1))* isnull(suboperations,1)   
from #FinalTarget  
inner join componentoperationpricing C on #FinalTarget.MachineID=C.MachineID and #FinalTarget.component=C.Componentid and  
#FinalTarget.Operation = c.Operationno where components>0  
  
    
  
UPDATE #FinalTarget  
SET Runtime = (UtilisedTime + DownTime - ManagementLoss)   
  
update #FinalTarget set Target= isnull(t2.tcount,0) from  
(  
select F.BatchStart,F.BatchEnd,F.Machineid, CO.componentid as component,CO.Operationno as operation,F.Operator,  
tcount=((F.Runtime*CO.suboperations)/CO.cycletime)*isnull(CO.targetpercent,100) /100  
from componentoperationpricing CO  
inner join #FinalTarget F on co.machineid=F.machineid and CO.Componentid=F.Component and Co.operationno=F.Operation    
) as T2 Inner Join #FinalTarget on t2.Machineid = #FinalTarget.Machineid and    
  t2.component = #FinalTarget.component and t2.Operation = #FinalTarget.Operation and  t2.Operator = #FinalTarget.Operator     
  and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd   
  
  
UPDATE #FinalTarget  
SET  
 ProductionEfficiency = (CN/UtilisedTime) ,  
 AvailabilityEfficiency = (UtilisedTime)/(UtilisedTime + DownTime - ManagementLoss) WHERE UtilisedTime <> 0  
  
UPDATE #FinalTarget  
SET  
 OverAllEfficiency = (ProductionEfficiency * AvailabilityEfficiency)*100,   
 ProductionEfficiency = ProductionEfficiency * 100 ,  
 AvailabilityEfficiency = AvailabilityEfficiency * 100  
  
INSERT INTO  #Downcode(Pdate,Shift,Fromtm,Totm,BatchStart,BatchEnd,machineinterface,Compinterface,Opninterface,oprinterface,downcode,downdescription,downtime)  
select  F.Pdate,F.Shift,F.Fromtm,F.Totm,F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.oprinterface,downcodeinformation.Downid,downcodeinformation.downdescription,    
  sum (CASE    
    WHEN (autodata.msttime >= F.BatchStart  AND autodata.ndtime <=F.BatchEnd)  THEN autodata.loadunload    
    WHEN ( autodata.msttime < F.BatchStart  AND autodata.ndtime <= F.BatchEnd  AND autodata.ndtime > F.BatchStart ) THEN DateDiff(second,F.BatchStart,autodata.ndtime)    
    WHEN ( autodata.msttime >= F.BatchStart   AND autodata.msttime <F.BatchEnd  AND autodata.ndtime > F.BatchEnd  ) THEN DateDiff(second,autodata.msttime,F.BatchEnd )    
    WHEN ( autodata.msttime < F.BatchStart  AND autodata.ndtime > F.BatchEnd ) THEN DateDiff(second,F.BatchStart,F.BatchEnd )    
    END ) as down    
    from #T_autodata autodata     
    inner join #FinalTarget F on autodata.mc = F.Machineinterface and autodata.comp=F.Compinterface and autodata.opn=F.Opninterface and autodata.opr = F.Oprinterface    
    inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid    
  where (autodata.datatype=2) AND    
    (( (autodata.msttime>=F.BatchStart) and (autodata.ndtime<=F.BatchEnd))    
       OR ((autodata.msttime<F.BatchStart)and (autodata.ndtime>F.BatchStart)and (autodata.ndtime<=F.BatchEnd))    
       OR ((autodata.msttime>=F.BatchStart)and (autodata.msttime<F.BatchEnd)and (autodata.ndtime>F.BatchEnd))    
       OR((autodata.msttime<F.BatchStart)and (autodata.ndtime>F.BatchEnd)))     
 --AND downcodeinformation.SortOrder IS NULL   DR0379
       group by F.Pdate,F.Shift,F.Fromtm,F.Totm,F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.oprinterface,downcodeinformation.Downid,downcodeinformation.downdescription  
  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'    
BEGIN     
  UPDATE  #Downcode SET downtime = isnull(downtime,0) - isNull(T2.PPDT ,0)    
  FROM(    
  SELECT F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.oprinterface,    
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
  INNER JOIN #FinalTarget F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn and F.oprinterface=Autodata.opr    
  WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND (downcodeinformation.availeffy = 0) --and downcodeinformation.downid in ('New Job Set up Change','Job Loading','Job Unloading','Waiting for QC Inspector')  
  --AND downcodeinformation.SortOrder IS NULL   --DR0379
   AND    
   ((autodata.sttime >= F.BatchStart  AND autodata.ndtime <=F.BatchEnd)    
   OR ( autodata.sttime < F.BatchStart  AND autodata.ndtime <= F.BatchEnd AND autodata.ndtime > F.BatchStart )    
   OR ( autodata.sttime >= F.BatchStart   AND autodata.sttime <F.BatchEnd AND autodata.ndtime > F.BatchEnd )    
   OR ( autodata.sttime < F.BatchStart  AND autodata.ndtime > F.BatchEnd))    
   AND    
   ((autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)    
   OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )    
   OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )    
   OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )     
   AND    
   ((F.BatchStart >= T.StartTime  AND F.BatchEnd <=T.EndTime)    
   OR ( F.BatchStart < T.StartTime  AND F.BatchEnd <= T.EndTime AND F.BatchEnd > T.StartTime )    
   OR ( F.BatchStart >= T.StartTime   AND F.BatchStart <T.EndTime AND F.BatchEnd > T.EndTime )    
   OR ( F.BatchStart < T.StartTime  AND F.BatchEnd > T.EndTime) )     
   group  by F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.oprinterface    
  )AS T2  Inner Join #Downcode on t2.machineinterface = #Downcode.machineinterface and    
  t2.compinterface = #Downcode.compinterface and t2.opninterface = #Downcode.opninterface and  t2.oprinterface = #Downcode.oprinterface     
  and t2.BatchStart=#Downcode.BatchStart and t2.BatchEnd=#Downcode.BatchEnd   
END  

  UPDATE #FinalTarget SET Downtimecode = t2.Downid ,DowntimeDescription=t2.downdescription      
  from  
 (      
 SELECT distinct t.machineinterface,t.Compinterface,t.Opninterface,t.oprinterface,t.Pdate,t.shift,  
     STUFF(ISNULL((SELECT ', ' + x.downcode + ' [' + cast(dbo.f_FormatTime(sum(x.downtime),'hh:mm:ss') as nvarchar(max))  + ']'  
     FROM #Downcode x  
       WHERE x.downtime<>0 and x.machineinterface = t.machineinterface and x.Compinterface = t.Compinterface and x.Opninterface=t.Opninterface     
 and x.oprinterface=t.oprinterface and x.Pdate=t.Pdate and x.shift=t.shift    
    GROUP BY x.downcode  
     FOR XML PATH (''), TYPE).value('.','NVARCHAR(max)'), ''), 1, 2, '') [downid],  
STUFF(ISNULL((SELECT ', ' + x.downdescription   
     FROM #Downcode x  
       WHERE x.downtime<>0 and x.machineinterface = t.machineinterface and x.Compinterface = t.Compinterface and x.Opninterface=t.Opninterface     
 and x.oprinterface=t.oprinterface and x.Pdate=t.Pdate and x.shift=t.shift    
    GROUP BY x.downdescription  
     FOR XML PATH (''), TYPE).value('.','NVARCHAR(max)'), ''), 1, 2, '') [downdescription]  
   from #Downcode t  
    Group by t.machineinterface,t.Compinterface,t.Opninterface,t.oprinterface,t.Pdate,t.shift  
 ) as t2 Inner Join #FinalTarget on t2.machineinterface = #FinalTarget.machineinterface and t2.compinterface = #FinalTarget.compinterface and t2.opninterface = #FinalTarget.opninterface   
 and  t2.oprinterface = #FinalTarget.oprinterface and t2.Pdate=#FinalTarget.Pdate and t2.shift=#FinalTarget.shift   

select Convert(nvarchar(10),FromTm,120) as Date,Shift,Machineid as MachineName,Component as ProductNo,CompDescription as ProductName,Operation as OprnCode, 
OpnDescription , Operator as OperatorName,dbo.f_FormatTime(SUM(isnull(Utilisedtime,0)),'hh:mm:ss') as Utilisedtime,
Round(SUM(isnull([Target],0)),0) as Target,Round((SUM(isnull(Components,0))),2) as Actual,((Round(SUM(isnull([Target],0)),0)) - (Round((SUM(isnull(Components,0))),2))) as [Difference],
dbo.f_FormatTime((SUM(isnull(stdtime,0))),'mm') as StdCycleTime,dbo.f_FormatTime((Round(SUM(isnull(avgCycletime,0)),2)),'mm') as ActualCycleTime,  
Downtimecode,DowntimeDescription,dbo.f_FormatTime(SUM(isnull(Downtime,0)),'hh:mm:ss') as TotalDown,Round(AVG(isnull(AvailabilityEfficiency,0)),0) as AE ,Round(AVG(isnull(ProductionEfficiency,0)),0) as PE ,
Round(AVG(isnull(OverAllEfficiency,0)),0) as OE  
into #FinalOutput1 from #FinalTarget    
--where (Utilisedtime>0 or Downtime>0 or Components>0)  
where (isnull(Downtime,0)>0 or isnull(Components,0)>0)
Group by Machineid,fromtm,shift,Operator,Component,CompDescription,Operation,OpnDescription,Downtimecode,DowntimeDescription  
Order by Machineid,FromTm  

update #FinalOutput1 set [Target]=Actual,[Difference]=0 where [Target]=0

Update #FinalOutput1 set AE=isnull(T1.AE,0), PE=isnull(T1.PE,0), OE=isnull(T1.OE,0)
FROM(
	select Convert(nvarchar(10),FromTm,120) as Date,Shift,Machineid as MachineName,Component as ProductNo,CompDescription as ProductName,Operation as OprnCode, 
	OpnDescription , Operator as OperatorName,Round(AVG(isnull(AvailabilityEfficiency,0)),0) as AE ,Round(AVG(isnull(ProductionEfficiency,0)),0) as PE ,
	Round(AVG(isnull(OverAllEfficiency,0)),0) as OE  
	from #FinalTarget    
	where (AvailabilityEfficiency>0 or ProductionEfficiency>0 or OverallEfficiency>0)  
	Group by Machineid,fromtm,shift,Operator,Component,CompDescription,Operation,OpnDescription,Downtimecode,DowntimeDescription  
)T1 inner join #FinalOutput1 T2 on T1.[Date]=T2.[Date] and T1.[Shift]=T2.[Shift] and T1.MachineName=T2.MachineName and T1.ProductNo=T2.ProductNo and T1.OprnCode=T2.OprnCode and T1.OperatorName=T2.OperatorName
  
  Select * from #FinalOutput1
    Order by MachineName,[Date]  

END    
  
