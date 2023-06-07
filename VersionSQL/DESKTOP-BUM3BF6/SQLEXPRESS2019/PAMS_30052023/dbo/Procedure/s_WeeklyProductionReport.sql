/****** Object:  Procedure [dbo].[s_WeeklyProductionReport]    Committed by VersionSQL https://www.versionsql.com ******/

/***********************************************************************************************************
Procedure altered by Sangeeta Kallur on 16-Feb-2006							   *
to include threshold(Down) in BatchML Calculation
Changed By SSK on 10-July-2006 : -AutoAxel Request [Considering SubOperations at CO Level]		   *
Changed Count,Actual Avg{Cycle Time , LoadUnload Time} Calns
Changed By SSK on 06/Oct/2006 : To include Plant level Concept						   *
Procedure Altered By SSK on 06-Dec-2006 :
	To Remove Constraint Name & add it as Primary Key 						   *
Procedure Changed By Sangeeta Kallur on 01-MAR-2007:
	:To Change the production count for MultiSpindle Type of machines. [MAINI Req]
DR0176:24/Mar/2009:Karthik G :: Divide by zero error encountered.
mod 1 :- ER0181 By Kusuma M.H on 13-May-2009.2) Modify all the procedures accordingly. Qualify machine wherever we are making use of component and opeartion no.
mod 2 :- ER0182 By Kusuma M.H on 13-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
mod 3 :- changed by KarthikG on 01-jan-2009 for ER0210. Introduce PDT on 5150.
Following points have been noted
	a) Handle PDT at Machine Level. 
	b) Only type 1 records have been taken care.
	c) Not differentiating Managemenloss from down 
	d) Not removing ICD from Utilized time as we are considering only type 1 records.
ER0244 - KarthikG - 23/Aug/2010 :: To convert BatchDown Column into (hh:mm:ss) Format.
***********************************************************************************************************/

--s_WeeklyProductionReport '2010-08-16','2010-08-17','',''

CREATE   PROCEDURE [dbo].[s_WeeklyProductionReport]
	@Startdate datetime,
	@Enddate datetime,
	@Machine nvarchar(50)= '',
	@PlantID  nvarchar(50)= ''
AS
Begin

declare @machineid as nVarchar(50)
declare @compid as nvarchar(50)
declare @operationid as nvarchar(50)
declare @idealcycletime as int
declare @idealloadunload as int
declare @cycletime int
declare @loadunload int
declare @curmachineid as nvarchar(50)
declare @curcomp as nvarchar(50)
declare @curop as nvarchar(50)
declare @downtime as int
declare @avgcycletime as int
declare @avgloadunload as int
declare @qty as int
declare @strmachine nvarchar(255)
declare @strsql  nvarchar(4000)
declare @timeformat as nvarchar(2000)
declare @StrMPlantID nvarchar(255)
declare @strXmachine nvarchar(255)
select @strXmachine =''
select @strsql =''
select @strmachine=''
select @StrMPlantID=''
if isnull(@Machine,'') <> ''
begin
	---mod 2
--	select @strmachine = ' and machineinformation.MachineID = ''' + @Machine + ''''
--	select @strXmachine = ' and Ex.MachineID = ''' + @Machine + ''''
	select @strmachine = ' and machineinformation.MachineID = N''' + @Machine + ''''
	select @strXmachine = ' and Ex.MachineID = N''' + @Machine + ''''
	---mod 2
end
if isnull(@PlantID,'') <> ''
begin
	---mod 2
--	select @StrMPlantID = ' and  PlantMachine.PlantID = ''' + @PlantID + ''''
	select @StrMPlantID = ' and  PlantMachine.PlantID = N''' + @PlantID + ''''
	---mod 2
end

select @timeformat ='ss'
select @timeformat = isnull((select valueintext from cockpitdefaults where parameter='timeformat'),'ss')
if (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')
begin
select @timeformat = 'ss'
end

--Begin: Temp Table
create table #TblWeeklyProdRpt
(
	SerialNo bigint NOT NULL,
	Machine nvarchar(50) NOT NULL,
	Component nvarchar(50),
	Operation nvarchar(50),
	Qty int,
	FromTime datetime,
	ToTime datetime,
	IdealMachiningTime int,
	IdealLoadUnloadtime int,
	CycleTime int,
	LoadUnload int,
	datatype tinyint,
	dcode nvarchar(50),
	Parts Float,
	Downtime bigint
)
ALTER Table #TblWeeklyProdRpt
	ADD PRIMARY KEY CLUSTERED
	(
	machine,SerialNo
	)ON [PRIMARY]

CREATE TABLE #Exceptions
(
	MachineID NVarChar(50),
	ComponentID Nvarchar(50),
	OperationNo Int,
	StartTime DateTime,
	EndTime DateTime,
	IdealCount Int,
	ActualCount Int,
	Ratio Float
)

--mod 3
Create table #PlannedDownTimes
(
	MachineInterface nvarchar(50),
	StartTime DateTime,
	EndTime DateTime
)

SELECT @StrSql = ''
SELECT @StrSql = @StrSql + 'Insert into #PlannedDownTimes
SELECT MachineInformation.InterfaceID as MachineInterface,
CASE When StartTime<''' + convert(nvarchar(20),@StartDate,120)+''' Then ''' + convert(nvarchar(20),@StartDate,120)+''' Else StartTime End As StartTime,
CASE When EndTime>''' + convert(nvarchar(20),@EndDate,120)+''' Then ''' + convert(nvarchar(20),@EndDate,120)+''' Else EndTime End As EndTime
from PlannedDownTimes 
inner join MachineInformation on PlannedDownTimes.machine = MachineInformation.MachineID
inner join plantmachine on MachineInformation.MachineID = plantmachine.machineID
WHERE PDTstatus = 1 And ((StartTime >= ''' + convert(nvarchar(20),@StartDate,120)+'''  AND EndTime <=''' + convert(nvarchar(20),@EndDate,120)+''') 
OR ( StartTime < ''' + convert(nvarchar(20),@StartDate,120)+''' AND EndTime <= ''' + convert(nvarchar(20),@EndDate,120)+''' AND EndTime > ''' + convert(nvarchar(20),@StartDate,120)+''' )
OR ( StartTime >= ''' + convert(nvarchar(20),@StartDate,120)+''' AND StartTime <''' + convert(nvarchar(20),@EndDate,120)+''' AND EndTime > ''' + convert(nvarchar(20),@EndDate,120)+''' )
OR ( StartTime < ''' + convert(nvarchar(20),@StartDate,120)+''' AND EndTime > ''' + convert(nvarchar(20),@EndDate,120)+'''))'
SELECT @StrSql = @StrSql + @strmachine + @StrMPlantID
Exec (@strsql)
--mod 3


/*
If isnull(@PlantID, '') <> ''
BEGIN
	
		SELECT @strsql='insert into #TblWeeklyProdRpt(serialno,machine,component,operation,idealmachiningtime,idealloadunloadtime,cycletime,loadunload,fromtime,totime,datatype,dcode,Parts)'
		SELECT @strsql=@strsql+' SELECT  autodata.id,machineinformation.machineid,'
		SELECT @strsql=@strsql+' ci.componentid,cop.operationno,cop.machiningtime,(cop.cycletime - cop.machiningtime),autodata.cycletime, autodata.loadunload,'
		SELECT @strsql=@strsql+' autodata.sttime, autodata.ndtime,autodata.datatype,autodata.dcode,autodata.partscount'
		SELECT @strsql=@strsql+' from autodata inner join machineinformation on (autodata.mc = machineinformation.interfaceid)'
		SELECT @strsql=@strsql+' inner join componentinformation ci on (ci.interfaceid = autodata.comp)'
		SELECT @strsql=@strsql+' inner join componentoperationpricing cop on (cop.interfaceid = autodata.opn and ci.componentid = cop.componentid)'
		SELECT @strsql=@strsql+' Inner Join PlantMachine on PlantMachine.machineid=machineinformation.machineid'
		SELECT @strsql=@strsql+' where sttime >= '''+Convert(NVarChar(20),@startdate)+''' and ndtime <= '''+Convert(NVarChar(20),@enddate)+''''
		SELECT @strsql=@strsql+ @StrMPlantID+@strmachine
		SELECT @strsql=@strsql+' order by machineinformation.machineid, sttime,autodata.id'
		Exec(@strsql)
END
ELSE
BEGIN
		Select @StrSql='insert into #TblWeeklyProdRpt(serialno,machine,component,operation,idealmachiningtime,idealloadunloadtime,cycletime,loadunload,fromtime,totime,datatype,dcode,parts)'
		Select @StrSql=@StrSql+' SELECT  autodata.id,machineinformation.machineid,ci.componentid,cop.operationno,'
		Select @StrSql=@StrSql+' cop.machiningtime,(cop.cycletime - cop.machiningtime),autodata.cycletime, autodata.loadunload,'
		Select @StrSql=@StrSql+' autodata.sttime, autodata.ndtime,autodata.datatype,autodata.dcode,autodata.partscount'
		Select @StrSql=@StrSql+' from autodata inner join machineinformation on (autodata.mc = machineinformation.interfaceid)'
		Select @StrSql=@StrSql+' inner join componentinformation ci on (ci.interfaceid = autodata.comp)'
		Select @StrSql=@StrSql+' inner join componentoperationpricing cop on (cop.interfaceid = autodata.opn and ci.componentid = cop.componentid)'
		Select @StrSql=@StrSql+' where sttime >= '''+Convert(NVarChar(20),@StartDate)+''' and ndtime <= '''+Convert(NVarChar(20),@EndDate)+''''
		Select @StrSql=@StrSql + @strmachine
		Select @StrSql=@StrSql+' order by machineinformation.machineid, sttime,autodata.id'
		Exec(@strsql)
END
*/
/**************************************************************************************************************/
/* 			FOLLOWING SECTION IS ADDED BY SANGEETA KALLUR					*/
SELECT @StrSql = 'INSERT INTO #Exceptions(MachineID ,ComponentID,OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount, Ratio )
		SELECT Ex.MachineID ,Ex.ComponentID,Ex.OperationNo,StartTime ,EndTime ,IdealCount ,ActualCount ,CAST(CAST(ActualCount AS FLOAT)/CAST(IdealCount AS FLOAT)AS FLOAT)
		From ProductionCountException Ex
		Inner Join MachineInformation M ON Ex.MachineID=M.MachineID
		Inner Join ComponentInformation C ON Ex.ComponentID=C.ComponentID
		Inner Join Componentoperationpricing O ON Ex.OperationNo=O.OperationNo AND C.ComponentID=O.ComponentID '
---mod 1		
SELECT @StrSql = @StrSql + ' and O.MachineId=Ex.MachineId '
---mod 1
SELECT @StrSql = @StrSql + ' WHERE  M.MultiSpindleFlag=1 '
SELECT @StrSql =@StrSql + @strXMachine
SELECT @StrSql =@StrSql +'AND ((Ex.StartTime>=  ''' + convert(nvarchar(20),@StartDate,120)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@EndDate,120)+''' )
		OR (Ex.StartTime< ''' + convert(nvarchar(20),@StartDate,120)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@StartDate,120)+''' AND Ex.EndTime<= ''' + convert(nvarchar(20),@EndDate,120)+''')
		OR(Ex.StartTime>= ''' + convert(nvarchar(20),@StartDate,120)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@EndDate,120)+''' AND Ex.StartTime< ''' + convert(nvarchar(20),@EndDate,120)+''')
		OR(Ex.StartTime< ''' + convert(nvarchar(20),@StartDate,120)+''' AND Ex.EndTime> ''' + convert(nvarchar(20),@EndDate,120)+''' ))'
Exec (@strsql)

UPDATE #Exceptions SET StartTime=@StartDate WHERE (StartTime<@StartDate)AND EndTime>@StartDate
UPDATE #Exceptions SET EndTime=@EndDate WHERE (EndTime>@EndDate AND StartTime<@EndDate )

/*
If isnull(@PlantID, '') <> ''
BEGIN
	
		SELECT @strsql='insert into #TblWeeklyProdRpt(serialno,machine,component,operation,idealmachiningtime,idealloadunloadtime,cycletime,loadunload,fromtime,totime,datatype,dcode,Parts)'
		SELECT @strsql=@strsql+' SELECT  autodata.id,machineinformation.machineid,'
		SELECT @strsql=@strsql+' ci.componentid,cop.operationno,cop.machiningtime,(cop.cycletime - cop.machiningtime),autodata.cycletime, autodata.loadunload,'
		SELECT @strsql=@strsql+' autodata.sttime, autodata.ndtime,autodata.datatype,autodata.dcode,
		CASE
		WHEN Autodata.Ndtime >T1.StartTime And Autodata.Ndtime <=T1.EndTime THEN T1.Ratio
		ELSE Autodata.partscount End'
		SELECT @strsql=@strsql+' from autodata inner join machineinformation on (autodata.mc = machineinformation.interfaceid)'
		SELECT @strsql=@strsql+' inner join componentinformation ci on (ci.interfaceid = autodata.comp)'
		SELECT @strsql=@strsql+' inner join componentoperationpricing cop on (cop.interfaceid = autodata.opn and ci.componentid = cop.componentid)'
		---mod 1		
		SELECT @StrSql = @StrSql + ' and cop.machineid=machineinformation.machineid '
		---mod 1
		SELECT @strsql=@strsql+' Inner Join PlantMachine on PlantMachine.machineid=machineinformation.machineid'
		SELECT @strsql=@strsql+' LEFT OUTER JOIN (SELECT MachineID,ComponentID,OperationNo,StartTime,EndTime ,Ratio From #Exceptions) AS T1
		ON T1.MachineID=machineinformation.MachineID AND T1.ComponentID=Ci.ComponentID
		AND T1.OperationNo=COP.OperationNo AND Autodata.Ndtime >T1.StartTime And Autodata.Ndtime <=T1.EndTime'
		SELECT @strsql=@strsql+' where sttime >= '''+Convert(NVarChar(20),@startdate)+''' and ndtime <= '''+Convert(NVarChar(20),@enddate)+''''
		SELECT @strsql=@strsql+ @StrMPlantID+@strmachine
		SELECT @strsql=@strsql+' order by machineinformation.machineid, sttime,autodata.id'
		Exec(@strsql)
		
END
ELSE
BEGIN
		Select @StrSql='insert into #TblWeeklyProdRpt(serialno,machine,component,operation,idealmachiningtime,idealloadunloadtime,cycletime,loadunload,fromtime,totime,datatype,dcode,parts)'
		Select @StrSql=@StrSql+' SELECT  autodata.id,machineinformation.machineid,ci.componentid,cop.operationno,'
		Select @StrSql=@StrSql+' cop.machiningtime,(cop.cycletime - cop.machiningtime),autodata.cycletime, autodata.loadunload,'
		Select @StrSql=@StrSql+' autodata.sttime, autodata.ndtime,autodata.datatype,autodata.dcode,
		CASE
		WHEN Autodata.Ndtime >T1.StartTime And Autodata.Ndtime <=T1.EndTime THEN T1.Ratio
		ELSE Autodata.partscount End'
		Select @StrSql=@StrSql+' from autodata inner join machineinformation on (autodata.mc = machineinformation.interfaceid)'
		Select @StrSql=@StrSql+' inner join componentinformation ci on (ci.interfaceid = autodata.comp)'
		Select @StrSql=@StrSql+' inner join componentoperationpricing cop on (cop.interfaceid = autodata.opn and ci.componentid = cop.componentid)'
		---mod 1		
		SELECT @StrSql = @StrSql + ' and cop.machineid=machineinformation.machineid '
		---mod 1
		SELECT @strsql=@strsql+' LEFT OUTER JOIN (SELECT MachineID,ComponentID,OperationNo,StartTime,EndTime ,Ratio From #Exceptions) AS T1
		ON T1.MachineID=machineinformation.MachineID AND T1.ComponentID=Ci.ComponentID
		AND T1.OperationNo=COP.OperationNo AND Autodata.Ndtime >T1.StartTime And Autodata.Ndtime <=T1.EndTime'
		Select @StrSql=@StrSql+' where sttime >= '''+Convert(NVarChar(20),@startdate)+''' and ndtime <= '''+Convert(NVarChar(20),@enddate)+''''
		Select @StrSql=@StrSql + @strmachine
		Select @StrSql=@StrSql+' order by machineinformation.machineid, sttime,autodata.id'
		Exec(@strsql)
END
*/

		SELECT @strsql='insert into #TblWeeklyProdRpt(serialno,machine,component,operation,idealmachiningtime,idealloadunloadtime,cycletime,loadunload,fromtime,totime,datatype,dcode,Parts)
		SELECT  autodata.id,machineinformation.machineid,
		ci.componentid,cop.operationno,cop.machiningtime,(cop.cycletime - cop.machiningtime),autodata.cycletime, autodata.loadunload,
		autodata.sttime, autodata.ndtime,autodata.datatype,autodata.dcode,
		CASE
			WHEN Autodata.Ndtime >T1.StartTime And Autodata.Ndtime <=T1.EndTime THEN T1.Ratio
			ELSE Autodata.partscount 
		End
		from autodata 
		inner join machineinformation on (autodata.mc = machineinformation.interfaceid)
		inner join componentinformation ci on (ci.interfaceid = autodata.comp)
		inner join componentoperationpricing cop on (cop.interfaceid = autodata.opn and ci.componentid = cop.componentid) and cop.machineid=machineinformation.machineid 
		Inner Join PlantMachine on PlantMachine.machineid=machineinformation.machineid
		Left Outer Join (SELECT MachineID,ComponentID,OperationNo,StartTime,EndTime ,Ratio From #Exceptions) AS T1
		ON T1.MachineID=machineinformation.MachineID AND T1.ComponentID=Ci.ComponentID AND T1.OperationNo=COP.OperationNo 
		AND Autodata.Ndtime >T1.StartTime And Autodata.Ndtime <=T1.EndTime
		where (sttime >= '''+Convert(NVarChar(20),@startdate,120)+''' and ndtime <= '''+Convert(NVarChar(20),@enddate,120)+''') '
--mod 3
		SELECT @strsql=@strsql+ @StrMPlantID+@strmachine

		IF (SELECT ValueInText From CockpitDefaults Where Parameter='Ignore_Count_4m_PLD')='Y'
		BEGIN
			SELECT @strsql=@strsql+' And autodata.ID NOT IN (SELECT ID From AutoData A Cross Join #PlannedDownTimes Where A.mc = #PlannedDownTimes.MachineInterface and A.Sttime>=StartTime And A.NdTime<=EndTime And A.DataType=1)'
		END

		IF (SELECT ValueInText From CockpitDefaults Where Parameter='Ignore_Dtime_4m_PLD')='Y'
		BEGIN
			SELECT @strsql=@strsql+' And autodata.ID NOT IN (SELECT ID From AutoData A Cross Join #PlannedDownTimes Where A.mc = #PlannedDownTimes.MachineInterface and A.Sttime>=StartTime And A.NdTime<=EndTime And A.DataType=2)'
		END

		IF (SELECT ValueInText From CockpitDefaults Where Parameter='Ignore_Dtime_4m_PLD')<>'Y' AND (SELECT ValueInText From CockpitDefaults Where Parameter='Ignore_Dtime_4m_PLD')<>'N'
		BEGIN
			SELECT @strsql=@strsql+' And autodata.ID NOT IN (SELECT ID From AutoData A Cross Join #PlannedDownTimes Where A.mc = #PlannedDownTimes.MachineInterface and A.Sttime>=StartTime And A.NdTime<=EndTime And A.DataType=2 And A.DCode=(Select Interfaceid From DownCodeInformation Where DownID=(Select ValueInText From CockpitDefaults Where Parameter=''Ignore_Dtime_4m_PLD'')))'
		END
--mod 3
		SELECT @strsql=@strsql+' order by machineinformation.machineid, sttime,autodata.id'
		Exec(@strsql)

/***********************************************************************************************************************/
	Declare RptCursor CURSOR FOR
		SELECT 	#tblweeklyprodrpt.machine,
			#tblweeklyprodrpt.component,
			#tblweeklyprodrpt.operation
		from 	#tblweeklyprodrpt
		order by machine,fromtime
	
		OPEN RptCursor
				
		FETCH NEXT FROM RptCursor INTO @machineid, @compid, @operationid
		if (@@fetch_status = 0)
		begin
		  select @qty = 1
		  update #Tblweeklyprodrpt set qty = @qty where current of rptcursor
		
		  -- initialize current variables		
		  select @curmachineid = @machineid	
		  select @curcomp = @compid
		  select @curop = @operationid
		end	
		
		WHILE (@@fetch_status <> -1)
		BEGIN
			  IF (@@fetch_status <> -2)
			    BEGIN
					FETCH NEXT FROM RptCursor INTO @machineid, @compid, @operationid
					if (@@fetch_status = 0) and (@curmachineid = @machineid) and (@curcomp = @compid) and (@curop = @operationid)
					begin
						update #Tblweeklyprodrpt set qty = @qty where current of rptcursor
					end
					else if (@@fetch_status = 0)
					begin -- 2
						select @qty = @qty + 1
						update #Tblweeklyprodrpt set qty = @qty where current of rptcursor
						
						select @curmachineid = @machineid	
						select @curcomp = @compid
						select @curop = @operationid
					end
			    END
		END
--Output
/*
select qty as Batch, machine, component, operation,
min(fromtime) BatchStart, max(totime) BatchEnd, datediff(s,min(fromtime),max(totime)) BatchPeriod,
max(idealmachiningtime) IdealMachiningTime, max(idealloadunloadtime) IdealLoadUnload,
dbo.f_formattime(max(idealmachiningtime),@timeformat)as frmtidealmachiningtime,
dbo.f_formattime(max(idealloadunloadtime),@timeformat)as frmtIdealLoadUnload,
Isnull((Select CAST(CEILING((sum(parts))/ISNULL(O.SubOperations,1))AS INTEGER) From #tblweeklyprodrpt T1
INNER JOIN ComponentInformation C ON T1.Component=C.ComponentID
INNER JOIN ComponentOperationPricing O ON T1.Operation=O.OperationNo AND C.ComponentID=O.ComponentID
Where Datatype = 1 and t1.qty = t2.qty Group BY qty,O.SubOperations),0) AS Production,
Isnull((select avg(T1.cycletime/parts)* ISNULL(O.SubOperations,1) From #tblweeklyprodrpt T1
INNER JOIN ComponentInformation C ON T1.Component=C.ComponentID
INNER JOIN ComponentOperationPricing O ON T1.Operation=O.OperationNo AND C.ComponentID=O.ComponentID
--And T1.machine = t2.machine  --DR0176:24/Mar/2009:Karthik G
Where datatype = 1 and T1.qty = t2.qty group by qty,O.SubOperations),0) AS Avgcycle,
Isnull((select avg(T1.loadunload/parts)* ISNULL(O.SubOperations,1) from #tblweeklyprodrpt t1
INNER JOIN ComponentInformation C ON T1.Component=C.ComponentID
INNER JOIN ComponentOperationPricing O ON T1.Operation=O.OperationNo AND C.ComponentID=O.ComponentID
--And T1.machine = t2.machine  --DR0176:24/Mar/2009:Karthik G
where datatype = 1 and t1.qty = t2.qty group by qty,O.SubOperations),0) as Avgloadunload,
dbo.f_formattime(Isnull((select avg(T1.cycletime/parts)* ISNULL(O.SubOperations,1)  from #tblweeklyprodrpt t1
INNER JOIN ComponentInformation C ON T1.Component=C.ComponentID
INNER JOIN ComponentOperationPricing O ON T1.Operation=O.OperationNo AND C.ComponentID=O.ComponentID
--And T1.machine = t2.machine   --DR0176:24/Mar/2009:Karthik G
where datatype = 1 and t1.qty = t2.qty group by qty,O.SubOperations),0),@timeformat) as frmtAvgcycle,
dbo.f_formattime(Isnull((select avg(T1.loadunload/parts)* ISNULL(O.SubOperations,1)  from #tblweeklyprodrpt t1
INNER JOIN ComponentInformation C ON T1.Component=C.ComponentID
INNER JOIN ComponentOperationPricing O ON T1.Operation=O.OperationNo AND C.ComponentID=O.ComponentID
--And T1.machine = t2.machine  --DR0176:24/Mar/2009:Karthik G
where datatype = 1 and t1.qty = t2.qty group by qty,O.SubOperations),0),@timeformat) as frmtAvgloadunload,
dbo.f_formattime(isnull((select sum(loadunload) from #tblweeklyprodrpt t1 where datatype = 2 and t1.qty = t2.qty group by qty),0),@timeformat) as BatchDown,
isnull((select sum(CASE --Previously it was sum(loadunload) instead of Case :: Commented By SKallur
WHEN loadunload >ISNULL(downcodeinformation.Threshold,0)  and ISNULL(downcodeinformation.Threshold,0)>0 then ISNULL(downcodeinformation.Threshold,0)
ELSE loadunload
END) from #tblweeklyprodrpt t1 inner join downcodeinformation on t1.dcode = downcodeinformation.interfaceid
	where datatype = 2 and downcodeinformation.availeffy =1 and t1.qty = t2.qty group by qty),0) as BatchML
from #tblweeklyprodrpt t2
group by qty,machine,component,operation order by qty
*/

	select qty as Batch,
	avg(T1.cycletime/parts)* ISNULL(O.SubOperations,1) as Avgcycle,
	avg(T1.loadunload/T1.parts)* ISNULL(O.SubOperations,1) as Avgload
	into #TempAvg from #tblweeklyprodrpt T1
	Inner Join ComponentInformation C ON T1.Component=C.componentID	
	INNER JOIN ComponentOperationPricing O ON T1.Operation=O.OperationNo AND C.ComponentID=O.ComponentID
	---mod 1
	inner join machineinformation M on M.machineid=O.machineid and T1.machine=M.machineid
	---mod 1
	where T1.datatype=1 
	and T1.Parts > 0 --DR0176 - 26/May/2010 - Karthik G
	group by qty,O.SubOperations



	--select * from #TempAvg
	select qty as Batch,machine,component, operation,
	min(fromtime) BatchStart,max(totime) BatchEnd,datediff(s,min(fromtime),max(totime)) BatchPeriod,
	max(idealmachiningtime) IdealMachiningTime,	max(idealloadunloadtime) IdealLoadUnload,
	dbo.f_FormatTime(max(idealmachiningtime),@TimeFormat)AS frmtidealmachiningtime,
	dbo.f_FormatTime(max(idealloadunloadtime),@TimeFormat)AS frmtIdealLoadUnload,
	IsNull((select CAST(CEILING(CAST(sum(T1.parts)AS Float)/ISNULL(O.SubOperations,1))AS INTEGER) from #tblweeklyprodrpt T1 Inner Join ComponentInformation C ON T1.Component=C.componentID	INNER JOIN ComponentOperationPricing O ON T1.Operation=O.OperationNo AND C.ComponentID=O.ComponentID where datatype = 1 and t1.qty = t2.qty group by qty,O.SubOperations),0) as Production,
	IsNull(A.Avgcycle,0) as AvgCycle,
	IsNull(A.AvgLoad,0) as Avgloadunload,
	dbo.f_FormatTime(A.Avgcycle,@TimeFormat) AS frmtAvgcycle,
	dbo.f_FormatTime(A.AvgLoad ,@TimeFormat) AS frmtAvgloadunload,
	--dbo.f_FormatTime(isnull((select sum(loadunload) from #tblweeklyprodrpt t1 where datatype = 2 and t1.qty = t2.qty group by qty),0),@TimeFormat) as BatchDown,
--	isnull((select sum(loadunload) from #tblweeklyprodrpt t1 where datatype = 2 and t1.qty = t2.qty group by qty),0) as BatchDown,--ER0244 - KarthikG - 23/Aug/2010
	dbo.f_FormatTime(isnull((select sum(loadunload) from #tblweeklyprodrpt t1 where datatype = 2 and t1.qty = t2.qty group by qty),0),@TimeFormat) as BatchDown,--ER0244 - KarthikG - 23/Aug/2010
	isnull((select sum(CASE --Priviously it was sum(loadunload)instead of CASE
	WHEN loadunload >ISNULL(downcodeinformation.Threshold,0) and ISNULL(downcodeinformation.Threshold,0)>0 then ISNULL(downcodeinformation.Threshold,0)
	ELSE loadunload
	END) from #tblweeklyprodrpt t1 inner join downcodeinformation on t1.dcode = downcodeinformation.interfaceid
	where datatype = 2 and downcodeinformation.availeffy =1 and t1.qty = t2.qty group by qty),0) as BatchML
	from #tblweeklyprodrpt t2  left outer join #TempAvg A on A.batch=t2.qty
	group by qty,machine,component,operation,A.Avgcycle,A.AvgLoad
	order by qty

End
