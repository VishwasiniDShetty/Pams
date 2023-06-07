/****** Object:  Procedure [dbo].[s_GetPreviousShift]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE procedure [dbo].[s_GetPreviousShift]
As
Begin
Create table #GetShiftTime
	(
	dDate DateTime,
	ShiftName NVarChar(50),
	StartTime DateTime,
	EndTime DateTime
	)
Declare @shiftid as smallint
Declare @preday as datetime
Declare @shiftname as nvarchar(50)
Declare @gettime as datetime
Declare @gettime1 as datetime
Declare @sttime_1 as datetime
Declare @ndtime_1 as datetime
Declare @ShiftStartTime as datetime
declare @ShiftEndTime as datetime
select @gettime1=(Select getdate())
Select @gettime=(select dbo.f_GetLogicalDaystart(getdate()))
Select @preday=(select dateadd(day,-1,@gettime))
Select @shiftid=(Select top 1 shiftid from shiftdetails where running=1 order by shiftid desc)
print @preday
Select @shiftname=(Select ShiftName from shiftdetails where running=1 and shiftid=@shiftid)
insert into #GetShiftTime Exec s_GetShiftTime  @preday,@shiftname

insert into #GetShiftTime Exec s_GetShiftTime @gettime,''
--Select* from #GetShiftTime order by StartTime
--return
--insert into #GetShiftTime Exec s_GetShiftTime '2013-07-22 06:30:00.000','THIRD'
----'2010-07-14 06:00:00.000'
 --Select* from #GetShiftTime order by StartTime
Declare Finder  cursor for 
Select StartTime,Endtime from #GetShiftTime order by StartTime
Open Finder
FETCH NEXT FROM Finder INTO @sttime_1,@ndtime_1
while (@@fetch_status= 0)
Begin

If (@gettime1>=@sttime_1 and @gettime1>=@ndtime_1)
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
Select top 1 * from #GetShiftTime Where StartTime<=@ShiftStartTime and Endtime<=@ShiftEndTime order by starttime desc
End
