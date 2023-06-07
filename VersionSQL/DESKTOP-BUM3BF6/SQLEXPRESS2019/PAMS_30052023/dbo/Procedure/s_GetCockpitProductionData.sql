/****** Object:  Procedure [dbo].[s_GetCockpitProductionData]    Committed by VersionSQL https://www.versionsql.com ******/

/***************************************************************************************
Procedure Altred On top of 4.5.0.0 by Sangeeta Kallur On May-2006
To support the down within the production cycle as they appear.
Added extra In_Cycle_DownTime Column
Changed by SSK : ER0025 : 25/07/07 : To show LoadUnload Loss in VDG-Production Grid
Changed by SSK : DR0040 : 21/08/07 : Records or not sorted by sttime
mod 1 :- ER0181 By Kusuma M.H on 11-May-2009.2) Modify all the procedures accordingly. Qualify machine wherever we are making use of component and opeartion no.
mod 2 :- ER0182 By Kusuma M.H on 11-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
mod 3 :- ER0210 By KarthikG Introduce PDT on 5150. Handle PDT at Machine Level.
mod 4 :- ER0253 by Karthick R on 28-sep-2010.To suppress PDT details while displaying production Data
mod 5: - ER0266 by Karthick R on 20-Oct-2010.To Apply PDT for cycle time calculation
ER0273 - SwathiKS - 26/Nov/2010 :: To Add ComponentInformation.Description Column Under VDG-Production Grid and
			           To Provide Setting In CockpitDefaults (Parameter- "VDG-ComponentSetting")	
DR0273- SwathiKS - 05/Mar/2011 :: To Change Valueintext In CockpitDefaults where (Parameter- "VDG-ComponentSetting")	
			          To Rename Componentid(Description)Column as Componentid.
ER0295 - SwathiKS  - 02/Jul/2011 :: To Apply PDT For Loadunload.
DR0309 - SwathiKS - 21/Jun/2012 :: To Handle ICD + PDT Interaction during Final Update and PDTStatus=1.(Cycletime was Negative)
ER0384 - SwathiKS - 01/Jul/2014 :: Performance Optimization while handling interaction between ICD and PDT for Type1.
ER0394 - SwathiKS - 22/Sep/2014 :: To Show In Progress Records Based on Setting in Cockpitdefaults Table, 
If Setting = "Y" then Calling  Procedure [dbo].[s_GetInProcessCycles].
ER0402 - SwathiKS - 01/Jan/2015 :: To Show Operators which does not have Master entry in Production Grid.
DR0349 - SwathiKS - 29/Jan/2015 :: Ace - Observerd Negative Values while handling ICD-PDT Interaction. 
ER0450 - SwathiKS - 10/Oct/2017 :: To handle Partscount Mismatch in VDG production grid.
s_GetCockpitProductionData '2014-03-30 06:00:00 AM','2014-03-31 06:00:00 AM','ECONO-1'
**************************************************************************************/
CREATE PROCEDURE [dbo].[s_GetCockpitProductionData]
	@StartTime datetime,
	@EndTime datetime,
	@MachineID nvarchar(50)
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

-- 05/14/2004 satyendra included serialNo, Remarks, ID and create aTemp Table and time comparision
--- 16-Dec-2004 sjaiswal , include OpearatorName
SELECT
IDENTITY(int, 1, 1) AS SerialNo,
componentinformation.componentid AS ComponentID,
componentinformation.description AS description, --ER0273 - SwathiKS - 26/Nov/2010
componentoperationpricing.operationno AS OperationNo,
--ER0402 Changes From Here
--employeeinformation.Employeeid AS OperatorID,
--employeeinformation.[name] AS OperatorName,
Isnull(employeeinformation.Employeeid,autodata.opr) AS OperatorID,
Isnull(employeeinformation.[name],'---') AS OperatorName,
--ER0402 changes Till here
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
--ISNULL(autodata.loadunload,0)-(ISNULL(componentoperationpricing.cycletime,0) - ISNULL(componentoperationpricing.machiningtime,0)) AS LULoss,--SSK:ER0025:25/07/07
ISNULL(componentoperationpricing.cycletime,0)StdCycleTime,
ISNULL(componentoperationpricing.machiningtime,0)StdMachiningTime,--SSK:DR0040:21/08/07
autodata.id,
CASE
WHEN   DATEDIFF(SECOND,autodata.sttime,autodata.ndtime)>autodata.cycletime
THEN DATEDIFF(SECOND,autodata.sttime,autodata.ndtime)-autodata.cycletime
ELSE  0
END  AS  In_Cycle_DownTime
INTO #TempCockpitProductionData
FROM         autodata INNER JOIN
machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID INNER JOIN
componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID
AND componentinformation.componentid =  componentoperationpricing.componentid
---mod 1
and componentoperationpricing.machineid=machineinformation.machineid
---mod 1
--INNER JOIN employeeinformation ON autodata.opr = employeeinformation.interfaceid --ER0402
LEFT OUTER JOIN employeeinformation ON autodata.opr = employeeinformation.interfaceid --ER0402
WHERE
----ER0450 From Here
--(autodata.sttime >= @StartTime )
--AND
--(autodata.sttime < @EndTime )
(autodata.ndtime > @StartTime )
AND
(autodata.ndtime <= @EndTime )
----ER0450 Till Here
AND
---mod 2
--(machineinformation.machineid = @MachineID)
(machineinformation.machineid = N'' + @MachineID + '')
---mod 2
AND
(autodata.datatype = 1)
ORDER BY autodata.sttime



--        Select * from #TempCockpitProductionData order by SerialNo
--mod 3
--mod 4
/*
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
BEGIN
	Insert Into #TempCockpitProductionData(ComponentID,OperatorID,OperatorName,StartTime,EndTime,Remarks,id,
	LoadUnloadTime,StdCycleTime,StdMachiningTime)
	SELECT '--','--',DownReason,StartTime,EndTime,DownReason,0,0,0,0
	From PlannedDownTimes Where PDTstatus = 1 and machine = @MachineID and
		((StartTime >= @StartTime  AND EndTime <=@EndTime)
		OR ( StartTime < @StartTime  AND EndTime <= @EndTime AND EndTime > @StartTime )
		OR ( StartTime >= @StartTime   AND StartTime <@EndTime AND EndTime > @EndTime )
		OR ( StartTime < @StartTime  AND EndTime > @EndTime) )
End
*/
--mod 4
--mod 3
--mod 5
--Select * from #TempCockpitProductionData

/********** ER0295 Commented From here. ************************
If ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y' and
(SELECT ValueInInt From CockpitDefaults Where Parameter ='VDG-CycleDefinition')=2)
BEGIN
UPDATE #TempCockpitProductionData set  CycleTime=isnull(CycleTime,0) - isNull(TT.PPDT ,0),PDT=isNull(TT.PPDT ,0)
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
			OR ( A.sttime < T.StartTime  AND A.ndtime > T.EndTime) )
		group by A.mc,A.comp,A.Opn,A.sttime,A.ndtime
	)
	as TT INNER JOIN #TempCockpitProductionData ON TT.mc = #TempCockpitProductionData.MachineInterface
		and TT.comp = #TempCockpitProductionData.CompInterface
			and TT.opn = #TempCockpitProductionData.OPNInterface and tt.sttime=#TempCockpitProductionData.StartTime
and #TempCockpitProductionData.EndTime=TT.ndtime
****************** ER0295 Commented Till Here. **************************/


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
			--where autodata.DataType=1 And autodata.msttime >=@StartTime  AND autodata.msttime < @EndTime)A --DR0309 Swathi 21/Jun/12
			where autodata.DataType=1 And autodata.sttime >=@StartTime  AND autodata.sttime < @EndTime)A --DR0309 Swathi 21/Jun/12
			CROSS jOIN PlannedDownTimes T
			WHERE T.Machine=A.Machineid AND
			
			((A.msttime >= T.StartTime  AND A.ndtime <=T.EndTime)
			OR ( A.msttime < T.StartTime  AND A.ndtime <= T.EndTime AND A.ndtime > T.StartTime )
			OR ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime AND A.ndtime > T.EndTime )
			OR ( A.msttime < T.StartTime  AND A.ndtime > T.EndTime) )
			and T.PDTStatus = 1   --DR0309 Swathi 16/Aug/12
			/*--Swathi 21/Jun/12 Added From here Reference 
			((A.sttime >= T.StartTime  AND A.ndtime <=T.EndTime)
			OR ( A.msttime < T.StartTime  AND A.ndtime <= T.EndTime AND A.ndtime > T.StartTime )
			OR ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime AND A.ndtime > T.EndTime )
			OR ( A.msttime < T.StartTime  AND A.ndtime > T.EndTime) )
			--Swathi 21/Jun/12 Added Till here*/
		group by A.mc,A.comp,A.Opn,A.sttime,A.ndtime,A.msttime
	)
	as TT INNER JOIN #TempCockpitProductionData ON TT.mc = #TempCockpitProductionData.MachineInterface
		and TT.comp = #TempCockpitProductionData.CompInterface
			and TT.opn = #TempCockpitProductionData.OPNInterface and tt.sttime=#TempCockpitProductionData.StartTime
and #TempCockpitProductionData.EndTime=TT.ndtime
--ER0295 Modified Till here.

    /******************************* ER0384 from here  ******************************************************

		UPDATE  #TempCockpitProductionData set CycleTime=isnull(CycleTime,0) + isNull(T2.IPDT ,0) 	FROM	(
		--Select AutoData.mc,autodata.comp,autodata.Opn, autodata.sttime,autodata.ndtime, -- DR0309 Swathi Commented
		Select AutoData.mc,autodata.comp,autodata.Opn,T1.sttime,T1.ndtime,--DR0309 Swathi Added
		SUM(
		CASE 	
			When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
			When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
			When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
			when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		From AutoData INNER Join
			(Select mc,Sttime,NdTime From AutoData
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
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
		and T.PDTStatus = 1  --DR0309 Swathi 16/Aug/12
		--GROUP BY AUTODATA.mc,autodata.comp,autodata.Opn,autodata.sttime,autodata.ndtime --DR0309 Swathi Commented
		GROUP BY AUTODATA.mc,autodata.comp,autodata.Opn,t1.sttime,t1.ndtime --DR0309 SWathi Added
		)AS T2  INNER JOIN #TempCockpitProductionData ON T2.mc = #TempCockpitProductionData.MachineInterface
				and T2.comp = #TempCockpitProductionData.CompInterface
			and T2.opn = #TempCockpitProductionData.OPNInterface and t2.sttime=#TempCockpitProductionData.StartTime
			and #TempCockpitProductionData.EndTime=T2.ndtime
		************************************** ER0384 till Here ********************************/

		/********************************** DR0349 Commented From here ************************************
		--Handle intearction between ICD and PDT for type 1 production record for the selected time period.
		UPDATE  #TempCockpitProductionData set CycleTime =isnull(CycleTime,0) + isNull(T2.IPDT ,0) 	FROM	
		(
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
		where PDTStatus = 1 and ((( StartTime >=@starttime) And ( EndTime <=@Endtime))
		or (StartTime < @starttime  and  EndTime <= @Endtime AND EndTime > @starttime)
		or (StartTime >= @starttime  AND StartTime <@Endtime AND EndTime > @Endtime)
		or (( StartTime <@starttime) And ( EndTime >@Endtime )) )
		)T
		on T1.machine=T.machine AND
		((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
		or (T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
		or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
		or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )group by T1.mc,T1.comp,T1.opn,T1.sttime,T1.ndtime
		)AS T2  INNER JOIN #TempCockpitProductionData ON T2.mc = #TempCockpitProductionData.MachineInterface
				and T2.comp = #TempCockpitProductionData.CompInterface
			and T2.opn = #TempCockpitProductionData.OPNInterface and t2.sttime=#TempCockpitProductionData.StartTime
		and #TempCockpitProductionData.EndTime=T2.ndtime
		********************************** DR0349 Commented Till here ************************************/

		/********************************* DR0349 Added From here ************************************/
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
		/********************************* DR0349 Added Till here ************************************/
set ansi_warnings ON
End
--mod 5

--ER0394 From Here
Declare @ICDSetting as nvarchar(50)
Select @ICDSetting = isnull(Valueintext,'N') From CockpitDefaults Where Parameter ='Current_Cycle_ICD_Records'
IF @ICDSetting = 'Y'
BEGIN
	insert into #TempCockpitProductionData exec [dbo].[s_GetInProcessCycles] @starttime,@Endtime,@Machineid
END
--ER0394 Till Here

declare @strsql as nvarchar(4000)

--ER0273 - SwathiKS - 26/Nov/2010 From Here
Declare @VDGComp as nvarchar(50)
Select @VDGComp=''
Select @VDGComp=(Select ValueInText From CockpitDefaults WHERE Parameter ='VDG-ComponentSetting')
--ER0273 - SwathiKS - 26/Nov/2010 Till here

declare @TimeFormat as nvarchar(50)
SELECT @TimeFormat = ''
SELECT @TimeFormat = (SELECT  ValueInText  FROM CockpitDefaults WHERE Parameter = 'TimeFormat')
if (ISNULL(@TimeFormat,'')) = ''
	SELECT @TimeFormat = N'ss'


SELECT @strsql = 'SELECT SerialNo, '

--ER0273 - SwathiKS - 26/Nov/2010 From Here
--if @VDGComp = 'In VDG Grid - ComponentID Only' DR0273- SwathiKS - 05/Mar/2011
If @VDGComp = 'In VDG Grid - ComponentID without Description' --DR0273- SwathiKS - 05/Mar/2011
Begin
SELECT @strsql = @strsql +'Componentid as Componentid, '
End

if @VDGComp = 'In VDG Grid - ComponentID with Description'
Begin
--DR0273- SwathiKS - 05/Mar/2011 From Here
--SELECT @strsql = @strsql +'Componentid + ''(''+ Description + '')'' as ''Componentid(Description)'', '
SELECT @strsql = @strsql +'Componentid + ''(''+ Description + '')'' as ''Componentid'', '
--DR0273- SwathiKS - 05/Mar/2011 Till Here
End
--ER0273 - SwathiKS - 26/Nov/2010 Till Here

SELECT @strsql = @strsql +'OperationNo,OperatorID,OperatorName,StartTime,EndTime, '
if (@TimeFormat = 'hh:mm:ss'or @TimeFormat = 'hh' or @TimeFormat = 'mm' or @TimeFormat = 'ss' )
BEGIN
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(CycleTime,''' + @TimeFormat + ''') as CycleTime,'
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(LoadUnloadTime,''' + @TimeFormat + ''') as LoadUnloadTime,'
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(In_Cycle_DownTime,''' + @TimeFormat + ''') as In_Cycle_DownTime,'
	--mod 5
	
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(PDT,''' + @TimeFormat + ''') as PDT,'
	--mod 5
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(LoadUnloadTime-(StdCycleTime-StdMachiningTime),''' + @TimeFormat + ''')AS LULoss,'
ENd
SELECT @strsql =  @strsql  + 'Remarks,id,CycleTime as SortCycleTime,LoadUnloadTime as SortLoadUnloadTime FROM #TempCockpitProductionData order by SerialNo'
print @strsql
EXEC (@strsql)
END
