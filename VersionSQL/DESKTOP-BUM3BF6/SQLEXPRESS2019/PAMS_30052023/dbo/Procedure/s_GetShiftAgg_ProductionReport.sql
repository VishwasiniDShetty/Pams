/****** Object:  Procedure [dbo].[s_GetShiftAgg_ProductionReport]    Committed by VersionSQL https://www.versionsql.com ******/

/**************************************** -- HISTORY -- ******************************************
Procedure Created By Sangeeta Kallur on 13-Nov-2006 : To get reports On Shift Aggregation Data .
	Basic intention was to replace "PUSH by Hour" Concept by "PUSH by SHIFT".
Procedure Changed By SSK on 23/Nov/2006 :
	 Bz of change in column names of 'ShiftProductionDetails','ShiftDownTimeDetails'tables.
Procedure Changed By SSK on 30/Jan/2007 :
	To get AcceptedParts as Output
Procedure Changed by Sangeeta Kallur on 02-Feb-2007
	To get Marked_for_Rework as OutPut
	To change the QE Calculation ie QE=AcceptedParts/(AcceptedParts+Rejection+Rework)
Procedure altered by Mrudula on 28-dec-07 to change the length of operation no to nvarchar(5)
Mod 1:- Procedure modified by Mrudula on 19-mar-2008 for DR0094. To introduce threshold comparision for managementLoss.
Procedure altered by Shilpa H.M on 20-may-08 for NR0043:Where we support Groupid's to be displayed as indvidual operator
Procedure altered by KarthikG on 20-May-2008 for ER0135. To add minor losses(down) with utilized time so that PE is reduced(correct)
Procedure altered by KarthikG on 12-Jun-2008 for ER0138. In adding minor losses with utilized time i.e..
	Minor losses means downid of PE_Flag set is read from the same shiftaggdowndata instead of reading from downcodeinformation
Procedure altered by KarthikG on 10-Mar-2009 ER0175 :: To new Excel Reports has been added in Shift basis as Format - 3 and in Daily basis as Format - 3.
--This Procedure is used in the report SM_Aggregated_DayProductionReport_Type3_Template.xls, SM_Aggregated_ShiftProductionReport_Type3_Template.xls
mod 2 :- ER0182 By Kusuma M.H on 18-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
Note:For ER0181 No component operation qualification found.
ER0229 - KarthikG - 10/May/2010 :: Increase the size of operation number business id from 4 to 8.
In ComponentOperationPricing table operationno from smallint to int.
DR0292 - Swathi KS - 24/Aug/2011 ::a> Microsoft ODBC Error Has Occured Due to Calculation has been done even AcceptedParts = 0 .
				    Flow :: SM->Agg->Production Report Machinewise->Daily->Format-3.
				   b> In the Reports,Graph Was Showing Downtime 00:00:00 Due to Unhandling Null values.
				    Flow : SM ->Agg->Downtime Report->Machinewise Downtime Matrix.
DR0302 - SwathiKS - 26/dec/2011 :: To Handle PE Mismatch in SM->Agg->Production Report Operatorwise -> TimeConsolidated.
ER0388 - SwathiKS - 01/Aug/2014 :: To include WorkOrdernumber in SM->Agg->Production Report Machinewise -> Daily -> Format3.

--s_GetShiftAgg_ProductionReport '2020-12-01 08:30:00','2020-12-03 08:30:00','','','','','Machinewise','Consolidatedformatrixreport','','',''
s_GetShiftAgg_ProductionReport '2020-12-01 08:30:00','2020-12-03 08:30:00','','','','','operatorwise','day','','',''
s_GetShiftAgg_ProductionReport '2020-07-20 08:30:00','2020-07-21 08:30:00','','','','','operatorwise','ProdReport','','',''
s_GetShiftAgg_ProductionReport '2021-06-01 00:00:00','2021-06-30 00:00:00','','','','2309','operatorwise','ProdReport','','',''
exec [dbo].[s_GetShiftAgg_ProductionReport] @StartDate=N'2020-10-01 00:00:00',@EndDate=N'2020-10-10 00:00:00',@PlantID=N'',@OperatorID=N'pct',@ReportType=N'OperatorWise',@Parameter=N'ProdReport'
exec s_GetShiftAgg_ProductionReport @StartDate=N'2022-01-01',@EndDate=N'2022-01-15',@ShiftName=N'',@PlantID=N'',@MachineId=N'30 Ton-Welding Machine-146,60 Ton-Welding Machine-155',@GroupID=N'',@ReportType=N'Machinewise',@Parameter=N'SONA_AggCockpit',@SortOrder=N'MachineID asc',@SortType=N''
**************************************************************************************************/

CREATE    PROCEDURE [dbo].[s_GetShiftAgg_ProductionReport]
	@StartDate As DateTime,
	@EndDate As DateTime,
	@ShiftName As  NVarChar(20)='',
	@PlantID As NVarChar(50)='',
	@MachineID As nvarchar(MAX) = '',
	@OperatorID As nvarchar(50) = '',
	@ReportType As nvarchar(20) , /* MachineWise,OperatorWise*/
	@Parameter As nvarchar(50),/* Shift,Day,Consolidated Etc*/
	@GroupID nvarchar(MAX)='',
	@SortType nvarchar(50)='CustomSortorder',
	@SortOrder nvarchar(50)=''
AS
BEGIN
----------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------
Declare @Strsql nvarchar(MAX)
Declare @Strmachine nvarchar(MAX)
Declare @timeformat AS nvarchar(12)
Declare @StrPlantID AS NVarchar(255)
Declare @StrOpr AS NVarchar(255)
Declare @StrShift AS NVarchar(255)
Declare @StrDmachine nvarchar(MAX)
Declare @StrDPlantID AS NVarchar(255)
Declare @StrDShift AS NVarchar(255)
Declare @StrDOpr nvarchar(255)
Declare @CurDate as datetime
Declare @LastDate as datetime
Declare @FromTime as datetime
Declare @ToTime as datetime
declare @StrGroupID as nvarchar(MAX)
declare @StrDGroupID as nvarchar(MAX)
declare @StrMCJoined as nvarchar(max)
declare @StrGroupJoined as nvarchar(max)
declare @StrDMCJoined as nvarchar(max)
declare @StrDGroupJoined as nvarchar(max)

Declare @StrTPMMachines AS nvarchar(500) 
SELECT @StrTPMMachines=''

select @StrDGroupID=''
select @StrGroupID=''
Select @Strsql = ''
Select @Strmachine = ''
Select @StrPlantID=''
Select @StrOpr=''
Select @StrShift=''
Select @StrDmachine = ''
Select @StrDPlantID=''
Select @StrDShift=''
Select @StrDOpr=''


If isnull(@PlantID,'') <> ''
Begin
	---mod 2
--	Select @StrPlantID = ' And ( ShiftProductionDetails.PlantID = ''' + @PlantID + ''' )'
	Select @StrPlantID = ' And ( ShiftProductionDetails.PlantID = N''' + @PlantID + ''' )'
	---mod 2
End
If isnull(@Machineid,'') <> ''
Begin
	select @StrMCJoined =  (case when (coalesce( +@StrMCJoined + ',''', '''')) = ''''  then 'N''' else @StrMCJoined+',N''' end) +item+'''' from [SplitStrings](@MachineID, ',')    
	if @StrMCJoined = 'N'''''  
	set @StrMCJoined = '' 
	select @MachineID = @StrMCJoined

	Select @Strmachine = ' And ( ShiftProductionDetails.MachineID IN (' + @MachineID + '))'
	
	---mod 2
End
If isnull(@OperatorID,'') <> ''
Begin
	---mod 2
--	Select @StrOpr = ' And ( ShiftProductionDetails.OperatorID = ''' + @OperatorID + ''')'
	Select @StrOpr = ' And ( ShiftProductionDetails.OperatorID = N''' + @OperatorID + ''')'
	---mod 2
End
If isnull(@ShiftName,'') <> ''
Begin
	---mod 2
--	Select @StrShift = ' And ( ShiftProductionDetails.Shift = ''' + @ShiftName + ''')'
	Select @StrShift = ' And ( ShiftProductionDetails.Shift = N''' + @ShiftName + ''')'
	---mod 2
End
if isnull(@GroupID,'')<> ''
Begin
	select @StrGroupJoined =  (case when (coalesce( +@StrGroupJoined + ',''', '''')) = ''''  then 'N''' else @StrGroupJoined+',N''' end) +item+'''' from [SplitStrings](@GroupID, ',')    
	if @StrGroupJoined = 'N'''''  
	set @StrGroupJoined = '' 
	select @GroupID = @StrGroupJoined

	Select @StrGroupid = ' And ( ShiftProductionDetails.GroupID  IN (' + @GroupID + '))'
End

------------------------------------------------------------------------------------------------------------

If isnull(@PlantID,'') <> ''
Begin
	---mod 2
--	Select @StrDPlantID = ' And ( ShiftDownTimeDetails.PlantID = ''' + @PlantID + ''' )'
	Select @StrDPlantID = ' And ( ShiftDownTimeDetails.PlantID = N''' + @PlantID + ''' )'
	---mod 2
End
If isnull(@Machineid,'') <> ''
Begin

	
	Select @StrDmachine = ' And ( ShiftDownTimeDetails.MachineID IN (' + @MachineID + '))'
	---mod 2
End
If isnull(@ShiftName,'') <> ''
Begin
	---mod 2
--	Select @StrDShift = ' And ( ShiftDownTimeDetails.Shift = ''' + @ShiftName + ''')'
	Select @StrDShift = ' And ( ShiftDownTimeDetails.Shift = N''' + @ShiftName + ''')'
	---mod 2
End
If isnull(@OperatorID,'') <> ''
Begin
	---mod 2
--	Select @StrDOpr = ' And ( ShiftDownTimeDetails.OperatorID = ''' + @OperatorID + ''')'
	Select @StrDOpr = ' And ( ShiftDownTimeDetails.OperatorID = N''' + @OperatorID + ''')'
	---mod 2
End
if isnull(@GroupID,'')<> ''
Begin
	Select @StrDGroupid = ' And ( ShiftDownTimeDetails.GroupID IN (' + @GroupID + '))'
End

-------------------------------------------------------------------------------------------------------------
Select @timeformat ='ss'
Select @timeformat = isnull((Select valueintext from cockpitdefaults where parameter='timeformat'),'ss')
if (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')
Begin
Select @timeformat = 'ss'
End
Select @CurDate = CAST(datePart(yyyy,@StartDate) AS nvarchar(4)) + '-' + SUBSTRING(DATENAME(MONTH,@StartDate),1,3) + '-' + CAST(datePart(dd,@StartDate) AS nvarchar(2))
Select @LastDate= CAST(datePart(yyyy,@EndDate) AS nvarchar(4)) + '-' + SUBSTRING(DATENAME(MONTH,@EndDate),1,3) + '-' + CAST(datePart(dd,@EndDate) AS nvarchar(2))
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
	Create Table #ProdData
	(
		[Day]  DateTime,
		Shift  NVarChar(50),
		MachineID  NVarChar(50),
		ComponentID NVarChar(50),
		OperationNo Int,
		StdCycleTime Float,
		AvgCycleTime Float,--Used for Speed Ratio
		StdLoadUnload Float,
		AvgLoadUnload Float,--Used for Load Ratio
		ProdCount  float,
		AcceptedParts float,
		RejCount  Int,
		RepeatCycle Int,
		DummyCycle Int,
		ReworkPerformed Int,
		MarkedForRework Int,
		AEffy  Float,
		PEffy  Float,
		QEffy  Float,
		OEffy  Float,
		UtilisedTime  Float,
		DownTime  Float,
		MgmtLoss  Float,
		DownTimeAE Float,
		CN  Float,	
		Isgrp int,
		WorkorderNo Nvarchar(50), --ER0388
		PEGreen smallint,
		PERed smallint,
		AEGreen smallint,
		AERed smallint,
		OEGreen smallint,
		OERed smallint,
		QEGreen smallint, 
		QERed smallint, 
		MachineDescription nvarchar(150),			
		MaxDownReasonTime nvarchar(50) DEFAULT (''),
		Plantid nvarchar(50),
		Groupid nvarchar(50),
		GroupDescription nvarchar(150),
		PlantDescription nvarchar(150),
		ProductionPdt FLOAT,
		DownPdt FLOAT,
		MLPdt float,
		TargetCount int,
		OperatorID  NVarChar(1000),
		OperatorName nvarchar(1000),
		RejectionReason nvarchar(1000)
	)
	CREATE TABLE #ShiftDetails (
		PDate datetime,
		Shift nvarchar(20),
		ShiftStart datetime,
		ShiftEnd datetime
	)
	Create Table #Header
	(
		[Day]  DateTime,
		Shift  NVarChar(50),
		PlantID NVarChar(50),
		MachineID  NVarChar(50),
		GroupID nvarchar(50),
		ComponentID NVarChar(50),
		OperationNo Int,
		OperatorID  NVarChar(50),
		OperatorName nvarchar(100),
		WorkorderNo Nvarchar(50) --ER0388		
	)

	Create Table #Summary
	(
		Plantid nvarchar(50),
		Groupid nvarchar(50),
		MachineID  NVarChar(50),
		ComponentID NVarChar(50),
		OperationNo Int,
		OperatorID  NVarChar(50),
		StdCycleTime Float,
		AvgCycleTime Float,--Used for Speed Ratio
		StdLoadUnload Float,
		AvgLoadUnload Float,--Used for Load Ratio
		ProdCount  float,
		AcceptedParts float,
		RejCount  Int,
		RepeatCycle Int,
		DummyCycle Int,
		ReworkPerformed Int,
		MarkedForRework Int,
		AEffy  Float,
		PEffy  Float,
		QEffy  Float,
		OEffy  Float,
		UtilisedTime  Float,
		DownTime  Float,
		MgmtLoss  Float,
		DownTimeAE Float,
		CN  Float,	
		WorkorderNo Nvarchar(50), --ER0388
		MachineDescription nvarchar(150),			
		MaxDownReasonTime nvarchar(50) DEFAULT (''),
		GroupDescription nvarchar(150),
		PlantDescription nvarchar(150),
		CycleEffy float,
		LoadUnloadEffy float,
		TotalTime float,
		ProductionPdt FLOAT,
		DownPdt FLOAT,
		MLPdt float

	)

	--Inserting distinct D-S-M-C-O-O records from 'ShiftProductionDetails'
	Select @Strsql=''
	Select @Strsql = 'Insert Into #Header([Day],Shift,PlantID,MachineID,ComponentID,OperationNo,OperatorID,WorkorderNo,GroupID,Operatorname) --ER0388
	SELECT Distinct pDate,Shift,PlantID,MachineID,ComponentID,OperationNo,OperatorID,WorkOrderNumber,GroupID,e.name --ER0388
	From ShiftProductionDetails
	left join employeeinformation e on e.employeeid=ShiftProductionDetails.OperatorID
	Where ShiftProductionDetails.pDate>='''+Convert(NvarChar(20),@CurDate)+''' and ShiftProductionDetails.pDate<='''+Convert(NvarChar(20),@LastDate)+''' '
	Select @Strsql=@Strsql+@StrPlantID+@Strmachine+@StrShift+@StrGroupID
	PRINT @Strsql
	Exec(@Strsql)


	--Inserting distinct D-S-M-C-O-O records from 'ShiftDownTimeDetails' which are not in 'ShiftProductionDetails'
	--ER0229 - KarthikG - 10/May/2010
	Select @Strsql = 'Insert Into #Header([Day],Shift,PlantID,MachineID,ComponentID,OperationNo,OperatorID,WorkorderNo,GroupID,Operatorname) --ER0388
	SELECT Distinct dDate,Shift,PlantID,MachineID,ComponentID,OperationNo,OperatorID,WorkOrderNumber,GroupID,e.name --ER0388
	From ShiftDownTimeDetails
	left join employeeinformation e on e.employeeid=ShiftDownTimeDetails.OperatorID
	Where (ShiftDownTimeDetails.dDate>='''+Convert(NvarChar(20),@CurDate)+''' and ShiftDownTimeDetails.dDate<='''+Convert(NvarChar(20),@LastDate)+''')
	And Convert(NvarChar(20),dDate)+Shift+MachineID+ComponentID+Convert(NvarChar(10),OperationNo)+OperatorID  NOT IN
	(SELECT Convert(Nvarchar(20),Day)+Shift+MachineID+ComponentID+Convert(NvarChar(10),OperationNo)+OperatorID From #Header)'
	--ER0229 - KarthikG - 10/May/2010
	Select @Strsql=@Strsql+@StrDPlantID+@StrDmachine+@StrDShift+@StrDGroupID
	print @Strsql
	Exec(@Strsql)
	
	Select @Strsql=''
	
	INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)
	EXEC s_GetShiftTime @StartDate,@ShiftName
	select @FromTime = (select TOP 1 ShiftStart from #ShiftDetails ORDER BY ShiftStart ASC)
	select @ToTime = (select TOP 1 ShiftEnd from #ShiftDetails ORDER BY ShiftEnd DESC)


--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
If isnull(@PlantID,'') <> ''
Begin
	---mod 2
--	Select @StrPlantID = ' And ( #Header.PlantID = ''' + @PlantID + ''' )'
	Select @StrPlantID = ' And ( #Header.PlantID = N''' + @PlantID + ''' )'
	---mod 2
End
If isnull(@Machineid,'') <> ''
Begin
	
	Select @Strmachine = ' And ( #Header.MachineID IN (' + @MachineID + '))'
	---mod 2
End
If isnull(@ShiftName,'') <> ''
Begin
	---mod 2
--	Select @StrShift = ' And ( #Header.Shift = ''' + @ShiftName + ''')'
	Select @StrShift = ' And ( #Header.Shift = N''' + @ShiftName + ''')'
	---mod 2
End
If isnull(@GroupID,'') <> ''
Begin
	Select @StrGroupID = ' And ( #Header.GroupID IN (' + @GroupID + '))'
	---mod 2
End


If @ReportType='MachineWise'
BEGIN

	If @Parameter='Shift' OR @Parameter='Day' or @Parameter='Summary'
	BEGIN
		--Inserting all production details by comparing #Header and ShiftProductionDetails
		Select @Strsql = 'Insert Into #ProdData([Day] ,Shift,MachineID,ComponentID,OperationNo,ProdCount,AcceptedParts ,
		StdCycleTime,StdLoadUnload,AvgCycleTime,AvgLoadUnload,CN,RepeatCycle,DummyCycle,ReworkPerformed,MarkedForRework,WorkorderNo) --ER0388
		Select #Header.[Day],#Header.Shift,#Header.MachineID,#Header.ComponentID,#Header.OperationNo,
		Sum(ISNULL(Prod_Qty,0)),Sum(ISNULL(AcceptedParts,0)),
		Max(CO_StdMachiningTime),Max(CO_StdLoadUnload),
		(sum(ActMachiningTime_Type12)/sum(Prod_Qty)),
		(Sum(ActLoadUnload_Type12)/sum(Prod_Qty)),
		--(sum(Prod_Qty) * Max(CO_StdMachiningTime+CO_StdLoadUnload)),
		sum(Prod_Qty * (CO_StdMachiningTime+CO_StdLoadUnload)),
		sum(ISNULL(Repeat_Cycles,0)),sum(ISNULL(Dummy_Cycles,0)),sum(ISNULL(Rework_Performed,0)),Sum(ISNULL(Marked_For_Rework,0))
		,Isnull(#Header.WorkorderNo,0) --ER0388
		From #Header Left Outer Join ShiftProductionDetails ON
			#Header.[Day]=ShiftProductionDetails.pDate
			AND #Header.MachineID=ShiftProductionDetails.MachineID
			AND #Header.Shift=ShiftProductionDetails.Shift
			AND #Header.ComponentID=ShiftProductionDetails.ComponentID
			AND #Header.OperationNo=ShiftProductionDetails.OperationNo
			AND #Header.OperatorID=ShiftProductionDetails.OperatorID
			AND #Header.WorkorderNo=ShiftProductionDetails.WorkorderNumber
		Where #Header.Day>='''+ Convert(NvarChar(20),@CurDate) +''' and #Header.Day<='''+ Convert(NvarChar(20),@LastDate) +''' '
		Select @Strsql=@Strsql+@StrPlantID+@Strmachine+@StrShift+@StrGroupID
		Select @Strsql=@Strsql+'Group By #Header.Day,#Header.Shift,#Header.MachineID,#Header.ComponentID,#Header.OperationNo'
		Select @Strsql=@Strsql+',#Header.WorkorderNo' --ER0388
		EXEC(@Strsql)
		print(@strsql)

		
		-- Updating Rejection Count
		UPDATE #ProdData SET RejCount=ISNULL(T1.Rej,0) 
		FROM(
			Select pDate,Shift,MachineID,ComponentID,OperationNo,WorkOrderNumber,Sum(isnull(Rejection_Qty,0))Rej
			From ShiftProductionDetails Left Outer Join ShiftRejectionDetails ON ShiftProductionDetails.ID=ShiftRejectionDetails.ID
			Where pDate>=@CurDate and pdate<=@LastDate
			Group By pDate,Shift,MachineID,ComponentID,OperationNo,WorkOrderNumber		
		)AS T1 Inner Join #ProdData ON #ProdData.[Day]=T1.pDate And #ProdData.Shift=T1.Shift And #ProdData.MachineID=T1.MachineID And  #ProdData.ComponentID=T1.ComponentID And  #ProdData.OperationNo=T1.OperationNo and #ProdData.WorkorderNo=t1.WorkOrderNumber

		-----------------------------------------------------updating rejection reason in Day,Shift,MachineID,ComponentID,OperationNo,WorkorderNo starts--------------------------------------------------------
			
		UPDATE #ProdData SET RejectionReason=ISNULL(T1.RejReason,'') 
		FROM(
		select distinct Day,Shift,MachineID,ComponentID,OperationNo,WorkorderNo, STUFF((SELECT distinct ',' + L2.Rejection_Reason
        From ShiftProductionDetails l1 Left Outer Join ShiftRejectionDetails l2 ON l1.ID=l2.ID
		 where l1.pDate=l3.day and l1.shift=l3.shift and l1.MachineID=l3.MachineID and l1.ComponentID=l3.ComponentID and l1.OperationNo=l3.OperationNo and l1.WorkOrderNumber=l3.WorkorderNo
         FOR XML PATH(''), TYPE
         ).value('.', 'NVARCHAR(MAX)') 
        ,1,1,'') RejReason from #ProdData l3
		)AS T1 Inner Join #ProdData ON #ProdData.[Day]=T1.Day And #ProdData.Shift=T1.Shift And #ProdData.MachineID=T1.MachineID And  #ProdData.ComponentID=T1.ComponentID And  #ProdData.OperationNo=T1.OperationNo and #ProdData.WorkorderNo=t1.WorkorderNo

		-----------------------------------------------------updating rejection reason in Day,Shift,MachineID,ComponentID,OperationNo,WorkorderNo ends--------------------------------------------------------

		-----------------------------------------------------Coma seperated Operatorid list for Day,Shift,MachineID,ComponentID,OperationNo,WorkorderNo	--------------------------------------------------
		
		UPDATE #ProdData SET OperatorID=ISNULL(T1.StrOperatorid,''),OperatorName=isnull(t1.StrOperatorName,'') 
		FROM
		(
		select distinct Day,Shift,MachineID,ComponentID,OperationNo,WorkorderNo, STUFF((SELECT distinct ',' + L2.OperatorID
         from #header L2 
		 where l2.day=l3.day and l2.shift=l3.shift and l2.MachineID=l3.MachineID and l2.ComponentID=l3.ComponentID and l2.OperationNo=l3.OperationNo and l2.WorkorderNo=l3.WorkorderNo
         FOR XML PATH(''), TYPE
         ).value('.', 'NVARCHAR(MAX)') 
        ,1,1,'') StrOperatorid,
		 STUFF((SELECT distinct ',' + L2.OperatorName
         from #header L2 
		 where l2.day=l3.day and l2.shift=l3.shift and l2.MachineID=l3.MachineID and l2.ComponentID=l3.ComponentID and l2.OperationNo=l3.OperationNo and l2.WorkorderNo=l3.WorkorderNo
         FOR XML PATH(''), TYPE
         ).value('.', 'NVARCHAR(MAX)') 
        ,1,1,'') StrOperatorName from #header l3	
		)AS T1 Inner Join #ProdData ON #ProdData.[Day]=T1.Day And #ProdData.Shift=T1.Shift And #ProdData.MachineID=T1.MachineID And  #ProdData.ComponentID=T1.ComponentID And  #ProdData.OperationNo=T1.OperationNo and #ProdData.WorkorderNo=t1.WorkorderNo

-------------------------------------------------------------Coma seperated Operatorid and operatorName list for Day,Shift,MachineID,ComponentID,OperationNo,WorkorderNo--------------------------------------------------

		
		IF @Parameter='Shift' or @Parameter='Summary'
		BEGIN
			-- Calculate CN for Date-Shift-Machine
			UPDATE #ProdData SET CN=  ISNULL(T1.CN,0) 
			From(
				Select [Day],Shift,MachineID ,Sum(Isnull(CN,0))As CN
				From #ProdData Where ([Day]>=@CurDate and [day]<=@lastdate)
				Group By [Day],Shift,MachineID )AS T1 Inner Join #ProdData ON #ProdData.[Day]=T1.[Day] And #ProdData.Shift=T1.Shift And #ProdData.MachineID=T1.MachineID
				
			-- Calculate Down Time for Date-Shift-Machine
			UPDATE #ProdData SET DownTime = Isnull(#ProdData.Downtime,0)+IsNull(T1.DownTime,0)
			From (select dDate,Shift,MachineID,
			Sum(DownTime)As DownTime
				From ShiftDownTimeDetails
				Where (dDate>=@CurDate and ddate<=@lastdate)
				---mod 1 to neglect only threshold ML from dtime(commented following line)
				---And ML_Flag=0
			
				Group By dDate,Shift,MachineID
			) as T1 Inner Join #ProdData ON #ProdData.[Day]=T1.dDate And #ProdData.Shift=T1.Shift And #ProdData.MachineID=T1.MachineID
			---mod 1
			UPDATE #ProdData SET DownTimeAE = Isnull(#ProdData.DownTimeAE,0)+IsNull(T1.DownTime,0)
			From (select dDate,Shift,MachineID,
			Sum(DownTime)As DownTime
				From ShiftDownTimeDetails
				Where (dDate>=@CurDate and ddate<=@lastdate)
				Group By dDate,Shift,MachineID
			) as T1 Inner Join #ProdData ON #ProdData.[Day]=T1.dDate And #ProdData.Shift=T1.Shift And #ProdData.MachineID=T1.MachineID

			UPDATE #ProdData SET MgmtLoss = Isnull(#ProdData.MgmtLoss,0)+IsNull(T1.LOSS,0)
			From (select dDate,Shift,MachineID,
			sum(
				 CASE
				WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0
				THEN isnull(ShiftDownTimeDetails.Threshold,0)
				ELSE ShiftDownTimeDetails.DownTime
				 END) AS LOSS
				From ShiftDownTimeDetails
				Where (dDate>=@CurDate and ddate<=@lastdate) and ShiftDownTimeDetails.Ml_Flag=1
				Group By dDate,Shift,MachineID
			) as T1 Inner Join #ProdData ON #ProdData.[Day]=T1.dDate And #ProdData.Shift=T1.Shift And #ProdData.MachineID=T1.MachineID
			
			---mod 1 to neglect only threshold ML from dtime
			UPDATE #ProdData SET DownTime=isnull(DownTime,0)-isnull(MgmtLoss,0)
			---mod 1
	
			/*CASE
				WHEN (StartTime>=@FromTime And EndTime<=@ToTime) THEN DateDiff(second,StartTime,EndTime)
				WHEN (StartTime<@FromTime And EndTime>@FromTime And EndTime<=@ToTime)THEN DateDiff(second, @FromTime, EndTime)
				WHEN (StartTime>=@FromTime And StartTime<@ToTime And EndTime>@ToTime) THEN DateDiff(second, StartTime, @ToTime)
				WHEN (StartTime<@FromTime And EndTime>@ToTime) THEN DateDiff(second, @FromTime, @ToTime)
	 		End */
			-- Calculate Utilised Time  for Date-Shift-Machine
			UPDATE #ProdData SET UtilisedTime = Isnull(#ProdData.UtilisedTime,0)+IsNull(T1.UtilisedTime,0)
			From (select pDate,Shift,MachineID,Sum(Sum_of_ActCycleTime)As UtilisedTime
			From ShiftProductionDetails
			Where (pDate>=@CurDate and pdate<=@LastDate)
			Group By pDate,Shift,MachineID
			) as T1 Inner Join #ProdData ON #ProdData.[Day]=T1.pDate And #ProdData.Shift=T1.Shift And #ProdData.MachineID=T1.MachineID	
			--ER0135-ER0138-karthikg-Machinewise-shift--s_GetShiftAgg_ProductionReport '2007-12-01','2007-12-01','DAY','','MC 01','','MachineWise','Shift'========

			UPDATE #ProdData SET UtilisedTime = Isnull(#ProdData.UtilisedTime,0)+IsNull(T1.MinorDownTime,0)
			From (SELECT ddate,Shift,MachineID,sum(datediff(s,starttime,endtime)) as MinorDownTime --componentid,operationno,
			FROM ShiftDownTimeDetails WHERE PE_Flag = 1--downid in (select downid from downcodeinformation where prodeffy = 1)
			and (dDate>=@CurDate and ddate<=@LastDate) group by ddate,shift,machineid--,componentid,operationno
			) as T1 Inner Join #ProdData ON #ProdData.[Day]=T1.ddate And #ProdData.Shift=T1.Shift And
			#ProdData.MachineID=T1.MachineID --And #ProdData.ComponentID=T1.componentid And #ProdData.OperationNo=T1.operationno
			--ER0135-ER0138===============================================================================================
			-- Calculate QEffy for Date-Shift-Machine
			/*UPDATE #ProdData SET QEffy=IsNull(T1.QE,0)
			FROM(Select [Day],Shift,MachineID,
			CAST((Sum(ProdCount)-Sum(RepeatCycle)-Sum(DummyCycle)-Sum(RejCount)+Sum(ReworkPerformed))As Float)/CAST((Sum(ProdCount)-Sum(RepeatCycle)-Sum(DummyCycle)+Sum(ReworkPerformed)) AS Float)As QE
			From #ProdData
			Group By [Day],Shift,MachineID )AS T1 Inner Join #ProdData ON #ProdData.[Day]=T1.[Day] And #ProdData.Shift=T1.Shift And #ProdData.MachineID=T1.MachineID
			*/
			
			/* Commented By DR0292 To Handle Divide By Zero Error.
			UPDATE #ProdData SET QEffy=IsNull(T1.QE,0)
			FROM(Select [Day],Shift,MachineID,
			CAST((Sum(AcceptedParts))As Float)/CAST((Sum(AcceptedParts)+Sum(RejCount)+Sum(MarkedForRework)) AS Float)As QE
			From #ProdData
			Group By [Day],Shift,MachineID )AS T1 Inner Join #ProdData ON #ProdData.[Day]=T1.[Day] And #ProdData.Shift=T1.Shift And #ProdData.MachineID=T1.MachineID
			*/

			
			UPDATE #ProdData SET QEffy=IsNull(T1.QE,0)
			FROM(Select [Day],Shift,MachineID,
			CAST((Sum(AcceptedParts))As Float)/CAST((Sum(AcceptedParts)+Sum(RejCount)+Sum(MarkedForRework)) AS Float)As QE
			From #ProdData 
			where AcceptedParts>0 --DR0292 Added.
			Group By [Day],Shift,MachineID )AS T1 Inner Join #ProdData ON #ProdData.[Day]=T1.[Day] And #ProdData.Shift=T1.Shift And #ProdData.MachineID=T1.MachineID

		--UPDATE #ProdData SET RejCount=ISNULL(T1.Rej,0) 
		--FROM(
		--	Select pDate,Shift,MachineID,ComponentID,OperationNo,WorkOrderNumber,Sum(isnull(Rejection_Qty,0))Rej
		--	From ShiftProductionDetails Left Outer Join ShiftRejectionDetails ON ShiftProductionDetails.ID=ShiftRejectionDetails.ID
		--	Where pDate>=@CurDate and pdate<=@LastDate
		--	Group By pDate,Shift,MachineID,ComponentID,OperationNo,WorkOrderNumber		
		--)AS T1 Inner Join #ProdData ON #ProdData.[Day]=T1.pDate And #ProdData.Shift=T1.Shift And #ProdData.MachineID=T1.MachineID And  #ProdData.ComponentID=T1.ComponentID And  #ProdData.OperationNo=T1.OperationNo and #ProdData.WorkorderNo=t1.WorkOrderNumber

			----------------------------------------------Operator names for given day,shift,machine,comp,operation,workordernumber level----------------------------------------------------------------

			

		END
		ELSE
		IF @Parameter='Day'
		BEGIN
			-- Calculate CN for Date-Machine
			UPDATE #ProdData SET CN=ISNULL(T1.CN,0) 
			From(
				Select [Day],MachineID ,Sum(CN)As CN
				From #ProdData Where ([Day]>=@CurDate and [day]<=@LastDate)
				Group By [Day],MachineID )AS T1 Inner Join #ProdData ON #ProdData.[Day]=T1.[Day] And  #ProdData.MachineID=T1.MachineID

				UPDATE #ProdData SET TargetCount=ISNULL(T1.TargetCount,0) 
			FROM(
				Select pDate,SD.Shift,SD.MachineID,SD.ComponentID,SD.OperationNo,Sum(isnull(L.IdealCount,0))TargetCount
				From ShiftProductionDetails SD inner join LoadSchedule L on
				  L.Machine =SD.MachineID and L.Component = SD.ComponentID and L.Operation = SD.OperationNo 
	            and L.date =SD.pDate and L.Shift = SD.Shift
				Where pDate >= @StartDate AND pDate <= @EndDate
				Group By pDate,SD.Shift,SD.MachineID,SD.ComponentID,SD.OperationNo		
			)AS T1 Inner Join #ProdData ON #ProdData.[Day]=T1.pDate And #ProdData.Shift=T1.Shift And #ProdData.MachineID=T1.MachineID And  #ProdData.ComponentID=T1.ComponentID And  #ProdData.OperationNo=T1.OperationNo
	
			-- Calculate DownTime for Date-Machine
			UPDATE #ProdData SET DownTime = Isnull(#ProdData.Downtime,0) + IsNull(T1.DownTime,0)
			From (select dDate,MachineID,
			Sum(DownTime)As DownTime
				From ShiftDownTimeDetails
				Where (dDate>=@CurDate and ddate<=@LastDate)
				---mod 1 to neglect only threshold ML from dtime(commented below line
				---And ML_Flag=0
				Group By dDate,MachineID
			) as T1 Inner Join #ProdData ON #ProdData.[Day]=T1.dDate  And #ProdData.MachineID=T1.MachineID
	
			
			---mod 1
			UPDATE #ProdData SET DownTimeAE = Isnull(#ProdData.DownTimeAE,0)+IsNull(T1.DownTime,0)
			From (select dDate,MachineID,
			Sum(DownTime)As DownTime
				From ShiftDownTimeDetails
				Where (dDate>=@CurDate and ddate<=@LastDate)
				Group By dDate,MachineID
			) as T1 Inner Join #ProdData ON #ProdData.[Day]=T1.dDate  And #ProdData.MachineID=T1.MachineID
         
			UPDATE #ProdData SET MgmtLoss = Isnull(#ProdData.MgmtLoss,0)+IsNull(T1.LOSS,0)
			From (select dDate,MachineID,
			sum(
				 CASE
				WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0
				THEN isnull(ShiftDownTimeDetails.Threshold,0)
				ELSE ShiftDownTimeDetails.DownTime
				 END) AS LOSS
				From ShiftDownTimeDetails
				Where (dDate>=@CurDate and ddate<=@lastdate) and ShiftDownTimeDetails.Ml_Flag=1
				Group By dDate,MachineID
			) as T1 Inner Join #ProdData ON #ProdData.[Day]=T1.dDate And #ProdData.MachineID=T1.MachineID
	
			---mod 1 to neglect only threshold ML from dtime
			UPDATE #ProdData SET DownTime=isnull(DownTime,0)-isnull(MgmtLoss,0)
			---mod 1
			
			-- Calculate UtilisedTime for Date-Machine
			UPDATE #ProdData SET UtilisedTime = Isnull(#ProdData.UtilisedTime,0)+IsNull(T1.UtilisedTime,0)
			From (select pDate,MachineID,Sum(Sum_of_ActCycleTime)As UtilisedTime
			From ShiftProductionDetails
			Where (pDate>=@CurDate and pdate<=@lastdate)
			Group By pDate,MachineID
			) as T1 Inner Join #ProdData ON #ProdData.[Day]=T1.pDate  And #ProdData.MachineID=T1.MachineID	
	
			
			--ER0135-ER0138-karthikg-Machinewise-day-s_GetShiftAgg_ProductionReport '2007-12-01','2007-12-01','DAY','','MC 01','','MachineWise','Day'
			UPDATE #ProdData SET UtilisedTime = Isnull(#ProdData.UtilisedTime,0)+IsNull(T1.MinorDownTime,0)
			From (SELECT ddate,MachineID,sum(datediff(s,starttime,endtime)) as MinorDownTime
			FROM ShiftDownTimeDetails WHERE PE_Flag = 1--downid in (select downid from downcodeinformation where prodeffy = 1)
			and (dDate>=@CurDate and ddate<=@LastDate) group by ddate,machineid
			) as T1 Inner Join #ProdData ON #ProdData.[Day]=T1.ddate And #ProdData.MachineID=T1.MachineID
			--ER0135-ER0138=========================================================================================
			-- Calculate QEffy for Date-Machine

			--UPDATE #ProdData SET QEffy=IsNull(T1.QE,0)  --DR0292
			UPDATE #ProdData SET QEffy= ISNULL(#ProdData.QEffy,0) + IsNull(T1.QE,0) --DR0292
			FROM(Select [Day],MachineID,
			CAST((Sum(AcceptedParts))As Float)/CAST((Sum(AcceptedParts)+Sum(RejCount)+Sum(MarkedForRework)) AS Float)As QE
			From #ProdData
			where AcceptedParts>0 --DR0292
			Group By [Day],MachineID )AS T1 Inner Join #ProdData ON #ProdData.[Day]=T1.[Day]  And #ProdData.MachineID=T1.MachineID
		END
		
		
		UPDATE #ProdData
		SET
			PEffy = (CN/UtilisedTime) ,
			---comment for mod 1
			-----AEffy = (UtilisedTime)/(UtilisedTime +ISNULL( DownTime,0))
			---till here
			AEffy = (UtilisedTime)/(UtilisedTime +ISNULL( DownTimeAE,0)-isnull(MgmtLoss,0))
		WHERE UtilisedTime <> 0


		--UPDATE #ProdData SET
		--	OEffy = PEffy * AEffy * QEffy * 100,
		--	PEffy = PEffy * 100 ,
		--	AEffy = AEffy * 100,
		--	QEffy = QEffy * 100
			
		UPDATE #ProdData SET
		OEffy = CASE WHEN (SELECT OEEFormula FROM MachineOEEFormula_Shanti where MachineID = #ProdData.MachineID) = 'AE'
						THEN (AEffy*100)
					WHEN (SELECT OEEFormula FROM MachineOEEFormula_Shanti where MachineID = #ProdData.MachineID) = 'AE*PE'
						THEN (AEffy * ISNULL(PEffy,1))*100
					ELSE  (PEffy * AEffy * ISNULL(QEffy,1))*100
				END,  
		PEffy = PEffy * 100 ,
		AEffy = AEffy * 100,
		QEffy = QEffy * 100


		IF @Parameter='Shift' 
		Begin
			Select
			[Day]  ,
			p1.Shift  ,
			p1.MachineID  ,
			p1.OperatorID,
			p1.OperatorName,
			p1.ComponentID ,
			p1.OperationNo ,
			dbo.f_formattime(isnull(StdCycleTime,0),@timeformat) As StdCycleTime ,
			dbo.f_formattime(isnull(AvgCycleTime,0),@timeformat) As AvgCycleTime ,
			dbo.f_formattime(isnull(StdLoadUnload,0),@timeformat) As StdLoadUnload ,
			dbo.f_formattime(isnull(AvgLoadUnload,0),@timeformat) As AvgLoadUnload ,
			CycleEffy =
			CASE
			   when ( Isnull(StdCycleTime,0) > 0 and
				  Isnull(AvgCycleTime,0) > 0
				) Then (StdCycleTime/AvgCycleTime)*100
			   Else 0
			END,
			LoadUnloadEffy =
			CASE
			   when ( Isnull(StdLoadUnload,0) > 0 and
				  Isnull(AvgLoadUnload,0) > 0
				) Then (StdLoadUnload/AvgLoadUnload)*100
			   Else 0
			END,
			Isnull(ProdCount,0)ProdCount  ,
			Isnull(p1.AcceptedParts,0)AcceptedParts,
			Isnull(RejCount,0)RejCount  ,
			isnull(RejectionReason,'') as RejectionReason,
			RepeatCycle ,
			DummyCycle ,
			ReworkPerformed ,
			MarkedForRework,
			Isnull(AEffy,0)AEffy  ,
			Isnull(PEffy,0)PEffy ,
			Isnull(QEffy,0)QEffy  ,
			Isnull(OEffy,0)OEffy  ,
			dbo.f_formattime(isnull(UtilisedTime,0),@timeformat) As UtilisedTime  ,
			dbo.f_formattime(isnull(DownTime,0),@timeformat) As DownTime  ,
			dbo.f_formattime(isnull(MgmtLoss,0),@timeformat) As MgmtLoss
			,WorkorderNo,s.GroupID --ER0388
			From #ProdData p1
			left outer join PlantMachineGroups s on s.MachineID=p1.MachineID
			--Order By [Day],MachineID --10/Mar/2009 Karthik G :: ER0175
			Order By [Day],p1.Shift,p1.MachineID,p1.ComponentID,p1.OperationNo
		END

		if @Parameter='Day'
		Begin
			Select
			[Day]  ,
			p1.Shift  ,
			p1.MachineID  ,
			p1.OperatorID,
			p1.OperatorName,
			p1.ComponentID ,
			p1.OperationNo ,
			dbo.f_formattime(isnull(StdCycleTime,0),@timeformat) As StdCycleTime ,
			dbo.f_formattime(isnull(AvgCycleTime,0),@timeformat) As AvgCycleTime ,
			dbo.f_formattime(isnull(StdLoadUnload,0),@timeformat) As StdLoadUnload ,
			dbo.f_formattime(isnull(AvgLoadUnload,0),@timeformat) As AvgLoadUnload ,
			CycleEffy =
			CASE
			   when ( Isnull(StdCycleTime,0) > 0 and
				  Isnull(AvgCycleTime,0) > 0
				) Then (StdCycleTime/AvgCycleTime)*100
			   Else 0
			END,
			LoadUnloadEffy =
			CASE
			   when ( Isnull(StdLoadUnload,0) > 0 and
				  Isnull(AvgLoadUnload,0) > 0
				) Then (StdLoadUnload/AvgLoadUnload)*100
			   Else 0
			END,
			Isnull(ProdCount,0)ProdCount  ,
			Isnull(p1.AcceptedParts,0)AcceptedParts,
			Isnull(RejCount,0)RejCount  ,
			isnull(RejectionReason,'') as RejectionReason,
			RepeatCycle ,
			DummyCycle ,
			ReworkPerformed ,
			MarkedForRework,
			Isnull(AEffy,0)AEffy  ,
			Isnull(PEffy,0)PEffy ,
			Isnull(QEffy,0)QEffy  ,
			Isnull(OEffy,0)OEffy  ,
			dbo.f_formattime(isnull(UtilisedTime,0),@timeformat) As UtilisedTime  ,
			dbo.f_formattime(isnull(DownTime,0),@timeformat) As DownTime  ,
			dbo.f_formattime(isnull(MgmtLoss,0),@timeformat) As MgmtLoss
			,WorkorderNo --ER0388
			,Isnull(TargetCount,0)TargetCount ,
			s.GroupID
			From #ProdData p1
			left outer join PlantMachineGroups s on s.MachineID=p1.MachineID
			--Order By [Day],MachineID --10/Mar/2009 Karthik G :: ER0175
			Order By [Day],p1.MachineID,p1.Shift,p1.ComponentID,p1.OperationNo
		END

		If @Parameter='Summary'
		Begin
			
			Insert into #Summary(ProdCount,AcceptedParts,RejCount,RepeatCycle,DummyCycle,ReworkPerformed,MarkedForRework,UtilisedTime,DownTime,MgmtLoss)
			Select isnull(SUM(ProdCount),0)ProdCount,Isnull(SUM(AcceptedParts),0)AcceptedParts,
			Isnull(SUM(RejCount),0)RejCount,SUM(RepeatCycle) as RepeatCycle ,
			SUM(DummyCycle) DummyCycle,SUM(ReworkPerformed) ReworkPerformed ,
			SUM(MarkedForRework) MarkedForRework,0,0,0
			From #ProdData
	
			update #Summary set StdCycleTime=T1.StdCycleTime,AvgCycleTime=T1.AvgCycleTime,StdLoadUnload=T1.StdLoadUnload,AvgLoadUnload=T1.AvgLoadUnload,
			CycleEffy=T1.CycleEffy,LoadUnloadEffy=T1.LoadUnloadEffy From
			(Select 
			isnull(SUM(StdCycleTime),0) As StdCycleTime ,
			isnull(SUM(AvgCycleTime),0) As AvgCycleTime ,
			isnull(SUM(StdLoadUnload),0) As StdLoadUnload ,
			isnull(SUM(AvgLoadUnload),0) As AvgLoadUnload ,
			CycleEffy =
			CASE
			   when ( Isnull(sum(StdCycleTime),0) > 0 and
				  Isnull(SUM(AvgCycleTime),0) > 0
				) Then (SUM(StdCycleTime)/SUM(AvgCycleTime))*100
			   Else 0
			END,
			LoadUnloadEffy =
			CASE
			   when ( Isnull(SUM(StdLoadUnload),0) > 0 and
				  Isnull(SUM(AvgLoadUnload),0) > 0
				) Then (SUM(StdLoadUnload)/SUM(AvgLoadUnload))*100
			   Else 0
			END From (Select Distinct MachineID,Shift,ComponentID,OperationNo,StdCycleTime,AvgCycleTime,StdLoadUnload,AvgLoadUnload from #ProdData)T
			)T1

				
			update #Summary set UtilisedTime=T.UtilisedTime,DownTime=T.DownTime,MgmtLoss=T.MgmtLoss FROM(
			Select SUM(isnull(UtilisedTime,0))As UtilisedTime,SUM(isnull(DownTime,0)) As DownTime,SUM(isnull(MgmtLoss,0)) As MgmtLoss From
			(Select Distinct MachineID,Shift,UtilisedTime,DownTime,MgmtLoss from #ProdData)T1)T


			update #Summary set AEffy=T1.AEffy From
			(Select	Avg(Isnull(AEffy,0))AEffy FROM (Select distinct Machineid,Shift,AEffy from #ProdData where AEffy>0)T)T1

			update #Summary set PEffy=T1.PEffy From
			(Select	Avg(Isnull(PEffy,0))PEffy FROM (Select distinct Machineid,Shift,PEffy from #ProdData where PEffy>0)T)T1

			update #Summary set OEffy=T1.OEffy From
			(Select	Avg(Isnull(OEffy,0))OEffy FROM(Select distinct Machineid,Shift,OEffy from #ProdData where OEffy>0)T)T1

			update #Summary set QEffy=T1.QEffy From
			(Select	Avg(Isnull(QEffy,0))QEffy FROM(Select distinct Machineid,Shift,QEffy from #ProdData where QEffy>0)T)T1

			Select dbo.f_formattime(StdCycleTime,@timeformat) as StdCycleTime,
			dbo.f_formattime(AvgCycleTime,@timeformat) as AvgCycleTime,
			dbo.f_formattime(StdLoadUnload,@timeformat) as StdLoadUnload,
			dbo.f_formattime(AvgLoadUnload,@timeformat) as AvgLoadUnload,CycleEffy,LoadUnloadEffy,ProdCount,
			AcceptedParts,RejCount,RepeatCycle,DummyCycle,ReworkPerformed,MarkedForRework,
			dbo.f_formattime(UtilisedTime,@timeformat) as UtilisedTime,
			dbo.f_formattime(DownTime,@timeformat) as DownTime,
			dbo.f_formattime(MgmtLoss,@timeformat) as MgmtLoss,ISNULL(AEffy,0) AS AEffy ,ISNULL(PEffy,0) AS PEffy,ISNULL(QEffy,0) AS QEffy ,ISNULL(OEffy,0) AS OEffy from #Summary
		END

	END
	If @Parameter='Consolidated' or @Parameter='ConsolidatedForMatrixReport'
	BEGIN
		If isnull(@PlantID,'') <> ''
		Begin
			---mod 2
--			Select @StrPlantID = ' And ( PlantMachine.PlantID = ''' + @PlantID + ''' )'
			Select @StrPlantID = ' And ( PlantMachine.PlantID = N''' + @PlantID + ''' )'
			---mdo 2
		End
		SELECT @StrTPMMachines=''
		IF ( SELECT TOP 1 ValueInText FROM  CockpitDefaults WHERE Parameter='TpmEnbMac')='E'  
		BEGIN  
		 SET  @StrTPMMachines = ' AND M.TPMTrakEnabled = 1 '  
		END  
		ELSE  
		BEGIN  
		 SET  @StrTPMMachines = ' '  
		END
		If isnull(@Machineid,'') <> ''
		Begin	
		Select @Strmachine = ' And ( M.MachineID IN (' + @MachineID + '))'
		End
		If isnull(@GroupID,'') <> ''
		Begin
		Select @StrGroupid = ' And ( PlantMachineGroups.GroupID IN (' + @GroupID + '))'
		End

		-- Inserting distinct Machines of the given plant
		SELECT @StrSql='INSERT INTO #ProdData(
		 MachineID ,PEffy ,AEffy ,QEffy,OEffy ,
		 ProdCount ,AcceptedParts,RejCount,MarkedForRework,UtilisedTime ,DownTime ,CN )
		 SELECT Distinct M.MachineID,0,0,0,0,0,0,0,0 ,0,0,0
		 FROM Machineinformation M
		 Left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
		 LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID
		 Where M.Interfaceid>''0'''
		 SELECT @StrSql=@StrSql+ @StrPlantID+ @Strmachine + @StrTPMMachines +@StrGroupID
		 Print @StrSql
		 EXEC(@StrSql)

		--Updating ProdCount for the selected time period
		SELECT @StrSql='Update #ProdData Set ProdCount=ISNULL(T2.ProdCount,0) 
		From (Select MachineID,Sum(Prod_Qty)AS ProdCount From ShiftProductionDetails
		Where pDate>='''+Convert(NvarChar(20),@StartDate)+''' and pDate<='''+Convert(NvarChar(20),@EndDate)+''''
		SELECT @StrSql=@StrSql+' Group By MachineID)AS T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
		print @StrSql
		EXEC(@StrSql)
		
		--Updating AcceptedParts for the selected time period
		SELECT @StrSql='Update #ProdData Set AcceptedParts=ISNULL(T2.AcceptedParts,0) 
		From (Select MachineID,Sum(AcceptedParts)AS AcceptedParts From ShiftProductionDetails
		Where pDate>='''+Convert(NvarChar(20),@StartDate)+''' and pDate<='''+Convert(NvarChar(20),@EndDate)+''''
		SELECT @StrSql=@StrSql+' Group By MachineID)AS T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
		print @StrSql
		EXEC(@StrSql)

		--Updating MarkedForRework for the selected time period
		SELECT @StrSql='Update #ProdData Set MarkedForRework=ISNULL(T2.MarkedForRework,0) 
		From (Select MachineID,Sum(Marked_For_Rework)AS MarkedForRework From ShiftProductionDetails
		Where pDate>='''+Convert(NvarChar(20),@StartDate)+''' and pDate<='''+Convert(NvarChar(20),@EndDate)+''''
		SELECT @StrSql=@StrSql+' Group By MachineID)AS T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
		print @StrSql
		EXEC(@StrSql)
		
		--Updating RejCount for the selected time period
		SELECT @StrSql='Update #ProdData Set RejCount=ISNULL(T2.RejCount,0) 
		From (Select MachineID,Sum(Rejection_Qty)AS RejCount From ShiftProductionDetails
		Inner Join ShiftRejectionDetails On ShiftProductionDetails.ID=ShiftRejectionDetails.ID
		Where pDate>='''+Convert(NvarChar(20),@StartDate)+''' and pDate<='''+Convert(NvarChar(20),@EndDate)+''''
		SELECT @StrSql=@StrSql+' Group By MachineID)AS T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
		EXEC(@StrSql)

		--Updating CN for the selected time period
		Update #ProdData Set CN=ISNULL(T2.CN,0) 
		From (
		Select MachineID,sum(Prod_Qty *(CO_StdMachiningTime+CO_StdLoadUnload)) AS CN
		From ShiftProductionDetails
		Where pDate>=@StartDate and pDate<=@EndDate
		Group By MachineID )AS T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID
		
		
		--Updating UtilisedTime for the selected time period
		SELECT @StrSql='UPDATE #ProdData SET UtilisedTime = IsNull(T2.UtilisedTime,0) 
		From (select MachineID,Sum(Sum_of_ActCycleTime)As UtilisedTime
		From ShiftProductionDetails
		Where pDate>='''+Convert(NvarChar(20),@StartDate)+''' and pDate<='''+Convert(NvarChar(20),@EndDate)+''''
		SELECT @StrSql=@StrSql+' Group By MachineID) as T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
		EXEC(@StrSql)

		--ER0135-ER0138-karthikg-Machinewise-Consolidated-s_GetShiftAgg_ProductionReport '2007-12-01','2007-12-01','','','','','MachineWise','Consolidated'
		SELECT @StrSql='UPDATE #ProdData SET UtilisedTime = Isnull(#ProdData.UtilisedTime,0)+IsNull(T2.MinorDownTime,0)
		From (SELECT MachineID,sum(datediff(s,starttime,endtime)) as MinorDownTime
			FROM ShiftDownTimeDetails WHERE PE_Flag = 1
		and ddate>='''+Convert(NvarChar(20),@StartDate)+''' and dDate<='''+Convert(NvarChar(20),@EndDate)+''''
		SELECT @StrSql=@StrSql+' group by machineid) as T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
		--print @StrSql
		EXEC(@StrSql)

		--ER0135-ER0138=================================================================================================================================================
		--Updating DownTime for the selected time period
		---commented ML_flag=0 to neglect only threshold value from Mgmtloss
		--SELECT @StrSql='Update #ProdData Set DownTime=ISNULL(T2.DownTime,0) --DR0292
		SELECT @StrSql='Update #ProdData Set DownTime=ISNULL(#ProdData.DownTime,0) + ISNULL(T2.DownTime,0)  --DR0292
		From (Select MachineID,Sum(DownTime)AS DownTime From ShiftDownTimeDetails
		Where dDate>='''+Convert(NvarChar(20),@StartDate)+''' and dDate<='''+Convert(NvarChar(20),@EndDate)+''' '-- And ML_Flag=0'
		SELECT @StrSql=@StrSql+' Group By MachineID)AS T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
		EXEC(@StrSql)

		---mod 1
			--SELECT @StrSql='Update #ProdData Set DownTimeAE=ISNULL(T2.DownTime,0) --DR0292
			SELECT @StrSql='Update #ProdData Set DownTimeAE=ISNULL(#ProdData.DownTimeAE,0) + ISNULL(T2.DownTime,0) --DR0292
			From (Select MachineID,Sum(DownTime)AS DownTime From ShiftDownTimeDetails
			Where dDate>='''+Convert(NvarChar(20),@StartDate)+''' and dDate<='''+Convert(NvarChar(20),@EndDate)+''' '
			SELECT @StrSql=@StrSql+' Group By MachineID)AS T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
			EXEC(@StrSql)

			SELECT @StrSql=' UPDATE #ProdData SET MgmtLoss = Isnull(#ProdData.MgmtLoss,0)+IsNull(T1.LOSS,0)
			From (select MachineID,
			sum(
				 CASE
				WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0
				THEN isnull(ShiftDownTimeDetails.Threshold,0)
				ELSE ShiftDownTimeDetails.DownTime
				 END) AS LOSS
				From ShiftDownTimeDetails
				Where dDate>='''+Convert(NvarChar(20),@StartDate)+''' and dDate<='''+Convert(NvarChar(20),@EndDate)+''' and ShiftDownTimeDetails.Ml_Flag=1 '
			SELECT @StrSql=@StrSql+' Group By MachineID
			) as T1 Inner Join #ProdData ON  #ProdData.MachineID=T1.MachineID '
			EXEC(@StrSql)
		---mod 1

		----to exclude threshold of ML from Downtime
		--UPDATE #ProdData SET DownTime=DownTime-MgmtLoss --DR0292
		UPDATE #ProdData SET DownTime=isnull(DownTime,0)-isnull(MgmtLoss,0) --DR0292

		---mod 1

		--Updating QEffy for the selected time period
		/*UPDATE #ProdData SET QEffy=IsNull(T1.QE,0)
		FROM(Select MachineID,
		CAST((Sum(Prod_Qty)-Sum(IsNull(Repeat_Cycles,0))-Sum(IsNull(Dummy_Cycles,0))-Sum(IsNull(Rejection_Qty,0))+Sum(IsNull(Rework_Performed,0)))As Float)/CAST((Sum(IsNull(Prod_Qty,0))-Sum(IsNull(Repeat_Cycles,0))-Sum(IsNull(Dummy_Cycles,0))+Sum(IsNull(Rework_Performed,0))) AS Float)As QE
		From ShiftProductionDetails Left Outer Join  ShiftRejectionDetails on ShiftProductionDetails.ID=ShiftRejectionDetails.ID
		Group By MachineID )AS T1 Inner Join #ProdData ON  #ProdData.MachineID=T1.MachineID
		*/

		--UPDATE #ProdData SET QEffy=IsNull(T1.QE,0) --DR0292
		UPDATE #ProdData SET QEffy= ISNULL(#ProdData.QEffy,0) + IsNull(T1.QE,0) --DR0292
		FROM(Select MachineID,
		CAST((Sum(AcceptedParts))As Float)/CAST((Sum(IsNull(AcceptedParts,0))+Sum(IsNull(MarkedForRework,0))+Sum(IsNull(RejCount,0))) AS Float)As QE
		From #ProdData Where AcceptedParts<>0 Group By MachineID
		)AS T1 Inner Join #ProdData ON  #ProdData.MachineID=T1.MachineID
		
		UPDATE #ProdData
		SET
			PEffy = (CN/UtilisedTime) ,
			---commented for mod 1
			----AEffy = (UtilisedTime)/(UtilisedTime + ISNULL( DownTime,0))
			---till here
			AEffy = (UtilisedTime)/(UtilisedTime + ISNULL( DownTimeAE,0)-isnull(MgmtLoss,0))
		WHERE UtilisedTime <> 0

			UPDATE #ProdData
			SET
			OEffy = CASE WHEN (SELECT OEEFormula FROM MachineOEEFormula_Shanti where MachineID = #ProdData.MachineID) = 'AE'
						THEN (AEffy*100)
					WHEN (SELECT OEEFormula FROM MachineOEEFormula_Shanti where MachineID = #ProdData.MachineID) = 'AE*PE'
						THEN (AEffy * ISNULL(PEffy,1))*100
					ELSE  (PEffy * AEffy * ISNULL(QEffy,1))*100
					END,
			PEffy = PEffy * 100 ,
			AEffy = AEffy * 100,
			QEffy = QEffy * 100
			
		IF @Parameter='Consolidated'
		Begin
			Select
			#ProdData.MachineID,
			Isnull(ProdCount,0)ProdCount  ,
			Isnull(AcceptedParts,0)AcceptedParts,
			Isnull(RejCount,0)RejCount  ,
			ISNULL(MarkedForRework,0)Rework,
			Isnull(AEffy,0)AEffy  ,
			Isnull(PEffy,0)PEffy ,
			Isnull(OEffy,0)OEffy  ,
			Isnull(QEffy,0)QEffy  ,
			dbo.f_formattime(isnull(UtilisedTime,0),@timeformat) As UtilisedTime  ,
			dbo.f_formattime(isnull(DownTime,0),@timeformat) As DownTime,
			dbo.f_formattime(isnull(UtilisedTime,0)+isnull(DownTime,0),@timeformat) As totaltime,
			p2.GroupID
			From #ProdData 
			left outer join PlantMachineGroups p2 on #ProdData.MachineID=p2.MachineID
			Order By #ProdData.MachineID
		End
		If @Parameter='ConsolidatedForMatrixReport'
		Begin

			--Declare @CountOfMc as int
			--Select @CountOfMc=count(MachineID) from #ProdData where (UtilisedTime>0 or DownTime>0)

			--INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)
			--EXEC s_GetShiftTime @StartDate,''
			--select @FromTime = (select TOP 1 ShiftStart from #ShiftDetails ORDER BY ShiftStart ASC)

			--INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)
			--EXEC s_GetShiftTime @EndDate,''
			--select @ToTime = (select TOP 1 ShiftEnd from #ShiftDetails ORDER BY ShiftEnd DESC)

			Select dbo.f_formattime(isnull(SUM(UtilisedTime),0),'hh') As UtilisedTime,dbo.f_formattime(isnull(SUM(DownTime),0),'hh') As DownTime,
			dbo.f_formattime(isnull(SUM(MgmtLoss),0),'hh') As MgmtLoss,
			--dbo.f_formattime((datediff(second,@FromTime,@ToTime)*@CountOfMc),'hh') as TotalTime,
			dbo.f_formattime(isnull(SUM(UtilisedTime),0)+isnull(SUM(DownTime),0),'hh') As TotalTime,
			dbo.f_formattime(isnull(SUM(UtilisedTime),0),@timeformat) As CustomUtilisedTime,
			dbo.f_formattime(isnull(SUM(DownTime),0),@timeformat) As CustomDownTime,
			dbo.f_formattime(isnull(SUM(UtilisedTime),0)+isnull(SUM(DownTime),0),@timeformat) As CustomTotalTime,
			Isnull(SUM(ProdCount),0) as  ProdCount  ,
			Isnull(SUM(AcceptedParts),0) as AcceptedParts,
			Isnull(SUM(RejCount),0) as RejCount  ,
			ISNULL(SUM(MarkedForRework),0) as Rework,
			Isnull(Avg(AEffy),0) as AEffy  ,
			Isnull(Avg(PEffy),0) as PEffy ,
			Isnull(Avg(OEffy),0) as OEffy  ,
			Isnull(Avg(QEffy),0) as QEffy from #ProdData Where (UtilisedTime>0 or DownTime>0)
		End

	END

	If @Parameter='SONA_AggCockpit'
	BEGIN
		If isnull(@PlantID,'') <> ''
		Begin
			Select @StrPlantID = ' And ( PlantMachine.PlantID = N''' + @PlantID + ''' )'
		End
		SELECT @StrTPMMachines=''
		IF ( SELECT TOP 1 ValueInText FROM  CockpitDefaults WHERE Parameter='TpmEnbMac')='E'  
		BEGIN  
		 SET  @StrTPMMachines = ' AND M.TPMTrakEnabled = 1 '  
		END  
		ELSE  
		BEGIN  
		 SET  @StrTPMMachines = ' '  
		END 
		If isnull(@Machineid,'') <> ''
		Begin
		Select @Strmachine = ' And ( M.MachineID IN (' + @MachineID + '))'
		End
		If isnull(@GroupID,'') <> ''
		Begin
		Select @StrGroupid = ' And ( PlantMachineGroups.GroupID IN (' + @GroupID + '))'
		End

		Declare @Strsortorder as nvarchar(max)
		Select @Strsortorder= ''

		If ISNULL(@SortOrder,'')=''
		BEGIN
			SET @SortOrder = 'MachineID ASC'
		END

		If @SortType='CustomSortorder'
		Begin
			Select @Strsortorder= ' inner join MachinewiseSortOrder MS on #ProdData.Machineid=MS.Machineid Order By MS.SortOrder '
		END
		Else
		Begin
			Select @Strsortorder= ' order by #ProdData.' + @SortOrder + ' '
		END 
		-- Inserting distinct Machines of the given plant
		Select @Strsql=''
		SELECT @StrSql='INSERT INTO #ProdData(
		 MachineID ,PEffy ,AEffy ,QEffy,OEffy ,
		 ProdCount ,AcceptedParts,RejCount,MarkedForRework,UtilisedTime ,DownTime ,CN,
		 MachineDescription,PEGreen ,PERed,AEGreen ,AERed ,OEGreen ,OERed,QERed,QEGreen,Plantid,Groupid)
		 SELECT Distinct M.MachineID,0,0,0,0,0,0,0,0 ,0,0,0,
		 M.Description,isnull(M.PEGreen,0),isnull(M.PERed,0),isnull(M.AEGreen ,0),isnull(M.AERed,0),isnull(M.OEGreen ,0),isnull(M.OERed,0),isnull(M.QERed,0),isnull(M.QEGreen,0)
		 ,PlantMachine.Plantid,PlantMachineGroups.Groupid
		 FROM Machineinformation M
		 Left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
		 LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID
		 Where M.Interfaceid>''0'''
		 SELECT @StrSql=@StrSql+ @StrPlantID+ @Strmachine + @StrTPMMachines +@StrGroupID
		 Print @StrSql
		 EXEC(@StrSql)

		--Updating ProdCount for the selected time period
		SELECT @StrSql='Update #ProdData Set ProdCount=ISNULL(T2.ProdCount,0) 
		From (Select MachineID,Sum(Prod_Qty)AS ProdCount From ShiftProductionDetails
		Where pDate>='''+Convert(NvarChar(10),@StartDate,120)+''' and pDate<='''+Convert(NvarChar(10),@EndDate,120)+''''
		SELECT @StrSql=@StrSql+' Group By MachineID)AS T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
		print @StrSql
		EXEC(@StrSql)
		
		--Updating AcceptedParts for the selected time period
		SELECT @StrSql='Update #ProdData Set AcceptedParts=ISNULL(T2.AcceptedParts,0) 
		From (Select MachineID,Sum(AcceptedParts)AS AcceptedParts From ShiftProductionDetails
		Where pDate>='''+Convert(NvarChar(10),@StartDate,120)+''' and pDate<='''+Convert(NvarChar(10),@EndDate,120)+''''
		SELECT @StrSql=@StrSql+' Group By MachineID)AS T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
		print @StrSql
		EXEC(@StrSql)

		--Updating MarkedForRework for the selected time period
		SELECT @StrSql='Update #ProdData Set MarkedForRework=ISNULL(T2.MarkedForRework,0) 
		From (Select MachineID,Sum(Marked_For_Rework)AS MarkedForRework From ShiftProductionDetails
		Where pDate>='''+Convert(NvarChar(10),@StartDate,120)+''' and pDate<='''+Convert(NvarChar(10),@EndDate,120)+''''
		SELECT @StrSql=@StrSql+' Group By MachineID)AS T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
		print @StrSql
		EXEC(@StrSql)
		
		--Updating RejCount for the selected time period
		SELECT @StrSql='Update #ProdData Set RejCount=ISNULL(T2.RejCount,0) 
		From (Select MachineID,Sum(Rejection_Qty)AS RejCount From ShiftProductionDetails
		Inner Join ShiftRejectionDetails On ShiftProductionDetails.ID=ShiftRejectionDetails.ID
		Where pDate>='''+Convert(NvarChar(10),@StartDate,120)+''' and pDate<='''+Convert(NvarChar(10),@EndDate,120)+''''
		SELECT @StrSql=@StrSql+' Group By MachineID)AS T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
		EXEC(@StrSql)

		--Updating CN for the selected time period
		Update #ProdData Set CN=ISNULL(T2.CN,0) 
		From (
		Select MachineID,sum(Prod_Qty *(CO_StdMachiningTime+CO_StdLoadUnload)) AS CN
		From ShiftProductionDetails
		Where pDate>=Convert(NvarChar(10),@StartDate,120) and pDate<=Convert(NvarChar(10),@EndDate,120)
		Group By MachineID )AS T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID
		

		
		--Updating UtilisedTime for the selected time period
		SELECT @StrSql='UPDATE #ProdData SET UtilisedTime = IsNull(T2.UtilisedTime,0) 
		From (select MachineID,Sum(Sum_of_ActCycleTime)As UtilisedTime
		From ShiftProductionDetails
		Where pDate>='''+Convert(NvarChar(10),@StartDate,120)+''' and pDate<='''+Convert(NvarChar(10),@EndDate,120)+''''
		SELECT @StrSql=@StrSql+' Group By MachineID) as T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
		EXEC(@StrSql)


		--ER0135-ER0138-karthikg-Machinewise-Consolidated-s_GetShiftAgg_ProductionReport '2007-12-01','2007-12-01','','','','','MachineWise','Consolidated'
		SELECT @StrSql='UPDATE #ProdData SET UtilisedTime = Isnull(#ProdData.UtilisedTime,0)+IsNull(T2.MinorDownTime,0)
		From (SELECT MachineID,sum(datediff(s,starttime,endtime)) as MinorDownTime
			FROM ShiftDownTimeDetails WHERE PE_Flag = 1
		and ddate>='''+Convert(NvarChar(10),@StartDate,120)+''' and dDate<='''+Convert(NvarChar(10),@EndDate,120)+''''
		SELECT @StrSql=@StrSql+' group by machineid) as T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
		--print @StrSql
		EXEC(@StrSql)


		SELECT @StrSql='UPDATE #ProdData SET productionpdt = IsNull(T2.prodpdt,0) 
		From (select MachineID,Sum(pdt)As prodpdt
		From ShiftProductionDetails
		Where pDate>='''+Convert(NvarChar(10),@StartDate,120)+''' and pDate<='''+Convert(NvarChar(10),@EndDate,120)+''''
		SELECT @StrSql=@StrSql+' Group By MachineID) as T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
		EXEC(@StrSql)

		SELECT @StrSql='UPDATE #ProdData SET downpdt = IsNull(T2.dnpdt,0) 
		From (select MachineID,Sum(pdt)As dnpdt
		From ShiftDownTimeDetails
		Where ml_flag<> 1 AND ddate>='''+Convert(NvarChar(10),@StartDate,120)+''' and ddate<='''+Convert(NvarChar(10),@EndDate,120)+''''
		SELECT @StrSql=@StrSql+' Group By MachineID) as T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
		EXEC(@StrSql)

		SELECT @StrSql='UPDATE #ProdData SET mlpdt = IsNull(T2.mlpdt,0) 
		From (select MachineID,Sum(pdt)As mlpdt
		From ShiftDownTimeDetails 
		Where ml_flag= 1 and ddate>='''+Convert(NvarChar(10),@StartDate,120)+''' and ddate<='''+Convert(NvarChar(10),@EndDate,120)+''''
		SELECT @StrSql=@StrSql+' Group By MachineID) as T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
		EXEC(@StrSql)



		--ER0135-ER0138=================================================================================================================================================
		--Updating DownTime for the selected time period
		---commented ML_flag=0 to neglect only threshold value from Mgmtloss
		--SELECT @StrSql='Update #ProdData Set DownTime=ISNULL(T2.DownTime,0) --DR0292
		SELECT @StrSql='Update #ProdData Set DownTime=ISNULL(#ProdData.DownTime,0) + ISNULL(T2.DownTime,0)  --DR0292
		From (Select MachineID,Sum(DownTime)AS DownTime From ShiftDownTimeDetails
		Where dDate>='''+Convert(NvarChar(10),@StartDate,120)+''' and dDate<='''+Convert(NvarChar(10),@EndDate,120)+''' '-- And ML_Flag=0'
		SELECT @StrSql=@StrSql+' Group By MachineID)AS T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
		EXEC(@StrSql)

		
		---mod 1
			--SELECT @StrSql='Update #ProdData Set DownTimeAE=ISNULL(T2.DownTime,0) --DR0292
			SELECT @StrSql='Update #ProdData Set DownTimeAE=ISNULL(#ProdData.DownTimeAE,0) + ISNULL(T2.DownTime,0) --DR0292
			From (Select MachineID,Sum(DownTime)AS DownTime From ShiftDownTimeDetails
			Where dDate>='''+Convert(NvarChar(10),@StartDate,120)+''' and dDate<='''+Convert(NvarChar(10),@EndDate,120)+''' '
			SELECT @StrSql=@StrSql+' Group By MachineID)AS T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
			EXEC(@StrSql)

			SELECT @StrSql=' UPDATE #ProdData SET MgmtLoss = Isnull(#ProdData.MgmtLoss,0)+IsNull(T1.LOSS,0)
			From (select MachineID,
			sum(
				 CASE
				WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0
				THEN isnull(ShiftDownTimeDetails.Threshold,0)
				ELSE ShiftDownTimeDetails.DownTime
				 END) AS LOSS
				From ShiftDownTimeDetails
				Where dDate>='''+Convert(NvarChar(10),@StartDate,120)+''' and dDate<='''+Convert(NvarChar(10),@EndDate,120)+''' and ShiftDownTimeDetails.Ml_Flag=1 '
			SELECT @StrSql=@StrSql+' Group By MachineID
			) as T1 Inner Join #ProdData ON  #ProdData.MachineID=T1.MachineID '
			EXEC(@StrSql)
		---mod 1

		----to exclude threshold of ML from Downtime
		--UPDATE #ProdData SET DownTime=DownTime-MgmtLoss --DR0292
		UPDATE #ProdData SET DownTime=isnull(DownTime,0)-isnull(MgmtLoss,0) --DR0292

		---mod 1

		--Updating QEffy for the selected time period
		/*UPDATE #ProdData SET QEffy=IsNull(T1.QE,0)
		FROM(Select MachineID,
		CAST((Sum(Prod_Qty)-Sum(IsNull(Repeat_Cycles,0))-Sum(IsNull(Dummy_Cycles,0))-Sum(IsNull(Rejection_Qty,0))+Sum(IsNull(Rework_Performed,0)))As Float)/CAST((Sum(IsNull(Prod_Qty,0))-Sum(IsNull(Repeat_Cycles,0))-Sum(IsNull(Dummy_Cycles,0))+Sum(IsNull(Rework_Performed,0))) AS Float)As QE
		From ShiftProductionDetails Left Outer Join  ShiftRejectionDetails on ShiftProductionDetails.ID=ShiftRejectionDetails.ID
		Group By MachineID )AS T1 Inner Join #ProdData ON  #ProdData.MachineID=T1.MachineID
		*/

		--UPDATE #ProdData SET QEffy=IsNull(T1.QE,0) --DR0292
		UPDATE #ProdData SET QEffy= ISNULL(#ProdData.QEffy,0) + IsNull(T1.QE,0) --DR0292
		FROM(Select MachineID,
		CAST((Sum(AcceptedParts))As Float)/CAST((Sum(IsNull(AcceptedParts,0))+Sum(IsNull(MarkedForRework,0))+Sum(IsNull(RejCount,0))) AS Float)As QE
		From #ProdData Where AcceptedParts<>0 Group By MachineID
		)AS T1 Inner Join #ProdData ON  #ProdData.MachineID=T1.MachineID
		
		UPDATE #ProdData
		SET
			PEffy = (CN/UtilisedTime) ,
			---commented for mod 1
			----AEffy = (UtilisedTime)/(UtilisedTime + ISNULL( DownTime,0))
			---till here
			AEffy = (UtilisedTime)/(UtilisedTime + ISNULL( DownTimeAE,0)-isnull(MgmtLoss,0))
		WHERE UtilisedTime <> 0

		UPDATE #ProdData
		SET
			OEffy = CASE WHEN (SELECT OEEFormula FROM MachineOEEFormula_Shanti where MachineID = #ProdData.MachineID) = 'AE'
						THEN (AEffy*100)
					WHEN (SELECT OEEFormula FROM MachineOEEFormula_Shanti where MachineID = #ProdData.MachineID) = 'AE*PE'
						THEN (AEffy * ISNULL(PEffy,1))*100
					ELSE  (PEffy * AEffy * ISNULL(QEffy,1))*100
					END,
			PEffy = PEffy * 100 ,
			AEffy = AEffy * 100,
			QEffy = QEffy * 100
		
			

		Select @strsql=''	
		SELECT @StrSql='Update #ProdData Set MaxDownReasonTime=ISNULL(#ProdData.MaxDownReasonTime,0) + ISNULL(T2.DownTime,0)
		From 
		(select Machineid,SUBSTRING((DownID),1,6)+ ''-''+ SUBSTRING(dbo.f_FormatTime(DownTime,''hh:mm:ss''),1,5) as DownTime from 
			(select Machineid,downid,downtime,ROW_NUMBER() over(partition by machineid order by downtime desc) as rn from
				(Select MachineID,Downid,Sum(DownTime)AS DownTime From ShiftDownTimeDetails
				Where dDate>='''+Convert(NvarChar(10),@StartDate,120)+''' and dDate<='''+Convert(NvarChar(10),@EndDate,120)+''' '-- And ML_Flag=0'
				SELECT @StrSql=@StrSql+' Group By MachineID,Downid		
				)T
			)T1  where T1.rn=1 
		)T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
		print(@strsql)
		EXEC(@StrSql)
		
		Select @Strsql=''
		select @Strsql=@strsql+'
		Select
		#ProdData.MachineID,
		Isnull(ProdCount,0)ProdCount  ,
		Isnull(AcceptedParts,0)AcceptedParts,
		Isnull(RejCount,0)RejCount  ,
		ISNULL(MarkedForRework,0)Rework,
		isnull(cn,0)CN,
		Isnull(AEffy,0)AEffy  ,
		Isnull(PEffy,0)PEffy ,
		Isnull(OEffy,0)OEffy  ,
		Isnull(QEffy,0)QEffy  ,
		dbo.f_formattime(isnull(UtilisedTime,0),''' + @timeformat +''') As UtilisedTime  ,
		dbo.f_formattime((isnull(DownTime,0)+isnull(MgmtLoss,0)),''' + @timeformat +''') As DownTime,
		dbo.f_formattime(isnull(MgmtLoss,0),''' + @timeformat +''') As ManagementLoss,
		dbo.f_formattime(isnull(productionpdt,0),''' + @timeformat +''') As productionpdt  ,
		dbo.f_formattime(isnull(downpdt,0),''' + @timeformat +''') As downpdt  ,
		dbo.f_formattime(isnull(mlpdt,0),''' + @timeformat +''') As mlpdt,
		MachineDescription as Description,PEGreen ,PERed,AEGreen ,AERed ,OEGreen ,OERed,QERed,QEGreen,MaxDownReasonTime,Plantid,Groupid
		From #ProdData '
		Select @Strsql=@Strsql+@Strsortorder
		exec(@strsql)
	END
END
ELSE If @ReportType='Cellwise' or @ReportType='Plantwise'
BEGIN

		If isnull(@PlantID,'') <> ''
		Begin
			Select @StrPlantID = ' And ( PlantMachine.PlantID = N''' + @PlantID + ''' )'
		End
		SELECT @StrTPMMachines=''
		IF ( SELECT TOP 1 ValueInText FROM  CockpitDefaults WHERE Parameter='TpmEnbMac')='E'  
		BEGIN  
		 SET  @StrTPMMachines = ' AND M.TPMTrakEnabled = 1 '  
		END  
		ELSE  
		BEGIN  
		 SET  @StrTPMMachines = ' '  
		END 
		If isnull(@Machineid,'') <> ''
		Begin
			Select @Strmachine = ' And ( M.MachineID IN (' + @MachineID + '))'
		End
		If isnull(@GroupID,'') <> ''
		Begin
		Select @StrGroupid = ' And ( PlantMachineGroups.GroupID IN (' + @GroupID + '))'
		End

		-- Inserting distinct Machines of the given plant
		Select @Strsql=''
		SELECT @StrSql='INSERT INTO #ProdData(
		 MachineID ,PEffy ,AEffy ,QEffy,OEffy ,
		 ProdCount ,AcceptedParts,RejCount,MarkedForRework,UtilisedTime ,DownTime ,CN,
		 MachineDescription,PEGreen ,PERed,AEGreen ,AERed ,OEGreen ,OERed,QERed,QEGreen,Groupid,Plantid,GroupDescription,PlantDescription)
		 SELECT Distinct M.MachineID,0,0,0,0,0,0,0,0 ,0,0,0,
		 M.Description,isnull(M.PEGreen,0),isnull(M.PERed,0),isnull(M.AEGreen ,0),isnull(M.AERed,0),isnull(M.OEGreen ,0),isnull(M.OERed,0),isnull(M.QERed,0),isnull(M.QEGreen,0),
		 PlantMachineGroups.Groupid,PlantMachine.PlantID,PlantMachineGroups.Description,Plantinformation.Description
		 FROM Machineinformation M
		 Left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
		 Left outer join Plantinformation on Plantinformation.Plantid=PlantMachine.Plantid
		 LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID
		 Where M.Interfaceid>''0'''
		 SELECT @StrSql=@StrSql+ @StrPlantID+ @Strmachine + @StrTPMMachines +@StrGroupID
		 Print @StrSql
		 EXEC(@StrSql)

		--Updating ProdCount for the selected time period
		SELECT @StrSql='Update #ProdData Set ProdCount=ISNULL(T2.ProdCount,0) 
		From (Select MachineID,Sum(Prod_Qty)AS ProdCount From ShiftProductionDetails
		Where pDate>='''+Convert(NvarChar(10),@StartDate,120)+''' and pDate<='''+Convert(NvarChar(10),@EndDate,120)+''''
		SELECT @StrSql=@StrSql+' Group By MachineID)AS T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
		print @StrSql
		EXEC(@StrSql)
		
		--Updating AcceptedParts for the selected time period
		SELECT @StrSql='Update #ProdData Set AcceptedParts=ISNULL(T2.AcceptedParts,0) 
		From (Select MachineID,Sum(AcceptedParts)AS AcceptedParts From ShiftProductionDetails
		Where pDate>='''+Convert(NvarChar(10),@StartDate,120)+''' and pDate<='''+Convert(NvarChar(10),@EndDate,120)+''''
		SELECT @StrSql=@StrSql+' Group By MachineID)AS T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
		print @StrSql
		EXEC(@StrSql)

		--Updating MarkedForRework for the selected time period
		SELECT @StrSql='Update #ProdData Set MarkedForRework=ISNULL(T2.MarkedForRework,0) 
		From (Select MachineID,Sum(Marked_For_Rework)AS MarkedForRework From ShiftProductionDetails
		Where pDate>='''+Convert(NvarChar(10),@StartDate,120)+''' and pDate<='''+Convert(NvarChar(10),@EndDate,120)+''''
		SELECT @StrSql=@StrSql+' Group By MachineID)AS T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
		print @StrSql
		EXEC(@StrSql)
		
		--Updating RejCount for the selected time period
		SELECT @StrSql='Update #ProdData Set RejCount=ISNULL(T2.RejCount,0) 
		From (Select MachineID,Sum(Rejection_Qty)AS RejCount From ShiftProductionDetails
		Inner Join ShiftRejectionDetails On ShiftProductionDetails.ID=ShiftRejectionDetails.ID
		Where pDate>='''+Convert(NvarChar(10),@StartDate,120)+''' and pDate<='''+Convert(NvarChar(10),@EndDate,120)+''''
		SELECT @StrSql=@StrSql+' Group By MachineID)AS T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
		EXEC(@StrSql)

		--Updating CN for the selected time period
		Update #ProdData Set CN=ISNULL(T2.CN,0) 
		From (
		Select MachineID,sum(Prod_Qty *(CO_StdMachiningTime+CO_StdLoadUnload)) AS CN
		From ShiftProductionDetails
		Where pDate>=Convert(NvarChar(10),@StartDate,120) and pDate<=Convert(NvarChar(10),@EndDate,120)
		Group By MachineID )AS T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID
		
		
		--Updating UtilisedTime for the selected time period
		SELECT @StrSql='UPDATE #ProdData SET UtilisedTime = IsNull(T2.UtilisedTime,0) 
		From (select MachineID,Sum(Sum_of_ActCycleTime)As UtilisedTime
		From ShiftProductionDetails
		Where pDate>='''+Convert(NvarChar(10),@StartDate,120)+''' and pDate<='''+Convert(NvarChar(10),@EndDate,120)+''''
		SELECT @StrSql=@StrSql+' Group By MachineID) as T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
		EXEC(@StrSql)

		SELECT @StrSql='UPDATE #ProdData SET UtilisedTime = Isnull(#ProdData.UtilisedTime,0)+IsNull(T2.MinorDownTime,0)
		From (SELECT MachineID,sum(datediff(s,starttime,endtime)) as MinorDownTime
			FROM ShiftDownTimeDetails WHERE PE_Flag = 1
		and ddate>='''+Convert(NvarChar(10),@StartDate,120)+''' and dDate<='''+Convert(NvarChar(10),@EndDate,120)+''''
		SELECT @StrSql=@StrSql+' group by machineid) as T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
		--print @StrSql
		EXEC(@StrSql)


		--Updating DownTime for the selected time period
		SELECT @StrSql='Update #ProdData Set DownTime=ISNULL(#ProdData.DownTime,0) + ISNULL(T2.DownTime,0)  --DR0292
		From (Select MachineID,Sum(DownTime)AS DownTime From ShiftDownTimeDetails
		Where dDate>='''+Convert(NvarChar(10),@StartDate,120)+''' and dDate<='''+Convert(NvarChar(10),@EndDate,120)+''' '-- And ML_Flag=0'
		SELECT @StrSql=@StrSql+' Group By MachineID)AS T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
		EXEC(@StrSql)

		SELECT @StrSql='Update #ProdData Set DownTimeAE=ISNULL(#ProdData.DownTimeAE,0) + ISNULL(T2.DownTime,0) 
		From (Select MachineID,Sum(DownTime)AS DownTime From ShiftDownTimeDetails
		Where dDate>='''+Convert(NvarChar(10),@StartDate,120)+''' and dDate<='''+Convert(NvarChar(10),@EndDate,120)+''' '
		SELECT @StrSql=@StrSql+' Group By MachineID)AS T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
		EXEC(@StrSql)

		SELECT @StrSql=' UPDATE #ProdData SET MgmtLoss = Isnull(#ProdData.MgmtLoss,0)+IsNull(T1.LOSS,0)
		From (select MachineID,
		sum(
				CASE
			WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0
			THEN isnull(ShiftDownTimeDetails.Threshold,0)
			ELSE ShiftDownTimeDetails.DownTime
				END) AS LOSS
			From ShiftDownTimeDetails
			Where dDate>='''+Convert(NvarChar(10),@StartDate,120)+''' and dDate<='''+Convert(NvarChar(10),@EndDate,120)+''' and ShiftDownTimeDetails.Ml_Flag=1 '
		SELECT @StrSql=@StrSql+' Group By MachineID
		) as T1 Inner Join #ProdData ON  #ProdData.MachineID=T1.MachineID '
		EXEC(@StrSql)
		---mod 1

		UPDATE #ProdData SET DownTime=isnull(DownTime,0)-isnull(MgmtLoss,0) 
 
		Select @strsql=''	
		SELECT @StrSql='Update #ProdData Set MaxDownReasonTime=ISNULL(#ProdData.MaxDownReasonTime,0) + ISNULL(T2.DownTime,0)
		From 
		(select Machineid,SUBSTRING((DownID),1,6)+ ''-''+ SUBSTRING(dbo.f_FormatTime(DownTime,''hh:mm:ss''),1,5) as DownTime from 
			(select Machineid,downid,downtime,ROW_NUMBER() over(partition by machineid order by downtime desc) as rn from
				(Select MachineID,Downid,Sum(DownTime)AS DownTime From ShiftDownTimeDetails
				Where dDate>='''+Convert(NvarChar(10),@StartDate,120)+''' and dDate<='''+Convert(NvarChar(10),@EndDate,120)+''' '-- And ML_Flag=0'
				SELECT @StrSql=@StrSql+' Group By MachineID,Downid		
				)T
			)T1  where T1.rn=1 
		)T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
		print(@strsql)
		EXEC(@StrSql)

		If @ReportType='Cellwise'
		Begin
				Insert into #Summary(Plantid,Groupid,ProdCount,AcceptedParts,RejCount,MarkedForRework,UtilisedTime,DownTime,MaxDownReasonTime,CN,DownTimeAE,MgmtLoss,GroupDescription)
				Select Plantid,#ProdData.Groupid,Isnull(sum(ProdCount),0),Isnull(sum(AcceptedParts),0),Isnull(sum(RejCount),0),ISNULL(sum(MarkedForRework),0),
				isnull(sum(UtilisedTime),0),isnull(sum(DownTime),0),Max(MaxDownReasonTime),ISNULL(SUM(CN),0),ISNULL(SUM(DownTimeAE),0),ISNULL(SUM(MgmtLoss),0),GroupDescription
				From #ProdData group By #ProdData.Groupid,GroupDescription,Plantid

				UPDATE #Summary
				SET
					PEffy = (CN/UtilisedTime) ,
					AEffy = (UtilisedTime)/(UtilisedTime + ISNULL( DownTimeAE,0)-isnull(MgmtLoss,0))
				WHERE UtilisedTime <> 0
		
				UPDATE #Summary SET QEffy= CAST(AcceptedParts As Float)/CAST((IsNull(AcceptedParts,0)+IsNull(MarkedForRework,0)+IsNull(RejCount,0)) AS Float)
				Where AcceptedParts<>0 

				UPDATE #Summary
				SET
				OEffy = CASE WHEN (SELECT OEEFormula FROM MachineOEEFormula_Shanti where MachineID = #Summary.MachineID) = 'AE'
						THEN (AEffy*100)
						WHEN (SELECT OEEFormula FROM MachineOEEFormula_Shanti where MachineID = #Summary.MachineID) = 'AE*PE'
							THEN (AEffy * ISNULL(PEffy,1))*100
						ELSE  (PEffy * AEffy * ISNULL(QEffy,1))*100
						END,
				PEffy = PEffy * 100 ,
				AEffy = AEffy * 100,
				QEffy = QEffy * 100	

				

				Select
				Plantid,Groupid,
				Isnull(ProdCount,0)ProdCount,
				Isnull(AcceptedParts,0)AcceptedParts,
				Isnull(RejCount,0)RejCount  ,
				ISNULL(MarkedForRework,0)Rework,
				Isnull(AEffy,0)AEffy,
				Isnull(PEffy,0)PEffy,
				Isnull(OEffy,0)OEffy,
				Isnull(QEffy,0)QEffy,
				dbo.f_formattime(isnull(UtilisedTime,0),@timeformat) As UtilisedTime  ,
				dbo.f_formattime((isnull(DownTime,0)+isnull(MgmtLoss,0)),@timeformat) As DownTime,
				dbo.f_formattime(isnull(MgmtLoss,0),@timeformat) As ManagementLoss,
				dbo.f_formattime((isnull(UtilisedTime,0)+isnull(DownTime,0)+isnull(MgmtLoss,0)),@timeformat) As Totaltime,
				GroupDescription as Description,MaxDownReasonTime,ISNULL(PEGreen,0) as PEGreen,ISNULL(PERed,0) as PERed,ISNULL(AEGreen,0) as AEGreen,isnull(AERed,0) as AERed,isnull(OEEGreen,0) as OEGreen,
				isnull(OEERed,0) as OERed,isnull(QERED,0) as QERED,isnull(QEGreen,0) as QEGreen
				From #Summary,TPMWEB_EfficiencyColorCoding where TPMWEB_EfficiencyColorCoding.Type='CellID'
				Order By Plantid,Groupid
			End
			If @ReportType='Plantwise'
			Begin
				Insert into #Summary(Plantid,ProdCount,AcceptedParts,RejCount,MarkedForRework,UtilisedTime,DownTime,MaxDownReasonTime,CN,DownTimeAE,MgmtLoss,PlantDescription)
				Select #ProdData.Plantid,Isnull(sum(ProdCount),0),Isnull(sum(AcceptedParts),0),Isnull(sum(RejCount),0),ISNULL(sum(MarkedForRework),0),
				isnull(sum(UtilisedTime),0),isnull(sum(DownTime),0),Max(MaxDownReasonTime),ISNULL(SUM(CN),0),ISNULL(SUM(DownTimeAE),0),ISNULL(SUM(MgmtLoss),0),PlantDescription
				From #ProdData group By #ProdData.Plantid,PlantDescription

				UPDATE #Summary
				SET
					PEffy = (CN/UtilisedTime) ,
					AEffy = (UtilisedTime)/(UtilisedTime + ISNULL( DownTimeAE,0)-isnull(MgmtLoss,0))
				WHERE UtilisedTime <> 0
		
				UPDATE #Summary SET QEffy= CAST(AcceptedParts As Float)/CAST((IsNull(AcceptedParts,0)+IsNull(MarkedForRework,0)+IsNull(RejCount,0)) AS Float)
				Where AcceptedParts<>0 

				UPDATE #Summary
				SET
				OEffy = CASE WHEN (SELECT OEEFormula FROM MachineOEEFormula_Shanti where MachineID = #Summary.MachineID) = 'AE'
						THEN (AEffy*100)
						WHEN (SELECT OEEFormula FROM MachineOEEFormula_Shanti where MachineID = #Summary.MachineID) = 'AE*PE'
							THEN (AEffy * ISNULL(PEffy,1))*100
						ELSE  (PEffy * AEffy * ISNULL(QEffy,1))*100
						END,
				PEffy = PEffy * 100 ,
				AEffy = AEffy * 100,
				QEffy = QEffy * 100	
			
				


				Select
				Plantid,
				Isnull(ProdCount,0)ProdCount  ,
				Isnull(AcceptedParts,0)AcceptedParts,
				Isnull(RejCount,0)RejCount  ,
				ISNULL(MarkedForRework,0)Rework,
				Isnull(AEffy,0)AEffy  ,
				Isnull(PEffy,0)PEffy ,
				Isnull(OEffy,0)OEffy  ,
				Isnull(QEffy,0)QEffy  ,
				dbo.f_formattime(isnull(UtilisedTime,0),@timeformat) As UtilisedTime  ,
				dbo.f_formattime((isnull(DownTime,0)+isnull(MgmtLoss,0)),@timeformat) As DownTime,
				dbo.f_formattime(isnull(MgmtLoss,0),@timeformat) As ManagementLoss,
				dbo.f_formattime((isnull(UtilisedTime,0)+isnull(DownTime,0)+isnull(MgmtLoss,0)),@timeformat) As Totaltime,
				PlantDescription as Description,MaxDownReasonTime,ISNULL(PEGreen,0) as PEGreen,ISNULL(PERed,0) as PERed,ISNULL(AEGreen,0) as AEGreen,isnull(AERed,0) as AERed,isnull(OEEGreen,0) as OEGreen,
				isnull(OEERed,0) as OERed,isnull(QERED,0) as QERED,isnull(QEGreen,0) as QEGreen
				From #Summary,TPMWEB_EfficiencyColorCoding where TPMWEB_EfficiencyColorCoding.Type='PlantID'
				Order By Plantid
			End
END
ELSE
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
IF @ReportType='OperatorWise'
BEGIN
	
	--alter table #ProdData Add Isgrp int NOT NULL --Added by Shm
	If isnull(@PlantID,'') <> ''
	Begin
		---mod 2
--		Select @StrPlantID = ' And ( PlantEmployee.PlantID = ''' + @PlantID + ''' )'
		Select @StrPlantID = ' And ( PlantEmployee.PlantID = N''' + @PlantID + ''' )'
		---mod 2
	End
	If isnull(@Machineid,'') <> ''
	Begin
		---mod 2
--		Select @Strmachine = ' And ( ShiftProductionDetails.MachineID = ''' + @MachineID + ''')'
		Select @Strmachine = ' And ( ShiftProductionDetails.MachineID IN (' + @MachineID + '))'
		---mod 2
	End

	Declare @StrDonwMachine nvarchar(50)
	select @StrDonwMachine=''
	If isnull(@Machineid,'') <> ''
	Begin
		---mod 2
--		Select @Strmachine = ' And ( ShiftProductionDetails.MachineID = ''' + @MachineID + ''')'
		Select @StrDonwMachine = ' And ( ShiftDownTimeDetails.MachineID IN (' + @MachineID + '))'
		---mod 2
	End

	select @StrOpr=''
	If isnull(@OperatorID,'') <> ''
	Begin
		---mod 2
--		Select @StrOpr = ' And ( ShiftProductionDetails.OperatorID = ''' + @OperatorID + ''')'
		Select @StrOpr = ' And ( ShiftProductionDetails.OperatorID = N''' + @OperatorID + ''')'
		---mod 2
	End
	If isnull(@GroupID,'') <> ''
	Begin
		--Select @StrGroupID = ' And ( ShiftProductionDetails.GroupID in (' + @GroupID + '))'
		Select @StrGroupID = ' And ( ShiftProductionDetails.GroupID IN (' + @GroupID + '))'
	End


	SELECT @StrSql=''
--s_GetShiftAgg_ProductionReport '2007-12-01','2007-12-01','DAY','','MC 01','','OperatorWise','Day'
	If @Parameter='Consolidated'
	BEGIN
		--Inserting Distinct Employees belongs to the specified Plant
		SELECT @StrSql='INSERT INTO #ProdData(
		 OperatorID ,PEffy ,AEffy ,QEffy,OEffy ,
		 ProdCount ,AcceptedParts,RejCount,MarkedForRework,UtilisedTime ,DownTime ,CN,Isgrp )
		 SELECT Distinct E.Employeeid,0,0,0,0,0,0,0,0 ,0,0,0,E.Operate
		 FROM employeeinformation E Inner Join ShiftProductionDetails  ON ShiftProductionDetails.OperatorID=E.Employeeid
		 Left Outer Join PlantEmployee ON PlantEmployee.EmployeeID=ShiftProductionDetails.OperatorID
		 Where E.Interfaceid>''0'''
		SELECT @StrSql=@StrSql+ @StrPlantID+ @StrOpr+@StrGroupID
		Print @StrSql
		EXEC(@StrSql)
		
		--Updating ProdCount for the selected time period
		SELECT @StrSql='Update #ProdData Set ProdCount=ISNULL(T2.ProdCount,0)
		From (Select OperatorID,Sum(Prod_Qty)AS ProdCount From ShiftProductionDetails
		Where pDate>='''+Convert(NvarChar(20),@StartDate)+''' and pDate<='''+Convert(NvarChar(20),@EndDate)+''''
		SELECT @StrSql=@StrSql+' Group By OperatorID)AS T2 Inner Join #ProdData ON T2.OperatorID=#ProdData.OperatorID'
		print @StrSql
		EXEC(@StrSql)
		
		--Updating AcceptedParts for the selected time period
		SELECT @StrSql='Update #ProdData Set AcceptedParts=ISNULL(T2.AcceptedParts,0) 
		From (Select OperatorID,Sum(AcceptedParts)AS AcceptedParts From ShiftProductionDetails
		Where pDate>='''+Convert(NvarChar(20),@StartDate)+''' and pDate<='''+Convert(NvarChar(20),@EndDate)+''''
		SELECT @StrSql=@StrSql+' Group By OperatorID)AS T2 Inner Join #ProdData ON T2.OperatorID=#ProdData.OperatorID'
		print @StrSql
		EXEC(@StrSql)

		--Updating MarkedForRework for the selected time period
		SELECT @StrSql='Update #ProdData Set MarkedForRework=ISNULL(T2.MarkedForRework,0) 
		From (Select OperatorID,Sum(Marked_For_Rework)AS MarkedForRework From ShiftProductionDetails
		Where pDate>='''+Convert(NvarChar(20),@StartDate)+''' and pDate<='''+Convert(NvarChar(20),@EndDate)+''''
		SELECT @StrSql=@StrSql+' Group By OperatorID)AS T2 Inner Join #ProdData ON T2.OperatorID=#ProdData.OperatorID'
		print @StrSql
		EXEC(@StrSql)
		
		--Updating RejCount for the selected time period
		SELECT @StrSql='Update #ProdData Set RejCount=ISNULL(T2.RejCount,0)
		From (Select OperatorID,Sum(Rejection_Qty)AS RejCount From ShiftProductionDetails
		Inner Join ShiftRejectionDetails On ShiftProductionDetails.ID=ShiftRejectionDetails.ID
		Where pDate>='''+Convert(NvarChar(20),@StartDate)+''' and pDate<='''+Convert(NvarChar(20),@EndDate)+''''
		SELECT @StrSql=@StrSql+' Group By OperatorID)AS T2 Inner Join #ProdData ON T2.OperatorID=#ProdData.OperatorID'
		EXEC(@StrSql)

		--Updating CN for the selected time period
		Update #ProdData Set CN=ISNULL(T2.CN,0) 
		From (
			--Select OperatorID,(sum(Prod_Qty) * max(CO_StdMachiningTime+CO_StdLoadUnload)) AS CN --DR0302 Commented
			Select OperatorID,sum(Prod_Qty *(CO_StdMachiningTime+CO_StdLoadUnload)) AS CN --DR0302 Added
			From ShiftProductionDetails
			Where pDate>=@StartDate and pDate<=@EndDate
			Group By OperatorID
		)AS T2 Inner Join #ProdData ON T2.OperatorID=#ProdData.OperatorID
		
		--Updating UtilisedTime for the selected time period
		SELECT @StrSql='UPDATE #ProdData SET UtilisedTime = IsNull(T2.UtilisedTime,0) 
		From (select OperatorID,Sum(Sum_of_ActCycleTime)As UtilisedTime
		From ShiftProductionDetails
		Where pDate>='''+Convert(NvarChar(20),@StartDate)+''' and pDate<='''+Convert(NvarChar(20),@EndDate)+''''
		SELECT @StrSql=@StrSql+' Group By OperatorID) as T2 Inner Join #ProdData ON T2.OperatorID=#ProdData.OperatorID'
		EXEC(@StrSql)
		
		--ER0135-ER0138-karthikg-Operatorwise-Consolidated-s_GetShiftAgg_ProductionReport '2007-12-01','2007-12-01','DAY','','MC 01','','Operatorwise','Consolidated'
		SELECT @StrSql='UPDATE #ProdData SET UtilisedTime = Isnull(#ProdData.UtilisedTime,0)+IsNull(T2.MinorDownTime,0)
		From (SELECT operatorid,sum(datediff(s,starttime,endtime)) as MinorDownTime
			FROM ShiftDownTimeDetails WHERE  PE_Flag = 1
		and ddate>='''+Convert(NvarChar(20),@StartDate)+''' and dDate<='''+Convert(NvarChar(20),@EndDate)+''''
		SELECT @StrSql=@StrSql+' Group By OperatorID) as T2 Inner Join #ProdData ON T2.OperatorID=#ProdData.OperatorID'
		--print @StrSql
		EXEC(@StrSql)

		--ER0135-ER0138=============================================================================================================================================
		--Updating DownTime for the selected time period
		---commented ML_flag=0 to neglect only threshold value from Mgmtloss
		--SELECT @StrSql='Update #ProdData Set DownTime=ISNULL(T2.DownTime,0) --DR0292
		SELECT @StrSql='Update #ProdData Set DownTime=isnull(#ProdData.Downtime,0) + ISNULL(T2.DownTime,0) --DR0292
		From (Select OperatorID,Sum(DownTime)AS DownTime From ShiftDownTimeDetails
		Where dDate>='''+Convert(NvarChar(20),@StartDate)+''' and dDate<='''+Convert(NvarChar(20),@EndDate)+''' ' ---And ML_Flag=0'
		SELECT @StrSql=@StrSql+' Group By OperatorID)AS T2 Inner Join #ProdData ON T2.OperatorID=#ProdData.OperatorID'
		EXEC(@StrSql)

		
		----mod 1
			--SELECT @StrSql='Update #ProdData Set DownTimeAE=ISNULL(T2.DownTime,0) --DR0292
			SELECT @StrSql='Update #ProdData Set DownTimeAE=ISNULL(#ProdData.DownTimeAE,0) + ISNULL(T2.DownTime,0) --DR0292
			From (Select OperatorID,Sum(DownTime)AS DownTime From ShiftDownTimeDetails
			Where dDate>='''+Convert(NvarChar(20),@StartDate)+''' and dDate<='''+Convert(NvarChar(20),@EndDate)+'''  '
			SELECT @StrSql=@StrSql+' Group By OperatorID)AS T2 Inner Join #ProdData ON T2.OperatorID=#ProdData.OperatorID'
			EXEC(@StrSql)
			
			--SELECT @StrSql=' UPDATE #ProdData SET MgmtLoss = IsNull(T1.LOSS,0) --DR0292
			SELECT @StrSql=' UPDATE #ProdData SET MgmtLoss = ISnull(#ProdData.MgmtLoss,0) +  IsNull(T1.LOSS,0) --DR0292
			From (select OperatorID,
			sum(
				 CASE
				WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0
				THEN isnull(ShiftDownTimeDetails.Threshold,0)
				ELSE ShiftDownTimeDetails.DownTime
				 END) AS LOSS
				From ShiftDownTimeDetails
				Where dDate>='''+Convert(NvarChar(20),@StartDate)+''' and dDate<='''+Convert(NvarChar(20),@EndDate)+''' and ShiftDownTimeDetails.Ml_Flag=1 '
			SELECT @StrSql=@StrSql+' Group By OperatorID
			) as T1 Inner Join #ProdData ON  #ProdData.OperatorID=T1.OperatorID '
			print @StrSql
			EXEC(@StrSql)
		----mod 1
		

		
		----to exclude threshold of ML from Downtime
		--update #ProdData set DownTime= DownTime-MgmtLoss --DR0292
		update #ProdData set DownTime=isnull(DownTime,0)-isnull(MgmtLoss,0) --DR0292

		
--Added by shilpa for nr0043 on 19-may-08
IF ISNULL(@OperatorID,'')<>''
BEGIN
	update #ProdData set ProdCount=T1.ProdCount,AcceptedParts=T1.AcceptedParts ,UtilisedTime=T1.Util,MgmtLoss=T1.Mgmt ,
	DownTime =T1.Dtime,	CN =T1.CN1,MarkedForRework=T1.MarkedForRework,RejCount=T1.RejCount,DownTimeAE=T1.DownTimeAE
	from (select sum(ProdCount) as ProdCount,sum(AcceptedParts) as AcceptedParts,sum(UtilisedTime) as Util,sum(MgmtLoss) as Mgmt,
	sum(DownTime) as Dtime,sum(CN) as CN1,sum(MarkedForRework) as MarkedForRework,sum(RejCount) as RejCount, sum(DownTimeAE) as DownTimeAE from #ProdData 
	) as  T1 where #ProdData.OperatorID=@Operatorid
	delete from #ProdData where #ProdData.OperatorID<>@Operatorid
END
ELSE
BEGIN
		
		declare @CurOperatorIDG as nvarchar(50)
		declare @CurProdCount as int
		declare @CurUtilisedTime as float
		declare @CurAcceptedParts as int
		declare @CurManagementLoss as float
		declare @CurDownTime as float
		declare @CurCN as float
		declare @InOpr as nvarchar(50)
		declare @sep as nvarchar(2)
		declare @CurMarkedForRework int
		declare @CurRejCount as int
		declare @CurDownTimeAE as int
		Select @sep =Groupseperator2 from smartdataportrefreshdefaults
		
		Declare TmpCursor Cursor For SELECT OperatorID,ProdCount,AcceptedParts,UtilisedTime,MgmtLoss,DownTime,
				CN,MarkedForRework,RejCount,DownTimeAE FROM #ProdData where isgrp=1
		OPEN  TmpCursor
		
		FETCH NEXT FROM TmpCursor INTO @CurOperatorIDG,@CurProdCount,@CurAcceptedParts,@CurUtilisedTime,@CurManagementLoss,@CurDownTime ,@CurCN,
				@CurMarkedForRework	,@CurRejCount,@CurDownTimeAE
		WHILE @@FETCH_STATUS=0
		BEGIN---cursor
			while  substring(@CurOperatorIDG,1,(case when CHARINDEX ( @sep ,@CurOperatorIDG)=0 then len(@CurOperatorIDG) else (CHARINDEX ( @sep ,@CurOperatorIDG)-1 ) end) ) <> ''
			begin
				set @InOpr=substring(@CurOperatorIDG,1,(case when CHARINDEX ( @sep ,@CurOperatorIDG)=0 then len(@CurOperatorIDG) else (CHARINDEX ( @sep ,@CurOperatorIDG)-1 ) end) )
				
				If not exists (select * from #ProdData where operatorid=@InOpr)
				Begin
					Insert into #ProdData(OperatorID,ProdCount,UtilisedTime,MgmtLoss,AcceptedParts,DownTime,CN,
					DownTimeAE,MarkedForRework,RejCount,isgrp)
					values(@InOpr,@CurProdCount,@CurUtilisedTime,@CurManagementLoss,
					@CurAcceptedParts,@CurDownTime,@CurCN,@CurDownTimeAE,
					@CurMarkedForRework,@CurRejCount,0)
				End
				Else
				Begin
					update #ProdData set ProdCount=ProdCount+@CurProdCount ,UtilisedTime=UtilisedTime+@CurUtilisedTime,MgmtLoss=MgmtLoss+@CurManagementLoss,
					AcceptedParts=AcceptedParts+@CurAcceptedParts,DownTime =DownTime+@CurDownTime,CN =CN+@CurCN,DownTimeAE=DownTimeAE+@CurDownTimeAE ,
					MarkedForRework=MarkedForRework+@CurMarkedForRework ,RejCount=RejCount+@CurRejCount	where #ProdData.OperatorID=@InOpr
				End							
				
				if CHARINDEX ( @sep ,@CurOperatorIDG) <>0
				begin
					set @CurOperatorIDG=substring(@CurOperatorIDG,CHARINDEX(@sep, @CurOperatorIDG)+ 1,LEN(@CurOperatorIDG) - CHARINDEX(@sep, @CurOperatorIDG)+ 1)
				end
				else
				begin
					set @CurOperatorIDG=''
				end
				--select @CurOperatorIDG
			end
			--FETCH NEXT FROM TmpCursor INTO @CurOperatorIDG,@CurComponents ,@CurUtilisedTime,@CurManagementLoss,@CurDownTime ,@CurCN
			FETCH NEXT FROM TmpCursor INTO @CurOperatorIDG,@CurProdCount,@CurAcceptedParts,@CurUtilisedTime,@CurManagementLoss,@CurDownTime ,@CurCN,
				@CurMarkedForRework	,@CurRejCount,@CurDownTimeAE
			
		END---cursor
close TmpCursor
deallocate TmpCursor
	delete from #ProdData where isgrp=1
END
--till here by shm
		UPDATE #ProdData
		SET
			PEffy = (CN/UtilisedTime) ,
			---commented for mod 1
			-----AEffy = (UtilisedTime)/(UtilisedTime + ISNULL( DownTime,0))
			---till here
			---mod 1
				AEffy = (UtilisedTime)/(UtilisedTime + ISNULL( DownTimeAE,0)-isnull(MgmtLoss,0))
			---mod 1
		WHERE UtilisedTime <> 0
	
		UPDATE #ProdData
		SET
			OEffy = CASE WHEN (SELECT OEEFormula FROM MachineOEEFormula_Shanti where MachineID = #ProdData.MachineID) = 'AE'
						THEN (AEffy*100)
						WHEN (SELECT OEEFormula FROM MachineOEEFormula_Shanti where MachineID = #ProdData.MachineID) = 'AE*PE'
							THEN (AEffy * ISNULL(PEffy,1))*100
						ELSE  (PEffy * AEffy * ISNULL(QEffy,1))*100
						END,
			PEffy = PEffy * 100 ,
			AEffy = AEffy * 100


			

	--select * from #ProdData
		Select
		OperatorID+' - '+[Name] AS Operator,
		Isnull(ProdCount,0)ProdCount  ,
		Isnull(AcceptedParts,0)AcceptedParts,
		Isnull(RejCount,0)RejCount  ,
		Isnull(MarkedForRework,0)Rework,
		Isnull(AEffy,0)AEffy  ,
		Isnull(PEffy,0)PEffy ,
		Isnull(OEffy,0)OEffy  ,
		dbo.f_formattime(isnull(UtilisedTime,0),@timeformat) As UtilisedTime  ,
		dbo.f_formattime(isnull(DownTime,0),@timeformat) As DownTime
		From #ProdData Inner Join EmployeeInformation
			ON #ProdData.OperatorID=EmployeeInformation.EmployeeID
		Order By OperatorID
	END
	If @Parameter='Day'
	BEGIN
		Select @strsql = 'SELECT OperatorID, '
		Select @strsql = @strsql + 'ComponentID, '
		Select @strsql = @strsql + 'MachineID,'
		Select @strsql = @strsql + 'OperationNo, '
		Select @strsql = @strsql + ' dbo.f_FormatTime(CO_StdMachiningTime ,''' + @TimeFormat + ''') AS IdealCycleTime, '
		Select @strsql = @strsql + ' dbo.f_FormatTime(CO_StdLoadUnload,''' + @TimeFormat + ''') AS IdealLoadUnload, '
		Select @strsql = @strsql + ' dbo.f_FormatTime(MaxMachiningTime,''' + @TimeFormat + ''') AS MaxCycleTime,'
		Select @strsql = @strsql + ' dbo.f_FormatTime(MinMachiningTime,''' + @TimeFormat + ''') AS MinCycleTime,'
		Select @strsql = @strsql + ' dbo.f_FormatTime(Sum(ActMachiningTime_Type12)/Sum(Prod_Qty) ,''' + @TimeFormat + ''') AS AvgCycleTime,'
		Select @strsql = @strsql + ' dbo.f_FormatTime(MaxLoadUnloadTime,''' + @TimeFormat + ''') AS MaxLoadUnload,'
		Select @strsql = @strsql + ' dbo.f_FormatTime(MinLoadUnloadTime,''' + @TimeFormat + ''') AS MinLoadUnload, '
		Select @strsql = @strsql + ' dbo.f_FormatTime(AVG(ActLoadUnload_Type12)/Sum(Prod_Qty)  ,''' + @TimeFormat + ''') AS AvgLoadUnload, '
		Select @strsql = @strsql + ' Sum(Prod_Qty) as OperationCount, Sum(AcceptedParts)as AcceptedParts,Sum(Dummy_Cycles)As Dummy_Cycles,Sum(Repeat_Cycles)as Repeat_Cycles,
		Sum(Rework_Performed)AS Rework_Performed,Sum(Marked_for_Rework)AS Marked_for_Rework,
		Sum(Prod_Qty-Repeat_Cycles-Dummy_Cycles-Marked_for_Rework-AcceptedParts+Rework_Performed)As RejCount'
		Select @strsql = @strsql + ' FROM ShiftProductionDetails '
		Select @strsql = @strsql + ' WHERE (pDate = ''' + convert(nvarchar(20),@StartDate) + ''')'
		Select @strsql = @strsql +  @StrOpr  + @strMachine
		Select @strsql = @strsql + ' GROUP BY OperatorID,ComponentID,MachineID, OperationNo, '
		Select @strsql = @strsql + ' CO_StdMachiningTime,CO_StdLoadUnload, SubOperation,MaxMachiningTime,MinMachiningTime,MaxLoadUnloadTime,MinLoadUnloadTime'
		exec (@strsql)
	END

	If @Parameter='ProdReport'
	BEGIN

	declare @start datetime
	declare @end datetime
	select @start=''
	select @end=''
	select @start=(select cast(convert(nvarchar(20),dbo.f_GetLogicalDay(@StartDate,'start'),120) as datetime))
	select @end=(select cast(convert(nvarchar(20),dbo.f_GetLogicalDay(@enddate,'end'),120) as datetime))

		Create table #NipponProdData
		(
			MachineID nvarchar(50),
			CycleEndTime datetime,
			ComponentID nvarchar(50),
			OperationNo nvarchar(50),
			OperatorID nvarchar(50),
			ProdCount float,
			StdCycleTime nvarchar(50),
			ActCycleTime nvarchar(50),
			EffCycleTime nvarchar(50),
			StdLoadUnload nvarchar(50),
			ActLoadUnload nvarchar(50),
			EffLoadUnload nvarchar(50),
			DownTime float,
			CN float,
			UtilisedTime float,
			DownTimeAE float,
			MgmtLoss float,
			AE float,
			PE float,
			QE float,
			OEE float
		)	

		--Select @strsql=''
		--Select @strsql='INSERT into #NipponProdData(MachineID,ComponentID,OperationNo,OperatorID,StdCycleTime,ActCycleTime,EffCycleTime,StdLoadUnload,ActLoadUnload,EffLoadUnload,ProdCount)'
		--Select @strsql = @strsql + ' SELECT MachineID,ComponentID,OperationNo,OperatorID, '
		--Select @strsql = @strsql + ' dbo.f_FormatTime(CO_StdMachiningTime ,''' + @TimeFormat + ''') AS IdealCycleTime, '
		--Select @strsql = @strsql + ' dbo.f_FormatTime(Sum(ActMachiningTime_Type12)/Sum(Prod_Qty) ,''' + @TimeFormat + ''') AS AvgCycleTime,'
		--Select @strsql = @strsql + ' dbo.f_FormatTime((Sum(ActMachiningTime_Type12)/Sum(Prod_Qty))/(CO_StdMachiningTime)  ,''' + @TimeFormat + ''') AS EffCycleTime,'
		--Select @strsql = @strsql + ' dbo.f_FormatTime(CO_StdLoadUnload,''' + @TimeFormat + ''') AS IdealLoadUnload, '
		--Select @strsql = @strsql + ' dbo.f_FormatTime(AVG(ActLoadUnload_Type12)/Sum(Prod_Qty)  ,''' + @TimeFormat + ''') AS AvgLoadUnload, '
		--Select @strsql = @strsql + ' dbo.f_FormatTime((AVG(ActLoadUnload_Type12)/Sum(Prod_Qty))/(CO_StdLoadUnload) ,''' + @TimeFormat + ''') AS EffLoadUnload, Sum(Prod_Qty) as ProdCount '
		--Select @strsql = @strsql + ' FROM ShiftProductionDetails '
		--Select @strsql = @strsql + ' Where pDate>='''+Convert(NvarChar(20),@StartDate)+''' and pDate<='''+Convert(NvarChar(20),@EndDate)+''''
		--Select @strsql = @strsql +  @StrOpr  + @strMachine
		--Select @strsql = @strsql + ' GROUP BY MachineID,ComponentID,OperationNo,OperatorID, '
		--Select @strsql = @strsql + ' CO_StdMachiningTime,CO_StdLoadUnload '
		--print (@strsql)
		--exec (@strsql)

		Select @strsql=''
		Select @strsql='INSERT into #NipponProdData(MachineID,ComponentID,OperationNo,OperatorID,StdCycleTime,ActCycleTime,EffCycleTime,StdLoadUnload,ActLoadUnload,EffLoadUnload,ProdCount)'
		Select @strsql = @strsql + ' SELECT MachineID,ComponentID,OperationNo,OperatorID, '
		Select @strsql = @strsql + ' CO_StdMachiningTime  AS IdealCycleTime, '
		Select @strsql = @strsql + ' Sum(ActMachiningTime_Type12)/Sum(Prod_Qty)  AS AvgCycleTime,'
		--Select @strsql = @strsql + ' (Sum(ActMachiningTime_Type12)/Sum(Prod_Qty))/(CO_StdMachiningTime)   AS EffCycleTime,'
		Select @strsql = @strsql + ' 0   AS EffCycleTime,'
		Select @strsql = @strsql + ' CO_StdLoadUnload AS IdealLoadUnload, '
		Select @strsql = @strsql + ' AVG(ActLoadUnload_Type12)/Sum(Prod_Qty)  AS AvgLoadUnload, '
		--Select @strsql = @strsql + ' (AVG(ActLoadUnload_Type12)/Sum(Prod_Qty))/(CO_StdLoadUnload)  AS EffLoadUnload, Sum(Prod_Qty) as ProdCount '
		Select @strsql = @strsql + ' 0  AS EffLoadUnload, Sum(Prod_Qty) as ProdCount '
		Select @strsql = @strsql + ' FROM ShiftProductionDetails '
		Select @strsql = @strsql + ' Where pDate>='''+Convert(NvarChar(20),@StartDate)+''' and pDate<='''+Convert(NvarChar(20),@EndDate)+''''
		Select @strsql = @strsql +  @StrOpr  + @strMachine
		Select @strsql = @strsql + ' GROUP BY MachineID,ComponentID,OperationNo,OperatorID, '
		Select @strsql = @strsql + ' CO_StdMachiningTime,CO_StdLoadUnload '
		print (@strsql)
		exec (@strsql)

		Select @strsql=''
		SELECT @StrSql='Update #NipponProdData Set CN=ISNULL(T2.CN,0) 
		From (
			Select MachineID,ComponentID,OperationNo,OperatorID,sum(Prod_Qty *(CO_StdMachiningTime+CO_StdLoadUnload)) AS CN 
			From ShiftProductionDetails
			Where pDate>='''+Convert(NvarChar(20),@StartDate)+''' and pDate<='''+Convert(NvarChar(20),@EndDate)+''''
		Select @strsql = @strsql +  @StrOpr  + @strMachine
		SELECT @StrSql=@StrSql+' Group By MachineID,ComponentID,OperationNo,OperatorID
		)AS T2 Inner Join #NipponProdData ON T2.MachineID=#NipponProdData.MachineID and T2.ComponentID=#NipponProdData.ComponentID 
		and T2.OperationNo=#NipponProdData.OperationNo and T2.OperatorID=#NipponProdData.OperatorID '
		print (@strsql)
		EXEC(@StrSql)
	
		Select @strsql=''
		SELECT @StrSql='UPDATE #NipponProdData SET UtilisedTime = IsNull(T2.UtilisedTime,0) 
		From (select MachineID,ComponentID,OperationNo,OperatorID,Sum(Sum_of_ActCycleTime)As UtilisedTime
		From ShiftProductionDetails
		Where pDate>='''+Convert(NvarChar(20),@StartDate)+''' and pDate<='''+Convert(NvarChar(20),@EndDate)+''''
		Select @strsql = @strsql +  @StrOpr  + @strMachine
		SELECT @StrSql=@StrSql+' Group By MachineID,ComponentID,OperationNo,OperatorID) 
		as T2 Inner Join #NipponProdData ON T2.MachineID=#NipponProdData.MachineID and T2.ComponentID=#NipponProdData.ComponentID 
		and T2.OperationNo=#NipponProdData.OperationNo and T2.OperatorID=#NipponProdData.OperatorID '
		print (@strsql)
		EXEC(@StrSql)
		
		Select @strsql=''
		SELECT @StrSql='UPDATE #NipponProdData SET UtilisedTime = Isnull(#NipponProdData.UtilisedTime,0)+IsNull(T2.MinorDownTime,0)
		From (SELECT MachineID,ComponentID,OperationNo,OperatorID,sum(datediff(s,starttime,endtime)) as MinorDownTime
			FROM ShiftDownTimeDetails WHERE  PE_Flag = 1 and OperatorID='''+@OperatorID+'''
		and ddate>='''+Convert(NvarChar(20),@StartDate)+''' and dDate<='''+Convert(NvarChar(20),@EndDate)+''''
		Select @strsql = @strsql   + @StrDonwMachine
		SELECT @StrSql=@StrSql+' Group By MachineID,ComponentID,OperationNo,OperatorID) as T2 Inner Join #NipponProdData ON T2.MachineID=#NipponProdData.MachineID and T2.ComponentID=#NipponProdData.ComponentID 
		and T2.OperationNo=#NipponProdData.OperationNo and T2.OperatorID=#NipponProdData.OperatorID'
		print (@StrSql)
		EXEC (@StrSql)


		Select @strsql=''
		SELECT @StrSql='Update #NipponProdData Set DownTime=isnull(#NipponProdData.Downtime,0) + ISNULL(T2.DownTime,0) 
		From (Select MachineID,ComponentID,OperationNo,OperatorID,Sum(isnull(DownTime,0))AS DownTime From ShiftDownTimeDetails
		Where dDate>='''+Convert(NvarChar(10),@StartDate,120)+''' and dDate<='''+Convert(NvarChar(10),@EndDate,120)+''' and OperatorID='''+@OperatorID+''' ' 
		Select @strsql = @strsql   + @StrDonwMachine
		SELECT @StrSql=@StrSql+' Group By MachineID,ComponentID,OperationNo,OperatorID)AS T2 
		Inner Join #NipponProdData ON T2.MachineID=#NipponProdData.MachineID and T2.ComponentID=#NipponProdData.ComponentID 
		and T2.OperationNo=#NipponProdData.OperationNo and T2.OperatorID=#NipponProdData.OperatorID '
		print (@StrSql)
		EXEC (@StrSql)


		Select @strsql=''
		SELECT @StrSql='Update #NipponProdData Set DownTimeAE=ISNULL(#NipponProdData.DownTimeAE,0) + ISNULL(T2.DownTime,0) 
		From (Select MachineID,ComponentID,OperationNo,OperatorID,Sum(DownTime)AS DownTime From ShiftDownTimeDetails
		Where dDate>='''+Convert(NvarChar(20),@StartDate)+''' and dDate<='''+Convert(NvarChar(20),@EndDate)+''' and OperatorID='''+@OperatorID+''' '
		Select @strsql = @strsql   + @StrDonwMachine
		SELECT @StrSql=@StrSql+' Group By MachineID,ComponentID,OperationNo,OperatorID)AS T2 Inner Join #NipponProdData ON T2.MachineID=#NipponProdData.MachineID and T2.ComponentID=#NipponProdData.ComponentID 
		and T2.OperationNo=#NipponProdData.OperationNo and T2.OperatorID=#NipponProdData.OperatorID '
		EXEC(@StrSql)

		Select @strsql=''
		SELECT @StrSql=' UPDATE #NipponProdData SET MgmtLoss = ISnull(#NipponProdData.MgmtLoss,0) +  IsNull(T1.LOSS,0) --DR0292
		From (select MachineID,ComponentID,OperationNo,OperatorID,
		sum(
				CASE
			WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0
			THEN isnull(ShiftDownTimeDetails.Threshold,0)
			ELSE ShiftDownTimeDetails.DownTime
				END) AS LOSS
			From ShiftDownTimeDetails
			Where dDate>='''+Convert(NvarChar(20),@StartDate)+''' and dDate<='''+Convert(NvarChar(20),@EndDate)+''' and ShiftDownTimeDetails.Ml_Flag=1 and OperatorID='''+@OperatorID+''''
			Select @strsql = @strsql   + @StrDonwMachine
		SELECT @StrSql=@StrSql+' Group By MachineID,ComponentID,OperationNo,OperatorID
		) as T1 Inner Join #NipponProdData ON T1.MachineID=#NipponProdData.MachineID and T1.ComponentID=#NipponProdData.ComponentID 
		and T1.OperationNo=#NipponProdData.OperationNo and T1.OperatorID=#NipponProdData.OperatorID '
		print @StrSql
		EXEC(@StrSql)

		

		update #NipponProdData set DownTime=isnull(DownTime,0)-isnull(MgmtLoss,0)

		IF ISNULL(@OperatorID,'')<>''
		BEGIN
			update #NipponProdData set UtilisedTime=T1.Util,MgmtLoss=T1.Mgmt ,
			DownTime =T1.Dtime,	CN =T1.CN1,DownTimeAE=T1.DownTimeAE
			from (select MachineID,ComponentID,OperationNo,OperatorID,sum(UtilisedTime) as Util,sum(MgmtLoss) as Mgmt,
			sum(DownTime) as Dtime,sum(CN) as CN1, sum(DownTimeAE) as DownTimeAE from #NipponProdData 
			where OperatorID=@OperatorID
			group by MachineID,ComponentID,OperationNo,OperatorID
			) as  T1 inner join #NipponProdData ON T1.MachineID=#NipponProdData.MachineID and T1.ComponentID=#NipponProdData.ComponentID 
		and T1.OperationNo=#NipponProdData.OperationNo and T1.OperatorID=#NipponProdData.OperatorID

			delete from #NipponProdData where #NipponProdData.OperatorID<>@Operatorid
		END

		UPDATE #NipponProdData
		SET PE = (CN/UtilisedTime) ,
			AE = (UtilisedTime)/(UtilisedTime + ISNULL( DownTimeAE,0)-isnull(MgmtLoss,0))
		WHERE UtilisedTime <> 0
	
		UPDATE #NipponProdData
		SET
		OEE = CASE WHEN (SELECT OEEFormula FROM MachineOEEFormula_Shanti where MachineID = #NipponProdData.MachineID) = 'AE'
					THEN (AE*100)
					WHEN (SELECT OEEFormula FROM MachineOEEFormula_Shanti where MachineID = #NipponProdData.MachineID) = 'AE*PE'
						THEN (AE * ISNULL(PE,1))*100
					ELSE  (PE * AE * ISNULL(QE,1))*100
					END,
		PE = PE * 100 ,
		AE = AE * 100

	

		Update #NipponProdData set EffCycleTime=T1.EffCT, EffLoadUnload=T1.EffLD
		from (
		select MachineID,ComponentID,OperationNo,OperatorID,(cast(StdCycleTime as float)/round(cast(ActCycleTime as float),2))*100 as EffCT,
		(cast(StdLoadUnload as float)/round(cast(ActLoadUnload as float),2))*100 as EffLD from #NipponProdData
		where ActCycleTime<>'0' and ActLoadUnload<>'0'
		)T1 inner join #NipponProdData ON T1.MachineID=#NipponProdData.MachineID and T1.ComponentID=#NipponProdData.ComponentID 
		and T1.OperationNo=#NipponProdData.OperationNo and T1.OperatorID=#NipponProdData.OperatorID

		------------------------------------------Update cycleEnd in MC+COMP+OPN+OPR Level start-------------------------------------------------------------------------------------------------
	
		update #NipponProdData set CycleEndTime=isnull(t1.CycleEndTime,'')
		from
		(
		select distinct m1.machineid,c1.componentid,c2.operationno, E1.employeeid,max(a1.ndtime) as CycleEndTime from autodata a1
		inner join machineinformation m1 on m1.InterfaceID=a1.mc
		inner join componentinformation c1 on c1.InterfaceID=a1.comp
		inner join componentoperationpricing c2 on c2.machineid=m1.machineid and c2.componentid=c1.componentid and c2.InterfaceID=a1.opn
		inner join employeeinformation e1 on e1.interfaceid=a1.opr
		inner join #NipponProdData n1 on n1.MachineID=c2.machineid and n1.ComponentID=c2.componentid and n1.OperationNo=c2.operationno and n1.OperatorID=e1.Employeeid
		where (convert(nvarchar(20),a1.ndtime,120)>=@start and convert(nvarchar(20),a1.ndtime,120)<=@end)
		group by m1.machineid,c1.componentid,c2.operationno, E1.employeeid
		)t1 inner join #NipponProdData n2 on n2.MachineID=t1.machineid and n2.ComponentID=t1.componentid and n2.OperationNo=t1.operationno and n2.OperatorID=t1.Employeeid

		------------------------------------------Update cycleEnd in MC+COMP+OPN+OPR Level end-------------------------------------------------------------------------------------------------

		
		select MachineID,CycleEndTime,ComponentID,OperationNo,OperatorID,e1.Name as OperatorName,ProdCount,StdCycleTime,round(ActCycleTime,2) as ActCycleTime,round(EffCycleTime,2) as EffCycleTime,
		StdLoadUnload,round(ActLoadUnload,2) as ActLoadUnload,round(EffLoadUnload,2) as EffLoadUnload,
		dbo.f_FormatTime(DownTime,@timeformat) as DownTime,round(PE,2) as PE,round(AE,2) as AE,round(OEE,2) as OEE from #NipponProdData
		left join employeeinformation e1 on e1.Employeeid=#NipponProdData.OperatorID

		select dbo.f_formattime(sum(T1.DownTime), @timeformat) as TotalDownTime, round(AVG(T1.OEE),2) AS AvgOEE, round(AVG(T1.EffCycleTime),2) AS AvgEffCycleTime,round(avg(T1.EffLoadUnload),2) as AvgEffLoadUnload
		from(
		select MachineID,ComponentID,OperationNo,OperatorID,ProdCount,StdCycleTime,round(ActCycleTime,2) as ActCycleTime,round(EffCycleTime,2) as EffCycleTime,
		StdLoadUnload,round(ActLoadUnload,2) as ActLoadUnload,round(EffLoadUnload,2) as EffLoadUnload,
		DownTime,round(PE,2) as PE,round(AE,2) as AE,round(OEE,2) as OEE from #NipponProdData)T1
		return



	END

	If @Parameter='Operator_DownData'
	BEGIN
		Select @strsql = 'SELECT OperatorID, '
		Select @strsql = @strsql + 'StartTime, '
		Select @strsql = @strsql + 'EndTime,'
		Select @strsql = @strsql + 'DownID, dbo.f_FormatTime(DownTime ,''' + @TimeFormat + ''')As DownTime'
		Select @strsql = @strsql + ' FROM ShiftDownTimeDetails '
		Select @strsql = @strsql + ' WHERE (dDate = ''' + convert(nvarchar(20),@StartDate) + ''')'
		Select @strsql = @strsql +  @StrDOpr  + @strDMachine
		exec (@strsql)
	END
END
DROP Table  #ProdData
DROP Table  #ShiftDetails
DROP Table  #Header
END
