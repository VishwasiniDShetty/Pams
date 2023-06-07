/****** Object:  Procedure [dbo].[s_GetSpindleUsageGraphReport]    Committed by VersionSQL https://www.versionsql.com ******/

--change machine length to 50 from 15: 17-feb-2006
CREATE               procedure [dbo].[s_GetSpindleUsageGraphReport]
	@CycleStart datetime,
	@CycleEnd   datetime,
	@machine nvarchar(50)
AS
BEGIN
declare @timeformat as nvarchar(20)
select @timeformat ='ss'
select @timeformat = isnull((select valueintext from cockpitdefaults where parameter='timeformat'),'ss')
if (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')
begin
select @timeformat = 'ss'
end
	create table #spindle(
	
	machine nvarchar(10),
	starttime datetime,
	endtime datetime,
	Dnumber integer,
	SpindleUsage  float,
	rotation nvarchar(15),
	CycleTime float
	)
insert into #spindle(machine, starttime, endtime,Dnumber,SpindleUsage,rotation,CycleTime)
select machine,starttime,endtime,detailnumber,datediff(second,starttime,endtime),0,datediff(second,@CycleStart,@CycleEnd)
from autodatadetails inner join machineinformation on autodatadetails.machine=machineinformation.interfaceid
where
recordtype=4 and machineID=@machine and starttime>=@CycleStart and starttime<=@CycleEnd
declare @curdno as integer
declare @currotation as nvarchar
declare spindlecursor  cursor for
select dnumber,rotation from #spindle
	open spindlecursor
	fetch next from spindlecursor into @curdno,@currotation
	while(@@fetch_status=0)
BEGIN
	if (@curdno=3)
	update #spindle set rotation='ClockWise'where dnumber=3
	else
	update #spindle set rotation='AntiClockWise'where dnumber=4
	fetch next from spindlecursor into @curdno,@currotation
END
SELECT
	machine,
	starttime,
	endtime,
	Dnumber,
	SpindleUsage,
	dbo.f_FormatTime(SpindleUsage,@timeformat) as frmtSpindleUsage,
	rotation,
	CycleTime
	 FROM #spindle
	close spindlecursor
	deallocate spindlecursor
	
	
END
