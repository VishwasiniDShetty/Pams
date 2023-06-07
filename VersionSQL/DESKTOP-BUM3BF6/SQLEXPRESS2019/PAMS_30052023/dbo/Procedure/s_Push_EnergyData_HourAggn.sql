/****** Object:  Procedure [dbo].[s_Push_EnergyData_HourAggn]    Committed by VersionSQL https://www.versionsql.com ******/

/*****************************************************************************************************
Procedure written by Mrudula M. Rao and Karthik G on 02-Nov-09 for NR0062.
Aggregate Energy Data at hour level
mod 1 :- By Mrudula on 30-nov-2009 for DR0225. Error while inserting record into last aggregation trail.Consider the records which are greater than last aggregated time stamp.
DR0236 - By SwathiKS on 23-Jun-2010 :: Use proper conditions in case statements to remove icd's from type 4 production records.
DR0304 - SwathiKS - 28/dec/2011 :: To handle Prodtime Mismatch and convert ddate as yyyy-mmm-dd format.
ER0340 - GeetanjaliK - 15/Nov/2012 :: To handle Utilised time Mismatch and to optimize performance.
select * from machineinformation
s_Push_EnergyData_HourAggn '2012-12-28 06:30:00 AM','2012-12-29 06:30:00 AM','''ACE-04'''
******************************************************************************************************/
CREATE                   procedure [dbo].[s_Push_EnergyData_HourAggn]
@FromDate as datetime,
@EndDate as Datetime,
@MachineId as nvarchar(250)=''
as
BEGIN
BEGIN TRANSACTION
CREATE TABLE #HourDetails
(
	PDate datetime,
	Shift nvarchar(20),
	ShiftID int,
	HourID int,
	HourStart datetime,
	HourEnd datetime
)
---table to get last aggregated timestamp for the machines
CREATE TABLE #LASTAGGTIME
(
	MachineID nvarchar(50),
	MachineInt nvarchar(50),
	LastAggstart datetime,
	LastAggHourStart datetime,
	LastAggHourEnd datetime,
	LastAggHourID nvarchar(50),
	lASTAGGDATE DATETIME,
	LASTAGGSHIFTID nvarchar(50)
)
	
---Table to hold exception defined.
CREATE TABLE #Exceptions
(
	MachineID NVarChar(50),
	ComponentID Nvarchar(50),
	OperationNo Int,
	StartTime DateTime,
	EndTime DateTime,
	ExStartTime DateTime,
	ExEndTime DateTime,
	ExCount Int,
	ActualCount Int,
	IdealCount Int,
	EXDate datetime,
	EXShiftId int,
	EXHrID int
)
--Final table to get energy , KW, ampere,PF,prod time,components and cost at hour level
Create table #GetFinalHourAggData
(
dDate DateTime not null,
ShiftName NVarChar(50),
ShiftID int not null,
HourId int not null,
HourStartTime DateTime not null,
HourEndTime DateTime,
MachineID nvarchar(50) not null,
McInterface nvarchar(50),
ProdTime float,
Components int,
Energy_KWH float,
minenergykwh float,
maxenergykwh float,
PF float,
KW float,
Ampere float,
Cost float,
LastAggstart datetime
)
ALTER TABLE #GetFinalHourAggData
	ADD PRIMARY KEY CLUSTERED
		(
			[dDate],
			[HourStartTime],
			[ShiftID],
			[HourId],
			[MachineID]
		) ON [PRIMARY]
declare @dDate as datetime
Declare @strMachine as nvarchar(600)
Declare @strPlantID as nvarchar(250)
Declare @StrSql as nvarchar(4000)
DECLARE @ErrNo as int
SET @StrSql = ''
SET @strMachine = ''
SET @strPlantID = ''
if isnull(@MachineID,'')<> ''
begin
	---SET @strMachine = ' AND MachineInformation.MachineID = ''' + @machineid + ''''
	---mod 2 Aggregating multiple machines at one time
	SET @strMachine = ' AND M.MachineID  in (' + @machineid + ') '
	---mod 2
end
--Get Shift Start and Shift End
	INSERT #HourDetails(
	PDate ,	Shift,	ShiftID ,HourId ,HourStart ,HourEnd )
	select @FromDate,shiftdetails.shiftname,Shifthourdefinition.shiftid,
	Shifthourdefinition.Hourid,
	case when Shifthourdefinition.fromday = 0 then cast((cast(datepart(yyyy,@FromDate) as nvarchar(20))+'-'+cast(datepart(m,@FromDate) as nvarchar(20))+'-'+cast(datepart(dd,@FromDate) as nvarchar(20))+' '+cast(datepart(hh,hourStart) as nvarchar(20))+':'+cast(datepart(n,hourStart) as nvarchar(20))+':'+cast(datepart(s,hourStart) as nvarchar(20))) as DateTime)
	when Shifthourdefinition.fromday = 1 then cast((cast(datepart(yyyy,@FromDate) as nvarchar(20))+'-'+cast(datepart(m,@FromDate) as nvarchar(20))+'-'+cast(datepart(dd,@FromDate) as nvarchar(20))+' '+cast(datepart(hh,hourStart) as nvarchar(20))+':'+cast(datepart(n,hourStart) as nvarchar(20))+':'+cast(datepart(s,hourStart) as nvarchar(20))) as DateTime)+1
	end as FromTime,
	case when Shifthourdefinition.today = 0 then cast((cast(datepart(yyyy,@FromDate) as nvarchar(20))+'-'+cast(datepart(m,@FromDate) as nvarchar(20))+'-'+cast(datepart(dd,@FromDate) as nvarchar(20))+' '+cast(datepart(hh,hourEnd) as nvarchar(20))+':'+cast(datepart(n,hourEnd) as nvarchar(20))+':'+cast(datepart(s,hourEnd) as nvarchar(20))) as DateTime)
	when Shifthourdefinition.today = 1 then cast((cast(datepart(yyyy,@FromDate) as nvarchar(20))+'-'+cast(datepart(m,@FromDate) as nvarchar(20))+'-'+cast(datepart(dd,@FromDate) as nvarchar(20))+' '+cast(datepart(hh,hourEnd) as nvarchar(20))+':'+cast(datepart(n,hourEnd) as nvarchar(20))+':'+cast(datepart(s,hourEnd) as nvarchar(20))) as DateTime)+1
	end as ToTime
	From Shifthourdefinition
	inner join shiftdetails on shiftdetails.shiftid=Shifthourdefinition.shiftid
	where shiftdetails.running = 1

	--Introduced TOP 1 to take care of input 'ALL' shifts
	declare @FirstStartTime datetime
	declare @FirstEndTime datetime
	select @FirstStartTime =(select TOP 1 HourStart from #HourDetails ORDER BY HourStart ASC)
	select @FirstEndTime =(select TOP 1 HourEnd from #HourDetails where HourStart=@FirstStartTime)
	--declare @firstHour int
	--declare @firstShift int
	declare @firstHour nvarchar(10)
	declare @firstShift nvarchar(10)

	--select @firstHour=''
	select @firstHour=(select TOP 1 hourid from #HourDetails order by HourStart ASC)
	select @firstShift=0
	select  @firstShift=(select TOP 1 ShiftID from #HourDetails order by HourStart ASC)
	
	--select * from #HourDetails
	--get last aggregated time for machine
	
	select @StrSql = ''
	select @StrSql = @StrSql + 'insert into #LASTAGGTIME(MachineID,MachineInt,LastAggstart,LastAggHourID,LastAggHourStart,LastAggHourEnd,lASTAGGDATE,LASTAGGSHIFTID)
	select T1.Machineid,T1.Mint,T1.LastAggstart,
	case when S.Starttime=T1.LastAggstart then S.HourId else ''' + @firstHour + ''' end as LastAggHourID,
	case when  T1.LastAggstart=''01-01-2000 12:00:00 AM'' then '''+ convert(nvarchar(20),@FirstStartTime,120) +''' else S.HourStart end,
	case when  T1.LastAggstart=''01-01-2000 12:00:00 AM'' then  ''' + convert(nvarchar(20),@FirstEndTime,120) +''' else S.HourEnd end,
	T1.lastdate,case when  T1.LastAggstart=''01-01-2000 12:00:00 AM'' then ''' + @firstShift + ''' else S.Shift end
	 from HourAggTrail S right outer join (
	SELECT case when max(S.aggdate) is null then  '''+ convert(nvarchar(20),@FromDate,120) +''' else max(S.aggdate) end as lastdate,M.Machineid,
	case when max(S.Starttime) is not null then max(S.Starttime) else ''01-01-2000 12:00:00 AM'' end as LastAggstart,
	M.Interfaceid as Mint
	 from Machineinformation M
	left outer join HourAggTrail as S on M.Machineid=S.Machineid where M.devicetype=''5'' '
	--where M.Machineid in (select distinct machineid from tcs_energyconsumption)
	select @StrSql = @StrSql + @strMachine
	select @StrSql = @StrSql + 'group by M.Machineid,M.Interfaceid)  T1 on T1.Machineid=S.Machineid  and T1.lastdate=S.aggdate  and S.Starttime=T1.LastAggstart '
	print (@StrSql)
	exec(@StrSql)

	
	--select * from #LASTAGGTIME
	Declare @Mdate as datetime
	Declare @MShift as int
	Declare @AMachine as nvarchar(50)
	Declare @curLastAggstart as datetime
	Declare @HourID as int
	
	declare @CurStrtTime as datetime
	declare @CurEndTime as datetime
	declare @MachineInt as nvarchar(50)
	---In the following lines we are preparing the temp table which contains the date,  shift,hour  and LastAggregated time stamp, and machine
	
	Declare TemplateHour CURSOR FOR
	SELECT distinct MachineID,MachineInt,lASTAGGDATE,LASTAGGSHIFTID,LastAggstart,LastAggHourID
				  from #LASTAGGTIME order by MachineID
	OPEN TemplateHour
	FETCH NEXT FROM TemplateHour INTO @AMachine,@MachineInt,@Mdate,@MShift,@curLastAggstart,@HourID
		
	print @mdate
	print @enddate
	 WHILE (@@fetch_status = 0)
	  BEGIN
		
		select @CurStrtTime=@Mdate
		select @CurEndTime=@EndDate
				
		---get shiftdefinition for all the days
		while @CurStrtTime<=@EndDate
		begin
			insert into #GetFinalHourAggData
			(dDate ,ShiftName ,ShiftID ,HourId ,HourStartTime ,HourEndTime ,MachineID,
			McInterface,ProdTime ,Components ,Energy_KWH,PF ,KW ,Ampere ,Cost ,LastAggstart)
			select convert(nvarchar(20),@CurStrtTime,111),Shiftdetails.shiftname,Shiftdetails.shiftid,Shifthourdefinition.HourID,
			case when Shifthourdefinition.fromday = 0 then cast((cast(datepart(yyyy,@CurStrtTime) as nvarchar(20))+'-'+cast(datepart(m,@CurStrtTime) as nvarchar(20))+'-'+cast(datepart(dd,@CurStrtTime) as nvarchar(20))+' '+cast(datepart(hh,hourStart) as nvarchar(20))+':'+cast(datepart(n,hourStart) as nvarchar(20))+':'+cast(datepart(s,hourStart) as nvarchar(20))) as DateTime)
				 when Shifthourdefinition.fromday = 1 then cast((cast(datepart(yyyy,@CurStrtTime) as nvarchar(20))+'-'+cast(datepart(m,@CurStrtTime) as nvarchar(20))+'-'+cast(datepart(dd,@CurStrtTime) as nvarchar(20))+' '+cast(datepart(hh,hourStart) as nvarchar(20))+':'+cast(datepart(n,hourStart) as nvarchar(20))+':'+cast(datepart(s,hourStart) as nvarchar(20))) as DateTime)+1
			end as FromTime,
			case when Shifthourdefinition.today = 0 then cast((cast(datepart(yyyy,@CurStrtTime) as nvarchar(20))+'-'+cast(datepart(m,@CurStrtTime) as nvarchar(20))+'-'+cast(datepart(dd,@CurStrtTime) as nvarchar(20))+' '+cast(datepart(hh,hourEnd) as nvarchar(20))+':'+cast(datepart(n,hourEnd) as nvarchar(20))+':'+cast(datepart(s,hourEnd) as nvarchar(20))) as DateTime)
				 when Shifthourdefinition.today = 1 then cast((cast(datepart(yyyy,@CurStrtTime) as nvarchar(20))+'-'+cast(datepart(m,@CurStrtTime) as nvarchar(20))+'-'+cast(datepart(dd,@CurStrtTime) as nvarchar(20))+' '+cast(datepart(hh,hourEnd) as nvarchar(20))+':'+cast(datepart(n,hourEnd) as nvarchar(20))+':'+cast(datepart(s,hourEnd) as nvarchar(20))) as DateTime)+1
			end as ToTime,@AMachine,@MachineInt,0,0,0,0,0,0,0,@curLastAggstart
			From Shifthourdefinition inner join shiftdetails on Shifthourdefinition.shiftid=shiftdetails.shiftid
			where  shiftdetails.running = 1
			order by Shifthourdefinition.ShiftID, Shifthourdefinition.HourID
	
			SELECT @CurStrtTime=DATEADD(DAY,1,@CurStrtTime)
		end
		
		
		
	 FETCH NEXT FROM TemplateHour INTO @AMachine,@MachineInt,@Mdate,@MShift,@curLastAggstart,@HourID
	  end
	
	close TemplateHour
	deallocate TemplateHour
	
	---delete the Machine and hour for which aggregation is already done.
	delete from #GetFinalHourAggData where LastAggstart>=HourEndTime
	
-- Get the utilised time
--mod 4
-- Type 1,2,3,4
UPDATE #GetFinalHourAggData SET ProdTime = isnull(ProdTime,0) + isNull(t2.cycle,0)
from
(select      mc,
	sum(case when ( (autodata.msttime>=H.HourStartTime) and (autodata.ndtime<=H.HourEndTime)) then  (cycletime+loadunload)
		 when ((autodata.msttime<H.HourStartTime)and (autodata.ndtime>H.HourStartTime)and (autodata.ndtime<=H.HourEndTime)) then DateDiff(second, H.HourStartTime, ndtime)
		 --when ((autodata.msttime>=H.HourStartTime)and (autodata.msttime<H.HourEndTime)and (autodata.ndtime>H.HourEndTime)) then DateDiff(second, stTime, H.HourEndTime) --DR0304 Commented
		 when ((autodata.msttime>=H.HourStartTime)and (autodata.msttime<H.HourEndTime)and (autodata.ndtime>H.HourEndTime)) then DateDiff(second, mstTime, H.HourEndTime)  --DR0304 Added
		 when ((autodata.msttime<H.HourStartTime)and (autodata.ndtime>H.HourEndTime)) then DateDiff(second, H.HourStartTime, H.HourEndTime) END ) as cycle,H.HourStartTime as HourStart,
		H.HourEndTime as HourEnd, H.dDate as dDate,H.HourId as hourid,H.ShiftID as Shiftid
from autodata inner join #GetFinalHourAggData H on autodata.mc=H.McInterface
where (autodata.datatype=1) AND(( (autodata.msttime>=H.HourStartTime) and (autodata.ndtime<=H.HourEndTime))
OR ((autodata.msttime<H.HourStartTime)and (autodata.ndtime>H.HourStartTime)and (autodata.ndtime<=H.HourEndTime))
OR ((autodata.msttime>=H.HourStartTime)and (autodata.msttime<H.HourEndTime)and (autodata.ndtime>H.HourEndTime))
OR((autodata.msttime<H.HourStartTime)and (autodata.ndtime>H.HourEndTime)))
group by autodata.mc,H.HourStartTime,H.HourEndTime,H.dDate,H.ShiftID,H.HourId
) as t2 inner join #GetFinalHourAggData on t2.mc = #GetFinalHourAggData.McInterface
and t2.HourStart=#GetFinalHourAggData.HourStartTime and T2.HourEnd=#GetFinalHourAggData.HourEndTime
--and T2.Ddate=#GetFinalHourAggData.dDate and T2.Shiftid=#GetFinalHourAggData.Hourid and T2.Hourid=#GetFinalHourAggData.HourId --DR0304 Commented
and T2.Ddate=#GetFinalHourAggData.dDate and T2.Shiftid=#GetFinalHourAggData.Shiftid and T2.Hourid=#GetFinalHourAggData.HourId --DR04304 Added
--Remove ICD from ProdTime
if (select count(*) from autodata where datediff(second,sttime,ndtime)>Cycletime )>0
begin
	UPDATE #GetFinalHourAggData SET ProdTime = isnull(ProdTime,0) - isNull(t2.Down,0)
	FROM
	(Select AutoData.mc ,
	SUM(
	CASE
		When autodata.sttime <= H.HourStartTime Then datediff(s, H.HourStartTime,autodata.ndtime )
		When autodata.sttime > H.HourStartTime Then datediff(s , autodata.sttime,autodata.ndtime)
	END) as Down,H.HourStartTime as HourStart,
		H.HourEndTime as HourEnd, H.dDate as dDate,H.HourId as hourid,H.ShiftID as Shiftid
	From AutoData INNER Join
--ER0340 Commented from here
--		(Select mc,Sttime,NdTime From AutoData inner join #GetFinalHourAggData H on
--			H.McInterface=autodata.mc
--			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
--			--(sttime < H.HourStartTime)And (ndtime > H.HourStartTime) AND (ndtime <= H.HourEndTime) ) as T1 --DR0304 Commented
--			  (msttime < H.HourStartTime)And (ndtime > H.HourStartTime) AND (ndtime <= H.HourEndTime) ) as T1 --DR0304 Added
--	ON AutoData.mc=T1.mc inner join #GetFinalHourAggData H on
--			H.McInterface=autodata.mc
--ER0340 Commented from here
	--ER0340 Added from here
(Select mc,Sttime,NdTime,H.HourStartTime,H.HourEndTime From AutoData inner join #GetFinalHourAggData H on
			H.McInterface=autodata.mc
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			--(sttime < H.HourStartTime)And (ndtime > H.HourStartTime) AND (ndtime <= H.HourEndTime) ) as T1 --DR0304 Commented
			  (msttime < H.HourStartTime)And (ndtime > H.HourStartTime) AND (ndtime <= H.HourEndTime) ) as T1 --DR0304 Added
	ON AutoData.mc=T1.mc inner join #GetFinalHourAggData H on
			H.McInterface=autodata.mc and T1.HourStartTime=H.HourStartTime and T1.HourEndTime=H.HourEndTime	
	--ER0340 Added till here
	Where AutoData.DataType=2
	And ( autodata.Sttime > T1.Sttime )
	And ( autodata.ndtime <  T1.ndtime )
	AND ( autodata.ndtime >  H.HourStartTime )
	GROUP BY AUTODATA.mc,H.HourStartTime,H.HourEndTime,H.dDate,H.ShiftID,H.HourId)as t2 inner join #GetFinalHourAggData on t2.mc = #GetFinalHourAggData.McInterface
	and t2.HourStart=#GetFinalHourAggData.HourStartTime and T2.HourEnd=#GetFinalHourAggData.HourEndTime
	 and T2.Ddate=#GetFinalHourAggData.dDate and T2.Shiftid=#GetFinalHourAggData.Shiftid and T2.Hourid=#GetFinalHourAggData.HourId
	
	/* If Down Records of TYPE-3*/
	UPDATE #GetFinalHourAggData SET ProdTime = isnull(ProdTime,0) - isNull(t2.Down,0)
	FROM
	(Select AutoData.mc ,
	SUM(CASE
		When autodata.ndtime > H.HourEndTime Then datediff(s,autodata.sttime, H.HourEndTime )
		When autodata.ndtime <=H.HourEndTime Then datediff(s , autodata.sttime,autodata.ndtime)
	END) as Down,H.HourStartTime as HourStart,H.HourEndTime as HourEnd,H.dDate,H.ShiftID,H.HourId
	From AutoData INNER Join
	
--	  --ER0340 Commented from here
--		(Select mc,Sttime,NdTime From AutoData inner join #GetFinalHourAggData H on
--			H.McInterface=autodata.mc
--			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
--			--(sttime >= H.HourStartTime)And (ndtime > H.HourEndTime)) as T1 --DR0304 Commented
--			  (sttime >= H.HourStartTime And sttime<H.HourEndTime and ndtime > H.HourEndTime)) as T1 --DR0304 Added
--	ON AutoData.mc=T1.mc inner join #GetFinalHourAggData H on
--			H.McInterface=autodata.mc
--	  --ER0340 Commented from here
	  --ER0340 Added from here
	 (Select mc,Sttime,NdTime,H.HourStartTime,H.HourEndTime From AutoData inner join #GetFinalHourAggData H on
			H.McInterface=autodata.mc
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			--(sttime >= H.HourStartTime)And (ndtime > H.HourEndTime)) as T1 --DR0304 Commented
			  (sttime >= H.HourStartTime And sttime<H.HourEndTime and ndtime > H.HourEndTime)) as T1 --DR0304 Added
	        ON AutoData.mc=T1.mc inner join #GetFinalHourAggData H on
			H.McInterface=autodata.mc and T1.HourStartTime=H.HourStartTime and T1.HourEndTime=H.HourEndTime
--ER0340 Added till here
	Where AutoData.DataType=2
	And (T1.Sttime < autodata.sttime  )
	And ( T1.ndtime >  autodata.ndtime)
	AND (autodata.sttime  <  H.HourEndTime)
	GROUP BY AUTODATA.mc,H.HourStartTime,H.HourEndTime,H.dDate,H.ShiftID,H.HourId)as t2 inner join #GetFinalHourAggData on t2.mc = #GetFinalHourAggData.McInterface
	and t2.HourStart=#GetFinalHourAggData.HourStartTime and T2.HourEnd=#GetFinalHourAggData.HourEndTime
	 and T2.Ddate=#GetFinalHourAggData.dDate and T2.Shiftid=#GetFinalHourAggData.Shiftid and T2.Hourid=#GetFinalHourAggData.HourId
	/* If Down Records of TYPE-4*/
	UPDATE #GetFinalHourAggData SET ProdTime = isnull(ProdTime,0) - isNull(t2.Down,0)
	FROM
	(Select AutoData.mc ,
	--DR0236 - By SwathiKS on 23-Jun-2010 FROM HERE
--	SUM(CASE
--		When autodata.sttime < H.HourStartTime AND autodata.ndtime<=H.HourEndTime Then datediff(s, H.HourStartTime,autodata.ndtime )
--		When autodata.ndtime >= H.HourEndTime AND autodata.sttime>H.HourStartTime Then datediff(s,autodata.sttime, H.HourEndTime )
--		When autodata.sttime >= H.HourStartTime AND
--		     autodata.ndtime <= H.HourEndTime Then datediff(s , autodata.sttime,autodata.ndtime)
--		When autodata.sttime<H.HourStartTime AND autodata.ndtime>H.HourEndTime   Then datediff(s , H.HourStartTime,H.HourEndTime)
--	END) as Down,H.HourStartTime as HourStart,H.HourEndTime as HourEnd,H.dDate,H.ShiftID,H.HourId
	SUM(CASE
		When autodata.sttime >= H.HourStartTime AND autodata.ndtime <= H.HourEndTime Then datediff(s , autodata.sttime,autodata.ndtime) --Type1
		When autodata.sttime < H.HourStartTime AND autodata.ndtime>H.HourStartTime AND autodata.ndtime<=H.HourEndTime Then datediff(s, H.HourStartTime,autodata.ndtime )--Type2
		When autodata.sttime>=H.HourStartTime AND autodata.sttime<H.HourEndTime AND autodata.ndtime > H.HourEndTime  Then datediff(s,autodata.sttime, H.HourEndTime ) --Type3
		When autodata.sttime<H.HourStartTime AND autodata.ndtime>H.HourEndTime   Then datediff(s , H.HourStartTime,H.HourEndTime) --Type4
	END) as Down,H.HourStartTime as HourStart,H.HourEndTime as HourEnd,H.dDate,H.ShiftID,H.HourId
	--DR0236 - By SwathiKS on 23-Jun-2010 TILL HERE
	From AutoData INNER Join
--ER0340 Commented From here
--		(Select mc,Sttime,NdTime From AutoData inner join #GetFinalHourAggData H on
--			H.McInterface=autodata.mc
--			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
--			(sttime < H.HourStartTime)And (ndtime > H.HourEndTime) ) as T1
--	ON AutoData.mc=T1.mc inner join #GetFinalHourAggData H on
--			H.McInterface=autodata.mc
--ER0340 Commented From here
	 --ER0340 Added from here
	(Select mc,Sttime,NdTime,H.HourStartTime,H.HourEndTime From AutoData inner join #GetFinalHourAggData H on
			H.McInterface=autodata.mc
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(msttime < H.HourStartTime)And (ndtime > H.HourEndTime) ) as T1
	ON AutoData.mc=T1.mc inner join #GetFinalHourAggData H on
			H.McInterface=autodata.mc and T1.HourStartTime=H.HourStartTime and T1.HourEndTime=H.HourEndTime
	--ER0340 Added till here
	
	Where AutoData.DataType=2
	And (T1.Sttime < autodata.sttime  )
	And ( T1.ndtime >  autodata.ndtime)
	AND (autodata.ndtime  >  H.HourStartTime)
	AND (autodata.sttime  <  H.HourEndTime)
	GROUP BY AUTODATA.mc,H.HourStartTime,H.HourEndTime,H.dDate,H.ShiftID,H.HourId
	)as t2 inner join #GetFinalHourAggData on t2.mc = #GetFinalHourAggData.McInterface
	and t2.HourStart=#GetFinalHourAggData.HourStartTime and T2.HourEnd=#GetFinalHourAggData.HourEndTime
	and T2.Ddate=#GetFinalHourAggData.dDate and T2.Shiftid=#GetFinalHourAggData.Shiftid and T2.Hourid=#GetFinalHourAggData.HourId
	
END
---Get the Count for the hours
UPDATE #GetFinalHourAggData SET components = ISNULL(components,0) + ISNULL(t2.comp,0)From(
	select Autodata.mc,#GetFinalHourAggData.HourStartTime as HourStart,#GetFinalHourAggData.HourEndTime as HourEnd,
	SUM(CEILING(CAST(autodata.partscount AS Float)/ISNULL(O.SubOperations,1))) as comp,
	 #GetFinalHourAggData.dDate as dDate,#GetFinalHourAggData.HourId as hourid,#GetFinalHourAggData.ShiftID as Shiftid
	from autodata
	inner join #GetFinalHourAggData on autodata.mc = #GetFinalHourAggData.McInterface
	Inner join componentinformation C on autodata.Comp = C.interfaceid
	Inner join ComponentOperationPricing O ON  autodata.Opn = O.interfaceid and C.Componentid=O.componentid
	inner join machineinformation on machineinformation.machineid =O.machineid and autodata.mc=machineinformation.interfaceid
	Where Autodata.datatype = 1
	and Autodata.ndtime > #GetFinalHourAggData.HourStartTime and Autodata.ndtime <= #GetFinalHourAggData.HourEndTime
	Group by Autodata.mc,#GetFinalHourAggData.HourStartTime,#GetFinalHourAggData.HourEndTime,
	#GetFinalHourAggData.dDate,#GetFinalHourAggData.ShiftID,#GetFinalHourAggData.HourId
)  t2 inner join #GetFinalHourAggData on t2.mc = #GetFinalHourAggData.McInterface
	and t2.HourStart=#GetFinalHourAggData.HourStartTime and T2.HourEnd=#GetFinalHourAggData.HourEndTime
	and T2.Ddate=#GetFinalHourAggData.dDate and T2.Shiftid=#GetFinalHourAggData.Shiftid and T2.Hourid=#GetFinalHourAggData.HourId
	

--Look for exceptions if any
	Insert into #Exceptions
	select machineinformation.MachineID,C.componentid,O.operationNo,
	#GetFinalHourAggData.HourStartTime,#GetFinalHourAggData.HourEndTime,
	Case when pce.StartTime <= #GetFinalHourAggData.HourStartTime then #GetFinalHourAggData.HourStartTime else pce.StartTime End as ExStartTime,
	Case when pce.EndTime >= #GetFinalHourAggData.HourEndTime then #GetFinalHourAggData.HourEndTime else pce.EndTime End as ExEndTime,0,
	isnull(ActualCount,0),Isnull(IdealCount,1),#GetFinalHourAggData.dDate,#GetFinalHourAggData.Shiftid,#GetFinalHourAggData.HourId
	from #GetFinalHourAggData
	Inner join machineinformation on #GetFinalHourAggData.MachineID = machineinformation.machineid
	Inner join ComponentOperationPricing O ON  machineinformation.machineid=O.machineid
	Inner join componentinformation C on C.Componentid=O.componentid
	Inner join ProductionCountException pce on pce.machineID = #GetFinalHourAggData.MachineID and pce.ComponentID = C.Componentid and pce.OperationNo = O.OperationNo
	Where ((#GetFinalHourAggData.HourStartTime >= pce.StartTime and #GetFinalHourAggData.HourEndTime <= pce.EndTime)or
	(#GetFinalHourAggData.HourStartTime < pce.StartTime and #GetFinalHourAggData.HourEndTime > pce.StartTime and #GetFinalHourAggData.HourEndTime <=pce.EndTime)or
	(#GetFinalHourAggData.HourStartTime >= pce.StartTime and #GetFinalHourAggData.HourStartTime <pce.EndTime and #GetFinalHourAggData.HourEndTime > pce.EndTime) or
	(#GetFinalHourAggData.HourStartTime < pce.StartTime and #GetFinalHourAggData.HourEndTime > pce.EndTime)
	)
	
	if (select count(*) from #Exceptions) > 0
	Begin
		---get the exception count
		UPDATE #Exceptions SET ExCount = ISNULL(ExCount,0) + (floor(ISNULL(t2.comp,0) * ISNULL(ActualCount,0))/ISNULL(IdealCount,0)) From(
			select M.MachineID,C.componentid,O.operationNo,#Exceptions.ExStartTime,#Exceptions.ExEndTime,
			SUM(CEILING(CAST(autodata.partscount AS Float)/ISNULL(O.SubOperations,1))) as comp
			from autodata
			inner join machineinformation M on autodata.mc=M.interfaceid
			Inner join componentinformation C on autodata.Comp = C.interfaceid
			Inner join ComponentOperationPricing O ON  autodata.Opn = O.interfaceid and C.Componentid=O.componentid and M.MachineID = O.MachineID
			inner join #Exceptions on  #Exceptions.machineId = M.MachineID and #Exceptions.Componentid = C.componentid and #Exceptions.OperationNo = O.OperationNo
			Where Autodata.datatype = 1	and Autodata.ndtime > #Exceptions.ExStartTime and Autodata.ndtime <= #Exceptions.ExEndTime
			Group by M.MachineID,C.componentid,O.operationNo,#Exceptions.ExStartTime,#Exceptions.ExEndTime
		) As T2 Inner join #Exceptions on T2.MachineID = #Exceptions.MachineID and T2.componentid = #Exceptions.componentid
		and T2.operationNo = #Exceptions.operationNo and T2.ExStartTime = #Exceptions.ExStartTime and T2.ExEndTime = #Exceptions.ExEndTime
		
		---update the table for the exceptions
		Update #GetFinalHourAggData set components = ISNULL(components,0) - ISNULL(ExCount,0) from (
			Select machineid,StartTime,EndTime,EXDate ,EXShiftId ,EXHrID,	sum(ExCount) as ExCount from #Exceptions
			group by machineid,StartTime,EndTime,EXDate ,EXShiftId ,EXHrID
		) as t1 inner join #GetFinalHourAggData on t1.machineid = #GetFinalHourAggData.MachineID and t1.StartTime = #GetFinalHourAggData.HourStartTime and t1.EndTime = #GetFinalHourAggData.HourEndTime
		and T1.EXDate=#GetFinalHourAggData.dDate and T1.EXShiftId=#GetFinalHourAggData.Shiftid and T1.EXHrID=#GetFinalHourAggData.HourId
	End



---Update the table for avg PF, Energy, Avg Ampere, cost and Avg KW
Update #GetFinalHourAggData
set #GetFinalHourAggData.PF = ISNULL(#GetFinalHourAggData.PF,0)+ISNULL(t1.PF,0),
--#GetFinalHourAggData.Energy_KWH = ISNULL(#GetFinalHourAggData.Energy_KWH,0)+ISNULL(t1.kwh,0),
--#GetFinalHourAggData.Cost = ISNULL(#GetFinalHourAggData.Cost,0)+ ISNULL((t1.kwh )* (Select max(Valueintext) from shopdefaults where Parameter = 'CostPerKWH'),0),
#GetFinalHourAggData.KW=isnull(t1.kw,0),
#GetFinalHourAggData.Ampere=isnull(t1.ampere,0)
from (
	select tcs_energyconsumption.MachineiD,HourStartTime,HourEndTime,
	--avg(tcs_energyconsumption.pf) as PF, --Swathi Commented
	round(avg(Abs(tcs_energyconsumption.pf)),5) as PF, --Swathi Commented
	round(isnull(max(tcs_energyconsumption.kwh),0)-isnull(min(tcs_energyconsumption.kwh),0),5) as kwh,
	round(avg(tcs_energyconsumption.Watt),5) as KW,
	round(avg(tcs_energyconsumption.Ampere),5) as Ampere,#GetFinalHourAggData.ddate as ddate,#GetFinalHourAggData.Hourid as hourid,#GetFinalHourAggData.shiftid as shiftid from tcs_energyconsumption inner join #GetFinalHourAggData on
	tcs_energyconsumption.machineID = #GetFinalHourAggData.MachineID and tcs_energyconsumption.gtime >= #GetFinalHourAggData.HourStartTime
	and tcs_energyconsumption.gtime <= #GetFinalHourAggData.HourEndTime 
	--And tcs_energyconsumption.pf >= 0 --Swathi Commented
	group by tcs_energyconsumption.MachineiD,HourStartTime,HourEndTime,#GetFinalHourAggData.dDate,
	#GetFinalHourAggData.shiftid,#GetFinalHourAggData.hourid
) as t1 inner join #GetFinalHourAggData on t1.machineiD = #GetFinalHourAggData.machineID and
t1.HourStartTime = #GetFinalHourAggData.HourStartTime and t1.HourEndTime = #GetFinalHourAggData.HourEndTime
and T1.Ddate=#GetFinalHourAggData.dDate and T1.Shiftid=#GetFinalHourAggData.Shiftid and T1.Hourid=#GetFinalHourAggData.HourId


Update #GetFinalHourAggData
set #GetFinalHourAggData.minenergykwh = ISNULL(#GetFinalHourAggData.minenergykwh,0)+ISNULL(t2.kwh,0)
from
(
select T1.MachineiD,T1.HourStartTime,T1.HourEndTime,
round(kwh,2) as kwh,T1.ddate,T1.hourid,T1.shiftid from
(
	select tcs_energyconsumption.MachineiD,HourStartTime,HourEndTime,
	min(gtime) as mingtime,#GetFinalHourAggData.ddate as ddate,#GetFinalHourAggData.Hourid as hourid,#GetFinalHourAggData.shiftid as shiftid from tcs_energyconsumption inner join #GetFinalHourAggData on
	tcs_energyconsumption.machineID = #GetFinalHourAggData.MachineID and tcs_energyconsumption.gtime >= #GetFinalHourAggData.HourStartTime
	and tcs_energyconsumption.gtime <= #GetFinalHourAggData.HourEndTime 
	group by tcs_energyconsumption.MachineiD,HourStartTime,HourEndTime,#GetFinalHourAggData.dDate,
	#GetFinalHourAggData.shiftid,#GetFinalHourAggData.hourid
) as t1 inner join tcs_energyconsumption on tcs_energyconsumption.gtime=t1.mingtime
) as T2
inner join #GetFinalHourAggData on T2.machineiD = #GetFinalHourAggData.machineID and
T2.HourStartTime = #GetFinalHourAggData.HourStartTime and T2.HourEndTime = #GetFinalHourAggData.HourEndTime
and T2.Ddate=#GetFinalHourAggData.dDate and T2.Shiftid=#GetFinalHourAggData.Shiftid and T2.Hourid=#GetFinalHourAggData.HourId


Update #GetFinalHourAggData
set #GetFinalHourAggData.MAXenergykwh = ISNULL(#GetFinalHourAggData.MAXenergykwh,0)+ISNULL(t2.kwh,0)
from
(
select T1.MachineiD,T1.HourStartTime,T1.HourEndTime,
round(kwh,2) as kwh,T1.ddate,T1.hourid,T1.shiftid from
(
	select tcs_energyconsumption.MachineiD,HourStartTime,HourEndTime,
	max(gtime) as maxgtime,#GetFinalHourAggData.ddate as ddate,#GetFinalHourAggData.Hourid as hourid,#GetFinalHourAggData.shiftid as shiftid from tcs_energyconsumption inner join #GetFinalHourAggData on
	tcs_energyconsumption.machineID = #GetFinalHourAggData.MachineID and tcs_energyconsumption.gtime >= #GetFinalHourAggData.HourStartTime
	and tcs_energyconsumption.gtime <= #GetFinalHourAggData.HourEndTime 
	group by tcs_energyconsumption.MachineiD,HourStartTime,HourEndTime,#GetFinalHourAggData.dDate,
	#GetFinalHourAggData.shiftid,#GetFinalHourAggData.hourid
) as t1 inner join tcs_energyconsumption on tcs_energyconsumption.gtime=t1.maxgtime
) as T2
inner join #GetFinalHourAggData on T2.machineiD = #GetFinalHourAggData.machineID and
T2.HourStartTime = #GetFinalHourAggData.HourStartTime and T2.HourEndTime = #GetFinalHourAggData.HourEndTime
and T2.Ddate=#GetFinalHourAggData.dDate and T2.Shiftid=#GetFinalHourAggData.Shiftid and T2.Hourid=#GetFinalHourAggData.HourId


Update #GetFinalHourAggData
set 
#GetFinalHourAggData.Energy_KWH = ISNULL(#GetFinalHourAggData.Energy_KWH,0)+ISNULL(t2.kwh,0)
from
(
select MachineiD,hourStartTime,HourEndTime,
round((maxenergykwh-minenergykwh),2) as kwh,ddate,hourid,shiftid
from #GetFinalHourAggData
) as T2
inner join #GetFinalHourAggData on T2.machineiD = #GetFinalHourAggData.machineID and
T2.HourStartTime = #GetFinalHourAggData.HourStartTime and T2.HourEndTime = #GetFinalHourAggData.HourEndTime
and T2.Ddate=#GetFinalHourAggData.dDate and T2.Shiftid=#GetFinalHourAggData.Shiftid and T2.Hourid=#GetFinalHourAggData.HourId


update #GetFinalHourAggData set Cost = ISNULL(#GetFinalHourAggData.Cost,0)+ ISNULL((Energy_KWH )* (Select max(Valueintext) from shopdefaults where Parameter = 'CostPerKWH'),0)


declare @Pshift as nvarchar(50)
declare @Pdate as datetime
declare @PHourStart as datetime
declare @PHourEnd as datetime
declare @Machine nvarchar(50)
declare @PShiftId nvarchar(50)
declare @PshiftName nvarchar(50)
declare @PhourId as int
	
	
	Declare RptHourCursor CURSOR FOR
	SELECT distinct dDate ,ShiftName ,ShiftID ,HourId ,
			HourStartTime ,HourEndTime ,MachineID
				from #GetFinalHourAggData    order by MAchineid,HourStartTime asc
	OPEN RptHourCursor
	FETCH NEXT FROM RptHourCursor INTO @Pdate,@PshiftName,@PShiftId,@PhourId,@PHourStart,@PHourEnd,@Machine
	 WHILE (@@fetch_status = 0)
	  BEGIN
	    if exists (select * from EnergyCockpit where dDate=@Pdate and dShift=@PShiftId and dHour=@PhourId and Machineid=@Machine)
	    begin


			---If Date , shift, hour and Machine combination exists in table, update the values
			UPDATE  [EnergyCockpit] set
			Starttime=@PHourStart, [Endtime]=@PHourEnd , [ProdTime]=T1.ProdTime, [pCount]=T1.Components, [Energy]=T1.Energy_KWH
			, [Cost]=T1.Cost, [PF]=T1.PF, [Ampere]=T1.Ampere, [KW]=T1.KW
			from ( select dDate ,ShiftName ,ShiftID ,HourId ,
			HourStartTime ,HourEndTime ,MachineID,ProdTIme,Components,Energy_KWH,PF,Cost,Ampere,KW
			from #GetFinalHourAggData  where dDate=@Pdate and ShiftID=@PShiftId and HourId=@PhourId
			 and MachineID=@Machine) T1 inner join EnergyCockpit on
			EnergyCockpit.dDate=T1.dDate and EnergyCockpit.dShift=T1.ShiftId and EnergyCockpit.dHour=T1.HourId
			 and EnergyCockpit.Machineid=T1.MachineID
			where EnergyCockpit.dDate=@Pdate and EnergyCockpit.dShift=@PShiftId and EnergyCockpit.dHour=@PhourId and EnergyCockpit.Machineid=@Machine
			set @ErrNo=@@ERROR
			IF @ErrNo <> 0
			BEGIN
				close RptHourCursor  --Close the cursor
				deallocate RptHourCursor --Deallocate the cursor
			 	GOTO ERROR_HANDLER -- go to error handler
			END
			
							
	    end
	    else
	    begin
			
		
		---else insert the values
		 INSERT INTO [EnergyCockpit]([dDate], [dShift], [dHour], [Starttime],
			[Endtime], [MachineID], [ProdTime], [pCount], [Energy], [Cost], [PF],
			[Ampere], [KW])
			select dDate,ShiftID ,HourId,HourStartTime ,HourEndTime ,MachineID,
			ProdTime ,Components ,Energy_KWH ,Cost,PF ,Ampere ,KW
			from #GetFinalHourAggData  where dDate=@Pdate and ShiftID=@PShiftId and
			 HourId=@PhourId
			 and MachineID=@Machine
			set @ErrNo=@@ERROR
			IF @ErrNo <> 0
			BEGIN
				close RptHourCursor  --Close the cursor
				deallocate RptHourCursor --Deallocate the cursor
			 	GOTO ERROR_HANDLER -- go to error handler
			END
			
	    end
	  FETCH NEXT FROM RptHourCursor INTO @Pdate,@PshiftName,@PShiftId,@PhourId,@PHourStart,@PHourEnd,@Machine
	
	  END
	close RptHourCursor
	deallocate RptHourCursor
---Isert into last aggregated trail table
select @StrSql=''
	select @StrSql=' insert into HourAggTrail([Machineid], [Shift], [HourStart], [HourEnd],
			 [HourID], [Aggdate], [Starttime], [AggregateTS])
	 select T.machineID,T.ShiftID,T.HourStartTime,T.HourEndTime,T.HourID,T.ddate,
	case when max(A.gtime)>T.HourEndTime then T.HourEndTime else max(A.gtime) end ,
	''' + convert(nvarchar(20),getdate(),120)+'''	from
	#GetFinalHourAggData T inner join tcs_energyconsumption  A on A.machineID = T.MachineID
	WHERE
	(A.gtime>=T.HourStartTime And A.gtime<=T.HourEndTime)
	'
	--mod 1
	--SELECT @StrSql = @StrSql + ' and A.gtime >= T.LastAggstart '
	SELECT @StrSql = @StrSql + ' and A.gtime > T.LastAggstart '
	---mod 1
	select @StrSql=@StrSql + 'group by T.machineID,T.ShiftID,T.HourStartTime,T.HourEndTime,T.HourID,T.ddate
				order by T.machineID,T.HourStartTime'
	--print @strsql
	exec (@StrSql)
			set @ErrNo=@@ERROR
			IF @ErrNo <> 0	 GOTO ERROR_HANDLER -- go to error handler
			
---select * from #GetFinalHourAggData order by Machineid,HourStarttime
select @@TRANCOUNT
while @@TRANCOUNT <> 0
		COMMIT TRANSACTION
	RETURN 	
ERROR_HANDLER:
	IF @@TRANCOUNT <> 0 ROLLBACK TRANSACTION
	select @ErrNo
insert into aggregate_Error(ErrNo,Machineid,StartDate,EndDate)
values(@ErrNo,'Hour Energy Aggregation',@FromDate,@EndDate)
	RETURN
END
