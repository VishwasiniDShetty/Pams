/****** Object:  Procedure [dbo].[s_GetShiftwiseProductionReportForADay]    Committed by VersionSQL https://www.versionsql.com ******/

/***************************************************************************

-- Author  : Sangeeta Kallur
-- Date    : 03-FEB-2006
-- Comments: To get shiftwise production for a day
--	     Raised by Nutech

Procedure Changed By SSK on 07-Oct-2006 to include Plant Concept
mod 1 :- ER0182 By Kusuma M.H on 09-Jun-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
Note:ER0181 not done because CO qualification not found.

***************************************************************************/


CREATE   PROCEDURE [dbo].[s_GetShiftwiseProductionReportForADay]
	@StartDate  AS datetime,
	@ShiftName  AS nvarchar(20)='',
	@MachineID AS nvarchar(50) = '',
	@Component AS nvarchar(50) = '',
	@OperationNo AS nvarchar(50) = '',
	@PlantID AS nvarchar(50) = ''
	
AS
BEGIN
DECLARE @StrSql AS nvarchar(4000)
DECLARE @StrMachine AS nvarchar(255)
DECLARE @StrPlantID AS nvarchar(255)

SELECT @StrSql=''
SELECT @StrMachine=''
SELECT @StrPlantID=''

IF ISNULL(@MachineID,'')<>''
BEGIN
	---mod 1
--	SELECT @StrMachine=' AND MachineInformation.Machineid='''+ @MachineID +''''
	SELECT @StrMachine=' AND MachineInformation.Machineid = N'''+ @MachineID +''''
	---mod 1
END
IF ISNULL(@PlantID,'')<>''
BEGIN
	---mod 1
--	SELECT @StrPlantID=' AND PlantMachine.PlantID='''+ @PlantID +''''
	SELECT @StrPlantID=' AND PlantMachine.PlantID = N'''+ @PlantID +''''
	---mod 1
END
--Create table to get Shift Details/Defination
	CREATE TABLE #ShiftDefn(
		ShiftDate  DateTime,		
		Shiftname   nvarchar(20),
		ShftSTtime  DateTime,
		ShftEndTime  DateTime	
	)

	IF  isnull(@ShiftName,'')<> ''
		BEGIN
			INSERT INTO #ShiftDefn(ShiftDate,Shiftname,ShftSTtime,ShftEndTime)  
			Exec s_GetShiftTime @StartDate,@ShiftName
		END
	ELSE
		BEGIN
			INSERT INTO #ShiftDefn(ShiftDate,Shiftname,ShftSTtime,ShftEndTime)  
			Exec s_GetShiftTime @StartDate,''
		END

	CREATE TABLE #MchId(
		Machineid Nvarchar(40)
	)

	
	SELECT @StrSql='INSERT INTO #MchId(Machineid)
	SELECT MachineInformation.Machineid FROM MachineInformation 
	Left Outer Join PlantMachine on MachineInformation.MachineID=PlantMachine.MachineID
	Where  MachineInformation.Machineid>''0'''
	SELECT @StrSql=@StrSql + @StrPlantID + @StrMachine
	EXEC(@StrSql)

	SELECT Machineid,Shiftname,ShftSTtime,ShftEndTime FROM #ShiftDefn,#MchId 
	group by Machineid,Shiftname,ShftSTtime,ShftEndTime
END
