/****** Object:  Procedure [dbo].[NewTech_MachineDataEditDetails]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[NewTech_MachineDataEditDetails]
@MachineID nvarchar(50) = ''

AS      
BEGIN

CREATE TABLE #MachineDataEdit(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[MachineID] [nvarchar](50) NULL,
	[UserID] [nvarchar](50) NULL,
	[OffsetChange] [bit] NULL,
	[ProgramEdit] [bit] NULL,
	[ParameterEdit] [bit] NULL,
	[Action] [nvarchar](50) NULL,
	[OffsetChangeStartTime] [datetime] NULL,
	[ProgramEditStartTime] [datetime] NULL,
	[ParameterEditStartTime] [datetime] NULL,
	[OffsetChangeEndTime] [datetime] NULL,
	[ProgramEditEndTime] [datetime] NULL,
	[ParameterEditEndTime] [datetime] NULL,
	[OffsetChangeExpectedEndTime] [datetime] NULL,
	[ProgramEditExpectedEndTime] [datetime] NULL,
	[ParameterEditExpectedEndTime] [datetime] NULL,
	[OffsetChangeTime] [nvarchar](50) NULL,
	[ProgramEditTime] [nvarchar](50) NULL,
	[ParameterEditTime] [nvarchar](50) NULL,
	[CountofEnabledParam] int,
	[CountofCompleted] int,
) 



Insert into #MachineDataEdit(MachineID,UserID,OffsetChange,ProgramEdit,ParameterEdit,
OffsetChangeStartTime,ProgramEditStartTime,ParameterEditStartTime,
OffsetChangeEndTime,ProgramEditEndTime,ParameterEditEndTime,CountofEnabledParam,CountofCompleted)
SELECT M.MachineID,UserID,OffsetChange,ProgramEdit,ParameterEdit,OffsetChangeStartTime,ProgramEditStartTime,ParameterEditStartTime,
OffsetChangeEndTime,ProgramEditEndTime,ParameterEditEndTime,0,0
from (select MachineID,max(ID) as id from MachineDataEdit group by MachineID)T
inner join MachineDataEdit M on T.id=M.id where (M.MachineID=@MachineID or isnull(@MachineID,'')='')
Union
Select Machineid,'',0,0,0,'','','','','','',0,0 from machineinformation
where Machineid Not in(select distinct Machineid from MachineDataEdit)
and  (MachineID=@MachineID or isnull(@MachineID,'')='')

update #MachineDataEdit set OffsetChangeExpectedEndTime=dateadd(second,T.OffsetChangeTime,OffsetChangeStartTime),OffsetChangeTime=T.OffsetChangeTime,
ParameterEditExpectedEndTime=dateadd(second,T.ParameterEditTime,ParameterEditStartTime),ProgramEditTime=T.ProgramEditTime,
ProgramEditExpectedEndTime=dateadd(second,T.ProgramEditTime,ProgramEditStartTime),ParameterEditTime=T.ParameterEditTime From
(Select MachineID, OffsetChangeTime, ParameterEditTime, ProgramEditTime FROM  MachineDataSettings)T inner join #MachineDataEdit on T.MachineID=#MachineDataEdit.MachineID

update #MachineDataEdit set CountofEnabledParam=1 from
(Select * from #MachineDataEdit where OffsetChange=1)T inner join #MachineDataEdit on T.MachineID=#MachineDataEdit.MachineID

update #MachineDataEdit set CountofEnabledParam=isnull(#MachineDataEdit.CountofEnabledParam,0)+1 from
(Select * from #MachineDataEdit where ProgramEdit=1)T inner join #MachineDataEdit on T.MachineID=#MachineDataEdit.MachineID

update #MachineDataEdit set CountofEnabledParam=isnull(#MachineDataEdit.CountofEnabledParam,0)+1 from
(Select * from #MachineDataEdit where ParameterEdit=1)T inner join #MachineDataEdit on T.MachineID=#MachineDataEdit.MachineID


update #MachineDataEdit set CountofCompleted=1 from
(Select * from #MachineDataEdit where isnull(OffsetChangeEndTime,'')<>'' and OffsetChange=1)T inner join #MachineDataEdit on T.MachineID=#MachineDataEdit.MachineID

update #MachineDataEdit set CountofCompleted=isnull(#MachineDataEdit.CountofCompleted,0)+1 from
(Select * from #MachineDataEdit where isnull(ProgramEditEndTime,'')<>'' and ProgramEdit=1)T inner join #MachineDataEdit on T.MachineID=#MachineDataEdit.MachineID

update #MachineDataEdit set CountofCompleted=isnull(#MachineDataEdit.CountofCompleted,0)+1 from
(Select * from #MachineDataEdit where isnull(ParameterEditEndTime,'')<>'' and ParameterEdit=1)T inner join #MachineDataEdit on T.MachineID=#MachineDataEdit.MachineID

update #MachineDataEdit set Action=case when CountofEnabledParam=CountofCompleted then 'Start' else 'End' end

update #MachineDataEdit SET UserID=case when action='Start' then '' else UserID end,
OffsetChange=case when action='Start' then 0 else OffsetChange end,
ProgramEdit=case when action='Start' then 0 else ProgramEdit end ,
ParameterEdit=case when action='Start' then 0 else ParameterEdit end,
--Action=case when action='End' then 'Start' else Action End,
OffsetChangeStartTime=case when action='Start' then '' else OffsetChangeStartTime end,
ProgramEditStartTime=case when action='Start' then '' else ProgramEditStartTime end,
ParameterEditStartTime=case when action='Start' then '' else ParameterEditStartTime end,
OffsetChangeEndTime=case when action='Start' then '' else OffsetChangeEndTime end,
ProgramEditEndTime=case when action='Start' then '' else ProgramEditEndTime end,
ParameterEditEndTime=case when action='Start' then '' else ParameterEditEndTime end,
OffsetChangeTime=case when action='Start' then OffsetChangeTime when cast(OffsetChangeExpectedEndTime as date)<>'1900-01-01' and OffsetChangeExpectedEndTime>=getdate()
then datediff(second,getdate(),OffsetChangeExpectedEndTime) else 0 end,
ProgramEditTime=case when action='Start' then ProgramEditTime when cast(ProgramEditExpectedEndTime as date)<>'1900-01-01' and ProgramEditExpectedEndTime>=getdate()
then datediff(second,getdate(),ProgramEditExpectedEndTime) else 0 end,
ParameterEditTime=case when action='Start' then ParameterEditTime when cast(ParameterEditExpectedEndTime as date)<>'1900-01-01' and ParameterEditExpectedEndTime>=getdate()
then datediff(second,getdate(),ParameterEditExpectedEndTime) else 0 end

select * from #MachineDataEdit

END
