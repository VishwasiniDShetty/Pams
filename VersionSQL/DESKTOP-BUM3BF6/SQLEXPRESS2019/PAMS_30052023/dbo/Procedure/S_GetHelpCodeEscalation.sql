/****** Object:  Procedure [dbo].[S_GetHelpCodeEscalation]    Committed by VersionSQL https://www.versionsql.com ******/

/*
exec [dbo].[S_GetHelpCodeEscalation]
*/
CREATE  Procedure [dbo].[S_GetHelpCodeEscalation]
AS
BEGIN

Create table #HelpCode
(
	Plantid nvarchar(50),
	Machineid nvarchar(50),
	HelpDescription nvarchar(50),
	ActionInfo nvarchar(50),
	LastCallTime Datetime,
	MobileNo nvarchar(500),
	Level2MobNo nvarchar(500),
	MessageInfo nvarchar(500),
	Level2Threshold int,
	CountofRows int,
	Helpcode nvarchar(50),
	ActionNo nvarchar(10),
	Level3MobNo nvarchar(500), ----ER0458
	Level3Threshold int, ----ER0458
	Raisedtime datetime, ----ER0458
	Remarks nvarchar(500) --ER0502
)

Create table #FinalHelpCode
(
	slno bigint identity(1,1),
	Plantid nvarchar(50),
	Machineid nvarchar(50),
	HelpDescription nvarchar(50),
	ActionInfo nvarchar(50),
	LastCallTime Datetime,
	MobileNo nvarchar(500),
	Level2MobNo nvarchar(500),
	MessageInfo nvarchar(500),
	ActionNo nvarchar(10),
	HelpCode nvarchar(10),
	ShiftID int,
	Raisedtime datetime, ----ER0458
	Remarks nvarchar(500) --ER0502
)

create table #CurrentShift
(
	Startdate datetime,
	shiftname nvarchar(50),
	Starttime datetime,
	Endtime datetime,
	shiftid int
)


Declare @Reqtime as datetime
Declare @i as integer,@j as integer
Declare @logicalstartdate datetime

Declare @curtime as datetime
Select @curtime = convert(Nvarchar(20),Getdate(),120)


Insert into #HelpCode (Plantid,Machineid,HelpDescription,ActionInfo,LastCallTime,MobileNo,Level2MobNo,MessageInfo,Level2Threshold,Helpcode,ActionNo,Level3MobNo,Level3Threshold,Raisedtime) ----ER0458
select P.Plantid,M.Machineid,HM.Help_Description,HA.Action,
Max(HD.Starttime),HR.MobileNo,HR.Level2MobNo,HR.[Message],HR.Level2Threshold,HM.Help_Code,HA.ActionNo,HR.Level3MobNo,HR.Level3Threshold,Max(HD.Starttime) ----ER0458
from HelpCodeDetails HD with (NOLOCK) --ER0377
inner join HelpRequestRule HR on HD.Plantid=HR.Plantid and HD.Machineid=HR.Machineid and HD.HelpCode=HR.HelpCode and HD.Action1=HR.Action
inner join Machineinformation M on HD.Machineid=M.interfaceid
inner join HelpCodeMaster HM on HM.Help_Code=HD.HelpCode
inner join HelpCodeActionInfo HA on HA.ActionNo=HD.Action1
inner join Plantmachine PM on PM.machineid=M.machineid
inner join Plantinformation P on P.Plantid=PM.Plantid
where HD.Action1='01' 
group by P.Plantid,M.Machineid,HM.Help_Description,HA.Action,
HR.MobileNo,HR.Level2MobNo,HR.[Message],HR.Level2Threshold,HM.Help_Code,HA.ActionNo,HR.Level3MobNo,HR.Level3Threshold ----ER0458

--ER0502 From Here
Update #HelpCode set Remarks = T1.AckRemarks from 
(select H.Plantid,H.Machineid,H.LastCallTime,HD.Remarks as AckRemarks,H.Helpcode
from #HelpCode H with (NOLOCK) 
inner join Machineinformation M on H.Machineid=M.machineid
inner join Plantmachine PM on PM.machineid=M.machineid
inner join Plantinformation P on P.Plantid=PM.Plantid
inner join HelpCodeDetails HD on P.PlantCode=HD.Plantid and HD.Machineid=M.InterfaceID and HD.HelpCode=H.HelpCode and HD.StartTime=H.LastCallTime
where HD.Action1='01') T1 
inner join #HelpCode H on T1.Plantid=H.Plantid and T1.Machineid=H.Machineid
and T1.LastCallTime=H.LastCallTime and T1.Helpcode=H.Helpcode 
--ER0502 From Here

Insert into #HelpCode (Plantid,Machineid,HelpDescription,ActionInfo,LastCallTime,MobileNo,Level2MobNo,MessageInfo,Level2Threshold,Helpcode,ActionNo,Level3MobNo,Level3Threshold,Raisedtime) ----ER0458
select P.Plantid,M.Machineid,HM.Help_Description,HA.Action,
Max(HD.Starttime),HR.MobileNo,HR.Level2MobNo,HR.[Message],HR.Level2Threshold,HM.Help_Code,HA.ActionNo,HR.Level3MobNo,HR.Level3Threshold,Max(HD.Starttime) ----ER0458
from HelpCodeDetails HD with (NOLOCK) --ER0377
inner join HelpRequestRule HR on HD.Plantid=HR.Plantid and HD.Machineid=HR.Machineid and HD.HelpCode=HR.HelpCode and HD.Action2=HR.Action
inner join Machineinformation M on HD.Machineid=M.interfaceid
inner join HelpCodeMaster HM on HM.Help_Code=HD.HelpCode
inner join HelpCodeActionInfo HA on HA.ActionNo=HD.Action2
inner join Plantmachine PM on PM.machineid=M.machineid
inner join Plantinformation P on P.Plantid=PM.Plantid
where HD.Action2='02' 
group by P.Plantid,M.Machineid,HM.Help_Description,
HA.Action,HR.MobileNo,HR.Level2MobNo,HR.[Message],HR.Level2Threshold,HM.Help_Code,HA.ActionNo,HR.Level3MobNo,HR.Level3Threshold

--ER0502 From Here
Update #HelpCode set Remarks = T1.AckRemarks from 
(select H.Plantid,H.Machineid,H.LastCallTime,HD.Remarks as AckRemarks,H.Helpcode
from #HelpCode H with (NOLOCK) 
inner join Machineinformation M on H.Machineid=M.machineid
inner join Plantmachine PM on PM.machineid=M.machineid
inner join Plantinformation P on P.Plantid=PM.Plantid
inner join HelpCodeDetails HD on P.PlantCode=HD.Plantid and HD.Machineid=M.InterfaceID and HD.HelpCode=H.HelpCode and HD.Endtime=H.LastCallTime
where HD.Action2='02') T1 
inner join #HelpCode H on T1.Plantid=H.Plantid and T1.Machineid=H.Machineid
and T1.LastCallTime=H.LastCallTime and T1.Helpcode=H.Helpcode 
--ER0502 From Here

Insert into #HelpCode (Plantid,Machineid,HelpDescription,ActionInfo,LastCallTime,MobileNo,Level2MobNo,MessageInfo,Level2Threshold,Helpcode,ActionNo,Level3MobNo,Level3Threshold,Raisedtime) ----ER0458
select P.Plantid,M.Machineid,HM.Help_Description,HA.Action,
Max(HD.Starttime),HR.MobileNo,HR.Level2MobNo,HR.[Message],HR.Level2Threshold,HM.Help_Code,HA.ActionNo,HR.Level3MobNo,HR.Level3Threshold,Max(HD.Starttime)
from HelpCodeDetails HD with (NOLOCK) --ER0377
inner join HelpRequestRule HR on HD.Plantid=HR.Plantid and HD.Machineid=HR.Machineid and HD.HelpCode=HR.HelpCode and HD.Action2=HR.Action
inner join Machineinformation M on HD.Machineid=M.interfaceid
inner join HelpCodeMaster HM on HM.Help_Code=HD.HelpCode
inner join HelpCodeActionInfo HA on HA.ActionNo=HD.Action2
inner join Plantmachine PM on PM.machineid=M.machineid
inner join Plantinformation P on P.Plantid=PM.Plantid
where HD.Action2='03' 
group by P.Plantid,M.Machineid,HM.Help_Description,
HA.Action,HR.MobileNo,HR.Level2MobNo,HR.[Message],HR.Level2Threshold,HA.ActionNo,HM.Help_Code,HR.Level3MobNo,HR.Level3Threshold


--ER0502 From Here
Update #HelpCode set Remarks = T1.AckRemarks from 
(select H.Plantid,H.Machineid,H.LastCallTime,HD.Remarks as AckRemarks,H.Helpcode
from #HelpCode H with (NOLOCK) 
inner join Machineinformation M on H.Machineid=M.machineid
inner join Plantmachine PM on PM.machineid=M.machineid
inner join Plantinformation P on P.Plantid=PM.Plantid
inner join HelpCodeDetails HD on P.PlantCode=HD.Plantid and HD.Machineid=M.InterfaceID and HD.HelpCode=H.HelpCode and HD.Endtime=H.LastCallTime
where HD.Action2='03') T1 
inner join #HelpCode H on T1.Plantid=H.Plantid and T1.Machineid=H.Machineid
and T1.LastCallTime=H.LastCallTime and T1.Helpcode=H.Helpcode 
--ER0502 From Here

Insert into #HelpCode (Plantid,Machineid,HelpDescription,ActionInfo,LastCallTime,MobileNo,Level2MobNo,MessageInfo,Level2Threshold,Helpcode,ActionNo,Level3MobNo,Level3Threshold,Raisedtime) ----ER0458
select P.Plantid,M.Machineid,HM.Help_Description,HA.Action,
Max(HD.Starttime),HR.MobileNo,HR.Level2MobNo,HR.[Message],HR.Level2Threshold,HM.Help_Code,HA.ActionNo,HR.Level3MobNo,HR.Level3Threshold,Max(HD.Starttime)
from HelpCodeDetails HD with (NOLOCK) --ER0377
inner join HelpRequestRule HR on HD.Plantid=HR.Plantid and HD.Machineid=HR.Machineid and HD.HelpCode=HR.HelpCode and HD.Action2=HR.Action
inner join Machineinformation M on HD.Machineid=M.interfaceid
inner join HelpCodeMaster HM on HM.Help_Code=HD.HelpCode
inner join HelpCodeActionInfo HA on HA.ActionNo=HD.Action2
inner join Plantmachine PM on PM.machineid=M.machineid
inner join Plantinformation P on P.Plantid=PM.Plantid
where HD.Action2='04' 
group by P.Plantid,M.Machineid,HM.Help_Description,
HA.Action,HR.MobileNo,HR.Level2MobNo,HR.[Message],HR.Level2Threshold,HA.ActionNo,HM.Help_Code,HR.Level3MobNo,HR.Level3Threshold


Update #HelpCode set Remarks = T1.AckRemarks from 
(select H.Plantid,H.Machineid,H.LastCallTime,HD.Remarks as AckRemarks,H.Helpcode
from #HelpCode H with (NOLOCK) 
inner join Machineinformation M on H.Machineid=M.machineid
inner join Plantmachine PM on PM.machineid=M.machineid
inner join Plantinformation P on P.Plantid=PM.Plantid
inner join HelpCodeDetails HD on P.PlantCode=HD.Plantid and HD.Machineid=M.InterfaceID and HD.HelpCode=H.HelpCode and HD.Endtime=H.LastCallTime
where HD.Action2='04') T1 
inner join #HelpCode H on T1.Plantid=H.Plantid and T1.Machineid=H.Machineid
and T1.LastCallTime=H.LastCallTime and T1.Helpcode=H.Helpcode 

Update #HelpCode set CountOfRows = isnull(CountOfRows,0) +  isnull(T.CountInit,0) from
(Select Count(*) as CountInit,M.Machineid,M.Requestedtime,H.ActionInfo from MessageHistory M with (NOLOCK) --ER0377
inner join #HelpCode H on M.Machineid=H.Machineid and M.RequestedTime=H.LastCallTime
 Group by M.Machineid,M.Requestedtime,H.ActionInfo)T inner join #HelpCode H on T.Machineid=H.Machineid and T.RequestedTime=H.LastCallTime



--  Insert into #FinalHelpCode (Plantid,Machineid,HelpDescription,ActionInfo,LastCallTime,MobileNo,Helpcode,ActionNo,Remarks)
--select  H.Plantid,H.Machineid,H.HelpDescription,HA.Action,H.LastCallTime,M.MobileNo,H.Helpcode,M.ActionNo,H.Remarks from #HelpCode H
-- inner join MessageHistory M on H.Machineid=M.MachineID and H.Helpcode=M.HelpCode and H.LastCallTime=M.StartTime
-- inner join HelpCodeActionInfo HA on HA.ActionNo=M.ActionNo
-- where H.ActionNo='03'

Insert into #FinalHelpCode (Plantid,Machineid,HelpDescription,ActionInfo,LastCallTime,MobileNo,MessageInfo,Helpcode,ActionNo,Remarks)
select H.Plantid,H.Machineid,H.HelpDescription,H.ActionInfo,H.LastCallTime,H.MobileNo,H.MessageInfo,H.Helpcode,H.ActionNo,H.Remarks from #HelpCode H
where H.ActionNo='04' and Not exists (select * from MessageHistory A2 
  where H.Machineid=A2.MachineID and H.LastCallTime=A2.StartTime and H.HelpCode=A2.HelpCode and H.ActionNo=A2.ActionNo)


 create table #MobileNo
(
Machineid nvarchar(50),
Helpcode nvarchar(50),
Raisedtime datetime,
MobileNo nvarchar(4000)
)

create table #MobileNo1
(
Machineid nvarchar(50),
Helpcode nvarchar(50),
Raisedtime datetime,
MobileNo nvarchar(4000)
)

create table #MobileNo2
(
Machineid nvarchar(50),
Helpcode nvarchar(50),
Raisedtime datetime,
MobileNo nvarchar(4000)
)

insert into #MobileNo
Select distinct Machineid,Helpcode,LastCallTime,MobileNo from #FinalHelpCode 

insert into #MobileNo1(Machineid,Helpcode,Raisedtime,MobileNo)
SELECT a.MachineID,a.Helpcode,a.Raisedtime,
     Trim(Split.a.value('.', 'VARCHAR(100)')) AS String  
 FROM  (SELECT MachineID, Helpcode, Raisedtime,
         CAST ('<M>' + REPLACE(MobileNo , ',', '</M><M>') + '</M>' AS XML) AS String  
     FROM  #MobileNo) AS A CROSS APPLY String.nodes ('/M') AS Split(a);

insert into #MobileNo2(Machineid,Raisedtime,Helpcode,MobileNo)
SELECT t.MachineID,t.Raisedtime , t.Helpcode,   
      STUFF(ISNULL((SELECT distinct ' , ' + M.MobileNo 
      FROM #MobileNo1 M     
        WHERE M.MachineID = t.MachineID and M.raisedtime = t.raisedtime and M.Helpcode = t.Helpcode
     GROUP BY M.MobileNo
      FOR XML PATH (''), TYPE).value('.','nVARCHAR(max)'), ''), 1, 2, '')           
    FROM #MobileNo1 t group by t.MachineID,t.Raisedtime , t.Helpcode


update #FinalHelpCode set Mobileno = T.Mobileno from
(select distinct Machineid,Raisedtime,MobileNo,Helpcode from #MobileNo2
)t inner join #FinalHelpCode on 
#FinalHelpCode.MachineID = t.MachineID and #FinalHelpCode.LastCallTime = t.raisedtime and #FinalHelpCode.Helpcode = t.Helpcode


Update #FinalHelpCode set MessageInfo=isnull(t.Msg,'')
from (
select distinct M.Machineid,HD.LastCallTime as raisedtime,HD.HelpCode,'TPM-Trak Msg From Machine  ' + HD.Machineid + ' : ' + isnull(HR.Message,'') + ' ' + Convert(nvarchar(20),HD.LastCallTime,100) as Msg from #FinalHelpCode HD
inner join Machineinformation M on HD.Machineid=M.Machineid
inner join Plantmachine PM on PM.machineid=M.machineid
inner join Plantinformation P on P.Plantid=PM.Plantid
left join HelpRequestRule HR on HR.Plantid=P.PlantCode and M.InterfaceID=HR.Machineid and HD.HelpCode=HR.HelpCode and HR.Action='04'
)t inner join #FinalHelpCode on 
#FinalHelpCode.MachineID = t.MachineID and #FinalHelpCode.LastCallTime = t.raisedtime and #FinalHelpCode.Helpcode = t.Helpcode

--Update #FinalHelpCode set MessageInfo=isnull(t.Msg,'')
--from (
--select distinct HD.Machineid,HD.LastCallTime as raisedtime,HD.HelpCode,'TPM-Trak Msg From Machine  ' + HD.Machineid + ' : Help request Closed'  + ' ' + Convert(nvarchar(20),HD.LastCallTime,100) as Msg 
--from #FinalHelpCode HD
--)t inner join #FinalHelpCode on 
--#FinalHelpCode.MachineID = t.MachineID and #FinalHelpCode.LastCallTime = t.raisedtime and #FinalHelpCode.Helpcode = t.Helpcode

 Select @j=Count(*) from #FinalHelpcode
select @i = 1


If @j <> 0
BEGIN

	While @i<=@j
	BEGIN

		Select @Reqtime = LastCallTime from #FinalHelpCode where slno = @i
	
		select @logicalstartdate = dbo.f_GetLogicalDayStart(@Reqtime)

		Insert into #CurrentShift(Startdate,shiftname,Starttime,Endtime)
		exec [s_GetShiftTime] @logicalstartdate,''

		update #CurrentShift set shiftid = T1.shiftid
		from( select shiftid,shiftname from shiftdetails where running=1)T1
		inner join #CurrentShift on #CurrentShift.shiftname=T1.shiftname

		Update #FinalHelpCode set Shiftid = Isnull(#FinalHelpCode.shiftid,0) + isnull(T1.shiftid,0) from
		(select TOP 1 * from #CurrentShift where @Reqtime>=starttime and @Reqtime<=endtime
		 ORDER BY STARTTIME ASC) T1 where slno=@i

		select @Reqtime = ''
		select @i = @i + 1

	END
END

  select distinct Plantid,Machineid,HelpDescription,HelpCode,LastCallTime,MobileNo,MessageInfo,'04' as ActionNo,ShiftID  into #FinalOutput1 from #FinalHelpCode
 order by Machineid,HelpCode

 Insert into Messagehistory(StartTime,Requestedtime,Msgstatus,MobileNo,Message,Machineid,ActionNo,HelpCode,ShiftID)
  select distinct LastCallTime,LastCallTime,0,MobileNo,MessageInfo, Machineid,ActionNo,HelpCode,ShiftID from #FinalOutput1 A1
  where not exists(select * from MessageHistory A2 
  where A1.Machineid=A2.MachineID and A1.LastCallTime=A2.StartTime and A1.HelpCode=A2.HelpCode and A1.ActionNo=A2.ActionNo)


End 
