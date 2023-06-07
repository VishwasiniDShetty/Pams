/****** Object:  Procedure [dbo].[s_GetLookups_Focas]    Committed by VersionSQL https://www.versionsql.com ******/

/********************************************
ER0346:: Created on : 8th Jan 2013 By Geetanjali Kore :: Lookup for master tables
s_GetLookups 'opn','CNC-15','','LA25BWD03-LKD'
S_GetLookUps 'Machine','CNC SHOP1','asc','','SIEMENS'
*******************************************/
CREATE procedure [dbo].[s_GetLookups_Focas]
 @name nvarchar(50),--Plant,Machine,AlarmCategory,PredefinedTimePeriod,Comp,operation
 @filter nvarchar(100)='',
 @order varchar(5)='asc',
 @filter1 nvarchar(50)='',
 @ControllerType nvarchar(50)=''
as
begin
declare @strsql nvarchar(4000)
Create table #shift (shiftname nvarchar(50))

if @name='Plant' 
begin
SET @strsql = ''
SET @strsql = 'Select distinct pm.Plantid from plantmachine pm inner join machineinformation mi
	on   pm.machineid=mi.machineid and  DNCTransferEnabled=1 order by pm.plantid '
SET @strsql = @strsql + @order
EXEC (@strsql)
END

IF @name = 'Machine'
  AND @filter = ''
BEGIN
SET @strsql = ''
SET @strsql = 'select Machineid from machineinformation where  DNCTransferEnabled=1 order by machineid '
SET @strsql = @strsql + @order
print(@strsql)
EXEC (@strsql)
END

IF @name = 'Machine'
  AND @filter <> ''
BEGIN
--set @strsql=''
--set   @strsql='Select mi.Machineid from plantmachine pm inner join machineinformation mi
--on   pm.machineid=mi.machineid and  tpmtrakenabled=1 and pm.plantid='
--set @strsql= @strsql +''''+@filter+''''
--set @strsql= @strsql+' order by mi.machineid '
--set @strsql= @strsql + @order
--exec(@strsql)
IF (@order = 'asc')
BEGIN
SELECT
  mi.Machineid
FROM plantmachine pm
INNER JOIN machineinformation mi
  ON pm.Machineid = mi.Machineid
    AND DNCTransferEnabled = 1
    AND (pm.plantid = @filter
      OR @filter = '')
    AND (mi.ControllerType = @ControllerType
      OR @ControllerType = '')
ORDER BY mi.Machineid ASC
END
ELSE
BEGIN
SELECT
  mi.Machineid
FROM plantmachine pm
INNER JOIN machineinformation mi
  ON pm.Machineid = mi.Machineid
    AND DNCTransferEnabled = 1
    AND (pm.plantid = @filter
      OR @filter = '')
    AND (mi.ControllerType = @ControllerType
      OR @ControllerType = '')
ORDER BY mi.Machineid DESC
END

END

IF @name = 'AlarmCategory'
BEGIN
SET @strsql = ''
SET @strsql = 'select Alarmno from  preventivemaster where charindex (''.'',alarmno)=''0'' order by alarmno '
SET @strsql = @strsql + @order
EXEC (@strsql)
END

IF @name = 'PredefinedTimePeriod'
BEGIN
INSERT INTO #shift (shiftname)
  SELECT
    'Today - ' + shiftname AS shiftname
  FROM shiftdetails
  WHERE running = 1
  UNION ALL
  SELECT
    'Today - All'
  UNION ALL
  SELECT
    'Yesterday - ' + shiftname AS shiftname
  FROM shiftdetails
  WHERE running = 1
  UNION ALL
  SELECT
    'Yesterday - All'
SELECT
  *
FROM #shift
END


IF @name = 'Comp'
  AND @filter = ''
BEGIN
SET @strsql = ''
SET @strsql = 'select distinct C.Componentid from componentoperationpricing C inner join Machineinformation M on M.machineid=C.machineid  inner join PlantMachine P on P.MachineID=M.Machineid where  M.DNCTransferEnabled=1'
SET @strsql = @strsql + ' order by C.Componentid '
SET @strsql = @strsql + @order
EXEC (@strsql)
END

IF @name = 'Comp'
  AND @filter <> ''
BEGIN
SET @strsql = ''
SET @strsql = 'select distinct C.Componentid from componentoperationpricing C inner join Machineinformation M on M.machineid=C.machineid inner join PlantMachine P on P.MachineID=M.Machineid  where  M.DNCTransferEnabled=1 and M.Machineid='
SET @strsql = @strsql + '''' + @filter + ''''
SET @strsql = @strsql + ' order by C.Componentid '
SET @strsql = @strsql + @order
EXEC (@strsql)
END

IF @name = 'Opn'
BEGIN

SELECT DISTINCT
  Operationno
FROM componentoperationpricing COP
INNER JOIN Componentinformation CI
  ON COP.componentid = CI.componentid
INNER JOIN machineinformation m
  ON COP.machineid = M.machineid
WHERE (COP.machineid = @filter
OR @filter = '')
AND (COP.componentid = @filter1
OR @filter1 = '')

--set @strsql=''
--set   @strsql='select  distinct Operationno from componentoperationpricing COP inner join  Componentinformation CI on COP.componentid=CI.componentid  inner join machineinformation m on COP.machineid=M.machineid'
--set @strsql= @strsql+' order by COP.Operationno '
--set @strsql= @strsql + @order
--exec(@strsql)
END

IF @name = 'Opn'
  AND @filter <> ''
  AND @filter1 <> ''
BEGIN
SET @strsql = ''
SET @strsql = 'select  distinct Operationno from componentoperationpricing COP inner join  Componentinformation CI on COP.componentid=CI.componentid  inner join machineinformation m on COP.machineid=M.machineid '
SET @strsql = @strsql + ' where COP.machineid=''' + @filter + ''''
SET @strsql = @strsql + 'and COP.componentid= ''' + @filter1 + ''''
SET @strsql = @strsql + ' order by COP.Operationno '
SET @strsql = @strsql + @order
EXEC (@strsql)
END

END
