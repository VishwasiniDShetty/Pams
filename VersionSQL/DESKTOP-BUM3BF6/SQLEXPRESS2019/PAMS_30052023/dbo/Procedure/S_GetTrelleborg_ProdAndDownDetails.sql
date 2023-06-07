/****** Object:  Procedure [dbo].[S_GetTrelleborg_ProdAndDownDetails]    Committed by VersionSQL https://www.versionsql.com ******/

--ER0461 - SwathiKS - 31/Jan/2018 :: Created new procedure For Trelleborg To show Prod and down Details at MO-Machine-Component Level.
--ER0465 - Gopinath - 15/may/2018 :: Performance Optimization(replaced cursor with partitionby).

--[dbo].[S_GetTrelleborg_ProdAndDownDetails] '2017-11-01 06:00:00 AM','2017-11-03 06:00:00 AM','','',''


CREATE Procedure [dbo].[S_GetTrelleborg_ProdAndDownDetails]
@Starttime datetime,
@Endtime datetime,
@PlantID nvarchar(50),
@Machineid nvarchar(50),
@Param nvarchar(50)
WITH RECOMPILE
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

CREATE TABLE #Target  
(
	PDate datetime,  
	Shift nvarchar(20), 
	Plantcode  nvarchar(50),
	MachineID nvarchar(50),
	machineinterface nvarchar(50),
	Component nvarchar(50),  
	Compinterface nvarchar(50),
	OpnInterface nvarchar(50),
	Operation nvarchar(50), 
	Operator nvarchar(50),
	Oprinterface nvarchar(50), 
	msttime datetime,
    ndtime datetime,
	FromTm datetime,
	ToTm datetime,   
    runtime int,   
    batchid int,
	Stdtime float,
	autodataid bigint,
	MONo nvarchar(50),
	StdSetupTime float
)

CREATE TABLE #FinalTarget    
(  
 Plantcode  nvarchar(50),  
 MachineID nvarchar(50) NOT NULL,  
 machineinterface nvarchar(50),  
 Component nvarchar(50) NOT NULL,  
 Compinterface nvarchar(50),  
 Operation nvarchar(50) NOT NULL,  
 OpnInterface nvarchar(50),    
 FromTm datetime,  
 ToTm datetime,     
 BatchStart datetime,  
 BatchEnd datetime,  
 batchid int,  
 MOQuantity int,
 MONO nvarchar(50),
 stdtime float,
 Runtime float,
 ToolAndNMPDown float,
 Components float,
 RejQty float,
 StdSetupTime float,
 [1stshift operator] nvarchar(max),
 [1stshift Components] float,
 [1stshift UT] float,
 [2ndshift operator] nvarchar(max),
 [2ndshift Components] float,
 [2ndshift UT] float,
 [3rdshift operator] nvarchar(max),
 [3rdshift Components] float,
 [3rdshift UT] float,
 [NoOfShots 1stShift] float,
 [NoOfShots 2ndShift] float,
 [NoOfShots 3rdShift] float,
 A  float,
 B  float,
 C  float,
 D  float,
 E  float,
 F  float,
 G  float,
 H  float,
 I  float,
 J  float,
 K  float,
 L  float,
 M  float,
 N  float,
 O  float,
 P  float
) 

CREATE TABLE #ShiftwiseFinalTarget    
(  
 Plantcode  nvarchar(50),  
 MachineID nvarchar(50) NOT NULL,  
 machineinterface nvarchar(50),  
 Component nvarchar(50) NOT NULL,  
 Compinterface nvarchar(50),  
 Operation nvarchar(50) NOT NULL,  
 OpnInterface nvarchar(50),  
 operator nvarchar(max),
  PDate datetime,  
 Shift nvarchar(20),    
 FromTm datetime,  
 ToTm datetime,     
 BatchStart datetime,  
 BatchEnd datetime,  
 batchid int,  
 MOQuantity int,
 MONO nvarchar(50),
 stdtime float,
 Runtime float,
 Components float,
 [NoOfShotsPerShift] float
) 

Create table #PlannedDownTimes
(
	MachineID nvarchar(50),
	MachineInterface nvarchar(50),
	StartTime DateTime,
	EndTime DateTime
)


CREATE TABLE #T_autodata
(
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
	[msttime] [datetime] NULL,
	[PartsCount] [int] NULL ,
	id  bigint not null,
	[WorkOrderNumber] [nvarchar](50) NULL
)

ALTER TABLE #T_autodata

ADD PRIMARY KEY CLUSTERED
(
	mc,sttime,ndtime ASC
)ON [PRIMARY]

Create table #Day
( StartTime datetime,
EndTime datetime
)

Create table #Downcode
(
	Slno int identity(1,1) NOT NULL,
	Downid nvarchar(50)
)

CREATE TABLE #ShiftDetails   
(  
 PDate datetime,  
 Shift nvarchar(20),  
 ShiftStart datetime,  
 ShiftEnd datetime  
)  

Insert into #Downcode(Downid)
Select top 16 downid from downcodeinformation where 
SortOrder<=16 and SortOrder IS NOT NULL order by sortorder

If @param = 'DownCodeList'
Begin
	select downid from #Downcode order by slno
	return
end 

Declare @strsql as nvarchar(4000)
Declare @strMachine as nvarchar(255)
Declare @strPlantID as nvarchar(255)
SELECT @strPlantID = ''
SELECT @strMachine = ''
Select @strsql = ''

Declare @T_ST AS Datetime 
Declare @T_ED AS Datetime
Select @T_ST=convert(nvarchar(25),@StartTime,120)
Select @T_ED=convert(nvarchar(25),@EndTime,120)

Declare @T_START AS Datetime 
Declare @T_END AS Datetime 

Select @T_START=dbo.f_GetLogicalDay(@StartTime,'start')
Select @T_END=dbo.f_GetLogicalDay(@EndTime,'End')

if isnull(@machineid,'')<> ''
begin
	SET @strMachine = ' AND MachineInformation.MachineID = N''' + @machineid + ''''
end

if isnull(@PlantID,'')<> ''
Begin

	SET @strPlantID = ' AND PlantMachine.PlantID = N''' + @PlantID + ''''
End

Select @strsql=''
select @strsql ='insert into #T_autodata '
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'
 select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id,WorkOrderNumber'
select @strsql = @strsql + ' from autodata WITH (NOLOCK) where (( sttime >='''+ convert(nvarchar(25),@T_START,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_END,120)+''' ) OR '
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_START,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_END,120)+''' )OR '
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_START,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_START,120)+'''
				 and ndtime<='''+convert(nvarchar(25),@T_END,120)+''' )'
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_START,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_END,120)+''' and sttime<'''+convert(nvarchar(25),@T_END,120)+''' ) )'
print @strsql
exec (@strsql)

SET @strSql = ''
SET @strSql = 'Insert into #PlannedDownTimes
	SELECT Machine,InterfaceID,
		CASE When StartTime<''' + convert(nvarchar(20),@StartTime,120)+''' Then ''' + convert(nvarchar(20),@StartTime,120)+''' Else StartTime End As StartTime,
		CASE When EndTime>''' + convert(nvarchar(20),@EndTime,120)+''' Then ''' + convert(nvarchar(20),@EndTime,120)+''' Else EndTime End As EndTime
	FROM PlannedDownTimes inner join MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID
	WHERE PDTstatus =1 and(
	(StartTime >= ''' + convert(nvarchar(20),@StartTime,120)+''' AND EndTime <=''' + convert(nvarchar(20),@EndTime,120)+''')
	OR ( StartTime < ''' + convert(nvarchar(20),@StartTime,120)+'''  AND EndTime <= ''' + convert(nvarchar(20),@EndTime,120)+''' AND EndTime > ''' + convert(nvarchar(20),@StartTime,120)+''' )
	OR ( StartTime >= ''' + convert(nvarchar(20),@StartTime,120)+'''   AND StartTime <''' + convert(nvarchar(20),@EndTime,120)+''' AND EndTime > ''' + convert(nvarchar(20),@EndTime,120)+''' )
	OR ( StartTime < ''' + convert(nvarchar(20),@StartTime,120)+'''  AND EndTime > ''' + convert(nvarchar(20),@EndTime,120)+''')) '
SET @strSql =  @strSql +  ' ORDER BY Machine,StartTime'
EXEC(@strSql)

while @T_START<=@T_END
Begin
	insert into #Day(StartTime,EndTime)
	Select dbo.f_GetLogicalDay(@T_START,'start'),dbo.f_GetLogicalDay(@T_START,'END') --g: changed @starttime to @T_START
	Select @T_START =dateadd(day,1,@T_START)
End

Select @strsql=''   
Select @strsql= 'insert into #Target(Plantcode,MachineID,machineinterface,Component,Compinterface,Operation,Opninterface,  
MONo,msttime,ndtime,FromTm,Totm,batchid,autodataid,stdtime,StdSetupTime)'  
select @strsql = @strsql + ' SELECT P.PlantCode,machineinformation.machineid, machineinformation.interfaceid,componentinformation.componentid, componentinformation.interfaceid,  
componentoperationpricing.operationno, componentoperationpricing.interfaceid,MD.MONumber,  
Case when autodata.msttime< D.StartTime then D.StartTime else autodata.msttime end,   
Case when autodata.ndtime> D.EndTime then D.EndTime else autodata.ndtime end,  
D.StartTime,D.EndTime,0,autodata.id,componentoperationpricing.cycletime,componentoperationpricing.StdSetupTime FROM #T_autodata autodata  
INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID   
INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID    
INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID  AND componentinformation.componentid = componentoperationpricing.componentid  
and componentoperationpricing.machineid=machineinformation.machineid   
inner join MoDetails MD on autodata.mc=MD.Machineinterface and autodata.workorderNumber=MD.MONumber
Left Outer Join downcodeinformation DI on DI.interfaceid=autodata.dcode  
Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid  
inner join PlantInformation P on P.plantid=Plantmachine.plantid 
Cross join #Day D
WHERE ((autodata.msttime >= D.StartTime  AND autodata.ndtime <= D.EndTime)  
OR ( autodata.msttime < D.StartTime  AND autodata.ndtime <= D.EndTime AND autodata.ndtime >D.StartTime )  
OR ( autodata.msttime >= D.StartTime AND autodata.msttime <D.EndTime AND autodata.ndtime > D.EndTime)  
OR ( autodata.msttime < D.StartTime AND autodata.ndtime > D.EndTime))'  
select @strsql = @strsql + @strmachine + @strPlantID  
select @strsql = @strsql + ' order by autodata.msttime'  
print @strsql  
exec (@strsql)  

insert into #FinalTarget (Plantcode,MachineID,Component,operation,machineinterface,Compinterface,Opninterface,MONO,BatchStart,BatchEnd,FromTm,ToTm,stdtime,StdSetupTime,Runtime,batchid)   
Select Plantcode,MachineID,Component,operation,machineinterface,Compinterface,Opninterface,MONO,min(msttime),max(ndtime),FromTm,ToTm,stdtime,StdSetupTime,Datediff(second,min(msttime),max(ndtime)),batchid from
(
Select Plantcode,MachineID,Component,operation,machineinterface,Compinterface,Opninterface,MONO,msttime,ndtime,FromTm,ToTm,stdtime,StdSetupTime,
RANK() OVER (
  PARTITION BY t.machineid 
  order by t.machineid, t.msttime
) -
RANK() OVER (
  PARTITION BY t.machineid, t.Compinterface, t.OpnInterface, t.MONO , t.Fromtm 
  order by t.machineid, t.msttime
) AS batchid
from #Target t 
) tt group by Plantcode,MachineID,Component,operation,machineinterface,Compinterface,Opninterface,MONO,batchid,FromTm,ToTm,stdtime,StdSetupTime
order by tt.batchid
--/ER0457
 

If NOT Exists(Select Count(*) from #FinalTarget)
Begin
	Return;
End

Update #FinalTarget Set MOQuantity = Isnull(MOQuantity,0) + Isnull(T1.Qty,0) from
(Select MODetails.Machineinterface,MODetails.MONumber,MODetails.MOQty as Qty from MODetails
inner join #FinalTarget on MODetails.Machineinterface=#FinalTarget.machineinterface and MODetails.MONumber=#FinalTarget.MONo
)T1 inner join #FinalTarget on T1.Machineinterface=#FinalTarget.machineinterface and T1.MONumber=#FinalTarget.MONo


If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'  
BEGIN  
   
 --Get the utilised time overlapping with PDT and negate it from UtilisedTime  
  UPDATE  #FinalTarget SET Runtime = isnull(#FinalTarget.Runtime,0) - isNull(T2.PPDT ,0)  
  FROM(  
  SELECT F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.MONO,  
     SUM  
     (CASE  
     WHEN autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN DateDiff(second,autodata.msttime,autodata.ndtime) --DR0325 Added  
     WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
     WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )  
     WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
     END ) as PPDT  
     FROM #T_autodata AutoData  
     CROSS jOIN #PlannedDownTimes T  
     INNER JOIN #FinalTarget F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn and F.MONO=Autodata.WorkOrderNumber  
     WHERE autodata.DataType=1 AND T.MachineInterface=autodata.mc AND  
      ((autodata.msttime >= F.BatchStart  AND autodata.ndtime <=F.BatchEnd)  
      OR ( autodata.msttime < F.BatchStart  AND autodata.ndtime <= F.BatchEnd AND autodata.ndtime > F.BatchStart )  
      OR ( autodata.msttime >= F.BatchStart   AND autodata.msttime <F.BatchEnd AND autodata.ndtime > F.BatchEnd )  
      OR ( autodata.msttime < F.BatchStart  AND autodata.ndtime > F.BatchEnd))  
      AND  
      ((autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
      OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
      OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )  
      OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )   
      AND  
      ((F.BatchStart >= T.StartTime  AND F.BatchEnd <=T.EndTime)  
      OR ( F.BatchStart < T.StartTime  AND F.BatchEnd <= T.EndTime AND F.BatchEnd > T.StartTime )  
      OR ( F.BatchStart >= T.StartTime   AND F.BatchStart <T.EndTime AND F.BatchEnd > T.EndTime )  
      OR ( F.BatchStart < T.StartTime  AND F.BatchEnd > T.EndTime) )   
      group  by F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.MONO  
  )AS T2  Inner Join #FinalTarget on t2.machineinterface = #FinalTarget.machineinterface and  
  t2.compinterface = #FinalTarget.compinterface and t2.opninterface = #FinalTarget.opninterface and  t2.MONO = #FinalTarget.MONO   
  and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  

 END



---Get the down times which are not of type Management Loss  
 UPDATE #FinalTarget SET ToolAndNMPDown = isnull(ToolAndNMPDown,0) + isNull(t2.down,0)  
 from  
 (select  F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.MONO,  
  sum (CASE  
    WHEN (autodata.msttime >= F.BatchStart  AND autodata.ndtime <=F.BatchEnd)  THEN autodata.loadunload  
    WHEN ( autodata.msttime < F.BatchStart  AND autodata.ndtime <= F.BatchEnd  AND autodata.ndtime > F.BatchStart ) THEN DateDiff(second,F.BatchStart,autodata.ndtime)  
    WHEN ( autodata.msttime >= F.BatchStart   AND autodata.msttime <F.BatchEnd  AND autodata.ndtime > F.BatchEnd  ) THEN DateDiff(second,autodata.msttime,F.BatchEnd )  
    WHEN ( autodata.msttime < F.BatchStart  AND autodata.ndtime > F.BatchEnd ) THEN DateDiff(second,F.BatchStart,F.BatchEnd )  
    END ) as down  
    from #T_autodata autodata   
    inner join #FinalTarget F on autodata.mc = F.Machineinterface and autodata.comp=F.Compinterface and autodata.opn=F.Opninterface and autodata.WorkOrderNumber = F.MONO  
    inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid  
  where (autodata.datatype=2) AND  
    (( (autodata.msttime>=F.BatchStart) and (autodata.ndtime<=F.BatchEnd))  
       OR ((autodata.msttime<F.BatchStart)and (autodata.ndtime>F.BatchStart)and (autodata.ndtime<=F.BatchEnd))  
       OR ((autodata.msttime>=F.BatchStart)and (autodata.msttime<F.BatchEnd)and (autodata.ndtime>F.BatchEnd))  
       OR((autodata.msttime<F.BatchStart)and (autodata.ndtime>F.BatchEnd)))   
    AND downcodeinformation.downid in('Tool/Mould Change','Power Failure')
       group by F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.MONO  
 ) as t2 Inner Join #FinalTarget on t2.machineinterface = #FinalTarget.machineinterface and  
 t2.compinterface = #FinalTarget.compinterface and t2.opninterface = #FinalTarget.opninterface and  t2.MONO = #FinalTarget.MONO   
 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  
  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
BEGIN   
	 UPDATE  #FinalTarget SET ToolAndNMPDown = isnull(ToolAndNMPDown,0) - isNull(T2.PPDT ,0)  
	 FROM(  
	 SELECT F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.MONO,  
		SUM  
		(CASE  
		WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)  
		WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
		WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )  
		WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
		END ) as PPDT  
		FROM #T_autodata AutoData  
		CROSS jOIN #PlannedDownTimes T  
		INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID  
		INNER JOIN #FinalTarget F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn and F.MONO=Autodata.WorkOrderNumber  
		WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc and downcodeinformation.downid in ('Tool/Mould Change','Power Failure')
		 AND  
		 ((autodata.sttime >= F.BatchStart  AND autodata.ndtime <=F.BatchEnd)  
		 OR ( autodata.sttime < F.BatchStart  AND autodata.ndtime <= F.BatchEnd AND autodata.ndtime > F.BatchStart )  
		 OR ( autodata.sttime >= F.BatchStart   AND autodata.sttime <F.BatchEnd AND autodata.ndtime > F.BatchEnd )  
		 OR ( autodata.sttime < F.BatchStart  AND autodata.ndtime > F.BatchEnd))  
		 AND  
		 ((autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
		 OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
		 OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )  
		 OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )   
		 AND  
		 ((F.BatchStart >= T.StartTime  AND F.BatchEnd <=T.EndTime)  
		 OR ( F.BatchStart < T.StartTime  AND F.BatchEnd <= T.EndTime AND F.BatchEnd > T.StartTime )  
		 OR ( F.BatchStart >= T.StartTime   AND F.BatchStart <T.EndTime AND F.BatchEnd > T.EndTime )  
		 OR ( F.BatchStart < T.StartTime  AND F.BatchEnd > T.EndTime) )   
		 group  by F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.MONO  
	 )AS T2  Inner Join #FinalTarget on t2.machineinterface = #FinalTarget.machineinterface and  
	 t2.compinterface = #FinalTarget.compinterface and t2.opninterface = #FinalTarget.opninterface and  t2.MONO = #FinalTarget.MONO   
	 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd 
END

--Calculation of PartsCount Begins..  
UPDATE #FinalTarget SET components = ISNULL(components,0) + ISNULL(t2.comp1,0)
From  
(  
 Select T1.mc,T1.comp,T1.opn,T1.WorkOrderNumber,T1.Batchstart,T1.Batchend,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp1 From
	(
	select mc,comp,opn,WorkOrderNumber,BatchStart,BatchEnd,SUM(autodata.partscount)AS OrginalCount from #T_autodata autodata  
	INNER JOIN #FinalTarget F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn and F.MONO=Autodata.WorkOrderNumber  
	where (autodata.ndtime>F.BatchStart) and (autodata.ndtime<=F.BatchEnd) and (autodata.datatype=1)  
	Group By mc,comp,opn,WorkOrderNumber,BatchStart,BatchEnd
	) as T1  
 INNER JOIN #FinalTarget F on F.machineinterface=T1.mc and F.Compinterface=T1.comp and F.Opninterface = T1.opn and F.MONO=T1.WorkOrderNumber  
 and F.Batchstart=T1.Batchstart and F.Batchend=T1.Batchend
 Inner join componentinformation C on F.Compinterface = C.interfaceid  
 Inner join ComponentOperationPricing O ON  F.Opninterface = O.interfaceid and C.Componentid=O.componentid  
 inner join machineinformation on machineinformation.machineid =O.machineid  
 and F.machineinterface=machineinformation.interfaceid  
 GROUP BY T1.mc,T1.comp,T1.opn,T1.WorkOrderNumber,T1.Batchstart,T1.Batchend  
) As T2 Inner Join #FinalTarget on T2.mc = #FinalTarget.machineinterface and  
T2.comp = #FinalTarget.compinterface and T2.opn = #FinalTarget.opninterface and  T2.WorkOrderNumber = #FinalTarget.MONO   
and T2.BatchStart=#FinalTarget.BatchStart and T2.BatchEnd=#FinalTarget.BatchEnd  
  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
BEGIN  
    
 UPDATE #FinalTarget SET components=ISNULL(components,0)- isnull(t2.PlanCt,0) FROM 
 ( 
 select autodata.mc,autodata.comp,autodata.opn,autodata.WorkOrderNumber,F.Batchstart,F.Batchend,
  ((CAST(Sum(ISNULL(PartsCount,1)) AS Float)/ISNULL(CO.SubOperations,1))) as PlanCt
   from #T_autodata autodata   
  INNER JOIN #FinalTarget F on F.machineinterface=autodata.mc and F.Compinterface=autodata.comp and F.Opninterface = autodata.opn and F.MONO=autodata.WorkOrderNumber  
  Inner jOIN #PlannedDownTimes T on T.MachineInterface=autodata.mc    
  inner join machineinformation M on autodata.mc=M.Interfaceid  
  Inner join componentinformation CI on autodata.comp=CI.interfaceid   
  inner join componentoperationpricing CO on autodata.opn=CO.interfaceid and  
  CI.componentid=CO.componentid  and CO.machineid=M.machineid  
  WHERE autodata.DataType=1 and  
  (autodata.ndtime>F.BatchStart) and (autodata.ndtime<=F.BatchEnd)   
  AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)  
   Group by autodata.mc,autodata.comp,autodata.opn,autodata.WorkOrderNumber,F.Batchstart,F.Batchend,CO.SubOperations   
 ) as T2 Inner Join #FinalTarget on T2.mc = #FinalTarget.machineinterface and  
 T2.comp = #FinalTarget.compinterface and T2.opn = #FinalTarget.opninterface and  T2.WorkOrderNumber = #FinalTarget.MONO   
 and T2.BatchStart=#FinalTarget.BatchStart and T2.BatchEnd=#FinalTarget.BatchEnd  
   
END


Update #FinalTarget set RejQty = isnull(S.RejQty,0) - isnull(T1.RejQty,0) from  
 (Select S.machineinterface,S.Compinterface,S.OpnInterface,S.MONO,S.BatchStart,S.BatchEnd,SUM(A.Rejection_Qty) as RejQty from AutodataRejections A  
 inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid  
 inner join #FinalTarget S on A.mc = S.Machineinterface and A.comp=S.Compinterface and A.opn=S.Opninterface  and A.WorkOrderNumber = S.MONO 
 where  A.flag = 'Rejection' and convert(nvarchar(10),(A.RejDate),126)=convert(nvarchar(10),(S.BatchStart),126) and     
 Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'   
 group by S.machineinterface,S.Compinterface,S.OpnInterface,S.MONO,S.BatchStart,S.BatchEnd)T1
 inner join #FinalTarget S on T1.Machineinterface = S.Machineinterface and T1.Compinterface=S.Compinterface and T1.Opninterface=S.Opninterface  
 and T1.MONO = S.MONO and T1.BatchStart=S.BatchStart and T1.BatchEnd=S.BatchEnd 

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
BEGIN  

Update #FinalTarget set RejQty = isnull(S.RejQty,0) - isnull(T1.RejQty,0) from  
 (Select S.machineinterface,S.Compinterface,S.OpnInterface,S.MONO,S.BatchStart,S.BatchEnd,SUM(A.Rejection_Qty) as RejQty from AutodataRejections A  
 inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid  
 inner join #FinalTarget S on A.mc = S.Machineinterface and A.comp=S.Compinterface and A.opn=S.Opninterface  and A.WorkOrderNumber = S.MONO 
 Cross join #Planneddowntimes P
 where  A.flag = 'Rejection' and convert(nvarchar(10),(A.RejDate),126)=convert(nvarchar(10),(S.BatchStart),126) and     
 Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'   
 and P.starttime>=S.BatchStart and P.Endtime<=S.BatchEnd and P.machineid=S.Machineid
 group by S.machineinterface,S.Compinterface,S.OpnInterface,S.MONO,S.BatchStart,S.BatchEnd)T1
 inner join #FinalTarget S on T1.Machineinterface = S.Machineinterface and T1.Compinterface=S.Compinterface and T1.Opninterface=S.Opninterface  
 and T1.MONO = S.MONO and T1.BatchStart=S.BatchStart and T1.BatchEnd=S.BatchEnd 

END 

 
 
 declare @i as nvarchar(10)
declare @colName as nvarchar(50)
Select @i=1

while @i <=15
Begin
	Select @ColName = Case when @i=1 then 'A'
						when @i=2 then 'B'
						when @i=3 then 'C'
						when @i=4 then 'D'
						when @i=5 then 'E'
						when @i=6 then 'F'
						when @i=7 then 'G'
						when @i=8 then 'H'
						when @i=9 then 'I'
						when @i=10 then 'J'
						when @i=11 then 'K'
						when @i=12 then 'L'
						when @i=13 then 'M'
						when @i=14 then 'N'
						when @i=15 then 'O'
						 END



	 ---Get the down times which are not of type Management Loss  
	 Select @strsql = ''
	 Select @strsql = @strsql + ' UPDATE #FinalTarget SET ' + @ColName + ' = isnull(' + @ColName + ',0) + isNull(t2.down,0)  
	 from  
	 (select  F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.MONO,  
	  sum (CASE  
		WHEN (autodata.msttime >= F.BatchStart  AND autodata.ndtime <=F.BatchEnd)  THEN autodata.loadunload  
		WHEN ( autodata.msttime < F.BatchStart  AND autodata.ndtime <= F.BatchEnd  AND autodata.ndtime > F.BatchStart ) THEN DateDiff(second,F.BatchStart,autodata.ndtime)  
		WHEN ( autodata.msttime >= F.BatchStart   AND autodata.msttime <F.BatchEnd  AND autodata.ndtime > F.BatchEnd  ) THEN DateDiff(second,autodata.msttime,F.BatchEnd )  
		WHEN ( autodata.msttime < F.BatchStart  AND autodata.ndtime > F.BatchEnd ) THEN DateDiff(second,F.BatchStart,F.BatchEnd )  
		END ) as down  
		from #T_autodata autodata   
		inner join #FinalTarget F on autodata.mc = F.Machineinterface and autodata.comp=F.Compinterface and autodata.opn=F.Opninterface and autodata.WorkorderNumber = F.MONO  
		inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid 
		inner join #Downcode on #Downcode.downid= downcodeinformation.downid
		where (autodata.datatype=''2'') AND  #Downcode.Slno= ' + @i + ' and 
		(( (autodata.msttime>=F.BatchStart) and (autodata.ndtime<=F.BatchEnd))  
		   OR ((autodata.msttime<F.BatchStart)and (autodata.ndtime>F.BatchStart)and (autodata.ndtime<=F.BatchEnd))  
		   OR ((autodata.msttime>=F.BatchStart)and (autodata.msttime<F.BatchEnd)and (autodata.ndtime>F.BatchEnd))  
		   OR((autodata.msttime<F.BatchStart)and (autodata.ndtime>F.BatchEnd)))   
		   group by F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.MONO  
	 ) as t2 Inner Join #FinalTarget on t2.machineinterface = #FinalTarget.machineinterface and  
	 t2.compinterface = #FinalTarget.compinterface and t2.opninterface = #FinalTarget.opninterface and  t2.MONO = #FinalTarget.MONO   
	 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd '
     print @strsql
	 exec(@strsql) 
	 
		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
		BEGIN   
			 Select @strsql = '' 
			 Select @strsql = @strsql + 'UPDATE  #FinalTarget SET ' + @ColName + ' = isnull(' + @ColName + ',0) - isNull(T2.PPDT ,0)  
			 FROM(  
			 SELECT F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.MONO,  
				SUM  
				(CASE  
				WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)  
				WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
				WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )  
				WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
				END ) as PPDT  
				FROM #T_autodata AutoData  
				CROSS jOIN #PlannedDownTimes T  
				INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID  
				INNER JOIN #FinalTarget F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn and F.MONO=Autodata.Workordernumber  
				inner join #Downcode on #Downcode.downid= downcodeinformation.downid		
				WHERE autodata.DataType=''2'' AND T.MachineInterface=autodata.mc AND #Downcode.Slno= ' + @i + '  
				 AND  
				 ((autodata.sttime >= F.BatchStart  AND autodata.ndtime <=F.BatchEnd)  
				 OR ( autodata.sttime < F.BatchStart  AND autodata.ndtime <= F.BatchEnd AND autodata.ndtime > F.BatchStart )  
				 OR ( autodata.sttime >= F.BatchStart   AND autodata.sttime <F.BatchEnd AND autodata.ndtime > F.BatchEnd )  
				 OR ( autodata.sttime < F.BatchStart  AND autodata.ndtime > F.BatchEnd))  
				 AND  
				 ((autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
				 OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
				 OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )  
				 OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )   
				 AND  
				 ((F.BatchStart >= T.StartTime  AND F.BatchEnd <=T.EndTime)  
				 OR ( F.BatchStart < T.StartTime  AND F.BatchEnd <= T.EndTime AND F.BatchEnd > T.StartTime )  
				 OR ( F.BatchStart >= T.StartTime   AND F.BatchStart <T.EndTime AND F.BatchEnd > T.EndTime )  
				 OR ( F.BatchStart < T.StartTime  AND F.BatchEnd > T.EndTime) )   
				 group  by F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.MONO  
			 )AS T2  Inner Join #FinalTarget on t2.machineinterface = #FinalTarget.machineinterface and  
			 t2.compinterface = #FinalTarget.compinterface and t2.opninterface = #FinalTarget.opninterface and  t2.MONO = #FinalTarget.MONO   
			 and t2.BatchStart=#FinalTarget.BatchStart and t2.BatchEnd=#FinalTarget.BatchEnd  '
			print @strsql
			exec(@Strsql)
		END

	select @i  =  @i + 1
End


Declare @CurStrtTime as datetime  
Declare @CurEndTime as datetime  
Select @CurStrtTime=@Starttime  
Select @CurEndTime=@Endtime  
  
  
while @CurStrtTime<=@CurEndTime  
BEGIN  
 INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)  
 EXEC s_GetShiftTime @CurStrtTime,'' 
 SELECT @CurStrtTime=DATEADD(DAY,1,@CurStrtTime)  
END  

 
Truncate Table #Target
Select @strsql=''   
Select @strsql= 'insert into #Target(Plantcode,MachineID,machineinterface,Component,Compinterface,Operation,Opninterface,Operator,Oprinterface, 
MONo,msttime,ndtime,Pdate,FromTm,Totm,Shift,batchid,autodataid,stdtime,StdSetupTime)'  
select @strsql = @strsql + ' SELECT P.PlantCode,machineinformation.machineid, machineinformation.interfaceid,componentinformation.componentid, componentinformation.interfaceid,  
componentoperationpricing.operationno, componentoperationpricing.interfaceid,E.Employeeid,E.interfaceid,MD.MONumber,  
Case when autodata.msttime< D.ShiftStart then D.ShiftStart else autodata.msttime end,   
Case when autodata.ndtime> D.ShiftEnd then D.ShiftEnd else autodata.ndtime end,  
D.Pdate,D.ShiftStart,D.ShiftEnd,D.Shift,0,autodata.id,componentoperationpricing.cycletime,componentoperationpricing.StdSetupTime FROM #T_autodata autodata  
INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID   
INNER JOIN componentinformation ON autodata.comp = componentinformation.InterfaceID    
INNER JOIN componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID  AND componentinformation.componentid = componentoperationpricing.componentid  
and componentoperationpricing.machineid=machineinformation.machineid   
inner join MoDetails MD on autodata.mc=MD.Machineinterface and autodata.workorderNumber=MD.MONumber
Left Outer Join downcodeinformation DI on DI.interfaceid=autodata.dcode  
Left Outer Join Employeeinformation E on E.interfaceid=autodata.opr
Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid  
inner join PlantInformation P on P.plantid=Plantmachine.plantid 
Cross join #ShiftDetails D
WHERE ((autodata.msttime >= D.ShiftStart  AND autodata.ndtime <= D.ShiftEnd)  
OR ( autodata.msttime < D.ShiftStart  AND autodata.ndtime <= D.ShiftEnd AND autodata.ndtime >D.ShiftStart )  
OR ( autodata.msttime >= D.ShiftStart AND autodata.msttime <D.ShiftEnd AND autodata.ndtime > D.ShiftEnd)  
OR ( autodata.msttime < D.ShiftStart AND autodata.ndtime > D.ShiftEnd))'  
select @strsql = @strsql + @strmachine + @strPlantID  
select @strsql = @strsql + ' order by autodata.msttime'  
print @strsql  
exec (@strsql)  


------ER0465 added from here
insert into #ShiftwiseFinalTarget (Plantcode,MachineID,Component,operation,machineinterface,Compinterface,Opninterface,MONO,BatchStart,BatchEnd,Pdate,FromTm,Totm,Shift,stdtime,Runtime,batchid)   
Select Plantcode,MachineID,Component,operation,machineinterface,Compinterface,Opninterface,MONO,min(msttime),max(ndtime),Pdate,FromTm,Totm,Shift,stdtime,0,batchid from
(
Select Plantcode,MachineID,Component,operation,machineinterface,Compinterface,Opninterface,MONO,msttime,ndtime,Pdate,FromTm,Totm,Shift,stdtime,
RANK() OVER (
  PARTITION BY t.machineid 
  order by t.machineid, t.msttime
) -
RANK() OVER (
  PARTITION BY t.machineid, t.Compinterface, t.OpnInterface, t.MONO , t.Fromtm 
  order by t.machineid, t.msttime
) AS batchid
from #Target t 
) tt group by Plantcode,MachineID,Component,operation,machineinterface,Compinterface,Opninterface,MONO,batchid,Pdate,FromTm,Totm,Shift,stdtime
order by tt.batchid
------ER0465 added till here

--Calculation of PartsCount Begins..  
UPDATE #ShiftwiseFinalTarget SET components = ISNULL(components,0) + ISNULL(t2.comp1,0)
From  
(  
 Select T1.mc,T1.comp,T1.opn,T1.WorkOrderNumber,T1.Batchstart,T1.Batchend,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp1 From
	(
	select mc,comp,opn,WorkOrderNumber,BatchStart,BatchEnd,SUM(autodata.partscount)AS OrginalCount from #T_autodata autodata  
	INNER JOIN #ShiftwiseFinalTarget F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn and F.MONO=Autodata.WorkOrderNumber  
	where (autodata.ndtime>F.BatchStart) and (autodata.ndtime<=F.BatchEnd) and (autodata.datatype=1)  
	Group By mc,comp,opn,WorkOrderNumber,BatchStart,BatchEnd
	) as T1  
 INNER JOIN #ShiftwiseFinalTarget F on F.machineinterface=T1.mc and F.Compinterface=T1.comp and F.Opninterface = T1.opn and F.MONO=T1.WorkOrderNumber  
 and F.Batchstart=T1.Batchstart and F.Batchend=T1.Batchend
 Inner join componentinformation C on F.Compinterface = C.interfaceid  
 Inner join ComponentOperationPricing O ON  F.Opninterface = O.interfaceid and C.Componentid=O.componentid  
 inner join machineinformation on machineinformation.machineid =O.machineid  
 and F.machineinterface=machineinformation.interfaceid  
 GROUP BY T1.mc,T1.comp,T1.opn,T1.WorkOrderNumber,T1.Batchstart,T1.Batchend  
) As T2 Inner Join #ShiftwiseFinalTarget on T2.mc = #ShiftwiseFinalTarget.machineinterface and  
T2.comp = #ShiftwiseFinalTarget.compinterface and T2.opn = #ShiftwiseFinalTarget.opninterface and  T2.WorkOrderNumber = #ShiftwiseFinalTarget.MONO   
and T2.BatchStart=#ShiftwiseFinalTarget.BatchStart and T2.BatchEnd=#ShiftwiseFinalTarget.BatchEnd  
  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
BEGIN  
    
 UPDATE #ShiftwiseFinalTarget SET components=ISNULL(components,0)- isnull(t2.PlanCt,0) FROM 
 ( 
 select autodata.mc,autodata.comp,autodata.opn,autodata.WorkOrderNumber,F.Batchstart,F.Batchend,
  ((CAST(Sum(ISNULL(PartsCount,1)) AS Float)/ISNULL(CO.SubOperations,1))) as PlanCt
   from #T_autodata autodata   
  INNER JOIN #ShiftwiseFinalTarget F on F.machineinterface=autodata.mc and F.Compinterface=autodata.comp and F.Opninterface = autodata.opn and F.MONO=autodata.WorkOrderNumber  
  Inner jOIN #PlannedDownTimes T on T.MachineInterface=autodata.mc    
  inner join machineinformation M on autodata.mc=M.Interfaceid  
  Inner join componentinformation CI on autodata.comp=CI.interfaceid   
  inner join componentoperationpricing CO on autodata.opn=CO.interfaceid and  
  CI.componentid=CO.componentid  and CO.machineid=M.machineid  
  WHERE autodata.DataType=1 and  
  (autodata.ndtime>F.BatchStart) and (autodata.ndtime<=F.BatchEnd)   
  AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)  
   Group by autodata.mc,autodata.comp,autodata.opn,autodata.WorkOrderNumber,F.Batchstart,F.Batchend,CO.SubOperations   
 ) as T2 Inner Join #ShiftwiseFinalTarget on T2.mc = #ShiftwiseFinalTarget.machineinterface and  
 T2.comp = #ShiftwiseFinalTarget.compinterface and T2.opn = #ShiftwiseFinalTarget.opninterface and  T2.WorkOrderNumber = #ShiftwiseFinalTarget.MONO   
 and T2.BatchStart=#ShiftwiseFinalTarget.BatchStart and T2.BatchEnd=#ShiftwiseFinalTarget.BatchEnd  
   
END

--Calculation of Stroke Begins..  
UPDATE #ShiftwiseFinalTarget SET [NoOfShotsPerShift] = ISNULL([NoOfShotsPerShift],0) + ISNULL(t2.comp1,0)
From  
(  
 Select T1.mc,T1.comp,T1.opn,T1.WorkOrderNumber,T1.Batchstart,T1.Batchend,SUM((CAST(O.PalletCount AS Float)/ISNULL(O.SubOperations,1))) As Comp1 From
	(
	select mc,comp,opn,WorkOrderNumber,BatchStart,BatchEnd from #T_autodata autodata  
	INNER JOIN #ShiftwiseFinalTarget F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn and F.MONO=Autodata.WorkOrderNumber  
	where (autodata.ndtime>F.BatchStart) and (autodata.ndtime<=F.BatchEnd) and (autodata.datatype=1)  
	Group By mc,comp,opn,WorkOrderNumber,BatchStart,BatchEnd
	) as T1  
 INNER JOIN #ShiftwiseFinalTarget F on F.machineinterface=T1.mc and F.Compinterface=T1.comp and F.Opninterface = T1.opn and F.MONO=T1.WorkOrderNumber  
 and F.Batchstart=T1.Batchstart and F.Batchend=T1.Batchend
 Inner join componentinformation C on F.Compinterface = C.interfaceid  
 Inner join ComponentOperationPricing O ON  F.Opninterface = O.interfaceid and C.Componentid=O.componentid  
 inner join machineinformation on machineinformation.machineid =O.machineid  
 and F.machineinterface=machineinformation.interfaceid  
 GROUP BY T1.mc,T1.comp,T1.opn,T1.WorkOrderNumber,T1.Batchstart,T1.Batchend  
) As T2 Inner Join #ShiftwiseFinalTarget on T2.mc = #ShiftwiseFinalTarget.machineinterface and  
T2.comp = #ShiftwiseFinalTarget.compinterface and T2.opn = #ShiftwiseFinalTarget.opninterface and  T2.WorkOrderNumber = #ShiftwiseFinalTarget.MONO   
and T2.BatchStart=#ShiftwiseFinalTarget.BatchStart and T2.BatchEnd=#ShiftwiseFinalTarget.BatchEnd  
  
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
BEGIN  
    
 UPDATE #ShiftwiseFinalTarget SET [NoOfShotsPerShift]=ISNULL([NoOfShotsPerShift],0)- isnull(t2.PlanCt,0) FROM 
 ( 
 select autodata.mc,autodata.comp,autodata.opn,autodata.WorkOrderNumber,F.Batchstart,F.Batchend,
  ((CAST(Sum(ISNULL(autodata.PartsCount,1)) AS Float)/ISNULL(CO.SubOperations,1))) as PlanCt
   from #T_autodata autodata   
  INNER JOIN #ShiftwiseFinalTarget F on F.machineinterface=autodata.mc and F.Compinterface=autodata.comp and F.Opninterface = autodata.opn and F.MONO=autodata.WorkOrderNumber  
  Inner jOIN #PlannedDownTimes T on T.MachineInterface=autodata.mc    
  inner join machineinformation M on autodata.mc=M.Interfaceid  
  Inner join componentinformation CI on autodata.comp=CI.interfaceid   
  inner join componentoperationpricing CO on autodata.opn=CO.interfaceid and  
  CI.componentid=CO.componentid  and CO.machineid=M.machineid  
  WHERE autodata.DataType=1 and  
  (autodata.ndtime>F.BatchStart) and (autodata.ndtime<=F.BatchEnd)   
  AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)  
   Group by autodata.mc,autodata.comp,autodata.opn,autodata.WorkOrderNumber,F.Batchstart,F.Batchend,CO.SubOperations   
 ) as T2 Inner Join #ShiftwiseFinalTarget on T2.mc = #ShiftwiseFinalTarget.machineinterface and  
 T2.comp = #ShiftwiseFinalTarget.compinterface and T2.opn = #ShiftwiseFinalTarget.opninterface and  T2.WorkOrderNumber = #ShiftwiseFinalTarget.MONO   
 and T2.BatchStart=#ShiftwiseFinalTarget.BatchStart and T2.BatchEnd=#ShiftwiseFinalTarget.BatchEnd  
   
END

--For Prodtime  
UPDATE #ShiftwiseFinalTarget SET Runtime = isnull(Runtime,0) + isNull(t2.cycle,0)  
from  
(select S.MachineID,S.Component,S.operation,S.MONO,S.BatchStart,S.BatchEnd,  
 sum(case when ((autodata.msttime>=S.BatchStart) and (autodata.ndtime<=S.BatchEnd)) then  (autodata.cycletime+autodata.loadunload)  
   when ((autodata.msttime<S.BatchStart)and (autodata.ndtime>S.BatchStart)and (autodata.ndtime<=S.BatchEnd)) then DateDiff(second, S.BatchStart, autodata.ndtime)  
   when ((autodata.msttime>=S.BatchStart)and (autodata.msttime<S.BatchEnd)and (autodata.ndtime>S.BatchEnd)) then DateDiff(second, autodata.mstTime, S.BatchEnd)  
   when ((autodata.msttime<S.BatchStart)and (autodata.ndtime>S.BatchEnd)) then DateDiff(second, S.BatchStart, S.BatchEnd) END ) as cycle  
from #T_autodata autodata   
inner join #ShiftwiseFinalTarget S on autodata.mc = S.Machineinterface and autodata.comp=S.Compinterface and autodata.opn=S.Opninterface and autodata.WorkOrderNumber = S.MONO  
where (autodata.datatype=1) AND(( (autodata.msttime>=S.BatchStart) and (autodata.ndtime<=S.BatchEnd))  
OR ((autodata.msttime<S.BatchStart)and (autodata.ndtime>S.BatchStart)and (autodata.ndtime<=S.BatchEnd))  
OR ((autodata.msttime>=S.BatchStart)and (autodata.msttime<S.BatchEnd)and (autodata.ndtime>S.BatchEnd))  
OR((autodata.msttime<S.BatchStart)and (autodata.ndtime>S.BatchEnd)))  
group by S.MachineID,S.Component,S.operation,S.MONO,S.BatchStart,S.BatchEnd  
) as t2 inner join #ShiftwiseFinalTarget on t2.MachineID = #ShiftwiseFinalTarget.MachineID and  t2.Component = #ShiftwiseFinalTarget.Component and   
t2.operation = #ShiftwiseFinalTarget.operation and t2.MONO = #ShiftwiseFinalTarget.MONO  
and t2.BatchStart=#ShiftwiseFinalTarget.BatchStart and t2.BatchEnd=#ShiftwiseFinalTarget.BatchEnd  


If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'  
BEGIN  
   
 --Get the utilised time overlapping with PDT and negate it from UtilisedTime  
  UPDATE  #ShiftwiseFinalTarget SET Runtime = isnull(Runtime,0) - isNull(T2.PPDT ,0)  
  FROM(  
  SELECT F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.MONO,  
     SUM  
     (CASE  
     WHEN autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN DateDiff(second,autodata.msttime,autodata.ndtime) --DR0325 Added  
     WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
     WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )  
     WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
     END ) as PPDT  
     FROM #T_autodata AutoData  
     CROSS jOIN #PlannedDownTimes T  
     INNER JOIN #ShiftwiseFinalTarget F on F.machineinterface=Autodata.mc and F.Compinterface=Autodata.comp and F.Opninterface = Autodata.opn and F.MONO=Autodata.WorkOrderNumber  
     WHERE autodata.DataType=1 AND T.MachineInterface=autodata.mc AND  
      ((autodata.msttime >= F.BatchStart  AND autodata.ndtime <=F.BatchEnd)  
      OR ( autodata.msttime < F.BatchStart  AND autodata.ndtime <= F.BatchEnd AND autodata.ndtime > F.BatchStart )  
      OR ( autodata.msttime >= F.BatchStart   AND autodata.msttime <F.BatchEnd AND autodata.ndtime > F.BatchEnd )  
      OR ( autodata.msttime < F.BatchStart  AND autodata.ndtime > F.BatchEnd))  
      AND  
      ((autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
      OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
      OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )  
      OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )   
      AND  
      ((F.BatchStart >= T.StartTime  AND F.BatchEnd <=T.EndTime)  
      OR ( F.BatchStart < T.StartTime  AND F.BatchEnd <= T.EndTime AND F.BatchEnd > T.StartTime )  
      OR ( F.BatchStart >= T.StartTime   AND F.BatchStart <T.EndTime AND F.BatchEnd > T.EndTime )  
      OR ( F.BatchStart < T.StartTime  AND F.BatchEnd > T.EndTime) )   
      group  by F.BatchStart,F.BatchEnd,F.machineinterface,F.Compinterface,F.Opninterface,F.MONO  
  )AS T2  Inner Join #ShiftwiseFinalTarget on t2.machineinterface = #ShiftwiseFinalTarget.machineinterface and  
  t2.compinterface = #ShiftwiseFinalTarget.compinterface and t2.opninterface = #ShiftwiseFinalTarget.opninterface and  t2.MONO = #ShiftwiseFinalTarget.MONO   
  and t2.BatchStart=#ShiftwiseFinalTarget.BatchStart and t2.BatchEnd=#ShiftwiseFinalTarget.BatchEnd  

 END


---------------------------------------- Getting EmployeeID and EmployeeName For Each Shift --------------------------------------
select T.machineinterface,T.Compinterface,T.OpnInterface,T.MONo,T.Oprinterface,T.operator,T.PDate,T.Shift,T.FromTm,T.ToTm,F.BatchStart,F.BatchEnd
into #opr from #Target T
INNER JOIN #ShiftwiseFinalTarget F on F.machineinterface=T.machineinterface and F.Compinterface=T.Compinterface and F.Opninterface = T.OpnInterface and F.MONO=T.MONo  
where 
((T.FromTm>=F.BatchStart and T.ToTm<=F.BatchEnd)
OR (T.FromTm<F.BatchStart and T.ToTm>F.BatchStart and T.ToTm<=F.BatchEnd)
OR (T.FromTm>=F.BatchStart and T.FromTm<F.BatchEnd and T.ToTm>F.BatchEnd)
OR (T.FromTm<F.BatchStart and T.ToTm>F.BatchEnd)) 
group by T.machineinterface,T.Compinterface,T.OpnInterface,T.MONo,T.Oprinterface,T.operator,T.PDate,T.Shift,T.FromTm,T.ToTm,F.BatchStart,F.BatchEnd

UPDATE #ShiftwiseFinalTarget SET operator = t2.opr 
from(
SELECT T.machineinterface,T.Compinterface,T.OpnInterface,T.MONo,T.PDate,T.Shift,T.BatchStart,T.BatchEnd,
		STUFF(ISNULL((SELECT ', ' + x.Operator
				FROM #opr x
				WHERE x.machineinterface = t.machineinterface and x.Compinterface = t.Compinterface and x.OpnInterface = t.OpnInterface and x.MONo = t.MONo
				 and x.PDate = t.PDate  and x.Shift = t.Shift and x.BatchStart = t.BatchStart and x.BatchEnd = t.BatchEnd
			GROUP BY x.Operator
				FOR XML PATH (''), TYPE).value('.','VARCHAR(max)'), ''), 1, 2, '') [opr]      
	FROM #opr t)
as t2 Inner Join #ShiftwiseFinalTarget on t2.machineinterface = #ShiftwiseFinalTarget.machineinterface and  
  t2.compinterface = #ShiftwiseFinalTarget.compinterface and t2.opninterface = #ShiftwiseFinalTarget.opninterface and  t2.MONO = #ShiftwiseFinalTarget.MONO   
  and t2.BatchStart=#ShiftwiseFinalTarget.BatchStart and t2.BatchEnd=#ShiftwiseFinalTarget.BatchEnd  

Update #FinalTarget set [1stshift operator] = isnull(T1.Operator,0) ,[1stshift Components]=isnull(T1.Components,0),
 [1stshift UT]=isnull(T1.Runtime,0),[NoOfShots 1stShift]=ISNULL([NoOfShots] ,0) from  
(Select S.machineinterface,S.Compinterface,S.OpnInterface,S.MONO,S.Pdate,S.Operator,SUM(IsNULL(S.Components,0)) as Components,SUM(ISNULL(S.Runtime,0)) as Runtime
,SUM(IsNULL(S.[NoOfShotsPerShift],0)) as [NoOfShots] from #ShiftwiseFinalTarget S  
inner join (select * from shiftdetails where shiftdetails.shiftid=1 and Running=1)shiftdetails on S.Shift=shiftdetails.ShiftName
inner join #FinalTarget F on F.machineinterface = S.Machineinterface and F.Compinterface=S.Compinterface and F.OpnInterface=S.Opninterface and F.MONO = S.MONO 
and Convert(nvarchar(10),S.PDate,120)=Convert(nvarchar(10),F.FromTm,120)  
group by S.machineinterface,S.Compinterface,S.OpnInterface,S.MONO,S.PDate,S.Operator)T1
inner join #FinalTarget S on T1.Machineinterface = S.Machineinterface and T1.Compinterface=S.Compinterface and T1.Opninterface=S.Opninterface  
and T1.MONO = S.MONO and Convert(nvarchar(10),T1.PDate,120)=Convert(nvarchar(10),FromTm,120) 

Update #FinalTarget set [2ndshift operator] = isnull(T1.Operator,0) ,[2ndshift Components]=isnull(T1.Components,0),
 [2ndshift UT]=isnull(T1.Runtime,0) ,[NoOfShots 2ndShift]=ISNULL([NoOfShots] ,0) from  
(Select S.machineinterface,S.Compinterface,S.OpnInterface,S.MONO,S.Pdate,S.Operator,SUM(IsNULL(S.Components,0)) as Components,SUM(ISNULL(S.Runtime,0)) as Runtime
,SUM(IsNULL(S.[NoOfShotsPerShift],0)) as [NoOfShots] from #ShiftwiseFinalTarget S  
inner join (select * from shiftdetails where shiftdetails.shiftid=2 and Running=1)shiftdetails on S.Shift=shiftdetails.ShiftName
inner join #FinalTarget F on F.machineinterface = S.Machineinterface and F.Compinterface=S.Compinterface and F.OpnInterface=S.Opninterface and F.MONO = S.MONO 
and Convert(nvarchar(10),S.PDate,120)=Convert(nvarchar(10),F.FromTm,120)  
group by S.machineinterface,S.Compinterface,S.OpnInterface,S.MONO,S.PDate,S.Operator)T1
inner join #FinalTarget S on T1.Machineinterface = S.Machineinterface and T1.Compinterface=S.Compinterface and T1.Opninterface=S.Opninterface  
and T1.MONO = S.MONO and Convert(nvarchar(10),T1.PDate,120)=Convert(nvarchar(10),FromTm,120) 


Update #FinalTarget set [3rdshift operator] = isnull(T1.Operator,0) ,[3rdshift Components]=isnull(T1.Components,0),
 [3rdshift UT]=isnull(T1.Runtime,0),[NoOfShots 3rdShift]=ISNULL([NoOfShots] ,0) from  
(Select S.machineinterface,S.Compinterface,S.OpnInterface,S.MONO,S.Pdate,S.Operator,SUM(IsNULL(S.Components,0)) as Components,SUM(ISNULL(S.Runtime,0)) as Runtime
,SUM(IsNULL(S.[NoOfShotsPerShift],0)) as [NoOfShots] from #ShiftwiseFinalTarget S  
inner join (select * from shiftdetails where shiftdetails.shiftid=3 and Running=1)shiftdetails on S.Shift=shiftdetails.ShiftName
inner join #FinalTarget F on F.machineinterface = S.Machineinterface and F.Compinterface=S.Compinterface and F.OpnInterface=S.Opninterface and F.MONO = S.MONO 
and Convert(nvarchar(10),S.PDate,120)=Convert(nvarchar(10),F.FromTm,120) 
group by S.machineinterface,S.Compinterface,S.OpnInterface,S.MONO,S.PDate,S.Operator)T1
inner join #FinalTarget S on T1.Machineinterface = S.Machineinterface and T1.Compinterface=S.Compinterface and T1.Opninterface=S.Opninterface  
and T1.MONO = S.MONO and Convert(nvarchar(10),T1.PDate,120)=Convert(nvarchar(10),FromTm,120) 

Select MONo,Component as PartNo,MOQuantity,MachineID,Convert(nvarchar(10),FromTm,120) as Pdate, 
RIGHT('0'+LTRIM(RIGHT(CONVERT(varchar,BatchStart,100),8)),7) + ' To ' + RIGHT('0'+LTRIM(RIGHT(CONVERT(varchar,BatchEnd,100),8)),7) as TimeTakenInActual,
Floor(dbo.f_FormatTime(ISNULL(Runtime,0),'hh')) as AvailableCapacity,Floor(dbo.f_FormatTime(ISNULL(Runtime,0)-ISNULL(ToolAndNMPDown,0),'hh')) as [TimeExcludingTCOAndNMP],
ISNULL(components,0) as [NoOfMoldedSeals],ISNULL(components,0)- ISNULL(RejQty,0) as [NoOfOKSeals],dbo.f_FormatTime(ISNULL(stdtime,0),'hh') as Cycletime,
dbo.f_FormatTime(ISNULL(StdSetupTime,0),'hh') as [SetuptimeBOM],
dbo.f_formattime(A,'hh') as A,dbo.f_formattime(B,'hh') as B,dbo.f_formattime(C,'hh') as C,dbo.f_formattime(D,'hh') as D,
dbo.f_formattime(E,'hh') as E,dbo.f_formattime(F,'hh') as F,dbo.f_formattime(G,'hh') as G,dbo.f_formattime(H,'hh') as H,dbo.f_formattime(I,'hh') as I,
dbo.f_formattime(J,'hh') as J,dbo.f_formattime(K,'hh') as K,dbo.f_formattime(L,'hh') as L,dbo.f_formattime(M,'hh') as M,
dbo.f_formattime(N,'hh') as N,dbo.f_formattime(O,'hh') as O,dbo.f_formattime(P,'hh') as P,
ISNULL([1stshift operator],'') as [1stshift operator],ISNULL([1stshift Components],0) as [1stshift Components],dbo.f_FormatTime(ISNULL([1stshift UT],0),'hh') as [1stshift UT],ISNULL([NoOfShots 1stShift],0) as [NoOfShots 1stShift],
ISNULL([2ndshift operator],'') as [2ndshift operator],ISNULL([2ndshift Components],0) as [2ndshift Components],dbo.f_FormatTime(ISNULL([2ndshift UT],0),'hh') as [2ndshift UT],ISNULL([NoOfShots 2ndShift],0) as [NoOfShots 2ndShift],
ISNULL([3rdshift operator],'') as [3rdshift operator],ISNULL([3rdshift Components],0) as [3rdshift Components],dbo.f_FormatTime(ISNULL([3rdshift UT],0),'hh') as [3rdshift UT],ISNULL([NoOfShots 3rdShift],0) as [NoOfShots 3rdShift],
0 as [NoofCavity]
from #FinalTarget order by MachineID,BatchStart

end
