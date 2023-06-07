/****** Object:  Procedure [dbo].[s_GetCockpitData_cell]    Committed by VersionSQL https://www.versionsql.com ******/

/*************************************************************************
 CELL View in COCKPIT
 Madhu Kestur 12 January 2005

 Procedure modified by Sangeeta Kallur on 16-Feb-2006
 to include threshold(down) in Management Loss Calculation

 Procedure Altred On top of 4.5.0.0 by Sangeeta Kallur On May-2006 
 [Originally this proc altered for testing]
 To support the down within the production cycle as they appear.

 Procedure Altered By SSK on 07-July-2006 : For Considering SubOperations at CO Level.
 Changed Count,CN,TurnOver Calculation on #CockpitData
 Changed finishopn ,UtilisedTime Calculation on #CockpitDatacellfinish

 Procedure Changed By SSK on 06-Dec-2006 : To remove constraint name.
 For DR0236 altered by karthick R on 23-06-2010  Use proper conditions in case statements to remove icd's from type 4 production records.
--[s_GetCockpitData_cell] '2010-05-01','2010-05-02','',''
***********************************************************************/




CREATE      PROCEDURE [dbo].[s_GetCockpitData_cell]
	@StartTime datetime output,
	@EndTime datetime output,
	@CellID nvarchar(50) = '',
	@PlantID nvarchar(50)=''
AS
BEGIN
CREATE TABLE #CockPitDataCellfinish (
	CellID nvarchar(50) NOT NULL,
	MachineID nvarchar(50) NOT NULL,
	ComponentID nvarchar (50) NOT NULL,
	OperationNo smallint NOT NULL,
	UtilisedTime float,
	DownTime float,
	OperationTime float,
	finishopn float,
	yield float,
	yieldeffy float
--CONSTRAINT CockpitDataCellfinish_key PRIMARY KEY (Cellid, machineid,componentid,operationno)
)

ALTER TABLE #CockPitDataCellfinish
	ADD PRIMARY KEY CLUSTERED
		(
			[Cellid], 
			[machineid],
			[componentid],
			[operationno]
		) ON [PRIMARY]


CREATE TABLE #CockPitDataCell (
	CellID nvarchar(50) PRIMARY KEY ,
	ProductionEfficiency float,
	AvailabilityEfficiency float,
	OverallEfficiency float,	
	TotalOpn float,
	FinishOpn float,
	YieldEffy float,
	TotalTime float,
	UtilisedTime float,
	ManagementLoss float,
	DownTime float,
	TurnOver float,
	ReturnPerHour float,
	CN float,
	Remarks nvarchar(40)
--CONSTRAINT CockpitDataCell1_key PRIMARY KEY (Cellid)
)


CREATE TABLE #CockPitData(
	CellID nvarchar(50),
	MachineID nvarchar(50),
	MachineInterface nvarchar(50) PRIMARY KEY,
	TotalOpn float,
	FinishOpn float,
	TotalTime float,
	UtilisedTime float,
	ManagementLoss float,
	DownTime float,
	TurnOver float,
	ReturnPerHour float,
	CN float
--CONSTRAINT CockpitData11_key PRIMARY KEY (machineinterface)
)

DECLARE @strSqlCell as nvarchar(4000)
DECLARE @strPlantID as nvarchar(50)
DECLARE @strCellID as nvarchar(50)
DECLARE @strSql as nvarchar(4000)
SET @strSqlCell =''
SET @strPlantID =''
SET @strCellID =''
SET @strSql = ''
if isnull(@CellID,'')<> '' 
begin
	SET @strCellID = ' AND (CellHistory.CellId =''' +  @cellid + ''')'
end
if isnull(@PlantID,'')<> ''
Begin
	SET @strPlantID = ' AND (PlantInformation.PlantID = ''' +  @PlantID + ''')'
End


	SET @strSql ='  INSERT INTO #CockpitData (
		cellid,
		MachineID ,
		MachineInterface,
		TotalOpn,
		Finishopn,
		TotalTime ,
		UtilisedTime ,	
		ManagementLoss,
		DownTime ,
		TurnOver ,
		ReturnPerHour ,
		CN
			)
		SELECT cellhistory.cellid,cellhistory.MachineID, machineinformation.interfaceid ,
			0,0,0,0,0,0,0,0,0 
		FROM CellHistory INNER JOIN
                machineinformation ON CellHistory.MachineId = machineinformation.machineid
                LEFT OUTER JOIN PlantInformation ON CellHistory.PlantID = PlantInformation.PlantID
		WHERE  machineinformation.interfaceid > 0 ' + @strCellID + @strPlantID
		
	EXEC(@strSql)

	SET @strSql = ''
	SET @strSql = ' INSERT INTO #CockpitDataCellFinish (
			CellID,
			MachineID,
			ComponentID,
			OperationNo,
			UtilisedTime,
			DownTime,
			OperationTime,
			finishopn,
			yield,
			yieldeffy
			)
			SELECT cellfinishoperation.CellId,
				cellhistory.MachineID, 
				cellfinishoperation.ComponentID,
				cellfinishoperation.Operationno, 0,0,0,0,
				cellfinishoperation.yield,0
			
			FROM CellHistory INNER JOIN
                        machineinformation ON CellHistory.MachineId = machineinformation.machineid INNER JOIN
                        CellFinishOperation ON CellHistory.CellId = CellFinishOperation.CellId LEFT OUTER JOIN
                        PlantInformation ON CellHistory.PlantID = PlantInformation.PlantID
			WHERE  machineinformation.interfaceid > 0 ' + @strCellID + @strPlantID
	EXEC(@strSql)	
	SET @strSql=''

---------------------- BEGIN: Get the utilised time
-- Type 1

UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)from
(select      mc,
	sum(cycletime+loadunload) as cycle
  from autodata
where (autodata.msttime>=@StartTime)    and (autodata.ndtime<=@EndTime)
    and (autodata.datatype=1)
group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface


UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
from
(select  mc,
         sum(DateDiff(second, @StartTime, ndtime)) cycle
from autodata
where (autodata.msttime<@StartTime)
and (autodata.ndtime>@StartTime)
and (autodata.ndtime<=@EndTime)
and (autodata.datatype=1)
group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface

-- Type 3

UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
from
(select  mc,
             sum(DateDiff(second, mstTime, @Endtime)) cycle
from autodata
where (autodata.msttime>=@StartTime)
and (autodata.msttime<@EndTime)
and (autodata.ndtime>@EndTime)
and (autodata.datatype=1)
group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface

--type 4
UPDATE #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) + isnull(t2.cycle,0)
from
(select mc,
        sum(DateDiff(second, @StartTime, @EndTime)) cycle
from autodata
where (autodata.msttime<@StartTime)
and (autodata.ndtime>@EndTime)
and (autodata.datatype=1)
group by autodata.mc
)as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface

/* Fetching Down Records from Production Cycle  */
/* If Down Records of TYPE-2*/
UPDATE  #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
FROM
(Select AutoData.mc ,
SUM(
CASE 
	When autodata.sttime <= @StartTime Then datediff(s, @StartTime,autodata.ndtime )
	When autodata.sttime > @StartTime Then datediff(s , autodata.sttime,autodata.ndtime)
END) as Down
From AutoData INNER Join 
	(Select mc,Sttime,NdTime From AutoData
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And 
		(sttime < @StartTime)And (ndtime > @StartTime) AND (ndtime <= @EndTime)) as T1
ON AutoData.mc=T1.mc 
Where AutoData.DataType=2 
And ( autodata.Sttime > T1.Sttime )
And ( autodata.ndtime <  T1.ndtime ) 
AND ( autodata.ndtime >  @StartTime )
GROUP BY AUTODATA.mc)AS T2 Inner Join #CockpitData on t2.mc = #CockpitData.machineinterface

/* If Down Records of TYPE-3*/

UPDATE  #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
FROM
(Select AutoData.mc , 
SUM(CASE 
	When autodata.ndtime > @EndTime Then datediff(s,autodata.sttime, @EndTime )
	When autodata.ndtime <=@EndTime Then datediff(s , autodata.sttime,autodata.ndtime)
END) as Down
From AutoData INNER Join 
	(Select mc,Sttime,NdTime From AutoData
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And 
		(sttime >= @StartTime)And (ndtime > @EndTime)) as T1
ON AutoData.mc=T1.mc 
Where AutoData.DataType=2 
And (T1.Sttime < autodata.sttime  )
And ( T1.ndtime >  autodata.ndtime) 
AND (autodata.sttime  <  @EndTime)
GROUP BY AUTODATA.mc)AS T2 Inner Join #CockpitData on t2.mc = #CockpitData.machineinterface

/* If Down Records of TYPE-4*/
UPDATE  #CockpitData SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
FROM
(Select AutoData.mc ,
SUM(CASE 
--DR0236 altered by karthick R on 23-06-2010:From here
/*
	When autodata.sttime < @StartTime AND autodata.ndtime<=@EndTime Then datediff(s, @StartTime,autodata.ndtime )
	When autodata.ndtime >= @EndTime AND autodata.sttime>@StartTime Then datediff(s,autodata.sttime, @EndTime )
	When autodata.sttime >= @StartTime AND
	     autodata.ndtime <= @EndTime Then datediff(s , autodata.sttime,autodata.ndtime)
	When autodata.sttime<@StartTime AND autodata.ndtime>@EndTime   Then datediff(s , @StartTime,@EndTime)*/

When autodata.sttime >= @StartTime AND autodata.ndtime <= @EndTime Then datediff(s , autodata.sttime,autodata.ndtime)--type 1
When autodata.sttime < @StartTime AND autodata.ndtime > @StartTime And autodata.ndtime<=@EndTime Then datediff(s, @StartTime,autodata.ndtime )--type 2
When autodata.sttime>=@StartTime and Autodata.sttime<@EndTime and autodata.ndtime > @EndTime then datediff(s,autodata.sttime, @EndTime )--type3
When autodata.sttime<@StartTime AND autodata.ndtime>@EndTime   Then datediff(s , @StartTime,@EndTime) --type 4
			
--DR0236 altered by karthick R on 23-06-2010 --till here
END) as Down

From AutoData INNER Join 	(Select mc,Sttime,NdTime From AutoData
		Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And 
		(sttime < @StartTime)And (ndtime > @EndTime) ) as T1
ON AutoData.mc=T1.mc 
Where AutoData.DataType=2 
And (T1.Sttime < autodata.sttime  )
And ( T1.ndtime >  autodata.ndtime) 
AND (autodata.ndtime  >  @StartTime)
AND (autodata.sttime  <  @EndTime)
GROUP BY AUTODATA.mc
)AS T2 Inner Join #CockpitData on t2.mc = #CockpitData.machineinterface


/*******************************Down Record***********************************/


-------------------END: Utilised Time

-------------------BEGIN: ManagementLoss
/* 
--Sample Case  
--Type-2 ,Type-3 and Type-4 commented code is removed by SSK
-- Type 1
UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
from
(select      mc,
	sum(loadunload) loss
 from autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
where (autodata.msttime>=@StartTime)
    and (autodata.ndtime<=@EndTime)
    and (autodata.datatype=2)
and (downcodeinformation.availeffy = 1)
group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface

---------------END: ManagementLoss
*/
------------------------------ Begins : ManagementLoss Caln including Threshold by S Kallur ----------------------------
-- Type 1
UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
from
(select      mc,
	sum(CASE
WHEN loadunload >ISNULL(downcodeinformation.Threshold,0) and ISNULL(downcodeinformation.Threshold,0) >0 THEN ISNULL(downcodeinformation.Threshold,0)
ELSE loadunload
END) loss
 from autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
where (autodata.msttime>=@StartTime)
    and (autodata.ndtime<=@EndTime)
    and (autodata.datatype=2)
and (downcodeinformation.availeffy = 1)
group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface

-- Type 2
UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
from
(select      mc,
	sum(case
when DateDiff(second, @StartTime, ndtime)>ISNULL(downcodeinformation.Threshold,0) and ISNULL(downcodeinformation.Threshold,0) >0 THEN ISNULL(downcodeinformation.Threshold,0)
else DateDiff(second, @StartTime, ndtime)
end) loss
 from autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
where (autodata.sttime<@StartTime)
    and (autodata.ndtime>@StartTime)
and (autodata.ndtime<=@EndTime)
and (autodata.datatype=2)
and (downcodeinformation.availeffy = 1)
group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface

-- Type 3
UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)

from
(select      mc,
	sum(CASE
WHEN DateDiff(second, stTime, @Endtime)>ISNULL(downcodeinformation.Threshold,0) and ISNULL(downcodeinformation.Threshold,0) >0 THEN ISNULL(downcodeinformation.Threshold,0)
ELSE DateDiff(second, stTime, @Endtime)
END) loss
 from autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
where (autodata.msttime>=@StartTime)
and (autodata.sttime<@EndTime)
and (autodata.ndtime>@EndTime)
and (autodata.datatype=2)
and (downcodeinformation.availeffy = 1)
group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface


-- Type 4
UPDATE #CockpitData SET ManagementLoss = isnull(ManagementLoss,0) + isNull(t2.loss,0)
from
(select mc,
	sum(CASE
WHEN DateDiff(second, @StartTime, @Endtime)>ISNULL(downcodeinformation.Threshold,0) and ISNULL(downcodeinformation.Threshold,0) >0 THEN ISNULL(downcodeinformation.Threshold,0)
ELSE DateDiff(second, @StartTime, @Endtime)
END) loss
 from autodata INNER JOIN downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
where autodata.msttime<@StartTime
and autodata.ndtime>@EndTime
and (autodata.datatype=2)
and (downcodeinformation.availeffy = 1)
group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface
-------------------------------------------- ::  Ends ::   ------------------------------------------
-- Get the value of CN
-- Type 1
--Type-2  commented code is removed by SSK
/*
UPDATE #CockpitData SET CN = CN +
isNull((
SELECT     SUM(C * N)
FROM
(
	SELECT     componentoperationpricing.cycletime AS C, COUNT(autodata.comp) AS N
	FROM         autodata INNER JOIN
componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID AND
componentoperationpricing.componentid = componentinformation.componentid
	where
		(autodata.mc = #CockpitData.machineinterface)
	    and (autodata.msttime>=@StartTime)
	    and (autodata.ndtime<=@EndTime)
	    and (autodata.datatype=1)
	group by componentoperationpricing.operationno, componentoperationpricing.componentid , componentoperationpricing.cycletime
) DERIVEDTBL
),0)
*/

UPDATE #CockpitData SET CN = isnull(CN,0) + isNull(t2.C1N1,0)
from
(select mc,
        SUM(componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1)) C1N1
   FROM autodata INNER JOIN
componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID AND
componentoperationpricing.componentid = componentinformation.componentid
  where (autodata.sttime>=@StartTime)
    and (autodata.ndtime<=@EndTime)
    and (autodata.datatype=1)
  group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface

-- Type 2

UPDATE #CockpitData SET CN = isnull(CN,0) + isNull(t2.C1N1,0)
from
(select mc,
        SUM(componentoperationpricing.cycletime/ISNULL(ComponentOperationPricing.SubOperations,1)) C1N1
   FROM autodata INNER JOIN
componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID AND
componentoperationpricing.componentid = componentinformation.componentid
where (autodata.sttime<@StartTime)
  and (autodata.ndtime>@StartTime)
  and (autodata.ndtime<=@EndTime)
  and (autodata.datatype=1)
  group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface


-- Get the TurnOver
-- Type 1
UPDATE #CockpitData SET turnover = isnull(turnover,0) + isNull(t2.revenue,0)
from
(select mc,
        SUM(componentoperationpricing.price/ISNULL(ComponentOperationPricing.SubOperations,1)) revenue
   FROM autodata INNER JOIN
componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID AND
componentoperationpricing.componentid = componentinformation.componentid
  where (autodata.sttime>=@StartTime)
    and (autodata.ndtime<=@EndTime)
    and (autodata.datatype=1)
  group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface


-- Type 2
UPDATE #CockpitData SET turnover = isnull(turnover,0) + isNull(t2.revenue,0)
from
(select mc,
        SUM(componentoperationpricing.price/ISNULL(ComponentOperationPricing.SubOperations,1)) revenue
   FROM autodata INNER JOIN
componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID AND
componentoperationpricing.componentid = componentinformation.componentid
where (autodata.sttime<@StartTime)
  and (autodata.ndtime>@StartTime)
  and (autodata.ndtime<=@EndTime)
  and (autodata.datatype=1)
  group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface

---------BEGIN: Get the total Number of (operations)
-- Type 1
/* 
Following code is commented by Sangeeta Kallur 
*/
		/*UPDATE #CockpitData SET TotalOpn = isnull(TotalOpn,0) + isNull(t2.comp,0)
		from
		(select mc,
			count(*) comp
		 from autodata
		where (autodata.sttime>=@StartTime)
		and (autodata.ndtime<=@EndTime)
		and (autodata.datatype=1)
		group by autodata.mc
		) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface
		
		
		-- Type 2
		UPDATE #CockpitData SET TotalOpn = isnull(TotalOpn,0) + isNull(t2.comp,0)
		from
		(select mc,
			count(*) comp
		 from autodata
		where (autodata.sttime<@StartTime)
		and (autodata.ndtime>@StartTime)
		and (autodata.ndtime<=@EndTime)
		and (autodata.datatype=1)
		group by autodata.mc
		) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface
               */
/* By SSK : Count for TYPE-1 & TYPE-2 */
UPDATE #CockpitData SET TotalOpn = ISNULL(TotalOpn,0) + ISNULL(t2.comp,0)
From
(
 Select mc,SUM(CEILING (CAST(T1.OrginalCount AS Float)/ISNULL(O.SubOperations,1))) As Comp  
	   From (select mc,count(*)AS OrginalCount,comp,opn from autodata 
	   WHERE (autodata.ndtime>@StartTime) AND (autodata.ndtime<=@EndTime) AND (autodata.datatype=1)
	   Group By mc,comp,opn) as T1 
   Inner join componentinformation C on T1.Comp = C.interfaceid 
   Inner join ComponentOperationPricing O ON  T1.Opn = O.interfaceid and C.Componentid=O.componentid
   GROUP BY mc
) As T2 Inner join #CockpitData on T2.mc = #CockpitData.machineinterface 


----------END: Get the total number of OPERATIONS

----------BEGIN: Get number of FINISH OPERATIONS in the Cell, by machine
/*
--Type 1
--Type-2  commented code is removed by SSK
UPDATE #CockpitData SET finishopn = isnull(finishopn,0) + isNull(t2.finish,0)
from
(select  mc, count(autodata.opn) finish
   FROM autodata INNER JOIN
machineinformation ON autodata.mc = machineinformation.interfaceid INNER JOIN
cellhistory ON machineinformation.machineid = cellhistory.machineid INNER JOIN
componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID AND
componentoperationpricing.componentid = componentinformation.componentid INNER join
cellfinishoperation ON componentoperationpricing.componentid = cellfinishoperation.componentid AND
componentoperationpricing.operationno = cellfinishoperation.operationno AND
cellfinishoperation.cellid = cellhistory.cellid
where (autodata.sttime>=@StartTime)
  and (autodata.ndtime<=@EndTime)
  and (autodata.datatype=1)
group by autodata.mc
)as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface
*/
----------END:   Get number of FINISH OPERATIONS in the Cell, by machine

-- Get the down time
-- Type 1
UPDATE #CockpitData SET downtime = isnull(downtime,0) + isNull(t2.down,0)
from
(select mc,
	sum(loadunload) down
 from autodata
where (autodata.msttime>=@StartTime)
and (autodata.ndtime<=@EndTime)
and (autodata.datatype=2)
group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface

-- Type 2
UPDATE #CockpitData SET downtime = isnull(downtime,0) + isNull(t2.down,0)
from
(select mc,
	sum(DateDiff(second, @StartTime, ndtime)) down
 from autodata
where (autodata.sttime<@StartTime)
and (autodata.ndtime>@StartTime)
and (autodata.ndtime<=@EndTime)
and (autodata.datatype=2)
group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface


-- Type 3
UPDATE #CockpitData SET downtime = isnull(downtime,0) + isNull(t2.down,0)from
(select mc,
	sum(DateDiff(second, stTime, @Endtime)) down
 from autodata
where (autodata.msttime>=@StartTime)

and (autodata.sttime<@EndTime)
and (autodata.ndtime>@EndTime)
and (autodata.datatype=2)group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface


-- Type 4
UPDATE #CockpitData SET downtime = isnull(downtime,0) + isNull(t2.down,0)
from
(select mc,
	sum(DateDiff(second, @StartTime, @EndTime)) down
 from autodata
where autodata.msttime<@StartTime
and autodata.ndtime>@EndTime
and (autodata.datatype=2)
group by autodata.mc
) as t2 inner join #CockpitData on t2.mc = #CockpitData.machineinterface

--Update Total Time
UPDATE #CockpitData
SET	TotalTime = DateDiff(second, @StartTime, @EndTime)


-----------------------Cell/Machine/Component/Operation-----------

---------------------- BEGIN: Get the utilised time
-- Type 1

UPDATE #CockpitDataCellFinish SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
from
(select cellhistory.machineid,
	cellfinishoperation.componentid, 
	cellfinishoperation.operationno,
	sum(autodata.cycletime+autodata.loadunload) as cycle
FROM autodata INNER JOIN
machineinformation ON autodata.mc = machineinformation.interfaceid INNER JOIN
cellhistory ON machineinformation.machineid = cellhistory.machineid INNER JOIN
componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID AND
componentoperationpricing.componentid = componentinformation.componentid INNER join
cellfinishoperation ON componentoperationpricing.componentid = cellfinishoperation.componentid AND
componentoperationpricing.operationno = cellfinishoperation.operationno AND
cellfinishoperation.cellid = cellhistory.cellid
where (autodata.msttime>=@StartTime)
    and (autodata.ndtime<=@EndTime)
    and (autodata.datatype=1)
group by cellhistory.machineid, cellfinishoperation.componentid, cellfinishoperation.operationno
) as t2 inner join #CockpitDataCellFinish on t2.machineid = #CockpitDataCellFinish.machineid and
		   	t2.componentid = #CockpitDataCellFinish.componentid and				
			t2.Operationno = #CockpitDataCellFinish.operationno



--Type 2
UPDATE #CockpitDataCellFinish SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
from
(select cellhistory.machineid,
	cellfinishoperation.componentid, 
	cellfinishoperation.operationno,
	sum(DateDiff(second, @StartTime, ndtime)) cycle
FROM autodata INNER JOIN
machineinformation ON autodata.mc = machineinformation.interfaceid INNER JOIN
cellhistory ON machineinformation.machineid = cellhistory.machineid INNER JOIN
componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID AND
componentoperationpricing.componentid = componentinformation.componentid INNER join
cellfinishoperation ON componentoperationpricing.componentid = cellfinishoperation.componentid AND
componentoperationpricing.operationno = cellfinishoperation.operationno AND
cellfinishoperation.cellid = cellhistory.cellid
where (autodata.msttime<@StartTime)
and (autodata.ndtime>@StartTime)
and (autodata.ndtime<=@EndTime)
and (autodata.datatype=1)
group by cellhistory.machineid, cellfinishoperation.componentid, cellfinishoperation.operationno
) as t2 inner join #CockpitDataCellFinish on t2.machineid = #CockpitDataCellFinish.machineid and
		   	t2.componentid = #CockpitDataCellFinish.componentid and				
			t2.Operationno = #CockpitDataCellFinish.operationno

-- Type 3

UPDATE #CockpitDataCellFinish SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
from
(select cellhistory.machineid,
	cellfinishoperation.componentid, 
	cellfinishoperation.operationno,
	sum(DateDiff(second, mstTime, @Endtime)) cycle
FROM autodata INNER JOIN
machineinformation ON autodata.mc = machineinformation.interfaceid INNER JOIN
cellhistory ON machineinformation.machineid = cellhistory.machineid INNER JOIN
componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID AND
componentoperationpricing.componentid = componentinformation.componentid INNER join
cellfinishoperation ON componentoperationpricing.componentid = cellfinishoperation.componentid AND
componentoperationpricing.operationno = cellfinishoperation.operationno AND
cellfinishoperation.cellid = cellhistory.cellid
where (autodata.msttime>=@StartTime)
and (autodata.msttime<@EndTime)
and (autodata.ndtime>@EndTime)
and (autodata.datatype=1)
group by cellhistory.machineid, cellfinishoperation.componentid, cellfinishoperation.operationno
) as t2 inner join #CockpitDataCellFinish on t2.machineid = #CockpitDataCellFinish.machineid and
		   	t2.componentid = #CockpitDataCellFinish.componentid and				
			t2.Operationno = #CockpitDataCellFinish.operationno

--type 4

UPDATE #CockpitDataCellFinish SET UtilisedTime = isnull(UtilisedTime,0) + isNull(t2.cycle,0)
from
(select cellhistory.machineid,
	cellfinishoperation.componentid, 
	cellfinishoperation.operationno,
	sum(DateDiff(second, @StartTime, @EndTime)) cycle
FROM autodata INNER JOIN
machineinformation ON autodata.mc = machineinformation.interfaceid INNER JOIN
cellhistory ON machineinformation.machineid = cellhistory.machineid INNER JOIN
componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID AND
componentoperationpricing.componentid = componentinformation.componentid INNER join
cellfinishoperation ON componentoperationpricing.componentid = cellfinishoperation.componentid AND
componentoperationpricing.operationno = cellfinishoperation.operationno AND
cellfinishoperation.cellid = cellhistory.cellid
where (autodata.msttime<@StartTime)
and (autodata.ndtime>@EndTime)
and (autodata.datatype=1)
group by cellhistory.machineid, cellfinishoperation.componentid, cellfinishoperation.operationno
) as t2 inner join #CockpitDataCellFinish on t2.machineid = #CockpitDataCellFinish.machineid and
		   	t2.componentid = #CockpitDataCellFinish.componentid and				
			t2.Operationno = #CockpitDataCellFinish.operationno

	/* Down Within Production Cycle*/
	-- Type - 2 
	UPDATE  #CockpitDataCellFinish SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
	FROM
	(Select Cellhistory.Machineid,Cellfinishoperation.Componentid, Cellfinishoperation.Operationno,
	SUM(
	CASE 
		When autodata.sttime <= @StartTime Then datediff(s, @StartTime,autodata.ndtime )
		When autodata.sttime > @StartTime Then datediff(s , autodata.sttime,autodata.ndtime)
	END) as Down
	From AutoData INNER Join 
		(Select mc,Comp,Opn,Sttime,NdTime From AutoData
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And 
			(sttime < @StartTime)And (ndtime > @StartTime) AND (ndtime <= @EndTime)) as T1
	ON AutoData.mc=T1.mc AND AutoData.Comp=T1.Comp AND AutoData.Opn=T1.Opn
	INNER JOIN Machineinformation ON autodata.mc = machineinformation.interfaceid 
	INNER JOIN Cellhistory ON machineinformation.machineid = Cellhistory.machineid 
	INNER JOIN Componentoperationpricing ON autodata.opn = Componentoperationpricing.InterfaceID
	INNER JOIN Componentinformation ON autodata.comp = Componentinformation.InterfaceID AND
	Componentoperationpricing.Componentid = componentinformation.Componentid 
	INNER join cellfinishoperation ON Componentoperationpricing.Componentid = Cellfinishoperation.Componentid AND
	Componentoperationpricing.operationno =Cellfinishoperation.operationno AND
	Cellfinishoperation.cellid = Cellhistory.Cellid
	Where AutoData.DataType=2 
	And ( autodata.Sttime > T1.Sttime )
	And ( autodata.ndtime <  T1.ndtime ) 
	AND ( autodata.ndtime >  @StartTime )
	GROUP BY Cellhistory.Machineid,Cellfinishoperation.Componentid, Cellfinishoperation.Operationno)AS T2 
	Inner Join  #CockpitDataCellFinish on T2.machineid = #CockpitDataCellFinish.machineid And
			   	T2.componentid = #CockpitDataCellFinish.Componentid And				
				T2.Operationno = #CockpitDataCellFinish.operationno
	
	/* Down Within Production Cycle*/
	-- Type - 3 
	UPDATE  #CockpitDataCellFinish SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
	FROM
	(Select Cellhistory.Machineid,Cellfinishoperation.Componentid, Cellfinishoperation.Operationno,
	SUM(
	CASE 
		When autodata.ndtime > @EndTime Then datediff(s,autodata.sttime, @EndTime )
		When autodata.ndtime <=@EndTime Then datediff(s , autodata.sttime,autodata.ndtime)
	END) as Down
	From AutoData INNER Join 
		(Select mc,Comp,Opn,Sttime,NdTime From AutoData
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And 
			(sttime >= @StartTime)And (ndtime > @EndTime)) as T1
	ON AutoData.mc=T1.mc AND AutoData.Comp=T1.Comp AND AutoData.Opn=T1.Opn
	INNER JOIN Machineinformation ON autodata.mc = machineinformation.interfaceid 
	INNER JOIN Cellhistory ON machineinformation.machineid = Cellhistory.machineid 
	INNER JOIN Componentoperationpricing ON autodata.opn = Componentoperationpricing.InterfaceID
	INNER JOIN Componentinformation ON autodata.comp = Componentinformation.InterfaceID AND
	Componentoperationpricing.Componentid = componentinformation.Componentid 
	INNER join cellfinishoperation ON Componentoperationpricing.Componentid = Cellfinishoperation.Componentid AND
	Componentoperationpricing.operationno =Cellfinishoperation.operationno AND
	Cellfinishoperation.cellid = Cellhistory.Cellid
	Where AutoData.DataType=2 
	And (T1.Sttime < autodata.sttime  )
	And ( T1.ndtime >  autodata.ndtime) 
	AND (autodata.sttime  <  @EndTime)
	GROUP BY Cellhistory.Machineid,Cellfinishoperation.Componentid, Cellfinishoperation.Operationno)AS T2 
	Inner Join  #CockpitDataCellFinish on T2.machineid = #CockpitDataCellFinish.machineid And
			   	T2.componentid = #CockpitDataCellFinish.Componentid And				
				T2.Operationno = #CockpitDataCellFinish.operationno
	
	/* Down Within Production Cycle*/
	-- Type - 4 
	UPDATE  #CockpitDataCellFinish SET UtilisedTime = isnull(UtilisedTime,0) - isNull(t2.Down,0)
	FROM
	(Select Cellhistory.Machineid,Cellfinishoperation.Componentid, Cellfinishoperation.Operationno,
	SUM(
	CASE 
		When autodata.sttime < @StartTime AND autodata.ndtime<=@EndTime Then datediff(s, @StartTime,autodata.ndtime )
		When autodata.ndtime >= @EndTime AND autodata.sttime>@StartTime Then datediff(s,autodata.sttime, @EndTime )
		When autodata.sttime >= @StartTime AND
		     autodata.ndtime <= @EndTime Then datediff(s , autodata.sttime,autodata.ndtime)
		When autodata.sttime<@StartTime AND autodata.ndtime>@EndTime   Then datediff(s , @StartTime,@EndTime)
	END) as Down
	From AutoData INNER Join 
		(Select mc,Comp,Opn,Sttime,NdTime From AutoData
			Where DataType=1 And DateDiff(Second,sttime,ndtime)>CycleTime And 
			(sttime < @StartTime)And (ndtime > @EndTime)) as T1
	ON AutoData.mc=T1.mc AND AutoData.Comp=T1.Comp AND AutoData.Opn=T1.Opn
	INNER JOIN Machineinformation ON autodata.mc = machineinformation.interfaceid 
	INNER JOIN Cellhistory ON machineinformation.machineid = Cellhistory.machineid 
	INNER JOIN Componentoperationpricing ON autodata.opn = Componentoperationpricing.InterfaceID
	INNER JOIN Componentinformation ON autodata.comp = Componentinformation.InterfaceID AND
	Componentoperationpricing.Componentid = componentinformation.Componentid 
	INNER join cellfinishoperation ON Componentoperationpricing.Componentid = Cellfinishoperation.Componentid AND
	Componentoperationpricing.operationno =Cellfinishoperation.operationno AND
	Cellfinishoperation.cellid = Cellhistory.Cellid
	Where AutoData.DataType=2 
	And (T1.Sttime < autodata.sttime  )
	And ( T1.ndtime >  autodata.ndtime) 
	AND (autodata.ndtime  >  @StartTime)
	AND (autodata.sttime  <  @EndTime)
	GROUP BY Cellhistory.Machineid,Cellfinishoperation.Componentid, Cellfinishoperation.Operationno)AS T2 
	Inner Join  #CockpitDataCellFinish on T2.machineid = #CockpitDataCellFinish.machineid And
			   	T2.componentid = #CockpitDataCellFinish.Componentid And				
				T2.Operationno = #CockpitDataCellFinish.operationno
	

------------------END: Utilised Time

-------------------BEGIN: Downtime excluding ManagementLoss
-- Type 1

UPDATE #CockpitDataCellFinish SET DownTime = isnull(DownTime,0) + isNull(t2.down,0)
from
(select cellhistory.machineid,
	cellfinishoperation.componentid, 
	cellfinishoperation.operationno,
	sum(autodata.loadunload) as down
FROM autodata INNER JOIN
machineinformation ON autodata.mc = machineinformation.interfaceid INNER JOIN
cellhistory ON machineinformation.machineid = cellhistory.machineid INNER JOIN
componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID AND
componentoperationpricing.componentid = componentinformation.componentid INNER join
cellfinishoperation ON componentoperationpricing.componentid = cellfinishoperation.componentid AND
componentoperationpricing.operationno = cellfinishoperation.operationno AND
cellfinishoperation.cellid = cellhistory.cellid INNER JOIN
downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
where (autodata.msttime>=@StartTime)
    and (autodata.ndtime<=@EndTime)
    and (autodata.datatype=2)
and (downcodeinformation.availeffy = 0)
group by cellhistory.machineid, cellfinishoperation.componentid, cellfinishoperation.operationno
) as t2 inner join #CockpitDataCellFinish on t2.machineid = #CockpitDataCellFinish.machineid and
		   	t2.componentid = #CockpitDataCellFinish.componentid and				
			t2.Operationno = #CockpitDataCellFinish.operationno

-- Type 2
UPDATE #CockpitDataCellFinish SET DownTime = isnull(DownTime,0) + isNull(t2.down,0)
from
(select cellhistory.machineid,
	cellfinishoperation.componentid, 
	cellfinishoperation.operationno,
	sum(DateDiff(second, @StartTime, ndtime)) down
FROM autodata INNER JOIN
machineinformation ON autodata.mc = machineinformation.interfaceid INNER JOIN
cellhistory ON machineinformation.machineid = cellhistory.machineid INNER JOIN
componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID AND
componentoperationpricing.componentid = componentinformation.componentid INNER join
cellfinishoperation ON componentoperationpricing.componentid = cellfinishoperation.componentid AND
componentoperationpricing.operationno = cellfinishoperation.operationno AND
cellfinishoperation.cellid = cellhistory.cellid INNER JOIN
downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
where (autodata.sttime<@StartTime)
    and (autodata.ndtime>@StartTime)
and (autodata.ndtime<=@EndTime)
and (autodata.datatype=2)
and (downcodeinformation.availeffy = 0)
group by cellhistory.machineid, cellfinishoperation.componentid, cellfinishoperation.operationno
) as t2 inner join #CockpitDataCellFinish on t2.machineid = #CockpitDataCellFinish.machineid and
		   	t2.componentid = #CockpitDataCellFinish.componentid and				
			t2.Operationno = #CockpitDataCellFinish.operationno

-- Type 3

UPDATE #CockpitDataCellFinish SET DownTime = isnull(DownTime,0) + isNull(t2.down,0)
from
(select cellhistory.machineid,
	cellfinishoperation.componentid, 
	cellfinishoperation.operationno,
	sum(DateDiff(second, stTime, @Endtime)) down
FROM autodata INNER JOIN
machineinformation ON autodata.mc = machineinformation.interfaceid INNER JOIN
cellhistory ON machineinformation.machineid = cellhistory.machineid INNER JOIN
componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID AND
componentoperationpricing.componentid = componentinformation.componentid INNER join
cellfinishoperation ON componentoperationpricing.componentid = cellfinishoperation.componentid AND
componentoperationpricing.operationno = cellfinishoperation.operationno AND
cellfinishoperation.cellid = cellhistory.cellid INNER JOIN
downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
where (autodata.msttime>=@StartTime)
and (autodata.sttime<@EndTime)
and (autodata.ndtime>@EndTime)
and (autodata.datatype=2)
and (downcodeinformation.availeffy = 0)
group by cellhistory.machineid, cellfinishoperation.componentid, cellfinishoperation.operationno
) as t2 inner join #CockpitDataCellFinish on t2.machineid = #CockpitDataCellFinish.machineid and
		   	t2.componentid = #CockpitDataCellFinish.componentid and				
			t2.Operationno = #CockpitDataCellFinish.operationno
-- Type 4
UPDATE #CockpitDataCellFinish SET DownTime = isnull(DownTime,0) + isNull(t2.down,0)
from
(select cellhistory.machineid,
	cellfinishoperation.componentid, 
	cellfinishoperation.operationno,
	sum(DateDiff(second, @StartTime, @Endtime)) down
FROM autodata INNER JOIN
machineinformation ON autodata.mc = machineinformation.interfaceid INNER JOIN
cellhistory ON machineinformation.machineid = cellhistory.machineid INNER JOIN
componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID AND
componentoperationpricing.componentid = componentinformation.componentid INNER join
cellfinishoperation ON componentoperationpricing.componentid = cellfinishoperation.componentid AND
componentoperationpricing.operationno = cellfinishoperation.operationno AND
cellfinishoperation.cellid = cellhistory.cellid INNER JOIN
downcodeinformation ON autodata.dcode = downcodeinformation.interfaceid
where autodata.msttime<@StartTime
and autodata.ndtime>@EndTime
and (autodata.datatype=2)
and (downcodeinformation.availeffy = 0)
group by cellhistory.machineid, cellfinishoperation.componentid, cellfinishoperation.operationno
) as t2 inner join #CockpitDataCellFinish on t2.machineid = #CockpitDataCellFinish.machineid and
		   	t2.componentid = #CockpitDataCellFinish.componentid and				
			t2.Operationno = #CockpitDataCellFinish.operationno

---------------END: Downtime excluding ManagementLoss

---------------BEGIN: Finish Operations by Cell/Component/Operation

--Type 1
UPDATE #CockpitDatacellfinish SET finishopn = isnull(finishopn,0) + isNull(t2.finish,0)
from
(select cellhistory.machineid,
	cellfinishoperation.componentid, 
	cellfinishoperation.operationno,
	CEILING(CAST(count(autodata.opn)AS Float)/ISNULL(ComponentOperationPricing.SubOperations,1)) finish
   FROM autodata INNER JOIN
machineinformation ON autodata.mc = machineinformation.interfaceid INNER JOIN
cellhistory ON machineinformation.machineid = cellhistory.machineid INNER JOIN
componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID AND
componentoperationpricing.componentid = componentinformation.componentid INNER join
cellfinishoperation ON componentoperationpricing.componentid = cellfinishoperation.componentid AND
componentoperationpricing.operationno = cellfinishoperation.operationno AND
cellfinishoperation.cellid = cellhistory.cellid
where (autodata.sttime>=@StartTime)
  and (autodata.ndtime<=@EndTime)
  and (autodata.datatype=1)
group by cellhistory.machineid, cellfinishoperation.componentid, cellfinishoperation.operationno,ComponentOperationPricing.SubOperations
)as t2 inner join #CockpitDataCellFinish on t2.machineid = #CockpitDataCellFinish.machineid and
		   	t2.componentid = #CockpitDataCellFinish.componentid and				
			t2.Operationno = #CockpitDataCellFinish.operationno




--Type 2

UPDATE #CockpitDatacellfinish SET finishopn = isnull(finishopn,0) + isNull(t2.finish,0)
from
(select cellhistory.machineid,
	cellfinishoperation.componentid, 
	cellfinishoperation.operationno,
	CEILING(CAST(count(autodata.opn)AS Float)/ISNULL(ComponentOperationPricing.SubOperations,1)) finish
   FROM autodata INNER JOIN
machineinformation ON autodata.mc = machineinformation.interfaceid INNER JOIN
cellhistory ON machineinformation.machineid = cellhistory.machineid INNER JOIN
componentoperationpricing ON autodata.opn = componentoperationpricing.InterfaceID INNER JOIN
componentinformation ON autodata.comp = componentinformation.InterfaceID AND
componentoperationpricing.componentid = componentinformation.componentid INNER join
cellfinishoperation ON componentoperationpricing.componentid = cellfinishoperation.componentid AND
componentoperationpricing.operationno = cellfinishoperation.operationno AND
cellfinishoperation.cellid = cellhistory.cellid
where (autodata.sttime<@StartTime)
and (autodata.ndtime>@StartTime)
and (autodata.ndtime<=@EndTime)
  and (autodata.datatype=1)
group by cellhistory.machineid, cellfinishoperation.componentid, cellfinishoperation.operationno,ComponentOperationPricing.SubOperations
)as t2 inner join #CockpitDataCellFinish on t2.machineid = #CockpitDataCellFinish.machineid and
		   	t2.componentid = #CockpitDataCellFinish.componentid and				
			t2.Operationno = #CockpitDataCellFinish.operationno

---------------END  : Finish Operations by Cell/Component/Operation

delete from #CockpitDataCellFinish where utilisedtime = 0 and downtime = 0

/*
update #CockpitDataCellFinish
set yieldeffy = (finishopn * 3600)/((UtilisedTime + Downtime) * yield)
*/
--Changed yield definition to Takt Time - mkestur 22/01/2005
update #CockpitDataCellFinish
set yieldeffy = (finishopn * yield)/(UtilisedTime + Downtime) 

------------------------------------Cell/Machine/Component/Operation------------



--insert into the cell table
begin
INSERT INTO #CockpitDataCell (
	CellId,
	ProductionEfficiency,
	AvailabilityEfficiency,
	OverallEfficiency,
	TotalOpn,
	finishopn,
	yieldeffy,
	TotalTime ,
	UtilisedTime ,	
	ManagementLoss,
	DownTime ,
	TurnOver ,
	CN
	)
	SELECT CellId,0,0,0,sum(TotalOpn),0,0,sum(totaltime),sum(utilisedtime),
			    sum(ManagementLoss),sum(downtime),sum(turnover),sum(CN) 
	FROM #CockpitData group by #CockpitData.CellId
end


UPDATE #CockpitDataCell
SET
	ProductionEfficiency = (CN/UtilisedTime) ,
	AvailabilityEfficiency = (UtilisedTime)/(UtilisedTime + DownTime - ManagementLoss),	ReturnPerHour = (TurnOver/UtilisedTime)*3600,
	Remarks = ' '
WHERE UtilisedTime <> 0


UPDATE #CockpitDatacell
SET
	OverAllEfficiency = (ProductionEfficiency * AvailabilityEfficiency)*100,
	ProductionEfficiency = ProductionEfficiency * 100 ,
	AvailabilityEfficiency = AvailabilityEfficiency * 100

UPDATE #CockpitDatacell
SET Remarks = 'No Production in Cell'
WHERE UtilisedTime = 0

---BEGIN: Calculate Number of Finish Opeartions and Average Yield Efficiency for the cell

UPDATE #CockpitDatacell SET yieldeffy = isNull(t2.yieldeffy,0),
			    finishopn = isnull(t2.finish,0)
from
(select #CockpitDatacellfinish.cellid, sum(finishopn) as finish, (sum(finishopn * yieldeffy)/sum(finishopn))*100 as YieldEffy
from #cockpitdatacellfinish
group by cellid
Having sum(finishopn)> 0) as t2 inner join #CockpitDataCell on t2.cellid = #CockpitDatacell.cellid

---END  : Calculate Number of Finish Operations and Average Yield Efficiency for the cell

/*
select * from #CockpitDataCell
*/

/*
select * from #CockpitDataCellFinish
*/

/*
select cellid, sum(finishopn) as finishopn, (sum(finishopn * yieldeffy)/sum(finishopn))*100 as YieldEffy
from #cockpitdatacellfinish
group by cellid
*/

SELECT
#CockpitDataCell.CellID,
ProductionEfficiency,
AvailabilityEfficiency,
OverAllEfficiency,
TotalOpn,
FinishOpn,
yieldeffy,
TurnOver,
--Convert(nvarchar(4), convert(bigint, UtilisedTime)/3600) + ':' + convert(nvarchar(2), (convert(bigint, UtilisedTime)%3600)/60) + ':' + convert(nvarchar(2), (convert(bigint, UtilisedTime)%60)) as UtilisedTime,

--Convert(nvarchar(4), convert(bigint, ManagementLoss)/3600) + ':' + convert(nvarchar(2), (convert(bigint, ManagementLoss)%3600)/60) + ':' + convert(nvarchar(2), (convert(bigint, ManagementLoss)%60)) as ManagementLoss,
--Convert(nvarchar(4), convert(bigint, DownTime)/3600) + ':' + convert(nvarchar(2), (convert(bigint, DownTime)%3600)/60) + ':' + convert(nvarchar(2), (convert(bigint, DownTime)%60)) as DownTime,
--Convert(nvarchar(6), convert(bigint, TotalTime)/3600) + ':' + convert(nvarchar(2), (convert(bigint, TotalTime)%3600)/60) + ':' + convert(nvarchar(2), (convert(bigint, TotalTime)%60)) as TotalTime,
dbo.f_FormatTime(UtilisedTime,'hh:mm:ss') as UtilisedTime,
dbo.f_FormatTime(ManagementLoss,'hh:mm:ss') as ManagementLoss,
dbo.f_FormatTime(DownTime,'hh:mm:ss') as DownTime,
dbo.f_FormatTime(TotalTime,'hh:mm:ss') as TotalTime,
ReturnPerHour,
Remarks,
Cell.PEGreen,
Cell.PERed,
Cell.AEGreen,
Cell.AERed,
Cell.OEGreen,
Cell.OERed,
@StartTime as StartTime,
@EndTime as EndTime
FROM #CockpitDataCell inner join Cell on #cockpitdatacell.cellid = Cell.cellid
order by #CockpitDatacell.CellId asc
END
