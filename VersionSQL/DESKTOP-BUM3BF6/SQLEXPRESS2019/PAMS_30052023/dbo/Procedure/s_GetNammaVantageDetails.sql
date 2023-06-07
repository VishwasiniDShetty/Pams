/****** Object:  Procedure [dbo].[s_GetNammaVantageDetails]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE        PROCEDURE [dbo].[s_GetNammaVantageDetails]    
 @StartTime datetime,    
 @EndTime datetime,    
 @shift nvarchar(50)='',    
 @Machineid nvarchar(50)='',    
 @Plantid nvarchar(50)='',    
 @param nvarchar(50)=''     
AS    
BEGIN    
    
Declare @strPlantID as nvarchar(255)    
Declare @strSql as nvarchar(4000)    
Declare @strMachine as nvarchar(255)    
declare @i as nvarchar(10)    
    
select @i = 1    
    
SELECT @strPlantID = ''    
SELECT @strSql = ''    
SELECT @strMachine = ''    
    
CREATE TABLE #CockPitData     
(    
 MachineID nvarchar(50),    
 MachineInterface nvarchar(50) PRIMARY KEY,    
 ProductionEfficiency float,    
 AvailabilityEfficiency float,    
 OverallEfficiency float,    
 CN float,    
 cycletime float,    
 Loadunload float,    
 ManagementLoss float,    
 Stoppage float,    
 MLDown float,    
 PlannedDT float,    
 PEGreen smallint,    
 PERed smallint,    
 AEGreen smallint,    
 AERed smallint,    
 OEGreen smallint,    
 OERed smallint    
)    
    
CREATE TABLE #PLD    
(    
 MachineID nvarchar(50),    
 MachineInterface nvarchar(50),    
 pPlannedDT float Default 0,    
 dPlannedDT float Default 0,    
 IPlannedDT float Default 0,    
 LPlannedDT float Default 0,    
 PlannedDT float Default 0,    
 DownID nvarchar(50)    
)    
    
Create table #PlannedDownTimes    
(    
 MachineID nvarchar(50) NOT NULL,     
 MachineInterface nvarchar(50) NOT NULL,     
 StartTime DateTime NOT NULL,     
 EndTime DateTime NOT NULL    
)    
    
ALTER TABLE #PlannedDownTimes    
ADD PRIMARY KEY CLUSTERED    
 (   [MachineInterface],    
  [StartTime],    
  [EndTime]    
         
 ) ON [PRIMARY]    
    
    
CREATE TABLE #FinalData    
(    
 MachineID NvarChar(50),    
 MachineInterface nvarchar(50),    
 Energy float,    
 Maxenergy float,    
 Minenergy float,    
 AvgEnergy float,    
    EnergyEff float    
)    
    
    
create table #Runningpart_Part    
(      
 Machineid nvarchar(50),      
 Componentid nvarchar(50),    
 Operation nvarchar(50),    
 Mc nvarchar(50),      
 comp nvarchar(50),    
 Opn nvarchar(50),    
 suboperation int,    
 cycletime float,    
 TargetPercent int,    
 ShiftTarget float,    
 ShiftActual float,    
 sttime datetime,    
 shiftdate datetime,    
 shiftstart datetime,    
 shiftend datetime,    
 shiftname nvarchar(50),    
 Noofrecords int,    
 stdthreshold float    
)      
    
Create table #HourlyData    
(    
 HourName nvarchar(10),    
 MachineID nvarchar(50),    
 Mc nvarchar(50),      
 comp nvarchar(50),    
 Opn nvarchar(50),    
 suboperation int,    
 cycletime float,    
 TargetPercent int,    
 FromTime datetime,      
 ToTime Datetime,      
 Actual float,      
 Target float    
)    
    
Create table #HourlyData1    
(    
  HourName nvarchar(10),    
  Machineid nvarchar(50),      
  FromTime datetime,      
  ToTime Datetime,      
  Actual float,      
  Target float    
)    
    
Create Table #ShiftTemp      
 (      
  PDate datetime,      
  ShiftName nvarchar(20),      
  FromTime datetime,      
  ToTime Datetime,      
 )     
    
Create Table #Shiftdetails     
 (      
  PDate datetime,      
  ShiftName nvarchar(20),      
  FromTime datetime,      
  ToTime Datetime,      
 )     
    
    
Create Table #oprdetails     
 (      
  PDate datetime,      
  ShiftName nvarchar(20),      
  FromTime datetime,      
  ToTime Datetime,      
  Operator nvarchar(Max)    
 )     
    
declare @currtime as datetime    
select @currtime=getdate()    
    
if isnull(@machineid,'')<> ''    
begin    
 SET @strMachine = ' AND MachineInformation.MachineID = N''' + @machineid + ''''    
end    
    
if isnull(@PlantID,'')<> ''    
Begin    
 SET @strPlantID = ' AND PlantMachine.PlantID = N''' + @PlantID + ''''    
End    
    
If @param = 'Donutchart' or @param='Efficiency'    
Begin    
    SET @strSql = 'INSERT INTO #CockpitData (    
     MachineID ,    
     MachineInterface,    
     ProductionEfficiency ,    
     AvailabilityEfficiency,    
     OverallEfficiency,    
     CN ,    
cycletime ,     
     Loadunload,    
     ManagementLoss,    
     Stoppage ,    
     MLDown,    
     PlannedDT,    
     PEGreen,    
     PERed,    
     AEGreen,    
     AERed,    
     OEGreen,    
     OERed    
     ) '    
    SET @strSql = @strSql + ' SELECT MachineInformation.MachineID, MachineInformation.interfaceid ,0,0,0,0,0,0,0,0,0,0,PEGreen ,PERed,AEGreen ,AERed ,OEGreen ,OERed FROM MachineInformation     
         LEFT OUTER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID WHERE MachineInformation.TPMTrakEnabled = 1 and MachineInformation.interfaceid > ''0'' '    
    SET @strSql =  @strSql + @strMachine + @strPlantID     
    EXEC(@strSql)    
    
    --mod 4 Get the Machines into #PLD    
    SET @strSql = ''    
    SET @strSql = 'INSERT INTO #PLD(MachineID,MachineInterface,pPlannedDT,dPlannedDT)    
     SELECT MachineID ,Interfaceid,0  ,0 FROM MachineInformation WHERE MachineInformation.TPMTrakEnabled = 1 and MachineInformation.interfaceid > ''0'' '    
    SET @strSql =  @strSql + @strMachine     
    EXEC(@strSql)    
    
    
    /* Planned Down times for the given time period */    
    SET @strSql = ''    
    SET @strSql = 'Insert into #PlannedDownTimes    
     SELECT Machine,InterfaceID,    
      CASE When StartTime<''' + convert(nvarchar(20),@StartTime,120)+''' Then ''' + convert(nvarchar(20),@StartTime,120)+''' Else StartTime End As StartTime,    
      CASE When EndTime>''' + convert(nvarchar(20),@EndTime,120)+''' Then ''' + convert(nvarchar(20),@EndTime,120)+''' Else EndTime End As EndTime    
     FROM PlannedDownTimes inner join MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID    
     WHERE MachineInformation.TPMTrakEnabled = 1 and PDTstatus =1 and(    
     (StartTime >= ''' + convert(nvarchar(20),@StartTime,120)+''' AND EndTime <=''' + convert(nvarchar(20),@EndTime,120)+''')    
     OR ( StartTime < ''' + convert(nvarchar(20),@StartTime,120)+'''  AND EndTime <= ''' + convert(nvarchar(20),@EndTime,120)+''' AND EndTime > ''' + convert(nvarchar(20),@StartTime,120)+''' )    
     OR ( StartTime >= ''' + convert(nvarchar(20),@StartTime,120)+'''   AND StartTime <''' + convert(nvarchar(20),@EndTime,120)+''' AND EndTime > ''' + convert(nvarchar(20),@EndTime,120)+''' )    
     OR ( StartTime < ''' + convert(nvarchar(20),@StartTime,120)+'''  AND EndTime > ''' + convert(nvarchar(20),@EndTime,120)+''')) '    
    SET @strSql =  @strSql + @strMachine +  ' ORDER BY Machine,StartTime'    
    EXEC(@strSql)    
    
    -- Get the Cycle time and Loadunload at Machine Level    
    UPDATE #CockpitData SET cycletime = isnull(cycletime,0) + isNull(t2.cycle,0),Loadunload = isnull(Loadunload,0) + isNull(t2.LD,0)    
    from    
    (select A.mc,Sum    
       (CASE    
       WHEN A.sttime >= @StartTime  AND A.ndtime <=@EndTime  THEN (A.cycletime)    
       WHEN ( A.sttime < @StartTime  AND A.ndtime <= @EndTime  AND A.ndtime > @StartTime ) THEN DateDiff(second,@StartTime,A.ndtime)    
       WHEN ( A.sttime >= @StartTime   AND A.sttime <@EndTime  AND A.ndtime > @EndTime  ) THEN DateDiff(second,A.sttime,@EndTime )    
       WHEN ( A.sttime < @StartTime  AND A.ndtime > @EndTime ) THEN DateDiff(second,@StartTime,@EndTime )    
       END)  as cycle,    
       sum(case    
       WHEN A.msttime >= @StartTime  AND A.sttime <=@EndTime  THEN DateDiff(second,A.msttime,A.sttime)    
       WHEN ( A.msttime < @StartTime  AND A.sttime <= @EndTime  AND A.sttime > @StartTime ) THEN DateDiff(second,@StartTime,A.sttime)    
       WHEN ( A.msttime >= @StartTime   AND A.msttime <@EndTime  AND A.sttime > @EndTime  ) THEN DateDiff(second,A.msttime,@EndTime )    
       WHEN ( A.msttime < @StartTime  AND A.sttime > @EndTime ) THEN DateDiff(second,@StartTime,@EndTime )    
       END)  as LD    
    from autodata A where (A.datatype=1) and    
       ((A.msttime >= @StartTime  AND A.ndtime <=@EndTime)    
       OR ( A.msttime < @StartTime  AND A.ndtime <= @EndTime AND A.ndtime > @StartTime )    
       OR ( A.msttime >= @StartTime   AND A.msttime <@EndTime AND A.ndtime > @EndTime )    
       OR ( A.msttime < @StartTime  AND A.ndtime > @EndTime) )    
    group by A.mc    
    ) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface    
    
    
    /* Fetching Down Records from Production Cycle  */    
    /* If Down Records of TYPE-2*/    
    UPDATE  #CockpitData SET cycletime = isnull(cycletime,0) - isNull(t2.Down,0)    
    FROM    
    (Select AutoData.mc ,    
    SUM(    
    CASE    
     When autodata.sttime <= @StartTime Then datediff(s, @StartTime,autodata.ndtime )    
     When autodata.sttime > @StartTime Then datediff(s , autodata.sttime,autodata.ndtime)    
    END) as Down    
    From AutoData INNER Join    
     (Select mc,Sttime,NdTime From AutoData    
      Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And    
      (msttime < @StartTime)And (ndtime > @StartTime) AND (ndtime <= @EndTime)) as T1    
    ON AutoData.mc=T1.mc    
    Where AutoData.DataType=2    
    And ( autodata.Sttime > T1.Sttime )    
    And ( autodata.ndtime <  T1.ndtime )    
    AND ( autodata.ndtime >  @StartTime )    
    GROUP BY AutoData.mc)AS T2 Inner Join #CockpitData on t2.mc = #CockpitData.machineinterface    
    
    /* If Down Records of TYPE-3*/    
    UPDATE  #CockpitData SET cycletime = isnull(cycletime,0) - isNull(t2.Down,0)    
    FROM    
    (Select AutoData.mc ,    
    SUM(CASE    
     When autodata.ndtime > @EndTime Then datediff(s,autodata.sttime, @EndTime )    
     When autodata.ndtime <=@EndTime Then datediff(s , autodata.sttime,autodata.ndtime)    
    END) as Down    
    From AutoData INNER Join    
     (Select mc,Sttime,NdTime From AutoData    
      Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And    
      (sttime >= @StartTime)And (ndtime > @EndTime) and (sttime<@EndTime) ) as T1    
    ON AutoData.mc=T1.mc    
    Where AutoData.DataType=2    
    And (T1.Sttime < autodata.sttime  )    
    And ( T1.ndtime >  autodata.ndtime)    
    AND (autodata.sttime  <  @EndTime)    
    GROUP BY AutoData.mc)AS T2 Inner Join #CockpitData on t2.mc = #CockpitData.machineinterface    
    
    /* If Down Records of TYPE-4*/    
    UPDATE  #CockpitData SET cycletime = isnull(cycletime,0) - isNull(t2.Down,0)    
    FROM    
    (Select AutoData.mc ,    
    SUM(CASE    
     When autodata.sttime >= @StartTime AND autodata.ndtime <= @EndTime Then datediff(s , autodata.sttime,autodata.ndtime)    
     When autodata.sttime < @StartTime AND autodata.ndtime > @StartTime AND autodata.ndtime<=@EndTime Then datediff(s, @StartTime,autodata.ndtime )    
     When autodata.sttime>=@StartTime And autodata.sttime < @EndTime AND autodata.ndtime > @EndTime Then datediff(s,autodata.sttime, @EndTime )    
     When autodata.sttime<@StartTime AND autodata.ndtime>@EndTime   Then datediff(s , @StartTime,@EndTime)    
    END) as Down    
    From AutoData INNER Join    
     (Select mc,Sttime,NdTime From AutoData    
      Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And    
      (msttime < @StartTime)And (ndtime > @EndTime) ) as T1    
    ON AutoData.mc=T1.mc    
    Where AutoData.DataType=2    
    And (T1.Sttime < autodata.sttime  )    
    And ( T1.ndtime >  autodata.ndtime)    
    AND (autodata.ndtime  >  @StartTime)    
    AND (autodata.sttime  <  @EndTime)    
    GROUP BY AUTODATA.mc    
    )AS T2 Inner Join #CockpitData on t2.mc = #CockpitData.machineinterface    
    
    
    --mod 4:Get utilised time and loadunload over lapping with PDT.    
    If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'    
    BEGIN    
    
    
      UPDATE #PLD SET pPlannedDT = isnull(pPlannedDT,0) + isNull(TT.CyclePDT ,0),LPlannedDT = isnull(LPlannedDT,0) + isNull(TT.LDPDT,0)    
      FROM    
      (    
       SELECT autodata.MC,SUM    
        (CASE    
        WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN DateDiff(second,autodata.sttime,autodata.ndtime)     
        WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)    
        WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )    
        WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )    
        END)  as CyclePDT,    
        sum(case    
        WHEN autodata.msttime >= T.StartTime  AND autodata.sttime <=T.EndTime  THEN DateDiff(second,autodata.msttime,autodata.sttime)    
        WHEN ( autodata.msttime < T.StartTime  AND autodata.sttime <= T.EndTime  AND autodata.sttime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.sttime)    
        WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.sttime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )    
        WHEN ( autodata.msttime < T.StartTime  AND autodata.sttime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )    
        END)  as LDPDT    
        FROM     
         (    
          select M.machineid,mc,sttime,ndtime,msttime from autodata    
          inner join machineinformation M on M.interfaceid=Autodata.mc    
           where autodata.DataType=1 And     
          ((autodata.msttime >= @starttime  AND autodata.ndtime <=@Endtime)    
          OR ( autodata.msttime < @starttime  AND autodata.ndtime <= @Endtime AND autodata.ndtime > @starttime )    
          OR ( autodata.msttime >= @starttime   AND autodata.msttime <@Endtime AND autodata.ndtime > @Endtime )    
          OR ( autodata.msttime < @starttime  AND autodata.ndtime > @Endtime))    
         )    
       AutoData inner jOIN #PlannedDownTimes T on T.Machineid=AutoData.machineid    
       WHERE     
        (    
        (autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)    
        OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )    
        OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )    
        OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )    
       group by autodata.mc    
      ) as TT INNER JOIN #CockpitData ON TT.mc = #CockpitData.MachineInterface    
    
      --mod 4(4):Handle intearction between ICD and PDT for type 1 production record for the selected time period.    
      UPDATE  #PLD set IPlannedDT =isnull(IPlannedDT,0) + isNull(T2.IPDT ,0)  FROM     
      (    
       Select T1.mc,SUM(    
       CASE      
        When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1    
        When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2    
        When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3    
        when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4    
        END) as IPDT from    
           (    
           Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype from autodata A    
           Where A.DataType=2    
           and exists     
             (    
             Select B.Sttime,B.NdTime,B.mc From AutoData B    
             Where B.mc = A.mc and    
             B.DataType=1 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And    
             (B.msttime >= @starttime AND B.ndtime <= @Endtime) and    
             (B.sttime < A.sttime) AND (B.ndtime > A.ndtime)     
             )    
           )as T1 inner join    
      (select  machine,Case when starttime<@starttime then @starttime else starttime end as starttime,     
      case when endtime> @Endtime then @Endtime else endtime end as endtime from dbo.PlannedDownTimes     
      where ((( StartTime >=@starttime) And ( EndTime <=@Endtime))    
      or (StartTime < @starttime  and  EndTime <= @Endtime AND EndTime > @starttime)    
      or (StartTime >= @starttime  AND StartTime <@Endtime AND EndTime > @Endtime)    
      or (( StartTime <@starttime) And ( EndTime >@Endtime )) )    
      )T on T1.machine=T.machine AND    
      ((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))    
      or (T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)    
      or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )    
      or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )group by T1.mc    
      )AS T2  INNER JOIN #PLD ON T2.mc = #PLD.MachineInterface    
    
     /* Fetching Down Records from Production Cycle  */    
     /* If production  Records of TYPE-2*/    
     UPDATE  #PLD set IPlannedDT =isnull(IPlannedDT,0) + isNull(T2.IPDT ,0)  FROM     
     (    
      Select T1.mc,SUM(    
      CASE      
       When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1    
       When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2    
       When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3    
       when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4    
      END) as IPDT from    
        (Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype from autodata A    
        Where A.DataType=2    
        and exists     
          (    
          Select B.Sttime,B.NdTime From AutoData B    
          Where B.mc = A.mc and    
          B.DataType=1 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And    
          (B.msttime < @StartTime And B.ndtime > @StartTime AND B.ndtime <= @EndTime)     
          And ((A.Sttime > B.Sttime) And ( A.ndtime < B.ndtime) AND ( A.ndtime > @StartTime ))    
          )    
        )as T1 inner join    
      (select  machine,Case when starttime<@starttime then @starttime else starttime end as starttime,     
      case when endtime> @Endtime then @Endtime else endtime end as endtime from dbo.PlannedDownTimes     
      where ((( StartTime >=@starttime) And ( EndTime <=@Endtime))    
      or (StartTime < @starttime  and  EndTime <= @Endtime AND EndTime > @starttime)    
      or (StartTime >= @starttime  AND StartTime <@Endtime AND EndTime > @Endtime)    
      or (( StartTime <@starttime) And ( EndTime >@Endtime )) )    
      )T on T1.machine=T.machine AND    
      (( T.StartTime >= @StartTime ) And ( T.StartTime <  T1.ndtime )) group by T1.mc    
     )AS T2  INNER JOIN #PLD ON T2.mc = #PLD.MachineInterface    
         
     /* If production Records of TYPE-3*/    
     UPDATE  #PLD set IPlannedDT =isnull(IPlannedDT,0) + isNull(T2.IPDT ,0)FROM     
     (    
      Select T1.mc,SUM(    
      CASE      
        When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1    
        When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2    
        When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3    
        when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4    
       END) as IPDT from    
          (Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype from autodata A    
          Where A.DataType=2    
          and exists     
            (    
            Select B.Sttime,B.NdTime From AutoData B    
            Where B.mc = A.mc and    
            B.DataType=1 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And    
            (B.sttime >= @StartTime And B.ndtime > @EndTime and B.sttime <@EndTime) and    
            ((B.Sttime < A.sttime  )And ( B.ndtime > A.ndtime) AND (A.msttime < @EndTime))    
            )    
          )as T1 inner join    
      (select  machine,Case when starttime<@starttime then @starttime else starttime end as starttime,     
      case when endtime> @Endtime then @Endtime else endtime end as endtime from dbo.PlannedDownTimes     
      where ((( StartTime >=@starttime) And ( EndTime <=@Endtime))    
      or (StartTime < @starttime  and  EndTime <= @Endtime AND EndTime > @starttime)    
      or (StartTime >= @starttime  AND StartTime <@Endtime AND EndTime > @Endtime)    
      or (( StartTime <@starttime) And ( EndTime >@Endtime )) )    
      )T on T1.machine=T.machine    
      AND (( T.EndTime > T1.Sttime )And ( T.EndTime <=@EndTime )) group by T1.mc    
      )AS T2  INNER JOIN #PLD ON T2.mc = #PLD.MachineInterface    
         
         
     /* If production Records of TYPE-4*/    
     UPDATE  #PLD set IPlannedDT =isnull(IPlannedDT,0) + isNull(T2.IPDT ,0)FROM     
     (    
      Select T1.mc,SUM(    
      CASE      
       When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1    
       When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2    
       When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3    
       when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4    
      END) as IPDT from    
       (Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype from autodata A    
       Where A.DataType=2    
       and exists     
         (    
         Select B.Sttime,B.NdTime From AutoData B    
         Where B.mc = A.mc and    
         B.DataType=1 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And    
         (B.msttime < @StartTime And B.ndtime > @EndTime)    
         And ((B.Sttime < A.sttime)And ( B.ndtime >  A.ndtime)AND (A.ndtime  >  @StartTime) AND (A.sttime  <  @EndTime))    
         )    
       )as T1 inner join    
       (select  machine,Case when starttime<@starttime then @starttime else starttime end as starttime,     
       case when endtime> @Endtime then @Endtime else endtime end as endtime from dbo.PlannedDownTimes     
       where ((( StartTime >=@starttime) And ( EndTime <=@Endtime))    
       or (StartTime < @starttime  and  EndTime <= @Endtime AND EndTime > @starttime)    
       or (StartTime >= @starttime  AND StartTime <@Endtime AND EndTime > @Endtime)    
       or (( StartTime <@starttime) And ( EndTime >@Endtime )) )    
       )T on T1.machine=T.machine AND    
     (( T.StartTime >=@StartTime) And ( T.EndTime <=@EndTime )) group by T1.mc    
     )AS T2  INNER JOIN #PLD ON T2.mc = #PLD.MachineInterface    
    END    
    
    
    If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dt 
 
ime_4m_PLD')<>'Y')    
    BEGIN    
      -- Type 1    
      UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)    
      from    
      (select mc,sum(    
      CASE    
      WHEN (loadunload) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0    
      THEN isnull(downcodeinformation.Threshold,0)    
      ELSE loadunload    
      END) AS LOSS    
      from autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid    
      where (autodata.msttime>=@StartTime)    
      and (autodata.ndtime<=@EndTime)    
      and (autodata.datatype=2)    
      and (downcodeinformation.availeffy = 1)     
      group by autodata.mc) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface    
    
      -- Type 2    
      UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)    
      from    
      (select      mc,sum(    
      CASE WHEN DateDiff(second, @StartTime, ndtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0    
      then isnull(downcodeinformation.Threshold,0)    
      ELSE DateDiff(second, @StartTime, ndtime)    
      END)loss    
      from autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid    
      where (autodata.sttime<@StartTime)    
      and (autodata.ndtime>@StartTime)    
      and (autodata.ndtime<=@EndTime)    
      and (autodata.datatype=2)    
      and (downcodeinformation.availeffy = 1)    
      group by autodata.mc    
      ) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface    
    
      -- Type 3    
      UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)    
      from    
      (select      mc,SUM(    
      CASE WHEN DateDiff(second,stTime, @Endtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0    
      then isnull(downcodeinformation.Threshold,0)    
      ELSE DateDiff(second, stTime, @Endtime)    
      END)loss    
      from autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid    
      where (autodata.msttime>=@StartTime)    
      and (autodata.sttime<@EndTime)    
      and (autodata.ndtime>@EndTime)    
      and (autodata.datatype=2)    
      and (downcodeinformation.availeffy = 1)    
      group by autodata.mc    
      ) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface    
    
      -- Type 4    
      UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)    
      from    
      (select mc,sum(    
      CASE WHEN DateDiff(second, @StartTime, @Endtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0    
      then isnull(downcodeinformation.Threshold,0)    
      ELSE DateDiff(second, @StartTime, @Endtime)    
      END)loss    
      from autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid    
      where autodata.msttime<@StartTime    
      and autodata.ndtime>@EndTime    
      and (autodata.datatype=2)    
      and (downcodeinformation.availeffy = 1)    
      group by autodata.mc    
      ) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface    
    
      ---get the downtime for the time period    
      UPDATE #CockpitData SET Stoppage = isnull(Stoppage,0) + isNull(t2.down,0)    
      from    
      (    
       select mc,sum(    
       CASE    
       WHEN  autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime  THEN  loadunload    
       WHEN (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  THEN DateDiff(second, @StartTime, ndtime)    
       WHEN (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)  THEN DateDiff(second, stTime, @Endtime)    
       WHEN autodata.msttime<@StartTime and autodata.ndtime>@EndTime   THEN DateDiff(second, @StartTime, @EndTime)    
       END    
       )AS down    
       from autodata inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid    
       where autodata.datatype=2 AND    
       (    
       (autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)    
       OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)    
       OR (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)    
       OR (autodata.msttime<@StartTime and autodata.ndtime>@EndTime )    
       )    
       group by autodata.mc    
      ) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface    
    
    End    
    
    
    ---Handling interaction between PDT and Stoppage . Also interaction between PDT and Management Loss    
    If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'    
    BEGIN    
    
     ---step 1     
     UPDATE #CockpitData SET Stoppage = isnull(Stoppage,0) + isNull(t2.down,0)    
     from    
     (select mc,sum(    
       CASE    
       WHEN  autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime  THEN  loadunload    
       WHEN (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  THEN DateDiff(second, @StartTime, ndtime)    
       WHEN (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)  THEN DateDiff(second, stTime, @Endtime)    
       WHEN autodata.msttime<@StartTime and autodata.ndtime>@EndTime   THEN DateDiff(second, @StartTime, @EndTime)    
       END    
      )AS down    
     from autodata inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid    
     where autodata.datatype=2 AND    
     (    
     (autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)    
     OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)    
     OR (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)    
     OR (autodata.msttime<@StartTime and autodata.ndtime>@EndTime )    
     ) AND (downcodeinformation.availeffy = 0)    
     group by autodata.mc    
     ) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface    
    
     ---step 2 checking for (downcodeinformation.availeffy = 0) to get the overlapping PDT and Downs which is not ML    
     UPDATE #PLD set dPlannedDT =isnull(dPlannedDT,0) + isNull(TT.PPDT ,0)    
     FROM(    
      --Production PDT    
      SELECT autodata.MC, SUM    
         (CASE    
       WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)    
       WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)    
       WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )    
       WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )    
       END ) as PPDT    
      FROM AutoData CROSS jOIN #PlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid    
      WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND    
       (    
       (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)    
       OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )    
       OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )    
       OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)    
       ) AND (downcodeinformation.availeffy = 0)    
      group by autodata.mc    
     ) as TT INNER JOIN #PLD ON TT.mc = #PLD.MachineInterface    
    
    
     ---step 3    
     ---Management loss calculation    
     ---IN T1 Select get all the downtimes which is of type management loss    
     ---IN T2  get the time to be deducted from the cycle if the cycle is overlapping with the PDT. And it should be ML record    
     ---In T3 Get the real management loss , and time to be considered as real down for each cycle(by comaring with the ML threshold)    
     ---In T4 consolidate everything at machine level and update the same to #CockpitData for ManagementLoss and MLDown    
         
     UPDATE #CockpitData SET  ManagementLoss = isnull(ManagementLoss,0) + isNull(t4.Mloss,0),MLDown=isNull(MLDown,0)+isNull(t4.Dloss,0)    
     from    
     (select T3.mc,sum(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss from (    
     select   t1.id,T1.mc,T1.Threshold,    
     case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0    
     then DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)- isnull(T1.Threshold ,0)    
     else 0 End  as Dloss,    
     case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0    
     then isnull(T1.Threshold,0)    
     else (DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)) End  as Mloss    
      from    
         
     (   select id,mc,comp,opn,opr,D.threshold,    
      case when autodata.sttime<@StartTime then @StartTime else sttime END as sttime,    
             case when ndtime>@EndTime then @EndTime else ndtime END as ndtime    
      from autodata    
      inner join downcodeinformation D    
      on autodata.dcode=D.interfaceid where autodata.datatype=2 AND    
      (    
      (autodata.sttime>=@StartTime  and  autodata.ndtime<=@EndTime)    
      OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)    
      OR (autodata.sttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)    
      OR (autodata.sttime<@StartTime and autodata.ndtime>@EndTime )    
      ) AND (D.availeffy = 1)) as T1      
     left outer join    
     (SELECT autodata.id,    
          sum(CASE    
       WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)    
       WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)    
       WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )    
       WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )    
       END ) as PPDT    
      FROM AutoData CROSS jOIN #PlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid    
      WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND    
       (    
       (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)    
       OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )    
       OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )    
       OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)    
       )    
       AND (downcodeinformation.availeffy = 1)     
       group  by autodata.id ) as T2 on T1.id=T2.id ) as T3  group by T3.mc    
     ) as t4 inner join #CockpitData on t4.mc = #CockpitData.machineinterface    
    
     UPDATE #CockpitData SET Stoppage = isnull(Stoppage,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)    
    END    
    
    UPDATE #CockpitData SET CN = isnull(CN,0) + isNull(t2.C1N1,0) from    
    (    
     select mc,    
     SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))* autodata.partscount) C1N1    
     FROM autodata INNER JOIN    
     componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN    
     componentinformation ON autodata.comp = componentinformation.InterfaceID AND    
     componentoperationpricing.componentid = componentinformation.componentid    
     inner join machineinformation on machineinformation.interfaceid=autodata.mc    
     and componentoperationpricing.machineid=machineinformation.machineid    
     where (((autodata.sttime>=@StartTime)and (autodata.ndtime<=@EndTime)) or    
     ((autodata.sttime<@StartTime)and (autodata.ndtime>@StartTime)and (autodata.ndtime<=@EndTime)) )    
     and (autodata.datatype=1)    
     group by autodata.mc    
    ) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface    
    
    
    -- mod 4 Ignore count from CN calculation which is over lapping with PDT    
    If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'    
    BEGIN    
     UPDATE #CockpitData SET CN = isnull(CN,0) - isNull(t2.C1N1,0)    
     From    
     (    
      select mc,SUM((O.cycletime * ISNULL(A.PartsCount,1))/ISNULL(O.SubOperations,1))  C1N1    
      From autodata A    
      Inner join machineinformation M on M.interfaceid=A.mc    
      Inner join componentinformation C ON A.Comp=C.interfaceid    
      Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID    
      Cross jOIN #PlannedDownTimes T    
      WHERE A.DataType=1 AND T.MachineInterface=A.mc    
      AND(A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)    
      AND(A.ndtime > @StartTime  AND A.ndtime <=@EndTime)    
      Group by mc    
     ) as T2    
     inner join #CockpitData  on t2.mc = #CockpitData.machineinterface    
    END    
    
    
    --mod 4: Update Utilised Time and Down time    
    UPDATE #CockpitData SET     
    cycletime=(cycletime-ISNULL(#PLD.pPlannedDT,0)+isnull(#PLD.IPlannedDT,0)),    
    Loadunload = (loadunload - isnull(#pld.LPlannedDT,0)),    
    Stoppage=(Stoppage-ISNULL(#PLD.dPlannedDT,0)),    
    PlannedDT = (ISNULL(#PLD.pPlannedDT,0) + ISNULL(#PLD.dPlannedDT,0) + isnull(#pld.LPlannedDT,0))    
    From #CockpitData Inner Join #PLD on #PLD.Machineid=#CockpitData.Machineid    
    
    -- Calculate efficiencies    
    UPDATE #CockpitData    
    SET    
     ProductionEfficiency = (CN/(cycletime+loadunload)) ,    
     AvailabilityEfficiency = ((cycletime+loadunload))/((cycletime+loadunload) + Stoppage - ManagementLoss)    
    WHERE cycletime <> 0    
    
    UPDATE #CockpitData    
    SET    
     OverAllEfficiency = (ProductionEfficiency * AvailabilityEfficiency)*100,    
     ProductionEfficiency = ProductionEfficiency * 100 ,    
     AvailabilityEfficiency = AvailabilityEfficiency * 100    
    
    update #cockpitdata set Stoppage = (Stoppage - ManagementLoss)    
End    
    
If @param = 'Donutchart'    
Begin    
 select Machineid,round(cycletime/60,2) as cycletime,round(Loadunload/60,2) as Loadunload,round(Stoppage/60,2) as Stoppage,    
 round(ManagementLoss/60,2) as ManagementLoss,round(PlannedDT/60,2) as PlannedDT from #CockpitData    
end    
    
    
If @param = 'Efficiency'    
Begin    
 select Machineid,Round(AvailabilityEfficiency,2) as AvailabilityEfficiency,Round(ProductionEfficiency,2) as ProductionEfficiency,    
 Round(OverAllEfficiency,2) as OverAllEfficiency,PEGreen ,PERed,AEGreen ,AERed ,OEGreen ,OERed from #CockpitData    
end    
    
If @param='energy'    
begin    
    
   declare @RecCount as nvarchar(10)    
   Select @reccount=isnull(Valueinint,0) from shopdefaults where parameter='PickNoOfRecordsFrmAutodata'    
    
   select @strsql=''    
   SELECT @strsql= @strsql + 'insert into #Runningpart_Part(Machineid,Componentid,operation,shiftstart,shiftend,stdthreshold)      
   select top 1  T.machineid,T.Componentid,T.operationno,T.sttime,T.ndtime,isnull(T.UpperEnergyThreshold,0) from     
   (    
   select A.machineid,A.Componentid,A.operationno,Min(A.sttime) as sttime,Max(A.ndtime) as ndtime,isnull(A.UpperEnergyThreshold,0) as UpperEnergyThreshold from     
   (    
   select Top '+@reccount+' Machineinformation.machineid,C.Componentid,CO.operationno,sttime,ndtime,isnull(CO.UpperEnergyThreshold,0) as UpperEnergyThreshold from Autodata A    
   inner join Machineinformation on A.mc=Machineinformation.interfaceid      
   inner join Componentinformation C on A.comp=C.interfaceid      
   inner join Componentoperationpricing CO on A.opn=CO.interfaceid      
   and Machineinformation.Machineid=CO.Machineid and C.Componentid=CO.Componentid'      
   SELECT @strsql = @strsql + @strmachine      
   SELECT @strsql = @strsql + ' where sttime>='''+convert(nvarchar(20),@starttime)+''' and ndtime<='''+convert(nvarchar(20),@endtime)+'''    
   Order by sttime desc    
   )A     
   Group by A.machineid,A.Componentid,A.operationno,A.UpperEnergyThreshold     
   )T Order by T.sttime desc '    
   print @strsql    
   exec (@strsql)      
    
      select @strsql=''    
   SELECT @strsql= @strsql + 'update #Runningpart_Part set Noofrecords =  isnull(Noofrecords,0) + isnull(T.reccount,0) from(    
   Select count(mc)  as reccount from     
   (    
   select Top '+@reccount+' mc from Autodata A    
   inner join Machineinformation on A.mc=Machineinformation.interfaceid      
   inner join Componentinformation C on A.comp=C.interfaceid      
   inner join Componentoperationpricing CO on A.opn=CO.interfaceid      
   and Machineinformation.Machineid=CO.Machineid and C.Componentid=CO.Componentid'      
   SELECT @strsql = @strsql + @strmachine      
   SELECT @strsql = @strsql + ' where sttime>='''+convert(nvarchar(20),@starttime)+''' and ndtime<='''+convert(nvarchar(20),@endtime)+'''     
   Order by sttime desc    
   )A1 ) as T '    
   print @strsql    
   exec (@strsql)      
    
  
  
  
   set @strsql = ''    
   SET @strsql = '    
   insert into #finaldata(MachineID,    
    MachineInterface,    
    Energy,    
    Maxenergy,    
    Minenergy)'    
   SET @strsql = @strsql + '    
   SELECT MachineInformation.MachineID, MachineInformation.interfaceid,0,0,0 FROM  MachineInformation    
   inner JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID      
   WHERE MachineInformation.interfaceid > ''0 '' and  MachineInformation.devicetype=''5'''    
   SET @strSql =  @strSql + @strMachine + @strPlantID     
   print @strSql    
   EXEC(@strSql)    
    
  ---- To calculate Energy for the Running M-C-O this will be used for AverageEnergy calculation From here -----------    
  Update #FinalData    
  set #FinalData.MinEnergy = ISNULL(#FinalData.MinEnergy,0)+ISNULL(t1.kwh,0) from     
  (    
  select T.MachineiD,round(kwh,2) as kwh from     
   (    
    select  tcs_energyconsumption.MachineiD,min(gtime) as mingtime    
    from tcs_energyconsumption WITH(NOLOCK)     
    --inner join #FinalData on tcs_energyconsumption.machineID = #FinalData.MachineID     
--    inner join #Runningpart_Part on tcs_energyconsumption.machineID = #Runningpart_Part.MachineID     
    where tcs_energyconsumption.kwh>0 and tcs_energyconsumption.gtime >= '2014-09-05 10:00:00.000'  
    and tcs_energyconsumption.gtime <= '2014-09-05 11:15:19.000'  
    group by tcs_energyconsumption.MachineiD    
   )T inner join tcs_energyconsumption on tcs_energyconsumption.gtime=T.mingtime    
  ) as t1  inner join #FinalData on t1.machineiD = #FinalData.machineID     
    
    
    
  Update #FinalData    
  set #FinalData.MaxEnergy = ISNULL(#FinalData.MaxEnergy,0)+ISNULL(t1.kwh,0) from     
  (    
  select T.MachineiD,round(kwh,2)as kwh from     
   (    
    select  tcs_energyconsumption.MachineiD,max(gtime) as maxgtime    
    from tcs_energyconsumption WITH(NOLOCK)     
    inner join #FinalData on tcs_energyconsumption.machineID = #FinalData.MachineID     
    inner join #Runningpart_Part on tcs_energyconsumption.machineID = #Runningpart_Part.MachineID     
    where tcs_energyconsumption.gtime >= #Runningpart_Part.shiftstart    
    and tcs_energyconsumption.gtime <= #Runningpart_Part.shiftend    
    group by  tcs_energyconsumption.MachineiD    
   )T inner join tcs_energyconsumption on tcs_energyconsumption.gtime=T.maxgtime    
   ) as t1 inner join #FinalData on t1.machineiD = #FinalData.machineID     
   
  
  Update #FinalData set #FinalData.Energy = ISNULL(#FinalData.Energy,0)+ISNULL(t1.kwh,0)    
  from     
  (    
   select MachineiD,round((MaxEnergy - MinEnergy),2) as kwh from #FinalData     
  ) as t1 inner join #FinalData on t1.machineiD = #FinalData.machineID    
  ---- To calculate Energy for the Running M-C-O this will be used for AverageEnergy calculation Till here -------    
    
    
  Update #FinalData set #FinalData.AvgEnergy = ISNULL(#FinalData.AvgEnergy,0)+ISNULL(t1.Avgeng,0)    
  from     
  (    
   select #Runningpart_Part.MachineiD,(Energy/#Runningpart_Part.Noofrecords) as Avgeng from #FinalData     
   inner join #Runningpart_Part on #FinalData.machineID = #Runningpart_Part.MachineID     
   where energy>0    
  ) as t1 inner join #FinalData on t1.machineiD = #FinalData.machineID    
    
  Update #FinalData set #FinalData.EnergyEff = ISNULL(#FinalData.EnergyEff,0)+ISNULL(t1.eff,0)    
  from     
  (    
   select #Runningpart_Part.MachineiD,(#Runningpart_Part.stdthreshold/#FinalData.AvgEnergy)*100 as eff from #FinalData     
   inner join #Runningpart_Part on #FinalData.machineID = #Runningpart_Part.MachineID     
   where #Runningpart_Part.stdthreshold>0    
  ) as t1 inner join #FinalData on t1.machineiD = #FinalData.machineID    
    
  
  
    
  --------------- To calculate Energy at Machine Level from here ------------------------    
  Update #FinalData set MinEnergy = 0,MaxEnergy=0,Energy=0    
    
  Update #FinalData    
  set #FinalData.MinEnergy = ISNULL(#FinalData.MinEnergy,0)+ISNULL(t1.kwh,0) from     
  (    
  select T.MachineiD,round(kwh,2) as kwh from     
   (    
    select  tcs_energyconsumption.MachineiD,min(gtime) as mingtime    
    from tcs_energyconsumption WITH(NOLOCK)     
    inner join #FinalData on tcs_energyconsumption.machineID = #FinalData.MachineID     
    where tcs_energyconsumption.kwh>0 and tcs_energyconsumption.gtime >= @starttime    
    and tcs_energyconsumption.gtime <= @endtime    
    group by tcs_energyconsumption.MachineiD    
   )T inner join tcs_energyconsumption on tcs_energyconsumption.gtime=T.mingtime    
  ) as t1  inner join #FinalData on t1.machineiD = #FinalData.machineID     
    
    
    
  Update #FinalData    
  set #FinalData.MaxEnergy = ISNULL(#FinalData.MaxEnergy,0)+ISNULL(t1.kwh,0) from     
  (    
  select T.MachineiD,round(kwh,2)as kwh from     
   (    
    select  tcs_energyconsumption.MachineiD,max(gtime) as maxgtime    
    from tcs_energyconsumption WITH(NOLOCK)     
    inner join #FinalData on tcs_energyconsumption.machineID = #FinalData.MachineID     
    where tcs_energyconsumption.gtime >= @starttime    
    and tcs_energyconsumption.gtime <= @endtime    
    group by  tcs_energyconsumption.MachineiD    
   )T inner join tcs_energyconsumption on tcs_energyconsumption.gtime=T.maxgtime    
   ) as t1 inner join #FinalData on t1.machineiD = #FinalData.machineID     
    
    
  Update #FinalData set #FinalData.Energy = ISNULL(#FinalData.Energy,0)+ISNULL(t1.kwh,0)    
  from     
  (    
   select MachineiD,round((MaxEnergy - MinEnergy),2) as kwh from #FinalData     
  ) as t1 inner join #FinalData on t1.machineiD = #FinalData.machineID    
  ------- To calculate Energy at Machine Level Till Here ---------------------    
    
    
 -- select MachineID,isnull(round(Energy,2),0) as Energy,isnull(Round(AvgEnergy,2),0) as AvgEnergy,isnull(round(EnergyEff,2),0) as EnergyEff from #finaldata    
  select MachineID,'10' as Energy,'2' as AvgEnergy,'53.2' as EnergyEff from #finaldata    
    
end    
    
If @param='RunningPart'    
Begin    
    
 declare @start as datetime    
     
    
 select @start = dbo.f_GetLogicalDay(@starttime,'start')    
    
 select @strsql=''    
 SELECT @strsql= @strsql + 'insert into #Runningpart_Part(Machineid,Componentid,operation,shiftactual,shifttarget)      
    select Top 1 Machineinformation.machineid,C.Componentid,CO.operationno,0,0 from Autodata A      
    inner join Machineinformation on A.mc=Machineinformation.interfaceid      
    inner join Componentinformation C on A.comp=C.interfaceid      
    inner join Componentoperationpricing CO on A.opn=CO.interfaceid      
    and Machineinformation.Machineid=CO.Machineid and C.Componentid=CO.Componentid      
    where sttime>='''+convert(nvarchar(20),@starttime)+''' and ndtime<='''+convert(nvarchar(20),@endtime)+'''   '      
  SELECT @strsql = @strsql + @strmachine      
    SELECT @strsql = @strsql + ' Order by A.sttime desc'    
 print @strsql    
 exec (@strsql)      
    
 --Calculation of PartsCount Begins..    
 UPDATE #Runningpart_Part SET shiftactual = ISNULL(shiftactual,0) + ISNULL(t2.comp,0)    
 From    
 (        
  Select M.machineid,C.componentid,O.Operationno,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp     
      From (select mc,SUM(autodata.partscount)AS OrginalCount,comp,opn from autodata    
      where (autodata.ndtime>@StartTime) and (autodata.ndtime<=@EndTime) and (autodata.datatype=1)    
      Group By mc,comp,opn) as T1    
  Inner join Machineinformation M on M.interfaceID = T1.mc    
  Inner join componentinformation C on T1.Comp=C.interfaceid    
  Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineID = M.MachineID    
  GROUP BY M.machineid,C.componentid,O.Operationno    
 ) As T2 Inner join #Runningpart_Part on T2.machineid = #Runningpart_Part.Machineid and T2.componentid = #Runningpart_Part.componentid and T2.Operationno = #Runningpart_Part.Operation     
    
 --Mod 4 Apply PDT for calculation of Count    
 If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'    
 BEGIN    
    
   UPDATE #Runningpart_Part SET components = ISNULL(shiftactual,0) - ISNULL(T2.comp,0) from(    
    select M.machineid,C.componentid,O.Operationno,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp From     
    (     
     select mc,Sum(ISNULL(PartsCount,1))AS OrginalCount,comp,opn from autodata    
     CROSS JOIN #PlannedDownTimes T    
     WHERE autodata.DataType=1 And T.MachineInterface = autodata.mc    
     AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)    
     AND (autodata.ndtime > @StartTime  AND autodata.ndtime <=@EndTime)    
     Group by mc,comp,opn    
    ) as T1    
   Inner join Machineinformation M on M.interfaceID = T1.mc    
   Inner join componentinformation C on T1.Comp=C.interfaceid    
   Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineID = M.MachineID    
   GROUP BY M.machineid,C.componentid,O.Operationno    
   ) as T2 Inner join #Runningpart_Part on T2.machineid = #Runningpart_Part.Machineid and T2.componentid = #Runningpart_Part.componentid and T2.Operationno = #Runningpart_Part.Operation     
    
 END    
    
    
    update #Runningpart_Part set Shifttarget= ISNULL(Shifttarget,0) + ISNULL(T2.tcount,0) from    
 (    
  select date as date1,shift,machine,component,L.operation as opn,idealcount as tcount from loadschedule L    
  Inner join #Runningpart_Part on L.machine = #Runningpart_Part.Machineid and L.component = #Runningpart_Part.componentid and L.Operation = #Runningpart_Part.Operation     
  where date = convert(nvarchar(10),@start,112) and shift=@shift    
     ) as T2 Inner join #Runningpart_Part on T2.machine = #Runningpart_Part.Machineid and T2.component = #Runningpart_Part.componentid and T2.Opn = #Runningpart_Part.Operation     
    
   update #Runningpart_Part set Shifttarget= ISNULL(Shifttarget,0) + ISNULL(T2.tcount,0) from    
 (    
  select date as date1,shift,machine,component,L.operation as opn,idealcount as tcount from loadschedule L    
  Inner join #Runningpart_Part on L.machine = #Runningpart_Part.Machineid and L.component = #Runningpart_Part.componentid and L.Operation = #Runningpart_Part.Operation     
  where date in (select top 1 date from loadschedule where date < convert(nvarchar(10),@start,112) and shift = @shift order by date desc)  and shift=@shift    
     ) as T2 Inner join #Runningpart_Part on T2.machine = #Runningpart_Part.Machineid and T2.component = #Runningpart_Part.componentid and T2.Opn = #Runningpart_Part.Operation     
  where #Runningpart_Part.Shifttarget=0    
     
    
 select Machineid,Componentid,operation,shiftactual,shifttarget from #Runningpart_Part    
    
end    
    
If @param='Hourlydetails'    
Begin    
    
  declare @curstarttime as datetime      
  Declare @curendtime as datetime      
  declare @curstart as datetime      
  declare @hourid nvarchar(50)      
  Declare @StrDiv int      
  Declare @counter as datetime       
  declare @enddate as datetime   
    
   select @counter=convert(datetime, cast(DATEPART(yyyy,@StartTime)as nvarchar(4))+'-'+cast(datepart(mm,@StartTime)as nvarchar(2))+'-'+cast(datepart(dd,@StartTime)as nvarchar(2)) +' 00:00:00.000')      
            
      select @counter=  CASE      
      WHEN FROMDAY=1 AND TODAY=1 THEN dbo.f_GetLogicalDayStart(@counter)      
      WHEN FROMDAY=0 AND TODAY=1 THEN @COUNTER      
      WHEN FROMDAY=0 AND TODAY=0 THEN @COUNTER      
      END FROM SHIFTDETAILS WHERE RUNNING=1 AND SHIFTNAME=@SHIFT      
    
      Insert into #ShiftTemp(PDate,ShiftName, FromTime, ToTime)      
      Exec s_GetShiftTime @counter,@Shift    
        
      SELECT TOP 1 @counter=FromTime FROM #ShiftTemp ORDER BY FromTime ASC      
      SELECT TOP 1 @Enddate=ToTime FROM #ShiftTemp ORDER BY FromTime DESC      
      select @StrDiv=cast (ceiling (cast(datediff(second,@counter,@Enddate)as float ) /3600) as int)       
    
      While(@counter < @Enddate)      
      BEGIN      
        SELECT @curstarttime=@counter      
        SELECT @curendtime=DATEADD(Second,3600,@counter)      
        if @curendtime >= @Enddate      
        Begin      
         set @curendtime = @Enddate      
        End      
    
   Select @strsql=''    
   select @strsql ='Insert into #HourlyData1(HourName,Machineid,FromTime,ToTime,Actual,Target)'    
   select @strsql = @strsql + ' Select ''H''+ '''+ @i +''',Machineinformation.Machineid, ''' + convert(nvarchar(20),@curstarttime) + ''', ''' + convert(nvarchar(20),@curendtime) + ''',0,0    
   from Machineinformation inner join Plantmachine on Plantmachine.machineid=Machineinformation.machineid'    
   select @strsql = @strsql + @strmachine + @strPlantID    
   print @strsql    
   exec (@strsql)    
      
   select @i = @i + 1    
      SELECT @counter = DATEADD(Second,3600,@counter)      
     END      
    
 select @strsql=''    
 SELECT @strsql= @strsql + 'insert into #Runningpart_Part(Machineid,Componentid,operation,suboperation,cycletime,targetpercent)      
    select Top 1 A.mc,A.comp,A.opn,ISNULL(CO.SubOperations,1),CO.cycletime,CO.targetpercent from Autodata A      
    inner join Machineinformation on A.mc=Machineinformation.interfaceid      
    inner join Componentinformation C on A.comp=C.interfaceid      
    inner join Componentoperationpricing CO on A.opn=CO.interfaceid      
    and Machineinformation.Machineid=CO.Machineid and C.Componentid=CO.Componentid      
    where sttime>='''+convert(nvarchar(20),@starttime)+''' and ndtime<='''+convert(nvarchar(20),@endtime)+'''   '      
  SELECT @strsql = @strsql + @strmachine      
    SELECT @strsql = @strsql + ' Order by A.sttime desc'    
 print @strsql    
 exec (@strsql)      
    
 Insert into #HourlyData(HourName,Machineid,mc,comp,opn,FromTime,ToTime,Actual,Target,suboperation,cycletime,targetpercent)    
 Select H.HourName,H.machineid,R.Machineid,R.Componentid,R.Operation,H.FromTime,H.ToTime,H.Actual,H.Target,R.suboperation,R.cycletime,R.Targetpercent from #HourlyData1 H cross join #Runningpart_Part R    
    
    
    
 --Calculation of PartsCount Begins..    
 UPDATE #HourlyData SET actual = ISNULL(actual,0) + ISNULL(t2.compcount,0)    
 From    
 (        
  Select T1.mc,T1.comp,T1.opn,T1.Fromtime,T1.totime,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(T1.SubOperation,1))) As compcount     
      From     
    (    
     select A.mc,A.comp,A.opn,SUM(A.partscount)AS OrginalCount,H.fromtime,H.totime,H.suboperation from autodata A    
     inner join #HourlyData H on H.mc=A.mc and H.comp=A.comp and H.opn=A.opn    
     where (A.ndtime>H.FromTime) and (A.ndtime<=H.ToTime) and (A.datatype=1)    
     Group By A.mc,A.comp,A.opn,H.fromtime,H.totime,H.suboperation    
    ) as T1    
  GROUP BY T1.mc,T1.comp,T1.opn,T1.Fromtime,T1.totime    
 ) As T2 Inner join #HourlyData on T2.mc = #HourlyData.mc and T2.comp = #HourlyData.comp and T2.opn = #HourlyData.opn and T2.fromtime=#HourlyData.fromtime and T2.totime=#HourlyData.totime     
    
 --Mod 4 Apply PDT for calculation of Count    
 If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'    
 BEGIN    
    
   UPDATE #HourlyData SET actual = ISNULL(actual,0) - ISNULL(T2.compcount,0) from    
   (    
    select T1.mc,T1.comp,T1.opn,T1.Fromtime,T1.totime,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(T1.SubOperation,1))) as compcount From     
    (     
     select A.mc,Sum(ISNULL(A.PartsCount,1))AS OrginalCount,A.comp,A.opn,H.fromtime,H.totime,H.suboperation from autodata A    
     inner join #HourlyData H on H.mc=A.mc and H.comp=A.comp and H.opn=A.opn    
     CROSS JOIN #PlannedDownTimes T    
     WHERE autodata.DataType=1 And T.MachineInterface = A.mc    
     AND (A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)    
     AND (A.ndtime > H.FromTime  AND A.ndtime <=H.ToTime)    
     Group by A.mc,A.comp,A.opn,H.fromtime,H.totime,H.suboperation    
    ) as T1    
   GROUP BY T1.mc,T1.comp,T1.opn,T1.Fromtime,T1.totime    
   ) as T2 Inner join #HourlyData on T2.mc = #HourlyData.mc and T2.comp = #HourlyData.comp and T2.opn = #HourlyData.opn and T2.fromtime=#HourlyData.fromtime and T2.totime=#HourlyData.totime     
 END    
    
 --Calculation of Hourly Target begins by %Ideal    
 update #HourlyData set Target= isnull(Target,0)+ ISNULL(t2.tcount,0) from    
 (select H.comp,H.Opn,H.mc,H.fromtime,H.totime,tcount=((datediff(second,H.fromtime,H.totime)* H.suboperation)/H.cycletime)*isnull(H.targetpercent,100) /100    
  from #HourlyData H)as T2 Inner join #HourlyData on T2.mc = #HourlyData.mc and T2.comp = #HourlyData.comp and T2.opn = #HourlyData.opn and T2.fromtime=#HourlyData.fromtime and T2.totime=#HourlyData.totime     
     
 --To Appliy PDT for Hourly Target    
 If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'    
 BEGIN    
    
  update #HourlyData set Target=Target-((cast(t3.Totalpdt as float)/cast(datediff(ss,t3.Starttime,t3.Endtime) as float))*Target) from    
  (    
   Select Machineid,comp,opn,Starttime,Endtime,Sum(Datediff(ss,Starttimepdt,Endtimepdt))as TotalPDT    
   From (    
      select fd.StartTime,fd.EndTime,fd.MachineID,fd.comp,fd,opn,    
      Case when fd.StartTime <= pdt.StartTime then pdt.StartTime else fd.StartTime End as Starttimepdt,    
      Case when fd.EndTime >= pdt.EndTime then pdt.EndTime else fd.EndTime End as Endtimepdt    
      from (Select distinct machineid,comp,opn,fromtime as StartTime ,totime as EndTime from #HourlyData) as fd    
      cross join planneddowntimes pdt    
      where PDTstatus = 1  and fd.machineID = pdt.Machine and     
      ((pdt.StartTime >= fd.StartTime and pdt.EndTime <= fd.EndTime)or    
      (pdt.StartTime < fd.StartTime and pdt.EndTime > fd.StartTime and pdt.EndTime <=fd.EndTime)or    
      (pdt.StartTime >= fd.StartTime and pdt.StartTime <fd.EndTime and pdt.EndTime > fd.EndTime) or    
      (pdt.StartTime < fd.StartTime and pdt.EndTime > fd.EndTime))    
     )T2 group by Machineid,comp,opn,Starttime,Endtime    
           )T3 inner join #HourlyData on T3.Machineid=#HourlyData.machineid and T3.comp = #HourlyData.comp and T3.opn = #HourlyData.opn and T3.Starttime=#HourlyData.fromtime and T3.Endtime= #HourlyData.totime    
 End    
    
  If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'    
  BEGIN    
   --To apply ML for Hourly Target    
   UPDATE #HourlyData SET  Target=Target-((cast(t4.Mloss as float)/cast(datediff(ss,t4.fromtime,t4.totime) as float))*Target)     
   from    
   (select T3.mc,T3.comp,T3.opn,T3.fromtime,T3.totime,sum(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss from (    
   select   t1.id,T1.mc,T1.comp,T1.opn,T1.fromtime,T1.totime,T1.Threshold,    
   case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0    
   then DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)- isnull(T1.Threshold ,0)    
   else 0 End  as Dloss,    
   case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0    
   then isnull(T1.Threshold,0)    
 else (DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)) End  as Mloss    
    from    
       
   (   select autodata.id,autodata.mc,autodata.comp,autodata.opn,D.threshold,H.fromtime,H.totime,    
    case when autodata.sttime<H.fromtime then H.fromtime else sttime END as sttime,    
          case when ndtime>H.totime then H.totime else ndtime END as ndtime    
    from autodata inner join #HourlyData H on H.mc=autodata.mc and H.comp=autodata.comp and H.opn=autodata.opn    
    inner join downcodeinformation D    
    on autodata.dcode=D.interfaceid where autodata.datatype=2 AND    
    (    
    (autodata.sttime>=H.fromtime  and  autodata.ndtime<=H.totime)    
    OR (autodata.sttime<H.fromtime and  autodata.ndtime>H.fromtime and autodata.ndtime<=H.totime)    
    OR (autodata.sttime>=H.fromtime  and autodata.sttime<H.totime  and autodata.ndtime>H.totime)    
    OR (autodata.sttime<H.fromtime and autodata.ndtime>H.totime )    
    ) AND (D.availeffy = 1)) as T1      
   left outer join    
   (SELECT autodata.id,autodata.mc,autodata.comp,autodata.opn,H.fromtime,H.totime,    
        sum(CASE    
     WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)    
     WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)    
     WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )    
     WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )    
     END ) as PPDT    
    FROM AutoData inner join #HourlyData H on H.mc=autodata.mc and H.comp=autodata.comp and H.opn=autodata.opn    
    inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid    
    cross join #PlannedDownTimes T     
    WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND    
     (    
     (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)    
     OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )    
     OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )    
     OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)    
     )    
     AND (downcodeinformation.availeffy = 1)     
     group  by autodata.id,autodata.mc,autodata.comp,autodata.opn,H.fromtime,H.totime ) as T2 on T1.id=T2.id ) as T3 group by T3.mc,T3.comp,T3.opn,T3.fromtime,T3.totime    
   ) as t4 inner join #HourlyData on T4.mc=#HourlyData.mc and T4.comp = #HourlyData.comp and T4.opn = #HourlyData.opn and T4.fromtime=#HourlyData.fromtime and T4.totime= #HourlyData.totime    
  END    
    
 --Final Output    
 select HourName,FromTime,ToTime,Actual,round(Target,2) as target,case when Actual<target then 'sad' else 'happy' end as remarks from #HourlyData     
 where fromtime<=@currtime order by fromtime    
    
end    
    
If @param = 'Schedule' or @param='operatorlist'    
Begin    
    
 declare @CurStrtTime as datetime      
     DECLARE @empid nvarchar(MAX)      
    
 select @CurStrtTime=''    
 select @CurendTime = ''    
 select @empid =''    
    
 select @CurStrtTime = dateadd(d,-1,dbo.f_GetLogicalDay(@starttime,'start'))    
 select @CurendTime = dateadd(d,1,dbo.f_GetLogicalDay(@starttime,'start'))    
    
 while @CurStrtTime<=@CurendTime    
 Begin    
  INSERT #ShiftTemp(Pdate, ShiftName, FromTime, ToTime)    
  EXEC s_GetShiftTime @CurStrtTime,''    
  select @CurStrtTime = dateadd(d,1,@CurStrtTime)    
 end    
    
    
    
 INSERT #Shiftdetails(Pdate, ShiftName, FromTime, ToTime)    
 select top 1 * from #ShiftTemp where fromtime<@starttime order by fromtime desc    
    
 INSERT #Shiftdetails(Pdate, ShiftName, FromTime, ToTime)    
 select * from #ShiftTemp where fromtime>= @starttime and totime<=@endtime    
    
    
 INSERT #Shiftdetails(Pdate, ShiftName, FromTime, ToTime)    
 select top 1 * from #ShiftTemp where fromtime> @starttime order by fromtime asc    
    
    
    
 If @param='operatorlist'    
 begin    
    
  select @CurStrtTime = min(fromtime) from  #Shiftdetails     
  select @CurendTime = max(totime) from #Shiftdetails     
    
  insert into #oprdetails(Pdate, ShiftName, FromTime, ToTime)    
  select Pdate, ShiftName, FromTime, ToTime from #Shiftdetails order by fromtime     
    
  select @empid=''    
  select  @empid = @empid + T.emp + '/ ' from    
  (select distinct top 3 Ltrim(E.employeeid) as emp from autodata inner join employeeinformation E on autodata.opr=E.interfaceid     
  cross join (select top 1 * from #ShiftTemp where fromtime<@starttime order by fromtime desc)T where sttime>=T.FromTime and ndtime<=T.ToTime)T    
    
  update #oprdetails set operator = @empid where fromtime=(select top 1 fromtime from #ShiftTemp where fromtime<@starttime order by fromtime desc)    
    
    
  select @empid=''    
  select  @empid = @empid + T.emp + '/ ' from    
  (select distinct top 3 Ltrim(E.employeeid) as emp from autodata inner join employeeinformation E on autodata.opr=E.interfaceid     
  cross join (select * from #ShiftTemp where fromtime>= @starttime and totime<=@endtime)T where sttime>=T.FromTime and ndtime<=T.ToTime)T    
    
  update #oprdetails set operator = @empid where fromtime=(select fromtime from #ShiftTemp where fromtime>= @starttime and totime<=@endtime)    
    
    
  select @empid=''    
  select  @empid = @empid + T.emp + '/ ' from    
  (select distinct top 3  Ltrim(E.employeeid) as emp from autodata inner join employeeinformation E on autodata.opr=E.interfaceid     
  cross join (select top 1 * from #ShiftTemp where fromtime> @starttime order by fromtime asc)T where sttime>=T.FromTime and ndtime<=T.ToTime)T    
    
  update #oprdetails set operator = @empid where fromtime=(select top 1 fromtime from #ShiftTemp where fromtime> @starttime order by fromtime asc)    
    
  select convert(nvarchar(5),FromTime,108) AS FromTime, CONVERT(nvarchar(5),ToTime,108) as ToTime,ShiftName, operator from #oprdetails order by convert(nvarchar(20),fromtime,120)    
    
 return    
 end    
    
    
 insert into #Runningpart_Part(mc,comp,opn,suboperation,Machineid,Componentid,operation,shiftdate,shiftstart,shiftend,shiftname,shifttarget,shiftactual)    
 select Machineinformation.interfaceid,C.interfaceid,CO.interfaceid,CO.suboperations,L.machine,L.component,L.operation,S.Pdate,S.fromtime,S.totime,S.shiftname,0,0 from loadschedule L    
 inner join Machineinformation on L.machine=Machineinformation.machineid     
 inner join Componentinformation C on L.component=C.componentid      
 inner join Componentoperationpricing CO on L.operation=CO.operationno      
 and Machineinformation.Machineid=CO.Machineid and C.Componentid=CO.Componentid      
 cross join #Shiftdetails S where L.date = convert(nvarchar(10),S.pdate,112) and L.shift=S.shiftname    
    
    
  --Calculation of PartsCount Begins..    
  UPDATE #Runningpart_Part SET shiftactual = ISNULL(shiftactual,0) + ISNULL(t2.compcount,0)    
  From    
  (        
   Select T1.mc,T1.comp,T1.opn,T1.shiftstart,T1.shiftend,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(T1.SubOperation,1))) As compcount     
       From     
     (    
      select A.mc,A.comp,A.opn,SUM(A.partscount)AS OrginalCount,H.shiftstart,H.shiftend,H.suboperation from autodata A    
      inner join #Runningpart_Part H on H.mc=A.mc and H.comp=A.comp and H.opn=A.opn    
      where (A.ndtime>H.shiftstart) and (A.ndtime<=H.shiftend) and (A.datatype=1)    
      Group By A.mc,A.comp,A.opn,H.shiftstart,H.shiftend,H.suboperation    
     ) as T1    
   GROUP BY T1.mc,T1.comp,T1.opn,T1.shiftstart,T1.shiftend    
  ) As T2 Inner join #Runningpart_Part on T2.mc = #Runningpart_Part.mc and T2.comp = #Runningpart_Part.comp and T2.opn = #Runningpart_Part.opn and T2.shiftstart=#Runningpart_Part.shiftstart and T2.shiftend=#Runningpart_Part.shiftend     
    
  --Mod 4 Apply PDT for calculation of Count    
  If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'    
  BEGIN    
    
    UPDATE #Runningpart_Part SET shiftactual = ISNULL(shiftactual,0) - ISNULL(T2.compcount,0) from    
    (    
     select T1.mc,T1.comp,T1.opn,T1.shiftstart,T1.shiftend,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(T1.SubOperation,1))) as compcount From     
     (     
      select A.mc,Sum(ISNULL(A.PartsCount,1))AS OrginalCount,A.comp,A.opn,H.shiftstart,H.shiftend,H.suboperation from autodata A    
      inner join #Runningpart_Part H on H.mc=A.mc and H.comp=A.comp and H.opn=A.opn    
      CROSS JOIN #PlannedDownTimes T    
      WHERE autodata.DataType=1 And T.MachineInterface = A.mc    
      AND (A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)    
      AND (A.ndtime > H.shiftstart  AND A.ndtime <=H.shiftend)    
      Group by A.mc,A.comp,A.opn,H.shiftstart,H.shiftend,H.suboperation    
     ) as T1    
    GROUP BY T1.mc,T1.comp,T1.opn,T1.shiftstart,T1.shiftend    
    ) as T2 Inner join #Runningpart_Part on T2.mc = #Runningpart_Part.mc and T2.comp = #Runningpart_Part.comp and T2.opn = #Runningpart_Part.opn and T2.shiftstart=#Runningpart_Part.shiftstart and T2.totime=#Runningpart_Part.shiftend     
  END    
    
    
   update #Runningpart_Part set Shifttarget= ISNULL(Shifttarget,0) + ISNULL(T2.tcount,0) from    
 (    
  select shiftstart,shiftend,L.machine,l.component,L.operation as opn,L.idealcount as tcount from loadschedule L    
  Inner join #Runningpart_Part on L.machine = #Runningpart_Part.Machineid and L.component = #Runningpart_Part.componentid and L.Operation = #Runningpart_Part.Operation     
  where date = convert(nvarchar(10),#Runningpart_Part.shiftdate,112) and shift=#Runningpart_Part.shiftname    
  ) as T2 Inner join #Runningpart_Part on T2.machine = #Runningpart_Part.Machineid and T2.component = #Runningpart_Part.componentid and T2.Opn = #Runningpart_Part.Operation     
     and T2.shiftstart = #Runningpart_Part.shiftstart and T2.shiftend = #Runningpart_Part.shiftend     
    
    
 select shiftstart,shiftend,shiftname,Machineid,componentid,operation,shifttarget,shiftactual from #Runningpart_Part order by shiftstart    
    
end    
    
If @param = 'MainSpindleDetails'    
Begin    
    
 select @strsql=''      
 SELECT @strsql= @strsql + 'insert into #Runningpart_Part(Machineid,Componentid,operation)      
    select Top 1 Machineinformation.machineid,A.comp,A.opn from Autodata A      
    inner join Machineinformation on A.mc=Machineinformation.interfaceid      
    inner join Componentinformation C on A.comp=C.interfaceid      
    inner join Componentoperationpricing CO on A.opn=CO.interfaceid      
    and Machineinformation.Machineid=CO.Machineid and C.Componentid=CO.Componentid      
    where sttime>='''+convert(nvarchar(20),@starttime)+''' and ndtime<='''+convert(nvarchar(20),@endtime)+'''   '      
  SELECT @strsql = @strsql + @strmachine      
    SELECT @strsql = @strsql + ' Order by A.sttime desc'    
 print @strsql    
 exec (@strsql)      
    
    
  Select top 6 MachineID, ComponentID, OperationID, ToolNo, ToolActual, ToolTarget,(Tooltarget-ToolActual) as Remaining from Focas_toollife inner join    
 (select Max(CNCtimestamp) as CNCTime from Focas_toollife F    
  inner join #Runningpart_Part R on F.machineid=R.machineid and F.Componentid=R.Componentid and F.operationid=R.operation    
  where CNCTimestamp>=@starttime and CNCTimestamp<=@endtime and Spindletype=1 and F.machineid=@machineid    
  )as T1 on Focas_toollife.CNCtimestamp=T1.CNCTime and Focas_toollife.Spindletype=1 order by ToolActual desc, cast(dbo.SplitAlphanumeric(toolno,'^0-9')as int)    
    
end    
    
If @param = 'SubSpindleDetails'    
Begin    
    
select @strsql=''    
 SELECT @strsql= @strsql + 'insert into #Runningpart_Part(Machineid,Componentid,operation)      
    select Top 1 Machineinformation.machineid,A.comp,A.opn from Autodata A      
    inner join Machineinformation on A.mc=Machineinformation.interfaceid      
    inner join Componentinformation C on A.comp=C.interfaceid      
    inner join Componentoperationpricing CO on A.opn=CO.interfaceid      
    and Machineinformation.Machineid=CO.Machineid and C.Componentid=CO.Componentid      
    where sttime>='''+convert(nvarchar(20),@starttime)+''' and ndtime<='''+convert(nvarchar(20),@endtime)+'''   '      
  SELECT @strsql = @strsql + @strmachine      
    SELECT @strsql = @strsql + ' Order by A.sttime desc'    
 print @strsql    
 exec (@strsql)      
    
  Select top 6 MachineID, ComponentID, OperationID, ToolNo, ToolActual, ToolTarget,(Tooltarget-ToolActual) as Remaining from Focas_toollife inner join    
 (select Max(CNCtimestamp) as CNCTime from Focas_toollife F    
  inner join #Runningpart_Part R on F.machineid=R.machineid and F.Componentid=R.Componentid and F.operationid=R.operation    
  where CNCTimestamp>=@starttime and CNCTimestamp<=@endtime and Spindletype=2 and F.machineid=@machineid    
  )as T1 on Focas_toollife.CNCtimestamp=T1.CNCTime and Focas_toollife.Spindletype=2 order by ToolActual desc, cast(dbo.SplitAlphanumeric(toolno,'^0-9')as int)    
end    
    
If @param = 'CoolantLubOilLevel'    
Begin    
    
 declare @ColLevel as int    
 declare @LubLevel as int   
 declare @CoolentLevel as int  
 declare @LubOilLevel as int   
 select @ColLevel = isnull(valueinint,0) from shopdefaults where parameter='CoolantLifeRemaining'    
 select @LubLevel = isnull(valueinint,0) from shopdefaults where parameter='LubricantLifeRemaining'    
 select @CoolentLevel = isnull(valueinint,0) from shopdefaults where parameter='CoolentTankCapacityInLitres'    
 select  @LubOilLevel = isnull(valueinint,0) from shopdefaults where parameter='LubOilTankCapacityInLitres'  
     
    --select top 1 ((CoolentLevel/4095.0 ) * 100.0)as CoolentLevel, LubOilLevel , (CoolentLevel/70)*@ColLevel as TimeRemainingHrscoolant,(LubOilLevel/70)*@LubLevel as TimeRemainingHrsLubricant from dbo.Focas_CoolentLubOilInfo where MachineId = @Machineid
  
    
    --order by id desc       
  select top 1 ((CoolentLevel/4095.0) * 100.0)as CoolentLevel,     
                 ((LubOilLevel/4095.0) * 100.0) as LubOilLevel ,     
                 ((((CoolentLevel/4095.0) * 100.0)/100.0))*@ColLevel as TimeRemainingHrscoolant,     
                 (((LubOilLevel/4095.0) * 100.0)/100.0)*@LubLevel as TimeRemainingHrsLubricant,  
     ((CoolentLevel/4095.0) * @CoolentLevel) as CoolentLevelInLitres,  
      ((LubOilLevel/4095.0) * @LubOilLevel) as LubOilLevelInLitres  
    from dbo.Focas_CoolentLubOilInfo where MachineId = @Machineid    
    order by id desc       
end    
    
end    
