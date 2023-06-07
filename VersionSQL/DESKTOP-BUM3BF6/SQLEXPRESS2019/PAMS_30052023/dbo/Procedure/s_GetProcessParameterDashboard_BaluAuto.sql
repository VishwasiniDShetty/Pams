/****** Object:  Procedure [dbo].[s_GetProcessParameterDashboard_BaluAuto]    Committed by VersionSQL https://www.versionsql.com ******/

  
/*************************************************************************************************** 
-- Author:		Anjana C V
-- Create date: 27 Nov 2019
-- Modified date: 27 Nov 2019
-- Description:  Get  Process Parameter Dashboard Data for Balu Auto 
exec [s_GetProcessParameterDashboard_BaluAuto] '2019-12-07 09:00:00','2019-05-10 18:00:00','CNC-22'
exec [s_GetProcessParameterDashboard_BaluAuto] '2019-12-07 09:00:00','','CNC-22'
exec [s_GetProcessParameterDashboard_BaluAuto] '','','CNC-22','DrillDown'
exec s_GetCockpitData_WithTempTable '2019-12-07 09:00:00','2019-05-10 18:00:00' 
****************************************************************************************************/  
CREATE PROCEDURE [dbo].[s_GetProcessParameterDashboard_BaluAuto]  
 @StartTime datetime ='',  
 @EndTime datetime ='',  
 @MachineID nvarchar(50) = '',
 @Param nvarchar(50)=''
 AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

Declare @strSql as nvarchar(4000)  
Declare @strMachine as nvarchar(255)
Declare @T_ST AS Datetime   
Declare @T_ED AS Datetime 
Declare @Type40Threshold int  
Declare @Type1Threshold int  
Declare @Type11Threshold int  
Declare @CurrTime as DateTime
declare @startdate as datetime  
declare @enddate as datetime  
declare @startdatetime nvarchar(20)  
declare @i as nvarchar(10)
declare @colStatus as nvarchar(50)
declare @colTS as nvarchar(50)

-- PEGreen,PERed,
CREATE TABLE #FinalTarget   
(  
	MachineID nvarchar(50),  
	MachineInterface nvarchar(50) PRIMARY KEY,  
	ProductionEfficiency float,  
	AvailabilityEfficiency float,  
	QualityEfficiency float, 
	OverallEfficiency float,  
	Components float,  
	RejCount float, 
	TotalTime float,  
	UtilisedTime float,  
	ManagementLoss float,  
	DownTime float,  
	CN float,  
	--Remarks nvarchar(100),  
	MCStatus nvarchar(50), 
	PlantID nvarchar(50), 
	--PEGreen smallint,  
	--PERed smallint,  
	--AEGreen smallint,  
	--AERed smallint,  
	OEGreen smallint,  
	OERed smallint,  
	--QEGreen smallint, 
	--QERed smallint, 
	DownReason nvarchar(50) DEFAULT ('') ,
	MLDown float ,
	ToolLifeStatus nvarchar(50),
	P1Status nvarchar(50),
	P2Status nvarchar(50),  
	P3Status nvarchar(50),  
	P4Status nvarchar(50),  
	P5Status nvarchar(50),  
	P6Status nvarchar(50),  
	P7Status nvarchar(50),  
	P8Status nvarchar(50),  
	P9Status nvarchar(50),  
	P10Status nvarchar(50),  
	--P11Status nvarchar(50),
	--P12Status nvarchar(50),
	--P13Status nvarchar(50),  
	--P14Status nvarchar(50),
	--P15Status nvarchar(50),
	ToolLifeTs DateTime,
	P1Ts DateTime,  
	P2Ts DateTime,  
	P3Ts DateTime,  
	P4Ts DateTime,  
	P5Ts DateTime,  
	P6Ts DateTime,  
	P7Ts DateTime,  
	P8Ts DateTime,  
	P9Ts DateTime,  
	P10Ts DateTime,
	--P11Ts DateTime,
	--P12Ts DateTime,
	--P13Ts DateTime,
	--P14Ts DateTime , 
	--P15Ts DateTime 
) 

Create table #PlannedDownTimes  
(  
	 MachineID nvarchar(50) NOT NULL,  
	 MachineInterface nvarchar(50) NOT NULL,  
	 StartTime DateTime NOT NULL,   
	 EndTime DateTime NOT NULL,
	 IgnoreCount bit default(0) 
)  

ALTER TABLE #PlannedDownTimes  
 ADD PRIMARY KEY CLUSTERED  
  (    [MachineInterface],  
	   [StartTime],  
	   [EndTime]  
        
  ) ON [PRIMARY]  
  
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

CREATE TABLE #MachineRunningStatus  
(  
	 MachineID NvarChar(50),  
	 MachineInterface nvarchar(50),  
	 sttime Datetime,  
	 ndtime Datetime,  
	 DataType smallint,  
	 ColorCode varchar(10),
	 DownReason nvarchar(50)  
)   

Create table #ProcessParameter
(
	Slno int identity(1,1) NOT NULL,
	Parameter nvarchar(100),
	ParameterName nvarchar(100) 
)

CREATE TABLE #ShiftDefn  
(  
	 ShiftDate datetime,    
	 Shiftname nvarchar(20),  
	 ShftSTtime datetime,  
	 ShftEndTime datetime,
	 Machineid nvarchar(50),
	 shiftid int --sv 
) 

create table #shift    
(    
	 ShiftDate nvarchar(10), 
	 shiftname nvarchar(20),    
	 Shiftstart datetime,    
	 Shiftend datetime,    
	 shiftid int,
	 Machineid nvarchar(50) 
)    

CREATE Table #ToolLife
(
MachineId nvarchar(50),
McInterfaceId nvarchar(50),
ComponetId nvarchar(50),
CompInterfaceId nvarchar(50),
ToolNumber nvarchar(50),
ToolDescription nvarchar(50),
target int,
Actual int,
Status nvarchar(50),
UpdatedTS nvarchar(50)
)

Select @strsql='' 
select @strMachine = ''

SET @strSql = 'INSERT INTO #FinalTarget (MachineID ,MachineInterface,ProductionEfficiency , AvailabilityEfficiency, QualityEfficiency,OverallEfficiency,  
				 Components , RejCount, TotalTime , UtilisedTime , ManagementLoss, DownTime , CN,--PEGreen ,PERed,AEGreen, AERed , 
				OEGreen ,  OERed, 
				--QERed, QEGreen, 
				MCStatus, PlantID ) '  
SET @strSql = @strSql + ' SELECT MachineInformation.MachineID, MachineInformation.interfaceid ,0,0,0,0,0,0,0,0,0,0,0,
						--PEGreen ,PERed,AEGreen ,AERed ,
						OEGreen ,OERed,
						--isnull(QERed,0),isnull(QEGreen,0),
						0,PlantID 
						FROM MachineInformation 
						LEFT OUTER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID 
						WHERE MachineInformation.interfaceid > ''0'' and MachineInformation.Devicetype=1 '  
SET @strSql =  @strSql + @strMachine 
print @strsql
EXEC(@strSql)  
--=======================================ToolLife data=======================================-- 

INSERT INTO #ToolLife (MachineId,McInterfaceId,ComponetId,CompInterfaceId,ToolNumber,ToolDescription,target,actual,Status,UpdatedTs)
SELECT DISTINCT F.Machineid,F.MachineInterface,A.CompInterfaceID,C.componentid,T.ToolNo,T.ToolDescription,A.tooltarget,A.ToolActual,
(CASE When isnull(A.tooltarget,0) = isnull(A.ToolActual,0) Then 'OK' 
	  WHEN isnull(A.tooltarget,0) <> isnull(A.ToolActual,0) THEN 'NOT OK' 
	  END ) Status,
Starttime
FROM #FinalTarget F
INNER JOIN AutodataDetails A ON A.Machine =  F.MachineInterface 
INNER JOIN componentinformation C ON C.InterfaceID = A.CompInterfaceID
INNER JOIN ToolSequence T ON T.MachineID = F.MachineId AND T.ComponentID = C.componentid And T.ToolNo = A.DetailNumber
WHERE A.CompInterfaceID = (SELECT CompInterfaceID from AutodataDetails Autodata 
							WHERE Starttime = ( SELECT Max(Starttime) FROM AutodataDetails AD Where AD.Machine = Autodata.Machine AND RecordType = 86) 
							AND Autodata.Machine = A.Machine
							AND RecordType = 86 )
AND RecordType = 86
------------------------------------------------------------------------------------------------------------------
IF @Param= 'DrillDown'
BEGIN

	SELECT *
	 FROM #ToolLife Where MachineId = @Machineid

END
------------------------------------------------------------------------------------------------------------------
ELSE
 BEGIN

	 SELECT @CurrTime = convert(nvarchar(20),getdate(),120)  
  
	 IF ISNULL(@EndTime,'') = ''
	 BEGIN 
	  SELECT @EndTime = getdate()
	 END 

	 select @startdate = dbo.f_GetLogicalDaystart(@StartTime)  
	 select @enddate = dbo.f_GetLogicalDaystart(@endtime)  

	 while @startdate<=@enddate    
	 Begin        
		 INSERT INTO #ShiftDefn(Machineid,ShiftDate,Shiftname,ShftSTtime,ShftEndTime,shiftid)    
		 EXEC [dbo].[s_getLastWorkingShift] @Machineid,'',@startdate,'Shift'  
  
		 Select @startdate = dateadd(d,1,@startdate)     
	 END  

	 Insert into #shift (Machineid,ShiftDate,shiftname,Shiftstart,Shiftend)   
	 select Machineid,convert(nvarchar(10),ShiftDate,126),shiftname,ShftSTtime,ShftEndTime 
	 from #ShiftDefn 
	 where ShftSTtime>=@StartTime and ShftEndTime<=@endtime 
    
	 Update #shift Set shiftid = isnull(#shift.Shiftid,0) + isnull(T1.shiftid,0) from    
			(Select SD.shiftid ,SD.shiftname from shiftdetails SD    
			inner join #shift S on SD.shiftname=S.shiftname where    
			running=1 )T1 inner join #shift on  T1.shiftname=#shift.shiftname   

	 Insert into #ProcessParameter(Parameter,ParameterName)
		Select P.ParameterID,P.DisplayHeader 
		from (--SELECT DISTINCT top 15 ParameterID,DisplayHeader,max(DisplayOrder) DisplayOrder
			  SELECT DISTINCT top 10 ParameterID,DisplayHeader,max(DisplayOrder) DisplayOrder
			  FROM ProcessParameterSettings_BaluAuto
			  where  DisplayOrder<=15 and ISNULL(DisplayOrder,0) <> 0 And Enabled = 1
			  And (Isnull(@MachineID,'') = '' or MachineID = @MachineID)
			  GROUP BY ParameterID,DisplayHeader 
			 ) P
		order by P.DisplayOrder
 
	select * from #ProcessParameter order by slno
    
	if isnull(@machineid,'')<> ''  
	begin  
	 SET @strMachine = ' AND MachineInformation.MachineID = N''' + @machineid + '''' 
	end  

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

	SET @strSql = ''  
	SET @strSql = 'Insert into #PlannedDownTimes  
	 SELECT Machine,InterfaceID,  
	  CASE When StartTime<''' + convert(nvarchar(20),@StartTime,120)+''' Then ''' + convert(nvarchar(20),@StartTime,120)+''' Else StartTime End As StartTime,  
	  CASE When EndTime>''' + convert(nvarchar(20),@EndTime,120)+''' Then ''' + convert(nvarchar(20),@EndTime,120)+''' Else EndTime End As EndTime  
	 ,IgnoreCount   --SV Added Column
	 FROM PlannedDownTimes inner join MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID  
	 WHERE PDTstatus =1 and(  
	 (StartTime >= ''' + convert(nvarchar(20),@StartTime,120)+''' AND EndTime <=''' + convert(nvarchar(20),@EndTime,120)+''')  
	 OR ( StartTime < ''' + convert(nvarchar(20),@StartTime,120)+'''  AND EndTime <= ''' + convert(nvarchar(20),@EndTime,120)+''' AND EndTime > ''' + convert(nvarchar(20),@StartTime,120)+''' )  
	 OR ( StartTime >= ''' + convert(nvarchar(20),@StartTime,120)+'''   AND StartTime <''' + convert(nvarchar(20),@EndTime,120)+''' AND EndTime > ''' + convert(nvarchar(20),@EndTime,120)+''' )  
	 OR ( StartTime < ''' + convert(nvarchar(20),@StartTime,120)+'''  AND EndTime > ''' + convert(nvarchar(20),@EndTime,120)+''')) '  
	SET @strSql =  @strSql + @strMachine + ' ORDER BY Machine,StartTime'  
	EXEC(@strSql)  


	Update #FinalTarget
	SET ToolLifeStatus = T.Toolstatus,
		ToolLifeTs = T.ToolTs
	FROM (
		Select Tl.MachineId, 
		(CASE WHEN 'NOT OK' IN (select Tlf.Status FROM #ToolLife Tlf where Tlf.MachineId = Tl.MachineId)
				 THEN 'NOT OK'
			  WHEN ('NOT OK' NOT IN (select Tlf.Status FROM #ToolLife Tlf where Tlf.MachineId = Tl.MachineId))
			   AND ('OK' IN  (select Tlf.Status FROM #ToolLife Tlf where Tlf.MachineId = Tl.MachineId) )
				 THEN 'Ok'
		END) Toolstatus,
		(CASE WHEN 'NOT OK' IN (select Tlf.Status FROM #ToolLife Tlf where Tlf.MachineId = Tl.MachineId)
				 THEN  (SELECT MAX(Tlf.UpdatedTs) from #ToolLife Tlf where Tlf.MachineId = Tl.MachineId AND Status = 'NOT OK') 
		END) ToolTs
		FROM #ToolLife Tl 
		)T INNER JOIN #FinalTarget F ON F.MachineID = T.MachineId

	--=======================================OEE Calculation=======================================-- 
	--Calculation of PartsCount Begins..  
	UPDATE #FinalTarget SET components = ISNULL(components,0) + ISNULL(t2.comp,0)  
	From  
	(  
		Select mc,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp  
		 From (select mc,SUM(autodata.partscount)AS OrginalCount,comp,opn   
	   from #T_autodata autodata 
		 where (autodata.ndtime>@StartTime) and (autodata.ndtime<=@EndTime) and (autodata.datatype=1)  
		 Group By mc,comp,opn) as T1  
	 Inner join componentinformation C on T1.Comp = C.interfaceid  
	 Inner join ComponentOperationPricing O ON  T1.Opn = O.interfaceid and C.Componentid=O.componentid  
	 inner join machineinformation on machineinformation.machineid =O.machineid  
	 and T1.mc=machineinformation.interfaceid   
	 GROUP BY mc  
	) As T2 Inner join #FinalTarget on T2.mc = #FinalTarget.machineinterface  
  
	--Mod 4 Apply PDT for calculation of Count  
	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
	BEGIN  
	 UPDATE #FinalTarget SET components = ISNULL(components,0) - ISNULL(T2.comp,0) from(  
	  select mc,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp From ( 
	   select mc,Sum(ISNULL(PartsCount,1))AS OrginalCount,comp,opn   
	   from #T_autodata autodata 
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
	 ) as T2 inner join #FinalTarget on T2.mc = #FinalTarget.machineinterface  
	END  

	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='N'  
	BEGIN  
	 UPDATE #FinalTarget SET components = ISNULL(components,0) - ISNULL(T2.comp,0) from(  
	  select mc,SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp From ( 
	   select mc,Sum(ISNULL(PartsCount,1))AS OrginalCount,comp,opn   
	   from #T_autodata autodata 
	   CROSS JOIN #PlannedDownTimes T  
	   WHERE autodata.DataType=1 And T.MachineInterface = autodata.mc  and T.IgnoreCount=1
	   AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)  
	   AND (autodata.ndtime > @StartTime  AND autodata.ndtime <=@EndTime)  
		  Group by mc,comp,opn  
	  ) as T1  
	 Inner join Machineinformation M on M.interfaceID = T1.mc  
	 Inner join componentinformation C on T1.Comp=C.interfaceid  
	 Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineID = M.MachineID  
	 GROUP BY MC  
	 ) as T2 inner join #FinalTarget on T2.mc = #FinalTarget.machineinterface  
	END  
	-------------------------------------UtilisedTime-------------------------------------
	--For Prodtime 

	UPDATE #FinalTarget SET Utilisedtime = isnull(Utilisedtime,0) + isNull(t2.cycle,0)  
	from  
	(select autodata.mc, 
	 sum(case when ((autodata.msttime>=@StartTime) and (autodata.ndtime<=@EndTime)) then  (autodata.cycletime+autodata.loadunload)  
	   when ((autodata.msttime<@StartTime)and (autodata.ndtime>@StartTime)and (autodata.ndtime<=@EndTime)) then DateDiff(second, @StartTime, autodata.ndtime)  
	   when ((autodata.msttime>=@StartTime)and (autodata.msttime<@EndTime)and (autodata.ndtime>@EndTime)) then DateDiff(second, autodata.mstTime, @EndTime)  
	   when ((autodata.msttime<@StartTime)and (autodata.ndtime>@EndTime)) then DateDiff(second, @StartTime, @EndTime) END ) as cycle  
	from #T_autodata autodata   
	where (autodata.datatype=1) AND(( (autodata.msttime>=@StartTime) and (autodata.ndtime<=@EndTime))  
	OR ((autodata.msttime<@StartTime)and (autodata.ndtime>@StartTime)and (autodata.ndtime<=@EndTime))  
	OR ((autodata.msttime>=@StartTime)and (autodata.msttime<@EndTime)and (autodata.ndtime>@EndTime))  
	OR((autodata.msttime<@StartTime)and (autodata.ndtime>@EndTime)))  
	group by autodata.mc
	) as t2 inner join #FinalTarget on t2.mc = #FinalTarget.MachineInterface 


	/* Fetching Down Records from Production Cycle  */  
	/* If Down Records of TYPE-2*/  
	UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)  
	FROM  
	(Select AutoData.mc ,  
	SUM(  
	CASE  
	 When autodata.sttime <= @StartTime Then datediff(s, @StartTime,autodata.ndtime )  
	 When autodata.sttime > @StartTime Then datediff(s , autodata.sttime,autodata.ndtime)  
	END) as Down  
	From #T_autodata AutoData INNER Join
	 (Select mc,Sttime,NdTime From #T_autodata AutoData  
	  Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And  
	  (msttime < @StartTime)And (ndtime > @StartTime) AND (ndtime <= @EndTime)) as T1  
	ON AutoData.mc=T1.mc  
	Where AutoData.DataType=2  
	And ( autodata.Sttime > T1.Sttime )  
	And ( autodata.ndtime <  T1.ndtime )  
	AND ( autodata.ndtime >  @StartTime )  
	GROUP BY AUTODATA.mc)AS T2 Inner Join #FinalTarget on t2.mc = #FinalTarget.machineinterface  

	/* If Down Records of TYPE-3*/  
	UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)  
	FROM  
	(Select AutoData.mc ,  
	SUM(CASE  
	 When autodata.ndtime > @EndTime Then datediff(s,autodata.sttime, @EndTime )  
	 When autodata.ndtime <=@EndTime Then datediff(s , autodata.sttime,autodata.ndtime)  
	END) as Down   
	From #T_autodata AutoData INNER Join 
	 (Select mc,Sttime,NdTime From #T_autodata AutoData  
	  Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And  
	  (sttime >= @StartTime)And (ndtime > @EndTime) and (sttime<@EndTime) ) as T1  
	ON AutoData.mc=T1.mc  
	Where AutoData.DataType=2  
	And (T1.Sttime < autodata.sttime  )  
	And ( T1.ndtime >  autodata.ndtime)  
	AND (autodata.sttime  <  @EndTime)  
	GROUP BY AUTODATA.mc)AS T2 Inner Join #FinalTarget on t2.mc = #FinalTarget.machineinterface  

	/* If Down Records of TYPE-4*/  
	UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)  
	FROM  
	(Select AutoData.mc ,  
	SUM(CASE  
	 When autodata.sttime >= @StartTime AND autodata.ndtime <= @EndTime Then datediff(s , autodata.sttime,autodata.ndtime)  
	 When autodata.sttime < @StartTime AND autodata.ndtime > @StartTime AND autodata.ndtime<=@EndTime Then datediff(s, @StartTime,autodata.ndtime )  
	 When autodata.sttime>=@StartTime And autodata.sttime < @EndTime AND autodata.ndtime > @EndTime Then datediff(s,autodata.sttime, @EndTime )  
	 When autodata.sttime<@StartTime AND autodata.ndtime>@EndTime   Then datediff(s , @StartTime,@EndTime)  
	END) as Down  
	From #T_autodata AutoData INNER Join 
	 (Select mc,Sttime,NdTime From #T_autodata AutoData  
	  Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And  
	  (msttime < @StartTime)And (ndtime > @EndTime) ) as T1  
	ON AutoData.mc=T1.mc  
	Where AutoData.DataType=2  
	And (T1.Sttime < autodata.sttime  )  
	And ( T1.ndtime >  autodata.ndtime)  
	AND (autodata.ndtime  >  @StartTime)  
	AND (autodata.sttime  <  @EndTime)  
	GROUP BY AUTODATA.mc  
	)AS T2 Inner Join #FinalTarget on t2.mc = #FinalTarget.machineinterface  

	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
	BEGIN
	
		--get the utilised time overlapping with PDT and negate it from UtilisedTime
		UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.PlanDT,0)
		from
		( 
			select  T.Machineid as machine,
			sum (CASE 
			WHEN (autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN DateDiff(second,autodata.msttime,autodata.ndtime) 
			WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )
			WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PlanDT
			from #T_autodata autodata CROSS jOIN #PlannedDownTimes T 
			WHERE autodata.DataType=1   and T.MachineInterface=autodata.mc AND(
			(autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime)
		)
		group by T.Machineid  ) as t2 inner join #FinalTarget S on   t2.machine=S.machineId
	

	---Add ICD's Overlapping  with PDT to UtilisedTime---
	/* Fetching Down Records from Production Cycle  */
	---Handle intearction between ICD and PDT for type 1 production record for the selected time period.---
			UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)
			FROM	(
			Select  AutoData.mc,
			SUM(
			CASE 	
				When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
				When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
				When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
				when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
			END) as IPDT
			from #T_autodata autodata INNER Join  
				(Select mc,Sttime,NdTime from #T_autodata autodata inner join #FinalTarget S on S.MachineInterface=autodata.mc
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
					(msttime >= @StartTime) AND (ndtime <= @EndTime)) as T1
			ON AutoData.mc=T1.mc CROSS jOIN #PlannedDownTimes T
			Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc
			And (( autodata.Sttime >= T1.Sttime )  
			And ( autodata.ndtime <= T1.ndtime )  
			)
			AND
			((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
			or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
			or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
			or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )
			GROUP BY AUTODATA.mc 
			)AS T2  INNER JOIN #FinalTarget ON
		T2.mc = #FinalTarget.MachineInterface   

		/* If production  Records of TYPE-2*/
		UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)
		FROM
		(Select  AutoData.mc ,
		SUM(
		CASE 	
			When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
			When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
			When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
			when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		from #T_autodata autodata CROSS jOIN #PlannedDownTimes T INNER Join  
			(Select mc,Sttime,NdTime,@StartTime as StartTime from #T_autodata autodata inner join #FinalTarget S on S.MachineInterface=autodata.mc
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(msttime < @StartTime)And (ndtime > @StartTime) AND (ndtime <= @EndTime)) as T1
		ON AutoData.mc=T1.mc 
		Where AutoData.DataType=2  and T.MachineInterface=autodata.mc
		And (( autodata.Sttime > T1.Sttime )
		And ( autodata.ndtime <  T1.ndtime )
		AND ( autodata.ndtime >  T1.StartTime ))
		AND
		(( T.StartTime >= T1.StartTime )
		And ( T.StartTime <  T1.ndtime ) )
		GROUP BY AUTODATA.mc  )AS T2  INNER JOIN #FinalTarget ON
		T2.mc = #FinalTarget.MachineInterface  

	

		/* If production Records of TYPE-3*/
		UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)
		FROM
		(Select  AutoData.mc ,
		SUM(
		CASE 	
			When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
			When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
			When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
			when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		from #T_autodata autodata CROSS jOIN #PlannedDownTimes T INNER Join 
			(Select mc,Sttime,NdTime,@StartTime as StartTime,@EndTime as EndTime from #T_autodata autodata inner join #FinalTarget S on S.MachineInterface=autodata.mc
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(sttime >= @StartTime)And (ndtime > @EndTime) and autodata.sttime <@EndTime) as T1
		ON AutoData.mc=T1.mc  
		Where AutoData.DataType=2  and T.MachineInterface=autodata.mc
		And ((T1.Sttime < autodata.sttime  )
		And ( T1.ndtime >  autodata.ndtime)
		AND (autodata.sttime  <  T1.EndTime))
		AND
		(( T.EndTime > T1.Sttime )
		And ( T.EndTime <=T1.EndTime ) )
		GROUP BY AUTODATA.mc )AS T2   INNER JOIN #FinalTarget ON
		T2.mc = #FinalTarget.MachineInterface  

		/* If production Records of TYPE-4*/
		UPDATE  #FinalTarget SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)
		FROM
		(Select  AutoData.mc ,
		SUM(
		CASE 	
			When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
			When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
			When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
			when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		from #T_autodata autodata CROSS jOIN #PlannedDownTimes T INNER Join
			(Select mc,Sttime,NdTime,@StartTime as StartTime,@EndTime as EndTime from #T_autodata autodata inner join #FinalTarget S on S.MachineInterface=autodata.mc
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(msttime < @StartTime)And (ndtime > @EndTime)) as T1
		ON AutoData.mc=T1.mc 
		Where AutoData.DataType=2 and T.MachineInterface=autodata.mc
		And ( (T1.Sttime < autodata.sttime  )
			And ( T1.ndtime >  autodata.ndtime)
			AND (autodata.ndtime  >  T1.StartTime)
			AND (autodata.sttime  <  T1.EndTime))
		AND
		(( T.StartTime >=T1.StartTime)
		And ( T.EndTime <=T1.EndTime ) )
		GROUP BY AUTODATA.mc
		)AS T2  INNER JOIN #FinalTarget ON
		T2.mc = #FinalTarget.MachineInterface  
	
	END
	--========================================== Down Record ========================================== --
	--============================= ManagementLoss and Downtime Calculation Starts ========================== --  

	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y')  
	BEGIN  
	  -- Type 1  
	  UPDATE #FinalTarget SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)  
	  from  
	  (select mc,sum(  
	  CASE  
	  WHEN (loadunload) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0  
	  THEN isnull(downcodeinformation.Threshold,0)  
	  ELSE loadunload  
	  END) AS LOSS  
	  from #T_autodata autodata 
	  INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid  
	  where (autodata.msttime>=@StartTime)  
	  and (autodata.ndtime<=@EndTime)  
	  and (autodata.datatype=2)  
	  and (downcodeinformation.availeffy = 1)   
	  and (downcodeinformation.ThresholdfromCO <>1)  
	  group by autodata.mc) as t2 inner join #FinalTarget on t2.mc = #FinalTarget.machineinterface  
	  -- Type 2  
	  UPDATE #FinalTarget SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)  
	  from  
	  (select      mc,sum(  
	  CASE WHEN DateDiff(second, @StartTime, ndtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0  
	  then isnull(downcodeinformation.Threshold,0)  
	  ELSE DateDiff(second, @StartTime, ndtime)  
	  END)loss  
	  from #T_autodata autodata    
	  INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid  
	  where (autodata.sttime<@StartTime)  
	  and (autodata.ndtime>@StartTime)  
	  and (autodata.ndtime<=@EndTime)  
	  and (autodata.datatype=2)  
	  and (downcodeinformation.availeffy = 1)  
	  and (downcodeinformation.ThresholdfromCO <>1)  
	  group by autodata.mc  
	  ) as t2 inner join #FinalTarget on t2.mc = #FinalTarget.machineinterface  
	  -- Type 3  
	  UPDATE #FinalTarget SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)  
	  from  
	  (select mc,SUM(  
	  CASE WHEN DateDiff(second,stTime, @Endtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0  
	  then isnull(downcodeinformation.Threshold,0)  
	  ELSE DateDiff(second, stTime, @Endtime)  
	  END)loss   
	  from #T_autodata autodata  
	  INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid  
	  where (autodata.msttime>=@StartTime)  
	  and (autodata.sttime<@EndTime)  
	  and (autodata.ndtime>@EndTime)  
	  and (autodata.datatype=2)  
	  and (downcodeinformation.availeffy = 1)  
	  and (downcodeinformation.ThresholdfromCO <>1)  
	  group by autodata.mc  
	  ) as t2 inner join #FinalTarget on t2.mc = #FinalTarget.machineinterface  
	  -- Type 4  
	  UPDATE #FinalTarget SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)  
	  from  
	  (select mc,sum(  
	  CASE WHEN DateDiff(second, @StartTime, @Endtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0  
	  then isnull(downcodeinformation.Threshold,0)  
	  ELSE DateDiff(second, @StartTime, @Endtime)  
	  END)loss   
	  from #T_autodata autodata
	  INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid  
	  where autodata.msttime<@StartTime  
	  and autodata.ndtime>@EndTime  
	  and (autodata.datatype=2)  
	  and (downcodeinformation.availeffy = 1)  
	  and (downcodeinformation.ThresholdfromCO <>1)  
	  group by autodata.mc  
	  ) as t2 inner join #FinalTarget on t2.mc = #FinalTarget.machineinterface  
	  ---get the downtime for the time period  
	  UPDATE #FinalTarget SET downtime = isnull(downtime,0) + isNull(t2.down,0)  
	  from  
	  (select mc,sum(  
		CASE  
		WHEN  autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime  THEN  loadunload  
		WHEN (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  THEN DateDiff(second, @StartTime, ndtime)  
		WHEN (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)  THEN DateDiff(second, stTime, @Endtime)  
		WHEN autodata.msttime<@StartTime and autodata.ndtime>@EndTime   THEN DateDiff(second, @StartTime, @EndTime)  
		END  
	   )AS down  
	  from #T_autodata autodata  
	  inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid  
	  where autodata.datatype=2 AND  
	  (  
	  (autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)  
	  OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  
	  OR (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)  
	  OR (autodata.msttime<@StartTime and autodata.ndtime>@EndTime )  
	  )  
	  group by autodata.mc  
	  ) as t2 inner join #FinalTarget on t2.mc = #FinalTarget.machineinterface  

	End  
 
	--- Handling interaction between PDT and downtime . Also interaction between PDT and Management Loss  
	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'  
	BEGIN  

	 UPDATE #FinalTarget SET downtime = isnull(downtime,0) + isNull(t2.down,0)  
	 from  
	 (select mc,sum(  
	   CASE  
			 WHEN  autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime  THEN  loadunload  
	   WHEN (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  THEN DateDiff(second, @StartTime, ndtime)  
	   WHEN (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)  THEN DateDiff(second, stTime, @Endtime)  
	   WHEN autodata.msttime<@StartTime and autodata.ndtime>@EndTime   THEN DateDiff(second, @StartTime, @EndTime)  
	   END  
	  )AS down  
	 from #T_autodata autodata  
	 inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid  
	 where autodata.datatype=2 AND  
	 (  
	 (autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)  
	 OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  
	 OR (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)  
	 OR (autodata.msttime<@StartTime and autodata.ndtime>@EndTime )  
	 ) AND (downcodeinformation.availeffy = 0)  
	 group by autodata.mc  
	 ) as t2 inner join #FinalTarget on t2.mc = #FinalTarget.machineinterface  

	 UPDATE #FinalTarget SET downtime = isnull(downtime,0) - isNull(t2.PldDown,0)
		from(
			select  T.Machineid as machine,SUM
				   (CASE
				WHEN (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN autodata.loadunload
				WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
				WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
				WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
				END ) as PldDown
			from #T_autodata autodata  
			CROSS jOIN #PlannedDownTimes T
			INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID
			WHERE autodata.DataType=2  and T.MachineInterface=autodata.mc  AND(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)
			AND (downcodeinformation.availeffy = 0)
			group by T.Machineid  ) as t2 inner join #FinalTarget S on  t2.machine=S.machineId

   
	 UPDATE #FinalTarget SET  ManagementLoss = isnull(ManagementLoss,0) + isNull(t4.Mloss,0),MLDown=isNull(MLDown,0)+isNull(t4.Dloss,0)  
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
	  ) AND (D.availeffy = 1)     
	  and (D.ThresholdfromCO <>1)) as T1    
	 left outer join  
	 (SELECT autodata.id,  
			 sum(CASE  
	   WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)  
	   WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)  
	   WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )  
	   WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )  
	   END ) as PPDT  
	  FROM #T_autodata AutoData  
	  CROSS jOIN #PlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid  
	  WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND  
	   (  
	   (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  
	   OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )  
	   OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )  
	   OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  
	   )   
	   AND (downcodeinformation.availeffy = 1)   
	   AND (downcodeinformation.ThresholdfromCO <>1) 
	   group  by autodata.id ) as T2 on T1.id=T2.id ) as T3  group by T3.mc  
	 ) as t4 inner join #FinalTarget on t4.mc = #FinalTarget.machineinterface  
    
	 UPDATE #FinalTarget SET downtime = isnull(downtime,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)  
	END  
	--====================================================================================--   
	 if (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y'
		begin
		
			UPDATE #FinalTarget SET downtime = isnull(downtime,0) - isNull(t2.PldDown,0)
			from(
			select T.MachineID as machine,SUM
				   (CASE
				WHEN (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN autodata.loadunload
				WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
				WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
				WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
				END ) as PldDown
			from #T_autodata autodata CROSS jOIN #PlannedDownTimes T --ER0324 Added
			INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID
			WHERE autodata.DataType=2  and T.MachineInterface=autodata.mc  AND(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)
			AND DownCodeInformation.DownID=(SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')
			group by T.MachineID) as t2 inner join #FinalTarget S on  t2.machine=S.machineId
	
		end  
	--========================================== CN ========================================== --
	print '----cn----' 
	UPDATE #FinalTarget SET CN = isnull(CN,0) + isNull(t2.C1N1,0)  
	from  
	(select mc,  
	SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))* autodata.partscount) C1N1   
	FROM #T_autodata autodata 
	INNER JOIN  
	componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN  
	componentinformation ON autodata.comp = componentinformation.InterfaceID AND  
	componentoperationpricing.componentid = componentinformation.componentid  
	inner join machineinformation on machineinformation.interfaceid=autodata.mc  
	and componentoperationpricing.machineid=machineinformation.machineid   
	where (((autodata.sttime>=@StartTime)and (autodata.ndtime<=@EndTime)) or  
	((autodata.sttime<@StartTime)and (autodata.ndtime>@StartTime)and (autodata.ndtime<=@EndTime)) )  
	and (autodata.datatype=1)  
	group by autodata.mc  
	) as t2 inner join #FinalTarget on t2.mc = #FinalTarget.machineinterface  

	--- Ignore count from CN calculation which is over lapping with PDT  
	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
	BEGIN  
	 UPDATE #FinalTarget SET CN = isnull(CN,0) - isNull(t2.C1N1,0)  
	 From  
	 (  
	  select mc,SUM((O.cycletime * ISNULL(A.PartsCount,1))/ISNULL(O.SubOperations,1))  C1N1  
	  From #T_autodata A  
	  Inner join machineinformation M on M.interfaceid=A.mc  
	  Inner join componentinformation C ON A.Comp=C.interfaceid  
	  Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID  
	  Cross jOIN #PlannedDownTimes T  
	  WHERE A.DataType=1 AND T.MachineInterface=A.mc  
	  AND(A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)  
	  AND(A.ndtime > @StartTime  AND A.ndtime <=@EndTime)  
	  Group by mc  
	 ) as T2  
	 inner join #FinalTarget  on t2.mc = #FinalTarget.machineinterface  
	END  
	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='N'  
	BEGIN  
	 UPDATE #FinalTarget SET CN = isnull(CN,0) - isNull(t2.C1N1,0)  
	 From  
	 (  
	  select mc,SUM((O.cycletime * ISNULL(A.PartsCount,1))/ISNULL(O.SubOperations,1))  C1N1  
	  From #T_autodata A  
	  Inner join machineinformation M on M.interfaceid=A.mc  
	  Inner join componentinformation C ON A.Comp=C.interfaceid  
	  Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID  
	  Cross jOIN #PlannedDownTimes T  
	  WHERE A.DataType=1 AND T.MachineInterface=A.mc  and T.IgnoreCount=1
	  AND(A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)  
	  AND(A.ndtime > @StartTime  AND A.ndtime <=@EndTime)  
	  Group by mc  
	 ) as T2  
	 inner join #FinalTarget  on t2.mc = #FinalTarget.machineinterface  
	END 

	--====================================Calculate efficiencies====================================--   
	Update #FinalTarget set RejCount = isnull(RejCount,0) + isnull(T1.RejQty,0)  
	From  
	( Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A  
	inner join Machineinformation M on A.mc=M.interfaceid  
	inner join #FinalTarget on #FinalTarget.machineid=M.machineid   
	inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid  
	where A.CreatedTS>=@StartTime and A.CreatedTS<@Endtime and A.flag = 'Rejection'  
	and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000'  
	group by A.mc,M.Machineid  
	)T1 inner join #FinalTarget B on B.Machineid=T1.Machineid   
  
	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
	BEGIN  
	 Update #FinalTarget set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from  
	 (Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A  
	 inner join Machineinformation M on A.mc=M.interfaceid  
	 inner join #FinalTarget on #FinalTarget.machineid=M.machineid   
	 inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid  
	 Cross join Planneddowntimes P  
	 where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid   
	 and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000' and  
	 A.CreatedTS>=@StartTime and A.CreatedTS<@Endtime And  
	 A.CreatedTS>=P.Starttime and A.CreatedTS<P.endtime  
	 group by A.mc,M.Machineid)T1 inner join #FinalTarget B on B.Machineid=T1.Machineid   
	END  
 
	---SV
	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='N'  
	BEGIN  
	 Update #FinalTarget set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from  
	 (Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A  
	 inner join Machineinformation M on A.mc=M.interfaceid  
	 inner join #FinalTarget on #FinalTarget.machineid=M.machineid   
	 inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid  
	 Cross join Planneddowntimes P  
	 where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid  and P.IgnoreCount=1   
	 and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000' and  
	 A.CreatedTS>=@StartTime and A.CreatedTS<@Endtime And  
	 A.CreatedTS>=P.Starttime and A.CreatedTS<P.endtime  
	 group by A.mc,M.Machineid)T1 inner join #FinalTarget B on B.Machineid=T1.Machineid   
	END  
	---SV 

	Update #FinalTarget set RejCount = isnull(RejCount,0) + isnull(T1.RejQty,0)  
	From  
	( Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A  
	inner join Machineinformation M on A.mc=M.interfaceid  
	inner join #FinalTarget on #FinalTarget.machineid=M.machineid   
	inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid  
	inner join #shift S on convert(nvarchar(10),(A.RejDate),126)=S.shiftdate and A.RejShift=S.shiftid --DR0333  
	where A.flag = 'Rejection' and A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (S.shiftdate) and  --DR0333  
	Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'  
	group by A.mc,M.Machineid  
	)T1 inner join #FinalTarget B on B.Machineid=T1.Machineid   
  
	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'  
	BEGIN  
	 Update #FinalTarget set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from  
	 (Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A  
	 inner join Machineinformation M on A.mc=M.interfaceid  
	 inner join #FinalTarget on #FinalTarget.machineid=M.machineid   
	 inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid  
	 inner join #shift S on convert(nvarchar(10),(A.RejDate),126)=S.shiftdate and A.RejShift=S.shiftid --DR0333  
	 Cross join Planneddowntimes P  
	 where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid and  
	 A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (S.shiftdate) and --DR0333  
	 Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'  
	 and P.starttime>=S.Shiftstart and P.Endtime<=S.shiftend  
	 group by A.mc,M.Machineid)T1 inner join #FinalTarget B on B.Machineid=T1.Machineid   
	END  

	---SV
	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='N'  
	BEGIN  
	 Update #FinalTarget set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from  
	 (Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A  
	 inner join Machineinformation M on A.mc=M.interfaceid  
	 inner join #FinalTarget on #FinalTarget.machineid=M.machineid   
	 inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid  
	 inner join #shift S on convert(nvarchar(10),(A.RejDate),126)=S.shiftdate and A.RejShift=S.shiftid --DR0333  
	 Cross join Planneddowntimes P  
	 where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid and  P.IgnoreCount=1 AND
	 A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (S.shiftdate) and --DR0333  
	 Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'  
	 and P.starttime>=S.Shiftstart and P.Endtime<=S.shiftend  
	 group by A.mc,M.Machineid)T1 inner join #FinalTarget B on B.Machineid=T1.Machineid   
	END
	--SV
  
	UPDATE #FinalTarget SET QualityEfficiency= ISNULL(QualityEfficiency,0) + IsNull(T1.QE,0)   
	FROM(Select MachineID,  
	CAST((Sum(Components))As Float)/CAST((Sum(IsNull(Components,0))+Sum(IsNull(RejCount,0))) AS Float)As QE  
	From #FinalTarget Where Components<>0 Group By MachineID  
	)AS T1 Inner Join #FinalTarget ON  #FinalTarget.MachineID=T1.MachineID   
	--====================================Calculate efficiencies====================================--  
	UPDATE #FinalTarget  
	SET  
	 ProductionEfficiency = (ISNULL(CN,0)/UtilisedTime) ,  
	 AvailabilityEfficiency = (ISNULL(UtilisedTime,0))/(ISNULL(UtilisedTime,0) + ISNULL(DownTime,0) - ISNULL(ManagementLoss,0)),  
	 TotalTime = DateDiff(second, @StartTime, @EndTime)
	WHERE ISNULL(UtilisedTime,0) <> 0  

	--==========================================OEE==========================================-- 
	UPDATE #FinalTarget  
	SET  OverAllEfficiency = (ProductionEfficiency * AvailabilityEfficiency )*100
	--===============================================Running Status===============================================-- 

	select @Type40Threshold =0  
	select @Type1Threshold = 0  
	select @Type11Threshold = 0  
  
	select @Type40Threshold = (Select isnull(Valueintext2,5)*60 from shopdefaults where parameter='ANDONStatusThreshold' and valueintext = 'Type40Threshold')  
	select @Type1Threshold = (Select isnull(Valueintext2,5)*60 from shopdefaults where parameter='ANDONStatusThreshold' and valueintext = 'Type1Threshold')  
	select @Type11Threshold = (Select isnull(Valueintext2,5)*60 from shopdefaults where parameter='ANDONStatusThreshold' and valueintext = 'Type11Threshold')  

	-- select * from MachineRunningStatus

	Insert into #machineRunningStatus (MachineID,MachineInterface,sttime,ndtime,DataType,ColorCode)
	select fd.MachineID,fd.MachineInterface,sttime,ndtime,datatype,ColorCode 
	from MachineRunningStatus mr    
	right outer join #FinalTarget fd on fd.MachineInterface = mr.MachineInterface
	--where sttime<@currtime and isnull(ndtime,'1900-01-01')<@currtime
	order by fd.MachineInterface

	 ------------using MachineRunningStatus table instead of rawdata Till Here------------  
	update #machineRunningStatus set ColorCode = case when (datediff(second,sttime,@CurrTime)- @Type11Threshold)>0  then 'Red' else 'Green' end where datatype in (11)  
	update #machineRunningStatus set ColorCode = 'Green' where datatype in (41)  
	update #machineRunningStatus set ColorCode = 'Red' where datatype in (42,2)  
  
	update #machineRunningStatus set ColorCode = t1.ColorCode from (  
	Select mrs.MachineID,Case when (  
	case when datatype = 40 then datediff(second,sttime,@CurrTime)- @Type40Threshold  
	when datatype = 1 then datediff(second,ndtime,@CurrTime)- @Type1Threshold  
	end) > 0 then 'Red' else 'Green' end as ColorCode  
	from #machineRunningStatus mrs   
	where  datatype in (40,1)  
	) as t1 inner join #machineRunningStatus on t1.MachineID = #machineRunningStatus.MachineID  
  
	update #machineRunningStatus set ColorCode ='Red' where isnull(sttime,'1900-01-01')='1900-01-01'  

	update #machineRunningStatus
	SET  DownReason = T. DownReason   
	FROM 
		(
		select fd.MachineID,fd.MachineInterface,
		(case when datatype in ('2','22') then d.downid  else '' end) as DownReason
		from rawdata 
		inner join (    select mc,max(slno) as slno 
						from rawdata WITH (NOLOCK)   
						where (Rawdata.sttime>=@StartTime and Rawdata.sttime<=@EndTime) 
						--and datatype in (2,11,41,42,40,22)
						and datatype in (2,22)
						group by mc
					) t1  on t1.mc=rawdata.mc and t1.slno=rawdata.slno   
		right outer join (select distinct machineid,MachineInterface from #FinalTarget) fd on fd.MachineInterface = rawdata.mc  
		left join downcodeinformation d on d.interfaceid = RawData.SPLSTRING2
		where sttime<@EndTime and isnull(ndtime,'1900-01-01') < @EndTime
		--and datatype in (1,2,11,41,42,40,22)
		and datatype in (2,22)
		)T 
	INNER JOIN #machineRunningStatus ON t.MachineID = #machineRunningStatus.MachineID 
  
	update #FinalTarget set MCStatus = T1.MCStatus , DownReason = T1.DownReason
	from   
		(select Machineid,  
		Case when Colorcode='White' then 'Stopped'  
		when Colorcode='Red' then 'Stopped'  
		when Colorcode='Green' then 'Running' end as MCStatus,
		DownReason 
		from #machineRunningStatus
		)T1  
	inner join #FinalTarget on T1.MachineID = #FinalTarget.MachineID   

	--===============================================Process Parameter===============================================-- 
	Select @i=1

	--while @i <=15
	while @i <=10
	Begin
		Select @colStatus = Case when @i=1 then 'P1Status'
								 when @i=2 then 'P2Status'
								 when @i=3 then 'P3Status'
								 when @i=4 then 'P4Status'
								 when @i=5 then 'P5Status'
								 when @i=6 then 'P6Status'
								 when @i=7 then 'P7Status'
								 when @i=8 then 'P8Status'
								 when @i=9 then 'P9Status'
								 when @i=10 then 'P10Status'
								 --when @i=11 then 'P11Status'
								 --when @i=12 then 'P12Status'
								 --when @i=13 then 'P13Status'
								 --when @i=14 then 'P14Status'
								 --when @i=15 then 'P15Status'
							 END

		Select @colTS = Case when @i=1 then 'P1Ts'
								 when @i=2 then 'P2Ts'
								 when @i=3 then 'P3Ts'
								 when @i=4 then 'P4Ts'
								 when @i=5 then 'P5Ts'
								 when @i=6 then 'P6Ts'
								 when @i=7 then 'P7Ts'
								 when @i=8 then 'P8Ts'
								 when @i=9 then 'P9Ts'
								 when @i=10 then 'P10Ts'
								 --when @i=11 then 'P11Ts'
								 --when @i=12 then 'P12Ts'
								 --when @i=13 then 'P13Ts'
								 --when @i=14 then 'P14Ts'
								 --when @i=15 then 'P15Ts'
							 END

	 Select @strsql = ''
		 Select @strsql = @strsql + ' UPDATE #FinalTarget SET ' + @colStatus + ' =  T.Status
		 from  
		 (
		 select F.MachineID , T.Value as Status
			from ProcessParameterSettings_BaluAuto S
			inner join ProcessParameterTransaction_BaluAuto T On S.MachineID = T.MachineID AND S.ParameterID = T.ParameterID
			INNER JOIN #ProcessParameter P ON P.Parameter = T.ParameterID
			INNER JOIN #FinalTarget F On F.MachineID = T.MachineID
			Where UpdatedTS = (select max(UpdatedTS) FROM ProcessParameterTransaction_BaluAuto PT where PT.MachineID = T.MachineID AND PT.ParameterID = T.ParameterID)
			AND P.Slno = ' + @i + '  
		 )T INNER JOIN #FinalTarget F ON F.MachineId = T.machineId ' 

		 print @strsql
		 exec(@strsql) 

	 Select @strsql = ''
		 Select @strsql = @strsql + ' UPDATE #FinalTarget SET ' + @colTS + ' = T.UpdatedTS
		  from  
		 (
		 select F.MachineID , T.UpdatedTS as UpdatedTS
			from ProcessParameterSettings_BaluAuto S
			inner join ProcessParameterTransaction_BaluAuto T On S.MachineID = T.MachineID AND S.ParameterID = T.ParameterID
			INNER JOIN #ProcessParameter P ON P.Parameter = T.ParameterID
			INNER JOIN #FinalTarget F On F.MachineID = T.MachineID
			Where UpdatedTS = (select max(UpdatedTS) FROM ProcessParameterTransaction_BaluAuto PT where PT.MachineID = T.MachineID AND PT.ParameterID = T.ParameterID)
			AND P.Slno = ' + @i + '  
			AND T.Value = ''Not OK''
		 )T INNER JOIN #FinalTarget F ON F.MachineId = T.machineId ' 

		 print @strsql
		 exec(@strsql) 

	 select @i  =  @i + 1
	End


	--==============================================================================================-- 

	select MachineID,OverallEfficiency, Components,MCStatus,DownReason,
	OEGreen,OERed,
	ToolLifeStatus,P1Status,P2Status,P3Status,P4Status,P5Status,P6Status,P7Status,P8Status ,P9Status,P10Status,
	--P11Status,P12Status,P13Status,P14Status,P15Status,
	ToolLifeTs,P1Ts,P2Ts,P3Ts,P4Ts,P5Ts,P6Ts,P7Ts,P8Ts,P9Ts,P10Ts 
	--P11Ts,P12Ts,P13Ts,P14Ts,P15Ts
	from #FinalTarget
END
END
