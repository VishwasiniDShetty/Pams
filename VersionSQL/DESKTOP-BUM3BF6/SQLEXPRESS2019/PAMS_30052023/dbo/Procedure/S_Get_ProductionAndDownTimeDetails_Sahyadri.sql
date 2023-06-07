/****** Object:  Procedure [dbo].[S_Get_ProductionAndDownTimeDetails_Sahyadri]    Committed by VersionSQL https://www.versionsql.com ******/

/*
Created date: 10-Oct-2022
Created By: Raksha R

exec [dbo].[S_Get_ProductionAndDownTimeDetails_Sahyadri] 'SAHYADRI','CNC','JYOTI 1,JYOTI 2,JYOTI 3','','2022-09-19 00:00:00.000','','Day'

exec [dbo].[S_Get_ProductionAndDownTimeDetails_Sahyadri] 'SAHYADRI','CNC','JYOTI 1,JYOTI 2,JYOTI 3','first','2022-09-19 00:00:00.000','','Shift'
exec [dbo].[S_Get_ProductionAndDownTimeDetails_Sahyadri] 'SAHYADRI','CNC','JYOTI 1,JYOTI 2,JYOTI 3','Second','2022-09-19 00:00:00.000','','Shift'

exec [dbo].[S_Get_ProductionAndDownTimeDetails_Sahyadri] 'SAHYADRI','CNC','JYOTI 1,JYOTI 2,JYOTI 3','','2022-09-01 00:00:00.000','2022-09-30 00:00:00.000','Month'
exec [dbo].[S_Get_ProductionAndDownTimeDetails_Sahyadri] 'SAHYADRI','CNC','JYOTI 1,JYOTI 2,JYOTI 3','','2022-09-19 00:00:00.000','2022-09-19 00:00:00.000','Consolidated'
*/
CREATE Procedure [dbo].[S_Get_ProductionAndDownTimeDetails_Sahyadri]
@PlantID nvarchar(50)='',
@GroupID nvarchar(max)='',
@MachineID nvarchar(max)='',
@Shift nvarchar(50)='',
@StartDate datetime='',
@EndDate datetime='',
@Param nvarchar(50)=''   /****  Day/ Shift/ Month/ Consolidated ****/


AS
BEGIN

Declare @StrPlantID AS NVarchar(255)
Declare @Strsql nvarchar(MAX)
Declare @Strmachine nvarchar(MAX)
declare @StrGroupID as nvarchar(MAX)
declare @StrMCJoined as nvarchar(max)
declare @StrGroupJoined as nvarchar(max)
Declare @timeformat AS nvarchar(12)
Declare @StrTPMMachines AS nvarchar(500)

Select @StrPlantID=''
select @StrGroupID=''
Select @Strsql = ''
Select @Strmachine = ''
SELECT @StrTPMMachines=''

Select @timeformat ='ss'
Select @timeformat = isnull((Select valueintext from cockpitdefaults where parameter='timeformat'),'ss')
if (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')
Begin
Select @timeformat = 'ss'
End

Create Table #ProdData
(
	[Day]  DateTime,
	Shift  NVarChar(50),
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
	TargetCount int
)

	IF ( SELECT TOP 1 ValueInText FROM  CockpitDefaults WHERE Parameter='TpmEnbMac')='E'
	BEGIN
		SET  @StrTPMMachines = ' AND M.TPMTrakEnabled = 1 '
	END
	ELSE
	BEGIN
		SET  @StrTPMMachines = ' '
	END

	If isnull(@PlantID,'') <> ''
	Begin
		Select @StrPlantID = ' And ( PlantMachine.PlantID = N''' + @PlantID + ''' )'
	End

	If isnull(@Machineid,'') <> ''
	Begin	
		select @StrMCJoined =  (case when (coalesce( +@StrMCJoined + ',''', '''')) = ''''  then 'N''' else @StrMCJoined+',N''' end) +item+'''' from [SplitStrings](@MachineID, ',')    
		if @StrMCJoined = 'N'''''  
		set @StrMCJoined = '' 
		select @MachineID = @StrMCJoined

		SET @strMachine = ' AND M.machineid in (' + @MachineID +')'
	End

	If isnull(@GroupID,'') <> ''
	Begin
		select @StrGroupJoined =  (case when (coalesce( +@StrGroupJoined + ',''', '''')) = ''''  then 'N''' else @StrGroupJoined+',N''' end) +item+'''' from [SplitStrings](@GroupID, ',')    
		if @StrGroupJoined = 'N'''''  
		set @StrGroupJoined = '' 
		select @GroupID = @StrGroupJoined

		Select @StrGroupID = ' And ( PlantMachineGroups.GroupID IN (' + @GroupID + ')) '
	End

IF @Param='Consolidated' or @Param='Month'
BEGIN
	SELECT @StrSql='INSERT INTO #ProdData(
		MachineID ,PEffy ,AEffy ,QEffy,OEffy ,
		ProdCount ,AcceptedParts,RejCount,MarkedForRework,UtilisedTime ,DownTime ,CN )
		SELECT Distinct M.MachineID,0,0,0,0,0,0,0,0 ,0,0,0
		FROM Machineinformation M
		Left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
		LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID
		Where M.Interfaceid>''0'''
		SELECT @StrSql=@StrSql+ @StrPlantID+ @Strmachine+@StrTPMMachines+@StrGroupID
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

	SELECT @StrSql='UPDATE #ProdData SET UtilisedTime = Isnull(#ProdData.UtilisedTime,0)+IsNull(T2.MinorDownTime,0)
	From (SELECT MachineID,sum(datediff(s,starttime,endtime)) as MinorDownTime
		FROM ShiftDownTimeDetails WHERE PE_Flag = 1
	and ddate>='''+Convert(NvarChar(20),@StartDate)+''' and dDate<='''+Convert(NvarChar(20),@EndDate)+''''
	SELECT @StrSql=@StrSql+' group by machineid) as T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
	EXEC(@StrSql)

	--Updating DownTime for the selected time period
	---commented ML_flag=0 to neglect only threshold value from Mgmtloss
	SELECT @StrSql='Update #ProdData Set DownTime=ISNULL(#ProdData.DownTime,0) + ISNULL(T2.DownTime,0)  --DR0292
	From (Select MachineID,Sum(DownTime)AS DownTime From ShiftDownTimeDetails
	Where dDate>='''+Convert(NvarChar(20),@StartDate)+''' and dDate<='''+Convert(NvarChar(20),@EndDate)+''' '-- And ML_Flag=0'
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
	
	----to exclude threshold of ML from Downtime
	UPDATE #ProdData SET DownTime=isnull(DownTime,0)-isnull(MgmtLoss,0) --DR0292


	UPDATE #ProdData SET QEffy= ISNULL(#ProdData.QEffy,0) + IsNull(T1.QE,0) --DR0292
	FROM(Select MachineID,
	CAST((Sum(AcceptedParts))As Float)/CAST((Sum(IsNull(AcceptedParts,0))+Sum(IsNull(MarkedForRework,0))+Sum(IsNull(RejCount,0))) AS Float)As QE
	From #ProdData Where AcceptedParts<>0 Group By MachineID
	)AS T1 Inner Join #ProdData ON  #ProdData.MachineID=T1.MachineID
		
	UPDATE #ProdData
	SET
		PEffy = (CN/UtilisedTime) ,
		AEffy = (UtilisedTime)/(UtilisedTime + ISNULL( DownTime,0)-isnull(MgmtLoss,0))
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

	Select
	p2.GroupID,
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
	dbo.f_formattime(isnull(MgmtLoss,0),@timeformat) As MgmtLoss,
	dbo.f_formattime(isnull(UtilisedTime,0)+isnull(DownTime,0)+isnull(MgmtLoss,0),@timeformat) As TotalTime,
	dbo.f_formattime(isnull(UtilisedTime,0),'ss') As UtilisedTimeInSec  ,
	dbo.f_formattime(isnull(DownTime,0),'ss') As DownTimeInSec,
	dbo.f_formattime(isnull(MgmtLoss,0),'ss') As MgmtLossInSec,
	dbo.f_formattime(isnull(UtilisedTime,0)+isnull(DownTime,0)+isnull(MgmtLoss,0),'ss') As TotalTimeInSec
	From #ProdData 
	left outer join PlantMachineGroups p2 on #ProdData.MachineID=p2.MachineID
	Order By #ProdData.MachineID
END

IF @Param='Shift' or @Param='Day'
BEGIN
	Set @EndDate=@StartDate

	SELECT @StrSql='INSERT INTO #ProdData(
		MachineID ,PEffy ,AEffy ,QEffy,OEffy ,
		ProdCount ,AcceptedParts,RejCount,MarkedForRework,UtilisedTime ,DownTime ,CN )
		SELECT Distinct M.MachineID,0,0,0,0,0,0,0,0 ,0,0,0
		FROM Machineinformation M
		Left Outer Join PlantMachine ON PlantMachine.MachineID=M.MachineID
		LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID
		Where M.Interfaceid>''0'''
		SELECT @StrSql=@StrSql+ @StrPlantID+ @Strmachine+@StrTPMMachines+@StrGroupID
		Print @StrSql
		EXEC(@StrSql)

	--Updating ProdCount for the selected time period
	SELECT @StrSql='Update #ProdData Set ProdCount=ISNULL(T2.ProdCount,0) 
	From (Select MachineID,Sum(Prod_Qty)AS ProdCount From ShiftProductionDetails
	Where pDate>='''+Convert(NvarChar(20),@StartDate)+''' and pDate<='''+Convert(NvarChar(20),@EndDate)+'''
	and  (Shift = '''+@Shift+'''  or isnull('''+@Shift+''','''')='''') '
	SELECT @StrSql=@StrSql+' Group By MachineID)AS T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
	print @StrSql
	EXEC(@StrSql)
		
	--Updating AcceptedParts for the selected time period
	SELECT @StrSql='Update #ProdData Set AcceptedParts=ISNULL(T2.AcceptedParts,0) 
	From (Select MachineID,Sum(AcceptedParts)AS AcceptedParts From ShiftProductionDetails
	Where pDate>='''+Convert(NvarChar(20),@StartDate)+''' and pDate<='''+Convert(NvarChar(20),@EndDate)+'''
	and  (Shift = '''+@Shift+'''  or isnull('''+@Shift+''','''')='''') '
	SELECT @StrSql=@StrSql+' Group By MachineID)AS T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
	print @StrSql
	EXEC(@StrSql)

	--Updating MarkedForRework for the selected time period
	SELECT @StrSql='Update #ProdData Set MarkedForRework=ISNULL(T2.MarkedForRework,0) 
	From (Select MachineID,Sum(Marked_For_Rework)AS MarkedForRework From ShiftProductionDetails
	Where pDate>='''+Convert(NvarChar(20),@StartDate)+''' and pDate<='''+Convert(NvarChar(20),@EndDate)+'''
	and  (Shift = '''+@Shift+'''  or isnull('''+@Shift+''','''')='''') '
	SELECT @StrSql=@StrSql+' Group By MachineID)AS T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
	print @StrSql
	EXEC(@StrSql)
		
	--Updating RejCount for the selected time period
	SELECT @StrSql='Update #ProdData Set RejCount=ISNULL(T2.RejCount,0) 
	From (Select MachineID,Sum(Rejection_Qty)AS RejCount From ShiftProductionDetails
	Inner Join ShiftRejectionDetails On ShiftProductionDetails.ID=ShiftRejectionDetails.ID
	Where pDate>='''+Convert(NvarChar(20),@StartDate)+''' and pDate<='''+Convert(NvarChar(20),@EndDate)+'''
	and  (Shift = '''+@Shift+'''  or isnull('''+@Shift+''','''')='''') '
	SELECT @StrSql=@StrSql+' Group By MachineID)AS T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
	EXEC(@StrSql)

	--Updating CN for the selected time period
	Update #ProdData Set CN=ISNULL(T2.CN,0) 
	From (
	Select MachineID,sum(Prod_Qty *(CO_StdMachiningTime+CO_StdLoadUnload)) AS CN
	From ShiftProductionDetails
	Where pDate>=@StartDate and pDate<=@EndDate
	and  (Shift = @Shift  or isnull(@Shift,'')='' )
	Group By MachineID )AS T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID
		
		
	--Updating UtilisedTime for the selected time period
	SELECT @StrSql='UPDATE #ProdData SET UtilisedTime = IsNull(T2.UtilisedTime,0) 
	From (select MachineID,Sum(Sum_of_ActCycleTime)As UtilisedTime
	From ShiftProductionDetails
	Where pDate>='''+Convert(NvarChar(20),@StartDate)+''' and pDate<='''+Convert(NvarChar(20),@EndDate)+'''
	and  (Shift = '''+@Shift+'''  or isnull('''+@Shift+''','''')='''') '
	SELECT @StrSql=@StrSql+' Group By MachineID) as T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
	EXEC(@StrSql)

	--ER0135-ER0138-karthikg-Machinewise-Consolidated-s_GetShiftAgg_ProductionReport '2007-12-01','2007-12-01','','','','','MachineWise','Consolidated'
	SELECT @StrSql='UPDATE #ProdData SET UtilisedTime = Isnull(#ProdData.UtilisedTime,0)+IsNull(T2.MinorDownTime,0)
	From (SELECT MachineID,sum(datediff(s,starttime,endtime)) as MinorDownTime
		FROM ShiftDownTimeDetails WHERE PE_Flag = 1
	and ddate>='''+Convert(NvarChar(20),@StartDate)+''' and dDate<='''+Convert(NvarChar(20),@EndDate)+'''
	and  (Shift = '''+@Shift+'''  or isnull('''+@Shift+''','''')='''') '
	SELECT @StrSql=@StrSql+' group by machineid) as T2 Inner Join #ProdData ON T2.MachineID=#ProdData.MachineID'
	--print @StrSql
	EXEC(@StrSql)

	--Updating DownTime for the selected time period
	---commented ML_flag=0 to neglect only threshold value from Mgmtloss
	SELECT @StrSql='Update #ProdData Set DownTime=ISNULL(#ProdData.DownTime,0) + ISNULL(T2.DownTime,0)  --DR0292
	From (Select MachineID,Sum(DownTime)AS DownTime From ShiftDownTimeDetails
	Where dDate>='''+Convert(NvarChar(20),@StartDate)+''' and dDate<='''+Convert(NvarChar(20),@EndDate)+''' 
	and  (Shift = '''+@Shift+'''  or isnull('''+@Shift+''','''')='''') '   -- And ML_Flag=0'
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
			Where dDate>='''+Convert(NvarChar(20),@StartDate)+''' and dDate<='''+Convert(NvarChar(20),@EndDate)+'''
			and  (Shift = '''+@Shift+'''  or isnull('''+@Shift+''','''')='''') and ShiftDownTimeDetails.Ml_Flag=1 '
		SELECT @StrSql=@StrSql+' Group By MachineID
		) as T1 Inner Join #ProdData ON  #ProdData.MachineID=T1.MachineID '
		EXEC(@StrSql)

	----to exclude threshold of ML from Downtime
	UPDATE #ProdData SET DownTime=isnull(DownTime,0)-isnull(MgmtLoss,0) --DR0292


	UPDATE #ProdData SET QEffy= ISNULL(#ProdData.QEffy,0) + IsNull(T1.QE,0) --DR0292
	FROM(Select MachineID,
	CAST((Sum(AcceptedParts))As Float)/CAST((Sum(IsNull(AcceptedParts,0))+Sum(IsNull(MarkedForRework,0))+Sum(IsNull(RejCount,0))) AS Float)As QE
	From #ProdData Where AcceptedParts<>0 Group By MachineID
	)AS T1 Inner Join #ProdData ON  #ProdData.MachineID=T1.MachineID
		
	UPDATE #ProdData
	SET
		PEffy = (CN/UtilisedTime) ,
		AEffy = (UtilisedTime)/(UtilisedTime + ISNULL( DownTime,0)-isnull(MgmtLoss,0))
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

	Select
	p2.GroupID,
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
	dbo.f_formattime(isnull(MgmtLoss,0),@timeformat) As MgmtLoss,
	dbo.f_formattime(isnull(UtilisedTime,0)+isnull(DownTime,0)+isnull(MgmtLoss,0),@timeformat) As TotalTime,
	dbo.f_formattime(isnull(UtilisedTime,0),'ss') As UtilisedTimeInSec  ,
	dbo.f_formattime(isnull(DownTime,0),'ss') As DownTimeInSec,
	dbo.f_formattime(isnull(MgmtLoss,0),'ss') As MgmtLossInSec,
	dbo.f_formattime(isnull(UtilisedTime,0)+isnull(DownTime,0)+isnull(MgmtLoss,0),'ss') As TotalTimeInSec
	From #ProdData 
	left outer join PlantMachineGroups p2 on #ProdData.MachineID=p2.MachineID
	Order By #ProdData.MachineID
END


END
