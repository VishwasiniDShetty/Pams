/****** Object:  Procedure [dbo].[s_GetSONA_ANDONDetails_POC]    Committed by VersionSQL https://www.versionsql.com ******/

--NR0134 - SwathiKS - 20/Nov/2016 :: New Procedure to show Sch.Target,RunTarget,ActualCount,LineSpeed,DelayTime,Bekido,Machinestatus for SONA Web Andon.
--exec [dbo].[s_GetSONA_ANDONDetails_POC] '2016-06-14 10:30:00','','ACE VTL-06','',''
--[dbo].[s_GetSONA_ANDONDetails_POC] '2016-11-21 18:56:00','','siemens','',''

CREATE PROCEDURE [dbo].[s_GetSONA_ANDONDetails_POC]
	@Startdate datetime,
	@SHIFT nvarchar(50)='',
	@MachineID nvarchar(50) = '',
	@PlantID nvarchar(50)='',
	@Param nvarchar(50)=''

WITH RECOMPILE
AS
BEGIN

SET NOCOUNT ON; --ER0377

Declare @strPlantID as nvarchar(255)
Declare @strSql as nvarchar(4000)
Declare @strMachine as nvarchar(255)
declare @timeformat as nvarchar(2000)
Declare @StrTPMMachines AS nvarchar(500)
	
SELECT @StrTPMMachines=''				
SELECT @strMachine = ''
SELECT @strPlantID = ''
SELECT @timeformat ='ss'

Select @timeformat = isnull((select valueintext from cockpitdefaults where parameter='timeformat'),'ss')
if (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')
begin
	select @timeformat = 'ss'
end

Create Table #Shift
(	
	PDate datetime,
	ShiftName nvarchar(20),
	ShiftID int,
	Shiftstart datetime,
	Shiftend Datetime
)

Create Table #ShiftTemp
(	
	Plantid nvarchar(50),
	Machineid nvarchar(50),
	machineinterface nvarchar(50),
	PDate datetime,
	ShiftName nvarchar(20),
	ShiftID int,
	FromTime datetime,
	ToTime Datetime,
	Actual float,
	RunTarget int,
	ScheduledTarget float,
	OKProdqty float,
	RejCount float,
	LineLevelRejQty float,
	LineLevelRwkQty float,
	TotalAvailableHours float,
	BNMCT float,
	Bekido float,
	RunningComponent nvarchar(50),
	Linespeed float,
	DelayTime float,
	MachineStatus nvarchar(50),
	DownReason NvarChar(50),	
    DataType smallint


)


CREATE TABLE #MachineRunningStatus
(
	MachineID NvarChar(50),
	MachineInterface nvarchar(50),
	sttime Datetime,
	ndtime Datetime,
	DataType smallint,
	ColorCode varchar(10),
	DownReason NvarChar(50)

)


Create Table #PDT
(	
	Machineid nvarchar(50),
	machineinterface nvarchar(50),
	FromTime datetime,
	ToTime Datetime,
	StartTime_PDT Datetime,
	EndTime_PDT Datetime,
	DownReason nvarchar(50),
	Actual float
)

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

CREATE TABLE #Target    
(  
PDate datetime,  
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
sttime datetime,     
msttime datetime,  
ndtime datetime,  
batchid int,  
autodataid bigint ,
stdTime float,
Shift nvarchar(20),
datatype tinyint,  
Components float,  
DownCode nvarchar(50),
DownReason nvarchar(100),
SubOperations int,
Runtime float
)  
  
CREATE TABLE #FinalTarget    
(  
 PDate datetime,
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
 batchsttime datetime,     
 BatchStart datetime,  
 BatchEnd datetime,  
 batchid int,  
 Runtime float,  
 StdTime float,  
 Components float,  
 DownCode nvarchar(50),
 datatype tinyint,  
 Shift nvarchar(20),
 DownReason nvarchar(100),
 SubOperations int,
 avgCycletime float,
 Avgloadunload float
)  


Declare @T_ST AS Datetime 
Declare @T_ED AS Datetime 
declare @counter as datetime
declare @stdate as nvarchar(20)

if isnull(@machineid,'')<> ''
begin
	SET @strMachine = ' AND MachineInformation.MachineID = N''' + @machineid + ''''
end

if isnull(@PlantID,'')<> ''
Begin
	SET @strPlantID = ' AND PlantMachine.PlantID = N''' + @PlantID + ''''
End

IF ( SELECT TOP 1 ValueInText FROM  CockpitDefaults WHERE Parameter='TpmEnbMac')='E'
BEGIN
	SET  @StrTPMMachines = 'AND MachineInformation.TPMTrakEnabled = 1'
END
ELSE
BEGIN
	SET  @StrTPMMachines = ' '
END


INSERT INTO #Shift(PDate,Shiftname,Shiftstart,Shiftend,ShiftID)      
Exec [s_GetCurrentShiftTime] @Startdate,''  

Select @T_ST=min(Shiftstart) from #Shift
Select @T_ED=max(Shiftend) from #Shift

Declare @Shiftstart as datetime
Declare @Curtime as datetime

Select @Shiftstart = (Select Top 1 Shiftstart from #shift order by Shiftstart)
Select @Curtime = @Startdate --getdate()


Select @strsql=''
select @strsql ='insert into #T_autodata '
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'
	select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'
select @strsql = @strsql + ' from autodata where (( sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_ED,120)+''' ) OR '
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' )OR '
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ST,120)+'''
					and ndtime<='''+convert(nvarchar(25),@T_ED,120)+''' )'
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' and sttime<'''+convert(nvarchar(25),@T_ED,120)+''' ) )'
print @strsql
exec (@strsql)


select @strsql=''
Select @strsql = @Strsql + '
insert  #ShiftTemp	(Plantid,Machineid,MachineInterface,PDate,ShiftName,ShiftID,FromTime,ToTime,Actual,RunTarget,RejCount,LineLevelRejQty,LineLevelRwkQty)
Select Plantmachine.Plantid,MachineInformation.MachineID,MachineInformation.interfaceid,S.PDate,S.ShiftName,S.ShiftID,S.Shiftstart,S.Shiftend,0,0,0,0,0
FROM MachineInformation cross join #shift S
LEFT OUTER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID where 1=1 '
SET @strSql =  @strSql + @strMachine + @strPlantID + @StrTPMMachines
print @strsql
EXEC(@strSql)


  Update #ShiftTemp set Actual=T1.Actual1 from
	(
	select M.machineid as machine,S.FromTime as hrstart,S.ToTime as hrend,sum(A.partscount/O.suboperations) as Actual1
	from #T_autodata A
	inner join machineinformation M on M.interfaceid=A.mc
	inner join componentinformation C on C.interfaceid=A.comp
	inner join componentoperationpricing O on O.interfaceid=A.opn and C.componentid=O.componentid and O.MachineID = M.MachineID
	inner join #ShiftTemp S on M.Machineid= S.machineid
	where A.datatype=1 and A.ndtime>S.FromTime and A.ndtime<=S.ToTime
	group by M.machineid,S.FromTime ,S.ToTime
	) as T1 inner join #ShiftTemp on #ShiftTemp.machineid=T1.machine and #ShiftTemp.Fromtime=T1.hrstart and #ShiftTemp.totime=T1.hrend


	insert into #PDT
	select st.machineID,st.machineinterface,st.FromTime,st.ToTime,
	case when  st.FromTime > pdt.StartTime then st.FromTime else pdt.StartTime end,
	case when  st.ToTime < pdt.EndTime then st.ToTime else pdt.EndTime end,pdt.DownReason,0
	from #ShiftTemp st inner join PlannedDownTimes pdt
	on st.machineID = pdt.Machine and PDTstatus = 1 and
	((pdt.StartTime >= st.FromTime  AND pdt.EndTime <=st.ToTime)
	OR ( pdt.StartTime < st.FromTime  AND pdt.EndTime <= st.ToTime AND pdt.EndTime > st.FromTime )
	OR ( pdt.StartTime >= st.FromTime   AND pdt.StartTime <st.ToTime AND pdt.EndTime > st.ToTime )
	OR ( pdt.StartTime < st.FromTime  AND pdt.EndTime > st.ToTime))

	--ER0210-KarthikG-17/Dec/2009::From Here
	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
	BEGIN
	update #PDT set Actual=isnull(#PDT.Actual,0) + isNull(t1.Actual ,0) from
	(
		select M.machineid as machine,StartTime_PDT,EndTime_PDT,sum(A.partscount/O.suboperations) as Actual
		from #T_autodata A
		inner join machineinformation M on M.interfaceid=A.mc
		inner join componentinformation C on C.interfaceid=A.comp
		inner join componentoperationpricing O on O.interfaceid=A.opn and C.componentid=O.componentid and O.MachineID = M.MachineID
		inner join #PDT  on M.Machineid= #PDT.machineid
		where A.datatype=1 and A.ndtime>#PDT.StartTime_PDT and A.ndtime<=#PDT.EndTime_PDT
		group by M.machineid,StartTime_PDT,EndTime_PDT
	) as t1 inner join #PDT on #PDT.machineid=t1.machine and #PDT.StartTime_PDT=t1.StartTime_PDT and #PDT.EndTime_PDT=t1.EndTime_PDT

		Update #ShiftTemp set Actual = isnull(#ShiftTemp.Actual,0) - isNull(t1.Actual ,0) from(
			Select MachineID,FromTime,ToTime,sum(Actual) as Actual from #PDT Group by MachineID,FromTime,ToTime
		) as t1 inner join #ShiftTemp on t1.machineID = #ShiftTemp.machineID and
		t1.FromTime = #ShiftTemp.FromTime and t1.ToTime = #ShiftTemp.ToTime

	End

------To Calculate ShiftLevel SCHEDULED TARGET
Select @strsql=''   
Select @strsql= 'insert into #Target(MachineID,machineinterface,Component,Compinterface,Operation,Opninterface,  
Operator,Oprinterface,sttime,msttime,ndtime,FromTm,Totm,Pdate,batchid,autodataid,stdtime,Suboperations,Shift,datatype,components,Downcode,DownReason)'  
select @strsql = @strsql + ' SELECT machineinformation.machineid, machineinformation.interfaceid,componentinformation.componentid, componentinformation.interfaceid,  
componentoperationpricing.operationno, componentoperationpricing.interfaceid,EI.Employeeid,EI.interfaceid, 
Case when autodata.sttime< T.Shiftstart then T.Shiftstart else autodata.sttime end,    
Case when autodata.msttime< T.Shiftstart then T.Shiftstart else autodata.msttime end,   
Case when autodata.ndtime> T.ShiftEnd then T.ShiftEnd else autodata.ndtime end,  
T.shiftstart,T.Shiftend,T.pdate,0,autodata.id,componentoperationpricing.Cycletime,componentoperationpricing.Suboperations,T.ShiftName,autodata.datatype,
0,autodata.dcode,DI.DownID FROM #T_autodata  autodata  
INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID   
INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID    
INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID  AND componentinformation.componentid = componentoperationpricing.componentid  and componentoperationpricing.machineid=machineinformation.machineid   
Left Outer Join Employeeinformation EI on EI.interfaceid=autodata.opr   
Left Outer Join downcodeinformation DI on DI.interfaceid=autodata.dcode  
Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid   
Cross join #Shift T  
WHERE ((autodata.msttime >= T.Shiftstart  AND autodata.ndtime <= T.ShiftEnd)  
OR ( autodata.msttime < T.Shiftstart  AND autodata.ndtime <= T.ShiftEnd AND autodata.ndtime >T.Shiftstart )  
OR ( autodata.msttime >= T.Shiftstart AND autodata.msttime <T.ShiftEnd AND autodata.ndtime > T.ShiftEnd)  
OR ( autodata.msttime < T.Shiftstart AND autodata.ndtime > T.ShiftEnd))'  
select @strsql = @strsql + @strmachine + @strPlantID 
select @strsql = @strsql + ' order by autodata.msttime'  
print @strsql  
exec (@strsql) 
  

  
declare @mc_prev nvarchar(50),@comp_prev nvarchar(50),@opn_prev nvarchar(50),@datatype_prev nvarchar(50),@From_Prev datetime  
declare @mc nvarchar(50),@comp nvarchar(50),@opn nvarchar(50),@datatype nvarchar(50),@Fromtime datetime,@id nvarchar(50)  
declare @batchid int  
Declare @autodataid bigint,@autodataid_prev bigint  
  
declare @setupcursor  cursor  
set @setupcursor=cursor for  
select autodataid,FromTm,MachineID,Component,Operation,datatype from #Target order by machineid,msttime  
open @setupcursor  
fetch next from @setupcursor into @autodataid,@Fromtime,@mc,@comp,@opn,@datatype  
  
set @autodataid_prev=@autodataid  
set @mc_prev = @mc  
set @comp_prev = @comp  
set @opn_prev = @opn  
set @datatype_prev = @datatype  
SET @From_Prev = @Fromtime  
set @batchid =1  
  
while @@fetch_status = 0  
begin  
If @mc_prev=@mc and @comp_prev=@comp and @opn_prev=@opn and @datatype_prev=@datatype and @From_Prev = @Fromtime  
 begin    
  update #Target set batchid = @batchid where autodataid=@autodataid and MachineID=@mc and Component=@comp and Operation=@opn and datatype=@datatype and FromTm=@Fromtime  
  print @batchid  
 end  
 else  
 begin   
    set @batchid = @batchid+1          
    update #Target set batchid = @batchid where autodataid=@autodataid and MachineID=@mc and Component=@comp and Operation=@opn and datatype=@datatype and FromTm=@Fromtime  
    set @autodataid_prev=@autodataid   
    set @mc_prev=@mc    
    set @comp_prev=@comp  
    set @opn_prev=@opn   
    set @datatype_prev = @datatype  
    SET @From_Prev = @Fromtime  
 end   
 fetch next from @setupcursor into @autodataid,@Fromtime,@mc,@comp,@opn,@datatype  
   
end  
close @setupcursor  
deallocate @setupcursor  
  
insert into #FinalTarget (pdate,MachineID,Component,operation,Operator,machineinterface,Compinterface,Opninterface,Oprinterface,Datatype,batchid,Batchsttime,BatchStart,BatchEnd,Runtime,FromTm,ToTm,stdtime,Suboperations,shift,Components,Downcode,DownReason)   
Select pdate,MachineID,Component,operation,Operator,machineinterface,Compinterface,Opninterface,Oprinterface,Datatype,batchid,min(Sttime),min(msttime),max(ndtime),0,FromTm,ToTm,stdtime,Suboperations,shift,sum(Components),Downcode,DownReason from #Target   
group by pdate,MachineID,Component,operation,Operator,machineinterface,Compinterface,Opninterface,Oprinterface,Datatype,batchid,FromTm,ToTm,stdtime,shift,Suboperations,Downcode,DownReason order by batchid   


UPDATE #FinalTarget SET components = ISNULL(components,0) + ISNULL(t2.comp1,0)
From  
(  
 Select T1.mc,T1.comp,T1.opn,T1.opr,T1.Batchstart,T1.Batchend,
 SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp1
     From (select mc,comp,opn,opr,BatchStart,BatchEnd,SUM(autodata.partscount)AS OrginalCount from #T_autodata autodata  
     INNER JOIN #FinalTarget F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn and F.oprinterface=Autodata.opr  
     where ((autodata.ndtime>F.Batchsttime and autodata.ndtime<=F.BatchEnd))
	 and (autodata.datatype=1) and F.Datatype=1  
     Group By mc,comp,opn,opr,BatchStart,BatchEnd) as T1  
 INNER JOIN #FinalTarget F on F.machineinterface=T1.mc and F.Compinterface=T1.comp and F.Opninterface = T1.opn and F.oprinterface=T1.opr  
 and F.Batchstart=T1.Batchstart and F.Batchend=T1.Batchend
 Inner join componentinformation C on F.Compinterface = C.interfaceid  
 Inner join ComponentOperationPricing O ON  F.Opninterface = O.interfaceid and C.Componentid=O.componentid  
 inner join machineinformation on machineinformation.machineid =O.machineid  
 and F.machineinterface=machineinformation.interfaceid  
 GROUP BY T1.mc,T1.comp,T1.opn,T1.opr,T1.Batchstart,T1.Batchend  
) As T2 Inner Join #FinalTarget on T2.mc = #FinalTarget.machineinterface and  
T2.comp = #FinalTarget.compinterface and T2.opn = #FinalTarget.opninterface and  T2.opr = #FinalTarget.oprinterface   
and T2.BatchStart=#FinalTarget.BatchStart and T2.BatchEnd=#FinalTarget.BatchEnd  
 
 
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
BEGIN  
    
 UPDATE #FinalTarget SET components=ISNULL(components,0)- isnull(t2.PlanCt,0) 
  FROM ( select autodata.mc,autodata.comp,autodata.opn,autodata.opr,F.Batchstart,F.Batchend,
  ((CAST(Sum(ISNULL(PartsCount,1)) AS Float)/ISNULL(CO.SubOperations,1))) as PlanCt
  from #T_autodata autodata   
     INNER JOIN #FinalTarget F on F.machineinterface=autodata.mc and F.Compinterface=autodata.comp and F.Opninterface = autodata.opn and F.oprinterface=autodata.opr  
  inner join machineinformation M on autodata.mc=M.Interfaceid  
  Inner jOIN PlannedDownTimes T on T.Machine=M.Machineid    
  Inner join componentinformation CI on autodata.comp=CI.interfaceid   
  inner join componentoperationpricing CO on autodata.opn=CO.interfaceid and  
  CI.componentid=CO.componentid  and CO.machineid=M.machineid  
  WHERE autodata.DataType=1 and F.Datatype=1 and  
  (autodata.ndtime>F.Batchsttime) and (autodata.ndtime<=F.BatchEnd)   
  AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)  
   Group by autodata.mc,autodata.comp,autodata.opn,autodata.opr,F.Batchstart,F.Batchend,CO.SubOperations   
 ) as T2 Inner Join #FinalTarget on T2.mc = #FinalTarget.machineinterface and  
 T2.comp = #FinalTarget.compinterface and T2.opn = #FinalTarget.opninterface and  T2.opr = #FinalTarget.oprinterface   
 and T2.BatchStart=#FinalTarget.BatchStart and T2.BatchEnd=#FinalTarget.BatchEnd  
   
END  


Update #FinalTarget Set Runtime = datediff(second,BatchStart,BatchEnd)


update #Shifttemp set RunTarget= isnull(t1.tcount,0) from
(Select T.Shiftstart,T.mcid,SUM(tcount) as tcount from
	(
	select F.FromTm as ShiftStart,F.ToTm as ShiftEnd,F.Machineid as mcid, CO.componentid as component,CO.Operationno as operation,
	tcount=((F.Runtime*CO.suboperations)/CO.cycletime)*isnull(CO.targetpercent,100) /100
	from componentoperationpricing CO
	inner join #FinalTarget F on co.machineid=F.machineid and CO.Componentid=F.Component and Co.operationno=F.Operation 
	)T group by T.Shiftstart,T.mcid
) as T1 inner join #Shifttemp on #Shifttemp.Fromtime=T1.Shiftstart and #Shifttemp.Machineid=T1.mcid

declare @MinLuLR  integer
set @MinLuLR=isnull((select top 1 valueinint from Shopdefaults where parameter='MinLUforLR'),0)


Update #Shifttemp Set RunningComponent = T1.CurrentModel from 
(select top 1 C.componentid as CurrentModel from #T_autodata A  
inner join Machineinformation M on A.mc=M.interfaceid  
inner join Componentinformation C on A.comp=C.interfaceid  
inner join Componentoperationpricing CO on A.opn=CO.interfaceid and M.Machineid=CO.Machineid and C.Componentid=CO.Componentid 
where M.machineid=@Machineid 
order by sttime desc )T1 

declare @MAXSetupChangetime as datetime
declare @RunningModel as nvarchar(50)

Select @RunningModel = RunningComponent from #Shifttemp

Select @MAXSetupChangetime = MAX(BatchEnd) from #FinalTarget where downcode like('%Change Over%')
IF ISNULL(@MAXSetupChangetime,'1900-01-01')='1900-01-01'
Begin
Select @MAXSetupChangetime = MIN(BatchStart) from #FinalTarget 
END


UPDATE #FinalTarget SET Avgcycletime = isnull(Avgcycletime,0) + isNull(t2.avgcycle,0),AVGLoadUnload = isnull(AVGLoadUnload,0) + isnull(LD,0)
 from  
 (select S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd,  
 sum(autodata.cycletime)as avgcycle,Sum(case when autodata.loadunload>=@MinLuLR then (autodata.loadunload) end) as LD
 from #T_autodata autodata      
 inner join (Select Top 5 * From #FinalTarget where Datatype=1 and Component=@RunningModel and batchstart>@MAXSetupChangetime Order by BatchStart Desc)S
 on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface and autodata.opr = S.Oprinterface  
 where (autodata.ndtime>S.Batchsttime and autodata.ndtime<=S.BatchEnd  )
 and (autodata.datatype=1)  
 and (autodata.partscount>0)    
 group by S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd  
 ) as t2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and   
 t2.operation = #FinalTarget.operation and t2.Operator = #FinalTarget.Operator  
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  


If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_AvgCycletime_4m_PLD')='Y' --ER0363 Added
BEGIN

	 UPDATE #FinalTarget SET Avgcycletime = isnull(Avgcycletime,0) - isNull(t2.PPDT,0),AVGLoadUnload = isnull(AVGLoadUnload,0) - isnull(LD,0)  
	 from  (
	select A.MachineID,A.Component,A.operation,A.Operator,A.BatchStart,A.BatchEnd,Sum
			(CASE
			WHEN A.sttime >= T.StartTime  AND A.ndtime <=T.EndTime  THEN DateDiff(second,A.sttime,A.ndtime) --DR0325 Added
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
				select S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd,autodata.sttime,autodata.ndtime,autodata.msttime
				from #T_autodata autodata      
				inner join (Select Top 5 * From #FinalTarget where Component=@RunningModel and batchstart>@MAXSetupChangetime Order by BatchStart Desc) S
				on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface and autodata.opr = S.Oprinterface  
				where (autodata.ndtime>S.Batchsttime and autodata.ndtime<=S.BatchEnd)
				and (autodata.datatype=1) 
			)A
			CROSS jOIN PlannedDownTimes T 
			WHERE T.Machine=A.MachineID AND
			((A.msttime >= T.StartTime  AND A.ndtime <=T.EndTime)
			OR ( A.msttime < T.StartTime  AND A.ndtime <= T.EndTime AND A.ndtime > T.StartTime )
			OR ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime AND A.ndtime > T.EndTime )
			OR ( A.msttime < T.StartTime  AND A.ndtime > T.EndTime) )	
		group by A.MachineID,A.Component,A.operation,A.Operator,A.BatchStart,A.BatchEnd
	)
	as T2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and   
	 t2.operation = #FinalTarget.operation and t2.Operator = #FinalTarget.Operator  
	 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  

	--Handle intearction between ICD and PDT for type 1 production record for the selected time period.
		 UPDATE #FinalTarget SET Avgcycletime = isnull(Avgcycletime,0) + isNull(T2.IPDT ,0) 	FROM	
		(
		Select T1.MachineID,T1.Component,T1.operation,T1.Operator,T1.BatchStart,T1.BatchEnd,
		SUM(
		CASE 	
			When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
			When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
			When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
			when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		from #T_autodata autodata INNER Join --ER0324 Added
			(	select S.MachineID,S.Component,S.operation,S.Operator,S.BatchStart,S.BatchEnd,autodata.sttime,autodata.ndtime,autodata.msttime,
				S.Compinterface,S.Opninterface,S.Oprinterface,autodata.mc
				from #T_autodata autodata      
				inner join (Select Top 5 * From #FinalTarget where Component=@RunningModel and batchstart>@MAXSetupChangetime Order by BatchStart Desc) S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface and autodata.opr = S.Oprinterface  
				where (autodata.ndtime>S.Batchsttime and autodata.ndtime<=S.BatchEnd)
				and (autodata.datatype=1)And DateDiff(Second,sttime,ndtime)>CycleTime 
			) as T1
		ON AutoData.mc=T1.mc and autodata.comp=T1.Compinterface and autodata.opn=T1.Opninterface and autodata.opr = T1.Oprinterface  
		CROSS jOIN PlannedDownTimes T 
		Where AutoData.DataType=2 And T.Machine=T1.Machineid
		And (( autodata.Sttime >= T1.Sttime ) 
		And ( autodata.ndtime <= T1.ndtime )
		)
		AND
		((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
		or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
		or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
		or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )))	
		GROUP BY T1.MachineID,T1.Component,T1.operation,T1.Operator,T1.BatchStart,T1.BatchEnd
		)AS T2 inner join #FinalTarget on t2.MachineID = #FinalTarget.MachineID and  t2.Component = #FinalTarget.Component and   
	 t2.operation = #FinalTarget.operation and t2.Operator = #FinalTarget.Operator  
	 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  

	
End


Update #FinalTarget set avgCycletime=(isnull(T.avgCycletime,0)/isnull(T.components,1))* isnull(T.suboperations,1),
AVGLoadUnload=(isnull(T.AVGLoadUnload,0)/isnull(T.components,1))* isnull(T.suboperations,1) From
(Select Machineid,Component,Batchstart,suboperations,SUM(Components) as Components,SUM(avgCycletime) as avgCycletime,SUM(AVGLoadUnload) as AVGLoadUnload from #FinalTarget
where components>0 Group by Machineid,Component,Batchstart,suboperations)T 
inner join #FinalTarget on #FinalTarget.Component=T.Component and T.BatchStart=#FinalTarget.BatchStart


Update #Shifttemp Set Linespeed = T1.LS From
(
Select Machineid,SUM(avgCycletime/stdtime) as LS from
	(Select distinct Machineid,component,SUM(avgCycletime) + SUM(AVGLoadUnload) as avgCycletime,stdtime from #Finaltarget where avgCycletime>0
	group by Machineid,component,stdtime
	)T 
group by Machineid)T1 

Update #Shifttemp set RejCount = isnull(RejCount,0) + isnull(T1.RejQty,0)
From
( Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A
inner join Machineinformation M on A.mc=M.interfaceid
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
inner join #Shifttemp S on S.machineid=M.machineid and convert(nvarchar(10),(A.RejDate),126)=S.Pdate and A.RejShift=S.shiftid
where A.flag = 'Rejection' and A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (S.Pdate) and  
Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
group by A.mc,M.Machineid
)T1 inner join #Shifttemp B on B.Machineid=T1.Machineid 

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN

	Update #Shifttemp set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from
	(Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A
	inner join Machineinformation M on A.mc=M.interfaceid
	inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
	inner join #Shifttemp S on S.machineid=M.machineid and convert(nvarchar(10),(A.RejDate),126)=S.Pdate and A.RejShift=S.shiftid
	Cross join Planneddowntimes P
	where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid and
	A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (S.PDate) and 
	Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
	and P.starttime>=S.fromtime and P.Endtime<=S.totime
	group by A.mc,M.Machineid)T1 inner join #Shifttemp B on B.Machineid=T1.Machineid 

END

Update #Shifttemp set LineLevelRejQty = isnull(LineLevelRejQty,0) + isnull(T1.RejQty,0)
From
( Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A
inner join Machineinformation M on A.mc=M.interfaceid
inner join #Shifttemp S on S.machineid=M.machineid and convert(nvarchar(10),(A.RejDate),126)=S.Pdate and A.RejShift=S.shiftid
where A.flag = 'Rejection' and A.Rejection_code='99' and A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (S.Pdate) and  
Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
group by A.mc,M.Machineid
)T1 inner join #Shifttemp B on B.Machineid=T1.Machineid 

Update #Shifttemp set LineLevelRwkQty = isnull(LineLevelRwkQty,0) + isnull(T1.RejQty,0)
From
( Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A
inner join Machineinformation M on A.mc=M.interfaceid
inner join #Shifttemp S on S.machineid=M.machineid and convert(nvarchar(10),(A.RejDate),126)=S.Pdate and A.RejShift=S.shiftid
where A.flag = 'Rejection' and A.Rejection_code='98' and A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (S.Pdate) and  
Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
group by A.mc,M.Machineid
)T1 inner join #Shifttemp B on B.Machineid=T1.Machineid 



Update #Shifttemp Set Actual =T1.Actual, OKProdqty = T1.OKProdqty,TotalAvailableHours=T1.TotalAvailableHours From
(Select Machineid,SUM(Actual) as Actual,SUM(Actual)-SUM(RejCount) as OKProdqty,SUM(RejCount) as RejCount,SUM(LineLevelRejQty) as LineLevelRejQty,SUM(LineLevelRwkQty) as LineLevelRwkQty,
datediff(SECOND,@shiftstart,@curtime) as TotalAvailableHours from #Shifttemp
group by Machineid)T1 inner join #Shifttemp on #Shifttemp.Machineid=T1.Machineid

update #Shifttemp set TotalAvailableHours=isnull(#Shifttemp.TotalAvailableHours,0) - isNull(t1.PDTHours ,0) from
(
	select ISNULL(SUM(datediff(hour,StartTime_PDT,EndTime_PDT)),0) as PDTHours from #Shifttemp
	inner join #PDT  on #Shifttemp.Machineid= #PDT.machineid
	where #PDT.StartTime_PDT>=@shiftstart and #PDT.EndTime_PDT<=@curtime and #PDT.Machineid=@Machineid
) as t1 

update #Shifttemp set BNMCT = Isnull(BNMCT,0) + ISnull(T.Cycle,0) from
(Select T1.Machineid,Sum(T1.Cycletime) as Cycle from 
	(select co.machineid,co.Componentid,co.Operationno,sum(CO.Cycletime) as cycletime from 
		(select distinct A.mc,A.comp,A.opn from #T_autodata A   
		where A.ndtime>@shiftstart and A.ndtime<=@curtime 
		)A
	inner join Componentinformation C on A.comp=C.interfaceid  
	inner join Componentoperationpricing CO on A.opn=CO.interfaceid and C.Componentid=CO.Componentid 
	WHERE co.machineid='BNM' group by co.machineid,co.Componentid,co.Operationno 
	)T1 
group by T1.Machineid)T


update #Shifttemp  set Bekido = (OKProdqty * BNMCT)/(TotalAvailableHours) * 100 where OKProdqty>0 

Update #Shifttemp Set delaytime = T2.DT From (
Select T1.Machineid,SUM(T1.Delaytime) as DT From
(
	Select T.Machineid,T.Component,((S.RunTarget-T.Components)* T.StdTime) as Delaytime from
	(	
		Select F.Machineid,F.Component,SUM(F.Components) as Components,F.StdTime from #Finaltarget F
		Group by F.Machineid,F.Component,F.StdTime 
	)T inner join #Shifttemp S on T.Machineid=S.Machineid
)T1 group by T1.Machineid )T2


Declare @Type40Threshold int
Declare @Type1Threshold int
Declare @Type11Threshold int
Declare @Type22Threshold int

Set @Type40Threshold =0
Set @Type1Threshold = 0
Set @Type11Threshold = 0
Set @Type22Threshold = 0


--Set @Type40Threshold = (Select isnull(Valueintext2,5)*60 from shopdefaults where parameter='ANDONStatusThreshold' and valueintext = 'Type40Threshold')
--Set @Type1Threshold = (Select isnull(Valueintext2,5)*60 from shopdefaults where parameter='ANDONStatusThreshold' and valueintext = 'Type1Threshold')
--Set @Type11Threshold = (Select isnull(Valueintext2,5)*60 from shopdefaults where parameter='ANDONStatusThreshold' and valueintext = 'Type11Threshold')
--Set @Type22Threshold = (Select isnull(Valueintext2,5)*60 from shopdefaults where parameter='ANDONStatusThreshold' and valueintext = 'Type22Threshold')
Set @Type40Threshold = (Select isnull(Valueintext2,1) from shopdefaults where parameter='ANDONStatusThreshold' and valueintext = 'Type40Threshold')
Set @Type1Threshold = (Select isnull(Valueintext2,1) from shopdefaults where parameter='ANDONStatusThreshold' and valueintext = 'Type1Threshold')
Set @Type11Threshold = (Select isnull(Valueintext2,1) from shopdefaults where parameter='ANDONStatusThreshold' and valueintext = 'Type11Threshold')


print @Type40Threshold
print @Type1Threshold
print @Type11Threshold


Insert into #machineRunningStatus
select fd.MachineID,fd.MachineInterface,rawdata.sttime,rawdata.ndtime,rawdata.datatype,'White',rawdata.SplString2 from rawdata
inner join (select mc,max(slno) as slno from rawdata WITH (NOLOCK) where sttime<getdate() and isnull(ndtime,'1900-01-01')<getdate() 
and datatype in(2,42,40,41,1,11,22) and datepart(year,sttime)>'2000' group by mc ) t1 on t1.mc=rawdata.mc and t1.slno=rawdata.slno --For SAF DR0370
right outer join #Shifttemp fd on fd.MachineInterface = rawdata.mc
order by rawdata.mc



--update #machineRunningStatus set ColorCode = case when (datediff(second,sttime,@CurTime)- @Type11Threshold)>0  then 'Red' else 'Green' end where datatype in (11)
update #machineRunningStatus set ColorCode = 'Green' where datatype in (41,11)
update #machineRunningStatus set ColorCode = 'Red' where datatype in (42,2,22)

update #machineRunningStatus set ColorCode = t1.ColorCode from (
Select mrs.MachineID,Case when (
case when datatype = 40 then datediff(second,sttime,getdate())- @Type40Threshold
when datatype = 1 then datediff(second,ndtime,getdate())- @Type1Threshold
end) > 0 then 'Red' else 'Green' end as ColorCode
from #machineRunningStatus mrs 
where  datatype in (40,1)
) as t1 inner join #machineRunningStatus on t1.MachineID = #machineRunningStatus.MachineID

update #machineRunningStatus set ColorCode ='Red' where isnull(sttime,'1900-01-01')='1900-01-01'

update #Shifttemp set MachineStatus = T1.MCStatus from 
(select Machineid,
Case when Colorcode='White' then 'Stopped'
when Colorcode='Red' then 'Stopped'
when Colorcode='Green' then 'Running' end as MCStatus from #machineRunningStatus)T1
inner join #Shifttemp on T1.MachineID = #Shifttemp.MachineID




update #Shifttemp set datatype=T1.Datatype from 
(select Machineid,datatype from #machineRunningStatus)T1
inner join #Shifttemp on T1.MachineID = #Shifttemp.MachineID

update #Shifttemp set DownReason=T1.DownReason from 
(select Machineid,datatype,Downcodeinformation.DownID as DownReason from #machineRunningStatus
inner join Downcodeinformation on #machineRunningStatus.DownReason=Downcodeinformation.Interfaceid 
where #machineRunningStatus.datatype in (42,2,22))T1
inner join #Shifttemp on T1.MachineID = #Shifttemp.MachineID


 declare @TYPE22SUFFIX nvarchar(50)      
 select @TYPE22SUFFIX=ValueInText from Shopdefaults where Parameter='TYPE22ANDTYPE2SUFFIX'  

 declare @TYPE2SUFFIX nvarchar(50)      
 select @TYPE2SUFFIX=ValueInText2 from Shopdefaults where Parameter='TYPE22ANDTYPE2SUFFIX'  

update #Shifttemp set DownReason = T1.DownReason from 
(Select Machineid,case when datatype='22' then DownReason + ' ' + @TYPE22SUFFIX 
when datatype = '2' then DownReason + ' ' + @TYPE2SUFFIX else DownReason End as DownReason from #Shifttemp)T1
inner join #Shifttemp on T1.MachineID = #Shifttemp.MachineID



update #Shifttemp set DownReason='Machine Idle' where datatype in (42,2,22) and DownReason IS NULL

 declare @Targetsource nvarchar(50)      
 select @Targetsource=ValueInText from Shopdefaults where Parameter='TargetFrom'  

IF isnull(@Targetsource,'')='Default Target per CO'      
BEGIN      
  
Update #Shifttemp set ScheduledTarget = T1.Target from
(
select T.Machine,SUM(T.IdealCount) as Target
from (
     select L.date,
            L.Component,
            L.operation,
	        L.idealcount,
	        L.Machine,
			L.Shift,
            row_number() over(partition by L.Component,L.operation,L.Shift order by L.date desc) as rn
     from Loadschedule L inner join (Select distinct Pdate,Shift,machineid,Component,operation from #Finaltarget) as #Finaltarget on 
	 L.Component=#Finaltarget.Component and L.operation=#Finaltarget.operation and #Finaltarget.machineid=L.machine where L.Machine=@Machineid and L.Date<=#Finaltarget.Pdate and L.Shift=#Finaltarget.Shift
     ) as T 
where T.rn <= 1 group by T.Machine)T1 inner join #Shifttemp H on T1.machine=H.machineid
        
END      


select ISNULL(ScheduledTarget,0) as ScheduledTarget,ISNULL(RunTarget,0) as RunTarget,ISNULL(OKProdqty,0) as Actual,ISNULL(Round([dbo].[f_FormatTime](Delaytime,'mm'),0),0) as Delaytime,
ISNULL(Round(Linespeed*100,1),0) as Linespeed ,ISNULL(round(Bekido,1),0) as Bekido,MachineStatus,RunningComponent,
DownReason from #Shifttemp
--DownReason from #Shifttemp
end
