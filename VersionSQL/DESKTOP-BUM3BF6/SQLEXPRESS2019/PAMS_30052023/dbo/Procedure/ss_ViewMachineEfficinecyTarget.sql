/****** Object:  Procedure [dbo].[ss_ViewMachineEfficinecyTarget]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[ss_ViewMachineEfficinecyTarget] '2021-04-01','','View','OE'
CREATE PROCEDURE [dbo].[ss_ViewMachineEfficinecyTarget]
@date datetime='',
@machineid nvarchar(50)='',
@param nvarchar(50)='',
@Efficiency nvarchar(20)=''
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
declare @year int
if(@date ='')
	BEGIN
	set @year = year(getdate());
	END
else
	BEGIN
	set @year = year(@date);
	END


create table #temp
(
MonName nvarchar(50),
Machineid nvarchar(50),
Efficiency int default 85
)



;WITH Months (N, MyDate) AS
(
SELECT 1, DateAdd(year, DateDiff(year, 0, GetDate()), 0)
UNION ALL
SELECT N+1, DateAdd(month, 1, MyDate)
  FROM Months
 WHERE N < 12
)

insert into #temp(MonName,MachineID)
select  DateName(month, MyDate),Machineid FROM Months  cross join MachineInformation 
where (MachineID = @Machineid or @Machineid='') 
 ORDER BY N;


update #temp set Efficiency = ISNULL(T.Efficiency,0) from
(select Machineid,DateName(mm,StartDate) as MonName,
 case when @Efficiency='OE' then  OE 
 when @Efficiency='AE' then  AE 
 when @Efficiency='PE' then  PE 
 when @Efficiency='QE' then  QE 
 End as Efficiency 
from efficiencyTarget where (MachineID = @Machineid or @Machineid='') 
and  year(StartDate) = @year)T inner join #temp on T.Machineid= #temp.Machineid and T.MonName= #temp.MonName

if(@param = 'View')
BEGIN
DECLARE @DynamicPivotQuery AS NVARCHAR(MAX)
DECLARE @ColumnName AS NVARCHAR(MAX)

--Get distinct values of the PIVOT Column 
SELECT @ColumnName= ISNULL(@ColumnName + ',','') 
       + QUOTENAME(MonName)
FROM (SELECT DISTINCT MonName FROM #temp) AS Cours

SET @DynamicPivotQuery = 
  N'
  SELECT Machineid,' + @ColumnName + '
    FROM #temp 
    PIVOT(MAX(Efficiency)
          FOR MonName IN (' + @ColumnName + ')) AS PVTTable'

--Execute the Dynamic Pivot Query
execute (@DynamicPivotQuery)
END

END
