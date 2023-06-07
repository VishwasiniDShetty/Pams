/****** Object:  Procedure [dbo].[s_GetComponentProductionReportFromAutoData]    Committed by VersionSQL https://www.versionsql.com ******/

/*************************   History   ************************************************************************************
By Sangeeta Kallur On 16-June-2006                                                                                     *
For Component Centric Cockpits.
Calcualtions at component level
Changed By Sangeeta Kallur on 05-July-2006                                                                             *
Changed Utilised Time Caln to support Down Within Production Cycle.                                                    *
Changed By SSK on 11-July-2006 :- Supporting SubOperations Concept at CO Level.                                        *
Change in  ProdCount, Min,Max,Avg(Cycle Time , LoadUnload Time),Speed Ration,Load Ration Caln.
Changed By Mrudula to include pallette count                                                                           *
Procedure Changed By Sangeeta Kallur on 23-FEB-2007 ::For MultiSpindle type of machines [MAINI Req].
													  		*
Procedure Changed By Karthigeyan G on 25-Jul-2007 :DR0016:For Calculation of AvgLoadUnLoad and LoadRation
	by omiting the records whose LoadUnLoad is less than the minimum LoadUnload(From ShopDefaults)			*	
ER0181 By Karthik G on 29-Sep-2009. Modify all the procedures accordingly. Qualify machine wherever we are making use of component and opeartion no.
ER0182 By Karthik G on 29-Sep-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
DR0213 By Karthik G on 29-Sep-2009. To avoid divide by zero error use only partscount > 0.
ER0210 By Karthik G on 05-Feb-2010. Introduce PDT on 5150. 1) Handle PDT at Machine Level.
			2) Handle interaction between PDT and Mangement Loss. Also handle interaction InCycleDown And PDT.
			3) Improve the performance.
			4) Handle intearction between ICD and PDT for type 1 production record for the selected time period.
Note:pdt not applied for AvgLoadUnload,LoadRation
ER0229 - Swathi ks - 10/May/2010 :: In ComponentOperationPricing table operationno from smallint to int.
DR0260 - SyedArifM - 29/Sep/2010 :: SmartManager - Production Report-Componentwise .Converting SpeedRatio and LoadRatio from TimeFormat to Float.
DR0267 - Karthikr - 09/Feb/2011 :: To Add Default Constraint To ManagementLoss and Downtime Columns in Temp Table.
DR0276 - SwathiKS - 26/Apr/2011 ::To Handle PE Mismatch with Cockpit While calculating PE Taken Machiningtime instead of Cycletime of COP Table.
				  SM -> Standard -> Production Report - Componentwise , ReportName -> SM_ProductionReportComponentwise.rpt
DR0285 - SwathiKS - 21/Jun/2011 :: To Calculate PE using (StdCycleTime + StdLoadUnload)instead of StdCycleTime .
NR0097 - SwathiKS - 21/Jan/2014 :: Since we are splitting Production and Down Cycle across shifts while showing partscount we have to consider decimal values instead whole Numbers.
DR0339 - SwathiKS - 25/Feb/2014 :: While handling ICD-PDT Interaction for Type-1,we have to pick cycles which has ProductionStart=ICDStart and ProductionEnd=ICDEnd.

**************************************************************************************************************************/
--s_GetComponentProductionReportFromAutoData '2022-06-01 06:00:00 AM','2022-06-02 06:00:00 AM','',''
CREATE PROCEDURE [dbo].[s_GetComponentProductionReportFromAutoData]
	@StartTime as DateTime ,
	@EndTime as DateTime,
	@ComponentID AS NvarChar(50)='',
	@OperationNo AS NvarChar(50)=''
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @StrSql nvarchar(4000)
DECLARE @TimeFormat NVarChar(30)
DECLARE @StrCompOpn AS NvarChar(255)
DECLARE @StrOpn AS NvarChar(255)
SELECT @StrSql=''
SELECT @StrCompOpn=''
SELECT @StrOpn=''


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


If ISNULL(@ComponentID,'')<>''
BEGIN
	SELECT @StrCompOpn=' AND C.ComponentID=N'''+ @ComponentID +''''
END
If ISNULL(@OperationNo,'')<>''
BEGIN
	SELECT @StrOpn=' AND O.OperationNo=N'''+ Convert(NVarChar,@OperationNo) +''' '
END
SELECT @TimeFormat ='ss'
SELECT @TimeFormat = isnull((SELECT ValueInText From CockPitDefaults Where Parameter='TimeFormat'),'ss')
if (@TimeFormat <>'hh:mm:ss' and @TimeFormat <>'hh' and @TimeFormat <>'mm'and @TimeFormat <>'ss')
BEGIN
SELECT @TimeFormat = 'ss'
END
CREATE TABLE #ProductionTime(
			  PMachineID  nvarchar(50),--ER0181 By Karthik G on 29-Sep-2009.
			  PMachineInterface nvarchar(50),--ER0210
			  PmachineDescription nvarchar(150),
			  PComponentID  nvarchar(50),
			  PComponentInterface nvarchar(50),
			  shiftid nvarchar(50),
			  RejCount float default 0,
			  --POperationNo  SmallInt,--ER0229 - Swathi ks - 10/May/2010
			  POperationNo  Int,
			  POperationInterface nvarchar(50),
			  Price 	Float,
			  UtilisedTime  Float,
			  ProdCount     Float,
			  CNprodcount   Float,
			  DownTime      Float default (0),
			  ManagementLoss Float default (0),
			  StdCycleTime  Float,
			  AvgCycleTime  Float,
			  MinCycleTime  Float,
			  MaxCycleTime  Float,
			  SpeedRation   Float(2),
			  StdLoadUnload Float,
			  AvgLoadUnload Float,
			  MinLoadUnload Float,
			  MaxLoadUnload Float,
			  LoadRation    Float(2),
			  AvailabilityEfficiency Float,
			  ProductionEfficiency   Float,
			  QualityEfficiency float,
			  OverAllEfficiency      Float,
			  TurnOver               Float
			  ---mod 4 Added MLDown to store genuine downs which is contained in Management loss
			  ,MLDown float
			  ---mod 4
			 )
--ER0210
--CREATE TABLE #DownTime (
--			PMachineID  nvarchar(50) ,--ER0181 By Karthik G on 29-Sep-2009.
--			PComponentID  nvarchar(50) ,
--			POperationNo  SmallInt,
--			DownTime      Float,
--			ManagementLoss Float
--			)
--ER0210
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
	)
--ER0210(PDT)
CREATE TABLE #PLD
(
	MachineID nvarchar(50),
	MachineInterface nvarchar(50),
	ComponentID Nvarchar(50),
	ComponentInterface nvarchar(50),
	OperationNo Int,
	OperationInterface nvarchar(50),
	pPlannedDT float Default 0,
	dPlannedDT float Default 0,
	MPlannedDT float Default 0,
	IPlannedDT float Default 0,
	DownID nvarchar(50)
)
Create table #PlannedDownTimes
(
	MachineID nvarchar(50),
	MachineInterface nvarchar(50),
	StartTime DateTime,
	EndTime DateTime
)

CREATE TABLE #ShiftDefn
(
	ShiftDate datetime,		
	Shiftname nvarchar(20),
	ShftSTtime datetime,
	ShftEndTime datetime	
)

create table #shift
(
	
	ShiftDate nvarchar(50), --DR0333
	shiftname nvarchar(50),
	Shiftstart datetime,
	Shiftend datetime,
	shiftid int
)

declare @startdate as datetime
declare @enddate as datetime
declare @startdatetime nvarchar(20)
select @startdate=dbo.f_GetLogicalDay(@StartTime,'start')
select @enddate=dbo.f_GetLogicalDay(@EndTime,'end')


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

Insert into #shift (ShiftDate,shiftname,Shiftstart,Shiftend)
select convert(nvarchar(10),ShiftDate,126),shiftname,ShftSTtime,ShftEndTime from #ShiftDefn --where ShftSTtime>=@StartTime and ShftEndTime<=@endtime 


Update #shift Set shiftid = isnull(#shift.Shiftid,0) + isnull(T1.shiftid,0) from
(Select SD.shiftid ,SD.shiftname from shiftdetails SD
inner join #shift S on SD.shiftname=S.shiftname where
running=1 )T1 inner join #shift on  T1.shiftname=#shift.shiftname


/* Planned Down times for the given time period */
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
SET @strSql =  @strSql + ' ORDER BY Machine,StartTime'
EXEC(@strSql)
--ER0210(PDT)
/*
BEGIN PRODUCTION TIME CALCULATIONS
*/
--ER0181 By Karthik G on 29-Sep-2009.
	--SELECT @StrSql='INSERT INTO #ProductionTime(pComponentID,POperationNo, Price,ProdCount,CNprodcount, '
	SELECT @StrSql='INSERT INTO #ProductionTime(PMachineID,PMachineInterface,PmachineDescription,pComponentID,PComponentInterface,POperationNo,POperationInterface,Price,ProdCount,CNprodcount, '
--ER0181 By Karthik G on 29-Sep-2009.
	SELECT @StrSql=@StrSql+'StdCycleTime,AvgCycleTime,MinCycleTime,MaxCycleTime,SpeedRation,StdLoadUnload, '
	SELECT @StrSql=@StrSql+'AvgLoadUnload,MinLoadUnload,MaxLoadUnload,LoadRation)'
--ER0181 By Karthik G on 29-Sep-2009.
	--SELECT @StrSql=@StrSql+'SELECT C.ComponentID,O.OperationNo ,Max(O.Price),'
	SELECT @StrSql=@StrSql+'SELECT M.MachineID,M.InterfaceID,M.Description,C.ComponentID,C.interfaceID,O.OperationNo,O.interfaceid,Max(O.Price),'
--ER0181 By Karthik G on 29-Sep-2009.
	--SELECT @StrSql=@StrSql+'CAST(CEILING(CAST(sum(A.partscount) AS Float )/ISNULL(O.SubOperations,1))AS INTEGER)AS ProdCount ,' --NR0097
	SELECT @StrSql=@StrSql+'CAST((CAST(sum(A.partscount) AS Float )/ISNULL(O.SubOperations,1))AS FLOAT)AS ProdCount ,' --NR0097
	--SELECT @StrSql=@StrSql+'CAST(CEILING(CAST(sum(A.partscount) AS Float )/ISNULL(O.SubOperations,1))AS INTEGER)AS CNprodcount ,' --NR0097
	SELECT @StrSql=@StrSql+'CAST((CAST(sum(A.partscount) AS Float )/ISNULL(O.SubOperations,1))AS FLOAT)AS CNprodcount ,' --NR0097
	--SELECT @StrSql=@StrSql+'O.MachiningTime  AS StdCycleTime,'  ---DR0276
	--SELECT @StrSql=@StrSql+'O.cycleTime  AS StdCycleTime,'  ---DR0276 {--DR0285 Commented}
	SELECT @StrSql=@StrSql+'O.MachiningTime  AS StdCycleTime,' --DR0285
	--SELECT @StrSql=@StrSql+'AVG(A.Cycletime/A.partscount)* ISNULL(O.SubOperations,1) AS AvgCycleTime,'
	SELECT @StrSql=@StrSql+'(SUM(A.Cycletime)/SUM(A.partscount))* ISNULL(O.SubOperations,1) AS AvgCycleTime,'
	SELECT @StrSql=@StrSql+'Min(A.Cycletime/A.partscount)* ISNULL(O.SubOperations,1) AS MinCycleTime,'
	SELECT @StrSql=@StrSql+'Max(A.Cycletime/A.partscount)* ISNULL(O.SubOperations,1) AS MaxCycleTime,'
	SELECT @StrSql=@StrSql+'CASE WHEN (AVG(A.Cycletime/A.partscount)*ISNULL(O.SubOperations,1))>0 THEN '
	SELECT @StrSql=@StrSql+'O.MachiningTime /(AVG(A.Cycletime/A.partscount)*ISNULL(O.SubOperations,1)) ELSE 0 END AS SpeedRation,'
	SELECT @StrSql=@StrSql+'(O.CycleTime - O.MachiningTime) AS StdLoadUnload,0,'
--	SELECT @StrSql=@StrSql+'AVG(A.loadunload/A.partscount)* ISNULL(O.SubOperations,1) AS AvgLoadUnload,' --Karthi:DR0016
	SELECT @StrSql=@StrSql+'Min(A.loadunload/A.partscount)* ISNULL(O.SubOperations,1) AS MinLoadUnload,'
	SELECT @StrSql=@StrSql+'Max(A.loadunload/A.partscount)* ISNULL(O.SubOperations,1) AS MaxLoadUnload,0'
--	SELECT @StrSql=@StrSql+'CASE WHEN (AVG(A.loadunload/A.partscount)* ISNULL(O.SubOperations,1))>0 THEN '
--	SELECT @StrSql=@StrSql+'(O.CycleTime - O.MachiningTime)/(AVG(A.loadunload/A.partscount)* ISNULL(O.SubOperations,1))ELSE 0 END AS LoadRation '--Karthi:DR0016
--ER0181 By Karthik G on 29-Sep-2009
	--SELECT @StrSql=@StrSql+'FROM AutoData A Inner Join  ComponentInformation C ON A.Comp=C.InterfaceID '
	--SELECT @StrSql=@StrSql+'Inner Join ComponentOperationPricing O ON A.Opn=O.InterfaceID AND C.ComponentID=O.ComponentID '
	SELECT @StrSql=@StrSql+' FROM #T_autodata A Inner Join MachineInformation M ON A.mc=M.InterfaceID Inner Join  ComponentInformation C ON A.Comp=C.InterfaceID '
	SELECT @StrSql=@StrSql+' Inner Join ComponentOperationPricing O ON A.Opn=O.InterfaceID AND C.ComponentID=O.ComponentID AND M.MachineID=O.MachineID '
--ER0181 By Karthik G on 29-Sep-2009
	SELECT @StrSql=@StrSql+' WHERE DataType=1 AND  Ndtime<='''+Convert(NvarChar(20),@EndTime,120)+''' AND Ndtime>'''+Convert(NvarChar(20),@StartTime,120)+''' '
--DR0213 By Karthik G on 29-Sep-2009
	SELECT @StrSql=@StrSql+' and A.PartsCount > 0 '
--DR0213 By Karthik G on 29-Sep-2009
	SELECT @StrSql=@StrSql+@StrCompOpn+@StrOpn
	SELECT @StrSql=@StrSql+' Group By M.MachineID,M.InterfaceID,M.Description,C.ComponentID,C.interfaceID,O.OperationNo,O.interfaceid,O.MachiningTime,O.CycleTime,O.SubOperations '
	SELECT @StrSql=@StrSql+' Order By C.ComponentID,O.OperationNo,M.MachineID'
	EXEC(@StrSql)
	--Karthi : DR0016 : Changes start here
	SELECT @StrSql =''
	SELECT @StrSql ='Update #productiontime set AvgLoadUnload = ISNULL(T1.AvgLoadUnload,0),LoadRation = ISNULL(T1.LoadRation,0)'
	SELECT @StrSql=@StrSql + 'from ('
--ER0181 By Karthik G on 29-Sep-2009
	--SELECT @StrSql=@StrSql + 'SELECT C.ComponentID,O.OperationNo ,'
	SELECT @StrSql=@StrSql + 'SELECT M.MachineID,C.ComponentID,O.OperationNo ,'
--ER0181 By Karthik G on 29-Sep-2009
	--SELECT @StrSql=@StrSql + 'AVG(A.loadunload/A.partscount)*ISNULL(O.SubOperations,1) AS AvgLoadUnload , '
	SELECT @StrSql=@StrSql + ' (SUM(A.loadunload)/SUM(A.partscount))*ISNULL(O.SubOperations,1) AS AvgLoadUnload , '
	SELECT @StrSql=@StrSql + ' CASE WHEN (AVG(A.loadunload/A.partscount)* ISNULL(O.SubOperations,1))>0 '
	SELECT @StrSql=@StrSql + 'THEN (O.CycleTime - O.MachiningTime)/(AVG(A.loadunload/A.partscount)* ISNULL(O.SubOperations,1)) '
	SELECT @StrSql=@StrSql + 'ELSE 0 END AS LoadRation '
--ER0181 By Karthik G on 29-Sep-2009
	--SELECT @StrSql=@StrSql + 'FROM #T_autodata  A Inner Join  ComponentInformation C ON A.Comp=C.InterfaceID Inner Join ComponentOperationPricing O ON A.Opn=O.InterfaceID AND C.ComponentID=O.ComponentID '
	SELECT @StrSql=@StrSql + ' FROM #T_autodata  A Inner join MachineInformation M ON A.mc=M.InterfaceID Inner Join  ComponentInformation C ON A.Comp=C.InterfaceID Inner Join ComponentOperationPricing O ON A.Opn=O.InterfaceID AND C.ComponentID=O.ComponentID and O.MachineID = M.MachineID '
--ER0181 By Karthik G on 29-Sep-2009
--DR0213 By Karthik G on 29-Sep-2009
--SELECT @StrSql=@StrSql + 'WHERE DataType=1 AND A.loadunload >= isnull((SELECT top 1 VALUEININT FROM SHOPDEFAULTS where parameter = ''minluforlr''),0)'
	--SELECT @StrSql=@StrSql + 'WHERE DataType=1 And partscount >0 AND A.loadunload >= isnull((SELECT top 1 VALUEININT FROM SHOPDEFAULTS where parameter = ''minluforlr''),0)'
		SELECT @StrSql=@StrSql + 'WHERE DataType=1 And partscount >0 '

--DR0213 By Karthik G on 29-Sep-2009
	SELECT @StrSql=@StrSql + ' AND  Ndtime<='''+Convert(NvarChar(20),@EndTime,120)+''' AND Ndtime>'''+Convert(NvarChar(20),@StartTime,120)+''' '
	SELECT @StrSql=@StrSql+@StrCompOpn+@StrOpn
--ER0181 By Karthik G on 29-Sep-2009
	--SELECT @StrSql=@StrSql + ' Group By C.ComponentID,O.OperationNo,O.SubOperations,O.CycleTime,O.MachiningTime'
	SELECT @StrSql=@StrSql + ' Group By M.MachineID,C.ComponentID,O.OperationNo,O.SubOperations,O.CycleTime,O.MachiningTime'
--ER0181 By Karthik G on 29-Sep-2009
	SELECT @StrSql=@StrSql + ' ) As T1 Inner Join  #productiontime '
	SELECT @StrSql=@StrSql + ' ON #productiontime.pMachineID=T1.MachineID AND #productiontime.pComponentID=T1.ComponentID AND #productiontime.POperationNo=T1.OperationNo'
	EXEC(@StrSql)	
	--Karthi : DR0016 : Changes end here
	SET @strSql = ''
	SET @strSql = 'INSERT INTO #PLD(MachineID,MachineInterface,ComponentID,ComponentInterface,OperationNo,OperationInterface)
		SELECT distinct PMachineID,PMachineInterface,pComponentID,PComponentInterface,POperationNo,POperationInterface FROM #productiontime'
	EXEC(@strSql)
SELECT @StrSql =''
SELECT @StrSql = 'INSERT INTO #Exceptions(MachineID ,ComponentID,OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,ExCount )
		SELECT Ex.MachineID ,Ex.ComponentID,Ex.OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,0
		From ProductionCountException Ex
		Inner Join MachineInformation M ON Ex.MachineID=M.MachineID
		Inner Join ComponentInformation C ON Ex.ComponentID=C.ComponentID
		Inner Join Componentoperationpricing O ON Ex.OperationNo=O.OperationNo AND C.ComponentID=O.ComponentID And M.machineID=O.MachineID
		WHERE M.MultiSpindleFlag=1 AND
		((Ex.StartTime>=  ''' + convert(nvarchar(20),@StartTime,120)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@EndTime,120)+''' )
		OR (Ex.StartTime< ''' + convert(nvarchar(20),@StartTime,120)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@StartTime,120)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@EndTime,120)+''')
		OR(Ex.StartTime>= ''' + convert(nvarchar(20),@StartTime,120)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@EndTime,120)+''' AND Ex.StartTime< ''' + convert(nvarchar(20),@EndTime,120)+''')
		OR(Ex.StartTime< ''' + convert(nvarchar(20),@StartTime,120)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@EndTime,120)+''' ))'
SELECT @StrSql = @StrSql +  @StrCompOpn + @StrOpn
Exec (@strsql)
IF (SELECT Count(*) from #Exceptions)<>0
BEGIN
	UPDATE #Exceptions SET StartTime=@StartTime WHERE (StartTime<@StartTime)AND EndTime>@StartTime
	UPDATE #Exceptions SET EndTime=@EndTime WHERE (EndTime>@EndTime AND StartTime<@EndTime )
	
	Select @StrSql = 'UPDATE #Exceptions SET ExCount=ISNULL(T2.Comp,0) From
	(
		SELECT T1.MachineID AS MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime AS StartTime,T1.EndTime AS EndTime,
		--SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp --NR0097
		SUM(CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp
	 	From (
			select M.MachineID,C.ComponentID,O.OperationNo,mc,comp,opn,Tt1.StartTime,Tt1.EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from #T_autodata  autodata
			Inner Join MachineInformation M  ON autodata.MC=M.InterfaceID
			Inner Join ComponentInformation  C ON autodata.Comp = C.InterfaceID
			Inner Join ComponentOperationPricing O on autodata.Opn=O.InterfaceID And C.ComponentID=O.ComponentID And M.MachineID=O.MachineID
			Inner Join (
				Select MachineID,ComponentID,OperationNo,StartTime,EndTime From #Exceptions
			)AS Tt1 ON Tt1.MachineID=M.MachineID AND Tt1.ComponentID = C.ComponentID AND Tt1.OperationNo= O.OperationNo
			Where (autodata.ndtime>Tt1.StartTime) AND (autodata.ndtime<=Tt1.EndTime) and (autodata.datatype=1)'
	Select @StrSql = @StrSql + @StrCompOpn + @StrOpn
	Select @StrSql = @StrSql +' Group by M.MachineID,C.ComponentID,O.OperationNo,Tt1.StartTime,Tt1.EndTime,mc,comp,opn
		) as T1
		Inner join MachineInformation M on T1.mc=M.interfaceid
	   	Inner join componentinformation C on T1.Comp=C.interfaceid
	   	Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid and M.MachineID=O.MachineID
	  	GROUP BY T1.MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime,t1.EndTime
	)AS T2
	WHERE  #Exceptions.StartTime=T2.StartTime AND #Exceptions.EndTime=T2.EndTime
	AND #Exceptions.MachineID=T2.MachineID AND #Exceptions.ComponentID = T2.ComponentID AND #Exceptions.OperationNo=T2.OperationNo'
	Exec(@StrSql)
	
	--ER0210(PDT)
	If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
	BEGIN
			Select @StrSql =''
			Select @StrSql ='UPDATE #Exceptions SET ExCount=ISNULL(ExCount,0) - ISNULL(T3.compCount,0)
			From
			(
				SELECT T2.MachineID AS MachineID,T2.ComponentID,T2.OperationNo,T2.StartTime AS StartTime,T2.EndTime AS EndTime,
				--SUM(CEILING (CAST(T2.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as compCount --NR0097
				SUM((CAST(T2.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as compCount --NR0097
				From
				(
					select MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,comp,opn,
					Max(T1.XStartTime)StartTime,Max(T1.XEndTime)EndTime,T1.PLD_StartTime,T1.PLD_EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from #T_autodata  autodata
					Inner Join MachineInformation ON autodata.MC=MachineInformation.InterfaceID
					Inner Join ComponentInformation ON autodata.Comp = ComponentInformation.InterfaceID
					Inner Join ComponentOperationPricing on autodata.Opn=ComponentOperationPricing.InterfaceID And ComponentInformation.ComponentID=ComponentOperationPricing.ComponentID And ComponentOperationPricing.MachineID = MachineInformation.MachineID
					Inner Join	
					(
						SELECT Ex.MachineID,Ex.ComponentID,Ex.OperationNo,Ex.StartTime As XStartTime, Ex.EndTime AS XEndTime,
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
						From #Exceptions AS Ex inner JOIN #PlannedDownTimes AS Td on Ex.MachineID = Td.MachineID
						Where ((Td.StartTime>=Ex.StartTime And Td.EndTime <=Ex.EndTime)OR
						(Td.StartTime< Ex.StartTime And Td.EndTime<=Ex.EndTime AND Td.EndTime>Ex.StartTime)OR
						(Td.StartTime>= Ex.StartTime And Td.StartTime <Ex.EndTime AND Td.EndTime>Ex.EndTime)OR
						(Td.StartTime< Ex.StartTime And Td.EndTime>Ex.EndTime))'
				Select @StrSql = @StrSql + ' )AS T1 ON T1.MachineID=MachineInformation.MachineID AND T1.ComponentID = ComponentInformation.ComponentID AND T1.OperationNo= ComponentOperationPricing.OperationNo and T1.Machineid=ComponentOperationPricing.MachineID
					Where (autodata.ndtime>T1.PLD_StartTime AND autodata.ndtime<=T1.PLD_EndTime) and (autodata.datatype=1)
				AND (autodata.ndtime > ''' + convert(nvarchar(20),@StartTime)+''' AND autodata.ndtime<=''' + convert(nvarchar(20),@EndTime)+''' )'
				Select @StrSql = @StrSql+' Group by MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,T1.PLD_StartTime,T1.PLD_EndTime,comp,opn
				)AS T2
				Inner join componentinformation C on T2.Comp=C.interfaceid
				Inner join ComponentOperationPricing O ON T2.Opn=O.interfaceid and C.Componentid=O.componentid and T2.MachineID = O.MachineID
				GROUP BY T2.MachineID,T2.ComponentID,T2.OperationNo,T2.StartTime,t2.EndTime
			)As T3
			WHERE  #Exceptions.StartTime=T3.StartTime AND #Exceptions.EndTime=T3.EndTime
			AND #Exceptions.MachineID=T3.MachineID AND #Exceptions.ComponentID = T3.ComponentID AND #Exceptions.OperationNo=T3.OperationNo'
			--PRINT @StrSql
			EXEC(@StrSql)
	End
	--ER0210(PDT)
	UPDATE #Exceptions SET ExCount=ExCount-((ExCount * ActualCount)/ISNULL(IdealCount,0))
END
	UPDATE #ProductionTime SET ProdCount = ISNULL(ProdCount,0)-ISNULL(T1.XCount,0)	FROM (
--ER0181 By Karthik G on 29-Sep-2009
	--Select ComponentID, OperationNo ,Sum(ISNULL(ExCount,0))As XCount FROM  #Exceptions GROUP BY ComponentID, OperationNo
	Select MachineID,ComponentID,OperationNo ,Sum(ISNULL(ExCount,0))As XCount FROM  #Exceptions GROUP BY machineID,ComponentID,OperationNo
	--)AS T1 Inner Join #ProductionTime ON #ProductionTime.pComponentID=T1.ComponentID AND #ProductionTime.POperationNo=T1.OperationNo
	)AS T1 Inner Join #ProductionTime ON #ProductionTime.pMachineID=T1.MachineID AND #ProductionTime.pComponentID=T1.ComponentID AND #ProductionTime.POperationNo=T1.OperationNo
--ER0181 By Karthik G on 29-Sep-2009
--ER0210(PDT)--Apply PDT for calculation of Count
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	UPDATE #ProductionTime SET ProdCount = ISNULL(#ProductionTime.ProdCount,0) - ISNULL(T2.ProdCount,0)
	from(
		select mc,comp,opn, 
		--SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as ProdCount --NR0097
		SUM((CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as ProdCount --NR0097
		From (
			select mc,comp,opn,Sum(ISNULL(PartsCount,1))AS OrginalCount from #T_autodata  autodata
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
--ER0210(PDT)
--ER0181 By Karthik G on 29-Sep-2009 - From Here
/*******************************      Utilised Calculation Starts ***************************************************/
	UPDATE #ProductionTime SET UtilisedTime=ISNULL(UtilisedTime,0)+ISNULL(T1.ProductionTime,0)	From(
		SELECT M.MachineID,C.ComponentID,O.OperationNo,
		Sum(
		CASE
		WHEN (mSttime>=@StartTime And Ndtime<=@EndTime) THEN A.Cycletime+A.loadunload
		WHEN (mSttime<@StartTime AND Ndtime>@StartTime AND Ndtime<=@EndTime) THEN DateDiff(ss,@StartTime,Ndtime)
		WHEN (mSttime>=@StartTime AND mSttime<@EndTime AND Ndtime>@EndTime) THEN DateDiff(ss, mSttime, @Endtime)
		WHEN (mSttime<@StartTime AND Ndtime>@EndTime) THEN DateDiff(ss, @StartTime, @EndTime)
		END )AS ProductionTime
		FROM #T_autodata  A
		Inner Join MachineInformation M ON A.mc=M.InterfaceID
		Inner Join ComponentInformation C ON A.Comp=C.InterfaceID
		Inner Join ComponentOperationPricing O ON A.Opn=O.InterfaceID AND C.ComponentID=O.ComponentID and M.MachineID = O.MachineID			
		WHERE DataType=1 And ((mSttime>=@StartTime And Ndtime<=@EndTime) OR
		(mSttime<@StartTime AND Ndtime>@StartTime AND Ndtime<=@EndTime)OR
		(mSttime>=@StartTime AND mSttime<@EndTime AND Ndtime>@EndTime)OR
		(mSttime<@StartTime AND Ndtime>@EndTime)
		)Group By M.MachineID,C.ComponentID,O.OperationNo
	)AS T1 Inner Join #ProductionTime ON T1.MachineID=#ProductionTime.PMachineID AND T1.ComponentID=#ProductionTime.PComponentID AND T1.OperationNo=#ProductionTime.POperationNo
--ER0181 By Karthik G on 29-Sep-2009 - Till Here
/* Fetching Down Records from Production Cycle  */
/* If Down Records of TYPE-2*/
--ER0181 By Karthik G on 29-Sep-2009 - From Here
UPDATE  #ProductionTime SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)	FROM(
	Select M.MachineID,C.ComponentID,O.OperationNo,
	SUM(
	CASE
		When autodata.sttime <= @StartTime Then datediff(s, @StartTime,autodata.ndtime )
		When autodata.sttime > @StartTime Then datediff(s , autodata.sttime,autodata.ndtime)
	END) as Down
	From #T_autodata AutoData INNER Join
		(Select Mc,Comp,Opn,Sttime,NdTime From #T_autodata  autodata
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(msttime < @StartTime)And (ndtime > @StartTime) AND (ndtime <= @EndTime)) as T1
	ON AutoData.mc=T1.mc AND AutoData.Comp=T1.Comp AND  AutoData.Opn=T1.Opn
	Inner Join MachineInformation M ON Autodata.mc=M.InterfaceID
	Inner Join ComponentInformation C ON AutoData.Comp=C.InterfaceID
	Inner Join ComponentOperationPricing O ON AutoData.Opn=O.InterfaceID AND C.ComponentID=O.ComponentID AND M.MachineID=O.MachineID
	Where AutoData.DataType=2
	And ( autodata.Sttime > T1.Sttime )
	And ( autodata.ndtime <  T1.ndtime )
	AND ( autodata.ndtime >  @StartTime )
	GROUP BY M.MachineID,C.ComponentID,O.OperationNo
)AS T2 Inner Join #ProductionTime ON T2.MachineID=#ProductionTime.PMachineID AND T2.ComponentID=#ProductionTime.PComponentID AND T2.OperationNo=#ProductionTime.POperationNo
--ER0181 By Karthik G on 29-Sep-2009 - Till Here
/* If Down Records of TYPE-3*/
--ER0181 By Karthik G on 29-Sep-2009 - From Here
UPDATE  #ProductionTime SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)FROM(
	Select M.MachineID,C.ComponentID,O.OperationNo,
	SUM(CASE
	When autodata.ndtime > @EndTime Then datediff(s,autodata.sttime, @EndTime )
	When autodata.ndtime <=@EndTime Then datediff(s , autodata.sttime,autodata.ndtime)
	END) as Down
	From #T_autodata AutoData INNER Join
	(Select Mc,Comp,Opn,Sttime,NdTime From #T_autodata  autodata
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(sttime >= @StartTime)And (ndtime > @EndTime) and (sttime<@EndTime)) as T1
	ON AutoData.mc=T1.mc AND AutoData.Comp=T1.Comp AND  AutoData.Opn=T1.Opn
	Inner Join MachineInformation M ON Autodata.mc=M.InterfaceID
	Inner Join ComponentInformation C ON AutoData.Comp=C.InterfaceID
	Inner Join ComponentOperationPricing O ON AutoData.Opn=O.InterfaceID AND C.ComponentID=O.ComponentID AND M.MachineID=O.MachineID
	Where AutoData.DataType=2
	And (T1.Sttime < autodata.sttime  )
	And ( T1.ndtime >  autodata.ndtime)
	AND (autodata.sttime  <  @EndTime)
	GROUP BY M.MachineID,C.ComponentID,O.OperationNo
)AS T2 Inner Join #ProductionTime ON T2.MachineID=#ProductionTime.PMachineID AND T2.ComponentID=#ProductionTime.PComponentID AND T2.OperationNo=#ProductionTime.POperationNo
--ER0181 By Karthik G on 29-Sep-2009 - Till Here
/* If Down Records of TYPE-4*/
--ER0181 By Karthik G on 29-Sep-2009 - From Here
UPDATE  #ProductionTime SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
FROM
(Select M.MachineID,C.ComponentID,O.OperationNo,
SUM(CASE
	When autodata.sttime < @StartTime AND autodata.ndtime<=@EndTime Then datediff(s, @StartTime,autodata.ndtime )
	When autodata.ndtime >= @EndTime AND autodata.sttime>@StartTime Then datediff(s,autodata.sttime, @EndTime )
	When autodata.sttime >= @StartTime AND
	     autodata.ndtime <= @EndTime Then datediff(s , autodata.sttime,autodata.ndtime)
	When autodata.sttime<@StartTime AND autodata.ndtime>@EndTime   Then datediff(s , @StartTime,@EndTime)
END) as Down
From #T_autodata AutoData INNER Join
	(Select  Mc,Comp,Opn,Sttime,NdTime From #T_autodata  autodata
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(msttime < @StartTime)And (ndtime > @EndTime) ) as T1
ON AutoData.mc=T1.mc AND AutoData.Comp=T1.Comp AND  AutoData.Opn=T1.Opn
Inner Join MachineInformation M ON Autodata.mc=M.InterfaceID
Inner Join ComponentInformation C ON AutoData.Comp=C.InterfaceID
Inner Join ComponentOperationPricing O ON AutoData.Opn=O.InterfaceID AND C.ComponentID=O.ComponentID AND M.MachineID=O.MachineID
Where AutoData.DataType=2
And (T1.Sttime < autodata.sttime  )
And ( T1.ndtime >  autodata.ndtime)
AND (autodata.ndtime  >  @StartTime)
AND (autodata.sttime  <  @EndTime)
GROUP BY  M.MachineID,C.ComponentID,O.OperationNo
)AS T2 Inner Join #ProductionTime ON T2.MachineID=#ProductionTime.PMachineID AND T2.ComponentID=#ProductionTime.PComponentID AND T2.OperationNo=#ProductionTime.POperationNo
--ER0181 By Karthik G on 29-Sep-2009 - Till Here
--ER0210(PDT) --Get utilised time over lapping with PDT.
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')='Y'
BEGIN
	UPDATE #PLD set pPlannedDT =isnull(pPlannedDT,0) + isNull(TT.PPDT ,0) FROM(
		--Production Time in PDT
		SELECT autodata.MC,autodata.comp,autodata.opn,SUM
			(CASE
			WHEN autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.cycletime+autodata.loadunload)
			WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.msttime,T.EndTime )
			WHEN ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END)  as PPDT
		FROM #T_autodata AutoData CROSS jOIN #PlannedDownTimes T
		WHERE autodata.DataType=1 And T.MachineInterface=AutoData.mc AND
			((autodata.msttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.msttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.msttime >= T.StartTime   AND autodata.msttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.msttime < T.StartTime  AND autodata.ndtime > T.EndTime) )
		group by autodata.mc,autodata.comp,autodata.opn
	)as TT INNER JOIN #PLD ON TT.mc = #PLD.MachineInterface And TT.comp=#PLD.ComponentInterface and TT.opn=#PLD.OperationInterface
--select * from #PLD
	--mod 4(4):Handle intearction between ICD and PDT for type 1 production record for the selected time period.
		UPDATE  #PLD set IPlannedDT =isnull(IPlannedDT,0) + isNull(T2.IPDT ,0) 	FROM	(
		SELECT autodata.MC,autodata.comp,autodata.opn,SUM(
		CASE 	
			When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
			When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
			When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
			when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		From #T_autodata AutoData INNER Join
			(Select mc,Comp,Opn,Sttime,NdTime From #T_autodata  autodata
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(msttime >= @StartTime) AND (ndtime <= @EndTime)) as T1
		ON AutoData.mc=T1.mc AND AutoData.Comp=T1.Comp AND  AutoData.Opn=T1.Opn
		CROSS jOIN #PlannedDownTimes T
		Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc
		And (( autodata.Sttime >= T1.Sttime ) --DR0339
		And ( autodata.ndtime <=  T1.ndtime ) --DR0339
		)
		AND
		((( T.StartTime >=T1.Sttime) And ( T.EndTime <=T1.ndtime ))
		or ( T.StartTime < T1.Sttime  and  T.EndTime <= T1.ndtime AND T.EndTime > T1.Sttime)
		or (T.StartTime >= T1.Sttime   AND T.StartTime <T1.ndtime AND T.EndTime > T1.ndtime )
		or (( T.StartTime <T1.Sttime) And ( T.EndTime >T1.ndtime )) )
		group by autodata.mc,autodata.comp,autodata.opn
		)AS T2 INNER JOIN #PLD ON T2.mc = #PLD.MachineInterface And T2.comp=#PLD.ComponentInterface And T2.opn=#PLD.OperationInterface
	---mod 4(4)
	
	/* Fetching Down Records from Production Cycle  */
	/* If production  Records of TYPE-2*/
	UPDATE  #PLD set IPlannedDT =isnull(IPlannedDT,0) + isNull(T2.IPDT ,0) 	FROM	(
			SELECT autodata.MC,autodata.comp,autodata.opn,SUM(
			CASE 	
				When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
				When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
				When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
				when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
			END) as IPDT
			From #T_autodata AutoData INNER Join
				(Select mc,comp,opn,Sttime,NdTime From #T_autodata  autodata
					Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
					(msttime < @StartTime)And (ndtime > @StartTime) AND (ndtime <= @EndTime)) as T1
			ON AutoData.mc=T1.mc AND AutoData.Comp=T1.Comp AND  AutoData.Opn=T1.Opn
			CROSS jOIN #PlannedDownTimes T
			Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc
			And (( autodata.Sttime > T1.Sttime )
			And ( autodata.ndtime <  T1.ndtime )
			AND ( autodata.ndtime >  @StartTime ))
			AND
			(( T.StartTime >= @StartTime )
			And ( T.StartTime <  T1.ndtime ) )
			group by autodata.mc,autodata.comp,autodata.opn
		)AS T2 INNER JOIN #PLD ON T2.mc = #PLD.MachineInterface And T2.comp=#PLD.ComponentInterface And T2.opn=#PLD.OperationInterface
	
	/* If production Records of TYPE-3*/
	UPDATE  #PLD set IPlannedDT =isnull(IPlannedDT,0) + isNull(T2.IPDT ,0) FROM (
		SELECT autodata.MC,autodata.comp,autodata.opn,SUM(
		CASE 	
			When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
			When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
			When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
			when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		From #T_autodata AutoData INNER Join
			(Select mc,comp,opn,Sttime,NdTime From #T_autodata  autodata
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(sttime >= @StartTime)And (ndtime > @EndTime) and autodata.sttime <@EndTime) as T1
		ON AutoData.mc=T1.mc AND AutoData.Comp=T1.Comp AND  AutoData.Opn=T1.Opn
		CROSS jOIN #PlannedDownTimes T
		Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc
		And ((T1.Sttime < autodata.sttime  )
		And ( T1.ndtime >  autodata.ndtime)
		AND (autodata.msttime  <  @EndTime))
		AND
		(( T.EndTime > T1.Sttime )
		And ( T.EndTime <=@EndTime ) )
		group by autodata.mc,autodata.comp,autodata.opn
	)AS T2 INNER JOIN #PLD ON T2.mc = #PLD.MachineInterface And T2.comp=#PLD.ComponentInterface And T2.opn=#PLD.OperationInterface	
	
	/* If production Records of TYPE-4*/
	UPDATE  #PLD set IPlannedDT =isnull(IPlannedDT,0) + isNull(T2.IPDT ,0) FROM(
		SELECT autodata.MC,autodata.comp,autodata.opn,SUM(
		CASE 	
			When autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  Then datediff(s , autodata.sttime,autodata.ndtime) ---type 1
			When autodata.sttime < T.StartTime  and  autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime Then datediff(s, T.StartTime,autodata.ndtime ) ---type 2
			When ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime ) Then datediff(s, autodata.sttime,T.EndTime ) ---type 3
			when ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)  Then datediff(s, T.StartTime,T.EndTime ) ---type 4
		END) as IPDT
		From #T_autodata AutoData INNER Join
			(Select mc,comp,opn,Sttime,NdTime From #T_autodata  autodata
				Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
				(msttime < @StartTime)And (ndtime > @EndTime)) as T1
		ON AutoData.mc=T1.mc AND AutoData.Comp=T1.Comp AND  AutoData.Opn=T1.Opn
		CROSS jOIN #PlannedDownTimes T
		Where AutoData.DataType=2 And T.MachineInterface=AutoData.mc
		And ( (T1.Sttime < autodata.sttime  )
		And ( T1.ndtime >  autodata.ndtime)
		AND (autodata.ndtime  >  @StartTime)
		AND (autodata.sttime  <  @EndTime))
		AND	(( T.StartTime >=@StartTime)
		And ( T.EndTime <=@EndTime ) )
		group by autodata.mc,autodata.comp,autodata.opn
	)AS T2 INNER JOIN #PLD ON T2.mc = #PLD.MachineInterface And T2.comp=#PLD.ComponentInterface And T2.opn=#PLD.OperationInterface	
END
/*******************************      Utilised Calculation Ends ***************************************************/
--ER0210(PDT)
	
	/*--ER0210--Commented by KarthikG : From Here
	SELECT @StrSql=''
	--ER0181 By Karthik G on 29-Sep-2009
	--SELECT @StrSql='INSERT INTO #DownTime (PComponentID,POperationNo,DownTime ) '
	SELECT @StrSql='INSERT INTO #DownTime (PMachineID,PComponentID,POperationNo,DownTime ) '
	--ER0181 By Karthik G on 29-Sep-2009
	SELECT @StrSql=@StrSql+'SELECT M.MachineID,C.ComponentID,O.OperationNo ,Sum( '
	SELECT @StrSql=@StrSql+'CASE '
	SELECT @StrSql=@StrSql+'WHEN (Sttime>='''+Convert(NvarChar(20),@StartTime,120)+''' And Ndtime<='''+Convert(NvarChar(20),@EndTime,120)+''') THEN DateDiff(ss,Sttime,Ndtime) '
	SELECT @StrSql=@StrSql+'WHEN (Sttime<='''+Convert(NvarChar(20),@StartTime,120)+'''  AND Ndtime>'''+Convert(NvarChar(20),@StartTime,120)+'''  AND Ndtime<='''+Convert(NvarChar(20),@EndTime,120)+''') THEN DateDiff(ss,'''+Convert(NvarChar(20),@StartTime,120)+''' ,Ndtime) '
	SELECT @StrSql=@StrSql+'WHEN (Sttime>='''+Convert(NvarChar(20),@StartTime,120)+'''  AND Sttime<'''+Convert(NvarChar(20),@EndTime,120)+''' AND Ndtime>'''+Convert(NvarChar(20),@EndTime,120)+''') THEN DateDiff(ss, Sttime, '''+Convert(NvarChar(20),@EndTime,120)+''')'
	SELECT @StrSql=@StrSql+'WHEN (Sttime<'''+Convert(NvarChar(20),@StartTime,120)+'''  AND Ndtime>'''+Convert(NvarChar(20),@EndTime,120)+''')THEN DateDiff(ss, '''+Convert(NvarChar(20),@StartTime,120)+''' , '''+Convert(NvarChar(20),@EndTime,120)+''')'
	SELECT @StrSql=@StrSql+'END )AS DownTime  '
	SELECT @StrSql=@StrSql+'FROM AutoData A Inner Join  ComponentInformation C ON A.Comp=C.InterfaceID Inner Join ComponentOperationPricing O ON A.Opn=O.InterfaceID AND C.ComponentID=O.ComponentID '
	SELECT @StrSql=@StrSql+'Inner Join MachineInformation M On A.mc=M.InterfaceID and M.MachineID=O.MachineID '		--ER0181 By Karthik G on 29-Sep-2009
	SELECT @StrSql=@StrSql+'WHERE DataType=2 And ( '
	SELECT @StrSql=@StrSql+'(Sttime>='''+Convert(NvarChar(20),@StartTime,120)+'''  And Ndtime<='''+Convert(NvarChar(20),@EndTime,120)+''') OR '
	SELECT @StrSql=@StrSql+'(Sttime<='''+Convert(NvarChar(20),@StartTime,120)+'''  AND Ndtime>'''+Convert(NvarChar(20),@StartTime,120)+'''  AND Ndtime<='''+Convert(NvarChar(20),@EndTime,120)+''')OR '
	SELECT @StrSql=@StrSql+'(Sttime>='''+Convert(NvarChar(20),@StartTime,120)+'''  AND Sttime<'''+Convert(NvarChar(20),@EndTime,120)+''' AND Ndtime>'''+Convert(NvarChar(20),@EndTime,120)+''')OR '
	SELECT @StrSql=@StrSql+'(Sttime<'''+Convert(NvarChar(20),@StartTime,120)+'''  AND Ndtime>'''+Convert(NvarChar(20),@EndTime,120)+''')) '
	SELECT @StrSql=@StrSql+@StrCompOpn+@StrOpn
	SELECT @StrSql=@StrSql+' Group By M.MachineID,C.ComponentID,O.OperationNo '--ER0181 By Karthik G on 29-Sep-2009
	SELECT @StrSql=@StrSql+' Order By M.MachineID,C.ComponentID,O.OperationNo '--ER0181 By Karthik G on 29-Sep-2009
	EXEC(@StrSql)	
	
	UPDATE #DownTime SET ManagementLoss=ISNULL(ManagementLoss,0)+ISNULL(T1.ALoss,0)
	FROM
	--ER0181 By Karthik G on 29-Sep-2009
	--(SELECT C.ComponentID,O.OperationNo ,Sum(
	(SELECT M.MachineID,C.ComponentID,O.OperationNo,Sum(
	--ER0181 By Karthik G on 29-Sep-2009	
	CASE
	WHEN (Sttime>=@StartTime And Ndtime<=@EndTime) THEN
		CASE
			WHEN (A.Loadunload) > isnull(D.Threshold,0) and isnull(D.Threshold,0) > 0  THEN isnull(D.Threshold,0)
			ELSE A.Loadunload
		END
	WHEN (Sttime<@StartTime AND Ndtime>@StartTime AND Ndtime<=@EndTime) THEN
	 	CASE
			WHEN DateDiff(second, @StartTime, ndtime) > isnull(D.Threshold,0) and isnull(D.Threshold,0) > 0  Then isnull(D.Threshold,0)
			ELSE DateDiff(second, @StartTime, ndtime)
		END
	WHEN (Sttime>=@StartTime AND Sttime<@EndTime AND Ndtime>@EndTime) THEN
		CASE
			WHEN DateDiff(second,stTime, @Endtime) > isnull(D.Threshold,0) and isnull(D.Threshold,0) > 0  Then isnull(D.Threshold,0)
			ELSE DateDiff(second, stTime, @Endtime)
		END
	WHEN (Sttime<@StartTime AND Ndtime>@EndTime)THEN
		CASE
			WHEN DateDiff(second, @StartTime, @Endtime) > isnull(D.Threshold,0) and isnull(D.Threshold,0) > 0  Then isnull(D.Threshold,0)
			ELSE DateDiff(second, @StartTime, @Endtime)
		END
	END )AS ALoss
	FROM AutoData A
	Inner Join MachineInformation M ON A.mc=M.InterfaceID
	Inner Join ComponentInformation C ON A.Comp=C.InterfaceID
	Inner Join ComponentOperationPricing O ON A.Opn=O.InterfaceID AND C.ComponentID=O.ComponentID AND M.MachineID=O.MachineID--ER0181 By Karthik G on 29-Sep-2009	
	Inner JOin DownCodeInformation D ON A.Dcode=D.InterfaceID
	WHERE AvailEffy=1 AND DataType=2 And (
	(Sttime>=@StartTime And Ndtime<=@EndTime) OR
	(Sttime<@StartTime AND Ndtime>@StartTime AND Ndtime<=@EndTime)OR
	(Sttime>=@StartTime AND Sttime<@EndTime AND Ndtime>@EndTime)OR
	(Sttime<@StartTime AND Ndtime>@EndTime)
	)
	Group By M.MachineID,C.ComponentID,O.OperationNo
	--ER0181 By Karthik G on 29-Sep-2009	
	--)AS T1 Inner Join #DownTime ON T1.ComponentID=#DownTime.PComponentID AND T1.OperationNo=#DownTime.POperationNo
	)AS T1 Inner Join #DownTime ON T1.MachineID=#DownTime.PMachineID AND T1.ComponentID=#DownTime.PComponentID AND T1.OperationNo=#DownTime.POperationNo
	--ER0181 By Karthik G on 29-Sep-2009	
	
	
	UPDATE #ProductionTime SET DownTime=ISNULL(T1.DT,0),ManagementLoss=ISNULL(T1.AL,0)
	FROM(
	--ER0181 By Karthik G on 29-Sep-2009	
	--SELECT PComponentID,POperationNo,ISNULL(DownTime,0)AS DT,ISNULL(ManagementLoss,0)AS AL FROM #DownTime
	--)AS T1 INNER JOIN #ProductionTime ON #ProductionTime.PComponentID=T1.PComponentID AND #ProductionTime.POperationNo=T1.POperationNo
	SELECT PMachineID,PComponentID,POperationNo,ISNULL(DownTime,0)AS DT,ISNULL(ManagementLoss,0)AS AL FROM #DownTime
	)AS T1 INNER JOIN #ProductionTime ON #ProductionTime.PMachineID=T1.PmachineID AND #ProductionTime.PComponentID=T1.PComponentID AND #ProductionTime.POperationNo=T1.POperationNo
	--ER0181 By Karthik G on 29-Sep-2009	
	*/--ER0210--Commented by KarthikG : till Here
/*******************************Down Record***********************************/
--**************************************** ManagementLoss and Downtime Calculation Starts **************************************
---ER0210 from here
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='N' or ((SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y')
BEGIN
		-- Type 1
		UPDATE #ProductionTime SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)from(
			select mc,comp,opn,
			sum(CASE
			WHEN (autodata.loadunload) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
			THEN isnull(downcodeinformation.Threshold,0)
			ELSE autodata.loadunload
			END) AS LOSS
			from #T_autodata  autodata
			Inner Join MachineInformation M ON autodata.mc=M.InterfaceID
			Inner Join ComponentInformation C ON autodata.Comp=C.InterfaceID
			Inner Join ComponentOperationPricing O ON autodata.Opn=O.InterfaceID AND C.ComponentID=O.ComponentID AND M.MachineID=O.MachineID
			INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
			where (autodata.msttime>=@StartTime)
			and (autodata.ndtime<=@EndTime)
			and (autodata.datatype=2)
			and (downcodeinformation.availeffy = 1)
			group by mc,comp,opn
		) as t2 inner join #ProductionTime on t2.mc = #ProductionTime.PMachineInterface and t2.comp = #ProductionTime.PComponentInterface and t2.opn = #ProductionTime.POperationInterface
		-- Type 2
		UPDATE #ProductionTime SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
		from
			(select mc,comp,opn,sum(
			CASE WHEN DateDiff(second, @StartTime, ndtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
			then isnull(downcodeinformation.Threshold,0)
			ELSE DateDiff(second, @StartTime, ndtime)
			END)loss
			--DateDiff(second, @StartTime, ndtime)
			from #T_autodata  autodata
			Inner Join MachineInformation M ON autodata.mc=M.InterfaceID
			Inner Join ComponentInformation C ON autodata.Comp=C.InterfaceID
			Inner Join ComponentOperationPricing O ON autodata.Opn=O.InterfaceID AND C.ComponentID=O.ComponentID AND M.MachineID=O.MachineID
			INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
			where (autodata.sttime<@StartTime)
			and (autodata.ndtime>@StartTime)
			and (autodata.ndtime<=@EndTime)
			and (autodata.datatype=2)
			and (downcodeinformation.availeffy = 1)
			group by mc,comp,opn
		) as t2 inner join #ProductionTime on t2.mc = #ProductionTime.PMachineInterface and t2.comp = #ProductionTime.PComponentInterface and t2.opn = #ProductionTime.POperationInterface
		-- Type 3
		UPDATE #ProductionTime SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
		from
			(select      mc,comp,opn,SUM(
			CASE WHEN DateDiff(second,stTime, @Endtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
			then isnull(downcodeinformation.Threshold,0)
			ELSE DateDiff(second, stTime, @Endtime)
			END)loss
			-- sum(DateDiff(second, stTime, @Endtime)) loss
			from #T_autodata  autodata
			Inner Join MachineInformation M ON autodata.mc=M.InterfaceID
			Inner Join ComponentInformation C ON autodata.Comp=C.InterfaceID
			Inner Join ComponentOperationPricing O ON autodata.Opn=O.InterfaceID AND C.ComponentID=O.ComponentID AND M.MachineID=O.MachineID
			INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
			where (autodata.msttime>=@StartTime)
			and (autodata.sttime<@EndTime)
			and (autodata.ndtime>@EndTime)
			and (autodata.datatype=2)
			and (downcodeinformation.availeffy = 1)
			group by mc,comp,opn
		) as t2 inner join #ProductionTime on t2.mc = #ProductionTime.PMachineInterface and t2.comp = #ProductionTime.PComponentInterface and t2.opn = #ProductionTime.POperationInterface
		-- Type 4
		UPDATE #ProductionTime SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
		from
			(select mc,comp,opn,sum(
			CASE WHEN DateDiff(second, @StartTime, @Endtime) > isnull(downcodeinformation.Threshold,0) and isnull(downcodeinformation.Threshold,0) > 0
			then isnull(downcodeinformation.Threshold,0)
			ELSE DateDiff(second, @StartTime, @Endtime)
			END)loss
			--sum(DateDiff(second, @StartTime, @Endtime)) loss
			from #T_autodata  autodata
			Inner Join MachineInformation M ON autodata.mc=M.InterfaceID
			Inner Join ComponentInformation C ON autodata.Comp=C.InterfaceID
			Inner Join ComponentOperationPricing O ON autodata.Opn=O.InterfaceID AND C.ComponentID=O.ComponentID AND M.MachineID=O.MachineID
			INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
			where autodata.msttime<@StartTime
			and autodata.ndtime>@EndTime
			and (autodata.datatype=2)
			and (downcodeinformation.availeffy = 1)
			group by mc,comp,opn
		) as t2 inner join #ProductionTime on t2.mc = #ProductionTime.PMachineInterface and t2.comp = #ProductionTime.PComponentInterface and t2.opn = #ProductionTime.POperationInterface
		---get the downtime for the time period
		UPDATE #ProductionTime SET downtime = isnull(downtime,0) + isNull(t2.down,0)
		from
		(select mc,comp,opn,sum(
				CASE
				WHEN  autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime  THEN  autodata.loadunload
				WHEN (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  THEN DateDiff(second, @StartTime, ndtime)
				WHEN (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)  THEN DateDiff(second, stTime, @Endtime)
				WHEN autodata.msttime<@StartTime and autodata.ndtime>@EndTime   THEN DateDiff(second, @StartTime, @EndTime)
				END
			)AS down
		from #T_autodata  autodata
		Inner Join MachineInformation M ON autodata.mc=M.InterfaceID
		Inner Join ComponentInformation C ON autodata.Comp=C.InterfaceID
		Inner Join ComponentOperationPricing O ON autodata.Opn=O.InterfaceID AND C.ComponentID=O.ComponentID AND M.MachineID=O.MachineID
		inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		where autodata.datatype=2 AND
		(
		(autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)
		OR (autodata.sttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
		OR (autodata.msttime>=@StartTime  and autodata.sttime<@EndTime  and autodata.ndtime>@EndTime)
		OR (autodata.msttime<@StartTime and autodata.ndtime>@EndTime )
		)
		group by mc,comp,opn
		) as t2 inner join #ProductionTime on t2.mc = #ProductionTime.PMachineInterface and t2.comp = #ProductionTime.PComponentInterface and t2.opn = #ProductionTime.POperationInterface
End
--Handling interaction between PDT and downtime . Also interaction between PDT and Management Loss
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')='Y'
BEGIN
	---step 1
	
	UPDATE #ProductionTime SET downtime = isnull(downtime,0) + isNull(t2.down,0)
	from
	(select mc,comp,opn,sum(
			CASE
	        WHEN  autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime  THEN  autodata.loadunload
			WHEN (autodata.msttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)  THEN DateDiff(second, @StartTime, ndtime)
			WHEN (autodata.msttime>=@StartTime  and autodata.msttime<@EndTime  and autodata.ndtime>@EndTime)  THEN DateDiff(second, mstTime, @Endtime)
			WHEN autodata.msttime<@StartTime and autodata.ndtime>@EndTime   THEN DateDiff(second, @StartTime, @EndTime)
			END
		)AS down
	from #T_autodata  autodata
	Inner Join MachineInformation M ON autodata.mc=M.InterfaceID
	Inner Join ComponentInformation C ON autodata.Comp=C.InterfaceID
	Inner Join ComponentOperationPricing O ON autodata.Opn=O.InterfaceID AND C.ComponentID=O.ComponentID AND M.MachineID=O.MachineID
	inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
	where autodata.datatype=2 AND
	(
	(autodata.msttime>=@StartTime  and  autodata.ndtime<=@EndTime)
	OR (autodata.msttime<@StartTime and  autodata.ndtime>@StartTime and autodata.ndtime<=@EndTime)
	OR (autodata.msttime>=@StartTime  and autodata.msttime<@EndTime  and autodata.ndtime>@EndTime)
	OR (autodata.msttime<@StartTime and autodata.ndtime>@EndTime )
	) AND (downcodeinformation.availeffy = 0)
	group by mc,comp,opn
	) as t2 inner join #ProductionTime on t2.mc = #ProductionTime.PMachineInterface and t2.comp = #ProductionTime.PComponentInterface and t2.opn = #ProductionTime.POperationInterface
	---step 2
	-- checking for (downcodeinformation.availeffy = 0) to get the overlapping PDT and Downs which is not ML
	UPDATE #PLD set dPlannedDT =isnull(dPlannedDT,0) + isNull(TT.PPDT ,0)
	FROM(
		--Production PDT
		SELECT mc,comp,opn, SUM
		   (CASE
			WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PPDT
		FROM #T_autodata  autodata
		Inner Join MachineInformation M ON autodata.mc=M.InterfaceID
		Inner Join ComponentInformation C ON autodata.Comp=C.InterfaceID
		Inner Join ComponentOperationPricing O ON autodata.Opn=O.InterfaceID AND C.ComponentID=O.ComponentID AND M.MachineID=O.MachineID
		CROSS jOIN #PlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)
			/*AND
			(
			(autodata.sttime >= @StartTime  AND autodata.ndtime <=@EndTime)
			OR ( autodata.sttime < @StartTime  AND autodata.ndtime <= @EndTime AND autodata.ndtime > @StartTime )
			OR ( autodata.sttime >= @StartTime   AND autodata.sttime <@EndTime AND autodata.ndtime > @EndTime )
			OR ( autodata.sttime < @StartTime  AND autodata.ndtime > @EndTime)
			) */ AND (downcodeinformation.availeffy = 0)
		group by mc,comp,opn
	) as TT INNER JOIN #PLD ON TT.mc = #PLD.MachineInterface and TT.comp = #PLD.ComponentInterface and TT.opn = #PLD.OperationInterface
	--select * from #PLD
	---step 3
	---Management loss calculation
	---IN T1 Select get all the downtimes which is of type management loss
	---IN T2  get the time to be deducted from the cycle if the cycle is overlapping with the PDT. And it should be ML record
	---In T3 Get the real management loss , and time to be considered as real down for each cycle(by comaring with the ML threshold)
	---In T4 consolidate everything at machine level and update the same to #ProductionTime for ManagementLoss and MLDown
	
	UPDATE #ProductionTime SET  ManagementLoss = isnull(ManagementLoss,0) + isNull(t4.Mloss,0),MLDown=isNull(MLDown,0)+isNull(t4.Dloss,0)
	from
	(select T3.mc,T3.comp,T3.opn,sum(T3.Mloss) as Mloss,sum(T3.Dloss) as Dloss from (
	select   t1.id,T1.mc,T1.comp,T1.opn,T1.Threshold,
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
		from #T_autodata  autodata
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
		FROM #T_autodata AutoData CROSS jOIN #PlannedDownTimes T inner join downcodeinformation on autodata.dcode=downcodeinformation.interfaceid
		WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)
--			AND
--			(
--			(autodata.sttime >= @StartTime  AND autodata.ndtime <=@EndTime)
--			OR ( autodata.sttime < @StartTime  AND autodata.ndtime <= @EndTime AND autodata.ndtime > @StartTime )
--			OR ( autodata.sttime >= @StartTime   AND autodata.sttime <@EndTime AND autodata.ndtime > @EndTime )
--			OR ( autodata.sttime < @StartTime  AND autodata.ndtime > @EndTime)
--			)
			AND (downcodeinformation.availeffy = 1) group  by autodata.id ) as T2 on T1.id=T2.id ) as T3  group by T3.mc,T3.comp,T3.opn
	) as t4 inner join #ProductionTime on t4.mc = #ProductionTime.PMachineInterface and t4.comp = #ProductionTime.PComponentInterface and t4.opn = #ProductionTime.POperationInterface
	UPDATE #ProductionTime SET downtime = isnull(downtime,0)+isnull(ManagementLoss,0)+isNull(MLDown,0)
END
-- Till here Handling interaction between PDT and downtime . Also interaction between PDT and Management Loss
-- If Ignore_Dtime_4m_PLD<> Y and Ignore_Dtime_4m_PLD<> N
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'Y' AND (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
BEGIN
	UPDATE #PLD set dPlannedDT =isnull(dPlannedDT,0) + isNull(TT.PPDT ,0)
	FROM(
		--Production PDT
		SELECT mc,comp,opn, SUM
		       (CASE
			WHEN autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime  THEN (autodata.loadunload)
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime  AND autodata.ndtime > T.StartTime ) THEN DateDiff(second,T.StartTime,autodata.ndtime)
			WHEN ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime  AND autodata.ndtime > T.EndTime  ) THEN DateDiff(second,autodata.sttime,T.EndTime )
			WHEN ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime ) THEN DateDiff(second,T.StartTime,T.EndTime )
			END ) as PPDT
		FROM #T_autodata AutoData Inner Join MachineInformation M ON autodata.mc=M.InterfaceID
		Inner Join ComponentInformation C ON autodata.Comp=C.InterfaceID
		Inner Join ComponentOperationPricing O ON autodata.Opn=O.InterfaceID AND C.ComponentID=O.ComponentID AND M.MachineID=O.MachineID
		CROSS jOIN #PlannedDownTimes T
		Inner Join DownCodeInformation D ON AutoData.DCode = D.InterfaceID
		WHERE autodata.DataType=2 AND T.MachineInterface=autodata.mc AND D.DownID=(SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD') AND
			(
			(autodata.sttime >= T.StartTime  AND autodata.ndtime <=T.EndTime)
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime <= T.EndTime AND autodata.ndtime > T.StartTime )
			OR ( autodata.sttime >= T.StartTime   AND autodata.sttime <T.EndTime AND autodata.ndtime > T.EndTime )
			OR ( autodata.sttime < T.StartTime  AND autodata.ndtime > T.EndTime)
			)
--			AND
--			(
--			(autodata.sttime >= @StartTime  AND autodata.ndtime <=@EndTime)
--			OR ( autodata.sttime < @StartTime  AND autodata.ndtime <= @EndTime AND autodata.ndtime > @StartTime )
--			OR ( autodata.sttime >= @StartTime   AND autodata.sttime <@EndTime AND autodata.ndtime > @EndTime )
--			OR ( autodata.sttime < @StartTime  AND autodata.ndtime > @EndTime)
--			)--AND (D.availeffy = 0)
		group by mc,comp,opn
	) as TT INNER JOIN #PLD ON TT.mc = #PLD.MachineInterface and TT.comp = #PLD.ComponentInterface and TT.opn = #PLD.OperationInterface
END
--If Ignore_Dtime_4m_PLD<> Y and Ignore_Dtime_4m_PLD<> N
--************************************ Down and Management  Calculation Ends ******************************************

--------------------------------------------Rejcount cal starts--------------------------------------------------------
Update #ProductionTime set RejCount = isnull(RejCount,0) + isnull(T1.RejQty,0)
From
( Select A.mc,a.comp,a.opn,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A
inner join Machineinformation M on A.mc=M.interfaceid
inner join #ProductionTime on #ProductionTime.PMachineID=M.machineid and #ProductionTime.PComponentInterface=a.comp and #ProductionTime.POperationInterface=a.opn
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
where A.CreatedTS>=@StartTime and A.CreatedTS<@Endtime and A.flag = 'Rejection'
and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000'
group by A.mc,M.Machineid,a.comp,a.opn
)T1 inner join #ProductionTime B on B.PMachineID=T1.Machineid and b.PComponentInterface=t1.comp and b.POperationInterface=t1.opn

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	Update #ProductionTime set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from
	(Select A.mc,a.comp,a.opn,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A
	inner join Machineinformation M on A.mc=M.interfaceid 
	inner join #ProductionTime on #ProductionTime.PMachineInterface=a.mc  and #ProductionTime.PComponentInterface=a.comp and #ProductionTime.POperationInterface=a.opn
	inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
	Cross join Planneddowntimes P
	where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid 
	and Isnull(A.Rejshift,'a')='a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')='1900-01-01 00:00:00.000' and
	A.CreatedTS>=@StartTime and A.CreatedTS<@Endtime And
	A.CreatedTS>=P.Starttime and A.CreatedTS<P.endtime
	group by A.mc,M.Machineid,a.comp,a.opn
	)T1 inner join #ProductionTime B on B.PMachineID=T1.Machineid and b.PComponentInterface=t1.comp and b.POperationInterface=t1.opn
END

Update #ProductionTime set RejCount = isnull(RejCount,0) + isnull(T1.RejQty,0)
From
(Select A.mc,a.comp,a.opn, SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A
inner join Machineinformation M on A.mc=M.interfaceid
inner join #ProductionTime on #ProductionTime.PMachineInterface=a.mc and #ProductionTime.PComponentInterface=a.comp and #ProductionTime.POperationInterface=a.opn
inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
inner join #shift S on convert(nvarchar(10),(A.RejDate),126)=convert(nvarchar(10),(S.shiftdate),126) and A.RejShift=S.shiftid --DR0333
where A.flag = 'Rejection' and A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (convert(nvarchar(10),(S.shiftdate),126)) and  --DR0333
Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
group by A.mc,M.Machineid,a.comp,a.opn
)T1 inner join #ProductionTime B on B.PMachineID=T1.Machineid and b.PComponentInterface=t1.comp and b.POperationInterface=t1.opn

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Count_4m_PLD')='Y'
BEGIN
	Update #ProductionTime set RejCount = isnull(RejCount,0) - isnull(T1.RejQty,0) from
	(Select A.mc,a.comp,a.opn,SUM(A.Rejection_Qty) as RejQty,M.Machineid from AutodataRejections A
	inner join Machineinformation M on A.mc=M.interfaceid
	inner join #ProductionTime on #ProductionTime.PMachineInterface=a.mc and #ProductionTime.PComponentInterface=a.comp and #ProductionTime.POperationInterface=a.opn
	inner join Rejectioncodeinformation R on A.Rejection_code=R.interfaceid
	inner join #shift S on convert(nvarchar(10),(A.RejDate),126)=convert(nvarchar(10),(S.shiftdate),126) and A.RejShift=S.shiftid --DR0333
	Cross join Planneddowntimes P
	where P.PDTStatus =1 and A.flag = 'Rejection' and P.machine=M.Machineid and
	A.Rejshift in (S.shiftid) and convert(nvarchar(10),(A.RejDate),126) in (convert(nvarchar(10),S.shiftdate,126)) and --DR0333
	Isnull(A.Rejshift,'a')<>'a' and Isnull(A.RejDate,'1900-01-01 00:00:00.000')<>'1900-01-01 00:00:00.000'
	and P.starttime>=S.Shiftstart and P.Endtime<=S.shiftend
	group by A.mc,M.Machineid,a.comp,a.opn
	)T1 inner join #ProductionTime B on B.PMachineID=T1.Machineid and b.PComponentInterface=t1.comp  and b.POperationInterface=t1.opn
END
-------------------------------------------------Rejcount cal ends-----------------------------------------------
---ER0210 till here
--ER0210: Update Utilised Time and Down time
UPDATE #ProductionTime
	SET UtilisedTime=(UtilisedTime-ISNULL(#PLD.pPlannedDT,0)+isnull(#PLD.IPlannedDT,0)),
	    DownTime=(DownTime-ISNULL(#PLD.dPlannedDT,0))
	From #ProductionTime Inner Join #PLD on #PLD.Machineid=#ProductionTime.PMachineid
	and #PLD.ComponentID=#ProductionTime.PComponentID and #PLD.OperationNo=#ProductionTime.POperationNo
---ER0210
--Calculate Availability Efficiency,Production Efficiency,Overall Efficiency


--UPDATE #ProductionTime SET QualityEfficiency= ISNULL(QualityEfficiency,0) + IsNull(T1.QE,0) 
--FROM(Select PMachineID,PComponentID,POperationNo,
--CAST((Sum(ProdCount))As Float)/CAST((Sum(IsNull(ProdCount,0))+Sum(IsNull(RejCount,0))) AS Float)As QE
--From #ProductionTime Where ProdCount<>0 Group By pmachineid,PComponentID,POperationNo
--)AS T1 Inner Join #ProductionTime ON  #ProductionTime.PMachineID=T1.PMachineID and #ProductionTime.PComponentID=t1.PComponentID and #ProductionTime.POperationNo=t1.POperationNo

UPDATE #ProductionTime SET QualityEfficiency= ISNULL(QualityEfficiency,0) + IsNull(T1.QE,0) 
FROM(Select PMachineID,PComponentID,POperationNo,
cast((Sum(isnull(ProdCount,0))-Sum(IsNull(RejCount,0))) as float)/CAST((Sum(IsNull(ProdCount,0))) AS Float)As QE
From #ProductionTime Where ProdCount<>0 Group By pmachineid,PComponentID,POperationNo
)AS T1 Inner Join #ProductionTime ON  #ProductionTime.PMachineID=T1.PMachineID and #ProductionTime.PComponentID=t1.PComponentID and #ProductionTime.POperationNo=t1.POperationNo


	UPDATE #ProductionTime SET
	--ProductionEfficiency=(CNprodcount * StdCycleTime)/(UtilisedTime),--ER0210
	--ProductionEfficiency=(prodcount * StdCycleTime)/(UtilisedTime), --DR0285
   ProductionEfficiency=(prodcount * (StdCycleTime + StdLoadUnload))/(UtilisedTime), --DR0285
	AvailabilityEfficiency=(UtilisedTime )/(UtilisedTime +DownTime- ManagementLoss)
	WHERE UtilisedTime<>0
	 

	UPDATE #ProductionTime SET
	ProductionEfficiency=ProductionEfficiency * 100,
	AvailabilityEfficiency=AvailabilityEfficiency * 100,
	QualityEfficiency=QualityEfficiency*100,
	--OverAllEfficiency=ProductionEfficiency*AvailabilityEfficiency * 100,
	OverAllEfficiency=ProductionEfficiency*AvailabilityEfficiency*QualityEfficiency * 100,
	TurnOver=ProdCount*Price
	


			  SELECT
			  PComponentID AS ComponentID ,
			  POperationNo AS OperationNo ,
			  PMachineID AS MachineID ,--ER0181 By Karthik G on 29-Sep-2009	
			  PMachinedescription as Machinedescription,
			  Price AS Price	,
			  dbo.f_FormatTime(UtilisedTime,@TimeFormat) AS UtilisedTime,
			  Round(ProdCount,2) as ProdCount, --NR0097 Added Round Funtion
			  Round(RejCount,2) as rejcount, --NR0097 Added Round Funtion
			  dbo.f_FormatTime(DownTime, @TimeFormat) AS DownTime  ,
			  dbo.f_FormatTime(ManagementLoss,@TimeFormat) AS ManagementLoss,
			  dbo.f_FormatTime(StdCycleTime,@TimeFormat) AS StdCycleTime ,
			  dbo.f_FormatTime(AvgCycleTime,@TimeFormat) AS AvgCycleTime,
			  dbo.f_FormatTime(MinCycleTime,@TimeFormat) AS MinCycleTime ,
			  dbo.f_FormatTime(MaxCycleTime,@TimeFormat) AS MaxCycleTime,
			  --dbo.f_FormatTime(SpeedRation,@TimeFormat) AS SpeedRation, --DR0260 - SyedArifM - 29/Sep/2010
			  --CEILING(SpeedRation) AS SpeedRation,--DR0260 - SyedArifM - 29/Sep/2010		
			  round(isnull(SpeedRation,0),2) AS SpeedRation,--DR0260 - SyedArifM - 29/Sep/2010				
			  dbo.f_FormatTime(StdLoadUnload,@TimeFormat) AS StdLoadUnload,
			  dbo.f_FormatTime(AvgLoadUnload,@TimeFormat) AS AvgLoadUnload ,
			  dbo.f_FormatTime(MinLoadUnload,@TimeFormat) AS MinLoadUnload ,
			  dbo.f_FormatTime(MaxLoadUnload,@TimeFormat) AS MaxLoadUnload,
		          --dbo.f_FormatTime(LoadRation,@TimeFormat) AS LoadRation, --DR0260 - SyedArifM - 29/Sep/2010
			  --CEILING(LoadRation) AS LoadRation,--DR0260 - SyedArifM - 29/Sep/2010
			  round(isnull(LoadRation,0),2) AS LoadRation,--DR0260 - SyedArifM - 29/Sep/2010
			  ROUND(Isnull(AvailabilityEfficiency,0),2) as AvailabilityEfficiency,
			  ROUND(Isnull(ProductionEfficiency,0),2) as ProductionEfficiency,
			  ROUND(Isnull(QualityEfficiency,0),2) as QualityEfficiency,
			  ROUND(Isnull(OverAllEfficiency,0),2) as OverAllEfficiency,
			  Isnull(TurnOver,0) as TurnOver
			  FROM #ProductionTime order by PComponentID,POperationNo,PMachineID

END
