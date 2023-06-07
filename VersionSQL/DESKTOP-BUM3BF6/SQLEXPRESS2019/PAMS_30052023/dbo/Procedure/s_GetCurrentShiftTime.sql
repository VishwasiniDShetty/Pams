/****** Object:  Procedure [dbo].[s_GetCurrentShiftTime]    Committed by VersionSQL https://www.versionsql.com ******/

--NR0082 - SwathiKS - 02/Nov/2012 :: Created New Procedure to get current running shift or All shifts for the given time period.
--[s_GetCurrentShiftTime] '2012-01-05 ',''



CREATE     PROCEDURE [dbo].[s_GetCurrentShiftTime]
	@StartDate as datetime,
	@Param as nvarchar(20) = ''
AS
BEGIN
create table #CurrentShift
(
	Startdate datetime,
	--shiftname nvarchar(10),
	shiftname nvarchar(20), --changed for GEA
	Starttime datetime,
	Endtime datetime,
	shiftid int
)
declare @logicalstartdate datetime
select @logicalstartdate = dbo.f_GetLogicalDayStart(@startdate)
--print @logicalstartdate
Insert into #CurrentShift(Startdate,shiftname,Starttime,Endtime)
--exec [s_GetShiftTime] @logicalstartdate,''
select * from [dbo].[s_FunCurrentShiftTime](@logicalstartdate,'')
update #CurrentShift set shiftid = T1.shiftid
from( select shiftid,shiftname from shiftdetails where running=1)T1
inner join #CurrentShift on #CurrentShift.shiftname=T1.shiftname
If @param=''
Begin
	select TOP 1 * from #CurrentShift where @startdate>=starttime and @startdate<=endtime
	ORDER BY STARTTIME ASC
End
If @param='ALL Shifts'
Begin
	select * from #CurrentShift
end
END
