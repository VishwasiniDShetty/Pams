/****** Object:  Procedure [dbo].[s_GetMachineAlarm]    Committed by VersionSQL https://www.versionsql.com ******/

/*************************************************************************
Procedure Developed By Sangeeta Kallur on 27-Mar-2006
Comments :: To Get Alarm Information at the Machine Level
mod 1 :- ER0182 By Kusuma M.H on 28-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
Note:For ER0181 No component operation qualification found.
DR0238 - SwathiKS - 24/Jun/2010 :: Error detected by database dll in the following report
	 SMARTMANAGER /ANALYSIS REPORT STANDARD/MachineWise Alarm Report CrystalReport - SM_MachineAlarms.rpt
	 Alarm Number has been changed decimal(18,2) to nvarchar(10)
DR0245 - SwathiKS - 2/Aug/2010 :: To handle Incorrect Syntax error in SmartCockpit-VDG Graph
ER0270 - KarthikR - 30/Oct/2010 :: To Show AlarmNumber in Piechart and Include MachineID in SM_MachineAlarms.rpt
*************************************************************************/
--s_GetMachineAlarm '2009-11-01 12:00:00','2009-11-30 12:00:00','','','',''
--SET DATEFORMAT YMD
--s_GetMachineAlarm '2010-02-24 12:00:00','2010-02-26 12:00:00','','','',''
--s_GetMachineAlarm '2010-02-24 1:10:17 PM','2010-02-26 1:10:17 PM','MBC BEHRINGER','Maintenance Alarms','','','Report'
CREATE            PROCEDURE [dbo].[s_GetMachineAlarm]
	@StartTime DateTime,
	@EndTime DateTime,
	@MachineID NVarChar(50)='' ,
	@AlarmCategory NvarChar(50)='',
	--@AlarmNumber DECIMAL(18,2)=0.0,--DR0238 - SwathiKS - 24/Jun/2010
	--@AlarmNumber nvarchar(10),--DR0245 - SwathiKS - 2/Aug/2010
	@AlarmNumber nvarchar(10)='',
	@PlantID nvarchar(50)='',
	@Param nvarchar(10)='Grid'
AS
BEGIN
SET DATEFORMAT YMD

CREATE TABLE #TmpAlarmTable
(
SerialNo  INT IDENTITY(1,1),
MachineID  NVarChar(50),
AlarmCategory  NVarChar(50),
--AlarmNumber  DECIMAL(18,2) ,--DR0238 - SwathiKS - 24/Jun/2010
AlarmNumber NVarChar(10),
AlarmDescription  NVarChar(100),
AlarmTime  DateTime
)
Declare @strPlantID as nvarchar(50)
DECLARE @StrSql AS NVarChar(4000)
SET @strPlantID = ''
SELECT @StrSql='INSERT INTO #TmpAlarmTable(MachineID,AlarmNumber,AlarmTime)'
SELECT @StrSql=@StrSql + ' SELECT Mch.MachineID,A.AlarmNumber,AlarmTime From AutoDataAlarms A INNER JOIN MachineInformation Mch on  Mch.Interfaceid=A.Machineid'
--SELECT @StrSql=@StrSql + ' LEFT OUTER JOIN MachineAlarmInformation M on A.alarmNumber=M.AlarmNumber AND M.MachineID=Mch.MachineID ' --ER0270 - KarthikR - 30/Oct/2010
SELECT @StrSql=@StrSql + ' LEFT OUTER JOIN MachineAlarmInformation M on cast(A.alarmNumber as int)=M.AlarmNumber AND M.MachineID=Mch.MachineID ' --ER0270 - KarthikR - 30/Oct/2010
SELECT @strsql = @strsql +' left OUTER Join PlantMachine P on Mch.machineid = P.machineid '
SELECT @StrSql=@StrSql + ' WHERE A.AlarmTime>='''+ CONVERT(NVarChar,@StartTime)+ ''' AND  A.AlarmTime<=''' + CONVERT(NVarChar,@EndTime) + ''' AND A.RecordType=6 or A.RecordType=85'
--SELECT @StrSql=@StrSql + ' WHERE A.AlarmTime>='''+ CONVERT(NVarChar,@StartTime)+ ''' AND  A.AlarmTime<=''' + CONVERT(NVarChar,@EndTime) + ''' '
DECLARE @StrMachine AS NvarChar(100)
DECLARE @StrAlCategory AS NvarChar(100)
DECLARE @StrAlNumber AS NvarChar(100)
SELECT @StrMachine=''
SELECT @StrAlCategory=''
SELECT @StrAlNumber=''
IF ISNULL(@MachineID,'')<>''
BEGIN
	---mod 1
--	SELECT @StrMachine=' And Mch.MachineID=''' + @MachineID + ''' '
	SELECT @StrMachine=' And Mch.MachineID= N''' + @MachineID + ''' '
	---mod 1
END
IF ISNULL(@AlarmCategory,'')<>''
BEGIN
	---mod 1
--	SELECT @StrAlCategory=' And M.AlarmCategory='''+ @AlarmCategory +''' '
	SELECT @StrAlCategory=' And M.AlarmCategory= N'''+ @AlarmCategory +''' '
	---mod 1
END
IF @AlarmNumber<>''
BEGIN
	---mod 1
--	SELECT @StrAlNumber=' And A.AlarmNumber=' + CONVERT(NVarChar,@AlarmNumber) + ' '
	--SELECT @StrAlNumber=' And A.AlarmNumber= N' + CONVERT(NVarChar,@AlarmNumber) + ' '--DR0238 - SwathiKS - 24/Jun/2010
	SELECT @StrAlNumber=' And A.AlarmNumber = N'''+ @AlarmNumber +''' '
	---mod 1
END
if isnull(@PlantID,'') <> ''
BEGIN
	---mod 1

--	SELECT @strPlantID = ' AND ( P.PlantID = ''' + @PlantID+ ''')'
	SELECT @strPlantID = ' AND ( P.PlantID = N''' + @PlantID+ ''')'
	---mod 1
END
SELECT @StrSql=@StrSql  + @StrMachine + @StrAlCategory + @StrAlNumber + @strPlantID
EXEC (@StrSql)
DECLARE @CurMchID AS NVarChar(50)
--DECLARE @CurAlNumber AS  DECIMAL(18,2)--DR0238 - SwathiKS - 24/Jun/2010
DECLARE @CurAlNumber AS  NVarChar(50)
DECLARE @CurAlDscr AS NVarChar(100)
DECLARE TmpCursor  CURSOR FOR SELECT MachineID,AlarmNumber From #TmpAlarmTable
OPEN TmpCursor
FETCH NEXT FROM TmpCursor Into @CurMchID,@CurAlNumber
WHILE @@FETCH_STATUS=0
BEGIN
	IF (SELECT COUNT(*) FROM MachineAlarmInformation Where MachineID=@CurMchID AND AlarmNumber=@CurAlNumber)<>0
	BEGIN
		UPDATE #TmpAlarmTable SET AlarmDescription = ISNULL(T1.Dscr,'No_Dscr') FROM
		(SELECT AlarmDescription  AS Dscr FROM MachineAlarmInformation Where MachineID=@CurMchID AND AlarmNumber=@CurAlNumber )AS T1
		WHERE #TmpAlarmTable.MachineID=@CurMchID AND #TmpAlarmTable.AlarmNumber=@CurAlNumber
		UPDATE #TmpAlarmTable SET AlarmCategory = ISNULL(T1.AlarmCategory,'No_Dscr') FROM
		(SELECT AlarmCategory   FROM MachineAlarmInformation Where MachineID=@CurMchID AND AlarmNumber=@CurAlNumber )AS T1
		WHERE #TmpAlarmTable.MachineID=@CurMchID AND #TmpAlarmTable.AlarmNumber=@CurAlNumber
	END
	ELSE
	BEGIN
		UPDATE #TmpAlarmTable SET AlarmDescription = ISNULL(T1.Dscr,'No_Dscr') FROM
		(SELECT AlarmDescription  AS Dscr FROM MachineAlarmInformation Where MachineID='' AND AlarmNumber=@CurAlNumber )AS T1
		WHERE #TmpAlarmTable.MachineID=@CurMchID AND #TmpAlarmTable.AlarmNumber=@CurAlNumber
		UPDATE #TmpAlarmTable SET AlarmCategory = ISNULL(T1.AlarmCategory,'No_Dscr') FROM
		(SELECT AlarmCategory   FROM MachineAlarmInformation Where MachineID='' AND AlarmNumber=@CurAlNumber )AS T1
		WHERE #TmpAlarmTable.MachineID=@CurMchID AND #TmpAlarmTable.AlarmNumber=@CurAlNumber
		
		
	END
FETCH NEXT FROM TmpCursor Into @CurMchID,@CurAlNumber
END
	---ER0270 - KarthikR - 30/Oct/2010 From Here
/*SELECT
	SerialNo  ,
	MachineID  ,
	AlarmCategory  ,
	AlarmNumber ,
	AlarmTime,
	AlarmDescription
	FROM #TmpAlarmTable */

If @Param = 'Report' 
	BEGIN
	SELECT MachineID ,AlarmCategory ,AlarmNumber ,AlarmTime,AlarmDescription FROM #TmpAlarmTable 
	order by Machineid,AlarmTime
END
else 
begin
	SELECT
		SerialNo  ,
		MachineID  ,
		AlarmCategory  ,
		AlarmNumber ,
		AlarmTime,
		AlarmDescription
		FROM #TmpAlarmTable
end

---ER0270 - KarthikR - 30/Oct/2010 Till Here
END
