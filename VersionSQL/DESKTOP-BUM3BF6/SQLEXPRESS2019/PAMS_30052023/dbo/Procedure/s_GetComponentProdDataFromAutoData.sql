/****** Object:  Procedure [dbo].[s_GetComponentProdDataFromAutoData]    Committed by VersionSQL https://www.versionsql.com ******/

/**********************************************************************
Author :: Sangeeta Kallur On 30th Sep 2005
To Get ComponentProduction Details From AutoData
Machine, DownReason,  change in length of @component from 20 to 50 17-feb-2006
Changed By Sangeeta Kallur on 06-July-2006
CompCount was not validating with Datatype
to count component against suboperations--changed To Support SubOperations at CO Level{AutoAxel Request}.
Changed by Mrudula to include pallette count
Procedure Changed By Sangeeta Kallur on 23-FEB-2007
	::For MultiSpindle type of machines [MAINI Req].
Note :- (ER0181) Assuming the suboperation will remain same for a particular CO machine qualification is not done.
mod 1 :- ER0182 By Kusuma M.H on 16-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
mod 2 :- ER0210 By KarthikG Introduce PDT on 5150. Handle PDT at Machine Level.
DR0250 - KarthikR - 24/Aug/2010 :: To handle error Invalid Column Name machineinterface
					 Temp table #PlannedDownTimes has been changed into #PlannedDownTimes_GetComponent
DR0277 -SwathiKS - 28/Apr/2011 :: To Update Target When @ComparisonParam = 'ProdCount' and @TimeAxis='Day'.
				  SM -> Standard -> Comparision Reports
***********************************************************************/
--s_GetComponentProdDataFromAutoData '2011-Apr-12','2011-Apr-13','','','',''
CREATE      PROCEDURE [dbo].[s_GetComponentProdDataFromAutoData]
		@StartTime as Datetime,			
		@EndTime as datetime,
		@Machine as nvarchar(50) = '',
		@Component as nvarchar(50)='',
		@Operation as nvarchar(20)='',
		@PlantID as nvarchar(50)='',
		@Param as nvarchar(20) = 'ALL' --DR0277
AS
BEGIN
declare @strsql nvarchar(4000)
declare @strmachine nvarchar(255)
declare @stroperation nvarchar(255)
declare @strcomponent nvarchar(255)
Declare @strPlantID as nvarchar(50)
Declare @strXmachine nvarchar(255)
Declare @strXoperation nvarchar(255)
Declare @strXcomponent nvarchar(255)
Create Table #ProdData
	(
	MachineID Nvarchar(50),
	ComponentID Nvarchar(50),
	OperationID Nvarchar(50),
	CmpCount Int
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
	ExCount Int
)
select @strsql = ''
select @strmachine = ''
select @strcomponent = ''
select @stroperation = ''
select @strPlantID = ''
select @strXmachine = ''
select @strXcomponent = ''
select @strXoperation = ''
if isnull(@Machine,'') <> ''
begin
	---mod 1
--	select @strmachine = ' AND ( M.machineid = ''' + @Machine+ ''')'
--	select @strXmachine = ' AND ( Ex.Machineid = ''' + @Machine+ ''')'
	select @strmachine = ' AND ( M.machineid = N''' + @Machine+ ''')'
	select @strXmachine = ' AND ( Ex.Machineid = N''' + @Machine+ ''')'
	---mod 1
end
if isnull(@Component, '') <> ''
begin
	---mod 1
--	select @strcomponent = ' AND ( C.componentid = ''' + @Component+ ''')'
--	select @strXcomponent = ' AND ( Ex.Componentid = ''' + @Component+ ''')'
	select @strcomponent = ' AND ( C.componentid = N''' + @Component+ ''')'
	select @strXcomponent = ' AND ( Ex.Componentid = N''' + @Component+ ''')'
	---mod 1
end
if isnull(@Operation, '') <> ''
begin
	---mod 1
--	select @stroperation = ' AND ( O.Operationno = ''' + @Operation + ''')'
--	select @strXoperation = ' AND ( Ex.Operationno = ''' + @Operation + ''')'
	select @stroperation = ' AND ( O.Operationno = N''' + @Operation + ''')'
	select @strXoperation = ' AND ( Ex.Operationno = N''' + @Operation + ''')'
	---mod 1
end
if isnull(@PlantID,'') <> ''
BEGIN	
	---mod 1
--	SELECT @strPlantID = ' AND ( P.PlantID = ''' + @PlantID+ ''')'
	SELECT @strPlantID = ' AND ( P.PlantID = N''' + @PlantID+ ''')'
	---mod 1
END
--mod 2
Create table #PlannedDownTimes_GetComponent  --DR0250 - KarthikR - 24/Aug/2010 
(
	MachineID nvarchar(50),
	MachineInterface nvarchar(50),
	StartTime DateTime,
	EndTime DateTime
)
SELECT @strsql=''
--DR0250 - KarthikR - 24/Aug/2010 
SELECT @strsql='Insert into #PlannedDownTimes_GetComponent SELECT M.MachineID,M.InterfaceID,StartTime,EndTime 
From PlannedDownTimes inner join machineinformation M on M.MachineID = PlannedDownTimes.machine
Where PDTstatus = 1 And
(( StartTime >= '''+convert(nvarchar(20),@StartTime,120)+''' AND EndTime <= '''+ convert(nvarchar(20),@EndTime,120)+''')
OR ( StartTime <  '''+convert(nvarchar(20),@StartTime,120)+''' AND EndTime <= '''+ convert(nvarchar(20),@EndTime,120)+''' AND EndTime > '''+convert(nvarchar(20),@StartTime,120)+''' )
OR ( StartTime >= '''+convert(nvarchar(20),@StartTime,120)+''' AND StartTime < '''+ convert(nvarchar(20),@EndTime,120)+''' AND EndTime > '''+ convert(nvarchar(20),@EndTime,120)+''' )
OR ( StartTime <  '''+convert(nvarchar(20),@StartTime,120)+''' AND EndTime > '''+ convert(nvarchar(20),@EndTime,120)+''') )
And exists (SELECT ValueInText From CockpitDefaults Where Parameter =''Ignore_Count_4m_PLD'' And ValueInText = ''Y'')'
SELECT @strsql= @strsql + @strmachine
print(@strsql)
exec (@strsql)
--mod 2
SELECT @strsql=''
SELECT @strsql='INSERT INTO #ProdData(MachineID,ComponentID,OperationID,CmpCount)'
select @strsql = @strsql + 'SELECT M.MachineID,C.componentid,O.operationno,CAST(CEILING(CAST(sum(A.partscount)as float)/ ISNULL(o.SubOperations,1))as integer ) from '
select @strsql = @strsql +'autodata A '
select @strsql = @strsql +' INNER JOIN machineinformation M on A.mc=M.interfaceid '
select @strsql = @strsql +' inner join ComponentInformation C on A.comp=C.interfaceid '
select @strsql = @strsql +' inner join ComponentOperationPricing O on A.opn=O.interfaceid and C.componentid=O.componentid And O.MachineID=M.MachineID '
SELECT @strsql = @strsql +' LEFT OUTER Join PlantMachine P on m.machineid = P.machineid '
select @strsql = @strsql +' WHERE A.DataType=1 And A.ndtime>'''+convert(nvarchar(20),@StartTime,120)+'''  and A.Ndtime<='''+ convert(nvarchar(20),@EndTime,120)+''' '
select @strsql = @strsql + @strmachine + @strcomponent + @stroperation + @strPlantID
select @strsql = @strsql + ' GROUP BY M.MachineID,C.componentid,O.operationno,o.SubOperations'
--print @strsql
EXEC (@strsql)
SELECT @StrSql =''
SELECT @StrSql = 'INSERT INTO #Exceptions(MachineID ,ComponentID,OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,ExCount )
		SELECT Ex.MachineID ,Ex.ComponentID,Ex.OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,0
		From ProductionCountException Ex
		Inner Join MachineInformation M ON Ex.MachineID=M.MachineID
		Inner Join ComponentInformation C ON Ex.ComponentID=C.ComponentID
		Inner Join Componentoperationpricing O ON Ex.OperationNo=O.OperationNo AND C.ComponentID=O.ComponentID and O.MachineID=M.MachineID
		WHERE M.MultiSpindleFlag=1 AND
		((Ex.StartTime>=  ''' + convert(nvarchar(20),@StartTime,120)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@EndTime,120)+''' )
		OR (Ex.StartTime< ''' + convert(nvarchar(20),@StartTime,120)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@StartTime,120)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@EndTime,120)+''')
		OR(Ex.StartTime>= ''' + convert(nvarchar(20),@StartTime,120)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@EndTime,120)+''' AND Ex.StartTime< ''' + convert(nvarchar(20),@EndTime,120)+''')
		OR(Ex.StartTime< ''' + convert(nvarchar(20),@StartTime,120)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@EndTime,120)+''' ))'
SELECT @StrSql = @StrSql + @strXmachine + @strXcomponent + @strXoperation
Exec (@strsql)
IF (SELECT Count(*) from #Exceptions)<>0
BEGIN
	UPDATE #Exceptions SET StartTime=@StartTime WHERE (StartTime<@StartTime)AND EndTime>@StartTime
	UPDATE #Exceptions SET EndTime=@EndTime WHERE (EndTime>@EndTime AND StartTime<@EndTime )
	
	Select @StrSql = 'UPDATE #Exceptions SET ExCount=ISNULL(T2.Comp,0) From
	(
		SELECT T1.MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime AS StartTime,T1.EndTime AS EndTime,
		SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp
	 	From (
			select M.MachineID,C.ComponentID,O.OperationNo,mc,comp,opn,Tt1.StartTime,Tt1.EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from autodata
			Inner Join MachineInformation M  ON autodata.MC=M.InterfaceID
			Inner Join ComponentInformation  C ON autodata.Comp = C.InterfaceID
			Inner Join ComponentOperationPricing O on autodata.Opn=O.InterfaceID And C.ComponentID=O.ComponentID and O.MachineID=M.MachineID
			Inner Join (
				Select MachineID,ComponentID,OperationNo,StartTime,EndTime From #Exceptions
			)AS Tt1 ON Tt1.MachineID=M.MachineID AND Tt1.ComponentID = C.ComponentID AND Tt1.OperationNo= O.OperationNo and O.MachineID=Tt1.MachineID
			Where (autodata.ndtime>Tt1.StartTime) AND (autodata.ndtime<=Tt1.EndTime) and (autodata.datatype=1)'
	Select @StrSql = @StrSql + @strmachine + @strcomponent + @stroperation
	Select @StrSql = @StrSql +' Group by M.MachineID,C.ComponentID,O.OperationNo,Tt1.StartTime,Tt1.EndTime,mc,comp,opn
		) as T1
		Inner join machineinformation M on T1.mc=M.interfaceid
	   	Inner join componentinformation C on T1.Comp=C.interfaceid
	   	Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid  and O.MachineID=M.MachineID
	  	GROUP BY T1.MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime,t1.EndTime
	)AS T2
	WHERE  #Exceptions.StartTime=T2.StartTime AND #Exceptions.EndTime=T2.EndTime
	AND #Exceptions.MachineID=T2.MachineID AND #Exceptions.ComponentID = T2.ComponentID AND #Exceptions.OperationNo=T2.OperationNo'
	Exec(@StrSql)
	--mod 2
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
				select M.MachineID,C.ComponentID,O.OperationNo,mc,comp,opn,
				Max(T1.XStartTime)StartTime,Max(T1.XEndTime)EndTime,T1.PLD_StartTime,T1.PLD_EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from autodata
				Inner Join MachineInformation M  ON autodata.MC=M.InterfaceID
				Inner Join ComponentInformation  C ON autodata.Comp = C.InterfaceID
				Inner Join ComponentOperationPricing O on autodata.Opn=O.InterfaceID And C.ComponentID=O.ComponentID and O.MachineID=M.MachineID
				Inner Join	
				(
					SELECT Tx.MachineID,ComponentID,OperationNo,Tx.StartTime As XStartTime, Tx.EndTime AS XEndTime,
					CASE
					WHEN (Td.StartTime< Tx.StartTime And Td.EndTime<=Tx.EndTime AND Td.EndTime>Tx.StartTime) THEN Tx.StartTime
					WHEN  (Td.StartTime< Tx.StartTime And Td.EndTime>Tx.EndTime) THEN Tx.StartTime
					ELSE Td.StartTime
					END AS PLD_StartTime,
					CASE
					WHEN (Td.StartTime>= Tx.StartTime And Td.StartTime <Tx.EndTime AND Td.EndTime>Tx.EndTime) THEN Tx.EndTime
					WHEN  (Td.StartTime< Tx.StartTime And Td.EndTime>Tx.EndTime) THEN Tx.EndTime
					ELSE  Td.EndTime
					END AS PLD_EndTime
					From #Exceptions AS Tx CROSS JOIN #PlannedDownTimes_GetComponent AS Td
					Where Td.MachineID = Tx.MachineID And ((Td.StartTime>=Tx.StartTime And Td.EndTime <=Tx.EndTime)OR
					(Td.StartTime< Tx.StartTime And Td.EndTime<=Tx.EndTime AND Td.EndTime>Tx.StartTime)OR
					(Td.StartTime>= Tx.StartTime And Td.StartTime <Tx.EndTime AND Td.EndTime>Tx.EndTime)OR
					(Td.StartTime< Tx.StartTime And Td.EndTime>Tx.EndTime))
				)AS T1 ON T1.MachineID=M.MachineID AND T1.ComponentID = C.ComponentID AND T1.OperationNo= O.OperationNo
				Where ( autodata.ndtime>T1.PLD_StartTime AND autodata.ndtime<=T1.PLD_EndTime) and (autodata.datatype=1)
				and (autodata.ndtime>''' + Convert(nvarchar(20),@StartTime,120)+''' and  autodata.ndtime<=''' + Convert(nvarchar(20),@EndTime,120)+''') '
			Select @StrSql = @StrSql+@strmachine + @strcomponent + @stroperation
			Select @StrSql = @StrSql+' Group by M.MachineID,C.ComponentID,O.OperationNo,T1.PLD_StartTime,T1.PLD_EndTime,mc,comp,opn
			)AS T2
			Inner join MachineInformation M on T2.mc = M.interfaceid
			Inner join componentinformation C on T2.Comp=C.interfaceid
			Inner join ComponentOperationPricing O ON T2.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineID=M.MachineID
			GROUP BY T2.MachineID,T2.ComponentID,T2.OperationNo,T2.StartTime,t2.EndTime
		)As T3
		WHERE  #Exceptions.StartTime=T3.StartTime AND #Exceptions.EndTime=T3.EndTime
		AND #Exceptions.MachineID=T3.MachineID AND #Exceptions.ComponentID = T3.ComponentID AND #Exceptions.OperationNo=T3.OperationNo'
		PRINT @StrSql
		EXEC(@StrSql)
		--mod 2
	END
	UPDATE #Exceptions SET ExCount=ExCount-((ExCount * ActualCount)/ISNULL(IdealCount,0))
	
	Update #ProdData set CmpCount = isnull(CmpCount,0) - isnull(t1.XCount,0) from (
		Select MachineID, ComponentID, OperationNo, sum(ISNULL(ExCount,0)) as XCount from #Exceptions
		Group by MachineID, ComponentID, OperationNo
	) as t1 inner join #ProdData on #ProdData.MachineID = t1.MachineID
	and #ProdData.ComponentID=t1.ComponentID and #ProdData.OperationID=t1.OperationNo
	
END
--mod 2
--SELECT @StartTime AS StartTime,@EndTime AS EndTime,
--#ProdData.ComponentID,#ProdData.OperationID,(CmpCount-ISNULL(Xt.XCount,0))AS CmpCount
--From #ProdData Left Outer Join (
--	Select ComponentID, OperationNo ,Sum(ISNULL(ExCount,0))As XCount FROM  #Exceptions
--	GROUP BY ComponentID, OperationNo
--)As Xt ON #ProdData.ComponentID=Xt.ComponentID AND #ProdData.OperationID=Xt.OperationNo
--mod 2
--mod 2
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	UPDATE #ProdData SET CmpCount = ISNULL(CmpCount,0) - ISNULL(T2.compCount,0)
	from
	(
		select M.MachineID,C.ComponentID,O.OperationNo,SUM(CEILING(CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as compCount
	 	From (
			select mc,comp,opn,Sum(ISNULL(PartsCount,1))AS OrginalCount from autodata
			CROSS jOIN #PlannedDownTimes_GetComponent T WHERE autodata.DataType=1 And Autodata.mc = T.machineInterface
			AND(autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)
			AND(autodata.ndtime > @StartTime  AND autodata.ndtime <=@EndTime)
			Group by mc,comp,opn
		) as T1
	   Inner join MachineInformation M on T1.mc=M.interfaceid
	   Inner join componentinformation C on T1.Comp=C.interfaceid
	   Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineID = M.MachineID
	   Group By M.MachineID,C.ComponentID,O.OperationNo
	) as T2 inner join #ProdData on #ProdData.MachineID = T2.MachineID
	And #ProdData.ComponentID=T2.ComponentID AND #ProdData.OperationID=T2.OperationNo
END
--mod 2

--SELECT @StartTime AS StartTime,@EndTime AS EndTime,ComponentID,OperationID,CmpCount From #ProdData  --DR0277 Commented

--DR0277 From Here.
If @Param = 'ProdCount'
Begin
SELECT @StartTime AS StartTime,@EndTime AS EndTime,Machineid,ComponentID,OperationID,CmpCount From #ProdData
end


If @Param = 'ALL'
Begin
SELECT @StartTime AS StartTime,@EndTime AS EndTime,ComponentID,OperationID,CmpCount From #ProdData
end
--DR0277 Till Here.

END
