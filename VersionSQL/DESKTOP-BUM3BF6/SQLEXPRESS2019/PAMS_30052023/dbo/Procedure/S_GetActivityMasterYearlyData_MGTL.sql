/****** Object:  Procedure [dbo].[S_GetActivityMasterYearlyData_MGTL]    Committed by VersionSQL https://www.versionsql.com ******/

/************************************************************************************************  
-- Author:		Anjana C V
-- Create date: 27 Dec 2018
-- Modified date: 28 Dec 2018
-- Description:  Get Activity Master Yearly Data FOR MGTL and Update activity date
[S_GetActivityMasterYearlyData_MGTL] 'Daily',2018,'2018-01-01 00:00:00.000'
[S_GetActivityMasterYearlyData_MGTL] 'Daily',2019,'2019-01-01 00:00:00.000','2019-01-02 06:00:00.000','Check operating pressure of hydraulic unit daily 10 to 12 Bar','Update'
[S_GetActivityMasterYearlyData_MGTL] 'Weekly',2018,'2018-01-01 00:00:00.000'
[S_GetActivityMasterYearlyData_MGTL] 'Weekly',2019,'2019-01-01 06:00:00.000'
[S_GetActivityMasterYearlyData_MGTL] '15 Days',2018,'2018-01-01 00:00:00.000'
[S_GetActivityMasterYearlyData_MGTL] '15 Days',2019,'2019-01-01 06:00:00.000'
[S_GetActivityMasterYearlyData_MGTL] '1 Month',2018,'2018-01-01 00:00:00.000'
[S_GetActivityMasterYearlyData_MGTL] '1 Month',2019,'2019-01-01 06:00:00.000'
[S_GetActivityMasterYearlyData_MGTL] '3 Month',2018,'2018-01-01 00:00:00.000'
[S_GetActivityMasterYearlyData_MGTL] '3 Month',2019,'2019-01-01 06:00:00.000'
[S_GetActivityMasterYearlyData_MGTL] '6 Month',2018,'2018-01-01 00:00:00.000'
[S_GetActivityMasterYearlyData_MGTL] '6 Month',2019,'2019-01-01 06:00:00.000'
[S_GetActivityMasterYearlyData_MGTL] '1 Year',2018,'2018-01-01 06:00:00.000'
[S_GetActivityMasterYearlyData_MGTL] '1 Year',2019,'2019-01-01 06:00:00.000'
[S_GetActivityMasterYearlyData_MGTL] '1 Year',2020,'2020-01-01 06:00:00.000'
[S_GetActivityMasterYearlyData_MGTL] '1 Year',2021,'2021-01-01 06:00:00.000'
[S_GetActivityMasterYearlyData_MGTL] '2 Year',2018,'2018-01-01 00:00:00.000'
[S_GetActivityMasterYearlyData_MGTL] '2 Year',2019,'2019-01-01 06:00:00.000'
[S_GetActivityMasterYearlyData_MGTL] '2 Year',2020,'2020-01-01 06:00:00.000'

[S_GetActivityMasterYearlyData_MGTL] 'Daily',2019,'2019-01-01 00:00:00.000','2019-05-01 00:00:00.000','View'
[S_GetActivityMasterYearlyData_MGTL] 'Weekly',2019,'2019-01-01 00:00:00.000','2019-05-01 00:00:00.000','View'
[S_GetActivityMasterYearlyData_MGTL] '1 Month',2019,'2019-01-01 00:00:00.000','2019-05-01 00:00:00.000','View'
[S_GetActivityMasterYearlyData_MGTL] '3 Month',2019,'2019-01-01 00:00:00.000','2019-05-01 00:00:00.000','View'
[S_GetActivityMasterYearlyData_MGTL] '6 Month',2019,'2019-01-01 00:00:00.000','2019-05-01 00:00:00.000','View'
[S_GetActivityMasterYearlyData_MGTL] '1 Year',2019,'2019-01-01 00:00:00.000','2019-05-01 00:00:00.000','View'

Activity	FreqID	ActivityDate
Check operating pressure of hydraulic unit daily 10 to 12 Bar	8	2019-04-25 00:00:00.000

S_GetActivityMasterYearlyData_MGTL 'Weekly','2021','2021-08-04 18:37:00.000','2021-08-10 18:37:00.000','View','','TEST01'
***************************************************************************************************/  
CREATE PROCEDURE [dbo].[S_GetActivityMasterYearlyData_MGTL]  
@Frequency  nvarchar(100),
@Year INT,
@SDate datetime,
@NewDate datetime = '',
@param nvarchar(50) ='',
@Activity nvarchar(100)='',
@MachineID NVARCHAR(50)=''

AS
BEGIN

DECLARE @EndOfYear datetime
DECLARE @Activityday datetime
DECLARE @freqType  nvarchar(50)
DECLARE @FrequencyValue int
DECLARE @Frequencyid int
DECLARE @ColumnName NVARCHAR(MAX)  
DECLARE @query NVARCHAR(MAX)  
IF @Year = ''
BEGIN
SELECT @Year = YEAR (GETDATE())
END

 Select @EndOfYear=  DATEADD(yy, DATEDIFF(yy, 0, @SDate) + 1, -1)
 Select @Activityday = @SDate
 Select @freqType=FreqType from ActivityFreq_MGTL where Frequency=@frequency	
 Select @FrequencyValue= Freqvalue from ActivityFreq_MGTL where Frequency=@frequency	
 Select @Frequencyid= FreqID from ActivityFreq_MGTL where Frequency=@frequency


IF @param = 'Update'
BEGIN
 IF EXISTS (SELECT * FROM [ActivityMasterYearlyData_MGTL] WHERE FreqID = @Frequencyid and 
 ActivityID = @Activity and year = @Year and MachineID=@MachineID and ActivityDate=@SDate)
  BEGIN

   UPDATE  [ActivityMasterYearlyData_MGTL] 
   SET ActivityDate = @NewDate
   WHERE FreqID = @Frequencyid 
   and ActivityID = @Activity
   and ActivityDate = @SDate
   and year = @Year
   and MachineID=@MachineID
  END 
END


ELSE IF @param = 'View'
BEGIN
 
 CREATE TABLE #ActivityMaster
 (
	[MachineID] NVARCHAR(50),
	[ActivityID] [int] NOT NULL,
	[Activity] [nvarchar](100),
	[FreqID] [int],
	Frequency [nvarchar](50),
	[ActivityDate] [datetime],
	[year] [int],
	DisplayActivityStart  [nvarchar](100)
)


 INSERT INTO #ActivityMaster (ActivityID,Activity,FreqID,ActivityDate,year,Frequency,MachineID)
  SELECT ActivityID,Activity,FreqID,ActivityDate,year,@Frequency,@MachineID FROM [ActivityMasterYearlyData_MGTL]
  WHERE FreqID = @Frequencyid
  AND YEAR = @Year  
  AND (ActivityDate >= @SDate AND ActivityDate <=@NewDate ) AND Machineid=@MachineID
  ORDER BY ActivityDate


	IF @freqType = 'Daily'
	BEGIN
	print @Frequency
	 IF @Frequency = 'Weekly'
		BEGIN
		Update #ActivityMaster set DisplayActivityStart = 'Week'+convert(nvarchar (10),(datediff(week, dateadd(week, datediff(week, 0, dateadd(month, datediff(month, 0, ActivityDate), 0)), 0), ActivityDate - 1) + 1)) +' ' + cast(datename(mm,ActivityDate) as nvarchar(3)) + ' ' + cast(year(ActivityDate)as nvarchar)
		END
    ELSE 
	 BEGIN
		Update #ActivityMaster set DisplayActivityStart = cast(datepart(dd,ActivityDate) as nvarchar(2)) + ' ' + cast(datename(mm,ActivityDate) as nvarchar(3)) + ' ' + cast(year(ActivityDate)as nvarchar)
		from #ActivityMaster
	  END 
    END

	IF @freqType = 'Month'
		BEGIN
		Update #ActivityMaster set DisplayActivityStart = cast(datename(mm,ActivityDate) as nvarchar(3)) + ' ' + cast(year(ActivityDate)as nvarchar)  from #ActivityMaster
		END

	IF @freqType = 'Year'
		BEGIN
		Update #ActivityMaster set DisplayActivityStart = cast(year(ActivityDate)as nvarchar)  from #ActivityMaster 
		END

--SELECT * FROM #ActivityMaster ORDER BY ActivityDate

select @ColumnName = STUFF((SELECT ',' + QUOTENAME(T.DisplayActivityStart)
from
(
SELECT MAX(ActivityDate) as ActivityDate,DisplayActivityStart AS DisplayActivityStart
FROM #ActivityMaster
group by DisplayActivityStart
) AS T 
Order by T.ActivityDate        
FOR XML PATH(''), TYPE                
).value('.', 'NVARCHAR(MAX)')                 
,1,1,'')

/*
select @ColumnName = STUFF((SELECT distinct ',' + QUOTENAME(DisplayActivityStart)
from #ActivityMaster 
group by ActivityDate,DisplayActivityStart
Order by ActivityDate           
FOR XML PATH(''), TYPE                
).value('.', 'NVARCHAR(MAX)')                 
,1,1,'')
*/

PRINT @ColumnName

set @query = 'SELECT ROW_NUMBER() OVER(Order by activityid) as [Sl No],MachineID,ActivityID,Activity,Frequency, ' + @columnname + '
From 
             (
                select ActivityID,Activity,Frequency,ActivityDate,DisplayActivityStart,Machineid
                from #ActivityMaster
            ) x
            pivot 
            (
               max(ActivityDate)
                for DisplayActivityStart in (' + @ColumnName + ')
            ) p1
order by ActivityID'

print @query
EXEC sp_executesql @query
 return
end


ELSE
BEGIN

 IF EXISTS (SELECT * FROM [ActivityMasterYearlyData_MGTL] WHERE FreqID = @Frequencyid and machineid=@machineid)
  BEGIN
   DELETE FROM  [ActivityMasterYearlyData_MGTL] WHERE FreqID = @Frequencyid AND YEAR = @Year and  machineid=@machineid
  END 

CREATE TABLE #Time_d
(
ACTIVITYDATE datetime
)

PRINT @Activityday
PRINT @EndOfYear
IF @freqType = 'Daily'
   BEGIN
	PRINT 'INSIDE DAILY'
	 WHILE @Activityday<=@EndOfYear
	 BEGIN
	  INSERT INTO #Time_d (ACTIVITYDATE)
	  VALUES(@Activityday)
	 -- SELECT @Activityday = dateadd(d, (datediff(d, 0, @Activityday + @FrequencyValue)) , 0) 
	 SELECT @Activityday = dateadd(d,@FrequencyValue,@Activityday)
	 end

   END

IF @freqType = 'Month'
   BEGIN
	
	 WHILE @Activityday<=@EndOfYear
	 BEGIN
	  INSERT INTO #Time_d (ACTIVITYDATE)
	  VALUES(@Activityday)
	  SELECT @Activityday =  DATEADD(month,@FrequencyValue, @Activityday )
	 END

   END

 IF @freqType = 'Year'
 BEGIN

	If @Frequency = '2 Year'
	BEGIN

	  IF NOT EXISTS (SELECT * FROM [ActivityMasterYearlyData_MGTL] WHERE @Year + 1 = YEAR AND  FREQID = @Frequencyid)
	   BEGIN
		Select @EndOfYear=  DATEADD(yy, DATEDIFF(yy, 0, (DATEADD(year,@FrequencyValue,@Activityday))) + 1, -1)
		WHILE @Activityday<=@EndOfYear
		 BEGIN
		 INSERT INTO #Time_d (ACTIVITYDATE)
		 VALUES(@Activityday)
		 SELECT @Activityday =  DATEADD(year,@FrequencyValue,@Activityday)
		END
	   END
	END
	ELSE 
	BEGIN 
	  INSERT INTO #Time_d (ACTIVITYDATE)
	  VALUES(@Activityday)
	END
	

 END

   insert into [ActivityMasterYearlyData_MGTL] (ActivityID,Activity,FreqID,ActivityDate,year,machineid)
   select ActivityID,Activity,FreqID,ACTIVITYDATE, YEAR (ACTIVITYDATE),MachineID FROM  [ActivityMaster_MGTL] 
   CROSS JOIN #Time_d
   WHERE FreqID = @Frequencyid AND MachineID=@MachineID

  
END
END
