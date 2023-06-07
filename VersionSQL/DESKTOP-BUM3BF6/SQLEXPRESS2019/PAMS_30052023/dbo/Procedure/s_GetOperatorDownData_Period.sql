/****** Object:  Procedure [dbo].[s_GetOperatorDownData_Period]    Committed by VersionSQL https://www.versionsql.com ******/

-- Author  - Sangeet Kallur on 10-Feb-2005
-- Calculation of DownTime for the specified period by considering the Type-1,type-2
-- Type-3,Type-4 cases by Operator View
--DR0108:by Shilpa
--mod 1 :- ER0182 By Kusuma M.H on 09-Jun-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
--Note:ER0181 not done because CO qualification not found.
--ER0210 By Karthikg on 16/Feb/2010 :: Introduce PDT on 5150. Handle PDT at Machine Level. 
--s_GetOperatorDownData_Period '2009-12-01 06:00:00','2009-12-02 06:00:00','','MCV 400',''

CREATE           PROCEDURE [dbo].[s_GetOperatorDownData_Period]

(	@StartTime  datetime,
	@EndTime  DateTime,
	@Operator nvarchar(50)= '',
	@MachineID nvarchar(50) = '',
	@PlantID nvarchar(50)=''
)
AS
BEGIN
CREATE TABLE #TempDownData
	( StartTime Datetime,
	  EndTime Datetime,
	  machineid nvarchar(50),
	  MchInterfaceID nvarchar(10),
	  OperatorID nvarchar(50),
	  OprInterfaceid nvarchar(50),
	  OperatorName nvarchar(50),
	  DownID nvarchar(50),
	  DownDescription nvarchar(50),
	  DownTime float,
	  ElapsedTime  INTEGER,
	  RecordID bigint PRIMARY KEY
	 )
declare @strsql nvarchar (4000)
declare @stroperator nvarchar(255)
declare @strMachine nvarchar(255)
Declare @strPlantID as nvarchar(50)
SET @strPlantID = ''
select @strMachine = ''
select @strsql = ''
select @stroperator = ''
if isnull(@operator, '') <> ''
begin
	---mod 1
--	select @stroperator = ' AND ( employeeinformation.employeeid = ''' + @Operator +''')'
	select @stroperator = ' AND ( employeeinformation.employeeid = N''' + @Operator +''')'
	---MOD 1
end
if isnull(@MachineId, '') <> ''
begin
	---mod 1
--	select @strMachine = ' AND ( machineInformation.machineId = ''' + @MachineId + ''')'
	select @strMachine = ' AND ( machineInformation.machineId = N''' + @MachineId + ''')'
	---mod 1
end
if isnull(@PlantID,'') <> ''
BEGIN
	---mod 1
--	SELECT @strPlantID = ' AND ( P.PlantID = ''' + @PlantID+ ''')'
	SELECT @strPlantID = ' AND ( P.PlantID = N''' + @PlantID+ ''')'
	---mod 1
END
select @strsql = 'insert into #TempDownData (StartTime,EndTime,MachineID,MchInterfaceID,OperatorID,OprInterfaceid,OperatorName,DownID,DownDescription, DownTime,ElapsedTime,  RecordID)
			select distinct
			autodata.sttime,
			autodata.ndtime,
			machineinformation.machineid,
			machineinformation.Interfaceid,
			employeeinformation.Employeeid,
			employeeinformation.InterfaceID,
			employeeinformation.Name,
			downcodeinformation.downid,
			downcodeinformation.downdescription,
			0,
			case
			When (autodata.msttime >= ''' + convert(nvarchar(20),@StartTime,120) + '''  AND autodata.ndtime <= ''' + convert(nvarchar(20),@EndTime,120) + ''')  then loadunload
			WHEN ( autodata.sttime < ''' + convert(nvarchar(20),@StartTime,120) + '''   AND autodata.ndtime <= ''' + convert(nvarchar(20),@EndTime,120) + ''' AND autodata.ndtime > ''' + convert(nvarchar(20),@StartTime,120) + ''' )THEN DateDiff(second, ''' + convert(nvarchar(20),@StartTime,120) + ''', ndtime)
			WHEN ( autodata.msttime >= ''' + convert(nvarchar(20),@StartTime,120) + '''   AND autodata.sttime < ''' + convert(nvarchar(20),@EndTime,120) + ''' AND autodata.ndtime > ''' + convert(nvarchar(20),@EndTime,120) + ''')  THEN  DateDiff(second, stTime, ''' + convert(nvarchar(20),@EndTime,120) + ''')
			ELSE
			DateDiff(second, ''' + convert(nvarchar(20),@StartTime,120) + ''', ''' + convert(nvarchar(20),@EndTime,120) + ''')
			End as ElapsedTime,
			autodata.id
			FROM         autodata INNER JOIN
			machineinformation ON autodata.mc = machineinformation.InterfaceID LEFT OUTER JOIN
			PlantMachine P on machineinformation.machineid = P.machineid  INNER JOIN
			downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid INNER JOIN
			employeeinformation ON autodata.opr = employeeinformation.interfaceid  LEFT OUTER JOIN
			PlantEmployee ON employeeinformation.Employeeid = PlantEmployee.employeeID
			WHERE
			(autodata.datatype = 2) AND'
select @strsql = @strsql + ' ((autodata.msttime >= ''' + convert(nvarchar(20),@StartTime,120) + '''  AND autodata.ndtime <= ''' + convert(nvarchar(20),@EndTime,120) + ''') '
select @strsql = @strsql + ' OR ( autodata.sttime < ''' + convert(nvarchar(20),@StartTime,120) + '''   AND autodata.ndtime <= ''' + convert(nvarchar(20),@EndTime,120) + ''' AND autodata.ndtime > ''' + convert(nvarchar(20),@StartTime,120) + ''' )'
select @strsql = @strsql + ' OR ( autodata.msttime >= ''' + convert(nvarchar(20),@StartTime,120) + '''   AND autodata.sttime < ''' + convert(nvarchar(20),@EndTime,120) + ''' AND autodata.ndtime > ''' + convert(nvarchar(20),@EndTime,120) + ''' )'
select @strsql = @strsql + ' OR ( autodata.msttime < ''' + convert(nvarchar(20),@StartTime,120) + '''   AND autodata.ndtime > ''' + convert(nvarchar(20),@EndTime,120) + ''' ) )'
select @strsql = @strsql + @stroperator + @strMachine + @strPlantID
select @strsql = @strsql + ' ORDER BY autodata.ndtime'
exec(@strsql)
print @strsql

--ER0210
DECLARE @StrPLD_DownId NVARCHAR(2000)
SELECT @StrPLD_DownId=''
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y' AND (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' 
BEGIN
	SELECT @StrPLD_DownId=' AND D.DownID= (SELECT ValueInText From CockpitDefaults Where Parameter =''Ignore_Dtime_4m_PLD'')'
END

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
BEGIN
		SELECT Machine,
			CASE When StartTime<@StartTime Then @StartTime Else StartTime End As StartTime,
			CASE When EndTime>@EndTime Then @EndTime Else EndTime End As EndTime
			INTO #PlannedDownTimes
		FROM PlannedDownTimes
		WHERE PDTstatus = 1 And ((StartTime >= @StartTime  AND EndTime <=@EndTime) 
		OR ( StartTime < @StartTime  AND EndTime <= @EndTime AND EndTime > @StartTime )
		OR ( StartTime >= @StartTime   AND StartTime <@EndTime AND EndTime > @EndTime )
		OR ( StartTime < @StartTime  AND EndTime > @EndTime)) 
		And machine in (Select distinct MachineID from #TempDownData)

		Select @strSql=''
		Select @strSql='update #TempDownData set ElapsedTime = isnull(#TempDownData.ElapsedTime,0) - isNull(t1.DownTime ,0) from (
			Select M.RecordID,
			sum(DateDiff(Second,Case when M.StartTime > T.StartTime then M.StartTime else T.StartTime End,Case when M.EndTime < T.EndTime then M.EndTime else T.EndTime End)) as DownTime
			from #TempDownData M cross join #PlannedDownTimes T inner join DownCodeinformation D on D.DownID = M.DownID
			Where M.MachineID = T.Machine And
			((M.StartTime >= T.StartTime  AND M.EndTime <=T.EndTime) 
			OR ( M.StartTime < T.StartTime  AND M.EndTime <= T.EndTime AND M.EndTime > T.StartTime )
			OR ( M.StartTime >= T.StartTime   AND M.StartTime <T.EndTime AND M.EndTime > T.EndTime )
			OR ( M.StartTime < T.StartTime  AND M.EndTime > T.EndTime)) '
		Select @strSql=@strSql+@StrPLD_DownId
		Select @strSql=@strSql+' Group by M.RecordID
		) as t1 inner join #TempDownData on #TempDownData.RecordID = t1.RecordID'
		print @strSql
		exec(@strSql)


END







--Get the total down time by operator
UPDATE #TempDownData SET DownTime = isNull(t2.loss,0)
FROM
(SELECT OperatorID,SUM(Elapsedtime)loss from #TempDownData
group by  #TempDownData.OperatorID
) as t2 inner join #TempDownData on #TempDownData.OperatorID=t2.OperatorID
/*
--------------------Type 1  ---------------
UPDATE #TempDownData SET DownTime = isnull(DownTime,0) + isNull(t2.loss,0)
from
(select      mc,opr,
	sum(loadunload) loss
from autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
where (autodata.msttime>=@StartTime)
and (autodata.ndtime<=@EndTime)
and (autodata.datatype=2)
group by autodata.opr,mc
) as t2 inner join #TempDownData on t2.opr = #TempDownData.OprInterfaceid
-----------------------Type 2  -----------------
UPDATE #TempDownData SET DownTime = isnull(DownTime,0) + isNull(t2.loss,0)
from
(select      mc,opr,
	sum(DateDiff(second, @StartTime, ndtime)) loss
from autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
where (autodata.sttime<@StartTime)
and (autodata.ndtime>@StartTime)
and (autodata.ndtime<=@EndTime)
and (autodata.datatype=2)
group by autodata.opr,mc
) as t2 inner join #TempDownData on t2.opr = #TempDownData.OprInterfaceid
-----------------------Type 3  -----------------
UPDATE #TempDownData SET DownTime = isnull(DownTime,0) + isNull(t2.loss,0)
from
(select      mc,opr,
	sum(DateDiff(second, stTime, @Endtime)) loss
from autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
where (autodata.msttime>=@StartTime)
and (autodata.sttime<@EndTime)
and (autodata.ndtime>@EndTime)
and (autodata.datatype=2)
group by autodata.opr,mc
) as t2 inner join #TempDownData on t2.opr = #TempDownData.OprInterfaceid
-----------------------Type 4  -----------------
UPDATE #TempDownData SET DownTime = isnull(DownTime,0) + isNull(t2.loss,0)
from
(select mc,opr,
	sum(DateDiff(second, @StartTime, @Endtime)) loss
from autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
where autodata.msttime<@StartTime
and autodata.ndtime>@EndTime
and (autodata.datatype=2)
group by autodata.opr,mc
) as t2 inner join #TempDownData on t2.opr = #TempDownData.OprInterfaceid
------------------------------------------------
*/
declare @TimeFormat as nvarchar(50)
SELECT @TimeFormat = ''
SELECT @TimeFormat = (SELECT  ValueInText  FROM CockpitDefaults WHERE Parameter = 'TimeFormat')
if (ISNULL(@TimeFormat,'')) = ''
	SELECT @TimeFormat = 'ss'
SELECT @strsql = 'SELECT  StartTime,EndTime,MachineID,OperatorID,OperatorName,DownID,DownDescription,Downtime as DownNumeric,'
if (@TimeFormat = 'hh:mm:ss'or @TimeFormat = 'hh' or @TimeFormat = 'mm' or @TimeFormat = 'ss' )
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(ElapsedTime,''' + @TimeFormat + ''') as ElapsedTime, '
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(DownTime,''' + @TimeFormat + ''') as DownTime '
SELECT @strsql =  @strsql  + ' From #TempDownData order by MachineId,Endtime'
EXEC (@strsql)

--s_GetToolStockDetails '3-Jun-08','7-Jun-08','',''

END
