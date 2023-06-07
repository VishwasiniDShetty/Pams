/****** Object:  Procedure [dbo].[s_GetShiftAgg_ComparisonReports_Graphs]    Committed by VersionSQL https://www.versionsql.com ******/

/**************************************** -- HISTORY -- ******************************************
Procedure Created By Sangeeta Kallur on 27-Nov-2006 : Comparison Reports on Aggregated Data
Shiftwise Report Period < a Day
Daywise Report Period   < a Week
WeekWise Report Period  < a Month
Monthwise Report Period < a Year
Procedure Changed By SSK on 30/Jan/2007 :
	To get AcceptedParts as Output
	To get DownTime,Utilised time in Minutes
Mod 1:- Procedure modified by Mrudula on 19-mar-2008 for DR0094. To introduce threshold comparison for ManagementLoss.
Mod 2:- Procedure modified by MKestur on 26th-March-2008; Month report incorrectly cumulates KPIs - machine qualification missed out in CROSS JOIN
Procedure altered by KarthikG on 20-May-2008 for ER0135. To add minor losses(down) with utilized time so that PE is reduced(correct)
mod 3 :- ER0182 By Kusuma M.H on 28-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
Note:For ER0181 No component operation qualification found.
****************************************************************************************************************************************************/
CREATE                         PROCEDURE [dbo].[s_GetShiftAgg_ComparisonReports_Graphs]
	@StartDate As DateTime,
	@EndDate As DateTime='27-Nov-2006',
	@ShiftName As  NVarChar(20)='',
	@PlantID As NVarChar(50)='',
	@MachineID As nvarchar(50) = '',
	@DownReason As NVarChar(50)='',
	@RejectionReason As NVarChar(50)='',
	@ComparisonType As nvarchar(20) /*SHIFT,DAY,WEEK,MONTH*/
	
AS
BEGIN
----------------------------------------------------------------------------------------------------------
--* Declaration of Variables *--
----------------------------------------------------------------------------------------------------------
Declare @Strsql nvarchar(4000)
Declare @timeformat AS nvarchar(12)
Declare @Strmachine nvarchar(255)
Declare @StrPlantID AS NVarchar(255)
Declare @StrShift AS NVarchar(255)
Declare @CurDate As DateTime
Declare @StratOfMonth As DateTime
Declare @EndOfMonth As DateTime
Select @Strsql = ''
Select @Strmachine = ''
Select @StrPlantID=''
Select @StrShift=''
-------------------------------------------------------------------------------------------------------------
-- * Building Strings * --
-------------------------------------------------------------------------------------------------------------
If isnull(@PlantID,'') <> ''
Begin
	---mod 3
--	Select @StrPlantID = ' And ( PlantMachine.PlantID = ''' + @PlantID + ''' )'
	Select @StrPlantID = ' And ( PlantMachine.PlantID = N''' + @PlantID + ''' )'
	---mod 3
End
If isnull(@Machineid,'') <> ''
Begin
	---mod 3
--	Select @Strmachine = ' And ( MachineInformation.MachineID = ''' + @MachineID + ''')'
	Select @Strmachine = ' And ( MachineInformation.MachineID = N''' + @MachineID + ''')'
	---mod 3
End
If isnull(@ShiftName,'') <> ''
Begin
	---mod 3
--	Select @StrShift = ' And ( ShiftProductionDetails.Shift = ''' + @ShiftName + ''')'
	Select @StrShift = ' And ( ShiftProductionDetails.Shift = N''' + @ShiftName + ''')'
	---mod 3
End
Select @timeformat ='ss'
Select @timeformat = isnull((Select valueintext from cockpitdefaults where parameter='timeformat'),'ss')
if (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')
Begin
Select @timeformat = 'ss'
End
--------------------------------------------------------------------------------------------------------
					-- * Creation of Temp Tables * --
--------------------------------------------------------------------------------------------------------
	
	Create Table #Header
	(
	RowHeader NVarChar(50)
	)
	Create Table #ProdData
	(
		Pdate DateTime,
		StartDate  DateTime,
		EndDate DateTime,
		Shift  NVarChar(20),
		MachineID  NVarChar(50),
		ProdCount Int DEFAULT 0,
		AcceptedParts Int DEFAULT 0,
		RejCount  Int DEFAULT 0,
		RepeatCycle Int DEFAULT 0,
		DummyCycle Int DEFAULT 0,
		ReworkPerformed Int DEFAULT 0,
		MarkedForRework Int DEFAULT 0,
		AEffy  Float DEFAULT 0,
		PEffy  Float DEFAULT 0,
		QEffy  Float DEFAULT 0,
		OEffy  Float DEFAULT 0,
		UtilisedTime  Float DEFAULT 0,
		DownTime  Float DEFAULT 0,
		CN  Float DEFAULT 0,
		---mod 1 introduced following column to store actual management loss
		ManagementLoss float default 0,
		DowntimeAE float default 0
		--CONSTRAINT ShiftAgg_ComparisonReports3_key PRIMARY KEY (MachineID,StartDate,EndDate)
	)
	CREATE TABLE #TimePeriodDetails (
		PDate datetime,
		Shift nvarchar(20),
		DStart datetime,
		DEnd datetime
		--CONSTRAINT ShiftAgg_ComparisonReports2_key PRIMARY KEY (PDate,DStart,DEnd)
	)
	CREATE TABLE #MachineInfo (
		MachineID nvarchar(50)PRIMARY KEY
		)
	
------------------------------------------------------------------------------------------------------------
/*
Population of #ProdData based on Input Parameters ( Shift,Day or Month )(PlantID ,MachineID)
*/
-----------------------------------------------------------------------------------------------------------
	
	Select @Strsql ='Insert Into #MachineInfo(MachineID)'
	Select @Strsql =@Strsql+' Select   Distinct MachineInformation.MachineID From MachineInformation'
	Select @Strsql =@Strsql+' Left Outer Join PlantMachine ON MachineInformation.MachineID=PlantMachine.MachineID'
	Select @Strsql =@Strsql+' Where MachineInformation.MachineID Is Not NULL'
	Select @Strsql =@Strsql+@StrPlantID+@Strmachine
	Select @Strsql =@Strsql+' Order By MachineInformation.MachineID'
	
	Exec (@Strsql)
	Select @Strsql =''
	If @ComparisonType='SHIFT'
	BEGIN
		INSERT #TimePeriodDetails(Pdate, Shift, DStart, DEnd)
		EXEC s_GetShiftTime @StartDate,@ShiftName
	END
	ELSE
	IF @ComparisonType='DAY'
	BEGIN
		SELECT @CurDate=@StartDate
		While @CurDate<=@EndDate
		BEGIN
			INSERT INTO #TimePeriodDetails ( pDate )
			SELECT @CurDate
			
			SELECT @CurDate=DateAdd(dd,1,@CurDate)
		END
	END
	IF @ComparisonType='Month'
	BEGIN
		SELECT @StratOfMonth=dbo.f_GetPhysicalMonth(@StartDate,'Start')
		SELECT @EndOfMonth=dbo.f_GetPhysicalMonth(@EndDate,'End')
		
		While @StratOfMonth<=@EndOfMonth
		BEGIN
			INSERT INTO #TimePeriodDetails ( DStart, DEnd )
			SELECT @StratOfMonth,dbo.f_GetPhysicalMonth(@StratOfMonth,'End')
			SELECT @StratOfMonth=DateAdd(mm,1,@StratOfMonth)
		END
	END
	Insert Into #ProdData(MachineID,Pdate,StartDate,EndDate,Shift)
	Select MachineID,Pdate,DStart,DEnd ,Shift From #TimePeriodDetails CROSS Join #MachineInfo
--------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
If isnull(@PlantID,'') <> ''
Begin
	---mod 3
--	Select @StrPlantID = ' And ( ShiftProductionDetails.PlantID = ''' + @PlantID + ''' )'
	Select @StrPlantID = ' And ( ShiftProductionDetails.PlantID = N''' + @PlantID + ''' )'
	---mod 3
End
If isnull(@Machineid,'') <> ''
Begin
	---mod 3
--	Select @Strmachine = ' And ( ShiftProductionDetails.MachineID = ''' + @MachineID + ''')'
	Select @Strmachine = ' And ( ShiftProductionDetails.MachineID = N''' + @MachineID + ''')'
	---mod 3
End
--------------------------------------------------------------------------------------------------------
/*
		Below section calculates KPI's if @ComparisonType='SHIFT'
*/
--------------------------------------------------------------------------------------------------------
	If @ComparisonType='SHIFT'
	BEGIN
		
		Select @CurDate = CAST(datePart(yyyy,@StartDate) AS nvarchar(4)) + '-' + SUBSTRING(DATENAME(MONTH,@StartDate),1,3) + '-' + CAST(datePart(dd,@StartDate) AS nvarchar(2))
		
		Select @Strsql = 'Update #ProdData Set ProdCount=ISNULL(T2.ProdCount,0),AcceptedParts=ISNULL(T2.AcceptedParts,0),'
		Select @Strsql = @Strsql+ 'RepeatCycle=ISNULL(T2.Repeat_Cycles,0),DummyCycle=ISNULL(T2.Dummy_Cycles,0),'
		Select @Strsql = @Strsql+ 'ReworkPerformed=ISNULL(T2.Rework_Performed,0),MarkedForRework=ISNULL(T2.MarkedForRework,0),UtilisedTime=ISNULL(T2.UtilisedTime,0)'
		Select @Strsql = @Strsql+ ' From('
		Select @Strsql = @Strsql+ ' Select pDate,Shift,MachineID,Sum(ISNULL(Prod_Qty,0))ProdCount,Sum(ISNULL(AcceptedParts,0))AcceptedParts,Sum(ISNULL(Repeat_Cycles,0))AS Repeat_Cycles ,Sum(ISNULL(Dummy_Cycles,0))AS Dummy_Cycles,
					    Sum(ISNULL(Rework_Performed,0))AS Rework_Performed,Sum(ISNULL(Marked_For_Rework,0)) as MarkedForRework,Sum(Sum_of_ActCycleTime)As UtilisedTime
		                            From ShiftProductionDetails'
		Select @Strsql = @Strsql+ ' Where MachineID IS NOT NULL And pDate='''+Convert(NVarChar(20),@CurDate)+''' '
		Select @Strsql = @Strsql+  @StrPlantID + @Strmachine + @StrShift
		Select @Strsql = @Strsql+ ' GROUP By pDate,Shift,MachineID'
		Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.pDate=T2.pDate And #ProdData.Shift=T2.Shift And #ProdData.MachineID=T2.MachineID'
		Print @Strsql
		Exec(@Strsql)
		--ER0135-karthikg-shift-s_GetShiftAgg_ComparisonReports '2007-12-01','2007-12-02','','','MC 01','','','Shift',''
		Select @Strsql =''
		SELECT @StrSql='UPDATE #ProdData SET UtilisedTime = Isnull(#ProdData.UtilisedTime,0)+IsNull(T2.MinorDownTime,0) '
		SELECT @StrSql=@StrSql+'From (SELECT MachineID,ddate,shift,sum(datediff(s,starttime,endtime)) as MinorDownTime '
		SELECT @StrSql=@StrSql+'FROM ShiftDownTimeDetails WHERE downid in (select downid from downcodeinformation where prodeffy = 1) '
		SELECT @StrSql=@StrSql+'Group By MachineID,ddate,shift) as T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID and T2.ddate=#ProdData.pdate and T2.shift=#ProdData.Shift'
--		print @StrSql
		EXEC(@StrSql)
		--ER0135========================================================================================================================
		Select @Strsql = 'UPDATE #ProdData SET RejCount=ISNULL(T1.Rej,0)'
		Select @Strsql = @Strsql+' FROM('
		Select @Strsql = @Strsql+' Select pDate,Shift,MachineID,Sum(isnull(Rejection_Qty,0))Rej'
		Select @Strsql = @Strsql+' From ShiftProductionDetails Left Outer Join ShiftRejectionDetails ON ShiftProductionDetails.ID=ShiftRejectionDetails.ID'
		Select @Strsql = @Strsql+' Where pDate='''+Convert(NVarChar(20),@CurDate)+''''
		Select @Strsql = @Strsql+@StrPlantID + @Strmachine + @StrShift
		Select @Strsql = @Strsql+' Group By pDate,Shift,MachineID'
		Select @Strsql = @Strsql+' )AS T1 Inner Join #ProdData ON #ProdData.pDate=T1.pDate And #ProdData.MachineID=T1.MachineID And #ProdData.Shift=T1.Shift'
		Print @Strsql
		Exec(@Strsql)
		Select @Strsql = 'Update #ProdData Set CN=ISNULL(T2.CN,0)'
		Select @Strsql = @Strsql + ' From ('
		Select @Strsql = @Strsql + ' Select pDate,Shift,MachineID,sum(Prod_Qty *(CO_StdMachiningTime+CO_StdLoadUnload)) AS CN '
		Select @Strsql = @Strsql + ' From ShiftProductionDetails '
		Select @Strsql = @Strsql + ' Where pDate='''+Convert(NVarChar(20),@CurDate)+''' '
		Select @Strsql = @Strsql + @StrPlantID + @Strmachine + @StrShift
		Select @Strsql = @Strsql + ' Group By pDate,Shift,MachineID'
		Select @Strsql = @Strsql + ' )AS T2 Inner Join #ProdData ON #ProdData.pDate=T2.pDate And #ProdData.MachineID=T2.MachineID And #ProdData.Shift=T2.Shift'
		Print @Strsql
		Exec(@Strsql)
		
		If isnull(@PlantID,'') <> ''
		Begin
			---mod 3
--			Select @StrPlantID = ' And ( ShiftDownTimeDetails.PlantID = ''' + @PlantID + ''' )'
			Select @StrPlantID = ' And ( ShiftDownTimeDetails.PlantID = N''' + @PlantID + ''' )'
			---mod 3
		End
		If isnull(@Machineid,'') <> ''
		Begin
			---mod 3
--			Select @Strmachine = ' And ( ShiftDownTimeDetails.MachineID = ''' + @MachineID + ''')'
			Select @Strmachine = ' And ( ShiftDownTimeDetails.MachineID = N''' + @MachineID + ''')'
			---mod 3
		End
		If isnull(@ShiftName,'') <> ''
		Begin
			---mod 3
--			Select @StrShift = ' And ( ShiftDownTimeDetails.Shift = ''' + @ShiftName + ''')'
			Select @StrShift = ' And ( ShiftDownTimeDetails.Shift = N''' + @ShiftName + ''')'
			---mod 3
		End
		---mod 1 to neglect only threshold ML from dtime. Consider total downtime here.
		Select @Strsql = 'UPDATE #ProdData SET DownTime = IsNull(T1.DownTime,0)'
		Select @Strsql = @Strsql + ' From (select dDate,Shift,MachineID,( Sum(DownTime) )As DownTime'
		---mod 1 to neglect only threshold ML from dtime
		---Select @Strsql = @Strsql + ' From ShiftDownTimeDetails where dDate='''+Convert(NVarChar(20),@CurDate)+'''  And ML_Flag=0'
		Select @Strsql = @Strsql + ' From ShiftDownTimeDetails where dDate='''+Convert(NVarChar(20),@CurDate)+''' '
		---till here
		Select @Strsql = @Strsql + @StrPlantID + @Strmachine + @StrShift
		Select @Strsql = @Strsql + ' Group By dDate,Shift,MachineID'
		Select @Strsql = @Strsql + ' ) AS T1 Inner Join #ProdData ON #ProdData.pDate=T1.dDate And #ProdData.MachineID=T1.MachineID And #ProdData.Shift=T1.Shift'
		Print @Strsql
		Exec(@Strsql)	
		
		----mod 1
		----ML calculations
		--ManagementLoss
			-- Type 1
		
			Select @Strsql = 'UPDATE #ProdData SET ManagementLoss =  isNull(t1.loss,0)'
			Select @Strsql = @Strsql + 'from (select ShiftDownTimeDetails.dDate,ShiftDownTimeDetails.Shift,ShiftDownTimeDetails.MachineID,sum(
				 CASE
				WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0
				THEN isnull(ShiftDownTimeDetails.Threshold,0)
				ELSE ShiftDownTimeDetails.DownTime
				 END) AS LOSS '
				Select @Strsql = @Strsql + ' From ShiftDownTimeDetails   where dDate='''+Convert(NVarChar(20),@CurDate)+''' And ML_Flag=1'
			Select @Strsql = @Strsql + @StrPlantID + @Strmachine + @StrShift
			Select @Strsql = @Strsql + ' Group By ShiftDownTimeDetails.dDate,ShiftDownTimeDetails.Shift,ShiftDownTimeDetails.MachineID'
			Select @Strsql = @Strsql + ' ) AS T1 Inner Join #ProdData ON #ProdData.pDate=T1.dDate And #ProdData.MachineID=T1.MachineID And #ProdData.Shift=T1.Shift'
			Print @Strsql
			Exec(@Strsql)	
		
		----Till here ML
		---mod 1
		---select * from #ProdData
		UPDATE #ProdData SET QEffy=CAST((AcceptedParts)As Float)/CAST((AcceptedParts+RejCount+MarkedForRework) AS Float)
		Where CAST((AcceptedParts+RejCount+MarkedForRework) AS Float) <> 0
		
		
		UPDATE #ProdData
		SET
			PEffy = (CN/UtilisedTime) ,
			---comment for mod 1
			----AEffy = (UtilisedTime)/(UtilisedTime + ISNULL( DownTime,0))
			--- till here
			---mod 1
			AEffy = (UtilisedTime)/(UtilisedTime + ISNULL( DownTime,0)-ManagementLoss)
			---mod 1
		WHERE UtilisedTime <> 0
		UPDATE #ProdData
		SET
			OEffy = PEffy * AEffy * QEffy * 100,
			PEffy = PEffy * 100 ,
			AEffy = AEffy * 100,
			QEffy = QEffy * 100
		---mod 1 to neglect only threshold ML from dtime
		UPDATE #ProdData SET DownTime=DownTime-ManagementLoss
		
		
	END
-----------------------------------------------------------------------------------------------------------------
/*
		Below section calculates KPI's if @ComparisonType='DAY'
*/
-----------------------------------------------------------------------------------------------------------------
	If @ComparisonType='DAY'
	BEGIN
		Select @Strsql = 'Update #ProdData Set ProdCount=ISNULL(T2.ProdCount,0),AcceptedParts=ISNULL(T2.AcceptedParts,0),'
		Select @Strsql = @Strsql+ 'RepeatCycle=ISNULL(T2.Repeat_Cycles,0),DummyCycle=ISNULL(T2.Dummy_Cycles,0),'
		Select @Strsql = @Strsql+ 'ReworkPerformed=ISNULL(T2.Rework_Performed,0),MarkedForRework=isnull(T2.MarkedForRework,0),UtilisedTime=ISNULL(T2.UtilisedTime,0)'
		Select @Strsql = @Strsql+ ' From('
		Select @Strsql = @Strsql+ ' Select pDate,MachineID,Sum(ISNULL(Prod_Qty,0))ProdCount,Sum(ISNULL(AcceptedParts,0))AcceptedParts,Sum(ISNULL(Repeat_Cycles,0))AS Repeat_Cycles ,Sum(ISNULL(Dummy_Cycles,0))AS Dummy_Cycles,
					    Sum(ISNULL(Rework_Performed,0))AS Rework_Performed,Sum(Isnull(Marked_For_Rework,0))AS MarkedForRework,Sum(Sum_of_ActCycleTime)As UtilisedTime
		                            From ShiftProductionDetails Inner Join (Select pDate As tDate ,MachineID As tMachineID  From #ProdData )T1 ON ShiftProductionDetails.pDate=T1.tDate And ShiftProductionDetails.MachineID=T1.tMachineID'
		Select @Strsql = @Strsql+ ' Where MachineID IS NOT NULL And pDate=T1.tDate '
		Select @Strsql = @Strsql+  @StrPlantID + @Strmachine
		Select @Strsql = @Strsql+ ' GROUP By pDate,MachineID'
		Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.pDate=T2.pDate And #ProdData.MachineID=T2.MachineID'
		Print @Strsql
		Exec(@Strsql)
		--ER0135-karthikg-day---s_GetShiftAgg_ComparisonReports '2007-12-01','2007-12-02','','','MC 01','','','day',''
		Select @Strsql =''
		SELECT @StrSql='UPDATE #ProdData SET UtilisedTime = Isnull(#ProdData.UtilisedTime,0)+IsNull(T2.MinorDownTime,0)
		From (select ddate,MachineId,sum(datediff(s,starttime,endtime)) as MinorDownTime from shiftdowntimedetails
		where downid in (select downid from downcodeinformation where prodeffy = 1)'
		SELECT @StrSql=@StrSql+' group by MachineID,ddate) as T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID and T2.ddate=#ProdData.pdate'
		print @StrSql
		EXEC(@StrSql)
		--ER0135=======================================================================================================================
		Select @Strsql = 'UPDATE #ProdData SET RejCount=ISNULL(T2.Rej,0)'
		Select @Strsql = @Strsql+' FROM('
		Select @Strsql = @Strsql+' Select pDate,MachineID,Sum(isnull(Rejection_Qty,0))Rej'
		Select @Strsql = @Strsql+' From ShiftProductionDetails Inner Join (Select pDate As tDate ,MachineID As tMachineID  From #ProdData )T1 ON ShiftProductionDetails.pDate=T1.tDate And ShiftProductionDetails.MachineID=T1.tMachineID
					   Left Outer Join ShiftRejectionDetails ON ShiftProductionDetails.ID=ShiftRejectionDetails.ID'
		Select @Strsql = @Strsql+' Where pDate=T1.tDate'
		Select @Strsql = @Strsql+@StrPlantID + @Strmachine
		Select @Strsql = @Strsql+' Group By pDate,MachineID'
		Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.pDate=T2.pDate And #ProdData.MachineID=T2.MachineID '
		Print @Strsql
		Exec(@Strsql)
		Select @Strsql = 'Update #ProdData Set CN=ISNULL(T2.CN,0)'
		Select @Strsql = @Strsql + ' From ('
		Select @Strsql = @Strsql + ' Select pDate,MachineID,sum(Prod_Qty *(CO_StdMachiningTime+CO_StdLoadUnload)) AS CN '
		Select @Strsql = @Strsql + ' From ShiftProductionDetails Inner Join (Select pDate As tDate ,MachineID As tMachineID  From #ProdData )T1 ON ShiftProductionDetails.pDate=T1.tDate And ShiftProductionDetails.MachineID=T1.tMachineID '
		Select @Strsql = @Strsql + ' Where pDate=T1.tDate '
		Select @Strsql = @Strsql + @StrPlantID + @Strmachine
		Select @Strsql = @Strsql + ' Group By pDate,MachineID '
		Select @Strsql = @Strsql + ' )AS T2 Inner Join #ProdData ON #ProdData.pDate=T2.pDate And #ProdData.MachineID=T2.MachineID '
		Print @Strsql
		Exec(@Strsql)
		
		If isnull(@PlantID,'') <> ''
		Begin
			---mod 3
--			Select @StrPlantID = ' And ( ShiftDownTimeDetails.PlantID = ''' + @PlantID + ''' )'
			Select @StrPlantID = ' And ( ShiftDownTimeDetails.PlantID = N''' + @PlantID + ''' )'
			---mod 3
		End
		If isnull(@Machineid,'') <> ''
		Begin
			---mod 3
--			Select @Strmachine = ' And ( ShiftDownTimeDetails.MachineID = ''' + @MachineID + ''')'
			Select @Strmachine = ' And ( ShiftDownTimeDetails.MachineID = N''' + @MachineID + ''')'
			---mod 3
		End
		
		Select @Strsql = 'UPDATE #ProdData SET DownTime = IsNull(T2.DownTime,0)'
		Select @Strsql = @Strsql + ' From (select dDate,MachineID,(Sum(DownTime))As DownTime'
		Select @Strsql = @Strsql + ' From ShiftDownTimeDetails Inner Join (Select pDate As tDate ,MachineID As tMachineID  From #ProdData )T1 ON ShiftDownTimeDetails.dDate=T1.tDate And ShiftDownTimeDetails.MachineID=T1.tMachineID '
		---mod 1 to neglect only threshold ML from dtime
		---Select @Strsql = @Strsql + ' where dDate=T1.tDate And ML_Flag=0'
		Select @Strsql = @Strsql + ' where dDate=T1.tDate '
		---till here
		Select @Strsql = @Strsql + @StrPlantID + @Strmachine 		
		Select @Strsql = @Strsql + ' Group By dDate,MachineID'
		Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON #ProdData.pDate=T2.dDate And #ProdData.MachineID=T2.MachineID '
		Print @Strsql
		Exec(@Strsql)	
		
		----mod 1
		----ML calculations
		--ManagementLoss
			-- Type 1
		
			Select @Strsql = 'UPDATE #ProdData SET ManagementLoss =  isNull(t2.loss,0)'
			Select @Strsql = @Strsql + 'from (select ShiftDownTimeDetails.dDate,ShiftDownTimeDetails.MachineID,sum(
				 CASE
				WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0
				THEN isnull(ShiftDownTimeDetails.Threshold,0)
				ELSE ShiftDownTimeDetails.DownTime
				 END) AS LOSS '
				Select @Strsql = @Strsql + ' From ShiftDownTimeDetails Inner Join (Select pDate As tDate ,MachineID As tMachineID  From #ProdData )T1 ON ShiftDownTimeDetails.dDate=T1.tDate And ShiftDownTimeDetails.MachineID=T1.tMachineID  '
			 	Select @Strsql = @Strsql + ' where dDate=T1.tDate  And ML_Flag=1'
			Select @Strsql = @Strsql + @StrPlantID + @Strmachine
			Select @Strsql = @Strsql + ' Group By ShiftDownTimeDetails.dDate,ShiftDownTimeDetails.MachineID'
			Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON #ProdData.pDate=T2.dDate And #ProdData.MachineID=T2.MachineID '
			Print @Strsql
			Exec(@Strsql)	
		
		----Till here ML
		---mod 1
		
		UPDATE #ProdData SET QEffy=CAST((AcceptedParts)As Float)/CAST((AcceptedParts+RejCount+MarkedForRework) AS Float)
		Where CAST((AcceptedParts+RejCount+MarkedForRework) AS Float) <> 0
		
		
		UPDATE #ProdData
		SET
			PEffy = (CN/UtilisedTime) ,
			---comment for mod 1
			----AEffy = (UtilisedTime)/(UtilisedTime + ISNULL( DownTime,0))
			----till here
			AEffy = (UtilisedTime)/(UtilisedTime + ISNULL( DownTime,0)-ManagementLoss)
		WHERE UtilisedTime <> 0
	
		---select * from #ProdData
		UPDATE #ProdData
		SET
			OEffy = PEffy * AEffy * QEffy * 100,
			PEffy = PEffy * 100 ,
			AEffy = AEffy * 100,
			QEffy = QEffy * 100
		---mod 1 to neglect only threshold ML from dtime
		UPDATE #ProdData SET DownTime=DownTime-ManagementLoss
		
	END
-------------------------------------------------------------------------------------------------------------------
/*
		Below section calculates KPI's if @ComparisonType='MONTH'
*/
-------------------------------------------------------------------------------------------------------------------
	If @ComparisonType='MONTH'
	BEGIN
		/* Mod 2: removed machineid is null and introduced T1.tmachineid = ShiftProductionDetails.machineid */
		
		Select @Strsql = 'Update #ProdData Set ProdCount=ISNULL(T2.ProdCount,0),AcceptedParts=ISNULL(T2.AcceptedParts,0),'
		Select @Strsql = @Strsql+ 'RepeatCycle=ISNULL(T2.Repeat_Cycles,0),DummyCycle=ISNULL(T2.Dummy_Cycles,0),'
		Select @Strsql = @Strsql+ 'ReworkPerformed=ISNULL(T2.Rework_Performed,0),MarkedForRework=ISNULL(T2.MarkedForRework,0),UtilisedTime=ISNULL(T2.UtilisedTime,0)'
		Select @Strsql = @Strsql+ ' From('
		Select @Strsql = @Strsql+ ' Select T1.StartDate As StartDate ,T1.EndDate As EndDate,MachineID,Sum(ISNULL(Prod_Qty,0))ProdCount,Sum(ISNULL(AcceptedParts,0))AcceptedParts,Sum(ISNULL(Repeat_Cycles,0))AS Repeat_Cycles ,Sum(ISNULL(Dummy_Cycles,0))AS Dummy_Cycles,
					    Sum(ISNULL(Rework_Performed,0))AS Rework_Performed,Sum(ISNULL(Marked_For_Rework,0)) AS MarkedForRework,Sum(Sum_of_ActCycleTime)As UtilisedTime
		                            From ShiftProductionDetails CROSS Join (Select StartDate ,EndDate,MachineID As tMachineID  From #ProdData ) as T1 '
		Select @Strsql = @Strsql+ ' Where T1.tMachineID =  ShiftProductionDetails.Machineid And pDate>=T1.StartDate And pDate<= T1.EndDate'
		Select @Strsql = @Strsql+  @StrPlantID + @Strmachine
		Select @Strsql = @Strsql+ ' GROUP By T1.StartDate,T1.EndDate,MachineID'
		Select @Strsql = @Strsql+ ' )As T2 Right Outer Join #ProdData ON #ProdData.StartDate=T2.StartDate And #ProdData.EndDate=T2.EndDate And #ProdData.MachineID=T2.MachineID'
		Print @Strsql
		Exec(@Strsql)
		
		--ER0135-karthikg-Month-s_GetShiftAgg_ComparisonReports '2007-11-01','2008-01-01','','','MC 01','','','Month',''
		Select @Strsql =''
		SELECT @StrSql='UPDATE #ProdData SET UtilisedTime = Isnull(#ProdData.UtilisedTime,0)+IsNull(T2.MinorDownTime,0) '
		Select @Strsql = @Strsql+ 'From (SELECT MachineID,datepart(mm,ddate)as dmonth,datepart(yyyy,ddate)as dyear,sum(datediff(s,starttime,endtime)) as MinorDownTime FROM ShiftDownTimeDetails '
		Select @Strsql = @Strsql+ 'WHERE downid in (select downid from downcodeinformation where prodeffy = 1) Group By MachineID,datepart(mm,ddate),datepart(yyyy,ddate)'
		Select @Strsql = @Strsql+ ') as T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID and T2.dmonth=datepart(mm,#ProdData.Startdate) and T2.dyear=datepart(yyyy,#ProdData.EndDate)'
--		print @StrSql
		EXEC(@StrSql)
		--ER0135========================================================================================================================
		/* Mod 2: introduced T1.tmachineid = ShiftProductionDetails.machineid */
		Select @Strsql = 'UPDATE #ProdData SET RejCount=ISNULL(T2.Rej,0)'
		Select @Strsql = @Strsql+' FROM('
		Select @Strsql = @Strsql+' Select T1.StartDate As StartDate ,T1.EndDate As EndDate,MachineID,Sum(isnull(Rejection_Qty,0))Rej'
		Select @Strsql = @Strsql+' From ShiftProductionDetails CROSS Join (Select StartDate ,EndDate,MachineID As tMachineID  From #ProdData )T1
					   Left Outer Join ShiftRejectionDetails ON ShiftProductionDetails.ID=ShiftRejectionDetails.ID'
		Select @Strsql = @Strsql+' Where T1.tmachineid = ShiftProductionDetails.machineid and pDate>=T1.StartDate And pDate<= T1.EndDate'
		Select @Strsql = @Strsql+@StrPlantID + @Strmachine
		Select @Strsql = @Strsql+' Group By T1.StartDate,T1.EndDate,MachineID'
		Select @Strsql = @Strsql+' )AS T2 Inner Join #ProdData ON #ProdData.StartDate=T2.StartDate And #ProdData.EndDate=T2.EndDate And #ProdData.MachineID=T2.MachineID '
		Print @Strsql
		Exec(@Strsql)
		
		/* Mod 2: introduced T1.tmachineid = ShiftProductionDetails.machineid */
		Select @Strsql = 'Update #ProdData Set CN=ISNULL(T2.CN,0)'
		Select @Strsql = @Strsql + ' From ('
		Select @Strsql = @Strsql + ' Select T1.StartDate As StartDate ,T1.EndDate As EndDate,MachineID,sum(Prod_Qty *(CO_StdMachiningTime+CO_StdLoadUnload)) AS CN '
		Select @Strsql = @Strsql + ' From ShiftProductionDetails CROSS Join (Select StartDate ,EndDate,MachineID As tMachineID  From #ProdData )T1 '
		Select @Strsql = @Strsql + ' Where T1.tmachineid = ShiftProductionDetails.machineid and pDate>=T1.StartDate And pDate<= T1.EndDate '
		Select @Strsql = @Strsql + @StrPlantID + @Strmachine
		Select @Strsql = @Strsql + ' Group By T1.StartDate,T1.EndDate,MachineID '
		Select @Strsql = @Strsql + ' )AS T2 Inner Join #ProdData ON #ProdData.StartDate=T2.StartDate And #ProdData.EndDate=T2.EndDate And #ProdData.MachineID=T2.MachineID '
		Print @Strsql
		Exec(@Strsql)
		
		If isnull(@PlantID,'') <> ''
		Begin
			---mod 3
--			Select @StrPlantID = ' And ( ShiftDownTimeDetails.PlantID = ''' + @PlantID + ''' )'
			Select @StrPlantID = ' And ( ShiftDownTimeDetails.PlantID = N''' + @PlantID + ''' )'
			---mod 3
		End
		If isnull(@Machineid,'') <> ''
		Begin
			---mod 3
--			Select @Strmachine = ' And ( ShiftDownTimeDetails.MachineID = ''' + @MachineID + ''')'
			Select @Strmachine = ' And ( ShiftDownTimeDetails.MachineID = N''' + @MachineID + ''')'
			---mod 3
		End
		
		
		/* Downtime Calc: Mod 2 - Removed ML_Flag = 0, introduced T1.tmachineid = ShiftDowntimeDetails.machineid */
		
		Select @Strsql = 'UPDATE #ProdData SET DownTime = IsNull(T2.DownTime,0)'
		Select @Strsql = @Strsql + ' From (select T1.StartDate As StartDate ,T1.EndDate As EndDate,MachineID,(Sum(DownTime))As DownTime'
		Select @Strsql = @Strsql + ' From ShiftDownTimeDetails CROSS Join (Select StartDate ,EndDate,MachineID As tMachineID  From #ProdData )T1
				 where T1.tmachineid = ShiftDowntimeDetails.machineid and dDate>=T1.StartDate And dDate<= T1.EndDate'
		Select @Strsql = @Strsql + @StrPlantID + @Strmachine 		
		Select @Strsql = @Strsql + ' Group By T1.StartDate,T1.EndDate,MachineID'
		Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON #ProdData.StartDate=T2.StartDate And #ProdData.EndDate=T2.EndDate And #ProdData.MachineID=T2.MachineID '
		Print @Strsql
		Exec(@Strsql)	
		
		----mod 1 introduced with mod 2 by mkestur:26-march-2008
		----ML calculations
		--ManagementLoss
			-- Type 1
		
			Select @Strsql = 'UPDATE #ProdData SET ManagementLoss =  isNull(T2.loss,0)'
			Select @Strsql = @Strsql + 'from (select T1.startdate as startdate, T1.Enddate as Enddate, Machineid, sum(
				 CASE
				WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0
				THEN isnull(ShiftDownTimeDetails.Threshold,0)
				ELSE ShiftDownTimeDetails.DownTime
				 END) AS LOSS '
				Select @Strsql = @Strsql + ' From ShiftDownTimeDetails CROSS JOIN (Select StartDate ,EndDate,MachineID As tMachineID  From #ProdData )T1
where T1.tmachineid = ShiftDowntimeDetails.machineid and dDate>=T1.StartDate And dDate<= T1.EndDate And ML_flag = 1'
			
			Select @Strsql = @Strsql + @StrPlantID + @Strmachine
			Select @Strsql = @Strsql + ' Group By T1.StartDate,T1.EndDate,MachineID'
			Select @Strsql = @Strsql + ' ) AS T2 Inner Join #ProdData ON #ProdData.StartDate=T2.StartDate And #ProdData.EndDate=T2.EndDate And #ProdData.MachineID=T2.MachineID '
			Print @Strsql
			Exec(@Strsql)	
		
		----Till here ML
		---mod 1
		UPDATE #ProdData SET QEffy=CAST((AcceptedParts)As Float)/CAST((AcceptedParts+RejCount+MarkedForRework) AS Float)
		Where CAST((AcceptedParts+RejCount+MarkedForRework) AS Float) <> 0
		UPDATE #ProdData
		SET
			PEffy = (CN/UtilisedTime) ,
			AEffy = (UtilisedTime)/(UtilisedTime + ISNULL( DownTime,0))
		WHERE UtilisedTime <> 0
		UPDATE #ProdData
		SET
			OEffy = PEffy * AEffy * QEffy * 100,
			PEffy = PEffy * 100 ,
			AEffy = AEffy * 100,
			QEffy = QEffy * 100
	---mod 1 introduced with mod2 to neglect threshold ML from dtime
		UPDATE #ProdData SET DownTime=DownTime-ManagementLoss
		
	END
	
	
		Select * From #ProdData
	
	
END
