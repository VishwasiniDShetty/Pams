/****** Object:  Procedure [dbo].[s_GetProdAndDownReport_Eastern]    Committed by VersionSQL https://www.versionsql.com ******/

/***************************************************************************************************
-- Author:		Anjana C V
-- Create date: 04 Feb 2019
-- Modified date: 04 Feb 2019
-- Description:  Get Production And Down Report Data for Eastern
-- s_GetProdAndDownReport_Eastern '2018-02-01 06:00:00 AM','2019-02-05 02:00:00 PM','SECOND B','B-03','EBPL'
-- s_GetProdAndDownReport_Eastern '2019-03-05 06:00:00 AM','2019-03-06 02:30:00 PM','','CR-05',''
**************************************************************************************************/
CREATE PROCEDURE [dbo].[s_GetProdAndDownReport_Eastern]
	@StartDate datetime ,
	@EndDate datetime ,
	@Shift nvarchar(20) = '',
	@MachineID nvarchar(50) = '',
	@PlantID NvarChar(50)=''
	
AS
BEGIN

declare @strsql nvarchar(4000)
declare @strmachine nvarchar(255)
Declare @StrPlantID AS NVarchar(255)
Declare @StrtTime as DATETIME
Declare @timeformat AS nvarchar(12) 
declare @MinLuLR  integer

Select @timeformat = 'ss'
select @strsql = ''
select @strmachine = ''
select @StrPlantID = ''
SELECT @StrtTime = @StartDate
SELECT @MinLuLR=isnull((select top 1 valueinint from Shopdefaults where parameter='MinLUforLR'),0)

CREATE TABLE #Target  
 ( 
 id int,
 MachineID nvarchar(50) ,  
 machineinterface nvarchar(50),
 ComponentID nvarchar(50) ,
 Componentinterface nvarchar(50),
 OperationId nvarchar(50) NOT NULL,
 OperationInterface nvarchar(50),
 OperationDescription nvarchar(50),
 Operator nvarchar(50),  
 OperatorId nvarchar(50),
 OperatorInterface nvarchar(50),
 Ddate datetime,
 Shift nvarchar(20),
 ShiftStart datetime,
 ShiftEnd datetime,
 StdCycleTime float,
 ActCycleTime float,
 Actloadunload float,
 TargetProd float,
 Pcount float, 
 OkQty  float,
 ReworkQty float,
 RejectionQty float,
 TotalProdQty float,
 --UtilisedTime float,
 --CN float,
 --DownTime float,
 --OperatorEffi float,
 --MachineEffi float,
 --Remark nvarchar(500) ,
 SubOperations int
 )

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

ALTER TABLE #T_autodata

ADD PRIMARY KEY CLUSTERED
(
	mc,sttime ASC
)ON [PRIMARY]

CREATE TABLE #FinalTarget  
 ( 
 id int,
 MachineID nvarchar(50) ,  
 machineinterface nvarchar(50),
 ComponentID nvarchar(50) ,
 Componentinterface nvarchar(50),
 OperationId nvarchar(50) NOT NULL,
 OperationInterface nvarchar(50),
 OperationDescription nvarchar(50),
 Operator nvarchar(50),  
 OperatorId nvarchar(50),
 OperatorInterface nvarchar(50),
 Ddate datetime,
 Shift nvarchar(20),
 ShiftStart datetime,
 ShiftEnd datetime,
 StdCycleTime float,
 ActCycleTime float,
 Actloadunload float,
 TargetProd float,
 Pcount float, 
 OkQty  float,
 ReworkQty float,
 RejectionQty float,
 TotalProdQty float,
 UtilisedTime float,
 CN float,
 DownTime float,
 OperatorEffi float,
 MachineEffi float,
 Remark nvarchar(500) ,
 SubOperations int
)

CREATE TABLE #ShiftDefn
	(
		Pdate DateTime,		
		Shift nvarchar(20),
		ShiftStart DateTime,
		ShiftEnd DateTime	
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


while @StrtTime<=@EndDate  
BEGIN  
 INSERT #ShiftDefn(Pdate, Shift, ShiftStart, ShiftEnd)  
 EXEC s_GetShiftTime @StrtTime,@Shift 
 SELECT @StrtTime=DATEADD(DAY,1,@StrtTime)  
END  

if isnull(@PlantID,'') <> ''
	begin
	 select @StrPlantID = ' and ( PlantMachine.PlantID = N''' + @PlantID + ''' )'
	end
if isnull(@machineid,'') <> ''
	begin
	select @strmachine = ' and ( machineinformation.MachineID = N''' + @MachineID + ''')'
	end

Select @strsql=''
		select @strsql ='insert into #T_autodata '
		select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'
		 select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'
		select @strsql = @strsql + ' from autodata where (( sttime >='''+ convert(nvarchar(25),@StartDate,120)+''' and ndtime <= '''+ convert(nvarchar(25),@EndDate,120)+''' ) OR '
		select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@StartDate,120)+''' and ndtime >'''+ convert(nvarchar(25),@EndDate,120)+''' )OR '
		select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@StartDate,120)+''' and ndtime >'''+ convert(nvarchar(25),@StartDate,120)+'''
						 and ndtime<='''+convert(nvarchar(25),@EndDate,120)+''' )'
		select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@StartDate,120)+''' and ndtime >'''+ convert(nvarchar(25),@EndDate,120)+''' and sttime<'''+convert(nvarchar(25),@EndDate,120)+''' ) )'
		print @strsql
		exec (@strsql)

Select @strsql=''
		select @strsql ='insert into #FinalTarget(id,
						 MachineID,machineinterface ,ComponentID ,Componentinterface ,OperationId ,OperationInterface ,OperationDescription,
						 Operator, OperatorID,OperatorInterface,
						 Ddate,Shift,ShiftStart,ShiftEnd,StdCycleTime,SubOperations) '
		select @strsql = @strsql + 'SELECT distinct (ROW_NUMBER() OVER(ORDER BY max(sttime) ASC)) AS id ,
		                 Machineinformation.Machineid,Machineinformation.interfaceid,
						componentinformation.componentid,componentinformation.interfaceid,componentoperationpricing.operationno,
						componentoperationpricing.interfaceid,componentoperationpricing.Description,
						employeeinformation.name,employeeinformation.Employeeid,employeeinformation.interfaceid,
						Pdate, Shift, ShiftStart, ShiftEnd ,componentoperationpricing.cycletime,ISNULL(ComponentOperationPricing.SubOperations,1) '
		select @strsql = @strsql + ' from #T_autodata autodata inner join machineinformation on machineinformation.interfaceid=autodata.mc inner join '
		select @strsql = @strsql + ' componentinformation ON autodata.comp = componentinformation.InterfaceID  INNER JOIN '
		select @strsql = @strsql + ' componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID)'
		select @strsql = @strsql + ' AND (componentinformation.componentid = componentoperationpricing.componentid) '
		select @strsql = @strsql + ' and componentoperationpricing.machineid=machineinformation.machineid '
		select @strsql = @strsql + ' inner join employeeinformation on autodata.opr=employeeinformation.interfaceid'
		select @strsql = @strsql + ' Left Outer Join PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID '
		select @strsql = @strsql + ' cross join #ShiftDefn where '
		select @strsql = @strsql + '(( sttime >= shiftstart and ndtime <= shiftend ) OR '
		select @strsql = @strsql + '( sttime < shiftstart and ndtime > shiftend )OR '
		select @strsql = @strsql + '( sttime < shiftstart and ndtime > shiftstart and ndtime<=shiftend )'
		select @strsql = @strsql + ' OR ( sttime >= shiftstart and ndtime > shiftend and sttime<shiftend ) ) and machineinformation.interfaceid>0 '
		select @strsql = @strsql + @strmachine + @StrPlantID
		select @strsql = @strsql + ' group by machineinformation.machineid, componentinformation.componentid, componentoperationpricing.operationno,
						componentoperationpricing.Description,ComponentOperationPricing.SubOperations,
						employeeinformation.name,employeeinformation.Employeeid,employeeinformation.interfaceid,componentoperationpricing.cycletime,
						Pdate, Shift, ShiftStart, ShiftEnd ,
						machineinformation.interfaceid,componentinformation.interfaceid,componentoperationpricing.interfaceid
		               order by ShiftStart asc,Machineinformation.Machineid'
		print @strsql
		exec (@strsql)

Select @strsql=''
		select @strsql ='insert into #Target ( id,
						 MachineID,machineinterface ,ComponentID ,Componentinterface ,OperationId ,OperationInterface ,OperationDescription,
						 Operator, OperatorID,OperatorInterface,
						 Ddate,Shift,ShiftStart,ShiftEnd ,StdCycleTime, Actloadunload ,ActCycleTime,TargetProd,OkQty,Pcount,ReworkQty,RejectionQty ,
						 TotalProdQty ,
						 --DownTime ,OperatorEffi ,MachineEffi,
						 SubOperations
						 --,Remark 
						 ) ' 
		select @strsql = @strsql + ' SELECT distinct (ROW_NUMBER() OVER(ORDER BY max(sttime) ASC)) AS id ,
						Machineinformation.Machineid,Machineinformation.interfaceid,
						componentinformation.componentid,componentinformation.interfaceid,componentoperationpricing.operationno,
						componentoperationpricing.interfaceid,componentoperationpricing.Description,
						employeeinformation.name,employeeinformation.Employeeid,employeeinformation.interfaceid,
						Pdate, Shift, ShiftStart, ShiftEnd,componentoperationpricing.cycletime,
						Sum(case when (autodata.loadunload>=''' +convert(nvarchar(20),@MinLuLR)+ ''' )  then (autodata.loadunload) end) as Actloadunload,
						sum(autodata.cycletime) as ActCycleTime,
						--(30600/componentoperationpricing.cycletime) as TotalProdQty,0,
						(DATEDIFF(second, ShiftStart, ShiftEnd)/componentoperationpricing.cycletime) as TotalProdQty,0,
						(CAST(Sum(autodata.partscount)AS Float)/ISNULL(ComponentOperationPricing.SubOperations,1)) as Pcount,
						0,0,0,
						--0,0,0,
						ISNULL(ComponentOperationPricing.SubOperations,1)
						from #T_autodata autodata inner join machineinformation on machineinformation.interfaceid=autodata.mc inner join 
					    componentinformation ON autodata.comp = componentinformation.InterfaceID  INNER JOIN  
						componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID)
						AND (componentinformation.componentid = componentoperationpricing.componentid) 
						and componentoperationpricing.machineid=machineinformation.machineid  
						Left join employeeinformation on autodata.opr=employeeinformation.interfaceid 
						Left Outer Join PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID 
						cross join #ShiftDefn where 
						 machineinformation.interfaceid > 0 and (( sttime >= shiftstart and ndtime <= shiftend ) 
						 OR ( sttime < shiftstart and ndtime > shiftstart and ndtime<=shiftend )) 
						 and autodata.datatype=1  AND (autodata.partscount > 0 )'
						select @strsql = @strsql + @strmachine + @StrPlantID
						select @strsql = @strsql + ' group by machineinformation.machineid, componentinformation.componentid, componentoperationpricing.operationno,
						componentoperationpricing.Description,ComponentOperationPricing.SubOperations,componentoperationpricing.cycletime,
						employeeinformation.name,employeeinformation.Employeeid,employeeinformation.interfaceid,
						Pdate, Shift, ShiftStart, ShiftEnd ,
						machineinformation.interfaceid,componentinformation.interfaceid,componentoperationpricing.interfaceid 
						order by  ShiftStart asc,machineinformation.machineid '
		print @strsql
		exec (@strsql)

 
	insert INTO #PlannedDownTimesShift(StartTime,EndTime,Machine,MachineInterface,Downreason,Shiftst)
		select
		CASE When StartTime<T1.ShiftStart Then T1.ShiftStart Else StartTime End,
		case When EndTime>T1.ShiftEnd Then T1.ShiftEnd Else EndTime End,
		Machine,M.InterfaceID,
		DownReason,T1.ShiftStart
		FROM PlannedDownTimes cross join #ShiftDefn T1
		inner join MachineInformation M on PlannedDownTimes.machine = M.MachineID
		WHERE PDTstatus =1 and (
		(StartTime >= T1.ShiftStart  AND EndTime <=T1.ShiftEnd)
		OR ( StartTime < T1.ShiftStart  AND EndTime <= T1.ShiftEnd AND EndTime > T1.ShiftStart )
		OR ( StartTime >= T1.ShiftStart   AND StartTime <T1.ShiftEnd AND EndTime > T1.ShiftEnd )
		OR ( StartTime < T1.ShiftStart  AND EndTime > T1.ShiftEnd) )
		and machine in (select distinct machine from #Target)
        ORDER BY StartTime

		Update  #Target  set OkQty = Isnull(T1.OkQty,0) 
		FROM  ( SELECT  S.machineinterface, S.Componentinterface, S.OperationInterface,S.OperatorInterface ,S.shiftstart, S.ShiftEnd,
		(CAST(Sum(a.partscount)AS Float)/ISNULL(S.SubOperations,1)) as OkQty
		from #T_autodata A 
		INNER join #Target S on A.mc=S.MachineInterface and S.Componentinterface=A.comp and S.OperationInterface=A.opn
		and S.OperatorInterface = A.opr
		WHERE ( A.ndtime > S.shiftstart  AND A.ndtime <=S.ShiftEnd )
		and (SUBSTRING (S.OperationDescription ,(DATALENGTH(cast(S.OperationDescription as varchar))-2 ), 3 )) !='REW'
		group by S.SubOperations, ShiftStart, ShiftEnd,S.machineinterface, S.Componentinterface, S.OperationInterface, S.OperatorInterface
		) T1 inner join  #Target  on  T1.machineinterface = #Target.machineinterface and T1.Componentinterface = #Target.Componentinterface 
		and T1.OperationInterface = #Target.OperationInterface and T1.OperatorInterface = #Target.OperatorInterface 
		and #Target.shiftstart=T1.shiftstart and  #Target .ShiftEnd=T1.ShiftEnd 

		Update  #Target  set RejectionQty = Isnull( #Target .RejectionQty,0) + Isnull(T1.RejectionQty,0) from
		(Select  T.machineinterface, T.Componentinterface, T.OperationInterface, T.OperatorInterface , T.shiftstart,T.ShiftEnd,SUM(A.Rejection_Qty) as RejectionQty
		from AutodataRejections A 
		INNER join  #Target  T on T.machineinterface=A.mc and T.Componentinterface=A.comp and T.OperationInterface=A.opn
		and T.OperatorInterface = A.opr
		where A.Flag= 'Rejection' 
		and (A.CreatedTS>=T.shiftstart  and A.CreatedTS<=T.ShiftEnd)
		group by T.shiftstart,T.ShiftEnd,T.machineinterface, T.Componentinterface, T.OperationInterface, T.OperatorInterface
		)T1 inner join  #Target  on  T1.machineinterface = #Target.machineinterface and T1.Componentinterface = #Target.Componentinterface 
		and T1.OperationInterface = #Target.OperationInterface and T1.OperatorInterface = #Target.OperatorInterface 
		and #Target .shiftstart=T1.shiftstart and  #Target .ShiftEnd=T1.ShiftEnd 

		Update  #Target  set ReworkQty = Isnull( #Target .ReworkQty,0) + Isnull(T1.ReworkQty,0) from
		(Select  S.machineinterface, S.Componentinterface, S.OperationInterface, S.OperatorInterface,  S.shiftstart,S.ShiftEnd,SUM(A.PartsCount) as ReworkQty
		from #T_autodata A 
		inner join #Target S on A.mc=S.MachineInterface  
		and S.Componentinterface=A.comp and S.OperationInterface=A.opn
		and S.OperatorInterface = A.opr
		where (A.datatype=1) AND ( A.ndtime > S.shiftstart  AND A.ndtime <=S.ShiftEnd )
		and  (SUBSTRING (S.OperationDescription ,(DATALENGTH(cast(S.OperationDescription as varchar))-2 ), 3 )) ='REW'
		group by S.shiftstart,S.ShiftEnd,S.machineinterface, S.Componentinterface, S.OperationInterface, S.OperatorInterface
		)T1 inner join  #Target  on  T1.machineinterface = #Target.machineinterface and T1.Componentinterface = #Target.Componentinterface 
		and T1.OperationInterface = #Target.OperationInterface 
		and T1.OperatorInterface = #Target.OperatorInterface 
		and #Target .shiftstart=T1.shiftstart and  #Target .ShiftEnd=T1.ShiftEnd


	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
	BEGIN

	   UPDATE #Target SET OkQty = isnull(OkQty,0) - isNull(t2.Ok1Qty1,0)
		From
		(
			select T.Machine as machine,T.Shiftst as initime,
			A.comp as Componentinterface,A.opn as OperationInterface, A.opr as OperatorInterface ,
			sum(CAST(a.partscount AS Float)/ISNULL(S.SubOperations,1))  Ok1Qty1
			from #T_autodata  A 
			inner join #Target S on A.mc=S.MachineInterface and S.Componentinterface=A.comp and S.OperationInterface=A.opn  
			 and S.OperatorInterface = A.opr
			CROSS jOIN #PlannedDownTimesShift T
			WHERE A.DataType=1 and T.MachineInterface=A.mc
			and (SUBSTRING (S.OperationDescription ,(DATALENGTH(cast(S.OperationDescription as varchar))-2 ), 3 )) !='REW'
			AND(A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)
			Group by T.Machine,T.shiftst,A.comp,A.opn,A.opr
		) as T2
		inner join #Target S  on t2.initime=S.ShiftStart  and t2.machine = S.machineid
		 and t2.Componentinterface = S.Componentinterface 
		and t2.OperationInterface = S.OperationInterface 
		and T2.OperatorInterface = S.OperatorInterface 

		Update  #Target  set RejectionQty = isnull(RejectionQty,0) - isNull(t2.RejectionQty1,0)
		From
		(
			select T.Machine as machine,T.Shiftst as initime,
			A.comp as Componentinterface,A.opn as OperationInterface, A.opr as OperatorInterface ,
			SUM(A.Rejection_Qty) as RejectionQty1
			from AutodataRejections  A 
			inner join #Target G on A.mc=G.MachineInterface and G.Componentinterface=A.comp and G.OperationInterface=A.opn
			 and G.OperatorInterface = A.opr
			CROSS jOIN #PlannedDownTimesShift T
			WHERE (A.CreatedTS>=T.StartTime  and A.CreatedTS<=T.EndTime)
			and A.Flag= 'Rejection' 
			Group by T.Machine,T.shiftst,A.comp,A.opn,A.opr
		) as T2
		inner join #Target S  on t2.initime=S.ShiftStart  and t2.machine = S.machineid
		 and t2.Componentinterface = S.Componentinterface 
		and t2.OperationInterface = S.OperationInterface 
		and T2.OperatorInterface = S.OperatorInterface 
	
		Update  #Target  set ReworkQty = isnull(ReworkQty,0) - isNull(t2.ReworkQty1,0)
		From
		(
			select T.Machine as machine,T.Shiftst as initime,
			A.comp as Componentinterface,A.opn as OperationInterface, A.opr as OperatorInterface ,
			SUM(A.PartsCount) as ReworkQty1
			from #T_autodata  A 
			inner join #Target G on A.mc=G.MachineInterface and G.Componentinterface=A.comp and G.OperationInterface=A.opn
			 and G.OperatorInterface = A.opr
			CROSS jOIN #PlannedDownTimesShift T
			where (A.datatype=1) AND ( A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime )
			and  (SUBSTRING (G.OperationDescription ,(DATALENGTH(cast(G.OperationDescription as varchar))-2 ), 3 )) ='REW'
			Group by T.Machine,T.shiftst,A.comp,A.opn,A.opr
		) as T2
		inner join #Target S  on t2.initime=S.ShiftStart  and t2.machine = S.machineid
		 and t2.Componentinterface = S.Componentinterface 
		 and t2.OperationInterface = S.OperationInterface 
		 and T2.OperatorInterface = S.OperatorInterface 
	END


   Update  #Target  set TotalProdQty  = (isnull(OkQty,0) + isnull(ReworkQty,0)+ isnull(RejectionQty,0))

/****************************************************************************************/
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_AvgCycletime_4m_PLD')='Y' --ER0363 Added
BEGIN

	UPDATE #Target set ActCycleTime =isnull(ActCycleTime,0) - isNull(TT.PPDT ,0),
	ActLoadUnload = isnull(ActLoadUnload,0) - isnull(LD,0)
	FROM(
		--Production Time in PDT
	Select A.mc,A.comp,A.Opn,A.opr,A.ShiftStart,A.ShiftEnd,Sum
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
				SELECT distinct M.MachineID,
				autodata.MC,autodata.comp,autodata.Opn,autodata.opr,autodata.sttime,autodata.ndtime,autodata.msttime
				,autodata.Cycletime,M.ShiftStart,M.ShiftEnd
				from #T_autodata autodata 
				inner join #Target M on M.machineinterface=Autodata.mc
				and autodata.comp=M.Componentinterface and autodata.Opn=M.OperationInterface
				and M.OperatorInterface = autodata.opr
				where autodata.DataType=1 And autodata.ndtime >M.ShiftStart  AND autodata.ndtime <=M.ShiftEnd
			)A
			CROSS jOIN PlannedDownTimes T 
			WHERE T.Machine=A.MachineID AND
			((A.msttime >= T.StartTime  AND A.ndtime <=T.EndTime)
			OR ( A.msttime < T.StartTime  AND A.ndtime <= T.EndTime AND A.ndtime > T.StartTime )
			OR ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime AND A.ndtime > T.EndTime )
			OR ( A.msttime < T.StartTime  AND A.ndtime > T.EndTime) )
		group by A.mc,A.comp,A.Opn,A.opr,A.ShiftStart,A.ShiftEnd
	)
	as TT INNER JOIN #Target ON TT.mc = #Target.MachineInterface
		and TT.comp = #Target.Componentinterface
			and TT.opn = #Target.OperationInterface 
			and TT.opr = #Target.OperatorInterface 
			and TT.ShiftStart=#Target.ShiftStart
						and TT.ShiftEnd= #Target.ShiftEnd

	--Handle intearction between ICD and PDT for type 1 production record for the selected time period.
		UPDATE  #Target set ActCycleTime =isnull(ActCycleTime,0) + isNull(T2.IPDT ,0) 	FROM	
		(
		Select AutoData.mc,autodata.comp,autodata.Opn,autodata.opr,T1.ShiftStart,T1.ShiftEnd,
		SUM(
		CASE 	
			When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) 
			When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) 
			When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) 
			when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) 
		END) as IPDT
		from #T_autodata autodata INNER Join 
			(Select distinct MachineID,mc,Sttime,NdTime,M.ShiftStart,M.ShiftEnd from #T_autodata autodata
				inner join #Target M on M.machineinterface=Autodata.mc
				and autodata.comp=M.Componentinterface and autodata.Opn=M.OperationInterface 
				and M.OperatorInterface = autodata.opr
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(ndtime > M.ShiftStart) AND (ndtime <= M.ShiftEnd)) as T1
		ON AutoData.mc=T1.mc 
		CROSS jOIN PlannedDownTimes T 
		Where AutoData.DataType=2 And T.Machine=T1.MachineID
		And (( autodata.Sttime >= T1.Sttime )
		And ( autodata.ndtime <= T1.ndtime )
		)
		AND
		((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
		or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
		or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
		or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )))	
		GROUP BY AUTODATA.mc,autodata.comp,autodata.Opn,autodata.opr,T1.ShiftStart,T1.ShiftEnd
		)AS T2  INNER JOIN #Target ON T2.mc = #Target.MachineInterface
			and T2.comp = #Target.Componentinterface
			and T2.opr = #Target.OperatorInterface 
			and T2.opn = #Target.OperationInterface and T2.ShiftStart=#Target.ShiftStart
						and T2.ShiftStart= #Target.ShiftEnd
	
End

/*******************************UtilisedTime and CN***********************************/
UPDATE #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
from
(select      mc,S.Componentinterface, S.OperationInterface,
S.OperatorInterface ,
	sum(case when ( (autodata.msttime>=S.shiftstart) and (autodata.ndtime<=S.ShiftEnd)) then  (cycletime+loadunload)
		 when ((autodata.msttime<S.shiftstart)and (autodata.ndtime>S.shiftstart)and (autodata.ndtime<=S.ShiftEnd)) then DateDiff(second, S.shiftstart, ndtime)
		 when ((autodata.msttime>=S.shiftstart)and (autodata.msttime<S.ShiftEnd)and (autodata.ndtime>S.ShiftEnd)) then DateDiff(second, mstTime, S.ShiftEnd)
		 when ((autodata.msttime<S.shiftstart)and (autodata.ndtime>S.ShiftEnd)) then DateDiff(second, S.shiftstart, S.ShiftEnd) END ) as cycle,S.shiftstart as ShiftStart
		 from #T_autodata autodata inner join #FinalTarget S on autodata.mc=S.MachineInterface  
		 and S.Componentinterface=autodata.comp and S.OperationInterface=autodata.opn
		 and S.OperatorInterface = autodata.opr
		 where (autodata.datatype=1) AND(( (autodata.msttime>=S.shiftstart) and (autodata.ndtime<=S.ShiftEnd))
		 OR ((autodata.msttime<S.shiftstart)and (autodata.ndtime>S.shiftstart)and (autodata.ndtime<=S.ShiftEnd))
		 OR ((autodata.msttime>=S.shiftstart)and (autodata.msttime<S.ShiftEnd)and (autodata.ndtime>S.ShiftEnd))
		 OR((autodata.msttime<S.shiftstart)and (autodata.ndtime>S.ShiftEnd)))
		 group by autodata.mc,S.shiftstart,S.Componentinterface, S.OperationInterface, S.OperatorInterface
		 ) as t2 inner join #FinalTarget on t2.mc = #FinalTarget.machineinterface
		 and t2.Componentinterface = #FinalTarget.Componentinterface 
		and T2.OperatorInterface = #FinalTarget.OperatorInterface 
		 and t2.OperationInterface = #FinalTarget.OperationInterface 
		 and t2.ShiftStart=#FinalTarget.shiftstart

-------For Type2
		UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
		FROM
		(Select AutoData.mc,autodata.comp as Componentinterface,autodata.opn as OperationInterface,
		autodata.opr as OperatorInterface ,
		SUM(
		CASE
			When autodata.sttime <= T1.shiftstart Then datediff(s, T1.shiftstart,autodata.ndtime )
			When autodata.sttime > T1.shiftstart Then datediff(s , autodata.sttime,autodata.ndtime)
		END) as Down,t1.shiftstart as ShiftStart,T1.Ddate as Ddate
		From #T_autodata autodata INNER Join
			(Select mc,autodata.comp,autodata.opn,autodata.opr,Sttime,NdTime,shiftstart,ShiftEnd,Ddate From #T_autodata autodata
				inner join #FinalTarget ST1 ON ST1.MachineInterface=Autodata.mc
		         and ST1.OperatorInterface = autodata.opr
				and ST1.Componentinterface=autodata.comp and ST1.OperationInterface=autodata.opn
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(msttime < shiftstart)And (ndtime > shiftstart) AND (ndtime <= ShiftEnd)
		) as T1 on t1.mc=autodata.mc and t1.comp=autodata.comp and t1.opn=autodata.opn  and t1.opr=autodata.opr
		Where AutoData.DataType=2
		And ( autodata.Sttime > T1.Sttime )
		And ( autodata.ndtime <  T1.ndtime )
		AND ( autodata.ndtime >  T1.shiftstart )
		GROUP BY AUTODATA.mc,T1.shiftstart,T1.Ddate,autodata.comp , autodata.opn,autodata.opr
		)AS T2 Inner Join #FinalTarget on t2.mc = #FinalTarget.machineinterface
		and t2.Componentinterface = #FinalTarget.Componentinterface 
		and T2.OperatorInterface = #FinalTarget.OperatorInterface 
	    and t2.OperationInterface = #FinalTarget.OperationInterface 
		and T2.Ddate = #FinalTarget.Ddate and t2.ShiftStart=#FinalTarget.shiftstart
		--For Type4
		UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
		FROM
		(Select AutoData.mc ,autodata.comp as Componentinterface,autodata.opn as OperationInterface,
		autodata.opr as OperatorInterface ,
		SUM(CASE
			When autodata.sttime >= T1.shiftstart AND autodata.ndtime <= T1.ShiftEnd Then datediff(s , autodata.sttime,autodata.ndtime)
			When autodata.sttime < T1.shiftstart And autodata.ndtime >T1.shiftstart AND autodata.ndtime<=T1.ShiftEnd Then datediff(s, T1.shiftstart,autodata.ndtime )
			When autodata.sttime >= T1.shiftstart AND autodata.sttime<T1.ShiftEnd AND autodata.ndtime>T1.ShiftEnd Then datediff(s,autodata.sttime, T1.ShiftEnd )
			When autodata.sttime<T1.shiftstart AND autodata.ndtime>T1.ShiftEnd   Then datediff(s , T1.shiftstart,T1.ShiftEnd)
		END) as Down,T1.shiftstart as ShiftStart,T1.Ddate as Ddate
		From #T_autodata autodata INNER Join
			(Select mc,autodata.comp,autodata.opn,autodata.opr,Sttime,NdTime,shiftstart,ShiftEnd,Ddate From #T_autodata autodata
				inner join #FinalTarget ST1 ON ST1.MachineInterface =Autodata.mc
				and ST1.Componentinterface=autodata.comp and ST1.OperationInterface=autodata.opn
		        and ST1.OperatorInterface = autodata.opr
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(msttime < shiftstart)And (ndtime >ShiftEnd)
			 ) as T1
		ON AutoData.mc=T1.mc and t1.comp=autodata.comp and t1.opn=autodata.opn and t1.opr=autodata.opr
		Where AutoData.DataType=2
		And (T1.Sttime < autodata.sttime  )
		And ( T1.ndtime >  autodata.ndtime)
		AND (autodata.ndtime  >  T1.shiftstart)
		AND (autodata.sttime  <  T1.ShiftEnd)
		GROUP BY AUTODATA.mc,T1.shiftstart,T1.Ddate,T1.Ddate,autodata.comp , autodata.opn, autodata.opr
		 )AS T2 Inner Join #FinalTarget on t2.mc = #FinalTarget.machineinterface
		and t2.Componentinterface = #FinalTarget.Componentinterface 
	    and t2.OperationInterface = #FinalTarget.OperationInterface 
		and T2.OperatorInterface = #FinalTarget.OperatorInterface 
		and T2.Ddate = #FinalTarget.Ddate and t2.ShiftStart=#FinalTarget.shiftstart
		--Type 3
		UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
		FROM
		(Select AutoData.mc ,autodata.comp as Componentinterface,autodata.opn as OperationInterface,
		autodata.opr as OperatorInterface ,
		SUM(CASE
			When autodata.ndtime > T1.ShiftEnd Then datediff(s,autodata.sttime, T1.ShiftEnd )
			When autodata.ndtime <=T1.ShiftEnd Then datediff(s , autodata.sttime,autodata.ndtime)
		END) as Down,T1.shiftstart as ShiftStart,T1.Ddate as Ddate
		From #T_autodata autodata INNER Join
			(Select mc,autodata.comp,autodata.opn,autodata.opr,Sttime,NdTime,shiftstart,ShiftEnd,Ddate From #T_autodata autodata
				inner join #FinalTarget ST1 ON ST1.MachineInterface =Autodata.mc
				and ST1.Componentinterface=autodata.comp and ST1.OperationInterface=autodata.opn
		        and ST1.OperatorInterface = autodata.opr
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(sttime >= shiftstart)And (ndtime >ShiftEnd) and (sttime< ShiftEnd)
		 ) as T1
		ON AutoData.mc=T1.mc and t1.comp=autodata.comp and t1.opn=autodata.opn and t1.opr=autodata.opr
		Where AutoData.DataType=2
		And (T1.Sttime < autodata.sttime  )
		And ( T1.ndtime >  autodata.ndtime)
		AND (autodata.sttime  <  T1.ShiftEnd)
		GROUP BY AUTODATA.mc,T1.shiftstart,T1.Ddate,autodata.comp , autodata.opn,autodata.opr )AS T2 
		Inner Join #FinalTarget on t2.mc = #FinalTarget.machineinterface
		and t2.Componentinterface = #FinalTarget.Componentinterface 
	    and t2.OperationInterface = #FinalTarget.OperationInterface 
		and T2.OperatorInterface = #FinalTarget.OperatorInterface 
		and t2.Ddate=#FinalTarget.Ddate and t2.ShiftStart=#FinalTarget.shiftstart

----------------------------CN--------------------------------------------------
		--Type 1
		UPDATE #FinalTarget SET CN = isnull(CN,0) + isNull(t2.C1N1,0)
		from
		(select mc,S.Componentinterface, S.OperationInterface, S.OperatorInterface ,
		 SUM((S.StdCycleTime/ISNULL(S.SubOperations,1))*autodata.partscount) C1N1,
		 S.Ddate as date1,S.shiftstart as ShiftStart
		 from #T_autodata autodata
		inner join #FinalTarget S on autodata.mc=S.MachineInterface and S.Componentinterface=autodata.comp and S.OperationInterface=autodata.opn
		and S.OperatorInterface = autodata.opr  
		  where (autodata.sttime>=S.shiftstart)
			and (autodata.ndtime<=S.ShiftEnd)
			and (autodata.datatype=1)
		  group by autodata.mc,S.Ddate,S.shiftstart,S.Componentinterface, S.OperationInterface, S.OperatorInterface
		) as t2 inner join #FinalTarget on t2.mc = #FinalTarget.machineinterface
		and t2.Componentinterface = #FinalTarget.Componentinterface 
	    and t2.OperationInterface = #FinalTarget.OperationInterface
		and T2.OperatorInterface = #FinalTarget.OperatorInterface  
		and t2.date1=#FinalTarget.Ddate and t2.ShiftStart=#FinalTarget.shiftstart
		
		--Type 2
		UPDATE #FinalTarget SET CN = isnull(CN,0) + isNull(t2.C1N1,0)
		from
		(select mc,S.Componentinterface, S.OperationInterface, S.OperatorInterface,
		 SUM((S.StdCycleTime/ISNULL(S.SubOperations,1))*autodata.partscount) C1N1,
		  S.Ddate as date1,S.shiftstart as ShiftStart
		   from #T_autodata autodata 
		inner join #FinalTarget S on autodata.mc=S.MachineInterface and S.Componentinterface=autodata.comp and S.OperationInterface=autodata.opn
		and S.OperatorInterface = autodata.opr  
		where (autodata.sttime<S.shiftstart)
		  and (autodata.ndtime>S.shiftstart)
		  and (autodata.ndtime<=S.ShiftEnd)
		  and (autodata.datatype=1)
		  group by autodata.mc,S.Ddate,S.shiftstart,S.Componentinterface, S.OperationInterface,S.OperatorInterface
		) as t2 inner join #FinalTarget on t2.mc = #FinalTarget.machineinterface
		and t2.Componentinterface = #FinalTarget.Componentinterface 
	    and t2.OperationInterface = #FinalTarget.OperationInterface 
		and T2.OperatorInterface = #FinalTarget.OperatorInterface 
		and t2.date1=#FinalTarget.Ddate and t2.ShiftStart=#FinalTarget.shiftstart


	----------------------------------------------------------------------
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
BEGIN
	
	UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.PlanDT,0)
	from( select T.ShiftSt as intime,T.Machine as machine,
		autodata.comp as Componentinterface,autodata.opn as OperationInterface,
		autodata.opr as OperatorInterface,
		sum (CASE
	WHEN (autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN DateDiff(second,autodata.msttime,autodata.ndtime) --DR0325 Added
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
	group by T.Machine,T.ShiftSt,autodata.comp,autodata.opn,autodata.opr
	) as t2 inner join #FinalTarget S on t2.intime=S.shiftstart and t2.machine=S.machineId
	and t2.Componentinterface = S.Componentinterface 
	and t2.OperationInterface = S.OperationInterface 
	and T2.OperatorInterface = S.OperatorInterface 

	UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)
		FROM	(
		Select T.ShiftSt as intime,AutoData.mc,
		autodata.comp as Componentinterface,autodata.opn as OperationInterface,
		autodata.opr as OperatorInterface,
		SUM(
		CASE 	
			When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
			When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
			When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
			when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		from #T_autodata autodata INNER Join
			(Select mc,autodata.comp,autodata.opn,autodata.opr,Sttime,NdTime,S.shiftstart as StartTime from #T_autodata autodata
			 inner join #FinalTarget S on S.MachineInterface=autodata.mc
			 and S.Componentinterface=autodata.comp and S.OperationInterface=autodata.opn
			 and S.OperatorInterface = autodata.opr
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(msttime >= S.shiftstart) AND (ndtime <= S.ShiftEnd)) as T1
		ON AutoData.mc=T1.mc and t1.comp=autodata.comp and t1.opn=autodata.opn and t1.opr=autodata.opr
		CROSS jOIN #PlannedDownTimesShift T
		Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc
		And (( autodata.Sttime >= T1.Sttime ) 
		And ( autodata.ndtime <= T1.ndtime )
		)
		AND
		((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
		or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
		or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
		or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )
		GROUP BY AUTODATA.mc,T.ShiftSt,autodata.comp,autodata.opn,autodata.opr
		)AS T2  INNER JOIN #FinalTarget ON
	T2.mc = #FinalTarget.MachineInterface and  t2.intime=#FinalTarget.shiftstart
	and t2.Componentinterface = #FinalTarget.Componentinterface 
	and t2.OperationInterface = #FinalTarget.OperationInterface
	and T2.OperatorInterface = #FinalTarget.OperatorInterface  
	

	---mod 12(4)
	/* If production  Records of TYPE-2*/
	UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)
	FROM
	(Select T.ShiftSt as intime,AutoData.mc ,
	autodata.comp as Componentinterface,autodata.opn as OperationInterface,
	autodata.opr as OperatorInterface,
	SUM(
	CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT
	from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join
		(Select mc,autodata.comp,autodata.opn,autodata.opr,Sttime,NdTime,S.shiftstart as StartTime from #T_autodata autodata 
		inner join #FinalTarget S on S.MachineInterface=autodata.mc and S.Componentinterface=autodata.comp and S.OperationInterface=autodata.opn
			 and S.OperatorInterface = autodata.opr
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(msttime < S.shiftstart)And (ndtime > S.shiftstart) AND (ndtime <= S.ShiftEnd)) as T1
	ON AutoData.mc=T1.mc  and t1.comp=autodata.comp and t1.opn=autodata.opn and t1.opr=autodata.opr
	and T1.StartTime=T.ShiftSt 
	Where AutoData.DataType=2  and T.MachineInterface=autodata.mc
	And (( autodata.Sttime > T1.Sttime ) And ( autodata.ndtime <  T1.ndtime )
	AND ( autodata.ndtime >  T1.StartTime )) AND (( T.StartTime >= T1.StartTime )
	And ( T.StartTime <  T1.ndtime ) )
	GROUP BY AUTODATA.mc,T.ShiftSt,autodata.comp,autodata.opn,autodata.opr )AS T2  INNER JOIN #FinalTarget ON
	T2.mc = #FinalTarget.MachineInterface and  t2.intime=#FinalTarget.shiftstart
	and t2.Componentinterface = #FinalTarget.Componentinterface 
	and t2.OperationInterface = #FinalTarget.OperationInterface
	and T2.OperatorInterface = #FinalTarget.OperatorInterface  

	

	/* If production Records of TYPE-3*/
	UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)
	FROM
	(Select T.ShiftSt as intime,AutoData.mc ,
	autodata.comp as Componentinterface,autodata.opn as OperationInterface,
	autodata.opr as OperatorInterface,
	SUM(
	CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT
	from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join 
		(Select mc,autodata.comp,autodata.opn,autodata.opr,Sttime,NdTime,S.shiftstart as StartTime,S.ShiftEnd as EndTime from #T_autodata autodata
		 inner join #FinalTarget S on S.MachineInterface=autodata.mc and S.Componentinterface=autodata.comp and S.OperationInterface=autodata.opn
			 and S.OperatorInterface = autodata.opr
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(sttime >= S.shiftstart)And (ndtime > S.ShiftEnd) and autodata.sttime <S.ShiftEnd
		) as T1
	ON AutoData.mc=T1.mc and t1.comp=autodata.comp and t1.opn=autodata.opn and t1.opr=autodata.opr
	and T1.StartTime=T.ShiftSt
	Where AutoData.DataType=2  and T.MachineInterface=autodata.mc
	And ((T1.Sttime < autodata.sttime  ) And ( T1.ndtime >  autodata.ndtime)
	AND (autodata.sttime  <  T1.EndTime)) AND (( T.EndTime > T1.Sttime ) And ( T.EndTime <=T1.EndTime ) )
	GROUP BY AUTODATA.mc,T.ShiftSt,autodata.comp,autodata.opn,autodata.opr )AS T2   INNER JOIN #FinalTarget ON
	T2.mc = #FinalTarget.MachineInterface and  t2.intime=#FinalTarget.shiftstart
	and t2.Componentinterface = #FinalTarget.Componentinterface 
	and t2.OperationInterface = #FinalTarget.OperationInterface
	and T2.OperatorInterface = #FinalTarget.OperatorInterface   
	
/* If production Records of TYPE-4*/
	UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)
	FROM
	(Select T.ShiftSt as intime,AutoData.mc ,
	autodata.comp as Componentinterface,autodata.opn as OperationInterface,
	autodata.opr as OperatorInterface,
	SUM(
	CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT
	from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join 
		(Select mc,autodata.comp,autodata.opn,autodata.opr,Sttime,NdTime,S.shiftstart as StartTime,S.ShiftEnd as EndTime from #T_autodata autodata 
		inner join #FinalTarget S on S.MachineInterface=autodata.mc and S.Componentinterface=autodata.comp and S.OperationInterface=autodata.opn
			 and S.OperatorInterface = autodata.opr
	    Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And(msttime < S.shiftstart)And (ndtime > S.ShiftEnd)
		) as T1
	ON AutoData.mc=T1.mc and t1.comp=autodata.comp and t1.opn=autodata.opn and t1.opr=autodata.opr
	and T1.StartTime=T.ShiftSt
	Where AutoData.DataType=2 and T.MachineInterface=autodata.mc
	And ( (T1.Sttime < autodata.sttime  ) And ( T1.ndtime >  autodata.ndtime)
	AND (autodata.ndtime  >  T1.StartTime) AND (autodata.sttime  <  T1.EndTime))
	AND (( T.StartTime >=T1.StartTime) And ( T.EndTime <=T1.EndTime ) )
	GROUP BY AUTODATA.mc,T.ShiftSt,autodata.comp,autodata.opn,autodata.opr )AS T2 
	 INNER JOIN #FinalTarget ON
	T2.mc = #FinalTarget.MachineInterface and  t2.intime=#FinalTarget.shiftstart
	and t2.Componentinterface = #FinalTarget.Componentinterface 
	and t2.OperationInterface = #FinalTarget.OperationInterface
	and T2.OperatorInterface = #FinalTarget.OperatorInterface  
	
	END

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN

   UPDATE #FinalTarget SET CN = isnull(CN,0) - isNull(t2.C1N1,0)
	From
	(
		select T.Machine as machine,T.Shiftst as initime,
		A.comp as Componentinterface,A.opn as OperationInterface,
	    A.opr as OperatorInterface,
		SUM((S.StdCycleTime * ISNULL(A.PartsCount,1))/ISNULL(S.SubOperations,1))  C1N1
		from #T_autodata  A 
		inner join #FinalTarget S on A.mc=S.MachineInterface and S.Componentinterface=A.comp and S.OperationInterface=A.opn
		and S.OperatorInterface = A.opr
		CROSS jOIN #PlannedDownTimesShift T
		WHERE A.DataType=1 and T.MachineInterface=A.mc
		AND(A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)
		Group by T.Machine,T.shiftst,A.comp,A.opn,A.opr 
	) as T2
	inner join #FinalTarget S  on t2.initime=S.ShiftStart  and t2.machine = S.machineid
	 and t2.Componentinterface = S.Componentinterface 
	and t2.OperationInterface = S.OperationInterface 
	and T2.OperatorInterface = S.OperatorInterface 
	
END


/*******************************Down Record***********************************/
	UPDATE #FinalTarget SET downtime = isnull(downtime,0) + isNull(t2.down,0)
	from
	(select      mc, S.Componentinterface, S.OperationInterface,
	S.OperatorInterface,
	sum(case when ( (autodata.msttime>=S.shiftstart) and (autodata.ndtime<=S.ShiftEnd)) then  loadunload
	when ((autodata.sttime<S.shiftstart)and (autodata.ndtime>S.shiftstart)and (autodata.ndtime<=S.ShiftEnd)) then DateDiff(second, S.shiftstart, ndtime)
	when ((autodata.msttime>=S.shiftstart)and (autodata.msttime<S.ShiftEnd)and (autodata.ndtime>S.ShiftEnd)) then DateDiff(second, stTime, S.ShiftEnd)
	when ((autodata.msttime<S.shiftstart)and (autodata.ndtime>S.ShiftEnd)) then DateDiff(second, S.shiftstart, S.ShiftEnd) END ) as down,S.shiftstart as ShiftStart
	from #T_autodata autodata 
	inner join #FinalTarget S on autodata.mc=S.MachineInterface and S.Componentinterface=autodata.comp and S.OperationInterface=autodata.opn
	and S.OperatorInterface = autodata.opr
	inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
	where (autodata.datatype=2) AND(( (autodata.msttime>=S.shiftstart) and (autodata.ndtime<=S.ShiftEnd))
	OR ((autodata.msttime<S.shiftstart)and (autodata.ndtime>S.shiftstart)and (autodata.ndtime<=S.ShiftEnd))
	OR ((autodata.msttime>=S.shiftstart)and (autodata.msttime<S.ShiftEnd)and (autodata.ndtime>S.ShiftEnd))
	OR((autodata.msttime<S.shiftstart)and (autodata.ndtime>S.ShiftEnd))) 
	group by autodata.mc,S.shiftstart, S.Componentinterface, S.OperationInterface, S.OperatorInterface
	) as t2 inner join #FinalTarget on t2.mc = #FinalTarget.machineinterface 
	and t2.Componentinterface = #FinalTarget.Componentinterface 
	and t2.OperationInterface = #FinalTarget.OperationInterface
	and T2.OperatorInterface = #FinalTarget.OperatorInterface  
	and t2.ShiftStart=#FinalTarget.shiftstart


If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN

	UPDATE #FinalTarget SET downtime = isnull(downtime,0) - isNull(t2.PldDown,0)
	from(
		select T.ShiftSt  as ShiftStart,T.Machine as machine,autodata.comp as Componentinterface,autodata.opn as OperationInterface,
		autodata.opr as OperatorInterface,
		SUM
		       (CASE
			WHEN (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN autodata.loadunload
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PldDown
		from #T_autodata autodata  
		inner join #FinalTarget S on autodata.mc=S.MachineInterface and S.Componentinterface=autodata.comp and S.OperationInterface=autodata.opn
		and S.OperatorInterface = autodata.opr
		CROSS jOIN #PlannedDownTimesShift T
		INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID
		WHERE autodata.DataType=2  and T.machineinterface=autodata.mc  
		AND (
		(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
		OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
		OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
		OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
		)
   group by T.Machine,T.ShiftSt,autodata.comp,autodata.opn,autodata.opr
   ) as t2 inner join #FinalTarget S on t2.ShiftStart=S.shiftstart and t2.machine=S.machineId
   and t2.Componentinterface = S.Componentinterface and t2.OperationInterface = S.OperationInterface 
  and T2.OperatorInterface = S.OperatorInterface 

END
--------------------------------------------------------------------------
Update #Target set ActCycleTime=(isnull(ActCycleTime,0)/isnull(Pcount,1))* isnull(SubOperations,1),
Actloadunload=(isnull(Actloadunload,0)/isnull(Pcount,1))* isnull(suboperations,1) 
from #Target
where Pcount>0

/*
update #Target
set OperatorId = t1.OperatorID,
Operator = t1.OperatorName
from (
select machineinterface,ComponentID,OperationId,ShiftStart,ShiftEnd,
   (SELECT STUFF((SELECT DISTINCT ','  + EI.Employeeid  
   FROM #T_autodata a 
    inner Join Employeeinformation EI on EI.interfaceid=a.opr   
	where a.mc  = t.machineinterface and t.Componentinterface=a.comp and t.OperationInterface=a.opn 
	and (( (a.msttime>=T.ShiftStart) and (a.ndtime<=T.ShiftEnd)) OR ((a.msttime<T.ShiftStart)and (a.ndtime>T.ShiftStart)and (a.ndtime<=T.ShiftEnd))  
	OR ((a.msttime>=T.ShiftStart)and (a.msttime<T.ShiftEnd)and (a.ndtime>T.ShiftEnd)) OR((a.msttime<T.ShiftStart)and (a.ndtime>T.ShiftEnd))) 
	FOR XML PATH (''),  TYPE, ROOT).value('.', 'varchar(max)'), 1, 1, '')
 	)as OperatorID,
	(SELECT STUFF((SELECT DISTINCT ','  + EI.Name  
   FROM #T_autodata a 
    inner Join Employeeinformation EI on EI.interfaceid=a.opr   
	where a.mc  = t.machineinterface and t.Componentinterface=a.comp and t.OperationInterface=a.opn 
	and (( (a.msttime>=T.ShiftStart) and (a.ndtime<=T.ShiftEnd)) OR ((a.msttime<T.ShiftStart)and (a.ndtime>T.ShiftStart)and (a.ndtime<=T.ShiftEnd))  
	OR ((a.msttime>=T.ShiftStart)and (a.msttime<T.ShiftEnd)and (a.ndtime>T.ShiftEnd)) OR((a.msttime<T.ShiftStart)and (a.ndtime>T.ShiftEnd))) 
	FOR XML PATH (''),  TYPE, ROOT).value('.', 'varchar(max)'), 1, 1, '')
 	)as OperatorName
	from #Target t
    )t1 inner join #Target t2 on t1.machineinterface  = t2.machineinterface 
	and t1.ShiftStart  = t2.ShiftStart and t1.ShiftEnd  = t2.ShiftEnd
	and  t1.ComponentID = t2.ComponentID and  t1.OperationId = t2.OperationId
		and T2.OperatorInterface = t1.OperatorInterface 
*/
 Update  #FinalTarget  set  
 ActCycleTime = T.ActCycleTime ,
 Actloadunload = T.Actloadunload ,
 TargetProd = T.TargetProd ,
 Pcount = T.Pcount , 
 OkQty  = T.OkQty ,
 ReworkQty = T.ReworkQty ,
 RejectionQty = T.RejectionQty ,
 TotalProdQty =  T.TotalProdQty
 from 
 (
 select ShiftStart,MachineID ,ComponentID  ,OperationId ,OperatorID,
 ActCycleTime,Actloadunload,TargetProd,Pcount,OkQty,ReworkQty,RejectionQty,TotalProdQty
 from #Target
 )T inner join #FinalTarget F on F.ShiftStart = T.ShiftStart
 and F.MachineID = T.MachineID
 and F.ComponentID = T.ComponentID
 and F.OperationId =T.OperationId
 and F.OperatorID = T.OperatorId


 Update  #FinalTarget  set OperatorEffi = (CN/UtilisedTime) *100 
 where UtilisedTime <> 0
  Update  #FinalTarget  set MachineEffi = (TotalProdQty / TargetProd)  *100
 where TargetProd <> 0

 Select Ddate,Shift,ShiftStart,ShiftEnd,MachineID ,ComponentID  ,OperationId ,Operator, OperatorID,OperationDescription,
 dbo.f_formattime(StdCycleTime, @timeformat) as StdCycleTime ,
 dbo.f_formattime(ActCycleTime,  @timeformat) as AvgCycleTime,
 dbo.f_formattime( Actloadunload, @timeformat) as Avgloadunload,
  dbo.f_formattime(ActCycleTime + Actloadunload, @timeformat) as ActCycleTime,
  isnull(pcount,0) as partcount,
-- dbo.f_formattime(UtilisedTime, @timeformat) as ActCycleTime,
  round(isnull(TargetProd,0),0) as TargetProd,
  isnull(OkQty,0) as OkQty,isnull(ReworkQty,0) as ReworkQty,isnull(RejectionQty,0) as RejectionQty,isnull(TotalProdQty,0) as TotalProdQty, 
  dbo.f_formattime(UtilisedTime, 'ss') as UtilisedTime ,dbo.f_formattime(DownTime, 'ss') as DownTime ,
  isnull(OperatorEffi,0) as OperatorEffi  ,isnull(MachineEffi,0) as MachineEffi,Remark,CN,UtilisedTime as UT 
 from #FinalTarget 
 Order by Ddate,Shift,MachineID,id,ComponentID,OperationId,OperationDescription

END
