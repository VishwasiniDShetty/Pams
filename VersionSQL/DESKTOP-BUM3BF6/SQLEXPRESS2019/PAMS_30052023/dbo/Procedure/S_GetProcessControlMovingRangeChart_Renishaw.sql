/****** Object:  Procedure [dbo].[S_GetProcessControlMovingRangeChart_Renishaw]    Committed by VersionSQL https://www.versionsql.com ******/

/***************************************************************************************************
-- Author:	SwathiKS
-- Create date: 10 December 2019
-- Description:	Process Control Moving Range Chart
-- [S_GetProcessControlMovingRangeChart_Renishaw] 'Diameter','POSITION OF BORE  13 WRT ORIGIN','Circle:CIR_DIA13_RH_BOTTOM','Overall'
-- [S_GetProcessControlMovingRangeChart_Renishaw] 'Flatness','SR NO 78','PLN_D'
[S_GetProcessControlMovingRangeChart_Renishaw] '2019-12-19 16:25:46.000','2019-12-25 16:25:46.000','','Perpendicularity_0_05_WRT_C_M1','35','110',''
**************************************************************************************************/
CREATE PROCEDURE [dbo].[S_GetProcessControlMovingRangeChart_Renishaw]
	@StartDate datetime='',
	@EndDate datetime='',
    @machine nvarchar(50)='',
	@Dimension nvarchar(50)='',
	@Component nvarchar(50)='',
	@Operation nvarchar(50)='',
	@Param nvarchar(50)	 = ''
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

CREATE TABLE #Target
(
id int,
Component nvarchar(50),
Operation nvarchar(50),
Dimension nvarchar(50),
BatchTs datetime,
LSL float,
USL float,
Mean float,
Value float,
MeasuredValue float
)

INSERT INTO #Target (id,Component,Dimension,Operation,BatchTs,LSL,USL,Mean,MeasuredValue,Value)
select  Row_Number() OVER (Order by A.Comp, A.BatchTS desc) as RowNumber, A.Comp, A.Dimension, A.Opn, A.BatchTS, S.LSL,S.USL,0,cast(A.Value as float),0 from SPCAutodata A
inner join SPC_Characteristic S on A.Comp=S.ComponentID and A.Opn=S.OperationNo and A.Dimension=S.CharacteristicCode
where  Dimension =@Dimension and Comp = @Component and Opn = @Operation
and (A.Timestamp between @StartDate and @EndDate)

UPDATE #Target 
SET Mean = (T.Value/T.BatchCount) 
	FROM (SELECT Comp,COUNT(BatchTS) BatchCount,SUM(Value) Value from SPCAutodata 
		  where Dimension =@Dimension 
				and Comp = @Component 
				and Opn = @Operation
				and (Timestamp between @StartDate and @EndDate)
		 GROUP BY Comp ) T INNER JOIN #Target tg ON T.Comp = Tg.Component

UPDATE #Target SET Value = T.VALUE FROM 
( 
SELECT  a.id,a.Component ,A.BatchTs , (b.MeasuredValue - a.MeasuredValue) AS Value
FROM #Target a JOIN #Target b ON b.id = a.id - 1 and a.Component = B.Component 
) T INNER JOIN #Target tg ON T.Component = Tg.Component and T.BatchTs = Tg.BatchTs and T.id = Tg.id


IF @Param = 'Overall'
BEGIN
	SELECT ID,
	 Component,Dimension,Operation,BatchTs,LSL,USL,Mean,abs(Value) as Value,MeasuredValue
	 from #Target 
	 Order by BatchTs Desc
END
ELSE
BEGIN
	select T.* from 
	(
	 SELECT Top 30 ID,
	 Component,Dimension,Operation,BatchTs,LSL,USL,Mean,abs(Value) as Value,MeasuredValue
	 from #Target 
	 Order by BatchTs Desc
	 )T
	  Order by ID
  END
END
