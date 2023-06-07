/****** Object:  Procedure [dbo].[s_GetCockpitDownData_cell]    Committed by VersionSQL https://www.versionsql.com ******/

------------------------------------------------
--Procedure to populate downtime grid in viewdatagraph
--original author: M Kestur
--09th feb 2005
------------------------------------------------
CREATE  PROCEDURE [dbo].[s_GetCockpitDownData_cell]
	@StartTime datetime,
	@EndTime datetime,
	@CellID nvarchar(50)
AS
BEGIN
SELECT
	downcodeinformation.downid AS DownID,
	downcodeinformation.downdescription as [DownDescription],
	sum(autodata.loadunload) AS DownTime,
	count(autodata.loadunload) as NoOfDowns
INTO #TempCockpitDownData
FROM
	autodata INNER JOIN
	machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN
	CellHistory ON machineinformation.machineid = CellHistory.MachineId INNER JOIN
	downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
WHERE
	(autodata.sttime >= @StartTime )
	AND
	(autodata.sttime < @EndTime )
	AND
	(CellHistory.cellid = @cellID)
	AND
	(autodata.datatype = 2)
group by downcodeinformation.downid,
downcodeinformation.downdescription
ORDER BY downtime desc
--use another temp table to insert the serial number after sorting
select IDENTITY(int, 1, 1) AS SerialNo,
	DownID,
	DownDescription,
	DownTime,
	NoOfDowns
into  #temp2
from  #tempcockpitdowndata
Select * from #Temp2
/*
declare @strsql as nvarchar(4000)
declare @TimeFormat as nvarchar(50)
SELECT @TimeFormat = ''
SELECT @TimeFormat = (SELECT  ValueInText  FROM CockpitDefaults WHERE Parameter = 'TimeFormat')
if (ISNULL(@TimeFormat,'')) = ''
	SELECT @TimeFormat = 'ss'
SELECT @strsql = 'SELECT SerialNo,StartTime,EndTime,OperatorID,OperatorName,DownID,DownDescription,'
if (@TimeFormat = 'hh:mm:ss'or @TimeFormat = 'hh' or @TimeFormat = 'mm' or @TimeFormat = 'ss' )
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(DownTime,''' + @TimeFormat + ''') as DownTime , '
SELECT @strsql =  @strsql  + 'Remarks,id,DownTime as SortDownTime From #TempCockpitDownData order by SerialNo'
--print @strsql
EXEC (@strsql)
*/
END
