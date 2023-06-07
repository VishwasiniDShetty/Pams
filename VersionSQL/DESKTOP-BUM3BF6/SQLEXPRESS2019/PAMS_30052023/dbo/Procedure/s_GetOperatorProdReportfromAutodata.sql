/****** Object:  Procedure [dbo].[s_GetOperatorProdReportfromAutodata]    Committed by VersionSQL https://www.versionsql.com ******/

/*******************************************************************************************************
--Procedure altered by Sangeeta Kallur on 16-Feb-06
--To include Threshold(Down) in ManagementLoss Calculation
-- Machine, DownReason, component change length from 20 to 50 17-feb-2006
Changed By Sangeeta Kallur on 01-July-2006
Change in Utilised Time Caln to support down  within Production Cycle
Changed By SSK on 10-July-2006
To SubOperation Concept at CO Level
Chaned Caln CN,Components ie Count CalCulation.
Procedure Altered By SSK on 06-Oct-2006 to include Plane Level Concept
Procedure Altered By SSK on 06-Dec-2006 :
	To Remove Constraint Name & add it as Primary Key
Procedure Changed By Sangeeta Kallur on 26-FEB-2007 :
	[MAINI Req] :Production Count Exception for multispindle Machines.
Mod 1:- Procedure altered by Mrudula,Shilpa for nr0043 to support OPertaor Grouping
mod 2 :- ER0181 By Kusuma M.H on 13-May-2009.2) Modify all the procedures accordingly. Qualify machine wherever we are making use of component and opeartion no.
mod 3 :- ER0182 By Kusuma M.H on 13-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
mod 4 :- By Mrudula M. Rao on 12-mar-2009.ER0210 Introduce PDT on 5150.
	1) Handle PDT at Machine Level.
DR0236 - By SwathiKS on 23-Jun-2010 :: Use proper conditions in case statements to remove icd's from type 4 production records.
********************************************************************************************************/
CREATE                                PROCEDURE [dbo].[s_GetOperatorProdReportfromAutodata]
	@StartTime datetime,
	@Endtime datetime,
	@Operatorid nvarchar(25)='',
	@PlantID NVarChar(50)=''
AS
BEGIN
declare @timeformat as nvarchar(30)
Declare @StrSql AS nvarchar(4000)
Declare @StrOpr AS nvarchar(255)
Declare @StrOPlant AS nvarchar(255)
SELECT @StrSql=''
SELECT @StrOpr=''
SELECT @StrOPlant=''
CREATE TABLE #OprProdData(
	OperatorID nvarchar(50),
	Interfaceid nvarchar(50) PRIMARY KEY,
	ProductionEfficiency float,
	AvailabilityEfficiency float,
	OverallEfficiency float,
	Components float,
	UtilisedTime float,
	ManagementLoss float,
	DownTime float,
	CN float,
	isgrp int,
	--mod 4
	MLDown float
	---mod 4
)
CREATE TABLE #MCOO_pCounts
(
	MachineID NVarChar(50),
	ComponentID Nvarchar(50),
	OperationNo Int,
	Operator_IId NVarChar(50),
	pCount Int DEFAULT 0,
	CycleTime Int
	
)
CREATE TABLE #Exceptions
(
	MachineID NVarChar(50),
	ComponentID Nvarchar(50),
	OperationNo Int,
	StartTime DateTime,
	EndTime DateTime,
	IdealCount Int,
	ActualCount Int,
	ExCount Int DEFAULT 0
)
IF ISNULL(@Operatorid,'')<>''
BEGIN
---SELECT @StrOpr=' AND E.Employeeid = '''+ @Operatorid +''''
---mod 3
--SELECT @StrOpr=' AND E.Employeeid like  '''+'%'+ @Operatorid +'%'+''''
SELECT @StrOpr=' AND E.Employeeid like  N'''+'%'+ @Operatorid +'%'+''''
---mod 3
END
IF ISNULL(@PlantID,'')<>''
BEGIN
---mod 3
--SELECT @StrOPlant=' where PE.PlantID='''+ @PlantID +''' '
SELECT @StrOPlant=' where PE.PlantID= N'''+ @PlantID +''' '
---mod 3
END
select @timeformat ='ss'
select @timeformat = isnull((select valueintext from cockpitdefaults where parameter='timeformat'),'ss')
if (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')
begin
select @timeformat = 'ss'
end
if isnull(@PlantID,'')<>''
BEGIN
		SELECT @StrSql='INSERT INTO #OprProdData('
		SELECT @StrSql=@StrSql+' OperatorID ,Interfaceid ,ProductionEfficiency ,AvailabilityEfficiency ,OverallEfficiency ,'
		SELECT @StrSql=@StrSql+' Components ,UtilisedTime ,ManagementLoss ,DownTime ,CN,isgrp )'
		SELECT @StrSql=@StrSql+' SELECT E.Employeeid,E.interfaceid,0,0,0,0,0,0,0,0,E.operate '
		SELECT @StrSql=@StrSql+' FROM employeeinformation E Inner Join PlantEmployee PE ON PE.Employeeid=E.Employeeid'
		SELECT @StrSql=@StrSql+ @StrOPlant+ @StrOpr
		EXEC(@StrSql)
		--print @StrSql
END
ELSE
BEGIN
		SELECT @StrSql='INSERT INTO #OprProdData('
		SELECT @StrSql=@StrSql+' OperatorID ,Interfaceid ,ProductionEfficiency ,AvailabilityEfficiency ,'
		SELECT @StrSql=@StrSql+' OverallEfficiency ,Components ,UtilisedTime ,ManagementLoss ,DownTime ,CN,isgrp)'
		SELECT @StrSql=@StrSql+' SELECT E.Employeeid,E.interfaceid,0,0,0,0,0,0,0,0,E.operate FROM employeeinformation E'
		SELECT @StrSql=@StrSql+' where E.interfaceid >''0'''
		SELECT @StrSql=@StrSql+@StrOpr
		EXEC(@StrSql)
		--print @StrSql
END
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
/**************************************************************************************************************/
/* 			FOLLOWING SECTION IS ADDED BY SANGEETA KALLUR					*/
SELECT @StrSql = 'INSERT INTO #Exceptions(MachineID ,ComponentID,OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,ExCount )
		SELECT Ex.MachineID ,Ex.ComponentID,Ex.OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,0
		From ProductionCountException Ex
		Inner Join MachineInformation M ON Ex.MachineID=M.MachineID
		Inner Join ComponentInformation C ON Ex.ComponentID=C.ComponentID
		Inner Join Componentoperationpricing O ON Ex.OperationNo=O.OperationNo AND C.ComponentID=O.ComponentID '
		---mod 2		
		SELECT @StrSql = @StrSql + ' and O.MachineId=Ex.MachineId '
		---mod 2
		SELECT @StrSql = @StrSql + ' WHERE  M.MultiSpindleFlag=1 AND '
		SELECT @StrSql = @StrSql + ' ((Ex.StartTime>=  ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@EndTime)+''' )
		OR (Ex.StartTime< ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@EndTime)+''')
		OR(Ex.StartTime>= ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@EndTime)+''' AND Ex.StartTime< ''' + convert(nvarchar(20),@EndTime)+''')
		OR(Ex.StartTime< ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@EndTime)+''' ))'
		Exec (@strsql)
IF ( SELECT Count(*) from #Exceptions ) <> 0
BEGIN
	UPDATE #Exceptions SET StartTime=@StartTime WHERE (StartTime<@StartTime)AND EndTime>@StartTime
	UPDATE #Exceptions SET EndTime=@EndTime WHERE (EndTime>@EndTime AND StartTime<@EndTime )
	
	Select @StrSql = 'UPDATE #Exceptions SET ExCount=ISNULL(T2.Comp,0) From
	(
		SELECT T1.MachineID AS MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime AS StartTime,T1.EndTime AS EndTime,
		SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp
	 	From (
			select MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,comp,opn,Tt1.StartTime,Tt1.EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from autodata
			Inner Join MachineInformation   ON autodata.MC=MachineInformation.InterfaceID
			Inner Join EmployeeInformation E  ON autodata.Opr=E.InterfaceID
			Inner Join ComponentInformation  ON autodata.Comp = ComponentInformation.InterfaceID
			Inner Join ComponentOperationPricing on autodata.Opn=ComponentOperationPricing.InterfaceID And ComponentInformation.ComponentID=ComponentOperationPricing.ComponentID '
			---mod 2		
			SELECT @StrSql = @StrSql + ' and ComponentOperationPricing.MachineId=machineinformation.MachineId '
			---mod 2
			SELECT @StrSql = @StrSql + 'Inner Join (
				Select MachineID,ComponentID,OperationNo,StartTime,EndTime From #Exceptions
			)AS Tt1 ON Tt1.MachineID=MachineInformation.MachineID AND Tt1.ComponentID = ComponentInformation.ComponentID AND Tt1.OperationNo= ComponentOperationPricing.OperationNo and Tt1.MachineID=ComponentOperationPricing.MachineID
			Where (autodata.ndtime>Tt1.StartTime) AND (autodata.ndtime<=Tt1.EndTime) and (autodata.datatype=1) '
	Select @StrSql = @StrSql+ @StrOpr
	Select @StrSql = @StrSql+' Group by MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,Tt1.StartTime,Tt1.EndTime,comp,opn
		) as T1
	   	Inner join componentinformation C on T1.Comp=C.interfaceid
	   	Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid '
	---mod 2		
	SELECT @StrSql = @StrSql + ' Inner join machineinformation M on T1.MachineId = M.MachineId   and O.MachineId=M.MachineId '
	---mod 2
	SELECT @StrSql = @StrSql + ' GROUP BY T1.MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime,t1.EndTime
	)AS T2
	WHERE  #Exceptions.StartTime=T2.StartTime AND #Exceptions.EndTime=T2.EndTime
	AND #Exceptions.MachineID=T2.MachineID AND #Exceptions.ComponentID = T2.ComponentID AND #Exceptions.OperationNo=T2.OperationNo'
	Exec(@StrSql)
	
	---mod 4
	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
	BEGIN
		Select @StrSql =''
		Select @StrSql ='UPDATE #Exceptions SET ExCount=ISNULL(ExCount,0) - ISNULL(T3.Comp,0)
		From
		(
			SELECT T2.MachineID AS MachineID,T2.ComponentID,T2.OperationNo,T2.StartTime AS StartTime,T2.EndTime AS EndTime,
			SUM(CEILING (CAST(T2.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp
			From
			(
				select MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,comp,opn,
				Max(T1.XStartTime)StartTime,Max(T1.XEndTime)EndTime,T1.PLD_StartTime,T1.PLD_EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from autodata
				Inner Join MachineInformation   ON autodata.MC=MachineInformation.InterfaceID
				Inner Join EmployeeInformation E  ON autodata.Opr=E.InterfaceID
				Inner Join ComponentInformation  ON autodata.Comp = ComponentInformation.InterfaceID
				Inner Join ComponentOperationPricing on autodata.Opn=ComponentOperationPricing.InterfaceID And ComponentInformation.ComponentID=ComponentOperationPricing.ComponentID
				Inner Join	
				(
					SELECT MachineID,ComponentID,OperationNo,Ex.StartTime As XStartTime, Ex.EndTime AS XEndTime,
					CASE
						WHEN (Td.StartTime< Ex.StartTime And Td.EndTime<=Ex.EndTime AND Td.EndTime>Ex.StartTime) THEN Ex.StartTime
						WHEN  (Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime) THEN Ex.StartTime
						ELSE Td.StartTime
					END AS PLD_StartTime,
					CASE
						WHEN (Td.StartTime>= Ex.StartTime And Td.StartTime <Ex.EndTime AND Td.EndTime>Ex.EndTime) THEN Ex.EndTime
						WHEN  (Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime) THEN Ex.EndTime
						ELSE  Td.EndTime
					END AS PLD_EndTime		
					From #Exceptions AS Ex inner JOIN #PlannedDownTimes AS Td on Td.Machine=Ex.MachineId
					Where ((Td.StartTime>=Ex.StartTime And Td.EndTime <=Ex.EndTime)OR
					(Td.StartTime< Ex.StartTime And Td.EndTime<=Ex.EndTime AND Td.EndTime>Ex.StartTime)OR
					(Td.StartTime>= Ex.StartTime And Td.StartTime <Ex.EndTime AND Td.EndTime>Ex.EndTime)OR
					(Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime))'
			Select @StrSql = @StrSql + ' )AS T1 ON T1.MachineID=MachineInformation.MachineID AND T1.ComponentID = ComponentInformation.ComponentID AND T1.OperationNo= ComponentOperationPricing.OperationNo and T1.MachineID=ComponentOperationPricing.MachineID
				Where (autodata.ndtime>T1.PLD_StartTime AND autodata.ndtime<=T1.PLD_EndTime) and (autodata.datatype=1)
			AND (autodata.ndtime > ''' + convert(nvarchar(20),@StartTime)+''' AND autodata.ndtime<=''' + convert(nvarchar(20),@EndTime)+''' )'
			Select @StrSql = @StrSql + @StrOpr
			Select @StrSql = @StrSql+' Group by MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,T1.PLD_StartTime,T1.PLD_EndTime,comp,opn
			)AS T2
			Inner join MachineInformation on MachineInformation.MachineId=T2.MachineID
			Inner join componentinformation C on T2.Comp=C.interfaceid
			Inner join ComponentOperationPricing O ON T2.Opn=O.interfaceid and C.Componentid=O.componentid
			and MachineInformation.MachineId=O.MachineId
			GROUP BY T2.MachineID,T2.ComponentID,T2.OperationNo,T2.StartTime,t2.EndTime
		)As T3
		WHERE  #Exceptions.StartTime=T3.StartTime AND #Exceptions.EndTime=T3.EndTime
		AND #Exceptions.MachineID=T3.MachineID AND #Exceptions.ComponentID = T3.ComponentID AND #Exceptions.OperationNo=T3.OperationNo'
		EXEC(@StrSql)
	
	END
	---mod 4
	UPDATE #Exceptions SET ExCount=ExCount-((ExCount * ActualCount)/ISNULL(IdealCount,0))
END
/***************************************************************************************************************/
--Get Utilised Time
--#TYPE-1
--commented for mod 4: combined all types, from here
/*UPDATE #OprProdData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
from
(select     opr,
	sum(cycletime+loadunload) as cycle
from autodata
where (autodata.msttime>=@StartTime)
and (autodata.ndtime<=@EndTime)
and (autodata.datatype=1)
group by autodata.opr
) as t2 inner join #OprProdData on t2.opr = #OprProdData.interfaceid
--#TYPE-2
UPDATE #OprProdData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
from
(select  opr,
sum(DateDiff(second, @StartTime, ndtime)) cycle
from autodata
where (autodata.msttime<@StartTime)
and (autodata.ndtime>@StartTime)
and (autodata.ndtime<=@EndTime)
and (autodata.datatype=1)
group by autodata.opr
) as t2 inner join #OprProdData on t2.opr = #OprProdData.interfaceid
--#TYPE3
UPDATE #OprProdData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
from
(select  opr,
sum(DateDiff(second, mstTime, @Endtime)) cycle
from autodata
where (autodata.msttime>=@StartTime)
and (autodata.msttime<@EndTime)
and (autodata.ndtime>@EndTime)
and (autodata.datatype=1)
group by autodata.opr
) as t2 inner join #OprProdData on t2.opr = #OprProdData.interfaceid
--#TYPE-4
UPDATE #OprProdData SET UtilisedTime = isnull(UtilisedTime,0) + isnull(t2.cycle,0)
from
(select opr,
sum(DateDiff(second, @StartTime, @EndTime)) cycle
from autodata
where (autodata.msttime<@StartTime)
and (autodata.ndtime>@EndTime)
and (autodata.datatype=1)
group by autodata.opr
)as t2 inner join #OprProdData on t2.opr = #OprProdData.interfaceid */
--Commented till here for mod 4. Combining all types
--#TYPE-1,2,3,4
UPDATE #OprProdData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
From
(	select opr,
	sum(
		CASE
		WHEN (A.msttime>=@StartTime and A.ndtime<=@EndTime) THEN (cycletime+loadunload)
		WHEN (A.msttime<@StartTime and A.ndtime>@StartTime and A.ndtime<=@EndTime)THEN DateDiff(second, @StartTime, ndtime)
		WHEN (A.msttime>=@StartTime and A.msttime<@EndTime and A.ndtime>@EndTime) THEN DateDiff(second, mstTime, @Endtime)
		ELSE DateDiff(second, @StartTime, @EndTime) END
	) As cycle
	from autodata A
	where (A.datatype=1) AND (
	(A.msttime>=@StartTime and A.ndtime<=@EndTime)OR
	(A.msttime<@StartTime and A.ndtime>@StartTime and A.ndtime<=@EndTime)OR
	(A.msttime>=@StartTime and A.msttime<@EndTime and A.ndtime>@EndTime)OR
	((A.msttime<@StartTime and A.ndtime>@EndTime)))
	Group By A.opr
) as T2 inner join #OprProdData on T2.opr = #OprProdData.interfaceid
/* Fetching Down Records from Production Cycle  */
/* If Down Records of TYPE-2*/
UPDATE  #OprProdData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
FROM
(Select AutoData.Opr ,
SUM(
CASE
	When autodata.sttime <= @StartTime Then datediff(s, @StartTime,autodata.ndtime )
	When autodata.sttime > @StartTime Then datediff(s , autodata.sttime,autodata.ndtime)
END) as Down
From AutoData INNER Join
	(Select Opr,Sttime,NdTime From AutoData
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(msttime < @StartTime)And (ndtime > @StartTime) AND (ndtime <= @EndTime)) as T1
ON AutoData.Opr=T1.Opr
Where AutoData.DataType=2
And ( autodata.Sttime > T1.Sttime )
And ( autodata.ndtime <  T1.ndtime )
AND ( autodata.ndtime >  @StartTime )
GROUP BY AUTODATA.opr)AS T2 Inner Join #OprProdData on t2.Opr = #OprProdData.interfaceid
/* If Down Records of TYPE-3*/
UPDATE  #OprProdData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
FROM
(Select AutoData.Opr ,
SUM(CASE
	When autodata.ndtime > @EndTime Then datediff(s,autodata.sttime, @EndTime )
	When autodata.ndtime <=@EndTime Then datediff(s , autodata.sttime,autodata.ndtime)
END) as Down
From AutoData INNER Join
	(Select Opr,Sttime,NdTime From AutoData
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(sttime >= @StartTime)  and (sttime<@EndTime) And (ndtime > @EndTime)) as T1
ON AutoData.Opr=T1.Opr
Where AutoData.DataType=2
And (T1.Sttime < autodata.sttime  )
And ( T1.ndtime >  autodata.ndtime)
AND (autodata.sttime  <  @EndTime)
GROUP BY AUTODATA.Opr)AS T2 Inner Join #OprProdData on t2.Opr = #OprProdData.interfaceid
/* If Down Records of TYPE-4*/
UPDATE  #OprProdData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
FROM
(Select AutoData.Opr ,
--DR0236 - By SwathiKS on 23-Jun-2010 FROM HERE
--SUM(CASE
--	When autodata.sttime < @StartTime AND autodata.ndtime<=@EndTime Then datediff(s, @StartTime,autodata.ndtime )
--	When autodata.ndtime >= @EndTime AND autodata.sttime>@StartTime Then datediff(s,autodata.sttime, @EndTime )
--	When autodata.sttime >= @StartTime AND
--	     autodata.ndtime <= @EndTime Then datediff(s , autodata.sttime,autodata.ndtime)
--	When autodata.sttime<@StartTime AND autodata.ndtime>@EndTime   Then datediff(s , @StartTime,@EndTime)
--END) as Down
 SUM(CASE
	When autodata.sttime >= @StartTime AND autodata.ndtime <= @EndTime Then datediff(s , autodata.sttime,autodata.ndtime)--type 1
	When autodata.sttime < @StartTime AND autodata.ndtime > @StartTime And autodata.ndtime<=@EndTime Then datediff(s, @StartTime,autodata.ndtime )--type 2
	When autodata.sttime>=@StartTime and Autodata.sttime<@EndTime and autodata.ndtime > @EndTime then datediff(s,autodata.sttime, @EndTime )--type3
	When autodata.sttime<@StartTime AND autodata.ndtime>@EndTime   Then datediff(s , @StartTime,@EndTime) --type 4
END) as Down	
--DR0236 - By SwathiKS on 23-Jun-2010 TILL HERE
From AutoData INNER Join
	(Select Opr,Sttime,NdTime From AutoData
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(msttime < @StartTime)And (ndtime > @EndTime) ) as T1
ON AutoData.Opr=T1.Opr
Where AutoData.DataType=2
And (T1.Sttime < autodata.sttime  )
And ( T1.ndtime >  autodata.ndtime)
AND (autodata.ndtime  >  @StartTime)
AND (autodata.sttime  <  @EndTime)
GROUP BY AUTODATA.Opr
)AS T2 Inner Join #OprProdData on t2.Opr = #OprProdData.interfaceid
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
BEGIN
	
	SELECT @StrSql=''
	SELECT @StrSql=	'UPDATE  #OprProdData SET UtilisedTime = isnull(UtilisedTime,0)- isNull(TT.PPDT ,0)
		FROM(
		--Production Time in PDT
		SELECT A.Opr,SUM
			(CASE
			WHEN A.msttime >= T.StartTime  AND A.ndtime <=T.EndTime  THEN (A.cycletime+A.loadunload)
			WHEN ( A.msttime < T.StartTime  AND A.ndtime <= T.EndTime  AND A.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,A.ndtime)
			WHEN ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime  AND A.ndtime > T.EndTime  ) THEN DateDiff(second,A.msttime,T.EndTime )
			WHEN ( A.msttime < T.StartTime  AND A.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END)  as PPDT
		FROM AutoData A
		Inner Join EmployeeInformation E on A.Opr=E.InterfaceID inner jOIN #PlannedDownTimes T on
		T.MachineInterface=A.mc
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
		Group by A.Opr
	)
	 as TT Inner Join #OprProdData on TT.Opr = #OprProdData.interfaceid '
	Exec (@StrSql)
	--Handle intearction between ICD and PDT for type 1 production record for the selected time period.
	UPDATE  #OprProdData SET UtilisedTime = isnull(UtilisedTime,0)+ isNull(TT.IPDT ,0)  	FROM	(
	Select AutoData.opr,
	SUM(
	CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT
	From AutoData INNER Join
		(Select opr,mc,Sttime,NdTime From AutoData
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(msttime >= @StartTime) AND (ndtime <= @EndTime)) as T1
	ON AutoData.mc=T1.mc  and T1.opr=autodata.opr CROSS jOIN #PlannedDownTimes T
	Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc
	And (( autodata.Sttime > T1.Sttime )
	And ( autodata.ndtime <  T1.ndtime )
	)
	AND
	((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
	or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
	or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
	or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )
	GROUP BY AUTODATA.opr
	)as TT Inner Join #OprProdData on TT.Opr = #OprProdData.interfaceid
	
	/* Fetching Down Records from Production Cycle  */
	/* If production  Records of TYPE-2*/
	UPDATE  #OprProdData SET UtilisedTime = isnull(UtilisedTime,0)+ isNull(TT.IPDT ,0)	FROM	(
		Select AutoData.opr,
		SUM(
		CASE 	
			When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
			When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
			When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
			when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		From AutoData INNER Join
			(Select opr,mc,Sttime,NdTime From AutoData
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(msttime < @StartTime)And (ndtime > @StartTime) AND (ndtime <= @EndTime)) as T1
		ON AutoData.mc=T1.mc and T1.opr=autodata.opr CROSS jOIN #PlannedDownTimes T
		Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc
		And (( autodata.Sttime > T1.Sttime )
		And ( autodata.ndtime <  T1.ndtime )
		AND ( autodata.ndtime >  @StartTime ))
		AND
		(( T.StartTime >= @StartTime )
		And ( T.StartTime <  T1.ndtime ) )
		GROUP BY AutoData.opr
	)as TT Inner Join #OprProdData on TT.Opr = #OprProdData.interfaceid
	
	/* If production Records of TYPE-3*/
	UPDATE  #OprProdData SET UtilisedTime = isnull(UtilisedTime,0)+ isNull(TT.IPDT ,0)
	FROM
	(Select AutoData.opr,
	SUM(
	CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT
	From AutoData INNER Join
		(Select opr,mc,Sttime,NdTime From AutoData
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(sttime >= @StartTime)And (ndtime > @EndTime) and autodata.sttime <@EndTime) as T1
	ON AutoData.mc=T1.mc and T1.opr=autodata.opr CROSS jOIN #PlannedDownTimes T
	Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc
	And ((T1.Sttime < autodata.sttime  )
	And ( T1.ndtime >  autodata.ndtime)
	AND (autodata.msttime  <  @EndTime))
	AND
	(( T.EndTime > T1.Sttime )
	And ( T.EndTime <=@EndTime ) )
	GROUP BY AutoData.opr)as TT Inner Join #OprProdData on TT.Opr = #OprProdData.interfaceid
	
	
	/* If production Records of TYPE-4*/
	UPDATE  #OprProdData SET UtilisedTime = isnull(UtilisedTime,0)+ isNull(TT.IPDT ,0)
	FROM
	(Select AutoData.opr,
	SUM(
	CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT
	From AutoData INNER Join
		(Select opr,mc,Sttime,NdTime From AutoData
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(msttime < @StartTime)And (ndtime > @EndTime)) as T1
	ON AutoData.mc=T1.mc and T1.opr=autodata.opr CROSS jOIN #PlannedDownTimes T
	Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc
	And ( (T1.Sttime < autodata.sttime  )
		And ( T1.ndtime >  autodata.ndtime)
		AND (autodata.ndtime  >  @StartTime)
		AND (autodata.sttime  <  @EndTime)) AND
	(( T.StartTime >=@StartTime)
	And ( T.EndTime <=@EndTime )  )
	GROUP BY AutoData.opr )as TT Inner Join #OprProdData on TT.Opr = #OprProdData.interfaceid
END
/*******************************Down Record***********************************/
--Management Loss
/* ************************* Begins :: Commented by sangeeta kallur on 16th Feb 06
--#TYPE-1
--Deleted TYPE-2,TYPE-3,TYPE-4 Calns
UPDATE #OprProdData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
from
(select      opr,
	sum(loadunload) loss
from autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
where (autodata.msttime>=@StartTime)and (autodata.ndtime<=@EndTime)and (autodata.datatype=2)and (downcodeinformation.availeffy = 1)
group by autodata.opr
) as t2 inner join #OprProdData on t2.opr = #OprProdData.interfaceid
********************** Ends :: **************************************/
------------------------------ Begins :: MLoss Caln including theshold by SKallur ----------------------------
--mod 4
---Below IF condition added by Mrudula for mod 4. TO get the ML if 'Ignore_Dtime_4m_PLD'<>"Y"
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y')
BEGIN
--mod 4
	--TYPE-1
	UPDATE #OprProdData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
	from
	(select      opr,
		sum( CASE
	WHEN loadunload >ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0) > 0 THEN ISNULL(downcodeinformation.Threshold,0)
	ELSE loadunload
	END) loss
	from autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
	where (autodata.msttime>=@StartTime)and (autodata.ndtime<=@EndTime)and (autodata.datatype=2)and (downcodeinformation.availeffy = 1)
	group by autodata.opr
	) as t2 inner join #OprProdData on t2.opr = #OprProdData.interfaceid
	--TYPE-2
	UPDATE #OprProdData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
	from
	(select      opr,
		sum(CASE
	WHEN DateDiff(second, @StartTime, ndtime)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0) > 0 THEN ISNULL(downcodeinformation.Threshold,0)
	
	ELSE DateDiff(second, @StartTime, ndtime)
	END) loss
	from autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
	where (autodata.sttime<@StartTime)
	and (autodata.ndtime>@StartTime)
	and (autodata.ndtime<=@EndTime)
	and (autodata.datatype=2)
	and (downcodeinformation.availeffy = 1)
	group by autodata.opr
	) as t2 inner join #OprProdData on t2.opr = #OprProdData.interfaceid
	--TYPE-3
	UPDATE #OprProdData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
	from
	(select      opr,
		sum(CASE
	WHEN DateDiff(second, stTime, @Endtime)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0) > 0 THEN ISNULL(downcodeinformation.Threshold,0)
	ELSE DateDiff(second, stTime, @Endtime)
	END) loss
	from autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
	where (autodata.msttime>=@StartTime)
	and (autodata.sttime<@EndTime)
	and (autodata.ndtime>@EndTime)
	and (autodata.datatype=2)
	and (downcodeinformation.availeffy = 1)
	group by autodata.opr
	) as t2 inner join #OprProdData on t2.opr = #OprProdData.interfaceid
	--TYPE-4
	UPDATE #OprProdData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
	from
	(select opr,
		sum(CASE
	WHEN DateDiff(second, @StartTime, @Endtime)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0) > 0 THEN ISNULL(downcodeinformation.Threshold,0)
	ELSE DateDiff(second, @StartTime, @Endtime)
	END) loss
	from autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
	where autodata.msttime<@StartTime
	and autodata.ndtime>@EndTime
	and (autodata.datatype=2)
	and (downcodeinformation.availeffy = 1)
	group by autodata.opr
	) as t2 inner join #OprProdData on t2.opr = #OprProdData.interfaceid
	--Down time calculation
	--TYPE 1
	UPDATE #OprProdData SET downtime = isnull(downtime,0) + isNull(t2.down,0)
	from
	(select opr,
		sum(loadunload) down
	from autodata
	where (autodata.msttime>=@StartTime)
	and (autodata.ndtime<=@EndTime)
	and (autodata.datatype=2)
	group by autodata.opr
	) as t2 inner join #OprProdData on t2.opr = #OprProdData.interfaceid
	--#TYPE-2
	UPDATE #OprProdData SET downtime = isnull(downtime,0) + isNull(t2.down,0)
	from
	(select opr,
		sum(DateDiff(second, @StartTime, ndtime)) down
	from autodata
	where (autodata.sttime<@StartTime)
	and (autodata.ndtime>@StartTime)
	and (autodata.ndtime<=@EndTime)
	and (autodata.datatype=2)
	group by autodata.opr

	) as t2 inner join #OprProdData on t2.opr = #OprProdData.interfaceid
	--#TYPE-3
	UPDATE #OprProdData SET downtime = isnull(downtime,0) + isNull(t2.down,0)
	from
	(select opr,
		sum(DateDiff(second, stTime, @Endtime)) down
	from autodata
	where (autodata.msttime>=@StartTime)
	and (autodata.sttime<@EndTime)
	and (autodata.ndtime>@EndTime)
	and (autodata.datatype=2)group by autodata.opr
	) as t2 inner join #OprProdData on t2.opr = #OprProdData.interfaceid
	--#TYPE-4
	UPDATE #OprProdData SET downtime = isnull(downtime,0) + isNull(t2.down,0)
	from
	(select opr,
		sum(DateDiff(second, @StartTime, @EndTime)) down
	from autodata
	where autodata.msttime<@StartTime
	and autodata.ndtime>@EndTime
	and (autodata.datatype=2)
	group by autodata.opr
	) as t2 inner join #OprProdData on t2.opr = #OprProdData.interfaceid
---mod 4
END
---mod 4
---mod 4: Handling interaction between PDT and downtime . Also interaction between PDT and Management Loss
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN
	---step 1
	
	UPDATE #OprProdData SET downtime = isnull(downtime,0) + isNull(t2.down,0)
	from
	(select opr,sum(
			CASE
	        WHEN  autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime  THEN  loadunload
			WHEN (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  THEN DateDiff(second, @StartTime, ndtime)
			WHEN (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)  THEN DateDiff(second, stTime, @Endtime)
			WHEN autodata.msttime<@StartTime and autodata.ndtime>@EndTime   THEN DateDiff(second, @StartTime, @EndTime)
			END
		)AS down
	from autodata inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
	where autodata.datatype=2 AND
	(
	(autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)
	OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
	OR (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
	OR (autodata.msttime<@StartTime and autodata.ndtime>@EndTime )
	) AND (downcodeinformation.availeffy = 0)
	group by autodata.opr
	) as t2 inner join #OprProdData on t2.opr = #OprProdData.interfaceid
	--select * from #CockpitData
	---step 2
	---mod 4 checking for (downcodeinformation.availeffy = 0) to get the overlapping PDT and Downs which is not ML
	UPDATE #OprProdData SET downtime = isnull(downtime,0) - isNull(T2.PPDT ,0)
	FROM(
		--Production PDT
		SELECT autodata.opr, SUM
		   (CASE
			WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PPDT
		FROM AutoData CROSS jOIN #PlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)
			 AND (downcodeinformation.availeffy = 0)
		group by autodata.opr
	) as t2 inner join #OprProdData on t2.opr = #OprProdData.interfaceid
	--select * from #PLD
	---step 3
	---Management loss calculation
	---IN T1 Select get all the downtimes which is of type management loss
	---IN T2  get the time to be deducted from the cycle if the cycle is overlapping with the PDT. And it should be ML record
	---In T3 Get the real management loss , and time to be considered as real down for each cycle(by comaring with the ML threshold)
	---In T4 consolidate everything at machine level and update the same to #CockpitData for ManagementLoss and MLDown
	
	UPDATE #OprProdData SET  ManagementLoss = isnull(ManagementLoss,0) + isNull(t4.Mloss,0),MLDown=isNull(MLDown,0)+isNull(t4.Dloss,0)
	from
	(select T3.opr,sum(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss from (
	select   t1.opr,t1.id,T1.mc,T1.Threshold,
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
		from autodata
		inner join downcodeinformation D
		on autodata.dcode=D.interfaceid where autodata.datatype=2 AND
		(
		(autodata.sttime>=@StartTime  and  autodata.ndtime<=@EndTime)
		OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
		OR (autodata.sttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
		OR (autodata.sttime<@StartTime and autodata.ndtime>@EndTime )
		) AND (D.availeffy = 1)) as T1 	
	left outer join
	(SELECT autodata.id,
		       sum(CASE
			WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PPDT
		FROM AutoData CROSS jOIN #PlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)
			AND (downcodeinformation.availeffy = 1) group  by autodata.id ) as T2 on T1.id=T2.id ) as T3  group by T3.opr
	) as t4  inner join #OprProdData on t4.opr = #OprProdData.interfaceid
	UPDATE #OprProdData  SET downtime = isnull(downtime,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)
END
---mod 4: Till here Handling interaction between PDT and downtime . Also interaction between PDT and Management Loss
---mod 4:If Ignore_Dtime_4m_PLD<> Y and Ignore_Dtime_4m_PLD<> N
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y' AND (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
BEGIN
	UPDATE #OprProdData SET downtime = isnull(downtime,0) - isNull(T2.PPDT ,0)
	FROM(
		--Production PDT
		SELECT autodata.opr, SUM
		       (CASE
			WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PPDT
		FROM AutoData CROSS jOIN #PlannedDownTimes T
		Inner Join DownCodeInformation D ON AutoData.DCode = D.InterfaceID
		WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND D.DownID=(SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD') AND
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)
		group by autodata.opr
	) as t2 inner join #OprProdData on t2.opr = #OprProdData.interfaceid
END
---mod 4:If Ignore_Dtime_4m_PLD<> Y and Ignore_Dtime_4m_PLD<> N
------------------------------ :: Ends :: ------------------------------------------
--CN
UPDATE #OprProdData SET CN = isnull(CN,0) + isNull(t2.C1N1,0)
from
(select opr,
SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))* autodata.partscount) C1N1
FROM autodata INNER JOIN
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
group by autodata.opr
) as t2 inner join #OprProdData on t2.opr = #OprProdData.interfaceid
--Components
/*UPDATE #OprProdData SET components = ISNULL(components,0) + ISNULL(t2.comp,0)
from
( select Opr,SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp
	From (select Opr,SUM(autodata.partscount)AS OrginalCount,comp,opn from autodata
	Where (autodata.ndtime>@StartTime) and (autodata.ndtime<=@EndTime) and (autodata.datatype=1)
	Group by Opr,comp,opn) as T1
Inner join componentinformation C on T1.Comp=C.interfaceid
Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid
GROUP BY Opr
) as T2 inner join #OprProdData on T2.Opr = #OprProdData.interfaceID
*/
/**************************************************************************************************/
/*		FOLLOWING CODE IS ADDED BY SANGEETA KALLUR*/
INSERT INTO #MCOO_pCounts(MachineID ,ComponentID ,OperationNo ,Operator_IId ,pCount,CycleTime )
SELECT M.MachineID  ,C.ComponentID,O.OperationNo ,Opr,
CEILING (CAST(SUM(A.partscount) AS Float)/ISNULL(O.SubOperations,1)) ,O.CycleTime
From Autodata A
Inner Join MachineInformation M ON A.Mc=M.interfaceid
Inner join componentinformation C on A.Comp=C.interfaceid
Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid and C.Componentid=O.componentid
--mod 2
and O.machineid=M.machineid
--mod 2
Where (A.datatype=1)AND (A.ndtime>@StartTime  and A.ndtime<=@EndTime)
Group by M.MachineID,C.ComponentID,O.OperationNo,A.Opr,O.SubOperations,O.CycleTime
---mod 4: Neglect count overlapping with PDT
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	UPDATE #MCOO_pCounts SET pCount = ISNULL(pCount,0) - ISNULL(T2.PLD_Comp,0)
	from
	(
		select  M.MachineID ,C.ComponentID,O.OperationNo,A.Opr As Operator_IId,CEILING(CAST(Sum(ISNULL(A.PartsCount,1)) AS Float)/ISNULL(O.SubOperations,1)) AS PLD_Comp
		from autodata A
		Inner Join MachineInformation M ON A.Mc=M.interfaceid
		Inner join componentinformation C on A.Comp=C.interfaceid
	   	Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid and C.Componentid=O.componentid
		and O.MachineId=M.MachineId
		inner jOIN #PlannedDownTimes T on T.Machine=M.MachineID WHERE A.DataType=1
			AND (A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)
			AND (A.ndtime > @StartTime  AND A.ndtime <=@EndTime)
		Group by M.MachineID,C.ComponentID,O.OperationNo,A.Opr,O.SubOperations
	) as T2 inner join #MCOO_pCounts on #MCOO_pCounts.MachineID=T2.MachineID AND #MCOO_pCounts.Componentid=T2.Componentid AND #MCOO_pCounts.OperationNo=T2.OperationNo AND #MCOO_pCounts.Operator_IId=T2.Operator_IId
	-- mod 4 Ignore count from CN calculation which is over lapping with PDT
	UPDATE #OprProdData SET CN = isnull(CN,0) - isNull(t2.C1N1,0)
	From
	(
		select opr,SUM((O.cycletime * ISNULL(A.PartsCount,1))/ISNULL(O.SubOperations,1))  C1N1
		From autodata A
		Inner join machineinformation M on M.interfaceid=A.mc
		Inner join componentinformation C ON A.Comp=C.interfaceid
		Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID
		Cross jOIN #PlannedDownTimes T
		WHERE A.DataType=1 AND T.MachineInterface=A.mc
		AND(A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)
		AND(A.ndtime > @StartTime  AND A.ndtime <=@EndTime)
		Group by opr
	) as T2
	 inner join #OprProdData on t2.opr = #OprProdData.interfaceid
END
---mod 4
UPDATE #MCOO_pCounts SET pCount=ISNULL(Tt.OpnCount,0)
FROM
(
	SELECT Operator_IId,Ti.MachineID,Ti.Componentid,Ti.OperationNo,(pCount-(pCount*(Ti.Ratio)))AS OpnCount
	FROM #MCOO_pCounts Left Outer Join
	(
		SELECT #Exceptions.MachineID,#Exceptions.Componentid,#Exceptions.OperationNo,CAST(CAST (SUM(ExCount) AS FLOAT)/CAST(Max(T1.tCount)AS FLOAT )AS FLOAT) AS Ratio
		FROM #Exceptions  Inner Join (
				SELECT MachineID,Componentid,OperationNo,SUM(pCount)AS tCount
				FROM #MCOO_pCounts Group By  MachineID,Componentid,OperationNo
				)T1 ON  T1.MachineID=#Exceptions.MachineID AND T1.Componentid=#Exceptions.Componentid AND T1.OperationNo=#Exceptions.OperationNo
		Group By  #Exceptions.MachineID,#Exceptions.Componentid,#Exceptions.OperationNo
	)Ti ON Ti.MachineID=#MCOO_pCounts.MachineID AND Ti.Componentid=#MCOO_pCounts.Componentid AND Ti.OperationNo=#MCOO_pCounts.OperationNo
)AS Tt InneR Join #MCOO_pCounts ON #MCOO_pCounts.MachineID=Tt.MachineID AND #MCOO_pCounts.Componentid=Tt.Componentid AND #MCOO_pCounts.OperationNo=Tt.OperationNo AND #MCOO_pCounts.Operator_IId=Tt.Operator_IId
UPDATE #OprProdData SET Components = ISNULL(Tt.OCount,0)
FROM
(
	SELECT Operator_IId,Sum(pCount)As OCount   From #MCOO_pCounts GROUP BY Operator_IId
) AS Tt Inner Join #OprProdData ON #OprProdData.Interfaceid=Tt.Operator_IId
/*
UPDATE #OprProdData SET CN = ISNULL(Tt.C1N1,0)
FROM
(
	SELECT Operator_IId,SUM(CNi)C1N1  From
		(
			SELECT Operator_IId ,ISNULL(pCount*CycleTime,0)AS CNi FROM  #MCOO_pCounts
		) AS Ti
	GROUP BY Operator_IId
)AS Tt Inner Join #OprProdData ON #OprProdData.Interfaceid=Tt.Operator_IId
*/
/**************************************************************************************************/
/* Commented for Mod 4 : Moved below calculation within if ignore_dtime_from_PLD<>"Y"
--DownTime
--#TYPE-1
UPDATE #OprProdData SET downtime = isnull(downtime,0) + isNull(t2.down,0)
from
(select opr,
	sum(loadunload) down
from autodata
where (autodata.msttime>=@StartTime)
and (autodata.ndtime<=@EndTime)
and (autodata.datatype=2)
group by autodata.opr
) as t2 inner join #OprProdData on t2.opr = #OprProdData.interfaceid
--#TYPE-2
UPDATE #OprProdData SET downtime = isnull(downtime,0) + isNull(t2.down,0)
from
(select opr,
	sum(DateDiff(second, @StartTime, ndtime)) down
from autodata
where (autodata.sttime<@StartTime)
and (autodata.ndtime>@StartTime)
and (autodata.ndtime<=@EndTime)
and (autodata.datatype=2)
group by autodata.opr
) as t2 inner join #OprProdData on t2.opr = #OprProdData.interfaceid
--#TYPE-3
UPDATE #OprProdData SET downtime = isnull(downtime,0) + isNull(t2.down,0)
from
(select opr,
	sum(DateDiff(second, stTime, @Endtime)) down
from autodata
where (autodata.msttime>=@StartTime)
and (autodata.sttime<@EndTime)
and (autodata.ndtime>@EndTime)
and (autodata.datatype=2)group by autodata.opr
) as t2 inner join #OprProdData on t2.opr = #OprProdData.interfaceid
--#TYPE-4
UPDATE #OprProdData SET downtime = isnull(downtime,0) + isNull(t2.down,0)
from
(select opr,
	sum(DateDiff(second, @StartTime, @EndTime)) down
from autodata
where autodata.msttime<@StartTime
and autodata.ndtime>@EndTime
and (autodata.datatype=2)
group by autodata.opr
) as t2 inner join #OprProdData on t2.opr = #OprProdData.interfaceid
Commented  till here for Mod 4 : Moved below calculation within if ignore_dtime_from_PLD<>"Y" */
--Mod1
IF ISNULL(@Operatorid,'')<>''
BEGIN
	update #OprProdData set Components=T1.comp ,UtilisedTime=T1.Util,ManagementLoss=T1.Mgmt ,
	DownTime =T1.Dtime,	CN =T1.CN1
	from (select sum(Components) as comp,sum(UtilisedTime) as Util,sum(ManagementLoss) as Mgmt,
	sum(DownTime) as Dtime,sum(CN) as CN1 from #OprProdData ) as  T1 where #OprProdData.OperatorID=@Operatorid
	delete from #OprProdData where #OprProdData.OperatorID<>@Operatorid
END
ELSE
BEGIN
		/*	--Commented by shilpa on 19-may-08
		CREATE TABLE #OprProdDataG(
			OperatorIDG nvarchar(50),
			ComponentsG float,
			UtilisedTimeG float,
			ManagementLossG float,
			DownTimeG float,
			CNG float
		)
		insert into #OprProdDataG(OperatorIDG,ComponentsG ,	UtilisedTimeG ,	ManagementLossG ,DownTimeG ,CNG)
		select OperatorID,Components,UtilisedTime,ManagementLoss,DownTime,CN from #OprProdData where isgrp=1
		   */  --till here
		
		declare @CurOperatorIDG as nvarchar(50)
		declare @CurComponents as float
		declare @CurUtilisedTime as float
		declare @CurManagementLoss as float
		declare @CurDownTime as float
		declare @CurCN as float
		declare @InOpr as nvarchar(50)
		declare @sep as nvarchar(2)
		Select @sep =Groupseperator2 from smartdataportrefreshdefaults
		
		Declare TmpCursor Cursor For SELECT OperatorID,Components ,UtilisedTime ,ManagementLoss,DownTime,CN FROM #OprProdData where isgrp=1
		OPEN  TmpCursor
		--FETCH NEXT FROM TmpCursorICD INTO @CurMachineID,@CurDate,@CurStrtTime,@CurEndTime
		FETCH NEXT FROM TmpCursor INTO @CurOperatorIDG,@CurComponents ,@CurUtilisedTime,@CurManagementLoss,@CurDownTime ,@CurCN
		WHILE @@FETCH_STATUS=0
		BEGIN---cursor
			while  substring(@CurOperatorIDG,1,(case when CHARINDEX ( @sep ,@CurOperatorIDG)=0 then len(@CurOperatorIDG) else (CHARINDEX ( @sep ,@CurOperatorIDG)-1 ) end) ) <> ''
			begin
				--print  @CurOperatorIDG
				set @InOpr=substring(@CurOperatorIDG,1,(case when CHARINDEX ( @sep ,@CurOperatorIDG)=0 then len(@CurOperatorIDG) else (CHARINDEX ( @sep ,@CurOperatorIDG)-1 ) end) )
				
				If not exists (select * from #OprProdData where operatorid=@InOpr)
				Begin
					Insert into #OprProdData(OperatorID,Components,UtilisedTime,ManagementLoss,DownTime,CN,isgrp)
					values(@InOpr,@CurComponents,@CurUtilisedTime,@CurManagementLoss,@CurDownTime,@CurCN,0)
				End
				Else
				Begin
					update #OprProdData set Components=Components+@CurComponents ,UtilisedTime=UtilisedTime+@CurUtilisedTime,ManagementLoss=ManagementLoss+@CurManagementLoss,
					DownTime =DownTime+@CurDownTime,CN =CN+@CurCN where #OprProdData.OperatorID=@InOpr
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
			FETCH NEXT FROM TmpCursor INTO @CurOperatorIDG,@CurComponents ,@CurUtilisedTime,@CurManagementLoss,@CurDownTime ,@CurCN
			
			
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
Components,
CN,
UtilisedTime,
dbo.f_FormatTime(UtilisedTime,@timeformat) as frmtUtilisedTime,
dbo.f_FormatTime(ManagementLoss,@timeformat) as ManagementLoss,
dbo.f_FormatTime(DownTime,@timeformat) as DownTime,
@StartTime as StartTime,
@EndTime as EndTime
FROM #OprProdData INNER JOIN Employeeinformation on #OprProdData.Operatorid = Employeeinformation.employeeid
WHERE Components > 0 OR DownTime > 0order by operatorid asc
END
