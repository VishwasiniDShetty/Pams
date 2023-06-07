/****** Object:  Procedure [dbo].[S_GetForgingProdAnalysisReport_Mangal]    Committed by VersionSQL https://www.versionsql.com ******/

/***************************************************************************************
-- Author:		Anjana C V
-- Create date: 07 May 2019
-- Modified date: 08 May 2019
-- Description: Get Forging Production Analysis Report Mangal
-- [S_GetForgingProdAnalysisReport_Mangal] '2019-04-24 06:00:00 AM','2019-04-25 06:00:00 AM'
**************************************************************************************/
CREATE PROCEDURE [dbo].[S_GetForgingProdAnalysisReport_Mangal]
	@StartTime datetime,
	@EndTime datetime
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @T_ST datetime
DECLARE @T_ED datetime
DECLARE @strsql nvarchar(max)
DECLARE @i as nvarchar(10)
DECLARE @colName as nvarchar(50)
Declare @timeformat AS nvarchar(12)  
--DECLARE @WaitingDown as nvarchar(50)
 CREATE TABLE #Target  
 ( 
 StartDate datetime,
 EndDate datetime,
 MachineID nvarchar(50) NOT NULL,  
 machineinterface nvarchar(50),
 AvailableTime Float, 
 NetAvalTime float,
 Utilization float,
 RunTime float,
 Uptime Float,
 TotalDelayTime float, 
 D1  float,
 D2  float,
 D3  float,
 D4  float,
 D5  float,
 C1 float,
 C2 float,
 C3 float,
 C4 float,
 C5 float,
 C6 float,
 C7 float,
 C8 Float, -- Lunch brk
 )

 
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
	id  bigint not null,
	WorkOrderNumber nvarchar(50)
)

ALTER TABLE #T_autodata

ADD PRIMARY KEY CLUSTERED
(
	mc,sttime,ndtime,msttime ASC
)ON [PRIMARY]


CREATE TABLE #PlannedDownTimesShift
	(
		SlNo int not null identity(1,1),
		Starttime datetime,
		EndTime datetime,
		Machine nvarchar(50),
		MachineInterface nvarchar(50),
		DownReason nvarchar(50),  
		ShiftSt datetime
	)

 Create table #Downcode
(
	Slno int identity(1,1) NOT NULL,
	Downid nvarchar(50),
	InterfaceId nvarchar(50),
	downCatergory nvarchar(50)
)

 Create table #DownCatergory
(
	Slno int identity(1,1) NOT NULL,
	downCatergory nvarchar(50)
)

Select @timeformat = 'mm'
SELECT @T_ST = @StartTime 
SELECT @T_ED = @EndTime

Insert into #Downcode(Downid,InterfaceId,downCatergory)
Select top 5 downid,InterfaceId,Catagory 
from downcodeinformation where 
catagory  = 'Management losses' 
order by sortorder

--Insert into #Downcode(Downid,InterfaceId,downCatergory)
--Select downid,InterfaceId,Catagory 
--from downcodeinformation
--where downid = 'Lunch time'

Insert into #DownCatergory
Select  DownCategory from DownCategoryInformation
where DownCategory in ('Measurement & Adjustment Loss','Set up & Adjustment loss','Length CO','Cutting Tool Repalcement losses',
'Break down loss','Bins not available','Waiting for Material, Personel & Meeting','Lunch & dinner')

Select @strsql=''
select @strsql ='insert into #T_autodata '
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'
	select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id,WorkOrderNumber'
select @strsql = @strsql + ' from autodata where 
  (( sttime >='''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_ED,120)+''' ) OR '  
select @strsql = @strsql + '( msttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+''' )
OR '  
select @strsql = @strsql + '( msttime <'''+ convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ST,120)+'''  
     and ndtime<='''+convert(nvarchar(25),@T_ED,120)+''' )'  
select @strsql = @strsql + ' OR ( msttime >='''+convert(nvarchar(25),@T_ST,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_ED,120)+'''
 and msttime<'''+convert(nvarchar(25),@T_ED,120)+''' ) )'  

print @strsql
exec (@strsql)
/***************************************************************************************/
INSERT INTO #Target(StartDate,EndDate,MachineID,machineinterface,AvailableTime,NetAvalTime,Utilization,
RunTime,Uptime,TotalDelayTime,D1,D2,D3,D4,D5,C8,C1,C2,C3,C4,C5,C6,C7) 
 Select distinct @StartTime,@EndTime,
 m.machineid,m.interfaceid,
 DateDiff(SECOND, @StartTime,@EndTime) AS AvailableTime,
 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 FROM Machineinformation m 
-- inner join #T_autodata autodata on autodata.mc = m.interfaceid
where  TPMTrakEnabled = 1 

/***************************************************************************************/
	insert INTO #PlannedDownTimesShift(StartTime,EndTime,Machine,MachineInterface,Downreason,Shiftst)
		select
		CASE When StartTime<@T_ST Then @T_ST Else StartTime End,
		case When EndTime>@T_ED Then @T_ED Else EndTime End,
		Machine,M.InterfaceID,
		DownReason,@T_ST
		FROM PlannedDownTimes 
		inner join MachineInformation M on PlannedDownTimes.machine = M.MachineID
		WHERE PDTstatus =1 and (
		(StartTime >= @T_ST  AND EndTime <=@T_ED)
		OR ( StartTime < @T_ST  AND EndTime <= @T_ED AND EndTime > @T_ST )
		OR ( StartTime >= @T_ST   AND StartTime <@T_ED AND EndTime > @T_ED )
		OR ( StartTime < @T_ST  AND EndTime > @T_ED) )
		and machine in (select distinct machine from #Target)
        ORDER BY StartTime

/***************************************************************************************/

Select @i=1
while @i <=6
Begin

 Select @ColName = Case when @i=1 then 'D1'
						when @i=2 then 'D2'
						when @i=3 then 'D3'
						when @i=4 then 'D4'
						when @i=5 then 'D5'
						END

			Select @strsql = ''
			Select @strsql = @strsql + ' UPDATE  #Target SET ' + @ColName + ' = isnull(' + @ColName + ',0) + isNull(t2.down,0)  
			from  
			(select  F.StartDate,F.EndDate,F.machineinterface,
			sum (CASE  
			WHEN (autodata.msttime >= F.StartDate  AND autodata.ndtime <=F.EndDate)  THEN autodata.loadunload  
			WHEN ( autodata.msttime < F.StartDate  AND autodata.ndtime <= F.EndDate  AND autodata.ndtime > F.StartDate ) 
			THEN DateDiff(second,F.StartDate,autodata.ndtime)  
			WHEN ( autodata.msttime >= F.StartDate   AND autodata.msttime <F.EndDate  AND autodata.ndtime > F.EndDate  ) 
			THEN DateDiff(second,autodata.msttime,F.EndDate )  
			WHEN ( autodata.msttime < F.StartDate  AND autodata.ndtime > F.EndDate ) THEN DateDiff(second,F.StartDate,F.EndDate )  
			END ) as down  
			from #T_autodata autodata   
			inner join  #Target F on autodata.mc = F.Machineinterface 
			inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid 
			inner join #Downcode on #Downcode.downid= downcodeinformation.downid
			where (autodata.datatype=''2'') AND  #Downcode.Slno= ' + @i + ' and 
			(( (autodata.msttime>=F.StartDate) and (autodata.ndtime<=F.EndDate))  
			OR ((autodata.msttime<F.StartDate)and (autodata.ndtime>F.StartDate)and (autodata.ndtime<=F.EndDate))  
			OR ((autodata.msttime>=F.StartDate)and (autodata.msttime<F.EndDate)and (autodata.ndtime>F.EndDate))  
			OR((autodata.msttime<F.StartDate)and (autodata.ndtime>F.EndDate))) 
			group by F.StartDate,F.EndDate,F.machineinterface
			) as t2 Inner Join #Target on t2.machineinterface = #Target.machineinterface and t2.StartDate=#Target.StartDate and t2.EndDate=#Target.EndDate'
			print @strsql
			exec(@Strsql)

			If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
			BEGIN   
				Select @strsql = '' 
				Select @strsql = @strsql + 'UPDATE  #Target SET ' + @ColName + ' = isnull(' + @ColName + ',0) - isNull(T2.PPDT ,0)  
				FROM(  
				SELECT  F.StartDate,F.EndDate,F.machineinterface,
				SUM  
				(CASE  
				WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)  
				WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
				WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )  
				WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
				END ) as PPDT  
				FROM #T_autodata AutoData  
				CROSS jOIN #PlannedDownTimesShift T  
				INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID  
				INNER JOIN #Target F on F.machineinterface=Autodata.mc
				inner join #Downcode on #Downcode.downid= downcodeinformation.downid
				WHERE autodata.DataType=''2'' AND T.MachineInterface=autodata.mc 
				and #Downcode.Slno= ' + @i + '  
				AND  
				((autodata.sttime >= F.StartDate  AND autodata.ndtime <=F.EndDate)  
				OR ( autodata.sttime < F.StartDate  AND autodata.ndtime <= F.EndDate AND autodata.ndtime > F.StartDate )  
				OR ( autodata.sttime >= F.StartDate   AND autodata.sttime <F.EndDate AND autodata.ndtime > F.EndDate )  
				OR ( autodata.sttime < F.StartDate  AND autodata.ndtime > F.EndDate))  
				AND  
				((autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
				OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
				OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )  
				OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )   
				AND  
				((F.StartDate >= T.StartTime  AND F.EndDate <=T.EndTime)  
				OR ( F.StartDate < T.StartTime  AND F.EndDate <= T.EndTime AND F.EndDate > T.StartTime )  
				OR ( F.StartDate >= T.StartTime   AND F.StartDate <T.EndTime AND F.EndDate > T.EndTime )  
				OR ( F.StartDate < T.StartTime  AND F.EndDate > T.EndTime) )   
				group  by F.StartDate,F.EndDate,F.machineinterface
				)AS T2  Inner Join #Target on t2.machineinterface = #Target.machineinterface   
				and t2.StartDate=#Target.StartDate and t2.EndDate=#Target.EndDate  '
				print @strsql
				exec(@Strsql)
			END


     select @i  =  @i + 1
	 END

/***************************************************************************************/

Select @i=1
while @i <=8
Begin

 Select @ColName = Case when @i=1 then 'C1'
						when @i=2 then 'C2'
						when @i=3 then 'C3'
						when @i=4 then 'C4'
						when @i=5 then 'C5'
						when @i=6 then 'C6'
						when @i=7 then 'C7'
						when @i=8 then 'C8'
						END

			Select @strsql = ''
			Select @strsql = @strsql + ' UPDATE  #Target SET ' + @ColName + ' = isnull(' + @ColName + ',0) + isNull(t2.down,0)  
			from  
			(select  F.StartDate,F.EndDate,F.machineinterface,
			sum (CASE  
			WHEN (autodata.msttime >= F.StartDate  AND autodata.ndtime <=F.EndDate)  THEN autodata.loadunload  
			WHEN ( autodata.msttime < F.StartDate  AND autodata.ndtime <= F.EndDate  AND autodata.ndtime > F.StartDate ) 
			THEN DateDiff(second,F.StartDate,autodata.ndtime)  
			WHEN ( autodata.msttime >= F.StartDate   AND autodata.msttime <F.EndDate  AND autodata.ndtime > F.EndDate  ) 
			THEN DateDiff(second,autodata.msttime,F.EndDate )  
			WHEN ( autodata.msttime < F.StartDate  AND autodata.ndtime > F.EndDate ) THEN DateDiff(second,F.StartDate,F.EndDate )  
			END ) as down  
			from #T_autodata autodata   
			inner join  #Target F on autodata.mc = F.Machineinterface 
			inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid 
			inner join #DownCatergory on #DownCatergory.downCatergory= downcodeinformation.Catagory
			where (autodata.datatype=''2'') AND  #DownCatergory.Slno= ' + @i + ' and 
			(( (autodata.msttime>=F.StartDate) and (autodata.ndtime<=F.EndDate))  
			OR ((autodata.msttime<F.StartDate)and (autodata.ndtime>F.StartDate)and (autodata.ndtime<=F.EndDate))  
			OR ((autodata.msttime>=F.StartDate)and (autodata.msttime<F.EndDate)and (autodata.ndtime>F.EndDate))  
			OR((autodata.msttime<F.StartDate)and (autodata.ndtime>F.EndDate))) 
			group by F.StartDate,F.EndDate,F.machineinterface
			) as t2 Inner Join #Target on t2.machineinterface = #Target.machineinterface and t2.StartDate=#Target.StartDate and t2.EndDate=#Target.EndDate'
			print @strsql
			exec(@Strsql)

			If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
			BEGIN   
				Select @strsql = '' 
				Select @strsql = @strsql + 'UPDATE  #Target SET ' + @ColName + ' = isnull(' + @ColName + ',0) - isNull(T2.PPDT ,0)  
				FROM(  
				SELECT  F.StartDate,F.EndDate,F.machineinterface,
				SUM  
				(CASE  
				WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)  
				WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
				WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )  
				WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
				END ) as PPDT  
				FROM #T_autodata AutoData  
				CROSS jOIN #PlannedDownTimesShift T  
				INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID  
				INNER JOIN #Target F on F.machineinterface=Autodata.mc
				inner join #DownCatergory on #DownCatergory.downCatergory= downcodeinformation.Catagory
				WHERE autodata.DataType=''2'' AND T.MachineInterface=autodata.mc 
				and #DownCatergory.Slno= ' + @i + '  
				AND  
				((autodata.sttime >= F.StartDate  AND autodata.ndtime <=F.EndDate)  
				OR ( autodata.sttime < F.StartDate  AND autodata.ndtime <= F.EndDate AND autodata.ndtime > F.StartDate )  
				OR ( autodata.sttime >= F.StartDate   AND autodata.sttime <F.EndDate AND autodata.ndtime > F.EndDate )  
				OR ( autodata.sttime < F.StartDate  AND autodata.ndtime > F.EndDate))  
				AND  
				((autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
				OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
				OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )  
				OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )   
				AND  
				((F.StartDate >= T.StartTime  AND F.EndDate <=T.EndTime)  
				OR ( F.StartDate < T.StartTime  AND F.EndDate <= T.EndTime AND F.EndDate > T.StartTime )  
				OR ( F.StartDate >= T.StartTime   AND F.StartDate <T.EndTime AND F.EndDate > T.EndTime )  
				OR ( F.StartDate < T.StartTime  AND F.EndDate > T.EndTime) )   
				group  by F.StartDate,F.EndDate,F.machineinterface
				)AS T2  Inner Join #Target on t2.machineinterface = #Target.machineinterface   
				and t2.StartDate=#Target.StartDate and t2.EndDate=#Target.EndDate  '
				print @strsql
				exec(@Strsql)
			END


     select @i  =  @i + 1
	 END

/***************************************************************************************/
--select @WaitingDown = 'C'+ convert(nvarchar,slno) From #DownCatergory

--Select @strsql = '' 
--				Select @strsql = @strsql + 'UPDATE  #Target SET ' + @WaitingDown + ' = isnull(' + @WaitingDown + ',0) - isNull(C8 ,0) '
--print @strsql
--exec(@Strsql)
/*
/**********************************RunTime********************************************/
UPDATE #Target SET RunTime = isnull(RunTime,0) + isNull(t2.cycle,0)    
from    
(select S.MachineID,S.StartDate ,S.EndDate,    
 sum(case when ((autodata.sttime>=S.StartDate ) and (autodata.ndtime<=S.EndDate)) THEN autodata.cycletime
   when ((autodata.sttime<S.StartDate )and (autodata.ndtime>S.StartDate )and (autodata.ndtime<=S.EndDate)) then DateDiff(second, S.StartDate , autodata.ndtime)    
   when ((autodata.sttime>=S.StartDate )and (autodata.sttime<S.EndDate)and (autodata.ndtime>S.EndDate)) then DateDiff(second, autodata.sttime, S.EndDate)    
   when ((autodata.sttime<S.StartDate )and (autodata.ndtime>S.EndDate)) then DateDiff(second, S.StartDate , S.EndDate) END ) as cycle    
from #T_autodata autodata     
inner join #Target S on autodata.mc = S.Machineinterface 
where (autodata.datatype=1) AND(( (autodata.sttime>=S.StartDate ) and (autodata.ndtime<=S.EndDate))    
OR ((autodata.sttime<S.StartDate )and (autodata.ndtime>S.StartDate )and (autodata.ndtime<=S.EndDate))    
OR ((autodata.sttime>=S.StartDate )and (autodata.sttime<S.EndDate)and (autodata.ndtime>S.EndDate))    
OR((autodata.sttime<S.StartDate )and (autodata.ndtime>S.EndDate)))    
group by S.MachineID,S.StartDate ,S.EndDate    
) as t2 inner join #Target on t2.MachineID = #Target.MachineID   
and t2.StartDate=#Target.StartDate and t2.EndDate=#Target.EndDate 

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
BEGIN

UPDATE  #Target SET  RunTime = isnull(RunTime,0) - isNull(T2.RunTime1 ,0)
  FROM(    
  SELECT F.StartDate,F.EndDate,F.machineinterface,   
    SUM    
     (CASE    
     WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN autodata.cycletime--DateDiff(second,autodata.sttime,autodata.ndtime) --DR0325 Added    
     WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)    
     WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )    
     WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )    
     END ) as RunTime1
     FROM #T_autodata AutoData    
     CROSS jOIN #PlannedDownTimesShift T    
     INNER JOIN #Target F on F.machineinterface=Autodata.mc 
     WHERE autodata.DataType=1 AND T.MachineInterface=autodata.mc AND    
      ((autodata.sttime >= F.StartDate  AND autodata.ndtime <=F.EndDate)    
      OR ( autodata.sttime < F.StartDate  AND autodata.ndtime <= F.EndDate AND autodata.ndtime > F.StartDate )    
      OR ( autodata.sttime >= F.StartDate   AND autodata.sttime <F.EndDate AND autodata.ndtime > F.EndDate )    
      OR ( autodata.sttime < F.StartDate  AND autodata.ndtime > F.EndDate))    
      AND    
      ((autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)    
      OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )    
      OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )    
      OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime) )     
      AND    
      ((F.StartDate >= T.StartTime  AND F.EndDate <=T.EndTime)    
      OR ( F.StartDate < T.StartTime  AND F.EndDate <= T.EndTime AND F.EndDate > T.StartTime )    
      OR ( F.StartDate >= T.StartTime   AND F.StartDate <T.EndTime AND F.EndDate > T.EndTime )    
      OR ( F.StartDate < T.StartTime  AND F.EndDate > T.EndTime) )     
      group  by F.StartDate,F.EndDate,F.machineinterface
  )AS T2  Inner Join #Target on t2.machineinterface = #Target.machineinterface 
  and t2.StartDate=#Target.StartDate and t2.EndDate=#Target.EndDate 
  END
/***************************************************************************************/
*/
UPDATE  #Target SET NetAvalTime = (AvailableTime - (D1+D2+D3+D4+D5))
UPDATE  #Target SET Utilization = (NetAvalTime/AvailableTime) * 100 where AvailableTime <> 0
UPDATE  #Target SET RunTime = (AvailableTime - (D1+D2+D3+D4+D5+C1+C2+C3+C4+C5+C6+C7+C8))
UPDATE  #Target SET Uptime = (RunTime/NetAvalTime) * 100 where NetAvalTime <> 0
UPDATE  #Target SET TotalDelayTime = (NetAvalTime - RunTime ) 

SELECT * from #Downcode
SELECT * From #DownCatergory

SELECT
StartDate,EndDate,MachineID,machineinterface,dbo.f_FormatTime(AvailableTime,@TimeFormat) AvailableTime,dbo.f_FormatTime(NetAvalTime,@TimeFormat) NetAvalTime,
round(Utilization,2) Utilization, dbo.f_FormatTime(RunTime,@TimeFormat) RunTime,Round(Uptime,2) Uptime,dbo.f_FormatTime(TotalDelayTime,@TimeFormat) TotalDelayTime,
dbo.f_FormatTime(D1,@TimeFormat) D1,dbo.f_FormatTime(D2,@TimeFormat) D2, dbo.f_FormatTime(D3,@TimeFormat) D3,
dbo.f_FormatTime(D4,@TimeFormat) D4,dbo.f_FormatTime(D5,@TimeFormat) D5,
dbo.f_FormatTime(C1,@TimeFormat) C1,dbo.f_FormatTime(C2,@TimeFormat) C2,dbo.f_FormatTime(C3,@TimeFormat) C3,
dbo.f_FormatTime(C4,@TimeFormat) C4, dbo.f_FormatTime(C5,@TimeFormat) C5,dbo.f_FormatTime(C6,@TimeFormat) C6,
dbo.f_FormatTime(C7,@TimeFormat) C7,dbo.f_FormatTime(C8,@TimeFormat) C8
FROM #Target
ORDER BY MachineID

SELECT
dbo.f_FormatTime(SUM(AvailableTime),@TimeFormat) AvailableTime,dbo.f_FormatTime(SUM(NetAvalTime),@TimeFormat) NetAvalTime,
Round(((SUM(NetAvalTime)/SUM(AvailableTime))*100),2) Utilization, 
dbo.f_FormatTime(SUM(RunTime),@TimeFormat) RunTime,
round(((SUM(RunTime)/SUM(NetAvalTime))*100),2) Uptime,
dbo.f_FormatTime(SUM(TotalDelayTime),@TimeFormat) TotalDelayTime,
dbo.f_FormatTime(SUM(D1),@TimeFormat) D1,dbo.f_FormatTime(SUM(D2),@TimeFormat) D2, dbo.f_FormatTime(SUM(D3),@TimeFormat) D3,
dbo.f_FormatTime(SUM(D4),@TimeFormat) D4,dbo.f_FormatTime(SUM(D5),@TimeFormat) D5,
dbo.f_FormatTime(SUM(C1),@TimeFormat) C1,dbo.f_FormatTime(SUM(C2),@TimeFormat) C2,dbo.f_FormatTime(SUM(C3),@TimeFormat) C3,
dbo.f_FormatTime(SUM(C4),@TimeFormat) C4, dbo.f_FormatTime(SUM(C5),@TimeFormat) C5,dbo.f_FormatTime(SUM(C6),@TimeFormat) C6,
dbo.f_FormatTime(SUM(C7),@TimeFormat) C7,dbo.f_FormatTime(SUM(C8),@TimeFormat) C8
FROM #Target

END 
