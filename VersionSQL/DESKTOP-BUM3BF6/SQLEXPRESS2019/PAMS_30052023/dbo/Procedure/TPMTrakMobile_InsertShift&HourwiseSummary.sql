/****** Object:  Procedure [dbo].[TPMTrakMobile_InsertShift&HourwiseSummary]    Committed by VersionSQL https://www.versionsql.com ******/

/*
[dbo].[TPMTrakMobile_InsertShift&HourwiseSummary]     '2021-03-15 07:01:00'
*/
CREATE PROCEDURE [dbo].[TPMTrakMobile_InsertShift&HourwiseSummary]  
@StartDate datetime=''
WITH RECOMPILE
AS
BEGIN
	
SET NOCOUNT ON
DECLARE @update_count int
DECLARE @ErrorCode  int  
DECLARE @ErrorStep  varchar(200)
DECLARE @Return_Message VARCHAR(1024) 
SET @ErrorCode = 0
SET @Return_Message = ''
 

Declare @Date as Datetime
If @StartDate= ''
Begin
	SET @Date=getdate()
End
Else
Begin
	SET @Date=@StartDate
End

Create Table #ShiftwiseSummary  
(  
[Sl No] Bigint Identity(1,1) Not Null, 
[PlantID] nvarchar(50), 
[Machineid] nvarchar(50),  
MachineInterface int,
[ShiftDate] datetime,  
[ShiftName] nvarchar(50),  
[From time] datetime,  
[To Time] datetime,  
RejCount float, 
TotalTime float,
UtilisedTime float,
ManagementLoss float,
DownTime float,
CN float,
ProductionEfficiency float,
AvailabilityEfficiency float,
OverallEfficiency float,
QualityEfficiency float,
Components float,
MLDown float,
[ShiftID] int,
[Status] nvarchar(50),
LastCycletime Datetime,
LastCycleCO nvarchar(100),
LastCycleStart Datetime,
LastCycleEnd Datetime,
ElapsedTime int,
LastCycleSpindleRunTime int,
LastCycleDatatype nvarchar(50),
RunningCycleUT float,
RunningCycleDT float,
RunningCyclePDT float,
RunningCycleML float,
RunningCycleAE float,
MachineStatus nvarchar(100),
NetUtilisedtime float,
NetDowntime float,
PEGreen smallint,
PERed smallint,
AEGreen smallint,
AERed smallint,
OEGreen smallint,
OERed smallint,
QEGreen smallint, 
QERed smallint, 
MaxDownReason nvarchar(50),
OperatorName nvarchar(50)
)  

CREATE TABLE #ShiftDetails   
(  
 SlNo bigint identity(1,1) NOT NULL,
 PDate datetime,  
 Shift nvarchar(20),  
 ShiftStart datetime,  
 ShiftEnd datetime  
)  


Create Table #HourwiseSummary  
(  
	[Sl No] Bigint Identity(1,1) Not Null, 
	[PlantID] nvarchar(50), 
	[Machineid] nvarchar(50),  
	[MachineStatus] nvarchar(100),
	[RunningProgram] nvarchar(100),
	[ShiftDate] datetime,  
	[ShiftName] nvarchar(50),  
	[From time] datetime,  
	[To Time] datetime,  
	[TotalTime] float,
	[Powerontime] float,  
	[Cutting time] float,  
	[Operating time] float,
	[PartsCount] float, 
	[ProgramNo] nvarchar(50),
	[Stoppagetime] float,
	[HourID] int,
	[Shiftid] int
)


CREATE TABLE #HourDetails   
(  
 PDate datetime,  
 Shift nvarchar(20), 
 Shiftid int,
 HourID int, 
 HourStart datetime,  
 HourEnd datetime  
) 

CREATE TABLE #Shift_MachinewiseStoppages
(
	id bigint identity(1,1),
	[PlantID] nvarchar(50),
	[ShiftDate] datetime,  
	[ShiftName] nvarchar(50),  
 	[ShiftID] int,
	Machineid nvarchar(50),
	Fromtime datetime,
	Totime datetime,
	BatchTS	datetime,
	BatchStart datetime,
	BatchEnd datetime,
	Stoppagetime int,
	MachineStatus nvarchar(50),
	Reason nvarchar(50)
	
)



CREATE TABLE #PlannedDownTimesShift
(
	SlNo int not null identity(1,1),
	Starttime datetime,
	EndTime datetime,
	Machine nvarchar(50),
	MachineInterface nvarchar(50),
	DownReason nvarchar(50),
	ShiftSt datetime
)

CREATE TABLE #T_autodata
(
	[mc] [nvarchar](50)not NULL,
	[comp] [nvarchar](50) NULL,
	[opn] [nvarchar](50) NULL,
	[opr] [nvarchar](50) NULL,
	[dcode] [nvarchar](50) NULL,
	[sttime] [datetime] not NULL,
	[ndtime] [datetime] NULL,
	[datatype] [tinyint] NULL ,
	[cycletime] [int] NULL,
	[loadunload] [int] NULL ,
	[msttime] [datetime] NULL,
	--[PartsCount] [int] NULL , --NR0097
	--[PartsCount] decimal(18,5) NULL , --NR0097
	[PartsCount] FLOAT NULL , 
	id  bigint not null
)

create table #Runningpart_Part
(  
 Machineid nvarchar(50),  
 Componentid nvarchar(50),
 StTime Datetime,
 ShiftStart datetime,
 ShiftEnd datetime,
 shiftname nvarchar(50),
 OperatorName nvarchar(50)
)  

Declare @strsql nvarchar(4000)  
Select @strsql = ''  

select @Date= [dbo].[f_GetLogicalDayStart](@date)

INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)   
EXEC s_GetShiftTime @Date,''



Insert into #ShiftwiseSummary (PlantID,Machineid,MachineInterface,ShiftDate,[From time],[To Time],ShiftID,ShiftName,ProductionEfficiency,AvailabilityEfficiency,OverallEfficiency ,UtilisedTime ,ManagementLoss,DownTime ,CN,
PEGreen ,PERed,AEGreen ,AERed ,OEGreen ,OERed,QERed,QEGreen,Components,QualityEfficiency,RejCount,RunningCycleAE)   --SV
SELECT distinct Plantmachine.PlantID,Machineinformation.machineid,Machineinformation.interfaceid, S.PDate,S.shiftstart,S.shiftend,S.ShiftID,S.Shift,0,0,0,0,0,0,0
,isnull(PEGreen,0) ,isnull(PERed,0),isnull(AEGreen,0) ,isnull(AERed,0) ,isnull(OEGreen,0) ,isnull(OERed,0),isnull(QERed,0),isnull(QEGreen,0),0,0,0,0 FROM dbo.Machineinformation  
left outer join dbo.Plantmachine on Machineinformation.machineid=Plantmachine.machineid  
Cross join (Select T.Pdate, T.Shift, S.ShiftID , T.ShiftStart, T.ShiftEnd from #ShiftDetails T inner join Shiftdetails S on S.Shiftname=T.Shift where S.Running=1) S
where Plantmachine.PlantID IS NOT NULL AND Machineinformation.TPMTrakenabled=1 


declare @Counter as datetime
declare @stdate as nvarchar(20)
select @counter=convert(datetime, cast(DATEPART(yyyy,@Date)as nvarchar(4))+'-'+cast(datepart(mm,@Date)as nvarchar(2))+'-'+cast(datepart(dd,@Date)as nvarchar(2)) +' 00:00:00.000')         
select @stdate = CAST(datePart(yyyy,@Date) AS nvarchar(4)) + '-' + CAST(datePart(mm,@Date) AS nvarchar(2)) + '-' + CAST(datePart(dd,@Date) AS nvarchar(2))         

declare @threshold as int
Select @threshold = isnull(ValueInText,5) from Focas_Defaults where parameter='DowntimeThreshold'

If @threshold = '' or @threshold is NULL
Begin
	select @threshold='5'
End

insert  #HourDetails (PDate,Shift,Shiftid,Hourstart,Hourend,HourID)         
select @counter,S.ShiftName, S.Shiftid,       
dateadd(day,SH.Fromday,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.HourStart) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourStart) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourStart) as nvarchar(2))))),         
dateadd(day,SH.Today,(convert(datetime, @stdate + ' ' + CAST(datePart(hh,SH.HourEnd) AS nvarchar(2)) + ':' + CAST(datePart(mi,SH.HourEnd) as nvarchar(2))+ ':' + CAST(datePart(ss,SH.HourEnd) as nvarchar(2))))),SH.HourID       
from (Select distinct ShiftName,Shiftid from #ShiftwiseSummary) S inner join Shifthourdefinition SH on SH.shiftid=S.Shiftid                

Insert into #HourwiseSummary (PlantID,Machineid,ShiftDate,Shiftid,HourID,[From time],[To Time],ShiftName,[Cutting time],Powerontime,[Operating Time],[PartsCount],Stoppagetime)   --SV
SELECT distinct PlantMachine.PlantID,Machineinformation.machineid,S.PDate,S.Shiftid,S.Hourid,S.Hourstart,S.Hourend,S.Shift,0,0,0,0,0 FROM dbo.Machineinformation  
left outer join dbo.Plantmachine on Machineinformation.machineid=Plantmachine.machineid  
Cross join #HourDetails S where Plantmachine.PlantID IS NOT NULL AND Machineinformation.TPMTrakenabled=1 


---mod 12 get the PDT's defined,at shift and Machine level
insert INTO #PlannedDownTimesShift(StartTime,EndTime,Machine,MachineInterface,Downreason,Shiftst)
select
CASE When StartTime<T1.ShiftStart Then T1.ShiftStart Else StartTime End,
case When EndTime>T1.ShiftEnd Then T1.ShiftEnd Else EndTime End,
Machine,M.InterfaceID,
DownReason,T1.ShiftStart
FROM PlannedDownTimes cross join #ShiftDetails T1
inner join MachineInformation M on PlannedDownTimes.machine = M.MachineID
WHERE PDTstatus =1 and (
(StartTime >= T1.ShiftStart  AND EndTime <=T1.ShiftEnd)
OR ( StartTime < T1.ShiftStart  AND EndTime <= T1.ShiftEnd AND EndTime > T1.ShiftStart )
OR ( StartTime >= T1.ShiftStart   AND StartTime <T1.ShiftEnd AND EndTime > T1.ShiftEnd )
OR ( StartTime < T1.ShiftStart  AND EndTime > T1.ShiftEnd) )
and machine in (select distinct machine from #ShiftwiseSummary)
ORDER BY StartTime


declare @T_ST as datetime
declare @T_ED as datetime

select @T_ST= (select top 1 [From Time] from #ShiftwiseSummary order by [From Time])
select @T_ED = (select top 1 [To Time] from #ShiftwiseSummary order by [From Time] desc)

Select @strsql=''
select @strsql ='insert into #T_autodata '
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'
 select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'
select @strsql = @strsql + ' from autodata where (( sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_ED,120)+''' ) OR '
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' )OR '
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ST,120)+'''
				 and ndtime<='''+convert(nvarchar(25),@T_ED,120)+''' )'
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' and sttime<'''+convert(nvarchar(25),@T_ED,120)+''' ) )'
print @strsql
exec (@strsql)

insert into #Runningpart_Part(Machineid,OperatorName,Sttime,ShiftStart)
	select Machineinformation.machineid,E.Name,Max(A.Sttime),[from time] from 
	(
	Select Mc,Opr,Max(sttime) as Sttime,s.[from time] From #T_autodata A 
	inner join #shiftwisesummary s on A.mc = s.machineinterface
	where sttime>=s.[From time] and ndtime<=s.[To Time]
	Group by Mc,Opr,[from time]
	) as A
	inner join Machineinformation on A.mc=Machineinformation.interfaceid  
	inner join Employeeinformation E on A.Opr=E.interfaceid  
group by Machineinformation.machineid,E.Name,[from time]


--select * from #Runningpart_Part

--	select Machineid,OperatorName as opr,sttime,ShiftStart,
--	row_number() over(partition by Machineid,shiftstart order by sttime desc) as rn
--	From #Runningpart_Part 
--	--)T where T.rn <= 1



/******************************************************* SHIFTWISE SUMMARY *********************************************************/

		-------For Type2
		UPDATE  #ShiftwiseSummary SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
		FROM
		(Select AutoData.mc ,
		SUM(
		CASE
		When autodata.sttime <= T1.[From time] Then datediff(s, T1.[From time],autodata.ndtime )
		When autodata.sttime > T1.[From time] Then datediff(s , autodata.sttime,autodata.ndtime)
		END) as Down,t1.[From time] as ShiftStart,T1.ShiftDate as ShiftDate
		from #T_autodata autodata INNER Join
		(Select mc,Sttime,NdTime,[From time],[To Time],ShiftDate from #T_autodata autodata
		inner join #ShiftwiseSummary ST1 ON ST1.MachineInterface=Autodata.mc
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(msttime < [From time])And (ndtime > [From time]) AND (ndtime <= [To Time])
		) as T1 on t1.mc=autodata.mc
		Where AutoData.DataType=2
		And ( autodata.Sttime > T1.Sttime )
		And ( autodata.ndtime <  T1.ndtime )
		AND ( autodata.ndtime >  T1.[From time] )
		GROUP BY AUTODATA.mc,T1.[From time],T1.ShiftDate)AS T2 Inner Join #ShiftwiseSummary on t2.mc = #ShiftwiseSummary.machineinterface
		and T2.ShiftDate = #ShiftwiseSummary.ShiftDate and t2.ShiftStart=#ShiftwiseSummary.[From time]

		--For Type4
		UPDATE  #ShiftwiseSummary SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
		FROM
		(Select AutoData.mc ,
		SUM(CASE
		When autodata.sttime >= T1.[From time] AND autodata.ndtime <= T1.[To Time] Then datediff(s , autodata.sttime,autodata.ndtime)
		When autodata.sttime < T1.[From time] And autodata.ndtime >T1.[From time] AND autodata.ndtime<=T1.[To Time] Then datediff(s, T1.[From time],autodata.ndtime )
		When autodata.sttime >= T1.[From time] AND autodata.sttime<T1.[To Time] AND autodata.ndtime>T1.[To Time] Then datediff(s,autodata.sttime, T1.[To Time] )
		When autodata.sttime<T1.[From time] AND autodata.ndtime>T1.[To Time]   Then datediff(s , T1.[From time],T1.[To Time])
		END) as Down,T1.[From time] as ShiftStart,T1.ShiftDate as ShiftDate
		from #T_autodata autodata INNER Join
		(Select mc,Sttime,NdTime,[From time],[To Time],ShiftDate from #T_autodata autodata
		inner join #ShiftwiseSummary ST1 ON ST1.MachineInterface =Autodata.mc
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(msttime < [From time])And (ndtime >[To Time])
				
		) as T1
		ON AutoData.mc=T1.mc
		Where AutoData.DataType=2
		And (T1.Sttime < autodata.sttime  )
		And ( T1.ndtime >  autodata.ndtime)
		AND (autodata.ndtime  >  T1.[From time])
		AND (autodata.sttime  <  T1.[To Time])
		GROUP BY AUTODATA.mc,T1.[From time],T1.ShiftDate
		)AS T2 Inner Join #ShiftwiseSummary on t2.mc = #ShiftwiseSummary.machineinterface
		and T2.ShiftDate = #ShiftwiseSummary.ShiftDate and t2.ShiftStart=#ShiftwiseSummary.[From time]

		--Type 3
		UPDATE  #ShiftwiseSummary SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
		FROM
		(Select AutoData.mc ,
		SUM(CASE
		When autodata.ndtime > T1.[To Time] Then datediff(s,autodata.sttime, T1.[To Time] )
		When autodata.ndtime <=T1.[To Time] Then datediff(s , autodata.sttime,autodata.ndtime)
		END) as Down,T1.[From time] as ShiftStart,T1.ShiftDate as ShiftDate
		from #T_autodata autodata INNER Join
		(Select mc,Sttime,NdTime,[From time],[To Time],ShiftDate from #T_autodata autodata
		inner join #ShiftwiseSummary ST1 ON ST1.MachineInterface =Autodata.mc
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(sttime >= [From time])And (ndtime >[To Time]) and (sttime< [To Time])
		) as T1
		ON AutoData.mc=T1.mc
		Where AutoData.DataType=2
		And (T1.Sttime < autodata.sttime  )
		And ( T1.ndtime >  autodata.ndtime)
		AND (autodata.sttime  <  T1.[To Time])
		GROUP BY AUTODATA.mc,T1.[From time],T1.ShiftDate )AS T2 Inner Join #ShiftwiseSummary on t2.mc = #ShiftwiseSummary.machineinterface
		and t2.ShiftDate=#ShiftwiseSummary.ShiftDate and t2.ShiftStart=#ShiftwiseSummary.[From time]
		---------------------------------------ER0324 Added Till Here ------------------------------------------------	


		--BEGIN: CN
		--Type 1
		UPDATE #ShiftwiseSummary SET CN = isnull(CN,0) + isNull(t2.C1N1,0)
		from
		(select mc,
		  SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))*autodata.partscount) C1N1,S.ShiftDate as date1,S.[From time] as ShiftStart
		   from #T_autodata autodata INNER JOIN --ER0324 Added
		componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
		componentinformation ON autodata.comp = componentinformation.InterfaceID AND
		componentoperationpricing.componentid = componentinformation.componentid
		---mod 7
		inner join machineinformation on machineinformation.interfaceid=autodata.mc
		and componentoperationpricing.machineid=machineinformation.machineid
		---mod 7
		inner join #ShiftwiseSummary S on autodata.mc=S.MachineInterface
		  where (autodata.sttime>=S.[From time])
			and (autodata.ndtime<=S.[To Time])
			and (autodata.datatype=1)
		  group by autodata.mc,S.ShiftDate,S.[From time]
		) as t2 inner join #ShiftwiseSummary on t2.mc = #ShiftwiseSummary.machineinterface
		and t2.date1=#ShiftwiseSummary.ShiftDate and t2.ShiftStart=#ShiftwiseSummary.[From time]

		--Type 2
		UPDATE #ShiftwiseSummary SET CN = isnull(CN,0) + isNull(t2.C1N1,0)
		from
		(select mc,
		  SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))*autodata.partscount) C1N1,S.ShiftDate as date1,S.[From time] as ShiftStart
		   from #T_autodata autodata INNER JOIN --ER0324 Added
		componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
		componentinformation ON autodata.comp = componentinformation.InterfaceID AND
		componentoperationpricing.componentid = componentinformation.componentid
		---mod 7
		inner join machineinformation on machineinformation.interfaceid=autodata.mc
		and componentoperationpricing.machineid=machineinformation.machineid
		---mod 7
		inner join #ShiftwiseSummary S on autodata.mc=S.MachineInterface
		where (autodata.sttime<S.[From time])
		  and (autodata.ndtime>S.[From time])
		  and (autodata.ndtime<=S.[To Time])
		  and (autodata.datatype=1)
		  group by autodata.mc,S.ShiftDate,S.[From time]
		) as t2 inner join #ShiftwiseSummary on t2.mc = #ShiftwiseSummary.machineinterface
		and t2.date1=#ShiftwiseSummary.ShiftDate and t2.ShiftStart=#ShiftwiseSummary.[From time]

		-- Get the utilised time
		-- Type 1,2,3,4
		UPDATE #ShiftwiseSummary SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
		from
		(select      mc,
		sum(case when ( (autodata.msttime>=S.[From time]) and (autodata.ndtime<=S.[To Time])) then  (cycletime+loadunload)
		 when ((autodata.msttime<S.[From time])and (autodata.ndtime>S.[From time])and (autodata.ndtime<=S.[To Time])) then DateDiff(second, S.[From time], ndtime)
		 when ((autodata.msttime>=S.[From time])and (autodata.msttime<S.[To Time])and (autodata.ndtime>S.[To Time])) then DateDiff(second, mstTime, S.[To Time])
		 when ((autodata.msttime<S.[From time])and (autodata.ndtime>S.[To Time])) then DateDiff(second, S.[From time], S.[To Time]) END ) as cycle,S.[From time] as ShiftStart
		from #T_autodata autodata inner join #ShiftwiseSummary S on autodata.mc=S.MachineInterface --ER0324 Added
		where (autodata.datatype=1) AND(( (autodata.msttime>=S.[From time]) and (autodata.ndtime<=S.[To Time]))
		OR ((autodata.msttime<S.[From time])and (autodata.ndtime>S.[From time])and (autodata.ndtime<=S.[To Time]))
		OR ((autodata.msttime>=S.[From time])and (autodata.msttime<S.[To Time])and (autodata.ndtime>S.[To Time]))
		OR((autodata.msttime<S.[From time])and (autodata.ndtime>S.[To Time])))
		group by autodata.mc,S.[From time]
		) as t2 inner join #ShiftwiseSummary on t2.mc = #ShiftwiseSummary.machineinterface
		and t2.ShiftStart=#ShiftwiseSummary.[From time]


		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
		BEGIN

		--get the utilised time overlapping with PDT and negate it from UtilisedTime
		UPDATE  #ShiftwiseSummary SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.PlanDT,0)
		from( select T.ShiftSt as intime,T.Machine as machine,sum (CASE
		--WHEN (autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN (cycletime+loadunload) --DR0325 Commented
		WHEN (autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN DateDiff(second,autodata.msttime,autodata.ndtime) --DR0325 Added
		WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
		WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )
		WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
		END ) as PlanDT
		from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T --ER0324 Added
		WHERE autodata.DataType=1   and T.MachineInterface=autodata.mc AND(
		(autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
		OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
		OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )
		OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime)
		)
		group by T.Machine,T.ShiftSt ) as t2 inner join #ShiftwiseSummary S on t2.intime=S.[From time] and t2.machine=S.machineId


		---mod 12:Add ICD's Overlapping  with PDT to UtilisedTime
		/* Fetching Down Records from Production Cycle  */
		---mod 12(4):Handle intearction between ICD and PDT for type 1 production record for the selected time period.
		UPDATE  #ShiftwiseSummary SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)
		FROM	(
		Select T.ShiftSt as intime,AutoData.mc,
		SUM(
		CASE 	
			When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
			When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
			When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
			when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		from #T_autodata autodata INNER Join --ER0324 Added
			(Select mc,Sttime,NdTime,S.[From time] as StartTime from #T_autodata autodata inner join #ShiftwiseSummary S on S.MachineInterface=autodata.mc
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(msttime >= S.[From time]) AND (ndtime <= S.[To Time])) as T1
		ON AutoData.mc=T1.mc CROSS jOIN #PlannedDownTimesShift T
		Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc
		And (( autodata.Sttime >= T1.Sttime ) --DR0339
		And ( autodata.ndtime <= T1.ndtime ) --DR0339
		)
		AND
		((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
		or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
		or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
		or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )
		GROUP BY AUTODATA.mc,T.ShiftSt
		)AS T2  INNER JOIN #ShiftwiseSummary ON
		T2.mc = #ShiftwiseSummary.MachineInterface and  t2.intime=#ShiftwiseSummary.[From time]


		---mod 12(4)
		/* If production  Records of TYPE-2*/
		UPDATE  #ShiftwiseSummary SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)
		FROM
		(Select T.ShiftSt as intime,AutoData.mc ,
		SUM(
		CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join --ER0324 Added
		(Select mc,Sttime,NdTime,S.[From time] as StartTime from #T_autodata autodata inner join #ShiftwiseSummary S on S.MachineInterface=autodata.mc
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(msttime < S.[From time])And (ndtime > S.[From time]) AND (ndtime <= S.[To Time])) as T1
		ON AutoData.mc=T1.mc  and T1.StartTime=T.ShiftSt
		Where AutoData.DataType=2  and T.MachineInterface=autodata.mc
		And (( autodata.Sttime > T1.Sttime )
		And ( autodata.ndtime <  T1.ndtime )
		AND ( autodata.ndtime >  T1.StartTime ))
		AND
		(( T.StartTime >= T1.StartTime )
		And ( T.StartTime <  T1.ndtime ) )
		GROUP BY AUTODATA.mc,T.ShiftSt )AS T2  INNER JOIN #ShiftwiseSummary ON
		T2.mc = #ShiftwiseSummary.MachineInterface and  t2.intime=#ShiftwiseSummary.[From time]



		/* If production Records of TYPE-3*/
		UPDATE  #ShiftwiseSummary SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)
		FROM
		(Select T.ShiftSt as intime,AutoData.mc ,
		SUM(
		CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join --ER0324 Added
		(Select mc,Sttime,NdTime,S.[From time] as StartTime,S.[To Time] as EndTime from #T_autodata autodata inner join #ShiftwiseSummary S on S.MachineInterface=autodata.mc
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(sttime >= S.[From time])And (ndtime > S.[To Time]) and autodata.sttime <S.[To Time]) as T1
		ON AutoData.mc=T1.mc and T1.StartTime=T.ShiftSt
		Where AutoData.DataType=2  and T.MachineInterface=autodata.mc
		And ((T1.Sttime < autodata.sttime  )
		And ( T1.ndtime >  autodata.ndtime)
		AND (autodata.sttime  <  T1.EndTime))
		AND
		(( T.EndTime > T1.Sttime )
		And ( T.EndTime <=T1.EndTime ) )
		GROUP BY AUTODATA.mc,T.ShiftSt)AS T2   INNER JOIN #ShiftwiseSummary ON
		T2.mc = #ShiftwiseSummary.MachineInterface and  t2.intime=#ShiftwiseSummary.[From time]



		/* If production Records of TYPE-4*/
		UPDATE  #ShiftwiseSummary SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)
		FROM
		(Select T.ShiftSt as intime,AutoData.mc ,
		SUM(
		CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join --ER0324 Added
		(Select mc,Sttime,NdTime,S.[From time] as StartTime,S.[To Time] as EndTime from #T_autodata autodata inner join #ShiftwiseSummary S on S.MachineInterface=autodata.mc
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(msttime < S.[From time])And (ndtime > S.[To Time])) as T1
		ON AutoData.mc=T1.mc and T1.StartTime=T.ShiftSt
		Where AutoData.DataType=2 and T.MachineInterface=autodata.mc
		And ( (T1.Sttime < autodata.sttime  )
		And ( T1.ndtime >  autodata.ndtime)
		AND (autodata.ndtime  >  T1.StartTime)
		AND (autodata.sttime  <  T1.EndTime))
		AND
		(( T.StartTime >=T1.StartTime)
		And ( T.EndTime <=T1.EndTime ) )
		GROUP BY AUTODATA.mc,T.ShiftSt)AS T2  INNER JOIN #ShiftwiseSummary ON
		T2.mc = #ShiftwiseSummary.MachineInterface and  t2.intime=#ShiftwiseSummary.[From time]

		END


		---Mod 12 Apply PDT for Utilized time and ICD's
		---mod 12 Apply PDT for CN calculation
		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
		BEGIN
		UPDATE #ShiftwiseSummary SET CN = isnull(CN,0) - isNull(t2.C1N1,0)
		From
		(
		select M.Machineid as machine,T.Shiftst as initime,SUM((O.cycletime * ISNULL(A.PartsCount,1))/ISNULL(O.SubOperations,1))  C1N1
		from #T_autodata  A inner join machineinformation M on A.mc=M.interfaceid --ER0324 Added
		Inner join componentinformation C ON A.Comp=C.interfaceid
		Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid AND O.Machineid=M.Machineid --DR0299 Sneha K
		CROSS jOIN #PlannedDownTimesShift T
		WHERE A.DataType=1 and T.MachineInterface=A.mc
		AND(A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)
		Group by M.Machineid,T.shiftst
		) as T2
		inner join #ShiftwiseSummary S  on t2.initime=S.[From time]  and t2.machine = S.machineid
		END

		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y')
		BEGIN
		--Type 1
		UPDATE #ShiftwiseSummary SET downtime = isnull(downtime,0) + isNull(t2.down,0)
		from
		(select mc,
		sum(loadunload) down,S.[From time] as ShiftStart
		from #T_autodata autodata inner join #ShiftwiseSummary S on autodata.mc=S.MachineInterface --ER0324 Added
		where (autodata.msttime>=S.[From time])
		and (autodata.ndtime<= S.[To Time])
		and (autodata.datatype=2)
		group by autodata.mc,S.[From time]
		) as t2 inner join #ShiftwiseSummary on t2.mc = #ShiftwiseSummary.machineinterface
		and t2.ShiftStart=#ShiftwiseSummary.[From time]

		-- Type 2
		UPDATE #ShiftwiseSummary SET downtime = isnull(downtime,0) + isNull(t2.down,0)
		from
		(select mc,
		sum(DateDiff(second, S.[From time], ndtime)) down,S.[From time] as ShiftStart
		from #T_autodata autodata inner join #ShiftwiseSummary S on autodata.mc=S.MachineInterface --ER0324 Added
		where (autodata.sttime<S.[From time])
		and (autodata.ndtime>S.[From time])
		and (autodata.ndtime<= S.[To Time])
		and (autodata.datatype=2)
		group by autodata.mc,S.[From time]
		) as t2 inner join #ShiftwiseSummary on t2.mc = #ShiftwiseSummary.machineinterface
		and t2.ShiftStart=#ShiftwiseSummary.[From time]


		-- Type 3
		UPDATE #ShiftwiseSummary SET downtime = isnull(downtime,0) + isNull(t2.down,0)
		from
		(select mc,
		sum(DateDiff(second, stTime,  S.[To Time])) down,S.[From time] as ShiftStart
		from #T_autodata autodata inner join #ShiftwiseSummary S on autodata.mc=S.MachineInterface --ER0324 Added
		where (autodata.msttime>=S.[From time])
		and (autodata.sttime< S.[To Time])
		and (autodata.ndtime> S.[To Time])
		and (autodata.datatype=2)group by autodata.mc,S.[From time]
		) as t2 inner join #ShiftwiseSummary on t2.mc = #ShiftwiseSummary.machineinterface
		and t2.ShiftStart=#ShiftwiseSummary.[From time]


		-- Type 4
		UPDATE #ShiftwiseSummary SET downtime = isnull(downtime,0) + isNull(t2.down,0)
		from
		(select mc,
		sum(DateDiff(second, S.[From time],  S.[To Time])) down,S.[From time] as ShiftStart
		from #T_autodata autodata inner join #ShiftwiseSummary S on autodata.mc=S.MachineInterface --ER0324 Added
		where autodata.msttime<S.[From time]
		and autodata.ndtime> S.[To Time]
		and (autodata.datatype=2)group by autodata.mc,S.[From time]
		) as t2 inner join #ShiftwiseSummary on t2.mc = #ShiftwiseSummary.machineinterface
		and t2.ShiftStart=#ShiftwiseSummary.[From time]
		--END: Get the Down Time

		---Management Loss-----
		-- Type 1
		UPDATE #ShiftwiseSummary SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
		from
		(select      mc,
		sum(CASE
		WHEN loadunload >ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)
		ELSE loadunload
		END) loss,S.[From time] as ShiftStart
		from #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid inner join #ShiftwiseSummary S on autodata.mc=S.MachineInterface --ER0324 Added
		where (autodata.msttime>=S.[From time])
		and (autodata.ndtime<=S.[To Time])
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1)
		group by autodata.mc,S.[From time]
		) as t2 inner join #ShiftwiseSummary on t2.mc = #ShiftwiseSummary.machineinterface
		and t2.ShiftStart=#ShiftwiseSummary.[From time]

		-- Type 2
		UPDATE #ShiftwiseSummary SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
		from
		(select      mc,
		sum(CASE
		WHEN DateDiff(second, S.[From time], ndtime)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)
		ELSE DateDiff(second, S.[From time], ndtime)
		end) loss,S.[From time] as ShiftStart
		from #T_autodata autodata --ER0324 Added
		INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid inner join #ShiftwiseSummary S on autodata.mc=S.MachineInterface
		where (autodata.sttime<S.[From time])
		and (autodata.ndtime>S.[From time])
		and (autodata.ndtime<=S.[To Time])
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1)
		group by autodata.mc,S.[From time]
		) as t2 inner join #ShiftwiseSummary on t2.mc = #ShiftwiseSummary.machineinterface
		and t2.ShiftStart=#ShiftwiseSummary.[From time]

		-- Type 3
		UPDATE #ShiftwiseSummary SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
		from
		(select      mc,
		sum(CASE
		WHEN DateDiff(second, stTime, S.[To Time])>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)ELSE DateDiff(second, stTime, S.[To Time])
		END) loss,S.[From time] as ShiftStart
		from #T_autodata autodata  --ER0324 Added
		INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid inner join #ShiftwiseSummary S on autodata.mc=S.MachineInterface
		where (autodata.msttime>=S.[From time])
		and (autodata.sttime<S.[To Time])
		and (autodata.ndtime>S.[To Time])
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1)
		group by autodata.mc,S.[From time]
		) as t2 inner join #ShiftwiseSummary on t2.mc = #ShiftwiseSummary.machineinterface
		and t2.ShiftStart=#ShiftwiseSummary.[From time]

		-- Type 4
		UPDATE #ShiftwiseSummary SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
		from
		(select mc,
		sum(CASE
		WHEN DateDiff(second, S.[From time], S.[To Time])>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)
		ELSE DateDiff(second, S.[From time], S.[To Time])
		END) loss,S.[From time] as ShiftStart
		from #T_autodata autodata --ER0324 Added
		INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid inner join #ShiftwiseSummary S on autodata.mc=S.MachineInterface
		where autodata.msttime<S.[From time]
		and autodata.ndtime>S.[To Time]
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1)
		group by autodata.mc,S.[From time]
		) as t2 inner join #ShiftwiseSummary on t2.mc = #ShiftwiseSummary.machineinterface
		and t2.ShiftStart=#ShiftwiseSummary.[From time]


		if (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y'
		begin

		UPDATE #ShiftwiseSummary SET downtime = isnull(downtime,0) - isNull(t2.PldDown,0)
		from(
		select T.Shiftst  as intime,T.Machine as machine,SUM
			   (CASE
			WHEN (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN autodata.loadunload
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PldDown
		from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T --ER0324 Added
		INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID
		WHERE autodata.DataType=2  and T.MachineInterface=autodata.mc  AND(
		(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
		OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
		OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
		OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
		)
		AND DownCodeInformation.DownID=(SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')
		group by T.Machine,T.ShiftSt ) as t2 inner join #ShiftwiseSummary S on t2.intime=S.[From time] and t2.machine=S.machineId

		end
		END


		---mod 12:Get the down time and Management loss when setting for 'Ignore_Dtime_4m_PLD'='Y'
		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
		BEGIN
		---Get the down times which are not of type Management Loss
		UPDATE #ShiftwiseSummary SET downtime = isnull(downtime,0) + isNull(t2.down,0)
		from
		(select      mc,
		sum(case when ( (autodata.msttime>=S.[From time]) and (autodata.ndtime<=S.[To Time])) then  loadunload
			 when ((autodata.sttime<S.[From time])and (autodata.ndtime>S.[From time])and (autodata.ndtime<=S.[To Time])) then DateDiff(second, S.[From time], ndtime)
			 when ((autodata.msttime>=S.[From time])and (autodata.msttime<S.[To Time])and (autodata.ndtime>S.[To Time])) then DateDiff(second, stTime, S.[To Time])
			 when ((autodata.msttime<S.[From time])and (autodata.ndtime>S.[To Time])) then DateDiff(second, S.[From time], S.[To Time]) END ) as down,S.[From time] as ShiftStart
		from #T_autodata autodata --ER0324 Added
		inner join #ShiftwiseSummary S on autodata.mc=S.MachineInterface
		inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		where (autodata.datatype=2) AND(( (autodata.msttime>=S.[From time]) and (autodata.ndtime<=S.[To Time]))
		  OR ((autodata.msttime<S.[From time])and (autodata.ndtime>S.[From time])and (autodata.ndtime<=S.[To Time]))
		  OR ((autodata.msttime>=S.[From time])and (autodata.msttime<S.[To Time])and (autodata.ndtime>S.[To Time]))
		  OR((autodata.msttime<S.[From time])and (autodata.ndtime>S.[To Time]))) AND (downcodeinformation.availeffy = 0)
		  group by autodata.mc,S.[From time]
		) as t2 inner join #ShiftwiseSummary on t2.mc = #ShiftwiseSummary.machineinterface
		and t2.ShiftStart=#ShiftwiseSummary.[From time]

		UPDATE #ShiftwiseSummary SET downtime = isnull(downtime,0) - isNull(t2.PldDown,0)
		from(
		select T.Shiftst  as intime,T.Machine as machine,SUM
			   (CASE
			WHEN (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN autodata.loadunload
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PldDown
		from #T_autodata autodata  --ER0324 Added
		CROSS jOIN #PlannedDownTimesShift T
		INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID
		WHERE autodata.DataType=2  and T.MachineInterface=autodata.mc  AND(
		(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
		OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
		OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
		OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
		)
		AND (downcodeinformation.availeffy = 0)
		group by T.Machine,T.ShiftSt ) as t2 inner join #ShiftwiseSummary S on t2.intime=S.[From time] and t2.machine=S.machineId


		UPDATE #ShiftwiseSummary SET ManagementLoss = isnull(ManagementLoss,0)+ isNull(t4.Mloss,0),MLDown=isNull(MLDown,0)+isNull(t4.Dloss,0)
		from
		(select T3.mc,T3.StrtShft,sum(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss from
		(
		select   t1.id,T1.mc,T1.Threshold,T1.StartShift as StrtShft,
		case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0) > 0
		then DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)- isnull(T1.Threshold ,0)
		else 0 End  as Dloss,
		case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0) > 0
		then isnull(T1.Threshold,0)
		else DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0) End  as Mloss
		from

		(   select id,mc,comp,opn,opr,D.threshold,S.[From time] as StartShift,
		case when autodata.sttime<S.[From time] then S.[From time] else sttime END as sttime,
   			case when ndtime>S.[To Time] then S.[To Time] else ndtime END as ndtime
		from #T_autodata autodata --ER0324 Added
		inner join downcodeinformation D
		on autodata.dcode=D.interfaceid inner join #ShiftwiseSummary S on autodata.mc=S.MachineInterface
		where autodata.datatype=2 AND
		(
		(autodata.msttime>=S.[From time]  and  autodata.ndtime<=S.[To Time])
		OR (autodata.sttime<S.[From time] and  autodata.ndtime>S.[From time] and autodata.ndtime<=S.[To Time])
		OR (autodata.msttime>=S.[From time]  and autodata.sttime<S.[To Time]  and autodata.ndtime>S.[To Time])
		OR (autodata.msttime<S.[From time] and autodata.ndtime>S.[To Time] )
		) AND (D.availeffy = 1)) as T1 	
		left outer join
		(SELECT T.Shiftst  as intime, autodata.id,
			   sum(CASE
			WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PPDT
		from #T_autodata autodata  --ER0324 Added
		CROSS jOIN #PlannedDownTimesShift T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		WHERE autodata.DataType=2 and T.MachineInterface=autodata.mc AND
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)
			 AND (downcodeinformation.availeffy = 1) group by autodata.id,T.Shiftst ) as T2 on T1.id=T2.id  and T1.StartShift=T2.intime ) as T3  group by T3.mc,T3.StrtShft
		) as t4 inner join #ShiftwiseSummary S on t4.StrtShft=S.[From time] and t4.mc=S.MachineInterface
		UPDATE #ShiftwiseSummary  set downtime = isnull(downtime,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)

		END

		--Mod 4
		--Calculation of PartsCount Begins..
		UPDATE #ShiftwiseSummary SET components = ISNULL(components,0) + ISNULL(t2.comp,0)
		From
		(  
		Select mc,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp, T1.[From time],T1.[To Time]
		   From (select mc,SUM(autodata.partscount)AS OrginalCount,comp,opn ,S.[From time],S.[To Time] from #T_autodata autodata 
		   inner join #ShiftwiseSummary S on autodata.mc=S.MachineInterface
		   where (autodata.ndtime>S.[From time]) and (autodata.ndtime<=S.[To Time]) and (autodata.datatype=1)
		   Group By mc,comp,opn,S.[From time],S.[To Time]) as T1 
		Inner join componentinformation C on T1.Comp = C.interfaceid
		Inner join ComponentOperationPricing O ON  T1.Opn = O.interfaceid and C.Componentid=O.componentid
		---mod 2
		inner join machineinformation on machineinformation.machineid =O.machineid
		and T1.mc=machineinformation.interfaceid
		---mod 2
		GROUP BY mc,T1.[From time],T1.[To Time]
		) As T2 Inner join #ShiftwiseSummary on T2.mc = #ShiftwiseSummary.machineinterface and #ShiftwiseSummary.[From time] = T2.[From time] 
		and #ShiftwiseSummary.[To Time] = T2.[To Time]



		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
		BEGIN
		UPDATE #ShiftwiseSummary SET components = ISNULL(components,0) - ISNULL(T2.comp,0) from(
		select mc,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp,T1.[From time],T1.[To Time] From ( --NR0097
			select mc,Sum(ISNULL(PartsCount,1))AS OrginalCount,comp,opn,S.[From time],S.[To Time]  from #T_autodata autodata
			 inner join #ShiftwiseSummary S on autodata.mc=S.MachineInterface
			CROSS JOIN #PlannedDownTimesShift T
			WHERE autodata.DataType=1 And T.MachineInterface = autodata.mc
			AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)
			AND (autodata.ndtime > S.[From time]  AND autodata.ndtime <=S.[To Time] )
			Group by mc,comp,opn,S.[From time],S.[To Time]
		) as T1
		Inner join Machineinformation M on M.interfaceID = T1.mc
		Inner join componentinformation C on T1.Comp=C.interfaceid
		Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineID = M.MachineID
		GROUP BY MC,T1.[From time],T1.[To Time]
		) as T2 inner join #ShiftwiseSummary on T2.mc = #ShiftwiseSummary.machineinterface and #ShiftwiseSummary.[From time] = T2.[From time]
		and #ShiftwiseSummary.[To Time]= T2.[To Time]
		END
		--Mod 4
		--Calculation of PartsCount Ends..

		Update #ShiftwiseSummary set RejCount = isnull(RejCount,0) + isnull(T1.RejQty,0)
		From
		( Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid,s.[From time] from AutodataRejections A
		inner join Machineinformation M on A.mc=M.interfaceid
		inner join #ShiftwiseSummary S on S.machineid=M.machineid 
		inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
		where A.CreatedTS>=S.[From time] and A.CreatedTS<S.[To Time] and A.flag = 'Rejection'
		and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000'
		group by A.mc,M.Machineid,S.[From time]
		)T1 inner join #ShiftwiseSummary B on B.Machineid=T1.Machineid and B.[From time]=T1.[From time]


		

		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
		BEGIN
		Update #ShiftwiseSummary set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from
		(Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid,S.[From time] from AutodataRejections A
		inner join Machineinformation M on A.mc=M.interfaceid
		inner join #ShiftwiseSummary S on S.machineid=M.machineid 
		inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
		Cross join Planneddowntimes P
		where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid 
		and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000' and
		A.CreatedTS>=S.[From time] and A.CreatedTS<S.[To Time] And
		A.CreatedTS>=P.Starttime and A.CreatedTS<P.endtime
		group by A.mc,M.Machineid,S.[From time])T1 inner join #ShiftwiseSummary B on B.Machineid=T1.Machineid and B.[From time]=T1.[From time]
		END

		Update #ShiftwiseSummary set RejCount = isnull(RejCount,0) + isnull(T1.RejQty,0)
		From
		( Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid,S.[From time]	 from AutodataRejections A
		inner join Machineinformation M on A.mc=M.interfaceid
		inner join #ShiftwiseSummary S on S.machineid=M.machineid and convert(nvarchar(10),(A.RejDate),126)=convert(nvarchar(10),S.shiftdate,126) and A.RejShift=S.shiftid --DR0333
		inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid	
		where A.flag = 'Rejection' and A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (convert(nvarchar(10),S.shiftdate,126)) and  --DR0333
		Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
		group by A.mc,M.Machineid,S.[From time]
		)T1 inner join #ShiftwiseSummary B on B.Machineid=T1.Machineid and B.[From time]=T1.[From time]



		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
		BEGIN
		Update #ShiftwiseSummary set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from
		(Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid,S.[From time] from AutodataRejections A
		inner join Machineinformation M on A.mc=M.interfaceid
		inner join #ShiftwiseSummary S on S.machineid=M.machineid and convert(nvarchar(10),(A.RejDate),126)=convert(nvarchar(10),S.shiftdate,126) and A.RejShift=S.shiftid
		inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
		Cross join Planneddowntimes P
		where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid and
		A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (convert(nvarchar(10),S.shiftdate,126)) and --DR0333
		Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
		and P.starttime>=S.[From time] and P.Endtime<=S.[To Time]
		group by A.mc,M.Machineid,S.[From time])T1 inner join #ShiftwiseSummary B on B.Machineid=T1.Machineid and B.[From time]=T1.[From time]
		END

		UPDATE #ShiftwiseSummary SET QualityEfficiency= ISNULL(QualityEfficiency,1) + IsNull(T1.QE,1) 
		FROM(Select MachineID,[from time],
		CAST((Sum(Components))As Float)/CAST((Sum(IsNull(Components,0))+Sum(IsNull(RejCount,0))) AS Float)As QE
		From #ShiftwiseSummary Where Components<>0 Group By MachineID,[From time]
		)AS T1 Inner Join #ShiftwiseSummary B on B.Machineid=T1.Machineid and B.[From time]=T1.[From time]




		UPDATE #ShiftwiseSummary SET
		ProductionEfficiency = (CN/UtilisedTime) ,
		AvailabilityEfficiency = (UtilisedTime)/(UtilisedTime + DownTime - ManagementLoss)
		WHERE UtilisedTime <> 0

		UPDATE #ShiftwiseSummary SET NetDowntime=DownTime-ManagementLoss

		UPDATE #ShiftwiseSummary
		SET
		OverAllEfficiency = (ProductionEfficiency * AvailabilityEfficiency * ISNULL(QualityEfficiency,1))*100,
		ProductionEfficiency = ProductionEfficiency * 100 ,
		AvailabilityEfficiency = AvailabilityEfficiency * 100,
		QualityEfficiency = QualityEfficiency*100

		update #ShiftwiseSummary set TotalTime = DateDiff(second, [From time],[To Time] )


		--Update #ShiftwiseSummary Set Lastcycletime = T1.LastCycle  from 
		--(
		--Select A.Machineid,A.Endtime as LastCycle,#ShiftwiseSummary.[From time] from Autodata_MaxTime A
		--inner join #ShiftwiseSummary on A.Machineid = #ShiftwiseSummary.machineinterface
		--where A.Starttime>=#ShiftwiseSummary.[From time] and A.Endtime<=#ShiftwiseSummary.[To Time]
		--) T1 inner join #ShiftwiseSummary on T1.MachineID = #ShiftwiseSummary.machineinterface and #ShiftwiseSummary.[From time] = T1.[From time]

		--update #ShiftwiseSummary set Operator=T1.Name from
		--(
		--Select mc,comp as Comp,opn,opr,E.Name,#ShiftwiseSummary.[From time],[To Time] from autodata A
		--inner join #ShiftwiseSummary on A.mc = #ShiftwiseSummary.machineinterface
		--LEFT OUTER JOIN employeeinformation E ON E.interfaceid=A.opr
		--) T1 inner join #ShiftwiseSummary on T1.mc = #ShiftwiseSummary.machineinterface and #ShiftwiseSummary.[From time] = T1.[From time] AND #ShiftwiseSummary.[To Time]=T1.[To Time]
	
		Create table #AE  
		(  
		mc nvarchar(50),  
		dcode nvarchar(50),  
		sttime datetime,  
		ndtime datetime,  
		Loadunload float,  
		CycleStart datetime,  
		CycleEnd datetime,  
		TotalTime float,  
		UT float,  
		Downtime float,  
		PDT float,  
		ManagementLoss float,  
		MLDown float,  
		id bigint,  
		datatype nvarchar(50),
		ShiftStart datetime,
		ShiftEnd datetime  
		)  
 
		CREATE TABLE #MachineRunningStatus
		(
		MachineID NvarChar(50),
		MachineInterface nvarchar(50),
		sttime Datetime,
		ndtime Datetime,
		DataType smallint,
		ColorCode varchar(10),
		Comp NvarChar(50), 
		Opn NvarChar(50), 
		StartTime datetime, 
		Downtime float, 
		Totaltime int, 
		ManagementLoss float, 
		UT float,
		PDT float,
		LastRecorddatatype int, 
		AutodataMaxtime datetime,
		ShiftStart datetime,
		ShiftEnd datetime 
		) 

		Create table #PlannedDownTimes
		(
		MachineID nvarchar(50) NOT NULL, 
		MachineInterface nvarchar(50) NOT NULL, 
		StartTime DateTime NOT NULL,
		EndTime DateTime NOT NULL, 
		ShiftStart datetime,
		)

		Declare @Type40Threshold int
		Declare @Type1Threshold int
		Declare @Type11Threshold int

		Set @Type40Threshold =0
		Set @Type1Threshold = 0
		Set @Type11Threshold = 0

		Set @Type40Threshold = (Select isnull(Valueintext2,5)*60 from shopdefaults where parameter='ANDONStatusThreshold' and valueintext = 'Type40Threshold')
		Set @Type1Threshold = (Select isnull(Valueintext2,5)*60 from shopdefaults where parameter='ANDONStatusThreshold' and valueintext = 'Type1Threshold')
		Set @Type11Threshold = (Select isnull(Valueintext2,5)*60 from shopdefaults where parameter='ANDONStatusThreshold' and valueintext = 'Type11Threshold')

		Declare @currtime as datetime
		Set @CurrTime = getdate()--case when @CurrTime>@EndTime then @EndTime else @CurrTime end  
  
		---Query to get Machinewise Last Record from Rawdata where Datatype in 11  
		Insert into #machineRunningStatus(MachineID,MachineInterface,AutodataMaxtime,sttime,DataType,Comp,Opn,Totaltime,Downtime,UT,ShiftStart,ShiftEnd)  
		select fd.MachineID,fd.MachineInterface,A.Endtime,case when sttime<fd.[From time] then fd.[From time] else sttime end,datatype,comp,opn,0,0,0,fd.[From time],fd.[To Time] from rawdata  
		inner join (select rawdata.mc,max(rawdata.slno) as slno,S.[From time] from rawdata WITH (NOLOCK)   
		inner join Autodata_maxtime A on rawdata.mc=A.machineid 
		inner join #ShiftwiseSummary S on RawData.mc=S.MachineInterface 
		where (Rawdata.sttime>A.Endtime and Rawdata.sttime>=S.[From time] and rawdata.sttime<=S.[To Time]) and rawdata.datatype=11 group by rawdata.mc,S.[From time]) t1   
		on t1.mc=rawdata.mc and t1.slno=rawdata.slno  
		inner join Autodata_maxtime A on rawdata.mc=A.machineid  
		right outer join #ShiftwiseSummary fd on fd.MachineInterface = t1.mc and fd.[From time]=t1.[From time] 
		where (Rawdata.sttime>A.Endtime and Rawdata.sttime>=fd.[From time] and rawdata.sttime<=fd.[To Time]) and rawdata.datatype=11   
		order by rawdata.mc  
  


		Update #machineRunningStatus set UT=ISNULL(T1.UT,0),Downtime=ISNULL(T1.Dt,0) from  
		(Select MachineInterface,ShiftStart,case when AutodataMaxtime<sttime then (O.cycletime-O.machiningtime) end as UT,  
		case when dateadd(second,(O.cycletime-O.machiningtime),AutodataMaxtime)<sttime then datediff(second,dateadd(second,(O.cycletime-O.machiningtime),AutodataMaxtime),sttime) end as DT   
		from #MachineRunningStatus  
		inner join machineinformation M on #MachineRunningStatus.MachineInterface=M.InterfaceID   
		inner join componentinformation C on C.InterfaceID=#MachineRunningStatus.Comp  
		inner join componentoperationpricing O on O.componentid=C.componentid and M.machineid=O.machineid and   
		#MachineRunningStatus.Opn=O.InterfaceID)T1 inner join #machineRunningStatus on T1.MachineInterface=#machineRunningStatus.MachineInterface 
		and T1.ShiftStart=#MachineRunningStatus.ShiftStart 
  
		Update #machineRunningStatus set ndtime = case when T1.Endtime>T1.ShiftEnd then T1.ShiftEnd else T1.Endtime end,LastRecorddatatype=T1.LastRecorddatatype from  
		(select rawdata.mc,rawdata.datatype,case when rawdata.datatype=40 then dateadd(second,@type40threshold,rawdata.sttime)  
		when rawdata.datatype=42 then rawdata.ndtime  
		when rawdata.datatype=41 then rawdata.sttime   
		else M.ShiftEnd end as endtime,  
		case when rawdata.datatype in(40,41,42) then RawData.DataType   
		else 11 end as LastRecorddatatype,M.ShiftStart,M.ShiftEnd from  
		(  
		select rawdata.mc,max(rawdata.slno) as slno,M.ShiftStart from rawdata   
		inner join #machineRunningStatus M on M.MachineInterface=rawdata.mc  
		where rawdata.datatype in(40,41,42) and (rawdata.sttime>M.sttime and rawdata.sttime>=M.shiftstart and ISNULL(Rawdata.ndtime,Rawdata.sttime)<=M.ShiftEnd) 
		 group by rawdata.mc,M.ShiftStart
		)T1  inner join rawdata on rawdata.slno=t1.slno  
		inner join #machineRunningStatus M on M.MachineInterface=rawdata.mc and t1.ShiftStart=M.ShiftStart
		)T1 inner join #machineRunningStatus on #machineRunningStatus.MachineInterface=T1.mc  and t1.ShiftStart=#MachineRunningStatus.ShiftStart
  
		update  #machineRunningStatus set ndtime=ShiftEnd,LastRecorddatatype=11 where ndtime IS NULL  


		Insert into #AE(mc,dcode,sttime,ndtime,Loadunload,CycleStart,CycleEnd,TotalTime,UT,Downtime,PDT,ManagementLoss,MLDown,id,datatype,ShiftStart,ShiftEnd)  
		Select M.MachineInterface,A.dcode,A.sttime,A.ndtime,A.Loadunload,M.sttime,M.ndtime,M.Totaltime,0,0,0,0,0,A.id,A.datatype,M.ShiftStart,M.ShiftEnd from Autodata_ICD A  
		right outer join #machineRunningStatus M On A.mc=M.MachineInterface  
		Where A.sttime>=M.sttime and A.ndtime<=M.ndtime  
		and M.datatype='11' and A.datatype='42' Order by A.mc,A.sttime  
  
		IF EXISTS(select * from #AE where datatype=42)  
		Begin  
  
		update #machineRunningStatus set Totaltime=Datediff(second,sttime,ndtime)  
  
		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y')  
		BEGIN  
		UPDATE #AE SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)  
		from  
		(select mc,sttime,shiftstart,  
		CASE  
		WHEN Datediff(second,sttime,ndtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0  
		THEN isnull(downcodeinformation.Threshold,0)  
		ELSE Datediff(second,sttime,ndtime)  
		END AS LOSS from #AE autodata    
		INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid  
		where (autodata.datatype=42) and (downcodeinformation.availeffy = 1)  
		) as t2 inner join  #AE on t2.mc = #AE.mc and t2.sttime=#AE.Sttime  and t2.ShiftStart=#AE.ShiftStart
  
		UPDATE #AE SET downtime = isnull(downtime,0) + isNull(t2.down,0)  
		from  
		(select mc,Datediff(second,sttime,ndtime) AS down,sttime,ndtime,ShiftStart 
		from #AE autodata inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid  
		) as t2 inner join #AE on t2.mc = #AE.mc and t2.sttime=#AE.Sttime  and t2.ShiftStart=#AE.ShiftStart
		END  
  
		Delete From #PlannedDownTimes  
  
		SET @strSql = ''  
		SET @strSql = 'Insert into #PlannedDownTimes(machineid,machineinterface,starttime,endtime,Shiftstart)  
		SELECT MachineInformation.Machineid,MachineInformation.InterfaceID,  
		CASE When StartTime<#AE.CycleStart Then #AE.CycleStart Else StartTime End As StartTime,  
		CASE When EndTime>#AE.CycleEnd Then #AE.CycleEnd Else EndTime End As EndTime,#AE.Shiftstart  
		FROM PlannedDownTimes inner join MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID  
		inner join (Select Distinct mc,CycleStart,CycleEnd from #AE) #AE on #AE.mc = MachineInformation.InterfaceID  
		WHERE PDTstatus =1 and(  
		(StartTime >= #AE.CycleStart AND EndTime <=#AE.CycleEnd)  
		OR ( StartTime < #AE.CycleStart  AND EndTime <= #AE.CycleEnd AND EndTime > #AE.CycleStart )  
		OR ( StartTime >= #AE.CycleStart   AND StartTime <#AE.CycleEnd AND EndTime > #AE.CycleEnd )  
		OR ( StartTime < #AE.CycleStart  AND EndTime > #AE.CycleEnd)) '  
		SET @strSql =  @strSql + ' ORDER BY MachineInformation.Machineid,PlannedDownTimes.StartTime'  
		EXEC(@strSql)  
  
		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
		BEGIN  
  
  
		UPDATE #AE SET downtime = isnull(downtime,0) + isNull(t2.down,0)  
		from  
		(select mc,Datediff(second,sttime,ndtime) AS down,sttime,ndtime,ShiftStart 
		from #AE autodata inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid  
		where (downcodeinformation.availeffy = 0)  
		) as t2 inner join #AE on t2.mc = #AE.mc and t2.sttime=#AE.Sttime and t2.ShiftStart=#AE.ShiftStart
  
		UPDATE #AE set DownTime =isnull(DownTime,0) - isNull(TT.PPDT ,0),PDT=isnull(PDT,0) + isNull(TT.PPDT ,0)  
		FROM(  
		--Down PDT  
		SELECT autodata.MC,DownID,sttime, SUM  
		(CASE  
		WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)  
		WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
		WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )  
		WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
		END ) as PPDT,autodata.ShiftStart 
		FROM #AE AutoData  
		CROSS jOIN #PlannedDownTimes T  
		Inner Join DownCodeInformation On AutoData.DCode=DownCodeInformation.InterfaceID  
		WHERE autodata.DataType=42 AND (downcodeinformation.availeffy = 0) AND  
		T.MachineInterface = AutoData.mc And  
		(  
		(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
		OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
		OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )  
		OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  
		)  
		group by autodata.mc,DownID,sttime,autodata.ShiftStart 
		) as TT INNER JOIN #AE ON TT.mc = #AE.mc and TT.sttime=#AE.Sttime and #ae.ShiftEnd=TT.ShiftStart
  
  
		UPDATE #AE SET  ManagementLoss = isnull(ManagementLoss,0) + isNull(t4.Mloss,0),MLDown=isNull(MLDown,0)+isNull(t4.Dloss,0),  
		PDT=isnull(PDT,0) + isNull(t4.PPDT ,0)  
		from  
		(select T3.mc,T3.sttime,T3.ShiftStart,SUM(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss,sum(T3.PPDT) as PPDT from (  
		select T1.mc,T1.Threshold,T2.PPDT,T1.sttime,T1.ShiftStart, 
		case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0  
		then DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)- isnull(T1.Threshold ,0)  
		else 0 End  as Dloss,  
		case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0  
		then isnull(T1.Threshold,0)  
		else (DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)) End  as Mloss  
		from  
  
		(   
		select sttime,mc,D.threshold,ndtime,ShiftStart  
		from #AE autodata --ER0374  
		inner join downcodeinformation D on autodata.dcode=D.interfaceid   
		where autodata.datatype=42 AND D.availeffy = 1     
		) as T1     
		left outer join  
		(  
		SELECT autodata.sttime,autodata.ndtime,autodata.mc,autodata.shiftstart,  
		sum(CASE  
		WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)  
		WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
		WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )  
		WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
		END ) as PPDT  
		FROM #AE AutoData   
		CROSS jOIN #PlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid  
		WHERE autodata.DataType=42 AND T.MachineInterface=autodata.mc and T.Shiftstart=autodata.ShiftStart AND  
		(  
		(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
		OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
		OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )  
		OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  
		)  
		AND (downcodeinformation.availeffy = 1)   
		group  by autodata.sttime,autodata.ndtime,autodata.mc,autodata.ShiftStart) as T2 on T1.mc=T2.mc and T1.sttime=T2.sttime and T1.ShiftStart=T2.ShiftStart) as T3  group by T3.mc,T3.sttime,T3.Shiftstart 
		) as t4 inner join #AE on t4.mc = #AE.mc and t4.sttime = #AE.sttime and t4.ShiftStart=#AE.ShiftStart
  
		UPDATE #AE SET downtime = isnull(downtime,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)  
		END  
  
		Update #MachineRunningStatus SET downtime = isnull(downtime,0)+ isnull(T1.down,0),ManagementLoss = isnull(ManagementLoss,0)+isnull(T1.ML,0),  
		UT = ISNULL(UT,0)+ (ISNULL(Totaltime,0)-ISNULL(T1.down,0)),#MachineRunningStatus.PDT=ISNULL(#MachineRunningStatus.PDT,0)+ ISNULL(T1.PDT,0) from  
		(Select shiftstart,mc,Sum(ManagementLoss) as ML,Sum(Downtime) as Down,SUM(PDT) as PDT from #AE Group By mc,ShiftStart)T1  
		inner join #MachineRunningStatus on T1.mc = #MachineRunningStatus.machineinterface  and T1.ShiftStart = #MachineRunningStatus.ShiftStart
  
		END  
  


		--Update #MachineRunningStatus set DownTime = Isnull(#MachineRunningStatus.DownTime,0) + Isnull(t2.DownTime,0),StartTime=t2.endtime  
		Update #MachineRunningStatus set UT = Isnull(#MachineRunningStatus.UT,0) + Isnull(t2.DownTime,0),StartTime=t2.endtime  
		from (  
		Select mrs.MachineID,mrs.datatype,case when t1.endtime<mrs.ShiftEnd then datediff(second,t1.endtime,mrs.ShiftEnd) else 0 end as Downtime,
		case when t1.endtime<mrs.ShiftEnd then t1.endtime else mrs.ShiftEnd end as endtime ,mrs.ShiftStart 
		from #machineRunningStatus mrs inner join  
		(  
		Select mrs.MachineID,case when mrs.LastRecorddatatype=11 then dateadd(second,@Type11Threshold,sttime) else mrs.ndtime end as endtime,ShiftStart   
		from #machineRunningStatus mrs  
		Inner join Machineinformation M on M.interfaceID = mrs.MachineInterface  
		) as t1 on t1.machineID = mrs.machineID and t1.ShiftStart = mrs.ShiftStart      
		) as t2 inner join #MachineRunningStatus on t2.MachineID = #MachineRunningStatus.MachineID and t2.ShiftStart = #MachineRunningStatus.ShiftStart   
  
		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'   
		BEGIN  
		-- update #MachineRunningStatus set Downtime = Isnull(#MachineRunningStatus.Downtime,0) - isnull(T2.pdt,0),#MachineRunningStatus.PDT=ISNULL(#MachineRunningStatus.PDT,0)+isnull(T2.pdt,0)
		update #MachineRunningStatus set UT = Isnull(#MachineRunningStatus.UT,0) - isnull(T2.pdt,0),#MachineRunningStatus.PDT=ISNULL(#MachineRunningStatus.PDT,0)+isnull(T2.pdt,0)
		from  
		(  
		Select T1.machineid,sum(datediff(ss,T1.StartTime,t1.EndTime)) as pdt,T1.ShiftStart
		from   
		(  
		select fD.machineid,fd.Shiftstart,  
		Case when  fd.starttime <= pdt.StartTime then pdt.StartTime else  fd.starttime End as StartTime,  
		Case when fd.ShiftEnd >= pdt.EndTime then pdt.EndTime else fd.ShiftEnd End as EndTime  
		From Planneddowntimes pdt  
		inner join #machineRunningStatus fD on fd.machineid=Pdt.machine  
		inner join #AE on fd.MachineInterface=#AE.mc and fd.ShiftStart=#AE.ShiftStart
		where PDTstatus = 1  and   
		((pdt.StartTime >= fd.starttime and pdt.EndTime <= fd.ShiftEnd)or  
		(pdt.StartTime < fd.starttime and pdt.EndTime > fd.starttime and pdt.EndTime <=fd.ShiftEnd)or  
		(pdt.StartTime >= fd.starttime and pdt.StartTime <fd.ShiftEnd and pdt.EndTime >fd.ShiftEnd) or  
		(pdt.StartTime <  fd.starttime and pdt.EndTime >fd.ShiftEnd)) 
		)T1  group by T1.machineid ,T1.ShiftStart 
		)T2 inner join #MachineRunningStatus on #MachineRunningStatus.machineid=t2.machineid and #MachineRunningStatus.ShiftStart=t2.ShiftStart   
		end  

		Update #ShiftwiseSummary SET RunningCycleUT= isnull(RunningCycleUT,0)+isnull(T.UT,0),RunningCycleDT=ISNULL(RunningCycleDT,0)+ISNULL(T.DT,0),  
		RunningCycleML=ISNULL(#ShiftwiseSummary.RunningCycleML,0)+ISNULL(T.ManagementLoss,0),RunningCyclePDT=ISNULL(RunningCyclePDT,0)+ISNULL(T.PDT,0) from  
		(  
		Select ShiftStart,MachineInterface as mc,ISNULL(Downtime,0) as DT,ISNULL(UT,0) as UT,IsNULL(ManagementLoss,0) as ManagementLoss,
		ISNULL(PDT,0) as PDT from #MachineRunningStatus  
		)T inner join #ShiftwiseSummary on #ShiftwiseSummary.MachineInterface=T.mc  and #ShiftwiseSummary.[From time]=T.shiftstart
  
		UPDATE #ShiftwiseSummary  
		SET 
		RunningCycleAE = ((RunningCycleUT)/(RunningCycleUT + RunningCycleDT - RunningCycleML))*100 where (RunningCycleUT + RunningCycleDT - RunningCycleML)>0


		--Query to get Machinewise Spindle records for each CycleStart and CycleEnd  
		Delete From #machineRunningStatus  
  
		---Query to get Machinewise Last Record from Rawdata where Datatype in 1,2,11  
		Insert into #machineRunningStatus(MachineID,MachineInterface,sttime,ndtime,DataType,Downtime,comp,Opn,ShiftStart,ShiftEnd)  
		select fd.MachineID,fd.MachineInterface,sttime,fd.[To Time],datatype,datediff(second,sttime,fd.[To Time]),comp,opn,fd.[From time],fd.[To Time] from rawdata  
		inner join (select mc,max(slno) as slno,S.[From time] from rawdata WITH (NOLOCK)   
		inner join Autodata_maxtime A on rawdata.mc=A.machineid 
		inner join #ShiftwiseSummary S on RawData.mc=S.MachineInterface 
		where (Rawdata.sttime>A.Endtime and Rawdata.sttime>=S.[From time] and rawdata.sttime<=S.[To Time]) and rawdata.datatype=11 group by mc,S.[From time]
		) t1 
		on t1.mc=rawdata.mc and t1.slno=rawdata.slno  
		inner join Autodata_maxtime A on rawdata.mc=A.machineid  
		right outer join #ShiftwiseSummary fd on fd.MachineInterface = t1.mc and fd.[From time]=t1.[From time] 
		where (Rawdata.sttime>A.Endtime and Rawdata.sttime>=fd.[From time] and rawdata.sttime<=fd.[To Time]) and rawdata.datatype=11   
		order by rawdata.mc 

		--Query to get Machinewise Spindle records for each CycleStart and CycleEnd  
		select R.slno,R.mc,R.sttime,R.ndtime,R.datatype,M.ShiftStart INTO #Spindle from rawdata R  
		inner join #machineRunningStatus M on M.MachineInterface=R.mc  
		where R.sttime>=M.sttime and R.sttime<=M.ndtime  
		and R.datatype in (40,41) order by R.mc,R.sttime  
  
		--Query to get Spindlestart ans SpindleEnd for each Machine  
		Select S.mc,S.Sttime as SpindleStart,Min(S1.Sttime) as SpindleEnd,S.ShiftStart INTO #TempSpindle from #Spindle S  
		inner join #Spindle S1 on S.mc=S1.mc and S.ShiftStart=S1.ShiftStart
		Where S.Slno<S1.Slno and S.datatype='41' and S1.Datatype='40'  
		Group by S.mc,S.Sttime,S.ShiftStart
  
		--Query to Get Finaldeatils into Temap table  
		Select M.MachineInterface as mc,M.sttime,M.ndtime,M.datatype,M.ColorCode,SUM(Datediff(Second,T.SpindleStart,T.SpindleEnd)) as Spindleruntime,M.comp,M.opn,M.ShiftStart INTO #SpindleDeatils  
		From #TempSpindle T Right Outer join #machineRunningStatus M on M.MachineInterface=T.mc and M.ShiftStart=T.ShiftStart 
		Group by M.MachineInterface,M.sttime,M.ndtime,M.datatype,M.ColorCode,M.comp,M.opn,M.ShiftStart  

  
		--Updating data to #cockpit table  
		Update #ShiftwiseSummary Set LastCycleCO=T1.CO,LastCycleStart=T1.sttime,LastCycleSpindleRunTime=T1.Spindleruntime,  
		LastCycleDatatype=T1.datatype from   
		(  
		Select A.mc,CASE when A.datatype=11 then A.sttime else '' end AS STTIME,A.datatype,A.Spindleruntime,CO.Componentid + ' <' + cast(CO.Operationno as nvarchar(50)) + '>'  as CO,ShiftStart From #SpindleDeatils A  
		inner join Machineinformation on A.mc=Machineinformation.interfaceid    
		left outer join Componentinformation C on A.comp=C.interfaceid    
		left outer join Componentoperationpricing CO on A.opn=CO.interfaceid    
		and Machineinformation.Machineid=CO.Machineid and C.Componentid=CO.Componentid    
		) T1 inner join #ShiftwiseSummary on T1.mc = #ShiftwiseSummary.MachineInterface and T1.ShiftStart = #ShiftwiseSummary.[From time]
	
		---Query to get Machinewise Last Record from Rawdata where Datatype in 11,1,2,22,42 for peekay  
		Update #ShiftwiseSummary Set MachineStatus=T1.DownStatus From
		(select RawData.mc,fd.[from time],
		Case when rawdata.datatype in(11,41) then 'Cycle Started'
		When rawdata.datatype=1 then 'Cycle Ended'
		When rawdata.datatype in(22,42) then  'Stopped ' + D.Downid 
		When rawdata.datatype in(2,40) then 'Stopped' 
		END as DownStatus from Rawdata
		inner join (select mc,max(slno) as slno,S.[From time] from rawdata WITH (NOLOCK)   
		inner join #ShiftwiseSummary S on RawData.mc=S.MachineInterface 
		where Rawdata.sttime<S.[To Time] and rawdata.datatype in(11,1,2,22,42) group by mc,S.[From time]) t1 on t1.mc=rawdata.mc and t1.slno=rawdata.slno  
		Left Outer join Downcodeinformation D on rawdata.splstring2=D.interfaceid
		right outer join #ShiftwiseSummary fd on fd.MachineInterface = t1.mc and fd.[From time]=t1.[From time] 
		) T1 inner join #ShiftwiseSummary on T1.mc = #ShiftwiseSummary.MachineInterface and T1.[from time] = #ShiftwiseSummary.[From time] WHERE ShiftName<>'DAY'


		
	   ---------------------------------------------------- DAYWISE RUNNINGCYCLE Calculation---------------------------------------------------------------

			Insert into #ShiftwiseSummary (PlantID,Machineid,MachineInterface,ShiftDate,[From time],[To Time],ShiftID,ShiftName,UtilisedTime ,ManagementLoss,DownTime ,CN,Components,NetDowntime,RejCount
			,PEGreen ,PERed,AEGreen ,AERed ,OEGreen ,OERed,QERed,QEGreen,QualityEfficiency,AvailabilityEfficiency,ProductionEfficiency,OverallEfficiency,RunningCycleAE)   --SV
			SELECT S.PlantID,S.machineid,S.MachineInterface,S.ShiftDate,min(S.[From time]),max(S.[To Time]),4,'DAY',ISNULL(sum(S.utilisedtime),0),ISNULL(sum(managementloss),0),ISNULL(sum(downtime),0),ISNULL(sum(CN),0),
			ISNULL(sum(components),0),ISNULL(sum(netdowntime),0),ISNULL(sum(rejcount),0)
			,isnull(PEGreen,0) ,isnull(PERed,0),isnull(AEGreen,0) ,isnull(AERed,0) ,isnull(OEGreen,0) ,isnull(OERed,0),isnull(QERed,0),isnull(QEGreen,0),0,0,0,0,0 FROM 
			#ShiftwiseSummary S group by S.PlantID,S.machineid,S.MachineInterface,S.ShiftDate,PEGreen ,PERed,AEGreen ,AERed ,OEGreen ,OERed,QERed,QEGreen


			UPDATE #ShiftwiseSummary SET
			ProductionEfficiency = (CN/UtilisedTime) ,
			AvailabilityEfficiency = (UtilisedTime)/(UtilisedTime + DownTime - ManagementLoss)
			WHERE UtilisedTime <> 0 and ShiftName='DAY'

			UPDATE #ShiftwiseSummary SET NetDowntime=DownTime-ManagementLoss where ShiftName='DAY'

			UPDATE #ShiftwiseSummary SET QualityEfficiency= ISNULL(QualityEfficiency,1) + IsNull(T1.QE,1) 
			FROM(Select MachineID,[from time],
			CAST((Sum(Components))As Float)/CAST((Sum(IsNull(Components,0))+Sum(IsNull(RejCount,0))) AS Float)As QE
			From #ShiftwiseSummary Where Components<>0 Group By MachineID,[From time]
			)AS T1 Inner Join #ShiftwiseSummary B on B.Machineid=T1.Machineid and B.[From time]=T1.[From time] and ShiftName='DAY'

			UPDATE #ShiftwiseSummary
			SET
			OverAllEfficiency = (ProductionEfficiency * AvailabilityEfficiency * ISNULL(QualityEfficiency,1))*100,
			ProductionEfficiency = ProductionEfficiency * 100 ,
			AvailabilityEfficiency = AvailabilityEfficiency * 100,
			QualityEfficiency = QualityEfficiency*100 where ShiftName='DAY'



			--Update #ShiftwiseSummary Set Lastcycletime = T1.LastCycle  from 
			--(
			--Select A.Machineid,A.Endtime as LastCycle from Autodata_MaxTime A
			--) T1 inner join #ShiftwiseSummary on T1.MachineID = #ShiftwiseSummary.machineinterface and #ShiftwiseSummary.ShiftName='DAY'



			Delete From #machineRunningStatus  
			Delete FROM #AE

			Set @CurrTime = case when @CurrTime>@T_ED then @T_ED else @CurrTime end  
  
			---Query to get Machinewise Last Record from Rawdata where Datatype in 11  
			Insert into #machineRunningStatus(MachineID,MachineInterface,AutodataMaxtime,sttime,DataType,Comp,Opn,Totaltime,Downtime,UT)  
			select fd.MachineID,fd.MachineInterface,A.Endtime,case when sttime<@T_ST then @T_ST else sttime end,datatype,comp,opn,0,0,0 from rawdata  
			inner join (select mc,max(slno) as slno from rawdata WITH (NOLOCK)   
			inner join Autodata_maxtime A on rawdata.mc=A.machineid where (Rawdata.sttime>A.Endtime and Rawdata.sttime<@currtime) and rawdata.datatype=11 group by mc  ) t1   
			on t1.mc=rawdata.mc and t1.slno=rawdata.slno  
			inner join Autodata_maxtime A on rawdata.mc=A.machineid  
			right outer join (select distinct machineid,MachineInterface from #ShiftwiseSummary) fd on fd.MachineInterface = rawdata.mc  
			where (Rawdata.sttime>A.Endtime and Rawdata.sttime<@currtime) and rawdata.datatype=11   
			order by rawdata.mc  
  
			Update #machineRunningStatus set UT=ISNULL(T1.UT,0),Downtime=ISNULL(T1.Dt,0) from  
			(Select MachineInterface,case when AutodataMaxtime<sttime then (O.cycletime-O.machiningtime) end as UT,  
			case when dateadd(second,(O.cycletime-O.machiningtime),AutodataMaxtime)<sttime then datediff(second,dateadd(second,(O.cycletime-O.machiningtime),AutodataMaxtime),sttime) end as DT   
			from #MachineRunningStatus  
			inner join machineinformation M on #MachineRunningStatus.MachineInterface=M.InterfaceID   
			inner join componentinformation C on C.InterfaceID=#MachineRunningStatus.Comp  
			inner join componentoperationpricing O on O.componentid=C.componentid and M.machineid=O.machineid and   
			#MachineRunningStatus.Opn=O.InterfaceID)T1 inner join #machineRunningStatus on T1.MachineInterface=#machineRunningStatus.MachineInterface  
  
			Update #machineRunningStatus set ndtime = case when T1.Endtime>@CurrTime then @CurrTime else T1.Endtime end,LastRecorddatatype=T1.LastRecorddatatype from  
			(select rawdata.mc,rawdata.datatype,case when rawdata.datatype=40 then dateadd(second,@type40threshold,rawdata.sttime)  
			when rawdata.datatype=42 then rawdata.ndtime  
			when rawdata.datatype=41 then rawdata.sttime   
			else @CurrTime end as endtime,  
			case when rawdata.datatype in(40,41,42) then RawData.DataType   
			else 11 end as LastRecorddatatype from  
			(  
			select rawdata.mc,max(rawdata.slno) as slno from rawdata   
			inner join #machineRunningStatus M on M.MachineInterface=rawdata.mc  
			where rawdata.datatype in(40,41,42) and (rawdata.sttime>M.sttime and ISNULL(Rawdata.ndtime,Rawdata.sttime)<@currtime)  group by rawdata.mc  
			)T1  inner join rawdata on rawdata.slno=t1.slno  
			inner join #machineRunningStatus M on M.MachineInterface=rawdata.mc  
			)T1 inner join #machineRunningStatus on #machineRunningStatus.MachineInterface=T1.mc  
  
			update  #machineRunningStatus set ndtime=@CurrTime,LastRecorddatatype=11 where ndtime IS NULL  
  
			Insert into #AE(mc,dcode,sttime,ndtime,Loadunload,CycleStart,CycleEnd,TotalTime,UT,Downtime,PDT,ManagementLoss,MLDown,id,datatype)  
			Select M.MachineInterface,A.dcode,A.sttime,A.ndtime,A.Loadunload,M.sttime,M.ndtime,M.Totaltime,0,0,0,0,0,A.id,A.datatype from Autodata_ICD A  
			right outer join #machineRunningStatus M On A.mc=M.MachineInterface  
			Where A.sttime>=M.sttime and A.ndtime<=M.ndtime  
			and M.datatype='11' and A.datatype='42' Order by A.mc,A.sttime  
  
			IF EXISTS(select * from #AE where datatype=42)  
			Begin  
  
				update #machineRunningStatus set Totaltime=Datediff(second,sttime,ndtime)  
  
				If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y')  
				BEGIN  
					UPDATE #AE SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)  
					from  
					(select mc,sttime,  
					CASE  
					WHEN Datediff(second,sttime,ndtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0  
					THEN isnull(downcodeinformation.Threshold,0)  
					ELSE Datediff(second,sttime,ndtime)  
					END AS LOSS from #AE autodata    
					INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid  
					where (autodata.datatype=42) and (downcodeinformation.availeffy = 1)  
					) as t2 inner join  #AE on t2.mc = #AE.mc and t2.sttime=#AE.Sttime  
  
					UPDATE #AE SET downtime = isnull(downtime,0) + isNull(t2.down,0)  
					from  
					(select mc,Datediff(second,sttime,ndtime) AS down,sttime,ndtime  
					from #AE autodata inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid  
					) as t2 inner join #AE on t2.mc = #AE.mc and t2.sttime=#AE.Sttime  
				END  
  
				Delete From #PlannedDownTimes  
  
				SET @strSql = ''  
				SET @strSql = 'Insert into #PlannedDownTimes(machineid,machineinterface,starttime,endtime)  
				SELECT MachineInformation.Machineid,MachineInformation.InterfaceID,  
				CASE When StartTime<#AE.CycleStart Then #AE.CycleStart Else StartTime End As StartTime,  
				CASE When EndTime>#AE.CycleEnd Then #AE.CycleEnd Else EndTime End As EndTime  
				FROM PlannedDownTimes inner join MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID  
				inner join (Select Distinct mc,CycleStart,CycleEnd from #AE) #AE on #AE.mc = MachineInformation.InterfaceID  
				WHERE PDTstatus =1 and(  
				(StartTime >= #AE.CycleStart AND EndTime <=#AE.CycleEnd)  
				OR ( StartTime < #AE.CycleStart  AND EndTime <= #AE.CycleEnd AND EndTime > #AE.CycleStart )  
				OR ( StartTime >= #AE.CycleStart   AND StartTime <#AE.CycleEnd AND EndTime > #AE.CycleEnd )  
				OR ( StartTime < #AE.CycleStart  AND EndTime > #AE.CycleEnd)) '  
				SET @strSql =  @strSql +  ' ORDER BY MachineInformation.Machineid,PlannedDownTimes.StartTime'  
				EXEC(@strSql)  
  
				If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
				BEGIN  
  
  
					UPDATE #AE SET downtime = isnull(downtime,0) + isNull(t2.down,0)  
					from  
					(select mc,Datediff(second,sttime,ndtime) AS down,sttime,ndtime  
					from #AE autodata inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid  
					where (downcodeinformation.availeffy = 0)  
					) as t2 inner join #AE on t2.mc = #AE.mc and t2.sttime=#AE.Sttime  
  
					UPDATE #AE set DownTime =isnull(DownTime,0) - isNull(TT.PPDT ,0),PDT=isnull(PDT,0) + isNull(TT.PPDT ,0)  
					FROM(  
					--Down PDT  
					SELECT autodata.MC,DownID,sttime, SUM  
					(CASE  
					WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)  
					WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
					WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )  
					WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
					END ) as PPDT  
					FROM #AE AutoData --ER0374  
					CROSS jOIN #PlannedDownTimes T  
					Inner Join DownCodeInformation On AutoData.DCode=DownCodeInformation.InterfaceID  
					WHERE autodata.DataType=42 AND (downcodeinformation.availeffy = 0) AND  
					T.MachineInterface = AutoData.mc And  
					(  
					(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
					OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
					OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )  
					OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  
					)  
					group by autodata.mc,DownID,sttime  
					) as TT INNER JOIN #AE ON TT.mc = #AE.mc and TT.sttime=#AE.Sttime  
  
  
					UPDATE #AE SET  ManagementLoss = isnull(ManagementLoss,0) + isNull(t4.Mloss,0),MLDown=isNull(MLDown,0)+isNull(t4.Dloss,0),  
					PDT=isnull(PDT,0) + isNull(t4.PPDT ,0)  
					from  
					(select T3.mc,T3.sttime,sum(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss,sum(T3.PPDT) as PPDT from (  
					select T1.mc,T1.Threshold,T2.PPDT,T1.sttime,  
					case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0  
					then DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)- isnull(T1.Threshold ,0)  
					else 0 End  as Dloss,  
					case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0  
					then isnull(T1.Threshold,0)  
					else (DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)) End  as Mloss  
					from  
  
					(   
					select sttime,mc,D.threshold,ndtime  
					from #AE autodata --ER0374  
					inner join downcodeinformation D on autodata.dcode=D.interfaceid   
					where autodata.datatype=42 AND D.availeffy = 1     
					) as T1     
					left outer join  
					(  
					SELECT autodata.sttime,autodata.ndtime,autodata.mc,  
					sum(CASE  
					WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)  
					WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
					WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )  
					WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
					END ) as PPDT  
					FROM #AE AutoData   
					CROSS jOIN #PlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid  
					WHERE autodata.DataType=42 AND T.MachineInterface=autodata.mc AND  
					(  
					(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
					OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
					OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )  
					OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  
					)  
					AND (downcodeinformation.availeffy = 1)   
					group  by autodata.sttime,autodata.ndtime,autodata.mc) as T2 on T1.mc=T2.mc and T1.sttime=T2.sttime) as T3  group by T3.mc,T3.sttime  
					) as t4 inner join #AE on t4.mc = #AE.mc and t4.sttime = #AE.sttime  
  
					UPDATE #AE SET downtime = isnull(downtime,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)  
				END  
  
				Update #MachineRunningStatus SET downtime = isnull(downtime,0)+ isnull(T1.down,0),ManagementLoss = isnull(ManagementLoss,0)+isnull(T1.ML,0),  
				UT = ISNULL(UT,0)+ (ISNULL(Totaltime,0)-ISNULL(T1.down,0)),#MachineRunningStatus.PDT=ISNULL(#MachineRunningStatus.PDT,0)+ ISNULL(T1.PDT,0) from  
				(Select mc,Sum(ManagementLoss) as ML,Sum(Downtime) as Down,SUM(PDT) as PDT from #AE Group By mc)T1  
				inner join #MachineRunningStatus on T1.mc = #MachineRunningStatus.machineinterface  
  
			  END  
			


			--Update #MachineRunningStatus set DownTime = Isnull(#MachineRunningStatus.DownTime,0) + Isnull(t2.DownTime,0),StartTime=t2.endtime  
			Update #MachineRunningStatus set UT = Isnull(#MachineRunningStatus.UT,0) + Isnull(t2.DownTime,0),StartTime=t2.endtime  
			from (  
			Select mrs.MachineID,mrs.datatype,case when t1.endtime<@CurrTime then datediff(second,t1.endtime,@CurrTime) else 0 end as Downtime,
			case when t1.endtime<@CurrTime then t1.endtime else @CurrTime end as endtime  
			from #machineRunningStatus mrs inner join  
			(  
			Select mrs.MachineID,case when mrs.LastRecorddatatype=11 then dateadd(second,@Type11Threshold,sttime) else mrs.ndtime end as endtime   
			from #machineRunningStatus mrs  
			Inner join Machineinformation M on M.interfaceID = mrs.MachineInterface  
			) as t1 on t1.machineID = mrs.machineID   
			) as t2 inner join #MachineRunningStatus on t2.MachineID = #MachineRunningStatus.MachineID   
  
			If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'   
			BEGIN  
			-- update #MachineRunningStatus set Downtime = Isnull(#MachineRunningStatus.Downtime,0) - isnull(T2.pdt,0),#MachineRunningStatus.PDT=ISNULL(#MachineRunningStatus.PDT,0)+isnull(T2.pdt,0)
			update #MachineRunningStatus set UT = Isnull(#MachineRunningStatus.UT,0) - isnull(T2.pdt,0),#MachineRunningStatus.PDT=ISNULL(#MachineRunningStatus.PDT,0)+isnull(T2.pdt,0)
			from  
			(  
			Select T1.machineid,sum(datediff(ss,T1.StartTime,t1.EndTime)) as pdt   
			from   
			(  
			select fD.machineid,  
			Case when  fd.starttime <= pdt.StartTime then pdt.StartTime else  fd.starttime End as StartTime,  
			Case when @Currtime >= pdt.EndTime then pdt.EndTime else @Currtime End as EndTime  
			From Planneddowntimes pdt  
			inner join #machineRunningStatus fD on fd.machineid=Pdt.machine  
			inner join #AE on fd.MachineInterface=#AE.mc  
			where PDTstatus = 1  and   
			((pdt.StartTime >= fd.starttime and pdt.EndTime <= @Currtime)or  
			(pdt.StartTime < fd.starttime and pdt.EndTime > fd.starttime and pdt.EndTime <=@Currtime)or  
			(pdt.StartTime >= fd.starttime and pdt.StartTime <@Currtime and pdt.EndTime >@Currtime) or  
			(pdt.StartTime <  fd.starttime and pdt.EndTime >@Currtime))  
			)T1  group by T1.machineid   
			)T2 inner join #MachineRunningStatus on #MachineRunningStatus.machineid=t2.machineid   
			end  

			Update #ShiftwiseSummary SET RunningCycleUT= isnull(RunningCycleUT,0)+isnull(T.UT,0),RunningCycleDT=ISNULL(RunningCycleDT,0)+ISNULL(T.DT,0),  
			RunningCycleML=ISNULL(#ShiftwiseSummary.RunningCycleML,0)+ISNULL(T.ManagementLoss,0),RunningCyclePDT=ISNULL(RunningCyclePDT,0)+ISNULL(T.PDT,0) from  
			(  
			Select MachineInterface as mc,ISNULL(Downtime,0) as DT,ISNULL(UT,0) as UT,IsNULL(ManagementLoss,0) as ManagementLoss,ISNULL(PDT,0) as PDT from #MachineRunningStatus  
			)T inner join #ShiftwiseSummary on #ShiftwiseSummary.MachineInterface=T.mc  WHERE #ShiftwiseSummary.ShiftName='DAY'


			UPDATE #ShiftwiseSummary  
			SET RunningCycleAE = ((RunningCycleUT)/(RunningCycleUT + RunningCycleDT - RunningCycleML))*100  WHERE #ShiftwiseSummary.ShiftName='DAY'
			and (RunningCycleUT + RunningCycleDT - RunningCycleML)>0

			--SV 
			Select @T_ED = case when @T_ED<@CurrTime then @T_ED else @currtime end

			UPDATE #ShiftwiseSummary
			SET
			TotalTime = DateDiff(second, @T_ST, case when T.Endtime IS NULL Then @T_ED else T.Endtime END) from
			(Select mc,	CASE	
			when max(ndtime)>@T_ST and max(ndtime)<@T_ED then Max(ndtime)
			when max(ndtime)<@T_ST and max(ndtime)<@T_ED then @T_ED
			WHEN max(ndtime)>@T_ST and max(ndtime)>@T_ED then @T_ED
			END as Endtime from #T_autodata Autodata
			Where ((autodata.msttime >= @T_ST  AND autodata.ndtime <=@T_ED)
			OR ( autodata.msttime < @T_ST  AND autodata.ndtime <= @T_ED AND autodata.ndtime > @T_ST )
			OR ( autodata.msttime >= @T_ST   AND autodata.msttime <@T_ED AND autodata.ndtime > @T_ED )
			OR ( autodata.msttime < @T_ST  AND autodata.ndtime > @T_ED))
			Group by mc)T inner join #ShiftwiseSummary on #ShiftwiseSummary.MachineInterface=T.mc WHERE #ShiftwiseSummary.ShiftName='DAY'



			UPDATE #ShiftwiseSummary  
			SET 
			TotalTime = DateDiff(second, @T_ST, @T_ED) Where ISNULL(TotalTime,0)=0 AND #ShiftwiseSummary.ShiftName='DAY'

			


			--Query to get Machinewise Spindle records for each CycleStart and CycleEnd  
			Delete From #machineRunningStatus  
  
			---Query to get Machinewise Last Record from Rawdata where Datatype in 1,2,11  
			Insert into #machineRunningStatus(MachineID,MachineInterface,sttime,ndtime,DataType,Downtime,comp,Opn)  
			select fd.MachineID,fd.MachineInterface,sttime,@currtime,datatype,datediff(second,sttime,@currtime),comp,opn from rawdata  
			inner join (select mc,max(slno) as slno from rawdata WITH (NOLOCK)   
			inner join Autodata_maxtime A on rawdata.mc=A.machineid where (Rawdata.sttime>A.Endtime and Rawdata.sttime<@currtime) and rawdata.datatype=11 group by mc) t1 
			on t1.mc=rawdata.mc and t1.slno=rawdata.slno  
			inner join Autodata_maxtime A on rawdata.mc=A.machineid  
			right outer join (select distinct machineid,MachineInterface from #ShiftwiseSummary) fd on fd.MachineInterface = rawdata.mc  
			where (Rawdata.sttime>A.Endtime and Rawdata.sttime<@currtime) and rawdata.datatype=11   
			order by rawdata.mc   
  
			--Query to get Machinewise Spindle records for each CycleStart and CycleEnd  
			select R.slno,R.mc,R.sttime,R.ndtime,R.datatype INTO #Spindle1 from rawdata R  
			inner join #machineRunningStatus M on M.MachineInterface=R.mc  
			where R.sttime>=M.sttime and R.sttime<=M.ndtime  
			and R.datatype in (40,41) order by R.mc,R.sttime  
  
			--Query to get Spindlestart ans SpindleEnd for each Machine  
			Select S.mc,S.Sttime as SpindleStart,Min(S1.Sttime) as SpindleEnd INTO #TempSpindle1 from #Spindle1 S  
			inner join #Spindle1 S1 on S.mc=S1.mc  
			Where S.Slno<S1.Slno and S.datatype='41' and S1.Datatype='40'  
			Group by S.mc,S.Sttime 
  
			--Query to Get Finaldeatils into Temap table  
			Select M.MachineInterface as mc,M.sttime,M.ndtime,M.datatype,M.ColorCode,SUM(Datediff(Second,T.SpindleStart,T.SpindleEnd)) as Spindleruntime,M.comp,M.opn INTO #SpindleDeatils1 
			From #TempSpindle1 T Right Outer join #machineRunningStatus M on M.MachineInterface=T.mc  
			Group by M.MachineInterface,M.sttime,M.ndtime,M.datatype,M.ColorCode,M.comp,M.opn  

  
			--Updating data to #cockpit table  
			Update #ShiftwiseSummary Set LastCycleCO=T1.CO,LastCycleStart=T1.sttime,LastCycleSpindleRunTime=T1.Spindleruntime,  
			LastCycleDatatype=T1.datatype from   
			(  
			Select A.mc,CASE when A.datatype=11 then A.sttime else '' end AS STTIME,A.datatype,A.Spindleruntime,CO.Componentid + ' <' + cast(CO.Operationno as nvarchar(50)) + '>'  as CO From #SpindleDeatils1 A  
			inner join Machineinformation on A.mc=Machineinformation.interfaceid    
			left outer join Componentinformation C on A.comp=C.interfaceid    
			left outer join Componentoperationpricing CO on A.opn=CO.interfaceid    
			and Machineinformation.Machineid=CO.Machineid and C.Componentid=CO.Componentid    
			) T1 inner join #ShiftwiseSummary on T1.mc = #ShiftwiseSummary.MachineInterface  WHERE ShiftName='DAY'
	---------------------------------------------------- DAYWISE RUNNINGCYCLE Calculation---------------------------------------------------------------


			---Query to get Machinewise Last Record from Rawdata where Datatype in 11,1,2,22,42 for peekay  
			Update #ShiftwiseSummary Set MachineStatus=T1.DownStatus From
			(select RawData.mc,
			Case when rawdata.datatype in(11,41) then 'Cycle Started'
			When rawdata.datatype=1 then 'Cycle Ended'
			When rawdata.datatype in(22,42) then  'Stopped ' + D.Downid 
			When rawdata.datatype in(2,40) then 'Stopped' 
			END as DownStatus from Rawdata
			inner join (select mc,max(slno) as slno from rawdata WITH (NOLOCK)   
			where Rawdata.sttime<@currtime and rawdata.datatype in(11,1,2,22,42) group by mc) t1 on t1.mc=rawdata.mc and t1.slno=rawdata.slno  
			Left Outer join Downcodeinformation D on rawdata.splstring2=D.interfaceid
			) T1 inner join #ShiftwiseSummary on T1.mc = #ShiftwiseSummary.MachineInterface WHERE ShiftName='DAY'

			
Update #ShiftwiseSummary Set OperatorName = isnull(T1.opr,0),LastCycletime=t1.StTime from
(Select Machineid,T.opr,t.StTime,t.shiftstart from
	(select Machineid,OperatorName as opr,sttime,ShiftStart,
	row_number() over(partition by Machineid,shiftstart order by sttime desc) as rn
	From #Runningpart_Part 
	)T where T.rn <= 1
) as T1 inner join #ShiftwiseSummary on #ShiftwiseSummary.machineid=T1.machineid  and #ShiftwiseSummary.[From time]=t1.ShiftStart

Update #ShiftwiseSummary Set OperatorName = isnull(T1.opr,0),LastCycletime=t1.StTime from
(Select Machineid,T.opr,t.StTime from
	(select Machineid,OperatorName as opr,sttime,
	row_number() over(partition by Machineid order by sttime desc) as rn
	From #Runningpart_Part 
	)T where T.rn <= 1
) as T1 inner join #ShiftwiseSummary on #ShiftwiseSummary.machineid=T1.machineid  WHERE ShiftName='DAY'

/******************************************************* SHIFTWISE SUMMARY *********************************************************/

/******************************************************* HOURWISE CO LEVEL PARTSCOUNT *********************************************************/

		----ComponentOperation level details
		CREATE TABLE #ShiftProductionFromAutodataT2 
		(
		MachineID nvarchar(50) NOT NULL,
		Component nvarchar(50) NOT NULL,
		Operation nvarchar(50) NOT NULL,
		MachineInterface nvarchar(50),
		CompInterface nvarchar(50),
		OpnInterface nvarchar(50),
		OperationCount float,
		UtilisedTime float,
		Downtime float,
		ManagementLoss Float,
		Pdate datetime not null,
		Shift nvarchar(50),
		Shiftid int,
		HourID int, 
		HourStart datetime not null,  
		HourEnd datetime 
		)
		ALTER TABLE #ShiftProductionFromAutodataT2
		ADD PRIMARY KEY CLUSTERED
		(
			[Pdate],[HourStart],
			[MachineID],
			[Component],
			[Operation]
		) ON [PRIMARY]

		CREATE TABLE #PlannedDownTimesHour
		(
		SlNo int not null identity(1,1),
		Starttime datetime,
		EndTime datetime,
		Machine nvarchar(50),
		MachineInterface nvarchar(50),
		DownReason nvarchar(50),
		HourStart datetime
		)


		insert INTO #PlannedDownTimesHour(StartTime,EndTime,Machine,MachineInterface,Downreason,HourStart)
		select
		CASE When StartTime<T1.HourStart Then T1.HourStart Else StartTime End,
		case When EndTime>T1.HourEnd Then T1.HourEnd Else EndTime End,
		Machine,M.InterfaceID,
		DownReason,T1.HourStart
		FROM PlannedDownTimes cross join #HourDetails T1
		inner join MachineInformation M on PlannedDownTimes.machine = M.MachineID
		WHERE PDTstatus =1 and (
		(StartTime >= T1.HourStart  AND EndTime <=T1.HourEnd)
		OR ( StartTime < T1.HourStart  AND EndTime <= T1.HourEnd AND EndTime > T1.HourStart )
		OR ( StartTime >= T1.HourStart   AND StartTime <T1.HourEnd AND EndTime > T1.HourEnd )
		OR ( StartTime < T1.HourStart  AND EndTime > T1.HourEnd) )
		and machine in (select distinct machine from Machineinformation)
		ORDER BY StartTime


		Select @strsql=''
		select @strsql = 'insert into #ShiftProductionFromAutodataT2 (MachineID,Component,Operation,OperationCount, '
		select @strsql = @strsql + 'Pdate,Shift,Shiftid, HourID,HourStart,HourEnd,MachineInterface,CompInterface,	OpnInterface) '
		select @strsql = @strsql + ' SELECT  distinct machineinformation.machineid, componentinformation.componentid,componentoperationpricing.operationno, '
		select @strsql = @strsql + ' (CAST(Sum(autodata.partscount)AS Float)/ISNULL(ComponentOperationPricing.SubOperations,1)) as PCount ,' 
		select @strsql = @strsql + ' Pdate,Shift,Shiftid,HourID,HourStart,HourEnd '
		select @strsql = @strsql + ',machineinformation.interfaceid,componentinformation.interfaceid,componentoperationpricing.interfaceid'
		select @strsql = @strsql + ' from #T_autodata autodata INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID '
		select @strsql = @strsql + ' INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID '
		select @strsql = @strsql + ' INNER JOIN componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID)'
		select @strsql = @strsql +' and componentoperationpricing.machineid=machineinformation.machineid '
		select @strsql = @strsql + ' AND (componentinformation.componentid = componentoperationpricing.componentid) '
		select @strsql = @strsql + ' Left Outer Join PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID '
		select @strsql = @strsql + ' cross join  #HourDetails   '
		select @strsql = @strsql + ' where machineinformation.interfaceid > 0 '
		select @strsql = @strsql + 'and (( sttime >= HourStart and ndtime <= HourEnd ) OR '
		select @strsql = @strsql + '( sttime < HourStart and ndtime > HourStart and ndtime<=HourEnd ))'
		select @strsql = @strsql + ' and autodata.datatype=1 '
		select @strsql = @strsql + ' AND (autodata.partscount > 0 ) '
		select @strsql = @strsql + ' group by machineinformation.machineid, componentinformation.componentid, '
		select @strsql = @strsql + ' componentoperationpricing.operationno, '
		select @strsql = @strsql + ' Pdate,Shift,Shiftid,HourID,HourStart,HourEnd,ComponentOperationPricing.SubOperations '
		select @strsql = @strsql + ',machineinformation.interfaceid,componentinformation.interfaceid,componentoperationpricing.interfaceid order by  Hourstart asc,machineinformation.machineid '
		print @strsql
		Exec(@strsql)


		---mod 12 : Neglect count overlapping with PDT
		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
		BEGIN

		UPDATE #ShiftProductionFromAutodataT2 SET OperationCount=ISNULL(OperationCount,0)- isnull(t2.PlanCt,0)
		FROM ( select T.Hourstart as intime,Machineinformation.machineid as machine,
		((CAST(Sum(ISNULL(PartsCount,1)) AS Float)/ISNULL(Componentoperationpricing.SubOperations,1))) as PlanCt, --NR0097
		Componentinformation.componentid as compid,componentoperationpricing.Operationno as opnno from  autodata --ER0324 Added
		Inner jOIN #PlannedDownTimesHour T on T.MachineInterface=autodata.mc  
		inner join machineinformation on autodata.mc=machineinformation.Interfaceid
		Inner join componentinformation on autodata.comp=componentinformation.interfaceid 
		inner join componentoperationpricing on autodata.opn=componentoperationpricing.interfaceid and
		componentinformation.componentid=componentoperationpricing.componentid  and componentoperationpricing.machineid=machineinformation.machineid
		WHERE autodata.DataType=1
		AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)
		 Group by Machineinformation.machineid,componentinformation.componentid ,componentoperationpricing.Operationno,componentoperationpricing.SubOperations,T.Hourstart

		) as T2 inner join #ShiftProductionFromAutodataT2 S on T2.machine = S.machineid  and T2.compid=S.Component and   t2.opnno=S.Operation and  t2.intime=S.Hourstart

		END

/******************************************************* HOURWISE CO LEVEL PARTSCOUNT *********************************************************/


/******************************************************* HOURWISE SUMMARY *********************************************************/

		CREATE TABLE #ShiftProductionFromAutodataT1
		(
		PlantID nvarchar(50),
		MachineID nvarchar(50),
		MachineInterface nvarchar(50),
		UtilisedTime float,
		Downtime float,
		ManagementLoss Float,
		MLdown float,
		Pdate datetime not null,
		Shift nvarchar(50),
		Shiftid int,
		HourID int, 
		HourStart datetime ,  
		HourEnd datetime,
		ppt float,
		tt float
		)


		Insert into #ShiftProductionFromAutodataT1(PlantID,MachineID,MachineInterface,PDate,Shift,Shiftid, HourID,HourStart,HourEnd,UtilisedTime,Downtime,PPT)
		SELECT distinct Plantmachine.PlantID,Machineinformation.machineid,Machineinformation.interfaceid,S.PDate,S.Shift,S.Shiftid,S.Hourid,S.Hourstart,S.Hourend,0,0,0 FROM dbo.Machineinformation  
		left outer join dbo.Plantmachine on Machineinformation.machineid=Plantmachine.machineid  
		Cross join #HourDetails S where Plantmachine.PlantID IS NOT NULL AND Machineinformation.TPMTrakenabled=1  

		TRUNCATE TABLE #PlannedDownTimesHour

		insert INTO #PlannedDownTimesHour(StartTime,EndTime,Machine,MachineInterface,Downreason,HourStart)
		select
		CASE When StartTime<T1.HourStart Then T1.HourStart Else StartTime End,
		case When EndTime>T1.HourEnd Then T1.HourEnd Else EndTime End,
		Machine,M.InterfaceID,
		DownReason,T1.HourStart
		FROM PlannedDownTimes cross join #HourDetails T1
		inner join MachineInformation M on PlannedDownTimes.machine = M.MachineID
		WHERE PDTstatus =1 and (
		(StartTime >= T1.HourStart  AND EndTime <=T1.HourEnd)
		OR ( StartTime < T1.HourStart  AND EndTime <= T1.HourEnd AND EndTime > T1.HourStart )
		OR ( StartTime >= T1.HourStart   AND StartTime <T1.HourEnd AND EndTime > T1.HourEnd )
		OR ( StartTime < T1.HourStart  AND EndTime > T1.HourEnd) )
		and machine in (select distinct machine from Machineinformation)
		ORDER BY StartTime


		-- Get the utilised time
		--mod 4
		-- Type 1,2,3,4
		UPDATE #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
		from
		(select      mc,
		sum(case when ( (autodata.msttime>=S.Hourstart) and (autodata.ndtime<=S.HourEnd)) then  (cycletime+loadunload)
		 when ((autodata.msttime<S.Hourstart)and (autodata.ndtime>S.Hourstart)and (autodata.ndtime<=S.HourEnd)) then DateDiff(second, S.Hourstart, ndtime)
		 when ((autodata.msttime>=S.Hourstart)and (autodata.msttime<S.HourEnd)and (autodata.ndtime>S.HourEnd)) then DateDiff(second, mstTime, S.HourEnd)
		 when ((autodata.msttime<S.Hourstart)and (autodata.ndtime>S.HourEnd)) then DateDiff(second, S.Hourstart, S.HourEnd) END ) as cycle,S.Hourstart as ShiftStart
		from #T_autodata autodata inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface --ER0324 Added
		where (autodata.datatype=1) AND(( (autodata.msttime>=S.Hourstart) and (autodata.ndtime<=S.HourEnd))
		OR ((autodata.msttime<S.Hourstart)and (autodata.ndtime>S.Hourstart)and (autodata.ndtime<=S.HourEnd))
		OR ((autodata.msttime>=S.Hourstart)and (autodata.msttime<S.HourEnd)and (autodata.ndtime>S.HourEnd))
		OR((autodata.msttime<S.Hourstart)and (autodata.ndtime>S.HourEnd)))
		group by autodata.mc,S.Hourstart
		) as t2 inner join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
		and t2.ShiftStart=#ShiftProductionFromAutodataT1.Hourstart


		-------For Type2
		UPDATE  #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
		FROM
		(Select AutoData.mc ,
		SUM(
		CASE
		When autodata.sttime <= T1.Hourstart Then datediff(s, T1.Hourstart,autodata.ndtime )
		When autodata.sttime > T1.Hourstart Then datediff(s , autodata.sttime,autodata.ndtime)
		END) as Down,t1.Hourstart as ShiftStart,T1.PDate as PDate
		from #T_autodata autodata INNER Join
		(Select mc,Sttime,NdTime,Hourstart,HourEnd,PDate from #T_autodata autodata
		inner join #ShiftProductionFromAutodataT1 ST1 ON ST1.MachineInterface=Autodata.mc
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(msttime < Hourstart)And (ndtime > Hourstart) AND (ndtime <= HourEnd)
		) as T1 on t1.mc=autodata.mc
		Where AutoData.DataType=2
		And ( autodata.Sttime > T1.Sttime )
		And ( autodata.ndtime <  T1.ndtime )
		AND ( autodata.ndtime >  T1.Hourstart )
		GROUP BY AUTODATA.mc,T1.Hourstart,T1.PDate)AS T2 Inner Join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
		and T2.PDate = #ShiftProductionFromAutodataT1.PDate and t2.ShiftStart=#ShiftProductionFromAutodataT1.Hourstart



		--Type 3
		UPDATE  #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
		FROM
		(Select AutoData.mc ,
		SUM(CASE
		When autodata.ndtime > T1.HourEnd Then datediff(s,autodata.sttime, T1.HourEnd )
		When autodata.ndtime <=T1.HourEnd Then datediff(s , autodata.sttime,autodata.ndtime)
		END) as Down,T1.Hourstart as ShiftStart,T1.PDate as PDate
		from #T_autodata autodata INNER Join
		(Select mc,Sttime,NdTime,Hourstart,HourEnd,PDate from #T_autodata autodata
		inner join #ShiftProductionFromAutodataT1 ST1 ON ST1.MachineInterface =Autodata.mc
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(sttime >= Hourstart)And (ndtime >HourEnd) and (sttime< HourEnd)
		) as T1
		ON AutoData.mc=T1.mc
		Where AutoData.DataType=2
		And (T1.Sttime < autodata.sttime  )
		And ( T1.ndtime >  autodata.ndtime)
		AND (autodata.sttime  <  T1.HourEnd)
		GROUP BY AUTODATA.mc,T1.Hourstart,T1.PDate )AS T2 Inner Join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
		and t2.PDate=#ShiftProductionFromAutodataT1.PDate and t2.ShiftStart=#ShiftProductionFromAutodataT1.Hourstart


		--For Type4
		UPDATE  #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
		FROM
		(Select AutoData.mc ,
		SUM(CASE
		When autodata.sttime >= T1.Hourstart AND autodata.ndtime <= T1.HourEnd Then datediff(s , autodata.sttime,autodata.ndtime)
		When autodata.sttime < T1.Hourstart And autodata.ndtime >T1.Hourstart AND autodata.ndtime<=T1.HourEnd Then datediff(s, T1.Hourstart,autodata.ndtime )
		When autodata.sttime >= T1.Hourstart AND autodata.sttime<T1.HourEnd AND autodata.ndtime>T1.HourEnd Then datediff(s,autodata.sttime, T1.HourEnd )
		When autodata.sttime<T1.Hourstart AND autodata.ndtime>T1.HourEnd   Then datediff(s , T1.Hourstart,T1.HourEnd)
		END) as Down,T1.Hourstart as ShiftStart,T1.PDate as PDate
		from #T_autodata autodata INNER Join
		(Select mc,Sttime,NdTime,Hourstart,HourEnd,PDate from #T_autodata autodata
		inner join #ShiftProductionFromAutodataT1 ST1 ON ST1.MachineInterface =Autodata.mc
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(msttime < Hourstart)And (ndtime >HourEnd)

		) as T1
		ON AutoData.mc=T1.mc
		Where AutoData.DataType=2
		And (T1.Sttime < autodata.sttime  )
		And ( T1.ndtime >  autodata.ndtime)
		AND (autodata.ndtime  >  T1.Hourstart)
		AND (autodata.sttime  <  T1.HourEnd)
		GROUP BY AUTODATA.mc,T1.Hourstart,T1.PDate
		)AS T2 Inner Join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
		and T2.PDate = #ShiftProductionFromAutodataT1.PDate and t2.ShiftStart=#ShiftProductionFromAutodataT1.Hourstart

		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
		BEGIN

		--get the utilised time overlapping with PDT and negate it from UtilisedTime
		UPDATE  #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.PlanDT,0)
		from( select T.HourStart as intime,T.Machine as machine,sum (CASE
		WHEN (autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN DateDiff(second,autodata.msttime,autodata.ndtime) --DR0325 Added
		WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
		WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )
		WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
		END ) as PlanDT
		from #T_autodata autodata CROSS jOIN #PlannedDownTimesHour T --ER0324 Added
		WHERE autodata.DataType=1   and T.MachineInterface=autodata.mc AND(
		(autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
		OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
		OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )
		OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime)
		)
		group by T.Machine,T.HourStart ) as t2 inner join #ShiftProductionFromAutodataT1 S on t2.intime=S.HourStart and t2.machine=S.machineId


		---mod 12:Add ICD's Overlapping  with PDT to UtilisedTime
		/* Fetching Down Records from Production Cycle  */
		---mod 12(4):Handle intearction between ICD and PDT for type 1 production record for the selected time period.
		UPDATE  #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)
		FROM	(
		Select T.HourStart as intime,AutoData.mc,
		SUM(
		CASE 	
			When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
			When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
			When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
			when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		from #T_autodata autodata INNER Join --ER0324 Added
			(Select mc,Sttime,NdTime,S.HourStart as StartTime from #T_autodata autodata inner join #ShiftProductionFromAutodataT1 S on S.MachineInterface=autodata.mc
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(msttime >= S.HourStart) AND (ndtime <= S.HourEnd)) as T1
		ON AutoData.mc=T1.mc CROSS jOIN #PlannedDownTimesHour T
		Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc
		And (( autodata.Sttime >= T1.Sttime ) --DR0339
		And ( autodata.ndtime <= T1.ndtime ) --DR0339
		)
		AND
		((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
		or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
		or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
		or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )
		GROUP BY AUTODATA.mc,T.HourStart
		)AS T2  INNER JOIN #ShiftProductionFromAutodataT1 ON
		T2.mc = #ShiftProductionFromAutodataT1.MachineInterface and  t2.intime=#ShiftProductionFromAutodataT1.HourStart


		---mod 12(4)
		/* If production  Records of TYPE-2*/
		UPDATE  #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)
		FROM
		(Select T.HourStart as intime,AutoData.mc ,
		SUM(
		CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		from #T_autodata autodata CROSS jOIN #PlannedDownTimesHour T INNER Join --ER0324 Added
		(Select mc,Sttime,NdTime,S.HourStart as StartTime from #T_autodata autodata inner join #ShiftProductionFromAutodataT1 S on S.MachineInterface=autodata.mc
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(msttime < S.HourStart)And (ndtime > S.HourStart) AND (ndtime <= S.HourEnd)) as T1
		ON AutoData.mc=T1.mc  and T1.StartTime=T.HourStart
		Where AutoData.DataType=2  and T.MachineInterface=autodata.mc
		And (( autodata.Sttime > T1.Sttime )
		And ( autodata.ndtime <  T1.ndtime )
		AND ( autodata.ndtime >  T1.StartTime ))
		AND
		(( T.StartTime >= T1.StartTime )
		And ( T.StartTime <  T1.ndtime ) )
		GROUP BY AUTODATA.mc,T.HourStart )AS T2  INNER JOIN #ShiftProductionFromAutodataT1 ON
		T2.mc = #ShiftProductionFromAutodataT1.MachineInterface and  t2.intime=#ShiftProductionFromAutodataT1.HourStart



		/* If production Records of TYPE-3*/
		UPDATE  #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)
		FROM
		(Select T.HourStart as intime,AutoData.mc ,
		SUM(
		CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		from #T_autodata autodata CROSS jOIN #PlannedDownTimesHour T INNER Join --ER0324 Added
		(Select mc,Sttime,NdTime,S.HourStart as StartTime,S.HourEnd as EndTime from #T_autodata autodata inner join #ShiftProductionFromAutodataT1 S on S.MachineInterface=autodata.mc
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(sttime >= S.HourStart)And (ndtime > S.HourEnd) and autodata.sttime <S.HourEnd) as T1
		ON AutoData.mc=T1.mc and T1.StartTime=T.HourStart
		Where AutoData.DataType=2  and T.MachineInterface=autodata.mc
		And ((T1.Sttime < autodata.sttime  )
		And ( T1.ndtime >  autodata.ndtime)
		AND (autodata.sttime  <  T1.EndTime))
		AND
		(( T.EndTime > T1.Sttime )
		And ( T.EndTime <=T1.EndTime ) )
		GROUP BY AUTODATA.mc,T.HourStart)AS T2   INNER JOIN #ShiftProductionFromAutodataT1 ON
		T2.mc = #ShiftProductionFromAutodataT1.MachineInterface and  t2.intime=#ShiftProductionFromAutodataT1.HourStart



		/* If production Records of TYPE-4*/
		UPDATE  #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)
		FROM
		(Select T.HourStart as intime,AutoData.mc ,
		SUM(
		CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		from #T_autodata autodata CROSS jOIN #PlannedDownTimesHour T INNER Join --ER0324 Added
		(Select mc,Sttime,NdTime,S.HourStart as StartTime,S.HourEnd as EndTime from #T_autodata autodata inner join #ShiftProductionFromAutodataT1 S on S.MachineInterface=autodata.mc
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(msttime < S.HourStart)And (ndtime > S.HourEnd)) as T1
		ON AutoData.mc=T1.mc and T1.StartTime=T.HourStart
		Where AutoData.DataType=2 and T.MachineInterface=autodata.mc
		And ( (T1.Sttime < autodata.sttime  )
		And ( T1.ndtime >  autodata.ndtime)
		AND (autodata.ndtime  >  T1.StartTime)
		AND (autodata.sttime  <  T1.EndTime))
		AND
		(( T.StartTime >=T1.StartTime)
		And ( T.EndTime <=T1.EndTime ) )
		GROUP BY AUTODATA.mc,T.HourStart)AS T2  INNER JOIN #ShiftProductionFromAutodataT1 ON
		T2.mc = #ShiftProductionFromAutodataT1.MachineInterface and  t2.intime=#ShiftProductionFromAutodataT1.HourStart

		END



		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y')
		BEGIN
		--Type 1
		UPDATE #ShiftProductionFromAutodataT1 SET downtime = isnull(downtime,0) + isNull(t2.down,0)
		from
		(select mc,
		sum(loadunload) down,S.HourStart as ShiftStart
		from #T_autodata autodata inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface --ER0324 Added
		where (autodata.msttime>=S.HourStart)
		and (autodata.ndtime<= S.HourEnd)
		and (autodata.datatype=2)
		group by autodata.mc,S.HourStart
		) as t2 inner join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
		and t2.ShiftStart=#ShiftProductionFromAutodataT1.HourStart

		-- Type 2
		UPDATE #ShiftProductionFromAutodataT1 SET downtime = isnull(downtime,0) + isNull(t2.down,0)
		from
		(select mc,
		sum(DateDiff(second, S.HourStart, ndtime)) down,S.HourStart as ShiftStart
		from #T_autodata autodata inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface --ER0324 Added
		where (autodata.sttime<S.HourStart)
		and (autodata.ndtime>S.HourStart)
		and (autodata.ndtime<= S.HourEnd)
		and (autodata.datatype=2)
		group by autodata.mc,S.HourStart
		) as t2 inner join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
		and t2.ShiftStart=#ShiftProductionFromAutodataT1.HourStart


		-- Type 3
		UPDATE #ShiftProductionFromAutodataT1 SET downtime = isnull(downtime,0) + isNull(t2.down,0)
		from
		(select mc,
		sum(DateDiff(second, stTime,  S.HourEnd)) down,S.HourStart as ShiftStart
		from #T_autodata autodata inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface --ER0324 Added
		where (autodata.msttime>=S.HourStart)
		and (autodata.sttime< S.HourEnd)
		and (autodata.ndtime> S.HourEnd)
		and (autodata.datatype=2)group by autodata.mc,S.HourStart
		) as t2 inner join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
		and t2.ShiftStart=#ShiftProductionFromAutodataT1.HourStart


		-- Type 4
		UPDATE #ShiftProductionFromAutodataT1 SET downtime = isnull(downtime,0) + isNull(t2.down,0)
		from
		(select mc,
		sum(DateDiff(second, S.HourStart,  S.HourEnd)) down,S.HourStart as ShiftStart
		from #T_autodata autodata inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface --ER0324 Added
		where autodata.msttime<S.HourStart
		and autodata.ndtime> S.HourEnd
		and (autodata.datatype=2)group by autodata.mc,S.HourStart
		) as t2 inner join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
		and t2.ShiftStart=#ShiftProductionFromAutodataT1.HourStart
		--END: Get the Down Time


		---Management Loss-----
		-- Type 1
		UPDATE #ShiftProductionFromAutodataT1 SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
		from
		(select      mc,
		sum(CASE
		WHEN loadunload >ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)
		ELSE loadunload
		END) loss,S.HourStart as ShiftStart
		from #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid 
		inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface --ER0324 Added
		where (autodata.msttime>=S.HourStart)
		and (autodata.ndtime<=S.HourEnd)
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1)
		group by autodata.mc,S.HourStart
		) as t2 inner join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
		and t2.ShiftStart=#ShiftProductionFromAutodataT1.HourStart

		-- Type 2
		UPDATE #ShiftProductionFromAutodataT1 SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
		from
		(select      mc,
		sum(CASE
		WHEN DateDiff(second, S.HourStart, ndtime)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)
		ELSE DateDiff(second, S.HourStart, ndtime)
		end) loss,S.HourStart as ShiftStart
		from #T_autodata autodata --ER0324 Added
		INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface
		where (autodata.sttime<S.HourStart)
		and (autodata.ndtime>S.HourStart)
		and (autodata.ndtime<=S.HourEnd)
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1)
		group by autodata.mc,S.HourStart
		) as t2 inner join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
		and t2.ShiftStart=#ShiftProductionFromAutodataT1.HourStart

		-- Type 3
		UPDATE #ShiftProductionFromAutodataT1 SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
		from
		(select      mc,
		sum(CASE
		WHEN DateDiff(second, stTime, S.HourEnd)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)ELSE DateDiff(second, stTime, S.HourEnd)
		END) loss,S.HourStart as ShiftStart
		from #T_autodata autodata  --ER0324 Added
		INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface
		where (autodata.msttime>=S.HourStart)
		and (autodata.sttime<S.HourEnd)
		and (autodata.ndtime>S.HourEnd)
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1)
		group by autodata.mc,S.HourStart
		) as t2 inner join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
		and t2.ShiftStart=#ShiftProductionFromAutodataT1.HourStart

		-- Type 4
		UPDATE #ShiftProductionFromAutodataT1 SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
		from
		(select mc,
		sum(CASE
		WHEN DateDiff(second, S.HourStart, S.HourEnd)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)
		ELSE DateDiff(second, S.HourStart, S.HourEnd)
		END) loss,S.HourStart as ShiftStart
		from #T_autodata autodata --ER0324 Added
		INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface
		where autodata.msttime<S.HourStart
		and autodata.ndtime>S.HourEnd
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1)
		group by autodata.mc,S.HourStart
		) as t2 inner join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
		and t2.ShiftStart=#ShiftProductionFromAutodataT1.HourStart


		if (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y'
		begin

		UPDATE #ShiftProductionFromAutodataT1 SET downtime = isnull(downtime,0) - isNull(t2.PldDown,0)
		from(
		select T.Hourstart  as intime,T.Machine as machine,SUM
			   (CASE
			WHEN (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN autodata.loadunload
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PldDown
		from #T_autodata autodata CROSS jOIN #PlannedDownTimesHour T --ER0324 Added
		INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID
		WHERE autodata.DataType=2  and T.MachineInterface=autodata.mc  AND(
		(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
		OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
		OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
		OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
		)
		AND DownCodeInformation.DownID=(SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')
		group by T.Machine,T.Hourstart ) as t2 inner join #ShiftProductionFromAutodataT1 S on t2.intime=S.HourStart and t2.machine=S.machineId

		end
		---mod 12
		END


		---mod 12:Get the down time and Management loss when setting for 'Ignore_Dtime_4m_PLD'='Y'
		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
		BEGIN
		---Get the down times which are not of type Management Loss
		UPDATE #ShiftProductionFromAutodataT1 SET downtime = isnull(downtime,0) + isNull(t2.down,0)
		from
		(select      mc,
		sum(case when ( (autodata.msttime>=S.HourStart) and (autodata.ndtime<=S.HourEnd)) then  loadunload
			 when ((autodata.sttime<S.HourStart)and (autodata.ndtime>S.HourStart)and (autodata.ndtime<=S.HourEnd)) then DateDiff(second, S.HourStart, ndtime)
			 when ((autodata.msttime>=S.HourStart)and (autodata.msttime<S.HourEnd)and (autodata.ndtime>S.HourEnd)) then DateDiff(second, stTime, S.HourEnd)
			 when ((autodata.msttime<S.HourStart)and (autodata.ndtime>S.HourEnd)) then DateDiff(second, S.HourStart, S.HourEnd) END ) as down,S.HourStart as ShiftStart
		from #T_autodata autodata --ER0324 Added
		inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface
		inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		where (autodata.datatype=2) AND(( (autodata.msttime>=S.HourStart) and (autodata.ndtime<=S.HourEnd))
		  OR ((autodata.msttime<S.HourStart)and (autodata.ndtime>S.HourStart)and (autodata.ndtime<=S.HourEnd))
		  OR ((autodata.msttime>=S.HourStart)and (autodata.msttime<S.HourEnd)and (autodata.ndtime>S.HourEnd))
		  OR((autodata.msttime<S.HourStart)and (autodata.ndtime>S.HourEnd))) AND (downcodeinformation.availeffy = 0)
		  group by autodata.mc,S.HourStart
		) as t2 inner join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
		and t2.ShiftStart=#ShiftProductionFromAutodataT1.HourStart


		UPDATE #ShiftProductionFromAutodataT1 SET downtime = isnull(downtime,0) - isNull(t2.PldDown,0)
		from(
		select T.Hourstart  as intime,T.Machine as machine,SUM
			   (CASE
			WHEN (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN autodata.loadunload
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PldDown
		from #T_autodata autodata  --ER0324 Added
		CROSS jOIN #PlannedDownTimesHour T
		INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID
		WHERE autodata.DataType=2  and T.MachineInterface=autodata.mc  AND(
		(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
		OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
		OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
		OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
		)
		AND (downcodeinformation.availeffy = 0)
		group by T.Machine,T.Hourstart ) as t2 inner join #ShiftProductionFromAutodataT1 S on t2.intime=S.HourStart and t2.machine=S.machineId


		UPDATE #ShiftProductionFromAutodataT1 SET ManagementLoss = isnull(ManagementLoss,0)+ isNull(t4.Mloss,0),MLDown=isNull(MLDown,0)+isNull(t4.Dloss,0)
		from
		(select T3.mc,T3.StrtShft,sum(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss from
		(
		select   t1.id,T1.mc,T1.Threshold,T1.StartShift as StrtShft,
		case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0) > 0
		then DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)- isnull(T1.Threshold ,0)
		else 0 End  as Dloss,
		case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0) > 0
		then isnull(T1.Threshold,0)
		else DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0) End  as Mloss
		from

		(   select id,mc,comp,opn,opr,D.threshold,S.HourStart as StartShift,
		case when autodata.sttime<S.HourStart then S.HourStart else sttime END as sttime,
   			case when ndtime>S.HourEnd then S.HourEnd else ndtime END as ndtime
		from #T_autodata autodata --ER0324 Added
		inner join downcodeinformation D
		on autodata.dcode=D.interfaceid inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface
		where autodata.datatype=2 AND
		(
		(autodata.msttime>=S.HourStart  and  autodata.ndtime<=S.HourEnd)
		OR (autodata.sttime<S.HourStart and  autodata.ndtime>S.HourStart and autodata.ndtime<=S.HourEnd)
		OR (autodata.msttime>=S.HourStart  and autodata.sttime<S.HourEnd  and autodata.ndtime>S.HourEnd)
		OR (autodata.msttime<S.HourStart and autodata.ndtime>S.HourEnd )
		) AND (D.availeffy = 1)) as T1 	
		left outer join
		(SELECT T.Hourstart  as intime, autodata.id,
			   sum(CASE
			WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PPDT
		from #T_autodata autodata  --ER0324 Added
		CROSS jOIN #PlannedDownTimesHour T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		WHERE autodata.DataType=2 and T.MachineInterface=autodata.mc AND
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)
			 AND (downcodeinformation.availeffy = 1) group by autodata.id,T.Hourstart ) as T2 on T1.id=T2.id  and T1.StartShift=T2.intime ) as T3  group by T3.mc,T3.StrtShft
		) as t4 inner join #ShiftProductionFromAutodataT1 S on t4.StrtShft=S.HourStart and t4.mc=S.MachineInterface

		UPDATE #ShiftProductionFromAutodataT1  set downtime = isnull(downtime,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)

		END

		Update #ShiftProductionFromAutodataT1 SET TT = DateDiff(second, Hourstart, HourEnd)

		update #ShiftProductionFromAutodataT1 SET PPT=(TT - (TT - (ISNULL(UtilisedTime,0) + (ISNULL(downtime,0) - ISNULL(ManagementLoss,0)))))
/******************************************************* HOURWISE SUMMARY *********************************************************/



/******************************************************* SHIFTWISE DOWNSTART AND DOWNEND *********************************************************/
insert into #Shift_MachinewiseStoppages(PlantID,Machineid,Shiftdate,Shiftid,Shiftname,fromtime,totime,BatchTS,Batchstart,BatchEnd,MachineStatus,Stoppagetime,Reason)
SELECT L1.PlantID,L1.Machineid,L1.Shiftdate,L1.Shiftid,L1.Shiftname,L1.[From Time],L1.[To Time],null,
case when autodata.sttime< L1.[From Time]  then  L1.[From Time]  else autodata.sttime end AS StartTime,
case when autodata.ndtime>L1.[To Time] then L1.[To Time] else autodata.ndtime end AS EndTime,
downcodeinformation.downid AS DownID,
case
When (autodata.sttime >= L1.[From Time] AND autodata.ndtime <= L1.[To Time] ) THEN loadunload
WHEN ( autodata.sttime < L1.[From Time] AND autodata.ndtime <= L1.[To Time] AND autodata.ndtime > L1.[From Time] ) THEN DateDiff(second, L1.[From Time], ndtime)
WHEN ( autodata.sttime >= L1.[From Time] AND autodata.sttime < L1.[To Time] AND autodata.ndtime > L1.[To Time] ) THEN  DateDiff(second, stTime, L1.[To Time])
ELSE
DateDiff(second, L1.[From Time], L1.[To Time])END AS DownTime,
downcodeinformation.downdescription
FROM         autodata INNER JOIN
machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN
downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
LEFT OUTER JOIN employeeinformation ON autodata.opr = employeeinformation.interfaceid 
inner join #ShiftwiseSummary L1 on L1.machineid=machineinformation.machineid 
WHERE autodata.datatype = 2 AND 
(
(autodata.sttime >= L1.[From Time]  AND autodata.ndtime <=L1.[To Time])
OR ( autodata.sttime < L1.[From Time]  AND autodata.ndtime <= L1.[To Time] AND autodata.ndtime > L1.[From Time] )
OR ( autodata.sttime >= L1.[From Time]   AND autodata.sttime <L1.[To Time] AND autodata.ndtime > L1.[To Time] )
OR ( autodata.sttime < L1.[From Time]  AND autodata.ndtime > L1.[To Time])
)
ORDER BY L1.Machineid,autodata.ndtime




If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
BEGIN
update #Shift_MachinewiseStoppages set Stoppagetime = isnull(Stoppagetime,0)-isnull(TT.plannedDT,0)
	from
(
	Select A.Batchstart as  StartTime,A.BatchEnd as EndTime,A.fromtime, A.totime,			
			sum(case
			WHEN A.Batchstart >= T.StartTime  AND A.BatchEnd <=T.EndTime  THEN A.Stoppagetime
			WHEN ( A.Batchstart < T.StartTime  AND A.BatchEnd <= T.EndTime  AND A.BatchEnd > T.StartTime ) THEN DateDiff(second,T.StartTime,A.BatchEnd)
			WHEN ( A.Batchstart >= T.StartTime   AND A.Batchstart <T.EndTime  AND A.BatchEnd > T.EndTime  ) THEN DateDiff(second,A.Batchstart,T.EndTime )
			WHEN ( A.Batchstart < T.StartTime  AND A.BatchEnd > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END) as plannedDT
	From #Shift_MachinewiseStoppages A CROSS jOIN PlannedDownTimes T
			WHERE  T.machine=A.Machineid  and pdtstatus=1 and 
			((A.Batchstart >= T.StartTime  AND A.BatchEnd <=T.EndTime)
			OR ( A.Batchstart < T.StartTime  AND A.BatchEnd <= T.EndTime AND A.BatchEnd > T.StartTime )
			OR ( A.Batchstart >= T.StartTime   AND A.Batchstart <T.EndTime AND A.BatchEnd > T.EndTime )
			OR ( A.Batchstart < T.StartTime  AND A.BatchEnd > T.EndTime))
			and
			((A.fromtime >= T.StartTime  AND A.totime  <=T.EndTime)
			OR ( A.fromtime < T.StartTime  AND A.totime  <= T.EndTime AND A.totime > T.StartTime )
			OR ( A.fromtime >= T.StartTime   AND A.fromtime  <T.EndTime AND A.totime > T.EndTime )
			OR ( A.fromtime < T.StartTime  AND A.totime  > T.EndTime))
			group by A.Batchstart,A.BatchEnd,A.fromtime, A.totime
)TT
INNER JOIN #Shift_MachinewiseStoppages ON TT.StartTime=#Shift_MachinewiseStoppages.Batchstart and TT.EndTime=#Shift_MachinewiseStoppages.BatchEnd
and TT.fromtime = #Shift_MachinewiseStoppages.fromtime and TT.totime =#Shift_MachinewiseStoppages.totime
END



/******************************************************* SHIFTWISE DOWNSTART AND DOWNEND *********************************************************/

/******************************************************* SHIFTWISE DOWNTIME SUMMARY *********************************************************/

		CREATE TABLE #DownTimeData
		(
			[Sl No] Bigint Identity(1,1) Not Null, 
			[PlantID] nvarchar(50), 
			MachineID nvarchar(50) NOT NULL,
			MachineInterface nvarchar(4),
			DownID nvarchar(50) NOT NULL,
			DownReason nvarchar(50)  ,
			downtime float,
			DownFreq int,
			ShiftDate datetime,
			fromtime datetime,
			totime datetime,
			Shiftid int,
			Shiftname nvarchar(50)
			
		)


		insert into #DownTimeData (plantid,machineid,MachineInterface,ShiftDate,fromtime,totime,Shiftid,ShiftName,Downid,DownReason)
		SELECT distinct Plantmachine.PlantID,Machineinformation.machineid,Machineinformation.interfaceid, S.PDate,S.shiftstart,S.shiftend,S.ShiftID,S.Shift,downcodeinformation.interfaceid,downcodeinformation.downdescription 
		FROM dbo.Machineinformation  CROSS JOIN downcodeinformation
		left outer join dbo.Plantmachine on Machineinformation.machineid=Plantmachine.machineid  
		Cross join (Select T.Pdate, T.Shift, S.ShiftID , T.ShiftStart, T.ShiftEnd from #ShiftDetails T inner join Shiftdetails S on S.Shiftname=T.Shift where S.Running=1) S
		where Plantmachine.PlantID IS NOT NULL AND Machineinformation.TPMTrakenabled=1 



		--Type 1,2,3 and 4.
		UPDATE #DownTimeData SET DownTime =isnull(DownTime,0) + isnull(t2.down,0) ,DownFreq=dwnfrq
		FROM
		(SELECT mc,count(mc)as dwnfrq,#DownTimeData.fromtime,#DownTimeData.totime,
		SUM(CASE
		WHEN (autodata.sttime>=#DownTimeData.fromtime  and autodata.ndtime<= #DownTimeData.totime ) THEN loadunload
		WHEN (autodata.sttime<#DownTimeData.fromtime  and autodata.ndtime>#DownTimeData.fromtime and autodata.ndtime<=#DownTimeData.totime) THEN DateDiff(second, #DownTimeData.fromtime, ndtime)
		WHEN (autodata.sttime>=#DownTimeData.fromtime  and autodata.sttime<#DownTimeData.totime and autodata.ndtime>#DownTimeData.totime) THEN DateDiff(second, stTime, #DownTimeData.totime)
		ELSE DateDiff(second,#DownTimeData.fromtime,#DownTimeData.totime)
		END) as down,
		#DownTimeData.Downid 
		from #T_autodata autodata INNER JOIN
		machineinformation ON autodata.mc = machineinformation.InterfaceID 
		Left Outer Join PlantMachine ON PlantMachine.MachineID=machineinformation.MachineID 
		INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID 
		INNER JOIN employeeinformation ON autodata.opr = employeeinformation.interfaceid 
		INNER JOIN #DownTimeData ON autodata.mc=#DownTimeData.MachineInterface and  autodata.dcode = #DownTimeData.downid
		where  datatype=2 AND ((autodata.sttime>=#DownTimeData.fromtime and autodata.ndtime<=#DownTimeData.totime )OR
		(autodata.sttime<#DownTimeData.fromtime and autodata.ndtime>#DownTimeData.fromtime and autodata.ndtime<= #DownTimeData.totime)OR
		(autodata.sttime>=#DownTimeData.fromtime and autodata.sttime<#DownTimeData.totime and autodata.ndtime> #DownTimeData.totime)OR
		(autodata.sttime<#DownTimeData.fromtime and autodata.ndtime>#DownTimeData.totime))
		group by autodata.mc,#DownTimeData.Downid,#DownTimeData.fromtime,#DownTimeData.totime)
		as t2 inner join #DownTimeData on t2.mc=#DownTimeData.MachineInterface and t2.downid=#DownTimeData.downid and t2.fromtime = #DownTimeData.fromtime and t2.totime = #DownTimeData.totime


		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
		BEGIN
		UPDATE #DownTimeData  SET  DownTime =isnull(DownTime,0) - isNull(TT.PPDT ,0),DownFreq=dwnfrq
		FROM(	
		SELECT autodata.MC,count(mc)as dwnfrq,#DownTimeData.fromtime,#DownTimeData.totime,#DownTimeData.Downid , SUM
			   (CASE
			WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PPDT
		from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T
		Inner Join #DownTimeData On autodata.mc=#DownTimeData.MachineInterface and AutoData.DCode=#DownTimeData.DownId
		WHERE autodata.DataType=2 AND T.MachineInterface = AutoData.mc And
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)
			AND
			(
			(autodata.sttime >= #DownTimeData.fromtime   AND autodata.ndtime <=#DownTimeData.totime)
			OR ( autodata.sttime < #DownTimeData.fromtime   AND autodata.ndtime <= #DownTimeData.totime AND autodata.ndtime > #DownTimeData.fromtime  )
			OR ( autodata.sttime >= #DownTimeData.fromtime    AND autodata.sttime < #DownTimeData.totime AND autodata.ndtime > #DownTimeData.totime )
			OR ( autodata.sttime < #DownTimeData.fromtime   AND autodata.ndtime > #DownTimeData.totime)
			)
		group by autodata.mc,DownId,#DownTimeData.fromtime,#DownTimeData.totime
		) as TT INNER JOIN #DownTimeData ON TT.mc = #DownTimeData.MachineInterface AND #DownTimeData.DownID=TT.DownId and TT.fromtime = #DownTimeData.fromtime and TT.totime = #DownTimeData.totime

		END

		Update #ShiftwiseSummary SET MaxDownReason = MaxDownReasonTime
		From (select A.MachineID as MachineID,A.fromtime,
		SUBSTRING(MAx(D.DownID),1,6)+ '-'+ SUBSTRING(dbo.f_FormatTime(A.DownTime,'hh:mm:ss'),1,5) as MaxDownReasonTime
		FROM #DownTimeData A
		INNER JOIN (SELECT B.machineid,B.fromtime,MAX(B.DownTime)as DownTime FROM #DownTimeData B group by machineid,fromtime) as T2
		ON A.MachineId = T2.MachineId and A.DownTime = t2.DownTime and A.fromtime=t2.fromtime
		inner join downcodeinformation D on A.DownID=D.interfaceid
		Where A.DownTime > 0
		group by A.MachineId,A.DownTime,A.fromtime)as T3 inner join #ShiftwiseSummary on T3.MachineID = #ShiftwiseSummary.MachineID and T3.fromtime = #ShiftwiseSummary.[From time]
		WHERE #ShiftwiseSummary.ShiftName<>'DAY'

		Update #ShiftwiseSummary SET MaxDownReason = MaxDownReasonTime
		From (select T.MachineID as MachineID,T.DownID + '-'+ SUBSTRING(dbo.f_FormatTime(T.MaxDownReasonTime,'hh:mm:ss'),1,5) as MaxDownReasonTime
		From (
				select A.MachineID as MachineID,D.DownID,ROW_NUMBER() OVER(Partition by A.MachineID ORDER BY A.MachineID,SUM(A.DownTime) desc) AS rn,
				SUM(A.DownTime) as MaxDownReasonTime
				FROM #DownTimeData A
				inner join downcodeinformation D on A.DownID=D.interfaceid
				Where A.DownTime > 0
				group by A.MachineId,D.DownID
			)T where T.rn=1
		)as T3 inner join #ShiftwiseSummary on T3.MachineID = #ShiftwiseSummary.MachineID 
		WHERE #ShiftwiseSummary.ShiftName='DAY'

/******************************************************* SHIFTWISE DOWNTIME SUMMARY *********************************************************/


/******************************************************* SHIFTWISE CO LEVEL STATISTICS *********************************************************/

	CREATE TABLE #ProductionTime
	(
	Plantid nvarchar(50),
	PMachineID  nvarchar(50),
	PMachineInterface nvarchar(50),
	PComponentID  nvarchar(50),
	PComponentInterface nvarchar(50),
	--CompDescription nvarchar(50),
	CompDescription nvarchar(100),
	POperationNo  Int,
	POperationInterface nvarchar(50),
	Price 	Float,
	ProdCount     Float,
	CNprodcount   Float,
	StdCycleTime  Float,
	AvgCycleTime  Float,
	MinCycleTime  Float,
	MaxCycleTime  Float,
	StdLoadUnload Float,
	AvgLoadUnload Float,
	MinLoadUnload Float,
	MaxLoadUnload Float,
	ShiftDate datetime,
	fromtime datetime,
	totime datetime,
	Shiftid int,
	Shiftname nvarchar(50)
	)
	
INSERT INTO #ProductionTime(Plantid,PMachineID,PMachineInterface,pComponentID,PComponentInterface,CompDescription,POperationNo,POperationInterface,Price,ProdCount,CNprodcount,
 StdCycleTime,AvgCycleTime,MinCycleTime,MaxCycleTime,StdLoadUnload, AvgLoadUnload,MinLoadUnload,MaxLoadUnload,ShiftDate,fromtime,totime,ShiftID,Shiftname)
SELECT Plantmachine.Plantid,M.MachineID,M.InterfaceID,C.ComponentID,C.interfaceID,C.Description,O.OperationNo,O.interfaceid,Max(O.Price),
CAST((CAST(sum(A.partscount) AS Float )/ISNULL(O.SubOperations,1))AS FLOAT)AS ProdCount , 
CAST((CAST(sum(A.partscount) AS Float )/ISNULL(O.SubOperations,1))AS FLOAT)AS CNprodcount ,
O.MachiningTime  AS StdCycleTime,
AVG(A.Cycletime/A.partscount)* ISNULL(O.SubOperations,1) AS AvgCycleTime,
Min(A.Cycletime/A.partscount)* ISNULL(O.SubOperations,1) AS MinCycleTime,
Max(A.Cycletime/A.partscount)* ISNULL(O.SubOperations,1) AS MaxCycleTime,
(O.CycleTime - O.MachiningTime) AS StdLoadUnload,0,
	Min(A.loadunload/A.partscount)* ISNULL(O.SubOperations,1) AS MinLoadUnload,
Max(A.loadunload/A.partscount)* ISNULL(O.SubOperations,1) AS MaxLoadUnload,
	S.PDate,S.shiftstart,S.shiftend,S.ShiftID,S.Shift
 FROM #T_autodata A Inner Join MachineInformation M ON A.mc=M.InterfaceID Inner Join  ComponentInformation C ON A.Comp=C.InterfaceID 
 left outer join dbo.Plantmachine on M.machineid=Plantmachine.machineid  
Inner Join ComponentOperationPricing O ON A.Opn=O.InterfaceID AND C.ComponentID=O.ComponentID AND M.MachineID=O.MachineID Cross join 
(Select T.Pdate, T.Shift, S.ShiftID , T.ShiftStart, T.ShiftEnd from #ShiftDetails T inner join Shiftdetails S on S.Shiftname=T.Shift where S.Running=1) S
 WHERE DataType=1 AND  Ndtime<=S.shiftend AND Ndtime>S.ShiftStart
and A.PartsCount > 0 
Group By Plantmachine.Plantid,M.MachineID,M.InterfaceID,C.ComponentID,C.interfaceID,C.Description,O.OperationNo,O.interfaceid,O.MachiningTime,O.CycleTime,O.SubOperations,S.PDate,S.shiftstart,S.shiftend,S.ShiftID,S.Shift
Order By C.ComponentID,O.OperationNo,M.MachineID


Update #productiontime set AvgLoadUnload = ISNULL(T1.AvgLoadUnload,0)
from (
SELECT M.MachineID,C.ComponentID,O.OperationNo ,#ProductionTime.totime,#ProductionTime.fromtime,
AVG(A.loadunload/A.partscount)*ISNULL(O.SubOperations,1) AS AvgLoadUnload 
FROM #T_autodata A Inner join MachineInformation M ON A.mc=M.InterfaceID Inner Join  ComponentInformation C ON A.Comp=C.InterfaceID
Inner Join ComponentOperationPricing O ON A.Opn=O.InterfaceID AND C.ComponentID=O.ComponentID and O.MachineID = M.MachineID 
inner join #ProductionTime on A.mc= #ProductionTime.PMachineInterface and A.Opn= #ProductionTime.POperationInterface and A.Comp=  #ProductionTime.PComponentInterface
WHERE DataType=1 And partscount >0 AND A.loadunload >= isnull((SELECT top 1 VALUEININT FROM SHOPDEFAULTS where parameter = 'minluforlr'),0)
AND  Ndtime<= #ProductionTime.totime AND Ndtime>#ProductionTime.fromtime
Group By M.MachineID,C.ComponentID,O.OperationNo,O.SubOperations,O.CycleTime,O.MachiningTime,#ProductionTime.totime,#ProductionTime.fromtime
) As T1 Inner Join  #productiontime 
ON #ProductionTime.pMachineID=T1.MachineID AND #ProductionTime.pComponentID=T1.ComponentID AND #ProductionTime.POperationNo=T1.OperationNo
and #ProductionTime.fromtime= T1.FromTime and #ProductionTime.ToTime = T1.totime
/******************************************************* SHIFTWISE COLEVEL STATISTICS *********************************************************/


/******************************************************* SHIFTWISE Rejection start *********************************************************/
CREATE TABLE #Shift_MachinewiseRejection
(
	
	[PlantID] nvarchar(50),
	[Machineid] nvarchar(50),
	[Date] datetime,  
	[ShiftName] nvarchar(50),  
 	[ShiftID] int,
	[RejFreq] int,
	[RejQty] int,
	[RejReason] nvarchar(150),
	
)
		insert into #Shift_MachinewiseRejection(PlantID,Machineid,Date,ShiftID,Shiftname,RejFreq,RejQty,RejReason)
		Select S.PlantID,S.Machineid,S.ShiftDate,S.ShiftID,S.ShiftName,count(R.rejectionid) as RejFreq, SUM(A.Rejection_Qty) as RejQty,R.rejectionid from AutodataRejections A
		inner join Machineinformation M on A.mc=M.interfaceid
		inner join #ShiftwiseSummary S on S.machineid=M.machineid 
		inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
		where A.CreatedTS>=S.[From time] and A.CreatedTS<S.[To Time] and A.flag = 'Rejection'
		and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000'
		group by A.mc,S.PlantID,S.Machineid,S.ShiftDate,S.ShiftID,S.ShiftName,S.[From time],S.[To Time],R.rejectionid

		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
		BEGIN
		Update #Shift_MachinewiseRejection set RejQty = isnull(RejQty,0) - isnull(T1.RejecQty,0) from
		(Select S.PlantID,S.Machineid,S.ShiftDate,S.ShiftID,S.ShiftName, SUM(A.Rejection_Qty) as RejecQty,R.rejectionid from AutodataRejections A
		inner join Machineinformation M on A.mc=M.interfaceid
		inner join #ShiftwiseSummary S on S.machineid=M.machineid 
		inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
		Cross join Planneddowntimes P
		where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid 
		and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000' and
		A.CreatedTS>=S.[From time] and A.CreatedTS<S.[To Time] And
		A.CreatedTS>=P.Starttime and A.CreatedTS<P.endtime
		group by A.mc,S.PlantID,S.Machineid,S.ShiftDate,S.ShiftID,S.ShiftName,S.[From time],S.[To Time],R.rejectionid)T1 inner join #Shift_MachinewiseRejection B on B.Machineid=T1.Machineid and B.PlantID=T1.PlantID and B.RejReason=T1.rejectionid and T1.ShiftDate=B.Date AND B.ShiftID=T1.ShiftID and B.ShiftName=T1.ShiftName
		END

		insert into #Shift_MachinewiseRejection(PlantID,Machineid,Date,ShiftID,Shiftname,RejFreq,RejQty,RejReason)
		Select  S.PlantID,S.Machineid,S.ShiftDate,S.ShiftID,S.ShiftName,count(R.rejectionid) as RejFreq, SUM(A.Rejection_Qty) as RejQty,R.rejectionid from AutodataRejections A
		inner join Machineinformation M on A.mc=M.interfaceid
		inner join #ShiftwiseSummary S on S.machineid=M.machineid and convert(nvarchar(10),(A.RejDate),126)=convert(nvarchar(10),(S.shiftdate),126) and A.RejShift=S.shiftid 
		inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid	
		where A.flag = 'Rejection' and A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (convert(nvarchar(10),(S.shiftdate),126)) and  
		Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
		group by A.mc,S.PlantID,S.Machineid,S.ShiftDate,S.ShiftName,S.ShiftID,S.[From time],S.[To Time],R.rejectionid

		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
		BEGIN
		Update #Shift_MachinewiseRejection set RejQty = isnull(RejQty,0) - isnull(T1.RejecQty,0) from
		(Select S.PlantID,S.Machineid,S.ShiftDate,S.ShiftID,S.ShiftName, SUM(A.Rejection_Qty) as RejecQty,R.rejectionid from AutodataRejections A
		inner join Machineinformation M on A.mc=M.interfaceid
		inner join #ShiftwiseSummary S on S.machineid=M.machineid and convert(nvarchar(10),(A.RejDate),126)=convert(nvarchar(10),S.shiftdate,126) and A.RejShift=S.shiftid
		inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
		Cross join Planneddowntimes P
		where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid and
		A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (convert(nvarchar(10),S.shiftdate,126)) and 
		Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
		and P.starttime>=S.[From time] and P.Endtime<=S.[To Time]
		group by A.mc,S.PlantID,S.Machineid,S.ShiftDate,S.ShiftID,S.ShiftName,S.[From time],S.[To Time],R.rejectionid)T1
		inner join #Shift_MachinewiseRejection B on B.Machineid=T1.Machineid and B.PlantID=T1.PlantID and B.RejReason=T1.rejectionid and T1.ShiftDate=B.Date AND B.ShiftID=T1.ShiftID and B.ShiftName=T1.ShiftName
		END

/******************************************************* SHIFTWISE Rejection end *********************************************************/


BEGIN TRY
	BEGIN TRAN

	------------------------------ HOURWISE CYCLES ---------------------------------------------------------------------
	SET @ErrorStep = 'Error in Inserting HOURWISE CYCLES Into Table FocasWeb_HourwiseCycles';

	--IF NOT EXISTS(Select * from FocasWeb_HourwiseCycles F where  Convert(Nvarchar(10),F.Date,120) In (Select Distinct Convert(Nvarchar(10),L.ShiftDate,120) From #HourwiseSummary L))
	--BEGIN
	--	Insert into FocasWeb_HourwiseCycles( PlantID, MachineID, Date,Shiftid, Shift, HourID, HourStart, HourEnd, ProgramID, PartCount,UpdatedTS,ProgramBlock)
	--	select #HourwiseSummary.PlantID,#HourwiseSummary.Machineid,Convert(Nvarchar(10),#HourwiseSummary.ShiftDate,120),#HourwiseSummary.ShiftID,#HourwiseSummary.Shiftname,#HourwiseSummary.hourid,#HourwiseSummary.[From Time],#HourwiseSummary.[To Time],T2.Component,isnull(Sum(T2.OperationCount),0)as CycleCount,getdate(),T2.Operation from #ShiftProductionFromAutodataT2 T2
	--	Right Outer join #HourwiseSummary on #HourwiseSummary.[From Time] = T2.HourStart and #HourwiseSummary.Machineid=T2.MachineID
	--	group by #HourwiseSummary.ShiftID,#HourwiseSummary.PlantID,#HourwiseSummary.Machineid,Convert(Nvarchar(10),#HourwiseSummary.ShiftDate,120),#HourwiseSummary.Shiftname,#HourwiseSummary.hourid,#HourwiseSummary.[From Time],#HourwiseSummary.[To Time],T2.Component,T2.OPERATION
	--	Order by Convert(Nvarchar(10),#HourwiseSummary.ShiftDate,120),#HourwiseSummary.PlantID,#HourwiseSummary.Machineid,#HourwiseSummary.ShiftID,#HourwiseSummary.hourid
		
	--END
	--ELSE
	--BEGIN

	--	Delete from FocasWeb_HourwiseCycles where Convert(Nvarchar(10),Date,120) In (Select Distinct Convert(Nvarchar(10),L.ShiftDate,120) From #HourwiseSummary L)

	--	Insert into FocasWeb_HourwiseCycles( PlantID, MachineID, Date,Shiftid, Shift, HourID, HourStart, HourEnd, ProgramID, PartCount,UpdatedTS,ProgramBlock)
	--	select #HourwiseSummary.PlantID,#HourwiseSummary.Machineid,Convert(Nvarchar(10),#HourwiseSummary.ShiftDate,120),#HourwiseSummary.ShiftID,#HourwiseSummary.Shiftname,#HourwiseSummary.hourid,#HourwiseSummary.[From Time],#HourwiseSummary.[To Time],T2.Component,isnull(Sum(T2.OperationCount),0)as CycleCount,getdate(),T2.Operation from #ShiftProductionFromAutodataT2 T2
	--	Right Outer join #HourwiseSummary on #HourwiseSummary.[From Time] = T2.HourStart and #HourwiseSummary.Machineid=T2.MachineID
	--	group by #HourwiseSummary.ShiftID,#HourwiseSummary.PlantID,#HourwiseSummary.Machineid,Convert(Nvarchar(10),#HourwiseSummary.ShiftDate,120),#HourwiseSummary.Shiftname,#HourwiseSummary.hourid,#HourwiseSummary.[From Time],#HourwiseSummary.[To Time],T2.Component,T2.OPERATION
	--	Order by Convert(Nvarchar(10),#HourwiseSummary.ShiftDate,120),#HourwiseSummary.PlantID,#HourwiseSummary.Machineid,#HourwiseSummary.ShiftID,#HourwiseSummary.hourid
	--END

	Delete from FocasWeb_HourwiseCycles where Convert(Nvarchar(10),Date,120) In (Select Distinct Convert(Nvarchar(10),L.ShiftDate,120) From #HourwiseSummary L)

	Insert into FocasWeb_HourwiseCycles( PlantID, MachineID, Date,Shiftid, Shift, HourID, HourStart, HourEnd, ProgramID, PartCount,UpdatedTS,ProgramBlock)
	select #HourwiseSummary.PlantID,#HourwiseSummary.Machineid,Convert(Nvarchar(10),#HourwiseSummary.ShiftDate,120),#HourwiseSummary.ShiftID,
	#HourwiseSummary.Shiftname,#HourwiseSummary.hourid,#HourwiseSummary.[From Time],#HourwiseSummary.[To Time],T2.Component,
	isnull(Sum(T2.OperationCount),0)as CycleCount,getdate(),T2.Operation from #ShiftProductionFromAutodataT2 T2
	Right Outer join #HourwiseSummary on #HourwiseSummary.[From Time] = T2.HourStart and #HourwiseSummary.Machineid=T2.MachineID
	where NOT EXISTS (Select Distinct cast(L.Date as date) From FocasWeb_HourwiseCycles L where cast(L.Date as date)=cast(#HourwiseSummary.ShiftDate as date))
	group by #HourwiseSummary.ShiftID,#HourwiseSummary.PlantID,#HourwiseSummary.Machineid,Convert(Nvarchar(10),#HourwiseSummary.ShiftDate,120),#HourwiseSummary.Shiftname,#HourwiseSummary.hourid,#HourwiseSummary.[From Time],#HourwiseSummary.[To Time],T2.Component,T2.OPERATION
	Order by Convert(Nvarchar(10),#HourwiseSummary.ShiftDate,120),#HourwiseSummary.PlantID,#HourwiseSummary.Machineid,#HourwiseSummary.ShiftID,#HourwiseSummary.hourid

	SET @update_count = @@ROWCOUNT
	print 'Inserted ' + CONVERT(varchar, @update_count) + ' records in table FocasWeb_HourwiseCycles'
	------------------------------ HOURWISE CYCLES ---------------------------------------------------------------------


	------------------------------ SHIFTWISE SUMMARY ---------------------------------------------------------------------
	SET @ErrorStep = 'Error in Inserting SHIFTWISE SUMMARY Into Table FocasWeb_ShiftwiseSummary';
	
	

	--IF NOT EXISTS(Select * from FocasWeb_ShiftwiseSummary F where  Convert(Nvarchar(10),F.Date,120) in (Select distinct Convert(Nvarchar(10),L.ShiftDate,120) From #ShiftwiseSummary L))
	--BEGIN

	--	Insert into FocasWeb_ShiftwiseSummary( PlantID, MachineID, Date, ShiftID,Shift, PartCount, TotalTime, PowerOnTime, OperatingTime, CuttingTime, Stoppages,UpdatedTS,RejCount,QualityEfficiency)
	--	select PlantID,Machineid,Convert(Nvarchar(10),ShiftDate,120),ShiftID,Shiftname,Sum(Components),SUM(UtilisedTime),Round(sum(AvailabilityEfficiency),0),Round(sum(ProductionEfficiency),0),Round(sum(OverAllEfficiency),0),sum(downtime),getdate(),sum(RejCount),ROUND(SUM(QualityEfficiency),0) from #ShiftwiseSummary
	--	where Shiftname<>'DAY'
	--	Group by PlantID,Machineid,Shiftdate,Shiftname,ShiftID
	--	Order by Convert(Nvarchar(10),ShiftDate,120),PlantID,Machineid,ShiftID

		
	--END

	--ELSE
	--BEGIN
	--	DELETE from FocasWeb_ShiftwiseSummary where Convert(Nvarchar(10),Date,120) in (Select distinct Convert(Nvarchar(10),L.ShiftDate,120) From #ShiftwiseSummary L)

	--	Insert into FocasWeb_ShiftwiseSummary( PlantID, MachineID, Date,ShiftID, Shift, PartCount, TotalTime, PowerOnTime, OperatingTime, CuttingTime, Stoppages, UpdatedTS,RejCount,QualityEfficiency)
	--	select PlantID,Machineid,Convert(Nvarchar(10),ShiftDate,120),ShiftID,Shiftname,Sum(Components),SUM(UtilisedTime),Round(sum(AvailabilityEfficiency),0),Round(sum(ProductionEfficiency),0),Round(sum(OverAllEfficiency),0),sum(downtime),getdate(),sum(RejCount),ROUND(SUM(QualityEfficiency),0) from #ShiftwiseSummary
	--	where Shiftname<>'DAY'
	--	Group by PlantID,Machineid,Shiftdate,Shiftname,ShiftID
	--	Order by Convert(Nvarchar(10),ShiftDate,120),PlantID,Machineid,ShiftID
	--END

	DELETE from FocasWeb_ShiftwiseSummary where Convert(Nvarchar(10),Date,120) in (Select distinct Convert(Nvarchar(10),L.ShiftDate,120) From #ShiftwiseSummary L)

	Insert into FocasWeb_ShiftwiseSummary( PlantID, MachineID, Date,ShiftID, Shift, PartCount, TotalTime, PowerOnTime, OperatingTime, CuttingTime, Stoppages, UpdatedTS,RejCount,QualityEfficiency)
	select PlantID,Machineid,Convert(Nvarchar(10),ShiftDate,120),ShiftID,Shiftname,Sum(Components),SUM(UtilisedTime),Round(sum(AvailabilityEfficiency),0),
	Round(sum(ProductionEfficiency),0),Round(sum(OverAllEfficiency),0),sum(downtime),getdate(),sum(RejCount),ROUND(SUM(QualityEfficiency),0) from #ShiftwiseSummary
	where Shiftname<>'DAY'
	and NOT EXISTS (Select Distinct Cast(L.Date as date) From FocasWeb_ShiftwiseSummary L where cast(L.Date as date)=cast(#ShiftwiseSummary.ShiftDate as date))
	Group by PlantID,Machineid,Shiftdate,Shiftname,ShiftID
	Order by Convert(Nvarchar(10),ShiftDate,120),PlantID,Machineid,ShiftID

	SET @update_count = @@ROWCOUNT
	print 'Inserted ' + CONVERT(varchar, @update_count) + ' records in table FocasWeb_ShiftwiseSummary'
	------------------------------ SHIFTWISE SUMMARY ---------------------------------------------------------------------

	------------------------------ SHIFTWISE COCKPIT ---------------------------------------------------------------------
	SET @ErrorStep = 'Error in Inserting SHIFTWISE COCKPIT Into Table FocasWeb_ShiftwiseCockpit';

	--IF NOT EXISTS(Select * from FocasWeb_ShiftwiseCockpit F where  Convert(Nvarchar(10),F.Date,120) in (Select distinct Convert(Nvarchar(10),L.ShiftDate,120) From #ShiftwiseSummary L))
	--BEGIN

	--	Insert into FocasWeb_ShiftwiseCockpit( PlantID, MachineID,MachineInterface, Date, ShiftID,Shift,Shiftstart,Shiftend,Utilisedtime,Downtime,MaxDownReason,Totaltime,NetDowntime,
	--	LastCycleCO,LastCycleStart,RunningCycleUT,RunningCycleDT,LastCycleSpindleRunTime,MachineStatus,AvailabilityEfficiency,ProductionEfficiency,OverAllEfficiency,Components
	--	,RejCount,QualityEfficiency,PEGreen ,PERed,AEGreen ,AERed ,OEGreen ,OERed,QERed,QEGreen,LastCycletime)
	--	select PlantID,Machineid,MachineInterface,Convert(Nvarchar(10),ShiftDate,120),ShiftID,Shiftname,[From time],[To Time],UtilisedTime,downtime,MaxDownReason,totaltime,
	--	NetDowntime,LastCycleCO,LastCycleStart,RunningCycleUT,RunningCycleDT,LastCycleSpindleRunTime,MachineStatus,
	--	Round(AvailabilityEfficiency,0),Round(ProductionEfficiency,0),Round(OverAllEfficiency,0),Components,RejCount,Round(QualityEfficiency,0) 
	--	,PEGreen ,PERed,AEGreen ,AERed ,OEGreen ,OERed,QERed,QEGreen,LastCycletime  from #ShiftwiseSummary
	--	Order by Convert(Nvarchar(10),ShiftDate,120),PlantID,Machineid,ShiftID
	--END
	--ELSE
	--BEGIN
	--	DELETE from FocasWeb_ShiftwiseCockpit where Convert(Nvarchar(10),Date,120) in (Select distinct Convert(Nvarchar(10),L.ShiftDate,120) From #ShiftwiseSummary L)

	--	Insert into FocasWeb_ShiftwiseCockpit( PlantID, MachineID,MachineInterface, Date, ShiftID,Shift,Shiftstart,Shiftend,Utilisedtime,Downtime,MaxDownReason,Totaltime,NetDowntime,
	--	LastCycleCO,LastCycleStart,RunningCycleUT,RunningCycleDT,LastCycleSpindleRunTime,MachineStatus,AvailabilityEfficiency,ProductionEfficiency,OverAllEfficiency,Components
	--	,RejCount,QualityEfficiency,PEGreen ,PERed,AEGreen ,AERed ,OEGreen ,OERed,QERed,QEGreen,LastCycletime)
	--	select PlantID,Machineid,MachineInterface,Convert(Nvarchar(10),ShiftDate,120),ShiftID,Shiftname,[From time],[To Time],UtilisedTime,downtime,MaxDownReason,totaltime,
	--	NetDowntime,LastCycleCO,LastCycleStart,RunningCycleUT,RunningCycleDT,LastCycleSpindleRunTime,MachineStatus,
	--	Round(AvailabilityEfficiency,0),Round(ProductionEfficiency,0),Round(OverAllEfficiency,0),Components,RejCount,Round(QualityEfficiency,0)
	--	,PEGreen ,PERed,AEGreen ,AERed ,OEGreen ,OERed,QERed,QEGreen,LastCycletime  from #ShiftwiseSummary
	--	Order by Convert(Nvarchar(10),ShiftDate,120),PlantID,Machineid,ShiftID
	--END

	DELETE from FocasWeb_ShiftwiseCockpit where Convert(Nvarchar(10),Date,120) in (Select distinct Convert(Nvarchar(10),L.ShiftDate,120) From #ShiftwiseSummary L)

	Insert into FocasWeb_ShiftwiseCockpit( PlantID, MachineID,MachineInterface, Date, ShiftID,Shift,Shiftstart,Shiftend,Utilisedtime,Downtime,MaxDownReason,Totaltime,NetDowntime,
	LastCycleCO,LastCycleStart,RunningCycleUT,RunningCycleDT,LastCycleSpindleRunTime,MachineStatus,AvailabilityEfficiency,ProductionEfficiency,OverAllEfficiency,Components
	,RejCount,QualityEfficiency,PEGreen ,PERed,AEGreen ,AERed ,OEGreen ,OERed,QERed,QEGreen,LastCycletime,Operator)
	select PlantID,Machineid,MachineInterface,Convert(Nvarchar(10),ShiftDate,120),ShiftID,Shiftname,[From time],[To Time],UtilisedTime,downtime,MaxDownReason,totaltime,
	NetDowntime,LastCycleCO,LastCycleStart,RunningCycleUT,RunningCycleDT,LastCycleSpindleRunTime,MachineStatus,
	Round(AvailabilityEfficiency,0),Round(ProductionEfficiency,0),Round(OverAllEfficiency,0),Components,RejCount,Round(QualityEfficiency,0)
	,PEGreen ,PERed,AEGreen ,AERed ,OEGreen ,OERed,QERed,QEGreen,LastCycletime,OperatorName  from #ShiftwiseSummary
	Where  NOT EXISTS (Select Distinct cast(L.Date as date) From FocasWeb_ShiftwiseCockpit L where cast(L.Date as date)=cast(#ShiftwiseSummary.ShiftDate as date))
	Order by Convert(Nvarchar(10),ShiftDate,120),PlantID,Machineid,ShiftID

	SET @update_count = @@ROWCOUNT
	print 'Inserted ' + CONVERT(varchar, @update_count) + ' records in table FocasWeb_ShiftwiseCockpit'
	------------------------------ SHIFTWISE COCKPIT ---------------------------------------------------------------------


	------------------------------ SHIFTWISE STOPPAGES ---------------------------------------------------------------------
	SET @ErrorStep = 'Error in Inserting SHIFTWISE STOPPAGES Into Table FocasWeb_ShiftwiseStoppages';

	--IF NOT EXISTS(Select * from [FocasWeb_ShiftwiseStoppages] F where Convert(Nvarchar(10),F.Date,120) in ( Select distinct Convert(Nvarchar(10),L.ShiftDate,120) from #Shift_MachinewiseStoppages L))
	--BEGIN

	--Insert into [FocasWeb_ShiftwiseStoppages](PlantID, MachineID, Date, ShiftID, Shift, Batchstart, BatchEnd, StoppageTime, Reason, UpdatedTS)
	--select PlantID,Machineid,Convert(Nvarchar(10),ShiftDate,120),Shiftid,Shiftname,Batchstart,BatchEnd,Stoppagetime,Reason,getdate() from #Shift_MachinewiseStoppages 
	--Order by Convert(Nvarchar(10),ShiftDate,120),PlantID,Machineid,ShiftID

	--END
	--ELSE
	--BEGIN

	--DELETE from [FocasWeb_ShiftwiseStoppages]  where  Convert(Nvarchar(10),Date,120) in ( Select distinct Convert(Nvarchar(10),L.ShiftDate,120) from #Shift_MachinewiseStoppages L)

	--Insert into [FocasWeb_ShiftwiseStoppages](PlantID, MachineID, Date, ShiftID, Shift, Batchstart, BatchEnd, StoppageTime, Reason, UpdatedTS)
	--select PlantID,Machineid,Convert(Nvarchar(10),ShiftDate,120),Shiftid,Shiftname,Batchstart,BatchEnd,Stoppagetime,Reason,getdate() from #Shift_MachinewiseStoppages 
	--Order by Convert(Nvarchar(10),ShiftDate,120),PlantID,Machineid,ShiftID

	--END

	DELETE from [FocasWeb_ShiftwiseStoppages]  where  Convert(Nvarchar(10),Date,120) in ( Select distinct Convert(Nvarchar(10),L.ShiftDate,120) from #Shift_MachinewiseStoppages L)

	Insert into [FocasWeb_ShiftwiseStoppages](PlantID, MachineID, Date, ShiftID, Shift, Batchstart, BatchEnd, StoppageTime, Reason, UpdatedTS)
	select PlantID,Machineid,Convert(Nvarchar(10),ShiftDate,120),Shiftid,Shiftname,Batchstart,BatchEnd,Stoppagetime,Reason,getdate() from #Shift_MachinewiseStoppages 
	Where NOT EXISTS (Select Distinct cast(L.Date as date) From FocasWeb_ShiftwiseStoppages L where cast(L.Date as date)=cast(#Shift_MachinewiseStoppages.ShiftDate as date))
	Order by Convert(Nvarchar(10),ShiftDate,120),PlantID,Machineid,ShiftID

	SET @update_count = @@ROWCOUNT
	print 'Inserted ' + CONVERT(varchar, @update_count) + ' records in table FocasWeb_ShiftwiseStoppages'
	------------------------------ SHIFTWISE STOPPAGES ---------------------------------------------------------------------


	------------------------------ SHIFTWISE STOPPAGES ---------------------------------------------------------------------
	SET @ErrorStep = 'Error in Inserting SHIFTWISE STOPPAGES Into Table FocasWeb_downfreq';

	--IF NOT EXISTS(Select * from FocasWeb_downfreq F where Convert(Nvarchar(10),F.Date,120) in ( Select distinct Convert(Nvarchar(10),L.ShiftDate,120) from #DownTimeData L))
	--BEGIN

	--	Insert into FocasWeb_downfreq(PlantID,MachineID,Date,ShiftID,[Shift],DownID,DownReason, DownFreq,Downtime)
	--	select PlantID,MachineID,Convert(Nvarchar(10),ShiftDate,120),ShiftID,Shiftname,DownID,DownReason,DownFreq,Downtime  from #DownTimeData
	--	where DownFreq > 0
	--	Order by Convert(Nvarchar(10),ShiftDate,120),PlantID,Machineid,ShiftID,DownFreq

	--END
	--Else
	--BEGIN

	--DELETE from FocasWeb_downfreq where Convert(Nvarchar(10),Date,120) in (Select distinct Convert(Nvarchar(10),L.ShiftDate,120) From #DownTimeData L)

	--Insert into FocasWeb_downfreq(PlantID,MachineID,Date,ShiftID,[Shift],DownID,DownReason, DownFreq,Downtime)
	--select PlantID,MachineID,Convert(Nvarchar(10),ShiftDate,120),ShiftID,Shiftname,DownID,DownReason,DownFreq,Downtime  from #DownTimeData
	--where DownFreq > 0
	--Order by Convert(Nvarchar(10),ShiftDate,120),PlantID,Machineid,ShiftID,DownFreq

	--END

	DELETE from FocasWeb_downfreq where Convert(Nvarchar(10),Date,120) in (Select distinct Convert(Nvarchar(10),L.ShiftDate,120) From #DownTimeData L)

	Insert into FocasWeb_downfreq(PlantID,MachineID,Date,ShiftID,[Shift],DownID,DownReason, DownFreq,Downtime)
	select PlantID,MachineID,Convert(Nvarchar(10),ShiftDate,120),ShiftID,Shiftname,DownID,DownReason,DownFreq,Downtime  from #DownTimeData
	where DownFreq > 0
	and NOT EXISTS (Select Distinct cast(L.Date as date) From FocasWeb_downfreq L where cast(L.Date as date)=cast(#DownTimeData.ShiftDate as date))
	Order by Convert(Nvarchar(10),ShiftDate,120),PlantID,Machineid,ShiftID,DownFreq

	SET @update_count = @@ROWCOUNT
	print 'Inserted ' + CONVERT(varchar, @update_count) + ' records in table FocasWeb_downfreq'
	------------------------------ SHIFTWISE STOPPAGES ---------------------------------------------------------------------


	------------------------------ HOURWISE TIMEINFO ---------------------------------------------------------------------
	SET @ErrorStep = 'Error in Inserting HOURWISE TIMEINF Into Table [FocasWeb_HourwiseTimeInfo]';

	--IF NOT EXISTS(Select * from [FocasWeb_HourwiseTimeInfo] F where  Convert(Nvarchar(10),F.Date,120) in(Select distinct Convert(Nvarchar(10),L.ShiftDate,120) from #HourwiseSummary L))
	--BEGIN
	--	Insert into [FocasWeb_HourwiseTimeInfo](PlantID, MachineID, Date, ShiftID, Shift, HourID, HourStart, HourEnd, PowerOntime, OperatingTime, CuttingTime, UpdatedTS)
	--	select PlantID,Machineid,PDate,Shiftid,Shift,HourID,HourStart,HourEnd,PPT,UtilisedTime,Downtime,getdate()
	--	from #ShiftProductionFromAutodataT1 
	--END
	--ELSE
	--BEGIN

	--	DELETE from [FocasWeb_HourwiseTimeInfo] where  Convert(Nvarchar(10),Date,120) in(Select distinct Convert(Nvarchar(10),L.ShiftDate,120) from #HourwiseSummary L)

	--	Insert into [FocasWeb_HourwiseTimeInfo](PlantID, MachineID, Date, ShiftID, Shift, HourID, HourStart, HourEnd, PowerOntime, OperatingTime, CuttingTime, UpdatedTS)
	--	select PlantID,Machineid,PDate,Shiftid,Shift,HourID,HourStart,HourEnd,PPT,UtilisedTime,Downtime,getdate()
	--	from #ShiftProductionFromAutodataT1 
	--END

	DELETE from [FocasWeb_HourwiseTimeInfo] where  Convert(Nvarchar(10),Date,120) in(Select distinct Convert(Nvarchar(10),L.ShiftDate,120) from #HourwiseSummary L)

	Insert into [FocasWeb_HourwiseTimeInfo](PlantID, MachineID, Date, ShiftID, Shift, HourID, HourStart, HourEnd, PowerOntime, OperatingTime, CuttingTime, UpdatedTS)
	select PlantID,Machineid,PDate,Shiftid,Shift,HourID,HourStart,HourEnd,PPT,UtilisedTime,Downtime,getdate()
	from #ShiftProductionFromAutodataT1 
	Where NOT EXISTS (Select Distinct cast(L.Date as date) From FocasWeb_HourwiseTimeInfo L where cast(L.Date as date)=cast(#ShiftProductionFromAutodataT1.Pdate as date))

	SET @update_count = @@ROWCOUNT
	print 'Inserted ' + CONVERT(varchar, @update_count) + ' records in table [FocasWeb_HourwiseTimeInfo]'
	------------------------------ HOURWISE TIMEINFO ---------------------------------------------------------------------

	------------------------------ SHIFTWISE SUMMARY ---------------------------------------------------------------------
	SET @ErrorStep = 'Error in Inserting SHIFTWISE Statistics Into Table FocasWeb_Statistics';

	--if not exists(select * from FocasWeb_Statistics F  where  Convert(Nvarchar(10),F.Date,120) in (Select distinct Convert(Nvarchar(10),L.ShiftDate,120) From #ShiftwiseSummary L))
	--BEGIN

	--	insert into FocasWeb_Statistics(Plantid,Machineid,component,operationNo,StdCycleTime,AvgCycleTime,MinCycleTime,MaxCycleTime,StdLoadUnload,AvgLoadUnload,MinLoadUnload,MaxLoadUnload,
	--	Date,ShiftID,Shift,UpdatedTS)
	--	select Plantid,PMachineid,PComponentID,POperationNo,StdCycleTime,AvgCycleTime,MinCycleTime,MaxCycleTime,StdLoadUnload,AvgLoadUnload,MinLoadUnload,MaxLoadUnload,
	--	Convert(Nvarchar(10),ShiftDate,120),ShiftID,Shiftname,getdate()
	--	from #ProductionTime
	--	Order by Convert(Nvarchar(10),ShiftDate,120),PlantID,PMachineid,PComponentID,POperationNo,ShiftID

	--END
	--else
	--BEGIN

	--DELETE from FocasWeb_Statistics where Convert(Nvarchar(10),Date,120) in (Select distinct Convert(Nvarchar(10),L.ShiftDate,120) From #ShiftwiseSummary L)

	--insert into FocasWeb_Statistics(Plantid,Machineid,component,operationNo,StdCycleTime,AvgCycleTime,MinCycleTime,MaxCycleTime,StdLoadUnload,AvgLoadUnload,MinLoadUnload,MaxLoadUnload,
	--Date,ShiftID,Shift,UpdatedTS)
	--select Plantid,PMachineid,PComponentID,POperationNo,StdCycleTime,AvgCycleTime,MinCycleTime,MaxCycleTime,StdLoadUnload,AvgLoadUnload,MinLoadUnload,MaxLoadUnload,
	--Convert(Nvarchar(10),ShiftDate,120),ShiftID,Shiftname,getdate()
	--from #ProductionTime
	--Order by Convert(Nvarchar(10),ShiftDate,120),PlantID,PMachineid,PComponentID,POperationNo,ShiftID
	--END

	DELETE from FocasWeb_Statistics where Convert(Nvarchar(10),Date,120) in (Select distinct Convert(Nvarchar(10),L.ShiftDate,120) From #ShiftwiseSummary L)

	insert into FocasWeb_Statistics(Plantid,Machineid,component,operationNo,StdCycleTime,AvgCycleTime,MinCycleTime,MaxCycleTime,StdLoadUnload,AvgLoadUnload,MinLoadUnload,MaxLoadUnload,
	Date,ShiftID,Shift,UpdatedTS)
	select Plantid,PMachineid,PComponentID,POperationNo,StdCycleTime,AvgCycleTime,MinCycleTime,MaxCycleTime,StdLoadUnload,AvgLoadUnload,MinLoadUnload,MaxLoadUnload,
	Convert(Nvarchar(10),ShiftDate,120),ShiftID,Shiftname,getdate()
	from #ProductionTime
	where NOT  EXISTS (Select Distinct cast(L.Date as date) From FocasWeb_Statistics L where cast(L.Date as date)=cast(#ProductionTime.ShiftDate as date))
	Order by Convert(Nvarchar(10),ShiftDate,120),PlantID,PMachineid,PComponentID,POperationNo,ShiftID

	SET @update_count = @@ROWCOUNT
	print 'Inserted ' + CONVERT(varchar, @update_count) + ' records in table FocasWeb_Statistics'
	------------------------------ SHIFTWISE SUMMARY ---------------------------------------------------------------------
	
	----------------------------- SHIFTWISE Rejection ---------------------------------------------------------------------
	SET @ErrorStep = 'Error in Inserting SHIFTWISE REJECTION  Into Table FocasWeb_ShiftwiseRejection';

	--IF NOT EXISTS(Select * from FocasWeb_ShiftwiseRejection F where Convert(Nvarchar(10),F.Date,120) in ( Select distinct Convert(Nvarchar(10),L.Date,120) from #Shift_MachinewiseRejection L))
	--BEGIN

	--	Insert into FocasWeb_ShiftwiseRejection(PlantID,MachineID,Date,ShiftID,[Shift],Rejection_Freq,Rejection_Qty,Rejection_Reason,UpdatedTS)
	--	select PlantID,MachineID,Convert(Nvarchar(10),Date,120),ShiftID,Shiftname,RejFreq,RejQty,RejReason,GETDATE() from #Shift_MachinewiseRejection
	--	where RejFreq > 0
	--	Order by Convert(Nvarchar(10),Date,120),PlantID,Machineid,ShiftID,RejFreq

	--END
	--Else
	--BEGIN

	--DELETE from FocasWeb_ShiftwiseRejection where Convert(Nvarchar(10),Date,120) in (Select distinct Convert(Nvarchar(10),L.Date,120) From #Shift_MachinewiseRejection L)

	--Insert into FocasWeb_ShiftwiseRejection(PlantID,MachineID,Date,ShiftID,[Shift],Rejection_Freq,Rejection_Qty, Rejection_Reason,UpdatedTS)
	--select PlantID,MachineID,Convert(Nvarchar(10),Date,120),ShiftID,Shiftname,RejFreq,RejQty,RejReason,GETDATE() from #Shift_MachinewiseRejection
	--where RejFreq > 0
	--Order by Convert(Nvarchar(10),Date,120),PlantID,Machineid,ShiftID,RejFreq

	--END

	DELETE from FocasWeb_ShiftwiseRejection where Convert(Nvarchar(10),Date,120) in (Select distinct Convert(Nvarchar(10),L.Date,120) From #Shift_MachinewiseRejection L)

	Insert into FocasWeb_ShiftwiseRejection(PlantID,MachineID,Date,ShiftID,[Shift],Rejection_Freq,Rejection_Qty, Rejection_Reason,UpdatedTS)
	select  PlantID,MachineID,Convert(Nvarchar(10),Date,120),ShiftID,Shiftname,RejFreq,RejQty,RejReason,GETDATE() from #Shift_MachinewiseRejection
	where RejFreq > 0 and NOT EXISTS (Select Distinct cast(L.Date as date) From FocasWeb_ShiftwiseRejection L where cast(L.Date as date)=cast(#Shift_MachinewiseRejection.Date as date))
	Order by Convert(Nvarchar(10),Date,120),PlantID,Machineid,ShiftID,RejFreq

	SET @update_count = @@ROWCOUNT
	print 'Inserted ' + CONVERT(varchar, @update_count) + ' records in table FocasWeb_ShiftwiseRejection'

	------------------------------ SHIFTWISE rejection ---------------------------------------------------------------------

	COMMIT TRAN
    SET  @ErrorCode  = 0
	Print 'TPMTRAK data Inserted Successfully For the day ='  + convert(nvarchar(10),@Date,120)
    RETURN @ErrorCode  

END TRY
BEGIN CATCH    
	PRINT 'Exception happened. Rolling back the transaction'  
    SET @ErrorCode = ERROR_NUMBER() 
	SET @Return_Message = @ErrorStep + ' '
							+ cast(isnull(ERROR_NUMBER(),-1) as varchar(20)) + ' line: '
							+ cast(isnull(ERROR_LINE(),-1) as varchar(20)) + ' ' 
							+ isnull(ERROR_MESSAGE(),'') + ' > ' 
							+ isnull(ERROR_PROCEDURE(),'')
	PRINT @Return_Message
	IF @@TRANCOUNT > 0 ROLLBACK
    RETURN @ErrorCode 
END CATCH

END
