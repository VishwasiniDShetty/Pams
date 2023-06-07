/****** Object:  Procedure [dbo].[s_GetInProcessCycles]    Committed by VersionSQL https://www.versionsql.com ******/

/********************************************************************************************
--ER0394 - SwathiKS - 22/Sep/2014 :: Created New Procedure for L&T, 
a> Select Machinewise Last Processed record from Autodata_Maxtime from that piont check for top 1 Type 11 record in Rawdata.
   Pick mc,comp,opn,opr and cycletime i.e Type 11 starttime to IncomingEndtime.
b> Check for ICD Records i.e Datatype=2 in Autodata_ICD from Type 11 starttime to IncomingEndtime for that Machine.
   If Present then pick mc, comp, opn, opr, ICD Start, ICD End
c> Sumup all Downtimes i.e (ICD cycles) at Machine  level and subtract from Cycletime to get Machiningtime.
d> Loadunload will be difference between LastProcessed record to Type 11 starttime.
e> Handle PDT interaction and ICD-PDT Interaction.
DR0365 - SwathiKS - 21/Jul/2015 :: Ace - Observerd Negative Values while handling ICD-PDT Interaction.   
********************************************************************************************/
--s_GetInProcessCycles '2015-07-15 06:00:00 AM','2015-07-20 10:00:00 AM','MCV4CMD02M'  
CREATE PROCEDURE [dbo].[s_GetInProcessCycles]
	@StartTime datetime,
	@EndTime datetime,
	@MachineID nvarchar(50)
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


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

create table #Inprocesscycles
(
	sttime datetime,
	ndtime datetime,
	msttime datetime,
	mc nvarchar(50),
	comp nvarchar(50),
	opn nvarchar(50),
	opr nvarchar(50),
	[id] bigint,
	datatype int
)

Declare @mc as nvarchar(50)
Declare @curtime as datetime
Select @mc=interfaceid from machineinformation where machineid=@machineid
Select @curtime=getdate()

Insert into #Inprocesscycles(sttime,ndtime,mc,comp,opn,opr,[id],datatype)
select top 1 sttime,@endtime,mc,comp,opn,opr,slno,'11' from rawdata
where sttime>=(Select MAX(endtime)as endtime from Autodata_Maxtime where machineid=@mc) and sttime<=@Curtime
and mc=@mc and datatype=11 order by sttime desc

update #Inprocesscycles set msttime = T1.endtime from
(Select MAX(endtime)as endtime from Autodata_Maxtime where machineid=@mc)T1
where mc=@mc and datatype=11

Insert into #Inprocesscycles(sttime,ndtime,mc,comp,opn,opr,[id],datatype)
select sttime,ndtime,mc,comp,opn,opr,id,'42' from autodata_ICD
where sttime>=(Select sttime from #Inprocesscycles where datatype=11) and ndtime<=(Select ndtime from #Inprocesscycles where datatype=11)
and mc=@mc 

SELECT
componentinformation.componentid AS ComponentID,
componentinformation.description AS description, 
componentoperationpricing.operationno AS OperationNo,
employeeinformation.Employeeid AS OperatorID,
employeeinformation.[name] AS OperatorName,
A.sttime AS sttime,
A.ndtime AS ndtime,
A.msttime as msttime,
Isnull(datediff(s,A.sttime,A.ndtime),0) AS CycleTime,
A.mc as mc,
A.comp as comp,
A.opn as opn,
0 As PDT,
ISNULL(datediff(s,A.msttime,A.sttime),0) AS LoadUnloadTime,
'In Progress Cycle' as Remarks,
ISNULL(componentoperationpricing.cycletime,0)StdCycleTime,
ISNULL(componentoperationpricing.machiningtime,0)StdMachiningTime,
A.id,
0 as  In_Cycle_DownTime,
A.datatype as datatype
INTO #Temp FROM  #Inprocesscycles A 
INNER JOIN machineinformation ON A.mc = machineinformation.InterfaceID 
INNER JOIN componentinformation ON A.comp = componentinformation.InterfaceID 
INNER JOIN componentoperationpricing ON A.opn = componentoperationpricing.InterfaceID
AND componentinformation.componentid =  componentoperationpricing.componentid
and componentoperationpricing.machineid=machineinformation.machineid
INNER JOIN employeeinformation ON A.opr = employeeinformation.interfaceid
WHERE (A.sttime >= @StartTime ) AND (A.sttime < @EndTime )
AND (machineinformation.machineid = N'' + @MachineID + '') 


update #Temp set In_Cycle_DownTime = Isnull(T1.ICD,0),Cycletime = Isnull(Cycletime,0)-Isnull(T1.ICD,0) from
(Select Sum(Datediff(s,sttime,ndtime)) as ICD from #Temp where datatype=42)T1
where datatype=11


If ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y' and (SELECT ValueInInt From CockpitDefaults Where Parameter ='VDG-CycleDefinition')=2)
BEGIN

	UPDATE #Temp set  CycleTime=isnull(CycleTime,0) - isNull(TT.PPDT ,0),LoadUnloadTime = isnull(LoadUnloadTime,0) - isnull(LD,0),PDT=isnull(PDT,0) + isNull(TT.PPDT ,0) + isnull(LD,0)
	FROM(
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
			From #Temp A INNER JOIN machineinformation ON A.mc = machineinformation.InterfaceID  CROSS jOIN PlannedDownTimes T
			WHERE A.datatype=11 and T.Machine=machineinformation.Machineid AND
			((A.msttime >= T.StartTime  AND A.ndtime <=T.EndTime)
			OR ( A.msttime < T.StartTime  AND A.ndtime <= T.EndTime AND A.ndtime > T.StartTime )
			OR ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime AND A.ndtime > T.EndTime )
			OR ( A.msttime < T.StartTime  AND A.ndtime > T.EndTime) )
			and T.PDTStatus = 1   
		group by A.mc,A.comp,A.Opn,A.sttime,A.ndtime,A.msttime
	)
	as TT INNER JOIN #Temp ON TT.mc = #Temp.mc and TT.comp = #Temp.comp and TT.opn = #Temp.opn 
	and TT.sttime=#Temp.sttime and #Temp.ndtime=TT.ndtime where #temp.datatype=11

	/***************************** DR0365 Commented From here ****************************************
	--Handle intearction between ICD and PDT for type 1 production record for the selected time period.
		UPDATE  #Temp set CycleTime =isnull(CycleTime,0) + isNull(TT.IPDT ,0)  	FROM	
		(
		Select T1.mc,T1.comp,T1.opn,T1.sttime,T1.ndtime,SUM(
			CASE 	
				When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1
				When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2
				When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3
				when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4
			END) as IPDT from
		(Select A.mc,A.comp,A.opn,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype from #Temp A
		Where A.DataType=42
		and exists 
			(
			Select B.Sttime,B.NdTime,B.mc,B.comp,B.opn From #Temp B
			Where B.mc = A.mc and
			B.DataType=11 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And
			(B.msttime >= @starttime AND B.ndtime <= @Endtime) and
			(B.sttime <= A.sttime) AND (B.ndtime >= A.ndtime) 
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
		)as TT INNER JOIN #Temp ON TT.mc = #Temp.mc and TT.comp = #Temp.comp and TT.opn = #Temp.opn 
		 where #temp.datatype=11
		***************************** DR0365 Commented Till here ***************************/

	------------------------------------ DR0365 Altered From Here -----------------------------------------
	 --Handle intearction between ICD and PDT for type 1 production record for the selected time period.  
	  UPDATE  #Temp set CycleTime =isnull(CycleTime,0) + isNull(TT.IPDT ,0)  FROM   
	  (  
	  Select T1.mc,T1.comp,T1.opn,T1.sttime,T1.ndtime,T1.cyclestart,T1.Cycleend,SUM(  
	   CASE    
		When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1  
		When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2  
		When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3  
		when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4  
	   END) as IPDT from  
	  (Select A.mc,A.comp,A.opn,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime,A.ndtime, A.datatype,  
	   B.Sttime as CycleStart,B.ndtime as CycleEnd from #Temp A inner join #Temp B on B.mc = A.mc  
	   Where A.DataType=42 and B.DataType=11 
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
	  )as TT INNER JOIN #Temp ON TT.mc = #Temp.mc and TT.comp = #Temp.comp and TT.opn = #Temp.opn   
	   and TT.cyclestart=#Temp.sttime and #Temp.ndtime=TT.Cycleend where #temp.datatype=11  
	   ------------------------------------- DR0365 Altered Till Here ----------------------------------------------

END


insert into #TempCockpitProductionData
select ComponentID,description,OperationNo,OperatorID,OperatorName,sttime,ndtime,CycleTime,mc,comp,opn,PDT,LoadUnloadTime,Remarks,StdCycleTime,StdMachiningTime,id,In_Cycle_DownTime from #Temp
where datatype=11

select * from #TempCockpitProductionData

END
