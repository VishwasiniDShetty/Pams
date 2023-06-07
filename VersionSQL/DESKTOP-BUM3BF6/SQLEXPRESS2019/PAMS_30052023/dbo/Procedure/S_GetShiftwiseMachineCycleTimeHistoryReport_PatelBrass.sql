/****** Object:  Procedure [dbo].[S_GetShiftwiseMachineCycleTimeHistoryReport_PatelBrass]    Committed by VersionSQL https://www.versionsql.com ******/

/**********************************************************
Created By : Anjana C V
Created On: 13 March 2020
Modifird On: 13 March 2020
Description : 
exec S_GetShiftwiseMachineCycleTimeHistoryReport_PatelBrass '2020-03-01 09:00:00','2020-03-10 09:00:00','','','','','CycleTime','Variant'

exec S_GetShiftwiseMachineCycleTimeHistoryReport_PatelBrass '2020-03-01 09:00:00','2020-03-10 09:00:00','','','','','MachiningTime',''
exec S_GetShiftwiseMachineCycleTimeHistoryReport_PatelBrass '2020-01-01 09:00:00','2020-01-03 09:00:00','','','','','LoadUnLoadTime'
exec S_GetShiftwiseMachineCycleTimeHistoryReport_PatelBrass '2020-01-01 09:00:00','2020-01-03 09:00:00','','','','','CycleTime'
**********************************************************/
CREATE procedure [dbo].[S_GetShiftwiseMachineCycleTimeHistoryReport_PatelBrass]
 @StartDate datetime,
 @EndDate datetime,
 @Machine nvarchar(50)='',
 @Shift Nvarchar(50)='',
 @Componenet nvarchar(50)='',
 @Operation nvarchar(50)='',
 @Param nvarchar(50)='', /*CycleTiem or loadunload or Machine */  
 @View nvarchar(50)=''
 AS 
 BEGIN 

 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

 DECLARE @Stdate datetime 
 DECLARE @ndDate datetime  
 DECLARE @Mintime float 
 DECLARE @CurStrtTime DateTime
 DECLARE @ShiftStr nvarchar(500)
 Declare @sqlstr nvarchar(MAX)

 CREATE TABLE #Target
 (
	 ID bigint IDENTITY(1,1) NOT NULL,
	 StartDate datetime ,
	 EndDate Datetime,
	 Pdate Datetime,
	 ShiftName nvarchar(50), 
	 MachineID nvarchar(50),
	 Comp nvarchar(50),
	 Opn nvarchar(50),
	 MinStdTime float,
	 StdTimeDiff float,
	 AvgMachineTime float,
	 MachiningTime float,
	 LoadUnLoadTime Float
 )

	Create table #ShiftTime
	(
		PDate DateTime ,
		ShiftName NVarChar(50),
		Shiftid int,
		StartTime DateTime,
		EndTime DateTime
	)

	SELECT @ShiftStr = ''
	SELECT @CurStrtTime = @StartDate

	IF ISNULL(@Shift,'') ='' SELECT @Shift = ''

	while @CurStrtTime<=@EndDate
	BEGIN
		INSERT #ShiftTime (Pdate, ShiftName, StartTime, EndTime)
		EXEC s_GetShiftTime @CurStrtTime,@Shift
		SELECT @CurStrtTime=DATEADD(DAY,1,@CurStrtTime)
	END

SELECT @ShiftStr = 
		( SELECT Stuff(( SELECT  ',' + QuoteName( S.ShiftName)
				FROM  shiftdetails S
				where running = 1
				order by S.shiftid
		  FOR XML Path(''),Type).value('text()[1]', 'varchar(max)'), 1, 1, '')
		)

	INSERT INTO #Target (Pdate,StartDate,EndDate,ShiftName,MachineID,Comp,Opn)
	 SELECT DISTINCT T.PDate,T.StartTime,T.EndTime,T.ShiftName,S.MachineID,S.ComponentID,S.OperationNo
		FROM ShiftProductionDetails S
		CROSS JOIN #ShiftTime T		
		WHERE Convert(NvarChar(10),S.Pdate,120) >= Convert(NvarChar(10),@StartDate,120)
		 AND Convert(NvarChar(10),S.Pdate,120) <= Convert(NvarChar(10),@EndDate,120)
		AND (ISNULL(@Machine,'') = '' OR S.MachineID = @Machine )
		AND (ISNULL(@Componenet,'') = '' OR S.ComponentID = @Componenet )
		AND (ISNULL(@Operation,'') = '' OR S.OperationNo = @Operation )
		ORDER BY S.MachineID,S.ComponentID,S.OperationNo,T.StartTime 

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
		WHERE Convert(NvarChar(10),S.Pdate,120) = Convert(NvarChar(10),Tg.Pdate,120) 
		AND S.Shift = Tg.ShiftName
		GROUP By Tg.StartDate,Tg.EndDate,S.MachineID,S.ComponentID,S.OperationNo
		)T
	INNER JOIN #Target Tg ON Tg.StartDate = T.StartDate and Tg.MachineID = T.MachineID 
	and Tg.Comp = T.ComponentID and Tg.Opn = T.OperationNo 
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
		WHERE Convert(NvarChar(10),S.Pdate,120) = Convert(NvarChar(10),Tg.Pdate,120) AND S.Shift = Tg.ShiftName
		GROUP By Tg.StartDate,Tg.EndDate,S.MachineID,S.ComponentID,S.OperationNo
		)T
	INNER JOIN #Target Tg ON Tg.StartDate = T.StartDate and Tg.MachineID = T.MachineID and Tg.Comp = T.ComponentID and Tg.Opn = T.OperationNo 
END

ELSE IF ISNULL(@Param,'') ='CycleTime'
BEGIN
UPDATE #Target
	SET MinStdTime = ISNULL(T.MinCycleTime,0) + ISNULL(T.MinStdLoadTime,0),
		AvgMachineTime = T.AvgMachineTime,
		MachiningTime = T.MinCycleTime ,
		LoadUnLoadTime = T.MinStdLoadTime
	FROM 
		(
		SELECT Tg.StartDate,Tg.EndDate,S.MachineID,S.ComponentID,S.OperationNo,MIN(S.CO_StdMachiningTime) MinCycleTime,MIN(S.CO_StdLoadUnload) as MinStdLoadTime,
		CASE WHEN ISNULL(sum(S.Prod_Qty),0) <> 0 
		THEN (sum(S.ActMachiningTime_Type12)/sum(S.Prod_Qty)) 
		END as AvgMachineTime
		FROM ShiftProductionDetails S
		INNER JOIN #Target Tg ON Tg.MachineID = S.MachineID AND Tg.Comp = s.ComponentID AND Tg.Opn = s.OperationNo
		WHERE Convert(NvarChar(10),S.Pdate,120) = Convert(NvarChar(10),Tg.Pdate,120)  AND S.Shift = Tg.ShiftName
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

IF ISNULL(@View,'') = 'Variant'
BEGIN

SELECT * FROM 
	(
	SELECT DISTINCT T.ID,T.Pdate,T.StartDate,T.EndDate,T.ShiftName,T.MachineID,T.Comp,T.Opn,
	 ISNULL(ROUND(T.MinStdTime,2),0) MinStdTime,ISNULL(ROUND(T.MachiningTime,2),0) MachiningTime,ISNULL(ROUND(T.LoadUnLoadTime,2),0) LoadUnLoadTime,ISNULL(ROUND(T.StdTimeDiff,2),0) StdTimeDiff,ISNULL(ROUND(T.AvgMachineTime,2),0) AvgMachineTime 
	 FROM  #Target T
	  WHERE ISNULL(T.MinStdTime,0) NOT IN (SELECT ISNULL(Tg.MinStdTime,0) from #Target Tg 
								 WHERE T.MachineID = Tg.MachineID AND T.Comp = Tg.Comp AND T.Opn = Tg.Opn
								 AND T.ID > Tg.ID AND T.StartDate > Tg.StartDate 
							   )	 
	 ) T1
	 WHERE ISNULL(T1.MinStdTime,0) <> 0 
	 ORDER By MachineId,Comp,Opn,StartDate

END
ELSE
BEGIN

--SELECT @sqlstr = ''
-- SELECT @sqlstr = ' SELECT  DISTINCT Pdate,StartDate,EndDate,MachineID,Comp,Opn,'+@ShiftStr+'
--		FROM  
--		( SELECT T.Pdate,T.StartDate,T.EndDate,T.ShiftName,T.MachineID,T.Comp,T.Opn,
--			 ISNULL(T.MinStdTime,0) MinStdTime,ISNULL(T.StdTimeDiff,0) StdTimeDiff,ISNULL(T.AvgMachineTime,0) AvgMachineTime ,
--			 CAST(T.MinStdTime AS nvarchar(20)) +'''+';'+'''+CAST(T.StdTimeDiff AS nvarchar(20))+'''+';'+'''+CAST(T.AvgMachineTime AS nvarchar(20)) as Value
--			 FROM  #Target T
--		) AS T1  
--		PIVOT  
--		(  
--		MAX(Value)  
--		FOR ShiftName IN ('+@ShiftStr+')  
--		) AS P
--		ORDER By MachineId,Comp,Opn,StartDate '

--	PRINT @sqlstr
--	EXEC (@sqlstr)

SELECT @sqlstr = ''
 SELECT @sqlstr = '  SELECT  DISTINCT Pdate,--StartDate,EndDate,
						MachineID,Comp,Opn,'+@ShiftStr+'
		FROM  
		( SELECT T.Pdate,--T.StartDate,T.EndDate,
		T.ShiftName,T.MachineID,T.Comp,T.Opn,
			 --ISNULL(T.MinStdTime,0) MinStdTime,ISNULL(T.StdTimeDiff,0) StdTimeDiff,ISNULL(T.AvgMachineTime,0) AvgMachineTime ,
			 ROUND(T.MinStdTime,2) as Value
			 FROM  #Target T
		) AS T1  
		PIVOT  
		(  
		MAX(Value)  
		FOR ShiftName IN ('+@ShiftStr+')  
		) AS P
		ORDER By MachineId,Comp,Opn,Pdate '

	PRINT @sqlstr
	EXEC (@sqlstr)

SELECT @sqlstr = ''
 SELECT @sqlstr = '  SELECT  DISTINCT Pdate,--StartDate,EndDate,
						MachineID,Comp,Opn,'+@ShiftStr+'
		FROM  
		( SELECT T.Pdate,--T.StartDate,T.EndDate,
		T.ShiftName,T.MachineID,T.Comp,T.Opn,
			 --ISNULL(T.MinStdTime,0) MinStdTime,ISNULL(T.StdTimeDiff,0) StdTimeDiff,ISNULL(T.AvgMachineTime,0) AvgMachineTime ,
			ROUND(T.StdTimeDiff,2) as Value
			 FROM  #Target T
		) AS T1  
		PIVOT  
		(  
		MAX(Value)  
		FOR ShiftName IN ('+@ShiftStr+')  
		) AS P
		ORDER By MachineId,Comp,Opn,Pdate '

	PRINT @sqlstr
	EXEC (@sqlstr)

SELECT @sqlstr = ''
 SELECT @sqlstr = ' SELECT  DISTINCT Pdate,--StartDate,EndDate,
						MachineID,Comp,Opn,'+@ShiftStr+'
		FROM  
		( SELECT DISTINCT T.Pdate,
		--T.StartDate,T.EndDate,
		T.ShiftName,T.MachineID,T.Comp,T.Opn,
			-- ISNULL(T.MinStdTime,0) MinStdTime,ISNULL(T.StdTimeDiff,0) StdTimeDiff,ISNULL(T.AvgMachineTime,0) AvgMachineTime ,
			 ROUND(T.AvgMachineTime,2) as Value
			 FROM  #Target T
		) AS T1  
		PIVOT  
		(  
		MAX(Value)  
		FOR ShiftName IN ('+@ShiftStr+')  
		) AS P
		ORDER By MachineId,Comp,Opn,Pdate '

	PRINT @sqlstr
	EXEC (@sqlstr)

 
END
 END
