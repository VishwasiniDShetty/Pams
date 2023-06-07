/****** Object:  Procedure [dbo].[s_PushDownDetail]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE     PROCEDURE [dbo].[s_PushDownDetail] @strPushDate as varchar(20), @machine as varchar(100)
AS
declare @machineid as varchar(50)
declare @componentid as varchar(50)
declare @operationno as smallint
declare @WOno as varchar(50)
declare @CycleTime as float
declare @price as float
declare @customerid as varchar(50)
declare @sttime as datetime
declare @ndtime as datetime
declare @eid as varchar(25)
declare @did as varchar(50)
declare @mc as varchar(4)
declare @comp as varchar(4)
declare @opn as varchar(4)
declare @opr as varchar(50)
declare @count as int
declare @date1 as datetime
declare @date2 as datetime
declare @hr1 as datetime
declare @hr2 as datetime
declare @hr as int
declare @strDate1 as varchar(20)
declare @strDate2 as varchar(20)
declare @strHr1 as varchar(20)
declare @strHr2 as varchar(20)
declare @pushdate as datetime
declare @downdate as datetime
DECLARE @NextDay as bit
declare @pushdatebegin as datetime
declare @pushdateend as datetime
declare @availeffy as bit
declare @threshold as int
declare @thtime as datetime
declare @curSttime as datetime
declare @curNdTime as datetime
declare @curDown as varchar(50)

--create temp table to details of split down records
Create table #DownTime(
StartTime datetime,
EndTime datetime,
Downcode varchar(50))
/*
Changes done by Sangeeta
Changed above tmp table name to #DownTime
Condition for MLE @Availeff=1(From @availeff-0)
Downcode - Threshold is in seconds.
Calculations like dateadd,datediff must be in seconds
Chech threshold >0
*/



select @pushdatebegin = convert(datetime, @strpushdate + ' 00:00:00', 103 )
select @pushdateend = convert(datetime, @strpushdate + ' 23:59:59', 103 )
select @pushdate = convert(datetime, @strpushdate, 103 )


if @machine = ''
	begin
	DECLARE CurDown CURSOR FOR
	SELECT mc,comp,opn,opr,machineid, componentid, operationno, customerid, sttime, ndtime,
	employeeid, downid FROM v_wodata where post = 0 and datatype = 2 and
	((sttime <= @pushdatebegin And ndtime >= @pushdateend)
	or (sttime > @pushdatebegin And sttime < @pushdateend And ndtime >= @pushdateend)
	or (sttime > @pushdatebegin And sttime < @pushdateend And ndtime > @pushdatebegin And ndtime < @pushdateend)
	or (sttime <= @pushdatebegin And ndtime < @pushdateend And ndtime > @pushdatebegin)
	)
	order by sttime
	end
else
	begin
	Declare CurDown Cursor For
	SELECT mc,comp,opn,opr,machineid, componentid, operationno, customerid, sttime, ndtime,
	employeeid, downid FROM v_wodata where post = 0 and datatype = 2 and machineid in (@machine) and
	((sttime <= @pushdatebegin And ndtime >= @pushdateend)
	or (sttime > @pushdatebegin And sttime < @pushdateend And ndtime >= @pushdateend)
	or (sttime > @pushdatebegin And sttime < @pushdateend And ndtime > @pushdatebegin And ndtime < @pushdateend)
	or (sttime <= @pushdatebegin And ndtime < @pushdateend And ndtime > @pushdatebegin)
	)
	order by sttime
	END

OPEN CurDown
FETCH NEXT FROM CurDown Into @mc,@comp, @opn, @opr, @machineid, @componentid, @operationno, @customerid, @sttime, @ndtime, @eid, @did
WHILE @@FETCH_STATUS = 0
	BEGIN

	   	select @WONo=workorderno, @CycleTime=cycletime, @price=price from workorderheader where
		machineid = @machineid and componentid= @componentid
		and operationno= @operationno
		and wodate= @pushdate
		order by wodate
		
		--insert records into workorderdowntimedetail		
		select @nextday = 0	
		select @date1 = @sttime
		select @date2 = @ndtime
	    	select @strdate1 = convert(varchar(20), @pushdate,106)
	    	--select @strdate2 = convert(varchar(20), @date2,106)
		select @downdate = cast(@strdate1 as datetime)

		-- delete records from Downtime temp table
		delete from #Downtime		

		select @availeffy = availeffy, @threshold = threshold 
		from downcodeinformation where downid = @did
			
		--check if down id is management loss type and threshold is exceeded
		if (@availeffy = 1) and (@threshold < datediff(ss,@sttime,@ndtime) AND @threshold > 0 )
		begin
			--compute the intermediate time to split the down time 
			select @thtime = dateadd(ss,@threshold,@sttime)
			insert into #Downtime values (@sttime, @thtime, @did)
			insert into #Downtime values (@thtime, @ndtime, 'MLE')			
				
		end
		else
			insert into #Downtime values (@sttime, @ndtime, @did)
						
			--While @date1 <= @date2 and @nextday <> 1
		
			--begin
		DECLARE Down_cursor CURSOR
		   FOR SELECT Starttime,EndTime, DownCode FROM #DownTime

		OPEN Down_cursor

		FETCH NEXT FROM down_cursor into @curStTime, @curNdtime, @curDown
				
		WHILE @@FETCH_STATUS = 0                 
		BEGIN

		    select @hr = 0
	            while @hr <= 23
		    begin
	               	select @hr1 = cast((@strdate1 + ' ' + cast(@hr as varchar(2))+ ':00:00:000') as datetime)
		        select @hr2 = cast((@strdate1+ ' ' + convert(varchar(2), @hr)+ ':59:59:000') as datetime)
		
		        If @cursttime <= @hr1 And @curndtime >= @hr2
			begin
				insert into workorderdowntimedetail
				(workorderno,downdate,timefrom,timeto,employeeid,downid,totaldown,autogenerated)
				 values(@wono,@downdate,convert(datetime, @hr1, 113),convert(datetime,@hr2, 113),@eid,@curdown,DATEDIFF(S,@hr1,@hr2),1)
			end
		        If @cursttime > @hr1 And @cursttime < @hr2 And @curndtime >= @hr2
			begin
				insert into workorderdowntimedetail
				(workorderno,downdate,timefrom,timeto,employeeid,downid,totaldown,autogenerated)
				values(@WOno,@downdate,convert(datetime,@cursttime,113),convert(datetime,@hr2,113),@eid,@curdown ,datediff(s, @curSTTIMe,@hr2),1)
			end
		       	if @cursttime > @hr1 And @cursttime < @hr2 And @curndtime < @hr2 And @curndtime > @hr1
			begin
				insert into workorderdowntimedetail
				(workorderno,downdate,timefrom,timeto,employeeid,downid,totaldown,autogenerated)
				values(@wono,@downdate,convert(datetime,@cursttime,113),convert(datetime,@curndtime,113),@eid,@curdown,datediff(s,@curSTTIMe,@curNDTIMe),1)
			end
	                If @cursttime <= @hr1 And @curndtime < @hr2 And @curndtime > @hr1
			begin
				insert into workorderdowntimedetail
				(workorderno,downdate,timefrom,timeto,employeeid,downid,totaldown,autogenerated)
				 values(@wono,@downdate,convert(datetime,@hr1,113),convert(datetime,@curndtime,113),@eid,@curdown,datediff(s,@hr1,@curNDTIMe),1)
			end	
			select @hr = @hr +1
		    end			
		FETCH NEXT FROM down_cursor into @curStTime, @curNdtime, @curDown
		end					
		close down_cursor
		deallocate down_cursor	

	    if @ndtime > @pushdateend
			select @nextday = 1		      	
		--end
		if @nextday <> 1
			update autodata set post=1
			where mc=@mc and comp=@comp and opn=@opn
			and opr=@opr  and sttime= @sttime and ndtime=@ndtime and datatype = 2
	
	FETCH NEXT FROM CurDown into @mc,@comp, @opn, @opr, @machineid, @componentid, @operationno, @customerid, @sttime, @ndtime, @eid, @did
END
CLOSE CurDown
DEALLOCATE CurDown
