/****** Object:  Procedure [dbo].[s_GetMercuryDaily_MachienwiseProdReportFrmAutodata]    Committed by VersionSQL https://www.versionsql.com ******/

/******************************************************************************************
Procedure Created by Mrudula to get Daily machinewise Production Report (Mercury Format)
mod 1 :- ER0181 By Kusuma M.H on 13-May-2009.2) Modify all the procedures accordingly. Qualify machine wherever we are making use of component and opeartion no.
mod 2 :- ER0182 By Kusuma M.H on 13-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
mod 3 :- ER0210 By Karthik G. Introduce PDT on 5150. 
			1) Handle PDT at Machine Level. 
			2) Handle interaction between PDT and Mangement Loss. Also handle interaction InCycleDown And PDT.
			3) Handle intearction between ICD and PDT for type 1 production record for the selected time period.
******************************************************************************************/
--go
--s_GetMercuryDaily_MachienwiseProdReportFrmAutodata '2009-12-01','2009-12-02','MCV 400','','',''
CREATE                          PROCEDURE [dbo].[s_GetMercuryDaily_MachienwiseProdReportFrmAutodata]
	@StartDate datetime,
	@EndDate datetime='',
	@MachineID nvarchar(50) = '',
	@ComponentID nvarchar(50) = '',
	@OperationNo nvarchar(50) = '',
	@PlantID  Nvarchar(50) = ''
AS
BEGIN
Declare @strsql nvarchar(4000)
Declare @strmachine nvarchar(255)
Declare @strcomponentid nvarchar(255)
Declare @stroperation nvarchar(255)
Declare @StrMPlantid NVarChar(255)
Declare @timeformat as nvarchar(12)
Declare @strXmachine NVarChar(255)
Declare @strXcomponentid NVarChar(255)
Declare @strXoperation NVarChar(255)
declare @TmpStDate datetime
declare @TmpEndDate datetime
Select @strsql = ''
Select @strcomponentid = ''
Select @stroperation = ''
Select @strmachine = ''
Select @StrMPlantid=''
Select @strXmachine =''
Select @strXcomponentid =''
Select @strXoperation =''
if isnull(@PlantID,'') <> ''
Begin
	---mod 2
--	Select @StrMPlantid = ' and ( PM.PlantID = ''' + @PlantID + ''')'
	Select @StrMPlantid = ' and ( PM.PlantID = N''' + @PlantID + ''')'
	---mod 2
End
if isnull(@machineid,'') <> ''
Begin
	---mod 2
--	Select @strmachine = ' and ( Machineinformation.MachineID = ''' + @MachineID + ''')'
--	Select @strXmachine = ' and ( EX.MachineID = ''' + @MachineID + ''')'
	Select @strmachine = ' and ( Machineinformation.MachineID = N''' + @MachineID + ''')'
	Select @strXmachine = ' and ( EX.MachineID = N''' + @MachineID + ''')'
	---mod 2
End
if isnull(@componentid,'') <> ''
Begin
	---mod 2
--	Select @strcomponentid = ' AND ( Componentinformation.componentid = ''' + @componentid + ''')'
--	Select @strXcomponentid = ' AND ( EX.componentid = ''' + @componentid + ''')'
	Select @strcomponentid = ' AND ( Componentinformation.componentid = N''' + @componentid + ''')'
	Select @strXcomponentid = ' AND ( EX.componentid = N''' + @componentid + ''')'
	---mod 2
End
if isnull(@operationno, '') <> ''
Begin
	---mod 2
--	Select @stroperation = ' AND ( Componentoperationpricing.operationno = ' + @OperationNo +')'
--	Select @strXoperation = ' AND ( EX.operationno = ' + @OperationNo +')'
	Select @stroperation = ' AND ( Componentoperationpricing.operationno = N''' + @OperationNo +''')'
	Select @strXoperation = ' AND ( EX.operationno = N''' + @OperationNo +''')'
	---mod 2
End
Select @timeformat = isnull((select valueintext from cockpitdefaults where parameter='timeformat'),'ss')
if (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')
begin
	select @timeformat = 'ss'
end
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
CREATE TABLE #Machinelist(
			MchName nvarchar(50),
			Minterface nvarchar(50)
		)
CREATE TABLE #ShiftDefinition(
		ShiftDate  DateTime,		
		Shiftname   nvarchar(20),
		ShftSTtime  DateTime,
		ShftEndTime  DateTime
		
	)
create table #MachinelevelDetail(
		Machine nvarchar(50) not null,
		MachineInterface nvarchar(50),
		Shiftname   nvarchar(20) ,
		StartTime Datetime not null,
		EndTime DateTime,
		MDate  dateTime,
		ProductionEfficiency float default 0,
		AvailabilityEfficiency float default 0,
		OverallEfficiency float default 0,
		UtilisedTime float default 0,
		ManagementLoss float default 0,
		DownTime float default 0,
		CN float default 0,
		---mod 2 Added MLDown to store genuine downs which is contained in Management loss
		MLDown float
		---mod 2
		)
Alter Table #MachinelevelDetail
	ADD PRIMARY KEY CLUSTERED
		(Machine,StartTime) ON [PRIMARY]
create table #DaywiseDetail
(
	Machine nvarchar(50) not null,
	MachineInterface nvarchar(50),
	PDate  dateTime,
	PordEffi float default 0,
	AvailEffi float default 0,
	OverEffi float default 0,
	UtilTime float default 0,
	MgmtLoss float default 0,
	Dtime float default 0,
	COuntN float default 0,
	DownMMl float default 0,
	ProdDay integer
)

CREATE TABLE #PlannedDownTimesShift
	(
		SlNo int not null identity(1,1),
		MachineID nvarchar(50),--mod 3(1)
		MachineInterface nvarchar(50),--mod 3(1)
		Starttime datetime,
		EndTime datetime,
		ShiftSt datetime
	)

CREATE TABLE #ShiftComponentOperatorDetail
	(
		Machineid nvarchar(50),
		Shiftid nvarchar(50),
		ShiftStart datetime,
		ShiftEnd datetime,
		Pdate datetime,
		Component nvarchar(50),
		Operationno integer,
		Operator nvarchar(50),
		Production integer,
		ProdShift integer,
		ProdDay integer,
		TotProd integer,
		DownShift float ,
		DownDay float ,
		DownML float ,
		AEShift float default 0,
		PEShift float default 0,
		OEShift float default 0,
		AEDay float default 0,
		PEDay float default 0,
		OEDay float default 0
	)

INSERT INTO #ShiftDefinition(ShiftDate,Shiftname,ShftSTtime,ShftEndTime)
		Exec s_GetShiftTime @StartDate
SELECT top 1 @TmpStDate=ShftSTtime FROM #ShiftDefinition  ORDER BY ShftSTtime ASC
SELECT @TmpEndDate =ShftEndTime FROM #ShiftDefinition
SELECT @StrSql='INSERT INTO #Machinelist(MchName,Minterface)'
SELECT @StrSql=@StrSql+' SELECT distinct Machineinformation.MachineId ,Machineinformation.InterfaceID from MachineInformation  '
SELECT @StrSql=@StrSql+' inner join Autodata A on Machineinformation.interfaceid=A.mc'
SELECT @StrSql=@StrSql+' INNER JOIN EmployeeInformation E on A.opr=E.Interfaceid'
SELECT @StrSql=@StrSql+' Left Outer Join PlantMachine PM ON  Machineinformation.MachineID=PM.MachineID'
SELECT @StrSql=@StrSql+' Left Outer Join PlantEmployee Pe ON E.Employeeid=PE.Employeeid WHERE '
SELECT @StrSql=@StrSql+'  ((A.sttime>='''+Convert(NVarChar(20),@TmpStDate,20)+''' and A.ndtime<='''+Convert(NVarChar(20),@TmpEndDate,20)+''')'
--mod 3(1)
SELECT @StrSql=@StrSql+' or(A.sttime< '''+Convert(NVarChar(20),@TmpStDate,20)+''' and A.ndTime<='''+Convert(NVarChar(20),@TmpEndDate,20)+''' and A.ndTime>'''+Convert(NVarChar(20),@TmpStDate,20)+''')'
SELECT @StrSql=@StrSql+' or(A.sttime>='''+Convert(NVarChar(20),@TmpStDate,20)+''' and A.sttime< '''+Convert(NVarChar(20),@TmpEndDate,20)+''' and A.ndTime>'''+Convert(NVarChar(20),@TmpEndDate,20)+''')'
SELECT @StrSql=@StrSql+' or(A.sttime< '''+Convert(NVarChar(20),@TmpStDate,20)+''' and A.ndtime> '''+Convert(NVarChar(20),@TmpEndDate,20)+'''))'
--mod 3(1)
SELECT @StrSql=@StrSql +@StrMachine+ @StrMPlantid
--print @StrSql
exec(@StrSql)


Insert into  #DaywiseDetail(Machine,MachineInterface,PDate)
select M.MchName,M.Minterface,@StartDate from #Machinelist M order by M.MchName
DECLARE @CurDate as datetime
DECLARE @CurSttime as datetime
DECLARE @CurNdtime  as datetime
DECLARE @CurShiftName as nvarchar(50)

DECLARE TmpMachineCur CURSOR for select ShiftDate,Shiftname,ShftSTtime,ShftEndTime from #ShiftDefinition

OPEN TmpMachineCur
FETCH NEXT FROM TmpMachineCur INTO @CurDate,@CurShiftName,@CurSttime,@CurNdtime
WHILE @@FETCH_STATUS=0
BEGIN
	INSERT INTO #MachinelevelDetail(Machine,MachineInterface,Shiftname,StartTime,EndTime,Mdate )
	SELECT M.MchName,M.Minterface,@CurShiftName,@CurSttime,@CurNdtime,@CurDate
	FROM  #Machinelist M
	Order  By M.MchName
	
	--GET THE PLANNED DOWN TIMES
	insert INTO #PlannedDownTimesShift(MachineID,MachineInterface,StartTime,EndTime,Shiftst)  
	select M.MachineID,M.interfaceid,
	CASE When StartTime<@CurSttime Then @CurSttime Else StartTime End,
	case When EndTime>@CurNdtime Then @CurNdtime Else EndTime End,@CurSttime
	FROM PlannedDownTimes inner join Machineinformation M on M.MachineID = PlannedDownTimes.Machine
	WHERE (
	(StartTime >= @CurSttime  AND EndTime <=@CurNdtime)
	OR ( StartTime < @CurSttime  AND EndTime <= @CurNdtime AND EndTime > @CurSttime )
	OR ( StartTime >= @CurSttime   AND StartTime <@CurNdtime AND EndTime > @CurNdtime )
	OR ( StartTime < @CurSttime  AND EndTime > @CurNdtime) )
	And PDTstatus = 1 And machine in (select Machine from #MachinelevelDetail)--mod 3(1)
	ORDER BY StartTime
	
	select @StrSql=''
	select @StrSql='Insert into #ShiftComponentOperatorDetail(Machineid,Shiftid,ShiftStart,ShiftEnd,Pdate,Component,Operationno,Operator,Production,ProdShift,ProdDay,TotProd)'
	select @StrSql=@StrSql+'(select Machineinformation.MachineId,''' +Convert(nvarchar(50),@CurShiftName)+ ''',''' +convert(nvarchar(20),@CurSttime,120)+''',''' +convert(nvarchar(20),@CurNdtime,120)+''',''' +convert(nvarchar(20),@CurDate,120)+ ''','
	select @StrSql=@StrSql+' C.ComponentID,CO.Operationno,E.EmployeeId,CEILING(CAST(Sum(autodata.partscount)AS Float)/ISNULL(CO.SubOperations,1)),0,0,0 From '
	select @StrSql=@StrSql+' Autodata inner join Machineinformation  on autodata.mc=Machineinformation.interfaceid '
	select @StrSql=@StrSql+' inner join componentinformation C on autodata.comp=C.interfaceid '
	select @StrSql=@StrSql+' inner join componentoperationpricing CO on autodata.opn=CO.interfaceid  and C.Componentid=CO.ComponentId'
	---mod 1
	select @StrSql=@StrSql+' and CO.machineid=machineinformation.machineid '
	---mod 1
	select @StrSql=@StrSql+' inner join Employeeinformation E on autodata.opr=E.interfaceid '
	select @strsql = @strsql + ' Left Outer Join PlantMachine PM ON PM.MachineID=Machineinformation.machineid'
	select @strsql = @strsql + ' WHERE (autodata.ndtime > ''' + convert(nvarchar(20),@CurSttime,120) + ''')'
	select @strsql = @strsql + ' AND (autodata.ndtime <= ''' + convert(nvarchar(20),@CurNdtime,120) + ''') and autodata.datatype=1 '
	SELECT @StrSql=@StrSql +@StrMachine+ @StrMPlantid
	SELECT @StrSql=@StrSql + ' Group by Machineinformation.Machineid,C.ComponentID,CO.Operationno,E.EmployeeId,CO.SubOperations) order by Machineinformation.MachineId,C.ComponentID,CO.Operationno,E.EmployeeId'
	
	exec(@strsql)

	---Apply exception rule
	select @StrSql=''
	SELECT @StrSql = 'INSERT INTO #Exceptions(MachineID ,ComponentID,OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,ExCount )
		SELECT Ex.MachineID ,Ex.ComponentID,Ex.OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,0
		From ProductionCountException Ex
		Inner Join MachineInformation M ON Ex.MachineID=M.MachineID
		Inner Join ComponentInformation C ON Ex.ComponentID=C.ComponentID
		Inner Join Componentoperationpricing O ON Ex.OperationNo=O.OperationNo AND C.ComponentID=O.ComponentID '
		---mod 1		
		SELECT @StrSql = @StrSql + ' and O.MachineId=Ex.MachineId '
		---mod 1
		SELECT @StrSql = @StrSql + ' WHERE  M.MultiSpindleFlag=1 '
		SELECT @StrSql =@StrSql + @strXMachine + @strXcomponentid + @strXoperation
		SELECT @StrSql =@StrSql +'AND ((Ex.StartTime>=  ''' + convert(nvarchar(20),@CurSttime,120)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@CurNdtime,120)+''' )
			OR (Ex.StartTime< ''' + convert(nvarchar(20),@CurSttime,120)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@CurSttime,120)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@CurNdtime,120)+''')
			OR(Ex.StartTime>= ''' + convert(nvarchar(20),@CurSttime,120)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@CurNdtime,120)+''' AND Ex.StartTime< ''' + convert(nvarchar(20),@CurNdtime,120)+''')
			OR(Ex.StartTime< ''' + convert(nvarchar(20),@CurSttime,120)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@CurNdtime,120)+''' ))'
	Exec (@strsql)

	IF ( SELECT Count(*) from #Exceptions ) <> 0
	BEGIN
		UPDATE #Exceptions SET StartTime=@CurSttime WHERE (StartTime<@CurSttime)AND EndTime>@CurSttime
		UPDATE #Exceptions SET EndTime=@CurNdtime WHERE (EndTime>@CurNdtime AND StartTime<@CurNdtime )
	
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
				---mod 1
				Select @StrSql = @StrSql +' and ComponentOperationPricing.machineid=machineinformation.machineid '
				---mod 1
				Select @StrSql = @StrSql +' Inner Join (
					Select MachineID,ComponentID,OperationNo,StartTime,EndTime From #Exceptions
				)AS Tt1 ON Tt1.MachineID=MachineInformation.MachineID AND Tt1.ComponentID = ComponentInformation.ComponentID AND Tt1.OperationNo= ComponentOperationPricing.OperationNo And Tt1.MachineID = ComponentOperationPricing.MachineID
				Where (autodata.ndtime>Tt1.StartTime) AND (autodata.ndtime<=Tt1.EndTime) and (autodata.datatype=1) '
		Select @StrSql = @StrSql+ @strmachine
		Select @StrSql = @StrSql+' Group by MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,Tt1.StartTime,Tt1.EndTime,comp,opn
			) as T1
		   	Inner join componentinformation C on T1.Comp=C.interfaceid
		   	Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid '
		---mod 1
		Select @StrSql = @StrSql +' Inner join machineinformation on T1.machineid=machineinformation.machineid And o.machineID = machineinformation.machineid'
		---mod 1
		Select @StrSql = @StrSql +' GROUP BY T1.MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime,t1.EndTime
		)AS T2
		WHERE  #Exceptions.StartTime=T2.StartTime AND #Exceptions.EndTime=T2.EndTime
		AND #Exceptions.MachineID=T2.MachineID AND #Exceptions.ComponentID = T2.ComponentID AND #Exceptions.OperationNo=T2.OperationNo'
		Exec(@StrSql)
	
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
					Inner Join ComponentOperationPricing on autodata.Opn=ComponentOperationPricing.InterfaceID And ComponentInformation.ComponentID=ComponentOperationPricing.ComponentID '
					---mod 1
					Select @StrSql = @StrSql +' and ComponentOperationPricing.machineid=machineinformation.machineid '
					---mod 1
					Select @StrSql = @StrSql +'Inner Join	
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
			
						From #Exceptions AS Ex CROSS JOIN #PlannedDownTimesShift AS Td
						Where Ex.MachineID=Td.MachineID AND ((Td.StartTime>=Ex.StartTime And Td.EndTime <=Ex.EndTime)OR
						(Td.StartTime< Ex.StartTime And Td.EndTime<=Ex.EndTime AND Td.EndTime>Ex.StartTime)OR
						(Td.StartTime>= Ex.StartTime And Td.StartTime <Ex.EndTime AND Td.EndTime>Ex.EndTime)OR
						(Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime))'
				Select @StrSql = @StrSql + ' )AS T1 ON T1.MachineID=MachineInformation.MachineID AND T1.ComponentID = ComponentInformation.ComponentID AND T1.OperationNo= ComponentOperationPricing.OperationNo And
				T1.MachineID = ComponentOperationPricing.MachineID	
				Where (autodata.ndtime>T1.PLD_StartTime AND autodata.ndtime<=T1.PLD_EndTime) and (autodata.datatype=1)
				AND (autodata.ndtime > ''' + convert(nvarchar(20),@CurSttime,120)+ ''' AND autodata.ndtime<=''' + convert(nvarchar(20),@CurNdtime,120)+''' )'
				Select @StrSql = @StrSql + @strMachine
				Select @StrSql = @StrSql+' Group by MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,T1.PLD_StartTime,T1.PLD_EndTime,comp,opn
				)AS T2
				Inner join componentinformation C on T2.Comp=C.interfaceid
				Inner join ComponentOperationPricing O ON T2.Opn=O.interfaceid and C.Componentid=O.componentid '
				---mod 1
				Select @StrSql = @StrSql +' Inner join machineinformation on O.machineid=machineinformation.machineid '
				---mod 1
				Select @StrSql = @StrSql +' GROUP BY T2.MachineID,T2.ComponentID,T2.OperationNo,T2.StartTime,t2.EndTime
					)As T3
			WHERE  #Exceptions.StartTime=T3.StartTime AND #Exceptions.EndTime=T3.EndTime
			AND #Exceptions.MachineID=T3.MachineID AND #Exceptions.ComponentID = T3.ComponentID AND #Exceptions.OperationNo=T3.OperationNo'
			EXEC(@StrSql)

		END
		
		UPDATE #Exceptions SET ExCount=ExCount-((ExCount * ActualCount)/ISNULL(IdealCount,0))
	
		UPDATE #ShiftComponentOperatorDetail SET Production=ISNULL(Tt.OpnCount,0) FROM(
			SELECT @CurSttime as inittime,Operator,Ti.MachineID as machine,Ti.Componentid as component,Ti.OperationNo as operation,(Production-(Production*(Ti.Ratio)))AS OpnCount
			FROM #ShiftComponentOperatorDetail Left Outer Join (
				SELECT #Exceptions.MachineID,#Exceptions.Componentid,#Exceptions.OperationNo,CAST(CAST (SUM(ExCount) AS FLOAT)/CAST(Max(T1.tCount)AS FLOAT )AS FLOAT) AS Ratio
				FROM #Exceptions  Inner Join (
						SELECT MachineID,Component,OperationNo,SUM(Production)AS tCount
						FROM #ShiftComponentOperatorDetail where #ShiftComponentOperatorDetail.ShiftStart=@CurSttime 
						Group By  MachineID,Component,OperationNo
				)T1 ON  T1.MachineID=#Exceptions.MachineID AND T1.Component=#Exceptions.Componentid AND T1.OperationNo=#Exceptions.OperationNo
				Group By  #Exceptions.MachineID,#Exceptions.Componentid,#Exceptions.OperationNo
			)Ti ON Ti.MachineID=#ShiftComponentOperatorDetail.MachineID AND Ti.Componentid=#ShiftComponentOperatorDetail.Component 
			AND Ti.OperationNo=#ShiftComponentOperatorDetail.OperationNo
		)AS Tt InneR Join #ShiftComponentOperatorDetail ON #ShiftComponentOperatorDetail.ShiftStart=Tt.inittime and
		#ShiftComponentOperatorDetail.MachineID=Tt.Machine AND #ShiftComponentOperatorDetail.Component=Tt.Component
		AND #ShiftComponentOperatorDetail.OperationNo=Tt.Operation AND #ShiftComponentOperatorDetail.Operator=Tt.Operator
	
		
	END
	
	
	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
	BEGIN
		UPDATE #ShiftComponentOperatorDetail SET Production=ISNULL(Production,0)-T1.PlanCount
		FROM
		(
			select @CurSttime as inittime, M.MachineID ,C.ComponentID,O.OperationNo,E.EmployeeId  As Employee,CEILING(CAST(Sum(ISNULL(A.PartsCount,1)) AS Float)/ISNULL(O.SubOperations,1)) AS PlanCount
			from autodata A
			Inner Join MachineInformation M ON A.Mc=M.interfaceid
			Inner join componentinformation C on A.Comp=C.interfaceid
		   	Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid and C.Componentid=O.componentid
			inner join Employeeinformation E on A.opr=E.interfaceid
			CROSS jOIN #PlannedDownTimesShift T WHERE A.DataType=1 And T.MachineID=M.MachineID
				AND (A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)
				AND (A.ndtime > @CurSttime  AND A.ndtime <=@CurNdtime)
			Group by M.MachineID,C.ComponentID,O.OperationNo,E.EmployeeId,O.SubOperations
		)T1 inner join #ShiftComponentOperatorDetail S on S.Machineid=T1.Machineid and S.Component=T1.Componentid and
		S.OperationNo=T1.OperationNo and S.Operator=T1.Employee and S.ShiftStart=T1.inittime
			
	END
	DELETE FROM #Exceptions
	FETCH NEXT FROM TmpMachineCur INTO @CurDate,@CurShiftName,@CurSttime,@CurNdtime
	
END
CLOSE TmpMachineCur
DEALLOCATE TmpMachineCur


	

-- Get the utilised time
-- Type 1,2,3,4
UPDATE #MachinelevelDetail SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0) from (
	select mc,
		sum(case when ((autodata.msttime>=D.StartTime) and (autodata.ndtime<=D.EndTime)) then  (cycletime+loadunload)
			 when ((autodata.msttime<D.StartTime) and (autodata.ndtime>D.StartTime) and (autodata.ndtime<=D.EndTime)) then DateDiff(second, D.StartTime, ndtime)
			when ((autodata.msttime>=D.StartTime) and (autodata.msttime<D.EndTime) and (autodata.ndtime>D.EndTime)) then DateDiff(second, msttime, D.EndTime)
			when ((autodata.msttime<D.StartTime) and (autodata.ndtime>D.EndTime)) then DateDiff(second, D.StartTime, D.EndTime) END ) as cycle,
	D.StartTime as SHIFTST
	from autodata inner join #MachinelevelDetail D on autodata.mc=D.machineinterface
	where (autodata.datatype=1) AND
	(((autodata.msttime>=D.StartTime)and (autodata.ndtime<=D.EndTime))
	OR ((autodata.msttime<D.StartTime) and (autodata.ndtime>D.StartTime) and (autodata.ndtime<=D.EndTime))
	OR ((autodata.msttime>=D.StartTime) and (autodata.msttime<D.EndTime) and (autodata.ndtime>D.EndTime))
	OR((autodata.msttime<D.StartTime) and (autodata.ndtime>D.EndTime)))
	group by autodata.mc,D.StartTime
) as t2 inner join #MachinelevelDetail on t2.mc = #MachinelevelDetail.machineinterface
and t2.SHIFTST=#MachinelevelDetail.StartTime


/* Fetching Down Records from Production Cycle  */
/* If Down Records of TYPE-2*/
UPDATE  #MachinelevelDetail SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0) FROM (
	Select AutoData.mc ,SUM(
	CASE
		When autodata.sttime <= M.StartTime Then datediff(s, M.StartTime,autodata.ndtime )
		When autodata.sttime > M.StartTime Then datediff(s , autodata.sttime,autodata.ndtime)
	END) as Down,M.StartTime as ShiftStart
	From AutoData INNER Join
		(Select mc,Sttime,NdTime From AutoData inner join #MachinelevelDetail M on autodata.mc=M.MachineInterface
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(msttime < M.StartTime)And (ndtime > M.StartTime) AND (ndtime <= M.EndTime)) as T1
	ON AutoData.mc=T1.mc inner join #MachinelevelDetail M on autodata.mc=M.MachineInterface
	Where AutoData.DataType=2
	And ( autodata.Sttime > T1.Sttime )
	And ( autodata.ndtime <  T1.ndtime )
	AND ( autodata.ndtime >  M.StartTime )
	GROUP BY AUTODATA.mc,M.StartTime
)AS T2 Inner Join #MachinelevelDetail on t2.mc = #MachinelevelDetail.machineinterface
and t2.ShiftStart=#MachinelevelDetail.StartTime


/* If Down Records of TYPE-3*/
UPDATE  #MachinelevelDetail SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
FROM
(Select AutoData.mc ,
SUM(CASE
	When autodata.ndtime > M.EndTime Then datediff(s,autodata.sttime, M.EndTime )
	When autodata.ndtime <=M.EndTime Then datediff(s , autodata.sttime,autodata.ndtime)
END) as Down,M.StartTime as ShiftStart
From AutoData INNER Join
	(Select mc,Sttime,NdTime From AutoData inner join #MachinelevelDetail M on autodata.mc=M.MachineInterface
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(sttime >= M.StartTime) And (sttime < M.EndTime) And (ndtime > M.EndTime)) as T1
ON AutoData.mc=T1.mc inner join #MachinelevelDetail M on autodata.mc=M.MachineInterface
Where AutoData.DataType=2
And (T1.Sttime < autodata.sttime  )
And ( T1.ndtime >  autodata.ndtime)
AND (autodata.sttime  <  M.EndTime)
GROUP BY AUTODATA.mc,M.StartTime)AS T2 Inner Join #MachinelevelDetail on t2.mc = #MachinelevelDetail.machineinterface
and t2.ShiftStart=#MachinelevelDetail.StartTime

/* If Down Records of TYPE-4*/
UPDATE  #MachinelevelDetail SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
FROM
(Select AutoData.mc ,
SUM(CASE
	When autodata.sttime >= M.StartTime AND autodata.ndtime <= M.EndTime Then datediff(s , autodata.sttime,autodata.ndtime)
	When autodata.sttime < M.StartTime AND autodata.ndtime > M.StartTime And autodata.ndtime<=M.EndTime Then datediff(s, M.StartTime,autodata.ndtime )
	When autodata.sttime>=M.StartTime And autodata.sttime<M.EndTime And autodata.ndtime > M.EndTime Then datediff(s,autodata.sttime, M.EndTime )
	When autodata.sttime<M.StartTime AND autodata.ndtime>M.EndTime   Then datediff(s , M.StartTime,M.EndTime)
END) as Down,M.StartTime as ShiftStart
From AutoData INNER Join
	(Select mc,Sttime,NdTime From AutoData inner join #MachinelevelDetail M on autodata.mc=M.MachineInterface
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(msttime < M.StartTime)And (ndtime > M.EndTime) ) as T1
ON AutoData.mc=T1.mc inner join #MachinelevelDetail M on autodata.mc=M.MachineInterface
Where AutoData.DataType=2
And (T1.Sttime < autodata.sttime  )
And ( T1.ndtime >  autodata.ndtime)
AND (autodata.ndtime  >  M.StartTime)
AND (autodata.sttime  <  M.EndTime)
GROUP BY AUTODATA.mc,M.StartTime
)AS T2 Inner Join #MachinelevelDetail on t2.mc = #MachinelevelDetail.machineinterface
and t2.ShiftStart=#MachinelevelDetail.StartTime



---Take out the planned downs from the utilised time
if (select valueintext from cockpitdefaults where Parameter ='Ignore_Ptime_4m_PLD') ='Y'
BEGIN
	select @strsql=''
	select @strsql='UPDATE  #MachinelevelDetail SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.PlanDT,0)
	from( select T.Shiftst as intime,autodata.mc as machine,sum (CASE
						WHEN (autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN (cycletime+loadunload)
						WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
						WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )
						WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
						END ) as PlanDT
					FROM AutoData CROSS jOIN #PlannedDownTimesShift T
					INNER JOIN machineinformation M ON autodata.mc = M.InterfaceID
					Left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
					WHERE autodata.DataType=1  And T.MachineID=M.MachineID AND (
						(autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
						OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
						OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )
						OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime)
						)'
	If isnull(@MachineID,'') <> ''
	BEGIN---mod 2
	  --Select @strsql = @strsql  + ' AND ( M.machineid = ''' + @MachineID+ ''')'
		select @strsql = @strsql  + ' AND ( M.machineid = N''' + @MachineID+ ''')'
	END--mod 2
	if isnull(@PlantID,'') <> ''
	BEGIN--mod 2
	  --Select @strsql = @strsql  +  ' ANd PlantMachine.Plantid='''+ @PlantID +''' '
		Select @strsql = @strsql  +  ' ANd PlantMachine.Plantid= N'''+ @PlantID +''' '
	END--mod 2
	Select @strsql = @strsql  + 'group by autodata.mc,T.Shiftst ) as t2 inner join #MachinelevelDetail D on t2.intime=D.StartTime and t2.machine=D.machineinterface'
	exec (@strsql)
	print @strsql

--mod 3(3):Handle intearction between ICD and PDT for type 1 production record for the selected time period.
		UPDATE #MachinelevelDetail SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.icd,0) from (
		select T.Shiftst as ShiftStartTime,autodata.mc,
		sum(Case
			When (autodata.msttime >= T.StartTime and autodata.ndtime <= T.EndTime) then (autodata.cycletime+autodata.loadunload)
			When (autodata.msttime < T.StartTime and autodata.ndtime <= T.EndTime and autodata.ndtime > T.StartTime) then Datediff(s,T.StartTime,autodata.ndtime)
			When (autodata.msttime >= T.StartTime and autodata.ndtime > T.EndTime and autodata.msttime < T.EndTime) then Datediff(s,autodata.msttime,T.EndTime)
			When (autodata.msttime < T.StartTime and autodata.ndtime > T.EndTime) then Datediff(s,T.StartTime,T.EndTime)
		End) as icd
		from autodata inner join 
			(Select mc,sttime,ndtime,D.StartTime from autodata inner join #MachinelevelDetail D on autodata.mc = D.machineinterface
			 where datatype = 1 and Datediff(s,sttime,ndtime) > Cycletime and
			 (autodata.msttime >= D.StartTime and autodata.ndtime <= D.EndTime)
			 ) as t1 on (autodata.sttime > t1.sttime and autodata.ndtime < t1.ndtime) and Autodata.mc=t1.mc
		inner join 	#PlannedDownTimesShift T on autodata.mc=T.machineinterface And t1.StartTime=T.Shiftst
		where (autodata.datatype=2) AND
		((autodata.msttime >= T.StartTime and autodata.ndtime <= T.EndTime) or
		(autodata.msttime < T.StartTime and autodata.ndtime <= T.EndTime and autodata.ndtime > T.StartTime) or
		(autodata.msttime >= T.StartTime and autodata.ndtime > T.EndTime and autodata.msttime < T.EndTime) or
		(autodata.msttime < T.StartTime and autodata.ndtime > T.EndTime))
		group by autodata.mc,T.Shiftst
	) as t2 inner join #MachinelevelDetail on t2.mc = #MachinelevelDetail.machineinterface And 	t2.ShiftStartTime=#MachinelevelDetail.StartTime
--mod 3(3):Handle intearction between ICD and PDT for type 1 production record for the selected time period.

/* If production  Records of TYPE-2*/
	UPDATE #MachinelevelDetail SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.icd,0) from (
		select T.Shiftst as ShiftStartTime,autodata.mc,
		sum(Case
			When (autodata.msttime >= T.StartTime and autodata.ndtime <= T.EndTime) then (autodata.cycletime+autodata.loadunload)
			When (autodata.msttime < T.StartTime and autodata.ndtime <= T.EndTime and autodata.ndtime > T.StartTime) then Datediff(s,T.StartTime,autodata.ndtime)
			When (autodata.msttime >= T.StartTime and autodata.ndtime > T.EndTime and autodata.msttime < T.EndTime) then Datediff(s,autodata.msttime,T.EndTime)
			When (autodata.msttime < T.StartTime and autodata.ndtime > T.EndTime) then Datediff(s,T.StartTime,T.EndTime)
		End) as icd
		from autodata inner join 
			(Select mc,sttime,ndtime,D.StartTime,D.EndTime from autodata inner join #MachinelevelDetail D on autodata.mc = D.machineinterface
			 where datatype = 1 and Datediff(s,sttime,ndtime) > Cycletime and
			 (autodata.msttime < D.StartTime and autodata.ndtime > D.EndTime and autodata.ndtime <= D.EndTime)
			 ) as t1 on (autodata.sttime > t1.sttime and autodata.ndtime < t1.ndtime) and Autodata.mc=t1.mc
		inner join 	#PlannedDownTimesShift T on autodata.mc=T.machineinterface And t1.StartTime=T.Shiftst
		where (autodata.datatype=2) AND
		((autodata.msttime >= T.StartTime and autodata.ndtime <= T.EndTime) or
		(autodata.msttime < T.StartTime and autodata.ndtime <= T.EndTime and autodata.ndtime > T.StartTime) or
		(autodata.msttime >= T.StartTime and autodata.ndtime > T.EndTime and autodata.msttime < T.EndTime) or
		(autodata.msttime < T.StartTime and autodata.ndtime > T.EndTime))
		And (autodata.ndtime > T1.StartTime) And (T.StartTime <  T1.EndTime)
		group by autodata.mc,T.Shiftst
	) as t2 inner join #MachinelevelDetail on t2.mc = #MachinelevelDetail.machineinterface And 	t2.ShiftStartTime=#MachinelevelDetail.StartTime

	/* If production  Records of TYPE-3*/
	UPDATE #MachinelevelDetail SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.icd,0) from (
		select T.Shiftst as ShiftStartTime,autodata.mc,
		sum(Case
			When (autodata.msttime >= T.StartTime and autodata.ndtime <= T.EndTime) then (autodata.cycletime+autodata.loadunload)
			When (autodata.msttime < T.StartTime and autodata.ndtime <= T.EndTime and autodata.ndtime > T.StartTime) then Datediff(s,T.StartTime,autodata.ndtime)
			When (autodata.msttime >= T.StartTime and autodata.ndtime > T.EndTime and autodata.msttime < T.EndTime) then Datediff(s,autodata.msttime,T.EndTime)
			When (autodata.msttime < T.StartTime and autodata.ndtime > T.EndTime) then Datediff(s,T.StartTime,T.EndTime)
		End) as icd
		from autodata inner join 
			(Select mc,sttime,ndtime,D.StartTime,D.EndTime from autodata inner join #MachinelevelDetail D on autodata.mc = D.machineinterface
			 where datatype = 1 and Datediff(s,sttime,ndtime) > Cycletime and
			 (autodata.sttime >= D.StartTime and autodata.ndtime > D.EndTime and autodata.sttime < D.StartTime)
			 ) as t1 on (autodata.sttime > t1.sttime and autodata.ndtime < t1.ndtime) and Autodata.mc=t1.mc
		inner join 	#PlannedDownTimesShift T on autodata.mc=T.machineinterface And t1.StartTime=T.Shiftst
		where (autodata.datatype=2) AND
		((autodata.msttime >= T.StartTime and autodata.ndtime <= T.EndTime) or
		(autodata.msttime < T.StartTime and autodata.ndtime <= T.EndTime and autodata.ndtime > T.StartTime) or
		(autodata.msttime >= T.StartTime and autodata.ndtime > T.EndTime and autodata.msttime < T.EndTime) or
		(autodata.msttime < T.StartTime and autodata.ndtime > T.EndTime))
		And (autodata.sttime < t1.EndTime) And (T.EndTime > t1.sttime) 
		group by autodata.mc,T.Shiftst
	) as t2 inner join #MachinelevelDetail on t2.mc = #MachinelevelDetail.machineinterface And 	t2.ShiftStartTime=#MachinelevelDetail.StartTime

	/* If production  Records of TYPE-4*/
	UPDATE #MachinelevelDetail SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.icd,0) from (
		select T.Shiftst as ShiftStartTime,autodata.mc,
		sum(Case
			When (autodata.msttime >= T.StartTime and autodata.ndtime <= T.EndTime) then (autodata.cycletime+autodata.loadunload)
			When (autodata.msttime < T.StartTime and autodata.ndtime <= T.EndTime and autodata.ndtime > T.StartTime) then Datediff(s,T.StartTime,autodata.ndtime)
			When (autodata.msttime >= T.StartTime and autodata.ndtime > T.EndTime and autodata.msttime < T.EndTime) then Datediff(s,autodata.msttime,T.EndTime)
			When (autodata.msttime < T.StartTime and autodata.ndtime > T.EndTime) then Datediff(s,T.StartTime,T.EndTime)
		End) as icd
		from autodata inner join 
			(Select mc,sttime,ndtime,D.StartTime,D.EndTime from autodata inner join #MachinelevelDetail D on autodata.mc = D.machineinterface
			 where datatype = 1 and Datediff(s,sttime,ndtime) > Cycletime and
			 (autodata.msttime < D.StartTime and autodata.ndtime > D.EndTime)
			 ) as t1 on (autodata.sttime > t1.sttime and autodata.ndtime < t1.ndtime) and Autodata.mc=t1.mc
		inner join 	#PlannedDownTimesShift T on autodata.mc=T.machineinterface And t1.StartTime=T.Shiftst
		where (autodata.datatype=2) AND
		((autodata.msttime >= T.StartTime and autodata.ndtime <= T.EndTime) or
		(autodata.msttime < T.StartTime and autodata.ndtime <= T.EndTime and autodata.ndtime > T.StartTime) or
		(autodata.msttime >= T.StartTime and autodata.ndtime > T.EndTime and autodata.msttime < T.EndTime) or
		(autodata.msttime < T.StartTime and autodata.ndtime > T.EndTime))
		And (autodata.ndtime>t1.StartTime and Autodata.sttime < t1.EndTime) 
		group by autodata.mc,T.Shiftst
	) as t2 inner join #MachinelevelDetail on t2.mc = #MachinelevelDetail.machineinterface And 	t2.ShiftStartTime=#MachinelevelDetail.StartTime


END	

/*
--BEGIN: Get the Down Time
--Type 1,2,3,4
UPDATE #MachinelevelDetail SET downtime = isnull(downtime,0) + isNull(t2.down,0)
from
(select mc,
	sum(case when ((autodata.sttime>=D.StartTime)and (autodata.ndtime<=D.EndTime)) then  (loadunload)
	    when ((autodata.sttime<D.StartTime) and (autodata.ndtime>D.StartTime) and (autodata.ndtime<=D.EndTime)) then DateDiff(second, D.StartTime, ndtime)
	    When ((autodata.sttime>=D.StartTime)and (autodata.sttime<D.EndTime) and (autodata.ndtime>D.EndTime)) then DateDiff(second, stTime, D.EndTime)
	    When (autodata.sttime<D.StartTime and autodata.ndtime>D.EndTime) then DateDiff(second, D.StartTime, D.EndTime) END) down,D.StartTime as Shiftst
from autodata inner join #MachinelevelDetail D on  Autodata.mc=D.machineinterface
where (autodata.datatype=2) AND (((autodata.msttime>=D.StartTime)and (autodata.ndtime<=D.EndTime))
OR ((autodata.sttime<D.StartTime) and (autodata.ndtime>D.StartTime) and (autodata.ndtime<=D.EndTime))
OR ((autodata.msttime>=D.StartTime)and (autodata.sttime<D.EndTime) and (autodata.ndtime>D.EndTime))
OR (autodata.msttime<D.StartTime and autodata.ndtime>D.EndTime) )
group by autodata.mc,D.StartTime
) as t2 inner join #MachinelevelDetail on t2.mc = #MachinelevelDetail.machineinterface
and t2.Shiftst=#MachinelevelDetail.StartTime

if (select valueintext from cockpitdefaults where Parameter ='Ignore_Dtime_4m_PLD') <> 'N'
BEGIN
	Select @strsql=''
	Select @strsql= 'UPDATE #MachinelevelDetail SET downtime = isnull(downtime,0) - isNull(t2.PldDown,0) '
	Select @strsql= @strsql+ 'from(
					select T.Shiftst  as intime,autodata.mc as machine,SUM
					       (CASE
						WHEN (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN autodata.loadunload
						WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
						WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
						WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
						END ) as PldDown
					FROM AutoData CROSS jOIN #PlannedDownTimesShift T
					INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID
					INNER JOIN machineinformation M ON autodata.mc = M.InterfaceID
					Left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
					WHERE autodata.DataType=2  AND(
					(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
					OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
					OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
					OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
					) '
	If isnull(@MachineID,'') <> ''
	BEGIN
		---mod 2
--		select @strsql = @strsql  + ' AND ( M.machineid = ''' + @MachineID+ ''')'
		select @strsql = @strsql  + ' AND ( M.machineid = N''' + @MachineID+ ''')'
		---mod 2
	END
	if isnull(@PlantID,'') <> ''
	BEGIN
		---mod 2
--		Select @strsql = @strsql  +  ' ANd PlantMachine.Plantid='''+ @PlantID +''' '
		Select @strsql = @strsql  +  ' ANd PlantMachine.Plantid= N'''+ @PlantID +''' '
		---mod 2
	END
	
		
	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y' AND (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
	BEGIN
		Select @strsql = @strsql  +' AND Downcodeinformation.DownID= (SELECT ValueInText From CockpitDefaults Where Parameter =''Ignore_Dtime_4m_PLD'')'
	END
	
	Select @strsql = @strsql  +'group by autodata.mc,T.Shiftst ) as t2 inner join #MachinelevelDetail D on t2.intime=D.StartTime and t2.machine=D.machineinterface'
	exec (@strsql)
--	print @strsql
END
---MANAGEMENT LOSS CALCULATIONS
--type 1
UPDATE #MachinelevelDetail SET ManagementLoss=ISNULL(ManagementLoss,0)+T1.MLOSS
FROM
(SELECT mc,sum(case when  isnull(loadunload,0)>isnull(downcodeinformation.threshold,0) and isnull(downcodeinformation.threshold,0)>0 then isnull(downcodeinformation.threshold,0)
else loadunload END)  MLOSS,M.Starttime as shiftst from autodata
inner join downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
inner join #MachinelevelDetail M on autodata.mc=M.machineinterface
where autodata.datatype=2 and (autodata.sttime>=M.StartTime and autodata.ndTime<=M.EndTime)
and (downcodeinformation.availeffy = 1)
group by autodata.mc,M.Starttime)as T1 INNER JOIN #MachinelevelDetail M ON T1.mc=M.machineinterface and T1.Shiftst=M.Starttime
--type 2
UPDATE #MachinelevelDetail SET ManagementLoss=ISNULL(ManagementLoss,0)+T1.MLOSS
FROM
(SELECT mc,sum(case
when Datediff(second,M.StartTime,ndtime)>isnull(downcodeinformation.threshold,0) and isnull(downcodeinformation.threshold,0)>0 then isnull(downcodeinformation.threshold,0)
else  Datediff(second,M.StartTime,ndtime) END)MLOSS,M.Starttime as shiftst from autodata
inner join downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
inner join #MachinelevelDetail M on autodata.mc=M.machineinterface
where autodata.datatype=2 and (autodata.sttime<M.StartTime) and (autodata.ndtime>M.StartTime ) and (autodata.ndtime<=M.Endtime)
and (downcodeinformation.availeffy = 1)
group by autodata.mc,M.Starttime)as T1 INNER JOIN #MachinelevelDetail M
ON T1.mc=M.machineinterface and T1.Shiftst=M.Starttime
--type 3
UPDATE #MachinelevelDetail SET ManagementLoss=ISNULL(ManagementLoss,0)+T1.MLOSS
FROM
(SELECT mc,sum(case
when Datediff(second,sttime,M.Endtime)>isnull(downcodeinformation.threshold,0) and isnull(downcodeinformation.threshold,0)>0 then isnull(downcodeinformation.threshold,0)
else  Datediff(second,sttime,M.Endtime) END)MLOSS,M.Starttime as shiftst from autodata
inner join downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
inner join #MachinelevelDetail M on autodata.mc=M.machineinterface
where autodata.datatype=2
and (autodata.sttime>=M.StartTime)
and (autodata.sttime<M.Endtime )
and (autodata.ndtime>M.Endtime)
and (downcodeinformation.availeffy = 1)
group by autodata.mc,M.Starttime)as T1 INNER JOIN #MachinelevelDetail M
ON T1.mc=M.machineinterface and T1.Shiftst=M.Starttime
---type 4
UPDATE #MachinelevelDetail SET ManagementLoss=ISNULL(ManagementLoss,0)+T1.MLOSS
FROM
(SELECT mc,sum(case
when Datediff(second,M.Starttime,M.Endtime)>isnull(downcodeinformation.threshold,0) and isnull(downcodeinformation.threshold,0)>0 then isnull(downcodeinformation.threshold,0)
else  Datediff(second,M.Starttime,M.Endtime) END)MLOSS,M.Starttime as shiftst from autodata
inner join downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
inner join #MachinelevelDetail M on autodata.mc=M.machineinterface
where autodata.datatype=2
and (autodata.sttime<M.StartTime)
and (autodata.ndtime>M.Endtime)
and (downcodeinformation.availeffy = 1)
group by autodata.mc,M.Starttime)as T1 INNER JOIN #MachinelevelDetail M
ON T1.mc=M.machineinterface and T1.Shiftst=M.Starttime

*/

--DownTime and ManagementLoss::Starts Here
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y')
BEGIN
		--Down Time
		--Type 1,2,3,4
		UPDATE #MachinelevelDetail SET downtime = isnull(downtime,0) + isNull(t2.Down,0) From (

			select mc,D.StartTime as ShiftStartTime,
			sum(Case 
					When (autodata.msttime>=D.StartTime And autodata.ndtime<=D.EndTime) Then loadunload
					When (autodata.msttime< D.StartTime And autodata.ndtime>D.StartTime And autodata.ndtime<=D.EndTime) Then DateDiff(second, D.StartTime, ndtime)
					When (autodata.msttime>=D.StartTime And autodata.sttime<D.EndTime And autodata.ndtime>D.EndTime) Then DateDiff(second, stTime, D.EndTime)
					When (autodata.msttime<D.StartTime And autodata.ndtime>D.EndTime) Then DateDiff(second, D.StartTime, D.EndTime)
				End) Down
			from autodata inner join #MachinelevelDetail D on  Autodata.mc=D.machineinterface
			where (autodata.datatype=2) And
			((autodata.msttime>=D.StartTime And autodata.ndtime<=D.EndTime) or
			 (autodata.msttime< D.StartTime And autodata.ndtime>D.StartTime And autodata.ndtime<=D.EndTime) or
			 (autodata.msttime>=D.StartTime And autodata.sttime<D.EndTime And autodata.ndtime>D.EndTime) or
			 (autodata.msttime<D.StartTime And autodata.ndtime>D.EndTime)) 
			group by autodata.mc,D.StartTime

		) as t2 inner join #MachinelevelDetail on t2.mc = #MachinelevelDetail.machineinterface and t2.ShiftStartTime=#MachinelevelDetail.StartTime

		--ManagementLoss Type 1
		--Type 1,2,3,4
		UPDATE #MachinelevelDetail SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.ML,0) From (

			select mc,D.StartTime as ShiftStartTime,
			sum(Case 
					When (autodata.msttime>=D.StartTime And autodata.ndtime<=D.EndTime) Then loadunload
					When (autodata.msttime< D.StartTime And autodata.ndtime>D.StartTime And autodata.ndtime<=D.EndTime) Then DateDiff(second, D.StartTime, ndtime)
					When (autodata.msttime>=D.StartTime And autodata.sttime<D.EndTime And autodata.ndtime>D.EndTime) Then DateDiff(second, stTime, D.EndTime)
					When (autodata.msttime<D.StartTime And autodata.ndtime>D.EndTime) Then DateDiff(second, D.StartTime, D.EndTime)
				End) ML
			from autodata Inner Join #MachinelevelDetail D On  Autodata.mc=D.machineinterface
						  Inner Join downcodeinformation On autodata.dcode = downcodeinformation.interfaceid
			where (autodata.datatype=2) And (downcodeinformation.availeffy = 1) And
			((autodata.msttime>=D.StartTime And autodata.ndtime<=D.EndTime) or
			 (autodata.msttime< D.StartTime And autodata.ndtime>D.StartTime And autodata.ndtime<=D.EndTime) or
			 (autodata.msttime>=D.StartTime And autodata.sttime<D.EndTime And autodata.ndtime>D.EndTime) or
			 (autodata.msttime<D.StartTime And autodata.ndtime>D.EndTime)) 
			group by autodata.mc,D.StartTime

		) as t2 inner join #MachinelevelDetail on t2.mc = #MachinelevelDetail.machineinterface and t2.ShiftStartTime=#MachinelevelDetail.StartTime

End

---mod 2: Handling interaction between PDT and downtime . Also interaction between PDT and Management Loss
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN
	---step 1
	--Down Time
		--Type 1,2,3,4
		UPDATE #MachinelevelDetail SET downtime = isnull(downtime,0) + isNull(t2.Down,0) From (

			select mc,D.StartTime as ShiftStartTime,
			sum(Case 
					When (autodata.msttime>=D.StartTime And autodata.ndtime<=D.EndTime) Then loadunload
					When (autodata.msttime< D.StartTime And autodata.ndtime>D.StartTime And autodata.ndtime<=D.EndTime) Then DateDiff(second, D.StartTime, ndtime)
					When (autodata.msttime>=D.StartTime And autodata.sttime<D.EndTime And autodata.ndtime>D.EndTime) Then DateDiff(second, stTime, D.EndTime)
					When (autodata.msttime<D.StartTime And autodata.ndtime>D.EndTime) Then DateDiff(second, D.StartTime, D.EndTime)
				End) Down
			from autodata inner join #MachinelevelDetail D on  Autodata.mc=D.machineinterface
						  Inner Join downcodeinformation On autodata.dcode = downcodeinformation.interfaceid
			where (autodata.datatype=2) And (downcodeinformation.availeffy = 0) And
			((autodata.msttime>=D.StartTime And autodata.ndtime<=D.EndTime) or
			 (autodata.msttime< D.StartTime And autodata.ndtime>D.StartTime And autodata.ndtime<=D.EndTime) or
			 (autodata.msttime>=D.StartTime And autodata.sttime<D.EndTime And autodata.ndtime>D.EndTime) or
			 (autodata.msttime<D.StartTime And autodata.ndtime>D.EndTime)) 
			group by autodata.mc,D.StartTime

		) as t2 inner join #MachinelevelDetail on t2.mc = #MachinelevelDetail.machineinterface and t2.ShiftStartTime=#MachinelevelDetail.StartTime

	--step 2
	---mod 3 checking for (downcodeinformation.availeffy = 0) to get the overlapping PDT and Downs which is not ML
	UPDATE #MachinelevelDetail set DownTime =isnull(DownTime,0) - isNull(TT.PPDT ,0) 
	FROM(
		SELECT autodata.MC,T.Shiftst as ShiftStartTime,SUM
		   (CASE
			WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime)
			END ) as PPDT
		FROM AutoData CROSS jOIN #PlannedDownTimesShift T 
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime) 
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime) 
			)
			AND (downcodeinformation.availeffy = 0)
		group by autodata.MC,T.Shiftst
	) as TT INNER JOIN #MachinelevelDetail ON TT.mc = #MachinelevelDetail.MachineInterface And TT.ShiftStartTime = #MachinelevelDetail.StartTime 

	---step 3
	---Management loss calculation 
	---IN T1 Select get all the downtimes which is of type management loss
	---IN T2  get the time to be deducted from the cycle if the cycle is overlapping with the PDT. And it should be ML record
	---In T3 Get the real management loss , and time to be considered as real down for each cycle(by comaring with the ML threshold)
	---In T4 consolidate everything at machine level and update the same to #CockpitData for ManagementLoss and MLDown

	UPDATE #MachinelevelDetail SET  ManagementLoss = isnull(ManagementLoss,0) + isNull(t4.Mloss,0),MLDown=isNull(MLDown,0)+isNull(t4.Dloss,0) from (

			select T3.mc,T3.StartTime,T3.EndTime,sum(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss from (
				select  t1.id,T1.mc,T1.Threshold,T1.StartTime,T1.EndTime,
				case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0  
				then DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)- isnull(T1.Threshold ,0)
				else 0 End  as Dloss,
				case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0
				then isnull(T1.Threshold,0)
				else (DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)) End  as Mloss
				from 
				(select id,mc,comp,opn,opr,DC.threshold,D.StartTime,D.EndTime,
						case when autodata.sttime<D.StartTime then D.StartTime else sttime END as sttime,
						case when ndtime>D.EndTime then D.EndTime else ndtime END as ndtime
					from autodata inner join downcodeinformation DC on autodata.dcode=DC.interfaceid
					CROSS jOIN #MachinelevelDetail D
					where autodata.datatype=2 And D.MachineInterface=autodata.mc and
					(
					(autodata.sttime>=D.StartTime  and  autodata.ndtime<=D.EndTime) 
					OR (autodata.sttime<D.StartTime and  autodata.ndtime>D.StartTime and autodata.ndtime<=D.EndTime)
					OR (autodata.sttime>=D.StartTime  and autodata.sttime<D.EndTime  and autodata.ndtime>D.EndTime)
					OR (autodata.sttime<D.StartTime and autodata.ndtime>D.EndTime )
					) AND (DC.availeffy = 1)
				) as T1 	
				left outer join 
				(SELECT autodata.id,T.Shiftst as ShiftStartTime,
						   sum(CASE
						WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
						WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
						WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
						WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
						END ) as PPDT
					FROM AutoData CROSS jOIN #PlannedDownTimesShift T 
					inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
					WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
						((autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime) 
						OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
						OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
						OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime))
						AND (downcodeinformation.availeffy = 1) group  by autodata.id,T.Shiftst
					) as T2 on T1.id=T2.id and T2.ShiftStartTime=T1.StartTime 
			) as T3  group by T3.mc,T3.StartTime,T3.EndTime
		) as t4 inner join #MachinelevelDetail on t4.mc = #MachinelevelDetail.machineinterface And
		t4.StartTime = #MachinelevelDetail.StartTime

	UPDATE #MachinelevelDetail SET downtime = isnull(downtime,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)

End

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y' AND (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' 
Begin

	UPDATE #MachinelevelDetail set DownTime =isnull(DownTime,0) - isNull(TT.PPDT ,0) FROM (
		SELECT autodata.MC,T.Shiftst as ShiftStartTime,SUM
		   (CASE
			WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime)
			END ) as PPDT
		FROM AutoData CROSS jOIN #PlannedDownTimesShift T 
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND downcodeinformation.DownID=(SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD') AND
			((autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime) 
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime))
		group by autodata.MC,T.Shiftst
	) as TT INNER JOIN #MachinelevelDetail ON TT.mc = #MachinelevelDetail.MachineInterface And TT.ShiftStartTime = #MachinelevelDetail.StartTime 
End
--DownTime and ManagementLoss::Ends Here

--Type 1,2
UPDATE #MachinelevelDetail SET CN = isnull(CN,0) + isNull(t2.C1N1,0) from (
	select mc,D.Starttime as shiftst,
	SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))*autodata.partscount) C1N1
	FROM autodata INNER JOIN
	componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
	componentinformation ON autodata.comp = componentinformation.InterfaceID AND
	componentoperationpricing.componentid = componentinformation.componentid
	---mod 1
	inner join machineinformation on machineinformation.interfaceid=autodata.mc	and componentoperationpricing.machineid=machineinformation.machineid
	---mod 1
	inner join #MachinelevelDetail D on  Autodata.mc=D.machineinterface
	where (autodata.datatype=1) AND (autodata.ndtime>D.Starttime) and (autodata.ndtime<=D.Endtime)
	group by autodata.mc,D.Starttime
) as t2 inner join #MachinelevelDetail on t2.mc = #MachinelevelDetail.machineinterface and t2.shiftst=#MachinelevelDetail.Starttime



/**************Remove CN from Planned Down time **************************/
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	UPDATE #MachinelevelDetail SET CN = isnull(CN,0) - isNull(t2.C1N1,0)
	From
	(
		select A.mc,T.Shiftst as ShiftStartTime,SUM((O.cycletime * ISNULL(A.PartsCount,1))/ISNULL(O.SubOperations,1))  C1N1
		From autodata A 
		Inner Join machineinformation M on A.mc=M.interfaceid
		Inner Join componentinformation C ON A.Comp=C.interfaceid
		Inner Join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.machineid=M.machineid
		Cross Join #PlannedDownTimesShift T
		WHERE A.DataType=1 And T.MachineID = M.machineid
		AND(A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)
		Group by A.mc,T.ShiftSt
	) as T2	inner join #MachinelevelDetail D on t2.ShiftStartTime=D.Starttime and t2.mc=D.machineinterface
END



UPDATE #MachinelevelDetail SET	ProductionEfficiency   = (CN/UtilisedTime) ,
								AvailabilityEfficiency = (UtilisedTime)/(UtilisedTime + DownTime - ManagementLoss)
WHERE UtilisedTime <> 0

UPDATE #MachinelevelDetail SET	OverAllEfficiency = (ProductionEfficiency * AvailabilityEfficiency)*100,
								ProductionEfficiency = ProductionEfficiency * 100 ,
								AvailabilityEfficiency = AvailabilityEfficiency * 100

Update #DaywiseDetail set UtilTime=isnull(T1.Utime,0),
						  MgmtLoss=isnull(T1.Mtime,0),
							 Dtime=isnull(T1.Dwn,0),
							CountN=isnull(T1.CCN,0)
from (select machine,Sum(UtilisedTime) as Utime,sum(ManagementLoss) as Mtime,sum(DownTime) as Dwn ,sum(CN) as CCN from #MachinelevelDetail group by Machine)as T1
inner join #DaywiseDetail D on T1.machine=D.Machine

UPDATE #DaywiseDetail SET	 PordEffi = (COuntN/UtilTime) ,
							AvailEffi = (UtilTime)/(UtilTime + Dtime - MgmtLoss)
WHERE UtilTime <> 0

UPDATE #DaywiseDetail SET OverEffi = (PordEffi * AvailEffi)*100,
						  PordEffi = PordEffi * 100 ,
						  AvailEffi = AvailEffi * 100

UPDATE #DaywiseDetail SET DownMMl=(Dtime - MgmtLoss)

delete from #ShiftComponentOperatorDetail where Production<=0

update #ShiftComponentOperatorDetail set Prodshift=isnull(T1.Pcount,0) from (
	select  max(operator) as opr,Shiftid as shift,machineid as machine,sum(Production) as Pcount,
	max(component) as comp, max(operationno) as oprnn from
	#ShiftComponentOperatorDetail group by machineid,shiftid
)as T1 inner join #ShiftComponentOperatorDetail on #ShiftComponentOperatorDetail.machineid=T1.machine
and #ShiftComponentOperatorDetail.Component=T1.comp and #ShiftComponentOperatorDetail.operationno=T1.oprnn
and #ShiftComponentOperatorDetail.Operator=T1.opr and #ShiftComponentOperatorDetail.ShiftId=T1.shift

/*update #ShiftComponentOperatorDetail set ProdDay=isnull(T1.Counttot,0)
from (select  machineid as machineid,sum(Production) as Counttot ,max(Component) as component,
max(Operationno) as operation,
max(T2.Opr) as Operator
from #ShiftComponentOperatorDetail inner join
(select  machineid as machine, max(operator) as Opr from  #ShiftComponentOperatorDetail where Shiftid=(select top 1 shiftid from  #ShiftComponentOperatorDetail order by shiftid desc) group by machineid) as T2 on
#ShiftComponentOperatorDetail.machineid=T2.Machine
group by machineid)
as T1 inner join #ShiftComponentOperatorDetail on #ShiftComponentOperatorDetail.machineid=T1.machineid
and #ShiftComponentOperatorDetail.Component=T1.component
and #ShiftComponentOperatorDetail.operationno=T1.operation
and #ShiftComponentOperatorDetail.Operator=T1.operator
where Shiftid=(select top 1 shiftid from  #ShiftComponentOperatorDetail order by shiftstart desc)*/

update #ShiftComponentOperatorDetail set ProdDay=isnull(T1.Counttot,0) from (
	select  machineid as machineid,sum(Production) as Counttot ,max(Component) as component,
	max(Operationno) as operation,max(T2.Opr) as Operator,Max(T2.shft) as shift
	from #ShiftComponentOperatorDetail inner join
	(select  machineid as machine, max(operator) as Opr,max(shiftid) as shft from  #ShiftComponentOperatorDetail where Shiftid in (select max(shiftid) from  #ShiftComponentOperatorDetail  group by machineid) group by machineid) as T2 on
	#ShiftComponentOperatorDetail.machineid=T2.Machine group by machineid
)as T1 inner join #ShiftComponentOperatorDetail on #ShiftComponentOperatorDetail.machineid=T1.machineid
and #ShiftComponentOperatorDetail.Component=T1.component
and #ShiftComponentOperatorDetail.operationno=T1.operation
and #ShiftComponentOperatorDetail.Operator=T1.operator
and #ShiftComponentOperatorDetail.shiftid=T1.shift

update #ShiftComponentOperatorDetail set  AEShift=isnull(T1.AEEff,0),PEShift=isnull(T1.PEEffi,0),OEShift=isnull(T1.OEEffi,0),DownShift=isnull(T1.Dwn,0) from (
	select  max(operator) as opr,Shiftid as shift,machineid as machine,max(T2.PEf) as PEEffi,max(T2.Oef) as OEEffi,max(T2.Aef) as AEEff,max(T2.TotDwn) as Dwn,
	max(component) as comp, max(operationno) as oprnn from	#ShiftComponentOperatorDetail inner join
	(select machine as mach,Shiftname as shift,ProductionEfficiency as PEf,
	AvailabilityEfficiency as Aef,OverallEfficiency as Oef ,DownTime as TotDwn from #MachinelevelDetail )as T2 on
	T2.mach=#ShiftComponentOperatorDetail.machineid and #ShiftComponentOperatorDetail.shiftid=T2.shift
	group by machineid,shiftid
)as T1 inner join #ShiftComponentOperatorDetail on
#ShiftComponentOperatorDetail.machineid=T1.machine
and #ShiftComponentOperatorDetail.Component=T1.comp
and #ShiftComponentOperatorDetail.operationno=T1.oprnn
and #ShiftComponentOperatorDetail.Operator=T1.opr
and #ShiftComponentOperatorDetail.ShiftId=T1.shift

update #ShiftComponentOperatorDetail set DownDay=isnull(T1.Dwn,0),DownML=isnull(T1.DML,0),AEDay=isnull(T1.AEf,0),PEDay=isnull(T1.Pef,0),OEDay=isnull(T1.Oef,0) From (
	select machineid as machineid,max(Component) as component,max(Operationno) as operation,
	max(T2.Opr) as Operator,Max(T2.shft) as shift,max(T3.DTim) as Dwn,max(T3.DMLTime) as DML,max(T3.AED) as AEf,max(T3.PED) as Pef,max(T3.OED) as Oef
	from #ShiftComponentOperatorDetail inner join
	(select  machineid as machine, max(operator) as Opr ,max(shiftid) as shft from  #ShiftComponentOperatorDetail where Shiftid in (select max(shiftid) from  #ShiftComponentOperatorDetail  group by machineid) group by machineid) as T2 on
	#ShiftComponentOperatorDetail.machineid=T2.Machine
	inner join (select machine as Machid,max(DTime) as DTim,max(DownMML) as DMLTime, max(AvailEffi) as AED,max(PordEffi) as PED,max(OverEffi) as OED from #DaywiseDetail group by machine) as  T3 on
	#ShiftComponentOperatorDetail.machineID=T3.Machid
	group by machineid
)as T1 inner join #ShiftComponentOperatorDetail on #ShiftComponentOperatorDetail.machineid=T1.machineid
and #ShiftComponentOperatorDetail.Component=T1.component
and #ShiftComponentOperatorDetail.operationno=T1.operation
and #ShiftComponentOperatorDetail.Operator=T1.operator
and #ShiftComponentOperatorDetail.shiftid=T1.shift
update #ShiftComponentOperatorDetail set TotProd=(select sum(Production)from  #ShiftComponentOperatorDetail)



select
		Machineid ,
		Shiftid ,
		ShiftStart,
		ShiftEnd ,
		Pdate ,
		Component ,
		Operationno ,
		Operator ,
		Production ,
		ProdShift ,
		ProdDay ,
		TotProd ,
		dbo.f_FormatTime(DownShift,@timeformat) as  DownShift ,
		dbo.f_FormatTime(DownDay,@timeformat) as  DownDay ,
		dbo.f_FormatTime(DownML,@timeformat) as  DownML ,
		AEShift ,
		PEShift ,
		OEShift ,
		AEDay ,
		PEDay ,
		OEDay ,
		isnull(DownShift,0) as DwnShftSec,
		isnull(DownDay,0) as DwnDaySec,
		isnull(DownML,0) as DwnMLSec
	from #ShiftComponentOperatorDetail order by Machineid asc,Shiftstart asc
END
