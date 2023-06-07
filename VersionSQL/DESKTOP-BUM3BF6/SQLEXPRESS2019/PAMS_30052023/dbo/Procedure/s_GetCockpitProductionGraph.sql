/****** Object:  Procedure [dbo].[s_GetCockpitProductionGraph]    Committed by VersionSQL https://www.versionsql.com ******/

/****************************************************************
Procedure Changed By MRao : New column added in autodata 'PartsCount'
gives number of components in the cycle .If Pallet ->gives the 'pallet count' else 'one'.
mod 1 :- for DR0114 by Mrudula. To consider seconds part of time stamp during calculations
mod 2 :- ER0181 By Kusuma M.H on 11-May-2009.2) Modify all the procedures accordingly. Qualify machine wherever we are making use of component and opeartion no.
mod 3 :- ER0182 By Kusuma M.H on 11-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
mod 4 :- ER0210 By KarthikG Introduce PDT on 5150. Handle PDT at Machine Level.
mod 5 :- ER0253 by Karthick R on 28-sep-2010.To suppress PDT details while displaying production graph
mod 6: - ER0266 by Karthick R on 20-Oct-2010.To Apply PDT for cycle time calculation
ER0295 - KarthickR/SwathiKS - 30/Jun/2011 :: To Apply PDT For ActLoadunload.
ER0303 - SwathiKS - 21/Sep/2011 :: a> To Change PLD Column To PDT.
		                   b> To Change Output For Report,WithPDT and Without PDT. 
DR0297 - SwathiKS - 01/Oct/2011 :: To Fix Error 'Operation is Not allowed When the object is closed.
						 Application-Defined or Object-Defined Error.
DR0309 - SwathiKS - 21/Jun/2012 :: To Handle ICD + PDT Interaction during Final Update and PDTStatus=1.(Cycletime was Negative)
ER0384 - SwathiKS - 01/Jul/2014 :: Performance Optimization while handling interaction between ICD and PDT for Type1.
ER0394 - SwathiKS - 22/Sep/2014 :: To Show In Progress Records Based on Setting in Cockpitdefaults Table, 
If Setting = "Y" then Calling  Procedure [dbo].[s_GetInProcessCycles].
DR0349 - SwathiKS - 29/Jan/2015 :: Ace - Observerd Negative Values while handling ICD-PDT Interaction. 
DR0370 - SwathiKS - 24/Dec/2015 :: To handle Sorting of Records in the Final output i.e Sorting by sttime of records.
ER0450 - SwathiKS - 10/Oct/2017 :: To handle Partscount Mismatch in VDG production grid.

s_GetCockpitProductionGraph '2015-01-30 06:00:00 AM','2015-01-31 06:00:00 AM','ACE VTL-02','ASLT'
****************************************************************/
CREATE PROCEDURE [dbo].[s_GetCockpitProductionGraph]
@StartTime datetime,
@EndTime datetime,
@MachineID nvarchar(50),
@Type nvarchar(10)='ALL' --'ALL','ASLT','ASMT','TMT'
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

declare @strsql nvarchar(4000)
--Intoduced @Type Variable for Different viewes of production Graph
-- Dec 4 2004 S. jaiswal
declare @TimeFormat as nvarchar(50)
SELECT @TimeFormat = 'ss'
SELECT @TimeFormat = (SELECT isnull(ValueInText,'ss')  FROM CockpitDefaults WHERE Parameter = 'TimeFormat')
if @TimeFormat = 'hh:mm:ss'
begin
	SELECT @TimeFormat = 'ss'
end
--mod 5
/*
--mod 4
----------------calculation of PLD------------------------------------------------
CREATE TABLE #PLD(sttime DATETIME,ndtime DATETIME,PlannedDT INT)
Insert Into #PLD(sttime,ndtime,PlannedDT)
SELECT StartTime,EndTime,
CASE
WHEN (StartTime >= @StartTime  AND EndTime <=@EndTime)  THEN DateDiff(second,StartTime,EndTime)
WHEN ( StartTime < @StartTime  AND EndTime <= @EndTime AND EndTime > @StartTime ) THEN DateDiff(second,@StartTime,EndTime)
WHEN ( StartTime >= @StartTime   AND StartTime <@EndTime AND EndTime > @EndTime ) THEN DateDiff(second,StartTime,@EndTime)
ELSE DateDiff(second,@StartTime,@EndTime)
END
From PlannedDownTimes Where PDTstatus = 1 and machine = @MachineID And
	  ((StartTime >= @StartTime  AND EndTime <=@EndTime)
	OR ( StartTime < @StartTime  AND EndTime <= @EndTime AND EndTime > @StartTime )
	OR ( StartTime >= @StartTime   AND StartTime <@EndTime AND EndTime > @EndTime )
	OR ( StartTime < @StartTime  AND EndTime > @EndTime))
And exists (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD' And ValueInText = 'Y')
--select * from #PLD
--------------------------------------------------------------------------------
*/
--mod 5
create table #tempALL(
	starttime datetime,
	endtime datetime,
--mod 6
	MachineInterface nvarchar(50),
	CompInterface nvarchar(50),
	OPNInterface nvarchar(50),
--mod 6
	actLoadUnloadTime int default 0,
	actMcTime int default 0,
	stdMcTime int default 0,
	stdlLoadUnloadTime int default 0,
	actTotalTime int default 0,
	stdTotalTime int default 0,
	--PLD int default 0) ER0303 Commented
	PDT int default 0) --ER0303 Added
--mod 4
---mod 1 Added 120 to format function To consider seconds part of time stamp during calculations
---mod 3
--IF( @Type = 'ALL')    -- Loadunload, Cycle
IF( @Type = N'ALL')    -- Loadunload, Cycle
---mod 3
Begin
	---''' select @strsql = 'SELECT autodata.loadunload AS actLoadUnloadTime,autodata.cycletime AS actMcTime,componentoperationpricing.machiningTime AS stdMcTime,(componentoperationpricing.cycletime - componentoperationpricing.machiningtime) AS stdlLoadUnloadTime '
	--mod 6
	--select @strsql = 'insert into #tempALL (actLoadUnloadTime,actMcTime,stdMcTime,stdlLoadUnloadTime) SELECT convert(decimal (18, 2),dbo.f_FormatTime(autodata.loadunload,''' + @TimeFormat + ''')) AS actLoadUnloadTime,'
	select @strsql = 'insert into #tempALL (Starttime,Endtime,MachineInterface, CompInterface,OPNInterface,actLoadUnloadTime,actMcTime,stdMcTime,stdlLoadUnloadTime)
	 SELECT autodata.sttime,autodata.ndtime, autodata.mc,autodata.comp,autodata.opn,convert(decimal (18, 2),dbo.f_FormatTime(autodata.loadunload,''' + @TimeFormat + ''')) AS actLoadUnloadTime,'
	--mod 6
	select @strsql = @strsql+'convert(decimal (18, 2),dbo.f_FormatTime(autodata.cycletime,''' + @TimeFormat + '''))  AS actMcTime,
	convert(decimal (18, 2),dbo.f_FormatTime((componentoperationpricing.machiningTime*autodata.partscount),''' + @TimeFormat + '''))  AS stdMcTime,
	convert(decimal (18, 2),dbo.f_FormatTime((componentoperationpricing.cycletime - componentoperationpricing.machiningtime)* autodata.partscount,''' + @TimeFormat + '''))  AS stdlLoadUnloadTime '
end
else
---mod 3
--if @Type = 'ASLT'   -- loadunload
if @Type = N'ASLT'   -- loadunload
---mod 3
	BEGIN
	--select @strsql = 'SELECT   autodata.loadunload AS actLoadUnloadTime,(componentoperationpricing.cycletime - componentoperationpricing.machiningtime) AS stdlLoadUnloadTime  '
	select @strsql = 'insert into #tempALL (Starttime,Endtime,actLoadUnloadTime,stdlLoadUnloadTime) SELECT autodata.sttime,autodata.ndtime,convert(decimal (18, 2),dbo.f_FormatTime(autodata.loadunload,''' + @TimeFormat + '''))  AS actLoadUnloadTime, --DR0370 included starttime and endtime
	convert(decimal (18, 2),dbo.f_FormatTime(((componentoperationpricing.cycletime - componentoperationpricing.machiningtime)* autodata.partscount) ,''' + @TimeFormat + ''')) AS stdlLoadUnloadTime  '
	END
ELSE
---mod 3
--if @Type = 'ASMT' --Act -std cycle time
if @Type = N'ASMT' --Act -std cycle time
---mod 3
	BEGIN
	--select @strsql = 'SELECT   autodata.cycletime AS actMcTime,(componentoperationpricing.machiningTime) AS stdMcTime  '
	--mod 6
	--select @strsql = 'insert into #tempALL (actMcTime,stdMcTime) SELECT   convert(decimal (18, 2),dbo.f_FormatTime(  autodata.cycletime ,''' + @TimeFormat + '''))  AS actMcTime,'
	  select @strsql = 'insert into #tempALL (Starttime,Endtime,MachineInterface, CompInterface,OPNInterface,actMcTime,stdMcTime) SELECT    autodata.sttime,autodata.ndtime, autodata.mc,autodata.comp,autodata.opn,convert(decimal (18, 2),dbo.f_FormatTime(  autodata.cycletime ,''' + @TimeFormat + '''))  AS actMcTime,'
	--mod 6
	select @strsql = @strsql+'convert(decimal (18, 2),dbo.f_FormatTime( (componentoperationpricing.machiningTime*autodata.partscount) ,''' + @TimeFormat + ''')) AS stdMcTime  '
	END
ELSE
--'convert(decimal (18, 2),dbo.f_FormatTime((componentoperationpricing.machiningTime+(componentoperationpricing.cycletime - componentoperationpricing.machiningtime))*autodata.partscount  ,''' + @TimeFormat + '''))
---mod 3
--if @Type = 'TMT' --TtaoMcTime( LU + CycleTime)
if @Type = N'TMT' --TtaoMcTime( LU + CycleTime)
---mod 3
	BEGIN
	--select @strsql = 'SELECT   autodata.cycletime+autodata.loadunload as actTotalTime ,(componentoperationpricing.machiningTime+(componentoperationpricing.cycletime - componentoperationpricing.machiningtime) AS stdTotalTime  '
	select @strsql = 'insert into #tempALL(Starttime,Endtime,MachineInterface, CompInterface,OPNInterface,actTotalTime,stdTotalTime) SELECT       autodata.sttime,autodata.ndtime, autodata.mc,autodata.comp,autodata.opn,convert(decimal (18, 2),dbo.f_FormatTime(  autodata.cycletime+autodata.loadunload ,''' + @TimeFormat + ''')) as actTotalTime ,'
	select @strsql = @strsql+'convert(decimal (18, 2),dbo.f_FormatTime((componentoperationpricing.machiningTime+(componentoperationpricing.cycletime - componentoperationpricing.machiningtime))*autodata.partscount  ,''' + @TimeFormat + '''))  AS stdTotalTime  '
	END
SELECT @strsql = @strsql + 'FROM autodata INNER JOIN  '
SELECT @strsql = @strsql + 'machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN   '
SELECT @strsql = @strsql + 'componentinformation ON autodata.comp = componentinformation.InterfaceID  INNER JOIN  '
SELECT @strsql = @strsql + 'componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID  '
SELECT @strsql = @strsql + 'AND componentinformation.componentid = componentoperationpricing.componentid '
---mod 2
SELECT @strsql = @strsql +'and componentoperationpricing.machineid=machineinformation.machineid '
---mod 2
SELECT @strsql = @strsql + 'WHERE  '
---ER0450 Added From Here
--SELECT @strsql = @strsql + '(autodata.sttime >= ''' + convert(nvarchar(20),@StartTime,120) + ''')  '
--SELECT @strsql = @strsql + 'AND  '
--SELECT @strsql = @strsql + '(autodata.sttime <'' ' + convert(nvarchar(20),@EndTime,120)  + ''')  '
SELECT @strsql = @strsql + '(autodata.ndtime > ''' + convert(nvarchar(20),@StartTime,120) + ''')  '
SELECT @strsql = @strsql + 'AND  '
SELECT @strsql = @strsql + '(autodata.ndtime <=''' + convert(nvarchar(20),@EndTime,120)  + ''')  '
---ER0450 Added Till Here
SELECT @strsql = @strsql + 'AND   '
---mod 3
--SELECT @strsql = @strsql + '(machineinformation.machineid =''' + @machineid +''') '
SELECT @strsql = @strsql + '(machineinformation.machineid =N''' + @machineid +''') '
---mod 3
SELECT @strsql = @strsql + 'AND  '
SELECT @strsql = @strsql + '(autodata.datatype = 1)  '
SELECT @strsql = @strsql + 'ORDER BY autodata.id  '
print (@strsql)
EXEC (@strsql)


/*************************ER0295 From Here.
If ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y' and
(SELECT ValueInInt From CockpitDefaults Where Parameter ='VDG-CycleDefinition')=2 and  @Type <> 'ASLT'  )

BEGIN
UPDATE #TempAll set  actMcTime=isnull(actMcTime,0) - isNull(TT.PPDT ,0)--,PDT=isNull(TT.PPDT ,0)
,actTotalTime=isnull(actTotalTime,0) - isNull(TT.PPDT ,0)
	FROM(
		--Production Time in PDT
	Select A.mc,A.comp,A.Opn,A.sttime,A.ndtime,Sum
			(CASE
			WHEN A.sttime >= T.StartTime  AND A.ndtime <=T.EndTime  THEN (A.cycletime)
			WHEN ( A.sttime < T.StartTime  AND A.ndtime <= T.EndTime  AND A.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,A.ndtime)
			WHEN ( A.sttime >= T.StartTime   AND A.sttime <T.EndTime  AND A.ndtime > T.EndTime  ) THEN DateDiff(second,A.sttime,T.EndTime )
			WHEN ( A.sttime < T.StartTime  AND A.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END)  as PPDT
	From 
			
		(
			SELECT M.Machineid,
			autodata.MC,autodata.comp,autodata.Opn,autodata.sttime,autodata.ndtime,autodata.Cycletime
			FROM AutoData inner join Machineinformation M on M.interfaceid=Autodata.mc
			where autodata.DataType=1 And autodata.sttime >=@StartTime  AND autodata.sttime < @EndTime)A
			CROSS jOIN PlannedDownTimes T
			WHERE T.Machine=A.Machineid AND
			((A.sttime >= T.StartTime  AND A.ndtime <=T.EndTime)
			OR ( A.sttime < T.StartTime  AND A.ndtime <= T.EndTime AND A.ndtime > T.StartTime )
			OR ( A.sttime >= T.StartTime   AND A.sttime <T.EndTime AND A.ndtime > T.EndTime )
			OR ( A.sttime < T.StartTime  AND A.ndtime > T.EndTime) 
		)
	group by A.mc,A.comp,A.Opn,A.sttime,A.ndtime
	)
	as TT INNER JOIN #TempAll ON TT.mc = #TempAll.MachineInterface
		and TT.comp = #TempAll.CompInterface
			and TT.opn = #TempAll.OPNInterface and tt.sttime=#TempAll.StartTime
and #TempAll.EndTime=TT.ndtime

ER0295 Till Here. ***********************/


--ER0295 Modified From Here.
If ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y' and
(SELECT ValueInInt From CockpitDefaults Where Parameter ='VDG-CycleDefinition')=2  )

BEGIN
set ansi_warnings off
UPDATE #TempAll set  actMcTime=isnull(actMcTime,0) - isNull(TT.PPDT ,0)--,PDT=isNull(TT.PPDT ,0)
,actTotalTime=isnull(actTotalTime,0) - isNull(TT.PPDT ,0)-isNull(TT.LD ,0),actLoadUnloadTime = isnull(actLoadUnloadTime,0) - isNull(TT.LD ,0),

--ER0303 From Here.
--PLD=case when @Type = N'TMT' or @Type = N'ALL' then isnull(PLD,0)+isNull(TT.PPDT ,0)+isNull(TT.LD ,0) 
--When @Type = N'ASLT' then isnull(PLD,0)+isNull(TT.LD ,0) 
--When @Type = N'ASMT' then isnull(PLD,0)+isNull(TT.PPDT ,0) end 
PDT=case when @Type = N'TMT' or @Type = N'ALL' then isnull(PDT,0)+isNull(TT.PPDT ,0)+isNull(TT.LD ,0) 
When @Type = N'ASLT' then isnull(PDT,0)+isNull(TT.LD ,0) 
When @Type = N'ASMT' then isnull(PDT,0)+isNull(TT.PPDT ,0) end 
--ER0303 Till Here.

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
			autodata.msttime
			FROM AutoData inner join Machineinformation M on M.interfaceid=Autodata.mc
			--where autodata.DataType=1 And autodata.msttime >=@StartTime  AND autodata.msttime < @EndTime)A--DR0309
			where autodata.DataType=1 And autodata.sttime >=@StartTime  AND autodata.sttime < @EndTime)A
			CROSS jOIN PlannedDownTimes T
			WHERE T.Machine=A.Machineid AND t.machine=@machineid and
			((A.msttime >= T.StartTime  AND A.ndtime <=T.EndTime)
			OR ( A.msttime < T.StartTime  AND A.ndtime <= T.EndTime AND A.ndtime > T.StartTime )
			OR ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime AND A.ndtime > T.EndTime )
			OR ( A.msttime < T.StartTime  AND A.ndtime > T.EndTime) 
			and T.PDTStatus = 1   --DR0309 Swathi 16/Aug/12
		)
	group by A.mc,A.comp,A.Opn,A.sttime,A.ndtime,A.msttime
	)
	as TT 
INNER JOIN #TempAll ON TT.mc = #TempAll.MachineInterface
		and TT.comp = #TempAll.CompInterface
			and TT.opn = #TempAll.OPNInterface and tt.sttime=#TempAll.StartTime
and #TempAll.EndTime=TT.ndtime
--ER0295 Modified Till Here.


/****************************** ER0384 From here ***********************************

		UPDATE  #TempAll  set  actMcTime=isnull(actMcTime,0) + isNull(T2.IPDT ,0)--,PDT=isNull(TT.PPDT ,0)
		,actTotalTime=isnull(actTotalTime,0) + isNull(T2.IPDT ,0)	FROM	(
		--Select AutoData.mc,autodata.comp,autodata.Opn,autodata.sttime,autodata.ndtime, --DR0309
		Select AutoData.mc,autodata.comp,autodata.Opn,T1.sttime,T1.ndtime,
		SUM(
		CASE 	
			When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
			When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
			When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
			when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		From AutoData INNER Join
			(Select mc,Sttime,NdTime From AutoData
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>AutoData.CycleTime And
				autodata.sttime >=@StartTime  AND autodata.sttime < @EndTime) as T1
		ON AutoData.mc=T1.mc inner join machineinformation M
		on m.interfaceid=T1.mc 
		CROSS jOIN PlannedDownTimes T
		Where AutoData.DataType=2 And T.Machine=m.Machineid
		And (( autodata.Sttime > T1.Sttime )
		And ( autodata.ndtime <  T1.ndtime )
		)
		AND
		((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
		or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
		or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
		or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )
		and T.PDTStatus = 1   --DR0309 Swathi 16/Aug/12
		--GROUP BY AUTODATA.mc,autodata.comp,autodata.Opn,autodata.sttime,autodata.ndtime --DR0309
		GROUP BY AUTODATA.mc,autodata.comp,autodata.Opn,t1.sttime,t1.ndtime --DR0309
		)AS T2  INNER JOIN #TempAll ON T2.mc = #TempAll.MachineInterface
				and T2.comp = #TempAll.CompInterface
			and T2.opn = #TempAll.OPNInterface and t2.sttime=#TempAll.StartTime
and #TempAll.EndTime=T2.ndtime
********************************* ER0384 Till Here ***********************************/

	/********************************** DR0349 Commented From here ************************************
		--Handle intearction between ICD and PDT for type 1 production record for the selected time period.
		UPDATE  #TempAll  set actMcTime=isnull(actMcTime,0) + isNull(T2.IPDT ,0)--,PDT=isNull(TT.PPDT ,0)
		,actTotalTime=isnull(actTotalTime,0) + isNull(T2.IPDT ,0) FROM	(
		Select T1.mc,T1.comp,T1.opn,T1.sttime,T1.ndtime,SUM(
			CASE 	
				When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1
				When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2
				When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3
				when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4
			END) as IPDT from
		(Select A.mc,A.comp,A.opn,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype from autodata A
		Where A.DataType=2
		and exists 
			(
			Select B.Sttime,B.NdTime,B.mc,B.comp,B.opn From AutoData B
			Where B.mc = A.mc and
			B.DataType=1 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And
			(B.msttime >= @starttime AND B.ndtime <= @Endtime) and
			(B.sttime < A.sttime) AND (B.ndtime > A.ndtime) 
			)
		 )as T1 inner join
		(select  machine,Case when starttime<@starttime then @starttime else starttime end as starttime, 
		case when endtime> @Endtime then @Endtime else endtime end as endtime from dbo.PlannedDownTimes 
		where PDTStatus = 1  and ((( StartTime >=@starttime) And ( EndTime <=@Endtime))
		or (StartTime < @starttime  and  EndTime <= @Endtime AND EndTime > @starttime)
		or (StartTime >= @starttime  AND StartTime <@Endtime AND EndTime > @Endtime)
		or (( StartTime <@starttime) And ( EndTime >@Endtime )) )
		)T
		on T1.machine=T.machine AND
		((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
		or (T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
		or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
		or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )group by T1.mc,T1.comp,T1.opn,T1.sttime,T1.ndtime
		)AS T2 INNER JOIN #TempAll ON T2.mc = #TempAll.MachineInterface
			and T2.comp = #TempAll.CompInterface
			and T2.opn = #TempAll.OPNInterface and t2.sttime=#TempAll.StartTime
			and #TempAll.EndTime=T2.ndtime
		********************************** DR0349 Commented Till here ************************************/

		/********************************* DR0349 Added From here ************************************/
		--Handle intearction between ICD and PDT for type 1 production record for the selected time period.
		UPDATE  #TempAll  set actMcTime=isnull(actMcTime,0) + isNull(T2.IPDT ,0)--,PDT=isNull(TT.PPDT ,0)
		,actTotalTime=isnull(actTotalTime,0) + isNull(T2.IPDT ,0) FROM	(
		Select T1.mc,T1.comp,T1.opn,T1.sttime,T1.ndtime,T1.CycleStart,T1.CycleEnd,SUM(
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
		where PDTStatus = 1  and ((( StartTime >=@starttime) And ( EndTime <=@Endtime))
		or (StartTime < @starttime  and  EndTime <= @Endtime AND EndTime > @starttime)
		or (StartTime >= @starttime  AND StartTime <@Endtime AND EndTime > @Endtime)
		or (( StartTime <@starttime) And ( EndTime >@Endtime )) )
		)T
		on T1.machine=T.machine AND
		((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
		or (T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
		or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
		or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )group by T1.mc,T1.comp,T1.opn,T1.sttime,T1.ndtime,T1.CycleStart,T1.CycleEnd
		)AS T2 INNER JOIN #TempAll ON T2.mc = #TempAll.MachineInterface
			and T2.comp = #TempAll.CompInterface
			and T2.opn = #TempAll.OPNInterface and t2.CycleStart=#TempAll.StartTime
			and #TempAll.EndTime=T2.CycleEnd
		/********************************* DR0349 Added Till here ************************************/
set ansi_warnings ON
End

--ER0394 From Here
create table #TempCockpitProductionData
(
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
	In_Cycle_DownTime int
)

Declare @ICDSetting as nvarchar(50)
Select @ICDSetting = isnull(Valueintext,'N') From CockpitDefaults Where Parameter ='Current_Cycle_ICD_Records'
IF @ICDSetting = 'Y'
BEGIN
	insert into #TempCockpitProductionData exec [dbo].[s_GetInProcessCycles] @starttime,@Endtime,@Machineid
END

INSERT INTO #TempAll(Starttime,Endtime,MachineInterface, CompInterface,OPNInterface,actLoadUnloadTime,actMcTime,stdMcTime,stdlLoadUnloadTime,actTotalTime,stdTotalTime)
Select StartTime,EndTime,MachineInterface, CompInterface,OPNInterface,convert(decimal (18, 2),dbo.f_FormatTime(LoadUnloadTime,'ss')),convert(decimal (18, 2),dbo.f_FormatTime(cycletime,'ss')),
convert(decimal (18, 2),dbo.f_FormatTime(StdMachiningTime,'ss')),
convert(decimal (18, 2),dbo.f_FormatTime((StdCycleTime - StdMachiningTime),'ss')),
convert(decimal (18, 2),dbo.f_FormatTime((cycletime+LoadUnloadTime) ,'ss')),
convert(decimal (18, 2),dbo.f_FormatTime((StdMachiningTime+(StdCycleTime- StdMachiningTime)) ,'ss')) from #TempCockpitProductionData
--ER0394 Till Here



/*ER0303 Changes From Here.
--select * from #TempAll
--return
--mod 6
--mod 4
IF( @Type = N'ALL')
Begin
print (@strsql)
--insert into #tempALL (StartTime,EndTime,PLD)(select * from #PLD)--mod 5
select actLoadUnloadTime,actMcTime,stdMcTime,stdlLoadUnloadTime,PLD from #tempALL
End
if @Type = N'ASLT'
Begin
--insert into #tempALL (StartTime,EndTime,PLD)(select * from #PLD)--mod 5
select actLoadUnloadTime,stdlLoadUnloadTime,PLD from #tempALL
End
if @Type = N'ASMT'
Begin
--insert into #tempALL (StartTime,EndTime,PLD)(select * from #PLD)--mod 5
select actMcTime,stdMcTime,PLD from #tempALL
End
if @Type = N'TMT'
Begin
--insert into #tempALL (StartTime,EndTime,PLD)(select * from #PLD)--mod 5
select actTotalTime,stdTotalTime,PLD from #tempALL
End
--mod 4
ER0303 Changes Till Here. 
*/

--ER0303 From Here.
If ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y' and
(SELECT ValueInInt From CockpitDefaults Where Parameter ='VDG-CycleDefinition')=2  )
	BEGIN
		IF( @Type = N'ALL')
		Begin
			select actLoadUnloadTime,actMcTime,stdMcTime,stdlLoadUnloadTime,PDT from #tempALL Order by starttime --DR0370 Added
		End
		if @Type = N'ASLT'
		Begin
			select actLoadUnloadTime,stdlLoadUnloadTime,PDT from #tempALL Order by starttime --DR0370 Added
		End
		if @Type = N'ASMT'
		Begin
			select actMcTime,stdMcTime,PDT from #tempALL Order by starttime --DR0370 Added
		End
		if @Type = N'TMT'
		Begin
			select actTotalTime,stdTotalTime,PDT from #tempALL Order by starttime --DR0370 Added
		End
	END

--If ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')<>'Y' and --DR0297 Commented
--(SELECT ValueInInt From CockpitDefaults Where Parameter ='VDG-CycleDefinition')<>2  )			--DR0297 Commented
ELSE  --DR0297 Added
	BEGIN
		IF( @Type = N'ALL')
		Begin
			select actLoadUnloadTime,actMcTime,stdMcTime,stdlLoadUnloadTime from #tempALL Order by starttime --DR0370 Added
		End
		if @Type = N'ASLT'
		Begin
			select actLoadUnloadTime,stdlLoadUnloadTime from #tempALL Order by starttime --DR0370 Added
		End
		if @Type = N'ASMT'
		Begin
			select actMcTime,stdMcTime from #tempALL Order by starttime --DR0370 Added
		End
		if @Type = N'TMT'
		Begin
			select actTotalTime,stdTotalTime from #tempALL Order by starttime --DR0370 Added
		End
	END
--ER0303 Till Here.


END
