/****** Object:  Procedure [dbo].[S_TTL_HelpRequestDetails]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[S_TTL_HelpRequestDetails] '2016-10-04','','''B''','','''ACE VTL-02''','',''
CREATE  proc [dbo].[S_TTL_HelpRequestDetails]
@starttime datetime,
@endtime datetime='',
@Shift nvarchar(250)='',
@PlantID nvarchar(500)='',
@Machineid nvarchar(4000)='',
@calltype nvarchar(500)='',
@param nvarchar(50) =''
As 
Begin

Declare @strsql as nvarchar(4000)
Declare @strplant as nvarchar(4000)
Declare @strmachine as nvarchar(2000)
Declare @Strcalltype as nvarchar(2000)

select @strplant=''
select @strmachine=''
select @Strcalltype=''

create table #ACK_request
(
[PSerial Number] bigint identity(1,1) NOT NULL,
Pinterface nvarchar(50),
Minterface nvarchar(50),
Eventinterface nvarchar(50),
PlantID nvarchar(50),
Machineid nvarchar(50),
[ShiftDate] datetime,
[ShiftName] nvarchar(50),
[From time] datetime,
[To Time] datetime,
[Request Desc] nvarchar(50),
[Raised TS] datetime,
[SMS Sent TS] datetime,
[SMS Sent To] nvarchar(4000),
[Ack TS] datetime,
[Close TS] datetime,
[Close SMS Sent TS] datetime,
[Close SMS Sent To] nvarchar(4000),
ACKTime float,
FIXTime float 
)

create table #ACK_requestMaster
(
Pinterface nvarchar(50),
Minterface nvarchar(50),
Eventinterface nvarchar(50),
PlantID nvarchar(50),
Machineid nvarchar(50),
[ShiftDate] datetime,
[ShiftName] nvarchar(50),
[From time] datetime,
[To Time] datetime,
[Request Desc] nvarchar(50)
)


CREATE TABLE #ShiftDetails 
(
	PDate datetime,
	Shiftid nvarchar(20),
	ShiftStart datetime,
	ShiftEnd datetime
)


if isnull(@PlantID,'')<>''
begin
set @strplant=' AND Plantinformation.Plantid=N'''+@PlantID+''''	
end

If isnull(@Machineid,'')<>''
begin
set @strmachine=' AND Machineinformation.MachineID  in ( ' +  @machineid + ') '
end

If isnull(@calltype,'')<>''
begin
set @strcalltype=' And Helpcodemaster.[help_description] in (' + @Calltype + ')'
end

Declare @CurStrtTime as datetime,@CurEndTime as datetime
Declare @shiftstart as datetime,@shiftend as datetime
declare @ShiftID as int
select @CurStrtTime = @starttime
Select @CurEndTime =@starttime


while @CurStrtTime<=@CurEndTime
BEGIN
	INSERT #ShiftDetails(Pdate, Shiftid, ShiftStart, ShiftEnd)
	EXEC s_GetShiftTime @CurStrtTime,''
	SELECT @CurStrtTime=DATEADD(DAY,1,@CurStrtTime)
END

if isnull(@Shift,'') <> ''
Begin
	select @strsql =''
	Select @strsql = @strsql +  'Delete from #ShiftDetails where shiftid not in ( ' +  @Shift + ') '
	exec(@strsql)
End

Select @ShiftID = Shiftid from Shiftdetails where running=1 and Shiftname=@Shift
select @shiftstart = Min(ShiftStart) from #ShiftDetails 
Select @shiftend = Max(Shiftend) from #ShiftDetails 

select @strsql =''
select @strsql = @strsql + 'Insert into #ACK_requestMaster (PInterface,Plantid,MInterface,Machineid,EventInterface,[Request Desc],ShiftDate,[From time],[To Time],ShiftName)
SELECT distinct plantinformation.Plantcode,plantinformation.Plantid,Machineinformation.interfaceid,Machineinformation.machineid,Helpcodemaster.[Help_code], Helpcodemaster.[help_description],S.PDate,S.shiftstart,S.shiftend,S.Shiftid FROM Machineinformation
inner join Plantmachine on Machineinformation.machineid=Plantmachine.machineid
inner join plantinformation on plantinformation.plantid=Plantmachine.plantid
Cross join #ShiftDetails S,helpcodemaster where 1=1'
Select @strsql = @strsql + @strmachine + @StrPlant  + @strcalltype
print @strsql
Exec (@strsql) 

Insert into #ACK_request (PInterface,Plantid,MInterface,Machineid,EventInterface,[Request Desc],ShiftDate,[From time],[To Time],ShiftName,[Raised TS],ACKTime,FIXTime)
select H.plantid,AK.Plantid,H.machineid,AK.machineid,H.helpcode,AK.[Request Desc],AK.Shiftdate,AK.[From time],AK.[To Time],AK.Shiftname,min(H.Starttime) as [Raised TS],0,0 from helpcodedetails H
 inner join #ACK_requestMaster AK on H.plantid=AK.PInterface and H.machineid=AK.MInterface and H.helpcode=AK.EventInterface
 where (H.action1='01') and H.Starttime>=AK.[From time] and H.starttime<=AK.[To Time]
group by H.plantid,AK.Plantid,H.machineid,AK.machineid,H.helpcode,AK.[Request Desc],AK.Shiftdate,AK.[From time],AK.[To Time],AK.Shiftname,H.Starttime

Update #ACK_request set [SMS Sent TS]=T2.[SMS Sent TS], [SMS Sent To]=T2.[SMS Sent To] From (
Select M.Machineid,M.Sendtime as [SMS Sent TS],M.MobileNo as [SMS Sent To],M.RequestedTime as [Raised TS],M.HelpCode from MessageHistory M
inner join #ACK_request AK on M.machineid=AK.Machineid and M.helpcode=AK.EventInterface and M.RequestedTime=AK.[Raised TS]
where (M.actionNo='01')
)as T2 inner join #ACK_request r on T2.Machineid=r.Machineid and T2.HelpCode=r.Eventinterface
and r.[Raised TS] = t2.[Raised TS]



Update #ACK_request set [Ack TS] = T2.[Ack TS], ACKTime = T2.ACKTime from
(select T1.plantid,T1.machineid,T1.helpcode,T1.[Raised TS],T1.[Ack TS] as [Ack TS],Datediff(s,T1.[Raised TS],T1.[Ack TS]) as ACKTime  from
(select V.plantid,V.machineid,V.helpcode,V.Starttime as [Raised TS],Max(V.Endtime) as [Ack TS] from helpcodedetails v
inner join #ACK_request AK on v.plantid=AK.Pinterface and v.Machineid=AK.Minterface and v.HelpCode=AK.Eventinterface and V.StartTime=AK.[Raised TS]
where isnull(V.Endtime,'1900-01-01')<>'1900-01-01' and (V.action1='01' and v.action2='02') and v.Starttime>=@shiftstart and v.Endtime<=@shiftend
group by V.plantid,V.machineid,V.helpcode,V.Starttime)T1) as T2 inner join #ACK_request r on T2.plantid=r.Pinterface and T2.Machineid=r.Minterface and T2.HelpCode=r.Eventinterface
and r.[Raised TS] = t2.[Raised TS]


Update #ACK_request set [Close TS] = T2.[Close TS], FIXTime = T2.FIXTime from
(select T1.plantid,T1.machineid,T1.helpcode,T1.[Raised TS],T1.[Close TS] as [Close TS],Datediff(s,T1.[Raised TS],T1.[Close TS]) as FIXTime  from
(select V.plantid,V.machineid,V.helpcode,V.Starttime as [Raised TS],Max(V.Endtime) as [Close TS] from helpcodedetails v
inner join #ACK_request AK on v.plantid=AK.Pinterface and v.Machineid=AK.Minterface and v.HelpCode=AK.Eventinterface and V.StartTime=AK.[Raised TS]
where isnull(V.Endtime,'1900-01-01')<>'1900-01-01' and (V.action1='01' and v.action2='03') and v.Starttime>=@shiftstart and v.Endtime<=@shiftend
group by V.plantid,V.machineid,V.helpcode,V.Starttime)T1) as T2 inner join #ACK_request r on T2.plantid=r.Pinterface and T2.Machineid=r.Minterface and T2.HelpCode=r.Eventinterface
and r.[Raised TS] = t2.[Raised TS]

Update #ACK_request set [SMS Sent TS]=T2.[SMS Sent TS], [SMS Sent To]=T2.[SMS Sent To] From (
Select M.Machineid,M.Sendtime as [SMS Sent TS],M.MobileNo as [SMS Sent To],M.RequestedTime as [Close TS],M.HelpCode from MessageHistory M
inner join #ACK_request AK on M.machineid=AK.Machineid and M.helpcode=AK.EventInterface and M.RequestedTime=AK.[Close TS]
where (M.actionNo='03')
)as T2 inner join #ACK_request r on T2.Machineid=r.Machineid and T2.HelpCode=r.Eventinterface
and r.[Close TS] = t2.[Close TS]

	
If @param = ''
BEGIN
  Select [PSerial Number], [Request Desc], [Raised TS], [SMS Sent TS], [SMS Sent To], [Ack TS], [Close TS], [Close SMS Sent TS], [Close SMS Sent To]
  from #ACK_request Order by ShiftDate,ShiftName,Plantid,Machineid,Eventinterface,[Raised TS]
END


end
