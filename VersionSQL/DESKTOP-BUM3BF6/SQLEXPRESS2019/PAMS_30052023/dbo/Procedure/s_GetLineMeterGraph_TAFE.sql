/****** Object:  Procedure [dbo].[s_GetLineMeterGraph_TAFE]    Committed by VersionSQL https://www.versionsql.com ******/

/**************************************************************************************************************** 
-----------------------Created By : Anjana C V----------------------- 
-----------------------Created On : 04/JAN/2019-----------------------
-----------------------Modified On : 05/JAN/2019-----------------------
-------NR275 - Description: Get Line Meter Graph data at machine level for TAFE -------
[dbo].[s_GetLineMeterGraph_TAFE] 'PKH VTL 3.5-02','2018-12-01 00:00:00.000','2018-12-31 00:00:00.000'
****************************************************************************************************************/
CREATE PROCEDURE [dbo].[s_GetLineMeterGraph_TAFE]
	@MachineID As nvarchar(50),
	@StartDate As DateTime,
	@EndDate As DateTime

AS
BEGIN

declare @CurStrtTime as datetime
select @CurStrtTime = @StartDate

DECLARE @percent FLOAT
select @percent = 10.00/100.00

create table #day
 (
  Starttime datetime,
  Endtime datetime
 )
 
 while @CurStrtTime<=@EndDate
  BEGIN
	Insert into #day(Starttime,Endtime)
    Select dbo.f_GetLogicalDay(@CurStrtTime,'start'),dbo.f_GetLogicalDay(@CurStrtTime,'End')
	SELECT @CurStrtTime=DATEADD(DAY,1,@CurStrtTime)
  END

--select * from #day

Create Table #ProdData
	(
	 Day  DateTime,
	 Starttime datetime,
     Endtime datetime,
	 --Shift  NVarChar(50),
	 MachineID  NVarChar(50),
	 TargetCount int default 0,
	 ActualCount int default 0,
	 AcceptedParts int default 0,
	 DelayCount int default 0,
	 TenPercent float default 0,
	 NegativeTenPercent float default 0
	 )

INSERT INTO #ProdData(Day,Starttime,Endtime,MachineID)
SELECT(CAST(datePart(yyyy,Starttime) AS nvarchar(4)) + '-' + SUBSTRING(DATENAME(MONTH,Starttime),1,3) + '-' + CAST(datePart(dd,Starttime) AS nvarchar(2))),
Starttime,Endtime,@MachineID FROM  #day 


UPDATE #ProdData
SET Day= T.pDate,
ActualCount = ISNULL(T.ActualCount,0) ,
AcceptedParts = ISNULL(T.AcceptedParts,0) 
FROM 
(
	SELECT Distinct SPD.pDate AS pDate,SPD.MachineID AS MachineID,
	Sum(ISNULL(Prod_Qty,0)) AS ActualCount,Sum(ISNULL(AcceptedParts,0)) AS AcceptedParts
	   --SPD.Shift,
	From ShiftProductionDetails SPD
	Where SPD.MachineID = @MachineID
	and SPD.pDate >= @StartDate 
	and  SPD.pDate <= @EndDate 
	group by SPD.pDate,SPD.MachineID
) T INNER JOIN #ProdData ON  T.pDate >= #ProdData.Day and T.MachineID = #ProdData.MachineID 

UPDATE #ProdData
SET TargetCount= isnull(T.TargetCount,0)
FROM 
(
	SELECT Distinct sum(L.IdealCount) as TargetCount,L.date AS pDate, L.Machine AS MachineID
	From LoadSchedule L
	inner join (select DISTINCT pDate,Shift,MachineID,ComponentID,OperationNo from ShiftProductionDetails )as SPD  
	on  L.Machine =SPD.MachineID and L.Component = SPD.ComponentID and L.Operation = SPD.OperationNo 
	and L.date =SPD.pDate and L.Shift = SPD.Shift
    Where SPD.MachineID = @MachineID
	and SPD.pDate >= @StartDate 
	and  SPD.pDate <= @EndDate 
	group by L.date,L.Machine
) T INNER JOIN #ProdData ON  T.pDate >= #ProdData.Day and T.MachineID = #ProdData.MachineID

update #ProdData
set DelayCount = (ActualCount - TargetCount)
,TenPercent = TargetCount + (@percent*TargetCount) 
,NegativeTenPercent = TargetCount -(@percent*TargetCount)  

select * from #ProdData

END
