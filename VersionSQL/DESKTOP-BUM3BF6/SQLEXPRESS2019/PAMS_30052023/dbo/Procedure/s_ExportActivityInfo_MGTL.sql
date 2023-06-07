/****** Object:  Procedure [dbo].[s_ExportActivityInfo_MGTL]    Committed by VersionSQL https://www.versionsql.com ******/

--exec s_ExportActivityInfo_MGTL @MachineID=N'Amit-01',@frequency=N'Daily',@Starttime='2021-02-01 02:48:23',@Endtime='2021-03-06 02:48:23',@FrequencyValue=1
--[dbo].[s_ExportActivityInfo_MGTL] 'CNC GRINDING','daily','2018-11-15 12:19:00','2018-12-30 12:19:00','1'

CREATE    PROCEDURE [dbo].[s_ExportActivityInfo_MGTL]
@machineid nvarchar(50),
@frequency as nvarchar(50),
@Starttime as Datetime,
@Endtime as Datetime,
@FrequencyValue int
WITH RECOMPILE
AS
BEGIN

SET NOCOUNT ON;

Create table #ActivityInfo
(
ActivityID int,
Activity nvarchar(100), 
Act nvarchar(10),
Frequency nvarchar(50),
ActivityStart datetime,
ActivityEnd datetime,
ActivityTS datetime,
ActivityStatus nvarchar(50) default 'U',
DisplayActivityStart nvarchar(50)
)

Create table #frequency
(
ActivityStart datetime,
ActivityEnd datetime,
DisplayActivityStart nvarchar(50)
)

declare @start as datetime
declare @end as datetime
declare @curtime as datetime

select @curtime=getdate() --@Starttime
select @start=@Starttime
Select @end=@Endtime

declare @freqType as nvarchar(50)
Select @freqType=FreqType from ActivityFreq_MGTL where Frequency=@frequency	


If @freqType='Month'
Begin
	While @start<=@end
	Begin
		Insert into #frequency(ActivityStart,ActivityEnd)
		Select dbo.f_GetLogicalMonth(@start,'start'),dbo.f_GetLogicalMonth(@start,'End')
		select @start=dateadd(month,@FrequencyValue,@start)
	End
	Update #frequency set DisplayActivityStart = cast(datename(mm,ActivityStart) as nvarchar(3)) + ' ' + cast(year(ActivityStart)as nvarchar)  from #frequency         
End

If @freqType='Year'
Begin

   Select @start = cast(datepart(yyyy,@start) as nvarchar(4))+ '-01' + '-01'        
   select @end = cast(datepart(yyyy,@end) as nvarchar(4))+ '-12' + '-31' 

	While @start<=@end
	Begin
		Insert into #frequency(ActivityStart,ActivityEnd)
		Select dbo.f_GetLogicalDayend(@start),dateadd(Year,@FrequencyValue,dbo.f_GetLogicalDayStart(@start))
		select @start=dateadd(Year,@FrequencyValue,@start)
	End
Update #frequency set DisplayActivityStart = cast(year(ActivityStart)as nvarchar)  from #frequency         

End


If @freqType='Daily'
Begin
	While @start<=@end
	Begin
		Insert into #frequency(ActivityStart,ActivityEnd)
		Select dbo.f_GetLogicalDayStart(@start),dbo.f_GetLogicalDayEnd(@start)
		select @start=dateadd(day,@FrequencyValue,@start)
	End
Update #frequency set DisplayActivityStart = cast(datepart(dd,ActivityStart) as nvarchar(2)) + ' ' + cast(datename(mm,ActivityStart) as nvarchar(3)) + ' ' + cast(year(ActivityStart)as nvarchar)  from #frequency         

End


Insert into #ActivityInfo(ActivityID,Activity,Act,Frequency,ActivityStart,ActivityEnd,DisplayActivityStart,ActivityTS)
Select AM.activityid,AM.Activity,'1R',@frequency,#frequency.ActivityStart,#frequency.ActivityEnd,#frequency.DisplayActivityStart,'1900-01-01' from ActivityMaster_MGTL AM
inner join ActivityFreq_MGTL AF on AM.FreqID=AF.FreqID
cross join #frequency where AF.Frequency=@frequency 

update #ActivityInfo set ActivityTS = A.ATS from
(Select AI.activityid,AI.frequency,AI.Activitystart,MAX(A.ActivityDoneTS) as ats from #ActivityInfo Ai
inner join ActivityTransaction_MGTL A on Ai.ActivityID=A.ActivityID and Ai.Frequency=A.Frequency and Ai.Activitystart=A.ActivityTS
where A.ActivityTS>=AI.ActivityStart and A.ActivityTS<=AI.ActivityEnd and Machineid=@machineid
group by AI.activityid,AI.frequency,AI.Activitystart)A inner join #ActivityInfo Ai on Ai.ActivityID=A.ActivityID and Ai.Activitystart=A.Activitystart


update #ActivityInfo set ActivityStatus=A.Astatus from
(Select AI.activityid,AI.frequency,AI.Activitystart,
case when Ai.activityts='1900-01-01' and convert(nvarchar(20),ActivityStart,120)<convert(nvarchar(20),@curtime,120) then 'P'
when Ai.activityts<>'1900-01-01' then cast(Ai.activityts as nvarchar(20)) else 'U' end as Astatus from #ActivityInfo Ai)A 
inner join #ActivityInfo Ai on Ai.ActivityID=A.ActivityID and Ai.Activitystart=A.Activitystart


DECLARE @query AS NVARCHAR(MAX)
DECLARE @ColumnName AS NVARCHAR(MAX)

select @ColumnName = STUFF((SELECT ',' + QUOTENAME(DisplayActivityStart)
from #frequency group by ActivityStart,DisplayActivityStart
Order by ActivityStart           
FOR XML PATH(''), TYPE                
).value('.', 'NVARCHAR(MAX)')                 
,1,1,'')


set @query = 'SELECT Activity,Act,Frequency,''1900-01-01 00:00:00'' as LastUpdate,' + @columnname + ',ActivityID  into ##ActivityInfo from 
             (
                select Act,ActivityID,Activity,Frequency,DisplayActivityStart,ActivityStatus
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

IF OBJECT_ID('tempdb.dbo.##ActivityInfo', 'U') IS NOT NULL
BEGIN

	update ##ActivityInfo set LastUpdate = A.TS from
	(select activityid,Max(ActivityTS)  as TS from #ActivityInfo group by ActivityID)A inner join ##ActivityInfo  on ##ActivityInfo.ActivityID=A.ActivityID
	where A.Ts<>'1900-01-01 00:00:00'

	update ##ActivityInfo set LastUpdate='' where LastUpdate='1900-01-01 00:00:00'
	 
	select ROW_NUMBER() OVER(Order by activityid) as [Sl No],* from ##ActivityInfo

	drop table ##ActivityInfo
END

End
