/****** Object:  Procedure [dbo].[S_Get_OperatorIncentiveReport]    Committed by VersionSQL https://www.versionsql.com ******/

/*
Created by Raksha R on 29-jul-2021

[dbo].[S_Get_OperatorIncentiveReport] '2022-01-04 00:00:00.000','2022-01-05 00:00:00.000','','','Akhilesh Morya','AvgCycleTime'

exec [dbo].[S_Get_OperatorIncentiveReport] @StartDate=N'2022-02-25 00:00:00',@EndDate=N'2022-02-25 00:00:00',@OperatorID=N'AMIT YADAV',@MachineID=N'',@Param=N'AvgCycleTime'

exec [dbo].[S_Get_OperatorIncentiveReport] @StartDate=N'2022-02-25 00:00:00',@EndDate=N'2022-02-25 00:00:00',@OperatorID=N'AMIT YADAV',@MachineID=N'',@Param=N'StdCycleTime'

*/
CREATE procedure [dbo].[S_Get_OperatorIncentiveReport]
@StartDate As DateTime,
@EndDate As DateTime,
@ShiftName As NVarChar(20)='',
@MachineID As nvarchar(50) = '',
@OperatorID as nvarchar(50)='',
@Param nvarchar(50)=''

AS
BEGIN

Declare @Strsql nvarchar(4000)
Declare @Strmachine nvarchar(255)
Declare @StrShift AS NVarchar(255)
Declare @StrOpr as nvarchar(255)

Select @Strsql = ''
Select @Strmachine = ''
Select @StrShift=''
Select @StrOpr=''

If isnull(@Machineid,'') <> ''
Begin
Select @Strmachine = ' And ( ShiftProductionDetails.MachineID = N''' + @MachineID + ''')'
End

If isnull(@ShiftName,'') <> ''
Begin
Select @StrShift = ' And ( ShiftProductionDetails.Shift = N''' + @ShiftName + ''')'
End

If isnull(@OperatorID,'') <> ''
Begin
Select @StrOpr = ' And ( ShiftProductionDetails.OperatorID = N''' + @OperatorID + ''')'
End

Create Table #ProdData
(
MachineID NVarChar(50),
ComponentID NVarChar(50),
OperationNo nvarchar(50),
OperatorID nvarchar(50),
OperatorName nvarchar(50),
Pdate DateTime,
Shift NVarChar(50),
Startdate datetime,
Enddate datetime,
StdCycleTime Float,
LoadUnload float,
TotalCycleTime float,
MachineHrRate float,
ProdCount float,
AcceptedParts float,
OperationRate float,
ShiftQty float,
ShiftIncentiveTotalInRS float,

ActMachiningTime_Type12 float default 0,
ActLoadUnload_Type12 float default 0,
AvgCycleTime float default 0,
AvgLoadUnload float default 0
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

IF @Param='' or @Param='StdCycleTime'
BEGIN
	Select @Strsql=''
	SELECT @StrSql='INSERT INTO #ProdData(MachineID,Shift,ComponentID,Pdate,OperationNo,OperatorID,OperatorName,Startdate,Enddate,Stdcycletime,LoadUnload,TotalCycleTime,MachineHrRate)
	SELECT Distinct  ShiftProductionDetails.Machineid,S.Shift, ShiftProductionDetails.Componentid,S.Pdate, ShiftProductionDetails.OperationNo,ShiftProductionDetails.OperatorID, employeeinformation.Name,
	S.ShiftStart, S.ShiftEnd,CO_StdMachiningTime, CO_StdLoadUnload,(CO_StdMachiningTime+CO_StdLoadUnload),ShiftProductionDetails.mchrrate
	from ShiftProductionDetails
	inner join Machineinformation M on M.Machineid=ShiftProductionDetails.Machineid
	inner join employeeinformation on ShiftProductionDetails.OperatorID=employeeinformation.Employeeid
	INNER join #ShiftDetails S on S.Pdate=ShiftProductionDetails.Pdate and S.Shift=ShiftProductionDetails.shift
	Where M.Interfaceid>''0'''
	SELECT @StrSql=@StrSql+ @Strmachine + @StrShift + @StrOpr
	Print @StrSql
	EXEC(@StrSql)


	Select @Strsql=''
	Select @Strsql = 'Update #ProdData Set ProdCount=ISNULL(T2.ProdCount,0),AcceptedParts=ISNULL(T2.AcceptedParts,0) '
	Select @Strsql = @Strsql+ ' From('
	Select @Strsql = @Strsql+ ' Select ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.Machineid,ShiftProductionDetails.Componentid,ShiftProductionDetails.OperationNo,
	ShiftProductionDetails.OperatorID,
	Sum(ISNULL(ShiftProductionDetails.Prod_Qty,0))ProdCount,
	Sum(ISNULL(ShiftProductionDetails.AcceptedParts,0))AcceptedParts
	From ShiftProductionDetails inner join 
	(select distinct pdate,machineid,Shift,ComponentID,OperationNo,OperatorID from #Proddata) 
	T1 on ShiftProductionDetails.pDate=T1.Pdate and ShiftProductionDetails.Shift=T1.Shift
	and ShiftProductionDetails.Machineid=T1.Machineid and ShiftProductionDetails.Componentid=T1.Componentid 
	and ShiftProductionDetails.OperationNo=T1.OperationNo and ShiftProductionDetails.OperatorID=T1.OperatorID'
	Select @Strsql = @Strsql+ ' Where 1=1 '
	Select @Strsql = @Strsql + @Strmachine + @StrShift
	Select @Strsql = @Strsql+ ' GROUP By ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.Machineid,ShiftProductionDetails.Componentid,ShiftProductionDetails.OperationNo,ShiftProductionDetails.OperatorID '
	Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.pDate=T2.pDate And #ProdData.Shift=T2.Shift and #ProdData.Machineid=T2.Machineid and #ProdData.Componentid=T2.Componentid 
	and #ProdData.OperationNo= T2.OperationNo and #ProdData.OperatorID= T2.OperatorID '
	Print @Strsql
	Exec(@Strsql)
END

IF @Param='AvgCycleTime'
BEGIN
	Select @Strsql=''
	SELECT @StrSql='INSERT INTO #ProdData(MachineID,Shift,ComponentID,Pdate,OperationNo,OperatorID,OperatorName,Startdate,Enddate,Stdcycletime,LoadUnload,TotalCycleTime,MachineHrRate)
	SELECT Distinct  ShiftProductionDetails.Machineid,S.Shift, ShiftProductionDetails.Componentid,S.Pdate, ShiftProductionDetails.OperationNo,ShiftProductionDetails.OperatorID, employeeinformation.Name,
	S.ShiftStart, S.ShiftEnd,CO_StdMachiningTime, CO_StdLoadUnload,0,ShiftProductionDetails.mchrrate
	from ShiftProductionDetails
	inner join Machineinformation M on M.Machineid=ShiftProductionDetails.Machineid
	inner join employeeinformation on ShiftProductionDetails.OperatorID=employeeinformation.Employeeid
	INNER join #ShiftDetails S on S.Pdate=ShiftProductionDetails.Pdate and S.Shift=ShiftProductionDetails.shift
	Where M.Interfaceid>''0'''
	SELECT @StrSql=@StrSql+ @Strmachine + @StrShift + @StrOpr
	Print @StrSql
	EXEC(@StrSql)

	Select @Strsql=''
	Select @Strsql = 'Update #ProdData Set ActMachiningTime_Type12=ISNULL(T2.ActMachiningTime_Type12,0),ActLoadUnload_Type12=ISNULL(T2.ActLoadUnload_Type12,0), AvgLoadUnload=isnull(T2.AvgLoadUnload,0) '
	Select @Strsql = @Strsql+ ' From('
	Select @Strsql = @Strsql+ ' Select ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.Machineid,ShiftProductionDetails.Componentid,ShiftProductionDetails.OperationNo,
	ShiftProductionDetails.OperatorID,
	Sum(ISNULL(ShiftProductionDetails.ActMachiningTime_Type12,0)) ActMachiningTime_Type12,
	Sum(ISNULL(ShiftProductionDetails.ActLoadUnload_Type12,0))ActLoadUnload_Type12,
	--sum(isnull(C.LoadUnload,0)) as ActLoadUnload_Type12
	sum(isnull(ShiftProductionDetails.CO_StdLoadUnload,0)) as AvgLoadUnload
	From ShiftProductionDetails inner join 
	(select distinct pdate,machineid,Shift,ComponentID,OperationNo,OperatorID from #Proddata) 
	T1 on ShiftProductionDetails.pDate=T1.Pdate and ShiftProductionDetails.Shift=T1.Shift
	and ShiftProductionDetails.Machineid=T1.Machineid and ShiftProductionDetails.Componentid=T1.Componentid 
	and ShiftProductionDetails.OperationNo=T1.OperationNo and ShiftProductionDetails.OperatorID=T1.OperatorID '
	--inner join componentoperationpricing C on ShiftProductionDetails.Componentid=C.Componentid and ShiftProductionDetails.machineid=C.machineid and ShiftProductionDetails.OperationNo=C.OperationNo'
	Select @Strsql = @Strsql+ ' Where 1=1 '
	Select @Strsql = @Strsql + @Strmachine + @StrShift
	Select @Strsql = @Strsql+ ' GROUP By ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.Machineid,ShiftProductionDetails.Componentid,ShiftProductionDetails.OperationNo,ShiftProductionDetails.OperatorID '
	Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.pDate=T2.pDate And #ProdData.Shift=T2.Shift and #ProdData.Machineid=T2.Machineid and #ProdData.Componentid=T2.Componentid 
	and #ProdData.OperationNo= T2.OperationNo and #ProdData.OperatorID= T2.OperatorID '
	Print @Strsql
	Exec(@Strsql)

	Select @Strsql=''
	Select @Strsql = 'Update #ProdData Set ProdCount=ISNULL(T2.ProdCount,0),AcceptedParts=ISNULL(T2.AcceptedParts,0) '
	Select @Strsql = @Strsql+ ' From('
	Select @Strsql = @Strsql+ ' Select ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.Machineid,ShiftProductionDetails.Componentid,ShiftProductionDetails.OperationNo,
	ShiftProductionDetails.OperatorID,
	Sum(ISNULL(ShiftProductionDetails.Prod_Qty,0))ProdCount,
	Sum(ISNULL(ShiftProductionDetails.AcceptedParts,0))AcceptedParts
	From ShiftProductionDetails inner join 
	(select distinct pdate,machineid,Shift,ComponentID,OperationNo,OperatorID from #Proddata) 
	T1 on ShiftProductionDetails.pDate=T1.Pdate and ShiftProductionDetails.Shift=T1.Shift
	and ShiftProductionDetails.Machineid=T1.Machineid and ShiftProductionDetails.Componentid=T1.Componentid 
	and ShiftProductionDetails.OperationNo=T1.OperationNo and ShiftProductionDetails.OperatorID=T1.OperatorID'
	Select @Strsql = @Strsql+ ' Where 1=1 '
	Select @Strsql = @Strsql + @Strmachine + @StrShift
	Select @Strsql = @Strsql+ ' GROUP By ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.Machineid,ShiftProductionDetails.Componentid,ShiftProductionDetails.OperationNo,ShiftProductionDetails.OperatorID '
	Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.pDate=T2.pDate And #ProdData.Shift=T2.Shift and #ProdData.Machineid=T2.Machineid and #ProdData.Componentid=T2.Componentid 
	and #ProdData.OperationNo= T2.OperationNo and #ProdData.OperatorID= T2.OperatorID '
	Print @Strsql
	Exec(@Strsql)

	Update #ProdData set AvgCycleTime=isnull(ActMachiningTime_Type12,0)/isnull(ProdCount,0) 
	--,AvgLoadUnload=isnull(ActLoadUnload_Type12,0)/isnull(ProdCount,0)
	where ProdCount>0

	Update #ProdData Set TotalCycleTime=Round((isnull(AvgCycleTime,0)+isnull(AvgLoadUnload,0)),2)

	update #ProdData set StdCycleTime=round(isnull(AvgCycleTime,0),2), LoadUnload=round(isnull(AvgLoadUnload,0),2)


END


/*Fromula : OperationRate = (((MachineHrRate/3600)*TotalCycleTime)*15%)*ProdCount
			ShiftIncentiveTotalInRS = (ProdCount*OperationRate) */

Declare @OperationRate float

Select @OperationRate = (ISNULL(cast(ValueInInt as float),0))/100 from ShopDefaults where Parameter='OperatorIncentiveReport' and ValueInText='OperationRate'


Update #ProdData set OperationRate= T1.opnRate
from(
select distinct Pdate,Shift,MachineID,ComponentID,OperationNo,OperatorID,((MachineHrRate/3600)*(TotalCycleTime * (@OperationRate))) as opnRate from #ProdData
)T1 inner join #ProdData T2 on T1.Pdate=T2.Pdate and T1.Shift=T2.Shift and T1.MachineID=T2.MachineID and T1.ComponentID=T2.ComponentID and T1.OperationNo=T2.OperationNo
and T1.OperatorID=T2.OperatorID

Update #ProdData set ShiftIncentiveTotalInRS= T1.shiftInc
from(
select distinct Pdate,Shift,MachineID,ComponentID,OperationNo,OperatorID, (ProdCount*OperationRate) as shiftInc from #ProdData
)T1 inner join #ProdData T2 on T1.Pdate=T2.Pdate and T1.Shift=T2.Shift and T1.MachineID=T2.MachineID and T1.ComponentID=T2.ComponentID and T1.OperationNo=T2.OperationNo
and T1.OperatorID=T2.OperatorID


select distinct OperatorID,OperatorName,Pdate,Shift,MachineID,ComponentID,OperationNo,Stdcycletime,LoadUnload,TotalCycleTime,MachineHrRate,
Round(isnull(OperationRate,0),3) as OperationRate,ProdCount, round(isnull(ShiftIncentiveTotalInRS,0),3) as ShiftIncentiveTotalInRS
from #ProdData
where ProdCount<>0
order by OperatorID,OperatorName,Pdate,Shift,MachineID,ComponentID,OperationNo

select distinct OperatorID,OperatorName,round(SUM(isnull(OperationRate,0)),3) as OperationRate,SUM(isnull(ProdCount,0)) as ProdCount, 
round(SUM(isnull(ShiftIncentiveTotalInRS,0)),3) as ShiftIncentiveTotalInRS
from #ProdData
group by OperatorID,OperatorName
order by OperatorID,OperatorName

END
