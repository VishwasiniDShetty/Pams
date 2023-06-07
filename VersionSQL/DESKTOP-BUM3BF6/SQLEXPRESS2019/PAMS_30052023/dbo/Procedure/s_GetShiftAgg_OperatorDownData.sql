/****** Object:  Procedure [dbo].[s_GetShiftAgg_OperatorDownData]    Committed by VersionSQL https://www.versionsql.com ******/

/**************************************** -- HISTORY -- ******************************************
Procedure Created By Sangeeta Kallur on 21-Nov-2006
Procedure Changed By SSK on 23/Nov/2006 :
	 Bz of change in column names of 'ShiftProductionDetails','ShiftDownTimeDetails'tables.
mod 1 :- ER0182 By Kusuma M.H on 08-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
Note:For ER0181 No component operation qualification found.
**************************************************************************************************/

CREATE    PROCEDURE [dbo].[s_GetShiftAgg_OperatorDownData]
	@StartDate As DateTime,
	@EndDate As DateTime,
	@ShiftName As  NVarChar(20)='',
	@PlantID As NVarChar(50)='',
	@MachineID As nvarchar(50) = '',
	@OperatorID As nvarchar(50) = ''
	
AS
BEGIN
----------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------
Declare @Strsql nvarchar(4000)
Declare @timeformat AS nvarchar(12)

Declare @StrDmachine nvarchar(255)
Declare @StrDPlantID AS NVarchar(255)
Declare @StrDShift AS NVarchar(255)
Declare @StrDOpr nvarchar(255)

Select @Strsql = ''
Select @StrDmachine = ''
Select @StrDPlantID=''
Select @StrDShift=''
Select @StrDOpr=''


------------------------------------------------------------------------------------------------------------
If isnull(@PlantID,'') <> ''
Begin
	---mod 1
--	Select @StrDPlantID = ' And ( ShiftDownTimeDetails.PlantID = ''' + @PlantID + ''' )'
	Select @StrDPlantID = ' And ( ShiftDownTimeDetails.PlantID = N''' + @PlantID + ''' )'
	---mod 1
End
If isnull(@Machineid,'') <> ''
Begin
	---mod 1
--	Select @StrDmachine = ' And ( ShiftDownTimeDetails.MachineID = ''' + @MachineID + ''')'
	Select @StrDmachine = ' And ( ShiftDownTimeDetails.MachineID = N''' + @MachineID + ''')'
	---mod 1
End
If isnull(@ShiftName,'') <> ''
Begin
	---mod 1
--	Select @StrDShift = ' And ( ShiftDownTimeDetails.Shift = ''' + @ShiftName + ''')'
	Select @StrDShift = ' And ( ShiftDownTimeDetails.Shift = N''' + @ShiftName + ''')'
	---mod 1
End
If isnull(@OperatorID,'') <> ''
Begin
	---mod 1
--	Select @StrDOpr = ' And ( ShiftDownTimeDetails.OperatorID = ''' + @OperatorID + ''')'
	Select @StrDOpr = ' And ( ShiftDownTimeDetails.OperatorID = N''' + @OperatorID + ''')'
	---mod 1
End

-------------------------------------------------------------------------------------------------------------

Select @timeformat ='ss'
Select @timeformat = isnull((Select valueintext from cockpitdefaults where parameter='timeformat'),'ss')
if (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')
Begin
 Select @timeformat = 'ss'
End

--------------------------------------------------------------------------------------------------------
	
		Select @strsql = 'SELECT OperatorID, '
		Select @strsql = @strsql + 'StartTime, '
		Select @strsql = @strsql + 'EndTime,'
		Select @strsql = @strsql + 'DownID, dbo.f_FormatTime(DownTime ,''' + @TimeFormat + ''')As DownTime'
		Select @strsql = @strsql + ' FROM ShiftDownTimeDetails '
		Select @strsql = @strsql + ' WHERE (dDate = ''' + convert(nvarchar(20),@StartDate) + ''')'
		Select @strsql = @strsql +  @StrDOpr  + @strDMachine + @StrDPlantID
		exec (@strsql)
	


END
