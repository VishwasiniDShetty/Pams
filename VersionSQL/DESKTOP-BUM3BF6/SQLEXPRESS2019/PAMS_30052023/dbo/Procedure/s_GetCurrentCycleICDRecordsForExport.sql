/****** Object:  Procedure [dbo].[s_GetCurrentCycleICDRecordsForExport]    Committed by VersionSQL https://www.versionsql.com ******/

--ER0370 - SwathiKS - 20/Nov/2013 :: Created New Procedure, Look at the last record in Autodata_Maxtime for the given machine. 
--If there are ICD records in autodata_ICD table with Start time > End time of Last record in autodata_Maxtime, then show those records.
--[dbo].[s_GetCurrentCycleICDRecordsforexport] '2015-12-03 06:00:00 AM','2015-12-04 06:00:00 AM','',''

CREATE                  PROCEDURE [dbo].[s_GetCurrentCycleICDRecordsForExport]
	@StartTime datetime,
	@EndTime datetime,
	@MachineID nvarchar(50)='',
	@Plantid nvarchar(50)=''
AS
BEGIN

create table #TempCockpitDownData
(
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

create table #autodata_ICD
(
	sttime datetime,
	ndtime datetime,
	mc nvarchar(50),
	dcode nvarchar(50),
	opr nvarchar(50),
	Loadunload int,
	[id] bigint
)

Declare @mc as nvarchar(50)
Declare @curtime as datetime
Select @mc=interfaceid from machineinformation where machineid=@machineid
Select @curtime=getdate()

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

Select @strsql = @strsql + '
Insert into #autodata_ICD
select sttime,ndtime,mc,dcode,opr,loadunload,id from Autodata_ICD
INNER JOIN machineinformation ON Autodata_ICD.mc = machineinformation.InterfaceID 
INNER JOIN Plantmachine ON Plantmachine.machineid = machineinformation.machineid 
inner join (Select machineid,MAX(endtime) as cursttime from Autodata_Maxtime group by machineid)T on Autodata_ICD.mc=T.machineid
where sttime>=T.cursttime and ndtime<= ''' + Convert(nvarchar(20),@Curtime,120) + ''''
SET @strSql =  @strSql + @strMachine + @strPlantId
exec(@strsql)


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


Select @strsql=''
select @strsql = @strsql + 'Insert into #Temp(Machineid,StartTime,EndTime,OperatorID,OperatorName,DownID,DownDescription,DownThreshold,DownTime,Remarks,[id],PDT)
SELECT machineinformation.machineid,
case when A.sttime<''' + Convert(nvarchar(20),@starttime,120) + ''' then ''' + Convert(nvarchar(20),@starttime,120) + ''' else A.sttime end AS StartTime,
case when A.ndtime>''' + Convert(nvarchar(20),@endtime,120) + ''' then ''' + Convert(nvarchar(20),@endtime,120) + ''' else A.ndtime end AS EndTime,
employeeinformation.Employeeid AS OperatorID,
employeeinformation.[Name]  AS OperatorName,
downcodeinformation.downid AS DownID,
downcodeinformation.downdescription as [DownDescription],
CASE
WHEN downcodeinformation.AvailEffy=1 and downcodeinformation.Threshold>0 THEN downcodeinformation.Threshold
ELSE 0 END AS [DownThreshold],
case
When (A.sttime >= ''' + Convert(nvarchar(20),@starttime,120) + ''' AND A.ndtime <= ''' + Convert(nvarchar(20),@endtime,120) + ''' ) THEN A.loadunload
WHEN ( A.sttime < ''' + Convert(nvarchar(20),@starttime,120) + ''' AND A.ndtime <= ''' + Convert(nvarchar(20),@endtime,120) + ''' AND A.ndtime > ''' + Convert(nvarchar(20),@starttime,120) + ''' ) THEN DateDiff(second, ''' + Convert(nvarchar(20),@starttime,120) + ''', A.ndtime)
WHEN ( A.sttime >= ''' + Convert(nvarchar(20),@starttime,120) + ''' AND A.sttime < ''' + Convert(nvarchar(20),@endtime,120) + ''' AND A.ndtime > ''' + Convert(nvarchar(20),@endtime,120) + ''' ) THEN  DateDiff(second, A.stTime, ''' + Convert(nvarchar(20),@endtime,120) + ''')
ELSE
DateDiff(second, ''' + Convert(nvarchar(20),@starttime,120) + ''', ''' + Convert(nvarchar(20),@endtime,120) + ''')END AS DownTime,
''Current Cycle ICD Record'' as Remarks,
A.id,
0 as PDT 
FROM  #autodata_ICD A 
INNER JOIN machineinformation ON A.mc = machineinformation.InterfaceID 
INNER JOIN downcodeinformation ON A.dcode = downcodeinformation.interfaceid 
INNER JOIN employeeinformation ON A.opr = employeeinformation.interfaceid
INNER JOIN Plantmachine ON Plantmachine.machineid = machineinformation.machineid 
WHERE 
(
(A.sttime >= ''' + Convert(nvarchar(20),@starttime,120) + '''  AND A.ndtime <=''' + Convert(nvarchar(20),@endtime,120) + ''')
OR ( A.sttime < ''' + Convert(nvarchar(20),@starttime,120) + '''  AND A.ndtime <= ''' + Convert(nvarchar(20),@endtime,120) + ''' AND A.ndtime > ''' + Convert(nvarchar(20),@starttime,120) + ''' )
OR ( A.sttime >= ''' + Convert(nvarchar(20),@starttime,120) + '''   AND A.sttime <''' + Convert(nvarchar(20),@endtime,120) + ''' AND A.ndtime > ''' + Convert(nvarchar(20),@endtime,120) + ''' )
OR ( A.sttime < ''' + Convert(nvarchar(20),@starttime,120) + '''  AND A.ndtime > ''' + Convert(nvarchar(20),@endtime,120) + ''')
)'
SET @strSql =  @strSql + @strMachine + @strPlantId
SET @strSql =  @strSql + ' ORDER BY A.ndtime'
exec(@Strsql)

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
BEGIN
update #Temp set DownTime = isnull(Downtime,0)-isnull(TT.plannedDT,0), PDT=isnull(TT.plannedDT,0)
	from
(
	Select A.machineid,A.StartTime,A.EndTime,			
			sum(case
			WHEN A.StartTime >= T.StartTime  AND A.EndTime <=T.EndTime  THEN A.DownTime
			WHEN ( A.StartTime < T.StartTime  AND A.EndTime <= T.EndTime  AND A.EndTime > T.StartTime ) THEN DateDiff(second,T.StartTime,A.EndTime)
			WHEN ( A.StartTime >= T.StartTime   AND A.StartTime <T.EndTime  AND A.EndTime > T.EndTime  ) THEN DateDiff(second,A.StartTime,T.EndTime )
			WHEN ( A.StartTime < T.StartTime  AND A.EndTime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END) as plannedDT
	From #Temp A CROSS jOIN PlannedDownTimes T
			WHERE  T.machine=A.Machineid  and pdtstatus=1 and 
			((A.StartTime >= T.StartTime  AND A.EndTime <=T.EndTime)
			OR ( A.StartTime < T.StartTime  AND A.EndTime <= T.EndTime AND A.EndTime > T.StartTime )
			OR ( A.StartTime >= T.StartTime   AND A.StartTime <T.EndTime AND A.EndTime > T.EndTime )
			OR ( A.StartTime < T.StartTime  AND A.EndTime > T.EndTime))
			group by A.StartTime,A.EndTime,a.Machineid
)TT
INNER JOIN #Temp ON TT.StartTime=#Temp.StartTime and #Temp.EndTime=TT.EndTime and #Temp.Machineid=TT.Machineid
END


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
) Select 	Machineid,
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
	PDT from #temp order by Machineid,starttime,endtime

SELECT * From #TempCockpitDownData 

END
