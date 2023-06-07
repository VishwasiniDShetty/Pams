/****** Object:  Procedure [dbo].[s_ReadGaugeSummary]    Committed by VersionSQL https://www.versionsql.com ******/

/**********************************************************
ER0281 - SnehaK - 15/Apr/2011 ::New Excel Report To Show Summary Of Calibration Done.
				Flow - SmartManager-> AnalysisReportStandard-> Gauge Report->Format -> Calibration Summary.
				ReportName - SM_GaugeReports.xls
***********************************************************/

CREATE       procedure [dbo].[s_ReadGaugeSummary]
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
	SELECT @strgaugeid = ' AND (t2.GaugeID = N''' +@GaugeID+ ''')'
end

if isnull(@GaugeSlNo,'') <> ''
begin
	SELECT @strgaugesn = ' AND (t2.[serial number] = N''' +@GaugeSlNo+ ''')'
end

select @strsql='select t2.gaugeid,t2.[serial number],max([calibration number]) as ''No.of times calibrated'',sum(t1.cnt) as ''No.of times Over due'' from calibrationhistory t2 
				left outer join
				(select 1 as cnt,gaugeid,[serial number] from calibrationhistory t2
				where  calibrationDoneOn<calibrationdueon and'
select @strsql = @strsql + ' calibrationDoneOn >= '''+ convert(nvarchar(20),@StartTime)+'''  and calibrationDoneOn <= '''+convert(nvarchar(20),@EndTime)+''' '

select @strsql = @strsql + @strgaugeid+@strgaugesn
select @strsql = @strsql +')t1 on t1.gaugeid=t2.gaugeid and t1.[serial number]=t2.[serial number] where 1=1  and '
select @strsql = @strsql + ' calibrationDoneOn >= '''+ convert(nvarchar(20),@StartTime)+'''  and calibrationDoneOn <= '''+convert(nvarchar(20),@EndTime)+''' '
select @strsql = @strsql + @strgaugeid+@strgaugesn
select @strsql = @strsql +'group by t2.gaugeid,t2.[serial number] '


print @strsql
EXEC (@strsql)
end
