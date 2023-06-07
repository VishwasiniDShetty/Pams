/****** Object:  Procedure [dbo].[s_GetShiftTarget_Eastern]    Committed by VersionSQL https://www.versionsql.com ******/

/***************************************************************************************************
-- Author:		Anjana C V
-- Create date: 21 March 2019
-- Modified date: 21 March 2019
-- Description:  Get Shift Target Eastern
-- s_GetShiftTarget_Eastern 'cnc-01','2','2','2019-03-25 22:00:00.000'
**************************************************************************************************/
CREATE PROCEDURE [dbo].[s_GetShiftTarget_Eastern]
	@mc nvarchar(50) ,
	@CompInterface nvarchar(50) ,
	@OpnInterface nvarchar(50),
	@SetupChangeTime datetime=''

AS
BEGIN

DECLARE @SDateTime datetime
DECLARE @CompID nvarchar(50)
DECLARE @OpnID nvarchar(50) 
select @SDateTime = getdate()

CREATE TABLE #target
(  
MachineID nvarchar(50) NOT NULL,
Compinterface nvarchar(50),
OpnInterface nvarchar(50),
Component nvarchar(50) NOT NULL ,
LoadUnload float,
Day datetime,
Shift nvarchar(20),  
ShiftStart datetime,  
ShiftEnd datetime,
TargetCount float,
Runtime float,
SetupChangeTime datetime,
LUThreshold float,
StdSetuptime float
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

CREATE TABLE #ShiftDetails   
   (  
	PDate datetime,  
	Shift nvarchar(20),  
	ShiftStart datetime,  
	ShiftEnd datetime,
	ShiftID nvarchar(50)
   ) 
   
select @CompID = componentid from componentinformation where InterfaceID = @CompInterface

IF EXISTS (SELECT * from componentoperationpricing where machineid = @mc and componentid = @compID and interfaceid = @OpnInterface)
BEGIN 

print '1'
INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd , ShiftID)  
EXEC  dbo.[s_GetCurrentShiftTime] @SDateTime

insert INTO #PlannedDownTimesShift(StartTime,EndTime,Machine,MachineInterface,Downreason,Shiftst) 
select  
CASE When StartTime<T1.ShiftStart Then T1.ShiftStart Else StartTime End,  
case When EndTime>T1.ShiftEnd Then T1.ShiftEnd Else EndTime End,  
Machine,MachineInformation.InterfaceID,  
DownReason,T1.ShiftStart  
FROM PlannedDownTimes 
cross join #ShiftDetails T1  
inner join MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID  
inner Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid   
inner Join PlantMachineGroups ON PlantMachineGroups.MachineID=Machineinformation.machineid and PlantMachineGroups.PlantID = PlantMachine.PlantID
WHERE PDTstatus =1 and (  
(StartTime >= T1.ShiftStart  AND EndTime <=T1.ShiftEnd)  
OR ( StartTime < T1.ShiftStart  AND EndTime <= T1.ShiftEnd AND EndTime > T1.ShiftStart )  
OR ( StartTime >= T1.ShiftStart   AND StartTime <T1.ShiftEnd AND EndTime > T1.ShiftEnd )  
OR ( StartTime < T1.ShiftStart  AND EndTime > T1.ShiftEnd) ) 
and machine = @mc
ORDER BY StartTime

--Insert into #target (MachineID,Compinterface,OpnInterface,Component,Day,Shift,ShiftStart, ShiftEnd ,TargetCount)
--SELECT @mc,@CompInterface,@OpnInterface,@CompID,PDate,Shift,ShiftStart, ShiftEnd,
--(DATEDIFF(second, ShiftStart, ShiftEnd)/componentoperationpricing.cycletime) as TotalProdQty
--from componentoperationpricing 
--Cross join #ShiftDetails 
--where machineid = @mc and componentid = @compID and interfaceid = @OpnInterface

--UPDATE #target
--set TargetCount = TargetCount - isnull(T1.PDT,0)     
-- from    
-- (
--  Select Machine,SUM(datediff(S, S.StartTime, S.EndTime)) as PDT ,T.ShiftStart
--  from PlannedDownTimes S  
--  inner join #Target T on T.MachineID = S.Machine and (S.StartTime>=T.ShiftStart and S.EndTime<=T.ShiftEnd)
--  group by machine,T.ShiftStart
--  )T1    
--  INNER JOIN #Target on T1.Machine=#Target.Machineid and T1.ShiftStart=#Target.ShiftStart


Insert into #target (MachineID,Compinterface,OpnInterface,Component,Day,Shift,ShiftStart, ShiftEnd ,Runtime,SetupChangeTime)
SELECT @mc,@CompInterface,@OpnInterface,@CompID,PDate,Shift,ShiftStart, ShiftEnd,
DATEDIFF(second, case when ISNULL(@SetupChangeTime,'1900-01-01')<>'1900-01-01' then @SetupChangeTime else shiftstart end, ShiftEnd),
case when ISNULL(@SetupChangeTime,'1900-01-01')<>'1900-01-01' then @SetupChangeTime else ShiftStart End From #ShiftDetails 

UPDATE #target
set Runtime = ISNULL(Runtime,0) - isnull(T1.PDT,0)     
 from    
 (
  Select Machine,SUM(datediff(S, S.StartTime, S.EndTime)) as PDT ,T.ShiftStart
  from #PlannedDownTimesShift S  
  inner join #Target T on T.MachineID = S.Machine and (S.StartTime>=T.ShiftStart and S.EndTime<=T.ShiftEnd)
  group by machine,T.ShiftStart
  )T1    
  INNER JOIN #Target on T1.Machine=#Target.Machineid and T1.ShiftStart=#Target.ShiftStart

  		
Update #target set TargetCount = Isnull(#target.targetcount,0) + isnull(T1.targetcount,0) from 
(
Select T.Machineid,T.ShiftStart,sum(((T.Runtime*CO.suboperations)/CO.cycletime)*isnull(CO.targetpercent,100) /100) as targetcount
from #Target T 
inner join machineinformation M on M.machineid=T.MachineID
inner join componentinformation C on C.interfaceid=T.Compinterface
inner join componentoperationpricing CO on M.machineid=co.machineid and c.componentid=Co.componentid
and Co.interfaceid=T.Opninterface
group by T.ShiftStart,T.Machineid
)T1  INNER JOIN #Target on T1.MachineID=#Target.Machineid and T1.ShiftStart=#Target.ShiftStart

Update #target set LoadUnload = Isnull(#target.LoadUnload,0) + isnull(T1.LU,0),LUThreshold=ISNULL(LUThreshold,0)+ISNULL(T1.loadunload,0)
,StdSetuptime=ISNULL(T1.StdSetupTime,0) from 
(
Select T.Machineid,T.ShiftStart, (co.cycletime - co.machiningtime) as LU,CO.loadunload,CO.StdSetupTime 
from #Target T 
inner join machineinformation M on M.machineid=T.MachineID
inner join componentinformation C on C.interfaceid=T.Compinterface
inner join componentoperationpricing CO on M.machineid=co.machineid and c.componentid=Co.componentid
and Co.interfaceid=T.Opninterface
)T1  INNER JOIN #Target on T1.MachineID=#Target.Machineid and T1.ShiftStart=#Target.ShiftStart

select * from #target

END

END
