/****** Object:  Procedure [dbo].[s_GetBatchWiseComponentProductionReportFromAutoData_Dantal]    Committed by VersionSQL https://www.versionsql.com ******/

/*
--s_GetBatchWiseComponentProductionReportFromAutoData_Dantal '2019-07-10 06:00:00 AM','2019-07-11 06:00:00 AM','',''

[dbo].[s_GetBatchWiseComponentProductionReportFromAutoData_Dantal] '2022-01-10 06:00:00 AM','2022-02-28 06:00:00 AM','',''
*/

CREATE PROCEDURE [dbo].[s_GetBatchWiseComponentProductionReportFromAutoData_Dantal]
	@StartTime as DateTime ,
	@EndTime as DateTime,
	@ComponentID AS NvarChar(50)='',
	@OperationNo AS NvarChar(50)=''
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @StrSql nvarchar(4000)
DECLARE @TimeFormat NVarChar(30)
DECLARE @StrCompOpn AS NvarChar(255)
DECLARE @StrOpn AS NvarChar(255)
SELECT @StrSql=''
SELECT @StrCompOpn=''
SELECT @StrOpn=''


CREATE TABLE #ShiftDetails   
(  
 PDate datetime,  
 Shift nvarchar(20),  
 ShiftStart datetime,  
 ShiftEnd datetime  
)  
  
CREATE TABLE #T_autodata(  
 [mc] [nvarchar](50)not NULL,  
 [comp] [nvarchar](50) NULL,  
 [opn] [nvarchar](50) NULL,  
 [opr] [nvarchar](50) NULL,  
 [dcode] [nvarchar](50) NULL,  
 [sttime] [datetime] not NULL,  
 [ndtime] [datetime] not NULL,  
 [datatype] [tinyint] NULL ,  
 [cycletime] [int] NULL,  
 [loadunload] [int] NULL ,  
 [msttime] [datetime] not NULL,  
 [PartsCount] decimal(18,5) NULL ,  
 id  bigint not null  
)  
  
ALTER TABLE #T_autodata  
  
ADD PRIMARY KEY CLUSTERED  
(  
 mc,sttime,ndtime,msttime ASC  
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
Shift nvarchar(20)
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
MLDown float,
stdTime float,
Avgcycletime float,
Shift nvarchar(20),
TotalAvailabletime float,
Others float,
CN float,
ProductionEfficiency float,
AvailabilityEfficiency float,
QualityEfficiency float,
OverallEfficiency float,
ActualAvailableTime Float,
DeviationInActAvlTime Float,
TargetCount Float,
ReworkHrs float,
MinCycleTime  Float,
MaxCycleTime  Float,
SpeedRation   Float(2),
StdLoadUnload Float,
AvgLoadUnload Float,
MinLoadUnload Float,
MaxLoadUnload Float,
LoadRation    Float(2),
RejCount float default 0,
MachiningTime float,
TotalLoadUnload float
)  
  
Create table #PlannedDownTimes
(
	MachineID nvarchar(50) NOT NULL, --ER0374
	MachineInterface nvarchar(50) NOT NULL, --ER0374
	StartTime DateTime NOT NULL, --ER0374
	EndTime DateTime NOT NULL --ER0374
)
  
CREATE TABLE #Summary  
(  
 MachineID nvarchar(50) NOT NULL,  
 Utilisedtime float,  
 Components float,  
 Downtime float,  
 ManagementLoss float  
)  


Declare @CurStrtTime as datetime  
Declare @CurEndTime as datetime  
Declare @T_Start AS Datetime   
Declare @T_End AS Datetime  
  


CREATE TABLE #ShiftDefn
(
	ShiftDate datetime,		
	Shiftname nvarchar(20),
	ShftSTtime datetime,
	ShftEndTime datetime	
)

create table #shift
(
	
	ShiftDate nvarchar(50), --DR0333
	shiftname nvarchar(50),
	Shiftstart datetime,
	Shiftend datetime,
	shiftid int
)

  

Select @strsql=''  
select @strsql ='insert into #T_autodata  
				SELECT mc, comp, opn, opr, dcode,sttime, ndtime, datatype, cycletime, loadunload, msttime, 
				PartsCount,id from autodata where (( sttime >='''+ convert(nvarchar(25),@StartTime,120)+''' 
				and ndtime <= '''+ convert(nvarchar(25),@EndTime,120)+''' )
				OR  ( sttime <'''+ convert(nvarchar(25),@StartTime,120)+''' and ndtime >'''+ convert(nvarchar(25),@EndTime,120)+''' )  
				OR ( sttime <'''+ convert(nvarchar(25),@StartTime,120)+''' and ndtime >'''+ convert(nvarchar(25),@StartTime,120)+'''  
				and ndtime<='''+convert(nvarchar(25),@EndTime,120)+''' ) 
				OR ( sttime >='''+convert(nvarchar(25),@StartTime,120)+''' and ndtime >'''+ convert(nvarchar(25),@EndTime,120)+''' 
				and sttime<'''+convert(nvarchar(25),@EndTime,120)+''' ) )'  
print @strsql  
exec (@strsql)  


If ISNULL(@ComponentID,'')<>''
BEGIN
	SELECT @StrCompOpn=' AND f.component=N'''+ @ComponentID +''''
END
If ISNULL(@OperationNo,'')<>''
BEGIN
	SELECT @StrOpn=' AND f.Operation=N'''+ Convert(NVarChar,@OperationNo) +''' '
END
SELECT @TimeFormat ='ss'
SELECT @TimeFormat = isnull((SELECT ValueInText From CockPitDefaults Where Parameter='TimeFormat'),'ss')
if (@TimeFormat <>'hh:mm:ss' and @TimeFormat <>'hh' and @TimeFormat <>'mm'and @TimeFormat <>'ss')
BEGIN
SELECT @TimeFormat = 'ss'
END
  

declare @startdate as datetime
declare @enddate as datetime
declare @startdatetime nvarchar(20)
select @startdate=dbo.f_GetLogicalDay(@StartTime,'start')
select @enddate=dbo.f_GetLogicalDay(@EndTime,'end')


while @startdate<=@enddate
Begin

	select @startdatetime = CAST(datePart(yyyy,@startdate) AS nvarchar(4)) + '-' + 
     CAST(datePart(mm,@startdate) AS nvarchar(2)) + '-' + 
     CAST(datePart(dd,@startdate) AS nvarchar(2))

	INSERT INTO #ShiftDefn(ShiftDate,Shiftname,ShftSTtime,ShftEndTime)
	select @startdate,ShiftName,
	Dateadd(DAY,FromDay,(convert(datetime, @startdatetime + ' ' + CAST(datePart(hh,FromTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,FromTime) as nvarchar(2))+ ':' + CAST(datePart(ss,FromTime) as nvarchar(2))))) as StartTime,
	DateAdd(Day,ToDay,(convert(datetime, @startdatetime + ' ' + CAST(datePart(hh,ToTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,ToTime) as nvarchar(2))+ ':' + CAST(datePart(ss,ToTime) as nvarchar(2))))) as EndTime
	from shiftdetails where running = 1 order by shiftid
	Select @startdate = dateadd(d,1,@startdate)
END

Insert into #shift (ShiftDate,shiftname,Shiftstart,Shiftend)
select convert(nvarchar(10),ShiftDate,126),shiftname,ShftSTtime,ShftEndTime from #ShiftDefn --where ShftSTtime>=@StartTime and ShftEndTime<=@endtime 


Update #shift Set shiftid = isnull(#shift.Shiftid,0) + isnull(T1.shiftid,0) from
(Select SD.shiftid ,SD.shiftname from shiftdetails SD
inner join #shift S on SD.shiftname=S.shiftname where
running=1 )T1 inner join #shift on  T1.shiftname=#shift.shiftname

  
/* Planned Down times for the given time period */  
/* Planned Down times for the given time period */
SET @strSql = ''
SET @strSql = 'Insert into #PlannedDownTimes
	SELECT Machine,InterfaceID,
		CASE When StartTime<''' + convert(nvarchar(20),@StartTime,120)+''' Then ''' + convert(nvarchar(20),@StartTime,120)+''' Else StartTime End As StartTime,
		CASE When EndTime>''' + convert(nvarchar(20),@EndTime,120)+''' Then ''' + convert(nvarchar(20),@EndTime,120)+''' Else EndTime End As EndTime
	FROM PlannedDownTimes inner join MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID
	WHERE PDTstatus =1 and(
	(StartTime >= ''' + convert(nvarchar(20),@StartTime,120)+''' AND EndTime <=''' + convert(nvarchar(20),@EndTime,120)+''')
	OR ( StartTime < ''' + convert(nvarchar(20),@StartTime,120)+'''  AND EndTime <= ''' + convert(nvarchar(20),@EndTime,120)+''' AND EndTime > ''' + convert(nvarchar(20),@StartTime,120)+''' )
	OR ( StartTime >= ''' + convert(nvarchar(20),@StartTime,120)+'''   AND StartTime <''' + convert(nvarchar(20),@EndTime,120)+''' AND EndTime > ''' + convert(nvarchar(20),@EndTime,120)+''' )
	OR ( StartTime < ''' + convert(nvarchar(20),@StartTime,120)+'''  AND EndTime > ''' + convert(nvarchar(20),@EndTime,120)+''')) '
SET @strSql =  @strSql + ' ORDER BY Machine,StartTime'
EXEC(@strSql)
--ER0210(PDT)
  
     
Select @strsql=''   
Select @strsql= 'insert into #Target(MachineID,machineinterface,Component,Compinterface,Operation,Opninterface,msttime,ndtime,FromTm,Totm,batchid,autodataid,stdtime)'  
select @strsql = @strsql + ' SELECT machineinformation.machineid, machineinformation.interfaceid,componentinformation.componentid, componentinformation.interfaceid,  
componentoperationpricing.operationno, componentoperationpricing.interfaceid,  
Case when autodata.msttime< '''+CONVERT(NVARCHAR(20),@StartTime,120)+''' then '''+CONVERT(NVARCHAR(20),@StartTime,120)+''' else autodata.msttime end,   
Case when autodata.ndtime> '''+CONVERT(NVARCHAR(20),@EndTime,120)+''' then '''+CONVERT(NVARCHAR(20),@EndTime,120)+''' else autodata.ndtime end,  
'''+CONVERT(NVARCHAR(20),@StartTime,120)+''','''+CONVERT(NVARCHAR(20),@EndTime,120)+''',0,autodata.id,componentoperationpricing.machiningtime FROM #T_autodata  autodata  
INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID   
INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID    
INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID  
AND componentinformation.componentid = componentoperationpricing.componentid  
and componentoperationpricing.machineid=machineinformation.machineid   
Left Outer Join downcodeinformation DI on DI.interfaceid=autodata.dcode  
Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid   
where 
((autodata.msttime >= '''+CONVERT(NVARCHAR(20),@StartTime,120)+'''  AND autodata.ndtime <='''+CONVERT(NVARCHAR(20),@EndTime,120)+''')
OR ( autodata.msttime < '''+CONVERT(NVARCHAR(20),@StartTime,120)+'''  AND autodata.ndtime <= '''+CONVERT(NVARCHAR(20),@EndTime,120)+''' AND autodata.ndtime > '''+CONVERT(NVARCHAR(20),@StartTime,120)+''' )
OR ( autodata.msttime >= '''+CONVERT(NVARCHAR(20),@StartTime,120)+'''   AND autodata.msttime <'''+CONVERT(NVARCHAR(20),@EndTime,120)+''' AND autodata.ndtime > '''+CONVERT(NVARCHAR(20),@EndTime,120)+''' )
OR ( autodata.msttime < '''+CONVERT(NVARCHAR(20),@StartTime,120)+'''  AND autodata.ndtime > '''+CONVERT(NVARCHAR(20),@EndTime,120)+''') ) '
--select @strsql = @strsql + @StrCompOpn + @StrOpn
select @strsql = @strsql + ' order by autodata.msttime'  
print @strsql  
exec (@strsql)  
  
 insert into #FinalTarget (MachineID,Component,operation,machineinterface,Compinterface,Opninterface,BatchStart,BatchEnd,FromTm,ToTm,Utilisedtime,Downtime,Components,ManagementLoss,MLDown,stdtime,shift,TotalAvailabletime,batchid)
select MachineID,Component,operation,machineinterface,Compinterface,Opninterface,min(msttime),max(ndtime),FromTm,ToTm,0 Utilisedtime,0 Downtime,0 Components,0 ManagementLoss,0 MLDown,stdtime,shift,0 TotalAvailabletime,batchid
from
(
select MachineID,Component,operation,machineinterface,Compinterface,Opninterface,msttime,ndtime,FromTm,ToTm,stdtime,shift,
RANK() OVER (
  PARTITION BY t.machineid
  order by t.machineid, t.msttime
) -
RANK() OVER (
  PARTITION BY  t.machineid, t.component, t.operation, t.fromtm --autodataid=@autodataid and MachineID=@mc and Component=@comp and Operation=@opn and Operator=@opr and FromTm=@Fromtime 
  order by t.machineid, t.fromtm, t.msttime
) AS batchid
from #Target t 
) tt
group by MachineID,Component,operation,machineinterface,Compinterface,Opninterface,batchid,FromTm,ToTm,stdtime,shift 
order by tt.batchid
-- ER0465 g:/


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
) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and   
t2.operation = #FinalTarget.operation and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  
  
  
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
  inner join #FinalTarget ST1 ON ST1.MachineInterface=Autodata.mc and ST1.CompInterface=Autodata.Comp and  
  ST1.opnInterface=Autodata.opn   
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
  inner join #FinalTarget ST1 ON ST1.MachineInterface=Autodata.mc and ST1.CompInterface=Autodata.Comp and  
  ST1.opnInterface=Autodata.opn   
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
  inner join #FinalTarget ST1 ON ST1.MachineInterface=Autodata.mc and ST1.CompInterface=Autodata.Comp and  
  ST1.opnInterface=Autodata.opn   
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
     CROSS jOIN #PlannedDownTimes T  
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
  from #T_autodata autodata CROSS jOIN #PlannedDownTimes T INNER Join   
   (  
    Select autodata.mc,autodata.comp,autodata.opn,autodata.Sttime,autodata.NdTime,S.Batchstart,S.BatchEnd  
     from #T_autodata autodata inner join #FinalTarget S on S.MachineInterface=Autodata.mc and S.CompInterface=Autodata.Comp and  
    S.opnInterface=Autodata.opn   
    Where DataType=1 And DateDiff(Second, autodata.sttime, autodata.ndtime)>CycleTime And  
    ( autodata.msttime >= S.Batchstart) AND ( autodata.ndtime <= S.BatchEnd)  
   ) as T1  
  ON AutoData.mc=T1.mc and autodata.comp=T1.comp and Autodata.opn=T1.opn   
  Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc  
  And (( autodata.Sttime >= T1.Sttime )  
  And ( autodata.ndtime <=  T1.ndtime ))  
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
  from #T_autodata autodata CROSS jOIN #PlannedDownTimes T INNER Join   
   (  
     Select autodata.mc,autodata.comp,autodata.opn,autodata.Sttime,autodata.NdTime,S.Batchstart,S.BatchEnd   
     from #T_autodata autodata inner join #FinalTarget S on S.MachineInterface=Autodata.mc and S.CompInterface=Autodata.Comp and  
     S.opnInterface=Autodata.opn  
     Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And  
     (msttime < S.Batchstart)And (ndtime > S.Batchstart) AND (ndtime <= S.BatchEnd)  
    ) as T1  
  ON AutoData.mc=T1.mc and autodata.comp=T1.comp and Autodata.opn=T1.opn    
  Where AutoData.DataType=2  and T.MachineInterface=autodata.mc  
  And (( autodata.Sttime > T1.Sttime )  
  And ( autodata.ndtime <  T1.ndtime )  
  AND ( autodata.ndtime >  T1.Batchstart ))  
  AND  
  (( T.StartTime >= T1.Batchstart )  
  And ( T.StartTime <  T1.ndtime ) )  
  GROUP BY T1.BatchStart,T1.BatchEnd,autodata.mc,autodata.comp,autodata.opn )AS T2 Inner Join #FinalTarget on t2.mc = #FinalTarget.machineinterface and  
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
 from #T_autodata autodata CROSS jOIN #PlannedDownTimes T INNER Join  
  (  
   Select autodata.mc,autodata.comp,autodata.opn,autodata.Sttime,autodata.NdTime,S.Batchstart,S.BatchEnd   
   from #T_autodata autodata inner join #FinalTarget S on S.MachineInterface=Autodata.mc and S.CompInterface=Autodata.Comp and  
   S.opnInterface=Autodata.opn   
   Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And  
   (sttime >= S.Batchstart And ndtime > S.BatchEnd and autodata.sttime <S.BatchEnd)   
  )as T1  
 ON AutoData.mc=T1.mc and autodata.comp=T1.comp and Autodata.opn=T1.opn  
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
 from #T_autodata autodata CROSS jOIN #PlannedDownTimes T INNER Join   
  (  
   Select autodata.mc,autodata.comp,autodata.opn,autodata.Sttime,autodata.NdTime,S.Batchstart,S.BatchEnd   
   from #T_autodata autodata inner join #FinalTarget S on S.MachineInterface=Autodata.mc and S.CompInterface=Autodata.Comp and  
   S.opnInterface=Autodata.opn   
   Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And  
   (msttime < S.Batchstart)And (ndtime > S.BatchEnd)  
  ) as T1  
 ON AutoData.mc=T1.mc and autodata.comp=T1.comp and Autodata.opn=T1.opn     
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

  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y')  
BEGIN  
  
 --Type 1  
 UPDATE #FinalTarget SET downtime = isnull(downtime,0) + isNull(t2.down,0)  
 from  
 (select S.MachineID,S.Component,S.operation,S.BatchStart,S.BatchEnd,  
 sum(loadunload) as down  
 from #T_autodata autodata   
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface
 where (autodata.msttime>=S.BatchStart)  
 and (autodata.ndtime<= S.BatchEnd)  
 and (autodata.datatype=2)  
 group by S.MachineID,S.Component,S.operation,S.BatchStart,S.BatchEnd  
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and   
 t2.operation = #FinalTarget.operation and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  
   
 -- Type 2  
 UPDATE #FinalTarget SET downtime = isnull(downtime,0) + isNull(t2.down,0)  
 from  
 (select S.MachineID,S.Component,S.operation,S.BatchStart,S.BatchEnd,  
 sum(DateDiff(second, S.BatchStart, ndtime)) down  
 from #T_autodata autodata   
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface  
 where (autodata.sttime<S.BatchStart)  
 and (autodata.ndtime>S.BatchStart)  
 and (autodata.ndtime<= S.BatchEnd)  
 and (autodata.datatype=2)  
 group by S.MachineID,S.Component,S.operation,S.BatchStart,S.BatchEnd  
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and   
 t2.operation = #FinalTarget.operation  and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  
   
 -- Type 3  
 UPDATE #FinalTarget SET downtime = isnull(downtime,0) + isNull(t2.down,0)  
 from  
 (select S.MachineID,S.Component,S.operation,S.BatchStart,S.BatchEnd,  
 sum(DateDiff(second, stTime,  S.BatchEnd)) down  
 from #T_autodata autodata  
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface
 where (autodata.msttime>=S.BatchStart)  
 and (autodata.sttime< S.BatchEnd)  
 and (autodata.ndtime> S.BatchEnd)  
 and (autodata.datatype=2)group by S.MachineID,S.Component,S.operation,S.BatchStart,S.BatchEnd  
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and   
 t2.operation = #FinalTarget.operation and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  
   
   
 -- Type 4  
 UPDATE #FinalTarget SET downtime = isnull(downtime,0) + isNull(t2.down,0)  
 from  
 (select S.MachineID,S.Component,S.operation,S.BatchStart,S.BatchEnd,  
 sum(DateDiff(second, S.BatchStart,  S.BatchEnd)) down  
 from #T_autodata autodata   
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface   
 where autodata.msttime<S.BatchStart  
 and autodata.ndtime> S.BatchEnd  
 and (autodata.datatype=2)group by S.MachineID,S.Component,S.operation,S.BatchStart,S.BatchEnd  
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and   
 t2.operation = #FinalTarget.operation  and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  
   
  
 ---Management Loss-----  
 -- Type 1  
 UPDATE #FinalTarget SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)  
 from  
 (select S.MachineID,S.Component,S.operation,S.BatchStart,S.BatchEnd,  
 sum(CASE  
 WHEN loadunload >ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)  
 ELSE loadunload  
 END) loss  
 from #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid   
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface   
 where (autodata.msttime>=S.BatchStart)  
 and (autodata.ndtime<=S.BatchEnd)  
 and (autodata.datatype=2)  
 and (downcodeinformation.availeffy = 1)  
    and (downcodeinformation.ThresholdfromCO <>1) --NR0097  
 group by  S.MachineID,S.Component,S.operation,S.BatchStart,S.BatchEnd  
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and   
 t2.operation = #FinalTarget.operation  and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  
  
 -- Type 2  
 UPDATE #FinalTarget SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)  
 from  
 (select S.MachineID,S.Component,S.operation,S.BatchStart,S.BatchEnd,  
  sum(CASE  
 WHEN DateDiff(second, S.BatchStart, ndtime)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)  
 ELSE DateDiff(second, S.BatchStart, ndtime)  
 end) loss  
 from #T_autodata autodata   
  INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid   
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface   
 where (autodata.sttime<S.BatchStart)  
 and (autodata.ndtime>S.BatchStart)  
 and (autodata.ndtime<=S.BatchEnd)  
 and (autodata.datatype=2)  
 and (downcodeinformation.availeffy = 1)  
 and (downcodeinformation.ThresholdfromCO <>1) --NR0097  
 group by S.MachineID,S.Component,S.operation,S.BatchStart,S.BatchEnd  
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and   
 t2.operation = #FinalTarget.operation  and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  
  
 -- Type 3  
 UPDATE #FinalTarget SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)  
 from  
 (select S.MachineID,S.Component,S.operation,S.BatchStart,S.BatchEnd,  
 sum(CASE  
 WHEN DateDiff(second, stTime, S.BatchEnd)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)  
 ELSE DateDiff(second, stTime, S.BatchEnd)  
 END) loss  
 from #T_autodata autodata    
 INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid   
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface
 where (autodata.msttime>=S.BatchStart)  
 and (autodata.sttime<S.BatchEnd)  
 and (autodata.ndtime>S.BatchEnd)  
 and (autodata.datatype=2)  
 and (downcodeinformation.availeffy = 1)  
 and (downcodeinformation.ThresholdfromCO <>1) --NR0097  
 group by S.MachineID,S.Component,S.operation,S.BatchStart,S.BatchEnd  
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and   
 t2.operation = #FinalTarget.operation and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  
  
 -- Type 4  
 UPDATE #FinalTarget SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)  
 from  
 (select S.MachineID,S.Component,S.operation,S.BatchStart,S.BatchEnd,  
 sum(CASE  
 WHEN DateDiff(second, S.BatchStart, S.BatchEnd)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)  
 ELSE DateDiff(second, S.BatchStart, S.BatchEnd)  
 END) loss  
 from #T_autodata autodata   
 INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid   
 inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface  
 where autodata.msttime<S.BatchStart  
 and autodata.ndtime>S.BatchEnd  
 and (autodata.datatype=2)  
 and (downcodeinformation.availeffy = 1)  
 and (downcodeinformation.ThresholdfromCO <>1) --NR0097  
 group by S.MachineID,S.Component,S.operation,S.BatchStart,S.BatchEnd  
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and   
 t2.operation = #FinalTarget.operation and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  
END  
  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
BEGIN  
  
 ---Get the down times which are not of type Management Loss  
 UPDATE #FinalTarget SET downtime = isnull(downtime,0) + isNull(t2.down,0)  
 from  
 (select  F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,  
  sum (CASE  
    WHEN (autodata.msttime >= F.BatchStart  AND autodata.ndtime <=F.BatchEnd)  THEN autodata.loadunload  
    WHEN ( autodata.msttime < F.BatchStart  AND autodata.ndtime <= F.BatchEnd  AND autodata.ndtime > F.BatchStart ) THEN DateDiff(second,F.BatchStart,autodata.ndtime)  
    WHEN ( autodata.msttime >= F.BatchStart   AND autodata.msttime <F.BatchEnd  AND autodata.ndtime > F.BatchEnd  ) THEN DateDiff(second,autodata.msttime,F.BatchEnd )  
    WHEN ( autodata.msttime < F.BatchStart  AND autodata.ndtime > F.BatchEnd ) THEN DateDiff(second,F.BatchStart,F.BatchEnd )  
    END ) as down  
    from #T_autodata autodata   
    inner join #FinalTarget F on autodata.mc = F.Machineinterface and autodata.comp=F.Compinterface and autodata.opn=F.Opninterface   
    inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid  
  where (autodata.datatype=2) AND  
    (( (autodata.msttime>=F.BatchStart) and (autodata.ndtime<=F.BatchEnd))  
       OR ((autodata.msttime<F.BatchStart)and (autodata.ndtime>F.BatchStart)and (autodata.ndtime<=F.BatchEnd))  
       OR ((autodata.msttime>=F.BatchStart)and (autodata.msttime<F.BatchEnd)and (autodata.ndtime>F.BatchEnd))  
       OR((autodata.msttime<F.BatchStart)and (autodata.ndtime>F.BatchEnd)))   
    AND (downcodeinformation.availeffy = 0)  
       group by F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface  
 ) as t2 Inner Join #FinalTarget on t2.machineinterface = #FinalTarget.machineinterface and  
 t2.compinterface = #FinalTarget.compinterface and t2.opninterface = #FinalTarget.opninterface   
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  
  
  
 UPDATE  #FinalTarget SET Downtime = isnull(Downtime,0) - isNull(T2.PPDT ,0)  
 FROM(  
 SELECT F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,  
    SUM  
    (CASE  
    WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)  
    WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
    WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )  
    WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
    END ) as PPDT  
    FROM #T_autodata AutoData  
    CROSS jOIN #PlannedDownTimes T  
    INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID  
    INNER JOIN #FinalTarget F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn   
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
     group  by F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface 
 )AS T2  Inner Join #FinalTarget on t2.machineinterface = #FinalTarget.machineinterface and  
 t2.compinterface = #FinalTarget.compinterface and t2.opninterface = #FinalTarget.opninterface   
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  
  
 UPDATE #FinalTarget SET ManagementLoss = isnull(ManagementLoss,0)+ isNull(t4.Mloss,0),MLDown=isNull(MLDown,0)+isNull(t4.Dloss,0)  
 from  
 (select T3.mc,T3.comp,T3.opn,T3.Batchstart as Batchstart,T3.Batchend as Batchend,sum(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss from  
  (  
 select   T1.id,T1.mc,T1.comp,T1.opn,T1.Threshold,T1.Batchstart as Batchstart,T1.Batchend as Batchend,  
 case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0) > 0  
 then DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)- isnull(T1.Threshold ,0)  
 else 0 End  as Dloss,  
 case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0) > 0  
 then isnull(T1.Threshold,0)  
 else DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0) End  as Mloss  
  from  
   
  (     
   select id,mc,comp,opn,D.threshold,S.Batchstart as Batchstart,S.BatchEnd as BatchEnd,  
   case when autodata.sttime<S.Batchstart then S.Batchstart else sttime END as sttime,  
   case when ndtime>S.BatchEnd then S.BatchEnd else ndtime END as ndtime  
   from #T_autodata autodata   
   inner join downcodeinformation D on autodata.dcode=D.interfaceid   
   INNER JOIN #FinalTarget S on S.machineinterface=Autodata.mc and S.Compinterface=Autodata.comp and S.Opninterface = Autodata.opn   
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
   SELECT id,F.BatchStart,F.BatchEnd,mc,comp,opn,  
   SUM  
   (CASE  
   WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)  
   WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
   WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )  
   WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
   END ) as PPDT  
   FROM #T_autodata AutoData  
   CROSS jOIN #PlannedDownTimes T  
   INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID  
   INNER JOIN #FinalTarget F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn   
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
    group  by id,F.BatchStart,F.BatchEnd,mc,comp,opn  
  ) as T2 on T1.id=T2.id and T1.mc=T2.mc and T1.comp=T2.comp and T1.opn=T2.opn  and T1.Batchstart=T2.Batchstart and T1.Batchend=T2.Batchend ) as T3  group by T3.mc,T3.comp,T3.opn,T3.Batchstart,T3.Batchend  
 ) as t4 Inner Join #FinalTarget on t4.mc = #FinalTarget.machineinterface and  
 t4.comp = #FinalTarget.compinterface and t4.opn = #FinalTarget.opninterface    
 and t4.BatchStart=#FinalTarget.BatchStart and t4.BatchEnd=#FinalTarget.BatchEnd  
  
 UPDATE #FinalTarget  set downtime = isnull(downtime,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)  
END  
  


  
--Calculation of PartsCount Begins..  
UPDATE #FinalTarget SET components = ISNULL(components,0) + ISNULL(t2.comp1,0),CN = isnull(CN,0) + isNull(t2.C1N1,0)  
From  
(  
 Select T1.mc,T1.comp,T1.opn,T1.Batchstart,T1.Batchend,
 SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp1,
SUM((O.cycletime/ISNULL(O.SubOperations,1))* T1.OrginalCount) C1N1
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
    
 UPDATE #FinalTarget SET components=ISNULL(components,0)- isnull(t2.PlanCt,0) ,CN = isnull(CN,0) - isNull(t2.C1N1,0) 
  FROM ( select autodata.mc,autodata.comp,autodata.opn,F.Batchstart,F.Batchend,
  ((CAST(Sum(ISNULL(PartsCount,1)) AS Float)/ISNULL(CO.SubOperations,1))) as PlanCt,
	SUM((CO.cycletime * ISNULL(PartsCount,1))/ISNULL(CO.SubOperations,1))  C1N1
   from #T_autodata autodata   
     INNER JOIN #FinalTarget F on F.machineinterface=autodata.mc and F.Compinterface=autodata.comp and F.Opninterface = autodata.opn 
  Inner jOIN #PlannedDownTimes T on T.MachineInterface=autodata.mc    
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
 
 
--------------------------------------------Rejcount cal starts--------------------------------------------------------
Update #FinalTarget set RejCount = isnull(RejCount,0) + isnull(T1.RejQty,0)
From
( Select A.mc,a.comp,a.opn,SUM(A.Rejection_Qty) as RejQty,M.Machineid,BatchStart,BatchEnd from AutodataRejections A
inner join Machineinformation M on A.mc=M.interfaceid
inner join #FinalTarget on #FinalTarget.MachineID=M.machineid and #FinalTarget.Compinterface=a.comp and #FinalTarget.OpnInterface=a.opn
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
where A.CreatedTS>=BatchStart and A.CreatedTS<BatchEnd and A.flag = 'Rejection'
and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000'
group by A.mc,M.Machineid,a.comp,a.opn,BatchStart,BatchEnd
)T1 inner join #FinalTarget B on B.MachineID=T1.Machineid and b.Compinterface=t1.comp and b.OpnInterface=t1.opn AND B.BatchStart=T1.BatchStart AND B.BatchEnd=T1.BatchEnd

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	Update #FinalTarget set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from
	(Select A.mc,a.comp,a.opn,SUM(A.Rejection_Qty) as RejQty,M.Machineid,BatchStart,BatchEnd from AutodataRejections A
	inner join Machineinformation M on A.mc=M.interfaceid 
	inner join #FinalTarget on #FinalTarget.MachineID=M.machineid and #FinalTarget.Compinterface=a.comp and #FinalTarget.OpnInterface=a.opn
	inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
	Cross join Planneddowntimes P
	where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid 
	and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000' and
	A.CreatedTS>=BatchStart and A.CreatedTS<BatchEnd And
	A.CreatedTS>=P.Starttime and A.CreatedTS<P.endtime
	group by A.mc,M.Machineid,a.comp,a.opn,BatchStart,BatchEnd
  )T1 inner join #FinalTarget B on B.MachineID=T1.Machineid and b.Compinterface=t1.comp and b.OpnInterface=t1.opn AND B.BatchStart=T1.BatchStart AND B.BatchEnd=T1.BatchEnd
END

Update #FinalTarget set RejCount = isnull(RejCount,0) + isnull(T1.RejQty,0)
From
(Select A.mc,a.comp,a.opn, SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A
inner join Machineinformation M on A.mc=M.interfaceid
inner join #FinalTarget on #FinalTarget.MachineID=M.machineid and #FinalTarget.Compinterface=a.comp and #FinalTarget.OpnInterface=a.opn
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
inner join #shift S on convert(nvarchar(10),(A.RejDate),126)=convert(nvarchar(10),(S.shiftdate),126) and A.RejShift=S.shiftid --DR0333
where A.flag = 'Rejection' and A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (convert(nvarchar(10),(S.shiftdate),126)) and  --DR0333
Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
group by A.mc,M.Machineid,a.comp,a.opn
)T1 inner join #FinalTarget B on B.MachineID=T1.Machineid and b.Compinterface=t1.comp and b.OpnInterface=t1.opn 

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	Update #FinalTarget set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from
	(Select A.mc,a.comp,a.opn,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A
	inner join Machineinformation M on A.mc=M.interfaceid
	inner join #FinalTarget on #FinalTarget.MachineID=M.machineid and #FinalTarget.Compinterface=a.comp and #FinalTarget.OpnInterface=a.opn
	inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
	inner join #shift S on convert(nvarchar(10),(A.RejDate),126)=convert(nvarchar(10),(S.shiftdate),126) and A.RejShift=S.shiftid --DR0333
	Cross join Planneddowntimes P
	where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid and
	A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (convert(nvarchar(10),S.shiftdate,126)) and --DR0333
	Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
	and P.starttime>=S.Shiftstart and P.Endtime<=S.shiftend
	group by A.mc,M.Machineid,a.comp,a.opn
	)T1 inner join #FinalTarget B on B.MachineID=T1.Machineid and b.Compinterface=t1.comp and b.OpnInterface=t1.opn 
END
-------------------------------------------------Rejcount cal ends-----------------------------------------------

update #FinalTarget set stdTime=(t1.StdCycleTime),Avgcycletime=(t1.AvgCycleTime),MinCycleTime=(t1.MinCycleTime),MaxCycleTime=(t1.MaxCycleTime),StdLoadUnload=(t1.StdLoadUnload),MinLoadUnload=(T1.MinLoadUnload),
MaxLoadUnload=(T1.MaxLoadUnload),SpeedRation=(T1.SpeedRation)
from
(
SELECT DISTINCT M.MachineID,machineinterface ,M.Description,C.ComponentID,Compinterface,O.OperationNo,OpnInterface,
	O.MachiningTime  AS StdCycleTime,batchstart,batchend,
	AVG(A.Cycletime/A.partscount)* ISNULL(O.SubOperations,1) AS AvgCycleTime,
	Min(A.Cycletime/A.partscount)* ISNULL(O.SubOperations,1) AS MinCycleTime,
	Max(A.Cycletime/A.partscount)* ISNULL(O.SubOperations,1) AS MaxCycleTime,
	CASE WHEN (AVG(A.Cycletime/A.partscount)*ISNULL(O.SubOperations,1))>0 THEN 
	O.MachiningTime /(AVG(A.Cycletime/A.partscount)*ISNULL(O.SubOperations,1)) ELSE 0 END AS SpeedRation,
	(O.CycleTime - O.MachiningTime) AS StdLoadUnload,
	Min(A.loadunload/A.partscount)* ISNULL(O.SubOperations,1) AS MinLoadUnload,
	Max(A.loadunload/A.partscount)* ISNULL(O.SubOperations,1) AS MaxLoadUnload
	FROM #T_autodata A Inner Join MachineInformation M ON A.mc=M.InterfaceID Inner Join  ComponentInformation C ON A.Comp=C.InterfaceID 
 inner join #FinalTarget S on a.mc = S.Machineinterface and a.comp=S.Compinterface and a.opn=S.Opninterface   
	 Inner Join ComponentOperationPricing O ON A.Opn=O.InterfaceID AND C.ComponentID=O.ComponentID AND M.MachineID=O.MachineID 
	 WHERE DataType=1  and (a.ndtime>S.BatchStart and a.ndtime<=S.BatchEnd  )
	 and A.PartsCount > 0
	Group By M.MachineID,machineinterface,M.Description,C.ComponentID,Compinterface,O.OperationNo,OpnInterface,O.MachiningTime,O.CycleTime,O.SubOperations,BatchStart,BatchEnd 
	)t1 inner join #FinalTarget F ON F.MachineID=T1.machineid AND F.ComponenT=T1.componentid AND F.Operation=T1.operationno AND F.BatchStart=T1.BatchStart AND F.BatchEnd=T1.BatchEnd


Update #FinalTarget set 
AvgLoadUnload = ISNULL(T1.AvgLoadUnload,0),LoadRation = ISNULL(T1.LoadRation,0)from
(
SELECT DISTINCT M.MachineID,C.ComponentID,O.OperationNo ,batchstart,batchend,AVG(A.loadunload/A.partscount)*ISNULL(O.SubOperations,1) AS AvgLoadUnload ,
CASE WHEN (AVG(A.loadunload/A.partscount)* ISNULL(O.SubOperations,1))>0 THEN (O.CycleTime - O.MachiningTime)/(AVG(A.loadunload/A.partscount)* ISNULL(O.SubOperations,1)) ELSE 0 END AS LoadRation  
FROM #T_autodata  A  inner join #FinalTarget S on a.mc = S.Machineinterface and a.comp=S.Compinterface and a.opn=S.Opninterface   
Inner join MachineInformation M ON A.mc=M.InterfaceID Inner Join  ComponentInformation C 
ON A.Comp=C.InterfaceID Inner Join ComponentOperationPricing O ON A.Opn=O.InterfaceID AND C.ComponentID=O.ComponentID and O.MachineID = M.MachineID 
WHERE DataType=1 And partscount >0  and (a.ndtime>S.BatchStart and a.ndtime<=S.BatchEnd  )
Group By M.MachineID,C.ComponentID,O.OperationNo,BatchStart,BatchEnd,O.SubOperations,O.CycleTime,O.MachiningTime 
)t1 inner join #FinalTarget F ON F.MachineID=T1.machineid AND F.ComponenT=T1.componentid AND F.Operation=T1.operationno AND F.BatchStart=T1.BatchStart AND F.BatchEnd=T1.BatchEnd


  ------------------------------------------------------------------------------loadunload time cal starts (msttime to sttime)------------------------------------------------------------------------------------------------------------------------------


UPDATE #FinalTarget SET TotalLoadUnload = isnull(TotalLoadUnload,0) + isNull(t2.ld,0)  
from  
(select S.MachineID,S.Component,S.operation,S.BatchStart,S.BatchEnd,  
 sum(case when ((autodata.msttime>=S.BatchStart) and (autodata.sttime<=S.BatchEnd)) then  DateDiff(second,autodata.msttime,autodata.sttime)  
   when ((autodata.msttime<S.BatchStart)and (autodata.sttime>S.BatchStart)and (autodata.sttime<=S.BatchEnd)) then DateDiff(second, S.BatchStart, autodata.sttime)  
   when ((autodata.msttime>=S.BatchStart)and (autodata.msttime<S.BatchEnd)and (autodata.sttime>S.BatchEnd)) then DateDiff(second, autodata.msttime, S.BatchEnd)  
   when ((autodata.msttime<S.BatchStart)and (autodata.sttime>S.BatchEnd)) then DateDiff(second, S.BatchStart, S.BatchEnd) END ) as ld  
from #T_autodata autodata   
inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface  
where (autodata.datatype=1) AND(( (autodata.msttime>=S.BatchStart) and (autodata.ndtime<=S.BatchEnd))  
OR ((autodata.msttime<S.BatchStart)and (autodata.ndtime>S.BatchStart)and (autodata.ndtime<=S.BatchEnd))  
OR ((autodata.msttime>=S.BatchStart)and (autodata.msttime<S.BatchEnd)and (autodata.ndtime>S.BatchEnd))  
OR((autodata.msttime<S.BatchStart)and (autodata.ndtime>S.BatchEnd)))  
group by S.MachineID,S.Component,S.operation,S.BatchStart,S.BatchEnd  
) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and   
t2.operation = #FinalTarget.operation and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'  
BEGIN  
   
 --Get the utilised time overlapping with PDT and negate it from UtilisedTime  
  UPDATE  #FinalTarget SET TotalLoadUnload = isnull(TotalLoadUnload,0) - isNull(T2.ldunload ,0)  
  FROM(  
  SELECT F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,  
    sum(case
			WHEN AutoData.msttime >= T.StartTime  AND Autodata.sttime <=T.EndTime  THEN DateDiff(second,Autodata.msttime,Autodata.sttime)
			WHEN ( Autodata.msttime < T.StartTime  AND Autodata.sttime <= T.EndTime  AND Autodata.sttime > T.StartTime ) THEN DateDiff(second,T.StartTime,Autodata.sttime)
			WHEN ( Autodata.msttime >= T.StartTime   AND Autodata.msttime <T.EndTime  AND Autodata.sttime > T.EndTime  ) THEN DateDiff(second,Autodata.msttime,T.EndTime )
			WHEN ( Autodata.msttime < T.StartTime  AND Autodata.sttime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END)   as ldunload  
     FROM #T_autodata AutoData  
     CROSS jOIN #PlannedDownTimes T  
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
end

  -----------------------------------------------------------------------------------------loadunload time  cal ends-----------------------------------------------------------------------------------------------------------------------



------------------------------------------------------------------------------Machining time cal starts------------------------------------------------------------------------------------------------------------------------------


UPDATE #FinalTarget SET MachiningTime = isnull(MachiningTime,0) + isNull(t2.mctime,0)  
from  
(select S.MachineID,S.Component,S.operation,S.BatchStart,S.BatchEnd,  
 sum(case when ((autodata.sttime>=S.BatchStart) and (autodata.ndtime<=S.BatchEnd)) then  (autodata.cycletime)  
   when ((autodata.sttime<S.BatchStart)and (autodata.ndtime>S.BatchStart)and (autodata.ndtime<=S.BatchEnd)) then DateDiff(second, S.BatchStart, autodata.ndtime)  
   when ((autodata.sttime>=S.BatchStart)and (autodata.sttime<S.BatchEnd)and (autodata.ndtime>S.BatchEnd)) then DateDiff(second, autodata.sttime, S.BatchEnd)  
   when ((autodata.sttime<S.BatchStart)and (autodata.ndtime>S.BatchEnd)) then DateDiff(second, S.BatchStart, S.BatchEnd) END ) as mctime  
from #T_autodata autodata   
inner join #FinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface  
where (autodata.datatype=1) AND(( (autodata.msttime>=S.BatchStart) and (autodata.ndtime<=S.BatchEnd))  
OR ((autodata.msttime<S.BatchStart)and (autodata.ndtime>S.BatchStart)and (autodata.ndtime<=S.BatchEnd))  
OR ((autodata.msttime>=S.BatchStart)and (autodata.msttime<S.BatchEnd)and (autodata.ndtime>S.BatchEnd))  
OR((autodata.msttime<S.BatchStart)and (autodata.ndtime>S.BatchEnd)))  
group by S.MachineID,S.Component,S.operation,S.BatchStart,S.BatchEnd  
) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and   
t2.operation = #FinalTarget.operation and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'  
BEGIN  
   
 --Get the utilised time overlapping with PDT and negate it from UtilisedTime  
  UPDATE  #FinalTarget SET MachiningTime = isnull(MachiningTime,0) - isNull(T2.PPDT ,0)  
  FROM(  
  SELECT F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,  
     SUM  
     (CASE  
     WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.cycletime) --DR0325 Added  
     WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
     WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )  
     WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
     END ) as PPDT  
     FROM #T_autodata AutoData  
     CROSS jOIN #PlannedDownTimes T  
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
end

  -----------------------------------------------------------------------------------------Machining time  cal ends-----------------------------------------------------------------------------------------------------------------------


UPDATE #FinalTarget SET QualityEfficiency= ISNULL(QualityEfficiency,0) + IsNull(T1.QE,0) 
FROM(Select MachineID,Component,Operation,
CAST((Sum(Components))As Float)/CAST((Sum(IsNull(Components,0))+Sum(IsNull(RejCount,0))) AS Float)As QE
From #FinalTarget Where Components<>0 Group By MachineID,Component,Operation
)AS T1 Inner Join #FinalTarget ON  #FinalTarget.MachineID=T1.MachineID and #FinalTarget.Component=t1.Component and #FinalTarget.Operation=t1.Operation


UPDATE #FinalTarget
SET
	ProductionEfficiency = (CN/UtilisedTime) ,
	AvailabilityEfficiency = (UtilisedTime)/(UtilisedTime + DownTime - ManagementLoss) WHERE UtilisedTime <> 0

UPDATE #FinalTarget
SET
	OverAllEfficiency = (ProductionEfficiency * AvailabilityEfficiency*QualityEfficiency)*100, 
	ProductionEfficiency = ProductionEfficiency * 100 ,
	AvailabilityEfficiency = AvailabilityEfficiency * 100,
	QualityEfficiency=QualityEfficiency*100


--SELECT Component AS ComponentID,Operation AS OperationNo,F.MACHINEID AS MachineID,M.description AS Machinedescription,
--BatchStart,BatchEnd,
--dbo.f_formattime(MachiningTime,@TimeFormat) as MachiningTime,
--dbo.f_formattime(TotalLoadUnload,@TimeFormat) as loadunload,
--dbo.f_formattime(Utilisedtime,@TimeFormat) as UtilisedTime,
--Components AS ProdCount,
--ISNULL(REJCOUNT,0) AS Rejcount,
----CN as CN,
--dbo.f_formattime(Downtime,@TimeFormat) as DownTime,
--dbo.f_formattime(stdtime,@TimeFormat) as StdCycleTime,
--dbo.f_formattime(Avgcycletime,@TimeFormat) as AvgCycleTime,
--dbo.f_formattime(mincycletime,@TimeFormat) as MinCycleTime,
--dbo.f_formattime(MaxCycleTime,@TimeFormat) as MaxCycleTime,
-- round(isnull(SpeedRation,0),2) AS SpeedRation,
--dbo.f_formattime(StdLoadUnload,@TimeFormat) as StdLoadUnload,
--dbo.f_formattime(AvgLoadUnload,@TimeFormat) as AvgLoadUnload,
--dbo.f_formattime(MinLoadUnload,@TimeFormat) as MinLoadUnload,
--dbo.f_formattime(MaxLoadUnload,@TimeFormat) as MaxLoadUnload,
-- round(isnull(LoadRation,0),2) AS LoadRation,
--ROUND(Isnull(AvailabilityEfficiency,0),2) as AvailabilityEfficiency,
--ROUND(Isnull(ProductionEfficiency,0),2) as ProductionEfficiency,
--ROUND(Isnull(QualityEfficiency,0),2) as QualityEfficiency,
--ROUND(Isnull(OverAllEfficiency,0),2) as OverAllEfficiency
-- FROM #FinalTarget F
--LEFT OUTER JOIN machineinformation M ON M.machineid=F.MachineID
--where Components>0
--Order by component,BatchStart ASC


select @strsql=''
select @strsql=@strsql+'SELECT distinct Component AS ComponentID,Operation AS OperationNo,F.MACHINEID AS MachineID,M.description AS Machinedescription,
BatchStart,BatchEnd,
dbo.f_formattime(f.MachiningTime,'''+@TimeFormat+''') as MachiningTime,
f.MachiningTime as MachiningTimeInsec,
dbo.f_formattime(f.TotalLoadUnload,'''+@TimeFormat+''') as Loadunload,
f.TotalLoadUnload as LoadUnloadInSec,
dbo.f_formattime(Utilisedtime,'''+@TimeFormat+''') as UtilisedTime,
f.UtilisedTime as UtilisedTimeinsec,
Components AS ProdCount,
ISNULL(REJCOUNT,0) AS Rejcount,
--CN as CN,
dbo.f_formattime(Downtime,'''+@TimeFormat+''') as DownTime,
f.downtime as DownTimeInsec,
dbo.f_formattime(stdtime,'''+@TimeFormat+''') as StdCycleTime,
dbo.f_formattime(Avgcycletime,'''+@TimeFormat+''') as AvgCycleTime,
dbo.f_formattime(mincycletime,'''+@TimeFormat+''') as MinCycleTime,
dbo.f_formattime(MaxCycleTime,'''+@TimeFormat+''') as MaxCycleTime,
 round(isnull(SpeedRation,0),2) AS SpeedRation,
dbo.f_formattime(StdLoadUnload,'''+@TimeFormat+''') as StdLoadUnload,
dbo.f_formattime(AvgLoadUnload,'''+@TimeFormat+''') as AvgLoadUnload,
dbo.f_formattime(MinLoadUnload,'''+@TimeFormat+''') as MinLoadUnload,
dbo.f_formattime(MaxLoadUnload,'''+@TimeFormat+''') as MaxLoadUnload,
 round(isnull(LoadRation,0),2) AS LoadRation,
ROUND(Isnull(AvailabilityEfficiency,0),2) as AvailabilityEfficiency,
ROUND(Isnull(ProductionEfficiency,0),2) as ProductionEfficiency,
ROUND(Isnull(QualityEfficiency,0),2) as QualityEfficiency,
ROUND(Isnull(OverAllEfficiency,0),2) as OverAllEfficiency
 FROM #FinalTarget F
LEFT OUTER JOIN machineinformation M ON M.machineid=F.MachineID
left outer join componentinformation on componentinformation.componentid=f.Component
left outer join componentoperationpricing on componentoperationpricing.machineid=m.machineid and componentoperationpricing.componentid=componentinformation.componentid
where Components>0 '
select @StrSql=@StrSql + @StrCompOpn + @StrOpn
select @strsql=@strsql + 'Order by component,BatchStart ASC '
print(@strsql)
exec(@strsql)

select @strsql='select t1.Componentid,dbo.f_formattime(isnull(sum(t1.MachiningTimeInsec),0),'''+@TimeFormat+''') as TotalMachineingTime,
dbo.f_formattime(isnull(sum(t1.LoadUnloadInSec),0),'''+@TimeFormat+''') as TotalLoadUnloadInSec,dbo.f_formattime(isnull(sum(t1.DownTimeInsec),0),'''+@TimeFormat+''') as TotalDownTimeInsec,
round(isnull(avg(t1.AvailabilityEfficiency),0),2) as AE,
round(isnull(avg(t1.ProductionEfficiency),0),2) as PE,
round(isnull(avg(t1.QualityEfficiency),0),2) as QE,
round(isnull(avg(t1.OverAllEfficiency),0),2) as oee FROM ( '
select @strsql=@strsql+'SELECT distinct Component AS ComponentID,Operation AS OperationNo,F.MACHINEID AS MachineID,M.description AS Machinedescription,
BatchStart,BatchEnd,
dbo.f_formattime(f.MachiningTime,'''+@TimeFormat+''') as MachiningTime,
f.MachiningTime as MachiningTimeInsec,
dbo.f_formattime(f.TotalLoadUnload,'''+@TimeFormat+''') as Loadunload,
f.TotalLoadUnload as LoadUnloadInSec,
dbo.f_formattime(Utilisedtime,'''+@TimeFormat+''') as UtilisedTime,
f.UtilisedTime as UtilisedTimeinsec,
Components AS ProdCount,
ISNULL(REJCOUNT,0) AS Rejcount,
--CN as CN,
dbo.f_formattime(Downtime,'''+@TimeFormat+''') as DownTime,
f.downtime as DownTimeInsec,
dbo.f_formattime(stdtime,'''+@TimeFormat+''') as StdCycleTime,
dbo.f_formattime(Avgcycletime,'''+@TimeFormat+''') as AvgCycleTime,
dbo.f_formattime(mincycletime,'''+@TimeFormat+''') as MinCycleTime,
dbo.f_formattime(MaxCycleTime,'''+@TimeFormat+''') as MaxCycleTime,
 round(isnull(SpeedRation,0),2) AS SpeedRation,
dbo.f_formattime(StdLoadUnload,'''+@TimeFormat+''') as StdLoadUnload,
dbo.f_formattime(AvgLoadUnload,'''+@TimeFormat+''') as AvgLoadUnload,
dbo.f_formattime(MinLoadUnload,'''+@TimeFormat+''') as MinLoadUnload,
dbo.f_formattime(MaxLoadUnload,'''+@TimeFormat+''') as MaxLoadUnload,
 round(isnull(LoadRation,0),2) AS LoadRation,
ROUND(Isnull(AvailabilityEfficiency,0),2) as AvailabilityEfficiency,
ROUND(Isnull(ProductionEfficiency,0),2) as ProductionEfficiency,
ROUND(Isnull(QualityEfficiency,0),2) as QualityEfficiency,
ROUND(Isnull(OverAllEfficiency,0),2) as OverAllEfficiency
 FROM #FinalTarget F
LEFT OUTER JOIN machineinformation M ON M.machineid=F.MachineID
left outer join componentinformation on componentinformation.componentid=f.Component
left outer join componentoperationpricing on componentoperationpricing.machineid=m.machineid and componentoperationpricing.componentid=componentinformation.componentid
where Components>0 '
select @StrSql=@StrSql + @StrCompOpn + @StrOpn
select @strsql=@strsql + ')t1 '
select @StrSql=@StrSql + 'group by t1.ComponentID order by t1.ComponentID '
print(@strsql)
exec(@strsql)
 
end  
