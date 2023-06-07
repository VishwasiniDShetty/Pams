/****** Object:  Procedure [dbo].[s_Alert_MachineView]    Committed by VersionSQL https://www.versionsql.com ******/

-- This is to display only those rules that have been mapped to the machineid --


--[dbo].[Alert_MachineView2] 'HMC-400XL','View'
--[dbo].[Alert_MachineView2] 'MAZAK1','View'

CREATE PROCEDURE [dbo].[s_Alert_MachineView]
@MachineID nvarchar(50),
@param nvarchar(50)=''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

create table #temp
(
Consumer nvarchar(50),
Rules nvarchar(50),
IsChecked Int default 0
)

if @param='View'
BEGIN	

insert into #temp (Rules,Consumer,IsChecked) 
select AR.RuleID,AC.UserId,0 from [Alert_Consumers] AC
Left outer join plantmachine PM on PM.Plantid=AC.Plantid 
inner join [Alert_AssignRulesToMachine] AR on AR.MachineID=PM.MachineID
where (PM.MachineID=@MachineID)

update #temp set IsChecked = T.IsChecked from 
(select tp.Rules,tp.Consumer , 1 as IsChecked from #temp tp 
inner join  [Alert_AssignRulesToUser] AU on tp.Consumer= AU.UserID and tp.Rules  = AU.RuleID 
left join [Alert_AssignRulesToMachine] AR on tp.Rules  = AR.RuleID and AU.Machineid=AR.Machineid
where AU.Machineid=@MachineID)T inner join #temp on T.Rules=#temp.Rules and T.Consumer= #temp.Consumer

DECLARE @DynamicPivotQuery AS NVARCHAR(MAX)
DECLARE @ColumnName AS NVARCHAR(MAX)

--Get distinct values of the PIVOT Column 
SELECT @ColumnName= ISNULL(@ColumnName + ',','') 
       + QUOTENAME(Rules)
FROM (SELECT DISTINCT Rules FROM #temp) AS Cours

SET @DynamicPivotQuery = 
  N'
  SELECT Consumer,' + @ColumnName + '
    FROM #temp 
    PIVOT(MAX(IsChecked)
          FOR Rules IN (' + @ColumnName + ')) AS PVTTable'

execute (@DynamicPivotQuery)
END
END
