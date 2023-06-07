/****** Object:  Procedure [dbo].[S_SPF_GetERPImportDetails]    Committed by VersionSQL https://www.versionsql.com ******/

/************************************************************************************************************  
NR0137- swathiKS - 03/May/2017 :: To Export Production Details into [S_Maxop_GetERPProductionDetails] table in ERP Database For Maxop.
[dbo].[S_SPF_GetERPImportDetails]  '2018-01-01','2018-01-01','','','',''
[dbo].[S_SPF_GetERPImportDetails]  '2017-10-23','2017-10-27','','','',''
[dbo].[S_SPF_GetERPImportDetails]  '2017-10-23','2017-10-26','','','',''
[dbo].[S_SPF_GetERPImportDetails]  '2017-10-23','2018-01-13','','','',''
[dbo].[S_SPF_GetERPImportDetails]  '2017-10-23','2017-11-04','','','',''
[dbo].[S_SPF_GetERPImportDetails]  '2017-10-23','2018-01-10','','','',''
select top 10 * from autodata  order by id desc--where isnull(Workordernumber,-1)=-1
**************************************************************************************************************/  
CREATE PROCEDURE [dbo].[S_SPF_GetERPImportDetails]
 @StartDate datetime,  
 @EndDate datetime,  
 @Shiftname nvarchar(50)='',  
 @MachineID nvarchar(50) = '',  
 @Plantid nvarchar(50) = '',
 @param nvarchar(50) = ''  
WITH RECOMPILE  
AS  
BEGIN  
  
CREATE TABLE #ShiftDetails   
(  
PDate datetime,  
Shift nvarchar(20),  
ShiftStart datetime,  
ShiftEnd datetime,
Shiftid int  
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
	WorkOrderNumber nvarchar(50)
)  
  
ALTER TABLE #T_autodata  
  
ADD PRIMARY KEY CLUSTERED  
(  
 mc,sttime ASC  
)ON [PRIMARY]  
  

CREATE TABLE #Target    
( 
	PlantID nvarchar(50) NOT NULL,   
	MachineID nvarchar(50) NOT NULL,  
	machineinterface nvarchar(50),  
	Compinterface nvarchar(50),  
	OpnInterface nvarchar(50),  
	Component nvarchar(50) NOT NULL,  
	Operation nvarchar(50) NOT NULL,  
	Operator nvarchar(50),  
	OprInterface nvarchar(50),  
	Pdate datetime,
	FromTm datetime,  
	ToTm datetime,     
	msttime datetime,  
	ndtime datetime,  
	batchid int,  
	autodataid bigint ,
	Shift nvarchar(20), 
	CycleTime float,
	SupervisorCode nvarchar(50),
	WorkOrderNo nvarchar(50),
	Tool nvarchar(50)
)  

  
CREATE TABLE #FinalTarget    
(    
	PlantID nvarchar(50) NOT NULL,   
	MachineID nvarchar(50) NOT NULL,  
	machineinterface nvarchar(50),  
	Component nvarchar(50) NOT NULL,  
	Compinterface nvarchar(50),  
	Operation nvarchar(50) NOT NULL,  
	OpnInterface nvarchar(50),  
	Operator nvarchar(50) NOT NULL,  
	OprInterface nvarchar(50),  
	PDate datetime,
	FromTm datetime,  
	ToTm datetime,     
	Shift nvarchar(20),
	BatchStart datetime,  
	BatchEnd datetime,  
	batchid int,  
	OkQty float,
	Stdcycletime float,
	SupervisorCode nvarchar(50),
	WorkOrderNo nvarchar(50),
	Tool nvarchar(50),
	Downcode nvarchar(50),
	Downtime float,
	ManagementLoss float,
	DownInterface nvarchar(50),
	Starttime datetime,  
	EndTime datetime,
	RejectionCode nvarchar(50),   
	Rejectioninterface nvarchar(50),     
	RejQty int,  
	RejectionTS DATETIME,
	recordid bigint,
	Shiftid int 
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
  

Declare @strsql nvarchar(4000)  
Declare @strmachine nvarchar(1000)  
Declare @StrTPMMachines AS nvarchar(1000)  
Declare @StrPlantid as nvarchar(1000)  

Declare @timeformat as nvarchar(12)  

Declare @T_Start AS Datetime   
Declare @T_End AS Datetime  
  
Select @strsql = ''  
Select @StrTPMMachines = ''  
Select @strmachine = ''  
select @strPlantID = ''  

 
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
 
Create table #LastAggTrail
(
Pdate datetime,
Machineid nvarchar(50),
Starttime datetime,
recordid int
)

 
Create table #FinalShift
(
Pdate datetime,
Shift nvarchar(20),
Machineid nvarchar(50),
ShiftStart datetime,
ShiftEnd datetime,
LastAggstart datetime,
Recordid int,
Shiftid int
)

Create table #SPF_LastAggTrail
(
Pdate datetime,
Machineid nvarchar(50),
Starttime datetime,
Endtime datetime,
RecordType nvarchar(50),
Recordid bigint
)

SET @EndDate = CAST(datePart(yyyy,@EndDate) AS nvarchar(4)) + '-' + CAST(datePart(mm,@EndDate) AS nvarchar(2)) + '-' + CAST(datePart(dd,@EndDate) AS nvarchar(2))

insert into #SPF_LastAggTrail(pdate,Machineid,Starttime,Endtime,RecordType)
select distinct dbo.f_GetLogicalDayEnd(@EndDate) as Pdate,machineinformation.machineid,dbo.f_GetLogicalDayEnd(@EndDate) as Starttime,dbo.f_GetLogicalDayEnd(@EndDate) as Endtime,'Production' as Recordtype from machineinformation
where Machineid NOT IN (select distinct M.MachineID from machineinformation M inner Join [SPF_ERPDB].[dbo].[SPF_LastAggTrail] A on M.Machineid=A.MachineCode
and A.datatype='Production')



insert into #SPF_LastAggTrail(pdate,Machineid,Starttime,Endtime,RecordType)
select distinct A.Pdate,A.MachineCode,A.starttime as Starttime,A.Endtime as Endtime,'Production' as Recordtype from [SPF_ERPDB].[dbo].[SPF_LastAggTrail] A
where EXISTS(select distinct M.MachineID from machineinformation M inner Join [SPF_ERPDB].[dbo].[SPF_LastAggTrail] A on M.Machineid=A.MachineCode
and A.datatype='Production') and  A.datatype='Production'



select @StrSql=''
SELECT @StrSql=' insert into #LastAggTrail (Pdate,Machineid,Starttime)'
SELECT @StrSql=@StrSql + 'select convert(nvarchar(10),S.Pdate,120),S.Machineid,S.Endtime from #SPF_LastAggTrail S
inner join Machineinformation M on M.MachineID=S.Machineid
LEFT OUTER JOIN PlantMachine ON M.MachineID=PlantMachine.MachineID
where S.RecordType=''Production'' '
SELECT @StrSql=@StrSql +@strMachine+@strPlantID 	
EXEC(@StrSql)



Declare @Mdate as datetime
Declare @AMachine as nvarchar(50)
Declare @curLastAggstart as datetime
	
declare @CurStrtTime as datetime
declare @CurEndTime as datetime

	
Declare TemplateShift CURSOR FOR
SELECT distinct Pdate,Machineid,Starttime from #LastAggTrail order by machineid
OPEN TemplateShift
FETCH NEXT FROM TemplateShift INTO @Mdate,@AMachine,@curLastAggstart
		
WHILE (@@fetch_status = 0)
BEGIN
		
select @CurStrtTime=@Mdate
select @CurEndTime=@EndDate

---get shiftdefinition for all the days
while @CurStrtTime<=@EndDate
begin
	INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)
	EXEC s_GetShiftTime @CurStrtTime,''
	SELECT @CurStrtTime=DATEADD(DAY,1,@CurStrtTime)
end

insert into #FinalShift(Pdate,Shift,ShiftStart,ShiftEnd,Machineid,LastAggstart)
select convert(nvarchar(10),Pdate,120), Shift,ShiftStart,ShiftEnd,@AMachine,@curLastAggstart from #ShiftDetails order by ShiftStart asc

delete from #ShiftDetails
		
FETCH NEXT FROM TemplateShift INTO @Mdate,@AMachine,@curLastAggstart
end

	
close TemplateShift
deallocate TemplateShift


Select @T_Start=min(Shiftstart) from #FinalShift
Select @T_End=MAX(Shiftend) from #FinalShift


/* Planned Down times for the given time period */  
Select @strsql=''  
select @strsql = 'insert INTO #PlannedDownTimesShift(StartTime,EndTime,Machine,MachineInterface,Downreason,Shiftst)'  
select @strsql = @strsql + 'select  
CASE When StartTime<T1.ShiftStart Then T1.ShiftStart Else StartTime End,  
case When EndTime>T1.ShiftEnd Then T1.ShiftEnd Else EndTime End,  
Machine,MachineInformation.InterfaceID,  
DownReason,T1.ShiftStart  
FROM PlannedDownTimes cross join #FinalShift T1  
inner join MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID  
WHERE MachineInformation.machineid=T1.machineid and PDTstatus =1 and (  
(StartTime >= T1.ShiftStart  AND EndTime <=T1.ShiftEnd)  
OR ( StartTime < T1.ShiftStart  AND EndTime <= T1.ShiftEnd AND EndTime > T1.ShiftStart )  
OR ( StartTime >= T1.ShiftStart   AND StartTime <T1.ShiftEnd AND EndTime > T1.ShiftEnd )  
OR ( StartTime < T1.ShiftStart  AND EndTime > T1.ShiftEnd) )'  
select @strsql = @strsql + @strmachine   
select @strsql = @strsql + 'ORDER BY StartTime'  
print @strsql  
exec (@strsql)  


Select @strsql=''  
select @strsql ='insert into #T_autodata '  
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'  
 select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id,WorkOrderNumber '  
select @strsql = @strsql + ' from autodata where (( sttime >='''+ convert(nvarchar(25),@T_Start,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_End,120)+''' ) OR '  
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_Start,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_End,120)+''' )OR '  
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_Start,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_Start,120)+'''  
     and ndtime<='''+convert(nvarchar(25),@T_End,120)+''' )'  
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_Start,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_End,120)+''' and sttime<'''+convert(nvarchar(25),@T_End,120)+''' ) )'  
print @strsql  
exec (@strsql)  


Select @strsql=''   
Select @strsql= 'insert into #Target(PlantID,MachineID,machineinterface,Component,Compinterface,Operation,OpnInterface,Operator,OprInterface,Pdate,Shift,FromTm,ToTm,msttime,ndtime,batchid,autodataid
,CycleTime,SupervisorCode,WorkOrderNo)'  
select @strsql = @strsql + ' SELECT PlantInformation.PlantID,machineinformation.machineid, machineinformation.interfaceid,componentinformation.componentid, componentinformation.interfaceid,  
componentoperationpricing.operationno, componentoperationpricing.interfaceid,EI.Employeeid,EI.interfaceid,T.Pdate,T.shift,T.shiftstart,T.Shiftend,
Case when autodata.msttime< T.Shiftstart then T.Shiftstart else autodata.msttime end,   
Case when autodata.ndtime> T.ShiftEnd then T.ShiftEnd else autodata.ndtime end,  
0,autodata.id,componentoperationpricing.cycletime,0,autodata.WorkOrderNumber FROM #T_autodata  autodata  
INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID   
INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID    
INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID  
AND componentinformation.componentid = componentoperationpricing.componentid  
and componentoperationpricing.machineid=machineinformation.machineid 
inner Join Employeeinformation EI on EI.interfaceid=autodata.opr   
Left Outer Join downcodeinformation DI on DI.interfaceid=autodata.dcode  
Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid
Left Outer Join PlantInformation ON PlantMachine.PlantID=PlantInformation.PlantID      
inner join #FinalShift T on Machineinformation.machineid=T.machineid
WHERE 
(autodata.msttime>=T.LastAggstart)
and ((autodata.msttime >= T.Shiftstart  AND autodata.ndtime <= T.ShiftEnd)  
OR ( autodata.msttime < T.Shiftstart  AND autodata.ndtime <= T.ShiftEnd AND autodata.ndtime >T.Shiftstart )  
OR ( autodata.msttime >= T.Shiftstart AND autodata.msttime <T.ShiftEnd AND autodata.ndtime > T.ShiftEnd)  
OR ( autodata.msttime < T.Shiftstart AND autodata.ndtime > T.ShiftEnd))'  
select @strsql = @strsql + @strmachine + @strPlantID  
select @strsql = @strsql + ' order by autodata.msttime'  
print @strsql  
exec (@strsql)  


declare @mc_prev nvarchar(50),@comp_prev nvarchar(50),@opn_prev nvarchar(50),@PlantID_prev nvarchar(50),@Opr_prev nvarchar(50),@WorkOrderNo_prev nvarchar(50), @From_Prev datetime  
declare @mc nvarchar(50),@comp nvarchar(50),@opn nvarchar(50),@Fromtime datetime,@id nvarchar(50),@PlantID1 nvarchar(50),@Opr nvarchar(50),@WorkOrderNo nvarchar(50)  
declare @batchid int,@recordid int 
Declare @autodataid bigint,@autodataid_prev bigint  
  
declare @setupcursor  cursor  
set @setupcursor=cursor for  
select autodataid,FromTm,PlantID,MachineID,Component,Operation,Operator,WorkOrderNo from #Target order by machineid,msttime  
open @setupcursor  
fetch next from @setupcursor into @autodataid,@Fromtime,@PlantID1,@mc,@comp,@opn,@Opr,@WorkOrderNo
  
set @autodataid_prev=@autodataid  
set @mc_prev = @mc  
set @PlantID_prev = @PlantID1  
set @Opr_prev = @Opr  
set @WorkOrderNo_prev = @WorkOrderNo  
set @comp_prev = @comp  
set @opn_prev = @opn  
SET @From_Prev = @Fromtime  


set @batchid =1  
  
while @@fetch_status = 0  
begin  

If @PlantID_prev=@PlantID1 and @mc_prev=@mc and @comp_prev=@comp and @opn_prev=@opn and  @Opr_prev = @Opr and @WorkOrderNo_prev = @WorkOrderNo and @From_Prev = @Fromtime  
begin    
  update #Target set batchid = @batchid where autodataid=@autodataid and MachineID=@mc and Component=@comp and Operation=@opn and FromTm=@Fromtime  
  AND PlantID=@PlantID1 and Operator= @Opr and WorkOrderNo= @WorkOrderNo
end  
else  
begin   
    set @batchid = @batchid+1          
    update #Target set batchid = @batchid where autodataid=@autodataid and MachineID=@mc and Component=@comp and Operation=@opn and FromTm=@Fromtime 
	AND PlantID=@PlantID1 and Operator= @Opr and WorkOrderNo= @WorkOrderNo 

    set @autodataid_prev=@autodataid   
    set @mc_prev=@mc    
    set @comp_prev=@comp  
    set @opn_prev=@opn   
    SET @From_Prev = @Fromtime  
	set @PlantID_prev = @PlantID1  
	set @Opr_prev = @Opr  
	set @WorkOrderNo_prev = @WorkOrderNo 
end   
fetch next from @setupcursor into @autodataid,@Fromtime,@PlantID1,@mc,@comp,@opn,@Opr,@WorkOrderNo
   
end  

close @setupcursor  
deallocate @setupcursor  
  


insert into #FinalTarget (Plantid,MachineID,machineinterface,Component,Compinterface,Operation,OpnInterface,Operator,OprInterface,batchid,BatchStart,BatchEnd,Pdate,FromTm,ToTm,Shift,SupervisorCode,WorkOrderNo,OkQty,StdCycletime)   
Select Plantid,MachineID,machineinterface,Component,Compinterface,operation,Opninterface,Operator,OprInterface,batchid,min(msttime),max(ndtime),Pdate,FromTm,ToTm,shift,
SupervisorCode,WorkOrderNo,0,cycletime from #Target   
group by Plantid,MachineID,machineinterface,Component,Compinterface,operation,Opninterface,Operator,OprInterface,batchid,SupervisorCode,WorkOrderNo,Pdate,FromTm,ToTm,shift,CycleTime
order by batchid   


--Calculation of PartsCount Begins..  
UPDATE #FinalTarget SET OKQty = ISNULL(OKQty,0) + ISNULL(t2.comp1,0)
From  
(  
 Select T1.mc,T1.comp,T1.opn,T1.Batchstart,T1.Batchend,T1.opr,T1.WorkOrderNumber,
 SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp1
     From 
	(select autodata.mc,autodata.comp,autodata.opn,autodata.opr,autodata.WorkOrderNumber,F.BatchStart,F.BatchEnd,SUM(autodata.partscount)AS OrginalCount from #T_autodata autodata  
     INNER JOIN #FinalTarget F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn 
	 and F.OprInterface = Autodata.opr and F.WorkOrderNo = Autodata.WorkOrderNumber
     where (autodata.ndtime>F.BatchStart) and (autodata.ndtime<=F.BatchEnd) and (autodata.datatype=1)  
     Group By autodata.mc,autodata.comp,autodata.opn,autodata.opr,autodata.WorkOrderNumber,F.BatchStart,F.BatchEnd
	) as T1  
 inner join machineinformation on machineinformation.InterfaceID =T1.mc
 Inner join componentinformation C on T1.comp = C.interfaceid  
 Inner join ComponentOperationPricing O ON  T1.opn = O.interfaceid and C.Componentid=O.componentid and machineinformation.machineid=O.machineid
 GROUP BY T1.mc,T1.comp,T1.opn,T1.Batchstart,T1.Batchend,T1.opr,T1.WorkOrderNumber
) As T2 Inner Join #FinalTarget on T2.mc = #FinalTarget.machineinterface and  
T2.comp = #FinalTarget.compinterface and T2.opn = #FinalTarget.opninterface
and T2.BatchStart=#FinalTarget.BatchStart and T2.BatchEnd=#FinalTarget.BatchEnd and t2.opr=#FinalTarget.OprInterface and t2.WorkOrderNumber=#FinalTarget.WorkOrderNo  
  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
BEGIN  
    
 UPDATE #FinalTarget SET OKQty=ISNULL(OKQty,0)- isnull(t2.PlanCt,0) FROM 
( 
	SELECT autodata.mc,autodata.comp,autodata.opn,autodata.opr,autodata.WorkOrderNumber,F.Batchstart,F.Batchend,
  ((CAST(Sum(ISNULL(autodata.PartsCount,1)) AS Float)/ISNULL(CO.SubOperations,1))) as PlanCt
   from #T_autodata autodata   
  INNER JOIN #FinalTarget F on F.machineinterface=autodata.mc and F.Compinterface=autodata.comp and F.Opninterface = autodata.opn and autodata.opr=F.OprInterface and autodata.WorkOrderNumber=F.WorkOrderNo 
  Inner jOIN #PlannedDownTimesShift T on T.MachineInterface=autodata.mc    
  inner join machineinformation M on autodata.mc=M.Interfaceid  
  Inner join componentinformation CI on autodata.comp=CI.interfaceid   
  inner join componentoperationpricing CO on autodata.opn=CO.interfaceid and CI.componentid=CO.componentid  and CO.machineid=M.machineid
  WHERE autodata.DataType=1 and  
  (autodata.ndtime>F.BatchStart) and (autodata.ndtime<=F.BatchEnd)   
  AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)  
   Group by autodata.mc,autodata.comp,autodata.opn,autodata.opr,autodata.WorkOrderNumber,F.Batchstart,F.Batchend
 ) as T2 Inner Join #FinalTarget on T2.mc = #FinalTarget.machineinterface and T2.comp = #FinalTarget.compinterface and T2.opn = #FinalTarget.opninterface
 and T2.BatchStart=#FinalTarget.BatchStart and T2.BatchEnd=#FinalTarget.BatchEnd and t2.opr=#FinalTarget.OprInterface and t2.WorkOrderNumber=#FinalTarget.WorkOrderNo
 
END  

delete from #SPF_LastAggTrail

insert into #SPF_LastAggTrail(machineid,Starttime,Endtime,RecordType)
select distinct #FinalTarget.machineid,'2018-01-01 06:00:00' as Starttime,'2018-01-01 06:00:00' as Endtime,'Production' as Recordtype from [#FinalTarget]
where NOT EXISTS(select distinct #FinalTarget.MachineID from [#FinalTarget] inner Join [SPF_ERPDB].[dbo].[SPF_LastAggTrail] A on #FinalTarget.Machineid=A.Machinecode
and A.datatype='Production')


insert into #SPF_LastAggTrail(machineid,Starttime,Endtime,RecordType)
select distinct A.machinecode,A.starttime as Starttime,A.Endtime as Endtime,'Production' as Recordtype from [SPF_ERPDB].[dbo].[SPF_LastAggTrail] A
where EXISTS(select distinct F.MachineID from [#FinalTarget] F inner Join [SPF_ERPDB].[dbo].[SPF_LastAggTrail] A on F.Machineid=A.Machinecode
and A.datatype='Production') and  A.datatype='Production'

insert into [SPF_ERPDB].[dbo].[SPF_ProductionDetails](Date, ShiftCode, MachineCode, ItemCode, ProcessCode, OperatorCode, RoutesheetNo, ToolCode, StartDateTime, EndDateTime, ProcessedQty, StdCycleTime, SupervisorCode, InsertedBy, UpdatedBy, UpdatedTS)
select Convert(nvarchar(10),FromTm,120) as PDate,F.Shift,F.MachineID as MachineCode,Component as ComponentCode,Operation as ProcessCode,Operator,WorkOrderNo,Tool,BatchStart as Starttime,BatchEnd as Endtime,
ISNULL(OKQty,0) as OKQty,StdCycleTime,SupervisorCode,'TPM','TPM',getdate()
FROM #FinalTarget F inner JOIN #SPF_LastAggTrail M on F.Machineid=M.Machineid
where F.BatchStart>M.starttime 
Order by F.Machineid,FromTm,BatchStart


Insert into [SPF_ERPDB].[dbo].[SPF_LastAggTrail](Pdate,Machinecode,Starttime,Endtime,Datatype)
Select MAX(Pdate),Machineid,Max(BatchStart) as Start,MAX(BatchEnd) as Endtime,'Production' from #FinalTarget 
where Machineid NOT IN(Select Distinct machinecode From [SPF_ERPDB].[dbo].[SPF_LastAggTrail] where Datatype='Production')
group by Machineid


Update [SPF_ERPDB].[dbo].[SPF_LastAggTrail] SET Pdate=T1.Pdate,Starttime=T1.Start,Endtime=T1.Endtime FROM
(
Select MAX(Pdate) as pdate,Machineid,Max(BatchStart) as Start,MAX(BatchEnd) as Endtime from #FinalTarget 
where Machineid IN(Select Distinct machinecode From [SPF_ERPDB].[dbo].[SPF_LastAggTrail] where datatype='Production')
group by Machineid
)T1 inner join  [SPF_ERPDB].[dbo].[SPF_LastAggTrail] on [SPF_ERPDB].[dbo].[SPF_LastAggTrail].machinecode=T1.MachineID 
and [SPF_ERPDB].[dbo].[SPF_LastAggTrail].datatype='Production'
/*****************************************************************PRODUCTION EXPORT*************************************************************************/



/************************************************************DOWN EXPORT*********************************************************************/
TRUNCATE TABLE #SPF_LastAggTrail
TRUNCATE TABLE #T_autodata
TRUNCATE TABLE #LastAggTrail
Truncate Table #Finaltarget
truncate table #ShiftDetails
truncate table #FInalShift
truncate table #PlannedDownTimesShift

insert into #SPF_LastAggTrail(pdate,Machineid,Starttime,Endtime,RecordType)
select distinct dbo.f_GetLogicalDayEnd(@EndDate) as Pdate,machineinformation.machineid,dbo.f_GetLogicalDayEnd(@EndDate) as Starttime,dbo.f_GetLogicalDayEnd(@EndDate) as Endtime,'Down' as Recordtype from machineinformation
where Machineid NOT IN(select distinct M.MachineID from machineinformation M inner Join [SPF_ERPDB].[dbo].[SPF_LastAggTrail] A on M.Machineid=A.MachineCode
and A.datatype='Down')


insert into #SPF_LastAggTrail(pdate,Machineid,Starttime,Endtime,RecordType)
select distinct A.Pdate,A.MachineCode,A.starttime as Starttime,A.Endtime as Endtime,'Down' as Recordtype from [SPF_ERPDB].[dbo].[SPF_LastAggTrail] A
where EXISTS(select distinct M.MachineID from machineinformation M inner Join [SPF_ERPDB].[dbo].[SPF_LastAggTrail] A on M.Machineid=A.MachineCode
and A.datatype='Down') and  A.datatype='Down'


select @StrSql=''
SELECT @StrSql=' insert into #LastAggTrail (Pdate,Machineid,Starttime)'
SELECT @StrSql=@StrSql + 'select convert(nvarchar(10),S.Pdate,120),S.Machineid,S.Endtime from #SPF_LastAggTrail S
inner join Machineinformation M on M.MachineID=S.Machineid
LEFT OUTER JOIN PlantMachine ON M.MachineID=PlantMachine.MachineID
where S.RecordType=''Down'' '
SELECT @StrSql=@StrSql +@strMachine+@strPlantID 	
EXEC(@StrSql)

	
Declare TemplateShift CURSOR FOR
SELECT distinct Pdate,Machineid,Starttime from #LastAggTrail order by machineid
OPEN TemplateShift
FETCH NEXT FROM TemplateShift INTO @Mdate,@AMachine,@curLastAggstart
		
WHILE (@@fetch_status = 0)
BEGIN
		
select @CurStrtTime=@Mdate
select @CurEndTime=@EndDate
				
---get shiftdefinition for all the days
while @CurStrtTime<=@EndDate
begin
	INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)
	EXEC s_GetShiftTime @CurStrtTime,''
	SELECT @CurStrtTime=DATEADD(DAY,1,@CurStrtTime)
end

insert into #FinalShift(Pdate,Shift,ShiftStart,ShiftEnd,Machineid,LastAggstart)
select convert(nvarchar(10),Pdate,120), Shift,ShiftStart,ShiftEnd,@AMachine,@curLastAggstart from #ShiftDetails order by ShiftStart asc

delete from #ShiftDetails
		
FETCH NEXT FROM TemplateShift INTO @Mdate,@AMachine,@curLastAggstart
end

	
close TemplateShift
deallocate TemplateShift

Select @T_Start=''
Select @T_End=''
Select @T_Start=min(Shiftstart) from #FinalShift
Select @T_End=MAX(Shiftend) from #FinalShift


/* Planned Down times for the given time period */  
Select @strsql=''  
select @strsql = 'insert INTO #PlannedDownTimesShift(StartTime,EndTime,Machine,MachineInterface,Downreason,Shiftst)'  
select @strsql = @strsql + 'select  
CASE When StartTime<T1.ShiftStart Then T1.ShiftStart Else StartTime End,  
case When EndTime>T1.ShiftEnd Then T1.ShiftEnd Else EndTime End,  
Machine,MachineInformation.InterfaceID,  
DownReason,T1.ShiftStart  
FROM PlannedDownTimes cross join #FinalShift T1  
inner join MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID  
WHERE MachineInformation.machineid=T1.machineid and PDTstatus =1 and (  
(StartTime >= T1.ShiftStart  AND EndTime <=T1.ShiftEnd)  
OR ( StartTime < T1.ShiftStart  AND EndTime <= T1.ShiftEnd AND EndTime > T1.ShiftStart )  
OR ( StartTime >= T1.ShiftStart   AND StartTime <T1.ShiftEnd AND EndTime > T1.ShiftEnd )  
OR ( StartTime < T1.ShiftStart  AND EndTime > T1.ShiftEnd) )'  
select @strsql = @strsql + @strmachine   
select @strsql = @strsql + 'ORDER BY StartTime'  
print @strsql  
exec (@strsql)  

Select @strsql=''  
select @strsql ='insert into #T_autodata '  
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'  
 select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id,WorkOrderNumber '  
select @strsql = @strsql + ' from autodata where (( sttime >='''+ convert(nvarchar(25),@T_Start,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_End,120)+''' ) OR '  
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_Start,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_End,120)+''' )OR '  
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_Start,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_Start,120)+'''  
     and ndtime<='''+convert(nvarchar(25),@T_End,120)+''' )'  
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_Start,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_End,120)+''' and sttime<'''+convert(nvarchar(25),@T_End,120)+''' ) )'  
print @strsql  
exec (@strsql)  

Select @strsql=''   
Select @strsql= 'insert into #FinalTarget(Plantid,MachineID,machineinterface,Component,Compinterface,Operation,OpnInterface,Operator,OprInterface,Pdate,Shift,BatchStart,BatchEnd,
SupervisorCode,WorkOrderNo,Starttime,Endtime,downinterface,Downcode,Downtime)'  
select @strsql = @strsql + ' SELECT PlantMachine.plantid,machineinformation.machineid, machineinformation.interfaceid,componentinformation.componentid, componentinformation.interfaceid,  
componentoperationpricing.operationno, componentoperationpricing.interfaceid,EI.Employeeid,EI.interfaceid,T.Pdate,T.shift,T.shiftstart,T.Shiftend,
0,autodata.WorkOrderNumber,
case when autodata.sttime<T.Shiftstart then T.Shiftstart else autodata.sttime end AS StartTime,
case when autodata.ndtime>T.ShiftEnd then T.ShiftEnd else autodata.ndtime end AS EndTime,
DI.interfaceid,DI.DownID,
case
When (autodata.sttime >= T.Shiftstart AND autodata.ndtime <= T.ShiftEnd ) THEN autodata.loadunload
WHEN ( autodata.sttime < T.Shiftstart AND autodata.ndtime <= T.ShiftEnd AND autodata.ndtime > T.Shiftstart ) THEN DateDiff(second, T.Shiftstart, ndtime)
WHEN ( autodata.sttime >= T.Shiftstart AND autodata.sttime < T.ShiftEnd AND autodata.ndtime > T.ShiftEnd ) THEN  DateDiff(second, stTime, T.ShiftEnd)
ELSE
DateDiff(second, T.Shiftstart, T.ShiftEnd)END AS DownTime
 FROM #T_autodata  autodata  
INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID   
INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID    
INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID  
AND componentinformation.componentid = componentoperationpricing.componentid  
and componentoperationpricing.machineid=machineinformation.machineid
inner Join Employeeinformation EI on EI.interfaceid=autodata.opr   
inner Join downcodeinformation DI on DI.interfaceid=autodata.dcode  
Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid  
inner join #FinalShift T on Machineinformation.machineid=T.machineid
WHERE (autodata.msttime>=T.LastAggstart)
and (autodata.datatype=2) and ((autodata.msttime >= T.Shiftstart  AND autodata.ndtime <= T.ShiftEnd)  
OR ( autodata.msttime < T.Shiftstart  AND autodata.ndtime <= T.ShiftEnd AND autodata.ndtime >T.Shiftstart )  
OR ( autodata.msttime >= T.Shiftstart AND autodata.msttime <T.ShiftEnd AND autodata.ndtime > T.ShiftEnd)  
OR ( autodata.msttime < T.Shiftstart AND autodata.ndtime > T.ShiftEnd)) ' 
select @strsql = @strsql + @strmachine + @strPlantID  
select @strsql = @strsql + ' order by autodata.msttime'  
print @strsql  
exec (@strsql)  


If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
BEGIN
update #FinalTarget set DownTime = isnull(Downtime,0)-isnull(T1.plannedDT,0)
	from
(
	Select A.machineinterface,A.Compinterface,A.OpnInterface,A.OprInterface,A.WorkOrderNo,A.BatchStart,A.StartTime,A.EndTime,			
			sum(case
			WHEN A.StartTime >= T.StartTime  AND A.EndTime <=T.EndTime  THEN A.DownTime
			WHEN ( A.StartTime < T.StartTime  AND A.EndTime <= T.EndTime  AND A.EndTime > T.StartTime ) THEN DateDiff(second,T.StartTime,A.EndTime)
			WHEN ( A.StartTime >= T.StartTime   AND A.StartTime <T.EndTime  AND A.EndTime > T.EndTime  ) THEN DateDiff(second,A.StartTime,T.EndTime )
			WHEN ( A.StartTime < T.StartTime  AND A.EndTime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END) as plannedDT
	From #FinalTarget A CROSS jOIN #PlannedDownTimesShift T
			WHERE  T.machine=A.machineid and 
			((A.StartTime >= T.StartTime  AND A.EndTime <=T.EndTime)
			OR ( A.StartTime < T.StartTime  AND A.EndTime <= T.EndTime AND A.EndTime > T.StartTime )
			OR ( A.StartTime >= T.StartTime   AND A.StartTime <T.EndTime AND A.EndTime > T.EndTime )
			OR ( A.StartTime < T.StartTime  AND A.EndTime > T.EndTime))
			group by A.machineinterface,A.Compinterface,A.OpnInterface,A.OprInterface,A.WorkOrderNo,A.BatchStart,A.StartTime,A.EndTime
)T1
INNER JOIN #FinalTarget ON  T1.Machineinterface = #FinalTarget.Machineinterface and T1.Compinterface=#FinalTarget.Compinterface and T1.Opninterface=#FinalTarget.Opninterface
and T1.OprInterface=#FinalTarget.OprInterface and T1.BatchStart=#FinalTarget.BatchStart and T1.StartTime=#FinalTarget.StartTime and T1.EndTime=#FinalTarget.EndTime and T1.WorkOrderNo=#FinalTarget.WorkOrderNo
END

delete from #SPF_LastAggTrail

insert into #SPF_LastAggTrail(machineid,Starttime,Endtime,RecordType)
select distinct #FinalTarget.machineid,'2018-01-01 06:00:00' as Starttime,'2018-01-01 06:00:00' as Endtime,'Down' as Recordtype from [#FinalTarget]
where NOT EXISTS(select distinct #FinalTarget.MachineID from [#FinalTarget] inner Join [SPF_ERPDB].[dbo].[SPF_LastAggTrail] A on #FinalTarget.Machineid=A.Machinecode
and A.datatype='Down')


insert into #SPF_LastAggTrail(machineid,Starttime,Endtime,RecordType)
select distinct A.machinecode,A.starttime as Starttime,A.Endtime as Endtime,'Down' as Recordtype from [SPF_ERPDB].[dbo].[SPF_LastAggTrail] A
where EXISTS(select distinct F.MachineID from [#FinalTarget] F inner Join [SPF_ERPDB].[dbo].[SPF_LastAggTrail] A on F.Machineid=A.Machinecode
and A.datatype='Down') and  A.datatype='Down'

insert into [SPF_ERPDB].[dbo].[SPF_DowntimeDetails](Date, ShiftCode, MachineCode, ItemCode, ProcessCode, OperatorCode, RoutesheetNo, ToolCode, IdletimeReason, Idletime, SupervisorCode, InsertedBy, UpdatedBy, UpdatedTS, Downstart, DownEnd)
select Convert(nvarchar(10),F.Pdate,120) as PDate,F.Shift,F.MachineID as MachineCode,F.Component as ComponentCode,F.Operation as ProcessCode,F.Operator,F.WorkOrderNo,F.Tool,F.Downcode,F.Downtime,
F.SupervisorCode,'TPM','TPM',getdate(),F.Starttime,F.Endtime
FROM #FinalTarget F inner JOIN #SPF_LastAggTrail M on F.Machineid=M.Machineid
where F.BatchStart>M.starttime 
Order by F.Machineid,F.Pdate,F.BatchStart,F.Starttime


Insert into [SPF_ERPDB].[dbo].[SPF_LastAggTrail](Pdate,Machinecode,Starttime,Endtime,Datatype)
Select MAX(Pdate),Machineid,Max(BatchStart) as Start,MAX(BatchEnd) as Endtime,'Down' from #FinalTarget 
where Machineid NOT IN(Select Distinct machinecode From [SPF_ERPDB].[dbo].[SPF_LastAggTrail] where Datatype='Down')
group by Machineid


Update [SPF_ERPDB].[dbo].[SPF_LastAggTrail] SET Pdate=T1.Pdate,Starttime=T1.Start,Endtime=T1.Endtime FROM
(
Select MAX(Pdate) as pdate,Machineid,Max(BatchStart) as Start,MAX(BatchEnd) as Endtime from #FinalTarget 
where Machineid IN(Select Distinct machinecode From [SPF_ERPDB].[dbo].[SPF_LastAggTrail] where datatype='Down')
group by Machineid
)T1 inner join  [SPF_ERPDB].[dbo].[SPF_LastAggTrail] on [SPF_ERPDB].[dbo].[SPF_LastAggTrail].machinecode=T1.MachineID 
and [SPF_ERPDB].[dbo].[SPF_LastAggTrail].datatype='Down'
/*********************************************************DOWNTIME EXPORT****************************************************************************/

/************************************************************REJECTIONS EXPORT***********************************************************************************/

Truncate Table #FinalTarget
Truncate Table #SPF_lastAggTrail
Truncate Table #FinalShift
Truncate Table #ShiftDetails
Truncate Table #LastAggTrail 
tRUNCATE TABLE #PlannedDownTimesShift

insert into #SPF_LastAggTrail(pdate,Machineid,RecordType,Recordid)
select distinct dbo.f_GetLogicalDayEnd(@EndDate) as Pdate,machineinformation.machineid,'Rejection' as Recordtype,0 from machineinformation
where Machineid NOT IN(select distinct M.MachineID from machineinformation M inner Join [SPF_ERPDB].[dbo].[SPF_LastAggTrail] A on M.Machineid=A.MachineCode
and A.datatype='Rejection')


Select T.machineid,T.mc,T.recordid,A.Rejdate,A.RejShift Into #AutodataRejections from 
(
--select M.machineid,A.mc,MIN(A.recordid) as recordid From AutodataRejections A
select M.machineid,A.mc,MIN(A.recordid) as recordid From AutodataRejections A --g:
inner join machineinformation M on A.mc=M.InterfaceID
inner Join [SPF_ERPDB].[dbo].[SPF_LastAggTrail] S on M.Machineid=S.MachineCode
Where A.recordid>S.RecordID
group by M.machineid,A.mc
)T inner join AutodataRejections A on A.mc=T.mc and A.recordid=T.recordid

insert into #SPF_LastAggTrail(pdate,Machineid,RecordType,Recordid)
select distinct A.RejDate,S.MachineCode,'Rejection' as Recordtype,S.RecordID from [SPF_ERPDB].[dbo].[SPF_LastAggTrail] S
inner join #AutodataRejections A on A.machineid=S.MachineCode and A.recordid>S.RecordID
where EXISTS(select distinct M.MachineID from machineinformation M inner Join [SPF_ERPDB].[dbo].[SPF_LastAggTrail] A on M.Machineid=A.MachineCode
and A.datatype='Rejection') and  S.datatype='Rejection'

select @StrSql=''
SELECT @StrSql=' insert into #LastAggTrail (Pdate,Machineid,recordid)'
SELECT @StrSql=@StrSql + 'select convert(nvarchar(10),S.Pdate,120),S.Machineid,S.recordid from #SPF_LastAggTrail S
inner join Machineinformation M on M.MachineID=S.Machineid
LEFT OUTER JOIN PlantMachine ON M.MachineID=PlantMachine.MachineID
where S.RecordType=''Rejection'' '
SELECT @StrSql=@StrSql +@strMachine+@strPlantID 	
EXEC(@StrSql)


Declare TemplateShift CURSOR FOR
SELECT distinct Pdate,Machineid,recordid from #LastAggTrail order by machineid
OPEN TemplateShift
FETCH NEXT FROM TemplateShift INTO @Mdate,@AMachine,@recordid
		
WHILE (@@fetch_status = 0)
BEGIN
		
select @CurStrtTime=@Mdate
select @CurEndTime=@EndDate
				
---get shiftdefinition for all the days
while @CurStrtTime<=@EndDate
begin
	INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)
	EXEC s_GetShiftTime @CurStrtTime,''
	SELECT @CurStrtTime=DATEADD(DAY,1,@CurStrtTime)
end

insert into #FinalShift(Pdate,Shift,ShiftStart,ShiftEnd,Machineid,Recordid)
select convert(nvarchar(10),Pdate,120), Shift,ShiftStart,ShiftEnd,@AMachine,@recordid from #ShiftDetails order by ShiftStart asc

delete from #ShiftDetails
		
FETCH NEXT FROM TemplateShift INTO @Mdate,@AMachine,@recordid
end

	
close TemplateShift
deallocate TemplateShift

update #FinalShift set Shiftid=T.Shiftid from
(select * from shiftdetails where Running=1)T inner join #FinalShift on #FinalShift.Shift=T.Shiftname

Select @strsql=''  
select @strsql = 'insert INTO #PlannedDownTimesShift(StartTime,EndTime,Machine,MachineInterface,Downreason,Shiftst)'  
select @strsql = @strsql + 'select  
CASE When StartTime<T1.ShiftStart Then T1.ShiftStart Else StartTime End,  
case When EndTime>T1.ShiftEnd Then T1.ShiftEnd Else EndTime End,  
Machine,MachineInformation.InterfaceID,  
DownReason,T1.ShiftStart  
FROM PlannedDownTimes cross join #FinalShift T1  
inner join MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID  
WHERE MachineInformation.machineid=T1.machineid and PDTstatus =1 and (  
(StartTime >= T1.ShiftStart  AND EndTime <=T1.ShiftEnd)  
OR ( StartTime < T1.ShiftStart  AND EndTime <= T1.ShiftEnd AND EndTime > T1.ShiftStart )  
OR ( StartTime >= T1.ShiftStart   AND StartTime <T1.ShiftEnd AND EndTime > T1.ShiftEnd )  
OR ( StartTime < T1.ShiftStart  AND EndTime > T1.ShiftEnd) )'  
select @strsql = @strsql + @strmachine   
select @strsql = @strsql + 'ORDER BY StartTime'  
print @strsql  
exec (@strsql)  

Select @strsql=''     
Select @strsql= 'insert into #FinalTarget(Plantid,MachineID,machineinterface,Component,Compinterface,Operation,OpnInterface,Operator,OprInterface,Pdate,Shift,Shiftid,BatchStart,BatchEnd,  
SupervisorCode,WorkOrderNo,RejectionCode,RejectionInterface,RejectionTS,RejQty,recordid)'    
select @strsql = @strsql + ' SELECT Plantmachine.Plantid,machineinformation.machineid, machineinformation.interfaceid,componentinformation.componentid, componentinformation.interfaceid,    
componentoperationpricing.operationno, componentoperationpricing.interfaceid,EI.Employeeid,EI.interfaceid,T.Pdate,T.shift,T.Shiftid,T.shiftstart,T.Shiftend,  
0,autodata.WorkOrderNumber,R.RejectionID,R.Interfaceid,autodata.CreatedTS,SUM(autodata.Rejection_Qty),autodata.recordid FROM AutodataRejections autodata    
INNER JOIN machineinformation ON autodata.mc = machineinformation.InterfaceID     
INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID      
INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID  AND componentinformation.componentid = componentoperationpricing.componentid    
and componentoperationpricing.machineid=machineinformation.machineid
inner Join Employeeinformation EI on EI.interfaceid=autodata.opr     
inner Join rejectioncodeinformation R on R.interfaceid=autodata.Rejection_Code    
Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid    
left outer join (select machinecode,recordid from [SPF_ERPDB].[dbo].[SPF_LastAggTrail] where Datatype=''Rejection'')ML on machineinformation.machineid=ML.machineCode      
inner join #FinalShift T on T.machineid=machineinformation.machineid and autodata.Rejshift=T.Shiftid 
and Convert(nvarchar(10),autodata.RejDate,120)=Convert(nvarchar(10),T.PDate,120)  
where autodata.flag = ''Rejection''  and autodata.recordid>ISNULL(ML.recordid,''0'')'    
select @strsql = @strsql + @strmachine + @strPlantID    
select @strsql = @strsql + ' group by Plantmachine.Plantid,machineinformation.machineid, machineinformation.interfaceid,componentinformation.componentid, componentinformation.interfaceid,    
componentoperationpricing.operationno, componentoperationpricing.interfaceid,EI.Employeeid,EI.interfaceid,T.Pdate,T.Shiftid,T.shift,T.shiftstart,T.Shiftend,  
autodata.WorkOrderNumber,R.RejectionID,R.Interfaceid,autodata.CreatedTS,autodata.recordid'    
print @strsql    
exec (@strsql)    
  
  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
BEGIN  
 Update #FinalTarget set RejQty = isnull(S.RejQty,0) - isnull(T1.RejQty,0) from  
 (Select S.machineinterface,S.Compinterface,S.OpnInterface,S.OprInterface,S.WorkOrderNo,S.RejectionInterface,S.recordid,SUM(A.Rejection_Qty) as RejQty from AutodataRejections A  
 inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid  
 inner join #FinalTarget S on A.mc = S.Machineinterface and A.comp=S.Compinterface and A.opn=S.Opninterface  
 and A.Opr = S.OprInterface and A.WorkOrderNumber=S.WorkOrderNo and A.Rejection_code=S.RejectionInterface  
 Cross join #PlannedDownTimesShift P  
 where A.flag = 'Rejection' and P.machine=S.Machineid and A.Rejshift=S.Shiftid and convert(nvarchar(10),(A.RejDate),126)=(S.Pdate) and     
 Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'   
 and P.starttime>=S.BatchStart and P.Endtime<=S.BatchEnd  
 group by S.machineinterface,S.Compinterface,S.OpnInterface,S.OprInterface,S.WorkOrderNo,S.RejectionInterface,S.RejectionTS,S.Recordid)T1   
 inner join #FinalTarget S on T1.Machineinterface = S.Machineinterface and T1.Compinterface=S.Compinterface and T1.Opninterface=S.Opninterface  
 and T1.OprInterface = S.OprInterface and T1.WorkOrderNo=S.WorkOrderNo and T1.RejectionInterface=S.RejectionInterface and T1.Recordid=S.Recordid
END   
 
Truncate table #SPF_LastAggTrail

insert into #SPF_LastAggTrail(Machineid,Starttime,Endtime,RecordType,Recordid)
select distinct #FinalTarget.machineid,'2017-01-01 06:00:00' as Starttime,'2017-01-01 06:00:00' as Endtime,'Rejection' as Recordtype,'0' from [#FinalTarget]  
where NOT EXISTS(select distinct #FinalTarget.MachineID from [#FinalTarget] inner Join [SPF_ERPDB].[dbo].[SPF_LastAggTrail]  A on #FinalTarget.Machineid=A.Machinecode
and A.Datatype='Rejection')  
  
  
insert into #SPF_LastAggTrail(Machineid,Starttime,Endtime,RecordType,Recordid)
select distinct A.machinecode,A.starttime as Starttime,A.Endtime as Endtime,'Rejection' as Recordtype,A.RecordId from [SPF_ERPDB].[dbo].[SPF_LastAggTrail]  A  
where EXISTS(select distinct F.MachineID from [#FinalTarget] F inner Join [SPF_ERPDB].[dbo].[SPF_LastAggTrail]  A on F.Machineid=A.Machinecode 
and A.datatype='Rejection') and  A.datatype='Rejection'  
  
Insert into [SPF_ERPDB].[dbo].[SPF_RejectionDetails](Date, ShiftCode, MachineCode, ItemCode, ProcessCode, OperatorCode, RoutesheetNo, ToolCode, RejectionReason, RejectionQty, SupervisorCode, InsertedBy, UpdatedBy, UpdatedTS)  
select Convert(nvarchar(10),F.Pdate,120) as PDate,F.Shift,F.MachineID as MachineCode,F.Component as ComponentCode, F.Operation as ProcessCode,
F.Operator as OperatorCode,F.WorkOrderNo,F.Tool,RejectionCode,RejQty,SupervisorCode,'TPM','TPM',getdate()  
from #FinalTarget F  
INNER JOIN #SPF_LastAggTrail M on F.Machineid=M.Machineid  
where F.recordid>M.Recordid and M.RecordType='Rejection'  
Order by F.Machineid,F.recordid,F.RejectionCode  
  
Insert into [SPF_ERPDB].[dbo].[SPF_LastAggTrail] (Machinecode,Starttime,datatype,Recordid)  
Select Machineid,Max(RejectionTS) as Start,'Rejection',Max(Recordid) from #FinalTarget   
where Machineid NOT IN(Select Distinct Machinecode From [SPF_ERPDB].[dbo].[SPF_LastAggTrail]  where datatype='Rejection')  
group by Machineid 
  
  
Update [SPF_ERPDB].[dbo].[SPF_LastAggTrail]  SET Starttime=T1.Start,Recordid=T1.id FROM  
(  
Select Machineid,Max(RejectionTS) as start,Max(recordid) as id from #FinalTarget   
where Machineid IN(Select Distinct Machinecode From [SPF_ERPDB].[dbo].[SPF_LastAggTrail] where datatype='Rejection')  
group by Machineid  
)T1 inner join  [SPF_ERPDB].[dbo].[SPF_LastAggTrail]  on [SPF_ERPDB].[dbo].[SPF_LastAggTrail].Machinecode=T1.Machineid   
and [SPF_ERPDB].[dbo].[SPF_LastAggTrail].datatype='Rejection'  
/******************************************************REJECTIONS EXPORT*********************************************************************/

/************************************************************REWORK EXPORT***********************************************************************************/

Truncate Table #FinalTarget
Truncate Table #SPF_lastAggTrail
Truncate Table #FinalShift
Truncate Table #ShiftDetails
Truncate Table #LastAggTrail 
tRUNCATE TABLE #PlannedDownTimesShift

insert into #SPF_LastAggTrail(pdate,Machineid,RecordType,Recordid)
select distinct dbo.f_GetLogicalDayEnd(@EndDate) as Pdate,machineinformation.machineid,'MarkedforRework' as Recordtype,0 from machineinformation
where Machineid NOT IN(select distinct M.MachineID from machineinformation M inner Join [SPF_ERPDB].[dbo].[SPF_LastAggTrail] A on M.Machineid=A.MachineCode
and A.datatype='MarkedforRework')


Select T.machineid,T.mc,T.recordid,A.Rejdate,A.RejShift Into #AutodataRework from 
(
--select M.machineid,A.mc,MIN(A.recordid) as recordid From AutodataRejections A
select M.machineid,A.mc,Min(A.recordid) as recordid From AutodataRejections A
inner join machineinformation M on A.mc=M.InterfaceID
inner Join [SPF_ERPDB].[dbo].[SPF_LastAggTrail] S on M.Machineid=S.MachineCode
Where A.recordid>S.RecordID
group by M.machineid,A.mc
)T inner join AutodataRejections A on A.mc=T.mc and A.recordid=T.recordid


insert into #SPF_LastAggTrail(pdate,Machineid,RecordType,Recordid)
select distinct A.RejDate,S.MachineCode,'MarkedforRework' as Recordtype,S.RecordID from [SPF_ERPDB].[dbo].[SPF_LastAggTrail] S
inner join #AutodataRework A on A.machineid=S.MachineCode and A.recordid>S.RecordID
where EXISTS(select distinct M.MachineID from machineinformation M inner Join [SPF_ERPDB].[dbo].[SPF_LastAggTrail] A on M.Machineid=A.MachineCode
and A.datatype='MarkedforRework') and  S.datatype='MarkedforRework'


select @StrSql=''
SELECT @StrSql=' insert into #LastAggTrail (Pdate,Machineid,recordid)'
SELECT @StrSql=@StrSql + 'select convert(nvarchar(10),S.Pdate,120),S.Machineid,S.recordid from #SPF_LastAggTrail S
inner join Machineinformation M on M.MachineID=S.Machineid
LEFT OUTER JOIN PlantMachine ON M.MachineID=PlantMachine.MachineID
where S.RecordType=''MarkedforRework'' '
SELECT @StrSql=@StrSql +@strMachine+@strPlantID 	
EXEC(@StrSql)

Declare TemplateShift CURSOR FOR
SELECT distinct Pdate,Machineid,recordid from #LastAggTrail order by machineid
OPEN TemplateShift
FETCH NEXT FROM TemplateShift INTO @Mdate,@AMachine,@recordid
		
WHILE (@@fetch_status = 0)
BEGIN
		
select @CurStrtTime=@Mdate
select @CurEndTime=@EndDate
				
---get shiftdefinition for all the days
while @CurStrtTime<=@EndDate
begin
	INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)
	EXEC s_GetShiftTime @CurStrtTime,''
	SELECT @CurStrtTime=DATEADD(DAY,1,@CurStrtTime)
end

insert into #FinalShift(Pdate,Shift,ShiftStart,ShiftEnd,Machineid,Recordid)
select convert(nvarchar(10),Pdate,120), Shift,ShiftStart,ShiftEnd,@AMachine,@recordid from #ShiftDetails order by ShiftStart asc

delete from #ShiftDetails
		
FETCH NEXT FROM TemplateShift INTO @Mdate,@AMachine,@recordid
end

	
close TemplateShift
deallocate TemplateShift

update #FinalShift set Shiftid=T.Shiftid from
(select * from shiftdetails where Running=1)T inner join #FinalShift on #FinalShift.Shift=T.Shiftname

Select @strsql=''  
select @strsql = 'insert INTO #PlannedDownTimesShift(StartTime,EndTime,Machine,MachineInterface,Downreason,Shiftst)'  
select @strsql = @strsql + 'select  
CASE When StartTime<T1.ShiftStart Then T1.ShiftStart Else StartTime End,  
case When EndTime>T1.ShiftEnd Then T1.ShiftEnd Else EndTime End,  
Machine,MachineInformation.InterfaceID,  
DownReason,T1.ShiftStart  
FROM PlannedDownTimes cross join #FinalShift T1  
inner join MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID  
WHERE MachineInformation.machineid=T1.machineid and PDTstatus =1 and (  
(StartTime >= T1.ShiftStart  AND EndTime <=T1.ShiftEnd)  
OR ( StartTime < T1.ShiftStart  AND EndTime <= T1.ShiftEnd AND EndTime > T1.ShiftStart )  
OR ( StartTime >= T1.ShiftStart   AND StartTime <T1.ShiftEnd AND EndTime > T1.ShiftEnd )  
OR ( StartTime < T1.ShiftStart  AND EndTime > T1.ShiftEnd) )'  
select @strsql = @strsql + @strmachine   
select @strsql = @strsql + 'ORDER BY StartTime'  
print @strsql  
exec (@strsql)  

Select @strsql=''     
Select @strsql= 'insert into #FinalTarget(Plantid,MachineID,machineinterface,Component,Compinterface,Operation,OpnInterface,Operator,OprInterface,Pdate,Shift,Shiftid,BatchStart,BatchEnd,  
SupervisorCode,WorkOrderNo,RejectionCode,RejectionInterface,RejectionTS,RejQty,recordid)'    
select @strsql = @strsql + ' SELECT Plantmachine.Plantid,machineinformation.machineid, machineinformation.interfaceid,componentinformation.componentid, componentinformation.interfaceid,    
componentoperationpricing.operationno, componentoperationpricing.interfaceid,EI.Employeeid,EI.interfaceid,T.Pdate,T.shift,T.Shiftid,T.shiftstart,T.Shiftend,  
0,autodata.WorkOrderNumber,R.Reworkid,R.Reworkinterfaceid,autodata.CreatedTS,SUM(autodata.Rejection_Qty),autodata.recordid FROM AutodataRejections autodata    
INNER JOIN machineinformation ON autodata.mc = machineinformation.InterfaceID     
INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID      
INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID  AND componentinformation.componentid = componentoperationpricing.componentid    
and componentoperationpricing.machineid=machineinformation.machineid
inner Join Employeeinformation EI on EI.interfaceid=autodata.opr     
inner Join Reworkinformation R on R.Reworkinterfaceid=autodata.Rejection_Code    
Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid    
left outer join (select machinecode,recordid from [SPF_ERPDB].[dbo].[SPF_LastAggTrail] where Datatype=''MarkedforRework'')ML on machineinformation.machineid=ML.machineCode      
inner join #FinalShift T on T.machineid=machineinformation.machineid and autodata.Rejshift=T.Shiftid 
and Convert(nvarchar(10),autodata.RejDate,120)=Convert(nvarchar(10),T.PDate,120)  
where autodata.flag = ''MarkedforRework''  and autodata.recordid>ISNULL(ML.recordid,''0'')'    
select @strsql = @strsql + @strmachine + @strPlantID    
select @strsql = @strsql + ' group by Plantmachine.Plantid,machineinformation.machineid, machineinformation.interfaceid,componentinformation.componentid, componentinformation.interfaceid,    
componentoperationpricing.operationno, componentoperationpricing.interfaceid,EI.Employeeid,EI.interfaceid,T.Pdate,T.Shiftid,T.shift,T.shiftstart,T.Shiftend,  
autodata.WorkOrderNumber,R.Reworkid,R.Reworkinterfaceid,autodata.CreatedTS,autodata.recordid'    
print @strsql    
exec (@strsql)    
  
  
  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
BEGIN  
 Update #FinalTarget set RejQty = isnull(S.RejQty,0) - isnull(T1.RejQty,0) from  
 (Select S.machineinterface,S.Compinterface,S.OpnInterface,S.OprInterface,S.WorkOrderNo,S.RejectionInterface,S.recordid,SUM(A.Rejection_Qty) as RejQty from AutodataRejections A  
 inner join Reworkinformation R on A.Rejection_code=R.Reworkinterfaceid  
 inner join #FinalTarget S on A.mc = S.Machineinterface and A.comp=S.Compinterface and A.opn=S.Opninterface  
 and A.Opr = S.OprInterface and A.WorkOrderNumber=S.WorkOrderNo and A.Rejection_code=S.RejectionInterface  
 Cross join #PlannedDownTimesShift P  
 where A.flag = 'MarkedforRework' and P.machine=S.Machineid and A.Rejshift=S.Shiftid and convert(nvarchar(10),(A.RejDate),126)=(S.Pdate) and     
 Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'   
 and P.starttime>=S.BatchStart and P.Endtime<=S.BatchEnd  
 group by S.machineinterface,S.Compinterface,S.OpnInterface,S.OprInterface,S.WorkOrderNo,S.RejectionInterface,S.RejectionTS,S.Recordid)T1   
 inner join #FinalTarget S on T1.Machineinterface = S.Machineinterface and T1.Compinterface=S.Compinterface and T1.Opninterface=S.Opninterface  
 and T1.OprInterface = S.OprInterface and T1.WorkOrderNo=S.WorkOrderNo and T1.RejectionInterface=S.RejectionInterface and T1.Recordid=S.Recordid
END   
 
Truncate table #SPF_LastAggTrail

insert into #SPF_LastAggTrail(Machineid,Starttime,Endtime,RecordType,Recordid)
select distinct #FinalTarget.machineid,'2017-01-01 06:00:00' as Starttime,'2017-01-01 06:00:00' as Endtime,'MarkedforRework' as Recordtype,'0' from [#FinalTarget]  
where NOT EXISTS(select distinct #FinalTarget.MachineID from [#FinalTarget] inner Join [SPF_ERPDB].[dbo].[SPF_LastAggTrail]  A on #FinalTarget.Machineid=A.Machinecode
and A.Datatype='MarkedforRework')  
  
  
insert into #SPF_LastAggTrail(Machineid,Starttime,Endtime,RecordType,Recordid)
select distinct A.machinecode,A.starttime as Starttime,A.Endtime as Endtime,'MarkedforRework' as Recordtype,A.RecordId from [SPF_ERPDB].[dbo].[SPF_LastAggTrail]  A  
where EXISTS(select distinct F.MachineID from [#FinalTarget] F inner Join [SPF_ERPDB].[dbo].[SPF_LastAggTrail]  A on F.Machineid=A.Machinecode 
and A.datatype='MarkedforRework') and  A.datatype='MarkedforRework'  
  
Insert into [SPF_ERPDB].[dbo].[SPF_ReworkDetails](Date, ShiftCode, MachineCode, ItemCode, ProcessCode, OperatorCode, RoutesheetNo, ToolCode, ReworkReason, ReworkQty, SupervisorCode, InsertedBy, UpdatedBy, UpdatedTS)  
select Convert(nvarchar(10),F.Pdate,120) as PDate,F.Shift,F.MachineID as MachineCode,F.Component as ComponentCode, F.Operation as ProcessCode,
F.Operator as OperatorCode,F.WorkOrderNo,F.Tool,RejectionCode,RejQty,SupervisorCode,'TPM','TPM',getdate()  
from #FinalTarget F  
INNER JOIN #SPF_LastAggTrail M on F.Machineid=M.Machineid  
where F.recordid>M.Recordid and M.RecordType='MarkedforRework'  
Order by F.Machineid,F.recordid,F.RejectionCode  
  
Insert into [SPF_ERPDB].[dbo].[SPF_LastAggTrail] (Machinecode,Starttime,datatype,Recordid)  
Select Machineid,Max(RejectionTS) as Start,'MarkedforRework',Max(Recordid) from #FinalTarget   
where Machineid NOT IN(Select Distinct Machinecode From [SPF_ERPDB].[dbo].[SPF_LastAggTrail]  where datatype='MarkedforRework')  
group by Machineid 
  
  
Update [SPF_ERPDB].[dbo].[SPF_LastAggTrail]  SET Starttime=T1.Start,Recordid=T1.id FROM  
(  
Select Machineid,Max(RejectionTS) as start,Max(recordid) as id from #FinalTarget   
where Machineid IN(Select Distinct Machinecode From [SPF_ERPDB].[dbo].[SPF_LastAggTrail] where datatype='MarkedforRework')  
group by Machineid  
)T1 inner join  [SPF_ERPDB].[dbo].[SPF_LastAggTrail]  on [SPF_ERPDB].[dbo].[SPF_LastAggTrail].Machinecode=T1.Machineid   
and [SPF_ERPDB].[dbo].[SPF_LastAggTrail].datatype='MarkedforRework'  
/******************************************************REWORK EXPORT*********************************************************************/


END  
