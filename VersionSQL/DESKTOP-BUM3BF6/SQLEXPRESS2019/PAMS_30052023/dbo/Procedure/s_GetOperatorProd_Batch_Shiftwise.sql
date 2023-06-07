/****** Object:  Procedure [dbo].[s_GetOperatorProd_Batch_Shiftwise]    Committed by VersionSQL https://www.versionsql.com ******/

/****************************************************************************************
										 	*
-- Author  : Sangeeta Kallur							 	*
-- Date    : 08-FEB-2006							 	*
-- Comments: To get shiftwise Operator Performance 				 	*
--	     Raised by Auto Axle						 	*
	     --This is Outer Procedure to get OperatorProd_Batch_Shiftwise	 	*
	     --Evn this is used as OuterProcedure to get JobCard Report		 	*
Procedure Altered By SSK on 07-Oct-2006 to include Plant Concept		 	*

By Sangeeta Kallur
	As of now ,#Tmp.Flag is used to know number of records existing for that 
	operator in that time period.Here "Count ie number of records" we are using
	for only above mentioned purpose.So,that is why this pricedure is not changed for 
	MAINI-MultiSpindle Logic.In case of any other use of "Count",than this procedure 
	need to be chnaged for MultiSpindle Logic.
Procedur altered by shm for DR0108:Used distinct keyword while select statement
mod 1 :- ER0182 By Kusuma M.H on 13-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
***********************************************************************************/

CREATE        PROCEDURE [dbo].[s_GetOperatorProd_Batch_Shiftwise]
	@StartDate  AS dateTIME,
	@EndDate AS datetime,
	@ShiftName  AS nvarchar(20)='',
	@Operator AS nvarchar(50)= '',
	@Machine  AS nvarchar(50)= '',
	@PlantID AS nvarchar(50)= ''
	
AS
BEGIN
--Create table to get Shift Details/Definition
	CREATE TABLE #ShiftDefn(
		ShiftDate  DateTime,		
		Shiftname   nvarchar(20),
		ShftSTtime  DateTime,
		ShftEndTime  DateTime	
	)
	CREATE TABLE #Operator(
		Operator nvarchar(50)
	)
	CREATE TABLE #Tmp(
		Shiftname   nvarchar(20),
		ShftSTtime  DateTime,
		ShftEndTime  DateTime,
		Operator nvarchar(50),
		Flag  Integer
	)	
DECLARE @Count as INTEGER
DECLARE @CurDate as DateTime
DECLARE @NxtDate as DateTime
DECLARE @OperatorLbl AS nvarchar(50)
DECLARE @MachineLbl AS nvarchar(50)
DECLARE @TmpStDate as DATETIME
DECLARE @TmpEndDate as DATETIME

DECLARE @StrSql AS NVarChar(4000)
DECLARE @StrEPlant AS NVarChar(4000)
DECLARE @StrMPlant AS NVarChar(4000)
DECLARE @StrMachine AS NVarChar(4000)
DECLARE @StrOpr AS NVarChar(4000)

SELECT @StrSql=''
SELECT @StrEPlant=''
SELECT @StrMPlant=''
SELECT @StrMachine=''
SELECT @StrOpr=''

IF ISNULL(@Machine,'')<>''
BEGIN
	---mod 1
--	SELECT @StrMachine=' and M.Machineid='''+ @Machine +''''
	SELECT @StrMachine=' and M.Machineid= N'''+ @Machine +''''
	---mod 1
END
IF ISNULL(@Operator,'')<>''
BEGIN
	---mod 1
--	SELECT @StrOpr='  E.Employeeid='''+ @Operator +''''
	SELECT @StrOpr='  E.Employeeid= N'''+ @Operator +''''
	---mod 1
END
IF ISNULL(@PlantID,'')<>''
BEGIN
	---mod 1
--	SELECT @StrEPlant=' and PE.PlantID='''+ @PlantID +''''
	SELECT @StrEPlant=' and PE.PlantID= N'''+ @PlantID +''''
	---mod 1
END
IF ISNULL(@PlantID,'')<>''
BEGIN
	---mod 1
--	SELECT @StrMPlant=' and PM.PlantID='''+ @PlantID +''''
	SELECT @StrMPlant=' and PM.PlantID= N'''+ @PlantID +''''
	---mod 1
END

SET @CurDate=@StartDate
WHILE @CurDate < @EndDate
BEGIN
		INSERT INTO #ShiftDefn(ShiftDate,Shiftname,ShftSTtime,ShftEndTime)  
		Exec s_GetShiftTime @CurDate,@ShiftName
		
		SET @CurDate=DATEADD(DAY,1,@CurDate)
END

SELECT @TmpStDate=ShftSTtime FROM #ShiftDefn WHERE ShiftDate=@StartDate ORDER BY ShftSTtime DESC
SELECT @TmpEndDate =ShftEndTime FROM #ShiftDefn

IF  isnull(@Operator,'')<> ''
BEGIN
	SELECT @StrSql='INSERT INTO #Operator(Operator)'
	SELECT @StrSql=@StrSql+' SELECT E.Employeeid FROM EmployeeInformation E '
	SELECT @StrSql=@StrSql+' Left Outer Join PlantEmployee PE ON PE.Employeeid =E.Employeeid Where '
	SELECT @StrSql=@StrSql+ @StrOpr+ @StrEPlant

	exec(@StrSql)
	SET @OperatorLbl=@Operator
END
ELSE
BEGIN
IF isnull(@Machine,'')<>''
BEGIN
	SELECT @StrSql='INSERT INTO #Operator(Operator)'
	SELECT @StrSql=@StrSql+' SELECT distinct E.Employeeid FROM EmployeeInformation E '
	SELECT @StrSql=@StrSql+' inner join Autodata A on E.interfaceid=A.opr'
	SELECT @StrSql=@StrSql+' INNER JOIN MachineInformation M on A.mc=M.Interfaceid'
	SELECT @StrSql=@StrSql+' Left Outer Join PlantMachine PM ON  M.MachineID=PM.MachineID'
	SELECT @StrSql=@StrSql+' Left Outer Join PlantEmployee Pe ON E.Employeeid=PE.Employeeid'
	SELECT @StrSql=@StrSql+' WHERE A.sttime>='''+Convert(NVarChar(20),@TmpStDate)+''' and A.ndtime<='''+Convert(NVarChar(20),@TmpEndDate)+''' '
	SELECT @StrSql=@StrSql + @StrMPlant + @StrMachine
	SET @MachineLbl=@Machine

END	
ELSE
BEGIN
	SELECT @StrSql='INSERT INTO #Operator(Operator)'
	SELECT @StrSql=@StrSql+' SELECT distinct E.Employeeid FROM EmployeeInformation E '
	SELECT @StrSql=@StrSql+' inner join Autodata A on E.interfaceid=A.opr'
	SELECT @StrSql=@StrSql+' INNER JOIN MachineInformation M on A.mc=M.Interfaceid'
	SELECT @StrSql=@StrSql+' Left Outer Join PlantMachine PM ON  M.MachineID=PM.MachineID'
	SELECT @StrSql=@StrSql+' Left Outer Join PlantEmployee Pe ON E.Employeeid=PE.Employeeid'
	SELECT @StrSql=@StrSql+' WHERE A.sttime>='''+Convert(NVarChar(20),@TmpStDate)+''' and A.ndtime<='''+Convert(NVarChar(20),@TmpEndDate)+''' '
	SELECT @StrSql=@StrSql + @StrEPlant
	SET @MachineLbl='ALL'
END
	exec(@StrSql)
	SET @OperatorLbl='ALL'
END

	
	INSERT INTO #Tmp(Operator,Shiftname,ShftSTtime,ShftEndTime )
	SELECT Operator,Shiftname,ShftSTtime,ShftEndTime 
	FROM #ShiftDefn,#Operator 
	Order  By Operator,ShftSTtime,Shiftname,ShftEndTime

Declare TmpCursor  Cursor For SELECT Operator,ShftSTtime,ShftEndTime FROM #Tmp
Declare @CurOpr as Nvarchar(50)
Declare @CurShftSTtime as DATETIME
Declare @CurShftEndTime as DATETIME

OPEN TmpCursor
FETCH NEXT FROM TmpCursor INTO @CurOpr,@CurShftSTtime,@CurShftEndTime
	WHILE @@FETCH_STATUS = 0
	BEGIN		
		SET @Count=0
		--'''SELECT @Count=Count(*)FROM AutoData inner join EmployeeInformation on AutoData.opr=EmployeeInformation.interfaceid
		SELECT @Count=isnull(sum(autodata.partscount),0)FROM AutoData inner join EmployeeInformation on AutoData.opr=EmployeeInformation.interfaceid
		Where 	EmployeeInformation.employeeid=@CurOpr AND ndtime>=@CurShftSTtime AND ndTime<=@CurShftEndTime
		IF @Count >= 0 
		BEGIN
			UPDATE #Tmp SET Flag=@Count Where Operator=@CurOpr and ShftSTtime= @CurShftSTtime
		END
		FETCH NEXT FROM TmpCursor INTO @CurOpr,@CurShftSTtime,@CurShftEndTime
	END

Select @OperatorLbl as OprLbl,@MachineLbl AS MchLbl,* from #Tmp
DEALLOCATE TmpCursor
END
