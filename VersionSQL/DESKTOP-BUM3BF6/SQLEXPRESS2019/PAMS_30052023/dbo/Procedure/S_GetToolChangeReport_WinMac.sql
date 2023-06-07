/****** Object:  Procedure [dbo].[S_GetToolChangeReport_WinMac]    Committed by VersionSQL https://www.versionsql.com ******/

/***************************************************************************************
-- Author:	Anjana C V
-- Create date: 22 March 2019
-- Modified date: 22 March 2019
-- Description:  Get Tool Change Report for WinMac
-- [S_GetToolChangeReport_WinMac] '2019-03-01 06:00:00 AM','2019-03-24 06:00:00 AM','WELDER-1','LP LINE-1','ACE1092SP','65'
-- [S_GetToolChangeReport_WinMac] '2019-03-01 06:00:00 AM','2019-03-24 06:00:00 AM','WELDER-1'
select * from plantmachine
**************************************************************************************/

CREATE Procedure [dbo].[S_GetToolChangeReport_WinMac]
@Starttime datetime,
@Endtime datetime,
@Machineid nvarchar(50),
@PlantID nvarchar(50) = '',
@CompID nvarchar(50) = '',
@Opn nvarchar(50) = ''
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

declare @strsql nvarchar(4000)
DECLARE @StrPlantID nvarchar(500)
DECLARE @StrComp nvarchar(500)
DECLARE @StrOpn nvarchar(500)

CREATE TABLE #Target  
 ( 
 PlantId  nvarchar(50) ,
 MachineID nvarchar(50) ,
 machineinterface nvarchar(50),
 ComponentID nvarchar(50) ,
 ComponentName nvarchar(50) ,
 Componentinterface nvarchar(50),
 OperationId nvarchar(50) ,
 OperationInterface nvarchar(50),
-- OperationDescription nvarchar(50),
 ToolNumber int,
 ToolDescription  nvarchar(200),
 Edge  nvarchar(50),
 Ddate datetime,
 Actual INT,
 Target INT
 )

select @StrPlantID = ''
select @StrComp = ''
select @StrOpn = ''

print '----start----'
if isnull(@PlantID,'') <> ''
	begin
	 select @StrPlantID = ' and ( P.PlantID = N''' + @PlantID + ''' )'
	end

if isnull(@CompID,'') <> ''
	begin
	select @strcomp= ' and ( C.componentid = N''' + @CompID + ''')'
	end

if isnull(@Opn,'') <> ''
	begin
	select @StrOpn= ' and ( COP.operationno = N''' + @Opn + ''')'
	end

print '----INSERT INTO #Target ----'
Select @strsql=''
select @strsql =' INSERT INTO #Target (PlantId,MachineID,machineinterface,ComponentID,ComponentName,Componentinterface,OperationId,
  OperationInterface,ToolNumber,ToolDescription,Edge,Ddate,Actual,Target)
  SELECT P.PLANTID ,M.Machineid,M.InterfaceID,C.componentid,C.Description,C.InterfaceID,COP.operationno,COP.InterfaceID,
  A.DetailNumber ,T.ToolDescription , A.SequenceNo , A.Starttime , A.ToolActual , A.ToolTarget 
  FROM AutodataDetails A
  Inner join machineinformation M on A.Machine = M.InterfaceID
  inner join PlantMachine P on P.MachineID = M.machineid 
  Inner join componentinformation C on A.CompInterfaceID = C.InterfaceID
  Inner Join componentoperationpricing COP on A.OpnInterfaceID = COP.InterfaceID 
  and M.machineid = COP.machineid and C.componentid = COP.componentid
  Inner Join  ToolSequence T on T.MachineID = M.Machineid and T.ComponentID = C.componentid
  and T.OperationNo = COP.operationno and T.ToolNo = A.DetailNumber 
  WHERE M.machineid = '''+ @Machineid +''' and (A.Starttime >= '''+ convert(nvarchar(25),@Starttime,120) +''' and A.Starttime <= '''+  convert(nvarchar(25),@Endtime,120) +''' ) '

select @strsql = @strsql +  @StrPlantID + @strcomp + @StrOpn

print @strsql
exec (@strsql)
print '----SELECT * from #Target----'
 SELECT * from #Target  ORDER BY PlantId,MachineID,ComponentID,OperationId,ToolNumber,Edge,Ddate
 END
