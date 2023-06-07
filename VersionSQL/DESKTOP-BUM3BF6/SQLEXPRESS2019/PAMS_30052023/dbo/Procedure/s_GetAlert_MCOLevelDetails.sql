/****** Object:  Procedure [dbo].[s_GetAlert_MCOLevelDetails]    Committed by VersionSQL https://www.versionsql.com ******/

--ER0458 - SwathiKS - 06/Apr/2018 ::  Alert Module :: Created New Procedure [dbo].[s_GetAlert_MCOLevelDetails] To Alert Hourwise and Shiftwise M-C-O Level Partscount
--[dbo].[s_GetAlert_MCOLevelDetails] '2017-11-04 06:00:00','','','','Shift'
--[dbo].[s_GetAlert_MCOLevelDetails] '2017-11-04 09:00:00','','','','Hour'
 
CREATE PROCEDURE [dbo].[s_GetAlert_MCOLevelDetails]  
 @StartDate datetime,  
 @ShiftIn nvarchar(20)='',  
 @PlantID nvarchar(50) = '',  
 @MachineID nvarchar(50) = '',  
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

  
create table #Machcomopnopr  
(  
 Machine nvarchar(50) NOT NULL,  
 machineinterface nvarchar(50),  
 Component nvarchar(50) NOT NULL,  
 CompInterface nvarchar(50),  
 Operation nvarchar(50) NOT NULL,  
 opnInterface nvarchar(50),   
 Shdate datetime not null,  
 ShftName nvarchar(50),  
 Fromtime datetime not null,  
 Totime datetime not null,  
 Shiftid int,
 HourId int,
 Actual int
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
DECLARE @stdate as nvarchar(25)  
declare @TmpStartdate as datetime  
declare @TmpEnddate as datetime  
  
declare @StartTime as datetime  
declare @EndTime as datetime  
declare @CurStrtTime as datetime  
declare @CurEndTime as datetime  
select @CurStrtTime=@StartDate  

  
  
declare @TD_ST as datetime  
declare @TD_ED as datetime  
  
select @stdate = CAST(datePart(yyyy,@StartDate) AS nvarchar(4)) + '-' + CAST(datePart(mm,@StartDate) AS nvarchar(2)) + '-' + CAST(datePart(dd,@StartDate) AS nvarchar(2))  

  
declare @strmachine nvarchar(255)  
declare @timeformat as nvarchar(2000)  
Declare @StrMPlantID AS NVarchar(255)  
Declare @shiftname as nvarchar(50)  
  
select @strsql = ''  
select @strmachine = ''  
Select @StrMPlantID=''  
Select @shiftname=''  
SELECT @timeformat ='ss'  

if isnull(@PlantID,'') <> ''  
begin  
 select @StrMPlantID = ' and ( PlantMachine.PlantID = N''' + @PlantID + ''' )'  
end  
if isnull(@machineid,'') <> ''  
begin  
 select @strmachine = ' and ( machineinformation.MachineID = N''' + @MachineID + ''')'  
end  
 
INSERT #ShiftDetails_SelPeriod(Pdate, Shift, ShiftStart, ShiftEnd,Shiftid)  
EXEC s_GetCurrentShiftTime @CurStrtTime,''  


Select @TD_ST=min(ShiftStart) from #ShiftDetails_SelPeriod  
Select @TD_ED=max(ShiftEnd) from #ShiftDetails_SelPeriod  

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

If @Param='hour'
Begin

   select CAST(datePart(yyyy,pdate) AS nvarchar(4)) + '-' + CAST(datePart(mm,pdate) AS nvarchar(2)) + '-' + CAST(datePart(dd,pdate) AS nvarchar(2)) as PDate,S.Shiftid,S.Shift as shiftname,S.ShiftStart, S.ShiftEnd,SH.Hourname,SH.HourID,  
   dateadd(day,SH.Fromday,(convert(datetime, CAST(datePart(yyyy,pdate) AS nvarchar(4)) + '-' + CAST(datePart(mm,pdate) AS nvarchar(2)) + '-' + CAST(datePart(dd,pdate) AS nvarchar(2)) + ' ' + CAST(datePart(hh,SH.HourStart) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourStart) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourStart) as nvarchar(2))))) as FromTime,  
   dateadd(day,SH.Today,(convert(datetime, CAST(datePart(yyyy,pdate) AS nvarchar(4)) + '-' + CAST(datePart(mm,pdate) AS nvarchar(2)) + '-' + CAST(datePart(dd,pdate) AS nvarchar(2)) + ' ' + CAST(datePart(hh,SH.HourEnd) AS nvarchar(2)) + ':' 
   + CAST(datePart(mi,SH.HourEnd) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourEnd) as nvarchar(2)))))  as ToTime
   into #hour from (Select * from #ShiftDetails_SelPeriod) S inner join Shifthourdefinition SH on SH.shiftid=S.Shiftid  
    order by S.PDate,S.Shiftid,SH.Hourid  

	
	insert into #HourlyData(PDate,Shiftid,ShiftName,Shiftstart,ShiftEnd,HourName,HourID,FromTime,ToTime)  
	Select PDate,Shiftid,ShiftName,Shiftstart,ShiftEnd,HourName,HourID,FromTime,ToTime from #hour where Convert(nvarchar(8),@StartDate,108)=Convert(nvarchar(8),Totime,108)

END

If @Param = 'Shift'
BEGIN
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
	select @strsql ='insert into #Machcomopnopr(Machine,machineinterface,Component,compinterface,Operation,opninterface,Shdate,  
		ShftName,Fromtime,ToTime,Actual) '  
	select @strsql = @strsql + 'SELECT distinct  Machineinformation.Machineid,Machineinformation.interfaceid,  
		componentinformation.componentid,componentinformation.interfaceid,componentoperationpricing.operationno,  
		componentoperationpricing.interfaceid,Pdate, Shift, ShiftStart, ShiftEnd,0 '  
	select @strsql = @strsql + ' from #T_autodata autodata inner join machineinformation on machineinformation.interfaceid=autodata.mc '
	select @strsql = @strsql + ' inner join componentinformation ON autodata.comp = componentinformation.InterfaceID '  
	select @strsql = @strsql + '  INNER JOIN componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID)'  
	select @strsql = @strsql + ' AND (componentinformation.componentid = componentoperationpricing.componentid) '   
	select @strsql = @strsql + ' and componentoperationpricing.machineid=machineinformation.machineid '  
	select @strsql = @strsql + ' Left Outer Join PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID '  
	select @strsql = @strsql + ' cross join #ShiftDetails_SelPeriod where '  
	select @strsql = @strsql + '(( sttime >= shiftstart and ndtime <= shiftend ) OR '  
	select @strsql = @strsql + '( sttime < shiftstart and ndtime > shiftend )OR '  
	select @strsql = @strsql + '( sttime < shiftstart and ndtime > shiftstart and ndtime<=shiftend )'  
	select @strsql = @strsql + ' OR ( sttime >= shiftstart and ndtime > shiftend and sttime<shiftend ) ) and machineinformation.TPMTrakEnabled=1 '  
	select @strsql = @strsql + @strmachine+@StrMPlantID  
	select @strsql = @strsql + ' order by Machineinformation.Machineid,shiftstart'  
	print @strsql  
	exec (@strsql)  
END

If @Param = 'Hour'
BEGIN
	Select @strsql=''  
	select @strsql ='insert INTO #PlannedDownTimesShift(StartTime,EndTime,Machine,MachineInterface,  
		Downreason,Shiftst)'  
	select @strsql = @strsql + 'select '  
	select @strsql = @strsql + 'CASE When StartTime<T1.Fromtime Then T1.Fromtime Else StartTime End,'  
	select @strsql = @strsql + 'case When EndTime>T1.Totime Then T1.Totime Else EndTime End,'  
	select @strsql = @strsql + 'Machine,MachineInformation.InterfaceID,'  
	select @strsql = @strsql + 'DownReason,T1.ShiftStart'  
	select @strsql = @strsql + ' FROM PlannedDownTimes cross join #HourlyData T1'  
	select @strsql = @strsql + ' inner join MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID'  
	select @strsql = @strsql + ' WHERE PDTstatus =1 and ( '  
	select @strsql = @strsql + '(StartTime >= T1.Fromtime  AND EndTime <=T1.Totime)'  
	select @strsql = @strsql + 'OR ( StartTime < T1.Fromtime  AND EndTime <= T1.Totime AND EndTime > T1.Fromtime )'  
	select @strsql = @strsql + 'OR ( StartTime >= T1.Fromtime   AND StartTime <T1.Totime AND EndTime > T1.Totime )'  
	select @strsql = @strsql + 'OR ( StartTime < T1.Fromtime  AND EndTime > T1.Totime) )'  
	select @strsql = @strsql + @strmachine  
	select @strsql = @strsql + 'ORDER BY StartTime '  
	print (@strsql)  
	exec (@strsql)  
  
	Select @strsql=''  
	select @strsql ='insert into #Machcomopnopr(Machine,machineinterface,Component,compinterface,Operation,opninterface,Shdate,  
		ShftName,Fromtime,ToTime,Actual) '  
	select @strsql = @strsql + 'SELECT distinct  Machineinformation.Machineid,Machineinformation.interfaceid,  
		componentinformation.componentid,componentinformation.interfaceid,componentoperationpricing.operationno,  
		componentoperationpricing.interfaceid,H.Pdate, H.ShiftName, H.Fromtime, H.Totime,0 '  
	select @strsql = @strsql + ' from #T_autodata autodata inner join machineinformation on machineinformation.interfaceid=autodata.mc '
	select @strsql = @strsql + ' inner join componentinformation ON autodata.comp = componentinformation.InterfaceID '  
	select @strsql = @strsql + '  INNER JOIN componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID)'  
	select @strsql = @strsql + ' AND (componentinformation.componentid = componentoperationpricing.componentid) '   
	select @strsql = @strsql + ' and componentoperationpricing.machineid=machineinformation.machineid '  
	select @strsql = @strsql + ' Left Outer Join PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID '  
	select @strsql = @strsql + ' cross join  #HourlyData H  where '  
	select @strsql = @strsql + '(( sttime >= H.Fromtime and ndtime <= H.Totime ) OR '  
	select @strsql = @strsql + '( sttime < H.Fromtime and ndtime > H.Totime )OR '  
	select @strsql = @strsql + '( sttime < H.Fromtime and ndtime > H.Fromtime and ndtime<=H.Totime )'  
	select @strsql = @strsql + ' OR ( sttime >= H.Fromtime and ndtime > H.Totime and sttime<H.Totime ) ) and machineinformation.TPMTrakEnabled=1 '  
	select @strsql = @strsql + @strmachine+@StrMPlantID  
	select @strsql = @strsql + ' order by Machineinformation.Machineid,H.Fromtime'  
	print @strsql  
	exec (@strsql)  
END

   UPDATE #Machcomopnopr SET Actual = ISNULL(Actual,0) + ISNULL(t2.comp1,0)   
   From    
   (    
   Select T1.mc,T1.comp,T1.opn,T1.fromtime,T1.Totime,  
   SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp1  
    From 
	(select mc,comp,opn,fromtime,totime,SUM(autodata.partscount)AS OrginalCount from #T_autodata autodata    
    INNER JOIN #Machcomopnopr F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn 
    where (autodata.ndtime>F.Fromtime) and (autodata.ndtime<=F.Totime) and (autodata.datatype=1)    
    Group By mc,comp,opn,fromtime,totime
	) as T1    
   INNER JOIN #Machcomopnopr F on F.machineinterface=T1.mc and F.Compinterface=T1.comp and F.Opninterface = T1.opn
   and F.Fromtime=T1.Fromtime and F.Totime=T1.Totime  
   Inner join componentinformation C on F.Compinterface = C.interfaceid    
   Inner join ComponentOperationPricing O ON  F.Opninterface = O.interfaceid and C.Componentid=O.componentid    
   inner join machineinformation on machineinformation.machineid =O.machineid and F.machineinterface=machineinformation.interfaceid    
   GROUP BY T1.mc,T1.comp,T1.opn,T1.fromtime,T1.Totime  
   ) As T2 Inner Join #Machcomopnopr on T2.mc = #Machcomopnopr.machineinterface and  T2.comp = #Machcomopnopr.compinterface and T2.opn = #Machcomopnopr.opninterface
   and T2.Fromtime=#Machcomopnopr.Fromtime and T2.Totime=#Machcomopnopr.Totime    
  
   If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'    
   BEGIN    
  
   UPDATE #Machcomopnopr SET Actual=ISNULL(Actual,0)- isnull(t2.PlanCt,0)  
   FROM ( select autodata.mc,autodata.comp,autodata.opn,F.Fromtime,F.Totime,  
   ((CAST(Sum(ISNULL(PartsCount,1)) AS Float)/ISNULL(CO.SubOperations,1))) as PlanCt  
   from #T_autodata autodata     
    INNER JOIN #Machcomopnopr F on F.machineinterface=autodata.mc and F.Compinterface=autodata.comp and F.Opninterface = autodata.opn
   Inner jOIN #PlannedDownTimesShift T on T.MachineInterface=autodata.mc      
   inner join machineinformation M on autodata.mc=M.Interfaceid    
   Inner join componentinformation CI on autodata.comp=CI.interfaceid     
   inner join componentoperationpricing CO on autodata.opn=CO.interfaceid and  CI.componentid=CO.componentid  and CO.machineid=M.machineid    
   WHERE autodata.DataType=1 and (autodata.ndtime>F.Fromtime and autodata.ndtime<=F.Totime)     
   AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)    
   Group by autodata.mc,autodata.comp,autodata.opn,F.Fromtime,F.Totime,CO.SubOperations     
   ) as T2 Inner Join #Machcomopnopr on T2.mc = #Machcomopnopr.machineinterface and T2.comp = #Machcomopnopr.compinterface and T2.opn = #Machcomopnopr.opninterface 
   and T2.Fromtime=#Machcomopnopr.Fromtime and T2.Totime=#Machcomopnopr.Totime   
  
   END    
  
  Select Shdate,ShftName,Fromtime,ToTime,Machine,machineinterface,Component,compinterface,Operation,opninterface,Actual From #Machcomopnopr
  where Actual>0 Order by Shdate,Fromtime,Machine
  
End  
  
  
