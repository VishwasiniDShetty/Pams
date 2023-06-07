/****** Object:  Procedure [dbo].[s_GetMonthwiseRejectionReport]    Committed by VersionSQL https://www.versionsql.com ******/

/***************************************************************************************
 Procedure Created by Sangeeta Kallur on 14-Sep-2006 :To Get the Monthwise Rejections Report 
 Procedure altered By SSK on 23-Nov-2006 :
 Bz of change in column names of 'ShiftProductionDetails','ShiftDownTimeDetails'

 Procedure Changed By Sangeeta Kallur on 01-Feb-2007
 	To change the calculation of PPM.
	ie From Prod_Qty to AcceptedParts+Reject_Qty_Marked_for_rework
select * from componentinformation
s_GetMonthwiseRejectionReport '2009-12-01','2009-12-02','A','MCV 400','Z200.019   DRIVE SHAFT SA6',''
DR0237 - SwathiKS on 24/Jun/2010 :: To handel 13Type Mismatch Error Operation Number has been changed from int to nvarchar(10)
*******************************************************************************************/
CREATE               PROCEDURE [dbo].[s_GetMonthwiseRejectionReport]

		@StartTime as DateTime,
		@EndTime AS datetime,
		@Shift as Nvarchar(20)='ALL',
		@MachineID as NvarChar(50)='ALL',
	    	@ComponentID AS NvarChar(50)='',
		--@OperationNo AS SmallInt=0, --DR0237 - SwathiKS on 24/Jun/2010
		@OperationNo AS NvarChar(10)='0',
		@PlantID as nvarchar(50)=''
AS
BEGIN


DECLARE @StrSql as NVarChar(4000)
DECLARE @StrMachineID AS Nvarchar(200)
DECLARE @StrComponentID AS NvarChar(200)
DECLARE @StrOperationNo  AS NvarChar(50)
DECLARE @StrShift AS NVarchar(200)
DECLARE @StrPlantID AS NVarchar(200)

SELECT @StrSql=''
SELECT @StrMachineID =''
SELECT @StrComponentID =''
SELECT @StrOperationNo  =''
SELECT @StrShift =''
SET @StrPlantID = ''



IF IsNull(@MachineID,'')<>'ALL'
BEGIN
	SELECT @StrMachineID=' AND machineinformation.Machineid='''+ @MachineID +''''
END

IF IsNull(@ComponentID,'')<>''
BEGIN
	SELECT @StrComponentID=' AND P.ComponentID='''+ @ComponentID +''''
END

IF IsNull(@OperationNo,'')<>''
BEGIN
	SELECT @StrOperationNo=' AND P.OperationNo='+ convert(Nvarchar,@OperationNo)+''
END

IF IsNull(@Shift,'')<>'ALL'
BEGIN
	SELECT @StrShift=' AND P.Shift='''+ @Shift +''''
END

IF IsNull(@PlantID,'')<>''
BEGIN
	SELECT @strPlantID = ' AND  PlantMachine.PlantID = ''' + @PlantID+ ''''
END

Create Table #MonthList
(
SofMonth  DateTime,
EofMonth  DateTime
)
Create Table #MachineNames
(
MachineID  NvarChar(50)
)


	SELECT @StrSql='Insert Into #MachineNames(MachineID) 
			SELECT machineinformation.machineid
			FROM  machineinformation LEFT OUTER JOIN
                        PlantMachine ON machineinformation.machineid = PlantMachine.MachineID Where machineinformation.machineid<>''''' 
	SELECT @StrSql=@StrSql + @StrMachineID + @strPlantID
	EXEC (@StrSql)
	SELECT @StrSql=''

	Declare @TMonth AS DateTime
	Declare @StOfMonth AS DateTime
	Declare @EndOfMonth AS DateTime

	SELECT @TMonth=[dbo].f_GetPhysicalMonth(@StartTime,'Start')
	While @TMonth<=[dbo].f_GetPhysicalMonth(@EndTime,'End')
	BEGIN

		SELECT @StOfMonth=[dbo].f_GetPhysicalMonth(@TMonth,'Start')
		SELECT @EndOfMonth=[dbo].f_GetPhysicalMonth(@TMonth,'End')
		Insert Into #MonthList(SofMonth,EofMonth)Values(@StOfMonth,@EndOfMonth)
		SELECT @TMonth=Dateadd(Month,1,@TMonth)
	END


	CREATE TABLE #MonthlyRejections
		(
		SofMonth DateTime,
		EofMonth DateTime,
		MachineID NvarChar(50),
		ProdQty Int,
		RejQty Int,
		PPM Int
		)
		Insert Into #MonthlyRejections(SofMonth,EofMonth,MachineID,ProdQty,RejQty,PPM)
		SELECT SofMonth,EofMonth,MachineID,0,0,0 From #MonthList Cross Join #MachineNames Order By MachineID,SofMonth
		
		--ProdQty=AcceptedParts+Marked_for_rework+Rejections		
		SELECT @StrSql='Update #MonthlyRejections SET ProdQty=ISNULL(T1.PQty,0)'
		SELECT @StrSql=@StrSql + ' From('
		SELECT @StrSql=@StrSql + ' Select P.MachineID AS MachineID ,T2.StTime As SOfMonth ,T2.EndTime As EOfMonth,(Sum(P.AcceptedParts)+ Sum(Marked_for_rework))AS PQty'
		SELECT @StrSql=@StrSql + ' From ShiftProductionDetails P'
		SELECT @StrSql=@StrSql + ' Inner Join (Select SofMonth AS StTime ,EofMonth AS EndTime,MachineID From #MonthlyRejections)AS T2 ON P.MachineID=T2.MachineID'
		SELECT @StrSql=@StrSql + ' Where P.MachineID=T2.MachineID AND P.pDate>=T2.StTime AND P.pDate<=T2.EndTime'
		SELECT @StrSql=@StrSql + @StrShift + @StrComponentID + @StrOperationNo
		SELECT @StrSql=@StrSql + ' Group By P.MachineID,T2.StTime,T2.EndTime'
		SELECT @StrSql=@StrSql + ' )AS T1 Inner Join #MonthlyRejections M ON T1.MachineID=M.MachineID AND T1.SOfMonth=M.SofMonth AND T1.EOfMonth=M.EOfMonth'
		Exec(@StrSql)
		
		SELECT @StrSql='Update #MonthlyRejections SET RejQty=ISNULL(T1.RQty,0)'
		SELECT @StrSql=@StrSql + ' From('
		SELECT @StrSql=@StrSql + ' Select P.MachineID AS MachineID ,T2.StTime As SOfMonth ,T2.EndTime As EOfMonth,Sum(ISNULL(R.Rejection_Qty,0)) as RQty'
		SELECT @StrSql=@StrSql + ' From ShiftProductionDetails P Left Outer Join ShiftRejectionDetails R ON P.ID=R.ID '
		SELECT @StrSql=@StrSql + ' Inner Join (Select SofMonth AS StTime ,EofMonth AS EndTime,MachineID From #MonthlyRejections)AS T2 ON P.MachineID=T2.MachineID'
		SELECT @StrSql=@StrSql + ' Where P.MachineID=T2.MachineID AND P.pDate>=T2.StTime AND P.pDate<=T2.EndTime'
		SELECT @StrSql=@StrSql + @StrShift + @StrComponentID + @StrOperationNo
		SELECT @StrSql=@StrSql + ' Group By P.MachineID,T2.StTime,T2.EndTime'
		SELECT @StrSql=@StrSql + ' )AS T1 Inner Join #MonthlyRejections M ON T1.MachineID=M.MachineID AND T1.SOfMonth=M.SofMonth AND T1.EOfMonth=M.EOfMonth'
		Exec(@StrSql)

 		Update #MonthlyRejections Set PPM =( (RejQty * 1000000)/(ISNULL(ProdQty,0)+ISNULL(RejQty,0)) ) 
		Where ProdQty<>0

		SELECT #MonthList.SofMonth ,
		#MonthList.EofMonth ,
		MachineID ,
		ProdQty + RejQty AS ProdQty,
		RejQty , 
	    	PPM 
		FROM #MonthlyRejections Right Outer Join #MonthList On #MonthlyRejections.SofMonth=#MonthList.SofMonth And #MonthlyRejections.EofMonth=#MonthList.EofMonth
			
END
