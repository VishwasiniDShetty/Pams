/****** Object:  Procedure [dbo].[s_GetToolUsageAggregateByCO]    Committed by VersionSQL https://www.versionsql.com ******/

/************************************************************************************************
SangeetaKallur on 20th Oct 2005 --To get ToolStatistics at the tool level,sequence insensitive  *
to include suboperation in componets count                                                      *
*
Changed By SSK on 11-July-2006 :- To consider SubOperations at CO Level against Count.          *
Procedure Changed By Sangeeta Kallur on 26-FEB-2007 :
	:For MultiSpindle type of machines [MAINI Req]. {Affecting area - Count}
mod 1 :- ER0181 By Kusuma M.H on 28-May-2009.2) Modify all the procedures accordingly. Qualify machine wherever we are making use of component and opeartion no.
mod 2 :- ER0182 By Kusuma M.H on 28-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
DR0237 - SwathiKS on 24/Jun/2010 :: To handel 13Type Mismatch Error Operation Number has been changed from int to nvarchar(10).
ER0400 - SwathiKS -  27/Dec/2014 :: To handle PDT, ICD for Type1 and ICD-PDT Interaction for Type 1 Records
while Calculating ActualToolUsage and handled Machineid in IdealUsage calculation.
*********************************************************************************************/
--s_GetToolUsageAggregateByCO '2014-11-19 06:16:39.350','2014-11-19 17:17:34.707','','KV','1',''
CREATE     PROCEDURE [dbo].[s_GetToolUsageAggregateByCO]
	@StartTime Datetime,
	@EndTime Datetime,
	@Machine Nvarchar(50)='',
	@Component Nvarchar(50),	
	--@OperationNo integer,  DR0237 - SwathiKS on 24/Jun/2010
	@OperationNo Nvarchar(10),
    @PlantID nvarchar(50)=''
	
AS
BEGIN

DECLARE @timeformat as nvarchar(20)
DECLARE @strPlantID as nvarchar(250)
DECLARE @StrMachine AS NvarChar(250)
DECLARE @strSql as nvarchar(4000)
DECLARE @strXMachine AS NvarChar(250)
DECLARE @ExCount AS INTEGER

SELECT @strPlantID = ''
SELECT @strSql = ''
SELECT @StrMachine=''
SELECT @strXMachine=''

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

--ER0400 Added From here
Create table #T_Autodata
(
	[mc] [nvarchar](50),
	[sttime] [datetime],
	[ndtime] [datetime]
)
--ER0400 Added Till here

CREATE TABLE #TmpActualToolUsage
(
	Machine nvarchar(10),
	Cyclestart datetime, --ER0400 
	Cycleend datetime, --ER0400 
	Starttime datetime,
	Endtime datetime,
	ActualToolUsage integer DEFAULT 0,
	Tool nvarchar(10),
	IDno integer,
	PDT int, --ER0400
	ICD INT, --ER0400
	IPDT INT, --ER0400
	ShowActualToolUsage int --ER0400
)

CREATE TABLE #TmpIdealToolUsage
(
	Machine Nvarchar(50), --ER0400
	ToolNo Nvarchar(5),
	IdealToolUsage Integer DEFAULT 0
)

CREATE TABLE #ActualToolUsage
(
	Machine Nvarchar(50), --ER0400
	ToolNo Nvarchar(5),
	ActToolUsage integer DEFAULT 0,
	PDT int, --ER0400
	ICD INT, --ER0400
	IPDT INT, --ER0400
	ShowActualToolUsage int --ER0400
)

CREATE TABLE #IdealToolUsage
(
	Machine Nvarchar(50), --ER0400
	ToolNo Nvarchar(5),
	IdealToolUsage Integer DEFAULT 0,
	CountCompOpn Integer DEFAULT 0
)

IF ISNULL(@Machine,'')<>''
BEGIN
	---mod 2
--	SELECT @StrMachine=' And M.MachineID=''' + @Machine + ''''
--	SELECT @StrXMachine=' And EX.MachineID=''' + @Machine + ''''
	SELECT @StrMachine=' And M.MachineID = N''' + @Machine + ''''
	SELECT @StrXMachine=' And EX.MachineID = N''' + @Machine + ''''
	---mod 2
END
if isnull(@PlantID,'') <> ''
BEGIN
	---mod 2
--	SELECT @strPlantID = ' AND ( P.PlantID = ''' + @PlantID+ ''')'
	SELECT @strPlantID = ' AND ( P.PlantID = N''' + @PlantID+ ''')'
	---mod 2
END

SELECT @timeformat ='ss'
SELECT @timeformat = isnull((select valueintext from cockpitdefaults where parameter='timeformat'),'ss')
IF (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')
BEGIN
	SELECT @timeformat = 'ss'
END
	
/********************** ER0400 Commented From here

	SELECT @StrSql='INSERT INTO #TmpActualToolUsage (Machine,Starttime ,Endtime, ActualToolUsage,Tool,IDno)
			SELECT machine,starttime,EndTime,0,
			CASE
				WHEN detailnumber>=0 AND detailnumber<=9 THEN ''T0'' + cast (detailnumber as nvarchar)
				WHEN detailnumber>9 THEN ''T'' + cast (detailnumber as nvarchar)
			END,
			ID
			FROM autodatadetails A INNER join machineinformation M ON A.machine=M.interfaceid
			INNER JOIN Componentinformation C ON A.CompInterfaceID=C.InterfaceID
			INNER JOIN ComponentOperationPricing O ON A.OpnInterfaceID=O.InterfaceID AND O.ComponentID=C.ComponentID '
	---mod 1
	SELECT @StrSql= @StrSql + ' and M.machineid = O.machineid '
	---mod 1
	SELECT @StrSql= @StrSql + ' left OUTER Join PlantMachine P on M.machineid = P.machineid
			WHERE recordtype=5 AND A.starttime>='''+ CONVERT(NVarChar,@StartTime)+ ''' AND A.starttime<=''' + CONVERT(NVarChar,@EndTime) + '''
			AND C.ComponentID=''' + @Component +''' AND O.OperationNo= ' + cast(@OperationNo as nvarchar)
	SELECT @StrSql = @StrSql + @StrMachine + @StrPlantID
	SELECT @StrSql = @StrSql + ' ORDER BY ID '
	print @StrSql
	exec (@StrSql)

	UPDATE #TmpActualToolUsage SET ActualToolUsage = datediff(SECOND,Starttime,Endtime)

ER0400 Commented Till here  *****************************/


------------------- ER0400 Added From here -------------------------------------------------
Select @strsql=''
select @strsql ='insert into #T_autodata '
select @strsql = @strsql + 'SELECT mc, Case when sttime<'''+ convert(nvarchar(25),@StartTime,120)+''' then '''+ convert(nvarchar(25),@StartTime,120)+''' else sttime end,'
	select @strsql = @strsql + 'case when ndtime>'''+ convert(nvarchar(25),@EndTime,120)+''' then '''+ convert(nvarchar(25),@EndTime,120)+''' else ndtime end'
select @strsql = @strsql + ' from autodata inner join Machineinformation M on autodata.mc=M.interfaceid 
left OUTER Join PlantMachine P on M.machineid = P.machineid
where Datatype=1 and (( sttime >='''+ convert(nvarchar(25),@StartTime,120)+''' and ndtime <= '''+ convert(nvarchar(25),@EndTime,120)+''' ) OR '
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@StartTime,120)+''' and ndtime >'''+ convert(nvarchar(25),@EndTime,120)+''' )OR '
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@StartTime,120)+''' and ndtime >'''+ convert(nvarchar(25),@StartTime,120)+''' and ndtime<='''+convert(nvarchar(25),@EndTime,120)+''' )OR '
select @strsql = @strsql + '( sttime >='''+convert(nvarchar(25),@StartTime,120)+''' and ndtime >'''+ convert(nvarchar(25),@EndTime,120)+''' and sttime<'''+convert(nvarchar(25),@EndTime,120)+''' ))'
SELECT @StrSql = @StrSql + @StrMachine + @StrPlantID
print @strsql
exec (@strsql)

Select @strsql=''
SELECT @StrSql='INSERT INTO #TmpActualToolUsage (Machine,Cyclestart,CycleEnd,Starttime,Endtime,ActualToolUsage,Tool,IDno,PDT,ICD,IPDT,ShowActualToolUsage)
		SELECT A.machine,T.sttime,T.ndtime,A.starttime,0,0,
		CASE
			WHEN A.detailnumber>=0 AND A.detailnumber<=9 THEN ''T0'' + cast (A.detailnumber as nvarchar)
			WHEN A.detailnumber>9 THEN ''T'' + cast (A.detailnumber as nvarchar)
		END,
		ID,0,0,0,0
		FROM autodatadetails A '
SELECT @StrSql= @StrSql + ' INNER JOIN #T_autodata T on A.machine=T.mc'		
SELECT @StrSql= @StrSql + ' INNER join machineinformation M ON A.machine=M.interfaceid'
SELECT @StrSql= @StrSql + ' left OUTER Join PlantMachine P on M.machineid = P.machineid'
SELECT @StrSql= @StrSql + ' WHERE recordtype=5 AND A.starttime>=T.sttime AND A.starttime<=T.ndtime'
SELECT @StrSql = @StrSql + @StrMachine + @StrPlantID
SELECT @StrSql = @StrSql + ' ORDER BY ID '
print @StrSql
exec (@StrSql)

DECLARE @curstarttime as datetime,@CurCyclestart as datetime
DECLARE @curendtime as datetime,@CurCycleend as datetime
DECLARE @nxtstarttime as datetime,@nxtCyclestart as datetime
DECLARE @nxtendtime as datetime,@nxtCycleend as datetime
DECLARE @curtmp as datetime
DECLARE	@curmachine as nvarchar(50),@nxtmachine as nvarchar(50)

DECLARE Rptcursor  cursor for
select Machine,starttime,endtime,cyclestart,Cycleend from #TmpActualToolUsage Order by Machine,starttime
open Rptcursor
fetch next from Rptcursor into @curmachine,@curstarttime,@curendtime,@CurCyclestart,@CurCycleend

IF (@@fetch_status = 0)
BEGIN

	fetch next  from Rptcursor into @nxtmachine,@nxtstarttime,@nxtendtime,@nxtCyclestart,@nxtCycleend

	while (@@fetch_status = 0)
	BEGIN
	
		set @curendtime = @nxtstarttime
		
		If @curmachine=@nxtmachine
		Begin
			update #TmpActualToolUsage set endtime = @curendtime where machine=@curmachine and starttime=@curstarttime
		End
		If @curmachine<>@nxtmachine
		Begin
			UPDATE #TmpActualToolUsage set endtime=@CurCycleend where machine=@curmachine and starttime=@curstarttime
		End

		SET @curstarttime=@nxtstarttime
		set @curmachine=@nxtmachine	
		set @CurCycleend = @nxtCycleend
		FETCH NEXT  from Rptcursor into @nxtmachine,@nxtstarttime,@nxtendtime,@nxtCyclestart,@nxtCycleend
	END

	UPDATE #TmpActualToolUsage set endtime=@CurCycleend where machine=@curmachine and starttime=@curstarttime
	UPDATE #TmpActualToolUsage SET ActualToolUsage = datediff(SECOND,Starttime,Endtime)	
END
		
close Rptcursor
deallocate Rptcursor

update #TmpActualToolUsage set ShowActualToolUsage=isnull(ShowActualToolUsage,0) + isnull(ActualToolUsage,0) --ER0400

/* Fetching Down Records from Tool Cycles */
/* If Down Records of TYPE-1*/
Update #TmpActualToolUsage set ActualToolUsage = isnull(ActualToolUsage,0) - isnull(t2.down,0),ICD=isnull(ICD,0) + isnull(t2.down,0) from 
(Select AutoData.mc ,
SUM(datediff(s , autodata.sttime,autodata.ndtime)) as Down,T.starttime,T.endtime
From AutoData inner join #TmpActualToolUsage T on Autodata.mc=T.machine
Where AutoData.DataType=2
And ( autodata.Sttime > T.Cyclestart)
And ( autodata.ndtime < T.Cycleend)
AND ( autodata.sttime >= T.starttime)
AND ( autodata.ndtime <= T.endtime)
group by AutoData.mc,T.starttime,T.endtime)T2 inner join #TmpActualToolUsage on T2.mc=#TmpActualToolUsage.machine and T2.starttime=#TmpActualToolUsage.starttime and T2.endtime=#TmpActualToolUsage.endtime	

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
BEGIN

	--mod 4:Get ToolUsage time over lapping with PDT.
	Update #TmpActualToolUsage set ActualToolUsage = isnull(ActualToolUsage,0) - isNull(T2.PPDT ,0),PDT= isnull(PDT,0) + isNull(T2.PPDT ,0)
	FROM(
		SELECT T.Machine,T.Starttime,T.Endtime,SUM(CASE
				When T.Starttime >= P.starttime AND T.Endtime <= P.endtime Then datediff(s , T.Starttime,T.Endtime)
				When T.Starttime < P.starttime AND T.Endtime > P.starttime AND T.Endtime<=P.endtime Then datediff(s, P.starttime,T.Endtime )
				When T.Starttime>=P.starttime And T.Starttime < P.endtime AND T.Endtime > P.endtime Then datediff(s,T.Starttime, P.endtime )
				When T.Starttime<P.starttime AND T.Endtime>P.endtime   Then datediff(s , P.starttime,P.endtime)
		END) as PPDT from #TmpActualToolUsage T
		inner join Machineinformation M on T.Machine=M.interfaceid
		inner jOIN PlannedDownTimes P on P.Machine=M.machineid
		WHERE 
			(
			(T.Starttime >= P.starttime  AND T.Endtime <=P.endtime)
			OR ( T.Starttime < P.starttime  AND T.Endtime <= P.endtime AND T.Endtime > P.starttime )
			OR ( T.Starttime >= P.starttime   AND T.Starttime <P.endtime AND T.Endtime > P.endtime )
			OR ( T.Starttime < P.starttime  AND T.Endtime > P.endtime) )
			AND
			(
			(P.Starttime >= T.Cyclestart  AND P.Endtime <=T.Cycleend)
			OR ( P.Starttime < T.Cyclestart  AND P.Endtime <= T.Cycleend AND P.Endtime > T.Cyclestart )
			OR ( P.Starttime >= T.Cyclestart   AND P.Starttime <T.Cycleend AND P.Endtime > T.Cycleend )
			OR ( P.Starttime < T.Cyclestart  AND P.Endtime > T.Cycleend) )
		group by T.Machine,T.Starttime,T.Endtime
	)AS T2 inner join #TmpActualToolUsage on T2.Machine=#TmpActualToolUsage.machine and T2.starttime=#TmpActualToolUsage.starttime and T2.endtime=#TmpActualToolUsage.endtime	

	--Handle intearction between ICD and PDT for type 1 Tool record for the selected time period.
	Update #TmpActualToolUsage set ActualToolUsage = isnull(ActualToolUsage,0) + isNull(T2.ICDPDT ,0), IPDT = isnull(IPDT,0) + isNull(T2.ICDPDT ,0) from
	(
	Select T1.mc,T1.starttime,T1.Endtime ,SUM(
		CASE 	
			When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1
			When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2
			When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3
			when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as ICDPDT from
	 (
		 Select M.Machineid,A.mc,A.sttime, A.ndtime,T.starttime,T.Endtime from autodata A 
		 inner join #TmpActualToolUsage T on A.mc=T.machine
		 inner join Machineinformation M on T.machine=M.interfaceid
		 Where A.DataType=2 and (A.sttime >= T.starttime AND A.ndtime <= T.Endtime) 
		 and (T.Cyclestart < A.sttime) AND (T.Cycleend > A.ndtime) 
	 )as T1 inner join
	(
		select  T.starttime as ToolStart,T.Endtime as ToolEnd,P.machine,Case when P.starttime<T.starttime then T.starttime else P.starttime end as starttime, 
		case when P.endtime> T.Endtime then T.Endtime else P.endtime end as endtime from dbo.PlannedDownTimes P
		inner join Machineinformation M on P.machine=M.machineid
		inner join #TmpActualToolUsage T on M.interfaceid=T.machine
		where 
		((( P.StartTime >=T.Cyclestart) And ( P.EndTime <=T.Cycleend))
		or (P.StartTime < T.Cyclestart  and  P.EndTime <= T.Cycleend AND P.EndTime > T.Cyclestart)
		or (P.StartTime >= T.Cyclestart  AND P.StartTime <T.Cycleend AND P.EndTime > T.Cycleend)
		or (( P.StartTime <T.Cyclestart) And ( P.EndTime >T.Cycleend )))
		AND (
		(T.Starttime >= P.starttime  AND T.Endtime <=P.endtime)
		OR ( T.Starttime < P.starttime  AND T.Endtime <= P.endtime AND T.Endtime > P.starttime )
		OR ( T.Starttime >= P.starttime   AND T.Starttime <P.endtime AND T.Endtime > P.endtime )
		OR ( T.Starttime < P.starttime  AND T.Endtime > P.endtime) )
	)T 
	on T1.machineid=T.machine AND T1.Starttime=T.ToolStart and T1.endtime=T.ToolEnd and
	((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
	or (T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
	or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
	or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )group by T1.mc,T1.starttime,T1.Endtime
	)AS T2 inner join #TmpActualToolUsage on T2.mc=#TmpActualToolUsage.machine and T2.starttime=#TmpActualToolUsage.starttime and T2.endtime=#TmpActualToolUsage.endtime	


END
------------------- ER0400 Added Till here -------------------------------------------------


/* -- ER0400
	INSERT INTO #TmpIdealToolUsage(ToolNo,IdealToolUsage)
	SELECT ToolNo,IdealUsage
	FROM TOOLSEQUENCE
	WHERE ComponentID=@Component AND OperationNO=@OperationNo

	INSERT INTO #ActualToolUsage(ToolNo,ActToolUsage)
	SELECT Tool,sum(ActualToolUsage)
	FROM #TmpActualToolUsage Group by Tool

	INSERT INTO #IdealToolUsage(ToolNo,IdealToolUsage)
	SELECT ToolNo,sum(IdealToolUsage)
	FROM #TmpIdealToolUsage Group By ToolNo
-- ER0400 */

-- ER0400 From here
select @strsql=''
select @strsql=@strsql + 'INSERT INTO #TmpIdealToolUsage(Machine,ToolNo,IdealToolUsage)
SELECT M.interfaceid,ToolNo,IdealUsage FROM TOOLSEQUENCE
Inner Join MachineInformation M  ON TOOLSEQUENCE.Machineid=M.Machineid
left OUTER Join PlantMachine P on M.machineid = P.machineid'
select @strsql=@strsql + ' WHERE ComponentID= '''+ @Component+ ''' AND OperationNO= '''+ @OperationNo + ''''
SELECT @StrSql = @StrSql + @StrMachine + @StrPlantID
print @StrSql
exec (@StrSql)


INSERT INTO #ActualToolUsage(Machine,ToolNo,ActToolUsage,PDT,ICD,IPDT,ShowActualToolUsage)
SELECT Machine,Tool,sum(ActualToolUsage),sum(PDT),SUM(ICD),SUM(IPDT),SUM(ShowActualToolUsage)
FROM #TmpActualToolUsage Group by Tool,Machine

INSERT INTO #IdealToolUsage(Machine,ToolNo,IdealToolUsage)
SELECT Machine,ToolNo,sum(IdealToolUsage)
FROM #TmpIdealToolUsage Group By ToolNo,Machine
-- ER0400 Till Here


set @strSql = ''	
SELECT @StrSql = 'INSERT INTO #Exceptions(MachineID ,ComponentID,OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,ExCount )
		SELECT Ex.MachineID ,Ex.ComponentID,Ex.OperationNo,StartTime,EndTime ,IdealCount ,ActualCount ,0
		From ProductionCountException Ex
		Inner Join MachineInformation M ON Ex.MachineID=M.MachineID
		Inner Join ComponentInformation C ON Ex.ComponentID=C.ComponentID
		Inner Join Componentoperationpricing O ON Ex.OperationNo=O.OperationNo AND C.ComponentID=O.ComponentID '
---mod 1
SELECT @StrSql =@StrSql + ' and M.machineid = O.machineid '
---mod 1
SELECT @StrSql =@StrSql + ' WHERE Ex.ComponentID= '''+@Component+''' AND M.MultiSpindleFlag=1 AND Ex.OperationNo= '''+cast(@OperationNo as nvarchar)+''' AND
		((Ex.StartTime >= ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@EndTime)+''' )
		OR (Ex.StartTime< ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@EndTime)+''')
		OR(Ex.StartTime>= ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@EndTime)+''' AND Ex.StartTime< ''' + convert(nvarchar(20),@EndTime)+''')
		OR(Ex.StartTime< ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@EndTime)+''' ))'
SELECT @StrSql = @StrSql + @strXMachine
Exec (@strsql)
		
IF (SELECT Count(*) from #Exceptions) <> 0
BEGIN
	UPDATE #Exceptions SET StartTime=@StartTime WHERE (StartTime<@StartTime)AND EndTime>@StartTime
	UPDATE #Exceptions SET EndTime=@EndTime WHERE (EndTime>@EndTime AND StartTime<@EndTime )

	set @strSql = ''
	Select @StrSql = 'UPDATE #Exceptions SET ExCount=ISNULL(T2.Comp,0) From
	(
		SELECT T1.MachineID AS MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime AS StartTime,T1.EndTime AS EndTime,
		SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp
	 	From (
			select M.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,comp,opn,Tt1.StartTime,Tt1.EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from autodata
			Inner Join MachineInformation M  ON autodata.MC=M.InterfaceID
			Inner Join ComponentInformation  ON autodata.Comp = ComponentInformation.InterfaceID
			Inner Join ComponentOperationPricing on autodata.Opn=ComponentOperationPricing.InterfaceID And ComponentInformation.ComponentID=ComponentOperationPricing.ComponentID '
	---mod 1
	Select @StrSql = @StrSql + ' and M.machineid = ComponentOperationPricing.machineid '
	---mod 1
	Select @StrSql = @StrSql + ' Inner Join (
				Select MachineID,ComponentID,OperationNo,StartTime,EndTime From #Exceptions
				)AS Tt1 ON Tt1.MachineID=M.MachineID AND Tt1.ComponentID = ComponentInformation.ComponentID AND Tt1.OperationNo= ComponentOperationPricing.OperationNo
			Where (autodata.sttime>=Tt1.StartTime) AND (autodata.ndtime<=Tt1.EndTime) and (autodata.datatype=1) '
	Select @StrSql = @StrSql+ @strmachine
	Select @StrSql = @StrSql+' Group by M.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,Tt1.StartTime,Tt1.EndTime,comp,opn
		) as T1
	   	Inner join componentinformation C on T1.Comp=C.interfaceid
	   	Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid  '
	---mod 1
	Select @StrSql = @StrSql+' Inner join machineinformation M on T1.machineid = M.machineid '
	---mod 1
	Select @StrSql = @StrSql+' GROUP BY T1.MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime,t1.EndTime
	)AS T2
	WHERE  #Exceptions.StartTime=T2.StartTime AND #Exceptions.EndTime=T2.EndTime
	AND #Exceptions.MachineID=T2.MachineID AND #Exceptions.ComponentID = T2.ComponentID AND #Exceptions.OperationNo=T2.OperationNo'
	Exec(@StrSql)
	UPDATE #Exceptions SET ExCount=ExCount-((ExCount * ActualCount)/ISNULL(IdealCount,0))
	
END


set @strSql = ''
set @strSql = '
	UPDATE #IdealToolUsage
	SET CountCompOpn=#T.COCount
	FROM
	(	
		SELECT M.interfaceid, --ER0400 Added Machine
		CAST(CEILING(CAST(Sum(A.PartsCount)AS Float)/ISNULL(O.SubOperations,1))AS INTEGER) As COCount
		FROM AUTODATA A INNER join machineinformation M ON A.mc=M.interfaceid
		INNER JOIN Componentinformation C ON A.Comp=C.InterfaceID
		INNER JOIN ComponentOperationPricing O ON A.Opn=O.InterfaceID AND O.ComponentID=C.ComponentID '
---mod 1
set @strSql = @strSql + ' and M.machineid = O.machineid '
---mod 1
set @strSql = @strSql + ' left OUTER Join PlantMachine P on M.machineid = P.machineid
		WHERE DataType=1 AND a.sttime>='''+ CONVERT(NVarChar,@StartTime)+ ''' AND a.sttime<=''' + CONVERT(NVarChar,@EndTime) + '''
		AND C.ComponentID=''' + @Component +''' AND O.OperationNo= ' + cast(@OperationNo as nvarchar)
set @strSql = @strSql +  @strMachine + @strPlantID
set @strSql = @strSql +  ' Group By O.SubOperations,M.interfaceid --ER0400 Added Machine
		) as #T inner join #IdealToolUsage on #IdealToolUsage.Machine=#T.interfaceid' ---ER0400 added Machine join
print (@strSql)
EXEC(@strSql)

SELECT @ExCount =  SUM(ExCount) From #Exceptions
UPDATE #IdealToolUsage SET CountCompOpn = ISNULL(CountCompOpn,0)-ISNULL(@ExCount,0)

IF ISNULL(@Machine,'')<> ''
BEGIN
	SET @Machine=@Machine
END
ELSE
BEGIN
	SET @Machine='ALL'
END

/* ER0400
SELECT A.ToolNo,
ActToolUsage,
IdealToolUsage ,
dbo.f_FormatTime(ActToolUsage,@timeformat) AS frmtActToolUsage,
dbo.f_FormatTime(IdealToolUsage,@timeformat) AS frmtIdealToolUsage,
CountCompOpn,
@Machine AS Machineid
FROM  #ActualToolUsage A LEFT OUTER JOIN #IdealToolUsage I  ON  A.ToolNo=I.ToolNo
ER0400 */

--ER0400 From here
SELECT A.ToolNo,
ActToolUsage,
IdealToolUsage ,
dbo.f_FormatTime(ShowActualToolUsage,@timeformat) AS frmtActToolUsage,
dbo.f_FormatTime(IdealToolUsage,@timeformat) AS frmtIdealToolUsage,
CountCompOpn,
--A.Machine AS Machineid,
M.Machineid as Machineid,
dbo.f_FormatTime(PDT,@timeformat) as PDT,
dbo.f_FormatTime(ICD,@timeformat) as ICD,
dbo.f_FormatTime(IPDT,@timeformat) as IPDT,
dbo.f_FormatTime((ShowActualToolUsage-ICD),@timeformat) as  NetUsagewithPDT, 
dbo.f_FormatTime(((ShowActualToolUsage-ICD-PDT)+IPDT),@timeformat) as NetUsagewithoutPDT 
FROM  #ActualToolUsage A 
inner join Machineinformation M on M.interfaceid=A.machine
LEFT OUTER JOIN #IdealToolUsage I  ON  A.ToolNo=I.ToolNo and A.Machine=I.Machine
--ER0400 Till here

END
