/****** Object:  Procedure [dbo].[s_GetProductionandDowntimeDetails]    Committed by VersionSQL https://www.versionsql.com ******/

/*******************************************************************************************************
--NR0107 :: SwathiKS :: 07/Oct/2014 :: Created new Procedure to show Production and Downtime details for L&T.
--ER0500 : SwathiKS: 05/Mar/2021::Altered Procedure [dbo].[s_GetProductionandDowntimeDetails], For Monthly Report Runtime=UT For Daily Report Runtime=TT-PDT-(DT+ML)

exec s_GetProductionandDowntimeDetails '2021-02-01 06:00:00','2021-02-02 06:00:00','','','Summary','Y'
exec s_GetProductionandDowntimeDetails '2020-02-01 06:00:00','2020-03-01 06:00:00','J-125','','COLevelDetails'
exec s_GetProductionandDowntimeDetails '2020-02-01 06:00:00','2020-03-01 06:00:00','J-125','','Efficiency'
exec s_GetProductionandDowntimeDetails '2020-02-01 06:00:00','2020-03-01 06:00:00','','J-125','Inprocessprodcycle'
exec s_GetProductionandDowntimeDetails '2020-02-01 06:00:00','2020-03-01 06:00:00','J-125','','Inprocessdowncycles'
exec s_GetProductionandDowntimeDetails '2020-02-01 06:00:00','2020-03-01 06:00:00','J-125','','DowntimeSummary'
***********************************************************************************************************/

CREATE        PROCEDURE [dbo].[s_GetProductionandDowntimeDetails]
	@StartTime datetime ,
	@EndTime datetime,
	@Machineid nvarchar(50)='',
	@plantid nvarchar(50)='',
	@param nvarchar(20)='',
	@machinelist nvarchar(20)=''
AS
BEGIN


CREATE TABLE #cockpitdata
(
	MachineID nvarchar(50),
	MachineInterface nvarchar(50),
	Totaltime float,
	UtilisedTime float,
	Downtime Float,
	Managementloss Float,
	MLDown float,
	PDT Float,
	Cyclecount Float,
	CN float,
	ProductionEfficiency float,
	AvailabilityEfficiency float,
	OverallEfficiency float,
	RunningPart nvarchar(50)
)

CREATE TABLE #PLD
(
	MachineID nvarchar(50),
	MachineInterface nvarchar(50),
	pPlannedDT float Default 0,
	dPlannedDT float Default 0,
	MPlannedDT float Default 0,
	IPlannedDT float Default 0,
	DownID nvarchar(50)
)
Create table #PlannedDownTimes
(
	MachineID nvarchar(50) NOT NULL, 
	MachineInterface nvarchar(50) NOT NULL, 
	StartTime DateTime NOT NULL, 
	EndTime DateTime NOT NULL 
)

ALTER TABLE #PlannedDownTimes
ADD PRIMARY KEY CLUSTERED
	(   [MachineInterface],
		[StartTime],
		[EndTime]
					
	) ON [PRIMARY]


declare @strsql as nvarchar(4000)
DECLARE @strmachine nvarchar(2000)
DECLARE @StrPlantID NVARCHAR(200)

SELECT  @strsql=''
SELECT @strmachine=''
SELECT @StrPlantID=''

if isnull(@PlantID,'')<>''
begin
	select @StrPlantID=' AND (plantmachine.PlantID =N'''+@PlantID+''')'
end

print @StrPlantID

If @machineid<>''
begin
	select @strmachine=' AND (MachineInformation.machineid =N'''+@MachineID+''')'
end

declare @TimeFormat as nvarchar(50)
SELECT @TimeFormat ='ss'
SELECT @TimeFormat = isnull((SELECT ValueInText From CockPitDefaults Where Parameter='TimeFormat'),'ss')
if (@TimeFormat <>'hh:mm:ss' and @TimeFormat <>'hh' and @TimeFormat <>'mm'and @TimeFormat <>'ss')
BEGIN
SELECT @TimeFormat = 'ss'
END

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
 mc,sttime,ndtime,msttime ASC  
)ON [PRIMARY]  
  
--create table #DowntimeSummary
--(
--Machineid nvarchar(50),
--DownDescription nvarchar(1000),
--Downtime nvarchar(50),
--NoOfOccurences int,
--MinDowntime nvarchar(50),
--MaxDowntime nvarchar(50),
--DowntimePercent float
--)

  
create table #DowntimeSummary
(
Machineid nvarchar(50),
DownDescription nvarchar(1000),
Downtime float,
NoOfOccurences int,
MinDowntime float,
MaxDowntime float,
DowntimePercent float
)

Declare @T_ST AS Datetime   
Declare @T_ED AS Datetime   

Select @T_ST=dbo.f_GetLogicalDaystart(@StartTime)  
Select @T_ED=dbo.f_GetLogicalDayend(@EndTime)  

Select @strsql=''  
select @strsql ='insert into #T_autodata '  
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'  
 select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'  
select @strsql = @strsql + ' from autodata where (( sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_ED,120)+''' ) OR '  
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' )OR '  
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ST,120)+'''  
     and ndtime<='''+convert(nvarchar(25),@T_ED,120)+''' )'  
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' and sttime<'''+convert(nvarchar(25),@T_ED,120)+''' ) )'  
print @strsql  
exec (@strsql)  

If @param='Summary' or @param='Efficiency' 
Begin

			SET @strSql = ''
			SET @strSql = 'Insert into #cockpitdata
				SELECT MachineInformation.machineid,MachineInformation.interfaceid,0,0,0,0,0,0,0,0,0,0,0,0 FROM MachineInformation  
				inner join plantmachine on MachineInformation.machineid=plantmachine.machineid
				WHERE MachineInformation.tpmtrakenabled=1'
			select @strsql = @strsql + @StrPlantID + @strmachine
			select @strsql = @strsql + ' ORDER BY MachineInformation.Machineid'
			print @strsql 
			EXEC(@strSql)

			SET @strSql = ''
			SET @strSql = 'Insert into #PlannedDownTimes
				SELECT Machine,InterfaceID,
					CASE When StartTime<''' + convert(nvarchar(20),@StartTime,120)+''' Then ''' + convert(nvarchar(20),@StartTime,120)+''' Else StartTime End As StartTime,
					CASE When EndTime>''' + convert(nvarchar(20),@EndTime,120)+''' Then ''' + convert(nvarchar(20),@EndTime,120)+''' Else EndTime End As EndTime
				FROM PlannedDownTimes inner join MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID
				WHERE PDTstatus =1 and MachineInformation.tpmtrakenabled=1 and(
				(StartTime >= ''' + convert(nvarchar(20),@StartTime,120)+''' AND EndTime <=''' + convert(nvarchar(20),@EndTime,120)+''')
				OR ( StartTime < ''' + convert(nvarchar(20),@StartTime,120)+'''  AND EndTime <= ''' + convert(nvarchar(20),@EndTime,120)+''' AND EndTime > ''' + convert(nvarchar(20),@StartTime,120)+''' )
				OR ( StartTime >= ''' + convert(nvarchar(20),@StartTime,120)+'''   AND StartTime <''' + convert(nvarchar(20),@EndTime,120)+''' AND EndTime > ''' + convert(nvarchar(20),@EndTime,120)+''' )
				OR ( StartTime < ''' + convert(nvarchar(20),@StartTime,120)+'''  AND EndTime > ''' + convert(nvarchar(20),@EndTime,120)+''')) '
			SET @strSql =  @strSql + @strMachine +  ' ORDER BY Machine,StartTime'
			EXEC(@strSql)

			-- Type 1
			UPDATE #cockpitdata SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
			from
			(select mc,sum(cycletime+loadunload) as cycle
			from #T_autodata autodata
			where (autodata.msttime>=@StartTime)
			and (autodata.ndtime<=@EndTime)
			and (autodata.datatype=1)
			group by autodata.mc
			) as t2 inner join #cockpitdata on t2.mc = #cockpitdata.machineinterface

			-- Type 2
			UPDATE #cockpitdata SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
			from
			(select  mc,SUM(DateDiff(second, @StartTime, ndtime)) cycle
			from #T_autodata autodata
			where (autodata.msttime<@StartTime)
			and (autodata.ndtime>@StartTime)
			and (autodata.ndtime<=@EndTime)
			and (autodata.datatype=1)
			group by autodata.mc
			) as t2 inner join #cockpitdata on t2.mc = #cockpitdata.machineinterface

			-- Type 3
			UPDATE  #cockpitdata SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
			from
			(select  mc,sum(DateDiff(second, mstTime, @EndTime)) cycle
			from #T_autodata autodata
			where (autodata.msttime>=@StartTime)
			and (autodata.msttime<@EndTime)
			and (autodata.ndtime>@EndTime)
			and (autodata.datatype=1)
			group by autodata.mc
			) as t2 inner join #cockpitdata on t2.mc = #cockpitdata.machineinterface

			-- Type 4
			UPDATE #cockpitdata SET UtilisedTime = isnull(UtilisedTime,0) + isnull(t2.cycle,0)
			from
			(select mc,
			sum(DateDiff(second, @StartTime, @EndTime)) cycle from #T_autodata autodata
			where (autodata.msttime<@StartTime)
			and (autodata.ndtime>@EndTime)
			and (autodata.datatype=1)
			group by autodata.mc
			)as t2 inner join #cockpitdata on t2.mc = #cockpitdata.machineinterface	

			/* Fetching Down Records from Production Cycle  */
			/* If Down Records of TYPE-2*/
			UPDATE  #cockpitdata SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
			FROM
			(Select AutoData.mc ,
			SUM(
			CASE
			When autodata.sttime <= @StartTime Then datediff(s, @StartTime,autodata.ndtime )
			When autodata.sttime > @StartTime Then datediff(s , autodata.sttime,autodata.ndtime)
			END) as Down
			From AutoData INNER Join
			(Select mc,Sttime,NdTime From AutoData
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(msttime < @StartTime)And (ndtime > @StartTime) AND (ndtime <= @EndTime)) as T1
			ON AutoData.mc=T1.mc
			Where AutoData.DataType=2
			And ( autodata.Sttime > T1.Sttime )
			And ( autodata.ndtime <  T1.ndtime )
			AND ( autodata.ndtime >  @StartTime )
			GROUP BY AUTODATA.mc)AS T2 Inner Join #cockpitdata on t2.mc = #cockpitdata.machineinterface

			/* If Down Records of TYPE-3*/
			UPDATE  #cockpitdata SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
			FROM
			(Select AutoData.mc ,
			SUM(CASE
			When autodata.ndtime > @EndTime Then datediff(s,autodata.sttime, @EndTime )
			When autodata.ndtime <=@EndTime Then datediff(s , autodata.sttime,autodata.ndtime)
			END) as Down
			From AutoData INNER Join
			(Select mc,Sttime,NdTime From AutoData
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(sttime >= @StartTime)And (ndtime > @EndTime) and (sttime<@EndTime) ) as T1
			ON AutoData.mc=T1.mc
			Where AutoData.DataType=2
			And (T1.Sttime < autodata.sttime  )
			And ( T1.ndtime >  autodata.ndtime)
			AND (autodata.sttime  <  @EndTime)
			GROUP BY AUTODATA.mc)AS T2 Inner Join #cockpitdata on t2.mc = #cockpitdata.machineinterface

			/* If Down Records of TYPE-4*/
			UPDATE  #cockpitdata SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
			FROM
			(Select AutoData.mc ,
			SUM(CASE
			When autodata.sttime >= @StartTime AND autodata.ndtime <= @EndTime Then datediff(s , autodata.sttime,autodata.ndtime)
			When autodata.sttime < @StartTime AND autodata.ndtime > @StartTime AND autodata.ndtime<=@EndTime Then datediff(s, @StartTime,autodata.ndtime )
			When autodata.sttime>=@StartTime And autodata.sttime < @EndTime AND autodata.ndtime > @EndTime Then datediff(s,autodata.sttime, @EndTime )
			When autodata.sttime<@StartTime AND autodata.ndtime>@EndTime   Then datediff(s , @StartTime,@EndTime)
			END) as Down
			From AutoData INNER Join
			(Select mc,Sttime,NdTime From AutoData
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(msttime < @StartTime)And (ndtime > @EndTime) ) as T1
			ON AutoData.mc=T1.mc
			Where AutoData.DataType=2
			And (T1.Sttime < autodata.sttime  )
			And ( T1.ndtime >  autodata.ndtime)
			AND (autodata.ndtime  >  @StartTime)
			AND (autodata.sttime  <  @EndTime)
			GROUP BY AUTODATA.mc
			)AS T2 Inner Join #cockpitdata on t2.mc = #cockpitdata.machineinterface

			--mod 4:Get utilised time over lapping with PDT.
			If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
			BEGIN
					UPDATE #cockpitdata set UtilisedTime =isnull(UtilisedTime,0) - isNull(TT.PPDT ,0),
					PDT = isnull(PDT,0)+isNull(TT.PPDT ,0) FROM
					(
					 SELECT autodata.MC,SUM
							(CASE
							WHEN autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN DateDiff(second,autodata.msttime,autodata.ndtime) --DR0325 Added
							WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
							WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )
							WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
							END)  as PPDT
							FROM (select M.machineid,mc,msttime,ndtime from  #T_autodata autodata
								inner join machineinformation M on M.interfaceid=Autodata.mc
								 where autodata.DataType=1 And 
								((autodata.msttime >= @starttime  AND autodata.ndtime <=@EndTime)
								OR ( autodata.msttime < @starttime  AND autodata.ndtime <= @EndTime AND autodata.ndtime > @starttime )
								OR ( autodata.msttime >= @starttime   AND autodata.msttime <@EndTime AND autodata.ndtime > @EndTime )
								OR ( autodata.msttime < @starttime  AND autodata.ndtime > @EndTime))
								)
						AutoData inner jOIN #PlannedDownTimes T on T.Machineid=AutoData.machineid
						WHERE 
							(
							(autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
							OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
							OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )
							OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )
						group by autodata.mc
					)as TT INNER JOIN #cockpitdata ON TT.mc = #cockpitdata.MachineInterface

					--mod 4(4):Handle intearction between ICD and PDT for type 1 production record for the selected time period.
					UPDATE  #cockpitdata set UtilisedTime =isnull(UtilisedTime,0) + isNull(T2.IPDT ,0),PDT = isnull(PDT,0) + isNull(T2.IPDT ,0) 	
					FROM	
					(
					Select T1.mc,SUM(
							CASE 	
								When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1
								When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2
								When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3
								when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4
							END) as IPDT from
						(Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype from #T_autodata A
						Where A.DataType=2
						and exists 
							(
							Select B.Sttime,B.NdTime,B.mc From AutoData B
							Where B.mc = A.mc and
							B.DataType=1 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And
							(B.msttime >= @starttime AND B.ndtime <= @EndTime) and
							(B.sttime < A.sttime) AND (B.ndtime > A.ndtime) 
							)
						 )as T1 inner join
						(select  machine,Case when starttime<@starttime then @starttime else starttime end as starttime, 
						case when endtime> @EndTime then @EndTime else endtime end as endtime from dbo.PlannedDownTimes 
						where ((( StartTime >=@starttime) And ( EndTime <=@EndTime))
						or (StartTime < @starttime  and  EndTime <= @EndTime AND EndTime > @starttime)
						or (StartTime >= @starttime  AND StartTime <@EndTime AND EndTime > @EndTime)
						or (( StartTime <@starttime) And ( EndTime >@EndTime )) )
						)T
						on T1.machine=T.machine AND
						((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
						or (T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
						or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
						or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )group by T1.mc
					)AS T2  INNER JOIN #cockpitdata ON T2.mc = #cockpitdata.MachineInterface
					---mod 4(4)

					/* Fetching Down Records from Production Cycle  */
					/* If production  Records of TYPE-2*/
					UPDATE  #cockpitdata set UtilisedTime =isnull(UtilisedTime,0) + isNull(T2.IPDT ,0),PDT =isnull(PDT,0) + isNull(T2.IPDT ,0) 	
					FROM	
					(
					Select T1.mc,SUM(
					CASE 	
						When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1
						When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2
						When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3
						when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4
					END) as IPDT from
					(Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype from #T_autodata A
					Where A.DataType=2
					and exists 
					(
					Select B.Sttime,B.NdTime From AutoData B
					Where B.mc = A.mc and
					B.DataType=1 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And
					(B.msttime < @StartTime And B.ndtime > @StartTime AND B.ndtime <= @EndTime) 
					And ((A.Sttime > B.Sttime) And ( A.ndtime < B.ndtime) AND ( A.ndtime > @StartTime ))
					)
					)as T1 inner join
					(select  machine,Case when starttime<@starttime then @starttime else starttime end as starttime, 
					case when endtime> @EndTime then @EndTime else endtime end as endtime from dbo.PlannedDownTimes 
					where ((( StartTime >=@starttime) And ( EndTime <=@EndTime))
					or (StartTime < @starttime  and  EndTime <= @EndTime AND EndTime > @starttime)
					or (StartTime >= @starttime  AND StartTime <@EndTime AND EndTime > @EndTime)
					or (( StartTime <@starttime) And ( EndTime >@EndTime )) )
					)T
					on T1.machine=T.machine AND
					(( T.StartTime >= @StartTime ) And ( T.StartTime <  T1.ndtime )) group by T1.mc
					)AS T2  INNER JOIN #cockpitdata ON T2.mc = #cockpitdata.MachineInterface

					/* If production Records of TYPE-3*/
					UPDATE  #cockpitdata set UtilisedTime =isnull(UtilisedTime,0) + isNull(T2.IPDT ,0),PDT =isnull(PDT,0) + isNull(T2.IPDT ,0) 	
					FROM
					(
					Select T1.mc,SUM(
						CASE 	
							When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1
							When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2
							When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3
							when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4
						END) as IPDT from
						(Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype from #T_autodata A
						Where A.DataType=2
						and exists 
						(
						Select B.Sttime,B.NdTime From AutoData B
						Where B.mc = A.mc and
						B.DataType=1 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And
						(B.sttime >= @StartTime And B.ndtime > @EndTime and B.sttime <@EndTime) and
						((B.Sttime < A.sttime  )And ( B.ndtime > A.ndtime) AND (A.msttime < @EndTime))
						)
						)as T1 inner join
						(select  machine,Case when starttime<@starttime then @starttime else starttime end as starttime, 
						case when endtime> @EndTime then @EndTime else endtime end as endtime from dbo.PlannedDownTimes 
						where ((( StartTime >=@starttime) And ( EndTime <=@EndTime))
						or (StartTime < @starttime  and  EndTime <= @EndTime AND EndTime > @starttime)
						or (StartTime >= @starttime  AND StartTime <@EndTime AND EndTime > @EndTime)
						or (( StartTime <@starttime) And ( EndTime >@EndTime )) )
						)T
						on T1.machine=T.machine
						AND (( T.EndTime > T1.Sttime )And ( T.EndTime <=@EndTime )) group by T1.mc
					)AS T2  INNER JOIN #cockpitdata ON T2.mc = #cockpitdata.MachineInterface


					/* If production Records of TYPE-4*/
					UPDATE  #cockpitdata set UtilisedTime =isnull(UtilisedTime,0) + isNull(T2.IPDT ,0),PDT =isnull(PDT,0) + isNull(T2.IPDT ,0) 	
					FROM
					(
						Select T1.mc,SUM(
						CASE 	
							When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1
							When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2
							When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3
							when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4
						END) as IPDT from
						(Select A.mc,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime, ndtime, A.datatype from #T_autodata A
						Where A.DataType=2
						and exists 
						(
						Select B.Sttime,B.NdTime From AutoData B
						Where B.mc = A.mc and
						B.DataType=1 And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And
						(B.msttime < @StartTime And B.ndtime > @EndTime)
						And ((B.Sttime < A.sttime)And ( B.ndtime >  A.ndtime)AND (A.ndtime  >  @StartTime) AND (A.sttime  <  @EndTime))
						)
						)as T1 inner join
							(select  machine,Case when starttime<@starttime then @starttime else starttime end as starttime, 
							case when endtime> @EndTime then @EndTime else endtime end as endtime from dbo.PlannedDownTimes 
							where ((( StartTime >=@starttime) And ( EndTime <=@EndTime))
							or (StartTime < @starttime  and  EndTime <= @EndTime AND EndTime > @starttime)
							or (StartTime >= @starttime  AND StartTime <@EndTime AND EndTime > @EndTime)
							or (( StartTime <@starttime) And ( EndTime >@EndTime )) )
							)T
							on T1.machine=T.machine AND
						(( T.StartTime >=@StartTime) And ( T.EndTime <=@EndTime )) group by T1.mc
					)AS T2  INNER JOIN #cockpitdata ON T2.mc = #cockpitdata.MachineInterface

			END
			
			If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y')
			BEGIN
					-- Type 1
					UPDATE #cockpitdata SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
					from
					(select mc,sum(
					CASE
					WHEN (loadunload) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
					THEN isnull(downcodeinformation.Threshold,0)
					ELSE loadunload
					END) AS LOSS
					from #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
					where (autodata.msttime>=@StartTime)
					and (autodata.ndtime<=@EndTime)
					and (autodata.datatype=2)
					and (downcodeinformation.availeffy = 1)
					group by autodata.mc) as t2 inner join #cockpitdata on t2.mc = #cockpitdata.machineinterface

					-- Type 2
					UPDATE #cockpitdata SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
					from
					(select      mc,sum(
					CASE WHEN DateDiff(second, @StartTime, ndtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
					then isnull(downcodeinformation.Threshold,0)
					ELSE DateDiff(second, @StartTime, ndtime)
					END)loss
					from #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
					where (autodata.sttime<@StartTime)
					and (autodata.ndtime>@StartTime)
					and (autodata.ndtime<=@EndTime)
					and (autodata.datatype=2)
					and (downcodeinformation.availeffy = 1)
					group by autodata.mc
					) as t2 inner join #cockpitdata on t2.mc = #cockpitdata.machineinterface

					-- Type 3
					UPDATE #cockpitdata SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
					from
					(select      mc,SUM(
					CASE WHEN DateDiff(second,stTime, @EndTime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
					then isnull(downcodeinformation.Threshold,0)
					ELSE DateDiff(second, stTime, @EndTime)
					END)loss
					from #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
					where (autodata.msttime>=@StartTime)
					and (autodata.sttime<@EndTime)
					and (autodata.ndtime>@EndTime)
					and (autodata.datatype=2)
					and (downcodeinformation.availeffy = 1)
					group by autodata.mc
					) as t2 inner join #cockpitdata on t2.mc = #cockpitdata.machineinterface

					-- Type 4
					UPDATE #cockpitdata SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
					from
					(select mc,sum(
					CASE WHEN DateDiff(second, @StartTime, @EndTime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
					then isnull(downcodeinformation.Threshold,0)
					ELSE DateDiff(second, @StartTime, @EndTime)
					END)loss
					from #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
					where autodata.msttime<@StartTime
					and autodata.ndtime>@EndTime
					and (autodata.datatype=2)
					and (downcodeinformation.availeffy = 1)
					group by autodata.mc
					) as t2 inner join #cockpitdata on t2.mc = #cockpitdata.machineinterface

					---get the downtime for the time period
					UPDATE #cockpitdata SET downtime = isnull(downtime,0) + isNull(t2.down,0)
					from
					(select mc,sum(
							CASE
							WHEN  autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime  THEN  loadunload
							WHEN (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  THEN DateDiff(second, @StartTime, ndtime)
							WHEN (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)  THEN DateDiff(second, stTime, @EndTime)
							WHEN autodata.msttime<@StartTime and autodata.ndtime>@EndTime   THEN DateDiff(second, @StartTime, @EndTime)
							END
						)AS down
					from #T_autodata autodata inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
					where autodata.datatype=2 AND
					(
					(autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)
					OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
					OR (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
					OR (autodata.msttime<@StartTime and autodata.ndtime>@EndTime )
					)
					group by autodata.mc
					) as t2 inner join #cockpitdata on t2.mc = #cockpitdata.machineinterface
			End


			---mod 4: Handling interaction between PDT and downtime . Also interaction between PDT and Management Loss
			If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
			BEGIN

				---step 1
				UPDATE #cockpitdata SET downtime = isnull(downtime,0) + isNull(t2.down,0)
				from
				(select mc,sum(
				CASE
				WHEN  autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime  THEN  loadunload
				WHEN (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  THEN DateDiff(second, @StartTime, ndtime)
				WHEN (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)  THEN DateDiff(second, stTime, @EndTime)
				WHEN autodata.msttime<@StartTime and autodata.ndtime>@EndTime   THEN DateDiff(second, @StartTime, @EndTime)
				END
				)AS down
				from #T_autodata autodata inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
				where autodata.datatype=2 AND
				(
				(autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)
				OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
				OR (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
				OR (autodata.msttime<@StartTime and autodata.ndtime>@EndTime )
				) AND (downcodeinformation.availeffy = 0)
				group by autodata.mc
				) as t2 inner join #cockpitdata on t2.mc = #cockpitdata.machineinterface
			
				---mod 4 checking for (downcodeinformation.availeffy = 0) to get the overlapping PDT and Downs which is not ML
				UPDATE #cockpitdata set downtime=isnull(downtime,0)- isNull(TT.PPDT ,0), PDT =isnull(PDT,0) + isNull(TT.PPDT ,0)
				FROM(
				SELECT autodata.MC, SUM
				(CASE
				WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
				WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
				WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
				WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
				END ) as PPDT
				FROM AutoData CROSS jOIN #PlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
				WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
				(
				(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
				OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
				OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
				OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
				) AND (downcodeinformation.availeffy = 0)
				group by autodata.mc
				) as TT INNER JOIN #cockpitdata ON TT.mc = #cockpitdata.MachineInterface


				UPDATE #cockpitdata SET  ManagementLoss = isnull(ManagementLoss,0) + isNull(t4.Mloss,0),MLDown=isNull(MLDown,0)+isNull(t4.Dloss,0)
				from
				(select T3.mc,sum(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss from (
				select   t1.id,T1.mc,T1.Threshold,
				case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0
				then DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)- isnull(T1.Threshold ,0)
				else 0 End  as Dloss,
				case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0
				then isnull(T1.Threshold,0)
				else (DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)) End  as Mloss
				from

				(   select id,mc,comp,opn,opr,D.threshold,
				case when autodata.sttime<@StartTime then @StartTime else sttime END as sttime,
				case when ndtime>@EndTime then @EndTime else ndtime END as ndtime
				from #T_autodata autodata
				inner join downcodeinformation D
				on autodata.dcode=D.interfaceid where autodata.datatype=2 AND
				(
				(autodata.sttime>=@StartTime  and  autodata.ndtime<=@EndTime)
				OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
				OR (autodata.sttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
				OR (autodata.sttime<@StartTime and autodata.ndtime>@EndTime )
				) AND (D.availeffy = 1)) as T1 	
				left outer join
				(SELECT autodata.id,
				sum(CASE
				WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
				WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
				WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
				WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
				END ) as PPDT
				FROM AutoData CROSS jOIN #PlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
				WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
				(
				(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
				OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
				OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
				OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
				)
				AND (downcodeinformation.availeffy = 1) group  by autodata.id ) as T2 on T1.id=T2.id ) as T3  group by T3.mc
				) as t4 inner join #cockpitdata on t4.mc = #cockpitdata.machineinterface

				UPDATE #cockpitdata SET downtime = isnull(downtime,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)
			END

			--Calculation of PartsCount Begins..
			UPDATE #cockpitdata SET cyclecount = ISNULL(cyclecount,0) + ISNULL(t2.comp,0)
			From
			(
			  Select mc,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp 
				   From (select mc,SUM(autodata.partscount)AS OrginalCount,comp,opn from #T_autodata autodata
				   where (autodata.ndtime>@StartTime) and (autodata.ndtime<=@EndTime) and (autodata.datatype=1)
				   Group By mc,comp,opn) as T1
			Inner join componentinformation C on T1.Comp = C.interfaceid
			Inner join ComponentOperationPricing O ON  T1.Opn = O.interfaceid and C.Componentid=O.componentid
			inner join machineinformation on machineinformation.machineid =O.machineid
			and T1.mc=machineinformation.interfaceid
			GROUP BY mc
			) As T2 Inner join #cockpitdata on T2.mc = #cockpitdata.machineinterface


			--Mod 4 Apply PDT for calculation of Count
			If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
			BEGIN
					UPDATE #cockpitdata SET cyclecount = ISNULL(cyclecount,0) - ISNULL(T2.comp,0) 
					from
					(
					 select mc,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp From 
						( 
							select mc,Sum(ISNULL(PartsCount,1))AS OrginalCount,comp,opn from #T_autodata autodata
							CROSS JOIN #PlannedDownTimes T
							WHERE autodata.DataType=1 And T.MachineInterface = autodata.mc
							AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)
							AND (autodata.ndtime > @StartTime  AND autodata.ndtime <=@EndTime)
							Group by mc,comp,opn
						) as T1
					Inner join Machineinformation M on M.interfaceID = T1.mc
					Inner join componentinformation C on T1.Comp=C.interfaceid
					Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineID = M.MachineID
					GROUP BY MC
					) as T2 inner join #cockpitdata on T2.mc = #cockpitdata.machineinterface
			END

			UPDATE #CockpitData SET CN = isnull(CN,0) + isNull(t2.C1N1,0)
			from
			(
			select mc,
			SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))* autodata.partscount) C1N1
			FROM autodata INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID 
			INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID AND
			componentoperationpricing.componentid = componentinformation.componentid
			inner join machineinformation on machineinformation.interfaceid=autodata.mc
			and componentoperationpricing.machineid=machineinformation.machineid
			where (((autodata.sttime>=@StartTime)and (autodata.ndtime<=@EndTime)) or
			((autodata.sttime<@StartTime)and (autodata.ndtime>@StartTime)and (autodata.ndtime<=@EndTime)) )
			and (autodata.datatype=1) group by autodata.mc
			) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface

			-- mod 4 Ignore count from CN calculation which is over lapping with PDT
			If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
			BEGIN
				UPDATE #CockpitData SET CN = isnull(CN,0) - isNull(t2.C1N1,0)
				From
				(
					select mc,SUM((O.cycletime * ISNULL(A.PartsCount,1))/ISNULL(O.SubOperations,1))  C1N1
					From autodata A
					Inner join machineinformation M on M.interfaceid=A.mc
					Inner join componentinformation C ON A.Comp=C.interfaceid
					Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID
					Cross jOIN #PlannedDownTimes T
					WHERE A.DataType=1 AND T.MachineInterface=A.mc
					AND(A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)
					AND(A.ndtime > @StartTime  AND A.ndtime <=@EndTime)
					Group by mc
				) as T2
				inner join #CockpitData  on t2.mc = #CockpitData.machineinterface
			END


			-- Calculate efficiencies

	UPDATE #CockpitData
			SET TotalTime = DateDiff(second, @StartTime, @EndTime) 

			UPDATE #CockpitData
			SET
				ProductionEfficiency = (CN/UtilisedTime) ,
				AvailabilityEfficiency = (UtilisedTime)/(UtilisedTime + DownTime - ManagementLoss)
				--,TotalTime = DateDiff(second, @StartTime, @EndTime) 
				WHERE UtilisedTime <> 0


			UPDATE #CockpitData
			SET
				OverAllEfficiency = (ProductionEfficiency * AvailabilityEfficiency)*100,
				ProductionEfficiency = ProductionEfficiency * 100 ,
				AvailabilityEfficiency = AvailabilityEfficiency * 100

			--Update #Cockpitdata Set RunningPart = isnull(T.Comp,0) from  
			--(select Machineinformation.machineid,C.Componentid as comp from 
			--	(Select mc,max(sttime) as sttime From Autodata where sttime>=@starttime and ndtime<=@endtime
			--	 group by mc)T inner join Autodata A on T.mc=A.mc and T.sttime=A.sttime
			--inner join Machineinformation on A.mc=Machineinformation.interfaceid    
			--inner join Componentinformation C on A.comp=C.interfaceid    
			--inner join Componentoperationpricing CO on A.opn=CO.interfaceid    
			--and Machineinformation.Machineid=CO.Machineid and C.Componentid=CO.Componentid    
			--where A.sttime>=@starttime and A.ndtime<=@endtime
			--)T inner join #Cockpitdata on #Cockpitdata.machineid=T.machineid   

			If @param='Efficiency'
			Begin
					SELECT Machineid, Round(Cyclecount,2) as Cyclecount,ProductionEfficiency,AvailabilityEfficiency,OverAllEfficiency from #cockpitdata
					return
			End

			If @param='Summary'
			Begin
				update #cockpitdata set downtime= isnull(downtime,0)-isnull(ManagementLoss,0)
			end
End
 
If @param = 'InProcessProdCycle' or @param='Summary'
Begin

	create table #TempCockpitProductionData
	(
		machineid nvarchar(50),
		ComponentID nvarchar(50),
		description nvarchar(100),
		OperationNo int,
		OperatorID nvarchar(50) ,
		OperatorName nvarchar(150) ,
		StartTime datetime,
		EndTime datetime,
		CycleTime int,
		MachineInterface nvarchar(50),
		CompInterface nvarchar(50),
		OpnInterface nvarchar(50),
		PDT int,
		LoadUnloadTime int,
		Remarks nvarchar(255),
		StdCycleTime int,
		StdMachiningTime int,
		id bigint,
		In_Cycle_DownTime int
	)

	--insert into #TempCockpitProductionData exec [dbo].[s_GetInProcessCycles] @starttime,@Endtime,@Machineid

		create table #Inprocesscycles
		(
		sttime datetime,
		ndtime datetime,
		msttime datetime,
		mc nvarchar(50),
		comp nvarchar(50),
		opn nvarchar(50),
		opr nvarchar(50),
		[id] bigint,
		datatype int
		)

		Declare @mc as nvarchar(50)
		Declare @curtime as datetime
		Select @mc=interfaceid from machineinformation where machineid=@machineid
		Select @curtime=getdate()
		Select @curtime = case when @curtime>@EndTime then @EndTime else @curtime end

		Insert into #Inprocesscycles(sttime,ndtime,mc,comp,opn,opr,[id],datatype,msttime)
		select case when RawData.sttime<@StartTime then @StartTime else RawData.Sttime end,@EndTime,RawData.mc,RawData.comp,RawData.opn,RawData.opr,RawData.slno,'11',
		case when A.Endtime<@starttime then @starttime else A.Endtime end from 
		(select mc,max(slno) as slno from rawdata 
		inner join Autodata_Maxtime A on A.Machineid=RawData.Mc
		where sttime>=A.Endtime and sttime<=@Curtime and datatype=11 group by mc)R
		inner join rawdata on R.slno=RawData.SlNo
		inner join Autodata_Maxtime A on A.Machineid=RawData.Mc
		INNER JOIN machineinformation ON A.Machineid = machineinformation.InterfaceID 
		INNER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID
		where RawData.sttime>=A.Endtime and RawData.sttime<=@Curtime and RawData.datatype=11 
		and (machineinformation.machineid=@MachineID or ISNULL(@machineid,'')='') 
		and (PlantMachine.PlantID = @plantid OR ISNULL(@plantid,'')='') 
		order by RawData.sttime 

		Insert into #Inprocesscycles(sttime,ndtime,mc,comp,opn,opr,[id],datatype)
		select A.sttime,A.ndtime,A.mc,A.comp,A.opn,A.opr,A.id,'42' from autodata_ICD A
		inner join #Inprocesscycles I on I.mc=A.mc
		where A.sttime>=I.sttime and A.ndtime<=I.ndtime
		and I.datatype=11


		SELECT machineinformation.machineid,
		componentinformation.componentid AS ComponentID,
		componentinformation.description AS description, 
		componentoperationpricing.operationno AS OperationNo,
		employeeinformation.Employeeid AS OperatorID,
		employeeinformation.[name] AS OperatorName,
		A.sttime AS sttime,
		A.ndtime AS ndtime,
		A.msttime as msttime,
		Isnull(datediff(s,A.sttime,A.ndtime),0) AS CycleTime,
		A.mc as mc,
		A.comp as comp,
		A.opn as opn,
		0 As PDT,
		ISNULL(datediff(s,A.msttime,A.sttime),0) AS LoadUnloadTime,
		'In Progress Cycle' as Remarks,
		ISNULL(componentoperationpricing.cycletime,0)StdCycleTime,
		ISNULL(componentoperationpricing.machiningtime,0)StdMachiningTime,
		A.id,
		0 as  In_Cycle_DownTime,
		A.datatype as datatype
		INTO #Temp FROM  #Inprocesscycles A 
		INNER JOIN machineinformation ON A.mc = machineinformation.InterfaceID 
		left outer JOIN componentinformation ON A.comp = componentinformation.InterfaceID 
		left outer JOIN componentoperationpricing ON A.opn = componentoperationpricing.InterfaceID
		AND componentinformation.componentid =  componentoperationpricing.componentid
		and componentoperationpricing.machineid=machineinformation.machineid
		INNER JOIN employeeinformation ON A.opr = employeeinformation.interfaceid
		WHERE --(A.sttime >= @StartTime ) AND (A.sttime < @EndTime )  and
		 (machineinformation.machineid=@MachineID or ISNULL(@machineid,'')='') 
	

		update #Temp set In_Cycle_DownTime = Isnull(T1.ICD,0),Cycletime = Isnull(Cycletime,0)-Isnull(T1.ICD,0) from
		(Select machineid,Sum(Datediff(s,sttime,ndtime)) as ICD from #Temp where datatype=42 group by machineid)T1
		where #temp.datatype=11 and T1.machineid=#Temp.machineid	


		If ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y' and (SELECT ValueInInt From CockpitDefaults Where Parameter ='VDG-CycleDefinition')=2)
		BEGIN

		UPDATE #Temp set  CycleTime=isnull(CycleTime,0) - isNull(TT.PPDT ,0),LoadUnloadTime = isnull(LoadUnloadTime,0) - isnull(LD,0),PDT=isnull(PDT,0) + isNull(TT.PPDT ,0) + isnull(LD,0)
		FROM(
				Select A.mc,A.comp,A.Opn,A.sttime,A.ndtime,A.msttime,Sum
				(CASE
				WHEN A.sttime >= T.StartTime  AND A.ndtime <=T.EndTime  THEN (A.cycletime)
				WHEN ( A.sttime < T.StartTime  AND A.ndtime <= T.EndTime  AND A.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,A.ndtime)
				WHEN ( A.sttime >= T.StartTime   AND A.sttime <T.EndTime  AND A.ndtime > T.EndTime  ) THEN DateDiff(second,A.sttime,T.EndTime )
				WHEN ( A.sttime < T.StartTime  AND A.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
				END)  as PPDT,
				sum(case
				WHEN A.msttime >= T.StartTime  AND A.sttime <=T.EndTime  THEN DateDiff(second,A.msttime,A.sttime)
				WHEN ( A.msttime < T.StartTime  AND A.sttime <= T.EndTime  AND A.sttime > T.StartTime ) THEN DateDiff(second,T.StartTime,A.sttime)
				WHEN ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime  AND A.sttime > T.EndTime  ) THEN DateDiff(second,A.msttime,T.EndTime )
				WHEN ( A.msttime < T.StartTime  AND A.sttime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
				END)  as LD
				From #Temp A INNER JOIN machineinformation ON A.mc = machineinformation.InterfaceID  CROSS jOIN PlannedDownTimes T
				WHERE A.datatype=11 and T.Machine=machineinformation.Machineid AND
				((A.msttime >= T.StartTime  AND A.ndtime <=T.EndTime)
				OR ( A.msttime < T.StartTime  AND A.ndtime <= T.EndTime AND A.ndtime > T.StartTime )
				OR ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime AND A.ndtime > T.EndTime )
				OR ( A.msttime < T.StartTime  AND A.ndtime > T.EndTime) )
				and T.PDTStatus = 1   
			group by A.mc,A.comp,A.Opn,A.sttime,A.ndtime,A.msttime
		)
		as TT INNER JOIN #Temp ON TT.mc = #Temp.mc and TT.comp = #Temp.comp and TT.opn = #Temp.opn 
		and TT.sttime=#Temp.sttime and #Temp.ndtime=TT.ndtime where #temp.datatype=11


		------------------------------------ DR0365 Altered From Here -----------------------------------------
			--Handle intearction between ICD and PDT for type 1 production record for the selected time period.  
			UPDATE  #Temp set CycleTime =isnull(CycleTime,0) + isNull(TT.IPDT ,0)  FROM   
			(  
			Select T1.mc,T1.comp,T1.opn,T1.sttime,T1.ndtime,T1.cyclestart,T1.Cycleend,SUM(  
			CASE    
			When T1.sttime >= T.StartTime  AND T1.ndtime <=T.EndTime  Then datediff(s , T1.sttime,T1.ndtime) ---type 1  
			When T1.sttime < T.StartTime  and  T1.ndtime <= T.EndTime AND T1.ndtime > T.StartTime Then datediff(s, T.StartTime,T1.ndtime ) ---type 2  
			When T1.sttime >= T.StartTime   AND T1.sttime <T.EndTime AND T1.ndtime > T.EndTime Then datediff(s, T1.sttime,T.EndTime ) ---type 3  
			when T1.sttime < T.StartTime  AND T1.ndtime > T.EndTime Then datediff(s, T.StartTime,T.EndTime ) ---type 4  
			END) as IPDT from  
			(Select A.mc,A.comp,A.opn,(select machineid from machineinformation where interfaceid = A.mc)as machine, A.sttime,A.ndtime, A.datatype,  
			B.Sttime as CycleStart,B.ndtime as CycleEnd from #Temp A inner join #Temp B on B.mc = A.mc  
			Where A.DataType=42 and B.DataType=11 
			And DateDiff(Second,B.sttime,B.ndtime)> B.CycleTime And  
			--(B.msttime >= @starttime AND B.ndtime <= @Endtime) and  
			(B.sttime < A.sttime) AND (B.ndtime > A.ndtime)     
			)as T1 inner join  
			(select  machine,Case when starttime<@starttime then @starttime else starttime end as starttime,   
			case when endtime> @Endtime then @Endtime else endtime end as endtime from dbo.PlannedDownTimes   
			where PDTStatus = 1 and ((( StartTime >=@starttime) And ( EndTime <=@Endtime))  
			or (StartTime < @starttime  and  EndTime <= @Endtime AND EndTime > @starttime)  
			or (StartTime >= @starttime  AND StartTime <@Endtime AND EndTime > @Endtime)  
			or (( StartTime <@starttime) And ( EndTime >@Endtime )) )  
			)T  
			on T1.machine=T.machine AND  
			((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))  
			or (T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)  
			or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )  
			or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )group by T1.mc,T1.comp,T1.opn,T1.sttime,T1.ndtime,T1.cyclestart,T1.Cycleend 
			)as TT INNER JOIN #Temp ON TT.mc = #Temp.mc and TT.comp = #Temp.comp and TT.opn = #Temp.opn   
			and TT.cyclestart=#Temp.sttime and #Temp.ndtime=TT.Cycleend where #temp.datatype=11  
			------------------------------------- DR0365 Altered Till Here ----------------------------------------------

		END


		insert into #TempCockpitProductionData
		select machineid,ComponentID,description,OperationNo,OperatorID,OperatorName,sttime,ndtime,CycleTime,mc,comp,opn,PDT,LoadUnloadTime,Remarks,StdCycleTime,StdMachiningTime,id,In_Cycle_DownTime from #Temp
		where datatype=11


	--If @param='Summary'
	--Begin
	--	--update #cockpitdata set UtilisedTime=isnull(#cockpitdata.UtilisedTime,0) + isnull(T.CycleTime,0),PDT= isnull(#cockpitdata.PDT,0) + isnull(T.PDT,0) from
	--	--(Select machineid,SUM(LoadUnloadTime+CycleTime) as Cycletime,SUM(PDT) as pdt from #TempCockpitProductionData group by machineid)T	
	--	--inner join #cockpitdata on #cockpitdata.MachineID=T.machineid
	--End

	If @param = 'InProcessProdCycle'
	Begin
		--Select machineid,ComponentID+' ('+description+')' AS ComponentID,dbo.f_formattime(StdCycleTime,'hh:mm:ss') as StdCycleTime,
		--dbo.f_formattime(LoadUnloadTime,'hh:mm:ss') as LoadUnloadTime,dbo.f_formattime(CycleTime,'hh:mm:ss') as CycleTime,dbo.f_formattime(In_Cycle_DownTime,'hh:mm:ss')as In_Cycle_DownTime,dbo.f_formattime(PDT,'hh:mm:ss') as PDT from #TempCockpitProductionData
		--Order by machineid
		Select machineid,ComponentID+' ('+description+')' AS ComponentID,OperationNo
		from #TempCockpitProductionData
		Order by machineid
		return
	end

End


If @param='InProcessDownCycles' or @param='Summary' or @param='DowntimeSummary'
Begin


	create table #TempCockpitDownData
	(
		SerialNO bigint IDENTITY (1, 1) NOT NULL,
		Machineid nvarchar(50),
		StartTime datetime,
		EndTime datetime,
		OperatorID nvarchar(50),
		OperatorName nvarchar(150),
		DownID nvarchar(50),
		DownDescription nvarchar(100),
		DownThreshold numeric(18) ,
		--DownTime nvarchar(50) ,
		Downtime float,
		Remarks nvarchar(255),
		[id] bigint,
		PDT int, --ER0295
		DownStatus nvarchar(50)
	)

		If @param='InProcessDownCycles' or @param='DowntimeSummary'
		Begin

			SELECT
			machineinformation.machineid,
			case when autodata.sttime<@starttime then @starttime else autodata.sttime end AS StartTime,
			case when autodata.ndtime>@endtime then @endtime else autodata.ndtime end AS EndTime,
			Isnull(employeeinformation.Employeeid,autodata.opr) AS OperatorID,
			Isnull(employeeinformation.[Name],'---')  AS OperatorName,
			downcodeinformation.downid AS DownID,
			downcodeinformation.downdescription as [DownDescription],
			CASE
			WHEN downcodeinformation.AvailEffy=1 AND downcodeinformation.ThresholdfromCO <>1 AND downcodeinformation.Threshold>0 THEN downcodeinformation.Threshold --NR0097
			ELSE 0 END AS [DownThreshold],
			case
			When (autodata.sttime >= @StartTime AND autodata.ndtime <= @EndTime ) THEN loadunload
			WHEN ( autodata.sttime < @StartTime AND autodata.ndtime <= @EndTime AND autodata.ndtime > @StartTime ) THEN DateDiff(second, @StartTime, ndtime)
			WHEN ( autodata.sttime >= @StartTime AND autodata.sttime < @EndTime AND autodata.ndtime > @EndTime ) THEN  DateDiff(second, stTime, @EndTime)
			ELSE
			DateDiff(second, @StartTime, @EndTime)END AS DownTime,
			autodata.Remarks,
			autodata.id,
			0 as PDT,'' as DownStatus
			INTO #Temp1
			FROM         autodata INNER JOIN
			machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN
			downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
			LEFT OUTER JOIN employeeinformation ON autodata.opr = employeeinformation.interfaceid 
			WHERE (machineinformation.machineid = @MachineID or isnull(@machineid,'')='') AND autodata.datatype = 2 AND
			(
			(autodata.sttime >= @StartTime  AND autodata.ndtime <=@EndTime)
			OR ( autodata.sttime < @StartTime  AND autodata.ndtime <= @EndTime AND autodata.ndtime > @StartTime )
			OR ( autodata.sttime >= @StartTime   AND autodata.sttime <@EndTime AND autodata.ndtime > @EndTime )
			OR ( autodata.sttime < @StartTime  AND autodata.ndtime > @EndTime)
			)
			ORDER BY autodata.ndtime

			update #Temp1 set [DownThreshold] = isnull([DownThreshold],0) + isnull(T1.DThreshold,0)  from
			(Select autodata.id,isnull(CO.Stdsetuptime,0)AS DThreshold from autodata
			inner join machineinformation M on autodata.mc = M.interfaceid
			inner join downcodeinformation D on autodata.dcode=D.interfaceid
			left outer join  employeeinformation ON autodata.opr = employeeinformation.interfaceid --ER0402
			left outer join componentinformation CI on autodata.comp = CI.interfaceid
			left outer join componentoperationpricing CO on autodata.opn =  CO.interfaceid and CI.componentid = CO.componentid and CO.machineid = M.machineid
			where (M.machineid = @MachineID or isnull(@machineid,'')='') and autodata.datatype=2 and D.ThresholdfromCO = 1
			And
			((autodata.sttime>=@starttime and autodata.ndtime<=@endtime) or
			 (autodata.sttime<@starttime and autodata.ndtime>@starttime and autodata.ndtime<=@endtime)or
			 (autodata.sttime>=@starttime and autodata.sttime<@endtime and autodata.ndtime>@endtime)or
			 (autodata.sttime<@starttime and autodata.ndtime>@endtime))
			)T1 inner join #Temp1 on T1.id=#Temp1.id

			If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
			BEGIN
			update #Temp1 set DownTime = isnull(Downtime,0)-isnull(TT.plannedDT,0), PDT=isnull(TT.plannedDT,0)
				from
			(
				Select A.StartTime,A.EndTime,A.machineid,		
						sum(case
						WHEN A.StartTime >= T.StartTime  AND A.EndTime <=T.EndTime  THEN A.DownTime
						WHEN ( A.StartTime < T.StartTime  AND A.EndTime <= T.EndTime  AND A.EndTime > T.StartTime ) THEN DateDiff(second,T.StartTime,A.EndTime)
						WHEN ( A.StartTime >= T.StartTime   AND A.StartTime <T.EndTime  AND A.EndTime > T.EndTime  ) THEN DateDiff(second,A.StartTime,T.EndTime )
						WHEN ( A.StartTime < T.StartTime  AND A.EndTime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
						END) as plannedDT
				From #Temp1 A CROSS jOIN PlannedDownTimes T
						WHERE  T.machine=A.machineid  and pdtstatus=1 and --datatype=2 and
						((A.StartTime >= T.StartTime  AND A.EndTime <=T.EndTime)
						OR ( A.StartTime < T.StartTime  AND A.EndTime <= T.EndTime AND A.EndTime > T.StartTime )
						OR ( A.StartTime >= T.StartTime   AND A.StartTime <T.EndTime AND A.EndTime > T.EndTime )
						OR ( A.StartTime < T.StartTime  AND A.EndTime > T.EndTime))
						group by A.StartTime,A.EndTime,A.machineid
			)TT
			INNER JOIN #Temp1 ON TT.StartTime=#Temp1.StartTime and #Temp1.EndTime=TT.EndTime and TT.machineid=#Temp1.machineid
			END

			SET IDENTITY_INSERT #TempCockpitDownData Off
			insert into #TempCockpitDownData
			(
				Machineid,        
				StartTime,
				EndTime,
				OperatorID,
				OperatorName,
				DownID,
				DownDescription,
				DownThreshold,
				DownTime,
				Remarks,
				[id],
				PDT, --ER0295
				DownStatus
			) 
			Select * from #temp1 order by starttime,endtime

		END

		create table #autodata_ICD        
		(        
		sttime datetime,        
		ndtime datetime,        
		mc nvarchar(50),        
		dcode nvarchar(50),        
		opr nvarchar(50),        
		Loadunload int,        
		[id] bigint        
		)        
      
		Select @mc=interfaceid from machineinformation where machineid=@machineid        
		Select @curtime=getdate()        
		select @curtime=case when @curtime>@EndTime then @EndTime else @curtime end

	
		select case when RawData.sttime<@StartTime then @StartTime else RawData.Sttime end as sttime,@EndTime as ndtime,RawData.mc into #CycleStart from 
		(select mc,max(slno) as slno from rawdata 
		inner join Autodata_Maxtime A on A.Machineid=RawData.Mc
		where sttime>=A.Endtime and sttime<=@Curtime and datatype=11 group by mc)R
		inner join rawdata on R.slno=RawData.SlNo
		inner join Autodata_Maxtime A on A.Machineid=RawData.Mc
		INNER JOIN machineinformation ON A.Machineid = machineinformation.InterfaceID 
		where RawData.sttime>=A.Endtime and RawData.sttime<=@Curtime and RawData.datatype=11 
		and (machineinformation.machineid=@MachineID or ISNULL(@machineid,'')='') order by RawData.sttime 

		--Insert into #autodata_ICD (sttime,ndtime,mc,dcode,opr,loadunload,id)       
		--select sttime,ndtime,mc,dcode,opr,loadunload,id from Autodata_ICD   AI
		--INNER JOIN machineinformation ON AI.mc = machineinformation.InterfaceID         
		--inner join Autodata_MaxTime AM on AM.Machineid=AI.mc     
		--where sttime>=AM.Endtime and ndtime<=@Curtime  
		--and (machineinformation.machineid=@MachineID or ISNULL(@machineid,'')='')      
      
	  	Insert into #autodata_ICD (sttime,ndtime,mc,dcode,opr,loadunload,id)       
		select AI.sttime,AI.ndtime,AI.mc,AI.dcode,AI.opr,AI.loadunload,AI.id from Autodata_ICD AI
		inner join #CycleStart I on I.mc=AI.mc
		where AI.sttime>=I.sttime and AI.ndtime<=I.ndtime
		

		SELECT machineinformation.machineid,   --added 
		case when A.sttime<@starttime then @starttime else A.sttime end AS StartTime,        
		case when A.ndtime>@endtime then @endtime else A.ndtime end AS EndTime,        
		employeeinformation.Employeeid AS OperatorID,        
		employeeinformation.[Name]  AS OperatorName,        
		downcodeinformation.downid AS DownID,        
		downcodeinformation.downdescription as [DownDescription],        
		CASE        
		WHEN downcodeinformation.AvailEffy=1 and downcodeinformation.Threshold>0 THEN downcodeinformation.Threshold        
		ELSE 0 END AS [DownThreshold],        
		case        
		When (A.sttime >= @StartTime AND A.ndtime <= @EndTime ) THEN A.loadunload        
		WHEN ( A.sttime < @StartTime AND A.ndtime <= @EndTime AND A.ndtime > @StartTime ) THEN DateDiff(second, @StartTime, A.ndtime)        
		WHEN ( A.sttime >= @StartTime AND A.sttime < @EndTime AND A.ndtime > @EndTime ) THEN  DateDiff(second, A.stTime, @EndTime)        
		ELSE        
		DateDiff(second, @StartTime, @EndTime)END AS DownTime,        
		'Current Cycle ICD Record' as Remarks,        
		A.id,        
		0 as PDT,'In Process Cycle' as DownStatus      
		INTO #Temp2        
		FROM  #autodata_ICD A         
		INNER JOIN machineinformation ON A.mc = machineinformation.InterfaceID         
		INNER JOIN downcodeinformation ON A.dcode = downcodeinformation.interfaceid         
		INNER JOIN employeeinformation ON A.opr = employeeinformation.interfaceid        
		WHERE  (machineinformation.machineid=@MachineID or ISNULL(@machineid,'')='')  AND          --Commented
		(        
		(A.sttime >= @StartTime  AND A.ndtime <=@EndTime)        
		OR ( A.sttime < @StartTime  AND A.ndtime <= @EndTime AND A.ndtime > @StartTime )        
		OR ( A.sttime >= @StartTime   AND A.sttime <@EndTime AND A.ndtime > @EndTime )        
		OR ( A.sttime < @StartTime  AND A.ndtime > @EndTime)        
		)        
		ORDER BY A.mc,A.ndtime        
        
		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'        
		BEGIN        
		update #Temp2 set DownTime = isnull(Downtime,0)-isnull(TT.plannedDT,0), PDT=isnull(TT.plannedDT,0)        
		from        
		(        
		Select A.StartTime,A.EndTime,A.machineid,           
		sum(case        
		WHEN A.StartTime >= T.StartTime  AND A.EndTime <=T.EndTime  THEN A.DownTime        
		WHEN ( A.StartTime < T.StartTime  AND A.EndTime <= T.EndTime  AND A.EndTime > T.StartTime ) THEN DateDiff(second,T.StartTime,A.EndTime)        
		WHEN ( A.StartTime >= T.StartTime   AND A.StartTime <T.EndTime  AND A.EndTime > T.EndTime  ) THEN DateDiff(second,A.StartTime,T.EndTime )        
		WHEN ( A.StartTime < T.StartTime  AND A.EndTime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )        
		END) as plannedDT        
		From #Temp2 A CROSS jOIN PlannedDownTimes T        
		WHERE -- T.machine=@machineid  and  --Commented
		A.machineid=T.Machine and --Added
		pdtstatus=1 and         
		((A.StartTime >= T.StartTime  AND A.EndTime <=T.EndTime)        
		OR ( A.StartTime < T.StartTime  AND A.EndTime <= T.EndTime AND A.EndTime > T.StartTime )        
		OR ( A.StartTime >= T.StartTime   AND A.StartTime <T.EndTime AND A.EndTime > T.EndTime )        
		OR ( A.StartTime < T.StartTime  AND A.EndTime > T.EndTime))        
		group by A.StartTime,A.EndTime,A.machineid      
		)TT        
		INNER JOIN #Temp2 ON TT.StartTime=#Temp2.StartTime and #Temp2.EndTime=TT.EndTime  and #Temp2.machineid=TT.machineid         
		END        
        
        
		insert into #TempCockpitDownData        
		(
		Machineid,        
		StartTime,        
		EndTime,        
		OperatorID,        
		OperatorName,        
		DownID,        
		DownDescription,        
		DownThreshold,        
		DownTime,        
		Remarks,        
		[id],        
		PDT,
		DownStatus    
		) Select * from #temp2 order by Machineid,starttime,endtime   


	iF @Param='DowntimeSummary'
	Begin

		insert into #DowntimeSummary(Machineid,DownDescription,DownTime,NoOfOccurences)
		Select Machineid,DownDescription,SUM(cast(DownTime as float)),COUNT(DownID) as NoOfOccurences
		From #TempCockpitDownData group by Machineid,DownDescription

		update #DowntimeSummary set MinDowntime=T.MinDowntime from(
		select  Machineid,DownDescription,case when COUNT(DownDescription)>1 then Min(cast(Downtime as float)) else 0 end as MinDowntime
		From #TempCockpitDownData group by Machineid,DownDescription)T inner join #DowntimeSummary on T.Machineid=#DowntimeSummary.Machineid
		and T.DownDescription=#DowntimeSummary.DownDescription

		update #DowntimeSummary set MaxDowntime=T.MaxDowntime from(
		select  Machineid,DownDescription,Max(cast(Downtime as float)) as MaxDowntime
		From #TempCockpitDownData group by Machineid,DownDescription)T inner join #DowntimeSummary on T.Machineid=#DowntimeSummary.Machineid
		and T.DownDescription=#DowntimeSummary.DownDescription

		update #DowntimeSummary set DowntimePercent=(ISNULL(#DowntimeSummary.downtime,0)/ISNULL(T.TotalDown,0))*100 from(
		select  Machineid,SUM(cast(Downtime as float)) as TotalDown
		From #TempCockpitDownData group by Machineid)T inner join #DowntimeSummary on T.Machineid=#DowntimeSummary.Machineid


		select Machineid,DownDescription,dbo.f_FormatTime(DownTime,@TimeFormat) as DownTime,NoOfOccurences,dbo.f_FormatTime(MinDowntime,@TimeFormat) as MinDowntime,
		dbo.f_FormatTime(MaxDowntime,@TimeFormat) as MaxDowntime,Round(DowntimePercent,2) as DowntimePercent from #DowntimeSummary order by Machineid	
		RETURN
	END

	If @param='InProcessDownCycles'
	Begin
		SELECT
		Machineid, 
		StartTime,
		EndTime,DownDescription,
		dbo.f_FormatTime(DownTime, @TimeFormat) as DownTime ,
		dbo.f_FormatTime(DownThreshold,@TimeFormat) AS DownThreshold,
		CASE
		WHEN (DownTime > DownThreshold AND DownThreshold >= 0) THEN dbo.f_FormatTime(abs(DownTime-DownThreshold),@TimeFormat)
		ELSE '0' END AS netDownTime,DownStatus
		From #TempCockpitDownData
		order by Machineid,StartTime	
	return
	end


	If @param='Summary'
	Begin



		update #cockpitdata set downtime= isnull(downtime,0)+isnull(T.NetDownTime,0),Managementloss=Managementloss + isnull(T.ML,0)
		from
		(Select machineid,sum(case when DownThreshold > 0 THEN DownThreshold ELSE 0 END) AS ML,
				sum(CASE
		        WHEN (DownTime > DownThreshold AND DownThreshold >= 0) THEN abs(DownTime-DownThreshold)
		        ELSE '0' END ) AS NetDownTime,Sum(PDT) as PDT from  #TempCockpitDownData group by Machineid)T
		inner join #cockpitdata on #cockpitdata.MachineID=T.Machineid

		--resultset1
		If @machinelist='Y'
		Begin
		SELECT DISTINCT machineid FROM #cockpitdata
		UNION
		SELECT DISTINCT machineid FROM #TempCockpitProductionData 
		END

		--resultset2
		select Machineid,Machineinterface,Cyclecount,
		dbo.f_formattime( totaltime,'hh:mm:ss') as Totaltime,'100' as TotalEffy,

		--dbo.f_formattime(UtilisedTime,'hh:mm:ss') as Runtime, 
		--dbo.f_formattime((Totaltime-PDT-(Downtime+Managementloss)),'hh:mm:ss') as Runtime, --based on last discussion since if data not there then TT=Runtime so instead considered runtime=UT
		dbo.f_formattime(UtilisedTime,'hh:mm:ss') as Runtime, --Used for MonthlyReport
		dbo.f_formattime((Totaltime-PDT-(Downtime+Managementloss)),'hh:mm:ss') as RuntimeForDailyReport, --Used For Daily Report

		--Isnull(Round((UtilisedTime/CASE when Totaltime=0 then 1 else Totaltime END) * 100,2),0) as RuntimeEffy,
		--Isnull(Round(((Totaltime-PDT-(Downtime+Managementloss))/CASE when Totaltime=0 then 1 else (Totaltime-(Managementloss+PDT)) END) * 100,2),0) as RuntimeEffy, --based on last discussion since if data not there then TT=Runtime so instead considered runtime=UT
		Isnull(Round((UtilisedTime/CASE when Totaltime=0 then 1 else Totaltime END) * 100,2),0) as RuntimeEffy, --Used for MonthlyReport
		Isnull(Round(((Totaltime-PDT-(Downtime+Managementloss))/CASE when Totaltime=0 then 1 else (Totaltime-(Managementloss+PDT)) END) * 100,2),0) as RuntimeEffyForDailyReport, --Used For Daily Report

		dbo.f_formattime(Downtime,'hh:mm:ss') as NetDowntime,
		ISNULL(Round((Downtime/CASE when Totaltime=0 then 1 else Totaltime END) * 100,2),0) as NetDowntimeEffy,
		dbo.f_formattime(PDT,'hh:mm:ss') as PDT,
		ISNULL(Round((PDT/CASE when Totaltime=0 then 1 else Totaltime END) * 100,2),0) as PDTEffy,
		dbo.f_formattime(Managementloss,'hh:mm:ss') as ManagementLoss ,
		ISNULL(Round((Managementloss/CASE when Totaltime=0 then 1 else Totaltime END) * 100,2),0) as MGMTEffy,
		dbo.f_formattime((Totaltime-PDT),'hh:mm:ss') as AvailableTime
		from #cockpitdata order by Machineid --g: case totaltime added
		return			
	End

end


If @param='COLevelDetails'
Begin

	CREATE TABLE #ProductionTime
	(
		PMachineID  nvarchar(50),
		PMachineInterface nvarchar(50),
		PComponentID  nvarchar(50),
		PComponentInterface nvarchar(50),
		CompDescription nvarchar(50),
		POperationNo  Int,
		POperationInterface nvarchar(50),
		Price 	Float,
		ProdCount     Float,
		CNprodcount   Float,
		StdCycleTime  Float,
		AvgCycleTime  Float,
		MinCycleTime  Float,
		MaxCycleTime  Float,
		SpeedRation   Float(2),
		StdLoadUnload Float,
		AvgLoadUnload Float,
		MinLoadUnload Float,
		MaxLoadUnload Float,
		LoadRation    Float(2)
	)
	
	If @machineid<>''
	begin
		select @strmachine=' AND (M.machineid =N'''+@MachineID+''')'
	end

	SELECT @StrSql=''	
	SELECT @StrSql='INSERT INTO #ProductionTime(PMachineID,PMachineInterface,pComponentID,PComponentInterface,CompDescription,POperationNo,POperationInterface,Price,ProdCount,CNprodcount, '
	SELECT @StrSql=@StrSql+'StdCycleTime,AvgCycleTime,MinCycleTime,MaxCycleTime,SpeedRation,StdLoadUnload, '
	SELECT @StrSql=@StrSql+'AvgLoadUnload,MinLoadUnload,MaxLoadUnload,LoadRation)'
	SELECT @StrSql=@StrSql+'SELECT M.MachineID,M.InterfaceID,C.ComponentID,C.interfaceID,C.Description,O.OperationNo,O.interfaceid,Max(O.Price),'
	SELECT @StrSql=@StrSql+'CAST((CAST(sum(A.partscount) AS Float )/ISNULL(O.SubOperations,1))AS FLOAT)AS ProdCount ,' 
	SELECT @StrSql=@StrSql+'CAST((CAST(sum(A.partscount) AS Float )/ISNULL(O.SubOperations,1))AS FLOAT)AS CNprodcount ,' 
	SELECT @StrSql=@StrSql+'O.MachiningTime  AS StdCycleTime,' 
	SELECT @StrSql=@StrSql+'AVG(A.Cycletime/A.partscount)* ISNULL(O.SubOperations,1) AS AvgCycleTime,'
	SELECT @StrSql=@StrSql+'Min(A.Cycletime/A.partscount)* ISNULL(O.SubOperations,1) AS MinCycleTime,'
	SELECT @StrSql=@StrSql+'Max(A.Cycletime/A.partscount)* ISNULL(O.SubOperations,1) AS MaxCycleTime,'
	SELECT @StrSql=@StrSql+'CASE WHEN (AVG(A.Cycletime/A.partscount)*ISNULL(O.SubOperations,1))>0 THEN '
	SELECT @StrSql=@StrSql+'O.MachiningTime /(AVG(A.Cycletime/A.partscount)*ISNULL(O.SubOperations,1)) ELSE 0 END AS SpeedRation,'
	SELECT @StrSql=@StrSql+'(O.CycleTime - O.MachiningTime) AS StdLoadUnload,0,'
	SELECT @StrSql=@StrSql+'Min(A.loadunload/A.partscount)* ISNULL(O.SubOperations,1) AS MinLoadUnload,'
	SELECT @StrSql=@StrSql+'Max(A.loadunload/A.partscount)* ISNULL(O.SubOperations,1) AS MaxLoadUnload,0'
	SELECT @StrSql=@StrSql+' FROM AutoData A Inner Join MachineInformation M ON A.mc=M.InterfaceID Inner Join  ComponentInformation C ON A.Comp=C.InterfaceID '
	SELECT @StrSql=@StrSql+' Inner Join ComponentOperationPricing O ON A.Opn=O.InterfaceID AND C.ComponentID=O.ComponentID AND M.MachineID=O.MachineID '
	SELECT @StrSql=@StrSql+' WHERE DataType=1 AND  Ndtime<='''+Convert(NvarChar(20),@EndTime,120)+''' AND Ndtime>'''+Convert(NvarChar(20),@StartTime,120)+''' '
	SELECT @StrSql=@StrSql+' and A.PartsCount > 0 '
	SELECT @StrSql=@StrSql+@strmachine
	SELECT @StrSql=@StrSql+' Group By M.MachineID,M.InterfaceID,C.ComponentID,C.interfaceID,C.Description,O.OperationNo,O.interfaceid,O.MachiningTime,O.CycleTime,O.SubOperations '
	SELECT @StrSql=@StrSql+' Order By C.ComponentID,O.OperationNo,M.MachineID'
	EXEC(@StrSql)

	SELECT @StrSql =''
	SELECT @StrSql ='Update #productiontime set AvgLoadUnload = ISNULL(T1.AvgLoadUnload,0),LoadRation = ISNULL(T1.LoadRation,0)'
	SELECT @StrSql=@StrSql + 'from ('
	SELECT @StrSql=@StrSql + 'SELECT M.MachineID,C.ComponentID,O.OperationNo ,'
	SELECT @StrSql=@StrSql + 'AVG(A.loadunload/A.partscount)*ISNULL(O.SubOperations,1) AS AvgLoadUnload ,CASE WHEN (AVG(A.loadunload/A.partscount)* ISNULL(O.SubOperations,1))>0 '
	SELECT @StrSql=@StrSql + 'THEN (O.CycleTime - O.MachiningTime)/(AVG(A.loadunload/A.partscount)* ISNULL(O.SubOperations,1)) '
	SELECT @StrSql=@StrSql + 'ELSE 0 END AS LoadRation '
	SELECT @StrSql=@StrSql + ' FROM AutoData A Inner join MachineInformation M ON A.mc=M.InterfaceID Inner Join  ComponentInformation C ON A.Comp=C.InterfaceID Inner Join ComponentOperationPricing O ON A.Opn=O.InterfaceID AND C.ComponentID=O.ComponentID and O.MachineID = M.MachineID '
	SELECT @StrSql=@StrSql + 'WHERE DataType=1 And partscount >0 AND A.loadunload >= isnull((SELECT top 1 VALUEININT FROM SHOPDEFAULTS where parameter = ''minluforlr''),0)'
	SELECT @StrSql=@StrSql + ' AND  Ndtime<='''+Convert(NvarChar(20),@EndTime,120)+''' AND Ndtime>'''+Convert(NvarChar(20),@StartTime,120)+''' '
	SELECT @StrSql=@StrSql+@strmachine
	SELECT @StrSql=@StrSql + ' Group By M.MachineID,C.ComponentID,O.OperationNo,O.SubOperations,O.CycleTime,O.MachiningTime'
	SELECT @StrSql=@StrSql + ' ) As T1 Inner Join  #productiontime '
	SELECT @StrSql=@StrSql + ' ON #productiontime.pMachineID=T1.MachineID AND #productiontime.pComponentID=T1.ComponentID AND #productiontime.POperationNo=T1.OperationNo'
	EXEC(@StrSql)	


	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
	BEGIN
		UPDATE #ProductionTime SET ProdCount = ISNULL(#ProductionTime.ProdCount,0) - ISNULL(T2.ProdCount,0)
		from(
			select mc,comp,opn, 
			SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as ProdCount 
			From (
				select mc,comp,opn,Sum(ISNULL(PartsCount,1))AS OrginalCount from #T_autodata autodata
				CROSS JOIN #PlannedDownTimes T
				WHERE autodata.DataType=1 And T.MachineInterface = autodata.mc
				AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)
				AND (autodata.ndtime > @StartTime  AND autodata.ndtime <=@EndTime)
				Group by mc,comp,opn
			) as T1
			Inner join Machineinformation M on M.interfaceID = T1.mc
			Inner join componentinformation C on T1.Comp=C.interfaceid
			Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineID = M.MachineID
			GROUP BY mc,comp,opn
		) as T2 inner join #ProductionTime on T2.mc = #ProductionTime.PMachineInterface and T2.Comp = #ProductionTime.PComponentInterface and T2.opn = #ProductionTime.POperationInterface
	END


	  --SELECT
	  --PMachineID,
	  --PComponentID+' ('+CompDescription+')' AS ComponentID ,
	  --POperationNo AS OperationNo ,
	  --Round(ProdCount,2) as ProdCount, 
	  --dbo.f_FormatTime(StdCycleTime,@TimeFormat) AS StdCycleTime ,
	  --dbo.f_FormatTime(AvgCycleTime,@TimeFormat) AS AvgCycleTime,
	  --dbo.f_FormatTime(MinCycleTime,@TimeFormat) AS MinCycleTime ,
	  --dbo.f_FormatTime(MaxCycleTime,@TimeFormat) AS MaxCycleTime,
	  --CEILING(SpeedRation) AS SpeedRation,			
	  --dbo.f_FormatTime(StdLoadUnload,@TimeFormat) AS StdLoadUnload,
	  --dbo.f_FormatTime(AvgLoadUnload,@TimeFormat) AS AvgLoadUnload ,
	  --dbo.f_FormatTime(MinLoadUnload,@TimeFormat) AS MinLoadUnload ,
	  --dbo.f_FormatTime(MaxLoadUnload,@TimeFormat) AS MaxLoadUnload,
	  --CEILING(LoadRation) AS LoadRation
	  --FROM #ProductionTime order by PMachineID, PComponentID,POperationNo

	  SELECT
	  PMachineID,
	  PComponentID+' ('+CompDescription+')' AS ComponentID ,
	  POperationNo AS OperationNo
	  FROM #ProductionTime order by PMachineID, PComponentID,POperationNo
end
END
