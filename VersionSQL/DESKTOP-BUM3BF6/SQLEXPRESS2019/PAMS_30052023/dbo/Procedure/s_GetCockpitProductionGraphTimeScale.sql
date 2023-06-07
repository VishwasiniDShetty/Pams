/****** Object:  Procedure [dbo].[s_GetCockpitProductionGraphTimeScale]    Committed by VersionSQL https://www.versionsql.com ******/

/*****************************************************************************
mod 1 :- for DR0114 by Mrudula. To consider seconds part of time stamp during calculations
Used in VDG
mod 2 :- ER0181 By Kusuma M.H on 11-May-2009.2) Modify all the procedures accordingly. Qualify machine wherever we are making use of component and opeartion no.
mod 3 :- ER0182 By Kusuma M.H on 11-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
mod 4 :- ER0210 By KarthikG Introduce PDT on 5150. Handle PDT at Machine Level.
ER0295 - Geethanjali Kore - 04/Jul/2011 :: To Apply PDT For Loadunload.
ER0303 - SwathiKS - 21/Sep/2011 :: a> To Change PLD Column To PDT.
		                           b> To Change Output For Report,WithPDT and Without PDT. 
DR0297 - SwathiKS - 01/Oct/2011 :: To Fix Error 'Operation is Not allowed When the object is closed.
								    Application-Defined or Object-Defined Error.
s_GetCockpitProductionGraphTimeScale '2009-12-01','2009-12-02','MCV 400','TMT'
s_GetCockpitProductionGraphTimeScale '2011-07-02' , '2011-07-03','IN2101-ACE1'
*******************************************************************************/
CREATE                PROCEDURE [dbo].[s_GetCockpitProductionGraphTimeScale]

@StartTime datetime, 
@EndTime datetime,   
@MachineID nvarchar(50),
@Type nvarchar(10)='ALL'

AS
BEGIN
declare @strsql nvarchar(4000)
--Intoduced @Type Variable for Different viewes of production Graph
-- Dec 4 2004 S. jaiswal
declare @TimeFormat as nvarchar(50)
SELECT @TimeFormat = 'ss'
--mod 4
create table #data
(
	sttime datetime,
	---ER0295 variables added From here.
	endtime datetime, 
	MachineInterface nvarchar(50),
	CompInterface nvarchar(50),
	OPNInterface nvarchar(50),
	---ER0295 variables added till here
	actLoadUnloadTime int,
	actMcTime int,
	stdMcTime int,
	stdLoadUnloadTime int,
	actTotalTime int default 0,
	stdTotalTime int default 0,
	--PLD int default 0) ER0303 Commented
	PDT int default 0   --ER0303 Added
 
)

--mod 4
SELECT @TimeFormat = (SELECT isnull(ValueInText,'ss')  FROM CockpitDefaults WHERE Parameter = 'TimeFormat')
if @TimeFormat = 'hh:mm:ss'
begin
	SELECT @TimeFormat = 'ss'
end
---mod 1 added 120 to format function. To consider seconds part of time stamp during calculations
---mod 3
--IF( @Type = 'ALL')    -- Loadunload, Cycle
IF( @Type = N'ALL')    -- Loadunload, Cycle
---mod 3
Begin

---ER0295 commented from here

----	---''' select @strsql = 'SELECT autodata.loadunload AS actLoadUnloadTime,autodata.cycletime AS actMcTime,componentoperationpricing.machiningTime AS stdMcTime,(componentoperationpricing.cycletime - componentoperationpricing.machiningtime) AS stdlLoadUnloadTime '
----	select @strsql = 'Insert into #data (actLoadUnloadTime,actMcTime,stdMcTime,stdLoadUnloadTime,sttime) SELECT convert(decimal (18, 2),dbo.f_FormatTime(autodata.loadunload,''' + @TimeFormat + ''')) AS actLoadUnloadTime,
----	convert(decimal (18, 2),dbo.f_FormatTime(autodata.cycletime,''' + @TimeFormat + '''))  AS actMcTime,
----	convert(decimal (18, 2),dbo.f_FormatTime((componentoperationpricing.machiningTime*autodata.partscount),''' + @TimeFormat + '''))  AS stdMcTime,
----	convert(decimal (18, 2),dbo.f_FormatTime((componentoperationpricing.cycletime - componentoperationpricing.machiningtime)* autodata.partscount,''' + @TimeFormat + '''))  AS stdLoadUnloadTime,autodata.sttime  '
----end
----else
-------mod 3
------if @Type = 'TMT' --TtaoMcTime( LU + CycleTime)
----if @Type = N'TMT' --TtaoMcTime( LU + CycleTime)
-------mod 3
----	BEGIN
----	--select @strsql = 'SELECT   autodata.cycletime+autodata.loadunload as actTotalTime ,(componentoperationpricing.machiningTime+(componentoperationpricing.cycletime - componentoperationpricing.machiningtime) AS stdTotalTime  '
----	select @strsql = 'Insert into #data (actTotalTime,stdTotalTime,sttime) SELECT   convert(decimal (18, 2),dbo.f_FormatTime(  autodata.cycletime+autodata.loadunload ,''' + @TimeFormat + ''')) as actTotalTime ,
----	convert(decimal (18, 2),dbo.f_FormatTime((componentoperationpricing.machiningTime+(componentoperationpricing.cycletime - componentoperationpricing.machiningtime))*autodata.partscount  ,''' + @TimeFormat + '''))  AS stdTotalTime,autodata.sttime   '
----	END
----SELECT @strsql = @strsql + 'FROM autodata INNER JOIN  '
----SELECT @strsql = @strsql + 'machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN   '
----SELECT @strsql = @strsql + 'componentinformation ON autodata.comp = componentinformation.InterfaceID  INNER JOIN  '
----SELECT @strsql = @strsql + 'componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID  '
----SELECT @strsql = @strsql + 'AND componentinformation.componentid = componentoperationpricing.componentid   '
-------mod 2
----SELECT @strsql = @strsql +'and componentoperationpricing.machineid=machineinformation.machineid '
-------mod 2
----SELECT @strsql = @strsql + 'WHERE  '
----SELECT @strsql = @strsql + '(autodata.sttime >= ''' + convert(nvarchar(20),@StartTime,120) + ''')  '
----SELECT @strsql = @strsql + 'AND  '
----SELECT @strsql = @strsql + '(autodata.sttime <'' ' + convert(nvarchar(20),@EndTime,120)  + ''')  '
----SELECT @strsql = @strsql + 'AND   '
-------mod 3
------SELECT @strsql = @strsql + '(machineinformation.machineid =''' + @machineid +''') '
----SELECT @strsql = @strsql + '(machineinformation.machineid =N''' + @machineid +''') '
-------mod 3
----SELECT @strsql = @strsql + 'AND  '
----SELECT @strsql = @strsql + '(autodata.datatype = 1)  '
----SELECT @strsql = @strsql + 'ORDER BY autodata.id  '
------print @strsql
----EXEC (@strsql)
------mod 4
----
----Insert Into #Data(actLoadUnloadTime, actMcTime, stdMcTime,stdLoadUnloadTime,sttime,PLD)
----SELECT
----0,0,0,0,StartTime,
----CASE
----WHEN (StartTime >= @StartTime  AND EndTime <=@EndTime)  THEN DateDiff(second,StartTime,EndTime)
----WHEN ( StartTime < @StartTime  AND EndTime <= @EndTime AND EndTime > @StartTime ) THEN DateDiff(second,@StartTime,EndTime)
----WHEN ( StartTime >= @StartTime   AND StartTime <@EndTime AND EndTime > @EndTime ) THEN DateDiff(second,StartTime,@EndTime)
----ELSE DateDiff(second,@StartTime,@EndTime)
----END
----From PlannedDownTimes Where PDTstatus = 1 and machine = @MachineID And
----	  (( StartTime >= @StartTime AND EndTime   <= @EndTime)
----	OR ( StartTime <  @StartTime AND EndTime   <= @EndTime AND EndTime > @StartTime )
----	OR ( StartTime >= @StartTime AND StartTime <  @EndTime AND EndTime > @EndTime )
----	OR ( StartTime <  @StartTime AND EndTime   >  @EndTime) )
----And exists (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD' And ValueInText = 'Y')
-----Er0295 Commented till here

--ER0295 Modified From here.
	---''' select @strsql = 'SELECT autodata.loadunload AS actLoadUnloadTime,autodata.cycletime AS actMcTime,componentoperationpricing.machiningTime AS stdMcTime,(componentoperationpricing.cycletime - componentoperationpricing.machiningtime) AS stdlLoadUnloadTime '
	select @strsql = 'Insert into #data (sttime,endtime,MachineInterface, CompInterface,OPNInterface,actLoadUnloadTime,actMcTime,stdMcTime,stdLoadUnloadTime) SELECT autodata.sttime,autodata.ndtime,autodata.mc,autodata.comp,autodata.opn,convert(decimal (18, 2),dbo.f_FormatTime(autodata.loadunload,''' + @TimeFormat + ''')) AS actLoadUnloadTime,
	convert(decimal (18, 2),dbo.f_FormatTime(autodata.cycletime,''' + @TimeFormat + '''))  AS actMcTime,
	convert(decimal (18, 2),dbo.f_FormatTime((componentoperationpricing.machiningTime*autodata.partscount),''' + @TimeFormat + '''))  AS stdMcTime,
	convert(decimal (18, 2),dbo.f_FormatTime((componentoperationpricing.cycletime - componentoperationpricing.machiningtime)* autodata.partscount,''' + @TimeFormat + '''))  AS stdLoadUnloadTime  '
end
else
if @Type = N'ASLT'   -- loadunload

	BEGIN
	select @strsql = 'insert into #data (actLoadUnloadTime,stdLoadUnloadTime) SELECT   convert(decimal (18, 2),dbo.f_FormatTime(autodata.loadunload,''' + @TimeFormat + '''))  AS actLoadUnloadTime,
	convert(decimal (18, 2),dbo.f_FormatTime(((componentoperationpricing.cycletime - componentoperationpricing.machiningtime)* autodata.partscount) ,''' + @TimeFormat + ''')) AS stdLoadUnloadTime  '
	END
ELSE
if @Type = N'ASMT' --Act -std cycle time
---mod 3
	BEGIN
	  select @strsql = 'insert into #data (sttime,endtime,MachineInterface, CompInterface,OPNInterface,actMcTime,stdMcTime) SELECT    autodata.sttime,autodata.ndtime, autodata.mc,autodata.comp,autodata.opn,convert(decimal (18, 2),dbo.f_FormatTime(  autodata.cycletime ,''' + @TimeFormat + '''))  AS actMcTime,'
	  select @strsql = @strsql+'convert(decimal (18, 2),dbo.f_FormatTime( (componentoperationpricing.machiningTime*autodata.partscount) ,''' + @TimeFormat + ''')) AS stdMcTime  '
	END
ELSE
---mod 3
--if @Type = 'TMT' --TtaoMcTime( LU + CycleTime)
if @Type = N'TMT' --TtaoMcTime( LU + CycleTime)
---mod 3
BEGIN
--select @strsql = 'SELECT   autodata.cycletime+autodata.loadunload as actTotalTime ,(componentoperationpricing.machiningTime+(componentoperationpricing.cycletime - componentoperationpricing.machiningtime) AS stdTotalTime  '
select @strsql = 'Insert into #data (sttime,endtime,MachineInterface, CompInterface,OPNInterface,actTotalTime,stdTotalTime) SELECT autodata.sttime,autodata.ndtime,autodata.mc,autodata.comp,autodata.opn,convert(decimal (18, 2),dbo.f_FormatTime(  autodata.cycletime+autodata.loadunload ,''' + @TimeFormat + ''')) as actTotalTime ,
convert(decimal (18, 2),dbo.f_FormatTime((componentoperationpricing.machiningTime+(componentoperationpricing.cycletime - componentoperationpricing.machiningtime))*autodata.partscount  ,''' + @TimeFormat + '''))  AS stdTotalTime   '
END
SELECT @strsql = @strsql + 'FROM autodata INNER JOIN  '
SELECT @strsql = @strsql + 'machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN   '
SELECT @strsql = @strsql + 'componentinformation ON autodata.comp = componentinformation.InterfaceID  INNER JOIN  '
SELECT @strsql = @strsql + 'componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID  '
SELECT @strsql = @strsql + 'AND componentinformation.componentid = componentoperationpricing.componentid   '
---mod 2
SELECT @strsql = @strsql +'and componentoperationpricing.machineid=machineinformation.machineid '
---mod 2
SELECT @strsql = @strsql + 'WHERE  '
SELECT @strsql = @strsql + '(autodata.sttime >= ''' + convert(nvarchar(20),@StartTime,120) + ''')  '
SELECT @strsql = @strsql + 'AND  '
SELECT @strsql = @strsql + '(autodata.sttime <'' ' + convert(nvarchar(20),@EndTime,120)  + ''')  '
SELECT @strsql = @strsql + 'AND   '
---mod 3
--SELECT @strsql = @strsql + '(machineinformation.machineid =''' + @machineid +''') '
SELECT @strsql = @strsql + '(machineinformation.machineid =N''' + @machineid +''') '
---mod 3
SELECT @strsql = @strsql + 'AND  '
SELECT @strsql = @strsql + '(autodata.datatype = 1)  '
SELECT @strsql = @strsql + 'ORDER BY autodata.id  '
print @strsql
EXEC (@strsql)
--mod 4
--ER0295 Modified Till here.

--------------------------ER0295 commented from here------------------------
------Insert Into #Data(actLoadUnloadTime, actMcTime, stdMcTime,stdLoadUnloadTime,sttime,PLD)
------SELECT
------0,0,0,0,StartTime,
------CASE
------WHEN (StartTime >= @StartTime  AND EndTime <=@EndTime)  THEN DateDiff(second,StartTime,EndTime)
------WHEN ( StartTime < @StartTime  AND EndTime <= @EndTime AND EndTime > @StartTime ) THEN DateDiff(second,@StartTime,EndTime)
------WHEN ( StartTime >= @StartTime   AND StartTime <@EndTime AND EndTime > @EndTime ) THEN DateDiff(second,StartTime,@EndTime)
------ELSE DateDiff(second,@StartTime,@EndTime)
------END
------From PlannedDownTimes Where PDTstatus = 1 and machine = @MachineID And
------	  (( StartTime >= @StartTime AND EndTime   <= @EndTime)
------	OR ( StartTime <  @StartTime AND EndTime   <= @EndTime AND EndTime > @StartTime )
------	OR ( StartTime >= @StartTime AND StartTime <  @EndTime AND EndTime > @EndTime )
------	OR ( StartTime <  @StartTime AND EndTime   >  @EndTime) )
------And exists (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD' And ValueInText = 'Y')
-----ER0295 Commented Till here. 
  
-------ER0295 code added from here
If ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y' and
(SELECT ValueInInt From CockpitDefaults Where Parameter ='VDG-CycleDefinition')=2)-- and @Type <> 'TMT'

BEGIN

UPDATE #data set  actMcTime=isnull(actMcTime,0) - isNull(TT.PPDT ,0)
,actTotalTime=isnull(actTotalTime,0) - isNull(TT.PPDT ,0)-isNull(TT.LD ,0),actLoadUnloadTime = isnull(actLoadUnloadTime,0) - isNull(TT.LD ,0),--PDT=isNull(TT.PPDT ,0),
--ER0303 Changes From Here
--PLD=case when @Type = N'TMT' or @Type = N'ALL' then isnull(PLD,0)+isNull(TT.PPDT ,0)+isNull(TT.LD ,0) 
--When @Type = N'ASLT' then isnull(PLD,0)+isNull(TT.LD ,0) 
--When @Type = N'ASMT' then isnull(PLD,0)+isNull(TT.PPDT ,0) end 
PDT=case when @Type = N'TMT' or @Type = N'ALL' then isnull(PDT,0)+isNull(TT.PPDT ,0)+isNull(TT.LD ,0) 
When @Type = N'ASLT' then isnull(PDT,0)+isNull(TT.LD ,0) 
When @Type = N'ASMT' then isnull(PDT,0)+isNull(TT.PPDT ,0) end 
--ER0303 Changes Till Here.
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
			where autodata.DataType=1 And autodata.msttime >=@StartTime  AND autodata.msttime < @EndTime)A
			CROSS jOIN PlannedDownTimes T
			WHERE T.Machine=A.Machineid AND t.machine=@machineid and
			((A.msttime >= T.StartTime  AND A.ndtime <=T.EndTime)
			OR ( A.msttime < T.StartTime  AND A.ndtime <= T.EndTime AND A.ndtime > T.StartTime )
			OR ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime AND A.ndtime > T.EndTime )
			OR ( A.msttime < T.StartTime  AND A.ndtime > T.EndTime) 
		)
	group by A.mc,A.comp,A.Opn,A.sttime,A.ndtime,A.msttime
	)
	as TT 
INNER JOIN #data ON TT.mc = #data.MachineInterface
		and TT.comp = #data.CompInterface
			and TT.opn =#data.OPNInterface and tt.sttime=#data.StTime
and #data.EndTime=TT.ndtime
-------ER0295 Modified Till here.



--	Handle intearction between ICD and PDT for type 1 production record for the selected time period.
		UPDATE  #data  set  actMcTime=isnull(actMcTime,0) + isNull(T2.IPDT ,0)--,PDT=isNull(T2.IPDT ,0)
,actTotalTime=isnull(actTotalTime,0) + isNull(T2.IPDT ,0)FROM	(
		Select AutoData.mc,autodata.comp,autodata.Opn,autodata.sttime,autodata.ndtime,
		SUM(
		CASE 	
			When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
			When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2 			When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
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
		GROUP BY AUTODATA.mc,autodata.comp,autodata.Opn,autodata.sttime,autodata.ndtime
		)AS T2  INNER JOIN #data ON T2.mc =#data.MachineInterface
				and T2.comp = #data.CompInterface
			and T2.opn = #data.OPNInterface and t2.sttime=#data.StTime
and #data.EndTime=T2.ndtime
End

/* ER0303 Commented From here.
IF( @Type = N'ALL')
Begin
select actLoadUnloadTime,actMcTime,stdMcTime,stdLoadUnloadTime,sttime,PLD from #data
End

--ER0295 From here
if @Type = N'ASLT'
Begin
--insert into #tempALL (StartTime,EndTime,PLD)(select * from #PLD)--mod 5
select actLoadUnloadTime,stdLoadUnloadTime,PLD from #data
End
if @Type = N'ASMT'
Begin
--insert into #tempALL (StartTime,EndTime,PLD)(select * from #PLD)--mod 5
select actMcTime,stdMcTime,PLD from #data
End
--ER0295 Till Here.

IF( @Type = N'TMT')
Begin
select actTotalTime,stdTotalTime,sttime,PLD from #data
End
--mod 4
ER0303 Commented Till Here */

--ER0303 From Here.
If ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y' and
(SELECT ValueInInt From CockpitDefaults Where Parameter ='VDG-CycleDefinition')=2)-- and @Type <> 'TMT'
	BEGIN
		IF( @Type = N'ALL')
		Begin
		select actLoadUnloadTime,actMcTime,stdMcTime,stdLoadUnloadTime,sttime,PDT from #data
		End

		if @Type = N'ASLT'
		Begin
		select actLoadUnloadTime,stdLoadUnloadTime,PDT from #data
		End

		if @Type = N'ASMT'
		Begin
		select actMcTime,stdMcTime,PDT from #data
		End

		IF( @Type = N'TMT')
		Begin
		select actTotalTime,stdTotalTime,sttime,PDT from #data
		End
	END

--If ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')<>'Y' and --DR0297 Commented
--(SELECT ValueInInt From CockpitDefaults Where Parameter ='VDG-CycleDefinition')<>2)-- and @Type <> 'TMT' --DR0297 commented
ELSE --DR0297 Added
	BEGIN
		IF( @Type = N'ALL')
		Begin
		select actLoadUnloadTime,actMcTime,stdMcTime,stdLoadUnloadTime,sttime from #data
		End

		if @Type = N'ASLT'
		Begin
		select actLoadUnloadTime,stdLoadUnloadTime from #data
		End

		if @Type = N'ASMT'
		Begin
		select actMcTime,stdMcTime from #data
		End

		IF( @Type = N'TMT')
		Begin
		select actTotalTime,stdTotalTime,sttime from #data
		End
	END
	--ER0303 Till Here.

END
