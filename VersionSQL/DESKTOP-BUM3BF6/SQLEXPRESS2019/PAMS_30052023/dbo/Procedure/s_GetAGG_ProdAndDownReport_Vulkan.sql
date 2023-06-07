/****** Object:  Procedure [dbo].[s_GetAGG_ProdAndDownReport_Vulkan]    Committed by VersionSQL https://www.versionsql.com ******/

/*
ER0501:SwathiKS:09/Mar/2021::New Procedure For VULKAN on Aggregated data to get Prod and Down Report on Date-Shift-Machine-Component-Operator-Workorder Level
[dbo].[s_GetAGG_ProdAndDownReport_Vulkan] '2020-10-10','2020-10-10','','','','',''

*/
CREATE PROCEDURE [dbo].[s_GetAGG_ProdAndDownReport_Vulkan]
@StartDate As DateTime,
@EndDate As DateTime,
@ShiftName As NVarChar(20)='',
@PlantID As NVarChar(50)='',
@MachineID As nvarchar(50) = '',
@CellID As nvarchar(50) = '',
@Parameter As nvarchar(50)=''

AS
BEGIN
----------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------
Declare @Strsql nvarchar(4000)
Declare @Strmachine nvarchar(255)
Declare @timeformat AS nvarchar(12)
Declare @StrPlantID AS NVarchar(255)
Declare @StrShift AS NVarchar(255)
Declare @StrCellID AS NVarchar(255)


Declare @StrDmachine nvarchar(255)
Declare @StrDPlantID AS NVarchar(255)
Declare @StrDShift AS NVarchar(255)
Declare @StrDCellID AS NVarchar(255)

Declare @CurDate as datetime
Declare @FromTime as datetime
Declare @ToTime as datetime

Select @Strsql = ''
Select @Strmachine = ''
Select @StrPlantID=''
Select @StrShift=''
Select @StrDmachine = ''
Select @StrDPlantID=''
Select @StrDShift=''
select @StrCellID=''
select @StrDCellID=''

If isnull(@PlantID,'') <> ''
Begin
Select @StrPlantID = ' And ( ShiftProductionDetails.PlantID = N''' + @PlantID + ''' )'
End
If isnull(@Machineid,'') <> ''
Begin
Select @Strmachine = ' And ( ShiftProductionDetails.MachineID = N''' + @MachineID + ''')'
End

If isnull(@ShiftName,'') <> ''
Begin
Select @StrShift = ' And ( ShiftProductionDetails.Shift = N''' + @ShiftName + ''')'
End
If isnull(@CellID,'') <> ''
Begin
Select @StrCellID = ' And ( ShiftProductionDetails.Groupid = N''' + @CellID + ''')'
End


If isnull(@PlantID,'') <> ''
Begin
Select @StrDPlantID = ' And ( ShiftDownTimeDetails.PlantID = N''' + @PlantID + ''' )'
End
If isnull(@Machineid,'') <> ''
Begin
Select @StrDmachine = ' And ( ShiftDownTimeDetails.MachineID = N''' + @MachineID + ''')'
End
If isnull(@ShiftName,'') <> ''
Begin
Select @StrDShift = ' And ( ShiftDownTimeDetails.Shift = N''' + @ShiftName + ''')'
End
If isnull(@CellID,'') <> ''
Begin
Select @StrDCellID = ' And ( ShiftDownTimeDetails.Groupid = N''' + @CellID + ''')'
End

Select @timeformat ='ss'
Select @timeformat = isnull((Select valueintext from cockpitdefaults where parameter='timeformat'),'ss')
if (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')
Begin
Select @timeformat = 'ss'
End

Select @CurDate = CAST(datePart(yyyy,@StartDate) AS nvarchar(4)) + '-' + SUBSTRING(DATENAME(MONTH,@StartDate),1,3) + '-' + CAST(datePart(dd,@StartDate) AS nvarchar(2))

Create Table #ProdData
(
Pdate DateTime,
Shift NVarChar(50),
Startdate DateTime,
Enddate DateTime,
PlantID NVarChar(50),
MachineID NVarChar(50),
ComponentID NVarChar(50),
OperatorID NVarChar(50),
WorkOrderNumber NVarChar(50),
CompDescription NVarChar(100),
StdCycleTime Float,
ProdCount Float,
AcceptedParts Float,
RejCount Float,
ReworkPerformed Float,
MarkedForRework Float,
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
Select @Strsql=''
SELECT @StrSql='INSERT INTO #ProdData(Pdate,Shift,Startdate,Enddate,MachineID,ComponentID,Plantid,Stdcycletime,OperatorID,WorkOrderNumber,CompDescription)
SELECT Distinct S.Pdate, S.Shift, S.ShiftStart, S.ShiftEnd, ShiftProductionDetails.Machineid,ShiftProductionDetails.Componentid,ShiftProductionDetails.Plantid,(CO_StdMachiningTime+CO_StdLoadUnload),
ShiftProductionDetails.OperatorID,ShiftProductionDetails.WorkOrderNumber,Componentinformation.Description from ShiftProductionDetails
inner join Machineinformation M on M.Machineid=ShiftProductionDetails.Machineid
inner join Componentinformation on Componentinformation.Componentid=ShiftProductionDetails.Componentid
INNER join #ShiftDetails S on S.Pdate=ShiftProductionDetails.Pdate and S.Shift=ShiftProductionDetails.shift
Where M.Interfaceid>''0'''
SELECT @StrSql=@StrSql+ @StrPlantID+ @Strmachine + @StrShift + @StrCellID
Print @StrSql
EXEC(@StrSql)


--Updating ProdCount,AcceptedParts,MarkedForRework,ReworkPerformed for the selected time period
Select @Strsql = 'Update #ProdData Set ProdCount=ISNULL(T2.ProdCount,0),AcceptedParts=ISNULL(T2.AcceptedParts,0),'
Select @Strsql = @Strsql+ 'ReworkPerformed=ISNULL(T2.Rework_Performed,0),MarkedForRework=ISNULL(T2.MarkedForRework,0),UtilisedTime=ISNULL(T2.UtilisedTime,0)'
Select @Strsql = @Strsql+ ' From('
Select @Strsql = @Strsql+ ' Select ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.Machineid,ShiftProductionDetails.Componentid,
ShiftProductionDetails.OperatorID,ShiftProductionDetails.WorkOrderNumber,
Sum(ISNULL(ShiftProductionDetails.Prod_Qty,0))ProdCount,Sum(ISNULL(ShiftProductionDetails.AcceptedParts,0))AcceptedParts,
Sum(ISNULL(ShiftProductionDetails.Rework_Performed,0))AS Rework_Performed,Sum(ISNULL(ShiftProductionDetails.Marked_For_Rework,0)) as MarkedForRework,
Sum(ShiftProductionDetails.Sum_of_ActCycleTime)As UtilisedTime
From ShiftProductionDetails inner join #Proddata T1 on ShiftProductionDetails.pDate=T1.Pdate and ShiftProductionDetails.Shift=T1.Shift
and ShiftProductionDetails.Machineid=T1.Machineid and ShiftProductionDetails.Componentid=T1.Componentid and ShiftProductionDetails.OperatorID=T1.OperatorID
and ShiftProductionDetails.WorkOrderNumber=T1.WorkOrderNumber'
Select @Strsql = @Strsql+ ' Where 1=1 '
Select @Strsql = @Strsql+ @StrPlantID + @Strmachine + @StrShift+ @StrCellID
Select @Strsql = @Strsql+ ' GROUP By ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.Machineid,ShiftProductionDetails.Componentid,
ShiftProductionDetails.OperatorID,ShiftProductionDetails.WorkOrderNumber '
Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.pDate=T2.pDate And #ProdData.Shift=T2.Shift and #ProdData.Machineid=T2.Machineid and #ProdData.Componentid=T2.Componentid 
and #ProdData.OperatorID=T2.OperatorID and #ProdData.WorkOrderNumber=T2.WorkOrderNumber'
Print @Strsql
Exec(@Strsql)

Select @Strsql = 'UPDATE #ProdData SET RejCount=ISNULL(T2.Rej,0)'
Select @Strsql = @Strsql+' FROM('
Select @Strsql = @Strsql+' Select ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.Machineid,ShiftProductionDetails.Componentid,
Sum(isnull(Rejection_Qty,0))Rej,ShiftProductionDetails.OperatorID,ShiftProductionDetails.WorkOrderNumber '
Select @Strsql = @Strsql+' From ShiftProductionDetails Left Outer Join ShiftRejectionDetails ON ShiftProductionDetails.ID=ShiftRejectionDetails.ID
inner join #Proddata T1 on ShiftProductionDetails.pDate=T1.Pdate and ShiftProductionDetails.Shift=T1.Shift
and ShiftProductionDetails.Machineid=T1.Machineid and ShiftProductionDetails.Componentid=T1.Componentid and ShiftProductionDetails.OperatorID=T1.OperatorID and ShiftProductionDetails.WorkOrderNumber=T1.WorkOrderNumber '
Select @Strsql = @Strsql+' Where ShiftProductionDetails.pDate=T1.Pdate '
Select @Strsql = @Strsql+ @StrPlantID + @Strmachine + @StrShift+ @StrCellID
Select @Strsql = @Strsql+' Group By ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.Machineid,ShiftProductionDetails.Componentid,ShiftProductionDetails.OperatorID,ShiftProductionDetails.WorkOrderNumber '
Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.pDate=T2.pDate And #ProdData.Shift=T2.Shift and #ProdData.Machineid=T2.Machineid and #ProdData.Componentid=T2.Componentid
and #ProdData.OperatorID=T2.OperatorID and #ProdData.WorkOrderNumber=T2.WorkOrderNumber '
Print @Strsql
Exec(@Strsql)

Select @Strsql = 'Update #ProdData Set CN=ISNULL(T2.CN,0)'
Select @Strsql = @Strsql + ' From ('
Select @Strsql = @Strsql + ' Select ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.Machineid,ShiftProductionDetails.Componentid,
ShiftProductionDetails.OperatorID,ShiftProductionDetails.WorkOrderNumber,
sum(ShiftProductionDetails.Prod_Qty *(CO_StdMachiningTime+CO_StdLoadUnload)) AS CN '
Select @Strsql = @Strsql + ' From ShiftProductionDetails
inner join #Proddata T1 on ShiftProductionDetails.pDate=T1.Pdate and ShiftProductionDetails.Shift=T1.Shift and ShiftProductionDetails.Machineid=T1.Machineid and ShiftProductionDetails.Componentid=T1.Componentid
and ShiftProductionDetails.OperatorID=T1.OperatorID and ShiftProductionDetails.WorkOrderNumber=T1.WorkOrderNumber'
Select @Strsql = @Strsql + ' Where ShiftProductionDetails.pDate=T1.Pdate '
Select @Strsql = @Strsql+ @StrPlantID + @Strmachine + @StrShift+ @StrCellID
Select @Strsql = @Strsql + ' Group By ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.Machineid,ShiftProductionDetails.Componentid,
ShiftProductionDetails.OperatorID,ShiftProductionDetails.WorkOrderNumber '
Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.pDate=T2.pDate And #ProdData.Shift=T2.Shift and #ProdData.Machineid=T2.Machineid and #ProdData.Componentid=T2.Componentid 
and #ProdData.OperatorID=T2.OperatorID and #ProdData.WorkOrderNumber=T2.WorkOrderNumber '
Print @Strsql
Exec(@Strsql)

Select @Strsql =''
SELECT @StrSql='UPDATE #ProdData SET UtilisedTime = Isnull(#ProdData.UtilisedTime,0)+IsNull(T2.MinorDownTime,0) '
SELECT @StrSql=@StrSql+'From (SELECT ShiftDownTimeDetails.dDate,ShiftDownTimeDetails.Shift,ShiftDownTimeDetails.Machineid,ShiftDownTimeDetails.Componentid,
sum(datediff(s,starttime,endtime)) as MinorDownTime,ShiftDownTimeDetails.OperatorID,ShiftDownTimeDetails.WorkOrderNumber '
SELECT @StrSql=@StrSql+'FROM ShiftDownTimeDetails Inner Join #ProdData T1 ON ShiftDownTimeDetails.ddate=T1.pdate
and ShiftDownTimeDetails.shift=T1.Shift and ShiftDownTimeDetails.Machineid=T1.Machineid and ShiftDownTimeDetails.Componentid=T1.Componentid
and ShiftDownTimeDetails.OperatorID=T1.OperatorID and ShiftDownTimeDetails.WorkOrderNumber=T1.WorkOrderNumber
WHERE downid in (select downid from downcodeinformation where prodeffy = 1) '
Select @Strsql = @Strsql+ @StrdPlantID + @Strdmachine + @StrDShift+ @StrDCellID
SELECT @StrSql=@StrSql+'Group By ShiftDownTimeDetails.dDate,ShiftDownTimeDetails.Shift,ShiftDownTimeDetails.Machineid,ShiftDownTimeDetails.Componentid,
ShiftDownTimeDetails.OperatorID,ShiftDownTimeDetails.WorkOrderNumber '
Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.pDate=T2.dDate And #ProdData.Shift=T2.Shift and #ProdData.Machineid=T2.Machineid and #ProdData.Componentid=T2.Componentid
and #ProdData.OperatorID=T2.OperatorID and #ProdData.WorkOrderNumber=T2.WorkOrderNumber '
print @StrSql
EXEC(@StrSql)

Select @Strsql = 'UPDATE #ProdData SET DownTime = IsNull(T2.DownTime,0)'
Select @Strsql = @Strsql + ' From (select ShiftDownTimeDetails.dDate,ShiftDownTimeDetails.Shift,ShiftDownTimeDetails.Machineid,ShiftDownTimeDetails.Componentid,
( Sum(ShiftDownTimeDetails.DownTime) )As DownTime,ShiftDownTimeDetails.OperatorID,ShiftDownTimeDetails.WorkOrderNumber'
Select @Strsql = @Strsql + ' From ShiftDownTimeDetails
Inner Join #ProdData T1 ON ShiftDownTimeDetails.Machineid=T1.Machineid and ShiftDownTimeDetails.Componentid=T1.Componentid and ShiftDownTimeDetails.ddate=T1.pdate
and ShiftDownTimeDetails.shift=T1.Shift and ShiftDownTimeDetails.OperatorID=T1.OperatorID and ShiftDownTimeDetails.WorkOrderNumber=T1.WorkOrderNumber
where dDate=T1.Pdate '
Select @Strsql = @Strsql+  @StrdPlantID + @Strdmachine + @StrDShift+ @StrDCellID
Select @Strsql = @Strsql + ' Group By ShiftDownTimeDetails.dDate,ShiftDownTimeDetails.Shift,ShiftDownTimeDetails.Machineid,ShiftDownTimeDetails.Componentid,
ShiftDownTimeDetails.OperatorID,ShiftDownTimeDetails.WorkOrderNumber '
Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.pDate=T2.dDate And #ProdData.Shift=T2.Shift and #ProdData.Machineid=T2.Machineid and #ProdData.Componentid=T2.Componentid 
and #ProdData.OperatorID=T2.OperatorID and #ProdData.WorkOrderNumber=T2.WorkOrderNumber '
Print @Strsql
Exec(@Strsql)

Select @Strsql = 'UPDATE #ProdData SET ManagementLoss = isNull(t2.loss,0)'
Select @Strsql = @Strsql + 'from (select ShiftDownTimeDetails.dDate,ShiftDownTimeDetails.Shift,ShiftDownTimeDetails.Machineid,ShiftDownTimeDetails.Componentid,sum(
CASE
WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0
THEN isnull(ShiftDownTimeDetails.Threshold,0)
ELSE ShiftDownTimeDetails.DownTime
END) AS LOSS,ShiftDownTimeDetails.OperatorID,ShiftDownTimeDetails.WorkOrderNumber '
Select @Strsql = @Strsql + ' From ShiftDownTimeDetails
Inner Join #ProdData T1 ON ShiftDownTimeDetails.Machineid=T1.Machineid and ShiftDownTimeDetails.Componentid=T1.Componentid
and ShiftDownTimeDetails.ddate=T1.pdate and ShiftDownTimeDetails.shift=T1.Shift and ShiftDownTimeDetails.OperatorID=T1.OperatorID and ShiftDownTimeDetails.WorkOrderNumber=T1.WorkOrderNumber
where dDate=T1.Pdate And ML_Flag=1 '
Select @Strsql = @Strsql+ @StrdPlantID + @Strdmachine + @StrDShift+ @StrDCellID
Select @Strsql = @Strsql + ' Group By ShiftDownTimeDetails.dDate,ShiftDownTimeDetails.Shift,ShiftDownTimeDetails.Machineid,ShiftDownTimeDetails.Componentid,
ShiftDownTimeDetails.OperatorID,ShiftDownTimeDetails.WorkOrderNumber '
Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.pDate=T2.dDate And #ProdData.Shift=T2.Shift and #ProdData.Machineid=T2.Machineid and #ProdData.Componentid=T2.Componentid 
and #ProdData.OperatorID=T2.OperatorID and #ProdData.WorkOrderNumber=T2.WorkOrderNumber '
Print @Strsql
Exec(@Strsql)

UPDATE #ProdData SET QEffy=CAST((AcceptedParts)As Float)/CAST((AcceptedParts+RejCount+MarkedForRework) AS Float)
Where CAST((AcceptedParts+RejCount+MarkedForRework) AS Float) <> 0


UPDATE #ProdData
SET
PEffy = (CN/UtilisedTime) , 
AEffy = (UtilisedTime)/(UtilisedTime + ISNULL( DownTime,0)-ManagementLoss)
WHERE UtilisedTime <> 0

UPDATE #ProdData
SET
OEffy = PEffy *AEffy *QEffy * 100,
PEffy = PEffy * 100 ,
AEffy = AEffy * 100,
QEffy = QEffy * 100

--select Pdate,Shift,MachineID,OperatorID,WorkOrderNumber as BatchNo,CompDescription as PartDescription,
--ProdCount as NoOfCycles,RejCount,AcceptedParts as ProductionQty,dbo.f_formattime(DownTime,'hh:mm:ss') as Downtime,
--Round(AEffy,2) as AEffy,Round(PEffy,0) as PEffy,Round(OEffy,2) as Oeffy from #ProdData
--Order by PDate,shift,MachineID

select Pdate,Shift,MachineID,OperatorID,WorkOrderNumber as BatchNo,CompDescription as PartDescription,
ProdCount as NoOfCycles,RejCount,(ProdCount - RejCount) as ProductionQty,dbo.f_formattime(DownTime,'hh:mm:ss') as Downtime,
Round(AEffy,2) as AEffy,Round(PEffy,0) as PEffy,Round(OEffy,2) as Oeffy from #ProdData
Order by PDate,shift,MachineID


select SUM(ProdCount) as NoOfCycles,SUM(RejCount) as Rejcount,SUM(AcceptedParts) as ProductionQty,dbo.f_formattime(SUM(DownTime),'hh') as Downtime,
Round(Avg(AEffy),2) as AEffy,Round(Avg(PEffy),2) as PEffy,Round(Avg(OEffy),2) as OEffy from #ProdData

END
