/****** Object:  Procedure [dbo].[s_SimulatedAggregatePush]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE   PROCEDURE [dbo].[s_SimulatedAggregatePush] @PushDate as datetime, @Machine as varchar(20)
AS

declare @mc as varchar(50)
declare @totime as int
declare @noofhr as int
declare @hr1 as datetime
declare @hr2 as datetime
declare @strh1 as varchar(20)
declare @strh2 as varchar(20)
declare @machineid as varchar(50)
declare @interfaceid as varchar(4)
declare @mchrrate as float
declare @autoload as int
declare @strdate1 as varchar(20)
declare @tmp as int
declare @noofcomp as int
declare @avgcycl as int
declare @compcnt as int
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

	-- Aggregate all records that fall exactly within the time slice	
	DECLARE CurComp CURSOR FOR

	SELECT DISTINCT mc, comp, opn, OPR, componentid, operationno, employeeid, customerid, mchrrate
	FROM v_wodata
       WHERE machineid=@machine AND DATEDIFF(D,@PUSHDATE,STDATE) = 0 AND sttime >= @hr1 and ndtime <= @hr2 and datatype = 1
	
	OPEN CurComp

	FETCH NEXT FROM Curcomp Into @mc,@cmp,@opn, @OPr, @cmpid, @operationno, @operatorid, @custid, @mchrrate

	WHILE (@@fetch_status <> -1)
	BEGIN 
		IF (@@fetch_status <> -2)
		BEGIN 
	
		print @mc 
		print @cmp
		print @opn
		print @opr
		print @machine
		print @cmpid
		print @operationno
		print @operatorid
		print @custid
		PRINT @nocomp
		
	
		select @nocomp = 0
		
		--get the number of components produced for the comp, operation for that hours
		select @noComp = count(comp), @starttime = min(sttime), @AvgCycle= avg(cycletime),  @avgLoad = avg(loadunload),  @productionTime = sum(cycletime + loadunload)
		from autodata where comp = @cmp and opr = @opr and opn = @opn and mc = @mc and datediff(d,stdate, @pushdate) = 0 and post = 0
		and sttime >= @hr1 and ndtime <= @HR2
		group by comp, opr, opn	

		

		if @NOCOMP > 0 
		begin
			select @wono=workorderno, @iCycleTime=cycletime, @price=price from workorderheader where 
			machineid = @machine and componentid = @cmpid and operationno = @operationno 
			and customerid = @custid
		
		
		
			print 'WO NO'
			print @wono

				
			select @totalDowntime = sum(totaldown) from workorderdowntimedetail where workorderno = @wono and datediff(d,downdate,@pushdate)=0 and timefrom >= @hr1 and timeto <= @hr2
		
			if @totaldowntime is null
				select @totaldowntime = 0 


			print 'Down time'
			print @totaldowntime
			PRINT 'Production Time'
			print @productiontime

			
			select @endtime = dateadd(s,@productiontime + @totaldowntime,@starttime)

			if @endtime > @hr2
				select @endtime = @hr2

			print 'Start Time and Endtime'
			print @starttime		
			print @endtime

			insert into workorderproductiondetail
			(workorderno,productiondate,timefrom,timeto,employeeid,production,rejection,accepted,cycletime,loadunload,mchrrate,price,turnover,expectedturnover,tottime, productiontime,c1n1)
			 values (@wono,@pushdate,@starttime,@endtime,@operatorid,@noComp,0,@nocomp,@avgcycle,@avgLoad,@mchrrate,@price,@nocomp*@price,((@avgcycle/3600) * @mchrrate), (datediff(s, @starttime, @endtime)), @productiontime, @icycletime * @nocomp)

			update autodata set post=1 
			where mc=@mc and comp=@cmp and opn=@opn 
			and opr=@opr and sttime >= @hr1 and ndtime <=@hr2 and datatype = 1
		end
		end
		FETCH NEXT FROM Curcomp Into @mc,@cmp,@opn, @OPr, @cmpid, @operationno, @operatorid, @custid, @mchrrate
	end



	CLOSE Curcomp
	DEALLOCATE CurComp


	-- Directly push all the records that have a startime before the beginning of the timeslice
/*	SELECT DISTINCT mc, comp, opn, OPR, sttime, ndtime, cycletime, loadunload, hr1=@hr1, hr2=@hr2
	FROM autodata
        WHERE mc='8113' AND DATEDIFF(D,@PUSHDATE,STDATE) = 0 AND ((sttime < @hr1 and ndtime >= @hr1 and ndtime <= @hr2) or (sttime >= @hr1 and sttime <= @hr2 and ndtime > @hr2)) and datatype = 1 and post = 0
*/
	DECLARE CurComp CURSOR FOR
	SELECT DISTINCT mc, comp, opn, OPR, componentid, operationno, employeeid, customerid, mchrrate, sttime, ndtime, cycletime, loadunload
	FROM v_wodata
        WHERE machineid=@machine AND DATEDIFF(D,@PUSHDATE,STDATE) = 0 AND ((sttime < @hr1 and ndtime >= @hr1 and ndtime <= @hr2) or (sttime >= @hr1 and sttime <= @hr2 and ndtime > @hr2)) and datatype = 1 and post = 0

	OPEN CurComp

	
	FETCH NEXT FROM Curcomp Into @mc,@cmp,@opn, @OPr, @cmpid, @operationno, @operatorid, @custid, @mchrrate, @starttime, @endtime, @cycletime, @loadunload
	WHILE (@@fetch_status = 0)
	BEGIN 

       	   select @WONo=workorderno, @iCycleTime=cycletime, @price=price from workorderheader where  
			machineid = @machine and componentid= @cmpid
			and operationno= @operationno
			and wodate= @pushdate
			and customerid = @custid
			order by wodate
	
			print 'WO NO'
			print @wono
			insert into workorderproductiondetail
			(workorderno,productiondate,timefrom,timeto,employeeid,production,rejection,accepted,cycletime,loadunload, mchrrate,price,turnover,expectedturnover,tottime,productiontime, c1n1)
			 values (@wono,@pushdate,@starttime,@endtime,@operatorid,1,0,1,@cycletime,@loadunload,@mchrrate,@price,@price,((@cycletime/3600) * @mchrrate), (datediff(s, @starttime, @endtime)),(datediff(s, @starttime, @endtime)), @icycletime * 1)
	
			update autodata set post=1 
			where mc=@mc and comp=@cmp and opn=@opn 
			and opr=@opr  and sttime= @starttime and ndtime=@endtime and datatype = 1

		FETCH NEXT FROM Curcomp Into @mc,@cmp,@opn, @OPr, @cmpid, @operationno, @operatorid, @custid, @mchrrate, @starttime, @endtime, @cycletime, @loadunload
	end



	CLOSE Curcomp

	DEALLOCATE Curcomp		

	select @tmp = @tmp + 1


	end

return 0
