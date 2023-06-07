/****** Object:  Procedure [dbo].[s_WeeklyOperatorProductionReport]    Committed by VersionSQL https://www.versionsql.com ******/

/**************************************************************************************************
1.Procedure altered by Sangeeta Kallur on 16-Feb-2006
	to include Threshold (Down) in BatchML Calculations
2.Changed By SSK on 10-July-2006 :-To Support SubOperations at CO Level{AutoAxel Request}.
	 Count ,Actual Avg(Cycle Time , LoadUnload Time)Caln.
3.Procedure Altered By SSK on 07-Oct-2006 to include Plant Concept
4.Procedure Altered By SSK on 06-Dec-2006 :
		To Remove Constraint Name & add it as Primary Key
5.Procedure Changed By Sangeeta Kallur on 01-MAR-2007:
		:To Change the production count for MultiSpindle Type of machines. [MAINI Req]
6.Procedure Changed By Sangeeta Kallur on 06-MAR-2007 : To Make it TYPE 2,3 and 4
7.procedure altered by SHM  to use distinct keyword:DR0108
8.DR0147:28-Nov-2008:KarthikG :: Procedure altered to add one more parameter.
--Used in reports 'SM_OperatorProd_Batch_Shiftwise' and 'SM_WeeklyOperatorProductionReport'
DR0176:24/Mar/2009:Karthik G :: Divide by zero error encountered.
mod 1 :- ER0181 By Kusuma M.H on 13-May-2009.2) Modify all the procedures accordingly. Qualify machine wherever we are making use of component and opeartion no.
mod 2 :- ER0182 By Kusuma M.H on 13-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
mod 3:-  By Mrudula M. Rao on 12-mar-2009.ER0210 Introduce PDT on 5150.
	1) Handle PDT at Machine Level.
	2) Corrected calculations for loadunload and cycletime for boundary records.
	3) Correct exception rule calculation.
DR0249 - KarthikG - 12/Aug/2010 :: To handle Error Subquery returned more than one value.
				   ReportName -  SM_WeeklyOperatorProductionReport.rpt
*************************************************************************************************/
--s_WeeklyOperatorProductionReport '2021-01-12','2021-01-12','','',''
CREATE                       PROCEDURE [dbo].[s_WeeklyOperatorProductionReport]
			@startdate datetime,
			@enddate datetime,
			@Operator nvarchar(50)= '',
			@PlantID nvarchar(50)= '',
			@parameter nvarchar(50)= ''  -- timebatch,timebatch_shiftwise --DR0147
AS
Begin
declare @machineid as nVarchar(50)
declare @compid as nvarchar(50)
declare @operationid as nvarchar(50)
declare @Operatorid as nvarchar(50)
declare @idealcycletime as int
declare @idealloadunload as int
declare @cycletime int
declare @loadunload int
declare @curmachineid as nvarchar(50)
declare @curcomp as nvarchar(50)
declare @curop as nvarchar(50)
declare @curoperatorid as nvarchar(50)
declare @downtime as int
declare @avgcycletime as int
declare @avgloadunload as int
declare @qty as int
declare @stdate as datetime
declare @curstdate as datetime
declare @strsql nvarchar (4000)
declare @TimeFormat as nvarchar(50)
declare @StrOPlant As nvarchar(255)
declare @StrOpr As nvarchar(255)
--mod 3:-SELECT * From CockpitDefaults
Declare @Ignore_Count_4m_PLD as nVarchar(50)
Declare @Ignore_Dtime_4m_PLD as nVarchar(50)
Declare @Ignore_Dtime_4m_PLD_interface as nVarchar(50)
Declare @Ignore_Ptime_4m_PLD as nVarchar(50)
--mod 3:-
--Begin: Temp Table
create table #TblWeeklyProdRpt
(
	SerialNo bigint NOT NULL,
	Operator nvarchar(50),
	Operatorname nvarchar(50),
	Machine nvarchar(50) NOT NULL,
	stdate datetime,
	Component nvarchar(50),
	Operation nvarchar(50),
	Qty int,
	FromTime datetime,
	ToTime datetime,
	IdealMachiningTime int,
	IdealLoadUnloadtime int,
	CycleTime int,
	LoadUnload int,
	datatype tinyint,
	dcode nvarchar(50),
	parts Float,
	Downtime bigint,
	--mod 3(1)
	msttime datetime,
	Ratio float
	---mod 3(1)
)
Alter Table #TblWeeklyProdRpt
	ADD PRIMARY KEY CLUSTERED
		(machine,SerialNo) ON [PRIMARY]
CREATE TABLE #Exceptions
(
	MachineID NVarChar(50),
	ComponentID Nvarchar(50),
	OperationNo Int,
	StartTime DateTime,
	EndTime DateTime,
	Ratio Float
)
--End: Temp Table
select @strsql = ''
select @StrOPlant = ''
select @StrOpr = ''
-------------------------------To handle Missed Batch record----------------------------- 
--if isnull(@operator, '') <> ''
--begin
--	---mod 2
----	SELECT @StrOpr=' And employeeinformation.EmployeeID='''+ @Operator +''''
--	SELECT @StrOpr=' And employeeinformation.EmployeeID= N'''+ @Operator +''''
--	---mod 2
----print @StrOpr
--end

-------------------------------To handle Missed Batch record----------------------------- 

if isnull(@operator, '') <> ''
begin
	---mod 2
--	SELECT @StrOpr=' And employeeinformation.EmployeeID='''+ @Operator +''''
	SELECT @StrOpr=' And operator= N'''+ @Operator +''''
	---mod 2
--print @StrOpr
end


if isnull(@PlantID, '') <> ''
begin
	---mod 2
--	SELECT @StrOPlant=' And PlantEmployee.PlantID='''+ @PlantID +''''
	SELECT @StrOPlant=' And PlantEmployee.PlantID= N'''+ @PlantID +''''
	---mod 2
end
SELECT @TimeFormat = 'ss'
SELECT @TimeFormat = isnull((SELECT  ValueInText  FROM CockpitDefaults WHERE Parameter = 'TimeFormat'),'ss')
if (@TimeFormat <> 'hh:mm:ss' and @TimeFormat <> 'hh' and @TimeFormat <> 'mm' and @TimeFormat <> 'ss' )
begin
	select @TimeFormat = 'ss'
end
select @Ignore_Count_4m_PLD = 'N'
select @Ignore_Count_4m_PLD = isnull(ValueInText,'N') From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD'
select @Ignore_Ptime_4m_PLD = 'N'
select @Ignore_Ptime_4m_PLD = isnull(ValueInText,'N') From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD'
SELECT @Ignore_Dtime_4m_PLD = 'N'
SELECT @Ignore_Dtime_4m_PLD =  isnull(ValueInText,'N') From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD'
select @Ignore_Dtime_4m_PLD_interface = isnull(interfaceid,'') from downcodeinformation where downid = @Ignore_Dtime_4m_PLD

BEGIN
/*
	SELECT @StrSql='insert into #TblWeeklyProdRpt(serialno,Operator,Operatorname,machine,stdate,component,operation,idealmachiningtime,idealloadunloadtime,cycletime,loadunload,fromtime,totime,datatype,dcode,parts)'
	SELECT @StrSql=@StrSql+' SELECT autodata.id,employeeinformation.employeeid,employeeinformation.name,machineinformation.machineid,'
	SELECT @StrSql=@StrSql+' autodata.stdate,ci.componentid,cop.operationno,cop.machiningtime,(cop.cycletime-cop.machiningtime),'
	SELECT @StrSql=@StrSql+' autodata.cycletime, autodata.loadunload,autodata.sttime, autodata.ndtime,autodata.datatype,autodata.dcode,autodata.partscount'
	SELECT @StrSql=@StrSql+' from autodata inner join employeeinformation on (autodata.opr = employeeinformation.interfaceid)'
	SELECT @StrSql=@StrSql+' Left Outer Join PlantEmployee on PlantEmployee.Employeeid=employeeinformation.Employeeid'
	SELECT @StrSql=@StrSql+' inner join machineinformation on (autodata.mc = machineinformation.interfaceid)'
	SELECT @StrSql=@StrSql+' inner join componentinformation ci on (ci.interfaceid = autodata.comp)'
	SELECT @StrSql=@StrSql+' inner join componentoperationpricing cop on (cop.interfaceid = autodata.opn and ci.componentid = cop.componentid)'
	SELECT @StrSql=@StrSql+' where sttime >= '''+ Convert(NVarChar(20),@startdate) +''' and ndtime <= '''+ Convert(NVarChar(20),@enddate) +''''
	SELECT @StrSql=@StrSql+ @StrOPlant+@StrOpr
	SELECT @StrSql=@StrSql+' order by machineinformation.machineid, sttime,autodata.id'
	EXEC(@StrSql)
*/
/**************************************************************************************************************/
--mod 3 : Get PDT at machienlevel
SELECT
	CASE When StartTime<@StartDate Then @StartDate Else StartTime End As StartTime,
	CASE When EndTime>@EndDate Then @EndDate Else EndTime End As EndTime,Machine,MachineInformation.Interfaceid as MachineInterface
	INTO #PlannedDownTimes
	FROM PlannedDownTimes inner join MachineInformation on MachineInformation.Machineid=PlannedDownTimes.Machine
	WHERE PDTstatus = 1 and ((StartTime >= @StartDate  AND EndTime <=@EndDate)
	OR ( StartTime < @StartDate  AND EndTime <= @EndDate AND EndTime > @StartDate )
	OR ( StartTime >= @StartDate   AND StartTime <@EndDate AND EndTime > @EndDate )
	OR ( StartTime < @StartDate  AND EndTime > @EndDate) )
	ORDER BY StartTime


--mod 3
/* 			FOLLOWING SECTION IS ADDED BY SANGEETA KALLUR					*/
Select @strsql=''
SELECT @StrSql = 'INSERT INTO #Exceptions(MachineID ,ComponentID,OperationNo,StartTime ,EndTime , Ratio )
		SELECT Ex.MachineID ,Ex.ComponentID,Ex.OperationNo,StartTime ,EndTime ,CAST(CAST(ActualCount AS FLOAT)/CAST(IdealCount AS FLOAT)AS FLOAT)
		From ProductionCountException Ex
		Inner Join MachineInformation M ON Ex.MachineID=M.MachineID
		Inner Join ComponentInformation C ON Ex.ComponentID=C.ComponentID
		Inner Join Componentoperationpricing O ON Ex.OperationNo=O.OperationNo AND C.ComponentID=O.ComponentID '
		---mod 1		
		SELECT @StrSql = @StrSql + ' and O.MachineId=Ex.MachineId '
		---mod 1
		SELECT @StrSql = @StrSql + ' WHERE  M.MultiSpindleFlag=1 '
		SELECT @StrSql =@StrSql +'AND ((Ex.StartTime>=  ''' + convert(nvarchar(20),@StartDate,120)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@EndDate,120)+''' )
		OR (Ex.StartTime< ''' + convert(nvarchar(20),@StartDate,120)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@StartDate,120)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@EndDate,120)+''')
		OR(Ex.StartTime>= ''' + convert(nvarchar(20),@StartDate,120)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@EndDate,120)+''' AND Ex.StartTime< ''' + convert(nvarchar(20),@EndDate,120)+''')
		OR(Ex.StartTime< ''' + convert(nvarchar(20),@StartDate,120)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@EndDate,120)+''' ))'
Exec (@strsql)
UPDATE #Exceptions SET StartTime=@StartDate WHERE (StartTime<@StartDate)AND EndTime>@StartDate
UPDATE #Exceptions SET EndTime=@EndDate WHERE (EndTime>@EndDate AND StartTime<@EndDate )

--Type 1 and 2
Select @strsql=''
SELECT @StrSql='Insert Into #TblWeeklyProdRpt(serialno,Operator,Operatorname,machine,stdate,component,operation,idealmachiningtime,idealloadunloadtime,cycletime,loadunload,fromtime,totime,datatype,dcode,parts,msttime,ratio)'
SELECT @StrSql=@StrSql+' SELECT distinct autodata.id,employeeinformation.employeeid,employeeinformation.name,machineinformation.machineid,'
SELECT @StrSql=@StrSql+' autodata.stdate,ci.componentid,cop.operationno,cop.machiningtime,(cop.cycletime-cop.machiningtime),'
SELECT @StrSql=@StrSql+'
		CASE
		WHEN  (sttime >= '''+ Convert(NVarChar(20),@startdate) +''' and ndtime <= '''+ Convert(NVarChar(20),@enddate) +''') THEN autodata.cycletime '
--mod 3(2)
---SELECT @StrSql=@StrSql+ 'Else DateDiff(ss,'''+ Convert(NVarChar(20),@startdate) +''',ndtime) END , '
SELECT @StrSql=@StrSql+ 'When  (sttime< '''+ Convert(NVarChar(20),@startdate,120) +''' and ndtime>'''+ Convert(NVarChar(20),@startdate,120) +''' and ndtime <= '''+ Convert(NVarChar(20),@enddate,120) +''') THEN   DateDiff(ss,'''+ Convert(NVarChar(20),@startdate,120) +''',ndtime) END , '
--mod 3(2)
---mod 3(2)
--SELECT @StrSql=@StrSql+ ' CASE
		--WHEN (sttime >= '''+ Convert(NVarChar(20),@startdate) +''' and ndtime <= '''+ Convert(NVarChar(20),@enddate) +''') THEN autodata.loadunload
		--ELSE DateDiff(ss,'''+ Convert(NVarChar(20),@startdate) +''',ndtime) END , '
SELECT @StrSql=@StrSql+ 'CASE WHEN AUTODATA.DATATYPE = 1 THEN ( CASE
		WHEN (msttime >= '''+ Convert(NVarChar(20),@startdate,120) +''' and ndtime <= '''+ Convert(NVarChar(20),@enddate,120) +''') THEN autodata.loadunload
		When  (msttime< '''+ Convert(NVarChar(20),@startdate,120) +''' and sttime>'''+ Convert(NVarChar(20),@startdate,120) +'''  and  ndtime>'''+ Convert(NVarChar(20),@startdate,120) +''' and ndtime <= '''+ Convert(NVarChar(20),@enddate,120) +''') THEN
		 DateDiff(ss,'''+ Convert(NVarChar(20),@startdate,120) +''',sttime)
		ELSE 0  END )
		WHEN AUTODATA.DATATYPE=2 THEN
		( CASE
		WHEN (msttime >= '''+ Convert(NVarChar(20),@startdate,120) +''' and ndtime <= '''+ Convert(NVarChar(20),@enddate,120) +''') THEN autodata.loadunload
		When  (msttime< '''+ Convert(NVarChar(20),@startdate,120) +'''   and  ndtime>'''+ Convert(NVarChar(20),@startdate,120) +''' and ndtime <= '''+ Convert(NVarChar(20),@enddate,120) +''') THEN
		 DateDiff(ss,'''+ Convert(NVarChar(20),@startdate,120) +''',NDTIME)
		ELSE 0  END ) END , '
---mod 3(2)
SELECT @StrSql=@StrSql+ 'autodata.sttime, autodata.ndtime,autodata.datatype,autodata.dcode, '
--mod 3(3)
--SELECT @StrSql=@StrSql+ 'CASE WHEN Autodata.Ndtime >T1.StartTime And Autodata.Ndtime <=T1.EndTime THEN T1.Ratio  ELSE Autodata.partscount End'
SELECT @StrSql=@StrSql+ ' autodata.partscount,autodata.msttime,CASE WHEN Autodata.Ndtime >T1.StartTime And Autodata.Ndtime <=T1.EndTime THEN T1.Ratio else 1 ENd '
--mod 3(2)
SELECT @StrSql=@StrSql+' from autodata inner join employeeinformation on (autodata.opr = employeeinformation.interfaceid)'
SELECT @StrSql=@StrSql+' Left Outer Join PlantEmployee on PlantEmployee.Employeeid=employeeinformation.Employeeid'
SELECT @StrSql=@StrSql+' inner join machineinformation on (autodata.mc = machineinformation.interfaceid)'
SELECT @StrSql=@StrSql+' inner join componentinformation ci on (ci.interfaceid = autodata.comp)'
SELECT @StrSql=@StrSql+' inner join componentoperationpricing cop on (cop.interfaceid = autodata.opn and ci.componentid = cop.componentid)'
---mod 1
SELECT @StrSql=@StrSql+' and cop.machineid= machineinformation.machineid '
---mod 1
SELECT @strsql=@strsql+' LEFT OUTER JOIN (SELECT MachineID,ComponentID,OperationNo,StartTime,EndTime ,Ratio From #Exceptions) AS T1
			ON T1.MachineID=machineinformation.MachineID AND T1.ComponentID=Ci.ComponentID
			AND T1.OperationNo=COP.OperationNo AND Autodata.Ndtime >T1.StartTime And Autodata.Ndtime <=T1.EndTime'
SELECT @StrSql=@StrSql+' where ((msttime >= '''+ Convert(NVarChar(20),@startdate,120) +''' and ndtime <= '''+ Convert(NVarChar(20),@enddate,120) +''')
			OR(msttime < '''+ Convert(NVarChar(20),@startdate,120) +''' AND ndtime > '''+ Convert(NVarChar(20),@startdate,120) +''' AND ndtime <= '''+ Convert(NVarChar(20),@enddate,120) +'''))'
--SELECT @StrSql=@StrSql+ @StrOPlant+@StrOpr (commented To Handle missed batch record)
SELECT @StrSql=@StrSql+ @StrOPlant
SELECT @StrSql=@StrSql+' order by machineinformation.machineid, sttime,autodata.id'
print @StrSql
EXEC(@StrSql)

--Type 3 and 4
Select @strsql=''
SELECT @StrSql='insert into #TblWeeklyProdRpt(serialno,Operator,Operatorname,machine,stdate,component,operation,idealmachiningtime,idealloadunloadtime,cycletime,loadunload,fromtime,totime,datatype,dcode)'
SELECT @StrSql=@StrSql+' SELECT distinct autodata.id,employeeinformation.employeeid,employeeinformation.name,machineinformation.machineid,'
SELECT @StrSql=@StrSql+' autodata.stdate,ci.componentid,cop.operationno,cop.machiningtime,(cop.cycletime-cop.machiningtime),'
--MOD 3(2)
--SELECT @StrSql=@StrSql+'
	--		CASE
		--	WHEN (sttime>='''+ Convert(NVarChar(20),@startdate) +''' AND sttime< '''+ Convert(NVarChar(20),@enddate) +''' AND ndtime> '''+ Convert(NVarChar(20),@enddate) +''' ) THEN DateDiff(ss,sttime,'''+ Convert(NVarChar(20),@enddate) +''')
			--ELSE DateDiff(ss,'''+ Convert(NVarChar(20),@startdate) +''','''+ Convert(NVarChar(20),@enddate) +''') END,
			--CASE
			--WHEN (sttime>='''+ Convert(NVarChar(20),@startdate) +''' AND sttime< '''+ Convert(NVarChar(20),@enddate) +''' AND ndtime> '''+ Convert(NVarChar(20),@enddate) +''' ) THEN DateDiff(ss,sttime,'''+ Convert(NVarChar(20),@enddate) +''')
			--ELSE DateDiff(ss,'''+ Convert(NVarChar(20),@startdate) +''','''+ Convert(NVarChar(20),@enddate) +''') END, '
SELECT @StrSql=@StrSql+ 'cASE WHEN autodata.DATATYPE=1 then
			(CASE
			WHEN (sttime>='''+ Convert(NVarChar(20),@startdate,120) +''' AND sttime< '''+ Convert(NVarChar(20),@enddate,120) +''' AND ndtime> '''+ Convert(NVarChar(20),@enddate,120) +''' ) THEN DateDiff(ss,sttime,'''+ Convert(NVarChar(20),@enddate,120) +''')
			WHEN (sttime< '''+ Convert(NVarChar(20),@startdate,120) +''' AND ndtime> '''+ Convert(NVarChar(20),@enddate,120) +''' )then  DateDiff(ss,'''+ Convert(NVarChar(20),@startdate,120) +''','''+ Convert(NVarChar(20),@enddate,120) +''') END)
			 end ,'
SELECT @StrSql=@StrSql+ 'cASE WHEN autodata.DATATYPE=1 then
			(CASE
			WHEN (msttime>='''+ Convert(NVarChar(20),@startdate,120) +''' AND msttime< '''+ Convert(NVarChar(20),@enddate,120) +''' AND ndtime> '''+ Convert(NVarChar(20),@enddate,120) +'''  and sttime>'''+ Convert(NVarChar(20),@enddate,120) +''' ) THEN DateDiff(ss,msttime,'''+ Convert(NVarChar(20),@enddate,120) +''')
			WHEN (msttime>='''+ Convert(NVarChar(20),@startdate,120) +''' AND msttime< '''+ Convert(NVarChar(20),@enddate,120) +''' AND ndtime> '''+ Convert(NVarChar(20),@enddate,120) +'''  and sttime<='''+ Convert(NVarChar(20),@enddate,120) +''' ) THEN DateDiff(ss,msttime,sttime)
			WHEN (msttime< '''+ Convert(NVarChar(20),@startdate,120) +''' AND ndtime> '''+ Convert(NVarChar(20),@enddate,120) +''' and sttime>'''+ Convert(NVarChar(20),@startdate,120) +'''  and  sttime<'''+ Convert(NVarChar(20),@enddate,120) +''' )then  DateDiff(ss,'''+ Convert(NVarChar(20),@startdate,120) +''',sttime)
			WHEN (msttime< '''+ Convert(NVarChar(20),@startdate,120) +''' AND ndtime> '''+ Convert(NVarChar(20),@enddate,120) +''' and sttime>'''+ Convert(NVarChar(20),@enddate,120) +''' )then  DateDiff(ss,'''+ Convert(NVarChar(20),@startdate,120) +''','''+ Convert(NVarChar(20),@enddate,120) +''' ) END)
			 When autodata.datatype=2 then (CASE
			WHEN (sttime>='''+ Convert(NVarChar(20),@startdate,120) +''' AND sttime< '''+ Convert(NVarChar(20),@enddate,120) +''' AND ndtime> '''+ Convert(NVarChar(20),@enddate,120) +''' ) THEN DateDiff(ss,sttime,'''+ Convert(NVarChar(20),@enddate,120) +''')
			WHEN (sttime< '''+ Convert(NVarChar(20),@startdate,120) +''' AND ndtime> '''+ Convert(NVarChar(20),@enddate,120) +''' )then  DateDiff(ss,'''+ Convert(NVarChar(20),@startdate,120) +''','''+ Convert(NVarChar(20),@enddate,120) +''') END)
			 end ,'
--MOD 3(2)	
	
SELECT @StrSql=@StrSql+	'autodata.sttime, autodata.ndtime,autodata.datatype,autodata.dcode'
SELECT @StrSql=@StrSql+' from autodata inner join employeeinformation on (autodata.opr = employeeinformation.interfaceid)'
SELECT @StrSql=@StrSql+' Left Outer Join PlantEmployee on PlantEmployee.Employeeid=employeeinformation.Employeeid'
SELECT @StrSql=@StrSql+' inner join machineinformation on (autodata.mc = machineinformation.interfaceid)'
SELECT @StrSql=@StrSql+' inner join componentinformation ci on (ci.interfaceid = autodata.comp)'
SELECT @StrSql=@StrSql+' inner join componentoperationpricing cop on (cop.interfaceid = autodata.opn and ci.componentid = cop.componentid)'
---mod 1
SELECT @StrSql=@StrSql+' and cop.machineid= machineinformation.machineid '
---mod 1
SELECT @StrSql=@StrSql+' where ((msttime>='''+ Convert(NVarChar(20),@startdate,120) +''' AND msttime< '''+ Convert(NVarChar(20),@enddate,120) +''' AND ndtime> '''+ Convert(NVarChar(20),@enddate,120) +''' )
			 OR(msttime<'''+ Convert(NVarChar(20),@startdate,120) +''' AND NdTime>'''+ Convert(NVarChar(20),@enddate,120) +'''))'
--SELECT @StrSql=@StrSql+ @StrOPlant+@StrOpr (commented To Handle missed batch record)
SELECT @StrSql=@StrSql+ @StrOPlant
SELECT @StrSql=@StrSql+' order by machineinformation.machineid, sttime,autodata.id'
print @StrSql
EXEC(@StrSql)

--Type 1,Type 2,Type 3 and Type 4  (Ignore overlapping with PDT)
IF @Ignore_Ptime_4m_PLD='Y'
Begin
	select @strsql=''
	SELECT @StrSql= @StrSql+ 'update #TblWeeklyProdRpt  set parts=isnull(#TblWeeklyProdRpt.parts,0)-T1.partcount , cycletime=isnull(#TblWeeklyProdRpt.cycletime,0) -isnull(T1.cycletime,0) ,loadunload=isnull(#TblWeeklyProdRpt.loadunload,0) -isnull(T1.LUNL,0) from
	( SELECT distinct A.id  as slno,'
	SELECT @StrSql=@StrSql+'
			sum(CASE
			WHEN  (sttime >= T.StartTime and ndtime <= T.Endtime) THEN A.cycletime
			When  (sttime< T.Starttime and ndtime>T.Starttime and ndtime <= T.Endtime ) THEN   DateDiff(ss,T.Starttime,ndtime)
			When (sttime>=T.Starttime and sttime<T.Endtime and ndtime>T.Endtime)  then DateDiff(ss,sttime,T.EndTime )
			When (sttime<T.Starttime and ndtime>T.Endtime) then datediff(second, T.Starttime,T.Endtime)
			Else 0 END ) as cycletime   , '
	SELECT @StrSql=@StrSql+ 'sum(CASE
			WHEN (msttime >= T.Starttime and sttime <= T.Endtime ) THEN A.loadunload
			When  (msttime< T.Starttime and sttime>T.Starttime  and  sttime<=T.endtime) THEN  DateDiff(ss,T.Starttime,sttime)
			When  (msttime>=T.Starttime and sttime>T.Endtime  and  msttime<T.endtime) THEN  DateDiff(ss,msttime,T.Endtime)
			When (msttime<T.Starttime and sttime>T.Endtime) then datediff(second, T.Starttime,T.Endtime)
			ELSE 0  END ) as LUNL,
			A.sttime, A.ndtime,A.datatype,
			sum(case when ndtime>T.Starttime and ndtime<=T.Endtime and ''' + @Ignore_Count_4m_PLD  + '''=''Y''' + ' then partscount else 0  end )  as partcount ,A.msttime '
	SELECT @StrSql=@StrSql+' from autodata A inner join employeeinformation E on (A.opr = E.interfaceid)'
	SELECT @StrSql=@StrSql+' Left Outer Join PlantEmployee on PlantEmployee.Employeeid=E.Employeeid'
	SELECT @StrSql=@StrSql+' inner join machineinformation M on (A.mc = M.interfaceid)'
	SELECT @StrSql=@StrSql+' inner join componentinformation ci on (ci.interfaceid = A.comp)'
	SELECT @StrSql=@StrSql+' inner join componentoperationpricing cop on (cop.interfaceid = A.opn and ci.componentid = cop.componentid)'
	SELECT @StrSql=@StrSql+' and cop.machineid= M.machineid '
	SELECT @strsql=@strsql+' inner join #PlannedDownTimes T on T.MachineInterface=A.mc  '
	SELECT @StrSql=@StrSql+' where A.datatype=1 and ((msttime >= '''+ Convert(NVarChar(20),@startdate,120) +''' and ndtime <= '''+ Convert(NVarChar(20),@enddate,120) +''')
				OR(msttime < '''+ Convert(NVarChar(20),@startdate,120) +''' AND ndtime > '''+ Convert(NVarChar(20),@startdate,120) +''' AND ndtime <= '''+ Convert(NVarChar(20),@enddate,120) +''')
				OR (msttime >= '''+ Convert(NVarChar(20),@startdate,120) +''' and msttime<'''+ Convert(NVarChar(20),@enddate,120) +''' and  ndtime >'''+ Convert(NVarChar(20),@enddate,120) +''')
				OR(msttime < '''+ Convert(NVarChar(20),@startdate,120) +''' AND ndtime > '''+ Convert(NVarChar(20),@enddate,120) +''' ) )
				and ((msttime >= T.Starttime and ndtime <= T.Endtime)
				OR(msttime < T.Starttime AND ndtime > T.Starttime AND ndtime <= T.Endtime)
				or(msttime>=T.Starttime and ndtime>T.Endtime  and  msttime<T.endtime)
				or(msttime<T.Starttime and ndtime>T.Endtime))'
	--SELECT @StrSql=@StrSql+ @StrOPlant+@StrOpr
	SELECT @StrSql=@StrSql+' Group by A.msttime,sttime,ndtime,datatype,A.id ) as T1 inner join #tblweeklyprodrpt on #tblweeklyprodrpt.serialno=T1.slno '
	print @StrSql
	EXEC(@StrSql)

	--Handle intearction between ICD and PDT for type 1 production record for the selected time period (Added for GEA To handle -ve Cycletime)
		UPDATE #TblWeeklyProdRpt set CycleTime =isnull(CycleTime,0) + isNull(T2.IPDT ,0) FROM	
		(
		Select T1.mc,T1.comp,T1.opn,T1.opr,T1.sttime,T1.ndtime,T1.cyclestart,T1.Cycleend,T1.id,SUM(
			CASE 	
				When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1
				When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2
				When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3
				when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4
			END) as IPDT from
		(Select A.mc,A.comp,A.opn,A.opr,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime,A.ndtime, A.datatype,
		 B.Sttime as CycleStart,B.ndtime as CycleEnd,B.id from autodata A 
		 inner join AutoData B on B.mc = A.mc and A.comp=B.comp and A.opn=B.opn and A.opr=B.opr
		 Where A.DataType=2 and B.DataType=1
			And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And
			(B.msttime >= @startdate AND B.ndtime <= @enddate) and
			(B.sttime <= A.sttime) AND (B.ndtime >= A.ndtime) 			
		 )as T1 inner join
		(select  machine,Case when starttime<@startdate then @startdate else starttime end as starttime, 
		case when endtime> @enddate then @enddate else endtime end as endtime from dbo.PlannedDownTimes 
		where PDTStatus = 1 and ((( StartTime >=@startdate) And ( EndTime <=@enddate))
		or (StartTime < @startdate  and  EndTime <= @enddate AND EndTime > @startdate)
		or (StartTime >= @startdate  AND StartTime <@enddate AND EndTime > @enddate)
		or (( StartTime <@startdate) And ( EndTime >@enddate )) )
		)T
		on T1.machine=T.machine AND
		((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
		or (T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
		or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
		or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )group by T1.mc,T1.comp,T1.opn,T1.opr,T1.sttime,T1.ndtime,T1.cyclestart,T1.Cycleend,T1.id
		)AS T2  INNER JOIN #tblweeklyprodrpt on #tblweeklyprodrpt.serialno=T2.id

	update #TblWeeklyProdRpt  set parts=parts*Ratio
END


IF @Ignore_Dtime_4m_PLD='Y'
Begin
	select @strsql=''
	SELECT @StrSql= @StrSql+ 'update #TblWeeklyProdRpt  set loadunload=isnull(#TblWeeklyProdRpt.loadunload,0) -isnull(T1.LUNL,0) from
	( SELECT distinct A.id  as slno,
		SUM(CASE
		WHEN  (sttime >= T.StartTime and ndtime <= T.Endtime) THEN A.loadunload
		When  (sttime< T.Starttime and ndtime>T.Starttime and ndtime <= T.Endtime ) THEN   DateDiff(ss,T.Starttime,ndtime)
		When (sttime>=T.Starttime and sttime<T.Endtime and ndtime>T.Endtime)  then DateDiff(ss,sttime,T.EndTime )
		When (sttime<T.Starttime and ndtime>T.Endtime) then datediff(second, T.Starttime,T.Endtime) Else 0 END ) as LUNL,
			A.sttime, A.ndtime,A.datatype,A.msttime '
	SELECT @StrSql=@StrSql+' from autodata A inner join employeeinformation E on (A.opr = E.interfaceid)'
	SELECT @StrSql=@StrSql+' Left Outer Join PlantEmployee on PlantEmployee.Employeeid=E.Employeeid'
	SELECT @StrSql=@StrSql+' inner join machineinformation M on (A.mc = M.interfaceid)'
	SELECT @StrSql=@StrSql+' inner join componentinformation ci on (ci.interfaceid = A.comp)'
	SELECT @StrSql=@StrSql+' inner join componentoperationpricing cop on (cop.interfaceid = A.opn and ci.componentid = cop.componentid)'
	SELECT @StrSql=@StrSql+' and cop.machineid= M.machineid '
	SELECT @strsql=@strsql+' inner join #PlannedDownTimes T on T.MachineInterface=A.mc  '
	SELECT @StrSql=@StrSql+' where A.datatype=2 and ((msttime >= '''+ Convert(NVarChar(20),@startdate,120) +''' and ndtime <= '''+ Convert(NVarChar(20),@enddate,120) +''')
				OR(msttime < '''+ Convert(NVarChar(20),@startdate,120) +''' AND ndtime > '''+ Convert(NVarChar(20),@startdate,120) +''' AND ndtime <= '''+ Convert(NVarChar(20),@enddate,120) +''')
				OR (msttime >= '''+ Convert(NVarChar(20),@startdate,120) +''' and msttime<'''+ Convert(NVarChar(20),@enddate,120) +''' and  ndtime >'''+ Convert(NVarChar(20),@enddate,120) +''')
				OR(msttime < '''+ Convert(NVarChar(20),@startdate,120) +''' AND ndtime > '''+ Convert(NVarChar(20),@enddate,120) +''' ) )
				and ((msttime >= T.Starttime and ndtime <= T.Endtime)
				OR(msttime < T.Starttime AND ndtime > T.Starttime AND ndtime <= T.Endtime)
				or(msttime>=T.Starttime and ndtime>T.Endtime  and  msttime<T.endtime)
				or(msttime<T.Starttime and ndtime>T.Endtime))'
	--SELECT @StrSql=@StrSql+ @StrOPlant+@StrOpr
	SELECT @StrSql=@StrSql+' Group by A.msttime,sttime,ndtime,datatype,A.id ) as T1 inner join #tblweeklyprodrpt on #tblweeklyprodrpt.serialno=T1.slno '
	print @StrSql
	EXEC(@StrSql)

END

END	


--DR0147
	if isnull(@parameter, '') = 'timebatchshiftwise'		-- timebatchshiftwise
	begin
	update #tblweeklyprodrpt set stdate = @startdate
	end
	Declare RptCursor CURSOR FOR
		SELECT 	#tblweeklyprodrpt.operator,
		        #tblweeklyprodrpt.machine,
			#tblweeklyprodrpt.stdate,
			#tblweeklyprodrpt.component,
			#tblweeklyprodrpt.operation
		from 	#tblweeklyprodrpt
		order by machine,fromtime
	
		OPEN RptCursor
				
		FETCH NEXT FROM RptCursor INTO @operatorid,@machineid, @stdate, @compid, @operationid
		if (@@fetch_status = 0)
		begin
		  select @qty = 1
		  update #Tblweeklyprodrpt set qty = @qty where current of rptcursor
		
		  -- initialize current variables		
		  select @curoperatorid = @operatorid	
		  select @curmachineid = @machineid	
		  select @curcomp = @compid
		  select @curop = @operationid
		  select @curstdate = @stdate
		end	
		   WHILE (@@fetch_status <> -1)
			BEGIN
			  IF (@@fetch_status <> -2)
			    BEGIN
				FETCH NEXT FROM RptCursor INTO @operatorid, @machineid, @stdate, @compid, @operationid
				if (@@fetch_status = 0) and (@curoperatorid = @operatorid) and(@curmachineid = @machineid) and (@curcomp = @compid) and (@curop = @operationid) and (@curstdate = @stdate)
					begin
						update #Tblweeklyprodrpt set qty = @qty where current of rptcursor
					end
				else if (@@fetch_status = 0)
					begin -- 2
						select @qty = @qty + 1
						update #Tblweeklyprodrpt set qty = @qty where current of rptcursor
						
						select @curoperatorid = @operatorid	
						select @curmachineid = @machineid	
						select @curcomp = @compid
						select @curop = @operationid
						select @curstdate = @stdate
					end
			    END
			END
--Output
/*	--From here--DR0176:24/Mar/2009:Karthik G :: Divide by zero error encountered.
	select qty as Batch, operator,Operatorname, machine, stdate, component, operation,
	min(fromtime) BatchStart,
	max(totime) BatchEnd,
	datediff(s,min(fromtime),max(totime)) BatchPeriod,
	max(idealmachiningtime) IdealMachiningTime,
	max(idealloadunloadtime) IdealLoadUnload,
	dbo.f_FormatTime(max(idealmachiningtime),@TimeFormat)AS FormtIdealCycTime,
	dbo.f_FormatTime(max(idealloadunloadtime),@TimeFormat)AS FormtIdealLoadUnload,
	
	IsNull((select CAST(CEILING(CAST(sum(T1.parts)AS Float)/ISNULL(O.SubOperations,1))AS INTEGER) from #tblweeklyprodrpt T1
	Inner Join ComponentInformation C ON T1.Component=C.componentID
	INNER JOIN ComponentOperationPricing O ON T1.Operation=O.OperationNo AND C.ComponentID=O.ComponentID
	where datatype = 1 and t1.qty = t2.qty group by qty,O.SubOperations),0) as Production,
	isnull((select avg(T1.cycletime/T1.parts)* ISNULL(O.SubOperations,1) from #tblweeklyprodrpt t1
	Inner Join ComponentInformation C ON T1.Component=C.componentID
	INNER JOIN ComponentOperationPricing O ON T1.Operation=O.OperationNo AND C.ComponentID=O.ComponentID
	where datatype = 1 and t1.qty = t2.qty group by qty,O.SubOperations),0) as Avgcycle,
	
	isnull((select avg(T1.loadunload/T1.parts)* ISNULL(O.SubOperations,1) from #tblweeklyprodrpt t1
	Inner Join ComponentInformation C ON T1.Component=C.componentID
	INNER JOIN ComponentOperationPricing O ON T1.Operation=O.OperationNo AND C.ComponentID=O.ComponentID
	where datatype = 1 and t1.qty = t2.qty group by qty,O.SubOperations),0) as Avgloadunload,
	
	dbo.f_FormatTime(isnull((select avg(T1.cycletime/T1.parts)* ISNULL(O.SubOperations,1) from #tblweeklyprodrpt t1
	Inner Join ComponentInformation C ON T1.Component=C.componentID
	INNER JOIN ComponentOperationPricing O ON T1.Operation=O.OperationNo AND C.ComponentID=O.ComponentID
	where datatype = 1 and t1.qty = t2.qty group by qty,O.SubOperations),0) ,@TimeFormat) AS FormtAvgCycTime,
	
	dbo.f_FormatTime(isnull((select avg(T1.loadunload/T1.parts)* ISNULL(O.SubOperations,1) from #tblweeklyprodrpt t1
	Inner Join ComponentInformation C ON T1.Component=C.componentID
	INNER JOIN ComponentOperationPricing O ON T1.Operation=O.OperationNo AND C.ComponentID=O.ComponentID
	where datatype = 1 and t1.qty = t2.qty group by qty,O.SubOperations),0) ,@TimeFormat) AS FormtAvglLoadUnload,
	dbo.f_FormatTime(isnull((select sum(loadunload) from #tblweeklyprodrpt t1 where datatype = 2 and t1.qty = t2.qty group by qty),0),@TimeFormat) as BatchDown,
	
	isnull((select sum(CASE --Priviously it was sum(loadunload)instead of CASE
	WHEN loadunload >ISNULL(downcodeinformation.Threshold,0) and ISNULL(downcodeinformation.Threshold,0)>0 then ISNULL(downcodeinformation.Threshold,0)
	ELSE loadunload
	END) from #tblweeklyprodrpt t1 inner join downcodeinformation on t1.dcode = downcodeinformation.interfaceid
	where datatype = 2 and downcodeinformation.availeffy =1 and t1.qty = t2.qty group by qty),0) as BatchML
	from #tblweeklyprodrpt t2
	group by qty,operator,operatorname,machine,stdate,component,operation   order by operator,qty
	--Till here--DR0176:24/Mar/2009:Karthik G :: Divide by zero error encountered.
*/


	select qty as Batch,
	avg(T1.cycletime/parts)* ISNULL(O.SubOperations,1) as Avgcycle,
	avg(T1.loadunload/T1.parts)* ISNULL(O.SubOperations,1) as Avgload
	into #TempAvg from #tblweeklyprodrpt T1
	Inner Join ComponentInformation C ON T1.Component=C.componentID	
	INNER JOIN ComponentOperationPricing O ON T1.Operation=O.OperationNo AND C.ComponentID=O.ComponentID
	---mod 1
	inner join machineinformation on machineinformation.machineid=O.machineid
	---mod 1
	where T1.datatype=1 and T1.parts > 0 group by qty,O.SubOperations
	---select * from #TempAvg

	-----------------------------------------------------------------------Commented To Handle missed batch record	-------------------------------------------------------------------------
		--select qty as Batch, operator,Operatorname, machine, stdate, component, operation,
	--min(fromtime) BatchStart,max(totime) BatchEnd,datediff(s,min(fromtime),max(totime)) BatchPeriod,
	----max(idealmachiningtime) IdealMachiningTime,
	----max(idealloadunloadtime) IdealLoadUnload,

	--dbo.f_FormatTime(max(idealmachiningtime),'ss')as IdealMachiningTimeinsec,
	--dbo.f_FormatTime(max(idealloadunloadtime),'ss')as IdealLoadUnloadinsec,


	--dbo.f_FormatTime(max(idealmachiningtime),@TimeFormat)as IdealMachiningTime,
	--dbo.f_FormatTime(max(idealloadunloadtime),@TimeFormat)as IdealLoadUnload,

	--dbo.f_FormatTime(max(idealmachiningtime),@TimeFormat)AS FormtIdealCycTime,
	--dbo.f_FormatTime(max(idealloadunloadtime),@TimeFormat)AS FormtIdealLoadUnload,
	----IsNull((select CAST(CEILING(CAST(sum(T1.parts)AS Float)/ISNULL(O.SubOperations,1))AS INTEGER) from #tblweeklyprodrpt T1 Inner Join ComponentInformation C ON T1.Component=C.componentID	INNER JOIN ComponentOperationPricing O ON T1.Operation=O.OperationNo AND C.ComponentID=O.ComponentID where datatype = 1 and t1.qty = t2.qty group by qty,O.SubOperations),0) as Production, --DR0249 - KarthikG - 12/Aug/2010
	--round(IsNull((select CAST(CAST(sum(T1.parts)AS Float)/ISNULL(O.SubOperations,1)AS float) from #tblweeklyprodrpt T1 inner join machineinformation M on M.Machineid=T1.Machine Inner Join ComponentInformation C ON T1.Component=C.componentID Inner JOIN ComponentOperationPricing O ON T1.Operation=O.OperationNo AND C.ComponentID=O.ComponentID and O.Machineid=M.MachineID where datatype = 1 and t1.qty = t2.qty group by qty,O.SubOperations),0),2) as Production, --DR0249 - KarthikG - 12/Aug/2010
	----IsNull(A.Avgcycle,0) as AvgCycle,
	----IsNull(A.AvgLoad,0) as Avgloadunload,

	--dbo.f_FormatTime(IsNull(A.Avgcycle,0),'ss') as AvgCycleinsec,
	--dbo.f_FormatTime(IsNull(A.AvgLoad,0),'ss') as Avgloadunloadinsec,


	--dbo.f_FormatTime(IsNull(A.Avgcycle,0),@TimeFormat) as AvgCycle,
	--dbo.f_FormatTime(IsNull(A.AvgLoad,0),@TimeFormat) as Avgloadunload,
	--dbo.f_FormatTime(A.Avgcycle,@TimeFormat) AS FormtAvgCycTime,
	--dbo.f_FormatTime(A.AvgLoad ,@TimeFormat) AS FormtAvglLoadUnload,
	--dbo.f_FormatTime(isnull((select sum(loadunload) from #tblweeklyprodrpt t1 where datatype = 2 and t1.qty = t2.qty group by qty),0),@TimeFormat) as BatchDown,
	--isnull((select sum(CASE --Priviously it was sum(loadunload)instead of CASE
	--WHEN loadunload >ISNULL(downcodeinformation.Threshold,0) and ISNULL(downcodeinformation.Threshold,0)>0 then ISNULL(downcodeinformation.Threshold,0)
	--ELSE loadunload
	--END) from #tblweeklyprodrpt t1 inner join downcodeinformation on t1.dcode = downcodeinformation.interfaceid
	--where datatype = 2 and downcodeinformation.availeffy =1 and t1.qty = t2.qty group by qty),0) as BatchML
	--from #tblweeklyprodrpt t2  left outer join #TempAvg A on A.batch=t2.qty
	--group by qty,operator,operatorname,machine,stdate,component,operation ,A.Avgcycle,A.AvgLoad
	--order by operator,qty

	-----------------------------------------------------------------------Commented To Handle missed batch record	-------------------------------------------------------------------------


select @strsql=''
select @strsql='select qty as Batch, operator,Operatorname, machine, stdate, component, operation,
	min(fromtime) BatchStart,max(totime) BatchEnd,datediff(s,min(fromtime),max(totime)) BatchPeriod,
	dbo.f_FormatTime(max(idealmachiningtime),''ss'')as IdealMachiningTimeinsec,
	dbo.f_FormatTime(max(idealloadunloadtime),''ss'')as IdealLoadUnloadinsec,
	dbo.f_FormatTime(max(idealmachiningtime),'''+@TimeFormat+''')as IdealMachiningTime,
	dbo.f_FormatTime(max(idealloadunloadtime),'''+@TimeFormat+''')as IdealLoadUnload,
	dbo.f_FormatTime(max(idealmachiningtime),'''+@TimeFormat+''')AS FormtIdealCycTime,
	dbo.f_FormatTime(max(idealloadunloadtime),'''+@TimeFormat+''')AS FormtIdealLoadUnload,
	round(IsNull((select CAST(CAST(sum(T1.parts)AS Float)/ISNULL(O.SubOperations,1)AS float) from #tblweeklyprodrpt T1 inner join machineinformation M on M.Machineid=T1.Machine Inner Join ComponentInformation C ON T1.Component=C.componentID Inner JOIN ComponentOperationPricing O ON T1.Operation=O.OperationNo AND C.ComponentID=O.ComponentID and O.Machineid=M.MachineID where datatype = 1 and t1.qty = t2.qty group by qty,O.SubOperations),0),2) as Production, --DR0249 - KarthikG - 12/Aug/2010
	dbo.f_FormatTime(IsNull(A.Avgcycle,0),''ss'') as AvgCycleinsec,
	dbo.f_FormatTime(IsNull(A.AvgLoad,0),''ss'') as Avgloadunloadinsec,
	dbo.f_FormatTime(IsNull(A.Avgcycle,0),'''+@TimeFormat+''') as AvgCycle,
	dbo.f_FormatTime(IsNull(A.AvgLoad,0),'''+@TimeFormat+''') as Avgloadunload,
	dbo.f_FormatTime(A.Avgcycle,'''+@TimeFormat+''') AS FormtAvgCycTime,
	dbo.f_FormatTime(A.AvgLoad ,'''+@TimeFormat+''') AS FormtAvglLoadUnload,
	dbo.f_FormatTime(isnull((select sum(loadunload) from #tblweeklyprodrpt t1 where datatype = 2 and t1.qty = t2.qty group by qty),0),'''+@TimeFormat+''') as BatchDown,
	isnull((select sum(CASE --Priviously it was sum(loadunload)instead of CASE
	WHEN loadunload >ISNULL(downcodeinformation.Threshold,0) and ISNULL(downcodeinformation.Threshold,0)>0 then ISNULL(downcodeinformation.Threshold,0)
	ELSE loadunload
	END) from #tblweeklyprodrpt t1 inner join downcodeinformation on t1.dcode = downcodeinformation.interfaceid
	where datatype = 2 and downcodeinformation.availeffy =1 and t1.qty = t2.qty group by qty),0) as BatchML
	from #tblweeklyprodrpt t2  left outer join #TempAvg A on A.batch=t2.qty where 1=1 '
select @strsql=@strsql+@StrOpr
select @strsql=@strsql+'group by qty,operator,operatorname,machine,stdate,component,operation ,A.Avgcycle,A.AvgLoad 
	order by operator,qty '
print(@strsql)
exec(@strsql)
End
