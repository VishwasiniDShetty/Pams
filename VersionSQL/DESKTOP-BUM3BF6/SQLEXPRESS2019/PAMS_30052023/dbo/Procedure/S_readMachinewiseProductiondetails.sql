/****** Object:  Procedure [dbo].[S_readMachinewiseProductiondetails]    Committed by VersionSQL https://www.versionsql.com ******/

  
/********************************************************************************  
NR0077 - KarthikR/GeetanjaliK/SwathiKS - 20/Jan/2012 :: Created New Procedure to show Machinewise Production details For Dantal.   
ER0393 - SwathiKS - 17/Sep/2014 :: Performance optimization and To Get shiftwise utlilised time, down time and management loss and Parts for a month.  
--Launch will be under Standard -> Production Report-Machinewise -> Format Time Consolidated -> Shiftwise Analysis Report   
S_readMachinewiseProductiondetails '2017-11-01','2017-11-10','','','','shiftwise'  
************************************************************************************/  
  
CREATE PROCEDURE [dbo].[S_readMachinewiseProductiondetails]  
  
 @StartDate datetime,  
 @EndDate datetime='',  
    @PlantID NvarChar(50)='',   
 @MachineID nvarchar(50) = '',  
 @ShiftIn nvarchar(20) ,  
 @Param nvarchar(20)=''  
   
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
  
  
--------------------Temp tables------------------------------------------------------  
CREATE TABLE #Exceptions  
(  
 MachineID NVarChar(50),   
 StartTime DateTime,  
 EndTime DateTime,  
 IdealCount Int,  
 ActualCount Int,  
 ExCount Int DEFAULT 0,  
 Sdate datetime not null,  
 ShiftName nvarchar(50)   
)  
--Shift Details  
CREATE TABLE #ShiftDetails_SelPeriod (  
 PDate datetime,  
 Shift nvarchar(20),  
 ShiftStart datetime,  
 ShiftEnd datetime  
)  
  
--Machine level details  
CREATE TABLE #ShiftProductionFromAutodata_ShiftBasis (  
     slno integer identity,  
 MachineInterface nvarchar(50) not null,  
 UstartShift datetime not null,  
 UEndShift datetime not null,  
 MachineID nvarchar(50) NOT NULL,   
 ProductionEfficiency float,  
 AvailabilityEfficiency float,  
 OverallEfficiency float,  
 UtilisedTime float,  
 ManagementLoss float,  
 DownTime float,  
 CN float,  
 Qty float,  
 Udate datetime not null,  
 Ushift nvarchar(50),   
 MLDown float,  
 TurnOver float,  
 ReturnPerHour float,  
 ReturnPerHourtotal float,  
 PDT float --SV  
   
)  
ALTER TABLE #ShiftProductionFromAutodata_ShiftBasis  
 ADD PRIMARY KEY CLUSTERED  
  (   slno  
   
  ) ON [PRIMARY]  
  
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
  
  
--ER0393 added From Here  
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
 [PartsCount] int NULL ,  
 id  bigint not null  
)  
  
ALTER TABLE #T_autodata  
  
ADD PRIMARY KEY CLUSTERED  
(  
 mc,sttime ASC  
)ON [PRIMARY]  
--ER0393 Added Till here  
  
  
---Temp Tabels------------------------------------------------------------------------------------  
declare @strsql nvarchar(4000)  
declare @strmachine nvarchar(255)  
declare @timeformat as nvarchar(2000)  
Declare @StrMPlantID AS NVarchar(255)  
Declare @strXmachine AS NVarchar(255)  
Declare @shiftname as nvarchar(50)  
  
select @strsql = ''  
select @strmachine = ''  
select @strXmachine = ''  
Select @StrMPlantID=''  
Select @shiftname=''  
SELECT @timeformat ='ss'  
  
Select @timeformat = isnull((select valueintext from cockpitdefaults where parameter='timeformat'),'ss')  
if (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')  
begin  
 select @timeformat = 'ss'  
end  
  
if isnull(@EndDate,'')=''  
begin  
 select @EndDate=@StartDate  
end  
if isnull(@PlantID,'') <> ''  
begin  
 select @StrMPlantID = ' and ( PlantMachine.PlantID = N''' + @PlantID + ''' )'  
end  
if isnull(@machineid,'') <> ''  
begin  
 select @strmachine = ' and ( machineinformation.MachineID = N''' + @MachineID + ''')'  
 select @strXmachine = ' and ( EX.MachineID = N''' + @MachineID + ''')'  
end  
  
  
  
declare @StartTime as datetime  
declare @Duration as Bigint  
declare @EndTime as datetime  
declare @CurStrtTime as datetime  
declare @CurEndTime as datetime  
select @CurStrtTime=@StartDate  
select @CurEndTime=@EndDate  
  
  
declare @TD_ST as datetime  
declare @TD_ED as datetime  
  
--Get Shift Start and Shift End  
while @CurStrtTime<=@EndDate  
BEGIN  
 INSERT #ShiftDetails_SelPeriod(Pdate, Shift, ShiftStart, ShiftEnd)  
 EXEC s_GetShiftTime @CurStrtTime,@ShiftIn  
   
 SELECT @CurStrtTime=DATEADD(DAY,1,@CurStrtTime)  
END  
  
Select @TD_ST=min(ShiftStart) from #ShiftDetails_SelPeriod  
Select @TD_ED=max(ShiftEnd) from #ShiftDetails_SelPeriod  
  
Select top 1 @Duration=datediff(s,ShiftStart,ShiftEnd) from #ShiftDetails_SelPeriod  
  
  
Select @Duration=@Duration* case when @StartDate=@EndDate then 1  
else datediff(day,@StartDate,@EndDate) end  
  
--ER0393 From here  
Select @strsql=''  
select @strsql ='insert into #T_autodata '  
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'  
 select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'  
select @strsql = @strsql + ' from autodata where (( sttime >='''+ convert(nvarchar(25),@TD_ST,120)+''' and ndtime <= '''+ convert(nvarchar(25),@TD_ED,120)+''' ) OR '  
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@TD_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@TD_ED,120)+''' )OR '  
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@TD_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@TD_ST,120)+'''  
     and ndtime<='''+convert(nvarchar(25),@TD_ED,120)+''' )'  
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@TD_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@TD_ED,120)+''' and sttime<'''+convert(nvarchar(25),@TD_ED,120)+''' ) )'  
print @strsql  
exec (@strsql)  
--ER0393 Till here  
  
SELECT @StrSql=''  
If ( Select Count(*) from Machineinformation where MultiSpindleFlag=1)>0-- and interfaceid in(select distinct Machineint from #Machcomopnopr))>0  
  BEGIN  
   SELECT @StrSql = 'INSERT INTO #Exceptions(MachineID ,StartTime ,EndTime ,IdealCount ,ActualCount ,ExCount,Sdate,Shiftname )  
     SELECT Ex.MachineID ,  
     case when StartTime<MI.ShiftStart AND EndTime>MI.ShiftStart then MI.ShiftStart else StartTime end,  
     case when EndTime> MI.ShiftEnd  AND StartTime< MI.ShiftEnd then  MI.ShiftEnd else EndTime end  
     ,IdealCount ,ActualCount ,0 , t0.Pdate,MI.Shift  
     From ProductionCountException Ex  
     Inner Join MachineInformation M ON Ex.MachineID=M.MachineID      
     Inner join  #ShiftDetails_SelPeriod  MI ON t0.Shift=MI.Shift   
     Inner join  #ShiftDetails_SelPeriod as t0  on t0.Shift=MI.Shift'  
   SELECT @StrSql = @StrSql + ' WHERE  M.MultiSpindleFlag=1 '  
   SELECT @StrSql =@StrSql + @strXMachine   
   SELECT @StrSql =@StrSql +'AND ((Ex.StartTime>=MI.ShiftStart AND Ex.EndTime<= MI.ShiftEnd )  
     OR (Ex.StartTime< MI.ShiftStart AND Ex.EndTime> MI.ShiftStart AND Ex.EndTime<= MI.ShiftEnd)  
     OR(Ex.StartTime>=MI.ShiftStart AND Ex.EndTime> MI.ShiftStart  AND Ex.StartTime<MI.ShiftEnd)  
     OR(Ex.StartTime< MI.ShiftStart AND Ex.EndTime> MI.ShiftEnd))'  
   Print(@strsql)  
   Exec (@strsql)  
   IF ( SELECT Count(*) from #Exceptions ) <> 0  
    BEGIN  
  
     Select @StrSql = 'UPDATE #Exceptions SET ExCount=ISNULL(T2.Comp,0) From  
     (  
      SELECT T1.MachineID AS MachineID,T1.StartTime AS StartTime,T1.EndTime AS EndTime,  
      SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp  
       From (  
       select MachineInformation.MachineID,Tt1.StartTime,Tt1.EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from autodata  
       Inner Join MachineInformation   ON autodata.MC=MachineInformation.InterfaceID'  
     Select @StrSql = @StrSql +'Inner Join (Select MachineID,StartTime,EndTime From #Exceptions  
       )AS Tt1 ON Tt1.MachineID=MachineInformation.MachineID AND   
       Where (autodata.ndtime>Tt1.StartTime) AND (autodata.ndtime<=Tt1.EndTime) and (autodata.datatype=1) '  
     Select @StrSql = @StrSql+ @strmachine   
     Select @StrSql = @StrSql+' Group by MachineInformation.MachineID,Tt1.StartTime,Tt1.EndTime  
      ) as T1'  
        Select @StrSql = @StrSql+' Inner join machineinformation M on T1.machineid = M.machineid '  
     Select @StrSql = @StrSql+' GROUP BY T1.MachineID,T1.StartTime,t1.EndTime  
     )AS T2  
     WHERE  #Exceptions.StartTime=T2.StartTime AND #Exceptions.EndTime=T2.EndTime  
     AND #Exceptions.MachineID=T2.MachineID '  
     Exec(@StrSql)  
       
     ---mod 12:Apply PDT for calculation of exception count  
     If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
      BEGIN  
       Select @StrSql =''  
       Select @StrSql ='UPDATE #Exceptions SET ExCount=ISNULL(ExCount,0) - ISNULL(T3.Comp,0)  
       From  
       (  
        SELECT T2.MachineID AS MachineID,T2.StartTime AS StartTime,T2.EndTime AS EndTime,  
        SUM(CEILING (CAST(T2.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp  
        From  
        (  
         select MachineInformation.MachineID,  
         Max(T1.XStartTime)StartTime,Max(T1.XEndTime)EndTime,T1.PLD_StartTime,T1.PLD_EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from autodata  
         Inner Join MachineInformation   ON autodata.MC=MachineInformation.InterfaceID  
         Inner Join   
         (  
          SELECT MachineID,Ex.StartTime As XStartTime, Ex.EndTime AS XEndTime,  
          CASE  
           WHEN (Td.StartTime< Ex.StartTime And Td.EndTime<=Ex.EndTime AND Td.EndTime>Ex.StartTime) THEN Ex.StartTime  
           WHEN  (Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime) THEN Ex.StartTime  
           ELSE Td.StartTime  
          END AS PLD_StartTime,  
          CASE  
           WHEN (Td.StartTime>= Ex.StartTime And Td.StartTime <Ex.EndTime AND Td.EndTime>Ex.EndTime) THEN Ex.EndTime  
           WHEN  (Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime) THEN Ex.EndTime  
           ELSE  Td.EndTime  
          END AS PLD_EndTime  
         
          From #Exceptions AS Ex Cross join  #PlannedDownTimesShift AS Td  
          Where Td.Machine=Ex.Machineid  and  ((Td.StartTime>=Ex.StartTime And Td.EndTime <=Ex.EndTime)OR  
          (Td.StartTime< Ex.StartTime And Td.EndTime<=Ex.EndTime AND Td.EndTime>Ex.StartTime)OR  
          (Td.StartTime>= Ex.StartTime And Td.StartTime <Ex.EndTime AND Td.EndTime>Ex.EndTime)OR '  
        Select @StrSql = @StrSql + '(Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime)) and Td.Shiftst=''' +convert(nvarchar(20),@startdate,120)+ '''' ---ER0280   
        Select @StrSql = @StrSql + ' )AS T1 ON T1.MachineID=MachineInformation.MachineID   
        Where (autodata.ndtime>T1.PLD_StartTime AND autodata.ndtime<=T1.PLD_EndTime) and (autodata.datatype=1)'  
        Select @StrSql = @StrSql + ' AND (autodata.ndtime > ''' + convert(nvarchar(20),@startdate,120)+''' AND autodata.ndtime<=''' + convert(nvarchar(20),@Enddate,120)+''' )'  ---ER0280   
        Select @StrSql = @StrSql+' Group by MachineInformation.MachineID,T1.PLD_StartTime,T1.PLD_EndTime  
        )AS T2 GROUP BY T2.MachineID,T2.ComponentID,T2.OperationNo,T2.StartTime,t2.EndTime  
       )As T3  
       WHERE  #Exceptions.StartTime=T3.StartTime AND #Exceptions.EndTime=T3.EndTime  
       AND #Exceptions.MachineID=T3.MachineID '  
       PRINT @StrSql  
       EXEC(@StrSql)  
       UPDATE #Exceptions SET ExCount=ExCount-((ExCount * ActualCount)/ISNULL(IdealCount,0))  
     End  
     ---mod 12:Apply PDT for calculation of exception count  
   
   End  
End  
  
  Select @strsql=''  
  select @strsql ='insert into #ShiftProductionFromAutodata_ShiftBasis (MachineInterface,UstartShift,UEndShift,MachineID  
                         ,ProductionEfficiency, AvailabilityEfficiency ,  
                      OverallEfficiency, UtilisedTime, ManagementLoss, DownTime,Qty, CN,Udate,Ushift,MLDown , TurnOver,    ReturnPerHour,    ReturnPerHourtotal ,PDT ) ' --sV  
  select @strsql = @strsql + 'SELECT distinct  Machineinformation.interfaceid,  
                         sp.ShiftStart,sp.ShiftEnd,Machineinformation.Machineid,0,0,0,0,0,0,0,0,sp.Pdate,sp.Shift,0,0,0,0,0' --SV  
  select @strsql = @strsql + ' from machineinformation  '  
  select @strsql = @strsql + '  inner Join PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID '  
  select @strsql = @strsql + '   Cross join #ShiftDetails_SelPeriod sp where 1=1 and machineinformation.tpmtrakenabled=''1'''  
  select @strsql = @strsql +@strmachine+@StrMPlantID  
  select @strsql = @strsql + ' order by Machineinformation.Machineid'  
  print (@strsql)  
  exec (@strsql)  
  
  
  Select @strsql=''  
  select @strsql ='insert INTO #PlannedDownTimesShift(StartTime,EndTime,Machine,MachineInterface,  
      Downreason,Shiftst)'  
  select @strsql = @strsql + 'select '  
  select @strsql = @strsql + 'CASE When StartTime<T1.ShiftStart Then T1.ShiftStart Else StartTime End,'  
  select @strsql = @strsql + 'case When EndTime>T1.ShiftEnd Then T1.ShiftEnd Else EndTime End,'  
  select @strsql = @strsql + 'Machine,MachineInformation.InterfaceID,'  
  select @strsql = @strsql + 'DownReason,T1.ShiftStart'  
  select @strsql = @strsql + ' FROM PlannedDownTimes cross join #ShiftDetails_SelPeriod T1'  
  select @strsql = @strsql + ' inner join MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID'  
  select @strsql = @strsql + ' WHERE PDTstatus =1 and ( '  
  select @strsql = @strsql + '(StartTime >= T1.ShiftStart  AND EndTime <=T1.ShiftEnd)'  
  select @strsql = @strsql + 'OR ( StartTime < T1.ShiftStart  AND EndTime <= T1.ShiftEnd AND EndTime > T1.ShiftStart )'  
  select @strsql = @strsql + 'OR ( StartTime >= T1.ShiftStart   AND StartTime <T1.ShiftEnd AND EndTime > T1.ShiftEnd )'  
  select @strsql = @strsql + 'OR ( StartTime < T1.ShiftStart  AND EndTime > T1.ShiftEnd) )'  
  select @strsql = @strsql + @strmachine  
  select @strsql = @strsql + 'ORDER BY StartTime '  
  print (@strsql)  
  exec (@strsql)  
  
-- Utilized Time Calculation Type 1,2,3,4 -Starts here  
 UPDATE #ShiftProductionFromAutodata_ShiftBasis SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)  
 from  
  (select     mc,  
     sum(case when ( (autodata.msttime>=S.UstartShift) and (autodata.ndtime<=S.UEndShift)) then  (cycletime+loadunload)  
     when ((autodata.msttime<S.UstartShift)and (autodata.ndtime>S.UstartShift)and (autodata.ndtime<=S.UEndShift)) then DateDiff(second, S.UstartShift, ndtime)  
     when ((autodata.msttime>=S.UstartShift)and (autodata.msttime<S.UEndShift)and (autodata.ndtime>S.UEndShift)) then DateDiff(second, mstTime, S.UEndShift)  
     when ((autodata.msttime<S.UstartShift)and (autodata.ndtime>S.UEndShift)) then DateDiff(second, S.UstartShift, S.UEndShift) END ) as cycle,S.UstartShift as ShiftStart  
     from #T_autodata autodata --ER0393  
     inner join #ShiftProductionFromAutodata_ShiftBasis S on autodata.mc=S.MachineInterface  
     where (autodata.datatype=1) AND(( (autodata.msttime>=S.UstartShift) and (autodata.ndtime<=S.UEndShift))  
     OR ((autodata.msttime<S.UstartShift)and (autodata.ndtime>S.UstartShift)and (autodata.ndtime<=S.UEndShift))  
     OR ((autodata.msttime>=S.UstartShift)and (autodata.msttime<S.UEndShift)and (autodata.ndtime>S.UEndShift))  
     OR((autodata.msttime<S.UstartShift)and (autodata.ndtime>S.UEndShift)))  
     group by autodata.mc,S.UstartShift)   
   as t2 inner join #ShiftProductionFromAutodata_ShiftBasis on t2.mc = #ShiftProductionFromAutodata_ShiftBasis.machineinterface  
   and t2.ShiftStart=#ShiftProductionFromAutodata_ShiftBasis.UstartShift  
-- Utilized Time Calculation Type 1,2,3,4 -Ends here  
  
  
--Utilized Time with ICD Interaction   
  
  -------For Type2  
  UPDATE  #ShiftProductionFromAutodata_ShiftBasis SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)  
  FROM  
  (Select AutoData.mc ,  
  SUM(  
  CASE  
   When autodata.sttime <= T1.UstartShift Then datediff(s, T1.UstartShift,autodata.ndtime )  
   When autodata.sttime > T1.UstartShift Then datediff(s , autodata.sttime,autodata.ndtime)  
  END) as Down,t1.UstartShift as ShiftStart,T1.UDate as udate  
  From #T_autodata AutoData INNER Join--ER0393  
   (Select mc,Sttime,NdTime,UstartShift,UEndShift,udate From #T_autodata AutoData --ER0393  
    inner join #ShiftProductionFromAutodata_ShiftBasis ST1 ON ST1.MachineInterface=Autodata.mc  
    Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And  
    (msttime < UstartShift)And (ndtime > UstartShift) AND (ndtime <= UEndShift)  
  ) as T1 on t1.mc=autodata.mc  
  Where AutoData.DataType=2  
  And ( autodata.Sttime > T1.Sttime )  
  And ( autodata.ndtime <  T1.ndtime )  
  AND ( autodata.ndtime >  T1.UstartShift )  
  GROUP BY AUTODATA.mc,T1.UstartShift,T1.UDate)AS T2 Inner Join #ShiftProductionFromAutodata_ShiftBasis on t2.mc = #ShiftProductionFromAutodata_ShiftBasis.machineinterface  
  and T2.UDate = #ShiftProductionFromAutodata_ShiftBasis.UDate and t2.ShiftStart=#ShiftProductionFromAutodata_ShiftBasis.UstartShift  
  
   
  --For Type4  
  UPDATE #ShiftProductionFromAutodata_ShiftBasis SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)  
  FROM  
  (Select AutoData.mc ,  
  SUM(CASE  
   When autodata.sttime >= T1.UstartShift AND autodata.ndtime <= T1.UEndShift Then datediff(s , autodata.sttime,autodata.ndtime)  
   When autodata.sttime < T1.UstartShift And autodata.ndtime >T1.UstartShift AND autodata.ndtime<=T1.UEndShift Then datediff(s, T1.UstartShift,autodata.ndtime )  
   When autodata.sttime >= T1.UstartShift AND autodata.sttime<T1.UEndShift AND autodata.ndtime>T1.UEndShift Then datediff(s,autodata.sttime, T1.UEndShift )  
   When autodata.sttime<T1.UstartShift AND autodata.ndtime>T1.UEndShift   Then datediff(s , T1.UstartShift,T1.UEndShift)  
  END) as Down,T1.UstartShift as ShiftStart,T1.UDate as udate  
  From #T_autodata AutoData --ER0393  
  INNER Join  
   (Select mc,Sttime,NdTime,UstartShift,UEndShift,UDate From #T_autodata AutoData --ER0393  
    inner join #ShiftProductionFromAutodata_ShiftBasis ST1 ON ST1.MachineInterface =Autodata.mc  
    Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And  
    (msttime < UstartShift)And (ndtime >UEndShift)  
     
   ) as T1  
  ON AutoData.mc=T1.mc   
  Where AutoData.DataType=2  
  And (T1.Sttime < autodata.sttime  )  
  And ( T1.ndtime >  autodata.ndtime)  
  AND (autodata.ndtime  >  T1.UstartShift)  
  AND (autodata.sttime  <  T1.UEndShift)  
  GROUP BY AUTODATA.mc,T1.UstartShift,T1.UDate  
   )AS T2 Inner Join #ShiftProductionFromAutodata_ShiftBasis on t2.mc = #ShiftProductionFromAutodata_ShiftBasis.machineinterface  
  and T2.UDate = #ShiftProductionFromAutodata_ShiftBasis.UDate and t2.ShiftStart=#ShiftProductionFromAutodata_ShiftBasis.UstartShift  
  
    
  --Type 3  
  UPDATE  #ShiftProductionFromAutodata_ShiftBasis SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)  
  FROM  
  (Select AutoData.mc ,  
  SUM(CASE  
   When autodata.ndtime > T1.UEndShift Then datediff(s,autodata.sttime, T1.UEndShift )  
   When autodata.ndtime <=T1.UEndShift Then datediff(s , autodata.sttime,autodata.ndtime)  
  END) as Down,T1.UstartShift as ShiftStart,T1.Udate as Udate  
  From #T_autodata AutoData --ER0393  
   INNER Join  
   (Select mc,Sttime,NdTime,ustartshift,uendshift,udate From #T_autodata AutoData --ER0393  
    inner join #ShiftProductionFromAutodata_ShiftBasis ST1 ON ST1.MachineInterface =Autodata.mc  
    Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And  
    (sttime >= UstartShift)And (ndtime >UEndShift) and (sttime< UEndShift)  
   ) as T1  
  ON AutoData.mc=T1.mc   
  Where AutoData.DataType=2  
  And (T1.Sttime < autodata.sttime  )  
  And ( T1.ndtime >  autodata.ndtime)  
  AND (autodata.sttime  <  T1.UEndShift)  
  GROUP BY AUTODATA.mc,T1.UstartShift,T1.Udate )AS T2 Inner Join #ShiftProductionFromAutodata_ShiftBasis on t2.mc = #ShiftProductionFromAutodata_ShiftBasis.machineinterface  
  and t2.udate=#ShiftProductionFromAutodata_ShiftBasis.udate and t2.ShiftStart=#ShiftProductionFromAutodata_ShiftBasis.UstartShift  
  
  
  
  --Type 1 and 2  
  UPDATE #ShiftProductionFromAutodata_ShiftBasis SET CN = isnull(CN,0) + isNull(t2.C1N1,0)  
  from  
  (  
      select mc,S.UstartShift,  
      SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))*autodata.partscount) C1N1  
      From #T_autodata AutoData --ER0393  
   INNER JOIN  
   componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN  
   componentinformation ON autodata.comp = componentinformation.InterfaceID AND  
   componentoperationpricing.componentid = componentinformation.componentid  
   inner join machineinformation on machineinformation.interfaceid=autodata.mc  
   and componentoperationpricing.machineid=machineinformation.machineid  
   inner join #ShiftProductionFromAutodata_ShiftBasis S on autodata.mc=S.MachineInterface  
     where (autodata.ndtime>S.UstartShift)  
   and (autodata.ndtime<=S.UEndShift)  
   and (autodata.datatype=1) group by autodata.mc,S.UstartShift  
   ) as t2 inner join #ShiftProductionFromAutodata_ShiftBasis on t2.mc = #ShiftProductionFromAutodata_ShiftBasis.machineinterface  
     and t2.UstartShift=#ShiftProductionFromAutodata_ShiftBasis.UstartShift  
    
  
---Mod 12 Apply PDT for Utilized time and ICD's  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'  
BEGIN  
   
 --get the utilised time overlapping with PDT and negate it from UtilisedTime  
 UPDATE  #ShiftProductionFromAutodata_ShiftBasis SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.PlanDT,0)  
 ,PDT = isnull(PDT,0) + isNull(t2.PlanDT,0) --SV  
 from( select T.ShiftSt as intime,T.Machine as machine,sum (CASE  
 WHEN (autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN (cycletime+loadunload)  
 WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
 WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )  
 WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
 END ) as PlanDT  
 From #T_autodata AutoData --ER0393  
 CROSS jOIN #PlannedDownTimesShift T  
 WHERE autodata.DataType=1   and T.MachineInterface=autodata.mc AND(  
 (autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
 OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
 OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )  
 OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime)  
 )  
 group by T.Machine,T.ShiftSt ) as t2 inner join #ShiftProductionFromAutodata_ShiftBasis S on t2.intime=S.UstartShift and t2.machine=S.machineId  
   
---mod 12:Add ICD's Overlapping  with PDT to UtilisedTime  
 /* Fetching Down Records from Production Cycle  */  
  ---mod 12(4):Handle intearction between ICD and PDT for type 1 production record for the selected time period.  
  UPDATE  #ShiftProductionFromAutodata_ShiftBasis SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)  
  FROM (  
  Select T.ShiftSt as intime,AutoData.mc,  
  SUM(  
  CASE    
   When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1  
   When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2  
   When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3  
   when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4  
  END) as IPDT  
  From #T_autodata AutoData --ER0393  
  INNER Join  
   (Select mc,Sttime,NdTime,S.UstartShift as StartTime From #T_autodata AutoData --ER0393  
   inner join #ShiftProductionFromAutodata_ShiftBasis S on S.MachineInterface=autodata.mc  
   Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And  
    (msttime >= S.UstartShift) AND (ndtime <= S.UEndShift)) as T1  
  ON AutoData.mc=T1.mc CROSS jOIN #PlannedDownTimesShift T  
  Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc  
  And (( autodata.Sttime > T1.Sttime )  
  And ( autodata.ndtime <  T1.ndtime )  
  )  
  AND  
  ((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))  
  or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)  
  or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )  
  or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )  
  GROUP BY AUTODATA.mc,T.ShiftSt  
  )AS T2  INNER JOIN #ShiftProductionFromAutodata_ShiftBasis ON  
 T2.mc = #ShiftProductionFromAutodata_ShiftBasis.MachineInterface and  t2.intime=#ShiftProductionFromAutodata_ShiftBasis.UstartShift  
   
 ---mod 12(4)  
 /* If production  Records of TYPE-2*/  
 UPDATE  #ShiftProductionFromAutodata_ShiftBasis SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)  
 FROM  
 (Select T.ShiftSt as intime,AutoData.mc ,  
 SUM(  
 CASE    
  When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1  
  When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2  
  When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3  
  when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4  
 END) as IPDT  
 From #T_autodata AutoData --ER0393  
 CROSS jOIN #PlannedDownTimesShift T INNER Join  
  (Select mc,Sttime,NdTime,S.UstartShift as StartTime From #T_autodata AutoData --ER0393  
  inner join #ShiftProductionFromAutodata_ShiftBasis S on S.MachineInterface=autodata.mc  
   Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And  
   (msttime < S.UstartShift)And (ndtime > S.UstartShift) AND (ndtime <= S.UEndShift)) as T1  
 ON AutoData.mc=T1.mc  and T1.StartTime=T.ShiftSt  
 Where AutoData.DataType=2  and T.MachineInterface=autodata.mc  
 And (( autodata.Sttime > T1.Sttime )  
 And ( autodata.ndtime <  T1.ndtime )  
 AND ( autodata.ndtime >  T1.StartTime ))  
 AND  
 (( T.StartTime >= T1.StartTime )  
 And ( T.StartTime <  T1.ndtime ) )  
 GROUP BY AUTODATA.mc,T.ShiftSt )AS T2  INNER JOIN #ShiftProductionFromAutodata_ShiftBasis ON  
 T2.mc = #ShiftProductionFromAutodata_ShiftBasis.MachineInterface and  t2.intime=#ShiftProductionFromAutodata_ShiftBasis.UstartShift  
   
 /* If production Records of TYPE-3*/  
 UPDATE  #ShiftProductionFromAutodata_ShiftBasis SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)  
 FROM  
 (Select T.ShiftSt as intime,AutoData.mc ,  
 SUM(  
 CASE    
  When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1  
  When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2  
  When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3  
  when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4  
 END) as IPDT  
 From #T_autodata AutoData --ER0393  
  CROSS jOIN #PlannedDownTimesShift T INNER Join  
  (Select mc,Sttime,NdTime,S.UstartShift as StartTime,S.UEndShift as EndTime From #T_autodata AutoData --ER0393  
  inner join #ShiftProductionFromAutodata_ShiftBasis S on S.MachineInterface=autodata.mc  
  Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And  
  (sttime >= S.UstartShift)And (ndtime > S.UEndShift) and autodata.sttime <S.UEndShift) as T1  
 ON AutoData.mc=T1.mc and T1.StartTime=T.ShiftSt  
 Where AutoData.DataType=2  and T.MachineInterface=autodata.mc  
 And ((T1.Sttime < autodata.sttime  )  
 And ( T1.ndtime >  autodata.ndtime)  
 AND (autodata.sttime  <  T1.EndTime))  
 AND  
 (( T.EndTime > T1.Sttime )  
 And ( T.EndTime <=T1.EndTime ) )  
 GROUP BY AUTODATA.mc,T.ShiftSt)AS T2   INNER JOIN #ShiftProductionFromAutodata_ShiftBasis ON  
 T2.mc = #ShiftProductionFromAutodata_ShiftBasis.MachineInterface and  t2.intime=#ShiftProductionFromAutodata_ShiftBasis.UstartShift  
   
   
 /* If production Records of TYPE-4*/  
 UPDATE  #ShiftProductionFromAutodata_ShiftBasis SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)  
 FROM  
 (Select T.ShiftSt as intime,AutoData.mc ,  
 SUM(  
 CASE    
  When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1  
  When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2  
  When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3  
  when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4  
 END) as IPDT  
 From #T_autodata AutoData --ER0393   
 CROSS jOIN #PlannedDownTimesShift T INNER Join  
  (Select mc,Sttime,NdTime,S.UstartShift as StartTime,S.UEndShift as EndTime From #T_autodata AutoData --ER0393  
   inner join #ShiftProductionFromAutodata_ShiftBasis S on S.MachineInterface=autodata.mc  
   Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And  
   (msttime < S.UstartShift)And (ndtime > S.UEndShift)) as T1  
 ON AutoData.mc=T1.mc and T1.StartTime=T.ShiftSt  
 Where AutoData.DataType=2 and T.MachineInterface=autodata.mc  
 And ( (T1.Sttime < autodata.sttime  )  
  And ( T1.ndtime >  autodata.ndtime)  
  AND (autodata.ndtime  >  T1.StartTime)  
  AND (autodata.sttime  <  T1.EndTime))  
 AND  
 (( T.StartTime >=T1.StartTime)  
 And ( T.EndTime <=T1.EndTime ) )  
 GROUP BY AUTODATA.mc,T.ShiftSt)AS T2  INNER JOIN #ShiftProductionFromAutodata_ShiftBasis ON  
 T2.mc = #ShiftProductionFromAutodata_ShiftBasis.MachineInterface and  t2.intime=#ShiftProductionFromAutodata_ShiftBasis.UstartShift  
   
END  
  
  
---Mod 12 Apply PDT for Utilized time and ICD's  
---mod 12 Apply PDT for CN calculation  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
BEGIN  
 UPDATE #ShiftProductionFromAutodata_ShiftBasis SET CN = isnull(CN,0) - isNull(t2.C1N1,0)  
 From  
 (  
  select M.Machineid as machine,T.Shiftst as initime,SUM((O.cycletime * ISNULL(A.PartsCount,1))/ISNULL(O.SubOperations,1))  C1N1  
  From #T_autodata A --ER0393   
  inner join machineinformation M on A.mc=M.interfaceid  
  Inner join componentinformation C ON A.Comp=C.interfaceid  
        Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID  
  CROSS jOIN #PlannedDownTimesShift T  
  WHERE A.DataType=1 and T.MachineInterface=A.mc  
  AND(A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)  
  Group by M.Machineid,T.shiftst  
 ) as T2  
 inner join #ShiftProductionFromAutodata_ShiftBasis S  on t2.initime=S.UstartShift  and t2.machine = S.machineid  
END  
-- Apply PDT for CN calculation  
  
--Calculation of PartsCount Begins..  
UPDATE #ShiftProductionFromAutodata_ShiftBasis SET Qty = ISNULL(Qty,0) + ISNULL(t2.comp,0)  
From  
(  
 Select mc,S.UstartShift,S.UEndShift,SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp  
     From (select mc,autodata.ndtime,autodata.partscount as OrginalCount,comp,opn From #T_autodata AutoData --ER0393  
     where (autodata.ndtime>@TD_ST) and (autodata.ndtime<=@TD_ED) and (autodata.datatype=1)  
     ) as T1  
   
 Inner join componentinformation C on T1.Comp = C.interfaceid  
 Inner join ComponentOperationPricing O ON  T1.Opn = O.interfaceid and C.Componentid=O.componentid  
 inner join machineinformation on machineinformation.machineid =O.machineid  
 and T1.mc=machineinformation.interfaceid  
 inner join #ShiftProductionFromAutodata_ShiftBasis S on S.machineinterface=t1.mc  
 where t1.ndtime>S.UstartShift and t1.ndtime<=S.UEndShift  
 GROUP BY mc,S.UstartShift,S.UEndShift  
) As T2 Inner join #ShiftProductionFromAutodata_ShiftBasis on T2.mc = #ShiftProductionFromAutodata_ShiftBasis.machineinterface  
 and t2.UstartShift=#ShiftProductionFromAutodata_ShiftBasis.UstartShift  
  
--Apply Exception on Count..  
UPDATE #ShiftProductionFromAutodata_ShiftBasis SET Qty = ISNULL(Qty,0) - ISNULL(t2.comp,0)  
from  
( select MachineID,SUM(ExCount) as comp  
 From #Exceptions GROUP BY MachineID) as T2  
Inner join #ShiftProductionFromAutodata_ShiftBasis on T2.MachineID = #ShiftProductionFromAutodata_ShiftBasis.MachineID  
--Mod 4 Apply PDT for calculation of Count  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
BEGIN  
 UPDATE #ShiftProductionFromAutodata_ShiftBasis SET Qty = ISNULL(Qty,0) - ISNULL(T2.comp,0) from(  
  select mc,s.UstartShift,SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp From (  
   select mc,ndtime,PartsCount AS OrginalCount,comp,opn from autodata  
   CROSS JOIN #PlannedDownTimesShift T  
   WHERE autodata.DataType=1 And T.MachineInterface = autodata.mc  
   AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)  
   AND (autodata.ndtime > @TD_ST  AND autodata.ndtime <=@TD_ED)  
      --Group by mc,comp,opn  
  ) as T1  
 inner join #ShiftProductionFromAutodata_ShiftBasis S on  S.machineinterface=t1.mc  
 Inner join Machineinformation M on S.machineinterface = T1.mc  
 Inner join componentinformation C on T1.Comp=C.interfaceid  
 Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineID = M.MachineID  
 where t1.ndtime>S.UstartShift and t1.ndtime<=S.UEndShift  
 GROUP BY MC,S.UstartShift--,S.UEndShift  
 ) as T2 inner join #ShiftProductionFromAutodata_ShiftBasis on T2.mc = #ShiftProductionFromAutodata_ShiftBasis.machineinterface  
and t2.UstartShift=#ShiftProductionFromAutodata_ShiftBasis.UstartShift  
END  
--------------------------------------------Down Record----------------------------------------------------  
---Below IF condition added by Mrudula for mod 12. TO get the ML and Down if 'Ignore_Dtime_4m_PLD'<>"Y"  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_
4m_PLD')<>'Y')  
BEGIN  
 --Type 1  
 UPDATE #ShiftProductionFromAutodata_ShiftBasis SET downtime = isnull(downtime,0) + isNull(t2.down,0)  
 from  
 (select mc,  
  sum(loadunload) down,S.UstartShift as ShiftStart  
 From #T_autodata AutoData --ER0393  
 inner join #ShiftProductionFromAutodata_ShiftBasis S on autodata.mc=S.MachineInterface  
 where (autodata.msttime>=S.UstartShift)  
 and (autodata.ndtime<= S.UEndShift)  
 and (autodata.datatype=2)  
 group by autodata.mc,S.UstartShift  
 ) as t2 inner join #ShiftProductionFromAutodata_ShiftBasis on t2.mc = #ShiftProductionFromAutodata_ShiftBasis.machineinterface  
 and t2.ShiftStart=#ShiftProductionFromAutodata_ShiftBasis.UstartShift  
   
 -- Type 2  
 UPDATE #ShiftProductionFromAutodata_ShiftBasis SET downtime = isnull(downtime,0) + isNull(t2.down,0)  
 from  
 (select mc,  
  sum(DateDiff(second, S.UstartShift, ndtime)) down,S.UstartShift as ShiftStart  
 From #T_autodata AutoData --ER0393  
 inner join #ShiftProductionFromAutodata_ShiftBasis S on autodata.mc=S.MachineInterface  
 where (autodata.sttime<S.UstartShift)  
 and (autodata.ndtime>S.UstartShift)  
 and (autodata.ndtime<= S.UEndShift)  
 and (autodata.datatype=2)  
 group by autodata.mc,S.UstartShift  
 ) as t2 inner join #ShiftProductionFromAutodata_ShiftBasis on t2.mc = #ShiftProductionFromAutodata_ShiftBasis.machineinterface  
 and t2.ShiftStart=#ShiftProductionFromAutodata_ShiftBasis.UstartShift  
   
   
 -- Type 3  
 UPDATE #ShiftProductionFromAutodata_ShiftBasis SET downtime = isnull(downtime,0) + isNull(t2.down,0)  
 from  
 (select mc,  
  sum(DateDiff(second, stTime,  S.UEndShift)) down,S.UstartShift as ShiftStart  
 From #T_autodata AutoData --ER0393  
 inner join #ShiftProductionFromAutodata_ShiftBasis S on autodata.mc=S.MachineInterface  
 where (autodata.msttime>=S.UstartShift)  
 and (autodata.sttime< S.UEndShift)  
 and (autodata.ndtime> S.UEndShift)  
 and (autodata.datatype=2)group by autodata.mc,S.Udate,S.UstartShift  
 ) as t2 inner join #ShiftProductionFromAutodata_ShiftBasis on t2.mc = #ShiftProductionFromAutodata_ShiftBasis.machineinterface  
 and t2.ShiftStart=#ShiftProductionFromAutodata_ShiftBasis.UstartShift  
   
   
 -- Type 4  
 UPDATE #ShiftProductionFromAutodata_ShiftBasis SET downtime = isnull(downtime,0) + isNull(t2.down,0)  
 from  
 (select mc,  
  sum(DateDiff(second, S.UstartShift,  S.UEndShift)) down,S.UstartShift as ShiftStart  
 From #T_autodata AutoData --ER0393  
 inner join #ShiftProductionFromAutodata_ShiftBasis S on autodata.mc=S.MachineInterface  
 where autodata.msttime<S.UstartShift  
 and autodata.ndtime> S.UEndShift  
 and (autodata.datatype=2)group by autodata.mc,S.Udate,S.UstartShift  
 ) as t2 inner join #ShiftProductionFromAutodata_ShiftBasis on t2.mc = #ShiftProductionFromAutodata_ShiftBasis.machineinterface  
 and t2.ShiftStart=#ShiftProductionFromAutodata_ShiftBasis.UstartShift  
 --END: Get the Down Time  
 ---Management Loss-----  
 -- Type 1  
 UPDATE #ShiftProductionFromAutodata_ShiftBasis SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)  
 from  
 (select      mc,  
  sum(CASE  
 WHEN loadunload >ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)  
 ELSE loadunload  
 END) loss,S.UstartShift as ShiftStart  
 From #T_autodata AutoData --ER0393  
 INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid inner join #ShiftProductionFromAutodata_ShiftBasis S on autodata.mc=S.MachineInterface  
 where (autodata.msttime>=S.UstartShift)  
 and (autodata.ndtime<=S.UEndShift)  
 and (autodata.datatype=2)  
 and (downcodeinformation.availeffy = 1)  
 group by autodata.mc,S.UstartShift  
 ) as t2 inner join #ShiftProductionFromAutodata_ShiftBasis on t2.mc = #ShiftProductionFromAutodata_ShiftBasis.machineinterface  
 and t2.ShiftStart=#ShiftProductionFromAutodata_ShiftBasis.UstartShift  
 -- Type 2  
 UPDATE #ShiftProductionFromAutodata_ShiftBasis SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)  
 from  
 (select      mc,  
  sum(CASE  
 WHEN DateDiff(second, S.UstartShift, ndtime)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)  
 ELSE DateDiff(second, S.UstartShift, ndtime)  
 end) loss,S.UstartShift as ShiftStart  
 From #T_autodata AutoData --ER0393  
 INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid inner join #ShiftProductionFromAutodata_ShiftBasis S on autodata.mc=S.MachineInterface  
 where (autodata.sttime<S.UstartShift)  
 and (autodata.ndtime>S.UstartShift)  
 and (autodata.ndtime<=S.UEndShift)  
 and (autodata.datatype=2)  
 and (downcodeinformation.availeffy = 1)  
 group by autodata.mc,S.Udate,S.UstartShift  
 ) as t2 inner join #ShiftProductionFromAutodata_ShiftBasis on t2.mc = #ShiftProductionFromAutodata_ShiftBasis.machineinterface  
 and t2.ShiftStart=#ShiftProductionFromAutodata_ShiftBasis.UstartShift  
 -- Type 3  
 UPDATE #ShiftProductionFromAutodata_ShiftBasis SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)  
 from  
 (select      mc,  
  sum(CASE  
 WHEN DateDiff(second, stTime, S.UEndShift)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)ELSE DateDiff(second, stTime, S.UEndShift)  
 END) loss,S.UstartShift as ShiftStart  
 From #T_autodata AutoData --ER0393  
 INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid inner join #ShiftProductionFromAutodata_ShiftBasis S on autodata.mc=S.MachineInterface  
 where (autodata.msttime>=S.UstartShift)  
 and (autodata.sttime<S.UEndShift)  
 and (autodata.ndtime>S.UEndShift)  
 and (autodata.datatype=2)  
 and (downcodeinformation.availeffy = 1)  
 group by autodata.mc,S.UstartShift  
 ) as t2 inner join #ShiftProductionFromAutodata_ShiftBasis on t2.mc = #ShiftProductionFromAutodata_ShiftBasis.machineinterface  
 and t2.ShiftStart=#ShiftProductionFromAutodata_ShiftBasis.UstartShift  
 -- Type 4  
 UPDATE #ShiftProductionFromAutodata_ShiftBasis SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)  
 from  
 (select mc,  
  sum(CASE  
 WHEN DateDiff(second, S.UstartShift, S.UEndShift)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)  
 ELSE DateDiff(second, S.UstartShift, S.UEndShift)  
 END) loss,S.UstartShift as ShiftStart  
 From #T_autodata AutoData --ER0393  
 INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid inner join #ShiftProductionFromAutodata_ShiftBasis S on autodata.mc=S.MachineInterface  
 where autodata.msttime<S.UstartShift  
 and autodata.ndtime>S.UEndShift  
 and (autodata.datatype=2)  
 and (downcodeinformation.availeffy = 1)  
 group by autodata.mc,S.UstartShift  
 ) as t2 inner join #ShiftProductionFromAutodata_ShiftBasis on t2.mc = #ShiftProductionFromAutodata_ShiftBasis.machineinterface  
 and t2.ShiftStart=#ShiftProductionFromAutodata_ShiftBasis.UstartShift  
  
  
 if (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y'  
 begin  
    
  UPDATE #ShiftProductionFromAutodata_ShiftBasis SET downtime = isnull(downtime,0) - isNull(t2.PldDown,0)  
  ,PDT=isnull(PDT,0) + isNull(t2.PldDown,0) --SV  
  from(  
  select T.Shiftst  as intime,T.Machine as machine,SUM  
         (CASE  
   WHEN (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN autodata.loadunload  
   WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
   WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )  
   WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
   END ) as PldDown  
  From #T_autodata AutoData --ER0393  
  CROSS jOIN #PlannedDownTimesShift T  
  INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID  
  WHERE autodata.DataType=2  and T.MachineInterface=autodata.mc  AND(  
  (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
  OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
  OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )  
  OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  
  )  
  AND DownCodeInformation.DownID=(SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')  
  group by T.Machine,T.ShiftSt ) as t2 inner join #ShiftProductionFromAutodata_ShiftBasis S on t2.intime=S.UstartShift and t2.machine=S.machineId  
   
 end  
---mod 12  
END  
---mod 12  
---mod 12:Get the down time and Management loss when setting for 'Ignore_Dtime_4m_PLD'='Y'  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
BEGIN  
 ---Get the down times which are not of type Management Loss  
 UPDATE #ShiftProductionFromAutodata_ShiftBasis SET downtime = isnull(downtime,0) + isNull(t2.down,0)  
 from  
 (select      mc,  
  sum(case when ( (autodata.msttime>=S.UstartShift) and (autodata.ndtime<=S.UEndShift)) then  loadunload  
    when ((autodata.sttime<S.UstartShift)and (autodata.ndtime>S.UstartShift)and (autodata.ndtime<=S.UEndShift)) then DateDiff(second, S.UstartShift, ndtime)  
    when ((autodata.msttime>=S.UstartShift)and (autodata.msttime<S.UEndShift)and (autodata.ndtime>S.UEndShift)) then DateDiff(second, stTime, S.UEndShift)  
    when ((autodata.msttime<S.UstartShift)and (autodata.ndtime>S.UEndShift)) then DateDiff(second, S.UstartShift, S.UEndShift) END ) as down,S.UstartShift as ShiftStart  
   From #T_autodata AutoData --ER0393  
  inner join #ShiftProductionFromAutodata_ShiftBasis S on autodata.mc=S.MachineInterface  
    inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid  
 where (autodata.datatype=2) AND(( (autodata.msttime>=S.UstartShift) and (autodata.ndtime<=S.UEndShift))  
       OR ((autodata.msttime<S.UstartShift)and (autodata.ndtime>S.UstartShift)and (autodata.ndtime<=S.UEndShift))  
       OR ((autodata.msttime>=S.UstartShift)and (autodata.msttime<S.UEndShift)and (autodata.ndtime>S.UEndShift))  
       OR((autodata.msttime<S.UstartShift)and (autodata.ndtime>S.UEndShift))) AND (downcodeinformation.availeffy = 0)  
       group by autodata.mc,S.UstartShift  
 ) as t2 inner join #ShiftProductionFromAutodata_ShiftBasis on t2.mc = #ShiftProductionFromAutodata_ShiftBasis.machineinterface  
 and t2.ShiftStart=#ShiftProductionFromAutodata_ShiftBasis.UstartShift  
   
 UPDATE #ShiftProductionFromAutodata_ShiftBasis SET downtime = isnull(downtime,0) - isNull(t2.PldDown,0)  
 ,PDT=isnull(PDT,0) + isNull(t2.PldDown,0) --SV  
 from(  
  select T.Shiftst  as intime,T.Machine as machine,SUM  
         (CASE  
   WHEN (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN autodata.loadunload  
   WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
   WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )  
   WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
   END ) as PldDown  
  From #T_autodata AutoData --ER0393  
  CROSS jOIN #PlannedDownTimesShift T  
  INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID  
  WHERE autodata.DataType=2  and T.MachineInterface=autodata.mc  AND(  
  (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
  OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
  OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )  
  OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  
  )  
  AND (downcodeinformation.availeffy = 0)  
  group by T.Machine,T.ShiftSt ) as t2 inner join #ShiftProductionFromAutodata_ShiftBasis S on t2.intime=S.UstartShift and t2.machine=S.machineId  
   
   
 UPDATE #ShiftProductionFromAutodata_ShiftBasis SET ManagementLoss = isnull(ManagementLoss,0)+ isNull(t4.Mloss,0),MLDown=isNull(MLDown,0)+isNull(t4.Dloss,0)  
 ,PDT=isnull(PDT,0) + isnull(T4.PPDT,0)  
 from  
 (select T3.mc,T3.StrtShft,sum(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss   
    ,sum(T3.PPDT) as PPDT   
 from  
  (  
 select   t1.id,T1.mc,T1.Threshold,T1.StartShift as StrtShft,  
 case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0) > 0  
 then DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)- isnull(T1.Threshold ,0)  
 else 0 End  as Dloss,  
 case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0) > 0  
 then isnull(T1.Threshold,0)  
 else DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0) End  as Mloss  
 ,isnull(T2.PPDT,0)as PPDT --SV  
  from  
   
 (   select id,mc,comp,opn,opr,D.threshold,S.UstartShift as StartShift,  
  case when autodata.sttime<S.UstartShift then S.UstartShift else sttime END as sttime,  
         case when ndtime>S.UEndShift then S.UEndShift else ndtime END as ndtime  
  From #T_autodata AutoData --ER0393  
  inner join downcodeinformation D  
  on autodata.dcode=D.interfaceid inner join #ShiftProductionFromAutodata_ShiftBasis S on autodata.mc=S.MachineInterface  
  where autodata.datatype=2 AND  
  (  
  (autodata.msttime>=S.UstartShift  and  autodata.ndtime<=S.UEndShift)  
  OR (autodata.sttime<S.UstartShift and  autodata.ndtime>S.UstartShift and autodata.ndtime<=S.UEndShift)  
  OR (autodata.msttime>=S.UstartShift  and autodata.sttime<S.UEndShift  and autodata.ndtime>S.UEndShift)  
  OR (autodata.msttime<S.UstartShift and autodata.ndtime>S.UEndShift )  
  ) AND (D.availeffy = 1)) as T1    
 left outer join  
 (SELECT T.Shiftst  as intime, autodata.id,  
         sum(CASE  
   WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)  
   WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
   WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )  
   WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
   END ) as PPDT  
  From #T_autodata AutoData --ER0393  
   CROSS jOIN #PlannedDownTimesShift T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid  
  WHERE autodata.DataType=2 and T.MachineInterface=autodata.mc AND  
   (  
   (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
   OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
   OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )  
   OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  
   )  
    AND (downcodeinformation.availeffy = 1) group by autodata.id,T.Shiftst ) as T2 on T1.id=T2.id  and T1.StartShift=T2.intime ) as T3  group by T3.mc,T3.StrtShft  
 ) as t4 inner join #ShiftProductionFromAutodata_ShiftBasis S on t4.StrtShft=S.UstartShift and t4.mc=S.MachineInterface  
 UPDATE #ShiftProductionFromAutodata_ShiftBasis  set downtime = isnull(downtime,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)  
   
END  
------------------------------ : End Downtime and ML calculation  : --------------------------------------------------------  
  
  
  
  
UPDATE #ShiftProductionFromAutodata_ShiftBasis SET turnover = isnull(turnover,0) + isNull(t2.revenue,0)  
from  
(select mc,S.UstartShift,S.UEndShift,  
SUM((componentoperationpricing.price/ISNULL(ComponentOperationPricing.SubOperations,1))* ISNULL(autodata.partscount,1)) revenue  
From #T_autodata AutoData --ER0393  
INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID  
INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID AND componentoperationpricing.componentid = componentinformation.componentid  
inner join machineinformation on componentoperationpricing.machineid=machineinformation.machineid  
AND autodata.mc = machineinformation.interfaceid  
inner join #ShiftProductionFromAutodata_ShiftBasis S on S.machineinterface=autodata.mc   
where (  
(autodata.sttime>=S.UstartShift and autodata.ndtime<=S.UEndShift)OR  
(autodata.sttime<S.UstartShift and autodata.ndtime>S.UstartShift and autodata.ndtime<=S.UEndShift))and (autodata.datatype=1)  
  
group by autodata.mc,S.UstartShift,S.UEndShift  
) as t2   
inner join #ShiftProductionFromAutodata_ShiftBasis on t2.mc = #ShiftProductionFromAutodata_ShiftBasis.machineinterface  
and t2.UEndShift=#ShiftProductionFromAutodata_ShiftBasis.UEndShift  
  
  
--Excluding Exception count from turnover calculation  
UPDATE #ShiftProductionFromAutodata_ShiftBasis SET Turnover = ISNULL(Turnover,0) - ISNULL(t2.xTurnover,0)  
from  
( select Ex.MachineID,  
SUM((O.price)* ISNULL(ExCount,0)) as xTurnover  
From #Exceptions Ex  
  
INNER JOIN ComponentOperationPricing O ON   
---mod 2  
 O.machineid = Ex.machineid  
---mod 2  
GROUP BY Ex.MachineID) as T2  
Inner join #ShiftProductionFromAutodata_ShiftBasis on T2.MachineID = #ShiftProductionFromAutodata_ShiftBasis.MachineID  
  
--Mod 4 Apply PDT for TurnOver Calculation.  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
BEGIN  
 UPDATE #ShiftProductionFromAutodata_ShiftBasis SET turnover = isnull(turnover,0) - isNull(t2.revenue,0)  
 From  
 (  
  select mc,S.UStartShift,S.UEndShift,SUM((O.price * ISNULL(A.PartsCount,1))/ISNULL(O.SubOperations,1))as revenue  
  From #T_autodata A --ER0393  
  inner join #ShiftProductionFromAutodata_ShiftBasis S on S.machineinterface=A.mc   
  Inner join machineinformation M on M.interfaceid=A.mc  
  Inner join componentinformation C ON A.Comp=C.interfaceid  
  Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID  
  CROSS jOIN #PlannedDownTimesShift T  
  WHERE A.DataType=1 And T.MachineInterface = A.mc  
  AND(A.ndtime > T.Starttime  AND A.ndtime <=T.Endtime)  
  AND(A.ndtime > S.UStartShift  AND A.ndtime <=S.UEndShift)  
  Group by mc,S.UStartShift,S.UEndShift  
 ) as T2  
 inner join #ShiftProductionFromAutodata_ShiftBasis  on t2.mc = #ShiftProductionFromAutodata_ShiftBasis.machineinterface  
and t2.UStartShift=#ShiftProductionFromAutodata_ShiftBasis.UStartShift  
END  
  
  
If @param = '' --ER0393 Added IF  
BEGIN          --ER0393 Added IF  
  
 Select S.Machineid,(case when UtilisedTime>0 then cn/UtilisedTime else 0 end)*100 as PE,  
 (case when ae>0 and UtilisedTime>0 then UtilisedTime/ae else 0 end) * 100 As AE,  
 (case when UtilisedTime>0 then cn/UtilisedTime else 0 end)*(case when ae>0 and UtilisedTime>0 then UtilisedTime/ae else 0 end)* 100 AS OEE,T1.QTY,  
 dbo.f_FormatTime(T1.UtilisedTime,@timeformat) as UtilisedTime,dbo.f_FormatTime(T1.UtilisedTime,'hh:mm:ss') as strUtilisedTime,  
 dbo.f_FormatTime(T1.DownTime,@timeformat) as DownTime,dbo.f_FormatTime(T1.DownTime,'hh:mm:ss') as strDownTime,  
 dbo.f_FormatTime(T1.ManagementLoss,@timeformat) as ManagementLoss,dbo.f_FormatTime(T1.ManagementLoss,'hh:mm:ss') as strManagementLoss,  
 T1.TurnOver,(case when UtilisedTime>0 then (TurnOver/UtilisedTime)*3600 else 0 end)as RET,T1.RETTOT  
 from (select distinct machineid,machineinterface from   
 #ShiftProductionFromAutodata_ShiftBasis) S  
 left outer join   
 (  
 select Machineid,machineinterface,sum(CN) as CN,  
 (SUM(UtilisedTime) + sum(DownTime) - sum(ManagementLoss)) as AE,  
 --0  as AE,  
 --(sum(TurnOver)/SUM(UtilisedTime))*3600 as RET,  
 sum(TurnOver) as TurnOver,  
 (sum(TurnOver)/@Duration)*3600 as RETTOT   
 ,sum(qty) as qty  
 ,SUM(UtilisedTime) as UtilisedTime   
 ,sum(DownTime) as DownTime  
 ,sum(ManagementLoss) as ManagementLoss  
 from  #ShiftProductionFromAutodata_ShiftBasis  
 --where UtilisedTime<>0   
 group by machineinterface,Machineid   
   
 ) t1 on  
 t1.machineinterface=S.machineinterface   
END --ER0393 Added IF  
--ER0393 Added From Here  
ELSE If @param = 'Shiftwise'  
BEGIN  
  
 UPDATE #ShiftProductionFromAutodata_ShiftBasis SET  
 ProductionEfficiency = (CN/UtilisedTime) ,  
 AvailabilityEfficiency = (UtilisedTime)/(UtilisedTime + DownTime - ManagementLoss) WHERE UtilisedTime <> 0  
  
 Select S.Udate,S.UShift,S.Machineid,  
 dbo.f_FormatTime(S.UtilisedTime,@timeformat) as UtilisedTime,  
 dbo.f_FormatTime((S.DownTime-S.ManagementLoss),@timeformat) as DownTime,  
 dbo.f_FormatTime(S.ManagementLoss,@timeformat) as ManagementLoss,S.PDT as PDT,S.QTY,  
 ProductionEfficiency * 100 as PE,  
 AvailabilityEfficiency * 100 As AE,(ProductionEfficiency * AvailabilityEfficiency)*100 as OEE from   
 #ShiftProductionFromAutodata_ShiftBasis S   
 --where (S.UtilisedTime<>0 and S.DownTime<>0 and S.ManagementLoss<>0)   --DR0379 commented
 Order by S.Udate,S.UShift,S.Machineid  
END   
--ER0393 Added Till Here  
  
End  
  
  
