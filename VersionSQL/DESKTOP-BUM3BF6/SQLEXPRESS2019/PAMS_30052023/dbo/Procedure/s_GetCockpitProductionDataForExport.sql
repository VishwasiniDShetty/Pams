/****** Object:  Procedure [dbo].[s_GetCockpitProductionDataForExport]    Committed by VersionSQL https://www.versionsql.com ******/

/***************************************************************************************
s_GetCockpitProductionDataforexport '2015-12-03 06:00:00 AM','2015-12-04 06:00:00 AM',''
**************************************************************************************/
CREATE                 PROCEDURE [dbo].[s_GetCockpitProductionDataForExport]
	@StartTime datetime,
	@EndTime datetime,
	@MachineID nvarchar(50)='',
	@Plantid nvarchar(50)=''
AS
BEGIN


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

create table #TempCockpitProductionData
(
	SerialNo int IDENTITY (1, 1),
	Machineid nvarchar(50),
	ComponentID nvarchar(50),
	description nvarchar(100),
	OperationNo int,
	OperatorID nvarchar(50) ,
	OperatorName nvarchar(150) ,
	StartTime datetime,
	EndTime datetime,
	CycleTime int,
	MachineInterface nvarchar(50),
	CompInterface nvarchar(50),
	OpnInterface nvarchar(50),
	PDT int,
	LoadUnloadTime int,
	Remarks nvarchar(255),
	StdCycleTime int,
	StdMachiningTime int,
	id bigint,
	In_Cycle_DownTime int,
	partscount int
)

SELECT @strSql = @strSql + '
Insert into #TempCockpitProductionData(Machineid,ComponentID,description,OperationNo,OperatorID,OperatorName,StartTime,EndTime,CycleTime
,MachineInterface,CompInterface,OpnInterface,PDT,LoadUnloadTime,Remarks,StdCycleTime,StdMachiningTime,id,In_Cycle_DownTime,partscount)
SELECT
machineinformation.machineid as Machineame,
componentinformation.componentid AS ComponentID,
componentinformation.description AS description, 
componentoperationpricing.operationno AS OperationNo,
Isnull(employeeinformation.Employeeid,autodata.opr) AS OperatorID,
Isnull(employeeinformation.[name],''---'') AS OperatorName,
autodata.sttime AS StartTime,
autodata.ndtime AS EndTime,
autodata.cycletime AS CycleTime,
--mod 5
autodata.mc as MachineInterface,
autodata.comp as CompInterface,
autodata.opn as OpnInterface,
0 As PDT,
--mod 5
ISNULL(autodata.loadunload,0) AS LoadUnloadTime,
autodata.Remarks,
ISNULL(componentoperationpricing.cycletime,0)StdCycleTime,
ISNULL(componentoperationpricing.machiningtime,0)StdMachiningTime,
autodata.id,
CASE
WHEN   DATEDIFF(SECOND,autodata.sttime,autodata.ndtime)>autodata.cycletime
THEN DATEDIFF(SECOND,autodata.sttime,autodata.ndtime)-autodata.cycletime
ELSE  0
END  AS  In_Cycle_DownTime,
autodata.partscount as Partscount
FROM autodata 
INNER JOIN machineinformation ON autodata.mc = machineinformation.InterfaceID 
INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID 
INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID
AND componentinformation.componentid =  componentoperationpricing.componentid
and componentoperationpricing.machineid=machineinformation.machineid
INNER JOIN Plantmachine ON Plantmachine.machineid = machineinformation.machineid 
LEFT OUTER JOIN employeeinformation ON autodata.opr = employeeinformation.interfaceid 
WHERE
(autodata.sttime >= ''' + convert(nvarchar(20),@StartTime,120) + ''')
AND
(autodata.sttime < ''' + convert(nvarchar(20),@EndTime,120) + ''' )
AND (autodata.datatype = 1)'
SET @strSql =  @strSql + @strMachine + @strPlantID
SET @strSql =  @strSql + ' ORDER BY autodata.sttime'
EXEC(@strSql)


--ER0295 Modified From here.
If ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y' and
(SELECT ValueInInt From CockpitDefaults Where Parameter ='VDG-CycleDefinition')=2)
BEGIN

set ansi_warnings off

UPDATE #TempCockpitProductionData set  CycleTime=isnull(CycleTime,0) - isNull(TT.PPDT ,0),
LoadUnloadTime = isnull(LoadUnloadTime,0) - isnull(LD,0),
PDT=isnull(PDT,0) + isNull(TT.PPDT ,0) + isnull(LD,0)
	FROM(
		--Production Time in PDT
	Select A.mc,A.comp,A.Opn,A.sttime,A.ndtime,A.msttime,Sum
			(CASE
			WHEN A.sttime >= T.StartTime  AND A.ndtime <=T.EndTime  THEN (A.cycletime)
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
			SELECT M.Machineid,
			autodata.MC,autodata.comp,autodata.Opn,autodata.sttime,autodata.ndtime,autodata.Cycletime,
			autodata.msttime,autodata.loadunload
			FROM AutoData inner join Machineinformation M on M.interfaceid=Autodata.mc
			where autodata.DataType=1 And autodata.sttime >=@StartTime  AND autodata.sttime < @EndTime)A --DR0309 Swathi 21/Jun/12
			CROSS jOIN PlannedDownTimes T
			WHERE T.Machine=A.Machineid AND
			
			((A.msttime >= T.StartTime  AND A.ndtime <=T.EndTime)
			OR ( A.msttime < T.StartTime  AND A.ndtime <= T.EndTime AND A.ndtime > T.StartTime )
			OR ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime AND A.ndtime > T.EndTime )
			OR ( A.msttime < T.StartTime  AND A.ndtime > T.EndTime) )
			and T.PDTStatus = 1  
		group by A.mc,A.comp,A.Opn,A.sttime,A.ndtime,A.msttime
	)
	as TT INNER JOIN #TempCockpitProductionData ON TT.mc = #TempCockpitProductionData.MachineInterface
	and TT.comp = #TempCockpitProductionData.CompInterface
	and TT.opn = #TempCockpitProductionData.OPNInterface and tt.sttime=#TempCockpitProductionData.StartTime
	and #TempCockpitProductionData.EndTime=TT.ndtime

		--Handle intearction between ICD and PDT for type 1 production record for the selected time period.
		UPDATE  #TempCockpitProductionData set CycleTime =isnull(CycleTime,0) + isNull(T2.IPDT ,0) 	FROM	
		(
		Select T1.mc,T1.comp,T1.opn,T1.sttime,T1.ndtime,T1.cyclestart,T1.Cycleend,SUM(
			CASE 	
				When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1
				When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2
				When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3
				when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4
			END) as IPDT from
		(Select A.mc,A.comp,A.opn,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime,A.ndtime, A.datatype,
		 B.Sttime as CycleStart,B.ndtime as CycleEnd from autodata A inner join AutoData B on B.mc = A.mc
		 Where A.DataType=2 and B.DataType=1
			And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And
			(B.msttime >= @starttime AND B.ndtime <= @Endtime) and
			(B.sttime < A.sttime) AND (B.ndtime > A.ndtime) 
			
		 )as T1 inner join
		(select  machine,Case when starttime<@starttime then @starttime else starttime end as starttime, 
		case when endtime> @Endtime then @Endtime else endtime end as endtime from dbo.PlannedDownTimes 
		where PDTStatus = 1 and ((( StartTime >=@starttime) And ( EndTime <=@Endtime))
		or (StartTime < @starttime  and  EndTime <= @Endtime AND EndTime > @starttime)
		or (StartTime >= @starttime  AND StartTime <@Endtime AND EndTime > @Endtime)
		or (( StartTime <@starttime) And ( EndTime >@Endtime )) )
		)T
		on T1.machine=T.machine AND
		((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
		or (T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
		or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
		or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )group by T1.mc,T1.comp,T1.opn,T1.sttime,T1.ndtime,T1.cyclestart,T1.Cycleend
		)AS T2  INNER JOIN #TempCockpitProductionData ON T2.mc = #TempCockpitProductionData.MachineInterface
				and T2.comp = #TempCockpitProductionData.CompInterface
			and T2.opn = #TempCockpitProductionData.OPNInterface and t2.cyclestart=#TempCockpitProductionData.StartTime
		and #TempCockpitProductionData.EndTime=T2.Cycleend

set ansi_warnings ON
End

Declare @ICDSetting as nvarchar(50)
Select @ICDSetting = isnull(Valueintext,'N') From CockpitDefaults Where Parameter ='Current_Cycle_ICD_Records'
IF @ICDSetting = 'Y'
BEGIN
	insert into #TempCockpitProductionData exec [dbo].[s_GetInProcessCyclesforexport] @starttime,@Endtime,@Machineid,@plantid
END


Declare @VDGComp as nvarchar(50)
Select @VDGComp=''
Select @VDGComp=(Select ValueInText From CockpitDefaults WHERE Parameter ='VDG-ComponentSetting')

declare @TimeFormat as nvarchar(50)
SELECT @TimeFormat = ''
SELECT @TimeFormat = (SELECT  ValueInText  FROM CockpitDefaults WHERE Parameter = 'TimeFormat')
--if (ISNULL(@TimeFormat,'')) = ''
	SELECT @TimeFormat = N'ss'

SELECT @strsql=''

SELECT @strsql = 'SELECT Machineid as Machinename, '

If @VDGComp = 'In VDG Grid - ComponentID without Description' 
Begin
SELECT @strsql = @strsql +'Componentid as ComponentName, '
End

if @VDGComp = 'In VDG Grid - ComponentID with Description'
Begin
SELECT @strsql = @strsql +'Componentid + ''(''+ Description + '')'' as ''ComponentName'', '
End

SELECT @strsql = @strsql +'OperationNo,Operatorid,OperatorName,StartTime,EndTime, '
if (@TimeFormat = 'hh:mm:ss'or @TimeFormat = 'hh' or @TimeFormat = 'mm' or @TimeFormat = 'ss' )
BEGIN
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(CycleTime,''' + @TimeFormat + ''') as [Actual.CycleTime],'
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(LoadUnloadTime,''' + @TimeFormat + ''') as [A.LoadUnloadTime],'
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(In_Cycle_DownTime,''' + @TimeFormat + ''') as ICD,'
	--mod 5
	
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(PDT,''' + @TimeFormat + ''') as PDT,'
	--mod 5
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(LoadUnloadTime-(StdCycleTime-StdMachiningTime),''' + @TimeFormat + ''')AS LULoss,'
ENd
SELECT @strsql =  @strsql  + 'Remarks,id,CycleTime as SortCycleTime,LoadUnloadTime as SortLoadUnloadTime,Partscount FROM #TempCockpitProductionData order by SerialNo'
print @strsql
EXEC (@strsql)
END
