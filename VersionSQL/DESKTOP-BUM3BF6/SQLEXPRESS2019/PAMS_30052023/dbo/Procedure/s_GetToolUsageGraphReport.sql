/****** Object:  Procedure [dbo].[s_GetToolUsageGraphReport]    Committed by VersionSQL https://www.versionsql.com ******/

/*************************************************************************************
SangeetaKallur on 19thOct - Modified to get ToolSequenceNumber and IdealTool Usage
change machine length to 50 from 15: 17-feb-2006

Sangeeta Kallur Modified on 27-Sep-2006
To Aggregare consecutive tools

ER0400 - SwathiKS -  26/Dec/2014 :: To handle PDT, ICD for Type1 and ICD-PDT Interaction for Type 1 Records
while Calculating ActualToolUsage and handled Machineid in IdealUsage calculation.
**************************************************************************************/

--s_GetToolUsageGraphReport '2014-11-17 16:16:39.350','2014-11-17 17:17:34.707','VM024'
CREATE                        procedure [dbo].[s_GetToolUsageGraphReport]
	@CycleStart datetime,
	@CycleEnd   datetime,
	@machine nvarchar(50)
AS
BEGIN

DECLARE @timeformat as nvarchar(20)
DECLARE @ToolNo as integer

select @timeformat ='ss'
select @timeformat = isnull((select valueintext from cockpitdefaults where parameter='timeformat'),'ss')

if (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')
begin
select @timeformat = 'ss'
end

create table #tool
(
	machine nvarchar(15),
	starttime datetime,
	endtime datetime,
	toolusage   integer,
	tool nvarchar(6),
	IDno integer,
	SeqNo integer,
	IdealToolUsage integer,
	GroupNo  INTEGER DEFAULT 1,
	GActToolUsage Int DEFAULT 1,
	GIdealToolUsage Int DEFAULT 1,
	PDT int, --ER0400
	ICD INT, --ER0400
	IPDT INT, --ER0400
	ActualToolUsage int --ER0400
)

--INSERT INTO #tool (machine,starttime ,endtime, toolusage,tool,IDno,SeqNo,IdealToolUsage)--ER0400
INSERT INTO #tool (machine,starttime ,endtime, toolusage,tool,IDno,SeqNo,IdealToolUsage,PDT,ICD,IPDT,ActualToolUsage)--ER0400
SELECT machine,starttime,0,0,
	CASE
	WHEN detailnumber >= 0 AND detailnumber <=9 THEN 'T0'+CAST(detailnumber AS NVARCHAR)
	WHEN detailnumber >9 THEN 'T'+CAST(detailnumber AS NVARCHAR)
	END,
ID,0,0
,0,0,0,0 --ER0400
FROM autodatadetails INNER join machineinformation ON autodatadetails.machine=machineinformation.interfaceid
WHERE recordtype=5 AND machineID = @machine AND starttime>=@CycleStart AND starttime<=@CycleEnd
ORDER BY ID


CREATE TABLE #T1
(
	Machineid Nvarchar(50), --ER0400
	ComponentID Nvarchar(50),
	OpnNo integer
)

INSERT INTO #T1(Machineid,ComponentID,OpnNo)
--SELECT C.Componentid ,O.operationno FROM --ER0400
SELECT M.machineID,C.Componentid ,O.operationno FROM --ER0400
autodata A INNER JOIN componentinformation C on A.comp=C.interfaceid
INNER JOIN Machineinformation M on A.mc=M.interfaceid
INNER JOIN componentoperationpricing O on A.opn=O.interfaceid AND C.componentid=O.componentid
WHERE M.machineID=@machine and sttime>=@CycleStart and ndtime<=@CycleEnd


DECLARE @curstarttime as datetime
DECLARE @curendtime as datetime
DECLARE @nxtstarttime as datetime
DECLARE @nxtendtime as datetime
DECLARE @curtmp as datetime
DECLARE @i as integer
SET @i=1
DECLARE @Componentid as nvarchar(50)
DECLARE @OpnNo as integer

DECLARE @GrpNo AS Integer
DECLARE @CurToolNo as NVarChar(6)
DECLARE @NxtToolNo as NVarChar(6)


DECLARE Rptcursor  cursor for
select starttime,endtime from #tool
open Rptcursor
fetch next from Rptcursor into @curstarttime,@curendtime	

IF (@@fetch_status = 0)
BEGIN
fetch next  from Rptcursor into @nxtstarttime,@nxtendtime	

	while (@@fetch_status = 0)
	BEGIN
	
		set @curendtime = @nxtstarttime
		update #tool set endtime = @curendtime,SeqNo=@i  where starttime=@curstarttime
		SET @i=@i+1

		--ER0400 From Here	
		--	UPDATE #tool SET IdealToolUsage = T2.IdealUsage
		--	FROM
		--	(
		--	 SELECT IdealUsage,Sequenceno  from ToolSequence S INNER JOIN #T1 ON S.ComponentID=#T1.ComponentID AND S.OperationNo=#T1.OpnNo
		--	)as T2 WHERE #tool.SeqNo =T2.Sequenceno

			UPDATE #tool SET IdealToolUsage = T2.IdealUsage
			FROM
			(
			 SELECT IdealUsage,Sequenceno  from ToolSequence S INNER JOIN #T1 ON S.Machineid=#T1.Machineid and S.ComponentID=#T1.ComponentID AND S.OperationNo=#T1.OpnNo
			)as T2 WHERE #tool.SeqNo =T2.Sequenceno
		--ER0400 Till Here	

		SELECT @CurToolNo=Tool From #tool Where StartTime=@curstarttime
		SELECT @GrpNo=GroupNo From #tool Where StartTime=@curstarttime

		SET @curstarttime=@nxtstarttime

		SELECT @NxtToolNo=Tool From #tool Where StartTime=@curstarttime

		IF @NxtToolNo=@CurToolNo
		BEGIN
			Update #tool SET GroupNo=@GrpNo WHERE StartTime=@curstarttime
		END
		ELSE
		BEGIN
			Update #tool SET GroupNo=@GrpNo+1 WHERE StartTime=@curstarttime
		END
		FETCH NEXT  from Rptcursor into @nxtstarttime,@nxtendtime	
		
	END


	UPDATE #tool set endtime=@CycleEnd ,Seqno=@i  where starttime=@curstarttime
	update #tool set toolusage = datediff(SECOND,starttime,endtime)

	--ER0400 From Here	
	--UPDATE #tool SET IdealToolUsage = T2.IdealUsage
	--FROM
	--(
	-- SELECT IdealUsage,Sequenceno  from ToolSequence S INNER JOIN #T1 ON S.ComponentID=#T1.ComponentID AND S.OperationNo=#T1.OpnNo
	--)as T2 WHERE #tool.SeqNo =T2.Sequenceno
	

	UPDATE #tool SET IdealToolUsage = T2.IdealUsage
	FROM
	(
	 SELECT IdealUsage,Sequenceno  from ToolSequence S INNER JOIN #T1 ON S.Machineid=#T1.Machineid and S.ComponentID=#T1.ComponentID AND S.OperationNo=#T1.OpnNo
	)as T2 WHERE #tool.SeqNo =T2.Sequenceno
	--ER0400 Till Here	
END
		
close 	Rptcursor
deallocate Rptcursor	

Update #tool set ActualToolUsage=Isnull(ActualToolUsage,0) + isnull(toolusage,0) --ER0400 i.e Kept ToolUsage in one column before removing ICD and handling PDT interaction.


------------------------ ER0400 Added From Here --------------------------------------------------
/* Fetching Down Records from Tool Cycles */
/* If Down Records of TYPE-1*/
Update #tool set toolusage = isnull(toolusage,0) - isnull(t2.down,0),ICD=isnull(ICD,0) + isnull(t2.down,0) from 
(Select AutoData.mc ,
SUM(datediff(s , autodata.sttime,autodata.ndtime)) as Down,T.starttime,T.endtime
From AutoData inner join #tool T on Autodata.mc=T.machine
Where AutoData.DataType=2
And ( autodata.Sttime > @CycleStart)
And ( autodata.ndtime < @CycleEnd)
AND ( autodata.sttime >= T.starttime)
AND ( autodata.ndtime <= T.endtime)
group by AutoData.mc,T.starttime,T.endtime)T2 inner join #tool on T2.mc=#tool.machine and T2.starttime=#tool.starttime and T2.endtime=#tool.endtime


/* Commented From Here Since there is less possibility of occurence of Type 2,3,4

/* Fetching Down Records from Tool Cycles */
/* If Down Records of TYPE-2*/
Update #tool set toolusage = isnull(toolusage,0) - isnull(t2.down,0) from 
(Select AutoData.mc ,
SUM(
CASE
	When autodata.sttime <= T.starttime Then datediff(s, T.starttime,autodata.ndtime )
	When autodata.sttime > T.starttime Then datediff(s , autodata.sttime,autodata.ndtime)
END) as Down,T.starttime,T.endtime
From AutoData inner join #tool T on Autodata.mc=T.machine
Where AutoData.DataType=2
And ( autodata.Sttime > @CycleStart)
And ( autodata.ndtime < @CycleEnd)
AND ( autodata.sttime < T.starttime)
AND ( autodata.ndtime > T.starttime)
AND ( autodata.ndtime <= T.endtime)
group by AutoData.mc,T.starttime,T.endtime)T2 inner join #tool on T2.mc=#tool.machine and T2.starttime=#tool.starttime and T2.endtime=#tool.endtime

/* If Down Records of TYPE-3*/
Update #tool set toolusage = isnull(toolusage,0) - isnull(t2.down,0) from 
(Select AutoData.mc ,
SUM(CASE
	When autodata.ndtime > T.endtime Then datediff(s,autodata.sttime, T.endtime)
	When autodata.ndtime <=T.endtime Then datediff(s , autodata.sttime,autodata.ndtime)
END) as Down,T.starttime,T.endtime
From AutoData inner join #tool T on Autodata.mc=T.machine
Where AutoData.DataType=2
And ( autodata.Sttime > @CycleStart)
And ( autodata.ndtime < @CycleEnd)
AND (autodata.sttime>= T.starttime)
AND (autodata.ndtime > T.endtime)
AND (autodata.sttime < T.endtime)
group by AutoData.mc,T.starttime,T.endtime)T2 inner join #tool on T2.mc=#tool.machine and T2.starttime=#tool.starttime and T2.endtime=#tool.endtime


/* If Down Records of TYPE-4*/
Update #tool set toolusage = isnull(toolusage,0) - isnull(t2.down,0) from 
(Select AutoData.mc ,
SUM(CASE
	When autodata.sttime >= T.starttime AND autodata.ndtime <= T.endtime Then datediff(s , autodata.sttime,autodata.ndtime)
	When autodata.sttime < T.starttime AND autodata.ndtime > T.starttime AND autodata.ndtime<=T.endtime Then datediff(s, T.starttime,autodata.ndtime )
	When autodata.sttime>=T.starttime And autodata.sttime < T.endtime AND autodata.ndtime > T.endtime Then datediff(s,autodata.sttime, T.endtime )
	When autodata.sttime<T.starttime AND autodata.ndtime>T.endtime   Then datediff(s , T.starttime,T.endtime)
END) as Down,T.starttime,T.endtime
From AutoData inner join #tool T on Autodata.mc=T.machine
Where AutoData.DataType=2
And ( autodata.Sttime > @CycleStart)
And ( autodata.ndtime < @CycleEnd)
AND (autodata.sttime  <  T.starttime)
AND (autodata.ndtime  >  T.endtime)
GROUP BY AUTODATA.mc,T.starttime,T.endtime
)AS T2 inner join #tool on T2.mc=#tool.machine and T2.starttime=#tool.starttime and T2.endtime=#tool.endtime

 Commented Till Here Since there is less possibility of occurence of Type 2,3,4 */


If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
BEGIN

	--mod 4:Get ToolUsage time over lapping with PDT.
	Update #tool set toolusage = isnull(toolusage,0) - isNull(T2.PPDT ,0),PDT= isnull(PDT,0) + isNull(T2.PPDT ,0)
	FROM(
		SELECT T.Machine,T.Starttime,T.Endtime,SUM(CASE
				When T.Starttime >= P.starttime AND T.Endtime <= P.endtime Then datediff(s , T.Starttime,T.Endtime)
				When T.Starttime < P.starttime AND T.Endtime > P.starttime AND T.Endtime<=P.endtime Then datediff(s, P.starttime,T.Endtime )
				When T.Starttime>=P.starttime And T.Starttime < P.endtime AND T.Endtime > P.endtime Then datediff(s,T.Starttime, P.endtime )
				When T.Starttime<P.starttime AND T.Endtime>P.endtime   Then datediff(s , P.starttime,P.endtime)
		END) as PPDT from #tool T
		inner join Machineinformation M on T.Machine=M.interfaceid
		inner jOIN PlannedDownTimes P on P.Machine=M.machineid
		WHERE 
			(
			(T.Starttime >= P.starttime  AND T.Endtime <=P.endtime)
			OR ( T.Starttime < P.starttime  AND T.Endtime <= P.endtime AND T.Endtime > P.starttime )
			OR ( T.Starttime >= P.starttime   AND T.Starttime <P.endtime AND T.Endtime > P.endtime )
			OR ( T.Starttime < P.starttime  AND T.Endtime > P.endtime) )
			AND
			(
			(P.Starttime >= @CycleStart  AND P.Endtime <=@CycleEnd)
			OR ( P.Starttime < @CycleStart  AND P.Endtime <= @CycleEnd AND P.Endtime > @CycleStart )
			OR ( P.Starttime >= @CycleStart   AND P.Starttime <@CycleEnd AND P.Endtime > @CycleEnd )
			OR ( P.Starttime < @CycleStart  AND P.Endtime > @CycleEnd) )
		group by T.Machine,T.Starttime,T.Endtime
	)AS T2 inner join #tool on T2.machine=#tool.machine and T2.starttime=#tool.starttime and T2.endtime=#tool.endtime


	--Handle intearction between ICD and PDT for type 1 Tool record for the selected time period.
	Update #tool set toolusage = isnull(toolusage,0) + isNull(T2.ICDPDT ,0), IPDT = isnull(IPDT,0) + isNull(T2.ICDPDT ,0) from
	(
	Select T1.mc,T1.starttime,T1.Endtime ,SUM(
		CASE 	
			When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1
			When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2
			When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3
			when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as ICDPDT from
	 (
		 Select M.Machineid,A.mc,A.sttime, A.ndtime,T.starttime,T.Endtime from autodata A 
		 inner join #tool T on A.mc=T.machine
		 inner join Machineinformation M on T.machine=M.interfaceid
		 Where A.DataType=2 and (A.sttime >= T.starttime AND A.ndtime <= T.Endtime) 
		 and (@Cyclestart < A.sttime) AND (@CycleEnd > A.ndtime) 
	 )as T1 inner join
	(
		select  T.starttime as ToolStart,T.Endtime as ToolEnd,P.machine,Case when P.starttime<T.starttime then T.starttime else P.starttime end as starttime, 
		case when P.endtime> T.Endtime then T.Endtime else P.endtime end as endtime from dbo.PlannedDownTimes P
		inner join Machineinformation M on P.machine=M.machineid
		inner join #tool T on M.interfaceid=T.machine
		where ((( P.StartTime >=@CycleStart) And ( P.EndTime <=@CycleEnd))
		or (P.StartTime < @CycleStart  and  P.EndTime <= @CycleEnd AND P.EndTime > @CycleStart)
		or (P.StartTime >= @CycleStart  AND P.StartTime <@CycleEnd AND P.EndTime > @CycleEnd)
		or (( P.StartTime <@CycleStart) And ( P.EndTime >@CycleEnd )) )
		AND (
		(T.Starttime >= P.starttime  AND T.Endtime <=P.endtime)
		OR ( T.Starttime < P.starttime  AND T.Endtime <= P.endtime AND T.Endtime > P.starttime )
		OR ( T.Starttime >= P.starttime   AND T.Starttime <P.endtime AND T.Endtime > P.endtime )
		OR ( T.Starttime < P.starttime  AND T.Endtime > P.endtime) )
	)T on T1.machineid=T.machine AND T1.Starttime=T.ToolStart and T1.endtime=T.ToolEnd and
	((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
	or (T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
	or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
	or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )group by T1.mc,T1.starttime,T1.Endtime
	)AS T2 inner join #tool on T2.mc=#tool.machine and T2.starttime=#tool.starttime and T2.endtime=#tool.endtime

/* Commented From Here Since there is less possibility of occurence of Type 2,3,4

	--Handle intearction between ICD and PDT for type 2 Tool record for the selected time period.
	Update #tool set toolusage = isnull(toolusage,0) + isNull(T2.IPDT ,0)from
		(Select T1.mc,T1.starttime,T1.Endtime ,SUM(
		CASE 	
			When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1
			When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2
			When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3
			when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT from
		(
		 Select M.Machineid,A.mc,A.sttime, A.ndtime,T.starttime,T.Endtime from autodata A 
		 inner join #tool T on A.mc=T.machine
		 inner join Machineinformation M on T.machine=M.interfaceid
		 Where A.DataType=2 and (A.sttime< T.starttime AND A.ndtime>T.starttime AND A.ndtime <= T.Endtime) 
		 and (@Cyclestart < A.sttime) AND (@CycleEnd > A.ndtime) 
		)as T1 inner join
		(
		select  T.starttime as ToolStart,T.Endtime as ToolEnd,P.machine,Case when P.starttime<T.starttime then T.starttime else P.starttime end as starttime, 
		case when P.endtime> T.Endtime then T.Endtime else P.endtime end as endtime from dbo.PlannedDownTimes P
		inner join Machineinformation M on P.machine=M.machineid
		inner join #tool T on M.interfaceid=T.machine
		where ((( P.StartTime >=@CycleStart) And ( P.EndTime <=@CycleEnd))
		or (P.StartTime < @CycleStart  and  P.EndTime <= @CycleEnd AND P.EndTime > @CycleStart)
		or (P.StartTime >= @CycleStart  AND P.StartTime <@CycleEnd AND P.EndTime > @CycleEnd)
		or (( P.StartTime <@CycleStart) And ( P.EndTime >@CycleEnd )) )
		AND (
		(T.Starttime >= P.starttime  AND T.Endtime <=P.endtime)
		OR ( T.Starttime < P.starttime  AND T.Endtime <= P.endtime AND T.Endtime > P.starttime )
		OR ( T.Starttime >= P.starttime   AND T.Starttime <P.endtime AND T.Endtime > P.endtime )
		OR ( T.Starttime < P.starttime  AND T.Endtime > P.endtime) )
		)T on T1.machineid=T.machine AND T1.Starttime=T.ToolStart and T1.endtime=T.ToolEnd and
		(( T.StartTime >= @cyclestart ) And ( T.StartTime <  T1.ndtime )) group by T1.mc,T1.starttime,T1.Endtime
	)AS T2 inner join #tool on T2.mc=#tool.machine and T2.starttime=#tool.starttime and T2.endtime=#tool.endtime


	--Handle intearction between ICD and PDT for type 3 Tool record for the selected time period.
	Update #tool set toolusage = isnull(toolusage,0) + isNull(T2.IPDT ,0)from(
	Select T1.mc,T1.starttime,T1.Endtime ,SUM(
		CASE 	
			When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1
			When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2
			When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3
			when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT from
		(
			 Select M.Machineid,A.mc,A.sttime, A.ndtime,T.starttime,T.Endtime from autodata A 
			 inner join #tool T on A.mc=T.machine
			 inner join Machineinformation M on T.machine=M.interfaceid
			 Where A.DataType=2 and (A.sttime>=T.starttime AND A.sttime<T.Endtime AND A.ndtime > T.Endtime) 
			 and (@Cyclestart < A.sttime) AND (@CycleEnd > A.ndtime) 
		)as T1 inner join
		(
			select  T.starttime as ToolStart,T.Endtime as ToolEnd,P.machine,Case when P.starttime<T.starttime then T.starttime else P.starttime end as starttime, 
			case when P.endtime> T.Endtime then T.Endtime else P.endtime end as endtime from dbo.PlannedDownTimes P
			inner join Machineinformation M on P.machine=M.machineid
			inner join #tool T on M.interfaceid=T.machine
			where ((( P.StartTime >=@CycleStart) And ( P.EndTime <=@CycleEnd))
			or (P.StartTime < @CycleStart  and  P.EndTime <= @CycleEnd AND P.EndTime > @CycleStart)
			or (P.StartTime >= @CycleStart  AND P.StartTime <@CycleEnd AND P.EndTime > @CycleEnd)
			or (( P.StartTime <@CycleStart) And ( P.EndTime >@CycleEnd )) )
			AND (
			(T.Starttime >= P.starttime  AND T.Endtime <=P.endtime)
			OR ( T.Starttime < P.starttime  AND T.Endtime <= P.endtime AND T.Endtime > P.starttime )
			OR ( T.Starttime >= P.starttime   AND T.Starttime <P.endtime AND T.Endtime > P.endtime )
			OR ( T.Starttime < P.starttime  AND T.Endtime > P.endtime) )
		)T on T1.machineid=T.machine AND T1.Starttime=T.ToolStart and T1.endtime=T.ToolEnd 
		AND (( T.EndTime > T1.Sttime )And ( T.EndTime <=@Cycleend )) group by T1.mc,T1.starttime,T1.Endtime
		)AS T2 inner join #tool on T2.mc=#tool.machine and T2.starttime=#tool.starttime and T2.endtime=#tool.endtime


	--Handle intearction between ICD and PDT for type 4 Tool record for the selected time period.
	Update #tool set toolusage = isnull(toolusage,0) + isNull(T2.IPDT ,0)from(
		Select T1.mc,T1.starttime,T1.Endtime ,SUM(
		CASE 	
			When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1
			When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2
			When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3
			when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT from
		(
			 Select M.Machineid,A.mc,A.sttime, A.ndtime,T.starttime,T.Endtime from autodata A 
			 inner join #tool T on A.mc=T.machine
			 inner join Machineinformation M on T.machine=M.interfaceid
			 Where A.DataType=2 and (A.sttime<T.starttime and A.ndtime > T.Endtime) 
			 and (@Cyclestart < A.sttime) AND (@CycleEnd > A.ndtime) 
		)as T1 inner join
		(
			select  T.starttime as ToolStart,T.Endtime as ToolEnd,P.machine,Case when P.starttime<T.starttime then T.starttime else P.starttime end as starttime, 
			case when P.endtime> T.Endtime then T.Endtime else P.endtime end as endtime from dbo.PlannedDownTimes P
			inner join Machineinformation M on P.machine=M.machineid
			inner join #tool T on M.interfaceid=T.machine
			where ((( P.StartTime >=@CycleStart) And ( P.EndTime <=@CycleEnd))
			or (P.StartTime < @CycleStart  and  P.EndTime <= @CycleEnd AND P.EndTime > @CycleStart)
			or (P.StartTime >= @CycleStart  AND P.StartTime <@CycleEnd AND P.EndTime > @CycleEnd)
			or (( P.StartTime <@CycleStart) And ( P.EndTime >@CycleEnd )) )
			AND (
			(T.Starttime >= P.starttime  AND T.Endtime <=P.endtime)
			OR ( T.Starttime < P.starttime  AND T.Endtime <= P.endtime AND T.Endtime > P.starttime )
			OR ( T.Starttime >= P.starttime   AND T.Starttime <P.endtime AND T.Endtime > P.endtime )
			OR ( T.Starttime < P.starttime  AND T.Endtime > P.endtime) )
		)T on T1.machineid=T.machine AND T1.Starttime=T.ToolStart and T1.endtime=T.ToolEnd and
		(( T.StartTime >=@Cyclestart) And ( T.EndTime <=@Cycleend )) group by T1.mc,T1.starttime,T1.Endtime 
		)AS T2 inner join #tool on T2.mc=#tool.machine and T2.starttime=#tool.starttime and T2.endtime=#tool.endtime

     Commented From Here Since there is less possibility of occurence of Type 2,3,4 */
end
---- ------------------------ ER0400 Added Till Here --------------------------------------------------

Update #tool Set GActToolUsage=Isnull(GSumAct,0),GIdealToolUsage=ISNULL(GSumIdeal,0) From
(Select  GroupNo,Sum(toolusage)AS GSumAct ,sum(IdealToolUsage) as GSumIdeal From #tool
Group By GroupNo)AS T Inner JOIN #tool on T.GroupNo=#tool.GroupNo

SELECT
machine,
starttime,
endtime,
tool+' - ' As GraphTool,
tool,
SeqNo as ToolSeqNo,
GroupNo,
--toolusage  as ActualToolUsage, --ER0400
ActualToolUsage, --ER0400
GActToolUsage,
IdealToolUsage,
GIdealToolUsage,
--dbo.f_FormatTime(toolusage,@timeformat) as frmtToolUsage, --ER0400
dbo.f_FormatTime(ActualToolUsage,@timeformat) as frmtToolUsage, --ER0400
dbo.f_FormatTime(IdealToolUsage,@timeformat) as frmtIdealToolUsage,
dbo.f_FormatTime(PDT,@timeformat) as PDT,--ER0400
dbo.f_FormatTime(ICD,@timeformat) as ICD,--ER0400
dbo.f_FormatTime(IPDT,@timeformat) as IPDT,--ER0400
dbo.f_FormatTime((ActualToolUsage-ICD),@timeformat) as  NetUsagewithPDT, --ER0400
dbo.f_FormatTime(((ActualToolUsage-ICD-PDT)+IPDT),@timeformat) as NetUsagewithoutPDT --ER0400
FROM #tool

		
drop table #tool

END
