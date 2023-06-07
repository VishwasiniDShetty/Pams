/****** Object:  Procedure [dbo].[s_GetShiftwiseProductionReport]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE   PROCEDURE [dbo].[s_GetShiftwiseProductionReport]
	@StartDate as DateTime,
	@EndDate as DateTime,
	@MachineID as nvarchar(50) = '',
	@ComponentID as nvarchar(50) = '',
	@OperatorID as nvarchar(50) = ''
AS
BEGIN
--Build DateVsShifts
CREATE TABLE #temp1 (
	PDate smalldatetime,
	shift nvarchar(20),
	starttime datetime,
	endtime datetime	
	)
DECLARE @dDate smalldatetime
declare @strdate varchar(20)
SELECT @dDate = @StartDate
WHILE @dDate  <= @EndDate
BEGIN
	/*
	select @strdate = datename(day, @dDate) + '-' + datename(month, @ddate) + '-' + datename(year, @ddate)
	insert into #temp1(Pdate, shift, starttime, endtime) select @dDate, shiftname,
	convert(datetime, @strdate + ' ' + cast(starttime as varchar(2)) + ':00:00'),
	dateadd (hour,noofhrs,(convert(datetime,@strdate + ' ' + cast(starttime as varchar(2)) + ':00:00') ))
	from shiftdetails where running = 1 order by shiftname
	SELECT @dDate = DateAdd(Day, 1, @dDate)
	*/
	INSERT #temp1(Pdate, shift, starttime, endtime)
	EXEC s_GetShiftTime @dDate
	SELECT @dDate = DateAdd(Day, 1, @dDate)
	

END
--Populate Component, Operation, Production, Rejection, Operator for each shift
CREATE TABLE #temp2 (
	PDate smalldatetime,
	shift nvarchar(20),
	ComponentID nvarchar(50),
	OperationID nvarchar(50),
	Production float,
	Rejection float,
	OperatorID nvarchar(50),
	Downtime float
	)
DECLARE CurReport CURSOR FOR
SELECT Pdate, shift, starttime, endtime
FROM #temp1
OPEN CurReport
DECLARE @cstarttime datetime
DECLARE @cendtime datetime
DECLARE @cPdate smalldatetime
DECLARE @cshift nvarchar(20)
FETCH NEXT FROM CurReport INTO @cPdate,@cshift, @cstarttime,@cendtime
WHILE @@FETCH_STATUS = 0
BEGIN
--call asaf1
insert #temp2(pdate, shift, componentid, operationid, Production, Rejection, operatorid, downtime)
exec s_GetShiftwiseComponentOperations @cPdate, @cshift, @cstarttime, @cendtime, @machineid, @componentid, @operatorid
-- This is executed as long as the previous fetch succeeds.
FETCH NEXT FROM CurReport INTO @cPdate, @cshift, @cstarttime, @cendtime
END
CLOSE CurReport
DEALLOCATE CurReport
select * from #temp2 order by Pdate, shift, componentid, operationid
drop table #temp1
drop table #temp2
end
