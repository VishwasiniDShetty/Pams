/****** Object:  Procedure [dbo].[s_GetShiftAgg_prodcount]    Committed by VersionSQL https://www.versionsql.com ******/

--ER0169 :: This Procedure is created by Karthik G on 06-Feb-2009
	--Generate a report  that gives shiftwise actual count, daywise actual count and daywise target along with the graph.
	--The graph will be at day level showing both target and actual value.
	--The report should be generated for the selected month and machine.
-- This Procedure is used in SmartManager->Shift Aggregated Reports -> ProductionReport-Machinewise (Month) -> AggProductionCountMonthlyTemplate.xls

CREATE procedure [dbo].[s_GetShiftAgg_prodcount]
	@dDate datetime,
	@MachineID nvarchar(50)
as
Begin
declare @StartDate as DateTime
declare @EndDate as DateTime
declare @tempdate as DateTime
select @StartDate = cast((cast(datepart(yyyy,@dDate) as varchar(5)) + '-' + cast(datepart(mm,@dDate) as varchar(5)) + '-' + '1') as datetime)
select @EndDate =  dateadd(d,-1,dateadd(m,1,@StartDate))
CREATE TABLE #tempdate(pDate DateTime)
CREATE TABLE #tempshift(Shift nvarchar(50),ShiftID nvarchar(50))
CREATE TABLE #temptable
(
	pDate DateTime,
	Shift nvarchar(50),
	ShiftID nvarchar(50),
	ActualCount int,
	TargetCount int
)
	insert into #tempshift (Shift,ShiftID)select shiftName,ShiftID from shiftdetails where running = 1 order by shiftid
	select @tempdate = @StartDate
	
	while @tempdate <= @EndDate
	Begin
		insert into #tempdate (pDate)select @tempdate
		Select @tempdate = dateadd(d,1,@tempdate)
	End
--s_GetShiftAgg_prodcount '2008-09-01','5I01'
--select * from #tempshift
--select * from #tempdate cross join #tempshift
	insert into #temptable (pDate,Shift,ShiftID) select * from #tempdate cross join #tempshift
	update #temptable set ActualCount = isnull(t1.acount,0) from(
		select pDate,Shift,MachineId,Isnull(sum(AcceptedParts),0) as acount from shiftproductiondetails
		where pdate >= @StartDate and pdate <= @EndDate and MachineID = @MachineID
		group by pDate,Shift,MachineId)
	as t1 inner join #temptable on
	t1.pDate = #temptable.pDate and t1.Shift = #temptable.Shift
--s_GetShiftAgg_prodcount '2009-02-06','ACE VANTAGE'
--	select sdate,shiftid,sum(target) as Target from shifthourtargets where machineid = @MachineID and sdate >= @StartDate and sdate <= @EndDate group by sdate,shiftid
	update #temptable set targetcount = t1.Target from(
		select sdate,sum(target) as Target from shifthourtargets where
		machineid = @MachineID and sdate >= @StartDate and sdate <= @EndDate
		group by sdate
	) as t1 inner join #temptable on t1.sdate = #temptable.pdate
	select pDate,datepart(d,pDate) as pday,Shift,ShiftID,Isnull(ActualCount,0) as ActualCount,Isnull(TargetCount,0) as TargetCount from #temptable
	order by pday,ShiftID
	--s_GetShiftAgg_prodcount '2008-09-01','5I01'
End
