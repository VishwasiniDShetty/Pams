/****** Object:  Procedure [dbo].[s_GetShiftwiseMachineUsageReport]    Committed by VersionSQL https://www.versionsql.com ******/

/************************************************************************************************************  
NR0097- swathiKS - 16/Dec/2013 :: To show Shiftwise M-C-O-O Level Utilisedtime, Downtime and Components. (Implemented Batching Concept)  
While Accounting ManagementLoss, To apply Threshold from Componentoperationprcing table for the Downs with "PickFomCO = 1" else apply threshold from Downcodeinformation tablw eith "Availeffy=1".  
Since we are splitting Production and Down Cycle across shifts while showing partscount we have to consider decimal values instead whole Numbers.
[dbo].[s_GetShiftwiseMachineUsageReport] '2014-01-01','2014-01-09','','CLASSIC MCY','','summary'  
**************************************************************************************************************/  
CREATE PROCEDURE [dbo].[s_GetShiftwiseMachineUsageReport]  
 @StartDate datetime,  
 @EndDate datetime,  
 @Shiftname nvarchar(50),  
 @MachineID nvarchar(50) = '',  
 @Plantid nvarchar(50) = '',  
 @param nvarchar(50) = ''  
  
WITH RECOMPILE  
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
 --[PartsCount] [int] NULL ,  
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
 --[PartsCount] [int] NULL ,  
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
 Component nvarchar(50) NOT NULL,  
 Operation nvarchar(50) NOT NULL,  
 Operator nvarchar(50),  
 OprInterface nvarchar(50),  
 FromTm datetime,  
 ToTm datetime,     
 msttime datetime,  
ndtime datetime,  
batchid int,  
autodataid bigint  
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
 BatchStart datetime,  
 BatchEnd datetime,  
 batchid int,  
 Utilisedtime float,  
 Components float,  
 Downtime float,  
 ManagementLoss float,  
 MLDown float  
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
  
CREATE TABLE #Summary  
(  
 MachineID nvarchar(50) NOT NULL,  
 Utilisedtime float,  
 Components float,  
 Downtime float,  
 ManagementLoss float  
)  
  
Declare @strsql nvarchar(4000)  
Declare @strmachine nvarchar(1000)  
Declare @StrTPMMachines AS nvarchar(1000)  
Declare @StrPlantid as nvarchar(1000)  
  
Declare @timeformat as nvarchar(12)  
Declare @CurStrtTime as datetime  
Declare @CurEndTime as datetime  
Declare @T_Start AS Datetime   
Declare @T_End AS Datetime  
  
Select @strsql = ''  
Select @StrTPMMachines = ''  
Select @strmachine = ''  
select @strPlantID = ''  
  
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
  
Select @CurStrtTime=@StartDate  
Select @CurEndTime=@EndDate  
  
  
while @CurStrtTime<=@CurEndTime  
BEGIN  
 INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)  
 EXEC s_GetShiftTime @CurStrtTime,@ShiftName  
 SELECT @CurStrtTime=DATEADD(DAY,1,@CurStrtTime)  
END  
  
  
  
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
select @strsql ='insert into #T_autodataforDown '  
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'  
 select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'  
select @strsql = @strsql + ' from #T_autodata autodata inner join Machineinformation on Machineinformation.interfaceid=Autodata.mc   
inner join Plantmachine on Plantmachine.machineid=Machineinformation.machineid  
where (datatype=1) and (( sttime >='''+ convert(nvarchar(25),@T_Start,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_End,120)+''' ) OR '  
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_Start,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_End,120)+''' )OR '  
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_Start,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_Start,120)+'''  
     and ndtime<='''+convert(nvarchar(25),@T_End,120)+''' )'  
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_Start,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_End,120)+''' and sttime<'''+convert(nvarchar(25),@T_End,120)+''' ) )'  
select @strsql = @strsql + @strmachine + @strPlantID  
print @strsql  
exec (@strsql)  
  
Select @strsql=''  
select @strsql ='insert into #T_autodataforDown '  
select @strsql = @strsql + 'SELECT A1.mc, A1.comp, A1.opn, A1.opr, A1.dcode,A1.sttime,'  
 select @strsql = @strsql + 'A1.ndtime, A1.datatype, A1.cycletime, A1.loadunload, A1.msttime, A1.PartsCount,A1.id'  
select @strsql = @strsql + ' from #T_autodata A1 inner join Machineinformation on Machineinformation.interfaceid=A1.mc   
inner join Plantmachine on Plantmachine.machineid=Machineinformation.machineid  
where A1.datatype=2 and  
(( A1.sttime >='''+ convert(nvarchar(25),@T_Start,120)+''' and A1.ndtime <= '''+convert(nvarchar(25),@T_End,120)+'''  ) OR  
 ( A1.sttime <'''+ convert(nvarchar(25),@T_Start,120)+''' and A1.ndtime >'''+convert(nvarchar(25),@T_End,120)+'''  )OR   
 (A1.sttime <'''+ convert(nvarchar(25),@T_Start,120)+''' and A1.ndtime >'''+ convert(nvarchar(25),@T_Start,120)+''' and A1.ndtime<='''+convert(nvarchar(25),@T_End,120)+'''  ) or  
 (A1.sttime >='''+ convert(nvarchar(25),@T_Start,120)+''' and A1.ndtime >'''+convert(nvarchar(25),@T_End,120)+'''  and A1.sttime<'''+convert(nvarchar(25),@T_End,120)+'''  ) )  
and NOT EXISTS ( select * from #T_autodata A2   
inner join Machineinformation on Machineinformation.interfaceid=A2.mc  
inner join Plantmachine on Plantmachine.machineid=Machineinformation.machineid  
 where  A2.datatype=1 and  ((  A2.sttime >='''+ convert(nvarchar(25),@T_Start,120)+''' and  A2.ndtime <= '''+convert(nvarchar(25),@T_End,120)+'''  ) OR  
 (A2.sttime <'''+ convert(nvarchar(25),@T_Start,120)+''' and  A2.ndtime >'''+convert(nvarchar(25),@T_End,120)+'''  )OR   
 (A2.sttime <'''+ convert(nvarchar(25),@T_Start,120)+''' and  A2.ndtime >'''+ convert(nvarchar(25),@T_Start,120)+''' and  A2.ndtime<='''+convert(nvarchar(25),@T_End,120)+'''  )   
OR (A2.sttime >='''+ convert(nvarchar(25),@T_Start,120)+''' and  A2.ndtime >'''+convert(nvarchar(25),@T_End,120)+'''  and  A2.sttime<'''+convert(nvarchar(25),@T_End,120)+'''  ) )  
and A2.sttime<=A1.sttime and A2.ndtime>A1.ndtime and A1.mc=A2.mc'  
select @strsql = @strsql + @strmachine+ @strPlantID  
select @strsql = @strsql + ' )'  
select @strsql = @strsql + @strmachine+ @strPlantID  
print @strsql  
exec (@strsql)  
  
Select @strsql=''   
Select @strsql= 'insert into #Target(MachineID,machineinterface,Component,Compinterface,Operation,Opninterface,  
Operator,Oprinterface,msttime,ndtime,FromTm,Totm,batchid,autodataid)'  
select @strsql = @strsql + ' SELECT machineinformation.machineid, machineinformation.interfaceid,componentinformation.componentid, componentinformation.interfaceid,  
componentoperationpricing.operationno, componentoperationpricing.interfaceid,EI.Employeeid,EI.interfaceid,  
Case when autodata.msttime< T.Shiftstart then T.Shiftstart else autodata.msttime end,   
Case when autodata.ndtime> T.ShiftEnd then T.ShiftEnd else autodata.ndtime end,  
T.shiftstart,T.Shiftend,0,autodata.id FROM #T_autodataforDown  autodata  
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
select @strsql = @strsql + @strmachine + @strPlantID  
select @strsql = @strsql + ' order by autodata.msttime'  
print @strsql  
exec (@strsql)  
  
  
  
  
declare @mc_prev nvarchar(50),@comp_prev nvarchar(50),@opn_prev nvarchar(50),@opr_prev nvarchar(50),@From_Prev datetime  
declare @mc nvarchar(50),@comp nvarchar(50),@opn nvarchar(50),@opr nvarchar(50),@Fromtime datetime,@id nvarchar(50)  
declare @batchid int  
Declare @autodataid bigint,@autodataid_prev bigint  
  
declare @setupcursor  cursor  
set @setupcursor=cursor for  
select autodataid,FromTm,MachineID,Component,Operation,Operator from #Target order by machineid,msttime  
open @setupcursor  
fetch next from @setupcursor into @autodataid,@Fromtime,@mc,@comp,@opn,@opr  
  
set @autodataid_prev=@autodataid  
set @mc_prev = @mc  
set @comp_prev = @comp  
set @opn_prev = @opn  
set @opr_prev = @opr  
SET @From_Prev = @Fromtime  
set @batchid =1  
  
while @@fetch_status = 0  
begin  
If @mc_prev=@mc and @comp_prev=@comp and @opn_prev=@opn and @opr_prev=@opr and @From_Prev = @Fromtime  
 begin    
  update #Target set batchid = @batchid where autodataid=@autodataid and MachineID=@mc and Component=@comp and Operation=@opn and Operator=@opr and FromTm=@Fromtime  
  print @batchid  
 end  
 else  
 begin   
    set @batchid = @batchid+1          
    update #Target set batchid = @batchid where autodataid=@autodataid and MachineID=@mc and Component=@comp and Operation=@opn and Operator=@opr and FromTm=@Fromtime  
    set @autodataid_prev=@autodataid   
    set @mc_prev=@mc    
    set @comp_prev=@comp  
    set @opn_prev=@opn   
    set @opr_prev = @opr  
    SET @From_Prev = @Fromtime  
 end   
 fetch next from @setupcursor into @autodataid,@Fromtime,@mc,@comp,@opn,@Opr  
   
end  
close @setupcursor  
deallocate @setupcursor  
  
insert into #FinalTarget (MachineID,Component,operation,Operator,machineinterface,Compinterface,Opninterface,Oprinterface,batchid,BatchStart,BatchEnd,FromTm,ToTm,Utilisedtime,Downtime,Components,ManagementLoss,MLDown)   
Select MachineID,Component,operation,Operator,machineinterface,Compinterface,Opninterface,Oprinterface,batchid,min(msttime),max(ndtime),FromTm,ToTm,0,0,0 ,0,0 from #Target   
group by MachineID,Component,operation,Operator,machineinterface,Compinterface,Opninterface,Oprinterface,batchid,FromTm,ToTm order by batchid   
  
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
  
  
  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_
4m_PLD')<>'Y')  
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
  
  
----------------------------- NR0097 Added From here ----------------------------------------------  
  
select autodata.id,S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd,  
isnull(CO.Stdsetuptime,0)AS Stdsetuptime,   
SUM(CASE  
WHEN (autodata.msttime >= S.BatchStart  AND autodata.ndtime <=S.BatchEnd)  THEN autodata.loadunload  
WHEN ( autodata.msttime < S.BatchStart  AND autodata.ndtime <= S.BatchEnd  AND autodata.ndtime > S.BatchStart ) THEN DateDiff(second,S.BatchStart,autodata.ndtime)  
WHEN ( autodata.msttime >= S.BatchStart   AND autodata.msttime <S.BatchEnd  AND autodata.ndtime > S.BatchEnd  ) THEN DateDiff(second,autodata.msttime,S.BatchEnd )  
WHEN ( autodata.msttime < S.BatchStart  AND autodata.ndtime > S.BatchEnd ) THEN DateDiff(second,S.BatchStart,S.BatchEnd )  
END ) as setuptime,0 as MLDown,0 as Downtime into #setuptime  
 from #T_autodata autodata   
 INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid   
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface and autodata.opr = S.Oprinterface  
 left outer join componentoperationpricing CO on S.operation =  CO.interfaceid and S.Component = CO.componentid and CO.machineid = S.MachineID  
 where ((autodata.sttime >= S.BatchStart  AND autodata.ndtime <=S.BatchEnd)  
 OR ( autodata.sttime < S.BatchStart  AND autodata.ndtime <= S.BatchEnd AND autodata.ndtime > S.BatchStart )  
 OR ( autodata.sttime >= S.BatchStart   AND autodata.sttime <S.BatchEnd AND autodata.ndtime > S.BatchEnd )  
 OR ( autodata.sttime < S.BatchStart  AND autodata.ndtime > S.BatchEnd))  
 and (autodata.datatype=2)  
 and (downcodeinformation.ThresholdfromCO =1 )  
 group by autodata.id,S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd,CO.Stdsetuptime  
   
  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
BEGIN  
  
 Update #setuptime set setuptime = isnull(setuptime,0) - isnull(t1.setuptime_pdt,0) from   
 (  
  select autodata.id,S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd,  
  sum(datediff(s,CASE WHEN autodata.sttime >= T.StartTime THEN autodata.sttime else T.StartTime End,  
  CASE WHEN autodata.ndtime <= T.EndTime THEN autodata.ndtime else T.EndTime End))  
  as setuptime_pdt  
  from #T_autodata autodata  
  INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid   
  Inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface and autodata.opr = S.Oprinterface  
  Left outer join componentoperationpricing CO on S.operation =  CO.interfaceid and S.Component = CO.componentid and CO.machineid = S.MachineID  
  CROSS jOIN #PlannedDownTimesShift T  
  where datatype=2 and T.MachineInterface=AutoData.mc   
  and downcodeinformation.ThresholdfromCO = 1   
  AND  
  ((autodata.sttime >=S.BatchStart  AND autodata.ndtime <=S.BatchEnd)  
  OR ( autodata.sttime <S.BatchStart  AND autodata.ndtime <=S.BatchEnd AND autodata.ndtime >S.BatchStart )  
  OR ( autodata.sttime >=S.BatchStart   AND autodata.sttime <S.BatchEnd AND autodata.ndtime >S.BatchEnd )  
  OR ( autodata.sttime <S.BatchStart  AND autodata.ndtime >S.BatchEnd))  
  AND  
  ((autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
  OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
  OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )  
  OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )   
  AND  
  ((S.BatchStart >= T.StartTime  AND S.BatchEnd <=T.EndTime)  
  OR (S.BatchStart < T.StartTime  AND S.BatchEnd <= T.EndTime AND S.BatchEnd > T.StartTime )  
  OR (S.BatchStart >= T.StartTime   AND S.BatchStart <T.EndTime AND S.BatchEnd > T.EndTime )  
  OR (S.BatchStart < T.StartTime  AND S.BatchEnd > T.EndTime) )   
  group by autodata.id,S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd  
 ) as t1 inner join #setuptime on t1.id=#setuptime.id and t1.MachineID = #setuptime.MachineID and #setuptime.Component = t1.Component and #setuptime.operation = t1.operation  
 and t1.Operator=#setuptime.Operator and t1.BatchStart=#setuptime.BatchStart and t1.BatchEnd=#setuptime.BatchEnd  
  
 Update #setuptime set Downtime = isnull(Downtime,0) + isnull(T1.Setupdown,0) from  
 (Select id,MachineID,Component,operation,Operator,BatchStart,BatchEnd,  
  Case when setuptime>stdsetuptime then setuptime-stdsetuptime else 0 end as Setupdown  
  from #setuptime)T1  inner join #setuptime on t1.id=#setuptime.id and t1.MachineID = #setuptime.MachineID and #setuptime.Component = t1.Component and #setuptime.operation = t1.operation  
  and t1.Operator=#setuptime.Operator and t1.BatchStart=#setuptime.BatchStart and t1.BatchEnd=#setuptime.BatchEnd  
  
End  
  
  
Update #setuptime set MLDown = Isnull(MLDown,0) + isnull(T1.SetupML,0) from  
(Select id,MachineID,Component,operation,Operator,BatchStart,BatchEnd,  
Case when setuptime<stdsetuptime then setuptime else stdsetuptime end as SetupML  
from #setuptime)T1 inner join #setuptime on t1.id=#setuptime.id and t1.MachineID = #setuptime.MachineID and #setuptime.Component = t1.Component and #setuptime.operation = t1.operation  
and t1.Operator=#setuptime.Operator and t1.BatchStart=#setuptime.BatchStart and t1.BatchEnd=#setuptime.BatchEnd  
  
  
Update #FinalTarget set Downtime = isnull(Downtime,0) + isnull(T2.Down,0),ManagementLoss=isnull(ManagementLoss,0) + isnull(T2.ML,0) from  
(Select MachineID,Component,operation,Operator,BatchStart,BatchEnd,  
Sum(Downtime) as Down,Sum(MLDown) as ML from #setuptime   
Group by MachineID,Component,operation,Operator,BatchStart,BatchEnd) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and   
t2.operation = #FinalTarget.operation and t2.Operator = #FinalTarget.Operator  
and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  
  
----------------------------- NR0097 Added Till here ----------------------------------------------  

--Calculation of PartsCount Begins..  
UPDATE #FinalTarget SET components = ISNULL(components,0) + ISNULL(t2.comp1,0)  
From  
(  
 Select T1.mc,T1.comp,T1.opn,T1.opr,T1.Batchstart,T1.Batchend,
 --SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp1   --NR0097
 SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp1   --NR0097
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
    
 UPDATE #FinalTarget SET components=ISNULL(components,0)- isnull(t2.PlanCt,0)  
  FROM ( select autodata.mc,autodata.comp,autodata.opn,autodata.opr,F.Batchstart,F.Batchend,
  --(CEILING (CAST(Sum(ISNULL(PartsCount,1)) AS Float)/ISNULL(CO.SubOperations,1))) as PlanCt   --NR0097
  ((CAST(Sum(ISNULL(PartsCount,1)) AS Float)/ISNULL(CO.SubOperations,1))) as PlanCt  --NR0097
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
  

  
If @param = ''  
BEGIN  
 select FromTm as PDate,Machineid,Component,Operation,Operator, BatchStart,  
 BatchEnd,Isnull(Round(Components,2),0) as Components,dbo.f_formattime(Utilisedtime,'mm') as Utilisedtime,dbo.f_formattime(Downtime,'mm') as Downtime  
 from #FinalTarget  where (Utilisedtime>0 or Downtime>0 or Components>0) Order by FromTm,Machineid
END  
  
If @param='Summary'  
BEGIN  
 select Machineid,dbo.f_formattime(Sum(Utilisedtime),'mm') as Utilisedtime,dbo.f_formattime(Sum(Downtime),'mm') as Downtime,ISnull(Round(Sum(Components),2),0) as Components from #FinalTarget  
 where (Utilisedtime>0 or Downtime>0 or Components>0) Group by Machineid  
END  
  
END  
  
