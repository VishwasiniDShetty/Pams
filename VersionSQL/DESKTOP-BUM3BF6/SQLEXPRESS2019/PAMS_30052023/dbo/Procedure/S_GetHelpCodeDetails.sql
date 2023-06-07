/****** Object:  Procedure [dbo].[S_GetHelpCodeDetails]    Committed by VersionSQL https://www.versionsql.com ******/

/*******************************************************************************************************************
---NR0095 - 2013-Oct-31 - SwathiKS :: Created New Procedure to log HelpCode Details into Message History Table based on
-- rules in Helprequestrule table.
--ER0377 - 11/Mar/2014 - SwathiKS :: To introduce with(NOLOCK) in Select Statements for Performance Optimization.
*******************************************************************************************************************/
CREATE Procedure [dbo].[S_GetHelpCodeDetails]
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
	Threshold int,
	CountofRows int
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
	ShiftID int
)

create table #CurrentShift
(
	Startdate datetime,
	shiftname nvarchar(10),
	Starttime datetime,
	Endtime datetime,
	shiftid int
)


Declare @Reqtime as datetime
Declare @i as integer,@j as integer
Declare @logicalstartdate datetime

Declare @curtime as datetime
Select @curtime = convert(Nvarchar(20),Getdate(),120)


Insert into #HelpCode (Plantid,Machineid,HelpDescription,ActionInfo,LastCallTime,MobileNo,Level2MobNo,MessageInfo,Threshold)
select P.Plantid,M.Machineid,HM.Help_Description,HA.Action,
Max(HD.Starttime),HR.MobileNo,HR.Level2MobNo,HR.[Message],HR.Threshold
from HelpCodeDetails HD with (NOLOCK) --ER0377
inner join HelpRequestRule HR on HD.Plantid=HR.Plantid and HD.Machineid=HR.Machineid and HD.HelpCode=HR.HelpCode and HD.Action1=HR.Action
inner join Machineinformation M on HD.Machineid=M.interfaceid
inner join HelpCodeMaster HM on HM.Help_Code=HD.HelpCode
inner join HelpCodeActionInfo HA on HA.ActionNo=HD.Action1
inner join Plantmachine PM on PM.machineid=M.machineid
inner join Plantinformation P on P.Plantid=PM.Plantid
where HD.Action1='01' 
group by P.Plantid,M.Machineid,HM.Help_Description,HA.Action,HR.MobileNo,HR.Level2MobNo,HR.[Message],HR.Threshold

Update #HelpCode set LastCallTime = T1.LastCall,ActionInfo=T1.Action,MobileNo=T1.MobileNo,
Level2MobNo=T1.Level2MobNo,MessageInfo=T1.[Message],Threshold=T1.Threshold from
(select P.Plantid,M.Machineid,HM.Help_Description,HA.Action,
max(HD.Starttime)as Starttime,Max(HD.Endtime)as LastCall,HR.MobileNo,HR.Level2MobNo,HR.[Message],HR.Threshold
from HelpCodeDetails HD with (NOLOCK) --ER0377
inner join HelpRequestRule HR on HD.Plantid=HR.Plantid and HD.Machineid=HR.Machineid and HD.HelpCode=HR.HelpCode and HD.Action2=HR.Action
inner join Machineinformation M on HD.Machineid=M.interfaceid
inner join HelpCodeMaster HM on HM.Help_Code=HD.HelpCode
inner join HelpCodeActionInfo HA on HA.ActionNo=HD.Action2
inner join Plantmachine PM on PM.machineid=M.machineid
inner join Plantinformation P on P.Plantid=PM.Plantid
where HD.Action2='03' 
group by P.Plantid,M.Machineid,HM.Help_Description,
HA.Action,HR.MobileNo,HR.Level2MobNo,HR.[Message],HR.Threshold) T1 
inner join #HelpCode H on T1.Plantid=H.Plantid and T1.Machineid=H.Machineid
and T1.Starttime=H.LastCallTime and T1.Help_Description=H.HelpDescription


Update #HelpCode set CountOfRows = isnull(CountOfRows,0) +  isnull(T.CountInit,0) from
(Select Count(*) as CountInit,M.Machineid,M.Requestedtime,H.ActionInfo from MessageHistory M with (NOLOCK) --ER0377
inner join #HelpCode H on M.Machineid=H.Machineid and M.RequestedTime=H.LastCallTime
 Group by M.Machineid,M.Requestedtime,H.ActionInfo)T inner join #HelpCode H on T.Machineid=H.Machineid and T.RequestedTime=H.LastCallTime


 ---Inserting when Data not present in MessageHistory for the incoming Machineid.
Insert into #FinalHelpCode (Plantid,Machineid,HelpDescription,ActionInfo,LastCallTime,MobileNo,MessageInfo)
select  H.Plantid,H.Machineid,H.HelpDescription,H.ActionInfo,H.LastCallTime,H.MobileNo,H.MessageInfo from #HelpCode H
where H.machineid not in(select distinct isnull(Machineid,'a') from Messagehistory with (NOLOCK)) --ER0377

 ---Inserting when Machineid already exist in MessageHistory table but Timestamps are different and CountofRow in MessageHistory should be less than 1.
Insert into #FinalHelpCode (Plantid,Machineid,HelpDescription,ActionInfo,LastCallTime,MobileNo,MessageInfo)
select H.Plantid,H.Machineid,H.HelpDescription,H.ActionInfo,H.LastCallTime,H.MobileNo,H.MessageInfo from #HelpCode H
inner join (select Machineid,Max(RequestedTime) as RequestedTime from MessageHistory with (NOLOCK) --ER0377
group by Machineid) M on M.Machineid=H.Machineid and M.RequestedTime <> H.LastCallTime and isnull(H.CountOfRows,0)<1


--Escalation for RESET
--Inserting when Machineid already exist in MessageHistory table but Timestamps are different and CountofRow in MessageHistory should be less than 1. 
--and If Lastaction is "Initiated" and Escalated i.e CountofRows in MessageHistory = "2" then send Message to Level2MobNos when Actioninfo="RESET"
 Insert into #FinalHelpCode (Plantid,Machineid,HelpDescription,ActionInfo,LastCallTime,MobileNo,MessageInfo)
select H.Plantid,H.Machineid,H.HelpDescription,H.ActionInfo,H.LastCallTime,H.Level2MobNo,H.MessageInfo from #HelpCode H
inner join ( Select T1.Machineid,T1.Requestedtime,M.Actionno,Count(*) as Countofaction from 
 (Select M.Machineid,MAX(M.Requestedtime) as Requestedtime from MessageHistory M with (NOLOCK) Group by M.Machineid)T1  --ER0377
 inner join MessageHistory M on T1.Machineid=M.Machineid and T1.RequestedTime=M.RequestedTime
 group by  T1.Machineid,T1.Requestedtime,M.Actionno) M on M.Machineid=H.Machineid and M.RequestedTime <> H.LastCallTime 
 and isnull(H.CountOfRows,0)<1 and H.ActionInfo='Reset' and M.Actionno='01' and M.Countofaction=2

 --To avoid Duplicates when action'Reset'
 --i.e Machine already present with Same Timestamp for the action 'Reset' then CountofRows should be 'Zero'.
Insert into #FinalHelpCode (Plantid,Machineid,HelpDescription,ActionInfo,LastCallTime,Mobileno,MessageInfo)
select  H.Plantid,H.Machineid,H.HelpDescription,H.ActionInfo,H.LastCallTime,H.MobileNo,H.MessageInfo from #HelpCode H
inner join (select distinct Machineid,Max(RequestedTime) as RequestedTime from MessageHistory with (NOLOCK) --ER0377
group by  Machineid) M on M.Machineid=H.Machineid and M.RequestedTime = H.LastCallTime
where H.ActionInfo='Reset' and isnull(H.CountOfRows,0) = 0

--To handle duplicates and Escalation for action 'Initiated' 
--i.e Machine already present with Same Timestamp for the action not equal to 'Reset' then CountofRows=1 then send message to Level2MobNos.
Insert into #FinalHelpCode (Plantid,Machineid,HelpDescription,ActionInfo,LastCallTime,Mobileno,MessageInfo)
select  H.Plantid,H.Machineid,H.HelpDescription,H.ActionInfo,H.LastCallTime,H.Level2MobNo,H.MessageInfo from #HelpCode H
inner join (select distinct Machineid,Max(RequestedTime) as RequestedTime from MessageHistory with (NOLOCK) --ER0377
group by  Machineid) M on M.Machineid=H.Machineid and M.RequestedTime=H.LastCallTime
where H.ActionInfo<>'Reset' and Datediff(s,RequestedTime,@Curtime)>H.Threshold and H.CountOfRows<2 --and Datediff(s,RequestedTime,@Curtime)< H.Threshold+20

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

--Update #FinalHelpCode set Helpcode = Case when HelpDescription='Material' THEN '01'
--WHEN HelpDescription='Maintenance' THEN '02'
--WHEN HelpDescription='Inspection' THEN '03'
--WHEN HelpDescription='Supervision' THEN '04'
--eND
--
--Update #FinalHelpCode set ActionNo = Case when ActionInfo='Initiated' THEN '01'
--WHEN ActionInfo='Acknowledged' THEN '02'
--WHEN ActionInfo='Reset' THEN '03'
--WHEN ActionInfo='Completed' THEN '04'
--eND

Update #FinalHelpCode set Helpcode = T1.Help_Code from
(Select HelpCodeMaster.Help_Code,HelpCodeMaster.Help_Description from HelpCodeMaster inner join #FinalHelpCode
on #FinalHelpCode.HelpDescription=HelpCodeMaster.Help_Description)T1 inner join #FinalHelpCode
on #FinalHelpCode.HelpDescription=T1.Help_Description

Update #FinalHelpCode set ActionNo = T1.ActionNo from
(Select HelpCodeActionInfo.ActionNo,HelpCodeActionInfo.Action from HelpCodeActionInfo inner join #FinalHelpCode
on #FinalHelpCode.ActionInfo=HelpCodeActionInfo.Action)T1 inner join #FinalHelpCode
on #FinalHelpCode.ActionInfo=T1.Action

Insert into Messagehistory(Requestedtime,Msgstatus,MobileNo,Message,Machineid,shiftid,ActionNo,HelpCode)
select LastCallTime,0,MobileNo 
,'TPM-Trak Msg From Machine  ' + Machineid + ' : ' + MessageInfo + ' ' + Convert(nvarchar(20),LastCallTime,100),
Machineid,shiftid,ActionNo,HelpCode from #FinalHelpCode Order by LastCallTime

End 
