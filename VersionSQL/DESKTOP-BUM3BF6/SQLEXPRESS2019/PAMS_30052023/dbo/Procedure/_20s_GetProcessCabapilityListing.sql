/****** Object:  Procedure [dbo].[ s_GetProcessCabapilityListing]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE          PROCEDURE [dbo].[ s_GetProcessCabapilityListing]
@customerid as nvarchar(50)='',
@componentid as nvarchar(50)='',
@FromDate as smalldatetime = '01/01/1999' output,
@ToDate as smalldatetime = '06/01/2004' output 
AS
BEGIN
Declare @strsql nvarchar(1000)
select @strsql = 'select testid, testdate, customerid, componentid, parameter, instrument, machineid, employeeid, usl, lsl, noofobs, groupsize, histinterval, result, pp, ppk, cp, cpk, s1, s2, rbar, xdbar, avgucl, avglcl, rngucl, rnglcl,''' + convert(nvarchar(20),@FromDate) + ''' as FromDate,''' + convert(nvarchar(20),@ToDate) + ''' as ToDate' + ' from processcapabilityheader  '

if isnull(@customerid, '') <>'' and isnull(@componentid, '') = ''
	begin
	select @strsql = @strsql + 'WHERE ' + '(customerid ='''+ @customerid +''') and (testdate >=''' + convert(nvarchar(20),@FromDate) + ''') AND( testdate<=''' + convert(nvarchar(20),@ToDate) + ''')'
	end
if isnull(@customerid, '') = '' and isnull(@componentid, '') <> ''
	begin
	select @strsql = @strsql + 'WHERE ' + '(componentid ='''+@componentid +''')and (testdate >=''' + convert(nvarchar(20),@FromDate) + ''') AND (testdate<=''' + convert(nvarchar(20),@ToDate) + ''')'
	end
if isnull(@customerid, '') <> '' and isnull(@componentid, '') <> ''
	begin
	select @strsql =@strsql + 'WHERE ' + '(customerid ='''+ @customerid +''') AND (componentid ='''+@componentid +''') and (testdate >=''' + convert(nvarchar(20),@FromDate) + ''') AND( testdate<=''' + convert(nvarchar(20),@ToDate) + ''')'
	end
if isnull(@customerid,'') = '' AND isnull( @componentid,'')=''
BEGIN
select @strsql =@strsql + 'WHERE ' + '(testdate >=''' + convert(nvarchar(20),@FromDate) + ''') AND( testdate<=''' + convert(nvarchar(20),@ToDate) + ''')'
END
select @strsql = @strsql + ' order by componentid asc'
EXEC(@strsql)
--Print @strsql
return
END
