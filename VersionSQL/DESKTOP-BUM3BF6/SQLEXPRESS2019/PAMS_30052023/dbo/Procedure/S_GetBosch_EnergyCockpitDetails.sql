/****** Object:  Procedure [dbo].[S_GetBosch_EnergyCockpitDetails]    Committed by VersionSQL https://www.versionsql.com ******/

  
  
/************************************************************************************************************    
ER0449 - swathiKS - 30/Apr/2017 :: Created New procedure to get Houwise and Shiftwise energy and production Details.    
--[dbo].[S_GetBosch_EnergyCockpitDetails]   '2017-01-24','2017-01-25','','CNC GRINDING','','shift'  
**************************************************************************************************************/    
CREATE PROCEDURE [dbo].[S_GetBosch_EnergyCockpitDetails]  
 @StartDate datetime,    
 @EndDate datetime,    
 @Shiftname nvarchar(50)='',    
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
ShiftEnd datetime,  
Hourstart datetime,    
Hourend datetime,  
Hourid int,  
Shiftid int    
)    
   
CREATE TABLE #SDetails     
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
msttime datetime,    
ndtime datetime,    
batchid int,    
autodataid bigint ,  
stdTime float,  
Shift nvarchar(20),  
Shiftid int    
  
)    
    
CREATE TABLE #FinalTarget      
(    
    
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
 batchid int,    
 Utilisedtime float,    
 Components float,    
 Shift nvarchar(20),  
 Cost float,  
Energy float,  
Maxenergy float,  
Minenergy float,  
Shiftid int    
  
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
    
declare @counter as datetime            
declare @stdate as nvarchar(20)    
  
Select @CurStrtTime=@StartDate    
Select @CurEndTime=@EndDate    
    
If @Param ='Shift'   
Begin  
  while @CurStrtTime<=@CurEndTime    
  BEGIN    
   INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)    
   EXEC s_GetShiftTime @CurStrtTime,@ShiftName    
   SELECT @CurStrtTime=DATEADD(DAY,1,@CurStrtTime)    
  END    
  
  update #ShiftDetails set shiftid=T.SHIFTID FROM  
  (Select S.Shiftid,SD.Shift from shiftdetails S inner join #ShiftDetails SD on SD.shift=S.shiftname  
   where S.running=1)T inner join #ShiftDetails on #ShiftDetails.shift=T.shift  
END  
  
If @Param ='Hour'  
Begin    
  
 INSERT #SDetails(Pdate, Shift, ShiftStart, ShiftEnd)    
 EXEC s_GetShiftTime @CurStrtTime,@ShiftName    
  
 select @stdate = CAST(datePart(yyyy,@CurStrtTime) AS nvarchar(4)) + '-' + CAST(datePart(mm,@CurStrtTime) AS nvarchar(2)) + '-' + CAST(datePart(dd,@CurStrtTime) AS nvarchar(2))            
 select @counter=convert(datetime, cast(DATEPART(yyyy,@CurStrtTime)as nvarchar(4))+'-'+cast(datepart(mm,@CurStrtTime)as nvarchar(2))+'-'+cast(datepart(dd,@CurStrtTime)as nvarchar(2)) +' 00:00:00.000')            
    
  
 INSERT #ShiftDetails(Pdate, Shift, ShiftStart,ShiftEnd,HourID,ShiftID,HourStart,HourEnd)    
 select @counter,S.Shift,S.ShiftStart,S.ShiftEnd,SH.HourID,SH.Shiftid,            
 dateadd(day,SH.Fromday,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.HourStart) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourStart) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourStart) as nvarchar(2))))),            
 dateadd(day,SH.Today,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.HourEnd) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourEnd) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourEnd) as nvarchar(2)))))            
 from #SDetails S   
    inner join Shiftdetails SD on S.shift=SD.shiftname  
 inner join Shifthourdefinition SH on SH.shiftid=SD.Shiftid            
 where SD.running=1   
  
END    
    
Select @T_Start=dbo.f_GetLogicalDay(@StartDate,'start')    
Select @T_End=dbo.f_GetLogicalDay(@EndDate,'End')    
    
If @param='shift'  
begin    
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
     
end  
  
If @param='hour'  
begin   
   
 /* Planned Down times for the given time period */    
 Select @strsql=''    
 select @strsql = 'insert INTO #PlannedDownTimesShift(StartTime,EndTime,Machine,MachineInterface,Downreason,Shiftst)'    
 select @strsql = @strsql + 'select    
 CASE When StartTime<T1.Hourstart Then T1.Hourstart Else StartTime End,    
 case When EndTime>T1.Hourend Then T1.Hourend Else EndTime End,    
 Machine,MachineInformation.InterfaceID,    
 DownReason,T1.Hourstart    
 FROM PlannedDownTimes cross join #ShiftDetails T1    
 inner join MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID    
 WHERE PDTstatus =1 and (    
 (StartTime >= T1.Hourstart  AND EndTime <=T1.Hourend)    
 OR ( StartTime < T1.Hourstart  AND EndTime <= T1.Hourend AND EndTime > T1.Hourstart )    
 OR ( StartTime >= T1.Hourstart   AND StartTime <T1.Hourend AND EndTime > T1.Hourend )    
 OR ( StartTime < T1.Hourstart  AND EndTime > T1.Hourend) )'    
 select @strsql = @strsql + @strmachine     
 select @strsql = @strsql + 'ORDER BY StartTime'    
 print @strsql    
 exec (@strsql)    
     
end  
    
    
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
    
  
If @param='Shift'  
Begin  
  
 Select @strsql=''     
 Select @strsql= 'insert into #Target(MachineID,machineinterface,Component,Compinterface,Operation,Opninterface,msttime,ndtime,FromTm,Totm,batchid,autodataid,stdtime,Shift,Shiftid)'    
 select @strsql = @strsql + ' SELECT machineinformation.machineid, machineinformation.interfaceid,componentinformation.componentid, componentinformation.interfaceid,    
 componentoperationpricing.operationno, componentoperationpricing.interfaceid,   
 Case when autodata.msttime< T.Shiftstart then T.Shiftstart else autodata.msttime end,     
 Case when autodata.ndtime> T.ShiftEnd then T.ShiftEnd else autodata.ndtime end,    
 T.shiftstart,T.Shiftend,0,autodata.id,componentoperationpricing.cycletime,T.shift,T.Shiftid FROM #T_autodata  autodata    
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
End  
  
    
  
If @param='Hour'  
Begin  
  
 Select @strsql=''     
 Select @strsql= 'insert into #Target(MachineID,machineinterface,Component,Compinterface,Operation,Opninterface,msttime,ndtime,FromTm,Totm,batchid,autodataid,stdtime,Shift,Shiftid)'    
 select @strsql = @strsql + ' SELECT machineinformation.machineid, machineinformation.interfaceid,componentinformation.componentid, componentinformation.interfaceid,    
 componentoperationpricing.operationno, componentoperationpricing.interfaceid,   
 Case when autodata.msttime< T.HourStart then T.HourStart else autodata.msttime end,     
 Case when autodata.ndtime> T.HourEnd then T.HourEnd else autodata.ndtime end,    
 T.HourStart,T.HourEnd,0,autodata.id,componentoperationpricing.cycletime,T.shift,T.Shiftid FROM #T_autodata  autodata    
 INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID     
 INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID      
 INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID    
 AND componentinformation.componentid = componentoperationpricing.componentid    
 and componentoperationpricing.machineid=machineinformation.machineid     
 inner Join Employeeinformation EI on EI.interfaceid=autodata.opr     
 Left Outer Join downcodeinformation DI on DI.interfaceid=autodata.dcode    
 Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid     
 Cross join #ShiftDetails T    
 WHERE ((autodata.msttime >= T.HourStart  AND autodata.ndtime <= T.HourEnd)    
 OR ( autodata.msttime < T.HourStart  AND autodata.ndtime <= T.HourEnd AND autodata.ndtime >T.HourStart )    
 OR ( autodata.msttime >= T.HourStart AND autodata.msttime <T.HourEnd AND autodata.ndtime > T.HourEnd)    
 OR ( autodata.msttime < T.HourStart AND autodata.ndtime > T.HourEnd))'    
 select @strsql = @strsql + @strmachine + @strPlantID    
 select @strsql = @strsql + ' order by autodata.msttime'    
 print @strsql    
 exec (@strsql)    
End  
  
    
declare @mc_prev nvarchar(50),@comp_prev nvarchar(50),@opn_prev nvarchar(50), @From_Prev datetime    
declare @mc nvarchar(50),@comp nvarchar(50),@opn nvarchar(50),@Fromtime datetime,@id nvarchar(50)    
declare @batchid int    
Declare @autodataid bigint,@autodataid_prev bigint    
    
declare @setupcursor  cursor    
set @setupcursor=cursor for    
select autodataid,FromTm,MachineID,Component,Operation from #Target order by machineid,msttime    
open @setupcursor    
fetch next from @setupcursor into @autodataid,@Fromtime,@mc,@comp,@opn    
    
set @autodataid_prev=@autodataid    
set @mc_prev = @mc    
set @comp_prev = @comp    
set @opn_prev = @opn    
SET @From_Prev = @Fromtime    
set @batchid =1    
    
while @@fetch_status = 0    
begin    
If @mc_prev=@mc and @comp_prev=@comp and @opn_prev=@opn and @From_Prev = @Fromtime    
 begin      
  update #Target set batchid = @batchid where autodataid=@autodataid and MachineID=@mc and Component=@comp and Operation=@opn and FromTm=@Fromtime    
  print @batchid    
 end    
 else    
 begin     
    set @batchid = @batchid+1            
    update #Target set batchid = @batchid where autodataid=@autodataid and MachineID=@mc and Component=@comp and Operation=@opn and FromTm=@Fromtime    
    set @autodataid_prev=@autodataid     
    set @mc_prev=@mc      
    set @comp_prev=@comp    
    set @opn_prev=@opn     
    SET @From_Prev = @Fromtime    
 end     
 fetch next from @setupcursor into @autodataid,@Fromtime,@mc,@comp,@opn    
     
end    
close @setupcursor    
deallocate @setupcursor    
    
insert into #FinalTarget (MachineID,Component,operation,machineinterface,Compinterface,Opninterface,batchid,BatchStart,BatchEnd,FromTm,ToTm,Utilisedtime,Components,shift,Shiftid)     
Select MachineID,Component,operation,machineinterface,Compinterface,Opninterface,batchid,min(msttime),max(ndtime),FromTm,ToTm,0,0,shift,Shiftid from #Target     
group by MachineID,Component,operation,machineinterface,Compinterface,Opninterface,batchid,FromTm,ToTm,shift,Shiftid order by batchid     
    
  
    
  
--For Prodtime    
UPDATE #FinalTarget SET Utilisedtime = isnull(Utilisedtime,0) + isNull(t2.cycle,0)    
from    
(select S.MachineID,S.Component,S.operation,S.BatchStart,S.BatchEnd,    
 sum(case when ((autodata.msttime>=S.BatchStart) and (autodata.ndtime<=S.BatchEnd)) then  (autodata.cycletime+autodata.loadunload)    
   when ((autodata.msttime<S.BatchStart)and (autodata.ndtime>S.BatchStart)and (autodata.ndtime<=S.BatchEnd)) then DateDiff(second, S.BatchStart, autodata.ndtime)    
   when ((autodata.msttime>=S.BatchStart)and (autodata.msttime<S.BatchEnd)and (autodata.ndtime>S.BatchEnd)) then DateDiff(second, autodata.mstTime, S.BatchEnd)    
   when ((autodata.msttime<S.BatchStart)and (autodata.ndtime>S.BatchEnd)) then DateDiff(second, S.BatchStart, S.BatchEnd) END ) as cycle    
from #T_autodata autodata     
inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface  
where (autodata.datatype=1) AND(( (autodata.msttime>=S.BatchStart) and (autodata.ndtime<=S.BatchEnd))    
OR ((autodata.msttime<S.BatchStart)and (autodata.ndtime>S.BatchStart)and (autodata.ndtime<=S.BatchEnd))    
OR ((autodata.msttime>=S.BatchStart)and (autodata.msttime<S.BatchEnd)and (autodata.ndtime>S.BatchEnd))    
OR((autodata.msttime<S.BatchStart)and (autodata.ndtime>S.BatchEnd)))    
group by S.MachineID,S.Component,S.operation,S.BatchStart,S.BatchEnd    
) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and t2.operation = #FinalTarget.operation   
and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd    
    
    
--Type 2    
UPDATE  #FinalTarget SET Utilisedtime = isnull(Utilisedtime,0) - isNull(t2.Down,0)    
FROM    
(Select T1.mc,T1.comp,T1.opn,T1.BatchStart,T1.BatchEnd,    
SUM(    
CASE    
 When autodata.sttime <= T1.BatchStart Then datediff(s, T1.BatchStart,autodata.ndtime )    
 When autodata.sttime > T1.BatchStart Then datediff(s,autodata.sttime,autodata.ndtime)    
END) as Down    
From #T_autodata AutoData INNER Join    
 (Select AutoData.mc,AutoData.comp,AutoData.opn,AutoData.Sttime as sttime,AutoData.NdTime as ndtime,    
  ST1.BatchStart as BatchStart,ST1.BatchEnd as BatchEnd From #T_autodata AutoData    
  inner join #FinalTarget ST1 ON ST1.MachineInterface=Autodata.mc and ST1.CompInterface=Autodata.Comp and ST1.opnInterface=Autodata.opn  
  Where DataType=1 And DateDiff(Second,AutoData.sttime,AutoData.ndtime)>CycleTime And    
  (AutoData.msttime < ST1.BatchStart)And (AutoData.ndtime > ST1.BatchStart) AND (AutoData.ndtime <= ST1.BatchEnd)    
 ) as T1 on t1.mc=autodata.mc and t1.comp=autodata.comp and t1.opn=autodata.opn   
Where AutoData.DataType=2    
And ( autodata.Sttime > T1.Sttime )    
And ( autodata.ndtime <  T1.ndtime )    
AND ( autodata.ndtime >  T1.BatchStart )    
GROUP BY T1.mc,T1.comp,T1.opn,T1.BatchStart,T1.BatchEnd)AS T2 Inner Join #FinalTarget on t2.mc = #FinalTarget.machineinterface and    
t2.comp = #FinalTarget.compinterface and t2.opn = #FinalTarget.opninterface   
and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd    
    
    
    
--Type 3    
UPDATE  #FinalTarget SET Utilisedtime = isnull(Utilisedtime,0) - isNull(t2.Down,0)    
FROM    
(Select T1.mc,T1.comp,T1.opn,T1.BatchStart,T1.BatchEnd,    
SUM(CASE    
 When autodata.ndtime > T1.BatchEnd Then datediff(s,autodata.sttime, T1.BatchEnd )    
 When autodata.ndtime <= T1.BatchEnd Then datediff(s , autodata.sttime,autodata.ndtime)    
END) as Down    
From #T_autodata AutoData INNER Join    
 (Select AutoData.mc,AutoData.comp,AutoData.opn,AutoData.Sttime as sttime,AutoData.NdTime as ndtime,    
  ST1.BatchStart as BatchStart,ST1.BatchEnd as BatchEnd From #T_autodata AutoData    
  inner join #FinalTarget ST1 ON ST1.MachineInterface=Autodata.mc and ST1.CompInterface=Autodata.Comp and ST1.opnInterface=Autodata.opn   
  Where DataType=1 And DateDiff(Second,AutoData.sttime,AutoData.ndtime)>CycleTime And    
  (AutoData.sttime >= ST1.BatchStart)And (AutoData.ndtime > ST1.BatchEnd) and (AutoData.sttime< ST1.BatchEnd)    
   ) as T1    
ON t1.mc=autodata.mc and t1.comp=autodata.comp and t1.opn=autodata.opn  
Where AutoData.DataType=2    
And (T1.Sttime < autodata.sttime)    
And ( T1.ndtime > autodata.ndtime)    
AND (autodata.sttime  <  T1.BatchEnd)    
GROUP BY T1.mc,T1.comp,T1.opn,T1.BatchStart,T1.BatchEnd )AS T2 Inner Join #FinalTarget on t2.mc = #FinalTarget.machineinterface and    
t2.comp = #FinalTarget.compinterface and t2.opn = #FinalTarget.opninterface   
and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd    
    
    
--For Type4    
UPDATE  #FinalTarget SET Utilisedtime = isnull(Utilisedtime,0) - isNull(t2.Down,0)    
FROM    
(Select T1.mc,T1.comp,T1.opn,T1.BatchStart,T1.BatchEnd,    
SUM(CASE    
 When autodata.sttime >= T1.BatchStart AND autodata.ndtime <= T1.BatchEnd Then datediff(s , autodata.sttime,autodata.ndtime)    
 When autodata.sttime < T1.BatchStart And autodata.ndtime >T1.BatchStart AND autodata.ndtime<=T1.BatchEnd Then datediff(s, T1.BatchStart,autodata.ndtime )    
 When autodata.sttime >= T1.BatchStart AND autodata.sttime<T1.BatchEnd AND autodata.ndtime>T1.BatchEnd Then datediff(s,autodata.sttime, T1.BatchEnd )    
 When autodata.sttime<T1.BatchStart AND autodata.ndtime>T1.BatchEnd   Then datediff(s , T1.BatchStart,T1.BatchEnd)    
END) as Down    
From #T_autodata AutoData INNER Join    
 (Select AutoData.mc,AutoData.comp,AutoData.opn,AutoData.Sttime as sttime,AutoData.NdTime as ndtime,    
  ST1.BatchStart as BatchStart,ST1.BatchEnd as BatchEnd  From #T_autodata AutoData    
  inner join #FinalTarget ST1 ON ST1.MachineInterface=Autodata.mc and ST1.CompInterface=Autodata.Comp and  ST1.opnInterface=Autodata.opn   
  where DataType=1 And DateDiff(Second,AutoData.sttime,AutoData.ndtime)>CycleTime And     
  (AutoData.msttime <  ST1.BatchStart) And (AutoData.ndtime > ST1.BatchEnd)    
 ) as T1    
on t1.mc=autodata.mc and t1.comp=autodata.comp and t1.opn=autodata.opn  
Where AutoData.DataType=2    
And (T1.Sttime < autodata.sttime  )    
And ( T1.ndtime >  autodata.ndtime)    
AND (autodata.ndtime  >  T1.BatchStart)    
AND (autodata.sttime  <  T1.BatchEnd)    
GROUP BY T1.mc,T1.comp,T1.opn,T1.BatchStart,T1.BatchEnd    
 )AS T2 Inner Join #FinalTarget on t2.mc = #FinalTarget.machineinterface and    
t2.comp = #FinalTarget.compinterface and t2.opn = #FinalTarget.opninterface  
and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd    
    
      
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'    
BEGIN    
     
 --Get the utilised time overlapping with PDT and negate it from UtilisedTime    
  UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) - isNull(T2.PPDT ,0)    
  FROM(    
  SELECT F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,    
     SUM    
     (CASE    
     WHEN autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN DateDiff(second,autodata.msttime,autodata.ndtime) --DR0325 Added    
     WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)    
     WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )    
     WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )    
     END ) as PPDT    
     FROM #T_autodata AutoData    
     CROSS jOIN #PlannedDownTimesShift T    
     INNER JOIN #FinalTarget F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn  
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
      group  by F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface    
  )AS T2  Inner Join #FinalTarget on t2.machineinterface = #FinalTarget.machineinterface and    
  t2.compinterface = #FinalTarget.compinterface and t2.opninterface = #FinalTarget.opninterface    
  and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd    
    
 ---mod 12:Add ICD's Overlapping  with PDT to Prodtime    
 /* Fetching Down Records from Production Cycle  */    
  ---mod 12(4):Handle intearction between ICD and PDT for type 1 production record for the selected time period.    
  UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)    
  FROM(    
  Select T1.BatchStart,T1.BatchEnd,autodata.mc,autodata.comp,autodata.opn,  
  SUM(    
  CASE      
   When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1    
   When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2    
   When (autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3    
   when (autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4    
  END) as IPDT    
  from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join     
   (    
    Select autodata.mc,autodata.comp,autodata.opn,autodata.Sttime,autodata.NdTime,S.Batchstart,S.BatchEnd,S.FromTm     
     from #T_autodata autodata inner join #FinalTarget S on S.MachineInterface=Autodata.mc and S.CompInterface=Autodata.Comp and S.opnInterface=Autodata.opn   
    Where DataType=1 And DateDiff(Second, autodata.sttime, autodata.ndtime)>CycleTime And    
    ( autodata.msttime >= S.Batchstart) AND ( autodata.ndtime <= S.BatchEnd)    
   ) as T1    
  ON AutoData.mc=T1.mc and autodata.comp=T1.comp and Autodata.opn=T1.opn and T.ShiftSt=T1.FromTm     
  Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc    
  And (( autodata.Sttime > T1.Sttime )    
  And ( autodata.ndtime <  T1.ndtime ))    
  AND    
  ((T.StartTime >=T1.Sttime And T.EndTime <=T1.ndtime )    
  or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)    
  or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )    
  or ( T.StartTime <T1.Sttime And T.EndTime >T1.ndtime ))    
  GROUP BY T1.BatchStart,T1.BatchEnd,autodata.mc,autodata.comp,autodata.opn  
  )AS T2  Inner Join #FinalTarget on t2.mc = #FinalTarget.machineinterface and    
  t2.comp = #FinalTarget.compinterface and t2.opn = #FinalTarget.opninterface   
  and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd    
    
  ---mod 12(4)    
  /* If production  Records of TYPE-2*/    
  UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)    
  FROM    
  (Select T1.BatchStart,T1.BatchEnd,autodata.mc,autodata.comp,autodata.opn,   
  SUM(    
  CASE      
   When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1    
   When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2    
   When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3    
   when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4    
  END) as IPDT    
  from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join     
   (    
     Select autodata.mc,autodata.comp,autodata.opn,autodata.Sttime,autodata.NdTime,S.Batchstart,S.BatchEnd,S.FromTm     
     from #T_autodata autodata inner join #FinalTarget S on S.MachineInterface=Autodata.mc and S.CompInterface=Autodata.Comp and S.opnInterface=Autodata.opn   
     Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And    
     (msttime < S.Batchstart)And (ndtime > S.Batchstart) AND (ndtime <= S.BatchEnd)    
    ) as T1    
  ON AutoData.mc=T1.mc and autodata.comp=T1.comp and Autodata.opn=T1.opn and T.ShiftSt=T1.FromTm     
  Where AutoData.DataType=2  and T.MachineInterface=autodata.mc    
  And (( autodata.Sttime > T1.Sttime )    
  And ( autodata.ndtime <  T1.ndtime )    
  AND ( autodata.ndtime >  T1.Batchstart ))    
  AND    
  (( T.StartTime >= T1.Batchstart )    
  And ( T.StartTime <  T1.ndtime ) )    
  GROUP BY T1.BatchStart,T1.BatchEnd,autodata.mc,autodata.comp,autodata.opn)AS T2 Inner Join #FinalTarget on t2.mc = #FinalTarget.machineinterface and    
  t2.comp = #FinalTarget.compinterface and t2.opn = #FinalTarget.opninterface  
  and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd    
    
     
    
 /* If production Records of TYPE-3*/    
 UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)    
 FROM    
 (Select T1.BatchStart,T1.BatchEnd,autodata.mc,autodata.comp,autodata.opn,   
 SUM(    
 CASE      
  When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1    
  When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2    
  When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3    
  when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4    
 END) as IPDT    
 from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join    
  (    
   Select autodata.mc,autodata.comp,autodata.opn,autodata.Sttime,autodata.NdTime,S.Batchstart,S.BatchEnd,S.FromTm     
   from #T_autodata autodata inner join #FinalTarget S on S.MachineInterface=Autodata.mc and S.CompInterface=Autodata.Comp and    
   S.opnInterface=Autodata.opn  
   Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And    
   (sttime >= S.Batchstart And ndtime > S.BatchEnd and autodata.sttime <S.BatchEnd)     
  )as T1    
 ON AutoData.mc=T1.mc and autodata.comp=T1.comp and Autodata.opn=T1.opn and T.ShiftSt=T1.FromTm     
 Where AutoData.DataType=2  and T.MachineInterface=autodata.mc    
 And ((T1.Sttime < autodata.sttime  )    
 And ( T1.ndtime >  autodata.ndtime)    
 AND (autodata.sttime  <  T1.BatchEnd))    
 AND    
 (( T.EndTime > T1.Sttime )    
 And ( T.EndTime <=T1.BatchEnd ) )    
 GROUP BY T1.BatchStart,T1.BatchEnd,autodata.mc,autodata.comp,autodata.opn)AS T2 Inner Join #FinalTarget on t2.mc = #FinalTarget.machineinterface and    
 t2.comp = #FinalTarget.compinterface and t2.opn = #FinalTarget.opninterface   
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd    
    
     
 /* If production Records of TYPE-4*/    
 UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)    
 FROM    
 (Select T1.BatchStart,T1.BatchEnd,autodata.mc,autodata.comp,autodata.opn,    
 SUM(    
 CASE      
  When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1    
  When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2    
  When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3    
when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4    
 END) as IPDT    
 from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join     
  (    
   Select autodata.mc,autodata.comp,autodata.opn,autodata.Sttime,autodata.NdTime,S.Batchstart,S.BatchEnd,S.FromTm     
   from #T_autodata autodata inner join #FinalTarget S on S.MachineInterface=Autodata.mc and S.CompInterface=Autodata.Comp and S.opnInterface=Autodata.opn  
   Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And    
   (msttime < S.Batchstart)And (ndtime > S.BatchEnd)    
  ) as T1    
 ON AutoData.mc=T1.mc and autodata.comp=T1.comp and Autodata.opn=T1.opn and T.ShiftSt=T1.FromTm     
 Where AutoData.DataType=2 and T.MachineInterface=autodata.mc    
 And ( (T1.Sttime < autodata.sttime  )    
  And ( T1.ndtime >  autodata.ndtime)    
  AND (autodata.ndtime  >  T1.Batchstart)    
  AND (autodata.sttime  <  T1.BatchEnd))    
 AND    
 (( T.StartTime >=T1.Batchstart)    
 And ( T.EndTime <=T1.BatchEnd ) )    
 GROUP BY T1.BatchStart,T1.BatchEnd,autodata.mc,autodata.comp,autodata.opn)AS T2  Inner Join #FinalTarget on t2.mc = #FinalTarget.machineinterface and    
 t2.comp = #FinalTarget.compinterface and t2.opn = #FinalTarget.opninterface  
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd    
    
END    
    
   
   
--Calculation of PartsCount Begins..    
UPDATE #FinalTarget SET components = ISNULL(components,0) + ISNULL(t2.comp1,0)  
From    
(    
 Select T1.mc,T1.comp,T1.opn,T1.Batchstart,T1.Batchend,  
 SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp1  
     From (select mc,comp,opn,BatchStart,BatchEnd,SUM(autodata.partscount)AS OrginalCount from #T_autodata autodata    
     INNER JOIN #FinalTarget F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn   
     where (autodata.ndtime>F.BatchStart) and (autodata.ndtime<=F.BatchEnd) and (autodata.datatype=1)    
     Group By mc,comp,opn,BatchStart,BatchEnd) as T1    
 INNER JOIN #FinalTarget F on F.machineinterface=T1.mc and F.Compinterface=T1.comp and F.Opninterface = T1.opn  
 and F.Batchstart=T1.Batchstart and F.Batchend=T1.Batchend  
 Inner join componentinformation C on F.Compinterface = C.interfaceid    
 Inner join ComponentOperationPricing O ON  F.Opninterface = O.interfaceid and C.Componentid=O.componentid    
 inner join machineinformation on machineinformation.machineid =O.machineid    
 and F.machineinterface=machineinformation.interfaceid    
 GROUP BY T1.mc,T1.comp,T1.opn,T1.Batchstart,T1.Batchend    
) As T2 Inner Join #FinalTarget on T2.mc = #FinalTarget.machineinterface and    
T2.comp = #FinalTarget.compinterface and T2.opn = #FinalTarget.opninterface  
and T2.BatchStart=#FinalTarget.BatchStart and T2.BatchEnd=#FinalTarget.BatchEnd    
    
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'    
BEGIN    
      
 UPDATE #FinalTarget SET components=ISNULL(components,0)- isnull(t2.PlanCt,0)  
  FROM ( select autodata.mc,autodata.comp,autodata.opn,F.Batchstart,F.Batchend,  
  ((CAST(Sum(ISNULL(PartsCount,1)) AS Float)/ISNULL(CO.SubOperations,1))) as PlanCt  
   from #T_autodata autodata     
     INNER JOIN #FinalTarget F on F.machineinterface=autodata.mc and F.Compinterface=autodata.comp and F.Opninterface = autodata.opn   
  Inner jOIN #PlannedDownTimesShift T on T.MachineInterface=autodata.mc      
  inner join machineinformation M on autodata.mc=M.Interfaceid    
  Inner join componentinformation CI on autodata.comp=CI.interfaceid     
  inner join componentoperationpricing CO on autodata.opn=CO.interfaceid and    
  CI.componentid=CO.componentid  and CO.machineid=M.machineid    
  WHERE autodata.DataType=1 and    
  (autodata.ndtime>F.BatchStart) and (autodata.ndtime<=F.BatchEnd)     
  AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)    
   Group by autodata.mc,autodata.comp,autodata.opn,F.Batchstart,F.Batchend,CO.SubOperations     
 ) as T2 Inner Join #FinalTarget on T2.mc = #FinalTarget.machineinterface and    
 T2.comp = #FinalTarget.compinterface and T2.opn = #FinalTarget.opninterface  
 and T2.BatchStart=#FinalTarget.BatchStart and T2.BatchEnd=#FinalTarget.BatchEnd    
     
END    
  
Update #FinalTarget      
set #FinalTarget.MinEnergy = ISNULL(#FinalTarget.MinEnergy,0)+ISNULL(t1.kwh,0) from       
(      
select T.MachineiD,T.Component,T.BatchStart,T.BatchEnd,round(kwh,2) as kwh from       
(      
 select  F.MachineiD,F.Component,F.BatchStart,F.BatchEnd,min(gtime) as mingtime      
 from tcs_energyconsumption WITH(NOLOCK) inner join #FinalTarget F on       
 tcs_energyconsumption.machineID = F.MachineID and tcs_energyconsumption.gtime >= F.BatchStart and tcs_energyconsumption.gtime <= F.BatchEnd      
 where tcs_energyconsumption.kwh>0       
 group by  F.MachineiD,F.Component,F.BatchStart,F.BatchEnd  
)T  inner join tcs_energyconsumption on tcs_energyconsumption.gtime=T.mingtime       
AND tcs_energyconsumption.MachineID = T.MachineID --DR0359      
) as t1  inner join #FinalTarget on t1.machineiD = #FinalTarget.machineID and t1.Component = #FinalTarget.Component and t1.BatchStart = #FinalTarget.BatchStart and t1.BatchEnd = #FinalTarget.BatchEnd      
  
Update #FinalTarget      
set #FinalTarget.MinEnergy = ISNULL(#FinalTarget.MinEnergy,0)+ISNULL(t1.kwh,0) from       
(      
select T.MachineiD,T.Component,T.BatchStart,T.BatchEnd,round(kwh,2) as kwh from       
(      
 select  F.MachineiD,F.Component,F.BatchStart,F.BatchEnd,MAX(gtime) as MAXgtime      
 from tcs_energyconsumption WITH(NOLOCK) inner join #FinalTarget F on       
 tcs_energyconsumption.machineID = F.MachineID and tcs_energyconsumption.gtime >= F.BatchStart and tcs_energyconsumption.gtime <= F.BatchEnd      
 where tcs_energyconsumption.kwh>0       
 group by  F.MachineiD,F.Component,F.BatchStart,F.BatchEnd  
)T  inner join tcs_energyconsumption on tcs_energyconsumption.gtime=T.MAXgtime       
AND tcs_energyconsumption.MachineID = T.MachineID --DR0359      
) as t1  inner join #FinalTarget on t1.machineiD = #FinalTarget.machineID and t1.Component = #FinalTarget.Component and t1.BatchStart = #FinalTarget.BatchStart and t1.BatchEnd = #FinalTarget.BatchEnd      
  
  
Update #FinalTarget set #FinalTarget.Energy = ISNULL(#FinalTarget.Energy,0)+ISNULL(t1.kwh,0),  
#FinalTarget.Cost = ISNULL(#FinalTarget.Cost,0)+ISNULL(t1.kwh * (Select max(Valueintext) from shopdefaults where Parameter = 'CostPerKWH'),0)  
from       
(      
select F.MachineiD,F.Component,F.BatchStart,F.BatchEnd,round((MaxEnergy - MinEnergy),2) as kwh from #FinalTarget F       
) as t1 inner join #FinalTarget on  t1.machineiD = #FinalTarget.machineID and t1.Component = #FinalTarget.Component and t1.BatchStart = #FinalTarget.BatchStart and t1.BatchEnd = #FinalTarget.BatchEnd         
      
If @param='Shift'  
Begin  
 select Convert(nvarchar(10),FromTm,120) as PDate,Machineid,shift,Shiftid,Component,Operation,  
 dbo.f_formattime(sum(Utilisedtime),'hh:mm:ss') as ProductionTime,SUM(Components) as ProductionCount,  
 SUM(Energy) as Energy,SUM(Cost) as Cost from #FinalTarget    
where (Utilisedtime>0 or Components>0)   
Group by Machineid,fromtm,shift,Component,Operation,Shiftid  
Order by Machineid,FromTm  
End  
  
  
If @param='Hour'  
Begin  
 select Convert(nvarchar(10),FromTm,120) as PDate,Machineid,shift,Shiftid,fromtm as HourStart,ToTm as HourEnd,Component,Operation,  
 dbo.f_formattime(sum(Utilisedtime),'hh:mm:ss') as ProductionTime,SUM(Components) as ProductionCount,  
 SUM(Energy) as Energy,SUM(Cost) as Cost from #FinalTarget    
where (Utilisedtime>0 or Components>0)   
Group by Machineid,fromtm,shift,Component,Operation,ToTm,Shiftid  
Order by Machineid,FromTm  
End  
    
END    
  
