/****** Object:  Procedure [dbo].[s_GetComponentList]    Committed by VersionSQL https://www.versionsql.com ******/

/********************************************************************************************************************
--DR0070 changed BY shilpa 16 nov 07 to cast interfaceid as integer.
--mod 1 :- ER0181 By Kusuma M.H on 19-May-2009.2) Modify all the procedures accordingly. Qualify machine wherever we are making use of component and opeartion no.
--mod 2 :- ER0182 By Kusuma M.H on 19-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
--mod 3 :- ER0193 by Kusuma M.H on 27-Aug-2009.2)CO list report:Order by Operation interface id and machine id.Now, the same opn repeats for different machines – these records should appear together.
--mod 4 :- ER0227 By karthikG 0n 10-may-2010. Increase the size of Component InterfaceID from 4 to 16.
--ER0384 - SwathiKS - 04/Jul/2014 :: To include Machine Filter.
--[dbo].[s_GetComponentList] '','','','componentid','excel report'
********************************************************************************************************************/
CREATE       PROCEDURE [dbo].[s_GetComponentList]
@customerid nvarchar(50)='',
@componentid nvarchar(50)='',
@orderby nvarchar(50)='',
@Machineid nvarchar(50)='', --ER0384
@ReportType nvarchar(50)='' --ER0384
AS
BEGIN
---mod 1
---Increased the size of the string to support unicode characters.
--Declare @strsql nvarchar(1000)
Declare @strsql nvarchar(4000)
Declare @strmachine as nvarchar(4000) --ER0384 

 --ER0384 From Here
select @strsql=''
select @strmachine = ''
if isnull(@machineid,'')<> ''
begin
	SET @strMachine = ' AND M.MachineID = N''' + @machineid + ''''
end
 --ER0384 Till Here

If @ReportType='' or @ReportType='Crystal Report' --ER0384
begin --ER0384

		---mod 1
		select @strsql = 'SELECT componentinformation.componentid as componentid,'
		select @strsql = @strsql + 'componentinformation.interfaceid as componentinterfaceid,'
		select @strsql = @strsql + 'componentinformation.customerid as customerid,'
		select @strsql = @strsql + 'componentoperationpricing.operationno as operationno,'
		select @strsql = @strsql + 'componentoperationpricing.interfaceid as operationinterfaceid,'
		select @strsql = @strsql + 'componentoperationpricing.description as description,'
		select @strsql = @strsql + 'componentoperationpricing.machineid as machineid,'
		select @strsql = @strsql + 'componentoperationpricing.cycletime as cycletime,'
		select @strsql = @strsql + 'componentoperationpricing.price as price,'
		select @strsql = @strsql + 'componentoperationpricing.drawingno as drawingno,
		(componentoperationpricing.cycletime-componentoperationpricing.MachiningTime)AS LoadUnload,
				componentoperationpricing.Loadunload AS LUThreshold'
		select @strsql = @strsql + ' FROM componentinformation INNER JOIN componentoperationpricing ON componentinformation.componentid = componentoperationpricing.componentid '
		---mod 1
		select @strsql = @strsql + ' inner join machineinformation M on M.machineid = componentoperationpricing.machineid '
		select @strsql = @strsql + @strMachine --ER0384
		---mod 1
		if isnull(@customerid, '') <> '' and isnull(@componentid, '') = ''
		begin
		---mod 2
		--	select @strsql = @strsql + 'WHERE ' + '(customerid ='''+ @customerid +''')'
		select @strsql = @strsql + 'WHERE ' + '(customerid =N'''+ @customerid +''')'
		---mod 2
		end
		if isnull(@customerid, '') = '' and isnull(@componentid, '') <> ''
		begin
		---mod 2
		--	select @strsql = @strsql + 'WHERE ' + '(componentinformation.componentid ='''+@componentid +''')'
		select @strsql = @strsql + 'WHERE ' + '(componentinformation.componentid =N'''+@componentid +''')'
		---mod 2
		end
		if isnull(@customerid, '') <> '' and isnull(@componentid, '') <> ''
		begin
		---mod 2
		--	select @strsql =@strsql + 'WHERE ' + '(customerid ='''+ @customerid +''') AND (componentinformation.componentid ='''+@componentid +''')'
		select @strsql =@strsql + 'WHERE ' + '(customerid =N'''+ @customerid +''') AND (componentinformation.componentid =N'''+@componentid +''')'
		---mod 2
		end


		If @orderby='componentid'
		begin
		--mod 3
		--	select @strsql = @strsql + 'order by  componentinformation.componentid asc'
		select @strsql = @strsql + 'order by  componentinformation.componentid,componentoperationpricing.interfaceid,componentoperationpricing.machineid asc'
		--mod 3
		end
		if @orderby='interfaceid'
		begin
		--mod 3
		--	select @strsql = @strsql + 'order by cast(componentinformation.interfaceid as integer) asc'
		--ER0227 By karthikG 0n 10-may-2010
		--select @strsql = @strsql + 'order by cast(componentinformation.interfaceid as integer),componentoperationpricing.interfaceid,componentoperationpricing.machineid asc'
		select @strsql = @strsql + 'order by cast(componentinformation.interfaceid as bigint),componentoperationpricing.interfaceid,componentoperationpricing.machineid asc'
		--ER0227 By karthikG 0n 10-may-2010
		--mod 3
		end
		EXEC(@strsql)
		Print @strsql

end --ER0384

--ER0384 From Here
If @ReportType='Excel Report'
begin

	select @strsql = 'SELECT componentinformation.componentid as componentid,'
	select @strsql = @strsql + 'componentinformation.interfaceid as componentinterfaceid,'
	select @strsql = @strsql + 'componentinformation.customerid as customerid,'
	select @strsql = @strsql + 'componentinformation.description as Compdescription,'
	select @strsql = @strsql + 'componentoperationpricing.operationno as operationno,'
	select @strsql = @strsql + 'componentoperationpricing.interfaceid as operationinterfaceid,'
	select @strsql = @strsql + 'componentoperationpricing.description as Opndescription,'
	select @strsql = @strsql + 'componentoperationpricing.machineid as machineid,'
	select @strsql = @strsql + 'componentoperationpricing.cycletime as cycletime,'
	select @strsql = @strsql + 'componentoperationpricing.MachiningTime as MachiningTime,
	(componentoperationpricing.cycletime-componentoperationpricing.MachiningTime)AS LoadUnload '
	select @strsql = @strsql + ' FROM componentinformation INNER JOIN componentoperationpricing ON componentinformation.componentid = componentoperationpricing.componentid '
	select @strsql = @strsql + ' inner join machineinformation M on M.machineid = componentoperationpricing.machineid '
	select @strsql = @strsql + @strMachine --ER0384

	if isnull(@customerid, '') <> '' and isnull(@componentid, '') = ''
	begin
	select @strsql = @strsql + 'WHERE ' + '(customerid =N'''+ @customerid +''')'
	end

	if isnull(@customerid, '') = '' and isnull(@componentid, '') <> ''
	begin
	select @strsql = @strsql + 'WHERE ' + '(componentinformation.componentid =N'''+@componentid +''')'
	end

	if isnull(@customerid, '') <> '' and isnull(@componentid, '') <> ''
	begin
	select @strsql =@strsql + 'WHERE ' + '(customerid =N'''+ @customerid +''') AND (componentinformation.componentid =N'''+@componentid +''')'
	end

	If @orderby='componentid'
	begin
	select @strsql = @strsql + 'order by  componentoperationpricing.machineid ,componentinformation.componentid,componentoperationpricing.interfaceid asc'
	End

	if @orderby='interfaceid'
	begin
	select @strsql = @strsql + 'order by componentoperationpricing.machineid ,cast(componentinformation.interfaceid as bigint),componentoperationpricing.interfaceid asc'
	end
	EXEC(@strsql)
	Print @strsql
end
--ER0384 Till Here


END
