/****** Object:  Procedure [dbo].[s_GetEfficiencyFromAutodataForMultipleMachines]    Committed by VersionSQL https://www.versionsql.com ******/

/********************************************************************************************************
NR0115-Vasavi-05/Jun/2015::i).To calculate AE,PE,OEE for multiple machines.
ii)To get Operators working in each shift. 
s_GetEfficiencyFromAutodata_Vasavi '2013-12-02','2013-12-03','CT-23,CT-24','','OEE','Shift','','Console'
*******************************************************************************************************/

CREATE PROCEDURE [dbo].[s_GetEfficiencyFromAutodataForMultipleMachines]
	@StartTime datetime ,
	@EndTime datetime ,
	@MachineID nvarchar(50) = '',
	@PlantID nvarchar(50)='',
	@ComparisonParam as nvarchar(20),
	@TimeAxis as nvarchar(20), --'Month','Day','Shift','Hour'
	@ShiftName as nvarchar(20)='',
	@Type as NVarchar(20)='Console'--'Console','Cockpit',we need different output based on the requirement.
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SET ARITHABORT ON
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
Create Table #opr
	(
		opr nvarchar(4000),
		shiftnm nvarchar(20) null,
		machine nvarchar(50),
		Strttm datetime
		
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
	MachineID nvarchar(50),
	MachineInterface nvarchar(50) ,
	ProductionEfficiency float,
	AvailabilityEfficiency float,
	OverallEfficiency float,
	Components float,
	UtilisedTime float,
	ManagementLoss float,
	DownTime float,
	CN float,
	Rejection float
	--mod 4
	,MLDown float,
	operator nvarchar(1000)
	--mod 4
--CONSTRAINT CockpitData1_key PRIMARY KEY (machineinterface)
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
--if isnull(@machineid,'')<> ''
--begin
--	---mod 2
----	SET @strMachine = ' AND MachineInformation.MachineID = ''' + @machineid + ''''
----	SET @strXMachine = ' AND EX.MachineID = ''' + @machineid + ''''
--	SET @strMachine = ' AND MachineInformation.MachineID = N''' + @machineid + ''''
--	SET @strXMachine = ' AND EX.MachineID = N''' + @machineid + ''''
--	---mod 2
--end

create table #machines
( Machine nvarchar(50)
)


if isnull(@machineid,'') <> ''
begin
	
	--SELECT @strmachine = ' and ( machineinformation.MachineID = N''' + @MachineID + ''')'
	insert into #machines(machine)
	exec dbo.Split @machineid, ','


end
if isnull(@PlantID,'')<>''
Begin
	---mod 2
--	SET @strPlantID =  ' AND PlantMachine.PlantID = ''' + @PlantID + ''''
	SET @strPlantID =  ' AND PlantMachine.PlantID = N''' + @PlantID + ''''
	---mod 2
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
		select @Counter,'ALL',dbo.f_GetLogicalDay(@Counter,'start'),dbo.f_GetLogicalDay(@Counter,'end')
		SELECT @counter = Dateadd(Day,1,@counter)
	end
end
if @TimeAxis='Month'
begin
	Delete from #ShiftTemp
	While(@counter <= @EndTime)
	begin
		insert into #ShiftTemp(Pdate,ShiftName,FromTime,ToTime)
		select @Counter,'ALL',dbo.f_GetLogicalMonth(@Counter,'start'),dbo.f_GetLogicalMonth(@Counter,'end')
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
			CN,
			Rejection,
			operator
					) '
			SET @strSql = @strSql + ' SELECT S.Pdate,S.FromTime,S.ToTime,S.ShiftName,MachineInformation.MachineID, MachineInformation.interfaceid ,0,0,0,0,0,0,0,0,0,0 FROM MachineInformation
						  INNER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID
						  cross join #ShiftTemp S whERE  machineinformation.machineid in (select machine from #machines) and  MachineInformation.interfaceid > ''0''  '
			SET @strSql = @strSql + @strPlantID 
			EXEC(@strSql)


insert into #opr
select  employeeinformation.Employeeid as opr,#CockpitData.shftnm,#CockpitData.machineID,#CockpitData.Strttm as machine
from autodata inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface INNER JOIN
employeeinformation ON    employeeinformation.interfaceid=autodata.opr 
where (autodata.datatype=1 OR autodata.datatype=2 )
AND(( (autodata.msttime>=#CockpitData.Strttm) and (autodata.ndtime<=#CockpitData.ndtim))
OR ((autodata.msttime<#CockpitData.Strttm)and (autodata.ndtime>#CockpitData.Strttm)and (autodata.ndtime<=#CockpitData.ndtim))
OR ((autodata.msttime>=#CockpitData.Strttm)and (autodata.msttime<#CockpitData.ndtim)and (autodata.ndtime>#CockpitData.ndtim))
OR((autodata.msttime<#CockpitData.Strttm)and (autodata.ndtime>#CockpitData.ndtim))) and #CockpitData.machineID in (select machine from #machines)
group by #CockpitData.machineID,employeeinformation.Employeeid,#CockpitData.shftnm,#CockpitData.Strttm

UPDATE #CockpitData SET Operator = t2.opr 
from(
SELECT t.shiftnm,t.machine ,t.Strttm,
       STUFF(ISNULL((SELECT ', ' + x.opr
                FROM #opr x
               WHERE x.shiftnm = t.shiftnm and x.machine = t.machine and x.Strttm=t.strttm
            GROUP BY x.opr
             FOR XML PATH (''), TYPE).value('.','VARCHAR(max)'), ''), 1, 2, '') [opr]      
  FROM #opr t)
as t2 inner join #CockpitData on t2.shiftnm = #CockpitData.shftnm and t2.machine =#CockPitData .MachineID and t2.Strttm = #CockpitData.Strttm	

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
	AND (autodata.sttime  <  T.Dend))
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
---mod 4
/*UPDATE #CockpitData SET UtilisedTime =  isNull(t2.cycle,0)
from
(select     #ShiftTemp.Fromtime as intime, mc,
sum(case when ( (autodata.msttime>= #ShiftTemp.Fromtime) and (autodata.ndtime<=#ShiftTemp.Totime)) then  (cycletime+loadunload)
		 when ((autodata.msttime< #ShiftTemp.Fromtime)and (autodata.ndtime> #ShiftTemp.Fromtime)and (autodata.ndtime<=#ShiftTemp.Totime)) then DateDiff(second,  #ShiftTemp.Fromtime, ndtime)
		 when ((autodata.msttime>= #ShiftTemp.Fromtime)and (autodata.msttime<#ShiftTemp.Totime)and (autodata.ndtime>#ShiftTemp.Totime)) then DateDiff(second, mstTime, #ShiftTemp.Totime)
		 when ((autodata.msttime< #ShiftTemp.Fromtime)and (autodata.ndtime>#ShiftTemp.Totime)) then DateDiff(second,  #ShiftTemp.Fromtime, #ShiftTemp.Totime) END ) as  cycle
from autodata cross join #ShiftTemp
where (autodata.datatype=1)
AND(( (autodata.msttime>=#ShiftTemp.Fromtime) and (autodata.ndtime<=#ShiftTemp.Totime))
OR ((autodata.msttime<#ShiftTemp.Fromtime)and (autodata.ndtime>#ShiftTemp.Fromtime)and (autodata.ndtime<=#ShiftTemp.Totime))
OR ((autodata.msttime>=#ShiftTemp.Fromtime)and (autodata.msttime<#ShiftTemp.Totime)and (autodata.ndtime>#ShiftTemp.Totime))
OR((autodata.msttime<#ShiftTemp.Fromtime)and (autodata.ndtime>#ShiftTemp.Totime))
)
AND autodata.mc in (select distinct MachineInterface from #CockpitData )
group by autodata.mc,#ShiftTemp.Fromtime
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
*/
/*UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
from
(select     #CockpitData.Strttm as intime, mc,sum(cycletime+loadunload) as cycle
from autodata inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface
where (autodata.msttime>=#CockpitData.Strttm)
and (autodata.ndtime<=#CockpitData.ndtim)
and (autodata.datatype=1)
group by autodata.mc,#CockpitData.Strttm
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
-- Type 2
UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
from
(select #CockpitData.Strttm as intime, mc,SUM(DateDiff(second, #CockpitData.Strttm, ndtime)) cycle
from autodata inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface
where (autodata.msttime<#CockpitData.Strttm)
and (autodata.ndtime>#CockpitData.Strttm)
and (autodata.ndtime<=#CockpitData.ndtim)
and (autodata.datatype=1)
group by autodata.mc,#CockpitData.Strttm
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
-- Type 3
UPDATE  #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
from
(select #CockpitData.Strttm as intime, mc,sum(DateDiff(second, stTime, #CockpitData.ndtim)) cycle
from autodata inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface
where (autodata.msttime>=#CockpitData.Strttm)
and (autodata.msttime<#CockpitData.ndtim)
and (autodata.ndtime>#CockpitData.ndtim)
and (autodata.datatype=1)
group by autodata.mc,#CockpitData.Strttm
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
-- Type 4
UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) + isnull(t2.cycle,0)
from
(select  #CockpitData.Strttm as intime,mc,
sum(DateDiff(second, #CockpitData.Strttm, #CockpitData.ndtim)) cycle
from autodata inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface
where (autodata.msttime<#CockpitData.Strttm)
and (autodata.ndtime>#CockpitData.ndtim)
and (autodata.datatype=1)
group by autodata.mc,#CockpitData.Strttm
)as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
*/
--ICD for Type 2 prod record
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
---mod 6
--	When autodata.sttime < T1.DurStrt AND autodata.ndtime<=T1.DurEnd Then datediff(s, T1.DurStrt,autodata.ndtime )
--	When autodata.ndtime >= T1.DurEnd AND autodata.sttime>T1.DurStrt Then datediff(s,autodata.sttime, T1.DurEnd )
--	When autodata.sttime >= T1.DurStrt AND autodata.ndtime <= T1.DurEnd Then datediff(s , autodata.sttime,autodata.ndtime)
--	When autodata.sttime<T1.DurStrt AND autodata.ndtime>T1.DurEnd   Then datediff(s , T1.DurStrt,T1.DurEnd)
	When autodata.sttime >= T1.DurStrt AND autodata.ndtime <= T1.DurEnd Then datediff(s , autodata.sttime,autodata.ndtime)
	When autodata.sttime < T1.DurStrt AND autodata.ndtime<=T1.DurEnd and autodata.ndtime > T1.DurStrt Then datediff(s, T1.DurStrt,autodata.ndtime )
	When autodata.sttime>=T1.DurStrt and autodata.ndtime >T1.DurEnd AND autodata.sttime<T1.DurEnd  Then datediff(s,autodata.sttime, T1.DurEnd )
	When autodata.sttime<T1.DurStrt AND autodata.ndtime>T1.DurEnd   Then datediff(s , T1.DurStrt,T1.DurEnd)
---mod 6
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
CEILING (sum(CAST((autodata.partscount) AS Float)/ISNULL(componentoperationpricing.SubOperations,1))) as pcount
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
		CEILING (sum(CAST((A.partscount) AS Float)/ISNULL(O.SubOperations,1))) as PlanCt
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
			Where (autodata.ndtime>Tt1.StartTime) AND (autodata.ndtime<=Tt1.EndTime) and (autodata.datatype=1) and autodata.mc in (select machine from #machines)  '
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
--Apply Exception on Count..
UPDATE #CockpitData SET components = ISNULL(components,0) - ISNULL(t2.comp,0)
from
( select DurStart as intime,MachineID,SUM(ExCount) as comp
	From #Exceptions GROUP BY MachineID,DurStart ) as T2
Inner join #CockpitData on T2.MachineID = #CockpitData.MachineID
and t2.intime=#CockpitData.Strttm
--mod 4(5):Optimization
/* mod 4(5) if @TimeAxis='Day' or @TimeAxis='Shift' or @TimeAxis='Month' or @TimeAxis='Hour'
BEGIN
	DECLARE @TmpPdate AS DATETIME
	DECLARE @TmpShiftName AS nvarchar(50)
	DECLARE EffiRptCursor  Cursor  For
		SELECT Pdate,ShiftName,FromTime,ToTime From #ShiftTemp
		Open EffiRptCursor
		FETCH NExt From EffiRptCursor into @TmpPdate,@TmpShiftName,@CurStarttime,@CurEndtime
		While(@@Fetch_Status=0)
		BEGIN
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
			CN,
			Rejection
					) '
			SET @strSql = @strSql + ' SELECT '''+convert(nvarchar(20),@TmpPdate)+''','''+convert(nvarchar(20),@curstarttime)+''','''+convert(nvarchar(20),@curendtime)+''','''+convert(nvarchar(50),@TmpShiftName)+''',MachineInformation.MachineID, MachineInformation.interfaceid ,0,0,0,0,0,0,0,0,0 FROM MachineInformation
						  INNER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID WHERE MachineInformation.interfaceid > ''0''  '
			SET @strSql = @strSql + @strPlantID + @strMachine
			--EXEC(@strSql)
			
			--update #Cockpitdata set shftnm=@TmpShiftName where Strttm=@CurStarttime and ndtim=@CurEndtime
	mod 4(5)*/		
/**************************************************************************************************************/
/* 			FOLLOWING SECTION IS ADDED BY SANGEETA KALLUR					*/
/* mod 4 (5) SELECT @StrSql = 'INSERT INTO #Exceptions(MachineID ,ComponentID,OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,ExCount )
		SELECT Ex.MachineID ,Ex.ComponentID,Ex.OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,0
		From ProductionCountException Ex
		Inner Join MachineInformation M ON Ex.MachineID=M.MachineID
		Inner Join ComponentInformation C ON Ex.ComponentID=C.ComponentID
		Inner Join Componentoperationpricing O ON Ex.OperationNo=O.OperationNo AND C.ComponentID=O.ComponentID '
---mod 1
SELECT @StrSql = @StrSql+ ' and Ex.machineid=O.machineid '
---mod 1
SELECT @StrSql = @StrSql+ ' WHERE  M.MultiSpindleFlag=1 '
SELECT @StrSql =@StrSql + @strXMachine
SELECT @StrSql =@StrSql +'AND ((Ex.StartTime>=  ''' + convert(nvarchar(20),@CurStarttime)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@CurEndtime)+''' )
		OR (Ex.StartTime< ''' + convert(nvarchar(20),@CurStarttime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@CurStarttime)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@CurEndtime)+''')
		OR(Ex.StartTime>= ''' + convert(nvarchar(20),@CurStarttime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@CurEndtime)+''' AND Ex.StartTime< ''' + convert(nvarchar(20),@CurEndtime)+''')
		OR(Ex.StartTime< ''' + convert(nvarchar(20),@CurStarttime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@CurEndtime)+''' ))'
Exec (@strsql)
IF ( SELECT Count(*) from #Exceptions ) <> 0
BEGIN
	UPDATE #Exceptions SET StartTime=@CurStarttime WHERE (StartTime<@CurStarttime)AND EndTime>@CurStarttime
	UPDATE #Exceptions SET EndTime=@CurEndtime WHERE (EndTime>@CurEndtime AND StartTime<@CurEndtime )
	Select @StrSql = 'UPDATE #Exceptions SET ExCount=ISNULL(T2.Comp,0) From
	(
		SELECT T1.MachineID AS MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime AS StartTime,T1.EndTime AS EndTime,
		SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp
	 	From (
			select MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,comp,opn,Tt1.StartTime,Tt1.EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from autodata
			Inner Join MachineInformation   ON autodata.MC=MachineInformation.InterfaceID
			Inner Join EmployeeInformation E  ON autodata.Opr=E.InterfaceID
			Inner Join ComponentInformation  ON autodata.Comp = ComponentInformation.InterfaceID
			Inner Join ComponentOperationPricing on autodata.Opn=ComponentOperationPricing.InterfaceID And ComponentInformation.ComponentID=ComponentOperationPricing.ComponentID '
	---mod 1
	SELECT @StrSql =@StrSql + ' and MachineInformation.machineid=ComponentOperationPricing.machineid '
	---mod 1
	SELECT @StrSql =@StrSql +' Inner Join (
				Select MachineID,ComponentID,OperationNo,StartTime,EndTime From #Exceptions
			)AS Tt1 ON Tt1.MachineID=MachineInformation.MachineID AND Tt1.ComponentID = ComponentInformation.ComponentID AND Tt1.OperationNo= ComponentOperationPricing.OperationNo
			Where (autodata.ndtime>Tt1.StartTime) AND (autodata.ndtime<=Tt1.EndTime) and (autodata.datatype=1) '
	Select @StrSql = @StrSql+ @strMachine
	Select @StrSql = @StrSql+' Group by MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,Tt1.StartTime,Tt1.EndTime,comp,opn
		) as T1
	   	Inner join componentinformation C on T1.Comp=C.interfaceid
	   	Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid '
	---mod 1
	Select @StrSql = @StrSql+' Inner join machineinformation M on T1.MachineID=M.machineid '
	---mod 1
	Select @StrSql = @StrSql+' GROUP BY T1.MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime,t1.EndTime
	)AS T2
	WHERE  #Exceptions.StartTime=T2.StartTime AND #Exceptions.EndTime=T2.EndTime
	AND #Exceptions.MachineID=T2.MachineID AND #Exceptions.ComponentID = T2.ComponentID AND #Exceptions.OperationNo=T2.OperationNo'
	Exec(@StrSql)
	UPDATE #Exceptions SET ExCount=ExCount-((ExCount * ActualCount)/ISNULL(IdealCount,0))
	
END mod 4(5) */
/**************************************************************************************************************/
	
-- Type 1
/* Commented for mod 4(5) UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
from
(select     @CurStarttime as intime, mc,sum(cycletime+loadunload) as cycle
from autodata
where (autodata.msttime>=@CurStarttime)
and (autodata.ndtime<=@curendtime)
and (autodata.datatype=1)
group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
-- Type 2
UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
from
(select @CurStarttime as intime, mc,SUM(DateDiff(second, @CurStarttime, ndtime)) cycle
from autodata
where (autodata.msttime<@CurStarttime)
and (autodata.ndtime>@CurStarttime)
and (autodata.ndtime<=@curendtime)
and (autodata.datatype=1)
group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
-- Type 3
UPDATE  #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
from
(select @CurStarttime as intime, mc,sum(DateDiff(second, stTime, @curendtime)) cycle
from autodata
where (autodata.msttime>=@CurStarttime)
and (autodata.msttime<@curendtime)
and (autodata.ndtime>@curendtime)
and (autodata.datatype=1)
group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
-- Type 4
UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) + isnull(t2.cycle,0)
from
(select  @CurStarttime as intime,mc,
sum(DateDiff(second, @CurStarttime, @curendtime)) cycle
from autodata
where (autodata.msttime<@CurStarttime)
and (autodata.ndtime>@curendtime)
and (autodata.datatype=1)
group by autodata.mc
)as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm  Commented for mod 4(5) */
/* Fetching Down Records from Production Cycle  */
/* If Down Records of TYPE-2*/
/*UPDATE  #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
FROM
(Select @CurStarttime as intime,AutoData.mc ,
SUM(
CASE
	When autodata.sttime <= @CurStarttime Then datediff(s, @CurStarttime,autodata.ndtime )
	When autodata.sttime > @CurStarttime Then datediff(s , autodata.sttime,autodata.ndtime)
END)  as Down
From AutoData INNER Join
	(Select mc,Sttime,NdTime From AutoData
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(msttime < @CurStarttime)And (ndtime > @CurStarttime) AND (ndtime <= @curendtime)) as T1
ON AutoData.mc=T1.mc
Where AutoData.DataType=2
And ( autodata.Sttime > T1.Sttime )
And ( autodata.ndtime <  T1.ndtime )
AND ( autodata.ndtime >  @CurStarttime )
GROUP BY AUTODATA.mc)AS T2 Inner Join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
	*/		
/* If Down Records of TYPE-3*/
/*UPDATE  #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
FROM
(Select @CurStarttime as intime,AutoData.mc ,
SUM(CASE
	When autodata.ndtime > @curendtime Then datediff(s,autodata.sttime, @curendtime )
	When autodata.ndtime <=@curendtime Then datediff(s , autodata.sttime,autodata.ndtime)
END) as Down
From AutoData INNER Join
	(Select mc,Sttime,NdTime From AutoData
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(sttime >= @CurStarttime)And (ndtime > @curendtime) and sttime<@curendtime ) as T1
ON AutoData.mc=T1.mc
Where AutoData.DataType=2
And (T1.Sttime < autodata.sttime  )
And ( T1.ndtime >  autodata.ndtime)
AND (autodata.sttime  <  @curendtime)
GROUP BY AUTODATA.mc)AS T2 Inner Join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm */
/* If Down Records of TYPE-4*/
/*UPDATE  #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
FROM
(Select @CurStarttime as intime, AutoData.mc ,
SUM(CASE
	When autodata.sttime < @CurStarttime AND autodata.ndtime<=@curendtime Then datediff(s, @CurStarttime,autodata.ndtime )
	When autodata.ndtime >= @curendtime AND autodata.sttime>@CurStarttime Then datediff(s,autodata.sttime, @curendtime )
	When autodata.sttime >= @CurStarttime AND
	     autodata.ndtime <= @curendtime Then datediff(s , autodata.sttime,autodata.ndtime)
	When autodata.sttime<@CurStarttime AND autodata.ndtime>@curendtime   Then datediff(s , @CurStarttime,@curendtime)
END) as Down
From AutoData INNER Join
	(Select mc,Sttime,NdTime From AutoData
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(msttime < @CurStarttime)And (ndtime > @curendtime) ) as T1
ON AutoData.mc=T1.mc
Where AutoData.DataType=2
And (T1.Sttime < autodata.sttime  )
And ( T1.ndtime >  autodata.ndtime)
AND (autodata.ndtime  >  @CurStarttime)
AND (autodata.sttime  <  @curendtime)
GROUP BY AUTODATA.mc
)AS T2 Inner Join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm*/
/*******************************Down Record***********************************/
--ManagementLoss
-- Type 1
/*UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
from
(select @CurStarttime as intime,mc,sum(
CASE
WHEN (loadunload) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
THEN isnull(downcodeinformation.Threshold,0)
ELSE loadunload
END) AS LOSS
from autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
where (autodata.msttime>=@CurStarttime)
and (autodata.ndtime<=@curendtime)
and (autodata.datatype=2)
and (downcodeinformation.availeffy = 1)
group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
			
-- Type 2
UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
from
(select    @CurStarttime as intime, mc,sum(
CASE WHEN DateDiff(second, @CurStarttime, ndtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
then isnull(downcodeinformation.Threshold,0)
ELSE DateDiff(second, @CurStarttime, ndtime)
END)loss
--DateDiff(second, @CurStarttime, ndtime)
from autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
where (autodata.sttime<@CurStarttime)
and (autodata.ndtime>@CurStarttime)
and (autodata.ndtime<=@curendtime)
and (autodata.datatype=2)
and (downcodeinformation.availeffy = 1)
group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
			
-- Type 3
UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
from
(select   @CurStarttime as intime, mc,SUM(
CASE WHEN DateDiff(second,stTime, @curendtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
then isnull(downcodeinformation.Threshold,0)
ELSE DateDiff(second, stTime, @curendtime)
END)loss
-- sum(DateDiff(second, stTime, @curendtime)) loss
from autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
where (autodata.msttime>=@CurStarttime)
and (autodata.sttime<@curendtime)
and (autodata.ndtime>@curendtime)
and (autodata.datatype=2)
and (downcodeinformation.availeffy = 1)
group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
-- Type 4
			
UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
from
(select @CurStarttime as intime, mc,sum(
CASE WHEN DateDiff(second, @CurStarttime, @curendtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
then isnull(downcodeinformation.Threshold,0)
ELSE DateDiff(second, @CurStarttime, @curendtime)
END)loss
--sum(DateDiff(second, @CurStarttime, @curendtime)) loss
from autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
where autodata.msttime<@CurStarttime
and autodata.ndtime>@curendtime
and (autodata.datatype=2)
and (downcodeinformation.availeffy = 1)
group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
	*/		
			-- Get the value of CN
-- Type 1
/* Changed by SSK to Combine SubOperations
*/
/*UPDATE #CockpitData SET CN = isnull(CN,0) + isNull(t2.C1N1,0)
from
(select @CurStarttime as intime,mc,
--SUM(componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1)) C1N1
SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))*autodata.partscount) C1N1
FROM autodata INNER JOIN
componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID AND
componentoperationpricing.componentid = componentinformation.componentid
---mod 1
inner join machineinformation on machineinformation.interfaceid=autodata.mc
and componentoperationpricing.machineid=machineinformation.machineid
---mod 1
where (autodata.sttime>=@CurStarttime)
and (autodata.ndtime<=@curendtime)
and (autodata.datatype=1)
group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
-- Type 2
UPDATE #CockpitData SET CN = isnull(CN,0) + isNull(t2.C1N1,0)
from
(select @CurStarttime as intime, mc,
SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))*autodata.partscount) C1N1			
FROM autodata INNER JOIN
componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID AND
componentoperationpricing.componentid = componentinformation.componentid
---mod 1
inner join machineinformation on machineinformation.interfaceid=autodata.mc
and componentoperationpricing.machineid=machineinformation.machineid
---mod 1
where (autodata.sttime<@CurStarttime)
and (autodata.ndtime>@CurStarttime)
and (autodata.ndtime<=@curendtime)
and (autodata.datatype=1)
group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
	*/	
/*			
-- Get the Number of Components
-- Type 1
UPDATE #CockpitData SET components = ISNULL(components,0) + ISNULL(t2.comp,0)
From
(
Select @CurStarttime as intime,mc,SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp
	   From (select mc,sum(autodata.partscount)AS OrginalCount,comp,opn from autodata
	   where (autodata.sttime>=@CurStarttime) and (autodata.ndtime<=@curendtime) and (autodata.datatype=1)
	   Group By mc,comp,opn) as T1
Inner join componentinformation C on T1.Comp = C.interfaceid
Inner join ComponentOperationPricing O ON  T1.Opn = O.interfaceid and C.Componentid=O.componentid
GROUP BY mc
) As T2 Inner join #CockpitData on T2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
UPDATE #CockpitData SET components = ISNULL(components,0) + ISNULL(t2.comp,0)
from
( select  @CurStarttime as intime,mc,SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp
	From (select mc,sum(autodata.partscount) AS OrginalCount,comp,opn from autodata
	Where (autodata.sttime<@CurStarttime) and (autodata.ndtime>@CurStarttime) and (autodata.ndtime<=@curendtime) and (autodata.datatype=1)
	Group by mc,comp,opn) as T1
Inner join componentinformation C on T1.Comp=C.interfaceid
Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid
GROUP BY MC
) as T2 inner join #CockpitData on T2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
*/
/*********************************************************************************************************************/
			/* FOLLOWING CODE IS ADDED BY SANGEETA KALLUR */
/* mod 4(5) SELECT @StrSql = 'INSERT INTO #MCO_pCounts(StTime, MachineID ,ComponentID ,OperationNo , pCount,CycleTime )
	SELECT ''' + Convert(Nvarchar(20),@CurStarttime) + ''',MachineInformation.MachineID  ,C.ComponentID,O.OperationNo ,
	CEILING (CAST(SUM(A.partscount) AS Float)/ISNULL(O.SubOperations,1)) ,O.CycleTime
	From Autodata A
	Inner Join MachineInformation  ON A.Mc=MachineInformation.interfaceid
	Inner join componentinformation C on A.Comp=C.interfaceid
	Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid and C.Componentid=O.componentid '
---mod 1
SELECT @StrSql = @StrSql + ' and MachineInformation.machineid = O.machineid '
---mod 1
SELECT @StrSql = @StrSql + ' Where (A.datatype=1)AND (A.ndtime> ''' + Convert(Nvarchar(20),@CurStarttime) + '''  and A.ndtime<='''+Convert(NVarChar(20),@CurEndtime)+''')  '
SELECT @StrSql = @StrSql + @strMachine
SELECT @StrSql = @StrSql + 'Group by MachineInformation.MachineID,C.ComponentID,O.OperationNo,O.SubOperations,O.CycleTime'
Exec (@StrSql)
UPDATE #MCO_pCounts SET pCount=ISNULL(Tt.OpnCount,0)
FROM
(
	SELECT #MCO_pCounts.MachineID,#MCO_pCounts.Componentid,#MCO_pCounts.OperationNo,ISNULL(SUM(pCount),0)-ISNULL(Sum(Ti.ExCount),0) AS OpnCount
	FROM #MCO_pCounts Inner Join
		(
			SELECT MachineID,Componentid,OperationNo,SUM(ExCount)ExCount
			FROM #Exceptions Group By  MachineID,Componentid,OperationNo
		)As Ti ON #MCO_pCounts.MachineID = Ti.MachineID AND #MCO_pCounts.Componentid=Ti.Componentid AND #MCO_pCounts.OperationNo=Ti.OperationNo
	Group By  #MCO_pCounts.MachineID,#MCO_pCounts.Componentid,#MCO_pCounts.OperationNo
)AS Tt InneR Join #MCO_pCounts ON #MCO_pCounts.MachineID=Tt.MachineID AND #MCO_pCounts.Componentid=Tt.Componentid AND #MCO_pCounts.OperationNo=Tt.OperationNo
UPDATE #CockpitData SET Components = ISNULL(Tt.OCount,0)
FROM
(
	SELECT Max(StTime)StTime,MachineID,Sum(pCount)As OCount   From #MCO_pCounts GROUP BY MachineID
) AS Tt Inner Join #CockpitData ON #CockpitData.MachineID=Tt.MachineID AND Tt.StTime = #CockpitData.Strttm mod 4(5) */
/*
UPDATE #CockpitData SET CN = ISNULL(Tt.C1N1,0)
FROM
(
	SELECT Max(StTime)StTime,MachineID,SUM(CNi)C1N1  From
		(
			SELECT StTime,MachineID ,ISNULL(pCount*CycleTime,0)AS CNi FROM  #MCO_pCounts
		) AS Ti
	GROUP BY MachineID
)AS Tt Inner Join #CockpitData ON #CockpitData.MachineID=Tt.MachineID AND Tt.StTime = #CockpitData.Strttm
*/
/*********************************************************************************************************************/			
-- Get the down time.0
-- Type 1
/*UPDATE #CockpitData SET downtime = isnull(downtime,0) + isNull(t2.down,0)
from
(select  @CurStarttime as intime, mc,
	sum(loadunload) down
from autodata
where (autodata.msttime>=@CurStarttime)
and (autodata.ndtime<=@curendtime)
and (autodata.datatype=2)
group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
-- Type 2
UPDATE #CockpitData SET downtime = isnull(downtime,0) + isNull(t2.down,0)
from
(select   @CurStarttime as intime,mc,
	sum(DateDiff(second, @CurStarttime, ndtime)) down
from autodata
where (autodata.sttime<@CurStarttime)
and (autodata.ndtime>@CurStarttime)
and (autodata.ndtime<=@curendtime)
and (autodata.datatype=2)
group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
-- Type 3
UPDATE #CockpitData SET downtime = isnull(downtime,0) + isNull(t2.down,0)
from
(select  @CurStarttime as intime, mc,
	sum(DateDiff(second, stTime, @curendtime)) down
from autodata
where (autodata.msttime>=@CurStarttime)
and (autodata.sttime<@curendtime)
and (autodata.ndtime>@curendtime)
and (autodata.datatype=2)group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
-- Type 4
UPDATE #CockpitData SET downtime = isnull(downtime,0) + isNull(t2.down,0)
from
(select  @CurStarttime as intime,mc,
	sum(DateDiff(second, @CurStarttime, @curendtime)) down
from autodata
where autodata.msttime<@CurStarttime
and autodata.ndtime>@curendtime
and (autodata.datatype=2)
group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
*/	
/*mod 4(5) DELETE FROM #MCO_pCounts
DELETE FROM #Exceptions
	
FETCH NExt From EffiRptCursor into @TmpPdate,@TmpShiftName,@curstarttime,@curendtime			
END
END mod 4(5)*/
UPDATE #CockpitData
		SET
			ProductionEfficiency = (CN/UtilisedTime) ,
			AvailabilityEfficiency = (UtilisedTime)/(UtilisedTime + DownTime - ManagementLoss)
			
		WHERE UtilisedTime <> 0
if @TimeAxis='Shift'
BEGIN
	DECLARE @strShiftName  nvarchar(200)
	Declare @Machine as nvarchar(200)
		SET @strShiftName = ''
		SET @strmachine = ''
--		if isnull(@Machine,'') <> ''
--			BEGIN
--			---mod 2
----			SELECT @strmachine = ' AND ( ShiftProductionDetails.machineid = ''' + @Machine+ ''')'
--			SELECT @strmachine = ' AND ( ShiftProductionDetails.machineid = N''' + @Machine+ ''')'
--			---mdo 2
--			END
		if isnull(@ShiftName, '') <> ''
			BEGIN
			---mod 2
--			SELECT @strShiftName = ' AND ( ShiftProductionDetails.Shift = ''' + @ShiftName+ ''')'
			SELECT @strShiftName = ' AND ( ShiftProductionDetails.Shift = N''' + @ShiftName+ ''')'
			---mod 2
			END
		SELECT @StrSql= ' UPDATE #CockpitData SET #CockpitData.Rejection = ISNULL(t.RejectionSUM,0) '
		SELECT @StrSql=@StrSql+ ' From '
		SELECT @StrSql=@StrSql+ '(Select ShiftProductionDetails.pDate as pDate ,Shift,MachineID,SUM(ShiftRejectionDetails.Rejection_Qty) as RejectionSum'
		SELECT @StrSql=@StrSql+ ' From ShiftProductionDetails Left Outer Join ShiftRejectionDetails ON'
		SELECT @StrSql=@StrSql+ ' ShiftProductionDetails.ID=ShiftRejectionDetails.ID'
		SELECT @StrSql=@StrSql+ ' WHERE ShiftProductionDetails.machineid in (select machine from #machines) and ShiftProductionDetails.pDate >='''+ Convert(Nvarchar(20),@StartTime)+''''
		SELECT @StrSql=@StrSql+ ' AND ShiftProductionDetails.pDate <='''+ Convert(Nvarchar(20),@EndTime)+''''
		SELECT @StrSql=@StrSql + @strShiftName
		SELECT @StrSql=@StrSql +' GROUP by ShiftProductionDetails.pDate,ShiftProductionDetails.MachineID,ShiftProductionDetails.shift) as t '
		SELECT @StrSql=@StrSql +' inner join #CockpitData on #CockpitData.Pdt = t.pDate and #CockpitData.shftnm = t.shift and #CockpitData.machineid = t.machineID '
		--select * from #CockpitData
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
	if @TimeAxis='Shift' AND @Type='Console'
	BEGIN
		SELECT
			--cast(cast(DateName(month,Pdt) as nvarchar(3))+ ' '+cast(datepart(dd,Pdt)as nvarchar(2))+ ' Shift-' +cast(shftnm as nvarchar(20)) as Nvarchar(50)) as Day,
		cast(cast(DateName(month,Pdt) as nvarchar(3))+ ' '+cast(datepart(dd,Pdt)as nvarchar(2)) as Nvarchar(50)) as Day,	
		cast('Shift-'+cast(shftnm as nvarchar(20))as nvarchar(50)) as Shift,
					Pdt as [Date],shftnm as [ShiftName],Strttm as [StartTime],ndtim as [EndTime],MachineID,
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
		Components,Rejection,Operator
		FROM #CockpitData where Shftnm<>'Third' Order by Strttm,Machineid
	END
	if @TimeAxis='Day'AND @Type='Console'
	BEGIN
		SELECT	
		cast(cast(DateName(month,Pdt) as nvarchar(3))+ ' '+cast(datepart(yyyy,Pdt)as nvarchar(4)) as Nvarchar(50)) as Day,
		Strttm AS Shift,
		--cast(cast(DateName(month,Pdt) as nvarchar(3))+ ' '+cast(datepart(dd,Pdt)as nvarchar(2)) as Nvarchar(50)) as Day,
		Pdt,shftnm,Strttm,
		ndtim,	
		 MachineID,AvailabilityEfficiency * 100 As AE,
		ProductionEfficiency * 100 As PE,
		(ProductionEfficiency * AvailabilityEfficiency)*100 As OE,
		Components		
		FROM #CockpitData Order by Machineid,Strttm
	END
	if  @TimeAxis='Month'AND @Type='Console'
	BEGIN
		SELECT	
		--cast(cast(DateName(month,Pdt) as nvarchar(3))+ ' '+cast(datepart(yyyy,Pdt)as nvarchar(4)) as Nvarchar(50)) as Day,
		cast(Datepart(yyyy,pdt)as nvarchar(50)) As Day,
		Strttm AS Shift,
		Pdt,shftnm,Strttm,
		ndtim,	
		 MachineID,AvailabilityEfficiency * 100 As AE,
		ProductionEfficiency * 100 As PE,
		(ProductionEfficiency * AvailabilityEfficiency)*100 As OE,
		Components		
		FROM #CockpitData Order by Machineid,Strttm
	END
	if @TimeAxis='Hour' AND @Type='Cockpit'
	BEGIN
		SELECT	
		cast(cast(DateName(month,Pdt) as nvarchar(3))+ ' '+cast(datepart(dd,Pdt)as nvarchar(2))+ ' Shift-' +cast(shftnm as nvarchar(20)) as Nvarchar(50)) as Day,
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
		Components		
		FROM #CockpitData Order by Machineid,Strttm
	END
SET ARITHABORT ON
END
