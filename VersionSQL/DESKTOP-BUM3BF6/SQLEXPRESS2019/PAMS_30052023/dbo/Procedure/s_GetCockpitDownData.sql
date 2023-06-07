/****** Object:  Procedure [dbo].[s_GetCockpitDownData]    Committed by VersionSQL https://www.versionsql.com ******/

/*************************************************************************************
Created By sangeeta Kallur on 23-Mar-06
Changed existing s_GetCockpitDownData
To account type-1 ,type-2,type-3 and type-4 records And to get Threshold,MLE
Procedure changed by SSK : 22-Nov-07 : DR0079
mod 1 :- ER0210 By KarthikG Introduce PDT on 5150. Handle PDT at Machine Level.
s_GetCockpitDownData '2010-08-01','2011-08-21','MBC PUMA 400XL'
drop table #TempCockpitDownData
To handle error
DR0253 - KarthikR - 28/Aug/2010 :: The view data graph down tab after implementing PDT-
				   the row number and the bar graph are not matching.
DR0273- SwathiKS - 12/Mar/2011 :: To Handle Error String or binary Data would be Truncated.
ER0295 - SwathiKS - 02/Jul/2011 :: To Apply PDT For Loadunload.
DR0292 - SwathiKS - 26/Aug/2011 :: To Avoid Negative Downtime in SmartCockpit->VDG.
ER0370 - SwathiKS - 25/Nov/2013 :: To Show Current Cycle ICD Records Based on Setting in Cockpitdefaults Table, 
If Setting = "Y" then Calling  Procedure [dbo].[s_GetCurrentCycleICDRecords].
NR0097 - SwathiKS - 17/dec/2013 :: Ace - While Accounting DownThreshold, To apply Threshold from Componentoperationprcing table for the Downs with 
"PickFomCO = 1" else apply threshold from Downcodeinformation table eith "Availeffy=1" and "PickFomCO <> 1" .
ER0402 - SwathiKS - 01/Jan/2015 :: To Show Operators which does not have Master entry in Down Grid.
s_GetCockpitDownData '2014-03-28 07:00:00' , '2014-03-30 15:30:00','DOOSAN-5'
***************************************************************************************/
CREATE PROCEDURE [dbo].[s_GetCockpitDownData]
	@StartTime datetime,
	@EndTime datetime,
	@MachineID nvarchar(50)
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

---DR0253 - KarthikR - 28/Aug/2010 from here
create table #TempCockpitDownData
(
	SerialNO bigint IDENTITY (1, 1) NOT NULL,
	StartTime datetime,
	EndTime datetime,
	OperatorID nvarchar(50),
	--OperatorName nvarchar(50), --DR0270
	OperatorName nvarchar(150),
	DownID nvarchar(50),
	--DownDescription nvarchar(50),--DR0270
	DownDescription nvarchar(100),
	--DownThreshold numeric(9) , --DR0270
	DownThreshold numeric(18) ,
	DownTime nvarchar(50) ,
	--Remarks nvarchar(50), --DR0270
	Remarks nvarchar(255),
	[id] bigint,
	PDT int --ER0295
)
---DR0253 - KarthikR - 28/Aug/2010 Till here
SELECT
--DR0292 Changes From Here.
--autodata.sttime,
--autodata.ndtime,
case when autodata.sttime<@starttime then @starttime else autodata.sttime end AS StartTime,
case when autodata.ndtime>@endtime then @endtime else autodata.ndtime end AS EndTime,
--DR0292 Changes Till Here.
--ER0402 Changes From here
--employeeinformation.Employeeid AS OperatorID,
--employeeinformation.[Name]  AS OperatorName,
Isnull(employeeinformation.Employeeid,autodata.opr) AS OperatorID,
Isnull(employeeinformation.[Name],'---')  AS OperatorName,
--ER0402 Changes Till here
downcodeinformation.downid AS DownID,
downcodeinformation.downdescription as [DownDescription],
CASE
--WHEN downcodeinformation.AvailEffy=1 and downcodeinformation.Threshold>0 THEN downcodeinformation.Threshold --NR0097
WHEN downcodeinformation.AvailEffy=1 AND downcodeinformation.ThresholdfromCO <>1 AND downcodeinformation.Threshold>0 THEN downcodeinformation.Threshold --NR0097
ELSE 0 END AS [DownThreshold],
case
When (autodata.sttime >= @StartTime AND autodata.ndtime <= @EndTime ) THEN loadunload
WHEN ( autodata.sttime < @StartTime AND autodata.ndtime <= @EndTime AND autodata.ndtime > @StartTime ) THEN DateDiff(second, @StartTime, ndtime)
WHEN ( autodata.sttime >= @StartTime AND autodata.sttime < @EndTime AND autodata.ndtime > @EndTime ) THEN  DateDiff(second, stTime, @EndTime)
ELSE
DateDiff(second, @StartTime, @EndTime)END AS DownTime,
autodata.Remarks,
autodata.id,
0 as PDT --ER0295
INTO #Temp
FROM         autodata INNER JOIN
machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN
downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
--INNER JOIN employeeinformation ON autodata.opr = employeeinformation.interfaceid --ER0402
LEFT OUTER JOIN employeeinformation ON autodata.opr = employeeinformation.interfaceid --ER0402
WHERE machineinformation.machineid = @MachineID AND autodata.datatype = 2 AND
(
(autodata.sttime >= @StartTime  AND autodata.ndtime <=@EndTime)
OR ( autodata.sttime < @StartTime  AND autodata.ndtime <= @EndTime AND autodata.ndtime > @StartTime )
OR ( autodata.sttime >= @StartTime   AND autodata.sttime <@EndTime AND autodata.ndtime > @EndTime )
OR ( autodata.sttime < @StartTime  AND autodata.ndtime > @EndTime)
)
ORDER BY autodata.ndtime

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
-------------------------- NR0097 Added Till Here --------------------------------------

/************************* ER0295 Commented From Here.**************************
--mod 1
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN
		Insert Into #Temp
		(StartTime,EndTime,OperatorID,OperatorName,DownID,DownDescription,DownTime,id)
		SELECT
		StartTime,EndTime,'--','--',DownReason,DownReason,
		CASE
		WHEN (StartTime >= @StartTime AND EndTime <=@EndTime) THEN  DateDiff(second,StartTime,EndTime)
		WHEN (StartTime < @StartTime  AND EndTime <= @EndTime AND EndTime > @StartTime ) THEN DateDiff(second,@StartTime,EndTime)
		WHEN (StartTime >= @StartTime AND StartTime <@EndTime AND EndTime > @EndTime ) THEN DateDiff(second,@StartTime,@EndTime)
		ELSE  DateDiff(second,@StartTime,@EndTime) END,0
		From PlannedDownTimes Where PDTstatus = 1 and machine = @MachineID and
			((StartTime >= @StartTime  AND EndTime <=@EndTime)
			OR ( StartTime < @StartTime  AND EndTime <= @EndTime AND EndTime > @StartTime )
			OR ( StartTime >= @StartTime   AND StartTime <@EndTime AND EndTime > @EndTime )
			OR ( StartTime < @StartTime  AND EndTime > @EndTime))
END
--mod 1
********************** ER0295 Commented Till Here. *********************/
--ER0295 Modified From here
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
BEGIN
update #Temp set DownTime = isnull(Downtime,0)-isnull(TT.plannedDT,0), PDT=isnull(TT.plannedDT,0)
	from
(
	Select A.StartTime,A.EndTime,			
			sum(case
			WHEN A.StartTime >= T.StartTime  AND A.EndTime <=T.EndTime  THEN A.DownTime
			WHEN ( A.StartTime < T.StartTime  AND A.EndTime <= T.EndTime  AND A.EndTime > T.StartTime ) THEN DateDiff(second,T.StartTime,A.EndTime)
			WHEN ( A.StartTime >= T.StartTime   AND A.StartTime <T.EndTime  AND A.EndTime > T.EndTime  ) THEN DateDiff(second,A.StartTime,T.EndTime )
			WHEN ( A.StartTime < T.StartTime  AND A.EndTime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END) as plannedDT
	From #Temp A CROSS jOIN PlannedDownTimes T
			WHERE  T.machine=@machineid  and pdtstatus=1 and --datatype=2 and
			((A.StartTime >= T.StartTime  AND A.EndTime <=T.EndTime)
			OR ( A.StartTime < T.StartTime  AND A.EndTime <= T.EndTime AND A.EndTime > T.StartTime )
			OR ( A.StartTime >= T.StartTime   AND A.StartTime <T.EndTime AND A.EndTime > T.EndTime )
			OR ( A.StartTime < T.StartTime  AND A.EndTime > T.EndTime))
			group by A.StartTime,A.EndTime
)TT
INNER JOIN #Temp ON TT.StartTime=#Temp.StartTime and #Temp.EndTime=TT.EndTime
END
--ER0295 Modified Till Here.
--DR0079 : Starts here
---DR0253 - KarthikR - 28/Aug/2010 from here
/*
SELECT
IDENTITY(int, 1, 1) AS SerialNo,*
INTO #TempCockpitDownData
FROM #Temp
*/
SET IDENTITY_INSERT #TempCockpitDownData Off
insert into #TempCockpitDownData
(
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
	PDT --ER0295
) Select * from #temp order by starttime,endtime
---DR0253 - KarthikR - 28/Aug/2010 Till here
--DR0079 : Ends here

--ER0370 From Here
Declare @ICDSetting as nvarchar(50)
Select @ICDSetting = isnull(Valueintext,'N') From CockpitDefaults Where Parameter ='Current_Cycle_ICD_Records'
IF @ICDSetting = 'Y'
BEGIN
	insert into #TempCockpitDownData exec [dbo].[s_GetCurrentCycleICDRecords] @starttime,@Endtime,@Machineid
END
--ER0370 Till Here

declare @TimeFormat as nvarchar(50)
SELECT @TimeFormat = ''
SELECT @TimeFormat = (SELECT  ValueInText  FROM CockpitDefaults WHERE Parameter = 'TimeFormat')
if (ISNULL(@TimeFormat,'')) = ''
SELECT @TimeFormat = 'ss'

SELECT SerialNO,
StartTime,
EndTime,
OperatorID,
OperatorName,
DownID,
DownDescription,
dbo.f_FormatTime(DownTime, @TimeFormat  ) as DownTime ,
dbo.f_FormatTime(DownThreshold,@TimeFormat) AS DownThreshold,
CASE
WHEN (DownTime > DownThreshold AND DownThreshold > 0) THEN dbo.f_FormatTime(abs(DownTime-DownThreshold),@TimeFormat)
ELSE '0' END AS MLE,
Remarks,id,DownTime as SortDownTime ,
PDT --ER0295
,DownID as SortDownID, --SV
DownDescription as SortDownDescription --SV
,DownThreshold as SortDownThreshold --SV
From #TempCockpitDownData
order by SerialNo

END
