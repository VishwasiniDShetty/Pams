/****** Object:  Procedure [dbo].[s_GetCockpitDownDataForExport]    Committed by VersionSQL https://www.versionsql.com ******/

/*************************************************************************************
s_GetCockpitDownDataforexport '2015-12-03 06:00:00 AM','2015-12-04 06:00:00 AM',''
***************************************************************************************/
CREATE                  PROCEDURE [dbo].[s_GetCockpitDownDataForExport]
	@StartTime datetime,
	@EndTime datetime,
	@MachineID nvarchar(50)='',
	@Plantid nvarchar(50)=''
AS
BEGIN

create table #TempCockpitDownData
(
	SerialNO bigint IDENTITY (1, 1) NOT NULL,
	Machineid nvarchar(50),
	StartTime datetime,
	EndTime datetime,
	OperatorID nvarchar(50),
	OperatorName nvarchar(150),
	DownID nvarchar(50),
	DownDescription nvarchar(100),
	DownThreshold numeric(18) ,
	DownTime nvarchar(50) ,
	Remarks nvarchar(255),
	[id] bigint,
	PDT int 
)


create table #Temp
(
	SerialNO bigint IDENTITY (1, 1) NOT NULL,
	Machineid nvarchar(50),
	StartTime datetime,
	EndTime datetime,
	OperatorID nvarchar(50),
	OperatorName nvarchar(150),
	DownID nvarchar(50),
	DownDescription nvarchar(100),
	DownThreshold numeric(18) ,
	DownTime nvarchar(50) ,
	Remarks nvarchar(255),
	[id] bigint,
	PDT int 
)


Declare @strPlantID as nvarchar(255)
Declare @strSql as nvarchar(4000)
Declare @strMachine as nvarchar(255)

SELECT @strSql=''
SELECT @strMachine = ''
SELECT @strPlantID = ''

if isnull(@machineid,'')<> ''
begin
	SET @strMachine = ' AND MachineInformation.MachineID = N''' + @machineid + ''''
end

if isnull(@PlantID,'')<> ''
Begin
	SET @strPlantID = ' AND PlantMachine.PlantID = N''' + @PlantID + ''''
End

Select @strsql = @Strsql + '
Insert into #Temp(Machineid,StartTime,EndTime,OperatorID,OperatorName,DownID,DownDescription,DownThreshold,DownTime,Remarks,[id],PDT)
SELECT machineinformation.Machineid,
case when autodata.sttime< ''' + Convert(nvarchar(20),@starttime) + ''' then ''' + Convert(nvarchar(20),@starttime) + '''  else autodata.sttime end AS StartTime,
case when autodata.ndtime>''' + Convert(nvarchar(20),@endtime) + '''  then ''' + Convert(nvarchar(20),@endtime) + '''  else autodata.ndtime end AS EndTime,
Isnull(employeeinformation.Employeeid,autodata.opr) AS OperatorID,
Isnull(employeeinformation.[Name],''---'')  AS OperatorName,
downcodeinformation.downid AS DownID,
downcodeinformation.downdescription as [DownDescription],
CASE
WHEN downcodeinformation.AvailEffy=1 AND downcodeinformation.ThresholdfromCO <>1 AND downcodeinformation.Threshold>0 THEN downcodeinformation.Threshold --NR0097
ELSE 0 END AS [DownThreshold],
case
When (autodata.sttime >= ''' + Convert(nvarchar(20),@starttime) + '''  AND autodata.ndtime <= ''' + Convert(nvarchar(20),@EndTime) + '''  ) THEN loadunload
WHEN ( autodata.sttime < ''' + Convert(nvarchar(20),@starttime) + '''  AND autodata.ndtime <= ''' + Convert(nvarchar(20),@EndTime) + ''' AND autodata.ndtime > ''' + Convert(nvarchar(20),@starttime) + '''  ) THEN DateDiff(second, ''' + Convert(nvarchar(20),@starttime) + ''' , ndtime)
WHEN ( autodata.sttime >= ''' + Convert(nvarchar(20),@starttime) + '''  AND autodata.sttime < ''' + Convert(nvarchar(20),@EndTime) + ''' AND autodata.ndtime > ''' + Convert(nvarchar(20),@EndTime) + ''' ) THEN  DateDiff(second, stTime, ''' + Convert(nvarchar(20),@EndTime) + ''')
ELSE
DateDiff(second, ''' + Convert(nvarchar(20),@starttime) + ''' , ''' + Convert(nvarchar(20),@Endtime) + ''')END AS DownTime,
autodata.Remarks,
autodata.id,
0 as PDT
FROM autodata INNER JOIN
machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN
downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
LEFT OUTER JOIN employeeinformation ON autodata.opr = employeeinformation.interfaceid --ER0402
INNER JOIN Plantmachine ON Plantmachine.machineid = machineinformation.machineid 
WHERE autodata.datatype = 2 AND
(
(autodata.sttime >= ''' + Convert(nvarchar(20),@starttime) + '''  AND autodata.ndtime <=''' + Convert(nvarchar(20),@EndTime) + ''')
OR ( autodata.sttime < ''' + Convert(nvarchar(20),@starttime) + '''  AND autodata.ndtime <= ''' + Convert(nvarchar(20),@EndTime) + ''' AND autodata.ndtime > ''' + Convert(nvarchar(20),@starttime) + ''' )
OR ( autodata.sttime >= ''' + Convert(nvarchar(20),@starttime) + '''   AND autodata.sttime <''' + Convert(nvarchar(20),@EndTime) + ''' AND autodata.ndtime > ''' + Convert(nvarchar(20),@endtime) + ''' )
OR ( autodata.sttime < ''' + Convert(nvarchar(20),@starttime) + '''  AND autodata.ndtime > ''' + Convert(nvarchar(20),@EndTime) + ''')
)'
SET @strSql =  @strSql + @strMachine + @strPlantID
SET @strSql =  @strSql + 'ORDER BY autodata.ndtime'
Exec(@strsql)

--------------------------- NR0097 Added From Here ----------------------------------
update #Temp set [DownThreshold] = isnull([DownThreshold],0) + isnull(T1.DThreshold,0)  from
(Select autodata.id,isnull(CO.Stdsetuptime,0)AS DThreshold from autodata
inner join machineinformation M on autodata.mc = M.interfaceid
inner join downcodeinformation D on autodata.dcode=D.interfaceid
--INNER JOIN employeeinformation ON autodata.opr = employeeinformation.interfaceid --ER0402
left outer join  employeeinformation ON autodata.opr = employeeinformation.interfaceid --ER0402
left outer join componentinformation CI on autodata.comp = CI.interfaceid
left outer join componentoperationpricing CO on autodata.opn =  CO.interfaceid and CI.componentid = CO.componentid and CO.machineid = M.machineid
where M.machineid = @MachineID and autodata.datatype=2 and D.ThresholdfromCO = 1
And
((autodata.sttime>=@starttime and autodata.ndtime<=@endtime) or
 (autodata.sttime<@starttime and autodata.ndtime>@starttime and autodata.ndtime<=@endtime)or
 (autodata.sttime>=@starttime and autodata.sttime<@endtime and autodata.ndtime>@endtime)or
 (autodata.sttime<@starttime and autodata.ndtime>@endtime))
)T1 inner join #Temp on T1.id=#Temp.id

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
BEGIN
update #Temp set DownTime = isnull(Downtime,0)-isnull(TT.plannedDT,0), PDT=isnull(TT.plannedDT,0)
	from
(
	Select A.StartTime,A.EndTime,A.Machineid,			
			sum(case
			WHEN A.StartTime >= T.StartTime  AND A.EndTime <=T.EndTime  THEN A.DownTime
			WHEN ( A.StartTime < T.StartTime  AND A.EndTime <= T.EndTime  AND A.EndTime > T.StartTime ) THEN DateDiff(second,T.StartTime,A.EndTime)
			WHEN ( A.StartTime >= T.StartTime   AND A.StartTime <T.EndTime  AND A.EndTime > T.EndTime  ) THEN DateDiff(second,A.StartTime,T.EndTime )
			WHEN ( A.StartTime < T.StartTime  AND A.EndTime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END) as plannedDT
	From #Temp A CROSS jOIN PlannedDownTimes T
			WHERE  T.machine=A.Machineid  and pdtstatus=1 and --datatype=2 and
			((A.StartTime >= T.StartTime  AND A.EndTime <=T.EndTime)
			OR ( A.StartTime < T.StartTime  AND A.EndTime <= T.EndTime AND A.EndTime > T.StartTime )
			OR ( A.StartTime >= T.StartTime   AND A.StartTime <T.EndTime AND A.EndTime > T.EndTime )
			OR ( A.StartTime < T.StartTime  AND A.EndTime > T.EndTime))
			group by A.StartTime,A.EndTime,A.Machineid
)TT
INNER JOIN #Temp ON TT.StartTime=#Temp.StartTime and #Temp.EndTime=TT.EndTime and #temp.machineid=TT.Machineid
END


SET IDENTITY_INSERT #TempCockpitDownData Off
insert into #TempCockpitDownData
(
	Machineid,
	StartTime,
	EndTime,
	OperatorID,
	OperatorName,
	DownID,
	DownDescription,
	DownThreshold,
	DownTime,
	Remarks,
	[id],
	PDT 
) Select Machineid,
	StartTime,
	EndTime,
	OperatorID,
	OperatorName,
	DownID,
	DownDescription,
	DownThreshold,
	DownTime,
	Remarks,
	[id],
	PDT  from #temp order by Machineid,starttime,endtime


--ER0370 From Here
Declare @ICDSetting as nvarchar(50)
Select @ICDSetting = isnull(Valueintext,'N') From CockpitDefaults Where Parameter ='Current_Cycle_ICD_Records'
IF @ICDSetting = 'Y'
BEGIN
	insert into #TempCockpitDownData exec [dbo].[s_GetCurrentCycleICDRecordsForExport] @starttime,@Endtime,@Machineid,@Plantid
END
--ER0370 Till Here

declare @TimeFormat as nvarchar(50)
SELECT @TimeFormat = ''
SELECT @TimeFormat = (SELECT  ValueInText  FROM CockpitDefaults WHERE Parameter = 'TimeFormat')
--if (ISNULL(@TimeFormat,'')) = ''
SELECT @TimeFormat = 'ss'

SELECT SerialNO,Machineid as [Machine Name],
StartTime,
EndTime,
OperatorID,
OperatorName,
DownID as DownReason,
DownDescription,
dbo.f_FormatTime(DownTime, @TimeFormat  ) as DownTime ,
dbo.f_FormatTime(DownThreshold,@TimeFormat) AS DownThreshold,
CASE
WHEN (DownTime > DownThreshold AND DownThreshold > 0) THEN dbo.f_FormatTime(abs(DownTime-DownThreshold),@TimeFormat)
ELSE '0' END AS MLE,
Remarks,id,DownTime as [Actual.Time(Sec)] ,
PDT 
From #TempCockpitDownData
order by SerialNo

END
