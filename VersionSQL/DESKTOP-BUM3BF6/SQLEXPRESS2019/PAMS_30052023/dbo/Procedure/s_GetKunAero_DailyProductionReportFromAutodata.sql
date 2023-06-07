/****** Object:  Procedure [dbo].[s_GetKunAero_DailyProductionReportFromAutodata]    Committed by VersionSQL https://www.versionsql.com ******/

--ER0465 - SwathiKS - 2018/06/06 :: Created new procedure to Show production and Down data for KunAeroSpace.
--Launch: Std-Prodction and Down Report - Daily By Hour Format - Daily Shiftwise Prod-Excel
--[s_GetKunAero_DailyProductionReportFromAutodata] '2018-07-24','','',''

CREATE PROCEDURE [dbo].[s_GetKunAero_DailyProductionReportFromAutodata]
	@StartDate datetime,
	@Shift nvarchar(20),
	@MachineID nvarchar(50) = '',
	@PlantID  Nvarchar(50) = '',
	@param nvarchar(50)=''

WITH RECOMPILE
AS
BEGIN

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

Declare @strsql nvarchar(4000)
Declare @strmachine nvarchar(255)
Declare @StrTPMMachines AS nvarchar(500)
Declare @StrMPlantid NVarChar(255)
Declare @timeformat as nvarchar(12)

Declare @StartTime as datetime
Declare @EndTime as datetime
Select @strsql = ''
Select @StrTPMMachines = ''
Select @strmachine = ''
Select @StrMPlantid=''

-- mod 4
IF ( SELECT TOP 1 ValueInText FROM  CockpitDefaults WHERE Parameter='TpmEnbMac')='E'
BEGIN
	SET  @StrTPMMachines = 'AND MachineInformation.TPMTrakEnabled = 1'
END
ELSE
BEGIN
	SET  @StrTPMMachines = ' '
END

if isnull(@PlantID,'') <> ''
Begin
	Select @StrMPlantid = ' and ( PlantMachine.PlantID = N''' + @PlantID + ''')'
End

if isnull(@machineid,'') <> ''
Begin
	Select @strmachine = ' and ( Machineinformation.MachineID = N''' + @MachineID + ''')'
End


--Shift Details
CREATE TABLE #shiftdetails (
	PDate datetime,
	Shift nvarchar(20),
	ShiftStart datetime,
	ShiftEnd datetime,
	Shiftid int
)
--MCOW level details

CREATE TABLE #Target 
(
	MachineID nvarchar(50) NOT NULL,
	MachineInterface nvarchar(50),
	Component nvarchar(50) NOT NULL,
	Operation nvarchar(50) NOT NULL,
	CompInterface nvarchar(50),
	OpnInterface nvarchar(50),
	WorkOrderNo nvarchar(50),
	Compdescription nvarchar(100),
	CustomerName nvarchar(50),
	WorkOrderdate datetime,
	WorkOrderQty nvarchar(50),
	StdCycletime float,
	StdLoadunload float,
	Stdmctime float,
	Suboperations int,
	Targetpercent int,
	msttime datetime,
	ndtime datetime,
	PDate datetime,
	FromTm datetime,  
	ToTm datetime,  
	Shift nvarchar(20) 
)

CREATE TABLE #FinalTarget 
(
	MachineID nvarchar(50) NOT NULL,
	MachineInterface nvarchar(50),
	Component nvarchar(50) NOT NULL,
	Operation nvarchar(50) NOT NULL,
	CompInterface nvarchar(50),
	OpnInterface nvarchar(50),
	WorkOrderNo nvarchar(50),
	Compdescription nvarchar(100),
	CustomerName nvarchar(50),
	WorkOrderdate datetime,
	WorkOrderQty nvarchar(50),
	StdMctime float,
	StdCycletime float,
	StdLoadunload float,
	Suboperations int,
	Targetpercent int,
	PcountPerhr float,
	PlanQty int default 0,
	Accepted int default 0,
	Rejected int default 0,
	AcceptPercent float default 0,
	Rejectpercent float default 0,
	Downtime float,
	Operatorname nvarchar(4000),
	msttime datetime,
	ndtime datetime,
	PDate datetime,
	FromTm datetime,  
	ToTm datetime,  
	Shift nvarchar(20),
	shiftid int,
	batchid int,
	runtime float,
	Remarks nvarchar(max)
)


CREATE TABLE #FinalTarget1
(
	id int identity(1,1) not null,
	MachineID nvarchar(50) NOT NULL,
	MachineInterface nvarchar(50),
	Component nvarchar(50) NOT NULL,
	Operation nvarchar(50) NOT NULL,
	CompInterface nvarchar(50),
	OpnInterface nvarchar(50),
	WorkOrderNo nvarchar(50),
	Compdescription nvarchar(100),
	CustomerName nvarchar(50),
	WorkOrderdate datetime,
	WorkOrderQty nvarchar(50),
	StdCycletime float,
	StdLoadunload float,
	Stdmctime float,
	Suboperations int,
	Targetpercent int,
	PcountPerhr float,
	Shift1PlanQty int default 0,
	Shift1Accepted int default 0,
	Shift1Rejected int default 0,
	Shift1AcceptPercent float,
	Shift1Rejectpercent float,
	Shift1Downtime float default 0,
	Shift1Operatorname nvarchar(4000),
	Shift1Remarks nvarchar(max),
	Shift2PlanQty int default 0,
	Shift2Accepted int default 0,
	Shift2Rejected int default 0,
	Shift2AcceptPercent float,
	Shift2Rejectpercent float,
	Shift2Downtime float default 0,
	Shift2Operatorname nvarchar(4000),
	Shift2Remarks nvarchar(max),
	Shift3PlanQty int default 0,
	Shift3Accepted int default 0,
	Shift3Rejected int default 0,
	Shift3AcceptPercent float,
	Shift3Rejectpercent float,
	Shift3Downtime float default 0,
	Shift3Operatorname nvarchar(4000),
	Shift3Remarks nvarchar(max),
	WorkingHrs float,
	DownTimeinHrs float,
	ProdTotal float default 0,
	CumulativeProdTotal float,
	CumulativeRejTotal float,
	PrevdayAccepted float default 0,
	PrevdayRejected float default 0,
	Total nvarchar(50) default 0,
	Productivetime nvarchar(50) default 0,
	NonProductiveTime nvarchar(50) default 0,
	OverallPercent float,
	A  float,
	B  float,
	C  float,
	D  float,
	E  float,
	F  float,
	G  float,
	H  float,
	CN float
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
 [PartsCount] decimal(18,5) NULL ,
 id  bigint not null,
 [WorkOrderNumber] [nvarchar](50)
)  
  
ALTER TABLE #T_autodata  
  
ADD PRIMARY KEY CLUSTERED  
(  
 mc,sttime ASC  
)ON [PRIMARY]  


Create table #Downcode
(
	Slno int identity(1,1) NOT NULL,
	Downid nvarchar(50)
)

Insert into #Downcode(Downid)
Select top 8 downid from downcodeinformation where 
SortOrder<=8 and SortOrder IS NOT NULL order by sortorder

If @param = 'DownCodeList'
Begin
	select downid from #Downcode order by slno
	return
end 

Declare @PrevDay as datetime
Declare @T_Start AS Datetime   
Declare @T_End AS Datetime  
   
INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)  
EXEC s_GetShiftTime @startdate,''  

Select @PrevDay = convert(datetime, convert(nvarchar(10),@StartDate,120) + ' ' + CAST(datePart(hh,FromTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,FromTime) as nvarchar(2))+ ':' + CAST(datePart(ss,FromTime) as nvarchar(2)))
from shiftdetails where Running=1 and shiftid=1

Declare @MonthStart as Datetime  
Select @MonthStart = dbo.f_GetLogicalMonth(@Startdate,'start')   
  

select @T_Start = @MonthStart
Select @T_End = max(ShiftEnd) from #shiftdetails 

Select @strsql=''  
select @strsql ='insert into #T_autodata '  
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'  
 select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id,WorkOrderNumber'  
select @strsql = @strsql + ' from autodata WITH(NOLOCK) where (( sttime >='''+ convert(nvarchar(25),@T_Start,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_End,120)+''' ) OR '  
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_Start,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_End,120)+''' )OR '  
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_Start,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_Start,120)+'''  
     and ndtime<='''+convert(nvarchar(25),@T_End,120)+''' )'  
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_Start,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_End,120)+''' and sttime<'''+convert(nvarchar(25),@T_End,120)+''' ) )'  
print @strsql  
exec (@strsql)  

Select @T_Start=min(ShiftStart) from #shiftdetails  
Select @T_End=max(ShiftEnd) from #shiftdetails 

/* Planned Down times for the given time period */  
Select @strsql=''  
select @strsql = 'insert INTO #PlannedDownTimesShift(StartTime,EndTime,Machine,MachineInterface,Downreason,Shiftst)'  
select @strsql = @strsql + 'select  
CASE When StartTime<T1.ShiftStart Then T1.ShiftStart Else StartTime End,  
case When EndTime>T1.ShiftEnd Then T1.ShiftEnd Else EndTime End,  
Machine,MachineInformation.InterfaceID,  
DownReason,T1.ShiftStart  
FROM PlannedDownTimes cross join #ShiftDetails T1  
inner join MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID  
WHERE PDTstatus =1 and (  
(StartTime >= T1.ShiftStart  AND EndTime <=T1.ShiftEnd)  
OR ( StartTime < T1.ShiftStart  AND EndTime <= T1.ShiftEnd AND EndTime > T1.ShiftStart )  
OR ( StartTime >= T1.ShiftStart   AND StartTime <T1.ShiftEnd AND EndTime > T1.ShiftEnd )  
OR ( StartTime < T1.ShiftStart  AND EndTime > T1.ShiftEnd) )'  
select @strsql = @strsql + @strmachine   
select @strsql = @strsql + 'ORDER BY StartTime'  
print @strsql  
exec (@strsql)  


select M.machineid, M.interfaceid as MachineInterface,C.componentid, C.interfaceid as CompInterface,  
C.description,C.customerid,O.operationno, O.interfaceid as OpnInterface,
O.machiningtime,O.cycletime,(O.cycletime-O.machiningtime) as StdLoadunload,O.Suboperations,O.TargetPercent into #MCO from
(select distinct mc,comp,opn from #T_autodata)autodata INNER JOIN  machineinformation M ON autodata.mc = M.InterfaceID   
INNER JOIN componentinformation C ON autodata.comp = C.InterfaceID    
INNER JOIN componentoperationpricing O ON autodata.opn = O.InterfaceID  
AND C.componentid = O.componentid and O.machineid=M.machineid   


/*
Select @strsql=''   
Select @strsql= 'insert into #Target(MachineID,MachineInterface,Component,CompInterface,Compdescription,CustomerName,Operation,OpnInterface,WorkOrderNo,WorkOrderDate,WorkOrderQty,Stdmctime,StdCycletime,StdLoadunload,Suboperations,TargetPercent,msttime,ndtime,
Pdate,Shift,fromtm,totm)'  
select @strsql = @strsql + ' SELECT distinct machineinformation.machineid, machineinformation.interfaceid,componentinformation.componentid, componentinformation.interfaceid,  
componentinformation.description,componentinformation.customerid,componentoperationpricing.operationno, componentoperationpricing.interfaceid,autodata.workordernumber, MOS.DateOfRequirement, MOS.Quantity,
componentoperationpricing.machiningtime,componentoperationpricing.cycletime,(componentoperationpricing.cycletime-componentoperationpricing.machiningtime),componentoperationpricing.Suboperations,componentoperationpricing.TargetPercent,
Case when autodata.msttime< T.Shiftstart then T.Shiftstart else autodata.msttime end,   
Case when autodata.ndtime> T.ShiftEnd then T.ShiftEnd else autodata.ndtime end,T.Pdate,T.Shift,T.Shiftstart,T.shiftend FROM #T_autodata autodata  
INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID   
INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID    
INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID  
AND componentinformation.componentid = componentoperationpricing.componentid and componentoperationpricing.machineid=machineinformation.machineid   
Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid   
left outer join MOschedule MOS on MOS.Partid=componentinformation.componentid and autodata.workordernumber=MOS.Monumber
Cross join #ShiftDetails T  
WHERE ((autodata.msttime >= T.Shiftstart  AND autodata.ndtime <= T.ShiftEnd)  
OR ( autodata.msttime < T.Shiftstart  AND autodata.ndtime <= T.ShiftEnd AND autodata.ndtime >T.Shiftstart )  
OR ( autodata.msttime >= T.Shiftstart AND autodata.msttime <T.ShiftEnd AND autodata.ndtime > T.ShiftEnd)  
OR ( autodata.msttime < T.Shiftstart AND autodata.ndtime > T.ShiftEnd))'  
select @strsql = @strsql + @strmachine + @StrMPlantid
print @strsql  
exec (@strsql)  
*/


Select @strsql=''   
Select @strsql= 'insert into #Target(MachineID,MachineInterface,Component,CompInterface,Compdescription,CustomerName,Operation,OpnInterface,WorkOrderNo,WorkOrderDate,WorkOrderQty,Stdmctime,StdCycletime,StdLoadunload,Suboperations,TargetPercent,msttime,ndtime,
Pdate,Shift,fromtm,totm)'  
select @strsql = @strsql + ' SELECT distinct machineinformation.machineid, machineinformation.interfaceid,MCO.componentid, MCO.CompInterface,  
MCO.description,MCO.customerid,MCO.operationno, MCO.OpnInterface,autodata.workordernumber, MOS.DateOfRequirement, MOS.Quantity,
MCO.machiningtime,MCO.cycletime,MCO.StdLoadunload,MCO.Suboperations,MCO.TargetPercent,
Case when autodata.msttime< T.Shiftstart then T.Shiftstart else autodata.msttime end,   
Case when autodata.ndtime> T.ShiftEnd then T.ShiftEnd else autodata.ndtime end,T.Pdate,T.Shift,T.Shiftstart,T.shiftend FROM #T_autodata autodata  
INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID     
INNER JOIN #MCO MCO  on autodata.mc=MCO.MachineInterface and autodata.comp=MCO.CompInterface and autodata.opn=MCO.Opninterface
Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid   
--left outer join MOschedule MOS on MOS.Partid=MCO.componentid and autodata.workordernumber=MOS.Monumber
left outer join MOschedule MOS on autodata.workordernumber=MOS.Monumber
Cross join #ShiftDetails T  
WHERE ((autodata.msttime >= T.Shiftstart  AND autodata.ndtime <= T.ShiftEnd)  
OR ( autodata.msttime < T.Shiftstart  AND autodata.ndtime <= T.ShiftEnd AND autodata.ndtime >T.Shiftstart )  
OR ( autodata.msttime >= T.Shiftstart AND autodata.msttime <T.ShiftEnd AND autodata.ndtime > T.ShiftEnd)  
OR ( autodata.msttime < T.Shiftstart AND autodata.ndtime > T.ShiftEnd))'  
select @strsql = @strsql + @strmachine + @StrMPlantid
print @strsql  
exec (@strsql)  

insert into #FinalTarget (MachineID,MachineInterface,Component,CompInterface,Compdescription,CustomerName,Operation,OpnInterface,WorkOrderNo,WorkOrderDate,WorkOrderQty,StdMctime,StdCycletime,StdLoadunload,Suboperations,TargetPercent,msttime,ndtime,batchid,Pdate,Shift,FromTm,ToTm)
select MachineID,MachineInterface,Component,CompInterface,Compdescription,CustomerName,Operation,OpnInterface,WorkOrderNo,WorkOrderDate,WorkOrderQty,StdMctime,StdCycletime,StdLoadunload,Suboperations,TargetPercent,min(msttime),max(ndtime),batchid,Pdate,Shift,FromTm,ToTm
from
(
select MachineID,MachineInterface,Component,CompInterface,Compdescription,CustomerName,Operation,OpnInterface,WorkOrderNo,WorkOrderDate,WorkOrderQty,StdMctime,StdCycletime,StdLoadunload,Suboperations,TargetPercent,msttime,ndtime,Pdate,Shift,FromTm,ToTm,
RANK() OVER (
  PARTITION BY t.machineid
  order by t.machineid, t.msttime
) -
RANK() OVER (
  PARTITION BY  t.machineid, t.component, t.operation, t.workorderno,t.fromtm
  order by t.machineid, t.fromtm,t.msttime
) AS batchid
from #Target t 
) tt
group by  MachineID,MachineInterface,Component,CompInterface,Compdescription,CustomerName,Operation,OpnInterface,WorkOrderNo,WorkOrderDate,WorkOrderQty,StdMctime,StdCycletime,StdLoadunload,Suboperations,TargetPercent,batchid,Pdate,Shift,FromTm,ToTm
order by tt.batchid


update #FinalTarget set shiftid = T.shiftid from
(select shiftname,shiftid from shiftdetails where Running=1)t inner join #FinalTarget F ON T.ShiftName=f.Shift
 
update  #FinalTarget set runtime=datediff(second,msttime,ndtime)

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')<>'N'
BEGIN

	Update #FinalTarget set Runtime=Isnull(Runtime,0) - Isnull(T3.pdt,0) 
	from (
	Select t2.machineinterface,T2.Machine,T2.msttime,T2.ndtime,T2.Fromtm,sum(datediff(ss,T2.StartTimepdt,t2.EndTimepdt))as pdt
	from
		(
		Select T1.machineinterface,T1.Compinterface,T1.Opninterface,T1.msttime,T1.ndtime,T1.FromTm,Pdt.machine,
		Case when  T1.msttime <= pdt.StartTime then pdt.StartTime else T1.msttime End as StartTimepdt,
		Case when  T1.ndtime >= pdt.EndTime then pdt.EndTime else T1.ndtime End as EndTimepdt
		from #FinalTarget T1
		inner join Planneddowntimes pdt on t1.machineid=Pdt.machine
		where PDTstatus = 1  and
		((pdt.StartTime >= t1.msttime and pdt.EndTime <= t1.ndTime)or
		(pdt.StartTime < t1.msttime and pdt.EndTime > t1.msttime and pdt.EndTime <=t1.ndTime)or
		(pdt.StartTime >= t1.msttime and pdt.StartTime <t1.ndTime and pdt.EndTime >t1.ndTime) or
		(pdt.StartTime <  t1.msttime and pdt.EndTime >t1.ndTime))
		)T2 group by  t2.machineinterface,T2.Machine,T2.msttime,T2.ndtime,T2.Fromtm
	) T3 inner join #FinalTarget T on T.machineinterface=T3.machineinterface and T.msttime=T3.msttime and  T.ndtime=T3.ndtime and T.Fromtm=T3.Fromtm

ENd
	
Update #FinalTarget set PlanQty = Isnull(PlanQty,0) + isnull(T1.targetcount,0) from 
(
	Select T.Machineid,T.FromTm,T.ToTm,T.msttime,T.ndtime,sum(((T.Runtime*T.Suboperations)/T.StdCycletime)*isnull(T.Targetpercent,100) /100) as targetcount
	from #FinalTarget T 
	group by T.Machineid,T.FromTm,T.ToTm,T.msttime,T.ndtime
)T1 inner join #FinalTarget on #FinalTarget.machineid=T1.machineid and #FinalTarget.FromTm=T1.FromTm and  #FinalTarget.msttime=T1.msttime



--Calculation of PartsCount Begins..  
UPDATE #FinalTarget SET Accepted = ISNULL(Accepted,0) + ISNULL(t2.comp1,0)
From  
(  
 Select T1.mc,T1.comp,T1.opn,T1.WorkOrderNumber,T1.msttime,T1.ndtime,T1.FromTm,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(F.SubOperations,1))) As Comp1 From 
	 (select autodata.mc,autodata.comp,autodata.opn,autodata.WorkOrderNumber,F.msttime,F.ndtime,F.FromTm,SUM(autodata.partscount)AS OrginalCount from #T_autodata autodata  
     INNER JOIN #FinalTarget F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn and F.WorkOrderNo=Autodata.WorkOrderNumber  
     where (autodata.ndtime>F.msttime) and (autodata.ndtime<=F.ndtime) and (autodata.datatype=1)  
     Group By autodata.mc,autodata.comp,autodata.opn,autodata.WorkOrderNumber,F.msttime,F.ndtime,F.FromTm
	 ) as T1  
 INNER JOIN #FinalTarget F on F.machineinterface=T1.mc and F.Compinterface=T1.comp and F.Opninterface = T1.opn and F.WorkOrderNo=T1.WorkOrderNumber  
 and F.msttime=T1.msttime and F.FromTm=T1.FromTm
 GROUP BY T1.mc,T1.comp,T1.opn,T1.WorkOrderNumber,T1.msttime,T1.ndtime,T1.FromTm
) As T2 Inner Join #FinalTarget on T2.mc = #FinalTarget.machineinterface and T2.comp = #FinalTarget.compinterface and T2.opn = #FinalTarget.opninterface and  T2.WorkOrderNumber = #FinalTarget.WorkOrderNo   
and T2.msttime=#FinalTarget.msttime and T2.FromTm=#FinalTarget.FromTm  
  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
BEGIN  
    
 UPDATE #FinalTarget SET Accepted=ISNULL(Accepted,0)- isnull(t2.PlanCt,0) FROM
 ( 
	SELECT autodata.mc,autodata.comp,autodata.opn,autodata.WorkOrderNumber,F.msttime,F.FromTm,((CAST(Sum(ISNULL(PartsCount,1)) AS Float)/ISNULL(F.SubOperations,1))) as PlanCt
	from #T_autodata autodata   
	INNER JOIN #FinalTarget F on F.machineinterface=autodata.mc and F.Compinterface=autodata.comp and F.Opninterface = autodata.opn and F.WorkOrderNo=autodata.WorkOrderNumber  
	Inner jOIN #PlannedDownTimesShift T on T.MachineInterface=autodata.mc    
	WHERE autodata.DataType=1 and  
	(autodata.ndtime>F.msttime) and (autodata.ndtime<=F.ndtime)   
	AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)  
	Group by autodata.mc,autodata.comp,autodata.opn,autodata.WorkOrderNumber,F.msttime,F.FromTm,F.SubOperations
 ) as T2 Inner Join #FinalTarget on T2.mc = #FinalTarget.machineinterface and T2.comp = #FinalTarget.compinterface and T2.opn = #FinalTarget.opninterface and  T2.WorkOrderNumber = #FinalTarget.WorkOrderNo   
and T2.msttime=#FinalTarget.msttime and T2.FromTm=#FinalTarget.FromTm  
END  


Update #FinalTarget set Rejected = isnull(Rejected,0) + isnull(T2.RejQty,0)  
From  
( Select A.mc,A.comp,A.opn,A.WorkOrderNumber,F.msttime,F.FromTm,SUM(A.Rejection_Qty) as RejQty from AutodataRejections A  
INNER JOIN #FinalTarget F on F.machineinterface=A.mc and F.Compinterface=A.comp and F.Opninterface = A.opn and F.WorkOrderNo=A.WorkOrderNumber
and convert(nvarchar(10),(A.RejDate),126)=convert(nvarchar(10),(F.PDate),126) and A.RejShift=F.shiftid 
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid  
where A.flag = 'Rejection' and A.Rejshift in (f.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (convert(nvarchar(10),(F.PDate),126)) and 
Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'  
group by A.mc,A.comp,A.opn,A.WorkOrderNumber,F.msttime,F.FromTm 
)T2 Inner Join #FinalTarget on T2.mc = #FinalTarget.machineinterface and T2.comp = #FinalTarget.compinterface and T2.opn = #FinalTarget.opninterface and  T2.WorkOrderNumber = #FinalTarget.WorkOrderNo   
and T2.msttime=#FinalTarget.msttime and T2.FromTm=#FinalTarget.FromTm  
   
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
BEGIN  

Update #FinalTarget set Rejected = isnull(Rejected,0) - isnull(T2.RejQty,0)  
From  
( Select A.mc,A.comp,A.opn,A.WorkOrderNumber,F.msttime,F.FromTm,SUM(A.Rejection_Qty) as RejQty from AutodataRejections A  
INNER JOIN #FinalTarget F on F.machineinterface=A.mc and F.Compinterface=A.comp and F.Opninterface = A.opn and F.WorkOrderNo=A.WorkOrderNumber
and convert(nvarchar(10),(A.RejDate),126)=convert(nvarchar(10),(F.PDate),126) and A.RejShift=F.shiftid 
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid  
Cross join #PlannedDownTimesShift P  
where A.flag = 'Rejection' and A.Rejshift in (f.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (convert(nvarchar(10),(F.PDate),126)) and 
Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'  
and P.starttime>=F.msttime and P.Endtime<=F.ndtime
group by A.mc,A.comp,A.opn,A.WorkOrderNumber,F.msttime,F.FromTm 
)T2 Inner Join #FinalTarget on T2.mc = #FinalTarget.machineinterface and T2.comp = #FinalTarget.compinterface and T2.opn = #FinalTarget.opninterface and  T2.WorkOrderNumber = #FinalTarget.WorkOrderNo   
and T2.msttime=#FinalTarget.msttime and T2.FromTm=#FinalTarget.FromTm 

END  

/*
---Get the down times 
UPDATE #FinalTarget SET downtime = isnull(downtime,0) + isNull(t2.down,0)  
from  
(select  F.msttime,F.ndtime,F.machineinterface,F.Compinterface,F.Opninterface,F.Workorderno,F.FromTm,
sum (CASE  
WHEN (autodata.msttime >= F.msttime  AND autodata.ndtime <=F.ndtime)  THEN autodata.loadunload  
WHEN ( autodata.msttime < F.msttime  AND autodata.ndtime <= F.ndtime  AND autodata.ndtime > F.msttime ) THEN DateDiff(second,F.msttime,autodata.ndtime)  
WHEN ( autodata.msttime >= F.msttime   AND autodata.msttime <F.ndtime  AND autodata.ndtime > F.ndtime  ) THEN DateDiff(second,autodata.msttime,F.ndtime )  
WHEN ( autodata.msttime < F.msttime  AND autodata.ndtime > F.ndtime ) THEN DateDiff(second,F.msttime,F.ndtime )  
END ) as down  
from #T_autodata autodata   
inner join #FinalTarget F on autodata.mc = F.Machineinterface and autodata.comp=F.Compinterface and autodata.opn=F.Opninterface and autodata.WorkOrderNumber = F.WorkOrderNo  
inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid  
where (autodata.datatype=2) AND  
(( (autodata.msttime>=F.msttime) and (autodata.ndtime<=F.ndtime))  
    OR ((autodata.msttime<F.msttime)and (autodata.ndtime>F.msttime)and (autodata.ndtime<=F.ndtime))  
    OR ((autodata.msttime>=F.msttime)and (autodata.msttime<F.ndtime)and (autodata.ndtime>F.ndtime))  
    OR((autodata.msttime<F.msttime)and (autodata.ndtime>F.ndtime)))   
    group by F.msttime,F.ndtime,F.machineinterface,F.Compinterface,F.Opninterface,F.Workorderno ,F.FromTm
) as t2 Inner Join #FinalTarget on t2.machineinterface = #FinalTarget.machineinterface and  
t2.compinterface = #FinalTarget.compinterface and t2.opninterface = #FinalTarget.opninterface and  t2.Workorderno = #FinalTarget.Workorderno   
and t2.msttime=#FinalTarget.msttime and t2.ndtime=#FinalTarget.ndtime and t2.FromTm=#FinalTarget.FromTm
  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
BEGIN   
 UPDATE  #FinalTarget SET Downtime = isnull(Downtime,0) - isNull(T2.PPDT ,0)  
 FROM(  
 SELECT F.msttime,F.ndtime,F.machineinterface,F.Compinterface,F.Opninterface,F.Workorderno,F.FromTm,
    SUM  
    (CASE  
    WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)  
    WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
    WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )  
    WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
    END ) as PPDT  
    FROM #T_autodata AutoData  
    CROSS jOIN #PlannedDownTimesShift T  
    INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID  
    INNER JOIN #FinalTarget F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn and F.Workorderno=Autodata.WorkOrderNumber  
    WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc 
     AND  
     ((autodata.sttime >= F.msttime  AND autodata.ndtime <=F.ndtime)  
     OR ( autodata.sttime < F.msttime  AND autodata.ndtime <= F.ndtime AND autodata.ndtime > F.msttime )  
     OR ( autodata.sttime >= F.msttime   AND autodata.sttime <F.ndtime AND autodata.ndtime > F.ndtime )  
     OR ( autodata.sttime < F.msttime  AND autodata.ndtime > F.ndtime))  
     AND  
     ((autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
     OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
     OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )  
     OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )   
     AND  
	((T.StartTime >= F.msttime AND T.EndTime <=F.ndtime)  
	OR ( T.StartTime < F.msttime AND T.EndTime <= F.ndtime AND t.EndTime > F.msttime)  
	OR ( T.StartTime >= F.msttime AND T.StartTime <F.ndtime AND T.EndTime > F.ndtime)  
	OR ( T.StartTime < F.msttime AND T.EndTime > F.ndtime) )
     group  by F.msttime,F.ndtime,F.machineinterface,F.Compinterface,F.Opninterface,F.Workorderno,F.FromTm  
 )AS T2  Inner Join #FinalTarget on t2.machineinterface = #FinalTarget.machineinterface and  
 t2.compinterface = #FinalTarget.compinterface and t2.opninterface = #FinalTarget.opninterface and  t2.Workorderno = #FinalTarget.Workorderno   
 and t2.msttime=#FinalTarget.msttime and t2.ndtime=#FinalTarget.ndtime and t2.FromTm=#FinalTarget.FromTm
 END
 */

select  F.msttime,F.ndtime,F.machineinterface,F.Compinterface,F.Opninterface,F.Workorderno,F.FromTm,downcodeinformation.downid,
sum (CASE  
WHEN (autodata.msttime >= F.msttime  AND autodata.ndtime <=F.ndtime)  THEN autodata.loadunload  
WHEN ( autodata.msttime < F.msttime  AND autodata.ndtime <= F.ndtime  AND autodata.ndtime > F.msttime ) THEN DateDiff(second,F.msttime,autodata.ndtime)  
WHEN ( autodata.msttime >= F.msttime   AND autodata.msttime <F.ndtime  AND autodata.ndtime > F.ndtime  ) THEN DateDiff(second,autodata.msttime,F.ndtime )  
WHEN ( autodata.msttime < F.msttime  AND autodata.ndtime > F.ndtime ) THEN DateDiff(second,F.msttime,F.ndtime )  
END ) as Downtime into #Down
from #T_autodata autodata   
inner join #FinalTarget F on autodata.mc = F.Machineinterface and autodata.comp=F.Compinterface and autodata.opn=F.Opninterface and autodata.WorkOrderNumber = F.WorkOrderNo  
inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid  
where (autodata.datatype=2) AND  
(( (autodata.msttime>=F.msttime) and (autodata.ndtime<=F.ndtime))  
OR ((autodata.msttime<F.msttime)and (autodata.ndtime>F.msttime)and (autodata.ndtime<=F.ndtime))  
OR ((autodata.msttime>=F.msttime)and (autodata.msttime<F.ndtime)and (autodata.ndtime>F.ndtime))  
OR((autodata.msttime<F.msttime)and (autodata.ndtime>F.ndtime)))   
group by F.msttime,F.ndtime,F.machineinterface,F.Compinterface,F.Opninterface,F.Workorderno ,F.FromTm,downcodeinformation.downid

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
BEGIN   
 UPDATE  #Down SET Downtime = isnull(Downtime,0) - isNull(T2.PPDT ,0)  
 FROM(  
 SELECT F.msttime,F.ndtime,F.machineinterface,F.Compinterface,F.Opninterface,F.Workorderno,F.FromTm,downcodeinformation.downid,
    SUM  
    (CASE  
    WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)  
    WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
    WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )  
    WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
    END ) as PPDT  
    FROM #T_autodata AutoData  
    CROSS jOIN #PlannedDownTimesShift T  
    INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID  
    INNER JOIN #FinalTarget F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn and F.Workorderno=Autodata.WorkOrderNumber  
    WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc 
     AND  
     ((autodata.sttime >= F.msttime  AND autodata.ndtime <=F.ndtime)  
     OR ( autodata.sttime < F.msttime  AND autodata.ndtime <= F.ndtime AND autodata.ndtime > F.msttime )  
     OR ( autodata.sttime >= F.msttime   AND autodata.sttime <F.ndtime AND autodata.ndtime > F.ndtime )  
     OR ( autodata.sttime < F.msttime  AND autodata.ndtime > F.ndtime))  
     AND  
     ((autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
     OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
     OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )  
     OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )   
     AND  
	((T.StartTime >= F.msttime AND T.EndTime <=F.ndtime)  
	OR ( T.StartTime < F.msttime AND T.EndTime <= F.ndtime AND t.EndTime > F.msttime)  
	OR ( T.StartTime >= F.msttime AND T.StartTime <F.ndtime AND T.EndTime > F.ndtime)  
	OR ( T.StartTime < F.msttime AND T.EndTime > F.ndtime) )
     group  by F.msttime,F.ndtime,F.machineinterface,F.Compinterface,F.Opninterface,F.Workorderno,F.FromTm ,downcodeinformation.downid
 )AS T2  Inner Join #Down on t2.machineinterface = #Down.machineinterface and  
 t2.compinterface = #Down.compinterface and t2.opninterface = #Down.opninterface and  t2.Workorderno = #Down.Workorderno   
 and t2.msttime=#Down.msttime and t2.ndtime=#Down.ndtime and t2.FromTm=#Down.FromTm and t2.downid=#Down.downid
 END

UPDATE #FinalTarget SET downtime = isnull(downtime,0) + isNull(t2.down,0)  
from  
(select  F.msttime,F.ndtime,F.machineinterface,F.Compinterface,F.Opninterface,F.Workorderno,F.FromTm,sum(D.Downtime) as down  from #down D 
inner join #FinalTarget F on D.MachineInterface= F.Machineinterface and D.CompInterface=F.Compinterface and D.OpnInterface=F.Opninterface and D.WorkOrderNo= F.WorkOrderNo  
group by F.msttime,F.ndtime,F.machineinterface,F.Compinterface,F.Opninterface,F.Workorderno ,F.FromTm
) as t2 Inner Join #FinalTarget on t2.machineinterface = #FinalTarget.machineinterface and  
t2.compinterface = #FinalTarget.compinterface and t2.opninterface = #FinalTarget.opninterface and  t2.Workorderno = #FinalTarget.Workorderno   
and t2.msttime=#FinalTarget.msttime and t2.ndtime=#FinalTarget.ndtime and t2.FromTm=#FinalTarget.FromTm

UPDATE #FinalTarget SET Remarks = t2.Downid           
from(          
SELECT f.machineinterface,f.Compinterface,f.Opninterface,f.Workorderno,f.FromTm,         
    STUFF(ISNULL((SELECT ' , ' + x.downid + ' [' + cast(dbo.f_formattime(sum(x.downtime),'mm') as nvarchar(max))  + ']'          
    FROM #Down x           
    WHERE x.downtime<>0 and F.machineinterface = x.machineinterface and F.compinterface = x.compinterface and x.opninterface = F.opninterface and  F.Workorderno = X.Workorderno  
	and x.FromTm=f.FromTm
    GROUP BY x.downid  order by sum(x.downtime) desc,x.downid asc          
    FOR XML PATH (''), TYPE).value('.','nVARCHAR(max)'), ''), 1, 2, '') [downid]                
FROM #Down f )as t2 inner join #FinalTarget on t2.machineinterface = #FinalTarget.machineinterface and  
t2.compinterface = #FinalTarget.compinterface and t2.opninterface = #FinalTarget.opninterface and  t2.Workorderno = #FinalTarget.Workorderno   
and t2.FromTm=#FinalTarget.FromTm 

select F.machineinterface,F.Compinterface,F.Opninterface,F.Workorderno,employeeinformation.Employeeid as oprid,F.FromTm,F.ToTm
into #opr from #T_autodata autodata 
INNER JOIN #FinalTarget F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn and F.Workorderno=Autodata.WorkOrderNumber  
INNER JOIN employeeinformation ON employeeinformation.interfaceid=autodata.opr 
where 
((autodata.msttime>=F.FromTm) and (autodata.ndtime<=F.ToTm)
OR (autodata.msttime<F.FromTm and autodata.ndtime>F.FromTm and autodata.ndtime<=F.ToTm)
OR (autodata.msttime>=F.FromTm and autodata.msttime<F.ToTm and autodata.ndtime>F.ToTm)
OR (autodata.msttime<F.FromTm and autodata.ndtime>F.ToTm)) 
group by F.machineinterface,F.Compinterface,F.Opninterface,F.Workorderno,employeeinformation.Employeeid,F.FromTm,F.ToTm

UPDATE #FinalTarget SET Operatorname = t2.opr 
from(
SELECT F.machineinterface,F.Compinterface,F.Opninterface,F.Workorderno,F.FromTm,
		STUFF(ISNULL((SELECT ', ' + x.oprid
				FROM #opr x
				WHERE F.machineinterface = x.machineinterface and F.compinterface = x.compinterface and x.opninterface = F.opninterface and  F.Workorderno = X.Workorderno   
				and F.FromTm=X.FromTm
				GROUP BY x.oprid
				FOR XML PATH (''), TYPE).value('.','VARCHAR(max)'), ''), 1, 2, '') [opr]      
	FROM #opr F) as T2 INNER JOIN #FinalTarget on t2.machineinterface = #FinalTarget.machineinterface and  
 t2.compinterface = #FinalTarget.compinterface and t2.opninterface = #FinalTarget.opninterface and  t2.Workorderno = #FinalTarget.Workorderno   
 and t2.FromTm=#FinalTarget.FromTm

 insert into #Finaltarget1(MachineID,MachineInterface,component,CompInterface,Operation,OpnInterface,WorkOrderNo,WorkOrderdate,WorkOrderQty,StdMctime,StdLoadunload,StdCycletime,Suboperations,Compdescription,CustomerName,Targetpercent)
 Select MachineID,MachineInterface,component,CompInterface,Operation,OpnInterface,WorkOrderNo,WorkOrderdate,WorkOrderQty,StdMctime,StdLoadunload,StdCycletime,Suboperations,Compdescription,CustomerName,Targetpercent from #Finaltarget
 group by  MachineID,MachineInterface,component,CompInterface,Operation,OpnInterface,WorkOrderNo,WorkOrderdate,WorkOrderQty,StdMctime,StdLoadunload,StdCycletime,Suboperations,Compdescription,CustomerName,Targetpercent

 update #FinalTarget1 set Shift1PlanQty=T2.planqty,Shift1Accepted=ISNULL(T2.Accepted,0)-ISNULL(T2.Rejected,0),Shift1Rejected=T2.Rejected,Shift1Downtime=T2.Downtime,Shift1Operatorname=T2.Operatorname,
 Shift1Remarks=T2.Remarks from
 (select MachineInterface,CompInterface,OpnInterface,WorkOrderNo,ISNULL(sum(PlanQty),0) as planqty,ISNULL(SUM(Accepted),0) as Accepted,ISNULL(SUM(Rejected),0) as Rejected,
 SUM(Downtime) as Downtime,Operatorname,Remarks from (select * from #FinalTarget where shiftid='1')#FinalTarget
 group by MachineInterface,CompInterface,OpnInterface,WorkOrderNo,Operatorname,Remarks) as T2 INNER JOIN #FinalTarget1 on t2.machineinterface = #FinalTarget1.machineinterface and  
 t2.compinterface = #FinalTarget1.compinterface and t2.opninterface = #FinalTarget1.opninterface and  t2.Workorderno = #FinalTarget1.Workorderno 

  update #FinalTarget1 set Shift2PlanQty=T2.planqty,Shift2Accepted=ISNULL(T2.Accepted,0)-ISNULL(T2.Rejected,0),Shift2Rejected=T2.Rejected,Shift2Downtime=T2.Downtime,Shift2Operatorname=T2.Operatorname,
  Shift2Remarks=T2.Remarks from
 (select MachineInterface,CompInterface,OpnInterface,WorkOrderNo,ISNULL(sum(PlanQty),0) as planqty,ISNULL(SUM(Accepted),0) as Accepted,ISNULL(SUM(Rejected),0) as Rejected,
 SUM(Downtime) as Downtime,Operatorname,Remarks from (select * from #FinalTarget where shiftid='2')#FinalTarget 
 group by MachineInterface,CompInterface,OpnInterface,WorkOrderNo,Operatorname,Remarks) as T2 INNER JOIN #FinalTarget1 on t2.machineinterface = #FinalTarget1.machineinterface and  
 t2.compinterface = #FinalTarget1.compinterface and t2.opninterface = #FinalTarget1.opninterface and  t2.Workorderno = #FinalTarget1.Workorderno 

  update #FinalTarget1 set Shift3PlanQty=T2.planqty,Shift3Accepted=ISNULL(T2.Accepted,0)-ISNULL(T2.Rejected,0),Shift3Rejected=T2.Rejected,Shift3Downtime=T2.Downtime,Shift3Operatorname=T2.Operatorname,
  Shift3Remarks=T2.Remarks from
 (select MachineInterface,CompInterface,OpnInterface,WorkOrderNo,ISNULL(sum(PlanQty),0) as planqty,ISNULL(SUM(Accepted),0) as Accepted,ISNULL(SUM(Rejected),0) as Rejected,
 SUM(Downtime) as Downtime,Operatorname,Remarks from (select * from #FinalTarget where shiftid='3')#FinalTarget
 group by MachineInterface,CompInterface,OpnInterface,WorkOrderNo,Operatorname,Remarks) as T2 INNER JOIN #FinalTarget1 on t2.machineinterface = #FinalTarget1.machineinterface and  
 t2.compinterface = #FinalTarget1.compinterface and t2.opninterface = #FinalTarget1.opninterface and  t2.Workorderno = #FinalTarget1.Workorderno 


 declare @i as nvarchar(10)
declare @colName as nvarchar(50)
Select @i=1

while @i <=8 
Begin
	Select @ColName = Case when @i=1 then 'A'
						when @i=2 then 'B'
						when @i=3 then 'C'
						when @i=4 then 'D'
						when @i=5 then 'E'
						when @i=6 then 'F'
						when @i=7 then 'G'
						when @i=8 then 'H'
					END

	 ---Get the down times which are not of type Management Loss  
	 Select @strsql = ''
	 Select @strsql = @strsql + ' UPDATE #FinalTarget1 SET ' + @ColName + ' = isnull(' + @ColName + ',0) + isNull(t2.down,0)  
	 from  
	 (select  F.machineinterface,F.Compinterface,F.Opninterface,F.Workorderno,  
	  sum (CASE  
		WHEN (autodata.msttime >= '''+convert(nvarchar(20),@T_start,120)+'''  AND autodata.ndtime <='''+convert(nvarchar(20),@T_End,120)+''')  THEN autodata.loadunload  
		WHEN ( autodata.msttime < '''+convert(nvarchar(20),@T_start,120)+'''  AND autodata.ndtime <= '''+convert(nvarchar(20),@T_End,120)+'''  AND autodata.ndtime > '''+convert(nvarchar(20),@T_start,120)+''' ) THEN DateDiff(second,'''+convert(nvarchar(20),@T_start,120)+''',autodata.ndtime)  
		WHEN ( autodata.msttime >= '''+convert(nvarchar(20),@T_start,120)+'''   AND autodata.msttime <'''+convert(nvarchar(20),@T_End,120)+'''  AND autodata.ndtime > '''+convert(nvarchar(20),@T_End,120)+'''  ) THEN DateDiff(second,autodata.msttime,'''+convert(nvarchar(20),@T_End,120)+''' )  
		WHEN ( autodata.msttime < '''+convert(nvarchar(20),@T_start,120)+'''  AND autodata.ndtime > '''+convert(nvarchar(20),@T_End,120)+''' ) THEN DateDiff(second,'''+convert(nvarchar(20),@T_start,120)+''','''+convert(nvarchar(20),@T_End,120)+''' )  
		END ) as down  
		from #T_autodata autodata   
		inner join #FinalTarget1 F on autodata.mc = F.Machineinterface and autodata.comp=F.Compinterface and autodata.opn=F.Opninterface and autodata.WorkorderNumber = F.Workorderno  
		inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid 
		inner join #Downcode on #Downcode.downid= downcodeinformation.downid
		where (autodata.datatype=''2'') AND  #Downcode.Slno= ' + @i + ' and 
		(( (autodata.msttime>='''+convert(nvarchar(20),@T_start,120)+''') and (autodata.ndtime<='''+convert(nvarchar(20),@T_End,120)+'''))  
		   OR ((autodata.msttime<'''+convert(nvarchar(20),@T_start,120)+''')and (autodata.ndtime>'''+convert(nvarchar(20),@T_start,120)+''')and (autodata.ndtime<='''+convert(nvarchar(20),@T_End,120)+'''))  
		   OR ((autodata.msttime>='''+convert(nvarchar(20),@T_start,120)+''')and (autodata.msttime<'''+convert(nvarchar(20),@T_End,120)+''')and (autodata.ndtime>'''+convert(nvarchar(20),@T_End,120)+'''))  
		   OR((autodata.msttime<'''+convert(nvarchar(20),@T_start,120)+''')and (autodata.ndtime>'''+convert(nvarchar(20),@T_End,120)+''')))   
		   group by F.machineinterface,F.Compinterface,F.Opninterface,F.Workorderno  
	 ) as t2 Inner Join #FinalTarget1 on t2.machineinterface = #FinalTarget1.machineinterface and  
	 t2.compinterface = #FinalTarget1.compinterface and t2.opninterface = #FinalTarget1.opninterface and  t2.Workorderno = #FinalTarget1.Workorderno ' 
     print @strsql
	 exec(@strsql) 
	 
		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
		BEGIN   
			 Select @strsql = '' 
			 Select @strsql = @strsql + 'UPDATE  #FinalTarget1 SET ' + @ColName + ' = isnull(' + @ColName + ',0) - isNull(T2.PPDT ,0)  
			 FROM(  
			 SELECT F.machineinterface,F.Compinterface,F.Opninterface,F.WorkOrderNo,  
				SUM  
				(CASE  
				WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)  
				WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
				WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )  
				WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
				END ) as PPDT  
				FROM #T_autodata AutoData  
				CROSS jOIN #PlannedDownTimesShift T  
				INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID  
				INNER JOIN #FinalTarget1 F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn and F.WorkOrderNo=Autodata.WorkOrderNumber  
				inner join #Downcode on #Downcode.downid= downcodeinformation.downid	
				WHERE autodata.DataType=''2'' AND T.MachineInterface=autodata.mc and #Downcode.Slno= ' + @i + '  
				 AND  
				 ((autodata.sttime >= '''+convert(nvarchar(20),@T_start,120)+'''  AND autodata.ndtime <='''+convert(nvarchar(20),@T_End,120)+''')  
				 OR ( autodata.sttime < '''+convert(nvarchar(20),@T_start,120)+'''  AND autodata.ndtime <= '''+convert(nvarchar(20),@T_End,120)+''' AND autodata.ndtime > '''+convert(nvarchar(20),@T_start,120)+''' )  
				 OR ( autodata.sttime >= '''+convert(nvarchar(20),@T_start,120)+'''   AND autodata.sttime <'''+convert(nvarchar(20),@T_End,120)+''' AND autodata.ndtime > '''+convert(nvarchar(20),@T_End,120)+''' )  
				 OR ( autodata.sttime < '''+convert(nvarchar(20),@T_start,120)+'''  AND autodata.ndtime > '''+convert(nvarchar(20),@T_End,120)+'''))  
				 AND  
				 ((autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
				 OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
				 OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )  
				 OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )   
				 AND  
				 ((T.StartTime >='''+convert(nvarchar(20),@T_start,120)+''' AND T.EndTime<='''+convert(nvarchar(20),@T_End,120)+''')  
				 OR (T.StartTime <'''+convert(nvarchar(20),@T_start,120)+'''   AND T.EndTime<='''+convert(nvarchar(20),@T_End,120)+''' AND T.Endtime>'''+convert(nvarchar(20),@T_start,120)+''' )  
				 OR ( T.StartTime >= '''+convert(nvarchar(20),@T_start,120)+''' AND T.starttime<'''+convert(nvarchar(20),@T_end,120)+''' AND  T.EndTime >'''+convert(nvarchar(20),@T_End,120)+''')  
				 OR ( T.StartTime <'''+convert(nvarchar(20),@T_start,120)+''' AND T.EndTime>'''+convert(nvarchar(20),@T_End,120)+''') )   
				 group  by F.machineinterface,F.Compinterface,F.Opninterface,F.WorkOrderNo  
			 )AS T2  Inner Join #FinalTarget1 on t2.machineinterface = #FinalTarget1.machineinterface and  
			 t2.compinterface = #FinalTarget1.compinterface and t2.opninterface = #FinalTarget1.opninterface and  t2.WorkOrderNo = #FinalTarget1.WorkOrderNo '
			print @strsql
			exec(@Strsql)
		END

	select @i  =  @i + 1
End


update #FinalTarget1 set Shift1AcceptPercent = (cast(Shift1Accepted as float)/cast(Shift1PlanQty as float))*100  where Shift1PlanQty>0

update #FinalTarget1 set Shift1Rejectpercent = (cast(Shift1Rejected as float)/cast(Shift1PlanQty as float))*100  where Shift1PlanQty>0

update #FinalTarget1 set Shift2AcceptPercent = (cast(Shift2Accepted as float)/cast(Shift2PlanQty as float))*100  where Shift2PlanQty>0

update #FinalTarget1 set Shift2Rejectpercent = (cast(Shift2Rejected as float)/cast(Shift2PlanQty as float))*100  where Shift2PlanQty>0

update #FinalTarget1 set Shift3AcceptPercent = (cast(Shift3Accepted as float)/cast(Shift3PlanQty as float))*100  where Shift3PlanQty>0

update #FinalTarget1 set Shift3Rejectpercent = (cast(Shift3Rejected as float)/cast(Shift3PlanQty as float))*100  where Shift3PlanQty>0

--For Prodtime  
UPDATE #FinalTarget1 SET Productivetime = isnull(Productivetime,0) + isNull(t2.cycle,0)  
from  
(select S.MachineID,S.Component,S.operation,S.WorkOrderNo,  
 sum(case when ((autodata.msttime>=@T_Start) and (autodata.ndtime<=@T_End)) then  (autodata.cycletime+autodata.loadunload)  
   when ((autodata.msttime<@T_Start)and (autodata.ndtime>@T_Start)and (autodata.ndtime<=@T_End)) then DateDiff(second, @T_Start, autodata.ndtime)  
   when ((autodata.msttime>=@T_Start)and (autodata.msttime<@T_End)and (autodata.ndtime>@T_End)) then DateDiff(second, autodata.mstTime, @T_End)  
   when ((autodata.msttime<@T_Start)and (autodata.ndtime>@T_End)) then DateDiff(second, @T_Start, @T_End) END ) as cycle  
from #T_autodata autodata   
inner join #FinalTarget1 S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface and autodata.WorkOrderNumber = S.WorkOrderNo  
where (autodata.datatype=1) AND(( (autodata.msttime>=@T_Start) and (autodata.ndtime<=@T_End))  
OR ((autodata.msttime<@T_Start)and (autodata.ndtime>@T_Start)and (autodata.ndtime<=@T_End))  
OR ((autodata.msttime>=@T_Start)and (autodata.msttime<@T_End)and (autodata.ndtime>@T_End))  
OR((autodata.msttime<@T_Start)and (autodata.ndtime>@T_End)))  
group by S.MachineID,S.Component,S.operation,S.WorkOrderNo
) as t2 inner join #FinalTarget1 on t2.MachineID = #FinalTarget1.MachineID and  t2.Component = #FinalTarget1.Component and   
t2.operation = #FinalTarget1.operation and t2.WorkOrderNo = #FinalTarget1.WorkOrderNo  
  
  
--Type 2  
UPDATE  #FinalTarget1 SET Productivetime = isnull(Productivetime,0) - isNull(t2.Down,0)  
FROM  
(Select T1.mc,T1.comp,T1.opn,T1.WorkOrderNumber,
SUM(  
CASE  
 When autodata.sttime <= @T_Start Then datediff(s, @T_Start,autodata.ndtime )  
 When autodata.sttime >@T_Start Then datediff(s,autodata.sttime,autodata.ndtime)  
END) as Down  
From #T_autodata AutoData INNER Join  
 (Select AutoData.mc,AutoData.comp,AutoData.opn,AutoData.WorkOrderNumber,autodata.sttime,autodata.ndtime 
   From #T_autodata AutoData  
  inner join #FinalTarget1 ST1 ON ST1.MachineInterface=Autodata.mc and ST1.CompInterface=Autodata.Comp and  
  ST1.opnInterface=Autodata.opn and Autodata.WorkOrderNumber = ST1.WorkOrderNo  
  Where DataType=1 And DateDiff(Second,AutoData.sttime,AutoData.ndtime)>CycleTime And  
  (AutoData.msttime < @T_Start)And (AutoData.ndtime >@T_Start) AND (AutoData.ndtime <= @T_End)  
 ) as T1 on t1.mc=autodata.mc and t1.comp=autodata.comp and t1.opn=autodata.opn and T1.WorkOrderNumber=Autodata.WorkOrderNumber  
Where AutoData.DataType=2  
And ( autodata.Sttime > T1.Sttime )  
And ( autodata.ndtime <  T1.ndtime )  
AND ( autodata.ndtime > @T_Start )  
GROUP BY T1.mc,T1.comp,T1.opn,T1.WorkOrderNumber)AS T2 Inner Join #FinalTarget1 on t2.mc = #FinalTarget1.machineinterface and  
t2.comp = #FinalTarget1.compinterface and t2.opn = #FinalTarget1.opninterface and  t2.WorkOrderNumber = #FinalTarget1.WorkOrderNo   
 
--Type 3  
UPDATE  #FinalTarget1 SET Productivetime = isnull(Productivetime,0) - isNull(t2.Down,0)  
FROM  
(Select T1.mc,T1.comp,T1.opn,T1.workordernumber,
SUM(CASE  
 When autodata.ndtime > @T_End Then datediff(s,autodata.sttime, @T_End )  
 When autodata.ndtime <= @T_End Then datediff(s , autodata.sttime,autodata.ndtime)  
END) as Down  
From #T_autodata AutoData INNER Join  
 (Select AutoData.mc,AutoData.comp,AutoData.opn,AutoData.WorkOrderNumber,AutoData.Sttime as sttime,AutoData.NdTime as ndtime 
  From #T_autodata AutoData  
  inner join #FinalTarget1 ST1 ON ST1.MachineInterface=Autodata.mc and ST1.CompInterface=Autodata.Comp and  
  ST1.opnInterface=Autodata.opn and Autodata.WorkOrderNumber = ST1.WorkOrderNo  
  Where DataType=1 And DateDiff(Second,AutoData.sttime,AutoData.ndtime)>CycleTime And  
  (AutoData.sttime >= @T_Start)And (AutoData.ndtime > @T_End) and (AutoData.sttime< @T_End)  
   ) as T1  
ON t1.mc=autodata.mc and t1.comp=autodata.comp and t1.opn=autodata.opn and T1.WorkOrderNumber=Autodata.WorkOrderNumber  
Where AutoData.DataType=2  
And (T1.Sttime < autodata.sttime)  
And ( T1.ndtime > autodata.ndtime)  
AND (autodata.sttime  <  @T_End)  
GROUP BY T1.mc,T1.comp,T1.opn,T1.WorkOrderNumber)AS T2 Inner Join #FinalTarget1 on t2.mc = #FinalTarget1.machineinterface and  
t2.comp = #FinalTarget1.compinterface and t2.opn = #FinalTarget1.opninterface and  t2.WorkOrderNumber = #FinalTarget1.WorkOrderNo   

  
  
--For Type4  
UPDATE  #FinalTarget1 SET Productivetime = isnull(Productivetime,0) - isNull(t2.Down,0)  
FROM  
(Select T1.mc,T1.comp,T1.opn,T1.WorkOrderNumber,  
SUM(CASE  
 When autodata.sttime >= @T_Start AND autodata.ndtime <= @T_end Then datediff(s , autodata.sttime,autodata.ndtime)  
 When autodata.sttime < @T_Start And autodata.ndtime >@T_Start AND autodata.ndtime<=@T_end Then datediff(s, @T_Start,autodata.ndtime )  
 When autodata.sttime >= @T_Start AND autodata.sttime<@T_end AND autodata.ndtime>@T_end Then datediff(s,autodata.sttime, @T_end )  
 When autodata.sttime<@T_Start AND autodata.ndtime>@T_end   Then datediff(s , @T_Start,@T_end)  
END) as Down  
From #T_autodata AutoData INNER Join  
 (Select AutoData.mc,AutoData.comp,AutoData.opn,AutoData.WorkOrderNumber,AutoData.Sttime as sttime,AutoData.NdTime as ndtime  
  From #T_autodata AutoData  
  inner join #FinalTarget1 ST1 ON ST1.MachineInterface=Autodata.mc and ST1.CompInterface=Autodata.Comp and  
  ST1.opnInterface=Autodata.opn and Autodata.WorkOrderNumber = ST1.WorkOrderNo  
  where DataType=1 And DateDiff(Second,AutoData.sttime,AutoData.ndtime)>CycleTime And   
  (AutoData.msttime < @T_Start) And (AutoData.ndtime >@T_end)  
 ) as T1  
on t1.mc=autodata.mc and t1.comp=autodata.comp and t1.opn=autodata.opn and T1.WorkOrderNumber=Autodata.WorkOrderNumber   
Where AutoData.DataType=2  
And (T1.Sttime < autodata.sttime  )  
And ( T1.ndtime >  autodata.ndtime)  
AND (autodata.ndtime  >  @T_Start)  
AND (autodata.sttime  <  @T_end)  
GROUP BY T1.mc,T1.comp,T1.opn,T1.WorkOrderNumber
 )AS T2 Inner Join #FinalTarget1 on t2.mc = #FinalTarget1.machineinterface and  
t2.comp = #FinalTarget1.compinterface and t2.opn = #FinalTarget1.opninterface and  t2.WorkOrderNumber = #FinalTarget1.WorkOrderNo   
  
    
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'  
BEGIN  
   
 --Get the utilised time overlapping with PDT and negate it from UtilisedTime  
  UPDATE  #FinalTarget1 SET Productivetime = isnull(Productivetime,0) - isNull(T2.PPDT ,0)  
  FROM(  
  SELECT F.machineinterface,F.Compinterface,F.Opninterface,F.WorkOrderNo,  
     SUM  
     (CASE  
     WHEN autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN DateDiff(second,autodata.msttime,autodata.ndtime) --DR0325 Added  
     WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
     WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )  
     WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
     END ) as PPDT  
     FROM #T_autodata AutoData  
     CROSS jOIN #PlannedDownTimesShift T  
     INNER JOIN #FinalTarget1 F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn and F.WorkOrderNo=Autodata.WorkOrderNumber  
     WHERE autodata.DataType=1 AND T.MachineInterface=autodata.mc AND  
      ((autodata.msttime >= @T_Start  AND autodata.ndtime <=@T_End)  
      OR ( autodata.msttime < @T_Start  AND autodata.ndtime <= @T_End AND autodata.ndtime > @T_Start )  
      OR ( autodata.msttime >= @T_Start   AND autodata.msttime <@T_End AND autodata.ndtime > @T_End )  
      OR ( autodata.msttime < @T_Start  AND autodata.ndtime > @T_End))  
      AND  
      ((autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
      OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
      OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )  
      OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )   
      AND  
	((T.StartTime >= @T_Start AND T.EndTime <=@T_End)  
	OR ( T.StartTime < @T_Start AND T.EndTime <= @T_End AND t.EndTime > @T_Start)  
	OR ( T.StartTime >= @T_Start AND T.StartTime <@T_End AND T.EndTime > @T_End)  
	OR ( T.StartTime < @T_Start AND T.EndTime > @T_End) )
      group  by F.machineinterface,F.Compinterface,F.Opninterface,F.WorkOrderNo  
  )AS T2  Inner Join #FinalTarget1 on t2.machineinterface = #FinalTarget1.machineinterface and  
  t2.compinterface = #FinalTarget1.compinterface and t2.opninterface = #FinalTarget1.opninterface and  t2.WorkOrderNo = #FinalTarget1.WorkOrderNo   
  
 ---mod 12:Add ICD's Overlapping  with PDT to Prodtime  
 /* Fetching Down Records from Production Cycle  */  
  ---mod 12(4):Handle intearction between ICD and PDT for type 1 production record for the selected time period.  
  UPDATE  #FinalTarget1 SET Productivetime = isnull(Productivetime,0) + isNull(T2.IPDT ,0)  
  FROM(  
  Select autodata.mc,autodata.comp,autodata.opn,autodata.WorkOrderNumber,  
  SUM(  
  CASE    
   When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1  
   When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2  
   When (autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3  
   when (autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4  
  END) as IPDT  
  from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join   
   (  
    Select autodata.mc,autodata.comp,autodata.opn,autodata.WorkOrderNumber,autodata.Sttime,autodata.NdTime  
     from #T_autodata autodata inner join #FinalTarget1 S on S.MachineInterface=Autodata.mc and S.CompInterface=Autodata.Comp and  
    S.opnInterface=Autodata.opn and Autodata.WorkOrderNumber = S.WorkOrderNo  
    Where DataType=1 And DateDiff(Second, autodata.sttime, autodata.ndtime)>CycleTime And  
    ( autodata.msttime >= @T_Start) AND ( autodata.ndtime <= @T_End)  
   ) as T1  
  ON AutoData.mc=T1.mc and autodata.comp=T1.comp and Autodata.opn=T1.opn and autodata.WorkOrderNumber=T1.WorkOrderNumber 
  Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc  
  And (( autodata.Sttime > T1.Sttime )  
  And ( autodata.ndtime <  T1.ndtime ))  
  AND  
  ((T.StartTime >=T1.Sttime And T.EndTime <=T1.ndtime )  
  or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)  
  or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )  
  or ( T.StartTime <T1.Sttime And T.EndTime >T1.ndtime ))  
  GROUP BY autodata.mc,autodata.comp,autodata.opn,autodata.WorkOrderNumber  
  )AS T2  Inner Join #FinalTarget1 on t2.mc = #FinalTarget1.machineinterface and  
  t2.comp = #FinalTarget1.compinterface and t2.opn = #FinalTarget1.opninterface and  t2.WorkOrderNumber = #FinalTarget1.WorkOrderNo   
  
  ---mod 12(4)  
  /* If production  Records of TYPE-2*/  
  UPDATE  #FinalTarget1 SET Productivetime = isnull(Productivetime,0) + isNull(T2.IPDT ,0)  
  FROM  
  (Select autodata.mc,autodata.comp,autodata.opn,autodata.WorkOrderNumber,  
  SUM(  
  CASE    
   When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1  
   When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2  
   When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3  
   when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4  
  END) as IPDT  
  from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join   
   (  
     Select autodata.mc,autodata.comp,autodata.opn,autodata.WorkOrderNumber,autodata.Sttime,autodata.NdTime  
     from #T_autodata autodata inner join #FinalTarget1 S on S.MachineInterface=Autodata.mc and S.CompInterface=Autodata.Comp and  
     S.opnInterface=Autodata.opn and Autodata.WorkOrderNumber = S.WorkOrderNo  
     Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And  
     (msttime < @T_Start)And (ndtime > @T_Start) AND (ndtime <= @T_End)  
    ) as T1  
  ON AutoData.mc=T1.mc and autodata.comp=T1.comp and Autodata.opn=T1.opn and autodata.WorkOrderNumber=T1.WorkOrderNumber
  Where AutoData.DataType=2  and T.MachineInterface=autodata.mc  
  And (( autodata.Sttime > T1.Sttime )  
  And ( autodata.ndtime <  T1.ndtime )  
  AND ( autodata.ndtime >  @T_Start))  
  AND  
  (( T.StartTime >= @T_Start )  
  And ( T.StartTime <  T1.ndtime ) )  
  GROUP BY autodata.mc,autodata.comp,autodata.opn,autodata.WorkOrderNumber )AS T2 Inner Join #FinalTarget1 on t2.mc = #FinalTarget1.machineinterface and  
  t2.comp = #FinalTarget1.compinterface and t2.opn = #FinalTarget1.opninterface and  t2.WorkOrderNumber = #FinalTarget1.WorkOrderNo     
   
  
 /* If production Records of TYPE-3*/  
 UPDATE  #FinalTarget1 SET Productivetime	 = isnull(Productivetime,0) + isNull(T2.IPDT ,0)  
 FROM  
 (Select autodata.mc,autodata.comp,autodata.opn,autodata.WorkOrderNumber,  
 SUM(  
 CASE    
  When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1  
  When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2  
  When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3  
  when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4  
 END) as IPDT  
 from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join  
  (  
   Select autodata.mc,autodata.comp,autodata.opn,autodata.WorkOrderNumber,autodata.Sttime,autodata.NdTime
   from #T_autodata autodata inner join #FinalTarget1 S on S.MachineInterface=Autodata.mc and S.CompInterface=Autodata.Comp and  
   S.opnInterface=Autodata.opn and Autodata.WorkOrderNumber = S.WorkOrderNo  
   Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And  
   (sttime >= @T_Start And ndtime > @T_End and autodata.sttime <@T_End)   
  )as T1  
 ON AutoData.mc=T1.mc and autodata.comp=T1.comp and Autodata.opn=T1.opn and autodata.WorkOrderNumber=T1.WorkOrderNumber
 Where AutoData.DataType=2  and T.MachineInterface=autodata.mc  
 And ((T1.Sttime < autodata.sttime  )  
 And ( T1.ndtime >  autodata.ndtime)  
 AND (autodata.sttime<@T_End))  
 AND  
 (( T.EndTime > T1.Sttime )  
 And ( T.EndTime <=@T_End) )  
 GROUP BY autodata.mc,autodata.comp,autodata.opn,autodata.WorkOrderNumber)AS T2 Inner Join #FinalTarget1 on t2.mc = #FinalTarget1.machineinterface and  
 t2.comp = #FinalTarget1.compinterface and t2.opn = #FinalTarget1.opninterface and  t2.WorkOrderNumber = #FinalTarget1.WorkOrderNo   
  
   
 /* If production Records of TYPE-4*/  
 UPDATE  #FinalTarget1 SET Productivetime = isnull(Productivetime,0) + isNull(T2.IPDT ,0)  
 FROM  
 (Select autodata.mc,autodata.comp,autodata.opn,autodata.WorkOrderNumber,  
 SUM(  
 CASE    
  When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1  
  When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2  
  When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3  
  when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4  
 END) as IPDT  
 from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join   
  (  
   Select autodata.mc,autodata.comp,autodata.opn,autodata.WorkOrderNumber,autodata.Sttime,autodata.NdTime
   from #T_autodata autodata inner join #FinalTarget1 S on S.MachineInterface=Autodata.mc and S.CompInterface=Autodata.Comp and  
   S.opnInterface=Autodata.opn and Autodata.WorkOrderNumber = S.WorkOrderNo  
   Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And  
   (msttime < @T_Start And ndtime > @T_End)  
  ) as T1  
 ON AutoData.mc=T1.mc and autodata.comp=T1.comp and Autodata.opn=T1.opn and autodata.WorkOrderNumber=T1.WorkOrderNumber
 Where AutoData.DataType=2 and T.MachineInterface=autodata.mc  
 And ( (T1.Sttime < autodata.sttime  )  
  And ( T1.ndtime >  autodata.ndtime)  
  AND (autodata.ndtime  >  @T_Start)  
  AND (autodata.sttime  <  @T_End))  
 AND  
 (( T.StartTime >=@T_Start)  
 And ( T.EndTime <=@T_End) )  
 GROUP BY autodata.mc,autodata.comp,autodata.opn,autodata.WorkOrderNumber)AS T2  Inner Join #FinalTarget1 on t2.mc = #FinalTarget1.machineinterface and  
 t2.comp = #FinalTarget1.compinterface and t2.opn = #FinalTarget1.opninterface and  t2.WorkOrderNumber = #FinalTarget1.WorkOrderNo   
  
END  


-----BEGIN: CN  
--Type 1 and Type 2  
UPDATE #FinalTarget1 SET CN = isnull(CN,0) + isNull(t2.C1N1,0) from 
(  
 select autodata.mc,autodata.comp,autodata.opn,autodata.workordernumber,SUM((F.StdCycletime * ISNULL(autodata.PartsCount,1))/ISNULL(F.SubOperations,1)) C1N1 
 FROM #T_autodata autodata 
INNER JOIN #FinalTarget1 F on F.machineinterface=autodata.mc and F.Compinterface=autodata.comp and F.Opninterface = autodata.opn and F.WorkOrderNo=autodata.WorkOrderNumber 
 where (autodata.ndtime>@T_Start)and (autodata.ndtime<=@T_End)and (autodata.datatype=1) 
 group by autodata.mc,autodata.comp,autodata.opn,autodata.workordernumber
) as t2 Inner Join #FinalTarget1 on t2.mc = #FinalTarget1.machineinterface and  
 t2.comp = #FinalTarget1.compinterface and t2.opn = #FinalTarget1.opninterface and  t2.WorkOrderNumber = #FinalTarget1.WorkOrderNo 
  
-- mod 4 Ignore count from CN calculation which is over lapping with PDT  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
BEGIN  
 
  UPDATE #FinalTarget1 SET CN=ISNULL(CN,0)- isnull(t2.C1N1,0) FROM
 ( 
	SELECT autodata.mc,autodata.comp,autodata.opn,autodata.WorkOrderNumber,SUM((F.StdCycletime * ISNULL(autodata.PartsCount,1))/ISNULL(F.SubOperations,1))  C1N1  
	from #T_autodata autodata   
	INNER JOIN #FinalTarget1 F on F.machineinterface=autodata.mc and F.Compinterface=autodata.comp and F.Opninterface = autodata.opn and F.WorkOrderNo=autodata.WorkOrderNumber  
	Inner jOIN PlannedDownTimes T on T.Machine=f.MachineID   
	WHERE autodata.DataType=1 and  
	(autodata.ndtime>@T_Start) and (autodata.ndtime<=@T_End)   
	AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)  
	Group by autodata.mc,autodata.comp,autodata.opn,autodata.WorkOrderNumber
 ) as T2 Inner Join #FinalTarget1 on T2.mc = #FinalTarget1.machineinterface and T2.comp = #FinalTarget1.compinterface and T2.opn = #FinalTarget1.opninterface and  T2.WorkOrderNumber = #FinalTarget1.WorkOrderNo   
END 

---Get the down times 
UPDATE #FinalTarget1 SET NonProductiveTime = isnull(NonProductiveTime,0) + isNull(t2.down,0)  
from  
(select  F.machineinterface,F.Compinterface,F.Opninterface,F.Workorderno,
sum (CASE  
WHEN (autodata.msttime >= @T_Start  AND autodata.ndtime <=@T_end)  THEN autodata.loadunload  
WHEN ( autodata.msttime < @T_Start  AND autodata.ndtime <= @T_end  AND autodata.ndtime > @T_Start ) THEN DateDiff(second,@T_Start,autodata.ndtime)  
WHEN ( autodata.msttime >= @T_Start   AND autodata.msttime <@T_end  AND autodata.ndtime > @T_end  ) THEN DateDiff(second,autodata.msttime,@T_end )  
WHEN ( autodata.msttime < @T_Start  AND autodata.ndtime > @T_end ) THEN DateDiff(second,@T_Start,@T_end )  
END ) as down  
from #T_autodata autodata   
inner join #FinalTarget1 F on autodata.mc = F.Machineinterface and autodata.comp=F.Compinterface and autodata.opn=F.Opninterface and autodata.WorkOrderNumber = F.WorkOrderNo  
inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid  
where (autodata.datatype=2) AND  
(( (autodata.msttime>=@T_Start) and (autodata.ndtime<=@T_end))  
    OR ((autodata.msttime<@T_Start)and (autodata.ndtime>@T_Start)and (autodata.ndtime<=@T_end))  
    OR ((autodata.msttime>=@T_Start)and (autodata.msttime<@T_end)and (autodata.ndtime>@T_end))  
    OR((autodata.msttime<@T_Start)and (autodata.ndtime>@T_end)))   
    group by F.machineinterface,F.Compinterface,F.Opninterface,F.Workorderno 
) as t2 Inner Join #FinalTarget1 on t2.machineinterface = #FinalTarget1.machineinterface and  
t2.compinterface = #FinalTarget1.compinterface and t2.opninterface = #FinalTarget1.opninterface and  t2.Workorderno = #FinalTarget1.Workorderno   
  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
BEGIN   
 UPDATE  #FinalTarget1 SET NonProductiveTime = isnull(NonProductiveTime,0) - isNull(T2.PPDT ,0)  
 FROM(  
 SELECT F.machineinterface,F.Compinterface,F.Opninterface,F.Workorderno,
    SUM  
    (CASE  
    WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)  
    WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
    WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )  
    WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
    END ) as PPDT  
    FROM #T_autodata AutoData  
    CROSS jOIN #PlannedDownTimesShift T  
    INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID  
    INNER JOIN #FinalTarget1 F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn and F.Workorderno=Autodata.WorkOrderNumber  
    WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc 
     AND  
     ((autodata.sttime >= @T_Start  AND autodata.ndtime <=@T_END)  
     OR ( autodata.sttime < @T_Start  AND autodata.ndtime <= @T_END AND autodata.ndtime > @T_Start )  
     OR ( autodata.sttime >= @T_Start   AND autodata.sttime <@T_end AND autodata.ndtime > @T_end )  
     OR ( autodata.sttime < @T_Start  AND autodata.ndtime > @T_end))  
     AND  
     ((autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
     OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
     OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )  
     OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )   
     AND  
	((T.StartTime >= @T_Start AND T.EndTime <=@T_End)  
	OR ( T.StartTime < @T_Start AND T.EndTime <= @T_End AND t.EndTime > @T_Start)  
	OR ( T.StartTime >= @T_Start AND T.StartTime <@T_End AND T.EndTime > @T_End)  
	OR ( T.StartTime < @T_Start AND T.EndTime > @T_End) )
     group  by F.machineinterface,F.Compinterface,F.Opninterface,F.Workorderno
 )AS T2  Inner Join #FinalTarget1 on t2.machineinterface = #FinalTarget1.machineinterface and  
 t2.compinterface = #FinalTarget1.compinterface and t2.opninterface = #FinalTarget1.opninterface and  t2.Workorderno = #FinalTarget1.Workorderno   
 END

 update #Finaltarget1 set ProdTotal = (ISNULL(Shift1Accepted,0)+ISNULL(Shift1Rejected,0) +ISNULL(Shift2Accepted,0)+ ISNULL(Shift2Rejected,0)+ISNULL(Shift3Accepted,0)+ ISNULL(Shift3Rejected,0))
 
--Calculation of PartsCount Begins..  
UPDATE #FinalTarget1 SET CumulativeProdTotal = ISNULL(CumulativeProdTotal,0) + ISNULL(t2.comp1,0)
From  
(  
 Select T1.mc,T1.comp,T1.opn,T1.WorkOrderNumber,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(F.SubOperations,1))) As Comp1 From 
	 (select autodata.mc,autodata.comp,autodata.opn,autodata.WorkOrderNumber,SUM(autodata.partscount)AS OrginalCount from #T_autodata autodata  
     INNER JOIN #FinalTarget1 F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn and F.WorkOrderNo=Autodata.WorkOrderNumber  
     where (autodata.ndtime>@MonthStart) and (autodata.ndtime<=@T_End) and (autodata.datatype=1)  
     Group By autodata.mc,autodata.comp,autodata.opn,autodata.WorkOrderNumber
	 ) as T1  
 INNER JOIN #FinalTarget1 F on F.machineinterface=T1.mc and F.Compinterface=T1.comp and F.Opninterface = T1.opn and F.WorkOrderNo=T1.WorkOrderNumber  
 GROUP BY T1.mc,T1.comp,T1.opn,T1.WorkOrderNumber
) As T2 Inner Join #FinalTarget1 on T2.mc = #FinalTarget1.machineinterface and T2.comp = #FinalTarget1.compinterface and T2.opn = #FinalTarget1.opninterface and  T2.WorkOrderNumber = #FinalTarget1.WorkOrderNo   
  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
BEGIN  
    
 UPDATE #FinalTarget1 SET CumulativeProdTotal=ISNULL(CumulativeProdTotal,0)- isnull(t2.PlanCt,0) FROM
 ( 
	SELECT autodata.mc,autodata.comp,autodata.opn,autodata.WorkOrderNumber,((CAST(Sum(ISNULL(PartsCount,1)) AS Float)/ISNULL(F.SubOperations,1))) as PlanCt
	from #T_autodata autodata   
	INNER JOIN #FinalTarget1 F on F.machineinterface=autodata.mc and F.Compinterface=autodata.comp and F.Opninterface = autodata.opn and F.WorkOrderNo=autodata.WorkOrderNumber  
	Inner jOIN PlannedDownTimes T on T.Machine=f.MachineID   
	WHERE autodata.DataType=1 and  
	(autodata.ndtime>@MonthStart) and (autodata.ndtime<=@T_End)   
	AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)  
	Group by autodata.mc,autodata.comp,autodata.opn,autodata.WorkOrderNumber
 ) as T2 Inner Join #FinalTarget1 on T2.mc = #FinalTarget1.machineinterface and T2.comp = #FinalTarget1.compinterface and T2.opn = #FinalTarget1.opninterface and  T2.WorkOrderNumber = #FinalTarget1.WorkOrderNo   
END 

update #finaltarget1 set PcountPerhr = cast((isnull(#finaltarget1.StdCycletime,0))/60  as float) where StdCycletime>0

Update #finaltarget1 SET WorkingHrs=Round((ProdTotal/PcountPerhr),2)  

-------------------------------------------------------------------------------------------------------------------------------------------
select @T_Start = dbo.f_GetLogicalDayStart(@PrevDay)
Select @T_End = dbo.f_GetLogicalDayend(@PrevDay)

--Calculation of PartsCount Begins..  

UPDATE #FinalTarget1 SET PrevdayAccepted = ISNULL(PrevdayAccepted,0) + ISNULL(t2.comp,0)    
From    
(    
   Select mc,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp --NR0097    
     From (select mc,SUM(autodata.partscount)AS OrginalCount,comp,opn from #T_autodata autodata    
     where (autodata.ndtime>@T_Start) and (autodata.ndtime<=@T_End) and (autodata.datatype=1)    
     Group By mc,comp,opn) as T1    
 Inner join componentinformation C on T1.Comp = C.interfaceid    
 Inner join ComponentOperationPricing O ON  T1.Opn = O.interfaceid and C.Componentid=O.componentid      
 inner join machineinformation on machineinformation.machineid =O.machineid    
 and T1.mc=machineinformation.interfaceid    
 GROUP BY mc    
) As T2 Inner join #FinalTarget1 on T2.mc = #FinalTarget1.machineinterface

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'    
BEGIN    
	 UPDATE #FinalTarget1 SET PrevdayAccepted = ISNULL(PrevdayAccepted,0) - ISNULL(T2.comp,0) from
	 (    
	  select mc,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp From 
		(
		select mc,Sum(ISNULL(PartsCount,1))AS OrginalCount,comp,opn from #T_autodata autodata  
		Inner join Machineinformation M on M.interfaceID = autodata.mc     
		CROSS JOIN PlannedDownTimes T    
		WHERE autodata.DataType=1 And T.Machine = M.machineid    
		AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)    
		AND (autodata.ndtime > @T_Start  AND autodata.ndtime <=@T_End)    
		Group by mc,comp,opn    
		) as T1    
	 Inner join Machineinformation M on M.interfaceID = T1.mc    
	 Inner join componentinformation C on T1.Comp=C.interfaceid    
	 Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineID = M.MachineID    
	 GROUP BY MC    
	 ) as T2 inner join #FinalTarget1 on T2.mc = #FinalTarget1.machineinterface    
END    

DELETE FROM #shiftdetails

INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)  
EXEC s_GetShiftTime @Prevday,''  

update #ShiftDetails set shiftid = T.shiftid from
(select shiftname,shiftid from shiftdetails where Running=1)t inner join #ShiftDetails F ON T.ShiftName=f.Shift

Update #FinalTarget1 set PrevdayRejected = isnull(PrevdayRejected,0) + isnull(T1.RejQty,0)    
From    
( Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A    
inner join Machineinformation M on A.mc=M.interfaceid    
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid    
inner join #shiftdetails S on convert(nvarchar(10),(A.RejDate),126)=S.PDate and A.RejShift=S.shiftid 
where A.flag = 'Rejection' and A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (S.PDate) and  --DR0333    
Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'    
group by A.mc,M.Machineid    
)T1 inner join #FinalTarget1 B on B.MachineID=T1.Machineid     
    
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'    
BEGIN    
 Update #FinalTarget1 set PrevdayRejected = isnull(PrevdayRejected,0) - isnull(T1.RejQty,0) from    
 (Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A    
 inner join Machineinformation M on A.mc=M.interfaceid    
 inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid    
 inner join #shiftdetails S on convert(nvarchar(10),(A.RejDate),126)=S.PDate and A.RejShift=S.shiftid --DR0333    
 Cross join Planneddowntimes P    
 where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid and    
 A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (S.PDate) and --DR0333    
 Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'    
 and P.starttime>=S.Shiftstart and P.Endtime<=S.shiftend    
 group by A.mc,M.Machineid)T1 inner join #FinalTarget1 B on B.Machineid=T1.Machineid     
END    
    
------------------------------------*/

DELETE FROM #shiftdetails

declare @MStart as datetime
select @MStart = @MonthStart

while @MStart<=@T_End
Begin
INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)  
EXEC s_GetShiftTime @MStart,''  
select @MStart = dateadd(day,1,@MStart)
End

update #ShiftDetails set shiftid = T.shiftid from
(select shiftname,shiftid from shiftdetails where Running=1)t inner join #ShiftDetails F ON T.ShiftName=f.Shift

Update #FinalTarget1 set CumulativeRejTotal = isnull(CumulativeRejTotal,0) + isnull(T2.RejQty,0)  
From  
( Select A.mc,A.comp,A.opn,A.WorkOrderNumber,SUM(A.Rejection_Qty) as RejQty from AutodataRejections A  
INNER JOIN #FinalTarget1 F on F.machineinterface=A.mc and F.Compinterface=A.comp and F.Opninterface = A.opn and F.WorkOrderNo=A.WorkOrderNumber
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid  
cross join #shiftdetails S
where A.flag = 'Rejection' and A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (convert(nvarchar(10),(S.PDate),126)) and 
Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'  
group by A.mc,A.comp,A.opn,A.WorkOrderNumber
)T2 Inner Join #FinalTarget1 on T2.mc = #FinalTarget1.machineinterface and T2.comp = #FinalTarget1.compinterface and T2.opn = #FinalTarget1.opninterface and  T2.WorkOrderNumber = #FinalTarget1.WorkOrderNo   
   
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
BEGIN  

Update #FinalTarget1 set CumulativeRejTotal = isnull(CumulativeRejTotal,0) - isnull(T2.RejQty,0)  
From  
( Select A.mc,A.comp,A.opn,A.WorkOrderNumber,SUM(A.Rejection_Qty) as RejQty from AutodataRejections A  
INNER JOIN #FinalTarget1 F on F.machineinterface=A.mc and F.Compinterface=A.comp and F.Opninterface = A.opn and F.WorkOrderNo=A.WorkOrderNumber
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid  
inner join PlannedDownTimes P  on F.MachineID=P.Machine
cross join #shiftdetails S
where A.flag = 'Rejection' and A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (convert(nvarchar(10),(S.PDate),126)) and 
Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'  
and P.starttime>=@MonthStart and P.Endtime<=@T_End
group by A.mc,A.comp,A.opn,A.WorkOrderNumber
)T2 Inner Join #FinalTarget1 on T2.mc = #FinalTarget1.machineinterface and T2.comp = #FinalTarget1.compinterface and T2.opn = #FinalTarget1.opninterface and  T2.WorkOrderNumber = #FinalTarget1.WorkOrderNo   

END 

update #finaltarget1 set Total =  ISNULL(Round((WorkingHrs+dbo.f_formattime(NonProductiveTime, 'hh')),2),0)

update #FinalTarget1 set OverallPercent = Round((CN/Productivetime)*100,2) where Productivetime>0

select Machineid,Compdescription as PartName,Component as ItemNo,Operation as OpnNo,CustomerName,WorkOrderNo,WorkOrderdate,WorkOrderQty,
dbo.f_formattime(Stdmctime,'hh:mm:ss')  as Cycletime,dbo.f_formattime(StdLoadunload,'hh:mm:ss') as Loadunload,ISNULL(Round(PcountPerhr,2),0) as PcountPerhr,
ISNULL(Shift1PlanQty,0) as Shift1PlanQty,ISNULL(Shift1Accepted,0) as Shift1Accepted,ISNULL(Shift1Rejected,0) as Shift1Rejected,
ISNULL(ROUND(Shift1AcceptPercent,2),0) as Shift1AcceptPercent,ISNULL(ROUND(Shift1Rejectpercent,2),0) as Shift1Rejectpercent,ISNULL(Shift1Downtime,0) as Shift1Downtime,
ISNULL(Shift1Remarks,'') as Remarks1,Shift1Operatorname,
ISNULL(Shift2PlanQty,0) as Shift2PlanQty,ISNULL(Shift2Accepted,0) as Shift2Accepted,ISNULL(Shift2Rejected,0) as Shift2Rejected,
ISNULL(ROUND(Shift2AcceptPercent,2),0) as Shift2AcceptPercent,ISNULL(ROUND(Shift2Rejectpercent,2),0) as Shift2Rejectpercent,ISNULL(Shift2Downtime,0) as Shift2Downtime,
ISNULL(Shift2Remarks,'') as Remarks2,Shift2Operatorname,
ISNULL(Shift3PlanQty,0) as Shift3PlanQty,ISNULL(Shift3Accepted,0) as Shift3Accepted,ISNULL(Shift3Rejected,0) as Shift3Rejected,
ISNULL(ROUND(Shift3AcceptPercent,2),0) as Shift3AcceptPercent,ISNULL(ROUND(Shift3Rejectpercent,2),0) as Shift3Rejectpercent,ISNULL(Shift3Downtime,0) as Shift3Downtime,
ISNULL(Shift3Remarks,'') as Remarks3,Shift3Operatorname,
ISNULL(ProdTotal,0) as ProdTotal,ISNULL(CumulativeProdTotal,0) as CumulativeProdTotal,
isnull(WorkingHrs,0) AS WorkingHrs,
Round(dbo.f_formattime(NonProductiveTime, 'hh'),2) as DownTimeinHrs,
(ISNULL(Shift1PlanQty,0)+ISNULL(Shift2PlanQty,0) +ISNULL(Shift3PlanQty,0)) as TotalPlannedQTY,
(ISNULL(Shift1Accepted,0)+ISNULL(Shift2Accepted,0) +ISNULL(Shift3Accepted,0)) as TotalAcceptedQTY,
(ISNULL(Shift1Rejected,0)+ISNULL(Shift2Rejected,0) +ISNULL(Shift3Rejected,0)) as TotalRejectedQTY,
(ISNULL(PrevdayAccepted,0)-ISNULL(PrevdayRejected,0)) as PrevdayAccepted,ISNULL(PrevdayRejected,0) as PrevdayRejected,
Total as TotalTime,  
(ISNULL(CumulativeProdTotal,0)-ISNULL(CumulativeRejTotal,0)) as CumulativeAcceptedQTY,ISNULL(CumulativeRejTotal,0) as CumulativeRejectedQTY,
dbo.f_formattime(A,'hh:mm:ss') as A,dbo.f_formattime(B,'hh:mm:ss') as B,dbo.f_formattime(C,'hh:mm:ss') as C,dbo.f_formattime(D,'hh:mm:ss') as D,
dbo.f_formattime(E,'hh:mm:ss') as E,dbo.f_formattime(F,'hh:mm:ss') as F,dbo.f_formattime(G,'hh:mm:ss') as G,dbo.f_formattime(H,'hh:mm:ss') as H,
dbo.f_formattime(Productivetime,'hh:mm:ss') as Productivetime,dbo.f_formattime(NonProductiveTime,'hh:mm:ss') as NonProductiveTime,
ISNULL(OverallPercent,0) as OverallPercent
 from #finaltarget1 order by Machineid

END
