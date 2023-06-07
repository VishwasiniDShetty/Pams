/****** Object:  Procedure [dbo].[S_GetSpindleRuntimeInfo]    Committed by VersionSQL https://www.versionsql.com ******/

/*
[dbo].[S_GetSpindleRuntimeInfo] '2021-11-10 06:00:00.000','2021-11-10 10:37:29.000',''
*/
CREATE procedure [dbo].[S_GetSpindleRuntimeInfo]
@fromTime datetime='',
@endtime datetime='',
@Machineid nvarchar(50)=''
as
begin

declare @startdate nvarchar(100)
declare @enddate nvarchar(100)
select @startdate=@fromTime
select @enddate=@endtime

create table #temp
(
Date datetime,
Shift nvarchar(50),
MachineID NVARCHAR(50),
Runtime float,
updatedTS DATETIME
)
create table #temp1
(
Date datetime,
Shift nvarchar(50),
MachineID NVARCHAR(50),
Runtime float,
updatedTS DATETIME,
ShiftDate DateTime,		
Shiftname nvarchar(20),
ShftSTtime DateTime,
ShftEndTime DateTime
)


create table #shift
(
ShiftDate DateTime,		
Shiftname nvarchar(20),
ShftSTtime DateTime,
ShftEndTime DateTime
)


insert into #temp(MachineID,Runtime,updatedTS)
(
select m.MachineID,Runtime,updatedTS FROM spindleruntimedatainfo s
inner join machineinformation m on m.interfaceid=s.machineid  where (m.machineid=@Machineid or isnull(@machineid,'')='') and updatedTS>=@fromTime and updatedTS<=@endtime
)


while cast(@startdate as date)<=cast(@enddate as date)
begin
INSERT INTO #shift(ShiftDate,Shiftname,ShftSTtime,ShftEndTime)
		Exec s_GetShiftTime @startdate,''
		SELECT @startdate = DATEADD(DAY,1,@Startdate)
end


insert into #temp1
select * from  #temp cross join #shift


select shiftdate,Shiftname,MachineID,dbo.f_FormatTime(Runtime,'hh:mm:ss') as Runtime,updatedts,ShftSTtime,ShftEndTime from #temp1 where updatedTS>=ShftSTtime and updatedTS<=ShftEndTime
order by ShiftDate,shiftname,MachineID
end
