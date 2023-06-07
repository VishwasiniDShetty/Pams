/****** Object:  Procedure [dbo].[s_GetAggMoney_LossMatrix]    Committed by VersionSQL https://www.versionsql.com ******/

/*********************************************************************************
Procedure created by Mrudula to get Money loss statistica from aggregated data
created on 28/dec/2006
mod1:- By Mrudula on 22-nov-2006
mod 2 :- ER0182 By Kusuma M.H on 28-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
Note:For ER0181 No component operation qualification found.
DR0380 : By Gopinath on 12-Dec-2017
  Get number of months in the range and then increment counter, 
  Introduce alias to reuse the column name for another column
******************************************************************************************/
--s_GetAggMoney_LossMatrix '2008-08-01','2008-08-05','','3I13','Shift','0'
CREATE               procedure [dbo].[s_GetAggMoney_LossMatrix]
	@StartTime DateTime,
	@EndTime DateTime,
	---mod 2
	---Replaced varchar with nvarchar to support unicode characters.
--	@PlantID varchar(50) = '',
--	@MachineID  varchar(8000) = '',
--	@CompType varchar(20) = '',
	@PlantID nvarchar(50) = '',
	@MachineID  nvarchar(4000) = '',
	@CompType nvarchar(20) = '',
	---mod 2
	@Exclude int = 0
as
begin
---mod 2
---Replaced varchar with nvarchar to support unicode characters.
--declare @Strsql as varchar(8000)
--declare @StrMachineId as varchar(8000)
declare @Strsql as nvarchar(4000)
declare @StrMachineId as nvarchar(4000)
---mod 2
declare @StrPlantid as nvarchar(250)
Declare @counter as datetime
declare @StrPlant as nvarchar(250)
declare  @curstarttime as datetime
Declare @curendtime   as datetime
Declare @curMachineID AS NvarChar(50)
Declare @MCursor_MId  As NVarChar(50)     --MachineID AS Cursor Variable For MCursor
Declare @MCursor_Mst As DateTime      --MonthStart  AS Cursor Variable For MCursor
Declare @MCursor_Mnd As DateTime       --MonthEnd AS Cursor Variable For MCursor
declare @cn as int
select @curstarttime=@StartTime
select @cn=0
select @counter=convert(datetime, cast(DATEPART(yyyy,@StartTime)as nvarchar(4))+'-'+cast(datepart(mm,@StartTime)as nvarchar(2))+'-'+cast(datepart(dd,@StartTime)as nvarchar(2)) +' 00:00:00.000')
create table #TempTimeShift
(
	Pdate datetime,
	shift nvarchar(50),
	Frmtime datetime,
	totime datetime
)
create table #Templossdaymonth
(
	machineid nvarchar(50),
	dayval datetime,
	sttime datetime,
	ndtime datetime,
	shift nvarchar(50),
	Moneylost float,
	Reasontot float,
	machinetot float,
	mcount int,
	daycnt int
)
if @CompType='Shift'
begin
	insert into #TempTimeShift(Pdate,Shift,Frmtime,totime)
	exec s_GetShiftTime @StartTime,''
end
if @CompType='Day'
begin
	
	While(@counter <= @EndTime) and @cn<=31
		BEGIN
			select @curstarttime=dbo.f_GetLogicalDay(@curstarttime,'start')
			select @curendtime=dbo.f_GetLogicalDay(@curstarttime,'end')
			Insert into #TempTimeShift(Pdate,Frmtime,Totime)
			select @Counter,@curstarttime,@curendtime
			SELECT @curstarttime = Dateadd(Day,1,@curstarttime)
			SELECT @counter = Dateadd(Day,1,@counter)
			select @cn=@cn+1
		END
end
declare @mon as integer
--if @CompType='Month'
--begin
--	select @mon=month(@Counter)
--	while(@mon<=month(@EndTime))
--		begin
--			select @curstarttime=dbo.f_GetLogicalMonth(@curstarttime,'start')
--			select @curendtime=dbo.f_GetLogicalMonth(@curstarttime,'end')
--			Insert into #TempTimeShift(Pdate,Frmtime,Totime)
--			select convert(datetime, cast(DATEPART(yyyy,@curstarttime)as nvarchar(4))+'-'+cast(datepart(mm,@curstarttime)as nvarchar(2))+'-'+cast(datepart(dd,@curstarttime)as nvarchar(2)) ),@curstarttime,@curendtime
--			SELECT @curstarttime = Dateadd(month,1,@curstarttime)
--			SELECT @counter = Dateadd(month,1,@counter)
--			select @mon=month(@Counter)
--		end
--end

--DR0380 : Get number of months in the range and then increment counter
if @CompType='Month' --g:
begin
	declare @totmon as int
	select @totmon = datediff(m, @StartTime, @EndTime)
	select @mon=0
	while(@mon<=@totmon)
		begin
			select @curstarttime=dbo.f_GetLogicalMonth(@curstarttime,'start')
			select @curendtime=dbo.f_GetLogicalMonth(@curstarttime,'end')
			Insert into #TempTimeShift(Pdate,Frmtime,Totime)
			select convert(datetime, cast(DATEPART(yyyy,@curstarttime)as nvarchar(4))+'-'+cast(datepart(mm,@curstarttime)as nvarchar(2))+'-'+cast(datepart(dd,@curstarttime)as nvarchar(2)) ),@curstarttime,@curendtime
			SELECT @curstarttime = Dateadd(month,1,@curstarttime)
			SELECT @counter = Dateadd(month,1,@counter)
			select @mon=@mon+1
		end
end
--DR0380

IF ISNULL(@PlantID,'')<>''
BEGIN
---mod 2
--SELECT @StrPlant=' And PlantMachine.PlantID='''+ @PlantID +''''
SELECT @StrPlant=' And PlantMachine.PlantID= N'''+ @PlantID +''''
---mod 2
END

--select * from #TempTimeShift
--if @CompType
select @Strsql=''
select @Strsql='insert into #Templossdaymonth (machineid,dayval,shift,sttime,ndtime,Moneylost) '
select @Strsql=@strsql+' select machineinformation.machineid,#TempTimeShift.Pdate,#TempTimeShift.shift,#TempTimeShift.Frmtime,#TempTimeShift.ToTime, 0 from machineinformation'
select @Strsql=@strsql+' cross join #TempTimeShift  LEFT OUTER JOIN PlantMachine ON PlantMachine.MachineID=Machineinformation.MachineID '
if  isnull(@machineid,'') <> '' and isnull(@Plantid,'') <> '' and @Exclude=0
	begin
	select @strsql =  @strsql + ' where  machineinformation.machineid  in (' + @machineid + ')'
	---mod 2
--	select @strsql=@strsql+' And PlantMachine.PlantID='''+ @PlantID +''''
	select @strsql=@strsql+' And PlantMachine.PlantID= N'''+ @PlantID +''''
	---mod 2
	end
print @strsql
if  isnull(@machineid,'') <> '' and isnull(@Plantid,'') <> '' and @Exclude=1
	begin
	select @strsql =  @strsql + ' where  machineinformation.machineid not in (' + @machineid + ')'
	---mod 2
--	select @strsql=@strsql+' And PlantMachine.PlantID='''+ @PlantID +''''
	select @strsql=@strsql+' And PlantMachine.PlantID= N'''+ @PlantID +''''
	---mod 2
	end
	if isnull(@machineid,'') <> '' and isnull(@Plantid,'')='' and @Exclude=0
	begin
	select @strsql =  @strsql + ' where  machineinformation.machineid  in (' + @machineid + ')'
	end
if  isnull(@machineid,'') <> '' and isnull(@Plantid,'') = '' and @Exclude=1
	begin
	select @strsql =  @strsql + ' where  machineinformation.machineid not in (' + @machineid + ')'
	end
if isnull(@Plantid,'')<>'' and isnull(@machineid,'')=''
	begin
	---mod 2
--	select @strsql=@strsql+ ' where plantmachine.plantid=''' +@Plantid+ ''' '
	select @strsql=@strsql+ ' where plantmachine.plantid= N''' +@Plantid+ ''' '
	---mod 2
	end
select @strsql=@strsql+'order by #TempTimeShift.Pdate desc,#TempTimeShift.shift,machineinformation.machineid '
exec (@strsql)
---select * from #Templossdaymonth
print @strsql
select @StrPlantID=''
select @StrMachineId=''
select @strsql=''
if isnull(@PlantID,'')<>''
begin
	---mod 2
--	select @StrPlantID=' AND (SM.PlantID ='''+@PlantID+''')'
	select @StrPlantID=' AND (SM.PlantID = N'''+@PlantID+''')'
	---mod 2
end
IF ISNULL(@MachineID,'')<>'' and @Exclude=0
BEGIN
	SELECT @StrMachineId=' AND (SM.machineid in ('+@MachineID+' ))'
END
IF ISNULL(@MachineID,'')<>'' and @Exclude=1
BEGIN
	SELECT @StrMachineId=' AND (SM.machineid not in ('+@MachineID+' ))'
end
if @CompType='shift'
begin
	select @strsql='update #Templossdaymonth SET MoneyLost = Isnull(moneylost,0) + IsNull(t2.mloss,0)'
	select @strsql=@strsql+'from (select SM.machineid as mch,SM.shift,sum(moneylost) as mloss from ShiftAggMoneyLoss SM '
	select @strsql=@strsql+'where SM.dDate='''+convert(varchar(20),@StartTime)+ ''''
	select @strsql=@strsql+@StrPlantId+@StrMachineid
	select @strsql=@strsql+' group by SM.shift,SM.machineid) '
	select @strsql=@strsql+'as t2 inner join #Templossdaymonth on t2.mch=#Templossdaymonth.machineid and t2.shift=#Templossdaymonth.shift '
	print (@strsql)
	exec (@Strsql)
	
end

if @CompType='day'
begin
	select @strsql='update #Templossdaymonth SET MoneyLost = Isnull(moneylost,0) + IsNull(t2.mloss,0)'
	select @strsql=@strsql+'from (select SM.machineid as mch,sum(moneylost) as mloss,SM.dDate from ShiftAggMoneyLoss SM '
	select @strsql=@strsql+'where SM.dDate>='''+convert(varchar(20),@StartTime)+ ''' and SM.dDate<=''' + convert(varchar(20),@EndTime)+''' '
	select @strsql=@strsql+@StrPlantId+@StrMachineid
	select @strsql=@strsql+' group by SM.dDate,SM.machineid) '
	select @strsql=@strsql+'as t2 inner join #Templossdaymonth on t2.mch=#Templossdaymonth.machineid and t2.dDate=#Templossdaymonth.dayval'
	print (@strsql)
	exec (@Strsql)
end

if @CompType='month'
begin
Declare MCursor  Cursor For SELECT MachineID,sttime,ndtime  From #Templossdaymonth
	OPEN MCursor
	Fetch Next From MCursor Into @MCursor_MId,@MCursor_Mst,@MCursor_Mnd
	While @@Fetch_Status=0
	BEGIN
		select @strsql=''
		select @strsql='UPDATE #Templossdaymonth SET MoneyLost = Isnull(moneylost,0) + IsNull(mloss,0)
				From
				(Select SM.MachineID as mch,Sum(SM.Moneylost) AS mloss,'''+convert(varchar(20),@MCursor_Mst)+''' as strt From ShiftAggMoneyLoss SM
				  LEFT OUTER JOIN PlantMachine ON SM.machineid = PlantMachine.MachineID
				Where (SM.dDate>=''' + convert(varchar(12),@MCursor_Mst)+ ''') AND (SM.dDate<''' + convert(varchar(12),@MCursor_Mnd)+ ''') and SM.machineid=''' +@MCursor_MId+ '''
				Group By SM.machineid
				) AS T2 inner join #Templossdaymonth on T2.mch = #Templossdaymonth.MachineID and t2.strt =#Templossdaymonth.sttime'
		exec (@Strsql)
		print @CompType
		print @strsql
		Fetch Next From MCursor Into @MCursor_MId,@MCursor_Mst,@MCursor_Mnd
	end
end
update #Templossdaymonth set
machinetot=(SELECT SUM(moneylost) FROM #Templossdaymonth as TL WHERE TL.machineID = #Templossdaymonth.machineid)
update #Templossdaymonth set
mcount=(select count(machineid)from (select distinct machineid from #Templossdaymonth  where machinetot>0) as m1)
if @comptype='day' or @comptype='month'
begin
update #Templossdaymonth set
daycnt=(select count(dayval) from (select distinct dayval from #Templossdaymonth where machinetot>0) as m2)
end
if @comptype='shift'
begin
update #Templossdaymonth set
daycnt=(select count(shift) from (select distinct shift from #Templossdaymonth where machinetot>0) as m2)
end
--select * from #Templossdaymonth
---output
--select * from #Templossdaymonth

--if @Comptype='Shift'
--	--select dayval as today,
--	--       shift as dayval,
--	select t1.dayval as today, --g:
--	       t2.shift as dayval, --g:
--	       t1.machineid,
--	       t1.moneylost,
--	       t1.machinetot,
--		t1.mcount,
--		t1.daycnt	
--	 from #Templossdaymonth t1 inner join #Templossdaymonth t2 on t1.machineid = t2.machineid
--	where t1.machinetot>0
--	order by t1.dayval,t1.shift,t1.machinetot desc,t1.mcount
	--order by machinetot desc

--DR0380 : Introduce alias to reuse the column name for another column
if @Comptype='Shift'
	select t1.dayval as today,
	       t1.shift as dayval,
	       t1.machineid,
	       t1.moneylost,
	       t1.machinetot,
		t1.mcount,
		t1.daycnt	
	 from #Templossdaymonth t1 
	where t1.machinetot>0
	order by t1.dayval,t1.shift,t1.machinetot desc,t1.mcount
--DR0380

else if @Comptype='day'-- or @Comptype='month'
	select dayval,
	       moneylost,
	       machineid,
	       machinetot,
		mcount,
		daycnt	
	 from #Templossdaymonth
	where machinetot>0
	--order by machineid, machinetot desc
	
	order by dayval asc,machinetot desc,mcount
else if  @Comptype='month'
	select
		cast(cast(datename(month,dayval) as nvarchar(3))+'-'+cast(datepart(yy,dayval) as nvarchar(4)) as nvarchar(20)) as  dayval,
	       moneylost,
	       machineid,
	       machinetot,
	       dayval as months,
		mcount,
		daycnt
	      -- count( machineid) from (select distinct machineid from #Templossdaymonth) as mcount	
		--count(select distinct machineid from #Templossdaymonth) as mcount
	 from #Templossdaymonth
	where machinetot>0
	order by months asc,machinetot desc,mcount
end
