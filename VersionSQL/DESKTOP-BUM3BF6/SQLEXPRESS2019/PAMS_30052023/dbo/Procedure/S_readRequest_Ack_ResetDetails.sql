/****** Object:  Procedure [dbo].[S_readRequest_Ack_ResetDetails]    Committed by VersionSQL https://www.versionsql.com ******/

--ER0502 - Swathi - 16/03/2021 :: AAAPL : Altered Proc to include Remarks for each Action
--[dbo].[S_readRequest_Ack_ResetDetails] '2020-09-10','2020-09-30','','Win Chennai - SCP','','','AvgCalltype'

CREATE  proc [dbo].[S_readRequest_Ack_ResetDetails]
@starttime datetime,
@endtime datetime,
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
declare @timeformat as nvarchar(2000)


select @strplant=''
select @strmachine=''
select @Strcalltype=''
SELECT @timeformat ='ss'

Select @timeformat = isnull((select valueintext from cockpitdefaults where parameter='timeformat'),'ss')
if (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')
begin
	select @timeformat = 'ss'
end


CREATE TABLE #T_autodata(
	[mc] [nvarchar](50)not NULL,
	[comp] [nvarchar](50) NULL,
	[opn] [nvarchar](50) NULL,
	[opr] [nvarchar](50) NULL,
	[dcode] [nvarchar](50) NULL,
	[sttime] [datetime] not NULL,
	[ndtime] [datetime] not NULL,
	[datatype] [tinyint] NULL ,
	[cycletime] [int] NULL,
	[loadunload] [int] NULL ,
	[msttime] [datetime] not NULL,
	[PartsCount] decimal(18,5) NULL ,
	id  bigint not null
)

Create table #PlannedDownTimes
(
	MachineID nvarchar(50) NOT NULL, --ER0374
	MachineInterface nvarchar(50) NOT NULL, --ER0374
	StartTime DateTime NOT NULL, --ER0374
	EndTime DateTime NOT NULL --ER0374
)

ALTER TABLE #PlannedDownTimes
	ADD PRIMARY KEY CLUSTERED
		(   [MachineInterface],
			[StartTime],
			[EndTime]
						
		) ON [PRIMARY]


create table #ACK_request
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
Eventid nvarchar(50),
RequestedTime datetime,
AcknowledgeTime datetime,
ResetTime datetime,
Completedtime datetime,
ACKTime float,
FIXTime float ,
CMPTime float,
DownT float,
AvgAcktime float,
AvgFixTime float,
AvgCMPTime float,
MTBF FLOAT,
RaisedRemarks nvarchar(500),
AckRemarks nvarchar(500),
ResetRemarks nvarchar(500),
CloseRemarks nvarchar(500)
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
Eventid nvarchar(50)
)


CREATE TABLE #ShiftDetails 
(
	PDate datetime,
	Shiftid nvarchar(20),
	ShiftStart datetime,
	ShiftEnd datetime
)

create table #MTBF
(
MachineID NVARCHAR(50),
MachineInterface nvarchar(50),
EventInterface nvarchar(50),
EventID NVARCHAR(50),
TotalTime float,
DownTime float,
Difference_Time float,
RiseCount  int,
MainTime_MTBF FLOAT
)

ALTER TABLE #T_autodata

ADD PRIMARY KEY CLUSTERED
(
	mc,sttime,ndtime,msttime ASC
)ON [PRIMARY]

Declare @T_ST AS Datetime 
Declare @T_ED AS Datetime 

---ER0374 from here
--Select @T_ST=dbo.f_GetLogicalDay(@StartTime,'start')
--Select @T_ED=dbo.f_GetLogicalDay(@EndTime,'End')
Select @T_ST=dbo.f_GetLogicalDaystart(@StartTime)
Select @T_ED=dbo.f_GetLogicalDayend(@EndTime)
---ER0374 Till here

Select @strsql=''
select @strsql ='insert into #T_autodata '
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'
	select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'
select @strsql = @strsql + ' from autodata where (( sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_ED,120)+''' ) OR '
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' )OR '
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ST,120)+'''
					and ndtime<='''+convert(nvarchar(25),@T_ED,120)+''' )'
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' and sttime<'''+convert(nvarchar(25),@T_ED,120)+''' ) )'
print @strsql
exec (@strsql)


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
select @CurStrtTime = @starttime
Select @CurEndTime =@endtime


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

select @shiftstart = Min(ShiftStart) from #ShiftDetails 
Select @shiftend = Max(Shiftend) from #ShiftDetails 

SET @strSql = ''
SET @strSql = 'Insert into #PlannedDownTimes
SELECT Machine,InterfaceID,
CASE When StartTime<''' + convert(nvarchar(20),@StartTime,120)+''' Then ''' + convert(nvarchar(20),@StartTime,120)+''' Else StartTime End As StartTime,
CASE When EndTime>''' + convert(nvarchar(20),@EndTime,120)+''' Then ''' + convert(nvarchar(20),@EndTime,120)+''' Else EndTime End As EndTime
FROM PlannedDownTimes inner join MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID
LEFT OUTER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID 
LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID 
and PlantMachineGroups.machineid = PlantMachine.MachineID
WHERE PDTstatus =1 and(
(StartTime >= ''' + convert(nvarchar(20),@StartTime,120)+''' AND EndTime <=''' + convert(nvarchar(20),@EndTime,120)+''')
OR ( StartTime < ''' + convert(nvarchar(20),@StartTime,120)+'''  AND EndTime <= ''' + convert(nvarchar(20),@EndTime,120)+''' AND EndTime > ''' + convert(nvarchar(20),@StartTime,120)+''' )
OR ( StartTime >= ''' + convert(nvarchar(20),@StartTime,120)+'''   AND StartTime <''' + convert(nvarchar(20),@EndTime,120)+''' AND EndTime > ''' + convert(nvarchar(20),@EndTime,120)+''' )
OR ( StartTime < ''' + convert(nvarchar(20),@StartTime,120)+'''  AND EndTime > ''' + convert(nvarchar(20),@EndTime,120)+''')) '
SET @strSql =  @strSql + @strMachine + ' ORDER BY Machine,StartTime'
EXEC(@strSql)



select @strsql =''
select @strsql = @strsql + 'Insert into #ACK_requestMaster (PInterface,Plantid,MInterface,Machineid,EventInterface,Eventid,ShiftDate,[From time],[To Time],ShiftName)
SELECT distinct plantinformation.Plantcode,plantinformation.Plantid,Machineinformation.interfaceid,Machineinformation.machineid,Helpcodemaster.[Help_code], Helpcodemaster.[help_description],S.PDate,S.shiftstart,S.shiftend,S.Shiftid FROM Machineinformation
inner join Plantmachine on Machineinformation.machineid=Plantmachine.machineid
inner join plantinformation on plantinformation.plantid=Plantmachine.plantid
Cross join #ShiftDetails S,helpcodemaster where 1=1'
Select @strsql = @strsql + @strmachine + @StrPlant  + @strcalltype
print @strsql
Exec (@strsql) 

Insert into #ACK_request (PInterface,Plantid,MInterface,Machineid,EventInterface,Eventid,ShiftDate,[From time],[To Time],ShiftName,RequestedTime,ACKTime,FIXTime,CMPTime,
AvgAcktime,AvgFixTime,AvgCMPTime)
select H.plantid,AK.Plantid,H.machineid,AK.machineid,H.helpcode,AK.eventid,AK.Shiftdate,AK.[From time],AK.[To Time],AK.Shiftname,min(H.Starttime) as RequestedTime,0,0,0,0,0,0 from helpcodedetails H
 inner join #ACK_requestMaster AK on H.plantid=AK.PInterface and H.machineid=AK.MInterface and H.helpcode=AK.EventInterface
 where (H.action1='01') and H.Starttime>=AK.[From time] and H.starttime<=AK.[To Time]
group by H.plantid,AK.Plantid,H.machineid,AK.machineid,H.helpcode,AK.eventid,AK.Shiftdate,AK.[From time],AK.[To Time],AK.Shiftname,H.Starttime

----------------------------------------------------------------------Cal of MTBF STARTS-------------------------------------------------------------------------------------------------------------

insert into #MTBF(MachineInterface,MachineID,EventInterface,EventID)
select DISTINCT H.machineid,AK.machineid,H.helpcode,AK.eventid from helpcodedetails H
 inner join #ACK_requestMaster AK on  H.machineid=AK.MInterface and H.helpcode=AK.EventInterface
 where (H.action1='01') and H.Starttime>=AK.[From time] and H.starttime<=AK.[To Time]

 update #MTBF set TotalTime=Datediff(s,@starttime,@endtime)

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN
	---step 1
	
	UPDATE #MTBF SET downtime = isnull(downtime,0) + isNull(t2.down,0)
	from
	(select mc,sum(
			CASE
	        WHEN  autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime  THEN  loadunload
			WHEN (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  THEN DateDiff(second, @StartTime, ndtime)
			WHEN (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)  THEN DateDiff(second, stTime, @Endtime)
			WHEN autodata.msttime<@StartTime and autodata.ndtime>@EndTime   THEN DateDiff(second, @StartTime, @EndTime)
			END
		)AS down
	from #T_autodata autodata --ER0374
	inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
	where autodata.datatype=2 AND
	(
	(autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)
	OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
	OR (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
	OR (autodata.msttime<@StartTime and autodata.ndtime>@EndTime )
	) 
	group by autodata.mc
	) as t2 inner join #MTBF on t2.mc = #MTBF.machineinterface
	--select * from #CockpitData

	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
	begin
	UPDATE #MTBF set DownTime =isnull(DownTime,0) - isNull(TT.PPDT ,0)
	FROM(
		--Production PDT
		SELECT autodata.MC, SUM
		   (CASE
			WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PPDT
		FROM #T_autodata AutoData --ER0374
		CROSS jOIN #PlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)
			
		group by autodata.mc
	) as TT INNER JOIN #MTBF ON TT.mc = #MTBF.MachineInterface
	end
 END

 UPDATE #MTBF SET Difference_Time=(TotalTime-DownTime)

---------------------------------------------------------------------------------MTBF DOWN CAL ENDS----------------------------------------------------------------------------------------------------------
Update #ACK_request set AcknowledgeTime = T2.AcknowledgeTime, ACKTime = T2.ACKTime from
(select T1.plantid,T1.machineid,T1.helpcode,T1.RequestedTime,T1.AcknowledgeTime as AcknowledgeTime,Datediff(s,T1.RequestedTime,T1.AcknowledgeTime) as ACKTime  from
(select V.plantid,V.machineid,V.helpcode,V.Starttime as RequestedTime,Max(V.Endtime) as AcknowledgeTime from helpcodedetails v
inner join #ACK_request AK on v.plantid=AK.Pinterface and v.Machineid=AK.Minterface and v.HelpCode=AK.Eventinterface and V.StartTime=AK.RequestedTime
where isnull(V.Endtime,'1900-01-01')<>'1900-01-01' and (V.action1='01' and v.action2='02') and v.Starttime>=@shiftstart and v.Endtime<=@shiftend
group by V.plantid,V.machineid,V.helpcode,V.Starttime)T1) as T2 inner join #ACK_request r on T2.plantid=r.Pinterface and T2.Machineid=r.Minterface and T2.HelpCode=r.Eventinterface
and r.RequestedTime = t2.RequestedTime

Update #ACK_request set ResetTime = T2.Resettime, FIXTime = T2.FIXTime from
(select T1.plantid,T1.machineid,T1.helpcode,T1.RequestedTime,T1.Resettime as Resettime,Datediff(s,T1.RequestedTime,T1.ResetTime) as FIXTime  from
(select V.plantid,V.machineid,V.helpcode,V.Starttime as RequestedTime,Max(V.Endtime) as ResetTime from helpcodedetails v
inner join #ACK_request AK on v.plantid=AK.Pinterface and v.Machineid=AK.Minterface and v.HelpCode=AK.Eventinterface and V.StartTime=AK.RequestedTime
where isnull(V.Endtime,'1900-01-01')<>'1900-01-01' and (V.action1='01' and v.action2='03') and v.Starttime>=@shiftstart and v.Endtime<=@shiftend
group by V.plantid,V.machineid,V.helpcode,V.Starttime)T1) as T2 inner join #ACK_request r on T2.plantid=r.Pinterface and T2.Machineid=r.Minterface and T2.HelpCode=r.Eventinterface
and r.RequestedTime = t2.RequestedTime

Update #ACK_request set Completedtime = T2.Completedtime, CMPTime = T2.CMPTime from
(select T1.plantid,T1.machineid,T1.helpcode,T1.RequestedTime,T1.Completedtime as Completedtime,Datediff(s,T1.RequestedTime,T1.Completedtime) as CMPTime  from
(select V.plantid,V.machineid,V.helpcode,V.Starttime as RequestedTime,Max(V.Endtime) as Completedtime from helpcodedetails v
inner join #ACK_request AK on v.plantid=AK.Pinterface and v.Machineid=AK.Minterface and v.HelpCode=AK.Eventinterface and V.StartTime=AK.RequestedTime
where isnull(V.Endtime,'1900-01-01')<>'1900-01-01' and (V.action1='01' and v.action2='04') and v.Starttime>=@shiftstart and v.Endtime<=@shiftend
group by V.plantid,V.machineid,V.helpcode,V.Starttime)T1) as T2 inner join #ACK_request r on T2.plantid=r.Pinterface and T2.Machineid=r.Minterface and T2.HelpCode=r.Eventinterface
and r.RequestedTime = t2.RequestedTime



Update #ACK_request set RaisedRemarks = T2.Remarks from
(select V.plantid,V.machineid,V.helpcode,V.Starttime as RequestedTime,v.Remarks from helpcodedetails v
inner join #ACK_request AK on v.plantid=AK.Pinterface and v.Machineid=AK.Minterface and v.HelpCode=AK.Eventinterface and V.StartTime=AK.RequestedTime
where V.action1='01' and isnull(V.Endtime,'1900-01-01')='1900-01-01' and v.Starttime>=@shiftstart and v.StartTime<=@shiftend
)as T2 inner join #ACK_request r on T2.plantid=r.Pinterface and T2.Machineid=r.Minterface and T2.HelpCode=r.Eventinterface
and r.RequestedTime = t2.RequestedTime

Update #ACK_request set AckRemarks = T2.Remarks from
(select V.plantid,V.machineid,V.helpcode,V.Starttime as RequestedTime,v.Remarks from helpcodedetails v
inner join #ACK_request AK on v.plantid=AK.Pinterface and v.Machineid=AK.Minterface and v.HelpCode=AK.Eventinterface and V.StartTime=AK.RequestedTime
where isnull(V.Endtime,'1900-01-01')<>'1900-01-01' and (V.action1='01' and v.action2='02') and v.Starttime>=@shiftstart and v.Endtime<=@shiftend
)as T2 inner join #ACK_request r on T2.plantid=r.Pinterface and T2.Machineid=r.Minterface and T2.HelpCode=r.Eventinterface
and r.RequestedTime = t2.RequestedTime

Update #ACK_request set ResetRemarks = T2.Remarks from
(select V.plantid,V.machineid,V.helpcode,V.Starttime as RequestedTime,v.Remarks from helpcodedetails v
inner join #ACK_request AK on v.plantid=AK.Pinterface and v.Machineid=AK.Minterface and v.HelpCode=AK.Eventinterface and V.StartTime=AK.RequestedTime
where isnull(V.Endtime,'1900-01-01')<>'1900-01-01' and (V.action1='01' and v.action2='03') and v.Starttime>=@shiftstart and v.Endtime<=@shiftend
)as T2 inner join #ACK_request r on T2.plantid=r.Pinterface and T2.Machineid=r.Minterface and T2.HelpCode=r.Eventinterface
and r.RequestedTime = t2.RequestedTime

Update #ACK_request set CloseRemarks = T2.Remarks from
(select V.plantid,V.machineid,V.helpcode,V.Starttime as RequestedTime,v.Remarks from helpcodedetails v
inner join #ACK_request AK on v.plantid=AK.Pinterface and v.Machineid=AK.Minterface and v.HelpCode=AK.Eventinterface and V.StartTime=AK.RequestedTime
where isnull(V.Endtime,'1900-01-01')<>'1900-01-01' and (V.action1='01' and v.action2='04') and v.Starttime>=@shiftstart and v.Endtime<=@shiftend
)as T2 inner join #ACK_request r on T2.plantid=r.Pinterface and T2.Machineid=r.Minterface and T2.HelpCode=r.Eventinterface
and r.RequestedTime = t2.RequestedTime	



---------------------------------------------------------------------dOWN CAL-----------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------Cal MTBF STARTS ------------------------------------------------------------------------------------------------------------

UPDATE #MTBF SET RiseCount=(T1.CNT)
FROM
(SELECT DISTINCT Machineid,Eventid,COUNT(RequestedTime) AS CNT FROM #ACK_request
GROUP BY Machineid,Eventid
) T1 INNER JOIN #MTBF ON #MTBF.MachineID=T1.Machineid AND #MTBF.EventID=T1.Eventid

UPDATE #MTBF SET MainTime_MTBF=(Difference_Time/RiseCount)



If @param = ''
BEGIN
  Select Plantid,Machineid,Eventid,ShiftDate,ShiftName,RequestedTime,AcknowledgeTime,ResetTime,Completedtime,round((ACKTime/60),2) as ACKTime,Round((FIXTime/60),2) as FIXTime,Round((CMPTime/60),2) as CMPTime,Round((DownT/60),2) as DownT
  ,RaisedRemarks,AckRemarks,ResetRemarks,CloseRemarks from #ACK_request Order by ShiftDate,ShiftName,Plantid,Machineid,Eventinterface,RequestedTime
END

If @Param = 'AvgCalltype'
Begin
	set @strsql=''
	set @strsql='update #ACK_request set AvgAcktime=k.AvgAcktime,AvgFixTime=k.AvgFixTime,AvgCMPTime=k.AvgCMPTime from
    (select eventid, avg(acktime) as AvgAcktime,avg(fixtime) as AvgFixTime,avg(CMPTime) as AvgCMPTime from #ACK_request
	where (acktime>0 or fixtime>0 or cmptime>0) group by eventid)k inner join #ACK_request r on r.eventid=k.eventid '
	exec(@strsql)

	UPDATE #ACK_request SET MTBF=(T1.MTBF_Time)
	from
	(select  eventid,avg(MainTime_MTBF) as MTBF_Time from #MTBF
	group by eventid
	) t1 inner join #ACK_request on #ACK_request.Eventid=t1.EventID


    select  H.Help_Description,dbo.f_FormatTime(isnull(T1.AvgAcktime,0),@timeformat) as AvgAcktime,
	dbo.f_FormatTime(isnull(T1.AvgFixTime,0),@timeformat) as AvgFixTime,
	dbo.f_FormatTime(Isnull(T1.AvgCMPTime,0),@timeformat) as AvgCMPTime,
	dbo.f_FormatTime(isnull(t1.mtbf,0),@timeformat) as MTBF from
	(select distinct A.eventid,A.AvgAcktime,A.AvgFixTime,A.AvgCMPTime,a.MTBF from #ACK_request A )T1 
	 right outer join helpcodemaster H on H.Help_Description=T1.Eventid
	 order by H.Help_Code

	--     select  H.Help_Description,Isnull(round((T1.AvgAcktime/60),1),0) as AvgAcktime,
	--Isnull(round((T1.AvgFixTime/60),1),0) as AvgFixTime,
	--Isnull(round((T1.AvgCMPTime/60),1),0) as AvgCMPTime,
	--isnull(round((t1.mtbf/60),1),0) as MTBF from
	--(select distinct A.eventid,A.AvgAcktime,A.AvgFixTime,A.AvgCMPTime,a.MTBF from #ACK_request A )T1 
	-- right outer join helpcodemaster H on H.Help_Description=T1.Eventid
	-- order by H.Help_Code


END


end
