/****** Object:  Procedure [dbo].[s_GetDownReasons]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE procedure [dbo].[s_GetDownReasons]
@Param nvarchar(50)=''

AS
BEGIN

CREATE TABLE #HolidayShift
(
Holiday datetime,
Machine nvarchar(50),
Reason nvarchar(250),
ShiftStart datetime,
ShiftEnd datetime
)

CREATE TABLE #Holiday
(
Holiday datetime,
Machine nvarchar(50),
Reason nvarchar(250)
)

Insert into #Holiday(Holiday,Machine,Reason)
select T.StartTime,T.Machine,T.DownReason from TempPlannedDownTimes T
inner join HolidayList H on T.Machine=H.MachineID and T.DownReason=H.Reason 
where datepart(year,T.StartTime) = datepart(year,Holiday)

Insert into #HolidayShift(Holiday,Machine,Reason)
select T.StartTime,T.Machine,T.DownReason from TempPlannedDownTimes T
inner join HolidayList H on T.Machine=H.MachineID 
where Convert(nvarchar(10),T.StartTime,120) = Convert(nvarchar(10),Holiday,120)

update #HolidayShift set ShiftStart=T1.SD , ShiftEnd= T1.ED
from (
select Machine,Holiday,dbo.f_GetLogicalDayStart(Holiday) as SD,dbo.f_GetLogicalDayEnd(Holiday) as ED from #HolidayShift
)T1 inner join #HolidayShift T2 on T1.Machine=T2.Machine and T1.Holiday=T2.Holiday 

IF (@Param ='PDTsave' or ISNULL(@Param,'')='')
BEGIN
		(SELECT distinct T.* FROM TempPlannedDownTimes T
		INNER JOIN PlannedDownTimes M ON M.Machine=T.Machine 
		WHERE ((M.StartTime >= T.StartTime AND M.EndTime <= T.EndTime)
		OR (M.StartTime < T.StartTime AND M.EndTime <= T.EndTime AND M.EndTime > T.StartTime)
		OR (M.StartTime >= T.StartTime AND M.StartTime < T.EndTime AND M.EndTime > T.EndTime)
		OR (M.StartTime < T.StartTime AND M.EndTime > T.EndTime))
		OR (T.DownType = 'DailyDown'  and (M.StartTime between T.ShiftStart and T.ShiftEnd) and T.Machine=M.Machine and T.ShiftName=m.ShiftName and T.DownReason=M.DownReason and T.DayName=M.DayName )
		OR (convert(nvarchar(10),T.StartTime,120) = convert(nvarchar(10),M.StartTime,120) and convert(nvarchar(10),T.EndTime,120) = convert(nvarchar(10),M.EndTime,120) and T.Machine=M.Machine and T.DownReason=m.DownReason and T.DayName=M.DayName and T.shiftname=M.shiftName ))
		union
		(SELECT distinct T.* FROM TempPlannedDownTimes T
		INNER JOIN #HolidayShift T1 ON T.Machine=T1.Machine 
		WHERE (T.StartTime between T1.ShiftStart and T1.ShiftEnd))


	INSERT INTO PlannedDownTimes(StartTime,EndTime,Machine,DownReason,PDTstatus,SDTsttime,Ignorecount,DownType,dayname,shiftname,ShiftStart,ShiftEnd)
	select distinct StartTime,EndTime,Machine,DownReason,'1',SDTsttime,Ignorecount,DownType,dayname,shiftname,ShiftStart,ShiftEnd from TempPlannedDownTimes
	where (id not in((SELECT distinct T.ID FROM TempPlannedDownTimes T
		INNER JOIN PlannedDownTimes M ON M.Machine=T.Machine 
		WHERE ((M.StartTime >= T.StartTime AND M.EndTime <= T.EndTime)
		OR (M.StartTime < T.StartTime AND M.EndTime <= T.EndTime AND M.EndTime > T.StartTime)
		OR (M.StartTime >= T.StartTime AND M.StartTime < T.EndTime AND M.EndTime > T.EndTime)
		OR (M.StartTime < T.StartTime AND M.EndTime > T.EndTime))
		OR (T.DownType = 'DailyDown'  and (M.StartTime between T.ShiftStart and T.ShiftEnd) and T.Machine=M.Machine and T.ShiftName=m.ShiftName and T.DownReason=M.DownReason and T.DayName=M.DayName )
		OR (convert(nvarchar(10),T.StartTime,120) = convert(nvarchar(10),M.StartTime,120) and convert(nvarchar(10),T.EndTime,120) = convert(nvarchar(10),M.EndTime,120) and T.Machine=M.Machine and T.DownReason=m.DownReason and T.DayName=M.DayName and T.shiftname=M.shiftName ))
		union
		(SELECT distinct T.ID FROM TempPlannedDownTimes T
		INNER JOIN #HolidayShift T1 ON T.Machine=T1.Machine 
		WHERE (T.StartTime between T1.ShiftStart and T1.ShiftEnd))
		))

END

ELSE If @Param='HolidaySave'
Begin

	(SELECT distinct T.* FROM TempPlannedDownTimes T
	inner JOIN #HolidayShift T1 ON (T.Machine=T1.Machine ) and (T.StartTime between T1.ShiftStart  and T1.ShiftEnd ) 
	left join #Holiday T2 on T.Machine=T2.Machine and T.DownReason=T2.Reason and DATEPART(year,T.starttime)=DATEPART(year,T2.holiday) ) 
	union
	(SELECT distinct T.* FROM TempPlannedDownTimes T
	INNER JOIN PlannedDownTimes M ON M.Machine=T.Machine  and (M.StartTime >= T.StartTime AND M.EndTime <= T.EndTime))


		INSERT INTO HolidayList(Holiday,Reason,MachineID)
		select distinct StartTime,DownReason,Machine from TempPlannedDownTimes
		where (id not in (
		(SELECT distinct T.ID FROM TempPlannedDownTimes T
		inner JOIN #HolidayShift T1 ON (T.Machine=T1.Machine ) and (T.StartTime between T1.ShiftStart  and T1.ShiftEnd ) 
		left join #Holiday T2 on T.Machine=T2.Machine  and T.DownReason=T2.Reason and DATEPART(year,T.starttime)=DATEPART(year,T2.holiday) )
		union
		(SELECT distinct T.ID FROM TempPlannedDownTimes T
		INNER JOIN PlannedDownTimes M ON M.Machine=T.Machine  and (M.StartTime >= T.StartTime AND M.EndTime <= T.EndTime))
		))
		
		--dbo.f_GetLogicalDayStart(convert(nvarchar(23),(concat (StartTime,' ',(CONVERT(time, GETDATE())))),120)) as StartTime,
		--dbo.f_GetLogicalDayStart(convert(nvarchar(23),(concat (StartTime,' ',(CONVERT(time, GETDATE())))),120)) as EndTime,
		INSERT INTO PlannedDownTimes(StartTime,EndTime,Machine,DownReason,PDTstatus,SDTsttime,Ignorecount,DownType,dayname,shiftname,ShiftStart,ShiftEnd)
		select distinct StartTime,EndTime,Machine,DownReason,'1',SDTsttime,Ignorecount,DownType,dayname,shiftname,ShiftStart,ShiftEnd from TempPlannedDownTimes
		where (id not in (
		(SELECT distinct T.ID FROM TempPlannedDownTimes T
		inner JOIN #HolidayShift T1 ON (T.Machine=T1.Machine ) and (T.StartTime between T1.ShiftStart  and T1.ShiftEnd ) 
		left join #Holiday T2 on T.Machine=T2.Machine  and T.DownReason=T2.Reason and DATEPART(year,T.starttime)=DATEPART(year,T2.holiday) )
		union
		(SELECT distinct T.ID FROM TempPlannedDownTimes T
		INNER JOIN PlannedDownTimes M ON M.Machine=T.Machine  and (M.StartTime >= T.StartTime AND M.EndTime <= T.EndTime))
		))


End


END
