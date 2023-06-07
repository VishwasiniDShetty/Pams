/****** Object:  Procedure [dbo].[s_GetCockpitDownGraphTimeScale]    Committed by VersionSQL https://www.versionsql.com ******/

/******************************************************************************************
 mod 1 :- ER0210 By KarthikG Introduce PDT on 5150. Handle PDT at Machine Level. 
--s_GetCockpitDownGraphtimescale '2010-06-15 08:00:00.000 AM','2010-06-15 03:00:00.000 PM','MCV 600'
ER0295 - SnehaK - 02/Jun/2011 :: To Apply PDT For Loadunloadtime.
DR0292 - SwathiKS - 02/Sep/2011 :: To Handle 'Subscript Out of range Error' in VDG Cockpit.
DR0292 - SwathiKS - 26/Aug/2011 :: To Avoid Negative Downtime in SmartCockpit->VDG.
ER0303 - SwathiKS - 21/Sep/2011 :: To Change Output For Report,WithPDT and Without PDT.
s_GetCockpitDownGraphtimescale '2011-07-02' , '2011-07-03','IN2101-ACE1'
********************************************************************************************/
CREATE   PROCEDURE [dbo].[s_GetCockpitDownGraphTimeScale]
	@StartTime datetime,
	@EndTime datetime,
	@MachineID nvarchar(50)
	
AS
BEGIN
CREATE TABLE #Data
(
	sttime datetime,
	ndtime datetime, --ER0295 Added
	Machineid nvarchar(20), --ER0295 Added
	LoadUnloadTime int,
	DataType smallint,
	Dcode NvarChar(10),
	DownID NVarChar(50),
	loss decimal(18,2),
	PlannedDT Int
	
)

/************ ER0295 from here commented
-- 05/14/2004 satyendra Change in time comparison
--INSERT INTO #Data(sttime, loadunloadtime, datatype,Dcode,DownID,loss )
--SELECT     sttime as Time, autodata.loadunload AS LoadUnloadTime  , autodata.datatype,autodata.Dcode,DownCodeInformation.DownID,0
--FROM  autodata
--	INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID
--	INNER JOIN DownCodeInformation ON autodata.Dcode=DownCodeInformation.InterfaceID
--WHERE
--	(machineinformation.machineid = @MachineID)  AND
--	((autodata.sttime >= @StartTime  AND autodata.ndtime <=@EndTime)
--	OR ( autodata.sttime < @StartTime  AND autodata.ndtime <= @EndTime AND autodata.ndtime > @StartTime )
--	OR ( autodata.sttime >= @StartTime   AND autodata.sttime <@EndTime AND autodata.ndtime > @EndTime )
--	OR ( autodata.sttime < @StartTime  AND autodata.ndtime > @EndTime))
--ORDER BY autodata.id
--ER0295 till here commented
--mxk changed 'loadunloadtime to Downtime
ER0295 Commented Till Here. **************/

---ER0295 Modified From here.
INSERT INTO #Data(sttime,ndtime, loadunloadtime, datatype,Dcode,DownID,loss,Machineid )
SELECT     
--DR0292 From here.
--sttime as Time, ndtime, 
case when sttime<@starttime then @starttime else sttime end as Time, 
case when ndtime>@endtime then @endtime else ndtime end,
--DR0292 Till here.
case 
When (autodata.sttime >= @StartTime AND autodata.ndtime <= @EndTime ) THEN autodata.loadunload
WHEN ( autodata.sttime < @StartTime AND autodata.ndtime <= @EndTime AND autodata.ndtime > @StartTime ) THEN DateDiff(second, @StartTime, autodata.ndtime)
WHEN ( autodata.sttime >= @StartTime AND autodata.sttime < @EndTime AND autodata.ndtime > @EndTime ) THEN  DateDiff(second, autodata.stTime, @EndTime)
ELSE
DateDiff(second, @StartTime, @EndTime)END AS LoadUnloadTime, 
 autodata.datatype,autodata.Dcode,DownCodeInformation.DownID,0,machineinformation.Machineid
FROM  autodata
	INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID
	INNER JOIN DownCodeInformation ON autodata.Dcode=DownCodeInformation.InterfaceID
  	inner join Employeeinformation E on autodata.opr=E.interfaceid
WHERE
	(machineinformation.machineid = @MachineID)  AND datatype=2 and
	((autodata.sttime >= @StartTime  AND autodata.ndtime <=@EndTime)
	OR ( autodata.sttime < @StartTime  AND autodata.ndtime <= @EndTime AND autodata.ndtime > @StartTime )
	OR ( autodata.sttime >= @StartTime   AND autodata.sttime <@EndTime AND autodata.ndtime > @EndTime )
	OR ( autodata.sttime < @StartTime  AND autodata.ndtime > @EndTime))
ORDER BY autodata.id
--ER0295 Modofied Till here.

declare @TimeFormat as nvarchar(50)
SELECT @TimeFormat = 'ss'
SELECT @TimeFormat = (SELECT isnull(ValueInText,'ss')  FROM CockpitDefaults WHERE Parameter = 'TimeFormat')
if @TimeFormat = 'hh:mm:ss'
begin
	SELECT @TimeFormat = 'ss'
end
print @TimeFormat


UPDATE #Data SET loadunloadtime = 0 where datatype = 1 
--Revenue loss SJ
update #Data set loss= isnull(
(select mchrrate =
CASE @TimeFormat
WHEN 'hh' THEN mchrrate * (#Data.loadunloadtime)
WHEN 'mm' THEN mchrrate * (#Data.loadunloadtime)/60
WHEN 'ss' THEN mchrrate * (#Data.loadunloadtime)/3600
WHEN 'hh:mm:ss' THEN mchrrate *( #Data.loadunloadtime)/3600
ELSE 0
END
from machineinformation
where machineid=@MachineID),0)
where datatype=2

--mod 1
/******************    ER0295 commented From Here.
----If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
----BEGIN
----	Insert Into #Data(sttime, loadunloadtime, datatype,loss,PlannedDT)
----	SELECT
----	StartTime,0,2,0,
----	CASE
----	WHEN (StartTime >= @StartTime  AND EndTime <=@EndTime)  THEN DateDiff(second,StartTime,EndTime)
----	WHEN ( StartTime < @StartTime  AND EndTime <= @EndTime AND EndTime > @StartTime ) THEN DateDiff(second,@StartTime,EndTime)
----	WHEN ( StartTime >= @StartTime   AND StartTime <@EndTime AND EndTime > @EndTime ) THEN DateDiff(second,StartTime,@EndTime)
----	ELSE DateDiff(second,@StartTime,@EndTime)
----	END
----	From PlannedDownTimes Where PDTstatus = 1 and machine = @MachineID and
----	(( StartTime >= @StartTime AND EndTime   <= @EndTime)
----	OR ( StartTime <  @StartTime AND EndTime   <= @EndTime AND EndTime > @StartTime )
----	OR ( StartTime >= @StartTime AND StartTime <  @EndTime AND EndTime > @EndTime )
----	OR ( StartTime <  @StartTime AND EndTime   >  @EndTime) )
----End 
--mod 1
********************** ER0295 till here Commented *********************/




--ER0295 Modified from here
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
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
	From #data  A

			CROSS jOIN PlannedDownTimes T
			WHERE T.machine=@machineid  and pdtstatus=1 and ---datatype=2 and
			((A.sttime >= T.StartTime  AND A.ndtime <=T.EndTime)
			OR ( A.sttime < T.StartTime  AND A.ndtime <= T.EndTime AND A.ndtime > T.StartTime )
			OR ( A.sttime >= T.StartTime   AND A.sttime <T.EndTime AND A.ndtime > T.EndTime )
			OR ( A.sttime < T.StartTime  AND A.ndtime > T.EndTime)) 
			group by A.sttime,A.ndtime
	 )TT 
INNER JOIN #data ON TT.sttime=#data.StTime and #data.ndTime=TT.ndtime

END
---ER0295 Modified till here

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y' --ER0303 Added Line
BEGIN		--ER0303 Added Line
select
sttime, --DR0292 Added Output Parameter
convert(decimal (18, 2),dbo.f_FormatTime(loadunloadtime,@TimeFormat)) as DownTime,
CONVERT(decimal (18, 2),dbo.f_FormatTime(PlannedDT ,@TimeFormat)) AS PDT,
loss
FROM #Data where datatype =2 ORDER BY sttime --DownID
END  --ER0303 Added Line

--ER0303 Added From Here.
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y'
BEGIN
select
sttime, --DR0292 Added Output Parameter
convert(decimal (18, 2),dbo.f_FormatTime(loadunloadtime,@TimeFormat)) as DownTime,
loss
FROM #Data where datatype =2 ORDER BY sttime --DownID
END
--ER0303 Added Till Here.


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
