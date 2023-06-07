/****** Object:  Procedure [dbo].[s_GetAggOEEReport_Nippon]    Committed by VersionSQL https://www.versionsql.com ******/

/*
performance
[dbo].[s_GetAggOEEReport_Nippon] '2020-07-09','2020-07-09','','','','SHOP 2',''
[dbo].[s_GetAggOEEReport_Nippon] '2020-08-09','2020-08-09','','KI/VMC-19',''
[dbo].[s_GetAggOEEReport_Nippon] '2020-08-09','2020-08-09','','KI/VMC-22',''
[dbo].[s_GetAggOEEReport_Nippon] '2020-11-09','2020-11-09','','KI/HMC-03',''
[dbo].[s_GetAggOEEReport_Nippon] '2021-07-01','2021-07-01','','',''
exec [dbo].[s_GetAggOEEReport_Nippon] @StartDate=N'2021-09-12',@EndDate=N'2021-09-18',@ShiftName=N'',@MachineID=N'',@PlantID=N'INDIAN NIPPON P1',@GroupID=N'',@Parameter=N'View'
exec [dbo].[s_GetAggOEEReport_Nippon] @StartDate=N'2021-08-26',@EndDate=N'2021-08-26',@ShiftName=N'',@MachineID=N'',@PlantID=N'',@GroupID=N'',@Parameter=N'View'
*/
CREATE PROCEDURE [dbo].[s_GetAggOEEReport_Nippon]
@StartDate As DateTime,
@EndDate As DateTime,
@ShiftName As NVarChar(20)='',
@MachineID As nvarchar(50) = '',
@Parameter As nvarchar(50)='',
@PlantID nvarchar(50)='',
@GroupID nvarchar(50)=''

AS
BEGIN

Declare @Strsql nvarchar(4000)
Declare @Strmachine nvarchar(255)
Declare @timeformat AS nvarchar(12)
Declare @StrShift AS NVarchar(255)
Declare @StrDmachine nvarchar(255)
Declare @StrDShift AS NVarchar(255)
Declare @CurDate as datetime
Declare @FromTime as datetime
Declare @ToTime as datetime
Declare @StrPlant nvarchar(255)
Declare @StrGroup nvarchar(255)
Declare @StrDPlant nvarchar(255)
Declare @StrDGroup nvarchar(255)

Select @Strsql = ''
Select @Strmachine = ''
Select @StrShift=''
Select @StrDmachine = ''
Select @StrDShift=''
Select @StrPlant=''
Select @StrGroup=''
Select @StrDPlant=''
Select @StrDGroup=''

If isnull(@Machineid,'') <> ''
Begin
Select @Strmachine = ' And ( Machineinformation.MachineID = N''' + @MachineID + ''')'
End
If isnull(@ShiftName,'') <> ''
Begin
Select @StrShift = ' And ( s.Shift = N''' + @ShiftName + ''')'
End
If isnull(@PlantID,'') <> ''
Begin
Select @StrPlant = ' And ( Plantmachine.PlantID = N''' + @PlantID + ''')'
End
If isnull(@GroupID,'') <> ''
Begin
Select @StrGroup = ' And ( Plantmachinegroups.GroupID = N''' + @GroupID + ''')'
End


If isnull(@Machineid,'') <> ''
Begin
Select @StrDmachine = ' And ( ShiftDownTimeDetails.MachineID = N''' + @MachineID + ''')'
End
If isnull(@ShiftName,'') <> ''
Begin
Select @StrDShift = ' And ( ShiftDownTimeDetails.Shift = N''' + @ShiftName + ''')'
End
If isnull(@PlantID,'') <> ''
Begin
Select @StrDPlant = ' And ( ShiftDownTimeDetails.PlantID = N''' + @PlantID + ''')'
End
If isnull(@GroupID,'') <> ''
Begin
Select @StrDGroup = ' And ( ShiftDownTimeDetails.GroupID = N''' + @GroupID + ''')'
End

Select @timeformat ='ss'
Select @timeformat = isnull((Select valueintext from cockpitdefaults where parameter='timeformat'),'ss')
if (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')
Begin
Select @timeformat = 'ss'
End

Select @CurDate = CAST(datePart(yyyy,@StartDate) AS nvarchar(4)) + '-' + SUBSTRING(DATENAME(MONTH,@StartDate),1,3) + '-' + CAST(datePart(dd,@StartDate) AS nvarchar(2))

Create Table #machine
(
MachineID NVarChar(50),
Shift NVarChar(50),
Pdate DateTime,
Startdate DateTime,
Enddate DateTime
)

Create Table #ProdData
(
MachineID NVarChar(50),
Shift NVarChar(50),
ComponentID NVarChar(50) default '',
OperationNo nvarchar(50) default '',
OperatorID nvarchar(50) default '',
EmployeeName nvarchar(50) default '',
StdCycleTime Float,
ProdCount float default 0,
AcceptedParts float default 0,
RejCount float default 0,
Pdate DateTime,
Startdate DateTime,
Enddate DateTime,
ScheduleTime float,
Preventive float,
MCcleaning float,
NoPlan float,
DueToLowHigh float,
DueToMachine float,
DueToMethod float,
DueToMaterials float,
DueToMeasurement float,
Breakdown  float,
ProdDowntime  float,
TotalAT float ,
NetAT float,
NetOT float,
IdelOT float,
LostOT float,
MarkedForRework Int,
AEffy Float,
PEffy Float,
QEffy Float,
OEffy Float,
OperatorEfficiency float,
UtilisedTime Float,
DownTime Float,
ManagementLoss Float,
DownTimeAE Float,
CN Float,
Target float,
Performance1 float,
DownPDT FLOAT DEFAULT 0,
ProductionPDT FLOAT DEFAULT 0
)

CREATE TABLE #ShiftDetails (
PDate datetime,
Shift nvarchar(20),
ShiftStart datetime,
ShiftEnd datetime
)

WHILE @StartDate<=@EndDate
BEGIN
INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)
EXEC s_GetShiftTime @Startdate,@ShiftName
SELECT @Startdate = DATEADD(DAY,1,@Startdate)
END



-- Inserting distinct Machines of the given plant
--Select @Strsql=''
--SELECT @StrSql='INSERT INTO #ProdData(MachineID,Shift,ComponentID,Pdate,OperationNo,Startdate,Enddate,Stdcycletime)
--SELECT Distinct  ShiftProductionDetails.Machineid,S.Shift, ShiftProductionDetails.Componentid,S.Pdate, ShiftProductionDetails.OperationNo, S.ShiftStart, S.ShiftEnd,(CO_StdMachiningTime+CO_StdLoadUnload) from ShiftProductionDetails
--inner join Machineinformation M on M.Machineid=ShiftProductionDetails.Machineid
--INNER join #ShiftDetails S on S.Pdate=ShiftProductionDetails.Pdate and S.Shift=ShiftProductionDetails.shift
--Where M.Interfaceid>''0'''
--SELECT @StrSql=@StrSql+ @Strmachine + @StrShift
--Print @StrSql
--EXEC(@StrSql)

Select @Strsql=''
SELECT @StrSql='INSERT INTO #machine(MachineID,Shift,Pdate,Startdate,Enddate)
SELECT Distinct  Machineinformation.Machineid,S.Shift,S.Pdate, S.ShiftStart, S.ShiftEnd from  Machineinformation 
left outer join Plantmachine on Machineinformation.Machineid=Plantmachine.Machineid
left outer join Plantmachinegroups on Machineinformation.Machineid=Plantmachinegroups.Machineid
cross join #ShiftDetails S 
Where Machineinformation.Interfaceid>''0'''
SELECT @StrSql=@StrSql+ @Strmachine + @StrShift + @StrPlant + @StrGroup
Print @StrSql
EXEC(@StrSql)


Select @Strmachine=''
Select @StrShift=''
Select @StrPlant=''
Select @StrGroup=''

If isnull(@Machineid,'') <> ''
Begin
Select @Strmachine = ' And ( ShiftProductionDetails.MachineID = N''' + @MachineID + ''')'
End
If isnull(@ShiftName,'') <> ''
Begin
Select @StrShift = ' And ( ShiftProductionDetails.Shift = N''' + @ShiftName + ''')'
End
If isnull(@PlantID,'') <> ''
Begin
Select @StrPlant = ' And ( ShiftProductionDetails.PlantID = N''' + @PlantID + ''')'
End
If isnull(@GroupID,'') <> ''
Begin
Select @StrGroup = ' And ( ShiftProductionDetails.GroupID = N''' + @GroupID + ''')'
End


--Select @Strsql=''
--SELECT @StrSql='INSERT INTO #ProdData(MachineID,Shift,ComponentID,Pdate,OperationNo,Startdate,Enddate,Stdcycletime)
--SELECT Distinct S.Machineid,S.Shift,ShiftProductionDetails.Componentid,S.Pdate, ShiftProductionDetails.OperationNo, S.Startdate, S.Enddate,(CO_StdMachiningTime+CO_StdLoadUnload) from #machine S
--inner join ShiftProductionDetails on S.Machineid=ShiftProductionDetails.Machineid
--and S.Pdate=ShiftProductionDetails.Pdate and S.Shift=ShiftProductionDetails.shift
--Where 1=1 '
--SELECT @StrSql=@StrSql+ @Strmachine + @StrShift + @StrPlant + @StrGroup
--Print @StrSql
--EXEC(@StrSql)

--Select @Strsql=''
--SELECT @StrSql='INSERT INTO #ProdData(MachineID,Shift,ComponentID,OperatorID,EmployeeName,Pdate,OperationNo,Startdate,Enddate,Stdcycletime)
--SELECT Distinct S.Machineid,S.Shift,ShiftProductionDetails.Componentid,ShiftProductionDetails.OperatorID,E.Name as EmployeeName,S.Pdate, ShiftProductionDetails.OperationNo, S.Startdate, S.Enddate,(CO_StdMachiningTime+CO_StdLoadUnload) from #machine S
--inner join ShiftProductionDetails on S.Machineid=ShiftProductionDetails.Machineid
--and S.Pdate=ShiftProductionDetails.Pdate and S.Shift=ShiftProductionDetails.shift
--inner join employeeinformation E ON E.Employeeid=ShiftProductionDetails.Operatorid
--Where 1=1 '
--SELECT @StrSql=@StrSql+ @Strmachine + @StrShift + @StrPlant + @StrGroup
--Print @StrSql
--EXEC(@StrSql)

Select @Strsql=''
SELECT @StrSql='INSERT INTO #ProdData(MachineID,Shift,ComponentID,OperatorID,EmployeeName,Pdate,OperationNo,Startdate,Enddate)
(SELECT distinct  S.Machineid,S.Shift,ShiftProductionDetails.Componentid,ShiftProductionDetails.OperatorID,E.Name as EmployeeName,S.Pdate, ShiftProductionDetails.OperationNo, S.Startdate, S.Enddate from #machine S
inner join ShiftProductionDetails on S.Machineid=ShiftProductionDetails.Machineid
and S.Pdate=ShiftProductionDetails.Pdate and S.Shift=ShiftProductionDetails.shift
inner join employeeinformation E ON E.Employeeid=ShiftProductionDetails.Operatorid where 1=1 '
SELECT @StrSql=@StrSql+ @Strmachine + @StrShift + @StrPlant + @StrGroup
SELECT @StrSql=@StrSql+'  ) union 
(SELECT  S.Machineid,S.Shift,shiftdowntimedetails.Componentid,shiftdowntimedetails.OperatorID,E.Name as EmployeeName,S.Pdate, shiftdowntimedetails.OperationNo, S.Startdate, S.Enddate  from #machine S
inner join shiftdowntimedetails on S.Machineid=shiftdowntimedetails.Machineid
and S.Pdate=shiftdowntimedetails.ddate and S.Shift=shiftdowntimedetails.shift
inner join employeeinformation E ON E.Employeeid=shiftdowntimedetails.Operatorid
Where 1=1 '
Select @Strsql = @Strsql + @StrDmachine + @StrDShift + @StrDPlant + @StrDGroup
SELECT @StrSql=@StrSql+' ) '
Print @StrSql
EXEC(@StrSql)

Select @Strsql=''
Select @Strsql = 'Update #ProdData Set Stdcycletime=ISNULL(T2.Stdcycletime,0)'
Select @Strsql = @Strsql+ ' From('
Select @Strsql = @Strsql+ ' Select ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.Machineid,ShiftProductionDetails.Componentid,ShiftProductionDetails.OperatorID,sum(CO_StdMachiningTime+CO_StdLoadUnload) As Stdcycletime
From ShiftProductionDetails inner join (select distinct pdate,shift,machineid,Componentid,OperatorID from #Proddata) T1 on ShiftProductionDetails.pDate=T1.Pdate and ShiftProductionDetails.Shift=T1.Shift
and ShiftProductionDetails.Machineid=T1.Machineid and ShiftProductionDetails.Componentid=T1.Componentid  AND ShiftProductionDetails.OperatorID=T1.OperatorID '
Select @Strsql = @Strsql+ ' Where 1=1 '
Select @Strsql = @Strsql + @Strmachine + @StrShift + @StrPlant + @StrGroup
Select @Strsql = @Strsql+ ' GROUP By ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.Machineid,ShiftProductionDetails.Componentid,ShiftProductionDetails.OperatorID '
Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.pDate=T2.pDate And #ProdData.Shift=T2.Shift and #ProdData.Machineid=T2.Machineid and #ProdData.Componentid=T2.Componentid and #ProdData.OperatorID= T2.OperatorID  '
Print @Strsql
EXEC(@StrSql)


--Updating ProdCount,AcceptedParts,MarkedForRework,ReworkPerformed for the selected date-Shift-Machine-Component
Select @Strsql=''
Select @Strsql = 'Update #ProdData Set ProdCount=ISNULL(T2.ProdCount,0),AcceptedParts=ISNULL(T2.AcceptedParts,0),MarkedForRework=ISNULL(T2.MarkedForRework,0)'
Select @Strsql = @Strsql+ ' From('
--Select @Strsql = @Strsql+ ' Select ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.Machineid,ShiftProductionDetails.Componentid,ShiftProductionDetails.OperationNo
Select @Strsql = @Strsql+ ' Select ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.Machineid,ShiftProductionDetails.Componentid,ShiftProductionDetails.OperatorID,
Sum(ISNULL(ShiftProductionDetails.Prod_Qty,0))ProdCount,
Sum(ISNULL(ShiftProductionDetails.AcceptedParts,0))AcceptedParts,
Sum(ISNULL(ShiftProductionDetails.Marked_For_Rework,0)) as MarkedForRework,
Sum(ShiftProductionDetails.Sum_of_ActCycleTime)As UtilisedTime
From ShiftProductionDetails inner join
--(select distinct pdate,machineid,Shift,ComponentID from #Proddata) T1 on ShiftProductionDetails.pDate=T1.Pdate and ShiftProductionDetails.Shift=T1.Shift
(select distinct pdate,machineid,Shift,ComponentID,OperatorID from #Proddata) T1 on ShiftProductionDetails.pDate=T1.Pdate and ShiftProductionDetails.Shift=T1.Shift
--#Proddata T1 on ShiftProductionDetails.pDate=T1.Pdate and ShiftProductionDetails.Shift=T1.Shift AND 
and ShiftProductionDetails.Machineid=T1.Machineid and ShiftProductionDetails.Componentid=T1.Componentid  AND ShiftProductionDetails.OperatorID=T1.OperatorID '
Select @Strsql = @Strsql+ ' Where 1=1 '
Select @Strsql = @Strsql + @Strmachine + @StrShift + @StrPlant + @StrGroup
--Select @Strsql = @Strsql+ ' GROUP By ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.Machineid,ShiftProductionDetails.Componentid,ShiftProductionDetails.OperationNo '
--Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.pDate=T2.pDate And #ProdData.Shift=T2.Shift and #ProdData.Machineid=T2.Machineid and #ProdData.Componentid=T2.Componentid and #ProdData.OperationNo= T2.OperationNo '
Select @Strsql = @Strsql+ ' GROUP By ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.Machineid,ShiftProductionDetails.Componentid,ShiftProductionDetails.OperatorID '
Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.pDate=T2.pDate And #ProdData.Shift=T2.Shift and #ProdData.Machineid=T2.Machineid and #ProdData.Componentid=T2.Componentid  and #ProdData.OperatorID= T2.OperatorID  '
Print @Strsql
Exec(@Strsql)


--Updating UT for the selected Date-Machine
Select @Strsql=''
Select @Strsql = 'Update #ProdData Set UtilisedTime=ISNULL(T2.UtilisedTime,0)'
Select @Strsql = @Strsql+ ' From('
Select @Strsql = @Strsql+ ' Select ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.Machineid,ShiftProductionDetails.Componentid,ShiftProductionDetails.OperatorID,Sum(ShiftProductionDetails.Sum_of_ActCycleTime)As UtilisedTime
From ShiftProductionDetails inner join (select distinct pdate,shift,machineid,Componentid,OperatorID from #Proddata) T1 on ShiftProductionDetails.pDate=T1.Pdate and ShiftProductionDetails.Shift=T1.Shift
and ShiftProductionDetails.Machineid=T1.Machineid and ShiftProductionDetails.Componentid=T1.Componentid AND ShiftProductionDetails.OperatorID=T1.OperatorID '
Select @Strsql = @Strsql+ ' Where 1=1 '
Select @Strsql = @Strsql + @Strmachine + @StrShift + @StrPlant + @StrGroup
Select @Strsql = @Strsql+ ' GROUP By ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.Machineid,ShiftProductionDetails.Componentid,ShiftProductionDetails.OperatorID '
Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.pDate=T2.pDate And #ProdData.Shift=T2.Shift and #ProdData.Machineid=T2.Machineid and #ProdData.Componentid=T2.Componentid and #ProdData.OperatorID= T2.OperatorID  '
Print @Strsql
Exec(@Strsql)


--Updating Rejcount for the selected date-Shift-Machine-Component
Select @Strsql=''
Select @Strsql = 'UPDATE #ProdData SET RejCount=ISNULL(T2.Rej,0)'
Select @Strsql = @Strsql+' FROM('
--Select @Strsql = @Strsql+' Select ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.Machineid,ShiftProductionDetails.Componentid,ShiftProductionDetails.OperationNo,Sum(isnull(Rejection_Qty,0))Rej'
Select @Strsql = @Strsql+' Select ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.Machineid,ShiftProductionDetails.Componentid,ShiftProductionDetails.OperatorID,Sum(isnull(Rejection_Qty,0))Rej'
Select @Strsql = @Strsql+' From ShiftProductionDetails Left Outer Join ShiftRejectionDetails ON ShiftProductionDetails.ID=ShiftRejectionDetails.ID
inner join #Proddata T1 on ShiftProductionDetails.pDate=T1.Pdate and ShiftProductionDetails.Shift=T1.Shift
and ShiftProductionDetails.Machineid=T1.Machineid and ShiftProductionDetails.Componentid=T1.Componentid AND ShiftProductionDetails.OperatorID=T1.OperatorID '
Select @Strsql = @Strsql+' Where ShiftProductionDetails.pDate=T1.Pdate AND ShiftProductionDetails.Shift=T1.Shift AND ShiftProductionDetails.Machineid=T1.Machineid AND ShiftProductionDetails.Componentid=T1.Componentid 
 AND ShiftProductionDetails.OperatorID=T1.OperatorID '
Select @Strsql = @Strsql + @Strmachine + @StrShift + @StrPlant + @StrGroup
--Select @Strsql = @Strsql+' Group By ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.Machineid,ShiftProductionDetails.Componentid,ShiftProductionDetails.OperationNo '
--Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.pDate=T2.pDate And #ProdData.Shift=T2.Shift and #ProdData.Machineid=T2.Machineid and #ProdData.Componentid=T2.Componentid and #ProdData.OperationNo= T2.OperationNo '
Select @Strsql = @Strsql+' Group By ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.Machineid,ShiftProductionDetails.Componentid,ShiftProductionDetails.OperatorID '
Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.pDate=T2.pDate And #ProdData.Shift=T2.Shift and #ProdData.Machineid=T2.Machineid and #ProdData.Componentid=T2.Componentid and #ProdData.OperatorID=T2.OperatorID '
Print @Strsql
Exec(@Strsql)





                          

--Updating UT for the selected date-Machine
--Select @Strsql =''
--SELECT @StrSql='UPDATE #ProdData SET UtilisedTime = Isnull(#ProdData.UtilisedTime,0)+IsNull(T2.MinorDownTime,0) '
--SELECT @StrSql=@StrSql+'From (SELECT ShiftDownTimeDetails.dDate,ShiftDownTimeDetails.Machineid,
--sum(datediff(s,starttime,endtime)) as MinorDownTime '
--SELECT @StrSql=@StrSql+'FROM ShiftDownTimeDetails Inner Join (select distinct pdate,machineid from #Proddata) T1 ON ShiftDownTimeDetails.ddate=T1.pdate and ShiftDownTimeDetails.Machineid=T1.Machineid 
--WHERE downid in (select downid from downcodeinformation where prodeffy = 1) '
--Select @Strsql = @Strsql + @StrDmachine + @StrDShift + @StrDPlant + @StrDGroup
--SELECT @StrSql=@StrSql+'Group By ShiftDownTimeDetails.dDate,ShiftDownTimeDetails.Machineid '
--Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.pDate=T2.dDate and #ProdData.Machineid=T2.Machineid '
--print @StrSql
--EXEC(@StrSql)



--Updating DT for the selected date-Machine
Select @Strsql =''
Select @Strsql = 'UPDATE #ProdData SET DownTime = IsNull(T2.DownTime,0)'
Select @Strsql = @Strsql + ' From (select ShiftDownTimeDetails.dDate,ShiftDownTimeDetails.Shift,ShiftDownTimeDetails.Machineid,ShiftDownTimeDetails.Componentid,ShiftDownTimeDetails.OperatorID,( Sum(ShiftDownTimeDetails.DownTime) )As DownTime'
Select @Strsql = @Strsql + ' From ShiftDownTimeDetails
Inner Join (select distinct pdate,shift,machineid,Componentid,OperatorID from #Proddata) T1 ON ShiftDownTimeDetails.Machineid=T1.Machineid  and ShiftDownTimeDetails.ddate=T1.pdate and ShiftDownTimeDetails.Shift=T1.shift
and ShiftDownTimeDetails.Componentid=T1.Componentid AND ShiftDownTimeDetails.OperatorID=T1.OperatorID
where dDate=T1.Pdate and ShiftDownTimeDetails.Machineid=T1.Machineid AND ShiftDownTimeDetails.Shift=T1.shift and ShiftDownTimeDetails.Componentid=T1.Componentid AND ShiftDownTimeDetails.OperatorID=T1.OperatorID '
Select @Strsql = @Strsql + @StrDmachine + @StrDShift + @StrDPlant + @StrDGroup
Select @Strsql = @Strsql + ' Group By ShiftDownTimeDetails.dDate,ShiftDownTimeDetails.Shift,ShiftDownTimeDetails.Machineid,ShiftDownTimeDetails.Componentid,ShiftDownTimeDetails.OperatorID '
Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.pDate=T2.dDate AND #ProdData.Shift=T2.Shift and #ProdData.Machineid=T2.Machineid and #ProdData.Componentid=T2.Componentid and  #ProdData.OperatorID=T2.OperatorID '
Print @Strsql
Exec(@Strsql)



--Updating ML for the selected date-Machine
SELECT @Strsql=''
Select @Strsql = 'UPDATE #ProdData SET ManagementLoss = isNull(t2.loss,0)'
Select @Strsql = @Strsql + 'from (select ShiftDownTimeDetails.dDate,ShiftDownTimeDetails.Machineid,ShiftDownTimeDetails.shift,ShiftDownTimeDetails.Componentid,ShiftDownTimeDetails.OperatorID, sum(
CASE
WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0
THEN isnull(ShiftDownTimeDetails.Threshold,0)
ELSE ShiftDownTimeDetails.DownTime
END) AS LOSS '
Select @Strsql = @Strsql + ' From ShiftDownTimeDetails
Inner Join (select distinct pdate,shift,machineid,Componentid,OperatorID from #Proddata) T1 ON ShiftDownTimeDetails.Machineid=T1.Machineid and ShiftDownTimeDetails.ddate=T1.pdate and ShiftDownTimeDetails.Shift=T1.shift
and ShiftDownTimeDetails.Componentid=T1.Componentid AND  ShiftDownTimeDetails.OperatorID=T1.OperatorID
where dDate=T1.Pdate and ShiftDownTimeDetails.Machineid=T1.Machineid and ShiftDownTimeDetails.Shift=T1.shift
and ShiftDownTimeDetails.Componentid=T1.Componentid AND  ShiftDownTimeDetails.OperatorID=T1.OperatorID And ML_Flag=1 '
Select @Strsql = @Strsql + @StrDmachine + @StrDShift + @StrDPlant + @StrDGroup
Select @Strsql = @Strsql + ' Group By ShiftDownTimeDetails.dDate,ShiftDownTimeDetails.Machineid,ShiftDownTimeDetails.shift,ShiftDownTimeDetails.componentid,ShiftDownTimeDetails.operatorid '
Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.pDate=T2.dDate And #ProdData.Machineid=T2.Machineid and #ProdData.shift=T2.Shift and #ProdData.Componentid=T2.Componentid AND  #ProdData.OperatorID=T2.OperatorID  '
Print @Strsql
Exec(@Strsql)


Select @Strsql =''
Select @Strsql = 'UPDATE #ProdData SET DownPDT = IsNull(T2.PDT,0)'
Select @Strsql = @Strsql + ' From (select ShiftDownTimeDetails.dDate,ShiftDownTimeDetails.Shift,ShiftDownTimeDetails.Machineid,ShiftDownTimeDetails.Componentid,ShiftDownTimeDetails.OperatorID,( Sum(ShiftDownTimeDetails.PDT) )As PDT'
Select @Strsql = @Strsql + ' From ShiftDownTimeDetails
Inner Join (select distinct pdate,shift,machineid,Componentid,OperatorID from #Proddata) T1 ON ShiftDownTimeDetails.Machineid=T1.Machineid  and ShiftDownTimeDetails.ddate=T1.pdate and ShiftDownTimeDetails.Shift=T1.shift
and ShiftDownTimeDetails.Componentid=T1.Componentid AND ShiftDownTimeDetails.OperatorID=T1.OperatorID
where dDate=T1.Pdate and ShiftDownTimeDetails.Machineid=T1.Machineid AND ShiftDownTimeDetails.Shift=T1.shift and ShiftDownTimeDetails.Componentid=T1.Componentid AND ShiftDownTimeDetails.OperatorID=T1.OperatorID '
Select @Strsql = @Strsql + @StrDmachine + @StrDShift + @StrDPlant + @StrDGroup
Select @Strsql = @Strsql + ' Group By ShiftDownTimeDetails.dDate,ShiftDownTimeDetails.Shift,ShiftDownTimeDetails.Machineid,ShiftDownTimeDetails.Componentid,ShiftDownTimeDetails.OperatorID '
Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.pDate=T2.dDate AND #ProdData.Shift=T2.Shift and #ProdData.Machineid=T2.Machineid and #ProdData.Componentid=T2.Componentid and  #ProdData.OperatorID=T2.OperatorID '
Print @Strsql
Exec(@Strsql)

Select @Strsql=''
Select @Strsql = 'Update #ProdData Set ProductionPDT=ISNULL(T2.PDT,0)'
Select @Strsql = @Strsql+ ' From('
Select @Strsql = @Strsql+ ' Select ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.Machineid,ShiftProductionDetails.Componentid,ShiftProductionDetails.OperatorID,Sum(ShiftProductionDetails.PDT)As PDT
From ShiftProductionDetails inner join (select distinct pdate,shift,machineid,Componentid,OperatorID from #Proddata) T1 on ShiftProductionDetails.pDate=T1.Pdate and ShiftProductionDetails.Shift=T1.Shift
and ShiftProductionDetails.Machineid=T1.Machineid and ShiftProductionDetails.Componentid=T1.Componentid AND ShiftProductionDetails.OperatorID=T1.OperatorID '
Select @Strsql = @Strsql+ ' Where 1=1 '
Select @Strsql = @Strsql + @Strmachine + @StrShift + @StrPlant + @StrGroup
Select @Strsql = @Strsql+ ' GROUP By ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.Machineid,ShiftProductionDetails.Componentid,ShiftProductionDetails.OperatorID '
Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.pDate=T2.pDate And #ProdData.Shift=T2.Shift and #ProdData.Machineid=T2.Machineid and #ProdData.Componentid=T2.Componentid and #ProdData.OperatorID= T2.OperatorID  '
Print @Strsql
Exec(@Strsql)



--UPDATE #ProdData SET DownTime=DownTime-ManagementLoss








--UPDATE #ProdData SET QEffy=CAST((T1.AccepParts)As Float)/CAST((T1.AccepParts+T1.RejectCount+T1.MarkedForReworkCount) AS Float)
--from (SELECT Pdate, shift,Machineid,Componentid,operationno,operatorid,SUM(ISNULL(AcceptedParts,0)) as AccepParts, SUM(ISNULL(RejCount,0)) as RejectCount, SUM(ISNULL(MarkedForRework,0)) as MarkedForReworkCount  from 
--#ProdData
--Group by Pdate,shift, Machineid,componentid,operationno,operatorid
--)T1 inner join #ProdData T2 on T1.MachineID=T2.MachineID and T1.Pdate=T2.Pdate and T1.Shift=T2.Shift AND T1.ComponentID=T2.ComponentID AND T1.OperationNo=T2.OperationNo and T1.OperatorID=T2.OperatorID
--Where CAST((T1.AccepParts+T1.RejectCount+T1.MarkedForReworkCount) AS Float) <> 0


 
-- UPDATE #ProdData  
-- SET  
--  PEffy = (CN/UtilisedTime) ,  
--  AEffy = (UtilisedTime)/(UtilisedTime + ISNULL( DownTime,0))  
-- WHERE UtilisedTime <> 0 


--UPDATE #ProdData
--SET
--OEffy = ROUND((PEffy *AEffy *QEffy * 100),2),
--PEffy = Round((PEffy * 100),2),
--AEffy = ROUND((AEffy * 100),2),
--QEffy = ROUND((QEffy * 100),2)

update #ProdData set ScheduleTime= T1.scheduleTime
from (SELECT Pdate,Machineid,shift,componentid,operatorid,datediff(SECOND,Startdate,Enddate)as scheduleTime from #ProdData
Group by Pdate,Machineid,shift,componentid,operatorid,Startdate,Enddate
)T1 inner join #ProdData T2 on T1.MachineID=T2.MachineID and T1.Pdate=T2.Pdate and T1.Shift=t2.Shift and t1.ComponentID=t2.ComponentID and  t1.OperatorID=t2.OperatorID

-----------------------------------------------------------------------------------------------------    Planned DowTimes Calculation Begins  -------------------------------------------------------------------------------------------------------------------------------
UPDATE #ProdData SET Preventive = isnull(T1.Preventive,0)
from
(Select P.MachineID,Pdate,p.shift,p.componentid,p.operatorid, Sum(ShiftDownTimeDetails.DownTime) as Preventive from ShiftDownTimeDetails
inner join (select distinct MachineID,Pdate,shift,componentid,operatorid from #ProdData) P on P.MachineID=ShiftDownTimeDetails.MachineID and p.Pdate=ShiftDownTimeDetails.dDate and p.Shift=ShiftDownTimeDetails.Shift
and p.ComponentID=ShiftDownTimeDetails.ComponentID and p.OperatorID=ShiftDownTimeDetails.OperatorID
where P.MachineID=ShiftDownTimeDetails.MachineID and p.Pdate=ShiftDownTimeDetails.dDate and p.Shift=ShiftDownTimeDetails.Shift
and p.ComponentID=ShiftDownTimeDetails.ComponentID and p.OperatorID=ShiftDownTimeDetails.OperatorID and ShiftDownTimeDetails.DownCategory='Preventive maintenance'
group by P.MachineID,Pdate,p.Shift,p.ComponentID,p.OperatorID)T1
Inner Join #ProdData on T1.Machineid=#ProdData.Machineid and T1.Pdate=#ProdData.Pdate and t1.Shift=#ProdData.Shift and t1.ComponentID=#ProdData.ComponentID  and t1.OperatorID=#ProdData.OperatorID

--UPDATE #ProdData SET MCcleaning = isnull(T1.MCcleaning,0)
--from
--(Select  P.MachineID,Pdate,p.shift,p.componentid,p.operatorid, Sum(ShiftDownTimeDetails.DownTime) as MCcleaning from ShiftDownTimeDetails
--inner join (select distinct MachineID,Pdate,shift,componentid,operatorid from #ProdData) P on P.MachineID=ShiftDownTimeDetails.MachineID and p.Pdate=ShiftDownTimeDetails.dDate and p.Shift=ShiftDownTimeDetails.Shift
--and p.ComponentID=ShiftDownTimeDetails.ComponentID and  p.OperatorID=ShiftDownTimeDetails.OperatorID
--where P.MachineID=ShiftDownTimeDetails.MachineID and p.Pdate=ShiftDownTimeDetails.dDate and p.Shift=ShiftDownTimeDetails.Shift
--and p.ComponentID=ShiftDownTimeDetails.ComponentID and  p.OperatorID=ShiftDownTimeDetails.OperatorID and ShiftDownTimeDetails.DownID in('M/C cleaning','Lunch','Tea break')
--group by P.MachineID,Pdate,p.Shift,p.ComponentID,p.OperatorID)T1
--Inner Join #ProdData on T1.Machineid=#ProdData.Machineid and T1.Pdate=#ProdData.Pdate and t1.Shift=#ProdData.Shift and t1.ComponentID=#ProdData.ComponentID and  t1.OperatorID=#ProdData.OperatorID

UPDATE #ProdData SET NoPlan = isnull(T1.NoPlan,0)
from
(Select P.MachineID,Pdate,p.shift,p.componentid,p.operatorid, Sum(ShiftDownTimeDetails.DownTime) as NoPlan from ShiftDownTimeDetails
inner join (select distinct MachineID,Pdate,shift,componentid,operatorid from #ProdData) P on P.MachineID=ShiftDownTimeDetails.MachineID and p.Pdate=ShiftDownTimeDetails.dDate and p.Shift=ShiftDownTimeDetails.Shift
and p.ComponentID=ShiftDownTimeDetails.ComponentID and  p.OperatorID=ShiftDownTimeDetails.OperatorID
where P.MachineID=ShiftDownTimeDetails.MachineID and p.Pdate=ShiftDownTimeDetails.dDate and p.Shift=ShiftDownTimeDetails.Shift
and p.ComponentID=ShiftDownTimeDetails.ComponentID and  p.OperatorID=ShiftDownTimeDetails.OperatorID and ShiftDownTimeDetails.DownCategory = 'No plan'
group by P.MachineID,Pdate,p.Shift,p.ComponentID,p.OperatorID)T1
Inner Join #ProdData on T1.Machineid=#ProdData.Machineid and T1.Pdate=#ProdData.Pdate and t1.Shift=#ProdData.Shift and t1.ComponentID=#ProdData.ComponentID and  t1.OperatorID=#ProdData.OperatorID

-----------------------------------------------------------------------------------------------------   Planned DowTimes Calculation ends  -------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------   UnPlanned DowTimes Calculation Begins  -------------------------------------------------------------------------------------------------------------------------------


UPDATE #ProdData SET DueToLowHigh = isnull(T1.DueToLowHigh,0)
from
(Select  P.MachineID,Pdate,p.shift,p.componentid,p.operatorid,Sum(ShiftDownTimeDetails.DownTime) as DueToLowHigh from ShiftDownTimeDetails
inner join (select distinct MachineID,Pdate,shift,componentid,operatorid from #ProdData) P on P.MachineID=ShiftDownTimeDetails.MachineID and p.Pdate=ShiftDownTimeDetails.dDate and p.Shift=ShiftDownTimeDetails.Shift
and p.ComponentID=ShiftDownTimeDetails.ComponentID and  p.OperatorID=ShiftDownTimeDetails.OperatorID
where P.MachineID=ShiftDownTimeDetails.MachineID and p.Pdate=ShiftDownTimeDetails.dDate and p.Shift=ShiftDownTimeDetails.Shift
and p.ComponentID=ShiftDownTimeDetails.ComponentID and  p.OperatorID=ShiftDownTimeDetails.OperatorID and ShiftDownTimeDetails.DownCategory='Due to Men (for L&A high)'
group by P.MachineID,Pdate,p.Shift,p.ComponentID,p.OperatorID)T1
Inner Join #ProdData on T1.Machineid=#ProdData.Machineid and T1.Pdate=#ProdData.Pdate and t1.Shift=#ProdData.Shift and t1.ComponentID=#ProdData.ComponentID  and t1.OperatorID=#ProdData.OperatorID

UPDATE #ProdData SET DueToMachine = isnull(T1.DueToMachine,0)
from
(Select  P.MachineID,Pdate,p.shift,p.componentid,p.operatorid,Sum(ShiftDownTimeDetails.DownTime) as DueToMachine from ShiftDownTimeDetails
inner join (select distinct MachineID,Pdate,shift,componentid,operatorid from #ProdData) P on P.MachineID=ShiftDownTimeDetails.MachineID and p.Pdate=ShiftDownTimeDetails.dDate and p.Shift=ShiftDownTimeDetails.Shift
and p.ComponentID=ShiftDownTimeDetails.ComponentID and p.OperatorID=ShiftDownTimeDetails.OperatorID
where P.MachineID=ShiftDownTimeDetails.MachineID and p.Pdate=ShiftDownTimeDetails.dDate and p.Shift=ShiftDownTimeDetails.Shift
and p.ComponentID=ShiftDownTimeDetails.ComponentID and  p.OperatorID=ShiftDownTimeDetails.OperatorID and ShiftDownTimeDetails.DownCategory='Due To Machine'
group by P.MachineID,Pdate,p.Shift,p.ComponentID,p.OperatorID)T1
Inner Join #ProdData on T1.Machineid=#ProdData.Machineid and T1.Pdate=#ProdData.Pdate and t1.Shift=#ProdData.Shift and t1.ComponentID=#ProdData.ComponentID  and t1.OperatorID=#ProdData.OperatorID

UPDATE #ProdData SET DueToMethod = isnull(T1.DueToMethod,0)
from
(Select  P.MachineID,Pdate,p.shift,p.componentid,p.operatorid,Sum(ShiftDownTimeDetails.DownTime) as DueToMethod from ShiftDownTimeDetails
inner join (select distinct MachineID,Pdate,shift,componentid,operatorid from #ProdData) P on P.MachineID=ShiftDownTimeDetails.MachineID and p.Pdate=ShiftDownTimeDetails.dDate and p.Shift=ShiftDownTimeDetails.Shift
and p.ComponentID=ShiftDownTimeDetails.ComponentID and  p.OperatorID=ShiftDownTimeDetails.OperatorID
where P.MachineID=ShiftDownTimeDetails.MachineID and p.Pdate=ShiftDownTimeDetails.dDate and p.Shift=ShiftDownTimeDetails.Shift
and p.ComponentID=ShiftDownTimeDetails.ComponentID  and p.OperatorID=ShiftDownTimeDetails.OperatorID and ShiftDownTimeDetails.DownCategory='Due To Method'
group by P.MachineID,Pdate,p.Shift,p.ComponentID,p.OperatorID)T1
Inner Join #ProdData on T1.Machineid=#ProdData.Machineid and T1.Pdate=#ProdData.Pdate and t1.Shift=#ProdData.Shift and t1.ComponentID=#ProdData.ComponentID and t1.OperatorID=#ProdData.OperatorID

UPDATE #ProdData SET DueToMaterials = isnull(T1.DueToMaterials,0)
from
(Select  P.MachineID,Pdate,p.shift,p.componentid,p.operatorid,Sum(ShiftDownTimeDetails.DownTime) as DueToMaterials from ShiftDownTimeDetails
inner join (select distinct MachineID,Pdate,shift,componentid,operatorid from #ProdData) P on P.MachineID=ShiftDownTimeDetails.MachineID and p.Pdate=ShiftDownTimeDetails.dDate and p.Shift=ShiftDownTimeDetails.Shift
and p.ComponentID=ShiftDownTimeDetails.ComponentID and  p.OperatorID=ShiftDownTimeDetails.OperatorID
where P.MachineID=ShiftDownTimeDetails.MachineID and p.Pdate=ShiftDownTimeDetails.dDate and p.Shift=ShiftDownTimeDetails.Shift
and p.ComponentID=ShiftDownTimeDetails.ComponentID and  p.OperatorID=ShiftDownTimeDetails.OperatorID and ShiftDownTimeDetails.DownCategory='Due To Materials'
group by P.MachineID,Pdate,p.Shift,p.ComponentID,p.OperatorID)T1
Inner Join #ProdData on T1.Machineid=#ProdData.Machineid and T1.Pdate=#ProdData.Pdate and t1.Shift=#ProdData.Shift and t1.ComponentID=#ProdData.ComponentID and  t1.OperatorID=#ProdData.OperatorID

UPDATE #ProdData SET DueToMeasurement = isnull(T1.DueToMeasurement,0)
from
(Select  P.MachineID,Pdate,p.shift,p.componentid,p.operatorid,Sum(ShiftDownTimeDetails.DownTime) as DueToMeasurement from ShiftDownTimeDetails
inner join (select distinct MachineID,Pdate,shift,componentid,operatorid from #ProdData) P on P.MachineID=ShiftDownTimeDetails.MachineID and p.Pdate=ShiftDownTimeDetails.dDate and p.Shift=ShiftDownTimeDetails.Shift
and p.ComponentID=ShiftDownTimeDetails.ComponentID and  p.OperatorID=ShiftDownTimeDetails.OperatorID
where P.MachineID=ShiftDownTimeDetails.MachineID and p.Pdate=ShiftDownTimeDetails.dDate and p.Shift=ShiftDownTimeDetails.Shift
and p.ComponentID=ShiftDownTimeDetails.ComponentID and  p.OperatorID=ShiftDownTimeDetails.OperatorID and ShiftDownTimeDetails.DownCategory='Due To Measurement'
group by P.MachineID,Pdate,p.Shift,p.ComponentID,p.OperatorID)T1
Inner Join #ProdData on T1.Machineid=#ProdData.Machineid and T1.Pdate=#ProdData.Pdate and t1.Shift=#ProdData.Shift and t1.ComponentID=#ProdData.ComponentID  and t1.OperatorID=#ProdData.OperatorID

-----------------------------------------------------------------------------------------------------   UnPlanned DowTimes Calculation Ends  -------------------------------------------------------------------------------------------------------------------------------

--UPDATE #ProdData SET ProdDowntime = isnull(T1.ProdDowntime,0)
--from
--(Select P.MachineID,Pdate,Sum(ShiftDownTimeDetails.DownTime) as ProdDowntime from ShiftDownTimeDetails
--inner join (select distinct  MachineID,Pdate from #ProdData) P on P.MachineID=ShiftDownTimeDetails.MachineID
--where ShiftDownTimeDetails.dDate=P.Pdate and ShiftDownTimeDetails.DownCategory !='Breakdown'
--		and ShiftDownTimeDetails.DownID not in('Preventive maintenance','M/C cleaning','Lunch Break','No plan')
--group by P.MachineID,Pdate)T1
--Inner Join #ProdData on T1.Machineid=#ProdData.Machineid and T1.Pdate=#ProdData.Pdate





update #ProdData set TotalAT=isnull(t1.TotalAT,0)
FROM
(SELECT PDATE,SHIFT,Machineid,ComponentID,operatorid,(ISNULL(CAST(utilisedtime as float),0) + ISNULL(CAST(downtime as float),0)+ ISNULL(CAST(ProductionPDT as float),0)+ ISNULL(CAST(DownPDT as float),0) ) as TotalAT from #ProdData
)T1 INNER JOIN #ProdData T2 on T1.MachineID=T2.MachineID and T1.Pdate=T2.Pdate AND T1.Shift=T2.Shift AND T1.ComponentID=T2.ComponentID AND  T1.OperatorID=T2.OperatorID


update #ProdData set NetAT= ISNULL(T1.NetAT,0)
from (SELECT Pdate,Machineid,SHIFT,Componentid,operatorid, (ISNULL(CAST(TotalAT as float),0) - (ISNULL(CAST(Preventive as float),0) + ISNULL(CAST(NoPlan as float),0) + ISNULL(CAST(ProductionPDT as float),0)+ ISNULL(CAST(DownPDT as float),0) )) as NetAT from #ProdData
)T1 inner join #ProdData T2 on T1.MachineID=T2.MachineID and T1.Pdate=T2.Pdate and t1.Shift=t2.Shift and t1.ComponentID=t2.ComponentID and t1.OperatorID=t2.OperatorID


update #ProdData set NetOT= ISNULL(T1.NetOT,0)
from (SELECT Pdate,Machineid,SHIFT,Componentid,operatorid, (ISNULL(CAST(NetAT as float),0) - (ISNULL(CAST(DueToLowHigh as float),0) + ISNULL(CAST(DueToMachine as float),0) + ISNULL(CAST(DueToMethod as float),0) +ISNULL(CAST(DueToMaterials as float),0) + ISNULL(CAST(DueToMeasurement as float),0) )) as NetOT from #ProdData
)T1 inner join #ProdData T2 on T1.MachineID=T2.MachineID and T1.Pdate=T2.Pdate and t1.Shift=t2.Shift and t1.ComponentID=t2.ComponentID and  t1.OperatorID=t2.OperatorID



update #ProdData set Performance1= ISNULL(T1.Performance1,0)
from (SELECT Pdate,Machineid,SHIFT,Componentid,operatorid, (ISNULL(CAST(ProdCount as float),0) /( (ISNULL(CAST(NetOT as float),0) / ISNULL(CAST(StdCycleTime as float),0)))) as Performance1 from #ProdData where StdCycleTime>0 and NetOT>0
)T1 inner join #ProdData T2 on T1.MachineID=T2.MachineID and T1.Pdate=T2.Pdate and t1.Shift=t2.Shift and t1.ComponentID=t2.ComponentID  and t1.OperatorID=t2.OperatorID



update #ProdData set target= round(ISNULL(T1.Target,0),0)
from (SELECT Pdate,Machineid,SHIFT,Componentid,operatorid, (NetAT /StdCycleTime) as Target from #ProdData where StdCycleTime>0 
)T1 inner join #ProdData T2 on T1.MachineID=T2.MachineID and T1.Pdate=T2.Pdate and t1.Shift=t2.Shift and t1.ComponentID=t2.ComponentID and  t1.OperatorID=t2.OperatorID



update #ProdData set AEffy= ISNULL(T1.AEffy,0)
from (SELECT Pdate,Machineid,SHIFT,Componentid,operatorid, (NetOT /NetAT ) as AEffy from #ProdData where NetAT>0
)T1 inner join #ProdData T2 on T1.MachineID=T2.MachineID and T1.Pdate=T2.Pdate and t1.Shift=t2.Shift and t1.ComponentID=t2.ComponentID and t1.OperatorID=t2.OperatorID



UPDATE #ProdData SET PEffy=ISNULL(T1.PEffy,0)
FROM (SELECT Pdate,Machineid,SHIFT,Componentid,operatorid, (prodcount /target ) as PEffy from #ProdData where target>0
)T1 inner join #ProdData T2 on T1.MachineID=T2.MachineID and T1.Pdate=T2.Pdate and t1.Shift=t2.Shift and t1.ComponentID=t2.ComponentID and t1.OperatorID=t2.OperatorID


--UPDATE #ProdData SET QEffy=ISNULL(T1.QEffy,0)
--FROM (SELECT Pdate,Machineid,SHIFT,Componentid,operationno,operatorid, (AcceptedParts /ProdCount )*100 as QEffy from #ProdData
--)T1 inner join #ProdData T2 on T1.MachineID=T2.MachineID and T1.Pdate=T2.Pdate and t1.Shift=t2.Shift and t1.ComponentID=t2.ComponentID and t1.OperationNo=t2.OperationNo and t1.OperatorID=t2.OperatorID
--Where ProdCount  <> 0

UPDATE #ProdData SET QEffy=CAST((T1.AccepParts)As Float)/CAST((T1.AccepParts+T1.RejectCount+T1.MarkedForReworkCount) AS Float)
from (SELECT Pdate, shift,Machineid,Componentid,operatorid,SUM(ISNULL(AcceptedParts,0)) as AccepParts, SUM(ISNULL(RejCount,0)) as RejectCount, SUM(ISNULL(MarkedForRework,0)) as MarkedForReworkCount  from 
#ProdData
Group by Pdate,shift, Machineid,componentid,operatorid
)T1 inner join #ProdData T2 on T1.MachineID=T2.MachineID and T1.Pdate=T2.Pdate and T1.Shift=T2.Shift AND T1.ComponentID=T2.ComponentID and T1.OperatorID=T2.OperatorID
Where CAST((T1.AccepParts+T1.RejectCount+T1.MarkedForReworkCount) AS Float) <> 0

UPDATE #ProdData SET OperatorEfficiency=ISNULL(T1.OprEfficiency,0)
FROM (SELECT Pdate,Machineid,SHIFT,Componentid,operatorid, (Performance1 *QEffy ) as OprEfficiency from #ProdData
)T1 inner join #ProdData T2 on T1.MachineID=T2.MachineID and T1.Pdate=T2.Pdate and t1.Shift=t2.Shift and t1.ComponentID=t2.ComponentID  and t1.OperatorID=t2.OperatorID


UPDATE #ProdData
SET
OEffy = (PEffy *AEffy *QEffy)

select #machine.Pdate,#machine.MachineID,#machine.Shift,ISNULL(ComponentID,'') as ComponentID,ISNULL(OperatorID,'') as OperatorID,ISNULL(EmployeeName,'') as EmployeeName,
		dbo.f_FormatTime(StdCycleTime,'mm') as StdCycleTime,
		ISNULL(ProdCount,0) as ProdCount,
		ISNULL(AcceptedParts,0) AS OkPartQty,
		ISNULL(RejCount,0) as RejCount,
		dbo.f_FormatTime(Preventive,'mm') as Preventive,
		dbo.f_FormatTime(Productionpdt,'mm') as ProductionPDT,
		DBO.f_FormatTime(DownPDT,'mm') AS DownPDT,
		dbo.f_FormatTime(MCcleaning,'mm') as MCcleaning,
		dbo.f_FormatTime(NoPlan,'mm') as NoPlan,
		dbo.f_FormatTime(DueToLowHigh,'mm') as DueToLowHigh,
		dbo.f_FormatTime(DueToMachine,'mm') as DueToMachine,
		dbo.f_FormatTime(DueToMethod,'mm') as DueToMethod,
		dbo.f_FormatTime(DueToMaterials,'mm') as DueToMaterials,
		dbo.f_FormatTime(DueToMeasurement,'mm') as DueToMeasurement,
		dbo.f_FormatTime(TotalAT,'mm') as TotalAvailableTime,
		dbo.f_FormatTime(NetAT,'mm') as NetAT,
		dbo.f_FormatTime(NetOT,'mm') as NetOT,
		round(ISNULL(Target,0),0) AS Target,
	  round(isnull(performance1,0),2) as Performance1,
	round((isnull(AEffy,0))*100,0) as AEffy,round((isnull(PEffy,0))*100,0) as Performance,round((isnull(QEffy,0))*100,0) as QEffy,
	round((isnull(OEffy,0))*100,0) as OEffy,round((isnull(OperatorEfficiency,0))*100,0) as operatorefficiency
from #ProdData
Right outer join #machine on #ProdData.MachineID=#machine.MachineID and #ProdData.Pdate=#machine.Pdate and #ProdData.shift=#machine.shift
order by #machine.Pdate,#machine.MachineID,#machine.Shift


select T.pdate,'All Machines' as Machineid,T.Shift,ROUND(T.OkPartQty,0) as okpart, ROUND((T.AEFFY*100),0) AS AEffy,ROUND((T.PEFFY*100),0) AS Performance,ROUND((T.QEFFY*100),0) AS QEffy,ROUND((T.AEFFY*T.PEFFY*T.QEFFY*100),0) AS OEffy
FROM(
select #machine.Pdate,
#machine.Shift,(SUM(AcceptedParts)) AS OkPartQty,
CASE WHEN SUM(NETAT)<>0 THEN (SUM(netot)/sum(netat)) ELSE 0 END as AEFFY,
CASE WHEN SUM(Target)<>0 then (SUM(ProdCount)/sum(Target)) else 0 end as PEFFY,
case when sum(Prodcount)<>0 then (SUM(AcceptedParts)/SUM(ProdCount)) else 0 end AS QEFFY
from #ProdData Right outer join #machine on #ProdData.MachineID=#machine.MachineID and #ProdData.Pdate=#machine.Pdate and #ProdData.shift=#machine.shift
group by #machine.pdate, #machine.shift) T
ORDER BY pdate, Shift


select #machine.Pdate, isnull(sum(AcceptedParts),0) as TotalOkQty from #ProdData
Right outer join #machine on #ProdData.MachineID=#machine.MachineID and #ProdData.Pdate=#machine.Pdate and #ProdData.shift=#machine.shift
group by #machine.pdate
order by #machine.pdate 


--PEffy = Round((PEffy * 100),0),
--AEffy = ROUND((AEffy * 100),0),
--QEffy = ROUND((QEffy * 100),0),
--OperatorEfficiency=round((OperatorEfficiency*100),0)

--update #ProdData set IdelOT= ISNULL(T1.IdelOT,0)
--from (SELECT Pdate,Machineid, SUM(StdCycleTime*ProdCount) as IdelOT from #ProdData
--Group by Pdate,Machineid
--)T1 inner join #ProdData T2 on T1.MachineID=T2.MachineID and T1.Pdate=T2.Pdate

--update #ProdData set LostOT= ISNULL(T1.LostOT,0)
--from (SELECT Pdate,Machineid, SUM(StdCycleTime*RejCount) as LostOT from #ProdData
--Group by Pdate,Machineid
--)T1 inner join #ProdData T2 on T1.MachineID=T2.MachineID and T1.Pdate=T2.Pdate

--update #ProdData set RejCount= ISNULL(T1.Rejqty,0)
--from (SELECT Pdate,Machineid, SUM(RejCount) as Rejqty from #ProdData
--Group by Pdate,Machineid
--)T1 inner join #ProdData T2 on T1.MachineID=T2.MachineID and T1.Pdate=T2.Pdate


--select Pdate,MachineID,Shift,ComponentID,StdCycleTime,ProdCount,RejCount,dbo.f_FormatTime(ScheduleTime,'mm') as ScheduleTime,Preventive,MCcleaning,NoPlan,Breakdown,ProdDowntime,NetAT,NetOT,IdelOT,
--	LostOT,AEffy,PEffy,QEffy,OEffy
--from #ProdData order by Pdate,MachineID

--select #machine.Pdate,#machine.MachineID,#machine.Shift,ISNULL(ComponentID,'') as ComponentID,ISNULL(OperationNo,'') as OperationNo,

--select #machine.Pdate,#machine.MachineID,#machine.Shift,ISNULL(ComponentID,'') as ComponentID,ISNULL(OperationNo,'') as OperationNo,ISNULL(OperatorID,'') as OperatorID,ISNULL(EmployeeName,'') as EmployeeName,
--		dbo.f_FormatTime(StdCycleTime,'mm') as StdCycleTime,
--		ISNULL(ProdCount,0) as ProdCount,
--		ISNULL(AcceptedParts,0) AS OkPartQty,
--		ISNULL(RejCount,0) as RejCount,
--		dbo.f_FormatTime(Preventive,'mm') as Preventive,
--		dbo.f_FormatTime(MCcleaning,'mm') as MCcleaning,
--		dbo.f_FormatTime(NoPlan,'mm') as NoPlan,
--		dbo.f_FormatTime(DueToLowHigh,'mm') as DueToLowHigh,
--		dbo.f_FormatTime(DueToMachine,'mm') as DueToMachine,
--		dbo.f_FormatTime(DueToMethod,'mm') as DueToMethod,
--		dbo.f_FormatTime(DueToMaterials,'mm') as DueToMaterials,
--		dbo.f_FormatTime(DueToMeasurement,'mm') as DueToMeasurement,
--		dbo.f_FormatTime(TotalAT,'mm') as TotalAvailableTime,
--		--dbo.f_FormatTime(Breakdown,'mm') as Breakdown,
--		--dbo.f_FormatTime(ProdDowntime,'mm') as ProdDowntime,
--		dbo.f_FormatTime(NetAT,'mm') as NetAT,
--		dbo.f_FormatTime(NetOT,'mm') as NetOT,
--		ROUND(ISNULL(Target,0),1) AS Target,
--		--dbo.f_FormatTime(dbo.f_FormatTime(NetOT,'mm')/dbo.f_FormatTime(StdCycleTime,'mm'),'mm') as Target
--		--dbo.f_FormatTime(IdelOT,'mm') as IdelOT,
--	  --	isnull(LostOT,0) as LostOT,
--	isnull(AEffy,0) as AEffy,isnull(PEffy,0) as PEffy,isnull(QEffy,0) as QEffy,isnull(OEffy,0) as OEffy,round(isnull(performance1,0),2) as Performance1,isnull(operatorefficiency,0) as operatorefficiency
--from #ProdData
--Right outer join #machine on #ProdData.MachineID=#machine.MachineID and #ProdData.Pdate=#machine.Pdate and #ProdData.shift=#machine.shift
--order by #machine.Pdate,#machine.MachineID,#machine.Shift

--select T.pdate,'All Machines' as Machineid,T.shift,sum(T.OkPartQty) as okpart,round(avg(T.Performance),0) AS Performance, round(avg(t.AEffy),0) as AEffy,round(avg(t.QEffy),0) as QEffy ,round(avg(t.OEffy),0) as OEffy
--from
--(
--select #machine.Pdate,#machine.MachineID,#machine.Shift,ISNULL(ComponentID,'') as ComponentID,ISNULL(OperatorID,'') as OperatorID,ISNULL(EmployeeName,'') as EmployeeName,
--		dbo.f_FormatTime(StdCycleTime,'mm') as StdCycleTime,
--		ISNULL(ProdCount,0) as ProdCount,
--		ISNULL(AcceptedParts,0) AS OkPartQty,
--		ISNULL(RejCount,0) as RejCount,
--		dbo.f_FormatTime(Preventive,'mm') as Preventive,
--		dbo.f_FormatTime(MCcleaning,'mm') as MCcleaning,
--		dbo.f_FormatTime(NoPlan,'mm') as NoPlan,
--		dbo.f_FormatTime(DueToLowHigh,'mm') as DueToLowHigh,
--		dbo.f_FormatTime(DueToMachine,'mm') as DueToMachine,
--		dbo.f_FormatTime(DueToMethod,'mm') as DueToMethod,
--		dbo.f_FormatTime(DueToMaterials,'mm') as DueToMaterials,
--		dbo.f_FormatTime(DueToMeasurement,'mm') as DueToMeasurement,
--		dbo.f_FormatTime(TotalAT,'mm') as TotalAvailableTime,
--		--dbo.f_FormatTime(Breakdown,'mm') as Breakdown,
--		--dbo.f_FormatTime(ProdDowntime,'mm') as ProdDowntime,
--		dbo.f_FormatTime(NetAT,'mm') as NetAT,
--		dbo.f_FormatTime(NetOT,'mm') as NetOT,
--		round(ISNULL(Target,0),0) AS Target,
--		--dbo.f_FormatTime(dbo.f_FormatTime(NetOT,'mm')/dbo.f_FormatTime(StdCycleTime,'mm'),'mm') as Target
--		--dbo.f_FormatTime(IdelOT,'mm') as IdelOT,
--	  --	isnull(LostOT,0) as LostOT,
--	isnull(AEffy,0) as AEffy,isnull(PEffy,0) as Performance,isnull(QEffy,0) as QEffy,isnull(OEffy,0) as OEffy,round(isnull(performance1,0),2) as Performance1,isnull(operatorefficiency,0) as operatorefficiency
--from #ProdData
--Right outer join #machine on #ProdData.MachineID=#machine.MachineID and #ProdData.Pdate=#machine.Pdate and #ProdData.shift=#machine.shift
----order by #machine.Pdate,#machine.MachineID,#machine.Shift

--)T
--GROUP BY pdate, SHIFT
--ORDER BY pdate, Shift



END
