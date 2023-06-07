/****** Object:  Procedure [dbo].[s_GetDailyProductionReportFromAutodata_Kiswok]    Committed by VersionSQL https://www.versionsql.com ******/

/************************************************************************************************************
Procedure altered by Sangeeta K On 16-Feb-2006
Including Threshold(Down)in MLoss Calculation
Changed By Sangeeta Kallur On 01-July-2006
To Support Down Within Production Cycle.
Changed By SSK on 10-July-2006 :- Sub Operations at CO Level [Autoaxel]
Changed [CN,OperationCount,Actual Avg(CycleTime , LoadUnload) Caln]
Chaged By SSK on 06-Oct-2006 :To include Plant Level Concept
Procedure Changed By SSK on 02-Dec-2006 : To Remove Constraint Name.
Altered by Mrudula to calculate production and target for a period of time
Altered By Mrudula To add @EndDate ie to make it for open time period.
Procedure Changed By Sangeeta Kallur on 22-FEB-2007 : TO BRING MARKS CHANGES INTO PRODUCT.
Procedure Changed By Sangeeta Kallur on 01-MAR-2007 :
	To Change Production count Which gets affected for Multispindle type of machines.
Procedure Changed by SSK:25/07/07:DR0016:To consider records whose LU >= MinLUForLR for LR,Avg LU,LU Effy
Procedure altered by Mrudula to change the order of the output
mod 1 :- ER0181 By Kusuma M.H on 12-May-2009.2) Modify all the procedures accordingly. Qualify machine wherever we are making use of component and opeartion no.
mod 2 :- ER0182 By Kusuma M.H on 12-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
mod 3:- DR0213 by Mrudula M. Rao on 25-Sep-2009. Divide by zero error is coming. put sutodata.partscount>0 for calculating average values
mod 4:- ER0210 By Karthik G :: Introduce PDT on 5150.
			1) Handle PDT at Machine Level.
			2) Handle interaction between PDT and Mangement Loss. Also handle interaction InCycleDown And PDT.
			3) Improve the performance.
			4) Handle intearction between ICD and PDT for type 1 production record for the selected time period.
DR0236 - By SwathiKS on 23-Jun-2010 :: Use proper conditions in case statements to remove icd's from type 4 production records.
mod 5: - DR0263 - Karthick R - 21/oct/2010.To Apply PDT for target also for Avg cycletime
DR0296 - SwathiKS - 13/Sep/2011 :: To Validate with PlantMachine Table.
DR0327 - SwathiKS -26/Apr/2013 :: To handle Negative Average Cycletime During PDT.
DR0325 - SwathiKS - 13/May/2013 :: a> To handle PDT for Avgloadunload and Avgcycletime.
				   b> For Utilised calculation To consider difference between Autodata msttime and ndtime instaed of NetCycletime for Tyep1 Record with PDT and
				      also during ICD-PDT interaction for Type 1,2,3,4 Records. 
ER0363 - SwathiKS - 12/Aug/2013 :: To Consider PDT for AverageCycletime and AvgLoadunload Based on Setting in CockpitDefaults i.e 
(Ignore_Ptime_4m_PLD)='Y' and (Ignore_AvgCycletime_4m_PLD)='Y'
NR0097 - SwathiKS - 21/Jan/2014 :: Since we are splitting Production and Down Cycle across shifts while showing partscount we have to consider decimal values instead whole Numbers.
--DR0339 - SwathiKS - 25/Feb/2014 :: While handling ICD-PDT Interaction for Type-1,we have to pick cycles which has ProductionStart=ICDStart and ProductionEnd=ICDEnd.
ER0450 - SwathiKS - 10/oct/2017 :: If the CompanyName Contains "SHANTI IRON AND STEEL FOUNDRY" then Show OperationDescription Instead of OperationNo in the following Reports.
a> SM-Std-Production Report Machinewise-Daily-Format1
ER0465 - Gopinath - 15/may/2018 :: Performance Optimization(Altered while loop logic).
--s_GetDailyProductionReportFromAutodata_Kiswok '2019-07-01','','Phantom','','','','2021-07-01'

[dbo].[s_GetDailyProductionReportFromAutodata_Kiswok] '2020-11-02','Equator Phantom','','','','','2020-11-02'
[dbo].[s_GetDailyProductionReportFromAutodata_Kiswok] '2020-11-02','Laser Marking Machine Compact x','','','','','2020-11-02'
[dbo].[s_GetDailyProductionReportFromAutodata_Kiswok] '2021-03-21','','','','','','2021-03-21','Summary'
[dbo].[s_GetDailyProductionReportFromAutodata_Kiswok] '2021-03-18','','','','','','2021-03-18',''


**************************************************************************************************************/
CREATE PROCEDURE [dbo].[s_GetDailyProductionReportFromAutodata_Kiswok]
	@StartDate datetime,
	@MachineID nvarchar(50) = '',
	@GroupID As nvarchar(50) = '',
	@ComponentID nvarchar(50) = '',
	@OperationNo nvarchar(50) = '',
	@PlantID  Nvarchar(50) = '',
	@EndDate datetime,
	@param nvarchar(50)=''
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

Declare @strSql as nvarchar(4000)
Declare @strmachine nvarchar(255)
Declare @strcomponentid nvarchar(255)
Declare @stroperation nvarchar(255)
Declare @StrTPMMachines AS nvarchar(500)
Declare @StrMPlantid NVarChar(255)
Declare @timeformat as nvarchar(12)
Declare @StartTime as datetime
Declare @EndTime as datetime
Declare @strXmachine NVarChar(255)
Declare @strXcomponentid NVarChar(255)
Declare @strXoperation NVarChar(255)
Declare @StrGroupID AS NVarchar(255)


Select @strsql = ''
Select @strcomponentid = ''
Select @stroperation = ''
Select @StrTPMMachines = ''
Select @strmachine = ''
Select @StrMPlantid=''
Select @strXmachine =''
Select @strXcomponentid =''
Select @strXoperation =''
select @StrGroupID=''


-- mod 4
IF ( SELECT TOP 1 ValueInText FROM  CockpitDefaults WHERE Parameter='TpmEnbMac')='E'
BEGIN
	SET  @StrTPMMachines = 'AND MachineInformation.TPMTrakEnabled = 1'
END
ELSE
BEGIN
	SET  @StrTPMMachines = ' '
END
--mod 4
if isnull(@PlantID,'') <> ''
Begin
	---mod 2
--	Select @StrMPlantid = ' and ( PlantMachine.PlantID = ''' + @PlantID + ''')'
	Select @StrMPlantid = ' and ( PlantMachine.PlantID = N''' + @PlantID + ''')'
	---mod 2
End
if isnull(@machineid,'') <> ''
Begin
	---mod 2
--	Select @strmachine = ' and ( Machineinformation.MachineID = ''' + @MachineID + ''')'
--	Select @strXmachine = ' and ( EX.MachineID = ''' + @MachineID + ''')'
	Select @strmachine = ' and ( Machineinformation.MachineID = N''' + @MachineID + ''')'
	Select @strXmachine = ' and ( EX.MachineID = N''' + @MachineID + ''')'	
---mod 2
End
if isnull(@componentid,'') <> ''
Begin
	---mod 2
--	Select @strcomponentid = ' AND ( Componentinformation.componentid = ''' + @componentid + ''')'
--	Select @strXcomponentid = ' AND ( EX.componentid = ''' + @componentid + ''')'
	Select @strcomponentid = '  AND ( Componentinformation.componentid = N''' + @componentid + ''')'
	Select @strXcomponentid = ' AND ( EX.componentid = N''' + @componentid + ''')'
	---mod 2
End
if isnull(@operationno, '') <> ''
Begin
	---mod 2
--	Select @stroperation = ' AND ( Componentoperationpricing.operationno = ' + @OperationNo +')'
--	Select @strXoperation = ' AND ( EX.operationno = ' + @OperationNo +')'
	Select @stroperation = ' AND ( Componentoperationpricing.operationno = N''' + @OperationNo + ''')'
	Select @strXoperation = ' AND ( EX.operationno = N''' + @OperationNo + ''')'
	---mdo 2
End

If isnull(@GroupID ,'') <> ''
Begin
Select @StrGroupID = ' And ( PlantMachineGroups.GroupID = N''' + @GroupID + ''')'
End

CREATE TABLE #Exceptions
(
	MachineID NVarChar(50),
	ComponentID Nvarchar(50),
	OperationNo Int,
	StartTime DateTime,
	EndTime DateTime,
	--NR0097
	--IdealCount Int,
	--ActualCount Int,
	--ExCount Int DEFAULT 0
	IdealCount float,
	ActualCount float,
	ExCount float DEFAULT 0
	--NR0097
)
--Shift Details
CREATE TABLE #DailyProductionFromAutodataT0 (
	DDate datetime,
	Shift nvarchar(20),
	ShiftStart datetime,
	ShiftEnd datetime,
	shiftid nvarchar(20)
)
--Machine level details
CREATE TABLE #DailyProductionFromAutodataT1 (
	MachineID nvarchar(50) NOT NULL,
	GroupID nvarchar(50),
	MachineInterface nvarchar(50),
	ProductionEfficiency float,
	AvailabilityEfficiency float,
	OverallEfficiency float,
	UtilisedTime float,
	ManagementLoss float,
	DownTime float,
	CN float,
	Pdate datetime NOT NULL,
	FromTime datetime,
	ToTime datetime,
	---mod 4 Added MLDown to store genuine downs which is contained in Management loss
	MLDown float,
	QualityEfficiency float,
	RejCount float
	---mod 4
--CONSTRAINT DailyProductionFromAutodataT1_key PRIMARY KEY (MachineID)
)
ALTER TABLE #DailyProductionFromAutodataT1 ADD
	 PRIMARY KEY  CLUSTERED
	(       [Pdate],
		[MachineID]
	)  ON [PRIMARY]

 
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

print 'Insert into #T_autodata'

select @StartTime=dbo.f_GetLogicalDay(@StartDate,'start')
select @EndTime=dbo.f_GetLogicalDay(@EndDate,'end')

Select @strsql=''  
select @strsql ='insert into #T_autodata  
				SELECT mc, comp, opn, opr, dcode,sttime, ndtime, datatype, cycletime, loadunload, msttime, 
				PartsCount,id from autodata where (( sttime >='''+ convert(nvarchar(25),@StartTime,120)+''' 
				and ndtime <= '''+ convert(nvarchar(25),@EndTime,120)+''' )
				OR  ( sttime <'''+ convert(nvarchar(25),@StartTime,120)+''' and ndtime >'''+ convert(nvarchar(25),@EndTime,120)+''' )  
				OR ( sttime <'''+ convert(nvarchar(25),@StartTime,120)+''' and ndtime >'''+ convert(nvarchar(25),@StartTime,120)+'''  
				and ndtime<='''+convert(nvarchar(25),@EndTime,120)+''' ) 
				OR ( sttime >='''+convert(nvarchar(25),@StartTime,120)+''' and ndtime >'''+ convert(nvarchar(25),@EndTime,120)+''' 
				and sttime<'''+convert(nvarchar(25),@EndTime,120)+''' ) )'  
print @strsql  
exec (@strsql)  

-- ER0465 g:
--CREATE TABLE #T_autodata(  
-- [mc] [nvarchar](50)not NULL,  
-- [comp] [nvarchar](50) NULL,  
-- [opn] [nvarchar](50) NULL,  
-- [opr] [nvarchar](50) NULL,  
-- [dcode] [nvarchar](50) NULL,  
-- [sttime] [datetime] not NULL,  
-- [ndtime] [datetime] not NULL,  
-- [datatype] [tinyint] NULL ,  
-- [cycletime] [int] NULL,  
-- [loadunload] [int] NULL ,  
-- [msttime] [datetime] not NULL,  
-- [PartsCount] decimal(18,5) NULL ,  
-- id  bigint not null  
--)  
  
--ALTER TABLE #T_autodata  
  
--ADD PRIMARY KEY CLUSTERED  
--(  
-- mc,sttime,ndtime,msttime ASC  
--)ON [PRIMARY] 

--Select @strsql=''  
--select @strsql ='insert into #T_autodata '  
--select @strsql = @strsql + 'SELECT mc, comp, opn, opr, dcode,sttime,'  
-- select @strsql = @strsql + 'ndtime, datatype, cycletime, loadunload, msttime, PartsCount,id'  
--select @strsql = @strsql + ' from autodata where (( sttime >='''+ convert(nvarchar(25),@StartDate,120)+''' and ndtime <= '''+ convert(nvarchar(25),@EndDate,120)+''' ) OR '  
--select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@StartDate,120)+''' and ndtime >'''+ convert(nvarchar(25),@EndDate,120)+''' )OR '  
--select @strsql = @strsql + '( sttime <'''+ convert(nvarchar(25),@StartDate,120)+''' and ndtime >'''+ convert(nvarchar(25),@StartDate,120)+'''  
--     and ndtime<='''+convert(nvarchar(25),@EndDate,120)+''' )'  
--select @strsql = @strsql + ' OR ( sttime >='''+convert(nvarchar(25),@StartDate,120)+''' and ndtime >'''+ convert(nvarchar(25),@EndDate,120)+''' and sttime<'''+convert(nvarchar(25),@EndDate,120)+''' ) )'  
--print @strsql  
--exec (@strsql) 

--ER0465 g:/


--ComponentOperation level details
CREATE TABLE #DailyProductionFromAutodataT2 (
	Cdate datetime not null,
	MachineID nvarchar(50) NOT NULL,
	GroupID nvarchar(50),
	Component nvarchar(50) NOT NULL,
	Operation nvarchar(50) NOT NULL,
	CycleTime float,
	LoadUnload float,
--DR0325 From here
	AvgCycleTime float, --NR0097 Uncommented
	AvgLoadUnload float, --NR0097 Uncommented
	--AvgCycleTime Nvarchar(25),
	--AvgLoadUnload Nvarchar(25),
--DR0325 Till here
--NR0097 From here
	--CountShift1 int,
	--CountShift2 int,
	--CountShift3 int,
	CountShift1 float,
	CountShift2 float,
	CountShift3 float,
	CountShiftTotal float,
--NR0097 Till Here
	NameShift1 nvarchar(20),
	NameShift2 nvarchar(20),
	NameShift3 nvarchar(20),
	TargetCount int Default 0,
	FromTm datetime,
	ToTm datetime
--CONSTRAINT DailyProductionFromAutodataT2_key PRIMARY KEY (MachineID,Component,Operation)
)
ALTER TABLE #DailyProductionFromAutodataT2 ADD
	 PRIMARY KEY  CLUSTERED
	(
		[Cdate],[MachineID],[Component],[Operation]
		
	)  ON [PRIMARY]
--CREATE TABLE #PLD
--(
--	Pdate datetime NOT NULL,
--	MachineID nvarchar(50),
--	MachineInterface nvarchar(50),
--	pPlannedDT float Default 0,
--	dPlannedDT float Default 0,
--	MPlannedDT float Default 0,
--	IPlannedDT float Default 0,
--	DownID nvarchar(50)
--)
Create table #PlannedDownTimes
(
	MachineID nvarchar(50),
	MachineInterface nvarchar(50),
	StartTime_LogicalDay DateTime,
	EndTime_LogicalDay DateTime,
	StartTime_PDT DateTime,
	EndTime_PDT DateTime,
	pPlannedDT float Default 0,
	dPlannedDT float Default 0,
	MPlannedDT float Default 0,
	IPlannedDT float Default 0,
	DownID nvarchar(50)
)
declare @Targetsource nvarchar(50)
select @Targetsource=ValueInText from Shopdefaults where Parameter='TargetFrom'


  
----mod 4
--/* Planned Down times for the given time period */
--SET @strSql = ''
--SET @strSql = 'Insert into #PlannedDownTimes
--	SELECT Machine,InterfaceID,
--		CASE When StartTime<''' + convert(nvarchar(20),dbo.f_GetLogicalDay(@StartDate,'start'),120)+''' Then ''' + convert(nvarchar(20),dbo.f_GetLogicalDay(@StartDate,'start'),120)+''' Else StartTime End As StartTime,
--		CASE When EndTime>''' + convert(nvarchar(20),dbo.f_GetLogicalDay(@EndDate,'End'),120)+''' Then ''' + convert(nvarchar(20),dbo.f_GetLogicalDay(@EndDate,'End'),120)+''' Else EndTime End As EndTime
--	FROM PlannedDownTimes inner join MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID
--	WHERE PDTstatus =1 and(
--	(StartTime >= ''' + convert(nvarchar(20),dbo.f_GetLogicalDay(@StartDate,'start'),120)+''' AND EndTime <=''' + convert(nvarchar(20),dbo.f_GetLogicalDay(@EndDate,'End'),120)+''')
--	OR ( StartTime < ''' + convert(nvarchar(20),dbo.f_GetLogicalDay(@StartDate,'start'),120)+'''  AND EndTime <= ''' + convert(nvarchar(20),dbo.f_GetLogicalDay(@EndDate,'End'),120)+''' AND EndTime > ''' + convert(nvarchar(20),dbo.f_GetLogicalDay(@StartDate,'start'),120)+''' )
--	OR ( StartTime >= ''' + convert(nvarchar(20),dbo.f_GetLogicalDay(@StartDate,'start'),120)+'''   AND StartTime <''' + convert(nvarchar(20),dbo.f_GetLogicalDay(@EndDate,'End'),120)+''' AND EndTime > ''' + convert(nvarchar(20),dbo.f_GetLogicalDay(@EndDate,'End'),120)+''' )
--	OR ( StartTime < ''' + convert(nvarchar(20),dbo.f_GetLogicalDay(@StartDate,'start'),120)+'''  AND EndTime > ''' + convert(nvarchar(20),dbo.f_GetLogicalDay(@EndDate,'End'),120)+''')) '
--SET @strSql =  @strSql + @strMachine + @StrTPMMachines + ' ORDER BY Machine,StartTime'
--EXEC(@strSql)
----mod 4
select @StartTime=@StartDate
select @EndTime=@EndDate

Declare @lstart AS nvarchar(50) --ER0465
Declare @lend AS nvarchar(50) --ER0465

while @StartTime<=@EndTime
BEGIN
	SET @lstart = dbo.f_GetLogicalDay(@StartTime,'start') --ER0465
	SET @lend = dbo.f_GetLogicalDay(@StartTime,'End') --ER0465
	If ISNULL(@PlantID,'')<>''
	BEGIN
		if isnull(@machineid,'')<> ''
		begin
			--INSERT INTO #DailyProductionFromAutodataT1 (MachineID,MachineInterface,ProductionEfficiency,
			--AvailabilityEfficiency,OverallEfficiency,UtilisedTime,ManagementLoss,DownTime,CN,Pdate,FromTime,ToTime)
			--SELECT M.MachineID, M.interfaceid ,0,0,0,0,0,0,0,convert(nvarchar(20),@StartTime),
			--@lstart,@lend
			--FROM MachineInformation M Inner Join PlantMachine PM ON PM.MachineID=M.MachineID
			--WHERE M.MachineID = @machineid AND PM.PlantID=@PlantID

			SELECT @StrSql=''
			SELECT @StrSql='INSERT INTO #DailyProductionFromAutodataT1 (MachineID,GroupID,MachineInterface,ProductionEfficiency,
			AvailabilityEfficiency,OverallEfficiency,UtilisedTime,ManagementLoss,DownTime,CN,Pdate,FromTime,ToTime)'
			SELECT @StrSql=@StrSql+'SELECT MachineInformation.MachineID,PlantMachineGroups.GroupId ,MachineInformation.interfaceid ,0,0,0,0,0,0,0,''' +convert(nvarchar(20),@StartTime)+ ''', '
			SELECT @StrSql=@StrSql+' ''' +@lstart+ ''',''' +@lend+ ''' '
			SELECT @StrSql=@StrSql+'FROM MachineInformation  Inner Join PlantMachine PM ON PM.MachineID=MachineInformation.MachineID
									LEFT JOIN PlantMachineGroups ON  PlantMachineGroups.machineid = PM.MachineID and PlantMachineGroups.PlantID=PM.PlantID'
			SELECT @StrSql=@StrSql+' WHERE MachineInformation.MachineID = '''+ @machineid+''' AND PM.PlantID = ''' +@PlantID+''' '
			SELECT @StrSql=@StrSql+ @strmachine+ @StrGroupID
			Exec(@StrSql)
		end
		else
		begin
			--INSERT INTO #DailyProductionFromAutodataT1 (MachineID,MachineInterface,ProductionEfficiency,
			--AvailabilityEfficiency,OverallEfficiency,UtilisedTime,ManagementLoss,DownTime,CN,Pdate,FromTime,ToTime)
			--SELECT M.MachineID, M.interfaceid ,0,0,0,0,0,0,0,convert(nvarchar(20),@StartTime),
			--@lstart,@lend
			--FROM MachineInformation M Inner Join PlantMachine PM ON PM.MachineID=M.MachineID
			--where interfaceid > '0' AND PM.PlantID=@PlantID

			SELECT @StrSql=''
			SELECT @StrSql='INSERT INTO #DailyProductionFromAutodataT1 (MachineID,GroupID,MachineInterface,ProductionEfficiency,
			AvailabilityEfficiency,OverallEfficiency,UtilisedTime,ManagementLoss,DownTime,CN,Pdate,FromTime,ToTime)'
			SELECT @StrSql=@StrSql+'SELECT MachineInformation.MachineID,PlantMachineGroups.GroupId, MachineInformation.interfaceid ,0,0,0,0,0,0,0,''' +convert(nvarchar(20),@StartTime)+ ''', '
			SELECT @StrSql=@StrSql+' ''' +@lstart+ ''',''' +@lend+ ''' '
			SELECT @StrSql=@StrSql+'FROM MachineInformation  Inner Join PlantMachine PM ON PM.MachineID=MachineInformation.MachineID
									LEFT JOIN PlantMachineGroups ON  PlantMachineGroups.machineid = PM.MachineID and PlantMachineGroups.PlantID=PM.PlantID'
			SELECT @StrSql=@StrSql+' WHERE  interfaceid >''0'' AND pm.pLANTid = '''+@PlantID+ ''' '
			SELECT @StrSql=@StrSql+ @strmachine+@StrGroupID
			Exec(@StrSql)

		end
	END
	ELSE
	BEGIN
		SELECT @StrSql=''
		SELECT @StrSql='INSERT INTO #DailyProductionFromAutodataT1 ('
		SELECT @StrSql=@StrSql+' MachineID ,GroupID,MachineInterface,ProductionEfficiency ,AvailabilityEfficiency ,'			
		SELECT @StrSql=@StrSql+' OverallEfficiency ,UtilisedTime ,ManagementLoss,DownTime ,CN,Pdate,FromTime,ToTime)'
		SELECT @StrSql=@StrSql+' SELECT MachineInformation.MachineID,PlantMachineGroups.GroupId, MachineInformation.interfaceid ,0,0,0,0,0,0,0,''' +convert(nvarchar(20),@StartTime)+ ''', '
		SELECT @StrSql=@StrSql+' ''' +@lstart+ ''',''' +@lend+ ''' '
		SELECT @StrSql=@StrSql+' FROM MachineInformation 
								 LEFT JOIN PlantMachineGroups on MachineInformation.machineid = PlantMachineGroups.machineid  
								 where interfaceid >''0'''
		SELECT @StrSql=@StrSql+ @strmachine+@StrGroupID
		Exec(@StrSql)
		SELECT @StrSql=''
	END

	--mod 4 Get the Machines into #PLD
	Insert into #PlannedDownTimes
	Select machineinformation.MachineID,machineinformation.InterfaceID,@lstart,@lend,
	 Case When StartTime<@lstart Then @lstart Else StartTime End as StartTime, 	
	 Case When EndTime > @lend Then @lend Else EndTime End as EndTime,
	 0,0,0,0,PlannedDownTimes.DownReason
	 from PlannedDownTimes inner join machineinformation on PlannedDownTimes.machine=machineinformation.machineid
	      Where PlannedDownTimes.PDTstatus =1 AND (
		(StartTime >= @lstart and EndTime <= @lend) OR
		(StartTime < @lstart and EndTime <= @lend and EndTime > @lstart) OR
		(StartTime >= @lstart and EndTime > @lend and StartTime < @lend) OR
		(StartTime < @lstart and EndTime > @lend))
		And machineinformation.MachineID in (select distinct MachineID from #DailyProductionFromAutodataT1)
	--mod 4
	SELECT @StartTime=DATEADD(DAY,1,@StartTime)
END


--Get Logical day start and end
--select @StartTime = dbo.f_GetLogicalDay(@StartDate,'start')
--select @EndTime = dbo.f_GetLogicalDay(@StartDate,'end')
-- Get the utilised time
-- Type 1

UPDATE #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0) from (
	select mc,sum(cycletime+loadunload) as cycle,D.Pdate as date1
	from  #T_autodata autodata inner join #DailyProductionFromAutodataT1 D on autodata.mc=D.machineinterface
	where (autodata.msttime>=D.FromTime)and (autodata.ndtime<=D.ToTime)and (autodata.datatype=1)
	group by autodata.mc,D.Pdate
) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface
and t2.date1=#DailyProductionFromAutodataT1.Pdate

--Type 2
UPDATE #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0) from (
	select mc,sum(DateDiff(second, D.FromTime, ndtime)) cycle,D.Pdate as date1
	from  #T_autodata autodata inner join #DailyProductionFromAutodataT1 D on autodata.mc=D.machineinterface
	where (autodata.msttime<D.FromTime)and (autodata.ndtime>D.FromTime)and (autodata.ndtime<=D.ToTime)
	and (autodata.datatype=1) group by autodata.mc,D.Pdate
) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface
and t2.date1=#DailyProductionFromAutodataT1.Pdate

-- Type 3
UPDATE #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0) from (
	select mc,sum(DateDiff(second, mstTime, D.ToTime)) cycle,D.Pdate as date1
	from  #T_autodata autodata inner join #DailyProductionFromAutodataT1 D on autodata.mc=D.machineinterface
	where (autodata.msttime>=D.FromTime)and (autodata.msttime<D.ToTime)and (autodata.ndtime>D.ToTime)
	and (autodata.datatype=1)group by autodata.mc,D.Pdate
) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface
and t2.date1=#DailyProductionFromAutodataT1.Pdate

-- Type 4
UPDATE #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isnull(t2.cycle,0) from (
	select mc,sum(DateDiff(second, D.FromTime, D.ToTime)) cycle,D.Pdate as date1
	from  #T_autodata autodata inner join #DailyProductionFromAutodataT1 D on autodata.mc=D.machineinterface
	where (autodata.msttime<D.FromTime)and (autodata.ndtime>D.ToTime)and (autodata.datatype=1)
	group by autodata.mc,D.Pdate
)as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface
and t2.date1=#DailyProductionFromAutodataT1.Pdate

-- END: Get the utilised time
/* By Sangeeta Kallur */
/* Fetching Down Records from Production Cycle  */
/* If Down Records of TYPE-2*/
UPDATE  #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0) FROM (
	Select AutoData.mc,SUM(
		CASE
			When autodata.sttime <= D.FromTime Then datediff(s, D.FromTime,autodata.ndtime )
			When autodata.sttime > D.FromTime Then datediff(s , autodata.sttime,autodata.ndtime)
		END) as Down,D.Pdate as date1 from  #T_autodata autodata INNER Join (
			Select mc,Sttime,NdTime,D.Pdate from  #T_autodata autodata inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And (msttime < D.FromTime)And (ndtime > D.FromTime) AND (ndtime <= D.ToTime)
			) as T1
	ON AutoData.mc=T1.mc inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface And T1.Pdate=D.PDate
	Where AutoData.DataType=2
	And ( autodata.Sttime > T1.Sttime )And ( autodata.ndtime <  T1.ndtime )AND ( autodata.ndtime >  D.FromTime )
	GROUP BY AUTODATA.mc,D.Pdate
)AS T2 Inner Join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface and t2.date1=#DailyProductionFromAutodataT1.Pdate
print sysdatetime()--g:
/* If Down Records of TYPE-3*/
UPDATE  #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0) FROM (
	Select AutoData.mc,SUM(
		CASE
			When autodata.ndtime > D.ToTime Then datediff(s,autodata.sttime, D.ToTime )
			When autodata.ndtime <=D.ToTime Then datediff(s , autodata.sttime,autodata.ndtime)
		END) as Down,D.Pdate as date1 from  #T_autodata autodata INNER Join (
			Select mc,Sttime,NdTime,D.Pdate from  #T_autodata autodata inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And(sttime >= D.FromTime)And (ndtime > D.ToTime) And (sttime<D.ToTime)
			) as T1
	ON AutoData.mc=T1.mc inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface And T1.Pdate=D.PDate
	Where AutoData.DataType=2 And (T1.Sttime < autodata.sttime)And ( T1.ndtime >  autodata.ndtime)AND (autodata.sttime  <  D.ToTime)
	GROUP BY AUTODATA.mc,D.Pdate
)AS T2 Inner Join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface and t2.date1=#DailyProductionFromAutodataT1.Pdate
print sysdatetime()--g:
/* If Down Records of TYPE-4*/
UPDATE  #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0) FROM (
	Select AutoData.mc,
--DR0236 - By SwathiKS on 23-Jun-2010 from here
--		SUM(CASE
--			When autodata.sttime < D.FromTime AND autodata.ndtime<=D.ToTime Then datediff(s, D.FromTime,autodata.ndtime )
--			When autodata.ndtime >= D.ToTime AND autodata.sttime>D.FromTime Then datediff(s,autodata.sttime, D.ToTime )
--			When autodata.sttime >= D.FromTime AND autodata.ndtime <=D.ToTime Then datediff(s , autodata.sttime,autodata.ndtime)
--			When autodata.sttime<D.FromTime AND autodata.ndtime>D.ToTime Then datediff(s , D.FromTime,D.ToTime)
--		END) as Down,
		SUM(CASE
			When autodata.sttime >= D.FromTime AND autodata.ndtime <=D.ToTime Then datediff(s ,autodata.sttime,autodata.ndtime) --Type1
			When autodata.sttime < D.FromTime AND autodata.ndtime>D.FromTime AND autodata.ndtime<=D.ToTime Then datediff(s, D.FromTime,autodata.ndtime ) --Type2
			When autodata.sttime>=D.FromTime AND autodata.sttime<D.ToTime AND autodata.ndtime > D.ToTime Then datediff(s,autodata.sttime, D.ToTime ) --Type3
			When autodata.sttime<D.FromTime AND autodata.ndtime>D.ToTime Then datediff(s ,D.FromTime,D.ToTime)--Type4
		END) as Down,
--DR0236 - By SwathiKS on 23-Jun-2010 till here
			D.Pdate as date1 from  #T_autodata autodata INNER Join (
			Select mc,Sttime,NdTime,D.Pdate from  #T_autodata autodata inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And(msttime < D.FromTime)And (ndtime > D.ToTime)
			) as T1
	ON AutoData.mc=T1.mc inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface And T1.Pdate=D.PDate
	Where AutoData.DataType=2 And (T1.Sttime < autodata.sttime)And
(T1.ndtime >  autodata.ndtime) AND (autodata.ndtime  >  D.FromTime) AND (autodata.sttime  <  D.ToTime)
	GROUP BY AUTODATA.mc,D.Pdate
)AS T2 Inner Join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface and t2.date1=#DailyProductionFromAutodataT1.Pdate
--mod 4:Get utilised time over lapping with PDT.

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
BEGIN
	--Detect Utilised Time over lapping with PDT
	UPDATE #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.cycle,0) from (
		select mc,StartTime_LogicalDay,EndTime_LogicalDay,
		sum(Case
--			When (autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) then (autodata.cycletime+autodata.loadunload) --DR0325 Commented
			When (autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) then Datediff(s,autodata.msttime,autodata.ndtime) --DR0325 added
			When (autodata.msttime < StartTime_PDT and autodata.ndtime <= EndTime_PDT and autodata.ndtime > StartTime_PDT) then Datediff(s,StartTime_PDT,autodata.ndtime)
			When (autodata.msttime >= StartTime_PDT and autodata.ndtime > EndTime_PDT and autodata.msttime < EndTime_PDT) then Datediff(s,autodata.msttime,EndTime_PDT)
			When (autodata.msttime < StartTime_PDT and autodata.ndtime > EndTime_PDT) then Datediff(s,StartTime_PDT,EndTime_PDT)
		End) as cycle
		from  #T_autodata autodata inner join #PlannedDownTimes  on autodata.mc=#PlannedDownTimes.machineinterface
		where (autodata.datatype=1) AND
		((autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) or
		(autodata.msttime < StartTime_PDT and autodata.ndtime <= EndTime_PDT and autodata.ndtime > StartTime_PDT) or
		(autodata.msttime >= StartTime_PDT and autodata.ndtime > EndTime_PDT and autodata.msttime < EndTime_PDT) or
		(autodata.msttime < StartTime_PDT and autodata.ndtime > EndTime_PDT))
		group by autodata.mc,StartTime_LogicalDay,EndTime_LogicalDay
	) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface And
	t2.StartTime_LogicalDay=#DailyProductionFromAutodataT1.FromTime And t2.EndTime_LogicalDay=#DailyProductionFromAutodataT1.ToTime


	/* Fetching Down Records from Production Cycle  */
	/* If production  Records of TYPE-1*/
	--mod 4(4):Handle intearction between ICD and PDT for type 1 production record for the selected time period.
	UPDATE #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.icd,0) from (
		select autodata.mc,StartTime_LogicalDay,EndTime_LogicalDay,
		sum(Case
--			When (autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) then (autodata.cycletime+autodata.loadunload) --DR0325 Commented
			When (autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) then Datediff(s,autodata.msttime,autodata.ndtime) --DR0325 Added
			When (autodata.msttime < StartTime_PDT and autodata.ndtime <= EndTime_PDT and autodata.ndtime > StartTime_PDT) then Datediff(s,StartTime_PDT,autodata.ndtime)
			When (autodata.msttime >= StartTime_PDT and autodata.ndtime > EndTime_PDT and autodata.msttime < EndTime_PDT) then Datediff(s,autodata.msttime,EndTime_PDT)
			When (autodata.msttime < StartTime_PDT and autodata.ndtime > EndTime_PDT) then Datediff(s,StartTime_PDT,EndTime_PDT)
		End) as icd
		from  #T_autodata autodata inner join
			(Select mc,sttime,ndtime,D.fromtime from  #T_autodata autodata inner join #DailyProductionFromAutodataT1 D on autodata.mc = D.machineinterface
			 where datatype = 1 and Datediff(s,sttime,ndtime) > Cycletime and
			 (autodata.msttime >= D.fromtime and autodata.ndtime <= D.totime)
			 ) as t1 on 
		(autodata.sttime >= t1.sttime and autodata.ndtime <= t1.ndtime) --DR0339
		and Autodata.mc=t1.mc
		inner join 	#PlannedDownTimes  on autodata.mc=#PlannedDownTimes.machineinterface And t1.FromTime=#PlannedDownTimes.StartTime_LogicalDay
		where (autodata.datatype=2) AND
		((autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) or
		(autodata.msttime < StartTime_PDT and autodata.ndtime <= EndTime_PDT and autodata.ndtime > StartTime_PDT) or
		(autodata.msttime >= StartTime_PDT and autodata.ndtime > EndTime_PDT and autodata.msttime < EndTime_PDT) or
		(autodata.msttime < StartTime_PDT and autodata.ndtime > EndTime_PDT))
		group by autodata.mc,StartTime_LogicalDay,EndTime_LogicalDay
	) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface And
	t2.StartTime_LogicalDay=#DailyProductionFromAutodataT1.FromTime And t2.EndTime_LogicalDay=#DailyProductionFromAutodataT1.ToTime


	--mod 4(4):Handle intearction between ICD and PDT for type 1 production record for the selected time period.
	/* If production  Records of TYPE-2*/
	UPDATE #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.icd,0) from (
		select autodata.mc,StartTime_LogicalDay,EndTime_LogicalDay,
		sum(Case
--			When (autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) then (autodata.cycletime+autodata.loadunload) --DR0325 Commented
			When (autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) then  Datediff(s,autodata.msttime,autodata.ndtime) --DR0325 added
			When (autodata.msttime < StartTime_PDT and autodata.ndtime <= EndTime_PDT and autodata.ndtime > StartTime_PDT) then Datediff(s,StartTime_PDT,autodata.ndtime)
			When (autodata.msttime >= StartTime_PDT and autodata.ndtime > EndTime_PDT and autodata.msttime < EndTime_PDT) then Datediff(s,autodata.msttime,EndTime_PDT)
			When (autodata.msttime < StartTime_PDT and autodata.ndtime > EndTime_PDT) then Datediff(s,StartTime_PDT,EndTime_PDT)
		End) as icd
		from  #T_autodata autodata inner join
			(Select mc,sttime,ndtime,D.fromtime from  #T_autodata autodata inner join #DailyProductionFromAutodataT1 D on autodata.mc = D.machineinterface
			 where datatype = 1 and Datediff(s,sttime,ndtime) > Cycletime and
			 (autodata.msttime < D.fromtime and autodata.ndtime > D.totime and autodata.ndtime <= D.totime)
			 ) as t1 on (autodata.sttime > t1.sttime and autodata.ndtime < t1.ndtime) and Autodata.mc=t1.mc
		inner join 	#PlannedDownTimes  on autodata.mc=#PlannedDownTimes.machineinterface And t1.FromTime=#PlannedDownTimes.StartTime_LogicalDay
		where (autodata.datatype=2) AND
		((autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) or
		(autodata.msttime < StartTime_PDT and autodata.ndtime <= EndTime_PDT and autodata.ndtime > StartTime_PDT) or
		(autodata.msttime >= StartTime_PDT and autodata.ndtime > EndTime_PDT and autodata.msttime < EndTime_PDT) or
		(autodata.msttime < StartTime_PDT and autodata.ndtime > EndTime_PDT))
		And (autodata.ndtime > T1.FromTime) And (StartTime_PDT <  T1.ndtime)
		group by autodata.mc,StartTime_LogicalDay,EndTime_LogicalDay
	) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface And
	t2.StartTime_LogicalDay=#DailyProductionFromAutodataT1.FromTime And t2.EndTime_LogicalDay=#DailyProductionFromAutodataT1.ToTime

	/* If production  Records of TYPE-3*/
	UPDATE #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.icd,0) from (
		select autodata.mc,StartTime_LogicalDay,EndTime_LogicalDay,
		sum(Case
--			When (autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) then (autodata.cycletime+autodata.loadunload) --DR0325 Commented
			When (autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) then Datediff(s,autodata.msttime,autodata.ndtime) --DR0325 Added
			When (autodata.msttime < StartTime_PDT and autodata.ndtime <= EndTime_PDT and autodata.ndtime > StartTime_PDT) then Datediff(s,StartTime_PDT,autodata.ndtime)
			When (autodata.msttime >= StartTime_PDT and autodata.ndtime > EndTime_PDT and autodata.msttime < EndTime_PDT) then Datediff(s,autodata.msttime,EndTime_PDT)
			When (autodata.msttime < StartTime_PDT and autodata.ndtime > EndTime_PDT) then Datediff(s,StartTime_PDT,EndTime_PDT)
		End) as icd
		from  #T_autodata autodata inner join
			(Select mc,sttime,ndtime,D.fromtime,D.ToTime from  #T_autodata autodata inner join #DailyProductionFromAutodataT1 D on autodata.mc = D.machineinterface
			 where datatype = 1 and Datediff(s,sttime,ndtime) > Cycletime and
			 (autodata.sttime >= D.fromtime and autodata.ndtime > D.totime and autodata.sttime < D.totime)
			 ) as t1 on (autodata.sttime > t1.sttime and autodata.ndtime < t1.ndtime) and Autodata.mc=t1.mc
		inner join 	#PlannedDownTimes  on autodata.mc=#PlannedDownTimes.machineinterface And t1.FromTime=#PlannedDownTimes.StartTime_LogicalDay
		where (autodata.datatype=2) AND
		((autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) or
		(autodata.msttime < StartTime_PDT and autodata.ndtime <= EndTime_PDT and autodata.ndtime > StartTime_PDT) or
		(autodata.msttime >= StartTime_PDT and autodata.ndtime > EndTime_PDT and autodata.msttime < EndTime_PDT) or
		(autodata.msttime < StartTime_PDT and autodata.ndtime > EndTime_PDT))
		And (autodata.sttime < T1.ToTime) And (EndTime_PDT > t1.sttime)
		group by autodata.mc,StartTime_LogicalDay,EndTime_LogicalDay
	) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface And
	t2.StartTime_LogicalDay=#DailyProductionFromAutodataT1.FromTime And t2.EndTime_LogicalDay=#DailyProductionFromAutodataT1.ToTime


	/* If production  Records of TYPE-4*/
	UPDATE #DailyProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.icd,0) from (
		select autodata.mc,StartTime_LogicalDay,EndTime_LogicalDay,
		sum(Case
--			When (autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) then (autodata.cycletime+autodata.loadunload) --DR0325 Commented
			When (autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) then Datediff(s,autodata.msttime,autodata.ndtime) --DR0325 added
			When (autodata.msttime < StartTime_PDT and autodata.ndtime <= EndTime_PDT and autodata.ndtime > StartTime_PDT) then Datediff(s,StartTime_PDT,autodata.ndtime)
			When (autodata.msttime >= StartTime_PDT and autodata.ndtime > EndTime_PDT and autodata.msttime < EndTime_PDT) then Datediff(s,autodata.msttime,EndTime_PDT)
			When (autodata.msttime < StartTime_PDT and autodata.ndtime > EndTime_PDT) then Datediff(s,StartTime_PDT,EndTime_PDT)
		End) as icd
		from  #T_autodata autodata inner join
			(Select mc,sttime,ndtime,D.fromtime,D.totime from  #T_autodata autodata inner join #DailyProductionFromAutodataT1 D on autodata.mc = D.machineinterface
			 where datatype = 1 and Datediff(s,sttime,ndtime) > Cycletime and
			 (autodata.msttime < D.fromtime and autodata.ndtime > D.totime)
			 ) as t1 on (autodata.sttime > t1.sttime and autodata.ndtime < t1.ndtime) and Autodata.mc=t1.mc
		inner join 	#PlannedDownTimes  on autodata.mc=#PlannedDownTimes.machineinterface And t1.FromTime=#PlannedDownTimes.StartTime_LogicalDay
		where (autodata.datatype=2) AND
		((autodata.msttime >= StartTime_PDT and autodata.ndtime <= EndTime_PDT) or
		(autodata.msttime < StartTime_PDT and autodata.ndtime <= EndTime_PDT and autodata.ndtime > StartTime_PDT) or
		(autodata.msttime >= StartTime_PDT and autodata.ndtime > EndTime_PDT and autodata.msttime < EndTime_PDT) or
		(autodata.msttime < StartTime_PDT and autodata.ndtime > EndTime_PDT))
		And (autodata.ndtime>t1.FromTime and Autodata.sttime < t1.totime)
		group by autodata.mc,StartTime_LogicalDay,EndTime_LogicalDay
	) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface And
	t2.StartTime_LogicalDay=#DailyProductionFromAutodataT1.FromTime And t2.EndTime_LogicalDay=#DailyProductionFromAutodataT1.ToTime
END
print sysdatetime()--g:



--ManagementLoss and Downtime Calculation Starts
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y')
BEGIN
		--Down Time
		--Type 1
		UPDATE #DailyProductionFromAutodataT1 SET downtime = isnull(downtime,0) + isNull(t2.down,0)
		from
		(select mc,
			sum(loadunload) down,D.Pdate as date1
		from  #T_autodata autodata inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface
		where (autodata.msttime>=D.FromTime)
		and (autodata.ndtime<=D.ToTime)
		and (autodata.datatype=2)
		group by autodata.mc,D.Pdate
		) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface
		and t2.date1=#DailyProductionFromAutodataT1.Pdate
		-- Type 2
		UPDATE #DailyProductionFromAutodataT1 SET downtime = isnull(downtime,0) + isNull(t2.down,0)
		from
		(select mc,
			sum(DateDiff(second, D.FromTime, ndtime)) down,D.Pdate as date1
		from  #T_autodata autodata inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface
		where (autodata.sttime<D.FromTime)
		and (autodata.ndtime>D.FromTime)
		and (autodata.ndtime<=D.ToTime)
		and (autodata.datatype=2)
		group by autodata.mc,D.Pdate
		) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface
		and t2.date1=#DailyProductionFromAutodataT1.Pdate
		-- Type 3
		UPDATE #DailyProductionFromAutodataT1 SET downtime = isnull(downtime,0) + isNull(t2.down,0)
		from
		(select mc,
			sum(DateDiff(second, stTime, D.ToTime)) down,D.Pdate as date1
		from  #T_autodata autodata inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface
		where (autodata.msttime>=D.FromTime)
		and (autodata.sttime<D.ToTime)
		and (autodata.ndtime>D.ToTime)
		and (autodata.datatype=2)group by autodata.mc,D.Pdate
		) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface
		and t2.date1=#DailyProductionFromAutodataT1.Pdate
		-- Type 4
		UPDATE #DailyProductionFromAutodataT1 SET downtime = isnull(downtime,0) + isNull(t2.down,0)
		from
		(select mc,
			sum(DateDiff(second, D.FromTime, D.ToTime)) down,D.Pdate as date1
		from  #T_autodata autodata inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface
		where autodata.msttime<D.FromTime
		and autodata.ndtime>D.ToTime
		and (autodata.datatype=2)
		group by autodata.mc,D.Pdate
		) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface
		and t2.date1=#DailyProductionFromAutodataT1.Pdate
		--ManagementLoss Type 1
		UPDATE #DailyProductionFromAutodataT1 SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
		from
		(select      mc,
			sum(case
		when isnull(loadunload,0)>isnull(downcodeinformation.threshold,0) AND isnull(downcodeinformation.threshold,0) > 0 THEN isnull(downcodeinformation.threshold,0)
		ELSE loadunload
		END) loss,D.Pdate as date1
		from  #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface
		where (autodata.msttime>=D.FromTime)
		and (autodata.ndtime<=D.ToTime)
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1)
		group by autodata.mc,D.Pdate
		) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface
		and t2.date1=#DailyProductionFromAutodataT1.Pdate
		-- Type 2
		UPDATE #DailyProductionFromAutodataT1 SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
		from
		(select      mc,
			sum(CASE
		WHEN DateDiff(second, D.FromTime, ndtime) >isnull(downcodeinformation.threshold,0) AND isnull(downcodeinformation.threshold,0) > 0 THEN isnull(downcodeinformation.threshold,0)
		ELSE DateDiff(second, D.FromTime, ndtime)
		END) loss,D.Pdate as date1
		from  #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface
		where (autodata.sttime<D.FromTime)
		and (autodata.ndtime>D.FromTime)
		and (autodata.ndtime<=D.ToTime)
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1)
		group by autodata.mc,D.Pdate
		) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface
		and t2.date1=#DailyProductionFromAutodataT1.Pdate
		-- Type 3
		UPDATE #DailyProductionFromAutodataT1 SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
		from
		(select      mc,
			sum(CASE
		WHEN DateDiff(second, stTime, D.ToTime) >isnull(downcodeinformation.threshold,0) AND isnull(downcodeinformation.threshold,0) > 0 THEN isnull(downcodeinformation.threshold,0)
		ELSE DateDiff(second, stTime, D.ToTime)
		END) loss,D.Pdate as date1
		from  #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface
		where (autodata.msttime>=D.FromTime)
		and (autodata.sttime<D.ToTime)
		and (autodata.ndtime>D.ToTime)
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1)
		group by autodata.mc,D.Pdate
		) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface
		and t2.date1=#DailyProductionFromAutodataT1.Pdate
		-- Type 4
		UPDATE #DailyProductionFromAutodataT1 SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
		from
		(select mc,
			sum(CASE
		WHEN DateDiff(second, D.FromTime, D.ToTime)>isnull(downcodeinformation.threshold,0) AND isnull(downcodeinformation.threshold,0) > 0 THEN isnull(downcodeinformation.threshold,0)
		ELSE DateDiff(second, D.FromTime, D.ToTime)
		END ) loss,D.Pdate as date1
		from  #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface
		where autodata.msttime<D.FromTime
		and autodata.ndtime>D.ToTime
		and (autodata.datatype=2)
		and (downcodeinformation.availeffy = 1)
		group by autodata.mc,D.Pdate
		) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface
		and t2.date1=#DailyProductionFromAutodataT1.Pdate
End
print sysdatetime()--g:

---mod 4: Handling interaction between PDT and downtime . Also interaction between PDT and Management Loss
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN
	---step 1
	UPDATE #DailyProductionFromAutodataT1 SET downtime = isnull(downtime,0) + isNull(t2.down,0)	from (
		select mc,D.FromTime,D.ToTime,sum(
			CASE
				WHEN  autodata.msttime>=D.FromTime  and  autodata.ndtime<=D.ToTime  THEN  loadunload
				WHEN (autodata.sttime<D.FromTime and  autodata.ndtime>D.FromTime and autodata.ndtime<=D.ToTime)  THEN DateDiff(second, D.FromTime, ndtime)
				WHEN (autodata.msttime>=D.FromTime  and autodata.sttime<D.ToTime  and autodata.ndtime>D.ToTime)  THEN DateDiff(second, stTime, D.ToTime)
				WHEN autodata.msttime<D.FromTime and autodata.ndtime>D.ToTime   THEN DateDiff(second, D.FromTime, D.ToTime)
			END
			)AS down
		from  #T_autodata autodata inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		inner join #DailyProductionFromAutodataT1 D on autodata.mc = D.MachineInterface
		where autodata.datatype=2 AND
		(
		(autodata.msttime>=D.FromTime  and  autodata.ndtime<=D.ToTime)
		OR (autodata.sttime<D.FromTime and  autodata.ndtime>D.FromTime and autodata.ndtime<=D.ToTime)
		OR (autodata.msttime>=D.FromTime  and autodata.sttime<D.ToTime  and autodata.ndtime>D.ToTime)
		OR (autodata.msttime<D.FromTime and autodata.ndtime>D.ToTime )
		) AND (downcodeinformation.availeffy = 0)
		group by autodata.mc,D.FromTime,D.ToTime
	) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface
	And t2.FromTime = #DailyProductionFromAutodataT1.FromTime
	And t2.ToTime = #DailyProductionFromAutodataT1.ToTime
	--step 2
	---mod 4 checking for (downcodeinformation.availeffy = 0) to get the overlapping PDT and Downs which is not ML
	UPDATE #DailyProductionFromAutodataT1 set DownTime =isnull(DownTime,0) - isNull(TT.PPDT ,0)
	FROM(
		SELECT autodata.MC,StartTime_LogicalDay,EndTime_LogicalDay,SUM
		   (CASE
			WHEN autodata.sttime >= T.StartTime_PDT  AND autodata.ndtime <=T.EndTime_PDT  THEN (autodata.loadunload)
			WHEN ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime <= T.EndTime_PDT  AND autodata.ndtime > T.StartTime_PDT ) THEN DateDiff(second,T.StartTime_PDT,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime_PDT   AND autodata.sttime <T.EndTime_PDT  AND autodata.ndtime > T.EndTime_PDT  ) THEN DateDiff(second,autodata.sttime,T.EndTime_PDT )
			WHEN ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime > T.EndTime_PDT ) THEN DateDiff(second,T.StartTime_PDT,T.EndTime_PDT )
			END ) as PPDT
		from  #T_autodata autodata CROSS jOIN #PlannedDownTimes T
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
			(
			(autodata.sttime >= T.StartTime_PDT  AND autodata.ndtime <=T.EndTime_PDT)
			OR ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime <= T.EndTime_PDT AND autodata.ndtime > T.StartTime_PDT )
			OR ( autodata.sttime >= T.StartTime_PDT   AND autodata.sttime <T.EndTime_PDT AND autodata.ndtime > T.EndTime_PDT )
			OR ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime > T.EndTime_PDT)
			)
			AND (downcodeinformation.availeffy = 0)
		group by autodata.MC,StartTime_LogicalDay,EndTime_LogicalDay
	) as TT INNER JOIN #DailyProductionFromAutodataT1 ON TT.mc = #DailyProductionFromAutodataT1.MachineInterface And
	TT.StartTime_LogicalDay = #DailyProductionFromAutodataT1.FromTime and TT.EndTime_LogicalDay = #DailyProductionFromAutodataT1.ToTime
	---step 3
	---Management loss calculation
	---IN T1 Select get all the downtimes which is of type management loss
	---IN T2  get the time to be deducted from the cycle if the cycle is overlapping with the PDT. And it should be ML record
	---In T3 Get the real management loss , and time to be considered as real down for each cycle(by comaring with the ML threshold)
	---In T4 consolidate everything at machine level and update the same to #CockpitData for ManagementLoss and MLDown
	UPDATE #DailyProductionFromAutodataT1 SET  ManagementLoss = isnull(ManagementLoss,0) + isNull(t4.Mloss,0),MLDown=isNull(MLDown,0)+isNull(t4.Dloss,0) from (
			select T3.mc,T3.FromTime,T3.ToTime,sum(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss from (
	
				select  t1.id,T1.mc,T1.Threshold,T1.FromTime,T1.Totime,
				case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0
				then DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)- isnull(T1.Threshold ,0)
				else 0 End  as Dloss,
				case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0)>0
				then isnull(T1.Threshold,0)
				else (DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)) End  as Mloss
				 from
				(   select id,mc,comp,opn,opr,DC.threshold,D.FromTime,D.ToTime,
						case when autodata.sttime<D.FromTime then D.FromTime else sttime END as sttime,
						case when ndtime>D.ToTime then D.ToTime else ndtime END as ndtime
					from  #T_autodata autodata inner join downcodeinformation DC on autodata.dcode=DC.interfaceid
					CROSS jOIN #DailyProductionFromAutodataT1 D
					where autodata.datatype=2 And D.MachineInterface=autodata.mc and
					(
					(autodata.sttime>=D.FromTime  and  autodata.ndtime<=D.ToTime)
					OR (autodata.sttime<D.FromTime and  autodata.ndtime>D.FromTime and autodata.ndtime<=D.ToTime)
					OR (autodata.sttime>=D.FromTime  and autodata.sttime<D.ToTime  and autodata.ndtime>D.ToTime)
					OR (autodata.sttime<D.FromTime and autodata.ndtime>D.ToTime )
					) AND (DC.availeffy = 1)) as T1 	
				left outer join
				(SELECT autodata.id,T.StartTime_LogicalDay,T.EndTime_LogicalDay,
						   sum(CASE
						WHEN autodata.sttime >= T.StartTime_PDT  AND autodata.ndtime <=T.EndTime_PDT  THEN (autodata.loadunload)
						WHEN ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime <= T.EndTime_PDT  AND autodata.ndtime > T.StartTime_PDT ) THEN DateDiff(second,T.StartTime_PDT,autodata.ndtime)
						WHEN ( autodata.sttime >= T.StartTime_PDT   AND autodata.sttime <T.EndTime_PDT  AND autodata.ndtime > T.EndTime_PDT  ) THEN DateDiff(second,autodata.sttime,T.EndTime_PDT )
						WHEN ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime > T.EndTime_PDT ) THEN DateDiff(second,T.StartTime_PDT,T.EndTime_PDT )
						END ) as PPDT
					from  #T_autodata autodata CROSS jOIN #PlannedDownTimes T
					inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
					WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
						((autodata.sttime >= T.StartTime_PDT  AND autodata.ndtime <=T.EndTime_PDT)
						OR ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime <= T.EndTime_PDT AND autodata.ndtime > T.StartTime_PDT )
						OR ( autodata.sttime >= T.StartTime_PDT   AND autodata.sttime <T.EndTime_PDT AND autodata.ndtime > T.EndTime_PDT )
						OR ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime > T.EndTime_PDT))
						AND (downcodeinformation.availeffy = 1) group  by autodata.id,T.starttime_LogicalDay,T.EndTime_LogicalDay
					) as T2 on T1.id=T2.id and T2.starttime_LogicalDay=T1.FromTime and T2.EndTime_LogicalDay=T1.ToTime
			) as T3  group by T3.mc,T3.FromTime,T3.ToTime
		) as t4 inner join #DailyProductionFromAutodataT1 on t4.mc = #DailyProductionFromAutodataT1.machineinterface And
		t4.FromTime = #DailyProductionFromAutodataT1.FromTime and  t4.ToTime = #DailyProductionFromAutodataT1.ToTime
	UPDATE #DailyProductionFromAutodataT1 SET downtime = isnull(downtime,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)
--s_GetDailyProductionReportFromAutodata_Kiswok '2009-12-01','','','','','2009-12-02'MCV 500
End

print sysdatetime()--g:

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y' AND (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
Begin
	UPDATE #DailyProductionFromAutodataT1 set downtime =isnull(downtime,0) - isNull(t1.PPDT ,0)
	FROM(
		--Production PDT
		SELECT autodata.MC,T.StartTime_LogicalDay,T.EndTime_LogicalDay, SUM
		       (CASE
			WHEN autodata.sttime >= T.StartTime_PDT  AND autodata.ndtime <=T.EndTime_PDT  THEN (autodata.loadunload)
			WHEN ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime <= T.EndTime_PDT  AND autodata.ndtime > T.StartTime_PDT ) THEN DateDiff(second,T.StartTime_PDT,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime_PDT   AND autodata.sttime <T.EndTime_PDT  AND autodata.ndtime > T.EndTime_PDT  ) THEN DateDiff(second,autodata.sttime,T.EndTime_PDT )
			WHEN ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime > T.EndTime_PDT ) THEN DateDiff(second,T.StartTime_PDT,T.EndTime_PDT )
			END ) as PPDT
		from  #T_autodata autodata CROSS jOIN #PlannedDownTimes T
		Inner Join DownCodeInformation D ON AutoData.DCode = D.InterfaceID
		WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND D.DownID=(SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD') AND
			((autodata.sttime >= T.StartTime_PDT  AND autodata.ndtime <=T.EndTime_PDT)
			OR ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime <= T.EndTime_PDT AND autodata.ndtime > T.StartTime_PDT )
			OR ( autodata.sttime >= T.StartTime_PDT   AND autodata.sttime <T.EndTime_PDT AND autodata.ndtime > T.EndTime_PDT )
			OR ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime > T.EndTime_PDT))group by autodata.mc,T.StartTime_LogicalDay,T.EndTime_LogicalDay
	) as t1 INNER JOIN #DailyProductionFromAutodataT1 ON t1.mc = #DailyProductionFromAutodataT1.MachineInterface And
	t1.StartTime_LogicalDay = #DailyProductionFromAutodataT1.FromTime and t1.EndTime_LogicalDay = #DailyProductionFromAutodataT1.ToTime
	
End
print sysdatetime()--g:
--BEGIN: CN
--Type 1 and Type 2
UPDATE #DailyProductionFromAutodataT1 SET CN = isnull(CN,0) + isNull(t2.C1N1,0) from (
	select mc,--SUM(componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1)) C1N1
	SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))*autodata.partscount) C1N1,D.Pdate as date1
	from  #T_autodata autodata INNER JOIN
	componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
	componentinformation ON autodata.comp = componentinformation.InterfaceID AND
	componentoperationpricing.componentid = componentinformation.componentid
	inner join #DailyProductionFromAutodataT1 D on  Autodata.mc=D.machineinterface
	---mod 1
	inner join machineinformation on machineinformation.interfaceid=autodata.mc and componentoperationpricing.machineid=machineinformation.machineid
	---mod 1
	where (autodata.ndtime>D.FromTime)and (autodata.ndtime<=D.ToTime)and (autodata.datatype=1) group by autodata.mc,D.Pdate
) as t2 inner join #DailyProductionFromAutodataT1 on t2.mc = #DailyProductionFromAutodataT1.machineinterface
and t2.date1=#DailyProductionFromAutodataT1.Pdate
-- mod 4 Ignore count from CN calculation which is over lapping with PDT
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	UPDATE #DailyProductionFromAutodataT1 SET CN = isnull(CN,0) - isNull(t1.C1N1,0)
	From
	(
		select mc,T.StartTime_LogicalDay,T.EndTime_LogicalDay,
		SUM((O.cycletime * ISNULL(A.PartsCount,1))/ISNULL(O.SubOperations,1))  C1N1
		From  #T_autodata A
		Inner join machineinformation M on M.interfaceid=A.mc
		Inner join componentinformation C ON A.Comp=C.interfaceid
		Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid And O.MachineID = M.MachineID
		Cross jOIN #PlannedDownTimes T
		WHERE A.DataType=1 AND T.MachineInterface=A.mc AND (A.ndtime > T.StartTime_PDT AND A.ndtime <=T.EndTime_PDT)
		Group by mc,T.StartTime_LogicalDay,T.EndTime_LogicalDay
	) as t1
	inner join #DailyProductionFromAutodataT1 on t1.mc = #DailyProductionFromAutodataT1.machineinterface And
	t1.StartTime_LogicalDay = #DailyProductionFromAutodataT1.FromTime and t1.EndTime_LogicalDay = #DailyProductionFromAutodataT1.ToTime
END
-- mod 4

print sysdatetime()--g:



--select * from #DailyProductionFromAutodataT1
--Get component operation level details
--select * from #DailyProductionFromAutodataT0
--return
print sysdatetime()--g:
select @StartTime=@StartDate
select @EndTime=@EndDate
DECLARE @CurStart datetime
DECLARE @CurEndTime datetime
while @StartTime<=@EndTime
BEGIN
	select @CurStart=dbo.f_GetLogicalDay(@StartTime,'start')
	select @CurEndTime=dbo.f_GetLogicalDay(@StartTime,'End')
	select @strsql = 'insert into #DailyProductionFromAutodataT2 (Cdate,MachineID,GroupID,Component,Operation,CycleTime,LoadUnload,AvgLoadUnload,AvgCycleTime,'
	select @strsql = @strsql + 'CountShift1,CountShift2,CountShift3,FromTm,ToTm)'
	select @strsql = @strsql + '( SELECT ''' +convert(nvarchar(20),@StartTime)+ ''', machineinformation.machineid,PlantMachineGroups.GroupID, componentinformation.componentid, '
	select @strsql = @strsql + ' componentoperationpricing.operationno, '
	select @strsql = @strsql + ' componentoperationpricing.machiningtime, '
	select @strsql = @strsql + ' (componentoperationpricing.cycletime - componentoperationpricing.machiningtime),0, '
	--select @strsql = @strsql + ' AVG(autodata.loadunload/autodata.partscount) * ISNULL(ComponentOperationPricing.SubOperations,1), ' ::DR0016
	--mod 5
	--select @strsql = @strsql + ' AVG(autodata.cycletime/autodata.partscount) * ISNULL(ComponentOperationPricing.SubOperations,1) ,'
	  select @strsql = @strsql + ' sum(isnull(autodata.cycletime,0)) ,'
	--mod 5
	select @strsql = @strsql + ' 0,0,0,''' +convert(nvarchar(20),@CurStart)+ ''',''' +convert(nvarchar(20),@CurEndTime)+ ''' '
	select @strsql = @strsql + ' from  #T_autodata autodata INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN  '
	select @strsql = @strsql + ' componentinformation ON autodata.comp = componentinformation.InterfaceID  INNER JOIN '
	select @strsql = @strsql + ' componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID)'
	select @strsql = @strsql + ' AND (componentinformation.componentid = componentoperationpricing.componentid) '
	---mod 1
	select @strsql = @strsql + ' and componentoperationpricing.machineid=machineinformation.machineid '
	---mod 1
	select @strsql = @strsql + ' Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid
								 LEFT  JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID'
	select @strsql = @strsql + ' WHERE (autodata.ndtime > ''' + convert(nvarchar(20),@CurStart) + ''')'
	select @strsql = @strsql + ' AND (autodata.ndtime <= ''' + convert(nvarchar(20),@CurEndTime) + ''')'
	select @strsql = @strsql + @StrMPlantid + @strmachine + @strcomponentid + @stroperation+@StrGroupID
	select @strsql = @strsql + ' AND (autodata.datatype = 1)'
	--mod 3
	select @strsql = @strsql + ' AND (autodata.partscount > 0 ) '
	--mod 3
	select @strsql = @strsql + ' GROUP BY machineinformation.machineid,PlantMachineGroups.GroupID,componentinformation.componentid, componentoperationpricing.operationno, '
	select @strsql = @strsql + ' componentoperationpricing.cycletime, componentoperationpricing.machiningtime ,ComponentOperationPricing.SubOperations)'
	print @strsql
	exec(@strsql)



	--********************* SSK:25/07/07 : DR0016  Starts Here
	select @strsql =''
	select @strsql = 'UPDATE #DailyProductionFromAutodataT2 SET AvgLoadUnload=ISNULL(T2.AvgLoadUnload,0)'
	select @strsql = @strsql + ' FROM('
	select @strsql = @strsql + ' SELECT ''' +convert(nvarchar(20),@StartTime)+ ''' AS Cdate, machineinformation.machineid AS Machineid, componentinformation.componentid AS Component, '
	select @strsql = @strsql + ' componentoperationpricing.operationno AS operation , '
--	select @strsql = @strsql + ' AVG(autodata.loadunload/autodata.partscount) * ISNULL(ComponentOperationPricing.SubOperations,1) AS AvgLoadUnload ' --DR0325 commented
	select @strsql = @strsql + ' SUM(autodata.loadunload) AS AvgLoadUnload ' --DR0325 Added
	select @strsql = @strsql + ' from  #T_autodata autodata INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN  '
	select @strsql = @strsql + ' componentinformation ON autodata.comp = componentinformation.InterfaceID  INNER JOIN '
	select @strsql = @strsql + ' componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID)'
	select @strsql = @strsql + ' AND (componentinformation.componentid = componentoperationpricing.componentid) '
	---mod 1
	select @strsql = @strsql + ' and componentoperationpricing.machineid=machineinformation.machineid '
	---mod 1
	select @strsql = @strsql + ' Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid'
	select @strsql = @strsql + ' WHERE (autodata.ndtime > ''' + convert(nvarchar(20),@CurStart) + ''')'
	select @strsql = @strsql + ' AND (autodata.ndtime <= ''' + convert(nvarchar(20),@CurEndTime) + ''')'
	select @strsql = @strsql + @StrMPlantid + @strmachine + @strcomponentid + @stroperation
	select @strsql = @strsql + ' AND autodata.datatype = 1 AND autodata.loadunload>=(SELECT TOP 1 ISNULL(ValueInInt,0) From ShopDefaults Where Parameter=''MinLUForLR'')'
	--mod 3
	select @strsql = @strsql + ' AND (autodata.partscount > 0 )'
	--mod 3
	select @strsql = @strsql + ' GROUP BY machineinformation.machineid,componentinformation.componentid, componentoperationpricing.operationno,ComponentOperationPricing.SubOperations '
	select @strsql = @strsql + ' )AS T2 INNER JOIN #DailyProductionFromAutodataT2 ON T2.Cdate=#DailyProductionFromAutodataT2.Cdate AND T2.Machineid=#DailyProductionFromAutodataT2.Machineid
	AND T2.Component=#DailyProductionFromAutodataT2.Component AND T2.operation=#DailyProductionFromAutodataT2.operation'
	print sysdatetime() --g:
	exec(@strsql)
	print sysdatetime() --g:
	--********************* SSK:25/07/07 : DR0016  Ends Here
	
	--BEGIN: Update shift1, shift2, shift3 counts
	INSERT #DailyProductionFromAutodataT0(DDate,Shift, ShiftStart, ShiftEnd)
	EXEC s_GetShiftTime @StartTime
	
	SELECT @StartTime=DATEADD(DAY,1,@StartTime)
END

		Update #DailyProductionFromAutodataT0 Set shiftid = isnull(#DailyProductionFromAutodataT0.shiftid,0) + isnull(T1.shiftid,0) from    
(Select SD.shiftid ,SD.shiftname from shiftdetails SD    
inner join #DailyProductionFromAutodataT0 S on SD.shiftname=S.Shift where    
running=1 )T1 inner join #DailyProductionFromAutodataT0 on  T1.shiftname=#DailyProductionFromAutodataT0.Shift  




Update #DailyProductionFromAutodataT1 set RejCount = isnull(RejCount,0) + isnull(T1.RejQty,0)    
From    
( Select A.mc,SUM(A.Rejection_Qty) as RejQty,T1.Pdate from AutodataRejections A    
inner join Machineinformation M on A.mc=M.interfaceid    
inner join #DailyProductionFromAutodataT1 T1 on T1.MachineInterface=A.mc    
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid    
where A.CreatedTS>=T1.FromTime and A.CreatedTS<T1.ToTime and A.flag = 'Rejection'    
and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000'    
group by A.mc,T1.Pdate
)T1 inner join #DailyProductionFromAutodataT1 B on B.MachineInterface=T1.mc and B.Pdate=T1.Pdate     
 
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'    
BEGIN    
 Update #DailyProductionFromAutodataT1 set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from    
 (Select A.mc,SUM(A.Rejection_Qty) as RejQty,T1.Pdate from AutodataRejections A    
 inner join Machineinformation M on A.mc=M.interfaceid    
 inner join #DailyProductionFromAutodataT1 T1 on T1.MachineInterface=A.mc   
 inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid    
 Cross join PlannedDownTimes P    
 where  A.flag = 'Rejection' and P.machine=M.Machineid     
 and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000' and    
 A.CreatedTS>=FromTime and A.CreatedTS<ToTime And    
 A.CreatedTS>=P.Starttime and A.CreatedTS<P.endtime    
 group by A.mc,T1.Pdate
 )T1 inner join #DailyProductionFromAutodataT1 B on B.MachineInterface=T1.mc and B.Pdate=T1.Pdate     
END     


Update #DailyProductionFromAutodataT1 set RejCount = isnull(RejCount,0) + isnull(T1.RejQty,0)    
From    
( Select A.mc,SUM(A.Rejection_Qty) as RejQty,T1.Pdate from AutodataRejections A    
inner join Machineinformation M on A.mc=M.interfaceid    
inner join #DailyProductionFromAutodataT1 T1 on T1.MachineInterface=A.mc   
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid    
inner join #DailyProductionFromAutodataT0 S on (convert(nvarchar(10),(A.RejDate),120)=convert(nvarchar(10),S.DDate,120)) and A.RejShift=S.shiftid 
where A.flag = 'Rejection' and A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),120) in (convert(nvarchar(10),S.DDate,120)) and  
Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'    
group by A.mc,T1.Pdate
)T1 inner join #DailyProductionFromAutodataT1 B on  B.MachineInterface=T1.mc and B.Pdate=T1.Pdate   
    
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'    
BEGIN    
 Update #DailyProductionFromAutodataT1 set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from    
 (Select A.mc,SUM(A.Rejection_Qty) as RejQty,T1.Pdate from AutodataRejections A    
 inner join Machineinformation M on A.mc=M.interfaceid    
 inner join #DailyProductionFromAutodataT1 T1 on T1.MachineInterface=A.mc  
 inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid    
 inner join #DailyProductionFromAutodataT0 S on (convert(nvarchar(10),(A.RejDate),120)=convert(nvarchar(10),S.DDate,120)) and A.RejShift=S.shiftid      
 Cross join PlannedDownTimes P    
 where  A.flag = 'Rejection' and P.machine=M.Machineid and    
 A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),120) in (convert(nvarchar(10),s.DDate,120)) and 
 Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'    
 and P.starttime>=S.ShiftStart and P.Endtime<=S.ShiftEnd
 group by A.mc,T1.Pdate)T1 inner join #DailyProductionFromAutodataT1 B on  B.MachineInterface=T1.mc and B.Pdate=T1.Pdate   
END    
 



print 'ab'
print sysdatetime()--g:


declare @Dateval datetime
declare @shiftstart datetime
declare @shiftend  datetime
declare @shiftid  nvarchar(20)
declare @shiftname  nvarchar(20)
declare @shiftnamevalue  nvarchar(20)
declare @recordcount smallint
declare @lastdate datetime
--Initialize values
select @shiftstart = @starttime
select @shiftend = @endtime
select @shiftid = 'CountShift'
select @shiftname = 'NameShift'
select @shiftnamevalue = 'Shift 1'
select @recordcount = 0
select @lastdate=@StartDate
Declare RptDailyCursor CURSOR FOR 	
		SELECT 	#DailyProductionFromAutodataT0.DDate,
				#DailyProductionFromAutodataT0.Shift,
				#DailyProductionFromAutodataT0.ShiftStart,
				#DailyProductionFromAutodataT0.ShiftEnd
		from 	#DailyProductionFromAutodataT0	order by Ddate,shift

print sysdatetime() --g:

OPEN RptDailyCursor
FETCH NEXT FROM RptDailyCursor INTO @Dateval,@shiftnamevalue, @shiftstart, @shiftend
while (@@fetch_status = 0)
Begin
	if @Dateval=dateadd(day,1,@lastdate)
	BEGIN
	      SELECT @lastdate=@Dateval
	      SELECT @recordcount=0
	END
	select @recordcount = @recordcount + 1
	select @shiftid = 'CountShift' + cast(@recordcount as nvarchar(1))
	select @shiftname = 'NameShift' + cast(@recordcount as nvarchar(1))
	--Mod 4(1)
		Delete #PlannedDownTimes
		Insert into #PlannedDownTimes
		Select machineinformation.MachineID,machineinformation.InterfaceID,@shiftstart,@shiftend,
		Case When StartTime<@shiftstart Then @shiftstart Else StartTime End as StartTime, 	
		Case When EndTime > @shiftend Then @shiftend Else EndTime End as EndTime,
		0,0,0,0,PlannedDownTimes.DownReason
		 from PlannedDownTimes	inner join machineinformation on PlannedDownTimes.machine=machineinformation.machineid
		 Where PlannedDownTimes.PDTstatus =1 And (
		(StartTime >= @shiftstart and EndTime <= @shiftend) OR
		(StartTime < @shiftstart and EndTime <= @shiftend and EndTime > @shiftstart) OR
		(StartTime >= @shiftstart and EndTime > @shiftend and StartTime < @shiftend) OR
		(StartTime < @shiftstart and EndTime > @shiftend))
		And machineinformation.MachineID in (select distinct MachineID from #DailyProductionFromAutodataT1)
	--Mod 4(1)
	select @strsql = ''
	select @strsql = 'UPDATE #DailyProductionFromAutodataT2 SET ' + @shiftid + '= isNull(t5.OperationCount,0), '
	select @strsql = @strsql + @shiftname + ' = ''' + @shiftNamevalue + ''''
	select @strsql = @strsql + ' from ( SELECT machineinformation.machineid, componentinformation.componentid, '
	select @strsql = @strsql + ' componentoperationpricing.operationno, '
	--select @strsql = @strsql + ' CEILING(CAST(Sum(autodata.partscount)AS Float)/ISNULL(ComponentOperationPricing.SubOperations,1)) AS operationcount,D.Cdate as date1' --NR0097
	select @strsql = @strsql + ' (CAST(Sum(autodata.partscount)AS Float)/ISNULL(ComponentOperationPricing.SubOperations,1)) AS operationcount,D.Cdate as date1' --NR0097
	select @strsql = @strsql + ' from  #T_autodata autodata INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN  '
	select @strsql = @strsql + ' componentinformation ON autodata.comp = componentinformation.InterfaceID  INNER JOIN '
	select @strsql = @strsql + ' componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID'
	select @strsql = @strsql + ' AND componentinformation.componentid = componentoperationpricing.componentid) '
	---mod 1
	select @strsql = @strsql + ' and componentoperationpricing.machineid=machineinformation.machineid '
	---mod 1
	select @strsql = @strsql + ' inner join #DailyProductionFromAutodataT2 D on Machineinformation.machineid=D.machineid
	AND componentinformation.componentid=D.Component AND componentoperationpricing.operationno=D.Operation '
	select @strsql = @strsql + ' Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid'
	select @strsql = @strsql + ' WHERE (autodata.ndtime > ''' + convert(nvarchar(20),@ShiftStart) + ''')'
	select @strsql = @strsql + ' AND (autodata.ndtime <= ''' + convert(nvarchar(20),@ShiftEnd) + ''') and D.Cdate=''' + convert(nvarchar(20),@Dateval) + ''' '
	select @strsql = @strsql + @StrMPlantid + @strmachine + @strcomponentid + @stroperation
	select @strsql = @strsql + ' AND (autodata.datatype = 1)'
	select @strsql = @strsql + ' GROUP BY machineinformation.machineid,componentinformation.componentid, componentoperationpricing.operationno,ComponentOperationPricing.SubOperations,D.Cdate ) '
	select @strsql = @strsql + ' as t5 inner join #DailyProductionFromAutodataT2 on (t5.machineid = #DailyProductionFromAutodataT2.machineid '
	select @strsql = @strsql + 'and t5.componentid = #DailyProductionFromAutodataT2.component '
	select @strsql = @strsql + 'and t5.operationno = #DailyProductionFromAutodataT2.operation and t5.date1=#DailyProductionFromAutodataT2.Cdate)'
	exec(@strsql)
	--Mod 4(1) Apply PDT
	If (select valueintext from cockpitdefaults where parameter='Ignore_Count_4m_Pld')='Y'
	Begin
		 Select @Strsql = 'Update #DailyProductionFromAutodataT2 Set '+ @Shiftid+'=(Isnull('+ @ShiftId +',0)-Isnull(T2.Count,0))'
	     Select @Strsql =@Strsql + ' from (Select machineinformation.machineid,'
		 --Ceiling(cast(Sum(autodata.partscount) as float)/Isnull(Componentoperationpricing.Suboperations,1)) as Count, --NR0097
		 Select @Strsql =@Strsql + ' (cast(Sum(autodata.partscount) as float)/Isnull(Componentoperationpricing.Suboperations,1)) as Count,' --NR0097
	     Select @Strsql =@Strsql + ' ComponentInformation.Componentid,Componentoperationpricing.operationno,D.Cdate as date1 from #T_autodata autodata
			     inner Join #PlannedDownTimes T  on T.machineinterface = autodata.mc
			     inner join machineinformation on machineinformation.interfaceid=autodata.mc
			     inner join ComponentInformation on ComponentInformation.Interfaceid=autodata.Comp
			     inner join Componentoperationpricing on Componentoperationpricing.Interfaceid=autodata.opn and Componentoperationpricing.componentid=ComponentInformation.componentid and Componentoperationpricing.machineID = machineinformation.MachineID
				 inner join #DailyProductionFromAutodataT2 D on Machineinformation.machineid=D.machineid AND componentinformation.componentid=D.Component AND componentoperationpricing.operationno=D.Operation
				 Left Outer Join PlantMachine ON PlantMachine.MachineID=Machineinformation.machineid --DR0296
			     Where autodata.datatype=1 and (autodata.ndtime> T.StartTime_PDT and autodata.ndtime <= T.EndTime_PDT) '
	     Select @Strsql = @Strsql + ' and (autodata.ndtime > ''' +Convert(nvarchar(20),@ShiftStart) + ''' and autodata.ndtime <= ''' + Convert(Nvarchar(20),@ShiftEnd) + ''') and D.Cdate=''' + convert(nvarchar(20),@Dateval) + ''''
	     select @strsql = @strsql + @StrMPlantid + @strmachine + @strcomponentid + @stroperation
	     Select @Strsql = @Strsql + ' Group by machineinformation.machineid,ComponentInformation.componentid,Componentoperationpricing.operationno,
			     Componentoperationpricing.Suboperations,D.Cdate) as T2 inner join #DailyProductionFromAutodataT2 on (T2.machineid = #DailyProductionFromAutodataT2.machineid
			     and T2.Componentid= #DailyProductionFromAutodataT2.Component and T2.operationno=#DailyProductionFromAutodataT2.operation and t2.date1 = #DailyProductionFromAutodataT2.cdate)' 		      	
	    --print @strsql
	    Exec(@strsql)
	End
	--Mod 4(1)



	/**************************************************************************************************************/
	/* 			FOLLOWING SECTION IS ADDED BY SANGEETA KALLUR					*/
	SELECT @StrSql = 'INSERT INTO #Exceptions(MachineID ,ComponentID,OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,ExCount )
			SELECT Ex.MachineID ,Ex.ComponentID,Ex.OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,0
			From ProductionCountException Ex
			Inner Join MachineInformation M ON Ex.MachineID=M.MachineID
			Inner Join ComponentInformation C ON Ex.ComponentID=C.ComponentID
			Inner Join Componentoperationpricing O ON Ex.OperationNo=O.OperationNo AND C.ComponentID=O.ComponentID'
			---mod 2		
			SELECT @StrSql = @StrSql + ' and O.MachineId=Ex.MachineId '
			---mod 2
			SELECT @StrSql = @StrSql + 'WHERE  M.MultiSpindleFlag=1 '
	SELECT @StrSql =@StrSql + @strXMachine + @strXcomponentid + @strXoperation
	SELECT @StrSql =@StrSql +'AND ((Ex.StartTime>=  ''' + convert(nvarchar(20),@ShiftStart)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@ShiftEnd)+''' )
			OR (Ex.StartTime< ''' + convert(nvarchar(20),@ShiftStart)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@ShiftStart)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@ShiftEnd)+''')
			OR(Ex.StartTime>= ''' + convert(nvarchar(20),@ShiftStart)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@ShiftEnd)+''' AND Ex.StartTime< ''' + convert(nvarchar(20),@ShiftEnd)+''')
			OR(Ex.StartTime< ''' + convert(nvarchar(20),@ShiftStart)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@ShiftEnd)+''' ))'
	
	Exec (@strsql)
	
	IF ( SELECT Count(*) from #Exceptions ) <> 0
	BEGIN
		UPDATE #Exceptions SET StartTime=@ShiftStart WHERE (StartTime<@ShiftStart)AND EndTime>@ShiftStart
		UPDATE #Exceptions SET EndTime=@ShiftEnd WHERE (EndTime>@ShiftEnd AND StartTime<@ShiftEnd )
		Select @StrSql = 'UPDATE #Exceptions SET ExCount=ISNULL(T2.Comp,0) From
		(
			SELECT T1.MachineID AS MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime AS StartTime,T1.EndTime AS EndTime,
			--SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp --NR0097
			SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp --NR0097
	 		From (
				select MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,comp,opn,Tt1.StartTime,Tt1.EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from #T_autodata autodata
				Inner Join MachineInformation   ON autodata.MC=MachineInformation.InterfaceID
				Inner Join EmployeeInformation E  ON autodata.Opr=E.InterfaceID
				Inner Join ComponentInformation  ON autodata.Comp = ComponentInformation.InterfaceID
				Inner Join ComponentOperationPricing on autodata.Opn=ComponentOperationPricing.InterfaceID And ComponentInformation.ComponentID=ComponentOperationPricing.ComponentID'
				
				---mod 1
				select @strsql = @strsql + ' and componentoperationpricing.machineid=machineinformation.machineid '
				---mod 1
				select @strsql = @strsql + 'Inner Join (
					Select MachineID,ComponentID,OperationNo,StartTime,EndTime From #Exceptions
				)AS Tt1 ON Tt1.MachineID=MachineInformation.MachineID AND Tt1.ComponentID = ComponentInformation.ComponentID AND Tt1.OperationNo= ComponentOperationPricing.OperationNo
				Where (autodata.ndtime>Tt1.StartTime) AND (autodata.ndtime<=Tt1.EndTime) and (autodata.datatype=1) '
		Select @StrSql = @StrSql+ @strmachine + @strcomponentid + @stroperation
		Select @StrSql = @StrSql+' Group by MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,Tt1.StartTime,Tt1.EndTime,comp,opn
			) as T1
	   		Inner join componentinformation C on T1.Comp=C.interfaceid
	   		Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid '
		---mod 1
		select @strsql = @strsql + ' Inner join machineinformation M on T1.machineid = M.machineid '
		---mod 1
		select @strsql = @strsql + ' GROUP BY T1.MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime,t1.EndTime
		)AS T2
		WHERE  #Exceptions.StartTime=T2.StartTime AND #Exceptions.EndTime=T2.EndTime
		AND #Exceptions.MachineID=T2.MachineID AND #Exceptions.ComponentID = T2.ComponentID AND #Exceptions.OperationNo=T2.OperationNo'
		Exec(@StrSql)
		If (select valueintext from cockpitdefaults where parameter='Ignore_Count_4m_Pld')='Y'
		Begin	   		
			 Select @Strsql=''	
			 Select @Strsql='Update #Exceptions Set Excount=Isnull(Excount,0)-Isnull(T3.comp,0) from
					 (Select T2.machineid as Machineid,T2.ComponentId as ComponentId,T2.OperationNo as OperationNo,T2.StartTime
					 as StartTime,T2.EndTime as EndTime,
					 --Sum(Ceiling(Cast(T2.OriginalCount as Float))/Isnull(COP.Suboperations,1)) as Comp --NR0097
					 Sum((Cast(T2.OriginalCount as Float))/Isnull(COP.Suboperations,1)) as Comp	--NR0097
					 from	
			     		(Select M.Machineid,C.Componentid,Cp.OperationNo,Comp,Opn,Max(T1.XStartTime)StartTime,Max(T1.XEndTime)EndTime,
						 T1.Pld_StartTime,T1.Pld_ENdTime,Sum(Isnull(PartsCount,1)) as OriginalCount from #T_autodata autodata
						 Inner Join Machineinformation M on autodata.mc = M.interfaceid
						 Inner Join ComponentInformation C on autodata.comp = C.Interfaceid 	
						 Inner join ComponentOperationPricing Cp on autodata.opn = Cp.Interfaceid and C.ComponentId = Cp.ComponentId and Cp.MachineID = M.MachineID
						 inner join
							(Select Machineid,Componentid,OperationNo,Ex.StartTime as XStartTime,Ex.EndTime as XEndTime,
					     		Case When (Pdt.StartTime_PDT < Ex.StartTime and Pdt.EndTime_PDT <= Ex.EndTime and Pdt.EndTime_PDT > Ex.StartTime) then Ex.StartTime
					     			 When (Pdt.StartTime_PDT < Ex.StartTime and Pdt.EndTime_PDT > Ex.EndTime) then Ex.StartTime	
							 Else Pdt.StartTime_PDT	End as Pld_StartTime,
					     		Case When (Pdt.StartTime_PDT >= Ex.StartTime and Pdt.EndTime_PDT > Ex.EndTime and Pdt.StartTime_PDT < Ex.EndTime) then Ex.EndTime
					     			 When (Pdt.StartTime_PDT < Ex.StartTime and Pdt.EndTIme_PDT > Ex.EndTime) then Ex.EndTime
							 Else Pdt.EndTime_PDT End as Pld_EndTime
							 from #Exceptions as Ex cross join #PlannedDownTimes as Pdt	
							 Where (Ex.MachineID=pdt.MachineID) AND ((Pdt.StartTime >= Ex.StartTime and Pdt.EndTime <= Ex.EndTime) OR
					     		(Pdt.StartTime >= Ex.StartTime and Pdt.EndTime > Ex.EndTime and Pdt.StartTime < Ex.EndTime) OR
					     		(Pdt.StartTime < Ex.StartTime and Pdt.EndTime <= Ex.EndTime and Pdt.EndTime > Ex.StartTime) OR
					     		(Pdt.StartTime < Ex.StartTime and Pdt.EndTime > Ex.EndTime ))'
			Select @Strsql = @Strsql + @StrxMachine			
			Select @Strsql = @Strsql + ') as T1 on T1.Machineid = M.Machineid and T1.Componentid = C.componentid and T1.OperationNo = Cp.OperationNo and T1.Machineid=Cp.MachineID
					 Where (autodata.ndtime > T1.Pld_StartTime and autodata.ndtime <= T1.Pld_EndTime) and (Datatype=1)
					 and autodata.ndtime >''' + Convert(nvarchar(50),@ShiftStart) + ''' and autodata.ndtime <= ''' + Convert(nvarchar(50),@ShiftEnd) + ''''
			Select @Strsql = @Strsql + ' Group By M.Machineid,C.Componentid,Cp.operationno,T1.Pld_StartTime,T1.Pld_EndTime,Comp,opn
					 ) as T2 Inner join MachineInformation M on T2.MachineID=M.MachineID
							 Inner join Componentinformation CO on T2.Comp=CO.Interfaceid
							 Inner join Componentoperationpricing COP on T2.Opn = COP.interfaceid and CO.ComponentId = COP.ComponentId and COP.Machineid=M.MachineID'
			Select @Strsql = @Strsql + ' Group by T2.Machineid,T2.Componentid,T2.Operationno,T2.StartTime,T2.EndTime
					 ) as T3 Where #Exceptions.Machineid = T3.Machineid and #Exceptions.Componentid = T3.ComponentId
					 and #Exceptions.OperationNo = T3.OperationNo and #Exceptions.StartTime = T3.StartTime and #Exceptions.EndTime = T3.EndTime'
			--print @Strsql	
			EXEC (@StrSql)	
		End--If
		UPDATE #Exceptions SET ExCount=ExCount-((ExCount * ActualCount)/ISNULL(IdealCount,0))
	END
	SELECT @StrSql=''
	SELECT @StrSql='UPDATE #DailyProductionFromAutodataT2 SET '+@shiftid+'=ISNULL(pCount,0)
	FROM
	(
	SELECT  Cdate  ,'+@shiftname+' AS ShftName,#DailyProductionFromAutodataT2.MachineID,Component,Operation ,(ISNULL('+@shiftid+',0)-ISNULL(ExCount,0))As pCount
	FROM #DailyProductionFromAutodataT2 INNER JOIN
		(
		SELECT MachineID,ComponentID,OperationNo ,SUM(ExCount)AS ExCount
		FROM #Exceptions GROUP BY MachineID,ComponentID,OperationNo
		)AS Ti ON #DailyProductionFromAutodataT2.MachineID=Ti.MachineID AND #DailyProductionFromAutodataT2.Component=Ti.ComponentID AND #DailyProductionFromAutodataT2.Operation=Ti.OperationNo
	WHERE Cdate=''' + Convert(nvarchar(20),@Dateval) + ''' AND '+@shiftname+'='''+@shiftNamevalue+'''
	)As T1 Inner Join #DailyProductionFromAutodataT2 ON
		 #DailyProductionFromAutodataT2.MachineID=T1.MachineID AND
		 #DailyProductionFromAutodataT2.Component=T1.Component AND
		 #DailyProductionFromAutodataT2.Operation=T1.Operation AND
		 #DailyProductionFromAutodataT2.Cdate=T1.Cdate'

	EXEC (@StrSql)
	
	DELETE FROM #Exceptions
FETCH NEXT FROM RptDailyCursor INTO @Dateval,@shiftnamevalue, @shiftstart, @shiftend
End	

print sysdatetime() --g:

/**************************************************************************************************************/
/*
	  WHILE (@@fetch_status <> -1)
		BEGIN
		  IF (@@fetch_status <> -2)
		    BEGIN
			FETCH NEXT FROM RptDailyCursor INTO @shiftnamevalue, @shiftstart, @shiftend
			if (@@fetch_status = 0)
				begin
					select @recordcount = @recordcount + 1
					select @shiftid = 'CountShift' + cast(@recordcount as nvarchar(1))					select @shiftname = 'NameShift' + cast(@recordcount as nvarchar(1))
				
					select @strsql = ''
					select @strsql = 'UPDATE #DailyProductionFromAutodataT2 SET ' + @shiftid + '= isNull(t5.OperationCount,0), '
					select @strsql = @strsql + @shiftname + ' = ''' + @shiftNamevalue + ''''
					select @strsql = @strsql + ' from ( SELECT machineinformation.machineid, componentinformation.componentid, '
					select @strsql = @strsql + ' componentoperationpricing.operationno, '
					select @strsql = @strsql + ' count(componentoperationpricing.operationno) operationcount'
					select @strsql = @strsql + ' from autodata INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN  '
					select @strsql = @strsql + ' componentinformation ON autodata.comp = componentinformation.InterfaceID  INNER JOIN '
					select @strsql = @strsql + ' componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID'
					select @strsql = @strsql + ' AND componentinformation.componentid = componentoperationpricing.componentid) '
					select @strsql = @strsql + ' WHERE (autodata.ndtime > ''' + convert(nvarchar(20),@ShiftStart) + ''')'
					select @strsql = @strsql + ' AND (autodata.ndtime <= ''' + convert(nvarchar(20),@ShiftEnd) + ''')'
					select @strsql = @strsql + @strmachine + @strcomponentid + @stroperation
					select @strsql = @strsql + ' AND (autodata.datatype = 1)'
					select @strsql = @strsql + ' GROUP BY machineinformation.machineid,componentinformation.componentid, componentoperationpricing.operationno) '
					select @strsql = @strsql + ' as t5 inner join #DailyProductionFromAutodataT2 on (t5.machineid = #DailyProductionFromAutodataT2.machineid '
					select @strsql = @strsql + 'and t5.componentid = #DailyProductionFromAutodataT2.component '
					select @strsql = @strsql + 'and t5.operationno = #DailyProductionFromAutodataT2.operation)'
			
					exec(@strsql)
					
			    	end	
				
		    END
		END
*/
CLOSE RptDailyCursor
DEALLOCATE RptDailyCursor



/*
select @strsql = ''
select @strsql = 'UPDATE #DailyProductionFromAutodataT2 SET ' + @shiftid + '= isNull(t5.OperationCount,0), '
select @strsql = @strsql + @shiftname + ' = ''' + @shiftNamevalue + ''''
select @strsql = @strsql + ' from ( SELECT machineinformation.machineid, componentinformation.componentid, '
select @strsql = @strsql + ' componentoperationpricing.operationno, '
select @strsql = @strsql + ' count(componentoperationpricing.operationno) operationcount'
select @strsql = @strsql + ' from autodata INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN  '
select @strsql = @strsql + ' componentinformation ON autodata.comp = componentinformation.InterfaceID  INNER JOIN '
select @strsql = @strsql + ' componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID'
select @strsql = @strsql + ' AND componentinformation.componentid = componentoperationpricing.componentid) '
select @strsql = @strsql + ' WHERE (autodata.ndtime > ''' + convert(nvarchar(20),@ShiftStart) + ''')'
select @strsql = @strsql + ' AND (autodata.ndtime <= ''' + convert(nvarchar(20),@ShiftEnd) + ''')'
select @strsql = @strsql + @strmachine + @strcomponentid + @stroperation
select @strsql = @strsql + ' AND (autodata.datatype = 1)'
select @strsql = @strsql + ' GROUP BY machineinformation.machineid,componentinformation.componentid, componentoperationpricing.operationno) '
select @strsql = @strsql + ' as t5 inner join #DailyProductionFromAutodataT2 on (t5.machineid = #DailyProductionFromAutodataT2.machineid '
select @strsql = @strsql + 'and t5.componentid = #DailyProductionFromAutodataT2.component '
select @strsql = @strsql + 'and t5.operationno = #DailyProductionFromAutodataT2.operation)'
exec(@strsql)
*/
--END: Update shift1, shift2, shift3 counts
---Calculation of target count
Declare @TrSql3 varchar(8000)
Declare @strmachine3 nvarchar(255)
Declare @stroperation3 nvarchar(255)
Declare @strcomponent3 nvarchar(255)
select @TrSql3=''
SELECT @strmachine3 = ''
SELECT @strcomponent3= ''
SELECT @stroperation3 = ''
if isnull(@MachineID,'') <> ''
	BEGIN
	---mod 3
--	SELECT @strmachine3 = ' AND ( machine = ''' + @MachineID+ ''')'
	SELECT @strmachine3 = ' AND ( machine = N''' + @MachineID+ ''')'
	---mod 3
	END
if isnull(@ComponentID, '') <> ''
	BEGIN
	---mod 3
--	SELECT @strcomponent3 = ' AND ( component = ''' + @ComponentID+ ''')'
	SELECT @strcomponent3 = ' AND ( component = N''' + @ComponentID+ ''')'
	---mod 3
	END
if isnull(@OperationNo, '') <> ''
	BEGIN
	---mod 3
--	SELECT @stroperation3 = ' AND ( Operation = ''' + @OperationNo+ ''')'
	SELECT @stroperation3 = ' AND ( Operation = N''' + @OperationNo+ ''')'
	---mod 3
	END
if isnull(@Targetsource,'')='Exact Schedule'
BEGIN
	 select @TrSql3=''
	 select @TrSql3='update #DailyProductionFromAutodataT2 set TargetCount= isnull(TargetCount,0)+ ISNULL(t1.tcount,0) from
			( select date as date1,machine,component,operation,sum(idealcount) as tcount from
		  	loadschedule where date>=''' +convert(nvarchar(20),@startDate)+''' and date<=''' +convert(nvarchar(20),@EndDate)+ ''' '
select @TrSql3= @TrSql3 + @strmachine3 + @strcomponent3 + @stroperation3
	 select @TrSql3=@TrSql3+ 'group by date,machine,component,operation ) as t1 inner join #DailyProductionFromAutodataT2 on
		  	t1.date1=#DailyProductionFromAutodataT2.Cdate and t1.machine=#DailyProductionFromAutodataT2.MachineId and t1.component=#DailyProductionFromAutodataT2.Component
		  	and t1.operation=#DailyProductionFromAutodataT2.Operation '	
--	PRINT @TrSql3
print sysdatetime() --g:
	EXEC (@TrSql3)
	print sysdatetime() --g:
		
END
if isnull(@Targetsource,'')='Default Target per CO'
BEGIN
	PRINT @Targetsource
	select @TrSql3=''
	 select @TrSql3='update #DailyProductionFromAutodataT2 set TargetCount= isnull(TargetCount,0)+ ISNULL(t1.tcount,0) from
			( select DATE AS date1, machine,component,operation,sum(idealcount) as tcount from
		  	loadschedule where date=(SELECT TOP 1 DATE FROM LOADSCHEDULE ORDER BY DATE DESC) and SHIFT=(SELECT TOP 1 SHIFT FROM LOADSCHEDULE ORDER BY SHIFT DESC)'
select @TrSql3= @TrSql3 + @strmachine3 + @strcomponent3 + @stroperation3
	 select @TrSql3=@TrSql3+ ' group by date,machine,component,operation ) as t1 inner join #DailyProductionFromAutodataT2 on
			t1.machine=#DailyProductionFromAutodataT2.MachineId and
		  	 t1.component=#DailyProductionFromAutodataT2.Component
		  	and t1.operation=#DailyProductionFromAutodataT2.Operation '	
--	PRINT @TrSql3
	EXEC (@TrSql3)
	
	UPDATE #DailyProductionFromAutodataT2 SET TargetCount=TargetCount*(SELECT COUNT(*) FROM  SHIFTDETAILS WHERE RUNNING=1)
	
END
print sysdatetime() --g:
IF ISNULL(@Targetsource,'')='% Ideal'
BEGIN
		select @strmachine3=''
	if isnull(@MachineID,'') <> ''
	BEGIN
	---mod 3
--	SELECT @strmachine3 = ' AND ( CO.machineID = ''' + @MachineID+ ''')'
	SELECT @strmachine3 = ' AND ( CO.machineID = N''' + @MachineID+ ''')'
	---mod 3
	END
	select @strcomponent3=''
	if isnull(@ComponentID, '') <> ''
	BEGIN
	---mod 3
--	SELECT @strcomponent3 = ' AND (CO.componentID = ''' + @ComponentID+ ''')'
	SELECT @strcomponent3 = ' AND (CO.componentID = N''' + @ComponentID+ ''')'
	---mod 3
	END
	select @stroperation3=''
	if isnull(@OperationNo, '') <> ''
	BEGIN
	---mod 3
--	SELECT @stroperation3 = ' AND ( CO.operationno = ''' + @OperationNo + ''')'
	SELECT @stroperation3 = ' AND ( CO.operationno = N''' + @OperationNo + ''')'
	---mod 3
	END
	
select @TrSql3=''
---mod 2
--	select @TrSql3='update #DailyProductionFromAutodataT2 set TargetCount= isnull(TargetCount,0)+ ISNULL(t1.tcount,0) from
--			 ( select CO.componentid as component,CO.Operationno as operation, tcount=((datediff(second,#DailyProductionFromAutodataT2.Fromtm,#DailyProductionFromAutodataT2.Totm)*CO.suboperations)/CO.cycletime)*isnull(CO.targetpercent,100) /100
--			from componentoperationpricing CO inner join #DailyProductionFromAutodataT2 on CO.Componentid=#DailyProductionFromAutodataT2.Component
--			and Co.operationno=#DailyProductionFromAutodataT2.Operation  '
select @TrSql3='update #DailyProductionFromAutodataT2 set TargetCount= isnull(TargetCount,0)+ ISNULL(t1.tcount,0) from
			 ( select CO.machineid as machine,CO.componentid as component,CO.Operationno as operation, tcount=((datediff(second,#DailyProductionFromAutodataT2.Fromtm,#DailyProductionFromAutodataT2.Totm)*CO.suboperations)/CO.cycletime)*isnull(CO.targetpercent,100) /100
			from componentoperationpricing CO inner join #DailyProductionFromAutodataT2 on CO.Componentid=#DailyProductionFromAutodataT2.Component
			and Co.operationno=#DailyProductionFromAutodataT2.Operation  '
	---mod 2
	select @TrSql3= @TrSql3 + @strcomponent3 + @stroperation3
	select @TrSql3=@TrSql3+ '  ) as t1 inner join #DailyProductionFromAutodataT2 on
		  	  t1.component=#DailyProductionFromAutodataT2.Component
		  	and t1.operation=#DailyProductionFromAutodataT2.Operation'	
	---mod 2
	select @TrSql3 = @TrSql3 + ' and t1.machine = #DailyProductionFromAutodataT2.machineID '
	---mod 2
--	PRINT @TrSql3
	EXEC (@TrSql3)
	print sysdatetime() --g:
--Select * from #DailyProductionFromAutodataT2
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
	BEGIN
		update #DailyProductionFromAutodataT2 set Targetcount=Targetcount-((cast(t3.Totalpdt as float)/cast(datediff(ss,t3.Starttime,t3.Endtime) as float))*Targetcount)
						from 
						(
						Select Machineid,Starttime,Endtime,Sum(Datediff(ss,Starttimepdt,Endtimepdt))as TotalPDT
						From 
						(
						select fd.StartTime,fd.EndTime,Case 
										when fd.StartTime <= pdt.StartTime then pdt.StartTime
										else fd.StartTime
										End as Starttimepdt
						,Case when fd.EndTime >= pdt.EndTime then pdt.EndTime else fd.EndTime End as Endtimepdt
						,fd.MachineID 
						from 
						(Select distinct Machineid,FromTm as StartTime ,ToTm  as EndTime from #DailyProductionFromAutodataT2) as fd
						 cross join planneddowntimes pdt
						where PDTstatus = 1  and fd.machineID = pdt.Machine and --and DownReason <> 'SDT'
						((pdt.StartTime >= fd.StartTime and pdt.EndTime <= fd.EndTime)or 
						(pdt.StartTime < fd.StartTime and pdt.EndTime > fd.StartTime and pdt.EndTime <=fd.EndTime)or
						(pdt.StartTime >= fd.StartTime and pdt.StartTime <fd.EndTime and pdt.EndTime > fd.EndTime) or
						(pdt.StartTime < fd.StartTime and pdt.EndTime > fd.EndTime))
						)T2 group by Machineid,Starttime,Endtime
						)T3 inner join #DailyProductionFromAutodataT2
						on T3.Machineid=#DailyProductionFromAutodataT2.machineid
						 and T3.Starttime=#DailyProductionFromAutodataT2.FromTm  
						and T3.Endtime= #DailyProductionFromAutodataT2.ToTm 
						where Targetcount>0
						
			End--return

END
print 'aaa'
print sysdatetime() --g:
--mod 5

--If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y' --ER0363 Commented
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_AvgCycletime_4m_PLD')='Y' --ER0363 Added
BEGIN

	--DR0327 Commented From Here
------	UPDATE #DailyProductionFromAutodataT2 set AvgCycleTime =isnull(AvgCycleTime,0) - isNull(TT.PPDT ,0)
------	FROM(
------		--Production Time in PDT
------	Select A.mc,A.comp,A.Opn,A.MachineID,A.component,A.operation,A.FromTm,A.ToTm,Sum
------			(CASE
------			WHEN A.sttime >= T.StartTime  AND A.ndtime <=T.EndTime  THEN (A.cycletime)
------			WHEN ( A.sttime < T.StartTime  AND A.ndtime <= T.EndTime  AND A.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,A.ndtime)
------			WHEN ( A.sttime >= T.StartTime   AND A.sttime <T.EndTime  AND A.ndtime > T.EndTime  ) THEN DateDiff(second,A.sttime,T.EndTime )
------			WHEN ( A.sttime < T.StartTime  AND A.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
------			END)  as PPDT
------	From 
------			
------		(
------				SELECT M.MachineID,M.component,M.operation,M.FromTm,M.ToTm,
------				autodata.MC,autodata.comp,autodata.Opn,autodata.sttime,autodata.ndtime
------				,autodata.Cycletime--,M.ShftStrt,M.ShftND
------				from autodata inner join Machineinformation on Machineinformation.interfaceid=Autodata.mc
------						  inner join componentinformation on componentinformation.interfaceid=autodata.comp
------						   inner join componentoperationpricing
------							ON (autodata.opn = componentoperationpricing.InterfaceID)
------							AND componentinformation.componentid = componentoperationpricing.componentid
------							and componentoperationpricing.machineid=machineinformation.machineid  
------			inner join (Select distinct MachineID,component,operation,FromTm,ToTm from #DailyProductionFromAutodataT2) M on M.Machineid=machineinformation.machineid 
------			and M.component=componentoperationpricing.componentid and M.operation=componentoperationpricing.Operationno
------			where autodata.DataType=1 And autodata.ndtime >M.FromTm  AND autodata.ndtime <=M.ToTm
------		)A
------			--CROSS jOIN PlannedDownTimes T 
------			WHERE T.Machine=A.MachineID AND
------			((A.sttime >= T.StartTime  AND A.ndtime <=T.EndTime)
------			OR ( A.sttime < T.StartTime  AND A.ndtime <= T.EndTime AND A.ndtime > T.StartTime )
------			OR ( A.sttime >= T.StartTime   AND A.sttime <T.EndTime AND A.ndtime > T.EndTime )
------			OR ( A.sttime < T.StartTime  AND A.ndtime > T.EndTime) )
------		group by A.mc,A.comp,A.Opn,A.MachineID,A.component,A.operation,A.FromTm,A.ToTm
------)
------	as TT INNER JOIN #DailyProductionFromAutodataT2 ON TT.MachineID = #DailyProductionFromAutodataT2.MachineID
------		and TT.component = #DailyProductionFromAutodataT2.component
------			and TT.operation = #DailyProductionFromAutodataT2.operation and TT.FromTm=#DailyProductionFromAutodataT2.FromTm 
------					and TT.ToTm= #DailyProductionFromAutodataT2.ToTm
--------Select * from #DailyProductionFromAutodataT2
------
------	--Handle intearction between ICD and PDT for type 1 production record for the selected time period.
------	UPDATE  #DailyProductionFromAutodataT2 set AvgCycleTime =isnull(AvgCycleTime,0) + isNull(T2.IPDT ,0) 	FROM	(
------		Select T1.MachineID,T1.component,T1.operation,AutoData.mc,autodata.comp,autodata.Opn,T1.FromTm,T1.ToTm,
------		SUM(
------		CASE 	
------			When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
------			When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
------			When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
------			when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
------		END) as IPDT
------		from autodata INNER Join
------			(Select M.MachineID,M.component,M.operation,mc,Sttime,NdTime,M.FromTm,M.ToTm From AutoData
------				inner join Machineinformation on Machineinformation.interfaceid=Autodata.mc
------						  inner join componentinformation on componentinformation.interfaceid=autodata.comp
------						   inner join componentoperationpricing
------							ON (autodata.opn = componentoperationpricing.InterfaceID)
------							AND componentinformation.componentid = componentoperationpricing.componentid
------							and componentoperationpricing.machineid=machineinformation.machineid  
------			inner join (Select distinct MachineID,component,operation,FromTm,ToTm from #DailyProductionFromAutodataT2) M on M.Machineid=machineinformation.machineid 
------			and M.component=componentoperationpricing.componentid and M.operation=componentoperationpricing.Operationno
------				Where DataType=1 And DateDiff(Second,sttime,ndtime)>AutoData.CycleTime And
------				(ndtime > M.FromTm) AND (ndtime <= M.ToTm)) as T1
------		ON AutoData.mc=T1.mc 
------		--CROSS jOIN PlannedDownTimes T 
------		Where AutoData.DataType=2 And T.Machine=T1.MachineID
------		And (( autodata.Sttime > T1.Sttime )
------		And ( autodata.ndtime <  T1.ndtime )
------		)
------		AND
------		((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
------		or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
------		or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
------		or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )
------		GROUP BY T1.MachineID,T1.component,T1.operation,AUTODATA.mc,autodata.comp,autodata.Opn,T1.FromTm,T1.ToTm
------	)AS T2  INNER JOIN #DailyProductionFromAutodataT2 ON T2.MachineID = #DailyProductionFromAutodataT2.MachineID
------				and T2.component = #DailyProductionFromAutodataT2.component
------			and T2.operation = #DailyProductionFromAutodataT2.operation and T2.FromTm=#DailyProductionFromAutodataT2.FromTm 
------				and T2.ToTm= #DailyProductionFromAutodataT2.ToTm
		--DR0327 Commented Till here

/******************************************	DR0325 Commented From Here ********************************************
	
		------------------------------------------DR0327 added From Here-------------------------------------------
		UPDATE #DailyProductionFromAutodataT2 set AvgCycleTime =isnull(AvgCycleTime,0) - isNull(TT.PPDT ,0)
		FROM(
		--Production Time in PDT
			Select A.mc,A.comp,A.Opn,A.MachineID,A.component,A.operation,A.FromTm,A.ToTm,Sum
			(CASE
			WHEN A.sttime >= T.StartTime_PDT  AND A.ndtime <=T.EndTime_PDT  THEN (A.cycletime)
			WHEN ( A.sttime < T.StartTime_PDT  AND A.ndtime <= T.EndTime_PDT  AND A.ndtime > T.StartTime_PDT ) THEN DateDiff(second,T.StartTime_PDT,A.ndtime)
			WHEN ( A.sttime >= T.StartTime_PDT   AND A.sttime <T.EndTime_PDT  AND A.ndtime > T.EndTime_PDT  ) THEN DateDiff(second,A.sttime,T.EndTime_PDT )
			WHEN ( A.sttime < T.StartTime_PDT  AND A.ndtime > T.EndTime_PDT ) THEN DateDiff(second,T.StartTime_PDT,T.EndTime_PDT )
			END)  as PPDT
			From 
			
			(
				SELECT M.MachineID,M.component,M.operation,M.FromTm,M.ToTm,
				autodata.MC,autodata.comp,autodata.Opn,autodata.sttime,autodata.ndtime
				,autodata.Cycletime--,M.ShftStrt,M.ShftND
				from autodata inner join Machineinformation on Machineinformation.interfaceid=Autodata.mc
						  inner join componentinformation on componentinformation.interfaceid=autodata.comp
						   inner join componentoperationpricing
							ON (autodata.opn = componentoperationpricing.InterfaceID)
							AND componentinformation.componentid = componentoperationpricing.componentid
							and componentoperationpricing.machineid=machineinformation.machineid  
			inner join (Select distinct MachineID,component,operation,FromTm,ToTm from #DailyProductionFromAutodataT2) M on M.Machineid=machineinformation.machineid 
			and M.component=componentoperationpricing.componentid and M.operation=componentoperationpricing.Operationno
			where autodata.DataType=1 And autodata.ndtime >M.FromTm  AND autodata.ndtime <=M.ToTm
			)A
			--CROSS jOIN PlannedDownTimes T --DR0327 Commented
			CROSS jOIN #PlannedDownTimes T --DR0327 Added
			WHERE T.MachineID=A.MachineID AND --DR0327 Added "Machineid" instead "Machine"
			T.StartTime_LogicalDay = A.FromTm AND --DR0327 Added
			((A.sttime >= T.StartTime_PDT  AND A.ndtime <=T.EndTime_PDT)
			OR ( A.sttime < T.StartTime_PDT  AND A.ndtime <= T.EndTime_PDT AND A.ndtime > T.StartTime_PDT )
			OR ( A.sttime >= T.StartTime_PDT   AND A.sttime <T.EndTime_PDT AND A.ndtime > T.EndTime_PDT )
			OR ( A.sttime < T.StartTime_PDT  AND A.ndtime > T.EndTime_PDT) )
		group by A.mc,A.comp,A.Opn,A.MachineID,A.component,A.operation,A.FromTm,A.ToTm
	)
	as TT INNER JOIN #DailyProductionFromAutodataT2 ON TT.MachineID = #DailyProductionFromAutodataT2.MachineID
		and TT.component = #DailyProductionFromAutodataT2.component
			and TT.operation = #DailyProductionFromAutodataT2.operation and TT.FromTm=#DailyProductionFromAutodataT2.FromTm 
					and TT.ToTm= #DailyProductionFromAutodataT2.ToTm


	--Handle intearction between ICD and PDT for type 1 production record for the selected time period.
	UPDATE  #DailyProductionFromAutodataT2 set AvgCycleTime =isnull(AvgCycleTime,0) + isNull(T2.IPDT ,0) 	FROM	(
		Select T1.MachineID,T1.component,T1.operation,AutoData.mc,autodata.comp,autodata.Opn,T1.FromTm,T1.ToTm,
		SUM(
		CASE 	
			When autodata.sttime >= T.StartTime_PDT  AND autodata.ndtime <=T.EndTime_PDT  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
			When autodata.sttime < T.StartTime_PDT  and  autodata.ndtime <= T.EndTime_PDT AND autodata.ndtime > T.StartTime_PDT Then datediff(s, T.StartTime_PDT,autodata.ndtime ) ---type 2
			When ( autodata.sttime >= T.StartTime_PDT   AND autodata.sttime <T.EndTime_PDT AND autodata.ndtime > T.EndTime_PDT ) Then datediff(s, autodata.sttime,T.EndTime_PDT ) ---type 3
			when ( autodata.sttime < T.StartTime_PDT  AND autodata.ndtime > T.EndTime_PDT)  Then datediff(s, T.StartTime_PDT,T.EndTime_PDT ) ---type 4
		END) as IPDT
		from autodata INNER Join
			(Select M.MachineID,M.component,M.operation,mc,Sttime,NdTime,M.FromTm,M.ToTm From AutoData
				inner join Machineinformation on Machineinformation.interfaceid=Autodata.mc
						  inner join componentinformation on componentinformation.interfaceid=autodata.comp
						   inner join componentoperationpricing
							ON (autodata.opn = componentoperationpricing.InterfaceID)
							AND componentinformation.componentid = componentoperationpricing.componentid
							and componentoperationpricing.machineid=machineinformation.machineid  
			inner join (Select distinct MachineID,component,operation,FromTm,ToTm from #DailyProductionFromAutodataT2) M on M.Machineid=machineinformation.machineid 
			and M.component=componentoperationpricing.componentid and M.operation=componentoperationpricing.Operationno
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>AutoData.CycleTime And
				(ndtime > M.FromTm) AND (ndtime <= M.ToTm)) as T1
		ON AutoData.mc=T1.mc 
		--CROSS jOIN PlannedDownTimes T --DR0327 Commented
		 CROSS jOIN #PlannedDownTimes T --DR0327 Added
		Where AutoData.DataType=2 And 
		T.MachineID=T1.MachineID --DR0327 Added "Machineid" instaed "Machine"
		AND T.StartTime_LogicalDay = T1.FromTm --DR0327 Added
		And (( autodata.Sttime > T1.Sttime )
		And ( autodata.ndtime <  T1.ndtime )
		)
		AND
		((( T.StartTime_PDT >=T1.Sttime) And ( T.EndTime_PDT <=T1.ndtime ))
		or ( T.StartTime_PDT < T1.Sttime  and  T.EndTime_PDT <= T1.ndtime AND T.EndTime_PDT > T1.Sttime)
		or (T.StartTime_PDT >= T1.Sttime   AND T.StartTime_PDT <T1.ndtime AND T.EndTime_PDT > T1.ndtime )
		or (( T.StartTime_PDT <T1.Sttime) And ( T.EndTime_PDT >T1.ndtime )) )
		GROUP BY T1.MachineID,T1.component,T1.operation,AUTODATA.mc,autodata.comp,autodata.Opn,T1.FromTm,T1.ToTm
	)AS T2  INNER JOIN #DailyProductionFromAutodataT2 ON T2.MachineID = #DailyProductionFromAutodataT2.MachineID
				and T2.component = #DailyProductionFromAutodataT2.component
			and T2.operation = #DailyProductionFromAutodataT2.operation and T2.FromTm=#DailyProductionFromAutodataT2.FromTm 
				and T2.ToTm= #DailyProductionFromAutodataT2.ToTm
      ---------------------------------DR0327 Added Till Here---------------------------------------------

	******************************************	DR0325 Commented From Here ********************************************/

	print sysdatetime()--g:
			------------------------------------------DR0325 added From Here-------------------------------------------
		UPDATE #DailyProductionFromAutodataT2 set AvgCycleTime =isnull(AvgCycleTime,0) - isNull(TT.PPDT ,0)
		,AvgLoadUnload = isnull(AvgLoadUnload,0) - isnull(LD,0)
		FROM(
		--Production Time in PDT
			Select A.mc,A.comp,A.Opn,A.MachineID,A.component,A.operation,A.FromTm,A.ToTm,Sum
			(CASE
--			WHEN A.sttime >= T.StartTime  AND A.ndtime <=T.EndTime  THEN (A.cycletime) --DR0325 Commented
			WHEN A.sttime >= T.StartTime  AND A.ndtime <=T.EndTime  THEN DateDiff(second,A.sttime,A.ndtime) --DR0325 added
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
			From 
			
			(
				SELECT M.MachineID,M.component,M.operation,M.FromTm,M.ToTm,
				autodata.MC,autodata.comp,autodata.Opn,autodata.sttime,autodata.ndtime
				,autodata.Cycletime,autodata.msttime--,M.ShftStrt,M.ShftND
				from  #T_autodata autodata inner join Machineinformation on Machineinformation.interfaceid=Autodata.mc
						  inner join componentinformation on componentinformation.interfaceid=autodata.comp
						   inner join componentoperationpricing
							ON (autodata.opn = componentoperationpricing.InterfaceID)
							AND componentinformation.componentid = componentoperationpricing.componentid
							and componentoperationpricing.machineid=machineinformation.machineid  
			inner join (Select distinct MachineID,component,operation,FromTm,ToTm from #DailyProductionFromAutodataT2) M on M.Machineid=machineinformation.machineid 
			and M.component=componentoperationpricing.componentid and M.operation=componentoperationpricing.Operationno
			where autodata.DataType=1 And autodata.ndtime >M.FromTm  AND autodata.ndtime <=M.ToTm
			)A
			CROSS jOIN PlannedDownTimes T 
			WHERE T.Machine=A.MachineID AND 
			((A.msttime >= T.StartTime  AND A.ndtime <=T.EndTime)
			OR ( A.msttime < T.StartTime  AND A.ndtime <= T.EndTime AND A.ndtime > T.StartTime )
			OR ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime AND A.ndtime > T.EndTime )
			OR ( A.msttime < T.StartTime  AND A.ndtime > T.EndTime) ) 
--			AND 
--			((T.StartTime >= A.FromTm  AND T.EndTime <=A.ToTm)
--			OR ( T.StartTime < A.FromTm  AND T.EndTime <= A.ToTm AND T.EndTime > A.FromTm )
--			OR ( T.StartTime >= A.FromTm   AND T.StartTime <A.ToTm AND T.EndTime > A.ToTm )
--			OR ( T.StartTime < A.FromTm  AND T.EndTime > A.ToTm) )
		group by A.mc,A.comp,A.Opn,A.MachineID,A.component,A.operation,A.FromTm,A.ToTm
	)
	as TT INNER JOIN #DailyProductionFromAutodataT2 ON TT.MachineID = #DailyProductionFromAutodataT2.MachineID
		and TT.component = #DailyProductionFromAutodataT2.component
			and TT.operation = #DailyProductionFromAutodataT2.operation and TT.FromTm=#DailyProductionFromAutodataT2.FromTm 
					and TT.ToTm= #DailyProductionFromAutodataT2.ToTm

print sysdatetime()--g:
	--Handle intearction between ICD and PDT for type 1 production record for the selected time period.
	UPDATE  #DailyProductionFromAutodataT2 set AvgCycleTime =isnull(AvgCycleTime,0) + isNull(T2.IPDT ,0) 	FROM	(
		Select T1.MachineID,T1.component,T1.operation,AutoData.mc,autodata.comp,autodata.Opn,T1.FromTm,T1.ToTm,
		SUM(
		CASE 	
			When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
			When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
			When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
			when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		from  #T_autodata autodata INNER Join
			(Select M.MachineID,M.component,M.operation,mc,Sttime,NdTime,M.FromTm,M.ToTm From #T_autodata autodata
				inner join Machineinformation on Machineinformation.interfaceid=Autodata.mc
						  inner join componentinformation on componentinformation.interfaceid=autodata.comp
						   inner join componentoperationpricing
							ON (autodata.opn = componentoperationpricing.InterfaceID)
							AND componentinformation.componentid = componentoperationpricing.componentid
							and componentoperationpricing.machineid=machineinformation.machineid  
			inner join (Select distinct MachineID,component,operation,FromTm,ToTm from #DailyProductionFromAutodataT2) M on M.Machineid=machineinformation.machineid 
			and M.component=componentoperationpricing.componentid and M.operation=componentoperationpricing.Operationno
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>AutoData.CycleTime And
				(ndtime > M.FromTm) AND (ndtime <= M.ToTm)) as T1
		ON AutoData.mc=T1.mc 
		CROSS jOIN PlannedDownTimes T 
		Where AutoData.DataType=2 And 
		T.Machine=T1.MachineID 
		And (( autodata.Sttime >= T1.Sttime ) --DR0339
		And ( autodata.ndtime <=  T1.ndtime )--DR0339
		)
		AND
		((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
		or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
		or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
		or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) ) 
--		AND 
--		((T.StartTime >= T1.FromTm  AND T.EndTime <=T1.ToTm)
--		OR ( T.StartTime < T1.FromTm  AND T.EndTime <= T1.ToTm AND T.EndTime > T1.FromTm )
--		OR ( T.StartTime >= T1.FromTm   AND T.StartTime <T1.ToTm AND T.EndTime > T1.ToTm )
--		OR ( T.StartTime < T1.FromTm  AND T.EndTime > T1.ToTm) )
		GROUP BY T1.MachineID,T1.component,T1.operation,AUTODATA.mc,autodata.comp,autodata.Opn,T1.FromTm,T1.ToTm
	)AS T2  INNER JOIN #DailyProductionFromAutodataT2 ON T2.MachineID = #DailyProductionFromAutodataT2.MachineID
				and T2.component = #DailyProductionFromAutodataT2.component
			and T2.operation = #DailyProductionFromAutodataT2.operation and T2.FromTm=#DailyProductionFromAutodataT2.FromTm 
				and T2.ToTm= #DailyProductionFromAutodataT2.ToTm
      ---------------------------------DR0325 Added Till Here---------------------------------------------
End

update #DailyProductionFromAutodataT2 set AvgCycleTime=AvgCycleTime/ case
	when isnull(#DailyProductionFromAutodataT2.CountShift1,0)
	+isnull(#DailyProductionFromAutodataT2.CountShift2,0)
	+isnull(#DailyProductionFromAutodataT2.CountShift3,0)>0 then isnull(#DailyProductionFromAutodataT2.CountShift1,0)
	+isnull(#DailyProductionFromAutodataT2.CountShift2,0)
	+isnull(#DailyProductionFromAutodataT2.CountShift3,0)
	else 1 end ,
	--DR0325 Added From Here
	Avgloadunload=Avgloadunload/ case
	when isnull(#DailyProductionFromAutodataT2.CountShift1,0)
	+isnull(#DailyProductionFromAutodataT2.CountShift2,0)
	+isnull(#DailyProductionFromAutodataT2.CountShift3,0)>0 then isnull(#DailyProductionFromAutodataT2.CountShift1,0)
	+isnull(#DailyProductionFromAutodataT2.CountShift2,0)
	+isnull(#DailyProductionFromAutodataT2.CountShift3,0)else 1 end
	--DR0325 Added Till Here
--mod 5
------------------------------------------------------
--Get preferred time format
select @timeformat ='ss'
select @timeformat = isnull((select valueintext from cockpitdefaults where parameter='timeformat'),'ss')
if (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')
begin
select @timeformat = 'ss'
end
--Output
declare @shiftname1 nvarchar(20)
declare @shiftname2 nvarchar(20)
declare @shiftname3 nvarchar(20)
select @shiftname1 = (select top 1 NameShift1 from #DailyProductionFromAutodataT2 where Nameshift1 > '')
select @shiftname2 = (select top 1 NameShift2 from #DailyProductionFromAutodataT2 where Nameshift2 > '')
select @shiftname3 = (select top 1 NameShift3 from #DailyProductionFromAutodataT2 where Nameshift3 > '')

-----ER0450 From Here
if EXISTS(select * from company where CompanyName like '%SHANTI IRON AND STEEL FOUNDRY%')
Begin
update #DailyProductionFromAutodataT2 set Operation = T.Description From
(Select distinct machineid,componentid,operationno,description from componentoperationpricing
)T inner join #DailyProductionFromAutodataT2 D on T.machineid=D.machineid and T.componentid=D.Component and T.operationno=D.Operation
End
-----ER0450 Till Here

-- Calculate efficiencies
Update #DailyProductionFromAutodataT2 set CountShiftTotal=T1.TotalCount
from(
select A.MachineID,A.Cdate, A.GroupID,A.Component,A.Operation,(CountShift1+CountShift2+CountShift3) as TotalCount from #DailyProductionFromAutodataT2 A
)AS T1 Inner Join #DailyProductionFromAutodataT2  T2 ON  T2.MachineID=T1.MachineID 
and T2.Cdate=T1.Cdate and T1.GroupID=T2.GroupID and T1.Component=T2.Component and T1.Operation=T2.Operation


UPDATE #DailyProductionFromAutodataT1 SET QualityEfficiency= ISNULL(QualityEfficiency,0) + IsNull(T1.QE,1) 
FROM(Select T1.MachineID,T1.FromTime,
--CAST((Sum(ISNULL(CountShiftTotal,0)))As Float)/CAST((Sum(IsNull(CountShiftTotal,0))+Sum(IsNull(RejCount,0))) AS Float)As QE
CAST((Sum(ISNULL(CountShiftTotal,0)))As Float)/CAST((Sum(IsNull(CountShiftTotal,0))+(IsNull(RejCount,0))) AS Float)As QE
From #DailyProductionFromAutodataT1 T1
INNER JOIN #DailyProductionFromAutodataT2  T2 ON
		T1.MachineID = T2.MachineID and
		T1.Pdate=T2.Cdate 
		and T1.GroupID=T2.GroupID
Where (CountShiftTotal)<>0 
Group By T1.MachineID,T1.FromTime,RejCount
)AS T1 Inner Join #DailyProductionFromAutodataT1 T2 ON  T2.MachineID=T1.MachineID 
and T2.FromTime=T1.FromTime 

UPDATE #DailyProductionFromAutodataT1
SET
	ProductionEfficiency = (CN/UtilisedTime) ,
	AvailabilityEfficiency = (UtilisedTime)/(UtilisedTime + DownTime - ManagementLoss)
WHERE UtilisedTime <> 0


UPDATE #DailyProductionFromAutodataT1
SET
	--OverAllEfficiency = (ProductionEfficiency * AvailabilityEfficiency)*100,
	 OverAllEfficiency = CASe WHEN (SELECT OEEFormula FROM MachineOEEFormula_Shanti where MachineID = #DailyProductionFromAutodataT1.MachineID) = 'AE'
           THEN (AvailabilityEfficiency)*100
		   --ELSE (ProductionEfficiency * AvailabilityEfficiency ) *100
		   WHEN (SELECT OEEFormula FROM MachineOEEFormula_Shanti where MachineID = #DailyProductionFromAutodataT1.MachineID) = 'AE*PE'
		   THEN (ProductionEfficiency * AvailabilityEfficiency ) *100
		   ELSE (ProductionEfficiency * AvailabilityEfficiency * ISNULL(QualityEfficiency,1))*100
		   END,  
	ProductionEfficiency = ProductionEfficiency * 100 ,
	AvailabilityEfficiency = AvailabilityEfficiency * 100,
	QualityEfficiency=QualityEfficiency*100

if @param=''
begin
select  #DailyProductionFromAutodataT1.MachineID,
	#DailyProductionFromAutodataT1.GroupID,
	ISNULL(ROUND(#DailyProductionFromAutodataT1.ProductionEfficiency,2),0) as ProductionEfficiency,
	ISNULL(ROUND(#DailyProductionFromAutodataT1.AvailabilityEfficiency,2),0) as AvailabilityEfficiency,
	isnull(Round(#DailyProductionFromAutodataT1.QualityEfficiency,2),0) as QualityEfficiency,

	--isnull(Round(#DailyProductionFromAutodataT1.RejCount,2),0) as RejCount,
	isnull(Round(#DailyProductionFromAutodataT2.CountShiftTotal,2),0) as CountShiftTotal,

	--isnull(round(((#DailyProductionFromAutodataT2.CountShiftTotal/#DailyProductionFromAutodataT2.TargetCount)*100),2),0) as [Percent],

	ISNULL(ROUND(#DailyProductionFromAutodataT1.OverallEfficiency,2),0) as OverallEfficiency,
	dbo.f_formattime(#DailyProductionFromAutodataT1.DownTime, @timeformat) as frmtDownTime,
	isnull(#DailyProductionFromAutodataT2.Component,'') as Component,
	isnull(#DailyProductionFromAutodataT2.Operation,'') as Operation,

	--ROUND(isnull(#DailyProductionFromAutodataT2.CycleTime,0),2) as frmtCycleTime,	
	--ROUND(isnull(#DailyProductionFromAutodataT2.LoadUnload,0),2) as frmtLoadUnload,
	--ROUND(isnull(#DailyProductionFromAutodataT2.AvgCycleTime,0), 2) as frmtAvgCycleTime,
	--ROUND(isnull(#DailyProductionFromAutodataT2.AvgLoadUnload,0),2) as frmtAvgLoadUnload,

	dbo.f_formattime(isnull(#DailyProductionFromAutodataT2.CycleTime,0),@timeformat) as frmtCycleTime,	
	dbo.f_formattime(isnull(#DailyProductionFromAutodataT2.LoadUnload,0),@timeformat) as frmtLoadUnload,
	dbo.f_formattime(isnull(#DailyProductionFromAutodataT2.AvgCycleTime,0), @timeformat) as frmtAvgCycleTime,
	dbo.f_formattime(isnull(#DailyProductionFromAutodataT2.AvgLoadUnload,0),@timeformat) as frmtAvgLoadUnload,



	isnull(#DailyProductionFromAutodataT2.NameShift1,@shiftname1) as NameShift1,
	isnull(Round(#DailyProductionFromAutodataT2.CountShift1,2),0)as CountShift1, --NR0097 Added Round Function
	isnull(#DailyProductionFromAutodataT2.NameShift2,@shiftname2) as NameShift2,
	isnull(Round(#DailyProductionFromAutodataT2.CountShift2,2),0)as CountShift2, --NR0097 Added Round Function
	isnull(#DailyProductionFromAutodataT2.NameShift3,@shiftname3) as NameShift3,
	isnull(Round(#DailyProductionFromAutodataT2.CountShift3,2),0) as CountShift3, --NR0097 Added Round Function
	cyclefficiency =
	CASE
	   when ( isnull(#DailyProductionFromAutodataT2.CycleTime,0) > 0 and
		  isnull(#DailyProductionFromAutodataT2.AvgCycleTime,0) > 0
		) then ROUND((#DailyProductionFromAutodataT2.CycleTime/#DailyProductionFromAutodataT2.AvgCycleTime)*100,2)
	   else 0
	END,
	LoadUnloadefficiency =
	CASE
	   when ( isnull(#DailyProductionFromAutodataT2.LoadUnload,0) > 0 and
		  isnull(#DailyProductionFromAutodataT2.AvgLoadUnload,0) > 0
		) then ROUND((#DailyProductionFromAutodataT2.LoadUnload/#DailyProductionFromAutodataT2.AvgLoadUnload)*100,2)
	   else 0
	END,
	--cast(cast(DateName(month,#DailyProductionFromAutodataT1.pdate)as nvarchar(3))+'-'+cast(datepart(dd,#DailyProductionFromAutodataT1.Pdate)as nvarchar(2))+'-'+cast(datepart(yyyy,#DailyProductionFromAutodataT1.Pdate)as nvarchar(4))as nvarchar(20)) as Day,
	--case when datalength(CAST(Month(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)))=2 then '0'+CAST(Month(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)) else CAST(Month(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)) end+cast(cast(DateName(month,#DailyProductionFromAutodataT1.pdate)as nvarchar(3))+'-'+case when datalength(CAST(Day(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)))=2 then '0'+CAST(Day(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)) else CAST(Day(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)) end+'-'+cast(datepart(yyyy,#DailyProductionFromAutodataT1.Pdate)as nvarchar(4))as nvarchar(20)) as Day,
	cast(cast(datepart(yyyy,#DailyProductionFromAutodataT1.Pdate)as nvarchar(4))+case when datalength(CAST(Month(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)))=2 then '0'+CAST(Month(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)) else CAST(Month(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)) end+cast(DateName(month,#DailyProductionFromAutodataT1.pdate)as nvarchar(3))+'-'+case when datalength(CAST(Day(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)))=2 then '0'+CAST(Day(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)) else CAST(Day(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)) end+'-'+cast(datepart(yyyy,#DailyProductionFromAutodataT1.Pdate)as nvarchar(4))as nvarchar(20)) as Day,
	isnull(#DailyProductionFromAutodataT2.TargetCount,0) as Target,M.description as Machinedescription
from   #DailyProductionFromAutodataT1 
inner join machineinformation M on #DailyProductionFromAutodataT1.MachineID=M.machineid
LEFT OUTER JOIN #DailyProductionFromAutodataT2 ON
	#DailyProductionFromAutodataT1.MachineID = #DailyProductionFromAutodataT2.MachineID
	and #DailyProductionFromAutodataT1.GroupID = #DailyProductionFromAutodataT2.GroupID
	and #DailyProductionFromAutodataT1.Pdate=#DailyProductionFromAutodataT2.Cdate
	where (#DailyProductionFromAutodataT1.DownTime > 0 or #DailyProductionFromAutodataT2.CycleTime>0 
	or (#DailyProductionFromAutodataT2.CountShift1+#DailyProductionFromAutodataT2.CountShift2+#DailyProductionFromAutodataT2.CountShift3)>0)
	order by #DailyProductionFromAutodataT1.Pdate,#DailyProductionFromAutodataT1.GroupID,#DailyProductionFromAutodataT2.Operation
END

if @param='Summary'
begin
SELECT t1.day,T1.GroupID,t1.Operation,SUM(T1.CountShift1) AS TotalCountshift1,sum(T1.CountShift2) AS TotalCountshift2,SUM(T1.CountShift3) as TotalCountshift3,sum(T1.CountShiftTotal) AS TotalProduction,ROUND(AVG(T1.OverallEfficiency),2) as OverallEfficiency FROM(
select  #DailyProductionFromAutodataT1.MachineID,
	#DailyProductionFromAutodataT1.GroupID,
	ISNULL(ROUND(#DailyProductionFromAutodataT1.ProductionEfficiency,2),0) as ProductionEfficiency,
	ISNULL(ROUND(#DailyProductionFromAutodataT1.AvailabilityEfficiency,2),0) as AvailabilityEfficiency,
	isnull(Round(#DailyProductionFromAutodataT1.QualityEfficiency,2),0) as QualityEfficiency,

	--isnull(Round(#DailyProductionFromAutodataT1.RejCount,2),0) as RejCount,
	isnull(Round(#DailyProductionFromAutodataT2.CountShiftTotal,2),0) as CountShiftTotal,

	ISNULL(ROUND(#DailyProductionFromAutodataT1.OverallEfficiency,2),0) as OverallEfficiency,
	dbo.f_formattime(#DailyProductionFromAutodataT1.DownTime, @timeformat) as frmtDownTime,
	isnull(#DailyProductionFromAutodataT2.Component,'') as Component,
	isnull(#DailyProductionFromAutodataT2.Operation,'') as Operation,

	--ROUND(isnull(#DailyProductionFromAutodataT2.CycleTime,0),2) as frmtCycleTime,	
	--ROUND(isnull(#DailyProductionFromAutodataT2.LoadUnload,0),2) as frmtLoadUnload,
	--ROUND(isnull(#DailyProductionFromAutodataT2.AvgCycleTime,0), 2) as frmtAvgCycleTime,
	--ROUND(isnull(#DailyProductionFromAutodataT2.AvgLoadUnload,0),2) as frmtAvgLoadUnload,

	dbo.f_formattime(isnull(#DailyProductionFromAutodataT2.CycleTime,0),@timeformat) as frmtCycleTime,	
	dbo.f_formattime(isnull(#DailyProductionFromAutodataT2.LoadUnload,0),@timeformat) as frmtLoadUnload,
	dbo.f_formattime(isnull(#DailyProductionFromAutodataT2.AvgCycleTime,0), @timeformat) as frmtAvgCycleTime,
	dbo.f_formattime(isnull(#DailyProductionFromAutodataT2.AvgLoadUnload,0),@timeformat) as frmtAvgLoadUnload,


	isnull(#DailyProductionFromAutodataT2.NameShift1,@shiftname1) as NameShift1,
	isnull(Round(#DailyProductionFromAutodataT2.CountShift1,2),0)as CountShift1, --NR0097 Added Round Function
	isnull(#DailyProductionFromAutodataT2.NameShift2,@shiftname2) as NameShift2,
	isnull(Round(#DailyProductionFromAutodataT2.CountShift2,2),0)as CountShift2, --NR0097 Added Round Function
	isnull(#DailyProductionFromAutodataT2.NameShift3,@shiftname3) as NameShift3,
	isnull(Round(#DailyProductionFromAutodataT2.CountShift3,2),0) as CountShift3, --NR0097 Added Round Function
	cyclefficiency =
	CASE
	   when ( isnull(#DailyProductionFromAutodataT2.CycleTime,0) > 0 and
		  isnull(#DailyProductionFromAutodataT2.AvgCycleTime,0) > 0
		) then ROUND((#DailyProductionFromAutodataT2.CycleTime/#DailyProductionFromAutodataT2.AvgCycleTime)*100,2)
	   else 0
	END,
	LoadUnloadefficiency =
	CASE
	   when ( isnull(#DailyProductionFromAutodataT2.LoadUnload,0) > 0 and
		  isnull(#DailyProductionFromAutodataT2.AvgLoadUnload,0) > 0
		) then ROUND((#DailyProductionFromAutodataT2.LoadUnload/#DailyProductionFromAutodataT2.AvgLoadUnload)*100,2)
	   else 0
	END,
	--cast(cast(DateName(month,#DailyProductionFromAutodataT1.pdate)as nvarchar(3))+'-'+cast(datepart(dd,#DailyProductionFromAutodataT1.Pdate)as nvarchar(2))+'-'+cast(datepart(yyyy,#DailyProductionFromAutodataT1.Pdate)as nvarchar(4))as nvarchar(20)) as Day,
	--case when datalength(CAST(Month(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)))=2 then '0'+CAST(Month(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)) else CAST(Month(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)) end+cast(cast(DateName(month,#DailyProductionFromAutodataT1.pdate)as nvarchar(3))+'-'+case when datalength(CAST(Day(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)))=2 then '0'+CAST(Day(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)) else CAST(Day(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)) end+'-'+cast(datepart(yyyy,#DailyProductionFromAutodataT1.Pdate)as nvarchar(4))as nvarchar(20)) as Day,
	cast(cast(datepart(yyyy,#DailyProductionFromAutodataT1.Pdate)as nvarchar(4))+case when datalength(CAST(Month(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)))=2 then '0'+CAST(Month(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)) else CAST(Month(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)) end+cast(DateName(month,#DailyProductionFromAutodataT1.pdate)as nvarchar(3))+'-'+case when datalength(CAST(Day(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)))=2 then '0'+CAST(Day(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)) else CAST(Day(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)) end+'-'+cast(datepart(yyyy,#DailyProductionFromAutodataT1.Pdate)as nvarchar(4))as nvarchar(20)) as Day,
	isnull(#DailyProductionFromAutodataT2.TargetCount,0) as Target,M.description as Machinedescription
from   #DailyProductionFromAutodataT1 
inner join machineinformation M on #DailyProductionFromAutodataT1.MachineID=M.machineid
LEFT OUTER JOIN #DailyProductionFromAutodataT2 ON
	#DailyProductionFromAutodataT1.MachineID = #DailyProductionFromAutodataT2.MachineID
	and #DailyProductionFromAutodataT1.GroupID = #DailyProductionFromAutodataT2.GroupID
	and #DailyProductionFromAutodataT1.Pdate=#DailyProductionFromAutodataT2.Cdate
	where (#DailyProductionFromAutodataT1.DownTime > 0 or #DailyProductionFromAutodataT2.CycleTime>0 
	or (#DailyProductionFromAutodataT2.CountShift1+#DailyProductionFromAutodataT2.CountShift2+#DailyProductionFromAutodataT2.CountShift3)>0)
	--order by #DailyProductionFromAutodataT1.GroupID,#DailyProductionFromAutodataT1.MachineID,#DailyProductionFromAutodataT2.Operation
)T1 
group by t1.Day,T1.GroupID,T1.Operation
order by t1.Day,T1.GroupID,T1.Operation
end





if @param='FinalSummary'
begin
select t1.Day, t1.Groupid,T1.Operation,sum(T1.Target) as [Plan],sum(T1.CountShiftTotal) AS Actual,round((sum(T1.CountShiftTotal)/sum(nullif(t1.Target,0)))*100,2) as [Percent], ROUND(AVG(T1.OverallEfficiency),2) as OverallEfficiency  from(
select  #DailyProductionFromAutodataT1.MachineID,
	#DailyProductionFromAutodataT1.GroupID,
	ISNULL(ROUND(#DailyProductionFromAutodataT1.ProductionEfficiency,2),0) as ProductionEfficiency,
	ISNULL(ROUND(#DailyProductionFromAutodataT1.AvailabilityEfficiency,2),0) as AvailabilityEfficiency,
	isnull(Round(#DailyProductionFromAutodataT1.QualityEfficiency,2),0) as QualityEfficiency,

	--isnull(Round(#DailyProductionFromAutodataT1.RejCount,2),0) as RejCount,
	isnull(Round(#DailyProductionFromAutodataT2.CountShiftTotal,2),0) as CountShiftTotal,
	--isnull(round(((#DailyProductionFromAutodataT2.CountShiftTotal/#DailyProductionFromAutodataT2.TargetCount)*100),2),0) as [Percent],

	ISNULL(ROUND(#DailyProductionFromAutodataT1.OverallEfficiency,2),0) as OverallEfficiency,
	dbo.f_formattime(#DailyProductionFromAutodataT1.DownTime, @timeformat) as frmtDownTime,
	isnull(#DailyProductionFromAutodataT2.Component,'') as Component,
	isnull(#DailyProductionFromAutodataT2.Operation,'') as Operation,

	--ROUND(isnull(#DailyProductionFromAutodataT2.CycleTime,0),2) as frmtCycleTime,	
	--ROUND(isnull(#DailyProductionFromAutodataT2.LoadUnload,0),2) as frmtLoadUnload,
	--ROUND(isnull(#DailyProductionFromAutodataT2.AvgCycleTime,0), 2) as frmtAvgCycleTime,
	--ROUND(isnull(#DailyProductionFromAutodataT2.AvgLoadUnload,0),2) as frmtAvgLoadUnload,

	dbo.f_formattime(isnull(#DailyProductionFromAutodataT2.CycleTime,0),@timeformat) as frmtCycleTime,	
	dbo.f_formattime(isnull(#DailyProductionFromAutodataT2.LoadUnload,0),@timeformat) as frmtLoadUnload,
	dbo.f_formattime(isnull(#DailyProductionFromAutodataT2.AvgCycleTime,0), @timeformat) as frmtAvgCycleTime,
	dbo.f_formattime(isnull(#DailyProductionFromAutodataT2.AvgLoadUnload,0),@timeformat) as frmtAvgLoadUnload,

	isnull(#DailyProductionFromAutodataT2.NameShift1,@shiftname1) as NameShift1,
	isnull(Round(#DailyProductionFromAutodataT2.CountShift1,2),0)as CountShift1, --NR0097 Added Round Function
	isnull(#DailyProductionFromAutodataT2.NameShift2,@shiftname2) as NameShift2,
	isnull(Round(#DailyProductionFromAutodataT2.CountShift2,2),0)as CountShift2, --NR0097 Added Round Function
	isnull(#DailyProductionFromAutodataT2.NameShift3,@shiftname3) as NameShift3,
	isnull(Round(#DailyProductionFromAutodataT2.CountShift3,2),0) as CountShift3, --NR0097 Added Round Function
	cyclefficiency =
	CASE
	   when ( isnull(#DailyProductionFromAutodataT2.CycleTime,0) > 0 and
		  isnull(#DailyProductionFromAutodataT2.AvgCycleTime,0) > 0
		) then ROUND((#DailyProductionFromAutodataT2.CycleTime/#DailyProductionFromAutodataT2.AvgCycleTime)*100,2)
	   else 0
	END,
	LoadUnloadefficiency =
	CASE
	   when ( isnull(#DailyProductionFromAutodataT2.LoadUnload,0) > 0 and
		  isnull(#DailyProductionFromAutodataT2.AvgLoadUnload,0) > 0
		) then ROUND((#DailyProductionFromAutodataT2.LoadUnload/#DailyProductionFromAutodataT2.AvgLoadUnload)*100,2)
	   else 0
	END,
	--cast(cast(DateName(month,#DailyProductionFromAutodataT1.pdate)as nvarchar(3))+'-'+cast(datepart(dd,#DailyProductionFromAutodataT1.Pdate)as nvarchar(2))+'-'+cast(datepart(yyyy,#DailyProductionFromAutodataT1.Pdate)as nvarchar(4))as nvarchar(20)) as Day,
	--case when datalength(CAST(Month(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)))=2 then '0'+CAST(Month(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)) else CAST(Month(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)) end+cast(cast(DateName(month,#DailyProductionFromAutodataT1.pdate)as nvarchar(3))+'-'+case when datalength(CAST(Day(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)))=2 then '0'+CAST(Day(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)) else CAST(Day(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)) end+'-'+cast(datepart(yyyy,#DailyProductionFromAutodataT1.Pdate)as nvarchar(4))as nvarchar(20)) as Day,
	cast(cast(datepart(yyyy,#DailyProductionFromAutodataT1.Pdate)as nvarchar(4))+case when datalength(CAST(Month(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)))=2 then '0'+CAST(Month(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)) else CAST(Month(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)) end+cast(DateName(month,#DailyProductionFromAutodataT1.pdate)as nvarchar(3))+'-'+case when datalength(CAST(Day(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)))=2 then '0'+CAST(Day(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)) else CAST(Day(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)) end+'-'+cast(datepart(yyyy,#DailyProductionFromAutodataT1.Pdate)as nvarchar(4))as nvarchar(20)) as Day,
	isnull(#DailyProductionFromAutodataT2.TargetCount,0) as Target,M.description as Machinedescription
from   #DailyProductionFromAutodataT1 
inner join machineinformation M on #DailyProductionFromAutodataT1.MachineID=M.machineid
LEFT OUTER JOIN #DailyProductionFromAutodataT2 ON
	#DailyProductionFromAutodataT1.MachineID = #DailyProductionFromAutodataT2.MachineID
	and #DailyProductionFromAutodataT1.GroupID = #DailyProductionFromAutodataT2.GroupID
	and #DailyProductionFromAutodataT1.Pdate=#DailyProductionFromAutodataT2.Cdate
	where (#DailyProductionFromAutodataT1.DownTime > 0 or #DailyProductionFromAutodataT2.CycleTime>0 
	or (#DailyProductionFromAutodataT2.CountShift1+#DailyProductionFromAutodataT2.CountShift2+#DailyProductionFromAutodataT2.CountShift3)>0)
	--order by #DailyProductionFromAutodataT1.GroupID,#DailyProductionFromAutodataT1.MachineID,#DailyProductionFromAutodataT2.Operation
)T1 
group by t1.Day, T1.GroupID,t1.Operation
ORDER BY t1.Day, T1.GroupID,T1.Operation
end
--IF @Param='Summary'
--Begin
--	select  ROUND(AVG(T1.ProductionEfficiency),2) as ProductionEfficiency,            
--		ROUND(AVG(T1.AvailabilityEfficiency),2) as AvailabilityEfficiency,
--		ROUND(AVG(T1.QualityEfficiency),2) as QualityEfficiency,
--		ROUND(AVG(T1.OverallEfficiency),2) as OverallEfficiency,
--		dbo.f_formattime(sum(T1.frmtDownTime), @timeformat) as TotalDownTime
--	from (select  #DailyProductionFromAutodataT1.MachineID,
--	#DailyProductionFromAutodataT1.GroupID,
--	ISNULL(ROUND(#DailyProductionFromAutodataT1.ProductionEfficiency,2),0) as ProductionEfficiency,
--	ISNULL(ROUND(#DailyProductionFromAutodataT1.AvailabilityEfficiency,2),0) as AvailabilityEfficiency,
--	isnull(Round(#DailyProductionFromAutodataT1.QualityEfficiency,2),0) as QualityEfficiency,

--	--isnull(Round(#DailyProductionFromAutodataT1.RejCount,2),0) as RejCount,
--	--isnull(Round(#DailyProductionFromAutodataT2.CountShiftTotal,2),0) as CountShiftTotal,

--	ISNULL(ROUND(#DailyProductionFromAutodataT1.OverallEfficiency,2),0) as OverallEfficiency,
--	isnull(#DailyProductionFromAutodataT1.DownTime,0) as frmtDownTime,
--	isnull(#DailyProductionFromAutodataT2.Component,'') as Component,
--	isnull(#DailyProductionFromAutodataT2.Operation,'') as Operation,
--	ROUND(isnull(#DailyProductionFromAutodataT2.CycleTime,0),2) as frmtCycleTime,	
--	ROUND(isnull(#DailyProductionFromAutodataT2.LoadUnload,0),2) as frmtLoadUnload,
--	ROUND(isnull(#DailyProductionFromAutodataT2.AvgCycleTime,0), 2) as frmtAvgCycleTime,
--	ROUND(isnull(#DailyProductionFromAutodataT2.AvgLoadUnload,0),2) as frmtAvgLoadUnload,
--	isnull(#DailyProductionFromAutodataT2.NameShift1,@shiftname1) as NameShift1,
--	isnull(Round(#DailyProductionFromAutodataT2.CountShift1,2),0)as CountShift1, --NR0097 Added Round Function
--	isnull(#DailyProductionFromAutodataT2.NameShift2,@shiftname2) as NameShift2,
--	isnull(Round(#DailyProductionFromAutodataT2.CountShift2,2),0)as CountShift2, --NR0097 Added Round Function
--	isnull(#DailyProductionFromAutodataT2.NameShift3,@shiftname3) as NameShift3,
--	isnull(Round(#DailyProductionFromAutodataT2.CountShift3,2),0) as CountShift3, --NR0097 Added Round Function
--	cyclefficiency =
--	CASE
--	   when ( isnull(#DailyProductionFromAutodataT2.CycleTime,0) > 0 and
--		  isnull(#DailyProductionFromAutodataT2.AvgCycleTime,0) > 0
--		) then ROUND((#DailyProductionFromAutodataT2.CycleTime/#DailyProductionFromAutodataT2.AvgCycleTime)*100,2)
--	   else 0
--	END,
--	LoadUnloadefficiency =
--	CASE
--	   when ( isnull(#DailyProductionFromAutodataT2.LoadUnload,0) > 0 and
--		  isnull(#DailyProductionFromAutodataT2.AvgLoadUnload,0) > 0
--		) then ROUND((#DailyProductionFromAutodataT2.LoadUnload/#DailyProductionFromAutodataT2.AvgLoadUnload)*100,2)
--	   else 0
--	END,
--	--cast(cast(DateName(month,#DailyProductionFromAutodataT1.pdate)as nvarchar(3))+'-'+cast(datepart(dd,#DailyProductionFromAutodataT1.Pdate)as nvarchar(2))+'-'+cast(datepart(yyyy,#DailyProductionFromAutodataT1.Pdate)as nvarchar(4))as nvarchar(20)) as Day,
--	--case when datalength(CAST(Month(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)))=2 then '0'+CAST(Month(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)) else CAST(Month(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)) end+cast(cast(DateName(month,#DailyProductionFromAutodataT1.pdate)as nvarchar(3))+'-'+case when datalength(CAST(Day(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)))=2 then '0'+CAST(Day(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)) else CAST(Day(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)) end+'-'+cast(datepart(yyyy,#DailyProductionFromAutodataT1.Pdate)as nvarchar(4))as nvarchar(20)) as Day,
--	cast(cast(datepart(yyyy,#DailyProductionFromAutodataT1.Pdate)as nvarchar(4))+case when datalength(CAST(Month(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)))=2 then '0'+CAST(Month(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)) else CAST(Month(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)) end+cast(DateName(month,#DailyProductionFromAutodataT1.pdate)as nvarchar(3))+'-'+case when datalength(CAST(Day(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)))=2 then '0'+CAST(Day(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)) else CAST(Day(#DailyProductionFromAutodataT1.Pdate)as nvarchar(2)) end+'-'+cast(datepart(yyyy,#DailyProductionFromAutodataT1.Pdate)as nvarchar(4))as nvarchar(20)) as Day,
--	isnull(#DailyProductionFromAutodataT2.TargetCount,0) as Target,M.description as Machinedescription
--from   #DailyProductionFromAutodataT1 
--inner join machineinformation M on #DailyProductionFromAutodataT1.MachineID=M.machineid
--LEFT OUTER JOIN #DailyProductionFromAutodataT2 ON
--	#DailyProductionFromAutodataT1.MachineID = #DailyProductionFromAutodataT2.MachineID
--	and #DailyProductionFromAutodataT1.GroupID = #DailyProductionFromAutodataT2.GroupID
--	and #DailyProductionFromAutodataT1.Pdate=#DailyProductionFromAutodataT2.Cdate
--	where (#DailyProductionFromAutodataT1.DownTime > 0 or #DailyProductionFromAutodataT2.CycleTime>0 
--	or (#DailyProductionFromAutodataT2.CountShift1+#DailyProductionFromAutodataT2.CountShift2+#DailyProductionFromAutodataT2.CountShift3)>0)

--	)T1
--END



END
