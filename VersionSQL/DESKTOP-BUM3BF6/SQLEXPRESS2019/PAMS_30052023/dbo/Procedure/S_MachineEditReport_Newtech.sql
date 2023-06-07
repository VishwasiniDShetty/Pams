/****** Object:  Procedure [dbo].[S_MachineEditReport_Newtech]    Committed by VersionSQL https://www.versionsql.com ******/

/*
[dbo].[S_MachineEditReport_Newtech] '2021-05-08 10:00:00.000','2021-05-10 15:00:00.000'
*/
CREATE Procedure [dbo].[S_MachineEditReport_Newtech]
@startTime datetime,
@EndTime datetime
AS
Begin

Create table #Temp(
UserID nvarchar(50),
Dept nvarchar(50),
CNCData nvarchar(50),
LoginDate date,
LoginTime time,
LogoutDate date,
LogoutTime time
)


Insert into #Temp (UserID,CNCData,LoginDate,LoginTime,LogoutDate,LogoutTime)
SELECT UserID, 'OffsetChange', Convert(Date,OffsetChangeStartTime),CONVERT(time,OffsetChangeStartTime), convert(Date,OffsetChangeEndTime),Convert(time,OffsetChangeEndTime)
FROM MachineDataEdit where OffsetChange=1 and CNCTimeStamp>=@startTime and CNCTimeStamp<=@EndTime

Insert into #Temp (UserID,CNCData,LoginDate,LoginTime,LogoutDate,LogoutTime)
SELECT UserID, 'ProgramEdit', Convert(date, ProgramEditStartTime),convert(time,ProgramEditStartTime), convert(date,ProgramEditEndTime),convert(time,ProgramEditEndTime)
FROM MachineDataEdit where ProgramEdit=1 and CNCTimeStamp>=@startTime and CNCTimeStamp<=@EndTime

Insert into #Temp (UserID,CNCData,LoginDate,LoginTime,LogoutDate,LogoutTime)
SELECT UserID, 'ParameterEdit', Convert(date,ParameterEditStartTime), convert(time,ParameterEditStartTime),convert(date,ParameterEditEndTime),convert(time,ParameterEditEndTime)
FROM MachineDataEdit where ParameterEdit=1 and CNCTimeStamp>=@startTime and CNCTimeStamp<=@EndTime

update #Temp set Dept= t.Role from
(select emp.Employeeid,emp.Role from employeeinformation emp inner join #Temp t1 on t1.UserID=emp.Employeeid) as t
inner join #Temp t2 on t2.UserID=t.Employeeid

select UserID,Dept,CNCData,LoginDate,LoginTime,LogoutDate,LogoutTime from #Temp

End
