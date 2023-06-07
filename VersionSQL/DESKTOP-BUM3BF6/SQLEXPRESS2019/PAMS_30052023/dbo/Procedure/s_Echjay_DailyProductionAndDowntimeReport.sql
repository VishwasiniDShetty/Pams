/****** Object:  Procedure [dbo].[s_Echjay_DailyProductionAndDowntimeReport]    Committed by VersionSQL https://www.versionsql.com ******/

  
/*****************************************************************************************************  
--NR0129 - 20/Oct/2016 - SwathiKS - Created New Procedure to show Daily Production and Down details for Echjay. 
DR0379 - SwathiKS - 30/Nov/2017 :: To handle error invalid object name #PlannedDownShift 
ER0465 - Gopinath - 16/may/2018 :: Performance Optimization(handling while loop logic).

--s_Echjay_DailyProductionAndDowntimeReport '2017-11-21','','','','','2017-11-22'  
*****************************************************************************************************/  
  
CREATE PROCEDURE [dbo].[s_Echjay_DailyProductionAndDowntimeReport]  
 @StartDate datetime,  
 @MachineID nvarchar(50) = '',  
 @ComponentID nvarchar(50) = '',  
 @OperationNo nvarchar(50) = '',  
 @PlantID  Nvarchar(50) = '',  
 @EndDate datetime,  
 @Param nvarchar(50)=''  
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
  
Declare @strsql nvarchar(4000)  
Declare @strmachine nvarchar(255)  
Declare @strcomponentid nvarchar(255)  
Declare @stroperation nvarchar(255)  
Declare @StrTPMMachines AS nvarchar(500)  
Declare @StrMPlantid NVarChar(255)  
Declare @timeformat as nvarchar(12)  
Declare @StartTime as datetime  
Declare @EndTime as datetime  
Declare @strXmachine NVarChar(255)  
Declare @strXcomponentid NVarChar(255)  
Declare @strXoperation NVarChar(255)  
Select @strsql = ''  
Select @strcomponentid = ''  
Select @stroperation = ''  
Select @StrTPMMachines = ''  
Select @strmachine = ''  
Select @StrMPlantid=''  
Select @strXmachine =''  
Select @strXcomponentid =''  
Select @strXoperation =''  
-- mod 4  
IF ( SELECT TOP 1 ValueInText FROM  CockpitDefaults WHERE Parameter='TpmEnbMac')='E'  
BEGIN  
 SET  @StrTPMMachines = 'AND MachineInformation.TPMTrakEnabled = 1'  
END  
ELSE  
BEGIN  
 SET  @StrTPMMachines = ' '  
END  
--mod 4  
if isnull(@PlantID,'') <> ''  
Begin  
  
 Select @StrMPlantid = ' and ( PlantMachine.PlantID = N''' + @PlantID + ''')'  
End  
if isnull(@machineid,'') <> ''  
Begin  
  
 Select @strmachine = ' and ( Machineinformation.MachineID = N''' + @MachineID + ''')'  
End  
if isnull(@componentid,'') <> ''  
Begin  
  
 Select @strcomponentid = '  AND ( Componentinformation.componentid = N''' + @componentid + ''')'  
  
End  
if isnull(@operationno, '') <> ''  
Begin  
  
 Select @stroperation = ' AND ( Componentoperationpricing.operationno = N''' + @OperationNo + ''')'  
  
End  
  
CREATE TABLE #DailyProductionFromAutodataT0   
(  
 DDate datetime,  
 Shift nvarchar(20),  
 ShiftStart datetime,  
 ShiftEnd datetime  
)  
  
--Machine level details  
CREATE TABLE #DailyProductionFromAutodataT1   
(  
 MachineID nvarchar(50) NOT NULL,  
 MachineInterface nvarchar(50),  
 ProductionEfficiency float,  
 AvailabilityEfficiency float,  
 OverallEfficiency float,  
 UtilisedTime float,  
 ManagementLoss float,  
 DownTime float,  
 CN float,  
 Pdate datetime NOT NULL,  
 FromTime datetime,  
 ToTime datetime,  
 MLDown float,  
 A  float,  
 B  float,  
 C  float,  
 D  float,  
 E  float,  
 F  float,  
 G  float,  
 NonproductiveTime float  
)  
  
ALTER TABLE #DailyProductionFromAutodataT1 ADD  
  PRIMARY KEY  CLUSTERED  
 (       [Pdate],  
  [MachineID]  
 )  ON [PRIMARY]  
  
--ComponentOperation level details  
CREATE TABLE #DailyProductionFromAutodataT2 (  
 Cdate datetime not null,  
 MachineID nvarchar(50) NOT NULL,  
 Component nvarchar(50) NOT NULL,  
 Operation nvarchar(50) NOT NULL,  
 CycleTime float,  
 LoadUnload float,  
 CountShift1 float,  
 CountShift2 float,  
 CountShift3 float,  
 NameShift1 nvarchar(20),  
 NameShift2 nvarchar(20),  
 NameShift3 nvarchar(20),  
 TargetCount int Default 0,  
 FromTm datetime,  
 ToTm datetime,  
    ProdPerHour float,  
 ProdTotal float,  
 WorkingHours float,  
 CummCount float  
)  
ALTER TABLE #DailyProductionFromAutodataT2 ADD  
  PRIMARY KEY  CLUSTERED  
 (  
  [Cdate],[MachineID],[Component],[Operation]  
    
 )  ON [PRIMARY]  
  
Create table #PlannedDownTimes  
(  
 MachineID nvarchar(50),  
 MachineInterface nvarchar(50),  
 StartTime_LogicalDay DateTime,  
 EndTime_LogicalDay DateTime,  
 StartTime_PDT DateTime,  
 EndTime_PDT DateTime,  
 pPlannedDT float Default 0,  
 dPlannedDT float Default 0,  
 MPlannedDT float Default 0,  
 IPlannedDT float Default 0,  
 DownID nvarchar(50)  
)  
  
Create table #Downcode  
(  
 Slno int identity(1,1) NOT NULL,  
 Downid nvarchar(50)  
)  
  
Insert into #Downcode(Downid)  
Select top 7 downid from downcodeinformation where   
SortOrder<=15 and SortOrder IS NOT NULL order by sortorder  
  
If @param = 'DownCodeList'  
Begin  
 select downid from #Downcode order by slno  
 return  
end   
  
  
declare @lstart nvarchar(50)  --ER0465
declare @lend nvarchar(50)  --ER0465

declare @Targetsource nvarchar(50)  
select @Targetsource=ValueInText from Shopdefaults where Parameter='TargetFrom'  

  
select @StartTime=@StartDate  
select @EndTime=@EndDate  
while @StartTime<=@EndTime  
BEGIN  

SET @lstart = dbo.f_GetLogicalDay(@StartTime,'start') --ER0465
SET @lend = dbo.f_GetLogicalDay(@StartTime,'End') --ER0465

 If ISNULL(@PlantID,'')<>''  
 BEGIN  

  if isnull(@machineid,'')<> ''  
  begin  
   INSERT INTO #DailyProductionFromAutodataT1 (MachineID,MachineInterface,ProductionEfficiency,  
   AvailabilityEfficiency,OverallEfficiency,UtilisedTime,ManagementLoss,DownTime,CN,Pdate,FromTime,ToTime)  
   SELECT M.MachineID, M.interfaceid ,0,0,0,0,0,0,0,convert(nvarchar(20),@StartTime),  
   @lstart,@lend  
   FROM MachineInformation M Inner Join PlantMachine PM ON PM.MachineID=M.MachineID  
   WHERE M.MachineID = @machineid AND PM.PlantID=@PlantID  
  end  
  else  
  begin  
   INSERT INTO #DailyProductionFromAutodataT1 (MachineID,MachineInterface,ProductionEfficiency,  
   AvailabilityEfficiency,OverallEfficiency,UtilisedTime,ManagementLoss,DownTime,CN,Pdate,FromTime,ToTime)  
   SELECT M.MachineID, M.interfaceid ,0,0,0,0,0,0,0,convert(nvarchar(20),@StartTime),  
   @lstart,@lend  
   FROM MachineInformation M Inner Join PlantMachine PM ON PM.MachineID=M.MachineID  
   where interfaceid > '0' AND PM.PlantID=@PlantID  
  end  
 END  
 ELSE  
 BEGIN  
  SELECT @StrSql=''  
  SELECT @StrSql='INSERT INTO #DailyProductionFromAutodataT1 ('  
  SELECT @StrSql=@StrSql+' MachineID ,MachineInterface,ProductionEfficiency ,AvailabilityEfficiency ,'     
  SELECT @StrSql=@StrSql+' OverallEfficiency ,UtilisedTime ,ManagementLoss,DownTime ,CN,Pdate,FromTime,ToTime)'  
  SELECT @StrSql=@StrSql+' SELECT MachineID, interfaceid ,0,0,0,0,0,0,0,''' +convert(nvarchar(20),@StartTime)+ ''', '  
  SELECT @StrSql=@StrSql+' ''' +@lstart+ ''',''' +@lend+ ''' '  
  SELECT @StrSql=@StrSql+' FROM MachineInformation where interfaceid >''0'''  
  SELECT @StrSql=@StrSql+ @strmachine  
  Exec(@StrSql)  
  SELECT @StrSql=''  
 END  
   
 --mod 4 Get the Machines into #PLD  
 Insert into #PlannedDownTimes  
 Select machineinformation.MachineID,machineinformation.InterfaceID,@lstart,@lend,  
  Case When StartTime<@lstart Then @lstart Else StartTime End as StartTime,    
  Case When EndTime > @lend Then @lend Else EndTime End as EndTime,  
  0,0,0,0,PlannedDownTimes.DownReason  
  from PlannedDownTimes inner join machineinformation on PlannedDownTimes.machine=machineinformation.machineid  
       Where PlannedDownTimes.PDTstatus =1 AND (  
  (StartTime >= @lstart and EndTime <= @lend) OR  
  (StartTime < @lstart and EndTime <= @lend and EndTime > @lstart) OR  
  (StartTime >= @lstart and EndTime > @lend and StartTime < @lend) OR  
  (StartTime < @lstart and EndTime > @lend))  
  And machineinformation.MachineID in (select distinct MachineID from #DailyProductionFromAutodataT1)  
 --mod 4  
 SELECT @StartTime=DATEADD(DAY,1,@StartTime)  
END  
  
-- Get the utilised time  
-- Type 1  
UPDATE #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0) from (  
 select mc,sum(cycletime+loadunload) as cycle,D.Pdate as date1  
 from autodata inner join #DailyProductionFromAutodataT1 D on autodata.mc=D.machineinterface  
 where (autodata.msttime>=D.FromTime)and (autodata.ndtime<=D.ToTime)and (autodata.datatype=1)  
 group by autodata.mc,D.Pdate  
) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface  
and t2.date1=#DailyProductionFromAutodataT1.Pdate  
--Type 2  
UPDATE #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0) from (  
 select mc,sum(DateDiff(second, D.FromTime, ndtime)) cycle,D.Pdate as date1  
 from autodata inner join #DailyProductionFromAutodataT1 D on autodata.mc=D.machineinterface  
 where (autodata.msttime<D.FromTime)and (autodata.ndtime>D.FromTime)and (autodata.ndtime<=D.ToTime)  
 and (autodata.datatype=1) group by autodata.mc,D.Pdate  
) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface  
and t2.date1=#DailyProductionFromAutodataT1.Pdate  
-- Type 3  
UPDATE #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0) from (  
 select mc,sum(DateDiff(second, mstTime, D.ToTime)) cycle,D.Pdate as date1  
 from autodata inner join #DailyProductionFromAutodataT1 D on autodata.mc=D.machineinterface  
 where (autodata.msttime>=D.FromTime)and (autodata.msttime<D.ToTime)and (autodata.ndtime>D.ToTime)  
 and (autodata.datatype=1)group by autodata.mc,D.Pdate  
) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface  
and t2.date1=#DailyProductionFromAutodataT1.Pdate  
-- Type 4  
UPDATE #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isnull(t2.cycle,0) from (  
 select mc,sum(DateDiff(second, D.FromTime, D.ToTime)) cycle,D.Pdate as date1  
 from autodata inner join #DailyProductionFromAutodataT1 D on autodata.mc=D.machineinterface  
 where (autodata.msttime<D.FromTime)and (autodata.ndtime>D.ToTime)and (autodata.datatype=1)  
 group by autodata.mc,D.Pdate  
)as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface  
and t2.date1=#DailyProductionFromAutodataT1.Pdate  
-- END: Get the utilised time  
  
/* By Sangeeta Kallur */  
/* Fetching Down Records from Production Cycle  */  
/* If Down Records of TYPE-2*/  
UPDATE  #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0) FROM (  
 Select AutoData.mc,SUM(  
  CASE  
   When autodata.sttime <= D.FromTime Then datediff(s, D.FromTime,autodata.ndtime )  
   When autodata.sttime > D.FromTime Then datediff(s , autodata.sttime,autodata.ndtime)  
  END) as Down,D.Pdate as date1 From AutoData INNER Join (  
   Select mc,Sttime,NdTime,D.Pdate From AutoData inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface  
   Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And (msttime < D.FromTime)And (ndtime > D.FromTime) AND (ndtime <= D.ToTime)  
   ) as T1  
 ON AutoData.mc=T1.mc inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface And T1.Pdate=D.PDate  
 Where AutoData.DataType=2  
 And ( autodata.Sttime > T1.Sttime )And ( autodata.ndtime <  T1.ndtime )AND ( autodata.ndtime >  D.FromTime )  
 GROUP BY AUTODATA.mc,D.Pdate  
)AS T2 Inner Join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface and t2.date1=#DailyProductionFromAutodataT1.Pdate  
  
/* If Down Records of TYPE-3*/  
UPDATE  #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0) FROM (  
 Select AutoData.mc,SUM(  
  CASE  
   When autodata.ndtime > D.ToTime Then datediff(s,autodata.sttime, D.ToTime )  
   When autodata.ndtime <=D.ToTime Then datediff(s , autodata.sttime,autodata.ndtime)  
  END) as Down,D.Pdate as date1 From AutoData INNER Join (  
   Select mc,Sttime,NdTime,D.Pdate From AutoData inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface  
   Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And(sttime >= D.FromTime)And (ndtime > D.ToTime) And (sttime<D.ToTime)  
   ) as T1  
 ON AutoData.mc=T1.mc inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface And T1.Pdate=D.PDate  
 Where AutoData.DataType=2 And (T1.Sttime < autodata.sttime)And ( T1.ndtime >  autodata.ndtime)AND (autodata.sttime  <  D.ToTime)  
 GROUP BY AUTODATA.mc,D.Pdate  
)AS T2 Inner Join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface and t2.date1=#DailyProductionFromAutodataT1.Pdate  
  
/* If Down Records of TYPE-4*/  
UPDATE  #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0) FROM (  
 Select AutoData.mc,  
  SUM(CASE  
   When autodata.sttime >= D.FromTime AND autodata.ndtime <=D.ToTime Then datediff(s ,autodata.sttime,autodata.ndtime) --Type1  
   When autodata.sttime < D.FromTime AND autodata.ndtime>D.FromTime AND autodata.ndtime<=D.ToTime Then datediff(s, D.FromTime,autodata.ndtime ) --Type2  
   When autodata.sttime>=D.FromTime AND autodata.sttime<D.ToTime AND autodata.ndtime > D.ToTime Then datediff(s,autodata.sttime, D.ToTime ) --Type3  
   When autodata.sttime<D.FromTime AND autodata.ndtime>D.ToTime Then datediff(s ,D.FromTime,D.ToTime)--Type4  
  END) as Down,  
--DR0236 - By SwathiKS on 23-Jun-2010 till here  
   D.Pdate as date1 From AutoData INNER Join (  
   Select mc,Sttime,NdTime,D.Pdate From AutoData inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface  
   Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And(msttime < D.FromTime)And (ndtime > D.ToTime)  
   ) as T1  
 ON AutoData.mc=T1.mc inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface And T1.Pdate=D.PDate  
 Where AutoData.DataType=2 And (T1.Sttime < autodata.sttime)And  
(T1.ndtime >  autodata.ndtime) AND (autodata.ndtime  >  D.FromTime) AND (autodata.sttime  <  D.ToTime)  
 GROUP BY AUTODATA.mc,D.Pdate  
)AS T2 Inner Join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface and t2.date1=#DailyProductionFromAutodataT1.Pdate  
  
--mod 4:Get utilised time over lapping with PDT.  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'  
BEGIN  
 --Detect Utilised Time over lapping with PDT  
 UPDATE #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.cycle,0) from (  
  select mc,StartTime_LogicalDay,EndTime_LogicalDay,  
  sum(Case  
--   When (autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) then (autodata.cycletime+autodata.loadunload) --DR0325 Commented  
   When (autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) then Datediff(s,autodata.msttime,autodata.ndtime) --DR0325 added  
   When (autodata.msttime < StartTime_PDT and autodata.ndtime <= EndTime_PDT and autodata.ndtime > StartTime_PDT) then Datediff(s,StartTime_PDT,autodata.ndtime)  
   When (autodata.msttime >= StartTime_PDT and autodata.ndtime > EndTime_PDT and autodata.msttime < EndTime_PDT) then Datediff(s,autodata.msttime,EndTime_PDT)  
   When (autodata.msttime < StartTime_PDT and autodata.ndtime > EndTime_PDT) then Datediff(s,StartTime_PDT,EndTime_PDT)  
  End) as cycle  
  from autodata inner join #PlannedDownTimes  on autodata.mc=#PlannedDownTimes.machineinterface  
  where (autodata.datatype=1) AND  
  ((autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) or  
  (autodata.msttime < StartTime_PDT and autodata.ndtime <= EndTime_PDT and autodata.ndtime > StartTime_PDT) or  
  (autodata.msttime >= StartTime_PDT and autodata.ndtime > EndTime_PDT and autodata.msttime < EndTime_PDT) or  
  (autodata.msttime < StartTime_PDT and autodata.ndtime > EndTime_PDT))  
  group by autodata.mc,StartTime_LogicalDay,EndTime_LogicalDay  
 ) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface And  
 t2.StartTime_LogicalDay=#DailyProductionFromAutodataT1.FromTime And t2.EndTime_LogicalDay=#DailyProductionFromAutodataT1.ToTime  
  
  
 /* Fetching Down Records from Production Cycle  */  
 /* If production  Records of TYPE-1*/  
 --mod 4(4):Handle intearction between ICD and PDT for type 1 production record for the selected time period.  
 UPDATE #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.icd,0) from (  
  select autodata.mc,StartTime_LogicalDay,EndTime_LogicalDay,  
  sum(Case  
   When (autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) then Datediff(s,autodata.msttime,autodata.ndtime) --DR0325 Added  
   When (autodata.msttime < StartTime_PDT and autodata.ndtime <= EndTime_PDT and autodata.ndtime > StartTime_PDT) then Datediff(s,StartTime_PDT,autodata.ndtime)  
   When (autodata.msttime >= StartTime_PDT and autodata.ndtime > EndTime_PDT and autodata.msttime < EndTime_PDT) then Datediff(s,autodata.msttime,EndTime_PDT)  
   When (autodata.msttime < StartTime_PDT and autodata.ndtime > EndTime_PDT) then Datediff(s,StartTime_PDT,EndTime_PDT)  
  End) as icd  
  from autodata inner join  
   (Select mc,sttime,ndtime,D.fromtime from autodata inner join #DailyProductionFromAutodataT1 D on autodata.mc = D.machineinterface  
    where datatype = 1 and Datediff(s,sttime,ndtime) > Cycletime and  
    (autodata.msttime >= D.fromtime and autodata.ndtime <= D.totime)  
    ) as t1 on   
  (autodata.sttime >= t1.sttime and autodata.ndtime <= t1.ndtime) --DR0339  
  and Autodata.mc=t1.mc  
  inner join  #PlannedDownTimes  on autodata.mc=#PlannedDownTimes.machineinterface And t1.FromTime=#PlannedDownTimes.StartTime_LogicalDay  
  where (autodata.datatype=2) AND  
  ((autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) or  
  (autodata.msttime < StartTime_PDT and autodata.ndtime <= EndTime_PDT and autodata.ndtime > StartTime_PDT) or  
  (autodata.msttime >= StartTime_PDT and autodata.ndtime > EndTime_PDT and autodata.msttime < EndTime_PDT) or  
  (autodata.msttime < StartTime_PDT and autodata.ndtime > EndTime_PDT))  
  group by autodata.mc,StartTime_LogicalDay,EndTime_LogicalDay  
 ) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface And  
 t2.StartTime_LogicalDay=#DailyProductionFromAutodataT1.FromTime And t2.EndTime_LogicalDay=#DailyProductionFromAutodataT1.ToTime  
  
  
 --mod 4(4):Handle intearction between ICD and PDT for type 1 production record for the selected time period.  
 /* If production  Records of TYPE-2*/  
 UPDATE #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.icd,0) from (  
  select autodata.mc,StartTime_LogicalDay,EndTime_LogicalDay,  
  sum(Case  
   When (autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) then  Datediff(s,autodata.msttime,autodata.ndtime) --DR0325 added  
   When (autodata.msttime < StartTime_PDT and autodata.ndtime <= EndTime_PDT and autodata.ndtime > StartTime_PDT) then Datediff(s,StartTime_PDT,autodata.ndtime)  
   When (autodata.msttime >= StartTime_PDT and autodata.ndtime > EndTime_PDT and autodata.msttime < EndTime_PDT) then Datediff(s,autodata.msttime,EndTime_PDT)  
   When (autodata.msttime < StartTime_PDT and autodata.ndtime > EndTime_PDT) then Datediff(s,StartTime_PDT,EndTime_PDT)  
  End) as icd  
  from autodata inner join  
   (Select mc,sttime,ndtime,D.fromtime from autodata inner join #DailyProductionFromAutodataT1 D on autodata.mc = D.machineinterface  
    where datatype = 1 and Datediff(s,sttime,ndtime) > Cycletime and  
    (autodata.msttime < D.fromtime and autodata.ndtime > D.totime and autodata.ndtime <= D.totime)  
    ) as t1 on (autodata.sttime > t1.sttime and autodata.ndtime < t1.ndtime) and Autodata.mc=t1.mc  
  inner join  #PlannedDownTimes  on autodata.mc=#PlannedDownTimes.machineinterface And t1.FromTime=#PlannedDownTimes.StartTime_LogicalDay  
  where (autodata.datatype=2) AND  
  ((autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) or  
  (autodata.msttime < StartTime_PDT and autodata.ndtime <= EndTime_PDT and autodata.ndtime > StartTime_PDT) or  
  (autodata.msttime >= StartTime_PDT and autodata.ndtime > EndTime_PDT and autodata.msttime < EndTime_PDT) or  
  (autodata.msttime < StartTime_PDT and autodata.ndtime > EndTime_PDT))  
  And (autodata.ndtime > T1.FromTime) And (StartTime_PDT <  T1.ndtime)  
  group by autodata.mc,StartTime_LogicalDay,EndTime_LogicalDay  
 ) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface And  
 t2.StartTime_LogicalDay=#DailyProductionFromAutodataT1.FromTime And t2.EndTime_LogicalDay=#DailyProductionFromAutodataT1.ToTime  
  
 /* If production  Records of TYPE-3*/  
 UPDATE #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.icd,0) from (  
  select autodata.mc,StartTime_LogicalDay,EndTime_LogicalDay,  
  sum(Case  
   When (autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) then Datediff(s,autodata.msttime,autodata.ndtime) --DR0325 Added  
   When (autodata.msttime < StartTime_PDT and autodata.ndtime <= EndTime_PDT and autodata.ndtime > StartTime_PDT) then Datediff(s,StartTime_PDT,autodata.ndtime)  
   When (autodata.msttime >= StartTime_PDT and autodata.ndtime > EndTime_PDT and autodata.msttime < EndTime_PDT) then Datediff(s,autodata.msttime,EndTime_PDT)  
   When (autodata.msttime < StartTime_PDT and autodata.ndtime > EndTime_PDT) then Datediff(s,StartTime_PDT,EndTime_PDT)  
  End) as icd  
  from autodata inner join  
   (Select mc,sttime,ndtime,D.fromtime,D.ToTime from autodata inner join #DailyProductionFromAutodataT1 D on autodata.mc = D.machineinterface  
    where datatype = 1 and Datediff(s,sttime,ndtime) > Cycletime and  
    (autodata.sttime >= D.fromtime and autodata.ndtime > D.totime and autodata.sttime < D.totime)  
    ) as t1 on (autodata.sttime > t1.sttime and autodata.ndtime < t1.ndtime) and Autodata.mc=t1.mc  
  inner join  #PlannedDownTimes  on autodata.mc=#PlannedDownTimes.machineinterface And t1.FromTime=#PlannedDownTimes.StartTime_LogicalDay  
  where (autodata.datatype=2) AND  
  ((autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) or  
  (autodata.msttime < StartTime_PDT and autodata.ndtime <= EndTime_PDT and autodata.ndtime > StartTime_PDT) or  
  (autodata.msttime >= StartTime_PDT and autodata.ndtime > EndTime_PDT and autodata.msttime < EndTime_PDT) or  
  (autodata.msttime < StartTime_PDT and autodata.ndtime > EndTime_PDT))  
  And (autodata.sttime < T1.ToTime) And (EndTime_PDT > t1.sttime)  
  group by autodata.mc,StartTime_LogicalDay,EndTime_LogicalDay  
 ) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface And  
 t2.StartTime_LogicalDay=#DailyProductionFromAutodataT1.FromTime And t2.EndTime_LogicalDay=#DailyProductionFromAutodataT1.ToTime  
  
  
 /* If production  Records of TYPE-4*/  
 UPDATE #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.icd,0) from (  
  select autodata.mc,StartTime_LogicalDay,EndTime_LogicalDay,  
  sum(Case  
--   When (autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) then (autodata.cycletime+autodata.loadunload) --DR0325 Commented  
   When (autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) then Datediff(s,autodata.msttime,autodata.ndtime) --DR0325 added  
   When (autodata.msttime < StartTime_PDT and autodata.ndtime <= EndTime_PDT and autodata.ndtime > StartTime_PDT) then Datediff(s,StartTime_PDT,autodata.ndtime)  
   When (autodata.msttime >= StartTime_PDT and autodata.ndtime > EndTime_PDT and autodata.msttime < EndTime_PDT) then Datediff(s,autodata.msttime,EndTime_PDT)  
   When (autodata.msttime < StartTime_PDT and autodata.ndtime > EndTime_PDT) then Datediff(s,StartTime_PDT,EndTime_PDT)  
  End) as icd  
  from autodata inner join  
   (Select mc,sttime,ndtime,D.fromtime,D.totime from autodata inner join #DailyProductionFromAutodataT1 D on autodata.mc = D.machineinterface  
    where datatype = 1 and Datediff(s,sttime,ndtime) > Cycletime and  
    (autodata.msttime < D.fromtime and autodata.ndtime > D.totime)  
    ) as t1 on (autodata.sttime > t1.sttime and autodata.ndtime < t1.ndtime) and Autodata.mc=t1.mc  
  inner join  #PlannedDownTimes  on autodata.mc=#PlannedDownTimes.machineinterface And t1.FromTime=#PlannedDownTimes.StartTime_LogicalDay  
  where (autodata.datatype=2) AND  
  ((autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) or  
  (autodata.msttime < StartTime_PDT and autodata.ndtime <= EndTime_PDT and autodata.ndtime > StartTime_PDT) or  
  (autodata.msttime >= StartTime_PDT and autodata.ndtime > EndTime_PDT and autodata.msttime < EndTime_PDT) or  
  (autodata.msttime < StartTime_PDT and autodata.ndtime > EndTime_PDT))  
  And (autodata.ndtime>t1.FromTime and Autodata.sttime < t1.totime)  
  group by autodata.mc,StartTime_LogicalDay,EndTime_LogicalDay  
 ) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface And  
 t2.StartTime_LogicalDay=#DailyProductionFromAutodataT1.FromTime And t2.EndTime_LogicalDay=#DailyProductionFromAutodataT1.ToTime  
END  
  
  
  
  
--ManagementLoss and Downtime Calculation Starts  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4
m_PLD')<>'Y')  
BEGIN  
  --Down Time  
  --Type 1  
  UPDATE #DailyProductionFromAutodataT1 SET downtime = isnull(downtime,0) + isNull(t2.down,0)  
  from  
  (select mc,  
   sum(loadunload) down,D.Pdate as date1  
  from autodata inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface  
  where (autodata.msttime>=D.FromTime)  
  and (autodata.ndtime<=D.ToTime)  
  and (autodata.datatype=2)  
  group by autodata.mc,D.Pdate  
  ) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface  
  and t2.date1=#DailyProductionFromAutodataT1.Pdate  
  
  -- Type 2  
  UPDATE #DailyProductionFromAutodataT1 SET downtime = isnull(downtime,0) + isNull(t2.down,0)  
  from  
  (select mc,  
   sum(DateDiff(second, D.FromTime, ndtime)) down,D.Pdate as date1  
  from autodata inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface  
  where (autodata.sttime<D.FromTime)  
  and (autodata.ndtime>D.FromTime)  
  and (autodata.ndtime<=D.ToTime)  
  and (autodata.datatype=2)  
  group by autodata.mc,D.Pdate  
  ) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface  
  and t2.date1=#DailyProductionFromAutodataT1.Pdate  
  
  -- Type 3  
  UPDATE #DailyProductionFromAutodataT1 SET downtime = isnull(downtime,0) + isNull(t2.down,0)  
  from  
  (select mc,  
   sum(DateDiff(second, stTime, D.ToTime)) down,D.Pdate as date1  
  from autodata inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface  
  where (autodata.msttime>=D.FromTime)  
  and (autodata.sttime<D.ToTime)  
  and (autodata.ndtime>D.ToTime)  
  and (autodata.datatype=2)group by autodata.mc,D.Pdate  
  ) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface  
  and t2.date1=#DailyProductionFromAutodataT1.Pdate  
  
  -- Type 4  
  UPDATE #DailyProductionFromAutodataT1 SET downtime = isnull(downtime,0) + isNull(t2.down,0)  
  from  
  (select mc,  
   sum(DateDiff(second, D.FromTime, D.ToTime)) down,D.Pdate as date1  
  from autodata inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface  
  where autodata.msttime<D.FromTime  
  and autodata.ndtime>D.ToTime  
  and (autodata.datatype=2)  
  group by autodata.mc,D.Pdate  
  ) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface  
  and t2.date1=#DailyProductionFromAutodataT1.Pdate  
  
  --ManagementLoss Type 1  
  UPDATE #DailyProductionFromAutodataT1 SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)  
  from  
  (select      mc,  
   sum(case  
  when isnull(loadunload,0)>isnull(downcodeinformation.threshold,0) AND isnull(downcodeinformation.threshold,0) > 0 THEN isnull(downcodeinformation.threshold,0)  
  ELSE loadunload  
  END) loss,D.Pdate as date1  
  from autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface  
  where (autodata.msttime>=D.FromTime)  
  and (autodata.ndtime<=D.ToTime)  
  and (autodata.datatype=2)  
  and (downcodeinformation.availeffy = 1)  
  group by autodata.mc,D.Pdate  
  ) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface  
  and t2.date1=#DailyProductionFromAutodataT1.Pdate  
  
  -- Type 2  
  UPDATE #DailyProductionFromAutodataT1 SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)  
  from  
  (select      mc,  
   sum(CASE  
  WHEN DateDiff(second, D.FromTime, ndtime) >isnull(downcodeinformation.threshold,0) AND isnull(downcodeinformation.threshold,0) > 0 THEN isnull(downcodeinformation.threshold,0)  
  ELSE DateDiff(second, D.FromTime, ndtime)  
  END) loss,D.Pdate as date1  
  from autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface  
  where (autodata.sttime<D.FromTime)  
  and (autodata.ndtime>D.FromTime)  
  and (autodata.ndtime<=D.ToTime)  
  and (autodata.datatype=2)  
  and (downcodeinformation.availeffy = 1)  
  group by autodata.mc,D.Pdate  
  ) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface  
  and t2.date1=#DailyProductionFromAutodataT1.Pdate  
  
  -- Type 3  
  UPDATE #DailyProductionFromAutodataT1 SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)  
  from  
  (select      mc,  
   sum(CASE  
  WHEN DateDiff(second, stTime, D.ToTime) >isnull(downcodeinformation.threshold,0) AND isnull(downcodeinformation.threshold,0) > 0 THEN isnull(downcodeinformation.threshold,0)  
  ELSE DateDiff(second, stTime, D.ToTime)  
  END) loss,D.Pdate as date1  
  from autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface  
  where (autodata.msttime>=D.FromTime)  
  and (autodata.sttime<D.ToTime)  
  and (autodata.ndtime>D.ToTime)  
  and (autodata.datatype=2)  
  and (downcodeinformation.availeffy = 1)  
  group by autodata.mc,D.Pdate  
  ) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface  
  and t2.date1=#DailyProductionFromAutodataT1.Pdate  
  
  -- Type 4  
  UPDATE #DailyProductionFromAutodataT1 SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)  
  from  
  (select mc,  
   sum(CASE  
  WHEN DateDiff(second, D.FromTime, D.ToTime)>isnull(downcodeinformation.threshold,0) AND isnull(downcodeinformation.threshold,0) > 0 THEN isnull(downcodeinformation.threshold,0)  
  ELSE DateDiff(second, D.FromTime, D.ToTime)  
  END ) loss,D.Pdate as date1  
  from autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface  
  where autodata.msttime<D.FromTime  
  and autodata.ndtime>D.ToTime  
  and (autodata.datatype=2)  
  and (downcodeinformation.availeffy = 1)  
  group by autodata.mc,D.Pdate  
  ) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface  
  and t2.date1=#DailyProductionFromAutodataT1.Pdate  
End  
  
  
---mod 4: Handling interaction between PDT and downtime . Also interaction between PDT and Management Loss  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
BEGIN  
  
 ---step 1  
 UPDATE #DailyProductionFromAutodataT1 SET downtime = isnull(downtime,0) + isNull(t2.down,0) from (  
  select mc,D.FromTime,D.ToTime,sum(  
   CASE  
    WHEN  autodata.msttime>=D.FromTime  and  autodata.ndtime<=D.ToTime  THEN  loadunload  
    WHEN (autodata.sttime<D.FromTime and  autodata.ndtime>D.FromTime and autodata.ndtime<=D.ToTime)  THEN DateDiff(second, D.FromTime, ndtime)  
    WHEN (autodata.msttime>=D.FromTime  and autodata.sttime<D.ToTime  and autodata.ndtime>D.ToTime)  THEN DateDiff(second, stTime, D.ToTime)  
    WHEN autodata.msttime<D.FromTime and autodata.ndtime>D.ToTime   THEN DateDiff(second, D.FromTime, D.ToTime)  
   END  
   )AS down  
  from autodata inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid  
  inner join #DailyProductionFromAutodataT1 D on autodata.mc = D.MachineInterface  
  where autodata.datatype=2 AND  
  (  
  (autodata.msttime>=D.FromTime  and  autodata.ndtime<=D.ToTime)  
  OR (autodata.sttime<D.FromTime and  autodata.ndtime>D.FromTime and autodata.ndtime<=D.ToTime)  
  OR (autodata.msttime>=D.FromTime  and autodata.sttime<D.ToTime  and autodata.ndtime>D.ToTime)  
  OR (autodata.msttime<D.FromTime and autodata.ndtime>D.ToTime )  
  ) AND (downcodeinformation.availeffy = 0)  
  group by autodata.mc,D.FromTime,D.ToTime  
 ) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface  
 And t2.FromTime = #DailyProductionFromAutodataT1.FromTime  
 And t2.ToTime = #DailyProductionFromAutodataT1.ToTime  
  
 --step 2  
 ---mod 4 checking for (downcodeinformation.availeffy = 0) to get the overlapping PDT and Downs which is not ML  
 UPDATE #DailyProductionFromAutodataT1 set DownTime =isnull(DownTime,0) - isNull(TT.PPDT ,0)  
 FROM(  
  SELECT autodata.MC,StartTime_LogicalDay,EndTime_LogicalDay,SUM  
     (CASE  
   WHEN autodata.sttime >= T.StartTime_PDT  AND autodata.ndtime <=T.EndTime_PDT  THEN (autodata.loadunload)  
   WHEN ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime <= T.EndTime_PDT  AND autodata.ndtime > T.StartTime_PDT ) THEN DateDiff(second,T.StartTime_PDT,autodata.ndtime)  
   WHEN ( autodata.sttime >= T.StartTime_PDT   AND autodata.sttime <T.EndTime_PDT  AND autodata.ndtime > T.EndTime_PDT  ) THEN DateDiff(second,autodata.sttime,T.EndTime_PDT )  
   WHEN ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime > T.EndTime_PDT ) THEN DateDiff(second,T.StartTime_PDT,T.EndTime_PDT )  
   END ) as PPDT  
  FROM AutoData CROSS jOIN #PlannedDownTimes T  
  inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid  
  WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND  
   (  
   (autodata.sttime >= T.StartTime_PDT  AND autodata.ndtime <=T.EndTime_PDT)  
   OR ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime <= T.EndTime_PDT AND autodata.ndtime > T.StartTime_PDT )  
   OR ( autodata.sttime >= T.StartTime_PDT   AND autodata.sttime <T.EndTime_PDT AND autodata.ndtime > T.EndTime_PDT )  
   OR ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime > T.EndTime_PDT)  
   )  
   AND (downcodeinformation.availeffy = 0)  
  group by autodata.MC,StartTime_LogicalDay,EndTime_LogicalDay  
 ) as TT INNER JOIN #DailyProductionFromAutodataT1 ON TT.mc = #DailyProductionFromAutodataT1.MachineInterface And  
 TT.StartTime_LogicalDay = #DailyProductionFromAutodataT1.FromTime and TT.EndTime_LogicalDay = #DailyProductionFromAutodataT1.ToTime  
  
 ---step 3  
 ---Management loss calculation  
 ---IN T1 Select get all the downtimes which is of type management loss  
 ---IN T2  get the time to be deducted from the cycle if the cycle is overlapping with the PDT. And it should be ML record  
 ---In T3 Get the real management loss , and time to be considered as real down for each cycle(by comaring with the ML threshold)  
 ---In T4 consolidate everything at machine level and update the same to #CockpitData for ManagementLoss and MLDown  
 UPDATE #DailyProductionFromAutodataT1 SET  ManagementLoss = isnull(ManagementLoss,0) + isNull(t4.Mloss,0),MLDown=isNull(MLDown,0)+isNull(t4.Dloss,0) from (  
   select T3.mc,T3.FromTime,T3.ToTime,sum(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss from (  
   
    select  t1.id,T1.mc,T1.Threshold,T1.FromTime,T1.Totime,  
    case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0  
    then DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)- isnull(T1.Threshold ,0)  
    else 0 End  as Dloss,  
    case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0  
    then isnull(T1.Threshold,0)  
    else (DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)) End  as Mloss  
     from  
    (   select id,mc,comp,opn,opr,DC.threshold,D.FromTime,D.ToTime,  
      case when autodata.sttime<D.FromTime then D.FromTime else sttime END as sttime,  
      case when ndtime>D.ToTime then D.ToTime else ndtime END as ndtime  
     from autodata inner join downcodeinformation DC on autodata.dcode=DC.interfaceid  
     CROSS jOIN #DailyProductionFromAutodataT1 D  
     where autodata.datatype=2 And D.MachineInterface=autodata.mc and  
     (  
     (autodata.sttime>=D.FromTime  and  autodata.ndtime<=D.ToTime)  
     OR (autodata.sttime<D.FromTime and  autodata.ndtime>D.FromTime and autodata.ndtime<=D.ToTime)  
     OR (autodata.sttime>=D.FromTime  and autodata.sttime<D.ToTime  and autodata.ndtime>D.ToTime)  
     OR (autodata.sttime<D.FromTime and autodata.ndtime>D.ToTime )  
     ) AND (DC.availeffy = 1)) as T1    
    left outer join  
    (SELECT autodata.id,T.StartTime_LogicalDay,T.EndTime_LogicalDay,  
         sum(CASE  
      WHEN autodata.sttime >= T.StartTime_PDT  AND autodata.ndtime <=T.EndTime_PDT  THEN (autodata.loadunload)  
      WHEN ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime <= T.EndTime_PDT  AND autodata.ndtime > T.StartTime_PDT ) THEN DateDiff(second,T.StartTime_PDT,autodata.ndtime)  
      WHEN ( autodata.sttime >= T.StartTime_PDT   AND autodata.sttime <T.EndTime_PDT  AND autodata.ndtime > T.EndTime_PDT  ) THEN DateDiff(second,autodata.sttime,T.EndTime_PDT )  
      WHEN ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime > T.EndTime_PDT ) THEN DateDiff(second,T.StartTime_PDT,T.EndTime_PDT )  
      END ) as PPDT  
     FROM AutoData CROSS jOIN #PlannedDownTimes T  
     inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid  
     WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND  
      ((autodata.sttime >= T.StartTime_PDT  AND autodata.ndtime <=T.EndTime_PDT)  
      OR ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime <= T.EndTime_PDT AND autodata.ndtime > T.StartTime_PDT )  
      OR ( autodata.sttime >= T.StartTime_PDT   AND autodata.sttime <T.EndTime_PDT AND autodata.ndtime > T.EndTime_PDT )  
      OR ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime > T.EndTime_PDT))  
      AND (downcodeinformation.availeffy = 1) group  by autodata.id,T.starttime_LogicalDay,T.EndTime_LogicalDay  
     ) as T2 on T1.id=T2.id and T2.starttime_LogicalDay=T1.FromTime and T2.EndTime_LogicalDay=T1.ToTime  
   ) as T3  group by T3.mc,T3.FromTime,T3.ToTime  
  ) as t4 inner join #DailyProductionFromAutodataT1 on t4.mc = #DailyProductionFromAutodataT1.machineinterface And  
  t4.FromTime = #DailyProductionFromAutodataT1.FromTime and  t4.ToTime = #DailyProductionFromAutodataT1.ToTime  
  
 UPDATE #DailyProductionFromAutodataT1 SET downtime = isnull(downtime,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)  
End  
  
  
  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y' AND (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'  
Begin  
  
 UPDATE #DailyProductionFromAutodataT1 set downtime =isnull(downtime,0) - isNull(t1.PPDT ,0)  
 FROM(  
  --Production PDT  
  SELECT autodata.MC,T.StartTime_LogicalDay,T.EndTime_LogicalDay, SUM  
         (CASE  
   WHEN autodata.sttime >= T.StartTime_PDT  AND autodata.ndtime <=T.EndTime_PDT  THEN (autodata.loadunload)  
   WHEN ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime <= T.EndTime_PDT  AND autodata.ndtime > T.StartTime_PDT ) THEN DateDiff(second,T.StartTime_PDT,autodata.ndtime)  
   WHEN ( autodata.sttime >= T.StartTime_PDT   AND autodata.sttime <T.EndTime_PDT  AND autodata.ndtime > T.EndTime_PDT  ) THEN DateDiff(second,autodata.sttime,T.EndTime_PDT )  
   WHEN ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime > T.EndTime_PDT ) THEN DateDiff(second,T.StartTime_PDT,T.EndTime_PDT )  
   END ) as PPDT  
  FROM AutoData CROSS jOIN #PlannedDownTimes T  
  Inner Join DownCodeInformation D ON AutoData.DCode = D.InterfaceID  
  WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND D.DownID=(SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD') AND  
   ((autodata.sttime >= T.StartTime_PDT  AND autodata.ndtime <=T.EndTime_PDT)  
   OR ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime <= T.EndTime_PDT AND autodata.ndtime > T.StartTime_PDT )  
   OR ( autodata.sttime >= T.StartTime_PDT   AND autodata.sttime <T.EndTime_PDT AND autodata.ndtime > T.EndTime_PDT )  
   OR ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime > T.EndTime_PDT))group by autodata.mc,T.StartTime_LogicalDay,T.EndTime_LogicalDay  
 ) as t1 INNER JOIN #DailyProductionFromAutodataT1 ON t1.mc = #DailyProductionFromAutodataT1.MachineInterface And  
 t1.StartTime_LogicalDay = #DailyProductionFromAutodataT1.FromTime and t1.EndTime_LogicalDay = #DailyProductionFromAutodataT1.ToTime  
   
End  
  
--BEGIN: CN  
--Type 1 and Type 2  
UPDATE #DailyProductionFromAutodataT1 SET CN = isnull(CN,0) + isNull(t2.C1N1,0) from (  
 select mc,  
 SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))*autodata.partscount) C1N1,D.Pdate as date1  
 FROM autodata INNER JOIN  
 componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN  
 componentinformation ON autodata.comp = componentinformation.InterfaceID AND  
 componentoperationpricing.componentid = componentinformation.componentid  
 inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface  
 ---mod 1  
 inner join machineinformation on machineinformation.interfaceid=autodata.mc and componentoperationpricing.machineid=machineinformation.machineid  
 ---mod 1  
 where (autodata.ndtime>D.FromTime)and (autodata.ndtime<=D.ToTime)and (autodata.datatype=1) group by autodata.mc,D.Pdate  
) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface  
and t2.date1=#DailyProductionFromAutodataT1.Pdate  
  
-- mod 4 Ignore count from CN calculation which is over lapping with PDT  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
BEGIN  
 UPDATE #DailyProductionFromAutodataT1 SET CN = isnull(CN,0) - isNull(t1.C1N1,0)  
 From  
 (  
  select mc,T.StartTime_LogicalDay,T.EndTime_LogicalDay,  
  SUM((O.cycletime * ISNULL(A.PartsCount,1))/ISNULL(O.SubOperations,1))  C1N1  
  From autodata A  
  Inner join machineinformation M on M.interfaceid=A.mc  
  Inner join componentinformation C ON A.Comp=C.interfaceid  
  Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID  
  Cross jOIN #PlannedDownTimes T  
  WHERE A.DataType=1 AND T.MachineInterface=A.mc AND (A.ndtime > T.StartTime_PDT AND A.ndtime <=T.EndTime_PDT)  
  Group by mc,T.StartTime_LogicalDay,T.EndTime_LogicalDay  
 ) as t1  
 inner join #DailyProductionFromAutodataT1 on t1.mc = #DailyProductionFromAutodataT1.machineinterface And  
 t1.StartTime_LogicalDay = #DailyProductionFromAutodataT1.FromTime and t1.EndTime_LogicalDay = #DailyProductionFromAutodataT1.ToTime  
END  
-- mod 4  
  
  
  
-- Calculate efficiencies  
UPDATE #DailyProductionFromAutodataT1  
SET  
 ProductionEfficiency = (CN/UtilisedTime) ,  
 AvailabilityEfficiency = (UtilisedTime)/(UtilisedTime + DownTime - ManagementLoss)  
WHERE UtilisedTime <> 0  
UPDATE #DailyProductionFromAutodataT1  
SET  
 OverAllEfficiency = (ProductionEfficiency * AvailabilityEfficiency)*100,  
 ProductionEfficiency = ProductionEfficiency * 100 ,  
 AvailabilityEfficiency = AvailabilityEfficiency * 100  
  
  
declare @i as nvarchar(10)  
declare @colName as nvarchar(50)  
Select @i=1  
  
while @i <=15  
Begin  
 Select @ColName = Case when @i=1 then 'A'  
      when @i=2 then 'B'  
      when @i=3 then 'C'  
      when @i=4 then 'D'  
      when @i=5 then 'E'  
      when @i=6 then 'F'  
      when @i=7 then 'G'  
       END  
  
  
  
  ---Get the down times which are not of type Management Loss    
  Select @strsql = ''  
  Select @strsql = @strsql + ' UPDATE #DailyProductionFromAutodataT1 SET ' + @ColName + ' = isnull(' + @ColName + ',0) + isNull(t2.down,0)    
  from    
  (select  F.Fromtime,F.Totime,F.machineinterface,   
   sum (CASE    
  WHEN (autodata.msttime >= F.Fromtime  AND autodata.ndtime <=F.Totime)  THEN autodata.loadunload    
  WHEN ( autodata.msttime < F.Fromtime  AND autodata.ndtime <= F.Totime  AND autodata.ndtime > F.Fromtime ) THEN DateDiff(second,F.Fromtime,autodata.ndtime)    
  WHEN ( autodata.msttime >= F.Fromtime   AND autodata.msttime <F.Totime  AND autodata.ndtime > F.Totime  ) THEN DateDiff(second,autodata.msttime,F.Totime )    
  WHEN ( autodata.msttime < F.Fromtime  AND autodata.ndtime > F.Totime ) THEN DateDiff(second,F.Fromtime,F.Totime )    
  END ) as down    
  from autodata     
  inner join #DailyProductionFromAutodataT1 F on autodata.mc = F.Machineinterface   
  inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid   
  inner join #Downcode on #Downcode.downid= downcodeinformation.downid  
  where (autodata.datatype=''2'') AND  #Downcode.Slno= ' + @i + ' and   
  (( (autodata.msttime>=F.Fromtime) and (autodata.ndtime<=F.Totime))    
     OR ((autodata.msttime<F.Fromtime)and (autodata.ndtime>F.Fromtime)and (autodata.ndtime<=F.Totime))    
     OR ((autodata.msttime>=F.Fromtime)and (autodata.msttime<F.Totime)and (autodata.ndtime>F.Totime))    
     OR((autodata.msttime<F.Fromtime)and (autodata.ndtime>F.Totime)))     
  AND (downcodeinformation.availeffy = ''0'')    
     group by F.Fromtime,F.Totime,F.machineinterface  
  ) as t2 Inner Join #DailyProductionFromAutodataT1 on t2.machineinterface = #DailyProductionFromAutodataT1.machineinterface     
  and t2.Fromtime=#DailyProductionFromAutodataT1.Fromtime and t2.Totime=#DailyProductionFromAutodataT1.Totime '  
     print @strsql  
  exec(@strsql)   
    
  If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'    
  BEGIN     
    Select @strsql = ''   
    Select @strsql = @strsql + 'UPDATE  #DailyProductionFromAutodataT1 SET ' + @ColName + ' = isnull(' + @ColName + ',0) - isNull(T2.PPDT ,0)    
    FROM(    
    SELECT F.Fromtime,F.Totime,F.machineinterface,  
    SUM    
    (CASE    
    WHEN autodata.sttime >= T.StartTime_PDT  AND autodata.ndtime <=T.EndTime_PDT  THEN (autodata.loadunload)    
    WHEN ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime <= T.EndTime_PDT  AND autodata.ndtime > T.StartTime_PDT ) THEN DateDiff(second,T.StartTime_PDT,autodata.ndtime)    
    WHEN ( autodata.sttime >= T.StartTime_PDT   AND autodata.sttime <T.EndTime_PDT  AND autodata.ndtime > T.EndTime_PDT  ) THEN DateDiff(second,autodata.sttime,T.EndTime_PDT )    
    WHEN ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime > T.EndTime_PDT ) THEN DateDiff(second,T.StartTime_PDT,T.EndTime_PDT )    
    END ) as PPDT    
    FROM AutoData    
    --CROSS jOIN #PlannedDownTimesShift T    --DR0379
	CROSS join #PlannedDownTimes T --DR0379
    INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID    
    INNER JOIN #DailyProductionFromAutodataT1 F on F.machineinterface=Autodata.mc   
    inner join #Downcode on #Downcode.downid= downcodeinformation.downid     
    WHERE autodata.DataType=''2'' AND T.MachineInterface=autodata.mc AND (downcodeinformation.availeffy = ''0'') and #Downcode.Slno= ' + @i + '    
     AND    
     ((autodata.sttime >= F.Fromtime  AND autodata.ndtime <=F.Totime)    
     OR ( autodata.sttime < F.Fromtime  AND autodata.ndtime <= F.Totime AND autodata.ndtime > F.Fromtime )    
     OR ( autodata.sttime >= F.Fromtime   AND autodata.sttime <F.Totime AND autodata.ndtime > F.Totime )    
     OR ( autodata.sttime < F.Fromtime  AND autodata.ndtime > F.Totime))    
     AND    
     ((autodata.msttime >= T.StartTime_PDT  AND autodata.ndtime <=T.EndTime_PDT)    
     OR ( autodata.msttime < T.StartTime_PDT  AND autodata.ndtime <= T.EndTime_PDT AND autodata.ndtime > T.StartTime_PDT )    
     OR ( autodata.msttime >= T.StartTime_PDT   AND autodata.msttime <T.EndTime_PDT AND autodata.ndtime > T.EndTime_PDT )    
     OR ( autodata.msttime < T.StartTime_PDT  AND autodata.ndtime > T.EndTime_PDT) )     
     AND    
     ((F.Fromtime >= T.StartTime_PDT  AND F.Totime <=T.EndTime_PDT)    
     OR ( F.Fromtime < T.StartTime_PDT  AND F.Totime <= T.EndTime_PDT AND F.Totime > T.StartTime_PDT )    
     OR ( F.Fromtime >= T.StartTime_PDT   AND F.Fromtime <T.EndTime_PDT AND F.Totime > T.EndTime_PDT )    
     OR ( F.Fromtime < T.StartTime_PDT  AND F.Totime > T.EndTime_PDT) )     
     group  by F.Fromtime,F.Totime,F.machineinterface  
    )AS T2  Inner Join #DailyProductionFromAutodataT1 on t2.machineinterface = #DailyProductionFromAutodataT1.machineinterface and    
     t2.Fromtime=#DailyProductionFromAutodataT1.Fromtime and t2.Totime=#DailyProductionFromAutodataT1.Totime  '  
   print @strsql  
   exec(@Strsql)  
  END  
  
 select @i  =  @i + 1  
End  
  
  
Select @strsql = ''  
 Select @strsql = @strsql + ' UPDATE #DailyProductionFromAutodataT1 SET NonproductiveTime = isnull(NonproductiveTime,0) + isNull(t2.down,0)    
 from    
 (select  F.Fromtime,F.Totime,F.machineinterface,   
  sum (CASE    
 WHEN (autodata.msttime >= F.Fromtime  AND autodata.ndtime <=F.Totime)  THEN autodata.loadunload    
 WHEN ( autodata.msttime < F.Fromtime  AND autodata.ndtime <= F.Totime  AND autodata.ndtime > F.Fromtime ) THEN DateDiff(second,F.Fromtime,autodata.ndtime)    
 WHEN ( autodata.msttime >= F.Fromtime   AND autodata.msttime <F.Totime  AND autodata.ndtime > F.Totime  ) THEN DateDiff(second,autodata.msttime,F.Totime )    
 WHEN ( autodata.msttime < F.Fromtime  AND autodata.ndtime > F.Totime ) THEN DateDiff(second,F.Fromtime,F.Totime )    
 END ) as down    
 from autodata     
 inner join #DailyProductionFromAutodataT1 F on autodata.mc = F.Machineinterface   
 inner join (Select * from downcodeinformation where downid not in(select downid from #downcode))downcodeinformation  
 on autodata.dcode=downcodeinformation.interfaceid   
 where (autodata.datatype=''2'') AND   
 (( (autodata.msttime>=F.Fromtime) and (autodata.ndtime<=F.Totime))    
    OR ((autodata.msttime<F.Fromtime)and (autodata.ndtime>F.Fromtime)and (autodata.ndtime<=F.Totime))    
    OR ((autodata.msttime>=F.Fromtime)and (autodata.msttime<F.Totime)and (autodata.ndtime>F.Totime))    
    OR((autodata.msttime<F.Fromtime)and (autodata.ndtime>F.Totime)))     
 AND (downcodeinformation.availeffy = ''0'')    
    group by F.Fromtime,F.Totime,F.machineinterface  
 ) as t2 Inner Join #DailyProductionFromAutodataT1 on t2.machineinterface = #DailyProductionFromAutodataT1.machineinterface     
 and t2.Fromtime=#DailyProductionFromAutodataT1.Fromtime and t2.Totime=#DailyProductionFromAutodataT1.Totime '  
 print @strsql  
 exec(@strsql)   
   
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'    
BEGIN     
  Select @strsql = ''   
  Select @strsql = @strsql + 'UPDATE  #DailyProductionFromAutodataT1 SET NonproductiveTime= isnull(NonproductiveTime,0) - isNull(T2.PPDT ,0)    
  FROM(    
  SELECT F.Fromtime,F.Totime,F.machineinterface,  
  SUM    
  (CASE    
  WHEN autodata.sttime >= T.StartTime_PDT  AND autodata.ndtime <=T.EndTime_PDT  THEN (autodata.loadunload)    
  WHEN ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime <= T.EndTime_PDT  AND autodata.ndtime > T.StartTime_PDT ) THEN DateDiff(second,T.StartTime_PDT,autodata.ndtime)    
  WHEN ( autodata.sttime >= T.StartTime_PDT   AND autodata.sttime <T.EndTime_PDT  AND autodata.ndtime > T.EndTime_PDT  ) THEN DateDiff(second,autodata.sttime,T.EndTime_PDT )    
  WHEN ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime > T.EndTime_PDT ) THEN DateDiff(second,T.StartTime_PDT,T.EndTime_PDT )    
  END ) as PPDT    
  FROM AutoData    
  --CROSS jOIN #PlannedDownTimesShift T     --DR0379
  CROSS jOIN  #PlannedDownTimes T --DR0379
  INNER JOIN (Select * from downcodeinformation where downid not in(select downid from #downcode))DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID    
  INNER JOIN #DailyProductionFromAutodataT1 F on F.machineinterface=Autodata.mc   
  WHERE autodata.DataType=''2'' AND T.MachineInterface=autodata.mc AND (downcodeinformation.availeffy = ''0'')   
   AND    
   ((autodata.sttime >= F.Fromtime  AND autodata.ndtime <=F.Totime)    
   OR ( autodata.sttime < F.Fromtime  AND autodata.ndtime <= F.Totime AND autodata.ndtime > F.Fromtime )    
   OR ( autodata.sttime >= F.Fromtime   AND autodata.sttime <F.Totime AND autodata.ndtime > F.Totime )    
   OR ( autodata.sttime < F.Fromtime  AND autodata.ndtime > F.Totime))    
   AND    
   ((autodata.msttime >= T.StartTime_PDT  AND autodata.ndtime <=T.EndTime_PDT)    
   OR ( autodata.msttime < T.StartTime_PDT  AND autodata.ndtime <= T.EndTime_PDT AND autodata.ndtime > T.StartTime_PDT )    
   OR ( autodata.msttime >= T.StartTime_PDT   AND autodata.msttime <T.EndTime_PDT AND autodata.ndtime > T.EndTime_PDT )    
   OR ( autodata.msttime < T.StartTime_PDT  AND autodata.ndtime > T.EndTime_PDT) )     
   AND    
   ((F.Fromtime >= T.StartTime_PDT  AND F.Totime <=T.EndTime_PDT)    
   OR ( F.Fromtime < T.StartTime_PDT  AND F.Totime <= T.EndTime_PDT AND F.Totime > T.StartTime_PDT )    
   OR ( F.Fromtime >= T.StartTime_PDT   AND F.Fromtime <T.EndTime_PDT AND F.Totime > T.EndTime_PDT )    
   OR ( F.Fromtime < T.StartTime_PDT  AND F.Totime > T.EndTime_PDT) )     
   group  by F.Fromtime,F.Totime,F.machineinterface  
  )AS T2  Inner Join #DailyProductionFromAutodataT1 on t2.machineinterface = #DailyProductionFromAutodataT1.machineinterface and    
   t2.Fromtime=#DailyProductionFromAutodataT1.Fromtime and t2.Totime=#DailyProductionFromAutodataT1.Totime  '  
 print @strsql  
 exec(@Strsql)  
END  
  
  
select @StartTime=@StartDate  
select @EndTime=@EndDate  
DECLARE @CurStart datetime  
DECLARE @CurEndTime datetime  
  
while @StartTime<=@EndTime  
BEGIN  
 select @CurStart=dbo.f_GetLogicalDay(@StartTime,'start')  
 select @CurEndTime=dbo.f_GetLogicalDay(@StartTime,'End')  
  
 select @strsql = 'insert into #DailyProductionFromAutodataT2 (Cdate,MachineID,Component,Operation,CycleTime,LoadUnload,'  
 select @strsql = @strsql + 'CountShift1,CountShift2,CountShift3,FromTm,ToTm)'  
 select @strsql = @strsql + '( SELECT ''' +convert(nvarchar(20),@StartTime)+ ''', machineinformation.machineid, componentinformation.componentid, '  
 select @strsql = @strsql + ' componentoperationpricing.operationno, '  
 select @strsql = @strsql + ' componentoperationpricing.machiningtime, '  
 select @strsql = @strsql + ' (componentoperationpricing.cycletime - componentoperationpricing.machiningtime), '  
 select @strsql = @strsql + ' 0,0,0,''' +convert(nvarchar(20),@CurStart)+ ''',''' +convert(nvarchar(20),@CurEndTime)+ ''' '  
 select @strsql = @strsql + ' FROM autodata INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN  '  
 select @strsql = @strsql + ' componentinformation ON autodata.comp = componentinformation.InterfaceID  INNER JOIN '  
 select @strsql = @strsql + ' componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID)'  
 select @strsql = @strsql + ' AND (componentinformation.componentid = componentoperationpricing.componentid) '  
 select @strsql = @strsql + ' and componentoperationpricing.machineid=machineinformation.machineid '  
 select @strsql = @strsql + ' Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid'  
 select @strsql = @strsql + ' WHERE (autodata.ndtime > ''' + convert(nvarchar(20),@CurStart) + ''')'  
 select @strsql = @strsql + ' AND (autodata.ndtime <= ''' + convert(nvarchar(20),@CurEndTime) + ''')'  
 select @strsql = @strsql + @StrMPlantid + @strmachine + @strcomponentid + @stroperation  
 select @strsql = @strsql + ' AND (autodata.datatype = 1)'  
 --mod 3  
 select @strsql = @strsql + ' AND (autodata.partscount > 0 ) '  
 --mod 3  
 select @strsql = @strsql + ' GROUP BY machineinformation.machineid,componentinformation.componentid, componentoperationpricing.operationno, '  
 select @strsql = @strsql + ' componentoperationpricing.cycletime, componentoperationpricing.machiningtime ,ComponentOperationPricing.SubOperations)'  
 print @strsql  
 exec(@strsql)  
   
 --BEGIN: Update shift1, shift2, shift3 counts  
 INSERT #DailyProductionFromAutodataT0(DDate,Shift, ShiftStart, ShiftEnd)  
 EXEC s_GetShiftTime @StartTime  
   
 SELECT @StartTime=DATEADD(DAY,1,@StartTime)  
END  
  
  
  
  
declare @Dateval datetime  
declare @shiftstart datetime  
declare @shiftend  datetime  
declare @shiftid  nvarchar(20)  
declare @shiftname  nvarchar(20)  
declare @shiftnamevalue  nvarchar(20)  
declare @recordcount smallint  
declare @lastdate datetime  
  
--Initialize values  
select @shiftstart = @starttime  
select @shiftend = @endtime  
select @shiftid = 'CountShift'  
select @shiftname = 'NameShift'  
select @shiftnamevalue = 'Shift 1'  
  
select @recordcount = 0  
select @lastdate=@StartDate  
Declare RptDailyCursor CURSOR FOR    
  SELECT  #DailyProductionFromAutodataT0.DDate,  
    #DailyProductionFromAutodataT0.Shift,  
    #DailyProductionFromAutodataT0.ShiftStart,  
    #DailyProductionFromAutodataT0.ShiftEnd  
  from  #DailyProductionFromAutodataT0 order by Ddate,shift  
OPEN RptDailyCursor  
FETCH NEXT FROM RptDailyCursor INTO @Dateval,@shiftnamevalue, @shiftstart, @shiftend  
  
while (@@fetch_status = 0)  
Begin  
 if @Dateval=dateadd(day,1,@lastdate)  
 BEGIN  
       SELECT @lastdate=@Dateval  
       SELECT @recordcount=0  
 END  
  
 select @recordcount = @recordcount + 1  
 select @shiftid = 'CountShift' + cast(@recordcount as nvarchar(1))  
 select @shiftname = 'NameShift' + cast(@recordcount as nvarchar(1))  
  
 Delete #PlannedDownTimes  
  
 Insert into #PlannedDownTimes  
 Select machineinformation.MachineID,machineinformation.InterfaceID,@shiftstart,@shiftend,  
 Case When StartTime<@shiftstart Then @shiftstart Else StartTime End as StartTime,    
 Case When EndTime > @shiftend Then @shiftend Else EndTime End as EndTime,  
 0,0,0,0,PlannedDownTimes.DownReason  
  from PlannedDownTimes inner join machineinformation on PlannedDownTimes.machine=machineinformation.machineid  
  Where PlannedDownTimes.PDTstatus =1 And (  
 (StartTime >= @shiftstart and EndTime <= @shiftend) OR  
 (StartTime < @shiftstart and EndTime <= @shiftend and EndTime > @shiftstart) OR  
 (StartTime >= @shiftstart and EndTime > @shiftend and StartTime < @shiftend) OR  
 (StartTime < @shiftstart and EndTime > @shiftend))  
 And machineinformation.MachineID in (select distinct MachineID from #DailyProductionFromAutodataT1)  
  
 --Mod 4(1)  
 select @strsql = ''  
 select @strsql = 'UPDATE #DailyProductionFromAutodataT2 SET ' + @shiftid + '= isNull(t5.OperationCount,0), '  
 select @strsql = @strsql + @shiftname + ' = ''' + @shiftNamevalue + ''''  
 select @strsql = @strsql + ' from ( SELECT machineinformation.machineid, componentinformation.componentid, '  
 select @strsql = @strsql + ' componentoperationpricing.operationno, '  
 select @strsql = @strsql + ' (CAST(Sum(autodata.partscount)AS Float)/ISNULL(ComponentOperationPricing.SubOperations,1)) AS operationcount,D.Cdate as date1' --NR0097  
 select @strsql = @strsql + ' FROM autodata INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN  '  
 select @strsql = @strsql + ' componentinformation ON autodata.comp = componentinformation.InterfaceID  INNER JOIN '  
 select @strsql = @strsql + ' componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID'  
 select @strsql = @strsql + ' AND componentinformation.componentid = componentoperationpricing.componentid) '  
 ---mod 1  
 select @strsql = @strsql + ' and componentoperationpricing.machineid=machineinformation.machineid '  
 ---mod 1  
 select @strsql = @strsql + ' inner join #DailyProductionFromAutodataT2 D on Machineinformation.machineid=D.machineid  
 AND componentinformation.componentid=D.Component AND componentoperationpricing.operationno=D.Operation '  
 select @strsql = @strsql + ' Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid'  
 select @strsql = @strsql + ' WHERE (autodata.ndtime > ''' + convert(nvarchar(20),@ShiftStart) + ''')'  
 select @strsql = @strsql + ' AND (autodata.ndtime <= ''' + convert(nvarchar(20),@ShiftEnd) + ''') and D.Cdate=''' + convert(nvarchar(20),@Dateval) + ''' '  
 select @strsql = @strsql + @StrMPlantid + @strmachine + @strcomponentid + @stroperation  
 select @strsql = @strsql + ' AND (autodata.datatype = 1)'  
 select @strsql = @strsql + ' GROUP BY machineinformation.machineid,componentinformation.componentid, componentoperationpricing.operationno,ComponentOperationPricing.SubOperations,D.Cdate ) '  
 select @strsql = @strsql + ' as t5 inner join #DailyProductionFromAutodataT2 on (t5.machineid = #DailyProductionFromAutodataT2.machineid '  
 select @strsql = @strsql + 'and t5.componentid = #DailyProductionFromAutodataT2.component '  
 select @strsql = @strsql + 'and t5.operationno = #DailyProductionFromAutodataT2.operation and t5.date1=#DailyProductionFromAutodataT2.Cdate)'  
 exec(@strsql)  
  
 --Mod 4(1) Apply PDT  
 If (select valueintext from cockpitdefaults where parameter='Ignore_Count_4m_Pld')='Y'  
 Begin  
   Select @Strsql = 'Update #DailyProductionFromAutodataT2 Set '+ @Shiftid+'=(Isnull('+ @ShiftId +',0)-Isnull(T2.Count,0))'  
      Select @Strsql =@Strsql + ' from (Select machineinformation.machineid,'  
   Select @Strsql =@Strsql + ' (cast(Sum(autodata.partscount) as float)/Isnull(Componentoperationpricing.Suboperations,1)) as Count,' --NR0097  
      Select @Strsql =@Strsql + ' ComponentInformation.Componentid,Componentoperationpricing.operationno,D.Cdate as date1 from autodata  
        inner Join #PlannedDownTimes T  on T.machineinterface = autodata.mc  
        inner join machineinformation on machineinformation.interfaceid=autodata.mc  
        inner join ComponentInformation on ComponentInformation.Interfaceid=autodata.Comp  
        inner join Componentoperationpricing on Componentoperationpricing.Interfaceid=autodata.opn and Componentoperationpricing.componentid=ComponentInformation.componentid and Componentoperationpricing.machineID = machineinformation.MachineID  
     inner join #DailyProductionFromAutodataT2 D on Machineinformation.machineid=D.machineid AND componentinformation.componentid=D.Component AND componentoperationpricing.operationno=D.Operation  
     Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid --DR0296  
        Where autodata.datatype=1 and (autodata.ndtime> T.StartTime_PDT and autodata.ndtime <= T.EndTime_PDT) '  
      Select @Strsql = @Strsql + ' and (autodata.ndtime > ''' +Convert(nvarchar(20),@ShiftStart) + ''' and autodata.ndtime <= ''' + Convert(Nvarchar(20),@ShiftEnd) + ''') and D.Cdate=''' + convert(nvarchar(20),@Dateval) + ''''  
      select @strsql = @strsql + @StrMPlantid + @strmachine + @strcomponentid + @stroperation  
      Select @Strsql = @Strsql + ' Group by machineinformation.machineid,ComponentInformation.componentid,Componentoperationpricing.operationno,  
        Componentoperationpricing.Suboperations,D.Cdate) as T2 inner join #DailyProductionFromAutodataT2 on (T2.machineid = #DailyProductionFromAutodataT2.machineid  
        and T2.Componentid= #DailyProductionFromAutodataT2.Component and T2.operationno=#DailyProductionFromAutodataT2.operation and t2.date1 = #DailyProductionFromAutodataT2.cdate)'            
     Exec(@strsql)  
 End  
 --Mod 4(1)  
FETCH NEXT FROM RptDailyCursor INTO @Dateval,@shiftnamevalue, @shiftstart, @shiftend  
  
  
END  
CLOSE RptDailyCursor  
DEALLOCATE RptDailyCursor  
  
Declare @MonthStart as Datetime  
Select @MonthStart = dbo.f_GetLogicalMonth(@Startdate,'start')   
  
  
select @strsql = ''  
select @strsql = 'UPDATE #DailyProductionFromAutodataT2 SET CummCount= Isnull(CummCount,0) + isNull(t5.OperationCount,0) '  
select @strsql = @strsql + ' from ( SELECT machineinformation.machineid, componentinformation.componentid, '  
select @strsql = @strsql + ' componentoperationpricing.operationno, '  
select @strsql = @strsql + ' (CAST(Sum(autodata.partscount)AS Float)/ISNULL(ComponentOperationPricing.SubOperations,1)) AS operationcount,D.Cdate as date1'   
select @strsql = @strsql + ' FROM autodata INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN  '  
select @strsql = @strsql + ' componentinformation ON autodata.comp = componentinformation.InterfaceID  INNER JOIN '  
select @strsql = @strsql + ' componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID'  
select @strsql = @strsql + ' AND componentinformation.componentid = componentoperationpricing.componentid) '  
select @strsql = @strsql + ' and componentoperationpricing.machineid=machineinformation.machineid '  
select @strsql = @strsql + ' inner join #DailyProductionFromAutodataT2 D on Machineinformation.machineid=D.machineid  
AND componentinformation.componentid=D.Component AND componentoperationpricing.operationno=D.Operation '  
select @strsql = @strsql + ' Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid'  
select @strsql = @strsql + ' WHERE (autodata.ndtime > ''' + convert(nvarchar(20),@MonthStart) + ''')'  
select @strsql = @strsql + ' AND (autodata.ndtime <= convert(nvarchar(20),D.ToTm)) '  
select @strsql = @strsql + @StrMPlantid + @strmachine + @strcomponentid + @stroperation  
select @strsql = @strsql + ' AND (autodata.datatype = 1)'  
select @strsql = @strsql + ' GROUP BY machineinformation.machineid,componentinformation.componentid, componentoperationpricing.operationno,ComponentOperationPricing.SubOperations,D.Cdate ) '  
select @strsql = @strsql + ' as t5 inner join #DailyProductionFromAutodataT2 on (t5.machineid = #DailyProductionFromAutodataT2.machineid '  
select @strsql = @strsql + 'and t5.componentid = #DailyProductionFromAutodataT2.component '  
select @strsql = @strsql + 'and t5.operationno = #DailyProductionFromAutodataT2.operation and t5.date1=#DailyProductionFromAutodataT2.Cdate)'  
exec(@strsql)  
  
--Mod 4(1) Apply PDT  
If (select valueintext from cockpitdefaults where parameter='Ignore_Count_4m_Pld')='Y'  
Begin  
  Select @Strsql = 'Update #DailyProductionFromAutodataT2 Set CummCount= Isnull(CummCount,0)-isNull(t2.Count,0)'  
     Select @Strsql =@Strsql + ' from (Select machineinformation.machineid,'  
  Select @Strsql =@Strsql + ' (cast(Sum(autodata.partscount) as float)/Isnull(Componentoperationpricing.Suboperations,1)) as Count,' --NR0097  
     Select @Strsql =@Strsql + ' ComponentInformation.Componentid,Componentoperationpricing.operationno,D.Cdate as date1 from autodata  
       inner Join #PlannedDownTimes T  on T.machineinterface = autodata.mc  
       inner join machineinformation on machineinformation.interfaceid=autodata.mc  
       inner join ComponentInformation on ComponentInformation.Interfaceid=autodata.Comp  
       inner join Componentoperationpricing on Componentoperationpricing.Interfaceid=autodata.opn and Componentoperationpricing.componentid=ComponentInformation.componentid and Componentoperationpricing.machineID = machineinformation.MachineID  
    inner join #DailyProductionFromAutodataT2 D on Machineinformation.machineid=D.machineid AND componentinformation.componentid=D.Component AND componentoperationpricing.operationno=D.Operation  
    Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid --DR0296  
       Where autodata.datatype=1 and (autodata.ndtime> T.StartTime_PDT and autodata.ndtime <= T.EndTime_PDT) '  
     Select @Strsql = @Strsql + ' and (autodata.ndtime > ''' +Convert(nvarchar(20),@MonthStart) + ''' and autodata.ndtime <= convert(nvarchar(20),D.ToTm)) '  
     select @strsql = @strsql + @StrMPlantid + @strmachine + @strcomponentid + @stroperation  
     Select @Strsql = @Strsql + ' Group by machineinformation.machineid,ComponentInformation.componentid,Componentoperationpricing.operationno,  
       Componentoperationpricing.Suboperations,D.Cdate) as T2 inner join #DailyProductionFromAutodataT2 on (T2.machineid = #DailyProductionFromAutodataT2.machineid  
       and T2.Componentid= #DailyProductionFromAutodataT2.Component and T2.operationno=#DailyProductionFromAutodataT2.operation and t2.date1 = #DailyProductionFromAutodataT2.cdate)'            
    Exec(@strsql)  
End  
  
  
---Calculation of target count  
Declare @TrSql3 varchar(8000)  
Declare @strmachine3 nvarchar(255)  
Declare @stroperation3 nvarchar(255)  
Declare @strcomponent3 nvarchar(255)  
select @TrSql3=''  
SELECT @strmachine3 = ''  
SELECT @strcomponent3= ''  
SELECT @stroperation3 = ''  
  
if isnull(@MachineID,'') <> ''  
 BEGIN  
 SELECT @strmachine3 = ' AND ( machine = N''' + @MachineID+ ''')'  
 END  
  
if isnull(@ComponentID, '') <> ''  
 BEGIN  
 SELECT @strcomponent3 = ' AND ( component = N''' + @ComponentID+ ''')'  
 END  
  
if isnull(@OperationNo, '') <> ''  
 BEGIN  
 SELECT @stroperation3 = ' AND ( Operation = N''' + @OperationNo+ ''')'  
 END  
  
if isnull(@Targetsource,'')='Exact Schedule'  
BEGIN  
  select @TrSql3=''  
  select @TrSql3='update #DailyProductionFromAutodataT2 set TargetCount= isnull(TargetCount,0)+ ISNULL(t1.tcount,0) from  
   ( select date as date1,machine,component,operation,sum(idealcount) as tcount from  
     loadschedule where date>=''' +convert(nvarchar(20),@startDate)+''' and date<=''' +convert(nvarchar(20),@EndDate)+ ''' '  
 select @TrSql3= @TrSql3 + @strmachine3 + @strcomponent3 + @stroperation3  
  select @TrSql3=@TrSql3+ 'group by date,machine,component,operation ) as t1 inner join #DailyProductionFromAutodataT2 on  
     t1.date1=#DailyProductionFromAutodataT2.Cdate and t1.machine=#DailyProductionFromAutodataT2.MachineId and t1.component=#DailyProductionFromAutodataT2.Component  
     and t1.operation=#DailyProductionFromAutodataT2.Operation '   
 EXEC (@TrSql3)  
    
END  
  
if isnull(@Targetsource,'')='Default Target per CO'  
BEGIN  
  
 select @TrSql3=''  
 select @TrSql3='update #DailyProductionFromAutodataT2 set TargetCount= isnull(TargetCount,0)+ ISNULL(t1.tcount,0) from  
 ( select DATE AS date1, machine,component,operation,sum(idealcount) as tcount from  
 loadschedule where date=(SELECT TOP 1 DATE FROM LOADSCHEDULE ORDER BY DATE DESC) and SHIFT=(SELECT TOP 1 SHIFT FROM LOADSCHEDULE ORDER BY SHIFT DESC)'  
 select @TrSql3= @TrSql3 + @strmachine3 + @strcomponent3 + @stroperation3  
 select @TrSql3=@TrSql3+ ' group by date,machine,component,operation ) as t1 inner join #DailyProductionFromAutodataT2 on  
 t1.machine=#DailyProductionFromAutodataT2.MachineId and  
 t1.component=#DailyProductionFromAutodataT2.Component  
 and t1.operation=#DailyProductionFromAutodataT2.Operation '   
 EXEC (@TrSql3)  
   
 UPDATE #DailyProductionFromAutodataT2 SET TargetCount=TargetCount*(SELECT COUNT(*) FROM  SHIFTDETAILS WHERE RUNNING=1)  
   
END  
  
IF ISNULL(@Targetsource,'')='% Ideal'  
BEGIN  
 select @strmachine3=''  
 if isnull(@MachineID,'') <> ''  
 BEGIN  
 SELECT @strmachine3 = ' AND ( CO.machineID = N''' + @MachineID+ ''')'  
 END  
  
 select @strcomponent3=''  
 if isnull(@ComponentID, '') <> ''  
 BEGIN  
 SELECT @strcomponent3 = ' AND (CO.componentID = N''' + @ComponentID+ ''')'  
 END  
  
 select @stroperation3=''  
 if isnull(@OperationNo, '') <> ''  
 BEGIN  
 SELECT @stroperation3 = ' AND ( CO.operationno = N''' + @OperationNo + ''')'  
 END  
   
 select @TrSql3=''  
 select @TrSql3='update #DailyProductionFromAutodataT2 set TargetCount= isnull(TargetCount,0)+ ISNULL(t1.tcount,0) from  
 ( select CO.machineid as machine,CO.componentid as component,CO.Operationno as operation, tcount=((datediff(second,#DailyProductionFromAutodataT2.Fromtm,#DailyProductionFromAutodataT2.Totm)*CO.suboperations)/CO.cycletime)*isnull(CO.targetpercent,100) /100  
 from componentoperationpricing CO inner join #DailyProductionFromAutodataT2 on CO.Componentid=#DailyProductionFromAutodataT2.Component  
 and Co.operationno=#DailyProductionFromAutodataT2.Operation and CO.machineid = #DailyProductionFromAutodataT2.machineID'  
 select @TrSql3= @TrSql3 + @strmachine3 + @strcomponent3 + @stroperation3  
 select @TrSql3=@TrSql3+ '  ) as t1 inner join #DailyProductionFromAutodataT2 on  
 t1.component=#DailyProductionFromAutodataT2.Component  
 and t1.operation=#DailyProductionFromAutodataT2.Operation'   
 select @TrSql3 = @TrSql3 + ' and t1.machine = #DailyProductionFromAutodataT2.machineID '  
 EXEC (@TrSql3)  
  
  
 If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'  
 BEGIN  
  
  update #DailyProductionFromAutodataT2 set Targetcount=Targetcount-((cast(t3.Totalpdt as float)/cast(datediff(ss,t3.Starttime,t3.Endtime) as float))*Targetcount)  
  from   
  (  
  Select Machineid,Starttime,Endtime,Sum(Datediff(ss,Starttimepdt,Endtimepdt))as TotalPDT  
  From   
  (  
  select fd.StartTime,fd.EndTime,Case   
     when fd.StartTime <= pdt.StartTime then pdt.StartTime  
     else fd.StartTime  
     End as Starttimepdt  
  ,Case when fd.EndTime >= pdt.EndTime then pdt.EndTime else fd.EndTime End as Endtimepdt  
  ,fd.MachineID   
  from   
  (Select distinct Machineid,FromTm as StartTime ,ToTm  as EndTime from #DailyProductionFromAutodataT2) as fd  
  cross join planneddowntimes pdt  
  where PDTstatus = 1  and fd.machineID = pdt.Machine and --and DownReason <> 'SDT'  
  ((pdt.StartTime >= fd.StartTime and pdt.EndTime <= fd.EndTime)or   
  (pdt.StartTime < fd.StartTime and pdt.EndTime > fd.StartTime and pdt.EndTime <=fd.EndTime)or  
  (pdt.StartTime >= fd.StartTime and pdt.StartTime <fd.EndTime and pdt.EndTime > fd.EndTime) or  
  (pdt.StartTime < fd.StartTime and pdt.EndTime > fd.EndTime))  
  )T2 group by Machineid,Starttime,Endtime  
  )T3 inner join #DailyProductionFromAutodataT2 on T3.Machineid=#DailyProductionFromAutodataT2.machineid and T3.Starttime=#DailyProductionFromAutodataT2.FromTm    
  and T3.Endtime= #DailyProductionFromAutodataT2.ToTm  where Targetcount>0  
  
 End  
  
END  
  
select @timeformat ='ss'  
select @timeformat = isnull((select valueintext from cockpitdefaults where parameter='timeformat'),'ss')  
  
if (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')  
begin  
select @timeformat = 'ss'  
end  
  
Update #DailyProductionFromAutodataT2 SET ProdPerHour=(isnull(#DailyProductionFromAutodataT2.CycleTime,0)+isnull(#DailyProductionFromAutodataT2.LoadUnload,0))/60   
  
Update #DailyProductionFromAutodataT2 SET ProdTotal=isnull(Round(#DailyProductionFromAutodataT2.CountShift1,2),0)+isnull(Round(#DailyProductionFromAutodataT2.CountShift2,2),0)+isnull(Round(#DailyProductionFromAutodataT2.CountShift3,2),0)   
  
Update #DailyProductionFromAutodataT2 SET WorkingHours=Round((ProdTotal/ProdPerHour),2)  
  
declare @shiftname1 nvarchar(20)  
declare @shiftname2 nvarchar(20)  
declare @shiftname3 nvarchar(20)  
select @shiftname1 = (select top 1 NameShift1 from #DailyProductionFromAutodataT2 where Nameshift1 > '')  
select @shiftname2 = (select top 1 NameShift2 from #DailyProductionFromAutodataT2 where Nameshift2 > '')  
select @shiftname3 = (select top 1 NameShift3 from #DailyProductionFromAutodataT2 where Nameshift3 > '')  
  
Select  #DailyProductionFromAutodataT1.Pdate,#DailyProductionFromAutodataT1.MachineID,isnull(#DailyProductionFromAutodataT2.Component,'') as Component,isnull(#DailyProductionFromAutodataT2.Operation,'') as Operation,  
dbo.f_formattime(isnull(#DailyProductionFromAutodataT2.CycleTime,0),@timeformat) as StdCycleTime,dbo.f_formattime(isnull(#DailyProductionFromAutodataT2.LoadUnload,0),@timeformat) as StdLoadUnload,  
isnull(#DailyProductionFromAutodataT2.ProdPerHour,0) as ProdPerHour,  
isnull(#DailyProductionFromAutodataT2.TargetCount,0) as ShiftTarget,  
isnull(Round(#DailyProductionFromAutodataT2.CountShift1,2),0)as CountShift1,   
isnull(Round(#DailyProductionFromAutodataT2.CountShift2,2),0)as CountShift2,   
isnull(Round(#DailyProductionFromAutodataT2.CountShift3,2),0) as CountShift3,   
isnull(#DailyProductionFromAutodataT2.ProdTotal,0) as ProdTotal,  
isnull(#DailyProductionFromAutodataT2.CummCount,0) as CummCount,  
isnull(#DailyProductionFromAutodataT2.WorkingHours,0) as WorkingHours,  
dbo.f_formattime((ISNULL(#DailyProductionFromAutodataT1.A,0) + ISNULL(#DailyProductionFromAutodataT1.B,0) + ISNULL(#DailyProductionFromAutodataT1.C,0) + ISNULL(#DailyProductionFromAutodataT1.D,0) + ISNULL(#DailyProductionFromAutodataT1.E,0) + ISNULL(#DailyProductionFromAutodataT1.F,0) + ISNULL(#DailyProductionFromAutodataT1.G,0)), @timeformat) as DownTime,  
dbo.f_formattime((isnull(#DailyProductionFromAutodataT2.WorkingHours,0)+ isnull(#DailyProductionFromAutodataT1.DownTime,0)),@timeformat) as TotalTime,  
dbo.f_formattime(#DailyProductionFromAutodataT1.A,@timeformat) as A,dbo.f_formattime(#DailyProductionFromAutodataT1.B,@timeformat) as B,dbo.f_formattime(#DailyProductionFromAutodataT1.C,@timeformat) as C,  
dbo.f_formattime(#DailyProductionFromAutodataT1.D,@timeformat) as D,dbo.f_formattime(#DailyProductionFromAutodataT1.E,@timeformat) as E,dbo.f_formattime(#DailyProductionFromAutodataT1.F,@timeformat) as F,  
dbo.f_formattime(#DailyProductionFromAutodataT1.G,@timeformat) as G,  
dbo.f_formattime(#DailyProductionFromAutodataT1.Utilisedtime, @timeformat) as ProductiveTime,  
dbo.f_formattime(#DailyProductionFromAutodataT1.NonproductiveTime, @timeformat) as NonproductiveTime,#DailyProductionFromAutodataT1.ProductionEfficiency as PE  
from   #DailyProductionFromAutodataT1 LEFT OUTER JOIN #DailyProductionFromAutodataT2 ON  
 #DailyProductionFromAutodataT1.MachineID = #DailyProductionFromAutodataT2.MachineID  
 and #DailyProductionFromAutodataT1.Pdate=#DailyProductionFromAutodataT2.Cdate  
END  
  
  
