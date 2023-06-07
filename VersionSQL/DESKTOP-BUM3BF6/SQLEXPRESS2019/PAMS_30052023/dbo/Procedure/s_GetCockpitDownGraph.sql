/****** Object:  Procedure [dbo].[s_GetCockpitDownGraph]    Committed by VersionSQL https://www.versionsql.com ******/

/***************************************************************************************************
Altered by Sangeeta Kallur on 07-Apr-2006
To get all type of records :- Type-1,Type-2,Type-3,Type-4
Altered By Sangeeta Kallur on 19-June-2006
To Get the DownID
mod 1:By Mrudula M. Rao on 30-jan-2010.ER0210 Introduce PDT on 5150. 1) Handle PDT at Machine Level.
mod 2 :- ER0181 By Mrudula M. Rao on 30-jan-2010 .2) Modify all the procedures accordingly. Qualify machine wherever we are making use of component and opeartion no.	
	Note:- No CO combination found
mod 3 :- ER0182 By  Mrudula M. Rao on 30-jan-2010 . Modify all the procedures to support unicode characters. Qualify with leading N.
ER0295 - SwathiKS - 28/Jun/2011 :: To Apply PDT For LoadunloadTime.
DR0292 - SwathiKS - 26/Aug/2011 :: To Avoid Negative Downtime in SmartCockpit->VDG.
ER0303 - SwathiKS - 21/Sep/2011 :: To Change Output For Report,WithPDT and Without PDT.
ER0370 - SwathiKS - 14/Nov/2013 :: a> To include DownThreshold.
b> To Show Current Cycle ICD Records Based on Setting in Cockpitdefaults Table, 
If Setting = "Y" then Calling  Procedure [dbo].[s_GetCurrentCycleICDRecords].
NR0097 - SwathiKS - 17/dec/2013 :: Ace - While Accounting DownThreshold, To apply Threshold from Componentoperationprcing table for the Downs with 
"PickFomCO = 1" else apply threshold from Downcodeinformation table eith "Availeffy=1" and "PickFomCO <> 1" .
ER0402 - SwathiKS - 01/Jan/2015 :: To Show Operators which does not have Master entry in Down Grid.
DR0365 - SwathiKS - 06/Aug/2015 :: To handle error String or binary data would be truncated.
--s_GetCockpitDownGraph '2014-03-28 07:00:00' , '2014-03-30 15:30:00','DOOSAN-5'
******************************************************************************************************/

CREATE PROCEDURE [dbo].[s_GetCockpitDownGraph]
	@StartTime datetime,
	@EndTime datetime,
	@MachineID nvarchar(50)
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

CREATE TABLE #Data
(
	sttime datetime,
	ndtime datetime, --ER0295 Added
	LoadUnloadTime int,
	DataType smallint,
	--Dcode NvarChar(10), --DR0365
	Dcode NvarChar(50), --DR0365
	DownID NVarChar(50)
	---mod 1: to store Planned downtime
	,PlannedDT Int,
	DownThreshold int --ER0370
	--mod 1	
)
	
-- 05/14/2004 satyendra Change in time comparison
/* ER0295 Commented From here.
INSERT INTO #Data(sttime, ndtime,loadunloadtime, datatype,Dcode,DownID)
SELECT     sttime as Time, ndtime,autodata.loadunload AS LoadUnloadTime  , autodata.datatype,autodata.Dcode,DownCodeInformation.DownID
FROM  autodata
	INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID
	INNER JOIN DownCodeInformation ON autodata.Dcode=DownCodeInformation.InterfaceID
	inner join Employeeinformation E on autodata.opr=E.interfaceid
WHERE
	(machineinformation.machineid = N''+@MachineID+'' )  AND datatype=2 and
	((autodata.sttime >= @StartTime  AND autodata.ndtime <=@EndTime)
	OR ( autodata.sttime < @StartTime  AND autodata.ndtime <= @EndTime AND autodata.ndtime > @StartTime )
	OR ( autodata.sttime >= @StartTime   AND autodata.sttime <@EndTime AND autodata.ndtime > @EndTime )
	OR ( autodata.sttime < @StartTime  AND autodata.ndtime > @EndTime))
	ORDER BY autodata.id
ER0295 Commented Till here. */
--ER0295 From Here.
INSERT INTO #Data(sttime,ndtime,loadunloadtime, datatype,Dcode,DownID,PlannedDT,DownThreshold) --ER0370
SELECT
--DR0292 From here.
--sttime as Time, ndtime,
case when sttime<@starttime then @starttime else sttime end as Time,
case when ndtime>@endtime then @endtime else ndtime end,
--DR0292 Till here.
case
When (autodata.sttime >= @StartTime AND autodata.ndtime <= @EndTime ) THEN loadunload
WHEN ( autodata.sttime < @StartTime AND autodata.ndtime <= @EndTime AND autodata.ndtime > @StartTime ) THEN DateDiff(second, @StartTime, ndtime)
WHEN ( autodata.sttime >= @StartTime AND autodata.sttime < @EndTime AND autodata.ndtime > @EndTime ) THEN  DateDiff(second, stTime, @EndTime)
ELSE
DateDiff(second, @StartTime, @EndTime)END AS LoadUnloadTime,
autodata.datatype,autodata.Dcode,DownCodeInformation.DownID,0
--ER0370 From here
,CASE
--WHEN downcodeinformation.AvailEffy=1 and downcodeinformation.Threshold>0 THEN downcodeinformation.Threshold --NR0097
WHEN downcodeinformation.AvailEffy=1 AND downcodeinformation.ThresholdfromCO <>1 and downcodeinformation.Threshold>0 THEN downcodeinformation.Threshold --NR0097
ELSE 0 END AS [DownThreshold]
--ER0370 Till here
FROM  autodata
	INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID
	INNER JOIN DownCodeInformation ON autodata.Dcode=DownCodeInformation.InterfaceID
	--inner join Employeeinformation E on autodata.opr=E.interfaceid --ER0402
	Left Outer join Employeeinformation E on autodata.opr=E.interfaceid --ER0402
WHERE
	(machineinformation.machineid = N''+@MachineID+'' )  AND datatype=2 and
	((autodata.sttime >= @StartTime  AND autodata.ndtime <=@EndTime)
	OR ( autodata.sttime < @StartTime  AND autodata.ndtime <= @EndTime AND autodata.ndtime > @StartTime )
	OR ( autodata.sttime >= @StartTime   AND autodata.sttime <@EndTime AND autodata.ndtime > @EndTime )
	OR ( autodata.sttime < @StartTime  AND autodata.ndtime > @EndTime))
	ORDER BY autodata.id
--ER0295 Till here.

--------------------------- NR0097 Added From Here ----------------------------------
update #Data set DownThreshold = isnull(DownThreshold,0) + isnull(T1.DThreshold,0)  from
(Select autodata.id,case when sttime<@starttime then @starttime else sttime end as sttime,
case when ndtime>@endtime then @endtime else ndtime end as ndtime,isnull(CO.Stdsetuptime,0)AS DThreshold from autodata
inner join machineinformation M on autodata.mc = M.interfaceid
inner join downcodeinformation D on autodata.dcode=D.interfaceid
--INNER JOIN employeeinformation ON autodata.opr = employeeinformation.interfaceid --ER0402
LEFT OUTER JOIN employeeinformation ON autodata.opr = employeeinformation.interfaceid --ER0402
left outer join componentinformation CI on autodata.comp = CI.interfaceid
left outer join componentoperationpricing CO on autodata.opn =  CO.interfaceid and CI.componentid = CO.componentid and CO.machineid = M.machineid
where (M.machineid = N''+@MachineID+'' ) and autodata.datatype=2 and D.ThresholdfromCO = 1
And
((autodata.sttime>=@starttime and autodata.ndtime<=@endtime) or
 (autodata.sttime<@starttime and autodata.ndtime>@starttime and autodata.ndtime<=@endtime)or
 (autodata.sttime>=@starttime and autodata.sttime<@endtime and autodata.ndtime>@endtime)or
 (autodata.sttime<@starttime and autodata.ndtime>@endtime))
)T1 inner join #Data on T1.sttime=#Data.sttime and T1.ndtime=#Data.ndtime
-------------------------- NR0097 Added Till Here --------------------------------------

--mod 1: Get the planned down times defined for the machine
/* ER0295 Commented From here.
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
BEGIN 	Insert Into #Data(sttime,PlannedDT,DataType,loadunloadtime)
	SELECT StartTime,
	sum(CASE
	WHEN (StartTime >= @StartTime  AND EndTime <=@EndTime)  THEN DateDiff(second,StartTime,EndTime)
	WHEN ( StartTime < @StartTime  AND EndTime <= @EndTime AND EndTime > @StartTime ) THEN DateDiff(second,@StartTime,EndTime)
	WHEN ( StartTime >= @StartTime   AND StartTime <@EndTime AND EndTime > @EndTime ) THEN DateDiff(second,StartTime,@EndTime)
	ELSE DateDiff(second,@StartTime,@EndTime)
	END) as PlannedDT,2,0
	From PlannedDownTimes  Where(
		   (StartTime >= @StartTime  AND EndTime <=@EndTime)
		OR ( StartTime < @StartTime  AND EndTime <= @EndTime AND EndTime > @StartTime )
		OR ( StartTime >= @StartTime   AND StartTime <@EndTime AND EndTime > @EndTime )
		OR ( StartTime < @StartTime  AND EndTime > @EndTime) ) and pdtstatus=1
		and PlannedDownTimes.Machine=N''+@MachineID+''
		group by starttime
END
--mod 1
ER0295 Commented Till Here. */
--ER0295 From Here.
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
BEGIN
update #data set LoadUnloadTime = isnull(Loadunloadtime,0)-isnull(TT.plannedDT,0), plannedDT=isnull(TT.plannedDT,0)
	from
(
	Select A.sttime,A.ndtime,			
			sum(case
			WHEN A.sttime >= T.StartTime  AND A.ndtime <=T.EndTime  THEN A.LoadUnloadTime
			WHEN ( A.sttime < T.StartTime  AND A.ndtime <= T.EndTime  AND A.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,A.ndtime)
			WHEN ( A.sttime >= T.StartTime   AND A.sttime <T.EndTime  AND A.ndtime > T.EndTime  ) THEN DateDiff(second,A.sttime,T.EndTime )
			WHEN ( A.sttime < T.StartTime  AND A.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END) as plannedDT
	From #data A CROSS jOIN PlannedDownTimes T
			WHERE  T.machine=@machineid  and pdtstatus=1 and
			((A.sttime >= T.StartTime  AND A.ndtime <=T.EndTime)
			OR ( A.sttime < T.StartTime  AND A.ndtime <= T.EndTime AND A.ndtime > T.StartTime )
			OR ( A.sttime >= T.StartTime   AND A.sttime <T.EndTime AND A.ndtime > T.EndTime )
			OR ( A.sttime < T.StartTime  AND A.ndtime > T.EndTime))
			group by A.sttime,A.ndtime
)TT
INNER JOIN #data ON TT.sttime=#data.StTime and #data.ndTime=TT.ndtime
END
--ER0295 Till Here.
UPDATE #Data SET loadunloadtime = 0 where datatype = 1
--mxk changed 'loadunloadtime to Downtime

--ER0370 From Here
create table #TempCockpitDownData
(
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

Declare @ICDSetting as nvarchar(50)
Select @ICDSetting = isnull(Valueintext,'N') From CockpitDefaults Where Parameter ='Current_Cycle_ICD_Records'
IF @ICDSetting = 'Y'
BEGIN
	insert into #TempCockpitDownData exec [dbo].[s_GetCurrentCycleICDRecords] @starttime,@Endtime,@Machineid
END

INSERT INTO #Data(sttime,ndtime,loadunloadtime, datatype,DownID,PlannedDT,DownThreshold) 
Select StartTime,EndTime,DownTime,'2',DownDescription,PDT,DownThreshold from #TempCockpitDownData
--ER0370 Till Here

declare @TimeFormat as nvarchar(50)
SELECT @TimeFormat = 'ss'
SELECT @TimeFormat = (SELECT isnull(ValueInText,'ss')  FROM CockpitDefaults WHERE Parameter = 'TimeFormat')
if @TimeFormat = 'hh:mm:ss'
begin
	SELECT @TimeFormat = 'ss'
end
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' --ER0303 Added
BEGIN	--ER0303 Added																				 -
	select
	convert(decimal (18, 2),dbo.f_FormatTime(loadunloadtime,@TimeFormat)) as DownTime
    ,convert(decimal (18, 2),dbo.f_FormatTime(DownThreshold,@TimeFormat)) AS DownThreshold  --ER0370 Added
	--mod 1
	,CONVERT(decimal (18, 2),dbo.f_FormatTime(PlannedDT ,@TimeFormat)) AS PDT
	---mod 1
	FROM #Data where datatype =2 ORDER BY sttime --DownID
END     --ER0303 Added
--ER0303 Added From Here.
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N'
BEGIN																					
	select
	convert(decimal (18, 2),dbo.f_FormatTime(loadunloadtime,@TimeFormat)) as DownTime
	,convert(decimal (18, 2),dbo.f_FormatTime(DownThreshold,@TimeFormat)) AS DownThreshold --ER0370 Added
	FROM #Data where datatype =2 ORDER BY sttime
END
--ER0303 Added Til Here.
/*
	select
	--DownID AS DownID, --Commented By Sangeeta Kallur to get the original OutPut
	loadunloadtime as DownTime
	FROM #Data where datatype =2
	ORDER BY DownID
*/
--        SELECT     sttime as Time, autodata.loadunload AS LoadUnloadTime
--        FROM         autodata INNER JOIN
--                    machineinformation ON autodata.mc = machineinformation.InterfaceID
--       WHERE
--            (autodata.ndtime > @StartTime )
--            AND
--            (autodata.ndtime <= @EndTime )
--            AND
--            (machineinformation.machineid = @MachineID)
--            AND
--            (autodata.datatype = 2)
--        ORDER BY autodata.id
END
