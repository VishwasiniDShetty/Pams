/****** Object:  Procedure [dbo].[s_GetComponentTrend_MonthWise]    Committed by VersionSQL https://www.versionsql.com ******/

/*************************************************************************************************************************
NRO115-Vasavi-06/Jun/2015::To get actualLoadUnload,actualCycleTime at M-C-O level for multiple machines monthwise.
exec [dbo].[s_GetComponentTrend_MonthWise] '2015-01-01 06:00:00 AM','2015-07-01 06:00:00 AM','ACE VTL-01,ACE VTL-02','','1','month'                           
***************************************************************************************************************************/
CREATE PROCEDURE [dbo].[s_GetComponentTrend_MonthWise]
	@StartTime datetime,
	@EndTime datetime,
	@MachineID nvarchar(50)='',
	@ComponentID nvarchar(50) = '',
	@OperationNo nvarchar(50) = '',
	@param nvarchar(50)=''
AS
BEGIN
Declare @strsql nvarchar(4000);
Declare @strmachine nvarchar(255);
Declare @strcomponentid nvarchar(255);
Declare @stroperation nvarchar(255);
Declare @timeformat as nvarchar(2000);
Declare @StrExComponent As Nvarchar(255);
Declare @StrExOpn As Nvarchar(255);
SELECT @strsql = '';
SELECT @strcomponentid = '';
SELECT @stroperation = '';
SELECT @strmachine = '';
SELECT @StrExComponent='';
SELECT @StrExOpn='';

CREATE TABLE #Exceptions
(
	MachineID NVarChar(50),
	ComponentID Nvarchar(50),
	OperationNo Int,
	StartTime DateTime,
	EndTime DateTime,
--	IdealCount Int,  --NR0097
--	ActualCount Int,  --NR0097
	IdealCount float,  --NR0097
	ActualCount float,  --NR0097
--	ExCount Int --NR0097
	Excount Float, --NR0097
	DurStart datetime,
	DurEnd datetime
)
CREATE TABLE #CockpitComponentsData --DR0016::SSK
(
    MStart datetime,
	Mend datetime,
	--mod 6
	MachineID nvarchar(50),
	MachineInterface nvarchar(50),
	--mod 6
	ComponentID  Nvarchar(50),
	
	OperationNo Int,
	--mod 6
	CompInterface nvarchar(50),
	OPNInterface nvarchar(50),
	--mod 6
	CycleTime Nvarchar(25),
	LoadUnload Nvarchar(25),
	AverageLoadUnload Nvarchar(25),
	AverageCycleTime Nvarchar(25),
	OperationCount Float 
	,partsforaverage float, --NR0097
	---mod 2
	PDT int, --ER0295
	
)

Create table #PlannedDownTimes
(
	MachineID nvarchar(50),
	MachineInterface nvarchar(50),
	StartTime DateTime,
	EndTime DateTime,
	DStart datetime,
	Dend datetime
)
Create Table #ShiftTemp
	(
		PDate datetime,
		ShiftName nvarchar(20) null,
		FromTime datetime,
		ToTime Datetime
	)

create table #machines

( Machine nvarchar(50)
)
Declare @Counter as datetime
select @counter=convert(datetime, cast(DATEPART(yyyy,@StartTime)as nvarchar(4))+'-'+cast(datepart(mm,@StartTime)as nvarchar(2))+'-'+cast(datepart(dd,@StartTime)as nvarchar(2)) +' 00:00:00.000')

if @param='Month'
begin
	Delete from #ShiftTemp;
	While(@counter <= @EndTime)
	begin
		insert into #ShiftTemp(Pdate,ShiftName,FromTime,ToTime)
		select @Counter,'ALL',dbo.f_GetLogicalMonth(@Counter,'start'),dbo.f_GetLogicalMonth(@Counter,'end')
		SELECT @counter = Dateadd(Month,1,@counter)
	end
end

SELECT @timeformat ='ss';
SELECT @timeformat = isnull((select valueintext from cockpitdefaults where parameter='timeformat'),'ss')
if (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')
begin
	SELECT @timeformat = 'ss'
end
if isnull(@machineid,'') <> ''
begin

	--SELECT @strmachine = ' and ( machineinformation.MachineID = N''' + @MachineID + ''')'
		insert into #machines(machine)
	exec dbo.Split @machineid, ','


end
if isnull(@componentid,'') <> ''
begin
	
	SELECT @strcomponentid = ' AND ( componentinformation.componentid = N''' + @componentid + ''')'
	SELECT @StrExComponent=' AND Ex.ComponentID = N''' + @componentid + ''' '
	
end
if isnull(@operationno, '') <> ''
begin
	
	SELECT @stroperation = ' AND ( componentoperationpricing.operationno = N''' + @OperationNo +''')'
	SELECT @StrExOpn = ' AND Ex.Operationno = N''' + @OperationNo +''''
	
end

---mod 1 added 120 parameter in convert function
SELECT @StrSql = 'INSERT INTO #Exceptions(MachineID ,ComponentID,OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,ExCount,DurStart,DurEnd )
		SELECT Ex.MachineID ,Ex.ComponentID,Ex.OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,0,S.FromTime,S.ToTime
		From ProductionCountException Ex
		Inner Join MachineInformation M ON Ex.MachineID=M.MachineID
		Inner Join ComponentInformation C ON Ex.ComponentID=C.ComponentID
		Inner Join Componentoperationpricing O ON Ex.OperationNo=O.OperationNo AND C.ComponentID=O.ComponentID '
		---mod 3
		SELECT @StrSql = @StrSql + ' and O.MachineId=Ex.MachineId cross join #ShiftTemp S  '
		---mod 3
		SELECT @StrSql = @StrSql + ' WHERE Ex.MachineID in (select machine from #machines) AND M.MultiSpindleFlag=1 AND
		((Ex.StartTime>=   S.FromTime AND Ex.EndTime<= S.ToTime  )
		OR (Ex.StartTime<  S.FromTime AND Ex.EndTime>S.FromTime  AND Ex.EndTime<=  S.ToTime)
			OR(Ex.StartTime>=S.FromTime AND Ex.EndTime> S.ToTime AND Ex.StartTime< S.ToTime)
		OR(Ex.StartTime< S.FromTime AND Ex.EndTime> S.ToTime ))'
SELECT @StrSql = @StrSql + @StrExComponent + @StrExOpn
Exec (@strsql)
print @StrSql;



insert into #PlannedDownTimes( MachineID,MachineInterface,StartTime,EndTime,Dstart,Dend)
SELECT PDT.machine,Machineinformation.InterfaceID,PDT.StartTime,PDT.EndTime,S.FromTime,S.ToTime FROM PlannedDownTimes PDT inner join
Machineinformation on Machineinformation.MachineID = PDT.Machine cross join #ShiftTemp S
WHERE ((PDT.StartTime >= S.FromTime  AND PDT.EndTime <=S.ToTime  )
OR ( PDT.StartTime < S.FromTime   AND PDT.EndTime <=S.ToTime   AND PDT.EndTime >S.FromTime )
OR ( PDT.StartTime >= S.FromTime    AND PDT.StartTime <S.ToTime   AND PDT.EndTime > S.ToTime  )
OR ( PDT.StartTime < S.FromTime   AND PDT.EndTime >S.ToTime ) ) And PDTstatus = 1 and  PDT.Machine in (select machine from #machines)

UPDATE #PlannedDownTimes SET StartTime=DStart  WHERE (StartTime<DStart AND EndTime>DStart)
UPDATE #PlannedDownTimes SET EndTime=DEnd  WHERE (EndTime>DEnd AND StartTime<DEnd )


	--vasavi added from here
IF (SELECT Count(*) from #Exceptions)<>0
BEGIN
	UPDATE #Exceptions SET StartTime=DurStart WHERE (StartTime<DurStart AND EndTime>DurStart)
	UPDATE #Exceptions SET EndTime=DurEnd WHERE (EndTime>DurEnd AND StartTime<DurEnd )
	Select @StrSql = 'UPDATE #Exceptions SET ExCount=ISNULL(T2.Comp,0) From
	(
		SELECT T1.DurStrart,T1.DurEnd,T1.MachineID AS MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime AS StartTime,T1.EndTime AS EndTime,
		--SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp --NR0097
        SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp --NR0097
		From (
			select T1.DurStart,T1.MacineID, M.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,comp,opn,Tt1.StartTime,Tt1.EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from autodata
			Inner Join MachineInformation M  ON autodata.MC=M.InterfaceID
			Inner Join ComponentInformation  ON autodata.Comp = ComponentInformation.InterfaceID
			Inner Join ComponentOperationPricing on autodata.Opn=ComponentOperationPricing.InterfaceID And ComponentInformation.ComponentID=ComponentOperationPricing.ComponentID '
			SELECT @StrSql = @StrSql +' and componentoperationpricing.machineid= M.machineid '
			
			SELECT @StrSql = @StrSql +' Inner Join (
				Select  DurStart,DurEnd,MachineID,ComponentID,OperationNo,StartTime,EndTime From #Exceptions
			)AS Tt1 ON Tt1.MachineID=M.MachineID AND Tt1.ComponentID = ComponentInformation.ComponentID AND Tt1.OperationNo= ComponentOperationPricing.OperationNo
			Where (autodata.ndtime>Tt1.StartTime) AND (autodata.ndtime<=Tt1.EndTime) and (autodata.datatype=1)
			And M.MachineID in (select machine from #machines) '
	Select @StrSql = @StrSql+ @strcomponentid + @stroperation
	Select @StrSql = @StrSql+' Group by M.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,Tt1.StartTime,Tt1.EndTime,comp,opn,Tt1.DurStart,Tt1.DurEnd
		) as T1
		Inner join componentinformation C on T1.Comp=C.interfaceid
		Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid '
	
		SELECT @StrSql = @StrSql +' inner join machineinformation M on T1.machineid= M.machineid '
	
		SELECT @StrSql = @StrSql +' GROUP BY T1.MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime,t1.EndTime,T1.DurStart,T1.DurEnd
	)AS T2
	WHERE  #Exceptions.StartTime=T2.StartTime AND #Exceptions.EndTime=T2.EndTime
	AND #Exceptions.MachineID=T2.MachineID AND #Exceptions.ComponentID = T2.ComponentID AND #Exceptions.OperationNo=T2.OperationNo
and #Exceptions.DurStart=T2.DurStart and #Exceptions.DurEnd=T2.DurEnd'
	Exec(@StrSql)


	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
	BEGIN
	Select @StrSql =''
	Select @StrSql ='UPDATE #Exceptions SET ExCount=ISNULL(ExCount,0) - ISNULL(T3.Comp,0) From (
		SELECT  T2.Dstart,T2.Dend,T2.MachineID AS MachineID,T2.ComponentID,T2.OperationNo,T2.StartTime AS StartTime,T2.EndTime AS EndTime,
		--SUM(CEILING (CAST(T2.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp From ( --NR0097
		SUM((CAST(T2.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp From ( --NR0097
		select T1.Dstart,T1.Dend,M.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,comp,opn,
		Max(T1.XStartTime)StartTime,Max(T1.XEndTime)EndTime,T1.PLD_StartTime,T1.PLD_EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from autodata
		Inner Join MachineInformation M  ON autodata.MC=M.InterfaceID
		Inner Join ComponentInformation  ON autodata.Comp = ComponentInformation.InterfaceID
		Inner Join ComponentOperationPricing on autodata.Opn=ComponentOperationPricing.InterfaceID And ComponentInformation.ComponentID=ComponentOperationPricing.ComponentID
		Inner Join	
	(
		SELECT Td.MachineID,ComponentID,OperationNo,Tx.StartTime As XStartTime, Tx.EndTime AS XEndTime,
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
		From #Exceptions AS Tx CROSS JOIN #PlannedDownTimes AS Td
		Where ((Td.StartTime>=Tx.StartTime And Td.EndTime <=Tx.EndTime) OR
		(Td.StartTime< Tx.StartTime And Td.EndTime<=Tx.EndTime AND Td.EndTime>Tx.StartTime)OR
		(Td.StartTime>= Tx.StartTime And Td.StartTime <Tx.EndTime AND Td.EndTime>Tx.EndTime)OR
		(Td.StartTime< Tx.StartTime And Td.EndTime>Tx.EndTime))
		)AS T1 ON T1.MachineID=M.MachineID AND T1.ComponentID = ComponentInformation.ComponentID AND T1.OperationNo= ComponentOperationPricing.OperationNo
		Where (autodata.ndtime>T1.PLD_StartTime  AND autodata.ndtime<=T1.PLD_EndTime) and (autodata.datatype=1)
		AND (autodata.ndtime > T1.Dstart AND autodata.ndtime<=T1.Dend )
		And M.MachineID in (select machine from #machines) '
		Select @StrSql = @StrSql+ @strcomponentid + @stroperation
		Select @StrSql = @StrSql+' Group by M.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,T1.PLD_StartTime,T1.PLD_EndTime,comp,opn,T1.Dstart,T1.Dend
		)AS T2
		Inner join componentinformation C on T2.Comp=C.interfaceid
		Inner join ComponentOperationPricing O ON T2.Opn=O.interfaceid and C.Componentid=O.componentid
		GROUP BY T2.MachineID,T2.ComponentID,T2.OperationNo,T2.StartTime,t2.EndTime,T2.Dstart,T2.Dend
		)As T3
		WHERE  #Exceptions.StartTime=T3.StartTime AND #Exceptions.EndTime=T3.EndTime
		AND #Exceptions.MachineID=T3.MachineID AND #Exceptions.ComponentID = T3.ComponentID AND #Exceptions.OperationNo=T3.OperationNo
		and #Exceptions.DurStart=T3.DStart and #Exceptions.DurEnd=T3.DEnd'
	PRINT @StrSql
	EXEC(@StrSql)
	End
	--vasavi added till here
	--mod 5
	UPDATE #Exceptions SET ExCount=ExCount-((ExCount * ActualCount)/ISNULL(IdealCount,0))
End


			SELECT @strsql=''
			select @strsql = 'INSERT INTO #CockpitComponentsData'
			select @strsql = @strsql + ' SELECT S.FromTime,S.ToTime,machineinformation.machineid,
											machineinformation.interfaceid,componentinformation.componentid as ComponentID, '
			select @strsql = @strsql + ' componentoperationpricing.operationno AS OperationNo,componentinformation.Interfaceid,componentoperationpricing.interfaceid, '
			select @strsql = @strsql + ' dbo.f_FormatTime(componentoperationpricing.machiningtime,''' + @timeformat + ''')  AS CycleTime, '
			select @strsql = @strsql + ' dbo.f_FormatTime((componentoperationpricing.cycletime - componentoperationpricing.machiningtime),''' + @timeformat + ''') AS LoadUnload, 0,'
			select @strsql = @strsql + 'sum(autodata.CycleTime) AS AverageCycleTime, '
			select @strsql = @strsql + ' CAST((CAST(Sum(autodata.PartsCount) AS Float)/ISNULL(componentoperationpricing.SubOperations,1))AS float) as OperationCount '
			select @strsql = @strsql + ',  CAST((CAST(Sum(autodata.PartsCount) AS Float)/ISNULL(componentoperationpricing.SubOperations,1))AS float) as partsforaverage' 
			select @strsql = @strsql + ',0'
			select @strsql = @strsql + ' FROM autodata INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN  '
			select @strsql = @strsql + ' componentinformation ON autodata.comp = componentinformation.InterfaceID  INNER JOIN '
			select @strsql = @strsql + ' componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID)'
			select @strsql = @strsql + ' AND (componentinformation.componentid = componentoperationpricing.componentid) '
			---mod 3
			SELECT @StrSql = @StrSql +' and componentoperationpricing.machineid= machineinformation.machineid cross join #shifttemp S'
			---mod 3
			select @strsql = @strsql + ' WHERE (autodata.ndtime> S.Fromtime)'
			select @strsql = @strsql + ' AND (autodata.ndtime <= S.ToTime) and machineinformation.machineid in (select machine from #machines) '
			select @strsql = @strsql + @strcomponentid + @stroperation
			select @strsql = @strsql + ' AND (autodata.datatype = 1)'
			select @strsql = @strsql + ' GROUP BY machineinformation.machineid,
											machineinformation.interfaceid,componentinformation.componentid, componentoperationpricing.operationno, '
			select @strsql = @strsql + ' componentinformation.Interfaceid,componentoperationpricing.interfaceid,componentoperationpricing.cycletime, componentoperationpricing.machiningtime,componentoperationpricing.SubOperations, S.FromTime,S.ToTime'
			--PRINT @StrSql
			exec (@strsql)
	
			select @strsql='UPDATE #CockpitComponentsData SET AverageLoadUnload=ISNULL(T2.AverageLoadUnload,0)'
			select @strsql = @strsql + ' From('
			select @strsql = @strsql + ' SELECT S.fromTime as FromTime,S.ToTime as ToTime, componentinformation.componentid as ComponentID, '
			select @strsql = @strsql + ' componentoperationpricing.operationno AS OperationNo, '
			--mod 2 : get the total loadunload
			---select @strsql = @strsql + ' dbo.f_FormatTime(AVG(autodata.loadunload/ISNULL(autodata.PartsCount,1)) * ISNULL(componentoperationpricing.SubOperations,1),''' + @timeformat + ''') AS AverageLoadUnload '
			select @strsql = @strsql + ' sum(autodata.loadunload) AS AverageLoadUnload '
			--mod 2
			select @strsql = @strsql + ' FROM autodata INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN  '
			select @strsql = @strsql + ' componentinformation ON autodata.comp = componentinformation.InterfaceID  INNER JOIN '
			select @strsql = @strsql + ' componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID)'
			select @strsql = @strsql + ' AND (componentinformation.componentid = componentoperationpricing.componentid) '
			---mod 3
			SELECT @StrSql = @StrSql +' and componentoperationpricing.machineid= machineinformation.machineid cross join #ShiftTemp S'
			---mod 3
			select @strsql = @strsql + ' WHERE (autodata.ndtime >S.fromTime )'
			select @strsql = @strsql + ' AND (autodata.ndtime <= S.ToTime) and machineinformation.machineid in (select machine from #machines) '
			select @strsql = @strsql +    @strcomponentid + @stroperation
			select @strsql = @strsql + ' AND (autodata.datatype = 1) AND autodata.loadunload>=(Select TOP 1 ISNULL(ValueInInt,0) From ShopDefaults Where Parameter=''MinLUForLR'')'
			select @strsql = @strsql + ' GROUP BY componentinformation.componentid, componentoperationpricing.operationno,componentoperationpricing.SubOperations,S.FromTime,S.ToTime '
			select @strsql = @strsql + ' )AS T2 INNER JOIN #CockpitComponentsData ON T2.ComponentID=#CockpitComponentsData.ComponentID AND T2.OperationNo=#CockpitComponentsData.OperationNo and T2.FromTime=#CockpitComponentsData.MStart '
			exec (@strsql)
			print @strsql
	--vasavi till here.
--ER0295 Modified From here.


--If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y' --ER0363 Commented
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_AvgCycletime_4m_PLD')='Y' --ER0363 Added
BEGIN
	UPDATE #CockpitComponentsData set AverageCycleTime =isnull(AverageCycleTime,0) - isNull(TT.PPDT ,0),
	AverageLoadUnload = isnull(AverageLoadUnload,0) - isnull(LD,0),PDT= isnull(PDT,0) + isNull(TT.PPDT ,0) + isnull(LD,0)
	FROM
	(
			Select A.mc,A.comp,A.Opn,Sum
			(CASE
--			WHEN A.sttime >= T.StartTime  AND A.ndtime <=T.EndTime  THEN (A.cycletime) --DR0325 Commented
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
					SELECT C.MStart,C.MEnd,M.Machineid,
					autodata.MC,autodata.comp,autodata.Opn,autodata.sttime,autodata.ndtime,autodata.Cycletime,autodata.msttime
					FROM AutoData inner join Machineinformation M on M.interfaceid=Autodata.mc inner join #CockpitComponentsData C on autodata.MC=C.MachineID and autodata.Comp=C.ComponentID and autodata.Opn=C.operationNo
					where autodata.DataType=1 And autodata.ndtime >C.MStart AND autodata.ndtime <=C.MEnd
				)A
			CROSS jOIN PlannedDownTimes T 
			WHERE T.Machine=A.Machineid AND T.Machine in (select machine from #machines) and  
			((A.msttime >= T.StartTime  AND A.ndtime <=T.EndTime)
			OR ( A.msttime < T.StartTime  AND A.ndtime <= T.EndTime AND A.ndtime > T.StartTime )
			OR ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime AND A.ndtime > T.EndTime )
			OR ( A.msttime < T.StartTime  AND A.ndtime > T.EndTime))
		  group by A.mc,A.comp,A.Opn
	)
	as TT INNER JOIN #CockpitComponentsData ON TT.mc = #CockpitComponentsData.MachineInterface
			and TT.comp = #CockpitComponentsData.CompInterface
			and TT.opn = #CockpitComponentsData.OPNInterface

--ER0295 Modified Till here.
--Handle intearction between ICD and PDT for type 1 production record for the selected time period.

		UPDATE  #CockpitComponentsData set AverageCycleTime =isnull(AverageCycleTime,0) + isNull(T2.IPDT ,0) FROM(
		Select AutoData.mc,autodata.comp,autodata.Opn,
		SUM(
		CASE 	
			When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
			When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
			When ( autodata.sttime >= T.StartTime  AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
			when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		From AutoData INNER Join
			(Select C.MStart,C.MEnd,mc,Sttime,NdTime,M.Machineid From AutoData 
				inner join Machineinformation M on M.interfaceid=Autodata.mc inner join #CockpitComponentsData C on autodata.MC=C.MachineID and autodata.Comp=C.ComponentID and autodata.Opn=C.operationNo
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>Autodata.CycleTime And
				(ndtime >C.MStart) AND (ndtime <=C.MEnd)) as T1
		ON AutoData.mc=T1.mc CROSS jOIN PlannedDownTimes T 
		Where AutoData.DataType=2 And T.Machine=T1.Machineid AND T.Machine in (select machine from #machines)
		And (( autodata.Sttime > T1.Sttime )
		And ( autodata.ndtime <  T1.ndtime )
		)
		AND
		((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
		or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
		or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
		or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )))
--		AND
--		((T.StartTime >= @StartTime  AND T.EndTime <=@EndTime)
--		OR ( T.StartTime < @StartTime  AND T.EndTime <= @EndTime AND T.EndTime > @StartTime )
--		OR ( T.StartTime >= @StartTime   AND T.StartTime <@EndTime AND T.EndTime >@EndTime )
--		OR ( T.StartTime < @StartTime  AND T.EndTime > @EndTime))	
		GROUP BY AUTODATA.mc,autodata.comp,autodata.Opn
		)AS T2  INNER JOIN #CockpitComponentsData ON T2.mc = #CockpitComponentsData.MachineInterface
				and T2.comp = #CockpitComponentsData.CompInterface
			and T2.opn = #CockpitComponentsData.OPNInterface

End
------------------------------------DR0325 Modified Till Here -----------------------------------------

--Apply Exception on Count..
UPDATE #CockpitComponentsData SET OperationCount = ISNULL(OperationCount,0) - ISNULL(t2.comp,0)
from
( select ComponentID,OperationNo,SUM(ExCount) as comp
	From #Exceptions GROUP BY ComponentID,OperationNo) as T2
Inner join #CockpitComponentsData on T2.ComponentID = #CockpitComponentsData.ComponentID
and T2.OperationNo = #CockpitComponentsData.OperationNo


If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	UPDATE #CockpitComponentsData SET OperationCount = ISNULL(OperationCount,0) - ISNULL(T2.comp,0),
									partsforaverage = ISNULL(partsforaverage,0) - ISNULL(T2.comp,0)
	from
	(
 select C.ComponentID As ComponentID,O.OperationNo As OperationNo,
--SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp --NR0097
SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp --NR0097
	 	From (
				select comp,opn,Sum(PartsCount)AS OrginalCount,MachineInterface from autodata
				CROSS jOIN #PlannedDownTimes T   WHERE autodata.DataType=1 And T.MachineInterface = autodata.mc
					AND(autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)
					--AND(autodata.ndtime > @StartTime  AND autodata.ndtime <=@EndTime)
				Group by comp,opn,MachineInterface
			) as T1
	   inner join Machineinformation M on M.interfaceid=T1.MachineInterface  ----DR0275
	   Inner join componentinformation C on T1.Comp=C.interfaceid
	   Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid
	   and O.Machineid=M.Machineid	----DR0275
	  Group By C.ComponentID,O.OperationNo
	) as T2 inner join #CockpitComponentsData on #CockpitComponentsData.ComponentID=T2.ComponentID AND #CockpitComponentsData.OperationNo=T2.OperationNo
END
--mod 5
--mod 2

		update #CockpitComponentsData set AverageLoadUnload=AverageLoadUnload/partsforaverage,
		AverageCycleTime=AverageCycleTime/partsforaverage where partsforaverage>0
--mod 2
	SELECT  MStart as MonthStart,MEnd as MonthEnd,MachineID,
		ComponentID  ,OperationNo ,CycleTime ,LoadUnload ,
		---mod 2
		---AverageLoadUnload,AverageCycleTime,
		dbo.f_FormatTime(AverageLoadUnload,@timeformat) as AverageLoadUnload,dbo.f_FormatTime(AverageCycleTime,@timeformat) as AverageCycleTime,
		---mod 2
		--OperationCount	FROM #CockpitComponentsData  --DR0016::SSK --NR0097
		round(OperationCount,2) as OperationCount  FROM #CockpitComponentsData 
		order by MStart, MachineID desc--DR0016::SSK --NR0097
	

	
END
