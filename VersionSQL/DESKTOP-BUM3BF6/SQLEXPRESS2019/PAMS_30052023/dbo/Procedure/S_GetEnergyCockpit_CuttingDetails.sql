/****** Object:  Procedure [dbo].[S_GetEnergyCockpit_CuttingDetails]    Committed by VersionSQL https://www.versionsql.com ******/

      
/**************************************************************************************************************      
NR0081 - GeetanjaliK - 2012-Nov-12 :: Created New proc.To show Machinewise Utilised time,Components,Cutting time Details,PF,Cost and Energy      
at Shift,Day and Time consolidated  Levels.      
ER0375 - SwathiKS - 2014-Feb-17 :: To enable open time period for daywise and shiftwise options.      
ER0383 - SwathiKS - 29/May/2014 :: Performance Optimization.      
a> Altered queries for ICD and Components Calculation.      
b> Introduced WITH(NOLOCK) for Autodata and tcs_energyconsumption tables.      
DR0359 - satya - 18-March-2015 :: Getting negative value for KWH because of missing machine join      
ER0419 - SwathiKS - 30/Oct/2015 :: a> To enable TimeConsolidated Option for OpentimePeriod.      
B> Added V1,V2,V3 in Ouput specific to Techno.      
c> To handle Negative kwh values.      
ER0454 - swathiKS - 10/Oct/2017 :: To Introduce Component and Operation For Techno.
ER0502:SwathiKS:12/Mar/2021::To Use EM_MachineInformation instead of Machineinformation.
Going forward we will store Machines in EM_MachineInformation Table which are enabled for Energy Data Collection instead of Machineinformation. 
To Assign Machines To Plant Use EM_PlantMachine instead of PlantMachine Table. 
Machines which are Enabled For OEE & Energy both, Should be stored in both the tables with same Machineid & interfaceid.  
Enery Related Info we can get From EM_Machineinformation and tcs_EnergyConsumption Tables
OEE Related Info from Mahcineinformation and Autodata Tables.

S_GetEnergyCockpit_CuttingDetails '2017-09-11 08:00:00','2017-09-11 18:00:00','','''TC-02''','','Shift','Machine EM'    
S_GetEnergyCockpit_CuttingDetails '2017-09-22 08:00:00','2017-09-22 18:00:00','','''TC-03''','','day'    
S_GetEnergyCockpit_CuttingDetails '2017-09-20 08:00:00','2017-09-22 18:00:00','','','','Shift'    
S_GetEnergyCockpit_CuttingDetails '2017-09-20 08:00:00','2017-09-22 18:00:00','','','','day'    

exec S_GetEnergyCockpit_CuttingDetails @Param=N'Shift',@Startdate=N'2021-08-04',@Enddate=N'2021-08-04',@MachineId=N'',@PlantId=N'',@Shift=N'',@MachineType=N'Machine EM'
***************************************************************************************************************/      
      
CREATE procedure [dbo].[S_GetEnergyCockpit_CuttingDetails]      
@Startdate  datetime,      
@Enddate datetime,      
@Plantid nvarchar(100)='',      
@Machineid  nvarchar(2000)='',      
@Shift  nvarchar(50)='',      
@Param nvarchar(50)='', --Shift,Day,Time Consolidated      
@MachineType nvarchar(50) ='',
@IsChecked int=0
      
with recompile --ER0383      
As Begin      
      
      
declare @sql nvarchar(4000) --geeta added      
      
Create table #Finaldata      
(      
 MachineID NvarChar(50),      
 MachineInterface nvarchar(100),      
 Shift nvarchar(50),      
 StartTime DateTime,      
 EndTime DateTime,      
 UtilisedTime nvarchar(100),      
 Cutting_Time nvarchar(100),      
 components int,      
 PF float,      
 Cost float,      
 Energy float,      
 Minenergy float,      
 Maxenergy float,      
--ER0419 From here      
 MinVolt1 float,      
 MinVolt2 float,       
 MinVolt3 float, 
 MinVolt4 float,
 MinVolt5 float,
 MinVolt6 float,
 MaxVolt1 float,       
 MaxVolt2 float,       
 MaxVolt3 float,
 MaxVolt4 float,
 MaxVolt5 float,
 MaxVolt6 float,
--ER0419 Till here     
 CompOpn nvarchar(max) ,
 Ampere1 float,
 Ampere2 float,
 Ampere3 float,
 KWHPerComponent float default 0,
 KVA FLOAT DEFAULT 0
)      
      
create Table #Energydata      
(      
Machineid nvarchar(50),      
Col1_ID int,      
Col2_ID int,      
Col1_gtime Datetime,      
Col2_gtime Datetime,      
st datetime,      
nd datetime,      
Col1_Amp float,      
Col2_Amp float,      
Col1_COl2 float      
)      
      
create table #temp      
(      
Machine nvarchar(50),      
starttime datetime,      
Endtime datetime,      
Cuttingdetail float,      
TotalCuttingTime float      
)      
      
Create table #GetShiftTime      
(      
dDate DateTime,      
ShiftName NVarChar(50),      
StartTime DateTime,      
EndTime DateTime      
)      
      
      
      
--ER0375 From Here      
Create table #day      
(      
 Starttime datetime,      
 Endtime datetime      
)      
declare @curstart as datetime      
declare @curend as datetime      
declare @Cuttime_Start as datetime      
declare @Cuttime_End as datetime      
Select @curstart = @Startdate      
Select @curend = @Enddate      
--ER0375 Till here      
      
declare @strsql as nvarchar(4000)      
declare @Plantname as nvarchar(100)      
declare @MachineName as nvarchar(2500)      
declare @Start as datetime      
declare @End as datetime      
declare @Mach as nvarchar(400)      
declare @shiftname1 as nvarchar(50)      

      
If isnull(@Param,'')='Shift'      
begin      
      
 --ER0375  From here      
 while @curstart <= @curend      
 Begin       
  insert into #GetShiftTime Exec s_GetShiftTime @curstart,@Shift      
  Select @curstart = Dateadd(d,1,@curstart)      
 End      
      
 Select @Cuttime_Start=min(StartTime) from #GetShiftTime      
 Select @Cuttime_End=max(EndTime) from #GetShiftTime      
 --ER0375 Tll Here      
 
-- insert into #GetShiftTime Exec s_GetShiftTime @Startdate,@Shift --ER0375      
-- select @Start = min(StartTime) from #GetShiftTime  --ER0375      
-- select @End = max(EndTime) from #GetShiftTime  --ER0375      
End      
      
if isnull(@Param,'')='Day'      
begin      
--ER0375 From here      
-- select @Start=dbo.f_GetLogicalDay(convert(nvarchar,@Startdate,101),'start')      
-- select @End=dbo.f_GetLogicalDay(convert(nvarchar,@Startdate,101),'end')      
       
 While @curstart<=@curend      
 BEGIN      
  Insert into #Day ( Starttime,Endtime)      
  select dbo.f_GetLogicalDay(convert(nvarchar,@curstart,101),'start'), dbo.f_GetLogicalDay(convert(nvarchar,@curstart,101),'end')      
  SELECT @curstart=DATEADD(DAY,1,@curstart)      
 END      
      
      
 Select @Cuttime_Start=min(StartTime) from #Day      
 Select @Cuttime_End=max(EndTime) from #Day      
--ER0375 Till here      
end      
      
      
if isnull(@Param,'')='Time Consolidated'      
begin      
--ER0419 Commented From Here      
-- select @Start=dbo.f_GetLogicalDay(convert(nvarchar,@Startdate,101),'start')      
-- select @End=dbo.f_GetLogicalDay(convert(nvarchar,@Enddate,101),'end')      
--      
-- --ER0375      
-- Select @Cuttime_Start=@Start      
-- Select @Cuttime_End=@End      
-- --ER0375      
--ER0419 Commented Till Here      
      
--ER0419 Added From Here      
      
 select @Start=convert(nvarchar(20),@Startdate,120)      
 select @End=convert(nvarchar(20),@Enddate,120)      
      
 Select @Cuttime_Start=@Start      
 Select @Cuttime_End=@End      
--ER0419 Added Till Here      
      
end      
      
If isnull(@Plantid,'')<>''      
begin      
 set @Plantname=' AND EM_PlantMachine.Plantid=N'''+@Plantid+''''      
 print @Plantname      
end      
      
if isnull(@Machineid,'')<>''      
begin      
 --select @MachineName=' AND Machineinformation.MachineId=N'''+@Machineid+'''' -- geeta commented      
    select @MachineName=' AND EM_Machineinformation.MachineId in ('+@Machineid+')' -- geeta added      
end       

If isnull(@Param,'')='Shift'      
Begin      
 set @strsql=''      
 SET @strsql = @strsql + 'insert into #Finaldata(#Finaldata.MachineID,#Finaldata.MachineInterface,UtilisedTime,Cutting_Time,components,PF,Cost,      
 Energy,Minenergy,Maxenergy,#Finaldata.StartTime,#Finaldata.EndTime,#Finaldata.Shift      
 ) SELECT EM_Machineinformation.MachineID, EM_Machineinformation.interfaceid,0,0,0,0,0,0,0,0,#GetShiftTime.starttime,#GetShiftTime.Endtime,#GetShiftTime.ShiftName FROM #GetShiftTime cross join EM_Machineinformation      
   inner JOIN EM_PlantMachine ON EM_Machineinformation.machineid = EM_PlantMachine.MachineID  WHERE  EM_Machineinformation.MachineType = ''' + @MachineType+ ''' and EM_Machineinformation.interfaceid > ''0''' 
   --and  EM_Machineinformation.devicetype=''5'' '      
 If @Plantname<>'' and  @MachineName<>''      
 begin      
  SET @strsql =  @strsql + @Plantname + @MachineName      
 end      
      
 If @Plantname<>''      
 begin      
  SET @strsql =  @strsql + @Plantname      
 end      
      
 If  @MachineName<>''      
 begin      
  SET @strsql =  @strsql  + @MachineName      
 end      


EXEC(@strsql)      
      
End      
      
--ER0375 From here      
If isnull(@Param,'')='Day'      
Begin      
 set @strsql=''      
 SET @strsql = @strsql + 'insert into #Finaldata(#Finaldata.MachineID,#Finaldata.MachineInterface,UtilisedTime,Cutting_Time,components,PF,Cost,      
 Energy,Minenergy,Maxenergy,#Finaldata.StartTime,#Finaldata.EndTime,#Finaldata.Shift      
 ) SELECT EM_Machineinformation.MachineID, EM_Machineinformation.interfaceid,0,0,0,0,0,0,0,0,#Day.starttime,#Day.Endtime,''ALL'' FROM #Day cross join EM_Machineinformation      
   inner JOIN EM_PlantMachine ON EM_Machineinformation.machineid = EM_PlantMachine.MachineID WHERE EM_Machineinformation.MachineType = ''' + @MachineType+''' and EM_Machineinformation.interfaceid > ''0'' '
   --and  MachineInformation.devicetype=''5'' '      
 If @Plantname<>'' and  @MachineName<>''      
 begin      
  SET @strsql =  @strsql + @Plantname + @MachineName      
 end      
      
 If @Plantname<>''      
 begin      
  SET @strsql =  @strsql + @Plantname      
 end      
      
 If  @MachineName<>''      
 begin      
  SET @strsql =  @strsql  + @MachineName      
 end      

 EXEC(@strsql)      
End      
--ER0375 Till Here      
      
--ELSE --ER0375 Commented      
If isnull(@Param,'')='Time Consolidated' --ER0375 Added Line      
begin      
 set @strsql=''      
 SET @strsql = @strsql + 'insert into #Finaldata(#Finaldata.MachineID,#Finaldata.MachineInterface,UtilisedTime,Cutting_Time,components,PF,Cost,Energy,Minenergy,Maxenergy,#Finaldata.Shift      
 ) SELECT EM_Machineinformation.MachineID, EM_Machineinformation.interfaceid,0,0,0,0,0,0,0,0,''All'' FROM EM_Machineinformation      
       inner JOIN EM_PlantMachine ON EM_Machineinformation.machineid = EM_PlantMachine.MachineID  WHERE EM_Machineinformation.MachineType =  ''' + @MachineType+''' and EM_Machineinformation.interfaceid > ''0'' '
	   --and  MachineInformation.devicetype=''5'' '      
 If @Plantname<>'' and  @MachineName<>''      
 begin      
  SET @strsql =  @strsql + @Plantname + @MachineName      
 end      
 If @Plantname<>''      
 begin      
  SET @strsql =  @strsql + @Plantname      
 end      
 If  @MachineName<>''      
 begin      
  SET @strsql =  @strsql  + @MachineName      
 end    

 EXEC(@strsql)      
      
 UPDATE #FinalData SET #Finaldata.StartTime=@start      
 UPDATE #FinalData SET #Finaldata.EndTime=@End      
End      

--ER0383 From Here      
declare @Noofdyasdiff as integer      
select @Noofdyasdiff = isnull(datediff(d,min(starttime),Max(endtime)),0) from #FinalData      
--If @Noofdyasdiff <= 2       
--begin      
      
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
   [PartsCount] [int] NULL ,      
   id  bigint not null      
  )      
      
  ALTER TABLE #T_autodata      
      
  ADD PRIMARY KEY CLUSTERED      
  (      
   mc,sttime,ndtime,msttime ASC      
  )ON [PRIMARY]      
      
      
  Declare @T_ST AS Datetime       
  Declare @T_ED AS Datetime       
      
  select @strsql = ''      
  Select @T_ST=min(StartTime) from #FinalData      
  Select @T_ED=max(EndTime)from #FinalData      



  select * into #tcs from tcs_energyconsumption where (gtime>=@T_ST and gtime<=@T_ED)
      
  Select @strsql=''      
  select @strsql ='insert into #T_autodata '      
  select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'      
   select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'      
  select @strsql = @strsql + ' from autodata WITH(NOLOCK) where (( sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_ED,120)+''' ) OR ' ---SV      
  select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' )OR '      
  select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ST,120)+'''      
       and ndtime<='''+convert(nvarchar(25),@T_ED,120)+''' )'      
  select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' and sttime<'''+convert(nvarchar(25),@T_ED,120)+''' ) )'      
  print @strsql      
  exec (@strsql)      
      
  --Type1      
  UPDATE #FinalData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t1.cycle,0) from(      
   select mc,#FinalData.StartTime,#FinalData.EndTime,sum(cycletime+loadunload) as cycle      
   from #T_autodata autodata WITH(NOLOCK) inner join #FinalData on autodata.mc = #FinalData.machineinterface --ER0383      
   where (autodata.msttime>=#FinalData.StartTime) and (autodata.ndtime<=#FinalData.EndTime)and (autodata.datatype=1)      
   group by autodata.mc,#FinalData.StartTime,#FinalData.EndTime      
  ) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime      
      
  -- Type 2      
  UPDATE #FinalData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t1.cycle,0) from(      
   select mc,#FinalData.StartTime,#FinalData.EndTime,sum(DateDiff(second, #FinalData.StartTime, ndtime)) as cycle      
   from #T_autodata autodata WITH(NOLOCK) inner join #FinalData on autodata.mc = #FinalData.machineinterface --ER0383      
   where (autodata.msttime<#FinalData.StartTime) and (autodata.ndtime>#FinalData.StartTime) and (autodata.ndtime<=#FinalData.EndTime) and (autodata.datatype=1)      
   group by autodata.mc,#FinalData.StartTime,#FinalData.EndTime      
  ) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime      
      
  -- Type 3      
  UPDATE #FinalData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t1.cycle,0) from(      
   select mc,#FinalData.StartTime,#FinalData.EndTime,sum(DateDiff(second, mstTime, #FinalData.EndTime)) as cycle      
   from #T_autodata autodata WITH(NOLOCK) inner join #FinalData on autodata.mc = #FinalData.machineinterface --ER0383      
   where (autodata.msttime>=#FinalData.StartTime) and (autodata.msttime<#FinalData.EndTime) and (autodata.ndtime>#FinalData.EndTime) and (autodata.datatype=1)      
   group by autodata.mc,#FinalData.StartTime,#FinalData.EndTime      
  ) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime      
      
  -- Type 4      
  UPDATE #FinalData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t1.cycle,0) from(      
   select mc,#FinalData.StartTime,#FinalData.EndTime,sum(DateDiff(second, #FinalData.StartTime, #FinalData.EndTime)) as cycle      
   from #T_autodata autodata WITH(NOLOCK)inner join #FinalData on autodata.mc = #FinalData.machineinterface --ER0383      
   where (autodata.msttime<#FinalData.StartTime) and (autodata.ndtime>#FinalData.EndTime) and (autodata.datatype=1)      
   group by autodata.mc,#FinalData.StartTime,#FinalData.EndTime      
  ) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime      
      
       
   ----/* Fetching Down Records from Production Cycle  */      
   ----/* If Down Records of TYPE-2*/      
    UPDATE  #FinalData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)      
    FROM (Select AutoData.mc ,T1.StartTime,T1.EndTime,      
    SUM(CASE      
     When autodata.sttime <= T1.StartTime Then datediff(s, T1.StartTime,autodata.ndtime )      
     When autodata.sttime > T1.StartTime Then datediff(s , autodata.sttime,autodata.ndtime)      
     END) as Down      
    From #T_autodata AutoData WITH(NOLOCK) INNER Join --ER0383      
     (Select mc,Sttime,NdTime,#FinalData.StartTime as StartTime,#FinalData.EndTime as EndTime From #T_autodata AutoData WITH(NOLOCK) --ER0383      
      inner join #FinalData on AutoData.mc = #FinalData.machineinterface      
      Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And      
      (msttime < #FinalData.StartTime)And (ndtime > #FinalData.StartTime) AND (ndtime <= #FinalData.EndTime)      
     ) as T1 ON AutoData.mc=T1.mc      
    Where AutoData.DataType=2      
    And ( autodata.Sttime > T1.Sttime )      
    And ( autodata.ndtime <  T1.ndtime )      
    AND ( autodata.ndtime >  T1.StartTime )      
    GROUP BY AUTODATA.mc,T1.StartTime,T1.EndTime)AS T2 inner join #FinalData on t2.mc = #FinalData.machineinterface       
    and T2.StartTime = #FinalData.StartTime and T2.EndTime = #FinalData.EndTime      
      
    /* If Down Records of TYPE-3*/      
    UPDATE  #FinalData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)      
    FROM(Select AutoData.mc,T1.StartTime,T1.EndTime,      
    SUM(CASE      
     When autodata.ndtime > T1.EndTime Then datediff(s,autodata.sttime, T1.EndTime )      
     When autodata.ndtime <=T1.EndTime Then datediff(s , autodata.sttime,autodata.ndtime)      
    END) as Down      
    From #T_autodata AutoData WITH(NOLOCK) INNER Join --ER0383      
     ( Select mc,Sttime,NdTime,#FinalData.StartTime as StartTime,#FinalData.EndTime as EndTime From #T_autodata AutoData WITH(NOLOCK) --ER0383      
      inner join #FinalData on AutoData.mc = #FinalData.machineinterface      
      Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And      
      (sttime >= #FinalData.StartTime)And (ndtime > #FinalData.EndTime) and (sttime<#FinalData.EndTime)       
     ) as T1 ON AutoData.mc=T1.mc      
    Where AutoData.DataType=2      
    And (T1.Sttime < autodata.sttime  )      
    And ( T1.ndtime >  autodata.ndtime)      
    AND (autodata.sttime  < T1.EndTime)      
    GROUP BY AUTODATA.mc,T1.StartTime,T1.EndTime)AS T2 inner join #FinalData on T2.mc = #FinalData.machineinterface       
    and T2.StartTime = #FinalData.StartTime and T2.EndTime = #FinalData.EndTime      
       
    /* If Down Records of TYPE-4*/      
    UPDATE  #FinalData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)      
    FROM      
    (Select AutoData.mc,T1.StartTime,T1.EndTime,      
    SUM(CASE      
     When autodata.sttime >= T1.StartTime AND autodata.ndtime <= T1.EndTime Then datediff(s , autodata.sttime,autodata.ndtime)      
     When autodata.sttime < T1.StartTime AND autodata.ndtime > T1.StartTime AND autodata.ndtime<=T1.EndTime Then datediff(s, T1.StartTime,autodata.ndtime )      
     When autodata.sttime>=T1.StartTime And autodata.sttime < T1.EndTime AND autodata.ndtime > T1.EndTime Then datediff(s,autodata.sttime, T1.EndTime )      
     When autodata.sttime<T1.StartTime AND autodata.ndtime>T1.EndTime   Then datediff(s , T1.StartTime,T1.EndTime)      
    END) as Down      
    From #T_autodata AutoData WITH(NOLOCK) INNER Join --ER0383      
     (Select mc,Sttime,NdTime,#FinalData.StartTime as StartTime,#FinalData.EndTime as EndTime From #T_autodata AutoData   WITH(NOLOCK) --ER0383      
      inner join #FinalData on AutoData.mc = #FinalData.machineinterface      
      Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And      
      (msttime < #FinalData.StartTime)And (ndtime > #FinalData.EndTime)       
     ) as T1 ON AutoData.mc=T1.mc      
    Where AutoData.DataType=2      
    And (T1.Sttime < autodata.sttime  )      
    And ( T1.ndtime >  autodata.ndtime)      
    AND (autodata.ndtime> T1.StartTime)      
    AND (autodata.sttime< T1.EndTime)      
    GROUP BY AUTODATA.mc,T1.StartTime,T1.EndTime      
    )AS T2 inner join #FinalData on T2.mc = #FinalData.machineinterface and T2.StartTime = #FinalData.StartTime and T2.EndTime = #FinalData.EndTime      
      
      
   --Calculation of PartsCount Begins..      
   UPDATE #FinalData SET components = ISNULL(components,0) + ISNULL(t2.comp,0)      
   From(      
    Select mc,T1.StartTime,T1.EndTime,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp From       
      (      
         select mc,SUM(autodata.partscount)AS OrginalCount,comp,opn,#FinalData.StartTime,#FinalData.EndTime from #T_autodata autodata WITH(NOLOCK) --ER0383      
         inner join #FinalData on autodata.mc = #FinalData.machineinterface      
         where (autodata.ndtime>#FinalData.StartTime) and (autodata.ndtime<=#FinalData.EndTime) and (autodata.datatype=1)      
         Group By mc,comp,opn,#FinalData.StartTime,#FinalData.EndTime      
      ) as T1      
    inner join machineinformation on machineinformation.interfaceid =T1.mc      
    Inner join componentinformation C on T1.Comp = C.interfaceid      
    Inner join ComponentOperationPricing O ON  T1.Opn = O.interfaceid and C.Componentid=O.componentid      
    and machineinformation.machineid=o.machineid      
    GROUP BY mc,T1.StartTime,T1.EndTime      
   ) As T2 Inner join #FinalData on T2.mc = #FinalData.machineinterface and T2.StartTime = #FinalData.StartTime and T2.EndTime = #FinalData.EndTime      
--end      
--ER0383 till Here      
      
--ER0383 From Here      
--else        
--Begin      
--   -- Type 1      
--   UPDATE #FinalData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t1.cycle,0) from(      
--    select mc,#FinalData.StartTime,#FinalData.EndTime,sum(cycletime+loadunload) as cycle      
--    from #T_autodata autodata WITH(NOLOCK) inner join #FinalData on autodata.mc = #FinalData.machineinterface      
--    where (autodata.msttime>=#FinalData.StartTime) and (autodata.ndtime<=#FinalData.EndTime)and (autodata.datatype=1)      
--    group by autodata.mc,#FinalData.StartTime,#FinalData.EndTime      
--   ) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime      
      
--   -- Type 2      
--   UPDATE #FinalData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t1.cycle,0) from(      
--    select mc,#FinalData.StartTime,#FinalData.EndTime,sum(DateDiff(second, #FinalData.StartTime, ndtime)) as cycle      
--    from #T_autodata autodata WITH(NOLOCK) inner join #FinalData on autodata.mc = #FinalData.machineinterface      
--    where (autodata.msttime<#FinalData.StartTime) and (autodata.ndtime>#FinalData.StartTime) and (autodata.ndtime<=#FinalData.EndTime) and (autodata.datatype=1)      
--    group by autodata.mc,#FinalData.StartTime,#FinalData.EndTime      
--   ) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime      
      
--   -- Type 3      
--   UPDATE #FinalData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t1.cycle,0) from(      
--    select mc,#FinalData.StartTime,#FinalData.EndTime,sum(DateDiff(second, mstTime, #FinalData.EndTime)) as cycle      
--    from #T_autodata autodata WITH(NOLOCK) inner join #FinalData on autodata.mc = #FinalData.machineinterface      
--    where (autodata.msttime>=#FinalData.StartTime) and (autodata.msttime<#FinalData.EndTime) and (autodata.ndtime>#FinalData.EndTime) and (autodata.datatype=1)      
--    group by autodata.mc,#FinalData.StartTime,#FinalData.EndTime      
--   ) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime      
      
--   -- Type 4      
--   UPDATE #FinalData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t1.cycle,0) from(      
--    select mc,#FinalData.StartTime,#FinalData.EndTime,sum(DateDiff(second, #FinalData.StartTime, #FinalData.EndTime)) as cycle      
--    from autodata WITH(NOLOCK) inner join #FinalData on autodata.mc = #FinalData.machineinterface      
--    where (autodata.msttime<#FinalData.StartTime) and (autodata.ndtime>#FinalData.EndTime) and (autodata.datatype=1)      
--    group by autodata.mc,#FinalData.StartTime,#FinalData.EndTime      
--   ) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime      
      
--/*      
      
--   ----/* Fetching Down Records from Production Cycle  */      
--   ----/* If Down Records of TYPE-2*/      
--   UPDATE #FinalData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t1.Down,0) from(      
--    select A1.mc,#FinalData.StartTime,#FinalData.EndTime,      
--    case      
--     When A2.sttime >= #FinalData.StartTime AND A2.ndtime <= #FinalData.EndTime Then datediff(s, A2.sttime,A2.ndtime)      
--     When A2.sttime < #FinalData.StartTime And A2.ndtime > #FinalData.StartTime AND A2.ndtime<=#FinalData.EndTime Then datediff(s, #FinalData.StartTime,A2.ndtime )      
--    end as Down      
--    from autodata A1 cross join autodata A2 cross join #FinalData      
--    where A1.datatype = 1 and A2.datatype = 2      
--    and A1.mc = #FinalData.machineinterface and A1.mc = A2.mc      
--    and A2.sttime > A1.sttime and A2.ndtime < A1.ndtime      
--    and A1.sttime < #FinalData.StartTime      
--    and A1.ndtime > #FinalData.StartTime      
--    and A1.ndtime <= #FinalData.EndTime      
--    and DateDiff(Second,A1.sttime,A1.ndtime)>A1.CycleTime      
--   ) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime      
      
--   ----/* If Down Records of TYPE-3*/      
--   UPDATE #FinalData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t1.Down,0) from(      
--    select A1.mc,#FinalData.StartTime,#FinalData.EndTime,      
--    case      
--     When A2.sttime >= #FinalData.StartTime AND A2.ndtime <= #FinalData.EndTime Then datediff(s, A2.sttime,A2.ndtime)      
--     When A2.sttime>=#FinalData.StartTime And A2.sttime < #FinalData.EndTime and A2.ndtime > #FinalData.EndTime Then datediff(s,A2.sttime, #FinalData.EndTime )      
--    end as Down      
--    from autodata A1 cross join autodata A2 cross join #FinalData      
--    where A1.datatype = 1 and A2.datatype = 2      
--    and A1.mc = #FinalData.machineinterface and A1.mc = A2.mc      
--    and A2.sttime > A1.sttime and A2.ndtime < A1.ndtime      
--    and A1.sttime >= #FinalData.StartTime      
--    and A1.sttime < #FinalData.EndTime      
--    and A1.ndtime > #FinalData.EndTime      
--    and DateDiff(Second,A1.sttime,A1.ndtime)>A1.CycleTime      
--   ) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime      
      
--   ----/* If Down Records of TYPE-4*/      
--   UPDATE #FinalData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t1.Down,0) from(      
--    select A1.mc,#FinalData.StartTime,#FinalData.EndTime,      
--    case      
--     When A2.sttime >= #FinalData.StartTime AND A2.ndtime <= #FinalData.EndTime Then datediff(s, A2.sttime,A2.ndtime)      
--     When A2.sttime < #FinalData.StartTime And A2.ndtime > #FinalData.StartTime AND A2.ndtime<=#FinalData.EndTime Then datediff(s, #FinalData.StartTime,A2.ndtime )      
--     When A2.sttime>=#FinalData.StartTime And A2.sttime < #FinalData.EndTime and A2.ndtime > #FinalData.EndTime Then datediff(s,A2.sttime, #FinalData.EndTime )      
--     When A2.sttime<#FinalData.StartTime AND A2.ndtime>#FinalData.EndTime   Then datediff(s, #FinalData.StartTime,#FinalData.EndTime)      
--    end as Down      
--    from autodata A1 cross join autodata A2 cross join #FinalData      
--    where A1.datatype = 1 and A2.datatype = 2      
--    and A1.mc = #FinalData.machineinterface and A1.mc = A2.mc      
--    and A2.sttime > A1.sttime and A2.ndtime < A1.ndtime      
--    and A1.sttime < #FinalData.StartTime      
--    and A1.ndtime > #FinalData.EndTime      
--    and DateDiff(Second,A1.sttime,A1.ndtime)>A1.CycleTime      
--   ) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime      
      
      
--   UPDATE #FinalData SET components = ISNULL(components,0) + ISNULL(t2.comp,0)From(      
--    select Autodata.mc,#FinalData.StartTime,#FinalData.EndTime,      
--    SUM(CEILING(CAST(autodata.partscount AS Float)/ISNULL(O.SubOperations,1))) as comp      
--    from autodata      
--    inner join #FinalData on autodata.mc = #FinalData.machineinterface      
--    Inner join componentinformation C on autodata.Comp = C.interfaceid      
--    Inner join ComponentOperationPricing O ON  autodata.Opn = O.interfaceid and C.Componentid=O.componentid      
--    inner join machineinformation on machineinformation.machineid =O.machineid and autodata.mc=machineinformation.interfaceid      
--    Where Autodata.datatype = 1      
--    and Autodata.ndtime > #FinalData.StartTime and Autodata.ndtime <= #FinalData.EndTime      
--    Group by Autodata.mc,#FinalData.StartTime,#FinalData.EndTime      
--   ) As T2 Inner join #FinalData on T2.mc = #FinalData.machineinterface and T2.StartTime = #FinalData.StartTime and T2.EndTime = #FinalData.EndTime      
      
--*/      
      
--   ----/* Fetching Down Records from Production Cycle  */      
--   ----/* If Down Records of TYPE-2*/      
--    UPDATE  #FinalData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)      
--    FROM (Select AutoData.mc ,T1.StartTime,T1.EndTime,      
--    SUM(CASE      
--     When autodata.sttime <= T1.StartTime Then datediff(s, T1.StartTime,autodata.ndtime )      
--     When autodata.sttime > T1.StartTime Then datediff(s , autodata.sttime,autodata.ndtime)      
--     END) as Down      
--    From #T_autodata AutoData WITH(NOLOCK) INNER Join      
--     (Select mc,Sttime,NdTime,#FinalData.StartTime as StartTime,#FinalData.EndTime as EndTime From #T_autodata AutoData WITH(NOLOCK)      
--      inner join #FinalData on AutoData.mc = #FinalData.machineinterface      
--      Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And      
--      (msttime < #FinalData.StartTime)And (ndtime > #FinalData.StartTime) AND (ndtime <= #FinalData.EndTime)      
--     ) as T1 ON AutoData.mc=T1.mc      
--    Where AutoData.DataType=2      
--    And ( autodata.Sttime > T1.Sttime )      
--    And ( autodata.ndtime <  T1.ndtime )      
--    AND ( autodata.ndtime >  T1.StartTime )      
--    GROUP BY AUTODATA.mc,T1.StartTime,T1.EndTime)AS T2 inner join #FinalData on t2.mc = #FinalData.machineinterface       
--    and T2.StartTime = #FinalData.StartTime and T2.EndTime = #FinalData.EndTime      
      
--    /* If Down Records of TYPE-3*/      
--    UPDATE  #FinalData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)      
--    FROM(Select AutoData.mc,T1.StartTime,T1.EndTime,      
--    SUM(CASE      
--     When autodata.ndtime > T1.EndTime Then datediff(s,autodata.sttime, T1.EndTime )      
--     When autodata.ndtime <=T1.EndTime Then datediff(s , autodata.sttime,autodata.ndtime)      
--    END) as Down      
--    From #T_autodata AutoData WITH(NOLOCK) INNER Join      
--     ( Select mc,Sttime,NdTime,#FinalData.StartTime as StartTime,#FinalData.EndTime as EndTime From #T_autodata AutoData WITH(NOLOCK)      
--      inner join #FinalData on AutoData.mc = #FinalData.machineinterface      
--      Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And      
--      (sttime >= #FinalData.StartTime)And (ndtime > #FinalData.EndTime) and (sttime<#FinalData.EndTime)       
--     ) as T1 ON AutoData.mc=T1.mc      
--    Where AutoData.DataType=2      
--    And (T1.Sttime < autodata.sttime  )      
--    And ( T1.ndtime >  autodata.ndtime)      
--    AND (autodata.sttime  < T1.EndTime)      
--    GROUP BY AUTODATA.mc,T1.StartTime,T1.EndTime)AS T2 inner join #FinalData on T2.mc = #FinalData.machineinterface       
--    and T2.StartTime = #FinalData.StartTime and T2.EndTime = #FinalData.EndTime      
       
--    /* If Down Records of TYPE-4*/      
--    UPDATE  #FinalData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)      
--    FROM      
--    (Select AutoData.mc,T1.StartTime,T1.EndTime,      
--    SUM(CASE      
--     When autodata.sttime >= T1.StartTime AND autodata.ndtime <= T1.EndTime Then datediff(s , autodata.sttime,autodata.ndtime)      
--     When autodata.sttime < T1.StartTime AND autodata.ndtime > T1.StartTime AND autodata.ndtime<=T1.EndTime Then datediff(s, T1.StartTime,autodata.ndtime )      
--     When autodata.sttime>=T1.StartTime And autodata.sttime < T1.EndTime AND autodata.ndtime > T1.EndTime Then datediff(s,autodata.sttime, T1.EndTime )      
--     When autodata.sttime<T1.StartTime AND autodata.ndtime>T1.EndTime   Then datediff(s , T1.StartTime,T1.EndTime)      
--    END) as Down      
--    From #T_autodata AutoData WITH(NOLOCK) INNER Join      
--     (Select mc,Sttime,NdTime,#FinalData.StartTime as StartTime,#FinalData.EndTime as EndTime From #T_autodata AutoData  WITH(NOLOCK)      
--      inner join #FinalData on AutoData.mc = #FinalData.machineinterface      
--      Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And      
--      (msttime < #FinalData.StartTime)And (ndtime > #FinalData.EndTime)       
--     ) as T1 ON AutoData.mc=T1.mc      
--    Where AutoData.DataType=2      
--    And (T1.Sttime < autodata.sttime  )      
--    And ( T1.ndtime >  autodata.ndtime)      
--    AND (autodata.ndtime> T1.StartTime)      
--    AND (autodata.sttime< T1.EndTime)      
--    GROUP BY AUTODATA.mc,T1.StartTime,T1.EndTime      
--    )AS T2 inner join #FinalData on T2.mc = #FinalData.machineinterface and T2.StartTime = #FinalData.StartTime and T2.EndTime = #FinalData.EndTime      
      
      
--   --Calculation of PartsCount Begins..      
--   UPDATE #FinalData SET components = ISNULL(components,0) + ISNULL(t2.comp,0)      
--   From(   
--    Select mc,T1.StartTime,T1.EndTime,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp From       
--      (      
--         select mc,SUM(autodata.partscount)AS OrginalCount,comp,opn,#FinalData.StartTime,#FinalData.EndTime from #T_autodata autodata WITH(NOLOCK)      
--         inner join #FinalData on autodata.mc = #FinalData.machineinterface      
--         where (autodata.ndtime>#FinalData.StartTime) and (autodata.ndtime<=#FinalData.EndTime) and (autodata.datatype=1)      
--         Group By mc,comp,opn,#FinalData.StartTime,#FinalData.EndTime      
--      ) as T1      
--    inner join machineinformation on machineinformation.interfaceid =T1.mc      
--    Inner join componentinformation C on T1.Comp = C.interfaceid      
--    Inner join ComponentOperationPricing O ON  T1.Opn = O.interfaceid and C.Componentid=O.componentid      
--    and machineinformation.machineid=o.machineid      
--    GROUP BY mc,T1.StartTime,T1.EndTime      
--   ) As T2 Inner join #FinalData on T2.mc = #FinalData.machineinterface and T2.StartTime = #FinalData.StartTime and T2.EndTime = #FinalData.EndTime      
--end      
----ER0383 Till Here      
      
Update #FinalData      
set #FinalData.PF = ISNULL(#FinalData.PF,0)+ISNULL(t1.PF,0)      
from (      
 select tcs_energyconsumption.MachineiD,StartTime,EndTime,      
 avg(abs(tcs_energyconsumption.pf)) as PF      
 from #tcs tcs_energyconsumption WITH(NOLOCK) inner join #FinalData on ----ER0383      
 tcs_energyconsumption.machineID = #FinalData.MachineID and tcs_energyconsumption.gtime >= #FinalData.StartTime      
 and tcs_energyconsumption.gtime <= #FinalData.EndTime --And tcs_energyconsumption.pf >= 0      
 group by tcs_energyconsumption.MachineiD,StartTime,EndTime      
) as t1 inner join #FinalData on t1.machineiD = #FinalData.machineID and      
t1.StartTime = #FinalData.StartTime and t1.endTime = #FinalData.EndTime      
      
      
Update #FinalData      
set #FinalData.MinEnergy = ISNULL(#FinalData.MinEnergy,0)+ISNULL(t1.kwh,0) from       
(      
select T.MachineiD,T.StartTime,T.EndTime,round(kwh,2) as kwh from       
 (      
 select  tcs_energyconsumption.MachineiD,StartTime,EndTime,      
 min(gtime) as mingtime      
 from #tcs tcs_energyconsumption WITH(NOLOCK) inner join #FinalData on ----ER0383      
 tcs_energyconsumption.machineID = #FinalData.MachineID and tcs_energyconsumption.gtime >= #FinalData.StartTime      
 and tcs_energyconsumption.gtime <= #FinalData.EndTime      
 where tcs_energyconsumption.kwh>0 --ER0419 Added      
 group by  tcs_energyconsumption.MachineiD,StartTime,EndTime)T      
 inner join #tcs  tcs_energyconsumption on tcs_energyconsumption.gtime=T.mingtime   AND tcs_energyconsumption.MachineID = T.MachineID --DR0359      
 --inner join tcs_energyconsumption on tcs_energyconsumption.gtime=T.mingtime      
 ) as t1       
inner join #FinalData on t1.machineiD = #FinalData.machineID and      
t1.StartTime = #FinalData.StartTime and t1.endTime = #FinalData.EndTime      
      
Update #FinalData      
set #FinalData.MaxEnergy = ISNULL(#FinalData.MaxEnergy,0)+ISNULL(t1.kwh,0) from       
(      
select T.MachineiD,T.StartTime,T.EndTime,round(kwh,2)as kwh from       
 (      
 select  tcs_energyconsumption.MachineiD,StartTime,EndTime,      
 max(gtime) as maxgtime      
 from #tcs tcs_energyconsumption WITH(NOLOCK) inner join #FinalData on ----ER0383      
 tcs_energyconsumption.machineID = #FinalData.MachineID and tcs_energyconsumption.gtime >= #FinalData.StartTime      
 and tcs_energyconsumption.gtime <= #FinalData.EndTime      
 where tcs_energyconsumption.kwh>0 --ER0419 Added      
 group by  tcs_energyconsumption.MachineiD,StartTime,EndTime)T      
 inner join #tcs tcs_energyconsumption on tcs_energyconsumption.gtime=T.maxgtime   AND tcs_energyconsumption.MachineID = T.MachineID -- DR0359      
 --inner join tcs_energyconsumption on tcs_energyconsumption.gtime=T.maxgtime      
 ) as t1       
inner join #FinalData on t1.machineiD = #FinalData.machineID and      
t1.StartTime = #FinalData.StartTime and t1.endTime = #FinalData.EndTime      
      
Update #FinalData      
set #FinalData.Energy = ISNULL(#FinalData.Energy,0)+ISNULL(t1.kwh,0),       
#FinalData.Cost = ISNULL(#FinalData.Cost,0)+ISNULL(t1.kwh * (Select max(Valueintext) from shopdefaults where Parameter = 'CostPerKWH'),0)      
from       
(      
 select MachineiD,StartTime,EndTime,round((MaxEnergy - MinEnergy),2) as kwh from #FinalData       
) as t1 inner join #FinalData on t1.machineiD = #FinalData.machineID and      
t1.StartTime = #FinalData.StartTime and t1.endTime = #FinalData.EndTime      
      
      
if @machineid<>''       
begin   

 --set @sql=''          
 --set @sql=@sql+' insert into #temp (Machine,starttime,Endtime,Cuttingdetail,TotalCuttingTime)      
 -- Select EM_Machineinformation.Machineid,sttime as StartTime,ndtime as EndTime,0,0 from #T_autodata autodata A WITH(NOLOCK) --ER0383      
 -- inner join EM_Machineinformation  on A.mc = EM_Machineinformation.interfaceid'      
 ----ER0375 From Here      
 ----where Machineinformation.devicetype=5 and datatype = 1 and sttime >= '''+convert(nvarchar(20),@Startdate)+'''      
 ----and ndtime <= '''+convert(nvarchar(20),@Enddate)+'''  '      
 ----set @sql=@sql + ' where Machineinformation.devicetype=5 and datatype = 1 and sttime >= '''+convert(nvarchar(20),@cuttime_Start,120)+'''      
 --set @sql=@sql + ' where datatype = 1 and EM_Machineinformation.MachineType =  ''' + @MachineType+''' and sttime >= '''+convert(nvarchar(20),@cuttime_Start,120)+'''      
 --and ndtime <= '''+convert(nvarchar(20),@cuttime_end,120)+'''  '      
 ----ER0375 Till Here      
 --set @sql=@sql +  @MachineName  + ' order by sttime'      
 --print(@sql)  
 --exec(@sql)  
 
  set @sql=''          
 set @sql=@sql+' insert into #temp (Machine,starttime,Endtime,Cuttingdetail,TotalCuttingTime)      
  Select EM_Machineinformation.Machineid,sttime as StartTime,ndtime as EndTime,0,0 from #T_autodata A WITH(NOLOCK) --ER0383      
  inner join EM_Machineinformation  on A.mc = EM_Machineinformation.interfaceid'      
 --ER0375 From Here      
 --where Machineinformation.devicetype=5 and datatype = 1 and sttime >= '''+convert(nvarchar(20),@Startdate)+'''      
 --and ndtime <= '''+convert(nvarchar(20),@Enddate)+'''  '      
 --set @sql=@sql + ' where Machineinformation.devicetype=5 and datatype = 1 and sttime >= '''+convert(nvarchar(20),@cuttime_Start,120)+'''      
 set @sql=@sql + ' where datatype = 1 and EM_Machineinformation.MachineType =  ''' + @MachineType+''' and sttime >= '''+convert(nvarchar(20),@cuttime_Start,120)+'''      
 and ndtime <= '''+convert(nvarchar(20),@cuttime_end,120)+'''  '      
 --ER0375 Till Here      
 set @sql=@sql +  @MachineName  + ' order by sttime'      
 print(@sql)  
 exec(@sql)      

  
      
      
 insert into #Energydata(Machineid,Col1_gtime,Col2_gtime,Col1_Amp,Col2_Amp,st,nd)      
 select S1.machineid ,s1.gtime,case when s1.gtime1>#temp.Endtime then #temp.Endtime else s1.gtime1 end,      
 s1.ampere,s1.ampere1,#temp.starttime,#temp.Endtime       
 --from  tcs_energyconsumption s1 WITH(NOLOCK) 
 from #tcs  s1 WITH(NOLOCK) 
 inner join #temp on s1.machineid=#temp.machine --ER0383      
 where S1.gtime>=#temp.starttime and S1.gtime<=#temp.Endtime       
 and isnull(s1.gtime1,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'      
      
      
      
      
-- insert into #temp (Machine,starttime,Endtime,Cuttingdetail,TotalCuttingTime)      
-- Select mi.Machineid,sttime as StartTime,ndtime as EndTime,0,0 from autodata A      
-- inner join Machineinformation mi on A.mc = mi.interfaceid      
-- where mi.devicetype=5 and datatype = 1 and sttime >= @Startdate and ndtime <= @Enddate        
-- and mi.Machineid = @MachineID      
-- order by sttime      
--      
--       
      
--insert into #Energydata(Machineid,Col1_gtime,Col2_gtime,Col1_Amp,Col2_Amp,st,nd)      
-- select @machineid,s1.gtime,case when s1.gtime1>#temp.Endtime then #temp.Endtime else s1.gtime1 end,      
-- s1.ampere,s1.ampere1,#temp.starttime,#temp.Endtime       
-- from tcs_energyconsumption s1, #temp      
-- where  S1.gtime>=#temp.starttime and S1.gtime<=#temp.Endtime and S1.machineid=@machineid      
-- and  #temp.Machine=@machineid and isnull(s1.gtime1,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'      
---- group by S1.machineid,s1.gtime,s1.gtime1,s1.ampere,s1.ampere1,#temp.starttime,#temp.Endtime      
      
       
end      
      
else      
begin 

 insert into #temp (Machine,starttime,Endtime,Cuttingdetail,TotalCuttingTime)      
 Select T.Machineid,sttime as StartTime,ndtime as EndTime,0,0 from #T_autodata  A WITH(NOLOCK) --ER0383      
 inner join EM_Machineinformation mi on A.mc = mi.interfaceid      
 --inner join (select distinct machineid from tcs_energyconsumption WITH(NOLOCK)) T on T.machineid=mi.Machineid --ER0383      
 inner join (select distinct machineid from #tcs tcs_energyconsumption WITH(NOLOCK)) T on T.machineid=mi.Machineid --ER0383      
 --where mi.devicetype=5 and datatype = 1 and sttime >= @Startdate and ndtime <= @Enddate   --ER0375      
 --where mi.devicetype=5 and datatype = 1 and sttime >= convert(nvarchar(20),@cuttime_Start,120) and ndtime <= convert(nvarchar(20),@cuttime_End,120) --ER0375        
 where datatype = 1 and mi.MachineType = @MachineType and sttime >= convert(nvarchar(20),@cuttime_Start,120) and ndtime <= convert(nvarchar(20),@cuttime_End,120) --ER0375        
 order by sttime 
 

 /*      
 insert into #Energydata(Machineid,Col1_ID,Col2_ID,st,nd)      
 select S1.machineid ,s1.idd,min(s2.idd),#temp.starttime,#temp.Endtime       
 from tcs_energyconsumption s1,tcs_energyconsumption s2, #temp      
 where s1.idd<s2.idd and S1.gtime>=#temp.starttime and S1.gtime<=#temp.Endtime       
 and S2.gtime>=#temp.starttime and S2.gtime<=#temp.Endtime       
 group by S1.machineid,s1.idd,#temp.starttime,#temp.Endtime      
 */      
       
 insert into #Energydata(Machineid,Col1_gtime,Col2_gtime,Col1_Amp,Col2_Amp,st,nd)      
 select S1.machineid ,s1.gtime,case when s1.gtime1>#temp.Endtime then #temp.Endtime else s1.gtime1 end,      
 s1.ampere,s1.ampere1,#temp.starttime,#temp.Endtime       
 --from tcs_energyconsumption s1 WITH(NOLOCK)
  from #tcs s1 WITH(NOLOCK)
 inner join #temp on s1.machineid=#temp.machine --ER0383      
 where S1.gtime>=#temp.starttime and S1.gtime<=#temp.Endtime       
 and isnull(s1.gtime1,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'      
-- group by S1.machineid,s1.gtime,s1.gtime1,s1.ampere,s1.ampere1,#temp.starttime,#temp.Endtime      
      
 End      
      

/*      
insert into #Energydata(Machineid,Col1_ID,Col2_ID,st,nd)      
select @machineid ,s1.idd,min(s2.idd),#temp.starttime,#temp.Endtime from tcs_energyconsumption s1,tcs_energyconsumption s2      
, #temp      
where s1.idd<s2.idd and S1.gtime>#temp.starttime and S1.gtime<#temp.Endtime and S1.machineid=@machineid      
and S2.gtime>#temp.starttime and S2.gtime<#temp.Endtime and S2.machineid=@machineid and #temp.Machine=@machineid      
group by S2.machineid,s1.idd,#temp.starttime,#temp.Endtime      
*/      
      
update #Energydata set COl1_COl2=datediff(s,Col1_gtime,Col2_gtime)      
      
      
Update #temp set Cuttingdetail=T.CT from(Select sum(COl1_COl2) as Ct,#temp.starttime as st,#temp.Endtime as nd  from #Energydata,#temp       
inner join EM_Machineinformation M on M.machineid=#temp.machine where Col1_Amp>= M.LowerPowerthreshold and M.MachineType = @MachineType and     
#temp.starttime=#Energydata.st and #Energydata.nd=#temp.Endtime group by #temp.starttime,#temp.Endtime)T  where T.st=#temp.starttime  and T.nd=#temp.Endtime      
      
      
update #Finaldata set cutting_time= isnull(cutting_time,0) + (t.count1) from      
(Select sum(#temp.Cuttingdetail) as count1,#temp.Machine,#Finaldata.StartTime,#Finaldata.EndTime from  #temp       
inner join #Finaldata on #Finaldata.MachineID=#temp.Machine      
where  #temp.starttime>=#Finaldata.StartTime and #temp.Endtime<=#Finaldata.EndTime       
group by #temp.Machine,#Finaldata.StartTime,#Finaldata.EndTime)  t where t.Machine=#Finaldata.MachineID      
and t.starttime=#Finaldata.StartTime and t.EndTime=#Finaldata.EndTime      
      
--ER0419 From Here      
--select MachineID,shift,StartTime,EndTime,dbo.f_FormatTime(UtilisedTime,'HH:MM:SS') as UtilisedTime,      
--dbo.f_FormatTime(Cutting_Time,'HH:MM:SS') as Cutting_Time,components,Round(PF,2) as PF,Round(Cost,2) as Cost,      
--round(Energy,2) as energy from #Finaldata      
      
--ER0419 Added from Here      
Update #Finaldata set MinVolt1=isnull(#Finaldata.MinVolt1,0) + isnull(T1.V1,0),MinVolt2=isnull(#Finaldata.MinVolt2,0) + isnull(T1.V2,0)      
,minVolt3=isnull(#Finaldata.minVolt3,0) + isnull(T1.V3,0),MinVolt4= isnull(#Finaldata.MinVolt4,0)+isnull(T1.V4,0),MinVolt5=isnull(#Finaldata.MinVolt5,0)+isnull(T1.V5,0),MinVolt6 = ISNULL(#Finaldata.MinVolt6,0)+ISNULL(T1.V6,0) from      
(      
 select TCS.MachineiD,F.StartTime,F.EndTime,min(Volt1) as V1,min(Volt2) as V2,min(Volt3) as V3, min(Volt4) as V4,min(Volt5) as V5,min(Volt6) as V6       
 --from tcs_energyconsumption TCS WITH(NOLOCK) inner join #FinalData F on 
  from #tcs TCS WITH(NOLOCK) inner join #FinalData F on       
 TCS.machineID = F.MachineID and TCS.gtime >= F.StartTime and TCS.gtime <= F.EndTime      
 group by  TCS.MachineiD,F.StartTime,F.EndTime      
) as T1       
inner join #FinalData on t1.machineiD = #FinalData.machineID and      
t1.StartTime = #FinalData.StartTime and t1.endTime = #FinalData.EndTime      
      
Update #Finaldata set MaxVolt1=isnull(#Finaldata.maxVolt1,0) + isnull(T1.V1,0),MaxVolt2=isnull(#Finaldata.MaxVolt2,0) + isnull(T1.V2,0)      
,MaxVolt3=isnull(#Finaldata.MaxVolt3,0) + isnull(T1.V3,0), MaxVolt4= isnull(#Finaldata.MaxVolt4,0)+isnull(T1.V4,0),MaxVolt5 = isnull(#Finaldata.MaxVolt5,0)+isnull(T1.V5,0),MaxVolt6=ISNULL(#Finaldata.MaxVolt6,0)+isnull(T1.V6,0) from      
(select TCS.MachineiD,F.StartTime,F.EndTime,max(Volt1) as V1,max(Volt2) as V2,max(Volt3) as V3, max(Volt4) as V4,max(Volt5) as V5, max(Volt6) as V6       
 --from tcs_energyconsumption TCS WITH(NOLOCK) inner join #FinalData F on  
  from #tcs TCS WITH(NOLOCK) inner join #FinalData F on       
 TCS.machineID = F.MachineID and TCS.gtime >= F.StartTime and TCS.gtime <= F.EndTime      
 group by  TCS.MachineiD,F.StartTime,F.EndTime      
) as T1       
inner join #FinalData on t1.machineiD = #FinalData.machineID and      
t1.StartTime = #FinalData.StartTime and t1.endTime = #FinalData.EndTime  


Update #Finaldata set Ampere1=isnull(#Finaldata.Ampere1,0)+isnull(T1.A1,0),      
Ampere2=isnull(#Finaldata.Ampere2,0)+isnull(T1.A2,0),Ampere3=isnull(#Finaldata.Ampere3,0)+isnull(T1.A3,0) from      
(      
select T.MachineiD,T.StartTime,T.EndTime,round(AmpereR,2) as A1,Round(AmpereY,2) as A2,Round(AmpereB,2) as A3 from       
(      
select  TCS.MachineiD,F.StartTime,F.EndTime,Max(gtime) as Maxgtime      
--from tcs_energyconsumption TCS WITH(NOLOCK) inner join #FinalData F on  
from #tcs TCS WITH(NOLOCK) inner join #FinalData F on       
TCS.machineID = F.MachineID and TCS.gtime >= F.StartTime and TCS.gtime <= F.EndTime      
group by  TCS.MachineiD,F.StartTime,F.EndTime)T      
inner join #tcs tcs_energyconsumption on tcs_energyconsumption.gtime=T.Maxgtime        
AND tcs_energyconsumption.MachineID = T.MachineID       
) as T1       
inner join #FinalData on t1.machineiD = #FinalData.machineID and      
t1.StartTime = #FinalData.StartTime and t1.endTime = #FinalData.EndTime

 
  --ER0454 Added from here    
select A.mc,A.Starttime,CO.Componentid + ' <' + cast(CO.Operationno as nvarchar(50)) + '>'  as CO INTO #CO from     
 (    
     Select Distinct A.mc,A.comp,A.opn,F.starttime from #T_autodata  A WITH(NOLOCK)     
  inner join #FinalData F on A.mc= F.MachineInterface and A.sttime >= F.StartTime and A.ndtime <= F.EndTime      
 )A    
inner join Machineinformation on A.mc=Machineinformation.interfaceid      
inner join Componentinformation C on A.comp=C.interfaceid      
inner join Componentoperationpricing CO on A.opn=CO.interfaceid      
and Machineinformation.Machineid=CO.Machineid and C.Componentid=CO.Componentid      
 
 UPDATE #Finaldata SET CompOpn = ISNULL(#Finaldata.CompOpn,'') + ISNULL(t1.CO,'')        
  from(        
  SELECT t1.mc,t1.Starttime ,        
      STUFF(ISNULL((SELECT ' , ' + t.CO       
      FROM #CO t         
        WHERE t.mc = t1.mc and t.Starttime = t1.Starttime    
     GROUP BY t.CO order by t1.mc,t1.Starttime       
      FOR XML PATH (''), TYPE).value('.','nVARCHAR(max)'), ''), 1, 2, '') [CO]              
    FROM #CO t1    
)as t1 inner join #FinalData on t1.mc = #FinalData.MachineInterface and      
t1.StartTime = #FinalData.StartTime    
 --ER0454 Added Till Here  

 update #Finaldata set KWHPerComponent=isnull(energy,0)/isnull(components,0) where components<>0

 UPDATE #Finaldata SET KVA=ISNULL(t1.KVA,0)
 FROM
 (
   SELECT F.MACHINEID,STARTTIME,ENDTIME,MAX(T.KVA) AS kva FROM #Finaldata F
 INNER JOIN tcs_energyconsumption T ON T.MachineID=F.MachineID
 WHERE gtime>=StartTime AND gtime<=EndTime
 GROUP BY F.MACHINEID,STARTTIME,EndTime
 )T1 INNER JOIN #Finaldata F ON F.MachineID=T1.MachineID AND F.StartTime=T1.StartTime AND F.EndTime=T1.EndTime



    
--ER0419 Added From Here 
IF (@IsChecked=0)
BEGIN
 select MachineID,shift,StartTime,EndTime,CompOpn,dbo.f_FormatTime(UtilisedTime,'HH:MM:SS') as ProductionTime,     --ER0454 added compopn 
 dbo.f_FormatTime(Cutting_Time,'HH:MM:SS') as Cutting_Time,components as ProductionCount,Round(PF,2) as PowerFactor,Round(Cost,2) as Cost,      
 round(Energy,2) as energy      
 ,cast(MinVolt1 as nvarchar(50))+ ' \ ' + cast(MaxVolt1 as nvarchar(50)) as Volt1      
 ,cast(MinVolt2 as nvarchar(50))+ ' \ ' + cast(MaxVolt2 as nvarchar(50)) as Volt2      
 ,cast(MinVolt3 as nvarchar(50))+ ' \ ' + cast(MaxVolt3 as nvarchar(50)) as Volt3     
 ,cast(MinVolt4 as nvarchar(50))+ ' \ ' + cast(MaxVolt4 as nvarchar(50)) as Volt4     
 ,cast(MinVolt5 as nvarchar(50))+ ' \ ' + cast(MaxVolt5 as nvarchar(50)) as Volt5     
 ,cast(MinVolt6 as nvarchar(50))+ ' \ ' + cast(MaxVolt6 as nvarchar(50)) as Volt6
 ,round(Ampere1,2) as AmpereR
 ,round(Ampere2,2) as AmpereY
 ,round(Ampere3,2) as AmpereB
 ,ROUND(KWHPerComponent,3) as KWHPerComponent
 ,ROUND(KVA,2) AS KVA
 from #Finaldata 
END

 if (@IsChecked=1) AND (@Param='Time Consolidated')
 begin
  select distinct top(10)  MachineID,shift,StartTime,EndTime,CompOpn,dbo.f_FormatTime(UtilisedTime,'HH:MM:SS') as ProductionTime,     --ER0454 added compopn 
 dbo.f_FormatTime(Cutting_Time,'HH:MM:SS') as Cutting_Time,components as ProductionCount,Round(PF,2) as PowerFactor,Round(Cost,2) as Cost,      
 round(Energy,2) as energy      
 ,cast(MinVolt1 as nvarchar(50))+ ' \ ' + cast(MaxVolt1 as nvarchar(50)) as Volt1      
 ,cast(MinVolt2 as nvarchar(50))+ ' \ ' + cast(MaxVolt2 as nvarchar(50)) as Volt2      
 ,cast(MinVolt3 as nvarchar(50))+ ' \ ' + cast(MaxVolt3 as nvarchar(50)) as Volt3     
 ,cast(MinVolt4 as nvarchar(50))+ ' \ ' + cast(MaxVolt4 as nvarchar(50)) as Volt4     
 ,cast(MinVolt5 as nvarchar(50))+ ' \ ' + cast(MaxVolt5 as nvarchar(50)) as Volt5     
 ,cast(MinVolt6 as nvarchar(50))+ ' \ ' + cast(MaxVolt6 as nvarchar(50)) as Volt6
 ,round(Ampere1,2) as AmpereR
 ,round(Ampere2,2) as AmpereY
 ,round(Ampere3,2) as AmpereB
  ,ROUND(KWHPerComponent,3) as KWHPerComponent
   ,ROUND(KVA,2) AS KVA
 from #Finaldata
 ORDER BY energy DESC
end

 if (@IsChecked=1) AND (@Param='DAY')
 BEGIN
 SELECT * FROM(
   select   MachineID,shift,StartTime,EndTime,CompOpn,dbo.f_FormatTime(UtilisedTime,'HH:MM:SS') as ProductionTime,     --ER0454 added compopn 
 dbo.f_FormatTime(Cutting_Time,'HH:MM:SS') as Cutting_Time,components as ProductionCount,Round(PF,2) as PowerFactor,Round(Cost,2) as Cost,      
 round(Energy,2) as energy      
 ,cast(MinVolt1 as nvarchar(50))+ ' \ ' + cast(MaxVolt1 as nvarchar(50)) as Volt1      
 ,cast(MinVolt2 as nvarchar(50))+ ' \ ' + cast(MaxVolt2 as nvarchar(50)) as Volt2      
 ,cast(MinVolt3 as nvarchar(50))+ ' \ ' + cast(MaxVolt3 as nvarchar(50)) as Volt3     
 ,cast(MinVolt4 as nvarchar(50))+ ' \ ' + cast(MaxVolt4 as nvarchar(50)) as Volt4     
 ,cast(MinVolt5 as nvarchar(50))+ ' \ ' + cast(MaxVolt5 as nvarchar(50)) as Volt5     
 ,cast(MinVolt6 as nvarchar(50))+ ' \ ' + cast(MaxVolt6 as nvarchar(50)) as Volt6
 ,round(Ampere1,2) as AmpereR
 ,round(Ampere2,2) as AmpereY
 ,round(Ampere3,2) as AmpereB
  ,ROUND(KWHPerComponent,3) as KWHPerComponent
   ,ROUND(KVA,2) AS KVA,Dense_rank()OVER(ORDER BY MachineID)AS ROWNO
 from #Finaldata)RS
 where ROWno<=10
 order by energy desc,machineid asc
 END


 if (@IsChecked=1) AND (@Param='SHIFT')
 BEGIN
 SELECT * FROM(
   select   MachineID,shift,StartTime,EndTime,CompOpn,dbo.f_FormatTime(UtilisedTime,'HH:MM:SS') as ProductionTime,     --ER0454 added compopn 
 dbo.f_FormatTime(Cutting_Time,'HH:MM:SS') as Cutting_Time,components as ProductionCount,Round(PF,2) as PowerFactor,Round(Cost,2) as Cost,      
 round(Energy,2) as energy      
 ,cast(MinVolt1 as nvarchar(50))+ ' \ ' + cast(MaxVolt1 as nvarchar(50)) as Volt1      
 ,cast(MinVolt2 as nvarchar(50))+ ' \ ' + cast(MaxVolt2 as nvarchar(50)) as Volt2      
 ,cast(MinVolt3 as nvarchar(50))+ ' \ ' + cast(MaxVolt3 as nvarchar(50)) as Volt3     
 ,cast(MinVolt4 as nvarchar(50))+ ' \ ' + cast(MaxVolt4 as nvarchar(50)) as Volt4     
 ,cast(MinVolt5 as nvarchar(50))+ ' \ ' + cast(MaxVolt5 as nvarchar(50)) as Volt5     
 ,cast(MinVolt6 as nvarchar(50))+ ' \ ' + cast(MaxVolt6 as nvarchar(50)) as Volt6
 ,round(Ampere1,2) as AmpereR
 ,round(Ampere2,2) as AmpereY
 ,round(Ampere3,2) as AmpereB
  ,ROUND(KWHPerComponent,3) as KWHPerComponent
   ,ROUND(KVA,2) AS KVA,Dense_rank()OVER(ORDER BY MachineID)AS ROWNO
 from #Finaldata)RS
 WHERE ROWNO<=10
 order by StartTime asc,shift asc,energy desc
END
 
-- if (@IsChecked=1) AND (@Param<>'SHIFT')
-- begin
--  select distinct top(10)  MachineID,shift,StartTime,EndTime,CompOpn,dbo.f_FormatTime(UtilisedTime,'HH:MM:SS') as ProductionTime,     --ER0454 added compopn 
-- dbo.f_FormatTime(Cutting_Time,'HH:MM:SS') as Cutting_Time,components as ProductionCount,Round(PF,2) as PowerFactor,Round(Cost,2) as Cost,      
-- round(Energy,2) as energy      
-- ,cast(MinVolt1 as nvarchar(50))+ ' \ ' + cast(MaxVolt1 as nvarchar(50)) as Volt1      
-- ,cast(MinVolt2 as nvarchar(50))+ ' \ ' + cast(MaxVolt2 as nvarchar(50)) as Volt2      
-- ,cast(MinVolt3 as nvarchar(50))+ ' \ ' + cast(MaxVolt3 as nvarchar(50)) as Volt3     
-- ,cast(MinVolt4 as nvarchar(50))+ ' \ ' + cast(MaxVolt4 as nvarchar(50)) as Volt4     
-- ,cast(MinVolt5 as nvarchar(50))+ ' \ ' + cast(MaxVolt5 as nvarchar(50)) as Volt5     
-- ,cast(MinVolt6 as nvarchar(50))+ ' \ ' + cast(MaxVolt6 as nvarchar(50)) as Volt6
-- ,round(Ampere1,2) as AmpereR
-- ,round(Ampere2,2) as AmpereY
-- ,round(Ampere3,2) as AmpereB
--  ,ROUND(KWHPerComponent,3) as KWHPerComponent
--   ,ROUND(KVA,2) AS KVA
-- from #Finaldata
--end

-- if (@IsChecked=1) AND (@Param='SHIFT')
-- BEGIN
-- SELECT * FROM(
--   select   MachineID,shift,StartTime,EndTime,CompOpn,dbo.f_FormatTime(UtilisedTime,'HH:MM:SS') as ProductionTime,     --ER0454 added compopn 
-- dbo.f_FormatTime(Cutting_Time,'HH:MM:SS') as Cutting_Time,components as ProductionCount,Round(PF,2) as PowerFactor,Round(Cost,2) as Cost,      
-- round(Energy,2) as energy      
-- ,cast(MinVolt1 as nvarchar(50))+ ' \ ' + cast(MaxVolt1 as nvarchar(50)) as Volt1      
-- ,cast(MinVolt2 as nvarchar(50))+ ' \ ' + cast(MaxVolt2 as nvarchar(50)) as Volt2      
-- ,cast(MinVolt3 as nvarchar(50))+ ' \ ' + cast(MaxVolt3 as nvarchar(50)) as Volt3     
-- ,cast(MinVolt4 as nvarchar(50))+ ' \ ' + cast(MaxVolt4 as nvarchar(50)) as Volt4     
-- ,cast(MinVolt5 as nvarchar(50))+ ' \ ' + cast(MaxVolt5 as nvarchar(50)) as Volt5     
-- ,cast(MinVolt6 as nvarchar(50))+ ' \ ' + cast(MaxVolt6 as nvarchar(50)) as Volt6
-- ,round(Ampere1,2) as AmpereR
-- ,round(Ampere2,2) as AmpereY
-- ,round(Ampere3,2) as AmpereB
--  ,ROUND(KWHPerComponent,3) as KWHPerComponent
--   ,ROUND(KVA,2) AS KVA,ROW_NUMBER() OVER (PARTITION BY SHIFT ORDER BY SHIFT)AS ROWNO
-- from #Finaldata)RS
-- WHERE ROWNO<=10
-- order by Shift ASC
--END

      
--ER0419 Added Till Here      
      
      
End      
