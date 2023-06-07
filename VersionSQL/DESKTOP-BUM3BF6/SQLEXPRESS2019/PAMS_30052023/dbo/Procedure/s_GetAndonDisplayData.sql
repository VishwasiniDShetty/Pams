/****** Object:  Procedure [dbo].[s_GetAndonDisplayData]    Committed by VersionSQL https://www.versionsql.com ******/

/*------------Procedure Created By Karthik G on 26/Nov/2009 ------------------------------
--NR0064-26/Nov/2009-Karthik :: New Appliacation and Procedure to drive Andon screen for BOSCH.
-----------------------------------------------------------------------------------------*/
CREATE 	PROCEDURE [dbo].[s_GetAndonDisplayData]
	@PlantID as nvarchar(50),
	@machineID as nvarchar(50)='',
	@MachinePlantLevel as nvarchar(50)='' --'MachineLevel','Plantlevel'
AS
BEGIN
--go
--s_GetAndonDisplayData 'Turning Center','','Plantlevel'

Declare @StartTime as DateTime
Declare @EndTime as DateTime
Declare @CurrTime as DateTime

--select @CurrTime = '2009-12-01 11:00:00'--getdate()

CREATE TABLE #GetShiftTime([ID] int IDENTITY(1,1),startdatetime datetime,shiftname NvarChar(50),StartTime datetime,EndTime datetime)

CREATE TABLE #FinalData
	(
		StartTime Datetime,
		EndTime Datetime,
		MachineID NvarChar(50),
		MachineInterface nvarchar(50),
		Target int,--is at day level
		Actual int,--is at day level
		DownTime int,--is at day level
		DownTime_Last int,
		--ShiftStartTime Datetime,
		--ShiftEndTime Datetime,
		--Downtime_Shift int,
		RunningStatus NvarChar(50)
	)

CREATE TABLE #Exceptions
	(
		MachineID NVarChar(50),
		ComponentID Nvarchar(50),
		OperationNo Int,
		StartTime DateTime,
		EndTime DateTime,
		ExStartTime DateTime,
		ExEndTime DateTime,
		ExCount Int,
		ActualCount Int,
		IdealCount Int
	)

CREATE TABLE #PDT
	(
		StartTime Datetime,
		EndTime Datetime,
		StartTimePDT DateTime,
		EndTimePDT Datetime,
		MachineID NvarChar(50),
		MachineInterface nvarchar(50),
		Actual Int,
		DownTime Int
	)

CREATE TABLE #MachineRunningStatus
	(
		MachineID NvarChar(50),
		MachineInterface nvarchar(50),
		sttime Datetime,
		ndtime Datetime,
		DataType smallint,
		ColorCode varchar(10),
		DownTime Int
	)

Insert #GetShiftTime exec s_GetShiftTimeSA @CurrTime


--select * from plantmachine where plantid = @PlantID
if @MachinePlantLevel = 'Plantlevel'
Begin
	Insert Into #FinalData (StartTime,EndTime,MachineID,MachineInterface,Target,Actual,Downtime,Downtime_Last)
	select min(#GetShiftTime.StartTime),max(#GetShiftTime.EndTime),Machineinformation.machineid,Machineinformation.interfaceid,0,0,0,0 from #GetShiftTime cross join plantmachine 
	--inner join (Select * from #GetShiftTime where StartTime <= @CurrTime and EndTime > @CurrTime) as t1 on 1=1
	inner join machineinformation on machineinformation.machineid = plantmachine.machineid
	where plantmachine.plantid = @PlantID group by Machineinformation.machineid,Machineinformation.interfaceid--,t1.StartTime,t1.EndTime
End



if @MachinePlantLevel = 'MachineLevel'
Begin
	Insert Into #FinalData (StartTime,EndTime,MachineID,MachineInterface,Target,Actual,Downtime,Downtime_Last)
	select min(#GetShiftTime.StartTime),max(#GetShiftTime.EndTime),Machineinformation.machineid,Machineinformation.interfaceid,0,0,0,0 from #GetShiftTime cross join plantmachine 
	--inner join (Select * from #GetShiftTime where StartTime <= @CurrTime and EndTime > @CurrTime) as t1 on 1=1
	inner join machineinformation on machineinformation.machineid = plantmachine.machineid
	where plantmachine.plantid = @PlantID and plantmachine.machineID = @machineID group by Machineinformation.machineid,Machineinformation.interfaceid--,t1.StartTime,t1.EndTime
End



--Calculating Target(at Day level)
Update #FinalData set Target = isnull(#FinalData.Target,0) + isNull(t1.target,0) from (
	select #FinalData.MachineID,sum(Isnull(ShiftHourTargets.target,0)) as Target from #FinalData inner join  ShiftHourTargets on 
	#FinalData.machineID = ShiftHourTargets.machineID and #FinalData.StartTime<=HourStart and
	#FinalData.EndTime>=HourEnd Group by #FinalData.MachineID
) as t1 inner join #FinalData on #FinalData.machineID = t1.MachineID

--Calculating Actual (i.e..PartsCount)(at Day level)
UPDATE #FinalData SET Actual = ISNULL(Actual,0) + ISNULL(t2.comp,0)From(
	select Autodata.mc,--#FinalData.StartTime,#FinalData.EndTime,
	SUM(CEILING(CAST(autodata.partscount AS Float)/ISNULL(O.SubOperations,1))) as comp
	from autodata 
	inner join #FinalData on autodata.mc = #FinalData.machineinterface
	Inner join componentinformation C on autodata.Comp = C.interfaceid
	Inner join ComponentOperationPricing O ON  autodata.Opn = O.interfaceid and C.Componentid=O.componentid
	inner join machineinformation on machineinformation.machineid =O.machineid and autodata.mc=machineinformation.interfaceid
	Where Autodata.datatype = 1
	and Autodata.ndtime > #FinalData.StartTime and Autodata.ndtime <= #FinalData.EndTime
	Group by Autodata.mc--,#FinalData.StartTime,#FinalData.EndTime
) As T2 Inner join #FinalData on T2.mc = #FinalData.machineinterface --and T2.StartTime = #FinalData.StartTime and T2.EndTime = #FinalData.EndTime

	--Calculating ExceptionCount(at Day level)
	Insert into #Exceptions
	select machineinformation.MachineID,C.componentid,O.operationNo,
	#FinalData.StartTime,#FinalData.EndTime,--pce.StartTime,pce.EndTime,
	Case when pce.StartTime <= #FinalData.StartTime then #FinalData.StartTime else pce.StartTime End as ExStartTime,
	Case when pce.EndTime >= #FinalData.EndTime then #FinalData.EndTime else pce.EndTime End as ExEndTime,0,
	isnull(ActualCount,0),Isnull(IdealCount,1)
	from #FinalData 
	Inner join machineinformation on #FinalData.MachineID = machineinformation.machineid 
	Inner join ComponentOperationPricing O ON  machineinformation.machineid=O.machineid 
	Inner join componentinformation C on C.Componentid=O.componentid 
	Inner join ProductionCountException pce on pce.machineID = #FinalData.MachineID and pce.ComponentID = C.Componentid and pce.OperationNo = O.OperationNo 
	Where ((#FinalData.StartTime >= pce.StartTime and #FinalData.EndTime <= pce.EndTime)or 
	(#FinalData.StartTime < pce.StartTime and #FinalData.EndTime > pce.StartTime and #FinalData.EndTime <=pce.EndTime)or
	(#FinalData.StartTime >= pce.StartTime and #FinalData.StartTime <pce.EndTime and #FinalData.EndTime > pce.EndTime) or
	(#FinalData.StartTime < pce.StartTime and #FinalData.EndTime > pce.EndTime)
	)--Validate if required. Group by machineinformation.MachineID,C.componentid,O.operationNo,#FinalData.StartTime,#FinalData.EndTime,pce.StartTime,pce.EndTime,IdealCount,ActualCount
	
	--Detecting ActualCount - ExceptionCount (at Day level)
	if (select count(*) from #Exceptions) > 0 
	Begin
		UPDATE #Exceptions SET ExCount = ISNULL(ExCount,0) + (floor(ISNULL(t2.comp,0) * ISNULL(ActualCount,0))/ISNULL(IdealCount,0)) From(
			select M.MachineID,C.componentid,O.operationNo,#Exceptions.ExStartTime,#Exceptions.ExEndTime,
			SUM(CEILING(CAST(autodata.partscount AS Float)/ISNULL(O.SubOperations,1))) as comp
			from autodata 
			inner join machineinformation M on autodata.mc=M.interfaceid 
			Inner join componentinformation C on autodata.Comp = C.interfaceid
			Inner join ComponentOperationPricing O ON  autodata.Opn = O.interfaceid and C.Componentid=O.componentid and M.MachineID = O.MachineID
			inner join #Exceptions on  #Exceptions.machineId = M.MachineID and #Exceptions.Componentid = C.componentid and #Exceptions.OperationNo = O.OperationNo
			Where Autodata.datatype = 1	and Autodata.ndtime > #Exceptions.ExStartTime and Autodata.ndtime <= #Exceptions.ExEndTime
			Group by M.MachineID,C.componentid,O.operationNo,#Exceptions.ExStartTime,#Exceptions.ExEndTime
		) As T2 Inner join #Exceptions on T2.MachineID = #Exceptions.MachineID and T2.componentid = #Exceptions.componentid 
		and T2.operationNo = #Exceptions.operationNo and T2.ExStartTime = #Exceptions.ExStartTime and T2.ExEndTime = #Exceptions.ExEndTime

		Update #FinalData set Actual = ISNULL(Actual,0) - ISNULL(ExCount,0) from (
			Select machineid,sum(ExCount) as ExCount --,StartTime,EndTime
			from #Exceptions
			group by machineid--,StartTime,EndTime
		) as t1 inner join #FinalData on t1.machineid = #FinalData.MachineID --and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime
	End

--Calculating DownTime (at Day level)
-- Type 1
UPDATE #FinalData SET Downtime = isnull(Downtime,0) + isNull(t1.down,0) from(
	select mc,sum(loadunload) as down--,#FinalData.StartTime,#FinalData.EndTime
	from autodata inner join #FinalData on autodata.mc = #FinalData.machineinterface
	where (autodata.msttime>=#FinalData.StartTime) and (autodata.ndtime<=#FinalData.EndTime)and (autodata.datatype=2)
	group by autodata.mc--,#FinalData.StartTime,#FinalData.EndTime
) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface --and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime

-- Type 2
UPDATE #FinalData SET Downtime = isnull(Downtime,0) + isNull(t1.down,0) from(
	select mc,sum(DateDiff(second, #FinalData.StartTime, ndtime)) down --#FinalData.StartTime,#FinalData.EndTime,
	from autodata inner join #FinalData on autodata.mc = #FinalData.machineinterface 
	where (autodata.sttime<#FinalData.StartTime) and (autodata.ndtime>#FinalData.StartTime)and (autodata.ndtime<=#FinalData.EndTime)and (autodata.datatype=2)
	group by autodata.mc--,#FinalData.StartTime,#FinalData.EndTime
) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface --and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime

-- Type 3
UPDATE #FinalData SET Downtime = isnull(Downtime,0) + isNull(t1.down,0) from( 
	select mc,sum(DateDiff(second, mstTime, #FinalData.EndTime))down --,#FinalData.StartTime,#FinalData.EndTime
	from autodata inner join #FinalData on autodata.mc = #FinalData.machineinterface 
	where (autodata.msttime>=#FinalData.StartTime) and (autodata.sttime<#FinalData.EndTime) and (autodata.ndtime>#FinalData.EndTime)
	and (autodata.datatype=2)group by autodata.mc--,#FinalData.StartTime,#FinalData.EndTime
) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface --and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime

-- Type 4
UPDATE #FinalData SET Downtime = isnull(Downtime,0) + isNull(t1.down,0) from (
	select mc,sum(DateDiff(second, #FinalData.StartTime, #FinalData.EndTime)) down --,#FinalData.StartTime,#FinalData.EndTime
	from autodata inner join #FinalData on autodata.mc = #FinalData.machineinterface 
	where autodata.msttime<#FinalData.StartTime and autodata.ndtime>#FinalData.EndTime and (autodata.datatype=2) 
	group by autodata.mc--,#FinalData.StartTime,#FinalData.EndTime
) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface --and t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime

/*
--Calculating DownTime (at Shift level)
-- Type 1
UPDATE #FinalData SET downtime_Shift = isnull(downtime_Shift,0) + isNull(t1.down,0) from(
	select mc,sum(loadunload) as down--,#FinalData.ShiftStartTime,#FinalData.ShiftEndTime
	from autodata inner join #FinalData on autodata.mc = #FinalData.machineinterface
	where (autodata.msttime>=#FinalData.ShiftStartTime) and (autodata.ndtime<=#FinalData.ShiftEndTime)and (autodata.datatype=2)
	group by autodata.mc--,#FinalData.ShiftStartTime,#FinalData.ShiftEndTime
) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface --and t1.ShiftStartTime = #FinalData.ShiftStartTime and t1.ShiftEndTime = #FinalData.ShiftEndTime

-- Type 2
UPDATE #FinalData SET downtime_Shift = isnull(downtime_Shift,0) + isNull(t1.down,0) from(
	select mc,sum(DateDiff(second, #FinalData.ShiftStartTime, ndtime)) down --,#FinalData.ShiftStartTime,#FinalData.ShiftEndTime
	from autodata inner join #FinalData on autodata.mc = #FinalData.machineinterface 
	where (autodata.msttime<#FinalData.ShiftStartTime) and (autodata.ndtime>#FinalData.ShiftStartTime)and (autodata.ndtime<=#FinalData.ShiftEndTime)and (autodata.datatype=2)
	group by autodata.mc--,#FinalData.ShiftStartTime,#FinalData.ShiftEndTime
) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface --and t1.ShiftStartTime = #FinalData.ShiftStartTime and t1.ShiftEndTime = #FinalData.ShiftEndTime

-- Type 3
UPDATE #FinalData SET downtime_Shift = isnull(downtime_Shift,0) + isNull(t1.down,0) from( 
	select mc,sum(DateDiff(second, mstTime, #FinalData.ShiftEndTime))down --,#FinalData.ShiftStartTime,#FinalData.ShiftEndTime
	from autodata inner join #FinalData on autodata.mc = #FinalData.machineinterface 
	where (autodata.msttime>=#FinalData.ShiftStartTime) and (autodata.sttime<#FinalData.ShiftEndTime) and (autodata.ndtime>#FinalData.ShiftEndTime)
	and (autodata.datatype=2)group by autodata.mc--,#FinalData.ShiftStartTime,#FinalData.ShiftEndTime
) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface --and t1.ShiftStartTime = #FinalData.ShiftStartTime and t1.ShiftEndTime = #FinalData.ShiftEndTime

-- Type 4
UPDATE #FinalData SET downtime_Shift = isnull(downtime_Shift,0) + isNull(t1.down,0) from (
	select mc,sum(DateDiff(second, #FinalData.ShiftStartTime, #FinalData.ShiftEndTime)) down --#FinalData.ShiftStartTime,#FinalData.ShiftEndTime,
	from autodata inner join #FinalData on autodata.mc = #FinalData.machineinterface 
	where autodata.msttime<#FinalData.ShiftStartTime and autodata.ndtime>#FinalData.ShiftEndTime and (autodata.datatype=2) 
	group by autodata.mc--,#FinalData.ShiftStartTime,#FinalData.ShiftEndTime
) as t1 inner join #FinalData on t1.mc = #FinalData.machineinterface --and t1.ShiftStartTime = #FinalData.ShiftStartTime and t1.ShiftEndTime = #FinalData.ShiftEndTime
*/

--Getting Planned Down Time 
Insert into #PDT (StartTime,EndTime,StartTimePDT,EndTimePDT,MachineID,MachineInterface,Actual,DownTime)
select fd.StartTime,fd.EndTime,
Case when fd.StartTime <= pdt.StartTime then pdt.StartTime else fd.StartTime End as StartTime,
Case when fd.EndTime >= pdt.EndTime then pdt.EndTime else fd.EndTime End as EndTime,
--pdt.StartTime,pdt.EndTime,
fd.MachineID,mi.interfaceid,0,0 
from #FinalData fd cross join planneddowntimes pdt
inner join machineinformation mi on mi.MachineID = fd.MachineID
where PDTstatus = 1  and fd.machineID = pdt.Machine and --and DownReason <> 'SDT'
((pdt.StartTime >= fd.StartTime and pdt.EndTime <= fd.EndTime)or 
(pdt.StartTime < fd.StartTime and pdt.EndTime > fd.StartTime and pdt.EndTime <=fd.EndTime)or
(pdt.StartTime >= fd.StartTime and pdt.StartTime <fd.EndTime and pdt.EndTime > fd.EndTime) or
(pdt.StartTime < fd.StartTime and pdt.EndTime > fd.EndTime))


--Calculating PLD Actual (i.e..PartsCount)(at Day level)
UPDATE #PDT SET Actual = ISNULL(Actual,0) + ISNULL(t2.comp,0)From(
	select Autodata.mc,--#PDT.StartTimePDT,#PDT.EndTimePDT,
	SUM(CEILING(CAST(autodata.partscount AS Float)/ISNULL(O.SubOperations,1))) as comp
	from autodata 
	inner join #PDT on autodata.mc = #PDT.machineinterface
	Inner join componentinformation C on autodata.Comp = C.interfaceid
	Inner join ComponentOperationPricing O ON  autodata.Opn = O.interfaceid and C.Componentid=O.componentid
	inner join machineinformation on machineinformation.machineid =O.machineid and autodata.mc=machineinformation.interfaceid
	Where Autodata.datatype = 1
	and Autodata.ndtime > #PDT.StartTimePDT and Autodata.ndtime <= #PDT.EndTimePDT
	Group by Autodata.mc--,#PDT.StartTimePDT,#PDT.EndTimePDT
) As T2 Inner join #PDT on T2.mc = #PDT.machineinterface --and T2.StartTimePDT = #PDT.StartTimePDT and T2.EndTimePDT = #PDT.EndTimePDT


	--Calculating PLD ExceptionCount(at Day level)
	delete #Exceptions
	Insert into #Exceptions
	select machineinformation.MachineID,C.componentid,O.operationNo,
	#PDT.StartTimePDT,#PDT.EndTimePDT,--pce.StartTime,pce.EndTime,
	Case when pce.StartTime <= #PDT.StartTimePDT then #PDT.StartTimePDT else pce.StartTime End as ExStartTime,
	Case when pce.EndTime >= #PDT.EndTimePDT then #PDT.EndTimePDT else pce.EndTime End as ExEndTime,0,
	isnull(ActualCount,0),Isnull(IdealCount,1)
	from #PDT 
	Inner join machineinformation on #PDT.MachineID = machineinformation.machineid 
	Inner join ComponentOperationPricing O ON  machineinformation.machineid=O.machineid 
	Inner join componentinformation C on C.Componentid=O.componentid 
	Inner join ProductionCountException pce on pce.machineID = #PDT.MachineID and pce.ComponentID = C.Componentid and pce.OperationNo = O.OperationNo 
	Where ((#PDT.StartTimePDT >= pce.StartTime and #PDT.EndTimePDT <= pce.EndTime)or 
	(#PDT.StartTimePDT < pce.StartTime and #PDT.EndTimePDT > pce.StartTime and #PDT.EndTimePDT <=pce.EndTime)or
	(#PDT.StartTimePDT >= pce.StartTime and #PDT.StartTimePDT <pce.EndTime and #PDT.EndTimePDT > pce.EndTime) or
	(#PDT.StartTimePDT < pce.StartTime and #PDT.EndTimePDT > pce.EndTime)
	)
	--Detecting PLD ActualCount - ExceptionCount (at Day level)
	if (select count(*) from #Exceptions) > 0 
	Begin
		UPDATE #Exceptions SET ExCount = ISNULL(ExCount,0) + (floor(ISNULL(t2.comp,0) * ISNULL(ActualCount,0))/ISNULL(IdealCount,0)) From(
			select M.MachineID,C.componentid,O.operationNo,#Exceptions.ExStartTime,#Exceptions.ExEndTime,
			SUM(CEILING(CAST(autodata.partscount AS Float)/ISNULL(O.SubOperations,1))) as comp
			from autodata 
			inner join machineinformation M on autodata.mc=M.interfaceid 
			Inner join componentinformation C on autodata.Comp = C.interfaceid
			Inner join ComponentOperationPricing O ON  autodata.Opn = O.interfaceid and C.Componentid=O.componentid and M.MachineID = O.MachineID
			inner join #Exceptions on  #Exceptions.machineId = M.MachineID and #Exceptions.Componentid = C.componentid and #Exceptions.OperationNo = O.OperationNo
			Where Autodata.datatype = 1	and Autodata.ndtime > #Exceptions.ExStartTime and Autodata.ndtime <= #Exceptions.ExEndTime
			Group by M.MachineID,C.componentid,O.operationNo,#Exceptions.ExStartTime,#Exceptions.ExEndTime
		) As T2 Inner join #Exceptions on T2.MachineID = #Exceptions.MachineID and T2.componentid = #Exceptions.componentid 
		and T2.operationNo = #Exceptions.operationNo and T2.ExStartTime = #Exceptions.ExStartTime and T2.ExEndTime = #Exceptions.ExEndTime

		Update #PDT set Actual = ISNULL(Actual,0) - ISNULL(ExCount,0) from (
			Select machineid,sum(ExCount) as ExCount --,StartTime,EndTime
			from #Exceptions
			group by machineid--,StartTime,EndTime
		) as t1 inner join #PDT on t1.machineid = #PDT.MachineID --and t1.StartTime = #PDT.StartTimePDT and t1.EndTime = #PDT.EndTimePDT
	End

--Calculating DownTime within PDT (DayLevel)
-- Type 1
UPDATE #PDT SET downtime = isnull(downtime,0) + isNull(t1.down,0) from(
	select mc,sum(loadunload) as down--,#PDT.StartTimePDT,#PDT.EndTimePDT
	from autodata inner join #PDT on autodata.mc = #PDT.machineinterface
	where (autodata.msttime>=#PDT.StartTimePDT) and (autodata.ndtime<=#PDT.EndTimePDT)and (autodata.datatype=2)
	group by autodata.mc--,#PDT.StartTimePDT,#PDT.EndTimePDT
) as t1 inner join #PDT on t1.mc = #PDT.machineinterface --and t1.StartTimePDT = #PDT.StartTimePDT and t1.EndTimePDT = #PDT.EndTimePDT

-- Type 2
UPDATE #PDT SET downtime = isnull(downtime,0) + isNull(t1.down,0) from(
	select mc,sum(DateDiff(second, #PDT.StartTimePDT, ndtime)) down --,#PDT.StartTimePDT,#PDT.EndTimePDT
	from autodata inner join #PDT on autodata.mc = #PDT.machineinterface 
	where (autodata.msttime<#PDT.StartTimePDT) and (autodata.ndtime>#PDT.StartTimePDT)and (autodata.ndtime<=#PDT.EndTimePDT)and (autodata.datatype=2)
	group by autodata.mc--,#PDT.StartTimePDT,#PDT.EndTimePDT
) as t1 inner join #PDT on t1.mc = #PDT.machineinterface --and t1.StartTimePDT = #PDT.StartTimePDT and t1.EndTimePDT = #PDT.EndTimePDT

-- Type 3
UPDATE #PDT SET downtime = isnull(downtime,0) + isNull(t1.down,0) from( 
	select mc,sum(DateDiff(second, mstTime, #PDT.EndTimePDT))down --,#PDT.StartTimePDT,#PDT.EndTimePDT
	from autodata inner join #PDT on autodata.mc = #PDT.machineinterface 
	where (autodata.msttime>=#PDT.StartTimePDT) and (autodata.sttime<#PDT.EndTimePDT) and (autodata.ndtime>#PDT.EndTimePDT)
	and (autodata.datatype=2)group by autodata.mc--,#PDT.StartTimePDT,#PDT.EndTimePDT
) as t1 inner join #PDT on t1.mc = #PDT.machineinterface --and t1.StartTimePDT = #PDT.StartTimePDT and t1.EndTimePDT = #PDT.EndTimePDT

-- Type 4
UPDATE #PDT SET downtime = isnull(downtime,0) + isNull(t1.down,0) from (
	select mc,sum(DateDiff(second, #PDT.StartTimePDT, #PDT.EndTimePDT)) down --,#PDT.StartTimePDT,#PDT.EndTimePDT
	from autodata inner join #PDT on autodata.mc = #PDT.machineinterface 
	where autodata.msttime<#PDT.StartTimePDT and autodata.ndtime>#PDT.EndTimePDT and (autodata.datatype=2) 
	group by autodata.mc--,#PDT.StartTimePDT,#PDT.EndTimePDT
) as t1 inner join #PDT on t1.mc = #PDT.machineinterface --and t1.StartTimePDT = #PDT.StartTimePDT and t1.EndTimePDT = #PDT.EndTimePDT

--Detecting PDT Actual and PDT DownTime (At Day Level)
Update #FinalData 
set Actual = Isnull(#FinalData.Actual,0) - Isnull(t1.Actual,0), 
Downtime = Isnull(#FinalData.Downtime,0) - Isnull(t1.DownTime,0) 
from (
	Select StartTime,EndTime,MachineID,Sum(isnull(Actual,0)) as Actual,sum(isnull(DownTime,0)) as DownTime from #PDT group by StartTime,EndTime,MachineID
) as t1 inner join #FinalData on t1.StartTime = #FinalData.StartTime and t1.EndTime = #FinalData.EndTime and t1.MachineID = #FinalData.MachineID


/*
--Calculating Downtime within PDT (ShiftLevel) 
Delete #PDT
Insert into #PDT (StartTime,EndTime,StartTimePDT,EndTimePDT,MachineID,MachineInterface,Actual,DownTime)
select fd.ShiftStartTime,fd.ShiftEndTime,
Case when fd.ShiftStartTime <= pdt.StartTime then pdt.StartTime else fd.ShiftStartTime End as StartTime,
Case when fd.ShiftEndTime >= pdt.EndTime then pdt.EndTime else fd.ShiftEndTime End as EndTime,
--pdt.StartTime,pdt.EndTime,
fd.MachineID,mi.interfaceid,0,0 
from #FinalData fd cross join planneddowntimes pdt
inner join machineinformation mi on mi.MachineID = fd.MachineID
where PDTstatus = 1  and fd.machineID = pdt.Machine and --and DownReason <> 'SDT'
((pdt.StartTime >= fd.ShiftStartTime and pdt.EndTime <= fd.ShiftEndTime)or 
(pdt.StartTime < fd.ShiftStartTime and pdt.EndTime > fd.ShiftStartTime and pdt.EndTime <=fd.ShiftEndTime)or
(pdt.StartTime >= fd.ShiftStartTime and pdt.StartTime <fd.ShiftEndTime and pdt.EndTime > fd.ShiftEndTime) or
(pdt.StartTime < fd.ShiftStartTime and pdt.EndTime > fd.ShiftEndTime))

-- Type 1
UPDATE #PDT SET downtime = isnull(downtime,0) + isNull(t1.down,0) from(
	select mc,sum(loadunload) as down--,#PDT.StartTimePDT,#PDT.EndTimePDT
	from autodata inner join #PDT on autodata.mc = #PDT.machineinterface
	where (autodata.msttime>=#PDT.StartTimePDT) and (autodata.ndtime<=#PDT.EndTimePDT)and (autodata.datatype=2)
	group by autodata.mc--,#PDT.StartTimePDT,#PDT.EndTimePDT
) as t1 inner join #PDT on t1.mc = #PDT.machineinterface --and t1.StartTimePDT = #PDT.StartTimePDT and t1.EndTimePDT = #PDT.EndTimePDT

-- Type 2
UPDATE #PDT SET downtime = isnull(downtime,0) + isNull(t1.down,0) from(
	select mc,sum(DateDiff(second, #PDT.StartTimePDT, ndtime)) down--,#PDT.StartTimePDT,#PDT.EndTimePDT 
	from autodata inner join #PDT on autodata.mc = #PDT.machineinterface 
	where (autodata.msttime<#PDT.StartTimePDT) and (autodata.ndtime>#PDT.StartTimePDT)and (autodata.ndtime<=#PDT.EndTimePDT)and (autodata.datatype=2)
	group by autodata.mc--,#PDT.StartTimePDT,#PDT.EndTimePDT
) as t1 inner join #PDT on t1.mc = #PDT.machineinterface --and t1.StartTimePDT = #PDT.StartTimePDT and t1.EndTimePDT = #PDT.EndTimePDT

-- Type 3
UPDATE #PDT SET downtime = isnull(downtime,0) + isNull(t1.down,0) from( 
	select mc,sum(DateDiff(second, mstTime, #PDT.EndTimePDT))down --,#PDT.StartTimePDT,#PDT.EndTimePDT
	from autodata inner join #PDT on autodata.mc = #PDT.machineinterface 
	where (autodata.msttime>=#PDT.StartTimePDT) and (autodata.sttime<#PDT.EndTimePDT) and (autodata.ndtime>#PDT.EndTimePDT)
	and (autodata.datatype=2)group by autodata.mc--,#PDT.StartTimePDT,#PDT.EndTimePDT
) as t1 inner join #PDT on t1.mc = #PDT.machineinterface --and t1.StartTimePDT = #PDT.StartTimePDT and t1.EndTimePDT = #PDT.EndTimePDT

-- Type 4
UPDATE #PDT SET downtime = isnull(downtime,0) + isNull(t1.down,0) from (
	select mc,sum(DateDiff(second, #PDT.StartTimePDT, #PDT.EndTimePDT)) down --,#PDT.StartTimePDT,#PDT.EndTimePDT
	from autodata inner join #PDT on autodata.mc = #PDT.machineinterface 
	where autodata.msttime<#PDT.StartTimePDT and autodata.ndtime>#PDT.EndTimePDT and (autodata.datatype=2) 
	group by autodata.mc--,#PDT.StartTimePDT,#PDT.EndTimePDT
) as t1 inner join #PDT on t1.mc = #PDT.machineinterface --and t1.StartTimePDT = #PDT.StartTimePDT and t1.EndTimePDT = #PDT.EndTimePDT


--Detecting Downtime within PDT (ShiftLevel) 
Update #FinalData 
set DownTime_Shift = Isnull(#FinalData.DownTime_Shift,0) - Isnull(t1.DownTime,0) 
from (
	Select StartTime,EndTime,MachineID,sum(isnull(DownTime,0)) as DownTime from #PDT group by StartTime,EndTime,MachineID
) as t1 inner join #FinalData on t1.StartTime = #FinalData.ShiftStartTime and t1.EndTime = #FinalData.ShiftEndTime and t1.MachineID = #FinalData.MachineID
*/


Insert into #machineRunningStatus
select fd.MachineID,fd.MachineInterface,sttime,ndtime,datatype,null,0 from rawdata 
inner join (select mc,max(slno) as slno from rawdata where sttime < @CurrTime and ndtime < @CurrTime group by mc ) t1 on t1.mc=rawdata.mc and t1.slno=rawdata.slno 
right outer join #FinalData fd on fd.MachineInterface = rawdata.mc  
order by rawdata.mc

Update #FinalData 
--set DownTime_Shift = Isnull(#FinalData.DownTime_Shift,0) + Isnull(t2.DownTime,0),Downtime = Isnull(#FinalData.Downtime,0) + Isnull(t2.DownTime,0)  
set Downtime = Isnull(#FinalData.Downtime,0) + Isnull(t2.DownTime,0)  
from (
	Select fd.MachineID,StartTime,EndTime,t1.sttime,t1.ndtime,t1.datatype,
	dateDiff(second,t1.LastRecordPlusThreshold,@CurrTime) as DownTime
	from #machineRunningStatus mrs inner join  #FinalData fd on fd.MachineID = mrs.MachineID
	inner join (
		Select mrs.MachineID,sttime,ndtime,datatype,
		case when (datatype = 1)or(datatype = 2)or(datatype = 42) then dateadd(ss,Threshold,ndtime) 
		when datatype = 40 then dateadd(ss,Threshold,sttime) end as LastRecordPlusThreshold
		from #machineRunningStatus mrs 
		inner join AndonConfigurator ac on mrs.MachineID = ac.MachineID
		inner join #FinalData fd on fd.MachineID = mrs.MachineID
	) as t1 on t1.machineID = fd.machineID and t1.LastRecordPlusThreshold >= fd.StartTime and t1.LastRecordPlusThreshold <= fd.EndTime 
) as t2 inner join #FinalData on t2.MachineID = #FinalData.MachineID 

--select @CurrTime = '2009-12-01 07:00:00'--getdate()

update #FinalData set DownTime_Last = Isnull(#FinalData.DownTime_Last,0) + datediff(second,t1.StartTime,t1.EndTime) from (
	Select #FinalData.machineinterface,
	isnull(case when #FinalData.StartTime > max(A.sttime) then #FinalData.StartTime else max(A.sttime) end,#FinalData.StartTime) as StartTime,
	isnull(max(A.ndtime),#FinalData.StartTime) as EndTime
	from #FinalData left outer join autodata A on #FinalData.machineinterface = A.mc
	and A.ndtime > #FinalData.StartTime and A.ndtime < @CurrTime and A.datatype = 2
	group by #FinalData.machineinterface,#FinalData.StartTime
) as t1 inner join #FinalData on t1.machineinterface = #FinalData.machineinterface

	
update #FinalData set DownTime_Last = Isnull(#FinalData.DownTime_Last,0) - datediff(second,t1.StartTime,t1.EndTime) from (
	select t1.Machineinterface,
	case when t1.StartTime > #PDT.StartTimePDT then t1.StartTime else #PDT.StartTimePDT end as StartTime,
	case when t1.EndTime > #PDT.EndTimePDT then #PDT.EndTimePDT else t1.EndTime end as EndTime
	--t1.StartTime,t1.EndTime,#PDT.StartTimePDT,#PDT.EndTimePDT 
	from (
		Select #FinalData.machineinterface,
		isnull(case when #FinalData.StartTime > max(A.sttime) then #FinalData.StartTime else max(A.sttime) end,#FinalData.StartTime) as StartTime,
		isnull(max(A.ndtime),#FinalData.StartTime) as EndTime
		from #FinalData left outer join autodata A on #FinalData.machineinterface = A.mc
		and A.ndtime > #FinalData.StartTime and A.ndtime < @CurrTime and A.datatype = 2
		group by #FinalData.machineinterface,#FinalData.StartTime
		) t1 
		cross join #PDT 
	where t1.machineinterface = #PDT.machineinterface and 
	((t1.StartTime>=#PDT.StartTimePDT and t1.EndTime<=#PDT.EndTimePDT)or
	(t1.StartTime<#PDT.StartTimePDT and t1.EndTime >#PDT.StartTimePDT and t1.EndTime<=#PDT.EndTimePDT)or
	(t1.StartTime>=#PDT.StartTimePDT and t1.StartTime<#PDT.EndTimePDT and t1.EndTime>#PDT.EndTimePDT)or
	(t1.StartTime<#PDT.StartTimePDT and t1.EndTime>#PDT.EndTimePDT))
) as t1 inner join #FinalData on t1.machineinterface = #FinalData.machineinterface

update #machineRunningStatus set ColorCode = 'Red' --(For Invalid Machines)
update #machineRunningStatus set ColorCode = 'Lime' where datatype in (11,41)
update #machineRunningStatus set ColorCode = 'Red' where datatype in (42,2)

update #machineRunningStatus set ColorCode = t1.ColorCode from (
Select mrs.MachineID,Case when (
case when datatype = 40 then datediff(second,sttime,@CurrTime)-Threshold
when datatype = 1 then datediff(second,ndtime,@CurrTime)-Threshold
end) > 0 then 'Red' else 'Lime' end as ColorCode
from #machineRunningStatus mrs inner join AndonConfigurator ac on mrs.MachineID = ac.MachineID and datatype in (40,1)
) as t1 inner join #machineRunningStatus on t1.MachineID = #machineRunningStatus.MachineID

--update #machineRunningStatus set ColorCode = 'Yellow' where MachineID in (select machine from planneddowntimes where PDTstatus = 1 and StartTime <= @CurrTime and endtime >= @CurrTime)

update #machineRunningStatus set ColorCode = t1.ColorCode from (
	select machineinformation.machineid,ad.recordtype,
	case when ad.recordtype=81 then 'Yellow' else 'NotYellow' end as ColorCode
	,max(ad.starttime) as StartTime from autodatadetails ad 
	inner join (select machine,max(autodatadetails.starttime) as StartTime from autodatadetails where recordtype in (81,80) group by machine) as t1 
	on ad.machine = t1.machine and ad.StartTime = t1.StartTime
	inner join machineinformation on machineinformation.interfaceid = ad.machine
	where recordtype in (81,80) group by machineinformation.machineid,ad.recordtype
) as t1 inner join #machineRunningStatus on t1.MachineID = #machineRunningStatus.MachineID and t1.RecordType = 81


Update #FinalData Set RunningStatus = t1.ColorCode from (
	Select MachineID,ColorCode from #machineRunningStatus
) as t1 inner join #FinalData on t1.machineID = #FinalData.MachineID

Select * from #FinalData cross join 
(Select dbo.f_FormatTime(sum(isnull(Downtime,0)),'HH:MM:SS') as Total_DownTime_Day,
		dbo.f_FormatTime( sum(isnull(DownTime_Last,0)),'HH:MM:SS') as Total_DownTime_Last
		from #FinalData) as t1

--Select * from #machineRunningStatus
--select * from planneddowntimes where StartTime <= getdate() and endtime >= getdate()


END
