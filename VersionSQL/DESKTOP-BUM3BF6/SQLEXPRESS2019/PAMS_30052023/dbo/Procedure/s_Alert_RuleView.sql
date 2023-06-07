/****** Object:  Procedure [dbo].[s_Alert_RuleView]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[Alert_RuleView2] 'IMTEX2017_LIVE','Backup','View'
--[dbo].[Alert_RuleView2] 'cnc shop1', '3','View'

CREATE PROCEDURE [dbo].[s_Alert_RuleView]
@PlantID nvarchar(50)='',
@RuleID nvarchar(50),
@param nvarchar(50)=''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

create table #temp
(
Consumer nvarchar(50),
MachineID nvarchar(50),
IsChecked Int default 0
)

if @param='View'
BEGIN	
insert into #temp (Machineid,Consumer,IsChecked) 
select MI.Machineid,Alert_Consumers.UserID,0 from plantmachine MI cross join Alert_Consumers 
inner join [Alert_AssignRulesToMachine] AR on MI.Machineid= AR.Machineid
Left outer join plantmachine PM on PM.Machineid=MI.Machineid 
where AR.RuleID=@ruleid and Alert_Consumers.Plantid=PM.Plantid AND (PM.Plantid=@plantid)

update #temp set ISchecked = T.IsChecked from 
(select tp.Consumer,tp.MachineID , 1 as IsChecked from #temp tp inner join [Alert_AssignRulesToUser] AR on 
tp.Machineid= AR.Machineid and tp.Consumer  = AR.UserID 
where AR.RuleID=@RuleID)T inner join #temp on T.Consumer=#temp.Consumer and T.Machineid= #temp.Machineid

DECLARE @DynamicPivotQuery AS NVARCHAR(MAX)
DECLARE @ColumnName AS NVARCHAR(MAX)

--Get distinct values of the PIVOT Column 
SELECT @ColumnName= ISNULL(@ColumnName + ',','') 
       + QUOTENAME(Machineid)
FROM (SELECT DISTINCT Machineid FROM #temp) AS Cours

SET @DynamicPivotQuery = 
  N'
  SELECT Consumer,' + @ColumnName + '
    FROM #temp 
    PIVOT(MAX(IsChecked)
          FOR MachineID IN (' + @ColumnName + ')) AS PVTTable'

--Execute the Dynamic Pivot Query
execute (@DynamicPivotQuery)
END
END
