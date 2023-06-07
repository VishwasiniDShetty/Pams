/****** Object:  Procedure [dbo].[s_GetAggOEEReport_Kiswok]    Committed by VersionSQL https://www.versionsql.com ******/

/*

[dbo].[s_GetAggOEEReport_Kiswok] '2020-07-09','2020-07-09','','','','SHOP 2',''
[dbo].[s_GetAggOEEReport_Kiswok] '2020-08-09','2020-08-09','','KI/VMC-19',''
[dbo].[s_GetAggOEEReport_Kiswok] '2020-08-09','2020-08-09','','KI/VMC-22',''
[dbo].[s_GetAggOEEReport_Kiswok] '2020-11-09','2020-11-09','','KI/HMC-03',''
[dbo].[s_GetAggOEEReport_Kiswok] '2021-07-02','2021-07-02','','',''

*/
CREATE PROCEDURE [dbo].[s_GetAggOEEReport_Kiswok]
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
Select @StrShift = ' And ( #ShiftDetails.Shift = N''' + @ShiftName + ''')'
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
ProdCount Int default 0,
AcceptedParts Int default 0,
RejCount Int default 0,
Pdate DateTime,
Startdate DateTime,
Enddate DateTime,
ScheduleTime nvarchar(50) default 0,
Preventive nvarchar(50) default 0,
MCcleaning nvarchar(50) default 0,
NoPlan nvarchar(50) default 0,
Breakdown nvarchar(50) default 0,
ProdDowntime nvarchar(50) default 0,
NetAT nvarchar(50) default 0,
NetOT nvarchar(50) default 0,
IdelOT nvarchar(50) default 0,
LostOT nvarchar(50) default 0,
MarkedForRework Int,
AEffy Float,
PEffy Float,
QEffy Float,
OEffy Float,
UtilisedTime Float,
DownTime Float,
ManagementLoss Float,
DownTimeAE Float,
CN Float
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

Select @Strsql=''
SELECT @StrSql='INSERT INTO #ProdData(MachineID,Shift,ComponentID,OperatorID,EmployeeName,Pdate,OperationNo,Startdate,Enddate,Stdcycletime)
SELECT Distinct S.Machineid,S.Shift,ShiftProductionDetails.Componentid,ShiftProductionDetails.OperatorID,E.Name as EmployeeName,S.Pdate, ShiftProductionDetails.OperationNo, S.Startdate, S.Enddate,(CO_StdMachiningTime+CO_StdLoadUnload) from #machine S
inner join ShiftProductionDetails on S.Machineid=ShiftProductionDetails.Machineid
and S.Pdate=ShiftProductionDetails.Pdate and S.Shift=ShiftProductionDetails.shift
inner join employeeinformation E ON E.Employeeid=ShiftProductionDetails.Operatorid
Where 1=1 '
SELECT @StrSql=@StrSql+ @Strmachine + @StrShift + @StrPlant + @StrGroup
Print @StrSql
EXEC(@StrSql)

--Updating ProdCount,AcceptedParts,MarkedForRework,ReworkPerformed for the selected date-Shift-Machine-Component
Select @Strsql=''
Select @Strsql = 'Update #ProdData Set ProdCount=ISNULL(T2.ProdCount,0),AcceptedParts=ISNULL(T2.AcceptedParts,0),MarkedForRework=ISNULL(T2.MarkedForRework,0)'
Select @Strsql = @Strsql+ ' From('
--Select @Strsql = @Strsql+ ' Select ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.Machineid,ShiftProductionDetails.Componentid,ShiftProductionDetails.OperationNo
Select @Strsql = @Strsql+ ' Select ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.Machineid,ShiftProductionDetails.Componentid,ShiftProductionDetails.OperationNo,ShiftProductionDetails.OperatorID,
Sum(ISNULL(ShiftProductionDetails.Prod_Qty,0))ProdCount,
Sum(ISNULL(ShiftProductionDetails.AcceptedParts,0))AcceptedParts,
Sum(ISNULL(ShiftProductionDetails.Marked_For_Rework,0)) as MarkedForRework,
Sum(ShiftProductionDetails.Sum_of_ActCycleTime)As UtilisedTime
From ShiftProductionDetails inner join
--(select distinct pdate,machineid,Shift,ComponentID from #Proddata) T1 on ShiftProductionDetails.pDate=T1.Pdate and ShiftProductionDetails.Shift=T1.Shift
(select distinct pdate,machineid,Shift,ComponentID,OperatorID from #Proddata) T1 on ShiftProductionDetails.pDate=T1.Pdate and ShiftProductionDetails.Shift=T1.Shift
--#Proddata T1 on ShiftProductionDetails.pDate=T1.Pdate and ShiftProductionDetails.Shift=T1.Shift AND 
and ShiftProductionDetails.Machineid=T1.Machineid and ShiftProductionDetails.Componentid=T1.Componentid AND ShiftProductionDetails.OperatorID=T1.OperatorID '
Select @Strsql = @Strsql+ ' Where 1=1 '
Select @Strsql = @Strsql + @Strmachine + @StrShift + @StrPlant + @StrGroup
--Select @Strsql = @Strsql+ ' GROUP By ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.Machineid,ShiftProductionDetails.Componentid,ShiftProductionDetails.OperationNo '
--Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.pDate=T2.pDate And #ProdData.Shift=T2.Shift and #ProdData.Machineid=T2.Machineid and #ProdData.Componentid=T2.Componentid and #ProdData.OperationNo= T2.OperationNo '
Select @Strsql = @Strsql+ ' GROUP By ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.Machineid,ShiftProductionDetails.Componentid,ShiftProductionDetails.OperationNo,ShiftProductionDetails.OperatorID '
Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.pDate=T2.pDate And #ProdData.Shift=T2.Shift and #ProdData.Machineid=T2.Machineid and #ProdData.Componentid=T2.Componentid and #ProdData.OperationNo= T2.OperationNo and #ProdData.OperatorID= T2.OperatorID  '
Print @Strsql
Exec(@Strsql)


--Updating UT for the selected Date-Machine
Select @Strsql=''
Select @Strsql = 'Update #ProdData Set UtilisedTime=ISNULL(T2.UtilisedTime,0)'
Select @Strsql = @Strsql+ ' From('
Select @Strsql = @Strsql+ ' Select ShiftProductionDetails.pDate,ShiftProductionDetails.Machineid,Sum(ShiftProductionDetails.Sum_of_ActCycleTime)As UtilisedTime
From ShiftProductionDetails inner join (select distinct pdate,machineid from #Proddata) T1 on ShiftProductionDetails.pDate=T1.Pdate and ShiftProductionDetails.Machineid=T1.Machineid '
Select @Strsql = @Strsql+ ' Where 1=1 '
Select @Strsql = @Strsql + @Strmachine + @StrShift + @StrPlant + @StrGroup
Select @Strsql = @Strsql+ ' GROUP By ShiftProductionDetails.pDate,ShiftProductionDetails.Machineid '
Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.pDate=T2.pDate and #ProdData.Machineid=T2.Machineid '
Print @Strsql
Exec(@Strsql)

--Updating Rejcount for the selected date-Shift-Machine-Component
Select @Strsql=''
Select @Strsql = 'UPDATE #ProdData SET RejCount=ISNULL(T2.Rej,0)'
Select @Strsql = @Strsql+' FROM('
--Select @Strsql = @Strsql+' Select ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.Machineid,ShiftProductionDetails.Componentid,ShiftProductionDetails.OperationNo,Sum(isnull(Rejection_Qty,0))Rej'
Select @Strsql = @Strsql+' Select ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.Machineid,ShiftProductionDetails.Componentid,ShiftProductionDetails.OperationNo,ShiftProductionDetails.OperatorID,Sum(isnull(Rejection_Qty,0))Rej'
Select @Strsql = @Strsql+' From ShiftProductionDetails Left Outer Join ShiftRejectionDetails ON ShiftProductionDetails.ID=ShiftRejectionDetails.ID
inner join #Proddata T1 on ShiftProductionDetails.pDate=T1.Pdate and ShiftProductionDetails.Shift=T1.Shift
and ShiftProductionDetails.Machineid=T1.Machineid and ShiftProductionDetails.Componentid=T1.Componentid AND ShiftProductionDetails.OperatorID=T1.OperatorID '
Select @Strsql = @Strsql+' Where ShiftProductionDetails.pDate=T1.Pdate '
Select @Strsql = @Strsql + @Strmachine + @StrShift + @StrPlant + @StrGroup
--Select @Strsql = @Strsql+' Group By ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.Machineid,ShiftProductionDetails.Componentid,ShiftProductionDetails.OperationNo '
--Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.pDate=T2.pDate And #ProdData.Shift=T2.Shift and #ProdData.Machineid=T2.Machineid and #ProdData.Componentid=T2.Componentid and #ProdData.OperationNo= T2.OperationNo '
Select @Strsql = @Strsql+' Group By ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.Machineid,ShiftProductionDetails.Componentid,ShiftProductionDetails.OperationNo,ShiftProductionDetails.OperatorID '
Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.pDate=T2.pDate And #ProdData.Shift=T2.Shift and #ProdData.Machineid=T2.Machineid and #ProdData.Componentid=T2.Componentid and #ProdData.OperationNo= T2.OperationNo AND #ProdData.OperatorID=T2.OperatorID '
Print @Strsql
Exec(@Strsql)

--Updating CN for the selected date-Machine
Select @Strsql=''
Select @Strsql = 'Update #ProdData Set CN=ISNULL(T2.CN,0)'
Select @Strsql = @Strsql + ' From ('
Select @Strsql = @Strsql + ' Select ShiftProductionDetails.pDate,ShiftProductionDetails.Machineid,sum(ShiftProductionDetails.Prod_Qty *(CO_StdMachiningTime+CO_StdLoadUnload)) AS CN '
Select @Strsql = @Strsql + ' From ShiftProductionDetails inner join (select distinct pdate,machineid from #Proddata) T1 on ShiftProductionDetails.pDate=T1.Pdate and ShiftProductionDetails.Machineid=T1.Machineid '
Select @Strsql = @Strsql + ' Where ShiftProductionDetails.pDate=T1.Pdate '
Select @Strsql = @Strsql + @Strmachine + @StrShift + @StrPlant + @StrGroup
Select @Strsql = @Strsql + ' Group By ShiftProductionDetails.pDate,ShiftProductionDetails.Machineid '
Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.pDate=T2.pDate and #ProdData.Machineid=T2.Machineid '
Print @Strsql
Exec(@Strsql)

--Updating UT for the selected date-Machine
Select @Strsql =''
SELECT @StrSql='UPDATE #ProdData SET UtilisedTime = Isnull(#ProdData.UtilisedTime,0)+IsNull(T2.MinorDownTime,0) '
SELECT @StrSql=@StrSql+'From (SELECT ShiftDownTimeDetails.dDate,ShiftDownTimeDetails.Machineid,
sum(datediff(s,starttime,endtime)) as MinorDownTime '
SELECT @StrSql=@StrSql+'FROM ShiftDownTimeDetails Inner Join (select distinct pdate,machineid from #Proddata) T1 ON ShiftDownTimeDetails.ddate=T1.pdate and ShiftDownTimeDetails.Machineid=T1.Machineid 
WHERE downid in (select downid from downcodeinformation where prodeffy = 1) '
Select @Strsql = @Strsql + @StrDmachine + @StrDShift + @StrDPlant + @StrDGroup
SELECT @StrSql=@StrSql+'Group By ShiftDownTimeDetails.dDate,ShiftDownTimeDetails.Machineid '
Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.pDate=T2.dDate and #ProdData.Machineid=T2.Machineid '
print @StrSql
EXEC(@StrSql)

--Updating DT for the selected date-Machine
Select @Strsql =''
Select @Strsql = 'UPDATE #ProdData SET DownTime = IsNull(T2.DownTime,0)'
Select @Strsql = @Strsql + ' From (select ShiftDownTimeDetails.dDate,ShiftDownTimeDetails.Machineid,( Sum(ShiftDownTimeDetails.DownTime) )As DownTime'
Select @Strsql = @Strsql + ' From ShiftDownTimeDetails
Inner Join (select distinct pdate,machineid from #Proddata) T1 ON ShiftDownTimeDetails.Machineid=T1.Machineid  and ShiftDownTimeDetails.ddate=T1.pdate
where dDate=T1.Pdate '
Select @Strsql = @Strsql + @StrDmachine + @StrDShift + @StrDPlant + @StrDGroup
Select @Strsql = @Strsql + ' Group By ShiftDownTimeDetails.dDate,ShiftDownTimeDetails.Machineid '
Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.pDate=T2.dDate and #ProdData.Machineid=T2.Machineid '
Print @Strsql
Exec(@Strsql)

--Updating ML for the selected date-Machine
SELECT @Strsql=''
Select @Strsql = 'UPDATE #ProdData SET ManagementLoss = isNull(t2.loss,0)'
Select @Strsql = @Strsql + 'from (select ShiftDownTimeDetails.dDate,ShiftDownTimeDetails.Machineid,sum(
CASE
WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0
THEN isnull(ShiftDownTimeDetails.Threshold,0)
ELSE ShiftDownTimeDetails.DownTime
END) AS LOSS '
Select @Strsql = @Strsql + ' From ShiftDownTimeDetails
Inner Join (select distinct pdate,machineid from #Proddata) T1 ON ShiftDownTimeDetails.Machineid=T1.Machineid and ShiftDownTimeDetails.ddate=T1.pdate
where dDate=T1.Pdate And ML_Flag=1 '
Select @Strsql = @Strsql + @StrDmachine + @StrDShift + @StrDPlant + @StrDGroup
Select @Strsql = @Strsql + ' Group By ShiftDownTimeDetails.dDate,ShiftDownTimeDetails.Machineid '
Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.pDate=T2.dDate And #ProdData.Machineid=T2.Machineid '
Print @Strsql
Exec(@Strsql)


UPDATE #ProdData SET DownTime=DownTime-ManagementLoss


UPDATE #ProdData SET QEffy=CAST((T1.AccepParts)As Float)/CAST((T1.AccepParts+T1.RejectCount+T1.MarkedForReworkCount) AS Float)
from (SELECT Pdate,Machineid, SUM(ISNULL(AcceptedParts,0)) as AccepParts, SUM(ISNULL(RejCount,0)) as RejectCount, SUM(ISNULL(MarkedForRework,0)) as MarkedForReworkCount  from 
#ProdData
Group by Pdate,Machineid
)T1 inner join #ProdData T2 on T1.MachineID=T2.MachineID and T1.Pdate=T2.Pdate
Where CAST((T1.AccepParts+T1.RejectCount+T1.MarkedForReworkCount) AS Float) <> 0


 
 UPDATE #ProdData  
 SET  
  PEffy = (CN/UtilisedTime) ,  
  AEffy = (UtilisedTime)/(UtilisedTime + ISNULL( DownTime,0))  
 WHERE UtilisedTime <> 0 


UPDATE #ProdData
SET
OEffy = ROUND((PEffy *AEffy *QEffy * 100),2),
PEffy = Round((PEffy * 100),2),
AEffy = ROUND((AEffy * 100),2),
QEffy = ROUND((QEffy * 100),2)

update #ProdData set ScheduleTime= T1.scheduleTime
from (SELECT Pdate,Machineid, datediff(SECOND,Pdate,Pdate+1)as scheduleTime from #ProdData
Group by Pdate,Machineid
)T1 inner join #ProdData T2 on T1.MachineID=T2.MachineID and T1.Pdate=T2.Pdate


UPDATE #ProdData SET Preventive = isnull(T1.Preventive,0)
from
(Select P.MachineID,Pdate, Sum(ShiftDownTimeDetails.DownTime) as Preventive from ShiftDownTimeDetails
inner join (select distinct  MachineID,Pdate from #ProdData) P on P.MachineID=ShiftDownTimeDetails.MachineID
where ShiftDownTimeDetails.dDate=P.Pdate and ShiftDownTimeDetails.DownID='Preventive maintenance'
group by P.MachineID,Pdate)T1
Inner Join #ProdData on T1.Machineid=#ProdData.Machineid and T1.Pdate=#ProdData.Pdate

UPDATE #ProdData SET MCcleaning = isnull(T1.MCcleaning,0)
from
(Select  P.MachineID,Pdate, Sum(ShiftDownTimeDetails.DownTime) as MCcleaning from ShiftDownTimeDetails
inner join (select distinct  MachineID,Pdate from #ProdData) P on P.MachineID=ShiftDownTimeDetails.MachineID
where ShiftDownTimeDetails.dDate=P.Pdate and ShiftDownTimeDetails.DownID in('M/C cleaning','Lunch')
group by P.MachineID,Pdate)T1
Inner Join #ProdData on T1.Machineid=#ProdData.Machineid and T1.Pdate=#ProdData.Pdate

UPDATE #ProdData SET NoPlan = isnull(T1.NoPlan,0)
from
(Select P.MachineID,Pdate, Sum(ShiftDownTimeDetails.DownTime) as NoPlan from ShiftDownTimeDetails
inner join (select distinct  MachineID,Pdate from #ProdData) P on P.MachineID=ShiftDownTimeDetails.MachineID
where ShiftDownTimeDetails.dDate=P.Pdate and ShiftDownTimeDetails.DownID = 'No plan'
group by P.MachineID,Pdate)T1
Inner Join #ProdData on T1.Machineid=#ProdData.Machineid and T1.Pdate=#ProdData.Pdate

UPDATE #ProdData SET Breakdown = isnull(T1.Breakdown,0)
from
(Select  P.MachineID,Pdate, Sum(ShiftDownTimeDetails.DownTime) as Breakdown from ShiftDownTimeDetails
inner join (select distinct  MachineID,Pdate from #ProdData) P on P.MachineID=ShiftDownTimeDetails.MachineID
where ShiftDownTimeDetails.dDate=P.Pdate and ShiftDownTimeDetails.DownCategory='Breakdown'
group by P.MachineID,Pdate)T1
Inner Join #ProdData on T1.Machineid=#ProdData.Machineid and T1.Pdate=#ProdData.Pdate


UPDATE #ProdData SET ProdDowntime = isnull(T1.ProdDowntime,0)
from
(Select P.MachineID,Pdate,Sum(ShiftDownTimeDetails.DownTime) as ProdDowntime from ShiftDownTimeDetails
inner join (select distinct  MachineID,Pdate from #ProdData) P on P.MachineID=ShiftDownTimeDetails.MachineID
where ShiftDownTimeDetails.dDate=P.Pdate and ShiftDownTimeDetails.DownCategory !='Breakdown'
		and ShiftDownTimeDetails.DownID not in('Preventive maintenance','M/C cleaning','Lunch Break','No plan')
group by P.MachineID,Pdate)T1
Inner Join #ProdData on T1.Machineid=#ProdData.Machineid and T1.Pdate=#ProdData.Pdate

update #ProdData set NetAT= ISNULL(T1.NetAT,0)
from (SELECT Pdate,Machineid, (ISNULL(CAST(ScheduleTime as float),0) - ISNULL(CAST(Preventive as float),0) - ISNULL(CAST(MCcleaning as float),0)) as NetAT from #ProdData
)T1 inner join #ProdData T2 on T1.MachineID=T2.MachineID and T1.Pdate=T2.Pdate

update #ProdData set NetOT= ISNULL(T1.NetOT,0)
from (SELECT Pdate,Machineid, (ISNULL(CAST(NetAT as float),0) - ISNULL(CAST(ProdDowntime as float),0) - ISNULL(CAST(NoPlan as float),0) - ISNULL(CAST(Breakdown as float),0)) as NetOT from #ProdData
)T1 inner join #ProdData T2 on T1.MachineID=T2.MachineID and T1.Pdate=T2.Pdate


update #ProdData set IdelOT= ISNULL(T1.IdelOT,0)
from (SELECT Pdate,Machineid, SUM(StdCycleTime*ProdCount) as IdelOT from #ProdData
Group by Pdate,Machineid
)T1 inner join #ProdData T2 on T1.MachineID=T2.MachineID and T1.Pdate=T2.Pdate

update #ProdData set LostOT= ISNULL(T1.LostOT,0)
from (SELECT Pdate,Machineid, SUM(StdCycleTime*RejCount) as LostOT from #ProdData
Group by Pdate,Machineid
)T1 inner join #ProdData T2 on T1.MachineID=T2.MachineID and T1.Pdate=T2.Pdate

update #ProdData set RejCount= ISNULL(T1.Rejqty,0)
from (SELECT Pdate,Machineid, SUM(RejCount) as Rejqty from #ProdData
Group by Pdate,Machineid
)T1 inner join #ProdData T2 on T1.MachineID=T2.MachineID and T1.Pdate=T2.Pdate


--select Pdate,MachineID,Shift,ComponentID,StdCycleTime,ProdCount,RejCount,dbo.f_FormatTime(ScheduleTime,'mm') as ScheduleTime,Preventive,MCcleaning,NoPlan,Breakdown,ProdDowntime,NetAT,NetOT,IdelOT,
--	LostOT,AEffy,PEffy,QEffy,OEffy
--from #ProdData order by Pdate,MachineID

--select #machine.Pdate,#machine.MachineID,#machine.Shift,ISNULL(ComponentID,'') as ComponentID,ISNULL(OperationNo,'') as OperationNo,

--select #machine.Pdate,#machine.MachineID,#machine.Shift,ISNULL(ComponentID,'') as ComponentID,ISNULL(OperationNo,'') as OperationNo,ISNULL(OperatorID,'') as OperatorID,ISNULL(EmployeeName,'') as EmployeeName,
--		dbo.f_FormatTime(StdCycleTime,'mm') as StdCycleTime,
--		ISNULL(ProdCount,0) as ProdCount,ISNULL(RejCount,0) as RejCount,
--		dbo.f_FormatTime(ScheduleTime,'mm') as ScheduleTime,
--		dbo.f_FormatTime(Preventive,'mm') as Preventive,
--		dbo.f_FormatTime(MCcleaning,'mm') as MCcleaning,
--		dbo.f_FormatTime(NoPlan,'mm') as NoPlan,
--		dbo.f_FormatTime(Breakdown,'mm') as Breakdown,
--		dbo.f_FormatTime(ProdDowntime,'mm') as ProdDowntime,
--		dbo.f_FormatTime(NetAT,'mm') as NetAT,
--		dbo.f_FormatTime(NetOT,'mm') as NetOT,
--		dbo.f_FormatTime(IdelOT,'mm') as IdelOT,
--	isnull(LostOT,0) as LostOT,isnull(AEffy,0) as AEffy,isnull(PEffy,0) as PEffy,isnull(QEffy,0) as QEffy,isnull(OEffy,0) as OEffy
--from #ProdData
--Right outer join #machine on #ProdData.MachineID=#machine.MachineID and #ProdData.Pdate=#machine.Pdate and #ProdData.shift=#machine.shift
--order by #machine.Pdate,#machine.MachineID,#machine.Shift


select #machine.Pdate,#machine.MachineID,#machine.Shift,ISNULL(ComponentID,'') as ComponentID,ISNULL(OperationNo,'') as OperationNo,ISNULL(OperatorID,'') as OperatorID,ISNULL(EmployeeName,'') as EmployeeName,
		dbo.f_FormatTime(StdCycleTime,'ss') as StdCycleTimeinsec,
		dbo.f_FormatTime(StdCycleTime,@timeformat) as StdCycleTime,
		ISNULL(ProdCount,0) as ProdCount,
		ISNULL(RejCount,0) as RejCount,
		dbo.f_FormatTime(ScheduleTime,'ss') as ScheduleTimeinsec,
		dbo.f_FormatTime(ScheduleTime,@timeformat) as ScheduleTime,
		dbo.f_FormatTime(Preventive,'ss') as Preventiveinsec,
		dbo.f_FormatTime(Preventive,@timeformat) as Preventive,
		dbo.f_FormatTime(MCcleaning,'ss') as MCcleaninginsec,
		dbo.f_FormatTime(MCcleaning,@timeformat) as MCcleaning,
		dbo.f_FormatTime(NoPlan,'ss') as NoPlaninsec,
		dbo.f_FormatTime(NoPlan,@timeformat) as NoPlan,
		dbo.f_FormatTime(Breakdown,'ss') as Breakdowninsec,
		dbo.f_FormatTime(Breakdown,@timeformat) as Breakdown,
		dbo.f_FormatTime(ProdDowntime,'ss') as ProdDowntimeinsec,
		dbo.f_FormatTime(ProdDowntime,@timeformat) as ProdDowntime,
		dbo.f_FormatTime(NetAT,'ss') as NetATinsec,
		dbo.f_FormatTime(NetAT,@timeformat) as NetAT,
		dbo.f_FormatTime(NetOT,'ss') as NetOTinsec,
		dbo.f_FormatTime(NetOT,@timeformat) as NetOT,
		dbo.f_FormatTime(IdelOT,'ss') as IdelOTinsec,
		dbo.f_FormatTime(IdelOT,@timeformat) as IdelOT,
		dbo.f_FormatTime(isnull(LostOT,0),'ss') as LostOTinsec,
		dbo.f_FormatTime(isnull(LostOT,0),@timeformat) as LostOT,
	isnull(AEffy,0) as AEffy,isnull(PEffy,0) as PEffy,isnull(QEffy,0) as QEffy,isnull(OEffy,0) as OEffy
from #ProdData
Right outer join #machine on #ProdData.MachineID=#machine.MachineID and #ProdData.Pdate=#machine.Pdate and #ProdData.shift=#machine.shift
order by #machine.Pdate,#machine.MachineID,#machine.Shift


END
