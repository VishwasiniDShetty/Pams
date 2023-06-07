/****** Object:  Procedure [dbo].[s_GetShiftAndon_BremboBrakes]    Committed by VersionSQL https://www.versionsql.com ******/

/************************************************************************************************************  
-- Author: Anjana C V/Swathi
-- Create date: 20 Feb 2019
-- Modified date: 20 Feb 2019
exec [dbo].[s_GetShiftAndon_BremboBrakes]  '2019-07-31 06:45:00','','','''AMS MILLING''','','1'
 ************************************************************************************************************/  
CREATE PROCEDURE [dbo].[s_GetShiftAndon_BremboBrakes]  
 @SDateTime datetime = '',  
 @Plant nvarchar(50) = '',
 @Group nvarchar(50) = '',
 @Machine nvarchar(4000) = '',
 @Shift nvarchar(50) = '',
 @PalletCount int

 WITH RECOMPILE  
 AS
 BEGIN

 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
 
Declare @strsql nvarchar(4000)  
Declare @strmachine nvarchar(4000)  
Declare @strPlantID nvarchar(50)  
Declare @strGroupID nvarchar(50)  
Declare @T_Start datetime
Declare @T_End datetime
Declare @ShiftMc int 
Declare @LastShiftMc int
Select @strmachine = ''  
select @strPlantID = ''  
select @strGroupID = ''  

if @SDateTime = ''
begin
select @SDateTime = getdate()
end

  CREATE TABLE #ShiftDetails   
   (  
	PDate datetime,  
	Shift nvarchar(20),  
	ShiftStart datetime,  
	ShiftEnd datetime,
	ShiftType nvarchar(50),
	ShiftID nvarchar(50)
   ) 
 
   CREATE TABLE #ShiftDetails1   
   (  
	PDate datetime,  
	Shift nvarchar(20),  
	ShiftStart datetime,  
	ShiftEnd datetime,
	ShiftType nvarchar(50),
	ShiftID nvarchar(50)
   ) 
     
declare @Prevday as datetime
Select @Prevday= dateadd(day,-1,@SDateTime)

   INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd , ShiftID)  
   EXEC  dbo.[s_GetCurrentShiftTime] @SDateTime
   
   UPDATE #ShiftDetails 
   SET ShiftType = 'CurrentShift'

   declare @CurrentShifttime as float
   Select @CurrentShifttime = datediff(second,ShiftStart,ShiftEnd) from #ShiftDetails where ShiftType='CurrentShift'

   INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd , ShiftType , ShiftID )  
   select Pdate, Shift, ShiftStart, @SDateTime , 'ShiftTillNow' , ShiftID from #ShiftDetails where ShiftType = 'CurrentShift'

   --INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)  
   --EXEC [dbo].[s_GetPreviousShiftTime] @SDateTime

	INSERT #ShiftDetails1(Pdate, Shift, ShiftStart, ShiftEnd)  
	EXEC dbo.[s_GetShiftTime] @SDateTime

	INSERT #ShiftDetails1(Pdate, Shift, ShiftStart, ShiftEnd)  
	EXEC dbo.[s_GetShiftTime] @Prevday

	INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)  
	select top 1 Pdate, Shift, ShiftStart, ShiftEnd from #ShiftDetails1 where Shiftend<@SDateTime order by ShiftStart desc

   UPDATE #ShiftDetails 
   SET ShiftType = 'LastShift'
   where isnull (ShiftType,'') = ''

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
PlantId nvarchar(50),   
GroupId nvarchar(50),  
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
ShiftType nvarchar(50),
PDate datetime
)  

CREATE TABLE #FinalTarget    
(   
	PlantId nvarchar(50),   
	GroupId nvarchar(50),  
	MachineID nvarchar(50) NOT NULL,
	machineinterface nvarchar(50),
	Compinterface nvarchar(50),
	OpnInterface nvarchar(50),
	Oprinterface nvarchar(50),
	Component nvarchar(50) NOT NULL,  
    Operation nvarchar(50) NOT NULL,  
    Operator nvarchar(50),  
	msttime datetime,
    ndtime datetime,
	FromTm datetime,
	ToTm datetime,   
    runtime int,   
    batchid int,
	BatchStart datetime,
	BatchEnd datetime,
	Target float Default 0,
	CumulativeActual float Default 0,
	autodataid bigint,
    Shift nvarchar(20),
	ShiftType nvarchar(50),
    PDate datetime
 )

 CREATE TABLE #ShiftData    
(   
	PlantId nvarchar(50),   
	GroupId nvarchar(50),  
	Machineid nvarchar(50),   
	PDate datetime,
	ShiftName nvarchar(20),
	ShiftID int,
	Shiftstart datetime,
	ShiftEnd datetime,
	ShiftType nvarchar(50),
	--FromTime datetime,
	--ToTime Datetime,
	Target float Default 0,
	CumulativeActual float Default 0,
	Efficiency float,
	LastShiftEfficiency float
)

 CREATE TABLE #ShiftFinal  
(   
	PlantId nvarchar(50),   
	GroupId nvarchar(50),   
	PDate datetime,
	ShiftName nvarchar(20),
	Shiftstart datetime,
	ShiftEnd datetime,
	ShiftTarget float Default 0,
	CumulativeTarget float Default 0,
	CumulativeActual float Default 0,
	Efficiency float,
	LastShiftTarget float Default 0,
	LastShiftActual float Default 0,
	LastShiftEfficiency float,
    RunningPart nvarchar(50)
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

--if isnull(@machine,'') <> ''  
--Begin  
-- Select @strmachine = ' and ( Machineinformation.MachineID = N''' + @machine + ''')'  
--End  

if isnull(@machine,'') <> ''  
Begin  
 Select @strmachine = ' and Machineinformation.MachineID in (' + @machine + ')' 
End  
  
if isnull(@Plant,'') <> ''  
Begin  
 Select @strPlantID = ' and ( PlantMachine.PlantID = N''' + @Plant + ''')'  
End 
  
if isnull(@Group,'') <> ''  
Begin  
 Select @strGroupID = ' and ( PlantMachineGroups.GroupID = N''' + @Group + ''')'  
End 

select @T_Start = min(ShiftStart) from #ShiftDetails
select @T_End =  max(ShiftEnd) from #ShiftDetails

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
select @strsql = 'insert INTO #PlannedDownTimesShift(StartTime,EndTime,Machine,MachineInterface,Downreason,Shiftst)'  
select @strsql = @strsql + 'select  
CASE When StartTime<T1.ShiftStart Then T1.ShiftStart Else StartTime End,  
case When EndTime>T1.ShiftEnd Then T1.ShiftEnd Else EndTime End,  
Machine,MachineInformation.InterfaceID,  
DownReason,T1.ShiftStart  
FROM PlannedDownTimes cross join #ShiftDetails T1  
inner join MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID  
inner Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid   
inner Join PlantMachineGroups ON PlantMachineGroups.MachineID=Machineinformation.machineid and PlantMachineGroups.PlantID = PlantMachine.PlantID
WHERE PDTstatus =1 and (  
(StartTime >= T1.ShiftStart  AND EndTime <=T1.ShiftEnd)  
OR ( StartTime < T1.ShiftStart  AND EndTime <= T1.ShiftEnd AND EndTime > T1.ShiftStart )  
OR ( StartTime >= T1.ShiftStart   AND StartTime <T1.ShiftEnd AND EndTime > T1.ShiftEnd )  
OR ( StartTime < T1.ShiftStart  AND EndTime > T1.ShiftEnd) )'  
select @strsql = @strsql + @strmachine + @strPlantID  + @strGroupID   
select @strsql = @strsql + 'ORDER BY StartTime'  
print @strsql  
exec (@strsql) 

Select @strsql=''   
Select @strsql= 'insert into #Target(PlantID,GroupId,MachineID,machineinterface,Component,Compinterface,Operation,Opninterface,  
Operator,Oprinterface,msttime,ndtime,FromTm,Totm,batchid,autodataid,stdtime,Shift,ShiftType,PDate)'  
select @strsql = @strsql + ' SELECT PlantMachine.PlantID ,PlantMachineGroups.GroupId , machineinformation.machineid, machineinformation.interfaceid,
componentinformation.componentid, componentinformation.interfaceid,  
componentoperationpricing.operationno, componentoperationpricing.interfaceid,EI.Employeeid,EI.interfaceid,  
Case when autodata.msttime< T.Shiftstart then T.Shiftstart else autodata.msttime end,   
Case when autodata.ndtime> T.ShiftEnd then T.ShiftEnd else autodata.ndtime end,  
T.shiftstart,T.Shiftend,0,autodata.id,componentoperationpricing.machiningtime,T.shift,T.ShiftType, T.PDate
 FROM #T_autodata  autodata  
INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID   
INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID    
INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID  
AND componentinformation.componentid = componentoperationpricing.componentid  
and componentoperationpricing.machineid=machineinformation.machineid   
inner Join Employeeinformation EI on EI.interfaceid=autodata.opr   
Left Outer Join downcodeinformation DI on DI.interfaceid=autodata.dcode  
inner  Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid   
inner  Join PlantMachineGroups ON PlantMachineGroups.MachineID=Machineinformation.machineid and PlantMachineGroups.PlantID = PlantMachine.PlantID
Cross join #ShiftDetails T  
WHERE ((autodata.msttime >= T.Shiftstart  AND autodata.ndtime <= T.ShiftEnd)  
OR ( autodata.msttime < T.Shiftstart  AND autodata.ndtime <= T.ShiftEnd AND autodata.ndtime >T.Shiftstart )  
OR ( autodata.msttime >= T.Shiftstart AND autodata.msttime <T.ShiftEnd AND autodata.ndtime > T.ShiftEnd)  
OR ( autodata.msttime < T.Shiftstart AND autodata.ndtime > T.ShiftEnd))'  
select @strsql = @strsql + @strmachine + @strPlantID  + @strGroupID
select @strsql = @strsql + ' order by autodata.msttime'  
print @strsql  
exec (@strsql)  

insert into #FinalTarget (PlantID,GroupId,MachineID,Component,operation,Operator,machineinterface,Compinterface,Opninterface,Oprinterface,runtime,
BatchStart,BatchEnd,
FromTm,ToTm,shift,ShiftType,PDate,batchid)
select PlantID,GroupId,MachineID,Component,operation,Operator,machineinterface,Compinterface,Opninterface,Oprinterface,datediff(s,min(msttime),max(ndtime)),min(msttime),max(ndtime),FromTm,ToTm,shift,ShiftType,PDate,batchid
from
(
select PlantID,GroupId,MachineID,Component,operation,Operator,machineinterface,Compinterface,Opninterface,Oprinterface,msttime,ndtime,FromTm,ToTm,stdtime,shift,ShiftType,PDate,
RANK() OVER (
  PARTITION BY t.machineid
  order by t.machineid, t.msttime
) -
RANK() OVER (
  PARTITION BY  t.PlantID,t.GroupId,t.machineid, t.component, t.operation, t.operator, t.fromtm  
  order by t.PlantID,t.GroupId,t.machineid, t.fromtm, t.msttime
) AS batchid
from #Target t 
) tt
group by PlantID,GroupId,MachineID,Component,operation,Operator,machineinterface,Compinterface,Opninterface,Oprinterface,batchid,FromTm,ToTm,stdtime,shift,ShiftType,PDate
order by tt.batchid

UPDATE #FinalTarget SET CumulativeActual = ISNULL(CumulativeActual,0) + ISNULL(t2.comp1,0)
From  
(  
 Select T1.mc,T1.comp,T1.opn,T1.opr,T1.Batchstart,T1.Batchend,
(CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1)) As Comp1
     From (select mc,comp,opn,opr,BatchStart,BatchEnd,SUM(autodata.partscount)AS OrginalCount from #T_autodata autodata  
	 INNER JOIN (SELECT DISTINCT  machineinterface,Compinterface,Opninterface,oprinterface,BatchStart,BatchEnd from #FinalTarget) F 
	 on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn and F.oprinterface=Autodata.opr  
     where (autodata.ndtime>F.BatchStart) and (autodata.ndtime<=F.BatchEnd) and (autodata.datatype=1)  
     Group By mc,comp,opn,opr,BatchStart,BatchEnd) as T1  
  INNER JOIN (SELECT  DISTINCT  machineinterface,Compinterface,Opninterface,oprinterface,BatchStart,BatchEnd from #FinalTarget) F 
  on F.machineinterface=T1.mc and F.Compinterface=T1.comp and F.Opninterface = T1.opn and F.oprinterface=T1.opr 
 and F.Batchstart=T1.Batchstart and F.Batchend=T1.Batchend
 Inner join componentinformation C on F.Compinterface = C.interfaceid  
 Inner join ComponentOperationPricing O ON  F.Opninterface = O.interfaceid and C.Componentid=O.componentid  
 inner join machineinformation on machineinformation.machineid =O.machineid 
 and F.machineinterface=machineinformation.interfaceid  
) As T2 Inner Join #FinalTarget on T2.mc = #FinalTarget.machineinterface and  
T2.comp = #FinalTarget.compinterface and T2.opn = #FinalTarget.opninterface and  T2.opr = #FinalTarget.oprinterface   
and T2.BatchStart=#FinalTarget.BatchStart and T2.BatchEnd=#FinalTarget.BatchEnd  
  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
BEGIN  
    
 UPDATE #FinalTarget SET CumulativeActual=ISNULL(CumulativeActual,0)- isnull(t2.PlanCt,0) 
  FROM ( select autodata.mc,autodata.comp,autodata.opn,autodata.opr,F.Batchstart,F.Batchend,
  ((CAST(Sum(ISNULL(PartsCount,1)) AS Float)/ISNULL(CO.SubOperations,1))) as PlanCt
   from #T_autodata autodata   
  INNER JOIN (SELECT DISTINCT  machineinterface,Compinterface,Opninterface,oprinterface,BatchStart,BatchEnd from #FinalTarget) F 
  on F.machineinterface=autodata.mc and F.Compinterface=autodata.comp and F.Opninterface = autodata.opn and F.oprinterface=autodata.opr  
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

--insert into #ShiftData( PlantID,GroupId,Machineid,ShiftName,PDate,Shiftstart,ShiftEnd,ShiftType,CumulativeActual)
--select distinct PlantID,GroupId,MachineID,Shift,PDate,FromTm,Totm,ShiftType,sum(CumulativeActual)
--FROM #FinalTarget
--GROUP by PlantID,GroupId,MachineID,Shift,PDate,FromTm,Totm,ShiftType

insert into #ShiftData( PlantID,GroupId,Machineid,ShiftName,PDate,Shiftstart,ShiftEnd,ShiftType,CumulativeActual)
select distinct P.PlantID,PMG.GroupId,M.MachineID,S.Shift,S.PDate,S.ShiftStart,S.ShiftEnd,S.ShiftType,sum(F.CumulativeActual)
FROM machineinformation M
inner Join PlantMachine P ON P.MachineID=M.machineid   
inner Join PlantMachineGroups PMG ON PMG.MachineID=M.machineid and PMG.PlantID = P.PlantID
cross join #ShiftDetails S
Left outer join #FinalTarget F on M.machineid=F.MachineID and S.ShiftStart=F.FromTm and S.ShiftType=F.ShiftType
GROUP by P.PlantID,PMG.GroupId,M.MachineID,S.Shift,S.PDate,S.ShiftStart,S.ShiftEnd,S.ShiftType


--Update #ShiftData set Target = Isnull(Target,0) + isnull(T1.targetcount,0) from 
--		(
--			Select T.PlantID,T.GroupId,T.Machineid,T.FromTm,T.ToTm,sum(((T.Runtime*CO.suboperations)/CO.cycletime)*isnull(CO.targetpercent,100) /100) as targetcount
--			from #FinalTarget T 
--			inner join machineinformation M on M.Interfaceid=T.machineinterface
--			inner join componentinformation C on C.interfaceid=T.Compinterface
--			inner join componentoperationpricing CO on M.machineid=co.machineid and c.componentid=Co.componentid
--			and Co.interfaceid=T.Opninterface
--			group by T.FromTm,T.ToTm,T.Machineid,T.PlantID,T.GroupId
--		)T1 inner join #ShiftData on #ShiftData.PlantID=T1.PlantID and #ShiftData.GroupId=T1.GroupId and #ShiftData.machineid=T1.machineid 
--		and #ShiftData.Shiftstart=T1.FromTm and  #ShiftData.ShiftEnd=T1.ToTm

Select machine,Date,shift,IdealCount INTO #LoadSchedule from(
Select distinct L.machine,L.Date,L.shift,L.IdealCount,row_number() over(partition by L.machine,L.shift order by L.id desc) as rn from LoadSchedule L
inner join #ShiftData S on L.Machine=S.Machineid and L.Shift=S.ShiftName 
where convert(nvarchar(10),L.date,120)<=convert(nvarchar(10),S.PDate,120)
)T where T.rn=1


Update #ShiftData set Target = Isnull(Target,0) + isnull(T1.IdealCount,0) from 
(
	select S.pdate,S.Machineid,S.ShiftName,L.IdealCount,S.Shiftstart,S.ShiftEnd
	from #LoadSchedule L inner join #ShiftData S on L.Machine=S.Machineid and L.Shift=S.ShiftName
)T1 inner join #ShiftData H on T1.Machineid=H.Machineid and T1.ShiftName=H.ShiftName 

Update #ShiftData set Target = ROUND((Isnull(Target,0)*datediff(second,Shiftstart,ShiftEnd))/ISNULL(@CurrentShifttime,0) ,0)
where ShiftType='ShiftTillNow' and @CurrentShifttime>0


--select  distinct @ShiftMc =  count(MachineID) from #ShiftData  where ShiftType = 'CurrentShift'
--select  distinct @LastShiftMc =  count(MachineID) from #ShiftData  where ShiftType = 'LastShift'

--insert into #ShiftFinal( PlantID,GroupId,ShiftName,PDate,Shiftstart,ShiftEnd,ShiftTarget,CumulativeTarget,CumulativeActual,Efficiency,LastShiftEfficiency)
--select PlantID,GroupId,ShiftName,PDate,Shiftstart,ShiftEnd,
----sum(Target)/@ShiftMc,0,0,0,0
--sum(Target)/isnull(COUNT(MachineID),1),0,0,0,0
--from #ShiftData where ShiftType = 'CurrentShift' group by PlantID,GroupId,ShiftName,PDate,Shiftstart,ShiftEnd

insert into #ShiftFinal( PlantID,GroupId,ShiftName,PDate,Shiftstart,ShiftEnd,ShiftTarget,CumulativeTarget,CumulativeActual,Efficiency,LastShiftEfficiency)
select PlantID,GroupId,ShiftName,PDate,Shiftstart,ShiftEnd,sum(Target),0,0,0,0
from #ShiftData where ShiftType = 'CurrentShift' group by PlantID,GroupId,ShiftName,PDate,Shiftstart,ShiftEnd

--Update #ShiftFinal 
--set CumulativeTarget = T1.CumulativeTarget
--from (
----select PlantID,GroupId,Shiftstart,sum(Target)/@ShiftMc as CumulativeTarget 
--select PlantID,GroupId,Shiftstart,sum(Target)/isnull(COUNT(MachineID),1) as CumulativeTarget 
--from #ShiftData where ShiftType = 'ShiftTillNow' group by PlantID,GroupId,Shiftstart
--) T1 inner join #ShiftFinal F on T1.PlantID = F.PlantID and T1.GroupId = F.GroupId and  T1.Shiftstart = F.Shiftstart 

Update #ShiftFinal 
set CumulativeTarget = T1.CumulativeTarget
from (
--select PlantID,GroupId,Shiftstart,sum(Target)/@ShiftMc as CumulativeTarget 
select PlantID,GroupId,Shiftstart,sum(Target) as CumulativeTarget 
from #ShiftData where ShiftType = 'ShiftTillNow' group by PlantID,GroupId,Shiftstart
) T1 inner join #ShiftFinal F on T1.PlantID = F.PlantID and T1.GroupId = F.GroupId and  T1.Shiftstart = F.Shiftstart 

--Update #ShiftFinal 
--set CumulativeActual = T1.CumulativeActual
--from (
----select PlantID,GroupId,Shiftstart,sum(CumulativeActual)/@ShiftMc as CumulativeActual
--select PlantID,GroupId,Shiftstart,sum(CumulativeActual)/isnull(COUNT(MachineID),1) as CumulativeActual
--from #ShiftData where ShiftType = 'ShiftTillNow' group by PlantID,GroupId,Shiftstart
--) T1 inner join #ShiftFinal F on T1.PlantID = F.PlantID and T1.GroupId = F.GroupId and  T1.Shiftstart = F.Shiftstart 

Update #ShiftFinal 
set CumulativeActual = T1.CumulativeActual
from (
--select PlantID,GroupId,Shiftstart,sum(CumulativeActual)/@ShiftMc as CumulativeActual
select PlantID,GroupId,Shiftstart,sum(CumulativeActual) as CumulativeActual
from #ShiftData where ShiftType = 'ShiftTillNow' group by PlantID,GroupId,Shiftstart
) T1 inner join #ShiftFinal F on T1.PlantID = F.PlantID and T1.GroupId = F.GroupId and  T1.Shiftstart = F.Shiftstart 


Update #ShiftFinal 
set Efficiency = (CumulativeActual / CumulativeTarget ) *100
where CumulativeTarget<>0


--Update #ShiftFinal 
--set LastShiftTarget = T1.LastShiftTarget
--from (
----select PlantID,GroupId,Shiftstart,sum(Target)/isnull(@LastShiftMc,1) as LastShiftTarget 
--select PlantID,GroupId,Shiftstart,sum(Target)/isnull(COUNT(MachineID),1) as LastShiftTarget 
--from #ShiftData where ShiftType = 'LastShift' group by PlantID,GroupId,Shiftstart
--) T1 inner join #ShiftFinal F on T1.PlantID = F.PlantID and T1.GroupId = F.GroupId 


Update #ShiftFinal 
set LastShiftTarget = T1.LastShiftTarget
from (
--select PlantID,GroupId,Shiftstart,sum(Target)/isnull(@LastShiftMc,1) as LastShiftTarget 
select PlantID,GroupId,Shiftstart,sum(Target) as LastShiftTarget 
from #ShiftData where ShiftType = 'LastShift' group by PlantID,GroupId,Shiftstart
) T1 inner join #ShiftFinal F on T1.PlantID = F.PlantID and T1.GroupId = F.GroupId 

--Update #ShiftFinal 
--set LastShiftActual = T1.LastShiftActual
--from (
----select PlantID,GroupId,Shiftstart,sum(CumulativeActual)/isnull(@LastShiftMc,1) as LastShiftActual
--select PlantID,GroupId,Shiftstart,sum(CumulativeActual)/isnull(COUNT(MachineID),1) as LastShiftActual
--from #ShiftData where ShiftType = 'LastShift' group by PlantID,GroupId,Shiftstart
--) T1 inner join #ShiftFinal F on T1.PlantID = F.PlantID and T1.GroupId = F.GroupId 



Update #ShiftFinal 
set LastShiftActual = T1.LastShiftActual
from (
--select PlantID,GroupId,Shiftstart,sum(CumulativeActual)/isnull(@LastShiftMc,1) as LastShiftActual
select PlantID,GroupId,Shiftstart,sum(CumulativeActual) as LastShiftActual
from #ShiftData where ShiftType = 'LastShift' group by PlantID,GroupId,Shiftstart
) T1 inner join #ShiftFinal F on T1.PlantID = F.PlantID and T1.GroupId = F.GroupId 

Update #ShiftFinal 
set LastShiftEfficiency = (LastShiftActual / LastShiftTarget ) *100
where LastShiftTarget<>0


--Update #ShiftFinal 
--set RunningPart = T1.RunningPart
--from 
--(
--select componentid as RunningPart, PlantMachine.PlantID , PlantMachineGroups.GroupID
--from  #T_autodata autodata  
--INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID   
--inner join componentinformation C on autodata.comp = C.InterfaceID
--inner  Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid   
--inner  Join PlantMachineGroups ON PlantMachineGroups.MachineID=Machineinformation.machineid 
--and PlantMachineGroups.PlantID = PlantMachine.PlantID
--inner join  
--( select max(autodata.sttime)as sttime, PlantMachine.PlantID , PlantMachineGroups.GroupID from #T_autodata autodata 
--INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID   
--inner  Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid   
--inner  Join PlantMachineGroups ON PlantMachineGroups.MachineID=Machineinformation.machineid 
--group by  PlantMachine.PlantID , PlantMachineGroups.GroupID
--) a on a.GroupID=PlantMachineGroups.GroupID and a.PlantID =PlantMachine.PlantID and a.sttime =autodata.sttime
--)T1 inner join #ShiftFinal F on T1.PlantID = F.PlantID and T1.GroupId = F.GroupId 

Select top 2 component into #Runningcomponent from 
(
select max(batchend) as batchend,Component from #FinalTarget where ShiftType='ShiftTillNow'
group by Component
)T order by batchend desc

Update #ShiftFinal set RunningPart = T1.component
from (SELECT STUFF((SELECT '/ ' + [component] FROM #Runningcomponent FOR XML PATH('')),1,1,'') as component)T1 

select PlantID,GroupId,ShiftName,PDate,Shiftstart,ShiftEnd,
ISNULL(round(ShiftTarget,2),0) as ShiftTarget,
ISNULL(round(CumulativeTarget,2),0) as CumulativeTarget,ISNULL(CumulativeActual,0) as CumulativeActual,
ISNULL(round(Efficiency,2),0) as Efficiency,ISNULL(round(LastShiftEfficiency,2),0) as LastShiftEfficiency, ISNULL(RunningPart,'') as RunningPart  from #ShiftFinal

END
