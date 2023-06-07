/****** Object:  Procedure [dbo].[s_GetOperationPricing]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE   PROCEDURE [dbo].[s_GetOperationPricing]
	@MachineID as nvarchar(50) = '',
	@ComponentID as nvarchar(50) = '',
	@MachineIDLabel as nvarchar(50) = 'ALL',
	@ComponentIDLabel as nvarchar(50) = 'ALL'
AS
BEGIN
declare @strsql nvarchar(2000)
declare @strmachine nvarchar(255)
declare @stroperator nvarchar(255)
select @strsql = ''
select @strsql = 'SELECT componentoperationpricing.componentid AS ComponentID,
	componentoperationpricing.operationno AS OperationNo,
	componentoperationpricing.cycletime AS CycleTime,
	componentoperationpricing.price AS OperationPrice,
	machineinformation.machineid AS MachineID,
	machineinformation.mchrrate AS MachineHourRate,
	machineinformation.mchrrate * componentoperationpricing.cycletime / 3600 AS ExpectedPrice,
	componentoperationpricing.price - machineinformation.mchrrate * componentoperationpricing.cycletime / 3600 AS Difference,'''
select @strsql = @strsql + @MachineIDLabel + ''' as MachineIDLabel,'''
select @strsql = @strsql + @ComponentIDLabel + ''' as ComponentIDLabel FROM '
select @strsql = @strsql + 'componentoperationpricing INNER JOIN machineinformation ON
	componentoperationpricing.machineid = machineinformation.machineid'
if isnull(@machineid,'') <> '' and isnull(@componentid,'') = ''
	begin
	select @strsql = @strsql + ' WHERE ( componentoperationpricing.machineid = ''' + @MachineID+ ''')'
	end
if isnull(@componentid, '') <> '' and isnull(@machineid,'') = ''
	begin
	select @strsql = @strsql + ' WHERE ( componentoperationpricing.componentid = ''' + @ComponentID+ ''')'
	end
if isnull(@componentid, '') <> '' and isnull(@machineid,'') <> ''
	begin
	select @strsql = @strsql + ' WHERE ( componentoperationpricing.componentid = ''' + @ComponentID+ ''')'
	select @strsql = @strsql + ' AND ( componentoperationpricing.machineid = ''' + @MachineID+ ''')'	
	end
exec (@strsql)
/*
WHERE
	(componentoperationpricing.componentid LIKE '%'+@ComponentID+'%')
	AND
	(componentoperationpricing.machineid LIKE '%'+@MachineID+'%')
*/
/*
SELECT
	componentoperationpricing.componentid AS ComponentID,
	componentoperationpricing.operationno AS OperationNo,
	componentoperationpricing.cycletime AS CycleTime,
	componentoperationpricing.price AS OperationPrice,
	machineinformation.machineid AS MachineID,
	machineinformation.mchrrate AS MachineHourRate,
	machineinformation.mchrrate * componentoperationpricing.cycletime / 3600 AS ExpectedPrice,
	componentoperationpricing.price - machineinformation.mchrrate * componentoperationpricing.cycletime / 3600 AS Difference,
	@MachineIDLabel as MachineIDLabel,
	@ComponentIDLabel as ComponentIDLabel
FROM
	componentoperationpricing
		INNER JOIN
	machineinformation
		ON
	componentoperationpricing.machineid = machineinformation.machineid
WHERE
	(componentoperationpricing.componentid LIKE '%'+@ComponentID+'%')
	AND
	(componentoperationpricing.machineid LIKE '%'+@MachineID+'%')
*/
END
