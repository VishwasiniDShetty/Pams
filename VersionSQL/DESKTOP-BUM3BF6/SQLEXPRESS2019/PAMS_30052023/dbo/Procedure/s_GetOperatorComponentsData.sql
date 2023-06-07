/****** Object:  Procedure [dbo].[s_GetOperatorComponentsData]    Committed by VersionSQL https://www.versionsql.com ******/

/**************************** History *********************************************************
changed To Support SubOperations at CO Level{AutoAxel Request}.
Changed in Avg,Min,Max Calns
Procedure Altered by SSK on 06-Oct-2006 to include Plant Concept
Procedure Changed By Sangeeta Kallur on 26-FEB-2007 :
	[MAINI Req] :Production Count Exception for multispindle Machines.
mod 1 :- ER0181 By Kusuma M.H on 13-May-2009.2) Modify all the procedures accordingly. Qualify machine wherever we are making use of component and opeartion no.
mod 2 :- ER0182 By Kusuma M.H on 13-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
mod 3 :-By Mrudula M. Rao on 15-feb-2009.ER0210 Introduce PDT on 5150.
	1) Handle PDT at Machine Level. 
	2) Handle interaction between PDT and Mangement Loss. Also handle interaction InCycleDown And PDT.
	3) Improve the performance.
	4) Handle intearction between ICD and PDT for type 1 production record for the selected time period.

***********************************************************************************************/
CREATE                    PROCEDURE [dbo].[s_GetOperatorComponentsData]
	@StartDate datetime  OUTPUT,
	@Operator nvarchar(50) = '',
	@MachineID nvarchar(50) = '',
	@OperatorLabel nvarchar(50) = 'ALL',
	@MachineIdLabel nvarchar(50) = 'ALL',
	@PlantID nvarchar(50) = ''
	
AS
BEGIN
Declare @StartTime as datetime
Declare @EndTime as datetime
Declare @strsql nvarchar(4000)
Declare @stroperator nvarchar(255)
Declare @strMachine nvarchar(255)
Declare @TimeFormat as nvarchar(50)
Declare @StrPlantID as nvarchar(255)
Declare @StrxMachine as nvarchar(255)
--mod 3
Declare @Param1 As NVarChar(1000)
---mod 3
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
CREATE TABLE #TmpOperator
(
	OperatorID NVarChar(50),
	ComponentID NVarChar(50),
	MachineID NVarChar(50),
	OperationNo Int ,
	IdealCycleTime NVarChar(50),
	IdealLoadUnload NVarChar(50),
	MaxCycleTime NVarChar(50),
	MinCycleTime NVarChar(50),
	AveCycleTime NVarChar(50),
	MaxLoadUnload NVarChar(50),
	MinLoadUnload NVarChar(50),
	AveLoadUnload NVarChar(50),
	OperationCount Int Default 0
)
---mod 3
create table #PlannedDowntimes
(
	StartTime datetime,
	EndTime datetime,
	Machine nvarchar(50)
)
---mod 3
SELECT @strMachine = ''
SELECT @strsql = ''
SELECT @stroperator = ''
SELECT @StrPlantID=''
SELECT @StrxMachine=''
--mod 3
select @Param1=''
--mod 3


SELECT @TimeFormat = 'ss'
SELECT @TimeFormat = isnull((SELECT  ValueInText  FROM CockpitDefaults WHERE Parameter = 'TimeFormat'),'ss')
if (@TimeFormat <> 'hh:mm:ss' and @TimeFormat <> 'hh' and @TimeFormat <> 'mm' and @TimeFormat <> 'ss' )
begin
	select @TimeFormat = 'ss'
end
if isnull(@PlantID, '') <> ''
begin
	---mod 2
--	select @StrPlantID = ' AND ( PlantMachine.PlantID = ''' + @PlantID + ''')'
	select @StrPlantID = ' AND ( PlantMachine.PlantID = N''' + @PlantID + ''')'
	---mod 2
end
if isnull(@operator, '') <> ''
begin
	---mod 2
--	select @stroperator = ' AND ( employeeinformation.employeeid = ''' + @Operator + ''')'
	select @stroperator = ' AND ( employeeinformation.employeeid = N''' + @Operator + ''')'
	---mod 2
end
if isnull(@MachineId, '') <> ''
begin
	---mod 2
--	select @strMachine = ' AND ( machineInformation.machineId = ''' + @MachineId + ''')'
--	select @StrxMachine = ' AND ( Ex.MachineId = ''' + @MachineId + ''')'
	select @strMachine = ' AND ( machineInformation.machineId = N''' + @MachineId + ''')'
	select @StrxMachine = ' AND ( Ex.MachineId = N''' + @MachineId + ''')'
	---mod 2
end
--Get Logical day start and end
select @StartTime = dbo.f_GetLogicalDay(@StartDate,'start')
select @EndTime = dbo.f_GetLogicalDay(@StartDate,'end')

--mod 3: Get PDT
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	

	select @strsql=' insert INTO #PlannedDownTimes(StartTime,EndTime,Machine)
			SELECT 
			CASE When P.StartTime<'''+ convert(nvarchar(20),@StartTime,120)+''' Then ''' + convert(nvarchar(20),@StartTime,120)+'''  Else P.StartTime End As StartTime,
			CASE When P.EndTime>''' + convert(nvarchar(20),@EndTime,120)+'''  Then ''' + convert(nvarchar(20),@EndTime,120)+'''  Else P.EndTime End As EndTime,Machine
			FROM PlannedDownTimes P 
			WHERE (
			(P.StartTime >= ''' + convert(nvarchar(20),@StartTime,120)+'''  AND P.EndTime <= ''' + convert(nvarchar(20),@EndTime,120)+''' ) 
			OR ( P.StartTime <  ''' + convert(nvarchar(20),@StartTime,120)+'''   AND P.EndTime <= ''' + convert(nvarchar(20),@EndTime,120)+''' AND P.EndTime >  ''' + convert(nvarchar(20),@StartTime,120)+'''  )
			OR ( P.StartTime >=  ''' + convert(nvarchar(20),@StartTime,120)+'''    AND P.StartTime <''' + convert(nvarchar(20),@EndTime,120)+''' AND P.EndTime > ''' + convert(nvarchar(20),@EndTime,120)+''' )
			OR ( P.StartTime <  ''' + convert(nvarchar(20),@StartTime,120)+'''   AND P.EndTime >''' + convert(nvarchar(20),@EndTime,120)+''') ) and P.pdtstatus=1 '
			if isnull(@MachineId,'')<>''
			begin
				select @strsql=@strsql+' AND (P.machine =N'''+@MachineId+''') ' 
			ENd
			select @strsql=@strsql+' ORDER BY P.StartTime'
			print @strsql
			exec (@strsql)

	SELECT @Param1=' AND AutoData.ID Not In (
		Select ID From AutoData A CROSS JOIN #PlannedDownTimes  
		INNER JOIN  machineinformation ON a.mc = machineinformation.InterfaceID 
		Left Outer JOIN PlantMachine ON PlantMachine.MachineID=machineinformation.MachineID 
		INNER JOIN employeeinformation ON A.opr = employeeinformation.InterfaceID
		Where DataType=1 And A.NdTime>StartTime And A.NdTime<=EndTime'
	SELECT @Param1=@Param1 +@StrPlantID +  @strMachine + @stroperator
	SELECT @Param1=@Param1 + ')'
END
---mod 3: Get PDT



SELECT @StrSql =''
SELECT @StrSql = 'INSERT INTO #Exceptions(MachineID ,ComponentID,OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,ExCount )
		SELECT Ex.MachineID ,Ex.ComponentID,Ex.OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,0
		From ProductionCountException Ex
		Inner Join MachineInformation M ON Ex.MachineID=M.MachineID
		Inner Join ComponentInformation C ON Ex.ComponentID=C.ComponentID
		Inner Join Componentoperationpricing O ON Ex.OperationNo=O.OperationNo AND C.ComponentID=O.ComponentID '
---mod 1		
SELECT @StrSql = @StrSql + ' and O.MachineId=Ex.MachineId '
---mod 1
SELECT @StrSql = @StrSql + ' WHERE  M.MultiSpindleFlag=1 AND '
SELECT @StrSql = @StrSql + '((Ex.StartTime>=  ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@EndTime)+''' )
		OR (Ex.StartTime< ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@EndTime)+''')
		OR(Ex.StartTime>= ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@EndTime)+''' AND Ex.StartTime< ''' + convert(nvarchar(20),@EndTime)+''')
		OR(Ex.StartTime< ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@EndTime)+''' ))'
SELECT @StrSql = @StrSql + @StrxMachine
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
			Inner Join EmployeeInformation   ON autodata.Opr=EmployeeInformation.InterfaceID
			Inner Join MachineInformation   ON autodata.MC=MachineInformation.InterfaceID
			Inner Join ComponentInformation  ON autodata.Comp = ComponentInformation.InterfaceID
			Inner Join ComponentOperationPricing on autodata.Opn=ComponentOperationPricing.InterfaceID And ComponentInformation.ComponentID=ComponentOperationPricing.ComponentID '
			---mod 2
				Select @StrSql = @StrSql +' and ComponentOperationPricing.machineid=machineinformation.machineid'
			---mod 2
			Select @StrSql = @StrSql +' Inner Join (
				Select MachineID,ComponentID,OperationNo,StartTime,EndTime From #Exceptions
			)AS Tt1 ON Tt1.MachineID=MachineInformation.MachineID AND Tt1.ComponentID = ComponentInformation.ComponentID AND Tt1.OperationNo= ComponentOperationPricing.OperationNo and Tt1.MachineID=ComponentOperationPricing.MachineID
			Where (autodata.ndtime>Tt1.StartTime) AND (autodata.ndtime<=Tt1.EndTime) and (autodata.datatype=1) '
	Select @StrSql = @StrSql+ @StrMachine + @stroperator
	---mod 3
	Select @StrSql = @StrSql +@param1
	--mod 3
	Select @StrSql = @StrSql+' Group by MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,Tt1.StartTime,Tt1.EndTime,comp,opn
		) as T1
	   	Inner join componentinformation C on T1.Comp=C.interfaceid
	   	Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid  and T1.MachineID=O.MachineId '
	---mod 2
	Select @StrSql = @StrSql +' Inner join machineinformation M on T1.machineid = M.machineid '
	---mod 2
	Select @StrSql = @StrSql +' GROUP BY T1.MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime,t1.EndTime
	)AS T2
	WHERE  #Exceptions.StartTime=T2.StartTime AND #Exceptions.EndTime=T2.EndTime
	AND #Exceptions.MachineID=T2.MachineID AND #Exceptions.ComponentID = T2.ComponentID AND #Exceptions.OperationNo=T2.OperationNo'
	Exec(@StrSql)

	
	UPDATE #Exceptions SET ExCount=ExCount-((ExCount * ActualCount)/ISNULL(IdealCount,0))
END


SELECT @strsql=''
select @strsql ='INSERT INTO #TmpOperator'
select @strsql = @strsql +'(OperatorID ,ComponentID,MachineID ,OperationNo ,'
select @strsql = @strsql +'IdealCycleTime ,IdealLoadUnload ,MaxCycleTime ,MinCycleTime ,AveCycleTime ,'
select @strsql = @strsql +'MaxLoadUnload ,MinLoadUnload ,AveLoadUnload ,OperationCount  )'
select @strsql = @strsql + 'SELECT employeeinformation.employeeid as OperatorID, '
select @strsql = @strsql + ' componentinformation.componentid as ComponentID, '
select @strsql=  @strsql+'   machineinformation.machineid as MachineID,'
select @strsql = @strsql + ' componentoperationpricing.operationno AS OperationNo, '
select @strsql = @strsql + ' dbo.f_FormatTime(componentoperationpricing.machiningtime ,''' + @TimeFormat + ''') AS IdealCycleTime, '
select @strsql = @strsql + ' dbo.f_FormatTime((componentoperationpricing.cycletime - componentoperationpricing.machiningtime),''' + @TimeFormat + ''') AS IdealLoadUnload, '
select @strsql = @strsql + ' dbo.f_FormatTime(MAX(autodata.cycletime/autodata.partscount)* ISNULL(componentoperationpricing.SubOperations,1),''' + @TimeFormat + ''') AS MaxCycleTime,'
select @strsql = @strsql + ' dbo.f_FormatTime(MIN(autodata.cycletime/autodata.partscount)* ISNULL(componentoperationpricing.SubOperations,1),''' + @TimeFormat + ''') AS MinCycleTime,'
select @strsql = @strsql + ' dbo.f_FormatTime(AVG(autodata.cycletime/autodata.partscount) * ISNULL(componentoperationpricing.SubOperations,1),''' + @TimeFormat + ''') AS AveCycleTime,'
select @strsql = @strsql + ' dbo.f_FormatTime(MAX(autodata.loadunload/autodata.partscount)* ISNULL(componentoperationpricing.SubOperations,1),''' + @TimeFormat + ''') AS MaxLoadUnload,'
select @strsql = @strsql + ' dbo.f_FormatTime(MIN(autodata.loadunload/autodata.partscount)* ISNULL(componentoperationpricing.SubOperations,1),''' + @TimeFormat + ''') AS MinLoadUnload, '
select @strsql = @strsql + ' dbo.f_FormatTime(AVG(autodata.loadunload/autodata.partscount) * ISNULL(componentoperationpricing.SubOperations,1) ,''' + @TimeFormat + ''') AS AveLoadUnload, '
select @strsql = @strsql + ' CAST(CEILING(CAST(sum(autodata.partscount)as float)/ ISNULL(componentoperationpricing.SubOperations,1))as integer )as OperationCount '
select @strsql = @strsql + ' FROM autodata INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID Left Outer JOIN PlantMachine ON PlantMachine.MachineID=machineinformation.MachineID INNER JOIN '
select @strsql = @strsql + ' employeeinformation ON autodata.opr = employeeinformation.InterfaceID  INNER JOIN '
select @strsql = @strsql + ' componentinformation ON autodata.comp = componentinformation.InterfaceID  INNER JOIN '
select @strsql = @strsql + ' componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID)'
select @strsql = @strsql + ' AND (componentinformation.componentid = componentoperationpricing.componentid) '
---mod 1
Select @StrSql = @StrSql +' and componentoperationpricing.machineid=machineinformation.machineid'
---mod 1
---mod 3: Changed to select 2 types
--select @strsql = @strsql + ' WHERE (autodata.sttime > ''' + convert(nvarchar(20),@StartTime) + ''')'
select @strsql = @strsql + ' WHERE (autodata.ndtime > ''' + convert(nvarchar(20),@StartTime) + ''')'
---mod 3
select @strsql = @strsql + ' AND (autodata.ndtime <= ''' + convert(nvarchar(20),@EndTime) + ''')'
select @strsql = @strsql +  @StrPlantID +  @strMachine + @stroperator
---mod 3
select @strsql = @strsql +  @Param1
--mod 3
select @strsql = @strsql + ' AND (autodata.datatype = 1)'
select @strsql = @strsql + ' GROUP BY employeeinformation.employeeid,componentinformation.componentid,machineinformation.machineid, componentoperationpricing.operationno, '
select @strsql = @strsql + ' componentoperationpricing.cycletime, componentoperationpricing.machiningtime , componentoperationpricing.SubOperations'
exec (@strsql)


UPDATE #TmpOperator SET OperationCount = ISNULL(Tt.OpnCount,0)
FROM
(
SELECT OperatorID,Ti.MachineID,Ti.Componentid,Ti.OperationNo,(OperationCount-(OperationCount*(Ti.Ratio)))AS OpnCount
FROM #TmpOperator Left Outer Join
(
	SELECT #Exceptions.MachineID,#Exceptions.Componentid,#Exceptions.OperationNo,CAST(CAST (SUM(ExCount) AS FLOAT)/CAST(Max(T1.tCount)AS FLOAT )AS FLOAT) AS Ratio
	FROM #Exceptions  Inner Join (
	SELECT MachineID,Componentid,OperationNo,SUM(OperationCount)AS tCount
	FROM #TmpOperator Group By  MachineID,Componentid,OperationNo
	)T1 ON  T1.MachineID=#Exceptions.MachineID AND T1.Componentid=#Exceptions.Componentid AND T1.OperationNo=#Exceptions.OperationNo
		Group By  #Exceptions.MachineID,#Exceptions.Componentid,#Exceptions.OperationNo
	)Ti ON Ti.MachineID=#TmpOperator.MachineID AND Ti.Componentid=#TmpOperator.Componentid AND Ti.OperationNo=#TmpOperator.OperationNo
) AS Tt Inner Join #TmpOperator ON Tt.MachineID=#TmpOperator.MachineID AND Tt.Componentid=#TmpOperator.Componentid AND Tt.OperationNo=#TmpOperator.OperationNo AND Tt.OperatorID=#TmpOperator.OperatorID


SELECT  * FROM 	#TmpOperator
END
