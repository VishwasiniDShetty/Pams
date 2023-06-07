/****** Object:  Procedure [dbo].[s_GetWeeklyOperatorEfficiency]    Committed by VersionSQL https://www.versionsql.com ******/

/***********************************************************************************************
Note:- --Getting latest defined target for M C O combination Not calculating Ideal count based on regular settings
* Procedure Created By Sangeeta Kallur on 02-Mar-2007.
* Requirement From :: NSPL - CHENNAI
* To find the Operator Efficincy = Actual Count/Target {Should consider revised target }
*Procedure altered by Shilpa H.M:DR0108:for comparing the interfaceid with an integer 0[mod1]
mod 2 :- ER0181 By Kusuma M.H on 13-May-2009.2) Modify all the procedures accordingly. Qualify machine wherever we are making use of component and opeartion no.
mod 3 :- ER0182 By Kusuma M.H on 13-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
mod 4:- By Mrudula M. Rao on 26-feb-2009 for ER0220.
	StandardReports/Production Report Operator Wise--->Efficiency report
	1)Update production count calculation to hadle exceptions
	2) Update utilised time calculation to remove ICD.
mod 5:- By Mrudula M. Rao on 26-feb-2009.ER0210 Introduce PDT on 5150.
	1) Handle PDT at Machine Level.
	2) Improve the performance.
DR0236 - By SwathiKS on 23-Jun-2010 :: Use proper conditions in case statements to remove icd's from type 4 production records.
DR0285 - SwathiKS - 21/Jun/2011 :: While Calculating Operator efficiency Operator qualification has been missed out.
--s_GetWeeklyOperatorEfficiency '2009-04-01','2009-04-08','','A55','Z202.533   KLK COVER DIA 305X138','11','ARVIND S.P.'
************************************************************************************************/
CREATE                PROCEDURE [dbo].[s_GetWeeklyOperatorEfficiency]
		@StartTime AS Datetime,			
		@EndTime AS datetime,
		@PlantID AS Nvarchar(50)='',
		@MachineID AS Nvarchar(50),
		@ComponentID AS Nvarchar(50),
		@OperationNo AS Nvarchar(20),
		@OperatorID AS Nvarchar(50)=''
AS
BEGIN
DECLARE @StrSql AS NVarChar(4000)
DECLARE @StrOpr AS NVarChar(250)
DECLARE @NoOfShifts AS INTEGER
DECLARE @WeekSt As DateTime
DECLARE @TargetPerShift AS INTEGER
DECLARE @CycleTime AS INTEGER
---mod 5
declare @StrPLD_DownId as nvarchar(100)
DECLARE @Param1 AS NVarChar(1500) 
select @StrPLD_DownId=''
select @Param1=''
---mod 5
SELECT @StrOpr=''
SELECT @StrSql=''
If ISNULL(@OperatorID,'')<>''
BEGIN
	---mod 3
--	SELECT @StrOpr=' AND E.EmployeeID='''+@OperatorID+''' '
	SELECT @StrOpr=' AND E.EmployeeID=N'''+@OperatorID+''' '
	---mod 3
END
	CREATE TABLE #OperatorData
	(
		OperatorID Nvarchar(50),
		InterfaceID NVarChar(50),
		StartDate DateTime,
		EndDate DateTime,
		pCount Float DEFAULT 0,
		Target Float DEFAULT 0,
		Ratio Float DEFAULT 0,
		UtilisedTime Int DEFAULT 0,
		Effy Float DEFAULT 0
	)
	CREATE TABLE #Data
	(
		StartDate DateTime,
		EndDate DateTime,
		Target Int DEFAULT 0,
		DownTime Int DEFAULT 0,
		LossDueToDown Int DEFAULT 0
	)
	
	---mod 4
	CREATE TABLE #Exceptions
	(
		MachineID NVarChar(50),
		ComponentID Nvarchar(50),
		OperationNo Int,
		StartTime DateTime,
		EndTime DateTime,
		DurStart datetime,
		DurEnd datetime,
		IdealCount Int,
		ActualCount Int,
		ExCount Int DEFAULT 0
	)
	---mod 4
	---mod 5
	CREATE TABLE #PlannedDownTimes
	(
		StartTime DateTime,
		EndTime DateTime,
		Machine nvarchar(50),
		Dstart datetime,
		Dend datetime
	)
	
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y' AND (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
BEGIN
	SELECT @StrPLD_DownId=' AND D.DownID= (SELECT ValueInText From CockpitDefaults Where Parameter =''Ignore_Dtime_4m_PLD'')'
END
---mod 5
SELECT @WeekSt=@StartTime
WHILE @WeekSt<=@EndTime
BEGIN
	INSERT INTO #Data(StartDate,EndDate)
	SELECT dbo.f_GetLogicalDay(@WeekSt,'Start'), dbo.f_GetLogicalDay(@WeekSt,'End')
	SELECT @WeekSt=DATEADD(DAY,1,@WeekSt)
END	
SELECT @StrSql = 'INSERT INTO #OperatorData(OperatorID,InterfaceID,StartDate,EndDate)
SELECT EmployeeID,InterfaceID,StartDate,EndDate FROM EmployeeInformation E CROSS JOIN #Data Where InterfaceID<>''0'' ' -- mod1
SELECT @StrSql = @StrSql + @StrOpr
Exec(@StrSql)
--mod 5



insert into #PlannedDownTimes(StartTime,EndTime,Machine,
		DStart ,
		Dend )  select
	CASE When StartTime<#Data.StartDate Then #Data.StartDate Else StartTime End,
	case When EndTime>#Data.EndDate Then #Data.EndDate Else EndTime End,
	PlannedDownTimes.Machine,#Data.StartDate,#Data.EndDate
	FROM PlannedDownTimes   cross join #Data
	WHERE pdtstatus=1 and PlannedDownTimes.Machine=@MachineID and (
	(StartTime >= #Data.StartDate  AND EndTime <=#Data.EndDate)
	OR ( StartTime < #Data.StartDate  AND EndTime <= #Data.EndDate AND EndTime > #Data.StartDate )
	OR ( StartTime >= #Data.StartDate   AND StartTime <#Data.EndDate AND EndTime > #Data.EndDate )
	OR ( StartTime < #Data.StartDate  AND EndTime > #Data.EndDate) )
	ORDER BY StartTime
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	SELECT @Param1=' AND A.ID Not In (
		Select A.ID From AutoData A
		INNER JOIN employeeinformation E ON A.opr = E.InterfaceID
		Inner join Machineinformation on A.Mc=Machineinformation.interfaceid inner join'
		--SELECT @Param1=' #PlannedDownTimes on #PlannedDownTimes.Machine=Machineinformation.Machienid'--DR0285
		SELECT @Param1=@Param1 + ' #PlannedDownTimes on #PlannedDownTimes.Machine=Machineinformation.Machineid'--DR0285
		SELECT @Param1=@Param1 + ' Where DataType=1 And A.ndtime>StartTime And A.NdTime<=EndTime And
		A.Mc=(Select InterfaceID From MachineInformation Where MachineID=N'''+@MachineID+''' ) AND
		A.Comp=(Select InterfaceID From ComponentInformation Where ComponentID=N'''+@ComponentID+''') And
		A.Opn=(Select InterfaceID From ComponentOperationPricing Where  ComponentID=N'''+@ComponentID+''' And OperationNo=N'''+@OperationNo+''' and MachineID=N'''+@MachineID+''' ) '
	SELECT @Param1=@Param1 + @StrOpr
	SELECT @Param1=@Param1 + ') '
END


---mod 5
SELECT @StrSql ='UPDATE #OperatorData SET pCount=ISNULL(T2.pCount,0)
FROM
(
	SELECT E.EmployeeID,T1.StartDate,T1.EndDate,Sum(ISNULL(PartsCount,1)/isnull(O.suboperations,1)) As pCount
	From AutoData A
		Inner Join EmployeeInformation E on A.Opr=E.Interfaceid
		Inner Join MachineInformation M ON A.Mc=M.Interfaceid
		Inner Join ComponentInformation C ON A.Comp=C.Interfaceid
		Inner Join ComponentOperationPricing O ON A.Opn=O.Interfaceid AND C.ComponentID=O.ComponentID '
		---mod 2		
		SELECT @StrSql = @StrSql + ' and O.MachineId=M.MachineId '
		---mod 2
		SELECT @StrSql = @StrSql + ' inner Join(
			SELECT OperatorID,StartDate,EndDate FROM #OperatorData
		)AS T1 On E.EmployeeID=T1.OperatorID AND StartDate=T1.StartDate AND EndDate=T1.EndDate'
	SELECT @StrSql = @StrSql + ' WHERE A.NdTime>T1.StartDate AND A.NdTime<=T1.EndDate AND A.DataType=1
		AND M.MachineID=N'''+@MachineID+''' AND C.ComponentID=N'''+@ComponentID+''' AND O.OperationNo='+@OperationNo+''
SELECT @StrSql = @StrSql + @StrOpr
---mod 5
SELECT @StrSql = @StrSql +  @Param1
---mod 5
SELECT @StrSql = @StrSql + ' Group By E.EmployeeID,T1.StartDate,T1.EndDate
)AS T2 Inner JOin
	#OperatorData ON #OperatorData.OperatorID=T2.EmployeeID AND #OperatorData.StartDate=T2.StartDate AND #OperatorData.EndDate=T2.EndDate'
print @StrSql
Exec(@StrSql)





---mod 4 : Handle exceptions.
SELECT @StrSql =''
SELECT @StrSql = 'INSERT INTO #Exceptions(MachineID ,ComponentID,OperationNo,StartTime ,EndTime ,DurStart,DurEnd,IdealCount ,ActualCount ,ExCount )
		SELECT Ex.MachineID ,Ex.ComponentID,Ex.OperationNo,StartTime ,EndTime ,#Data.StartDate,#Data.EndDate,IdealCount ,ActualCount ,0
		From ProductionCountException Ex
		Inner Join MachineInformation M ON Ex.MachineID=M.MachineID
		Inner Join ComponentInformation C ON Ex.ComponentID=C.ComponentID
		Inner Join Componentoperationpricing O ON Ex.OperationNo=O.OperationNo AND C.ComponentID=O.ComponentID '
SELECT @StrSql = @StrSql + ' and O.MachineId=Ex.MachineId cross join #Data '
SELECT @StrSql = @StrSql + ' WHERE  M.MultiSpindleFlag=1 AND '
SELECT @StrSql = @StrSql + '((Ex.StartTime>=  #Data.StartDate AND Ex.EndTime<= #Data.EndDate )
		OR (Ex.StartTime< #Data.StartDate AND Ex.EndTime> #Data.StartDate AND Ex.EndTime<= #Data.EndDate)
		OR(Ex.StartTime>= #Data.StartDate AND Ex.EndTime> #Data.EndDate AND Ex.StartTime< #Data.EndDate)
		OR(Ex.StartTime< #Data.StartDate AND Ex.EndTime> #Data.EndDate ))'
SELECT @StrSql = @StrSql + ' and Ex.MachineID=N'''+@MachineID+'''  '
Exec (@strsql)
IF ( SELECT Count(*) from #Exceptions ) <> 0
BEGIN
	UPDATE #Exceptions SET StartTime=DurStart WHERE (StartTime<DurStart AND EndTime>DurStart)
	UPDATE #Exceptions SET EndTime=DurEnd WHERE (EndTime>DurEnd AND StartTime<DurEnd )
	Select @StrSql = 'UPDATE #Exceptions SET ExCount=ISNULL(T2.Comp,0) From
	(
		SELECT T1.DurStart,T1.DurEnd,T1.MachineID AS MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime AS StartTime,T1.EndTime AS EndTime,
		SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp
	 	From (
			select Tt1.DurStart,Tt1.DurEnd,MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,comp,opn,Tt1.StartTime,Tt1.EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from autodata
			Inner Join MachineInformation   ON autodata.MC=MachineInformation.InterfaceID
			Inner Join EmployeeInformation E  ON autodata.Opr=E.InterfaceID
			Inner Join ComponentInformation  ON autodata.Comp = ComponentInformation.InterfaceID
			Inner Join ComponentOperationPricing on autodata.Opn=ComponentOperationPricing.InterfaceID And ComponentInformation.ComponentID=ComponentOperationPricing.ComponentID '
	SELECT @StrSql =@StrSql + ' and MachineInformation.machineid=ComponentOperationPricing.machineid '
	SELECT @StrSql =@StrSql +' Inner Join (
				Select DurStart,DurEnd,MachineID,ComponentID,OperationNo,StartTime,EndTime From #Exceptions
			)AS Tt1 ON Tt1.MachineID=MachineInformation.MachineID AND Tt1.ComponentID = ComponentInformation.ComponentID AND Tt1.OperationNo= ComponentOperationPricing.OperationNo
			and Tt1.Machineid=ComponentOperationPricing.MachineID
			Where (autodata.ndtime>Tt1.StartTime) AND (autodata.ndtime<=Tt1.EndTime) and (autodata.datatype=1) '
	Select @StrSql = @StrSql+' Group by MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,Tt1.StartTime,Tt1.EndTime,comp,opn,Tt1.DurStart,Tt1.DurEnd
		) as T1
	   	Inner join componentinformation C on T1.Comp=C.interfaceid
	   	Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid '
	Select @StrSql = @StrSql+' Inner join machineinformation M on T1.MachineID=M.machineid  and M.MachineId=O.MachineID'
	Select @StrSql = @StrSql+' GROUP BY T1.MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime,t1.EndTime,T1.DurStart,T1.DurEnd
	)AS T2
	WHERE  #Exceptions.StartTime=T2.StartTime AND #Exceptions.EndTime=T2.EndTime
	AND #Exceptions.MachineID=T2.MachineID AND #Exceptions.ComponentID = T2.ComponentID AND #Exceptions.OperationNo=T2.OperationNo
	and #Exceptions.DurStart=T2.DurStart and #Exceptions.DurEnd=T2.DurEnd'
	Exec(@StrSql)
	
	
	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
	BEGIN
			
		Select @StrSql =''
		Select @StrSql ='UPDATE #Exceptions SET ExCount=ISNULL(ExCount,0) - ISNULL(T3.Comp,0)
		From
		(
			SELECT T2.Dstart,T2.Dend,T2.MachineID AS MachineID,T2.ComponentID,T2.OperationNo,T2.StartTime AS StartTime,T2.EndTime AS EndTime,
			SUM(CEILING (CAST(T2.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp
			From
			(
				select T1.Dstart,T1.Dend,MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,comp,opn,
				Max(T1.XStartTime)StartTime,Max(T1.XEndTime)EndTime,T1.PLD_StartTime,T1.PLD_EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from autodata
				Inner Join MachineInformation   ON autodata.MC=MachineInformation.InterfaceID
				Inner Join ComponentInformation  ON autodata.Comp = ComponentInformation.InterfaceID
				Inner Join ComponentOperationPricing on autodata.Opn=ComponentOperationPricing.InterfaceID And ComponentInformation.ComponentID=ComponentOperationPricing.ComponentID
				and ComponentOperationPricing.Machineid=MachineInformation.Machineid
				Inner Join	
				(
					SELECT Td.Dstart,Td.Dend,MachineID,ComponentID,OperationNo,Ex.StartTime As XStartTime, Ex.EndTime AS XEndTime,
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
		
					From #Exceptions AS Ex inner  join  #PlannedDownTimes  Td on Td.Machine=Ex.Machineid
					Where   ((Td.StartTime>=Ex.StartTime And Td.EndTime <=Ex.EndTime)OR
					(Td.StartTime< Ex.StartTime And Td.EndTime<=Ex.EndTime AND Td.EndTime>Ex.StartTime)OR
					(Td.StartTime>= Ex.StartTime And Td.StartTime <Ex.EndTime AND Td.EndTime>Ex.EndTime)OR
					(Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime))  '
			Select @StrSql = @StrSql + ' )AS T1 ON T1.MachineID=MachineInformation.MachineID AND T1.ComponentID = ComponentInformation.ComponentID AND
						   T1.OperationNo= ComponentOperationPricing.OperationNo and T1.machineid=ComponentOperationPricing.Machineid
				Where (autodata.ndtime>T1.PLD_StartTime AND autodata.ndtime<=T1.PLD_EndTime) and (autodata.datatype=1)
			AND (autodata.ndtime > T1.Dstart AND autodata.ndtime<=T1.Dend )'
			Select @StrSql = @StrSql+' Group by MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,T1.PLD_StartTime,T1.PLD_EndTime,comp,opn,T1.Dstart,T1.Dend
			)AS T2
			Inner join componentinformation C on T2.Comp=C.interfaceid
			Inner join ComponentOperationPricing O ON T2.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineId=T2.MachineID
			GROUP BY T2.MachineID,T2.ComponentID,T2.OperationNo,T2.StartTime,t2.EndTime,T2.Dstart,T2.Dend
		)As T3
		WHERE  #Exceptions.StartTime=T3.StartTime AND #Exceptions.EndTime=T3.EndTime
		AND #Exceptions.MachineID=T3.MachineID AND #Exceptions.ComponentID = T3.ComponentID AND #Exceptions.OperationNo=T3.OperationNo
		and #Exceptions.DurStart=T3.DStart and #Exceptions.DurEnd=T3.DEnd'
		PRINT @StrSql
		EXEC(@StrSql)
	END
		
	UPDATE #Exceptions SET ExCount=ExCount-((ExCount * ActualCount)/ISNULL(IdealCount,0))
	
END
UPDATE #OperatorData SET pCount=isnull(pCount,0)-ISNULL(Tt.Xcount,0)
FROM
(
	SELECT OperatorID,(pCount-(pCount*(Ti.Ratio)))AS Xcount,StartDate,EndDate
	FROM #OperatorData Left Outer Join
	(
		SELECT #Exceptions.DurStart,#Exceptions.DurEnd,CAST(CAST (SUM(ExCount) AS FLOAT)/CAST(Max(T1.tCount)AS FLOAT )AS FLOAT) AS Ratio
		FROM #Exceptions  Inner Join (
				SELECT SUM(pCount)AS tCount,#OperatorData.StartDate,#OperatorData.EndDate
				FROM #OperatorData Group By  #OperatorData.StartDate,#OperatorData.EndDate
				)T1 ON  T1.StartDate=#Exceptions.Durstart AND T1.EndDate=#Exceptions.DurEnd
		Group By  #Exceptions.DurStart,#Exceptions.DurEnd
	)Ti ON #OperatorData.StartDate=Ti.Durstart AND #OperatorData.EndDate=Ti.DurEnd
)AS Tt Inner Join #OperatorData ON #OperatorData.StartDate=Tt.StartDate AND #OperatorData.EndDate=Tt.EndDate AND #OperatorData.OperatorID=Tt.OperatorID
---mod 4
SELECT @NoOfShifts=Count(*) FROM ShiftDetails Where Running = 1
--Getting latest defined target for M C O combination Not calculating Ideal count based on regular settings
SELECT @TargetPerShift = IdealCount FROM LoadSchedule
	 WHERE Machine= @MachineID AND Component=@ComponentID AND  Operation = @OperationNo
	 Order By [Date] Desc
SELECT @TargetPerShift=@TargetPerShift * @NoOfShifts
UPDATE #DATA SET Target = @TargetPerShift
SELECT @CycleTime=CycleTime FROM ComponentOperationPricing
Where ComponentID=@ComponentID AND OperationNo=@OperationNo



UPDATE #DATA SET DownTime= ISNULL(T1.tDown,0)
FROM
(
	SELECT StartDate ,EndDate ,
	SUM(
	CASE
	WHEN (A.stTime>=StartDate AND A.NdTime<=EndDate) THEN A.LoadUnload
	WHEN (A.stTime<StartDate AND A.NdTime>StartDate AND A.NdTime<=EndDate) THEN DateDiff(ss,StartDate,A.NdTime)
	WHEN (A.stTime>=StartDate AND A.stTime<EndDate AND  A.NdTime>EndDate) THEN DateDiff(ss,A.Sttime,EndDate)
	WHEN (A.stTime<StartDate AND A.NdTime>EndDate) THEN DateDiff(ss,StartDate,EndDate)
	End)AS tDown
		From AutoData A
			Inner JoIN MachineInformation M ON A.Mc=M.Interfaceid
			Inner Join ComponentInformation C ON A.Comp=C.Interfaceid
			Inner Join ComponentOperationPricing O ON A.Opn=O.Interfaceid AND C.ComponentID=O.ComponentID
			---mod 2
			and O.machineid=M.machineid
			---mod 2
			CROSS JOIN #Data
			WHERE  A.DataType=2 AND
				((A.stTime>=StartDate AND A.NdTime<=EndDate)OR
				(A.stTime<StartDate AND A.NdTime>StartDate AND A.NdTime<=EndDate)OR
				(A.stTime>=StartDate AND A.stTime<EndDate AND  A.NdTime>EndDate)OR
				(A.stTime<StartDate AND A.NdTime>EndDate))
			AND M.MachineID=@MachineID AND C.ComponentID=@ComponentID AND O.OperationNo=@OperationNo
Group By StartDate ,EndDate
)T1 Inner Join #DATA ON #DATA.StartDate=T1.StartDate AND #DATA.EndDate=T1.EndDate
SELECT @strsql=''
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
BEGIN
	SELECT @strsql = 'UPDATE #DATA set DownTime =isnull(DownTime,0) - isNull(T1.DPDT ,0)
	FROM(
		SELECT T.Dstart as StartDate ,T.Dend as EndDate , SUM
		       (CASE
			WHEN A.sttime >= T.StartTime  AND A.ndtime <=T.EndTime  THEN A.LoadUnload
			WHEN ( A.sttime < T.StartTime  AND A.ndtime <= T.EndTime  AND A.ndtime > T.StartTime ) THEN DateDiff(ss,T.StartTime,A.ndtime)
			WHEN ( A.sttime >= T.StartTime   AND A.sttime <T.EndTime  AND A.ndtime > T.EndTime  ) THEN DateDiff(ss,A.sttime,T.EndTime )
			WHEN ( A.sttime < T.StartTime  AND A.ndtime > T.EndTime ) THEN DateDiff(ss,T.StartTime,T.EndTime )
			END ) as DPDT '
	SELECT @strsql =@strsql + ' FROM AutoData A 	
			Inner join ComponentInformation C on A.comp=C.interfaceid
		Inner join ComponentOperationPricing O on A.opn=O.interfaceid and C.componentid=O.componentid
		INNER JOIN machineinformation M on A.mc=M.interfaceid
		INNER JOIN DownCodeInformation D ON A.DCode=D.Interfaceid
		inner join #PlannedDownTimes T on T.Machine=M.MachineID
		WHERE A.DataType=2  AND M.MachineID=N'''+@MachineID+''' AND C.ComponentID=N'''+@ComponentID+''' AND O.OperationNo=N'''+@OperationNo+''' AND '
	SELECT @strsql =@strsql +' (
			(A.sttime >= T.StartTime  AND A.ndtime <=T.EndTime)
			OR ( A.sttime < T.StartTime  AND A.ndtime <= T.EndTime AND A.ndtime > T.StartTime )
			OR ( A.sttime >= T.StartTime   AND A.sttime <T.EndTime AND A.ndtime > T.EndTime )
			OR ( A.sttime < T.StartTime  AND A.ndtime > T.EndTime)
			)  '
	SELECT @strsql = @strsql + @StrPLD_DownId
	SELECT @strsql = @strsql + ' GROUP BY T.Dstart ,T.Dend
	)AS T1 Inner Join #DATA ON #DATA.StartDate=T1.StartDate AND #DATA.EndDate=T1.EndDate'
	print @strsql
	EXEC(@strsql)
END

UPDATE #DATA SET LossDueToDown=DownTime/@CycleTime WHERE @CycleTime<>0
UPDATE #DATA SET Target=Target-LossDueToDown



/*             --By swathi on 05-Apr-2009 from here
SELECT @StrSql = 'UPDATE #OperatorData SET UtilisedTime= ISNULL(T1.tUT,0)
FROM
(
	SELECT StartDate ,EndDate ,OperatorID,
	SUM(
	CASE
	WHEN (A.stTime>=StartDate AND A.NdTime<=EndDate) THEN (A.LoadUnload+A.CycleTime)
	WHEN (A.stTime<StartDate AND A.NdTime>StartDate AND A.NdTime<=EndDate) THEN DateDiff(ss,StartDate,A.NdTime)
	WHEN (A.stTime>=StartDate AND A.stTime<EndDate AND  A.NdTime>EndDate) THEN DateDiff(ss,A.Sttime,EndDate)
	WHEN (A.stTime<StartDate AND A.NdTime>EndDate) THEN DateDiff(ss,StartDate,EndDate)
	End)AS tUT
		From AutoData A
			Inner JoIN MachineInformation M ON A.Mc=M.Interfaceid
			Inner Join EmployeeInformation E ON A.Opr=E.Interfaceid
			Inner Join ComponentInformation C ON A.Comp=C.Interfaceid
			Inner Join ComponentOperationPricing O ON A.Opn=O.Interfaceid AND C.ComponentID=O.ComponentID '
			
			---mod 2		
			SELECT @StrSql = @StrSql + ' and O.MachineId=M.MachineId '
			---mod 2
			SELECT @StrSql = @StrSql + 'CROSS JOIN #OperatorData
			WHERE  A.DataType=1 AND
				((A.stTime>=StartDate AND A.NdTime<=EndDate)OR
				(A.stTime<StartDate AND A.NdTime>StartDate AND A.NdTime<=EndDate)OR
				(A.stTime>=StartDate AND A.stTime<EndDate AND  A.NdTime>EndDate)OR
				(A.stTime<StartDate AND A.NdTime>EndDate)) '
			---mod 3
			SELECT @StrSql = @StrSql + ' AND M.MachineID=N'''+@MachineID+''' AND C.ComponentID=N'''+@ComponentID+''' AND O.OperationNo=N'''+@OperationNo+''' '
			---mod 3
SELECT @StrSql = @StrSql + @StrOpr
SELECT @StrSql = @StrSql +' Group By StartDate ,EndDate,OperatorID
)T1 Inner Join #OperatorData ON #OperatorData.StartDate=T1.StartDate AND #OperatorData.EndDate=T1.EndDate AND #OperatorData.OperatorID=T1.OperatorID'
*/
SELECT @StrSql = 'UPDATE #OperatorData SET UtilisedTime= ISNULL(T1.tUT,0)
FROM
(
	SELECT StartDate ,EndDate ,OperatorID,
	SUM(
	CASE
	WHEN (A.mstTime>=StartDate AND A.NdTime<=EndDate) THEN (A.LoadUnload+A.CycleTime)
	WHEN (A.mstTime<StartDate AND A.NdTime>StartDate AND A.NdTime<=EndDate) THEN DateDiff(ss,StartDate,A.NdTime)
	WHEN (A.mstTime>=StartDate AND A.mstTime<EndDate AND  A.NdTime>EndDate) THEN DateDiff(ss,A.msttime,EndDate)
	WHEN (A.mstTime<StartDate AND A.NdTime>EndDate) THEN DateDiff(ss,StartDate,EndDate)
	End)AS tUT
		From AutoData A
			Inner JoIN MachineInformation M ON A.Mc=M.Interfaceid
			Inner Join EmployeeInformation E ON A.Opr=E.Interfaceid
			Inner Join ComponentInformation C ON A.Comp=C.Interfaceid
			Inner Join ComponentOperationPricing O ON A.Opn=O.Interfaceid AND C.ComponentID=O.ComponentID '
			
			---mod 2		
			SELECT @StrSql = @StrSql + ' and O.MachineId=M.MachineId '
			---mod 2
			SELECT @StrSql = @StrSql + 'CROSS JOIN #OperatorData '
			SELECT @StrSql = @StrSql + 'WHERE  A.DataType=1 '
			SELECT @StrSql = @StrSql + 'AND E.employeeid=operatorid ' --DR0285
            SELECT @StrSql = @StrSql + 'AND
				((A.mstTime>=StartDate AND A.NdTime<=EndDate)OR
				(A.mstTime<StartDate AND A.NdTime>StartDate AND A.NdTime<=EndDate)OR
				(A.mstTime>=StartDate AND A.mstTime<EndDate AND  A.NdTime>EndDate)OR
				(A.mstTime<StartDate AND A.NdTime>EndDate)) '
			---mod 3
			SELECT @StrSql = @StrSql + ' AND M.MachineID=N'''+@MachineID+''' AND C.ComponentID=N'''+@ComponentID+''' AND O.OperationNo=N'''+@OperationNo+''' '
			---mod 3
SELECT @StrSql = @StrSql + @StrOpr
SELECT @StrSql = @StrSql +' Group By StartDate ,EndDate,OperatorID
)T1 Inner Join #OperatorData ON #OperatorData.StartDate=T1.StartDate AND #OperatorData.EndDate=T1.EndDate AND #OperatorData.OperatorID=T1.OperatorID'
--By swathi on 05-Apr-2009 Till here
print @strsql
EXEC (@StrSql)
--mod 4



--ICD for Type 2 prod record
UPDATE #OperatorData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
FROM
(Select T1.DurStrt as intime,autodata.opr ,
SUM(
CASE
	When autodata.sttime <= T1.DurStrt Then datediff(s, T1.DurStrt,autodata.ndtime )
	When autodata.sttime > T1.DurStrt Then datediff(s , autodata.sttime,autodata.ndtime)
END)  as Down
From AutoData INNER Join
	(Select opr,Sttime,NdTime,#OperatorData.Startdate as DurStrt,#OperatorData.EndDate as DurEnd
	 From AutoData inner join #OperatorData on autodata.opr=#OperatorData.InterfaceID
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(msttime < #OperatorData.Startdate)And (ndtime > #OperatorData.Startdate) AND (ndtime <= #OperatorData.EndDate)) as T1
ON autodata.opr=T1.opr
Where AutoData.DataType=2
And ( autodata.Sttime > T1.Sttime )
And ( autodata.ndtime <  T1.ndtime )
AND ( autodata.ndtime >  T1.DurStrt )
GROUP BY autodata.opr,T1.DurStrt )AS T2 Inner Join #OperatorData on t2.opr = #OperatorData.InterfaceID and t2.intime=#OperatorData.Startdate
--ICD for Type 3 prod record		
UPDATE #OperatorData SET UtilisedTime= isnull(UtilisedTime,0) - isNull(t2.Down,0)
FROM
(Select T1.DurStrt as intime,autodata.opr ,
SUM(CASE
	When autodata.ndtime > T1.DurEnd Then datediff(s,autodata.sttime, T1.DurEnd )
	When autodata.ndtime <=T1.DurEnd Then datediff(s , autodata.sttime,autodata.ndtime)
END) as Down
From AutoData INNER Join
	(Select opr,Sttime,NdTime,#OperatorData.Startdate as DurStrt,#OperatorData.EndDate as DurEnd From AutoData
	 inner join #OperatorData on autodata.opr=#OperatorData.InterfaceID
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(sttime >= #OperatorData.Startdate)And (ndtime > #OperatorData.EndDate) and sttime<#OperatorData.EndDate ) as T1
ON autodata.opr=T1.opr
Where AutoData.DataType=2
And (T1.Sttime < autodata.sttime  )
And ( T1.ndtime >  autodata.ndtime)
AND (autodata.sttime  <  T1.DurEnd)
GROUP BY autodata.opr,T1.DurStrt )AS T2 Inner Join #OperatorData on t2.opr = #OperatorData.InterfaceID and t2.intime=#OperatorData.Startdate
--ICD for Type 4 prod record	
UPDATE #OperatorData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
FROM
(Select T1.DurStrt as intime, autodata.opr ,
--DR0236 - By SwathiKS on 23-Jun-2010 FROM HERE
--SUM(CASE
--	When autodata.sttime < T1.DurStrt AND autodata.ndtime<=T1.DurEnd Then datediff(s, T1.DurStrt,autodata.ndtime )
--	When autodata.ndtime >= T1.DurEnd AND autodata.sttime>T1.DurStrt Then datediff(s,autodata.sttime, T1.DurEnd )
--	When autodata.sttime >= T1.DurStrt AND
--	     autodata.ndtime <= T1.DurEnd Then datediff(s , autodata.sttime,autodata.ndtime)
--	When autodata.sttime<T1.DurStrt AND autodata.ndtime>T1.DurEnd   Then datediff(s , T1.DurStrt,T1.DurEnd)
--END) as Down
SUM(CASE
	When autodata.sttime >= T1.DurStrt AND autodata.ndtime <= T1.DurEnd Then datediff(s , autodata.sttime,autodata.ndtime) --TYPE1
	When autodata.sttime < T1.DurStrt AND autodata.ndtime>T1.DurStrt AND autodata.ndtime<=T1.DurEnd Then datediff(s, T1.DurStrt,autodata.ndtime )--TYPE2
	When autodata.sttime>=T1.DurStrt AND autodata.sttime<T1.DurEnd AND autodata.ndtime> T1.DurEnd Then datediff(s,autodata.sttime, T1.DurEnd )--TYPE3
	When autodata.sttime<T1.DurStrt AND autodata.ndtime>T1.DurEnd   Then datediff(s , T1.DurStrt,T1.DurEnd)--TYPE4
END) as Down
--DR0236 - By SwathiKS on 23-Jun-2010 TILL HERE
From AutoData INNER Join
	(Select opr,Sttime,NdTime,#OperatorData.Startdate as DurStrt,#OperatorData.EndDate as DurEnd  From AutoData
		inner join #OperatorData on autodata.opr=#OperatorData.InterfaceID
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(msttime < #OperatorData.Startdate)And (ndtime > #OperatorData.EndDate) ) as T1
ON autodata.opr=T1.opr
Where AutoData.DataType=2
And (T1.Sttime < autodata.sttime  )
And ( T1.ndtime >  autodata.ndtime)
AND (autodata.ndtime  >  T1.DurStrt)
AND (autodata.sttime  <  T1.DurEnd)
GROUP BY autodata.opr,T1.DurStrt
)AS T2 Inner Join #OperatorData on t2.opr = #OperatorData.InterfaceID and t2.intime=#OperatorData.Startdate
---mod 4
SELECT @strsql=''
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
BEGIN
/*    By swathi on 05-Apr-2009 from here
	SELECT @StrSql = 'UPDATE #OperatorData SET UtilisedTime= ISNULL(UtilisedTime,0) - ISNULL(T1.PPDT,0)'
	SELECT @StrSql = @StrSql +' FROM(
		--Production Time in PDT
		SELECT StartDate ,EndDate ,OperatorID,SUM
			(CASE
			WHEN A.sttime >= T.StartTime  AND A.ndtime <=T.EndTime  THEN (A.cycletime+A.loadunload)
			WHEN ( A.sttime < T.StartTime  AND A.ndtime <= T.EndTime  AND A.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,A.ndtime)
			WHEN ( A.sttime >= T.StartTime   AND A.sttime <T.EndTime  AND A.ndtime > T.EndTime  ) THEN DateDiff(second,A.sttime,T.EndTime )
			WHEN ( A.sttime < T.StartTime  AND A.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END)  as PPDT
		FROM AutoData A CROSS JOIN #OperatorData
			Inner JoIN MachineInformation M ON A.Mc=M.Interfaceid
			Inner Join EmployeeInformation E ON A.Opr=E.Interfaceid
			Inner Join ComponentInformation C ON A.Comp=C.Interfaceid
			Inner Join ComponentOperationPricing O ON A.Opn=O.Interfaceid AND C.ComponentID=O.ComponentID
			inner jOIN #PlannedDownTimes T on T.Machine=M.MachineID and T.DStart=#OperatorData.StartDate and T.Dend=#OperatorData.EndDate
		WHERE A.DataType=1 AND M.MachineID=N'''+@MachineID+''' AND C.ComponentID=N'''+@ComponentID+''' AND O.OperationNo=N'''+@OperationNo+''' AND
			( (A.sttime >= T.StartTime  AND A.ndtime <=T.EndTime)
			OR ( A.sttime < T.StartTime  AND A.ndtime <= T.EndTime AND A.ndtime > T.StartTime )
			OR ( A.sttime >= T.StartTime   AND A.sttime <T.EndTime AND A.ndtime > T.EndTime )
			OR ( A.sttime < T.StartTime  AND A.ndtime > T.EndTime) )
			AND(
			(A.sttime >= StartDate  AND A.ndtime <=EndDate)
			OR ( A.sttime < StartDate  AND A.ndtime <= EndDate AND A.ndtime > StartDate )
			OR ( A.sttime >= StartDate   AND A.sttime <EndDate AND A.ndtime > EndDate )
			OR ( A.sttime < StartDate  AND A.ndtime > EndDate))  '
	SELECT @StrSql = @StrSql + @StrOpr
	SELECT @StrSql = @StrSql +' group by StartDate ,EndDate,OperatorID
	)AS T1 Inner Join #OperatorData ON #OperatorData.StartDate=T1.StartDate AND #OperatorData.EndDate=T1.EndDate AND #OperatorData.OperatorID=T1.OperatorID'
*/
SELECT @StrSql = 'UPDATE #OperatorData SET UtilisedTime= ISNULL(UtilisedTime,0) - ISNULL(T1.PPDT,0)'
	SELECT @StrSql = @StrSql +' FROM(
		--Production Time in PDT
		SELECT StartDate ,EndDate ,OperatorID,SUM
			(CASE
			WHEN (A.msttime >= T.StartTime  AND A.ndtime <=T.EndTime)  THEN (A.cycletime+A.loadunload)
			WHEN ( A.msttime < T.StartTime  AND A.ndtime <= T.EndTime  AND A.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,A.ndtime)
			WHEN ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime  AND A.ndtime > T.EndTime  ) THEN DateDiff(second,A.msttime,T.EndTime )
			WHEN ( A.msttime < T.StartTime  AND A.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END)  as PPDT
		FROM AutoData A CROSS JOIN #OperatorData
			Inner JoIN MachineInformation M ON A.Mc=M.Interfaceid
			Inner Join EmployeeInformation E ON A.Opr=E.Interfaceid
			Inner Join ComponentInformation C ON A.Comp=C.Interfaceid
			Inner Join ComponentOperationPricing O ON A.Opn=O.Interfaceid AND C.ComponentID=O.ComponentID
			inner jOIN #PlannedDownTimes T on T.Machine=M.MachineID and T.DStart=#OperatorData.StartDate and T.Dend=#OperatorData.EndDate
		WHERE A.DataType=1 AND M.MachineID=N'''+@MachineID+''' AND C.ComponentID=N'''+@ComponentID+''' AND O.OperationNo=N'''+@OperationNo+''' AND
			( (A.msttime >= T.StartTime  AND A.ndtime <=T.EndTime)
			OR ( A.msttime < T.StartTime  AND A.ndtime <= T.EndTime AND A.ndtime > T.StartTime )
			OR ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime AND A.ndtime > T.EndTime )
			OR ( A.msttime < T.StartTime  AND A.ndtime > T.EndTime) )
			AND(
			(A.msttime >= StartDate  AND A.ndtime <=EndDate)
			OR ( A.msttime < StartDate  AND A.ndtime <= EndDate AND A.ndtime > StartDate )
			OR ( A.msttime >= StartDate   AND A.msttime <EndDate AND A.ndtime > EndDate )
			OR ( A.msttime < StartDate  AND A.ndtime > EndDate))  '
	SELECT @StrSql = @StrSql + @StrOpr
	SELECT @StrSql = @StrSql +' group by StartDate ,EndDate,OperatorID
	)AS T1 Inner Join #OperatorData ON #OperatorData.StartDate=T1.StartDate AND #OperatorData.EndDate=T1.EndDate AND #OperatorData.OperatorID=T1.OperatorID'
	EXEC(@StrSql)
--By swathi on 05-Apr-2009 Till here
	
	---mod 1 Handling interaction between PDT and ICD
	/* If production  Records of TYPE-1*/
	UPDATE #OperatorData SET UtilisedTime = isnull(UtilisedTime,0)+ isNull(t2.IPDT,0)
	FROM( Select T.Dstart,AutoData.opr ,
	SUM(
	CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  AND  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT
	From AutoData INNER Join (Select opr,Sttime,NdTime,#OperatorData.Startdate as DurStrt,#OperatorData.EndDate as DurEnd
	 From AutoData inner join #OperatorData on AutoData.opr=#OperatorData.InterfaceID
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(msttime >=#OperatorData.Startdate) AND (ndtime <= #OperatorData.EndDate)
	) as T1 ON AutoData.opr=T1.opr Inner JoIN MachineInformation M ON AutoData.Mc=M.Interfaceid
	inner jOIN #PlannedDownTimes T on
	 T.Machine=M.MachineID and T1.DurStrt=T.Dstart
	Where AutoData.DataType=2
	And (( autodata.Sttime > T1.Sttime )
	And ( autodata.ndtime <  T1.ndtime ))
	AND
	((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
	or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
	or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
	or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )
	group by AutoData.opr,T.Dstart
	)as t2 inner join #OperatorData on t2.opr = #OperatorData.InterfaceID and t2.Dstart=#OperatorData.Startdate
	
		
	/* If production  Records of TYPE-2*/
	UPDATE #OperatorData SET UtilisedTime = isnull(UtilisedTime,0)+ isNull(t2.IPDT,0)
	FROM
	(Select T.Dstart,AutoData.opr ,
	SUM(
	CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  AND  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT
	From AutoData INNER Join
		(Select opr,Sttime,NdTime,#OperatorData.Startdate as DurStrt,#OperatorData.EndDate as DurEnd
	 From AutoData inner join #OperatorData on AutoData.opr=#OperatorData.InterfaceID
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(msttime < #OperatorData.Startdate)And (ndtime > #OperatorData.Startdate) AND (ndtime <= #OperatorData.EndDate))
	 as T1 on
	AutoData.opr=T1.opr Inner JoIN MachineInformation M ON AutoData.Mc=M.Interfaceid
	inner jOIN #PlannedDownTimes T on
	 T.Machine=M.MachineID and T1.DurStrt=T.Dstart
	Where AutoData.DataType=2
	And (( autodata.Sttime > T1.Sttime )
	And ( autodata.ndtime <  T1.ndtime )
	AND ( autodata.ndtime >  T.Dstart ))
	AND
	(( T.StartTime >= T.Dstart )
	And ( T.StartTime <  T1.ndtime ) )
	GROUP BY AutoData.opr,T.Dstart )as t2 inner join #OperatorData on t2.opr = #OperatorData.InterfaceID and t2.Dstart=#OperatorData.Startdate
	
	
	/* If production Records of TYPE-3*/
	UPDATE #OperatorData SET UtilisedTime = isnull(UtilisedTime,0)+ isNull(t2.IPDT,0)
	FROM
	(Select T.Dstart,AutoData.opr ,
	SUM(
	CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT
	From AutoData INNER Join
		(Select opr,Sttime,NdTime,#OperatorData.Startdate as DurStrt,#OperatorData.EndDate as DurEnd From AutoData
		 inner join #OperatorData on AutoData.opr=#OperatorData.InterfaceID
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(sttime >= #OperatorData.Startdate)And (ndtime > #OperatorData.EndDate) and sttime<#OperatorData.EndDate) as T1
	ON AutoData.opr=T1.opr Inner JoIN MachineInformation M ON AutoData.Mc=M.Interfaceid
	inner jOIN #PlannedDownTimes T on
	 T.Machine=M.MachineID and T1.DurStrt=T.Dstart
	Where AutoData.DataType=2
	And ((T1.Sttime < autodata.sttime  )
	And ( T1.ndtime >  autodata.ndtime)
	AND (autodata.sttime  <  T.Dend))
	AND
	(( T.EndTime > T1.Sttime )
	And ( T.EndTime <=T.Dend ) )
	GROUP BY AutoData.opr,T.Dstart)as t2 inner join #OperatorData on t2.opr = #OperatorData.InterfaceID and t2.Dstart=#OperatorData.Startdate
	
	
	/* If production Records of TYPE-4*/
	UPDATE #OperatorData SET UtilisedTime = isnull(UtilisedTime,0)+ isNull(t2.IPDT,0)
	FROM
	(Select T.Dstart,AutoData.opr ,
	SUM(
	CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT
	From AutoData INNER Join
		(Select opr,Sttime,NdTime,#OperatorData.Startdate as DurStrt,#OperatorData.EndDate as DurEnd  From AutoData
		inner join #OperatorData on AutoData.opr=#OperatorData.InterfaceID
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(msttime < #OperatorData.Startdate)And (ndtime > #OperatorData.EndDate)) as T1
	ON AutoData.opr=T1.opr Inner JoIN MachineInformation M ON AutoData.Mc=M.Interfaceid
	inner jOIN #PlannedDownTimes T on
	 T.Machine=M.MachineID and T1.DurStrt=T.Dstart
	Where AutoData.DataType=2
	And ( (T1.Sttime < autodata.sttime  )
		And ( T1.ndtime >  autodata.ndtime)
		AND (autodata.ndtime  >  T.Dstart)
		AND (autodata.sttime  <  T.DEnd))
	AND
	(( T.StartTime >=T.Dstart)
	And ( T.EndTime <=T.DEnd ) )
	GROUP BY AutoData.opr,T.Dstart)as t2 inner join #OperatorData on t2.opr = #OperatorData.InterfaceID and t2.Dstart=#OperatorData.Startdate
	
END
/*
UPDATE #OperatorData SET Ratio=ISNULL(T2.Ratio,0)
FROM
(
	Select #OperatorData.OperatorID,#OperatorData.StartDate,#OperatorData.EndDate,CAST(CAST(pCount AS FLOAT)/CAST(DayCount AS FLOAT) AS FLOAT) AS Ratio
	From #OperatorData
		Inner Join (
			SELECT StartDate,EndDate,Sum(pCount)As DayCount From #OperatorData
			Group By StartDate,EndDate
		)AS T1 ON #OperatorData.StartDate = T1.StartDate AND #OperatorData.EndDate=T1.EndDate
	Where DayCount<>0
)AS T2 Inner Join #OperatorData ON #OperatorData.StartDate = T2.StartDate AND #OperatorData.EndDate=T2.EndDate AND #OperatorData.OperatorID=T2.OperatorID
*/
UPDATE #OperatorData SET Ratio=(pCount * @CycleTime)/UtilisedTime
Where UtilisedTime<>0


UPDATE #OperatorData SET Target=ISNULL(T2.Target,0)
FROM
(
	SELECT #OperatorData.StartDate,#OperatorData.EndDate,OperatorID,(#DATA.Target * #OperatorData. Ratio)Target
	FROM #OperatorData INNER JOIN #DATA
		ON #DATA.StartDate=#OperatorData.StartDate AND #DATA.EndDate=#OperatorData.EndDate
)T2 INNER JOIN #OperatorData ON  #OperatorData.StartDate = T2.StartDate AND #OperatorData.EndDate=T2.EndDate AND #OperatorData.OperatorID=T2.OperatorID
UPDATE #OperatorData SET Effy=(pCount/Target)*100 Where Target<>0
SELECT
#OperatorData.OperatorID,
#OperatorData.StartDate ,
#OperatorData.EndDate ,
#OperatorData.pCount ,
#OperatorData.Target AS OprTarget ,
#DATA.Target As DayTarget,
#OperatorData.Effy ,
dbo.f_FormatTime(DownTime,'hh:mm:ss')DownTime,
#OperatorData.UtilisedTime,
#OperatorData.Ratio,
LossDuetoDown
From #OperatorData
	Inner Join #DATA ON #DATA.StartDate=#OperatorData.StartDate AND #DATA.EndDate=#OperatorData.EndDate
where #OperatorData.Effy<>0 --DR0285
--Where OperatorID=@OperatorID
END
