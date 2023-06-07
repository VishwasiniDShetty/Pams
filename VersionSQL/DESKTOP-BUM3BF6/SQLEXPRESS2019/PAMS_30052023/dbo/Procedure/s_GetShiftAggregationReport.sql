/****** Object:  Procedure [dbo].[s_GetShiftAggregationReport]    Committed by VersionSQL https://www.versionsql.com ******/

/**************************************************************************************
Procedure Created by Sangeeta Kallur on 28-Apr-2006 : To Get the rejections for a shift
Procedure altered by Sangeeta Kallur on 23-Nov-2006 :
	Bz of change in column names of 'ShiftProductionDetails','ShiftProductionDetails' tables
Procedure Changed By Sangeeta Kallur on 01-Feb-2007
	To Change the PPM Calculation , To get Accepted Qty as OutPut
		ie instead of taking 'Prod_Qty'in the calculation( which is nothing but Cycles)
		we should take AcceptedQty+RejectedQty+Marked_for_Rework in the calculation
		
Procedure Changed By SSK On 05-Feb-2007
	To get Rejection Category and Operator Name as OutPut.
mod 1 :- ER0182 By Kusuma M.H on 28-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
Note:For ER0181 No component operation qualification found.
ER0229 - 19/May/2010 - KarthikG :: Increase the size of operation number business id from 4 to 8.
DR0237 - SwathiKS on 24/Jun/2010 :: To handel 13Type Mismatch Error Operation Number has been changed from int to nvarchar(10)
s_GetShiftAggregationReport '01-dec-2009','A','mcv 400','Z200.019   DRIVE SHAFT SA6','100011','date','shiftwise',''
s_GetShiftAggregationReport '01-dec-2009','A','mcv 400','Z200.019   DRIVE SHAFT SA6','date','shiftwise',''
*******************************************************************************************/
--s_GetShiftAggregationReport '01-dec-2009','A','A55','','date','shiftwise',''
CREATE                                      PROCEDURE [dbo].[s_GetShiftAggregationReport]
	@Date as DateTime,
	@Shift as Nvarchar(20)='ALL',
	@MachineID as NvarChar(50)='ALL',
	@ComponentID AS NvarChar(50)='',
	--@OperationNo AS SmallInt=NULL,
	--@OperationNo AS Int=NULL, --DR0237 - SwathiKS on 24/Jun/2010 
	@OperationNo AS Nvarchar(10)='',
	@Param AS Nvarchar(50)='Date', --Parameter to Specify Month/Date
	@Type AS Nvarchar(50),          --Report Type
	@PlantID nvarchar(50)=''
		
AS
BEGIN

CREATE TABLE #Tmp(
	PDate DateTime
	)
CREATE TABLE #TmpPR(
		PRDate DateTime,
		Shift Nvarchar(20),
		P_Qty Int,
		Sum_Of_PQty Int,
		SumPQty_ForMonth Int,
		R_Qty Int,
		Sum_Of_RQty Int,
		R_Reason Nvarchar(100),
		PPM Int,
		SumPPM_ForMonth Int,
		DefectRation Int
		)

DECLARE @StartTime AS datetime
DECLARE @EndTime AS datetime
SELECT @StartTime = dbo.f_GetPhysicalMonth(@Date,'Start')
SELECT @EndTime = dbo.f_GetPhysicalMonth(@Date,'End')
DECLARE @StrSql as NVarChar(4000)
DECLARE @StrMachineID AS Nvarchar(250)
DECLARE @StrComponentID AS NvarChar(250)
DECLARE @StrOperationNo  AS NvarChar(150)
DECLARE @StrShift AS NVarchar(250)
DECLARE @StrPlantID AS NVarchar(250)
SELECT @StrSql=''
SELECT @StrMachineID =''
SELECT @StrComponentID =''
SELECT @StrOperationNo  =''
SELECT @StrShift =''
SELECT @StrPlantID = ''
IF IsNull(@MachineID,'')<>'ALL'
BEGIN
	---mod 1
--	SELECT @StrMachineID=' AND SPD.Machineid='''+ @MachineID +''''
	SELECT @StrMachineID=' AND SPD.Machineid= N'''+ @MachineID +''''
	---mod 1
END
IF IsNull(@ComponentID,'')<>''
BEGIN
	---mod 1
--	SELECT @StrComponentID=' AND SPD.ComponentID='''+ @ComponentID +''''
	SELECT @StrComponentID=' AND SPD.ComponentID= N'''+ @ComponentID +''''
	---mod 1
END
IF IsNull(@OperationNo,'')<>''
BEGIN
	---mod 1
--	SELECT @StrOperationNo=' AND SPD.OperationNo='+ convert(Nvarchar,@OperationNo)+''
	SELECT @StrOperationNo=' AND SPD.OperationNo=N'''+ convert(Nvarchar,@OperationNo)+''''
	---mod 1
END
IF IsNull(@Shift,'')<>'ALL'
BEGIN
	---mod 1
--	SELECT @StrShift=' AND SPD.Shift='''+ @Shift +''''
	SELECT @StrShift=' AND SPD.Shift= N'''+ @Shift +''''
	---mod 1
END
IF IsNull(@PlantID,'')<>''
BEGIN
	---mod 1
--	SELECT @strPlantID = ' AND  PlantMachine.PlantID = ''' + @PlantID+ ''''
	SELECT @strPlantID = ' AND  PlantMachine.PlantID = N''' + @PlantID+ ''''
	---mod 1
END
IF @Type='ShiftWise'
BEGIN
	SELECT @StrSql='Select SPD.Shift,SPD.MachineID,SPD.ComponentID,SPD.OperationNo,SPD.OperatorID,Prod_Qty,AcceptedParts,Marked_for_Rework,RejectionCodeInformation.Catagory,R.Rejection_Reason,R.Rejection_Qty'
	SELECT @StrSql=@StrSql+ ' From ShiftProductionDetails SPD Left Outer Join ShiftRejectionDetails R ON SPD.ID=R.ID Inner Join RejectionCodeInformation ON R.Rejection_Reason=RejectionCodeInformation.RejectionId'
	SELECT @StrSql=@StrSql+ ' LEFT OUTER JOIN PlantMachine ON SPD.machineid = PlantMachine.MachineID '
	SELECT @StrSql=@StrSql+ ' WHERE SPD.pDate='''+ Convert(Nvarchar(20),@Date)+''''
	SELECT @StrSql=@StrSql + @StrMachineID + @StrShift + @StrPlantID
	SELECT @StrSql=@StrSql +' Order By Shift,Catagory,SPD.MachineID,SPD.ComponentID,SPD.OperationNo,SPD.OperatorID'
	EXEC (@StrSql)
print @StrSql
END

IF @Type='WrtCO'
BEGIN
	IF @Param='Date'
	BEGIN
		SELECT @StrSql='Select Shift,SPD.MachineID,ComponentID,OperationNo,OperatorID,Prod_Qty,AcceptedParts,Marked_for_Rework,RejectionCodeInformation.Catagory,R.Rejection_Reason,R.Rejection_Qty'
		SELECT @StrSql=@StrSql+ ' From ShiftProductionDetails SPD Left Outer Join ShiftRejectionDetails R ON SPD.ID=R.ID Inner Join RejectionCodeInformation ON R.Rejection_Reason=RejectionCodeInformation.RejectionId'
		SELECT @StrSql=@StrSql+ ' LEFT OUTER JOIN PlantMachine ON SPD.machineid = PlantMachine.MachineID '
		SELECT @StrSql=@StrSql+ ' WHERE SPD.pDate='''+ Convert(Nvarchar(20),@Date)+''''
		SELECT @StrSql=@StrSql +  @StrShift + @StrMachineID +@StrComponentID +  @StrOperationNo +   @StrPlantID
		SELECT @StrSql=@StrSql +' Order By Shift,Catagory,SPD.MachineID,SPD.ComponentID,SPD.OperationNo,SPD.OperatorID'
		EXEC (@StrSql)
		print @StrSql

	END

	ELSE
	BEGIN
		
		
		DECLARE @ProdVal AS INT
		DECLARE @RejVal AS INT
		DECLARE @PPMVal AS INT
		DECLARE @MonthSumPQty AS INT
		DECLARE @MonthSumPPM AS INT
		DECLARE @MonthSumRQty AS INT
		DECLARE @TmpDate AS DATETIME
		SELECT @TmpDate=@StartTime
		While(@TmpDate<=@EndTime)
		BEGIN
			INSERT INTO #Tmp(PDate)VALUES(@TmpDate)
			SELECT @TmpDate=@TmpDate+1
		END
		
		SET @MonthSumPQty=0
		SET @MonthSumPPM=0
		SET @MonthSumRQty=0
		SELECT @TmpDate=@StartTime
		While(@TmpDate<=@EndTime)
		BEGIN
			SELECT @StrSql='Insert Into #TmpPR(PRDate,Shift,P_Qty,R_Qty,R_Reason)'
			SELECT @StrSql=@StrSql+' Select pdate,shift,AcceptedParts+Marked_for_Rework,rejection_qty,rejection_reason'
			SELECT @StrSql=@StrSql+' From shiftproductiondetails SPD  LEFT OUTER JOIN shiftrejectiondetails '
			SELECT @StrSql=@StrSql+' ON SPD.ID=shiftrejectiondetails.ID
						LEFT OUTER JOIN PlantMachine ON SPD.machineid = PlantMachine.MachineID
						WHERE SPD.pdate='''+Convert(Nvarchar(20),@TmpDate)+ ''''
			SELECT @StrSql=@StrSql+ @StrMachineID + @StrComponentID +  @StrOperationNo +  @StrPlantID
			EXEC(@StrSql)
			
			SELECT @StrSql='UPDATE #TmpPR SET Sum_Of_PQty=ISNULL(T1.PQty,0)From
			(SELECT pDate,(SUM(ISNULL(AcceptedParts,0))+Sum(ISNULL(Marked_for_Rework,0))) As PQty  FROM  ShiftProductionDetails SPD LEFT OUTER JOIN PlantMachine ON SPD.machineid = PlantMachine.MachineID
			WHERE pDate='''+Convert(Nvarchar(20),@TmpDate)+ ''' AND Componentid='''+@Componentid+''' AND Operationno='''+Convert(Nvarchar(8),@Operationno)+ ''''
			SELECT @StrSql=@StrSql+@StrMachineID+@StrPlantID
			SELECT @StrSql=@StrSql+'Group By pdate)AS T1 INNER JOIN #TmpPR ON T1.pDate=#TmpPR.PRDate '
			EXEC(@StrSql)
			UPDATE #TmpPR SET Sum_Of_RQty=ISNULL(T1.RQty,0)From
			(SELECT PRDATE,SUM(R_Qty)RQty FROM #TmpPR
			WHERE PRDate=@TmpDate Group By PRDATE)AS T1 INNER JOIN #TmpPR ON T1.PRDATE=#TmpPR.PRDate
			
			SET @ProdVal=(SELECT TOP 1 Sum_Of_PQty FROM #TmpPR WHERE PRDate=@TmpDate)
			SET @RejVal=(SELECT TOP 1 Sum_Of_RQty FROM #TmpPR WHERE PRDate=@TmpDate)
			SET @ProdVal=ISNULL(@ProdVal,0)+ISNULL(@RejVal,0)
			IF @ProdVal<>0
			BEGIN
				SELECT @PPMVal=(1000000 * ISNULL(@RejVal,0))/ISNULL(@ProdVal,0)
			END
			SELECT @MonthSumPQty=@MonthSumPQty +ISNULL( @ProdVal,0)
			SELECT @MonthSumPPM=@MonthSumPPM + ISNULL(@PPMVal,0)
			SELECT @MonthSumRQty=@MonthSumRQty+ISNULL(@RejVal,0)
			
			
			UPDATE #TmpPR SET PPM=@PPMVal WHERE PRDate=@TmpDate
			SELECT @TmpDate=@TmpDate+1
			SELECT @ProdVal=0
			SELECT @RejVal=0
			SELECT @PPMVal=0
			
		END
		Update #TmpPR SET SumPQty_ForMonth=ISNULL(@MonthSumPQty,0)
		Update #TmpPR SET SumPPM_ForMonth=ISNULL(@MonthSumPPM,0)
		IF @MonthSumPQty<>0
		BEGIN
			Update #TmpPR SET DefectRation=(isnull(@MonthSumRQty,0)*1000000)/ISNULL(@MonthSumPQty,0)
		END

		--Update #TmpPR SET SumPQty_ForMonth=ISNULL(T1.PSum,0)From(
		--SELECT PRDATE,SUM(Sum_Of_PQty)AS PSum FROM #TmpPR Group By PRDATE )as T1
		Select PDate,Shift,P_Qty,Sum_Of_PQty+Sum_Of_RQty AS Sum_Of_PQty,SumPQty_ForMonth,R_Qty,Sum_Of_RQty,R_Reason,PPM,SumPPM_ForMonth,DefectRation From #Tmp Left Outer Join #TmpPR On #TmpPR.PRDate=#Tmp.PDate
		

		/*SELECT @TmpDate=@StartTime
		While(@TmpDate<=@EndTime)
		BEGIN
			UPDATE #Tmp SET P_Qty=ISNULL(T1.Prod_Qty,0),R_Qty=ISNULL(T1.Rej_Qty,0)--,R_Reason=ISNULL(T1.Rej_Reason,'')
			FROM(SELECT DATE,SUM(Prod_Qty)Prod_Qty ,SUM(Rejection_Qty)Rej_Qty  FROM  ShiftProductionDetails
			LEFT OUTER JOIN ShiftRejectionDetails ON ShiftProductionDetails.ID=ShiftRejectionDetails.ID
			WHERE
			Date=@TmpDate AND componentid=@componentid AND operationno=@operationno Group By Date)AS T1 INNER JOIN #Tmp ON T1.Date=#Tmp.PDate
			SELECT @TmpDate=@TmpDate+1
		END*/
		/*SELECT @StrSql='Select Date,Shift,sum(Prod_Qty)as Prod_Qty,Rejection_Reason,sum(Rejection_Qty) AS Rejection_Qty'
		SELECT @StrSql=@StrSql+ ' From ShiftProductionDetails Left Outer Join ShiftRejectionDetails ON'
		SELECT @StrSql=@StrSql+ ' ShiftProductionDetails.ID=ShiftRejectionDetails.ID'
		SELECT @StrSql=@StrSql+ ' WHERE ShiftProductionDetails.Date>='''+ Convert(Nvarchar(20),@StartTime)+''' AND ShiftProductionDetails.Date<='''+ Convert(Nvarchar(20),@EndTime)+''' '
		SELECT @StrSql=@StrSql +  @StrShift + @StrComponentID +  @StrOperationNo
		SELECT @StrSql=@StrSql +' Group By Date,Shift,Rejection_Reason'--ComponentID,OperationNo,Rejection_Reason'
		SELECT @StrSql=@StrSql +' Order By Date'*/
	END		
END
END
