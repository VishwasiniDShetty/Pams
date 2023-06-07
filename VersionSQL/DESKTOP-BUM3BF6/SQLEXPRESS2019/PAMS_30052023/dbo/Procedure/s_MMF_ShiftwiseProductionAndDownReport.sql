/****** Object:  Procedure [dbo].[s_MMF_ShiftwiseProductionAndDownReport]    Committed by VersionSQL https://www.versionsql.com ******/

/************************************************************************************************************  
NR0128- swathiKS - 30/Jan/2016 :: To show Shiftwise M-C-O-O Level Utilisedtime, Downtime and efficiency details for ALFALAVAL. (Implemented Batching Concept)
--[dbo].[s_MMF_ShiftwiseProductionAndDownReport]   '2016-06-14','B','ACE VTL-04','','GridHeader'
--[dbo].[s_MMF_ShiftwiseProductionAndDownReport]   '2016-06-14','B','ACE VTL-04','','Grid'  
--[dbo].[s_MMF_ShiftwiseProductionAndDownReport]   '2016-06-14','B','ACE VTL-04','','JobwiseQty'
--[dbo].[s_MMF_ShiftwiseProductionAndDownReport]   '2016-06-14','B','ACE VTL-04','','JobwiseProdAndDownData'
--[dbo].[s_MMF_ShiftwiseProductionAndDownReport]   '2016-06-14','C','ACE VTL-04','','JobwiseEnergyDetails'
ER0445 - SwathiKs - 24/jan/2017 :: To handle Sorting of componentID in the header.
**************************************************************************************************************/  
CREATE PROCEDURE [dbo].[s_MMF_ShiftwiseProductionAndDownReport]  
 @StartDate datetime,  
 @Shiftname nvarchar(50)='',  
 @MachineID nvarchar(50) = '',  
 @Plantid nvarchar(50) = '',
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
  

CREATE TABLE #Target    
(  
  
MachineID nvarchar(50) NOT NULL,  
machineinterface nvarchar(50),  
Compinterface nvarchar(50),  
OpnInterface nvarchar(50),  
Component nvarchar(50) NOT NULL,  
Operation nvarchar(50) NOT NULL,  
Operator nvarchar(50),  
OprInterface nvarchar(50),  
FromTm datetime,  
ToTm datetime,
sttime datetime,     
msttime datetime,  
ndtime datetime,  
batchid int,  
autodataid bigint ,
stdTime float,
Shift nvarchar(20),
datatype tinyint,  
Components float,  
DownCode nvarchar(50),
DownReason nvarchar(100),
SubOperations int
)  
  
CREATE TABLE #FinalTarget    
(  
 MachineID nvarchar(50) NOT NULL,  
 machineinterface nvarchar(50),  
 Component nvarchar(50) NOT NULL,  
 Compinterface nvarchar(50),  
 Operation nvarchar(50) NOT NULL,  
 OpnInterface nvarchar(50),  
 Operator nvarchar(50),  
 OprInterface nvarchar(50),  
 FromTm datetime,  
 ToTm datetime, 
 batchsttime datetime,     
 BatchStart datetime,  
 BatchEnd datetime,  
 batchid int,  
 BatchTime float,  
 StdTime float,  
 Components float,  
 DownCode nvarchar(50),
 datatype tinyint,  
 Shift nvarchar(20),
 DownReason nvarchar(100),
 SubOperations int,
 avgCycletime float,
 Avgloadunload float
)  
 
CREATE TABLE #EnergyDetails    
(
	CellID nvarchar(50),
	PlantID nvarchar(50),  
	MachineID nvarchar(50) NOT NULL,  
	machineinterface nvarchar(50),  
	Component nvarchar(50) NOT NULL,  
	Compinterface nvarchar(50),  
	Operation nvarchar(50) NOT NULL,  
	OpnInterface nvarchar(50),   
	FromTm datetime,  
	ToTm datetime,     
	BatchStart datetime,  
	BatchEnd datetime,
	MinEnergy float,
	MaxEnergy float,
	kwh float  
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
 Select @strmachine = ' and ( Machineinformation.MachineID = N''' + @MachineID + ''')'  
End  
  
if isnull(@PlantID,'') <> ''  
Begin  
 Select @strPlantID = ' and ( PlantMachine.PlantID = N''' + @PlantID + ''')'  
End  
 
INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)  
EXEC s_GetShiftTime @StartDate,@ShiftName  

  
Select @T_Start=dbo.f_GetLogicalDay(@StartDate,'start')  
Select @T_End=dbo.f_GetLogicalDay(@StartDate,'End')  
 
declare @MinLuLR  integer
set @MinLuLR=isnull((select top 1 valueinint from Shopdefaults where parameter='MinLUforLR'),0)
 
  
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
Select @strsql= 'insert into #Target(MachineID,machineinterface,Component,Compinterface,Operation,Opninterface,  
Operator,Oprinterface,sttime,msttime,ndtime,FromTm,Totm,batchid,autodataid,stdtime,Suboperations,Shift,datatype,components,Downcode,DownReason)'  
select @strsql = @strsql + ' SELECT machineinformation.machineid, machineinformation.interfaceid,componentinformation.componentid, componentinformation.interfaceid,  
componentoperationpricing.operationno, componentoperationpricing.interfaceid,EI.Employeeid,EI.interfaceid, 
Case when autodata.sttime< T.Shiftstart then T.Shiftstart else autodata.sttime end,    
Case when autodata.msttime< T.Shiftstart then T.Shiftstart else autodata.msttime end,   
Case when autodata.ndtime> T.ShiftEnd then T.ShiftEnd else autodata.ndtime end,  
T.shiftstart,T.Shiftend,0,autodata.id,componentoperationpricing.Cycletime,componentoperationpricing.Suboperations,T.shift,autodata.datatype,
0,autodata.dcode,DI.DownID FROM #T_autodata  autodata  
INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID   
INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID    
INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID  AND componentinformation.componentid = componentoperationpricing.componentid  and componentoperationpricing.machineid=machineinformation.machineid   
Left Outer Join Employeeinformation EI on EI.interfaceid=autodata.opr   
Left Outer Join downcodeinformation DI on DI.interfaceid=autodata.dcode  
Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid   
Cross join #ShiftDetails T  
WHERE ((autodata.msttime >= T.Shiftstart  AND autodata.ndtime <= T.ShiftEnd)  
OR ( autodata.msttime < T.Shiftstart  AND autodata.ndtime <= T.ShiftEnd AND autodata.ndtime >T.Shiftstart )  
OR ( autodata.msttime >= T.Shiftstart AND autodata.msttime <T.ShiftEnd AND autodata.ndtime > T.ShiftEnd)  
OR ( autodata.msttime < T.Shiftstart AND autodata.ndtime > T.ShiftEnd))'  
select @strsql = @strsql + @strmachine + @strPlantID 
select @strsql = @strsql + ' order by autodata.msttime'  
print @strsql  
exec (@strsql)  
  

  
declare @mc_prev nvarchar(50),@comp_prev nvarchar(50),@opn_prev nvarchar(50),@datatype_prev nvarchar(50),@From_Prev datetime ,@Dcode_prev nvarchar(50)  
declare @mc nvarchar(50),@comp nvarchar(50),@opn nvarchar(50),@datatype nvarchar(50),@Fromtime datetime,@id nvarchar(50),@Dcode nvarchar(50)
declare @batchid int  
Declare @autodataid bigint,@autodataid_prev bigint  
  
declare @setupcursor  cursor  
set @setupcursor=cursor for  
select autodataid,FromTm,MachineID,Component,Operation,datatype,Downcode from #Target order by machineid,msttime  
open @setupcursor  
fetch next from @setupcursor into @autodataid,@Fromtime,@mc,@comp,@opn,@datatype,@Dcode 
  
set @autodataid_prev=@autodataid  
set @mc_prev = @mc  
set @comp_prev = @comp  
set @opn_prev = @opn  
set @datatype_prev = @datatype  
SET @From_Prev = @Fromtime  
SET @Dcode_prev = @Dcode  

set @batchid =1  
  
while @@fetch_status = 0  
begin  
If @mc_prev=@mc and @comp_prev=@comp and @opn_prev=@opn and @datatype_prev=@datatype and @From_Prev = @Fromtime and ISNULL(@Dcode_prev,'A') = ISNULL(@Dcode,'A')
 begin    
  update #Target set batchid = @batchid where autodataid=@autodataid and MachineID=@mc and Component=@comp and Operation=@opn and datatype=@datatype and FromTm=@Fromtime 
  and ISNULL(Downcode,'A') = ISNULL(@Dcode,'A')  
  print @batchid  
 end  
 else  
 begin   
    set @batchid = @batchid+1          
    update #Target set batchid = @batchid where autodataid=@autodataid and MachineID=@mc and Component=@comp and Operation=@opn and datatype=@datatype and FromTm=@Fromtime and ISNULL(Downcode,'A') = ISNULL(@Dcode,'A')
    set @autodataid_prev=@autodataid   
    set @mc_prev=@mc    
    set @comp_prev=@comp  
    set @opn_prev=@opn   
    set @datatype_prev = @datatype  
    SET @From_Prev = @Fromtime  
	SET @Dcode_prev = @Dcode  

 end   
 fetch next from @setupcursor into @autodataid,@Fromtime,@mc,@comp,@opn,@datatype,@Dcode  
   
end  
close @setupcursor  
deallocate @setupcursor  


insert into #FinalTarget (MachineID,Component,operation,Operator,machineinterface,Compinterface,Opninterface,Oprinterface,Datatype,batchid,Batchsttime,BatchStart,BatchEnd,BatchTime,FromTm,ToTm,stdtime,Suboperations,shift,components,downcode,Downreason)   
Select MachineID,Component,operation,Operator,machineinterface,Compinterface,Opninterface,Oprinterface,Datatype,batchid,min(Sttime),min(msttime),max(ndtime),0,FromTm,ToTm,stdtime,Suboperations,shift,SUM(Components),downcode,Downreason from #Target   
group by MachineID,Component,operation,Operator,machineinterface,Compinterface,Opninterface,Oprinterface,Datatype,batchid,FromTm,ToTm,stdtime,shift,Suboperations,downcode,Downreason order by batchid   
  

--For Prodtime  
UPDATE #FinalTarget SET BatchTime = isnull(BatchTime,0) + isNull(t2.cycle,0)  
from  
(select S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd,  
 sum(case when ((autodata.msttime>=S.BatchStart) and (autodata.ndtime<=S.BatchEnd)) then  (autodata.cycletime+autodata.loadunload)  
   when ((autodata.msttime<S.BatchStart)and (autodata.ndtime>S.BatchStart)and (autodata.ndtime<=S.BatchEnd)) then DateDiff(second, S.BatchStart, autodata.ndtime)  
   when ((autodata.msttime>=S.BatchStart)and (autodata.msttime<S.BatchEnd)and (autodata.ndtime>S.BatchEnd)) then DateDiff(second, autodata.mstTime, S.BatchEnd)  
   when ((autodata.msttime<S.BatchStart)and (autodata.ndtime>S.BatchEnd)) then DateDiff(second, S.BatchStart, S.BatchEnd) END ) as cycle  
from #T_autodata autodata   
inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface and autodata.opr = S.Oprinterface  
where (autodata.datatype=1) And (S.Datatype=1) AND(( (autodata.msttime>=S.BatchStart) and (autodata.ndtime<=S.BatchEnd))  
OR ((autodata.msttime<S.BatchStart)and (autodata.ndtime>S.BatchStart)and (autodata.ndtime<=S.BatchEnd))  
OR ((autodata.msttime>=S.BatchStart)and (autodata.msttime<S.BatchEnd)and (autodata.ndtime>S.BatchEnd))  
OR((autodata.msttime<S.BatchStart)and (autodata.ndtime>S.BatchEnd)))  
group by S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd  
) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and   
t2.operation = #FinalTarget.operation and t2.Operator = #FinalTarget.Operator  
and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  
  
  
--Type 2  
UPDATE  #FinalTarget SET BatchTime = isnull(BatchTime,0) - isNull(t2.Down,0)  
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
  Where autodata.DataType=1 And (ST1.Datatype=1) And DateDiff(Second,AutoData.sttime,AutoData.ndtime)>CycleTime And  
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
UPDATE  #FinalTarget SET BatchTime = isnull(BatchTime,0) - isNull(t2.Down,0)  
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
  Where autodata.DataType=1 And (ST1.Datatype=1) And DateDiff(Second,AutoData.sttime,AutoData.ndtime)>CycleTime And  
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
UPDATE  #FinalTarget SET BatchTime = isnull(BatchTime,0) - isNull(t2.Down,0)  
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
  where autodata.DataType=1 And (ST1.Datatype=1) And DateDiff(Second,AutoData.sttime,AutoData.ndtime)>CycleTime And   
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
   
 --Get the utilised time overlapping with PDT and negate it from BatchTime  
  UPDATE  #FinalTarget SET BatchTime = isnull(BatchTime,0) - isNull(T2.PPDT ,0)  
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
     WHERE autodata.DataType=1 And (F.Datatype=1) AND T.MachineInterface=autodata.mc AND  
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
  UPDATE  #FinalTarget SET BatchTime = isnull(BatchTime,0) + isNull(T2.IPDT ,0)  
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
    Where autodata.DataType=1 And (S.Datatype=1) And DateDiff(Second, autodata.sttime, autodata.ndtime)>CycleTime And  
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
  UPDATE  #FinalTarget SET BatchTime = isnull(BatchTime,0) + isNull(T2.IPDT ,0)  
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
     Where autodata.DataType=1 And (S.Datatype=1) And DateDiff(Second,sttime,ndtime)>CycleTime And  
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
 UPDATE  #FinalTarget SET BatchTime = isnull(BatchTime,0) + isNull(T2.IPDT ,0)  
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
   Where autodata.DataType=1 And (S.Datatype=1) And DateDiff(Second,sttime,ndtime)>CycleTime And  
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
 UPDATE  #FinalTarget SET BatchTime = isnull(BatchTime,0) + isNull(T2.IPDT ,0)  
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
   Where autodata.DataType=1 And (S.Datatype=1) And DateDiff(Second,sttime,ndtime)>CycleTime And  
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


UPDATE #FinalTarget SET BatchTime = isnull(BatchTime,0) + isNull(t2.down,0)  
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
  where (autodata.datatype=2) And (F.Datatype=2) AND  
		(( (autodata.msttime>=F.BatchStart) and (autodata.ndtime<=F.BatchEnd))  
       OR ((autodata.msttime<F.BatchStart)and (autodata.ndtime>F.BatchStart)and (autodata.ndtime<=F.BatchEnd))  
       OR ((autodata.msttime>=F.BatchStart)and (autodata.msttime<F.BatchEnd)and (autodata.ndtime>F.BatchEnd))  
       OR((autodata.msttime<F.BatchStart)and (autodata.ndtime>F.BatchEnd)))   
       group by F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.oprinterface  
 ) as t2 Inner Join #FinalTarget on t2.machineinterface = #FinalTarget.machineinterface and  
 t2.compinterface = #FinalTarget.compinterface and t2.opninterface = #FinalTarget.opninterface and  t2.oprinterface = #FinalTarget.oprinterface   
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd and #FinalTarget.Datatype=2
  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
BEGIN 
   
	 UPDATE  #FinalTarget SET BatchTime = isnull(BatchTime,0) - isNull(T2.PPDT ,0)  
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
		WHERE autodata.DataType=2 And (F.Datatype=2) AND T.MachineInterface=autodata.mc    
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
	 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd and #FinalTarget.Datatype=2

END
  

--UPDATE #FinalTarget SET Downcode = t.DownID
--from(
--SELECT t.MachineID,t.Component,t.operation,t.BatchStart,
--	   STUFF(ISNULL((SELECT ', ' + x.downcode
--				FROM #Target x
--			   WHERE x.datatype=2 and x.MachineID = t.MachineID and x.Component = t.Component and x.operation = t.operation and x.msttime = t.BatchStart
--			GROUP BY x.downcode
--			 FOR XML PATH (''), TYPE).value('.','VARCHAR(max)'), ''), 1, 2, '') [DownID]      
--  FROM #FinalTarget t)
--as t inner join #FinalTarget on #FinalTarget.MachineID = t.MachineID and #FinalTarget.Component = t.Component and #FinalTarget.operation = t.operation and #FinalTarget.BatchStart = t.BatchStart
--
--UPDATE #FinalTarget SET DownReason = t.DownReason
--from(
--SELECT t.MachineID,t.Component,t.operation,t.BatchStart,
--	   STUFF(ISNULL((SELECT ', ' + x.DownReason
--				FROM #Target x
--			   WHERE x.datatype=2 and x.MachineID = t.MachineID and x.Component = t.Component and x.operation = t.operation and x.msttime = t.BatchStart
--			GROUP BY x.DownReason
--			 FOR XML PATH (''), TYPE).value('.','VARCHAR(max)'), ''), 1, 2, '') [DownReason]      
--  FROM #FinalTarget t)
--as t inner join #FinalTarget on #FinalTarget.MachineID = t.MachineID and #FinalTarget.Component = t.Component and #FinalTarget.operation = t.operation and #FinalTarget.BatchStart = t.BatchStart



UPDATE #FinalTarget SET components = ISNULL(components,0) + ISNULL(t2.comp1,0)
From  
(  
 Select T1.mc,T1.comp,T1.opn,T1.opr,T1.Batchstart,T1.Batchend,
 SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp1
     From (select mc,comp,opn,opr,BatchStart,BatchEnd,SUM(autodata.partscount)AS OrginalCount from #T_autodata autodata  
     INNER JOIN #FinalTarget F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn and F.oprinterface=Autodata.opr  
     where ((autodata.ndtime>F.Batchsttime and autodata.ndtime<=F.BatchEnd))
	 and (autodata.datatype=1) and F.Datatype=1  
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
    
 UPDATE #FinalTarget SET components=ISNULL(components,0)- isnull(t2.PlanCt,0) 
  FROM ( select autodata.mc,autodata.comp,autodata.opn,autodata.opr,F.Batchstart,F.Batchend,
  ((CAST(Sum(ISNULL(PartsCount,1)) AS Float)/ISNULL(CO.SubOperations,1))) as PlanCt
  from #T_autodata autodata   
     INNER JOIN #FinalTarget F on F.machineinterface=autodata.mc and F.Compinterface=autodata.comp and F.Opninterface = autodata.opn and F.oprinterface=autodata.opr  
  Inner jOIN #PlannedDownTimesShift T on T.MachineInterface=autodata.mc    
  inner join machineinformation M on autodata.mc=M.Interfaceid  
  Inner join componentinformation CI on autodata.comp=CI.interfaceid   
  inner join componentoperationpricing CO on autodata.opn=CO.interfaceid and  
  CI.componentid=CO.componentid  and CO.machineid=M.machineid  
  WHERE autodata.DataType=1 and F.Datatype=1 and  
  (autodata.ndtime>F.Batchsttime) and (autodata.ndtime<=F.BatchEnd)   
  AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)  
   Group by autodata.mc,autodata.comp,autodata.opn,autodata.opr,F.Batchstart,F.Batchend,CO.SubOperations   
 ) as T2 Inner Join #FinalTarget on T2.mc = #FinalTarget.machineinterface and  
 T2.comp = #FinalTarget.compinterface and T2.opn = #FinalTarget.opninterface and  T2.opr = #FinalTarget.oprinterface   
 and T2.BatchStart=#FinalTarget.BatchStart and T2.BatchEnd=#FinalTarget.BatchEnd  
   
END  

UPDATE #FinalTarget SET Avgcycletime = isnull(Avgcycletime,0) + isNull(t2.avgcycle,0),AVGLoadUnload = isnull(AVGLoadUnload,0) + isnull(LD,0)
 from  
 (select S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd,  
 sum(autodata.cycletime)as avgcycle,Sum(case when autodata.loadunload>=@MinLuLR then (autodata.loadunload) end) as LD
 from #T_autodata autodata      
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface and autodata.opr = S.Oprinterface  
 where (autodata.ndtime>S.Batchsttime and autodata.ndtime<=S.BatchEnd  )
 and (autodata.datatype=1)and S.Datatype=1   
 and (autodata.partscount>0)    
 group by S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd  
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and   
 t2.operation = #FinalTarget.operation and t2.Operator = #FinalTarget.Operator  
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  


If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_AvgCycletime_4m_PLD')='Y' --ER0363 Added
BEGIN

	 UPDATE #FinalTarget SET Avgcycletime = isnull(Avgcycletime,0) - isNull(t2.PPDT,0),AVGLoadUnload = isnull(AVGLoadUnload,0) - isnull(LD,0)  
	 from  (
	select A.MachineID,A.Component,A.operation,A.Operator,A.BatchStart,A.BatchEnd,Sum
			(CASE
			WHEN A.sttime >= T.StartTime  AND A.ndtime <=T.EndTime  THEN DateDiff(second,A.sttime,A.ndtime) --DR0325 Added
			WHEN ( A.sttime < T.StartTime  AND A.ndtime <= T.EndTime  AND A.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,A.ndtime)
			WHEN ( A.sttime >= T.StartTime   AND A.sttime <T.EndTime  AND A.ndtime > T.EndTime  ) THEN DateDiff(second,A.sttime,T.EndTime )
			WHEN ( A.sttime < T.StartTime  AND A.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END)  as PPDT,
		    sum(case
			WHEN A.msttime >= T.StartTime  AND A.sttime <=T.EndTime  THEN DateDiff(second,A.msttime,A.sttime)
			WHEN ( A.msttime < T.StartTime  AND A.sttime <= T.EndTime  AND A.sttime > T.StartTime ) THEN DateDiff(second,T.StartTime,A.sttime)
			WHEN ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime  AND A.sttime > T.EndTime  ) THEN DateDiff(second,A.msttime,T.EndTime )
			WHEN ( A.msttime < T.StartTime  AND A.sttime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END)  as LD
			From
			
			(
				select S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd,autodata.sttime,autodata.ndtime,autodata.msttime
				from #T_autodata autodata      
				inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface and autodata.opr = S.Oprinterface  
				where (autodata.ndtime>S.Batchsttime and autodata.ndtime<=S.BatchEnd)
				and (autodata.datatype=1) and S.Datatype=1  
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
		 UPDATE #FinalTarget SET Avgcycletime = isnull(Avgcycletime,0) + isNull(T2.IPDT ,0) 	FROM	
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
			(	select S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd,autodata.sttime,autodata.ndtime,autodata.msttime,
				S.Compinterface,S.Opninterface,S.Oprinterface,autodata.mc
				from #T_autodata autodata      
				inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface and autodata.opr = S.Oprinterface  
				where (autodata.ndtime>S.Batchsttime and autodata.ndtime<=S.BatchEnd)
				and (autodata.datatype=1) and S.Datatype=1  And DateDiff(Second,sttime,ndtime)>CycleTime 
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



Update #FinalTarget set avgCycletime=(isnull(T.avgCycletime,0)/isnull(T.components,1))* isnull(T.suboperations,1),
AVGLoadUnload=(isnull(T.AVGLoadUnload,0)/isnull(T.components,1))* isnull(T.suboperations,1) From
(Select Component,suboperations,SUM(Components) as Components,SUM(avgCycletime) as avgCycletime,SUM(AVGLoadUnload) as AVGLoadUnload from #FinalTarget
where components>0 Group by Component,suboperations)T inner join #FinalTarget on #FinalTarget.Component=T.Component




If @Param = 'Grid'
Begin

	select MachineID,Component,Datatype,Replace(LEFT(CONVERT(VARCHAR,BatchStart,108),5),':','.') as BatchStart,Replace(LEFT(CONVERT(VARCHAR,BatchEnd,108),5),':','.') as BatchEnd,Round(dbo.f_FormatTime(SUM(BatchTime),'mm'),0) as BatchTime,SUM(Components) as Components,Downcode,DownReason from #finaltarget 
	Group by MachineID,Component,Datatype,BatchStart,BatchEnd,Downcode,DownReason,avgCycletime Order by BatchStart
	return
END

If @Param = 'JobwiseQty'
Begin

	 select Component as JobName,SUM(Components) as TotalProduction,Min(Batchstart) as Batchstart from #finaltarget Group by Component 
	 order by batchstart
	 return
END

If @Param = 'GridHeader'
Begin

	Select MachineID,Component,Operator,stdtime,AvgCycleTime,AvgLoadunload,MIN(BatchStart) as BatchStart INTO #Tempfinaltarget From #finaltarget
	Group by MachineID,Component,Operator,stdtime,AvgCycleTime,AvgLoadunload Order by BatchStart

	Declare @HMachine as nvarchar(50)
	SET @HMachine = (Select Top 1 MachineID From #Tempfinaltarget)

	Select Max(BatchStart) as Batchstart,Component INTO #component from #Tempfinaltarget Group by Component order by BatchStart
	Declare @Hcomponent as nvarchar(max);
	Select @Hcomponent = COALESCE(@Hcomponent + ',', '') + CAST(x.Component AS NVARCHAR) 
	FROM #component x 

	Select Max(BatchStart) as Batchstart,Operator INTO #Operator from #Tempfinaltarget Group by Operator order by BatchStart
	Declare @HOperator as nvarchar(max);
	Select @HOperator = COALESCE(@HOperator + ',', '') + CAST(x.Operator AS NVARCHAR) 
	FROM #Operator x 

	Select MachineID,Component,stdtime,AvgCycleTime,AvgLoadunload,MIN(BatchStart) as BatchStart INTO #Cyclefinaltarget From #finaltarget
	where datatype = 1 Group by MachineID,Component,stdtime,AvgCycleTime,AvgLoadunload Order by BatchStart

	Select distinct BatchStart,Round(dbo.f_FormatTime((stdtime),'ss'),2) as StdCycleTime INTO #StdCycle from #Cyclefinaltarget order by BatchStart
	Declare @StdTime as nvarchar(max);
	Select @StdTime = COALESCE(@StdTime + ',', '') + CAST(x.StdCycleTime AS NVARCHAR) 
	FROM #StdCycle x 

	Select distinct BatchStart,Round(dbo.f_FormatTime((AvgCycleTime+AvgLoadunload),'ss'),2) as AvgCycleTime INTO #AvgCycle from #Cyclefinaltarget order by BatchStart
	DECLARE @Avg NVARCHAR(MAX);
	SELECT @Avg= COALESCE(@Avg + ',', '') + CAST(x.avgCycletime AS NVARCHAR)
	FROM #AvgCycle x 


	 SELECT @StartDate as Date,@ShiftName as Shift,@HMachine as Unit,@HOperator as Gang,@Hcomponent as JobName,@StdTime as StdTime,@Avg as ActualCycletime
	return
END

If @param = 'JobwiseProdAndDownData'
Begin

		Create table #JobDetails
		(
			Jobname nvarchar(50),
			Batchstart nvarchar(50),
			ProdTime float,
			Btime float,
			Group2 nvarchar(50),
			DownTime float
		)

		Insert Into #JobDetails(Jobname,Group2)
		Select #finaltarget.Component,D.Group2 from #finaltarget 
		Cross Join (Select Distinct Group2 from Downcodeinformation where Group2 IS NOT NULL and Group2<>''
		)D 

		Update #JobDetails Set ProdTime = T.PTime From
		(Select Component,SUM(BatchTime) as Ptime From #finaltarget
		where Datatype=1 Group By Component)T inner join #JobDetails on #JobDetails.Jobname=T.Component

		Update #JobDetails Set Batchstart = T.Batchstart From
		(Select Component,Min(Batchstart) as Batchstart From #finaltarget
		Group By Component)T inner join #JobDetails on #JobDetails.Jobname=T.Component

		Update #JobDetails Set Btime = T.Btime From
		(Select Component,SUM(BatchTime) as Btime From #finaltarget
		Group By Component)T inner join #JobDetails on #JobDetails.Jobname=T.Component

		UPDATE #JobDetails SET downtime = isnull(downtime,0) + isNull(t2.down,0)
		from
		(select f.MachineID,F.Component,downcodeinformation.Group2,sum(
		CASE
		WHEN  autodata.msttime>=F.BatchStart  and  autodata.ndtime<=F.BatchEnd  THEN  loadunload
		WHEN (autodata.sttime<F.BatchStart and  autodata.ndtime>F.BatchStart and autodata.ndtime<=F.BatchEnd)  THEN DateDiff(second, F.BatchStart, ndtime)
		WHEN (autodata.msttime>=F.BatchStart  and autodata.sttime<F.BatchEnd  and autodata.ndtime>F.BatchEnd)  THEN DateDiff(second, stTime, F.BatchEnd)
		WHEN autodata.msttime<F.BatchStart and autodata.ndtime>F.BatchEnd   THEN DateDiff(second, F.BatchStart, F.BatchEnd)
		END
		)AS down
		from #T_autodata As autodata 
		Inner Join #finaltarget F On Autodata.mc = F.machineinterface and Autodata.comp = F.compinterface and Autodata.opn = F.opninterface
		Inner JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
		inner join Downcategoryinformation on Downcategoryinformation.Downcategory=downcodeinformation.Catagory
		where autodata.datatype=2 AND F.datatype=2 and 
		(
		(autodata.msttime>=F.BatchStart  and  autodata.ndtime<=F.BatchEnd)
		OR (autodata.sttime<F.BatchStart and  autodata.ndtime>F.BatchStart and autodata.ndtime<=F.BatchEnd)
		OR (autodata.msttime>=F.BatchStart  and autodata.sttime<F.BatchEnd  and autodata.ndtime>F.BatchEnd)
		OR (autodata.msttime<F.BatchStart and autodata.ndtime>F.BatchEnd )
		) 
		group by F.MachineID,F.Component,downcodeinformation.Group2
		) as t2 inner join #JobDetails on #JobDetails.Jobname=T2.Component and #JobDetails.Group2=T2.Group2

	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
	BEGIN 

		UPDATE #JobDetails set downtime = isnull(downtime,0) - isNull(T2.PPDT ,0) FROM
		(
		SELECT f.MachineID,F.Component,downcodeinformation.Group2,SUM
		(CASE
		WHEN autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
		WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
		WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )
		WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
		END ) as PPDT
		from #T_autodata As autodata Cross Join #PlannedDownTimesShift T
		Inner Join #finaltarget F On Autodata.mc = F.machineinterface and Autodata.comp = F.compinterface and Autodata.opn = F.opninterface
		Inner JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
		inner join Downcategoryinformation on Downcategoryinformation.Downcategory=downcodeinformation.Catagory
		where autodata.datatype=2 AND F.datatype=2 and  T.MachineInterface=autodata.mc AND
		(
		(autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
		OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
		OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )
		OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime)
		) AND
		(
		(autodata.msttime>=F.BatchStart  and  autodata.ndtime<=F.BatchEnd)
		OR (autodata.msttime<F.BatchStart and  autodata.ndtime>F.BatchStart and autodata.ndtime<=F.BatchEnd)
		OR (autodata.msttime>=F.BatchStart  and autodata.msttime<F.BatchEnd  and autodata.ndtime>F.BatchEnd)
		OR (autodata.msttime<F.BatchStart and autodata.ndtime>F.BatchEnd )
		)  AND  
		 ((F.BatchStart >= T.StartTime  AND F.BatchEnd <=T.EndTime)  
		 OR ( F.BatchStart < T.StartTime  AND F.BatchEnd <= T.EndTime AND F.BatchEnd > T.StartTime )  
		 OR ( F.BatchStart >= T.StartTime   AND F.BatchStart <T.EndTime AND F.BatchEnd > T.EndTime )  
		 OR ( F.BatchStart < T.StartTime  AND F.BatchEnd > T.EndTime) )   
		group by f.MachineID,F.Component,downcodeinformation.Group2
		) as T2 inner join #JobDetails on #JobDetails.Jobname=T2.Component and #JobDetails.Group2=T2.Group2

	END

		Update #JobDetails SET Downtime = ROUND(dbo.f_FormatTime(Downtime,'mm'),0),BTime=Round(dbo.f_FormatTime(BTime,'mm'),0),ProdTime=Round(dbo.f_FormatTime(ProdTime,'mm'),0)

		DECLARE @SelectColumnName AS NVARCHAR(2000)
		DECLARE @DynamicPivotQuery1 AS NVARCHAR(2000)



		SELECT @SelectColumnName= ISNULL(@SelectColumnName + ',','') 
		+ QUOTENAME(Group2)
		FROM (select distinct Group2 from Downcodeinformation where Group2 IS NOT NULL and Group2<>'') AS BatchValues 

		SET @DynamicPivotQuery1 = 
		N'SELECT Jobname,BTime,ProdTime,' + @SelectColumnName + ' 
		FROM (select Jobname,BTime,ProdTime,Group2,Downtime,Batchstart
		from #JobDetails 
		)as s 
		PIVOT (max(Downtime)
		FOR [Group2] IN (' + @SelectColumnName + ')) AS PVTTable order by Batchstart'

		EXEC sp_executesql @DynamicPivotQuery1

		return

END

If @Param = 'JobwiseEnergyDetails'
Begin

insert into #EnergyDetails(CellID,PlantID,Machineinterface,MachineID,Compinterface,Component,Opninterface,operation,batchstart,batchend,minenergy,maxenergy,kwh)
select Cellhistory.CellID,PlantMachine.PlantID,NI.NodeInterface,NI.NodeId,F.Compinterface,F.Component,F.Opninterface,F.operation,F.batchstart,F.batchend,0,0,0 from #FinalTarget F
INNER JOIN Machineinformation ON F.Machineinterface = machineinformation.InterfaceID
inner join Cellhistory on Cellhistory.machineid=machineinformation.machineid
Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid
cross join MachineNodeInformation NI
where machineinformation.machineid = NI.MachineID --and F.Datatype=1


Update #EnergyDetails set MinEnergy = ISNULL(MinEnergy,0)+ISNULL(t2.kwh,0) from 
(
	select T1.MachineiD,T1.batchstart,T1.batchend,round(kwh,2) as kwh from 
	(
	select  T.MachineiD,D.batchstart,D.batchend,min(gtime) as mingtime
	from tcs_energyconsumption T WITH(NOLOCK) inner join #EnergyDetails D on 
	T.machineID = D.MachineID and T.gtime >= D.batchstart and T.gtime <= D.batchend
	where T.kwh>0 group by  T.MachineiD,D.batchstart,D.batchend
	)T1 inner join tcs_energyconsumption on tcs_energyconsumption.machineid=T1.machineid and tcs_energyconsumption.gtime=T1.mingtime

) as T2 Inner join #EnergyDetails on T2.Machineid = #EnergyDetails.machineid
and T2.batchstart = #EnergyDetails.batchstart and T2.batchend = #EnergyDetails.batchend

Update #EnergyDetails set MaxEnergy = ISNULL(MaxEnergy,0)+ISNULL(t2.kwh,0) from 
(
	select T1.MachineiD,T1.batchstart,T1.batchend,round(kwh,2) as kwh from 
	(
	select  T.MachineiD,D.batchstart,D.batchend,max(gtime) as maxgtime
	from tcs_energyconsumption T WITH(NOLOCK) inner join #EnergyDetails D on 
	T.machineID = D.MachineID and T.gtime >= D.batchstart and T.gtime <= D.batchend
	where T.kwh>0 group by  T.MachineiD,D.batchstart,D.batchend
	)T1 inner join tcs_energyconsumption on tcs_energyconsumption.machineid=T1.machineid and tcs_energyconsumption.gtime=T1.maxgtime

) as T2 Inner join #EnergyDetails on T2.Machineid = #EnergyDetails.machineid
and T2.batchstart = #EnergyDetails.batchstart and T2.batchend = #EnergyDetails.batchend

Update #EnergyDetails set kwh = Isnull(round((MaxEnergy - MinEnergy),2) ,0)

Create table #Energy
(
JobName nvarchar(50),
BatchStart Datetime,
BatchEnd datetime,
EnergyConsumption nvarchar(50),
InitialReading nvarchar(50),
LastReading nvarchar(50)
)

Insert into #Energy(JobName,BatchStart,BatchEnd,EnergyConsumption,InitialReading,LastReading)
	SELECT distinct t.Component,t.BatchStart,t.BatchEnd,0,
		   STUFF(ISNULL((SELECT ', ' + cast(x.MinEnergy as nvarchar)
					FROM #EnergyDetails x
				   WHERE  x.component=t.component and x.batchstart=t.Batchstart
				GROUP BY x.MinEnergy 
				 FOR XML PATH (''), TYPE).value('.','NVARCHAR(max)'), ''), 1, 2, '') [InitialReading],
	    STUFF(ISNULL((SELECT ', ' + cast(x.MaxEnergy as nvarchar)
					FROM #EnergyDetails x
				   WHERE  x.component=t.component and x.batchstart=t.Batchstart
				GROUP BY x.MaxEnergy 
				 FOR XML PATH (''), TYPE).value('.','NVARCHAR(max)'), ''), 1, 2, '') [LastReading] from #EnergyDetails t
				Group by t.Component,t.BatchStart,t.BatchEnd

Update #Energy Set EnergyConsumption = T1.kwh from 
(Select Batchstart,Component,cast(Round(SUM(kwh),2) as nvarchar) as kwh from #EnergyDetails 
group by Batchstart,component)T1 inner join #Energy on #Energy.JobName=t1.component and #Energy.batchstart=t1.Batchstart



select JobName,Replace(LEFT(CONVERT(VARCHAR,BatchStart,108),5),':','.') as BatchStart,Replace(LEFT(CONVERT(VARCHAR,BatchEnd,108),5),':','.') as BatchEnd,InitialReading,LastReading,EnergyConsumption from #Energy
where EnergyConsumption>'0' Order by BatchStart,BatchEnd 

END
  
END  
