/****** Object:  Procedure [dbo].[s_GetCurrentShift]    Committed by VersionSQL https://www.versionsql.com ******/

/****************************************************************************************************
NR0083 - Geetanjali Kore - 6/feb/2013 ::To Get the current shift.
*****************************************************************************************************/

CREATE procedure [dbo].[s_GetCurrentShift]
As
Begin
Create table #GetShiftTime
	(
	dDate DateTime,
	ShiftName NVarChar(50),
	StartTime DateTime,
	EndTime DateTime
	)
Declare @gettime as datetime
Declare @gettime1 as datetime
Declare @sttime_1 as datetime
Declare @ndtime_1 as datetime
Declare @ShiftStartTime as datetime
declare @ShiftEndTime as datetime
select @gettime1=(Select getdate())
Select @gettime=(select dbo.f_GetLogicalDaystart(getdate()))
insert into #GetShiftTime Exec s_GetShiftTime @gettime,''
--insert into #GetShiftTime Exec s_GetShiftTime '2013-07-13 05:19:00.000',''
----'2010-07-14 06:00:00.000'
Declare Finder  cursor for
Select StartTime,Endtime from #GetShiftTime order by StartTime
Open Finder
FETCH NEXT FROM Finder INTO @sttime_1,@ndtime_1
while (@@fetch_status= 0)
Begin
If (@gettime1>=@sttime_1 and @gettime1<=@ndtime_1)
begin
select @ShiftStartTime=@sttime_1
Select @ShiftEndTime=@ndtime_1
Print @ShiftStartTime
print @ShiftEndTime
End
FETCH NEXT FROM Finder INTO @sttime_1,@ndtime_1
End
Close Finder
Deallocate Finder
if (@ShiftStartTime<>''  and @ShiftEndTime<>'') 
begin
Select * from #GetShiftTime Where StartTime=@ShiftStartTime and Endtime=@ShiftEndTime
end
--else part:: when two shifts are defined
else
begin
Delete from #GetShiftTime
if(getdate()>(select dbo.f_GetLogicalDaystart(getdate())))
begin 
set @gettime1=(select dbo.f_GetLogicalDaystart(dateadd(day,1,getdate())))
print @gettime1
insert into #GetShiftTime Exec s_GetShiftTime @gettime1,''
Select top 1 *  from #GetShiftTime order by StartTime
end
else

begin
set @gettime1=(select dbo.f_GetLogicalDaystart(getdate()))
insert into #GetShiftTime Exec s_GetShiftTime @gettime1,''
Select top 1 *  from #GetShiftTime order by StartTime
end
end

End
