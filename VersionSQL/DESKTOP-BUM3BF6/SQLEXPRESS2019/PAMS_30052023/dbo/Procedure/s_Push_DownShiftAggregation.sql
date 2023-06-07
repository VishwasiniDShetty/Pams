/****** Object:  Procedure [dbo].[s_Push_DownShiftAggregation]    Committed by VersionSQL https://www.versionsql.com ******/

/*
Procedure Created by Sangeeta Kallur on 07-Nov-2006 For Down Time Shift Agregation
Procedure Altered by Sangeeta Kallur on 08-Nov-2006 : to include new parameter @Type{PUSH/DELETE}
Procedure Altered by Sangeeta Kallur on 23-Nov-2006 :
	Bz of change in column names of 'ShiftDownTimeDetails'
Procedure Changed By Sangeeta Kallur on 06-Dec-2006 : To include & populate new column StdSetUpTime
Procedure Altered by KarthikG on 12-Jun-2008 for ER0138. New column PE_Flag has been added to the table 
	ShiftDownTimeDetails and filled with data from prodeffy column from downcodeinformation depending on the downid
MOD 1:- fOR DR0148 BY mRUDULA ON 28-NOV-2008. pUT RETURN AT THE BEGINNING TO AVOID AGGREGATION FROM
          OLD exe

*/
CREATE                             PROCEDURE [dbo].[s_Push_DownShiftAggregation]
	@Date As DateTime,
	@Shift As Nvarchar(20),
	@MachineID As NvarChar(50),
	@PlantID As NvarChar(50),
	@Type As Nvarchar(20)
	
AS
BEGIN
--MOD 1
RETURN
--MOD 1
Declare @strMachine as nvarchar(250)
Declare @strPlantID as nvarchar(250)
Declare @StrSql as nvarchar(4000)
declare @StartTime as datetime
declare @EndTime as datetime
CREATE TABLE #ShiftDetails (
		PDate datetime,
		Shift nvarchar(20),
		ShiftStart datetime,
		ShiftEnd datetime
		)
		
	
SET @StrSql = ''
SET @strMachine = ''
SET @strPlantID = ''
IF @Type='PUSH'
BEGIN
	if isnull(@MachineID,'')<> ''
	begin
		SET @strMachine = ' AND MachineInformation.MachineID = ''' + @machineid + ''''
	end
	if isnull(@PlantID,'')<> ''
	Begin
		SET @strPlantID = ' AND PlantMachine.PlantID = ''' + @PlantID + ''''
	End
END
ELSE
BEGIN
	if isnull(@MachineID,'')<> ''
	begin
		SET @strMachine = ' AND ShiftDownTimeDetails.MachineID = ''' + @machineid + ''''
	end
		if isnull(@PlantID,'')<> ''
	Begin
		SET @strPlantID = ' AND ShiftDownTimeDetails.PlantID = ''' + @PlantID + ''''
	End
END
IF @Type='PUSH'
	BEGIN
	
	--Get Shift Start and Shift End
	INSERT #ShiftDetails(Pdate, Shift, ShiftStart, ShiftEnd)
	EXEC s_GetShiftTime @Date,@Shift
	
	--Introduced TOP 1 to take care of input 'ALL' shifts
	select @StartTime = (select TOP 1 shiftstart from #ShiftDetails ORDER BY shiftstart ASC)
	select @EndTime = (select TOP 1 shiftend from #ShiftDetails ORDER BY shiftend DESC)
	--Building String to get All Types of Down Records for shift.
	SELECT @StrSql=' INSERT INTO ShiftDownTimeDetails(
				dDate,Shift,
				PlantID,MachineID,
				ComponentID,
				OperationNo,
				OperatorID,
				StartTime,
				EndTime,
				DownCategory,
				DownID,
				DownTime, --In Seconds
				ML_Flag,
				Threshold,
				RetPerMcHour_Flag,StdSetupTime,PE_Flag)
		 SELECT '''+Convert(NvarChar(20),@Date)+''','''+@Shift+''',PlantMachine.PlantID,machineinformation.MachineID, componentinformation.componentid,
		 componentoperationpricing.operationno, EmployeeInformation.EmployeeID,Sttime,Ndtime,
		 DownCodeInformation.Catagory,DownCodeInformation.DownID,0,DownCodeInformation.AvailEffy,ISNULL(DownCodeInformation.Threshold,0),
		 DownCodeInformation.retpermchour,ISNULL(componentoperationpricing.StdSetupTime,0),ISNULL(DownCodeInformation.prodeffy,0)
		 FROM autodata
			INNER JOIN EmployeeInformation ON autodata.Opr=EmployeeInformation.InterfaceID
			INNER JOIN  machineinformation ON autodata.mc = machineinformation.InterfaceID
			LEFT OUTER JOIN PlantMachine ON machineinformation.MachineID=PlantMachine.MachineID
			INNER JOIN DownCodeInformation ON autodata.Dcode=DownCodeInformation.InterfaceID
			INNER JOIN  componentinformation ON autodata.comp = componentinformation.InterfaceID
			INNER JOIN componentoperationpricing ON (autodata.opn = componentoperationpricing.InterfaceID) AND (componentinformation.componentid = componentoperationpricing.componentid)
	 	 WHERE Datatype=2 And
	 	((StTime>='''+Convert(NvarChar(20),@StartTime)+''' And ndTime<='''+Convert(NvarChar(20),@EndTime)+''')
		 OR(StTime<'''+Convert(NvarChar(20),@StartTime)+''' And ndTime>'''+Convert(NvarChar(20),@StartTime)+''' And ndTime<='''+Convert(NvarChar(20),@EndTime)+''')
	 	OR(StTime>='''+Convert(NvarChar(20),@StartTime)+''' And StTime<'''+Convert(NvarChar(20),@EndTime)+''' And ndTime>'''+Convert(NvarChar(20),@EndTime)+''')
	 	OR(StTime<'''+Convert(NvarChar(20),@StartTime)+''' And ndTime>'''+Convert(NvarChar(20),@EndTime)+''')) '
		
		SELECT @StrSql = @StrSql+@strPlantID+@strMachine
		Exec (@StrSql)
		
		--Updating boundary records to shift start
		Update ShiftDownTimeDetails Set
		StartTime=@StartTime Where  MachineID=@MachineID And dDate=@Date And Shift=@Shift And StartTime<@StartTime
		
		--Updating boundary records to shift end
		Update ShiftDownTimeDetails Set 		
		EndTime=@EndTime Where  MachineID=@MachineID And dDate=@Date And Shift=@Shift And EndTime>@EndTime
		
		Update ShiftDownTimeDetails Set
		DownTime=DateDiff(second,StartTime,EndTime) Where dDate=@Date And Shift=@Shift And MachineID=@MachineID
	if isnull(@MachineID,'')<> ''
	begin
		SET @strMachine = ' AND ShiftDownTimeDetails.MachineID = ''' + @machineid + ''''
	end
	if isnull(@PlantID,'')<> ''
	Begin
		SET @strPlantID = ' AND ShiftDownTimeDetails.PlantID = ''' + @PlantID + ''''
	End
	
	SELECT @StrSql='Select DISTINCT *  from ShiftDownTimeDetails
	where dDATE='''+Convert(NvarChar(20),@Date)+''' AND SHIFT='''+@Shift+''''
SELECT @StrSql=@StrSql+@strPlantID+@strMachine
	exec(@StrSql)
END
ELSE
IF @Type='DELETE'
BEGIN
	SELECT @StrSql='Delete from ShiftDownTimeDetails Where dDATE='''+Convert(NvarChar(20),@Date)+''' AND SHIFT='''+@Shift+''''
	SELECT @StrSql=@StrSql+@strPlantID+@strMachine
	exec(@StrSql)
END
END
