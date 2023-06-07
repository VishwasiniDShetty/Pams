/****** Object:  Procedure [dbo].[s_GetWeeklyJobCard]    Committed by VersionSQL https://www.versionsql.com ******/

/*****************************   History    *********************************************************
Author :: Sangeeta Kallur
Changed by Sangeeta Kallur on 05-July-2006
Changed ProdTime Caln to substract Down within production Cycle.
changed To Support SubOperations at CO Level{AutoAxel Request}.
Change In Max,Min,AVG(Cycle Time,LoadUnload Time),Count Calns
Changed by Mrudula to include pallette count
Procedure Changed By Sangeeta Kallur on 27-FEB-2007 :
	[MAINI Req] :Production Count Exception for multispindle Machines.
mod 1 :- ER0181 By Kusuma M.H on 10-Jun-2009.2) Modify all the procedures accordingly. Qualify machine wherever we are making use of component and opeartion no.
mod 2 :- ER0182 By Kusuma M.H on 10-Jun-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
ER0210 By Karthikg on 03/Mar/2010 :: Introduce PDT on 5150. Handle PDT at Machine Level. 
DR0213 By Karthik G on 19/May/2010 :: To avoid Divide By Zero Error
s_GetWeeklyJobCard '01-dec-2009','02-dec-2009','','',''

*****************************************************************************************************/
CREATE        PROCEDURE [dbo].[s_GetWeeklyJobCard]
	@StartTime datetime,
	@EndTime datetime,
	@Operator nvarchar(50) = '',
	@MachineID nvarchar(50) = '',
	@PlantID nvarchar(50)=''
		
AS
BEGIN
Declare @strsql nvarchar(4000)
Declare @stroperator nvarchar(255)
Declare @strMachine nvarchar(255)
Declare @TimeFormat as nvarchar(50)
Declare @strPlantID as nvarchar(255)
Declare @strxMachine as nvarchar(255)
Declare @Param1 As NVarChar(2000)--ER0210

SELECT @strPlantID = ''
SELECT @strMachine = ''
SELECT @strsql = ''
SELECT @stroperator = ''
SELECT @TimeFormat = 'ss'
SELECT @strxMachine=''
SELECT @Param1=''--ER0210

Create Table #TmpJobCard
(
	OperatorID  NVarChar(50),
	ComponentID  NVarChar(50),
	MachineID  NVarChar(50),
	OperationNo  Int ,
	OperationDscr  NVarChar(100),
	IdealCycleTime NVarChar(20),
	IdealLoadUnload NVarChar(20),
	MaxCycleTime NVarChar(20),
	MinCycleTime NVarChar(20),
	AveCycleTime NVarChar(20),
	MaxLoadUnload NVarChar(20),
	MinLoadUnload NVarChar(20),
	AveLoadUnload NVarChar(20),
	ProdTime NVarChar(20),
	OperationCount Int
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

--ER0210
create table #PlannedDownTimes
(	
	Machine nvarchar(50),
	StartTime datetime,
	EndTime datetime
)
--ER0210

SELECT @TimeFormat = isnull((SELECT  ValueInText  FROM CockpitDefaults WHERE Parameter = 'TimeFormat'),'ss')
if (@TimeFormat <> 'hh:mm:ss' and @TimeFormat <> 'hh' and @TimeFormat <> 'mm' and @TimeFormat <> 'ss')
BEGIN
	SELECT @TimeFormat = 'ss'
END
if isnull(@operator, '') <> ''
BEGIN
	---mod 2
--	SELECT @stroperator = ' AND ( employeeinformation.employeeid = ''' + @Operator + ''')'
	SELECT @stroperator = ' AND ( employeeinformation.employeeid = N''' + @Operator + ''')'
	---mod 2
END
if isnull(@MachineId, '') <> ''
BEGIN
	---mod 2
--	SELECT @strMachine = ' AND ( machineInformation.machineId = ''' + @MachineId + ''')'
--	SELECT @strxMachine = ' AND ( EX.MachineId = ''' + @MachineId + ''')'
	SELECT @strMachine = ' AND ( machineInformation.machineId = N''' + @MachineId + ''')'
	SELECT @strxMachine = ' AND ( EX.MachineId = N''' + @MachineId + ''')'
	---mod 2
END
if isnull(@PlantID,'') <> ''
BEGIN
	---mod 2
--	SELECT @strPlantID = ' AND ( P.PlantID = ''' + @PlantID+ ''')'
	SELECT @strPlantID = ' AND ( P.PlantID = N''' + @PlantID+ ''')'
	---mod 2
END
--ER0210
			If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
			BEGIN
				SELECT @Param1=' AND AutoData.ID Not In (
					Select ID From AutoData A CROSS JOIN #PlannedDownTimes  
					INNER JOIN  machineinformation ON a.mc = machineinformation.InterfaceID and #PlannedDownTimes.Machine=machineinformation.MachineID
					Left Outer JOIN PlantMachine P ON P.MachineID=machineinformation.MachineID 
					INNER JOIN employeeinformation ON A.opr = employeeinformation.InterfaceID
					Where DataType=1 And A.ndtime>StartTime And A.NdTime<=EndTime'
				SELECT @Param1=@Param1 +@StrPlantID +  @strMachine + @stroperator
				SELECT @Param1=@Param1 + ')'
			END
--ER0210

SELECT @strsql ='Insert Into #TmpJobCard('
SELECT @strsql = @strsql + 'OperatorID,ComponentID,MachineID,OperationNo,OperationDscr,IdealCycleTime,'
SELECT @strsql = @strsql + 'IdealLoadUnload,MaxCycleTime,MinCycleTime,AveCycleTime,MaxLoadUnload,MinLoadUnload,AveLoadUnload,ProdTime,OperationCount) '
SELECT @strsql = @strsql + 'SELECT employeeinformation.employeeid as OperatorID,'
SELECT @strsql = @strsql + 'componentinformation.componentid as ComponentID,'
SELECT @strsql=  @strsql + 'machineinformation.machineid as MachineID,'
SELECT @strsql = @strsql + 'componentoperationpricing.operationno AS OperationNo,'
SELECT @strsql = @strsql + 'componentoperationpricing.Description AS OperationDscr,'
SELECT @strsql = @strsql + 'componentoperationpricing.machiningtime AS IdealCycleTime,'
SELECT @strsql = @strsql + '(componentoperationpricing.cycletime - componentoperationpricing.machiningtime) AS IdealLoadUnload,'
SELECT @strsql = @strsql + 'MAX(autodata.cycletime/autodata.partscount)* ISNULL(componentoperationpricing.SubOperations,1) AS MaxCycleTime,'
SELECT @strsql = @strsql + 'MIN(autodata.cycletime/autodata.partscount)* ISNULL(componentoperationpricing.SubOperations,1) AS MinCycleTime,'
SELECT @strsql = @strsql + 'AVG(autodata.cycletime/autodata.partscount)* ISNULL(componentoperationpricing.SubOperations,1) AS AveCycleTime,'
SELECT @strsql = @strsql + 'MAX(autodata.loadunload/autodata.partscount)* ISNULL(componentoperationpricing.SubOperations,1)AS MaxLoadUnload,'
SELECT @strsql = @strsql + 'MIN(autodata.loadunload/autodata.partscount)* ISNULL(componentoperationpricing.SubOperations,1) AS MinLoadUnload,'
SELECT @strsql = @strsql + 'AVG(autodata.loadunload/autodata.partscount)* ISNULL(componentoperationpricing.SubOperations,1) AS AveLoadUnload,'
SELECT @strsql = @strsql + 'SUM ( CASE'
SELECT @strsql = @strsql + ' WHEN (autodata.msttime >= ''' + convert(nvarchar(20),@StartTime,120) + '''  AND autodata.ndtime <= ''' + convert(nvarchar(20),@EndTime,120) + ''')  then (AutoData.cycletime + AutoData.loadunload)'
SELECT @strsql = @strsql + ' WHEN ( autodata.msttime < ''' + convert(nvarchar(20),@StartTime,120) + '''   AND autodata.ndtime <= ''' + convert(nvarchar(20),@EndTime,120) + ''' AND autodata.ndtime > ''' + convert(nvarchar(20),@StartTime,120) + ''' )THEN DateDiff(second, ''' + convert(nvarchar(20),@StartTime,120) + ''', ndtime) '
SELECT @strsql = @strsql + ' END )  AS ProdTime ,'
SELECT @strsql = @strsql + ' CAST(CEILING(CAST(sum(autodata.partscount) as float)/ ISNULL(componentoperationpricing.SubOperations,1))as integer ) as OperationCount '
SELECT @strsql = @strsql + ' FROM autodata INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID LEFT OUTER Join  '
SELECT @strsql = @strsql + ' PlantMachine P on machineinformation.machineid = P.machineid   INNER JOIN '
SELECT @strsql = @strsql + ' employeeinformation ON autodata.opr = employeeinformation.InterfaceID  LEFT OUTER Join '
select @strsql = @strsql + ' PlantEmployee ON employeeinformation.Employeeid = PlantEmployee.employeeID   INNER JOIN '
SELECT @strsql = @strsql + ' componentinformation ON autodata.comp = componentinformation.InterfaceID  INNER JOIN '
SELECT @strsql = @strsql + ' componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID)'
---mod 1
SELECT @strsql = @strsql + ' and machineinformation.machineid = componentoperationpricing.machineid '
---mod 1
SELECT @strsql = @strsql + ' AND (componentinformation.componentid = componentoperationpricing.componentid) '
SELECT @strsql = @strsql + ' WHERE (autodata.ndtime > ''' + convert(nvarchar(20),@StartTime) + ''')'
SELECT @strsql = @strsql + ' AND (autodata.ndtime <= ''' + convert(nvarchar(20),@EndTime) + ''')'
--ER0210
--SELECT @strsql = @strsql +   @strMachine + @stroperator + @strPlantID
SELECT @strsql = @strsql +   @strMachine + @stroperator + @strPlantID + @Param1
--ER0210
SELECT @strsql = @strsql + ' AND (autodata.datatype = 1)'
--DR0213 By Karthik G on 19/May/2010 
select @strsql = @strsql + ' AND (autodata.partscount > 0 ) '
--DR0213 By Karthik G on 19/May/2010 
SELECT @strsql = @strsql + ' GROUP BY employeeinformation.employeeid,machineinformation.machineid,componentinformation.componentid, componentoperationpricing.operationno, '
SELECT @strsql = @strsql + ' componentoperationpricing.cycletime, componentoperationpricing.machiningtime,componentoperationpricing.Description, componentoperationpricing.SubOperations '
Exec (@strsql)



SELECT @StrSql = 'INSERT INTO #Exceptions(MachineID ,ComponentID,OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,ExCount )
		SELECT Ex.MachineID ,Ex.ComponentID,Ex.OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,0
		From ProductionCountException Ex
		Inner Join MachineInformation M ON Ex.MachineID=M.MachineID
		Inner Join ComponentInformation C ON Ex.ComponentID=C.ComponentID
		Inner Join Componentoperationpricing O ON Ex.OperationNo=O.OperationNo AND C.ComponentID=O.ComponentID '
---mod 1
SELECT @StrSql = @StrSql + ' and M.machineid = O.machineid '
---mod 1
SELECT @StrSql = @StrSql + ' WHERE M.MultiSpindleFlag=1 AND
		((Ex.StartTime>=  ''' + convert(nvarchar(20),@StartTime,120)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@EndTime,120)+''' )
		OR (Ex.StartTime< ''' + convert(nvarchar(20),@StartTime,120)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@StartTime,120)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@EndTime,120)+''')
		OR(Ex.StartTime>= ''' + convert(nvarchar(20),@StartTime,120)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@EndTime,120)+''' AND Ex.StartTime< ''' + convert(nvarchar(20),@EndTime,120)+''')
		OR(Ex.StartTime< ''' + convert(nvarchar(20),@StartTime,120)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@EndTime,120)+''' ))'
SELECT @StrSql = @StrSql + @StrxMachine
Exec (@strsql)

IF ( SELECT Count(*) from #Exceptions ) <> 0
BEGIN
	UPDATE #Exceptions SET StartTime=@StartTime WHERE (StartTime<@StartTime)AND EndTime>@StartTime
	UPDATE #Exceptions SET EndTime=@EndTime WHERE (EndTime>@EndTime AND StartTime<@EndTime )
	Select @StrSql = 'UPDATE #TmpJobCard SET OperationCount=ISNULL(#TmpJobCard.OperationCount,0)-ISNULL(T1.ExCount,0) From	(
			select MachineID,ComponentID,OperationNo,employeeid,sum(ExCount) as ExCount from (
			select MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,employeeinformation.employeeid,--Tt1.StartTime,Tt1.EndTime,ActualCount,IdealCount,
			floor((SUM(CEILING (CAST(autodata.PartsCount AS Float)/ISNULL(ComponentOperationPricing.SubOperations,1)))*ActualCount)/IdealCount) as ExCount
			from autodata
			Inner Join EmployeeInformation on autodata.Opr=EmployeeInformation.InterfaceID
			Inner Join MachineInformation   ON autodata.MC=MachineInformation.InterfaceID
			Inner Join ComponentInformation  ON autodata.Comp = ComponentInformation.InterfaceID
			Inner Join ComponentOperationPricing on autodata.Opn=ComponentOperationPricing.InterfaceID And ComponentInformation.ComponentID=ComponentOperationPricing.ComponentID and MachineInformation.machineid = ComponentOperationPricing.machineid
			Inner Join (
				Select MachineID,ComponentID,OperationNo,StartTime,EndTime,ActualCount,IdealCount From #Exceptions
			)AS Tt1 ON Tt1.MachineID=MachineInformation.MachineID AND Tt1.ComponentID = ComponentInformation.ComponentID AND Tt1.OperationNo= ComponentOperationPricing.OperationNo
			Where (autodata.ndtime>Tt1.StartTime) AND (autodata.ndtime<=Tt1.EndTime) and (autodata.datatype=1) 
			AND (autodata.ndtime > ''' + convert(nvarchar(20),@StartTime,120)+''' AND autodata.ndtime<=''' + convert(nvarchar(20),@EndTime,120)+''' )'
	Select @StrSql = @StrSql+ @StrMachine + @stroperator
	Select @StrSql = @StrSql+' Group by MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,employeeinformation.employeeid,ActualCount,IdealCount) as T2 
	Group by MachineID,ComponentID,OperationNo,employeeid	--,Tt1.StartTime,Tt1.EndTime
	)AS T1	WHERE  #TmpJobCard.MachineID=T1.MachineID AND #TmpJobCard.ComponentID = T1.ComponentID AND #TmpJobCard.OperationNo=T1.OperationNo And #TmpJobCard.OperatorID=T1.employeeid'
	Exec(@StrSql)
	print @StrSql
END

--ER0210 /*  Exception rules and PLD rules can overlap : To handle production count in such situations */
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
			insert into #PlannedDownTimes(Machine,StartTime,EndTime)  
			select Machine,
			CASE When StartTime<@StartTime Then @StartTime Else StartTime End,
			case When EndTime>@EndTime Then @EndTime Else EndTime End 
			FROM PlannedDownTimes
			WHERE PDTstatus = 1 and 
			((StartTime >= @StartTime  AND EndTime <=@EndTime) 
			OR ( StartTime < @StartTime  AND EndTime <= @EndTime AND EndTime > @StartTime )
			OR ( StartTime >= @StartTime   AND StartTime <@EndTime AND EndTime > @EndTime )
			OR ( StartTime < @StartTime  AND EndTime > @EndTime))
			and machine in (select distinct machineid from #TmpJobCard)
			ORDER BY StartTime

	Select @StrSql =''
	Select @StrSql ='UPDATE #TmpJobCard SET OperationCount=ISNULL(#TmpJobCard.OperationCount,0) - ISNULL(T3.Comp,0)
	From
	(
		SELECT T2.MachineID,T2.ComponentID,T2.OperationNo,T2.OperatorID,T2.StartTime AS StartTime,T2.EndTime AS EndTime,
		SUM(CEILING (CAST(T2.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp 
		From 
		(
			select MachineInformation.MachineID,C.ComponentID,O.OperationNo,EmployeeInformation.EmployeeID as OperatorID,mc,comp,opn,opr,
			Max(T1.XStartTime)StartTime,Max(T1.XEndTime)EndTime,T1.PLD_StartTime,T1.PLD_EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from autodata 
			Inner Join MachineInformation   ON autodata.MC=MachineInformation.InterfaceID 
			Inner Join EmployeeInformation   ON autodata.Opr=EmployeeInformation.InterfaceID
			Inner Join ComponentInformation  C ON autodata.Comp = C.InterfaceID
			Inner Join ComponentOperationPricing O on autodata.Opn=O.InterfaceID And C.ComponentID=O.ComponentID And O.MachineID=MachineInformation.MachineID
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

				From #Exceptions AS Ex CROSS JOIN #PlannedDownTimes AS Td
				Where ((Td.StartTime>=Ex.StartTime And Td.EndTime <=Ex.EndTime)OR
				(Td.StartTime< Ex.StartTime And Td.EndTime<=Ex.EndTime AND Td.EndTime>Ex.StartTime)OR
				(Td.StartTime>= Ex.StartTime And Td.StartTime <Ex.EndTime AND Td.EndTime>Ex.EndTime)OR
				(Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime))'
		Select @StrSql = @StrSql + ' )AS T1 ON T1.MachineID=MachineInformation.MachineID AND T1.ComponentID = C.ComponentID AND T1.OperationNo= O.OperationNo
			Where (autodata.ndtime>T1.PLD_StartTime AND autodata.ndtime<=T1.PLD_EndTime) and (autodata.datatype=1) 
		AND (autodata.ndtime > ''' + convert(nvarchar(20),@StartTime,120)+''' AND autodata.ndtime<=''' + convert(nvarchar(20),@EndTime,120)+''' )'
		Select @StrSql = @StrSql +  @StrMachine + @stroperator
		Select @StrSql = @StrSql+' Group by MachineInformation.MachineID,C.ComponentID,O.OperationNo,EmployeeInformation.EmployeeID,T1.PLD_StartTime,T1.PLD_EndTime,mc,comp,opn,opr
		)AS T2 
		Inner join machineinformation M on T2.mc=M.interfaceid
		Inner join componentinformation C on T2.Comp=C.interfaceid 
		Inner join ComponentOperationPricing O ON T2.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineID=M.Machineid
		Inner join EmployeeInformation E on T2.opr=E.interfaceID
		GROUP BY T2.MachineID,T2.ComponentID,T2.OperationNo,T2.OperatorID,T2.StartTime,t2.EndTime
	)As T3
	WHERE #TmpJobCard.MachineID=T3.MachineID AND #TmpJobCard.ComponentID = T3.ComponentID AND #TmpJobCard.OperationNo=T3.OperationNo AND #TmpJobCard.OperatorID=T3.OperatorID'
	PRINT @StrSql
	EXEC(@StrSql)
END

--ER0210

--ER0210
--UPDATE #Exceptions SET ExCount=ExCount-((ExCount * ActualCount)/ISNULL(IdealCount,0))
--UPDATE #TmpJobCard SET OperationCount = ISNULL(Tt.OpnCount,0)
--FROM
--(
--	SELECT OperatorID,Ti.MachineID,Ti.Componentid,Ti.OperationNo,(OperationCount-(OperationCount*(Ti.Ratio)))AS OpnCount
--	FROM #TmpJobCard Left Outer Join
--	(
--		SELECT #Exceptions.MachineID,#Exceptions.Componentid,#Exceptions.OperationNo,CAST(CAST (SUM(ExCount) AS FLOAT)/CAST(Max(T1.tCount)AS FLOAT )AS FLOAT) AS Ratio
--		FROM #Exceptions  Inner Join (
--			SELECT MachineID,Componentid,OperationNo,SUM(OperationCount)AS tCount
--			FROM #TmpJobCard Group By  MachineID,Componentid,OperationNo
--			)T1 ON  T1.MachineID=#Exceptions.MachineID AND T1.Componentid=#Exceptions.Componentid AND T1.OperationNo=#Exceptions.OperationNo
--		Group By  #Exceptions.MachineID,#Exceptions.Componentid,#Exceptions.OperationNo
--	)Ti ON Ti.MachineID=#TmpJobCard.MachineID AND Ti.Componentid=#TmpJobCard.Componentid AND Ti.OperationNo=#TmpJobCard.OperationNo
--) AS Tt Inner Join #TmpJobCard ON Tt.MachineID=#TmpJobCard.MachineID AND Tt.Componentid=#TmpJobCard.Componentid AND Tt.OperationNo=#TmpJobCard.OperationNo AND Tt.OperatorID=#TmpJobCard.OperatorID
--ER0210

--UtiliseTime..
UPDATE  #TmpJobCard SET ProdTime = isnull(#TmpJobCard.ProdTime,0) - isNull(t2.Down,0) FROM (
	Select employeeinformation.employeeid AS OperatorID,machineinformation.machineid AS MachineId,componentinformation.componentid AS ComponentId,componentoperationpricing.operationno AS OperationNo,
	SUM(
	CASE
		When autodata.sttime <= @StartTime Then datediff(s, @StartTime,autodata.ndtime )
		When autodata.sttime > @StartTime Then datediff(s , autodata.sttime,autodata.ndtime)
	END) as Down
	From AutoData INNER Join
		(Select mc,Comp,Opn,Opr,Sttime,NdTime From AutoData
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(msttime < @StartTime)And (ndtime > @StartTime) AND (ndtime <= @EndTime)) as T1
	ON AutoData.Opr=T1.Opr And  AutoData.mc=T1.mc  AND AutoData.Comp= T1.Comp AND AutoData.Opn=T1.Opn
	INNER JOIN machineinformation ON autodata.mc = machineinformation.InterfaceID 
	INNER JOIN employeeinformation ON autodata.opr = employeeinformation.InterfaceID  
	INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID  
	INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID AND componentinformation.componentid = componentoperationpricing.componentid and componentoperationpricing.machineid = machineinformation.machineid
	Where AutoData.DataType=2 And ( autodata.Sttime > T1.Sttime ) And ( autodata.ndtime <  T1.ndtime ) AND ( autodata.ndtime >  @StartTime )
	GROUP BY employeeinformation.employeeid,machineinformation.machineid,componentinformation.componentid, componentoperationpricing.operationno
)AS T2 Inner Join #TmpJobCard ON T2.OperatorID = #TmpJobCard.OperatorID AND T2.MachineId = #TmpJobCard.MachineId AND T2.ComponentId = #TmpJobCard.ComponentId AND T2.OperationNo = #TmpJobCard.OperationNo

--ER0210
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
BEGIN

	UPDATE #TmpJobCard set ProdTime = isnull(#TmpJobCard.ProdTime,0) - isNull(T2.PPDT ,0) FROM(
		--Production Time in PDT
		SELECT employeeinformation.employeeid AS OperatorID,machineinformation.machineid AS MachineId,componentinformation.componentid AS ComponentId,componentoperationpricing.operationno AS OperationNo,
			SUM(CASE
			WHEN autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.cycletime+autodata.loadunload)
			WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )
			WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END)  as PPDT 
		FROM AutoData CROSS jOIN #PlannedDownTimes T
		INNER JOIN machineinformation ON autodata.mc = machineinformation.InterfaceID And T.Machine=machineinformation.MachineID
		INNER JOIN employeeinformation ON autodata.opr = employeeinformation.InterfaceID  
		INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID  
		INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID AND componentinformation.componentid = componentoperationpricing.componentid and componentoperationpricing.machineid = machineinformation.machineid
		WHERE autodata.DataType=1 AND autodata.ndtime > T.StartTime AND autodata.ndtime <= T.EndTime
		GROUP BY employeeinformation.employeeid,machineinformation.machineid,componentinformation.componentid, componentoperationpricing.operationno
	)AS T2 Inner Join #TmpJobCard ON T2.OperatorID = #TmpJobCard.OperatorID AND T2.MachineId = #TmpJobCard.MachineId AND T2.ComponentId = #TmpJobCard.ComponentId AND T2.OperationNo = #TmpJobCard.OperationNo


		UPDATE #TmpJobCard set ProdTime =isnull(#TmpJobCard.ProdTime,0) + isNull(T2.IPDT ,0) 	FROM	(
			Select employeeinformation.employeeid AS OperatorID,machineinformation.machineid AS MachineId,componentinformation.componentid AS ComponentId,componentoperationpricing.operationno AS OperationNo,
			SUM(
			CASE 	
				When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
				When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
				When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
				when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
			END) as IPDT

			From AutoData INNER Join 
				(Select mc,comp,opn,Sttime,NdTime From AutoData
					Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And 
					(msttime >= @StartTime) AND (ndtime <= @EndTime)) as T1
			ON AutoData.mc=T1.mc CROSS jOIN #PlannedDownTimes T
			INNER JOIN machineinformation ON autodata.mc = machineinformation.InterfaceID And T.Machine=machineinformation.MachineID
			INNER JOIN employeeinformation ON autodata.opr = employeeinformation.InterfaceID  
			INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID  
			INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID AND componentinformation.componentid = componentoperationpricing.componentid and componentoperationpricing.machineid = machineinformation.machineid
			Where AutoData.DataType=2 
			And (( autodata.Sttime > T1.Sttime )
			And ( autodata.ndtime <  T1.ndtime ) 
			) 
			AND
			((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime )) 
			or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime) 
			or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime ) 
			or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )
			GROUP BY employeeinformation.employeeid,machineinformation.machineid,componentinformation.componentid, componentoperationpricing.operationno
		)AS T2 Inner Join #TmpJobCard ON T2.OperatorID = #TmpJobCard.OperatorID AND T2.MachineId = #TmpJobCard.MachineId AND T2.ComponentId = #TmpJobCard.ComponentId AND T2.OperationNo = #TmpJobCard.OperationNo
   
	
	/* If production  Records of TYPE-2*/
	UPDATE #TmpJobCard set ProdTime =isnull(#TmpJobCard.ProdTime,0) + isNull(T2.IPDT ,0) 	FROM	(
		Select employeeinformation.employeeid AS OperatorID,machineinformation.machineid AS MachineId,componentinformation.componentid AS ComponentId,componentoperationpricing.operationno AS OperationNo,
		SUM(
		CASE 	
			When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
			When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
			When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
			when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		From AutoData INNER Join 
			(Select mc,Sttime,NdTime From AutoData
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And 
				(msttime < @StartTime)And (ndtime > @StartTime) AND (ndtime <= @EndTime)) as T1
		ON AutoData.mc=T1.mc CROSS jOIN #PlannedDownTimes T
		INNER JOIN machineinformation ON autodata.mc = machineinformation.InterfaceID And T.Machine=machineinformation.MachineID
		INNER JOIN employeeinformation ON autodata.opr = employeeinformation.InterfaceID  
		INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID  
		INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID AND componentinformation.componentid = componentoperationpricing.componentid and componentoperationpricing.machineid = machineinformation.machineid
		Where AutoData.DataType=2
		And (( autodata.Sttime > T1.Sttime )
		And ( autodata.ndtime <  T1.ndtime ) 
		AND ( autodata.ndtime >  @StartTime )) 
		AND
		(( T.StartTime >= @StartTime )
		And ( T.StartTime <  T1.ndtime ) )
		GROUP BY employeeinformation.employeeid,machineinformation.machineid,componentinformation.componentid, componentoperationpricing.operationno
	)AS T2 Inner Join #TmpJobCard ON T2.OperatorID = #TmpJobCard.OperatorID AND T2.MachineId = #TmpJobCard.MachineId AND T2.ComponentId = #TmpJobCard.ComponentId AND T2.OperationNo = #TmpJobCard.OperationNo

End
--ER0210


SELECT
OperatorID  ,
ComponentID ,
MachineID ,
OperationNo   ,
OperationDscr ,
dbo.f_FormatTime(IdealCycleTime ,@TimeFormat) AS IdealCycleTime,
dbo.f_FormatTime(IdealLoadUnload ,@TimeFormat)AS IdealLoadUnload,
dbo.f_FormatTime(MaxCycleTime ,@TimeFormat)AS MaxCycleTime,
dbo.f_FormatTime(MinCycleTime ,@TimeFormat)AS MinCycleTime,
dbo.f_FormatTime(AveCycleTime ,@TimeFormat)AS AveCycleTime,
dbo.f_FormatTime(MaxLoadUnload,@TimeFormat)AS MaxLoadUnload,
dbo.f_FormatTime(MinLoadUnload ,@TimeFormat)AS MinLoadUnload,
dbo.f_FormatTime(AveLoadUnload ,@TimeFormat)AS AveLoadUnload,
dbo.f_FormatTime(ProdTime ,@TimeFormat)AS ProdTime,
OperationCount
From #TmpJobCard
END
