/****** Object:  Procedure [dbo].[S_GetShiftWiseDowntimeReport_Nippon]    Committed by VersionSQL https://www.versionsql.com ******/

/*
--S_GetShiftWiseDowntimeReport_Nippon '2012-Dec-20 12:00:00 PM','2012-Dec-21 12:00:00 PM','','''defect''','','0'
--S_GetShiftWiseDowntimeReport_Nippon '2012-Dec-20 12:00:00 AM','2012-Dec-20 12:00:00 AM','ace-05','','WIn chennai - lcc','0'
--S_GetShiftWiseDowntimeReport_Nippon '2021-05-17 06:30:00','2021-05-18 06:30:00','','','',''

*/
CREATE procedure [dbo].[S_GetShiftWiseDowntimeReport_Nippon]
@StartTime datetime,
	@EndTime datetime,
	@MachineID nvarchar(50)= '',
	@DownID varchar(8000)='',
	@PlantID Nvarchar(50)='',
	@Exclude int
AS
BEGIN

--CREATE TABLE #Shift
--(
--	ShiftDate datetime,		
--	Shiftname nvarchar(20),
--	ShiftStart datetime,
--	ShiftEnd datetime	
--)

CREATE TABLE #ShiftDefn
(
	ShiftDate datetime,		
	Shiftname nvarchar(20),
	ShftSTtime datetime,
	ShftEndTime datetime	
)
create table #shift
(
	--ShiftDate Datetime, --DR0333
	ShiftDate nvarchar(10), --DR0333
	shiftname nvarchar(20),
	Shiftstart datetime,
	Shiftend datetime,
	shiftid int
)

create table #TempBreakDownData
(
StartTime datetime,
EndTime datetime,
machineid nvarchar(50),
machineDescription nvarchar(150),
componentid nvarchar(50),
OperationNo integer,
OperatorName nvarchar(50),
downid nvarchar(50),
DownDescription nvarchar(100),		--DR0177:24/Mar/2009:KarthikG
downtime float,
McDowntime float,
remarks nvarchar(255),
id bigint,
StdSetup float,
SetupEff float,
EmployeeName NVARCHAR(50),
Shift nvarchar(50)
)
CREATE TABLE #T_autodata(
	[mc] [nvarchar](50)not NULL,
	[comp] [nvarchar](50) NULL,
	[opn] [nvarchar](50) NULL,
	[opr] [nvarchar](50) NULL,
	[dcode] [nvarchar](50) NULL,
	[sttime] [datetime] not NULL,
	[ndtime] [datetime] not NULL,
	[datatype] [tinyint] NULL ,
	[Remarks][nvarchar](50) NULL,
	[cycletime] [int] NULL,
	[loadunload] [int] NULL ,
	[msttime] [datetime] not NULL,
	[PartsCount] decimal(18,5) NULL ,
	id  bigint not null
)

--mod 5
Create table #PlannedDownTimes
(
	Machine nvarchar(50),
	--StartTime DateTime, --DR0321
	--EndTime DateTime --DR0321
	st datetime, --DR0321
	nd datetime --DR0321
)
--mod 5
---mod 1
--DECLARE @strsql varchar(8000)
--DECLARE @StrDownId VARCHAR(8000)
DECLARE @strsql nvarchar(4000)
DECLARE @StrDownId NVARCHAR(4000)
---mod 1
DECLARE @strmachine nvarchar(200)
DECLARE @StrPlantID NVARCHAR(200)
--mod 4
DECLARE @StrPLD_DownId NVARCHAR(500)
declare @StrPLD  nvarchar(3000)
--mod 4
SELECT  @strsql=''
SELECT @strmachine=''
SELECT @StrDownId=''
SELECT @StrPlantID=''
--mod 4
select @StrPLD_DownId=''
select @StrPLD = ''
---mod 4
if isnull(@PlantID,'')<>''
begin
	---mod 1
	--select @StrPlantID=' AND (PlantMachine.PlantID ='''+@PlantID+''')'
	select @StrPlantID=' AND (P.PlantID =N'''+@PlantID+''')'
	---mod 1
end
if isnull(@MachineID,'')<>''
begin
	---mod 1
	--select @strmachine=' AND (machineinformation.machineid ='''+@MachineID+''')'
	select @strmachine=' AND (M.machineid =N'''+@MachineID+''')'
	---mod 1
end
IF ISNULL(@DownID,'')<>'' and @Exclude=0
BEGIN
	--SELECT @StrDownId=' AND (D.Downid in ( '+@DownID+' ))' --DR0321
	  SELECT @StrDownId=' AND (D.Downid in (' + @DownID + '))' --DR0321
END
IF ISNULL(@DownID,'')<>'' and @Exclude=1
BEGIN
--	SELECT @StrDownId=' AND (D.Downid not in ( '+@DownID+' ))' --DR0321
	SELECT @StrDownId=' AND (D.Downid not in (' + @DownID + '))' --DR0321
END

declare @CurStrtTime as datetime
declare @CurEndTime as datetime
--select @CurStrtTime=@StartTime
--select @CurEndTime=@EndTime 

declare @startdate as datetime
declare @enddate as datetime
declare @startdatetime nvarchar(20)

--ER0374 From Here
--select @startdate = dbo.f_GetLogicalDay(@StartTime,'start')
--select @enddate = dbo.f_GetLogicalDay(@endtime,'start')
select @startdate = dbo.f_GetLogicalDaystart(@StartTime)
select @enddate = dbo.f_GetLogicalDaystart(@endtime)
--ER0374 Till Here

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

Insert into #shift (ShiftDate,shiftname,Shiftstart,Shiftend)
--select ShiftDate,shiftname,ShftSTtime,ShftEndTime from #ShiftDefn where ShftSTtime>=@StartTime and ShftEndTime<=@endtime --DR0333
select convert(nvarchar(10),ShiftDate,126),shiftname,ShftSTtime,ShftEndTime from #ShiftDefn where ShftSTtime>=@StartTime and ShftEndTime<=@endtime --DR0333

Update #shift Set shiftid = isnull(#shift.Shiftid,0) + isnull(T1.shiftid,0) from
(Select SD.shiftid ,SD.shiftname from shiftdetails SD
inner join #shift S on SD.shiftname=S.shiftname where
running=1 )T1 inner join #shift on  T1.shiftname=#shift.shiftname


--while @CurStrtTime<=@CurEndTime
--BEGIN
--INSERT #Shift(ShiftDate,Shiftname,ShiftStart,ShiftEnd)    
--EXEC s_GetShiftTime @CurStrtTime,''
--SELECT @CurStrtTime=DATEADD(DAY,1,@CurStrtTime)
--END
--select * from #Shift
--return
Declare @T_ST AS Datetime 
Declare @T_ED AS Datetime 

Select @T_ST= min(ShiftStart) from #Shift
Select @T_ED=max(ShiftEnd) from #Shift

Select @strsql=''
select @strsql ='insert into #T_autodata '
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'
	select @strsql = @strsql + 'ndtime, datatype,Remarks,cycletime, loadunload, msttime, PartsCount,id'
select @strsql = @strsql + ' from autodata where (( sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_ED,120)+''' ) OR '
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' )OR '
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ST,120)+'''
					and ndtime<='''+convert(nvarchar(25),@T_ED,120)+''' )'
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' and sttime<'''+convert(nvarchar(25),@T_ED,120)+''' ) )'
print @strsql
exec (@strsql)



If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
BEGIN
	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y' AND (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
	BEGIN
		SELECT @StrPLD_DownId=' AND D.DownID= (SELECT ValueInText From CockpitDefaults Where Parameter =''Ignore_Dtime_4m_PLD'')'
	END
	/* Planned Down times for the given time period at machine level*/
	 select @strsql=' Insert into #PlannedDownTimes
	(Machine,st,nd)
	SELECT Machine,
		CASE When starttime<S.ShiftStart Then S.ShiftStart  Else starttime End As starttime,
		CASE When endtime>S.ShiftEnd  Then S.ShiftEnd  Else endtime End As endtime
		FROM PlannedDownTimes CROSS JOIN #shift S
	WHERE (
	(starttime >= S.ShiftStart AND endtime<=S.ShiftEnd)
	OR (starttime < S.ShiftStart AND endtime<=S.ShiftEnd AND endtime >S.ShiftStart )
	OR (starttime >= S.ShiftStart AND starttime<S.ShiftEnd AND endtime >S.ShiftEnd )
	OR (starttime < S.ShiftStart AND endtime>S.ShiftEnd) ) and pdtstatus=1 '
	if isnull(@MachineID,'')<>''
	begin
		select @strsql=@strsql+' AND (PlannedDownTimes.machine =N'''+@MachineID+''') '
	ENd
	select @strsql=@strsql+' ORDER BY starttime'
	print @strsql
	exec (@strsql)
	select @strPld=' LEFT OUTER JOIN
	(
	SELECT T1.Sttime AS PLD_Sttime ,T1.Ndtime AS PLD_Ndtime,T1.MachineID AS PLD_MachineID,Sum(ISNULL(T1.PLD_LoadUnload,0))PLD_LoadUnload
	FROM
		(SELECT A.Sttime,A.Ndtime,M.MachineID,
		CASE
			WHEN (A.sttime>=T.st AND A.ndtime<=T.nd) THEN Loadunload
			WHEN (A.sttime<T.st AND A.ndtime<=T.nd AND A.ndtime>T.st)THEN DATEDIFF(ss,T.st,A.ndtime)
			WHEN (A.sttime>=T.st AND A.sttime<T.nd AND A.ndtime>T.nd) THEN DATEDIFF(ss,A.Sttime,T.nd )
			WHEN (A.sttime<T.st AND A.ndtime>T.nd) THEN DATEDIFF(ss,T.st,T.nd)
		End As PLD_LoadUnload
		From #T_autodata A --CROSS JOIN #shift S
		INNER JOIN MachineInformation M  ON A.Mc=M.InterfaceID
		--Left Outer Join PlantMachine ON PlantMachine.machineid=M.machineid INNER JOIN --DR0321 Commented
		Left Outer Join PlantMachine P ON P.machineid=M.machineid INNER JOIN --DR0321 Added
		Downcodeinformation D ON A.dcode = D.interfaceid inner JOIN #PlannedDownTimes T on T.Machine=M.machineid
		Where A.Datatype=2 
		--And ((A.sttime>=S.ShiftStart AND A.ndtime<=S.ShiftEnd )
		--OR(A.sttime<S.ShiftStart AND A.ndtime>S.ShiftStart AND A.ndtime<=S.ShiftEnd )
		--OR(A.sttime>=S.ShiftStart AND A.ndtime>S.ShiftEnd  AND A.sttime<S.ShiftEnd )
		--OR(A.sttime<S.ShiftStart AND A.ndtime>S.ShiftEnd ))
		And (
		(A.sttime>=T.st AND A.ndtime<=T.nd)
		OR(A.sttime<T.st AND A.ndtime<=T.nd AND A.ndtime>T.st)
		OR(A.sttime>=T.st AND A.sttime<T.nd AND A.ndtime>T.nd)
		OR(A.sttime<T.st AND A.ndtime>T.nd))'
	select @strPld=@strPld + @StrPlantID + @strmachine + @StrDownId	+ @StrPLD_DownId
	select @strPld=@strPld + ')AS T1
	Group By T1.Sttime,T1.Ndtime,T1.MachineID'
	--) AS Td ON AutoData.Sttime=Td.PLD_Sttime AND AutoData.Ndtime=Td.PLD_Ndtime AND MachineInformation.MachineID=Td.PLD_MachineID '
	select @strPld=@strPld + ' )AS Td ON A.Sttime=Td.PLD_Sttime AND A.Ndtime=Td.PLD_Ndtime AND M.MachineID=Td.PLD_MachineID '
END
---mod 4
select @strsql='insert into  #TempBreakDownData(StartTime,endtime,machineid,machineDescription,componentid,OperationNo,OperatorName,EmployeeName,Shift,downid,downdescription,downtime,Mcdowntime,remarks,id,StdSetup,SetupEff)
select
CASE When A.sttime<S.ShiftStart Then S.ShiftStart  Else A.sttime End As sttime,
CASE When A.ndtime>S.ShiftEnd  Then S.ShiftEnd  Else A.ndtime End As ndtime,
--A.sttime,A.ndtime,
M.machineid,M.Description,
CI.componentid,
CO.operationno,E.employeeid,E.Name,S.Shiftname,
D.downid,D.downdescription,'
---A.loadunload  ----DR0308 Swathi Commented
----DR0308 Added From Here----------------
select @strsql=@strsql + ' SUM(CASE
			WHEN (A.sttime>=S.ShiftStart AND A.ndtime<=S.ShiftEnd) THEN A.Loadunload
			WHEN (A.sttime<S.ShiftStart AND A.ndtime>S.ShiftStart AND A.ndtime<=S.ShiftEnd) THEN DATEDIFF(ss,S.ShiftStart,A.ndtime)
			WHEN (A.sttime>=S.ShiftStart AND A.ndtime>S.ShiftEnd AND A.sttime<S.ShiftEnd) THEN DATEDIFF(ss,A.Sttime,S.ShiftEnd)
			WHEN (A.sttime<S.ShiftStart AND A.ndtime>S.ShiftEnd) THEN DATEDIFF(ss,S.ShiftStart,S.ShiftEnd)
		End )'
----DR0308 Added Till Here----------------
---mod 4
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
BEGIN
select @strsql=@strsql + '-ISNULL(Td.PLD_LoadUnload,0)'
END
---mod 4
select @strsql = @strsql + ' As downtime'
select @strsql=@strsql + ' ,0,A.Remarks,A.id,0,0
FROM #T_autodata A  INNER JOIN
machineinformation M ON A.mc = M.InterfaceID Left Outer Join
--PlantMachine ON PlantMachine.machineid=M.machineid INNER JOIN --DR0321 Commented
PlantMachine P ON P.machineid=M.machineid INNER JOIN --DR0321 Added
downcodeinformation D ON A.dcode = D.interfaceid INNER JOIN
employeeinformation E ON A.opr = E.interfaceid INNER JOIN
componentinformation CI ON A.COMP= CI.interfaceid INNER JOIN
componentoperationpricing CO ON A.opn  = CO.interfaceid and CO.componentid=CI.componentid'
---mod 3
select @strsql=@strsql +' and CO.Machineid=M.machineid '
---mod 3
---mod 4: Neglect planned down times
select @strsql=@strsql + @strPld + ' CROSS JOIN #Shift S '

---mod 4
select @strsql=@strsql +' WHERE (A.datatype = 2)'
--mod 5:Consider all 4 types
--select @strsql=@strsql +'AND (A.sttime >= ''' + convert(nvarchar(20),@StartTime) + ''')'
--select @strsql=@strsql +'AND (A.ndtime <= ''' + convert(nvarchar(20),@EndTime) + ''')'
SELECT @StrSql =@StrSql +'AND ((A.sttime>=S.ShiftStart AND A.ndtime<=S.ShiftEnd)
		OR(A.sttime<S.ShiftStart AND A.ndtime>S.ShiftStart AND A.ndtime<=S.ShiftEnd)
		OR(A.sttime>=S.ShiftStart AND A.ndtime>S.ShiftEnd AND A.sttime<S.ShiftEnd)
		OR(A.sttime<S.ShiftStart AND A.ndtime>S.ShiftEnd))'
---mod 5
select @strsql=@strsql + @StrPlantID + @strmachine + @StrDownId
----DR0308 Added From Here----------------
select @strsql=@strsql +'group by A.sttime,A.ndtime,
M.machineid,M.description,CI.componentid,
CO.operationno,E.employeeid,E.Name,S.Shiftname,
D.downid,D.downdescription,A.Remarks,A.id,S.ShiftStart,S.ShiftEnd'
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
BEGIN
select @strsql=@strsql + ' ,Td.PLD_LoadUnload'
END
----DR0308 Added Till Here----------------
--select @strsql=@strsql +'ORDER BY A.ndtime' ------DR0308 Commented
exec(@strsql)
print @strsql

---mod 5: delete records with downtime=0
delete from #TempBreakDownData where  downtime<=0
--mod 5
--updated by mrudula to capture std setup time from CO table
update #TempBreakDownData set StdSetup=ISNULL(T2.SETUp,0) From
---mod 2
--(SELECT C.componentID AS componentID,O.OperationNo AS OperationNo,O.StdSetupTime AS SETUp
-- FROM ComponentInformation C Inner Join  Componentoperationpricing O ON C.ComponentID=O.ComponentID
--)AS T2 Inner Join #TempBreakDownData on #TempBreakDownData.ComponentID=T2.ComponentID AND
-- #TempBreakDownData.OperationNo=T2.OperationNo
--WHERE #TempBreakDownData.Downid='SETUP'
(SELECT C.componentID AS componentID,O.OperationNo AS OperationNo,O.StdSetupTime AS SETUp,M.machineid
FROM ComponentInformation C Inner Join Componentoperationpricing O ON C.ComponentID=O.ComponentID
inner join machineinformation M on M.machineid = O.machineid
)AS T2 Inner Join #TempBreakDownData on #TempBreakDownData.ComponentID=T2.ComponentID
AND #TempBreakDownData.OperationNo=T2.OperationNo and #TempBreakDownData.machineid = T2.machineid
WHERE #TempBreakDownData.Downid='SETUP'
---mod 2
--Query to calculate Seup Efficiency
Update #TempBreakDownData set SetupEff=isnull((StdSetup/isnull(downtime,0)),0)*100  where Downid='SETUP' and downtime<>0
--Get the total down time by machine
update #TempBreakDownData set McDowntime = isnull(Mcdowntime,0) + isnull(t2.down,0)
from (select Machineid, sum(downtime) down
from #tempBreakdowndata group by Machineid)as t2 inner join #tempbreakdowndata on t2.machineid = #tempbreakdowndata.Machineid
--Format the downtime as per user preferences
declare @TimeFormat as nvarchar(25)
SELECT @TimeFormat = ''
SELECT @TimeFormat = (SELECT  ValueInText  FROM CockpitDefaults WHERE Parameter = 'TimeFormat')
if (ISNULL(@TimeFormat,'')) = ''
	SELECT @TimeFormat = 'ss'
SELECT @strsql = 'SELECT Id,StartTime,EndTime,machineID,machineDescription,componentid,OperationNo,OperatorName,EmployeeName,Shift,DownID,DownDescription,remarks,downtime as DownNumeric,Remarks,'
if (@TimeFormat = 'hh:mm:ss'or @TimeFormat = 'hh' or @TimeFormat = 'mm' or @TimeFormat = 'ss' )
begin	
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(DownTime,''' + @TimeFormat + ''') as DownTime , '
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(McDownTime,''' + @TimeFormat + ''') as McDownTime , '
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(StdSetup,''' + @TimeFormat + ''') as StdSetup , '
	end
SELECT @strsql =  @strsql  + 'SetupEff From #TempBreakDownData order by EndTime'
--print @strsql
EXEC (@strsql)
END
