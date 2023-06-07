/****** Object:  Procedure [dbo].[s_GetDantal_Downtime]    Committed by VersionSQL https://www.versionsql.com ******/

/*------------Procedure Created By Karthik R on 04/Sep/2010------------------------------
Prediction logic has been implemented for Downtime
From the last record we start predicting the downtime after applying 10 minutes thershold
Select * from rawdata --where slno=782913
order by slno desc
Select * from planneddowntimes where machine='MLC WELD SPM' order by starttime desc
Select * from machineinformation where interfaceid=12
s_GetDantal_Downtime 'MLC PUMA 400 L','2010-09-04 00:00:00'
ER0334 - SwathiKS - 24/Sep/2012 :: To handle escalation logic when datatype=1,2,40 and 42
and implemented backtobackdowns when datatype = 2 or 42 for QHT.
DR0319 - SwathiKS/GeetanjaliK - 21/Nov/12 :: To handle "Invalid use of null" when Track="DowntimeEscalation" in SmartAgent For QHT.
--[dbo].[s_GetDantal_Downtime1] 'MBC WELD SPM','2010-07-21 18:07:05.107','BacktoBackDowns'
-----------------------------------------------------------------------------------------*/
CREATE PROCEDURE [dbo].[s_GetDantal_Downtime]
	@machineID as nvarchar(100),
	@Starttime datetime,
	@param as nvarchar(50)= 'CurrentStatus' --'CurrentStatus' or 'BacktoBackDowns' --ER0334 Added
AS
BEGIN

Declare @Startdate as Datetime
Declare @mcinterface as bigint
Declare @actualDown as bigint
Declare @TIMEFORMAT as NVARCHAR(10)
Declare @pdt as bigint
declare @Recordsttime as datetime --ER0334 Added
declare @recordndtime as datetime --ER0334 Added
declare @RecordDatatype as bigint --ER0334 Added
declare @recordslno as bigint --ER0334 Added
declare @maxslno as bigint --ER0334
declare @curtime as datetime --ER0334 added

select @curtime = @Starttime


CREATE TABLE #DowntimeData
	(
		StartTime datetime,
		Max_Slno bigint,
		MachineID NvarChar(50),
		MachineInterface nvarchar(50),
		DownTime int,
		Recordsttime datetime, --ER0334 Added
		Recordndtime datetime --ER0334 added
	)

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
BEGIN TRANSACTION
set @pdt=0
Select @TIMEFORMAT=isnull(valueintext,'SS') from shopdefaults where parameter='TimeInFormat' order by parameter
PRINT(@TIMEFORMAT)



If @param = 'CurrentStatus'  --ER0334 Added Line
Begin						 --ER0334 Added Line


	insert into #DowntimeData(MachineID,MachineInterface,Max_slno)
	Select M.MachineID,M.interfaceID,max(slno) as sno from  machineinformation  M
	left outer join rawdata R on R.mc=M.interfaceid
	Group by M.MachineID,M.interfaceID
	print (@mcinterface)


	/*Calculating startime of the predicted down */
	update #downtimeData Set Starttime=T2.StartDate
	From #downtimeData inner join
	(Select mc,Case
			when Datatype=1 then Dateadd(n,10,ndtime)
			when (Datatype=2 and [status]=0) or datatype=40 then Dateadd(n,10,sttime)
			when (Datatype=2 and [status]=1) or datatype=42 then  Dateadd(n,10,ndtime)
			End as StartDate
	from rawdata inner join #downtimeData
	on mc=Machineinterface and slno=Max_Slno
	)T2 On mc=Machineinterface

	/*if last record was not found or starttime of the last record is less than starttime of intersted time period*/
	Update #DowntimeData set Starttime=@starttime  where isnull(Max_slno,1)=1
	or Starttime<@starttime

	/*calculating Actual down time*/
	update #downtimeData Set Downtime=datediff(ss,Starttime,dateadd(hh,1,@starttime))
	where Starttime>=@starttime and Starttime<dateadd(hh,1,@starttime)

	/*Appling PDT*/
	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
	BEGIN
				
				update #downtimeData set downtime=downtime-down from #downtimedata
				inner join (
					Select t1.machineid,sum(isnull(datediff(ss,T1.StartTime,T1.EndTime),0))as down
					from
					(
					select D.machineid,
					Case when  D.Starttime <= pdt.StartTime then pdt.StartTime else  D.Starttime End as StartTime,
					Case when dateadd(hh,1,@starttime) >= pdt.EndTime then pdt.EndTime else dateadd(hh,1,@starttime) End as EndTime
					From Planneddowntimes pdt
					inner join #DowntimeData D on D.machineid=Pdt.machine
					where PDTstatus = 1  and --pdt.Machine=@machineid and
					((pdt.StartTime >= D.Starttime and pdt.EndTime <= dateadd(hh,1,@starttime))or
					(pdt.StartTime < D.Starttime and pdt.EndTime > D.Starttime and pdt.EndTime <=dateadd(hh,1,@starttime))or
					(pdt.StartTime >= D.Starttime and pdt.StartTime <dateadd(hh,1,@starttime) and pdt.EndTime >dateadd(hh,1,@starttime)) or
					(pdt.StartTime <  D.Starttime and pdt.EndTime >dateadd(hh,1,@starttime)))
				) T1
					group by T1.machineid
				)t2 on t2.machineid=#downtimedata.machineId
	End

END    

----ER0334 Added From Here
If @param = 'BacktoBackDowns'
Begin

	insert into #DowntimeData(MachineID,MachineInterface,Max_slno)
	Select M.MachineID,M.interfaceID,max(slno) as sno from  machineinformation  M
	left outer join rawdata R on R.mc=M.interfaceid
	where M.machineid=@machineid
	Group by M.MachineID,M.interfaceID

	select @maxslno= Max_slno from #DowntimeData 
	select @RecordDatatype= datatype from rawdata where slno=@maxslno

	update #DowntimeData set Recordsttime = T1.sttime,Recordndtime = T1.ndtime from
	(select sttime,ndtime FROM rawdata where slno=@maxslno)T1


	select @Recordsttime = Recordsttime,@recordndtime = Recordndtime from #DowntimeData 
	set @recordndtime = @Recordsttime 


	print @Recordsttime
	print @recordndtime
	print @RecordDatatype
	
	If @RecordDatatype= '1' or @RecordDatatype= '40'
	Begin
		update #downtimeData Set Starttime=T2.StartDate
		From #downtimeData inner join
		(Select mc,Case 
		when Datatype=1 then Dateadd(n,10,ndtime) 
		when datatype=40 then Dateadd(n,10,sttime)
		End as StartDate
		from rawdata inner join #downtimeData
		on mc=Machineinterface and slno=Max_Slno
		)T2 On mc=Machineinterface
	End

	If @RecordDatatype= '2' or @RecordDatatype= '42'
	Begin
		update #downtimedata set starttime = @recordsttime 
	End

	while  @recordsttime=@recordndtime and (@RecordDatatype= '2' or @RecordDatatype= '42')
	Begin
			
			select @recordslno = max(slno) from rawdata where slno<@maxslno and mc = 
			(select Machineinterface from #downtimedata)		
			
			select @RecordDatatype = datatype from rawdata where slno=@recordslno

			If @RecordDatatype = ' 2'
			begin
				select @recordsttime = sttime from rawdata where datatype=2 and 
				slno=@recordslno and ndtime = @recordsttime
			end
			
			If @RecordDatatype = '42'
			begin
				select @recordsttime = sttime from rawdata where datatype=42 and 
				slno=@recordslno and ndtime = @recordsttime
			end


			If @recordsttime <> '' 
			Begin 
				update #downtimedata set starttime = @recordsttime 
				set @recordndtime = @recordsttime
				set @maxslno=@recordslno
				set @RecordDatatype= @RecordDatatype
			end

			If isnull(@recordsttime,'1900-01-01') = '1900-01-01' 
			Begin	
				set @recordsttime = '1900-01-01'
			end
	END


	/*if last record was not found or starttime of the last record is less than starttime of intersted time period*/
	Update #DowntimeData set Starttime=@starttime where isnull(Max_slno,1)=1
--Select * from #downtimeData
	/*calculating Actual down time*/
	update #downtimeData Set Downtime=datediff(n,Starttime,@curtime)

	/*Appling PDT*/
	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
	BEGIN
				
				update #downtimeData set downtime=downtime-down from #downtimedata
				inner join (
					Select t1.machineid,sum(isnull(datediff(ss,T1.StartTime,T1.EndTime),0))as down
					from
					(
					select D.machineid,
					Case when  D.Starttime <= pdt.StartTime then pdt.StartTime else  D.Starttime End as StartTime,
					Case when @curtime >= pdt.EndTime then pdt.EndTime else @curtime End as EndTime
					From Planneddowntimes pdt
					inner join #DowntimeData D on D.machineid=Pdt.machine
					where PDTstatus = 1  and --pdt.Machine=@machineid and
					((pdt.StartTime >= D.Starttime and pdt.EndTime <= @curtime)or
					(pdt.StartTime < D.Starttime and pdt.EndTime > D.Starttime and pdt.EndTime <=@curtime)or
					(pdt.StartTime >= D.Starttime and pdt.StartTime <@curtime and pdt.EndTime >@curtime) or
					(pdt.StartTime <  D.Starttime and pdt.EndTime >@curtime))
					) T1
					group by T1.machineid
				)t2 on t2.machineid=#downtimedata.machineId
	End

END
---ER0334 Added Till Here


-----Select machineid,[dbo].[f_FormatTime](downtime,@timeformat) as downtime,StartTime from #downtimeData order by machineid

--Select machineid,downtime,StartTime from #downtimeData order by machineid --DR0319 Commented
Select machineid,isnull(downtime,0) as downtime,StartTime from #downtimeData where downtime>0 order by machineid --DR0319 Added

Commit TRANSACTION

END
