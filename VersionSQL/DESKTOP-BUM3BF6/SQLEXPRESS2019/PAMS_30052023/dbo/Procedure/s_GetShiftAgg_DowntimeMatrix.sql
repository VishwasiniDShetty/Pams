/****** Object:  Procedure [dbo].[s_GetShiftAgg_DowntimeMatrix]    Committed by VersionSQL https://www.versionsql.com ******/

/****************************************************************************
Created by Mrudula Rao on 05/dec/2006
Procedure created to get down time details from shift aggregated data
NR0048 - KarthikG - 16-Jun-2008 - In SmartManager/Breakdown report give one more report type "MachineDownTime Matrix - 2" in excel sheet to show the downtimes at machine and category level.
mod 1 :- ER0182 By Kusuma M.H on 18-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
Note:For ER0181 No component operation qualification found.
ER0335 - SwathiKS - 02/Nov/2012 :: To include New Matrixtype "DTimeforOEETrend".
--[s_GetShiftAgg_DowntimeMatrix] '2011-Mar-01','2012-Apr-03','','','DTimeforOEETrend','','0'
*******************************************************************************/
CREATE            procedure [dbo].[s_GetShiftAgg_DowntimeMatrix]
	@StartTime DateTime,
	@EndTime DateTime,
	---mod 1
	---To support unicode characters replaced varchar with nvarchar.
--	@MachineID  varchar(50) = '',
--	@DownID  varchar(8000) = '',
--	@MatrixType varchar(20) = 'DTime',
--	@PlantID varchar(50) = '',
	@MachineID  nvarchar(50) = '',
	@DownID  nvarchar(4000) = '',
	@MatrixType nvarchar(20) = 'DTime',
	@PlantID nvarchar(50) = '',
	---mod 1
	@Exclude int = 0
AS
BEGIN
---mod 1
---To support unicode characters replaced varchar with nvarchar.
--declare @strsql varchar(8000)
--declare @strdownID varchar(8000)
--declare @strMachine varchar(255)
--declare @strcomponent varchar(255)
--declare @strOperator varchar(255)
--Declare @StrPlantID varchar(255)
--declare @StrPlant varchar(255)
declare @strsql nvarchar(4000)
declare @strdownID nvarchar(4000)
declare @strMachine nvarchar(255)
declare @strcomponent nvarchar(255)
declare @strOperator nvarchar(255)
Declare @StrPlantID nvarchar(255)
declare @StrPlant nvarchar(255)
---mod 1
-- Temporary Table
CREATE TABLE #DownTimeData
(
	MachineID nvarchar(50) not null,
	--McInterfaceid nvarchar(4),
	DownID nvarchar(50) not null,
	DownTime float,
	DownFreq int
	---CONSTRAINT downtimedata_key PRIMARY KEY (MachineId, DownID)
)
ALTER TABLE #DownTimeData ADD PRIMARY KEY CLUSTERED (MachineId, DownID) ON [DEFAULT]
CREATE TABLE #FinalData
(
	MachineID nvarchar(50) not null,
	DownID nvarchar(50) not null,
	DownTime float,
	downfreq int,
	TotalMachine float,
	TotalDown float,
	TotalMachineFreq float DEFAULT(0),
	TotalDownFreq float DEFAULT(0)
	--CONSTRAINT finaldata_key PRIMARY KEY (MachineID, DownID)
)
ALTER TABLE #FinalData ADD PRIMARY KEY CLUSTERED (MachineId, DownID) ON [DEFAULT]
select @strsql = ''
select @StrPlantID=''
SELECT @strmachine=''
SELECT @StrDownId=''
select @StrPlant=''
IF ISNULL(@PlantID,'')<>''
BEGIN
---mdo 1
--SELECT @StrPlant=' And PlantMachine.PlantID='''+ @PlantID +''''
SELECT @StrPlant=' And PlantMachine.PlantID=N'''+ @PlantID +''''
---mod 1
END
SELECT @strsql='INSERT INTO #DownTimeData(MachineID,DownID,DownTime,DownFreq)'
SELECT @strsql= @strsql+ 'SELECT Machineinformation.MachineID AS MachineID, downcodeinformation.downid AS DownID, 0,0 FROM Machineinformation CROSS JOIN downcodeinformation LEFT OUTER JOIN PlantMachine ON PlantMachine.MachineID=Machineinformation.MachineID ' ---SWathi Commented
--SELECT @strsql= @strsql+ 'SELECT Machineinformation.MachineID AS MachineID, downcodeinformation.downid AS DownID, 0,0 FROM Machineinformation CROSS JOIN downcodeinformation INNER JOIN PlantMachine ON PlantMachine.MachineID=Machineinformation.MachineID '
if isnull(@downid, '') <> '' and isnull(@machineid,'') <> '' and @Exclude=0
	begin
	select @strsql =  @strsql + ' where  downcodeinformation.downid in (' + @downid + ')'
	---mod 1
--	select @strsql =  @strsql + ' and ( Machineinformation.machineid = ''' + @machineid + ''')'
	select @strsql =  @strsql + ' and ( Machineinformation.machineid = N''' + @machineid + ''')'
	---mod 1
	end
--change
if isnull(@downid, '') <> '' and isnull(@machineid,'') <> '' and @Exclude=1
	begin
	select @strsql =  @strsql + ' where  downcodeinformation.downid not in (' + @downid + ')'
	---mod 1
--	select @strsql =  @strsql + ' and ( Machineinformation.machineid = ''' + @machineid + ''')'
	select @strsql =  @strsql + ' and ( Machineinformation.machineid = N''' + @machineid + ''')'
	---mod 1
	end
--change
if isnull(@downid, '') <> '' and isnull(@machineid,'') = '' and @Exclude=0
	begin
	select @strsql =  @strsql + ' where  downcodeinformation.downid in( ' + @downid + ' )'
	end
--change
if isnull(@downid, '') <> '' and isnull(@machineid,'') = '' and @Exclude=1
	begin
	select @strsql =  @strsql + ' where  downcodeinformation.downid not in( ' + @downid + ')'
	end
if isnull(@downid, '') = '' and isnull(@machineid,'') <> ''
	begin
	---mod 1
--	select @strsql =  @strsql + ' where ( Machineinformation.machineid = ''' + @machineid + ''')'
	select @strsql =  @strsql + ' where ( Machineinformation.machineid = N''' + @machineid + ''')'
	---mod 1
	end
select @strsql = @strsql + @StrPlant + ' ORDER BY  downcodeinformation.downid, Machineinformation.MachineID'
print @strsql
exec (@strsql)
--select * from #DownTimeData
--return
-------------------------------------------------------------------------
if isnull(@PlantID,'')<>''
begin
---mod 1
--select @StrPlantID=' AND (SD.PlantID ='''+@PlantID+''')'
select @StrPlantID=' AND (SD.PlantID =N'''+@PlantID+''')'
---mod 1
end
if isnull(@MachineID,'')<>''
begin
---mod 1
--select @strmachine=' AND (SD.machineid ='''+@MachineID+''')'
select @strmachine=' AND (SD.machineid =N'''+@MachineID+''')'
---mod 1
end
IF ISNULL(@DownID,'')<>'' and @Exclude=0
BEGIN
SELECT @StrDownId=' AND (SD.Downid in ('+@DownID+' ))'
END
IF ISNULL(@DownID,'')<>'' and @Exclude=1
BEGIN
SELECT @StrDownId=' AND (SD.Downid not in ('+@DownID+' ))'
END
select @strsql=''
---type 1
select @strsql= ' update #DownTimeData set DownTime=isnull(DownTime,0) + isnull(t2.down,0) , '
select @strsql = @strsql+' DownFreq = isNull(downfreq,0) + isNull(t2.dwnfrq,0) '
select @strsql = @strsql + ' FROM'
select @strsql = @strsql + ' (select SD.Machineid as Machineid,count(SD.machineid) as dwnfrq,sum(SD.downtime) as down,SD.downid as downid '
select @strsql = @strsql + ' from ShiftDownTimeDetails SD where SD.starttime>='''+convert(varchar(20),@starttime)+''' and '
select @strsql = @strsql + ' SD.EndTime<=''' +convert(varchar(20),@EndTime)+ ''' '
select @strsql = @strsql + @StrPlantID + @strmachine + @StrDownId
select @strsql = @strsql + ' group by SD.MachineId,SD.downid )'
select @strsql = @strsql + ' as t2 inner join #DownTimeData on t2.machineid=#DownTimeData.MachineId and t2.downid=#DownTimeData.downid'
exec (@strsql)
--TYPE2
select @strsql = ''
select @strsql = @strsql+'update #DownTimeData set DownTime=isnull(DownTime,0) + isnull(t2.down,0) , '
select @strsql = @strsql+' DownFreq = isNull(downfreq,0) + isNull(t2.dwnfrq,0) '
select @strsql = @strsql + ' FROM'
select @strsql = @strsql + ' (select SD.Machineid as Machineid,count(SD.machineid) as dwnfrq,sum(DateDiff(second, '''+convert(varchar(20),@StartTime)+''', SD.EndTime)) as down,SD.downid as downid '
select @strsql = @strsql + ' from ShiftDownTimeDetails SD where SD.starttime<'''+convert(varchar(20),@starttime)+''' and '
select @strsql = @strsql + ' SD.EndTime>''' +convert(varchar(20),@starttime)+ ''' and SD.EndTime<='''+convert(varchar(20),@endtime)+''''
select @strsql = @strsql + @StrPlantID + @strmachine + @StrDownId
select @strsql = @strsql + ' group by SD.MachineId,SD.downid )'
select @strsql = @strsql + ' as t2 inner join #DownTimeData on t2.machineid=#DownTimeData.MachineId and t2.downid=#DownTimeData.downid'
print @strsql
exec (@strsql)
--type 3
select @strsql = ''
select @strsql = @strsql+'update #DownTimeData set DownTime=isnull(DownTime,0) + isnull(t2.down,0) , '
select @strsql = @strsql+' DownFreq = isNull(downfreq,0) + isNull(t2.dwnfrq,0) '
select @strsql = @strsql + ' FROM'
select @strsql = @strsql + ' (select SD.Machineid as Machineid,count(SD.machineid) as dwnfrq,sum(DateDiff(second,SD.StartTime,'''+convert(varchar(20),@EndTime)+''' )) as down,SD.downid as downid '
select @strsql = @strsql + ' from ShiftDownTimeDetails SD where SD.starttime>='''+convert(varchar(20),@starttime)+''' and '
select @strsql = @strsql + ' SD.startTime<'''+convert(varchar(20),@endtime)+''' and SD.EndTime>'''+convert(varchar(20),@endtime)+''' '
select @strsql = @strsql + @StrPlantID + @strmachine + @StrDownId
select @strsql = @strsql + ' group by SD.MachineId,SD.downid )'
select @strsql = @strsql + ' as t2 inner join #DownTimeData on t2.machineid=#DownTimeData.MachineId and t2.downid=#DownTimeData.downid'
print @strsql
exec (@strsql)
---type 4
select @strsql = ''
select @strsql = @strsql+'update #DownTimeData set DownTime=isnull(DownTime,0) + isnull(t2.down,0) , '
select @strsql = @strsql+' DownFreq = isNull(downfreq,0) + isNull(t2.dwnfrq,0) '
select @strsql = @strsql + ' FROM'
select @strsql = @strsql + ' (select SD.Machineid as Machineid,count(SD.machineid) as dwnfrq,sum(DateDiff(second, '''+convert(varchar(20),@StartTime)+''', '''+convert(varchar(20),@EndTime)+'''))as down,SD.downid as Downid '
select @strsql = @strsql + ' from ShiftDownTimeDetails SD where SD.StartTime<'''+convert(varchar(20),@starttime)+''' and SD.EndTime>'''+convert(varchar(20),@endtime)+''' '
select @strsql = @strsql + @StrPlantID + @strmachine + @StrDownId
select @strsql = @strsql + ' group by SD.MachineId,SD.downid )'
select @strsql = @strsql + ' as t2 inner join #DownTimeData on t2.machineid=#DownTimeData.MachineId and t2.downid=#DownTimeData.downid'
print @strsql
exec (@strsql)
INSERT INTO #FinalData (MachineID, DownID, DownTime,downfreq, TotalMachine, TotalDown)
	select MachineID, DownID, DownTime, downfreq,0,0
	from #DownTimeData
--select * from #FinalData order by DownId,machineid
--return
UPDATE #FinalData
SET
TotalMachineFreq = (SELECT SUM(Downfreq) FROM #FinalData as FD WHERE Fd.machineID = #FinalData.machineid),
TotalDownFreq = (SELECT SUM(Downfreq) FROM #FinalData as FD WHERE Fd.DownID = #FinalData.DownID),
TotalMachine = (SELECT SUM(DownTime) FROM #FinalData as FD WHERE Fd.machineID = #FinalData.machineid),
TotalDown = (SELECT SUM(DownTime) FROM #FinalData as FD WHERE Fd.DownID = #FinalData.DownID)
---output
if @MatrixType = 'DTime'
Begin
	select 	MachineID,
	#FinalData.DownID as DownCode,
	downcodeinformation.DownDescription as DownID,
	DownTime as DownTime,
	DownFreq as DownFreq,
	TotalMachine as TotalMachine,
	TotalDown as TotalDown,
	DownTime/3600 as Hours,
	@StartTime as StartTime,
	@EndTime as EndTime,
	TotalMachineFreq as TotalMachineFreq,
	TotalDownFreq as TotalDownFreq
	FROM #FinalData
	INNER JOIN downcodeinformation on #FinalData.DownID = Downcodeinformation.downid
	WHERE (TotalDown > 0) and (TotalMachine > 0)
	Order By  TotalDown desc,DownID, TotalMachine desc, machineid
END

--ER0335 Added From Here
if @MatrixType = 'DTimeforOEETrend'
Begin
	select @strsql = ''
	select @strsql = @strsql+'select #FinalData.MachineID,
		DownDescription as DownID,
		round((DownTime/3600),2) as DownTime
	FROM #FinalData
	INNER JOIN downcodeinformation on #FinalData.DownID = Downcodeinformation.downid
	inner join Plantmachine on Plantmachine.machineid=#FinalData.MachineID
	where 1=1 '
	select @strsql = @strsql + @StrPlant
	select @strsql = @strsql + 'order by #FinalData.MachineID'
	print @strsql
	exec (@strsql)
End
--ER0335 Added Till Here

If @MatrixType = 'DTime_By_Catagory'--NR0048
Begin
select 	Isnull(downcodeinformation.Catagory,'Uncategorized') as Catagory, 	
	MachineID,
	sum(DownTime) as DownTime
	from #FinalData
	INNER JOIN downcodeinformation on #FinalData.DownID = downcodeinformation.downid
	WHERE (TotalDown > 0) and (TotalMachine > 0)
	group by downcodeinformation.Catagory,MachineID --Having sum(DownTime) > 0
	order by downcodeinformation.Catagory ,MachineID
--s_GetShiftAgg_DowntimeMatrix '2007-12-01 00:00:00' , '2007-12-10 08:00:00' ,'','','DTime_By_Catagory' ,'','0'
END
--NR0048
if @MatrixType = 'DFreq'
Begin
	select 	MachineID,
		#FinalData.DownID as DownCode,
		DownDescription as DownID,
		--DownTime as DownTime,
		DownFreq as DownFreq,
		--TotalMachine as TotalMachine,
		--TotalDown as TotalDown,
		--DownTime/3600 as Hours,
		--@MachineIDLabel as MachineIDLabel ,
		--@OperatorIDLabel  as OperatorIDLabel,
		--@DownIDLabel  as DownIDLabel ,


		--@ComponentIDLabel as ComponentIDLabel,
		--@StartTime as StartTime,
		--@EndTime as EndTime,
		TotalMachineFreq as TotalMachineFreq,
		TotalDownFreq as TotalDownFreq
	FROM #FinalData
	INNER JOIN downcodeinformation on #FinalData.DownID = Downcodeinformation.downid
	WHERE (TotalDownFreq > 0) and (TotalMachineFreq > 0)
	Order By  TotalDownFreq desc,downcodeinformation.DownID, TotalMachineFreq desc, machineid
End
END
