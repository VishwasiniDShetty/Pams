/****** Object:  Procedure [dbo].[s_GetShiftwiseProdandDownData]    Committed by VersionSQL https://www.versionsql.com ******/

/**********************************************************************************************
NR0092-SwathiKS-05/Aug/2013 :: New report requirement To Show ShiftLevel M-C-O-O-Partcount and Machine Level Downtime 
and Top 3 DownReasons Based on Criteria like <30mins,>30mins <60mins and >60mins.
--s_GetShiftwiseProdandDownData '2013-01-01','A','ACE VTL-01','','','','2013-01-01',''
--s_GetShiftwiseProdandDownData '2013-05-01','First','','','','','2013-05-20','prod'
--s_GetShiftwiseProdandDownData '2013-07-02','A','','','','','2013-07-02','Down'
--s_GetShiftwiseProdandDownData '2013-03-02','FIRST','','','','','2013-03-02','prod'

s_GetShiftwiseProdandDownData '2013-01-11' ,'FIRST','','','' ,'','2013-01-11','prod'
s_GetShiftwiseProdandDownData '2013-01-11' ,'FIRST','','','' ,'','2013-01-11','down'

**********************************************************************************************/
CREATE  PROCEDURE [dbo].[s_GetShiftwiseProdandDownData]
	@StartDate datetime,
	@ShiftIn nvarchar(20) = '',
	@MachineID nvarchar(50) = '',
	@ComponentID nvarchar(50) = '',
	@OperationNo nvarchar(50) = '',
	@PlantID NvarChar(50)='',
	@EndDate datetime='',
	@Param nvarchar(20)=''  
	
AS
BEGIN


CREATE TABLE #MCOLevelActual
( 
	MachineID nvarchar(50),
	Component nvarchar(50),
	CompDescription nvarchar(50),
	Operation nvarchar(50),
	OpnDescription nvarchar(50),
	Operator nvarchar(50),
	PartCount int,
	downtime float,
	Sdate datetime,
	ShiftName nvarchar(50),
	ShftStart datetime,
	ShftEnd datetime
)

create table #MachineLevelDown
(
	ShiftStart datetime,
	ShiftEnd datetime,
	Machineid nvarchar(50),
	Downtime nvarchar(50),
	DownReason nvarchar(50),
	PDT int,
	TotalDown float
)

CREATE TABLE #ShiftDetails 
(
	PDate datetime,
	Shift nvarchar(20),
	ShiftStart datetime,
	ShiftEnd datetime
)

CREATE TABLE #PlannedDownTimesShift
(
	Starttime datetime,
	EndTime datetime,
	Machine nvarchar(50),
	MachineInterface nvarchar(50),
	ShiftSt datetime
)

create table #machine
(
	machine nvarchar(50),
	ShiftStart datetime,
	ShiftEnd datetime
)

create table #Downdata1
(
	Machine nvarchar(50),
	ShiftStart datetime,
	ShiftEnd datetime,
	Dtime30min nvarchar(50),
	Remarks nvarchar(50)
)

create table #Downdata2
(
	Machine nvarchar(50),
	ShiftStart datetime,
	ShiftEnd datetime,
	Dtime60min nvarchar(50),
	Remarks nvarchar(50)
)

create table #Downdata3
(
	Machine nvarchar(50),
	ShiftStart datetime,
	ShiftEnd datetime,
	Dtime1hour nvarchar(50),
	Remarks nvarchar(50)
)

create table #downdata
(
	Machine nvarchar(50),
	ShiftStart datetime,
	ShiftEnd datetime,
	Dtime nvarchar(50),
	Remarks nvarchar(50)
)


declare @strsql nvarchar(4000)
Declare @StrMPlantID AS NVarchar(255)
declare @strmachine nvarchar(255)
declare @strcomponentid nvarchar(255)
declare @stroperation nvarchar(255)
select @strsql = ''
select @strcomponentid = ''
select @stroperation = ''
select @strmachine = ''
Select @StrMPlantID=''

if isnull(@EndDate,'')=''
begin
	select @EndDate=@StartDate
end

if isnull(@PlantID,'') <> ''
begin
	select @StrMPlantID = ' and ( PlantMachine.PlantID = N''' + @PlantID + ''' )'
end

if isnull(@machineid,'') <> ''
begin
	select @strmachine = ' and ( machineinformation.MachineID = N''' + @MachineID + ''')'
end

if isnull(@componentid,'') <> ''
begin
	select @strcomponentid = ' AND ( componentinformation.componentid = N''' + @componentid + ''')'
end

if isnull(@operationno, '') <> ''
begin
	select @stroperation = ' AND ( componentoperationpricing.operationno = N''' + @OperationNo +''')'
end

declare @CurStrtTime as datetime
declare @CurEndTime as datetime
select @CurStrtTime=@StartDate
select @CurEndTime=@EndDate

while @CurStrtTime<=@CurEndTime
BEGIN
	INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)
	EXEC s_GetShiftTime @CurStrtTime,@ShiftIn
	SELECT @CurStrtTime=DATEADD(DAY,1,@CurStrtTime)
END


IF  @param = 'Prod'
Begin

	Select @strsql=''
	select @strsql = 'insert into #MCOLevelActual (MachineID,Component,CompDescription,Operation,OpnDescription,Operator,PartCount,Downtime,Sdate,ShiftName,ShftStart,ShftEnd) '
	select @strsql = @strsql + ' SELECT  distinct machineinformation.machineid,componentinformation.componentid , componentinformation.Description,'
	select @strsql = @strsql + ' componentoperationpricing.operationno,componentoperationpricing.Description,Employeeinformation.Employeeid,'
	select @strsql = @strsql + ' CEILING(CAST(Sum(autodata.partscount)AS Float)/ISNULL(ComponentOperationPricing.SubOperations,1)),'
	select @strsql = @strsql + ' ''0'',Pdate, Shift, ShiftStart, ShiftEnd FROM autodata'
	select @strsql = @strsql + ' INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID '
	select @strsql = @strsql + ' INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID '
	select @strsql = @strsql + ' INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID'
	select @strsql = @strsql + ' and componentoperationpricing.machineid=machineinformation.machineid '
	select @strsql = @strsql + ' AND componentinformation.componentid = componentoperationpricing.componentid '
	select @strsql = @strsql + ' INNER Join Employeeinformation ON Employeeinformation.interfaceid=autodata.opr '
	select @strsql = @strsql + ' Left Outer Join PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID '
	select @strsql = @strsql + ' cross join  #ShiftDetails '
	select @strsql = @strsql + ' where machineinformation.interfaceid > 0 '
	select @strsql = @strsql + ' and (( sttime >= shiftstart and ndtime <= shiftend ) OR '
	select @strsql = @strsql + ' (sttime < shiftstart and ndtime > shiftstart and ndtime<=shiftend ))'
	select @strsql = @strsql + ' and autodata.datatype=1 '
	select @strsql = @strsql + ' AND (autodata.partscount > 0 ) '
	select @strsql = @strsql + @strmachine+@StrMPlantID+@strcomponentid+@stroperation
	select @strsql = @strsql + ' group by machineinformation.machineid,componentinformation.componentid, componentinformation.Description, '
	select @strsql = @strsql + ' componentoperationpricing.operationno,componentoperationpricing.Description,Employeeinformation.Employeeid,ComponentOperationPricing.SubOperations, '
	select @strsql = @strsql + ' Pdate, Shift, ShiftStart, ShiftEnd  '
	select @strsql = @strsql + ' order by  ShiftStart asc,machineinformation.machineid '
	print @strsql
	Exec(@strsql)


	Select @strsql=''
	select @strsql = 'Insert into #MachineLevelDown(shiftstart,shiftend,machineid,downtime)
	SELECT #ShiftDetails.ShiftStart as intime,#ShiftDetails.ShiftEnd,machineinformation.machineid,
	SUM(case
	When (autodata.sttime >= ShiftStart AND autodata.ndtime <= ShiftEnd ) THEN loadunload
	WHEN ( autodata.sttime < ShiftStart AND autodata.ndtime <= ShiftEnd AND autodata.ndtime > ShiftStart ) THEN DateDiff(second, ShiftStart, ndtime)
	WHEN ( autodata.sttime >= ShiftStart AND autodata.sttime < ShiftEnd AND autodata.ndtime > ShiftEnd ) THEN  DateDiff(second, stTime, ShiftEnd)
	ELSE
	DateDiff(second, ShiftStart, ShiftEnd)END) AS Down
	FROM autodata cross join #ShiftDetails 
	INNER JOIN machineinformation ON autodata.mc = machineinformation.InterfaceID 
	Left Outer Join PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID
	INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid 
	WHERE autodata.datatype = 2 AND
	(
	(autodata.sttime >= ShiftStart  AND autodata.ndtime <=ShiftEnd)
	OR ( autodata.sttime < ShiftStart  AND autodata.ndtime <= ShiftEnd AND autodata.ndtime > ShiftStart )
	OR ( autodata.sttime >= ShiftStart   AND autodata.sttime <ShiftEnd AND autodata.ndtime > ShiftEnd )
	OR ( autodata.sttime < ShiftStart  AND autodata.ndtime > ShiftEnd))'
	select @strsql = @strsql + @strmachine+@StrMPlantID
	select @strsql = @strsql + ' group by machineinformation.machineid,#ShiftDetails.ShiftStart,#ShiftDetails.ShiftEnd'
	print @strsql
	Exec(@strsql)

	insert INTO #PlannedDownTimesShift(StartTime,EndTime,Machine,MachineInterface,Shiftst)
	select
	CASE When StartTime<T1.ShiftStart Then T1.ShiftStart Else StartTime End,
	case When EndTime>T1.ShiftEnd Then T1.ShiftEnd Else EndTime End,
	Machine,M.InterfaceID,T1.ShiftStart
	FROM PlannedDownTimes cross join #ShiftDetails T1
	inner join MachineInformation M on PlannedDownTimes.machine = M.MachineID
	WHERE PDTstatus =1 and 
	((StartTime >= T1.ShiftStart  AND EndTime <=T1.ShiftEnd)
	OR ( StartTime < T1.ShiftStart  AND EndTime <= T1.ShiftEnd AND EndTime > T1.ShiftStart )
	OR ( StartTime >= T1.ShiftStart   AND StartTime <T1.ShiftEnd AND EndTime > T1.ShiftEnd )
	OR ( StartTime < T1.ShiftStart  AND EndTime > T1.ShiftEnd))
	and machine in (select distinct machine from #MCOLevelActual)
	ORDER BY StartTime

	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
	BEGIN

		UPDATE #MCOLevelActual SET PartCount = ISNULL(PartCount,0)- isnull(t2.PCount,0)
		FROM( 
		select T.Shiftst as intime,Machineinformation.machineid as machine,(CEILING (CAST(Sum(ISNULL(PartsCount,1)) AS Float)/ISNULL(Componentoperationpricing.SubOperations,1))) as PCount,
		Componentinformation.componentid as compid,componentoperationpricing.Operationno as opnno,Employeeinformation.employeeid as emp from autodata 
		Inner jOIN #PlannedDownTimesShift T on T.MachineInterface=autodata.mc  
		inner join machineinformation on autodata.mc=machineinformation.Interfaceid
		Inner join componentinformation on autodata.comp=componentinformation.interfaceid 
		inner join componentoperationpricing on autodata.opn=componentoperationpricing.interfaceid and
		componentinformation.componentid=componentoperationpricing.componentid  and componentoperationpricing.machineid=machineinformation.machineid
		INNER Join Employeeinformation ON Employeeinformation.interfaceid=autodata.opn 
		WHERE autodata.DataType=1 AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)
		Group by Machineinformation.machineid,componentinformation.componentid ,componentoperationpricing.Operationno,Employeeinformation.employeeid,componentoperationpricing.SubOperations,T.Shiftst
		) as T2 inner join #MCOLevelActual S on T2.machine = S.machineid  and T2.compid=S.Component and t2.opnno=S.Operation 
		  and t2.emp=S.operator and t2.intime=S.ShftStart
	END

	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
	BEGIN

		Update #MachineLevelDown set Downtime=isnull(Downtime,0) - isnull(T1.Down,0) from
		(
			SELECT T.Shiftst as intime,machineinformation.machineid,
			SUM(case
			When (autodata.sttime >= T.StartTime AND autodata.ndtime <= T.EndTime ) THEN loadunload
			WHEN ( autodata.sttime < T.StartTime AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime ) THEN DateDiff(second, T.StartTime, ndtime)
			WHEN ( autodata.sttime >= T.StartTime AND autodata.sttime < T.EndTime AND autodata.ndtime > T.EndTime ) THEN  DateDiff(second, stTime, T.EndTime)
			ELSE
			DateDiff(second, T.StartTime, T.EndTime)END) AS Down
			FROM autodata 
			Inner jOIN #PlannedDownTimesShift T on T.MachineInterface=autodata.mc  
			INNER JOIN machineinformation ON autodata.mc = machineinformation.InterfaceID 
			INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid 
			WHERE autodata.datatype = 2 AND
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)group by machineinformation.machineid,T.Shiftst
		)T1 inner join #MachineLevelDown S on T1.machineid = S.machineid  and  t1.intime=S.ShiftStart

	END

	select M2.MachineID as MACHINE,isnull(operation + ' - ' + OpnDescription,'') as PARTNO,isnull(Component + ' - ' + CompDescription,'') as PARTNAME,isnull(PartCount,0) as PartCount,isnull(Operator,'') as Operator,
	dbo.f_FormatTime(M2.DownTime,'hh:mm:ss') as DownTime from #MCOLevelActual M1  
	right outer join #MachineLevelDown M2 on M1.machineid=M2.machineid
	order by M2.MachineID,ShftStart

END

If @param = 'Down'
Begin

	Select @strsql = ''
	Select @strsql = 'Insert into #MachineLevelDown(ShiftStart,ShiftEnd,machineid,DownReason,Downtime,PDT,TotalDown)
	SELECT #ShiftDetails.ShiftStart,#ShiftDetails.ShiftEnd,machineinformation.machineid,downcodeinformation.downid AS DownID,
	SUM(case
	When (autodata.sttime >= ShiftStart AND autodata.ndtime <= ShiftEnd ) THEN loadunload
	WHEN ( autodata.sttime < ShiftStart AND autodata.ndtime <= ShiftEnd AND autodata.ndtime > ShiftStart ) THEN DateDiff(second, ShiftStart, ndtime)
	WHEN ( autodata.sttime >= ShiftStart AND autodata.sttime < ShiftEnd AND autodata.ndtime > ShiftEnd ) THEN  DateDiff(second, stTime, ShiftEnd)
	ELSE
	DateDiff(second, ShiftStart, ShiftEnd)END) AS DownTime,0 as PDT,0
	FROM autodata cross join #ShiftDetails 
	INNER JOIN machineinformation ON autodata.mc = machineinformation.InterfaceID 
	INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid 
	Left Outer Join PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID
	WHERE autodata.datatype = 2 AND
	(
	(autodata.sttime >= ShiftStart  AND autodata.ndtime <=ShiftEnd)
	OR ( autodata.sttime < ShiftStart  AND autodata.ndtime <= ShiftEnd AND autodata.ndtime > ShiftStart )
	OR ( autodata.sttime >= ShiftStart   AND autodata.sttime <ShiftEnd AND autodata.ndtime > ShiftEnd )
	OR ( autodata.sttime < ShiftStart  AND autodata.ndtime > ShiftEnd))'
	select @strsql = @strsql + @strmachine+@StrMPlantID
	select @strsql = @strsql + ' group by machineinformation.machineid,downcodeinformation.downid,#ShiftDetails.ShiftStart,#ShiftDetails.ShiftEnd'
	print @strsql
	Exec(@strsql)

	Insert into #machine
	select distinct machineid,ShiftStart,ShiftEnd from #MachineLevelDown

	declare @machine nvarchar(50)
	declare @ShiftStart datetime,@ShiftEnd datetime
	declare @GetDowntime cursor
	set @getdowntime = Cursor for
	select machine,ShiftStart,ShiftEnd from #machine  order by machine
	open @getdowntime

	Fetch next from @getdowntime into @machine,@ShiftStart,@ShiftEnd

	While @@Fetch_status = 0
	Begin
		
		Insert into #Downdata1(Machine,shiftstart,shiftend,Dtime30min,Remarks)
		select top 3 Machineid,shiftstart,shiftend,Downreason + '-' + dbo.f_formattime(Downtime,'hh:mm'),'1' from #MachineLevelDown
		where (Downtime/60)>0 and (Downtime/60)<30 and machineid=@machine and ShiftStart=@ShiftStart and ShiftEnd=@ShiftEnd
		order by Downtime desc

		Insert into #Downdata2(Machine,shiftstart,shiftend,Dtime60min,Remarks)
		select top 3 Machineid,shiftstart,shiftend,Downreason + '-' + dbo.f_formattime(Downtime,'hh:mm'),'2' from #MachineLevelDown
		where (Downtime/60)>30 and (Downtime/60)<60 and machineid=@machine and ShiftStart=@ShiftStart and ShiftEnd=@ShiftEnd
		order by Downtime desc

		Insert into #Downdata3(Machine,shiftstart,shiftend,Dtime1hour,Remarks)
		select top 3 Machineid,shiftstart,shiftend,Downreason + '-' + dbo.f_formattime(Downtime,'hh:mm'),'3' from #MachineLevelDown
		where (Downtime/60)>60 and machineid=@machine and ShiftStart=@ShiftStart and ShiftEnd=@ShiftEnd
		order by Downtime desc
	
		Fetch next from @getdowntime into @machine,@ShiftStart,@ShiftEnd
	end

	CLOSE @getdowntime;
	DEALLOCATE @getdowntime;


Insert into #Downdata(Machine,shiftstart,shiftend,Dtime,Remarks)
Select * from #Downdata1  UNION Select * from #Downdata2 UNION  Select * from #Downdata3 

select * from #Downdata order by machine,Remarks 
END

END
