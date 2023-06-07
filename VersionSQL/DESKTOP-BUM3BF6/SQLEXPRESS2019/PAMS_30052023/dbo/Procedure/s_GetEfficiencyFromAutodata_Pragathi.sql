/****** Object:  Procedure [dbo].[s_GetEfficiencyFromAutodata_Pragathi]    Committed by VersionSQL https://www.versionsql.com ******/

/********************************************************************************************************
This procedure is being used in the following places
1) Clickble graphs in cockpit (last 3,6,9,12 months)
2) ANALYSIS REPORT STANDARD/PRODUCTION REPORT MACHINEWISE/Shift Basis/Format - III
report file name = SM_ShiftProduction_Format3_TEMPLATE.xls
3) ANALYSIS REPORT STANDARD/comparision report/Time-Axis='Hour' Or  'Shift' Or  'Day' Or  'Month'
Compare='Available Efficeiency' or 'Production Efficiency' or 'Overall Effieciency'
report files :1) SM_EffiComparisonreport.rpt
		 2) SM_EffiComparisonreport_FORMAT_II.rpt
Procedure Altered By SSK on 06-Dec-2006:
	To Remove Constraint Name and adding it by Primary Key
Altered by Mrudula to get Hour,day,shift, and monthwise calculations
Procedure Changed By Sangeeta Kallur on 21-FEB-2007
	Bz of change in Column Names of ShiftProduction Details ie Date to pDate
Procedure Changed By Sangeeta Kallur on 28-FEB-2007.
	To Change Count and CN calculation : For Multispindle type of machines [MAINI Request.]
mod 1 :- ER0181 By Kusuma M.H on 16-May-2009.2) Modify all the procedures accordingly. Qualify machine wherever we are making use of component and opeartion no.
mod 2 :- ER0182 By Kusuma M.H on 16-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
mod 3 :- DR0207	By Kusuma M.H on 03-Sep-09.In the proc 's_GetEfficiencyFromAutodata' Isnull function is used for OE Column.
mod 4 :-By Mrudula M. Rao on 15-feb-2009.ER0210 Introduce PDT on 5150.
	1) Handle PDT at Machine Level.
	2) Handle interaction between PDT and Mangement Loss. Also handle interaction InCycleDown And PDT.
	3) Improve the performance.
	4) Handle intearction between ICD and PDT for type 1 production record for the selected time period.
	5)optimization
mod 6:- For DR0236 altered by karthick R on 24-06-2010  Use proper conditions in case statements to remove icd's from type 4 production records.
NR0111 - Vasavi - 12/Mar/2015 :: Calculation of Avg AE,PE,OE and Target OEE for Day and Shift.
DR0360 - Vasavi - 18/Mar/2015 ::Calculating Avg AE,PE,OE with respect to PDT.
*******************************************************************************************************/
--[s_GetEfficiencyFromAutodata_Pragathi] '2019-07-08','2019-07-08','','','','Shift','','Console','1'
--[s_GetEfficiencyFromAutodata_Pragathi] '2019-03-21','2019-03-23','','','','Day','','Console','0'

CREATE            PROCEDURE [dbo].[s_GetEfficiencyFromAutodata_Pragathi]
	@StartTime datetime ,
	@EndTime datetime ,
	@MachineID nvarchar(MAX) = '',
	@GroupID NVARCHAR(MAX)='',
	@PlantID nvarchar(50)='',
	@ComparisonParam as nvarchar(20),
	@TimeAxis as nvarchar(20), --'Month','Day','Shift','Hour'
	@ShiftName as nvarchar(20)='',
	@Type as NVarchar(20)='Console',--'Console','Cockpit',we need different output based on the requirement.
	@daywise as nvarchar(20)=''
AS
BEGIN
CREATE TABLE #Exceptions
(
	MachineID NVarChar(50),
	ComponentID Nvarchar(50),
	OperationNo Int,
	StartTime DateTime,
	EndTime DateTime,
	IdealCount Int,
	ActualCount Int,
	ExCount Int DEFAULT 0
	---mod 4(5)
	,DurStart datetime
	,DurEnd datetime
	---mod 4(5)
)
CREATE TABLE #MCO_pCounts
(
	StTime DateTime,
	MachineID NVarChar(50), 
	machineDescription NVarChar(150), 
	ComponentID Nvarchar(50),
	OperationNo Int,
	pCount Int DEFAULT 0,
	CycleTime Int
	
)
Create Table #ShiftHour
	(
		HDate datetime,
		Temshift nvarchar(50),
		Frmt datetime,
		Endt datetime,
	)
Create Table #ShiftTemp
	(
		PDate datetime,
		ShiftName nvarchar(20) null,
		FromTime datetime,
		ToTime Datetime
	)
CREATE TABLE #CockPitData (
	Pdt datetime,
	Strttm datetime,
	ndtim datetime,
	shftnm nvarchar(50),
	ShiftID int,
	MachineID nvarchar(50),
	MachineInterface nvarchar(50), 
	machineDescription NVarChar(150), 
	ProductionEfficiency float,
	AvailabilityEfficiency float,
	OverallEfficiency float,
	QualityEfficiency float default 0, --Vas
	RejCount float default 0, --vasavi
	Components float,
	UtilisedTime float,
	ManagementLoss float,
	DownTime float,
	CN float,
	Rejection float
	--mod 4
	,MLDown float
	--mod 4
,AvgProductionEfficiency float DEFAULT 0 -- DR0360 Added 
,AvgAvailabilityEfficiency float DEFAULT 0  -- DR0360 Added
,AvgQualityEfficiency float DEFAULT 0
,AvgOverallEfficiency float DEFAULT 0, -- DR0360 Added
TargetOEE float DEFAULT 0 -- DR0360 Added
)
---mod 4
CREATE TABLE #PlannedDownTimesEffi
	(
		SlNo int not null identity(1,1),
		Starttime datetime,
		EndTime datetime,
		DownReason nvarchar(50),
		Machine nvarchar(50),
		MInterface nvarchar(50),
		machineDescription NVarChar(150), 
		DStart datetime,
		Dend datetime
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
 id  bigint not null  
)  
  
ALTER TABLE #T_autodata  
  
ADD PRIMARY KEY CLUSTERED  
(  
 mc,sttime,ndtime,msttime ASC  
)ON [PRIMARY]  

---mod 4
Declare @strSql as nvarchar(MAX)
Declare @strMachine as nvarchar(MAX)
Declare @Counter as datetime
Declare @EndCount as datetime
Declare @CurShiftSt as datetime
Declare @Curshiftnd as datetime
Declare @curendtime   as datetime
Declare @CurShift as nvarchar(50)
Declare @CurHourDate as datetime
Declare @Incstrt as datetime
DEclare @IncEnd as datetime
declare @Endtm as datetime
declare @CurStarttime as datetime
declare @shifttemp as nvarchar(50)
Declare @strPlantID as nvarchar(4000)
Declare @strXMachine nvarchar(MAX)
declare @StrMCJoined as nvarchar(max)
declare @StrGroupJoined as nvarchar(max)
declare @strGroupID as nvarchar(max)

SET @strXMachine =''
SET @strMachine = ''
SET @strPlantID = ''
SET @strGroupID=''

Declare @StrTPMMachines AS nvarchar(500) 
SELECT @StrTPMMachines=''


select @counter=convert(datetime, cast(DATEPART(yyyy,@StartTime)as nvarchar(4))+'-'+cast(datepart(mm,@StartTime)as nvarchar(2))+'-'+cast(datepart(dd,@StartTime)as nvarchar(2)) +' 00:00:00.000')

IF ( SELECT TOP 1 ValueInText FROM  CockpitDefaults WHERE Parameter='TpmEnbMac')='E'  
BEGIN  
 SET  @StrTPMMachines = ' AND MachineInformation.TPMTrakEnabled = 1 '  
END  
ELSE  
BEGIN  
 SET  @StrTPMMachines = ' '  
END 

if isnull(@machineid,'')<> ''
begin
	select @StrMCJoined =  (case when (coalesce( +@StrMCJoined + ',''', '''')) = ''''  then 'N''' else @StrMCJoined+',N''' end) +item+'''' from [SplitStrings](@MachineID, ',')    
	if @StrMCJoined = 'N'''''  
	set @StrMCJoined = '' 
	select @MachineID = @StrMCJoined

	SET @strMachine = ' AND MachineInformation.MachineID IN (' + @machineid + ')'
	SET @strXMachine = ' AND EX.MachineID IN (' + @machineid + ')'
	---mod 2
end
if isnull(@PlantID,'')<> ''
Begin
	---mod 2
--	SET @strPlantID =  ' AND PlantMachine.PlantID = ''' + @PlantID + ''''
	SET @strPlantID =  ' AND PlantMachine.PlantID = N''' + @PlantID + ''''
	---mod 2
End

if isnull(@GroupID,'')<> ''
Begin
	select @StrGroupJoined =  (case when (coalesce( +@StrGroupJoined + ',''', '''')) = ''''  then 'N''' else @StrGroupJoined+',N''' end) +item+'''' from [SplitStrings](@GroupID, ',')    
	if @StrGroupJoined = 'N'''''  
	set @StrGroupJoined = '' 
	select @GroupID = @StrGroupJoined

	SET @strGroupID = ' AND PlantMachineGroups.GroupID in (' + @GroupID +')'
End

  
--Select @strsql=''  
--select @strsql ='insert into #T_autodata '  
--select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'  
-- select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'  
--select @strsql = @strsql + ' from autodata where (( sttime >='''+ convert(nvarchar(25),@StartTime,120)+''' and ndtime <= '''+ convert(nvarchar(25),@EndTime,120)+''' ) OR '  
--select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@StartTime,120)+''' and ndtime >'''+ convert(nvarchar(25),@EndTime,120)+''' )OR '  
--select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@StartTime,120)+''' and ndtime >'''+ convert(nvarchar(25),@StartTime,120)+'''  
--     and ndtime<='''+convert(nvarchar(25),@EndTime,120)+''' )'  
--select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@StartTime,120)+''' and ndtime >'''+ convert(nvarchar(25),@EndTime,120)+''' and sttime<'''+convert(nvarchar(25),@EndTime,120)+''' ) )'  
--print @strsql  
--exec (@strsql)  

if @TimeAxis='Hour'
begin
	Insert into #ShiftHour(HDate,TemShift, Frmt, Endt)
	Exec s_GetShiftTime @counter,@ShiftName
	
	DECLARE EffishiftCursor  Cursor  For
		SELECT Hdate,TemShift,Frmt,Endt From #ShiftHour
		Open EffishiftCursor
		FETCH NExt From EffishiftCursor into @CurHourDate,@CurShift,@CurShiftSt,@Curshiftnd
		While(@@Fetch_Status=0)
		BEGIN
			select @Incstrt=@CurShiftSt
			While(@Incstrt<@Curshiftnd)
			begin
				SELECT @IncEnd=DATEADD(Second,3600,@Incstrt)
					if @IncEnd >= @Curshiftnd
					Begin
						set @IncEnd = @Curshiftnd
					end
				Insert into #ShiftTemp(PDate,ShiftName, FromTime, ToTime)
				select @CurHourDate,@CurShift,@Incstrt,@IncEnd
				
				select @Incstrt=dateadd(second,3600,@Incstrt)
			end
			FETCH NExt From EffishiftCursor into  @CurHourDate,@CurShift,@CurShiftSt,@Curshiftnd
		END
	
END
if @TimeAxis='shift'
begin
	Delete from #ShiftTemp
		While(@counter <= @EndTime)
		BEGIN
			Insert into #ShiftTemp(PDate,ShiftName, FromTime, ToTime)
			Exec s_GetShiftTime @counter,@ShiftName
			SELECT @counter = Dateadd(Day,1,@counter)
		END
end
if @TimeAxis='Day'
begin
	Delete from #ShiftTemp
	While(@counter <= @EndTime)
	begin
		insert into #ShiftTemp(Pdate,ShiftName,FromTime,ToTime)
		select @Counter,'ALL',dbo.f_GetLogicalDay(@Counter,'start'),dbo.f_GetLogicalDay(@Counter,'end')
		SELECT @counter = Dateadd(Day,1,@counter)
	end
end
if @TimeAxis='Month'
begin
	Delete from #ShiftTemp
	While(@counter <= @EndTime)
	begin
		insert into #ShiftTemp(Pdate,ShiftName,FromTime,ToTime)
		select @Counter,'ALL',dbo.f_GetLogicalMonth(@Counter,'start'),dbo.f_GetLogicalMonth(@Counter,'end')
		SELECT @counter = Dateadd(Month,1,@counter)
	end
end

Declare @T_Start AS Datetime   
Declare @T_End AS Datetime  

Select @T_Start=Min(FromTime) from #ShiftTemp 
Select @T_End=max(ToTime) from #ShiftTemp  

  
Select @strsql=''  
select @strsql ='insert into #T_autodata '  
select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'  
 select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'  
select @strsql = @strsql + ' from autodata where (( sttime >='''+ convert(nvarchar(25),@T_Start,120)+''' and ndtime <= '''+ convert(nvarchar(25),@T_End,120)+''' ) OR '  
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_Start,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_End,120)+''' )OR '  
select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@T_Start,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_Start,120)+'''  
     and ndtime<='''+convert(nvarchar(25),@T_End,120)+''' )'  
select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@T_Start,120)+''' and ndtime >'''+ convert(nvarchar(25),@T_End,120)+''' and sttime<'''+convert(nvarchar(25),@T_End,120)+''' ) )'  
print @strsql  
exec (@strsql)  


---mod 4(5):Optimization
SET @strSql = 'INSERT INTO #CockpitData (
			Pdt,
			Strttm,
			ndtim,
			shftnm,
			MachineID ,
			MachineInterface,
			machineDescription,
			ProductionEfficiency ,
			AvailabilityEfficiency ,
			OverallEfficiency ,
			QualityEfficiency,
			Components ,
			UtilisedTime ,	
			ManagementLoss,
			DownTime ,
			CN,
			Rejection
					) '
			SET @strSql = @strSql + ' SELECT S.Pdate,S.FromTime,S.ToTime,S.ShiftName,MachineInformation.MachineID, MachineInformation.interfaceid ,Machineinformation.Description,
						  0,0,0,0,0,0,0,0,0,0 FROM MachineInformation
						  INNER JOIN PlantMachine ON machineinformation.machineid = PlantMachine.MachineID
						   LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID
						  cross join #ShiftTemp S whERE MachineInformation.interfaceid > ''0''  '
			SET @strSql = @strSql + @strPlantID + @strMachine + @StrTPMMachines + @strGroupID
			EXEC(@strSql)

		
---utilised time
-- Type 1
UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
from
(select     #CockpitData.Strttm as intime, mc,
sum(case when ( (autodata.msttime>= #CockpitData.Strttm) and (autodata.ndtime<=#CockpitData.ndtim)) then  (cycletime+loadunload)
		 when ((autodata.msttime< #CockpitData.Strttm)and (autodata.ndtime> #CockpitData.Strttm)and (autodata.ndtime<=#CockpitData.ndtim)) then DateDiff(second,  #CockpitData.Strttm, ndtime)
		 when ((autodata.msttime>= #CockpitData.Strttm)and (autodata.msttime<#CockpitData.ndtim)and (autodata.ndtime>#CockpitData.ndtim)) then DateDiff(second, mstTime, #CockpitData.ndtim)
		 when ((autodata.msttime< #CockpitData.Strttm)and (autodata.ndtime>#CockpitData.ndtim)) then DateDiff(second,  #CockpitData.Strttm, #CockpitData.ndtim) END ) as  cycle
from #T_autodata autodata inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface
where (autodata.datatype=1)
AND(( (autodata.msttime>=#CockpitData.Strttm) and (autodata.ndtime<=#CockpitData.ndtim))
OR ((autodata.msttime<#CockpitData.Strttm)and (autodata.ndtime>#CockpitData.Strttm)and (autodata.ndtime<=#CockpitData.ndtim))
OR ((autodata.msttime>=#CockpitData.Strttm)and (autodata.msttime<#CockpitData.ndtim)and (autodata.ndtime>#CockpitData.ndtim))
OR((autodata.msttime<#CockpitData.Strttm)and (autodata.ndtime>#CockpitData.ndtim))
)
group by autodata.mc,#CockpitData.Strttm
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
---mod 4 : Get PDT
insert into #PlannedDownTimesEffi(StartTime,EndTime,DownReason,Machine,MInterface,
		DStart ,
		Dend )  select
	CASE When StartTime<#CockpitData.Strttm Then #CockpitData.Strttm Else StartTime End,
	case When EndTime>#CockpitData.ndtim Then #CockpitData.ndtim Else EndTime End,DownReason,
	PlannedDownTimes.Machine,#CockpitData.machineinterface,#CockpitData.Strttm,#CockpitData.ndtim
	FROM PlannedDownTimes inner join #CockpitData on #CockpitData.MachineID=PlannedDownTimes.Machine
	WHERE pdtstatus=1 and (
	(StartTime >= #CockpitData.Strttm  AND EndTime <=#CockpitData.ndtim)
	OR ( StartTime < #CockpitData.Strttm  AND EndTime <= #CockpitData.ndtim AND EndTime > #CockpitData.Strttm )
	OR ( StartTime >= #CockpitData.Strttm   AND StartTime <#CockpitData.ndtim AND EndTime > #CockpitData.ndtim )
	OR ( StartTime < #CockpitData.Strttm  AND EndTime > #CockpitData.ndtim) )
	ORDER BY StartTime
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
BEGIN
	UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0)- isNull(t2.Pdown,0)
	FROM(
		--Production Time in PDT
		SELECT T.Dstart,autodata.MC,SUM
			(CASE
			WHEN autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.cycletime+autodata.loadunload)
			WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )
			WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END)  as Pdown
		FROM #T_autodata autodata inner jOIN #PlannedDownTimesEffi T on T.MInterface=autodata.mc
		WHERE autodata.DataType=1 AND
			(
			(autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )			
		group by autodata.mc,T.Dstart
	)as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.Dstart=#CockpitData.Strttm
	
	
	 ---mod 1 Handling interaction between PDT and ICD
	/* If production  Records of TYPE-1*/
	UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0)+ isNull(t2.IPDT,0)
	FROM( Select T.Dstart,AutoData.mc ,
	SUM(
	CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  AND  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT
	From #T_autodata  autodata INNER Join (Select mc,Sttime,NdTime,#CockpitData.Strttm as DurStrt,#CockpitData.ndtim as DurEnd
	 From #T_autodata  autodata inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(msttime >=#CockpitData.Strttm) AND (ndtime <= #CockpitData.ndtim)
	) as T1 ON AutoData.mc=T1.mc inner jOIN #PlannedDownTimesEffi T on
	 T.Minterface=autodata.mc and T1.DurStrt=T.Dstart
	Where AutoData.DataType=2
	And (( autodata.Sttime >= T1.Sttime )
	And ( autodata.ndtime <=  T1.ndtime ))
	AND
	((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
	or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
	or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
	or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )
	group by autodata.mc,T.Dstart
	)as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.Dstart=#CockpitData.Strttm
	
		
	/* If production  Records of TYPE-2*/
	UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0)+ isNull(t2.IPDT,0)
	FROM
	(Select T.Dstart,AutoData.mc ,
	SUM(
	CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  AND  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT
	From #T_autodata  autodata INNER Join
		(Select mc,Sttime,NdTime,#CockpitData.Strttm as DurStrt,#CockpitData.ndtim as DurEnd
	 From  #T_autodata autodata inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(msttime < #CockpitData.Strttm)And (ndtime > #CockpitData.Strttm) AND (ndtime <= #CockpitData.ndtim))
	 as T1
	ON AutoData.mc=T1.mc inner jOIN #PlannedDownTimesEffi T on
	 T.Minterface=autodata.mc and T1.DurStrt=T.Dstart
	Where AutoData.DataType=2
	And (( autodata.Sttime > T1.Sttime )
	And ( autodata.ndtime <  T1.ndtime )
	AND ( autodata.ndtime >  T.Dstart ))
	AND
	(( T.StartTime >= T.Dstart )
	And ( T.StartTime <  T1.ndtime ) )
	GROUP BY AUTODATA.mc,T.Dstart )as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.Dstart=#CockpitData.Strttm
	
	
	/* If production Records of TYPE-3*/
	UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0)+ isNull(t2.IPDT,0)
	FROM
	(Select T.Dstart,AutoData.mc ,
	SUM(
	CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT
	From  #T_autodata autodata INNER Join
		(Select mc,Sttime,NdTime,#CockpitData.Strttm as DurStrt,#CockpitData.ndtim as DurEnd From #T_autodata autodata
		 inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(sttime >= #CockpitData.Strttm)And (ndtime > #CockpitData.ndtim) and sttime<#CockpitData.ndtim) as T1
	ON AutoData.mc=T1.mc inner jOIN #PlannedDownTimesEffi T on
	 T.Minterface=autodata.mc and T1.DurStrt=T.Dstart
	Where AutoData.DataType=2
	And ((T1.Sttime < autodata.sttime  )
	And ( T1.ndtime >  autodata.ndtime)
	AND (autodata.sttime  <  T.Dend))
	AND
	(( T.EndTime > T1.Sttime )
	And ( T.EndTime <=T.Dend ) )
	GROUP BY AUTODATA.mc,T.Dstart)as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.Dstart=#CockpitData.Strttm
	
	
	/* If production Records of TYPE-4*/
	UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0)+ isNull(t2.IPDT,0)
	FROM
	(Select T.Dstart,AutoData.mc ,
	SUM(
	CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT
	From #T_autodata autodata INNER Join
		(Select mc,Sttime,NdTime,#CockpitData.Strttm as DurStrt,#CockpitData.ndtim as DurEnd  From #T_autodata autodata
		inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(msttime < #CockpitData.Strttm)And (ndtime > #CockpitData.ndtim)) as T1
	ON AutoData.mc=T1.mc inner jOIN #PlannedDownTimesEffi T on
	 T.Minterface=autodata.mc and T1.DurStrt=T.Dstart
	Where AutoData.DataType=2
	And ( (T1.Sttime < autodata.sttime  )
		And ( T1.ndtime >  autodata.ndtime)
		AND (autodata.ndtime  >  T.Dstart)
		AND (autodata.sttime  <  T.DEnd))
	AND
	(( T.StartTime >=T.Dstart)
	And ( T.EndTime <=T.DEnd ) )
	GROUP BY AUTODATA.mc,T.Dstart)as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.Dstart=#CockpitData.Strttm
END

UPDATE  #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
FROM
(Select T1.DurStrt as intime,AutoData.mc ,
SUM(
CASE
	When autodata.sttime <= T1.DurStrt Then datediff(s, T1.DurStrt,autodata.ndtime )
	When autodata.sttime > T1.DurStrt Then datediff(s , autodata.sttime,autodata.ndtime)
END)  as Down
From #T_autodata autodata INNER Join
	(Select mc,Sttime,NdTime,#CockpitData.Strttm as DurStrt,#CockpitData.ndtim as DurEnd
	 From #T_autodata autodata inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(msttime < #CockpitData.Strttm)And (ndtime > #CockpitData.Strttm) AND (ndtime <= #CockpitData.ndtim)) as T1
ON AutoData.mc=T1.mc
Where AutoData.DataType=2
And ( autodata.Sttime > T1.Sttime )
And ( autodata.ndtime <  T1.ndtime )
AND ( autodata.ndtime >  T1.DurStrt )
GROUP BY AUTODATA.mc,T1.DurStrt )AS T2 Inner Join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
--ICD for Type 3 prod record		
UPDATE  #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
FROM
(Select T1.DurStrt as intime,AutoData.mc ,
SUM(CASE
	When autodata.ndtime > T1.DurEnd Then datediff(s,autodata.sttime, T1.DurEnd )
	When autodata.ndtime <=T1.DurEnd Then datediff(s , autodata.sttime,autodata.ndtime)
END) as Down
From #T_autodata autodata INNER Join
	(Select mc,Sttime,NdTime,#CockpitData.Strttm as DurStrt,#CockpitData.ndtim as DurEnd From #T_autodata autodata
	 inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(sttime >= #CockpitData.Strttm)And (ndtime > #CockpitData.ndtim) and sttime<#CockpitData.ndtim ) as T1
ON AutoData.mc=T1.mc
Where AutoData.DataType=2
And (T1.Sttime < autodata.sttime  )
And ( T1.ndtime >  autodata.ndtime)
AND (autodata.sttime  <  T1.DurEnd)
GROUP BY AUTODATA.mc,T1.DurStrt )AS T2 Inner Join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
--ICD for Type 4 prod record	
UPDATE  #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
FROM
(Select T1.DurStrt as intime, AutoData.mc ,
SUM(CASE
---mod 6
--	When autodata.sttime < T1.DurStrt AND autodata.ndtime<=T1.DurEnd Then datediff(s, T1.DurStrt,autodata.ndtime )
--	When autodata.ndtime >= T1.DurEnd AND autodata.sttime>T1.DurStrt Then datediff(s,autodata.sttime, T1.DurEnd )
--	When autodata.sttime >= T1.DurStrt AND autodata.ndtime <= T1.DurEnd Then datediff(s , autodata.sttime,autodata.ndtime)
--	When autodata.sttime<T1.DurStrt AND autodata.ndtime>T1.DurEnd   Then datediff(s , T1.DurStrt,T1.DurEnd)
	When autodata.sttime >= T1.DurStrt AND autodata.ndtime <= T1.DurEnd Then datediff(s , autodata.sttime,autodata.ndtime)
	When autodata.sttime < T1.DurStrt AND autodata.ndtime<=T1.DurEnd and autodata.ndtime > T1.DurStrt Then datediff(s, T1.DurStrt,autodata.ndtime )
	When autodata.sttime>=T1.DurStrt and autodata.ndtime >T1.DurEnd AND autodata.sttime<T1.DurEnd  Then datediff(s,autodata.sttime, T1.DurEnd )
	When autodata.sttime<T1.DurStrt AND autodata.ndtime>T1.DurEnd   Then datediff(s , T1.DurStrt,T1.DurEnd)
---mod 6
END) as Down
From #T_autodata autodata INNER Join
	(Select mc,Sttime,NdTime,#CockpitData.Strttm as DurStrt,#CockpitData.ndtim as DurEnd  From #T_autodata autodata
		inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(msttime < #CockpitData.Strttm)And (ndtime > #CockpitData.ndtim) ) as T1
ON AutoData.mc=T1.mc
Where AutoData.DataType=2
And (T1.Sttime < autodata.sttime  )
And ( T1.ndtime >  autodata.ndtime)
AND (autodata.ndtime  >  T1.DurStrt)
AND (autodata.sttime  <  T1.DurEnd)
GROUP BY AUTODATA.mc,T1.DurStrt
)AS T2 Inner Join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
-- Get the value of CN and components
-- Type 1 and type 2
UPDATE #CockpitData SET CN = isnull(CN,0) + isNull(t2.C1N1,0),components=isnull(components,0)+isnull(T2.pcount,0)
from
(select  #CockpitData.Strttm as intime,mc,
SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))*autodata.partscount) C1N1,
CEILING (sum(CAST((autodata.partscount) AS Float)/ISNULL(componentoperationpricing.SubOperations,1))) as pcount
FROM #T_autodata autodata INNER JOIN
componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID AND
componentoperationpricing.componentid = componentinformation.componentid
inner join machineinformation on machineinformation.interfaceid=autodata.mc
and componentoperationpricing.machineid=machineinformation.machineid
inner join #CockpitData on componentoperationpricing.machineid=#CockpitData.MachineID --autodata.mc=#CockpitData.MachineInterface
where (autodata.ndtime>#CockpitData.Strttm)
and (autodata.ndtime<=#CockpitData.ndtim)
and (autodata.datatype=1)
group by autodata.mc,#CockpitData.Strttm
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
	
---mod 4
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	UPDATE #CockpitData SET CN = isnull(CN,0) - isNull(t2.C1N1,0),Components=isnull(components,0)-isnull(t2.PlanCt,0)
	From
	(
		select T.Dstart as intime,mc,SUM((O.cycletime * ISNULL(A.PartsCount,1))/ISNULL(O.SubOperations,1))  C1N1 ,
		CEILING (sum(CAST((A.partscount) AS Float)/ISNULL(O.SubOperations,1))) as PlanCt
		From #T_autodata A
		inner join machineinformation M on M.interfaceid=A.mc
		Inner join componentinformation C ON A.Comp=C.interfaceid
		Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid
		and O.MachineId=M.MachineId
		inner jOIN #PlannedDownTimesEffi T  on T.Minterface=A.mc
		WHERE A.DataType=1
		AND(A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)
		AND(A.ndtime > T.Dstart  AND A.ndtime <=T.Dend)
		Group by mc,T.Dstart
	) as T2
	inner join #CockpitData  on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
END
---mod 4
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y')
BEGIN
	--downtime type 1,2,3,4
	UPDATE #CockpitData SET downtime = isnull(downtime,0) + isNull(t2.down,0)
	from
	(select     #CockpitData.Strttm as intime, mc,
	sum(case when ( (autodata.msttime>= #CockpitData.Strttm) and (autodata.ndtime<=#CockpitData.ndtim)) then  (loadunload)
			 when ((autodata.msttime< #CockpitData.Strttm)and (autodata.ndtime> #CockpitData.Strttm)and (autodata.ndtime<=#CockpitData.ndtim)) then DateDiff(second,  #CockpitData.Strttm, ndtime)
			 when ((autodata.msttime>= #CockpitData.Strttm)and (autodata.msttime<#CockpitData.ndtim)and (autodata.ndtime>#CockpitData.ndtim)) then DateDiff(second, mstTime, #CockpitData.ndtim)
			 when ((autodata.msttime< #CockpitData.Strttm)and (autodata.ndtime>#CockpitData.ndtim)) then DateDiff(second,  #CockpitData.Strttm, #CockpitData.ndtim) END ) as  down
	from #T_autodata autodata inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface
	where (autodata.datatype=2)
	AND(( (autodata.msttime>=#CockpitData.Strttm) and (autodata.ndtime<=#CockpitData.ndtim))
	OR ((autodata.msttime<#CockpitData.Strttm)and (autodata.ndtime>#CockpitData.Strttm)and (autodata.ndtime<=#CockpitData.ndtim))
	OR ((autodata.msttime>=#CockpitData.Strttm)and (autodata.msttime<#CockpitData.ndtim)and (autodata.ndtime>#CockpitData.ndtim))
	OR((autodata.msttime<#CockpitData.Strttm)and (autodata.ndtime>#CockpitData.ndtim)))
	group by autodata.mc,#CockpitData.Strttm
	) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm	
	--ManagementLoss
	-- Type 1
	UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
	from
	(select #CockpitData.Strttm as intime,mc,sum(
	CASE
	WHEN (loadunload) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
	THEN isnull(downcodeinformation.Threshold,0)
	ELSE loadunload
	END) AS LOSS
	from #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
	inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface
	where (autodata.msttime>=#CockpitData.Strttm)
	and (autodata.ndtime<=#CockpitData.ndtim)
	and (autodata.datatype=2)
	and (downcodeinformation.availeffy = 1)
	group by autodata.mc,#CockpitData.Strttm
	) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
				
	-- Type 2
	UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
	from
	(select    #CockpitData.Strttm as intime, mc,sum(
	CASE WHEN DateDiff(second, #CockpitData.Strttm, ndtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
	then isnull(downcodeinformation.Threshold,0)
	ELSE DateDiff(second, #CockpitData.Strttm, ndtime)
	END)loss
	--DateDiff(second, @CurStarttime, ndtime)
	from #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
	inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface
	where (autodata.sttime<#CockpitData.Strttm)
	and (autodata.ndtime>#CockpitData.Strttm)
	and (autodata.ndtime<=#CockpitData.ndtim)
	and (autodata.datatype=2)
	and (downcodeinformation.availeffy = 1)
	group by autodata.mc,#CockpitData.Strttm
	) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
				
	-- Type 3
	UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
	from
	(select   #CockpitData.Strttm as intime, mc,SUM(
	CASE WHEN DateDiff(second,stTime, #CockpitData.ndtim) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
	then isnull(downcodeinformation.Threshold,0)
	ELSE DateDiff(second, stTime, #CockpitData.ndtim)
	END)loss
	-- sum(DateDiff(second, stTime, @curendtime)) loss
	from #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
	inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface
	where (autodata.msttime>=#CockpitData.Strttm)
	and (autodata.sttime<#CockpitData.ndtim)
	and (autodata.ndtime>#CockpitData.ndtim)
	and (autodata.datatype=2)
	and (downcodeinformation.availeffy = 1)
	group by autodata.mc,#CockpitData.Strttm
	) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
	-- Type 4
				
	
	UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
	from
	(select #CockpitData.Strttm as intime, mc,sum(
	CASE WHEN DateDiff(second, #CockpitData.Strttm, #CockpitData.ndtim) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
	then isnull(downcodeinformation.Threshold,0)
	ELSE DateDiff(second, #CockpitData.Strttm, #CockpitData.ndtim)
	END)loss
	--sum(DateDiff(second, @CurStarttime, @curendtime)) loss
	from #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
	inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface
	where autodata.msttime<#CockpitData.Strttm
	and autodata.ndtime>#CockpitData.ndtim
	and (autodata.datatype=2)
	and (downcodeinformation.availeffy = 1)
	group by autodata.mc,#CockpitData.Strttm
	) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
	IF (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y'
	BEGIN
	
	---get PDT downs overlapping with the down records.
		UPDATE #CockpitData SET downtime = isnull(downtime,0) - isNull(t2.PldDown,0)
		from(
		select T.Dstart  as intime,autodata.mc as mc,SUM
		       (CASE
			WHEN (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN autodata.loadunload
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PldDown
		FROM #T_autodata autodata inner jOIN #PlannedDownTimesEffi T  on T.Minterface=autodata.mc
		INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID
		WHERE autodata.DataType=2    and  (
			(autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )			
			AND DownCodeInformation.DownID=(SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')
		group by autodata.mc,T.Dstart ) as t2 inner join #CockpitData
		on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
	END
	
END
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN
	---Get the down times which are not of type Management Loss
	UPDATE #CockpitData SET downtime = isnull(downtime,0) + isNull(t2.down,0)
	from
	(select     #CockpitData.Strttm as intime, mc,
	sum(case when ( (autodata.msttime>= #CockpitData.Strttm) and (autodata.ndtime<=#CockpitData.ndtim)) then  (loadunload)
			 when ((autodata.msttime< #CockpitData.Strttm)and (autodata.ndtime> #CockpitData.Strttm)and (autodata.ndtime<=#CockpitData.ndtim)) then DateDiff(second,  #CockpitData.Strttm, ndtime)
			 when ((autodata.msttime>= #CockpitData.Strttm)and (autodata.msttime<#CockpitData.ndtim)and (autodata.ndtime>#CockpitData.ndtim)) then DateDiff(second, mstTime, #CockpitData.ndtim)
			 when ((autodata.msttime< #CockpitData.Strttm)and (autodata.ndtime>#CockpitData.ndtim)) then DateDiff(second,  #CockpitData.Strttm, #CockpitData.ndtim) END ) as  down
	from #T_autodata autodata inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface
	inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
	where (autodata.datatype=2)
	AND(( (autodata.msttime>=#CockpitData.Strttm) and (autodata.ndtime<=#CockpitData.ndtim))
	OR ((autodata.msttime<#CockpitData.Strttm)and (autodata.ndtime>#CockpitData.Strttm)and (autodata.ndtime<=#CockpitData.ndtim))
	OR ((autodata.msttime>=#CockpitData.Strttm)and (autodata.msttime<#CockpitData.ndtim)and (autodata.ndtime>#CockpitData.ndtim))
	OR((autodata.msttime<#CockpitData.Strttm)and (autodata.ndtime>#CockpitData.ndtim))) AND (downcodeinformation.availeffy = 0)
	group by autodata.mc,#CockpitData.Strttm
	) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
	
	---get PDT downs overlapping with the down records.
	UPDATE #CockpitData SET downtime = isnull(downtime,0) - isNull(t2.PldDown,0)
	from(
		select T.Dstart  as intime,autodata.mc as mc,SUM
		       (CASE
			WHEN (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN autodata.loadunload
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PldDown
		FROM #T_autodata autodata inner jOIN #PlannedDownTimesEffi T  on T.Minterface=autodata.mc
		INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID
		WHERE autodata.DataType=2    and  (
			(autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )			
			AND (downcodeinformation.availeffy = 0)
		group by autodata.mc,T.Dstart ) as t2 inner join #CockpitData
		on t2.mc = #CockpitData.machineinterface and t2.intime=#CockpitData.Strttm
	UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0)+ isNull(t4.Mloss,0),MLDown=isNull(MLDown,0)+isNull(t4.Dloss,0)
	from
	(select T3.mc,T3.Instart,sum(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss from
	 (
	select   t1.id,T1.mc,T1.Threshold,T1.InStart as Instart,
	case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0) > 0
	then DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)- isnull(T1.Threshold ,0)
	else 0 End  as Dloss,
	case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0) > 0
	then isnull(T1.Threshold,0)
	else DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0) End  as Mloss
	 from
	
	(   select id,mc,comp,opn,opr,D.threshold,#CockpitData.Strttm as InStart,
		case when autodata.sttime<#CockpitData.Strttm then #CockpitData.Strttm else sttime END as sttime,
	       	case when ndtime>#CockpitData.ndtim then #CockpitData.ndtim else ndtime END as ndtime
		from #T_autodata autodata inner join #CockpitData on autodata.mc=#CockpitData.MachineInterface
	inner join  downcodeinformation D on autodata.dcode=D.interfaceid
	where (autodata.datatype=2)
	AND(( (autodata.msttime>=#CockpitData.Strttm) and (autodata.ndtime<=#CockpitData.ndtim))
	OR ((autodata.msttime<#CockpitData.Strttm)and (autodata.ndtime>#CockpitData.Strttm)and (autodata.ndtime<=#CockpitData.ndtim))
	OR ((autodata.msttime>=#CockpitData.Strttm)and (autodata.msttime<#CockpitData.ndtim)and (autodata.ndtime>#CockpitData.ndtim))
	OR((autodata.msttime<#CockpitData.Strttm)and (autodata.ndtime>#CockpitData.ndtim)))  AND (D.availeffy = 1)) as T1 	
	left outer join
	(SELECT T.Dstart  as intime , autodata.id,
		       sum(CASE
			WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PPDT
		FROM #T_autodata autodata inner jOIN #PlannedDownTimesEffi T  on T.MInterface=autodata.mc
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		WHERE autodata.DataType=2 and
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)
			 AND (downcodeinformation.availeffy = 1) group by autodata.id,T.Dstart ) as T2 on T1.id=T2.id  and T2.Intime=T1.InStart ) as T3  group by T3.mc,T3.Instart
	) as t4 inner join  #CockpitData
		on t4.mc = #CockpitData.machineinterface and t4.Instart=#CockpitData.Strttm
	UPDATE #CockpitData  set downtime = isnull(downtime,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)
END
---Exceptions
SELECT @StrSql = 'INSERT INTO #Exceptions(MachineID ,ComponentID,OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,ExCount,DurStart,DurEnd )
		SELECT Ex.MachineID ,Ex.ComponentID,Ex.OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,0,
		S.FromTime,S.ToTime
		From ProductionCountException Ex
		Inner Join MachineInformation M ON Ex.MachineID=M.MachineID
		Inner Join ComponentInformation C ON Ex.ComponentID=C.ComponentID
		Inner Join Componentoperationpricing O ON Ex.OperationNo=O.OperationNo AND C.ComponentID=O.ComponentID '
SELECT @StrSql = @StrSql+ ' and Ex.machineid=O.machineid cross join #ShiftTemp S  '
SELECT @StrSql = @StrSql+ ' WHERE  M.MultiSpindleFlag=1 '
SELECT @StrSql =@StrSql + @strXMachine + @StrTPMMachines
SELECT @StrSql =@StrSql +'AND ((Ex.StartTime>=  S.FromTime AND Ex.EndTime<= S.ToTime )
		OR (Ex.StartTime< S.FromTime AND Ex.EndTime> S.FromTime AND Ex.EndTime<= S.ToTime)
		OR(Ex.StartTime>=S.FromTime AND Ex.EndTime> S.ToTime AND Ex.StartTime< S.ToTime)
		OR(Ex.StartTime< S.FromTime AND Ex.EndTime> S.ToTime ))'
Exec (@strsql)
IF ( SELECT Count(*) from #Exceptions ) <> 0
BEGIN
	UPDATE #Exceptions SET StartTime=DurStart WHERE (StartTime<DurStart AND EndTime>DurStart)
	UPDATE #Exceptions SET EndTime=DurEnd WHERE (EndTime>DurEnd AND StartTime<DurEnd )
	Select @StrSql = 'UPDATE #Exceptions SET ExCount=ISNULL(T2.Comp,0) From
	(
		SELECT T1.DurStart,T1.DurEnd,T1.MachineID AS MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime AS StartTime,T1.EndTime AS EndTime,
		SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp
	 	From (
			select Tt1.DurStart,Tt1.DurEnd,MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,comp,opn,Tt1.StartTime,Tt1.EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from #T_autodata autodata
			Inner Join MachineInformation   ON autodata.MC=MachineInformation.InterfaceID
			Inner Join EmployeeInformation E  ON autodata.Opr=E.InterfaceID
			Inner Join ComponentInformation  ON autodata.Comp = ComponentInformation.InterfaceID
			Inner Join ComponentOperationPricing on autodata.Opn=ComponentOperationPricing.InterfaceID And ComponentInformation.ComponentID=ComponentOperationPricing.ComponentID '
	SELECT @StrSql =@StrSql + ' and MachineInformation.machineid=ComponentOperationPricing.machineid '
	SELECT @StrSql =@StrSql +' Inner Join (
				Select DurStart,DurEnd,MachineID,ComponentID,OperationNo,StartTime,EndTime From #Exceptions
			)AS Tt1 ON Tt1.MachineID=MachineInformation.MachineID AND Tt1.ComponentID = ComponentInformation.ComponentID AND Tt1.OperationNo= ComponentOperationPricing.OperationNo
			and Tt1.Machineid=ComponentOperationPricing.MachineID
			Where (autodata.ndtime>Tt1.StartTime) AND (autodata.ndtime<=Tt1.EndTime) and (autodata.datatype=1) '
	Select @StrSql = @StrSql+' Group by MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,Tt1.StartTime,Tt1.EndTime,comp,opn,Tt1.DurStart,Tt1.DurEnd
		) as T1
	   	Inner join componentinformation C on T1.Comp=C.interfaceid
	   	Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid '
	Select @StrSql = @StrSql+' Inner join machineinformation M on T1.MachineID=M.machineid  and M.MachineId=O.MachineID'
	Select @StrSql = @StrSql+' GROUP BY T1.MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime,t1.EndTime,T1.DurStart,T1.DurEnd
	)AS T2
	WHERE  #Exceptions.StartTime=T2.StartTime AND #Exceptions.EndTime=T2.EndTime
	AND #Exceptions.MachineID=T2.MachineID AND #Exceptions.ComponentID = T2.ComponentID AND #Exceptions.OperationNo=T2.OperationNo
	and #Exceptions.DurStart=T2.DurStart and #Exceptions.DurEnd=T2.DurEnd'
	Exec(@StrSql)
	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
	BEGIN
			
		Select @StrSql =''
		Select @StrSql ='UPDATE #Exceptions SET ExCount=ISNULL(ExCount,0) - ISNULL(T3.Comp,0)
		From
		(
			SELECT T2.Dstart,T2.Dend,T2.MachineID AS MachineID,T2.ComponentID,T2.OperationNo,T2.StartTime AS StartTime,T2.EndTime AS EndTime,
			SUM(CEILING (CAST(T2.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp
			From
			(
				select T1.Dstart,T1.Dend,MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,comp,opn,
				Max(T1.XStartTime)StartTime,Max(T1.XEndTime)EndTime,T1.PLD_StartTime,T1.PLD_EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from #T_autodata autodata
				Inner Join MachineInformation   ON autodata.MC=MachineInformation.InterfaceID
				Inner Join ComponentInformation  ON autodata.Comp = ComponentInformation.InterfaceID
				Inner Join ComponentOperationPricing on autodata.Opn=ComponentOperationPricing.InterfaceID And ComponentInformation.ComponentID=ComponentOperationPricing.ComponentID
				and ComponentOperationPricing.Machineid=MachineInformation.Machineid
				Inner Join	
				(
					SELECT Td.Dstart,Td.Dend,MachineID,ComponentID,OperationNo,Ex.StartTime As XStartTime, Ex.EndTime AS XEndTime,
					CASE
						WHEN (Td.StartTime< Ex.StartTime And Td.EndTime<=Ex.EndTime AND Td.EndTime>Ex.StartTime) THEN Ex.StartTime
						WHEN  (Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime) THEN Ex.StartTime
						ELSE Td.StartTime
					END AS PLD_StartTime,
					CASE
						WHEN (Td.StartTime>= Ex.StartTime And Td.StartTime <Ex.EndTime AND Td.EndTime>Ex.EndTime) THEN Ex.EndTime
						WHEN  (Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime) THEN Ex.EndTime
						ELSE  Td.EndTime
					END AS PLD_EndTime
		
					From #Exceptions AS Ex inner  join  #PlannedDownTimesEffi  Td on Td.Machine=Ex.Machineid
					Where   ((Td.StartTime>=Ex.StartTime And Td.EndTime <=Ex.EndTime)OR
					(Td.StartTime< Ex.StartTime And Td.EndTime<=Ex.EndTime AND Td.EndTime>Ex.StartTime)OR
					(Td.StartTime>= Ex.StartTime And Td.StartTime <Ex.EndTime AND Td.EndTime>Ex.EndTime)OR
					(Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime))  '
			Select @StrSql = @StrSql + ' )AS T1 ON T1.MachineID=MachineInformation.MachineID AND T1.ComponentID = ComponentInformation.ComponentID AND
						   T1.OperationNo= ComponentOperationPricing.OperationNo and T1.machineid=ComponentOperationPricing.Machineid
				Where (autodata.ndtime>T1.PLD_StartTime AND autodata.ndtime<=T1.PLD_EndTime) and (autodata.datatype=1)
			AND (autodata.ndtime > T1.Dstart AND autodata.ndtime<=T1.Dend )'
			Select @StrSql = @StrSql+' Group by MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,T1.PLD_StartTime,T1.PLD_EndTime,comp,opn,T1.Dstart,T1.Dend
			)AS T2
			Inner join componentinformation C on T2.Comp=C.interfaceid
			Inner join ComponentOperationPricing O ON T2.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineId=T2.MachineID
			GROUP BY T2.MachineID,T2.ComponentID,T2.OperationNo,T2.StartTime,t2.EndTime,T2.Dstart,T2.Dend
		)As T3
		WHERE  #Exceptions.StartTime=T3.StartTime AND #Exceptions.EndTime=T3.EndTime
		AND #Exceptions.MachineID=T3.MachineID AND #Exceptions.ComponentID = T3.ComponentID AND #Exceptions.OperationNo=T3.OperationNo
		and #Exceptions.DurStart=T3.DStart and #Exceptions.DurEnd=T3.DEnd'
		PRINT @StrSql
		EXEC(@StrSql)
	END
	UPDATE #Exceptions SET ExCount=ExCount-((ExCount * ActualCount)/ISNULL(IdealCount,0))
	
END
--Apply Exception on Count..

CREATE TABLE #ShiftDefn
(
	ShiftDate datetime,		
	Shiftname nvarchar(20),
	ShftSTtime datetime,
	ShftEndTime datetime	
)



declare @startdate as datetime
declare @enddate as datetime
declare @startdatetime nvarchar(20)



if @TimeAxis='Shift' or @TimeAxis='DAY'
BEGIN
select @startdate=dbo.f_GetLogicalDay(@StartTime,'start')
select @enddate=dbo.f_GetLogicalDay(@EndTime,'end')
END



while @startdate<=@enddate
Begin

	select @startdatetime = CAST(datePart(yyyy,@startdate) AS nvarchar(4)) + '-' + 
     CAST(datePart(mm,@startdate) AS nvarchar(2)) + '-' + 
     CAST(datePart(dd,@startdate) AS nvarchar(2))

	INSERT INTO #ShiftDefn(ShiftDate,Shiftname,ShftSTtime,ShftEndTime)
	select @startdate,ShiftName,
	Dateadd(DAY,FromDay,(convert(datetime, @startdatetime + ' ' + CAST(datePart(hh,FromTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,FromTime) as nvarchar(2))+ ':' + CAST(datePart(ss,FromTime) as nvarchar(2))))) as StartTime,
	DateAdd(Day,ToDay,(convert(datetime, @startdatetime + ' ' + CAST(datePart(hh,ToTime) AS nvarchar(2)) + ':' + CAST(datePart(mi,ToTime) as nvarchar(2))+ ':' + CAST(datePart(ss,ToTime) as nvarchar(2))))) as EndTime
	from shiftdetails where running = 1 order by shiftid
	Select @startdate = dateadd(d,1,@startdate)
END


create table #shift
(
	
	ShiftDate nvarchar(10), --DR0333
	shiftname nvarchar(20),
	Shiftstart datetime,
	Shiftend datetime,
	shiftid int
)

Insert into #shift (ShiftDate,shiftname,Shiftstart,Shiftend)
select convert(nvarchar(10),ShiftDate,126),shiftname,ShftSTtime,ShftEndTime from #ShiftDefn --where ShftSTtime>=@StartTime and ShftEndTime<=@endtime 



Update #shift Set shiftid = isnull(#shift.Shiftid,0) + isnull(T1.shiftid,0) from
(Select SD.shiftid ,SD.shiftname from shiftdetails SD
inner join #shift S on SD.shiftname=S.shiftname where
running=1 )T1 inner join #shift on  T1.shiftname=#shift.shiftname

Update #CockPitData Set shiftid = isnull(#CockPitData.Shiftid,0) + isnull(T1.shiftid,0) from
(Select SD.shiftid ,SD.shiftname from shiftdetails SD
inner join #CockPitData S on SD.shiftname=S.shftnm where
running=1 )T1 inner join #CockPitData on  T1.shiftname=#CockPitData.shftnm


if @TimeAxis='Shift'
BEGIN

Update #Cockpitdata set RejCount = isnull(RejCount,0) + isnull(T1.RejQty,0)
From
( Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A
inner join Machineinformation M on A.mc=M.interfaceid
inner join #Cockpitdata on #Cockpitdata.machineid=M.machineid 
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
where A.CreatedTS>=@StartTime and A.CreatedTS<@Endtime and A.flag = 'Rejection'
and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000'
group by A.mc,M.Machineid
)T1 inner join #Cockpitdata B on B.Machineid=T1.Machineid 

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	Update #Cockpitdata set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from
	(Select A.mc,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A
	inner join Machineinformation M on A.mc=M.interfaceid
	inner join #Cockpitdata on #Cockpitdata.machineid=M.machineid 
	inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
	Cross join Planneddowntimes P
	where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid 
	and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000' and
	A.CreatedTS>=@StartTime and A.CreatedTS<@Endtime And
	A.CreatedTS>=P.Starttime and A.CreatedTS<P.endtime
	group by A.mc,M.Machineid)T1 inner join #Cockpitdata B on B.Machineid=T1.Machineid 
END

--Vas
Update #Cockpitdata set RejCount = isnull(RejCount,0) + isnull(T1.RejQty,0)
From
( 
 Select A.mc,sum(A.Rejection_Qty) as RejQty,M.Machineid,RejDate,C.shiftid as ShiftID,C.Pdt as PDT from AutodataRejections A
inner join Machineinformation M on A.mc=M.interfaceid
inner join #Cockpitdata C on C.machineid=M.machineid  and  C.ShiftID=A.RejShift and convert(nvarchar(10),(C.Pdt),126)=convert(nvarchar(10),(A.RejDate),126)
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
inner join #shift S on convert(nvarchar(10),(A.RejDate),126)=convert(nvarchar(10),S.shiftdate,126) and A.RejShift=S.shiftid --DR0333
where A.flag = 'Rejection' and A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (convert(nvarchar(10),(S.shiftdate),126)) 
and  Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
group by A.mc,M.Machineid,RejDate,C.shiftid,Pdt
)T1 inner join #Cockpitdata B on B.Machineid=T1.Machineid AND b.ShiftID=T1.ShiftID and b.Pdt=T1.PDT

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	Update #Cockpitdata set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from
	( Select A.mc,sum(A.Rejection_Qty) as RejQty,M.Machineid,RejDate,C.shiftid as ShiftID,C.Pdt as PDT from AutodataRejections A
	inner join Machineinformation M on A.mc=M.interfaceid
	inner join #Cockpitdata C on C.machineid=M.machineid  and  C.ShiftID=A.RejShift and convert(nvarchar(10),(C.Pdt),126)=convert(nvarchar(10),(A.RejDate),126)
	inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
	inner join #shift S on convert(nvarchar(10),(A.RejDate),126)=convert(nvarchar(10),(S.shiftdate),126) and A.RejShift=S.shiftid --DR0333
	Cross join Planneddowntimes P
	where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid and
	A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (convert(nvarchar(10),(S.shiftdate),126)) and --DR0333
	Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
	and P.starttime>=S.Shiftstart and P.Endtime<=S.shiftend
	group by A.mc,M.Machineid,RejDate,C.shiftid,Pdt)T1 inner join #Cockpitdata B on B.Machineid=T1.Machineid AND b.ShiftID=T1.ShiftID and b.Pdt=T1.PDT
END

END

UPDATE #CockpitData SET components = ISNULL(components,0) - ISNULL(t2.comp,0)
from
( select DurStart as intime,MachineID,SUM(ExCount) as comp
	From #Exceptions GROUP BY MachineID,DurStart ) as T2
Inner join #CockpitData on T2.MachineID = #CockpitData.MachineID
and t2.intime=#CockpitData.Strttm

--UPDATE #Cockpitdata SET QualityEfficiency= ISNULL(QualityEfficiency,0) + IsNull(T1.QE,0) 
--FROM(Select MachineID,
--CAST((Sum(Components))As Float)/CAST((Sum(IsNull(Components,0))+Sum(IsNull(RejCount,0))) AS Float)As QE,Strttm
--From #Cockpitdata Where Components<>0 Group By MachineID,Strttm
--)AS T1 Inner Join #Cockpitdata ON  #Cockpitdata.MachineID=T1.MachineID and #Cockpitdata.Strttm=T1.Strttm

UPDATE #Cockpitdata SET QualityEfficiency= ISNULL(QualityEfficiency,0) + IsNull(T1.QE,0) 
FROM(Select MachineID,
cast((Sum(isnull(Components,0))-Sum(IsNull(RejCount,0))) as float)/CAST((Sum(IsNull(Components,0))) AS Float)As QE,Strttm
From #Cockpitdata Where Components<>0 Group By MachineID,Strttm
)AS T1 Inner Join #Cockpitdata ON  #Cockpitdata.MachineID=T1.MachineID and #Cockpitdata.Strttm=T1.Strttm

UPDATE #CockpitData
		SET
			ProductionEfficiency = (CN/UtilisedTime) ,
			AvailabilityEfficiency = (UtilisedTime)/(UtilisedTime + DownTime - ManagementLoss)
			
		WHERE UtilisedTime <> 0


update #cockpitdata set AvgProductionEfficiency=isnull(t2.APE,0),AvgAvailabilityEfficiency = isnull(t2.aae,0),AvgQualityEfficiency=isnull(t2.aqe,0), AvgOverallEfficiency=isnull(t2.OEE,0)  from 
 (select MachineId,avg(ProductionEfficiency)*100 as APE,avg(AvailabilityEfficiency)*100 as AAE,avg(QualityEfficiency)*100 as aqe,
 (avg(ProductionEfficiency * AvailabilityEfficiency*QualityEfficiency)*100) As OEE  from #CockpitData 
 where UtilisedTime > 0 OR downtime > 0 --DR0360 added
group by machineid)t2 inner join #CockpitData on t2.MachineID = #CockpitData.MachineID


update #cockpitdata  set TargetOEE =isnull(t.OE,0) from    
(select machineid,OE,startdate,enddate from efficiencytarget)t 
inner join #CockpitData on t.MachineID = #CockpitData.MachineID and t.startdate<=#cockpitdata.Pdt and t.enddate>=#cockpitdata.Pdt 
--select isnull(t.OE,0) from (select machineid,OE from efficiencytarget where startdate<=@StartTime and enddate>=@starttime)t inner join #CockpitData on t.MachineID = #CockpitData.MachineID


--if @TimeAxis='Shift'
--BEGIN
--	DECLARE @strShiftName  nvarchar(200)
--	Declare @Machine as nvarchar(200)
--		SET @strShiftName = ''
--		SET @strmachine = ''
--		if isnull(@Machine,'') <> ''
--			BEGIN
--			---mod 2
----			SELECT @strmachine = ' AND ( ShiftProductionDetails.machineid = ''' + @Machine+ ''')'
--			SELECT @strmachine = ' AND ( ShiftProductionDetails.machineid = N''' + @Machine+ ''')'
--			---mdo 2
--			END
--		if isnull(@ShiftName, '') <> ''
--			BEGIN
--			---mod 2

--			SELECT @strShiftName = ' AND ( ShiftProductionDetails.Shift = N''' + @ShiftName+ ''')'
--			---mod 2
--			END
--		SELECT @StrSql= ' UPDATE #CockpitData SET			    #CockpitData.Rejection = ISNULL(t.RejectionSUM,0) '
--		SELECT @StrSql=@StrSql+ ' From '
--		SELECT @StrSql=@StrSql+ '(Select ShiftProductionDetails.pDate as pDate ,Shift,MachineID,SUM(ShiftRejectionDetails.Rejection_Qty) as RejectionSum'
--		SELECT @StrSql=@StrSql+ ' From ShiftProductionDetails Left Outer Join ShiftRejectionDetails ON'
--		SELECT @StrSql=@StrSql+ ' ShiftProductionDetails.ID=ShiftRejectionDetails.ID'
--		SELECT @StrSql=@StrSql+ ' WHERE ShiftProductionDetails.pDate >='''+ Convert(Nvarchar(20),@StartTime)+''''
--		SELECT @StrSql=@StrSql+ ' AND ShiftProductionDetails.pDate <='''+ Convert(Nvarchar(20),@EndTime)+''''
--		SELECT @StrSql=@StrSql + @strmachine + @strShiftName
--		SELECT @StrSql=@StrSql +' GROUP by ShiftProductionDetails.pDate,ShiftProductionDetails.MachineID,ShiftProductionDetails.shift) as t '
--		SELECT @StrSql=@StrSql +' inner join #CockpitData on #CockpitData.Pdt = t.pDate and #CockpitData.shftnm = t.shift and #CockpitData.machineid = t.machineID '
--		--select * from #CockpitData
--		Print (@StrSql)
--		EXEC(@StrSql)		
		
--END
	if @TimeAxis='Hour' AND @Type='Console'
	BEGIN
		SELECT	cast(cast(DateName(month,Pdt) as nvarchar(3))+ ' '+cast(datepart(dd,Pdt)as nvarchar(2))+ ' Shift-' +cast(shftnm as nvarchar(20)) as Nvarchar(50)) as Day,
		--cast(cast(DateName(month,pdate)as nvarchar(3))+'-'+cast(datepart(dd,Pdate)as nvarchar(2))+'-'+ cast(ShiftName as nvarchar(20))+' '+CASE WHEN DATALENGTH(Cast(datepart(hh,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,FromTime)as nvarchar(2)) ELSE cast(datepart(hh,FromTime)as nvarchar(2))END +':'+CASE WHEN DATALENGTH(Cast(datepart(n,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(n,FromTime)as nvarchar(2)) ELSE cast(datepart(n,FromTime)as nvarchar(2))END +' To '+CASE WHEN DATALENGTH(Cast(datepart(hh,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,ToTime)as nvarchar(2)) ELSE cast(datepart(hh,ToTime)as nvarchar(2))END+':'+CASE WHEN DATALENGTH(Cast(datepart(n,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(n,ToTime)as nvarchar(2)) ELSE cast(datepart(n,ToTime)as nvarchar(2))END  as nvarchar(50)) as Day,
		Cast(CAST(YEAR(Strttm)as nvarchar(4))+CAST(Month(Strttm)as nvarchar(2))+CAST(Day(Strttm)as nvarchar(2))+CASE WHEN DATALENGTH(Cast(datepart(hh,Strttm)as nvarchar))=2 THEN '0'+cast(datepart(hh,Strttm)as nvarchar(2)) ELSE cast(datepart(hh,Strttm)as nvarchar(2))END +':'+CASE WHEN DATALENGTH(Cast(datepart(n,Strttm)as nvarchar))=2 THEN '0'+cast(datepart(n,Strttm)as nvarchar(2)) ELSE cast(datepart(n,Strttm)as nvarchar(2))END+' To '+CASE WHEN DATALENGTH(Cast(datepart(hh,ndtim)as nvarchar))=2 THEN '0'+cast(datepart(hh,ndtim)as nvarchar(2)) ELSE cast(datepart(hh,ndtim)as nvarchar(2))END+':'+CASE WHEN DATALENGTH(Cast(datepart(n,ndtim)as nvarchar))=2 THEN '0'+cast(datepart(n,ndtim)as nvarchar(2)) ELSE cast(datepart(n,ndtim)as nvarchar(2))END  as NVarchar(50)) as Shift,
		Pdt,shftnm,Strttm,
		ndtim,	
		MachineID, machineDescription,AvailabilityEfficiency * 100 As AE,
		ProductionEfficiency * 100 As PE,
		(ProductionEfficiency * AvailabilityEfficiency)*100 As OE,
		Components		
		FROM #CockpitData Order by Machineid,Strttm
	END
	
--vasavi

	if @TimeAxis='Day'AND @Type='Console' and @daywise='sort'

	BEGIN

		SELECT	
		cast(cast(DateName(month,Pdt) as nvarchar(3))+ ' '+cast(datepart(dd,Pdt)as nvarchar(4)) as Nvarchar(50)) as Day,
		Strttm AS Shift,
		--cast(cast(DateName(month,Pdt) as nvarchar(3))+ ' '+cast(datepart(dd,Pdt)as nvarchar(2)) as Nvarchar(50)) as Day,
		Pdt,shftnm,Strttm,
		ndtim,	
		 MachineID,
		 machineDescription,
		 AvailabilityEfficiency * 100 As AE,
		(ProductionEfficiency * 100) As PE,
		(ProductionEfficiency * AvailabilityEfficiency)*100 As OE,
		  AvgProductionEfficiency as APE,
		  AvgAvailabilityEfficiency as AAE,
		  AvgOverallEfficiency,
	Components,
	isnull(targetOEE,0)	as targetOEE
	
		--FROM #CockpitData Order by [day],machineid
		FROM #CockpitData Order by Pdt,machineid --g:
	END
	
if @TimeAxis='Day'AND @Type='Console' and @daywise='0'
	BEGIN

		SELECT	
		cast(cast(DateName(month,Pdt) as nvarchar(3))+ ' '+cast(datepart(dd,Pdt)as nvarchar(4)) as Nvarchar(50)) as Day,
		Strttm AS Shift,
		--cast(cast(DateName(month,Pdt) as nvarchar(3))+ ' '+cast(datepart(dd,Pdt)as nvarchar(2)) as Nvarchar(50)) as Day,
		Pdt,shftnm,Strttm,
		ndtim,	
		 MachineID,
		  machineDescription,
		 AvailabilityEfficiency * 100 As AE,
		(ProductionEfficiency * 100) As PE,
		(ProductionEfficiency * AvailabilityEfficiency)*100 As OE,
		  AvgProductionEfficiency as APE,
		  AvgAvailabilityEfficiency as AAE,
		  AvgOverallEfficiency,
	Components,
	isnull(targetOEE,0)	as targetOEE
	
		FROM #CockpitData Order by Machineid,Strttm
	END
	
	if @TimeAxis='Shift' AND @Type='Console' and @daywise='sort'
	BEGIN
		SELECT
			--cast(cast(DateName(month,Pdt) as nvarchar(3))+ ' '+cast(datepart(dd,Pdt)as nvarchar(2))+ ' Shift-' +cast(shftnm as nvarchar(20)) as Nvarchar(50)) as Day,
		cast(cast(DateName(month,Pdt) as nvarchar(3))+ ' '+cast(datepart(dd,Pdt)as nvarchar(2)) as Nvarchar(50)) as Day,	
		cast('Shift-'+cast(shftnm as nvarchar(20))as nvarchar(50)) as Shift,
					Pdt,shftnm,Strttm,ndtim,MachineID, machineDescription,
		AvailabilityEfficiency * 100 As AE,
		ProductionEfficiency * 100 As PE,
		--(ProductionEfficiency * AvailabilityEfficiency)*100 As OE,
		---mod 3
		--'OE' = CASE
				--WHEN isnull(Components,0) <> 0 then (ProductionEfficiency * AvailabilityEfficiency*100) * ((Components - isnull(rejection,0))/Components)
			--END,
		'OE' = isnull(CASE
				WHEN isnull(Components,0) <> 0 then (ProductionEfficiency * AvailabilityEfficiency*100) * ((Components - isnull(RejCount,0))/Components)
			END,0),
		---mod 3
		Components,RejCount as Rejection,
AvgProductionEfficiency as APE,
AvgAvailabilityEfficiency as AAE,
AvgOverallEfficiency,
isnull(targetOEE,0)	as targetOEE
	
		--FROM #CockpitData Order by [day],[shift],machineID
		FROM #CockpitData Order by Pdt,[shift],machineID --g:
	END

if @TimeAxis='Shift' AND @Type='Console' and @daywise='1'
	BEGIN
		SELECT
			--cast(cast(DateName(month,Pdt) as nvarchar(3))+ ' '+cast(datepart(dd,Pdt)as nvarchar(2))+ ' Shift-' +cast(shftnm as nvarchar(20)) as Nvarchar(50)) as Day,
		cast(cast(DateName(month,Pdt) as nvarchar(3))+ ' '+cast(datepart(dd,Pdt)as nvarchar(2)) as Nvarchar(50)) as Day,	
		cast('Shift-'+cast(shftnm as nvarchar(20))as nvarchar(50)) as Shift,
					Pdt,shftnm,Strttm,ndtim,MachineID, machineDescription,
		ROUND(AvailabilityEfficiency * 100,2) As AE,
		ROUND(ProductionEfficiency * 100,2) As PE,
		round(qualityefficiency*100,2) as QE,
		--(ProductionEfficiency * AvailabilityEfficiency)*100 As OE,
		---mod 3
		--'OE' = CASE
				--WHEN isnull(Components,0) <> 0 then (ProductionEfficiency * AvailabilityEfficiency*100) * ((Components - isnull(rejection,0))/Components)
			--END,
		'OE' = isnull(CASE
				WHEN isnull(Components,0) <> 0 then ROUND((ProductionEfficiency * AvailabilityEfficiency*qualityefficiency* 100),2)
			END,0),
		---mod 3
		--Components,Rejection,
		Components,RejCount as Rejection,
    ROUND(AvgProductionEfficiency,2) as APE,
    ROUND(AvgAvailabilityEfficiency,2) as AAE,
	ROUND(AvgQualityEfficiency,2) as AQE,
    ROUND(AvgOverallEfficiency,2) as AvgOverallEfficiency,
    ROUND(isnull(targetOEE,0),2)	as targetOEE
	
		FROM #CockpitData Order by Machineid,Strttm
	END




	if  @TimeAxis='Month'AND @Type='Console'
	BEGIN
		SELECT	
		--cast(cast(DateName(month,Pdt) as nvarchar(3))+ ' '+cast(datepart(yyyy,Pdt)as nvarchar(4)) as Nvarchar(50)) as Day,
		cast(Datepart(yyyy,pdt)as nvarchar(50)) As Day,
		Strttm AS Shift,
		Pdt,shftnm,Strttm,
		ndtim,	
		 MachineID, machineDescription,AvailabilityEfficiency * 100 As AE,
		ProductionEfficiency * 100 As PE,
		(ProductionEfficiency * AvailabilityEfficiency)*100 As OE,
		Components		
		FROM #CockpitData Order by Machineid,Strttm
	END
	if @TimeAxis='Hour' AND @Type='Cockpit'
	BEGIN
		SELECT	
		cast(cast(DateName(month,Pdt) as nvarchar(3))+ ' '+cast(datepart(dd,Pdt)as nvarchar(2))+ ' Shift-' +cast(shftnm as nvarchar(20)) as Nvarchar(50)) as Day,
		--cast(cast(DateName(month,pdate)as nvarchar(3))+'-'+cast(datepart(dd,Pdate)as nvarchar(2))+'-'+ cast(ShiftName as nvarchar(20))+' '+CASE WHEN DATALENGTH(Cast(datepart(hh,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,FromTime)as nvarchar(2)) ELSE cast(datepart(hh,FromTime)as nvarchar(2))END +':'+CASE WHEN DATALENGTH(Cast(datepart(n,FromTime)as nvarchar))=2 THEN '0'+cast(datepart(n,FromTime)as nvarchar(2)) ELSE cast(datepart(n,FromTime)as nvarchar(2))END +' To '+CASE WHEN DATALENGTH(Cast(datepart(hh,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(hh,ToTime)as nvarchar(2)) ELSE cast(datepart(hh,ToTime)as nvarchar(2))END+':'+CASE WHEN DATALENGTH(Cast(datepart(n,ToTime)as nvarchar))=2 THEN '0'+cast(datepart(n,ToTime)as nvarchar(2)) ELSE cast(datepart(n,ToTime)as nvarchar(2))END  as nvarchar(50)) as Day,
		Cast(CAST(YEAR(Strttm)as nvarchar(4))+CAST(Month(Strttm)as nvarchar(2))+CAST(Day(Strttm)as nvarchar(2))+CASE WHEN DATALENGTH(Cast(datepart(hh,Strttm)as nvarchar))=2 THEN '0'+cast(datepart(hh,Strttm)as nvarchar(2)) ELSE cast(datepart(hh,Strttm)as nvarchar(2))END +':'+CASE WHEN DATALENGTH(Cast(datepart(n,Strttm)as nvarchar))=2 THEN '0'+cast(datepart(n,Strttm)as nvarchar(2)) ELSE cast(datepart(n,Strttm)as nvarchar(2))END+' To '+CASE WHEN DATALENGTH(Cast(datepart(hh,ndtim)as nvarchar))=2 THEN '0'+cast(datepart(hh,ndtim)as nvarchar(2)) ELSE cast(datepart(hh,ndtim)as nvarchar(2))END+':'+CASE WHEN DATALENGTH(Cast(datepart(n,ndtim)as nvarchar))=2 THEN '0'+cast(datepart(n,ndtim)as nvarchar(2)) ELSE cast(datepart(n,ndtim)as nvarchar(2))END  as NVarchar(50)) as Shift,
		Pdt,shftnm,Strttm,
		ndtim,	
		MachineID, machineDescription,AvailabilityEfficiency * 100 As AE,
		ProductionEfficiency * 100 As PE,
		(ProductionEfficiency * AvailabilityEfficiency)*100 As OE,
		Components		
		FROM #CockpitData Order by Machineid,Strttm
	END
	if @TimeAxis='Shift' AND @Type='Cockpit'
	BEGIN
		SELECT
		cast(cast(DateName(month,Pdt) as nvarchar(3))+ ' '+cast(datepart(dd,Pdt)as nvarchar(2))+ ' Shift-' +cast(shftnm as nvarchar(20)) as Nvarchar(50)) as Day,
		--cast(cast(DateName(month,Pdt) as nvarchar(3))+ ' '+cast(datepart(dd,Pdt)as nvarchar(2)) as Nvarchar(50)) as Day,	
		'Shift-'+cast(shftnm as nvarchar(20)) as Shift,
					Pdt,shftnm,Strttm,ndtim,MachineID, machineDescription,
		AvailabilityEfficiency * 100 As AE,
		ProductionEfficiency * 100 As PE,
		--(ProductionEfficiency * AvailabilityEfficiency)*100 As OE,
		---mod 3
		--'OE' = CASE
				--WHEN isnull(Components,0) <> 0 then (ProductionEfficiency * AvailabilityEfficiency*100) * ((Components - isnull(rejection,0))/Components)
			--END,
		'OE' = isnull(CASE
				WHEN isnull(Components,0) <> 0 then (ProductionEfficiency * AvailabilityEfficiency*100) * ((Components - isnull(RejCount,0))/Components)
			END,0),
		---mod 3
		Components,RejCount as Rejection
		FROM #CockpitData Order by Machineid,Strttm
	END
	if @TimeAxis='Day' AND @Type='Cockpit'
	BEGIN
		SELECT	
		--cast(cast(DateName(month,Pdt) as nvarchar(3))+ ' '+cast(datepart(yyyy,Pdt)as nvarchar(4)) as Nvarchar(50)) as Day,
		cast(cast(DateName(month,Pdt) as nvarchar(3))+ ' '+cast(datepart(dd,Pdt)as nvarchar(2)) as Nvarchar(50)) as Day,
		Pdt,shftnm,Strttm,
		ndtim,	
		 MachineID, machineDescription,AvailabilityEfficiency * 100 As AE,
		ProductionEfficiency * 100 As PE,
		(ProductionEfficiency * AvailabilityEfficiency)*100 As OE,
		Components	
		FROM #CockpitData Order by Machineid,Strttm

	END
	if  @TimeAxis='Month' AND @Type='Cockpit'
	BEGIN
		SELECT	
		cast(cast(DateName(month,Pdt) as nvarchar(3))+ ' '+cast(datepart(yyyy,Pdt)as nvarchar(4)) as Nvarchar(50)) as Day,
		--cast(Datepart(yyyy,pdt)as nvarchar(50)) As Day,
		Pdt,shftnm,Strttm,
		ndtim,	
		 MachineID, machineDescription,AvailabilityEfficiency * 100 As AE,
		ProductionEfficiency * 100 As PE,
		(ProductionEfficiency * AvailabilityEfficiency)*100 As OE,
		Components		
		FROM #CockpitData Order by Machineid,Strttm
	END
END
