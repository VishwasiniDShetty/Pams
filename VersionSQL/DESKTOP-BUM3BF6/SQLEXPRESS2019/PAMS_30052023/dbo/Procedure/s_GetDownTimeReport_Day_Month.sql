/****** Object:  Procedure [dbo].[s_GetDownTimeReport_Day_Month]    Committed by VersionSQL https://www.versionsql.com ******/

/****************************************************************
--NR0069 - SwathiKS\KarthikR - 09-Jul-2010 ::New Excel Report to show the Downtimes Daywise and Monthwise
--mod 1:-DR280 by Karthik R 31-may-2011 -To solve issue of invalid use of null in this report due to null category
SmartManager - Analysis Report Shift Aggregated Data - Downtime Reports 
Report Type - DowntimeReport-Daywise Template - DownTime_Daywise_Template.xls
Report Type - DowntimeReport-Monthwise Template - DownTime_Monthwise_Template.xls
*******************************************************************/
--s_GetDownTimeReport_Day_Month '2008-12-01','2009-01-30','','','day','downid'
--s_GetDownTimeReport_Day_Month '2008-10-01','2009-07-01','','','month','downid'
--s_GetDownTimeReport_Day_Month '2011-Feb-28','2011-May-31','','','day','catagory'
CREATE     PROCEDURE [dbo].[s_GetDownTimeReport_Day_Month] 

@Startdate datetime,
@Enddate datetime,
@plantID nvarchar(50)='',
@MachineID nvarchar(50)='',
@Timeaxis nvarchar(50), --month,day
@Param nvarchar(50) --catagory,downid

AS
BEGIN


Declare @strsql nvarchar(4000)
Declare @strMachine nvarchar(255)
Declare @StrPlantID nvarchar(255)
Declare @counter int
select @strsql=''
select @strMachine=''
select @StrPlantID=''


Create Table #day
(
	PDate nvarchar(50)
	

)

Create table #Month
(
	DStart nvarchar(50),
	DEnd nvarchar(50),
	QStartdate nvarchar(25),
	QEnddate nvarchar(25)	
)


Create table #Downtime
(

	Startdate nvarchar(50),
	Enddate nvarchar(50),
	DownID nvarchar(50),
	DownTime bigint default(0),
	QStartdate nvarchar(25),
	QEnddate nvarchar(25),
	QDownTime bigint default(0)
)


declare @starttime datetime
declare @endtime datetime
Declare @Temp datetime
Declare @QSDate datetime
Declare @QEDate datetime

if isnull(@PlantID,'')<>''
begin
select @StrPlantID=' AND (PlantMachine.PlantID =N'''+@PlantID+''')'
end

if isnull(@MachineID,'')<>''
begin
select @strmachine=' AND (Machineinformation.machineid =N'''+@MachineID+''')'
end

If @timeaxis='month'
BEGIN
	--Select da
	SELECT @starttime=dbo.f_GetPhysicalMonth(@StartDate,'Start')
	SELECT @endtime=dbo.f_GetPhysicalMonth(@EndDate,'End')
	SELECT @QSDate= @starttime
	SELECT @QEDate= dateadd(dd,-1,dateadd(mm,3,@starttime))

		While @starttime<=@endtime
		BEGIN
			
			INSERT INTO #Month (DStart,DEnd,QStartdate,QEnddate)
			SELECT @starttime,dbo.f_GetPhysicalMonth(@starttime,'End'),@QSDate,@QEDate
			SELECT  @starttime=DateAdd(mm,1, @starttime)
			If Datediff(ss,@starttime,dateadd(dd,1,@QEdate))=0
 			 Begin
				SELECT @QSDate= @starttime
				Select @QEDate=dateadd(dd,-1,dateadd(mm,3,@starttime))
			 End
			
		END
        --- Select * from #month
---return
		SELECT @starttime=dbo.f_GetPhysicalMonth(@StartDate,'Start')

	insert into #Downtime(Startdate,Enddate,Qstartdate,QEnddate,DownID)
	SELECT #month.DStart,#month.DEnd,#month.Qstartdate,#month.QEnddate, T1.Downid  FROM (Select distinct Downid from downcodeinformation )T1 CROSS JOIN #Month
---	Select * from 	#Downtime
   ---    Return

	Select @Strsql = 'UPDATE #Downtime SET DownTime = IsNull(T2.DownTime,0)'
	Select @Strsql = @Strsql + ' From (select ''1-''+left(Datename(mm,ddate),3)+''-''+Datename(yy,ddate) as pdate,(Sum(DownTime))As DownTime,ShiftDownTimeDetails.downid'
	Select @Strsql = @Strsql + ' From ShiftDownTimeDetails'
	select @strsql = @strsql + ' left outer join  machineinformation on machineinformation.machineid =ShiftDownTimeDetails.machineid '
	select @strsql = @strsql + ' left outer join PlantMachine on PlantMachine.plantID=ShiftDownTimeDetails.plantID and machineinformation.machineid= PlantMachine.machineid'
	Select @Strsql = @Strsql + ' where dDate>='''+convert(nvarchar(25),@starttime,120)+''' And dDate<='''+convert(nvarchar(25),@endtime,120)+''''
	Select @Strsql = @Strsql + @StrPlantID + @Strmachine 		
	Select @Strsql = @Strsql + ' Group By ''1-''+left(Datename(mm,ddate),3)+''-''+Datename(yy,ddate),ShiftDowntimeDetails.downID'
	Select @Strsql = @Strsql + ' ) AS T2 Inner Join #Downtime ON datediff(ss,#Downtime.StartDate,T2.pdate)=0 and #Downtime.downID=T2.downID '
	
	Print @Strsql
	Exec(@Strsql)	

	 UPDATE #Downtime SET QDownTime = IsNull(T1.DownTime,0) from #downtime inner join 
	(select #Downtime.Qstartdate,#Downtime.QEnddate,#Downtime.DownID,sum(#Downtime.Downtime)as Downtime from #Downtime 
	 group by #Downtime.Qstartdate,#Downtime.QEnddate,#Downtime.DownID)T1
	on T1.Qstartdate=#Downtime.Qstartdate and T1.QEnddate=#Downtime.QEnddate and T1.Downid = #Downtime.DownID
	
	
	
	
END


If @timeaxis='Day'
BEGIN
	select @starttime = convert(nvarchar(25),+'1-'+datename(mm,@startdate)+'-'+datename(yy,@startdate))
	set @startdate= @starttime
	set @endtime = dateadd(dd,-1,dateadd(mm,1,@starttime))
	set @temp=@starttime

	while @temp <=@endtime
	Begin
		Insert Into #day select  @temp
		set @temp= DateAdd(d,1,@temp)	
	End
--Select * from #day
--return
	

	insert into #Downtime(Startdate,DownID)
	SELECT #day.PDate, T1.Downid  FROM (Select distinct Downid from downcodeinformation )T1 CROSS JOIN #day 



	Select @Strsql = 'UPDATE #Downtime SET DownTime = IsNull(T2.DownTime,0)'
	Select @Strsql = @Strsql + ' From (select ddate,(Sum(DownTime))As DownTime,ShiftDownTimeDetails.downid'
	Select @Strsql = @Strsql + ' From ShiftDownTimeDetails'
	select @strsql = @strsql + ' left outer join  machineinformation on machineinformation.machineid =ShiftDownTimeDetails.machineid '
	select @strsql = @strsql + ' left outer join PlantMachine on PlantMachine.plantID=ShiftDownTimeDetails.plantID and machineinformation.machineid= PlantMachine.machineid'
	Select @Strsql = @Strsql +' where dDate>= '''+convert(varchar(20),@starttime,120)+''' And dDate<=  '''+convert(varchar(20),@endtime,120)+''''
	Select @Strsql = @Strsql + @StrPlantID + @Strmachine 		
	Select @Strsql = @Strsql + ' Group By ShiftDowntimeDetails.downID,ddate'
	Select @Strsql = @Strsql + ' ) AS T2 Inner Join #Downtime ON #Downtime.downID=T2.downID and t2.ddate=#Downtime.Startdate'
	Print @Strsql
	Exec(@Strsql)

	
--Select * from #Downtime
--return
end	


	
	If @param = 'catagory'
	begin
		select T2.Startdate,T1.Catagory as DownReason,sum(convert(bigint,T2.downtime))as DownTime,T2.Qstartdate,T2.QEndDate,sum(convert(bigint,T2.Qdowntime))as QDownTime from
		((
			--mod 1
			--select distinct catagory from downcodeinformation
			select distinct catagory from downcodeinformation where isnull(catagory,'s')<>'s'
			--mod 1
			) T1 
		left outer join (select D.catagory,#downtime.startdate,#downtime.downtime,#Downtime.Qstartdate,#Downtime.QEnddate,#Downtime.QDowntime from 
					downcodeinformation D inner join #downtime on D.downid=#downtime.DownID) T2 
				on T1.catagory=T2.catagory)
		   group by T2.Startdate,T1.Catagory,T2.Qstartdate,T2.QEnddate
		  order by T1.Catagory, cast(T2.Startdate as datetime)
		
	end
	Else
	begin
		select Startdate,Enddate,DownID as DownReason,Downtime,QStartDate,QEndDate,QDowntime from #downtime order by DownID,cast(startdate as datetime)
		
	end  

END
