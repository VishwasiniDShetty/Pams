/****** Object:  Procedure [dbo].[s_GetAndonDisplayData_prediction]    Committed by VersionSQL https://www.versionsql.com ******/

/*------------Procedure Created By KarthikR on 14/SEP/2010 ------------------------------
--ER0243-14/SEP/2010-KarthikR :: New Appliacation and Procedure to drive Andon screen for BOSCH with Prediction.
--DR0283 - 07/jun/2011-Karthik R While removing PDT from Downtime,the code picks only 1st record instead of all records of PDT
Select * from plantinformation
Select * from machineinformation
Select * from rawdata where slno=10881
select *  from planneddowntimes
Select max(sttime) from autodata
Select * from autodata where mc='1014' and sttime>='2010-06-01 06:00:00.000'
s_GetAndonDisplayData_prediction 'Plant 1','','Plantlevel'
update componentoperationpricing set targetpercent=100
--ER0293
--1>To apply PDT for Target if Target type is '%ideal'
--2>While calculating Target prediction has been applied by considering the Last CO as occurred for the remaining time period of the logical Day 's target calculation
-----------------------------------------------------------------------------------------*/
CREATE     	PROCEDURE [dbo].[s_GetAndonDisplayData_prediction]
	@PlantID as nvarchar(50),
	@machineID as nvarchar(50)='',
	@MachinePlantLevel as nvarchar(50)='' --'MachineLevel','Plantlevel'
AS
BEGIN
--go
--Select * from shiftdetails
-- 
--s_GetAndonDisplayData_prediction 'W3200-CAMSHAFT','9816','machinelevel'
--go
--s_GetAndonDisplayData_prediction 'NPCL','','Plantlevel'




Declare @StartTime as DateTime
Declare @EndTime as DateTime
Declare @CurrTime as DateTime
declare @TrSql3 as nvarchar(4000)
select @CurrTime =getdate()--'08-sep-2010 12:00:00 PM'
--select @CurrTime ='2010-06-01 02:00:00 PM'
Declare @curmachineid as nvarchar(50)
Declare @curcomp  as nvarchar(50)
Declare @curop  as int
Declare @cursttime  as Datetime
Declare @curndtime  as datetime
Declare @curstarttime  as Datetime
Declare @curEndtime  as datetime

Declare @cmachineid as nvarchar(50)
Declare @compid  as nvarchar(50)
Declare @operationid  as int
Declare @sttime  as Datetime
Declare @ndtime  as datetime
Declare @CEndtime  as Datetime
Declare @CStarttime  as datetime
print(@currtime)
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
		LastDownStart Datetime,
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
		DownTime Int--,
		--Max_slno bigint
	)
CREATE TABLE #Target
	(
		MachineID NvarChar(50),
		MachineInterface nvarchar(50),
		ComponentID Nvarchar(50),
		OperationNo Int,
		sttime Datetime,
		ndtime Datetime,
		StartTime DateTime,
		EndTime DateTime
	)

CREATE TABLE #Target_actime
	(
		MachineInterface nvarchar(50),
		ComponentID Nvarchar(50),
		OperationNo Int,
		sttime Datetime,
		ndtime Datetime,
		Pdt int
	)

--swathi
declare @Targetsource nvarchar(50)
select @Targetsource=ValueInText from Shopdefaults where Parameter='TargetFrom'
--update Shopdefaults set ValueInText='% Ideal' from Shopdefaults where Parameter='TargetFrom'
--select  @Targetsource
--Swathi


Insert #GetShiftTime exec s_GetShiftTimeSA @CurrTime


--Select * from #GetShiftTime
--select * from plantmachine where plantid = @PlantID
if @MachinePlantLevel = 'Plantlevel'
Begin
	Print 's'	
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


--return

IF ISNULL(@Targetsource,'')='% Ideal'
BEGIN

insert into #target
Select f.machineid,mc,comp,opn,msttime,ndtime,f.starttime,f.endtime from  #FinalData F inner join autodata A on F.MachineInterface=A.mc
				 where 
				((A.ndtime>=f.Starttime  and  A.ndtime<=f.Endtime) 
--				OR (A.sttime<f.Starttime and  A.ndtime>f.Starttime and A.ndtime<=f.Endtime)
--				OR (A.msttime>=f.Starttime  and A.sttime<f.Endtime  and A.ndtime>f.Endtime)
--				OR (A.msttime<f.Starttime and A.ndtime>f.Endtime )
				)
order by mc,sttime
/*
SELECT MachineInterface,
		ComponentID ,
		OperationNo ,
			Sttime,ndtime,Starttime,Endtime
		from 	#target
		order by MachineInterface,
			Sttime,ndtime*/
--select * from #target
	
	declare @RptCursor  cursor
set  @RptCursor= CURSOR FOR
		SELECT MachineInterface,
		ComponentID ,
		OperationNo ,
			Sttime,ndtime,Starttime,Endtime
		from 	#target
		order by MachineInterface,
			Sttime,ndtime
	
		OPEN @RptCursor
				
		FETCH NEXT FROM @RptCursor INTO @cmachineid, @compid, @operationid,@sttime,@ndtime,@cstarttime,@cendtime
		if (@@fetch_status = 0)
		begin
		  --select @qty = 1
		  --update #Tblweeklyprodrpt set qty = @qty where current of rptcursor
		
		  -- initialize current variables		
		  select @curmachineid = @cmachineid	
		  select @curcomp = @compid
		  select @curop = @operationid
		  Select @cursttime=@sttime
		  Select @curndtime=@ndtime
		  Select @curstarttime=@cstarttime
		  Select @curendtime=@cendtime
		end	
		
		WHILE (@@fetch_status <> -1)
		BEGIN
			  IF (@@fetch_status <> -2)
			    BEGIN
					FETCH NEXT FROM @RptCursor INTO @cmachineid, @compid, @operationid,@sttime,@ndtime,@cstarttime,@cendtime
					if (@@fetch_status = 0) and (@curmachineid = @cmachineid) and (@curcomp = @compid) and (@curop = @operationid)
					begin
							 Select @curndtime=@ndtime
						--update #Tblweeklyprodrpt set qty = @qty where current of rptcursor
					end
					else if (@@fetch_status = 0)
					begin -- 2
						--select @qty = @qty + 1
						--insert into #Target_actime values (@curmachineid,@curcomp,@curop,@cursttime,@curndtime)
						insert into #Target_actime
						Select @curmachineid as mc,@curcomp as comp,@curop as opn,
							Case  when @cursttime<@curstarttime then @curstarttime else @cursttime end as start,
							case when @curndtime>@curendtime then @curendtime Else @curndtime End as  endt,0
						--	into #Target_actime 
						select @curmachineid = @cmachineid	
						select @curcomp = @compid
						select @curop = @operationid
						Select @cursttime=@sttime
						Select @curndtime=@ndtime
					end
			    END
		END
insert into #Target_actime
						Select @curmachineid as mc,@curcomp as comp,@curop as opn,
							Case  when @cursttime<@curstarttime then @curstarttime else @cursttime end as start,
							case when @curndtime>@curendtime then @curendtime Else @curndtime End as  endt,0
						
close @rptcursor
deallocate @rptcursor
--Select * from #Target_actime
------update #Target_actime set sttime=,ndtime=
--Select * from #Target_actime

update #Target_actime set ndtime=t1.Endtime from #Target_actime inner join
(Select #Target_actime.machineinterface,max(#Target_actime.ndtime)as ndtime,#finaldata.Endtime from #Target_actime 
	inner join #finaldata on #finaldata.machineinterface=#Target_actime.machineinterface
 group by #Target_actime.machineinterface,#finaldata.Endtime )T1
on T1.machineinterface=#Target_actime.machineinterface and t1.ndtime=#Target_actime.ndtime

--Select * from #Target_actime
--return

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')<>'N' --and  @MachinePlantLevel= 'PlantLevel'
BEGIN

update #Target_actime set pdt=t3.pdt
from (Select t2.machineinterface,T2.Machine,T2.sttime,T2.ndtime,sum(datediff(ss,T2.StartTimepdt,t2.EndTimepdt))as pdt
from 
(
Select T1.*,Pdt.machine,
Case when  T1.Sttime <= pdt.StartTime then pdt.StartTime else T1.Sttime End as StartTimepdt,
Case when  T1.ndtime >= pdt.EndTime then pdt.EndTime else T1.ndtime End as EndTimepdt
 from #Target_actime T1
inner join #FinalData fd on fd.machineinterface=T1.machineinterface
inner join Planneddowntimes pdt on fd.machineid=Pdt.machine
where PDTstatus = 1  and --pdt.Machine=@machineid and 
((pdt.StartTime >= t1.Sttime and pdt.EndTime <= t1.ndTime)or 
(pdt.StartTime < t1.Sttime and pdt.EndTime > t1.Sttime and pdt.EndTime <=t1.ndTime)or
(pdt.StartTime >= t1.Sttime and pdt.StartTime <t1.ndTime and pdt.EndTime >t1.ndTime) or
(pdt.StartTime <  t1.Sttime and pdt.EndTime >t1.ndTime))
--order by T1.machineinterface,t1.sttime
)T2
group by  t2.machineinterface,T2.Machine,T2.sttime,T2.ndtime
) T3 
inner join #Target_actime T on T.machineinterface=T3.machineinterface
and T.Sttime=T3.Sttime
and  T.ndtime=T3.ndtime
--order by T2.Machine,T2.sttime,T2.ndtime
End
--Select * from #Target_actime
--return

update #FinalData set target=T1.target
from (
Select  M.machineid,
--T.sttime,T.ndtime,T.pdt,datediff(ss,t.sttime,t.ndtime),datediff(ss,t.sttime,t.ndtime)-t.pdt,Co.cycletime,(datediff(ss,t.sttime,t.ndtime)-t.pdt)/Co.cycletime
sum((((datediff(second,T.sttime,T.ndtime)-isnull(pdt,0))*Co.suboperations)/Co.cycletime)*isnull(Co.targetpercent,100) /100) as target
 from 
#target_actime T
inner join machineinformation M on M.Interfaceid=T.machineinterface
inner join componentinformation C on C.interfaceid=T.componentid
inner join componentoperationpricing CO on M.machineid=co.machineid and c.componentid=Co.componentid
and Co.interfaceid=T.OperationNo
--order by M.machineid,T.sttime,T.ndtime
 group by M.Machineid
)T1 inner join #FinalData on T1.machineid=#FinalData.machineid
--inner join 

--Select * from #FinalData
/*
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Ptime_4m_PLD')<>'N' --and  @MachinePlantLevel= 'PlantLevel'
BEGIN


update #finaldata set Target = Isnull(#FinalData.Target,0) -( (cast(T1.PDT as float)/cast(datediff(ss,T1.Starttime,t1.Endtime)as float))* Isnull(#FinalData.Target,0))--Isnull(t2.DownTime,0)
from(

Select T2.machineid,T2.Starttime,t2.Endtime,sum(datediff(ss,t2.starttimepdt,t2.endtimepdt)) as PDT 
from
(
select fD.machineid,fd.Starttime,fd.Endtime,
Case when  fd.Starttime <= pdt.StartTime then pdt.StartTime else  fd.Starttime End as StartTimepdt,
Case when @currtime >= pdt.EndTime then pdt.EndTime else @currtime End as EndTimepdt
From Planneddowntimes pdt 
 
inner join #FinalData fD on fd.machineid=Pdt.machine
where PDTstatus = 1  and --pdt.Machine=@machineid and 
((pdt.StartTime >= fd.Starttime and pdt.EndTime <= fd.EndTime)or 
(pdt.StartTime < fd.Starttime and pdt.EndTime > fd.Starttime and pdt.EndTime <=fd.EndTime)or
(pdt.StartTime >= fd.Starttime and pdt.StartTime <fd.EndTime and pdt.EndTime >fd.EndTime) or
(pdt.StartTime <  fd.Starttime and pdt.EndTime >fd.EndTime))
)T2
Group by t2.machineid,t2.Starttime,t2.Endtime
)t1 inner join #finaldata on #finaldata.machineid= t1.machineid
end
*/
--Select * from #finaldata


END

Else
	Begin

			Update #FinalData set Target = isnull(#FinalData.Target,0) + isNull(t1.target,0) from (
				select #FinalData.MachineID,sum(Isnull(ShiftHourTargets.target,0)) as Target from #FinalData inner join  ShiftHourTargets on 
				#FinalData.machineID = ShiftHourTargets.machineID and #FinalData.StartTime<=HourStart and
				#FinalData.EndTime>=HourEnd Group by #FinalData.MachineID
			) as t1 inner join #FinalData on #FinalData.machineID = t1.MachineID

	End
--select * from #finaldata
--return




/* Commented From Here
--Calculating Target(at Day level)
Update #FinalData set Target = isnull(#FinalData.Target,0) + isNull(t1.target,0) from (
	select #FinalData.MachineID,sum(Isnull(ShiftHourTargets.target,0)) as Target from #FinalData inner join  ShiftHourTargets on 
	#FinalData.machineID = ShiftHourTargets.machineID and #FinalData.StartTime<=HourStart and
	#FinalData.EndTime>=HourEnd Group by #FinalData.MachineID
) as t1 inner join #FinalData on #FinalData.machineID = t1.MachineID
 Commented Till Here */


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



--Getting Planned Down Time 
If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N'
BEGIN
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
End



--mod 5-Karthick R
Insert into #machineRunningStatus
select fd.MachineID,fd.MachineInterface,sttime,ndtime,datatype,null,0 from rawdata 
inner join (select mc,max(slno) as slno from rawdata where sttime < @CurrTime and ndtime < @CurrTime group by mc ) t1 on t1.mc=rawdata.mc and t1.slno=rawdata.slno 
right outer join #FinalData fd on fd.MachineInterface = rawdata.mc  
order by rawdata.mc




--mod 5-Karthick R
Declare @startdate as Datetime
select top 1 @startdate=Starttime from #Finaldata
--print()
update #machineRunningStatus set datatype=9999,sttime=@startdate
where sttime<@startdate or  isnull(sttime,'1900-01-01')='1900-01-01'

update #machineRunningStatus set datatype=9999,ndtime=@currtime
where ndtime<@startdate or  isnull(ndtime,'1900-01-01')='1900-01-01'

--update #machineRunningStatus set datatype=9999,ndtime=@currtime
--where ndtime<@currtime and ndtime<(Select top 1 starttime from #FinalData)
--Select * from #FinalData
--Select * from #machineRunningStatus
--return
Update #FinalData 
set DownTime_Last = Isnull(#FinalData.DownTime_Last,0) + Isnull(t2.DownTime,0)
,lastDownstart=t2.LastRecordPlusThreshold
from (
	Select fd.MachineID,StartTime,EndTime,t1.sttime,t1.ndtime,t1.datatype,
	dateDiff(second,t1.LastRecordPlusThreshold,@CurrTime) as DownTime,t1.LastRecordPlusThreshold
	from #machineRunningStatus mrs inner join  #FinalData fd on fd.MachineID = mrs.MachineID
	inner join (
		Select mrs.MachineID,sttime,ndtime,datatype,
		case when (datatype = 1)or(datatype = 2)or(datatype = 42) then dateadd(ss,isnull(Threshold,10),ndtime) 
		when datatype = 40 then dateadd(ss,isnull(Threshold,10),sttime)
		when datatype=9999 then sttime end as LastRecordPlusThreshold
		from #machineRunningStatus mrs 
		left outer join AndonConfigurator ac on mrs.MachineID = ac.MachineID
		inner join #FinalData fd on fd.MachineID = mrs.MachineID
	) as t1 on t1.machineID = fd.machineID and t1.LastRecordPlusThreshold >= fd.StartTime and t1.LastRecordPlusThreshold <=@currtime
) as t2 inner join #FinalData on t2.MachineID = #FinalData.MachineID 

--Select * from #finaldata
--return
--DR0283 - 07/jun/2011-Karthik R-from here
/*
			If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' and  @MachinePlantLevel= 'MachineLevel'
			BEGIN
			update #finaldata set DownTime_Last = Isnull(#FinalData.DownTime_Last,0) - T1.PDT--Isnull(t2.DownTime,0)
			from(
			--DR0283 - 07/jun/2011-Karthik R-from here
			Select T2.machineid,sum(datediff(ss,t2.starttime,t2.endtime)) as PDT
			from
			--DR0283 - 07/jun/2011-Karthik R -till here
			(
			select fD.machineid,
			Case when  fd.lastdownstart <= pdt.StartTime then pdt.StartTime else  fd.lastdownstart End as StartTime,
			Case when @currtime >= pdt.EndTime then pdt.EndTime else @currtime End as EndTime
			From Planneddowntimes pdt 
			inner join #FinalData fD on fd.machineid=Pdt.machine
			where PDTstatus = 1  and --pdt.Machine=@machineid and 
			((pdt.StartTime >= fd.lastdownstart and pdt.EndTime <= @currtime)or 
			(pdt.StartTime < fd.lastdownstart and pdt.EndTime > fd.lastdownstart and pdt.EndTime <=@currtime)or
			(pdt.StartTime >= fd.lastdownstart and pdt.StartTime <@currtime and pdt.EndTime >@currtime) or
			(pdt.StartTime <  fd.lastdownstart and pdt.EndTime >@currtime))

			)T2
			group by T2.MAchineid

			)t1 inner join #finaldata on #finaldata.machineID=t1.machineid
			end
*/

If (SELECT ValueInText From CockpitDefaults Where Parameter ='Ignore_Dtime_4m_PLD')<>'N' --and  @MachinePlantLevel= 'PlantLevel'
BEGIN
update #finaldata set DownTime_Last = Isnull(#FinalData.DownTime_Last,0) - T1.PDT--Isnull(t2.DownTime,0)
from(

Select sum(datediff(ss,t2.starttime,t2.endtime)) as PDT from

(
select fD.machineid,
Case when  fd.lastdownstart <= pdt.StartTime then pdt.StartTime else  fd.lastdownstart End as StartTime,
Case when @currtime >= pdt.EndTime then pdt.EndTime else @currtime End as EndTime
From Planneddowntimes pdt 
inner join #FinalData fD on fd.machineid=Pdt.machine
where PDTstatus = 1  and --pdt.Machine=@machineid and 
((pdt.StartTime >= fd.lastdownstart and pdt.EndTime <= @currtime)or 
(pdt.StartTime < fd.lastdownstart and pdt.EndTime > fd.lastdownstart and pdt.EndTime <=@currtime)or
(pdt.StartTime >= fd.lastdownstart and pdt.StartTime <@currtime and pdt.EndTime >@currtime) or
(pdt.StartTime <  fd.lastdownstart and pdt.EndTime >@currtime))
)T2

)t1 
end
--DR0283 - 07/jun/2011-Karthik R -till here
--Select * from #finaldata
--return







update #machineRunningStatus set ColorCode = 'Red' --(For Invalid Machines)
update #machineRunningStatus set ColorCode = 'Lime' where datatype in (11,41)
update #machineRunningStatus set ColorCode = 'Red' where datatype in (42,2)

update #machineRunningStatus set ColorCode = t1.ColorCode from (
Select mrs.MachineID,Case when (
case when datatype = 40 then datediff(second,sttime,@CurrTime)-isnull(Threshold,10)
when datatype = 1 then datediff(second,ndtime,@CurrTime)-isnull(Threshold,10)
end) > 0 then 'Red' else 'Lime' end as ColorCode
from #machineRunningStatus mrs left outer join AndonConfigurator ac on mrs.MachineID = ac.MachineID 
where  datatype in (40,1)
) as t1 inner join #machineRunningStatus on t1.MachineID = #machineRunningStatus.MachineID

--update #machineRunningStatus set ColorCode = 'Yellow' where MachineID in (select machine from planneddowntimes where PDTstatus = 1 and StartTime <= @CurrTime and endtime >= @CurrTime)

update #machineRunningStatus set ColorCode = t1.ColorCode from (
	select machineinformation.machineid,ad.recordtype,
	case when ad.recordtype=81 then 'Yellow' --else 'NotYellow'
	 end as ColorCode
	,max(ad.starttime) as StartTime from autodatadetails ad 
	inner join 
(select machine,max(autodatadetails.starttime) as StartTime from autodatadetails where recordtype in (81,80) group by machine) as t1 
	on ad.machine = t1.machine and ad.StartTime = t1.StartTime and  Datediff(n,t1.starttime,@currtime)<10
	inner join machineinformation on machineinformation.interfaceid = ad.machine
	where recordtype in (81,80) group by machineinformation.machineid,ad.recordtype
) 
as t1 inner join #machineRunningStatus on t1.MachineID = #machineRunningStatus.MachineID and t1.RecordType = 81


Update #FinalData Set RunningStatus = t1.ColorCode from (
	Select MachineID,ColorCode from #machineRunningStatus
) as t1 inner join #FinalData on t1.machineID = #FinalData.MachineID

--Select * from #FinalData
--Update #FinalData Set RunningStatus = 'Lime' where DownTime_Last=0 
--return
Select * from #FinalData cross join 
(Select dbo.f_FormatTime(sum(isnull(Downtime,0)),'HH:MM:SS') as Total_DownTime_Day,
		dbo.f_FormatTime( sum(isnull(DownTime_Last,0)),'HH:MM:SS') as Total_DownTime_Last
		from #FinalData) as t1 order by convert(bigint,#FinalData.machineid)

--Select * from #machineRunningStatus
--select * from planneddowntimes where StartTime <= getdate() and endtime >= getdate()


END
