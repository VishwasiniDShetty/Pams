/****** Object:  Procedure [dbo].[s_GetMonthwiseEnergyData]    Committed by VersionSQL https://www.versionsql.com ******/

/***********************************************************************************
ER0502:SwathiKS:12/Mar/2021::To Use EM_MachineInformation instead of Machineinformation.
Going forward we will store Machines in EM_MachineInformation Table which are enabled for Energy Data Collection instead of Machineinformation. 
To Assign Machines To Plant Use EM_PlantMachine instead of PlantMachine Table. 
Machines which are Enabled For OEE & Energy both, Should be stored in both the tables with same Machineid & interfaceid.  
Enery Related Info we can get From EM_Machineinformation and tcs_EnergyConsumption Tables
OEE Related Info from Mahcineinformation and Autodata Tables.

--[dbo].[s_GetMonthwiseEnergyData] '2015-03-01','2016-03-01','''AC-03'',''CLG-02''','','',''
***********************************************************************************/

CREATE PROCEDURE [dbo].[s_GetMonthwiseEnergyData]
@StartTime as DateTime,
@EndTime AS datetime,
@MachineID as NvarChar(4000)='',
@PlantID as nvarchar(50)='',
@param as nvarchar(50)='',
@MachineType nvarchar(50) = '',
@IsChecked float=0

AS
BEGIN

DECLARE @StrSql as NVarChar(4000)
DECLARE @StrMachineID AS Nvarchar(4000)
DECLARE @StrPlantID AS NVarchar(200)

SELECT @StrSql=''
SELECT @StrMachineID =''
SET @StrPlantID = ''

IF IsNull(@MachineID,'')<>''
BEGIN
	select @StrMachineID = ' AND EM_Machineinformation.Machineid in (' + @MachineID + ')'
END


IF IsNull(@PlantID,'')<>''
BEGIN
	SELECT @strPlantID = ' AND  EM_PlantMachine.PlantID = ''' + @PlantID+ ''''
END

Create Table #MonthList
(
SofMonth  DateTime,
EofMonth  DateTime
)

Create Table #MachineNames
(
MachineID  NvarChar(50)
)


SELECT @StrSql='Insert Into #MachineNames(MachineID)
SELECT EM_Machineinformation.machineid
FROM EM_Machineinformation 
LEFT OUTER JOIN EM_PlantMachine ON EM_Machineinformation.machineid = EM_PlantMachine.MachineID 
Where EM_Machineinformation.MachineType = ''' + @MachineType+ ''' and EM_Machineinformation.machineid<>'''''
SELECT @StrSql=@StrSql + @StrMachineID + @strPlantID 
EXEC (@StrSql)

SELECT @StrSql=''

Declare @TMonth AS DateTime
Declare @StOfMonth AS DateTime
Declare @EndOfMonth AS DateTime


SELECT @TMonth=[dbo].f_GetLogicalMonth(@StartTime,'Start')
While @TMonth<[dbo].f_GetLogicalMonth(@EndTime,'end')
BEGIN
    SELECT @StOfMonth=[dbo].f_GetLogicalMonth(@TMonth,'Start')
    SELECT @EndOfMonth=[dbo].f_GetLogicalMonth(@TMonth,'end')

    Insert Into #MonthList(SofMonth,EofMonth)Values(@StOfMonth,@EndOfMonth)
    SELECT @TMonth=Dateadd(Month,1,@TMonth)
END

CREATE TABLE #Finaldata
(
    StartTime DateTime,
    EndTime DateTime,
    StartMonth nvarchar(50),
    MachineID NvarChar(50),
    Maxenergy float,
    Minenergy float,
    KWH float
)

Insert Into #Finaldata(StartTime,EndTime,StartMonth,MachineID,KWH)
SELECT SofMonth,EofMonth, cast(datepart(year,SofMonth) as nvarchar(4))+ '-' +cast(datename(month,SofMonth) as nvarchar(3)),MachineID,0 From #MonthList Cross Join #MachineNames Order By MachineID,SofMonth

Update #FinalData
set #FinalData.MinEnergy = ISNULL(#FinalData.MinEnergy,0)+ISNULL(t1.kwh,0) from 
(
select T.MachineiD,T.StartTime,T.EndTime,round(kwh,2) as kwh from 
	(
	select  tcs_energyconsumption.MachineiD,StartTime,EndTime,min(gtime) as mingtime
	from tcs_energyconsumption WITH(NOLOCK) 
	inner join #FinalData on tcs_energyconsumption.machineID = #FinalData.MachineiD and 
	tcs_energyconsumption.gtime >= #FinalData.StartTime and tcs_energyconsumption.gtime <= #FinalData.EndTime
	where tcs_energyconsumption.kwh>0 
	group by  tcs_energyconsumption.MachineiD,StartTime,EndTime
	)T inner join tcs_energyconsumption on tcs_energyconsumption.gtime=T.mingtime AND tcs_energyconsumption.MachineID = T.MachineID 
) as t1 inner join #FinalData on t1.machineiD = #FinalData.MachineiD and t1.StartTime = #FinalData.StartTime and t1.endTime = #FinalData.EndTime

Update #FinalData
set #FinalData.MaxEnergy = ISNULL(#FinalData.MaxEnergy,0)+ISNULL(t1.kwh,0) from 
(
select T.MachineiD,T.StartTime,T.EndTime,round(kwh,2)as kwh from 
	(
	select  tcs_energyconsumption.MachineiD,StartTime,EndTime,max(gtime) as maxgtime
	from tcs_energyconsumption WITH(NOLOCK)
	inner join #FinalData on tcs_energyconsumption.machineID = #FinalData.MachineiD and 
	tcs_energyconsumption.gtime >= #FinalData.StartTime and tcs_energyconsumption.gtime <= #FinalData.EndTime
	group by  tcs_energyconsumption.MachineiD,StartTime,EndTime
	)T inner join tcs_energyconsumption on tcs_energyconsumption.gtime=T.maxgtime AND tcs_energyconsumption.MachineID = T.MachineID 
) as t1 inner join #FinalData on t1.machineiD = #FinalData.MachineiD and t1.StartTime = #FinalData.StartTime and t1.endTime = #FinalData.EndTime


Update #FinalData
set #FinalData.kwh = ISNULL(#FinalData.kwh,0)+ISNULL(t1.kwh,0)
from 
(
	select MachineiD,StartTime,EndTime,round((MaxEnergy - MinEnergy),2) as kwh from #FinalData 
) as t1 inner join #FinalData on t1.MachineiD = #FinalData.MachineiD and t1.StartTime = #FinalData.StartTime and t1.endTime = #FinalData.EndTime


DECLARE @DynamicPivotQuery AS NVARCHAR(4000)
DECLARE @SelectColumnName AS NVARCHAR(4000)

select @SelectColumnName = coalesce(@SelectColumnName+',','')+quotename(startmonth)from
(Select distinct cast(datepart(year,starttime) as nvarchar(4))+ '-' +cast(datename(month,starttime) as nvarchar(3)) as startmonth,StartTime from #Finaldata)as b order by b.starttime


if (@IsChecked=0)
begin
SET @DynamicPivotQuery = 
N'SELECT Machineid,' + @SelectColumnName + ' 
FROM (select MachineiD,startmonth,KWH from #Finaldata 
)as s 
PIVOT (max(KWH)
FOR [startmonth] IN (' + @SelectColumnName + ')) AS PVTTable order by MachineiD'


EXEC sp_executesql @DynamicPivotQuery
end

if (@IsChecked=1)
begin
SET @DynamicPivotQuery = 
N'SELECT distinct top(10) Machineid,' + @SelectColumnName + ' 
FROM (select MachineiD,startmonth,KWH from #Finaldata 
)as s 
PIVOT (max(KWH)
FOR [startmonth] IN (' + @SelectColumnName + ')) AS PVTTable order by MachineiD'


EXEC sp_executesql @DynamicPivotQuery
end

	
END	
