/****** Object:  Procedure [dbo].[S_GetProcessControlMovingRangeChart]    Committed by VersionSQL https://www.versionsql.com ******/

/*
-- Author:	SwathiKS
-- Create date: 10 December 2019
-- Description:	Process Control Moving Range Chart
-- [S_GetProcessControlMovingRangeChart] 'Diameter','POSITION OF BORE  13 WRT ORIGIN','Circle:CIR_DIA13_RH_BOTTOM','Overall'
-- [S_GetProcessControlMovingRangeChart] 'Flatness','SR NO 78','PLN_D'

[S_GetProcessControlMovingRangeChart] 'SPC-1','1','SAMPLE COMP','1'
[S_GetProcessControlMovingRangeChart] 'SPC-2','1','SAMPLE COMP','1'

exec S_GetProcessControlMovingRangeChart @machine=N'CNC-112',@Dimension=N'C01',@Component=N'RETAINER SEAT',@Operation=N'70',@Param=N'Overall'

*/
CREATE PROCEDURE [dbo].[S_GetProcessControlMovingRangeChart]
    @machine nvarchar(50),
	@Dimension nvarchar(50),
	@Component nvarchar(50),
	@Operation nvarchar(50),
	@StartDate datetime,
	@EndDate datetime,
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
MeasuredValue float,
IgnoreForCPCPK bit,
Remarks nvarchar(50)
)

--INSERT INTO #Target (id,Component,Dimension,Operation,BatchTs,LSL,USL,Mean,MeasuredValue,Value)
--select  Row_Number() OVER (Order by A.Comp, A.BatchTS desc) as RowNumber, A.Comp, A.Dimension, A.Opn, A.BatchTS, S.LSL,S.USL,0,cast(A.Value as float),0 from SPCAutodata A
--inner join SPC_Characteristic S on A.Comp=S.ComponentID and A.Opn=S.OperationNo and A.Dimension=S.CharacteristicCode
--where Dimension =@Dimension and Comp = @Component and Opn = @Operation

if  ((select ValueInText FROM ShopDefaults WHERE Parameter = 'SPCCompOpnSet') = 'SPCMaster')
BEGIN
	INSERT INTO #Target (id,Component,Dimension,Operation,BatchTs,LSL,USL,Mean,MeasuredValue,Value,IgnoreForCPCPK,Remarks)
	select  Row_Number() OVER (Order by A.Comp, A.BatchTS desc) as RowNumber, A.Comp, A.Dimension, A.Opn, A.BatchTS, SP.LSL,SP.USL,0,cast(A.Value as float),0 ,A.IgnoreForCPCPK,a.Remarks
	from SPCAutodata A
	inner join machineinformation M on M.interfaceid=A.mc
	inner join Componentinformation CI on CI.interfaceid=A.comp
	inner join SPC_Characteristic SP on M.machineid=SP.machineid 
			and CI.Componentid=SP.Componentid
			and A.opn=SP.operationno and A.Dimension=SP.CharacteristicID
	where  SP.componentid=@Component and 
	SP.operationno=@Operation and SP.CharacteristicCode=@Dimension and (Batchts >=@StartDate and BatchTS<=@EndDate)
	and M.machineid=@machine
END
ELSE 
BEGIN
	INSERT INTO #Target (id,Component,Dimension,Operation,BatchTs,LSL,USL,Mean,MeasuredValue,Value,IgnoreForCPCPK,Remarks)
	select  Row_Number() OVER (Order by A.Comp, A.BatchTS desc) as RowNumber, A.Comp, A.Dimension, A.Opn, A.BatchTS, SP.LSL,SP.USL,0,cast(A.Value as float),0 ,A.IgnoreForCPCPK,a.Remarks
	from SPCAutodata A
	inner join machineinformation M on M.interfaceid=A.mc
	inner join Componentinformation CI on CI.interfaceid=A.comp
	inner join Componentoperationpricing CO on CO.interfaceid=A.opn and 
			CO.machineid=M.machineid and CO.componentid=CI.Componentid
	inner join SPC_Characteristic SP on M.machineid=SP.machineid 
			and CI.Componentid=SP.Componentid
			and A.opn=SP.operationno and A.Dimension=SP.CharacteristicID
	where  SP.componentid=@Component and 
	SP.operationno=@Operation and SP.CharacteristicCode=@Dimension and (Batchts >=@StartDate and BatchTS<=@EndDate)
	and M.machineid=@machine
END






UPDATE #Target 
SET Mean = (T.Value/T.BatchCount) 
	FROM (SELECT Comp,COUNT(BatchTS) BatchCount,SUM(Value) Value from SPCAutodata 
		  where Dimension =@Dimension 
				and Comp = @Component 
				and Opn = @Operation
		 GROUP BY Comp ) T INNER JOIN #Target tg ON T.Comp = Tg.Component

UPDATE #Target SET Value = T.VALUE FROM 
( 
SELECT  a.id,a.Component ,A.BatchTs , (b.MeasuredValue - a.MeasuredValue) AS Value
FROM #Target a JOIN #Target b ON b.id = a.id - 1 and a.Component = B.Component 
) T INNER JOIN #Target tg ON T.Component = Tg.Component and T.BatchTs = Tg.BatchTs and T.id = Tg.id


IF @Param = 'Overall'
BEGIN
	SELECT ID,
	 Component,Dimension,Operation,BatchTs,LSL,USL,Mean,abs(Value) as Value,MeasuredValue,IgnoreForCPCPK,Remarks
	 from #Target 
	 Order by BatchTs Desc
END
ELSE
BEGIN
	select T.* from 
	(
	 SELECT Top 30 ID,
	 Component,Dimension,Operation,BatchTs,LSL,USL,Mean,abs(Value) as Value,MeasuredValue,IgnoreForCPCPK,Remarks
	 from #Target 
	 Order by BatchTs Desc
	 )T
	  Order by ID
  END
END
