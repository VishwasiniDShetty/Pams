/****** Object:  Procedure [dbo].[SP_WeeklyPlanDetailsViewAndSave_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

/*
SP_WeeklyPlanDetailsViewAndSave_PAMS '2023','05','20',''
*/
CREATE procedure [dbo].[SP_WeeklyPlanDetailsViewAndSave_PAMS]
@Year nvarchar(40)='',
@MonthValue nvarchar(5)='',
@WeekNumber nvarchar(4)='',
@Param nvarchar(50)=''
as 
begin
	create table #WeeklyPlanScreen
	(
	Year nvarchar(4),
	MonthVal nvarchar(10),
	WeekNumber nvarchar(4),
	CustomerID NVARCHAR(50),
	PartInterface nvarchar(50),
	PartID NVARCHAR(50),
	PartName nvarchar(100),
	FinalOperation nvarchar(50),
	MonthlyRequiredQty float,
	WeeklyRequiredQty float,
	ProductionPlanned float,
	PerDayHitRate float,
	Date DATETIME,
	LogicalDayStart datetime,
	LogicalDayEnd datetime,
	DayWisePlnQty float default 0,
	DayWiseActualQty float default 0,
	TotalProductionAchieved float default 0,
	WeeklyBacklog float default 0,
	ReasonForBackLog nvarchar(2000),
	RemarksByPPC NVARCHAR(2000),
	RemarksByProduction NVARCHAR(2000),
	RemarksByProductionSupervisor NVARCHAR(2000),
	UpdatedBy NVARCHAR(50),
	UpdatedTS DATETIME
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

	insert into #WeeklyPlanScreen(Year,MonthVal,WeekNumber,CustomerID,PartID,PartName,PartInterface,FinalOperation,Date,LogicalDayStart,LogicalDayEnd)
	SELECT DISTINCT Year,MonthValue,WeekNumber,D1.CustomerID,d1.PartID,C1.description,c1.interfaceid,P1.GroupID,Date,dbo.f_GetLogicalDay(date,'start'),dbo.f_GetLogicalDay(date,'end')
	 FROM DayWiseScheduleDetails_PAMS D1
	INNER JOIN componentinformation C1 ON C1.componentid=D1.PartID
	INNER JOIN componentoperationpricing C2 ON C1.componentid=C2.componentid
	INNER JOIN machineinformation M1 ON M1.machineid=C2.machineid
	INNER JOIN PlantMachineGroups P1 ON P1.MachineID=M1.machineid
	inner join PreferredMachineDetails_Pams p3 on c2.componentid=p3.PartID and c2.machineid=p3.PreferredMachineid and c2.operationno=p3.OperationNo
	WHERE D1.Year=@Year AND D1.MonthValue=@MonthValue AND D1.WeekNumber=@WeekNumber


	declare @StartTime datetime
	declare @EndTime datetime

	select @StartTime=(select min(Date) from #WeeklyPlanScreen)
	select @EndTime=(select max(Date) from #WeeklyPlanScreen)

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


	UPDATE #WeeklyPlanScreen SET MonthlyRequiredQty=isnull(T1.Monthlyqty,0)
	from
	(
	select distinct YearNo,MonthVal,partid,PlannedQty as Monthlyqty from MonthlyScheduleDetails_Pams where YearNo=@Year and MonthVal=@MonthValue
	) 
	t1 inner join #WeeklyPlanScreen on #WeeklyPlanScreen.Year=t1.YearNo and #WeeklyPlanScreen.MonthVal=t1.MonthVal and #WeeklyPlanScreen.PartID=t1.PartID

	update #WeeklyPlanScreen set DayWisePlnQty=isnull(t1.DayWisePlnQty,0)
	from
	(
	select distinct Year,MonthValue,PartID,date, sum(PlanQty) as DayWisePlnQty from MachineWisePlnQtyDetails_PAMS where  Year=@Year and MonthValue=@MonthValue
	group by Year,MonthValue,PartID,date
	) t1 inner join #WeeklyPlanScreen t2 on t1.Year=t2.Year and t1.MonthValue=t2.MonthVal and t1.PartID=t2.PartID and t1.Date=t2.Date

	--UPDATE #WeeklyPlanScreen SET WeeklyRequiredQty=isnull(T1.WeeklyQty,0)
	--from
	--(
	--select distinct year,monthval,partid, (MonthlyRequiredQty/(select count(distinct weeknumber) as CountOfWeeks from DayWiseScheduleDetails_PAMS where Year=@Year and MonthValue=@MonthValue)) as WeeklyQty from #WeeklyPlanScreen 
	--) 
	--t1 inner join #WeeklyPlanScreen on #WeeklyPlanScreen.Year=t1.Year and #WeeklyPlanScreen.MonthVal=t1.MonthVal and #WeeklyPlanScreen.PartID=t1.PartID

		UPDATE #WeeklyPlanScreen SET WeeklyRequiredQty=isnull(T1.WeeklyQty,0)
	from
	(
		select distinct Year,MonthValue,WeekNumber,partid,sum(PlannedQty) as WeeklyQty  from DayWiseScheduleDetails_PAMS
		where  Year=@Year and MonthValue=@MonthValue and WeekNumber=@WeekNumber
		group by Year,MonthValue,WeekNumber,partid	) 
	t1 inner join #WeeklyPlanScreen on #WeeklyPlanScreen.Year=t1.Year and #WeeklyPlanScreen.MonthVal=t1.MonthValue and #WeeklyPlanScreen.PartID=t1.PartID and #WeeklyPlanScreen.WeekNumber=t1.WeekNumber



	--update #WeeklyPlanScreen set ProductionPlanned=isnull(t1.ProductionPlanned,0)
	--from
	--(
	--select distinct Year,MonthValue,WeekNumber,partid,sum(PlannedQty) as ProductionPlanned  from DayWiseScheduleDetails_PAMS where Year=@Year and MonthValue=@MonthValue and WeekNumber=@WeekNumber
	--group by Year,MonthValue,WeekNumber,PartID
	--)
	--t1 inner join #WeeklyPlanScreen on #WeeklyPlanScreen.Year=t1.Year and #WeeklyPlanScreen.MonthVal=t1.MonthValue and #WeeklyPlanScreen.WeekNumber=t1.WeekNumber and #WeeklyPlanScreen.PartID=t1.PartID

		update #WeeklyPlanScreen set ProductionPlanned=isnull(t1.ProductionPlanned,0)
	from
	(
	select distinct Year,MonthValue,WeekNumber,partid,sum(PlanQty) as ProductionPlanned  from MachineWisePlnQtyDetails_PAMS where Year=@Year and MonthValue=@MonthValue and WeekNumber=@WeekNumber
	group by Year,MonthValue,WeekNumber,PartID
	)
	t1 inner join #WeeklyPlanScreen on #WeeklyPlanScreen.Year=t1.Year and #WeeklyPlanScreen.MonthVal=t1.MonthValue and #WeeklyPlanScreen.WeekNumber=t1.WeekNumber and #WeeklyPlanScreen.PartID=t1.PartID


		UPDATE #WeeklyPlanScreen SET PerDayHitRate=isnull(T1.PerDayHitRate,0)
	from
	(
	select distinct year,MonthValue,partid,WeekNumber, sum(PlanQty)/(select count(distinct date) as CountOfdays from MachineWisePlnQtyDetails_PAMS where Year=@Year and MonthValue=@MonthValue) as PerDayHitRate from MachineWisePlnQtyDetails_PAMS where Year=@Year and MonthValue=@MonthValue and WeekNumber=@WeekNumber
	group by year,MonthValue,partid,WeekNumber
	) 
	t1 inner join #WeeklyPlanScreen on #WeeklyPlanScreen.Year=t1.Year and #WeeklyPlanScreen.MonthVal=t1.MonthValue and #WeeklyPlanScreen.WeekNumber=t1.WeekNumber and #WeeklyPlanScreen.PartID=t1.PartID



	--UPDATE #WeeklyPlanScreen SET PerDayHitRate=isnull(T1.PerDayHitRate,0)
	--from
	--(
	--select distinct year,monthval,partid, (MonthlyRequiredQty/(select count(distinct date) as CountOfdays from DayWiseScheduleDetails_PAMS where Year=@Year and MonthValue=@MonthValue )) as PerDayHitRate from #WeeklyPlanScreen 
	--) 
	--t1 inner join #WeeklyPlanScreen on #WeeklyPlanScreen.Year=t1.Year and #WeeklyPlanScreen.MonthVal=t1.MonthVal and #WeeklyPlanScreen.PartID=t1.PartID


	-----------------------------------------------------------pick data from pjcedit details if production data entered manually ------------------------------------------------------------------------


	update #WeeklyPlanScreen set DayWiseActualQty=isnull(t1.prodqty,0)
	from
	(
		select distinct p1.date,p1.partid,sum(Prod_Qty) as prodqty from PJCProductionEditedDetails_PAMS p1
		group by p1.date,p1.partid
	) t1 inner join #WeeklyPlanScreen t2 on t1.Date=t2.Date and t1.PartID=t2.PartID --and isnull(t2.DayWiseActualQty,0)=0

	-----------------------------------------------------------pick data from pjcedit details if production data entered manually ------------------------------------------------------------------------

	-----------------------------------------------------------pick data from AUTODATA details if production data from ERP table not available ------------------------------------------------------------------------


	UPDATE #WeeklyPlanScreen SET DayWiseActualQty = ISNULL(DayWiseActualQty,0) + ISNULL(t2.Component,0)
	FROM
	(
		SELECT COMP, T1.LogicalDayStart,SUM((CAST(T1.OrginalCount AS FLOAT)/ISNULL(O.SubOperations,1))) AS Component 
		FROM (SELECT mc,T2.LogicalDayStart,SUM(autodata.partscount)AS OrginalCount,comp,opn 
		FROM #T_autodata autodata --ER0374
		INNER JOIN #WeeklyPlanScreen T2 ON autodata.comp=T2.PartInterface
		WHERE (autodata.ndtime>T2.LogicalDayStart) AND (autodata.ndtime<=T2.LogicalDayEnd) AND (autodata.datatype=1)
		GROUP BY mc,T2.LogicalDayStart,comp,opn) AS T1
		INNER JOIN componentinformation C ON T1.Comp = C.interfaceid
		INNER JOIN ComponentOperationPricing O ON  T1.Opn = O.interfaceid AND C.Componentid=O.componentid
		INNER JOIN machineinformation ON machineinformation.machineid =O.machineid
		AND T1.mc=machineinformation.interfaceid
		GROUP BY comp,T1.LogicalDayStart
	) AS T2 INNER JOIN #WeeklyPlanScreen ON T2.comp = #WeeklyPlanScreen.partinterface AND T2.LogicalDayStart=#WeeklyPlanScreen.LogicalDayStart AND ISNULL(#WeeklyPlanScreen.DayWiseActualQty,0)=0

	-----------------------------------------------------------pick data from AUTODATA details if production data from ERP table not available ------------------------------------------------------------------------


	update #WeeklyPlanScreen set TotalProductionAchieved=isnull(totalprod,0)
	from
	(select distinct year,monthval,weeknumber,partid,sum(DayWiseActualQty) as totalprod from #WeeklyPlanScreen
	group by  year,monthval,weeknumber,partid
	)t1 inner join #WeeklyPlanScreen on #WeeklyPlanScreen.Year=t1.Year and #WeeklyPlanScreen.MonthVal=t1.MonthVal and #WeeklyPlanScreen.WeekNumber=t1.WeekNumber and #WeeklyPlanScreen.PartID=t1.PartID

	update #WeeklyPlanScreen set WeeklyBacklog=isnull(t1.WeeklyBacklog,0)
	from
	(select distinct Year,MonthVal,WeekNumber,partid,(ProductionPlanned-TotalProductionAchieved) as WeeklyBacklog from #WeeklyPlanScreen
	)t1 inner join #WeeklyPlanScreen on #WeeklyPlanScreen.Year=t1.Year and #WeeklyPlanScreen.MonthVal=t1.MonthVal and #WeeklyPlanScreen.WeekNumber=t1.WeekNumber and #WeeklyPlanScreen.PartID=t1.PartID

	update #WeeklyPlanScreen set ReasonForBackLog=isnull(t1.ReasonForBackLog,'')
	from
	(select distinct Year,MonthValue,WeekNumber,PartID,ReasonForBackLog from DayWiseScheduleDetails_PAMS where Year=@Year and MonthValue=@MonthValue and WeekNumber=@WeekNumber
	)t1 inner join #WeeklyPlanScreen on t1.Year=#WeeklyPlanScreen.Year and t1.MonthValue=#WeeklyPlanScreen.MonthVal and t1.WeekNumber=#WeeklyPlanScreen.WeekNumber and t1.PartID=#WeeklyPlanScreen.PartID

	update #WeeklyPlanScreen set UpdatedBy=isnull(t1.UpdatedBy,''),UpdatedTS=ISNULL(T1.UPDATEDTS,''),RemarksByPPC=ISNULL(T1.RemarksByPPC,''),RemarksByProduction=ISNULL(T1.RemarksByProduction,''),
	RemarksByProductionSupervisor=ISNULL(T1.RemarksByProductionSupervisor,'')
	from
	(select distinct Year,MonthValue,WeekNumber,PartID,UpdatedBy,UPDATEDTS,RemarksByPPC,RemarksByProduction,RemarksByProductionSupervisor from WeeklyPlanQtyApproval_PAMS where Year=@Year and MonthValue=@MonthValue and WeekNumber=@WeekNumber
	)t1 inner join #WeeklyPlanScreen on t1.Year=#WeeklyPlanScreen.Year and t1.MonthValue=#WeeklyPlanScreen.MonthVal and t1.WeekNumber=#WeeklyPlanScreen.WeekNumber and t1.PartID=#WeeklyPlanScreen.PartID

	update #WeeklyPlanScreen set FinalOperation=isnull(t1.groupid,'')
	from
	(
	select distinct p1.PartID,p1.OperationNo,p1.PreferredMachineid,p2.GroupID from PreferredMachineDetails_Pams p1 
	inner join PlantMachineGroups p2 on p1.PreferredMachineid=p2.MachineID
	inner join componentoperationpricing c2 on p1.PreferredMachineid=c2.machineid and p1.PartID=c2.componentid and p1.OperationNo=c2.operationno
	where c2.FinishedOperation=1
	) t1 inner join #WeeklyPlanScreen t2 on t1.PartID=t2.PartID 
	
	SELECT distinct Year,MonthVal,WeekNumber,CustomerID,PartInterface,PartID,PartName,FinalOperation ,round(isnull(MonthlyRequiredQty,0),0) as MonthlyRequiredQty ,round(isnull(ProductionPlanned,0),0) as WeeklyRequiredQty,
	round(isnull(ProductionPlanned,0),0) as  ProductionPlanned,round(isnull(PerDayHitRate,0),0) as PerDayHitRate ,
	Date ,LogicalDayStart ,LogicalDayEnd ,round(isnull(DayWisePlnQty,0),0) as DayWisePlnQty ,round(isnull(DayWiseActualQty,0),0) as DayWiseActualQty ,round(isnull(TotalProductionAchieved,0),0) as TotalProductionAchieved ,
	case when round(isnull(WeeklyBacklog,0),0)>0 then WeeklyBacklog else 0 end  as WeeklyBacklog,ReasonForBackLog ,RemarksByPPC ,
	RemarksByProduction ,RemarksByProductionSupervisor ,UpdatedBy ,UpdatedTS  FROM #WeeklyPlanScreen
	RETURN



end
