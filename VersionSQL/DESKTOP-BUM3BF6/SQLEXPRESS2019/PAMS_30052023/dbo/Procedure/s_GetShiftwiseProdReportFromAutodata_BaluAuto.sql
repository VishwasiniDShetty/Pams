/****** Object:  Procedure [dbo].[s_GetShiftwiseProdReportFromAutodata_BaluAuto]    Committed by VersionSQL https://www.versionsql.com ******/

/***************************************************************************************************
Procedure Created by Anjana C V on 05-Dec-2018
-- Modified date: 08 May 2019
For BaluAuto : Get Shiftwise Production Report From Autodata  
[s_GetShiftwiseProdReportFromAutodata_BaluAuto] '2018-11-01','2018-11-2','A','PKH HBM-02'
[s_GetShiftwiseProdReportFromAutodata_BaluAuto] '2019-05-01','2019-05-30','','CNC-01'
exec s_GetShiftwiseProdReportFromAutodata_BaluAuto '2019-05-04','2019-05-04','FIRST ','CNC-01'
exec s_GetShiftwiseProductionReportFromAutodata '2019-05-04','FIRST','CNC-01','','','','2019-05-04','Shift'
**************************************************************************************************/
CREATE PROCEDURE [dbo].[s_GetShiftwiseProdReportFromAutodata_BaluAuto]
	@StartDate datetime,
	@EndDate datetime='',
	@ShiftIn nvarchar(20) = '',
	@MachineID nvarchar(50) = '',
	@PlantID NvarChar(50)=''
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

CREATE TABLE #T_autodata(
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

CREATE TABLE #ShiftTimeDetails (
	PDate datetime,
	Shift nvarchar(20),
	ShiftStart datetime,
	ShiftEnd datetime,
	Shiftid int, 
)

CREATE TABLE #Finaldata 
	(
	MachineInterface nvarchar(50) not null,
	ShftStart datetime not null,
	ShftEnd datetime not null,
	Shiftid int,
	MachineID nvarchar(50) NOT NULL,
	OperatorID Nvarchar(500) NOT NULL,
	ProductionEfficiency float DEFAULT 0,
	AvailabilityEfficiency float DEFAULT 0,
	QualityEfficiency float DEFAULT 0,
	OverallEfficiency float DEFAULT 0,
	PlannedProductionTime float,
	UtilisedTime float,
	ManagementLoss float,
	DownTime float,
	CN float,
	Sdate datetime not null,
	ShiftName nvarchar(50),
	MLDown float,
	RejCount int,
	components int,
	QuantityOk int,
    D1  float DEFAULT 0,
	D2  float DEFAULT 0,
	D3  float DEFAULT 0,
	D4 float DEFAULT 0,
	D5  float DEFAULT 0,
	D6  float DEFAULT 0,
	D7  float DEFAULT 0,
	D8  float DEFAULT 0,
	D9  float DEFAULT 0,
	D10  float DEFAULT 0,
	D11  float DEFAULT 0,
	D12  float DEFAULT 0,
	D13  float DEFAULT 0,
	--D14 float DEFAULT 0,
	NO_Data float DEFAULT 0,
	Others float DEFAULT 0,
	TotalLoss float DEFAULT 0,
	ActLoss float DEFAULT 0,
	LossErr float DEFAULT 0,
	TargetCycleTime float,
	LoadUnloadTime float,
	TargetCount float,
	RunTime float,
	ActualCycleTime float, 
	Actualloadunload float, 
	OperationCount float, 
	PartCycleTime Float
	)

	

ALTER TABLE #Finaldata
	ADD PRIMARY KEY CLUSTERED
		(   [MachineInterface],
			[ShftStart],
			[ShftEnd]
						
		) ON [PRIMARY]

ALTER TABLE #T_autodata

ADD PRIMARY KEY CLUSTERED
(
	mc,sttime ASC
)ON [PRIMARY]

--ComponentOperation level details
CREATE TABLE #Target (
	MachineID nvarchar(50) NOT NULL,
	Component nvarchar(50) NOT NULL,
	Operation nvarchar(50) NOT NULL,
	CycleTime float,
	LoadUnload float,
	PartCycleTime float,
	Avgcycletime float, 
	Avgloadunload float, 
	OperationCount float, 
	Sdate datetime not null,
	ShiftName nvarchar(50),
	ShftStart datetime not null,
	ShftEnd datetime,
	TargetCount float default 0,
	MachineInterface nvarchar(50),
	CompInterface nvarchar(50),
	OpnInterface nvarchar(50)
	--,RunTime  float default 0
)


ALTER TABLE #Target
	ADD PRIMARY KEY CLUSTERED
		(
			[Sdate],[ShftStart],
			[MachineID],
			[Component],
			[Operation]
		) ON [PRIMARY]

create table #Machcomopnopr
	(
		Machine nvarchar(50) NOT NULL,
		Machineint nvarchar(50),
		Component nvarchar(50) NOT NULL,
		CompInt nvarchar(50),
		Operation nvarchar(50) NOT NULL,
		opnInt nvarchar(50),
		Operator nvarchar(50),
		Shdate datetime not null,
		ShftName nvarchar(50),
		ShftStrt datetime not null,
		ShftND datetime not null,
		Shiftid int
	)
--temp table to store PDT's at shift level
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


Create table #Downcode
(
	Slno int identity(1,1) NOT NULL,
	Downid nvarchar(50),
	InterfaceId nvarchar(50),
)


CREATE TABLE #BatchTarget    
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

CREATE TABLE #BatchFinalTarget    
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
 Target float default 0,
 Shift nvarchar(20),
 Runtime float default 0,
 TotalAvailabletime float
)  

Insert into #Downcode(Downid,InterfaceId)
Select top 13 downid,InterfaceId from downcodeinformation where --catagory not in('Management Loss')and
SortOrder<=13 and isnull(SortOrder,0) <> 0
 order by sortorder

declare @strsql nvarchar(4000)
declare @strmachine nvarchar(255)
declare @timeformat as nvarchar(12)
Declare @StrMPlantID AS NVarchar(255)
select @strsql = ''
select @strmachine = ''
Select @StrMPlantID=''
Declare @T_ST AS Datetime 
Declare @T_ED AS Datetime 

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

declare @Targetsource nvarchar(50)
select @Targetsource=ValueInText from Shopdefaults where Parameter='TargetFrom'
declare @StartTime as datetime
declare @EndTime as datetime
declare @CurStrtTime as datetime
declare @CurEndTime as datetime
select @CurStrtTime=@StartDate
select @CurEndTime=@EndDate

while @CurStrtTime<=@EndDate
BEGIN
	INSERT #ShiftTimeDetails(Pdate, Shift, ShiftStart, ShiftEnd)
	EXEC s_GetShiftTime @CurStrtTime,@ShiftIn
	SELECT @CurStrtTime=DATEADD(DAY,1,@CurStrtTime)
END

update #ShiftTimeDetails 
set Shiftid = T.Shiftid
from  (select ShiftName,Shiftid from shiftdetails where Running = 1) T
inner join #ShiftTimeDetails S on S.Shift = T.ShiftName
--select * from #ShiftTimeDetails

delete FROM #ShiftTimeDetails where Shiftid = 3
 
Select @T_ST=min(ShiftStart) from #ShiftTimeDetails 
Select @T_ED=max(ShiftEnd) from #ShiftTimeDetails 


select @timeformat ='ss'
select @timeformat = isnull((select valueintext from cockpitdefaults where parameter='timeformat'),'ss')
if (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')
begin
select @timeformat = 'ss'
end
select @CurStrtTime=''
SELECT @CurEndTime=''
declare @CurShift nvarchar(50)
DECLARE @CurDate datetime
declare @Dateval datetime
declare @shiftstart datetime
declare @shiftend  datetime
declare @shiftnamevalue  nvarchar(20)
declare @MinLuLR  integer
set @MinLuLR=isnull((select top 1 valueinint from Shopdefaults where parameter='MinLUforLR'),0)

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


		Select @strsql=''
		select @strsql ='insert into #Machcomopnopr(Machine,MachineInt,Component,CompInt,Operation,OpnInt,Operator,Shdate,
						ShftName,ShftStrt,ShftND,ShiftId) '
		select @strsql = @strsql + 'SELECT distinct  Machineinformation.Machineid,Machineinformation.interfaceid,
						componentinformation.componentid,componentinformation.interfaceid,componentoperationpricing.operationno,
						componentoperationpricing.interfaceid,Employeeinformation.Employeeid, Pdate, Shift, ShiftStart, ShiftEnd ,ShiftId'
		select @strsql = @strsql + ' from #T_autodata autodata inner join machineinformation on machineinformation.interfaceid=autodata.mc inner join ' --ER0324 Added #T_autodata
		select @strsql = @strsql + ' componentinformation ON autodata.comp = componentinformation.InterfaceID  INNER JOIN '
		select @strsql = @strsql + ' componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID)'
		select @strsql = @strsql + ' AND (componentinformation.componentid = componentoperationpricing.componentid) '

		select @strsql = @strsql + ' and componentoperationpricing.machineid=machineinformation.machineid '

		select @strsql = @strsql + ' inner join employeeinformation on autodata.opr=employeeinformation.interfaceid'
		select @strsql = @strsql + ' Left Outer Join PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID '
		select @strsql = @strsql + ' cross join #ShiftTimeDetails where '
		select @strsql = @strsql + '(( sttime >= shiftstart and ndtime <= shiftend ) OR '
		select @strsql = @strsql + '( sttime < shiftstart and ndtime > shiftend )OR '
		select @strsql = @strsql + '( sttime < shiftstart and ndtime > shiftstart and ndtime<=shiftend )'
		select @strsql = @strsql + ' OR ( sttime >= shiftstart and ndtime > shiftend and sttime<shiftend ) ) and machineinformation.interfaceid>0 '
		select @strsql = @strsql + @strmachine+@StrMPlantID
		select @strsql = @strsql + ' order by Machineinformation.Machineid,shiftstart'
		print @strsql
		exec (@strsql)

		delete from shift_proc where SSession=@@SPID
		
		 insert into shift_proc(SSession,Machine,Mdate,Mshift,MShiftStart,MshiftEnd)
		 select distinct @@SPID,Machine,Shdate,ShftName,ShftStrt,ShftND from #Machcomopnopr order by ShftStrt asc
	  
	 -- SELECT DISTINCT Machine ,0,MachineInt,0,0,0,0,0,0,0,Shdate,
		--ShftName,ShftStrt,ShftND,ShiftId FROM #Machcomopnopr
		 
		insert INTO #PlannedDownTimesShift(StartTime,EndTime,Machine,MachineInterface,Downreason,Shiftst)
		select
		CASE When StartTime<T1.ShiftStart Then T1.ShiftStart Else StartTime End,
		case When EndTime>T1.ShiftEnd Then T1.ShiftEnd Else EndTime End,
		Machine,M.InterfaceID,
		DownReason,T1.ShiftStart
		FROM PlannedDownTimes cross join #ShiftTimeDetails T1
		inner join MachineInformation M on PlannedDownTimes.machine = M.MachineID
		WHERE PDTstatus =1 and (
		(StartTime >= T1.ShiftStart  AND EndTime <=T1.ShiftEnd)
		OR ( StartTime < T1.ShiftStart  AND EndTime <= T1.ShiftEnd AND EndTime > T1.ShiftStart )
		OR ( StartTime >= T1.ShiftStart   AND StartTime <T1.ShiftEnd AND EndTime > T1.ShiftEnd )
		OR ( StartTime < T1.ShiftStart  AND EndTime > T1.ShiftEnd) )
		and machine in (select distinct machine from #Machcomopnopr)
		ORDER BY StartTime

		Select @strsql=''
		select @strsql = 'insert into #Target (MachineID,Component,Operation,CycleTime,LoadUnload,AvgLoadUnload,AvgCycleTime,OperationCount, '
		select @strsql = @strsql + 'Sdate,ShiftName,ShftStart,ShftEnd, 	MachineInterface,CompInterface,	OpnInterface) '
		select @strsql = @strsql + ' SELECT  distinct machineinformation.machineid, componentinformation.componentid, 
		 componentoperationpricing.operationno, componentoperationpricing.machiningtime,  
		 (componentoperationpricing.cycletime - componentoperationpricing.machiningtime), 
		 Sum(case when (autodata.loadunload>=''' +convert(nvarchar(20),@MinLuLR)+ ''' )  then (autodata.loadunload) end), 
		 sum(autodata.cycletime) as Averagecycletime,
		 (CAST(Sum(autodata.partscount)AS Float)/ISNULL(ComponentOperationPricing.SubOperations,1)) as PCount ,
		 Pdate, Shift, ShiftStart, ShiftEnd ,machineinformation.interfaceid,componentinformation.interfaceid,componentoperationpricing.interfaceid
		 FROM #T_autodata autodata INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN  
		 componentinformation ON autodata.comp = componentinformation.InterfaceID  INNER JOIN 
		 componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID)
		 and componentoperationpricing.machineid=machineinformation.machineid 
		 AND (componentinformation.componentid = componentoperationpricing.componentid) 
		 Left Outer Join PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID 
		 cross join  #ShiftTimeDetails    
		 where machineinformation.interfaceid > 0 
		and (( sttime >= shiftstart and ndtime <= shiftend ) OR 
		( sttime < shiftstart and ndtime > shiftstart and ndtime<=shiftend ))
		 and autodata.datatype=1  AND (autodata.partscount > 0 ) '
		select @strsql = @strsql + @strmachine+@StrMPlantID
		select @strsql = @strsql + 'group by machineinformation.machineid, componentinformation.componentid,  componentoperationpricing.operationno, 
		 componentoperationpricing.machiningtime,ComponentOperationPricing.SubOperations,componentoperationpricing.cycletime,Pdate, Shift, ShiftStart, ShiftEnd  
		 ,machineinformation.interfaceid,componentinformation.interfaceid,componentoperationpricing.interfaceid order by  ShiftStart asc,machineinformation.machineid '
		print @strsql
		Exec(@strsql)

		Select @strsql=''
		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
		BEGIN
				
			UPDATE #Target SET OperationCount=ISNULL(OperationCount,0)- isnull(t2.PlanCt,0)
				FROM ( select T.Shiftst as intime,Machineinformation.machineid as machine,
				((CAST(Sum(ISNULL(PartsCount,1)) AS Float)/ISNULL(Componentoperationpricing.SubOperations,1))) as PlanCt, --NR0097
			 	Componentinformation.componentid as compid,componentoperationpricing.Operationno as opnno from #T_autodata autodata --ER0324 Added
				Inner jOIN #PlannedDownTimesShift T on T.MachineInterface=autodata.mc  inner join machineinformation on autodata.mc=machineinformation.Interfaceid
				Inner join componentinformation on autodata.comp=componentinformation.interfaceid inner join
				componentoperationpricing on autodata.opn=componentoperationpricing.interfaceid and
				componentinformation.componentid=componentoperationpricing.componentid  and componentoperationpricing.machineid=machineinformation.machineid
				WHERE autodata.DataType=1
				AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)
				 Group by Machineinformation.machineid,componentinformation.componentid ,componentoperationpricing.Operationno,componentoperationpricing.SubOperations,T.Shiftst
			
			) as T2 inner join #Target S on T2.machine = S.machineid  and T2.compid=S.Component and   t2.opnno=S.Operation and  t2.intime=S.ShftStart
			
		END
---------------------------------------------------------------------------------------------------
UPDATE #Target set PartCycleTime = AvgCycleTime
----------------------------------------------------------------------------------------------
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_AvgCycletime_4m_PLD')='Y' --ER0363 Added
BEGIN
	UPDATE #Target set PartCycleTime =isnull(PartCycleTime,0) - isNull(TT.PPDT ,0),
		AVGLoadUnload = isnull(AVGLoadUnload,0) - isnull(LD,0)
	FROM(
		--Production Time in PDT
	Select A.mc,A.comp,A.Opn,A.ShftStrt,A.ShftND,Sum
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
				SELECT distinct M.Machine,
				autodata.MC,autodata.comp,autodata.Opn,autodata.sttime,autodata.ndtime,autodata.msttime
				,autodata.Cycletime,M.ShftStrt,M.ShftND
				from #T_autodata autodata 
				inner join #Machcomopnopr M on M.machineint=Autodata.mc
				and autodata.comp=M.CompInt and autodata.Opn=M.opnInt
				where autodata.DataType=1 And autodata.ndtime >M.ShftStrt  AND autodata.ndtime <=M.ShftND
			)A
			CROSS jOIN PlannedDownTimes T 
			WHERE T.Machine=A.Machine AND
			((A.msttime >= T.StartTime  AND A.ndtime <=T.EndTime)
			OR ( A.msttime < T.StartTime  AND A.ndtime <= T.EndTime AND A.ndtime > T.StartTime )
			OR ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime AND A.ndtime > T.EndTime )
			OR ( A.msttime < T.StartTime  AND A.ndtime > T.EndTime) )
		group by A.mc,A.comp,A.Opn,A.ShftStrt,A.ShftND
	)
	as TT INNER JOIN #Target ON TT.mc = #Target.MachineInterface
		and TT.comp = #Target.CompInterface
			and TT.opn = #Target.OPNInterface and TT.ShftStrt=#Target.ShftStart
						and TT.ShftND= #Target.ShftEnd

	--Handle intearction between ICD and PDT for type 1 production record for the selected time period.
		UPDATE  #Target set PartCycleTime =isnull(PartCycleTime,0) + isNull(T2.IPDT ,0) 	FROM	
		(
		Select AutoData.mc,autodata.comp,autodata.Opn,T1.ShftStrt,T1.Shftnd,
		SUM(
		CASE 	
			When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
			When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
			When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
			when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		from #T_autodata autodata INNER Join 
			(Select distinct machine,mc,Sttime,NdTime,M.ShftStrt,M.Shftnd from #T_autodata autodata
				inner join #Machcomopnopr M on M.machineint=Autodata.mc
				and autodata.comp=M.CompInt and autodata.Opn=M.opnInt
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(ndtime > M.ShftStrt) AND (ndtime <= M.Shftnd)) as T1
		ON AutoData.mc=T1.mc 
		CROSS jOIN PlannedDownTimes T 
		Where AutoData.DataType=2 And T.Machine=T1.Machine
		And (( autodata.Sttime >= T1.Sttime )
		And ( autodata.ndtime <= T1.ndtime ) 
		)
		AND
		((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
		or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
		or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
		or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )))
		GROUP BY AUTODATA.mc,autodata.comp,autodata.Opn,T1.ShftStrt,T1.Shftnd
		)AS T2  INNER JOIN #Target ON T2.mc = #Target.MachineInterface
				and T2.comp = #Target.CompInterface
			and T2.opn = #Target.OPNInterface and T2.ShftStrt=#Target.ShftStart
						and T2.Shftnd= #Target.ShftEnd
	
End
----------------------------------------------------------------------------------------------
		INSERT INTO #Finaldata (
		 MachineID ,OperatorID,MachineInterface,ProductionEfficiency ,AvailabilityEfficiency ,
		OverallEfficiency ,UtilisedTime ,ManagementLoss,DownTime ,CN,Sdate,ShiftName,ShftStart,ShftEnd,Shiftid)
		/* SELECT DISTINCT Machine ,0,MachineInt,0,0,0,0,0,0,0,Shdate,
		ShftName,ShftStrt,ShftND,ShiftId FROM #Machcomopnopr 
		 */
		SELECT  DISTINCT Machine ,0,MachineInt,0,0,0,0,0,0,0,S.PDate,
		S.Shift,S.ShiftStart,S.ShiftEnd,S.ShiftId  FROM #Machcomopnopr  
		cross join  #ShiftTimeDetails S

		/*SELECT DISTINCT Machine ,0,MachineInt,0,0,0,0,0,0,0,S.PDate,
		S.Shift,S.ShiftStart,S.ShiftEnd,S.ShiftId FROM #Machcomopnopr  
		cross join  #ShiftTimeDetails S */

--------------------------------------------UtilisedTime----------------------------------------

UPDATE #Finaldata SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
from
(select  mc,
sum( case when ( (autodata.msttime>=S.ShftStart) and (autodata.ndtime<=S.ShftEnd)) 
then  (cycletime+loadunload)
		 when ((autodata.msttime<S.ShftStart)and (autodata.ndtime>S.ShftStart)and (autodata.ndtime<=S.ShftEnd)) 
		 then DateDiff(second, S.ShftStart, ndtime)
		 when ((autodata.msttime>=S.ShftStart)and (autodata.msttime<S.ShftEnd)and (autodata.ndtime>S.ShftEnd)) 
		 then DateDiff(second, mstTime, S.ShftEnd)
		 when ((autodata.msttime<S.ShftStart)and (autodata.ndtime>S.ShftEnd)) 
		 then DateDiff(second, S.ShftStart, S.ShftEnd) END
		  ) as cycle,
		  S.ShftStart as ShiftStart
from #T_autodata autodata inner join #Finaldata S on autodata.mc=S.MachineInterface --ER0324 Added
where (autodata.datatype=1) AND(( (autodata.msttime>=S.ShftStart) and (autodata.ndtime<=S.ShftEnd))
OR ((autodata.msttime<S.ShftStart) and (autodata.ndtime>S.ShftStart) and (autodata.ndtime<=S.ShftEnd))
OR ((autodata.msttime>=S.ShftStart) and (autodata.msttime<S.ShftEnd) and (autodata.ndtime>S.ShftEnd))
OR((autodata.msttime<S.ShftStart) and (autodata.ndtime>S.ShftEnd)))
group by autodata.mc,S.ShftStart
) as t2 inner join #Finaldata on t2.mc = #Finaldata.machineinterface
and t2.ShiftStart=#Finaldata.ShftStart
---------------------------------------------------------------------------------------------------
	UPDATE  #Finaldata SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
		FROM
		(Select AutoData.mc ,
		SUM(
		CASE
			When autodata.sttime <= T1.ShftStart Then datediff(s, T1.ShftStart,autodata.ndtime )
			When autodata.sttime > T1.ShftStart Then datediff(s , autodata.sttime,autodata.ndtime)
		END) as Down,t1.ShftStart as ShiftStart,T1.Sdate as Sdate
		From AutoData INNER Join
			(Select mc,Sttime,NdTime,ShftStart,ShftEnd,Sdate From AutoData
				inner join #Finaldata ST1 ON ST1.MachineInterface=Autodata.mc
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(msttime < ShftStart)And (ndtime > ShftStart) AND (ndtime <= ShftEnd)
		) as T1 on t1.mc=autodata.mc
		Where AutoData.DataType=2
		And ( autodata.Sttime > T1.Sttime )
		And ( autodata.ndtime <  T1.ndtime )
		AND ( autodata.ndtime >  T1.ShftStart )
		GROUP BY AUTODATA.mc,T1.ShftStart,T1.Sdate)AS T2 Inner Join #Finaldata on t2.mc = #Finaldata.machineinterface
		and T2.Sdate = #Finaldata.Sdate and t2.ShiftStart=#Finaldata.ShftStart
		--For Type4
	UPDATE  #Finaldata SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
		FROM
		(Select AutoData.mc ,
		SUM(CASE
			When autodata.sttime >= T1.ShftStart AND autodata.ndtime <= T1.ShftEnd Then datediff(s , autodata.sttime,autodata.ndtime)
			When autodata.sttime < T1.ShftStart And autodata.ndtime >T1.ShftStart AND autodata.ndtime<=T1.ShftEnd Then datediff(s, T1.ShftStart,autodata.ndtime )
			When autodata.sttime >= T1.ShftStart AND autodata.sttime<T1.ShftEnd AND autodata.ndtime>T1.ShftEnd Then datediff(s,autodata.sttime, T1.ShftEnd )
			When autodata.sttime<T1.ShftStart AND autodata.ndtime>T1.ShftEnd   Then datediff(s , T1.ShftStart,T1.ShftEnd)
		END) as Down,T1.ShftStart as ShiftStart,T1.Sdate as Sdate
		From AutoData INNER Join
			(Select mc,Sttime,NdTime,ShftStart,ShftEnd,Sdate From AutoData
				inner join #Finaldata ST1 ON ST1.MachineInterface =Autodata.mc
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(msttime < ShftStart)And (ndtime >ShftEnd)
			
		 ) as T1
		ON AutoData.mc=T1.mc
		Where AutoData.DataType=2
		And (T1.Sttime < autodata.sttime  )
		And ( T1.ndtime >  autodata.ndtime)
		AND (autodata.ndtime  >  T1.ShftStart)
		AND (autodata.sttime  <  T1.ShftEnd)
		GROUP BY AUTODATA.mc,T1.ShftStart,T1.Sdate
		 )AS T2 Inner Join #Finaldata on t2.mc = #Finaldata.machineinterface
		and T2.Sdate = #Finaldata.Sdate and t2.ShiftStart=#Finaldata.ShftStart
		--Type 3
		UPDATE  #Finaldata SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
		FROM
		(Select AutoData.mc ,
		SUM(CASE
			When autodata.ndtime > T1.ShftEnd Then datediff(s,autodata.sttime, T1.ShftEnd )
			When autodata.ndtime <=T1.ShftEnd Then datediff(s , autodata.sttime,autodata.ndtime)
		END) as Down,T1.ShftStart as ShiftStart,T1.Sdate as Sdate
		From AutoData INNER Join
			(Select mc,Sttime,NdTime,ShftStart,ShftEnd,Sdate From AutoData
				inner join #Finaldata ST1 ON ST1.MachineInterface =Autodata.mc
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(sttime >= ShftStart)And (ndtime >ShftEnd) and (sttime< ShftEnd)
		 ) as T1
		ON AutoData.mc=T1.mc
		Where AutoData.DataType=2
		And (T1.Sttime < autodata.sttime  )
		And ( T1.ndtime >  autodata.ndtime)
		AND (autodata.sttime  <  T1.ShftEnd)
		GROUP BY AUTODATA.mc,T1.ShftStart,T1.Sdate )AS T2 Inner Join #Finaldata on t2.mc = #Finaldata.machineinterface
		and t2.Sdate=#Finaldata.Sdate and t2.ShiftStart=#Finaldata.ShftStart
		
	UPDATE #Finaldata SET CN = isnull(CN,0) + isNull(t2.C1N1,0)
		from
		(select mc,
		  SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))*autodata.partscount) C1N1,S.Sdate as date1,S.ShftStart as ShiftStart
		   from #T_autodata autodata INNER JOIN 
		componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
		componentinformation ON autodata.comp = componentinformation.InterfaceID AND
		componentoperationpricing.componentid = componentinformation.componentid
		inner join machineinformation on machineinformation.interfaceid=autodata.mc
		and componentoperationpricing.machineid=machineinformation.machineid
		inner join (select distinct MachineInterface,ShftStart,ShftEnd,Sdate from #Finaldata) S on autodata.mc=S.MachineInterface
		  where (autodata.sttime>=S.ShftStart)
			and (autodata.ndtime<=S.ShftEnd)
			and (autodata.datatype=1)
		  group by autodata.mc,S.Sdate,S.ShftStart
		) as t2 inner join #Finaldata on t2.mc = #Finaldata.machineinterface
		and t2.date1=#Finaldata.Sdate and t2.ShiftStart=#Finaldata.ShftStart
		
		--Type 2
		UPDATE #Finaldata SET CN = isnull(CN,0) + isNull(t2.C1N1,0)
		from
		(select mc,
		  SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))*autodata.partscount) C1N1,S.Sdate as date1,S.ShftStart as ShiftStart
		   from #T_autodata autodata INNER JOIN 
		componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
		componentinformation ON autodata.comp = componentinformation.InterfaceID AND
		componentoperationpricing.componentid = componentinformation.componentid
		inner join machineinformation on machineinformation.interfaceid=autodata.mc
		and componentoperationpricing.machineid=machineinformation.machineid
		inner join (select distinct MachineInterface,ShftStart,ShftEnd,Sdate from #Finaldata) S on autodata.mc=S.MachineInterface
		where (autodata.sttime<S.ShftStart)
		  and (autodata.ndtime>S.ShftStart)
		  and (autodata.ndtime<=S.ShftEnd)
		  and (autodata.datatype=1)
		  group by autodata.mc,S.Sdate,S.ShftStart
		) as t2 inner join #Finaldata on t2.mc = #Finaldata.machineinterface
		and t2.date1=#Finaldata.Sdate and t2.ShiftStart=#Finaldata.ShftStart
 
UPDATE #Finaldata SET OperatorID= T.OperatorID
  from(
   select Machine,Shdate,ShftStrt,
   (SELECT STUFF((SELECT DISTINCT ';'  + m.Operator  
   FROM #Machcomopnopr m
	where mco.Machine= m.Machine 
	and mco.Shdate = m.Shdate
	and mco.ShftStrt = m.ShftStrt
	FOR XML PATH (''),  TYPE, ROOT).value('.', 'varchar(max)'), 1, 1, '')
 	)as OperatorID
	from #Machcomopnopr mco
    ) T inner join #Finaldata S
   on S.MachineID =T.Machine  and S.Sdate=T.Shdate and S.ShftStart=T.ShftStrt


If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
BEGIN
	
	UPDATE  #Finaldata SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.PlanDT,0)
	from( select T.ShiftSt as intime,T.Machine as machine,sum (CASE
	WHEN (autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN DateDiff(second,autodata.msttime,autodata.ndtime) 
	WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
	WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )
	WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
	END ) as PlanDT
	from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T 
	WHERE autodata.DataType=1   and T.MachineInterface=autodata.mc AND(
	(autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
	OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
	OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )
	OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime)
	)
	group by T.Machine,T.ShiftSt ) as t2 inner join #Finaldata S on t2.intime=S.ShftStart and t2.machine=S.machineId
	
      ---Add ICD's Overlapping  with PDT to UtilisedTime
	/* Fetching Down Records from Production Cycle  */
	 --Handle intearction between ICD and PDT for type 1 production record for the selected time period.
		UPDATE  #Finaldata SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)
		FROM	(
		Select T.ShiftSt as intime,AutoData.mc,
		SUM(
		CASE 	
			When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
			When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
			When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
			when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		from #T_autodata autodata INNER Join 
			(Select mc,Sttime,NdTime,S.ShftStart as StartTime from #T_autodata autodata inner join #Finaldata S on S.MachineInterface=autodata.mc
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(msttime >= S.ShftStart) AND (ndtime <= S.ShftEnd)) as T1
		ON AutoData.mc=T1.mc CROSS jOIN #PlannedDownTimesShift T
		Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc
		And (( autodata.Sttime >= T1.Sttime ) 
		And ( autodata.ndtime <= T1.ndtime ) 
		)
		AND
		((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
		or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
		or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
		or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )
		GROUP BY AUTODATA.mc,T.ShiftSt
		)AS T2  INNER JOIN #Finaldata ON
	T2.mc = #Finaldata.MachineInterface and  t2.intime=#Finaldata.ShftStart
	
	---mod 12(4)
	/* If production  Records of TYPE-2*/
	UPDATE  #Finaldata SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)
	FROM
	(Select T.ShiftSt as intime,AutoData.mc ,
	SUM(
	CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT
	from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join --ER0324 Added
		(Select mc,Sttime,NdTime,S.ShftStart as StartTime from #T_autodata autodata inner join #Finaldata S on S.MachineInterface=autodata.mc
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(msttime < S.ShftStart)And (ndtime > S.ShftStart) AND (ndtime <= S.ShftEnd)) as T1
	ON AutoData.mc=T1.mc  and T1.StartTime=T.ShiftSt
	Where AutoData.DataType=2  and T.MachineInterface=autodata.mc
	And (( autodata.Sttime > T1.Sttime )
	And ( autodata.ndtime <  T1.ndtime )
	AND ( autodata.ndtime >  T1.StartTime ))
	AND
	(( T.StartTime >= T1.StartTime )
	And ( T.StartTime <  T1.ndtime ) )
	GROUP BY AUTODATA.mc,T.ShiftSt )AS T2  INNER JOIN #Finaldata ON
	T2.mc = #Finaldata.MachineInterface and  t2.intime=#Finaldata.ShftStart

	/* If production Records of TYPE-3*/
	UPDATE  #Finaldata SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)
	FROM
	(Select T.ShiftSt as intime,AutoData.mc ,
	SUM(
	CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT
	from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join 
		(Select mc,Sttime,NdTime,S.ShftStart as StartTime,S.ShftEnd as EndTime from #T_autodata autodata inner join #Finaldata S on S.MachineInterface=autodata.mc
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(sttime >= S.ShftStart)And (ndtime > S.ShftEnd) and autodata.sttime <S.ShftEnd) as T1
	ON AutoData.mc=T1.mc and T1.StartTime=T.ShiftSt
	Where AutoData.DataType=2  and T.MachineInterface=autodata.mc
	And ((T1.Sttime < autodata.sttime  )
	And ( T1.ndtime >  autodata.ndtime)
	AND (autodata.sttime  <  T1.EndTime))
	AND
	(( T.EndTime > T1.Sttime )
	And ( T.EndTime <=T1.EndTime ) )
	GROUP BY AUTODATA.mc,T.ShiftSt)AS T2   INNER JOIN #Finaldata ON
	T2.mc = #Finaldata.MachineInterface and  t2.intime=#Finaldata.ShftStart
	
	/* If production Records of TYPE-4*/
	UPDATE  #Finaldata SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)
	FROM
	(Select T.ShiftSt as intime,AutoData.mc ,
	SUM(
	CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT
	from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join 
		(Select mc,Sttime,NdTime,S.ShftStart as StartTime,S.ShftEnd as EndTime from #T_autodata autodata inner join #Finaldata S on S.MachineInterface=autodata.mc
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(msttime < S.ShftStart)And (ndtime > S.ShftEnd)) as T1
	ON AutoData.mc=T1.mc and T1.StartTime=T.ShiftSt
	Where AutoData.DataType=2 and T.MachineInterface=autodata.mc
	And ( (T1.Sttime < autodata.sttime  )
		And ( T1.ndtime >  autodata.ndtime)
		AND (autodata.ndtime  >  T1.StartTime)
		AND (autodata.sttime  <  T1.EndTime))
	AND
	(( T.StartTime >=T1.StartTime)
	And ( T.EndTime <=T1.EndTime ) )
	GROUP BY AUTODATA.mc,T.ShiftSt)AS T2  INNER JOIN #Finaldata ON
	T2.mc = #Finaldata.MachineInterface and  t2.intime=#Finaldata.ShftStart
	
END

---Mod 12 Apply PDT for Utilized time and ICD's
---mod 12 Apply PDT for CN calculation
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	UPDATE #Finaldata SET CN = isnull(CN,0) - isNull(t2.C1N1,0)
	From
	(
		select M.Machineid as machine,T.Shiftst as initime,SUM((O.cycletime * ISNULL(A.PartsCount,1))/ISNULL(O.SubOperations,1))  C1N1
		from #T_autodata  A inner join machineinformation M on A.mc=M.interfaceid 
		Inner join componentinformation C ON A.Comp=C.interfaceid
		Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid AND O.Machineid=M.Machineid 
		CROSS jOIN #PlannedDownTimesShift T
		WHERE A.DataType=1 and T.MachineInterface=A.mc
		AND(A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)
		Group by M.Machineid,T.shiftst
	) as T2
	inner join #Finaldata S  on t2.initime=S.ShftStart  and t2.machine = S.machineid
END
---mod 12 Apply PDT for CN calculation
--mod 12
/*******************************Down Record***********************************/

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y')
BEGIN
	--Type 1
	UPDATE #Finaldata SET downtime = isnull(downtime,0) + isNull(t2.down,0)
	from
	(select mc,
		sum(loadunload) down,S.ShftStart as ShiftStart
	from #T_autodata autodata inner join #Finaldata S on autodata.mc=S.MachineInterface 
	where (autodata.msttime>=S.ShftStart)
	and (autodata.ndtime<= S.ShftEnd)
	and (autodata.datatype=2)
	group by autodata.mc,S.ShftStart
	) as t2 inner join #Finaldata on t2.mc = #Finaldata.machineinterface
	and t2.ShiftStart=#Finaldata.ShftStart
	
	-- Type 2
	UPDATE #Finaldata SET downtime = isnull(downtime,0) + isNull(t2.down,0)
	from
	(select mc,
		sum(DateDiff(second, S.ShftStart, ndtime)) down,S.ShftStart as ShiftStart
	from #T_autodata autodata inner join #Finaldata S on autodata.mc=S.MachineInterface 
	where (autodata.sttime<S.ShftStart)
	and (autodata.ndtime>S.ShftStart)
	and (autodata.ndtime<= S.ShftEnd)
	and (autodata.datatype=2)
	group by autodata.mc,S.ShftStart
	) as t2 inner join #Finaldata on t2.mc = #Finaldata.machineinterface
	and t2.ShiftStart=#Finaldata.ShftStart
	
	-- Type 3
	UPDATE #Finaldata SET downtime = isnull(downtime,0) + isNull(t2.down,0)
	from
	(select mc,
		sum(DateDiff(second, stTime,  S.ShftEnd)) down,S.ShftStart as ShiftStart
	from #T_autodata autodata inner join #Finaldata S on autodata.mc=S.MachineInterface 
	where (autodata.msttime>=S.ShftStart)
	and (autodata.sttime< S.ShftEnd)
	and (autodata.ndtime> S.ShftEnd)
	and (autodata.datatype=2)group by autodata.mc,S.Sdate,S.ShftStart
	) as t2 inner join #Finaldata on t2.mc = #Finaldata.machineinterface
	and t2.ShiftStart=#Finaldata.ShftStart

	-- Type 4
	UPDATE #Finaldata SET downtime = isnull(downtime,0) + isNull(t2.down,0)
	from
	(select mc,
		sum(DateDiff(second, S.ShftStart,  S.ShftEnd)) down,S.ShftStart as ShiftStart
	from #T_autodata autodata inner join #Finaldata S on autodata.mc=S.MachineInterface
	where autodata.msttime<S.ShftStart
	and autodata.ndtime> S.ShftEnd
	and (autodata.datatype=2)group by autodata.mc,S.Sdate,S.ShftStart
	) as t2 inner join #Finaldata on t2.mc = #Finaldata.machineinterface
	and t2.ShiftStart=#Finaldata.ShftStart
	--END: Get the Down Time
	---Management Loss-----
	-- Type 1
	UPDATE #Finaldata SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
	from
	(select      mc,
		sum(CASE
	WHEN loadunload >ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)
	ELSE loadunload
	END) loss,S.ShftStart as ShiftStart
	from #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid inner join #Finaldata S on autodata.mc=S.MachineInterface --ER0324 Added
	where (autodata.msttime>=S.ShftStart)
	and (autodata.ndtime<=S.ShftEnd)
	and (autodata.datatype=2)
	and (downcodeinformation.availeffy = 1)
	group by autodata.mc,S.ShftStart
	) as t2 inner join #Finaldata on t2.mc = #Finaldata.machineinterface
	and t2.ShiftStart=#Finaldata.ShftStart
	-- Type 2
	UPDATE #Finaldata SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
	from
	(select      mc,
		sum(CASE
	WHEN DateDiff(second, S.ShftStart, ndtime)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)
	ELSE DateDiff(second, S.ShftStart, ndtime)
	end) loss,S.ShftStart as ShiftStart
	from #T_autodata autodata 
	 INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid inner join #Finaldata S on autodata.mc=S.MachineInterface
	where (autodata.sttime<S.ShftStart)
	and (autodata.ndtime>S.ShftStart)
	and (autodata.ndtime<=S.ShftEnd)
	and (autodata.datatype=2)
	and (downcodeinformation.availeffy = 1)
	group by autodata.mc,S.Sdate,S.ShftStart
	) as t2 inner join #Finaldata on t2.mc = #Finaldata.machineinterface
	and t2.ShiftStart=#Finaldata.ShftStart
	-- Type 3
	UPDATE #Finaldata SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
	from
	(select      mc,
		sum(CASE
	WHEN DateDiff(second, stTime, S.ShftEnd)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)ELSE DateDiff(second, stTime, S.ShftEnd)
	END) loss,S.ShftStart as ShiftStart
	from #T_autodata autodata 
	INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid inner join #Finaldata S on autodata.mc=S.MachineInterface
	where (autodata.msttime>=S.ShftStart)
	and (autodata.sttime<S.ShftEnd)
	and (autodata.ndtime>S.ShftEnd)
	and (autodata.datatype=2)
	and (downcodeinformation.availeffy = 1)
	group by autodata.mc,S.ShftStart
	) as t2 inner join #Finaldata on t2.mc = #Finaldata.machineinterface
	and t2.ShiftStart=#Finaldata.ShftStart
	-- Type 4
	UPDATE #Finaldata SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
	from
	(select mc,
		sum(CASE
	WHEN DateDiff(second, S.ShftStart, S.ShftEnd)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)
	ELSE DateDiff(second, S.ShftStart, S.ShftEnd)
	END) loss,S.ShftStart as ShiftStart
	from #T_autodata autodata 
	INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid inner join #Finaldata S on autodata.mc=S.MachineInterface
	where autodata.msttime<S.ShftStart
	and autodata.ndtime>S.ShftEnd
	and (autodata.datatype=2)
	and (downcodeinformation.availeffy = 1)
	group by autodata.mc,S.ShftStart
	) as t2 inner join #Finaldata on t2.mc = #Finaldata.machineinterface
	and t2.ShiftStart=#Finaldata.ShftStart
	if (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y'
	begin
		
		UPDATE #Finaldata SET downtime = isnull(downtime,0) - isNull(t2.PldDown,0)
		from(
		select T.Shiftst  as intime,T.Machine as machine,SUM
		       (CASE
			WHEN (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN autodata.loadunload
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PldDown
		from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T
		INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID
		WHERE autodata.DataType=2  and T.MachineInterface=autodata.mc  AND(
		(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
		OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
		OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
		OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
		)
		AND DownCodeInformation.DownID=(SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')
		group by T.Machine,T.ShiftSt ) as t2 inner join #Finaldata S on t2.intime=S.ShftStart and t2.machine=S.machineId
	
	end
END

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN
	UPDATE #Finaldata SET downtime = isnull(downtime,0) + isNull(t2.down,0)
	from
	(select      mc,
		sum(case when ( (autodata.msttime>=S.ShftStart) and (autodata.ndtime<=S.ShftEnd)) then  loadunload
			 when ((autodata.sttime<S.ShftStart)and (autodata.ndtime>S.ShftStart)and (autodata.ndtime<=S.ShftEnd)) then DateDiff(second, S.ShftStart, ndtime)
			 when ((autodata.msttime>=S.ShftStart)and (autodata.msttime<S.ShftEnd)and (autodata.ndtime>S.ShftEnd)) then DateDiff(second, stTime, S.ShftEnd)
			 when ((autodata.msttime<S.ShftStart)and (autodata.ndtime>S.ShftEnd)) then DateDiff(second, S.ShftStart, S.ShftEnd) END ) as down,S.ShftStart as ShiftStart
	   from #T_autodata autodata 
	   inner join #Finaldata S on autodata.mc=S.MachineInterface
	   inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
	where (autodata.datatype=2) AND(( (autodata.msttime>=S.ShftStart) and (autodata.ndtime<=S.ShftEnd))
	      OR ((autodata.msttime<S.ShftStart)and (autodata.ndtime>S.ShftStart)and (autodata.ndtime<=S.ShftEnd))
	      OR ((autodata.msttime>=S.ShftStart)and (autodata.msttime<S.ShftEnd)and (autodata.ndtime>S.ShftEnd))
	      OR((autodata.msttime<S.ShftStart)and (autodata.ndtime>S.ShftEnd))) AND (downcodeinformation.availeffy = 0)
	      group by autodata.mc,S.ShftStart
	) as t2 inner join #Finaldata on t2.mc = #Finaldata.machineinterface
	and t2.ShiftStart=#Finaldata.ShftStart
	
	UPDATE #Finaldata SET downtime = isnull(downtime,0) - isNull(t2.PldDown,0)
	from(
		select T.Shiftst  as intime,T.Machine as machine,SUM
		       (CASE
			WHEN (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN autodata.loadunload
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PldDown
		from #T_autodata autodata 
		CROSS jOIN #PlannedDownTimesShift T
		INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID
		WHERE autodata.DataType=2  and T.MachineInterface=autodata.mc  AND(
		(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
		OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
		OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
		OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
		)
		AND (downcodeinformation.availeffy = 0)
		group by T.Machine,T.ShiftSt ) as t2 inner join #Finaldata S on t2.intime=S.ShftStart and t2.machine=S.machineId
	
	
	UPDATE #Finaldata SET ManagementLoss = isnull(ManagementLoss,0)+ isNull(t4.Mloss,0),MLDown=isNull(MLDown,0)+isNull(t4.Dloss,0)
	from
	(select T3.mc,T3.StrtShft,sum(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss from
	 (
	select   t1.id,T1.mc,T1.Threshold,T1.StartShift as StrtShft,
	case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0) > 0
	then DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)- isnull(T1.Threshold ,0)
	else 0 End  as Dloss,
	case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0) > 0
	then isnull(T1.Threshold,0)
	else DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0) End  as Mloss
	 from
	
	(   select id,mc,comp,opn,opr,D.threshold,S.ShftStart as StartShift,
		case when autodata.sttime<S.ShftStart then S.ShftStart else sttime END as sttime,
	       	case when ndtime>S.ShftEnd then S.ShftEnd else ndtime END as ndtime
		from #T_autodata autodata 
		inner join downcodeinformation D
		on autodata.dcode=D.interfaceid inner join #Finaldata S on autodata.mc=S.MachineInterface
		where autodata.datatype=2 AND
		(
		(autodata.msttime>=S.ShftStart  and  autodata.ndtime<=S.ShftEnd)
		OR (autodata.sttime<S.ShftStart and  autodata.ndtime>S.ShftStart and autodata.ndtime<=S.ShftEnd)
		OR (autodata.msttime>=S.ShftStart  and autodata.sttime<S.ShftEnd  and autodata.ndtime>S.ShftEnd)
		OR (autodata.msttime<S.ShftStart and autodata.ndtime>S.ShftEnd )
		) AND (D.availeffy = 1)) as T1 	
	left outer join
	(SELECT T.Shiftst  as intime, autodata.id,
		       sum(CASE
			WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PPDT
		from #T_autodata autodata 
		CROSS jOIN #PlannedDownTimesShift T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		WHERE autodata.DataType=2 and T.MachineInterface=autodata.mc AND
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)
			 AND (downcodeinformation.availeffy = 1) group by autodata.id,T.Shiftst ) as T2 on T1.id=T2.id  and T1.StartShift=T2.intime ) as T3  group by T3.mc,T3.StrtShft
	) as t4 inner join #Finaldata S on t4.StrtShft=S.ShftStart and t4.mc=S.MachineInterface
	UPDATE #Finaldata  set downtime = isnull(downtime,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)
	
END
---------------------------------------------------------------------------
select * from #downcode
declare @i as nvarchar(10)
declare @colName as nvarchar(50)
Select @i=1
print 'End of  update #Target & Start of update Down ' + convert(nvarchar(20),getdate(),120);

/*
SELECT @strsql = 'INSERT INTO #DownComponent(startdate,enddate,StartDay,MachineID,machineinterface,D1,D2,D3,D4,D5,D6,D7,D8,D9,D10,D11,D12,D13,D14) ' 
SELECT @strsql = @strsql + 'SELECT DISTINCT ShftStart,ShftEnd,Sdate,MachineID,MachineInterface,0,0,0,0,0,0,0,0,0,0,0,0,0,0 FROM #Finaldata'
print @strsql
exec(@strsql) 
*/

while @i <=13
Begin
 Select @ColName = Case when @i=1 then 'D1'
						when @i=2 then 'D2'
						when @i=3 then 'D3'
						when @i=4 then 'D4'
						when @i=5 then 'D5'
						when @i=6 then 'D6'
						when @i=7 then 'D7'
						when @i=8 then 'D8'
						when @i=9 then 'D9'
						when @i=10 then 'D10'
						when @i=11 then 'D11'
						when @i=12 then 'D12'
						when @i=13 then 'D13'
						--when @i=14 then 'D14'
						END

	 ---Get the down times which are not of type Management Loss  
	 Select @strsql = ''
	 Select @strsql = @strsql + ' UPDATE  #Finaldata SET ' + @ColName + ' = isnull(' + @ColName + ',0) + isNull(t2.down,0)  
	 from  
	 (select  F.ShftStart,F.ShftEnd,F.machineinterface,
	  sum (CASE  
		WHEN (autodata.msttime >= F.ShftStart  AND autodata.ndtime <=F.ShftEnd)  THEN autodata.loadunload  
		WHEN ( autodata.msttime < F.ShftStart  AND autodata.ndtime <= F.ShftEnd  AND autodata.ndtime > F.ShftStart ) 
		THEN DateDiff(second,F.ShftStart,autodata.ndtime)  
		WHEN ( autodata.msttime >= F.ShftStart   AND autodata.msttime <F.ShftEnd  AND autodata.ndtime > F.ShftEnd  ) 
		THEN DateDiff(second,autodata.msttime,F.ShftEnd )  
		WHEN ( autodata.msttime < F.ShftStart  AND autodata.ndtime > F.ShftEnd ) THEN DateDiff(second,F.ShftStart,F.ShftEnd )  
		END ) as down  
		from #T_autodata autodata   
		inner join  #Finaldata F on autodata.mc = F.Machineinterface 
		inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid 
		inner join #Downcode on #Downcode.downid= downcodeinformation.downid
		where (autodata.datatype=''2'') AND  #Downcode.Slno= ' + @i + ' and 
		(( (autodata.msttime>=F.ShftStart) and (autodata.ndtime<=F.ShftEnd))  
		   OR ((autodata.msttime<F.ShftStart) and (autodata.ndtime>F.ShftStart) and (autodata.ndtime<=F.ShftEnd))  
		   OR ((autodata.msttime>=F.ShftStart) and (autodata.msttime<F.ShftEnd) and (autodata.ndtime>F.ShftEnd))  
		   OR((autodata.msttime<F.ShftStart) and (autodata.ndtime>F.ShftEnd))) 
		   group by F.ShftStart,F.ShftEnd,F.machineinterface
	 ) as t2 Inner Join #Finaldata on t2.machineinterface = #Finaldata.machineinterface   
	  and t2.ShftStart=#Finaldata.ShftStart
	  and t2.ShftEnd=#Finaldata.ShftEnd'

     print @strsql
	 exec(@strsql) 

	 	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
			BEGIN   
				Select @strsql = '' 
				Select @strsql = @strsql + 'UPDATE  #Finaldata SET ' + @ColName + ' = isnull(' + @ColName + ',0) - isNull(T2.PPDT ,0)  
				FROM(  
				SELECT  F.ShftStart,F.ShftEnd,F.machineinterface,
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
				INNER JOIN #Finaldata F on F.machineinterface=Autodata.mc
				inner join #Downcode on #Downcode.downid= downcodeinformation.downid
				WHERE autodata.DataType=''2'' AND T.MachineInterface=autodata.mc 
				--AND (downcodeinformation.availeffy = ''0'') 
				and #Downcode.Slno= ' + @i + '  
				AND  
				((autodata.sttime >= F.ShftStart  AND autodata.ndtime <=F.ShftEnd)  
				OR ( autodata.sttime < F.ShftStart  AND autodata.ndtime <= F.ShftEnd AND autodata.ndtime > F.ShftStart )  
				OR ( autodata.sttime >= F.ShftStart   AND autodata.sttime <F.ShftEnd AND autodata.ndtime > F.ShftEnd )  
				OR ( autodata.sttime < F.ShftStart  AND autodata.ndtime > F.ShftEnd))  
				AND  
				((autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
				OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
				OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )  
				OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )   
				AND  
				((F.ShftStart >= T.StartTime  AND F.ShftEnd <=T.EndTime)  
				OR ( F.ShftStart < T.StartTime  AND F.ShftEnd <= T.EndTime AND F.ShftEnd > T.StartTime )  
				OR ( F.ShftStart >= T.StartTime   AND F.ShftStart <T.EndTime AND F.ShftEnd > T.EndTime )  
				OR ( F.ShftStart < T.StartTime  AND F.ShftEnd > T.EndTime) )   
				group  by F.ShftStart,F.ShftEnd,F.machineinterface
				)AS T2  Inner Join #Finaldata on t2.machineinterface = #Finaldata.machineinterface   
				and t2.ShftStart=#Finaldata.ShftStart and t2.ShftEnd=#Finaldata.ShftEnd  '
				print @strsql
				exec(@Strsql)
			END

	 select @i  =  @i + 1
	 END
------------------------------------------------------------------------------
UPDATE  #Finaldata SET NO_Data = isnull(NO_Data,0) + isNull(t2.down,0)  
from  
(select  F.ShftStart,F.ShftEnd,F.machineinterface,
sum (CASE  
WHEN (autodata.msttime >= F.ShftStart  AND autodata.ndtime <=F.ShftEnd)  THEN autodata.loadunload  
WHEN ( autodata.msttime < F.ShftStart  AND autodata.ndtime <= F.ShftEnd  AND autodata.ndtime > F.ShftStart ) 
THEN DateDiff(second,F.ShftStart,autodata.ndtime)  
WHEN ( autodata.msttime >= F.ShftStart   AND autodata.msttime <F.ShftEnd  AND autodata.ndtime > F.ShftEnd  ) 
THEN DateDiff(second,autodata.msttime,F.ShftEnd )  
WHEN ( autodata.msttime < F.ShftStart  AND autodata.ndtime > F.ShftEnd ) THEN DateDiff(second,F.ShftStart,F.ShftEnd )  
END ) as down  
from #T_autodata autodata   
inner join  #Finaldata F on autodata.mc = F.Machineinterface 
inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid 
where (autodata.datatype='2') AND  
(( (autodata.msttime>=F.ShftStart) and (autodata.ndtime<=F.ShftEnd))  
OR ((autodata.msttime<F.ShftStart)and (autodata.ndtime>F.ShftStart)and (autodata.ndtime<=F.ShftEnd))  
OR ((autodata.msttime>=F.ShftStart)and (autodata.msttime<F.ShftEnd)and (autodata.ndtime>F.ShftEnd))  
OR((autodata.msttime<F.ShftStart)and (autodata.ndtime>F.ShftEnd))) 
and downcodeinformation.downid ='NO_DATA'
group by F.ShftStart,F.ShftEnd,F.machineinterface
) as t2 Inner Join #Finaldata on t2.machineinterface = #Finaldata.machineinterface 
and t2.ShftStart=#Finaldata.ShftStart
and t2.ShftEnd=#Finaldata.ShftEnd

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
BEGIN 
  UPDATE  #Finaldata SET NO_Data = isnull(NO_Data,0) - isNull(T2.PPDT ,0)  
				FROM(  
				SELECT  F.ShftStart,F.ShftEnd,F.machineinterface,
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
				INNER JOIN #Target F on F.machineinterface=Autodata.mc
				WHERE autodata.DataType='2' AND T.MachineInterface=autodata.mc 
				--AND (downcodeinformation.availeffy = '0') 
				and downcodeinformation.downid ='NO_DATA'
				AND  
				((autodata.sttime >= F.ShftStart  AND autodata.ndtime <=F.ShftEnd)  
				OR ( autodata.sttime < F.ShftStart  AND autodata.ndtime <= F.ShftEnd AND autodata.ndtime > F.ShftStart )  
				OR ( autodata.sttime >= F.ShftStart   AND autodata.sttime <F.ShftEnd AND autodata.ndtime > F.ShftEnd )  
				OR ( autodata.sttime < F.ShftStart  AND autodata.ndtime > F.ShftEnd))  
				AND  
				((autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
				OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
				OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )  
				OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )   
				AND  
				((F.ShftStart >= T.StartTime  AND F.ShftEnd <=T.EndTime)  
				OR ( F.ShftStart < T.StartTime  AND F.ShftEnd <= T.EndTime AND F.ShftEnd > T.StartTime )  
				OR ( F.ShftStart >= T.StartTime   AND F.ShftStart <T.EndTime AND F.ShftEnd > T.EndTime )  
				OR ( F.ShftStart < T.StartTime  AND F.ShftEnd > T.EndTime) )   
				group  by F.ShftStart,F.ShftEnd,F.machineinterface
				)AS T2  Inner Join #Finaldata on t2.machineinterface = #Finaldata.machineinterface   
				and t2.ShftStart=#Finaldata.ShftStart and t2.ShftEnd=#Finaldata.ShftEnd  

END
------------------------------------------------------------------------------
UPDATE  #Finaldata SET Others = isnull(Others,0) + isNull(t2.down,0)  
from  
(select  F.ShftStart,F.ShftEnd,F.machineinterface,
sum (CASE  
WHEN (autodata.msttime >= F.ShftStart  AND autodata.ndtime <=F.ShftEnd)  THEN autodata.loadunload  
WHEN ( autodata.msttime < F.ShftStart  AND autodata.ndtime <= F.ShftEnd  AND autodata.ndtime > F.ShftStart ) 
THEN DateDiff(second,F.ShftStart,autodata.ndtime)  
WHEN ( autodata.msttime >= F.ShftStart   AND autodata.msttime <F.ShftEnd  AND autodata.ndtime > F.ShftEnd  ) 
THEN DateDiff(second,autodata.msttime,F.ShftEnd )  
WHEN ( autodata.msttime < F.ShftStart  AND autodata.ndtime > F.ShftEnd ) THEN DateDiff(second,F.ShftStart,F.ShftEnd )  
END ) as down  
from #T_autodata autodata   
inner join  #Finaldata F on autodata.mc = F.Machineinterface 
inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid 
where (autodata.datatype='2') AND  
(( (autodata.msttime>=F.ShftStart) and (autodata.ndtime<=F.ShftEnd))  
OR ((autodata.msttime<F.ShftStart)and (autodata.ndtime>F.ShftStart)and (autodata.ndtime<=F.ShftEnd))  
OR ((autodata.msttime>=F.ShftStart)and (autodata.msttime<F.ShftEnd)and (autodata.ndtime>F.ShftEnd))  
OR((autodata.msttime<F.ShftStart)and (autodata.ndtime>F.ShftEnd))) 
and downcodeinformation.downid NOT IN (SELECT downid FROM  #Downcode ) 
and downcodeinformation.downid <> 'NO_DATA'
group by F.ShftStart,F.ShftEnd,F.machineinterface
) as t2 Inner Join #Finaldata on t2.machineinterface = #Finaldata.machineinterface 
and t2.ShftStart=#Finaldata.ShftStart
and t2.ShftEnd=#Finaldata.ShftEnd

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
BEGIN 
  UPDATE  #Finaldata SET Others = isnull(Others,0) - isNull(T2.PPDT ,0)  
				FROM(  
				SELECT  F.ShftStart,F.ShftEnd,F.machineinterface,
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
				INNER JOIN #Target F on F.machineinterface=Autodata.mc
				WHERE autodata.DataType='2' AND T.MachineInterface=autodata.mc 
				--AND (downcodeinformation.availeffy = '0') 
				and downcodeinformation.downid NOT IN (SELECT downid FROM  #Downcode ) 
				and downcodeinformation.downid <> 'NO_DATA'
				AND  
				((autodata.sttime >= F.ShftStart  AND autodata.ndtime <=F.ShftEnd)  
				OR ( autodata.sttime < F.ShftStart  AND autodata.ndtime <= F.ShftEnd AND autodata.ndtime > F.ShftStart )  
				OR ( autodata.sttime >= F.ShftStart   AND autodata.sttime <F.ShftEnd AND autodata.ndtime > F.ShftEnd )  
				OR ( autodata.sttime < F.ShftStart  AND autodata.ndtime > F.ShftEnd))  
				AND  
				((autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
				OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
				OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )  
				OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )   
				AND  
				((F.ShftStart >= T.StartTime  AND F.ShftEnd <=T.EndTime)  
				OR ( F.ShftStart < T.StartTime  AND F.ShftEnd <= T.EndTime AND F.ShftEnd > T.StartTime )  
				OR ( F.ShftStart >= T.StartTime   AND F.ShftStart <T.EndTime AND F.ShftEnd > T.EndTime )  
				OR ( F.ShftStart < T.StartTime  AND F.ShftEnd > T.EndTime) )   
				group  by F.ShftStart,F.ShftEnd,F.machineinterface
				)AS T2  Inner Join #Finaldata on t2.machineinterface = #Finaldata.machineinterface   
				and t2.ShftStart=#Finaldata.ShftStart and t2.ShftEnd=#Finaldata.ShftEnd  

END
------------------------------------------------------------------------------
--------------------------------Part Count------------------------------------
UPDATE #Finaldata SET components = ISNULL(components,0) + ISNULL(t2.comp,0)  
From  
(  
	Select mc,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp,T1.ShftStart  
     From 
	 ( select mc,SUM(autodata.partscount)AS OrginalCount,comp,opn, ShftStart  as ShftStart
      from #T_autodata autodata 
      inner join  #Finaldata F on autodata.mc = F.Machineinterface 
      where (autodata.ndtime>ShftStart) and (autodata.ndtime<=ShftEnd) and (autodata.datatype=1)  
      Group By mc,comp,opn ,ShftStart
     ) as T1  
 Inner join componentinformation C on T1.Comp = C.interfaceid  
 Inner join ComponentOperationPricing O ON  T1.Opn = O.interfaceid and C.Componentid=O.componentid  
 inner join machineinformation on machineinformation.machineid =O.machineid  
 and T1.mc=machineinformation.interfaceid  

 GROUP BY mc , T1.ShftStart 
) As T2 Inner join #Finaldata on T2.mc = #Finaldata.machineinterface  
and  T2.ShftStart = #Finaldata.ShftStart  
  
--Mod 4 Apply PDT for calculation of Count  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
BEGIN  
 UPDATE #Finaldata SET components = ISNULL(components,0) - ISNULL(T2.comp,0)
  from(  

  select mc,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp , T1.ShiftSt
   From ( 
   select mc,Sum(ISNULL(PartsCount,1))AS OrginalCount,comp,opn,T.ShiftSt as ShiftSt
   from #T_autodata autodata 
   inner join  #Finaldata F on autodata.mc = F.Machineinterface 
   CROSS JOIN #PlannedDownTimesShift T  
   WHERE autodata.DataType=1 And T.MachineInterface = autodata.mc  
   AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)  
   AND (autodata.ndtime > ShftStart  AND autodata.ndtime <=ShftEnd)  
      Group by mc,comp,opn ,T.ShiftSt
  ) as T1  
 Inner join Machineinformation M on M.interfaceID = T1.mc  
 Inner join componentinformation C on T1.Comp=C.interfaceid  
 Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineID = M.MachineID  
 GROUP BY MC , T1.ShiftSt
 ) as T2 inner join #Finaldata on T2.mc = #Finaldata.machineinterface  
 and  T2.ShiftSt = #Finaldata.ShftStart 
END  
--Mod 4  

-----SV
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='N'  
BEGIN  
 UPDATE #Finaldata SET components = ISNULL(components,0) - ISNULL(T2.comp,0) from(  
  select mc,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp,T1.ShiftSt From (
   select mc,Sum(ISNULL(PartsCount,1))AS OrginalCount,comp,opn,T.ShiftSt as ShiftSt
   from #T_autodata autodata 
   inner join  #Finaldata F on autodata.mc = F.Machineinterface 
   CROSS JOIN #PlannedDownTimesShift T  
   WHERE autodata.DataType=1 And T.MachineInterface = autodata.mc  
   AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)  
   AND (autodata.ndtime > ShftStart  AND autodata.ndtime <=ShftEnd)  
      Group by mc,comp,opn ,T.ShiftSt
  ) as T1  
 Inner join Machineinformation M on M.interfaceID = T1.mc  
 Inner join componentinformation C on T1.Comp=C.interfaceid  
 Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineID = M.MachineID  
 GROUP BY MC ,T1.ShiftSt 
 ) as T2 inner join #Finaldata on T2.mc = #Finaldata.machineinterface  
  and  T2.ShiftSt = #Finaldata.ShftStart 
END  
---------------------------------Rejected Part-----------------------------------
Update #Finaldata set RejCount = isnull(RejCount,0) + isnull(T1.RejQty,0)
From
( Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid,#Finaldata.ShftStart 
 from AutodataRejections A
inner join Machineinformation M on A.mc=M.interfaceid
inner join #Finaldata on #Finaldata.machineid=M.machineid 
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
where A.CreatedTS>=ShftStart and A.CreatedTS<ShftEnd and A.flag = 'Rejection'
and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000'
group by A.mc,M.Machineid,#Finaldata.ShftStart 
)T1 inner join #Finaldata B on B.Machineid=T1.Machineid and B.ShftStart =T1.ShftStart

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	Update #Finaldata set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from
	(Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid,#Finaldata.ShftStart from AutodataRejections A
	inner join Machineinformation M on A.mc=M.interfaceid
	inner join #Finaldata on #Finaldata.machineid=M.machineid 
	inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
	Cross join Planneddowntimes P
	where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid 
	and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000' and
	A.CreatedTS>=ShftStart and A.CreatedTS<ShftEnd And
	A.CreatedTS>=P.Starttime and A.CreatedTS<P.endtime
	group by A.mc,M.Machineid,#Finaldata.ShftStart)T1 inner join #Finaldata B on B.Machineid=T1.Machineid and B.ShftStart =T1.ShftStart 
END

Update #Finaldata set RejCount = isnull(RejCount,0) + isnull(T1.RejQty,0)
From
( Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid,#Finaldata.ShftStart  from AutodataRejections A
inner join Machineinformation M on A.mc=M.interfaceid
inner join #Finaldata on #Finaldata.machineid=M.machineid 
and convert(nvarchar(10),(A.RejDate),126)=#Finaldata.Sdate and A.RejShift=#Finaldata.Shiftid 
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
where A.flag = 'Rejection' and A.Rejshift in (#Finaldata.Shiftid) and convert(nvarchar(10),(A.RejDate),126) in (#Finaldata.Sdate) and  --DR0333
Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
group by A.mc,M.Machineid,#Finaldata.ShftStart
)T1 inner join #Finaldata B on B.Machineid=T1.Machineid and B.ShftStart =T1.ShftStart 

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	Update #Finaldata set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from
	(Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid,#Finaldata.ShftStart  from AutodataRejections A
	inner join Machineinformation M on A.mc=M.interfaceid
	inner join #Finaldata on #Finaldata.machineid=M.machineid 
	and convert(nvarchar(10),(A.RejDate),126)=#Finaldata.Sdate and A.RejShift=#Finaldata.Shiftid 
	inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
	Cross join Planneddowntimes P
	where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid and
	A.Rejshift in (#Finaldata.Shiftid) and convert(nvarchar(10),(A.RejDate),126) in (#Finaldata.Sdate) and --DR0333
	Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
	and P.starttime>=#Finaldata.ShftStart and P.Endtime<=#Finaldata.ShftEnd
	group by A.mc,M.Machineid,#Finaldata.ShftStart
	)T1 inner join #Finaldata B on B.Machineid=T1.Machineid and B.ShftStart =T1.ShftStart 
END

---------------------------------------------------------------------------------------
Select @strsql=''   
	Select @strsql= 'insert into #BatchTarget(MachineID,machineinterface,Component,Compinterface,Operation,Opninterface,  
	msttime,ndtime,FromTm,Totm,batchid,autodataid,stdtime,Shift)'  
	select @strsql = @strsql + ' SELECT machineinformation.machineid, machineinformation.interfaceid,C.componentid, C.interfaceid,  
	O.operationno, O.interfaceid, 
	Case when autodata.msttime< T.ShiftStart then T.ShiftStart else autodata.msttime end,   
	Case when autodata.ndtime> T.ShiftEnd then T.ShiftEnd else autodata.ndtime end,  
	T.ShiftStart,T.ShiftEnd,0,autodata.id,O.Cycletime,T.shift FROM #T_autodata  autodata  
	INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID   
	INNER JOIN componentinformation C ON autodata.comp = C.InterfaceID    
	INNER JOIN componentoperationpricing O ON autodata.opn = O.InterfaceID  
	AND c.componentid = O.componentid and O.machineid=machineinformation.machineid   
	Left Outer Join downcodeinformation DI on DI.interfaceid=autodata.dcode  
	Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid   
	Cross join #ShiftTimeDetails T  
	WHERE ((autodata.msttime >= T.ShiftStart  AND autodata.ndtime <= T.ShiftEnd)  
	OR ( autodata.msttime < T.ShiftStart  AND autodata.ndtime <= T.ShiftEnd AND autodata.ndtime >T.ShiftStart )  
	OR ( autodata.msttime >= T.ShiftStart AND autodata.msttime <T.ShiftEnd AND autodata.ndtime > T.ShiftEnd)  
	OR ( autodata.msttime < T.ShiftStart AND autodata.ndtime > T.ShiftEnd))'  
	select @strsql = @strsql + @strmachine + @StrMPlantID
	select @strsql = @strsql + ' order by autodata.msttime'  
	print @strsql  
	exec (@strsql)  

insert into #BatchFinalTarget (MachineID,Component,operation,Operator,machineinterface,Compinterface,Opninterface,Oprinterface,BatchStart,BatchEnd,
	FromTm,ToTm,stdtime,shift,batchid,Target,runtime)
	select MachineID,Component,operation,Operator,machineinterface,Compinterface,Opninterface,Oprinterface,min(msttime),max(ndtime),
	FromTm,ToTm,stdtime,shift,batchid,0,datediff(s,min(msttime),max(ndtime))
	from
	(
	select MachineID,Component,operation,Operator,machineinterface,Compinterface,Opninterface,Oprinterface,msttime,ndtime,FromTm,ToTm,stdtime,shift,
	RANK() OVER (
	  PARTITION BY t.machineid
	  order by t.machineid, t.msttime
	) -
	RANK() OVER (
	  PARTITION BY  t.machineid, t.component, t.operation, t.operator, t.fromtm 
	  order by t.machineid, t.fromtm, t.msttime
	) AS batchid
	from #BatchTarget t 
	) tt
	group by MachineID,Component,operation,Operator,machineinterface,Compinterface,Opninterface,Oprinterface,batchid,FromTm,ToTm,stdtime,shift 
	order by tt.batchid


If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')<>'N'    
BEGIN    

   Update #BatchFinalTarget set Runtime=Isnull(Runtime,0) - Isnull(T3.pdt,0)     
	from (    
	Select t2.machineinterface,T2.Machine,T2.BatchStart,T2.BatchEnd,T2.Fromtm,sum(datediff(ss,T2.StartTimepdt,t2.EndTimepdt))as pdt    
	from    
	(    
	Select T1.machineinterface,T1.Compinterface,T1.Opninterface,T1.BatchStart,T1.BatchEnd,T1.FromTm,Pdt.machine,    
	Case when  T1.BatchStart <= pdt.StartTime then pdt.StartTime else T1.BatchStart End as StartTimepdt,    
	Case when  T1.BatchEnd >= pdt.EndTime then pdt.EndTime else T1.BatchEnd End as EndTimepdt    
	from #BatchFinalTarget T1    
	inner join #PlannedDownTimesShift pdt on t1.machineid=Pdt.machine    
	where     
	((pdt.StartTime >= t1.BatchStart and pdt.EndTime <= t1.BatchEnd)or    
	(pdt.StartTime < t1.BatchStart and pdt.EndTime > t1.BatchStart and pdt.EndTime <=t1.BatchEnd)or    
	(pdt.StartTime >= t1.BatchStart and pdt.StartTime <t1.BatchEnd and pdt.EndTime >t1.BatchEnd) or    
	(pdt.StartTime <  t1.BatchStart and pdt.EndTime >t1.BatchEnd))    
	)T2 group by  t2.machineinterface,T2.Machine,T2.BatchStart,T2.BatchEnd,T2.Fromtm    
	) T3 inner join #BatchFinalTarget T on T.machineinterface=T3.machineinterface and T.BatchStart=T3.BatchStart and  T.BatchEnd=T3.BatchEnd and T.Fromtm=T3.Fromtm    

END   
  
	Update #BatchFinalTarget set Target = Isnull(Target,0) + isnull(T2.targetcount,0) from     
		(    
		Select T.machineinterface,T.Compinterface,T.Opninterface,T.FromTm,T.BatchStart,T.BatchEnd,
		sum(((T.Runtime*CO.suboperations)/CO.cycletime)*isnull(CO.targetpercent,100) /100) as targetcount    
		from #BatchFinalTarget T     
		inner join machineinformation M on M.Interfaceid=T.machineinterface    
		inner join componentinformation C on C.interfaceid=T.Compinterface    
		inner join componentoperationpricing CO on M.machineid=co.machineid and c.componentid=Co.componentid    
		and Co.interfaceid=T.Opninterface    
		group by T.FromTm,T.BatchStart,T.BatchEnd,T.machineinterface,T.Compinterface,T.Opninterface   
		)T2 Inner Join #BatchFinalTarget on t2.machineinterface = #BatchFinalTarget.machineinterface and  
		t2.compinterface = #BatchFinalTarget.compinterface and t2.opninterface = #BatchFinalTarget.opninterface 
		and #BatchFinalTarget.BatchStart=T2.BatchStart and  #BatchFinalTarget.BatchEnd=T2.BatchEnd and #BatchFinalTarget.Fromtm=T2.Fromtm
---------------------------------------------------------------------------
update #Finaldata
	set TargetCount = t1.Target,
	RunTime = t1.RunTime
	from 
	(
	select machineinterface,--Compinterface,Opninterface,
	shift,FromTm, 
	FLOOR(sum(isnull(Target,0))) as Target,
	sum(isnull(Runtime,0)) as Runtime from #BatchFinalTarget
	group by machineinterface,--Compinterface,Opninterface,
	shift,FromTm 
	) as t1
	inner join #Finaldata s  on t1.machineinterface = s.machineinterface   
	--and t1.compinterface = s.compinterface and t1.opninterface = s.opninterface  
	and t1.shift = s.ShiftName and t1.FromTm =s.ShftStart
-----------------------------------------------------------------------------------------
UPDATE #Finaldata SET PlannedProductionTime = DateDiff(second,ShftStart,shftend) 
---------------------------------------------------------------------------------------
UPDATE #Finaldata SET QualityEfficiency= ISNULL(QualityEfficiency,0) + IsNull(T1.QE,0)   
FROM(Select MachineID,  ShftStart,
CAST((Sum(Components))As Float)/CAST((Sum(IsNull(Components,0))+Sum(IsNull(RejCount,0))) AS Float)As QE  
From #Finaldata Where Components<>0 Group By MachineID ,ShftStart
)AS T1 Inner Join #Finaldata ON  #Finaldata.MachineID=T1.MachineID  
and #Finaldata.ShftStart =T1.ShftStart
---------------------------------------------------------------------------
UPDATE #Finaldata
SET TotalLoss= ((D1+D2+D3+D4+D5+D6+D7+D8+D9+D10+D11+D12+D13) + NO_Data + Others ),
	QuantityOk = IsNull(Components,0) - IsNull(RejCount,0) 

UPDATE #Finaldata SET ActLoss = TotalLoss - NO_Data
UPDATE #Finaldata SET LossErr = TotalLoss - ActLoss
--------------------------------------------------------------------

	UPDATE #Finaldata
	SET ProductionEfficiency = (CN/UtilisedTime) ,
		AvailabilityEfficiency = (UtilisedTime)/(UtilisedTime + DownTime - ManagementLoss)
	WHERE UtilisedTime <> 0

	UPDATE #Finaldata
	SET  
		OverAllEfficiency = (ProductionEfficiency * AvailabilityEfficiency * QualityEfficiency)*100,
		ProductionEfficiency = ProductionEfficiency * 100 ,
		AvailabilityEfficiency = AvailabilityEfficiency * 100,
		QualityEfficiency = QualityEfficiency*100   
-------------------------------------------------------

UPDATE #Finaldata
set TargetCycleTime = S.CycleTime,
 LoadUnloadTime = S.LoadUnload ,
 --ActualCycleTime = S.ActualCycleTime,
 --ActualLoadUnload = S.ActualLoadUnload ,
 OperationCount = S. OperationCount,
 PartCycleTime = S.PartCycleTime
 from 
 (
 select MachineID,Sdate,ShiftName, sum(CycleTime) CycleTime, SUM(LoadUnload) LoadUnload,
 --SUM(AvgCycleTime) ActualCycleTime, 
  --AVG(AvgLoadUnload)/SUM(OperationCount) ActualLoadUnload,
 SUM(OperationCount) OperationCount,
 AVG(PartCycleTime)/SUM(OperationCount) PartCycleTime
 from #Target
 GROUP BY MachineID,Sdate,ShiftName
 ) S INNER JOIN   #Finaldata ON
		#Finaldata.MachineID = S.MachineID and
		#Finaldata.Sdate=S.Sdate and
		#Finaldata.ShiftName=S.ShiftName

--------------------------------------------------------------------------------
select DISTINCT #Finaldata.MachineID,
		--#Finaldata.OperatorId,
		#Finaldata.ProductionEfficiency,
		#Finaldata.AvailabilityEfficiency,
		#Finaldata.QualityEfficiency as QualityEfficiency,
		#Finaldata.OverallEfficiency,
		dbo.f_formattime(#Finaldata.PlannedProductionTime,'hh') PlannedProductionTime,
		dbo.f_formattime(#Finaldata.DownTime, @timeformat) as DownTime,
		dbo.f_formattime(#Finaldata.UtilisedTime, @timeformat) as UtilisedTime, 
	--	isnull(#Target.Component,'') as Component,
	--	isnull(#Target.Operation,'') as Operation,
		dbo.f_formattime(isnull(#Finaldata.TargetCycleTime,0),@timeformat) as CycleTime,
		dbo.f_formattime(isnull(#Finaldata.LoadUnloadTime,0),@timeformat) as LoadUnload,
		--dbo.f_formattime(isnull(#Finaldata.ActualCycleTime,0), @timeformat) as ActualCycleTime,
		--dbo.f_formattime(isnull(#Finaldata.ActualLoadUnload,0),@timeformat) as ActualLoadUnload,
		dbo.f_formattime(isnull(#Finaldata.PartCycleTime,0),@timeformat) as PartCycleTime,
		isnull(Round(#Finaldata.OperationCount,2),0)as OperationCount, 
		cyclefficiency =
		CASE
		   when ( isnull(#Finaldata.TargetCycleTime,0) > 0 and
			  isnull(#Finaldata.ActualCycleTime,0) > 0
			) then (#Finaldata.TargetCycleTime/#Finaldata.ActualCycleTime)*100
		   else 0
		END,
		LoadUnloadefficiency =
		CASE
		   when ( isnull(#Finaldata.LoadUnloadTime,0) > 0 and
			  isnull(#Finaldata.ActualLoadUnload,0) > 0
			) then (#Finaldata.LoadUnloadTime/#Finaldata.ActualLoadUnload)*100
		   else 0
		END,
		dbo.f_formattime(isnull(#Finaldata.D1,0),'mm') as D1,
		dbo.f_formattime(isnull(#Finaldata.D2,0),'mm') as D2,
		dbo.f_formattime(isnull(#Finaldata.D3,0),'mm') as D3,
		dbo.f_formattime(isnull(#Finaldata.D4,0),'mm') as D4,
		dbo.f_formattime(isnull(#Finaldata.D5,0),'mm') as D5,
		dbo.f_formattime(isnull(#Finaldata.D6,0),'mm') as D6,
		dbo.f_formattime(isnull(#Finaldata.D7,0),'mm') as D7,
		dbo.f_formattime(isnull(#Finaldata.D8,0),'mm') as D8,
		dbo.f_formattime(isnull(#Finaldata.D9,0),'mm') as D9,
		dbo.f_formattime(isnull(#Finaldata.D10,0),'mm') as D10,
		dbo.f_formattime(isnull(#Finaldata.D11,0),'mm') as D11,
		dbo.f_formattime(isnull(#Finaldata.D12,0),'mm') as D12,
		dbo.f_formattime(isnull(#Finaldata.D13,0),'mm') as D13,
		--dbo.f_formattime(isnull(#Finaldata.D14,0),'mm') as D14,
		dbo.f_formattime(isnull(#Finaldata.Others,0),'mm') as Others,
		dbo.f_formattime(isnull(#Finaldata.TotalLoss,0),'mm') as TotalLoss,
		dbo.f_formattime(isnull(#Finaldata.ActLoss,0),'mm') as ActLoss,
		dbo.f_formattime(isnull(#Finaldata.LossErr,0),'mm') as LossErr,
		isnull(#Finaldata.TargetCount,0) as QuantityPlanned, 
		isnull(#Finaldata.components,0) as QuantityProduced,
		isnull(#Finaldata.RejCount,0) as QuantityRejected,
		isnull(#Finaldata.QuantityOk,0) as QuantityOk,
		#Finaldata.Sdate as Day,
		#Finaldata.Shiftid,
		#Finaldata.ShiftName as shift
	    from  #Finaldata 
		/*LEFT OUTER JOIN #Target ON
		#Finaldata.MachineID = #Target.MachineID and
		#Finaldata.Sdate=#Target.Sdate and
		#Finaldata.ShiftName=#Target.ShiftName */
		ORDER BY #Finaldata.Sdate,#Finaldata.Shiftid, #Finaldata.MachineID
--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------
select DISTINCT #Finaldata.MachineID,
		--#Finaldata.OperatorId,
		AVG(#Finaldata.ProductionEfficiency) ProductionEfficiency,
		AVG(#Finaldata.AvailabilityEfficiency) AvailabilityEfficiency,
		AVG(#Finaldata.QualityEfficiency) as QualityEfficiency,
		AVG(#Finaldata.OverallEfficiency) OverallEfficiency,
		dbo.f_formattime(SUM(#Finaldata.PlannedProductionTime),'hh') PlannedProductionTime,
		dbo.f_formattime(SUM(#Finaldata.DownTime), @timeformat) as DownTime,
		dbo.f_formattime(SUM(#Finaldata.UtilisedTime), @timeformat) as UtilisedTime, 
	--	isnull(#Target.Component,'') as Component,
	--	isnull(#Target.Operation,'') as Operation,
		dbo.f_formattime(isnull(SUM(#Finaldata.TargetCycleTime),0),@timeformat) as CycleTime,
		dbo.f_formattime(isnull(SUM(#Finaldata.LoadUnloadTime),0),@timeformat) as LoadUnload,
		--dbo.f_formattime(isnull(SUM(#Finaldata.ActualCycleTime),0), @timeformat) as ActualCycleTime,
		--dbo.f_formattime(isnull(SUM(#Finaldata.ActualLoadUnload),0),@timeformat) as ActualLoadUnload,
		dbo.f_formattime(isnull(SUM(#Finaldata.PartCycleTime),0),@timeformat) as PartCycleTime,
		isnull(Round(SUM(#Finaldata.OperationCount),2),0)as OperationCount, 
		cyclefficiency =
		SUM(CASE
		   when ( isnull(#Finaldata.TargetCycleTime,0) > 0 and
			  isnull(#Finaldata.ActualCycleTime,0) > 0
			) then (#Finaldata.TargetCycleTime/#Finaldata.ActualCycleTime)*100
		   else 0
		END),
		LoadUnloadefficiency =
		SUM(CASE
		   when ( isnull(#Finaldata.LoadUnloadTime,0) > 0 and
			  isnull(#Finaldata.ActualLoadUnload,0) > 0
			) then (#Finaldata.LoadUnloadTime/#Finaldata.ActualLoadUnload)*100
		   else 0
		END),
		dbo.f_formattime(isnull(SUM(#Finaldata.D1),0),'mm') as D1,
		dbo.f_formattime(isnull(SUM(#Finaldata.D2),0),'mm') as D2,
		dbo.f_formattime(isnull(SUM(#Finaldata.D3),0),'mm') as D3,
		dbo.f_formattime(isnull(SUM(#Finaldata.D4),0),'mm') as D4,
		dbo.f_formattime(isnull(SUM(#Finaldata.D5),0),'mm') as D5,
		dbo.f_formattime(isnull(SUM(#Finaldata.D6),0),'mm') as D6,
		dbo.f_formattime(isnull(SUM(#Finaldata.D7),0),'mm') as D7,
		dbo.f_formattime(isnull(SUM(#Finaldata.D8),0),'mm') as D8,
		dbo.f_formattime(isnull(SUM(#Finaldata.D9),0),'mm') as D9,
		dbo.f_formattime(isnull(SUM(#Finaldata.D10),0),'mm') as D10,
		dbo.f_formattime(isnull(SUM(#Finaldata.D11),0),'mm') as D11,
		dbo.f_formattime(isnull(SUM(#Finaldata.D12),0),'mm') as D12,
		dbo.f_formattime(isnull(SUM(#Finaldata.D13),0),'mm') as D13,
		--dbo.f_formattime(isnull(#Finaldata.D14,0),'mm') as D14,
		dbo.f_formattime(isnull(SUM(#Finaldata.Others),0),'mm') as Others,
		dbo.f_formattime(isnull(SUM(#Finaldata.TotalLoss),0),'mm') as TotalLoss,
		dbo.f_formattime(isnull(SUM(#Finaldata.ActLoss),0),'mm') as ActLoss,
		dbo.f_formattime(isnull(SUM(#Finaldata.LossErr),0),'mm') as LossErr,
		isnull(SUM(#Finaldata.TargetCount),0) as QuantityPlanned, 
		isnull(SUM(#Finaldata.components),0) as QuantityProduced,
		isnull(SUM(#Finaldata.RejCount),0) as QuantityRejected,
		isnull(SUM(#Finaldata.QuantityOk),0) as QuantityOk
	    from  #Finaldata 
		/*LEFT OUTER JOIN #Target ON
		#Finaldata.MachineID = #Target.MachineID and
		#Finaldata.Sdate=#Target.Sdate and
		#Finaldata.ShiftName=#Target.ShiftName */
		GROUP BY #Finaldata.MachineID
		ORDER BY #Finaldata.MachineID
--------------------------------------------------------------------------------------------------


END
