/****** Object:  Procedure [dbo].[s_GetExportToHMIData]    Committed by VersionSQL https://www.versionsql.com ******/

-- [dbo].[s_GetExportToHMIData] '''cm-02''',''ACE-02'',''ACE-03'',''ACE-04'',''ACE-05'',''ACE-06'',''ACE-07'',''ACE-08'''
CREATE   PROCEDURE [dbo].[s_GetExportToHMIData]
	@MachineID as NvarChar(4000),
	@datatype as int =1

AS
BEGIN

Declare @strMachine as nvarchar(4000) --DR0302 Added
DECLARE @STRSQL AS nvarchar(4000)

if isnull(@MachineID,'')<> ''
begin
	SET @strMachine = ' MachineID  in ( ' +  @machineid + ') '
END

create table #Export
(
	MachineID nvarchar(50), 
	datastring varchar(4000), 
	userid nvarchar(50), 
	processedTimeStamp Datetime, 
	createTimeStamp Datetime, 
	dataType int
)

Set @STRSQL = ''
Set @STRSQL = @STRSQL + 'Insert into #Export(MachineID,processedTimeStamp)
SELECT distinct MachineID,''1900-01-01'' FROM exporttohmi where '
Set @STRSQL = @STRSQL + @strMachine
Print @STRSQL
EXEC(@STRSQL)

Update #Export set Datastring=T1.DString,Userid=T1.Userid,processedTimeStamp=T1.PTS,createTimeStamp=T1.CTS,
dataType=T1.Dtype from
( Select T.Machineid,E.Datastring as DString,E.Userid as Userid,E.processedTimeStamp as PTS,T.createTimeStamp as CTS 
  ,E.dataType as Dtype from exporttohmi E inner join
	 (Select Machineid,Max(createTimeStamp) as createTimeStamp from exporttohmi where Datatype = @datatype and isnull(processedTimeStamp,'1900-01-01')='1900-01-01'
	 group by Machineid)T on E.Machineid=T.machineid and E.createTimeStamp=T.createTimeStamp
)T1 inner join #Export on #Export.machineid=T1.machineid


Update #Export set Datastring=T1.DString,Userid=T1.Userid,processedTimeStamp=T1.PTS,createTimeStamp=T1.CTS,
dataType=T1.Dtype from
( Select T.Machineid,E.Datastring as DString,E.Userid as Userid,E.processedTimeStamp as PTS,T.createTimeStamp as CTS 
  ,E.dataType as Dtype from exporttohmi E inner join
	 (Select Machineid,Max(createTimeStamp) as createTimeStamp from exporttohmi where Datatype = @datatype and isnull(processedTimeStamp,'1900-01-01')<>'1900-01-01'
	 group by Machineid)T on E.Machineid=T.machineid and E.createTimeStamp=T.createTimeStamp
)T1 inner join #Export on #Export.machineid=T1.machineid where #Export.processedTimeStamp='1900-01-01 00:00:00.000'

Select * from #Export

END
