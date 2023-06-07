/****** Object:  Procedure [dbo].[s_GetCurrentCycleICDRecords_eshopx]    Committed by VersionSQL https://www.versionsql.com ******/

        
--ER0370 - SwathiKS - 20/Nov/2013 :: Created New Procedure, Look at the last record in Autodata_Maxtime for the given machine.         
--If there are ICD records in autodata_ICD table with Start time > End time of Last record in autodata_Maxtime, then show those records.        
--ER0450 - SwathiKS - 04/Jul/2017 :: To introduce Mode (Robo/Manual) in VDG for kennametal.(.net cockpit)          
        
--[dbo].[s_GetCurrentCycleICDRecords] '2017-09-01 06:00:00 AM','2017-09-02 06:00:00 AM','58002_STUDER'        
        
CREATE       PROCEDURE [dbo].[s_GetCurrentCycleICDRecords_eshopx]        
 @StartTime datetime,        
 @EndTime datetime,        
 @MachineID nvarchar(50)       
      
WITH RECOMPILE      
       
AS        
BEGIN        
       
      
       
create table #TempCockpitDownData1        
(        
 StartTime datetime,        
 EndTime datetime,        
 OperatorID nvarchar(50),        
 OperatorName nvarchar(150),        
 DownID nvarchar(50),        
 DownDescription nvarchar(100),        
 DownThreshold numeric(18) ,        
 DownTime nvarchar(50) ,        
 Remarks nvarchar(255),        
 [id] bigint,        
 PDT int,        
 Mode int,
 WorkOrderNumber nvarchar(50)--ER0450        
)        
        
create table #autodata_ICD        
(        
 sttime datetime,        
 ndtime datetime,        
 mc nvarchar(50),        
 dcode nvarchar(50),        
 opr nvarchar(50),        
 Loadunload int,        
 [id] bigint        
)        
        
Declare @mc as nvarchar(50)        
Declare @curtime as datetime        
Select @mc=interfaceid from machineinformation where machineid=@machineid        
Select @curtime=getdate()        
        
Insert into #autodata_ICD        
select sttime,ndtime,mc,dcode,opr,loadunload,id from Autodata_ICD        
where sttime>=(Select MAX(endtime) from Autodata_Maxtime where machineid=@mc) and ndtime<=@Curtime        
and mc=@mc        
        
        
SELECT        
case when A.sttime<@starttime then @starttime else A.sttime end AS StartTime,        
case when A.ndtime>@endtime then @endtime else A.ndtime end AS EndTime,        
employeeinformation.Employeeid AS OperatorID,        
employeeinformation.[Name]  AS OperatorName,        
downcodeinformation.downid AS DownID,        
downcodeinformation.downdescription as [DownDescription],        
CASE        
WHEN downcodeinformation.AvailEffy=1 and downcodeinformation.Threshold>0 THEN downcodeinformation.Threshold        
ELSE 0 END AS [DownThreshold],        
case        
When (A.sttime >= @StartTime AND A.ndtime <= @EndTime ) THEN A.loadunload        
WHEN ( A.sttime < @StartTime AND A.ndtime <= @EndTime AND A.ndtime > @StartTime ) THEN DateDiff(second, @StartTime, A.ndtime)        
WHEN ( A.sttime >= @StartTime AND A.sttime < @EndTime AND A.ndtime > @EndTime ) THEN  DateDiff(second, A.stTime, @EndTime)        
ELSE        
DateDiff(second, @StartTime, @EndTime)END AS DownTime,        
'Current Cycle ICD Record' as Remarks,        
A.id,        
0 as PDT,        
0 as Mode,
0 as WorkOrderNumber--ER0450         
INTO #Temp        
FROM  #autodata_ICD A         
INNER JOIN machineinformation ON A.mc = machineinformation.InterfaceID         
INNER JOIN downcodeinformation ON A.dcode = downcodeinformation.interfaceid         
INNER JOIN employeeinformation ON A.opr = employeeinformation.interfaceid        
WHERE machineinformation.machineid = @MachineID AND         
(        
(A.sttime >= @StartTime  AND A.ndtime <=@EndTime)        
OR ( A.sttime < @StartTime  AND A.ndtime <= @EndTime AND A.ndtime > @StartTime )        
OR ( A.sttime >= @StartTime   AND A.sttime <@EndTime AND A.ndtime > @EndTime )        
OR ( A.sttime < @StartTime  AND A.ndtime > @EndTime)        
)        
ORDER BY A.ndtime        
        
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'        
BEGIN        
update #Temp set DownTime = isnull(Downtime,0)-isnull(TT.plannedDT,0), PDT=isnull(TT.plannedDT,0)        
 from        
(        
 Select A.StartTime,A.EndTime,           
   sum(case        
   WHEN A.StartTime >= T.StartTime  AND A.EndTime <=T.EndTime  THEN A.DownTime        
   WHEN ( A.StartTime < T.StartTime  AND A.EndTime <= T.EndTime  AND A.EndTime > T.StartTime ) THEN DateDiff(second,T.StartTime,A.EndTime)        
   WHEN ( A.StartTime >= T.StartTime   AND A.StartTime <T.EndTime  AND A.EndTime > T.EndTime  ) THEN DateDiff(second,A.StartTime,T.EndTime )        
   WHEN ( A.StartTime < T.StartTime  AND A.EndTime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )        
   END) as plannedDT        
 From #Temp A CROSS jOIN PlannedDownTimes T        
   WHERE  T.machine=@machineid  and pdtstatus=1 and         
   ((A.StartTime >= T.StartTime  AND A.EndTime <=T.EndTime)        
   OR ( A.StartTime < T.StartTime  AND A.EndTime <= T.EndTime AND A.EndTime > T.StartTime )        
   OR ( A.StartTime >= T.StartTime   AND A.StartTime <T.EndTime AND A.EndTime > T.EndTime )        
   OR ( A.StartTime < T.StartTime  AND A.EndTime > T.EndTime))        
   group by A.StartTime,A.EndTime        
)TT        
INNER JOIN #Temp ON TT.StartTime=#Temp.StartTime and #Temp.EndTime=TT.EndTime        
END        
        
        
insert into #TempCockpitDownData1        
(        
 StartTime,        
 EndTime,        
 OperatorID,        
 OperatorName,        
 DownID,        
 DownDescription,        
 DownThreshold,        
 DownTime,        
 Remarks,        
 [id],        
 PDT,        
 Mode,
 WorkOrderNumber--ER0450        
) Select * from #temp order by starttime,endtime        
        
--ER0450        
IF EXISTS(SELECT * FROM Company where CompanyName Like 'kennametal%')        
Begin        
 SELECT * From #TempCockpitDownData1         
End        
Else        
Begin        
 SELECT StartTime,EndTime,OperatorID,OperatorName,DownID,DownDescription,DownThreshold,DownTime,Remarks,[id],PDT,WorkOrderNumber From #TempCockpitDownData1         
End        
--ER0450        
drop table #TempCockpitDownData1        
        
END        
