/****** Object:  Procedure [dbo].[s_GetProductionAndon_BremboBrakes]    Committed by VersionSQL https://www.versionsql.com ******/

/************************************************************************************************************  
-- Author: Anjana C V/Swathi
-- Create date: 05 Sep 2019
-- Modified date: 12 Sep 2019
exec [dbo].[s_GetProductionAndon_BremboBrakes]  '2019-09-16 12:37:00','TURNING-1','TURNING-2','VMC-1','VMC-2'
exec [dbo].[s_GetProductionAndon_BremboBrakes]  '2019-09-17 01:00:00','TURNING-1','TURNING-2','VMC-1','VMC-2'
 ************************************************************************************************************/  
CREATE PROCEDURE [dbo].[s_GetProductionAndon_BremboBrakes]  
 @SDateTime datetime = '',  
 @Mc1 nvarchar(50) = '',
 @Mc2 nvarchar(50) = '',
 @Mc3 nvarchar(4000) = '',
 @Mc4 nvarchar(50) = ''

WITH RECOMPILE  
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
 
Declare @strsql nvarchar(MAX)  
Declare @strmachine nvarchar(4000)  
Declare @T_Start datetime
Declare @T_End datetime
Declare @ShiftMc int 
Declare @LastShiftMc int
declare @Prevday as datetime

select @strsql  = ''
Select @strmachine = '' 
Select @Prevday= dateadd(day,-1,@SDateTime) 

if @SDateTime = ''
begin
	select @SDateTime = getdate()
end

CREATE TABLE #ShiftDetails   
(  
	PDate datetime,  
	Shift nvarchar(20),  
	ShiftStart datetime,  
	ShiftEnd datetime,
	ShiftType nvarchar(50),
	ShiftID nvarchar(50)
) 
 
CREATE TABLE #ShiftDetails1   
(  
	PDate datetime,  
	Shift nvarchar(20),  
	ShiftStart datetime,  
	ShiftEnd datetime,
	ShiftType nvarchar(50),
	ShiftID nvarchar(50)
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
	id  bigint not null  
)  
  
ALTER TABLE #T_autodata  
  
ADD PRIMARY KEY CLUSTERED  
(  
 mc,sttime ASC  
)ON [PRIMARY]  
  
CREATE TABLE #Target    
(  
	PlantId nvarchar(50),   
	GroupId nvarchar(50),  
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
	Shift nvarchar(20),
	ShiftType nvarchar(50),
	PDate datetime
)  

CREATE TABLE #FinalTarget    
(   
	PlantId nvarchar(50),   
	GroupId nvarchar(50),  
	MachineID nvarchar(50) NOT NULL,
	machineinterface nvarchar(50),
	Compinterface nvarchar(50),
	OpnInterface nvarchar(50),
	Oprinterface nvarchar(50),
	Component nvarchar(50) NOT NULL,  
    Operation nvarchar(50) NOT NULL,  
    Operator nvarchar(50),  
	msttime datetime,
    ndtime datetime,
	FromTm datetime,
	ToTm datetime,   
    runtime Float,   
    batchid int,
	BatchStart datetime,
	BatchEnd datetime,
	Target float Default 0,
	CumulativeActual float Default 0,
	autodataid bigint,
    Shift nvarchar(20),
	ShiftType nvarchar(50),
    PDate datetime
 )

 CREATE TABLE #ShiftData    
(   
	PlantId nvarchar(50),   
	GroupId nvarchar(50),  
	Machineid1 nvarchar(50),   
	Machineid2 nvarchar(50),   
	Machineid3 nvarchar(50),   
	Machineid4 nvarchar(50),  
	Mc_MaxCycleTime nvarchar(50),  
	MaxCycleTime nvarchar(50),
	targetpercent int,
	suboperations int,
	Runningpart nvarchar(50), 
	ComponentId nvarchar(50), 
	PDate datetime,
	ShiftName nvarchar(20),
	ShiftID int,
	Shiftstart datetime,
	ShiftEnd datetime,
	ShiftType nvarchar(50),
	Target float Default 0,
	CumulativeTarget float Default 0,
	Actual float Default 0,
	CumulativeActual float Default 0,
	Efficiency float,
	LastShiftEfficiency float
)

 CREATE TABLE #FinalData  
(   
	PlantId nvarchar(50),   
	GroupId nvarchar(50),   
	PDate datetime,
	ShiftName nvarchar(20),
	Shiftstart datetime,
	ShiftEnd datetime,
	ShiftTarget float Default 0,
	CumulativeTarget float Default 0,
	CumulativeActual float Default 0,
	Efficiency float,
	LastShiftTarget float Default 0,
	LastShiftActual float Default 0,
	LastShiftEfficiency float,
    RunningPart nvarchar(50)
)

INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd , ShiftID)  
   EXEC  dbo.[s_GetCurrentShiftTime] @SDateTime
   
UPDATE #ShiftDetails 
SET ShiftType = 'CurrentShift'

INSERT #ShiftDetails1(Pdate, Shift, ShiftStart, ShiftEnd)  
EXEC dbo.[s_GetShiftTime] @SDateTime

INSERT #ShiftDetails1(Pdate, Shift, ShiftStart, ShiftEnd)  
EXEC dbo.[s_GetShiftTime] @Prevday

INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)  
select top 1 Pdate, Shift, ShiftStart, ShiftEnd from #ShiftDetails1 where Shiftend<@SDateTime order by ShiftStart desc

UPDATE #ShiftDetails  SET ShiftType = 'LastShift' where isnull (ShiftType,'') = ''

if (isnull(@mc3,'') <> '' and isnull(@mc4,'') <> '' ) 
Begin  
 Select @strmachine = ' WHERE  Machineinformation.MachineID in (''' + @mc3 + ''','''+ @mc4 +''')' 
End  
 
select @T_Start = min(ShiftStart) from #ShiftDetails
select @T_End =  max(ShiftEnd) from #ShiftDetails

Select @strsql=''  
select @strsql ='insert into #T_autodata '  
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'  
select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'  
select @strsql = @strsql + ' from autodata where (( sttime >='''+ convert(nvarchar(25),@T_Start,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_End,120)+''' ) OR '  
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_Start,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_End,120)+''' )OR '  
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_Start,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_Start,120)+'''  
     and ndtime<='''+convert(nvarchar(25),@T_End,120)+''' )'  
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_Start,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_End,120)+''' and sttime<'''+convert(nvarchar(25),@T_End,120)+''' ) )'  
print @strsql  
exec (@strsql)  

--To pick components from Machine1 for the current and Last Shifts
insert into #ShiftData( Machineid1,Machineid2,Machineid3,Machineid4,ShiftName,PDate,Shiftstart,ShiftEnd,ShiftType,ShiftID,ComponentId)
 select distinct @Mc1,@Mc2,@Mc3,@Mc4,S.Shift,S.PDate,S.ShiftStart,S.ShiftEnd,S.ShiftType,ShiftID,C.Componentid 
		FROM  #ShiftDetails S 
			LEFT JOIN #T_autodata T on datatype in (1,2) and  (sttime >= S.ShiftStart and ndtime <= S.ShiftEnd) 
			LEFT JOIN Machineinformation ON  T.mc=Machineinformation.interfaceid AND  Machineinformation.Machineid = @Mc1 
			LEFT join Componentinformation C on T.comp=C.interfaceid  

--To update running part
UPDATE #ShiftData SET RunningPart = T.RunningPart
FROM (  
      SELECT distinct S.ShiftStart,S.ShiftEnd,S.ShiftType,C.Componentid  as RunningPart
	  FROM  #ShiftDetails S   
	  INNER join ( Select mc,max(sttime) as sttime , S1.Shiftstart, S1.ShiftEnd
						from #T_autodata 
						inner join  #ShiftDetails S1 ON (sttime >= S1.ShiftStart and ndtime <= S1.ShiftEnd) 
						Where datatype in (1,2)
						and S1.ShiftType = 'CurrentShift'
						group by mc , S1.Shiftstart, S1.ShiftEnd
			      )A on  A.Shiftstart = S.ShiftStart and A.ShiftEnd = S.ShiftEnd
	  INNER JOIN Machineinformation ON  A.mc=Machineinformation.interfaceid 
	  INNER join #T_autodata T on T.mc=A.mc and T.sttime=A.sttime and datatype in (1,2)
	  INNER join Componentinformation C on T.comp=C.interfaceid  
	  WHERE Machineinformation.Machineid = @Mc1 and S.ShiftType = 'CurrentShift'
     ) T INNER JOIN #ShiftData S ON T.Shiftstart = S.ShiftStart and T.ShiftEnd = S.ShiftEnd

--To pick Maximum Cycletime for the component among all Machines and update machine for that component&Cycletime
UPDATE #ShiftData
SET Mc_MaxCycleTime = T.Mc_MaxCycleTime,
MaxCycleTime = T.Maxcycletime,
suboperations = T.suboperations1,
targetpercent = T.targetpercent1
FROM (
      SELECT COP.componentid,
	  Machineid as Mc_MaxCycleTime,
	 -- (
		--SELECT Stuff((
		----SELECT DISTINCT ',' + ''''+ Co.Machineid +''''
		--SELECT DISTINCT ',' +  Co.Machineid 
		--FROM componentoperationpricing  Co
		--where Co.componentid = COP.componentid and Co.cycletime = C.Max_cycletime
		--FOR XML Path('')
		--,Type
		--).value('text()[1]', 'varchar(max)'), 1, 1, '')
		--)as Mc_MaxCycleTime,
	  cycletime as Maxcycletime,suboperations suboperations1,targetpercent targetpercent1
	  from componentoperationpricing COP
	  INNER JOIN (SELECT #ShiftData.componentid,max(cycletime) Max_cycletime from componentoperationpricing inner join #ShiftData on #ShiftData.ComponentId = componentoperationpricing.componentid group by #ShiftData.componentid
	             ) C ON C.componentid = COP.componentid and COP.cycletime = C.Max_cycletime
	  ) T INNER JOIN #ShiftData ON #ShiftData.ComponentId = T.componentid

 --Pick records from autodata for that Shift-component-machine
Select @strsql=''   
Select @strsql= 'insert into #Target(PlantID,GroupId,MachineID,machineinterface,Component,Compinterface,Operation,Opninterface,  
Operator,Oprinterface,msttime,ndtime,FromTm,Totm,batchid,autodataid,stdtime,Shift,ShiftType,PDate)'  
select @strsql = @strsql + ' SELECT PlantMachine.PlantID ,PlantMachineGroups.GroupId , machineinformation.machineid, machineinformation.interfaceid,
componentinformation.componentid, componentinformation.interfaceid,  
componentoperationpricing.operationno, componentoperationpricing.interfaceid,EI.Employeeid,EI.interfaceid,  
Case when autodata.msttime< S.Shiftstart then S.Shiftstart else autodata.msttime end,   
Case when autodata.ndtime> S.ShiftEnd then S.ShiftEnd else autodata.ndtime end,  
S.shiftstart,S.Shiftend,0,autodata.id,S.MaxCycleTime,S.ShiftName,S.ShiftType, S.PDate
 FROM #T_autodata  autodata  
 INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID  
 INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID    
 INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID  
 INNER JOIN #ShiftData S on  machineinformation.machineid = S.Mc_MaxCycleTime
 --machineinformation.machineid IN (SELECT item FROM SplitString(S.Mc_MaxCycleTime,'','') )
 and componentinformation.componentid = S.ComponentId
AND componentinformation.componentid = componentoperationpricing.componentid  
and componentoperationpricing.machineid=machineinformation.machineid   
inner Join Employeeinformation EI on EI.interfaceid=autodata.opr   
Left Outer Join downcodeinformation DI on DI.interfaceid=autodata.dcode  
Left  Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid   
Left  Join PlantMachineGroups ON PlantMachineGroups.MachineID=Machineinformation.machineid and PlantMachineGroups.PlantID = PlantMachine.PlantID
WHERE ((autodata.msttime >= S.Shiftstart  AND autodata.ndtime <= S.ShiftEnd)  
OR ( autodata.msttime < S.Shiftstart  AND autodata.ndtime <= S.ShiftEnd AND autodata.ndtime >S.Shiftstart )  
OR ( autodata.msttime >= S.Shiftstart AND autodata.msttime <S.ShiftEnd AND autodata.ndtime >S.ShiftEnd)  
OR ( autodata.msttime < S.Shiftstart AND autodata.ndtime > S.ShiftEnd))'  
select @strsql = @strsql
select @strsql = @strsql + ' order by autodata.msttime'  
print @strsql  
exec (@strsql)  

--Batching 
insert into #FinalTarget (PlantID,GroupId,MachineID,Component,operation,Operator,machineinterface,Compinterface,Opninterface,Oprinterface,runtime,
BatchStart,BatchEnd,FromTm,ToTm,shift,ShiftType,PDate,batchid)
	select PlantID,GroupId,MachineID,Component,operation,Operator,machineinterface,Compinterface,Opninterface,Oprinterface,0,--datediff(s,min(msttime),max(ndtime)),
	min(msttime),max(ndtime),FromTm,ToTm,shift,ShiftType,PDate,batchid
	from
	(
	select PlantID,GroupId,MachineID,Component,operation,Operator,machineinterface,Compinterface,Opninterface,Oprinterface,msttime,ndtime,FromTm,ToTm,stdtime,shift,ShiftType,PDate,
	RANK() OVER (
	  PARTITION BY t.machineid
	  order by t.machineid, t.msttime
	) -
	RANK() OVER (
	  PARTITION BY  t.PlantID,t.GroupId,t.machineid, t.component, t.operation, t.operator, t.fromtm  
	  order by t.PlantID,t.GroupId,t.machineid, t.fromtm, t.msttime
	) AS batchid
	from #Target t 
	) tt
	group by PlantID,GroupId,MachineID,Component,operation,Operator,machineinterface,Compinterface,Opninterface,Oprinterface,batchid,FromTm,ToTm,stdtime,shift,ShiftType,PDate
	order by tt.batchid

--updating batchend till curtime for cumulative target 
Update #FinalTarget SET BatchEnd = CASE WHEN T.Batchend < @SDateTime then @SDateTime ELSE T.Batchend END 
	FROM  (select Max(Batchend) Batchend ,ShiftType from #FinalTarget where ShiftType = 'CurrentShift' group by ShiftType) T 
	INNER JOIN #FinalTarget F ON F.ShiftType = T.ShiftType and T.Batchend = F.Batchend

--Update #FinalTarget SET Runtime =datediff(s,BatchStart,BatchEnd)

--calculate runtime from one batchstart to another batchstart to avoid gaps
Update #FinalTarget SET Runtime=ISNULL(datediff(second,T1.BatchStart,T1.BatchEnd),0) from
(select ShiftType,BatchStart,LEAD(BatchStart)OVER(ORDER BY batchstart) as batchend from #FinalTarget 
)T1 INNER JOIN #FinalTarget F ON F.ShiftType = T1.ShiftType and T1.BatchStart = F.BatchStart

--To Update Runtime for thae Last Batch/Record
Update #FinalTarget SET Runtime =datediff(s,BatchStart,BatchEnd) Where Runtime=0

Update #ShiftData set CumulativeTarget = Isnull(CumulativeTarget,0) + isnull(T1.targetcount,0) from 
		(
			Select T2.Component,T2.FromTm,T2.ToTm,SUM(targetcount) as targetcount
		  FROM
		  (
			Select T.Component,T.FromTm,T.ToTm,machineid,
			(sum((((T.Runtime)*S.suboperations)/S.MaxCycleTime)*isnull(S.targetpercent,100) /100)) as targetcount
			from #FinalTarget T 
			INNER JOIN  ( SELECT DISTINCT ComponentId,suboperations,targetpercent,MaxCycleTime,Shiftstart,ShiftEnd from #ShiftData) S
			ON S.ComponentId = T.Component and S.Shiftstart = T.FromTm and S.ShiftEnd = T.ToTm
			group by T.Component,T.FromTm,T.ToTm,S.suboperations,S.MaxCycleTime,S.targetpercent,machineid
			) T2
			group by T2.Component,T2.FromTm,T2.ToTm
		)T1 inner join #ShiftData on #ShiftData.ComponentId=T1.Component and #ShiftData.Shiftstart=T1.FromTm and  #ShiftData.ShiftEnd=T1.ToTm

--updating batchend till SHIFTEND for SHIFT target
Update #FinalTarget SET BatchEnd = CASE WHEN T.Batchend < ToTm then ToTm ELSE T.Batchend END 
FROM  (select Max(Batchend) Batchend ,ShiftType from #FinalTarget where ShiftType = 'CurrentShift' group by ShiftType) T INNER JOIN #FinalTarget F ON F.ShiftType = T.ShiftType and T.Batchend = F.Batchend

--Update #FinalTarget SET Runtime =datediff(s,BatchStart,BatchEnd)

--calculate runtime from one batchstart to another batchstart to avoid gaps
Update #FinalTarget SET Runtime=ISNULL(datediff(second,T1.BatchStart,T1.BatchEnd),0) from
(select ShiftType,BatchStart,LEAD(BatchStart)OVER(ORDER BY batchstart) as batchend from #FinalTarget 
)T1 INNER JOIN #FinalTarget F ON F.ShiftType = T1.ShiftType and T1.BatchStart = F.BatchStart

--To Update Runtime for thae Last Batch/Record
Update #FinalTarget SET Runtime =datediff(s,BatchStart,BatchEnd) Where Runtime=0

Update #ShiftData set Target = Isnull(Target,0) + isnull(T1.targetcount,0) from 
		(
			  Select T2.Component,T2.FromTm,T2.ToTm,SUM(targetcount) as targetcount
		  FROM
		  (
			Select T.Component,T.FromTm,T.ToTm,machineid,
			(sum((((T.Runtime)*S.suboperations)/S.MaxCycleTime)*isnull(S.targetpercent,100) /100)) as targetcount
			from #FinalTarget T 
			INNER JOIN  ( SELECT DISTINCT ComponentId,suboperations,targetpercent,MaxCycleTime,Shiftstart,ShiftEnd from #ShiftData) S
			ON S.ComponentId = T.Component and S.Shiftstart = T.FromTm and S.ShiftEnd = T.ToTm
			group by T.Component,T.FromTm,T.ToTm,S.suboperations,S.MaxCycleTime,S.targetpercent,machineid
			) T2
			group by T2.Component,T2.FromTm,T2.ToTm
		)T1 inner join #ShiftData on #ShiftData.ComponentId=T1.Component and #ShiftData.Shiftstart=T1.FromTm and  #ShiftData.ShiftEnd=T1.ToTm


Select @strsql=''   
Select @strsql= ' UPDATE #ShiftData SET CumulativeActual = ISNULL(CumulativeActual,0) + ISNULL(t2.comp,0)  
From  
(  
 Select T1.Shiftstart,T1.ShiftEnd,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp
     From (select mc,Shiftstart,ShiftEnd,SUM(autodata.partscount)AS OrginalCount,comp,opn from autodata  
			INNER JOIN  ( SELECT DISTINCT Shiftstart,ShiftEnd from #ShiftData) S
			ON (autodata.ndtime>S.Shiftstart) and (autodata.ndtime<=S.ShiftEnd) 
			where  (autodata.datatype=1)  
			Group By  mc,Shiftstart,ShiftEnd,comp,opn 
		  ) as T1  
 Inner join componentinformation C on T1.Comp = C.interfaceid  
 Inner join ComponentOperationPricing O ON  T1.Opn = O.interfaceid and C.Componentid=O.componentid  
 inner join machineinformation on machineinformation.machineid =O.machineid  
 and T1.mc=machineinformation.interfaceid '
Select @strsql= @strsql + @strmachine 
 Select @strsql= @strsql + ' GROUP BY T1.Shiftstart,T1.ShiftEnd  
	) As T2 Inner join #ShiftData on T2.Shiftstart = #ShiftData.Shiftstart and   T2.ShiftEnd = #ShiftData.ShiftEnd  '

PRINT @strsql
EXEC (@strsql)

--insert into #FinalData( RunningPart,ShiftName,PDate,Shiftstart,ShiftEnd,ShiftTarget,CumulativeTarget,CumulativeActual,Efficiency,LastShiftEfficiency)
--	select Runningpart,ShiftName,PDate,Shiftstart,ShiftEnd,Target,CumulativeTarget,CumulativeActual,0,0 from #ShiftData where ShiftType = 'CurrentShift' 

insert into #FinalData( RunningPart,ShiftName,PDate,Shiftstart,ShiftEnd, CumulativeActual,Efficiency,LastShiftEfficiency)
	select DISTINCT RunningPart,ShiftName,PDate,Shiftstart,ShiftEnd, CumulativeActual,0,0 from #ShiftData where ShiftType = 'CurrentShift' 

Update #FinalData 
set ShiftTarget = T1.ShiftTarget,
	CumulativeTarget = T1.CumulativeTarget
from (
	select Shiftstart,sum(Target) as ShiftTarget ,sum(CumulativeTarget) as CumulativeTarget 
	from #ShiftData where ShiftType = 'CurrentShift' group by Shiftstart
) T1 

Update #FinalData 
set Efficiency = (CumulativeActual / CumulativeTarget ) *100
where CumulativeTarget<>0

Update #FinalData 
set LastShiftTarget = T1.LastShiftTarget
from (
	select Shiftstart,sum(Target) as LastShiftTarget 
	from #ShiftData where ShiftType = 'LastShift' group by Shiftstart
) T1 

Update #FinalData 
set LastShiftActual = T1.LastShiftActual
from (
	select  distinct Shiftstart,CumulativeActual as LastShiftActual
	from #ShiftData where ShiftType = 'LastShift'
) T1

Update #FinalData 
set LastShiftEfficiency = (LastShiftActual / LastShiftTarget ) *100
where LastShiftTarget<>0

--ShiftChangeover if no records consider last component from shift
if EXISTS (SELECT * from #FinalData where (ShiftTarget = 0))
BEGIN 
 Update #FinalData 
 set
ShiftTarget = Isnull(ShiftTarget,0)+isnull((((datediff(s,Shiftstart,ShiftEnd)*T1.suboperations)/T1.MaxCycleTime)*isnull(T1.targetpercent,100) /100),0) 
from 
		(  
		 --   SELECT S.suboperations,S.MaxCycleTime,isnull(S.targetpercent,100) as targetpercent
			--from #FinalTarget T 
			--INNER JOIN  (SELECT DISTINCT ComponentId,suboperations,targetpercent,MaxCycleTime,Shiftstart,ShiftEnd from #ShiftData) S
			--ON S.ComponentId = T.Component and S.Shiftstart = T.FromTm and S.ShiftEnd = T.ToTm
			--WHERE T.BatchEnd = (SELECT MAX(BatchEnd) from #FinalTarget WHERE ShiftType = 'LastShift')
			--and ShiftType = 'LastShift'
			select DISTINCT COP.componentid,COP.SubOperations,MAX(COP.cycletime) as MaxCycleTime,COP.targetpercent from 
			(select top 1 comp from #T_autodata A order by ndtime desc)A
			inner join componentinformation C on C.InterfaceID=A.comp
			inner join componentoperationpricing COP on C.componentid=COP.componentid
			group by COP.componentid,COP.SubOperations,COP.targetpercent
		)T1 
END 

--ShiftChangeover if no records consider last component from shift
if EXISTS (SELECT * from #FinalData where (CumulativeTarget = 0))
BEGIN 
 Update #FinalData 
 set CumulativeTarget = Isnull(CumulativeTarget,0)+isnull((((datediff(s,Shiftstart,@SDateTime)*T1.suboperations)/T1.MaxCycleTime)*isnull(T1.targetpercent,100)/100),0) 
   from 
		(  
		 --   SELECT S.suboperations,S.MaxCycleTime,isnull(S.targetpercent,100) as targetpercent
			--from #FinalTarget T 
			--INNER JOIN  (SELECT DISTINCT ComponentId,suboperations,targetpercent,MaxCycleTime,Shiftstart,ShiftEnd from #ShiftData) S
			--ON S.ComponentId = T.Component and S.Shiftstart = T.FromTm and S.ShiftEnd = T.ToTm
			--WHERE T.BatchEnd = (SELECT MAX(BatchEnd) from #FinalTarget WHERE ShiftType = 'LastShift')
			--and ShiftType = 'LastShift'
			select DISTINCT COP.componentid,COP.SubOperations,MAX(COP.cycletime) as MaxCycleTime,COP.targetpercent from 
			(select top 1 comp from #T_autodata A order by ndtime desc)A
			inner join componentinformation C on C.InterfaceID=A.comp
			inner join componentoperationpricing COP on C.componentid=COP.componentid
			group by COP.componentid,COP.SubOperations,COP.targetpercent
		)T1 
END 

select ShiftName,PDate,Shiftstart,ShiftEnd,
ISNULL(round(ShiftTarget,2),0) as ShiftTarget,
ISNULL(round(CumulativeTarget,2),0) as CumulativeTarget,ISNULL(CumulativeActual,0) as CumulativeActual,
ISNULL(round(Efficiency,2),0) as Efficiency,ISNULL(round(LastShiftEfficiency,2),0) as LastShiftEfficiency, ISNULL(RunningPart,'') as RunningPart  from #FinalData

END
