/****** Object:  Procedure [dbo].[s_GetWiproSantoor_ProdDownReport]    Committed by VersionSQL https://www.versionsql.com ******/

 
/******************************************************************************************** 
--ER0439 - SwathiKS - 22/Nov/2016 :: Created New Procedure To show M-C-O-O Level Hourly Partscount and Downtime and ShiftLevel Qty,Target,Rejection and Efficiency.  
--DR0374 - SwathiKS - 15/Mar/2017 :: To handle Rejections were not showing in report in Email process.  
--DR0379 - SwathiKS - 07/Dec/2017 :: To handle error "Merging cells" for spf.
--ER0459 - SwathiKS - 09/Feb/2018 :: To display resultset in the order.
--DR0383 - SwathiKS - 24/Apr/2018 :: To handle ShiftTarget and HourlyTarget Mismatch for wipro Santoor.
--DR0386 - SwathiKS - 27/Jul/2018 :: To Fix Total DaywiseRejectionQty was not matching with Shiftwise RejQty for wipro Santoor.

--[dbo].[s_GetWiproSantoor_ProdDownReport] '2017-12-01 06:00:00','2017-12-01 14:00:00','''A''','','','ProductionRejection','schservice'  
--exec [s_GetWiproSantoor_ProdDownReport] @StartDate=N'2018-01-01 06:00:00',@Enddate=N'2018-01-03 06:00:00',@ShiftIn=N'',@PlantID=N'',@MachineID=N'',@RptProd_down=N'ProductionRejection',@Param=N''  
***********************************************************************************************/

  CREATE PROCEDURE [dbo].[s_GetWiproSantoor_ProdDownReport]  
 @StartDate datetime,  
 @Enddate datetime,  
 @ShiftIn nvarchar(20)='',  
 @PlantID nvarchar(50) = '',  
 @MachineID nvarchar(50) = '',  
 @RptProd_down nvarchar(50)='Production', --'ProductionRejection' --ER0327 Added  
 @Param nvarchar(50)=''  
  
WITH RECOMPILE  
AS  
BEGIN --PROC  
  
  
SET NOCOUNT ON;  
  
Create Table #HourlyData    
 (   
 SLNO int,  
 PDate datetime,  
 ShiftName nvarchar(20),  
 ShiftID int,  
 Shiftstart datetime,  
 ShiftEnd datetime,  
 HourName nvarchar(50),  
 HourID int,  
 FromTime datetime,  
 ToTime Datetime  
 )   
  
  
--Shift Details  
CREATE TABLE #ShiftDetails_SelPeriod (  
 PDate datetime,  
 Shift nvarchar(20),  
 ShiftStart datetime,  
 ShiftEnd datetime,  
 Shiftid int  
)  
  
  
Create Table #Base_Prod_ctn_Temp  
(   
 Sdate datetime,  
 Machineid nvarchar(50),  
 ComponentId nvarchar(50),  
 Operationno int,  
 Operatorid nvarchar(150),  
 machineinterface nvarchar(50),    
 Compinterface nvarchar(50),    
 OpnInterface nvarchar(50),    
 OprInterface nvarchar(50),  
 ShiftName nvarchar(20),  
 ShiftID int,  
 ShiftStartTime datetime,  
 ShiftEndTime datetime,  
 HourID nvarchar(50),  
 FromTime datetime,  
 ToTime Datetime,  
 Actual float default(0),  
 Target float default(0),  
 Hourlytarget float default(0),  
 ShftActualCount float default(0),  
 RejCount float default(0),   
 HourlyDowntime float default(0),  
 MachinewiseDowntime float default(0),  
 MachinewiseAE float default(0),  
 MachinewisePE float default(0),  
 MachinewiseOEE float default(0),  
 MachinewiseQE float default(0),  
 DaywiseAE float default(0),  
 DaywisePE float default(0),  
 DaywiseOEE float default(0),  
 DaywiseQE float default(0),  
 DaywiseDowntime float default(0),  
 DaywiseRejQty float default(0),  
 Hour1Actual float default(0),  
 Hour2Actual float default(0),  
 Hour3Actual float default(0),  
 Hour4Actual float default(0),  
 Hour5Actual float default(0),  
 Hour6Actual float default(0),  
 Hour7Actual float default(0),  
 Hour8Actual float default(0),  
 Hour1DT float default(0),  
 Hour2DT float default(0),  
 Hour3DT float default(0),  
 Hour4DT float default(0) ,  
 Hour5DT float default(0),  
 Hour6DT float default(0),  
 Hour7DT float default(0),  
 Hour8DT float default(0), 
	sttime datetime --ER0459
)  
  
  
create table #Machcomopnopr  
(  
 Machine nvarchar(50) NOT NULL,  
 Machineint nvarchar(50),  
 Component nvarchar(50) NOT NULL,  
 CompInt nvarchar(50),  
 Operation nvarchar(50) NOT NULL,  
 opnInt nvarchar(50),  
 Operator nvarchar(50),  
 Oprint nvarchar(50),  
 Shdate datetime not null,  
 ShftName nvarchar(50),  
 ShftStrt datetime not null,  
 ShftND datetime not null,  
 Shiftid int,
 sttime datetime --ER0459  
)  
  
--Machine level details  
CREATE TABLE #ShiftProductionFromAutodata_ShiftBasis   
(  
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
 Udate datetime,  
 Ushift nvarchar(50),   
 MLDown float,  
 TurnOver float,  
 ReturnPerHour float,  
 ReturnPerHourtotal float,  
 PDT float --ER0459  
   
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
  
  
DECLARE @strsql as varchar(4000)  
DECLARE @Targetsource as nvarchar(100)  
DECLARE @stdate as nvarchar(25)  
declare @ExactStdate as datetime  
declare @TmpStartdate as datetime  
declare @TmpEnddate as datetime  
  
declare @StartTime as datetime  
declare @EndTime as datetime  
declare @CurStrtTime as datetime  
declare @CurEndTime as datetime  
select @CurStrtTime=@StartDate  
select @CurEndTime=@EndDate  
  
  
declare @TD_ST as datetime  
declare @TD_ED as datetime  
  
select @stdate = CAST(datePart(yyyy,@StartDate) AS nvarchar(4)) + '-' + CAST(datePart(mm,@StartDate) AS nvarchar(2)) + '-' + CAST(datePart(dd,@StartDate) AS nvarchar(2))  
select @ExactStdate=convert(datetime, cast(DATEPART(yyyy,@StartDate)as nvarchar(4))+'-'+cast(datepart(mm,@StartDate)as nvarchar(2))+'-'+cast(datepart(dd,@StartDate)as nvarchar(2)) +' 00:00:00.000')  
  
set @TmpStartdate=  Cast([dbo].[f_GetLogicalDay](@startdate,'START') as datetime)  
set @TmpEnddate= Cast([dbo].[f_GetLogicalDay](@Enddate,'END') as datetime )  
  
declare @strmachine nvarchar(255)  
declare @timeformat as nvarchar(2000)  
Declare @StrMPlantID AS NVarchar(255)  
Declare @shiftname as nvarchar(50)  
  
select @strsql = ''  
select @strmachine = ''  
Select @StrMPlantID=''  
Select @shiftname=''  
SELECT @timeformat ='ss'  
  
--Select @timeformat = isnull((select valueintext from cockpitdefaults where parameter='timeformat'),'ss')  
--if (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')  
--begin  
-- select @timeformat = 'ss'  
--end  
--Select @timeformat = 'mm'  
  
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
end  
  
--Get Shift Start and Shift End  
while @CurStrtTime<=@EndDate  
BEGIN  
 INSERT #ShiftDetails_SelPeriod(Pdate, Shift, ShiftStart, ShiftEnd)  
 EXEC s_GetShiftTime @CurStrtTime,''  
   
 SELECT @CurStrtTime=DATEADD(DAY,1,@CurStrtTime)  
END  
  
Update #ShiftDetails_SelPeriod set Shiftid = T.Shiftid from  
(Select shiftdetails.Shiftid,shiftdetails.Shiftname from shiftdetails inner join #ShiftDetails_SelPeriod on #ShiftDetails_SelPeriod.Shift=shiftdetails.Shiftname  
where running=1)T inner join #ShiftDetails_SelPeriod on #ShiftDetails_SelPeriod.Shift=T.Shiftname  
  
IF @SHIFTIN <>''  
Begin  
 select @strsql=''  
 Select @strsql = @strsql + 'DELETE FROM #ShiftDetails_SelPeriod WHERE SHIFT NOT IN('+ @SHIFTIN + ')'  
 print @strsql  
 exec(@strsql)  
End  
  
Select @TD_ST=min(ShiftStart) from #ShiftDetails_SelPeriod  
Select @TD_ED=max(ShiftEnd) from #ShiftDetails_SelPeriod  
  
  
  
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
  
  
if @RptProd_down='ProductionRejection'  
Begin  
  
  
   Select @strsql=''  
   select @strsql ='insert into #ShiftProductionFromAutodata_ShiftBasis (MachineInterface,UstartShift,UEndShift,MachineID  
        ,ProductionEfficiency, AvailabilityEfficiency ,  
        OverallEfficiency, UtilisedTime, ManagementLoss, DownTime,Qty, CN,Udate,Ushift,MLDown , TurnOver,    ReturnPerHour,    ReturnPerHourtotal ,PDT ) ' --ER0459  
   select @strsql = @strsql + 'SELECT distinct  Machineinformation.interfaceid,  
        sp.ShiftStart,sp.ShiftEnd,Machineinformation.Machineid,0,0,0,0,0,0,0,0,sp.Pdate,sp.Shift,0,0,0,0,0' --ER0459  
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
  
   Select @strsql=''  
   select @strsql ='insert into #Machcomopnopr(Machine,MachineInt,Component,CompInt,Operation,OpnInt,Operator,Oprint,Shdate,  
      ShftName,ShftStrt,ShftND,sttime) '  --ER0459
   select @strsql = @strsql + 'SELECT distinct  Machineinformation.Machineid,Machineinformation.interfaceid,  
      componentinformation.componentid,componentinformation.interfaceid,componentoperationpricing.operationno,  
      componentoperationpricing.interfaceid,Employeeinformation.Employeeid,Employeeinformation.interfaceid, Pdate, Shift, ShiftStart, ShiftEnd,max(sttime) '   --ER0459
   select @strsql = @strsql + ' from #T_autodata autodata inner join machineinformation on machineinformation.interfaceid=autodata.mc inner join ' --ER0324 Added #T_autodata  
   select @strsql = @strsql + ' componentinformation ON autodata.comp = componentinformation.InterfaceID  INNER JOIN '  
   select @strsql = @strsql + ' componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID)'  
   select @strsql = @strsql + ' AND (componentinformation.componentid = componentoperationpricing.componentid) '  
   ---mod 7  
   select @strsql = @strsql + ' and componentoperationpricing.machineid=machineinformation.machineid '  
   ---mod 7  
   select @strsql = @strsql + ' inner join employeeinformation on autodata.opr=employeeinformation.interfaceid'  
   select @strsql = @strsql + ' Left Outer Join PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID '  
   select @strsql = @strsql + ' cross join #ShiftDetails_SelPeriod where '  
   select @strsql = @strsql + '(( sttime >= shiftstart and ndtime <= shiftend ) OR '  
   select @strsql = @strsql + '( sttime < shiftstart and ndtime > shiftend )OR '  
   select @strsql = @strsql + '( sttime < shiftstart and ndtime > shiftstart and ndtime<=shiftend )'  
   select @strsql = @strsql + ' OR ( sttime >= shiftstart and ndtime > shiftend and sttime<shiftend ) ) and machineinformation.interfaceid>0 '  
   select @strsql = @strsql + @strmachine+@StrMPlantID  
	select @strsql = @strsql + ' Group by Machineinformation.Machineid,Machineinformation.interfaceid,
					componentinformation.componentid,componentinformation.interfaceid,componentoperationpricing.operationno,
					componentoperationpricing.interfaceid,Employeeinformation.Employeeid,Employeeinformation.interfaceid, Pdate, Shift, ShiftStart, ShiftEnd --ER0459 to include group by 
		order by Machineinformation.Machineid,shiftstart'
		print @strsql
		exec (@strsql) 
   
   insert into #HourlyData(PDate,Shiftid,ShiftName,Shiftstart,ShiftEnd,HourName,HourID,FromTime,ToTime)  
   select CAST(datePart(yyyy,pdate) AS nvarchar(4)) + '-' + CAST(datePart(mm,pdate) AS nvarchar(2)) + '-' + CAST(datePart(dd,pdate) AS nvarchar(2)),S.Shiftid,S.Shift,S.ShiftStart, S.ShiftEnd,SH.Hourname,SH.HourID,  
   dateadd(day,SH.Fromday,(convert(datetime, CAST(datePart(yyyy,pdate) AS nvarchar(4)) + '-' + CAST(datePart(mm,pdate) AS nvarchar(2)) + '-' + CAST(datePart(dd,pdate) AS nvarchar(2)) + ' ' + CAST(datePart(hh,SH.HourStart) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourStart) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourStart) as nvarchar(2))))),  
   dateadd(day,SH.Today,(convert(datetime, CAST(datePart(yyyy,pdate) AS nvarchar(4)) + '-' + CAST(datePart(mm,pdate) AS nvarchar(2)) + '-' + CAST(datePart(dd,pdate) AS nvarchar(2)) + ' ' + CAST(datePart(hh,SH.HourEnd) AS nvarchar(2)) + ':' + CAST(datePart
(mi,SH.HourEnd) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourEnd) as nvarchar(2)))))  
   from (Select * from #ShiftDetails_SelPeriod) S inner join Shifthourdefinition SH on SH.shiftid=S.Shiftid  
   order by S.Shiftid,SH.Hourid  
  
   insert into #Base_Prod_ctn_Temp(Fromtime,totime,MachineId,ComponentiD,Operationno,OperatorID,HourID,ShiftName,ShiftStartTime,ShiftEndTime,Shiftid,machineinterface,Compinterface,OpnInterface,OprInterface,sttime)   --ER0459
   Select H.FromTime,H.Totime,M.Machine,M.Component,M.Operation,M.Operator,H.Hourid,M.ShftName,M.ShftStrt,M.ShftND,H.Shiftid,M.MachineInt,M.CompInt,M.OpnInt,M.Oprint,M.sttime from    --ER0459
         #Machcomopnopr M inner join #HourlyData H on M.ShftStrt=H.Shiftstart  
  
  
   UPDATE #Base_Prod_ctn_Temp SET Actual = ISNULL(Actual,0) + ISNULL(t2.comp1,0)   
   From    
   (    
   Select T1.mc,T1.comp,T1.opn,T1.opr,T1.fromtime,T1.Totime,  
   SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp1  
    From (select mc,comp,opn,opr,fromtime,totime,SUM(autodata.partscount)AS OrginalCount from #T_autodata autodata    
    INNER JOIN #Base_Prod_ctn_Temp F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn and F.oprinterface=Autodata.opr    
    where (autodata.ndtime>F.Fromtime) and (autodata.ndtime<=F.Totime) and (autodata.datatype=1)    
    Group By mc,comp,opn,opr,fromtime,totime) as T1    
   INNER JOIN #Base_Prod_ctn_Temp F on F.machineinterface=T1.mc and F.Compinterface=T1.comp and F.Opninterface = T1.opn and F.oprinterface=T1.opr    
   and F.Fromtime=T1.Fromtime and F.Totime=T1.Totime  
   Inner join componentinformation C on F.Compinterface = C.interfaceid    
   Inner join ComponentOperationPricing O ON  F.Opninterface = O.interfaceid and C.Componentid=O.componentid    
   inner join machineinformation on machineinformation.machineid =O.machineid    
   and F.machineinterface=machineinformation.interfaceid    
   GROUP BY T1.mc,T1.comp,T1.opn,T1.opr,T1.fromtime,T1.Totime  
   ) As T2 Inner Join #Base_Prod_ctn_Temp on T2.mc = #Base_Prod_ctn_Temp.machineinterface and    
   T2.comp = #Base_Prod_ctn_Temp.compinterface and T2.opn = #Base_Prod_ctn_Temp.opninterface and  T2.opr = #Base_Prod_ctn_Temp.oprinterface     
   and T2.Fromtime=#Base_Prod_ctn_Temp.Fromtime and T2.Totime=#Base_Prod_ctn_Temp.Totime    
  
   If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'    
   BEGIN    
  
   UPDATE #Base_Prod_ctn_Temp SET Actual=ISNULL(Actual,0)- isnull(t2.PlanCt,0)  
   FROM ( select autodata.mc,autodata.comp,autodata.opn,autodata.opr,F.Fromtime,F.Totime,  
   ((CAST(Sum(ISNULL(PartsCount,1)) AS Float)/ISNULL(CO.SubOperations,1))) as PlanCt  
   from #T_autodata autodata     
    INNER JOIN #Base_Prod_ctn_Temp F on F.machineinterface=autodata.mc and F.Compinterface=autodata.comp and F.Opninterface = autodata.opn and F.oprinterface=autodata.opr    
   Inner jOIN #PlannedDownTimesShift T on T.MachineInterface=autodata.mc      
   inner join machineinformation M on autodata.mc=M.Interfaceid    
   Inner join componentinformation CI on autodata.comp=CI.interfaceid     
   inner join componentoperationpricing CO on autodata.opn=CO.interfaceid and    
   CI.componentid=CO.componentid  and CO.machineid=M.machineid    
   WHERE autodata.DataType=1 and    
   (autodata.ndtime>F.Fromtime) and (autodata.ndtime<=F.Totime)     
   AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)    
   Group by autodata.mc,autodata.comp,autodata.opn,autodata.opr,F.Fromtime,F.Totime,CO.SubOperations     
   ) as T2 Inner Join #Base_Prod_ctn_Temp on T2.mc = #Base_Prod_ctn_Temp.machineinterface and    
   T2.comp = #Base_Prod_ctn_Temp.compinterface and T2.opn = #Base_Prod_ctn_Temp.opninterface and  T2.opr = #Base_Prod_ctn_Temp.oprinterface     
   and T2.Fromtime=#Base_Prod_ctn_Temp.Fromtime and T2.Totime=#Base_Prod_ctn_Temp.Totime   
  
   END    
  
  
   UPDATE #Base_Prod_ctn_Temp SET HourlyDowntime = isnull(HourlyDowntime,0) + isNull(t2.down,0)  
    from  
    (select T1.Starttime,M.MachineID,C.componentId,O.operationno,E.employeeid,sum(  
      CASE  
      WHEN  A.msttime>=T1.StartTime  and  A.ndtime<=T1.EndTime  THEN  A.loadunload  
      WHEN (A.sttime<T1.StartTime and  A.ndtime>T1.StartTime and A.ndtime<=T1.EndTime)  THEN DateDiff(second, T1.StartTime, ndtime)  
      WHEN (A.msttime>=T1.StartTime  and A.sttime<T1.EndTime  and A.ndtime>T1.EndTime)  THEN DateDiff(second, stTime, T1.Endtime)  
      WHEN A.msttime<T1.StartTime and A.ndtime>T1.EndTime   THEN DateDiff(second, T1.StartTime, T1.EndTime)  
      END  
     )AS down  
    from autodata A inner join downcodeinformation on A.dcode=downcodeinformation.interfaceid  
     inner join machineinformation M on M.interfaceid=A.mc  
     left outer join componentinformation C on C.interfaceid=A.comp  
     left outer join componentoperationpricing O on O.interfaceid=A.opn and C.componentid=O.componentid and O.MachineID = M.MachineID  
     left outer join Employeeinformation E on E.Interfaceid=A.opr  
     inner join (Select distinct Fromtime as StartTime,Totime as EndTime,Machineid,componentid,operationno,OPeratorid From #Base_Prod_ctn_Temp) T1   
    on T1.Machineid=O.Machineid and T1.componentid=O.componentid and T1.operationno=O.operationno and T1.OPeratorid=E.employeeid  
    Where ((A.msttime>=T1.StartTime  and  A.ndtime<=T1.EndTime)  
    OR (A.sttime<T1.StartTime and  A.ndtime>T1.StartTime and A.ndtime<=T1.EndTime)  
    OR (A.msttime>=T1.StartTime  and A.sttime<T1.EndTime  and A.ndtime>T1.EndTime)  
    OR (A.msttime<T1.StartTime and A.ndtime>T1.EndTime )  
    ) AND  A.datatype=2   
    group by T1.Starttime,M.MachineID,C.componentId,O.operationno,E.employeeid  
    ) as T2 inner join #Base_Prod_ctn_Temp BS on t2.MachineID = BS.MachineID  
    And T2.componentId=Bs.componentId and T2.operationno=BS.operationno and  
    T2.employeeid=BS.OPeratorid and T2.Starttime=Bs.Fromtime  
  
  
   If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
   BEGIN  
     UPDATE #Base_Prod_ctn_Temp SET HourlyDowntime = isnull(HourlyDowntime,0) - isNull(t2.PldDown,0)  
     from(  
     select AUTODATA.mc,AUTODATA.comp,AUTODATA.opn,AUTODATA.opr,f.fromtime,SUM  
         (CASE  
      WHEN (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN autodata.loadunload  
      WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
      WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )  
      WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
      END ) as PldDown  
     From #T_autodata AutoData CROSS jOIN #PlannedDownTimesShift T  
     INNER JOIN #Base_Prod_ctn_Temp F on F.machineinterface=autodata.mc and F.Compinterface=autodata.comp and F.Opninterface = autodata.opn and F.oprinterface=autodata.opr    
     INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID  
     WHERE autodata.DataType=2  and T.MachineInterface=autodata.mc and  
     ((autodata.msttime>=F.fromtime  and  autodata.ndtime<=F.Totime)  
     OR (autodata.sttime<F.fromtime and  autodata.ndtime>F.fromtime and autodata.ndtime<=F.Totime)  
     OR (autodata.msttime>=F.fromtime  and autodata.sttime<F.Totime  and autodata.ndtime>F.Totime)  
     OR (autodata.msttime<F.fromtime and autodata.ndtime>F.Totime ))  
      AND(  
     (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
     OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
     OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )  
     OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  
     )  
     AND (downcodeinformation.availeffy = 0)  
     group by AUTODATA.mc,AUTODATA.comp,AUTODATA.opn,AUTODATA.opr,f.fromtime) as t2 Inner Join #Base_Prod_ctn_Temp on T2.mc = #Base_Prod_ctn_Temp.machineinterface and    
     T2.comp = #Base_Prod_ctn_Temp.compinterface and T2.opn = #Base_Prod_ctn_Temp.opninterface and  T2.opr = #Base_Prod_ctn_Temp.oprinterface     
     and T2.Fromtime=#Base_Prod_ctn_Temp.Fromtime   
    end  
  
  
    Update #Base_Prod_ctn_Temp set SDate =T1.Udate From(  
    Select distinct S.Udate,S.UShift,S.Machineid,S.UStartShift  
     from #ShiftProductionFromAutodata_ShiftBasis S)T1 inner join #Base_Prod_ctn_Temp on #Base_Prod_ctn_Temp.ShiftStartTime=T1.UStartShift and   
    #Base_Prod_ctn_Temp.Machineid=T1.Machineid  
  
  
  
    Update #Base_Prod_ctn_Temp set RejCount = isnull(RejCount,0) + isnull(T1.RejQty,0)  
    From  
    ( Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid,B.ShiftStartTime from AutodataRejections A  
    inner join Machineinformation M on A.mc=M.interfaceid  
    inner join (Select distinct sdate,Machineid,ShiftStartTime,ShiftEndTime,Shiftid from #Base_Prod_ctn_Temp) B on B.machineid=M.machineid and convert(nvarchar(10),(A.RejDate),126)=convert(nvarchar(10),(B.Sdate),126) and A.RejShift=B.shiftid  
    inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid  
    where A.flag = 'Rejection' and A.Rejshift in (B.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (convert(nvarchar(10),(B.Sdate),126)) and  --DR0333  
    Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'  
    group by A.mc,M.Machineid,B.ShiftStartTime  
    )T1 inner join #Base_Prod_ctn_Temp B on B.Machineid=T1.Machineid and B.ShiftStartTime=T1.ShiftStartTime  
  


    If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
    BEGIN  
     Update #Base_Prod_ctn_Temp set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from  
     (Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid,B.ShiftStartTime from AutodataRejections A  
     inner join Machineinformation M on A.mc=M.interfaceid  
     inner join (Select distinct sdate,Machineid,ShiftStartTime,ShiftEndTime,Shiftid from #Base_Prod_ctn_Temp) B on B.machineid=M.machineid and convert(nvarchar(10),(A.RejDate),126)=convert(nvarchar(10),(B.Sdate),126) and A.RejShift=B.shiftid  
     inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid  
     Cross join #PlannedDownTimesShift P  
     where  A.flag = 'Rejection' and P.machine=M.Machineid and  
     A.Rejshift in (B.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (convert(nvarchar(10),(B.Sdate),126)) and --DR0333  
     Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'  
     and P.starttime>=B.ShiftStartTime and P.Endtime<=B.ShiftEndTime  
     group by A.mc,M.Machineid,B.ShiftStartTime)T1 inner join #Base_Prod_ctn_Temp B on B.Machineid=T1.Machineid and B.ShiftStartTime=T1.ShiftStartTime  
  
    END  
     
   
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
   ,PDT = isnull(PDT,0) + isNull(t2.PlanDT,0) --ER0459  
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
   If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y')  
   BEGIN  
    --Type 1  
    UPDATE #ShiftProductionFromAutodata_ShiftBasis SET downtime = isnull(downtime,0) + isNull(t2.down,0)  
    from  
    (select mc,  
     sum(loadunload) down,S.UstartShift as ShiftStart  
    From #T_autodata AutoData --ER0393  
    INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid  
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
    INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid  
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
    INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid  
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
    INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid  
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
     ,PDT=isnull(PDT,0) + isNull(t2.PldDown,0) --ER0459  
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
    ,PDT=isnull(PDT,0) + isNull(t2.PldDown,0) --ER0459  
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
    ,isnull(T2.PPDT,0)as PPDT --ER0459  
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
  
  
   UPDATE #ShiftProductionFromAutodata_ShiftBasis SET  
   ProductionEfficiency = (CN/UtilisedTime) ,  
   AvailabilityEfficiency = (UtilisedTime)/(UtilisedTime + DownTime - ManagementLoss) WHERE UtilisedTime <> 0  
  
  
   Update #Base_Prod_ctn_Temp set MachinewiseAE=T1.AE,MachinewisePE=T1.PE,  
   MachinewiseDowntime=T1.Downtime From(  
   Select S.Udate,S.UShift,S.Machineid,S.UStartShift,  
   dbo.f_FormatTime(S.UtilisedTime,@timeformat) as UtilisedTime,  
   --dbo.f_FormatTime((S.DownTime-S.ManagementLoss),@timeformat) as DownTime,  
   dbo.f_FormatTime((S.DownTime),@timeformat) as DownTime,  
   dbo.f_FormatTime(S.ManagementLoss,@timeformat) as ManagementLoss,S.PDT as PDT,S.QTY,  
   ProductionEfficiency as PE,  
   AvailabilityEfficiency  As AE from   
   #ShiftProductionFromAutodata_ShiftBasis S)T1 inner join #Base_Prod_ctn_Temp on #Base_Prod_ctn_Temp.ShiftStartTime=T1.UStartShift and   
   #Base_Prod_ctn_Temp.Machineid=T1.Machineid  
   --where (S.UtilisedTime<>0 and S.DownTime<>0 and S.ManagementLoss<>0)  
  
  
  
  
   Select top 1 @Targetsource = ValueInText from Shopdefaults where Parameter='TargetFrom'  
  
   if isnull(@Targetsource,'')='Exact Schedule'          
   BEGIN        
  
   select @strsql=''        
   select @strsql='update #Base_Prod_ctn_Temp Set Target= ISNULL(Target,0) + ISNULL(t1.idealcount,0) from        
   ( select L.date as date1,L.shift,L.machine,L.component,L.operation,L.idealcount as idealcount from        
   loadschedule L inner join (Select distinct Sdate,Shiftname,machineid,Componentid,operationno from #Base_Prod_ctn_Temp) as #Base_Prod_ctn_Temp on  
   L.Date=#Base_Prod_ctn_Temp.Sdate and L.Shift=#Base_Prod_ctn_Temp.ShiftName and L.component=#Base_Prod_ctn_Temp.Componentid       
   and L.operation=#Base_Prod_ctn_Temp.operationno and L.machine=#Base_Prod_ctn_Temp.machineid         
   ) T1 inner join #Base_Prod_ctn_Temp on t1.date1=#Base_Prod_ctn_Temp.Sdate and T1.Shift = #Base_Prod_ctn_Temp.ShiftName  
   and T1.Machine =  #Base_Prod_ctn_Temp.machineID and T1.Component = #Base_Prod_ctn_Temp.ComponentId  
   and T1.operation = #Base_Prod_ctn_Temp.Operationno'        
   exec(@strsql)         
  
   END        
          
           
   IF isnull(@Targetsource,'')='Default Target per CO'        
   BEGIN        
  
    Update #Base_Prod_ctn_Temp set Target = ISNULL(Target,0) + ISNULL(t1.idealcount,0) from  
    (  
    select T.Machine,T.Component,T.Operation,T.Date,T.Shift,SUM(T.IdealCount) as IdealCount  
    from (  
     select L.date,L.Component,L.operation,L.idealcount,L.Machine,L.Shift,  
     row_number() over(partition by L.Machine,L.Component,L.operation,L.Shift order by L.date desc) as rn  
     from Loadschedule L inner join (Select distinct Sdate,Shiftname,machineid,Componentid,operationno from #Base_Prod_ctn_Temp) as #Base_Prod_ctn_Temp on   
     L.Component=#Base_Prod_ctn_Temp.Componentid and L.operation=#Base_Prod_ctn_Temp.operationno and #Base_Prod_ctn_Temp.machineid=L.machine where L.Date<=#Base_Prod_ctn_Temp.Sdate and L.Shift=#Base_Prod_ctn_Temp.ShiftName  
    ) as T   
    where T.rn <= 1 group by T.Machine,T.Component,T.Operation,T.Date,T.Shift)T1 inner join #Base_Prod_ctn_Temp on t1.date=#Base_Prod_ctn_Temp.Sdate and T1.Shift = #Base_Prod_ctn_Temp.ShiftName  
    and T1.Machine =  #Base_Prod_ctn_Temp.machineID and T1.Component = #Base_Prod_ctn_Temp.ComponentId  
    and T1.operation = #Base_Prod_ctn_Temp.Operationno  
      
   END        

  
   If isnull(@Targetsource,'')='% Ideal'  
   Begin  
  
    update #Base_Prod_ctn_Temp set Target= t1.tcount from  
    (  
    select CO.componentid as component,CO.Operationno as operation,#Base_Prod_ctn_Temp.ShiftStartTime as strt  
    ,#Base_Prod_ctn_Temp.ShiftEndTime as ndtm,#Base_Prod_ctn_Temp.MachineID as mcid,  
    tcount=((datediff(second,#Base_Prod_ctn_Temp.ShiftStartTime,#Base_Prod_ctn_Temp.ShiftEndTime)*CO.suboperations)/CO.cycletime)*isnull(CO.targetpercent,100) /100  
    from componentoperationpricing CO inner join #Base_Prod_ctn_Temp  
    on #Base_Prod_ctn_Temp.machineid=Co.machineid and CO.Componentid=#Base_Prod_ctn_Temp.ComponentID and Co.operationno=#Base_Prod_ctn_Temp.Operationno  
    ) as t1 inner join #Base_Prod_ctn_Temp on t1.strt=#Base_Prod_ctn_Temp.ShiftStartTime  
    and t1.ndtm=#Base_Prod_ctn_Temp.ShiftEndTime  
    and t1.mcid=#Base_Prod_ctn_Temp.MachineID and t1.component=#Base_Prod_ctn_Temp.ComponentID and  
    t1.operation=#Base_Prod_ctn_Temp.Operationno   

 
    If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'  
    BEGIN  
     update #Base_Prod_ctn_Temp set Target=target-((cast(t3.Totalpdt as float)/cast(datediff(ss,t3.Starttime,t3.Endtime) as float))*target)  
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
      (Select distinct Machineid,ShiftStartTime as StartTime ,ShiftEndTime as EndTime from #Base_Prod_ctn_Temp) as fd  
       cross join planneddowntimes pdt  
      where PDTstatus = 1  and fd.machineID = pdt.Machine and --and DownReason <> 'SDT'  
      ((pdt.StartTime >= fd.StartTime and pdt.EndTime <= fd.EndTime)or  
      (pdt.StartTime < fd.StartTime and pdt.EndTime > fd.StartTime and pdt.EndTime <=fd.EndTime)or  
      (pdt.StartTime >= fd.StartTime and pdt.StartTime <fd.EndTime and pdt.EndTime > fd.EndTime) or  
      (pdt.StartTime < fd.StartTime and pdt.EndTime > fd.EndTime))  
      )T2 group by Machineid,Starttime,Endtime  
      )T3 inner join #Base_Prod_ctn_Temp  
      on T3.Machineid=#Base_Prod_ctn_Temp.machineid and T3.Starttime=#Base_Prod_ctn_Temp.Shiftstarttime and T3.Endtime= #Base_Prod_ctn_Temp.Shiftendtime  
    End  
   END    
  
--DR0379 From here 
--   update #Base_Prod_ctn_Temp set ShftActualCount=T1.Actual,Hourlytarget=Bs.Target/Isnull(T1.cnt,1) from #Base_Prod_ctn_Temp Bs  
--   inner join  
--   (Select sdate,MachineID,ComponentID,Operationno,operatorid,ShiftID,  
--   sum(Cast(Actual as float))as Actual,count(ShiftID) as cnt From #Base_Prod_ctn_Temp Bs  
--   Group by SDate,MachineID,ComponentID,Operationno,operatorid,ShiftID ) T1  
--   On T1.Sdate=Bs.Sdate and T1.MachineID=Bs.MachineID and T1.ComponentID=Bs.ComponentID  
--   and T1.Operationno=Bs.Operationno and T1.operatorid=Bs.operatorid  
--   and T1.ShiftID=Bs.ShiftID  

--SV
--   update #Base_Prod_ctn_Temp set ShftActualCount=ISNULL(T1.Actual,0),Hourlytarget=T1.Target/Isnull(T1.cnt,1),Target=Isnull(T1.Target,0) from #Base_Prod_ctn_Temp Bs  
--   inner join  
--   (Select sdate,MachineID,ComponentID,operatorid,ShiftID,  
--   sum(Cast(Actual as float))as Actual,count(distinct hourID) as cnt,SUM(Target) as Target From #Base_Prod_ctn_Temp Bs  
--   Group by SDate,MachineID,ComponentID,operatorid,ShiftID ) T1  
--   On T1.Sdate=Bs.Sdate and T1.MachineID=Bs.MachineID and T1.ComponentID=Bs.ComponentID  
--   and T1.operatorid=Bs.operatorid  
--   and T1.ShiftID=Bs.ShiftID  
--
--   update #Base_Prod_ctn_Temp set Actual=ISNULL(T1.Actual,0),HourlyDowntime=Isnull(T1.HourlyDowntime,0) from #Base_Prod_ctn_Temp Bs  
--   inner join  
--   (Select sdate,MachineID,ComponentID,operatorid,ShiftID,Hourid,  
--   sum(Cast(Actual as float))as Actual,SUM(HourlyDowntime) as HourlyDowntime From #Base_Prod_ctn_Temp Bs  
--   Group by SDate,MachineID,ComponentID,operatorid,ShiftID,Hourid ) T1  
--   On T1.Sdate=Bs.Sdate and T1.MachineID=Bs.MachineID and T1.ComponentID=Bs.ComponentID  
--   and T1.operatorid=Bs.operatorid and T1.ShiftID=Bs.ShiftID and T1.Hourid=Bs.Hourid
--SV

--SV
   update #Base_Prod_ctn_Temp set ShftActualCount=ISNULL(T1.Actual,0),Hourlytarget=Bs.Target/Isnull(T1.cnt,1),Target=Isnull(Bs.Target,0) from #Base_Prod_ctn_Temp Bs  
   inner join  
   (Select sdate,MachineID,ComponentID,Operationno,operatorid,ShiftID,  
   sum(Cast(Actual as float))as Actual,count(distinct hourID) as cnt From #Base_Prod_ctn_Temp Bs  
   Group by SDate,MachineID,ComponentID,Operationno,operatorid,ShiftID ) T1  
   On T1.Sdate=Bs.Sdate and T1.MachineID=Bs.MachineID and T1.ComponentID=Bs.ComponentID and T1.Operationno=Bs.Operationno 
   and T1.operatorid=Bs.operatorid  
   and T1.ShiftID=Bs.ShiftID  

   update #Base_Prod_ctn_Temp set Actual=ISNULL(T1.Actual,0),HourlyDowntime=Isnull(T1.HourlyDowntime,0) from #Base_Prod_ctn_Temp Bs  
   inner join  
   (Select sdate,MachineID,ComponentID,Operationno,operatorid,ShiftID,Hourid,  
   sum(Cast(Actual as float))as Actual,SUM(HourlyDowntime) as HourlyDowntime From #Base_Prod_ctn_Temp Bs  
   Group by SDate,MachineID,ComponentID,Operationno,operatorid,ShiftID,Hourid ) T1  
   On T1.Sdate=Bs.Sdate and T1.MachineID=Bs.MachineID and T1.ComponentID=Bs.ComponentID and T1.Operationno=Bs.Operationno 
   and T1.operatorid=Bs.operatorid and T1.ShiftID=Bs.ShiftID and T1.Hourid=Bs.Hourid
--SV
--DR0379 Till Here

  
--   UPDATE #Base_Prod_ctn_Temp SET MachinewiseQE= ISNULL(MachinewiseQE,0) + IsNull(T1.QE,0)   
--   FROM(Select MachineID,ShiftStartTime,  
--   CAST((Sum(ShftActualCount))As Float)/CAST((Sum(IsNull(ShftActualCount,0))+Sum(IsNull(RejCount,0))) AS Float) As QE  
--   From #Base_Prod_ctn_Temp Where ShftActualCount<>0 Group By MachineID,ShiftStartTime  
--   )AS T1 Inner Join #Base_Prod_ctn_Temp ON  #Base_Prod_ctn_Temp.MachineID=T1.MachineID and #Base_Prod_ctn_Temp.ShiftStartTime=T1.ShiftStartTime  
  
   UPDATE #Base_Prod_ctn_Temp SET MachinewiseQE= ISNULL(MachinewiseQE,0) + IsNull(T1.QE,0)   
   FROM(Select MachineID,ShiftStartTime,  
   CASE WHEN Sum(IsNull(RejCount,0))>0 THEN CAST((Sum(ShftActualCount))As Float)/CAST((Sum(IsNull(ShftActualCount,0))+Sum(IsNull(RejCount,0))) AS Float)   
   ELSE '0' END As QE  
   From #Base_Prod_ctn_Temp --Where ShftActualCount<>0   
   Group By MachineID,ShiftStartTime  
   )AS T1 Inner Join #Base_Prod_ctn_Temp ON  #Base_Prod_ctn_Temp.MachineID=T1.MachineID and #Base_Prod_ctn_Temp.ShiftStartTime=T1.ShiftStartTime  
  
  
   Update #Base_Prod_ctn_Temp set MachinewiseOEE = T1.OEE From(  
   Select S.ShiftStartTime,S.Machineid,  
   (MachinewisePE * MachinewiseAE * MachinewiseQE) as OEE from   
   #Base_Prod_ctn_Temp S)T1 inner join #Base_Prod_ctn_Temp on #Base_Prod_ctn_Temp.ShiftStartTime=T1.ShiftStartTime and   
   #Base_Prod_ctn_Temp.Machineid=T1.Machineid  
  
------------------------- DR0386 From here ---------------------------  
--   Update #Base_Prod_ctn_Temp set DaywiseDowntime=T1.Downtime,DaywiseRejQty=T1.Rejcount From(  
--   Select S.sdate,S.Machineid,  
--    dbo.f_FormatTime((SUM(S.HourlyDowntime)),@timeformat)as DownTime,SUM(RejCount) as Rejcount from   
--   #Base_Prod_ctn_Temp S  group by S.Sdate,S.Machineid )T1 inner join #Base_Prod_ctn_Temp on #Base_Prod_ctn_Temp.Sdate=T1.sDate and   
--   #Base_Prod_ctn_Temp.Machineid=T1.Machineid  
  

   Update #Base_Prod_ctn_Temp set DaywiseDowntime=T1.Downtime From(  
   Select S.sdate,S.Machineid,dbo.f_FormatTime((SUM(S.HourlyDowntime)),@timeformat)as DownTime from   
   #Base_Prod_ctn_Temp S  group by S.Sdate,S.Machineid )T1 inner join #Base_Prod_ctn_Temp on #Base_Prod_ctn_Temp.Sdate=T1.sDate and   
   #Base_Prod_ctn_Temp.Machineid=T1.Machineid  

   Update #Base_Prod_ctn_Temp set DaywiseRejQty=T1.Rejcount From(  
   Select S.sdate,S.Machineid,SUM(RejCount) as Rejcount from   
   (Select Distinct sdate,machineid,Rejcount,ShiftStartTime From #Base_Prod_ctn_Temp) S  
   group by S.Sdate,S.Machineid )T1 inner join #Base_Prod_ctn_Temp on #Base_Prod_ctn_Temp.Sdate=T1.sDate and #Base_Prod_ctn_Temp.Machineid=T1.Machineid  
--------------------------- DR0386 Till Here --------------------------------------------

   Update #Base_Prod_ctn_Temp set DaywiseAE=T1.AE,DaywisePE=T1.PE,  
   DaywiseOEE = T1.OEE  From(  
   Select S.sdate,S.Machineid  
    ,Avg(S.MachinewiseAE) as AE,AVG(S.MachinewisePE) as PE,  
   Avg(S.MachinewiseOEE) as OEE from   
   (Select distinct sdate,Shiftname,Machineid,MachinewiseAE,MachinewisePE,MachinewiseOEE from #Base_Prod_ctn_Temp) S group by S.Sdate,S.Machineid )T1 inner join #Base_Prod_ctn_Temp on #Base_Prod_ctn_Temp.Sdate=T1.sDate and   
   #Base_Prod_ctn_Temp.Machineid=T1.Machineid  
  
  
   Update #Base_Prod_ctn_Temp set DaywiseQE = T1.QE From(  
   Select distinct S.sdate,S.Machineid,Avg(S.MachinewiseQE) as QE from   
    #Base_Prod_ctn_Temp S where S.MachinewiseQE>0 group by S.Sdate,S.Machineid )T1 inner join #Base_Prod_ctn_Temp on #Base_Prod_ctn_Temp.Sdate=T1.sDate and   
   #Base_Prod_ctn_Temp.Machineid=T1.Machineid  
  
  
   Update #Base_Prod_ctn_Temp set Hour1DT=T1.Downtime,Hour1Actual=T1.Actual From(  
   Select S.Sdate,S.Machineid,  
   SUM(S.HourlyDowntime) as DownTime,SUM(Actual) as Actual from   
   #Base_Prod_ctn_Temp S  where s.Hourid='1' group by S.Sdate,S.Machineid)T1 inner join #Base_Prod_ctn_Temp on #Base_Prod_ctn_Temp.Sdate=T1.sDate and   
   #Base_Prod_ctn_Temp.Machineid=T1.Machineid    
  
   Update #Base_Prod_ctn_Temp set Hour2DT=T1.Downtime,Hour2Actual=T1.Actual From(  
   Select S.Sdate,S.Machineid,  
   SUM(S.HourlyDowntime) as DownTime,SUM(Actual) as Actual from   
   #Base_Prod_ctn_Temp S  where s.Hourid='2' group by S.Sdate,S.Machineid)T1 inner join #Base_Prod_ctn_Temp on #Base_Prod_ctn_Temp.Sdate=T1.sDate and   
   #Base_Prod_ctn_Temp.Machineid=T1.Machineid   
  
   Update #Base_Prod_ctn_Temp set Hour3DT=T1.Downtime,Hour3Actual=T1.Actual From(  
   Select S.Sdate,S.Machineid,  
   SUM(S.HourlyDowntime) as DownTime,SUM(Actual) as Actual from   
   #Base_Prod_ctn_Temp S where s.Hourid='3' group by S.Sdate,S.Machineid)T1 inner join #Base_Prod_ctn_Temp on #Base_Prod_ctn_Temp.Sdate=T1.sDate and   
   #Base_Prod_ctn_Temp.Machineid=T1.Machineid   
  
   Update #Base_Prod_ctn_Temp set Hour4DT=T1.Downtime,Hour4Actual=T1.Actual From(  
   Select S.Sdate,S.Machineid,  
   SUM(S.HourlyDowntime) as DownTime,SUM(Actual) as Actual from   
   #Base_Prod_ctn_Temp S  where s.Hourid='4' group by S.Sdate,S.Machineid)T1 inner join #Base_Prod_ctn_Temp on #Base_Prod_ctn_Temp.Sdate=T1.sDate and   
   #Base_Prod_ctn_Temp.Machineid=T1.Machineid   
  
   Update #Base_Prod_ctn_Temp set Hour5DT=T1.Downtime,Hour5Actual=T1.Actual From(  
   Select S.Sdate,S.Machineid,  
   SUM(S.HourlyDowntime) as DownTime,SUM(Actual) as Actual from   
   #Base_Prod_ctn_Temp S  where s.Hourid='5' group by S.Sdate,S.Machineid)T1 inner join #Base_Prod_ctn_Temp on #Base_Prod_ctn_Temp.Sdate=T1.sDate and   
   #Base_Prod_ctn_Temp.Machineid=T1.Machineid   
  
   Update #Base_Prod_ctn_Temp set Hour6DT=T1.Downtime,Hour6Actual=T1.Actual From(  
   Select S.Sdate,S.Machineid,  
   SUM(S.HourlyDowntime) as DownTime,SUM(Actual) as Actual from   
   #Base_Prod_ctn_Temp S where s.Hourid='6' group by S.Sdate,S.Machineid)T1 inner join #Base_Prod_ctn_Temp on #Base_Prod_ctn_Temp.Sdate=T1.sDate and   
   #Base_Prod_ctn_Temp.Machineid=T1.Machineid   
  
   Update #Base_Prod_ctn_Temp set Hour7DT=T1.Downtime,Hour7Actual=T1.Actual From(  
   Select S.Sdate,S.Machineid,  
   SUM(S.HourlyDowntime) as DownTime,SUM(Actual) as Actual from   
   #Base_Prod_ctn_Temp S  where s.Hourid='7' group by S.Sdate,S.Machineid)T1 inner join #Base_Prod_ctn_Temp on #Base_Prod_ctn_Temp.Sdate=T1.sDate and   
   #Base_Prod_ctn_Temp.Machineid=T1.Machineid   
  
   Update #Base_Prod_ctn_Temp set Hour8DT=T1.Downtime,Hour8Actual=T1.Actual From(  
   Select S.Sdate,S.Machineid,  
   SUM(S.HourlyDowntime) as DownTime,SUM(Actual) as Actual from   
   #Base_Prod_ctn_Temp S where s.Hourid='8' group by S.Sdate,S.Machineid)T1 inner join #Base_Prod_ctn_Temp on #Base_Prod_ctn_Temp.Sdate=T1.sDate and   
   #Base_Prod_ctn_Temp.Machineid=T1.Machineid   



   If @Param = ''  
   Begin  
  
	Select * From
    (Select distinct convert(nvarchar(10),B.Sdate,120) as date,B.ShiftName,B.Machineid,B.ComponentId,B.Operatorid,B.ShiftID,B.HourID, B.sttime, --ER0459      
    B.FromTime,B.ToTime,B.Actual,B.HourlyDowntime,  
    CEILING(B.Hourlytarget) as Hourlytarget,CEILING(B.Target) as ShiftTarget,B.ShftActualCount,B.RejCount as TotalRejection,      
    B.MachinewiseDowntime,Round(B.MachinewiseAE*100,2) as AE,Round(B.MachinewisePE*100,2) as PE,Round(B.MachinewiseOEE*100,2) as OEE,Round(B.MachinewiseQE*100,2) as QE,  
    Round(DaywiseAE*100,2) as DaywiseAE,Round(DaywisePE*100,2) as DaywisePE,Round(DaywiseOEE*100,2) as DaywiseOEE,Round(DaywiseQE*100,2) as DaywiseQE,DaywiseDowntime,DaywiseRejQty,  
    Hour1Actual,Hour1DT,Hour2Actual,Hour2DT,Hour3Actual,Hour3DT,Hour4Actual,Hour4DT,Hour5Actual,Hour5DT,Hour6Actual,Hour6DT,Hour7Actual,Hour7DT,Hour8Actual,Hour8DT 
	from #Base_Prod_ctn_Temp B  
    left outer join Plantmachine P on P.machineid=B.machineID) B order by B.date,B.MachineID,B.shiftID,B.sttime,B.componentID,B.operatorID,B.Hourid --ER0459
  
   End  
  
   If @Param = 'SchService'  
   Begin  
  
    IF @ShiftIN=''  
    Begin  
     select @strsql=''  
     Select @strsql = @strsql + 'DELETE FROM #Base_Prod_ctn_Temp WHERE ShiftName IN(''A'',''B'')'  
     print @strsql  
     exec(@strsql)  
    End  

 --ER0459    
 --   Select convert(nvarchar(10),B.Sdate,120) as date,B.ShiftName,B.Machineid,B.ComponentId,B.Operatorid,B.ShiftID,B.HourID,       
 --   B.FromTime,B.ToTime,B.Actual,B.HourlyDowntime,  
 --   CEILING(B.Hourlytarget) as Hourlytarget,CEILING(B.Target) as ShiftTarget,B.ShftActualCount,B.RejCount as TotalRejection,      
 --   B.MachinewiseDowntime,Round(B.MachinewiseAE*100,2) as AE,Round(B.MachinewisePE*100,2) as PE,Round(B.MachinewiseOEE*100,2) as OEE,Round(B.MachinewiseQE*100,2) as QE,  
 --   Round(DaywiseAE*100,2) as DaywiseAE,Round(DaywisePE*100,2) as DaywisePE,Round(DaywiseOEE*100,2) as DaywiseOEE,Round(DaywiseQE*100,2) as DaywiseQE,DaywiseDowntime,DaywiseRejQty,  
 --   Hour1Actual,Hour1DT,Hour2Actual,Hour2DT,Hour3Actual,Hour3DT,Hour4Actual,Hour4DT,Hour5Actual,Hour5DT,Hour6Actual,Hour6DT,Hour7Actual,Hour7DT,Hour8Actual,Hour8DT 
	----from #Base_Prod_ctn_Temp B  --DR0379
	--from #OUTPUT B --DR0379 
 --   left outer join Plantmachine P on P.machineid=B.machineID  
 --   order by B.Sdate,B.MachineID,B.shiftID,B.componentID,B.operatorID,B.Hourid  
 --ER0459

 	Select * From
    (Select distinct convert(nvarchar(10),B.Sdate,120) as date,B.ShiftName,B.Machineid,B.ComponentId,B.Operatorid,B.ShiftID,B.HourID, B.sttime, --ER0459      
    B.FromTime,B.ToTime,B.Actual,B.HourlyDowntime,  
    CEILING(B.Hourlytarget) as Hourlytarget,CEILING(B.Target) as ShiftTarget,B.ShftActualCount,B.RejCount as TotalRejection,      
    B.MachinewiseDowntime,Round(B.MachinewiseAE*100,2) as AE,Round(B.MachinewisePE*100,2) as PE,Round(B.MachinewiseOEE*100,2) as OEE,Round(B.MachinewiseQE*100,2) as QE,  
    Round(DaywiseAE*100,2) as DaywiseAE,Round(DaywisePE*100,2) as DaywisePE,Round(DaywiseOEE*100,2) as DaywiseOEE,Round(DaywiseQE*100,2) as DaywiseQE,DaywiseDowntime,DaywiseRejQty,  
    Hour1Actual,Hour1DT,Hour2Actual,Hour2DT,Hour3Actual,Hour3DT,Hour4Actual,Hour4DT,Hour5Actual,Hour5DT,Hour6Actual,Hour6DT,Hour7Actual,Hour7DT,Hour8Actual,Hour8DT 
	from #Base_Prod_ctn_Temp B  
    left outer join Plantmachine P on P.machineid=B.machineID) B order by B.date,B.MachineID,B.shiftID,B.sttime,B.componentID,B.operatorID,B.Hourid --ER0459
   End  
END  
  
End  
  
  
