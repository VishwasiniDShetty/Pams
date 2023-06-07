/****** Object:  Procedure [dbo].[SP_MachineWisePlnQtySaveAndView_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

/*
SP_MachineWisePlnQtySaveAndView_PAMS '''THRU GRINDING''','2023','05','18','DefaultView',''
*/
CREATE PROCEDURE [dbo].[SP_MachineWisePlnQtySaveAndView_PAMS]
@Group nvarchar(max)='',
@Year nvarchar(40)='',
@MonthValue nvarchar(5)='',
@WeekNumber nvarchar(4)='',
@Param nvarchar(50)='',
@MachineID NVARCHAR(MAX)='',
@ComponentID NVARCHAR(MAX)='',
@OperationNo nvarchar(max)=''

as
begin

	create table #MachineLevelPlanScreen
	(
	Year nvarchar(4),
	MonthVal nvarchar(10),
	WeekNumber nvarchar(4),
	CustomerID NVARCHAR(50),
	MachineID NVARCHAR(50),
	MachineInterface nvarchar(50),
	Description nvarchar(100),
	PartInterface nvarchar(50),
	PartID NVARCHAR(50),
	PartName nvarchar(100),
	OperationNo int,
	GroupID nvarchar(50),
	MonthlyRequiredQty float,
	WeeklyRequiredQty float,
	ProductionPlanned float,
	PerDayHitRate float,
    Prod_Hours_WithoutDressing float,
	GrindingWheelDress_Freq float,
	GrindingWheelDress_Time float,
	GrindingWheelDress_Time_Hrs float,
	RegulatingDressingTime_InMin float,
	RegulatingDressingTime_InHrs float,
	Total_Time_Required_Hrs float,
	Total_Time_RequiredPerDay_Hrs float,
	Date DATETIME,
	PDT FLOAT,
	LogicalDayStart datetime,
	LogicalDayEnd datetime,
	DayWisePlnQty float,
	DayWiseActualQty float default 0,
	TotalProductionAchieved float default 0,
	WeeklyBacklog float default 0,
	Remarks nvarchar(max) default '',
	UpdatedBy NVARCHAR(50),
	UpdatedTS DATETIME,
	CycleTime float default 0,
	OutputPerHour float default 0,
	TotalTimeRequiredWithoutPDT float,
	TypesOfParts float,
	TotalTimeInHours float,
	TransactionBit int default 0,
	ScheduledDates nvarchar(max),
	PreferredMachineBit int,
	ColorIndication int,
	NoOfDefaultMachinesForThePart float
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
	[msttime] [datetime] not NULL,
	[PartsCount] decimal(18,5) NULL ,
	id  bigint not null
	)

	ALTER TABLE #T_autodata

	ADD PRIMARY KEY CLUSTERED
	(
		mc,sttime,ndtime,msttime ASC
	)ON [PRIMARY]

	declare @strsql nvarchar(max)
	select @strsql=''
	Declare @T_ST AS Datetime 
	Declare @T_ED AS Datetime 

	DECLARE @strMachineID NVARCHAR(MAX)
	DECLARE @strComponentID NVARCHAR(MAX)
	DECLARE @strOperationNo NVARCHAR(MAX)
	declare @StrYear nvarchar(1000)
	declare @StrMonthValue nvarchar(1000)
	declare @StrWeekNumber nvarchar(1000)
	declare @StrGroup nvarchar(2000)
	select @StrGroup=''
	select @strComponentID=''
	select @strOperationNo=''
	select @StrMonthValue=''
	select @StrYear=''
	select @strsql=''
	SELECT @strMachineID=''

	if isnull(@year,'')<>''
	begin
		select @StrYear='And D1.Year=N'''+@Year+''' '
	END

	if isnull(@MonthValue,'')<>''
	begin
		select @StrMonthValue='And D1.MonthValue=N'''+@MonthValue+''' '
	END

	if isnull(@WeekNumber,'')<>''
	begin
		select @StrWeekNumber='And D1.WeekNumber=N'''+@WeekNumber+''' '
	END

	if isnull(@Group,'')<>''
	begin
		select @StrGroup='And p1.GroupID in ('+@Group+')'
	END

	IF ISNULL(@MachineID,'')<>''
	BEGIN
		SELECT @strMachineID='And m1.Machineid in ('+@MachineID+')'
	end

		IF ISNULL(@ComponentID,'')<>''
	BEGIN
		SELECT @strComponentID='And c1.ComponentID in ('+@ComponentID+')'
	end

		IF ISNULL(@OperationNo,'')<>''
	BEGIN
		SELECT @strOperationNo='And c2.operationno in ('+@OperationNo+')'
	end

	--insert into #MachineLevelPlanScreen(Year,MonthVal,WeekNumber,CustomerID,MachineID,MachineInterface,Description,PartID,PartName,PartInterface,OperationNo,GroupID,Date,LogicalDayStart,LogicalDayEnd)
	--SELECT DISTINCT Year,MonthValue,WeekNumber,D1.CustomerID,m1.machineid,m1.InterfaceID,m1.description,PartID,C1.description,c1.interfaceid,c2.operationno,P1.GroupID,Date,dbo.f_GetLogicalDay(date,'start'),dbo.f_GetLogicalDay(date,'end') FROM DayWiseScheduleDetails_PAMS D1
	--INNER JOIN componentinformation C1 ON C1.componentid=D1.PartID
	--INNER JOIN componentoperationpricing C2 ON C1.componentid=C2.componentid
	--INNER JOIN machineinformation M1 ON M1.machineid=C2.machineid
	--INNER JOIN PlantMachineGroups P1 ON P1.MachineID=M1.machineid
	--WHERE D1.Year=@Year AND D1.MonthValue=@MonthValue AND D1.WeekNumber=@WeekNumber AND P1.GroupID=@Group


	select @strsql=@strsql+'insert into #MachineLevelPlanScreen(Year,MonthVal,WeekNumber,CustomerID,MachineID,MachineInterface,Description,PartID,PartName,PartInterface,OperationNo,GroupID,Date,LogicalDayStart,LogicalDayEnd,CycleTime)
	SELECT DISTINCT Year,MonthValue,WeekNumber,D1.CustomerID,m1.machineid,m1.InterfaceID,m1.description,PartID,C1.description,c1.interfaceid,c2.operationno,P1.GroupID,Date,dbo.f_GetLogicalDay(date,''start''),dbo.f_GetLogicalDay(date,''end''),c2.CycleTime FROM DayWiseScheduleDetails_PAMS D1
	INNER JOIN componentinformation C1 ON C1.componentid=D1.PartID
	INNER JOIN componentoperationpricing C2 ON C1.componentid=C2.componentid
	INNER JOIN machineinformation M1 ON M1.machineid=C2.machineid
	INNER JOIN PlantMachineGroups P1 ON P1.MachineID=M1.machineid where 1=1 '
	select @strsql=@strsql+@StrYear+@StrMonthValue+@StrWeekNumber+@StrGroup+@strMachineID+@strComponentID+@strOperationNo
	print(@strsql)
	exec(@strsql)



	declare @StartTime datetime
	declare @EndTime datetime

	select @StartTime=(select min(Date) from #MachineLevelPlanScreen)
	select @EndTime=(select max(Date) from #MachineLevelPlanScreen)

	Select @T_ST=dbo.f_GetLogicalDay(@StartTime,'start')
	Select @T_ED=dbo.f_GetLogicalDay(@EndTime,'end')
	

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


	UPDATE #MachineLevelPlanScreen SET MonthlyRequiredQty=isnull(T1.Monthlyqty,0)
	from
	(
	select distinct YearNo,MonthVal,partid,PlannedQty as Monthlyqty from MonthlyScheduleDetails_Pams where YearNo=@Year and MonthVal=@MonthValue
	) 
	t1 inner join #MachineLevelPlanScreen on #MachineLevelPlanScreen.Year=t1.YearNo and #MachineLevelPlanScreen.MonthVal=t1.MonthVal and #MachineLevelPlanScreen.PartID=t1.PartID

	
	--UPDATE #MachineLevelPlanScreen SET WeeklyRequiredQty=isnull(T1.WeeklyQty,0)
	--from
	--(
	--select distinct year,monthval,partid,(MonthlyRequiredQty/(select count(distinct weeknumber) as CountOfWeeks from DayWiseScheduleDetails_PAMS where Year=@Year and MonthValue=@MonthValue)) as WeeklyQty from #MachineLevelPlanScreen 
	--) 
	--t1 inner join #MachineLevelPlanScreen on #MachineLevelPlanScreen.Year=t1.Year and #MachineLevelPlanScreen.MonthVal=t1.MonthVal and #MachineLevelPlanScreen.PartID=t1.PartID
	
	UPDATE #MachineLevelPlanScreen SET WeeklyRequiredQty=isnull(T1.WeeklyQty,0)
	from
	(
		select distinct Year,MonthValue,WeekNumber,partid,sum(PlannedQty) as WeeklyQty  from DayWiseScheduleDetails_PAMS
		where  Year=@Year and MonthValue=@MonthValue and WeekNumber=@WeekNumber
		group by Year,MonthValue,WeekNumber,partid
	) 
	t1 inner join #MachineLevelPlanScreen on #MachineLevelPlanScreen.Year=t1.Year and #MachineLevelPlanScreen.MonthVal=t1.MonthValue and #MachineLevelPlanScreen.WeekNumber=t1.WeekNumber and #MachineLevelPlanScreen.PartID=t1.PartID


	update #MachineLevelPlanScreen set ProductionPlanned=isnull(t1.ProductionPlanned,0)
	from
	(
	select distinct Year,MonthValue,WeekNumber,partid,sum(PlannedQty) as ProductionPlanned  from DayWiseScheduleDetails_PAMS where Year=@Year and MonthValue=@MonthValue and WeekNumber=@WeekNumber
	group by Year,MonthValue,WeekNumber,partid
	)
	t1 inner join #MachineLevelPlanScreen on #MachineLevelPlanScreen.Year=t1.Year and #MachineLevelPlanScreen.MonthVal=t1.MonthValue and #MachineLevelPlanScreen.WeekNumber=t1.WeekNumber and #MachineLevelPlanScreen.PartID=t1.PartID

	UPDATE #MachineLevelPlanScreen SET PerDayHitRate=isnull(T1.PerDayHitRate,0)
	from
	(
	select distinct year,monthval,partid, (MonthlyRequiredQty/(select count(distinct date) as CountOfdays from DayWiseScheduleDetails_PAMS where Year=@Year and MonthValue=@MonthValue)) as PerDayHitRate from #MachineLevelPlanScreen 
	) 
	t1 inner join #MachineLevelPlanScreen on #MachineLevelPlanScreen.Year=t1.Year and #MachineLevelPlanScreen.MonthVal=t1.MonthVal  and #MachineLevelPlanScreen.PartID=t1.PartID

	update #MachineLevelPlanScreen set NoOfDefaultMachinesForThePart=isnull(t1.NoOfDefaultMachinesForThePart,0)
	from
	(
		select distinct p1.PartID,p1.OperationNo,count(distinct p1.PreferredMachineid) as NoOfDefaultMachinesForThePart from PreferredMachineDetails_Pams p1
		--inner join #MachineLevelPlanScreen m1 on m1.MachineID=p1.PreferredMachineid and m1.PartID= p1.PartID and m1.OperationNo=p1.OperationNo
		group by p1.PartID,p1.OperationNo
	) t1 inner join #MachineLevelPlanScreen m1 on m1.PartID=t1.PartID and m1.OperationNo=t1.OperationNo

	--select * from #MachineLevelPlanScreen where PartID='R1071030'
	--return

	UPDATE #MachineLevelPlanScreen SET PerDayHitRate=isnull(T1.PerDayHitRate,0)
	from
	(
	select distinct year,monthval,partid,operationno, (PerDayHitRate)/(NoOfDefaultMachinesForThePart) as PerDayHitRate from #MachineLevelPlanScreen 
	) 
	t1 inner join #MachineLevelPlanScreen on #MachineLevelPlanScreen.Year=t1.Year and #MachineLevelPlanScreen.MonthVal=t1.MonthVal  and #MachineLevelPlanScreen.PartID=t1.PartID
	and #MachineLevelPlanScreen.OperationNo=t1.OperationNo

	--select * from #MachineLevelPlanScreen where PartID='R1071030'
	--return

		-----------------------------------------------------------pick data from pjcedit details if production data entered manually ------------------------------------------------------------------------


	update #MachineLevelPlanScreen set DayWiseActualQty=isnull(t1.prodqty,0)
	from
	(
		select distinct p1.date,p1.Machineid,p1.partid,p1.operationno, sum(Prod_Qty) as prodqty from PJCProductionEditedDetails_PAMS p1
		group by p1.date,p1.partid,p1.Machineid,p1.operationno
	) t1 inner join #MachineLevelPlanScreen t2 on t1.Date=t2.Date and t1.PartID=t2.PartID and t1.Machineid=t2.MachineID and t1.OperationNo=t2.OperationNo --and isnull(t2.DayWiseActualQty,0)=0

	-----------------------------------------------------------pick data from pjcedit details if production data entered manually ------------------------------------------------------------------------

	----------------------------------------------------------pick data from autodata if production data is zero-----------------------------------------------------------------------------------------

	UPDATE #MachineLevelPlanScreen SET DayWiseActualQty = ISNULL(DayWiseActualQty,0) + ISNULL(t2.Component,0)
	FROM
	(
		SELECT MC,COMP,OPN,T1.LogicalDayStart,SUM((CAST(T1.OrginalCount AS FLOAT)/ISNULL(O.SubOperations,1))) AS Component 
		FROM (SELECT mc,T2.LogicalDayStart,SUM(autodata.partscount)AS OrginalCount,comp,opn 
		FROM #T_autodata autodata --ER0374
		INNER JOIN #MachineLevelPlanScreen T2 ON AUTODATA.mc=T2.MachineInterface AND autodata.comp=T2.PartInterface AND autodata.opn=T2.OperationNo
		WHERE (autodata.ndtime>T2.LogicalDayStart) AND (autodata.ndtime<=T2.LogicalDayEnd) AND (autodata.datatype=1)
		GROUP BY mc,T2.LogicalDayStart,comp,opn) AS T1
		INNER JOIN componentinformation C ON T1.Comp = C.interfaceid
		INNER JOIN ComponentOperationPricing O ON  T1.Opn = O.interfaceid AND C.Componentid=O.componentid
		INNER JOIN machineinformation ON machineinformation.machineid =O.machineid
		AND T1.mc=machineinformation.interfaceid
		GROUP BY MC,COMP,opn,T1.LogicalDayStart
	) AS T2 INNER JOIN #MachineLevelPlanScreen ON T2.mc=#MachineLevelPlanScreen.MachineInterface AND T2.comp = #MachineLevelPlanScreen.partinterface
	 AND T2.opn=#MachineLevelPlanScreen.OperationNo AND T2.LogicalDayStart=#MachineLevelPlanScreen.LogicalDayStart and ISNULL(#MachineLevelPlanScreen.DayWiseActualQty,0)=0

	----------------------------------------------------------pick data from autodata if production data is zero-----------------------------------------------------------------------------------------


	update #MachineLevelPlanScreen set TotalProductionAchieved=isnull(totalprod,0)
	from
	(select distinct year,monthval,weeknumber,partid, sum(DayWiseActualQty) as totalprod from #MachineLevelPlanScreen
	group by  year,monthval,weeknumber,PartID
	)t1 inner join #MachineLevelPlanScreen on #MachineLevelPlanScreen.Year=t1.Year and #MachineLevelPlanScreen.MonthVal=t1.MonthVal and #MachineLevelPlanScreen.WeekNumber=t1.WeekNumber
	and #MachineLevelPlanScreen.PartID=t1.PartID

	update #MachineLevelPlanScreen set WeeklyBacklog=isnull(t1.WeeklyBacklog,0)
	from
	(select distinct Year,MonthVal,WeekNumber,PartID,(ProductionPlanned-TotalProductionAchieved) as WeeklyBacklog from #MachineLevelPlanScreen
	)t1 inner join #MachineLevelPlanScreen on #MachineLevelPlanScreen.Year=t1.Year and #MachineLevelPlanScreen.MonthVal=t1.MonthVal and #MachineLevelPlanScreen.WeekNumber=t1.WeekNumber and #MachineLevelPlanScreen.PartID=t1.partid

	--update #MachineLevelPlanScreen set ReasonForBackLog=isnull(t1.ReasonForBackLog,'')
	--from
	--(select distinct Year,MonthValue,WeekNumber,PartID,ReasonForBackLog from DayWiseScheduleDetails_PAMS where Year=@Year and MonthValue=@MonthValue and WeekNumber=@WeekNumber
	--)t1 inner join #MachineLevelPlanScreen on t1.Year=#MachineLevelPlanScreen.Year and t1.MonthValue=#MachineLevelPlanScreen.MonthVal and t1.WeekNumber=#MachineLevelPlanScreen.WeekNumber

	update #MachineLevelPlanScreen set DayWisePlnQty=isnull(t1.PlanQty,0),Remarks=isnull(t1.Remarks,''),updatedby=isnull(t1.updatedby,''),
	UpdatedTS=isnull(t1.updatedts,'')
	from
	(
	select distinct Year,MonthValue,WeekNumber,Date,MachineID,PartID,Operationno,PlanQty,Remarks,updatedby,updatedts,1 as TransactionBit,ScheduledDates  from MachineWisePlnQtyDetails_PAMS where YEAR=@Year and MonthValue=@MonthValue and WeekNumber=@WeekNumber
	)
	t1 inner join #MachineLevelPlanScreen on #MachineLevelPlanScreen.Year=t1.Year and #MachineLevelPlanScreen.MonthVal=t1.MonthValue and #MachineLevelPlanScreen.WeekNumber=t1.WeekNumber 
	and #MachineLevelPlanScreen.MachineID=t1.machineid and #MachineLevelPlanScreen.PartID=t1.partid and #MachineLevelPlanScreen.OperationNo=t1.Operationno and #MachineLevelPlanScreen.Date=t1.Date

		update #MachineLevelPlanScreen set TransactionBit=isnull(t1.TransactionBit,0),ScheduledDates =isnull(t1.ScheduledDates,'') 
	from
	(
	select distinct Year,MonthValue,WeekNumber,MachineID,PartID,Operationno,1 as TransactionBit,ScheduledDates  from MachineWisePlnQtyDetails_PAMS where YEAR=@Year and MonthValue=@MonthValue and WeekNumber=@WeekNumber
	)
	t1 inner join #MachineLevelPlanScreen on #MachineLevelPlanScreen.Year=t1.Year and #MachineLevelPlanScreen.MonthVal=t1.MonthValue and #MachineLevelPlanScreen.WeekNumber=t1.WeekNumber 
	and #MachineLevelPlanScreen.MachineID=t1.machineid and #MachineLevelPlanScreen.PartID=t1.partid and #MachineLevelPlanScreen.OperationNo=t1.Operationno 

	--------------------------------------------------------------OutputPerHour cal starts-----------------------------------------------------------------------------------------
	update #MachineLevelPlanScreen set OutputPerHour=ROUND(isnull((3600/cycletime),0),0)

	--------------------------------------------------------------OutputPerHour cal ENDS-----------------------------------------------------------------------------------------

	--------------------------------------------------------------ProductionTmewithoutdressing cal starts-----------------------------------------------------------------------------------------
	
	update #MachineLevelPlanScreen set Prod_Hours_WithoutDressing=isnull(PerDayHitRate,0)/isnull(OutputPerHour,0) 
	where isnull(OutputPerHour,0)>0

	--------------------------------------------------------------ProductionTmewithoutdressing cal ends-----------------------------------------------------------------------------------------

		update #MachineLevelPlanScreen set pdt=isnull(t1.pdt,0)
	from
	(
		select m1.LogicalDayStart,m1.LogicalDayEnd,MachineID,sum(distinct DATEDIFF(second,StartTime,EndTime)) as PDT from PlannedDownTimes m2
		inner join (select distinct LogicalDayStart,LogicalDayEnd,MachineID from #MachineLevelPlanScreen) m1 on m1.MachineID=m2.Machine and (m2.StartTime>=m1.LogicalDayStart and m2.EndTime<=m1.LogicalDayEnd)
		group by m1.LogicalDayStart,m1.LogicalDayEnd,MachineID
	) T1 INNER JOIN #MachineLevelPlanScreen T2 ON T1.LogicalDayStart=T2.LogicalDayStart AND T1.LogicalDayEnd=T2.LogicalDayEnd AND T1.MachineID=T2.MachineID

	
	--update #MachineLevelPlanScreen set pdt=isnull(t1.pdt,0)
	--from
	--(
	--	select m1.LogicalDayStart,m1.LogicalDayEnd,MachineID,sum(distinct DATEDIFF(second,StartTime,EndTime)) as PDT from #MachineLevelPlanScreen m1
	--	inner join PlannedDownTimes m2 on m1.MachineID=m2.Machine and (m2.StartTime>=m1.LogicalDayStart and m2.EndTime<=m1.LogicalDayEnd)
	--	group by m1.LogicalDayStart,m1.LogicalDayEnd,MachineID
	--) T1 INNER JOIN #MachineLevelPlanScreen T2 ON T1.LogicalDayStart=T2.LogicalDayStart AND T1.LogicalDayEnd=T2.LogicalDayEnd AND T1.MachineID=T2.MachineID

	UPDATE #MachineLevelPlanScreen SET TotalTimeRequiredWithoutPDT=(DATEDIFF(SECOND,LogicalDayStart,LogicalDayEnd))-isnull(PDT,0)

	update #MachineLevelPlanScreen set TotalTimeInHours=(TotalTimeRequiredWithoutPDT/3600)


	--update #MachineLevelPlanScreen set TypesOfParts=isnull(t1.TypesOfParts,0)
	--from
	--(
	--	select machineid,count(distinct partid) as TypesOfParts  from #MachineLevelPlanScreen
	--	group by machineid
	--) t1 inner join #MachineLevelPlanScreen t2 on t1.MachineID=t2.MachineID 

	--update #MachineLevelPlanScreen set TotalTimeInHours=((TotalTimeRequiredWithoutPDT/3600)/TypesOfParts)


	--UPDATE #MachineLevelPlanScreen SET DayWisePlnQty=ISNULL(T1.PerDayHitRate,0),PreferredMachineBit=isnull(t1.PreferredMachineBit,0)
	--FROM
	--(
	--SELECT DISTINCT YEAR , MonthVal,WeekNumber, M1.MachineID, M1.PARTID,M1.OperationNo,PerDayHitRate,1 as PreferredMachineBit FROM #MachineLevelPlanScreen M1
	--INNER JOIN PreferredMachineDetails_Pams M2 ON M1.MachineID=M2.PreferredMachineid AND M1.PartID=M2.PartID AND M1.Operationno=M2.OperationNo
	--) T1 INNER JOIN #MachineLevelPlanScreen T2 ON T1.Year=T2.Year AND T1.MonthVal=T2.MonthVal and t1.WeekNumber=t2.WeekNumber AND T1.PartID=T2.PartID AND T1.MachineID=T2.MachineID AND T1.OperationNo=T2.OperationNo

	UPDATE #MachineLevelPlanScreen SET PreferredMachineBit=isnull(t1.PreferredMachineBit,0)
	FROM
	(
	SELECT DISTINCT YEAR , MonthVal,WeekNumber, M1.MachineID, M1.PARTID,M1.OperationNo,PerDayHitRate,1 as PreferredMachineBit FROM #MachineLevelPlanScreen M1
	INNER JOIN PreferredMachineDetails_Pams M2 ON M1.MachineID=M2.PreferredMachineid AND M1.PartID=M2.PartID AND M1.Operationno=M2.OperationNo
	) T1 INNER JOIN #MachineLevelPlanScreen T2 ON T1.Year=T2.Year AND T1.MonthVal=T2.MonthVal and t1.WeekNumber=t2.WeekNumber AND T1.PartID=T2.PartID AND T1.MachineID=T2.MachineID AND T1.OperationNo=T2.OperationNo

	UPDATE #MachineLevelPlanScreen SET DayWisePlnQty=ISNULL(T1.PlanQty,0)
	FROM
	(
	SELECT YEAR,MonthValue,WeekNumber,Date,MachineID,M1.PartID,M1.Operationno,PlanQty FROM MachineWisePlnQtyDetails_PAMS M1
	) T1 INNER JOIN #MachineLevelPlanScreen T2 ON T1.Year=T2.Year AND T1.MonthValue=T2.MonthVal AND T1.WeekNumber=T2.WeekNumber AND T1.Date=T2.Date AND T1.MachineID=T2.MachineID AND T1.Operationno=T2.OperationNo AND T1.PartID=T2.PartID  

		UPDATE #MachineLevelPlanScreen SET PreferredMachineBit=isnull(t1.PreferredMachineBit,0)
	FROM
	(
	SELECT YEAR,MonthValue,WeekNumber,MachineID,M1.PartID,M1.Operationno,2 as PreferredMachineBit FROM MachineWisePlnQtyDetails_PAMS M1
	) T1 INNER JOIN #MachineLevelPlanScreen T2 ON T1.Year=T2.Year AND T1.MonthValue=T2.MonthVal AND T1.WeekNumber=T2.WeekNumber AND T1.MachineID=T2.MachineID AND T1.Operationno=T2.OperationNo AND T1.PartID=T2.PartID  

	
	update #MachineLevelPlanScreen set GrindingWheelDress_Freq=isnull(t1.grindingwheeldressingfrequency,0),GrindingWheelDress_Time=isnull(t1.Grindingwheeldressingtime,0),
	RegulatingDressingTime_InMin=isnull(t1.RegulatingdressingTimeInMin,0)
	from
	(
	select distinct Year,MonthValue,WeekNumber,MachineID,PartID,OperationNo,grindingwheeldressingfrequency,Grindingwheeldressingtime,RegulatingdressingTimeInMin from MachineWisePlnQtyDetails_PAMS
	) t1 inner join #MachineLevelPlanScreen t2 on t1.Year=t2.Year and t1.MonthValue=t2.MonthVal and t1.WeekNumber=t2.WeekNumber AND T1.MachineID =T2.MachineID
	AND T1.PartID=T2.PartID AND T1.Operationno=T2.OperationNo

	update #MachineLevelPlanScreen set Total_Time_Required_Hrs=isnull(t1.Total_Time_Required_Hrs,0)
	from
	(
	select distinct Year,MonthValue,WeekNumber,MachineID,PartID,Operationno,Total_Time_Required_Hrs from MachineWisePlnQtyDetails_PAMS  
	where YEAR=@Year and MonthValue=@MonthValue and WeekNumber=@WeekNumber
	) t1 inner join #MachineLevelPlanScreen t2 on t1.Year=t2.Year and t1.MonthValue=t2.MonthVal and t1.WeekNumber=t2.WeekNumber and 
	t1.MachineID=t2.MachineID and t1.PartID=t2.PartID and  t1.Operationno=t2.OperationNo

	update #MachineLevelPlanScreen set Total_Time_RequiredPerDay_Hrs=isnull(t1.Total_Time_RequiredPerDay_Hrs,0)
	from
	(
	select distinct Year,MonthValue,WeekNumber,MachineID,Total_Time_RequiredPerDay_Hrs from MachineWisePlnQtyDetails_PAMS  
	where YEAR=@Year and MonthValue=@MonthValue and WeekNumber=@WeekNumber
	) t1 inner join #MachineLevelPlanScreen t2 on t1.Year=t2.Year and t1.MonthValue=t2.MonthVal and t1.WeekNumber=t2.WeekNumber and 
	t1.MachineID=t2.MachineID 


	--select * from #MachineLevelPlanScreen where PreferredMachineBit='1' and MachineID='SMT-CNC' and OperationNo='40'
	--return

	if @Param='DefaultView'
	begin
		SELECT Year,MonthVal,WeekNumber,CustomerID,GroupID,m1.MachineID,m1.MachineInterface,Description,m1.PartID,m1.PartInterface,m1.PartName,m1.OperationNo,CycleTime,round(isnull(WeeklyRequiredQty,0),0) as WeeklyRequiredQty,round(isnull(ProductionPlanned,0),0) as ProductionPlanned,
		round(isnull(PerDayHitRate,0),0) as PerDayHitRate,Date,LogicalDayStart,LogicalDayEnd,
		case when isnull(PreferredMachineBit,0)=1 then  round(isnull(PerDayHitRate,0),0) else DayWisePlnQty end as DayWisePlnQty,round(isnull(DayWiseActualQty,0),0) as DayWiseActualQty,Remarks,m1.UpdatedBy,m1.UpdatedTS,
		ROUND(isnull(OutputPerHour,0),0) as OutputPerHour,
		round(isnull(Prod_Hours_WithoutDressing,0),1) as Prod_Hours_WithoutDressing,
		round(isnull(GrindingWheelDress_Freq,0),0) as GrindingWheelDress_Freq,
		round(isnull(GrindingWheelDress_Time,0),0) as GrindingWheelDress_Time,
		round(isnull(RegulatingDressingTime_InMin,0),0) as RegulatingDressingTime_InMin,
		round(isnull(MonthlyRequiredQty,0),0) as MonthlyRequiredQty,
		isnull(TransactionBit,0) as TransactionBit,isnull(ScheduledDates,'') as ScheduledDates,
		isnull(PreferredMachineBit,0) as  PreferredMachineBit,
		isnull(Total_Time_Required_Hrs,0) as Total_Time_Required_Hrs,
		isnull(Total_Time_RequiredPerDay_Hrs,0) as Total_Time_RequiredPerDay_Hrs,
		isnull(TotalTimeInHours,0) as TotalTimeAvailableInHours,
		case when isnull(TotalTimeInHours,0)<isnull(Total_Time_RequiredPerDay_Hrs,0) then 'Red' else 'Green' END ColoringBit
		--,round(isnull((perdayhitrate/OutputPerHour),0),0) as TotalTimeRequiredInHrs
		from #MachineLevelPlanScreen m1
		where PreferredMachineBit in ('1','2')
		order by MachineID,PartID,OperationNo
		--inner join PreferredMachineDetails_Pams m2 on m1.MachineID=m2.PreferredMachineid and m1.PartID=m2.PartID and m1.OperationNo=m2.OperationNo
	
		--FROM #MachineLevelPlanScreen
		--RETURN

		SELECT distinct CustomerID,Year,MonthVal,WeekNumber,MachineID,PartID,Operationno, ScheduledDates,GrindingWheelDress_Freq,GrindingWheelDress_Time,RegulatingDressingTime_InMin,Remarks
		from #MachineLevelPlanScreen m1  where PreferredMachineBit in ('2')
		order by MachineID,PartID,OperationNo

	end

	if @Param='AddPlanView'
	begin
	SELECT Year,MonthVal,WeekNumber,CustomerID,GroupID,m1.MachineID,m1.MachineInterface,Description,m1.PartID,m1.PartInterface,m1.PartName,m1.OperationNo,CycleTime,WeeklyRequiredQty,round(isnull(ProductionPlanned,0),0) as ProductionPlanned,
		round(isnull(PerDayHitRate,0),0) as PerDayHitRate,Date,LogicalDayStart,LogicalDayEnd,
		case when isnull(PreferredMachineBit,0)=1 then  round(isnull(PerDayHitRate,0),0) else DayWisePlnQty end as DayWisePlnQty,round(isnull(DayWiseActualQty,0),0) as DayWiseActualQty,Remarks,m1.UpdatedBy,m1.UpdatedTS,
		ROUND(isnull(OutputPerHour,0),0) as OutputPerHour,
		round(isnull(Prod_Hours_WithoutDressing,0),1) as Prod_Hours_WithoutDressing,
		round(isnull(GrindingWheelDress_Freq,0),0) as GrindingWheelDress_Freq,
		round(isnull(GrindingWheelDress_Time,0),0) as GrindingWheelDress_Time,
		round(isnull(RegulatingDressingTime_InMin,0),0) as RegulatingDressingTime_InMin,
		round(isnull(MonthlyRequiredQty,0),0) as MonthlyRequiredQty,
		isnull(TransactionBit,0) as TransactionBit,isnull(ScheduledDates,'') as ScheduledDates,
		isnull(PreferredMachineBit,0) as  PreferredMachineBit,
		isnull(Total_Time_Required_Hrs,0) as Total_Time_Required_Hrs,
		isnull(Total_Time_RequiredPerDay_Hrs,0) as Total_Time_RequiredPerDay_Hrs,
		isnull(TotalTimeInHours,0) as TotalTimeAvailableInHours,
		case when isnull(TotalTimeInHours,0)<isnull(Total_Time_RequiredPerDay_Hrs,0) then 'Red' else 'Green' END ColoringBit
		--,round(isnull((perdayhitrate/OutputPerHour),0),0) as TotalTimeRequiredInHrs
		from #MachineLevelPlanScreen m1
	end
end
