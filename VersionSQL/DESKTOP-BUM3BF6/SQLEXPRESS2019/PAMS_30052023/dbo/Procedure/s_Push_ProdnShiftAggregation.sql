/****** Object:  Procedure [dbo].[s_Push_ProdnShiftAggregation]    Committed by VersionSQL https://www.versionsql.com ******/

/*	*	*   	*	*	I*	*	*	*	*	*	*	*	*	*
*	Procedure Created By SSK on 06/Nov/2006 :: For Shift Aggregation Process
*	-------------------------------------------------------------------------------------------		*
*	Procedure Changed By SSK on 08/Nov/2006 :: to add @Type parameter
*	Procedure used in SmartManager - FrmMARKS.frm
*	------------------------------------------------------------------------------------------		*
*	Procedure Changed By SSK on 22/Nov/2006 ::
*	New Column 'PartsCount' as added into AutoData Which gives part Count.
*	ie if cycle is of pallet type,it will give pallet count else count.
*	------------------------------------------------------------------------------------------		*
*	Procedure changed by SSK on 23/Nov/2006 :
*		Bz of change in column names of 'ShiftProductionDetails','ShiftDownTimeDetails' tables.
*	Procedure Chnaged By SSK on 10-Jan-2007 :To Populate 'Acceptedparts' column.
*	------------------------------------------------------------------------------------------		*
*	
*	Procedure Changed By Sangeeta Kallur on 01/Mar/2007 :
*		For Considering MultiSpindle Machines - Which affects Production Count   	*
	MOD 1:- fOR DR0148 BY mRUDULA ON 28-NOV-2008. pUT RETURN AT THE BEGINNING TO AVOID AGGREGATION FROM
          OLD exe
*	*	*	*	*	*	*	*	*	*	*		*	*	*/
CREATE             PROCEDURE [dbo].[s_Push_ProdnShiftAggregation]
	@Date as DateTime,
	@Shift as Nvarchar(20),
	@MachineID as NvarChar(50),
	@PlantID As NvarChar(50),
	@Type As Nvarchar(20)='PUSH'
	
AS
BEGIN
--MOD 1
RETURN
--MOD 1

Declare @StartTime as datetime
Declare @EndTime as datetime
Declare @strMachine as nvarchar(250)
Declare @strPlantID as nvarchar(250)
Declare @StrSql as nvarchar(4000)
CREATE TABLE #ShiftDetails
(
	PDate datetime,
	Shift nvarchar(20),
	ShiftStart datetime,
	ShiftEnd datetime
)
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
SET @StrSql = ''
SET @strMachine = ''
SET @strPlantID = ''
If @Type='PUSH'
BEGIN
	if isnull(@MachineID,'')<> ''
	begin
		SET @strMachine = ' AND MachineInformation.MachineID = ''' + @machineid + ''''
	end
	if isnull(@PlantID,'')<> ''
	Begin
		SET @strPlantID = ' AND PlantMachine.PlantID = ''' + @PlantID + ''''
	End
END
ELSE
BEGIN
	if isnull(@MachineID,'')<> ''
	begin
		SET @strMachine = ' AND ShiftProductionDetails.MachineID = ''' + @machineid + ''''
	end
		if isnull(@PlantID,'')<> ''
	Begin
		SET @strPlantID = ' AND ShiftProductionDetails.PlantID = ''' + @PlantID + ''''
	End
END
If @Type='PUSH'
	BEGIN
	
	
	--Get Shift Start and Shift End
	INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)
	EXEC s_GetShiftTime @Date,@Shift
	
	--Introduced TOP 1 to take care of input 'ALL' shifts
	select @StartTime =(select TOP 1 shiftstart from #ShiftDetails ORDER BY shiftstart ASC)
	select @EndTime =(select TOP 1 shiftend from #ShiftDetails ORDER BY shiftend DESC)
	
	
	--Build String for Insertion[Production Details]
	-- CO_IdealCycleTime = Std.Machining Time OR Std.Cutting Time
	SELECT @StrSql=' Insert into ShiftProductionDetails (
				pDate,Shift,PlantID,MachineID,
				ComponentID,OperationNo,
				OperatorID,Prod_Qty,
				CO_StdMachiningTime,CO_StdLoadUnload,
				Price,SubOperation,AcceptedParts
				)
		 SELECT '''+Convert(NvarChar(20),@Date)+''','''+@Shift+''',PlantMachine.PlantID,machineinformation.MachineID, componentinformation.componentid,
		 componentoperationpricing.operationno, EmployeeInformation.EmployeeID,
		 CAST(CEILING(CAST(Sum(autodata.PartsCount)as float)/ ISNULL(componentoperationpricing.SubOperations,1))as integer ) as opn,
		 (componentoperationpricing.machiningtime),(componentoperationpricing.CycleTime - componentoperationpricing.machiningtime),
		 componentoperationpricing.Price,componentoperationpricing.SubOperations,
		 CAST(CEILING(CAST(Sum(autodata.PartsCount)as float)/ ISNULL(componentoperationpricing.SubOperations,1))as integer )
		 FROM autodata
			INNER JOIN EmployeeInformation ON autodata.Opr=EmployeeInformation.InterfaceID
			INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID
			LEFT OUTER JOIN PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID
			INNER JOIN  componentinformation ON autodata.comp = componentinformation.InterfaceID
			INNER JOIN componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID) AND (componentinformation.componentid = componentoperationpricing.componentid)
	 	 WHERE autodata.ndtime > '''+Convert(NvarChar(20),@StartTime)+''' AND autodata.ndtime <='''+Convert(NvarChar(20),@EndTime)+'''  AND (autodata.datatype = 1)'
	SELECT @StrSql = @StrSql+@strPlantID+@strMachine
	SELECT @StrSql = @StrSql+'GROUP BY  PlantMachine.PlantID,machineinformation.machineid,componentinformation.componentid, componentoperationpricing.operationno, EmployeeInformation.EmployeeID,
		 componentoperationpricing.cycletime, componentoperationpricing.machiningtime , componentoperationpricing.SubOperations,
		 componentoperationpricing.LoadUnload,componentoperationpricing.Price'
	Exec (@StrSql)
/**************************************************************************************************************/
/* 			FOLLOWING SECTION IS ADDED BY SANGEETA KALLUR					*/
SELECT @StrSql = 'INSERT INTO #Exceptions(MachineID ,ComponentID,OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,ExCount )
		SELECT Ex.MachineID ,Ex.ComponentID,Ex.OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,0
		From ProductionCountException Ex
		Inner Join MachineInformation M ON Ex.MachineID=M.MachineID
		Inner Join ComponentInformation C ON Ex.ComponentID=C.ComponentID
		Inner Join Componentoperationpricing O ON Ex.OperationNo=O.OperationNo AND C.ComponentID=O.ComponentID
		WHERE  Ex.MachineID='''+@MachineID+''' AND M.MultiSpindleFlag=1 AND
		((Ex.StartTime>=  ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@EndTime)+''' )
		OR (Ex.StartTime< ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@EndTime)+''')
		OR(Ex.StartTime>= ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@EndTime)+''' AND Ex.StartTime< ''' + convert(nvarchar(20),@EndTime)+''')
		OR(Ex.StartTime< ''' + convert(nvarchar(20),@StartTime)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@EndTime)+''' ))'
Exec (@strsql)
IF ( SELECT Count(*) from #Exceptions ) <> 0
BEGIN
	UPDATE #Exceptions SET StartTime=@StartTime WHERE (StartTime<@StartTime)AND EndTime>@StartTime
	UPDATE #Exceptions SET EndTime=@EndTime WHERE (EndTime>@EndTime AND StartTime<@EndTime )
	Select @StrSql = 'UPDATE #Exceptions SET ExCount=ISNULL(T2.Comp,0) From
	(
		SELECT T1.MachineID AS MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime AS StartTime,T1.EndTime AS EndTime,
		SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) as comp
	 	From (
			select MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,comp,opn,Tt1.StartTime,Tt1.EndTime,Sum(ISNULL(PartsCount,1))AS OrginalCount from autodata
			Inner Join MachineInformation   ON autodata.MC=MachineInformation.InterfaceID
			Inner Join EmployeeInformation E  ON autodata.Opr=E.InterfaceID
			Inner Join ComponentInformation  ON autodata.Comp = ComponentInformation.InterfaceID
			Inner Join ComponentOperationPricing on autodata.Opn=ComponentOperationPricing.InterfaceID And ComponentInformation.ComponentID=ComponentOperationPricing.ComponentID
			Inner Join (
				Select MachineID,ComponentID,OperationNo,StartTime,EndTime From #Exceptions
			)AS Tt1 ON Tt1.MachineID=MachineInformation.MachineID AND Tt1.ComponentID = ComponentInformation.ComponentID AND Tt1.OperationNo= ComponentOperationPricing.OperationNo
			Where (autodata.ndtime>Tt1.StartTime) AND (autodata.ndtime<=Tt1.EndTime) and (autodata.datatype=1) '
	Select @StrSql = @StrSql+ @strMachine
	Select @StrSql = @StrSql+' Group by MachineInformation.MachineID,ComponentInformation.ComponentID,ComponentOperationPricing.OperationNo,Tt1.StartTime,Tt1.EndTime,comp,opn
		) as T1
	   	Inner join componentinformation C on T1.Comp=C.interfaceid
	   	Inner join ComponentOperationPricing O ON T1.Opn=O.interfaceid and C.Componentid=O.componentid
	  	GROUP BY T1.MachineID,T1.ComponentID,T1.OperationNo,T1.StartTime,t1.EndTime
	)AS T2
	WHERE  #Exceptions.StartTime=T2.StartTime AND #Exceptions.EndTime=T2.EndTime
	AND #Exceptions.MachineID=T2.MachineID AND #Exceptions.ComponentID = T2.ComponentID AND #Exceptions.OperationNo=T2.OperationNo'
	Exec(@StrSql)
	UPDATE #Exceptions SET ExCount=ExCount-((ExCount * ActualCount)/ISNULL(IdealCount,0))
END
UPDATE ShiftProductionDetails SET AcceptedParts=ISNULL(AcceptedParts,0)-ISNULL(DummyC,0),
				Dummy_Cycles	=	ISNULL(DummyC,0)
FROM
(
	SELECT ShiftProductionDetails.pDate,ShiftProductionDetails.Shift,ShiftProductionDetails.MachineID,ShiftProductionDetails.Componentid,ShiftProductionDetails.OperationNo,ShiftProductionDetails.OperatorID,(AcceptedParts*(Ti.Ratio))As DummyC
	FROM ShiftProductionDetails LEFT OUTER JOIN
	(
		SELECT #Exceptions.MachineID,#Exceptions.Componentid,#Exceptions.OperationNo,CAST(CAST (SUM(ExCount) AS FLOAT)/CAST(Max(T1.tCount)AS FLOAT )AS FLOAT) AS Ratio
		FROM #Exceptions  Inner Join (
				SELECT MachineID,Componentid,OperationNo,SUM(AcceptedParts)AS tCount
				FROM ShiftProductionDetails WHERE pDate=@Date And Shift=@Shift AND MachineID=@MachineID
				Group By  MachineID,Componentid,OperationNo
				)T1 ON  T1.MachineID=#Exceptions.MachineID AND T1.Componentid=#Exceptions.Componentid AND T1.OperationNo=#Exceptions.OperationNo
		Group By  #Exceptions.MachineID,#Exceptions.Componentid,#Exceptions.OperationNo
	)AS Ti ON ShiftProductionDetails.MachineID =Ti.MachineID AND  ShiftProductionDetails.Componentid=Ti.Componentid AND ShiftProductionDetails.OperationNo=Ti.OperationNo
	WHERE ShiftProductionDetails.pDate=@Date And ShiftProductionDetails.Shift=@Shift AND ShiftProductionDetails.MachineID=@MachineID
)As Tm Inner Join ShiftProductionDetails ON
	ShiftProductionDetails.pDate       =Tm.pDate	   AND
	ShiftProductionDetails.Shift	   =Tm.Shift       AND
	ShiftProductionDetails.MachineID   =Tm.MachineID   AND
	ShiftProductionDetails.Componentid =Tm.Componentid AND
	ShiftProductionDetails.OperationNo =Tm.OperationNo AND
	ShiftProductionDetails.OperatorID  =Tm.OperatorID
/***************************************************************************************************************/
	-- Type 1/2 ::Calculate Actual Cutting Time for Speed Ratio.
	-- Type 1/2 ::Calculate Actual LoadUnload Time for Load Ratio.
	UPDATE ShiftProductionDetails SET
		ActMachiningTime_Type12 = isnull(ActMachiningTime_Type12,0) + isNull(t2.Cycle,0),
		ActLoadUnload_Type12 = isnull(ActLoadUnload_Type12,0) + isNull(t2.LoadUnload,0),
		MaxMachiningTime=Isnull(T2.MaxCycleTime,0),
		MinMachiningTime=Isnull(T2.MinCycleTime,0),
		MaxLoadUnloadTime=Isnull(T2.MaxLoadUnload,0),
		MinLoadUnloadTime=Isnull(T2.MinLoadUnload,0)
	from
	(select   @Date AS CDate,@Shift AS CShift, M.Machineid AS CMachine,C.componentid AS CComponent,O.OperationNo AS COpnNo,E.EmployeeID AS COpr,
	sum(A.cycletime) as Cycle,sum(A.loadunload) as LoadUnload,
	Max(Isnull(A.cycletime,0)/Isnull(A.PartsCount,1))* Avg(Isnull(SubOperations,1)) As MaxCycleTime,
	Min(Isnull(A.cycletime,0)/Isnull(A.PartsCount,1))* Avg(Isnull(SubOperations,1)) As MinCycleTime,
	Max(Isnull(A.LoadUnload,0)/Isnull(A.PartsCount,1))* Avg(Isnull(SubOperations,1)) As MaxLoadUnload,
	Min(Isnull(A.LoadUnload,0)/Isnull(A.PartsCount,1))* Avg(Isnull(SubOperations,1)) As MinLoadUnload
	from autodata A
		INNER JOIN Machineinformation M ON A.mc=M.InterfaceID
		INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
		INNER JOIN  componentinformation C ON A.comp = C.InterfaceID
		INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND (C.componentid = O.componentid)
	where (A.ndtime>@StartTime and A.ndtime<=@EndTime and A.datatype=1 And M.Machineid=@MachineID)
	group by M.Machineid,C.componentid,O.OperationNo ,E.EmployeeID
	) as t2 inner join ShiftProductionDetails on t2.CDate=ShiftProductionDetails.pDate
				And t2.CShift=ShiftProductionDetails.Shift
				And t2.CMachine = ShiftProductionDetails.MachineID
				And t2.CComponent=ShiftProductionDetails.Componentid
				And t2.COpnNo=ShiftProductionDetails.OperationNo
			        And t2.COpr=ShiftProductionDetails.OperatorID
/*
	-- Type 1/2 ::Calculate Actual LoadUnload Time for Load Ratio.
	UPDATE ShiftProductionDetails SET ActLoadUnload_Type12 = isnull(ActLoadUnload_Type12,0) + isNull(t2.Cycle,0)
	from
	(select   @Date AS CDate,@Shift AS CShift, M.Machineid AS CMachine,C.componentid AS CComponent,O.OperationNo AS COpnNo,E.EmployeeID AS COpr,
	sum(A.loadunload) as Cycle
	from autodata A
		INNER JOIN Machineinformation M ON A.mc=M.InterfaceID
		INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
		INNER JOIN  componentinformation C ON A.comp = C.InterfaceID
		INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND (C.componentid = O.componentid)
	where (A.ndtime>@StartTime and A.ndtime<=@EndTime and A.datatype=1 And M.Machineid=@MachineID)
	group by M.Machineid,C.componentid,O.OperationNo ,E.EmployeeID
	) as t2 inner join ShiftProductionDetails on t2.CDate=ShiftProductionDetails.Date
				And t2.CShift=ShiftProductionDetails.Shift
				And t2.CMachine = ShiftProductionDetails.MachineID
				And t2.CComponent=ShiftProductionDetails.Componentid
				And t2.COpnNo=ShiftProductionDetails.OperationNo
				And t2.COpr=ShiftProductionDetails.OperatorID	
*/
	-- To calculate Utilised Time
	-- Type 1
	UPDATE ShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) + isNull(t2.Cycle,0)
	from
	(select   @Date AS CDate,@Shift AS CShift, M.Machineid AS CMachine,C.componentid AS CComponent,O.OperationNo AS COpnNo,E.EmployeeID AS COpr,
	sum(A.cycletime + A.LoadUnload) as Cycle
	from autodata A
		INNER JOIN Machineinformation M ON A.mc=M.InterfaceID
		INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
		INNER JOIN  componentinformation C ON A.comp = C.InterfaceID
		INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND (C.componentid = O.componentid)
	where (A.msttime>=@StartTime and A.ndtime<=@EndTime and A.datatype=1 And M.Machineid=@MachineID)
	group by M.Machineid,C.componentid,O.OperationNo ,E.EmployeeID
	) as t2 inner join ShiftProductionDetails on t2.CDate=ShiftProductionDetails.pDate
				And t2.CShift=ShiftProductionDetails.Shift
				And t2.CMachine = ShiftProductionDetails.MachineID
				And t2.CComponent=ShiftProductionDetails.Componentid
				And t2.COpnNo=ShiftProductionDetails.OperationNo
				And t2.COpr=ShiftProductionDetails.OperatorID
	
	-- Type 2
	UPDATE ShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) + isNull(t2.Cycle,0)
	from
	(select   @Date AS CDate,@Shift AS CShift, M.Machineid AS CMachine,C.componentid AS CComponent,O.OperationNo AS COpnNo,E.EmployeeID AS COpr,SUM(DateDiff(second, @StartTime, ndtime)) as Cycle
	from autodata A
		INNER JOIN Machineinformation M ON A.mc=M.InterfaceID
		INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
		INNER JOIN  componentinformation C ON A.comp = C.InterfaceID
		INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND (C.componentid = O.componentid)
	where A.msttime<@StartTime and A.ndtime>@StartTime and A.ndtime<=@EndTime and A.datatype=1 And M.Machineid=@MachineID
	group by M.Machineid,C.componentid,O.OperationNo,E.EmployeeID
	) as t2 inner join ShiftProductionDetails on t2.CDate=ShiftProductionDetails.pDate
				And t2.CShift=ShiftProductionDetails.Shift
				And t2.CMachine = ShiftProductionDetails.MachineID
				And t2.CComponent=ShiftProductionDetails.Componentid
				And t2.COpnNo=ShiftProductionDetails.OperationNo
				And t2.COpr=ShiftProductionDetails.OperatorID
	
	-- Type 3
	UPDATE ShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) + isNull(t2.Cycle,0)
	from
	(select   @Date AS CDate,@Shift AS CShift, M.Machineid AS CMachine,C.componentid AS CComponent,O.OperationNo AS COpnNo,E.EmployeeID AS COpr,SUM(DateDiff(second, stTime, @Endtime)) as Cycle
	from autodata A
		INNER JOIN Machineinformation M ON A.mc=M.InterfaceID
		INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
		INNER JOIN  componentinformation C ON A.comp = C.InterfaceID
		INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND (C.componentid = O.componentid)
	where A.msttime>=@StartTime and A.msttime<@EndTime and A.ndtime>@EndTime and A.datatype=1 And M.Machineid=@MachineID
	group by M.Machineid,C.componentid,O.OperationNo,E.EmployeeID
	) as t2 inner join ShiftProductionDetails on t2.CDate=ShiftProductionDetails.pDate
				And t2.CShift=ShiftProductionDetails.Shift
				And t2.CMachine = ShiftProductionDetails.MachineID
				And t2.CComponent=ShiftProductionDetails.Componentid
				And t2.COpnNo=ShiftProductionDetails.OperationNo
				And t2.COpr=ShiftProductionDetails.OperatorID
	
	-- Type 4
	UPDATE ShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) + isNull(t2.Cycle,0)
	from
	(select   @Date AS CDate,@Shift AS CShift, M.Machineid AS CMachine,C.componentid AS CComponent,O.OperationNo AS COpnNo,E.EmployeeID AS COpr,SUM(DateDiff(second, @StartTime, @EndTime)) as Cycle
	from autodata A
		INNER JOIN Machineinformation M ON A.mc=M.InterfaceID
		INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
		INNER JOIN  componentinformation C ON A.comp = C.InterfaceID
		INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND (C.componentid = O.componentid)
	where  A.msttime<@StartTime and A.ndtime>@EndTime and A.datatype=1 And M.Machineid=@MachineID
	group by M.Machineid,C.componentid,O.OperationNo,E.EmployeeID
	) as t2 inner join ShiftProductionDetails on t2.CDate=ShiftProductionDetails.pDate
				And t2.CShift=ShiftProductionDetails.Shift
				And t2.CMachine = ShiftProductionDetails.MachineID
				And t2.CComponent=ShiftProductionDetails.Componentid
				And t2.COpnNo=ShiftProductionDetails.OperationNo
				And t2.COpr=ShiftProductionDetails.OperatorID
	
	/* Incylce Down */
	/* If Down Records of TYPE-2*/
	
	UPDATE  ShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) - isNull(t2.Down,0)
	FROM
	(Select @Date AS CDate,@Shift AS CShift, M.Machineid AS CMachine,C.componentid AS CComponent,O.OperationNo AS COpnNo,E.EmployeeID AS COpr,
	SUM(
	CASE
		When A.sttime <= @StartTime Then datediff(s, @StartTime,A.ndtime )
		When A.sttime > @StartTime Then datediff(s , A.sttime,A.ndtime)
	END) as Down
	From AutoData A INNER Join (Select mc,Comp,Opn,Opr,Sttime,NdTime From AutoData
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(sttime < @StartTime And ndtime > @StartTime AND ndtime <= @EndTime)) as T1 ON A.mc=T1.mc And A.Comp=T1.Comp And A.Opn=T1.Opn And A.Opr=T1.Opr
		
		Inner Join MachineInformation M on A.mc=M.Interfaceid
		INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
		INNER JOIN  componentinformation C ON A.comp = C.InterfaceID
		INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND (C.componentid = O.componentid)
		
	Where A.DataType=2
	And  A.Sttime > T1.Sttime And  A.ndtime <  T1.ndtime  AND  A.ndtime >  @StartTime  And M.Machineid=@MachineID
	GROUP BY M.Machineid,C.componentid,O.OperationNo,E.EmployeeID)AS T2
				Inner join ShiftProductionDetails on t2.CDate=ShiftProductionDetails.pDate
				And t2.CShift=ShiftProductionDetails.Shift
				And t2.CMachine = ShiftProductionDetails.MachineID
				And t2.CComponent=ShiftProductionDetails.Componentid
				And t2.COpnNo=ShiftProductionDetails.OperationNo
				And t2.COpr=ShiftProductionDetails.OperatorID
	
	
	/* If Down Records of TYPE-3*/
	
	UPDATE  ShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) - isNull(t2.Down,0)
	FROM
	(Select @Date AS CDate,@Shift AS CShift, M.Machineid AS CMachine,C.componentid AS CComponent,O.OperationNo AS COpnNo,E.EmployeeID AS COpr,
	SUM(
	CASE
		When A.ndtime > @EndTime Then datediff(s,A.sttime, @EndTime )
		When A.ndtime <=@EndTime Then datediff(s , A.sttime,A.ndtime)
	END) as Down
	From AutoData A INNER Join (Select mc,Comp,Opn,Opr,Sttime,NdTime From AutoData
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
		(sttime >= @StartTime)And (ndtime > @EndTime)) as T1 ON A.mc=T1.mc And A.Comp=T1.Comp And A.Opn=T1.Opn And A.Opr=T1.Opr
		
		Inner Join MachineInformation M on A.mc=M.Interfaceid
		INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
		INNER JOIN  componentinformation C ON A.comp = C.InterfaceID
		INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND (C.componentid = O.componentid)
	Where A.DataType=2
	And (T1.Sttime < A.sttime  )And ( T1.ndtime >  A.ndtime) AND (A.sttime  <  @EndTime) And M.Machineid=@MachineID
	GROUP BY M.Machineid,C.componentid,O.OperationNo,E.EmployeeID)AS T2
				Inner join ShiftProductionDetails on t2.CDate=ShiftProductionDetails.pDate
				And t2.CShift=ShiftProductionDetails.Shift
				And t2.CMachine = ShiftProductionDetails.MachineID
				And t2.CComponent=ShiftProductionDetails.Componentid
				And t2.COpnNo=ShiftProductionDetails.OperationNo
				And t2.COpr=ShiftProductionDetails.OperatorID
	
	
	/* If Down Records of TYPE-4*/
	UPDATE  ShiftProductionDetails SET Sum_of_ActCycleTime = isnull(Sum_of_ActCycleTime,0) - isNull(t2.Down,0)
	FROM
	(Select @Date AS CDate,@Shift AS CShift, M.Machineid AS CMachine,C.componentid AS CComponent,O.OperationNo AS COpnNo,E.EmployeeID AS COpr,
	SUM(
	CASE
		When A.sttime < @StartTime AND A.ndtime<=@EndTime Then datediff(s, @StartTime,A.ndtime )
		When A.ndtime >= @EndTime AND A.sttime>@StartTime Then datediff(s,A.sttime, @EndTime )
		When A.sttime >= @StartTime AND
		     A.ndtime <= @EndTime Then datediff(s , A.sttime,A.ndtime)
		When A.sttime<@StartTime AND A.ndtime>@EndTime   Then datediff(s , @StartTime,@EndTime)
	END) as Down
	From AutoData A INNER Join (Select mc,Comp,Opn,Opr,Sttime,NdTime From AutoData
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And
			(sttime < @StartTime)And (ndtime > @EndTime) ) as T1 ON A.mc=T1.mc And A.Comp=T1.Comp And A.Opn=T1.Opn And A.Opr=T1.Opr
		
		Inner Join MachineInformation M on A.mc=M.Interfaceid
		INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
		INNER JOIN  componentinformation C ON A.comp = C.InterfaceID
		INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND (C.componentid = O.componentid)
	Where A.DataType=2
	And (T1.Sttime < A.sttime  )And ( T1.ndtime >  A.ndtime) AND (A.ndtime  >  @StartTime)AND (A.sttime  <  @EndTime)And M.Machineid=@MachineID
	GROUP BY M.Machineid,C.componentid,O.OperationNo,E.EmployeeID)AS T2
				Inner join ShiftProductionDetails on t2.CDate=ShiftProductionDetails.pDate
				And t2.CShift=ShiftProductionDetails.Shift
				And t2.CMachine = ShiftProductionDetails.MachineID
				And t2.CComponent=ShiftProductionDetails.Componentid
				And t2.COpnNo=ShiftProductionDetails.OperationNo
				And t2.COpr=ShiftProductionDetails.OperatorID
	
	
	
	/*
	UPDATE  ShiftProductionDetails SET Sum_of_ActLoadUnload = isnull(Sum_of_ActLoadUnload,0) + isNull(t2.ActLU,0)
	FROM
	(Select @Date AS CDate,@Shift AS CShift, M.Machineid AS CMachine,C.componentid AS CComponent,O.OperationNo AS COpnNo,E.EmployeeID AS COpr,
	SUM(A.LoadUnload) as ActLU
	From AutoData A
		Inner Join MachineInformation M on A.mc=M.Interfaceid
		INNER JOIN EmployeeInformation E ON A.Opr=E.InterfaceID
		INNER JOIN  componentinformation C ON A.comp = C.InterfaceID
		INNER JOIN componentoperationpricing O ON (A.opn = O.InterfaceID) AND (C.componentid = O.componentid)
	Where A.DataType=1 And M.Machineid=@MachineID
	And (
	     (A.msttime>=@StartTime and A.ndtime<=@EndTime)
	  OR (A.msttime<@StartTime and A.ndtime>@StartTime and A.ndtime<=@EndTime)
	OR (A.msttime>=@StartTime and A.msttime<@EndTime and A.ndtime>@EndTime)
	OR (A.msttime<@StartTime and A.ndtime>@EndTime)
	)
	GROUP BY M.Machineid,C.componentid,O.OperationNo,E.EmployeeID)AS T2
			Inner join ShiftProductionDetails on t2.CDate=ShiftProductionDetails.Date
			And t2.CShift=ShiftProductionDetails.Shift
			And t2.CMachine = ShiftProductionDetails.MachineID
			And t2.CComponent=ShiftProductionDetails.Componentid
			And t2.COpnNo=ShiftProductionDetails.OperationNo
			And t2.COpr=ShiftProductionDetails.OperatorID
	*/
	if isnull(@MachineID,'')<> ''
	begin
		SET @strMachine = ' AND ShiftProductionDetails.MachineID = ''' + @machineid + ''''
	end
	if isnull(@PlantID,'')<> ''
	Begin
		SET @strPlantID = ' AND ShiftProductionDetails.PlantID = ''' + @PlantID + ''''
	End
	
	
	SELECT @StrSql=' SELECT  DISTINCT ID, pDate, PlantID, MachineID, Shift, ComponentID, OperationNo, OperatorID, Prod_Qty,
			 Repeat_Cycles, Dummy_Cycles, Rework_Performed,
			 Marked_for_Rework,AcceptedParts
			 FROM ShiftProductionDetails
		         where pDATE='''+Convert(NvarChar(20),@Date)+''' AND SHIFT='''+@Shift+''''
	SELECT @StrSql=@StrSql+@strPlantID+@strMachine + ' order by machineID '
	exec(@StrSql)
	
END
ELSE
IF @Type='DELETE'
BEGIN
	SELECT @StrSql='Delete from ShiftRejectionDetails where ID IN(Select ID From ShiftProductionDetails Where pDate='''+Convert(NvarChar(20),@Date)+'''  and Shift='''+@Shift+''''+@strPlantID+@strMachine+' )'
	exec(@StrSql)
	
	SELECT @StrSql=''
	SELECT @StrSql='Delete from ShiftProductionDetails where pDATE='''+Convert(NvarChar(20),@Date)+''' AND SHIFT='''+@Shift+''''
	SELECT @StrSql=@StrSql+@strPlantID+@strMachine
	exec(@StrSql)
END
END
