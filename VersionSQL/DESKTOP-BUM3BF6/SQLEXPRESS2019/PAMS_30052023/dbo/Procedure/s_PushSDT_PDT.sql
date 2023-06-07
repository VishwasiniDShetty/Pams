/****** Object:  Procedure [dbo].[s_PushSDT_PDT]    Committed by VersionSQL https://www.versionsql.com ******/

/****** Object:  StoredProcedure [dbo].[s_PushSDT_PDT]    Script Date: 07/02/2009 09:29:02 ******/
--s_SDT '2009-01-01 11:02:00','2009-01-02 11:04:00','CLASSIC MC','DelSDT'
--s_SDT '2009-01-01 11:04:00','2009-01-02 13:25:00','CLASSIC MC','DelSDT'
--select * from planneddowntimes where machine='CLASSIC MC' order by StartTime

CREATE PROCEDURE [dbo].[s_PushSDT_PDT]
	@Starttime datetime, 
	@Endtime datetime,
	@machine nvarchar(50),
	@type nvarchar(8)
AS
BEGIN
	if @type='AddSDT'
	begin
		---inactivate all the overlapping PDTs.
		update planneddowntimes set PDTstatus='0' 
		where Machine=@machine
		AND ((StartTime>=  @StartTime AND EndTime<= @EndTime)
		OR (StartTime< @StartTime AND EndTime> @StartTime AND EndTime<=@EndTime)
		OR (StartTime>= @StartTime AND EndTime> @EndTime AND StartTime< @EndTime)
		OR (StartTime< @StartTime AND EndTime> @EndTime ))

		---insert the new SDT record.
		insert into planneddowntimes(StartTime,EndTime,DownReason,machine,PDTstatus,SDTsttime)
		values(@starttime,@endtime,'SDT',@machine,'1',@starttime)

		---insert the partial overlapped PDTs of type 2 and 3.
		insert into planneddowntimes(starttime,endtime,downreason,machine,SDTsttime,PDTstatus) 
			select case when starttime< @starttime then starttime else @endtime end as starttime,
			case when starttime< @starttime then @starttime else endtime end as endtime,
			downreason,machine,@starttime,'1' from planneddowntimes 
			where machine=@machine AND ((StartTime< @StartTime AND EndTime> @StartTime AND EndTime<=@EndTime)
			OR (StartTime>= @StartTime AND EndTime> @EndTime AND StartTime< @EndTime))

		---insert the partial overlapped PDTs of type 4.
		insert into planneddowntimes(starttime,endtime,downreason,machine,SDTsttime,PDTstatus) 
			select starttime,@starttime,downreason,machine,@starttime,'1' from planneddowntimes 
			where machine=@machine AND ((StartTime< @StartTime AND EndTime> @EndTime))
		insert into planneddowntimes(starttime,endtime,downreason,machine,SDTsttime,PDTstatus) 
			select @endtime,endtime,downreason,machine,@starttime,'1' from planneddowntimes 
			where machine=@machine AND ((StartTime< @StartTime AND EndTime> @EndTime))
	end
	if @type='DelSDT'
	begin
		---activate all the overlapping PDTs.
		update planneddowntimes set PDTstatus='1' 
		where Machine=@machine
		AND ((StartTime>=  @StartTime AND EndTime<= @EndTime)
		OR (StartTime< @StartTime AND EndTime> @StartTime AND EndTime<=@EndTime)
		OR (StartTime>= @StartTime AND EndTime> @EndTime AND StartTime< @EndTime)
		OR (StartTime< @StartTime AND EndTime> @EndTime ))

		---delete the SDT and the linked(partailly overlapped) PDTs.
		delete from planneddowntimes where machine=@machine and SDTsttime=@starttime 
	end
END
