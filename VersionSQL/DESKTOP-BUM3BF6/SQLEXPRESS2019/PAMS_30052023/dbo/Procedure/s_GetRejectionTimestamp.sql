/****** Object:  Procedure [dbo].[s_GetRejectionTimestamp]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[s_GetRejectionTimestamp] '2015-10-29 02:12:30 AM','3','1','250','Hourlytarget'
CREATE Procedure [dbo].[s_GetRejectionTimestamp]
@FromDate datetime,
@shiftid nvarchar(50)='',
@Flag int='',
@Target int='',
@Param nvarchar(50)=''

AS
BEGIN

Create Table #ShiftTemp
(
	Slno int identity(1,1) NOT NULL,
	PDate datetime,
	ShiftName nvarchar(20),
	FromTime datetime,
	ToTime Datetime
)

Create Table #ShiftTemp1
(
	Slno int identity(1,1) NOT NULL,
	PDate datetime,
	ShiftName nvarchar(20),
	FromTime datetime,
	ToTime Datetime
)

Create Table #HourTemp
(
	ShiftName nvarchar(50),
	StartDate datetime,
	HourID int,
	HourStart datetime,
	HourEnd datetime,
	Target float
)

declare @startdate as datetime
declare @enddate as datetime
declare @startdatetime nvarchar(20)
Declare @ShiftHours as float
Declare @HourlyTarget as float


If @param=''
Begin
	--select @startdate = dbo.f_GetLogicalDay(@FromDate,'start')
	--select @enddate = dbo.f_GetLogicalDay(@FromDate,'start')
	select @startdate = dbo.f_GetLogicalDayStart(@FromDate)
	select @enddate = dbo.f_GetLogicalDayStart(@FromDate)

	while @startdate<=@enddate
	Begin

		select @startdatetime = CAST(datePart(yyyy,@startdate) AS nvarchar(4)) + '-' + 
		 CAST(datePart(mm,@startdate) AS nvarchar(2)) + '-' + 
		 CAST(datePart(dd,@startdate) AS nvarchar(2))

		Insert into #ShiftTemp(PDate,ShiftName, FromTime, ToTime)
		select @startdate,ShiftName,
		Dateadd(DAY,FromDay,(convert(datetime, @startdatetime + ' ' + CAST(datePart(hh,FromTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,FromTime) as nvarchar(2))+ ':' + CAST(datePart(ss,FromTime) as nvarchar(2))))) as StartTime,
		DateAdd(Day,ToDay,(convert(datetime, @startdatetime + ' ' + CAST(datePart(hh,ToTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,ToTime) as nvarchar(2))+ ':' + CAST(datePart(ss,ToTime) as nvarchar(2))))) as EndTime
		from shiftdetails where running = 1 order by shiftid
		Select @startdate = dateadd(d,1,@startdate)
	END
END

If @param='HourlyTarget'
Begin
		select @startdate = dbo.f_GetLogicalDayStart(@FromDate)

		Insert into #ShiftTemp1(PDate,ShiftName, FromTime, ToTime)
		select * from [dbo].[s_FunCurrentShiftTime](@startdate,'')

		Insert into #ShiftTemp(PDate,ShiftName, FromTime, ToTime)
		select TOP 1 PDate,ShiftName, FromTime, ToTime from #ShiftTemp1 where @FromDate>=FromTime and @FromDate<=ToTime
		ORDER BY FromTime ASC

		Select @ShiftHours = Datediff(Second,FromTime,ToTime) from #ShiftTemp
		Select @HourlyTarget = @Target/@ShiftHours
END


Declare @Counter as nvarchar(50)
declare @curstarttime as datetime  
Declare @curendtime as datetime  
declare @Endtime as datetime  
Declare @StrDiv int  
Declare @i as Nvarchar(50)

declare @k as int
Declare @count as int
Declare @shift as nvarchar(50)
declare @LogicalDaystart as datetime

Select @k = 1
Select @Count = count(*) from #ShiftTemp

While @k <= @Count
Begin

	SELECT TOP 1 @counter=FromTime FROM #ShiftTemp where slno=@k ORDER BY FromTime ASC  
	SELECT TOP 1 @EndTime=Totime FROM #ShiftTemp where slno=@k ORDER BY FromTime DESC  
	Select @Shift = Shiftname from #ShiftTemp where slno=@k 
	Select @LogicalDaystart=PDate from #ShiftTemp where slno=@k 
	select @StrDiv=cast (ceiling (cast(datediff(second,@counter,@EndTime)as float ) /3600) as int)   
	Select @i=1

	While(@counter < @EndTime)  
	BEGIN  
		SELECT @curstarttime=@counter  
		SELECT @curendtime=DATEADD(Second,3600,@counter)  
		if @curendtime >= @EndTime  
		Begin  
		 set @curendtime = @EndTime  
		End  

		 Insert into #HourTemp(ShiftName,StartDate,HourID,HourStart,HourEnd,Target)
		 Select @Shift,Convert(nvarchar(10),@LogicalDaystart,120) + ' 00:00:00.000',@i,convert(nvarchar(20),@curstarttime,120),convert(nvarchar(20),@curendtime,120),@HourlyTarget
	
		 SELECT @counter = DATEADD(Second,3600,@counter)  
		Select @i = @i + 1
	END  

Select @k = @k +1
END


If @param=''
Begin
Select Convert(nvarchar(10),Hourstart,120) + ' ' + Convert(nvarchar(8),@fromdate,108) as CreatedTS from #HourTemp 
where Convert(nvarchar(20),@fromdate,120) >= Convert(nvarchar(20),Hourstart,120) and Convert(nvarchar(20),@fromdate,120) < Convert(nvarchar(20),HourEnd,120)
--where Convert(nvarchar(8),@fromdate,108) between Convert(nvarchar(8),Hourstart,108) and Convert(nvarchar(8),HourEnd,108)
END

If @param='HourlyTarget'
Begin

	If @Flag = 1 --Full
	Begin
		Select StartDate,HourID,HourStart,HourEnd,Round(Target,2) as Target from #HourTemp Order by Hourid
	End

	If @Flag = 2 --Partial
	Begin
		Select StartDate,HourID,HourStart,HourEnd,Round(Target,2) as Target from #HourTemp where Convert(nvarchar(20),Hourstart,120)>=Convert(nvarchar(20),@fromdate,120) Order by Hourid
	End

END


END
