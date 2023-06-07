/****** Object:  Procedure [dbo].[S_GetWeightedCycleTime]    Committed by VersionSQL https://www.versionsql.com ******/

/****************************************************************
--NR0070 - KarthikR - 09-Jul-2010 ::New Excel Report to show the Weighted Cycle Time Machinewise
SmartManager - Analysis Report Shift Aggregated Data - Production Report-Machinewise
Format -2   Template - SM_WeightedCycleTime.xls
--S_GetWeightedCycleTime '2009-12-15','',''
*******************************************************************/

CREATE     PROCEDURE [dbo].[S_GetWeightedCycleTime] 

@StartDate Datetime,
@PlantID nvarchar(50)='',
@MachineID nvarchar(50)=''
AS
begin

Declare @strsql nvarchar(4000)
Declare @strMachine nvarchar(255)
Declare @StrPlantID nvarchar(255)
Declare @counter int
select @strsql=''
select @strMachine=''
select @StrPlantID=''

declare @starttime datetime
declare @endtime datetime
Declare @Temp datetime


Create Table #day
(
	PDate nvarchar(50)	
)



create table #AccParts
(
	StartDate nvarchar(50),
	ShiftName nvarchar(2),
	Cylinder bigint default(0),
	AcceptedParts bigint default(0)

)

if isnull(@PlantID,'')<>''
begin
select @StrPlantID=' AND (PlantMachine.PlantID =N'''+@PlantID+''')'
end

if isnull(@MachineID,'')<>''
begin
select @strmachine=' AND (Machineinformation.machineid =N'''+@MachineID+''')'
end

	select @starttime = convert(nvarchar(25),+'1-'+datename(mm,@startdate)+'-'+datename(yy,@startdate))
	set @startdate= @starttime
	set @endtime = dateadd(dd,-1,dateadd(mm,1,@starttime))
	set @temp=@starttime

	while @temp <=@endtime
	Begin
		Insert Into #day select  @temp
		set @temp= DateAdd(d,1,@temp)	
	End

	
	insert into #AccParts(StartDate,ShiftName,cylinder)
         select #day.PDate,T1.Shift,T2.cylinder from (select distinct Shift from shiftproductiondetails where componentid like '%SHFT-[0-9][0-9]-%' or componentid like '%SHFT-[0-9]-%')  as T1 
	
	cross join #day  cross join
	(select distinct substring(componentid,(charindex('shft-',componentid)+5),((charindex('-',componentid,(charindex('shft-',componentid)+5)))- (charindex('shft-',componentid)+5))) as Cylinder  from shiftproductiondetails where componentid like '%SHFT-[0-9][0-9]-%' or componentid like '%SHFT-[0-9]-%') as T2

 /*select * from #AccParts
return*/

	Select @Strsql = 'Update #AccParts Set AcceptedParts = ISNULL(T2.AcceptedParts,0)'
	Select @Strsql = @Strsql+ ' From('
	Select @Strsql = @Strsql+ ' Select pDate,Shift,substring(componentid,(charindex(''' + 'shft-'+''',componentid)+5),((charindex('''+'-'+''',componentid,(charindex('''+'shft-'+''',componentid)+5)))- (charindex('''+'shft-'+''',componentid)+5))) as Cyl,Sum(ISNULL(AcceptedParts,0))AcceptedParts'
	Select @Strsql = @Strsql+ ' From ShiftProductionDetails '
	select @strsql = @strsql + ' left outer join  machineinformation on machineinformation.machineid =ShiftproductionDetails.machineid '
	select @strsql = @strsql + ' left outer join PlantMachine on PlantMachine.plantID=ShiftproductionDetails.plantID and machineinformation.machineid= PlantMachine.machineid'
	Select @Strsql = @Strsql+ ' Where componentid like ''' +'%SHFT-[0-9][0-9]-%'+''' or componentid like '''+'%SHFT-[0-9]-%'+'''And pDate>='''+convert(nvarchar(25),@starttime,120)+''' and
		 pDate<='''+convert(nvarchar(25),@Endtime,120)+''''
	Select @Strsql = @Strsql+  @StrPlantID + @Strmachine
	Select @Strsql = @Strsql+ ' GROUP By pDate,shift,componentid'
	Select @Strsql = @Strsql+ ' )As T2 right outer join #AccParts ON #AccParts.StartDate=T2.pDate And #AccParts.cylinder=T2.cyl and #AccParts.ShiftName = T2.Shift'
	Print @Strsql
	Exec(@Strsql)





	--select StartDate,ShiftName,convert(nvarchar,Cylinder)+'Cyl'as Cylinder,Acceptedparts from #AccParts order by StartDate,ShiftName,Cylinder
         select StartDate,ShiftName,Cylinder,Acceptedparts from #AccParts order by StartDate,ShiftName,Cylinder



end
