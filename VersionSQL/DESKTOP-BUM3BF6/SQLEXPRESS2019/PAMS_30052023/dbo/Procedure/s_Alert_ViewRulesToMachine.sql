/****** Object:  Procedure [dbo].[s_Alert_ViewRulesToMachine]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[Alert_ViewRulesToMachine] '','','View'
--[dbo].[Alert_ViewRulesToMachine] '','''Down_L1''','View'
--[dbo].[Alert_ViewRulesToMachine] '','''Backup'',''Down_L1'',''Down_L2''','View'

CREATE PROCEDURE [dbo].[s_Alert_ViewRulesToMachine]
@PlantID nvarchar(50)='',
@RuleID nvarchar(Max)='',
@param nvarchar(50)=''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

create table #temp
(
MachineID nvarchar(50),
Rules nvarchar(50),
IsChecked Int default 0
)

declare @Strsql as nvarchar(4000)
declare @strPlantID as nvarchar(4000)
declare @strdown as nvarchar(4000)


Select @strsql=''
Select @strPlantID=''
Select @strdown=''

if isnull(@PlantID,'')<> ''
Begin
	SET @strPlantID = ' AND PM.PlantID = N''' + @PlantID + ''''
End

if isnull(@RuleID,'')  <> ''
BEGIN
	select @strdown = ' and ( [Alert_Rules].RuleID IN(' + @RuleID +'))'
END


if @param='View'
BEGIN	

Select @strsql=@Strsql + 'insert into #temp (Machineid,Rules) 
select MI.Machineid,RuleID from machineinformation MI  
inner join plantmachine PM on PM.Machineid=MI.Machineid 
cross join [Alert_Rules] where 1=1'
select @strsql =  @strsql + @strdown + @strPlantID
print @strsql
exec(@strsql)

update #temp set ISchecked = T.IsChecked from 
(select tp.Rules,tp.MachineID , 1 as IsChecked from #temp tp inner join [Alert_AssignRulesToMachine] ARM on 
tp.Machineid= ARM.Machineid and tp.Rules  = ARM.RuleID)T
inner join #temp on T.Rules=#temp.Rules and T.Machineid= #temp.Machineid

DECLARE @DynamicPivotQuery AS NVARCHAR(MAX)
DECLARE @ColumnName AS NVARCHAR(MAX)

--Get distinct values of the PIVOT Column 
SELECT @ColumnName= ISNULL(@ColumnName + ',','') 
       + QUOTENAME(Rules)
FROM (SELECT DISTINCT Rules FROM #temp) AS Cours


SET @DynamicPivotQuery = 
  N'
  SELECT Machineid as Machineid ,' + @ColumnName + '
    FROM #temp 
    PIVOT(MAX(IsChecked)
          FOR Rules IN (' + @ColumnName + ')) AS PVTTable'
--Execute the Dynamic Pivot Query
execute (@DynamicPivotQuery)


END



END
