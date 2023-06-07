/****** Object:  Procedure [dbo].[s_GetOperatorDownData]    Committed by VersionSQL https://www.versionsql.com ******/

/*
Procedure altered by SSK on 07-Oct-2006 to Include Plant Concept
Note:Component and operation not qualified.So,ER0181 not done.
mod 1 :- ER0182 By Kusuma M.H on 10-Jun-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
mod 2:-for DR0217 by Mrudula M. Rao on 08-Oct-2009.Need to increase the length of the down description
ER0210 By Karthikg on 08/Feb/2010 :: Introduce PDT on 5150. Handle PDT at Machine Level. 
s_GetOperatorDownData '01-dec-2009','','MCV 400',''
*/
CREATE   PROCEDURE [dbo].[s_GetOperatorDownData]
	@Startdate datetime,
	@Operator nvarchar(50)= '',
	@MachineID nvarchar(50) = '',
	@PlantID nvarchar(50) = ''
AS
BEGIN
CREATE TABLE #TempDownData
	( StartTime Datetime,
	  EndTime Datetime,
	  machineid nvarchar(50),
	  OperatorID nvarchar(50),
	  OperatorName nvarchar(50),
	  DownID nvarchar(50),
	  ---mod 2:Increase the length of column
	  ---DownDescription nvarchar(50),
	  DownDescription nvarchar(100),
	  ---mod 2
	  DownTime float,
	  OpDowntime float,
	  RecordID bigint PRIMARY KEY
	 )
declare @strsql nvarchar (2000)
declare @stroperator nvarchar(255)
declare @starttime datetime
declare @endtime datetime
declare @strMachine nvarchar(255)
declare @strMPlant nvarchar(255)
--Get Logical day start and end
select @StartTime = dbo.f_GetLogicalDay(@StartDate,'start')
select @EndTime = dbo.f_GetLogicalDay(@StartDate,'end')
select @strsql = ''
select @strMachine = ''
select @stroperator = ''
select @strMPlant = ''
if isnull(@operator, '') <> ''
	begin
	---mod 1
--	select @stroperator = ' AND ( employeeinformation.employeeid = ''' + @Operator +''')'
	select @stroperator = ' AND ( employeeinformation.employeeid = N''' + @Operator +''')'
	---mod 1
	end
if isnull(@MachineId, '') <> ''
	begin
	---mod 1
--	select @strMachine = ' AND ( machineInformation.machineId = ''' + @MachineId + ''')'
	select @strMachine = ' AND ( machineInformation.machineId = N''' + @MachineId + ''')'
	---mod 1
	end
if isnull(@PlantID, '') <> ''
	begin
	---mod 1
--	select @strMPlant = ' AND ( PlantMachine.PlantId = ''' + @PlantID + ''')'
	select @strMPlant = ' AND ( PlantMachine.PlantId = N''' + @PlantID + ''')'
	---mod 1
	end
select @strsql = 'insert into #TempDownData (StartTime,EndTime,MachineID,OperatorID,OperatorName,DownID,DownDescription, DownTime, Opdowntime, RecordID)
select
autodata.sttime,autodata.ndtime,
machineinformation.machineid,employeeinformation.Employeeid,
employeeinformation.Name,downcodeinformation.downid,
downcodeinformation.downdescription,autodata.loadunload,
0,autodata.id FROM  autodata INNER JOIN
machineinformation ON autodata.mc = machineinformation.InterfaceID Left Outer Join
PlantMachine ON machineinformation.machineid=PlantMachine.machineid INNER JOIN
downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid INNER JOIN
employeeinformation ON autodata.opr = employeeinformation.interfaceid
WHERE (autodata.datatype = 2)'
select @strsql = @strsql + 'AND (autodata.sttime >= ''' + convert(nvarchar(20),@StartTime) + ''')'
select @strsql = @strsql + 'AND (autodata.ndtime <= ''' + convert(nvarchar(20),@EndTime) + ''')'
select @strsql = @strsql + @stroperator + @strMachine + @strMPlant
select @strsql = @strsql + 'ORDER BY autodata.ndtime'
exec(@strsql)


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
		Select @strSql='update #TempDownData set DownTime = isnull(#TempDownData.DownTime,0) - isNull(t1.DownTime ,0) from (
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
--ER0210

--Get the total down time by operator
update #TempDownData set OpDowntime = isnull(opdowntime,0) + isnull(t2.down,0)
from (select Operatorid,MachineId, sum(downtime) down
from #tempdowndata group by operatorid,MachineId)as t2 inner join #tempdowndata on
t2.operatorid = #tempdowndata.operatorid AND t2.MachineId = #tempdowndata.MachineId


--Format the downtime to be displayed based on user's choice in ViewDataGraph
declare @TimeFormat as nvarchar(50)
SELECT @TimeFormat = ''
SELECT @TimeFormat = (SELECT  ValueInText  FROM CockpitDefaults WHERE Parameter = 'TimeFormat')
if (ISNULL(@TimeFormat,'')) = ''
	SELECT @TimeFormat = 'ss'
SELECT @strsql = 'SELECT  StartTime,EndTime,MachineID,OperatorID,OperatorName,DownID,DownDescription,Downtime as DownNumeric,'
if (@TimeFormat = 'hh:mm:ss'or @TimeFormat = 'hh' or @TimeFormat = 'mm' or @TimeFormat = 'ss' )
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(DownTime,''' + @TimeFormat + ''') as DownTime, '
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(OpDownTime,''' + @TimeFormat + ''') as OpDownTime '
SELECT @strsql =  @strsql  + ' From #TempDownData order by MachineId,Endtime'
EXEC (@strsql)
END
