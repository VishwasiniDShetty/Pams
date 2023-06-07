/****** Object:  Procedure [dbo].[s_GetCockpitProductionDataLNT]    Committed by VersionSQL https://www.versionsql.com ******/

/*  
exec [s_GetCockpitProductionDataLNT] '2017-12-01 06:00:00.000','2018-01-01 14:00:00.000','MC-J180-P0214', '93 base'  

select distinct ci.componentid, ci.interfaceid -- A.sttime, A.ndtime, A.datatype, A.cycletime
from AutoData A 
inner join componentinformation ci on A.comp=ci.interfaceid 
inner join machineinformation mi on A.mc=mi.interfaceid 
inner join componentoperationpricing cop ON A.opn=cop.InterfaceID AND ci.componentid=cop.componentid and cop.machineid=mi.machineid 
where A.sttime >= '2017-12-11' and A.sttime <= '2018-01-01' and mi.machineid = 'MC-J180-P0214' 
*/  
CREATE PROCEDURE [dbo].[s_GetCockpitProductionDataLNT]  
 @StartTime datetime,  
 @EndTime datetime,  
 @MachineID nvarchar(50),  
 @ComponentID nvarchar(50)
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
  
SELECT  
IDENTITY(int, 1, 1) AS SerialNo,  
componentinformation.componentid AS ComponentID,  
componentinformation.description AS description,  
componentoperationpricing.operationno AS OperationNo,  
Isnull(employeeinformation.Employeeid,autodata.opr) AS OperatorID,  
Isnull(employeeinformation.[name],'---') AS OperatorName,  
autodata.sttime AS StartTime,  
autodata.ndtime AS EndTime,  
autodata.cycletime AS CycleTime,  
autodata.mc as MachineInterface,  
autodata.comp as CompInterface,  
autodata.opn as OpnInterface,  
0 As PDT,  
ISNULL(autodata.loadunload,0) AS LoadUnloadTime,  
autodata.Remarks,  
ISNULL(componentoperationpricing.cycletime,0)StdCycleTime,  
ISNULL(componentoperationpricing.machiningtime,0)StdMachiningTime,  
autodata.id,  
CASE  
WHEN   DATEDIFF(SECOND,autodata.sttime,autodata.ndtime)>autodata.cycletime  
THEN DATEDIFF(SECOND,autodata.sttime,autodata.ndtime)-autodata.cycletime  
ELSE  0  
END  AS  In_Cycle_DownTime  
INTO #TempCockpitProductionData  
FROM         autodata INNER JOIN  
machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN  
componentinformation ON autodata.comp = componentinformation.InterfaceID INNER JOIN  
componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID  
AND componentinformation.componentid =  componentoperationpricing.componentid  
and componentoperationpricing.machineid=machineinformation.machineid  
LEFT OUTER JOIN employeeinformation ON autodata.opr = employeeinformation.interfaceid  
WHERE  
(autodata.ndtime > @StartTime )  
AND  
(autodata.ndtime <= @EndTime )  
AND  
(machineinformation.machineid = N'' + @MachineID + '')  
AND  
(componentinformation.componentid = N'' + @ComponentID + '')  
AND  
(autodata.datatype = 1)  
ORDER BY autodata.sttime  
  
create table #PlannedDownTimes (  Machine nvarchar(50) NOT NULL,   MachineInterface nvarchar(50) NOT NULL,  StartTime DateTime NOT NULL,  EndTime DateTime NOT NULL,  PDTStatus int )  
ALTER TABLE #PlannedDownTimes  ADD PRIMARY KEY CLUSTERED   (   [MachineInterface],    [StartTime],    [EndTime]         ) ON [PRIMARY]  

declare @strsql as nvarchar(4000) 
SET @strSql = '' 
SET @strSql = 'Insert into #PlannedDownTimes  SELECT Machine,InterfaceID,   CASE When StartTime<''' + convert(nvarchar(20),@StartTime,120)+''' Then ''' + convert(nvarchar(20),@StartTime,120)+''' Else StartTime End As StartTime,   CASE When EndTime>''' + convert(nvarchar(20),@EndTime,120)+''' Then ''' + convert(nvarchar(20),@EndTime,120)+''' Else EndTime End As EndTime  ,pdtstatus FROM 
PlannedDownTimes inner join MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID  WHERE PDTstatus =1 and(  (StartTime >= ''' + convert(nvarchar(20),@StartTime,120)+''' AND EndTime <=''' + convert(nvarchar(20),@EndTime,120)+''')  OR 
( StartTime < ''' + convert(nvarchar(20),@StartTime,120)+'''  AND EndTime <= ''' + convert(nvarchar(20),@EndTime,120)+''' AND EndTime > ''' + convert(nvarchar(20),@StartTime,120)+''' )  OR ( StartTime >= ''' + convert(nvarchar(20),@StartTime,120)+'''  
 AND StartTime <''' + convert(nvarchar(20),@EndTime,120)+''' AND EndTime > ''' + convert(nvarchar(20),@EndTime,120)+''' )  OR ( StartTime < ''' + convert(nvarchar(20),@StartTime,120)+'''  AND EndTime > ''' + convert(nvarchar(20),@EndTime,120)+''')) ' 
SET @strSql =  @strSql + ' and MachineInformation.MachineID='''+ @machineid + ''' ORDER BY Machine,StartTime' 
EXEC(@strSql)  

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'  
BEGIN  
  
set ansi_warnings off  
UPDATE #TempCockpitProductionData set  CycleTime=isnull(CycleTime,0) - isNull(TT.PPDT ,0),  
LoadUnloadTime = isnull(LoadUnloadTime,0) - isnull(LD,0),  
PDT=isnull(PDT,0) + isNull(TT.PPDT ,0) + isnull(LD,0)  
 FROM(  
  --Production Time in PDT  
 Select A.mc,A.comp,A.Opn,A.sttime,A.ndtime,A.msttime,Sum  
   (CASE  
   WHEN A.sttime >= T.StartTime  AND A.ndtime <=T.EndTime  THEN (A.cycletime)  
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
   SELECT M.Machineid,  
   autodata.MC,autodata.comp,autodata.Opn,autodata.sttime,autodata.ndtime,autodata.Cycletime,  
   autodata.msttime,autodata.loadunload  
   FROM AutoData inner join Machineinformation M on M.interfaceid=Autodata.mc  
   where autodata.DataType=1 And autodata.sttime >=@StartTime  AND autodata.sttime < @EndTime)A   
   CROSS jOIN #PlannedDownTimes T  
   WHERE T.Machine=A.Machineid AND  
     
   ((A.msttime >= T.StartTime  AND A.ndtime <=T.EndTime)  
   OR ( A.msttime < T.StartTime  AND A.ndtime <= T.EndTime AND A.ndtime > T.StartTime )  
   OR ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime AND A.ndtime > T.EndTime )  
   OR ( A.msttime < T.StartTime  AND A.ndtime > T.EndTime) )  
   and T.PDTStatus = 1    
  group by A.mc,A.comp,A.Opn,A.sttime,A.ndtime,A.msttime  
 )  
 as TT INNER JOIN #TempCockpitProductionData ON TT.mc = #TempCockpitProductionData.MachineInterface  
  and TT.comp = #TempCockpitProductionData.CompInterface  
   and TT.opn = #TempCockpitProductionData.OPNInterface and tt.sttime=#TempCockpitProductionData.StartTime  
and #TempCockpitProductionData.EndTime=TT.ndtime  
  
     
  --Handle intearction between ICD and PDT for type 1 production record for the selected time period.  
  UPDATE  #TempCockpitProductionData set CycleTime =isnull(CycleTime,0) + isNull(T2.IPDT ,0)  FROM   
  (  
  Select T1.mc,T1.comp,T1.opn,T1.sttime,T1.ndtime,T1.cyclestart,T1.Cycleend,SUM(  
   CASE    
    When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1  
    When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2  
    When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3  
    when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4  
   END) as IPDT from  
  (Select A.mc,A.comp,A.opn,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime,A.ndtime, A.datatype,  
   B.Sttime as CycleStart,B.ndtime as CycleEnd from autodata A inner join AutoData B on B.mc = A.mc 
   Where A.DataType=2 and B.DataType=1  
   And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And  
   (B.msttime >= @starttime AND B.ndtime <= @Endtime) and  
   (B.sttime < A.sttime) AND (B.ndtime > A.ndtime)   
   )as T1 inner join  
  (select  machine,Case when starttime<@starttime then @starttime else starttime end as starttime,   
  case when endtime> @Endtime then @Endtime else endtime end as endtime from dbo.PlannedDownTimes   
  where PDTStatus = 1 and ((( StartTime >=@starttime) And ( EndTime <=@Endtime))  
  or (StartTime < @starttime  and  EndTime <= @Endtime AND EndTime > @starttime)  
  or (StartTime >= @starttime  AND StartTime <@Endtime AND EndTime > @Endtime)  
  or (( StartTime <@starttime) And ( EndTime >@Endtime )) )  
  )T  
  on T1.machine=T.machine AND  
  ((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))  
  or (T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)  
  or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )  
  or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )group by T1.mc,T1.comp,T1.opn,T1.sttime,T1.ndtime,T1.cyclestart,T1.Cycleend  
  )AS T2  INNER JOIN #TempCockpitProductionData ON T2.mc = #TempCockpitProductionData.MachineInterface  
    and T2.comp = #TempCockpitProductionData.CompInterface  
   and T2.opn = #TempCockpitProductionData.OPNInterface and t2.cyclestart=#TempCockpitProductionData.StartTime  
  and #TempCockpitProductionData.EndTime=T2.Cycleend  
set ansi_warnings ON  
End  
  


--Declare @ICDSetting as nvarchar(50)  
--Select @ICDSetting = isnull(Valueintext,'N') From CockpitDefaults Where Parameter ='Current_Cycle_ICD_Records'  
--IF @ICDSetting = 'Y'  
--BEGIN  
-- insert into #TempCockpitProductionData exec [dbo].[s_GetInProcessCycles] @starttime,@Endtime,@Machineid  
--END  
--g:  
select A.mc,(select dc.downid from downcodeinformation dc where dc.interfaceid=A.dcode) AS dcode, A.sttime as ICDStart,A.ndtime as ICDEnd,  
cast(datediff(s, A.sttime, A.ndtime) as nvarchar(50)) as downtime, B.StartTime AS sttime, B.EndTime AS ndtime  
INTO #TmpICDTbl  
from autodata A with (nolock) inner join #TempCockpitProductionData B with (nolock) on B.MachineInterface = A.mc  
Where A.DataType=2 And DateDiff(s,B.StartTime,B.EndTime)> B.CycleTime And  
 (B.StartTime >= @starttime AND B.EndTime <= @endtime) and  
 (B.StartTime < A.sttime) AND (B.EndTime > A.ndtime)  AND A.mc=(select interfaceid from machineinformation mi where mi.machineid=@MachineID)  
  

  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'  
BEGIN  
  
set ansi_warnings off  
UPDATE #TmpICDTbl set downtime=isnull(downtime,0) - isNull(TT.PPDT ,0)  
 FROM(  
  --Production Time in PDT  
 Select A.mc,A.ICDStart,A.ICDEnd,Sum  
   (CASE  
   WHEN (A.ICDStart >= T.StartTime  AND A.ICDEnd <=T.EndTime)  THEN DateDiff(second,A.ICDStart,A.ICDEnd)  
   WHEN ( A.ICDStart < T.StartTime  AND A.ICDEnd <= T.EndTime  AND A.ICDEnd > T.StartTime ) THEN DateDiff(second,T.StartTime,A.ICDEnd)  
   WHEN ( A.ICDStart >= T.StartTime   AND A.ICDStart <T.EndTime  AND A.ICDEnd > T.EndTime  ) THEN DateDiff(second,A.ICDStart,T.EndTime )  
   WHEN ( A.ICDStart < T.StartTime  AND A.ICDEnd > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
   END)  as PPDT  
 From #TmpICDTbl A   
   CROSS jOIN #PlannedDownTimes T  
   WHERE T.MachineInterface=A.mc AND     
   ((A.ICDStart >= T.StartTime  AND A.ICDEnd <=T.EndTime)  
   OR ( A.ICDStart < T.StartTime  AND A.ICDEnd <= T.EndTime AND A.ICDEnd > T.StartTime )  
   OR ( A.ICDStart >= T.StartTime   AND A.ICDStart <T.EndTime AND A.ICDEnd > T.EndTime )  
   OR ( A.ICDStart < T.StartTime  AND A.ICDEnd > T.EndTime) )  
   and T.PDTStatus = 1    
  group by A.mc,A.ICDStart,A.ICDEnd  
 )  
 as TT INNER JOIN #TmpICDTbl ON TT.mc = #TmpICDTbl.mc and TT.ICDStart=#TmpICDTbl.ICDStart  
and #TmpICDTbl.ICDEnd=TT.ICDEnd  
set ansi_warnings ON  
  
END  

select mc, dcode, cast(SUM(cast(downtime as int)) as nvarchar(50)) downtime, sttime, ndtime
into #TmpICDTbl2
from #TmpICDTbl
group by mc, dcode, sttime, ndtime
order by downtime --g:

--update #tmpICDTbl set Downtime=Cast(dbo.f_FormatTime(Downtime,'hh:mm:ss') as nvarchar(50))
update #tmpICDTbl2 set Downtime=Cast(dbo.f_FormatTime(Downtime,'hh:mm:ss') as nvarchar(50))


declare @TimeFormat as nvarchar(50)  
SELECT @TimeFormat = 'hh:mm:ss'  
if (ISNULL(@TimeFormat,'')) = ''  
 SELECT @TimeFormat = N'hh:mm:ss'  
  
SELECT @strsql = 'SELECT SerialNo, Componentid AS PartNo, Description AS PartDescription, '  
SELECT @strsql = @strsql +'OperationNo, StartTime, EndTime, '  
if (@TimeFormat = 'hh:mm:ss'or @TimeFormat = 'hh' or @TimeFormat = 'mm' or @TimeFormat = 'ss' )  
BEGIN  
 SELECT @strsql = @strsql  +'dbo.f_FormatTime(pd.CycleTime,''' + @TimeFormat + ''') as CycleTime,'   SELECT @strsql = @strsql  +'dbo.f_FormatTime(In_Cycle_DownTime,''' + @TimeFormat + ''') as In_Cycle_DownTime,'  
 SELECT @strsql = @strsql  +'dbo.f_FormatTime(PDT,''' + @TimeFormat + ''') as PDT,'  
END  

SELECT @strsql =  @strsql  + 'pd.CycleTime AS CycleTimeSeconds,   
dbo.f_FormatTime(pd.stdcycletime, ''hh:mm:ss'') AS StdCycleTime,  
round(100*pd.stdcycletime/convert(float,CASE cycletime WHEN 0 THEN 1 ELSE cycletime END), 2) AS ProdEfficiency,  
isnull(  
CAST(''<root>''+   
stuff(  
(select '', '' + dcode + '' ('' + cast(downtime as nvarchar(50)) + '')'' AS [text()]   
from #tmpICDTbl2 A   
Where A.sttime >= pd.starttime AND A.ndtime <= pd.endtime  
for xml path('''')  
), 1, 2, '''') +''</root>'' AS XML).value(''(root)[1]'', ''varchar(max)'')  
 , '''') AS DownCode FROM #TempCockpitProductionData pd   
order by SerialNo'  
print @strsql  
EXEC (@strsql)  
  
END  
