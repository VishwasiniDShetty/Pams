/****** Object:  Procedure [dbo].[s_GetMonthwiseEfficiencyFromAutodata_Shanthi]    Committed by VersionSQL https://www.versionsql.com ******/

---DR0379 - swathiKS - 29/Nov/2017 :: To Rename Ourput columns to handle Error (3265 - Item cannot be found in the collection corresponding to the requested name or ordinal) For SPF   
--exec [s_GetMonthwiseEfficiencyFromAutodata_Shanthi] '2015-12-22','','Compact X','',''    
    
CREATE PROCEDURE [dbo].[s_GetMonthwiseEfficiencyFromAutodata_Shanthi]    
 @StartTime datetime,    
 @MachineID nvarchar(max) = '',
 @GroupID As nvarchar(max) = '',
 @PlantID nvarchar(50)='',    
 @Param as nvarchar(20)=''    
    
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    
SET NOCOUNT ON;    
    
Create Table #ShiftTemp    
(    
 PDate datetime,    
 ShiftName nvarchar(20) null,    
 FromTime datetime,    
 ToTime Datetime    
)    
    
    
CREATE TABLE #CockPitData     
(    
 Pdt datetime,    
 Strttm datetime,    
 ndtim datetime,    
 shftnm nvarchar(50),    
 ShiftID int,    
 MachineID nvarchar(50),    
 GroupID nvarchar(50),
 MachineInterface nvarchar(50),    
 ProductionEfficiency float,    
 AvailabilityEfficiency float,    
 OverallEfficiency float,    
 QualityEfficiency float default 0, --Vas    
 Components float,    
 UtilisedTime float,    
 ManagementLoss float,    
 DownTime float,    
 TurnOver Float default 0,    
 RejCount float default 0,     
 CN float,    
 Rejection float    
 ,MLDown float    
 ,AvgProductionEfficiency float DEFAULT 0     
 ,AvgAvailabilityEfficiency float DEFAULT 0      
 ,AvgOverallEfficiency float DEFAULT 0,     
 TargetOEE float DEFAULT 0 ,    
 TotalComp float default 0,    
 TotalDowntime int,    
 TotaldowntimeInt float ,    
 MachineHourRate int,    
 operator nvarchar(1000),    
 TotalTime float    
)    
---mod 4    
CREATE TABLE #PlannedDownTimesEffi    
(    
 SlNo int not null identity(1,1),    
 Starttime datetime,    
 EndTime datetime,    
 DownReason nvarchar(50),    
 Machine nvarchar(50),    
 MInterface nvarchar(50),    
 DStart datetime,    
 Dend datetime    
)    
---mod 4    
Declare @strSql as nvarchar(4000)    
Declare @strMachine as nvarchar(max)    
Declare @strPlantID as nvarchar(4000)  
Declare @StrGroupID AS NVarchar(max)
    
Declare @Counter as datetime    
declare @CurStarttime as datetime    
  
declare @StrMCJoined as nvarchar(max)
declare @StrGroupJoined as nvarchar(max)

SET @strMachine = ''    
SET @strPlantID = ''    
select @StrGroupID=''

Declare @StrTPMMachines AS nvarchar(500) 
SELECT @StrTPMMachines=''

IF ( SELECT TOP 1 ValueInText FROM  CockpitDefaults WHERE Parameter='TpmEnbMac')='E'  
BEGIN  
 SET  @StrTPMMachines = ' AND MachineInformation.TPMTrakEnabled = 1 '  
END  
ELSE  
BEGIN  
 SET  @StrTPMMachines = ' '  
END 

--if isnull(@machineid,'')<> ''    
--begin    
     
-- SET @strMachine = ' AND MachineInformation.MachineID = N''' + @machineid + ''''    
--end 

if isnull(@machineid,'') <> ''
begin
	select @StrMCJoined =  (case when (coalesce( +@StrMCJoined + ',''', '''')) = ''''  then 'N''' else @StrMCJoined+',N''' end) +item+'''' from [SplitStrings](@MachineID, ',')    
	if @StrMCJoined = 'N'''''  
	set @StrMCJoined = '' 
	select @MachineID = @StrMCJoined

	SET @strMachine = ' AND MachineInformation.MachineID in (' + @MachineID +')'
end

if isnull(@PlantID,'')<> ''    
Begin    
    
 SET @strPlantID =  ' AND PlantMachine.PlantID = N''' + @PlantID + ''''    
End    
    
--If isnull(@GroupID ,'') <> ''
--Begin
--Select @StrGroupID = ' And ( PlantMachineGroups.GroupID = N''' + @GroupID + ''')'
--End

If isnull(@GroupID ,'') <> ''
Begin
	select @StrGroupJoined =  (case when (coalesce( +@StrGroupJoined + ',''', '''')) = ''''  then 'N''' else @StrGroupJoined+',N''' end) +item+'''' from [SplitStrings](@GroupID, ',')    
	if @StrGroupJoined = 'N'''''  
	set @StrGroupJoined = '' 
	select @GroupID = @StrGroupJoined

	Select @StrGroupID = ' And ( PlantMachineGroups.GroupID IN (' + @GroupID + '))'
End

select @CurStarttime = Dateadd(month,-1,@Starttime)    

While(@CurStarttime <= @Starttime)    
begin    
   insert into #ShiftTemp(Pdate,ShiftName,FromTime,ToTime)    
   select cast(convert(nvarchar(10),dbo.f_GetLogicalMonth(@CurStarttime,'start'),112) as datetime),'ALL',dbo.f_GetLogicalMonth(@CurStarttime,'start'),dbo.f_GetLogicalmonth(@CurStarttime,'End')    
   select @CurStarttime = Dateadd(month,1,@CurStarttime)    
end   


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

Declare @T_ST AS Datetime 
Declare @T_ED AS Datetime 

---ER0374 from here
--Select @T_ST=dbo.f_GetLogicalDay(@StartTime,'start')
--Select @T_ED=dbo.f_GetLogicalDay(@EndTime,'End')
Select @T_ST=(select min(fromtime) from #ShiftTemp)
Select @T_ED=(select max(totime) from #ShiftTemp)

---ER0374 Till here

Select @strsql=''
select @strsql ='insert into #T_autodata '
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'
	select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime,PartsCount,id'
select @strsql = @strsql + ' from autodata where (( sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_ED,120)+''' ) OR '
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' )OR '
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ST,120)+'''
					and ndtime<='''+convert(nvarchar(25),@T_ED,120)+''' )'
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' and sttime<'''+convert(nvarchar(25),@T_ED,120)+''' ) )'
print @strsql
exec (@strsql)

    
---mod 4(5):Optimization    
SET @strSql = 'INSERT INTO #CockpitData (    
   Pdt,    
   Strttm,    
   ndtim,    
   shftnm,    
   MachineID , 
   GroupID,
   MachineInterface,    
   ProductionEfficiency ,    
   AvailabilityEfficiency ,    
   OverallEfficiency ,    
   Components ,    
   UtilisedTime ,     
   ManagementLoss,    
   DownTime ,    
   TurnOver,    
   CN,    
   Rejection,totaltime    
   ) '    
   SET @strSql = @strSql + ' SELECT S.Pdate,S.FromTime,S.ToTime,S.ShiftName,MachineInformation.MachineID,PlantMachineGroups.GroupID, MachineInformation.interfaceid ,0,0,0,0,0,0,0,0,0,0,0 FROM MachineInformation    
        INNER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID    
		LEFT JOIN PlantMachineGroups on machineinformation.machineid = PlantMachineGroups.machineid
		cross join #ShiftTemp S whERE MachineInformation.interfaceid > ''0''  '    
   SET @strSql = @strSql + @strPlantID + @strMachine +@StrTPMMachines + @StrGroupID  
   EXEC(@strSql)    
--vasavi  

    
/*    
UPDATE #CockpitData SET Operator = t2.opr    
from(    
select  #CockpitData.Strttm as intime, mc,employeeinformation.Employeeid as opr,#CockpitData.shftnm    
from autodata inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface INNER JOIN    
employeeinformation ON    employeeinformation.interfaceid=autodata.opr    
where (autodata.datatype=1 OR autodata.datatype=2 )    
AND(( (autodata.msttime>=#CockpitData.Strttm) and (autodata.ndtime<=#CockpitData.ndtim))    
OR ((autodata.msttime<#CockpitData.Strttm)and (autodata.ndtime>#CockpitData.Strttm)and (autodata.ndtime<=#CockpitData.ndtim))    
OR ((autodata.msttime>=#CockpitData.Strttm)and (autodata.msttime<#CockpitData.ndtim)and (autodata.ndtime>#CockpitData.ndtim))    
OR((autodata.msttime<#CockpitData.Strttm)and (autodata.ndtime>#CockpitData.ndtim))    
)    
group by autodata.mc,#CockpitData.Strttm,employeeinformation.Employeeid,#CockpitData.shftnm)    
as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm    
*/    
    
---utilised time    
-- Type 1    
UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)    
from    
(select     #CockpitData.Strttm as intime, mc,    
sum(case when ( (autodata.msttime>= #CockpitData.Strttm) and (autodata.ndtime<=#CockpitData.ndtim)) then  (cycletime+loadunload)    
   when ((autodata.msttime< #CockpitData.Strttm)and (autodata.ndtime> #CockpitData.Strttm)and (autodata.ndtime<=#CockpitData.ndtim)) then DateDiff(second,  #CockpitData.Strttm, ndtime)    
   when ((autodata.msttime>= #CockpitData.Strttm)and (autodata.msttime<#CockpitData.ndtim)and (autodata.ndtime>#CockpitData.ndtim)) then DateDiff(second, mstTime, #CockpitData.ndtim)    
   when ((autodata.msttime< #CockpitData.Strttm)and (autodata.ndtime>#CockpitData.ndtim)) then DateDiff(second,  #CockpitData.Strttm, #CockpitData.ndtim) END ) as  cycle    
from #T_autodata autodata inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface    
where (autodata.datatype=1)    
AND(( (autodata.msttime>=#CockpitData.Strttm) and (autodata.ndtime<=#CockpitData.ndtim))    
OR ((autodata.msttime<#CockpitData.Strttm)and (autodata.ndtime>#CockpitData.Strttm)and (autodata.ndtime<=#CockpitData.ndtim))    
OR ((autodata.msttime>=#CockpitData.Strttm)and (autodata.msttime<#CockpitData.ndtim)and (autodata.ndtime>#CockpitData.ndtim))    
OR((autodata.msttime<#CockpitData.Strttm)and (autodata.ndtime>#CockpitData.ndtim))    
)    
group by autodata.mc,#CockpitData.Strttm    
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm    
    
UPDATE  #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)    
FROM    
(Select T1.DurStrt as intime,AutoData.mc ,    
SUM(    
CASE    
 When autodata.sttime <= T1.DurStrt Then datediff(s, T1.DurStrt,autodata.ndtime )    
 When autodata.sttime > T1.DurStrt Then datediff(s , autodata.sttime,autodata.ndtime)    
END)  as Down    
From #T_autodata AutoData INNER Join    
 (Select mc,Sttime,NdTime,#CockpitData.Strttm as DurStrt,#CockpitData.ndtim as DurEnd    
  From #T_autodata AutoData inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface    
  Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And    
  (msttime < #CockpitData.Strttm)And (ndtime > #CockpitData.Strttm) AND (ndtime <= #CockpitData.ndtim)) as T1    
ON AutoData.mc=T1.mc    
Where AutoData.DataType=2    
And ( autodata.Sttime > T1.Sttime )    
And ( autodata.ndtime <  T1.ndtime )    
AND ( autodata.ndtime >  T1.DurStrt )    
GROUP BY AUTODATA.mc,T1.DurStrt )AS T2 Inner Join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm    
    
    
--ICD for Type 3 prod record      
UPDATE  #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)    
FROM    
(Select T1.DurStrt as intime,AutoData.mc ,    
SUM(CASE    
 When autodata.ndtime > T1.DurEnd Then datediff(s,autodata.sttime, T1.DurEnd )    
 When autodata.ndtime <=T1.DurEnd Then datediff(s , autodata.sttime,autodata.ndtime)    
END) as Down    
From #T_autodata AutoData INNER Join    
 (Select mc,Sttime,NdTime,#CockpitData.Strttm as DurStrt,#CockpitData.ndtim as DurEnd From #T_autodata AutoData    
  inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface    
  Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And    
  (sttime >= #CockpitData.Strttm)And (ndtime > #CockpitData.ndtim) and sttime<#CockpitData.ndtim ) as T1    
ON AutoData.mc=T1.mc    
Where AutoData.DataType=2    
And (T1.Sttime < autodata.sttime  )    
And ( T1.ndtime >  autodata.ndtime)    
AND (autodata.sttime  <  T1.DurEnd)    
GROUP BY AUTODATA.mc,T1.DurStrt )AS T2 Inner Join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm    
    
    
--ICD for Type 4 prod record     
UPDATE  #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)    
FROM    
(Select T1.DurStrt as intime, AutoData.mc ,    
SUM(CASE    
    
 When autodata.sttime >= T1.DurStrt AND autodata.ndtime <= T1.DurEnd Then datediff(s , autodata.sttime,autodata.ndtime)    
 When autodata.sttime < T1.DurStrt AND autodata.ndtime<=T1.DurEnd and autodata.ndtime > T1.DurStrt Then datediff(s, T1.DurStrt,autodata.ndtime )    
 When autodata.sttime>=T1.DurStrt and autodata.ndtime >T1.DurEnd AND autodata.sttime<T1.DurEnd  Then datediff(s,autodata.sttime, T1.DurEnd )    
 When autodata.sttime<T1.DurStrt AND autodata.ndtime>T1.DurEnd   Then datediff(s , T1.DurStrt,T1.DurEnd)    
    
END) as Down    
From #T_autodata AutoData INNER Join    
 (Select mc,Sttime,NdTime,#CockpitData.Strttm as DurStrt,#CockpitData.ndtim as DurEnd  From #T_autodata AutoData    
  inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface    
  Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And    
  (msttime < #CockpitData.Strttm)And (ndtime > #CockpitData.ndtim) ) as T1    
ON AutoData.mc=T1.mc    
Where AutoData.DataType=2    
And (T1.Sttime < autodata.sttime  )    
And ( T1.ndtime >  autodata.ndtime)    
AND (autodata.ndtime  >  T1.DurStrt)    
AND (autodata.sttime  <  T1.DurEnd)    
GROUP BY AUTODATA.mc,T1.DurStrt    
)AS T2 Inner Join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm    
    
    
---mod 4 : Get PDT    
insert into #PlannedDownTimesEffi(StartTime,EndTime,DownReason,Machine,MInterface,DStart ,Dend )      
select    
CASE When StartTime<#CockpitData.Strttm Then #CockpitData.Strttm Else StartTime End,    
case When EndTime>#CockpitData.ndtim Then #CockpitData.ndtim Else EndTime End,DownReason,    
PlannedDownTimes.Machine,#CockpitData.machineinterface,#CockpitData.Strttm,#CockpitData.ndtim    
FROM PlannedDownTimes inner join #CockpitData on #CockpitData.MachineID=PlannedDownTimes.Machine    
WHERE pdtstatus=1 and (    
(StartTime >= #CockpitData.Strttm  AND EndTime <=#CockpitData.ndtim)    
OR ( StartTime < #CockpitData.Strttm  AND EndTime <= #CockpitData.ndtim AND EndTime > #CockpitData.Strttm )    
OR ( StartTime >= #CockpitData.Strttm   AND StartTime <#CockpitData.ndtim AND EndTime > #CockpitData.ndtim )    
OR ( StartTime < #CockpitData.Strttm  AND EndTime > #CockpitData.ndtim) )    
ORDER BY StartTime    
    
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'    
BEGIN    
    
 UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0)- isNull(t2.Pdown,0)    
 FROM(    
  --Production Time in PDT    
  SELECT T.Dstart,autodata.MC,SUM    
   (CASE    
   WHEN autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.cycletime+autodata.loadunload)    
   WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)    
   WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )    
   WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )    
   END)  as Pdown    
  FROM     
  (select mc,msttime,ndtime,datatype,cycletime,loadunload from #T_autodata autodata    
    inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface    
     where autodata.DataType=1 And     
    ((autodata.msttime >= #CockpitData.Strttm  AND autodata.ndtime <=#CockpitData.ndtim)    
    OR ( autodata.msttime < #CockpitData.Strttm  AND autodata.ndtime <= #CockpitData.ndtim AND autodata.ndtime > #CockpitData.Strttm )    
    OR ( autodata.msttime >= #CockpitData.Strttm   AND autodata.msttime <#CockpitData.ndtim AND autodata.ndtime > #CockpitData.ndtim )    
    OR ( autodata.msttime < #CockpitData.Strttm  AND autodata.ndtime > #CockpitData.ndtim))    
  )    
  AutoData inner jOIN #PlannedDownTimesEffi T on T.MInterface=autodata.mc    
  WHERE autodata.DataType=1 AND    
   (    
   (autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)    
   OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )    
   OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )    
   OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )       
  group by autodata.mc,T.Dstart    
 )as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.Dstart=#CockpitData.Strttm    
    
    
  ---mod 1 Handling interaction between PDT and ICD    
 /* If production  Records of TYPE-1*/    
  UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0)+ isNull(t2.IPDT,0)    
  FROM( Select T.Dstart,T1.mc ,    
  SUM(    
  CASE      
   When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1    
   When T1.sttime < T.StartTime  AND  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2    
   When ( T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime ) Then datediff(s, T1.sttime,T.EndTime ) ---type 3    
   when ( T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4    
  END) as IPDT from    
   (Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype    
   ,#CockpitData.Strttm as DurStrt,#CockpitData.ndtim as DurEnd from #T_autodata  A    
   inner join #CockpitData on A.mc=#CockpitData.MachineInterface    
   Where A.DataType=2    
   and exists     
    (    
    Select B.Sttime,B.NdTime,B.mc From #T_autodata B    
    inner join #CockpitData on B.mc=#CockpitData.MachineInterface    
    Where B.mc = A.mc and    
    B.DataType=1 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And    
    (B.msttime >= #CockpitData.Strttm AND B.ndtime <= #CockpitData.ndtim) and    
    (B.sttime <= A.sttime) AND (B.ndtime >= A.ndtime)  --DR0339    
    )    
    )as T1 inner join #PlannedDownTimesEffi T on T.Minterface=T1.mc and T1.DurStrt=T.Dstart    
    AND    
   ((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))    
   or (T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)    
   or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )    
   or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )group by T1.mc,T.Dstart    
   )AS T2  inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.Dstart=#CockpitData.Strttm    
     
 /* If production  Records of TYPE-2*/     
  UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0)+ isNull(t2.IPDT,0) FROM    
  (Select T.Dstart,T1.mc ,    
  SUM(    
  CASE      
   When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1    
   When T1.sttime < T.StartTime  AND  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2    
   When ( T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime ) Then datediff(s, T1.sttime,T.EndTime ) ---type 3    
   when ( T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4    
  END) as IPDT from    
  (Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype     
  ,#CockpitData.Strttm as DurStrt,#CockpitData.ndtim as DurEnd from #T_autodata A    
  inner join #CockpitData on A.mc=#CockpitData.MachineInterface    
  Where A.DataType=2    
  and exists     
  (    
  Select B.Sttime,B.NdTime From #T_autodata B    
  inner join #CockpitData on B.mc=#CockpitData.MachineInterface    
  Where B.mc = A.mc and    
  B.DataType=1 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And    
  (B.msttime < #CockpitData.Strttm And B.ndtime > #CockpitData.Strttm AND B.ndtime <= #CockpitData.ndtim)     
  And ((A.Sttime > B.Sttime) And ( A.ndtime < B.ndtime) AND ( A.ndtime > #CockpitData.Strttm ))    
  )    
  )as T1 inner join #PlannedDownTimesEffi T on T.Minterface=T1.mc and T1.DurStrt=T.Dstart AND    
  (( T.StartTime >= T1.DurStrt ) And ( T.StartTime <  T1.ndtime ))     
  GROUP BY T1.mc,T.Dstart )as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.Dstart=#CockpitData.Strttm    
    
    
    
    
 /* If production Records of TYPE-3*/    
 UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0)+ isNull(t2.IPDT,0)    
 FROM    
 (Select T.Dstart,T1.mc ,    
 SUM(    
 CASE      
  When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1    
  When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2    
  When ( T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime ) Then datediff(s, T1.sttime,T.EndTime ) ---type 3    
  when ( T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4    
 END) as IPDT from    
  (Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype    
  ,#CockpitData.Strttm as DurStrt,#CockpitData.ndtim as DurEnd from #T_autodata A    
  inner join #CockpitData on A.mc=#CockpitData.MachineInterface    
  Where A.DataType=2    
  and exists     
  (    
  Select B.Sttime,B.NdTime From #T_autodata B    
  inner join #CockpitData on B.mc=#CockpitData.MachineInterface    
  Where B.mc = A.mc and    
  B.DataType=1 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And    
  (B.sttime >= #CockpitData.Strttm And B.ndtime > #CockpitData.ndtim and B.sttime <#CockpitData.ndtim) and    
  ((B.Sttime < A.sttime  )And ( B.ndtime > A.ndtime) AND (A.msttime < #CockpitData.ndtim))    
  )    
  )as T1 inner jOIN #PlannedDownTimesEffi T on T.Minterface=T1.mc and T1.DurStrt=T.Dstart    
  AND (( T.EndTime > T1.Sttime )And ( T.EndTime <=T1.DurEnd ))    
  GROUP BY T1.mc,T.Dstart    
  )as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.Dstart=#CockpitData.Strttm    
    
    
    
/* If production Records of TYPE-4*/    
 UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0)+ isNull(t2.IPDT,0)    
 FROM    
 (Select T.Dstart,T1.mc ,    
 SUM(    
 CASE      
  When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1    
  When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2    
  When ( T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime ) Then datediff(s, T1.sttime,T.EndTime ) ---type 3    
  when ( T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4    
 END) as IPDT from    
 (Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype     
 ,#CockpitData.Strttm as DurStrt,#CockpitData.ndtim as DurEnd from #T_autodata A    
 inner join #CockpitData on A.mc=#CockpitData.MachineInterface    
 Where A.DataType=2    
 and exists     
 (    
 Select B.Sttime,B.NdTime From #T_autodata B    
    inner join #CockpitData on B.mc=#CockpitData.MachineInterface    
 Where B.mc = A.mc and    
 B.DataType=1 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And    
 (B.msttime < #CockpitData.Strttm And B.ndtime > #CockpitData.ndtim)    
 And ((B.Sttime < A.sttime)And ( B.ndtime >  A.ndtime)AND (A.ndtime  >  #CockpitData.Strttm) AND (A.sttime  <  #CockpitData.ndtim))    
 )    
 )as T1 inner jOIN #PlannedDownTimesEffi T on  T.Minterface=T1.mc and T1.DurStrt=T.Dstart AND    
 (( T.StartTime >=T1.DurStrt) And ( T.EndTime <=T1.DurEnd ))     
    GROUP BY T1.mc,T.Dstart)as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.Dstart=#CockpitData.Strttm    
    
END    
    
    
    
    
-- Get the value of CN and components    
-- Type 1 and type 2    
UPDATE #CockpitData SET CN = isnull(CN,0) + isNull(t2.C1N1,0),components=isnull(components,0)+isnull(T2.pcount,0)    
from    
(select  #CockpitData.Strttm as intime,mc,    
SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))*autodata.partscount) C1N1,    
sum(CAST((autodata.partscount) AS Float)/ISNULL(componentoperationpricing.SubOperations,1)) as pcount    
    
FROM #T_autodata autodata INNER JOIN    
componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN    
componentinformation ON autodata.comp = componentinformation.InterfaceID AND    
componentoperationpricing.componentid = componentinformation.componentid    
inner join machineinformation on machineinformation.interfaceid=autodata.mc    
and componentoperationpricing.machineid=machineinformation.machineid    
inner join #CockpitData on componentoperationpricing.machineid=#CockpitData.MachineID --autodata.mc=#CockpitData.MachineInterface    
where (autodata.ndtime>#CockpitData.Strttm)    
and (autodata.ndtime<=#CockpitData.ndtim)    
and (autodata.datatype=1)    
group by autodata.mc,#CockpitData.Strttm    
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm    
    
    
---mod 4    
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'    
BEGIN    
 UPDATE #CockpitData SET CN = isnull(CN,0) - isNull(t2.C1N1,0),Components=isnull(components,0)-isnull(t2.PlanCt,0)    
 From    
 (    
  select T.Dstart as intime,mc,SUM((O.cycletime * ISNULL(A.PartsCount,1))/ISNULL(O.SubOperations,1))  C1N1 ,    
  --CEILING (sum(CAST((A.partscount) AS Float)/ISNULL(O.SubOperations,1))) as PlanCt    
  sum(CAST((A.partscount) AS Float)/ISNULL(O.SubOperations,1)) as PlanCt    
  From #T_autodata A    
  inner join machineinformation M on M.interfaceid=A.mc    
  Inner join componentinformation C ON A.Comp=C.interfaceid    
  Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid    
  and O.MachineId=M.MachineId    
  inner jOIN #PlannedDownTimesEffi T  on T.Minterface=A.mc    
  WHERE A.DataType=1    
  AND(A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)    
  AND(A.ndtime > T.Dstart  AND A.ndtime <=T.Dend)    
  Group by mc,T.Dstart    
 ) as T2    
 inner join #CockpitData  on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm    
END    
    
    
    
---mod 4    
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_
4  
m_PLD')<>'Y')    
BEGIN    
 --downtime type 1,2,3,4    
 UPDATE #CockpitData SET downtime = isnull(downtime,0) + isNull(t2.down,0)    
 from    
 (select     #CockpitData.Strttm as intime, mc,    
 sum(case when ( (autodata.msttime>= #CockpitData.Strttm) and (autodata.ndtime<=#CockpitData.ndtim)) then  (loadunload)    
    when ((autodata.msttime< #CockpitData.Strttm)and (autodata.ndtime> #CockpitData.Strttm)and (autodata.ndtime<=#CockpitData.ndtim)) then DateDiff(second,  #CockpitData.Strttm, ndtime)    
    when ((autodata.msttime>= #CockpitData.Strttm)and (autodata.msttime<#CockpitData.ndtim)and (autodata.ndtime>#CockpitData.ndtim)) then DateDiff(second, mstTime, #CockpitData.ndtim)    
    when ((autodata.msttime< #CockpitData.Strttm)and (autodata.ndtime>#CockpitData.ndtim)) then DateDiff(second,  #CockpitData.Strttm, #CockpitData.ndtim) END ) as  down    
 from #T_autodata autodata inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface    
 where (autodata.datatype=2)    
 AND(( (autodata.msttime>=#CockpitData.Strttm) and (autodata.ndtime<=#CockpitData.ndtim))    
 OR ((autodata.msttime<#CockpitData.Strttm)and (autodata.ndtime>#CockpitData.Strttm)and (autodata.ndtime<=#CockpitData.ndtim))    
 OR ((autodata.msttime>=#CockpitData.Strttm)and (autodata.msttime<#CockpitData.ndtim)and (autodata.ndtime>#CockpitData.ndtim))    
 OR((autodata.msttime<#CockpitData.Strttm)and (autodata.ndtime>#CockpitData.ndtim)))    
 group by autodata.mc,#CockpitData.Strttm    
 ) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm    
    
 --ManagementLoss    
 -- Type 1    
 UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)    
 from    
 (select #CockpitData.Strttm as intime,mc,sum(    
 CASE    
 WHEN (loadunload) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0    
 THEN isnull(downcodeinformation.Threshold,0)    
 ELSE loadunload    
 END) AS LOSS    
 from #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid    
 inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface    
 where (autodata.msttime>=#CockpitData.Strttm)    
 and (autodata.ndtime<=#CockpitData.ndtim)    
 and (autodata.datatype=2)    
 and (downcodeinformation.availeffy = 1)    
 group by autodata.mc,#CockpitData.Strttm    
 ) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm    
        
 -- Type 2    
 UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)    
 from    
 (select    #CockpitData.Strttm as intime, mc,sum(    
 CASE WHEN DateDiff(second, #CockpitData.Strttm, ndtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0    
 then isnull(downcodeinformation.Threshold,0)    
 ELSE DateDiff(second, #CockpitData.Strttm, ndtime)    
 END)loss    
 --DateDiff(second, @CurStarttime, ndtime)    
 from #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid    
 inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface    
 where (autodata.sttime<#CockpitData.Strttm)    
 and (autodata.ndtime>#CockpitData.Strttm)    
 and (autodata.ndtime<=#CockpitData.ndtim)    
 and (autodata.datatype=2)    
 and (downcodeinformation.availeffy = 1)    
 group by autodata.mc,#CockpitData.Strttm    
 ) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm    
        
 -- Type 3    
 UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)    
 from    
 (select   #CockpitData.Strttm as intime, mc,SUM(    
 CASE WHEN DateDiff(second,stTime, #CockpitData.ndtim) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0    
 then isnull(downcodeinformation.Threshold,0)  
 ELSE DateDiff(second, stTime, #CockpitData.ndtim)    
 END)loss    
 from #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid    
 inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface    
 where (autodata.msttime>=#CockpitData.Strttm)    
 and (autodata.sttime<#CockpitData.ndtim)    
 and (autodata.ndtime>#CockpitData.ndtim)    
 and (autodata.datatype=2)    
 and (downcodeinformation.availeffy = 1)    
 group by autodata.mc,#CockpitData.Strttm    
 ) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm    
    
 -- Type 4    
 UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)    
 from    
 (select #CockpitData.Strttm as intime, mc,sum(    
 CASE WHEN DateDiff(second, #CockpitData.Strttm, #CockpitData.ndtim) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0    
 then isnull(downcodeinformation.Threshold,0)    
 ELSE DateDiff(second, #CockpitData.Strttm, #CockpitData.ndtim)    
 END)loss    
 from #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid    
 inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface    
 where autodata.msttime<#CockpitData.Strttm    
 and autodata.ndtime>#CockpitData.ndtim    
 and (autodata.datatype=2)    
 and (downcodeinformation.availeffy = 1)    
 group by autodata.mc,#CockpitData.Strttm    
 ) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm    
    
 IF (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y'    
 BEGIN    
     
 ---get PDT downs overlapping with the down records.    
  UPDATE #CockpitData SET downtime = isnull(downtime,0) - isNull(t2.PldDown,0)    
  from(    
  select T.Dstart  as intime,autodata.mc as mc,SUM    
         (CASE    
   WHEN (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN autodata.loadunload    
   WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)    
   WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )    
   WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )    
   END ) as PldDown    
  FROM #T_autodata AutoData inner jOIN #PlannedDownTimesEffi T  on T.Minterface=autodata.mc    
  INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID    
  WHERE autodata.DataType=2    and  (    
   (autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)    
   OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )    
   OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )    
   OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )       
   AND DownCodeInformation.DownID=(SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')    
  group by autodata.mc,T.Dstart ) as t2 inner join #CockpitData    
  on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm    
 END    
     
END    
    
    
    
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'    
BEGIN    
 ---Get the down times which are not of type Management Loss    
 UPDATE #CockpitData SET downtime = isnull(downtime,0) + isNull(t2.down,0)    
 from    
 (select     #CockpitData.Strttm as intime, mc,    
 sum(case when ( (autodata.msttime>= #CockpitData.Strttm) and (autodata.ndtime<=#CockpitData.ndtim)) then  (loadunload)    
    when ((autodata.msttime< #CockpitData.Strttm)and (autodata.ndtime> #CockpitData.Strttm)and (autodata.ndtime<=#CockpitData.ndtim)) then DateDiff(second,  #CockpitData.Strttm, ndtime)    
    when ((autodata.msttime>= #CockpitData.Strttm)and (autodata.msttime<#CockpitData.ndtim)and (autodata.ndtime>#CockpitData.ndtim)) then DateDiff(second, mstTime, #CockpitData.ndtim)    
    when ((autodata.msttime< #CockpitData.Strttm)and (autodata.ndtime>#CockpitData.ndtim)) then DateDiff(second,  #CockpitData.Strttm, #CockpitData.ndtim) END ) as  down    
 from #T_autodata autodata inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface    
 inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid    
 where (autodata.datatype=2)    
 AND(( (autodata.msttime>=#CockpitData.Strttm) and (autodata.ndtime<=#CockpitData.ndtim))    
 OR ((autodata.msttime<#CockpitData.Strttm)and (autodata.ndtime>#CockpitData.Strttm)and (autodata.ndtime<=#CockpitData.ndtim))    
 OR ((autodata.msttime>=#CockpitData.Strttm)and (autodata.msttime<#CockpitData.ndtim)and (autodata.ndtime>#CockpitData.ndtim))    
 OR((autodata.msttime<#CockpitData.Strttm)and (autodata.ndtime>#CockpitData.ndtim))) AND (downcodeinformation.availeffy = 0)    
 group by autodata.mc,#CockpitData.Strttm    
 ) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm    
     
 ---get PDT downs overlapping with the down records.    
 UPDATE #CockpitData SET downtime = isnull(downtime,0) - isNull(t2.PldDown,0)    
 from(    
  select T.Dstart  as intime,autodata.mc as mc,SUM    
         (CASE    
   WHEN (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN autodata.loadunload    
   WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)    
   WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )    
   WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )    
   END ) as PldDown    
  FROM #T_autodata AutoData inner jOIN #PlannedDownTimesEffi T  on T.Minterface=autodata.mc    
  INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID    
  WHERE autodata.DataType=2    and  (    
   (autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)    
   OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )    
   OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )    
   OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )       
   AND (downcodeinformation.availeffy = 0)    
  group by autodata.mc,T.Dstart ) as t2 inner join #CockpitData    
  on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm    
    
    
 UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0)+ isNull(t4.Mloss,0),MLDown=isNull(MLDown,0)+isNull(t4.Dloss,0)    
 from    
 (select T3.mc,T3.Instart,sum(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss from    
  (    
 select   t1.id,T1.mc,T1.Threshold,T1.InStart as Instart,    
 case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0) > 0    
 then DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)- isnull(T1.Threshold ,0)    
 else 0 End  as Dloss,    
 case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0) > 0    
 then isnull(T1.Threshold,0)    
 else DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0) End  as Mloss    
  from    
     
 (   select id,mc,comp,opn,opr,D.threshold,#CockpitData.Strttm as InStart,    
  case when autodata.sttime<#CockpitData.Strttm then #CockpitData.Strttm else sttime END as sttime,    
         case when ndtime>#CockpitData.ndtim then #CockpitData.ndtim else ndtime END as ndtime    
  from #T_autodata autodata inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface    
 inner join  downcodeinformation D on autodata.dcode=D.interfaceid    
 where (autodata.datatype=2)    
 AND(( (autodata.msttime>=#CockpitData.Strttm) and (autodata.ndtime<=#CockpitData.ndtim))    
 OR ((autodata.msttime<#CockpitData.Strttm)and (autodata.ndtime>#CockpitData.Strttm)and (autodata.ndtime<=#CockpitData.ndtim))    
 OR ((autodata.msttime>=#CockpitData.Strttm)and (autodata.msttime<#CockpitData.ndtim)and (autodata.ndtime>#CockpitData.ndtim))    
 OR((autodata.msttime<#CockpitData.Strttm)and (autodata.ndtime>#CockpitData.ndtim)))  AND (D.availeffy = 1)) as T1      
 left outer join    
 (SELECT T.Dstart  as intime , autodata.id,    
         sum(CASE    
   WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)    
   WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)    
   WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )    
   WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )    
   END ) as PPDT    
  FROM #T_autodata AutoData inner jOIN #PlannedDownTimesEffi T  on T.MInterface=autodata.mc    
  inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid    
  WHERE autodata.DataType=2 and    
   (    
   (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)    
   OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )    
   OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )    
   OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)    
   )    
    AND (downcodeinformation.availeffy = 1) group by autodata.id,T.Dstart ) as T2 on T1.id=T2.id  and T2.Intime=T1.InStart ) as T3  group by T3.mc,T3.Instart    
 ) as t4 inner join  #CockpitData    
  on t4.mc = #CockpitData.machineinterface and t4.Instart=#CockpitData.Strttm    
    
 UPDATE #CockpitData  set downtime = isnull(downtime,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)    
END    
    
    
    
    
UPDATE #CockpitData SET turnover = isnull(turnover,0) + isNull(t2.revenue,0)    
from    
(select mc,    
SUM((componentoperationpricing.price/ISNULL(ComponentOperationPricing.SubOperations,1))* ISNULL(autodata.partscount,1)) revenue    
FROM #T_autodata autodata    
INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID    
INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID AND componentoperationpricing.componentid = componentinformation.componentid    
---mod 2    
inner join machineinformation on componentoperationpricing.machineid=machineinformation.machineid    
inner join #CockpitData on #CockpitData.machineid=machineinformation.machineid    
--mod 2 :- ER0181 By Kusuma M.H on 15-Sep-2009.    
AND autodata.mc = machineinformation.interfaceid    
where (    
(autodata.sttime>=#CockpitData.Strttm and autodata.ndtime<=#CockpitData.ndtim)OR    
(autodata.sttime<#CockpitData.Strttm and autodata.ndtime>#CockpitData.Strttm and autodata.ndtime<=#CockpitData.ndtim))and (autodata.datatype=1)    
group by autodata.mc    
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface    
    
    
CREATE TABLE #ShiftDefn    
(    
 ShiftDate datetime,      
 Shiftname nvarchar(20),    
 ShftSTtime datetime,    
 ShftEndTime datetime     
)    
    
declare @startdate as datetime    
declare @enddate as datetime    
declare @startdatetime nvarchar(20)    
    
select @startdate = [dbo].[f_GetLogicalMonth](dateadd(month,-1,@StartTime),'start')    
select @enddate = dbo.f_GetLogicalDayend(@StartTime)    
    
    
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
    
    
create table #shift    
(    
     
 ShiftDate nvarchar(10), --DR0333    
 shiftname nvarchar(20),    
 Shiftstart datetime,    
 Shiftend datetime,    
 shiftid int    
)    
    
Insert into #shift (ShiftDate,shiftname,Shiftstart,Shiftend)    
select convert(nvarchar(10),ShiftDate,126),shiftname,ShftSTtime,ShftEndTime from #ShiftDefn     
    
Update #shift Set shiftid = isnull(#shift.Shiftid,0) + isnull(T1.shiftid,0) from    
(Select SD.shiftid ,SD.shiftname from shiftdetails SD    
inner join #shift S on SD.shiftname=S.shiftname where    
running=1 )T1 inner join #shift on  T1.shiftname=#shift.shiftname    
    
Update #CockPitData Set shiftid = isnull(#CockPitData.Shiftid,0) + isnull(T1.shiftid,0) from    
(Select SD.shiftid ,SD.shiftname from shiftdetails SD    
inner join #CockPitData S on SD.shiftname=S.shftnm where    
running=1 )T1 inner join #CockPitData on  T1.shiftname=#CockPitData.shftnm    
    
    
    
    
    
    
Update #Cockpitdata set RejCount = isnull(RejCount,0) + isnull(T1.RejQty,0)    
From    
(     
Select A.mc,sum(A.Rejection_Qty) as RejQty,M.Machineid,DATEPART(month,C.Pdt) as mm,DATEPART(year,C.Pdt) as yy from AutodataRejections A    
inner join Machineinformation M on A.mc=M.interfaceid    
inner join #Cockpitdata C on C.machineid=M.machineid and DATEPART(month,A.RejDate) = DATEPART(month,C.Pdt)    
 and DATEPART(year,A.RejDate) = DATEPART(year,C.Pdt)     
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid    
inner join #ShiftTemp S on DATEPART(month,A.RejDate) = DATEPART(month,S.PDate) and     
DATEPART(year,A.RejDate) = DATEPART(year,S.PDate)     
where A.flag = 'Rejection' and  DATEPART(month,A.RejDate) = DATEPART(month,S.PDate) and     
DATEPART(year,A.RejDate) = DATEPART(year,S.PDate)     
and  Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'    
group by A.mc,M.Machineid,DATEPART(month,C.Pdt) ,DATEPART(year,C.Pdt)    
)T1 inner join #Cockpitdata B on B.Machineid=T1.Machineid  and DATEPART(month,b.Pdt) =T1.mm and DATEPART(year,b.Pdt) =T1.yy     
    
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'    
BEGIN    
 Update #Cockpitdata set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from    
 ( Select A.mc,sum(A.Rejection_Qty) as RejQty,M.Machineid,DATEPART(month,C.Pdt) as mm,DATEPART(year,C.Pdt) as yy from AutodataRejections A    
 inner join Machineinformation M on A.mc=M.interfaceid    
 inner join #Cockpitdata C on C.machineid=M.machineid and DATEPART(month,A.RejDate) = DATEPART(month,C.Pdt)    
 and DATEPART(year,A.RejDate) = DATEPART(year,C.Pdt)     
 inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid    
 inner join #ShiftTemp S on DATEPART(month,A.RejDate) = DATEPART(month,S.PDate) and     
 DATEPART(year,A.RejDate) = DATEPART(year,S.PDate)     
 Cross join Planneddowntimes P    
 where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid and    
 Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'    
 and P.starttime>=S.FromTime and P.Endtime<=S.ToTime    
 group by A.mc,M.Machineid,DATEPART(month,C.Pdt) ,DATEPART(year,C.Pdt))    
 T1 inner join #Cockpitdata B on B.Machineid=T1.Machineid and DATEPART(month,b.Pdt) =T1.mm and DATEPART(year,b.Pdt) =T1.yy     
    
END    
    
    
    
--UPDATE #Cockpitdata SET QualityEfficiency= ISNULL(QualityEfficiency,0) + IsNull(T1.QE,0)     
--FROM(Select MachineID,    
--CAST((Sum(Components))As Float)/CAST((Sum(IsNull(Components,0))+Sum(IsNull(RejCount,0))) AS Float)As QE,Strttm    
--From #Cockpitdata Where Components<>0 Group By MachineID,Strttm    
--)AS T1 Inner Join #Cockpitdata ON  #Cockpitdata.MachineID=T1.MachineID and #Cockpitdata.Strttm=T1.Strttm    

UPDATE #Cockpitdata SET QualityEfficiency= ISNULL(QualityEfficiency,0) + IsNull(T1.QE,0)     
FROM(Select MachineID,    
cast((Sum(isnull(Components,0))-Sum(IsNull(RejCount,0))) as float)/CAST((Sum(IsNull(Components,0))) AS Float)As QE,Strttm    
From #Cockpitdata Where Components<>0 Group By MachineID,Strttm    
)AS T1 Inner Join #Cockpitdata ON  #Cockpitdata.MachineID=T1.MachineID and #Cockpitdata.Strttm=T1.Strttm   


       
UPDATE #CockpitData    
  SET    
   ProductionEfficiency = (CN/UtilisedTime) ,    
   AvailabilityEfficiency = (UtilisedTime)/(UtilisedTime + DownTime - ManagementLoss),    
   TotalTime = DateDiff(second, Strttm, ndtim) WHERE UtilisedTime <> 0    
    
update #cockpitdata set AvgProductionEfficiency=isnull(t2.APE,0),AvgAvailabilityEfficiency = isnull(t2.aae,0),AvgOverallEfficiency=isnull(t2.OEE,0),totalComp=isnull(t2.totalComp,0) from     
 (select Strttm,avg(ProductionEfficiency)*100 as APE,avg(AvailabilityEfficiency)*100 as AAE,(avg(ProductionEfficiency * AvailabilityEfficiency)*100) As OEE,sum(components) as TotalComp  from #CockpitData     
 where UtilisedTime > 0 OR downtime > 0 --DR0360 added    
group by Strttm)t2 inner join #CockpitData on t2.Strttm = #CockpitData.Strttm    
    
UPDATE #CockpitData    
SET    
 OverAllEfficiency = (ProductionEfficiency * AvailabilityEfficiency * QualityEfficiency)*100,     
 ProductionEfficiency = ProductionEfficiency * 100 ,    
 AvailabilityEfficiency = AvailabilityEfficiency * 100,    
 QualityEfficiency = QualityEfficiency*100    
    
If (SELECT ValueInText From CockpitDefaults Where Parameter ='DisplayTTFormat')='Display TotalTime - Less PDT'     
BEGIN    
    
 UPDATE #CockpitData SET TotalTime = Totaltime - isnull(T1.PDT,0)     
 from    
 (Select P.Machine,C.Strttm,SUM(datediff(second,P.Starttime,P.endtime))as PDT from Planneddowntimes P    
  --inner join #CockpitData C on #CockpitData.machineid=P.machine    
 inner join #CockpitData C on C.machineid=P.machine    
  where P.starttime>=C.Strttm and P.endtime<=C.ndtim and  UtilisedTime <> 0   group by P.Machine,C.Strttm)T1    
  Inner Join #CockpitData on T1.Machine=#CockpitData.Machineid and T1.Strttm =#CockpitData.Strttm     
    
End 


    
update #CockPitData set MachineHourRate=    
 mchrrate  from machineinformation inner join #CockpitData on machineinformation.MachineID = #CockpitData.MachineID    
    
update #cockpitdata  set TargetOEE =isnull(t.OE,0) from        
(select machineid,OE,startdate,enddate from efficiencytarget)t     
inner join #CockpitData on t.MachineID = #CockpitData.MachineID and t.startdate<=#cockpitdata.Pdt and t.enddate>=#cockpitdata.Pdt     
    
update  #CockPitData set TotaldowntimeInt=DownTime     
    
----------- DR0379 From Here   
--SELECT T1.MachineID,T1.Components,T1.RejCount,T1.ProductionEfficiency,T1.AvailabilityEfficiency,T1.QualityEfficiency,T1.OverAllEfficiency,    
--T1.AvgOverallEfficiency,[dbo].[f_FormatTime] (T1.Totaltime,'hh:mm:ss') as Totaltime,[dbo].[f_FormatTime] (T1.downtime,'hh:mm:ss') as downtime,[dbo].[f_FormatTime] (T1.UtilisedTime,'hh:mm:ss') as UtilisedTime,    
--T2.MachineID,T2.Components,T2.RejCount,T2.ProductionEfficiency,T2.AvailabilityEfficiency,T2.QualityEfficiency,T2.OverAllEfficiency,    
--T2.AvgOverallEfficiency,[dbo].[f_FormatTime] (T2.Totaltime,'hh:mm:ss') as Totaltime,[dbo].[f_FormatTime] (T2.downtime,'hh:mm:ss') as downtime,[dbo].[f_FormatTime] (T2.UtilisedTime,'hh:mm:ss') as UtilisedTime    
--FROM (Select * from #CockpitData where datepart(month,Strttm)=datepart(month,@starttime)) T1 join     
--(Select * from #CockpitData where datepart(month,Strttm)=datepart(month,dateadd(month,-1,@starttime))) T2 on T1.machineid=T2.machineid     
--Order by T1.Machineid,T1.Strttm    
   
  
SELECT T1.MachineID,T1.GroupID,round(isnull(T1.Components,0),2) as Components,round(isnull(T1.RejCount,0),2) as RejCount,round(isnull(T1.ProductionEfficiency,0),2) as ProductionEfficiency,
round(isnull(T1.AvailabilityEfficiency,0),2) as AvailabilityEfficiency,round(isnull(T1.QualityEfficiency,0),2) as QualityEfficiency,round(isnull(T1.OverAllEfficiency,0),2) as OverAllEfficiency,    
round(isnull(T1.AvgOverallEfficiency,0),2) as AvgOverallEfficiency,[dbo].[f_FormatTime] (T1.Totaltime,'hh:mm:ss') as Totaltime,[dbo].[f_FormatTime] (T1.downtime,'hh:mm:ss') as downtime,[dbo].[f_FormatTime] (T1.UtilisedTime,'hh:mm:ss') as UtilisedTime,    
T2.MachineID as MachineID1,round(isnull(T2.Components,0),2) as Components1,round(isnull(T2.RejCount,0),2) as RejCount1,round(isnull(T2.ProductionEfficiency,0),2) as PE,round(isnull(T2.AvailabilityEfficiency,0),2) as AE,round(isnull(T2.QualityEfficiency,0),2) as QE,round(isnull(T2.OverAllEfficiency,0),2) as OE,    
round(isnull(T2.AvgOverallEfficiency,0),2) as AvgOE,[dbo].[f_FormatTime] (T2.Totaltime,'hh:mm:ss') as Totaltime1,[dbo].[f_FormatTime] (T2.downtime,'hh:mm:ss') as downtime1,[dbo].[f_FormatTime] (T2.UtilisedTime,'hh:mm:ss') as UtilisedTime1    
FROM (Select * from #CockpitData where datepart(month,Strttm)=datepart(month,@starttime)) T1 join     
(Select * from #CockpitData where datepart(month,Strttm)=datepart(month,dateadd(month,-1,@starttime))) T2 on T1.machineid=T2.machineid     
Order by T1.Machineid,T1.Strttm    
----------- DR0379 Till Here  
   
    
END    
    
