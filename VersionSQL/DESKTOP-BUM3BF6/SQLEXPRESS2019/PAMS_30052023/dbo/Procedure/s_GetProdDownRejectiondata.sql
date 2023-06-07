/****** Object:  Procedure [dbo].[s_GetProdDownRejectiondata]    Committed by VersionSQL https://www.versionsql.com ******/

--select * from autodata
--exec [s_GetProdDownRejectiondata] @StartTime='2017-01-17 10:13:00',@EndTime='2017-02-17 10:13:00',@machineid=N'23',@Component=N'',@operation=N'',@Operator=N'',@DownCode=N'',@Plantid=N'',@Datatype=N'Production Data',@param=N'Operator'
CREATE PROCEDURE    [dbo].[s_GetProdDownRejectiondata]
	@Plantid nvarchar(50)='',
	@Machineid nvarchar(50)='',
	@Component nvarchar(50) ='',
	@operation nvarchar(50)='',
	@Operator nvarchar(50) ='',
	@DownCode nvarchar(50)='',
	@StartTime datetime ='',
	@EndTime datetime ='',
	@Datatype nvarchar(50)='',
	@param nvarchar(50)=''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


if (@param ='Component' and  @Datatype ='')
BEGIN
Select distinct ci.interfaceid,ci.interfaceid + ' <'+ ci.ComponentId +'>' as result from componentinformation ci  inner join 
componentoperationpricing cop on rtrim(ltrim(ci.componentid)) = rtrim(ltrim(cop.componentid)) 
where cop.machineid = @machineid and ci.interfaceid is not null and cop.interfaceid is not null order by ci.interfaceid
END

if (@param ='Operation' and  @Datatype ='')
BEGIN
select distinct a.interfaceid as interfaceid ,a.componentid,a.interfaceid + ' <'+ CAST( a.operationno as nvarchar(20)) +'>'  as result From componentoperationpricing
 A inner join ( select B.componentid from componentinformation B where
 B.interfaceid=@Component
 ) t2
 on A.componentid = t2.componentid where a.interfaceid IS NOT NULL and
 A.machineid = @Machineid
END


if(@param='Downid' and  @Datatype ='')
BEGIN
select distinct interfaceid ,DownId, interfaceid +' <'+ downid +'>' as result from downcodeinformation where interfaceid is not null order by interfaceid
END


if(@param ='Operator' and  @Datatype ='')
BEGIN
select distinct e.interfaceid as interfaceid,p.employeeid as Employeeid,e.interfaceid +' <' +  p.employeeid + '>' as result from employeeinformation e 
        inner join Plantemployee p on e.employeeid=p.employeeid  where (p.plantID=@plantid or @plantid ='') order by interfaceid
END

if(@param ='Rejection')
BEGIN
select distinct interfaceid,rejectionid,interfaceid +' <'+ rejectionid +'>' as result from rejectioncodeinformation where rejectionid is not null order by rejectionid
END

if(@param='ProdWorkOrder')
BEGIN
select distinct WorkOrderNumber as result from autodata where mc=@Machineid and sttime >= @StartTime and ndtime <= @EndTime and  datatype= 1  
END


if(@param='DownWorkOrder')
BEGIN
select distinct WorkOrderNumber as result from autodata where mc=@Machineid and sttime >= @StartTime and ndtime <= @EndTime and  datatype= 2
END


if(@param ='PartsCount')
BEGIN
select distinct partscount as result from autodata where  mc=@Machineid and  comp=@Component and opn=@operation and datatype=1 and sttime >=@StartTime and ndtime <=@EndTime 
END

if(@param = 'FromComponentForPartsCount')
BEGIN
select distinct comp as result from autodata where  mc= @Machineid and  datatype=1  and 
sttime >=@StartTime and
 ndtime <= @endTime and comp is not null order by comp
 END


 if(@param = 'FromOpnForPartsCount')
 BEGIN
select distinct opn  as result from autodata  where  comp=@Component and mc=@Machineid and  
datatype=1 and sttime >= @StartTime and
ndtime <= @EndTime  and opn is not null order by opn
 END


 if(@param = 'Operator' and @Datatype ='Production Data')
BEGIN
	select distinct opr  as result from autodata where  mc=@machineid and  datatype= 1  and
	sttime >= @StartTime and
	ndtime <= @EndTime  and opr is not null order by opr
END


if(@param = 'Operator' and @Datatype ='Down Data')
BEGIN
	select distinct opr as result from autodata where  mc=@machineid and  datatype=2  and
	sttime >= @StartTime and
	ndtime <= @EndTime  and opr is not null order by opr
END

if(@param = 'Operator' and @Datatype ='Rejection Data')
BEGIN
select distinct opr as result from AutodataRejections where  mc=@Machineid and createdts between @StartTime and  @EndTime and opr is not null order by opr
END

 if(@param = 'Comp' and @Datatype ='Production Data')
BEGIN
	select distinct comp  as result from autodata  where   mc=@Machineid and  datatype=1 and 
	sttime >=@StartTime and ndtime <= @EndTime  and comp is not null order by comp
END

if(@param = 'Comp' and @Datatype ='Down Data')
BEGIN
	select distinct comp  as result from autodata  where   mc=@Machineid and  datatype=2 and 
	sttime >=@StartTime and ndtime <= @EndTime  and comp is not null order by comp
END

if(@param = 'Comp' and @Datatype ='Rejection Data')
BEGIN
select distinct comp as result from AutodataRejections where  mc=@Machineid and createdts between @StartTime and @EndTime and comp is not null order by comp
END

 if(@param = 'Opn' and @Datatype ='Production Data')
BEGIN
	select distinct opn  as result from autodata  where  comp=@Component and mc=@Machineid and  datatype=1 and 
	sttime >=@StartTime and ndtime <= @EndTime  and opn is not null order by opn
END


if(@param = 'Opn' and @Datatype ='Down Data')
BEGIN
	select distinct opn  as result from autodata  where  comp=@Component and mc=@Machineid and  datatype=2 and 
	sttime >=@StartTime and ndtime <= @EndTime  and opn is not null order by opn
END

if(@param = 'Opn' and @Datatype ='Rejection Data')
BEGIN
select distinct opr  as result from AutodataRejections where  mc=@Machineid and createdts between @StartTime and  @EndTime and opr is not null order by opr
END

if(@param = 'DownID' and @Datatype ='Down Data')
BEGIN
select distinct dcode as result from autodata  where  mc=@Machineid and datatype= 2 and sttime >= @StartTime and ndtime <= @EndTime and dcode is not null order by dcode
END


if(@param = 'Rejection' and @Datatype ='Rejection Data')
BEGIN
select distinct rejection_code as result  from AutodataRejections  where  mc=@Machineid and
createdts between @StartTime and @EndTime
and rejection_code is not null order by rejection_code
END


END
