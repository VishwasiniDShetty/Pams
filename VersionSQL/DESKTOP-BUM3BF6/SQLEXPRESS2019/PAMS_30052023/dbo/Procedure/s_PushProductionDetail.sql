/****** Object:  Procedure [dbo].[s_PushProductionDetail]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE   PROCEDURE [dbo].[s_PushProductionDetail] @PushDate as datetime, @Machine as varchar(50)
AS
declare @CycThld as int
declare @dt1 as datetime
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
select  @CycThld  = 600
	if @machine = ''
	begin
		DECLARE CurProd CURSOR FOR
		select machineid,interfaceid,mchrrate,autoload
		from machineinformation
	end
	else
	begin
		DECLARE CurProd CURSOR FOR
		select machineid,interfaceid,mchrrate,autoload
		from machineinformation where machineid = @machine
	end
	OPEN CurProd
	FETCH NEXT FROM CurProd Into @machineid,@interfaceid,@mchrrate,@autoload
	WHILE @@FETCH_STATUS = 0
	BEGIN
		/*PRINT 'IN CURSOR'*/
		select @avgcycl = avg(cycletime) from autodata
		where mc = @interfaceid and datediff(d,@pushdate,stdate) <= 0  and datediff(d,@pushdate,nddate) =0
		
		IF @AVGCYCL > @CYCThld
		--push data directly
			exec s_DirectPusH @pushdate, @machineid
		else
		begin
			exec sbSimulatedAggregate @pushdate, @machineid
	end
	FETCH NEXT FROM CurProd into @machineid,@interfaceid,@mchrrate,@autoload
	END
	CLOSE CurProd
	DEALLOCATE CurProd
