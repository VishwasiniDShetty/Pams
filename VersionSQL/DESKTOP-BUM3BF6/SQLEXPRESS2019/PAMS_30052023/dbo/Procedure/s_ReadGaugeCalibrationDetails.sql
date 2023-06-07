/****** Object:  Procedure [dbo].[s_ReadGaugeCalibrationDetails]    Committed by VersionSQL https://www.versionsql.com ******/

/**********************************************************
ER0281 - SnehaK - 15/Apr/2011 ::New Excel Report To Show Details Of CalibrationDone.
				Flow - SmartManager-> AnalysisReportStandard-> Gauge Report->Format -> Calibration Summary.
				ReportName - SM_GaugeReports.xls
***********************************************************/
--s_ReadGaugeCalibrationDetails '02-jan-2011','30-mar-2011','111','226'
CREATE        procedure [dbo].[s_ReadGaugeCalibrationDetails]
	@StartTime as datetime,
	@EndTime as Datetime,
	@GaugeID as nvarchar(50)='',
	@GaugeSlNo as nvarchar(20)=''
as
begin
	
declare @strsql nvarchar(4000)
declare @strgaugeid nvarchar(255)
declare @strgaugesn nvarchar(255)
select @strsql=''
select @strgaugesn=''
select @strgaugeid=''

if isnull(@GaugeID,'') <> ''
begin
	SELECT @strgaugeid = ' AND (GaugeID = N''' +@GaugeID+ ''')'
end

if isnull(@GaugeSlNo,'') <> ''
begin
		SELECT @strgaugesn = ' AND ([serial number] = N''' +@GaugeSlNo+ ''')'
end

select @strsql='select gaugeid,[serial number],calibrationdoneon as  CalibrationDate,datediff(day,calibrationdoneon,calibrationdueon) as overdue from calibrationhistory T1'
select @strsql = @strsql + ' where gaugeid in (T1.gaugeid)and [serial number] in (T1.[serial number]) and '
select @strsql = @strsql + ' calibrationDoneOn >= '''+ convert(nvarchar(20),@StartTime)+'''  and calibrationDoneOn <= '''+convert(nvarchar(20),@EndTime)+''' '

select @strsql = @strsql + @strgaugeid+@strgaugesn



print @strsql
EXEC (@strsql)
end
