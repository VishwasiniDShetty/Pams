/****** Object:  Procedure [dbo].[S_Get_KKPillar_ProductionDown_Report]    Committed by VersionSQL https://www.versionsql.com ******/

/*
Created By : Raksha R
Created On: 09-Sep-2022
exec [dbo].[S_Get_KKPillar_ProductionDown_Report] '2022-09-01 07:00:00','2022-09-08 07:00:00','','',''
exec [dbo].[S_Get_KKPillar_ProductionDown_Report] '2022-09-06 07:00:00','2022-09-07 07:00:00','','','','PC VMC 409,PC VMC 410',''
exec [dbo].[S_Get_KKPillar_ProductionDown_Report] '2022-09-07 07:00:00','2022-09-08 07:00:00','','','','PC VMC 467',''

*/
CREATE procedure [dbo].[S_Get_KKPillar_ProductionDown_Report]
@StartDate datetime='',  
@EndDate datetime='', 
@ShiftName nvarchar(50)='',
@PlantID nvarchar(50)='',
@GroupID nvarchar(max)='',
@MachineID nvarchar(max) = '',  
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
 ShiftEnd datetime  ,
 ShiftID int
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
 id  bigint not null ,
 WorkOrderNumber nvarchar(50)
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
 id  bigint not null,
 WorkOrderNumber nvarchar(50)
)  
  
ALTER TABLE #T_autodataforDown  
  
ADD PRIMARY KEY CLUSTERED  
(  
 mc,sttime ASC  
)ON [PRIMARY]  
  
  
CREATE TABLE #Target    
(  
PlantID nvarchar(50),
GroupID nvarchar(50),
MachineID nvarchar(50) NOT NULL,  
machineinterface nvarchar(50),  
MachineDescription nvarchar(100),
Compinterface nvarchar(50),  
OpnInterface nvarchar(50),  
Component nvarchar(50) NOT NULL,  
Operation nvarchar(50) NOT NULL,  
Operator nvarchar(50),  
OprInterface nvarchar(50),  
WorkOrderNumber nvarchar(50),
AvgCycleTime float,
FromTm datetime,  
ToTm datetime,  
Ddate datetime,
msttime datetime,  
ndtime datetime,  
batchid int,  
autodataid bigint ,
stdTime float,
Shift nvarchar(20),
ShiftID int
)  
  
CREATE TABLE #FinalTarget    
( 
PlantID nvarchar(50),
GroupID nvarchar(50),
MachineID nvarchar(50) NOT NULL,  
machineinterface nvarchar(50),  
MachineDescription nvarchar(100),
Component nvarchar(50) NOT NULL,  
Compinterface nvarchar(50),  
Operation nvarchar(50) NOT NULL,  
OpnInterface nvarchar(50),  
Operator nvarchar(50),  
OprInterface nvarchar(50),  
WorkOrderNumber nvarchar(50),
FromTm datetime,  
ToTm datetime,    
Ddate datetime,
BatchStart datetime,  
BatchEnd datetime,  
batchid int,  
Utilisedtime float,  
Components float default 0,
PartCount float default 0,
RejCount float default 0,
Downtime float,  
ManagementLoss float,  
MLDown float,
stdTime float,
Avgcycletime float,
Shift nvarchar(20),
ShiftID int,
TotalAvailabletime float,
Others float,
CN float,
ProductionEfficiency float,
AvailabilityEfficiency float,
OverallEfficiency float,
A  float,
B  float,
C  float,
D  float,
E  float,
F  float,
G  float,
H  float,
I  float,
J  float,
K  float,
L  float,
M  float,
N  float,
O  float,
P  float, 
Q  float,  
R  float,  
S  float,  
T  float,  
U  float,  
V  float,  
W  float,  
X  float,  
Y  float,  
Z  float, 
AA  float,  
AB  float,  
AC  float,  
AD  float,  
AE  float,  
AF  float,  
AG  float,  
ActualAvailableTime Float,
DeviationInActAvlTime Float,
TargetCount Float,
ReworkHrs float
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

Create table #Downcode
(
	Slno int identity(1,1) NOT NULL,
	Downid nvarchar(50)
)

Insert into #Downcode(Downid)
Select top 33 downid from downcodeinformation where 
(SortOrder>0 and SortOrder<=33) and SortOrder IS NOT NULL order by sortorder

If @param = 'DownCodeList'
Begin
	select downid from #Downcode order by slno
	return
end 


  
Declare @strsql nvarchar(max)  
Declare @strmachine nvarchar(1000)  
Declare @StrTPMMachines AS nvarchar(1000)  
Declare @StrPlantid as nvarchar(1000)  
Declare @strGroupID nvarchar(2000)

Declare @timeformat as nvarchar(12)  
Declare @CurStrtTime as datetime  
Declare @CurEndTime as datetime  
Declare @T_Start AS Datetime   
Declare @T_End AS Datetime  
declare @StrMCJoined as nvarchar(max)
declare @StrGroupJoined as nvarchar(max)

Select @strsql = ''  
Select @StrTPMMachines = ''  
Select @strmachine = ''  
select @strPlantID = ''  
Select @strGroupID=''

IF ( SELECT TOP 1 ValueInText FROM  CockpitDefaults WHERE Parameter='TpmEnbMac')='E'  
BEGIN  
 SET  @StrTPMMachines = ' AND MachineInformation.TPMTrakEnabled = 1 '  
END  
ELSE  
BEGIN  
 SET  @StrTPMMachines = ' '  
END  
  
--if isnull(@machineid,'') <> ''  
--Begin  
-- Select @strmachine = ' and ( Machineinformation.MachineID = N''' + @MachineID + ''')'  
--End  

if isnull(@machineid,'')<> ''
begin
	select @StrMCJoined =  (case when (coalesce( +@StrMCJoined + ',''', '''')) = ''''  then 'N''' 
							else @StrMCJoined+',N''' end) +item+'''' from [SplitStrings](@MachineID, ',')

	if @StrMCJoined = 'N'''''  
	set @StrMCJoined = '' 
	select @MachineID = @StrMCJoined

	 select @strMachine =  ' and ( machineinformation.machineid in (' + @MachineID + '))' 
end

if isnull(@PlantID,'')<> ''  
Begin   
 SET @strPlantID = ' AND PlantMachine.PlantID = N''' + @PlantID + '''  '  
End  

if isnull(@GroupID,'')<> ''
Begin
	select @StrGroupJoined =  (case when (coalesce( +@StrGroupJoined + ',''', '''')) = ''''  then 'N''' else @StrGroupJoined+',N''' end) +item+'''' from [SplitStrings](@GroupID, ',')    
	if @StrGroupJoined = 'N'''''  
	set @StrGroupJoined = '' 
	select @GroupID = @StrGroupJoined

	SET @strGroupID = ' AND PlantMachineGroups.GroupID in (' + @GroupID +') '
End

Select @CurStrtTime=@StartDate  
Select @CurEndTime=@EndDate  
  
  
while @CurStrtTime<=@CurEndTime  
BEGIN  
 INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)  
 EXEC s_GetShiftTime @CurStrtTime,@ShiftName  
 SELECT @CurStrtTime=DATEADD(DAY,1,@CurStrtTime)  
END  
  
Update #ShiftDetails Set shiftid = isnull(T1.shiftid,0) from  
(Select SD.shiftid ,SD.shiftname from shiftdetails SD  
inner join #ShiftDetails S on SD.shiftname=S.Shift where  
running=1 )T1 inner join #ShiftDetails on  T1.shiftname=#ShiftDetails.Shift 

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
select @strsql = @strsql + @strmachine  + @StrTPMMachines 
select @strsql = @strsql + 'ORDER BY StartTime'  
print @strsql  
exec (@strsql)  
  
  
  
Select @strsql=''  
select @strsql ='insert into #T_autodata '  
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'  
 select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id,WorkOrderNumber'  
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
 select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id,WorkOrderNumber'  
select @strsql = @strsql + ' from #T_autodata autodata inner join Machineinformation on Machineinformation.interfaceid=Autodata.mc   
inner join Plantmachine on Plantmachine.machineid=Machineinformation.machineid  
where (datatype=1)  and (( sttime >='''+ convert(nvarchar(25),@T_Start,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_End,120)+''' ) OR '  
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_Start,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_End,120)+''' )OR '  
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_Start,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_Start,120)+'''  
     and ndtime<='''+convert(nvarchar(25),@T_End,120)+''' )'  
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_Start,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_End,120)+''' and sttime<'''+convert(nvarchar(25),@T_End,120)+''' ) )'  
select @strsql = @strsql + @strmachine + @StrTPMMachines + @strPlantID  
print @strsql  
exec (@strsql)  
  
Select @strsql=''  
select @strsql ='insert into #T_autodataforDown '  
select @strsql = @strsql + 'SELECT A1.mc, A1.comp, A1.opn, A1.opr, A1.dcode,A1.sttime,'  
 select @strsql = @strsql + 'A1.ndtime, A1.datatype, A1.cycletime, A1.loadunload, A1.msttime, A1.PartsCount,A1.id,A1.WorkOrderNumber'  
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
select @strsql = @strsql + @strmachine + @StrTPMMachines + @strPlantID  
select @strsql = @strsql + ' )'  
select @strsql = @strsql + @strmachine + @StrTPMMachines + @strPlantID  
print @strsql  
exec (@strsql)  
  
 

Select @strsql=''   
Select @strsql= 'insert into #Target(PlantID,GroupID,MachineID,machineinterface,MachineDescription,Component,Compinterface,Operation,Opninterface,  
Operator,Oprinterface,WorkOrderNumber,msttime,ndtime,Ddate,FromTm,Totm,batchid,autodataid,stdtime,Shift,shiftid)'  
select @strsql = @strsql + ' SELECT PlantMachine.PlantID,PlantMachineGroups.GroupID,machineinformation.machineid, machineinformation.interfaceid,machineinformation.description,
isnull(componentinformation.componentid,autodata.comp)  as componentid, autodata.comp as compInterfaceid,  
isnull(componentoperationpricing.operationno,autodata.opn) as operationno, autodata.opn as opnInterfaceid,
isnull(EI.Employeeid,autodata.opr) as Employeeid,autodata.opr as oprInterfaceid, 
isnull(autodata.WorkOrderNumber,''0'') as WorkOrderNumber,
Case when autodata.msttime< T.Shiftstart then T.Shiftstart else autodata.msttime end,   
Case when autodata.ndtime> T.ShiftEnd then T.ShiftEnd else autodata.ndtime end,
convert(nvarchar(10),T.Pdate,120),
T.shiftstart,T.Shiftend,0,autodata.id,componentoperationpricing.machiningtime,T.shift ,T.shiftid
FROM #T_autodataforDown  autodata  
INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID   
LEFT JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID    
LEFT JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID  
AND componentinformation.componentid = componentoperationpricing.componentid  
and componentoperationpricing.machineid=machineinformation.machineid   
left Join Employeeinformation EI on EI.interfaceid=autodata.opr   
Left Outer Join downcodeinformation DI on DI.interfaceid=autodata.dcode  
Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid  
LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID	
Cross join #ShiftDetails T  
WHERE ((autodata.msttime >= T.Shiftstart  AND autodata.ndtime <= T.ShiftEnd)  
OR ( autodata.msttime < T.Shiftstart  AND autodata.ndtime <= T.ShiftEnd AND autodata.ndtime >T.Shiftstart )  
OR ( autodata.msttime >= T.Shiftstart AND autodata.msttime <T.ShiftEnd AND autodata.ndtime > T.ShiftEnd)  
OR ( autodata.msttime < T.Shiftstart AND autodata.ndtime > T.ShiftEnd))'  
select @strsql = @strsql + @strmachine + @StrTPMMachines + @strGroupID  + @strPlantID  
--select @strsql = @strsql + @strmachine  + @strPlantID  
select @strsql = @strsql + ' order by autodata.msttime'  
print @strsql  
exec (@strsql)  


  insert into #FinalTarget (PlantID,GroupID,MachineID,MachineDescription,Component,operation,Operator,WorkOrderNumber,machineinterface,Compinterface,Opninterface,Oprinterface,Ddate,BatchStart,BatchEnd,FromTm,ToTm,Utilisedtime,Downtime,Components,ManagementLoss,MLDown,stdtime,shift,shiftid,TotalAvailabletime,batchid)
select PlantID,GroupID,MachineID,MachineDescription,Component,operation,Operator,WorkOrderNumber,machineinterface,Compinterface,Opninterface,Oprinterface,Ddate,min(msttime),max(ndtime),FromTm,ToTm,0 Utilisedtime,0 Downtime,0 Components,0 ManagementLoss,0 MLDown,stdtime,shift,shiftid,0 TotalAvailabletime,batchid
from
(
select PlantID,GroupID,MachineID,MachineDescription,Component,operation,Operator,WorkOrderNumber,machineinterface,Compinterface,Opninterface,Oprinterface,Ddate,msttime,ndtime,FromTm,ToTm,stdtime,shift,shiftid,
RANK() OVER (
  PARTITION BY t.machineid
  order by t.machineid, t.msttime
) -
RANK() OVER (
  PARTITION BY  t.machineid, t.component, t.operation, t.operator,t.WorkOrderNumber, t.fromtm --autodataid=@autodataid and MachineID=@mc and Component=@comp and Operation=@opn and Operator=@opr and FromTm=@Fromtime 
  order by t.machineid, t.fromtm, t.msttime
) AS batchid
from #Target t 
) tt
group by PlantID,GroupID,MachineID,MachineDescription,Component,operation,Operator,WorkOrderNumber,machineinterface,Compinterface,Opninterface,Oprinterface,batchid,FromTm,ToTm,stdtime,shift,shiftid ,Ddate
order by tt.batchid


--insert into #FinalTarget (MachineID,Component,operation,Operator,WorkOrderNumber,machineinterface,Compinterface,Opninterface,Oprinterface,Ddate,BatchStart,BatchEnd,FromTm,ToTm,Utilisedtime,Downtime,Components,ManagementLoss,MLDown,stdtime,shift,TotalAvailabletime,batchid)
--select MachineID,Component,operation,Operator,WorkOrderNumber,machineinterface,Compinterface,Opninterface,Oprinterface,Ddate,FromTm,ToTm,FromTm,ToTm,0 Utilisedtime,0 Downtime,0 Components,0 ManagementLoss,0 MLDown,stdtime,shift,0 TotalAvailabletime,batchid
--from #Target

--For Prodtime  
UPDATE #FinalTarget SET Utilisedtime = isnull(Utilisedtime,0) + isNull(t2.cycle,0)  
from  
(select S.MachineID,S.Component,S.operation,S.Operator,S.WorkOrderNumber,S.BatchStart,S.BatchEnd,  
 sum(case when ((autodata.msttime>=S.BatchStart) and (autodata.ndtime<=S.BatchEnd)) then  (autodata.cycletime+autodata.loadunload)  
   when ((autodata.msttime<S.BatchStart)and (autodata.ndtime>S.BatchStart)and (autodata.ndtime<=S.BatchEnd)) then DateDiff(second, S.BatchStart, autodata.ndtime)  
   when ((autodata.msttime>=S.BatchStart)and (autodata.msttime<S.BatchEnd)and (autodata.ndtime>S.BatchEnd)) then DateDiff(second, autodata.mstTime, S.BatchEnd)  
   when ((autodata.msttime<S.BatchStart)and (autodata.ndtime>S.BatchEnd)) then DateDiff(second, S.BatchStart, S.BatchEnd) END ) as cycle  
from #T_autodata autodata   
inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface and autodata.opr = S.Oprinterface  and autodata.WorkOrderNumber=S.WorkOrderNumber
where (autodata.datatype=1) AND(( (autodata.msttime>=S.BatchStart) and (autodata.ndtime<=S.BatchEnd))  
OR ((autodata.msttime<S.BatchStart)and (autodata.ndtime>S.BatchStart)and (autodata.ndtime<=S.BatchEnd))  
OR ((autodata.msttime>=S.BatchStart)and (autodata.msttime<S.BatchEnd)and (autodata.ndtime>S.BatchEnd))  
OR((autodata.msttime<S.BatchStart)and (autodata.ndtime>S.BatchEnd)))  
group by S.MachineID,S.Component,S.operation,S.Operator,S.WorkOrderNumber,S.BatchStart,S.BatchEnd  
) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and   
t2.operation = #FinalTarget.operation and t2.Operator = #FinalTarget.Operator  and t2.WorkOrderNumber=#FinalTarget.WorkOrderNumber
and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  
  


--Type 2  
UPDATE  #FinalTarget SET Utilisedtime = isnull(Utilisedtime,0) - isNull(t2.Down,0)  
FROM  
(Select T1.mc,T1.comp,T1.opn,T1.opr,T1.WorkOrderNumber,T1.BatchStart,T1.BatchEnd,  
SUM(  
CASE  
 When autodata.sttime <= T1.BatchStart Then datediff(s, T1.BatchStart,autodata.ndtime )  
 When autodata.sttime > T1.BatchStart Then datediff(s,autodata.sttime,autodata.ndtime)  
END) as Down  
From #T_autodata AutoData INNER Join  
 (Select AutoData.mc,AutoData.comp,AutoData.opn,AutoData.opr,autodata.WorkOrderNumber,AutoData.Sttime as sttime,AutoData.NdTime as ndtime,  
  ST1.BatchStart as BatchStart,ST1.BatchEnd as BatchEnd From #T_autodata AutoData  
  inner join #FinalTarget ST1 ON ST1.MachineInterface=Autodata.mc and ST1.CompInterface=Autodata.Comp and  
  ST1.opnInterface=Autodata.opn and Autodata.opr = ST1.Oprinterface  and autodata.WorkOrderNumber=ST1.WorkOrderNumber
  Where DataType=1 And DateDiff(Second,AutoData.sttime,AutoData.ndtime)>CycleTime And  
  (AutoData.msttime < ST1.BatchStart)And (AutoData.ndtime > ST1.BatchStart) AND (AutoData.ndtime <= ST1.BatchEnd)  
 ) as T1 on t1.mc=autodata.mc and t1.comp=autodata.comp and t1.opn=autodata.opn and T1.opr=Autodata.opr  and T1.WorkOrderNumber=AutoData.WorkOrderNumber
Where AutoData.DataType=2  
And ( autodata.Sttime > T1.Sttime )  
And ( autodata.ndtime <  T1.ndtime )  
AND ( autodata.ndtime >  T1.BatchStart )  
GROUP BY T1.mc,T1.comp,T1.opn,T1.opr,T1.WorkOrderNumber,T1.BatchStart,T1.BatchEnd)AS T2 Inner Join #FinalTarget on t2.mc = #FinalTarget.machineinterface and  
t2.comp = #FinalTarget.compinterface and t2.opn = #FinalTarget.opninterface and  t2.opr = #FinalTarget.oprinterface   and t2.WorkOrderNumber=#FinalTarget.WorkOrderNumber
and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  
  
  
  
--Type 3  
UPDATE  #FinalTarget SET Utilisedtime = isnull(Utilisedtime,0) - isNull(t2.Down,0)  
FROM  
(Select T1.mc,T1.comp,T1.opn,T1.opr,T1.WorkOrderNumber,T1.BatchStart,T1.BatchEnd,  
SUM(CASE  
 When autodata.ndtime > T1.BatchEnd Then datediff(s,autodata.sttime, T1.BatchEnd )  
 When autodata.ndtime <= T1.BatchEnd Then datediff(s , autodata.sttime,autodata.ndtime)  
END) as Down  
From #T_autodata AutoData INNER Join  
 (Select AutoData.mc,AutoData.comp,AutoData.opn,AutoData.opr,autodata.WorkOrderNumber,AutoData.Sttime as sttime,AutoData.NdTime as ndtime,  
  ST1.BatchStart as BatchStart,ST1.BatchEnd as BatchEnd From #T_autodata AutoData  
  inner join #FinalTarget ST1 ON ST1.MachineInterface=Autodata.mc and ST1.CompInterface=Autodata.Comp and  
  ST1.opnInterface=Autodata.opn and Autodata.opr = ST1.Oprinterface  and autodata.WorkOrderNumber=ST1.WorkOrderNumber
  Where DataType=1 And DateDiff(Second,AutoData.sttime,AutoData.ndtime)>CycleTime And  
  (AutoData.sttime >= ST1.BatchStart)And (AutoData.ndtime > ST1.BatchEnd) and (AutoData.sttime< ST1.BatchEnd)  
   ) as T1  
ON t1.mc=autodata.mc and t1.comp=autodata.comp and t1.opn=autodata.opn and T1.opr=Autodata.opr  and T1.WorkOrderNumber=autodata.WorkOrderNumber
Where AutoData.DataType=2  
And (T1.Sttime < autodata.sttime)  
And ( T1.ndtime > autodata.ndtime)  
AND (autodata.sttime  <  T1.BatchEnd)  
GROUP BY T1.mc,T1.comp,T1.opn,T1.opr,T1.WorkOrderNumber,T1.BatchStart,T1.BatchEnd )AS T2 Inner Join #FinalTarget on t2.mc = #FinalTarget.machineinterface and  
t2.comp = #FinalTarget.compinterface and t2.opn = #FinalTarget.opninterface and  t2.opr = #FinalTarget.oprinterface   and t2.WorkOrderNumber=#FinalTarget.WorkOrderNumber
and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  
  
  
--For Type4  
UPDATE  #FinalTarget SET Utilisedtime = isnull(Utilisedtime,0) - isNull(t2.Down,0)  
FROM  
(Select T1.mc,T1.comp,T1.opn,T1.opr,T1.WorkOrderNumber,T1.BatchStart,T1.BatchEnd,  
SUM(CASE  
 When autodata.sttime >= T1.BatchStart AND autodata.ndtime <= T1.BatchEnd Then datediff(s , autodata.sttime,autodata.ndtime)  
 When autodata.sttime < T1.BatchStart And autodata.ndtime >T1.BatchStart AND autodata.ndtime<=T1.BatchEnd Then datediff(s, T1.BatchStart,autodata.ndtime )  
 When autodata.sttime >= T1.BatchStart AND autodata.sttime<T1.BatchEnd AND autodata.ndtime>T1.BatchEnd Then datediff(s,autodata.sttime, T1.BatchEnd )  
 When autodata.sttime<T1.BatchStart AND autodata.ndtime>T1.BatchEnd   Then datediff(s , T1.BatchStart,T1.BatchEnd)  
END) as Down  
From #T_autodata AutoData INNER Join  
 (Select AutoData.mc,AutoData.comp,AutoData.opn,AutoData.opr,autodata.WorkOrderNumber,AutoData.Sttime as sttime,AutoData.NdTime as ndtime,  
  ST1.BatchStart as BatchStart,ST1.BatchEnd as BatchEnd  From #T_autodata AutoData  
  inner join #FinalTarget ST1 ON ST1.MachineInterface=Autodata.mc and ST1.CompInterface=Autodata.Comp and  
  ST1.opnInterface=Autodata.opn and Autodata.opr = ST1.Oprinterface  and autodata.WorkOrderNumber=ST1.WorkOrderNumber
  where DataType=1 And DateDiff(Second,AutoData.sttime,AutoData.ndtime)>CycleTime And   
  (AutoData.msttime <  ST1.BatchStart) And (AutoData.ndtime > ST1.BatchEnd)  
 ) as T1  
on t1.mc=autodata.mc and t1.comp=autodata.comp and t1.opn=autodata.opn and T1.opr=Autodata.opr   and T1.WorkOrderNumber=autodata.WorkOrderNumber
Where AutoData.DataType=2  
And (T1.Sttime < autodata.sttime  )  
And ( T1.ndtime >  autodata.ndtime)  
AND (autodata.ndtime  >  T1.BatchStart)  
AND (autodata.sttime  <  T1.BatchEnd)  
GROUP BY T1.mc,T1.comp,T1.opn,T1.opr,T1.WorkOrderNumber,T1.BatchStart,T1.BatchEnd  
 )AS T2 Inner Join #FinalTarget on t2.mc = #FinalTarget.machineinterface and  
t2.comp = #FinalTarget.compinterface and t2.opn = #FinalTarget.opninterface and  t2.opr = #FinalTarget.oprinterface   and T2.WorkOrderNumber=#FinalTarget.WorkOrderNumber
and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  
  
    
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'  
BEGIN  
   
 --Get the utilised time overlapping with PDT and negate it from UtilisedTime  
  UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) - isNull(T2.PPDT ,0)  
  FROM(  
  SELECT F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.oprinterface,  F.WorkOrderNumber,
     SUM  
     (CASE  
     WHEN autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN DateDiff(second,autodata.msttime,autodata.ndtime) --DR0325 Added  
     WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
     WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )  
     WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
     END ) as PPDT  
     FROM #T_autodata AutoData  
     CROSS jOIN #PlannedDownTimesShift T  
     INNER JOIN #FinalTarget F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn and F.oprinterface=Autodata.opr  and F.WorkOrderNumber=autodata.WorkOrderNumber
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
      group  by F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.oprinterface,f.WorkOrderNumber  
  )AS T2  Inner Join #FinalTarget on t2.machineinterface = #FinalTarget.machineinterface and  
  t2.compinterface = #FinalTarget.compinterface and t2.opninterface = #FinalTarget.opninterface and  t2.oprinterface = #FinalTarget.oprinterface  and t2.WorkOrderNumber=#FinalTarget.WorkOrderNumber 
  and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  
  
 ---mod 12:Add ICD's Overlapping  with PDT to Prodtime  
 /* Fetching Down Records from Production Cycle  */  
  ---mod 12(4):Handle intearction between ICD and PDT for type 1 production record for the selected time period.  
  UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)  
  FROM(  
  Select T1.BatchStart,T1.BatchEnd,autodata.mc,autodata.comp,autodata.opn,autodata.opr, autodata.WorkOrderNumber, 
  SUM(  
  CASE    
   When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1  
   When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2  
   When (autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3  
   when (autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4  
  END) as IPDT  
  from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join   
   (  
    Select autodata.mc,autodata.comp,autodata.opn,autodata.opr,autodata.WorkOrderNumber,autodata.Sttime,autodata.NdTime,S.Batchstart,S.BatchEnd,S.FromTm   
     from #T_autodata autodata inner join #FinalTarget S on S.MachineInterface=Autodata.mc and S.CompInterface=Autodata.Comp and  
    S.opnInterface=Autodata.opn and Autodata.opr = S.Oprinterface  and autodata.WorkOrderNumber=S.WorkOrderNumber
    Where DataType=1 And DateDiff(Second, autodata.sttime, autodata.ndtime)>CycleTime And  
    ( autodata.msttime >= S.Batchstart) AND ( autodata.ndtime <= S.BatchEnd)  
   ) as T1  
  ON AutoData.mc=T1.mc and autodata.comp=T1.comp and Autodata.opn=T1.opn and autodata.opr=T1.opr and autodata.WorkOrderNumber=T1.WorkOrderNumber and T.ShiftSt=T1.FromTm   
  Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc  
  And (( autodata.Sttime > T1.Sttime )  
  And ( autodata.ndtime <  T1.ndtime ))  
  AND  
  ((T.StartTime >=T1.Sttime And T.EndTime <=T1.ndtime )  
  or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)  
  or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )  
  or ( T.StartTime <T1.Sttime And T.EndTime >T1.ndtime ))  
  GROUP BY T1.BatchStart,T1.BatchEnd,autodata.mc,autodata.comp,autodata.opn,autodata.opr,autodata.WorkOrderNumber  
  )AS T2  Inner Join #FinalTarget on t2.mc = #FinalTarget.machineinterface and  
  t2.comp = #FinalTarget.compinterface and t2.opn = #FinalTarget.opninterface and  t2.opr = #FinalTarget.oprinterface   and t2.WorkOrderNumber=#FinalTarget.WorkOrderNumber
  and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  
  
  ---mod 12(4)  
  /* If production  Records of TYPE-2*/  
  UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)  
  FROM  
  (Select T1.BatchStart,T1.BatchEnd,autodata.mc,autodata.comp,autodata.opn,autodata.opr, autodata.WorkOrderNumber, 
  SUM(  
  CASE    
   When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1  
   When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2  
   When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3  
   when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4  
  END) as IPDT  
  from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join   
   (  
     Select autodata.mc,autodata.comp,autodata.opn,autodata.opr,autodata.WorkOrderNumber,autodata.Sttime,autodata.NdTime,S.Batchstart,S.BatchEnd,S.FromTm   
     from #T_autodata autodata inner join #FinalTarget S on S.MachineInterface=Autodata.mc and S.CompInterface=Autodata.Comp and  
     S.opnInterface=Autodata.opn and Autodata.opr = S.Oprinterface  and autodata.WorkOrderNumber=S.WorkOrderNumber
     Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And  
     (msttime < S.Batchstart)And (ndtime > S.Batchstart) AND (ndtime <= S.BatchEnd)  
    ) as T1  
  ON AutoData.mc=T1.mc and autodata.comp=T1.comp and Autodata.opn=T1.opn and autodata.opr=T1.opr and autodata.WorkOrderNumber=T1.WorkOrderNumber and T.ShiftSt=T1.FromTm   
  Where AutoData.DataType=2  and T.MachineInterface=autodata.mc  
  And (( autodata.Sttime > T1.Sttime )  
  And ( autodata.ndtime <  T1.ndtime )  
  AND ( autodata.ndtime >  T1.Batchstart ))  
  AND  
  (( T.StartTime >= T1.Batchstart )  
  And ( T.StartTime <  T1.ndtime ) )  
  GROUP BY T1.BatchStart,T1.BatchEnd,autodata.mc,autodata.comp,autodata.opn,autodata.opr,autodata.WorkOrderNumber )AS T2 Inner Join #FinalTarget on t2.mc = #FinalTarget.machineinterface and  
  t2.comp = #FinalTarget.compinterface and t2.opn = #FinalTarget.opninterface and  t2.opr = #FinalTarget.oprinterface   and t2.WorkOrderNumber=#FinalTarget.WorkOrderNumber
  and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  
  
   
  
 /* If production Records of TYPE-3*/  
 UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)  
 FROM  
 (Select T1.BatchStart,T1.BatchEnd,autodata.mc,autodata.comp,autodata.opn,autodata.opr,autodata.WorkOrderNumber,  
 SUM(  
 CASE    
  When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1  
  When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2  
  When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3  
  when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4  
 END) as IPDT  
 from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join  
  (  
   Select autodata.mc,autodata.comp,autodata.opn,autodata.opr,autodata.WorkOrderNumber,autodata.Sttime,autodata.NdTime,S.Batchstart,S.BatchEnd,S.FromTm   
   from #T_autodata autodata inner join #FinalTarget S on S.MachineInterface=Autodata.mc and S.CompInterface=Autodata.Comp and  
   S.opnInterface=Autodata.opn and Autodata.opr = S.Oprinterface  and autodata.WorkOrderNumber=S.WorkOrderNumber
   Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And  
   (sttime >= S.Batchstart And ndtime > S.BatchEnd and autodata.sttime <S.BatchEnd)   
  )as T1  
 ON AutoData.mc=T1.mc and autodata.comp=T1.comp and Autodata.opn=T1.opn and autodata.opr=T1.opr and autodata.WorkOrderNumber=T1.WorkOrderNumber and T.ShiftSt=T1.FromTm   
 Where AutoData.DataType=2  and T.MachineInterface=autodata.mc  
 And ((T1.Sttime < autodata.sttime  )  
 And ( T1.ndtime >  autodata.ndtime)  
 AND (autodata.sttime  <  T1.BatchEnd))  
 AND  
 (( T.EndTime > T1.Sttime )  
 And ( T.EndTime <=T1.BatchEnd ) )  
 GROUP BY T1.BatchStart,T1.BatchEnd,autodata.mc,autodata.comp,autodata.opn,autodata.opr,autodata.WorkOrderNumber)AS T2 Inner Join #FinalTarget on t2.mc = #FinalTarget.machineinterface and  
 t2.comp = #FinalTarget.compinterface and t2.opn = #FinalTarget.opninterface and  t2.opr = #FinalTarget.oprinterface and t2.WorkOrderNumber=#FinalTarget.WorkOrderNumber  
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  
  
   
 /* If production Records of TYPE-4*/  
 UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)  
 FROM  
 (Select T1.BatchStart,T1.BatchEnd,autodata.mc,autodata.comp,autodata.opn,autodata.opr, autodata.WorkOrderNumber ,
 SUM(  
 CASE    
  When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1  
  When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2  
  When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3  
  when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4  
 END) as IPDT  
 from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join   
  (  
   Select autodata.mc,autodata.comp,autodata.opn,autodata.opr,autodata.WorkOrderNumber,autodata.Sttime,autodata.NdTime,S.Batchstart,S.BatchEnd,S.FromTm   
   from #T_autodata autodata inner join #FinalTarget S on S.MachineInterface=Autodata.mc and S.CompInterface=Autodata.Comp and  
   S.opnInterface=Autodata.opn and Autodata.opr = S.Oprinterface  and autodata.WorkOrderNumber=S.WorkOrderNumber
   Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And  
   (msttime < S.Batchstart)And (ndtime > S.BatchEnd)  
  ) as T1  
 ON AutoData.mc=T1.mc and autodata.comp=T1.comp and Autodata.opn=T1.opn and autodata.opr=T1.opr and autodata.WorkOrderNumber=T1.WorkOrderNumber and T.ShiftSt=T1.FromTm   
 Where AutoData.DataType=2 and T.MachineInterface=autodata.mc  
 And ( (T1.Sttime < autodata.sttime  )  
  And ( T1.ndtime >  autodata.ndtime)  
  AND (autodata.ndtime  >  T1.Batchstart)  
  AND (autodata.sttime  <  T1.BatchEnd))  
 AND  
 (( T.StartTime >=T1.Batchstart)  
 And ( T.EndTime <=T1.BatchEnd ) )  
 GROUP BY T1.BatchStart,T1.BatchEnd,autodata.mc,autodata.comp,autodata.opn,autodata.opr,autodata.WorkOrderNumber)AS T2  Inner Join #FinalTarget on t2.mc = #FinalTarget.machineinterface and  
 t2.comp = #FinalTarget.compinterface and t2.opn = #FinalTarget.opninterface and  t2.opr = #FinalTarget.oprinterface   and t2.WorkOrderNumber=#FinalTarget.WorkOrderNumber
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  
  
END  
  
  
  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' 
or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' 
and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y')  
BEGIN  
  
 --Type 1  
 UPDATE #FinalTarget SET downtime = isnull(downtime,0) + isNull(t2.down,0)  
 from  
 (select S.MachineID,S.Component,S.operation,S.Operator,S.WorkOrderNumber,S.BatchStart,S.BatchEnd,  
 sum(loadunload) as down  
 from #T_autodata autodata   
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface and autodata.opr = S.Oprinterface  
 and S.WorkOrderNumber=autodata.WorkOrderNumber
 where (autodata.msttime>=S.BatchStart)  
 and (autodata.ndtime<= S.BatchEnd)  
 and (autodata.datatype=2)  
 group by S.MachineID,S.Component,S.operation,S.Operator,S.WorkOrderNumber,S.BatchStart,S.BatchEnd  
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and   
 t2.operation = #FinalTarget.operation and t2.Operator = #FinalTarget.Operator  and t2.WorkOrderNumber=#FinalTarget.WorkOrderNumber
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  
   
 -- Type 2  
 UPDATE #FinalTarget SET downtime = isnull(downtime,0) + isNull(t2.down,0)  
 from  
 (select S.MachineID,S.Component,S.operation,S.Operator,S.WorkOrderNumber,S.BatchStart,S.BatchEnd,  
 sum(DateDiff(second, S.BatchStart, ndtime)) down  
 from #T_autodata autodata   
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface and autodata.opr = S.Oprinterface  
 and S.WorkOrderNumber=autodata.WorkOrderNumber
 where (autodata.sttime<S.BatchStart)  
 and (autodata.ndtime>S.BatchStart)  
 and (autodata.ndtime<= S.BatchEnd)  
 and (autodata.datatype=2)  
 group by S.MachineID,S.Component,S.operation,S.Operator,S.WorkOrderNumber,S.BatchStart,S.BatchEnd  
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and   
 t2.operation = #FinalTarget.operation and t2.Operator = #FinalTarget.Operator  and t2.WorkOrderNumber=#FinalTarget.WorkOrderNumber
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  
   
 -- Type 3  
 UPDATE #FinalTarget SET downtime = isnull(downtime,0) + isNull(t2.down,0)  
 from  
 (select S.MachineID,S.Component,S.operation,S.Operator,S.WorkOrderNumber,S.BatchStart,S.BatchEnd,  
 sum(DateDiff(second, stTime,  S.BatchEnd)) down  
 from #T_autodata autodata  
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface and autodata.opr = S.Oprinterface 
 and S.WorkOrderNumber=autodata.WorkOrderNumber
 where (autodata.msttime>=S.BatchStart)  
 and (autodata.sttime< S.BatchEnd)  
 and (autodata.ndtime> S.BatchEnd)  
 and (autodata.datatype=2)group by S.MachineID,S.Component,S.operation,S.Operator,S.WorkOrderNumber,S.BatchStart,S.BatchEnd  
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and   
 t2.operation = #FinalTarget.operation and t2.Operator = #FinalTarget.Operator  and t2.WorkOrderNumber=#FinalTarget.WorkOrderNumber
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  
   
   
 -- Type 4  
 UPDATE #FinalTarget SET downtime = isnull(downtime,0) + isNull(t2.down,0)  
 from  
 (select S.MachineID,S.Component,S.operation,S.Operator,S.WorkOrderNumber,S.BatchStart,S.BatchEnd,  
 sum(DateDiff(second, S.BatchStart,  S.BatchEnd)) down  
 from #T_autodata autodata   
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface and autodata.opr = S.Oprinterface  
 and S.WorkOrderNumber=autodata.WorkOrderNumber
 where autodata.msttime<S.BatchStart  
 and autodata.ndtime> S.BatchEnd  
 and (autodata.datatype=2)group by S.MachineID,S.Component,S.operation,S.Operator,S.WorkOrderNumber,S.BatchStart,S.BatchEnd  
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and   
 t2.operation = #FinalTarget.operation and t2.Operator = #FinalTarget.Operator and t2.WorkOrderNumber=#FinalTarget.WorkOrderNumber 
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  
   
  
 ---Management Loss-----  
 -- Type 1  
 UPDATE #FinalTarget SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)  
 from  
 (select S.MachineID,S.Component,S.operation,S.Operator,S.WorkOrderNumber,S.BatchStart,S.BatchEnd,  
 sum(CASE  
 WHEN loadunload >ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)  
 ELSE loadunload  
 END) loss  
 from #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid   
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface and autodata.opr = S.Oprinterface  
 and S.WorkOrderNumber=autodata.WorkOrderNumber
 where (autodata.msttime>=S.BatchStart)  
 and (autodata.ndtime<=S.BatchEnd)  
 and (autodata.datatype=2)  
 and (downcodeinformation.availeffy = 1)  
    and (downcodeinformation.ThresholdfromCO <>1) --NR0097  
 group by  S.MachineID,S.Component,S.operation,S.Operator,S.WorkOrderNumber,S.BatchStart,S.BatchEnd  
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and   
 t2.operation = #FinalTarget.operation and t2.Operator = #FinalTarget.Operator  and t2.WorkOrderNumber=#FinalTarget.WorkOrderNumber
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  
  
 -- Type 2  
 UPDATE #FinalTarget SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)  
 from  
 (select S.MachineID,S.Component,S.operation,S.Operator,S.WorkOrderNumber,S.BatchStart,S.BatchEnd,  
  sum(CASE  
 WHEN DateDiff(second, S.BatchStart, ndtime)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)  
 ELSE DateDiff(second, S.BatchStart, ndtime)  
 end) loss  
 from #T_autodata autodata   
  INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid   
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface and autodata.opr = S.Oprinterface  
 and S.WorkOrderNumber=autodata.WorkOrderNumber
 where (autodata.sttime<S.BatchStart)  
 and (autodata.ndtime>S.BatchStart)  
 and (autodata.ndtime<=S.BatchEnd)  
 and (autodata.datatype=2)  
 and (downcodeinformation.availeffy = 1)  
 and (downcodeinformation.ThresholdfromCO <>1) --NR0097  
 group by S.MachineID,S.Component,S.operation,S.Operator,S.WorkOrderNumber,S.BatchStart,S.BatchEnd  
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and   
 t2.operation = #FinalTarget.operation and t2.Operator = #FinalTarget.Operator and t2.WorkOrderNumber=#FinalTarget.WorkOrderNumber  
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  
  
 -- Type 3  
 UPDATE #FinalTarget SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)  
 from  
 (select S.MachineID,S.Component,S.operation,S.Operator,S.WorkOrderNumber,S.BatchStart,S.BatchEnd,  
 sum(CASE  
 WHEN DateDiff(second, stTime, S.BatchEnd)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)  
 ELSE DateDiff(second, stTime, S.BatchEnd)  
 END) loss  
 from #T_autodata autodata    
 INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid   
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface and autodata.opr = S.Oprinterface  
 and S.WorkOrderNumber=autodata.WorkOrderNumber
 where (autodata.msttime>=S.BatchStart)  
 and (autodata.sttime<S.BatchEnd)  
 and (autodata.ndtime>S.BatchEnd)  
 and (autodata.datatype=2)  
 and (downcodeinformation.availeffy = 1)  
 and (downcodeinformation.ThresholdfromCO <>1) --NR0097  
 group by S.MachineID,S.Component,S.operation,S.Operator,S.WorkOrderNumber,S.BatchStart,S.BatchEnd  
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and   
 t2.operation = #FinalTarget.operation and t2.Operator = #FinalTarget.Operator  and t2.WorkOrderNumber=#FinalTarget.WorkOrderNumber
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  
  
 -- Type 4  
 UPDATE #FinalTarget SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)  
 from  
 (select S.MachineID,S.Component,S.operation,S.Operator,S.WorkOrderNumber,S.BatchStart,S.BatchEnd,  
 sum(CASE  
 WHEN DateDiff(second, S.BatchStart, S.BatchEnd)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)  
 ELSE DateDiff(second, S.BatchStart, S.BatchEnd)  
 END) loss  
 from #T_autodata autodata   
 INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid   
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface and autodata.opr = S.Oprinterface  
 and S.WorkOrderNumber=autodata.WorkOrderNumber
 where autodata.msttime<S.BatchStart  
 and autodata.ndtime>S.BatchEnd  
 and (autodata.datatype=2)  
 and (downcodeinformation.availeffy = 1)  
 and (downcodeinformation.ThresholdfromCO <>1) --NR0097  
 group by S.MachineID,S.Component,S.operation,S.Operator,S.WorkOrderNumber,S.BatchStart,S.BatchEnd  
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and   
 t2.operation = #FinalTarget.operation and t2.Operator = #FinalTarget.Operator  and t2.WorkOrderNumber=#FinalTarget.WorkOrderNumber
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  
END  
  


  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
BEGIN  
  
 ---Get the down times which are not of type Management Loss  
 UPDATE #FinalTarget SET downtime = isnull(downtime,0) + isNull(t2.down,0)  
 from  
 (select  F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.oprinterface,  F.WorkOrderNumber,
  sum (CASE  
    WHEN (autodata.msttime >= F.BatchStart  AND autodata.ndtime <=F.BatchEnd)  THEN autodata.loadunload  
    WHEN ( autodata.msttime < F.BatchStart  AND autodata.ndtime <= F.BatchEnd  AND autodata.ndtime > F.BatchStart ) THEN DateDiff(second,F.BatchStart,autodata.ndtime)  
    WHEN ( autodata.msttime >= F.BatchStart   AND autodata.msttime <F.BatchEnd  AND autodata.ndtime > F.BatchEnd  ) THEN DateDiff(second,autodata.msttime,F.BatchEnd )  
    WHEN ( autodata.msttime < F.BatchStart  AND autodata.ndtime > F.BatchEnd ) THEN DateDiff(second,F.BatchStart,F.BatchEnd )  
    END ) as down  
    from #T_autodata autodata   
    inner join #FinalTarget F on autodata.mc = F.Machineinterface and autodata.comp=F.Compinterface and autodata.opn=F.Opninterface and autodata.opr = F.Oprinterface  
	and F.WorkOrderNumber=autodata.WorkOrderNumber
    inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid  
  where (autodata.datatype=2) AND  
    (( (autodata.msttime>=F.BatchStart) and (autodata.ndtime<=F.BatchEnd))  
       OR ((autodata.msttime<F.BatchStart)and (autodata.ndtime>F.BatchStart)and (autodata.ndtime<=F.BatchEnd))  
       OR ((autodata.msttime>=F.BatchStart)and (autodata.msttime<F.BatchEnd)and (autodata.ndtime>F.BatchEnd))  
       OR((autodata.msttime<F.BatchStart)and (autodata.ndtime>F.BatchEnd)))   
    AND (downcodeinformation.availeffy = 0)  
       group by F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.oprinterface ,F.WorkOrderNumber 
 ) as t2 Inner Join #FinalTarget on t2.machineinterface = #FinalTarget.machineinterface and  
 t2.compinterface = #FinalTarget.compinterface and t2.opninterface = #FinalTarget.opninterface and  t2.oprinterface = #FinalTarget.oprinterface  and t2.WorkOrderNumber=#FinalTarget.WorkOrderNumber 
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  
  
  
 UPDATE  #FinalTarget SET Downtime = isnull(Downtime,0) - isNull(T2.PPDT ,0)  
 FROM(  
 SELECT F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.oprinterface,F.WorkOrderNumber,  
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
	and F.WorkOrderNumber=autodata.WorkOrderNumber
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
     group  by F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.oprinterface ,F.WorkOrderNumber 
 )AS T2  Inner Join #FinalTarget on t2.machineinterface = #FinalTarget.machineinterface and  
 t2.compinterface = #FinalTarget.compinterface and t2.opninterface = #FinalTarget.opninterface and  t2.oprinterface = #FinalTarget.oprinterface and t2.WorkOrderNumber=#FinalTarget.WorkOrderNumber  
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  
  
 UPDATE #FinalTarget SET ManagementLoss = isnull(ManagementLoss,0)+ isNull(t4.Mloss,0),MLDown=isNull(MLDown,0)+isNull(t4.Dloss,0)  
 from  
 (select T3.mc,T3.comp,T3.opn,T3.opr,t3.WorkOrderNumber,T3.Batchstart as Batchstart,T3.Batchend as Batchend,sum(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss from  
  (  
 select   T1.id,T1.mc,T1.comp,T1.opn,T1.opr,T1.WorkOrderNumber,T1.Threshold,T1.Batchstart as Batchstart,T1.Batchend as Batchend,  
 case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0) > 0  
 then DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)- isnull(T1.Threshold ,0)  
 else 0 End  as Dloss,  
 case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0) > 0  
 then isnull(T1.Threshold,0)  
 else DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0) End  as Mloss  
  from  
   
  (     
   select id,mc,comp,opn,opr,autodata.WorkOrderNumber,D.threshold,S.Batchstart as Batchstart,S.BatchEnd as BatchEnd,  
   case when autodata.sttime<S.Batchstart then S.Batchstart else sttime END as sttime,  
   case when ndtime>S.BatchEnd then S.BatchEnd else ndtime END as ndtime  
   from #T_autodata autodata   
   inner join downcodeinformation D on autodata.dcode=D.interfaceid   
   INNER JOIN #FinalTarget S on S.machineinterface=Autodata.mc and S.Compinterface=Autodata.comp and S.Opninterface = Autodata.opn and S.oprinterface=Autodata.opr  
   and autodata.WorkOrderNumber=S.WorkOrderNumber
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
   SELECT id,F.BatchStart,F.BatchEnd,mc,comp,opr,opn,autodata.WorkOrderNumber,  
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
   and F.WorkOrderNumber=autodata.WorkOrderNumber
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
    group  by id,F.BatchStart,F.BatchEnd,mc,comp,opr,opn,autodata.WorkOrderNumber  
  ) as T2 on T1.id=T2.id and T1.mc=T2.mc and T1.comp=T2.comp and T1.opn=T2.opn and T1.opr=T2.opr and t1.WorkOrderNumber=t2.WorkOrderNumber 
  and T1.Batchstart=T2.Batchstart and T1.Batchend=T2.Batchend ) as T3  group by T3.mc,T3.comp,T3.opn,T3.opr,t3.WorkOrderNumber,T3.Batchstart,T3.Batchend  
 ) as t4 Inner Join #FinalTarget on t4.mc = #FinalTarget.machineinterface and  
 t4.comp = #FinalTarget.compinterface and t4.opn = #FinalTarget.opninterface and  t4.opr = #FinalTarget.oprinterface  and t4.WorkOrderNumber=#FinalTarget.WorkOrderNumber 
 and t4.BatchStart=#FinalTarget.BatchStart and t4.BatchEnd=#FinalTarget.BatchEnd  
  
 UPDATE #FinalTarget  set downtime = isnull(downtime,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)  
END  
  
--Calculation of PartsCount Begins..  
UPDATE #FinalTarget SET components = ISNULL(components,0) + ISNULL(t2.comp1,0),CN = isnull(CN,0) + isNull(t2.C1N1,0)  
From  
(  
 Select T1.mc,T1.comp,T1.opn,T1.opr,T1.WorkOrderNumber,T1.Batchstart,T1.Batchend,
 SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp1,
SUM((O.cycletime/ISNULL(O.SubOperations,1))* T1.OrginalCount) C1N1
     From (select mc,comp,opn,opr,autodata.WorkOrderNumber,BatchStart,BatchEnd,SUM(autodata.partscount)AS OrginalCount from #T_autodata autodata  
     INNER JOIN #FinalTarget F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn and F.oprinterface=Autodata.opr  
	 and autodata.WorkOrderNumber=F.WorkOrderNumber
     where (autodata.ndtime>F.BatchStart) and (autodata.ndtime<=F.BatchEnd) and (autodata.datatype=1)  
     Group By mc,comp,opn,opr,autodata.WorkOrderNumber,BatchStart,BatchEnd) as T1  
 INNER JOIN #FinalTarget F on F.machineinterface=T1.mc and F.Compinterface=T1.comp and F.Opninterface = T1.opn 
 and F.oprinterface=T1.opr and F.WorkOrderNumber=T1.WorkOrderNumber  
 and F.Batchstart=T1.Batchstart and F.Batchend=T1.Batchend
 inner join machineinformation on F.machineinterface=machineinformation.interfaceid 
 left join componentinformation C on F.Compinterface = C.interfaceid  
 left join ComponentOperationPricing O ON  F.Opninterface = O.interfaceid and C.Componentid=O.componentid  
 and machineinformation.machineid =O.machineid  
 GROUP BY T1.mc,T1.comp,T1.opn,T1.opr,T1.WorkOrderNumber,T1.Batchstart,T1.Batchend  
) As T2 Inner Join #FinalTarget on T2.mc = #FinalTarget.machineinterface and  
T2.comp = #FinalTarget.compinterface and T2.opn = #FinalTarget.opninterface and  T2.opr = #FinalTarget.oprinterface   and t2.WorkOrderNumber=#FinalTarget.WorkOrderNumber
and T2.BatchStart=#FinalTarget.BatchStart and T2.BatchEnd=#FinalTarget.BatchEnd  
 
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
BEGIN  
    
 UPDATE #FinalTarget SET components=ISNULL(components,0)- isnull(t2.PlanCt,0) ,CN = isnull(CN,0) - isNull(t2.C1N1,0) 
  FROM ( select autodata.mc,autodata.comp,autodata.opn,autodata.opr,autodata.WorkOrderNumber,F.Batchstart,F.Batchend,
  ((CAST(Sum(ISNULL(PartsCount,1)) AS Float)/ISNULL(CO.SubOperations,1))) as PlanCt,
	SUM((CO.cycletime * ISNULL(PartsCount,1))/ISNULL(CO.SubOperations,1))  C1N1
   from #T_autodata autodata   
     INNER JOIN #FinalTarget F on F.machineinterface=autodata.mc and F.Compinterface=autodata.comp and F.Opninterface = autodata.opn and F.oprinterface=autodata.opr  
	 and F.WorkOrderNumber=autodata.WorkOrderNumber
  Inner jOIN #PlannedDownTimesShift T on T.MachineInterface=autodata.mc    
  inner join machineinformation M on autodata.mc=M.Interfaceid  
  left join componentinformation CI on autodata.comp=CI.interfaceid   
  left join componentoperationpricing CO on autodata.opn=CO.interfaceid and  
  CI.componentid=CO.componentid  and CO.machineid=M.machineid  
  WHERE autodata.DataType=1 and  
  (autodata.ndtime>F.BatchStart) and (autodata.ndtime<=F.BatchEnd)   
  AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)  
   Group by autodata.mc,autodata.comp,autodata.opn,autodata.opr,autodata.WorkOrderNumber,F.Batchstart,F.Batchend,CO.SubOperations   
 ) as T2 Inner Join #FinalTarget on T2.mc = #FinalTarget.machineinterface and  
 T2.comp = #FinalTarget.compinterface and T2.opn = #FinalTarget.opninterface and  T2.opr = #FinalTarget.oprinterface and t2.WorkOrderNumber=#FinalTarget.WorkOrderNumber  
 and T2.BatchStart=#FinalTarget.BatchStart and T2.BatchEnd=#FinalTarget.BatchEnd  
   
END  

 
Update #FinalTarget set RejCount = isnull(RejCount,0) + isnull(T2.RejQty,0)  
From  
( Select A.mc,A.comp,A.opn,A.opr,A.WorkOrderNumber,FT.BatchStart,FT.BatchEnd,SUM(A.Rejection_Qty) as RejQty from AutodataRejections A  
inner join #FinalTarget FT on FT.machineinterface=A.mc and FT.Compinterface=A.comp and FT.OpnInterface=A.opn and FT.OprInterface=A.opr and FT.WorkOrderNumber=A.WorkOrderNumber
and A.CreatedTS>=BatchStart and A.CreatedTS<BatchEnd 
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid  
where A.flag = 'Rejection'  
and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000'  
group by A.mc,A.comp,A.opn,A.opr,A.WorkOrderNumber,FT.BatchStart,FT.BatchEnd
) T2 Inner Join #FinalTarget on T2.mc = #FinalTarget.machineinterface and  
 T2.comp = #FinalTarget.compinterface and T2.opn = #FinalTarget.opninterface and  T2.opr = #FinalTarget.oprinterface and t2.WorkOrderNumber=#FinalTarget.WorkOrderNumber  
 and T2.BatchStart=#FinalTarget.BatchStart and T2.BatchEnd=#FinalTarget.BatchEnd  
  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
BEGIN  
 Update #FinalTarget set RejCount = isnull(RejCount,0) - isnull(T2.RejQty,0) from  
 (Select A.mc,A.comp,A.opn,A.opr,A.WorkOrderNumber,FT.BatchStart,FT.BatchEnd,SUM(A.Rejection_Qty) as RejQty from AutodataRejections A  
 inner join #FinalTarget FT on FT.machineinterface=A.mc and FT.Compinterface=A.comp and FT.OpnInterface=A.opn and FT.OprInterface=A.opr and FT.WorkOrderNumber=A.WorkOrderNumber
 and A.CreatedTS>=BatchStart and A.CreatedTS<BatchEnd 
 inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid  
 Cross join Planneddowntimes P  
 where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=FT.Machineid   
 and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000' and  
 A.CreatedTS>=P.Starttime and A.CreatedTS<P.endtime  
 group by A.mc,A.comp,A.opn,A.opr,A.WorkOrderNumber,FT.BatchStart,FT.BatchEnd
 )T2 Inner Join #FinalTarget on T2.mc = #FinalTarget.machineinterface and  
 T2.comp = #FinalTarget.compinterface and T2.opn = #FinalTarget.opninterface and  T2.opr = #FinalTarget.oprinterface and t2.WorkOrderNumber=#FinalTarget.WorkOrderNumber  
 and T2.BatchStart=#FinalTarget.BatchStart and T2.BatchEnd=#FinalTarget.BatchEnd  
 
END  
  
Update #FinalTarget set RejCount = isnull(RejCount,0) + isnull(T2.RejQty,0)  
From  
( Select A.mc,A.comp,A.opn,A.opr,A.WorkOrderNumber,FT.BatchStart,FT.BatchEnd,SUM(A.Rejection_Qty) as RejQty from AutodataRejections A  
inner join #FinalTarget FT on FT.machineinterface=A.mc and FT.Compinterface=A.comp and FT.OpnInterface=A.opn and FT.OprInterface=A.opr and FT.WorkOrderNumber=A.WorkOrderNumber
 and A.CreatedTS>=BatchStart and A.CreatedTS<BatchEnd    
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid  
inner join #ShiftDetails S on convert(nvarchar(10),(A.RejDate),126)=convert(nvarchar(10),(S.PDate),126) and A.RejShift=S.shiftid --DR0333  
where A.flag = 'Rejection' and A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (convert(nvarchar(10),(S.PDate),126)) and  --DR0333  
Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'  
group by A.mc,A.comp,A.opn,A.opr,A.WorkOrderNumber,FT.BatchStart,FT.BatchEnd
)T2 Inner Join #FinalTarget on T2.mc = #FinalTarget.machineinterface and  
 T2.comp = #FinalTarget.compinterface and T2.opn = #FinalTarget.opninterface and  T2.opr = #FinalTarget.oprinterface and t2.WorkOrderNumber=#FinalTarget.WorkOrderNumber  
 and T2.BatchStart=#FinalTarget.BatchStart and T2.BatchEnd=#FinalTarget.BatchEnd
  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
BEGIN  
 Update #FinalTarget set RejCount = isnull(RejCount,0) - isnull(T2.RejQty,0) from  
 (Select A.mc,A.comp,A.opn,A.opr,A.WorkOrderNumber,FT.BatchStart,FT.BatchEnd,SUM(A.Rejection_Qty) as RejQty from AutodataRejections A  
 inner join #FinalTarget FT on FT.machineinterface=A.mc and FT.Compinterface=A.comp and FT.OpnInterface=A.opn and FT.OprInterface=A.opr and FT.WorkOrderNumber=A.WorkOrderNumber
 and A.CreatedTS>=BatchStart and A.CreatedTS<BatchEnd     
 inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid  
 inner join #ShiftDetails S on convert(nvarchar(10),(A.RejDate),126)=convert(nvarchar(10),(S.PDate),126) and A.RejShift=S.shiftid --DR0333  
 Cross join Planneddowntimes P  
 where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=FT.Machineid and  
 A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (convert(nvarchar(10),(S.PDate),126))  and --DR0333  
 Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'  
 and P.starttime>=S.Shiftstart and P.Endtime<=S.shiftend  
 group by A.mc,A.comp,A.opn,A.opr,A.WorkOrderNumber,FT.BatchStart,FT.BatchEnd
 )T2 Inner Join #FinalTarget on T2.mc = #FinalTarget.machineinterface and  
 T2.comp = #FinalTarget.compinterface and T2.opn = #FinalTarget.opninterface and  T2.opr = #FinalTarget.oprinterface and t2.WorkOrderNumber=#FinalTarget.WorkOrderNumber  
 and T2.BatchStart=#FinalTarget.BatchStart and T2.BatchEnd=#FinalTarget.BatchEnd  
END  

 UPDATE #FinalTarget SET Avgcycletime = isnull(Avgcycletime,0) + isNull(t2.avgcycle,0)  
 from  
 (select S.MachineID,S.Component,S.operation,S.Operator,S.WorkOrderNumber,S.BatchStart,S.BatchEnd,  
 sum(cycletime) avgcycle  
 from #T_autodata autodata      
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface and autodata.opr = S.Oprinterface  
 and S.WorkOrderNumber=autodata.WorkOrderNumber
 where (autodata.ndtime>S.BatchStart and autodata.ndtime<=S.BatchEnd  )
 and (autodata.datatype=1)  
 and (autodata.partscount>0)    
 group by S.MachineID,S.Component,S.operation,S.Operator,S.WorkOrderNumber,S.BatchStart,S.BatchEnd  
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and   
 t2.operation = #FinalTarget.operation and t2.Operator = #FinalTarget.Operator  and t2.WorkOrderNumber=#FinalTarget.WorkOrderNumber
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  

 
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y' 
and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_AvgCycletime_4m_PLD')='Y' --ER0363 Added
BEGIN

	 UPDATE #FinalTarget SET Avgcycletime = isnull(Avgcycletime,0) - isNull(t2.PPDT,0)  
	 from  (
	select A.MachineID,A.Component,A.operation,A.Operator,A.WorkOrderNumber,A.BatchStart,A.BatchEnd,Sum
			(CASE
			WHEN A.sttime >= T.StartTime  AND A.ndtime <=T.EndTime  THEN DateDiff(second,A.sttime,A.ndtime) --DR0325 Added
			WHEN ( A.sttime < T.StartTime  AND A.ndtime <= T.EndTime  AND A.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,A.ndtime)
			WHEN ( A.sttime >= T.StartTime   AND A.sttime <T.EndTime  AND A.ndtime > T.EndTime  ) THEN DateDiff(second,A.sttime,T.EndTime )
			WHEN ( A.sttime < T.StartTime  AND A.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END)  as PPDT
			From
			
			(
				select S.MachineID,S.Component,S.operation,S.Operator,S.WorkOrderNumber,S.BatchStart,S.BatchEnd,autodata.sttime,autodata.ndtime,autodata.msttime
				from #T_autodata autodata      
				inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface and autodata.opr = S.Oprinterface  
				and autodata.WorkOrderNumber=S.WorkOrderNumber
				where (autodata.ndtime>S.BatchStart and autodata.ndtime<=S.BatchEnd)
				and (autodata.datatype=1)  
			)A
			CROSS jOIN PlannedDownTimes T 
			WHERE T.Machine=A.MachineID AND
			((A.msttime >= T.StartTime  AND A.ndtime <=T.EndTime)
			OR ( A.msttime < T.StartTime  AND A.ndtime <= T.EndTime AND A.ndtime > T.StartTime )
			OR ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime AND A.ndtime > T.EndTime )
			OR ( A.msttime < T.StartTime  AND A.ndtime > T.EndTime) )	
		group by A.MachineID,A.Component,A.operation,A.Operator,A.WorkOrderNumber,A.BatchStart,A.BatchEnd
	)
	as T2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and   
	 t2.operation = #FinalTarget.operation and t2.Operator = #FinalTarget.Operator  and t2.WorkOrderNumber=#FinalTarget.WorkOrderNumber
	 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  

	--Handle intearction between ICD and PDT for type 1 production record for the selected time period.
		 UPDATE #FinalTarget SET Avgcycletime = isnull(Avgcycletime,0) + isNull(T2.IPDT ,0) 	FROM	
		(
		Select T1.MachineID,T1.Component,T1.operation,T1.Operator,T1.WorkOrderNumber,T1.BatchStart,T1.BatchEnd,
		SUM(
		CASE 	
			When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
			When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
			When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
			when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		from #T_autodata autodata INNER Join --ER0324 Added
			(	select S.MachineID,S.Component,S.operation,S.Operator,S.WorkOrderNumber,S.BatchStart,S.BatchEnd,autodata.sttime,autodata.ndtime,autodata.msttime,
				S.Compinterface,S.Opninterface,S.Oprinterface,autodata.mc
				from #T_autodata autodata      
				inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface and autodata.opr = S.Oprinterface  
				and S.WorkOrderNumber=autodata.WorkOrderNumber
				where (autodata.ndtime>S.BatchStart and autodata.ndtime<=S.BatchEnd)
				and (autodata.datatype=1) And DateDiff(Second,sttime,ndtime)>CycleTime 
			) as T1
		ON AutoData.mc=T1.mc and autodata.comp=T1.Compinterface and autodata.opn=T1.Opninterface and autodata.opr = T1.Oprinterface  and autodata.WorkOrderNumber=T1.WorkOrderNumber
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
		GROUP BY T1.MachineID,T1.Component,T1.operation,T1.Operator,T1.WorkOrderNumber,T1.BatchStart,T1.BatchEnd
		)AS T2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and   
	 t2.operation = #FinalTarget.operation and t2.Operator = #FinalTarget.Operator  and t2.WorkOrderNumber=#FinalTarget.WorkOrderNumber
	 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  

	
End


Update #FinalTarget set avgCycletime=(isnull(avgCycletime,0)/isnull(components,1))* isnull(suboperations,1) 
from #FinalTarget
left join componentoperationpricing C on #FinalTarget.MachineID=C.MachineID and #FinalTarget.component=C.Componentid and
#FinalTarget.Operation = c.Operationno where components>0

--Update #FinalTarget set avgCycletime=(isnull(t2.avgcycle,0)) 
--from 
--(select S.MachineID,S.Component,S.operation,S.Operator,S.WorkOrderNumber,S.BatchStart,S.BatchEnd,  
-- (isnull(avgCycletime,0)/isnull(components,1))* isnull(suboperations,1) as avgcycle  
-- from  #FinalTarget S 
-- left join componentoperationpricing C on S.MachineID=C.MachineID and S.component=C.Componentid and
-- S.Operation = c.Operationno 
-- where components>0
-- ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and   
-- t2.operation = #FinalTarget.operation and t2.Operator = #FinalTarget.Operator  and t2.WorkOrderNumber=#FinalTarget.WorkOrderNumber
-- and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  




declare @i as nvarchar(10)
declare @colName as nvarchar(50)
Select @i=1

while @i <=33 
Begin
	Select @ColName = Case when @i=1 then 'A'
						when @i=2 then 'B'
						when @i=3 then 'C'
						when @i=4 then 'D'
						when @i=5 then 'E'
						when @i=6 then 'F'
						when @i=7 then 'G'
						when @i=8 then 'H'
						when @i=9 then 'I'
						when @i=10 then 'J'
						when @i=11 then 'K'
						when @i=12 then 'L'
						when @i=13 then 'M'
						when @i=14 then 'N'
						when @i=15 then 'O'
						when @i=16 then 'P' 
						when @i=17 then 'Q' 
						when @i=18 then 'R' 
						when @i=19 then 'S' 
						when @i=20 then 'T' 
						when @i=21 then 'U' 
						when @i=22 then 'V' 
						when @i=23 then 'W' 
						when @i=24 then 'X' 
						when @i=25 then 'Y' 
						when @i=26 then 'Z' 
						when @i=27 then 'AA' 
						when @i=28 then 'AB' 
						when @i=29 then 'AC' 
						when @i=30 then 'AD' 
						when @i=31 then 'AE' 
						when @i=32 then 'AF' 
						when @i=33 then 'AG' 
						 END



	 ---Get the down times which are not of type Management Loss  
	 Select @strsql = ''
	 Select @strsql = @strsql + ' UPDATE #FinalTarget SET ' + @ColName + ' = isnull(' + @ColName + ',0) + isNull(t2.down,0)  
	 from  
	 (select  F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.oprinterface,  F.WorkOrderNumber,
	  sum (CASE  
		WHEN (autodata.msttime >= F.BatchStart  AND autodata.ndtime <=F.BatchEnd)  THEN autodata.loadunload  
		WHEN ( autodata.msttime < F.BatchStart  AND autodata.ndtime <= F.BatchEnd  AND autodata.ndtime > F.BatchStart ) THEN DateDiff(second,F.BatchStart,autodata.ndtime)  
		WHEN ( autodata.msttime >= F.BatchStart   AND autodata.msttime <F.BatchEnd  AND autodata.ndtime > F.BatchEnd  ) THEN DateDiff(second,autodata.msttime,F.BatchEnd )  
		WHEN ( autodata.msttime < F.BatchStart  AND autodata.ndtime > F.BatchEnd ) THEN DateDiff(second,F.BatchStart,F.BatchEnd )  
		END ) as down  
		from #T_autodata autodata   
		inner join #FinalTarget F on autodata.mc = F.Machineinterface and autodata.comp=F.Compinterface and autodata.opn=F.Opninterface and autodata.opr = F.Oprinterface  
		and autodata.WorkOrderNumber=F.WorkOrderNumber
		inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid 
		inner join #Downcode on #Downcode.downid= downcodeinformation.downid
		where (autodata.datatype=''2'') AND  #Downcode.Slno= ' + @i + ' and 
		(( (autodata.msttime>=F.BatchStart) and (autodata.ndtime<=F.BatchEnd))  
		   OR ((autodata.msttime<F.BatchStart)and (autodata.ndtime>F.BatchStart)and (autodata.ndtime<=F.BatchEnd))  
		   OR ((autodata.msttime>=F.BatchStart)and (autodata.msttime<F.BatchEnd)and (autodata.ndtime>F.BatchEnd))  
		   OR((autodata.msttime<F.BatchStart)and (autodata.ndtime>F.BatchEnd)))   
		AND (downcodeinformation.availeffy = ''0'')  
		   group by F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.oprinterface,F.WorkOrderNumber  
	 ) as t2 Inner Join #FinalTarget on t2.machineinterface = #FinalTarget.machineinterface and  
	 t2.compinterface = #FinalTarget.compinterface and t2.opninterface = #FinalTarget.opninterface and  t2.oprinterface = #FinalTarget.oprinterface  and t2.WorkOrderNumber=#FinalTarget.WorkOrderNumber 
	 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd '
     print @strsql
	 exec(@strsql) 
	 
		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
		BEGIN   
			 Select @strsql = '' 
			 Select @strsql = @strsql + 'UPDATE  #FinalTarget SET ' + @ColName + ' = isnull(' + @ColName + ',0) - isNull(T2.PPDT ,0)  
			 FROM(  
			 SELECT F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.oprinterface, F.WorkOrderNumber, 
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
				and F.WorkOrderNumber=autodata.WorkOrderNumber
				inner join #Downcode on #Downcode.downid= downcodeinformation.downid
			
				WHERE autodata.DataType=''2'' AND T.MachineInterface=autodata.mc AND (downcodeinformation.availeffy = ''0'') and #Downcode.Slno= ' + @i + '  
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
				 group  by F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.oprinterface ,F.WorkOrderNumber 
			 )AS T2  Inner Join #FinalTarget on t2.machineinterface = #FinalTarget.machineinterface and  
			 t2.compinterface = #FinalTarget.compinterface and t2.opninterface = #FinalTarget.opninterface and  t2.oprinterface = #FinalTarget.oprinterface   and t2.WorkOrderNumber=#FinalTarget.WorkOrderNumber
			 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  '
			print @strsql
			exec(@Strsql)
		END

	select @i  =  @i + 1
End


---Get the down times which are not of type Management Loss  
 UPDATE #FinalTarget SET Others = isnull(Others,0) + isNull(t2.down,0)  
 from  
 (select  F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.oprinterface,F.WorkOrderNumber,  
  sum (CASE  
    WHEN (autodata.msttime >= F.BatchStart  AND autodata.ndtime <=F.BatchEnd)  THEN autodata.loadunload  
    WHEN ( autodata.msttime < F.BatchStart  AND autodata.ndtime <= F.BatchEnd  AND autodata.ndtime > F.BatchStart ) THEN DateDiff(second,F.BatchStart,autodata.ndtime)  
    WHEN ( autodata.msttime >= F.BatchStart   AND autodata.msttime <F.BatchEnd  AND autodata.ndtime > F.BatchEnd  ) THEN DateDiff(second,autodata.msttime,F.BatchEnd )  
    WHEN ( autodata.msttime < F.BatchStart  AND autodata.ndtime > F.BatchEnd ) THEN DateDiff(second,F.BatchStart,F.BatchEnd )  
    END ) as down  
    from #T_autodata autodata   
    inner join #FinalTarget F on autodata.mc = F.Machineinterface and autodata.comp=F.Compinterface and autodata.opn=F.Opninterface and autodata.opr = F.Oprinterface  
	and autodata.WorkOrderNumber=F.WorkOrderNumber
    inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid  
  where (autodata.datatype=2) AND  
    (( (autodata.msttime>=F.BatchStart) and (autodata.ndtime<=F.BatchEnd))  
       OR ((autodata.msttime<F.BatchStart)and (autodata.ndtime>F.BatchStart)and (autodata.ndtime<=F.BatchEnd))  
       OR ((autodata.msttime>=F.BatchStart)and (autodata.msttime<F.BatchEnd)and (autodata.ndtime>F.BatchEnd))  
       OR((autodata.msttime<F.BatchStart)and (autodata.ndtime>F.BatchEnd)))   
    AND (downcodeinformation.availeffy = 0)  --and downcodeinformation.downid in('New Job Set up Change','Job Loading','Job Unloading','Waiting for QC Inspector')
	AND downcodeinformation.SortOrder IS NULL
       group by F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.oprinterface,F.WorkOrderNumber  
 ) as t2 Inner Join #FinalTarget on t2.machineinterface = #FinalTarget.machineinterface and  
 t2.compinterface = #FinalTarget.compinterface and t2.opninterface = #FinalTarget.opninterface and  t2.oprinterface = #FinalTarget.oprinterface   and T2.WorkOrderNumber=#FinalTarget.WorkOrderNumber
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  
  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
BEGIN   
	 UPDATE  #FinalTarget SET Others = isnull(Others,0) - isNull(T2.PPDT ,0)  
	 FROM(  
	 SELECT F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.oprinterface,  F.WorkOrderNumber,
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
		and F.WorkOrderNumber=autodata.WorkOrderNumber
		WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND (downcodeinformation.availeffy = 0) --and downcodeinformation.downid in ('New Job Set up Change','Job Loading','Job Unloading','Waiting for QC Inspector')
		AND downcodeinformation.SortOrder IS NULL
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
		 group  by F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.oprinterface ,F.WorkOrderNumber 
	 )AS T2  Inner Join #FinalTarget on t2.machineinterface = #FinalTarget.machineinterface and  
	 t2.compinterface = #FinalTarget.compinterface and t2.opninterface = #FinalTarget.opninterface and  t2.oprinterface = #FinalTarget.oprinterface   and t2.WorkOrderNumber=#FinalTarget.WorkOrderNumber
	 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd 
END


---Get the down times which are not of type Management Loss  
 UPDATE #FinalTarget SET ReworkHrs = isnull(ReworkHrs,0) + isNull(t2.down,0)  
 from  
 (select  F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.oprinterface, F.WorkOrderNumber, 
  sum (CASE  
    WHEN (autodata.msttime >= F.BatchStart  AND autodata.ndtime <=F.BatchEnd)  THEN autodata.loadunload  
    WHEN ( autodata.msttime < F.BatchStart  AND autodata.ndtime <= F.BatchEnd  AND autodata.ndtime > F.BatchStart ) THEN DateDiff(second,F.BatchStart,autodata.ndtime)  
    WHEN ( autodata.msttime >= F.BatchStart   AND autodata.msttime <F.BatchEnd  AND autodata.ndtime > F.BatchEnd  ) THEN DateDiff(second,autodata.msttime,F.BatchEnd )  
    WHEN ( autodata.msttime < F.BatchStart  AND autodata.ndtime > F.BatchEnd ) THEN DateDiff(second,F.BatchStart,F.BatchEnd )  
    END ) as down  
    from #T_autodata autodata   
    inner join #FinalTarget F on autodata.mc = F.Machineinterface and autodata.comp=F.Compinterface and autodata.opn=F.Opninterface and autodata.opr = F.Oprinterface  
	and F.WorkOrderNumber=autodata.WorkOrderNumber
    inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid  
  where (autodata.datatype=2) AND  
    (( (autodata.msttime>=F.BatchStart) and (autodata.ndtime<=F.BatchEnd))  
       OR ((autodata.msttime<F.BatchStart)and (autodata.ndtime>F.BatchStart)and (autodata.ndtime<=F.BatchEnd))  
       OR ((autodata.msttime>=F.BatchStart)and (autodata.msttime<F.BatchEnd)and (autodata.ndtime>F.BatchEnd))  
       OR((autodata.msttime<F.BatchStart)and (autodata.ndtime>F.BatchEnd)))   
    AND  downcodeinformation.downid='Rework'
       group by F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.oprinterface ,F.WorkOrderNumber 
 ) as t2 Inner Join #FinalTarget on t2.machineinterface = #FinalTarget.machineinterface and  
 t2.compinterface = #FinalTarget.compinterface and t2.opninterface = #FinalTarget.opninterface and  t2.oprinterface = #FinalTarget.oprinterface   and t2.WorkOrderNumber=#FinalTarget.WorkOrderNumber
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  
  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
BEGIN   
	 UPDATE  #FinalTarget SET ReworkHrs = isnull(ReworkHrs,0) - isNull(T2.PPDT ,0)  
	 FROM(  
	 SELECT F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.oprinterface,F.WorkOrderNumber,  
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
		and F.WorkOrderNumber=autodata.WorkOrderNumber
		WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc  
		AND  downcodeinformation.downid='Rework'
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
		 group  by F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.oprinterface,F.WorkOrderNumber  
	 )AS T2  Inner Join #FinalTarget on t2.machineinterface = #FinalTarget.machineinterface and  
	 t2.compinterface = #FinalTarget.compinterface and t2.opninterface = #FinalTarget.opninterface and  t2.oprinterface = #FinalTarget.oprinterface  and t2.WorkOrderNumber=#FinalTarget.WorkOrderNumber 
	 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd 
END

 --UPDATE #FinalTarget  set downtime = isnull(downtime,0)- (isnull(ManagementLoss,0)+ isnull(IgnoreDowns,0))

 --UPDATE #FinalTarget  set Utilisedtime = isnull(Utilisedtime,0) + (isnull(ManagementLoss,0)+ isnull(IgnoreDowns,0))

 UPDATE #FinalTarget  set TotalAvailabletime = Datediff(s,FromTm,ToTm) 

Declare @PDTSetting as nvarchar(50)
Select @PDTSetting = isnull(Valueintext,'N') From Shopdefaults Where Parameter ='Alfalaval Report-Totaltime Less PDT'

update #FinalTarget set ActualAvailableTime=TotalAvailabletime

UPDATE #FinalTarget SET ActualAvailableTime = isnull(ActualAvailableTime,0) - isnull(T1.PDT,0) 
from
(Select S.MachineID,S.Fromtm,SUM(datediff(S,T.Starttime,T.endtime))as PDT from #PlannedDownTimesShift T
inner join (select distinct machineid,fromtm,totm from #FinalTarget) S on T.Machine=S.Machineid and T.ShiftSt=S.Fromtm
 where T.starttime>=S.fromtm and T.endtime<=S.Totm group by S.MachineID,S.Fromtm)T1
Inner Join #FinalTarget on T1.Machineid=#FinalTarget.Machineid and  T1.Fromtm=#FinalTarget.Fromtm


If @PDTSetting='Y'
Begin
	UPDATE #FinalTarget SET TotalAvailabletime = TotalAvailabletime - isnull(T1.PDT,0) 
	from
	(Select S.MachineID,S.Fromtm,SUM(datediff(S,T.Starttime,T.endtime))as PDT from #PlannedDownTimesShift T
	inner join (select distinct machineid,fromtm,totm from #FinalTarget) S on T.Machine=S.Machineid and T.ShiftSt=S.Fromtm
	 where T.starttime>=S.fromtm and T.endtime<=S.Totm group by S.MachineID,S.Fromtm)T1
	Inner Join #FinalTarget on T1.Machineid=#FinalTarget.Machineid and  T1.Fromtm=#FinalTarget.Fromtm
eND



UPDATE #FinalTarget
SET
	ProductionEfficiency = (CN/UtilisedTime) ,
	AvailabilityEfficiency = (UtilisedTime)/(UtilisedTime + DownTime - ManagementLoss) WHERE UtilisedTime <> 0

UPDATE #FinalTarget
SET
	OverAllEfficiency = (ProductionEfficiency * AvailabilityEfficiency)*100, 
	ProductionEfficiency = ProductionEfficiency * 100 ,
	AvailabilityEfficiency = AvailabilityEfficiency * 100


UPDATE #FinalTarget
SET  DeviationInActAvlTime = ((ISNULL(TotalAvailabletime,0) - ISNULL(A,0))/ISNULL(ActualAvailableTime,0))*100 where ActualAvailableTime>0

UPDATE #FinalTarget
SET TargetCount = (ISNULL(Utilisedtime,0)/ISNULL(stdTime,0)) WHERE stdTime > 0

Update #FinalTarget set PartCount=ISNULL(T1.PartCount,0)
From(
	Select A1.Mc,A1.Comp,A1.Opn,A1.Opr,A1.WorkOrderNo,A1.[Date],A1.[Shift],sum(isnull(A1.PartCount,0)) as PartCount  from ProductionCountDetails_KKPillar A1
	inner join #FinalTarget A2 on A1.Mc=A2.machineinterface and A1.Comp=A2.Compinterface and A1.Opn=A2.OpnInterface and A1.Opr=A2.OprInterface
	and A1.WorkOrderNo=A2.WorkOrderNumber and convert(nvarchar(10),A1.[Date],120)=convert(nvarchar(10),A2.Ddate,120) and A1.[Shift]=A2.ShiftID
	Group by  A1.Mc,A1.Comp,A1.Opn,A1.Opr,A1.WorkOrderNo,A1.[Date],A1.[Shift]
)T1 inner join #FinalTarget T2 on T1.Mc=T2.machineinterface and T1.Comp=T2.Compinterface and T1.Opn=T2.OpnInterface and T1.Opr=T2.OprInterface
	and T1.WorkOrderNo=T2.WorkOrderNumber and convert(nvarchar(10),T1.[Date],120)=convert(nvarchar(10),T2.Ddate,120) and T1.[Shift]=T2.ShiftID

--select Ddate,[Shift],PlantID,GroupID as CircleNo,MachineID,machineinterface,Component as FCode,Compinterface,Operation,OpnInterface,Operator,
--OprInterface,WorkOrderNumber as BatchNo,dbo.f_formattime(stdTime,'hh:mm:ss') as stdCycleTime,dbo.f_formattime(sum(Utilisedtime),'hh:mm:ss') as ActualCycleTime,
----dbo.f_formattime(TotalAvailabletime,'hh') as TotalAvailabletime,dbo.f_formattime(sum(CN),'hh') as Prodhrs, dbo.f_formattime(sum(others),'hh') as others,
----dbo.f_formattime(sum(Downtime),'hh') as TotalDowntime,Round(Sum(AvailabilityEfficiency),2) as AE,Round(Sum(ProductionEfficiency),2) as PE,
----Round(Sum(OverAllEfficiency),2) as OE,dbo.f_formattime(ActualAvailableTime,'hh') as ActualAvailabletime,ROUND(DeviationInActAvlTime,2) as DeviationInActAvlTime,
----ROUND(SUM(TargetCount),2) as TargetCount,dbo.f_formattime(sum(Reworkhrs),'hh') as Reworkhrs,
--SUM(components) as ActualCount,Sum(RejCount) as RejCount,
--dbo.f_formattime((sum(isnull(A,0))),'hh:mm:ss') as A,dbo.f_formattime((sum(isnull(B,0))),'hh:mm:ss') as B,dbo.f_formattime((sum(isnull(C,0))),'hh:mm:ss') as C,
--dbo.f_formattime((sum(isnull(D,0))),'hh:mm:ss') as D,dbo.f_formattime((sum(isnull(E,0))),'hh:mm:ss') as E,dbo.f_formattime((sum(isnull(F,0))),'hh:mm:ss') as F,
--dbo.f_formattime((sum(isnull(G,0))),'hh:mm:ss') as G,dbo.f_formattime((sum(isnull(H,0))),'hh:mm:ss') as H,dbo.f_formattime((sum(isnull(I,0))),'hh:mm:ss') as I,
--dbo.f_formattime((sum(isnull(J,0))),'hh:mm:ss') as J,dbo.f_formattime((sum(isnull(K,0))),'hh:mm:ss') as K,dbo.f_formattime((sum(isnull(L,0))),'hh:mm:ss') as L,
--dbo.f_formattime((sum(isnull(M,0))),'hh:mm:ss') as M,dbo.f_formattime((sum(isnull(N,0))),'hh:mm:ss') as N,dbo.f_formattime((sum(isnull(O,0))),'hh:mm:ss') as O,
--dbo.f_formattime((sum(isnull(P,0))),'hh:mm:ss') as P,dbo.f_formattime((sum(isnull(Q,0))),'hh:mm:ss') as Q,dbo.f_formattime((sum(isnull(R,0))),'hh:mm:ss') as R,
--dbo.f_formattime((sum(isnull(S,0))),'hh:mm:ss') as S,dbo.f_formattime((sum(isnull(T,0))),'hh:mm:ss') as T,dbo.f_formattime((sum(isnull(U,0))),'hh:mm:ss') as U,
--dbo.f_formattime((sum(isnull(V,0))),'hh:mm:ss') as V,dbo.f_formattime((sum(isnull(W,0))),'hh:mm:ss') as W,dbo.f_formattime((sum(isnull(X,0))),'hh:mm:ss') as X,
--dbo.f_formattime((sum(isnull(Y,0))),'hh:mm:ss') as Y,dbo.f_formattime((sum(isnull(Z,0))),'hh:mm:ss') as Z,dbo.f_formattime((sum(isnull(AA,0))),'hh:mm:ss') as AA,
--dbo.f_formattime((sum(isnull(AB,0))),'hh:mm:ss') as AB,dbo.f_formattime((sum(isnull(AC,0))),'hh:mm:ss') as AC,dbo.f_formattime((sum(isnull(AD,0))),'hh:mm:ss') as AD,
--dbo.f_formattime((sum(isnull(AE,0))),'hh:mm:ss') as AE,dbo.f_formattime((sum(isnull(AF,0))),'hh:mm:ss') as AF,dbo.f_formattime((sum(isnull(AG,0))),'hh:mm:ss') as AG
--from #FinalTarget
--Group by Ddate,[Shift],PlantID,GroupID,MachineID,machineinterface,Component,Compinterface,Operation,OpnInterface,Operator,OprInterface,WorkOrderNumber,
--stdtime	--,TotalAvailabletime,ActualAvailableTime,DeviationInActAvlTime,Reworkhrs
--order by PlantID,Ddate,GroupID,MachineID,[Shift],Component,Operation,Operator,WorkOrderNumber



--select Ddate,[Shift],PlantID,GroupID as CircleNo,MachineID,machineinterface,Component as FCode,Compinterface,Operation,OpnInterface,Operator,
select Ddate,[Shift],PlantID,GroupID as Division,MachineID,machineinterface,MachineDescription as CircleNo,Component as FCode,Compinterface,Operation,OpnInterface,Operator,
OprInterface,WorkOrderNumber as BatchNo,dbo.f_formattime(stdTime,'mm') as StdCycleTime,dbo.f_formattime((sum(isnull(Utilisedtime,0))),'mm') as UtilisedTime,
dbo.f_formattime((sum(isnull(Avgcycletime,0))),'mm') as AvgcycleTime,SUM(components) as ActualCount,SUM(PartCount) AS PartCount,Sum(RejCount) as RejCount,
dbo.f_formattime((sum(isnull(A,0))),'mm') as A,dbo.f_formattime((sum(isnull(B,0))),'mm') as B,dbo.f_formattime((sum(isnull(C,0))),'mm') as C,
dbo.f_formattime((sum(isnull(D,0))),'mm') as D,dbo.f_formattime((sum(isnull(E,0))),'mm') as E,dbo.f_formattime((sum(isnull(F,0))),'mm') as F,
dbo.f_formattime((sum(isnull(G,0))),'mm') as G,dbo.f_formattime((sum(isnull(H,0))),'mm') as H,dbo.f_formattime((sum(isnull(I,0))),'mm') as I,
dbo.f_formattime((sum(isnull(J,0))),'mm') as J,dbo.f_formattime((sum(isnull(K,0))),'mm') as K,dbo.f_formattime((sum(isnull(L,0))),'mm') as L,
dbo.f_formattime((sum(isnull(M,0))),'mm') as M,dbo.f_formattime((sum(isnull(N,0))),'mm') as N,dbo.f_formattime((sum(isnull(O,0))),'mm') as O,
dbo.f_formattime((sum(isnull(P,0))),'mm') as P,dbo.f_formattime((sum(isnull(Q,0))),'mm') as Q,dbo.f_formattime((sum(isnull(R,0))),'mm') as R,
dbo.f_formattime((sum(isnull(S,0))),'mm') as S,dbo.f_formattime((sum(isnull(T,0))),'mm') as T,dbo.f_formattime((sum(isnull(U,0))),'mm') as U,
dbo.f_formattime((sum(isnull(V,0))),'mm') as V,dbo.f_formattime((sum(isnull(W,0))),'mm') as W,dbo.f_formattime((sum(isnull(X,0))),'mm') as X,
dbo.f_formattime((sum(isnull(Y,0))),'mm') as Y,dbo.f_formattime((sum(isnull(Z,0))),'mm') as Z,dbo.f_formattime((sum(isnull(AA,0))),'mm') as AA,
dbo.f_formattime((sum(isnull(AB,0))),'mm') as AB,dbo.f_formattime((sum(isnull(AC,0))),'mm') as AC,dbo.f_formattime((sum(isnull(AD,0))),'mm') as AD,
dbo.f_formattime((sum(isnull(AE,0))),'mm') as AE,dbo.f_formattime((sum(isnull(AF,0))),'mm') as AF,dbo.f_formattime((sum(isnull(AG,0))),'mm') as AG
from #FinalTarget
Group by Ddate,[Shift],PlantID,GroupID,MachineID,machineinterface,MachineDescription,Component,Compinterface,Operation,OpnInterface,Operator,OprInterface,WorkOrderNumber,
stdtime	
order by PlantID,Ddate,[Shift],GroupID,MachineID,Component,Operation,Operator,WorkOrderNumber


END
