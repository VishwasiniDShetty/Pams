/****** Object:  Procedure [dbo].[sbSimulatedAggregate]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE   procedure [dbo].[sbSimulatedAggregate]
@pushdate as datetime,
@machine As varchar(20)
as
declare @mc as varchar(50)
declare @totime as int
declare @noofhr as int
declare @hr1 as datetime
declare @hr2 as datetime
declare @machineid as varchar(50)
--declare @interfaceid as varchar(4)
declare @mchrrate as float
--declare @autoload as int
declare @strdate1 as varchar(20)
declare @tmp as int
--declare @avgcycl as int
declare @cmpcnt as int
declare @cmp as varchar(4)
declare @custid as varchar(50)
declare @cmpid as varchar(50)
declare @opn as varchar(50)
declare @wono as varchar(50)
declare @opr as varchar(50)
declare @nocomp as int
declare @operationno as varchar(50)
declare @starttime as datetime
declare @endtime as datetime
declare @operatorid as varchar(50)
declare @totaltime as int
declare @avgcycle as int
declare @iCycleTime as int
declare @price as int
declare @productionTime as int
declare @totaldowntime as int
declare @cycletime as int
declare @avgLoad as int
declare @loadunload as int
declare @CompType as varchar(50)
declare @wocount as int
declare @boundary as bit
declare @oprtype as varchar(50)
declare @temptime as int
declare @dtStTime as datetime
declare @dtNdTime as datetime
declare @lngSumTime as bigint
declare @totaldown as bigint
declare @count as int
If datediff(day, @pushdate, getdate()) > 0
begin	
select @totime = 23
select @noofhr = 24
end	
Else
begin	
If datediff(day,@pushdate, getdate()) = 0
	begin
select @totime = DATEPART(hh,getdate())
select @noofhr = @totime
	End
End
select @tmp = 0
while @tmp <= @totime
begin --while
	select @strdate1 = DATENAME(DAY,@PUSHDATE) + ' ' + dATENAME(month,@pushdate) + ' ' + datename(year, @pushdate)
	select @hr1 = cast((@strdate1 + ' ' + cast(@tmp as varchar(2))+ ':00:00:000') as datetime)
select @hr2 = cast((@strdate1+ ' ' + convert(varchar(2), @tmp)+ ':59:59:000') as datetime)
	PRINT 'hr1, HR2'
	PRINT @HR1
	PRINT @HR2	
	select @dtsttime = @hr1
	select @dtndtime = @hr1
	declare CurMachine Cursor For
	select machineid,mchrrate,interfaceid from machineinformation where machineid=@machine
	OPEN CurMachine
	FETCH NEXT FROM CurMachine Into @machineid,@mchrrate,@mc
	
	WHILE (@@fetch_status = 0)
	BEGIN --(while CurMachine)
--		print 'in curMACHINE'
		select @count=count(*) from autodata where msttime < @hr1 and ndtime > @hr2 and mc = @mc and datatype = 1
		if @count = 0
		begin
			DECLARE	CurBorder Cursor For
			select Comp, Opr, Opn,msttime,ndtime from autodata where mc=@mc  and msttime<@hr1 and ndtime>=@hr1 and ndtime <= @hr2 and datatype=1 and post = 0
		
			Open CurBorder	
		
			FETCH NEXT FROM CurBorder Into @CMP, @Opr, @Opn, @starttime, @endtime
			WHILE (@@fetch_status = 0)
			BEGIN --(while CurBorder)
--				PRINT 'In Curborder'
				select @custid = componentinformation.customerid,
				@cmpid = componentinformation.componentid,
				@cycletime = componentoperationpricing.cycletime,
				@price = componentoperationpricing.price,
				@operationNo = componentoperationpricing.operationno from
				componentinformation inner join componentoperationpricing
				on componentinformation.componentid=componentoperationpricing.componentid
				where componentinformation.interfaceid=@cmp and componentoperationpricing.interfaceid=@opn		
				select @operatorid=employeeid from employeeinformation where interfaceid=@opr
				--get workorder no
				select @wono=workorderno, @iCycleTime=cycletime from workorderheader where
				machineid = @machine and componentid = @cmpid and operationno = @operationno
				and customerid = @custid and datediff(d,wodate, @pushdate) = 0
		
				if @wono is not null
				begin
		        		insert into workorderproductiondetail
					(workorderno,productiondate,timefrom,timeto,employeeid,production,rejection,accepted)
					values (@wono,@pushdate,@starttime,@endtime,@operatorid,1,0,1)
					select @dtStTime = @endtime
					select @dtNdTime = @endtime
					update autodata set post = 1 where mc=@mc AND autodata.ndtime=@ENDTIME AND autodata.MSTTIME=@STARTTIME and comp =@cmp and opn=@opn and opr = @opr 				
				end		
			FETCH NEXT FROM CurBorder Into @CMP, @Opr, @Opn, @starttime, @endtime
			end -- while CurBorder
			close  CurBorder
			deallocate CurBorder
			PRINT @MACHINE
			PRINT @HR1
			PRINT @HR2
			--get the distinct comp/opn/opr combination for the given period of the given machine
			DECLARE	CurSimAgg Cursor For
			SELECT distinct autodata.comp, autodata.opn, autodata.opr
			FROM machineinformation INNER JOIN autodata ON machineinformation.InterfaceID = autodata.mc
			WHERE machineinformation.machineid=@machine AND autodata.ndtime>@hr1 AND autodata.ndtime<=@hr2 and msttime>=@hr1 and post = 0
			Open CurSimAgg	
			FETCH NEXT FROM CurSimAgg Into @CMP, @Opn, @Opr
			WHILE (@@fetch_status = 0)
			BEGIN --(while CurSimAgg)
--			PRINT 'IN CURSIMAGG'
				select @custid=componentinformation.customerid,
				@cmpid=componentinformation.componentid,
				@cycletime=componentoperationpricing.cycletime,
				@price=componentoperationpricing.price,
				@operationno=componentoperationpricing.operationno from
			        componentinformation inner join componentoperationpricing
				on componentinformation.componentid=componentoperationpricing.componentid
				where componentinformation.interfaceid=@cmp and componentoperationpricing.interfaceid=@opn
				select @operatorid=employeeid from employeeinformation where interfaceid=@opr
				--get workorder no
				select @wono=workorderno, @iCycleTime=cycletime from workorderheader where
				machineid = @machine and componentid = @cmpid and operationno = @operationno
				and customerid = @custid and datediff(d,wodate, @pushdate) = 0
		
			PRINT 'wono'
			PRINT @WONO			
			if @WONO IS NOT NULL
			begin
		        	--calculate aggreagte cycle+loadunload
		        	select @productionTime = 0
				select @cmpcnt = 0
		        	select @productiontime = sum(cycletime+loadunload), @cmpcnt=count(cycletime)  from autodata
				where mc=@mc and comp=@cmp and opn=@opn and opr=@opr
				and msttime>=@hr1 and ndtime<=@hr2 and datatype=1
		        	If @productiontime is null
		            		select @productiontime = 0
		        	If @cmpcnt is null
		            		select @cmpcnt = 0
				select @totaldowntime = 0
				select @temptime = sum(datediff(s,@hr1,@HR2)) from autodata
				where mc = @mc and comp = @cmp and opr = @opr and opn = @opn and sttime <= @hr1 and ndtime >= @hr2 and datatype = 2
			
				if @temptime is null
					select @temptime = 0
				select @totaldowntime = @totaldowntime + @temptime
	
				select @temptime = sum(datediff(s,sttime,@hr2)) from autodata
				where mc = @mc and comp = @cmp and opr = @opr and opn = @opn and sttime > @hr1 And sttime < @hr2 And ndtime >= @hr2 and datatype = 2
				if @temptime is null
					select @temptime = 0
				select @totaldowntime = @totaldowntime + @temptime
				select @temptime = sum(datediff(s,sttime,NDTIME)) from autodata
				where mc = @mc and comp = @cmp and opr = @opr and opn = @opn and sttime > @hr1 And sttime < @hr2 And ndtime < @hr2 And ndtime > @hr1 and datatype = 2
				if @temptime is null
					select @temptime = 0
				select @totaldowntime = @totaldowntime + @temptime
			
				select @temptime = sum(datediff(s,@HR1,NDTIME)) from autodata
				where mc = @mc and comp = @cmp and opr = @opr and opn = @opn and sttime <= @hr1 And ndtime < @hr2 And ndtime > @hr1 and datatype = 2
				if @temptime is null
					select @temptime = 0
				select @totaldowntime = @totaldowntime + @temptime
			        SELECT @dtStTime = @dtNdTime
				select @DTndtime = dateadd(s,@productiontime + @totaldowntime,@DTNDtime)
				print 'Total down, production time,  starttime, endtime'
				print @totaldowntime
				print @productiontime
				print @dtsttime
				print @dtndtime
			        insert into workorderproductiondetail (workorderno,productiondate,timefrom,timeto,employeeid,production,rejection,accepted)
				values (@WONO,@PUSHDATE,@dtStTime,@dtNdTime,@OPERATORID,@CmpCnt,0,@CMPCNT)
				select @dtStTime = @DTNDTime
				select @dtNdTime = @DTNDTime
				update autodata set post = 1 where mc=@mc AND autodata.ndtime>@hr1 AND autodata.ndtime<=@hr2 and msttime>=@hr1 and comp =@cmp and opn=@opn and opr = @opr
				
			end		
	
				FETCH NEXT FROM CurSimAgg Into @CMP, @Opn, @Opr
			end -- while CurSimAgg
			close  CurSimAgg
			deallocate CurSimAgg
		--print 'Begin CurDowntime'
		--wo present in down but not in prdn
			declare CurDowntime Cursor for	
		
	        	select DISTINCT workorderdowntimedetail.workorderno, sum(TOTALDOWN), employeeid
			from workorderdowntimedetail inner join
			workorderheader on workorderdowntimedetail.workorderno=workorderheader.workorderno
			where timefrom >= @hr1 and timeto <= @hr2 and workorderheader.machineid=@machine 	 	
			group by workorderdowntimedetail.workorderno, employeeid
		
			Open CurDowntime
			FETCH NEXT FROM CurDowntime Into @WONO, @totaldown,@operatorid
			WHILE (@@fetch_status = 0)
			BEGIN --(while CurDowntime)
		
		--print 'In down cursor'           	
			select @WOCOUNT=COUNT(*) from workorderproductiondetail where timefrom>=@hr1 and timeto<=@hr2 and workorderno=@wono and employeeid=@operatorid
				print 'WOCount'
				print @wocount
		        	if  @WOCOUNT = 0 OR @WOCOUNT IS NULL		
			        BEGIN
				print 'WOCOunt'
				SELECT @dtStTime = @dtNdTime
	              		SELECT @dtNdTime = DATEADD(s,@totaldown,@dtNdTime)
				print 'Dowm time record - total down, starttime, endtime'
				print @totaldown
				print @dtsttime
				print @dtndtime
	
		                insert into workorderproductiondetail (workorderno,productiondate,timefrom,timeto,employeeid,production,rejection,accepted)
				values (@WONO,@PUSHDATE,@dtStTime,@dtNdTime,@OPERATORID,0,0,0)
				END
		
				FETCH NEXT FROM CurDowntime Into @WONO, @totaldown, @operatorid
			end -- while CurDowntime
			close  Curdowntime
			deallocate Curdowntime
		
		
	    	--if production is not there then consider the total time as down and check down
			declare @recount as int
		--SELECT @recount=count(*)
		--FROM machineinformation INNER JOIN autodata ON machineinformation.InterfaceID = autodata.mc
		--WHERE machineinformation.machineid=@machine AND autodata.sttime>=@hr1 AND autodata.ndtime<=@hr2 and msttime>=@hr1 and datatype = 1
			Select @recount = count(*) from workorderproductiondetail
				inner join workorderheader on workorderproductiondetail.workorderno=workorderheader.workorderno
				where timefrom>=@hr1 and timeto <=@hr2 and workorderheader.machineid=@machineid
				
		print 'Count'
		print @recount
		if @recount = 0 		
		BEGIN
			Select @wono=workorderheader.workorderno,@operatorid=employeeid from workorderdowntimedetail
			inner join workorderheader on workorderdowntimedetail.workorderno=workorderheader.workorderno
			where timefrom>=@hr1 and timeto <=@hr2 and workorderheader.machineid=@machineid
			print 'WONO'
			print @wono
			if @wono is not null        		
			insert into workorderproductiondetail (workorderno,productiondate,timefrom,timeto,employeeid,production,rejection,accepted)
			values (@wono,@pushdate,@hr1,@hr2,@operatorid,0,0,0)
		end	    	
	end
	
	FETCH NEXT FROM CurMachine Into @machineid,@mchrrate,@mc
	END --(while CurMachine)
close CurMachine	
deallocate CurMachine
select @tmp = @tmp + 1
end
return 0
