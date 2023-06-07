/****** Object:  Procedure [dbo].[s_GetRapsri_HourwiseProdAndDownDetails]    Committed by VersionSQL https://www.versionsql.com ******/

--NR0135 - SwathiKS - 24/Jan/2017 :: Created New Procedure To show Hourwise Production and Downtime details for a given day & Machine shiftwise.
    
--[dbo].[s_GetRapsri_HourwiseProdAndDownDetails] '2017-01-18','','MCV 400 4','','HourwiseCount'    
    
CREATE PROCEDURE [dbo].[s_GetRapsri_HourwiseProdAndDownDetails]    
 @Startdate datetime,    
 @SHIFTNAME nvarchar(50)='',    
 @Machineid nvarchar(50)='',  
 @Plantid nvarchar(50)='',   
 @Param nvarchar(50)=''    
    
WITH RECOMPILE    
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
  

  
SET ARITHABORT ON    
Create Table #HourlyData      
 (     
 SLNO int identity(1,1) NOT NULL,    
 Machineid nvarchar(50),       
 PDate datetime,    
 ShiftName nvarchar(20),    
 ShiftID int,    
 Shiftstart datetime,    
 ShiftEnd datetime,    
 HourName nvarchar(50),    
 HourID int,    
 FromTime datetime,    
 ToTime Datetime,    
 TypeID nvarchar(50),  
 Operation nvarchar(50),    
 Actual nvarchar(50),      
 Target nvarchar(50) Default 0,  
 Downtime  nvarchar(4000),
 Employeeid nvarchar(500),    
 Employeename nvarchar(500),
 TotalActual float,
 TotalTarget float,
 TotalOutput float
 )     
    
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
 Components float,  
 Downtime nvarchar(4000),  
 stdTime float,
 Target float,
 Shift nvarchar(20),
 Runtime float,
 TotalAvailabletime float
)  
    
CREATE TABLE #T_autodataforDown    
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
 [PartsCount] [int] NULL ,    
 id  bigint not null    
)    
    
ALTER TABLE #T_autodataforDown    
    
ADD PRIMARY KEY CLUSTERED    
(    
 mc,sttime ASC    
)ON [PRIMARY]    
    

    
Create table #GetShiftTime    
(    
dDate DateTime,    
ShiftName NVarChar(50),    
StartTime DateTime,    
EndTime DateTime    
)    
    
Create table #ShiftTime    
(    
dDate DateTime ,    
ShiftName NVarChar(50),    
Shiftid int,    
StartTime DateTime,    
EndTime DateTime    
)    
    

CREATE TABLE #PlannedDownTimesHour
(
SlNo int not null identity(1,1),
Starttime datetime,
EndTime datetime,
Machine nvarchar(50),
MachineInterface nvarchar(50),
DownReason nvarchar(50),
ShiftSt datetime
)

declare @stdate as nvarchar(50)      
Declare @T_ST AS Datetime     
Declare @T_ED AS Datetime    
Declare @strsql nvarchar(4000)    
Declare @strmachine nvarchar(1000)  
Declare @StrTPMMachines AS nvarchar(1000)  
Declare @StrPlantid as nvarchar(1000)  
 declare @StrOpr as nvarchar(50)

    
Select @strsql = ''  
Select @StrTPMMachines = ''  
Select @strmachine = ''  
select @strPlantID = ''  
 select @StrOpr=''
 
IF ( SELECT TOP 1 ValueInText FROM  CockpitDefaults WHERE Parameter='TpmEnbMac')='E'  
BEGIN  
 SET  @StrTPMMachines = 'AND MachineInformation.TPMTrakEnabled = 1'  
END  
ELSE  
BEGIN  
 SET  @StrTPMMachines = ' '  
END  
  
if isnull(@machineid,'') <> ''  
Begin  
 Select @strmachine = ' and ( Machineinformation.MachineID = N''' + @MachineID + ''')'  
End  
  
if isnull(@PlantID,'') <> ''  
Begin  
 Select @strPlantID = ' and ( PlantMachine.PlantID = N''' + @PlantID + ''')'  
End  
  
Select @Startdate = convert(nvarchar(10),@StartDate,120) + ' ' + CAST(datePart(hh,FromTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,FromTime) as nvarchar(2))+ ':' + CAST(datePart(ss,FromTime) as nvarchar(2))
		FROM shiftdetails WHERE shiftid =1 and running = 1


Insert into #ShiftTime(ddate,Shiftname,Starttime,Endtime)    
Exec s_GetShiftTime @Startdate,''     
    
Update #ShiftTime set Shiftid = T.Shiftid from    
(Select shiftdetails.Shiftid,shiftdetails.Shiftname from shiftdetails inner join #ShiftTime on #ShiftTime.Shiftname=shiftdetails.Shiftname    
where running=1)T inner join #ShiftTime on #ShiftTime.Shiftname=T.Shiftname    

  
select @stdate = CAST(datePart(yyyy,ddate) AS nvarchar(4)) + '-' + CAST(datePart(mm,ddate) AS nvarchar(2)) + '-' + CAST(datePart(dd,ddate) AS nvarchar(2)) from #ShiftTime    
    
insert into #HourlyData(Machineid,PDate,ShiftName,ShiftID,Shiftstart,ShiftEnd,HourName,HourID,FromTime,ToTime,Actual,Target,TotalActual,TotalTarget,TotalOutput)    
select @Machineid,@stdate,S.ShiftName,S.Shiftid,S.StartTime,S.Endtime,SH.Hourname,SH.HourID,    
dateadd(day,SH.Fromday,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.HourStart) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourStart) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourStart) as nvarchar(2))))),    
dateadd(day,SH.Today,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.HourEnd) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourEnd) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourEnd) as nvarchar(2))))),0,0 ,0,0,0
 from (Select * from #ShiftTime) S inner join Shifthourdefinition SH on SH.shiftid=S.Shiftid    
order by S.Shiftid,SH.Hourid    

    
Select @T_ST=min(FromTime) from #HourlyData     
Select @T_ED=max(Totime) from #HourlyData     


---mod 12 get the PDT's defined,at shift and Machine level
insert INTO #PlannedDownTimeshour(StartTime,EndTime,Machine,MachineInterface,Downreason,Shiftst)
select
CASE When StartTime<T1.FromTime Then T1.FromTime Else StartTime End,
case When EndTime>T1.ToTime Then T1.ToTime Else EndTime End,Machine,M.InterfaceID,DownReason,T1.FromTime
FROM PlannedDownTimes cross join #HourlyData T1
inner join MachineInformation M on PlannedDownTimes.machine = M.MachineID
WHERE PlannedDownTimes.PDTstatus =1 and (
(StartTime >= T1.FromTime  AND EndTime <=T1.ToTime)
OR ( StartTime < T1.FromTime  AND EndTime <= T1.ToTime AND EndTime > T1.FromTime )
OR ( StartTime >= T1.FromTime   AND StartTime <T1.ToTime AND EndTime > T1.ToTime )
OR ( StartTime < T1.FromTime  AND EndTime > T1.ToTime) )
and machine=@Machineid
ORDER BY StartTime
    

---Getting Production And Down Records    
Select @strsql=''    
select @strsql ='insert into #T_autodataforDown '    
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'    
 select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'    
select @strsql = @strsql + ' from autodata inner join Machineinformation on Machineinformation.interfaceid=Autodata.mc     
where (( sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_ED,120)+''' ) OR '    
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' )OR '    
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ST,120)+'''    
     and ndtime<='''+convert(nvarchar(25),@T_ED,120)+''' )'    
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' and sttime<'''+convert(nvarchar(25),@T_ED,120)+''' ) )'    
select @strsql = @strsql + @strmachine    
--print @strsql    
exec (@strsql)    
    

    
  -------Getting Hourwise Target For the Given Machine and Target is based on Runtime Logic (PDT Applied)-------------------------    
Select @strsql=''   
Select @strsql= 'insert into #Target(MachineID,machineinterface,Component,Compinterface,Operation,Opninterface,  
msttime,ndtime,FromTm,Totm,batchid,autodataid,stdtime,Shift)'  
select @strsql = @strsql + ' SELECT machineinformation.machineid, machineinformation.interfaceid,C.componentid, C.interfaceid,  
O.operationno, O.interfaceid, 
Case when autodata.msttime< T.Fromtime then T.Fromtime else autodata.msttime end,   
Case when autodata.ndtime> T.Totime then T.Totime else autodata.ndtime end,  
T.Fromtime,T.Totime,0,autodata.id,O.Cycletime,T.shiftName FROM #T_autodataforDown  autodata  
INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID   
INNER JOIN componentinformation C ON autodata.comp = C.InterfaceID    
INNER JOIN componentoperationpricing O ON autodata.opn = O.InterfaceID  
AND c.componentid = O.componentid and O.machineid=machineinformation.machineid   
Left Outer Join downcodeinformation DI on DI.interfaceid=autodata.dcode  
Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid   
Cross join #HourlyData T  
WHERE ((autodata.msttime >= T.Fromtime  AND autodata.ndtime <= T.Totime)  
OR ( autodata.msttime < T.Fromtime  AND autodata.ndtime <= T.Totime AND autodata.ndtime >T.Fromtime )  
OR ( autodata.msttime >= T.Fromtime AND autodata.msttime <T.Totime AND autodata.ndtime > T.Totime)  
OR ( autodata.msttime < T.Fromtime AND autodata.ndtime > T.Totime))'  
select @strsql = @strsql + @strmachine + @strPlantID  + @stropr
select @strsql = @strsql + ' order by autodata.msttime'  
print @strsql  
exec (@strsql)  
  
 
declare @mc_prev nvarchar(50),@comp_prev nvarchar(50),@opn_prev nvarchar(50),@opr_prev nvarchar(50),@From_Prev datetime  
declare @mc nvarchar(50),@comp nvarchar(50),@opn nvarchar(50),@opr nvarchar(50),@Fromtime datetime,@id nvarchar(50)  
declare @batchid int  
Declare @autodataid bigint,@autodataid_prev bigint  
  
declare @setupcursor  cursor  
set @setupcursor=cursor for  
select autodataid,FromTm,MachineID,Component,Operation from #Target order by machineid,msttime  
open @setupcursor  
fetch next from @setupcursor into @autodataid,@Fromtime,@mc,@comp,@opn 
  
set @autodataid_prev=@autodataid  
set @mc_prev = @mc  
set @comp_prev = @comp  
set @opn_prev = @opn  
SET @From_Prev = @Fromtime  
set @batchid =1  
  
while @@fetch_status = 0  
begin  
If @mc_prev=@mc and @comp_prev=@comp and @opn_prev=@opn  and @From_Prev = @Fromtime  
 begin    
  update #Target set batchid = @batchid where autodataid=@autodataid and MachineID=@mc and Component=@comp and Operation=@opn  and FromTm=@Fromtime  
  print @batchid  
 end  
 else  
 begin   
    set @batchid = @batchid+1          
    update #Target set batchid = @batchid where autodataid=@autodataid and MachineID=@mc and Component=@comp and Operation=@opn  and FromTm=@Fromtime  
    set @autodataid_prev=@autodataid   
    set @mc_prev=@mc    
    set @comp_prev=@comp  
    set @opn_prev=@opn   
    SET @From_Prev = @Fromtime  
 end   
 fetch next from @setupcursor into @autodataid,@Fromtime,@mc,@comp,@opn  
   
end  
close @setupcursor  
deallocate @setupcursor  
  
insert into #FinalTarget (MachineID,Component,operation,machineinterface,Compinterface,Opninterface,batchid,BatchStart,BatchEnd,FromTm,ToTm,Downtime,
Components,runtime,stdtime,shift,Target)   
Select MachineID,Component,operation,machineinterface,Compinterface,Opninterface,batchid,min(msttime),max(ndtime),FromTm,ToTm,0,0,datediff(s,min(msttime),max(ndtime)),stdtime,shift,0 from #Target   
group by MachineID,Component,operation,machineinterface,Compinterface,Opninterface,batchid,FromTm,ToTm,stdtime,shift order by batchid   


If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')<>'N'    
BEGIN    

Update #FinalTarget set Runtime=Isnull(Runtime,0) - Isnull(T3.pdt,0)     
from (    
Select t2.machineinterface,T2.Machine,T2.BatchStart,T2.BatchEnd,T2.Fromtm,sum(datediff(ss,T2.StartTimepdt,t2.EndTimepdt))as pdt    
from    
(    
Select T1.machineinterface,T1.Compinterface,T1.Opninterface,T1.BatchStart,T1.BatchEnd,T1.FromTm,Pdt.machine,    
Case when  T1.BatchStart <= pdt.StartTime then pdt.StartTime else T1.BatchStart End as StartTimepdt,    
Case when  T1.BatchEnd >= pdt.EndTime then pdt.EndTime else T1.BatchEnd End as EndTimepdt    
from #FinalTarget T1    
inner join #PlannedDownTimeshour pdt on t1.machineid=Pdt.machine    
where     
((pdt.StartTime >= t1.BatchStart and pdt.EndTime <= t1.BatchEnd)or    
(pdt.StartTime < t1.BatchStart and pdt.EndTime > t1.BatchStart and pdt.EndTime <=t1.BatchEnd)or    
(pdt.StartTime >= t1.BatchStart and pdt.StartTime <t1.BatchEnd and pdt.EndTime >t1.BatchEnd) or    
(pdt.StartTime <  t1.BatchStart and pdt.EndTime >t1.BatchEnd))    
)T2 group by  t2.machineinterface,T2.Machine,T2.BatchStart,T2.BatchEnd,T2.Fromtm    
) T3 inner join #FinalTarget T on T.machineinterface=T3.machineinterface and T.BatchStart=T3.BatchStart and  T.BatchEnd=T3.BatchEnd and T.Fromtm=T3.Fromtm    

ENd    
 

  
Update #FinalTarget set Target = Isnull(Target,0) + isnull(T2.targetcount,0) from     
(    
Select T.machineinterface,T.Compinterface,T.Opninterface,T.FromTm,T.BatchStart,T.BatchEnd,FLOOR(sum(((T.Runtime*CO.suboperations)/CO.cycletime)*isnull(CO.targetpercent,100) /100)) as targetcount    
from #FinalTarget T     
inner join machineinformation M on M.Interfaceid=T.machineinterface    
inner join componentinformation C on C.interfaceid=T.Compinterface    
inner join componentoperationpricing CO on M.machineid=co.machineid and c.componentid=Co.componentid    
and Co.interfaceid=T.Opninterface    
group by T.FromTm,T.BatchStart,T.BatchEnd,T.machineinterface,T.Compinterface,T.Opninterface   
)T2 Inner Join #FinalTarget on t2.machineinterface = #FinalTarget.machineinterface and  
	 t2.compinterface = #FinalTarget.compinterface and t2.opninterface = #FinalTarget.opninterface 
	 and #FinalTarget.BatchStart=T2.BatchStart and  #FinalTarget.BatchEnd=T2.BatchEnd and #FinalTarget.Fromtm=T2.Fromtm
    


  
--Calculation of PartsCount Begins..  
UPDATE #FinalTarget SET components = ISNULL(components,0) + ISNULL(t2.comp1,0) 
From  
(  
 Select T1.mc,T1.comp,T1.opn,T1.Batchstart,T1.Batchend,
 SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp1
     From
	 (select mc,comp,opn,BatchStart,BatchEnd,SUM(autodata.partscount)AS OrginalCount from #T_autodataforDown autodata  
     INNER JOIN #FinalTarget F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn   
     where (autodata.ndtime>F.BatchStart) and (autodata.ndtime<=F.BatchEnd) and (autodata.datatype=1)  
     Group By mc,comp,opn,BatchStart,BatchEnd
	 ) as T1  
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
    
 UPDATE #FinalTarget SET components=ISNULL(components,0)- isnull(t2.PlanCt,0) 
  FROM ( select autodata.mc,autodata.comp,autodata.opn,F.Batchstart,F.Batchend,
  ((CAST(Sum(ISNULL(PartsCount,1)) AS Float)/ISNULL(CO.SubOperations,1))) as PlanCt   from #T_autodataforDown autodata   
     INNER JOIN #FinalTarget F on F.machineinterface=autodata.mc and F.Compinterface=autodata.comp and F.Opninterface = autodata.opn  
  Inner jOIN #PlannedDownTimeshour T on T.MachineInterface=autodata.mc    
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
   

---Get the down times which are not of type Management Loss  
  select  F.fromtm as Fromtime,F.Totm as Totime,F.BatchStart,F.BatchEnd,F.Machineid,F.machineinterface, F.Compinterface,F.Opninterface,
  sum (CASE  
	WHEN (autodata.msttime >= F.BatchStart  AND autodata.ndtime <=F.BatchEnd)  THEN autodata.loadunload  
	WHEN ( autodata.msttime < F.BatchStart  AND autodata.ndtime <= F.BatchEnd  AND autodata.ndtime > F.BatchStart ) THEN DateDiff(second,F.BatchStart,autodata.ndtime)  
	WHEN ( autodata.msttime >= F.BatchStart   AND autodata.msttime <F.BatchEnd  AND autodata.ndtime > F.BatchEnd  ) THEN DateDiff(second,autodata.msttime,F.BatchEnd )  
	WHEN ( autodata.msttime < F.BatchStart  AND autodata.ndtime > F.BatchEnd ) THEN DateDiff(second,F.BatchStart,F.BatchEnd )  
	END ) as downtime,downcodeinformation.Downid INTO #DOWN
	from #T_autodataforDown autodata   
	inner join #FinalTarget F on autodata.mc = F.Machineinterface and autodata.comp=F.Compinterface and autodata.opn=F.Opninterface
	inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid 
	where (autodata.datatype='2')  and 
	(( (autodata.msttime>=F.BatchStart) and (autodata.ndtime<=F.BatchEnd))  
	   OR ((autodata.msttime<F.BatchStart)and (autodata.ndtime>F.BatchStart)and (autodata.ndtime<=F.BatchEnd))  
	   OR ((autodata.msttime>=F.BatchStart)and (autodata.msttime<F.BatchEnd)and (autodata.ndtime>F.BatchEnd))  
	   OR((autodata.msttime<F.BatchStart)and (autodata.ndtime>F.BatchEnd)))   
	   group by F.BatchStart,F.BatchEnd,F.machineinterface,F.Machineid,F.Compinterface,F.Opninterface,downcodeinformation.Downid,F.fromtm,F.Totm

 
	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
	BEGIN   

		 UPDATE  #DOWN SET downtime = isnull(downtime,0) - isNull(T2.PPDT ,0)  
		 FROM(  
		 SELECT F.BatchStart,F.BatchEnd,F.fromtm,F.totm,F.machineinterface,F.Compinterface,F.Opninterface,DownCodeInformation.downid,  
			SUM  
			(CASE  
			WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)  
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )  
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
			END ) as PPDT  
			FROM #T_autodataforDown AutoData  
			CROSS jOIN #PlannedDownTimeshour T  
			INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID  
			INNER JOIN #FinalTarget F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn
			WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc   
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
			 group  by F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,DownCodeInformation.downid,F.fromtm,F.totm
		 )AS T2  Inner Join #DOWN on t2.machineinterface = #DOWN.machineinterface and  
		 t2.compinterface = #DOWN.compinterface and t2.opninterface = #DOWN.opninterface  
		 and t2.BatchStart=#DOWN.BatchStart and t2.BatchEnd=#DOWN.BatchEnd  and t2.downid=#DOWN.downid

	END

 Update #DOWN set Downtime = Round(dbo.f_FormatTime(Downtime,'mm'),2)

  -------------------------------- Getting Hourwise TypeID For the Given Machine-------------------------    
  UPDATE #HourlyData SET TypeID = t2.comp     
  from( 
	SELECT t.MachineID,t.FromTime,t.Totime, comp = STUFF((SELECT N', ' + x.component
	FROM #FinalTarget AS x
	WHERE x.MachineID = t.MachineID and x.FromTm = t.FromTime and x.ToTm=t.Totime
	group by x.component
	ORDER BY MIN(x.batchstart)   -- only change
	FOR XML PATH, TYPE).value(N'.[1]', N'nvarchar(max)'), 1, 2, N'')
	FROM dbo.#HourlyData AS t
	GROUP BY t.MachineID,t.FromTime,t.Totime  
   )    
  as t2 inner join #HourlyData on t2.MachineID = #HourlyData.MachineID and t2.FromTime =#HourlyData .FromTime and t2.Totime = #HourlyData.Totime     
 

 UPDATE #HourlyData SET Operation = t2.Opn     
  from(    
	SELECT t.MachineID,t.FromTime,t.Totime, Opn = STUFF((SELECT N', ' + x.Operation
	FROM #FinalTarget AS x
	WHERE x.MachineID = t.MachineID and x.FromTm = t.FromTime and x.ToTm=t.Totime
	group by x.Operation
	ORDER BY MIN(x.batchstart)   -- only change
	FOR XML PATH, TYPE).value(N'.[1]', N'nvarchar(max)'), 1, 2, N'')
	FROM dbo.#HourlyData AS t
	GROUP BY t.MachineID,t.FromTime,t.Totime
	)    
  as t2 inner join #HourlyData on t2.MachineID = #HourlyData.MachineID and t2.FromTime =#HourlyData .FromTime and t2.Totime = #HourlyData.Totime     


 select employeeinformation.Name as oprname, employeeinformation.Employeeid as oprid,#HourlyData.FromTime,#HourlyData.machineID , #HourlyData.Shiftname  
  into #opr from #T_autodataforDown autodata     
  inner join Machineinformation M on autodata.mc=M.interfaceid    
  inner join #HourlyData on #HourlyData.Machineid=#HourlyData.Machineid     
  INNER JOIN employeeinformation ON employeeinformation.interfaceid=autodata.opr     
  where     
  ((autodata.msttime>=#HourlyData.FromTime) and (autodata.ndtime<=#HourlyData.Totime)    
  OR (autodata.msttime<#HourlyData.FromTime and autodata.ndtime>#HourlyData.FromTime and autodata.ndtime<=#HourlyData.Totime)    
  OR (autodata.msttime>=#HourlyData.FromTime and autodata.msttime<#HourlyData.Totime and autodata.ndtime>#HourlyData.Totime)    
  OR (autodata.msttime<#HourlyData.FromTime and autodata.ndtime>#HourlyData.Totime))     
  group by #HourlyData.machineID,employeeinformation.Employeeid,employeeinformation.Name,#HourlyData.FromTime, #HourlyData.Shiftname  
    
  UPDATE #HourlyData SET Employeeid = t2.opr     
  from(    
  SELECT t.machineID , t.Shiftname,   
      STUFF(ISNULL((SELECT ', ' + x.oprid    
      FROM #opr x    
        WHERE x.machineID = t.machineID  and x.Shiftname=t.Shiftname  
     GROUP BY x.oprid    
      FOR 
	  XML PATH (''), TYPE).value('.','VARCHAR(max)'), ''), 1, 2, '') [opr]          
    FROM #opr t)    
  as t2 inner join #HourlyData on t2.machineID =#HourlyData .MachineID  and #HourlyData.Shiftname=t2.Shiftname   


 UPDATE #HourlyData SET actual = t2.actual    
  from(    
 	SELECT t.MachineID,t.FromTime,t.Totime, Actual = STUFF((SELECT N'/ ' + cast(x.components as NVARCHAR(50))
	FROM (Select fromtm,totm,machineid,component,sum(components) as components,Min(Batchstart) as Batchstart from #FinalTarget group by fromtm,totm,machineid,component) AS x
	WHERE x.MachineID = t.MachineID and x.FromTm = t.FromTime and x.ToTm=t.Totime
	group by x.components
	ORDER BY MIN(x.batchstart)   -- only change
	FOR XML PATH, TYPE).value(N'.[1]', N'nvarchar(max)'), 1, 2, N'')
	FROM dbo.#HourlyData AS t
	GROUP BY t.MachineID,t.FromTime,t.Totime)    
  as t2 inner join #HourlyData on t2.MachineID = #HourlyData.MachineID and t2.FromTime =#HourlyData .FromTime and t2.Totime = #HourlyData.Totime 

 UPDATE #HourlyData SET Target = t2.Target    
  from(    
  	SELECT t.MachineID,t.FromTime,t.Totime, target = STUFF((SELECT N'/ ' + cast(x.components as NVARCHAR(50))
	FROM (Select fromtm,totm,machineid,component,sum(target) as components,Min(Batchstart) as Batchstart from #FinalTarget group by fromtm,totm,machineid,component) AS x
	WHERE x.MachineID = t.MachineID and x.FromTm = t.FromTime and x.ToTm=t.Totime
	group by x.components
	ORDER BY MIN(x.batchstart)   -- only change
	FOR XML PATH, TYPE).value(N'.[1]', N'nvarchar(max)'), 1, 2, N'')
	FROM dbo.#HourlyData AS t
	GROUP BY t.MachineID,t.FromTime,t.Totime)    
  as t2 inner join #HourlyData on t2.MachineID = #HourlyData.MachineID and t2.FromTime =#HourlyData .FromTime and t2.Totime = #HourlyData.Totime 


 -------------------------------- Getting Hourwise DownID and Downtime For the Given Machine-------------------------    
  UPDATE #HourlyData SET Downtime = t2.Downid     
  from(    
  SELECT t.MachineID,t.FromTime ,t.Totime,    
      STUFF(ISNULL((SELECT ' , ' + x.downid + ' [' + cast(sum(x.downtime)as nvarchar(max))  + ']'    
      FROM #Down x     
        WHERE x.downtime<>0 and x.MachineID = t.MachineID and x.Fromtime = t.FromTime and x.Totime=t.Totime     
     GROUP BY x.downid  order by sum(x.downtime) desc,x.downid asc    
      FOR XML PATH (''), TYPE).value('.','nVARCHAR(max)'), ''), 1, 2, '') [downid]          
    FROM #Down t )    
  as t2 inner join #HourlyData on t2.MachineID = #HourlyData.MachineID and t2.FromTime =#HourlyData .FromTime and t2.Totime = #HourlyData.Totime  

 UPDATE #HourlyData SET TotalTarget = t2.TotalTarget,TotalActual = t2.TotalActual from
(select Machineid,Shift,SUM(Components) as TotalActual,SUM(Target) as TotalTarget from #FinalTarget
group by Machineid,Shift)    
as t2 inner join #HourlyData on t2.machineID =#HourlyData.MachineID  and t2.Shift= #HourlyData.Shiftname

update #HourlyData set TotalOutput = Round((TotalActual/TotalTarget)*100,2) where TotalActual>0

select Machineid,Employeeid,Shiftname,ShiftID,RIGHT('0'+LTRIM(RIGHT(CONVERT(varchar,Fromtime,100),8)),7) + '-' +  RIGHT('0'+LTRIM(RIGHT(CONVERT(varchar,Totime,100),8)),7) as shifthours,
TypeId as Component,operation as OpnNo,Target,Actual,Downtime,TotalTarget,TotalActual,TotalOutput from #HourlyData order by Fromtime

return

   
END  
