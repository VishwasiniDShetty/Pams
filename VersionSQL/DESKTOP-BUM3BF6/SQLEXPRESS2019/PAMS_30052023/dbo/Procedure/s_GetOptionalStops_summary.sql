/****** Object:  Procedure [dbo].[s_GetOptionalStops_summary]    Committed by VersionSQL https://www.versionsql.com ******/

/***************************************      History     *******************************************
Used in VDG for BOSCH

NR0051: Procedure created by Mrudula on 22-dec-2008. Get the summary of  optional stops for the given starttime
        and endtime of a production cycle and machineid.
mod 1:- By Mrudula M. Rao on 13-jan-2009 for ER0161 . Introduced componentid and operationno input parameters to get summary at component level
mod 2:- By Mrudula M. Rao on 16-jan-2009 for ER0162. Use datatype 70 for optional stop start and 71 for optional stop end. Instead of 40 and 41
	
s_GetOptionalStops_summary '35810_AMS','12/Mar/2008 2:00:00 AM','12/Mar/2008 6:25:50 PM','','ROLLER  RING',1
****************************************************************************************************/


CREATE           PROCEDURE [dbo].[s_GetOptionalStops_summary]

	@MachineID nvarchar(50) = '',
	@StartTime datetime ,
	@EndTime datetime ,
	@PlantID nvarchar(50)=''
	---mod 1
	,@componentid nvarchar(50)='',
	@Operation nvarchar(50)=''
	---mod 1
	
AS
BEGIN

Declare @strPlantID as nvarchar(255)
Declare @strSql as nvarchar(4000)
Declare @strMachine as nvarchar(255)
declare @timeformat as nvarchar(2000)
declare @curstarttime as datetime
declare @curendtime as datetime
declare @nxtstarttime as datetime
declare @nxtendtime as datetime
declare @CycStarttime as datetime
declare @CycEndtime as datetime
---mod 1
declare @strcomponent as nvarchar(50)
declare @stroperation as nvarchar(50)
---mod 1
				
SELECT @strMachine = ''
SELECT @strPlantID = ''
SELECT @timeformat ='ss'
---mod 1
select @strcomponent=''
select @stroperation=''
--mod 1

Select @timeformat = isnull((select valueintext from cockpitdefaults where parameter='timeformat'),'ss')
if (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')
begin
	select @timeformat = 'ss'
end



if isnull(@machineid,'')<> '' 
begin
	SET @strMachine = ' AND M.MachineID = ''' + @machineid + ''''
	
end
if isnull(@PlantID,'')<> ''
Begin
	SET @strPlantID = ' AND PlantMachine.PlantID = ''' + @PlantID + ''''
End



---mod 1
if isnull(@componentid, '') <> ''
begin
	select @strcomponent = ' AND ( C.componentid = ''' + @componentid+ ''')'
	
end
if isnull(@Operation, '') <> ''
begin
	select @stroperation = ' AND ( O.Operationno = ''' + @Operation + ''')'
	
end
---mod 1

create table #OptionalStops
      (
	Machineid nvarchar(50),
	CycStart datetime,
	CycEnd datetime,
	StartTime datetime,
	Endtime datetime,
	StopTime int
      )

Create table #NStops
    (MachID nvarchar(50),
     Strt datetime,
     ndtime datetime,
    RecordType int
    )

Create table #AllCycles
	(
	   Machineid nvarchar(50),
	   CycStart datetime,
	   CycEnd datetime
	)

---mod 1
/*insert into #AllCycles(Machineid,CycStart,CycEnd )
select @MachineID,A.sttime,A.ndtime from autodata A inner join machineinformation M
on A.mc=M.interfaceid Where M.Machineid=@MachineID and A.sttime>= @StartTime and A.ndtime<=@EndTime
and A.datatype=1 ORDER BY A.sttime ASC*/
---mod 1
--mod 1
select @strSql=''

select @strSql='insert into #AllCycles(Machineid,CycStart,CycEnd )
select M.Machineid,A.sttime,A.ndtime from autodata A inner join machineinformation M
on A.mc=M.interfaceid  inner join Componentinformation C on C.interfaceid=A.comp inner join 
Componentoperationpricing O on O.interfaceid=A.opn and C.componentid=O.componentid 
where A.sttime>=''' + convert(nvarchar(20), @StartTime,120) + ''' and A.ndtime<=''' + convert(nvarchar(20), @EndTime,120) + '''
and A.datatype=1 '
select @strSql=@strSql+@strMachine+@strcomponent+@stroperation

--print @strSql

--print @stroperation
Exec (@strSql)
---mod 1
---return
declare CycCursor cursor  for 
select CycStart,Cycend from #AllCycles
open CycCursor
fetch next from CycCursor into @CycStarttime,@CycEndtime
while 	(@@fetch_status=0)
BEGIN

	insert into #NStops(MachID,Strt,RecordType )
	Select M.Machineid,A.starttime,A.recordtype
	from autodatadetails A inner join machineinformation M on M.interfaceid=A.Machine
	Where M.Machineid=@MachineID and A.starttime> @CycStarttime and A.Starttime<@CycEndtime
	---mod 2	
	---and A.Recordtype in (40,41)
	and A.Recordtype in (70,71)
	---mod 2
	order by A.Starttime ASC
	
	DECLARE Optcursor  cursor for
	select Strt,ndtime from #NStops
		open Optcursor
		fetch next from Optcursor into @curstarttime,@curendtime	
		IF (@@fetch_status = 0)
	BEGIN
		fetch next  from Optcursor into @nxtstarttime,@nxtendtime	
		while (@@fetch_status = 0)
	BEGIN
		set @curendtime = @nxtstarttime
		update #NStops set ndtime = @curendtime  where Strt=@curstarttime
		SET @curstarttime=@nxtstarttime
		FETCH NEXT  from Optcursor into @nxtstarttime,@nxtendtime	
	END
		UPDATE #NStops set ndtime=@CycEndtime   where Strt=@curstarttime
	END
	
	close Optcursor
	deallocate Optcursor
	insert into #OptionalStops(Machineid,CycStart,CycEnd,StartTime,Endtime,StopTime)
	select MachID,@CycStarttime,@CycEndtime,Strt,ndtime,Datediff(s,Strt,ndtime) from #NStops
	where RecordType=70
	
	delete from #NStops

	fetch next from CycCursor into @CycStarttime,@CycEndtime

END ---for CycCursor
	
close CycCursor
deallocate CycCursor

declare @TotCyc as Float

select @TotCyc=(select sum(datediff(s,CycStart,CycEnd)) from #AllCycles)


Select @MachineID as MachineId ,dbo.f_FormatTime(datediff(s,@StartTime,@EndTime),@timeformat) as totaltime ,count(distinct N.CycStart) as CycLeCount,dbo.f_FormatTime(@TotCyc,@timeformat) as CycleTime
,count(O.StartTime) as OptionalStpCount, dbo.f_FormatTime(sum(O.StopTime),@timeformat) as OptionalStopTime,
(100*sum(O.StopTime))/isnull(@TotCyc,1) as percentoptional from  #AllCycles N
left outer join  #OptionalStops O on N.CycStart=O.CycStart 

 
END
