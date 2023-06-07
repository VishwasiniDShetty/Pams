/****** Object:  Procedure [dbo].[S_GetOperatorEfficiencyReport_Bhavani]    Committed by VersionSQL https://www.versionsql.com ******/

/***************************************************************************************************
-- Author:		Anjana C V
-- Create date: 12 Nov 2018
-- Modified date: 3 Nov 2018
-- Description:  Get Operator Efficiency Report Data for Bhavani

--[S_GetOperatorEfficiencyReport_Bhavani]'2017-10-30 06:00:00 ','2017-10-30 14:00:00'
--[S_GetOperatorEfficiencyReport_Bhavani] '2017-10-30 06:00:00 ','2017-10-30 14:00:00','317'
--[S_GetOperatorEfficiencyReport_Bhavani] '2017-10-30 06:00:00 ','2017-10-30 14:00:00','PCT'
**************************************************************************************************/

CREATE PROCEDURE [dbo].[S_GetOperatorEfficiencyReport_Bhavani]
	@StartTime datetime,
	@Endtime datetime,
	@Operatorid nvarchar(25)=''
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

declare @timeformat as nvarchar(30)
Declare @StrSql AS nvarchar(4000)
Declare @StrOpr AS nvarchar(255)
SELECT @StrSql=''
SELECT @StrOpr=''


CREATE TABLE #OprProdData(
	OperatorID nvarchar(50),
	Interfaceid nvarchar(50) NOT NULL,
	ComponentName nvarchar(100),
	CompInterface nvarchar(100) NOT NULL,
	ProductionEfficiency float,
	AvailabilityEfficiency float,
	OverallEfficiency float,
	Components float,
	UtilisedTime float,
	ManagementLoss float,
	DownTime float,
	CN float,
	isgrp int,
	MLDown float
)

ALTER TABLE #OprProdData

ADD PRIMARY KEY CLUSTERED
(
	Interfaceid,CompInterface ASC
)ON [PRIMARY]

CREATE TABLE #MCOO_pCounts
(
	MachineID NVarChar(50),
	ComponentID Nvarchar(50),
	CompInterface nvarchar(100),
	OperationNo Int,
	Operator_IId NVarChar(50),
	pCount Int DEFAULT 0,
	CycleTime Int
	
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


IF ISNULL(@Operatorid,'')<>''
BEGIN
SELECT @StrOpr=' AND E.Employeeid like  N'''+'%'+ @Operatorid +'%'+''''
END

select @timeformat ='ss'
select @timeformat = isnull((select valueintext from cockpitdefaults where parameter='timeformat'),'ss')
if (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')
begin
select @timeformat = 'ss'
end



Select @strsql=''
		select @strsql ='insert into #T_autodata '
		select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,
		                           ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id
		                         from autodata where (( sttime >='''+ convert(nvarchar(25),@StartTime,120)+''' and ndtime <= '''+ convert(nvarchar(25),@EndTime,120)+''' ) OR '
		select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@StartTime,120)+''' and ndtime >'''+ convert(nvarchar(25),@EndTime,120)+''' )OR '
		select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@StartTime,120)+''' and ndtime >'''+ convert(nvarchar(25),@StartTime,120)+'''
						 and ndtime<='''+convert(nvarchar(25),@EndTime,120)+''' )
						  OR ( sttime >='''+convert(nvarchar(25),@StartTime,120)+''' 
		                and ndtime >'''+ convert(nvarchar(25),@EndTime,120)+''' and sttime<'''+convert(nvarchar(25),@EndTime,120)+''' ) )'
		print @strsql
		exec (@strsql)


--SELECT @StrSql='INSERT INTO #OprProdData('
--		SELECT @StrSql=@StrSql+' OperatorID ,Interfaceid , ProductionEfficiency ,AvailabilityEfficiency ,'
--		SELECT @StrSql=@StrSql+' OverallEfficiency ,Components ,UtilisedTime ,ManagementLoss ,DownTime ,CN,isgrp)'
--		SELECT @StrSql=@StrSql+' SELECT E.Employeeid,E.interfaceid,0,0,0,0,0,0,0,0,E.operate 
--		FROM employeeinformation E
--		where E.interfaceid >''0''
--		 '
--		SELECT @StrSql=@StrSql+@StrOpr
--		EXEC(@StrSql)



SELECT @StrSql='INSERT INTO #OprProdData ('
		SELECT @StrSql=@StrSql+' OperatorID ,Interfaceid ,ComponentName,CompInterface,ProductionEfficiency ,AvailabilityEfficiency ,'
		SELECT @StrSql=@StrSql+' OverallEfficiency ,Components ,UtilisedTime ,ManagementLoss ,DownTime ,CN,isgrp)'
		SELECT @StrSql=@StrSql+' SELECT DISTINCT E.Employeeid,E.interfaceid,C.Componentid,C.InterfaceID,
		0,0,0,0,0,0,0,0,E.operate 
		FROM employeeinformation E 
		LEFT JOIN #T_autodata A ON E.interfaceid = A.OPR 
		INNER JOIN  componentinformation C ON  A.comp = C.InterfaceID 
		where E.interfaceid >''0''
		 '
		SELECT @StrSql=@StrSql+@StrOpr
		EXEC(@StrSql)
		--print @StrSql

---mod 4
/* Planned Down times for the given time period */
	SELECT IDENTITY(int, 1, 1) As SlNo,
		CASE When StartTime<@StartTime Then @StartTime Else StartTime End As StartTime,
		CASE When EndTime>@EndTime Then @EndTime Else EndTime End As EndTime,Machine,M.Interfaceid as MachineInterface,
		DownReason
		INTO #PlannedDownTimes
	FROM PlannedDownTimes inner join machineInformation M on M.MachineId=PlannedDownTimes.Machine
	WHERE (
	(StartTime >= @StartTime  AND EndTime <=@EndTime)
	OR ( StartTime < @StartTime  AND EndTime <= @EndTime AND EndTime > @StartTime )
	OR ( StartTime >= @StartTime   AND StartTime <@EndTime AND EndTime > @EndTime )
	OR ( StartTime < @StartTime  AND EndTime > @EndTime) ) and pdtstatus=1
	ORDER BY StartTime
--mod 4



--SELECT * FROM #OprProdData ORDER BY OperatorID ,Interfaceid ,ComponentName,CompInterface
/***********************Components details***************************************************************************************/
/*UPDATE #OprProdData SET  ComponentName = T2.ComponentName,
CompInterface =T2.CompInterface
From
( SELECT A1.OPR,	
(
SELECT  STUFF(
( SELECT DISTINCT  '/'  + (r.componentid)   
		from componentinformation r 
		INNER JOIN #T_autodata A2 ON  A2.comp = r.InterfaceID 
		where --(A2.datatype=1) AND 
		(
	(A2.msttime>=@StartTime and A2.ndtime<=@EndTime)OR
	(A2.msttime<@StartTime and A2.ndtime>@StartTime and A2.ndtime<=@EndTime)OR
	(A2.msttime>=@StartTime and A2.msttime<@EndTime and A2.ndtime>@EndTime)OR
	((A2.msttime<@StartTime and A2.ndtime>@EndTime)))
	AND A2.opr=A1.OPR
	FOR XML PATH(''), TYPE, ROOT).value('root[1]', 'nvarchar(max)'), 1, 1, '')
) As ComponentName,
(
SELECT  STUFF(
( SELECT DISTINCT  '/'  + (r.InterfaceID)   
		from componentinformation r 
		INNER JOIN #T_autodata A3 ON  A3.comp = r.InterfaceID 
		where --(A3.datatype=1) AND 
		(
	(A3.msttime>=@StartTime and A3.ndtime<=@EndTime)OR
	(A3.msttime<@StartTime and A3.ndtime>@StartTime and A3.ndtime<=@EndTime)OR
	(A3.msttime>=@StartTime and A3.msttime<@EndTime and A3.ndtime>@EndTime)OR
	((A3.msttime<@StartTime and A3.ndtime>@EndTime)))
	AND A3.opr=A1.OPR
	 FOR XML PATH(''), TYPE, ROOT).value('root[1]', 'nvarchar(max)'), 1, 1, '')
) As CompInterface
	from #T_autodata A1
	where --(A1.datatype=1) AND 
	(
	(A1.msttime>=@StartTime and A1.ndtime<=@EndTime)OR
	(A1.msttime<@StartTime and A1.ndtime>@StartTime and A1.ndtime<=@EndTime)OR
	(A1.msttime>=@StartTime and A1.msttime<@EndTime and A1.ndtime>@EndTime)OR
	((A1.msttime<@StartTime and A1.ndtime>@EndTime)))
	Group By A1.opr
) as T2 inner join #OprProdData on T2.opr = #OprProdData.interfaceid

*/


/***************************************************************************************************************/
--Get Utilised Time
--#TYPE-1
--commented for mod 4: combined all types, from here

UPDATE #OprProdData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
From
(	select A.opr, A.COMP,
	sum(
		CASE
		WHEN (A.msttime>=@StartTime and A.ndtime<=@EndTime) THEN (cycletime+loadunload)
		WHEN (A.msttime<@StartTime and A.ndtime>@StartTime and A.ndtime<=@EndTime)THEN DateDiff(second, @StartTime, ndtime)
		WHEN (A.msttime>=@StartTime and A.msttime<@EndTime and A.ndtime>@EndTime) THEN DateDiff(second, mstTime, @Endtime)
		ELSE DateDiff(second, @StartTime, @EndTime) END
	) As cycle
	from #T_autodata A
	where (A.datatype=1) AND (
	(A.msttime>=@StartTime and A.ndtime<=@EndTime)OR
	(A.msttime<@StartTime and A.ndtime>@StartTime and A.ndtime<=@EndTime)OR
	(A.msttime>=@StartTime and A.msttime<@EndTime and A.ndtime>@EndTime)OR
	((A.msttime<@StartTime and A.ndtime>@EndTime)))
	Group By A.opr, A.COMP
) as T2 inner join #OprProdData on T2.opr = #OprProdData.interfaceid AND T2.COMP=#OprProdData.CompInterface

/* Fetching Down Records from Production Cycle  */
/* If Down Records of TYPE-2*/
UPDATE  #OprProdData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
FROM
(Select #T_autodata.Opr ,#T_autodata.COMP,
SUM(
CASE
	When #T_autodata.sttime <= @StartTime Then datediff(s, @StartTime,#T_autodata.ndtime )
	When #T_autodata.sttime > @StartTime Then datediff(s , #T_autodata.sttime,#T_autodata.ndtime)
END) as Down
From #T_autodata INNER Join
	(Select Opr,COMP,Sttime,NdTime From #T_autodata
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(msttime < @StartTime)And (ndtime > @StartTime) AND (ndtime <= @EndTime)) as T1
ON #T_autodata.Opr=T1.Opr AND #T_autodata.comp =T1.comp
Where #T_autodata.DataType=2
And ( #T_autodata.Sttime > T1.Sttime )
And ( #T_autodata.ndtime <  T1.ndtime )
AND ( #T_autodata.ndtime >  @StartTime )
GROUP BY #T_autodata.opr,#T_autodata.COMP)AS T2 Inner Join #OprProdData on t2.Opr = #OprProdData.interfaceid AND T2.COMP=#OprProdData.CompInterface

/* If Down Records of TYPE-3*/
UPDATE  #OprProdData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
FROM
(Select #T_autodata.Opr ,#T_autodata.COMP,
SUM(CASE
	When #T_autodata.ndtime > @EndTime Then datediff(s,#T_autodata.sttime, @EndTime )
	When #T_autodata.ndtime <=@EndTime Then datediff(s , #T_autodata.sttime,#T_autodata.ndtime)
END) as Down
From #T_autodata INNER Join
	(Select Opr,comp,Sttime,NdTime From #T_autodata
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(sttime >= @StartTime)  and (sttime<@EndTime) And (ndtime > @EndTime)) as T1
ON #T_autodata.Opr=T1.Opr AND #T_autodata.comp =T1.comp
Where #T_autodata.DataType=2
And (T1.Sttime < #T_autodata.sttime  )
And ( T1.ndtime >  #T_autodata.ndtime)
AND (#T_autodata.sttime  <  @EndTime)
GROUP BY #T_autodata.Opr ,#T_autodata.COMP)AS T2 Inner Join #OprProdData on t2.Opr = #OprProdData.interfaceid AND T2.COMP=#OprProdData.CompInterface

/* If Down Records of TYPE-4*/
UPDATE  #OprProdData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
FROM
(Select #T_autodata.Opr ,#T_autodata.COMP,
 SUM(CASE
	When #T_autodata.sttime >= @StartTime AND #T_autodata.ndtime <= @EndTime Then datediff(s , #T_autodata.sttime,#T_autodata.ndtime)--type 1
	When #T_autodata.sttime < @StartTime AND #T_autodata.ndtime > @StartTime And #T_autodata.ndtime<=@EndTime Then datediff(s, @StartTime,#T_autodata.ndtime )--type 2
	When #T_autodata.sttime>=@StartTime and #T_autodata.sttime<@EndTime and #T_autodata.ndtime > @EndTime then datediff(s,#T_autodata.sttime, @EndTime )--type3
	When #T_autodata.sttime<@StartTime AND #T_autodata.ndtime>@EndTime   Then datediff(s , @StartTime,@EndTime) --type 4
END) as Down	
From #T_autodata INNER Join
	(Select Opr,comp,Sttime,NdTime From #T_autodata
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(msttime < @StartTime)And (ndtime > @EndTime) ) as T1
ON #T_autodata.Opr=T1.Opr AND #T_autodata.comp =T1.comp
Where #T_autodata.DataType=2
And (T1.Sttime < #T_autodata.sttime  )
And ( T1.ndtime >  #T_autodata.ndtime)
AND (#T_autodata.ndtime  >  @StartTime)
AND (#T_autodata.sttime  <  @EndTime)
GROUP BY #T_autodata.Opr,#T_autodata.COMP
)AS T2 Inner Join #OprProdData on t2.Opr = #OprProdData.interfaceid AND T2.COMP=#OprProdData.CompInterface

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
BEGIN
	
	SELECT @StrSql=''
	SELECT @StrSql=	'UPDATE  #OprProdData SET UtilisedTime = isnull(UtilisedTime,0)- isNull(TT.PPDT ,0)
		FROM(
		--Production Time in PDT
		SELECT A.Opr,a.comp,SUM
			(CASE
			WHEN A.msttime >= T.StartTime  AND A.ndtime <=T.EndTime  THEN (A.cycletime+A.loadunload)
			WHEN ( A.msttime < T.StartTime  AND A.ndtime <= T.EndTime  AND A.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,A.ndtime)
			WHEN ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime  AND A.ndtime > T.EndTime  ) THEN DateDiff(second,A.msttime,T.EndTime )
			WHEN ( A.msttime < T.StartTime  AND A.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END)  as PPDT
		FROM #T_autodata A
		Inner Join EmployeeInformation E on A.Opr=E.InterfaceID 
		inner jOIN #PlannedDownTimes T on T.MachineInterface=A.mc
		WHERE A.DataType=1 '
	SELECT @StrSql=@StrSql + @StrOpr
	SELECT @StrSql=@StrSql +' AND( (A.msttime >= T.StartTime  AND A.ndtime <=T.EndTime)
			OR ( A.msttime < T.StartTime  AND A.ndtime <= T.EndTime AND A.ndtime > T.StartTime )
			OR ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime AND A.ndtime > T.EndTime )
			OR ( A.msttime < T.StartTime  AND A.ndtime > T.EndTime) )
			AND((A.msttime >= ''' + convert(nvarchar(20),@StartTime)+'''  AND A.ndtime <=''' + convert(nvarchar(20),@EndTime)+''')
			OR ( A.msttime < ''' + convert(nvarchar(20),@StartTime)+'''  AND A.ndtime <= ''' + convert(nvarchar(20),@EndTime)+''' AND A.ndtime > ''' + convert(nvarchar(20),@StartTime)+''' )
			OR ( A.msttime >= ''' + convert(nvarchar(20),@StartTime)+'''   AND A.msttime <''' + convert(nvarchar(20),@EndTime)+''' AND A.ndtime > ''' + convert(nvarchar(20),@EndTime)+''' )
			OR ( A.msttime < ''' + convert(nvarchar(20),@StartTime)+'''  AND A.ndtime > ''' + convert(nvarchar(20),@EndTime)+''') )
		Group by A.Opr,A.COMP
	)
	 as TT Inner Join #OprProdData on TT.Opr = #OprProdData.interfaceid AND TT.COMP= #OprProdData.CompInterface'
	Exec (@StrSql)

	--Handle intearction between ICD and PDT for type 1 production record for the selected time period.

	UPDATE  #OprProdData SET UtilisedTime = isnull(UtilisedTime,0)+ isNull(TT.IPDT ,0)  	
	FROM	(
	Select AutoData.opr,AutoData.COMP,
	SUM(
	CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT
	From #T_autodata AutoData INNER Join
		(
		Select opr,COMP,mc,Sttime,NdTime From #T_autodata AutoData
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(msttime >= @StartTime) AND (ndtime <= @EndTime)
		) as T1
	ON AutoData.mc=T1.mc  AND AutoData.COMP=T1.COMP and T1.opr=autodata.opr CROSS jOIN #PlannedDownTimes T
	Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc
	And (( autodata.Sttime > T1.Sttime )
	And ( autodata.ndtime <  T1.ndtime )
	)
	AND
	((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
	or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
	or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
	or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )
	GROUP BY AUTODATA.opr,AutoData.COMP
	)as TT Inner Join #OprProdData on TT.Opr = #OprProdData.interfaceid  AND TT.COMP= #OprProdData.CompInterface
	
	/* Fetching Down Records from Production Cycle  */
	/* If production  Records of TYPE-2*/
	UPDATE  #OprProdData SET UtilisedTime = isnull(UtilisedTime,0)+ isNull(TT.IPDT ,0)	FROM	(
		Select AutoData.opr,AUTODATA.COMP,
		SUM(
		CASE 	
			When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
			When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
			When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
			when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		From #T_autodata AutoData INNER Join
			(
			Select opr,COMP,mc,Sttime,NdTime From #T_autodata AutoData
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(msttime < @StartTime)And (ndtime > @StartTime) AND (ndtime <= @EndTime)) as T1
		ON AutoData.mc=T1.mc and T1.opr=autodata.opr and T1.COMP=autodata.COMP  CROSS jOIN #PlannedDownTimes T
		Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc
		And (( autodata.Sttime > T1.Sttime )
		And ( autodata.ndtime <  T1.ndtime )
		AND ( autodata.ndtime >  @StartTime )
		)
		AND
		(( T.StartTime >= @StartTime )
		And ( T.StartTime <  T1.ndtime ) )
		GROUP BY AutoData.opr,AUTODATA.COMP
	)as TT Inner Join #OprProdData on TT.Opr = #OprProdData.interfaceid AND TT.COMP= #OprProdData.CompInterface
	
	/* If production Records of TYPE-3*/
	UPDATE  #OprProdData SET UtilisedTime = isnull(UtilisedTime,0)+ isNull(TT.IPDT ,0)
	FROM
	(Select AutoData.opr,AUTODATA.COMP,
	SUM(
	CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT
	From #T_autodata AutoData INNER Join
		(Select opr,COMP,mc,Sttime,NdTime From #T_autodata AutoData
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(sttime >= @StartTime)And (ndtime > @EndTime) and autodata.sttime <@EndTime) as T1
	ON AutoData.mc=T1.mc and T1.opr=autodata.opr and T1.COMP=autodata.COMP CROSS jOIN #PlannedDownTimes T
	Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc
	And ((T1.Sttime < autodata.sttime  )
	And ( T1.ndtime >  autodata.ndtime)
	AND (autodata.msttime  <  @EndTime))
	AND
	(( T.EndTime > T1.Sttime )
	And ( T.EndTime <=@EndTime ) )
	GROUP BY AutoData.opr,AUTODATA.COMP)as TT Inner Join #OprProdData on TT.Opr = #OprProdData.interfaceid AND TT.COMP= #OprProdData.CompInterface
	
	
	/* If production Records of TYPE-4*/
	UPDATE  #OprProdData SET UtilisedTime = isnull(UtilisedTime,0)+ isNull(TT.IPDT ,0)
	FROM
	(Select AutoData.opr,AUTODATA.COMP,
	SUM(
	CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT
	From #T_autodata AutoData INNER Join
		(Select opr,COMP,mc,Sttime,NdTime From #T_autodata AutoData
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(msttime < @StartTime)And (ndtime > @EndTime)) as T1
	ON AutoData.mc=T1.mc and T1.opr=autodata.opr and T1.COMP=autodata.COMP CROSS jOIN #PlannedDownTimes T
	Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc
	And ( (T1.Sttime < autodata.sttime  )
		And ( T1.ndtime >  autodata.ndtime)
		AND (autodata.ndtime  >  @StartTime)
		AND (autodata.sttime  <  @EndTime)) AND
	(( T.StartTime >=@StartTime)
	And ( T.EndTime <=@EndTime )  )
	GROUP BY AutoData.opr,AUTODATA.COMP )as TT Inner Join #OprProdData on TT.Opr = #OprProdData.interfaceid AND TT.COMP= #OprProdData.CompInterface
END
/*******************************Down Record***********************************/

------------------------------ Begins :: MLoss Caln including theshold by SKallur ----------------------------
--mod 4
---Below IF condition added by Mrudula for mod 4. TO get the ML if 'Ignore_Dtime_4m_PLD'<>"Y"
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' 
or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' 
and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y')
BEGIN
--mod 4
	--TYPE-1
	UPDATE #OprProdData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
	from
	(select      opr,COMP,
		sum( CASE
	WHEN loadunload >ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0) > 0 THEN ISNULL(downcodeinformation.Threshold,0)
	ELSE loadunload
	END) loss
	from #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
	where (autodata.msttime>=@StartTime)and (autodata.ndtime<=@EndTime)and (autodata.datatype=2)and (downcodeinformation.availeffy = 1)
	group by autodata.opr,COMP
	) as t2 inner join #OprProdData on t2.opr = #OprProdData.interfaceid AND T2.COMP= #OprProdData.CompInterface

	--TYPE-2
	UPDATE #OprProdData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
	from
	(select      opr,COMP,
		sum(CASE
	WHEN DateDiff(second, @StartTime, ndtime)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0) > 0 THEN ISNULL(downcodeinformation.Threshold,0)
	
	ELSE DateDiff(second, @StartTime, ndtime)
	END) loss
	from #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
	where (autodata.sttime<@StartTime)
	and (autodata.ndtime>@StartTime)
	and (autodata.ndtime<=@EndTime)
	and (autodata.datatype=2)
	and (downcodeinformation.availeffy = 1)
	group by autodata.opr,COMP
	) as t2 inner join #OprProdData on t2.opr = #OprProdData.interfaceid  AND T2.COMP= #OprProdData.CompInterface

	--TYPE-3
	UPDATE #OprProdData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
	from
	(select      opr,COMP,
		sum(CASE
	WHEN DateDiff(second, stTime, @Endtime)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0) > 0 THEN ISNULL(downcodeinformation.Threshold,0)
	ELSE DateDiff(second, stTime, @Endtime)
	END) loss
	from #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
	where (autodata.msttime>=@StartTime)
	and (autodata.sttime<@EndTime)
	and (autodata.ndtime>@EndTime)
	and (autodata.datatype=2)
	and (downcodeinformation.availeffy = 1)
	group by autodata.opr,COMP
	) as t2 inner join #OprProdData on t2.opr = #OprProdData.interfaceid  AND T2.COMP= #OprProdData.CompInterface

	--TYPE-4
	UPDATE #OprProdData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
	from
	(select opr,COMP,
		sum(CASE
	WHEN DateDiff(second, @StartTime, @Endtime)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0) > 0 THEN ISNULL(downcodeinformation.Threshold,0)
	ELSE DateDiff(second, @StartTime, @Endtime)
	END) loss
	from #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
	where autodata.msttime<@StartTime
	and autodata.ndtime>@EndTime
	and (autodata.datatype=2)
	and (downcodeinformation.availeffy = 1)
	group by autodata.opr,COMP
	) as t2 inner join #OprProdData on t2.opr = #OprProdData.interfaceid  AND T2.COMP= #OprProdData.CompInterface

	--Down time calculation
	--TYPE 1
	UPDATE #OprProdData SET downtime = isnull(downtime,0) + isNull(t2.down,0)
	from
	(select opr,COMP,
		sum(loadunload) down
	from #T_autodata autodata
	where (autodata.msttime>=@StartTime)
	and (autodata.ndtime<=@EndTime)
	and (autodata.datatype=2)
	group by autodata.opr,COMP
	) as t2 inner join #OprProdData on t2.opr = #OprProdData.interfaceid  AND T2.COMP= #OprProdData.CompInterface

	--#TYPE-2
	UPDATE #OprProdData SET downtime = isnull(downtime,0) + isNull(t2.down,0)
	from
	(select opr,COMP,
		sum(DateDiff(second, @StartTime, ndtime)) down
	from #T_autodata autodata
	where (autodata.sttime<@StartTime)
	and (autodata.ndtime>@StartTime)
	and (autodata.ndtime<=@EndTime)
	and (autodata.datatype=2)
	group by autodata.opr,COMP

	) as t2 inner join #OprProdData on t2.opr = #OprProdData.interfaceid  AND T2.COMP= #OprProdData.CompInterface

	--#TYPE-3
	UPDATE #OprProdData SET downtime = isnull(downtime,0) + isNull(t2.down,0)
	from
	(select opr,COMP,
		sum(DateDiff(second, stTime, @Endtime)) down
	from #T_autodata autodata
	where (autodata.msttime>=@StartTime)
	and (autodata.sttime<@EndTime)
	and (autodata.ndtime>@EndTime)
	and (autodata.datatype=2)group by autodata.opr,COMP
	) as t2 inner join #OprProdData on t2.opr = #OprProdData.interfaceid  AND T2.COMP= #OprProdData.CompInterface

	--#TYPE-4
	UPDATE #OprProdData SET downtime = isnull(downtime,0) + isNull(t2.down,0)
	from
	(select opr,COMP,
		sum(DateDiff(second, @StartTime, @EndTime)) down
	from #T_autodata autodata
	where autodata.msttime<@StartTime
	and autodata.ndtime>@EndTime
	and (autodata.datatype=2)
	group by autodata.opr,COMP
	) as t2 inner join #OprProdData on t2.opr = #OprProdData.interfaceid  AND T2.COMP= #OprProdData.CompInterface
---mod 4
END

---mod 4
---mod 4: Handling interaction between PDT and downtime . Also interaction between PDT and Management Loss
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN
	---step 1
	
	UPDATE #OprProdData SET downtime = isnull(downtime,0) + isNull(t2.down,0)
	from
	(select opr,COMP,
	sum(
			CASE
	        WHEN  autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime  THEN  loadunload
			WHEN (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  THEN DateDiff(second, @StartTime, ndtime)
			WHEN (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)  THEN DateDiff(second, stTime, @Endtime)
			WHEN autodata.msttime<@StartTime and autodata.ndtime>@EndTime   THEN DateDiff(second, @StartTime, @EndTime)
			END
		)AS down
	from #T_autodata autodata inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
	where autodata.datatype=2 AND
	(
	(autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)
	OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
	OR (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
	OR (autodata.msttime<@StartTime and autodata.ndtime>@EndTime )
	) AND (downcodeinformation.availeffy = 0)
	group by autodata.opr,COMP
	) as t2 inner join #OprProdData on t2.opr = #OprProdData.interfaceid  AND T2.COMP= #OprProdData.CompInterface

	---step 2
	---mod 4 checking for (downcodeinformation.availeffy = 0) to get the overlapping PDT and Downs which is not ML
	UPDATE #OprProdData SET downtime = isnull(downtime,0) - isNull(T2.PPDT ,0)
	FROM(
		--Production PDT
		SELECT autodata.opr,autodata.COMP, SUM
		   (CASE
			WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PPDT
		FROM #T_autodata AutoData CROSS jOIN #PlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)
			 AND (downcodeinformation.availeffy = 0)
		group by autodata.opr,autodata.COMP
	) as t2 inner join #OprProdData on t2.opr = #OprProdData.interfaceid  AND T2.COMP= #OprProdData.CompInterface

	---step 3
	---Management loss calculation
	---IN T1 Select get all the downtimes which is of type management loss
	---IN T2  get the time to be deducted from the cycle if the cycle is overlapping with the PDT. And it should be ML record
	---In T3 Get the real management loss , and time to be considered as real down for each cycle(by comaring with the ML threshold)
	---In T4 consolidate everything at machine level and update the same to #CockpitData for ManagementLoss and MLDown
	
	UPDATE #OprProdData SET  ManagementLoss = isnull(ManagementLoss,0) + isNull(t4.Mloss,0),MLDown=isNull(MLDown,0)+isNull(t4.Dloss,0)
	from
	(
	select T3.opr,T3.comp,sum(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss from 
	(
	select   t1.opr,T1.COMP,t1.id,T1.mc,T1.Threshold,
	case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0
	then DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)- isnull(T1.Threshold ,0)
	else 0 End  as Dloss,
	case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0
	then isnull(T1.Threshold,0)
	else (DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)) End  as Mloss
	 from
	
	(   select id,mc,comp,opn,opr,D.threshold,
		case when autodata.sttime<@StartTime then @StartTime else sttime END as sttime,
	       	case when ndtime>@EndTime then @EndTime else ndtime END as ndtime
		from #T_autodata autodata
		inner join downcodeinformation D
		on autodata.dcode=D.interfaceid where autodata.datatype=2 AND
		(
		(autodata.sttime>=@StartTime  and  autodata.ndtime<=@EndTime)
		OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
		OR (autodata.sttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
		OR (autodata.sttime<@StartTime and autodata.ndtime>@EndTime )
		) AND (D.availeffy = 1)) as T1 	
	left outer join
	(SELECT autodata.id,autodata.opr,autodata.comp,
		       sum(CASE
			WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PPDT
		FROM #T_autodata AutoData CROSS jOIN #PlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)
			AND (downcodeinformation.availeffy = 1) group  by autodata.id,autodata.opr,autodata.comp ) as T2 on T1.id=T2.id 
			) as T3  group by T3.opr,T3.comp
	) as t4  inner join #OprProdData on t4.opr = #OprProdData.interfaceid  AND T4.COMP= #OprProdData.CompInterface

	UPDATE #OprProdData  SET downtime = isnull(downtime,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)
END
---mod 4: Till here Handling interaction between PDT and downtime . Also interaction between PDT and Management Loss
---mod 4:If Ignore_Dtime_4m_PLD<> Y and Ignore_Dtime_4m_PLD<> N
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y' AND (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
BEGIN
	UPDATE #OprProdData SET downtime = isnull(downtime,0) - isNull(T2.PPDT ,0)
	FROM(
		--Production PDT
		SELECT autodata.opr, AUTODATA.COMP,SUM
		       (CASE
			WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PPDT
		FROM #T_autodata AutoData CROSS jOIN #PlannedDownTimes T
		Inner Join DownCodeInformation D ON AutoData.DCode = D.InterfaceID
		WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND D.DownID=(SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD') AND
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)
		group by autodata.opr,AUTODATA.COMP
	) as t2 inner join #OprProdData on t2.opr = #OprProdData.interfaceid  AND T2.COMP= #OprProdData.CompInterface
END
---mod 4:If Ignore_Dtime_4m_PLD<> Y and Ignore_Dtime_4m_PLD<> N
------------------------------ :: Ends :: ------------------------------------------
--CN
UPDATE #OprProdData SET CN = isnull(CN,0) + isNull(t2.C1N1,0)
from
(select opr,COMP,
SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))* autodata.partscount) C1N1
FROM #T_autodata autodata INNER JOIN
componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID AND
componentoperationpricing.componentid = componentinformation.componentid
--mod 2
inner join machineinformation on machineinformation.interfaceid=autodata.mc
and componentoperationpricing.machineid=machineinformation.machineid
--mod 2
where autodata.datatype=1 AND
((autodata.sttime>=@StartTime and autodata.ndtime<=@EndTime )OR
(autodata.sttime<@StartTime and autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime))
group by autodata.opr,COMP
) as t2 inner join #OprProdData on t2.opr = #OprProdData.interfaceid AND T2.COMP= #OprProdData.CompInterface

/**************************************************************************************************/
/*		FOLLOWING CODE IS ADDED BY SANGEETA KALLUR*/
INSERT INTO #MCOO_pCounts(MachineID ,ComponentID,CompInterface ,OperationNo ,Operator_IId ,pCount,CycleTime)
SELECT M.MachineID  ,C.ComponentID,A.COMP,O.OperationNo ,Opr,
CEILING (CAST(SUM(A.partscount) AS Float)/ISNULL(O.SubOperations,1)) ,O.CycleTime
From #T_autodata A
Inner Join MachineInformation M ON A.Mc=M.interfaceid
Inner join componentinformation C on A.Comp=C.interfaceid
Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid and C.Componentid=O.componentid
--mod 2
and O.machineid=M.machineid
--mod 2
Where (A.datatype=1)AND (A.ndtime>@StartTime  and A.ndtime<=@EndTime)
Group by M.MachineID,C.ComponentID,O.OperationNo,A.Opr,O.SubOperations,O.CycleTime,A.COMP
---mod 4: Neglect count overlapping with PDT
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	UPDATE #MCOO_pCounts SET pCount = ISNULL(pCount,0) - ISNULL(T2.PLD_Comp,0)
	from
	(
		select  M.MachineID ,C.ComponentID,O.OperationNo,A.Opr As Operator_IId,A.COMP,
		CEILING(CAST(Sum(ISNULL(A.PartsCount,1)) AS Float)/ISNULL(O.SubOperations,1)) AS PLD_Comp
		from  #T_autodata A
		Inner Join MachineInformation M ON A.Mc=M.interfaceid
		Inner join componentinformation C on A.Comp=C.interfaceid
	   	Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid and C.Componentid=O.componentid
		and O.MachineId=M.MachineId
		inner jOIN #PlannedDownTimes T on T.Machine=M.MachineID WHERE A.DataType=1
			AND (A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)
			AND (A.ndtime > @StartTime  AND A.ndtime <=@EndTime)
		Group by M.MachineID,C.ComponentID,O.OperationNo,A.Opr,O.SubOperations
	) as T2 inner join #MCOO_pCounts on #MCOO_pCounts.MachineID=T2.MachineID AND #MCOO_pCounts.Componentid=T2.Componentid 
	AND #MCOO_pCounts.OperationNo=T2.OperationNo AND #MCOO_pCounts.Operator_IId=T2.Operator_IId AND #MCOO_pCounts.CompInterface=T2.COMP
	-- mod 4 Ignore count from CN calculation which is over lapping with PDT
	UPDATE #OprProdData SET CN = isnull(CN,0) - isNull(t2.C1N1,0)
	From
	(
		select opr,A.COMP,SUM((O.cycletime * ISNULL(A.PartsCount,1))/ISNULL(O.SubOperations,1))  C1N1
		From #T_autodata A
		Inner join machineinformation M on M.interfaceid=A.mc
		Inner join componentinformation C ON A.Comp=C.interfaceid
		Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID
		Cross jOIN #PlannedDownTimes T
		WHERE A.DataType=1 AND T.MachineInterface=A.mc
		AND(A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)
		AND(A.ndtime > @StartTime  AND A.ndtime <=@EndTime)
		Group by opr,COMP
	) as T2
	 inner join #OprProdData on t2.opr = #OprProdData.interfaceid  AND T2.COMP=#OprProdData.CompInterface
END
---mod 4
UPDATE #OprProdData SET Components = ISNULL(Tt.OCount,0)
FROM
(
	SELECT Operator_IId,CompInterface,
	Sum(pCount)As OCount   From #MCOO_pCounts GROUP BY Operator_IId,CompInterface
) AS Tt Inner Join #OprProdData ON #OprProdData.Interfaceid=Tt.Operator_IId AND #OprProdData.CompInterface=Tt.CompInterface

IF ISNULL(@Operatorid,'')<>''
BEGIN
	update #OprProdData set Components=T1.comp ,UtilisedTime=T1.Util,ManagementLoss=T1.Mgmt ,
	DownTime =T1.Dtime,	CN =T1.CN1
	from (
	select CompInterface,sum(Components) as comp,sum(UtilisedTime) as Util,sum(ManagementLoss) as Mgmt,
	sum(DownTime) as Dtime,sum(CN) as CN1 from #OprProdData 
	GROUP BY CompInterface
	) as T1 inner join #OprProdData on T1.COMP=#OprProdData.CompInterface
	where #OprProdData.OperatorID=@Operatorid 
	delete from #OprProdData where #OprProdData.OperatorID<>@Operatorid
END
ELSE
BEGIN
		
		declare @CurOperatorIDG as nvarchar(50)
		declare @CurCompInterface as nvarchar(50)
		declare @CurComponents as float
		declare @CurUtilisedTime as float
		declare @CurManagementLoss as float
		declare @CurDownTime as float
		declare @CurCN as float
		declare @InOpr as nvarchar(50)
		declare @sep as nvarchar(2)
		Select @sep =Groupseperator2 from smartdataportrefreshdefaults
		
		Declare TmpCursor Cursor For SELECT OperatorID,CompInterface,Components ,UtilisedTime ,ManagementLoss,DownTime,CN FROM #OprProdData where isgrp=1
		OPEN  TmpCursor
		--FETCH NEXT FROM TmpCursorICD INTO @CurMachineID,@CurDate,@CurStrtTime,@CurEndTime
		FETCH NEXT FROM TmpCursor INTO @CurOperatorIDG,@CurCompInterface,@CurComponents ,@CurUtilisedTime,@CurManagementLoss,@CurDownTime ,@CurCN
		WHILE @@FETCH_STATUS=0
		BEGIN---cursor
			while  substring(@CurOperatorIDG,1,(case when CHARINDEX ( @sep ,@CurOperatorIDG)=0 then len(@CurOperatorIDG) else (CHARINDEX ( @sep ,@CurOperatorIDG)-1 ) end) ) <> ''
			begin
				--print  @CurOperatorIDG
				set @InOpr=substring(@CurOperatorIDG,1,(case when CHARINDEX ( @sep ,@CurOperatorIDG)=0 then len(@CurOperatorIDG) else (CHARINDEX ( @sep ,@CurOperatorIDG)-1 ) end) )
				
				If not exists (select * from #OprProdData where operatorid=@InOpr AND CompInterface=@CurCompInterface)
				Begin
					Insert into #OprProdData(OperatorID,CompInterface,Components,UtilisedTime,ManagementLoss,DownTime,CN,isgrp)
					values(@InOpr,@CurCompInterface,@CurComponents,@CurUtilisedTime,@CurManagementLoss,@CurDownTime,@CurCN,0)
				End
				Else
				Begin
					update #OprProdData set Components=Components+@CurComponents ,UtilisedTime=UtilisedTime+@CurUtilisedTime,ManagementLoss=ManagementLoss+@CurManagementLoss,
					DownTime =DownTime+@CurDownTime,CN =CN+@CurCN where #OprProdData.OperatorID=@InOpr  AND CompInterface=@CurCompInterface
				End
							
				if CHARINDEX ( @sep ,@CurOperatorIDG) <>0
				begin
					set @CurOperatorIDG=substring(@CurOperatorIDG,CHARINDEX(@sep, @CurOperatorIDG)+ 1,LEN(@CurOperatorIDG) - CHARINDEX(@sep, @CurOperatorIDG)+ 1)
				end
				else
				begin
					set @CurOperatorIDG=''
				end
				--select @CurOperatorIDG
			end
			FETCH NEXT FROM TmpCursor INTO @CurOperatorIDG,@CurCompInterface,@CurComponents ,@CurUtilisedTime,@CurManagementLoss,@CurDownTime ,@CurCN
			
			
		END---cursor
close TmpCursor
deallocate TmpCursor
	delete from #OprProdData where isgrp=1
END

----Mod1
--Calculate Efficiencies
UPDATE #OprProdData
SET
	ProductionEfficiency = (CN/UtilisedTime) ,
	AvailabilityEfficiency = (UtilisedTime)/(UtilisedTime + DownTime - ManagementLoss)
	WHERE UtilisedTime <> 0
UPDATE #OprProdData
SET
	OverAllEfficiency = (ProductionEfficiency * AvailabilityEfficiency)*100,
	ProductionEfficiency = ProductionEfficiency * 100 ,
	AvailabilityEfficiency = AvailabilityEfficiency * 100
SELECT
Operatorid as OperatorID,
Name as OperatorName,
ProductionEfficiency,
AvailabilityEfficiency,
OverAllEfficiency,
ComponentName as PartNumber,
Components as Qty,
--CN,
--UtilisedTime,
dbo.f_FormatTime(UtilisedTime,@timeformat) as UtilisedTime,
--dbo.f_FormatTime(ManagementLoss,@timeformat) as ManagementLoss,
dbo.f_FormatTime(DownTime,@timeformat) as DownTime
--,CN,UtilisedTime
--,@StartTime as StartTime,
--@EndTime as EndTime
FROM #OprProdData INNER JOIN Employeeinformation on #OprProdData.Operatorid = Employeeinformation.employeeid
WHERE Components > 0 OR DownTime > 0 order by operatorid asc,ComponentName 


END
