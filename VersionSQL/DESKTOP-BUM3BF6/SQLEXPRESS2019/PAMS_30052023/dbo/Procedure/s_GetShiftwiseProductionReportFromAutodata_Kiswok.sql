/****** Object:  Procedure [dbo].[s_GetShiftwiseProductionReportFromAutodata_Kiswok]    Committed by VersionSQL https://www.versionsql.com ******/

/***************************************************************************************************
Procedure altered by Sangeeta Kallur on 16-Feb-06
To include threshold(Down)in ManagementLoss Calculation
Chaged by Sangeeta Kallur to add Operator name
Changed By Sangeeta Kallur 30-June-2006
To Support Down within Production Cycle.[ManuGraph - Solution-2]
Changed By SSK on 10-July-2006 :- Sub Operations at CO Level [Autoaxel]
Changed [CN,OperationCount ,Actual-AvgCycleTime , Actual-AvgLoadUnloadTime Caln]
Procudure altered by SSK on 05/Oct/2006 to include plant level concept
Procedure Altered By SSK on 06-Dec-2006 :
	To Remove Constraint Name & add it as Primary Key
Altered by Mrudula to get Production and target for selected period of time nore than one day.
Procedure Changed By Sangeeta Kallur on 01-MAR-2007 :
	To Change Production count Which gets affected for Multispindle type of machines.
Modification 1:-Dr0016 By Mrudula on 24-july-2007
Description for DR0016:- Consider only those records for calculating Avg loadunload and loadunload efficiency
whose loadunload is greater than or equal to MinLUforLR from shopdefaults
mod 2:- for DR0091 by Mrudula on 14-feb-2008. To remove grouping by parts count
mod 3:- for DR0092 by Mrudula on 14-feb-2008. To change the  ordering  o fthe output.
--mod 4:- Optimization by Mrudula
mod 5 :- for DR0169 by Mrudula on 27-feb-2009. To delete entries from shift_proc table if
	 entries are there for  the current session.
mod 6 :- Optimization by Mrudula on 28-feb-2009.
mod 7 :- ER0181 By Kusuma M.H on 08-May-2009.2) Modify all the procedures accordingly. Qualify machine wherever we are making use of component and opeartion no.
mod 8 :- ER0182 By Kusuma M.H on 08-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
mod 9 :- DR0213 by Mrudula M. Rao on 25-Sep-2009. Divide by zero error is coming. put autodata.partscount>0 for calculating average values
mod 10:- DR0222 by Mrudula M. Rao on 20-oct-2009.20534  error detected by batabase DLL. (String or binary data would be truncated).
	 Increase the length of operator id column.
mod 11:- DR0225 by Mrudula M. Rao on 17-dec-2009.Efficiencies are in -ve. Problem is in calculation if utilised time.
	Not qualifying with shift starttime and endtime while eleminating ICD from Utilised time,
mod 12:- ER0210 Introduce PDT on 5150. 1) Handle PDT at Machine Level.
			2) Handle interaction between PDT and Mangement Loss. Also handle interaction InCycleDown And PDT.
			3) Improve the performance.
			4) Handle intearction between ICD and PDT for type 1 production record for the selected time period.
modified on 28-dec-2009.5)Not handled PDT in getting target .
select * from planneddowntimes
DR0236 - KarthikG - 19/Jun/2010 :: Use proper conditions in case statements to remove icd's from type 4 production records.
mod 13: - DR0263- Karthick R - 21/oct/2010.To Apply PDT for target also for Avg cycletime
ER0282 - KarthickR\SwathiKS - 22-Mar-2011 ::Optimization To increase Performance.
ER0291 - SwathiKS - 24/Jun/2011 :: Optimize to increase Performance.
DR0299 - SnehaK - 10/Nov/2011 :: To include Machine validation.
ER0319 - KarthikR - 04/Jan/2012 :: To include one more parameter type to show shiftwise utlised time,dowtime,Count with OEE color for cummins
ER0324 - KarthikR/SwathiKS - 04/Feb/2012 :: a> Optimize to increase Performance.
                                            b> To Handle Negative Efficiency.(Due to negative utilisedtime).
											c> To Rename Utilised Column from frmtDownTime to frmtUtilisedTime.
DR0313 - KarthikR - 14/Aug/12 ::To handle error  Invalid object Name PK_Autodata because it is already exists For Cummins.
DR0327 - SwathiKS - 25/Apr/2013 :: To handle Negative AverageCycletime during PDT.
DR0325 - SwathiKS - 13/May/2013 :: a> To handle PDT for Avgloadunload and Avgcycletime.
				   b> For Utilised calculation To consider difference between Autodata msttime and ndtime instead of NetCycletime for Tyep1 Record with PDT.
ER0363 - SwathiKS - 12/Aug/2013 :: To Consider PDT for AverageCycletime and AvgLoadunload Based on Setting in CockpitDefaults i.e 
(Ignore_Ptime_4m_PLD)='Y' and (Ignore_AvgCycletime_4m_PLD)='Y'
NR0097 - SwathiKS - 21/Jan/2014 :: Since we are splitting Production and Down Cycle across shifts while showing partscount we have to consider decimal values instead whole Numbers.
DR0339 - SwathiKS - 25/Feb/2014 :: While handling ICD-PDT Interaction for Type-1,we have to pick cycles which has ProductionStart=ICDStart and ProductionEnd=ICDEnd.
ER0374 - SwathiKS - 19/Jun/2014 :: If Third shift falls under next day then report was not showing output.
ER0414 - Vasavi - 29/Jul/2015 :: To Include New Parameter "Shift" to change Output Format for Ace.
ER0450 - SwathiKS - 10/oct/2017 :: If the CompanyName Contains "SHANTI IRON AND STEEL FOUNDRY" then Show OperationDescription Instead of OperationNo in the following Reports.
a> SM-Std-Production Report Machinewise-shift-Format1
b> SM-Std-Production and Down Report Machinewise-Format1

s_GetShiftwiseProductionReportFromAutodata_Kiswok '2020-11-02','','Equator Phantom','','','','','2020-11-02','shift'
s_GetShiftwiseProductionReportFromAutodata_Kiswok '2020-11-02','','Laser Marking Machine Compact x','','','','','2020-11-03','shift'


**************************************************************************************************/
/*
----s_GetShiftwiseProductionReportFromAutodata_Kiswok '2012-08-01','','IMPELLER OP 10 B','','','','2012-08-02','Shift_UT_DT'
----s_GetShiftwiseProductionReportFromAutodata_Kiswok '2021-04-01','','','','','','SHOP 3','2021-04-12','shift'
----s_GetShiftwiseProductionReportFromAutodata_Kiswok '2019-07-10','','','','','','2019-07-10','ProdandDown'
s_GetShiftwiseProductionReportFromAutodata_Kiswok '2021-03-18','','','','','','','2021-03-18','Summary'
s_GetShiftwiseProductionReportFromAutodata_Kiswok '2021-03-18','','','','','','','2021-03-18','Shift'

*/
CREATE PROCEDURE [dbo].[s_GetShiftwiseProductionReportFromAutodata_Kiswok]
	@StartDate datetime,
	@ShiftIn nvarchar(20) = '',
	@MachineID nvarchar(50) = '',
	@GroupID As nvarchar(50) = '',
	@ComponentID nvarchar(50) = '',
	@OperationNo nvarchar(50) = '',
	@PlantID NvarChar(50)='',
	@EndDate datetime='',
	@Param nvarchar(20)=''  
	
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

--------------------Temp tables------------------------------------------------------
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
	--ExCount Int DEFAULT 0,
	IdealCount float,
	ActualCount float,
	ExCount float DEFAULT 0,
	--NR0097
	Sdate datetime not null, --ER0280
	ShiftName nvarchar(50)  --ER0280
)
--Shift Details

/* DR0313 Commented From Here
--ER0324 Added From Here
CREATE TABLE #T_autodata(
	[mc] [nvarchar](50)not NULL,
	[comp] [nvarchar](50) NULL,
	[opn] [nvarchar](50) NULL,
	[opr] [nvarchar](50) NULL,
	[dcode] [nvarchar](50) NULL,
	[sttime] [datetime] not NULL,
	[ndtime] [datetime] NULL,
	[datatype] [tinyint] NULL ,
	[cycletime] [int] NULL,
	[loadunload] [int] NULL ,
	[msttime] [datetime] NULL,
	[PartsCount] [int] NULL ,
	id  bigint not null
 CONSTRAINT [PK_autodata] PRIMARY KEY CLUSTERED 
(
	mc,sttime ASC
)
)
--ER0324 Added Till Here
DR0313 Commented Till Here */

--DR0313 added From Here
CREATE TABLE #T_autodata(
	[mc] [nvarchar](50)not NULL,
	[comp] [nvarchar](50) NULL,
	[opn] [nvarchar](50) NULL,
	[opr] [nvarchar](50) NULL,
	[dcode] [nvarchar](50) NULL,
	[sttime] [datetime] not NULL,
	[ndtime] [datetime] NULL,
	[datatype] [tinyint] NULL ,
	[cycletime] [int] NULL,
	[loadunload] [int] NULL ,
	[msttime] [datetime] NULL,
	--[PartsCount] [int] NULL , --NR0097
	[PartsCount] decimal(18,5) NULL , --NR0097
	id  bigint not null
)
--DR0313 Added Till here

CREATE TABLE #ShiftProductionFromAutodataT0 (
	PDate datetime,
	Shift nvarchar(20),
	ShiftStart datetime,
	ShiftEnd datetime
)
--Operator at Machine Level
CREATE TABLE #TmpOperator(
	MachineID nvarchar(50),
	OperatorID Nvarchar(50),
	OperatorName nvarchar(50)
	)
--Machine level details
CREATE TABLE #ShiftProductionFromAutodataT1 (
	MachineInterface nvarchar(50) not null,
	MachineDescription nvarchar(150),
	UstartShift datetime not null,
	UEndShift datetime not null,
	MachineID nvarchar(50) NOT NULL,
	GroupID nvarchar(50),
	---mod 10
	--OperatorID Nvarchar(50) NOT NULL,
	OperatorID Nvarchar(500) NOT NULL,
	OperatorName nvarchar(500) not null,
	---mod 10
	ProductionEfficiency float,
	AvailabilityEfficiency float,
	OverallEfficiency float,
	UtilisedTime float,
	ManagementLoss float,
	DownTime float,
	CN float,
	Udate datetime not null,
	Ushift nvarchar(50)
	--mod 12
	,MLDown float,
	QualityEfficiency float,
	RejCount float,
	shiftid nvarchar(20)
	--mod 12
)
ALTER TABLE #ShiftProductionFromAutodataT1
	ADD PRIMARY KEY CLUSTERED
		(   [MachineInterface],
			[UstartShift],
[UEndShift]
						
		) ON [PRIMARY]


---DR0313 Added From Here
ALTER TABLE #T_autodata

ADD PRIMARY KEY CLUSTERED
(
	mc,sttime ASC
)ON [PRIMARY]
---DR0313 Added Till Here


--ComponentOperation level details
CREATE TABLE #ShiftProductionFromAutodataT2 (
	MachineID nvarchar(50) NOT NULL,
	GroupID nvarchar(50),
	Component nvarchar(50) NOT NULL,
	Operation nvarchar(50) NOT NULL,
	CycleTime float,
	LoadUnload float,
	Avgcycletime float, --DR0325 --NR0097  Uncommented
	Avgloadunload float, --DR0325 --NR0097  Uncommented
	--AvgCycleTime nvarchar(25),  --DR0325
	--AvgLoadUnload nvarchar(25),  --DR0325
	--OperationCount int, --NR0097
	OperationCount float, --NR0097
	Sdate datetime not null,
	ShiftName nvarchar(50),
	ShftStart datetime not null,
	ShftEnd datetime,
	TargetCount int default 0,
	MachineInterface nvarchar(50),
	CompInterface nvarchar(50),
	OpnInterface nvarchar(50),
	PlantID nvarchar(50),
	MachineDescription nvarchar(150)
)
ALTER TABLE #ShiftProductionFromAutodataT2
	ADD PRIMARY KEY CLUSTERED
		(
			[Sdate],[ShftStart],
			[MachineID],
			[Component],
			[Operation]
		) ON [PRIMARY]
create table #Machcomopnopr
	(
		--id  int identity(1,1) Not null,
		Machine nvarchar(50) NOT NULL,
		GroupID nvarchar(50),
		Machineint nvarchar(50),
		MachineDescription nvarchar(150),
		Component nvarchar(50) NOT NULL,
		CompInt nvarchar(50),
		Operation nvarchar(50) NOT NULL,
		opnInt nvarchar(50),
		Operator nvarchar(50),
		OperatorName nvarchar(50),
		Shdate datetime not null,
		ShftName nvarchar(50),
		ShftStrt datetime not null,
		ShftND datetime not null
	)
---mod 12. temp table to store PDT's at shift level
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
---mod 12
--ER0291 From Here.
If @Param = 'ProdandDown'
BEGIN
	Create Table #ShiftwiseProductionForADay
	(
		Machine nvarchar(40),
		Shift nvarchar(20),
		ShftSTarttime datetime,
		ShftndTime datetime
	)
	
	CREATE TABLE #ShiftDefn
	(
		ShiftDate DateTime,		
		Shiftname nvarchar(20),
		ShftSTtime DateTime,
		ShftEndTime DateTime	
	)
	
	CREATE TABLE #MchId
	(
		Machineid Nvarchar(40)
	)
	
	IF  isnull(@Shiftin,'')<> ''
	BEGIN
		INSERT INTO #ShiftDefn(ShiftDate,Shiftname,ShftSTtime,ShftEndTime)
		Exec s_GetShiftTime @StartDate,@Shiftin
	END
	ELSE
	BEGIN
		INSERT INTO #ShiftDefn(ShiftDate,Shiftname,ShftSTtime,ShftEndTime)
		Exec s_GetShiftTime @StartDate,''
	END
END
--ER0291 Till Here.
--------------------Temp tables------------------------------------------------------
declare @strsql nvarchar(4000)
declare @strmachine nvarchar(255)
declare @strcomponentid nvarchar(255)
declare @stroperation nvarchar(255)
declare @timeformat as nvarchar(12)
Declare @StrMPlantID AS NVarchar(255)
Declare @strXoperation AS NVarchar(255)
Declare @strXcomponentid AS NVarchar(255)
Declare @strXmachine AS NVarchar(255)
Declare @StrGroupID AS NVarchar(255)


select @strsql = ''
select @strcomponentid = ''
select @stroperation = ''
select @strmachine = ''
select @strXmachine = ''
select @strXcomponentid = ''
select @strXoperation = ''
Select @StrMPlantID=''
select @StrGroupID=''


Declare @T_ST AS Datetime --ER0324 Added
Declare @T_ED AS Datetime --ER0324 Added
--Declare @strXmachine AS NVarchar(255)
if isnull(@EndDate,'')=''
begin
	select @EndDate=@StartDate
end
if isnull(@PlantID,'') <> ''
begin
---mod 8
--	select @StrMPlantID = ' and ( PlantMachine.PlantID = ''' + @PlantID + ''' )'
	select @StrMPlantID = ' and ( PlantMachine.PlantID = N''' + @PlantID + ''' )'
---mod 8
end
if isnull(@machineid,'') <> ''
begin
---mod 8
--	select @strmachine = ' and ( machineinformation.MachineID = ''' + @MachineID + ''')'
--	select @strXmachine = ' and ( EX.MachineID = ''' + @MachineID + ''')'
	select @strmachine = ' and ( machineinformation.MachineID = N''' + @MachineID + ''')'
	select @strXmachine = ' and ( EX.MachineID = N''' + @MachineID + ''')'
---mod 8
end
if isnull(@componentid,'') <> ''
begin
---mod 8
--	select @strcomponentid = ' AND ( componentinformation.componentid = ''' + @componentid + ''')'
--	select @strXcomponentid = ' AND ( EX.componentid = ''' + @componentid + ''')'
	select @strcomponentid = ' AND ( componentinformation.componentid = N''' + @componentid + ''')'
	select @strXcomponentid = ' AND ( EX.componentid = N''' + @componentid + ''')'
---mod 8
end
if isnull(@operationno, '') <> ''
begin
	---mod 8
--	select @stroperation = ' AND ( componentoperationpricing.operationno = ' + @OperationNo +')'
--	select @strXoperation = ' AND ( EX.operationno = ' + @OperationNo +')'
	select @stroperation = ' AND ( componentoperationpricing.operationno = N''' + @OperationNo +''')'
	select @strXoperation = ' AND ( EX.operationno = N''' + @OperationNo + ''')'
	---mod 8
end


If isnull(@GroupID ,'') <> ''
Begin
Select @StrGroupID = ' And ( PlantMachineGroups.GroupID = N''' + @GroupID + ''')'
End


declare @Targetsource nvarchar(50)
select @Targetsource=ValueInText from Shopdefaults where Parameter='TargetFrom'
declare @StartTime as datetime
declare @EndTime as datetime
declare @CurStrtTime as datetime
declare @CurEndTime as datetime
select @CurStrtTime=@StartDate
select @CurEndTime=@EndDate
--Get Shift Start and Shift End
while @CurStrtTime<=@EndDate
BEGIN
	INSERT #ShiftProductionFromAutodataT0(Pdate, Shift, ShiftStart, ShiftEnd)
	EXEC s_GetShiftTime @CurStrtTime,@ShiftIn
	SELECT @CurStrtTime=DATEADD(DAY,1,@CurStrtTime)
END
Select @T_ST=min(ShiftStart) from #ShiftProductionFromAutodataT0 --ER0324 Added
Select @T_ED=max(ShiftEnd) from #ShiftProductionFromAutodataT0 --ER0324 Added
----ER0291 From here.
If @Param = 'ProdandDown'
BEGIN
	SELECT @StrSql='INSERT INTO #MchId(Machineid)
		SELECT MachineInformation.Machineid FROM MachineInformation
		Left Outer Join PlantMachine on MachineInformation.MachineID=PlantMachine.MachineID
		LEFT JOIN PlantMachineGroups on machineinformation.machineid = PlantMachineGroups.machineid
		Where  MachineInformation.Machineid>''0'''
		SELECT @StrSql=@StrSql + @StrMPlantID + @StrMachine+@StrGroupID
		EXEC(@StrSql)
	
		insert into #ShiftwiseProductionForADay
		SELECT Machineid,Shiftname,ShftSTtime,ShftEndTime FROM #ShiftDefn,#MchId
		group by Machineid,Shiftname,ShftSTtime,ShftEndTime
END
----ER0291 Till here
--mod 4
select @CurStrtTime=''
SELECT @CurEndTime=''
declare @CurShift nvarchar(50)
DECLARE @CurDate datetime
declare @Dateval datetime
declare @shiftstart datetime
declare @shiftend  datetime
declare @shiftnamevalue  nvarchar(20)
declare @MinLuLR  integer
set @MinLuLR=isnull((select top 1 valueinint from Shopdefaults where parameter='MinLUforLR'),0)
---------------------------------by Mrudula for optimization------------------------------------
	print sysdatetime()
		--ER0324 Added From Here
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
		--ER0324 Added Till Here
		
	
		 print sysdatetime()
		Select @strsql=''
		select @strsql ='insert into #Machcomopnopr(Machine,GroupID,MachineInt,MachineDescription,Component,CompInt,Operation,OpnInt,Operator,OperatorName,Shdate,
						ShftName,ShftStrt,ShftND) '
		select @strsql = @strsql + 'SELECT distinct  Machineinformation.Machineid,PlantMachineGroups.GroupID,Machineinformation.interfaceid,Machineinformation.Description,
						componentinformation.componentid,componentinformation.interfaceid,componentoperationpricing.operationno,
						componentoperationpricing.interfaceid,Employeeinformation.Employeeid,Employeeinformation.Name,Pdate, Shift, ShiftStart, ShiftEnd '
		select @strsql = @strsql + ' from #T_autodata autodata inner join machineinformation on machineinformation.interfaceid=autodata.mc inner join ' --ER0324 Added #T_autodata
		select @strsql = @strsql + ' componentinformation ON autodata.comp = componentinformation.InterfaceID  INNER JOIN '
		select @strsql = @strsql + ' componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID)'
		select @strsql = @strsql + ' AND (componentinformation.componentid = componentoperationpricing.componentid) '
		---mod 7
		select @strsql = @strsql + ' and componentoperationpricing.machineid=machineinformation.machineid '
		---mod 7
		select @strsql = @strsql + ' inner join employeeinformation on autodata.opr=employeeinformation.interfaceid'
		select @strsql = @strsql + ' Left Outer Join PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID 
									LEFT JOIN PlantMachineGroups on machineinformation.machineid = PlantMachineGroups.machineid'
		select @strsql = @strsql + ' cross join #ShiftProductionFromAutodataT0 where '
		select @strsql = @strsql + '(( sttime >= shiftstart and ndtime <= shiftend ) OR '
		select @strsql = @strsql + '( sttime < shiftstart and ndtime > shiftend )OR '
		select @strsql = @strsql + '( sttime < shiftstart and ndtime > shiftstart and ndtime<=shiftend )'
		select @strsql = @strsql + ' OR ( sttime >= shiftstart and ndtime > shiftend and sttime<shiftend ) ) and machineinformation.interfaceid>''0'' '
		select @strsql = @strsql + @strmachine+@StrMPlantID++@strcomponentid+@stroperation+@StrGroupID
		select @strsql = @strsql + ' order by Machineinformation.Machineid,shiftstart'
		print @strsql
		exec (@strsql)
	print sysdatetime()
		---mod 5
		delete from shift_proc where SSession=@@SPID
		---mod 5
		
		 insert into shift_proc(SSession,Machine,Mdate,Mshift,MShiftStart,MshiftEnd)
		select distinct @@SPID,Machine,Shdate,ShftName,ShftStrt,ShftND from #Machcomopnopr order by ShftStrt asc
		
		---mod 12 get the PDT's defined,at shift and Machine level
		insert INTO #PlannedDownTimesShift(StartTime,EndTime,Machine,MachineInterface,Downreason,Shiftst)
		select
		CASE When StartTime<T1.ShiftStart Then T1.ShiftStart Else StartTime End,
		case When EndTime>T1.ShiftEnd Then T1.ShiftEnd Else EndTime End,
		Machine,M.InterfaceID,
		DownReason,T1.ShiftStart
		FROM PlannedDownTimes cross join #ShiftProductionFromAutodataT0 T1
		inner join MachineInformation M on PlannedDownTimes.machine = M.MachineID
		WHERE PDTstatus =1 and (
		(StartTime >= T1.ShiftStart  AND EndTime <=T1.ShiftEnd)
		OR ( StartTime < T1.ShiftStart  AND EndTime <= T1.ShiftEnd AND EndTime > T1.ShiftStart )
		OR ( StartTime >= T1.ShiftStart   AND StartTime <T1.ShiftEnd AND EndTime > T1.ShiftEnd )
		OR ( StartTime < T1.ShiftStart  AND EndTime > T1.ShiftEnd) )
		and machine in (select distinct machine from #Machcomopnopr)
		ORDER BY StartTime
		---mod 12 get the PDT's defined,at shift and Machine level
		
		
		/*Select @strsql=''
		select @strsql = 'insert into #ShiftProductionFromAutodataT2 (MachineID,Component,Operation,CycleTime,LoadUnload,AvgLoadUnload,AvgCycleTime,OperationCount, '
		select @strsql = @strsql + 'Sdate,ShiftName,ShftStart,ShftEnd, 	MachineInterface,CompInterface,	OpnInterface) '
		select @strsql = @strsql + ' SELECT DISTINCT Machine ,Component,Operation,0,0,0,0,0,Shdate,
							ShftName,ShftStrt,ShftND,MachineInt,CompInt,OpnInt  FROM #Machcomopnopr '
		print @strsql
		exec (@strsql)
		
---------------------------------by Mrudula till here-------------------------------------------
	
		Select @strsql=''
		select @strsql = 'UPDATE #ShiftProductionFromAutodataT2 SET CycleTime=T1.Cycle, LoadUnload=T1.lLoad,
						AvgLoadUnload=T1.AvgLoad,AvgCycleTime=T1.AvgCycle,OperationCount=T1.OpCount '
		select @strsql = @strsql + ' from ( '
select @strsql = @strsql + ' SELECT distinct  S.MachineID as Mach,S.Component as Compn,S.Operation as Oprn,'
		select @strsql = @strsql + ' componentoperationpricing.machiningtime as Cycle, '
		select @strsql = @strsql + ' (componentoperationpricing.cycletime - componentoperationpricing.machiningtime) as lLoad, '
		select @strsql =@strsql+'AVG(case when (autodata.loadunload>=''' +convert(nvarchar(20),@MinLuLR)+ ''' )  then (autodata.loadunload/autodata.partscount) end ) * ISNULL(ComponentOperationPricing.SubOperations,1) as AvgLoad, '
		select @strsql = @strsql + ' AVG(autodata.cycletime/autodata.partscount) * ISNULL(ComponentOperationPricing.SubOperations,1) as AvgCycle,'
		select @strsql = @strsql + ' CEILING(CAST(Sum(autodata.partscount)AS Float)/ISNULL(ComponentOperationPricing.SubOperations,1)) as OpCount ,'
		select @strsql =@strsql+' S.Sdate as ShDate,S.ShiftName as Shft,S.ShftStart as ShStrt,S.ShftEnd as Shnd '
		select @strsql = @strsql + ' from #T_autodata autodata INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN  '
		select @strsql = @strsql + ' componentinformation ON autodata.comp = componentinformation.InterfaceID  INNER JOIN '
		select @strsql = @strsql + ' componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID)'
		select @strsql = @strsql + ' AND (componentinformation.componentid = componentoperationpricing.componentid) '
		select @strsql = @strsql + ' inner  join  #ShiftProductionFromAutodataT2  S on '
		select @strsql = @strsql + ' S.MachineInterface=autodata.mc and S.CompInterface=autodata.comp and S.OpnInterface=autodata.opn '
		select @strsql = @strsql + ' where machineinformation.interfaceid > 0 '
		select @strsql = @strsql + 'and (( sttime >= S.ShftStart and ndtime <= S.ShftEnd ) OR '
		select @strsql = @strsql + '( sttime < S.ShftStart and ndtime > S.ShftStart and ndtime<=S.ShftEnd ))'
		select @strsql = @strsql + ' and autodata.datatype=1 '
		select @strsql = @strsql + 'group by S.MachineID , S.Component, '
		select @strsql = @strsql + ' S.Operation, '
		select @strsql = @strsql + ' componentoperationpricing.machiningtime,ComponentOperationPricing.SubOperations,componentoperationpricing.cycletime,S.Sdate,S.ShiftName,S.ShftStart,S.ShftEnd  '
		select @strsql = @strsql + ' ) as T1 inner join #ShiftProductionFromAutodataT2 S on '
		select @strsql = @strsql + '  S.MachineID=T1.Mach and S.Component=T1.Compn and S.Operation=T1.Oprn  and '
		select @strsql = @strsql + ' S.Sdate=T1.ShDate and S.ShiftName=T1.Shft and S.ShftStart=T1.ShStrt and S.ShftEnd=T1.Shnd '
		print @strsql
		Exec(@strsql)
		Select @strsql=''
		*/


		Select @strsql=''
		select @strsql = 'insert into #ShiftProductionFromAutodataT2 (PlantID,MachineID,GroupID,Component,Operation,CycleTime,LoadUnload,AvgLoadUnload,AvgCycleTime,OperationCount, '
		select @strsql = @strsql + 'Sdate,ShiftName,ShftStart,ShftEnd, 	MachineInterface,CompInterface,	OpnInterface,MachineDescription) '
		select @strsql = @strsql + ' SELECT  distinct PlantMachine.PlantID,machineinformation.machineid,PlantMachineGroups.GroupID, componentinformation.componentid, '
		select @strsql = @strsql + ' componentoperationpricing.operationno, '
		select @strsql = @strsql + ' componentoperationpricing.machiningtime, '
		select @strsql = @strsql + ' (componentoperationpricing.cycletime - componentoperationpricing.machiningtime), '
		--select @strsql =@strsql+'AVG(case when (autodata.loadunload>=''' +convert(nvarchar(20),@MinLuLR)+ ''' )  then (autodata.loadunload/autodata.partscount) end ) * ISNULL(ComponentOperationPricing.SubOperations,1), ' --DR0325
		select @strsql =@strsql+'Sum(case when (autodata.loadunload>=''' +convert(nvarchar(20),@MinLuLR)+ ''' )  then (autodata.loadunload) end), ' --DR0325
		--mod 13
		--select @strsql = @strsql + ' AVG(autodata.cycletime/autodata.partscount)* ISNULL(ComponentOperationPricing.SubOperations,1) ,'
		select @strsql = @strsql + ' sum(autodata.cycletime) as Averagecycletime,'
		--mod 13
		
		--select @strsql = @strsql + ' CEILING(CAST(Sum(autodata.partscount)AS Float)/ISNULL(ComponentOperationPricing.SubOperations,1)) as PCount ,' --NR0097
		select @strsql = @strsql + ' (CAST(Sum(autodata.partscount)AS Float)/ISNULL(ComponentOperationPricing.SubOperations,1)) as PCount ,' --NR0097
		select @strsql =@strsql+' Pdate, Shift, ShiftStart, ShiftEnd '
		select @strsql = @strsql + ',machineinformation.interfaceid,componentinformation.interfaceid,componentoperationpricing.interfaceid,machineinformation.description'
		select @strsql = @strsql + ' FROM #T_autodata autodata INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID INNER JOIN  ' --ER0324 Added #T_autodata
		select @strsql = @strsql + ' componentinformation ON autodata.comp = componentinformation.InterfaceID  INNER JOIN '
		select @strsql = @strsql + ' componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID)'
		
		---mod 7
		select @strsql = @strsql +' and componentoperationpricing.machineid=machineinformation.machineid '
		---mod 7
		select @strsql = @strsql + ' AND (componentinformation.componentid = componentoperationpricing.componentid) '
		select @strsql = @strsql + ' Left Outer Join PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID
									LEFT JOIN PlantMachineGroups on machineinformation.machineid = PlantMachineGroups.machineid'
		select @strsql = @strsql + ' cross join  #ShiftProductionFromAutodataT0   '
		select @strsql = @strsql + ' where machineinformation.interfaceid > ''0'' '
		select @strsql = @strsql + 'and (( sttime >= shiftstart and ndtime <= shiftend ) OR '
		select @strsql = @strsql + '( sttime < shiftstart and ndtime > shiftstart and ndtime<=shiftend ))'
		select @strsql = @strsql + ' and autodata.datatype=1 '
		--mod 9
		select @strsql = @strsql + ' AND (autodata.partscount > 0 ) '
		--mod 9
		select @strsql = @strsql + @strmachine+@StrMPlantID+@strcomponentid+@stroperation+@StrGroupID
		select @strsql = @strsql + 'group by PlantMachine.PlantID,machineinformation.machineid,PlantMachineGroups.GroupID, componentinformation.componentid, '
		select @strsql = @strsql + ' componentoperationpricing.operationno, '
		select @strsql = @strsql + ' componentoperationpricing.machiningtime,ComponentOperationPricing.SubOperations,componentoperationpricing.cycletime,Pdate, Shift, ShiftStart, ShiftEnd  '
		select @strsql = @strsql + ',machineinformation.interfaceid,componentinformation.interfaceid,componentoperationpricing.interfaceid,machineinformation.description
		 order by  ShiftStart asc,machineinformation.machineid '
		print @strsql
		Exec(@strsql)


		Select @strsql=''
		
		---mod 12 : Neglect count overlapping with PDT
		If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
		BEGIN
				
			UPDATE #ShiftProductionFromAutodataT2 SET OperationCount=ISNULL(OperationCount,0)- isnull(t2.PlanCt,0)
				FROM ( select T.Shiftst as intime,Machineinformation.machineid as machine,
				--(CEILING (CAST(Sum(ISNULL(PartsCount,1)) AS Float)/ISNULL(Componentoperationpricing.SubOperations,1))) as PlanCt, --NR0097
				((CAST(Sum(ISNULL(PartsCount,1)) AS Float)/ISNULL(Componentoperationpricing.SubOperations,1))) as PlanCt, 
			 	Componentinformation.componentid as compid,componentoperationpricing.Operationno as opnno from #T_autodata autodata --ER0324 Added
				Inner jOIN #PlannedDownTimesShift T on T.MachineInterface=autodata.mc  inner join machineinformation on autodata.mc=machineinformation.Interfaceid
				Inner join componentinformation on autodata.comp=componentinformation.interfaceid inner join
				componentoperationpricing on autodata.opn=componentoperationpricing.interfaceid and
				componentinformation.componentid=componentoperationpricing.componentid  and componentoperationpricing.machineid=machineinformation.machineid
				WHERE autodata.DataType=1
				AND (autodata.ndtime > T.StartTime  AND autodata.ndtime <=T.EndTime)
				 Group by Machineinformation.machineid,componentinformation.componentid ,componentoperationpricing.Operationno,componentoperationpricing.SubOperations,T.Shiftst
			
			) as T2 inner join #ShiftProductionFromAutodataT2 S on T2.machine = S.machineid  and T2.compid=S.Component and   t2.opnno=S.Operation and  t2.intime=S.ShftStart
			
		END
		---mod 12 : Neglect count overlapping with PDT
		---test code start
		INSERT INTO #ShiftProductionFromAutodataT1 (
		 MachineID ,GroupID,OperatorID,OperatorName, MachineInterface,MachineDescription,ProductionEfficiency ,AvailabilityEfficiency ,
		OverallEfficiency ,UtilisedTime ,ManagementLoss,DownTime ,CN,Udate,Ushift,UstartShift,UEndShift)
		
		SELECT DISTINCT Machine ,GroupID,0,0,MachineInt,MachineDescription,0,0,0,0,0,0,0,Shdate,
							ShftName,ShftStrt,ShftND FROM #Machcomopnopr


		Update #ShiftProductionFromAutodataT1 Set shiftid = isnull(#ShiftProductionFromAutodataT1.shiftid,0) + isnull(T1.shiftid,0) from    
(Select SD.shiftid ,SD.shiftname from shiftdetails SD    
inner join #ShiftProductionFromAutodataT1 S on SD.shiftname=S.Ushift where    
running=1 )T1 inner join #ShiftProductionFromAutodataT1 on  T1.shiftname=#ShiftProductionFromAutodataT1.Ushift  

	---test code end
		
/*Declare RptShiftCursor CURSOR FOR
	SELECT 	#ShiftProductionFromAutodataT0.PDate,
		#ShiftProductionFromAutodataT0.Shift,
		#ShiftProductionFromAutodataT0.ShiftStart,
		#ShiftProductionFromAutodataT0.ShiftEnd
	from 	#ShiftProductionFromAutodataT0
	order by Pdate,shift*/
/*********************** ER0280 Commented From Here
Declare RptShiftCursor CURSOR FOR
	SELECT distinct Mdate,Mshift,MShiftStart,MshiftEnd from shift_proc where SSession=@@SPID order by MShiftStart
	OPEN RptShiftCursor
	FETCH NEXT FROM RptShiftCursor INTO @Dateval,@shiftnamevalue, @shiftstart, @shiftend
	 WHILE (@@fetch_status = 0)
	  BEGIN
ER0280 Commented Till Here **********************/		
		/**************************************************************************************************************/
		/*
				FOLLOWING SECTION IS ADDED BY SANGEETA KALLUR					*/
		/********************************   ER0280 Commented From Here
			SELECT @StrSql = 'INSERT INTO #Exceptions(MachineID ,ComponentID,OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,ExCount )
				SELECT Ex.MachineID ,Ex.ComponentID,Ex.OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,0
				From ProductionCountException Ex
				Inner Join MachineInformation M ON Ex.MachineID=M.MachineID
				Inner Join ComponentInformation C ON Ex.ComponentID=C.ComponentID
				Inner Join Componentoperationpricing O ON Ex.OperationNo=O.OperationNo AND C.ComponentID=O.ComponentID'
			---mod 7		
			SELECT @StrSql = @StrSql + ' and O.MachineId=Ex.MachineId '
			---mod 7
		SELECT @StrSql = @StrSql + ' WHERE  M.MultiSpindleFlag=1 '
		SELECT @StrSql =@StrSql + @strXMachine + @strXcomponentid + @strXoperation
		SELECT @StrSql =@StrSql +'AND ((Ex.StartTime>=  ''' + convert(nvarchar(20),@ShiftStart)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@ShiftEnd)+''' )
				OR (Ex.StartTime< ''' + convert(nvarchar(20),@ShiftStart)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@ShiftStart)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@ShiftEnd)+''')
				OR(Ex.StartTime>= ''' + convert(nvarchar(20),@ShiftStart)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@ShiftEnd)+''' AND Ex.StartTime< ''' + convert(nvarchar(20),@ShiftEnd)+''')
				OR(Ex.StartTime< ''' + convert(nvarchar(20),@ShiftStart)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@ShiftEnd)+''' ))'
		ER0280 Commented  Till Here ****************************************/
		
		---ER0280 From Here
		If ( Select Count(*) from Machineinformation where MultiSpindleFlag=1 and interfaceid in(select distinct Machineint from #Machcomopnopr))>0
		BEGIN
		SELECT @StrSql = 'INSERT INTO #Exceptions(MachineID ,ComponentID,OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,ExCount,Sdate,Shiftname )
				SELECT Ex.MachineID ,Ex.ComponentID,Ex.OperationNo,
				case when StartTime<MI.Shftstrt AND EndTime>MI.Shftstrt then MI.Shftstrt else StartTime end,
				case when EndTime> MI.ShftND  AND StartTime< MI.ShftND then  MI.ShftND else EndTime end
				,IdealCount ,ActualCount ,0 , MI.shdate,MI.Shftname
				From ProductionCountException Ex
				Inner Join MachineInformation M ON Ex.MachineID=M.MachineID
				Inner Join ComponentInformation C ON Ex.ComponentID=C.ComponentID
				Inner Join Componentoperationpricing O ON Ex.OperationNo=O.OperationNo AND C.ComponentID=O.ComponentID and O.MachineId=Ex.MachineId
				Inner join  #Machcomopnopr MI ON MI.Machine=Ex.MachineID and MI.Component=Ex.ComponentID and MI.Operation=Ex.OperationNo '
			---mod 7		
			--SELECT @StrSql = @StrSql + '  '
			---mod 7
		SELECT @StrSql = @StrSql + ' WHERE  M.MultiSpindleFlag=1 '
		SELECT @StrSql =@StrSql + @strXMachine + @strXcomponentid + @strXoperation
		SELECT @StrSql =@StrSql +'AND ((Ex.StartTime>=  MI.Shftstrt AND Ex.EndTime<= MI.ShftND )
				OR (Ex.StartTime< MI.Shftstrt AND Ex.EndTime> MI.Shftstrt AND Ex.EndTime<= MI.ShftND)
				OR(Ex.StartTime>=MI.Shftstrt AND Ex.EndTime> MI.ShftND  AND Ex.StartTime<MI.ShftND)
				OR(Ex.StartTime< MI.Shftstrt AND Ex.EndTime> MI.ShftND ))'
		Print(@strsql)
		Exec (@strsql)
		---ER0280 Till Here
		--Inner Join EmployeeInformation E  ON autodata.Opr=E.InterfaceID
		
		IF ( SELECT Count(*) from #Exceptions ) <> 0
		BEGIN
			---ER0280 From Here
			--UPDATE #Exceptions SET StartTime=@ShiftStart WHERE (StartTime<@ShiftStart)AND EndTime>@ShiftStart
			--UPDATE #Exceptions SET EndTime=@ShiftEnd WHERE (EndTime>@ShiftEnd AND StartTime<@ShiftEnd )
			---ER0280 Till Here
			Select @StrSql = 'UPDATE #Exceptions SET ExCount=ISNULL(T2.Comp,0) From
			(
				SELECT T1.MachineID AS MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime AS StartTime,T1.EndTime AS EndTime,
				--SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp --NR0097
				SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp --NR0097
	 			From (
					select MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,comp,opn,Tt1.StartTime,Tt1.EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from #T_autodata autodata --ER0324 Added
					Inner Join MachineInformation   ON autodata.MC=MachineInformation.InterfaceID
					Inner Join ComponentInformation  ON autodata.Comp = ComponentInformation.InterfaceID
					Inner Join ComponentOperationPricing on autodata.Opn=ComponentOperationPricing.InterfaceID And ComponentInformation.ComponentID=ComponentOperationPricing.ComponentID'
					---mod 7					
					Select @StrSql = @StrSql +' and ComponentOperationPricing.machineid=MachineInformation.machineid '
					--mod 7
					Select @StrSql = @StrSql +'Inner Join (
						Select MachineID,ComponentID,OperationNo,StartTime,EndTime From #Exceptions
					)AS Tt1 ON Tt1.MachineID=MachineInformation.MachineID AND Tt1.ComponentID = ComponentInformation.ComponentID AND Tt1.OperationNo= ComponentOperationPricing.OperationNo
					and Tt1.MachineID=ComponentOperationPricing.MachineID
					Where (autodata.ndtime>Tt1.StartTime) AND (autodata.ndtime<=Tt1.EndTime) and (autodata.datatype=1) '
			Select @StrSql = @StrSql+ @strmachine + @strcomponentid + @stroperation
			Select @StrSql = @StrSql+' Group by MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,Tt1.StartTime,Tt1.EndTime,comp,opn
				) as T1
	   			Inner join componentinformation C on T1.Comp=C.interfaceid
	   			Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineId=T1.MachineID '
			---mod 7
			Select @StrSql = @StrSql+' Inner join machineinformation M on T1.machineid = M.machineid  and M.Machineid=O.Machineid '
			---mod 7
	  		Select @StrSql = @StrSql+' GROUP BY T1.MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime,t1.EndTime
			)AS T2
			WHERE  #Exceptions.StartTime=T2.StartTime AND #Exceptions.EndTime=T2.EndTime
			AND #Exceptions.MachineID=T2.MachineID AND #Exceptions.ComponentID = T2.ComponentID AND #Exceptions.OperationNo=T2.OperationNo'
			
			Exec(@StrSql)
			
		---mod 6 Moved below END after the next query
		--END
		---mod 6
			---mod 12:Apply PDT for calculation of exception count
			If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
			BEGIN
				--can be improved
			
				Select @StrSql =''
				Select @StrSql ='UPDATE #Exceptions SET ExCount=ISNULL(ExCount,0) - ISNULL(T3.Comp,0)
				From
				(
					SELECT T2.MachineID AS MachineID,T2.ComponentID,T2.OperationNo,T2.StartTime AS StartTime,T2.EndTime AS EndTime,
					--SUM(CEILING (CAST(T2.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp --NR0097
					SUM((CAST(T2.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp --NR0097
					From
					(
						select MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,comp,opn,
						Max(T1.XStartTime)StartTime,Max(T1.XEndTime)EndTime,T1.PLD_StartTime,T1.PLD_EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from #T_autodata autodata --ER0324 Added
						Inner Join MachineInformation   ON autodata.MC=MachineInformation.InterfaceID
						Inner Join ComponentInformation  ON autodata.Comp = ComponentInformation.InterfaceID
						Inner Join ComponentOperationPricing on autodata.Opn=ComponentOperationPricing.InterfaceID And ComponentInformation.ComponentID=ComponentOperationPricing.ComponentID
						and ComponentOperationPricing.Machineid=MachineInformation.Machineid
						Inner Join	
						(
							SELECT MachineID,ComponentID,OperationNo,Ex.StartTime As XStartTime, Ex.EndTime AS XEndTime,
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
				
							From #Exceptions AS Ex Cross join  #PlannedDownTimesShift AS Td
							Where Td.Machine=Ex.Machineid  and  ((Td.StartTime>=Ex.StartTime And Td.EndTime <=Ex.EndTime)OR
							(Td.StartTime< Ex.StartTime And Td.EndTime<=Ex.EndTime AND Td.EndTime>Ex.StartTime)OR
							(Td.StartTime>= Ex.StartTime And Td.StartTime <Ex.EndTime AND Td.EndTime>Ex.EndTime)OR '
					--Select @StrSql = @StrSql + '(Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime)) and Td.Shiftst=''' +convert(nvarchar(20),@shiftstart,120)+ '''' 	---ER0280
					Select @StrSql = @StrSql + '(Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime)) and Td.Shiftst=''' +convert(nvarchar(20),@startdate,120)+ '''' ---ER0280
					Select @StrSql = @StrSql + ' )AS T1 ON T1.MachineID=MachineInformation.MachineID AND T1.ComponentID = ComponentInformation.ComponentID AND
								   T1.OperationNo= ComponentOperationPricing.OperationNo and T1.machineid=ComponentOperationPricing.Machineid
						Where (autodata.ndtime>T1.PLD_StartTime AND autodata.ndtime<=T1.PLD_EndTime) and (autodata.datatype=1)'
					--Select @StrSql = @StrSql + ' AND (autodata.ndtime > ''' + convert(nvarchar(20),@shiftstart,120)+''' AND autodata.ndtime<=''' + convert(nvarchar(20),@ShiftEnd,120)+''' )'	---ER0280
					Select @StrSql = @StrSql + ' AND (autodata.ndtime > ''' + convert(nvarchar(20),@startdate,120)+''' AND autodata.ndtime<=''' + convert(nvarchar(20),@Enddate,120)+''' )'  ---ER0280
					Select @StrSql = @StrSql+' Group by MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,T1.PLD_StartTime,T1.PLD_EndTime,comp,opn
					)AS T2
					Inner join componentinformation C on T2.Comp=C.interfaceid
					Inner join ComponentOperationPricing O ON T2.Opn=O.interfaceid and C.Componentid=O.componentid and O.MachineId=T2.MachineID
					GROUP BY T2.MachineID,T2.ComponentID,T2.OperationNo,T2.StartTime,t2.EndTime
				)As T3
				WHERE  #Exceptions.StartTime=T3.StartTime AND #Exceptions.EndTime=T3.EndTime
				AND #Exceptions.MachineID=T3.MachineID AND #Exceptions.ComponentID = T3.ComponentID AND #Exceptions.OperationNo=T3.OperationNo'
				PRINT @StrSql
				EXEC(@StrSql)
				UPDATE #Exceptions SET ExCount=ExCount-((ExCount * ActualCount)/ISNULL(IdealCount,0))
			END
			---mod 12:Apply PDT for calculation of exception count
	
			---update
			SELECT @StrSql=''	
	
			/*******************   ER0280 Commented From Here
			SELECT @StrSql='UPDATE #ShiftProductionFromAutodataT2 SET OperationCount=ISNULL(pCount,0)
			FROM
			(
			SELECT  Sdate  ,ShiftName ,#ShiftProductionFromAutodataT2.MachineID,Component,Operation ,(ISNULL(OperationCount,0)-ISNULL(ExCount,0))As pCount
			 FROM #ShiftProductionFromAutodataT2 INNER JOIN
				(
				SELECT MachineID,ComponentID,OperationNo,SUM(ExCount)AS ExCount
				FROM #Exceptions GROUP BY MachineID,ComponentID,OperationNo
				)AS Ti ON #ShiftProductionFromAutodataT2.MachineID=Ti.MachineID AND #ShiftProductionFromAutodataT2.Component=Ti.ComponentID AND #ShiftProductionFromAutodataT2.Operation=Ti.OperationNo
			WHERE Sdate=''' + Convert(nvarchar(20),@Dateval,120) + ''' AND ShiftName='''+@shiftNamevalue+'''
			)As T1 Inner Join #ShiftProductionFromAutodataT2 ON
				 #ShiftProductionFromAutodataT2.MachineID=T1.MachineID AND #ShiftProductionFromAutodataT2.Component=T1.Component AND #ShiftProductionFromAutodataT2.Operation=T1.Operation
				 AND #ShiftProductionFromAutodataT2.Sdate=T1.Sdate  AND #ShiftProductionFromAutodataT2.ShiftName=T1.ShiftName'
			EXEC (@StrSql)
			   ER0280 Commented Till Here  ********************/
			-- ER0280 From Here.
			SELECT @StrSql='UPDATE #ShiftProductionFromAutodataT2 SET OperationCount=ISNULL(pCount,0)
			FROM
			(
			SELECT  Sdate  ,ShiftName ,#ShiftProductionFromAutodataT2.MachineID,Component,Operation ,(ISNULL(OperationCount,0)-ISNULL(ExCount,0))As pCount
			 FROM #ShiftProductionFromAutodataT2 INNER JOIN
				(
				SELECT MachineID,ComponentID,OperationNo,SUM(ExCount)AS ExCount,Sdate,Shiftname
				FROM #Exceptions GROUP BY MachineID,ComponentID,OperationNo,Sdate,Shiftname
				)AS Ti ON #ShiftProductionFromAutodataT2.MachineID=Ti.MachineID AND #ShiftProductionFromAutodataT2.Component=Ti.ComponentID AND #ShiftProductionFromAutodataT2.Operation=Ti.OperationNo
				 AND #ShiftProductionFromAutodataT2.Sdate=Ti.Sdate  AND #ShiftProductionFromAutodataT2.ShiftName=Ti.ShiftName
			)As T1 Inner Join #ShiftProductionFromAutodataT2 ON
				 #ShiftProductionFromAutodataT2.MachineID=T1.MachineID AND #ShiftProductionFromAutodataT2.Component=T1.Component AND #ShiftProductionFromAutodataT2.Operation=T1.Operation
				 AND #ShiftProductionFromAutodataT2.Sdate=T1.Sdate  AND #ShiftProductionFromAutodataT2.ShiftName=T1.ShiftName'
			EXEC (@StrSql)
			--ER0280 Till Here.
		---mod 6
		END
		END --ER0280
		
		---mod 6
		
		--DELETE FROM #Exceptions  -----ER0280
/**************************************************************************************************************/
		/*****test code start*/
		----type 2
	
/*************************** ER0280 Commented From Here ***********************************************
		if (Select count(*) from #T_autodata autodata
			
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(sttime < @shiftstart)And (ndtime > @shiftstart) AND (ndtime <= @shiftend)
				and mc in (select distinct MachineInterface from #ShiftProductionFromAutodataT1)) >0
		BEGIN
		--mod 6
		UPDATE  #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
		FROM
		(Select AutoData.mc ,
		SUM(
		CASE
			When autodata.sttime <= S.UstartShift Then datediff(s, S.UstartShift,autodata.ndtime )
			When autodata.sttime > S.UstartShift Then datediff(s , autodata.sttime,autodata.ndtime)
		END) as Down,S.Udate as date1,S.UstartShift as ShiftStart
		from #T_autodata autodata INNER Join
			(Select mc,Sttime,NdTime from #T_autodata autodata
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(msttime < @shiftstart)And (ndtime > @shiftstart) AND (ndtime <= @shiftend)
				and mc in (select distinct MachineInterface from #ShiftProductionFromAutodataT1)
		) as T1
		ON AutoData.mc=T1.mc inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface
		Where AutoData.DataType=2
		And ( autodata.Sttime > T1.Sttime )
		And ( autodata.ndtime <  T1.ndtime )
		AND ( autodata.ndtime >  @shiftstart )
		and S.UstartShift=@shiftstart and S.UEndShift=@shiftend  and S.Udate=@Dateval
		GROUP BY AUTODATA.mc,S.Udate,S.UstartShift )AS T2 Inner Join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
		and t2.date1=#ShiftProductionFromAutodataT1.Udate and t2.ShiftStart=#ShiftProductionFromAutodataT1.UstartShift
		---mod 6
		END
		---mod 6
		
		---typ 4
		--mod 6
		if (Select count(*) from #T_autodata autodata
					Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
					(sttime < @shiftstart)And (ndtime > @shiftend)
					and mc in (select distinct MachineInterface from #ShiftProductionFromAutodataT1)) >0
		BEGIN
		--mod 6
			UPDATE  #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
			FROM
			(Select AutoData.mc ,
			SUM(CASE
--DR0236 - KarthikG - 19/Jun/2010
--				When autodata.sttime >= S.UstartShift AND autodata.ndtime <= S.UEndShift Then datediff(s , autodata.sttime,autodata.ndtime)
--				When autodata.sttime < S.UstartShift AND autodata.ndtime<=S.UEndShift Then datediff(s, S.UstartShift,autodata.ndtime )
--				When autodata.ndtime >= S.UEndShift AND autodata.sttime>S.UstartShift Then datediff(s,autodata.sttime, S.UEndShift )
--				When autodata.sttime<S.UstartShift AND autodata.ndtime>S.UEndShift   Then datediff(s , S.UstartShift,S.UEndShift)
				When autodata.sttime >= S.UstartShift AND autodata.ndtime <= S.UEndShift Then datediff(s , autodata.sttime,autodata.ndtime)
				When autodata.sttime < S.UstartShift And autodata.ndtime >S.UstartShift AND autodata.ndtime<=S.UEndShift Then datediff(s, S.UstartShift,autodata.ndtime )
				When autodata.sttime >= S.UstartShift AND autodata.sttime<S.UEndShift AND autodata.ndtime>S.UEndShift Then datediff(s,autodata.sttime, S.UEndShift )
				When autodata.sttime<S.UstartShift AND autodata.ndtime>S.UEndShift   Then datediff(s , S.UstartShift,S.UEndShift)
--DR0236 - KarthikG - 19/Jun/2010
			END) as Down,S.Udate as date1,S.UstartShift as ShiftStart
			from #T_autodata autodata INNER Join
				(Select mc,Sttime,NdTime from #T_autodata autodata
					Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
					(msttime < @shiftstart)And (ndtime > @shiftend)
					and mc in (select distinct MachineInterface from #ShiftProductionFromAutodataT1)
			 ) as T1
			ON AutoData.mc=T1.mc inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface
			Where AutoData.DataType=2
			And (T1.Sttime < autodata.sttime  )
			And ( T1.ndtime >  autodata.ndtime)
			AND (autodata.ndtime  >  S.UstartShift)
			AND (autodata.sttime  <  S.UEndShift)
			and S.UstartShift=@shiftstart and S.UEndShift=@shiftend  and S.Udate=@Dateval
			GROUP BY AUTODATA.mc,S.Udate,S.UstartShift
			 )AS T2 Inner Join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
			and t2.date1=#ShiftProductionFromAutodataT1.Udate and t2.ShiftStart=#ShiftProductionFromAutodataT1.UstartShift
	
			---mod 6
		END
		---mod 6
		---type 3
		--mod 6
		if (Select count(*) from #T_autodata autodata
					Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
					(sttime >= @shiftstart)And (ndtime >@shiftend) and (sttime< @shiftend)
				and mc in (select distinct MachineInterface from #ShiftProductionFromAutodataT1)) >0
		BEGIN
		
		--mod 6
			UPDATE  #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
			FROM
			(Select AutoData.mc ,
			SUM(CASE
				When autodata.ndtime > S.UEndShift Then datediff(s,autodata.sttime, S.UEndShift )
				When autodata.ndtime <=S.UEndShift Then datediff(s , autodata.sttime,autodata.ndtime)
			END) as Down,S.Udate as date1,S.UstartShift as ShiftStart
			from #T_autodata autodata INNER Join
				(Select mc,Sttime,NdTime from #T_autodata autodata
					Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
					(sttime >= @shiftstart)And (ndtime >@shiftend) and (sttime< @shiftend)
				and mc in (select distinct MachineInterface from #ShiftProductionFromAutodataT1)
			 ) as T1
			ON AutoData.mc=T1.mc inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface
			Where AutoData.DataType=2
			And (T1.Sttime < autodata.sttime  )
			And ( T1.ndtime >  autodata.ndtime)
			AND (autodata.sttime  <  S.UEndShift)
			and S.UstartShift=@shiftstart and S.UEndShift=@shiftend  and S.Udate=@Dateval
			GROUP BY AUTODATA.mc,S.Udate,S.UstartShift )AS T2 Inner Join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
			and t2.date1=#ShiftProductionFromAutodataT1.Udate and t2.ShiftStart=#ShiftProductionFromAutodataT1.UstartShift
			END	
		******************************* ER0280 Commented From Here ********************************/
		
		/***********************ER0280 From Here ***************************************/
		/**************** ER0324 Commented From Here **************************************
		-------For Type2
		UPDATE  #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
		FROM
		(Select AutoData.mc ,
		SUM(
		CASE
			When autodata.sttime <= S.UstartShift Then datediff(s, S.UstartShift,autodata.ndtime )
			When autodata.sttime > S.UstartShift Then datediff(s , autodata.sttime,autodata.ndtime)
		END) as Down,S.Udate as date1,S.UstartShift as ShiftStart
		from #T_autodata autodata INNER Join  --ER0324 Added
			(Select mc,Sttime,NdTime from #T_autodata autodata --ER0324 Added
				inner join #ShiftProductionFromAutodataT1 ST1 ON ST1.MachineInterface=Autodata.mc
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(msttime < UstartShift)And (ndtime > UstartShift) AND (ndtime <= UEndShift)
				
		) as T1
		ON AutoData.mc=T1.mc inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface
		Where AutoData.DataType=2
		And ( autodata.Sttime > T1.Sttime )
		And ( autodata.ndtime <  T1.ndtime )
		AND ( autodata.ndtime >  UstartShift )
		--and S.UstartShift=@shiftstart and S.UEndShift=@shiftend  and S.Udate=@Dateval
		GROUP BY AUTODATA.mc,S.Udate,S.UstartShift )AS T2 Inner Join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
		and t2.date1=#ShiftProductionFromAutodataT1.Udate and t2.ShiftStart=#ShiftProductionFromAutodataT1.UstartShift
		---mod 6
		
		--For Type4
		UPDATE  #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
		FROM
		(Select AutoData.mc ,
		SUM(CASE
--DR0236 - KarthikG - 19/Jun/2010
--				When autodata.sttime >= S.UstartShift AND autodata.ndtime <= S.UEndShift Then datediff(s , autodata.sttime,autodata.ndtime)
--				When autodata.sttime < S.UstartShift AND autodata.ndtime<=S.UEndShift Then datediff(s, S.UstartShift,autodata.ndtime )
--				When autodata.ndtime >= S.UEndShift AND autodata.sttime>S.UstartShift Then datediff(s,autodata.sttime, S.UEndShift )
--				When autodata.sttime<S.UstartShift AND autodata.ndtime>S.UEndShift   Then datediff(s , S.UstartShift,S.UEndShift)
			When autodata.sttime >= S.UstartShift AND autodata.ndtime <= S.UEndShift Then datediff(s , autodata.sttime,autodata.ndtime)
			When autodata.sttime < S.UstartShift And autodata.ndtime >S.UstartShift AND autodata.ndtime<=S.UEndShift Then datediff(s, S.UstartShift,autodata.ndtime )
			When autodata.sttime >= S.UstartShift AND autodata.sttime<S.UEndShift AND autodata.ndtime>S.UEndShift Then datediff(s,autodata.sttime, S.UEndShift )
			When autodata.sttime<S.UstartShift AND autodata.ndtime>S.UEndShift   Then datediff(s , S.UstartShift,S.UEndShift)
--DR0236 - KarthikG - 19/Jun/2010
		END) as Down,S.Udate as date1,S.UstartShift as ShiftStart
		from #T_autodata autodata INNER Join --ER0324 Added
			(Select mc,Sttime,NdTime from #T_autodata autodata  --ER0324 Added
				inner join #ShiftProductionFromAutodataT1 ST1 ON ST1.MachineInterface =Autodata.mc
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(msttime < UstartShift)And (ndtime >UEndShift)
				--and mc in (select distinct MachineInterface from #ShiftProductionFromAutodataT1)
		 ) as T1
		ON AutoData.mc=T1.mc inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface
		Where AutoData.DataType=2
		And (T1.Sttime < autodata.sttime  )
		And ( T1.ndtime >  autodata.ndtime)
		AND (autodata.ndtime  >  S.UstartShift)
		AND (autodata.sttime  <  S.UEndShift)
		--and S.UstartShift=@shiftstart and S.UEndShift=@shiftend  and S.Udate=@Dateval
		GROUP BY AUTODATA.mc,S.Udate,S.UstartShift
		 )AS T2 Inner Join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
		and t2.date1=#ShiftProductionFromAutodataT1.Udate and t2.ShiftStart=#ShiftProductionFromAutodataT1.UstartShift
			---mod 6
		
		
		--mod 6
		--Type 3
		UPDATE  #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
		FROM
		(Select AutoData.mc ,
		SUM(CASE
			When autodata.ndtime > S.UEndShift Then datediff(s,autodata.sttime, S.UEndShift )
			When autodata.ndtime <=S.UEndShift Then datediff(s , autodata.sttime,autodata.ndtime)
		END) as Down,S.Udate as date1,S.UstartShift as ShiftStart
		from #T_autodata autodata INNER Join --ER0324 Added
			(Select mc,Sttime,NdTime from #T_autodata autodata --ER0324 Added
				inner join #ShiftProductionFromAutodataT1 ST1 ON ST1.MachineInterface =Autodata.mc
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(sttime >= UstartShift)And (ndtime >UEndShift) and (sttime< UEndShift)
			--and mc in (select distinct MachineInterface from #ShiftProductionFromAutodataT1)
		 ) as T1
		ON AutoData.mc=T1.mc inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface
		Where AutoData.DataType=2
		And (T1.Sttime < autodata.sttime  )
		And ( T1.ndtime >  autodata.ndtime)
		AND (autodata.sttime  <  S.UEndShift)
		--and S.UstartShift=@shiftstart and S.UEndShift=@shiftend  and S.Udate=@Dateval
		GROUP BY AUTODATA.mc,S.Udate,S.UstartShift )AS T2 Inner Join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
		and t2.date1=#ShiftProductionFromAutodataT1.Udate and t2.ShiftStart=#ShiftProductionFromAutodataT1.UstartShift
		********************************** ER0324 Commented Till Here *****************************************/

		-----------------------------------ER0324 added From Here------------------------------------------------
		 Print  '----UPDATE  #ShiftProductionFromAutodataT1 SET UtilisedTime------'
         print getdate() 
		-------For Type2
		UPDATE  #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
		FROM
		(Select AutoData.mc ,
		SUM(
		CASE
			When autodata.sttime <= T1.UstartShift Then datediff(s, T1.UstartShift,autodata.ndtime )
			When autodata.sttime > T1.UstartShift Then datediff(s , autodata.sttime,autodata.ndtime)
		END) as Down,t1.UstartShift as ShiftStart,T1.UDate as udate
		From #T_autodata  AutoData INNER Join
			(Select mc,Sttime,NdTime,UstartShift,UEndShift,udate From #T_autodata AutoData
				inner join #ShiftProductionFromAutodataT1 ST1 ON ST1.MachineInterface=Autodata.mc
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(msttime < UstartShift)And (ndtime > UstartShift) AND (ndtime <= UEndShift)
		) as T1 on t1.mc=autodata.mc
		Where AutoData.DataType=2
		And ( autodata.Sttime > T1.Sttime )
		And ( autodata.ndtime <  T1.ndtime )
		AND ( autodata.ndtime >  T1.UstartShift )
		GROUP BY AUTODATA.mc,T1.UstartShift,T1.UDate)AS T2 Inner Join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
		and T2.UDate = #ShiftProductionFromAutodataT1.UDate and t2.ShiftStart=#ShiftProductionFromAutodataT1.UstartShift
		--For Type4
		UPDATE  #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
		FROM
		(Select AutoData.mc ,
		SUM(CASE
			When autodata.sttime >= T1.UstartShift AND autodata.ndtime <= T1.UEndShift Then datediff(s , autodata.sttime,autodata.ndtime)
			When autodata.sttime < T1.UstartShift And autodata.ndtime >T1.UstartShift AND autodata.ndtime<=T1.UEndShift Then datediff(s, T1.UstartShift,autodata.ndtime )
			When autodata.sttime >= T1.UstartShift AND autodata.sttime<T1.UEndShift AND autodata.ndtime>T1.UEndShift Then datediff(s,autodata.sttime, T1.UEndShift )
			When autodata.sttime<T1.UstartShift AND autodata.ndtime>T1.UEndShift   Then datediff(s , T1.UstartShift,T1.UEndShift)
		END) as Down,T1.UstartShift as ShiftStart,T1.UDate as udate
		From #T_autodata AutoData INNER Join
			(Select mc,Sttime,NdTime,UstartShift,UEndShift,UDate From #T_autodata AutoData
				inner join #ShiftProductionFromAutodataT1 ST1 ON ST1.MachineInterface =Autodata.mc
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(msttime < UstartShift)And (ndtime >UEndShift)
			
		 ) as T1
		ON AutoData.mc=T1.mc
		Where AutoData.DataType=2
		And (T1.Sttime < autodata.sttime  )
		And ( T1.ndtime >  autodata.ndtime)
		AND (autodata.ndtime  >  T1.UstartShift)
		AND (autodata.sttime  <  T1.UEndShift)
		GROUP BY AUTODATA.mc,T1.UstartShift,T1.UDate
		 )AS T2 Inner Join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
		and T2.UDate = #ShiftProductionFromAutodataT1.UDate and t2.ShiftStart=#ShiftProductionFromAutodataT1.UstartShift
		--Type 3
		UPDATE  #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
		FROM
		(Select AutoData.mc ,
		SUM(CASE
			When autodata.ndtime > T1.UEndShift Then datediff(s,autodata.sttime, T1.UEndShift )
			When autodata.ndtime <=T1.UEndShift Then datediff(s , autodata.sttime,autodata.ndtime)
		END) as Down,T1.UstartShift as ShiftStart,T1.Udate as Udate
		From #T_autodata AutoData INNER Join
			(Select mc,Sttime,NdTime,ustartshift,uendshift,udate From #T_autodata AutoData
				inner join #ShiftProductionFromAutodataT1 ST1 ON ST1.MachineInterface =Autodata.mc
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(sttime >= UstartShift)And (ndtime >UEndShift) and (sttime< UEndShift)
		 ) as T1
		ON AutoData.mc=T1.mc
		Where AutoData.DataType=2
		And (T1.Sttime < autodata.sttime  )
		And ( T1.ndtime >  autodata.ndtime)
		AND (autodata.sttime  <  T1.UEndShift)
		GROUP BY AUTODATA.mc,T1.UstartShift,T1.Udate )AS T2 Inner Join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
		and t2.udate=#ShiftProductionFromAutodataT1.udate and t2.ShiftStart=#ShiftProductionFromAutodataT1.UstartShift
		---------------------------------------ER0324 Added Till Here ------------------------------------------------
		 Print  '----UPDATE  #ShiftProductionFromAutodataT1 SET CN------'
         print getdate() 
		--select 'In cursor'
		--BEGIN: CN
		--Type 1
		UPDATE #ShiftProductionFromAutodataT1 SET CN = isnull(CN,0) + isNull(t2.C1N1,0)
		from
		(select mc,
		--SUM(componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1)) C1N1
		  SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))*autodata.partscount) C1N1,S.Udate as date1,S.UstartShift as ShiftStart
		   from #T_autodata autodata INNER JOIN --ER0324 Added
		componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
		componentinformation ON autodata.comp = componentinformation.InterfaceID AND
		componentoperationpricing.componentid = componentinformation.componentid
		---mod 7
		inner join machineinformation on machineinformation.interfaceid=autodata.mc
		and componentoperationpricing.machineid=machineinformation.machineid
		---mod 7
		inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface
		  where (autodata.sttime>=S.UstartShift)
			and (autodata.ndtime<=S.UEndShift)
			and (autodata.datatype=1)
		--and S.UstartShift=@shiftstart and S.UEndShift=@shiftend  and S.Udate=@Dateval  -------- ER0280
		  group by autodata.mc,S.Udate,S.UstartShift
		) as t2 inner join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
		and t2.date1=#ShiftProductionFromAutodataT1.Udate and t2.ShiftStart=#ShiftProductionFromAutodataT1.UstartShift
		
		--Type 2
		UPDATE #ShiftProductionFromAutodataT1 SET CN = isnull(CN,0) + isNull(t2.C1N1,0)
		from
		(select mc,
		  SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))*autodata.partscount) C1N1,S.Udate as date1,S.UstartShift as ShiftStart
		   from #T_autodata autodata INNER JOIN --ER0324 Added
		componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
		componentinformation ON autodata.comp = componentinformation.InterfaceID AND
		componentoperationpricing.componentid = componentinformation.componentid
		---mod 7
		inner join machineinformation on machineinformation.interfaceid=autodata.mc
		and componentoperationpricing.machineid=machineinformation.machineid
		---mod 7
		inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface
		where (autodata.sttime<S.UstartShift)
		  and (autodata.ndtime>S.UstartShift)
		  and (autodata.ndtime<=S.UEndShift)
		  and (autodata.datatype=1)
		--and S.UstartShift=@shiftstart and S.UEndShift=@shiftend  and S.Udate=@Dateval   -------- ER0280
		  group by autodata.mc,S.Udate,S.UstartShift
		) as t2 inner join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
		and t2.date1=#ShiftProductionFromAutodataT1.Udate and t2.ShiftStart=#ShiftProductionFromAutodataT1.UstartShift
	
		--FETCH NEXT FROM RptShiftCursor INTO @Dateval,@shiftnamevalue, @shiftstart, @shiftend
--END
--CLOSE RptShiftCursor
--DEALLOCATE RptShiftCursor
/*************************************************** ER0280 Till Here **************************************************/
Select @strsql=''
		--test  comment begin
		/*INSERT INTO #ShiftProductionFromAutodataT1 (
		 MachineID ,OperatorID,MachineInterface,ProductionEfficiency ,AvailabilityEfficiency ,
		OverallEfficiency ,UtilisedTime ,ManagementLoss,DownTime ,CN,Udate,Ushift,UstartShift,UEndShift)
		
		SELECT DISTINCT Machine ,0,MachineInt,0,0,0,0,0,0,0,Shdate,
							ShftName,ShftStrt,ShftND FROM #Machcomopnopr*/--test comment end
/* Select @strsql=''
		Select @strsql= 'INSERT INTO #ShiftProductionFromAutodataT1 ('
		Select @strsql=@strsql+' MachineID ,OperatorID,MachineInterface,ProductionEfficiency ,AvailabilityEfficiency ,'
	    Select @strsql=@strsql+' OverallEfficiency ,UtilisedTime ,ManagementLoss,DownTime ,CN,Udate,Ushift,UstartShift,UEndShift) '
		
select @strsql = @strsql + 'SELECT distinct  Machineinformation.Machineid, 0, Machineinformation.interfaceid, 0,0,0,0,0,0,0, Pdate, Shift, ShiftStart, ShiftEnd '
		select @strsql = @strsql + '  from #T_autodata autodata inner join machineinformation on machineinformation.interfaceid=autodata.mc '
		select @strsql = @strsql + ' Left Outer Join PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID '
		select @strsql = @strsql + ' cross join #ShiftProductionFromAutodataT0 where '
		select @strsql = @strsql + '(( sttime >= shiftstart and ndtime <= shiftend ) OR '
		select @strsql = @strsql + '( sttime < shiftstart and ndtime > shiftend )OR '
		select @strsql = @strsql + '( sttime < shiftstart and ndtime > shiftstart and ndtime<=shiftend )'
		select @strsql = @strsql + ' OR ( sttime >= shiftstart and ndtime > shiftend and sttime<shiftend ) ) and machineinformation.interfaceid>0 '
		select @strsql = @strsql + @strmachine+@StrMPlantID
		print @strsql
		Exec(@strsql)
		Select @strsql='' */

declare @CurMachineID as Nvarchar(50)
declare @CurOperatorID as Nvarchar(500)
declare @CurOperatorName as Nvarchar(500)
DECLARE @AllOprAtMachineLevel AS NVARCHAR(500)
DECLARE @AllOprAtMachineLevel1 AS NVARCHAR(500)

/*Declare TmpCursorsec Cursor For SELECT MachineID,Udate,UstartShift,UEndShift FROM #ShiftProductionFromAutodataT1*/
Declare TmpCursorsecid Cursor For SELECT  Machine,Mdate,MShiftStart,MshiftEnd from shift_proc where SSession=@@SPID  order by MShiftStart
OPEN  TmpCursorsecid
FETCH NEXT FROM TmpCursorsecid INTO @CurMachineID,@CurDate,@CurStrtTime,@CurEndTime
WHILE @@FETCH_STATUS=0
BEGIN
	DELETE  FROM #TmpOperator
	SELECT @AllOprAtMachineLevel=''
	SELECT @AllOprAtMachineLevel1=''
	INSERT INTO #TmpOperator(MachineID ,OperatorID,OperatorName)
	SELECT Distinct Machine,Operator,OperatorName FROM
	#Machcomopnopr
	WHERE #Machcomopnopr.Machine = @CurMachineID  AND Shdate=@CurDate AND
							ShftStrt=@CurStrtTime AND ShftND=@CurEndTime
	
		DECLARE InnerCusor CURSOR For SELECT OperatorID,OperatorName FROM #TmpOperator
			OPEN  InnerCusor
			FETCH NEXT FROM InnerCusor INTO @CurOperatorID,@CurOperatorName
			WHILE @@FETCH_STATUS=0
			BEGIN
				SELECT @AllOprAtMachineLevel=@AllOprAtMachineLevel + ' ; ' + @CurOperatorID
				SELECT @AllOprAtMachineLevel1=@AllOprAtMachineLevel1 + ' ; ' + @CurOperatorName
				FETCH NEXT FROM InnerCusor INTO @CurOperatorID,@CurOperatorName

			END
			UPDATE #ShiftProductionFromAutodataT1 SET OperatorID=SUBSTRING ( @AllOprAtMachineLevel , 3 , len(@AllOprAtMachineLevel) )
			WHERE MachineID =@CurMachineID and Udate=@CurDate and UstartShift=@CurStrtTime

			UPDATE #ShiftProductionFromAutodataT1 SET OperatorName=SUBSTRING ( @AllOprAtMachineLevel1 , 3 , len(@AllOprAtMachineLevel1) )
			WHERE MachineID =@CurMachineID and Udate=@CurDate and UstartShift=@CurStrtTime

		
			CLOSE InnerCusor
			DEALLOCATE InnerCusor
	
FETCH NEXT FROM TmpCursorsecid INTO @CurMachineID,@CurDate,@CurStrtTime,@CurEndTime
END
close TmpCursorsecid
deallocate TmpCursorsecid


--Declare TmpCursorsecname Cursor For SELECT  Machine,Mdate,MShiftStart,MshiftEnd from shift_proc where SSession=@@SPID  order by MShiftStart
--OPEN  TmpCursorsecname
--FETCH NEXT FROM TmpCursorsecname INTO @CurMachineID,@CurDate,@CurStrtTime,@CurEndTime
--WHILE @@FETCH_STATUS=0
--BEGIN
--	DELETE  FROM #TmpOperator
--	SELECT @AllOprAtMachineLevel=''
	
--	INSERT INTO #TmpOperator(MachineID ,OperatorName)
--	SELECT Distinct Machine,OperatorName FROM
--	#Machcomopnopr
--	WHERE #Machcomopnopr.Machine = @CurMachineID  AND Shdate=@CurDate AND
--							ShftStrt=@CurStrtTime AND ShftND=@CurEndTime
	
--		DECLARE InnerCusor CURSOR For SELECT OperatorName FROM #TmpOperator
--			OPEN  InnerCusor
--			FETCH NEXT FROM InnerCusor INTO @CurOperatorName
--			WHILE @@FETCH_STATUS=0
--			BEGIN
--				SELECT @AllOprAtMachineLevel=@AllOprAtMachineLevel + ' ; ' + @CurOperatorName
--				FETCH NEXT FROM InnerCusor INTO @CurOperatorName
--			END
--			UPDATE #ShiftProductionFromAutodataT1 SET OperatorName=SUBSTRING ( @AllOprAtMachineLevel , 3 , len(@AllOprAtMachineLevel) )
--			WHERE MachineID =@CurMachineID and Udate=@CurDate and UstartShift=@CurStrtTime
		
--			CLOSE InnerCusor
--			DEALLOCATE InnerCusor
	
--FETCH NEXT FROM TmpCursorsecname INTO @CurMachineID,@CurDate,@CurStrtTime,@CurEndTime
--END
--close TmpCursorsecname
--deallocate TmpCursorsecname




-- Get the utilised time
--mod 4
-- Type 1,2,3,4





UPDATE #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
from
(select      mc,
	sum(case when ( (autodata.msttime>=S.UstartShift) and (autodata.ndtime<=S.UEndShift)) then  (cycletime+loadunload)
		 when ((autodata.msttime<S.UstartShift)and (autodata.ndtime>S.UstartShift)and (autodata.ndtime<=S.UEndShift)) then DateDiff(second, S.UstartShift, ndtime)
		 when ((autodata.msttime>=S.UstartShift)and (autodata.msttime<S.UEndShift)and (autodata.ndtime>S.UEndShift)) then DateDiff(second, mstTime, S.UEndShift)
		 when ((autodata.msttime<S.UstartShift)and (autodata.ndtime>S.UEndShift)) then DateDiff(second, S.UstartShift, S.UEndShift) END ) as cycle,S.UstartShift as ShiftStart
from #T_autodata autodata inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface --ER0324 Added
where (autodata.datatype=1) AND(( (autodata.msttime>=S.UstartShift) and (autodata.ndtime<=S.UEndShift))
OR ((autodata.msttime<S.UstartShift)and (autodata.ndtime>S.UstartShift)and (autodata.ndtime<=S.UEndShift))
OR ((autodata.msttime>=S.UstartShift)and (autodata.msttime<S.UEndShift)and (autodata.ndtime>S.UEndShift))
OR((autodata.msttime<S.UstartShift)and (autodata.ndtime>S.UEndShift)))
group by autodata.mc,S.UstartShift
) as t2 inner join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
and t2.ShiftStart=#ShiftProductionFromAutodataT1.UstartShift



--mod 4
--mod 4
----Calculating ICD's and CN
--Declare TmpCursorICD Cursor For SELECT Pdate,ShiftStart, ShiftEnd FROM #ShiftProductionFromAutodataT0
/*test comment StartDeclare TmpCursorICD Cursor For SELECT distinct Mdate,MShiftStart,MshiftEnd  from shift_proc  where SSession=@@SPID  order by MShiftStart
OPEN  TmpCursorICD
--FETCH NEXT FROM TmpCursorICD INTO @CurMachineID,@CurDate,@CurStrtTime,@CurEndTime
FETCH NEXT FROM TmpCursorICD INTO @CurDate,@CurStrtTime,@CurEndTime
WHILE @@FETCH_STATUS=0
BEGIN		
		
		----type 2
		--mod 6
		if (Select count(*) from #T_autodata autodata inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(sttime < S.UstartShift)And (ndtime > S.UstartShift) AND (ndtime <= S.UEndShift)) >0
		BEGIN
		--mod 6
		 UPDATE  #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
		FROM
		(Select AutoData.mc ,
		SUM(
		CASE
			When autodata.sttime <= S.UstartShift Then datediff(s, S.UstartShift,autodata.ndtime )
			When autodata.sttime > S.UstartShift Then datediff(s , autodata.sttime,autodata.ndtime)
		END) as Down,S.Udate as date1,S.UstartShift as ShiftStart
		from #T_autodata autodata INNER Join
			(Select mc,Sttime,NdTime from #T_autodata autodata inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(sttime < S.UstartShift)And (ndtime > S.UstartShift) AND (ndtime <= S.UEndShift)
		---mod 11
		 and S.UstartShift=@CurStrtTime and S.UEndShift=@CurEndTime
		---mod 11
		) as T1
		ON AutoData.mc=T1.mc inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface
		Where AutoData.DataType=2
		And ( autodata.Sttime > T1.Sttime )
		And ( autodata.ndtime <  T1.ndtime )
		AND ( autodata.ndtime >  @CurStrtTime )
		and S.UstartShift=@CurStrtTime and S.UEndShift=@CurEndTime  and S.Udate=@CurDate
		GROUP BY AUTODATA.mc,S.Udate,S.UstartShift )AS T2 Inner Join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
		and t2.date1=#ShiftProductionFromAutodataT1.Udate and t2.ShiftStart=#ShiftProductionFromAutodataT1.UstartShift
		---mod 6
		END
		---mod 6
		
		---typ 4
		--mod 6
		if (Select count(*) from #T_autodata autodata inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(sttime < S.UstartShift)And (ndtime > S.UEndShift)) >0
		BEGIN
		--mod 6
UPDATE  #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
			FROM
			(Select AutoData.mc ,
			SUM(CASE
				When autodata.sttime < S.UstartShift AND autodata.ndtime<=S.UEndShift Then datediff(s, S.UstartShift,autodata.ndtime )
				When autodata.ndtime >= S.UEndShift AND autodata.sttime>S.UstartShift Then datediff(s,autodata.sttime, S.UEndShift )
				When autodata.sttime >= S.UstartShift AND
					 autodata.ndtime <= S.UEndShift Then datediff(s , autodata.sttime,autodata.ndtime)
				When autodata.sttime<S.UstartShift AND autodata.ndtime>S.UEndShift   Then datediff(s , S.UstartShift,S.UEndShift)
			END) as Down,S.Udate as date1,S.UstartShift as ShiftStart
			from #T_autodata autodata INNER Join
				(Select mc,Sttime,NdTime from #T_autodata autodata inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface
					Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
					(sttime < S.UstartShift)And (ndtime > S.UEndShift)
			---mod 11
			 and S.UstartShift=@CurStrtTime and S.UEndShift=@CurEndTime
			---mod 11
			 ) as T1
			ON AutoData.mc=T1.mc inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface
			Where AutoData.DataType=2
			And (T1.Sttime < autodata.sttime  )
			And ( T1.ndtime >  autodata.ndtime)
			AND (autodata.ndtime  >  S.UstartShift)
			AND (autodata.sttime  <  S.UEndShift)
			and S.UstartShift=@CurStrtTime and S.UEndShift=@CurEndTime  and S.Udate=@CurDate
			GROUP BY AUTODATA.mc,S.Udate,S.UstartShift
			 )AS T2 Inner Join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
			and t2.date1=#ShiftProductionFromAutodataT1.Udate and t2.ShiftStart=#ShiftProductionFromAutodataT1.UstartShift
			---mod 6
		END
		---mod 6
		---type 3
		--mod 6
		if (Select count(*) from #T_autodata autodata inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(sttime >= S.UstartShift)And (ndtime > S.UEndShift)) >0
		BEGIN
		
		--mod 6
			UPDATE  #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
			FROM
			(Select AutoData.mc ,
			SUM(CASE
				When autodata.ndtime > S.UEndShift Then datediff(s,autodata.sttime, S.UEndShift )
				When autodata.ndtime <=S.UEndShift Then datediff(s , autodata.sttime,autodata.ndtime)
			END) as Down,S.Udate as date1,S.UstartShift as ShiftStart
			from #T_autodata autodata INNER Join
				(Select mc,Sttime,NdTime from #T_autodata autodata inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface
					Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
					(sttime >= S.UstartShift)And (ndtime > S.UEndShift) and (sttime< S.UEndShift)
			---mod 11
			 and S.UstartShift=@CurStrtTime and S.UEndShift=@CurEndTime
			---mod 11
			 ) as T1
			ON AutoData.mc=T1.mc inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface
			Where AutoData.DataType=2
			And (T1.Sttime < autodata.sttime  )
			And ( T1.ndtime >  autodata.ndtime)
			AND (autodata.sttime  <  S.UEndShift)
			and S.UstartShift=@CurStrtTime and S.UEndShift=@CurEndTime  and S.Udate=@CurDate
			GROUP BY AUTODATA.mc,S.Udate,S.UstartShift )AS T2 Inner Join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
			and t2.date1=#ShiftProductionFromAutodataT1.Udate and t2.ShiftStart=#ShiftProductionFromAutodataT1.UstartShift
			---mod 6
		END
		---mod 6
		--select 'In cursor'
		--BEGIN: CN
		--Type 1
		UPDATE #ShiftProductionFromAutodataT1 SET CN = isnull(CN,0) + isNull(t2.C1N1,0)
		from
		(select mc,
		--SUM(componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1)) C1N1
		  SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))*autodata.partscount) C1N1,S.Udate as date1,S.UstartShift as ShiftStart
		   from #T_autodata autodata INNER JOIN
		componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
		componentinformation ON autodata.comp = componentinformation.InterfaceID AND
		componentoperationpricing.componentid = componentinformation.componentid
		---mod 7
		inner join machineinformation on machineinformation.interfaceid=autodata.mc
		and componentoperationpricing.machineid=machineinformation.machineid
		---mod 7
		inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface
		  where (autodata.sttime>=S.UstartShift)
			and (autodata.ndtime<=S.UEndShift)
			and (autodata.datatype=1)
		and S.UstartShift=@CurStrtTime and S.UEndShift=@CurEndTime  and S.Udate=@CurDate
		  group by autodata.mc,S.Udate,S.UstartShift
		) as t2 inner join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
		and t2.date1=#ShiftProductionFromAutodataT1.Udate and t2.ShiftStart=#ShiftProductionFromAutodataT1.UstartShift
		--Type 2
	
		UPDATE #ShiftProductionFromAutodataT1 SET CN = isnull(CN,0) + isNull(t2.C1N1,0)
		from
		(select mc,
		  SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))*autodata.partscount) C1N1,S.Udate as date1,S.UstartShift as ShiftStart
		   from #T_autodata autodata INNER JOIN
		componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
		componentinformation ON autodata.comp = componentinformation.InterfaceID AND
		componentoperationpricing.componentid = componentinformation.componentid
		---mod 7
		inner join machineinformation on machineinformation.interfaceid=autodata.mc
		and componentoperationpricing.machineid=machineinformation.machineid
		---mod 7
		inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface
		where (autodata.sttime<S.UstartShift)
		  and (autodata.ndtime>S.UstartShift)
		  and (autodata.ndtime<=S.UEndShift)
		  and (autodata.datatype=1)
		and S.UstartShift=@CurStrtTime and S.UEndShift=@CurEndTime  and S.Udate=@CurDate
		  group by autodata.mc,S.Udate,S.UstartShift
		) as t2 inner join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
		and t2.date1=#ShiftProductionFromAutodataT1.Udate and t2.ShiftStart=#ShiftProductionFromAutodataT1.UstartShift
	FETCH NEXT FROM TmpCursorICD INTO @CurDate,@CurStrtTime,@CurEndTime
END
close TmpCursorICD
deallocate TmpCursorICD  test comment end*/
--mod 4
---mod 12
---Mod 12 Apply PDT for Utilized time and ICD's


If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
BEGIN
	
	--get the utilised time overlapping with PDT and negate it from UtilisedTime
	UPDATE  #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.PlanDT,0)
	from( select T.ShiftSt as intime,T.Machine as machine,sum (CASE
	--WHEN (autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN (cycletime+loadunload) --DR0325 Commented
	WHEN (autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN DateDiff(second,autodata.msttime,autodata.ndtime) --DR0325 Added
	WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
	WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )
	WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
	END ) as PlanDT
	from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T --ER0324 Added
	WHERE autodata.DataType=1   and T.MachineInterface=autodata.mc AND(
	(autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
	OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
	OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )
	OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime)
	)
	group by T.Machine,T.ShiftSt ) as t2 inner join #ShiftProductionFromAutodataT1 S on t2.intime=S.UstartShift and t2.machine=S.machineId
	

---mod 12:Add ICD's Overlapping  with PDT to UtilisedTime
	/* Fetching Down Records from Production Cycle  */
	 ---mod 12(4):Handle intearction between ICD and PDT for type 1 production record for the selected time period.
		UPDATE  #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)
		FROM	(
		Select T.ShiftSt as intime,AutoData.mc,
		SUM(
		CASE 	
			When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
			When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
			When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
			when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		from #T_autodata autodata INNER Join --ER0324 Added
			(Select mc,Sttime,NdTime,S.UstartShift as StartTime from #T_autodata autodata inner join #ShiftProductionFromAutodataT1 S on S.MachineInterface=autodata.mc
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(msttime >= S.UstartShift) AND (ndtime <= S.UEndShift)) as T1
		ON AutoData.mc=T1.mc CROSS jOIN #PlannedDownTimesShift T
		Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc
		And (( autodata.Sttime >= T1.Sttime ) --DR0339
		And ( autodata.ndtime <= T1.ndtime ) --DR0339
		)
		AND
		((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
		or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
		or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
		or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )
		GROUP BY AUTODATA.mc,T.ShiftSt
		)AS T2  INNER JOIN #ShiftProductionFromAutodataT1 ON
	T2.mc = #ShiftProductionFromAutodataT1.MachineInterface and  t2.intime=#ShiftProductionFromAutodataT1.UstartShift
	

	---mod 12(4)
	/* If production  Records of TYPE-2*/
	UPDATE  #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)
	FROM
	(Select T.ShiftSt as intime,AutoData.mc ,
	SUM(
	CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT
	from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join --ER0324 Added
		(Select mc,Sttime,NdTime,S.UstartShift as StartTime from #T_autodata autodata inner join #ShiftProductionFromAutodataT1 S on S.MachineInterface=autodata.mc
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(msttime < S.UstartShift)And (ndtime > S.UstartShift) AND (ndtime <= S.UEndShift)) as T1
	ON AutoData.mc=T1.mc  and T1.StartTime=T.ShiftSt
	Where AutoData.DataType=2  and T.MachineInterface=autodata.mc
	And (( autodata.Sttime > T1.Sttime )
	And ( autodata.ndtime <  T1.ndtime )
	AND ( autodata.ndtime >  T1.StartTime ))
	AND
	(( T.StartTime >= T1.StartTime )
	And ( T.StartTime <  T1.ndtime ) )
	GROUP BY AUTODATA.mc,T.ShiftSt )AS T2  INNER JOIN #ShiftProductionFromAutodataT1 ON
	T2.mc = #ShiftProductionFromAutodataT1.MachineInterface and  t2.intime=#ShiftProductionFromAutodataT1.UstartShift

	

	/* If production Records of TYPE-3*/
	UPDATE  #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)
	FROM
	(Select T.ShiftSt as intime,AutoData.mc ,
	SUM(
	CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT
	from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join --ER0324 Added
		(Select mc,Sttime,NdTime,S.UstartShift as StartTime,S.UEndShift as EndTime from #T_autodata autodata inner join #ShiftProductionFromAutodataT1 S on S.MachineInterface=autodata.mc
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(sttime >= S.UstartShift)And (ndtime > S.UEndShift) and autodata.sttime <S.UEndShift) as T1
	ON AutoData.mc=T1.mc and T1.StartTime=T.ShiftSt
	Where AutoData.DataType=2  and T.MachineInterface=autodata.mc
	And ((T1.Sttime < autodata.sttime  )
	And ( T1.ndtime >  autodata.ndtime)
	AND (autodata.sttime  <  T1.EndTime))
	AND
	(( T.EndTime > T1.Sttime )
	And ( T.EndTime <=T1.EndTime ) )
	GROUP BY AUTODATA.mc,T.ShiftSt)AS T2   INNER JOIN #ShiftProductionFromAutodataT1 ON
	T2.mc = #ShiftProductionFromAutodataT1.MachineInterface and  t2.intime=#ShiftProductionFromAutodataT1.UstartShift
	

	
	/* If production Records of TYPE-4*/
	UPDATE  #ShiftProductionFromAutodataT1 SET UtilisedTime = isnull(UtilisedTime,0) + isNull(T2.IPDT ,0)
	FROM
	(Select T.ShiftSt as intime,AutoData.mc ,
	SUM(
	CASE 	
		When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
		When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
		When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
		when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
	END) as IPDT
	from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T INNER Join --ER0324 Added
		(Select mc,Sttime,NdTime,S.UstartShift as StartTime,S.UEndShift as EndTime from #T_autodata autodata inner join #ShiftProductionFromAutodataT1 S on S.MachineInterface=autodata.mc
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(msttime < S.UstartShift)And (ndtime > S.UEndShift)) as T1
	ON AutoData.mc=T1.mc and T1.StartTime=T.ShiftSt
	Where AutoData.DataType=2 and T.MachineInterface=autodata.mc
	And ( (T1.Sttime < autodata.sttime  )
		And ( T1.ndtime >  autodata.ndtime)
		AND (autodata.ndtime  >  T1.StartTime)
		AND (autodata.sttime  <  T1.EndTime))
	AND
	(( T.StartTime >=T1.StartTime)
	And ( T.EndTime <=T1.EndTime ) )
	GROUP BY AUTODATA.mc,T.ShiftSt)AS T2  INNER JOIN #ShiftProductionFromAutodataT1 ON
	T2.mc = #ShiftProductionFromAutodataT1.MachineInterface and  t2.intime=#ShiftProductionFromAutodataT1.UstartShift
	
END



---Mod 12 Apply PDT for Utilized time and ICD's
---mod 12 Apply PDT for CN calculation
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	UPDATE #ShiftProductionFromAutodataT1 SET CN = isnull(CN,0) - isNull(t2.C1N1,0)
	From
	(
		select M.Machineid as machine,T.Shiftst as initime,SUM((O.cycletime * ISNULL(A.PartsCount,1))/ISNULL(O.SubOperations,1))  C1N1
		from #T_autodata  A inner join machineinformation M on A.mc=M.interfaceid --ER0324 Added
		Inner join componentinformation C ON A.Comp=C.interfaceid
		Inner join ComponentOperationPricing O ON A.Opn=O.interfaceid AND C.Componentid=O.componentid AND O.Machineid=M.Machineid --DR0299 Sneha K
		CROSS jOIN #PlannedDownTimesShift T
		WHERE A.DataType=1 and T.MachineInterface=A.mc
		AND(A.ndtime > T.StartTime  AND A.ndtime <=T.EndTime)
		Group by M.Machineid,T.shiftst
	) as T2
	inner join #ShiftProductionFromAutodataT1 S  on t2.initime=S.UstartShift  and t2.machine = S.machineid
END
---mod 12 Apply PDT for CN calculation
--mod 12
/*******************************Down Record***********************************/
/*UPDATE #ShiftProductionFromAutodataT1 SET downtime = isnull(downtime,0) + isNull(t2.down,0)
from
(select      mc,
	sum(case when ( (autodata.msttime>=S.UstartShift) and (autodata.ndtime<=S.UEndShift)) then  loadunload
		 when ((autodata.sttime<S.UstartShift)and (autodata.ndtime>S.UstartShift)and (autodata.ndtime<=S.UEndShift)) then DateDiff(second, S.UstartShift, ndtime)
		 when ((autodata.msttime>=S.UstartShift)and (autodata.msttime<S.UEndShift)and (autodata.ndtime>S.UEndShift)) then DateDiff(second, mstTime, S.UEndShift)
		 when ((autodata.msttime<S.UstartShift)and (autodata.ndtime>S.UEndShift)) then DateDiff(second, S.UstartShift, S.UEndShift) END ) as down,S.UstartShift as ShiftStart
from #T_autodata autodata inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface
where (autodata.datatype=1) AND(( (autodata.msttime>=S.UstartShift) and (autodata.ndtime<=S.UEndShift))
OR ((autodata.msttime<S.UstartShift)and (autodata.ndtime>S.UstartShift)and (autodata.ndtime<=S.UEndShift))
OR ((autodata.msttime>=S.UstartShift)and (autodata.msttime<S.UEndShift)and (autodata.ndtime>S.UEndShift))
OR((autodata.msttime<S.UstartShift)and (autodata.ndtime>S.UEndShift)))
group by autodata.mc,S.UstartShift
) as t2 inner join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
and t2.ShiftStart=#ShiftProductionFromAutodataT1.UstartShift*/
--BEGIN: Get the Down Time and ML
---Below IF condition added by Mrudula for mod 12. TO get the ML and Down if 'Ignore_Dtime_4m_PLD'<>"Y"
 Print  '----UPDATE  #ShiftProductionFromAutodataT1 SET downtime------'
  print getdate() 
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y')
BEGIN
	--Type 1
	UPDATE #ShiftProductionFromAutodataT1 SET downtime = isnull(downtime,0) + isNull(t2.down,0)
	from
	(select mc,
		sum(loadunload) down,S.UstartShift as ShiftStart
	from #T_autodata autodata inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface --ER0324 Added
	where (autodata.msttime>=S.UstartShift)
	and (autodata.ndtime<= S.UEndShift)
	and (autodata.datatype=2)
	group by autodata.mc,S.UstartShift
	) as t2 inner join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
	and t2.ShiftStart=#ShiftProductionFromAutodataT1.UstartShift
	
	-- Type 2
	UPDATE #ShiftProductionFromAutodataT1 SET downtime = isnull(downtime,0) + isNull(t2.down,0)
	from
	(select mc,
		sum(DateDiff(second, S.UstartShift, ndtime)) down,S.UstartShift as ShiftStart
	from #T_autodata autodata inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface --ER0324 Added
	where (autodata.sttime<S.UstartShift)
	and (autodata.ndtime>S.UstartShift)
	and (autodata.ndtime<= S.UEndShift)
	and (autodata.datatype=2)
	group by autodata.mc,S.UstartShift
	) as t2 inner join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
	and t2.ShiftStart=#ShiftProductionFromAutodataT1.UstartShift
	
	
	-- Type 3
	UPDATE #ShiftProductionFromAutodataT1 SET downtime = isnull(downtime,0) + isNull(t2.down,0)
	from
	(select mc,
		sum(DateDiff(second, stTime,  S.UEndShift)) down,S.UstartShift as ShiftStart
	from #T_autodata autodata inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface --ER0324 Added
	where (autodata.msttime>=S.UstartShift)
	and (autodata.sttime< S.UEndShift)
	and (autodata.ndtime> S.UEndShift)
	and (autodata.datatype=2)group by autodata.mc,S.Udate,S.UstartShift
	) as t2 inner join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
	and t2.ShiftStart=#ShiftProductionFromAutodataT1.UstartShift
	
	
	-- Type 4
	UPDATE #ShiftProductionFromAutodataT1 SET downtime = isnull(downtime,0) + isNull(t2.down,0)
	from
	(select mc,
		sum(DateDiff(second, S.UstartShift,  S.UEndShift)) down,S.UstartShift as ShiftStart
	from #T_autodata autodata inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface --ER0324 Added
	where autodata.msttime<S.UstartShift
	and autodata.ndtime> S.UEndShift
	and (autodata.datatype=2)group by autodata.mc,S.Udate,S.UstartShift
	) as t2 inner join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
	and t2.ShiftStart=#ShiftProductionFromAutodataT1.UstartShift
	--END: Get the Down Time
	---Management Loss-----
	-- Type 1
	UPDATE #ShiftProductionFromAutodataT1 SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
	from
	(select      mc,
		sum(CASE
	WHEN loadunload >ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)
	ELSE loadunload
	END) loss,S.UstartShift as ShiftStart
	from #T_autodata autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface --ER0324 Added
	where (autodata.msttime>=S.UstartShift)
	and (autodata.ndtime<=S.UEndShift)
	and (autodata.datatype=2)
	and (downcodeinformation.availeffy = 1)
	group by autodata.mc,S.UstartShift
	) as t2 inner join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
	and t2.ShiftStart=#ShiftProductionFromAutodataT1.UstartShift
	-- Type 2
	UPDATE #ShiftProductionFromAutodataT1 SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
	from
	(select      mc,
		sum(CASE
	WHEN DateDiff(second, S.UstartShift, ndtime)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)
	ELSE DateDiff(second, S.UstartShift, ndtime)
	end) loss,S.UstartShift as ShiftStart
	from #T_autodata autodata --ER0324 Added
	 INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface
	where (autodata.sttime<S.UstartShift)
	and (autodata.ndtime>S.UstartShift)
	and (autodata.ndtime<=S.UEndShift)
	and (autodata.datatype=2)
	and (downcodeinformation.availeffy = 1)
	group by autodata.mc,S.Udate,S.UstartShift
	) as t2 inner join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
	and t2.ShiftStart=#ShiftProductionFromAutodataT1.UstartShift
	-- Type 3
	UPDATE #ShiftProductionFromAutodataT1 SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
	from
	(select      mc,
		sum(CASE
	WHEN DateDiff(second, stTime, S.UEndShift)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)ELSE DateDiff(second, stTime, S.UEndShift)
	END) loss,S.UstartShift as ShiftStart
	from #T_autodata autodata  --ER0324 Added
	INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface
	where (autodata.msttime>=S.UstartShift)
	and (autodata.sttime<S.UEndShift)
	and (autodata.ndtime>S.UEndShift)
	and (autodata.datatype=2)
	and (downcodeinformation.availeffy = 1)
	group by autodata.mc,S.UstartShift
	) as t2 inner join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
	and t2.ShiftStart=#ShiftProductionFromAutodataT1.UstartShift
	-- Type 4
	UPDATE #ShiftProductionFromAutodataT1 SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
	from
	(select mc,
		sum(CASE
	WHEN DateDiff(second, S.UstartShift, S.UEndShift)>ISNULL(downcodeinformation.Threshold,0) AND ISNULL(downcodeinformation.Threshold,0)>0 THEN ISNULL(downcodeinformation.Threshold,0)
	ELSE DateDiff(second, S.UstartShift, S.UEndShift)
	END) loss,S.UstartShift as ShiftStart
	from #T_autodata autodata --ER0324 Added
	INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface
	where autodata.msttime<S.UstartShift
	and autodata.ndtime>S.UEndShift
	and (autodata.datatype=2)
	and (downcodeinformation.availeffy = 1)
	group by autodata.mc,S.UstartShift
	) as t2 inner join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
	and t2.ShiftStart=#ShiftProductionFromAutodataT1.UstartShift
	if (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y'
	begin
		
		UPDATE #ShiftProductionFromAutodataT1 SET downtime = isnull(downtime,0) - isNull(t2.PldDown,0)
		from(
		select T.Shiftst  as intime,T.Machine as machine,SUM
		       (CASE
			WHEN (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN autodata.loadunload
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PldDown
		from #T_autodata autodata CROSS jOIN #PlannedDownTimesShift T --ER0324 Added
		INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID
		WHERE autodata.DataType=2  and T.MachineInterface=autodata.mc  AND(
		(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
		OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
		OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
		OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
		)
		AND DownCodeInformation.DownID=(SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')
		group by T.Machine,T.ShiftSt ) as t2 inner join #ShiftProductionFromAutodataT1 S on t2.intime=S.UstartShift and t2.machine=S.machineId
	
	end
---mod 12
END
---mod 12
---mod 12:Get the down time and Management loss when setting for 'Ignore_Dtime_4m_PLD'='Y'
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN
	---Get the down times which are not of type Management Loss
	UPDATE #ShiftProductionFromAutodataT1 SET downtime = isnull(downtime,0) + isNull(t2.down,0)
	from
	(select      mc,
		sum(case when ( (autodata.msttime>=S.UstartShift) and (autodata.ndtime<=S.UEndShift)) then  loadunload
			 when ((autodata.sttime<S.UstartShift)and (autodata.ndtime>S.UstartShift)and (autodata.ndtime<=S.UEndShift)) then DateDiff(second, S.UstartShift, ndtime)
			 when ((autodata.msttime>=S.UstartShift)and (autodata.msttime<S.UEndShift)and (autodata.ndtime>S.UEndShift)) then DateDiff(second, stTime, S.UEndShift)
			 when ((autodata.msttime<S.UstartShift)and (autodata.ndtime>S.UEndShift)) then DateDiff(second, S.UstartShift, S.UEndShift) END ) as down,S.UstartShift as ShiftStart
	   from #T_autodata autodata --ER0324 Added
	   inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface
	   inner join  downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
	where (autodata.datatype=2) AND(( (autodata.msttime>=S.UstartShift) and (autodata.ndtime<=S.UEndShift))
	      OR ((autodata.msttime<S.UstartShift)and (autodata.ndtime>S.UstartShift)and (autodata.ndtime<=S.UEndShift))
	      OR ((autodata.msttime>=S.UstartShift)and (autodata.msttime<S.UEndShift)and (autodata.ndtime>S.UEndShift))
	      OR((autodata.msttime<S.UstartShift)and (autodata.ndtime>S.UEndShift))) AND (downcodeinformation.availeffy = 0)
	      group by autodata.mc,S.UstartShift
	) as t2 inner join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
	and t2.ShiftStart=#ShiftProductionFromAutodataT1.UstartShift
	
	UPDATE #ShiftProductionFromAutodataT1 SET downtime = isnull(downtime,0) - isNull(t2.PldDown,0)
	from(
		select T.Shiftst  as intime,T.Machine as machine,SUM
		       (CASE
			WHEN (autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)  THEN autodata.loadunload
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PldDown
		from #T_autodata autodata  --ER0324 Added
		CROSS jOIN #PlannedDownTimesShift T
		INNER JOIN DownCodeInformation  ON AutoData.DCode = DownCodeInformation.InterfaceID
		WHERE autodata.DataType=2  and T.MachineInterface=autodata.mc  AND(
		(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
		OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
		OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
		OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
		)
		AND (downcodeinformation.availeffy = 0)
		group by T.Machine,T.ShiftSt ) as t2 inner join #ShiftProductionFromAutodataT1 S on t2.intime=S.UstartShift and t2.machine=S.machineId
	
	
	UPDATE #ShiftProductionFromAutodataT1 SET ManagementLoss = isnull(ManagementLoss,0)+ isNull(t4.Mloss,0),MLDown=isNull(MLDown,0)+isNull(t4.Dloss,0)
	from
	(select T3.mc,T3.StrtShft,sum(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss from
	 (
	select   t1.id,T1.mc,T1.Threshold,T1.StartShift as StrtShft,
	case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0) > 0
	then DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)- isnull(T1.Threshold ,0)
	else 0 End  as Dloss,
	case when DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0)> isnull(T1.Threshold ,0) and isnull(T1.Threshold ,0) > 0
	then isnull(T1.Threshold,0)
	else DateDiff(second,T1.sttime,T1.ndtime)-isnull(T2.PPDT,0) End  as Mloss
	 from
	
	(   select id,mc,comp,opn,opr,D.threshold,S.UstartShift as StartShift,
		case when autodata.sttime<S.UstartShift then S.UstartShift else sttime END as sttime,
	       	case when ndtime>S.UEndShift then S.UEndShift else ndtime END as ndtime
		from #T_autodata autodata --ER0324 Added
		inner join downcodeinformation D
		on autodata.dcode=D.interfaceid inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface
		where autodata.datatype=2 AND
		(
		(autodata.msttime>=S.UstartShift  and  autodata.ndtime<=S.UEndShift)
		OR (autodata.sttime<S.UstartShift and  autodata.ndtime>S.UstartShift and autodata.ndtime<=S.UEndShift)
		OR (autodata.msttime>=S.UstartShift  and autodata.sttime<S.UEndShift  and autodata.ndtime>S.UEndShift)
		OR (autodata.msttime<S.UstartShift and autodata.ndtime>S.UEndShift )
		) AND (D.availeffy = 1)) as T1 	
	left outer join
	(SELECT T.Shiftst  as intime, autodata.id,
		       sum(CASE
			WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PPDT
		from #T_autodata autodata  --ER0324 Added
		CROSS jOIN #PlannedDownTimesShift T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		WHERE autodata.DataType=2 and T.MachineInterface=autodata.mc AND
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)
			 AND (downcodeinformation.availeffy = 1) group by autodata.id,T.Shiftst ) as T2 on T1.id=T2.id  and T1.StartShift=T2.intime ) as T3  group by T3.mc,T3.StrtShft
	) as t4 inner join #ShiftProductionFromAutodataT1 S on t4.StrtShft=S.UstartShift and t4.mc=S.MachineInterface
	UPDATE #ShiftProductionFromAutodataT1  set downtime = isnull(downtime,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)
	
END
------------------------------ : End Downtime and ML calculation  : --------------------------------------------------------
--select * from #ShiftProductionFromAutodataT1
--return
/*
--BEGIN: CN
--Type 1
UPDATE #ShiftProductionFromAutodataT1 SET CN = isnull(CN,0) + isNull(t2.C1N1,0)
from
(select mc,
--SUM(componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1)) C1N1
SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))*autodata.partscount) C1N1,S.Udate as date1,S.UstartShift as ShiftStart
from #T_autodata autodata INNER JOIN
componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID AND
componentoperationpricing.componentid = componentinformation.componentid inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface
where (autodata.sttime>=S.UstartShift)
and (autodata.ndtime<=S.UEndShift)
and (autodata.datatype=1)
group by autodata.mc,S.Udate,S.UstartShift
) as t2 inner join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
and t2.date1=#ShiftProductionFromAutodataT1.Udate and t2.ShiftStart=#ShiftProductionFromAutodataT1.UstartShift
--Type 2	
UPDATE #ShiftProductionFromAutodataT1 SET CN = isnull(CN,0) + isNull(t2.C1N1,0)
from
(select mc,
--SUM(componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1)) C1N1
SUM((componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1))*autodata.partscount) C1N1,S.Udate as date1,S.UstartShift as ShiftStart
from #T_autodata autodata INNER JOIN
componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID AND
componentoperationpricing.componentid = componentinformation.componentid inner join #ShiftProductionFromAutodataT1 S on autodata.mc=S.MachineInterface
where (autodata.sttime<S.UstartShift)
and (autodata.ndtime>S.UstartShift)
and (autodata.ndtime<=S.UEndShift)
and (autodata.datatype=1)
group by autodata.mc,S.Udate,S.UstartShift
) as t2 inner join #ShiftProductionFromAutodataT1 on t2.mc = #ShiftProductionFromAutodataT1.machineinterface
and t2.date1=#ShiftProductionFromAutodataT1.Udate and t2.ShiftStart=#ShiftProductionFromAutodataT1.UstartShift
*/
-- Calculate efficiencies



Update #ShiftProductionFromAutodataT1 set RejCount = isnull(RejCount,0) + isnull(T1.RejQty,0)    
From    
( Select A.mc,SUM(A.Rejection_Qty) as RejQty,T1.UstartShift from AutodataRejections A    
inner join Machineinformation M on A.mc=M.interfaceid    
inner join #ShiftProductionFromAutodataT1 T1 on T1.MachineInterface=A.mc    
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid    
where A.CreatedTS>=T1.UstartShift and A.CreatedTS<T1.UEndShift and A.flag = 'Rejection'    
and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000'    
group by A.mc,T1.UstartShift
)T1 inner join #ShiftProductionFromAutodataT1 B on B.MachineInterface=T1.mc and B.UstartShift=T1.UstartShift     
 
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'    
BEGIN    
 Update #ShiftProductionFromAutodataT1 set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from    
 (Select A.mc,SUM(A.Rejection_Qty) as RejQty,T1.UstartShift from AutodataRejections A    
 inner join Machineinformation M on A.mc=M.interfaceid    
 inner join #ShiftProductionFromAutodataT1 T1 on T1.MachineInterface=A.mc   
 inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid    
 Cross join #PlannedDownTimesShift P    
 where  A.flag = 'Rejection' and P.machine=M.Machineid     
 and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000' and    
 A.CreatedTS>=UstartShift and A.CreatedTS<UEndShift And    
 A.CreatedTS>=P.Starttime and A.CreatedTS<P.endtime    
 group by A.mc,T1.UstartShift
 )T1 inner join #ShiftProductionFromAutodataT1 B on B.MachineInterface=T1.mc and B.UstartShift=T1.UstartShift     
END     

 
    
Update #ShiftProductionFromAutodataT1 set RejCount = isnull(RejCount,0) + isnull(T1.RejQty,0)    
From    
( Select A.mc,SUM(A.Rejection_Qty) as RejQty,T1.UstartShift from AutodataRejections A    
inner join Machineinformation M on A.mc=M.interfaceid    
inner join #ShiftProductionFromAutodataT1 T1 on T1.MachineInterface=A.mc   
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid    
--inner join #ShiftDefn S on (convert(nvarchar(10),(A.RejDate),120)=convert(nvarchar(10),S.shiftdate,120)) and A.RejShift=S.shiftid 
where A.flag = 'Rejection' and A.Rejshift in (T1.shiftid) and convert(nvarchar(10),(A.RejDate),120) in (convert(nvarchar(10),T1.Udate,120)) and  
Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'    
group by A.mc,T1.UstartShift
)T1 inner join #ShiftProductionFromAutodataT1 B on  B.MachineInterface=T1.mc and B.UstartShift=T1.UstartShift   
    
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'    
BEGIN    
 Update #ShiftProductionFromAutodataT1 set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from    
 (Select A.mc,SUM(A.Rejection_Qty) as RejQty,T1.UstartShift from AutodataRejections A    
 inner join Machineinformation M on A.mc=M.interfaceid    
 inner join #ShiftProductionFromAutodataT1 T1 on T1.MachineInterface=A.mc  
 inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid    
 --inner join #ShiftDefn S on convert(nvarchar(10),(A.RejDate),126)=S.shiftdate and A.RejShift=S.shiftid      
 Cross join #PlannedDownTimesShift P    
 where  A.flag = 'Rejection' and P.machine=M.Machineid and    
 A.Rejshift in (T1.shiftid) and convert(nvarchar(10),(A.RejDate),120) in (convert(nvarchar(10),T1.Udate,120)) and 
 Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'    
 and P.starttime>=T1.UstartShift and P.Endtime<=T1.UEndShift  
 group by A.mc,T1.UstartShift)T1 inner join #ShiftProductionFromAutodataT1 B on  B.MachineInterface=T1.mc and B.UstartShift=T1.UstartShift   
END    
 

UPDATE #ShiftProductionFromAutodataT1 SET QualityEfficiency= ISNULL(QualityEfficiency,0) + IsNull(T1.QE,1) 
FROM(Select T1.MachineID,T1.UstartShift,
--CAST((Sum(Operationcount))As Float)/CAST((Sum(IsNull(Operationcount,0))+Sum(IsNull(RejCount,0))) AS Float)As QE
CAST((Sum(Operationcount))As Float)/CAST((Sum(IsNull(Operationcount,0))+(IsNull(RejCount,0))) AS Float)As QE
From #ShiftProductionFromAutodataT1 T1
INNER JOIN #ShiftProductionFromAutodataT2  T2 ON
		T1.MachineID = T2.MachineID and
		T1.UDate=T2.Sdate and
		T1.Ushift=T2.ShiftName
Where Operationcount<>0 Group By T1.MachineID,T1.UstartShift,RejCount
)AS T1 Inner Join #ShiftProductionFromAutodataT1 ON  #ShiftProductionFromAutodataT1.MachineID=T1.MachineID and #ShiftProductionFromAutodataT1.UstartShift=T1.UstartShift






 Print  '----UPDATE  #ShiftProductionFromAutodataT1 SET effic------'
         print getdate() 

UPDATE #ShiftProductionFromAutodataT1
SET
	ProductionEfficiency = (CN/UtilisedTime) ,
	AvailabilityEfficiency = (UtilisedTime)/(UtilisedTime + DownTime - ManagementLoss)
WHERE UtilisedTime <> 0
UPDATE #ShiftProductionFromAutodataT1
SET
	OverAllEfficiency = (CASe WHEN (SELECT OEEFormula FROM MachineOEEFormula_Shanti where MachineID = #ShiftProductionFromAutodataT1.MachineID) = 'AE'
           THEN (AvailabilityEfficiency)*100
		   --ELSE (ProductionEfficiency * AvailabilityEfficiency ) *100
		   WHEN (SELECT OEEFormula FROM MachineOEEFormula_Shanti where MachineID = #ShiftProductionFromAutodataT1.MachineID) = 'AE*PE'
		   THEN (ProductionEfficiency * AvailabilityEfficiency ) *100
		   ELSE (ProductionEfficiency * AvailabilityEfficiency * ISNULL(QualityEfficiency,1))*100
		   END),
	--(ProductionEfficiency * AvailabilityEfficiency)*100,
	ProductionEfficiency = ProductionEfficiency * 100 ,
	AvailabilityEfficiency = AvailabilityEfficiency * 100,
	QualityEfficiency=QualityEfficiency*100
--mod 4
--mod 4
Declare @strmachine1 nvarchar(255)
Declare @stroperation1 nvarchar(255)
Declare @strcomponent1 nvarchar(255)
Declare @strShift1 nvarchar(255)
declare @TrSql1 nvarchar(2000)
SELECT @strmachine1 = ''
SELECT @strcomponent1 = ''
SELECT @stroperation1 = ''
SELECT @strShift1=''
	if isnull(@MachineID,'') <> ''
		BEGIN
		---mod 8
--		SELECT @strmachine1 = ' AND ( machine = ''' + @MachineID+ ''')'
		SELECT @strmachine1 = ' AND ( machine = N''' + @MachineID+ ''')'	
		---mod 8
		END
	if isnull(@ComponentID, '') <> ''
		BEGIN
		---mod 8
--		SELECT @strcomponent1 = ' AND ( component = ''' + @ComponentID+ ''')'
		SELECT @strcomponent1 = ' AND ( component = N''' + @ComponentID+ ''')'
		---mod 8
		END
	if isnull(@OperationNo, '') <> ''
		BEGIN
		---mod 8
--		SELECT @stroperation1 = ' AND ( operation = ''' + @OperationNo + ''')'
		SELECT @stroperation1 = ' AND ( operation = N''' + @OperationNo + ''')'
		---mod 8
		END
	if isnull(@ShiftIn,'')<> ''
		BEGIN
		---mod 8
--		SELECT @strShift1=' AND (shift=''' +@ShiftIn+ ''') '
		SELECT @strShift1=' AND (shift= N''' +@ShiftIn+ ''') '
		---mod 8
		END
		 Print  '----UPDATE  #ShiftProductionFromAutodataT2 SET target------'
         print getdate() 
	if isnull(@Targetsource,'')='Exact Schedule' 	 BEGIN
		select @TrSql1=''
	
	--select * from #shifttemp
	     select @TrSql1='update #ShiftProductionFromAutodataT2 set Targetcount= ISNULL(targetcount,0) + ISNULL(t1.tcount,0) from
		( select date as date1,shift,machine,component,operation,idealcount as tcount from
		  loadschedule where date>=''' +convert(nvarchar(20),@startDate)+''' and date<=''' +convert(nvarchar(20),@EndDate)+ ''' '
		 select @TrSql1= @TrSql1 + @strmachine1 + @strcomponent1 + @stroperation1 + @strShift1
	     select @TrSql1=@TrSql1+ ') as t1 inner join #ShiftProductionFromAutodataT2 on
		  t1.date1=#ShiftProductionFromAutodataT2.Sdate and t1.shift=#ShiftProductionFromAutodataT2.ShiftName and t1.component=#ShiftProductionFromAutodataT2.Component
		  and t1.operation=#ShiftProductionFromAutodataT2.Operation '
		---mod 7
		select @TrSql1 = @TrSql1 + ' and t1.machine = #ShiftProductionFromAutodataT2.machineid '
		---mod 7
--		print @TrSql1
		exec(@TrSql1)	
		
	END
	
		
		IF isnull(@Targetsource,'')='Default Target per CO'
		BEGIN
			PRINT @Targetsource
			select @TrSql1=''
			select @TrSql1='update #ShiftProductionFromAutodataT2 set Targetcount= isnull(Targetcount,0)+ ISNULL(t1.tcount,0) from
					( select DATE AS date1, machine,component,operation,sum(idealcount) as tcount from
				  	loadschedule where date=(SELECT TOP 1 DATE FROM LOADSCHEDULE ORDER BY DATE DESC) and SHIFT=(SELECT TOP 1 SHIFT FROM LOADSCHEDULE ORDER BY SHIFT DESC)'
		        select @TrSql1= @TrSql1 + @strmachine1 + @strcomponent1 + @stroperation1
			select @TrSql1=@TrSql1+ ' group by date,machine,component,operation ) as t1 inner join #ShiftProductionFromAutodataT2 on
				  	t1.component=#ShiftProductionFromAutodataT2.Component
				  	and t1.operation=#ShiftProductionFromAutodataT2.Operation '
			---mod 7
			select @TrSql1 = @TrSql1 + ' and t1.machine = #ShiftProductionFromAutodataT2.machineid '
			---mod 7	
			PRINT @TrSql1
			EXEC (@TrSql1)
			--select * from #Shifttemp
			--return
						
		END
		IF ISNULL(@Targetsource,'')='% Ideal'
		BEGIN
			select @strmachine1=''
			if isnull(@MachineID,'') <> ''
			BEGIN
			---mod 8
--			SELECT @strmachine1 = ' AND ( CO.machineID = ''' + @MachineID+ ''')'
			SELECT @strmachine1 = ' AND ( CO.machineID = N''' + @MachineID+ ''')'
			---mod 8
			END
			select @strcomponent1=''
			if isnull(@ComponentID, '') <> ''
			BEGIN
			---mod 8
--			SELECT @strcomponent1 = ' AND (CO.componentID = ''' + @ComponentID+ ''')'
			SELECT @strcomponent1 = ' AND (CO.componentID = N''' + @ComponentID+ ''')'
			---mod 8			
			END
			select @stroperation1=''
			if isnull(@OperationNo, '') <> ''
			BEGIN
			---mod 8
--			SELECT @stroperation1 = ' AND ( CO.operationno = ''' + @OperationNo + ''')'
			SELECT @stroperation1 = ' AND ( CO.operationno = N''' + @OperationNo + ''')'
			---mod 8
			END
			
		    select @TrSql1=''
			---mod 7
--			select @TrSql1='update #ShiftProductionFromAutodataT2 set Targetcount= isnull(Targetcount,0)+ ISNULL(t1.tcount,0) from
--					 ( select CO.componentid as component,CO.Operationno as operation, tcount=((datediff(second,#ShiftProductionFromAutodataT2.ShftStart,#ShiftProductionFromAutodataT2.ShftEnd)*CO.suboperations)/CO.cycletime)*isnull(CO.targetpercent,100) /100
--					from componentoperationpricing CO inner join #ShiftProductionFromAutodataT2 on CO.Componentid=#ShiftProductionFromAutodataT2.Component
--					and Co.operationno=#ShiftProductionFromAutodataT2.operation '
			select @TrSql1='update #ShiftProductionFromAutodataT2 set Targetcount= isnull(Targetcount,0)+ ISNULL(t1.tcount,0) from
					 ( select CO.componentid as component,CO.Operationno as operation,CO.machineid,tcount=((datediff(second,#ShiftProductionFromAutodataT2.ShftStart,#ShiftProductionFromAutodataT2.ShftEnd)*CO.suboperations)/CO.cycletime)*isnull(CO.targetpercent,100) /100
					from componentoperationpricing CO inner join #ShiftProductionFromAutodataT2 on CO.Componentid=#ShiftProductionFromAutodataT2.Component
					and Co.operationno=#ShiftProductionFromAutodataT2.operation '
			select @TrSql1= @TrSql1 +' inner join machineinformation on machineinformation.machineid=CO.machineid'
			---mod 7
			select @TrSql1= @TrSql1 + @strmachine1 + @strcomponent1 + @stroperation1
			select @TrSql1=@TrSql1+ '  ) as t1 inner join #ShiftProductionFromAutodataT2 on
				  	t1.component=#ShiftProductionFromAutodataT2.Component
				  	and t1.operation=#ShiftProductionFromAutodataT2.operation '	
			---mod 7
			select @TrSql1 = @TrSql1 + ' and t1.machineid = #ShiftProductionFromAutodataT2.machineid '
			---mod 7
			--PRINT @TrSql1
			EXEC (@TrSql1)
			--select * from #Shifttemp
			--return
--mod 13
			--select * from #Shifttemp
--Select * from #ShiftProductionFromAutodataT2
	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
	BEGIN
		update #ShiftProductionFromAutodataT2 set Targetcount=Targetcount-((cast(t3.Totalpdt as float)/cast(datediff(ss,t3.Starttime,t3.Endtime) as float))*Targetcount)
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
						(Select distinct Machineid,ShftStart as StartTime ,ShftEnd as EndTime from #ShiftProductionFromAutodataT2) as fd
						 cross join planneddowntimes pdt
						where PDTstatus = 1  and fd.machineID = pdt.Machine and --and DownReason <> 'SDT'
						((pdt.StartTime >= fd.StartTime and pdt.EndTime <= fd.EndTime)or
						(pdt.StartTime < fd.StartTime and pdt.EndTime > fd.StartTime and pdt.EndTime <=fd.EndTime)or
						(pdt.StartTime >= fd.StartTime and pdt.StartTime <fd.EndTime and pdt.EndTime > fd.EndTime) or
						(pdt.StartTime < fd.StartTime and pdt.EndTime > fd.EndTime))
						)T2 group by Machineid,Starttime,Endtime
						)T3 inner join #ShiftProductionFromAutodataT2
						on T3.Machineid=#ShiftProductionFromAutodataT2.machineid
						 and T3.Starttime=#ShiftProductionFromAutodataT2.ShftStart
						and T3.Endtime= #ShiftProductionFromAutodataT2.ShftEnd
						
			End
--mod 13
END
delete from shift_proc where SSession=@@SPID
--mod 13

/************************************** DR0325 Commented From Here **********************************
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
BEGIN
	UPDATE #ShiftProductionFromAutodataT2 set AvgCycleTime =isnull(AvgCycleTime,0) - isNull(TT.PPDT ,0)
	FROM(
		--Production Time in PDT
	Select A.mc,A.comp,A.Opn,A.ShftStrt,A.ShftND,Sum
			(CASE
			WHEN A.sttime >= T.StartTime  AND A.ndtime <=T.EndTime  THEN (A.cycletime)
			WHEN ( A.sttime < T.StartTime  AND A.ndtime <= T.EndTime  AND A.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,A.ndtime)
			WHEN ( A.sttime >= T.StartTime   AND A.sttime <T.EndTime  AND A.ndtime > T.EndTime  ) THEN DateDiff(second,A.sttime,T.EndTime )
			WHEN ( A.sttime < T.StartTime  AND A.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END)  as PPDT
	From
			
		(
				SELECT M.Machine,
				autodata.MC,autodata.comp,autodata.Opn,autodata.sttime,autodata.ndtime
				,autodata.Cycletime,M.ShftStrt,M.ShftND
			from #T_autodata autodata --ER0324 Added
			inner join #Machcomopnopr M on M.machineint=Autodata.mc
			and autodata.comp=M.CompInt and autodata.Opn=M.opnInt
			where autodata.DataType=1 And autodata.ndtime >M.ShftStrt  AND autodata.ndtime <=M.ShftND)A
			--CROSS jOIN PlannedDownTimes T --DR0327 commented
			CROSS jOIN #PlannedDownTimesShift T --DR0327 Added
			WHERE T.Machine=A.Machine AND
			T.ShiftSt = A.ShftStrt AND ---DR0327 Added
			((A.sttime >= T.StartTime  AND A.ndtime <=T.EndTime)
			OR ( A.sttime < T.StartTime  AND A.ndtime <= T.EndTime AND A.ndtime > T.StartTime )
			OR ( A.sttime >= T.StartTime   AND A.sttime <T.EndTime AND A.ndtime > T.EndTime )
			OR ( A.sttime < T.StartTime  AND A.ndtime > T.EndTime) )
		group by A.mc,A.comp,A.Opn,A.ShftStrt,A.ShftND
	)
	as TT INNER JOIN #ShiftProductionFromAutodataT2 ON TT.mc = #ShiftProductionFromAutodataT2.MachineInterface
		and TT.comp = #ShiftProductionFromAutodataT2.CompInterface
			and TT.opn = #ShiftProductionFromAutodataT2.OPNInterface and TT.ShftStrt=#ShiftProductionFromAutodataT2.ShftStart
						and TT.ShftND= #ShiftProductionFromAutodataT2.ShftEnd

	--Handle intearction between ICD and PDT for type 1 production record for the selected time period.
		UPDATE  #ShiftProductionFromAutodataT2 set AvgCycleTime =isnull(AvgCycleTime,0) + isNull(T2.IPDT ,0) 	FROM	(
		Select AutoData.mc,autodata.comp,autodata.Opn,T1.ShftStrt,T1.Shftnd,
		SUM(
		CASE 	
			When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
			When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
			When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
			when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		from #T_autodata autodata INNER Join --ER0324 Added
			(Select machine,mc,Sttime,NdTime,M.ShftStrt,M.Shftnd from #T_autodata autodata
				inner join #Machcomopnopr M on M.machineint=Autodata.mc
				and autodata.comp=M.CompInt and autodata.Opn=M.opnInt
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(ndtime > M.ShftStrt) AND (ndtime <= M.Shftnd)) as T1
		ON AutoData.mc=T1.mc 
		--CROSS jOIN PlannedDownTimes T --DR0327 Commented
		Cross join #PlannedDownTimesShift T --DR0327 Added
		Where AutoData.DataType=2 And T.Machine=T1.Machine
		AND T.ShiftSt = T1.ShftStrt ---DR0327 Added
		And (( autodata.Sttime > T1.Sttime )
		And ( autodata.ndtime <  T1.ndtime )
		)
		AND
		((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
		or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
		or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
		or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )
		GROUP BY AUTODATA.mc,autodata.comp,autodata.Opn,T1.ShftStrt,T1.Shftnd
		)AS T2  INNER JOIN #ShiftProductionFromAutodataT2 ON T2.mc = #ShiftProductionFromAutodataT2.MachineInterface
				and T2.comp = #ShiftProductionFromAutodataT2.CompInterface
			and T2.opn = #ShiftProductionFromAutodataT2.OPNInterface and T2.ShftStrt=#ShiftProductionFromAutodataT2.ShftStart
						and T2.Shftnd= #ShiftProductionFromAutodataT2.ShftEnd
	
End
********************************** DR0325 Commented From Here *****************************************/



----------------------------------- DR0325 Added From Here -----------------------------------------
 Print  '----UPDATE  #ShiftProductionFromAutodataT1 SET AvgCycleTime------'
 print getdate() 

--If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y' --ER0363 Commented
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_AvgCycletime_4m_PLD')='Y' --ER0363 Added
BEGIN
	UPDATE #ShiftProductionFromAutodataT2 set AvgCycleTime =isnull(AvgCycleTime,0) - isNull(TT.PPDT ,0),
		AVGLoadUnload = isnull(AVGLoadUnload,0) - isnull(LD,0)
	FROM(
		--Production Time in PDT
	Select A.mc,A.comp,A.Opn,A.ShftStrt,A.ShftND,Sum
			(CASE
--			WHEN A.sttime >= T.StartTime  AND A.ndtime <=T.EndTime  THEN (A.cycletime) --DR0325 Commented
			WHEN A.sttime >= T.StartTime  AND A.ndtime <=T.EndTime  THEN DateDiff(second,A.sttime,A.ndtime) --DR0325 Added
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
				SELECT distinct M.Machine,
				autodata.MC,autodata.comp,autodata.Opn,autodata.sttime,autodata.ndtime,autodata.msttime
				,autodata.Cycletime,M.ShftStrt,M.ShftND
				from #T_autodata autodata --ER0324 Added
				inner join #Machcomopnopr M on M.machineint=Autodata.mc
				and autodata.comp=M.CompInt and autodata.Opn=M.opnInt
				where autodata.DataType=1 And autodata.ndtime >M.ShftStrt  AND autodata.ndtime <=M.ShftND
			)A
			CROSS jOIN PlannedDownTimes T 
			WHERE T.Machine=A.Machine AND
			((A.msttime >= T.StartTime  AND A.ndtime <=T.EndTime)
			OR ( A.msttime < T.StartTime  AND A.ndtime <= T.EndTime AND A.ndtime > T.StartTime )
			OR ( A.msttime >= T.StartTime   AND A.msttime <T.EndTime AND A.ndtime > T.EndTime )
			OR ( A.msttime < T.StartTime  AND A.ndtime > T.EndTime) )
--			AND
--			((T.StartTime >= A.ShftStrt  AND T.EndTime <= A.ShftND)
--			OR ( T.StartTime < A.ShftStrt  AND T.EndTime <= A.ShftND AND T.EndTime > A.ShftStrt )
--			OR ( T.StartTime >= A.ShftStrt  AND T.StartTime <A.ShftND AND T.EndTime >A.ShftND )
--			OR ( T.StartTime < A.ShftStrt  AND T.EndTime > A.ShftND))		
		group by A.mc,A.comp,A.Opn,A.ShftStrt,A.ShftND
	)
	as TT INNER JOIN #ShiftProductionFromAutodataT2 ON TT.mc = #ShiftProductionFromAutodataT2.MachineInterface
		and TT.comp = #ShiftProductionFromAutodataT2.CompInterface
			and TT.opn = #ShiftProductionFromAutodataT2.OPNInterface and TT.ShftStrt=#ShiftProductionFromAutodataT2.ShftStart
						and TT.ShftND= #ShiftProductionFromAutodataT2.ShftEnd

	--Handle intearction between ICD and PDT for type 1 production record for the selected time period.
		UPDATE  #ShiftProductionFromAutodataT2 set AvgCycleTime =isnull(AvgCycleTime,0) + isNull(T2.IPDT ,0) 	FROM	
		(
		Select AutoData.mc,autodata.comp,autodata.Opn,T1.ShftStrt,T1.Shftnd,
		SUM(
		CASE 	
			When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
			When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
			When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
			when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		from #T_autodata autodata INNER Join --ER0324 Added
			(Select distinct machine,mc,Sttime,NdTime,M.ShftStrt,M.Shftnd from #T_autodata autodata
				inner join #Machcomopnopr M on M.machineint=Autodata.mc
				and autodata.comp=M.CompInt and autodata.Opn=M.opnInt
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(ndtime > M.ShftStrt) AND (ndtime <= M.Shftnd)) as T1
		ON AutoData.mc=T1.mc 
		CROSS jOIN PlannedDownTimes T 
		Where AutoData.DataType=2 And T.Machine=T1.Machine
		And (( autodata.Sttime >= T1.Sttime ) --DR0339
		And ( autodata.ndtime <= T1.ndtime ) --DR0339
		)
		AND
		((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
		or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
		or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
		or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )))
--		AND
--		((T.StartTime >= T1.ShftStrt  AND T.EndTime <= T1.ShftND)
--		OR ( T.StartTime < T1.ShftStrt  AND T.EndTime <= T1.ShftND AND T.EndTime > T1.ShftStrt )
--		OR ( T.StartTime >= T1.ShftStrt  AND T.StartTime <T1.ShftND AND T.EndTime >T1.ShftND )
--		OR ( T.StartTime < T1.ShftStrt  AND T.EndTime > T1.ShftND))		
		GROUP BY AUTODATA.mc,autodata.comp,autodata.Opn,T1.ShftStrt,T1.Shftnd
		)AS T2  INNER JOIN #ShiftProductionFromAutodataT2 ON T2.mc = #ShiftProductionFromAutodataT2.MachineInterface
				and T2.comp = #ShiftProductionFromAutodataT2.CompInterface
			and T2.opn = #ShiftProductionFromAutodataT2.OPNInterface and T2.ShftStrt=#ShiftProductionFromAutodataT2.ShftStart
						and T2.Shftnd= #ShiftProductionFromAutodataT2.ShftEnd
	
End
----------------------------------- DR0325 Added Till Here -----------------------------------------


/*ER0291
Update #ShiftProductionFromAutodataT2 set avgCycletime=(isnull(avgCycletime,0)/isnull(OperationCount,1))* isnull(suboperations,1) from #ShiftProductionFromAutodataT2
inner join componentoperationpricing C on #ShiftProductionFromAutodataT2.MachineID=C.MachineID and #ShiftProductionFromAutodataT2.component=C.Componentid and
#ShiftProductionFromAutodataT2.Operation = c.Operationno
ER0291*/
--ER0291
Update #ShiftProductionFromAutodataT2 set avgCycletime=(isnull(avgCycletime,0)/isnull(OperationCount,1))* isnull(suboperations,1) 
,avgloadunload=(isnull(avgloadunload,0)/isnull(OperationCount,1))* isnull(suboperations,1)  --DR0325 added
from #ShiftProductionFromAutodataT2
inner join componentoperationpricing C on #ShiftProductionFromAutodataT2.MachineID=C.MachineID and #ShiftProductionFromAutodataT2.component=C.Componentid and
#ShiftProductionFromAutodataT2.Operation = c.Operationno where OperationCount>0
--ER0291

-----ER0450 From Here
IF EXISTS(select * from company where CompanyName like '%SHANTI IRON AND STEEL FOUNDRY%')
Begin
	update #ShiftProductionFromAutodataT2 set Operation = T.Description From
	(Select distinct machineid,componentid,operationno,description from componentoperationpricing
	)T inner join #ShiftProductionFromAutodataT2 D on T.machineid=D.machineid and T.componentid=D.Component and T.operationno=D.Operation
END
-----ER0450 From Here


--mod 13
--Get preferred time format
select @timeformat ='ss'
select @timeformat = isnull((select valueintext from cockpitdefaults where parameter='timeformat'),'ss')
if (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')
begin
select @timeformat = 'ss'
end
--Output
 Print  '----Output------'
 print getdate() 

If @Param = 'ProdandDown'
Begin
	select  #ShiftProductionFromAutodataT1.MachineID,
	    #ShiftProductionFromAutodataT1.MachineDescription MachineDescription,
		#ShiftProductionFromAutodataT1.OperatorId,#ShiftProductionFromAutodataT1.OperatorName,
		ROUND(#ShiftProductionFromAutodataT1.ProductionEfficiency,2) as ProductionEfficiency,
		ROUND(#ShiftProductionFromAutodataT1.AvailabilityEfficiency,2) as AvailabilityEfficiency,
		ROUND(#ShiftProductionFromAutodataT1.OverallEfficiency,2) as OverallEfficiency,
		dbo.f_formattime(#ShiftProductionFromAutodataT1.DownTime, @timeformat) as frmtDownTime,
		isnull(#ShiftProductionFromAutodataT2.Component,'') as Component,
		isnull(#ShiftProductionFromAutodataT2.Operation,'') as Operation,
		------isnull(#ShiftProductionFromAutodataT2.CycleTime,0) as frmtCycleTime,
		------isnull(#ShiftProductionFromAutodataT2.LoadUnload,0) as frmtLoadUnload,
		------ROUND(isnull(#ShiftProductionFromAutodataT2.AvgCycleTime,0),2) as frmtAvgCycleTime,
		------ROUND(isnull(#ShiftProductionFromAutodataT2.AvgLoadUnload,0),2) as frmtAvgLoadUnload,

		--case when #ShiftProductionFromAutodataT2.PlantID='1003' then 
		--ROUND(isnull(#ShiftProductionFromAutodataT2.CycleTime,0)+isnull(#ShiftProductionFromAutodataT2.LoadUnload,0),2)
		--Else ROUND(isnull(#ShiftProductionFromAutodataT2.CycleTime,0),2) END as frmtCycleTime,
		--ROUND(isnull(#ShiftProductionFromAutodataT2.LoadUnload,0),2) as frmtLoadUnload,
		--case when #ShiftProductionFromAutodataT2.PlantID='1003' then 
		--ROUND(isnull(#ShiftProductionFromAutodataT2.AvgCycleTime,0)+isnull(#ShiftProductionFromAutodataT2.AvgLoadUnload,0),2)
		--Else ROUND(isnull(#ShiftProductionFromAutodataT2.AvgCycleTime,0),2) END as frmtAvgCycleTime,
		--ROUND(isnull(#ShiftProductionFromAutodataT2.AvgLoadUnload,0),2) as frmtAvgLoadUnload,
		case when #ShiftProductionFromAutodataT2.PlantID='1003' then 
		dbo.f_formattime(isnull(#ShiftProductionFromAutodataT2.CycleTime,0)+isnull(#ShiftProductionFromAutodataT2.LoadUnload,0),@timeformat)
		Else dbo.f_formattime(isnull(#ShiftProductionFromAutodataT2.CycleTime,0),@timeformat) END as frmtCycleTime,
		dbo.f_formattime(isnull(#ShiftProductionFromAutodataT2.LoadUnload,0),@timeformat) as frmtLoadUnload,
		case when #ShiftProductionFromAutodataT2.PlantID='1003' then 
		dbo.f_formattime(isnull(#ShiftProductionFromAutodataT2.AvgCycleTime,0)+isnull(#ShiftProductionFromAutodataT2.AvgLoadUnload,0),@timeformat)
		Else dbo.f_formattime(isnull(#ShiftProductionFromAutodataT2.AvgCycleTime,0),@timeformat) END as frmtAvgCycleTime,
		dbo.f_formattime(isnull(#ShiftProductionFromAutodataT2.AvgLoadUnload,0),@timeformat) as frmtAvgLoadUnload,
		isnull(Round(#ShiftProductionFromAutodataT2.OperationCount,2),0)as OperationCount,
		
		cyclefficiency =
		CASE
		   when ( isnull(#ShiftProductionFromAutodataT2.CycleTime,0) > 0 and
			  isnull(#ShiftProductionFromAutodataT2.AvgCycleTime,0) > 0
			) then ROUND((#ShiftProductionFromAutodataT2.CycleTime/#ShiftProductionFromAutodataT2.AvgCycleTime)*100,2)
		   else 0
		END,
		LoadUnloadefficiency =
		CASE
		   when ( isnull(#ShiftProductionFromAutodataT2.LoadUnload,0) > 0 and
			  isnull(#ShiftProductionFromAutodataT2.AvgLoadUnload,0) > 0
			) then ROUND((#ShiftProductionFromAutodataT2.LoadUnload/#ShiftProductionFromAutodataT2.AvgLoadUnload)*100,2)
		   else 0
		END,
		---mod 3
		---cast(cast(DateName(month,#ShiftProductionFromAutodataT1.Udate)as nvarchar(3))+'-'+cast(datepart(dd,#ShiftProductionFromAutodataT1.Udate)as nvarchar(2))+'-'+cast(datepart(yyyy,#ShiftProductionFromAutodataT1.Udate)as nvarchar(4))as nvarchar(20)) as Day,
		cast(cast(datepart(yyyy,#ShiftProductionFromAutodataT1.Udate)as nvarchar(4))+case when datalength(CAST(Month(#ShiftProductionFromAutodataT1.Udate)as nvarchar(2)))=2 then '0'+CAST(Month(#ShiftProductionFromAutodataT1.Udate)as nvarchar(2)) else CAST(Month(#ShiftProductionFromAutodataT1.Udate)as nvarchar(2)) end+cast(DateName(month,#ShiftProductionFromAutodataT1.Udate)as nvarchar(3))+'-'+case when datalength(CAST(Day(#ShiftProductionFromAutodataT1.Udate)as nvarchar(2)))=2 then '0'+CAST(Day(#ShiftProductionFromAutodataT1.Udate)as nvarchar(2)) else CAST(Day(#ShiftProductionFromAutodataT1.Udate)as nvarchar(2)) end+'-'+cast(datepart(yyyy,#ShiftProductionFromAutodataT1.Udate)as nvarchar(4))as nvarchar(20)) as Day,
		--mod 3
		#ShiftProductionFromAutodataT1.Ushift as shift,
		#ShiftProductionFromAutodataT2.TargetCount as Target,
		#ShiftwiseProductionForADay.shftstarttime, --ER0291 Added
		#ShiftwiseProductionForADay.shftndtime,  --ER0291 Added
		#ShiftwiseProductionForADay.Machine,   --ER0291 Added
		#ShiftwiseProductionForADay.shift   --ER0291 Added
	
	from   #ShiftProductionFromAutodataT1 LEFT OUTER JOIN #ShiftProductionFromAutodataT2 ON
		#ShiftProductionFromAutodataT1.MachineID = #ShiftProductionFromAutodataT2.MachineID and
		#ShiftProductionFromAutodataT1.UDate=#ShiftProductionFromAutodataT2.Sdate and
		#ShiftProductionFromAutodataT1.Ushift=#ShiftProductionFromAutodataT2.ShiftName
	
	----ER0291 Added From Here
	cross join #ShiftwiseProductionForADay
	
	where #ShiftProductionFromAutodataT1.MachineID = #ShiftwiseProductionForADay.Machine and
--ER0374 from here
--		cast(datepart(yyyy,#ShiftProductionFromAutodataT1.UDate)as nvarchar(4)) + '-' + cast(datepart(mm,#ShiftProductionFromAutodataT1.UDate)as nvarchar(2)) + '-'+  cast(datepart(dd,#ShiftProductionFromAutodataT1.UDate)as nvarchar(2)) =
--		cast(datepart(yyyy,#ShiftwiseProductionForADay.shftstarttime)as nvarchar(4)) + '-' + cast(datepart(mm,#ShiftwiseProductionForADay.shftstarttime)as nvarchar(2)) + '-'+  cast(datepart(dd,#ShiftwiseProductionForADay.shftstarttime)as nvarchar(2))
		cast(datepart(yyyy,#ShiftProductionFromAutodataT1.UstartShift)as nvarchar(4)) + '-' + cast(datepart(mm,#ShiftProductionFromAutodataT1.UstartShift)as nvarchar(2)) + '-'+  cast(datepart(dd,#ShiftProductionFromAutodataT1.UstartShift)as nvarchar(2)) =
		cast(datepart(yyyy,#ShiftwiseProductionForADay.shftstarttime)as nvarchar(4)) + '-' + cast(datepart(mm,#ShiftwiseProductionForADay.shftstarttime)as nvarchar(2)) + '-'+  cast(datepart(dd,#ShiftwiseProductionForADay.shftstarttime)as nvarchar(2))
--ER0374 till here
		-- and
		and #ShiftProductionFromAutodataT1.Ushift=#ShiftwiseProductionForADay.shift
	order by #shiftproductionfromautodataT1.Machineid,#ShiftProductionFromAutodataT1.Ushift,
	#ShiftwiseProductionForADay.shftstarttime,#ShiftwiseProductionForADay.shftndtime
	--ER0291 Added Till Here.
End
If @param = ''
Begin
	select  #ShiftProductionFromAutodataT1.MachineID,
		#ShiftProductionFromAutodataT1.GroupID,
	    #ShiftProductionFromAutodataT1.MachineDescription MachineDescription,
		#ShiftProductionFromAutodataT1.OperatorId,
		#ShiftProductionFromAutodataT1.ProductionEfficiency,
		#ShiftProductionFromAutodataT1.AvailabilityEfficiency,
		#ShiftProductionFromAutodataT1.OverallEfficiency,
		dbo.f_formattime(#ShiftProductionFromAutodataT1.DownTime, @timeformat) as frmtDownTime,
		--dbo.f_formattime(#ShiftProductionFromAutodataT1.UtilisedTime, @timeformat) as frmtDownTime, --ER0324 Commented
		dbo.f_formattime(#ShiftProductionFromAutodataT1.UtilisedTime, @timeformat) as frmtUtilisedTime, --ER0324 Added		
		isnull(#ShiftProductionFromAutodataT2.Component,'') as Component,
		isnull(#ShiftProductionFromAutodataT2.Operation,'') as Operation,
		dbo.f_formattime(isnull(#ShiftProductionFromAutodataT2.CycleTime,0),@timeformat) as frmtCycleTime,
		dbo.f_formattime(isnull(#ShiftProductionFromAutodataT2.LoadUnload,0),@timeformat) as frmtLoadUnload,
		dbo.f_formattime(isnull(#ShiftProductionFromAutodataT2.AvgCycleTime,0), @timeformat) as frmtAvgCycleTime,
		dbo.f_formattime(isnull(#ShiftProductionFromAutodataT2.AvgLoadUnload,0),@timeformat) as frmtAvgLoadUnload,

		isnull(Round(#ShiftProductionFromAutodataT2.OperationCount,2),0)as OperationCount, --NR0097 Added Round function
		
		cyclefficiency =
		CASE
		   when ( isnull(#ShiftProductionFromAutodataT2.CycleTime,0) > 0 and
			  isnull(#ShiftProductionFromAutodataT2.AvgCycleTime,0) > 0
			) then (#ShiftProductionFromAutodataT2.CycleTime/#ShiftProductionFromAutodataT2.AvgCycleTime)*100
		   else 0
		END,

		LoadUnloadefficiency =
		CASE
		   when ( isnull(#ShiftProductionFromAutodataT2.LoadUnload,0) > 0 and
			  isnull(#ShiftProductionFromAutodataT2.AvgLoadUnload,0) > 0
			) then (#ShiftProductionFromAutodataT2.LoadUnload/#ShiftProductionFromAutodataT2.AvgLoadUnload)*100
		   else 0
		END,
		---mod 3
		---cast(cast(DateName(month,#ShiftProductionFromAutodataT1.Udate)as nvarchar(3))+'-'+cast(datepart(dd,#ShiftProductionFromAutodataT1.Udate)as nvarchar(2))+'-'+cast(datepart(yyyy,#ShiftProductionFromAutodataT1.Udate)as nvarchar(4))as nvarchar(20)) as Day,
		cast(cast(datepart(yyyy,#ShiftProductionFromAutodataT1.Udate)as nvarchar(4))+case when datalength(CAST(Month(#ShiftProductionFromAutodataT1.Udate)as nvarchar(2)))=2 then '0'+CAST(Month(#ShiftProductionFromAutodataT1.Udate)as nvarchar(2)) else CAST(Month(#ShiftProductionFromAutodataT1.Udate)as nvarchar(2)) end+cast(DateName(month,#ShiftProductionFromAutodataT1.Udate)as nvarchar(3))+'-'+case when datalength(CAST(Day(#ShiftProductionFromAutodataT1.Udate)as nvarchar(2)))=2 then '0'+CAST(Day(#ShiftProductionFromAutodataT1.Udate)as nvarchar(2)) else CAST(Day(#ShiftProductionFromAutodataT1.Udate)as nvarchar(2)) end+'-'+cast(datepart(yyyy,#ShiftProductionFromAutodataT1.Udate)as nvarchar(4))as nvarchar(20)) as Day,
		--mod 3
		#ShiftProductionFromAutodataT1.Ushift as shift,
		#ShiftProductionFromAutodataT2.TargetCount as Target
	from   #ShiftProductionFromAutodataT1 
	LEFT OUTER JOIN #ShiftProductionFromAutodataT2 ON
		#ShiftProductionFromAutodataT1.MachineID = #ShiftProductionFromAutodataT2.MachineID and
		#ShiftProductionFromAutodataT1.UDate=#ShiftProductionFromAutodataT2.Sdate and
		#ShiftProductionFromAutodataT1.Ushift=#ShiftProductionFromAutodataT2.ShiftName
End

----ER0414 Added From Here
If @param = 'Shift'
Begin
	select #ShiftProductionFromAutodataT1.Ushift as shift,#ShiftProductionFromAutodataT1.MachineID,#ShiftProductionFromAutodataT1.GroupID,
	#ShiftProductionFromAutodataT1.MachineDescription MachineDescription,
		#ShiftProductionFromAutodataT1.OperatorId,#ShiftProductionFromAutodataT1.OperatorName,
		ISNULL(ROUND(#ShiftProductionFromAutodataT1.ProductionEfficiency,2),0) as ProductionEfficiency,
		ISNULL(ROUND(#ShiftProductionFromAutodataT1.AvailabilityEfficiency,2),0) as AvailabilityEfficiency,
		ISNULL(ROUND(#ShiftProductionFromAutodataT1.QualityEfficiency,2),0) as QualityEfficiency,
		--ISNULL(#ShiftProductionFromAutodataT1.RejCount,0) as RejCount,

		--round((isnull(#ShiftProductionFromAutodataT2.OperationCount,0)/nullif(#ShiftProductionFromAutodataT2.TargetCount,0)*100),2) as [Percent],


		ISNULL(ROUND(#ShiftProductionFromAutodataT1.OverallEfficiency,2),0) as OverallEfficiency,
		dbo.f_formattime(#ShiftProductionFromAutodataT1.DownTime, @timeformat) as frmtDownTime,
		dbo.f_formattime(#ShiftProductionFromAutodataT1.UtilisedTime, @timeformat) as frmtUtilisedTime, 
		isnull(#ShiftProductionFromAutodataT2.Component,'') as Component,
		isnull(#ShiftProductionFromAutodataT2.Operation,'') as Operation,
		case when #ShiftProductionFromAutodataT2.PlantID='1003' then 
		dbo.f_formattime(isnull(#ShiftProductionFromAutodataT2.CycleTime,0)+isnull(#ShiftProductionFromAutodataT2.LoadUnload,0),@timeformat)
		Else dbo.f_formattime(isnull(#ShiftProductionFromAutodataT2.CycleTime,0),@timeformat) END as frmtCycleTime,
		dbo.f_formattime(isnull(#ShiftProductionFromAutodataT2.LoadUnload,0),@timeformat) as frmtLoadUnload,
		------------dbo.f_formattime(isnull(#ShiftProductionFromAutodataT2.CycleTime,0),@timeformat) as frmtCycleTime,
		--case when #ShiftProductionFromAutodataT2.PlantID='1003' then 
		--ROUND(isnull(#ShiftProductionFromAutodataT2.CycleTime,0)+isnull(#ShiftProductionFromAutodataT2.LoadUnload,0),2)
		--Else ROUND(isnull(#ShiftProductionFromAutodataT2.CycleTime,0),2) END as frmtCycleTime,
		--ROUND(isnull(#ShiftProductionFromAutodataT2.LoadUnload,0),2) as frmtLoadUnload,
		-----------dbo.f_formattime(isnull(#ShiftProductionFromAutodataT2.AvgCycleTime,0), @timeformat) as frmtAvgCycleTime,
		--case when #ShiftProductionFromAutodataT2.PlantID='1003' then 
		--ROUND(isnull(#ShiftProductionFromAutodataT2.AvgCycleTime,0)+isnull(#ShiftProductionFromAutodataT2.AvgLoadUnload,0),2)
		--Else ROUND(isnull(#ShiftProductionFromAutodataT2.AvgCycleTime,0),2) END as frmtAvgCycleTime,
		--ROUND(isnull(#ShiftProductionFromAutodataT2.AvgLoadUnload,0),2) as frmtAvgLoadUnload,
		case when #ShiftProductionFromAutodataT2.PlantID='1003' then 
		dbo.f_formattime(isnull(#ShiftProductionFromAutodataT2.AvgCycleTime,0)+isnull(#ShiftProductionFromAutodataT2.AvgLoadUnload,0),@timeformat)
		Else dbo.f_formattime(isnull(#ShiftProductionFromAutodataT2.AvgCycleTime,0),@timeformat) END as frmtAvgCycleTime,
		dbo.f_formattime(isnull(#ShiftProductionFromAutodataT2.AvgLoadUnload,0),@timeformat) as frmtAvgLoadUnload,
		isnull(Round(#ShiftProductionFromAutodataT2.OperationCount,2),0)as OperationCount,
		--cyclefficiency =
		--CASE
		--   when ( isnull(#ShiftProductionFromAutodataT2.CycleTime,0) > 0 and
		--	  isnull(#ShiftProductionFromAutodataT2.AvgCycleTime,0) > 0
		--	) then (#ShiftProductionFromAutodataT2.CycleTime/#ShiftProductionFromAutodataT2.AvgCycleTime)*100
		--   else 0
		--END,
		--cyclefficiency =
		--CASE
		--   when ( isnull(#ShiftProductionFromAutodataT2.CycleTime,0) > 0 and
		--	  isnull(#ShiftProductionFromAutodataT2.AvgCycleTime,0) > 0
		--	) then ROUND(((#ShiftProductionFromAutodataT2.CycleTime+isnull(#ShiftProductionFromAutodataT2.LoadUnload,0))/(#ShiftProductionFromAutodataT2.AvgCycleTime+#ShiftProductionFromAutodataT2.AvgLoadUnload))*100,2)
		--   else 0
		--END,
		cyclefficiency =
		CASE
		   when ( isnull(#ShiftProductionFromAutodataT2.CycleTime,0) > 0 and
			  isnull(#ShiftProductionFromAutodataT2.AvgCycleTime,0) > 0
			) then (#ShiftProductionFromAutodataT2.CycleTime/#ShiftProductionFromAutodataT2.AvgCycleTime)*100
		   else 0
		END,
		LoadUnloadefficiency =
		CASE
		   when ( isnull(#ShiftProductionFromAutodataT2.LoadUnload,0) > 0 and
			  isnull(#ShiftProductionFromAutodataT2.AvgLoadUnload,0) > 0
			) then ROUND((#ShiftProductionFromAutodataT2.LoadUnload/#ShiftProductionFromAutodataT2.AvgLoadUnload)*100,2)
		   else 0
		END,
		 #ShiftProductionFromAutodataT1.Udate as Day,
		#ShiftProductionFromAutodataT2.TargetCount as Target
		--,#ShiftProductionFromAutodataT2.MachineDescription
	from   #ShiftProductionFromAutodataT1 LEFT OUTER JOIN #ShiftProductionFromAutodataT2 ON
		#ShiftProductionFromAutodataT1.MachineID = #ShiftProductionFromAutodataT2.MachineID and
		#ShiftProductionFromAutodataT1.GroupID=#ShiftProductionFromAutodataT2.GroupID AND
		#ShiftProductionFromAutodataT1.UDate=#ShiftProductionFromAutodataT2.Sdate and
		#ShiftProductionFromAutodataT1.Ushift=#ShiftProductionFromAutodataT2.ShiftName 
		where( #ShiftProductionFromAutodataT1.UtilisedTime >0 or #ShiftProductionFromAutodataT1.DownTime>0 or #ShiftProductionFromAutodataT2.OperationCount>0)
		--order by  #ShiftProductionFromAutodataT1.UShift,#ShiftProductionFromAutodataT1.UDate,#ShiftProductionFromAutodataT1.MachineID
		ORDER BY #ShiftProductionFromAutodataT1.Udate,#ShiftProductionFromAutodataT1.Ushift, #ShiftProductionFromAutodataT1.GroupID,#ShiftProductionFromAutodataT2.Operation
End

if @Param='Summary'
begin
SELECT t.Day, T.SHIFT,T.GROUPID,T.Operation,SUM(T.OperationCount) AS ActualProduction,ROUND(AVG(T.ProductionEfficiency),2) as AvgPE,ROUND(AVG(T.AvailabilityEfficiency),2) as AvgAE,
ROUND(avg(T.QualityEfficiency),2) as AvgQE,ROUND(AVG(T.OverallEfficiency),2) as AvgOEE FROM (
	select #ShiftProductionFromAutodataT1.Ushift as shift,#ShiftProductionFromAutodataT1.MachineID,#ShiftProductionFromAutodataT1.GroupID,
	#ShiftProductionFromAutodataT1.MachineDescription MachineDescription,
		#ShiftProductionFromAutodataT1.OperatorId,#ShiftProductionFromAutodataT1.OperatorName,
		ISNULL(ROUND(#ShiftProductionFromAutodataT1.ProductionEfficiency,2),0) as ProductionEfficiency,
		ISNULL(ROUND(#ShiftProductionFromAutodataT1.AvailabilityEfficiency,2),0) as AvailabilityEfficiency,
		ISNULL(ROUND(#ShiftProductionFromAutodataT1.QualityEfficiency,2),0) as QualityEfficiency,
		--ISNULL(#ShiftProductionFromAutodataT1.RejCount,0) as RejCount,

		--round((isnull(#ShiftProductionFromAutodataT2.OperationCount,0)/nullif(#ShiftProductionFromAutodataT2.TargetCount,0)*100),2) as [Percent],


		ISNULL(ROUND(#ShiftProductionFromAutodataT1.OverallEfficiency,2),0) as OverallEfficiency,
		dbo.f_formattime(#ShiftProductionFromAutodataT1.DownTime, @timeformat) as frmtDownTime,
		dbo.f_formattime(#ShiftProductionFromAutodataT1.UtilisedTime, @timeformat) as frmtUtilisedTime, 
		isnull(#ShiftProductionFromAutodataT2.Component,'') as Component,
		isnull(#ShiftProductionFromAutodataT2.Operation,'') as Operation,
		case when #ShiftProductionFromAutodataT2.PlantID='1003' then 
		dbo.f_formattime(isnull(#ShiftProductionFromAutodataT2.CycleTime,0)+isnull(#ShiftProductionFromAutodataT2.LoadUnload,0),@timeformat)
		Else dbo.f_formattime(isnull(#ShiftProductionFromAutodataT2.CycleTime,0),@timeformat) END as frmtCycleTime,
		dbo.f_formattime(isnull(#ShiftProductionFromAutodataT2.LoadUnload,0),@timeformat) as frmtLoadUnload,
		------------dbo.f_formattime(isnull(#ShiftProductionFromAutodataT2.CycleTime,0),@timeformat) as frmtCycleTime,
		--case when #ShiftProductionFromAutodataT2.PlantID='1003' then 
		--ROUND(isnull(#ShiftProductionFromAutodataT2.CycleTime,0)+isnull(#ShiftProductionFromAutodataT2.LoadUnload,0),2)
		--Else ROUND(isnull(#ShiftProductionFromAutodataT2.CycleTime,0),2) END as frmtCycleTime,
		--ROUND(isnull(#ShiftProductionFromAutodataT2.LoadUnload,0),2) as frmtLoadUnload,
		-----------dbo.f_formattime(isnull(#ShiftProductionFromAutodataT2.AvgCycleTime,0), @timeformat) as frmtAvgCycleTime,
		--case when #ShiftProductionFromAutodataT2.PlantID='1003' then 
		--ROUND(isnull(#ShiftProductionFromAutodataT2.AvgCycleTime,0)+isnull(#ShiftProductionFromAutodataT2.AvgLoadUnload,0),2)
		--Else ROUND(isnull(#ShiftProductionFromAutodataT2.AvgCycleTime,0),2) END as frmtAvgCycleTime,
		--ROUND(isnull(#ShiftProductionFromAutodataT2.AvgLoadUnload,0),2) as frmtAvgLoadUnload,
		case when #ShiftProductionFromAutodataT2.PlantID='1003' then 
		dbo.f_formattime(isnull(#ShiftProductionFromAutodataT2.AvgCycleTime,0)+isnull(#ShiftProductionFromAutodataT2.AvgLoadUnload,0),@timeformat)
		Else dbo.f_formattime(isnull(#ShiftProductionFromAutodataT2.AvgCycleTime,0),@timeformat) END as frmtAvgCycleTime,
		dbo.f_formattime(isnull(#ShiftProductionFromAutodataT2.AvgLoadUnload,0),@timeformat) as frmtAvgLoadUnload,
		isnull(Round(#ShiftProductionFromAutodataT2.OperationCount,2),0)as OperationCount,
		--cyclefficiency =
		--CASE
		--   when ( isnull(#ShiftProductionFromAutodataT2.CycleTime,0) > 0 and
		--	  isnull(#ShiftProductionFromAutodataT2.AvgCycleTime,0) > 0
		--	) then (#ShiftProductionFromAutodataT2.CycleTime/#ShiftProductionFromAutodataT2.AvgCycleTime)*100
		--   else 0
		--END,
		--cyclefficiency =
		--CASE
		--   when ( isnull(#ShiftProductionFromAutodataT2.CycleTime,0) > 0 and
		--	  isnull(#ShiftProductionFromAutodataT2.AvgCycleTime,0) > 0
		--	) then ROUND(((#ShiftProductionFromAutodataT2.CycleTime+isnull(#ShiftProductionFromAutodataT2.LoadUnload,0))/(#ShiftProductionFromAutodataT2.AvgCycleTime+#ShiftProductionFromAutodataT2.AvgLoadUnload))*100,2)
		--   else 0
		--END,
		cyclefficiency =
		CASE
		   when ( isnull(#ShiftProductionFromAutodataT2.CycleTime,0) > 0 and
			  isnull(#ShiftProductionFromAutodataT2.AvgCycleTime,0) > 0
			) then (#ShiftProductionFromAutodataT2.CycleTime/#ShiftProductionFromAutodataT2.AvgCycleTime)*100
		   else 0
		END,
		LoadUnloadefficiency =
		CASE
		   when ( isnull(#ShiftProductionFromAutodataT2.LoadUnload,0) > 0 and
			  isnull(#ShiftProductionFromAutodataT2.AvgLoadUnload,0) > 0
			) then ROUND((#ShiftProductionFromAutodataT2.LoadUnload/#ShiftProductionFromAutodataT2.AvgLoadUnload)*100,2)
		   else 0
		END,
		 #ShiftProductionFromAutodataT1.Udate as Day,
		#ShiftProductionFromAutodataT2.TargetCount as Target
		--,#ShiftProductionFromAutodataT2.MachineDescription
	from   #ShiftProductionFromAutodataT1 LEFT OUTER JOIN #ShiftProductionFromAutodataT2 ON
		#ShiftProductionFromAutodataT1.MachineID = #ShiftProductionFromAutodataT2.MachineID and
		#ShiftProductionFromAutodataT1.GroupID=#ShiftProductionFromAutodataT2.GroupID AND
		#ShiftProductionFromAutodataT1.UDate=#ShiftProductionFromAutodataT2.Sdate and
		#ShiftProductionFromAutodataT1.Ushift=#ShiftProductionFromAutodataT2.ShiftName 
		where( #ShiftProductionFromAutodataT1.UtilisedTime >0 or #ShiftProductionFromAutodataT1.DownTime>0 or #ShiftProductionFromAutodataT2.OperationCount>0)
		)T
		group by t.Day, t.shift,t.GroupID,t.Operation
		order by t.Day, t.shift,t.GroupID,t.Operation
end

IF @Param='FinalSummary'
begin
SELECT t1.day, t1.shift,t1.GroupID,t1.Operation,SUM(T1.Target) as [Plan],sum(T1.OperationCount) AS Actual,round( (sum(T1.OperationCount)/SUM(NULLIF(T1.Target,0)))*100,2) AS [Percent],ROUND(AVG(T1.OverallEfficiency),2) as OverallEfficiency FROM
	(select  #ShiftProductionFromAutodataT1.MachineID,#ShiftProductionFromAutodataT1.GroupID,
	#ShiftProductionFromAutodataT1.MachineDescription MachineDescription,
		#ShiftProductionFromAutodataT1.OperatorId,#ShiftProductionFromAutodataT1.OperatorName,
		ISNULL(ROUND(#ShiftProductionFromAutodataT1.ProductionEfficiency,2),0) as ProductionEfficiency,
		ISNULL(ROUND(#ShiftProductionFromAutodataT1.AvailabilityEfficiency,2),0) as AvailabilityEfficiency,
		ISNULL(ROUND(#ShiftProductionFromAutodataT1.QualityEfficiency,2),0) as QualityEfficiency,
		--ISNULL(#ShiftProductionFromAutodataT1.RejCount,0) as RejCount,
		--round((isnull(#ShiftProductionFromAutodataT2.OperationCount,0)/nullif(#ShiftProductionFromAutodataT2.TargetCount,0)*100),2) as [Percent],

		ISNULL(ROUND(#ShiftProductionFromAutodataT1.OverallEfficiency,2),0) as OverallEfficiency,
		dbo.f_formattime(#ShiftProductionFromAutodataT1.DownTime, @timeformat) as frmtDownTime,
		dbo.f_formattime(#ShiftProductionFromAutodataT1.UtilisedTime, @timeformat) as frmtUtilisedTime, 
		isnull(#ShiftProductionFromAutodataT2.Component,'') as Component,
		isnull(#ShiftProductionFromAutodataT2.Operation,'') as Operation,
		case when #ShiftProductionFromAutodataT2.PlantID='1003' then 
		dbo.f_formattime(isnull(#ShiftProductionFromAutodataT2.CycleTime,0)+isnull(#ShiftProductionFromAutodataT2.LoadUnload,0),@timeformat)
		Else dbo.f_formattime(isnull(#ShiftProductionFromAutodataT2.CycleTime,0),@timeformat) END as frmtCycleTime,
		dbo.f_formattime(isnull(#ShiftProductionFromAutodataT2.LoadUnload,0),@timeformat) as frmtLoadUnload,
		------------dbo.f_formattime(isnull(#ShiftProductionFromAutodataT2.CycleTime,0),@timeformat) as frmtCycleTime,
		--case when #ShiftProductionFromAutodataT2.PlantID='1003' then 
		--ROUND(isnull(#ShiftProductionFromAutodataT2.CycleTime,0)+isnull(#ShiftProductionFromAutodataT2.LoadUnload,0),2)
		--Else ROUND(isnull(#ShiftProductionFromAutodataT2.CycleTime,0),2) END as frmtCycleTime,
		--ROUND(isnull(#ShiftProductionFromAutodataT2.LoadUnload,0),2) as frmtLoadUnload,
		-----------dbo.f_formattime(isnull(#ShiftProductionFromAutodataT2.AvgCycleTime,0), @timeformat) as frmtAvgCycleTime,
		--case when #ShiftProductionFromAutodataT2.PlantID='1003' then 
		--ROUND(isnull(#ShiftProductionFromAutodataT2.AvgCycleTime,0)+isnull(#ShiftProductionFromAutodataT2.AvgLoadUnload,0),2)
		--Else ROUND(isnull(#ShiftProductionFromAutodataT2.AvgCycleTime,0),2) END as frmtAvgCycleTime,
		--ROUND(isnull(#ShiftProductionFromAutodataT2.AvgLoadUnload,0),2) as frmtAvgLoadUnload,
		case when #ShiftProductionFromAutodataT2.PlantID='1003' then 
		dbo.f_formattime(isnull(#ShiftProductionFromAutodataT2.AvgCycleTime,0)+isnull(#ShiftProductionFromAutodataT2.AvgLoadUnload,0),@timeformat)
		Else dbo.f_formattime(isnull(#ShiftProductionFromAutodataT2.AvgCycleTime,0),@timeformat) END as frmtAvgCycleTime,
		dbo.f_formattime(isnull(#ShiftProductionFromAutodataT2.AvgLoadUnload,0),@timeformat) as frmtAvgLoadUnload,
		isnull(Round(#ShiftProductionFromAutodataT2.OperationCount,2),0)as OperationCount,
		--cyclefficiency =
		--CASE
		--   when ( isnull(#ShiftProductionFromAutodataT2.CycleTime,0) > 0 and
		--	  isnull(#ShiftProductionFromAutodataT2.AvgCycleTime,0) > 0
		--	) then (#ShiftProductionFromAutodataT2.CycleTime/#ShiftProductionFromAutodataT2.AvgCycleTime)*100
		--   else 0
		--END,
		--cyclefficiency =
		--CASE
		--   when ( isnull(#ShiftProductionFromAutodataT2.CycleTime,0) > 0 and
		--	  isnull(#ShiftProductionFromAutodataT2.AvgCycleTime,0) > 0
		--	) then ROUND(((#ShiftProductionFromAutodataT2.CycleTime+isnull(#ShiftProductionFromAutodataT2.LoadUnload,0))/(#ShiftProductionFromAutodataT2.AvgCycleTime+#ShiftProductionFromAutodataT2.AvgLoadUnload))*100,2)
		--   else 0
		--END,
		cyclefficiency =
		CASE
		   when ( isnull(#ShiftProductionFromAutodataT2.CycleTime,0) > 0 and
			  isnull(#ShiftProductionFromAutodataT2.AvgCycleTime,0) > 0
			) then (#ShiftProductionFromAutodataT2.CycleTime/#ShiftProductionFromAutodataT2.AvgCycleTime)*100
		   else 0
		END,
		LoadUnloadefficiency =
		CASE
		   when ( isnull(#ShiftProductionFromAutodataT2.LoadUnload,0) > 0 and
			  isnull(#ShiftProductionFromAutodataT2.AvgLoadUnload,0) > 0
			) then ROUND((#ShiftProductionFromAutodataT2.LoadUnload/#ShiftProductionFromAutodataT2.AvgLoadUnload)*100,2)
		   else 0
		END,
		 #ShiftProductionFromAutodataT1.Udate as Day,
		#ShiftProductionFromAutodataT1.Ushift as shift,
		#ShiftProductionFromAutodataT2.TargetCount as Target
		--,#ShiftProductionFromAutodataT2.MachineDescription
	from   #ShiftProductionFromAutodataT1 LEFT OUTER JOIN #ShiftProductionFromAutodataT2 ON
		#ShiftProductionFromAutodataT1.MachineID = #ShiftProductionFromAutodataT2.MachineID and
		#ShiftProductionFromAutodataT1.GroupID=#ShiftProductionFromAutodataT2.GroupID AND
		#ShiftProductionFromAutodataT1.UDate=#ShiftProductionFromAutodataT2.Sdate and
		#ShiftProductionFromAutodataT1.Ushift=#ShiftProductionFromAutodataT2.ShiftName 
		where( #ShiftProductionFromAutodataT1.UtilisedTime >0 or #ShiftProductionFromAutodataT1.DownTime>0 or #ShiftProductionFromAutodataT2.OperationCount>0)
		--order by  #ShiftProductionFromAutodataT1.UShift,#ShiftProductionFromAutodataT1.UDate,#ShiftProductionFromAutodataT1.MachineID
		--ORDER BY #ShiftProductionFromAutodataT1.GroupID,#ShiftProductionFromAutodataT1.MachineID,#ShiftProductionFromAutodataT2.Operation
		)T1  
		GROUP BY t1.day, t1.shift, T1.GroupID,T1.Operation
		order by t1.day, t1.shift, T1.GroupID,T1.Operation
end


--IF @Param='Summary'
--Begin
--select ROUND(AVG(T1.ProductionEfficiency),2) as ProductionEfficiency,
--ROUND(AVG(T1.AvailabilityEfficiency),2) as AvailabilityEfficiency,
--ROUND(avg(T1.QualityEfficiency),2) as QualityEfficiency,
--ROUND(AVG(T1.OverallEfficiency),2) as OverallEfficiency,
--dbo.f_formattime(sum(T1.DownTime), @timeformat) as TotalDownTime,
--dbo.f_formattime(sum(T1.UtilisedTime), @timeformat) as frmtUtilisedTime
--from (Select distinct MachineID,Udate,Ushift,UstartShift,UEndShift,isnull(round(ProductionEfficiency,2),0) as ProductionEfficiency,isnull(round(QualityEfficiency,2),0) as QualityEfficiency,isnull(round(OverallEfficiency,2),0) as OverallEfficiency,DownTime,UtilisedTime,isnull(round(AvailabilityEfficiency,2),0)AS AvailabilityEfficiency  from #ShiftProductionFromAutodataT1
--where UtilisedTime>0 or downtime>0)T1

--END



If @param = 'Shift_UT_DT'
Begin
	select  #ShiftProductionFromAutodataT1.MachineID,
		#ShiftProductionFromAutodataT1.MachineDescription MachineDescription,
		max(#ShiftProductionFromAutodataT1.ProductionEfficiency) as PE ,
		max(#ShiftProductionFromAutodataT1.AvailabilityEfficiency) as AE,
		max(#ShiftProductionFromAutodataT1.OverallEfficiency) as OEE,
		dbo.f_formattime(max(#ShiftProductionFromAutodataT1.DownTime), @timeformat) as frmtDownTime,
		dbo.f_formattime(max(#ShiftProductionFromAutodataT1.UtilisedTime), @timeformat) as frmtUtilisedTime,
		isnull(Round(SUM(#ShiftProductionFromAutodataT2.OperationCount),2),0) as OperationCount, --NR0097 Added Round Function
		
		#ShiftProductionFromAutodataT1.Udate,
		---cast(cast(datepart(yyyy,#ShiftProductionFromAutodataT1.Udate)as nvarchar(4))+case when datalength(CAST(Month(#ShiftProductionFromAutodataT1.Udate)as nvarchar(2)))=2 then '0'+CAST(Month(#ShiftProductionFromAutodataT1.Udate)as nvarchar(2)) else CAST(Month(#ShiftProductionFromAutodataT1.Udate)as nvarchar(2)) end+cast(DateName(month,#ShiftProductionFromAutodataT1.Udate)as nvarchar(3))+'-'+case when datalength(CAST(Day(#ShiftProductionFromAutodataT1.Udate)as nvarchar(2)))=2 then '0'+CAST(Day(#ShiftProductionFromAutodataT1.Udate)as nvarchar(2)) else CAST(Day(#ShiftProductionFromAutodataT1.Udate)as nvarchar(2)) end+'-'+cast(datepart(yyyy,#ShiftProductionFromAutodataT1.Udate)as nvarchar(4))as nvarchar(20)) as Day,
		#ShiftProductionFromAutodataT1.Ushift as shift,
		case
		when max(#ShiftProductionFromAutodataT1.OverallEfficiency)>=max(MC.OEGreen) then 'Green'
		when max(#ShiftProductionFromAutodataT1.OverallEfficiency)< max(MC.OEGreen) and max(#ShiftProductionFromAutodataT1.OverallEfficiency)> max(MC.OERED) then 'Yellow'
		when max(#ShiftProductionFromAutodataT1.OverallEfficiency)<=max(MC.OERED) then 'RED'
		else 'RED' end OECOLOR,UstartShift,
	UEndShift
		--max(#ShiftProductionFromAutodataT2.TargetCount) as Target
	from   #ShiftProductionFromAutodataT1
	
LEFT OUTER JOIN #ShiftProductionFromAutodataT2 ON
		#ShiftProductionFromAutodataT1.MachineID = #ShiftProductionFromAutodataT2.MachineID and
		#ShiftProductionFromAutodataT1.UDate=#ShiftProductionFromAutodataT2.Sdate and
		#ShiftProductionFromAutodataT1.Ushift=#ShiftProductionFromAutodataT2.ShiftName
LEFT OUTER JOIN Machineinformation Mc ON MC.Machineid=#ShiftProductionFromAutodataT1.MachineID
group by #ShiftProductionFromAutodataT1.MachineID,#ShiftProductionFromAutodataT1.MachineDescription,#ShiftProductionFromAutodataT1.Udate,
		#ShiftProductionFromAutodataT1.Ushift,UstartShift,
	UEndShift
End



--ER0319 till here
 Print  '----END------'
 print getdate() 
END
