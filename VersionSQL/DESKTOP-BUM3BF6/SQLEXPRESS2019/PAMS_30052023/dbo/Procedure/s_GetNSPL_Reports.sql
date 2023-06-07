/****** Object:  Procedure [dbo].[s_GetNSPL_Reports]    Committed by VersionSQL https://www.versionsql.com ******/

/******************************************************************************************
Procedure has been restructured by Karthik G on 20-Nov-07 to make it open time period.
mod 1 :- Procedure altered by Mrudula on 07-dec-2007
13-Dec-2007 : Karthik G Procedure altered
ER0108 : 17-Jan-2008 : Karthik G Procedure enhanced to support the report "Load Schedule - Format II"
mod 1 :- DR0168 by Mrudula M. Rao on 27-feb-2009.when @ComparisonParam=LoadReport_FormatII
	then following error comes. Error number:3265
	Item cannot be found in the collection corresponding to the requested name or ordinal  .
	If load schedule for the selected input criteria is not found , procedure is giving different set
	of out put. S
mod 2 :- ER0181 By Kusuma M.H on 12-May-2009.2) Modify all the procedures accordingly. Qualify machine wherever we are making use of component and opeartion no.
mod 3 :- ER0182 By Kusuma M.H on 12-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
mod 4 :- DR0206 By Kusuma M.H on 03-Sep-09. s_GetNSPL_reports was erroring out because the column RowValue was casted as integer instead of float.
DR0258 - KarthikR - 09-Sep-2010 :: To handle Error converting data type nvarchar to float.
				   Smartconsole - SM - Standard Reports - Production Report- Machinewise  Type - Shift Format - II
				   ReportName - SM_NSPL_ShiftwiseComp.rpt
ER0252 - SyedArifM/KarthikR - 15-Sep-2010 :: 1>To Remove the rows when TotalOutput is Zero at MCOO Level.
				      		ReportName - SM_NSPL_ShiftwiseComp.rpt
				    	     2>	Applying NSPL Downs while calculating Shifttarget.
ER0253 - SyedArifM/SwathiKS - 22/sep/2010 :: To Show DownReason from NSPLDowns Table in the Rowheader at the shift level.
DR0259 - KarthikR - 23/Sep/2010 :: To calculate ShiftTarget at Minute Level and also including Machine in the join Condition.
ER0416 - SwathiKS - 08/Sep/2015 :: To include New column o/p% i.e Shiftwise Achieved/ShiftTarget for SKS Accessories.
ER0434 - SwathiKS - 30/May/2016 :: Downime was not reflecting when record of type 3 and 4 and TotalParts=0.
ER0459 - Gopinath A R - 10/Feb/2018 :: Temptables, indices, window functions for speed up

exec s_GetNSPL_Reports '2017-12-01','2017-12-07','','','','Shift' --12s
exec s_GetNSPL_Reports '2017-12-01','2017-12-15','','','','Shift' --49s
exec s_GetNSPL_Reports '2017-12-01','2017-12-30','','','','Shift' --215s
***********************************************************************************************/
--This procedure is used in
--Report : LoadReport2Template
--Report : SM_NSPL_ShiftwiseComp
--Report : SM_ShiftProduction_Format3
-- select * from Shopdefaults where Parameter='%IdealTargetCalculation'
-- update Shopdefaults set ValueInText='ByRunTime' where Parameter='%IdealTargetCalculation'
-- update Shopdefaults set ValueInText='ByTotalTime' where Parameter='%IdealTargetCalculation'
CREATE PROCEDURE [dbo].[s_GetNSPL_Reports]
		@StartDate as Datetime,			
		@EndDate as datetime,
		@PlantID nvarchar(50)='',
		@GroupID NVARCHAR(MAX)='',
		@Machine as nvarchar(MAX) = '',
		@ShiftName as nvarchar(20)='',
		@ComparisonParam as nvarchar(20) -- Shift / Week
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


SET NOCOUNT ON

Declare @strsql nvarchar(4000)
Declare @tempStartDate datetime
Declare @tempEndDate datetime
Declare @ShiftStartTime datetime
Declare @ShiftEndTime datetime
declare @Targetsource as nvarchar(50)
Declare @IDcounter as int
select @tempStartDate = @StartDate
select @tempEndDate = @EndDate
declare @maxshiftid as tinyint
declare @strPlantID as nvarchar(250)
declare @StrMachine as nvarchar(MAX)
declare @StrGroupID as nvarchar(max)
declare @StrMCJoined as nvarchar(max)
declare @StrGroupJoined as nvarchar(max)

--------------------------------------------------------used for parts Count and Total output-----------
declare @Date_PT as datetime
declare @FTime_PT as datetime
declare @TTime_PT as datetime
declare @mc as nvarchar(5)
declare @comp as nvarchar(5)
declare @opn as nvarchar(5)
declare @opr_PT as nvarchar(5)
declare @Dreson_PT as nvarchar(50)
declare @rh_PT as nvarchar(50)
declare @rv_PT as nvarchar(50)
Declare @oprID_PT as nvarchar(50)
Declare @shift_PT as nvarchar(50)
--------------------------------------------------------used for parts Count and Total output-----------


Declare @StrTPMMachines AS nvarchar(500) 
SELECT @StrTPMMachines=''

CREATE TABLE #FINALOUTPUT
	(
		[ID] int IDENTITY(1,1),
		[Date] Datetime,
		Shift NvarChar(20),
		Machine NvarChar(50),
		MachineID NvarChar(50),
		Operator NvarChar(50),
		OperatorID NvarChar(50),
		Component NvarChar(50),
		ComponentID NvarChar(50),
		Operation NvarChar(50),
		OperationID NvarChar(50),
		RowHeaderID NvarChar(50),
		ShiftName NvarChar(20),
		StartTime DateTime,
		EndTime DateTime,
		DownReason NvarChar(50),
		IsPartCount bit,
		RowHeader1 NvarChar(50),
		RowHeader2 NvarChar(50),
		RowHeader3 NvarChar(50),
		RowValue NvarChar(50),
		ExceptionRatio float,
		Dflag bit,
		Rowflag Nvarchar(2) --ER0252 - SyedArifM - 15-Sep-2010
		
	)

--ER0459
CREATE TABLE #T_autodata(              
 [mc] [nvarchar](50)not NULL,              
 [comp] [nvarchar](50) NULL,              
 [opn] [nvarchar](50) NULL,              
 [opr] [nvarchar](50) NULL,              
 [dcode] [nvarchar](50) NULL,              
 [sttime] [datetime] not NULL,              
 [ndtime] [datetime] not NULL,              
 [datatype] [tinyint] NULL ,              
 [cycletime] [int] NULL,              
 [loadunload] [int] NULL ,              
 [msttime] [datetime] not NULL,              
 [PartsCount] decimal(18,5) NULL ,              
 id  bigint not null              
)              
              
ALTER TABLE #T_autodata              
ADD PRIMARY KEY CLUSTERED              
(              
 mc,sttime ASC --,ndtime,msttime ASC              
)ON [PRIMARY]    


--Select @strsql=''              
--select @strsql ='insert into #T_autodata '              
--select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'              
-- select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'              
--select @strsql = @strsql + ' from autodata WITH(NOLOCK) where (( sttime >='''+ convert(nvarchar(25),@startdate,120)+''' and ndtime <= '''+ convert(nvarchar(25),@enddate,120)+''' ) OR '              
--select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@startdate,120)+''' and ndtime >'''+ convert(nvarchar(25),@enddate,120)+''' )OR '              
--select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@startdate,120)+''' and ndtime >'''+ convert(nvarchar(25),@startdate,120)+'''              
--     and ndtime<='''+convert(nvarchar(25),@enddate,120)+''' )'              
--select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@startdate,120)+''' and ndtime >'''+ convert(nvarchar(25),@enddate,120)+''' 
--and sttime<'''+convert(nvarchar(25),@enddate,120)+''' ) )'              
--print @strsql            
--print '00:: '+CONVERT(varchar, SYSDATETIME(), 121)  
--exec (@strsql)         
--print '00:: '+CONVERT(varchar, SYSDATETIME(), 121)
--create index idx_tad on #T_Autodata(mc,opr,comp,opn) --g:
--/ER0459
CREATE TABLE #NSPLDOWNS
	(
		FromTime DateTime,
		ToTime DateTime,
		Reason NVarChar(50)		
	)
CREATE TABLE #HeaderDate([Date] Datetime)
CREATE TABLE #HeaderShift(ShiftName NvarChar(50))
CREATE TABLE #HeaderComponent
	(
	Component NvarChar(50),
	ComponentId Nvarchar(50),
	Operation NvarChar(50),
	OperationID NvarChar(50),
	Operator NvarChar(50),
	OperatorID NvarChar(50),
	Machine NvarChar(50),
	MachineID NvarChar(50)
	)
CREATE TABLE #RowHeaderTable([ID] int IDENTITY(1,1),ShiftName NvarChar(50),StartTime Datetime,EndTime Datetime,RowHeader1 NvarChar(50),RowHeader2 NvarChar(50),DownReason NvarChar(50),IsPartCount bit)
CREATE TABLE #GetShiftTime([ID] int IDENTITY(1,1),startdatetime datetime,shiftname NvarChar(50),StartTime datetime,EndTime datetime)--,TotalTime bigint,TotalDownTime bigint)
CREATE TABLE #RowHeaderTable_new
(       [ID] int IDENTITY(1,1),
	[Date] datetime,
	ShiftName NvarChar(50),
	StartTime Datetime,
	EndTime Datetime,
	RowHeader1 NvarChar(50),
	RowHeader2 NvarChar(50),
	DownReason NvarChar(50),
	IsPartCount bit
)

----SV From Here
CREATE TABLE #Target
	(
		id bigint identity(1,1) not null,
		MachineID NvarChar(50),
		MachineInterface nvarchar(50),
		ComponentID Nvarchar(50),
		OperationNo Int,
		sttime Datetime,
		ndtime Datetime,
		hursttime datetime,
		hurndtime datetime,
		shftname nvarchar(20),
		Pdt int,
		batchid int
	)
CREATE TABLE #Target_actime
	(
		MachineID NvarChar(50),
		MachineInterface nvarchar(50),
		ComponentID Nvarchar(50),
		OperationNo Int,
		sttime Datetime,
		ndtime Datetime,
		hursttime datetime,
		hurndtime datetime,
		shftname nvarchar(20),
		Totaltime int	,
		batchid int	
	)
----SV Till Here

select @strmachine=''
select @strPlantID=''
SELECT @StrGroupID=''

IF ( SELECT TOP 1 ValueInText FROM  CockpitDefaults WHERE Parameter='TpmEnbMac')='E'  
BEGIN  
 SET  @StrTPMMachines = ' AND MachineInformation.TPMTrakEnabled = 1 '  
END  
ELSE  
BEGIN  
 SET  @StrTPMMachines = ' '  
END 

If isnull(@Machine,'') <> ''
BEGIN
---mod 3
--	SELECT @strmachine = ' AND ( Machineinformation.machineid = ''' + @Machine+ ''')'
	select @StrMCJoined =  (case when (coalesce( +@StrMCJoined + ',''', '''')) = ''''  then 'N''' else @StrMCJoined+',N''' end) +item+'''' from [SplitStrings](@Machine, ',')    
	if @StrMCJoined = 'N'''''  
	set @StrMCJoined = '' 
	select @Machine = @StrMCJoined

	SELECT @strmachine = ' AND ( Machineinformation.machineid IN (' + @Machine+ '))'
---mod  3
END
IF isnull(@PlantID,'') <> ''
BEGIN
---mod 3
--	SELECT @strPlantID = ' AND ( P.PlantID = ''' + @PlantID+ ''')'
	SELECT @strPlantID = ' AND ( P.PlantID = N''' + @PlantID+ ''')'
--mod 3
END

if isnull(@GroupID,'')<> ''
Begin
	select @StrGroupJoined =  (case when (coalesce( +@StrGroupJoined + ',''', '''')) = ''''  then 'N''' else @StrGroupJoined+',N''' end) +item+'''' from [SplitStrings](@GroupID, ',')    
	if @StrGroupJoined = 'N'''''  
	set @StrGroupJoined = '' 
	select @GroupID = @StrGroupJoined

	SET @strGroupID = ' AND PlantMachineGroups.GroupID in (' + @GroupID +')'
End

while @tempStartDate <= @tempEndDate
BEGIN		
	Insert #HeaderDate select @tempStartDate
	select @tempStartDate = @tempStartDate + 1    			
END
If isnull(@ShiftName,'') <> ''
BEGIN		
	Insert #HeaderShift select @ShiftName	
END
else
BEGIN
	Insert #HeaderShift select ShiftName from shiftdetails where running = 1	
END
	Insert Into #NSPLDowns(FromTime,ToTime,Reason)
	SELECT
	CASE Today
	WHEN 0 THEN convert(datetime, cast(DATEPART(yyyy,@StartDate)as nvarchar(4))+'-'+cast(datepart(mm,@StartDate)as nvarchar(2))+'-'+cast(datepart(dd,@StartDate)as nvarchar(2)) +' '+cast(datepart(hh,FromTime)as nvarchar(2))+':'+cast(datepart(mi,FromTime)as nvarchar(2))+':'+cast(datepart(ss,FromTime)as nvarchar(2))   )
	--ELSE convert(datetime, cast(DATEPART(yyyy,dateadd(dd,1,@StartDate))as nvarchar(4))+'-'+cast(datepart(mm,dateadd(dd,1,dateadd(dd,1,@StartDate)))as nvarchar(2))+'-'+cast(datepart(dd,dateadd(dd,1,@StartDate))as nvarchar(2)) +' '+cast(datepart(hh,FromTime)as nvarchar(2))+':'+cast(datepart(mi,FromTime)as nvarchar(2))+':'+cast(datepart(ss,FromTime)as nvarchar(2))   )
	ELSE convert(datetime, cast(DATEPART(yyyy,dateadd(dd,1,@StartDate))as nvarchar(4))+'-'+cast(datepart(mm,dateadd(dd,1,@StartDate))as nvarchar(2))+'-'+cast(datepart(dd,dateadd(dd,1,@StartDate))as nvarchar(2)) +' '+cast(datepart(hh,FromTime)as nvarchar(2))+':'+cast(datepart(mi,FromTime)as nvarchar(2))+':'+cast(datepart(ss,FromTime)as nvarchar(2))   )
	END,
	CASE Tommorrow
	WHEN 0 THEN  convert(datetime, cast(DATEPART(yyyy,@StartDate)as nvarchar(4))+'-'+cast(datepart(mm,@StartDate)as nvarchar(2))+'-'+cast(datepart(dd,@StartDate)as nvarchar(2)) +' '+cast(datepart(hh,ToTime)as nvarchar(2))+':'+cast(datepart(mi,ToTime)as nvarchar(2))+':'+cast(datepart(ss,ToTime)as nvarchar(2))   )
	--ELSE convert(datetime, cast(DATEPART(yyyy,dateadd(dd,1,@StartDate))as nvarchar(4))+'-'+cast(datepart(mm,dateadd(dd,1,dateadd(dd,1,@StartDate)))as nvarchar(2))+'-'+cast(datepart(dd,dateadd(dd,1,@StartDate))as nvarchar(2)) +' '+cast(datepart(hh,ToTime)as nvarchar(2))+':'+cast(datepart(mi,ToTime)as nvarchar(2))+':'+cast(datepart(ss,ToTime)as nvarchar(2))   )
	ELSE convert(datetime, cast(DATEPART(yyyy,dateadd(dd,1,@StartDate))as nvarchar(4))+'-'+cast(datepart(mm,dateadd(dd,1,@StartDate))as nvarchar(2))+'-'+cast(datepart(dd,dateadd(dd,1,@StartDate))as nvarchar(2)) +' '+cast(datepart(hh,ToTime)as nvarchar(2))+':'+cast(datepart(mi,ToTime)as nvarchar(2))+':'+cast(datepart(ss,ToTime)as nvarchar(2))   )
	END,DownReason From NSPLDowns where flag = '1'

print '01:: '+CONVERT(varchar, SYSDATETIME(), 121)
---Get the shift timings
--select sum(DateDiff(second,#T_Autodata.stTime,  #FINALOUTPUT.EndTime) from #NSPLDowns
--return
Insert #GetShiftTime exec s_GetShiftTime @StartDate,@ShiftName
			
					Declare @TempDate as datetime
					Declare @tempfrom as datetime--
					Declare @tempto as datetime--
					Declare @count as int--
					Declare @H_append as nvarchar(10)
		
		
		select @count = 1
		select @count=[ID] from #GetShiftTime where [ID] = (select min([ID])from #GetShiftTime)
		while @count <= (select max([ID]) from #GetShiftTime)
		Begin
		select @ShiftName = shiftname from #GetShiftTime where [ID] = @count
		-----------------------------------------------------------------------------
			select  @ShiftStartTime = starttime from #GetShiftTime where shiftname = @ShiftName
			select  @ShiftEndTime = endtime from #GetShiftTime where shiftname = @ShiftName
			print @ShiftStartTime		print @ShiftEndTime
			
			Insert #RowHeaderTable (StartTime) Select @ShiftStartTime
			
			While @ShiftEndTime > (Select max(StartTime) from #RowHeaderTable)
			Begin
			
				Select @TempDate = max(StartTime) from #RowHeaderTable
				If (Select count(*) from #NSPLDowns where FromTime >= @TempDate and FromTime <= DateAdd(s,3600,@TempDate)) > 0
				Begin
					Select top 1 @tempfrom = FromTime,@tempto = ToTime from #NSPLDowns where FromTime >= @TempDate and FromTime <= DateAdd(s,3600,@TempDate)
					Update #RowHeaderTable set Endtime = @tempfrom where Endtime is Null
					Insert #RowHeaderTable (StartTime) Select @tempfrom
					Update #RowHeaderTable set Endtime = @tempto where Endtime is Null
					Insert #RowHeaderTable (StartTime) Select @tempto
		--			print 'yes'
				End
				else
				Begin
					Update #RowHeaderTable set Endtime = DateAdd(s,3600,StartTime) where Endtime is Null		
					Insert #RowHeaderTable (StartTime) Select max(EndTime) from #RowHeaderTable
		--			print 'no'
				End
			End	
				
			Delete #RowHeaderTable where StartTime >= @ShiftEndTime
			Delete #RowHeaderTable where StartTime >= EndTime
			Update #RowHeaderTable set EndTime = @ShiftEndTime where EndTime > @ShiftEndTime
			Update #RowHeaderTable set ShiftName = t1.shiftName from
			(select * from #GetShiftTime) as t1 join #RowHeaderTable on #RowHeaderTable.Starttime >= t1.Starttime and #RowHeaderTable.EndTime <= t1.EndTime
		-----------------------------------------------------------------------------
		select @count = @count + 1
		End 		
		
		print '01:: '+CONVERT(varchar, SYSDATETIME(), 121)
		Update #RowHeaderTable Set RowHeader1 =
		Case Len(convert(Nvarchar(2),Datepart(hh,StartTime))) When 1 then '0'+convert(Nvarchar(2),Datepart(hh,StartTime))Else convert(Nvarchar(2),Datepart(hh,StartTime)) End +':'+
		Case Len(convert(Nvarchar(2),Datepart(n,StartTime))) When 1 then '0'+convert(Nvarchar(2),Datepart(n,StartTime))Else convert(Nvarchar(2),Datepart(n,StartTime)) End+' - '+
		Case Len(convert(Nvarchar(2),Datepart(hh,EndTime))) When 1 then '0'+convert(Nvarchar(2),Datepart(hh,EndTime))Else convert(Nvarchar(2),Datepart(hh,EndTime)) End +':'+
		Case Len(convert(Nvarchar(2),Datepart(n,EndTime))) When 1 then '0'+convert(Nvarchar(2),Datepart(n,EndTime))Else convert(Nvarchar(2),Datepart(n,EndTime)) End
			
		select @count = 0
		select @H_append = 1
		while @count <= (select max([ID]) from #RowHeaderTable)
		Begin
			if exists (select * from #RowHeaderTable where [ID]=@count)
			Begin	Update #RowHeaderTable set rowHeader2 = Case len(@H_append) when 1 then '0'+@H_append else @H_append end where [ID]=@count
				select @H_append = @H_append + 1										End	Else
			Begin	select @H_append = 1											End
		select @count = @count + 1
		End
		Update #RowHeaderTable Set DownReason = T1.Reason from
		(select FromTime,ToTime,Reason from #NSPLDowns) as T1 Inner join #RowHeaderTable on T1.FromTime=#RowHeaderTable.StartTime and T1.ToTime=#RowHeaderTable.EndTime
		print '01:: '+CONVERT(varchar, SYSDATETIME(), 121)
		Update #RowHeaderTable set DownReason = 'NoDown' where DownReason is Null
		
		select @count = 1
		select @count=[ID] from #GetShiftTime where [ID] = (select min([ID])from #GetShiftTime)
		while @count <= (select max([ID]) from #GetShiftTime)----------------While Start------------
		Begin
			select @ShiftName = shiftname from #GetShiftTime where [ID] = @count
			Insert #RowHeaderTable (RowHeader1) Select 'Hourly Target'
			Insert #RowHeaderTable (RowHeader1) Select 'Shift Target'
			Insert #RowHeaderTable (RowHeader1) Select 'Down Time'
			Insert #RowHeaderTable (RowHeader1) Select 'Total output'
			Insert #RowHeaderTable (RowHeader1) Select 'Total output (%)' --ER0416

 			Update #RowHeaderTable set ShiftName = @ShiftName where ShiftName is Null
			select @count = @count + 1
		End------------------------------------------------------------------While End-------------- 		
		print '01:: '+CONVERT(varchar, SYSDATETIME(), 121)
		Update #RowHeaderTable set DownReason = 'NoDown' where DownReason is Null
		--Update #RowHeaderTable set IsPartCount = 1 where DownReason = 'NoDown' and RowHeader1 not in ('Hourly Target','Shift Target','Down Time','Total output') --ER0416
		Update #RowHeaderTable set IsPartCount = 1 where DownReason = 'NoDown' and RowHeader1 not in ('Hourly Target','Shift Target','Down Time','Total output','Total output (%)') --ER0416
		Update #RowHeaderTable set IsPartCount = 0 where IsPartCount is null
		Update #RowHeaderTable set StartTime = t1.StartTime,EndTime = t1.EndTime from
		--(Select * from #GetShiftTime) as t1 join  #RowHeaderTable on t1.ShiftName = #RowHeaderTable.ShiftName where RowHeader1 in ('Hourly Target','Shift Target','Down Time','Total output')--ER0416
		(Select * from #GetShiftTime) as t1 join  #RowHeaderTable on t1.ShiftName = #RowHeaderTable.ShiftName where RowHeader1 in ('Hourly Target','Shift Target','Down Time','Total output','Total output (%)') ---ER0416
		print '01:: '+CONVERT(varchar, SYSDATETIME(), 121)
	print 'shiftname Default'
--End		
declare @Max_Date as datetime
declare @Min_Date as datetime
declare @Day_cnt as integer
select @Day_cnt=1
insert into #RowHeaderTable_new
([Date],ShiftName,StartTime ,EndTime ,RowHeader1 ,RowHeader2 ,DownReason ,IsPartCount)
select  @StartDate,ShiftName,StartTime ,EndTime ,RowHeader1 ,
RowHeader2 ,DownReason ,IsPartCount  from #RowHeaderTable
select 	@Min_Date=@StartDate+1		
select @Max_Date=@EndDate
while @Min_Date<=@Max_Date
begin
	insert into #RowHeaderTable_new([Date],ShiftName,StartTime ,EndTime ,RowHeader1 ,RowHeader2 ,DownReason ,IsPartCount)
select @Min_Date,ShiftName,StartTime+@Day_cnt ,EndTime+@Day_cnt,RowHeader1 ,RowHeader2 ,DownReason ,IsPartCount  from #RowHeaderTable
	select @Min_Date=@Min_Date+1
	select @Day_cnt=@Day_cnt+1
end

select 	@Min_Date=(select top 1 StartTime from #RowHeaderTable_new order by StartTime asc )		
select @Max_Date=(select top 1 EndTime from #RowHeaderTable_new order by StartTime desc )

---ER0459
Select @strsql=''              
select @strsql ='insert into #T_autodata '              
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'              
 select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'              
select @strsql = @strsql + ' from autodata WITH(NOLOCK) where (( sttime >='''+ convert(nvarchar(25),@Min_Date,120)+''' and ndtime <= '''+ convert(nvarchar(25),@Max_Date,120)+''' ) OR '              
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@Min_Date,120)+''' and ndtime >'''+ convert(nvarchar(25),@Max_Date,120)+''' )OR '              
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@Min_Date,120)+''' and ndtime >'''+ convert(nvarchar(25),@Min_Date,120)+'''              
     and ndtime<='''+convert(nvarchar(25),@Max_Date,120)+''' )'              
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@Min_Date,120)+''' and ndtime >'''+ convert(nvarchar(25),@Max_Date,120)+''' 
and sttime<'''+convert(nvarchar(25),@Max_Date,120)+''' ) )'              
exec (@strsql)         
create index idx_tad on #T_Autodata(mc,opr,comp,opn) --g:
---ER0459

select @Strsql=''
select @Strsql='Insert #HeaderComponent(ComponentID,Component,OperationID,Operation,OperatorID,Operator,Machine ,MachineID ) select distinct #T_Autodata.comp,componentinformation.Componentid, #T_Autodata.opn,componentoperationpricing.OperationNO,
#T_Autodata.opr,employeeinformation.employeeID,machineinformation.machineID,#T_Autodata.mc
from #T_Autodata  inner join machineinformation on machineinformation.interfaceid=#T_Autodata.mc inner join
componentinformation on #T_Autodata.comp=componentinformation.interfaceid
inner join componentoperationpricing on componentoperationpricing.interfaceid=#T_Autodata.opn and'
---mod 2
select @Strsql = @Strsql + ' componentoperationpricing.machineid=machineinformation.machineid '
---mod 2
select @Strsql=@Strsql +' and componentinformation.componentid=componentoperationpricing.componentid
inner join employeeinformation  on employeeinformation.interfaceid=#T_Autodata.opr
left outer join PlantMachine P on machineinformation.machineid = P.MachineID
 LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = P.PlantID and PlantMachineGroups.machineid = P.MachineID ' --ER0434
--ER0434 From Here commented below line and addded All 4 RecordTypes
--where sttime >= ''' +convert(varchar(20),@Min_Date,120)+ ''' and ndtime <= ''' + convert(varchar(20),@Max_Date,120)+ ''''
select @Strsql=@Strsql +' where
((sttime >= ''' +convert(varchar(20),@Min_Date,120)+ ''' and ndtime <= ''' + convert(varchar(20),@Max_Date,120)+ ''') OR
(sttime < ''' +convert(varchar(20),@Min_Date,120)+ ''' and ndtime > ''' +convert(varchar(20),@Min_Date,120)+ ''' and ndtime <= ''' + convert(varchar(20),@Max_Date,120)+ ''') OR
(sttime >= ''' +convert(varchar(20),@Min_Date,120)+ ''' and sttime < ''' +convert(varchar(20),@Max_Date,120)+ ''' and ndtime > ''' + convert(varchar(20),@Max_Date,120)+ ''') OR
(sttime < ''' +convert(varchar(20),@Min_Date,120)+ ''' and ndtime > ''' + convert(varchar(20),@Max_Date,120)+ '''))'
--ER0434 From Here
select @Strsql=@Strsql+@StrMachine + @StrTPMMachines + @strPlantID + @StrGroupID
exec(@Strsql)


print '02:: '+CONVERT(varchar, SYSDATETIME(), 121)

--INSERT INTO #FINALOUTPUT([Date],Machine,MachineID,Operator,OperatorID,Component,ComponentID,Operation,OperationID,RowHeaderID,ShiftName,StartTime,EndTime,RowHeader1,RowHeader2,DownReason,IsPartCount,Dflag)   --DR0258 - KarthikR - 09-Sep-2010
--INSERT INTO #FINALOUTPUT([Date],Machine,MachineID,Operator,OperatorID,Component,ComponentID,Operation,OperationID,RowHeaderID,ShiftName,StartTime,EndTime,RowHeader1,RowHeader2,RowValue,DownReason,IsPartCount,Dflag)  --ER0252 - SyedArifM - 15-Sep-2010
INSERT INTO #FINALOUTPUT([Date],Machine,MachineID,Operator,OperatorID,Component,ComponentID,Operation,OperationID,RowHeaderID,ShiftName,StartTime,EndTime,RowHeader1,RowHeader2,RowValue,DownReason,IsPartCount,Dflag,Rowflag) --ER0252 - SyedArifM - 15-Sep-2010
Select rht.[Date],c.machine,c.MachineID,c.Operator,c.OperatorID,c.Component,c.ComponentID,c.Operation,
--c.OperationID,rht.[ID],rht.ShiftName,rht.StartTime,rht.EndTime,rht.RowHeader1,rht.RowHeader2, --DR0258 - KarthikR - 09-Sep-2010
c.OperationID,rht.[ID],rht.ShiftName,rht.StartTime,rht.EndTime,rht.RowHeader1,rht.RowHeader2,0,
rht.DownReason,rht.IsPartCount,0,0 from
#HeaderComponent c cross join
#RowHeaderTable_new rht
print '02:: '+CONVERT(varchar, SYSDATETIME(), 121)

--Update #FINALOUTPUT set RowHeader3 = RowHeader1 where RowHeader1 in ('Hourly Target','Shift Target','Down Time','Total output') --ER0416
Update #FINALOUTPUT set RowHeader3 = RowHeader1 where RowHeader1 in ('Hourly Target','Shift Target','Down Time','Total output','Total output (%)') --ER0416
Update #FINALOUTPUT set RowHeader3 = RowHeader2 where RowHeader3 is Null
--Update #FINALOUTPUT set RowValue = t1.Tcount --DR0258 - KarthikR - 09-Sep-2010
Update #FINALOUTPUT set RowValue = isnull(t1.Tcount,0)
From
(
	select CAST(CEILING(CAST(sum(#T_Autodata.partscount)AS Float)/ISNULL(componentoperationpricing.SubOperations,1)) AS INTEGER) as Tcount,
	#FINALOUTPUT.MachineID as machid,#FINALOUTPUT.OperatorID as oprID,#FINALOUTPUT.ComponentID as compID,
	#FINALOUTPUT.OperationID as opnID, #FINALOUTPUT.StartTime as strt,#FINALOUTPUT.EndTime as endt
	from #T_Autodata inner join  #FINALOUTPUT on #T_Autodata.mc=#FINALOUTPUT.MachineID
	and #T_Autodata.opr=#FINALOUTPUT.OperatorID and #T_Autodata.comp= #FINALOUTPUT.ComponentID and
	#T_Autodata.opn= #FINALOUTPUT.OperationID inner join componentinformation on #T_Autodata.comp=componentinformation.interfaceid
	and componentinformation.componentid=#FINALOUTPUT.component
	inner join  componentoperationpricing on componentinformation.componentid=componentoperationpricing.componentid and
	componentoperationpricing.interfaceid=#T_Autodata.opn and componentoperationpricing.operationno=#FINALOUTPUT.operation
	
	---mod 2
	inner join machineinformation on machineinformation.machineid=componentoperationpricing.machineid
	and machineinformation.interfaceid=#FINALOUTPUT.machineid
	---mod 2
	where  (#T_Autodata.ndtime > #FINALOUTPUT.StartTime)AND (#T_Autodata.ndtime <= #FINALOUTPUT.EndTime ) and #FINALOUTPUT.RowHeader3 not in
	--('Hourly Target','Shift Target','Down Time','Total output') --ER0416
	('Hourly Target','Shift Target','Down Time','Total output','Total output (%)') --ER0416
	Group by componentoperationpricing.SubOperations,#FINALOUTPUT.MachineID,#FINALOUTPUT.OperatorID,#FINALOUTPUT.ComponentID,#FINALOUTPUT.OperationID,#FINALOUTPUT.StartTime,#FINALOUTPUT.EndTime
) as T1 inner join
	#FINALOUTPUT on #FINALOUTPUT.StartTime=T1.strt and #FINALOUTPUT.EndTime=T1.endt and
	#FINALOUTPUT.MachineID=T1.machid and #FINALOUTPUT.OperatorID =T1.oprID and #FINALOUTPUT.ComponentID =T1.compID and
	#FINALOUTPUT.OperationID=T1.opnID where  #FINALOUTPUT.RowHeader3 not in
	--('Hourly Target','Shift Target','Down Time','Total output') --ER0416
	('Hourly Target','Shift Target','Down Time','Total output','Total output (%)') --ER0416
	print '021:: '+CONVERT(varchar, SYSDATETIME(), 121)

--Update #FINALOUTPUT set RowValue = T1.Cnt --DR0258 - KarthikR - 09-Sep-2010
create index idx_fin on #FINALOUTPUT(Rowheader3,MachineID,operatorid, componentid, operationid ) --ER0459

Update #FINALOUTPUT set RowValue = isnull(T1.Cnt,0)
from
(select sum(convert(int,RowValue)) as Cnt,T2.StartTime as strt,
T2.EndTime as ndt,T2.MachineID as machid,T2.OperatorID as oprID,T2.ComponentID as compID,
T2.OperationID as opnID from
#FINALOUTPUT inner join (select #FINALOUTPUT.StartTime as Starttime,#FINALOUTPUT.MachineID as MachineID,
#FINALOUTPUT.EndTime as EndTime
,#FINALOUTPUT.OperatorID as OperatorID,#FINALOUTPUT.ComponentID as ComponentID,#FINALOUTPUT.OperationID as OperationID from
#FINALOUTPUT
where RowHeader3='Total output' ) as T2 on #FINALOUTPUT.MachineID=T2.MachineID and #FINALOUTPUT.OperatorID=T2.OperatorID and
#FINALOUTPUT.ComponentID=T2.ComponentID and #FINALOUTPUT.OperationID=T2.OperationID
---where #FINALOUTPUT.StartTime >=T2.StartTime and #FINALOUTPUT.EndTime <= T2.EndTime and IsPartCount = 1 --DR0258 - KarthikR - 09-Sep-2010
where #FINALOUTPUT.StartTime >=T2.StartTime and #FINALOUTPUT.EndTime <= T2.EndTime and (IsPartCount = 1 or isnumeric(rowvalue)=1)
group by T2.StartTime,T2.EndTime,
T2.MachineID,T2.OperatorID,T2.ComponentID,T2.OperationID )
as T1 inner join
#FINALOUTPUT on #FINALOUTPUT.StartTime=T1.strt and #FINALOUTPUT.EndTime=T1.ndt and
#FINALOUTPUT.MachineID=T1.machid and #FINALOUTPUT.OperatorID =T1.oprID and #FINALOUTPUT.ComponentID =T1.compID and
#FINALOUTPUT.OperationID=T1.opnID where #FINALOUTPUT.RowHeader3='Total output'
print '02:: '+CONVERT(varchar, SYSDATETIME(), 121)

--Update #FINALOUTPUT set RowValue = T1.Dtime   --DR0258 - KarthikR - 09-Sep-2010
Update #FINALOUTPUT set RowValue = isnull(T1.Dtime,0)
from
(select
sum(case when (#T_Autodata.sttime>=#FINALOUTPUT.StartTime)
	       and (#T_Autodata.ndtime<=#FINALOUTPUT.EndTime) then (#T_Autodata.loadunload)
	when (#T_Autodata.sttime<#FINALOUTPUT.StartTime)
		and (#T_Autodata.ndtime>#FINALOUTPUT.StartTime)
		and (#T_Autodata.ndtime<= #FINALOUTPUT.EndTime)  then DateDiff(second, #FINALOUTPUT.StartTime, #T_Autodata.ndtime)
	when (#T_Autodata.sttime>=#FINALOUTPUT.StartTime)
		and (#T_Autodata.sttime<#FINALOUTPUT.EndTime)
		and (#T_Autodata.ndtime>#FINALOUTPUT.EndTime)  then DateDiff(second,#T_Autodata.stTime,  #FINALOUTPUT.EndTime)
	when #T_Autodata.sttime<#FINALOUTPUT.StartTime
		and #T_Autodata.ndtime>#FINALOUTPUT.EndTime then DateDiff(second, #FINALOUTPUT.StartTime,  #FINALOUTPUT.EndTime) end )
	as Dtime,#FINALOUTPUT.StartTime as strt,
	#FINALOUTPUT.EndTime as ndt,#FINALOUTPUT.MachineID as machid,#FINALOUTPUT.OperatorID as oprID,#FINALOUTPUT.ComponentID as compID,
	#FINALOUTPUT.OperationID as opnID from #T_Autodata inner join
	#FINALOUTPUT  on #FINALOUTPUT.MachineID=#T_Autodata.mc and #FINALOUTPUT.OperatorID=#T_Autodata.opr and
	#FINALOUTPUT.ComponentID=#T_Autodata.comp and #FINALOUTPUT.OperationID=#T_Autodata.opn
where (((#T_Autodata.sttime>=#FINALOUTPUT.StartTime)
	and (#T_Autodata.ndtime<=#FINALOUTPUT.EndTime))or ((#T_Autodata.sttime<#FINALOUTPUT.StartTime)
	and (#T_Autodata.ndtime>#FINALOUTPUT.StartTime)
	and (#T_Autodata.ndtime<= #FINALOUTPUT.EndTime)) or ((#T_Autodata.sttime>=#FINALOUTPUT.StartTime)
	and (#T_Autodata.sttime<#FINALOUTPUT.EndTime)
	and (#T_Autodata.ndtime>#FINALOUTPUT.EndTime)) or (#T_Autodata.sttime<#FINALOUTPUT.StartTime
	and #T_Autodata.ndtime>#FINALOUTPUT.EndTime) ) and #T_Autodata.datatype=2  and #FINALOUTPUT.RowHeader3 = 'Down Time'
group by #FINALOUTPUT.StartTime,#FINALOUTPUT.EndTime,
	#FINALOUTPUT.MachineID,#FINALOUTPUT.OperatorID,#FINALOUTPUT.ComponentID,#FINALOUTPUT.OperationID )
as T1 inner join
#FINALOUTPUT on #FINALOUTPUT.StartTime=T1.strt and #FINALOUTPUT.EndTime=T1.ndt and
#FINALOUTPUT.MachineID=T1.machid and #FINALOUTPUT.OperatorID =T1.oprID and #FINALOUTPUT.ComponentID =T1.compID and
#FINALOUTPUT.OperationID=T1.opnID where RowHeader3 = 'Down Time'

print '02:: '+CONVERT(varchar, SYSDATETIME(), 121)

---mod 4
--update #FINALOUTPUT set Dflag=T1.Tflag from (select case when  max(rowvalue)  not in (select distinct reason from #NSPLDowns ) and sum(cast(RowValue as integer))<=0   then 0
--when  max(rowvalue) is not null and max(rowvalue) in (select distinct reason from #NSPLDowns )   then 1
--when  max(rowvalue)  not in (select distinct reason from #NSPLDowns ) and sum(cast(RowValue as integer))>0   then 1 end as Tflag,
--[Date],ShiftNAME,Machine,Operator,Component,Operation from #FINALOUTPUT
--where rowvalue is not null   group by [Date],ShiftNAME,Machine,Operator,Component,Operation) as T1
--inner join  #FINALOUTPUT on #FINALOUTPUT.[Date]=T1.[Date] and #FINALOUTPUT.ShiftNAME=T1.ShiftNAME and
--#FINALOUTPUT.Machine=T1.Machine and #FINALOUTPUT.Operator=T1.Operator  and #FINALOUTPUT.Component=T1.Component
--and #FINALOUTPUT.Operation=T1.Operation
--DR0258 - KarthikR - 09-Sep-2010 from here
/*
update #FINALOUTPUT set Dflag=T1.Tflag from (select case when  max(rowvalue)  not in (select distinct reason from #NSPLDowns ) and sum(cast(RowValue as float))<=0   then 0
when  max(cast(RowValue as float)) is not null and max(cast(RowValue as float)) in (select distinct reason from #NSPLDowns )   then 1
when  max(cast(RowValue as float))  not in (select distinct reason from #NSPLDowns ) and sum(cast(RowValue as float))>0   then 1 end as Tflag,
[Date],ShiftNAME,Machine,Operator,Component,Operation from #FINALOUTPUT
where rowvalue is not null   group by [Date],ShiftNAME,Machine,Operator,Component,Operation) as T1
inner join  #FINALOUTPUT on #FINALOUTPUT.[Date]=T1.[Date] and #FINALOUTPUT.ShiftNAME=T1.ShiftNAME and
#FINALOUTPUT.Machine=T1.Machine and #FINALOUTPUT.Operator=T1.Operator  and #FINALOUTPUT.Component=T1.Component
and #FINALOUTPUT.Operation=T1.Operation
---mod 4
*/
select distinct reason into #DNSPL from #NSPLDowns  --ER0459
update #FINALOUTPUT set Dflag=isnull(T1.Tflag,0) from
(select case
	when  max(rowvalue)  not in (select reason from #DNSPL) and sum(cast(RowValue as float))<=0   then 0 --ER0459
	when  max(RowValue) in (select reason from #DNSPL )   then 1										 --ER0459
	when  max(RowValue)  not in (select reason from #DNSPL ) and sum(cast(RowValue as float))>0   then 1 --ER0459
end as Tflag,
[Date],ShiftNAME,Machine,Operator,Component,Operation from #FINALOUTPUT
where isnull(rowvalue,1)<>1
group by [Date],ShiftNAME,Machine,Operator,Component,Operation) as T1
inner join  #FINALOUTPUT on #FINALOUTPUT.[Date]=T1.[Date] and #FINALOUTPUT.ShiftNAME=T1.ShiftNAME and
#FINALOUTPUT.Machine=T1.Machine and #FINALOUTPUT.Operator=T1.Operator  and #FINALOUTPUT.Component=T1.Component
and #FINALOUTPUT.Operation=T1.Operation
--DR0258 - KarthikR - 09-Sep-2010 till here
delete from #FINALOUTPUT where Dflag=0
print '03:: '+CONVERT(varchar, SYSDATETIME(), 121)
------------------------------------------------------------------------------------------------------------------------
--EXCEPTION CONCEPT :: ANY EXCEPTION LESS THAN AN HOUR WILL NOT BE CONSIDERED SINCE IT IS PRACTICALL NOT POSSIBLE
Update #FINALOUTPUT set RowValue = floor(RowValue * (isnull(convert(float,Actualcount)/convert(float,idealcount),0))) from
(Select * from productioncountexception)as t1 inner join #FINALOUTPUT fo on
t1.MachineID = fo.Machine and t1.ComponentID = fo.Component and t1.OperationNo = fo.Operation and
fo.StartTime>=t1.StartTime and fo.StartTime<t1.EndTime and fo.EndTime>t1.StartTime and fo.EndTime<=t1.EndTime
--where Ispartcount = 1 --DR0258 - KarthikR - 09-Sep-2010
where (Ispartcount = 1 or isnumeric(rowvalue)=1 )and isnull(rowvalue,1)<>1
------------------------------------------------------------------------------------------------------------------------

	Select top 1 @Targetsource = ValueInText from Shopdefaults where Parameter='TargetFrom'
	
	If isnull(@Targetsource,'')='Exact Schedule'
	Begin
		--Update #HeaderOperation set Operation = t1.OperationNO from (select OperationNo,interfaceid from componentoperationpricing)as t1 inner join #HeaderOperation on #HeaderOperation.OperationID = t1.interfaceid
		print 'Exact Schedule'
		--Update #FINALOUTPUT set RowValue = T1.idealcount  --DR0258 - KarthikR - 09-Sep-2010
		Update #FINALOUTPUT set RowValue =isnull( T1.idealcount,0)
		from
		(select * from loadschedule ) as T1
		inner join #FinalOutput on T1.[date] = #FINALOUTPUT.[Date] and T1.Shift = #FINALOUTPUT.ShiftName
		and T1.Machine = #FINALOUTPUT.Machine and T1.Component = #FINALOUTPUT.Component
		and T1.operation = #FINALOUTPUT.Operation where RowHeader3 = 'Shift Target' or RowHeader3 = 'Hourly Target'
	End

	If isnull(@Targetsource,'')='Default Target per CO'
	Begin
		print 'Default Target per CO'
		Create Table #loadschedule([date] datetime,shift NvarChar(50),Machine NvarChar(50),Component NvarChar(50),Operation NvarChar(50),IdealCount NvarChar(50))
		Insert #loadschedule Select [date],shift,Machine,Component,Operation,IdealCount from loadschedule order by [date]
		--Update #FINALOUTPUT set RowValue = T1.idealcount  --DR0258 - KarthikR - 09-Sep-2010
		Update #FINALOUTPUT set RowValue = isnull(T1.idealcount,0)
		from (select * from #loadschedule ) as T1
		inner join #FinalOutput on T1.Shift = #FINALOUTPUT.ShiftName and T1.Machine = #FINALOUTPUT.Machine
		and T1.Component = #FINALOUTPUT.Component and T1.operation = #FINALOUTPUT.Operation
		where RowHeader3 = 'Shift Target' or RowHeader3 = 'Hourly Target'
	End
	print '03:: '+CONVERT(varchar, SYSDATETIME(), 121)
	If isnull(@Targetsource,'')='% Ideal'
	Begin


		declare @Targetdef as nvarchar(50)
		Select @Targetdef = isnull(valueintext,'ByTotalTime') from Shopdefaults where Parameter='%IdealTargetCalculation'

		If @Targetdef='ByTotalTime'
		Begin
			print '04!!:: '+CONVERT(varchar, SYSDATETIME(), 121)
			--update #FINALOUTPUT set RowValue= t1.tcount from --DR0258 - KarthikR - 09-Sep-2010
			update #FINALOUTPUT set RowValue= isnull(t1.tcount,0) from
			(
			select CO.componentid as component,CO.Operationno as operation,CO.cycletime,CO.suboperations,#FINALOUTPUT.StartTime as strt,#FINALOUTPUT.EndTime as ndtm,#FINALOUTPUT.Machine as mcid,
			tcount=((datediff(second,#FINALOUTPUT.StartTime,#FINALOUTPUT.EndTime)*CO.suboperations)/CO.cycletime)*isnull(CO.targetpercent,100) /100
			from componentoperationpricing CO
			--inner join #FINALOUTPUT on CO.Componentid=#FINALOUTPUT.Component and Co.operationno=#FINALOUTPUT.Operation --DR0259 - KarthikR - 23/Sep/2010
			inner join #FINALOUTPUT on co.machineid=#finaloutput.machine and CO.Componentid=#FINALOUTPUT.Component and Co.operationno=#FINALOUTPUT.Operation --DR0259 - KarthikR - 23/Sep/2010
			---where #finaloutput.Component='GBS 750'
			--where #FINALOUTPUT.downreason='NoDown'
			) as t1 inner join #FINALOUTPUT on t1.strt=#FINALOUTPUT.StartTime and t1.ndtm=#FINALOUTPUT.EndTime and t1.mcid=#FINALOUTPUT.Machine and t1.component=#FINALOUTPUT.Component and
			t1.operation=#FINALOUTPUT.Operation where RowHeader3 = 'Shift Target' or RowHeader3 = 'Hourly Target'
			print '04:: '+CONVERT(varchar, SYSDATETIME(), 121)
		END


		If @Targetdef='ByRunTime'
		BEGIN

				Declare @curmachineid as nvarchar(50)
				Declare @curcomp  as nvarchar(50)
				Declare @curop  as int
				Declare @curhursttime as datetime
				Declare @curhurndtime as datetime
				Declare @curshftname as int

				Declare @machineid as nvarchar(50)
				Declare @compid  as nvarchar(50)
				Declare @operationid  as int
				declare @hurstarttime as datetime
				declare @hurendtime as datetime
				declare @batchid as int
				declare @id as bigint
				
				insert into #target(MachineID,MachineInterface,ComponentID,OperationNo,sttime,ndtime,hursttime,hurndtime,shftname,batchid)
				Select F.machine,A.mc,A.comp,A.opn,A.msttime,A.ndtime,F.StartTime,F.endtime,F.Shiftname,0 from  #FINALOUTPUT F
				inner join #T_Autodata A on F.MachineID=A.mc and F.componentid=A.comp and F.operationid=A.opn where F.RowHeader3 = 'Shift Target' and
				((A.ndtime>=F.StartTime and A.ndtime<=F.endtime) )
				order by mc,sttime

				print '041:: '+CONVERT(varchar, SYSDATETIME(), 121)
				--declare @RptCursor  cursor
				--set  @RptCursor= CURSOR FOR
				--SELECT MachineInterface,ComponentID,OperationNo,hursttime,hurndtime,id from #target order by MachineInterface,hursttime,Sttime
				--OPEN @RptCursor
				--FETCH NEXT FROM @RptCursor INTO @machineid, @compid, @operationid,@hurstarttime,@hurendtime,@id

				-- -- initialize current variables		
				--  select @curmachineid = @machineid	
				--  select @curcomp = @compid
				--  select @curop = @operationid
				--  Select @curhursttime=@hurstarttime
				--  Select @curhurndtime=@hurendtime
				--  set @batchid =1

				--while @@fetch_status = 0
				--begin
				--	If @curmachineid=@machineid and @curcomp = @compid and @curop = @operationid and @curhursttime=@hurstarttime
				--	begin			
				--		update #target set batchid = @batchid where MachineInterface=@machineid and ComponentID=@compid and OperationNo=@operationid and hursttime=@hurstarttime and id=@id
				--	end
				--	else
				--	begin	
				--	  set @batchid = @batchid +1
				--	  update #target set batchid = @batchid where MachineInterface=@machineid and ComponentID=@compid and OperationNo=@operationid and hursttime=@hurstarttime and id=@id
				--	  select @curmachineid = @machineid	
				--	  select @curcomp = @compid
				--	  select @curop = @operationid
				--	  Select @curhursttime=@hurstarttime
				--	  Select @curhurndtime=@hurendtime	
				--	end	
				
				--FETCH NEXT FROM @RptCursor INTO @machineid, @compid, @operationid,@hurstarttime,@hurendtime,@id			
				--end
				--close @RptCursor
				--deallocate @RptCursor

		--id bigint identity(1,1) not null,
		--MachineID NvarChar(50),
		--MachineInterface nvarchar(50),
		--ComponentID Nvarchar(50),
		--OperationNo Int,
		--sttime Datetime,
		--ndtime Datetime,
		--hursttime datetime,
		--hurndtime datetime,
		--shftname nvarchar(20),
		--Pdt int,
		--batchid int @curmachineid=@machineid and @curcomp = @compid and @curop = @operationid and @curhursttime=@hurstarttime
		--ER0459
				create index idx_tgt on #Target(machineid ,componentid ,operationno ,hursttime)
				update #Target 
				set batchid=tt.batchid 
				from
				(
				select t.machineid, t.componentid, t.operationno, t.hursttime,
				RANK() OVER (
				  PARTITION BY t.machineid
				  order by t.machineid, t.sttime
				) -
				RANK() OVER (
				  PARTITION BY t.machineid, t.componentid, t.operationno, t.hursttime
				  order by t.machineid, t.sttime
				) AS batchid
				from #Target t 
				) tt
				where tt.machineid=#target.machineid and tt.componentid=#target.componentid and tt.operationno=#target.operationno and tt.hursttime=#target.hursttime
		--/ER0459		

				print '042:: '+CONVERT(varchar, SYSDATETIME(), 121)

				insert into #Target_actime(machineid,MachineInterface,ComponentID,OperationNo,sttime,ndtime,hursttime,hurndtime,shftname,Totaltime,batchid)
				select machineid,MachineInterface,ComponentID,OperationNo,case when min(sttime)<hursttime then hursttime else min(sttime) end,
				case when max(ndtime)>hurndtime then hurndtime else max(ndtime) end,hursttime,hurndtime,shftname,0,batchid from #target
				group by machineid,MachineInterface,ComponentID,OperationNo,hursttime,hurndtime,shftname,batchid 

				update #Target_actime set Totaltime=datediff(s,sttime,ndtime)


				select machineid,MachineInterface,ComponentID,OperationNo,sum(totaltime) as Runtime,hursttime,hurndtime,shftname into #FinalTarget_actime from #Target_actime
				group by machineid,MachineInterface,ComponentID,OperationNo,hursttime,hurndtime,shftname


				update #FINALOUTPUT set RowValue= isnull(t1.tcount,0) from
				(
				select #FINALOUTPUT.StartTime as strt,#FINALOUTPUT.EndTime as ndtm,#FINALOUTPUT.Machine as mcid, CO.componentid as component,CO.Operationno as operation,CO.cycletime,CO.suboperations,
				tcount=((T.Runtime*CO.suboperations)/CO.cycletime)*isnull(CO.targetpercent,100) /100
				from componentoperationpricing CO
				inner join #FINALOUTPUT on co.machineid=#finaloutput.machine and CO.Componentid=#FINALOUTPUT.Component and Co.operationno=#FINALOUTPUT.Operation 
				inner join #FinalTarget_actime T on T.MachineInterface=#finaloutput.machineid and T.Componentid=#FINALOUTPUT.Componentid and T.operationno=#FINALOUTPUT.OperationID
				and T.hursttime= #FINALOUTPUT.StartTime and T.hurndtime=#FINALOUTPUT.EndTime where #FINALOUTPUT.RowHeader3 = 'Shift Target' 
				) as t1 inner join #FINALOUTPUT on t1.strt=#FINALOUTPUT.StartTime and t1.ndtm=#FINALOUTPUT.EndTime and t1.mcid=#FINALOUTPUT.Machine and t1.component=#FINALOUTPUT.Component and
				t1.operation=#FINALOUTPUT.Operation where RowHeader3 = 'Shift Target' or RowHeader3 = 'Hourly Target'
				print '04:: '+CONVERT(varchar, SYSDATETIME(), 121)
			END
		End


--Update #FINALOUTPUT set RowValue = RowValue where RowHeader3 = 'Shift Target' or RowHeader3 = 'Hourly Target'  --DR0259 - KarthikR - 23/Sep/2010
Update #FINALOUTPUT set RowValue = floor(RowValue) where RowHeader3 = 'Shift Target' or RowHeader3 = 'Hourly Target' --DR0259 - KarthikR - 23/Sep/2010
--Update #FINALOUTPUT set RowValue = DownReason where DownReason not in ('NoDown') --DR0258 - KarthikR - 09-Sep-2010
--Update #FINALOUTPUT set RowValue = DownReason+'('+ rowvalue +')' where DownReason not in ('NoDown')--ER0253 - SyedArifM/SwathiKS - 22/sep/2010
Update #FINALOUTPUT set RowValue ='D('+ rowvalue +')' where DownReason not in ('NoDown')--ER0253 - SyedArifM/SwathiKS - 22/sep/2010
Update #FINALOUTPUT set RowHeader1 = DownReason+'('+ RowHeader1 +')' where DownReason not in ('NoDown') --ER0253 - SyedArifM/SwathiKS - 22/sep/2010
--Update #FINALOUTPUT set RowValue = RowValue/DateDiff(hh,StartTime,EndTime) where RowHeader3 = 'Hourly Target' --DR0259 - KarthikR - 23/Sep/2010
Update #FINALOUTPUT set RowValue = floor((cast(RowValue as float) /DateDiff(n,StartTime,EndTime))*60) where RowHeader3 = 'Hourly Target'  --DR0259 - KarthikR - 23/Sep/2010
--Update #FINALOUTPUT set RowHeader1 = Null Where RowHeader1 in ('Hourly Target','Shift Target','Down Time','Total output') --ER0416
Update #FINALOUTPUT set RowHeader1 = Null Where RowHeader1 in ('Hourly Target','Shift Target','Down Time','Total output','Total output (%)') --ER0416
Update #FINALOUTPUT set RowHeader1 = ShiftName where RowHeader1 is Null
Update #FINALOUTPUT set RowValue = dbo.f_FormatTime(RowValue,'HH:MM:SS') where RowHeader3='Down Time'



if @ComparisonParam = 'LoadReport_FormatII'	--ER0108
Begin
	
	CREATE TABLE #TempFinalOutput
		(
			[Date] Datetime,
			Shift NvarChar(20),
			MachineID NvarChar(50),
			ComponentID NvarChar(50),
			OperationID NvarChar(50),
			Target int default 0,
			Actual int default 0
		)
	CREATE TABLE #TempLoadReport
		(
			[Date] Datetime,
			Shift NvarChar(20),
			MachineID NvarChar(50),
			ComponentID NvarChar(50),
			OperationID NvarChar(50),
			Target int default 0,
			Actual int default 0
		)
	CREATE TABLE #TempLoadReport_final
		(
			Date1 Datetime,
			Shift1 NvarChar(20),
			MachineID1 NvarChar(50),
			ComponentID1 NvarChar(50),
			OperationID1 NvarChar(50),
			Target1 int default 0,
			Actual1 int default 0,
			Date2 Datetime,
			Shift2 NvarChar(20),
			MachineID2 NvarChar(50),
			ComponentID2 NvarChar(50),
			OperationID2 NvarChar(50),
			Target2 int default 0,
			Actual2 int default 0
		)
	
	Insert into #TempFinalOutput([Date],Shift,MachineID,ComponentID,OperationID,Actual)
	Select [Date],ShiftNAME,Machine,Component,Operation,sum(Convert(int,(IsNull(RowValue,0)))) from #FINALOUTPUT
	where RowHeader3 = 'Total output' group by [Date],ShiftNAME,Machine,Component,Operation
	
	--select * from #TempLoadReport
	select @Strsql=''
	select @Strsql='Insert into #TempLoadReport([Date],Shift,MachineID,ComponentID,OperationID,Target)'
	select @Strsql=@Strsql+'select Date,Shift,Machine,Component,Operation,idealcount from LoadSchedule L
					inner join Machineinformation on L.Machine=Machineinformation.machineid
					inner join PlantMachine P on L.Machine=P.machineid 
					 LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = P.PlantID and PlantMachineGroups.machineid = P.MachineID 	'
	select @Strsql=@Strsql+' where Date >=''' +convert(varchar(20),@StartDate) + ''' and Date <=''' + convert(varchar(20),@EndDate)+''''
	select @Strsql=@Strsql+@strmachine+@StrTPMMachines+@strplantID + @StrGroupID
	exec(@Strsql)
	
	
--select * from #TempFinalOutput
--select * from #TempLoadReport
	---mod 1: commented below if condition,in order to have same outpt at any point of time
	if (select count(*) from #TempFinalOutput)>0 and (select count(*) from #TempLoadReport)>0
	begin
		
		insert into #TempLoadReport_final
		(
			Date1 ,
			Shift1 ,
			MachineID1 ,
			ComponentID1 ,
			OperationID1,
			Target1,
			Actual1 ,
			Date2 ,
			Shift2 ,
			MachineID2,
			ComponentID2 ,
			OperationID2 ,
			Target2 ,
			Actual2
		)
	
		select * from #TempLoadReport FULL OUTER JOIN  #TempFinalOutput t1 on
		t1.Date = #TempLoadReport.Date and t1.Shift = #TempLoadReport.Shift and
		t1.MachineID = #TempLoadReport.MachineID and t1.componentId = #TempLoadReport.ComponentID and
		t1.OperationID = #TempLoadReport.OperationID
		--select * from #TempLoadReport_final
		
		--mod 1 : moved below select outside of the if
		/*select case when Date1 is null then Date2 else Date1 end as [Date] ,
		       case when Shift1 is null then upper(Shift2) else upper(Shift1) end as Shift ,
			case when MachineID1 is null then MachineID2 else MachineID1 end as  MachineId ,
			case when ComponentID1 is null then ComponentID2 else ComponentID1 end as ComponentID,
			case when OperationID1 is null then OperationID2 else OperationID1 end as OperationID,
			Target1 as Target ,
			Actual2 as Actual from #TempLoadReport_final order by [Date],Shift,MachineID,ComponentID,OperationID
		return */
	
	end
		---mod 1; Moved the select statement from above IF
	
		select case when Date1 is null then Date2 else Date1 end as [Date] ,
		       case when Shift1 is null then upper(Shift2) else upper(Shift1) end as Shift ,
			case when MachineID1 is null then MachineID2 else MachineID1 end as  MachineId ,
			case when ComponentID1 is null then ComponentID2 else ComponentID1 end as ComponentID,
			case when OperationID1 is null then OperationID2 else OperationID1 end as OperationID,
			Target1 as Target ,
			Actual2 as Actual from #TempLoadReport_final order by [Date],Shift,MachineID,ComponentID,OperationID
		return
End
----ER0252 - SyedArifM - 15-Sep-2010
update #FINALOUTPUT set #FINALOUTPUT.RowFlag =T1.row
from  #FINALOUTPUT inner join
(Select [Date],ShiftNAME,Machine,Operator,Component,Operation, '1' Row
from #FINALOUTPUT
--where  RowHeader3 like '%Total output%' and Rowvalue like '0' --ER0416
--where  RowHeader3='Total output' and Rowvalue like '0' --ER0416 --ER0434
where (RowHeader3='Total output' and Rowvalue like '0') and (RowHeader3='Down Time' and Rowvalue like '00:00:00')--ER0416 --ER0434 Added
)  T1
on  #FINALOUTPUT.[Date] like T1.[Date] and #FINALOUTPUT.ShiftName like T1.ShiftName
and #FINALOUTPUT.Machine like T1.Machine and #FINALOUTPUT.Operator like T1.Operator
and #FINALOUTPUT.Component like T1.Component and #FINALOUTPUT.Operation like T1.Operation

delete from #FINALOUTPUT where RowFlag like '1'
----ER0252 - SyedArifM - 15-Sep-2010


----ER0252 - KarthikR - 15-Sep-2010
update #finalOutput set Rowvalue = ceiling(convert(float,t1.rowvalue)-((convert(float,t1.rowvalue)/ T5.ActualTime) * T5.Downtime))
from
#finaloutput T1
inner join
(
select  GS.shiftname,sum(datediff(n,FromTime,ToTime)) Downtime ,datediff(n,StartTime,EndTime) ActualTime
from #NSPLDowns N,#GetShiftTime GS
where N.FromTime >= GS.StartTime  and N.ToTime <= GS.EndTime
group by GS.shiftname,StartTime,EndTime
) T5 on T5.ShiftName = T1.ShiftName
where t1.RowHeader3 = 'Shift Target' and rowvalue>'0'
----ER0252 - KarthikR- 15-Sep-2010


--ER0416 Added From Here
update #finaloutput set rowvalue = T1.Totaloutput  from
(Select [Date],ShiftNAME,Machine,Operator,Component,Operation,rowvalue as Totaloutput
from #FINALOUTPUT where  RowHeader3 like 'Total output')T1 inner join #FINALOUTPUT on #FINALOUTPUT.[Date]=T1.[Date] and #FINALOUTPUT.ShiftName =T1.ShiftName
and #FINALOUTPUT.Machine=T1.Machine and #FINALOUTPUT.Operator=T1.Operator
and #FINALOUTPUT.Component=T1.Component and #FINALOUTPUT.Operation=T1.Operation
where #FINALOUTPUT.rowheader3='Total output (%)'

update #finaloutput set rowvalue = round(((convert(float,#finaloutput.rowvalue)/T1.shifttarget)*100),2)  from
(Select [Date],ShiftNAME,Machine,Operator,Component,Operation,rowvalue as shifttarget
from #FINALOUTPUT where  RowHeader3 like '%Shift Target%' )T1 inner join #FINALOUTPUT on #FINALOUTPUT.[Date]=T1.[Date] and #FINALOUTPUT.ShiftName =T1.ShiftName
and #FINALOUTPUT.Machine=T1.Machine and #FINALOUTPUT.Operator=T1.Operator
and #FINALOUTPUT.Component=T1.Component and #FINALOUTPUT.Operation=T1.Operation
where #FINALOUTPUT.rowheader3='Total output (%)'  and T1.shifttarget>'0'
--ER0416 Added Till Here

Select [Date],ShiftNAME,Machine,Operator,e.Name as OperatorName,Component,Operation,RowHeader1,RowHeader2,RowHeader3,IsNull(RowValue,0) as RowValue from #FINALOUTPUT
left outer join employeeinformation e on e.Employeeid=#FINALOUTPUT.Operator
order by [Date],ShiftNAME,Machine,Component,Operation,
Operator,RowHeader3
END
