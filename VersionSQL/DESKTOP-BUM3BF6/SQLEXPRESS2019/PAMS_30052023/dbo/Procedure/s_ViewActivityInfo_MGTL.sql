/****** Object:  Procedure [dbo].[s_ViewActivityInfo_MGTL]    Committed by VersionSQL https://www.versionsql.com ******/

/*-- =============================================
-- Author:		Anjana  C V
-- Create date: 15 NOV 2018
-- Modified date: 16 NOV 2018
-- Description:	View Activity Information with Pending , Completed task details

--[dbo].[s_ViewActivityInfo_MGTL] 'CNC GRINDING','3 Month','2019-01-24 00:00:00','current','3'
--[dbo].[s_ViewActivityInfo_MGTL] 'CNC GRINDING','3 Month','2019-01-24 00:00:00','Previous','3'
--[dbo].[s_ViewActivityInfo_MGTL] 'CNC GRINDING','3 Month','2019-01-24 00:00:00','Next','3'

--[dbo].[s_ViewActivityInfo_MGTL] 'CNC GRINDING','1 Year','2019-01-24 00:00:00','current','1'
--[dbo].[s_ViewActivityInfo_MGTL] 'CNC GRINDING','1 Year','2019-01-24 00:00:00','Previous','1'
--[dbo].[s_ViewActivityInfo_MGTL] 'CNC GRINDING','1 Year','2019-01-24 00:00:00','Next','1'

--[dbo].[s_ViewActivityInfo_MGTL] 'CNC GRINDING','2 Year','2018-08-31 12:19:00','current','2'
--[dbo].[s_ViewActivityInfo_MGTL] 'CNC GRINDING','2 Year','2018-08-31 12:19:00','Previous','2'
--[dbo].[s_ViewActivityInfo_MGTL] 'CNC GRINDING','2 Year','2018-08-31 12:19:00','Next','2'

exec [dbo].[s_ViewActivityInfo_MGTL] @frequency=N'Weekly',@machineid=N'TEST01',@Starttime=N'2021-06-01 06:00:00',@Screen=N'current',@FrequencyValue=N'9',@View=N'Report'

-- ============================================= */
CREATE    PROCEDURE [dbo].[s_ViewActivityInfo_MGTL]
@machineid nvarchar(50),
@frequency as nvarchar(50),
@Starttime as Datetime,
@Endtime as Datetime='',
@Screen nvarchar(50) ='current', --current/Previous/next
@FrequencyValue int,
@View nvarchar(50)=''

WITH RECOMPILE
AS
BEGIN

SET NOCOUNT ON;

DECLARE @Frequencyid INT
declare @freqval as int
declare @interval as int
declare @freqType as nvarchar(50)

Create table #ActivityInfo
(
ActivityID int,
Activity nvarchar(100), 
Act nvarchar(10),
Frequency nvarchar(50),
LastUpdated datetime,
--LastUpdated nvarchar(50),
ActivityDate datetime,
ActivityTS datetime,
ActivityStatus nvarchar(50) default 'U',
DisplayActivityStart nvarchar(50)
)

Create table #frequency
(
ActivityDate datetime,
DisplayActivityStart nvarchar(50)
)



Select @freqval=Freqvalue from ActivityFreq_MGTL where Frequency=@frequency	
Select @freqType=FreqType from ActivityFreq_MGTL where Frequency=@frequency
Select @Frequencyid= FreqID from ActivityFreq_MGTL where Frequency=@frequency


DECLARE @query AS NVARCHAR(MAX)
DECLARE @ColumnName AS NVARCHAR(MAX)

IF (@View = '' or isnull(@View,'')='')
BEGIN
			if @screen='Current'
			begin
				Insert into #frequency(ActivityDate)
	  				SELECT DISTINCT TOP 6 CAST (ActivityDate AS DATE) 
					FROM ActivityMasterYearlyData_MGTL
					WHERE  CAST (ActivityDate AS DATE) <= CAST (@Starttime as DATE)
					AND FreqID = @Frequencyid and MachineID=@machineid
					ORDER BY CAST (ActivityDate AS DATE)  DESC

				Insert into #frequency(ActivityDate)
	  				SELECT DISTINCT TOP 5 CAST (ActivityDate AS DATE) 
					FROM ActivityMasterYearlyData_MGTL
					WHERE  CAST (ActivityDate AS DATE) > CAST (@Starttime as DATE)
					AND FreqID = @Frequencyid and MachineID=@machineid
					ORDER BY CAST (ActivityDate AS DATE)  

			end

			if @screen='Previous'
			begin
				Insert into #frequency(ActivityDate)
				 SELECT DISTINCT TOP 11 CAST (ActivityDate AS DATE) 
				 FROM ActivityMasterYearlyData_MGTL
				 WHERE  CAST (ActivityDate AS DATE) < CAST (@Starttime as DATE)
				 AND FreqID = @Frequencyid and MachineID=@machineid
				 ORDER BY CAST (ActivityDate AS DATE)  DESC

		 
			end
	
			if @screen='Next'
			begin
				Insert into #frequency(ActivityDate)
				 SELECT DISTINCT TOP 11 CAST (ActivityDate AS DATE)
				 FROM ActivityMasterYearlyData_MGTL
				 WHERE  CAST (ActivityDate AS DATE) > CAST (@Starttime as DATE)
				 AND FreqID = @Frequencyid and MachineID=@machineid
				 ORDER BY CAST (ActivityDate AS DATE)  

				-- select * from #frequency
			end

			IF @freqType = 'Daily'
			BEGIN
			Update #frequency set DisplayActivityStart = cast(datepart(dd,ActivityDate) as nvarchar(2)) + ' ' + cast(datename(mm,ActivityDate) as nvarchar(3)) + ' ' + cast(year(ActivityDate)as nvarchar)
			from #frequency
			END 

			IF @freqType = 'Month'
			BEGIN
			Update #frequency set DisplayActivityStart = cast(datename(mm,ActivityDate) as nvarchar(3)) + ' ' + cast(year(ActivityDate)as nvarchar)  from #frequency
			END

			IF @freqType = 'Year'
			BEGIN
			Update #frequency set DisplayActivityStart = cast(year(ActivityDate)as nvarchar)  from #frequency 
			END


		Insert into #ActivityInfo(ActivityID,Activity,Act,Frequency,LastUpdated,ActivityDate,DisplayActivityStart,ActivityTS)
		Select  AM.activityid,AM.Activity,'1R',AF.Frequency,'1900-01-01',F.ActivityDate,F.DisplayActivityStart,'1900-01-01' 
		from ActivityMasterYearlyData_MGTL AM
		inner join ActivityFreq_MGTL AF on AM.FreqID=AF.FreqID
		CROSS JOIN #frequency F
		WHERE AF.FreqID = @Frequencyid AND AM.MACHINEID=@machineid

	
		--update #ActivityInfo set ActivityTS = A.ATS from
		--(Select AI.activityid,AI.frequency,AI.ActivityDate,MAX(A.ActivityDoneTS) as ats from #ActivityInfo Ai
		--inner join ActivityTransaction_MGTL A on Ai.ActivityID=A.ActivityID and Ai.Frequency=A.Frequency
		--where cast(A.ActivityTS as date)=cast (AI.ActivityDate as date)  and Machineid=@machineid
		--group by AI.activityid,AI.frequency,AI.ActivityDate
		--)A inner join #ActivityInfo Ai on Ai.ActivityID=A.ActivityID 
		--and Ai.ActivityDate =A.ActivityDate 

		update #ActivityInfo set ActivityTS = A.ATS from
		(Select AI.activityid,AI.frequency,AI.ActivityDate,MAX(A.ActivityDoneTS) as ats from #ActivityInfo Ai
		inner join ActivityTransaction_MGTL A on Ai.ActivityID=A.ActivityID and Ai.Frequency=A.Frequency
		where Datepart(Year,cast(A.ActivityTS as date))=Datepart(year,cast (AI.ActivityDate as date))
		and Datepart(month,cast(A.ActivityTS as date))=Datepart(month,cast (AI.ActivityDate as date)) 
		and AI.Frequency Like '%Month%'
		and Machineid=@machineid
		group by AI.activityid,AI.frequency,AI.ActivityDate
		)A inner join #ActivityInfo Ai on Ai.ActivityID=A.ActivityID 
		and Ai.ActivityDate =A.ActivityDate 

		update #ActivityInfo set ActivityTS = A.ATS from
		(Select AI.activityid,AI.frequency,AI.ActivityDate,MAX(A.ActivityDoneTS) as ats from #ActivityInfo Ai
		inner join ActivityTransaction_MGTL A on Ai.ActivityID=A.ActivityID and Ai.Frequency=A.Frequency
		where Datepart(Year,cast(A.ActivityTS as date))=Datepart(year,cast (AI.ActivityDate as date))
		and AI.Frequency Like '%Year%'
		and Machineid=@machineid
		group by AI.activityid,AI.frequency,AI.ActivityDate
		)A inner join #ActivityInfo Ai on Ai.ActivityID=A.ActivityID 
		and Ai.ActivityDate =A.ActivityDate 

		update #ActivityInfo set ActivityTS = A.ATS from
		(Select AI.activityid,AI.frequency,AI.ActivityDate,MAX(A.ActivityDoneTS) as ats from #ActivityInfo Ai
		inner join ActivityTransaction_MGTL A on Ai.ActivityID=A.ActivityID and Ai.Frequency=A.Frequency
		where cast(A.ActivityTS as date)=cast (AI.ActivityDate as date)
		and AI.Frequency in ('Daily','Weekly','15 Days')
		and Machineid=@machineid
		group by AI.activityid,AI.frequency,AI.ActivityDate
		)A inner join #ActivityInfo Ai on Ai.ActivityID=A.ActivityID 
		and Ai.ActivityDate =A.ActivityDate 

		update #ActivityInfo set ActivityStatus=A.Astatus from
		(
		Select AI.activityid,AI.frequency,AI.ActivityDate,
		--case when Ai.activityts='1900-01-01' and convert(nvarchar(20),ActivityDate,120)< convert(nvarchar(20),@Starttime,120) then 'P'
		case when Ai.activityts='1900-01-01' and convert(nvarchar(20),ActivityDate,120)< convert(nvarchar(20),getdate(),120) then 'P'
		when Ai.activityts<>'1900-01-01' then 'C' 
		else 'U' end as Astatus 
		from #ActivityInfo Ai
		)A inner join #ActivityInfo Ai on Ai.ActivityID=A.ActivityID 
		and Ai.ActivityDate=A.ActivityDate

		update #ActivityInfo set ActivityStatus=A.Astatus from
		(
		Select AI.activityid,AI.frequency,AI.ActivityDate,
		'NON' AS Astatus
		from #ActivityInfo Ai
		WHERE NOT EXISTS(
		SELECT * FROM ActivityMasterYearlyData_MGTL 
		WHERE cast(ActivityDate as date) = cast(AI.ActivityDate as date) and MachineID=@machineid
		AND Frequency = AI.frequency AND ActivityID = AI.ActivityID 
		)
		)A inner join #ActivityInfo Ai on Ai.ActivityID=A.ActivityID 
		and Ai.ActivityDate=A.ActivityDate

		update #ActivityInfo set LastUpdateD = A.TS from
		 (select activityid,Max(ActivityDoneTS)  as TS 
		 from ActivityTransaction_MGTL 
		 WHERE Frequency = @frequency
		 and Machineid = @machineid
		 group by ActivityID
		 )A 
		 inner join #ActivityInfo  on #ActivityInfo.ActivityID=A.ActivityID
		 where A.Ts<>'1900-01-01 00:00:000'

		update #ActivityInfo set LastUpdated=NULL where LastUpdated='1900-01-01 00:00:000'

		select @ColumnName = STUFF((SELECT  ',' + QUOTENAME(DisplayActivityStart)
		from #frequency 
		group by ActivityDate,DisplayActivityStart
		Order by ActivityDate           
		FOR XML PATH(''), TYPE                
		).value('.', 'NVARCHAR(MAX)')                 
		,1,1,'')

		set @query = 'SELECT ROW_NUMBER() OVER(Order by activityid) as [Sl No], Activity,Act,Frequency, LastUpdated as LastUpdate,' + @columnname + ',ActivityID 
		From 
					 (
						select Act,ActivityID,Activity,LastUpdated,Frequency,DisplayActivityStart,ActivityStatus
						from #ActivityInfo
					) x
					pivot 
					(
					   max(ActivityStatus)
						for DisplayActivityStart in (' + @ColumnName + ')
					) p1
		order by ActivityID'
		print @query
		EXEC sp_executesql @query
END

IF @View ='Report'
BEGIN
		if @screen='Current'
		begin
			Insert into #frequency(ActivityDate)
	  			SELECT DISTINCT TOP 11 CAST (ActivityDate AS DATE) 
				FROM ActivityMasterYearlyData_MGTL
				WHERE  (CAST (ActivityDate AS DATE) >= CAST (@Starttime as DATE) and CAST (ActivityDate AS DATE) <= CAST (@Endtime as DATE))
				AND FreqID = @Frequencyid and MachineID=@machineid
				ORDER BY CAST (ActivityDate AS DATE)  DESC
		end
		
		if @screen='Previous'
		begin
			Insert into #frequency(ActivityDate)
			 SELECT DISTINCT TOP 11 CAST (ActivityDate AS DATE) 
			 FROM ActivityMasterYearlyData_MGTL
			 WHERE  (CAST (ActivityDate AS DATE) >= CAST (@Starttime as DATE) and CAST (ActivityDate AS DATE) <= CAST (@Endtime as DATE))
			 AND FreqID = @Frequencyid and MachineID=@machineid
			 ORDER BY CAST (ActivityDate AS DATE)  DESC

		 
		end
	
		if @screen='Next'
		begin
			Insert into #frequency(ActivityDate)
			 SELECT DISTINCT TOP 11 CAST (ActivityDate AS DATE)
			 FROM ActivityMasterYearlyData_MGTL
			 WHERE  (CAST (ActivityDate AS DATE) >= CAST (@Starttime as DATE) and CAST (ActivityDate AS DATE) <= CAST (@Endtime as DATE))
			 AND FreqID = @Frequencyid and MachineID=@machineid
			 ORDER BY CAST (ActivityDate AS DATE)  
		end

		IF @freqType = 'Daily'
		BEGIN
		Update #frequency set DisplayActivityStart = cast(datepart(dd,ActivityDate) as nvarchar(2)) + ' ' + cast(datename(mm,ActivityDate) as nvarchar(3)) + ' ' + cast(year(ActivityDate)as nvarchar)
		from #frequency
		END 

		IF @freqType = 'Month'
		BEGIN
		Update #frequency set DisplayActivityStart = cast(datename(mm,ActivityDate) as nvarchar(3)) + ' ' + cast(year(ActivityDate)as nvarchar)  from #frequency
		END

		IF @freqType = 'Year'
		BEGIN
		Update #frequency set DisplayActivityStart = cast(year(ActivityDate)as nvarchar)  from #frequency 
		END

	

	Insert into #ActivityInfo(ActivityID,Activity,Act,Frequency,LastUpdated,ActivityDate,DisplayActivityStart,ActivityTS)
	Select  AM.activityid,AM.Activity,'1R',AF.Frequency,'1900-01-01',F.ActivityDate,F.DisplayActivityStart,'1900-01-01' 
	from ActivityMasterYearlyData_MGTL AM
	inner join ActivityFreq_MGTL AF on AM.FreqID=AF.FreqID
	CROSS JOIN #frequency F
	WHERE AF.FreqID = @Frequencyid AND AM.MACHINEID=@machineid

	


	update #ActivityInfo set ActivityTS = A.ATS from
	(Select AI.activityid,AI.frequency,AI.ActivityDate,MAX(A.ActivityDoneTS) as ats from #ActivityInfo Ai
	inner join ActivityTransaction_MGTL A on Ai.ActivityID=A.ActivityID and Ai.Frequency=A.Frequency
	where Datepart(Year,cast(A.ActivityTS as date))=Datepart(year,cast (AI.ActivityDate as date))
	and Datepart(month,cast(A.ActivityTS as date))=Datepart(month,cast (AI.ActivityDate as date)) 
	and AI.Frequency Like '%Month%'
	and Machineid=@machineid
	group by AI.activityid,AI.frequency,AI.ActivityDate
	)A inner join #ActivityInfo Ai on Ai.ActivityID=A.ActivityID 
	and Ai.ActivityDate =A.ActivityDate 

	update #ActivityInfo set ActivityTS = A.ATS from
	(Select AI.activityid,AI.frequency,AI.ActivityDate,MAX(A.ActivityDoneTS) as ats from #ActivityInfo Ai
	inner join ActivityTransaction_MGTL A on Ai.ActivityID=A.ActivityID and Ai.Frequency=A.Frequency
	where Datepart(Year,cast(A.ActivityTS as date))=Datepart(year,cast (AI.ActivityDate as date))
	and AI.Frequency Like '%Year%'
	and Machineid=@machineid
	group by AI.activityid,AI.frequency,AI.ActivityDate
	)A inner join #ActivityInfo Ai on Ai.ActivityID=A.ActivityID 
	and Ai.ActivityDate =A.ActivityDate 

	update #ActivityInfo set ActivityTS = A.ATS from
	(Select AI.activityid,AI.frequency,AI.ActivityDate,MAX(A.ActivityDoneTS) as ats from #ActivityInfo Ai
	inner join ActivityTransaction_MGTL A on Ai.ActivityID=A.ActivityID and Ai.Frequency=A.Frequency
	where cast(A.ActivityTS as date)=cast (AI.ActivityDate as date)
	and AI.Frequency in ('Daily','Weekly','15 Days')
	and Machineid=@machineid
	group by AI.activityid,AI.frequency,AI.ActivityDate
	)A inner join #ActivityInfo Ai on Ai.ActivityID=A.ActivityID 
	and Ai.ActivityDate =A.ActivityDate 

	update #ActivityInfo set ActivityStatus=A.Astatus from
	(
	Select AI.activityid,AI.frequency,AI.ActivityDate,
	--case when Ai.activityts='1900-01-01' and convert(nvarchar(20),ActivityDate,120)< convert(nvarchar(20),@Starttime,120) then 'P'
	case when Ai.activityts='1900-01-01' and convert(nvarchar(20),ActivityDate,120)< convert(nvarchar(20),getdate(),120) then 'P'
	when Ai.activityts<>'1900-01-01' then 'C' 
	else 'U' end as Astatus 
	from #ActivityInfo Ai
	)A inner join #ActivityInfo Ai on Ai.ActivityID=A.ActivityID 
	and Ai.ActivityDate=A.ActivityDate

	update #ActivityInfo set ActivityStatus=A.Astatus from
	(
	Select AI.activityid,AI.frequency,AI.ActivityDate,
	'NON' AS Astatus
	from #ActivityInfo Ai
	WHERE NOT EXISTS(
	SELECT * FROM ActivityMasterYearlyData_MGTL 
	WHERE cast(ActivityDate as date) = cast(AI.ActivityDate as date) and MachineID=@machineid
	AND Frequency = AI.frequency AND ActivityID = AI.ActivityID 
	)
	)A inner join #ActivityInfo Ai on Ai.ActivityID=A.ActivityID 
	and Ai.ActivityDate=A.ActivityDate

	update #ActivityInfo set LastUpdateD = A.TS from
	 (select activityid,Max(ActivityDoneTS)  as TS 
	 from ActivityTransaction_MGTL 
	 WHERE Frequency = @frequency
	 and Machineid = @machineid
	 group by ActivityID
	 )A 
	 inner join #ActivityInfo  on #ActivityInfo.ActivityID=A.ActivityID
	 where A.Ts<>'1900-01-01 00:00:000'

	update #ActivityInfo set LastUpdated=NULL where LastUpdated='1900-01-01 00:00:000'

	select @ColumnName = STUFF((SELECT  ',' + QUOTENAME(DisplayActivityStart)
	from #frequency 
	group by ActivityDate,DisplayActivityStart
	Order by ActivityDate           
	FOR XML PATH(''), TYPE                
	).value('.', 'NVARCHAR(MAX)')                 
	,1,1,'')

	set @query = 'SELECT ROW_NUMBER() OVER(Order by activityid) as [Sl No], Activity,Act,Frequency, LastUpdated as LastUpdate,' + @columnname + ',ActivityID 
	From 
				 (
					select Act,ActivityID,Activity,LastUpdated,Frequency,DisplayActivityStart,ActivityStatus
					from #ActivityInfo
				) x
				pivot 
				(
				   max(ActivityStatus)
					for DisplayActivityStart in (' + @ColumnName + ')
				) p1
	order by ActivityID'
	print @query
	EXEC sp_executesql @query
END

End
