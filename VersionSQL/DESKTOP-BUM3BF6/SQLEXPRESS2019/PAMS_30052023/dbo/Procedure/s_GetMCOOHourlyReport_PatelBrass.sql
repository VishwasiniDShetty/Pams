/****** Object:  Procedure [dbo].[s_GetMCOOHourlyReport_PatelBrass]    Committed by VersionSQL https://www.versionsql.com ******/

/***************************************************************************************************
-- Author:		Anjana  C V
-- Create date: 30 March 2020
-- Modified date: 30 March 2020
-- Description: Get MCOO level hoourly report for Patel Brass
-- EXEC [dbo].[s_GetMCOOHourlyReport_PatelBrass] '2020-03-01 09:00:00'
-- EXEC [dbo].[s_GetMCOOHourlyReport_PatelBrass] '2020-03-01 09:00:00','CNC-26'
-- EXEC [dbo].[s_GetMCOOHourlyReport_PatelBrass] '2020-03-01 09:00:00','CNC-26','FIRST '
-- EXEC [dbo].[s_GetMCOOHourlyReport_PatelBrass] '2020-03-14 09:00:00','','FIRST '
**************************************************************************************************/
CREATE PROCEDURE [dbo].[s_GetMCOOHourlyReport_PatelBrass]
		@StartDate as Datetime,
		@Machine as nvarchar(50) = '',
		@ShiftName as nvarchar(20)=''
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET NOCOUNT ON

Declare @T_Start AS Datetime     
Declare @T_End AS Datetime    
DECLARE @stdate AS nvarchar(10)
DECLARE @strsql NVarchar(4000)

CREATE TABLE #HourlyData
	(
		[ID] int IDENTITY(1,1),
		[Date] Datetime,
		MachineInt NvarChar(50),
		MachineID NvarChar(50),
		OperatorInt NvarChar(50),
		OperatorID NvarChar(50),
		ComponentInt NvarChar(50),
		ComponentID NvarChar(50),
		OperationInt NvarChar(50),
		OperationID NvarChar(50),
		ShiftName NvarChar(20),
		StartTime DateTime,
		EndTime DateTime,
		HourID Int,
		HourStart DateTime,
		HourEnd Datetime, 	
		HourlyTarget float,
		Actual float,
		CycleTime float	,
		PE Float,
		PEGreen smallint,  
		PERed smallint 	
	)
	
CREATE TABLE #ShiftData
	(
		[ID] int IDENTITY(1,1),
		[Date] Datetime,
		MachineInt NvarChar(50),
		MachineID NvarChar(50),
		OperatorInt NvarChar(50),
		OperatorID NvarChar(50),
		ComponentInt NvarChar(50),
		ComponentID NvarChar(50),
		OperationInt NvarChar(50),
		OperationID NvarChar(50),
		ShiftName NvarChar(20),
		StartTime DateTime,
		EndTime DateTime,
		TotalActual float,
		TotalTarget float,
		ShiftQty float,
		D1  float DEFAULT 0,
		D2  float DEFAULT 0,
		D3  float DEFAULT 0,
		D4 float DEFAULT 0,
		D5  float DEFAULT 0,
		D6  float DEFAULT 0,
		D7  float DEFAULT 0,
		D8  float DEFAULT 0,
		D9  float DEFAULT 0,
		TotalLoss float DEFAULT 0,
		ShiftLoss float DEFAULT 0
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
	 Target float default 0,
	 Shift nvarchar(20),
	 Runtime float default 0,
	 TotalAvailabletime float
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
	mc,sttime ASC                
)ON [PRIMARY]    

Create table #ShiftTime
(
	PDate DateTime ,
	ShiftName NVarChar(50),
	Shiftid int,
	StartTime DateTime,
	EndTime DateTime
)

CREATE TABLE #HourDetails
	(
		[ID] int IDENTITY(1,1),
		PDate Datetime,
		ShiftName NvarChar(20),
		ShiftID int,
		HourStartart DateTime,
		ShiftEnd DateTime,
		HourName NVarchar(50),
		HourID Int,
		HourStart DateTime,
		HourEnd Datetime 	
	)

CREATE TABLE #PlannedDownTimesHour
(
	SlNo int not null identity(1,1),
	Starttime datetime,
	EndTime datetime,
	Machine nvarchar(50),
	MachineInterface nvarchar(50),
	DownReason nvarchar(50),
	HourStart datetime
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

Create table #Downcode
(
	Slno int identity(1,1) NOT NULL,
	Downid nvarchar(50),
	InterfaceId nvarchar(50),
)

Insert into #Downcode(Downid,InterfaceId)
Select top 10 downid,InterfaceId from downcodeinformation 
	where  SortOrder<=10 and isnull(SortOrder,0) <> 0
	order by sortorder

SELECT @Startdate = DATEADD(MI, +1, @Startdate)

select @stdate = CAST(datePart(yyyy,@Startdate) AS nvarchar(4)) + '-' + CAST(datePart(mm,@Startdate) AS nvarchar(2)) + '-' + CAST(datePart(dd,@Startdate) AS nvarchar(2))

--Select @T_Start=dbo.f_GetLogicalDay(@StartDate,'start')    
--Select @T_End=dbo.f_GetLogicalDay(@StartDate,'End') 

IF ISNULL(@ShiftName,'') ='' SELECT @ShiftName = ''

insert into #ShiftTime (PDate,ShiftName,StartTime,EndTime)
Exec s_GetShiftTime @StartDate,@ShiftName

UPDATE #ShiftTime
set Shiftid = S.SHIFTID
FROM (SELECT SHIFTID,ShiftName from shiftdetails where running = 1) S
INNER JOIN #ShiftTime ST ON ST.ShiftName = S.ShiftName

  
insert into #HourDetails(PDate,ShiftName,ShiftID,HourStartart,ShiftEnd,HourName,HourID,HourStart,HourEnd)
select S.PDate,S.ShiftName,S.ShiftID,S.StartTime,S.EndTime,SH.Hourname,SH.HourID,
		dateadd(day,SH.Fromday,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.HourStart) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourStart) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourStart) as nvarchar(2))))),
		dateadd(day,SH.Today,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.HourEnd) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourEnd) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourEnd) as nvarchar(2)))))
		from (Select * from #ShiftTime ) S 
		inner join Shifthourdefinition SH on SH.shiftid=S.Shiftid
		WHERE ISNULL(SH.IsEnable,1) = 1
		order by S.Shiftid,SH.Hourid

Select @T_Start= MIN(StartTime) FROM #ShiftTime 
Select @T_End= MAX(EndTime) FROM #ShiftTime  
    
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

insert INTO #PlannedDownTimeshour(StartTime,EndTime,Machine,MachineInterface,Downreason,HourStart)
select
CASE When P.StartTime<T1.HourStart Then T1.HourStart Else P.StartTime End,
case When P.EndTime>T1.HourEnd Then T1.HourEnd Else P.EndTime End,Machine,M.InterfaceID,DownReason,T1.HourStart
FROM PlannedDownTimes P
cross join #HourlyData T1
inner join MachineInformation M on P.machine = M.MachineID
WHERE P.PDTstatus =1 and (
(P.StartTime >= T1.HourStart  AND P.EndTime <=T1.HourEnd)
OR ( P.StartTime < T1.HourStart  AND P.EndTime <= T1.HourEnd AND P.EndTime > T1.HourStart )
OR ( P.StartTime >= T1.HourStart   AND P.StartTime <T1.HourEnd AND P.EndTime > T1.HourEnd )
OR ( P.StartTime < T1.HourStart  AND P.EndTime > T1.HourEnd) )
and machine=T1.MachineID
AND (M.machineid = @Machine or ISNULL(@Machine ,'')='')
ORDER BY P.StartTime

insert INTO #PlannedDownTimesShift(StartTime,EndTime,Machine,MachineInterface,Downreason,Shiftst)
		select  
		CASE When T.StartTime<T1.StartTime Then T1.StartTime Else T.StartTime End,
		case When  T.EndTime>T1.EndTime Then T1.EndTime Else T.EndTime End,
		Machine,M.InterfaceID,
		DownReason,T1.StartTime
		FROM PlannedDownTimes T cross join #ShiftTime T1
		inner join MachineInformation M on T.machine = M.MachineID
		WHERE PDTstatus =1 and (
		(T.StartTime >= T1.StartTime  AND T.EndTime <=T1.EndTime)
		OR ( T.StartTime < T1.StartTime  AND T.EndTime <= T1.EndTime AND T.EndTime > T1.StartTime )
		OR ( T.StartTime >= T1.StartTime   AND T.StartTime <T1.EndTime AND T.EndTime > T1.EndTime )
		OR ( T.StartTime < T1.StartTime  AND T.EndTime > T1.EndTime) )
		--and machine in (select distinct machine from #Machcomopnopr)
		ORDER BY T.StartTime
		
-------------------------------------------------------------------------------------------
  
--Insert into #ShiftData(MachineID,MachineInt,ComponentID,ComponentInt,OperationID,OperationInt,OperatorID,OperatorInt,
--Date,ShiftName,StartTime,EndTime)
--	SELECT DISTINCT M.machineid,M.InterfaceID,C.componentid,C.InterfaceID,O.operationno,O.InterfaceID,E.Employeeid,E.interfaceid,
--	S.PDate,S.ShiftName,S.StartTime,S.EndTime
--	FROM #T_autodata A 
--	Inner join machineinformation M on M.interfaceid=A.mc
--	Inner join componentinformation C ON A.Comp=C.interfaceid
--	Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid 
--				AND C.Componentid=O.componentid And O.MachineID = M.MachineID
--	INNER Join Employeeinformation E ON E.interfaceid = A.opr 
--	CROSS JOIN #ShiftTime S
--	WHERE ((A.msttime >= S.StartTime  AND A.ndtime <= S.EndTime)  
--	OR ( A.msttime < S.StartTime  AND A.ndtime <= S.EndTime AND A.ndtime >S.StartTime )  
--	OR ( A.msttime >= S.StartTime AND A.msttime <S.EndTime AND A.ndtime > S.EndTime)  
--	OR ( A.msttime < S.StartTime AND A.ndtime > S.EndTime))
--	AND (M.machineid = @Machine or ISNULL(@Machine ,'')='')

Insert into #HourlyData(MachineID,MachineInt,ComponentID,ComponentInt,OperationID,OperationInt,OperatorID,OperatorInt,
Date,ShiftName,StartTime,EndTime,HourID,HourStart,HourEnd,CycleTime,PEGreen,PERed)
	SELECT DISTINCT M.machineid,M.InterfaceID,C.componentid,C.InterfaceID,O.operationno,O.InterfaceID,E.Employeeid,E.interfaceid,
	H.PDate,H.ShiftName,H.HourStartart,H.ShiftEnd,H.HourID,H.HourStart,H.HourEnd,
	O.cycletime,
       -- O.machiningtime,
	M.PEGreen,M.PERed
	FROM #T_autodata A 
	Inner join machineinformation M on M.interfaceid=A.mc
	Inner join componentinformation C ON A.Comp=C.interfaceid
	Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid 
				AND C.Componentid=O.componentid And O.MachineID = M.MachineID
	INNER Join Employeeinformation E ON E.interfaceid = A.opr 
	CROSS JOIN #HourDetails H
	WHERE ((A.msttime >= H.HourStart  AND A.ndtime <= H.HourEnd)  
	OR ( A.msttime < H.HourStart  AND A.ndtime <= H.HourEnd AND A.ndtime >H.HourStart )  
	OR ( A.msttime >= H.HourStart AND A.msttime <H.HourEnd AND A.ndtime > H.HourEnd)  
	OR ( A.msttime < H.HourStart AND A.ndtime > H.HourEnd))
	AND (M.machineid = @Machine or ISNULL(@Machine ,'')='')

Insert into #ShiftData(MachineID,MachineInt,ComponentID,ComponentInt,OperationID,OperationInt,OperatorID,OperatorInt,
						Date,ShiftName,StartTime,EndTime)
SELECT DISTINCT MachineID,MachineInt,ComponentID,ComponentInt,OperationID,OperationInt,OperatorID,OperatorInt,
	   Date,ShiftName,StartTime,EndTime 
FROM #HourlyData
-----------------------------Components-----------------------------------------------------
--------------------------------------------------------------------------------------------
  
Update #HourlyData set Actual = Isnull(Actual,0) + Isnull(T1.Comp,0)
 FROM  
	(
	Select M.machineid,C.componentid,O.operationno,E.Employeeid,T.HourStart,T.HourEnd,SUM(Isnull(A.partscount,1)/ISNULL(O.SubOperations,1)) As Comp
	from #T_autodata A
	Inner join machineinformation M on M.interfaceid=A.mc
	Inner join (SELECT DISTINCT MachineID,MachineInt,ComponentID,ComponentInt,OperationID,OperationInt,OperatorID,OperatorInt,HourStart,HourEnd,HourID FROM #HourlyData) T 
	on T.machineid=M.machineid AND T.ComponentInt = A.Comp AND  T.OperationInt = A.opn AnD T.OperatorInt = A.opr
	Inner join componentinformation C ON A.Comp=C.interfaceid
	Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID
	INNER Join Employeeinformation E ON E.interfaceid = A.opr 
	WHERE A.DataType=1 and M.machineid=T.MachineID
	AND(A.ndtime > T.HourStart  AND A.ndtime <=T.HourEnd)
	Group by M.machineid,C.componentid,O.operationno,E.Employeeid,T.HourStart,T.HourEnd
	)T1 
	inner join #HourlyData H on H.HourStart=T1.HourStart
	and H.HourEnd=T1.HourEnd and H.machineid=T1.machineid And H.ComponentID = T1.componentid 
	And H.OperationID = T1.operationno And H.OperatorId = T1.Employeeid

------------------------------------------------------------------------
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
	BEGIN

		Update #HourlyData set Actual = Isnull(Actual,0) - Isnull(T1.Comp,0) from  
		(Select M.machineid,C.componentid,O.operationno,E.Employeeid,T1.HourStart,T1.HourEnd,SUM(Isnull(A.partscount,1)/ISNULL(O.SubOperations,1)) As Comp
		from #T_autodata A
		Inner join machineinformation M on M.interfaceid=A.mc
		Inner join (SELECT DISTINCT MachineID,MachineInt,ComponentID,ComponentInt,OperationID,OperationInt,OperatorID,OperatorInt,HourStart,HourEnd,HourID FROM #HourlyData) T1 
		on T1.machineid=M.machineid AND T1.ComponentInt = A.Comp AND  T1.OperationInt = A.opn AnD T1.OperatorInt = A.opr
		Inner join componentinformation C ON A.Comp=C.interfaceid
		Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID
		INNER Join Employeeinformation E ON E.interfaceid = A.opr 
		CROSS jOIN PlannedDownTimes T
		WHERE A.DataType=1 and T.machine=T1.Machineid and M.machineid=T.Machine
		AND(A.ndtime > T1.HourStart  AND A.ndtime <=T1.HourEnd)
		AND(A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)
		Group by M.machineid,C.componentid,O.operationno,E.Employeeid,T1.HourStart,T1.HourEnd
		)T1 inner join #HourlyData H on H.HourStart=T1.HourStart
		and H.HourEnd=T1.HourEnd and H.machineid=T1.machineid And H.ComponentID = T1.componentid And H.OperationID = T1.operationno And H.OperatorId = T1.Employeeid
	END
-------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------
insert into #Target(MachineID,machineinterface,Component,Compinterface,Operation,Opninterface,Operator,OprInterface,      
	msttime,ndtime,FromTm,Totm,batchid,autodataid,stdtime,Shift)
	SELECT  machineinformation.machineid, machineinformation.interfaceid,C.componentid, C.interfaceid,  
	O.operationno, O.interfaceid,E.Employeeid,E.interfaceid, 
	Case when autodata.msttime< T.Hourstart then T.Hourstart else autodata.msttime end,   
	Case when autodata.ndtime> T.HourEnd then T.HourEnd else autodata.ndtime end,  
	T.Hourstart,T.HourEnd,0,autodata.id,O.Cycletime,T.ShiftName 
	FROM #T_autodata  autodata  
	INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID   
	INNER JOIN componentinformation C ON autodata.comp = C.InterfaceID    
	INNER JOIN componentoperationpricing O ON autodata.opn = O.InterfaceID  
	AND c.componentid = O.componentid and O.machineid=machineinformation.machineid
	INNER JOIN employeeinformation E ON Autodata.opr = E.interfaceid   
	Left Outer Join downcodeinformation DI on DI.interfaceid=autodata.dcode  
	Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid   
	Cross join #HourDetails T  
	WHERE ((autodata.msttime >= T.Hourstart  AND autodata.ndtime <= T.HourEnd)  
	OR ( autodata.msttime < T.Hourstart  AND autodata.ndtime <= T.HourEnd AND autodata.ndtime >T.Hourstart )  
	OR ( autodata.msttime >= T.Hourstart AND autodata.msttime <T.HourEnd AND autodata.ndtime > T.HourEnd)  
	OR ( autodata.msttime < T.Hourstart AND autodata.ndtime > T.HourEnd))
	AND (machineinformation.machineid = @Machine or ISNULL(@Machine ,'')='')
	order by autodata.msttime
  	
insert into #FinalTarget (MachineID,Component,operation,Operator,machineinterface,Compinterface,Opninterface,Oprinterface,BatchStart,BatchEnd,
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
	from #Target t 
	) tt
	group by MachineID,Component,operation,Operator,machineinterface,Compinterface,Opninterface,Oprinterface,batchid,FromTm,ToTm,stdtime,shift 
	order by tt.batchid


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
	inner join #PlannedDownTimesHour pdt on t1.machineid=Pdt.machine    
	where     
	((pdt.StartTime >= t1.BatchStart and pdt.EndTime <= t1.BatchEnd)or    
	(pdt.StartTime < t1.BatchStart and pdt.EndTime > t1.BatchStart and pdt.EndTime <=t1.BatchEnd)or    
	(pdt.StartTime >= t1.BatchStart and pdt.StartTime <t1.BatchEnd and pdt.EndTime >t1.BatchEnd) or    
	(pdt.StartTime <  t1.BatchStart and pdt.EndTime >t1.BatchEnd))    
	)T2 
	group by  t2.machineinterface,T2.Machine,T2.BatchStart,T2.BatchEnd,T2.Fromtm    
	) T3 inner join #FinalTarget T on T.machineinterface=T3.machineinterface and T.BatchStart=T3.BatchStart and  T.BatchEnd=T3.BatchEnd and T.Fromtm=T3.Fromtm    

END   
  
	Update #FinalTarget set Target = Isnull(Target,0) + isnull(T2.targetcount,0) from     
		(    
		Select T.machineinterface,T.Compinterface,T.Opninterface,T.FromTm,T.BatchStart,T.BatchEnd,T.OprInterface,
		sum(((T.Runtime*CO.suboperations)/CO.cycletime)*isnull(CO.targetpercent,100) /100) as targetcount    
		from #FinalTarget T     
		inner join machineinformation M on M.Interfaceid=T.machineinterface    
		inner join componentinformation C on C.interfaceid=T.Compinterface    
		inner join componentoperationpricing CO on M.machineid=co.machineid and c.componentid=Co.componentid    
		and Co.interfaceid=T.Opninterface    
		group by T.FromTm,T.BatchStart,T.BatchEnd,T.machineinterface,T.Compinterface,T.Opninterface,T.OprInterface   
		)T2 Inner Join #FinalTarget on t2.machineinterface = #FinalTarget.machineinterface and  
		t2.compinterface = #FinalTarget.compinterface and t2.opninterface = #FinalTarget.opninterface 
		AND t2.OprInterface = #FinalTarget.OprInterface
		and #FinalTarget.BatchStart=T2.BatchStart and  #FinalTarget.BatchEnd=T2.BatchEnd and #FinalTarget.Fromtm=T2.Fromtm

--------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------
	Update #HourlyData set HourlyTarget = Isnull(HourlyTarget,0) + isnull(T1.Target,0) from 
	(
	  select machineinterface,Compinterface,Opninterface,OprInterface,
			shift,FromTm, 
			FLOOR(sum(isnull(Target,0))) as Target,
			sum(isnull(Runtime,0)) as Runtime from #FinalTarget
			group by machineinterface,Compinterface,Opninterface,OprInterface,shift,FromTm 
	 )T1 inner join #HourlyData on #HourlyData.MachineInt=T1.machineinterface and
	 #HourlyData.ComponentInt=T1.Compinterface and #HourlyData.OperationInt=T1.Opninterface 
	 and #HourlyData.OperatorInt=T1.OprInterface and
	 #HourlyData.HourStart=T1.FromTm 

--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
UPDATE #HourlyData
SET HourlyTarget = 0 
WHERE ISNULL(Actual,0) =  0
  
---------------------------------------------------------------------------
select * from #downcode
declare @i as nvarchar(10)
declare @colName as nvarchar(50)
Select @i=1

while @i <=9
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
						END

	 ---Get the down times which are not of type Management Loss  
	 Select @strsql = ''
	 Select @strsql = @strsql + ' UPDATE  #ShiftData SET ' + @ColName + ' = isnull(' + @ColName + ',0) + isNull(t2.down,0)  
	 from  
	 (select  F.StartTime,F.EndTime,F.MachineInt,F.ComponentID,F.OperationID,F.OperatorID,
	  sum (CASE  
		WHEN (autodata.msttime >= F.StartTime  AND autodata.ndtime <=F.EndTime)  THEN autodata.loadunload  
		WHEN ( autodata.msttime < F.StartTime  AND autodata.ndtime <= F.EndTime  AND autodata.ndtime > F.StartTime ) 
		THEN DateDiff(second,F.StartTime,autodata.ndtime)  
		WHEN ( autodata.msttime >= F.StartTime   AND autodata.msttime <F.EndTime  AND autodata.ndtime > F.EndTime  ) 
		THEN DateDiff(second,autodata.msttime,F.EndTime )  
		WHEN ( autodata.msttime < F.StartTime  AND autodata.ndtime > F.EndTime ) THEN DateDiff(second,F.StartTime,F.EndTime )  
		END ) as down  
		from #T_autodata autodata   
		INNER JOIN #ShiftData F on F.MachineInt=Autodata.mc AND F.ComponentInt = AutoData.comp
		AND F.OperationInt = AutoData.opn AND  F.OperatorInt = AutoData.opr
		inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid 
		inner join #Downcode on #Downcode.downid= downcodeinformation.downid
		where (autodata.datatype=''2'') AND  #Downcode.Slno= ' + @i + ' and 
		(( (autodata.msttime>=F.StartTime) and (autodata.ndtime<=F.EndTime))  
		   OR ((autodata.msttime<F.StartTime) and (autodata.ndtime>F.StartTime) and (autodata.ndtime<=F.EndTime))  
		   OR ((autodata.msttime>=F.StartTime) and (autodata.msttime<F.EndTime) and (autodata.ndtime>F.EndTime))  
		   OR((autodata.msttime<F.StartTime) and (autodata.ndtime>F.EndTime))) 
		   group by F.StartTime,F.EndTime,F.MachineInt,F.ComponentID,F.OperationID,F.OperatorID
	 ) as t2 Inner Join #ShiftData on t2.MachineInt = #ShiftData.MachineInt AND t2.ComponentID = #ShiftData.ComponentID   
	  AND t2.OperationID = #ShiftData.OperationID  AND t2.OperatorID = #ShiftData.OperatorID
	  and t2.StartTime=#ShiftData.StartTime
	  and t2.EndTime=#ShiftData.EndTime'

     print @strsql
	 exec(@strsql) 

	 	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
			BEGIN   
				Select @strsql = '' 
				Select @strsql = @strsql + 'UPDATE  #ShiftData SET ' + @ColName + ' = isnull(' + @ColName + ',0) - isNull(T2.PPDT ,0)  
				FROM(  
				SELECT  F.StartTime,F.EndTime,F.MachineInt,F.ComponentID,F.OperationID,F.OperatorID,
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
				INNER JOIN #ShiftData F on F.MachineInt=Autodata.mc AND F.ComponentInt = AutoData.comp
				AND F.OperationInt = AutoData.opn AND  F.OperatorInt = AutoData.opr
				inner join #Downcode on #Downcode.downid= downcodeinformation.downid
				WHERE autodata.DataType=''2'' AND T.MachineInterface=autodata.mc 
				--AND (downcodeinformation.availeffy = ''0'') 
				and #Downcode.Slno= ' + @i + '  
				AND  
				((autodata.sttime >= F.StartTime  AND autodata.ndtime <=F.EndTime)  
				OR ( autodata.sttime < F.StartTime  AND autodata.ndtime <= F.EndTime AND autodata.ndtime > F.StartTime )  
				OR ( autodata.sttime >= F.StartTime   AND autodata.sttime <F.EndTime AND autodata.ndtime > F.EndTime )  
				OR ( autodata.sttime < F.StartTime  AND autodata.ndtime > F.EndTime))  
				AND  
				((autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
				OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
				OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )  
				OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )   
				AND  
				((F.StartTime >= T.StartTime  AND F.EndTime <=T.EndTime)  
				OR ( F.StartTime < T.StartTime  AND F.EndTime <= T.EndTime AND F.EndTime > T.StartTime )  
				OR ( F.StartTime >= T.StartTime   AND F.StartTime <T.EndTime AND F.EndTime > T.EndTime )  
				OR ( F.StartTime < T.StartTime  AND F.EndTime > T.EndTime) )   
				group  by F.StartTime,F.EndTime,F.MachineInt,F.ComponentID,F.OperationID,F.OperatorID
				)AS T2  Inner Join #ShiftData on t2.MachineInt = #ShiftData.MachineInt  AND t2.ComponentID = #ShiftData.ComponentID   
				 AND t2.OperationID = #ShiftData.OperationID  AND t2.OperatorID = #ShiftData.OperatorID 
				and t2.StartTime=#ShiftData.StartTime and t2.EndTime=#ShiftData.EndTime  '
				print @strsql
				exec(@Strsql)
			END

	 select @i  =  @i + 1
	 END
------------------------------------------------------------------------------
  
UPDATE #ShiftData SET TotalLoss= (D1+D2+D3+D4+D5+D6+D7+D8+D9)

UPDATE #ShiftData 
SET TotalActual = ISNULL(T.Actual,0) ,
	TotalTarget = ISNULL(T.Target,0)
FROM 
	(
	SELECT MachineID,ComponentID,OperationID,OperatorID,ShiftName,StartTime, SUM(Actual) as Actual, SUM(HourlyTarget) as Target
	FROM #HourlyData 
	GROUP BY MachineID,ComponentID,OperationID,OperatorID,ShiftName,StartTime 
	)T 
INNER JOIN #ShiftData S ON S.MachineID = T.MachineID AND S.ComponentID = T.ComponentID AND S.OperationID = T.OperationID 
						AND S.OperatorID = T.OperatorID AND S.StartTime = T.StartTime  

UPDATE #ShiftData 
SET ShiftQty = ISNULL(T.TotalActual,0) ,
	ShiftLoss = ISNULL(T.TotalLoss,0)
FROM 
	(
		SELECT MachineID,StartTime,SUM(TotalActual) TotalActual , SUM(TotalLoss) TotalLoss 
		FROM #ShiftData
		GROUP BY MachineID,StartTime
	)T
INNER JOIN #ShiftData S ON S.MachineID = T.MachineID AND S.StartTime = T.StartTime
--------------------------------------------------------------------------------------------
UPDATE #HourlyData
SET PE = ( ISNULL(Actual,0) /ISNULL(HourlyTarget,0) ) * 100
WHERE ISNULL(HourlyTarget,0) <> 0
------------------------------------output-----------------------------------------------
SELECT Date,MachineID,ComponentID,OperationID,OperatorID,ShiftName,StartTime,EndTime,HourID,HourStart,HourEnd,
	ISNULL(HourlyTarget,0) HourlyTarget,ISNULL(Actual,0) Actual, CycleTime,
	ISNULL(PE,0) PE,PEGreen,PERed 
FROM #HourlyData
ORDER BY StartTime,MachineID,ComponentID,OperationID,OperatorID,HourStart

SELECT Date,MachineID,ComponentID,OperationID,OperatorID,ShiftName,StartTime,EndTime,  
TotalActual,TotalTarget,ShiftQty,
dbo.f_formattime(D1,'mm') as D1,dbo.f_formattime(D2,'mm') as D2,dbo.f_formattime(D3,'mm') as D3,
dbo.f_formattime(D4,'mm') as D4,dbo.f_formattime(D5,'mm') as D5,dbo.f_formattime(D6,'mm') as D6,
dbo.f_formattime(D7,'mm') as D7,dbo.f_formattime(D8,'mm') as D8,dbo.f_formattime(D9,'mm') as D9,
dbo.f_formattime(TotalLoss,'mm') as TotalLoss,dbo.f_formattime(ShiftLoss,'mm') as ShiftLoss
FROM #ShiftData
ORDER BY StartTime,MachineID,ComponentID,OperationID,OperatorID
 
END
