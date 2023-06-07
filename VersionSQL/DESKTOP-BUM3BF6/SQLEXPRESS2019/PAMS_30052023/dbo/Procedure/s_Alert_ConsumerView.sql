/****** Object:  Procedure [dbo].[s_Alert_ConsumerView]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[Alert_ConsumerView] '','u1','View'
--[dbo].[Alert_ConsumerView] '','RAVI','View'

CREATE PROCEDURE [dbo].[s_Alert_ConsumerView]
@PlantID nvarchar(50)='',
@ConsumerID nvarchar(50),
@param nvarchar(50)=''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

create table #temp
(
Rules nvarchar(50),
MachineID nvarchar(50),
IsChecked Int default 0
)

if @param='View'
BEGIN	

insert into #temp (Machineid,Rules,IsChecked) 
select MI.Machineid,RuleID,0 from machineinformation MI  
Left outer join plantmachine PM on PM.Machineid=MI.Machineid 
cross join [Alert_Rules]
where (PM.Plantid=@plantid or @plantid='')

update #temp set ISchecked = T.IsChecked from 
(select tp.Rules,tp.MachineID , 1 as IsChecked from #temp tp 
left join [Alert_AssignRulesToMachine] AR on tp.Machineid= AR.Machineid and tp.Rules  = AR.RuleID    
inner join  [Alert_AssignRulesToUser] AU on tp.Machineid= AU.Machineid and tp.Rules  = AU.RuleID 
where AU.Userid=@ConsumerID)T inner join #temp on T.Rules=#temp.Rules and T.Machineid= #temp.Machineid

DECLARE @DynamicPivotQuery AS NVARCHAR(MAX)
DECLARE @ColumnName AS NVARCHAR(MAX)

--Get distinct values of the PIVOT Column 
SELECT @ColumnName= ISNULL(@ColumnName + ',','') 
       + QUOTENAME(Rules)
FROM (SELECT DISTINCT Rules FROM #temp) AS Cours

SET @DynamicPivotQuery = 
  N'
  SELECT MachineID,' + @ColumnName + '
    FROM #temp 
    PIVOT(MAX(IsChecked)
          FOR Rules IN (' + @ColumnName + ')) AS PVTTable'

--Execute the Dynamic Pivot Query
execute (@DynamicPivotQuery)


END



END
