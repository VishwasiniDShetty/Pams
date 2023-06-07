/****** Object:  Procedure [dbo].[s_GetMainiHelpRequestGrid]    Committed by VersionSQL https://www.versionsql.com ******/

/*
[dbo].[s_GetMainiHelpRequestGrid] 'Assembly'
[dbo].[s_GetMainiHelpRequestGrid] 'Balancing'

*/
CREATE Procedure [dbo].[s_GetMainiHelpRequestGrid]
@Machineid nvarchar(50)
AS
Begin

declare @count int
select @count=count(help_code) from HelpCodeMaster
Create table #HelpRequest
(
	ID bigint identity(1,1) Not null,
	Helpcode nvarchar(50),
	HelpDescription nvarchar(50),
    ActionNo nvarchar(50),
	ActionCode nvarchar(50),
	ISChecked int Default 0,
	Remarks nvarchar(max),
	RowID int,
	RaisedTimeStamp datetime,
	AckTimeStamp DATETIME,
	ResetTimeStamp datetime,
	CompletedTimeStamp Datetime,
	RaiseTime nvarchar(50),
	AckTime nvarchar(50),
	ResetTime nvarchar(50),
)

--Create table #HelpRequestTime
--(
--	ID bigint identity(1,1) Not null,
--	Helpcode nvarchar(50),
--	HelpDescription nvarchar(50),
--	RaisedTimeStamp datetime,
--	AckTimeStamp DATETIME,
--	ResetTimeStamp datetime,
--	CompletedTimeStamp Datetime,
--	RaiseTime nvarchar(50),
--	AckTime nvarchar(50),
--	ResetTime nvarchar(50)
--)

create table #temp1
(
Helpcode nvarchar(50),
Department nvarchar(50),
[Raised] int default 0,
[Ack] int default 0,
[Reset] int default 0,
[Close] int default 0
)

create table #temp2
(
Helpcode nvarchar(50),
HelpDescription nvarchar(50),
RowID INT,
Remarks nvarchar(max)
)



Declare @Curtime as datetime
Select @Curtime=getdate()

Insert into #HelpRequest(Helpcode,HelpDescription,ActionNo,ActionCode,ISChecked,Rowid)
Select HC.Help_code,HC.Help_Description,HA.ActionNo,HA.Action,0,0 from  HelpCodeActionInfo HA
Cross Join HelpCodeMaster HC
Order by HA.ActionNo,HC.Help_code

Declare @LastAction as nvarchar(10)
Select @LastAction = MAX(ActionNo) From HelpCodeActionInfo


--Update #HelpRequest Set ISChecked = T.checked,RowID=T.ROWID,Remarks=T.Remarks From
--(Select Helpcodedetails.Helpcode,Case when Helpcodedetails.Action2 IS NULL then Helpcodedetails.Action1 else Helpcodedetails.Action2 End as ActionNo,Case when Helpcodedetails.Action2=@LastAction then '0' else  '1'  end as checked,T1.ID as Rowid,Helpcodedetails.Remarks from Helpcodedetails inner join 
--(Select H.Helpcode,Max(H.ID) as ID from Helpcodedetails H inner join Machineinformation  M on H.Machineid=M.interfaceid
--where M.Machineid=@MachineId group by H.Helpcode)T1 on Helpcodedetails.ID=T1.ID and Helpcodedetails.Helpcode=T1.Helpcode
--)T inner join #HelpRequest on #HelpRequest.ActionNo=T.ActionNo and #HelpRequest.Helpcode=T.Helpcode

--Insert into #HelpRequestTime(Helpcode,HelpDescription)
--Select HC.Help_code,HC.Help_Description from HelpCodeMaster HC
--Order by HC.Help_code

Update #HelpRequest Set ISChecked = T.checked,RowID=T.ROWID,Remarks=T.Remarks From
(Select Helpcodedetails.Helpcode,Case when Helpcodedetails.Action2 IS NULL then Helpcodedetails.Action1 else Helpcodedetails.Action2 End as ActionNo,Case when Helpcodedetails.Action2=@LastAction then '0' else  '1'  end as checked,T1.ID as Rowid,Helpcodedetails.Remarks from Helpcodedetails inner join 
(Select H.Helpcode,Max(H.ID) as ID from Helpcodedetails H inner join Machineinformation  M on H.Machineid=M.interfaceid
where M.Machineid=@MachineId group by H.Helpcode)T1 on Helpcodedetails.ID=T1.ID and Helpcodedetails.Helpcode=T1.Helpcode
)T inner join #HelpRequest on #HelpRequest.ActionNo=T.ActionNo and #HelpRequest.Helpcode=T.Helpcode



Update #HelpRequest Set RaisedTimeStamp = T.RTime from
(Select H.Starttime as Rtime,H.Helpcode,H.Action1 From Helpcodedetails H inner join 
	(
	Select H.Helpcode,Max(H.ID) as ID from Helpcodedetails H inner join Machineinformation  M on H.Machineid=M.interfaceid
	where M.Machineid=@MachineId and H.Action1='01' group by H.Helpcode
	)T1 on H.ID=T1.ID and H.Helpcode=T1.Helpcode
)T inner join #HelpRequest on #HelpRequest.Helpcode=T.Helpcode

Update #HelpRequest Set AckTimeStamp = T.ATime from
(
 Select H.Endtime as Atime,H.Helpcode,H.Starttime,H.Action2 From Helpcodedetails H
 inner join Machineinformation  M on H.Machineid=M.interfaceid 
 inner join #HelpRequest on #HelpRequest.RaisedTimeStamp=H.Starttime and #HelpRequest.Helpcode=H.Helpcode
 where M.Machineid=@MachineId and (H.Action1='01' and H.Action2='02')
)T inner join #HelpRequest on #HelpRequest.Helpcode=T.Helpcode

Update #HelpRequest Set ResetTimeStamp = T.ResetTime from
(
 Select H.Endtime as ResetTime,H.Helpcode,H.Starttime,H.Action2 From Helpcodedetails H
 inner join Machineinformation  M on H.Machineid=M.interfaceid 
 inner join #HelpRequest on #HelpRequest.RaisedTimeStamp=H.Starttime and #HelpRequest.Helpcode=H.Helpcode
 where M.Machineid=@MachineId and (H.Action1='01' and H.Action2='03')
)T inner join #HelpRequest on #HelpRequest.Helpcode=T.Helpcode

Update #HelpRequest Set CompletedTimeStamp = T.CloseTime from
(
 Select H.Endtime as CloseTime,H.Helpcode,H.Starttime,H.Action2 From Helpcodedetails H
 inner join Machineinformation  M on H.Machineid=M.interfaceid 
 inner join #HelpRequest on #HelpRequest.RaisedTimeStamp=H.Starttime and #HelpRequest.Helpcode=H.Helpcode
 where M.Machineid=@MachineId and (H.Action1='01' and H.Action2='04')
)T inner join #HelpRequest on #HelpRequest.Helpcode=T.Helpcode


Update #HelpRequest Set RaiseTime = T1.RaiseTime from
(Select Helpcode,dbo.f_FormatTime(Datediff(second,RaisedTimeStamp,case when AckTimeStamp IS NULL then @Curtime else AckTimeStamp end),'hh:mm:ss') as RaiseTime
From #HelpRequest where ISNULL(RaisedTimeStamp,'1900-01-01')<>'1900-01-01' and 
case when @LastAction='04' then ISNULL(CompletedTimeStamp,'1900-01-01') else ISNULL(ResetTimeStamp,'1900-01-01') end ='1900-01-01')T1
inner join #HelpRequest on  #HelpRequest.Helpcode=T1.Helpcode 

Update #HelpRequest Set AckTime = T1.AckTime from
(Select Helpcode,dbo.f_FormatTime(Datediff(second,AckTimeStamp,case when ResetTimeStamp IS NULL then @Curtime else ResetTimeStamp end),'hh:mm:ss') as AckTime
From #HelpRequest where ISNULL(AckTimeStamp,'1900-01-01')<>'1900-01-01' and 
case when @LastAction='04' then ISNULL(CompletedTimeStamp,'1900-01-01') else ISNULL(ResetTimeStamp,'1900-01-01') end ='1900-01-01')T1
inner join #HelpRequest on #HelpRequest.Helpcode=T1.Helpcode

Update #HelpRequest Set ResetTime = T1.ResetTime from
(Select Helpcode,dbo.f_FormatTime(Datediff(second,ResetTimeStamp,case when CompletedTimeStamp IS NULL then @Curtime else CompletedTimeStamp end),'hh:mm:ss') as ResetTime
From #HelpRequest where ISNULL(ResetTimeStamp,'1900-01-01')<>'1900-01-01' and 
case when @LastAction='04' then ISNULL(CompletedTimeStamp,'1900-01-01') else ISNULL(ResetTimeStamp,'1900-01-01') end ='1900-01-01')T1
inner join #HelpRequest on  #HelpRequest.Helpcode=T1.Helpcode

insert into #temp2
Select distinct T.Helpcode,T.HelpDescription, T.RowID,#HelpRequest.Remarks  from #HelpRequest 
Inner Join (Select top(@count) Helpcode,HelpDescription,RowID from #HelpRequest order by RowID desc)T
on T.Rowid=#HelpRequest.Rowid

update #HelpRequest set RowID=T2.RowID,Remarks=T2.Remarks from
(
SELECT Helpcode,RowID,Remarks FROM #temp2
)T2
INNER JOIN #HelpRequest ON #HelpRequest.Helpcode=T2.Helpcode

DECLARE @query AS NVARCHAR(MAX)
DECLARE @ColumnName AS NVARCHAR(MAX)


select @ColumnName = STUFF((SELECT ',' + QUOTENAME(Actioncode)          
from #HelpRequest group by Actioncode,ActionNo
Order by ActionNo            
FOR XML PATH(''), TYPE                
).value('.', 'NVARCHAR(MAX)')                 
,1,1,'')


set @query = 'SELECT RowiD,Helpcode,HelpDescription as Department,' + @columnname + ',Remarks,RaiseTime,AckTime,ResetTime  from 
             (
                select Helpcode, HelpDescription,Actioncode,RaiseTime,AckTime,ResetTime,Remarks,rowid,ISChecked
                from #HelpRequest
            ) x
            pivot 
            (
                max(ISChecked)
                for Actioncode in (' + @ColumnName + ')
            ) p1
order by Helpcode'
print(@query)
EXEC sp_executesql @query

end
