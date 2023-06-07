/****** Object:  Procedure [dbo].[s_GetEfficiencyFromAutodata_Shanthi]    Committed by VersionSQL https://www.versionsql.com ******/

--exec s_GetCockpitData '2015-02-08 08:00:00 AM','2015-02-09 08:00:00 AM','',''
--exec [s_GetEfficiencyFromAutodata_Shanthi] '2017-05-21','2017-05-21','','','OEE','Shift','','Console'
--exec [s_GetEfficiencyFromAutodata_Shanthi] '2017-05-21','2017-05-21','','','','Day','','Console'
--exec [s_GetEfficiencyFromAutodata_Shanthi] '2015-07-21','2015-07-21','','','','Month','','Console'
--exec s_getcockpitdata '2015-07-01 08:00:00','2015-07-22 08:00:00','',''
--DR0379 - SwathiKS - 24/Nov/2017 :: To handle Multiple Operators For Each Machine-Shift For SPF.

CREATE PROCEDURE [dbo].[s_GetEfficiencyFromAutodata_Shanthi]
	@StartTime datetime,
	@EndTime datetime,
	@MachineID nvarchar(50) = '',
	@PlantID nvarchar(50)='',
	@ComparisonParam as nvarchar(20),
	@TimeAxis as nvarchar(20), --'Month','Day','Shift','Hour'
	@ShiftName as nvarchar(20)='',
	@Type as NVarchar(20)='Console',--'Console','Cockpit',we need different output based on the requirement.
	@daywise as nvarchar(20)=''
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


SET NOCOUNT ON;
CREATE TABLE #Exceptions
(
	MachineID NVarChar(50),
	ComponentID Nvarchar(50),
	OperationNo Int,
	StartTime DateTime,
	EndTime DateTime,
	IdealCount Int,
	ActualCount Int,
	ExCount Int DEFAULT 0
	---mod 4(5)
	,DurStart datetime
	,DurEnd datetime
	---mod 4(5)
)
CREATE TABLE #MCO_pCounts
(
	StTime DateTime,
	MachineID NVarChar(50),
	ComponentID Nvarchar(50),
	OperationNo Int,
	pCount Int DEFAULT 0,
	CycleTime Int
	
)
Create Table #ShiftHour
	(
		HDate datetime,
		Temshift nvarchar(50),
		Frmt datetime,
		Endt datetime,
	)
Create Table #ShiftTemp
	(
		PDate datetime,
		ShiftName nvarchar(20) null,
		FromTime datetime,
		ToTime Datetime
	)
CREATE TABLE #CockPitData (
	Pdt datetime,
	Strttm datetime,
	ndtim datetime,
	shftnm nvarchar(50),
	ShiftID int,
	MachineID nvarchar(50),
	MachineInterface nvarchar(50),
	ProductionEfficiency float,
	AvailabilityEfficiency float,
	OverallEfficiency float,
	QualityEfficiency float default 0, --Vas
	Components float,
	UtilisedTime float,
	ManagementLoss float,
	DownTime float,--vasavi
	TurnOver Float default 0,--vasavi
	RejCount float default 0, --vasavi
	DayRejCount float default 0,
	CN float,
	Rejection float
	--mod 4
	,MLDown float
	--mod 4
	,AvgProductionEfficiency float DEFAULT 0 -- DR0360 Added 
	,AvgAvailabilityEfficiency float DEFAULT 0  -- DR0360 Added
	,AvgOverallEfficiency float DEFAULT 0, -- DR0360 Addedr
	TargetOEE float DEFAULT 0 ,-- DR0360 Added
	TotalComp float default 0,
	TotalDowntime int,
	TotaldowntimeInt float ,
	MachineHourRate int,
	operator nvarchar(1000)
)
---mod 4
CREATE TABLE #PlannedDownTimesEffi
	(
		SlNo int not null identity(1,1),
		Starttime datetime,
		EndTime datetime,
		DownReason nvarchar(50),
		Machine nvarchar(50),
		MInterface nvarchar(50),
		DStart datetime,
		Dend datetime
	)
---mod 4
Declare @strSql as nvarchar(4000)
Declare @strMachine as nvarchar(900)
Declare @Counter as datetime
Declare @EndCount as datetime
Declare @CurShiftSt as datetime
Declare @Curshiftnd as datetime
Declare @curendtime   as datetime
Declare @CurShift as nvarchar(50)
Declare @CurHourDate as datetime
Declare @Incstrt as datetime
DEclare @IncEnd as datetime
declare @Endtm as datetime
declare @CurStarttime as datetime
declare @shifttemp as nvarchar(50)
Declare @strPlantID as nvarchar(4000)
Declare @strXMachine nvarchar(255)
SET @strXMachine =''
SET @strMachine = ''
SET @strPlantID = ''
select @counter=convert(datetime, cast(DATEPART(yyyy,@StartTime)as nvarchar(4))+'-'+cast(datepart(mm,@StartTime)as nvarchar(2))+'-'+cast(datepart(dd,@StartTime)as nvarchar(2)) +' 00:00:00.000')
if isnull(@machineid,'')<> ''
begin
	
	SET @strMachine = ' AND MachineInformation.MachineID = N''' + @machineid + ''''
	SET @strXMachine = ' AND EX.MachineID = N''' + @machineid + ''''
	
end
if isnull(@PlantID,'')<> ''
Begin

	SET @strPlantID =  ' AND PlantMachine.PlantID = N''' + @PlantID + ''''
	
End
if @TimeAxis='Hour'
begin
	Insert into #ShiftHour(HDate,TemShift, Frmt, Endt)
	Exec s_GetShiftTime @counter,@ShiftName
	
	DECLARE EffishiftCursor  Cursor  For
		SELECT Hdate,TemShift,Frmt,Endt From #ShiftHour
		Open EffishiftCursor
		FETCH NExt From EffishiftCursor into @CurHourDate,@CurShift,@CurShiftSt,@Curshiftnd
		While(@@Fetch_Status=0)
		BEGIN
			select @Incstrt=@CurShiftSt
			While(@Incstrt<@Curshiftnd)
			begin
				SELECT @IncEnd=DATEADD(Second,3600,@Incstrt)
					if @IncEnd >= @Curshiftnd
					Begin
						set @IncEnd = @Curshiftnd
					end
				Insert into #ShiftTemp(PDate,ShiftName, FromTime, ToTime)
				select @CurHourDate,@CurShift,@Incstrt,@IncEnd
				
				select @Incstrt=dateadd(second,3600,@Incstrt)
			end
			FETCH NExt From EffishiftCursor into  @CurHourDate,@CurShift,@CurShiftSt,@Curshiftnd
		END
	
END
if @TimeAxis='shift'
begin
	Delete from #ShiftTemp
		While(@counter <= @EndTime)
		BEGIN
			Insert into #ShiftTemp(PDate,ShiftName, FromTime, ToTime)
			Exec s_GetShiftTime @counter,@ShiftName
			SELECT @counter = Dateadd(Day,1,@counter)
		END
end
if @TimeAxis='Day'
begin
	Delete from #ShiftTemp
	While(@counter <= @EndTime)
	begin
		  insert into #ShiftTemp(Pdate,ShiftName,FromTime,ToTime)
		  select @Counter,'ALL',dbo.f_GetLogicalDay(@starttime,'start'),dbo.f_GetLogicalDay(@starttime,'End')
		  SELECT @counter = Dateadd(Day,1,@counter)
		 
	end
	
end
if @TimeAxis='Month'
begin
	Delete from #ShiftTemp
	While(@counter <= @EndTime)
	begin
		  insert into #ShiftTemp(Pdate,ShiftName,FromTime,ToTime)
		  select @Counter,'ALL',dbo.f_GetLogicalMonth(@StartTime,'start'),dbo.f_GetLogicalDay(@StartTime,'End')
		  SELECT @counter = Dateadd(Month,1,@counter)
		  
	end
	
end
---mod 4(5):Optimization
SET @strSql = 'INSERT INTO #CockpitData (
			Pdt,
			Strttm,
			ndtim,
			shftnm,
			MachineID ,
			MachineInterface,
			ProductionEfficiency ,
			AvailabilityEfficiency ,
			OverallEfficiency ,
			Components ,
			UtilisedTime ,	
			ManagementLoss,
			DownTime ,
			TurnOver,
			CN,
			Rejection
					) '
			SET @strSql = @strSql + ' SELECT S.Pdate,S.FromTime,S.ToTime,S.ShiftName,MachineInformation.MachineID, MachineInformation.interfaceid ,0,0,0,0,0,0,0,0,0,0 FROM MachineInformation
						  INNER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID
						  cross join #ShiftTemp S whERE MachineInformation.interfaceid > ''0''  '
			SET @strSql = @strSql + @strPlantID + @strMachine
			EXEC(@strSql)

--vasavi	---DR0379 From Here
--UPDATE #CockpitData SET Operator = t2.opr
--from(
--select  #CockpitData.Strttm as intime, mc,employeeinformation.Employeeid as opr,#CockpitData.shftnm from autodata 
--inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface 
--INNER JOIN employeeinformation ON employeeinformation.interfaceid=autodata.opr
--where (autodata.datatype=1 OR autodata.datatype=2 )
--AND(( (autodata.msttime>=#CockpitData.Strttm) and (autodata.ndtime<=#CockpitData.ndtim))
--OR ((autodata.msttime<#CockpitData.Strttm)and (autodata.ndtime>#CockpitData.Strttm)and (autodata.ndtime<=#CockpitData.ndtim))
--OR ((autodata.msttime>=#CockpitData.Strttm)and (autodata.msttime<#CockpitData.ndtim)and (autodata.ndtime>#CockpitData.ndtim))
--OR((autodata.msttime<#CockpitData.Strttm)and (autodata.ndtime>#CockpitData.ndtim))
--)
--group by autodata.mc,#CockpitData.Strttm,employeeinformation.Employeeid,#CockpitData.shftnm)
--as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm

-------------------
--update  #CockpitData SET Operator=t.[operator]
--from (select distinct  
--    substring(
--        (
--            Select distinct ','+ST1.operator  AS [text()]
--            From  #CockPitData ST1
--            Where ST1.Shftnm = ST2.Shftnm
--            For XML PATH ('')
--        ), 2, 1000) [operator],ST2.Shftnm
--From  #CockPitData ST2
--group by ST2.Shftnm
--)t  inner join #CockpitData on t.shftnm = #CockpitData.shftnm
--vasavi	

select  #CockpitData.Strttm as ShiftStart,MachineInterface,employeeinformation.Employeeid as opr
INTO #ShiftwiseOperator from autodata 
inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface 
INNER JOIN employeeinformation ON employeeinformation.interfaceid=autodata.opr
where (autodata.datatype=1 OR autodata.datatype=2 )
AND(( (autodata.msttime>=#CockpitData.Strttm) and (autodata.ndtime<=#CockpitData.ndtim))
OR ((autodata.msttime<#CockpitData.Strttm)and (autodata.ndtime>#CockpitData.Strttm)and (autodata.ndtime<=#CockpitData.ndtim))
OR ((autodata.msttime>=#CockpitData.Strttm)and (autodata.msttime<#CockpitData.ndtim)and (autodata.ndtime>#CockpitData.ndtim))
OR((autodata.msttime<#CockpitData.Strttm)and (autodata.ndtime>#CockpitData.ndtim))
)
group by MachineInterface,#CockpitData.Strttm,employeeinformation.Employeeid

UPDATE #CockpitData SET Operator = ISNULL(#CockpitData.Operator,'') + ISNULL(t2.opr,'')    
  from(    
  SELECT t.MachineInterface,t.ShiftStart,    
      STUFF(ISNULL((SELECT ' , ' + x.opr     
      FROM #ShiftwiseOperator x     
        WHERE x.MachineInterface = t.MachineInterface and x.ShiftStart = t.ShiftStart
     GROUP BY x.opr 
      FOR XML PATH (''), TYPE).value('.','nVARCHAR(max)'), ''), 1, 2, '') [opr]         
    FROM #ShiftwiseOperator t)    
as t2 inner join #CockpitData on t2.MachineInterface = #CockpitData.MachineInterface and t2.ShiftStart =#CockpitData.Strttm 

---DR0379 Till Here

	
---utilised time
-- Type 1
UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
from
(select     #CockpitData.Strttm as intime, mc,
sum(case when ( (autodata.msttime>= #CockpitData.Strttm) and (autodata.ndtime<=#CockpitData.ndtim)) then  (cycletime+loadunload)
		 when ((autodata.msttime< #CockpitData.Strttm)and (autodata.ndtime> #CockpitData.Strttm)and (autodata.ndtime<=#CockpitData.ndtim)) then DateDiff(second,  #CockpitData.Strttm, ndtime)
		 when ((autodata.msttime>= #CockpitData.Strttm)and (autodata.msttime<#CockpitData.ndtim)and (autodata.ndtime>#CockpitData.ndtim)) then DateDiff(second, mstTime, #CockpitData.ndtim)
		 when ((autodata.msttime< #CockpitData.Strttm)and (autodata.ndtime>#CockpitData.ndtim)) then DateDiff(second,  #CockpitData.Strttm, #CockpitData.ndtim) END ) as  cycle
from autodata inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface
where (autodata.datatype=1)
AND(( (autodata.msttime>=#CockpitData.Strttm) and (autodata.ndtime<=#CockpitData.ndtim))
OR ((autodata.msttime<#CockpitData.Strttm)and (autodata.ndtime>#CockpitData.Strttm)and (autodata.ndtime<=#CockpitData.ndtim))
OR ((autodata.msttime>=#CockpitData.Strttm)and (autodata.msttime<#CockpitData.ndtim)and (autodata.ndtime>#CockpitData.ndtim))
OR((autodata.msttime<#CockpitData.Strttm)and (autodata.ndtime>#CockpitData.ndtim))
)
group by autodata.mc,#CockpitData.Strttm
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm


---mod 4 : Get PDT
insert into #PlannedDownTimesEffi(StartTime,EndTime,DownReason,Machine,MInterface,
		DStart ,
		Dend )  select
	CASE When StartTime<#CockpitData.Strttm Then #CockpitData.Strttm Else StartTime End,
	case When EndTime>#CockpitData.ndtim Then #CockpitData.ndtim Else EndTime End,DownReason,
	PlannedDownTimes.Machine,#CockpitData.machineinterface,#CockpitData.Strttm,#CockpitData.ndtim
	FROM PlannedDownTimes inner join #CockpitData on #CockpitData.MachineID=PlannedDownTimes.Machine
	WHERE pdtstatus=1 and (
	(StartTime >= #CockpitData.Strttm  AND EndTime <=#CockpitData.ndtim)
	OR ( StartTime < #CockpitData.Strttm  AND EndTime <= #CockpitData.ndtim AND EndTime > #CockpitData.Strttm )
	OR ( StartTime >= #CockpitData.Strttm   AND StartTime <#CockpitData.ndtim AND EndTime > #CockpitData.ndtim )
	OR ( StartTime < #CockpitData.Strttm  AND EndTime > #CockpitData.ndtim) )
	ORDER BY StartTime

/*
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
BEGIN
	UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0)- isNull(t2.Pdown,0)
	FROM(
		--Production Time in PDT
		SELECT T.Dstart,autodata.MC,SUM
			(CASE
			WHEN autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.cycletime+autodata.loadunload)
			WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )
			WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END)  as Pdown
		FROM AutoData inner jOIN #PlannedDownTimesEffi T on T.MInterface=autodata.mc
		WHERE autodata.DataType=1 AND
			(
			(autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )			
		group by autodata.mc,T.Dstart
	)as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.Dstart=#CockpitData.Strttm


	 ---mod 1 Handling interaction between PDT and ICD
	/* If production  Records of TYPE-1*/
	UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0)+ isNull(t2.IPDT,0)
	FROM( Select T.Dstart,AutoData.mc ,
	SUM(
	CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  AND  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT
	From AutoData INNER Join (Select mc,Sttime,NdTime,#CockpitData.Strttm as DurStrt,#CockpitData.ndtim as DurEnd
	 From AutoData inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(msttime >=#CockpitData.Strttm) AND (ndtime <= #CockpitData.ndtim)
	) as T1 ON AutoData.mc=T1.mc inner jOIN #PlannedDownTimesEffi T on
	 T.Minterface=autodata.mc and T1.DurStrt=T.Dstart
	Where AutoData.DataType=2
	And (( autodata.Sttime > T1.Sttime )
	And ( autodata.ndtime <  T1.ndtime ))
	AND
	((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
	or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
	or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
	or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )
	group by autodata.mc,T.Dstart
	)as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.Dstart=#CockpitData.Strttm
	
		
	/* If production  Records of TYPE-2*/
	UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0)+ isNull(t2.IPDT,0)
	FROM
	(Select T.Dstart,AutoData.mc ,
	SUM(
	CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  AND  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT
	From AutoData INNER Join
		(Select mc,Sttime,NdTime,#CockpitData.Strttm as DurStrt,#CockpitData.ndtim as DurEnd
	 From AutoData inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(msttime < #CockpitData.Strttm)And (ndtime > #CockpitData.Strttm) AND (ndtime <= #CockpitData.ndtim))
	 as T1
	ON AutoData.mc=T1.mc inner jOIN #PlannedDownTimesEffi T on
	 T.Minterface=autodata.mc and T1.DurStrt=T.Dstart
	Where AutoData.DataType=2
	And (( autodata.Sttime > T1.Sttime )
	And ( autodata.ndtime <  T1.ndtime )
	AND ( autodata.ndtime >  T.Dstart ))
	AND
	(( T.StartTime >= T.Dstart )
	And ( T.StartTime <  T1.ndtime ) )
	GROUP BY AUTODATA.mc,T.Dstart )as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.Dstart=#CockpitData.Strttm
	/* If production Records of TYPE-3*/
	UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0)+ isNull(t2.IPDT,0)
	FROM
	(Select T.Dstart,AutoData.mc ,
	SUM(
	CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT
	From AutoData INNER Join
		(Select mc,Sttime,NdTime,#CockpitData.Strttm as DurStrt,#CockpitData.ndtim as DurEnd From AutoData
		 inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(sttime >= #CockpitData.Strttm)And (ndtime > #CockpitData.ndtim) and sttime<#CockpitData.ndtim) as T1
	ON AutoData.mc=T1.mc inner jOIN #PlannedDownTimesEffi T on
	 T.Minterface=autodata.mc and T1.DurStrt=T.Dstart
	Where AutoData.DataType=2
	And ((T1.Sttime < autodata.sttime  )
	And ( T1.ndtime >  autodata.ndtime)
	AND (autodata.sttime<  T.Dend))
	AND
	(( T.EndTime > T1.Sttime )
	And ( T.EndTime <=T.Dend ) )
	GROUP BY AUTODATA.mc,T.Dstart)as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.Dstart=#CockpitData.Strttm
	/* If production Records of TYPE-4*/
	UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0)+ isNull(t2.IPDT,0)
	FROM
	(Select T.Dstart,AutoData.mc ,
	SUM(
	CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT
	From AutoData INNER Join
		(Select mc,Sttime,NdTime,#CockpitData.Strttm as DurStrt,#CockpitData.ndtim as DurEnd  From AutoData
		inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(msttime < #CockpitData.Strttm)And (ndtime > #CockpitData.ndtim)) as T1
	ON AutoData.mc=T1.mc inner jOIN #PlannedDownTimesEffi T on
	 T.Minterface=autodata.mc and T1.DurStrt=T.Dstart
	Where AutoData.DataType=2
	And ( (T1.Sttime < autodata.sttime  )
		And ( T1.ndtime >  autodata.ndtime)
		AND (autodata.ndtime  >  T.Dstart)
		AND (autodata.sttime  <  T.DEnd))
	AND
	(( T.StartTime >=T.Dstart)
	And ( T.EndTime <=T.DEnd ) )
	GROUP BY AUTODATA.mc,T.Dstart)as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.Dstart=#CockpitData.Strttm
END

*/

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
BEGIN

	UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0)- isNull(t2.Pdown,0)
	FROM(
		--Production Time in PDT
		SELECT T.Dstart,autodata.MC,SUM
			(CASE
			WHEN autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.cycletime+autodata.loadunload)
			WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )
			WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END)  as Pdown
		FROM 
		(select mc,msttime,ndtime,datatype,cycletime,loadunload from autodata
				inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface
				 where autodata.DataType=1 And 
				((autodata.msttime >= #CockpitData.Strttm  AND autodata.ndtime <=#CockpitData.ndtim)
				OR ( autodata.msttime < #CockpitData.Strttm  AND autodata.ndtime <= #CockpitData.ndtim AND autodata.ndtime > #CockpitData.Strttm )
				OR ( autodata.msttime >= #CockpitData.Strttm   AND autodata.msttime <#CockpitData.ndtim AND autodata.ndtime > #CockpitData.ndtim )
				OR ( autodata.msttime < #CockpitData.Strttm  AND autodata.ndtime > #CockpitData.ndtim))
		)
		AutoData inner jOIN #PlannedDownTimesEffi T on T.MInterface=autodata.mc
		WHERE autodata.DataType=1 AND
			(
			(autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )			
		group by autodata.mc,T.Dstart
	)as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.Dstart=#CockpitData.Strttm


	 ---mod 1 Handling interaction between PDT and ICD
	/* If production  Records of TYPE-1*/
		UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0)+ isNull(t2.IPDT,0)
		FROM( Select T.Dstart,T1.mc ,
		SUM(
		CASE 	
			When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1
			When T1.sttime < T.StartTime  AND  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2
			When ( T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime ) Then datediff(s, T1.sttime,T.EndTime ) ---type 3
			when ( T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT from
			(Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype
			,#CockpitData.Strttm as DurStrt,#CockpitData.ndtim as DurEnd from autodata A
			inner join #CockpitData on A.mc=#CockpitData.MachineInterface
			Where A.DataType=2
			and exists 
				(
				Select B.Sttime,B.NdTime,B.mc From AutoData B
				inner join #CockpitData on B.mc=#CockpitData.MachineInterface
				Where B.mc = A.mc and
				B.DataType=1 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And
				(B.msttime >= #CockpitData.Strttm AND B.ndtime <= #CockpitData.ndtim) and
				(B.sttime <= A.sttime) AND (B.ndtime >= A.ndtime)  --DR0339
				)
			 )as T1 inner join #PlannedDownTimesEffi T on T.Minterface=T1.mc and T1.DurStrt=T.Dstart
			 AND
			((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
			or (T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
			or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
			or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )group by T1.mc,T.Dstart
			)AS T2  inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.Dstart=#CockpitData.Strttm
	
	/* If production  Records of TYPE-2*/	
		UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0)+ isNull(t2.IPDT,0) FROM
		(Select T.Dstart,T1.mc ,
		SUM(
		CASE 	
			When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1
			When T1.sttime < T.StartTime  AND  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2
			When ( T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime ) Then datediff(s, T1.sttime,T.EndTime ) ---type 3
			when ( T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT from
		(Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype 
		,#CockpitData.Strttm as DurStrt,#CockpitData.ndtim as DurEnd from autodata A
		inner join #CockpitData on A.mc=#CockpitData.MachineInterface
		Where A.DataType=2
		and exists 
		(
		Select B.Sttime,B.NdTime From AutoData B
		inner join #CockpitData on B.mc=#CockpitData.MachineInterface
		Where B.mc = A.mc and
		B.DataType=1 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And
		(B.msttime < #CockpitData.Strttm And B.ndtime > #CockpitData.Strttm AND B.ndtime <= #CockpitData.ndtim) 
		And ((A.Sttime > B.Sttime) And ( A.ndtime < B.ndtime) AND ( A.ndtime > #CockpitData.Strttm ))
		)
		)as T1 inner join #PlannedDownTimesEffi T on T.Minterface=T1.mc and T1.DurStrt=T.Dstart AND
		(( T.StartTime >= T1.DurStrt ) And ( T.StartTime <  T1.ndtime )) 
		GROUP BY T1.mc,T.Dstart )as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.Dstart=#CockpitData.Strttm




	/* If production Records of TYPE-3*/
	UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0)+ isNull(t2.IPDT,0)
	FROM
	(Select T.Dstart,T1.mc ,
	SUM(
	CASE 	
		When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1
		When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2
		When ( T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime ) Then datediff(s, T1.sttime,T.EndTime ) ---type 3
		when ( T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT from
		(Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype
		,#CockpitData.Strttm as DurStrt,#CockpitData.ndtim as DurEnd from autodata A
		inner join #CockpitData on A.mc=#CockpitData.MachineInterface
		Where A.DataType=2
		and exists 
		(
		Select B.Sttime,B.NdTime From AutoData B
		inner join #CockpitData on B.mc=#CockpitData.MachineInterface
		Where B.mc = A.mc and
		B.DataType=1 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And
		(B.sttime >= #CockpitData.Strttm And B.ndtime > #CockpitData.ndtim and B.sttime <#CockpitData.ndtim) and
		((B.Sttime < A.sttime  )And ( B.ndtime > A.ndtime) AND (A.msttime < #CockpitData.ndtim))
		)
		)as T1 inner jOIN #PlannedDownTimesEffi T on T.Minterface=T1.mc and T1.DurStrt=T.Dstart
		AND (( T.EndTime > T1.Sttime )And ( T.EndTime <=T1.DurEnd ))
		GROUP BY T1.mc,T.Dstart
		)as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.Dstart=#CockpitData.Strttm



/* If production Records of TYPE-4*/
	UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0)+ isNull(t2.IPDT,0)
	FROM
	(Select T.Dstart,T1.mc ,
	SUM(
	CASE 	
		When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1
		When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2
		When ( T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime ) Then datediff(s, T1.sttime,T.EndTime ) ---type 3
		when ( T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT from
	(Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype 
	,#CockpitData.Strttm as DurStrt,#CockpitData.ndtim as DurEnd from autodata A
	inner join #CockpitData on A.mc=#CockpitData.MachineInterface
	Where A.DataType=2
	and exists 
	(
	Select B.Sttime,B.NdTime From AutoData B
    inner join #CockpitData on B.mc=#CockpitData.MachineInterface
	Where B.mc = A.mc and
	B.DataType=1 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And
	(B.msttime < #CockpitData.Strttm And B.ndtime > #CockpitData.ndtim)
	And ((B.Sttime < A.sttime)And ( B.ndtime >  A.ndtime)AND (A.ndtime  >  #CockpitData.Strttm) AND (A.sttime  <  #CockpitData.ndtim))
	)
	)as T1 inner jOIN #PlannedDownTimesEffi T on  T.Minterface=T1.mc and T1.DurStrt=T.Dstart AND
	(( T.StartTime >=T1.DurStrt) And ( T.EndTime <=T1.DurEnd )) 
    GROUP BY T1.mc,T.Dstart)as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.Dstart=#CockpitData.Strttm

END



UPDATE  #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
FROM
(Select T1.DurStrt as intime,AutoData.mc ,
SUM(
CASE
	When autodata.sttime <= T1.DurStrt Then datediff(s, T1.DurStrt,autodata.ndtime )
	When autodata.sttime > T1.DurStrt Then datediff(s , autodata.sttime,autodata.ndtime)
END)  as Down
From AutoData INNER Join
	(Select mc,Sttime,NdTime,#CockpitData.Strttm as DurStrt,#CockpitData.ndtim as DurEnd
	 From AutoData inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(msttime < #CockpitData.Strttm)And (ndtime > #CockpitData.Strttm) AND (ndtime <= #CockpitData.ndtim)) as T1
ON AutoData.mc=T1.mc
Where AutoData.DataType=2
And ( autodata.Sttime > T1.Sttime )
And ( autodata.ndtime <  T1.ndtime )
AND ( autodata.ndtime >  T1.DurStrt )
GROUP BY AUTODATA.mc,T1.DurStrt )AS T2 Inner Join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm


--ICD for Type 3 prod record		
UPDATE  #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
FROM
(Select T1.DurStrt as intime,AutoData.mc ,
SUM(CASE
	When autodata.ndtime > T1.DurEnd Then datediff(s,autodata.sttime, T1.DurEnd )
	When autodata.ndtime <=T1.DurEnd Then datediff(s , autodata.sttime,autodata.ndtime)
END) as Down
From AutoData INNER Join
	(Select mc,Sttime,NdTime,#CockpitData.Strttm as DurStrt,#CockpitData.ndtim as DurEnd From AutoData
	 inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(sttime >= #CockpitData.Strttm)And (ndtime > #CockpitData.ndtim) and sttime<#CockpitData.ndtim ) as T1
ON AutoData.mc=T1.mc
Where AutoData.DataType=2
And (T1.Sttime < autodata.sttime  )
And ( T1.ndtime >  autodata.ndtime)
AND (autodata.sttime  <  T1.DurEnd)
GROUP BY AUTODATA.mc,T1.DurStrt )AS T2 Inner Join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm


--ICD for Type 4 prod record	
UPDATE  #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
FROM
(Select T1.DurStrt as intime, AutoData.mc ,
SUM(CASE

	When autodata.sttime >= T1.DurStrt AND autodata.ndtime <= T1.DurEnd Then datediff(s , autodata.sttime,autodata.ndtime)
	When autodata.sttime < T1.DurStrt AND autodata.ndtime<=T1.DurEnd and autodata.ndtime > T1.DurStrt Then datediff(s, T1.DurStrt,autodata.ndtime )
	When autodata.sttime>=T1.DurStrt and autodata.ndtime >T1.DurEnd AND autodata.sttime<T1.DurEnd  Then datediff(s,autodata.sttime, T1.DurEnd )
	When autodata.sttime<T1.DurStrt AND autodata.ndtime>T1.DurEnd   Then datediff(s , T1.DurStrt,T1.DurEnd)

END) as Down
From AutoData INNER Join
	(Select mc,Sttime,NdTime,#CockpitData.Strttm as DurStrt,#CockpitData.ndtim as DurEnd  From AutoData
		inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(msttime < #CockpitData.Strttm)And (ndtime > #CockpitData.ndtim) ) as T1
ON AutoData.mc=T1.mc
Where AutoData.DataType=2
And (T1.Sttime < autodata.sttime  )
And ( T1.ndtime >  autodata.ndtime)
AND (autodata.ndtime  >  T1.DurStrt)
AND (autodata.sttime  <  T1.DurEnd)
GROUP BY AUTODATA.mc,T1.DurStrt
)AS T2 Inner Join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm







-- Get the value of CN and components
-- Type 1 and type 2
UPDATE #CockpitData SET CN = isnull(CN,0) + isNull(t2.C1N1,0),components=isnull(components,0)+isnull(T2.pcount,0)
from
(select  #CockpitData.Strttm as intime,mc,
SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))*autodata.partscount) C1N1,
--CEILING (sum(CAST((autodata.partscount) AS Float)/ISNULL(componentoperationpricing.SubOperations,1))) as pcount
sum(CAST((autodata.partscount) AS Float)/ISNULL(componentoperationpricing.SubOperations,1)) as pcount

FROM autodata INNER JOIN
componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID AND
componentoperationpricing.componentid = componentinformation.componentid
inner join machineinformation on machineinformation.interfaceid=autodata.mc
and componentoperationpricing.machineid=machineinformation.machineid
inner join #CockpitData on componentoperationpricing.machineid=#CockpitData.MachineID --autodata.mc=#CockpitData.MachineInterface
where (autodata.ndtime>#CockpitData.Strttm)
and (autodata.ndtime<=#CockpitData.ndtim)
and (autodata.datatype=1)
group by autodata.mc,#CockpitData.Strttm
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm


---mod 4
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	UPDATE #CockpitData SET CN = isnull(CN,0) - isNull(t2.C1N1,0),Components=isnull(components,0)-isnull(t2.PlanCt,0)
	From
	(
		select T.Dstart as intime,mc,SUM((O.cycletime * ISNULL(A.PartsCount,1))/ISNULL(O.SubOperations,1))  C1N1 ,
		--CEILING (sum(CAST((A.partscount) AS Float)/ISNULL(O.SubOperations,1))) as PlanCt
		sum(CAST((A.partscount) AS Float)/ISNULL(O.SubOperations,1)) as PlanCt
		From autodata A
		inner join machineinformation M on M.interfaceid=A.mc
		Inner join componentinformation C ON A.Comp=C.interfaceid
		Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid
		and O.MachineId=M.MachineId
		inner jOIN #PlannedDownTimesEffi T  on T.Minterface=A.mc
		WHERE A.DataType=1
		AND(A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)
		AND(A.ndtime > T.Dstart  AND A.ndtime <=T.Dend)
		Group by mc,T.Dstart
	) as T2
	inner join #CockpitData  on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
END



---mod 4
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y')
BEGIN
	--downtime type 1,2,3,4
	UPDATE #CockpitData SET downtime = isnull(downtime,0) + isNull(t2.down,0)
	from
	(select     #CockpitData.Strttm as intime, mc,
	sum(case when ( (autodata.msttime>= #CockpitData.Strttm) and (autodata.ndtime<=#CockpitData.ndtim)) then  (loadunload)
			 when ((autodata.msttime< #CockpitData.Strttm)and (autodata.ndtime> #CockpitData.Strttm)and (autodata.ndtime<=#CockpitData.ndtim)) then DateDiff(second,  #CockpitData.Strttm, ndtime)
			 when ((autodata.msttime>= #CockpitData.Strttm)and (autodata.msttime<#CockpitData.ndtim)and (autodata.ndtime>#CockpitData.ndtim)) then DateDiff(second, mstTime, #CockpitData.ndtim)
			 when ((autodata.msttime< #CockpitData.Strttm)and (autodata.ndtime>#CockpitData.ndtim)) then DateDiff(second,  #CockpitData.Strttm, #CockpitData.ndtim) END ) as  down
	from autodata inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface
	where (autodata.datatype=2)
	AND(( (autodata.msttime>=#CockpitData.Strttm) and (autodata.ndtime<=#CockpitData.ndtim))
	OR ((autodata.msttime<#CockpitData.Strttm)and (autodata.ndtime>#CockpitData.Strttm)and (autodata.ndtime<=#CockpitData.ndtim))
	OR ((autodata.msttime>=#CockpitData.Strttm)and (autodata.msttime<#CockpitData.ndtim)and (autodata.ndtime>#CockpitData.ndtim))
	OR((autodata.msttime<#CockpitData.Strttm)and (autodata.ndtime>#CockpitData.ndtim)))
	group by autodata.mc,#CockpitData.Strttm
	) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
	--ManagementLoss
	-- Type 1
	UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
	from
	(select #CockpitData.Strttm as intime,mc,sum(
	CASE
	WHEN (loadunload) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
	THEN isnull(downcodeinformation.Threshold,0)
	ELSE loadunload
	END) AS LOSS
	from autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
	inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface
	where (autodata.msttime>=#CockpitData.Strttm)
	and (autodata.ndtime<=#CockpitData.ndtim)
	and (autodata.datatype=2)
	and (downcodeinformation.availeffy = 1)
	group by autodata.mc,#CockpitData.Strttm
	) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
				
	-- Type 2
	UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
	from
	(select    #CockpitData.Strttm as intime, mc,sum(
	CASE WHEN DateDiff(second, #CockpitData.Strttm, ndtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
	then isnull(downcodeinformation.Threshold,0)
	ELSE DateDiff(second, #CockpitData.Strttm, ndtime)
	END)loss
	--DateDiff(second, @CurStarttime, ndtime)
	from autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
	inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface
	where (autodata.sttime<#CockpitData.Strttm)
	and (autodata.ndtime>#CockpitData.Strttm)
	and (autodata.ndtime<=#CockpitData.ndtim)
	and (autodata.datatype=2)
	and (downcodeinformation.availeffy = 1)
	group by autodata.mc,#CockpitData.Strttm
	) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
				
	-- Type 3
	UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
	from
	(select   #CockpitData.Strttm as intime, mc,SUM(
	CASE WHEN DateDiff(second,stTime, #CockpitData.ndtim) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
	then isnull(downcodeinformation.Threshold,0)
	ELSE DateDiff(second, stTime, #CockpitData.ndtim)
	END)loss
	-- sum(DateDiff(second, stTime, @curendtime)) loss
	from autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
	inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface
	where (autodata.msttime>=#CockpitData.Strttm)
	and (autodata.sttime<#CockpitData.ndtim)
	and (autodata.ndtime>#CockpitData.ndtim)
	and (autodata.datatype=2)
	and (downcodeinformation.availeffy = 1)
	group by autodata.mc,#CockpitData.Strttm
	) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm

	-- Type 4
	UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
	from
	(select #CockpitData.Strttm as intime, mc,sum(
	CASE WHEN DateDiff(second, #CockpitData.Strttm, #CockpitData.ndtim) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
	then isnull(downcodeinformation.Threshold,0)
	ELSE DateDiff(second, #CockpitData.Strttm, #CockpitData.ndtim)
	END)loss
	--sum(DateDiff(second, @CurStarttime, @curendtime)) loss
	from autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
	inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface
	where autodata.msttime<#CockpitData.Strttm
	and autodata.ndtime>#CockpitData.ndtim
	and (autodata.datatype=2)
	and (downcodeinformation.availeffy = 1)
	group by autodata.mc,#CockpitData.Strttm
	) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm

	IF (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y'
	BEGIN
	
	---get PDT downs overlapping with the down records.
		UPDATE #CockpitData SET downtime = isnull(downtime,0) - isNull(t2.PldDown,0)
		from(
		select T.Dstart  as intime,autodata.mc as mc,SUM
		       (CASE
			WHEN (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN autodata.loadunload
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PldDown
		FROM AutoData inner jOIN #PlannedDownTimesEffi T  on T.Minterface=autodata.mc
		INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID
		WHERE autodata.DataType=2    and  (
			(autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )			
			AND DownCodeInformation.DownID=(SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')
		group by autodata.mc,T.Dstart ) as t2 inner join #CockpitData
		on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
	END
	
END



If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN
	---Get the down times which are not of type Management Loss
	UPDATE #CockpitData SET downtime = isnull(downtime,0) + isNull(t2.down,0)
	from
	(select     #CockpitData.Strttm as intime, mc,
	sum(case when ( (autodata.msttime>= #CockpitData.Strttm) and (autodata.ndtime<=#CockpitData.ndtim)) then  (loadunload)
			 when ((autodata.msttime< #CockpitData.Strttm)and (autodata.ndtime> #CockpitData.Strttm)and (autodata.ndtime<=#CockpitData.ndtim)) then DateDiff(second,  #CockpitData.Strttm, ndtime)
			 when ((autodata.msttime>= #CockpitData.Strttm)and (autodata.msttime<#CockpitData.ndtim)and (autodata.ndtime>#CockpitData.ndtim)) then DateDiff(second, mstTime, #CockpitData.ndtim)
			 when ((autodata.msttime< #CockpitData.Strttm)and (autodata.ndtime>#CockpitData.ndtim)) then DateDiff(second,  #CockpitData.Strttm, #CockpitData.ndtim) END ) as  down
	from autodata inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface
	inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
	where (autodata.datatype=2)
	AND(( (autodata.msttime>=#CockpitData.Strttm) and (autodata.ndtime<=#CockpitData.ndtim))
	OR ((autodata.msttime<#CockpitData.Strttm)and (autodata.ndtime>#CockpitData.Strttm)and (autodata.ndtime<=#CockpitData.ndtim))
	OR ((autodata.msttime>=#CockpitData.Strttm)and (autodata.msttime<#CockpitData.ndtim)and (autodata.ndtime>#CockpitData.ndtim))
	OR((autodata.msttime<#CockpitData.Strttm)and (autodata.ndtime>#CockpitData.ndtim))) AND (downcodeinformation.availeffy = 0)
	group by autodata.mc,#CockpitData.Strttm
	) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
	
	---get PDT downs overlapping with the down records.
	UPDATE #CockpitData SET downtime = isnull(downtime,0) - isNull(t2.PldDown,0)
	from(
		select T.Dstart  as intime,autodata.mc as mc,SUM
		       (CASE
			WHEN (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN autodata.loadunload
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PldDown
		FROM AutoData inner jOIN #PlannedDownTimesEffi T  on T.Minterface=autodata.mc
		INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID
		WHERE autodata.DataType=2    and  (
			(autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )			
			AND (downcodeinformation.availeffy = 0)
		group by autodata.mc,T.Dstart ) as t2 inner join #CockpitData
		on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm


	UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0)+ isNull(t4.Mloss,0),MLDown=isNull(MLDown,0)+isNull(t4.Dloss,0)
	from
	(select T3.mc,T3.Instart,sum(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss from
	 (
	select   t1.id,T1.mc,T1.Threshold,T1.InStart as Instart,
	case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0) > 0
	then DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)- isnull(T1.Threshold ,0)
	else 0 End  as Dloss,
	case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0) > 0
	then isnull(T1.Threshold,0)
	else DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0) End  as Mloss
	 from
	
	(   select id,mc,comp,opn,opr,D.threshold,#CockpitData.Strttm as InStart,
		case when autodata.sttime<#CockpitData.Strttm then #CockpitData.Strttm else sttime END as sttime,
	       	case when ndtime>#CockpitData.ndtim then #CockpitData.ndtim else ndtime END as ndtime
		from autodata inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface
	inner join  downcodeinformation D on autodata.dcode=D.interfaceid
	where (autodata.datatype=2)
	AND(( (autodata.msttime>=#CockpitData.Strttm) and (autodata.ndtime<=#CockpitData.ndtim))
	OR ((autodata.msttime<#CockpitData.Strttm)and (autodata.ndtime>#CockpitData.Strttm)and (autodata.ndtime<=#CockpitData.ndtim))
	OR ((autodata.msttime>=#CockpitData.Strttm)and (autodata.msttime<#CockpitData.ndtim)and (autodata.ndtime>#CockpitData.ndtim))
	OR((autodata.msttime<#CockpitData.Strttm)and (autodata.ndtime>#CockpitData.ndtim)))  AND (D.availeffy = 1)) as T1 	
	left outer join
	(SELECT T.Dstart  as intime , autodata.id,
		       sum(CASE
			WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PPDT
		FROM AutoData inner jOIN #PlannedDownTimesEffi T  on T.MInterface=autodata.mc
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		WHERE autodata.DataType=2 and
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)
			 AND (downcodeinformation.availeffy = 1) group by autodata.id,T.Dstart ) as T2 on T1.id=T2.id  and T2.Intime=T1.InStart ) as T3  group by T3.mc,T3.Instart
	) as t4 inner join  #CockpitData
		on t4.mc = #CockpitData.machineinterface and t4.Instart=#CockpitData.Strttm
	UPDATE #CockpitData  set downtime = isnull(downtime,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)
END




---Exceptions
SELECT @StrSql = 'INSERT INTO #Exceptions(MachineID ,ComponentID,OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,ExCount,DurStart,DurEnd )
		SELECT Ex.MachineID ,Ex.ComponentID,Ex.OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,0,
		S.FromTime,S.ToTime
		From ProductionCountException Ex
		Inner Join MachineInformation M ON Ex.MachineID=M.MachineID
		Inner Join ComponentInformation C ON Ex.ComponentID=C.ComponentID
		Inner Join Componentoperationpricing O ON Ex.OperationNo=O.OperationNo AND C.ComponentID=O.ComponentID '
SELECT @StrSql = @StrSql+ ' and Ex.machineid=O.machineid cross join #ShiftTemp S  '
SELECT @StrSql = @StrSql+ ' WHERE  M.MultiSpindleFlag=1 '
SELECT @StrSql =@StrSql + @strXMachine
SELECT @StrSql =@StrSql +'AND ((Ex.StartTime>=  S.FromTime AND Ex.EndTime<= S.ToTime )
		OR (Ex.StartTime< S.FromTime AND Ex.EndTime> S.FromTime AND Ex.EndTime<= S.ToTime)
		OR(Ex.StartTime>=S.FromTime AND Ex.EndTime> S.ToTime AND Ex.StartTime< S.ToTime)
		OR(Ex.StartTime< S.FromTime AND Ex.EndTime> S.ToTime ))'
Exec (@strsql)
IF ( SELECT Count(*) from #Exceptions ) <> 0
BEGIN
	UPDATE #Exceptions SET StartTime=DurStart WHERE (StartTime<DurStart AND EndTime>DurStart)
	UPDATE #Exceptions SET EndTime=DurEnd WHERE (EndTime>DurEnd AND StartTime<DurEnd )
	Select @StrSql = 'UPDATE #Exceptions SET ExCount=ISNULL(T2.Comp,0) From
	(
		SELECT T1.DurStart,T1.DurEnd,T1.MachineID AS MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime AS StartTime,T1.EndTime AS EndTime,
		SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp
	 	From (
			select Tt1.DurStart,Tt1.DurEnd,MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,comp,opn,Tt1.StartTime,Tt1.EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from autodata
			Inner Join MachineInformation   ON autodata.MC=MachineInformation.InterfaceID
			Inner Join EmployeeInformation E  ON autodata.Opr=E.InterfaceID
			Inner Join ComponentInformation  ON autodata.Comp = ComponentInformation.InterfaceID
			Inner Join ComponentOperationPricing on autodata.Opn=ComponentOperationPricing.InterfaceID And ComponentInformation.ComponentID=ComponentOperationPricing.ComponentID '
	SELECT @StrSql =@StrSql + ' and MachineInformation.machineid=ComponentOperationPricing.machineid '
	SELECT @StrSql =@StrSql +' Inner Join (
				Select DurStart,DurEnd,MachineID,ComponentID,OperationNo,StartTime,EndTime From #Exceptions
			)AS Tt1 ON Tt1.MachineID=MachineInformation.MachineID AND Tt1.ComponentID = ComponentInformation.ComponentID AND Tt1.OperationNo= ComponentOperationPricing.OperationNo
			and Tt1.Machineid=ComponentOperationPricing.MachineID
			Where (autodata.ndtime>Tt1.StartTime) AND (autodata.ndtime<=Tt1.EndTime) and (autodata.datatype=1) '
	Select @StrSql = @StrSql+' Group by MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,Tt1.StartTime,Tt1.EndTime,comp,opn,Tt1.DurStart,Tt1.DurEnd
		) as T1
	   	Inner join componentinformation C on T1.Comp=C.interfaceid
	   	Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid '
	Select @StrSql = @StrSql+' Inner join machineinformation M on T1.MachineID=M.machineid  and M.MachineId=O.MachineID'
	Select @StrSql = @StrSql+' GROUP BY T1.MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime,t1.EndTime,T1.DurStart,T1.DurEnd
	)AS T2
	WHERE  #Exceptions.StartTime=T2.StartTime AND #Exceptions.EndTime=T2.EndTime
	AND #Exceptions.MachineID=T2.MachineID AND #Exceptions.ComponentID = T2.ComponentID AND #Exceptions.OperationNo=T2.OperationNo
	and #Exceptions.DurStart=T2.DurStart and #Exceptions.DurEnd=T2.DurEnd'
	Exec(@StrSql)
	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
	BEGIN
			
		Select @StrSql =''
		Select @StrSql ='UPDATE #Exceptions SET ExCount=ISNULL(ExCount,0) - ISNULL(T3.Comp,0)
		From
		(
			SELECT T2.Dstart,T2.Dend,T2.MachineID AS MachineID,T2.ComponentID,T2.OperationNo,T2.StartTime AS StartTime,T2.EndTime AS EndTime,
			SUM(CEILING (CAST(T2.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp
			From
			(
				select T1.Dstart,T1.Dend,MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,comp,opn,
				Max(T1.XStartTime)StartTime,Max(T1.XEndTime)EndTime,T1.PLD_StartTime,T1.PLD_EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from autodata
				Inner Join MachineInformation   ON autodata.MC=MachineInformation.InterfaceID
				Inner Join ComponentInformation  ON autodata.Comp = ComponentInformation.InterfaceID
				Inner Join ComponentOperationPricing on autodata.Opn=ComponentOperationPricing.InterfaceID And ComponentInformation.ComponentID=ComponentOperationPricing.ComponentID
				and ComponentOperationPricing.Machineid=MachineInformation.Machineid
				Inner Join	
				(
					SELECT Td.Dstart,Td.Dend,MachineID,ComponentID,OperationNo,Ex.StartTime As XStartTime, Ex.EndTime AS XEndTime,
					CASE
						WHEN (Td.StartTime< Ex.StartTime And Td.EndTime<=Ex.EndTime AND Td.EndTime>Ex.StartTime) THEN Ex.StartTime
						WHEN  (Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime) THEN Ex.StartTime
						ELSE Td.StartTime
					END AS PLD_StartTime,
					CASE
						WHEN (Td.StartTime>= Ex.StartTime And Td.StartTime <Ex.EndTime AND Td.EndTime>Ex.EndTime) THEN Ex.EndTime
						WHEN  (Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime) THEN Ex.EndTime
						ELSE  Td.EndTime
					END AS PLD_EndTime
		
					From #Exceptions AS Ex inner  join  #PlannedDownTimesEffi  Td on Td.Machine=Ex.Machineid
					Where   ((Td.StartTime>=Ex.StartTime And Td.EndTime <=Ex.EndTime)OR
					(Td.StartTime< Ex.StartTime And Td.EndTime<=Ex.EndTime AND Td.EndTime>Ex.StartTime)OR
					(Td.StartTime>= Ex.StartTime And Td.StartTime <Ex.EndTime AND Td.EndTime>Ex.EndTime)OR
					(Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime))  '
			Select @StrSql = @StrSql + ' )AS T1 ON T1.MachineID=MachineInformation.MachineID AND T1.ComponentID = ComponentInformation.ComponentID AND
						   T1.OperationNo= ComponentOperationPricing.OperationNo and T1.machineid=ComponentOperationPricing.Machineid
				Where (autodata.ndtime>T1.PLD_StartTime AND autodata.ndtime<=T1.PLD_EndTime) and (autodata.datatype=1)
			AND (autodata.ndtime > T1.Dstart AND autodata.ndtime<=T1.Dend )'
			Select @StrSql = @StrSql+' Group by MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,T1.PLD_StartTime,T1.PLD_EndTime,comp,opn,T1.Dstart,T1.Dend
			)AS T2
			Inner join componentinformation C on T2.Comp=C.interfaceid
			Inner join ComponentOperationPricing O ON T2.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineId=T2.MachineID
			GROUP BY T2.MachineID,T2.ComponentID,T2.OperationNo,T2.StartTime,t2.EndTime,T2.Dstart,T2.Dend
		)As T3
		WHERE  #Exceptions.StartTime=T3.StartTime AND #Exceptions.EndTime=T3.EndTime
		AND #Exceptions.MachineID=T3.MachineID AND #Exceptions.ComponentID = T3.ComponentID AND #Exceptions.OperationNo=T3.OperationNo
		and #Exceptions.DurStart=T3.DStart and #Exceptions.DurEnd=T3.DEnd'
		PRINT @StrSql
		EXEC(@StrSql)
	END
	UPDATE #Exceptions SET ExCount=ExCount-((ExCount * ActualCount)/ISNULL(IdealCount,0))
	
END




--vasavi
UPDATE #CockpitData SET turnover = isnull(turnover,0) + isNull(t2.revenue,0)
from
(select mc,
SUM((componentoperationpricing.price/ISNULL(ComponentOperationPricing.SubOperations,1))* ISNULL(autodata.partscount,1)) revenue
FROM autodata
INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID
INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID AND componentoperationpricing.componentid = componentinformation.componentid
---mod 2
inner join machineinformation on componentoperationpricing.machineid=machineinformation.machineid
inner join #CockpitData on #CockpitData.machineid=machineinformation.machineid
--mod 2 :- ER0181 By Kusuma M.H on 15-Sep-2009.
AND autodata.mc = machineinformation.interfaceid
--mod 2 :- ER0181 By Kusuma M.H on 15-Sep-2009.
---mod 2
where (
(autodata.sttime>=#CockpitData.Strttm and autodata.ndtime<=#CockpitData.ndtim)OR
(autodata.sttime<#CockpitData.Strttm and autodata.ndtime>#CockpitData.Strttm and autodata.ndtime<=#CockpitData.ndtim))and (autodata.datatype=1)
group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface


--Excluding Exception count from turnover calculation
UPDATE #CockpitData SET Turnover = ISNULL(Turnover,0) - ISNULL(t2.xTurnover,0)
from
( select Ex.MachineID,
SUM((O.price)* ISNULL(ExCount,0)) as xTurnover
From #Exceptions Ex
INNER JOIN ComponentInformation C ON Ex.ComponentID=C.ComponentID
INNER JOIN ComponentOperationPricing O ON Ex.OperationNO=O.OperationNO AND C.ComponentID=O.ComponentID
---mod 2
and O.machineid = Ex.machineid
---mod 2
GROUP BY Ex.MachineID) as T2
Inner join #CockpitData on T2.MachineID = #CockpitData.MachineID

begin
	--ER0368 From here
CREATE TABLE #ShiftDefn
(
	ShiftDate datetime,		
	Shiftname nvarchar(20),
	ShftSTtime datetime,
	ShftEndTime datetime	
)



declare @startdate as datetime
declare @enddate as datetime
declare @startdatetime nvarchar(20)
if  @TimeAxis='Month'
BEGIN
select @startdate = [dbo].[f_GetLogicalMonth](@StartTime,'start')
select @enddate = dbo.f_GetLogicalDayend(@endtime)
END
if @TimeAxis='Shift' or @TimeAxis='DAY'
BEGIN
select @startdate=dbo.f_GetLogicalDayend(@StartTime)
select @enddate=dbo.f_GetLogicalDayend(@StartTime)
END



while @startdate<=@enddate
Begin

	select @startdatetime = CAST(datePart(yyyy,@startdate) AS nvarchar(4)) + '-' + 
     CAST(datePart(mm,@startdate) AS nvarchar(2)) + '-' + 
     CAST(datePart(dd,@startdate) AS nvarchar(2))

	INSERT INTO #ShiftDefn(ShiftDate,Shiftname,ShftSTtime,ShftEndTime)
	select @startdate,ShiftName,
	Dateadd(DAY,FromDay,(convert(datetime, @startdatetime + ' ' + CAST(datePart(hh,FromTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,FromTime) as nvarchar(2))+ ':' + CAST(datePart(ss,FromTime) as nvarchar(2))))) as StartTime,
	DateAdd(Day,ToDay,(convert(datetime, @startdatetime + ' ' + CAST(datePart(hh,ToTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,ToTime) as nvarchar(2))+ ':' + CAST(datePart(ss,ToTime) as nvarchar(2))))) as EndTime
	from shiftdetails where running = 1 order by shiftid
	Select @startdate = dateadd(d,1,@startdate)
END


create table #shift
(
	
	ShiftDate nvarchar(10), --DR0333
	shiftname nvarchar(20),
	Shiftstart datetime,
	Shiftend datetime,
	shiftid int
)

Insert into #shift (ShiftDate,shiftname,Shiftstart,Shiftend)
select convert(nvarchar(10),ShiftDate,126),shiftname,ShftSTtime,ShftEndTime from #ShiftDefn --where ShftSTtime>=@StartTime and ShftEndTime<=@endtime 



Update #shift Set shiftid = isnull(#shift.Shiftid,0) + isnull(T1.shiftid,0) from
(Select SD.shiftid ,SD.shiftname from shiftdetails SD
inner join #shift S on SD.shiftname=S.shiftname where
running=1 )T1 inner join #shift on  T1.shiftname=#shift.shiftname

Update #CockPitData Set shiftid = isnull(#CockPitData.Shiftid,0) + isnull(T1.shiftid,0) from
(Select SD.shiftid ,SD.shiftname from shiftdetails SD
inner join #CockPitData S on SD.shiftname=S.shftnm where
running=1 )T1 inner join #CockPitData on  T1.shiftname=#CockPitData.shftnm

Update #Cockpitdata set RejCount = isnull(RejCount,0) + isnull(T1.RejQty,0)
From
( Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A
inner join Machineinformation M on A.mc=M.interfaceid
inner join #Cockpitdata on #Cockpitdata.machineid=M.machineid 
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
where A.CreatedTS>=@StartTime and A.CreatedTS<@Endtime and A.flag = 'Rejection'
and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000'
group by A.mc,M.Machineid
)T1 inner join #Cockpitdata B on B.Machineid=T1.Machineid 

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	Update #Cockpitdata set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from
	(Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A
	inner join Machineinformation M on A.mc=M.interfaceid
	inner join #Cockpitdata on #Cockpitdata.machineid=M.machineid 
	inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
	Cross join Planneddowntimes P
	where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid 
	and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000' and
	A.CreatedTS>=@StartTime and A.CreatedTS<@Endtime And
	A.CreatedTS>=P.Starttime and A.CreatedTS<P.endtime
	group by A.mc,M.Machineid)T1 inner join #Cockpitdata B on B.Machineid=T1.Machineid 
END

if @TimeAxis='Shift'
BEGIN

--Vas
Update #Cockpitdata set RejCount = isnull(RejCount,0) + isnull(T1.RejQty,0)
From
( 
 Select A.mc,sum(A.Rejection_Qty) as RejQty,M.Machineid,RejDate,C.shiftid as ShiftID,C.Pdt as PDT from AutodataRejections A
inner join Machineinformation M on A.mc=M.interfaceid
inner join #Cockpitdata C on C.machineid=M.machineid  and  C.ShiftID=A.RejShift and C.Pdt=convert(nvarchar(10),(A.RejDate),126)
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
inner join #shift S on convert(nvarchar(10),(A.RejDate),126)=S.shiftdate and A.RejShift=S.shiftid --DR0333
where A.flag = 'Rejection' and A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (S.shiftdate) 
and  Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
group by A.mc,M.Machineid,RejDate,C.shiftid,Pdt
)T1 inner join #Cockpitdata B on B.Machineid=T1.Machineid AND b.ShiftID=T1.ShiftID and b.Pdt=T1.PDT

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	Update #Cockpitdata set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from
	( Select A.mc,sum(A.Rejection_Qty) as RejQty,M.Machineid,RejDate,C.shiftid as ShiftID,C.Pdt as PDT from AutodataRejections A
	inner join Machineinformation M on A.mc=M.interfaceid
	inner join #Cockpitdata C on C.machineid=M.machineid  and  C.ShiftID=A.RejShift and C.Pdt=convert(nvarchar(10),(A.RejDate),126)
	inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
	inner join #shift S on convert(nvarchar(10),(A.RejDate),126)=S.shiftdate and A.RejShift=S.shiftid --DR0333
	Cross join Planneddowntimes P
	where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid and
	A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (S.shiftdate) and --DR0333
	Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
	and P.starttime>=S.Shiftstart and P.Endtime<=S.shiftend
	group by A.mc,M.Machineid,RejDate,C.shiftid,Pdt)T1 inner join #Cockpitdata B on B.Machineid=T1.Machineid AND b.ShiftID=T1.ShiftID and b.Pdt=T1.PDT
END

END
--vas
if @TimeAxis='DAY'
BEGIN


Update #Cockpitdata set RejCount = isnull(RejCount,0) + isnull(T1.RejQty,0)
From
( 
Select A.mc,sum(A.Rejection_Qty) as RejQty,M.Machineid,RejDate,C.Pdt as PDT from AutodataRejections A
inner join Machineinformation M on A.mc=M.interfaceid
inner join #Cockpitdata C on C.machineid=M.machineid  and C.Pdt=convert(nvarchar(10),(A.RejDate),126)
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
inner join #ShiftTemp S on convert(nvarchar(10),(A.RejDate),126)=S.PDate 
where A.flag = 'Rejection' and convert(nvarchar(10),(A.RejDate),126) in (S.PDate) 
and  Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
group by A.mc,M.Machineid,RejDate,Pdt
)T1 inner join #Cockpitdata B on B.Machineid=T1.Machineid  and b.Pdt=T1.PDT

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	Update #Cockpitdata set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from
	( Select A.mc,sum(A.Rejection_Qty) as RejQty,M.Machineid,RejDate,C.Pdt as PDT from AutodataRejections A
	inner join Machineinformation M on A.mc=M.interfaceid
	inner join #Cockpitdata C on C.machineid=M.machineid and C.Pdt=convert(nvarchar(10),(A.RejDate),126)
	inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
	inner join #ShiftTemp S on convert(nvarchar(10),(A.RejDate),126)=S.PDate 
	Cross join Planneddowntimes P
	where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid and
	convert(nvarchar(10),(A.RejDate),126) in (S.PDate) and --DR0333
	Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
	and P.starttime>=S.FromTime and P.Endtime<=S.ToTime
	group by A.mc,M.Machineid,RejDate,Pdt)T1 inner join #Cockpitdata B on B.Machineid=T1.Machineid and b.Pdt=T1.PDT

END

END

if @TimeAxis='Month'
BEGIN



Update #Cockpitdata set RejCount = isnull(RejCount,0) + isnull(T1.RejQty,0)
From
( 
Select A.mc,sum(A.Rejection_Qty) as RejQty,M.Machineid,DATEPART(month,C.Pdt) as mm,DATEPART(year,C.Pdt) as yy from AutodataRejections A
inner join Machineinformation M on A.mc=M.interfaceid
inner join #Cockpitdata C on C.machineid=M.machineid and DATEPART(month,A.RejDate) = DATEPART(month,C.Pdt)
 and DATEPART(year,A.RejDate) = DATEPART(year,C.Pdt) 
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
inner join #ShiftTemp S on DATEPART(month,A.RejDate) = DATEPART(month,S.PDate) and 
DATEPART(year,A.RejDate) = DATEPART(year,S.PDate) 
where A.flag = 'Rejection' and  DATEPART(month,A.RejDate) = DATEPART(month,S.PDate) and 
DATEPART(year,A.RejDate) = DATEPART(year,S.PDate) 
and  Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
group by A.mc,M.Machineid,DATEPART(month,C.Pdt) ,DATEPART(year,C.Pdt)
)T1 inner join #Cockpitdata B on B.Machineid=T1.Machineid  and DATEPART(month,b.Pdt) =T1.mm and DATEPART(year,b.Pdt) =T1.yy 

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	Update #Cockpitdata set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from
	( Select A.mc,sum(A.Rejection_Qty) as RejQty,M.Machineid,DATEPART(month,C.Pdt) as mm,DATEPART(year,C.Pdt) as yy from AutodataRejections A
	inner join Machineinformation M on A.mc=M.interfaceid
	inner join #Cockpitdata C on C.machineid=M.machineid and DATEPART(month,A.RejDate) = DATEPART(month,C.Pdt)
	and DATEPART(year,A.RejDate) = DATEPART(year,C.Pdt) 
	inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
	inner join #ShiftTemp S on DATEPART(month,A.RejDate) = DATEPART(month,S.PDate) and 
	DATEPART(year,A.RejDate) = DATEPART(year,S.PDate) 
	Cross join Planneddowntimes P
	where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid and
	Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
	and P.starttime>=S.FromTime and P.Endtime<=S.ToTime
	group by A.mc,M.Machineid,DATEPART(month,C.Pdt) ,DATEPART(year,C.Pdt))
	T1 inner join #Cockpitdata B on B.Machineid=T1.Machineid and DATEPART(month,b.Pdt) =T1.mm and DATEPART(year,b.Pdt) =T1.yy 

END

END
--vas

end

--Apply Exception on Count..
UPDATE #CockpitData SET components = ISNULL(components,0) - ISNULL(t2.comp,0)
from
( select DurStart as intime,MachineID,SUM(ExCount) as comp
	From #Exceptions GROUP BY MachineID,DurStart ) as T2
Inner join #CockpitData on T2.MachineID = #CockpitData.MachineID
and t2.intime=#CockpitData.Strttm

UPDATE #Cockpitdata SET QualityEfficiency= ISNULL(QualityEfficiency,0) + IsNull(T1.QE,0) 
FROM(Select MachineID,
CAST((Sum(Components))As Float)/CAST((Sum(IsNull(Components,0))+Sum(IsNull(RejCount,0))) AS Float)As QE,Strttm
From #Cockpitdata Where Components<>0 Group By MachineID,Strttm
)AS T1 Inner Join #Cockpitdata ON  #Cockpitdata.MachineID=T1.MachineID and #Cockpitdata.Strttm=T1.Strttm


UPDATE #CockpitData
		SET
			ProductionEfficiency = (CN/UtilisedTime) ,
			AvailabilityEfficiency = (UtilisedTime)/(UtilisedTime + DownTime - ManagementLoss)
			
		WHERE UtilisedTime <> 0



update #CockPitData set MachineHourRate=
 mchrrate  from machineinformation inner join #CockpitData on machineinformation.MachineID = #CockpitData.MachineID

--vas
update #cockpitdata set AvgProductionEfficiency=isnull(t2.APE,0),AvgAvailabilityEfficiency = isnull(t2.aae,0),AvgOverallEfficiency=isnull(t2.OEE,0),totalComp=isnull(t2.totalComp,0) from 
 (select MachineId,avg(ProductionEfficiency)*100 as APE,avg(AvailabilityEfficiency)*100 as AAE,(avg(ProductionEfficiency * AvailabilityEfficiency)*100) As OEE,sum(components) as TotalComp  from #CockpitData 
 where UtilisedTime > 0 OR downtime > 0 --DR0360 added
group by machineid)t2 inner join #CockpitData on t2.MachineID = #CockpitData.MachineID




update #cockpitdata  set TargetOEE =isnull(t.OE,0) from    
(select machineid,OE,startdate,enddate from efficiencytarget)t 
inner join #CockpitData on t.MachineID = #CockpitData.MachineID and t.startdate<=#cockpitdata.Pdt and t.enddate>=#cockpitdata.Pdt 

update  #CockPitData set TotaldowntimeInt=DownTime 



--if @TimeAxis='Month' --Vas


if @TimeAxis='Shift'
BEGIN
	DECLARE @strShiftName  nvarchar(200)
	Declare @Machine as nvarchar(200)
		SET @strShiftName = ''
		SET @strmachine = ''
		if isnull(@Machine,'') <> ''
			BEGIN
			---mod 2
--			SELECT @strmachine = ' AND ( ShiftProductionDetails.machineid = ''' + @Machine+ ''')'
			SELECT @strmachine = ' AND ( ShiftProductionDetails.machineid = N''' + @Machine+ ''')'
			---mdo 2
			END
		if isnull(@ShiftName, '') <> ''
			BEGIN
			---mod 2

			SELECT @strShiftName = ' AND ( ShiftProductionDetails.Shift = N''' + @ShiftName+ ''')'
			---mod 2
			END
		SELECT @StrSql= ' UPDATE #CockpitData SET #CockpitData.Rejection = ISNULL(t.RejectionSUM,0) '
		SELECT @StrSql=@StrSql+ ' From '
		SELECT @StrSql=@StrSql+ '(Select ShiftProductionDetails.pDate as pDate ,Shift,MachineID,SUM(ShiftRejectionDetails.Rejection_Qty) as RejectionSum'
		SELECT @StrSql=@StrSql+ ' From ShiftProductionDetails Left Outer Join ShiftRejectionDetails ON'
		SELECT @StrSql=@StrSql+ ' ShiftProductionDetails.ID=ShiftRejectionDetails.ID'
		SELECT @StrSql=@StrSql+ ' WHERE ShiftProductionDetails.pDate >='''+ Convert(Nvarchar(20),@StartTime)+''''
		SELECT @StrSql=@StrSql+ ' AND ShiftProductionDetails.pDate <='''+ Convert(Nvarchar(20),@EndTime)+''''
		SELECT @StrSql=@StrSql + @strmachine + @strShiftName
		SELECT @StrSql=@StrSql +' GROUP by ShiftProductionDetails.pDate,ShiftProductionDetails.MachineID,ShiftProductionDetails.shift) as t '
		SELECT @StrSql=@StrSql +' inner join #CockpitData on #CockpitData.Pdt = t.pDate and #CockpitData.shftnm = t.shift and #CockpitData.machineid = t.machineID '
		
		Print (@StrSql)
		EXEC(@StrSql)		
		
END
	if @TimeAxis='Hour' AND @Type='Console'
	BEGIN
		SELECT	cast(cast(DateName(month,Pdt) as nvarchar(3))+ ' '+cast(datepart(dd,Pdt)as nvarchar(2))+ ' Shift-' +cast(shftnm as nvarchar(20)) as Nvarchar(50)) as Day,
		--cast(cast(DateName(month,pdate)as nvarchar(3))+'-'+cast(datepart(dd,Pdate)as nvarchar(2))+'-'+ cast(ShiftName as nvarchar(20))+' '+CASE WHEN DATALENGTH(Cast(datepart(hh,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,FromTime)as nvarchar(2)) ELSE cast(datepart(hh,FromTime)as nvarchar(2))END +':'+CASE WHEN DATALENGTH(Cast(datepart(n,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(n,FromTime)as nvarchar(2)) ELSE cast(datepart(n,FromTime)as nvarchar(2))END +' To '+CASE WHEN DATALENGTH(Cast(datepart(hh,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,ToTime)as nvarchar(2)) ELSE cast(datepart(hh,ToTime)as nvarchar(2))END+':'+CASE WHEN DATALENGTH(Cast(datepart(n,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(n,ToTime)as nvarchar(2)) ELSE cast(datepart(n,ToTime)as nvarchar(2))END  as nvarchar(50)) as Day,
		Cast(CAST(YEAR(Strttm)as nvarchar(4))+CAST(Month(Strttm)as nvarchar(2))+CAST(Day(Strttm)as nvarchar(2))+CASE WHEN DATALENGTH(Cast(datepart(hh,Strttm)as nvarchar))=2 THEN '0'+cast(datepart(hh,Strttm)as nvarchar(2)) ELSE cast(datepart(hh,Strttm)as nvarchar(2))END +':'+CASE WHEN DATALENGTH(Cast(datepart(n,Strttm)as nvarchar))=2 THEN '0'+cast(datepart(n,Strttm)as nvarchar(2)) ELSE cast(datepart(n,Strttm)as nvarchar(2))END+' To '+CASE WHEN DATALENGTH(Cast(datepart(hh,ndtim)as nvarchar))=2 THEN '0'+cast(datepart(hh,ndtim)as nvarchar(2)) ELSE cast(datepart(hh,ndtim)as nvarchar(2))END+':'+CASE WHEN DATALENGTH(Cast(datepart(n,ndtim)as nvarchar))=2 THEN '0'+cast(datepart(n,ndtim)as nvarchar(2)) ELSE cast(datepart(n,ndtim)as nvarchar(2))END  as NVarchar(50)) as Shift,
		Pdt,shftnm,Strttm,
		ndtim,	
		MachineID,AvailabilityEfficiency * 100 As AE,
		ProductionEfficiency * 100 As PE,
		(ProductionEfficiency * AvailabilityEfficiency)*100 As OE,
		Components		
		FROM #CockpitData Order by Machineid,Strttm
	END
	

if @TimeAxis='Day'AND @Type='Console' 
	BEGIN

	   SELECT	
	 
	   Strttm AS Shift,
	   --cast(cast(DateName(month,Pdt) as nvarchar(3))+ ' '+cast(datepart(dd,Pdt)as nvarchar(2)) as Nvarchar(50)) as Day,
	   Pdt,shftnm,Strttm,
	   ndtim,	
	   MachineID,(AvailabilityEfficiency * 100) As AE,
	   (ProductionEfficiency * 100) As PE,
		(QualityEfficiency * 100) As QualityEfficiency,
	   (ProductionEfficiency * AvailabilityEfficiency * QualityEfficiency)*100 As OE,
	   Components,[dbo].[f_FormatTime] (downtime,'hh:mm:ss') as downtime,turnOver,rejection
	   FROM #CockpitData Order by Machineid,Strttm
	END

if @TimeAxis='Shift' AND @Type='Console' and @daywise='order'

	BEGIN
		  SELECT
		  --cast(cast(DateName(month,Pdt) as nvarchar(3))+ ' '+cast(datepart(dd,Pdt)as nvarchar(2))+ ' Shift-' +cast(shftnm as nvarchar(20)) as Nvarchar(50)) as Day,
		 
		  cast('Shift-'+cast(shftnm as nvarchar(20))as nvarchar(50)) as Shift,
		  Pdt,shftnm,Strttm,ndtim,MachineID,
		  AvailabilityEfficiency * 100 As AE,
		  ProductionEfficiency * 100 As PE,
		  	(QualityEfficiency * 100) As QualityEfficiency,
			(ProductionEfficiency * AvailabilityEfficiency * QualityEfficiency)*100 As OE,
		  --(ProductionEfficiency * AvailabilityEfficiency)*100 As OE,
		  ---mod 3
		  --'OE' = CASE
		  --WHEN isnull(Components,0) <> 0 then (ProductionEfficiency * AvailabilityEfficiency*100) * ((Components - isnull(rejection,0))/Components)
		  --END,
--		  'OE' = isnull(CASE
--		  WHEN isnull(Components,0) <> 0 then (ProductionEfficiency * AvailabilityEfficiency*100) * ((Components - isnull(rejection,0))/Components)
--		  END,0),
		  ---mod 3
		  Components,TotalComp,[dbo].[f_FormatTime] (downtime,'hh:mm:ss') as downtime,operator
		  FROM #CockpitData Order by Strttm,[shift]
	END

if @TimeAxis='Shift' AND @Type='Console' 
	BEGIN
		  SELECT
		  --cast(cast(DateName(month,Pdt) as nvarchar(3))+ ' '+cast(datepart(dd,Pdt)as nvarchar(2))+ ' Shift-' +cast(shftnm as nvarchar(20)) as Nvarchar(50)) as Day,
		 
		  cast('Shift-'+cast(shftnm as nvarchar(20))as nvarchar(50)) as Shift,
		  Pdt,shftnm,Strttm,ndtim,MachineID,
		  AvailabilityEfficiency * 100 As AE,
		  ProductionEfficiency * 100 As PE,
		   	(QualityEfficiency * 100) As QualityEfficiency,
	   (ProductionEfficiency * AvailabilityEfficiency * QualityEfficiency)*100 As OE,
		  --(ProductionEfficiency * AvailabilityEfficiency)*100 As OE,
		  ---mod 3
		  --'OE' = CASE
		  --WHEN isnull(Components,0) <> 0 then (ProductionEfficiency * AvailabilityEfficiency*100) * ((Components - isnull(rejection,0))/Components)
		  --END,
--		  'OE' = isnull(CASE
--		  WHEN isnull(Components,0) <> 0 then (ProductionEfficiency * AvailabilityEfficiency*100) * ((Components - isnull(rejection,0))/Components)
--		  END,0),
		  ---mod 3
		  Components,TotalComp,[dbo].[f_FormatTime] (downtime,'hh:mm:ss') as downtime,operator
		  FROM #CockpitData Order by Machineid,Strttm
	END


	if  @TimeAxis='Month'AND @Type='Console'
	BEGIN
		SELECT	
		--cast(cast(DateName(month,Pdt) as nvarchar(3))+ ' '+cast(datepart(yyyy,Pdt)as nvarchar(4)) as Nvarchar(50)) as Day,
	
		Strttm AS Shift,
		Pdt,shftnm,Strttm,
		ndtim,	
		 MachineID,AvailabilityEfficiency * 100 As AE,
		ProductionEfficiency * 100 As PE,
			(QualityEfficiency * 100) As QualityEfficiency,
	   (ProductionEfficiency * AvailabilityEfficiency * QualityEfficiency)*100 As OE,
		Components,[dbo].[f_FormatTime] (downtime,'hh:mm:ss') as downtime,TurnOver,(MachineHourRate*(TotaldowntimeInt/3600))as [monthRevenueLoss],RejCount
		FROM #CockpitData Order by Machineid,Strttm
	END
	if @TimeAxis='Hour' AND @Type='Cockpit'
	BEGIN
		SELECT	
		
		--cast(cast(DateName(month,pdate)as nvarchar(3))+'-'+cast(datepart(dd,Pdate)as nvarchar(2))+'-'+ cast(ShiftName as nvarchar(20))+' '+CASE WHEN DATALENGTH(Cast(datepart(hh,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,FromTime)as nvarchar(2)) ELSE cast(datepart(hh,FromTime)as nvarchar(2))END +':'+CASE WHEN DATALENGTH(Cast(datepart(n,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(n,FromTime)as nvarchar(2)) ELSE cast(datepart(n,FromTime)as nvarchar(2))END +' To '+CASE WHEN DATALENGTH(Cast(datepart(hh,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,ToTime)as nvarchar(2)) ELSE cast(datepart(hh,ToTime)as nvarchar(2))END+':'+CASE WHEN DATALENGTH(Cast(datepart(n,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(n,ToTime)as nvarchar(2)) ELSE cast(datepart(n,ToTime)as nvarchar(2))END  as nvarchar(50)) as Day,
		Cast(CAST(YEAR(Strttm)as nvarchar(4))+CAST(Month(Strttm)as nvarchar(2))+CAST(Day(Strttm)as nvarchar(2))+CASE WHEN DATALENGTH(Cast(datepart(hh,Strttm)as nvarchar))=2 THEN '0'+cast(datepart(hh,Strttm)as nvarchar(2)) ELSE cast(datepart(hh,Strttm)as nvarchar(2))END +':'+CASE WHEN DATALENGTH(Cast(datepart(n,Strttm)as nvarchar))=2 THEN '0'+cast(datepart(n,Strttm)as nvarchar(2)) ELSE cast(datepart(n,Strttm)as nvarchar(2))END+' To '+CASE WHEN DATALENGTH(Cast(datepart(hh,ndtim)as nvarchar))=2 THEN '0'+cast(datepart(hh,ndtim)as nvarchar(2)) ELSE cast(datepart(hh,ndtim)as nvarchar(2))END+':'+CASE WHEN DATALENGTH(Cast(datepart(n,ndtim)as nvarchar))=2 THEN '0'+cast(datepart(n,ndtim)as nvarchar(2)) ELSE cast(datepart(n,ndtim)as nvarchar(2))END  as NVarchar(50)) as Shift,
		Pdt,shftnm,Strttm,
		ndtim,	
		MachineID,AvailabilityEfficiency * 100 As AE,
		ProductionEfficiency * 100 As PE,
		(ProductionEfficiency * AvailabilityEfficiency)*100 As OE,
		Components		
		FROM #CockpitData Order by Machineid,Strttm
	END
	if @TimeAxis='Shift' AND @Type='Cockpit'
	BEGIN
	   SELECT
	   cast(cast(DateName(month,Pdt) as nvarchar(3))+ ' '+cast(datepart(dd,Pdt)as nvarchar(2))+ ' Shift-' +cast(shftnm as nvarchar(20)) as Nvarchar(50)) as Day,
	   --cast(cast(DateName(month,Pdt) as nvarchar(3))+ ' '+cast(datepart(dd,Pdt)as nvarchar(2)) as Nvarchar(50)) as Day,	
	   'Shift-'+cast(shftnm as nvarchar(20)) as Shift,
	   Pdt,shftnm,Strttm,ndtim,MachineID,
	   AvailabilityEfficiency * 100 As AE,
	   ProductionEfficiency * 100 As PE,
	   --(ProductionEfficiency * AvailabilityEfficiency)*100 As OE,
	   ---mod 3
	   --'OE' = CASE
	   --WHEN isnull(Components,0) <> 0 then (ProductionEfficiency * AvailabilityEfficiency*100) * ((Components - isnull(rejection,0))/Components)
	   --END,
	   'OE' = isnull(CASE
	   WHEN isnull(Components,0) <> 0 then (ProductionEfficiency * AvailabilityEfficiency*100) * ((Components - isnull(rejection,0))/Components)
	   END,0),
	   ---mod 3
	   Components,Rejection
	   FROM #CockpitData Order by Machineid,Strttm
	END
	if @TimeAxis='Day' AND @Type='Cockpit'
	BEGIN
		SELECT	
		--cast(cast(DateName(month,Pdt) as nvarchar(3))+ ' '+cast(datepart(yyyy,Pdt)as nvarchar(4)) as Nvarchar(50)) as Day,
		cast(cast(DateName(month,Pdt) as nvarchar(3))+ ' '+cast(datepart(dd,Pdt)as nvarchar(2)) as Nvarchar(50)) as Day,
		Pdt,shftnm,Strttm,
		ndtim,	
		 MachineID,AvailabilityEfficiency * 100 As AE,
		ProductionEfficiency * 100 As PE,
		(ProductionEfficiency * AvailabilityEfficiency)*100 As OE,

		Components	
		FROM #CockpitData Order by Machineid,Strttm

	END
	if  @TimeAxis='Month' AND @Type='Cockpit'
	BEGIN
		SELECT	
		cast(cast(DateName(month,Pdt) as nvarchar(3))+ ' '+cast(datepart(yyyy,Pdt)as nvarchar(4)) as Nvarchar(50)) as Day,
		--cast(Datepart(yyyy,pdt)as nvarchar(50)) As Day,
		Pdt,shftnm,Strttm,
		ndtim,	
		 MachineID,AvailabilityEfficiency * 100 As AE,
		ProductionEfficiency * 100 As PE,
		(ProductionEfficiency * AvailabilityEfficiency)*100 As OE,
		Components,[dbo].[f_FormatTime] (downtime,'hh:mm:ss') as downtime		
		FROM #CockpitData Order by Machineid,Strttm
	END
END
