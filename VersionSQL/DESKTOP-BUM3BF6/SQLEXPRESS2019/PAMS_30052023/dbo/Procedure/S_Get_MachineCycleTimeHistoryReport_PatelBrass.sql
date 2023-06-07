/****** Object:  Procedure [dbo].[S_Get_MachineCycleTimeHistoryReport_PatelBrass]    Committed by VersionSQL https://www.versionsql.com ******/

/**********************************************************
Created By : Anjana C V
Created On: 13 March 2020
Modifird On: 13 March 2020
Description : 
exec S_Get_MachineCycleTimeHistoryReport_PatelBrass '2020-01-01','','','','','','','MachiningTime'
exec S_Get_MachineCycleTimeHistoryReport_PatelBrass '2020-01-01','','','','','','','LoadUnLoadTime'
exec S_Get_MachineCycleTimeHistoryReport_PatelBrass '2020-01-01','','','','','','','CycleTime'

**********************************************************/
CREATE procedure [dbo].[S_Get_MachineCycleTimeHistoryReport_PatelBrass]
 @StartDate datetime,
 @EndDate datetime='',
 @Machine nvarchar(50)='',
 @Shift Nvarchar(50)='',
 @Componenet nvarchar(50)='',
 @Operation nvarchar(50)='',
 @View nvarchar(50)='', /* Month or Shift wise view */
 @Param nvarchar(50)='' /*CycleTiem or loadunload or Machine */  
 AS 
 BEGIN 

 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

 DECLARE @Stdate datetime 
 DECLARE @ndDate datetime  
 DECLARE @Mintime float 
 DECLARE @CurStrtTime DateTime

 CREATE TABLE #Target
 (
	 ID bigint IDENTITY(1,1) NOT NULL,
	 StartDate datetime ,
	 EndDate Datetime,
	 MonthName nvarchar(50),
	 ShiftName nvarchar(50), 
	 MachineID nvarchar(50),
	 Comp nvarchar(50),
	 Opn nvarchar(50),
	 MinStdTime float,
	 StdTimeDiff float,
	 AvgMachineTime float
 )

	CREATE TABLE #TIME
	(
		 ID bigint IDENTITY(1,1) NOT NULL,
		 StartDate datetime ,
		 EndDate Datetime,
		 Month int,
		 MonthName nvarchar(50), 
		 Year INT
	)

	SELECT @Stdate = DATEADD(yy, DATEDIFF(yy, 0, @StartDate), 0)
	SELECT @ndDate = DATEADD(yy, DATEDIFF(yy, 0, @Stdate) + 1, -1)

	INSERT INTO #TIME (StartDate,EndDate,Month,MonthName,Year)
	SELECT TOP (DATEDIFF(MONTH, @Stdate, @ndDate)+1) 
	  StartDate  = DATEADD(MONTH, NUMBER, @Stdate),
	  --EndDate  = EOMONTH(DATEADD(MONTH, NUMBER, @Stdate)),
	   EndDate  = Convert(Nvarchar(10),DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,-1,@Stdate)+NUMBER ,0)),120),
	  MonthNumber = MONTH(DATEADD(MONTH, NUMBER, @Stdate)),
	  MonthNAME = DATENAME(MONTH,DATEADD(MONTH, NUMBER, @Stdate)),
	  TheYear  = YEAR(DATEADD(MONTH, number, @Stdate))
	  FROM [master].dbo.spt_values 
	  WHERE [type] = N'P' ORDER BY number	

	INSERT INTO #Target (StartDate,EndDate,MonthName,MachineID,Comp,Opn)
	 SELECT DISTINCT T.StartDate,T.EndDate,T.MonthName,S.MachineID,S.ComponentID,S.OperationNo
		FROM ShiftProductionDetails S
		CROSS JOIN #TIME T
		WHERE S.Pdate >= @Stdate and S.Pdate <= @ndDate
		AND (ISNULL(@Machine,'') = '' OR S.MachineID = @Machine )
		AND (ISNULL(@Componenet,'') = '' OR S.ComponentID = @Componenet )
		AND (ISNULL(@Operation,'') = '' OR S.OperationNo = @Operation )

IF ISNULL(@Param,'') ='' or ISNULL(@Param,'') ='MachiningTime'
BEGIN
	UPDATE #Target
	SET MinStdTime = T.MinStdTime,
		AvgMachineTime = T.AvgMachineTime
	FROM 
		(
		SELECT Tg.StartDate,Tg.EndDate,S.MachineID,S.ComponentID,S.OperationNo,MIN(S.CO_StdMachiningTime) as MinStdTime,
		CASE WHEN ISNULL(sum(S.Prod_Qty),0) <> 0 
		THEN (sum(S.ActMachiningTime_Type12)/sum(S.Prod_Qty)) 
		END as AvgMachineTime
		FROM ShiftProductionDetails S
		INNER JOIN #Target Tg ON Tg.MachineID = S.MachineID AND Tg.Comp = s.ComponentID AND Tg.Opn = s.OperationNo
		WHERE S.pDate >= Tg.StartDate AND S.pDate <= Tg.EndDate 
		GROUP By Tg.StartDate,Tg.EndDate,S.MachineID,S.ComponentID,S.OperationNo
		)T
	INNER JOIN #Target Tg ON Tg.StartDate = T.StartDate and Tg.MachineID = T.MachineID and Tg.Comp = T.ComponentID and Tg.Opn = T.OperationNo 
END
ELSE IF ISNULL(@Param,'') ='LoadUnLoadTime'
BEGIN
UPDATE #Target
	SET MinStdTime = T.MinStdTime,
		AvgMachineTime = T.AvgMachineTime
	FROM 
		(
		SELECT Tg.StartDate,Tg.EndDate,S.MachineID,S.ComponentID,S.OperationNo,MIN(S.CO_StdLoadUnload) as MinStdTime,
		CASE WHEN ISNULL(sum(S.Prod_Qty),0) <> 0 
		THEN (sum(S.ActMachiningTime_Type12)/sum(S.Prod_Qty)) 
		END as AvgMachineTime
		FROM ShiftProductionDetails S
		INNER JOIN #Target Tg ON Tg.MachineID = S.MachineID AND Tg.Comp = s.ComponentID AND Tg.Opn = s.OperationNo
		WHERE S.pDate >= Tg.StartDate AND S.pDate <= Tg.EndDate 
		GROUP By Tg.StartDate,Tg.EndDate,S.MachineID,S.ComponentID,S.OperationNo
		)T
	INNER JOIN #Target Tg ON Tg.StartDate = T.StartDate and Tg.MachineID = T.MachineID and Tg.Comp = T.ComponentID and Tg.Opn = T.OperationNo 
END

ELSE IF ISNULL(@Param,'') ='CycleTime'
BEGIN
UPDATE #Target
	SET MinStdTime = ISNULL(T.MinStdTime,0) + ISNULL(T.MinStdLoadTime,0),
		AvgMachineTime = T.AvgMachineTime
	FROM 
		(
		SELECT Tg.StartDate,Tg.EndDate,S.MachineID,S.ComponentID,S.OperationNo,MIN(S.CO_StdMachiningTime) MinStdTime,MIN(S.CO_StdLoadUnload) as MinStdLoadTime,
		CASE WHEN ISNULL(sum(S.Prod_Qty),0) <> 0 
		THEN (sum(S.ActMachiningTime_Type12)/sum(S.Prod_Qty)) 
		END as AvgMachineTime
		FROM ShiftProductionDetails S
		INNER JOIN #Target Tg ON Tg.MachineID = S.MachineID AND Tg.Comp = s.ComponentID AND Tg.Opn = s.OperationNo
		WHERE S.pDate >= Tg.StartDate AND S.pDate <= Tg.EndDate 
		GROUP By Tg.StartDate,Tg.EndDate,S.MachineID,S.ComponentID,S.OperationNo
		)T
	INNER JOIN #Target Tg ON Tg.StartDate = T.StartDate and Tg.MachineID = T.MachineID and Tg.Comp = T.ComponentID and Tg.Opn = T.OperationNo 
END

UPDATE #Target
SET StdTimeDiff  = ISNULL(Tg.MinStdTime,0) - ISNULL(T.MinTime,0)
FROM 
	(
	 SELECT MachineID,Comp,Opn, MIN(MinStdTime) MinTime
	 FROM #Target
	 WHERE ISNULL(MinStdTime,0) <> 0
	 GROUP BY MachineID,Comp,Opn
	) T
INNER JOIN #Target Tg on T.MachineID=Tg.MachineID and T.Comp =Tg.Comp  and t.Opn = Tg.Opn
WHERE ISNULL(Tg.MinStdTime,0) <> 0

 SELECT StartDate,EndDate,MonthName,MachineID,Comp,Opn,MinStdTime,StdTimeDiff,AvgMachineTime 
 FROM  #Target
 ORDER By StartDate,MachineId,Comp,Opn

 END
