/****** Object:  Procedure [dbo].[s_getDNCUsage]    Committed by VersionSQL https://www.versionsql.com ******/

/*****************************************************************
-ER0272 - 11/Nov/2010 - SwathiKS ::DNC Transfer->Log->Manage :: New Excel Report To show DNC Usage Details.
ReportName->DNCUsageReport_Template.xls
ER0298 - 09/Aug/2011 - SwathiKS :: To Introduce QTY Produced For DNCUsageReport_Template.xls.
ER0321 - SwathiKS - 08/feb/2012 :: To handle qty Mismatch.
ER0325 - SwathiKS - 22/feb/2012 :: a> To Update Quantity at Machine Level.
				   b> To Show specific logmessages in DNC Usage Report.
ER0327 - SwathiKS - 12/Apr/2012 :: To Include Prediction logic for starttime and endtime while updating Quantity.
ER0372 - SwathiKS - 22/Jan/2014 :: To include LogicalDaystart(DNCTimestamp) in Output.
ER0430 - SwathiKS - 18/Feb/2016 :: To include New column ProgramTransferEnd.
*****************************************************************/
--s_GetDNCUsage '2016-jan-13 06:00:00 AM','2016-jan-13 06:00:00 PM','9580','','','Successful Transfer with QTY'
CREATE       procedure [dbo].[s_getDNCUsage]
@starttime datetime,
@endtime datetime,
@machineid nvarchar(50)='',
@UserName nvarchar(10)='',
@clientname nvarchar(20)='',
@Param nvarchar(50)
as
Begin
declare @strsql as nvarchar(2000)
Declare @strMachine as nvarchar(1000)
select @strMachine = ''
create table #DNC_log
(
	Idd bigint,
	MachineID nvarchar(50),
	ClientName nvarchar(50),
	UserName nvarchar(50),
	Logmessage nvarchar(250),
	ProgramID nvarchar(50),
	TimeStamp datetime,
	TransferEnd datetime, --SV
	QTY int
)

--ER0430 From Here
create table #TempDNC_log1
(
	Idd bigint,
	MachineID nvarchar(50),
	ProgramID nvarchar(50),
	TransferStart datetime
)

create table #TempDNC_log
(
	Idd bigint,
	MachineID nvarchar(50),
	ProgramID nvarchar(50),
	TransferStart datetime,
	Endtime datetime,
	TransferEnd datetime,
	Comparestarttime datetime
)
--ER0430 Till Here

------------ER0327 Commented and Added From Here----------
/*
--ER0298 From Here.
create table #DNC_logWithQTY
(
	MachineID nvarchar(50),
	ProgramID nvarchar(50),
	starttime datetime,
	endtime datetime,
	QTY int
)
--ER0298 Till Here.
*/

create table #DNC_logWithQTY
(
	MachineID nvarchar(50),
	ProgramID nvarchar(50),
	starttime datetime,
	endtime datetime,
	Comparestarttime datetime,
	Logmessage nvarchar(250),
	QTY int
)

create table #DNC_logwithtimestamp
(
	MachineID nvarchar(50),
	ProgramID nvarchar(50),
	compareminstarttime datetime,
	comparemaxstarttime datetime,
	MinStarttime datetime,
	Maxendtime datetime,
	Logmessage nvarchar(250),
	Comparetime datetime
)
------------ER0327 Commented and Added Till Here----------


if isnull(@machineid,'') <> ''
begin
select @strMachine =  @strMachine +  ' and ( dnc_log.machineid = ''' + @machineid + ''')'
end
If isnull(@Param,'') = 'Successful Transfer'
Begin
	select @strsql = ''
	select @strsql = @strsql + 'select case when MachineID='''' then ''NA'' When MachineID<>'''' then MachineID end as MachineID,ClientName,UserName,Logmessage,substring(logmessage,charindex(''<'',logmessage),len(logmessage)) as ProgramID,TimeStamp from dnc_log '
	select @strsql = @strsql + 'where [TimeStamp] >=  ''' + convert(nvarchar(20),@StartTime) +'''  and [TimeStamp] <= ''' + convert(nvarchar(20),@EndTime)+''' '
	select @strsql = @strsql + 'and logmessage like ''Sending file to Machine%'' and ErrorNumber=0 and MessageType=''Action'' '
	select @strsql = @strsql + @strMachine
	select @strsql = @strsql + 'order by idd'
	print @strsql
	exec(@strsql)
End
If @Param = 'Errors Only'
Begin
	select @strsql = ''
	select @strsql =  'select case when MachineID='''' then ''NA'' When MachineID<>'''' then MachineID end as MachineID,ClientName,UserName,Logmessage, '
	select @strsql = @strsql + 'case when  charindex(''<'',logmessage)<=0 then ''Unknown''
	 when  charindex(''<'',logmessage)>-1 then  substring(logmessage,charindex(''<'',logmessage),len(logmessage))end as ProgramID,TimeStamp from dnc_log '	
	select @strsql = @strsql + 'where [TimeStamp] >= '''+ convert(nvarchar(20),@StartTime)+'''  and [TimeStamp] <= '''+convert(nvarchar(20),@EndTime)+''' '
	select @strsql = @strsql + 'and MessageType = ''Error'' '
	select @strsql = @strsql + @strMachine
	select @strsql = @strsql + 'order by idd'
	exec(@strsql)
End
If @Param = 'ALL'
Begin
select @strsql = ''
	select @strsql =@strsql + 'select case when MachineID='''' then ''NA'' When MachineID<>'''' then MachineID end as MachineID,ClientName,UserName,Logmessage, '
	select @strsql = @strsql + 'case when  charindex(''<'',logmessage)<=0 then ''Unknown''
	when  charindex(''<'',logmessage)>-1 then  substring(logmessage,charindex(''<'',logmessage),len(logmessage))end as ProgramID,MessageType,TimeStamp from dnc_log '
	select @strsql = @strsql + 'where [TimeStamp] >= '''+convert(nvarchar(20),@StartTime)+'''  and [TimeStamp] <= '''+convert(nvarchar(20),@EndTime)+''' '
	--select @strsql = @strsql+'and (' + @strMachine
	--select @strsql = @strsql + 'or Logmessage=''LoggedIN''or Logmessage=''LoggedOut'' )'
	select @strsql = @strsql+ @strMachine
	select @strsql = @strsql + 'order by idd'
	print(@strsql)
	exec(@strsql)
End
If @Param = 'ALL - Except Errors'
Begin
select @strsql = ''
	select @strsql =@strsql + 'select case when MachineID='''' then ''NA'' When MachineID<>'''' then MachineID end as MachineID,ClientName,UserName,Logmessage, '
	select @strsql = @strsql + 'case when  charindex(''<'',logmessage)<=0 then ''Unknown''
	when  charindex(''<'',logmessage)>-1 then  substring(logmessage,charindex(''<'',logmessage),len(logmessage))end as ProgramID,MessageType,TimeStamp from dnc_log '
	select @strsql = @strsql + 'where [TimeStamp] >= '''+convert(nvarchar(20),@StartTime)+'''  and [TimeStamp] <= '''+convert(nvarchar(20),@EndTime)+''' '
select @strsql = @strsql + 'and MessageType <> ''Error'' '
select @strsql = @strsql+ @strMachine
select @strsql = @strsql + 'order by idd'
	print(@strsql)
	exec(@strsql)
End
--ER0298 From Here.
If @Param = 'Successful Transfer With QTY'
Begin
	select @strsql = ''
	select @strsql = @strsql + 'Insert into #DNC_log(Idd,Machineid,ClientName,UserName,Logmessage,ProgramID,TimeStamp,QTY) '
	select @strsql = @strsql + 'select Idd,case when MachineID='''' then ''NA'' When MachineID<>'''' then MachineID end as MachineID,ClientName,UserName,Logmessage,case when  charindex(''<'',logmessage)<=0 then ''Unknown'' when  charindex(''<'',logmessage)>-1 then substring(logmessage,charindex(''<'',logmessage),charindex(''>'',logmessage)-charindex(''<'',logmessage)+1) END as ProgramID,
								TimeStamp,0 from dnc_log '
	select @strsql = @strsql + 'where [TimeStamp] >=  ''' + convert(nvarchar(20),@StartTime) +'''  and [TimeStamp] <= ''' + convert(nvarchar(20),@EndTime)+'''
								and logmessage like ''%Transferred Successfully To the Asset%'' and ErrorNumber=0 and MessageType=''Action'''
	select @strsql = @strsql + @strMachine
	select @strsql = @strsql + 'order by idd'
	print @strsql
	exec(@strsql)


	/******************** ER0327 Commented From Here *****************
	insert into #DNC_logWithQty(MachineID,ProgramID,starttime,Endtime,QTY)
	Select v.Machineid,V.programid,v.timestamp as time1, min(v1.timestamp) as time2,0
	from (Select * from #DNC_log) V inner join #DNC_log V1 on v.machineid=v1.machineid
	where  v1.idd>v.idd
	group by v.Machineid,v.timestamp,V.programid
	order by v.timestamp

	declare @maxendtime as datetime
	--select @maxendtime = max(endtime) from #DNC_logWithQty ER0325 Commented By Swathi
	select @maxendtime = max(timestamp) from #DNC_log --ER0325 Added By Swathi
	
	If @maxendtime<@endtime
	begin
		insert into #DNC_logWithQty(MachineID,ProgramID,starttime,Endtime,QTY)
		--select machineid,Programid,@maxendtime,@endtime,0 from #DNC_logWithQty where endtime=@maxendtime ER0325 Commented By Swathi
		select machineid,Programid,@maxendtime,@endtime,0 from #DNC_log where timestamp=@maxendtime --ER0325 Added By Swathi
	end
	******************** ER0327 Commented Till Here *****************/

	/******************** ER0327 Added From Here *****************/
	insert into #DNC_logWithQty(MachineID,ProgramID,Logmessage,Comparestarttime,starttime,Endtime,QTY)
	Select v.Machineid,V.programid,v.logmessage,v.timestamp as time1,v.timestamp,min(v1.timestamp) as time2,0
	from (Select * from #DNC_log) V inner join #DNC_log V1 on v.machineid=v1.machineid
	where  v1.idd>v.idd
	group by v.Machineid,v.timestamp,V.programid,v.logmessage
	order by v.timestamp



	Insert into #DNC_logwithtimestamp(Machineid,compareminstarttime,MinStarttime,comparetime)
	select DNC_log.Machineid,max(DNC_log.timestamp),case when max(DNC_log.timestamp)<@starttime then @starttime else max(DNC_log.timestamp)end,T1.Comparetime from DNC_log
	inner join (select Machineid, min(timestamp) as  Comparetime from #DNC_log group by machineid)T1 on T1.Machineid = DNC_log.Machineid
    where logmessage like '%Transferred Successfully To the Asset%' 
	and ErrorNumber=0 and MessageType='Action' and timestamp<@starttime
	group by DNC_log.machineid,T1.Comparetime

	update #DNC_logwithtimestamp set Programid = T1.Programid,Logmessage = T1.Logmessage
	from
	(
		select Machineid,Logmessage,Timestamp,substring(logmessage,charindex('<',logmessage),charindex('>',logmessage)-charindex('<',logmessage)+1) as ProgramID
		from dnc_log where timestamp <@starttime
	)T1 inner join #DNC_logwithtimestamp on T1.Machineid = #DNC_logwithtimestamp.Machineid and T1.timestamp= #DNC_logwithtimestamp.compareminstarttime


	Insert into #DNC_logWithQty(MachineID,ProgramID,Logmessage,Comparestarttime,starttime,Endtime,QTY)
	select Machineid,Programid,Logmessage,compareminstarttime,MinStarttime,comparetime,0 from #DNC_logwithtimestamp 

	Insert into #DNC_logwithtimestamp(Machineid,comparemaxstarttime,Maxendtime,comparetime)
	select DNC_log.Machineid,max(DNC_log.timestamp),case when max(DNC_log.timestamp)<@endtime then @endtime else max(DNC_log.timestamp)end,T1.Comparetime from DNC_log
	inner join (select Machineid, max(timestamp) as  Comparetime from #DNC_log group by machineid)T1 on T1.Machineid = DNC_log.Machineid
    where logmessage like '%Transferred Successfully To the Asset%' 
	and ErrorNumber=0 and MessageType='Action' and timestamp<@endtime
	group by DNC_log.machineid,T1.Comparetime

	update #DNC_logwithtimestamp set Programid = T1.Programid,Logmessage = T1.Logmessage
	from
	(
		select Machineid,Logmessage,Timestamp,substring(logmessage,charindex('<',logmessage),charindex('>',logmessage)-charindex('<',logmessage)+1) as ProgramID
		from dnc_log where timestamp <@endtime
	)T1 inner join #DNC_logwithtimestamp on T1.Machineid = #DNC_logwithtimestamp.Machineid and T1.timestamp= #DNC_logwithtimestamp.comparemaxstarttime


	Insert into #DNC_logWithQty(MachineID,ProgramID,Logmessage,Comparestarttime,starttime,Endtime,QTY)
	select Machineid,Programid,Logmessage,comparetime,comparemaxstarttime,Maxendtime,0 from #DNC_logwithtimestamp 
	where comparemaxstarttime = comparetime
	/******************** ER0327 Added Till Here *****************/



	/****************** ER0325 as on 20/feb/12 Commented From Here *******************************
	update #DNC_logWithQty set QTY = isnull(QTY,0) + isnull(T1.cnt,0) from
	(select M.machineid,'<' + P.Programname + '>' as Programname,sum(partscount) as cnt,D.starttime,D.endtime
	 from Autodata A
	inner join Machineinformation M on M.interfaceid=A.mc
	inner join componentinformation C on C.interfaceid=A.comp
	inner join Componentoperationpricing CI on C.componentid=CI.componentid
	and A.opn=CI.interfaceid and CI.Machineid=M.machineid
	inner join (select Programname,p1.machineid,componentid,operationno,timestamp
	 from Programuploadtomachine P1 
	where P1.timestamp>=@starttime and P1.timestamp<=@endtime) --ER0321 added
	-- P on P.machineid=M.Machineid and P.componentid=CI.componentid and P.operationno=CI.operationno ER0325 Commented By Swathi
	 P on P.machineid=M.Machineid and P.componentid=C.componentid and P.operationno=CI.operationno --ER0325 Added By Swathi
	inner join #DNC_logWithQty D on D.Machineid=P.Machineid and D.Programid='<' + P.Programname + '>'
	Where (A.ndtime>D.starttime and A.ndtime<=D.endtime)
	and A.datatype=1
	group by M.machineid,P.Programname,D.starttime,D.endtime)T1
	inner join #DNC_logWithQty D on D.machineid = T1.Machineid and D.programid=T1.Programname and
	D.starttime=T1.starttime and D.endtime=t1.endtime
	*********************** ER0325 as on 21/feb/12 Commented Till Here **********************/
	
	

    	--ER0325 as on 21/feb/12 Added From Here
	update #DNC_logWithQty set QTY = isnull(QTY,0) + isnull(T1.cnt,0) from
	(select M.machineid,d.programid as Programid,sum(partscount) as cnt,D.starttime,D.endtime
	 from Autodata A
	inner join Machineinformation M on M.interfaceid=A.mc
	inner join #DNC_logWithQty D on D.Machineid=M.Machineid 
	Where (A.ndtime>D.starttime and A.ndtime<=D.endtime)
	and A.datatype=1
	group by M.machineid,D.starttime,D.endtime,d.programid)T1
	inner join #DNC_logWithQty D on D.machineid = T1.Machineid and D.programid=T1.Programid and
	D.starttime=T1.starttime and D.endtime=t1.endtime
	--ER0325 as on 21/feb/12 Added Till here 


	Delete from #dnc_log

	select @strsql = ''
	select @strsql = @strsql + 'Insert into #DNC_log(Idd,Machineid,ClientName,UserName,Logmessage,ProgramID,TimeStamp,QTY) '
	select @strsql = @strsql + 'select Idd,case when MachineID='''' then ''NA'' When MachineID<>'''' then MachineID end as MachineID,ClientName,UserName,Logmessage,case when  charindex(''<'',logmessage)<=0 then ''Unknown'' when  charindex(''<'',logmessage)>-1 then substring(logmessage,charindex(''<'',logmessage),charindex(''>'',logmessage)-charindex(''<'',logmessage)+1) END as ProgramID,
								TimeStamp,0 from dnc_log '
	select @strsql = @strsql + 'where [TimeStamp] >=  ''' + convert(nvarchar(20),@StartTime) +'''  and [TimeStamp] <= ''' + convert(nvarchar(20),@EndTime)+''' '
	--ER0325 Added From Here
	select @strsql = @strsql + 'and (logmessage like ''%Transferred Successfully To the Asset%'' or logmessage like ''%Logged%''
	or logmessage like ''Connection%'' or logmessage like ''%Disconnected%'' or logmessage like ''%In viewing%'' or logmessage like ''%ProgramDeleted%'' or
	logmessage like ''%ProgramSaved%'' or logmessage like ''%The attempt to connect timed out%'' or logmessage like ''%The connection is reset by remote side%''
	or logmessage like ''%Transfer in Progress To The Asset%'') --SV added line
	and ErrorNumber=0 and MessageType=''Action'''
	--ER0325 Added Till Here
	select @strsql = @strsql + @strMachine
	select @strsql = @strsql + 'order by idd'
	print @strsql
	exec(@strsql)



	/*********************** ER0327 Commented From Here **************	
	update #dnc_log set QTY = T1.qty from
	(select D.machineid,programid,starttime,Qty from #DNC_logWithQty D
	inner join Programuploadtomachine P on D.Machineid=P.Machineid  ----ER0325 as on 21/feb/12 Added 
	and D.Programid='<' + P.Programname + '>' and D.starttime=P.timestamp)T1 ---ER0325 as on 21/feb/12 Added 
	inner join #DNC_log D on D.machineid = T1.Machineid and D.programid=T1.Programid and
	D.timestamp=T1.starttime
	*********************** ER0327 Commented From Here **************/


	/******************** ER0327 Added From Here *****************/
	insert into #DNC_log(Idd,Machineid,ClientName,UserName,Logmessage,ProgramID,TimeStamp,QTY) 
	select Idd,D1.machineid,ClientName,UserName,D1.Logmessage,D1.ProgramID,
	D1.minstarttime,0 from DNC_log inner join #DNC_logwithtimestamp D1 on 
	D1.Machineid =DNC_log.Machineid and D1.compareminstarttime = DNC_log.timestamp



	update #dnc_log set QTY = T1.qty from
	(select D.machineid,programid,starttime,Qty from #DNC_logWithQty D
	inner join Programuploadtomachine P on D.Machineid=P.Machineid  ----ER0325 as on 21/feb/12 Added 
	and D.Programid='<' + P.Programname + '>' and D.comparestarttime=P.timestamp)T1 ---ER0325 as on 21/feb/12 Added 
	inner join #DNC_log D on D.machineid = T1.Machineid and D.programid=T1.Programid and
	D.timestamp=T1.starttime
	/******************** ER0327 Added Till Here *****************/

	---------------------------------ER0430 From Here-------------------------------------------
	select @strsql = ''
	select @strsql = @strsql + 'Insert into #TempDNC_log1(Idd,Machineid,ProgramID,TransferStart) '
	select @strsql = @strsql + 'select Idd,case when MachineID='''' then ''NA'' When MachineID<>'''' then MachineID end as MachineID,case when  charindex(''<'',logmessage)<=0 then ''Unknown'' when  charindex(''<'',logmessage)>-1 then substring(logmessage,charindex(''<'',logmessage),charindex(''>'',logmessage)-charindex(''<'',logmessage)+1) END as ProgramID,
								TimeStamp from dnc_log '
	select @strsql = @strsql + 'where [TimeStamp] >=  ''' + convert(nvarchar(20),@StartTime) +'''  and [TimeStamp] <= ''' + convert(nvarchar(20),@EndTime)+''' '
	select @strsql = @strsql + 'and (logmessage like ''%Transfer in Progress To The Asset%'') 
	and ErrorNumber=0 and MessageType=''Action'''
	select @strsql = @strsql + @strMachine
	select @strsql = @strsql + 'order by idd'
	print @strsql
	exec(@strsql)


	insert into #TempDNC_log(Idd,MachineID,ProgramID,Comparestarttime,TransferStart,Endtime)
	Select v.idd,v.Machineid,V.programid,v.TransferStart,v.TransferStart as time1,min(v1.TransferStart) as time2
	from (Select * from #TempDNC_log1) V inner join #TempDNC_log1 V1 on v.machineid=v1.machineid
	where  v1.idd>v.idd
	group by v.idd,v.Machineid,v.TransferStart,V.programid
	order by v.TransferStart



	Insert into #TempDNC_log(MachineID,Comparestarttime,TransferStart,Endtime)
	select DNC_log.Machineid,max(DNC_log.timestamp),case when max(DNC_log.timestamp)<@starttime then @starttime else max(DNC_log.timestamp)end,T1.Comparetime from DNC_log
	inner join (select Machineid, min(TransferStart) as  Comparetime from #TempDNC_log group by machineid)T1 on T1.Machineid = DNC_log.Machineid
    where logmessage like '%Transfer in Progress To The Asset%' 
	and ErrorNumber=0 and MessageType='Action' and DNC_log.timestamp<@starttime
	group by DNC_log.machineid,T1.Comparetime

	update #TempDNC_log set Programid = T1.Programid
	from
	(
		select Machineid,Timestamp,substring(logmessage,charindex('<',logmessage),charindex('>',logmessage)-charindex('<',logmessage)+1) as ProgramID
		from dnc_log where timestamp <@starttime
	)T1 inner join #TempDNC_log on T1.Machineid = #TempDNC_log.Machineid and T1.timestamp= #TempDNC_log.Comparestarttime



	Insert into #TempDNC_log(MachineID,Comparestarttime,TransferStart,Endtime)
	select DNC_log.Machineid,max(DNC_log.timestamp),max(DNC_log.timestamp),case when max(DNC_log.timestamp)<@endtime then @endtime else max(DNC_log.timestamp) end from DNC_log
	inner join (select Machineid, max(TransferStart) as  Comparetime from #TempDNC_log group by machineid)T1 on T1.Machineid = DNC_log.Machineid
    where logmessage like '%Transfer in Progress To The Asset%' 
	and ErrorNumber=0 and MessageType='Action' and DNC_log.timestamp<@endtime
	group by DNC_log.machineid,T1.Comparetime

	update #TempDNC_log set Programid = T1.Programid
	from
	(
		select Machineid,Logmessage,Timestamp,substring(logmessage,charindex('<',logmessage),charindex('>',logmessage)-charindex('<',logmessage)+1) as ProgramID
		from dnc_log where timestamp <@endtime
	)T1 inner join #TempDNC_log on T1.Machineid = #TempDNC_log.Machineid and T1.timestamp= #TempDNC_log.Comparestarttime


	update #TempDNC_log set TransferEnd = T1.TransferEnd from
	(select T.Machineid,T.Comparestarttime,Max(D.Timestamp) as TransferEnd from DNC_log D
	inner join #TempDNC_log T on T.Machineid = D.Machineid 
    where D.logmessage like '%Transferred Successfully To the Asset%' and D.ErrorNumber=0 and D.MessageType='Action' and D.timestamp>T.TransferStart and D.Timestamp<=T.Endtime
	group by T.Machineid,T.Comparestarttime)T1 inner join #TempDNC_log on T1.Machineid=#TempDNC_log.Machineid and T1.Comparestarttime=#TempDNC_log.TransferStart

	update #dnc_log set TransferEnd = T1.TransferEnd from
	(select D.machineid,programid,TransferEnd,Comparestarttime from #TempDNC_log D)T1 
	inner join #DNC_log D on D.machineid = T1.Machineid and D.programid=T1.Programid and
	D.timestamp=T1.Comparestarttime
	-------------------- ER0430 Till Here ----------------------------------------


--	select D.Machineid,D.ClientName,D.UserName,D.Logmessage,D.ProgramID,D.TimeStamp,D.QTY from #DNC_log D
--	order by D.idd --ER0372 
--
--	select D.Machineid,D.ClientName,D.UserName,D.Logmessage,D.ProgramID,D.TimeStamp,D.QTY,[dbo].[f_GetLogicalDayStart](D.TimeStamp) as StartDate from #DNC_log D
--	order by D.idd --ER0372

--	select D.Machineid,D.ClientName,D.UserName,D.Logmessage,D.ProgramID,D.TimeStamp as TransferStart,D.TransferEnd as TransferEnd,D.QTY,[dbo].[f_GetLogicalDayStart](D.TimeStamp) as StartDate from #DNC_log D
--	order by D.idd --ER0372

	select D.Machineid,D.ClientName,D.UserName,D.Logmessage,D.ProgramID,D.TimeStamp as TransferStart,D.TransferEnd as TransferEnd,D.QTY,[dbo].[f_GetLogicalDayStart](D.TimeStamp) as StartDate from #DNC_log D
	order by D.idd --ER0430

End
--ER0298 Till Here.
end
