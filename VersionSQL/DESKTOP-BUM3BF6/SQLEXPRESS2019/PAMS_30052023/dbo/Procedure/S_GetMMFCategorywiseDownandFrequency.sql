/****** Object:  Procedure [dbo].[S_GetMMFCategorywiseDownandFrequency]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		Swathi KS
-- Create date: 2014-May-12
-- Description:	Created New Procedure to get Downtime and Downfrequency at DownCategory level.
-- =============================================
---[dbo].[S_GetMMfCategorywiseDownandFrequency] '2016-06-14 12:00:00','2016-06-15 12:00:00','CNC VTL','ACE VTL-04','','',''


CREATE PROCEDURE [dbo].[S_GetMMFCategorywiseDownandFrequency]

@Starttime datetime,
@Endtime datetime,
@PlantID nvarchar(50)='',
@MachineID nvarchar(50)='',
@DownCategory nvarchar(4000)='',
@DownID nvarchar(4000)='',
@Param nvarchar(50)=''

AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

create table #DownTimeData
(
	PlantID nvarchar(50),
	McInterfaceid nvarchar(50),
	Machineid nvarchar(50),
	DownCategory nvarchar(50),
	GroupID nvarchar(100),
	Downtime float,
	DownFreq int,
	TotalDownLossCategorywise float,
	TotalDownFreqCategorywise int,
	TotalDownLossMachinewise float,
	TotalDownFreqMachinewise int,
	PDT Float,
	ManagementLoss float,
	MLDown float
)

create table #FinalDownData
(
	PlantID nvarchar(50),
	McInterfaceid nvarchar(50),
	Machineid nvarchar(50),
	DownCategory nvarchar(50),
	GroupID nvarchar(100),
	DownID nvarchar(50),
	Downtime float,
	DownFreq int default 0,
	TotalDownLossCategorywise float,
	TotalDownFreqCategorywise int,
	TotalDownLossMachinewise float,
	TotalDownFreqMachinewise int,
	PDT Float,
	ManagementLoss float,
	MLDown float,
	Bookingtime float,
	Availabletime float
)

Create table #DownCategory
(
	DownCategory nvarchar(50),
	GroupID nvarchar(100),
	DownID nvarchar(50)
)



----Variable Declarations
declare @strsql nvarchar(4000)
Declare @StrPlant nvarchar(255)
declare @strMachine nvarchar(255)
declare @strDownCategory nvarchar(4000)
declare @strdownid nvarchar(4000)

select @strsql = ''
select @StrPlant = ''
select @strMachine = ''
select @strDownCategory = ''
select @strdownid = ''

IF ISNULL(@PlantID,'')<>''
BEGIN
SELECT @StrPlant=' And PlantMachine.PlantID=N'''+ @PlantID +''''
END

If isnull(@machineid,'') <> ''
BEGIN
select @strMachine = ' and (machineinformation.machineid = N''' + @machineid + ''')'
END

if isnull(@DownCategory, '') <> '' 
begin
select @strDownCategory = ' and downcategoryinformation.DownCategory in( ' + @DownCategory + ' )'
end

if isnull(@downid, '') <> '' 
begin
select @strdownid = ' and downcodeinformation.downid in( ' + @downid + ' )'
end


SELECT Machine,Interfaceid as MachineInterface,
	CASE When StartTime<@StartTime Then @StartTime Else StartTime End As StartTime,
	CASE When EndTime>@EndTime Then @EndTime Else EndTime End As EndTime
	INTO #PlannedDownTimes
FROM PlannedDownTimes inner join machineinformation on PlannedDownTimes.Machine=machineinformation.MachineID
WHERE PDTstatus = 1 And ((StartTime >= @StartTime  AND EndTime <=@EndTime)
OR ( StartTime < @StartTime  AND EndTime <= @EndTime AND EndTime > @StartTime )
OR ( StartTime >= @StartTime   AND StartTime <@EndTime AND EndTime > @EndTime )
OR ( StartTime < @StartTime  AND EndTime > @EndTime))



select @strsql =''
Select @strsql = @strsql + 'Insert into #Downcategory(DownCategory,GroupID)
Select DC.Downcategory,D.Group1 from Downcategoryinformation DC
Inner join (Select distinct Group1,Catagory,SortOrder From downcodeinformation) D on DC.DownCategory = D.Catagory where 1=1'
select @strsql = @strsql + @strDownCategory
select @strsql = @strsql +  ' ORDER BY DC.Downcategory,D.SortOrder'
print @strsql
exec (@strsql)

UPDATE #Downcategory SET DownID = t2.DownID 
from(
SELECT t.DownCategory,t.GroupID ,
	   STUFF(ISNULL((SELECT ', ' + x.Interfaceid
				FROM downcodeinformation x
			   WHERE x.Catagory = t.DownCategory and x.Group1 = t.GroupID
			GROUP BY x.Interfaceid
			 FOR XML PATH (''), TYPE).value('.','VARCHAR(max)'), ''), 1, 2, '') [DownID]      
  FROM #Downcategory t)
as t2 inner join #Downcategory on t2.DownCategory = #Downcategory.DownCategory and t2.GroupID =#Downcategory.GroupID 


--select @strsql =''
--select @strsql = @strsql + ' Insert into #DownTimeData(PlantID,McInterfaceid,Machineid,DownCategory)'
--select @strsql = @strsql + ' Select PlantMachine.Plantid,Machineinformation.interfaceid,Machineinformation.Machineid,Downcategoryinformation.Downcategory
--							FROM Machineinformation CROSS JOIN Downcategoryinformation
--							inner JOIN PlantMachine ON PlantMachine.MachineID=Machineinformation.MachineID where 1=1 '
--select @strsql = @strsql + @StrPlant + @strMachine + @strDownCategory
--select @strsql = @strsql +  ' ORDER BY Machineinformation.MachineID,Downcategoryinformation.Downcategory'
--print @strsql
--exec (@strsql)



select @strsql =''
select @strsql = @strsql + ' Insert into #DownTimeData(PlantID,McInterfaceid,Machineid,DownCategory,GroupID)'
select @strsql = @strsql + ' Select PlantMachine.Plantid,Machineinformation.interfaceid,Machineinformation.Machineid,#Downcategory.Downcategory,#Downcategory.GroupID
							FROM Machineinformation CROSS JOIN #Downcategory
							inner JOIN PlantMachine ON PlantMachine.MachineID=Machineinformation.MachineID where 1=1 '
select @strsql = @strsql + @StrPlant + @strMachine 
select @strsql = @strsql +  ' ORDER BY Machineinformation.MachineID,#Downcategory.Downcategory'
print @strsql
exec (@strsql)


If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y')
BEGIN



			--TYPE 1
			UPDATE #DownTimeData SET downtime = isnull(DownTime,0) + isnull(t2.down,0) , DownFreq = isNull(downfreq,0) + isNull(t2.dwnfrq,0) FROM
			(
			SELECT mc,count(mc)as dwnfrq,sum(loadunload)as down,downcodeinformation.catagory as catagory,downcodeinformation.Group1
			from autodata INNER JOIN machineinformation ON autodata.mc = machineinformation.InterfaceID 
			Left Outer Join PlantMachine ON PlantMachine.MachineID=machineinformation.MachineID
			Inner JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
			inner join Downcategoryinformation on Downcategoryinformation.Downcategory=downcodeinformation.Catagory
			where  (autodata.msttime>=@starttime and autodata.ndtime<=@endtime) and datatype=2 
			group by autodata.mc,downcodeinformation.catagory,downcodeinformation.Group1
			)as t2 inner join #DownTimeData on t2.mc=#DownTimeData.McInterfaceid and t2.catagory=#DownTimeData.DownCategory and t2.Group1=#DownTimeData.GroupID


			--TYPE 2
			UPDATE #DownTimeData SET downtime = isnull(DownTime,0) + isnull(t2.down,0) , DownFreq = isNull(downfreq,0) + isNull(t2.dwnfrq,0) FROM
			(
			SELECT mc,count(mc)as dwnfrq,sum(DateDiff(second, @StartTime, ndtime))as down,downcodeinformation.catagory as catagory,downcodeinformation.Group1
			from autodata INNER JOIN machineinformation ON autodata.mc = machineinformation.InterfaceID 
			Left Outer Join PlantMachine ON PlantMachine.MachineID=machineinformation.MachineID
			Inner JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
			inner join Downcategoryinformation on Downcategoryinformation.Downcategory=downcodeinformation.Catagory
			where ( autodata.msttime<@starttime and autodata.ndtime>@starttime and autodata.ndtime<=@endtime) and datatype=2 
			group by autodata.mc,downcodeinformation.catagory ,downcodeinformation.Group1
			)as t2 inner join #DownTimeData on t2.mc=#DownTimeData.McInterfaceid and t2.catagory=#DownTimeData.DownCategory and t2.Group1=#DownTimeData.GroupID


			--TYPE 3
			UPDATE #DownTimeData SET downtime = isnull(DownTime,0) + isnull(t2.down,0),DownFreq = isNull(downfreq,0) + isNull(t2.dwnfrq,0) FROM
			(
			SELECT mc,count(mc)as dwnfrq,sum(DateDiff(second, mstTime, @Endtime))as down,downcodeinformation.catagory as catagory,downcodeinformation.Group1
			from autodata INNER JOIN machineinformation ON autodata.mc = machineinformation.InterfaceID 
			Left Outer Join PlantMachine ON PlantMachine.MachineID=machineinformation.MachineID
			Inner JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
			inner join Downcategoryinformation on Downcategoryinformation.Downcategory=downcodeinformation.Catagory
			where (autodata.msttime>=@starttime and autodata.msttime<@endtime and autodata.ndtime>@endtime) and datatype=2 
			group by autodata.mc,downcodeinformation.catagory,downcodeinformation.Group1
			)as t2 inner join #DownTimeData on t2.mc=#DownTimeData.McInterfaceid and t2.catagory=#DownTimeData.DownCategory and t2.Group1=#DownTimeData.GroupID


			--TYPE 4
			UPDATE #DownTimeData SET downtime = isnull(DownTime,0) + isnull(t2.down,0),DownFreq = isNull(downfreq,0) + isNull(t2.dwnfrq,0) FROM
			(
			SELECT mc,count(mc)as dwnfrq,sum(DateDiff(second, @StartTime,@EndTime))as down,downcodeinformation.catagory as catagory,downcodeinformation.Group1
			from autodata INNER JOIN machineinformation ON autodata.mc = machineinformation.InterfaceID 
			Left Outer Join PlantMachine ON PlantMachine.MachineID=machineinformation.MachineID 
			Inner JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
			inner join Downcategoryinformation on Downcategoryinformation.Downcategory=downcodeinformation.Catagory
			where (autodata.msttime<@starttime and autodata.ndtime>@endtime) and datatype=2 
			group by autodata.mc,downcodeinformation.catagory,downcodeinformation.Group1
			)as t2 inner join #DownTimeData on t2.mc=#DownTimeData.McInterfaceid and t2.catagory=#DownTimeData.DownCategory and t2.Group1=#DownTimeData.GroupID


			--TYPE 1
			UPDATE #DownTimeData SET ManagementLoss = isnull(ManagementLoss,0) + isnull(t2.LOSS,0) FROM 
			(
			SELECT mc,
			sum(
			CASE WHEN (loadunload) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
			THEN isnull(downcodeinformation.Threshold,0) ELSE loadunload
			END) AS LOSS,downcodeinformation.catagory as catagory,downcodeinformation.Group1 from autodata 
			INNER JOIN machineinformation ON autodata.mc = machineinformation.InterfaceID 
			Left Outer Join PlantMachine ON PlantMachine.MachineID=machineinformation.MachineID
			Inner JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
			inner join Downcategoryinformation on Downcategoryinformation.Downcategory=downcodeinformation.Catagory
			where  (autodata.sttime>=@starttime and autodata.ndtime<=@endtime) and datatype=2 
			and (downcodeinformation.availeffy = 1)
			group by autodata.mc,downcodeinformation.catagory,downcodeinformation.Group1 
			)as t2 inner join #DownTimeData on t2.mc=#DownTimeData.McInterfaceid and t2.catagory=#DownTimeData.DownCategory and t2.Group1=#DownTimeData.GroupID


			--TYPE 2
			UPDATE #DownTimeData SET ManagementLoss = isnull(ManagementLoss,0) + isnull(t2.loss,0) FROM 
			(
			SELECT mc,
			sum(
			CASE WHEN DateDiff(second, @StartTime, ndtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
			then isnull(downcodeinformation.Threshold,0) ELSE DateDiff(second, @StartTime, ndtime)
			END)loss, downcodeinformation.catagory as catagory,downcodeinformation.Group1
			from autodata INNER JOIN machineinformation ON autodata.mc = machineinformation.InterfaceID 
			Left Outer Join PlantMachine ON PlantMachine.MachineID=machineinformation.MachineID 
			Inner JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
			inner join Downcategoryinformation on Downcategoryinformation.Downcategory=downcodeinformation.Catagory
			where ( autodata.sttime<@starttime and autodata.ndtime>@starttime and autodata.ndtime<=@endtime) and datatype=2 
			and (downcodeinformation.availeffy = 1)
			group by autodata.mc,downcodeinformation.catagory,downcodeinformation.Group1 
			)as t2 inner join #DownTimeData on t2.mc=#DownTimeData.McInterfaceid and t2.catagory=#DownTimeData.DownCategory and t2.Group1=#DownTimeData.GroupID


			--TYPE 3
			UPDATE #DownTimeData SET ManagementLoss = isnull(ManagementLoss,0) + isnull(t2.loss,0) FROM 
			(
			SELECT mc,
			SUM(
			CASE WHEN DateDiff(second,stTime, @Endtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0 then isnull(downcodeinformation.Threshold,0)
			ELSE DateDiff(second, stTime, @Endtime)
			END)loss, downcodeinformation.catagory as catagory,downcodeinformation.Group1
			from autodata INNER JOIN machineinformation ON autodata.mc = machineinformation.InterfaceID 
			Left Outer Join PlantMachine ON PlantMachine.MachineID=machineinformation.MachineID 
			Inner JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
			inner join Downcategoryinformation on Downcategoryinformation.Downcategory=downcodeinformation.Catagory
			where (autodata.sttime>=@starttime and autodata.sttime<@endtime and autodata.ndtime>@endtime) and datatype=2 
			and (downcodeinformation.availeffy = 1) 
			group by autodata.mc,downcodeinformation.catagory,downcodeinformation.Group1 
			)as t2 inner join #DownTimeData on t2.mc=#DownTimeData.McInterfaceid and t2.catagory=#DownTimeData.DownCategory and t2.Group1=#DownTimeData.GroupID


			--TYPE 4
			UPDATE #DownTimeData SET ManagementLoss = isnull(ManagementLoss,0) + isnull(t2.loss,0) FROM 
			(
			SELECT mc,
			sum(
			CASE WHEN DateDiff(second, @StartTime, @Endtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
			then isnull(downcodeinformation.Threshold,0) ELSE DateDiff(second, @StartTime, @Endtime)
			END)loss,downcodeinformation.catagory as catagory,downcodeinformation.Group1
			from autodata INNER JOIN machineinformation ON autodata.mc = machineinformation.InterfaceID 
			Left Outer Join PlantMachine ON PlantMachine.MachineID=machineinformation.MachineID 
			Inner JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
			inner join Downcategoryinformation on Downcategoryinformation.Downcategory=downcodeinformation.Catagory
			where (autodata.sttime<@starttime and autodata.ndtime>@endtime) and datatype=2 
			and (downcodeinformation.availeffy = 1)
			group by autodata.mc,downcodeinformation.catagory,downcodeinformation.Group1 
			) as t2 inner join #DownTimeData on t2.mc=#DownTimeData.McInterfaceid and t2.catagory=#DownTimeData.DownCategory and t2.Group1=#DownTimeData.GroupID
END

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN


			UPDATE #DownTimeData SET downtime = isnull(downtime,0) + isNull(t2.down,0),DownFreq = isNull(downfreq,0) + isNull(t2.dwnfrq,0)
			from
			(select mc,downcodeinformation.catagory as catagory,downcodeinformation.Group1,count(mc)as dwnfrq,sum(
					CASE
					WHEN  autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime  THEN  loadunload
					WHEN (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  THEN DateDiff(second, @StartTime, ndtime)
					WHEN (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)  THEN DateDiff(second, stTime, @Endtime)
					WHEN autodata.msttime<@StartTime and autodata.ndtime>@EndTime   THEN DateDiff(second, @StartTime, @EndTime)
					END
				)AS down
			from autodata INNER JOIN machineinformation ON autodata.mc = machineinformation.InterfaceID 
			Left Outer Join PlantMachine ON PlantMachine.MachineID=machineinformation.MachineID 
			Inner JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
			inner join Downcategoryinformation on Downcategoryinformation.Downcategory=downcodeinformation.Catagory
			where autodata.datatype=2 AND
			(
			(autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)
			OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
			OR (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
			OR (autodata.msttime<@StartTime and autodata.ndtime>@EndTime )
			) AND (downcodeinformation.availeffy = 0)
			group by autodata.mc,downcodeinformation.catagory,downcodeinformation.Group1 
			) as t2 inner join #DownTimeData on t2.mc=#DownTimeData.McInterfaceid and t2.catagory=#DownTimeData.DownCategory and t2.Group1=#DownTimeData.GroupID

			UPDATE #DownTimeData set PDT =isnull(PDT,0) + isNull(TT.PPDT ,0),downtime = isnull(downtime,0) - isNull(TT.PPDT ,0) FROM
			(
				SELECT autodata.MC, downcodeinformation.catagory as catagory,downcodeinformation.Group1,SUM
				   (CASE
					WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
					WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
					WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
					WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
					END ) as PPDT
				FROM AutoData CROSS jOIN #PlannedDownTimes T 
				INNER JOIN machineinformation ON autodata.mc = machineinformation.InterfaceID 
				Left Outer Join PlantMachine ON PlantMachine.MachineID=machineinformation.MachineID 
				Inner JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
				inner join Downcategoryinformation on Downcategoryinformation.Downcategory=downcodeinformation.Catagory
				WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
					(
					(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
					OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
					OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
					OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
					) AND (downcodeinformation.availeffy = 0)
				group by autodata.mc,downcodeinformation.catagory,downcodeinformation.Group1
			) as TT inner join #DownTimeData on TT.mc=#DownTimeData.McInterfaceid and TT.catagory=#DownTimeData.DownCategory and TT.Group1=#DownTimeData.GroupID



			UPDATE #DownTimeData SET  ManagementLoss = isnull(ManagementLoss,0) + isNull(t4.Mloss,0),MLDown=isNull(MLDown,0)+isNull(t4.Dloss,0)
					from
					(select T3.mc,T3.Catagory,T3.Group1,sum(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss from (
					select   t1.id,T1.mc,T1.Threshold,T1.Catagory,T1.Group1,
					case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0
					then DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)- isnull(T1.Threshold ,0)
					else 0 End  as Dloss,
					case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0
					then isnull(T1.Threshold,0)
					else (DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)) End  as Mloss
					 from
					
					(   select id,mc,D.threshold,D.catagory,D.Group1,
						case when autodata.sttime<@StartTime then @StartTime else sttime END as sttime,
	       					case when ndtime>@EndTime then @EndTime else ndtime END as ndtime
						from autodata
						inner join downcodeinformation D on autodata.dcode=D.interfaceid 
						inner join Downcategoryinformation on Downcategoryinformation.Downcategory=D.Catagory
						where autodata.datatype=2 AND
						(
						(autodata.sttime>=@StartTime  and  autodata.ndtime<=@EndTime)
						OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
						OR (autodata.sttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
						OR (autodata.sttime<@StartTime and autodata.ndtime>@EndTime )
						) AND (D.availeffy = 1)) as T1 	 --NR0097
					left outer join
					(SELECT autodata.id,downcodeinformation.catagory,downcodeinformation.Group1,
							   sum(CASE
							WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
							WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
							WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
							WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
							END ) as PPDT
						FROM AutoData CROSS jOIN #PlannedDownTimes T 
						inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
						inner join Downcategoryinformation on Downcategoryinformation.Downcategory=downcodeinformation.Catagory
						WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
							(
							(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
							OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
							OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
							OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
							)
							AND (downcodeinformation.availeffy = 1) 
							group  by autodata.id,downcodeinformation.catagory,downcodeinformation.Group1) as T2 on T1.id=T2.id ) as T3  group by T3.mc,T3.Catagory,T3.Group1
					) as t4 inner join #DownTimeData on t4.mc = #DownTimeData.McInterfaceid AND #DownTimeData.DownCategory=T4.catagory AND #DownTimeData.GroupID=T4.Group1


				UPDATE #DownTimeData SET downtime = isnull(downtime,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)

END



Update #DownTimeData set downtime = isnull(downtime,0) - isnull(Managementloss,0)


Update #DownTimeData set TotalDownlossCategorywise = isnull(TotalDownlossCategorywise,0) + isnull(T4.Totaldown,0),
TotalDownFreqCategorywise=isnull(TotalDownFreqCategorywise,0) + isnull(Totalfreq,0) from
(Select Downcategory as catagory,sum(downtime) as Totaldown,SUM(Downfreq) as Totalfreq from #DownTimeData
group by Downcategory)T4 inner join #DownTimeData on  #DownTimeData.DownCategory=T4.catagory




Update #DownTimeData set TotalDownLossMachinewise = isnull(TotalDownLossMachinewise,0) + isnull(T4.Totaldown,0),
TotalDownFreqMachinewise=isnull(TotalDownFreqMachinewise,0) + isnull(Totalfreq,0) from
(Select McInterfaceid as mc,sum(downtime) as Totaldown,SUM(Downfreq) as Totalfreq from #DownTimeData
group by McInterfaceid)T4 inner join #DownTimeData on t4.mc = #DownTimeData.McInterfaceid



--------------------------------- Getting Final Summary --------------------------------------
--select @strsql =''
--select @strsql = @strsql + ' Insert into #FinalDownData(PlantID,McInterfaceid,Machineid,DownCategory,DownID,Downtime,Downfreq,Managementloss,MLDown,TotalDownlossCategorywise,TotalDownFreqCategorywise,TotalDownLossMachinewise,TotalDownFreqMachinewise,Bookingtime,Availabletime)'
--select @strsql = @strsql + ' Select PlantMachine.Plantid,Machineinformation.interfaceid,Machineinformation.Machineid,Downcategoryinformation.Downcategory,downcodeinformation.downid
--							,0,0,0,0,0,0,0,0,0,0 FROM Machineinformation CROSS JOIN downcodeinformation
--							inner join Downcategoryinformation on Downcategoryinformation.Downcategory=downcodeinformation.Catagory
--							inner JOIN PlantMachine ON PlantMachine.MachineID=Machineinformation.MachineID where 1=1 '
--select @strsql = @strsql + @StrPlant + @strMachine + @strDownCategory + @strdownid
--select @strsql = @strsql +  ' ORDER BY Machineinformation.MachineID,Downcategoryinformation.Downcategory'
--print @strsql
--exec (@strsql)

select @strsql =''
select @strsql = @strsql + ' Insert into #FinalDownData(PlantID,McInterfaceid,Machineid,DownCategory,GroupID,DownID,Downtime,Downfreq,Managementloss,MLDown,TotalDownlossCategorywise,TotalDownFreqCategorywise,TotalDownLossMachinewise,TotalDownFreqMachinewise,Bookingtime,Availabletime)'
select @strsql = @strsql + ' Select PlantMachine.Plantid,Machineinformation.interfaceid,Machineinformation.Machineid,#Downcategory.Downcategory,#Downcategory.GroupID,#Downcategory.downid
							,0,0,0,0,0,0,0,0,0,0 FROM Machineinformation CROSS JOIN #Downcategory
							inner JOIN PlantMachine ON PlantMachine.MachineID=Machineinformation.MachineID where 1=1 '
select @strsql = @strsql + @StrPlant + @strMachine 
select @strsql = @strsql +  ' ORDER BY Machineinformation.MachineID,#Downcategory.Downcategory'
print @strsql
exec (@strsql)


Update #FinalDownData set Downtime = isnull(#FinalDownData.Downtime,0) + isnull(T1.Downtime,0),Downfreq = isnull(#FinalDownData.Downfreq,0) + isnull(T1.Downfreq,0),
Managementloss = isnull(#FinalDownData.Managementloss,0) + isnull(T1.Mloss,0), MLDown = isnull(#FinalDownData.MLDown,0) + isnull(T1.MLDown,0) , PDT = isnull(#FinalDownData.PDT,0) + isnull(T1.PDT,0) from 
(Select McInterfaceid as mc,DownCategory as catagory,GroupID,Downtime,Downfreq ,Managementloss as Mloss,MLDown,PDT from #DownTimeData)T1
INNER JOIN #FinalDownData ON T1.mc = #FinalDownData.McInterfaceid AND #FinalDownData.DownCategory=T1.catagory AND #FinalDownData.GroupID=T1.GroupID


Update #FinalDownData set TotalDownlossCategorywise = isnull(TotalDownlossCategorywise,0) + isnull(T4.Totaldown,0),
TotalDownFreqCategorywise=isnull(TotalDownFreqCategorywise,0) + isnull(Totalfreq,0) from
(Select Downcategory as catagory,sum(downtime) as Totaldown,SUM(Downfreq) as Totalfreq from #DownTimeData
group by Downcategory)T4 inner join #FinalDownData on  #FinalDownData.DownCategory=T4.catagory 


Update #FinalDownData set TotalDownLossMachinewise = isnull(TotalDownLossMachinewise,0) + isnull(T4.Totaldown,0),
TotalDownFreqMachinewise=isnull(TotalDownFreqMachinewise,0) + isnull(Totalfreq,0) from
(Select McInterfaceid as mc,sum(downtime) as Totaldown,SUM(Downfreq) as Totalfreq from #DownTimeData
group by McInterfaceid)T4 inner join #FinalDownData on t4.mc = #FinalDownData.McInterfaceid



Update #FinalDownData set Bookingtime = isnull(Bookingtime,0) + isnull(T4.btime,0) from
(Select McInterfaceid as mc,(datediff(s,@starttime,@endtime) - (sum(isnull(PDT ,0)) + sum(isnull(Managementloss,0))))  as btime from #DownTimeData
group by McInterfaceid)T4 inner join #FinalDownData on t4.mc = #FinalDownData.McInterfaceid



Update #FinalDownData set Availabletime = isnull(Availabletime,0) + isnull(T4.btime,0) from
(Select McInterfaceid as mc,isnull(Bookingtime ,0) - isnull(TotalDownLossMachinewise,0) as btime from #FinalDownData
group by McInterfaceid,Bookingtime,TotalDownLossMachinewise)T4 inner join #FinalDownData on t4.mc = #FinalDownData.McInterfaceid

--------------------------------- Getting Final Summary --------------------------------------



select 	PlantID,Machineid,DownCategory,GroupID,DownID,Round(Downtime/60,2) as Downtime,Managementloss,DownFreq,Round(Bookingtime/60,2) as Bookingtime,
Round(Availabletime/60,2) as Availabletime,Round(TotalDownLossCategorywise/60,2) as TotalDownLossCategorywise,TotalDownFreqCategorywise,
round(TotalDownLossMachinewise/60,2) as TotalDownLossMachinewise,TotalDownFreqMachinewise, round(((TotalDownLossMachinewise/60)/(Bookingtime/60))*100,2) as LossPercent,
round(((Availabletime/60)/(Bookingtime/60))*100,2) as AvailabilityPercet from #FinalDownData
order by Machineid,DownCategory

end
