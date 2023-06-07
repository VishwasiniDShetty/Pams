/****** Object:  Procedure [dbo].[s_JohnCrane_GetQualityDetails]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[s_JohnCrane_GetQualityDetails] '2017-12-19','2017-12-30','LT 2 LM 500 MSY','Day','All'

--[dbo].[s_JohnCrane_GetQualityDetails] '2017-12-19','2017-12-30','LT 2 LM 500 MSY','Day','Last'



--[dbo].[s_JohnCrane_GetQualityDetails] '2017-12-19','2017-12-30','LT 2 LM 500 MSY','Shift','All'

--[dbo].[s_JohnCrane_GetQualityDetails] '2017-12-19','2017-12-30','LT 2 LM 500 MSY','Shift','Last'





CREATE PROCEDURE [dbo].[s_JohnCrane_GetQualityDetails]

@FromDate Datetime,

@ToDate Datetime,

@Machineid nvarchar(50),

@ReportBy nvarchar(50),

@ShowRecord nvarchar(50)

AS

BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from

	-- interfering with SELECT statements.

SET NOCOUNT ON;



CREATE TABLE #Quality

(

	[MachineID] [nvarchar](50),

	[Shift] nvarchar(20),

	[LineInspected] float,

	[NCLines] float,

	[EQP] [int],

	[IQP] [int],

	[EQPThreshold] [int],

	[IQPThreshold] [int],

	[TimeStamp] [datetime],

	[Efficiency] Float,

	[TransNCLines] float,

	[TransLinesInspected] float,

	[Resettime] float

) ON [PRIMARY]


CREATE TABLE #LatestQualityRecord

(

	[MachineID] [nvarchar](50),

	[Shift] nvarchar(20),

	[LineInspected] float,

	[NCLines] float,

	[EQP] [int],

	[IQP] [int],

	[EQPThreshold] [int],

	[IQPThreshold] [int],

	[TimeStamp] [datetime],

	[Efficiency] Float,

	[TransNCLines] float,

	[TransLinesInspected] float

) ON [PRIMARY]


Create table #DayOrShift

(

	Starttime datetime,

	ShiftDate datetime,

	Shiftname nvarchar(20),

	Endtime datetime

)



Declare @Startdate as datetime

Declare @Enddate as datetime



Select @Startdate=@FromDate



If @ReportBy = 'Day'

Begin



	While @Startdate<=@ToDate

	Begin

		Insert into #DayOrShift(Starttime,Endtime)

		Select dbo.f_GetLogicalDay(@Startdate,'start'),dbo.f_GetLogicalDay(@Startdate,'End')

		Select @Startdate = Dateadd(day,1,@Startdate)

	End



	Select @Startdate=Min(Starttime) From #DayOrShift

	Select @Enddate=Max(Endtime) From #DayOrShift



	If @ShowRecord = 'All' or @ShowRecord = 'Last'

	Begin

		Insert into #Quality(MachineID, LineInspected, NCLines, EQP, IQP, EQPThreshold, IQPThreshold, TimeStamp , Efficiency,[TransNCLines],[TransLinesInspected])

		SELECT M.MachineID, LineInspected, NCLines, EQP, IQP, EQPThreshold, IQPThreshold, TimeStamp ,0,[TransNCLines],[TransLinesInspected]

		FROM JohnCrane_LineInspection J 

		inner join Machineinformation M on M.interfaceid=J.Machineid 

		Where Datatype='46' and M.Machineid=@Machineid and ([TimeStamp]>=@Startdate and [TimeStamp]<=@Enddate)

		Update #Quality SET Efficiency = ROUND(([TransNCLines]/[TransLinesInspected])*100,2) Where LineInspected>0


	End



	If @ShowRecord = 'Last'

	Begin

		Insert into #LatestQualityRecord(MachineID, LineInspected, NCLines, EQP, IQP, EQPThreshold, IQPThreshold, TimeStamp , Efficiency,[TransNCLines],[TransLinesInspected])

		SELECT TOP 1 M.MachineID, LineInspected, NCLines, EQP, IQP, EQPThreshold, IQPThreshold, TimeStamp ,0,[TransNCLines],[TransLinesInspected]

		FROM JohnCrane_LineInspection J 

		inner join Machineinformation M on M.interfaceid=J.Machineid 

		Where Datatype='46' and M.Machineid=@Machineid and ([TimeStamp]>=@Startdate and [TimeStamp]<=@Enddate)

		Order by TimeStamp Desc	

		Update #LatestQualityRecord SET Efficiency = ROUND(([TransNCLines]/[TransLinesInspected])*100,2) Where LineInspected>0


	End





End



If @ReportBy = 'Shift'

Begin



	While @Startdate<=@ToDate

	Begin

		Insert into #DayOrShift(ShiftDate,Shiftname,Starttime,Endtime)

		Exec s_GetShiftTime @StartDate,''

		Select @Startdate = Dateadd(day,1,@Startdate)

	End



	If @ShowRecord = 'All' or @ShowRecord = 'Last'

	Begin

		Insert into #Quality(MachineID,Shift, LineInspected, NCLines, EQP, IQP, EQPThreshold, IQPThreshold, TimeStamp , Efficiency,[TransNCLines],[TransLinesInspected])

		SELECT M.MachineID,S.Shiftname,J.LineInspected, J.NCLines, J.EQP, J.IQP, J.EQPThreshold, J.IQPThreshold, J.TimeStamp ,0,[TransNCLines],[TransLinesInspected]

		FROM JohnCrane_LineInspection J cross join #DayOrShift S	

		inner join Machineinformation M on M.interfaceid=J.Machineid 

		Where Datatype='46' and M.Machineid=@Machineid and ([TimeStamp]>=S.Starttime and [TimeStamp]<=S.Endtime)

		Update #Quality SET Efficiency = ROUND(([TransNCLines]/[TransLinesInspected])*100,2) Where LineInspected>0

	End



	If @ShowRecord = 'Last'

	Begin

		Insert into #LatestQualityRecord(MachineID,Shift, LineInspected, NCLines, EQP, IQP, EQPThreshold, IQPThreshold, TimeStamp , Efficiency,[TransNCLines],[TransLinesInspected])

		Select T.MachineID,T.Shiftname,T.LineInspected, T.NCLines, T.EQP, T.IQP, T.EQPThreshold, T.IQPThreshold, T.TimeStamp ,0  as Efficiency,[TransNCLines],[TransLinesInspected] from

		(

		SELECT M.MachineID,S.Shiftname,J.LineInspected, J.NCLines, J.EQP, J.IQP, J.EQPThreshold, J.IQPThreshold, J.TimeStamp,J.[TransNCLines],J.[TransLinesInspected],

		ROW_NUMBER() OVER(PARTITION BY S.Shiftname ORDER BY S.Shiftname,J.TimeStamp desc) as rn

		FROM JohnCrane_LineInspection J cross join #DayOrShift S	

		inner join Machineinformation M on M.interfaceid=J.Machineid 

		Where Datatype='46' and M.Machineid=@Machineid and ([TimeStamp]>=S.Starttime and [TimeStamp]<=S.Endtime)

		)T where T.rn=1
 	
		Update #LatestQualityRecord SET Efficiency = ROUND(([TransNCLines]/[TransLinesInspected])*100,2) Where LineInspected>0	

	End
End

DECLARE @machintid AS INT
SELECT @machintid = interfaceid FROM machineinformation WHERE machineid=@machineid

Update #Quality set [Resettime]=T.NCResetTime from
(SELECT main.Timestamp,CASE WHEN main.TransNCLines>0 THEN datediff(s, main.TimeStamp, (SELECT MIN(timestamp) FROM [JohnCrane_LineInspection] sub WHERE sub.datatype = 47 AND sub.timestamp > main.timestamp and sub.machineid=@machintid)) END as NCResetTime
FROM #Quality AS main)T inner join #Quality Q on Q.timestamp=T.timestamp

If @ShowRecord = 'Last'
Begin

SELECT main.timestamp, Row_Number() Over(Order by main.TimeStamp) as Slno,Shift, main.[TransLinesInspected] as LineInspected, main.[TransNCLines] as NCLines, 
ISNULL([TransLinesInspected],0)-ISNULL([TransNCLines],0) as OKParts,
main.EQP, main.IQP, main.EQPThreshold, main.IQPThreshold, Efficiency, [dbo].[f_FormatTime](CASE WHEN TransNCLines>0 then datediff(s, main.TimeStamp, (SELECT MIN(timestamp) FROM [JohnCrane_LineInspection] sub WHERE sub.datatype = 47 AND sub.timestamp > main.timestamp and sub.machineid=@machintid)) END, 'hh:mm:ss') as [Resettime]
FROM #LatestQualityRecord AS main

END


If @ShowRecord = 'All'
Begin

SELECT main.timestamp, Row_Number() Over(Order by main.TimeStamp) as Slno,Shift, main.[TransLinesInspected] as LineInspected, main.[TransNCLines] as NCLines, 
ISNULL([TransLinesInspected],0)-ISNULL([TransNCLines],0) as OKParts,
main.EQP, main.IQP, main.EQPThreshold, main.IQPThreshold, Efficiency, [dbo].[f_FormatTime]([Resettime],'hh:mm:ss') as [Resettime]
FROM #Quality AS main

END

Select ISNULL(SUM([TransLinesInspected]),0) as TotalLineInspected,ISNULL(SUM([TransNCLines]),0) as TotalNCLines,ISNULL(SUM([TransLinesInspected]),0)-ISNULL(SUM([TransNCLines]),0) as OKParts,
[dbo].[f_FormatTime](ISNULL(SUM([Resettime]),0),'hh:mm:ss') as TotalResettime From #Quality

--Select Row_Number() Over(Order by TimeStamp) as Slno,Shift, LineInspected, NCLines, EQP, IQP, EQPThreshold, IQPThreshold, TimeStamp , Efficiency,'12:00:00' as NCResetTime from #Quality Order by [TimeStamp]

--SELECT main.timestamp, Row_Number() Over(Order by main.TimeStamp) as Slno,Shift, main.LineInspected, main.NCLines, main.EQP, main.IQP, main.EQPThreshold, main.IQPThreshold, main.TimeStamp , Efficiency, [dbo].[f_FormatTime](CASE TransNCLines WHEN 0 THEN 0 ELSE datediff(s, main.TimeStamp, (SELECT MIN(timestamp) FROM [JohnCrane_LineInspection] sub WHERE sub.datatype = 47 AND sub.timestamp > main.timestamp and sub.machineid=@machintid)) END, 'hh:mm:ss') as NCResetTime
--FROM #Quality AS main


END
