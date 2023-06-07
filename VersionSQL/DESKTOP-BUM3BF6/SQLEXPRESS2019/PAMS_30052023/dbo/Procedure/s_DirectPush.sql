/****** Object:  Procedure [dbo].[s_DirectPush]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE   PROCEDURE [dbo].[s_DirectPush]
@pushdate as datetime,
@machine as varchar(100)
--@startTime as datetime,
--@endTime as datetime
AS
declare @machineid as varchar(50)
declare @componentid as varchar(50)
declare @operationno as smallint
declare @WOno as varchar(50)
declare @SCycleTime as int
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
declare @mchrate as float
declare @cycletime as int
declare @totdown as int
declare @strPushDate as varchar(20)
declare @EndofPushDate as datetime
declare @downdate as datetime
select @strPushDate = convert(varchar(20), @pushdate,106)
select @EndofPushDate = convert(datetime,(@strpushdate + ' ' + '23:59:59'),103)
Declare CurDir Cursor for
--get the data from autodata for a given machine and time slice
SELECT mc,comp,opn,opr,machineid, componentid, operationno, customerid, msttime, ndtime, cycletime,
employeeid, downid, mchrrate FROM v_wodata where post = 0 and datatype = 1 and nddate = @pushdate and ndtime <= @endofpushdate and machineid = @machine
OPEN CurDir
FETCH NEXT FROM CurDir Into @mc,@comp, @opn, @opr, @machineid, @componentid, @operationno, @customerid, @sttime, @ndtime, @cycletime, @eid, @did, @mchrate
WHILE @@FETCH_STATUS = 0
BEGIN
	   select @WONo=workorderno, @SCycleTime=cycletime, @price=price from workorderheader where
		machineid = @machineid and componentid= @componentid
		and operationno= @operationno
		and wodate= @pushdate
		order by wodate
--	   select @totdown=sum(totaldown) from workorderdowntimedetail where workorderno = @wono and downdate = @pushdate and timefrom >= @starttime and timeto <= @endtime		
-------------insert records into workorderPRODUCTIONdetail		
		print @wono
		insert into workorderproductiondetail
		(workorderno,productiondate,timefrom,timeto,employeeid,production,rejection,accepted,cycletime,mchrrate,price,turnover,expectedturnover,tottime,c1n1)
		 values (@wono,@pushdate,@sttime,@ndtime,@eid,1,0,1,@cycletime,@mchrate,@price,@price,((@cycletime/3600) * @mchrate), (datediff(s, @sttime, @ndtime)), @scycletime * 1)
		update autodata set post=1
		where mc=@mc and comp=@comp and opn=@opn
		and opr=@opr  and msttime= @sttime and ndtime=@ndtime and datatype = 1
FETCH NEXT FROM CurDir into @mc,@comp, @opn, @opr, @machineid, @componentid, @operationno, @customerid, @sttime, @ndtime, @cycletime, @eid, @did, @mchrate
END
CLOSE CurDir
DEALLOCATE CurDir
Declare CurDir Cursor for
SELECT workorderdowntimedetail.workorderno
,machineinformation.InterfaceID,
workorderdowntimedetail.downdate,
workorderdowntimedetail.timefrom,
workorderdowntimedetail.timeto,
workorderdowntimedetail.employeeid
FROM (workorderdowntimedetail
INNER JOIN workorderheader ON workorderdowntimedetail.workorderno = workorderheader.workorderno)
INNER JOIN machineinformation ON workorderheader.machineid = machineinformation.machineid
WHERE machineinformation.machineid = @Machine  AND workorderdowntimedetail.downdate = @pushdate
OPEN CurDir
FETCH NEXT FROM CurDir Into @wono,@mc, @downdate, @sttime, @ndtime, @eid
WHILE @@FETCH_STATUS = 0
BEGIN
select @count = count(*) from workorderproductiondetail
where workorderno = @wono and productiondate = @downdate and timefrom = @sttime and timeto = @ndtime --and employeeid = @eid
if @count = 0
--push all downs as it is
	insert into workorderproductiondetail (workorderno,productiondate,timefrom,timeto,employeeid,production,rejection,accepted,cycletime,mchrrate,price,turnover,expectedturnover,productiontime,tottime,c1n1)
	values (@wono,@downdate,@sttime,@ndtime,@eid,0,0,0,0,0,0,0,0,0,0,0)
FETCH NEXT FROM CurDir into @wono,@mc, @downdate, @sttime, @ndtime, @eid
END
CLOSE CurDir
DEALLOCATE CurDir
