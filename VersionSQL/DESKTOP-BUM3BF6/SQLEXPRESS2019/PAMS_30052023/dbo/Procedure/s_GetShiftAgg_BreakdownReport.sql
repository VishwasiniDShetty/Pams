/****** Object:  Procedure [dbo].[s_GetShiftAgg_BreakdownReport]    Committed by VersionSQL https://www.versionsql.com ******/

/*******************************************************************************************************
--Created by Mrudula Rao 02/dec/2006
--Procedure to get breakdown report from shift aggregated data
mod 1 :- ER0182 By Kusuma M.H on 18-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
Note:For ER0181 No component operation qualification found.
mod 2 :- DR0185 By Kusuma M.H on 25-May-2009. Increased the length of column downdescription from 50 to 100.
ER0317 - SwathiKS - 19/Dec/2011 :: To Calculate Setup Efficiency based on downid 'SETUP' or 'SETTING'.
 [dbo].[s_GetShiftAgg_BreakdownReport] '2020-12-01 08:30:00','2020-12-03 08:30:00','','','','0'
 [dbo].[s_GetShiftAgg_BreakdownReport] '2020-12-01 08:30:00','2020-12-03 08:30:00','','','','0','NipponDownReport'
 exec [dbo].[s_GetShiftAgg_BreakdownReport] @StartTime='2021-06-22 00:00:00',@EndTime=N'2021-06-30 00:00:00',@MachineID=N'',@Parameter=N'DownReport',@Exclude=N'0'
 exec [dbo].[s_GetShiftAgg_BreakdownReport] @StartTime='2021-06-24 00:00:00',@MachineID=N'',@EndTime=N'2021-06-30 00:00:00',@DownID=N'''SHIFT START'' ',@PlantID=N'',@Exclude=N'0',@Parameter=N'ConfidentalDownReport'
 exec [dbo].[s_GetShiftAgg_BreakdownReport] @StartTime='2021-07-01 00:00:00',@MachineID=N'',@EndTime=N'2021-07-03 00:00:00',@DownID=N'',@PlantID=N'',@Exclude=N'0',@Parameter=N'sum',@OperatorID=N''
  exec [dbo].[s_GetShiftAgg_BreakdownReport] @StartTime='2021-07-01 00:00:00',@MachineID=N'',@EndTime=N'2021-07-03 00:00:00',@DownID=N'',@PlantID=N'',@Exclude=N'0',@Parameter=N'dOWNrEPORT',@OperatorID=N''


********************************************************************************************************/
CREATE    procedure [dbo].[s_GetShiftAgg_BreakdownReport]
	@StartTime datetime,
	@EndTime datetime,
	@MachineID nvarchar(max)= '',
	@GroupID NVARCHAR(MAX)='',
	@DownID varchar(8000)='',
	@PlantID Nvarchar(50)='',
	@OperatorID NVARCHAR(50)='',
	@Exclude int,
	@Parameter nvarchar(50)=''
AS
BEGIN
---mod 1
---To support unicode characters replaced varchar with nvarchar.
--DECLARE @strsql varchar(8000)
DECLARE @strsql nvarchar(MAX)
--mod 1
DECLARE @strmachine nvarchar(MAX)
DECLARE @StrOperator nvarchar(200)
DECLARE @StrDownId NVARCHAR(MAX)
DECLARE @StrPlantID NVARCHAR(200)
DECLARE @timeformat NVARCHAR(12)
DECLARE @strGroupID NVARCHAR(MAX)
declare @StrMCJoined as nvarchar(max)
declare @StrGroupJoined as nvarchar(max)
DECLARE @StrDownJoined as nvarchar(max)

create table #TempBreakDownDataAgg
(
StartTime datetime,
EndTime datetime,
machineid nvarchar(50),
MachineDescription NVARCHAR(50),
componentid nvarchar(50),
OperationNo integer,
OperatorName nvarchar(50),
downid nvarchar(50),
---mod 2
--DownDescription nvarchar(50),
DownDescription nvarchar(100),
---mod 2
downtime float,
LapsedTime float,
PDT Float,
MgmtLoss float default 0,
McDowntime float default 0,
ActualDown float default 0,
id bigint primary key,
StdSetup float,
SetupEff float
)
SELECT  @strsql=''
SELECT @strmachine=''
SELECT @StrDownId=''
select @StrOperator=''
SELECT @StrPlantID=''
SELECT @strGroupID=''

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

	select @StrMCJoined =  (case when (coalesce( +@StrMCJoined + ',''', '''')) = ''''  then 'N''' else @StrMCJoined+',N''' end) +item+'''' from [SplitStrings](@MachineID, ',')    
	if @StrMCJoined = 'N'''''  
	set @StrMCJoined = '' 
	select @MachineID = @StrMCJoined

select @strmachine=' AND (SD.machineid IN ('+@MachineID+'))'
---mod 1
end

if isnull(@GroupID,'')<> ''
Begin
	select @StrGroupJoined =  (case when (coalesce( +@StrGroupJoined + ',''', '''')) = ''''  then 'N''' else @StrGroupJoined+',N''' end) +item+'''' from [SplitStrings](@GroupID, ',')    
	if @StrGroupJoined = 'N'''''  
	set @StrGroupJoined = '' 
	select @GroupID = @StrGroupJoined

	SET @strGroupID = ' AND SD.GroupID in (' + @GroupID +')'
End

if isnull(@downid,'')<>''
begin
	select @StrDownJoined =  (case when (coalesce( +@StrDownJoined + ',''', '''')) = ''''  then 'N''' else @StrDownJoined+',N''' end) +item+'''' from [SplitStrings](@DownID, ',')    
	if @StrDownJoined = 'N'''''  
	set @StrDownJoined = '' 
	select @DownID = @StrDownJoined
end


if isnull(@OperatorID,'')<>''
begin
---mod 1
--select @strmachine=' AND (SD.machineid ='''+@MachineID+''')'
select @StrOperator=' AND (SD.OperatorID =N'''+@OperatorID+''')'
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
Select @timeformat ='ss'
Select @timeformat = isnull((Select valueintext from cockpitdefaults where parameter='timeformat'),'ss')
if (@timeformat <>'hh:mm:ss' and @timeformat <>'hh' and @timeformat <>'mm'and @timeformat <>'ss')
Begin
Select @timeformat = 'ss'
End
Select @strsql = 'insert into #TempBreakDownDataAgg(StartTime,EndTime,MachineID,MachineDescription,ComponentID,OperationNo,'
select @strsql = @strsql+'OperatorName,DownID,DownDescription,DownTime,McDowntime,PDT,StdSetup,SetupEff,ID) '
select @strsql = @strsql+ ' select SD.StartTime,SD.EndTime,SD.MachineID,M.description,SD.ComponentID,SD.OperationNo,'
select @strsql = @strsql+ 'SD.OperatorID,SD.DownID,downcodeinformation.downdescription,SD.DownTime,0,isnull(SD.PDT,0),SD.StdSetupTime,0,SD.ID '
select @strsql = @strsql+' From ShiftDownTimeDetails SD INNER JOIN downcodeinformation ON SD.DownID=downcodeinformation.DownID inner join machineinformation M on sd.machineid=M.machineid
where ddate>=''' + convert(nvarchar(20),@StartTime)+ ''' '
select @strsql = @strsql+' and ddate<=''' +convert(nvarchar(20),@EndTime)+ ''' '
select @strsql = @strsql+ @StrPlantID+ @strmachine+ @strGroupID+ @StrDownId+ @StrOperator
select @strsql = @strsql+' order by SD.EndTime'
print @strsql
exec (@strsql)


												
--total Downtime by machine
update #TempBreakDownDataAgg set McDowntime=isnull(McDowntime,0)+ isnull(t2.down,0)
	from (select machineid,sum(downtime) as down from #TempBreakDownDataAgg group by machineid) as t2 inner join
	#TempBreakDownDataAgg on t2.machineid=#TempBreakDownDataAgg.machineid

--Query to calculate Seup Efficiency
--Update #TempBreakDownDataAgg set SetupEff=isnull((StdSetup/isnull(downtime,0)),0)*100  where Downid='SETUP' and downtime<>0 --ER0317 commented
Update #TempBreakDownDataAgg set SetupEff=isnull((StdSetup/isnull(downtime,0)),0)*100  where (Downid='SETUP' OR Downid='SETTING') and downtime<>0 --ER0317 Added

------------------------------------------------------------------------------------ Lapsed Time,Mgmtloss,ActualDown Calculation starts------------------------------------------------------------------------------------------------------------
update #TempBreakDownDataAgg set LapsedTime=isnull( DATEDIFF(s,StartTime,EndTime),0)

UPDATE #TempBreakDownDataAgg SET MgmtLoss = Isnull(#TempBreakDownDataAgg.MgmtLoss,0)+IsNull(T1.LOSS,0)
			From (select StartTime,MachineID,componentid,operationno,operatorid,
			sum(
				 CASE
				WHEN (ShiftDownTimeDetails.DownTime) > isnull(ShiftDownTimeDetails.Threshold,0) and isnull(ShiftDownTimeDetails.Threshold,0) > 0
				THEN isnull(ShiftDownTimeDetails.Threshold,0)
				ELSE ShiftDownTimeDetails.DownTime
				 END) AS LOSS
				From ShiftDownTimeDetails
				Where dDate>=@StartTime and dDate<=@EndTime and ShiftDownTimeDetails.Ml_Flag=1
				Group By StartTime,MachineID,componentid,OperationNo,OperatorID
			) as T1 Inner Join #TempBreakDownDataAgg ON #TempBreakDownDataAgg.StartTime=T1.StartTime and  #TempBreakDownDataAgg.MachineID=T1.MachineID
			and #TempBreakDownDataAgg.componentid=t1.ComponentID and #TempBreakDownDataAgg.OperationNo=t1.OperationNo and #TempBreakDownDataAgg.OperatorName=t1.OperatorID


update #TempBreakDownDataAgg set ActualDown=LapsedTime-(MgmtLoss+PDT) where LapsedTime>0

------------------------------------------------------------------------------------ Lapsed Time,Mgmtloss,ActualDown Calculation Ends------------------------------------------------------------------------------------------------------------

---output



IF (@Parameter='' or isnull(@Parameter,'')='')
BEGIN
	select @strsql=''
	select @strsql='select DISTINCT StartTime,EndTime,MachineID,ComponentID,OperationNo,OperatorName,DownID,DownDescription, '
	if (@TimeFormat = 'hh:mm:ss'or @TimeFormat = 'hh' or @TimeFormat = 'mm' or @TimeFormat = 'ss' )
	begin	
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(DownTime,''' + @TimeFormat + ''') as DownTime , '
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(McDownTime,''' + @TimeFormat + ''') as McDownTime , '
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(StdSetup,''' + @TimeFormat + ''') as StdSetup , '
	end
	SELECT @strsql =  @strsql  + 'SetupEff From #TempBreakDownDataAgg order by MachineID,EndTime'
	exec (@strsql)
END

--IF @Parameter='DownReport'
--BEGIN
--	select @strsql=''
--	select @strsql='select Convert(nvarchar(10),StartTime,120) as Date,StartTime,EndTime,ComponentID,OperationNo,OperatorName,DownID,DownDescription, '
--	if (@TimeFormat = 'hh:mm:ss'or @TimeFormat = 'hh' or @TimeFormat = 'mm' or @TimeFormat = 'ss' )
--	begin	
--		SELECT @strsql =  @strsql  +'dbo.f_FormatTime(DownTime,''' + @TimeFormat + ''') as DownTime  '
--	end
--	SELECT @strsql =  @strsql  + ' From #TempBreakDownDataAgg order by EndTime'
--	exec (@strsql)
--END

IF @Parameter='DownReport' 
BEGIN
	select @strsql=''
	select @strsql='select StartTime,EndTime,MachineID,MachineDescription,ComponentID,OperationNo,OperatorName,DownID,DownDescription, '
	if (@TimeFormat = 'hh:mm:ss'or @TimeFormat = 'hh' or @TimeFormat = 'mm' or @TimeFormat = 'ss' )
	begin	
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(DownTime,''' + @TimeFormat + ''') as DownTime , '
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(LapsedTime,''' + @TimeFormat + ''') as LapsedTime , '
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(MgmtLoss,''' + @TimeFormat + ''') as DowThreshold , '
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(PDT,''' + 'SS' + ''') as PDT , '
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(ActualDown,''' + @TimeFormat + ''') as ActualDown , '
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(McDownTime,''' + @TimeFormat + ''') as McDownTime , '
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(StdSetup,''' + @TimeFormat + ''') as StdSetup , '
	end
	SELECT @strsql =  @strsql  + 'SetupEff From #TempBreakDownDataAgg order by EndTime'
	exec (@strsql)
END

IF (@Parameter='AggBreakDownReport')
BEGIN
	select @strsql=''
	select @strsql='select DISTINCT StartTime,EndTime,MachineID,MachineDescription,ComponentID,OperationNo,OperatorName as OperatorID,E.name as OperatorName,DownID,DownDescription, '
	if (@TimeFormat = 'hh:mm:ss'or @TimeFormat = 'hh' or @TimeFormat = 'mm' or @TimeFormat = 'ss' )
	begin	
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(DownTime,''' + @TimeFormat + ''') as DownTime , '
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(PDT,''' + @TimeFormat + ''') as PDT , '
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(McDownTime,''' + @TimeFormat + ''') as McDownTime , '
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(StdSetup,''' + @TimeFormat + ''') as StdSetup , '
	end
	SELECT @strsql =  @strsql  + 'SetupEff From #TempBreakDownDataAgg left join employeeinformation E ON e.employeeid=#TempBreakDownDataAgg.operatorname order by MachineID,EndTime'
	PRINT(@STRSQL)
	exec (@strsql)
END


IF @Parameter='Sum' 
begin
select @strsql=''
SELECT @STRSQL='SELECT dbo.f_FormatTime(sum(CAST(T.LapsedTime AS FLOAT)),'''+@timeformat+''') as LapsedSum,dbo.f_FormatTime(sum(CAST(T.ActualDown AS FLOAT)),'''+@timeformat+''') as DownSum '
SELECT @strsql=@strsql+ 'from( '
	select @strsql=@strsql+ 'select StartTime,EndTime,MachineID,MachineDescription,ComponentID,OperationNo,OperatorName,DownID,DownDescription, '
	if (@TimeFormat = 'hh:mm:ss'or @TimeFormat = 'hh' or @TimeFormat = 'mm' or @TimeFormat = 'ss' )
	begin	
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(DownTime,''' + 'ss' + ''') as DownTime , '
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(LapsedTime,''' + 'SS' + ''') as LapsedTime , '
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(MgmtLoss,''' + 'ss' + ''') as DowThreshold , '
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(PDT,''' + 'SS' + ''') as PDT , '
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(ActualDown,''' + 'SS' + ''') as ActualDown , '
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(McDownTime,''' + 'ss' + ''') as McDownTime , '
	SELECT @strsql =  @strsql  +'dbo.f_FormatTime(StdSetup,''' + 'ss' + ''') as StdSetup , '
	SELECT @strsql =  @strsql  + 'SetupEff From #TempBreakDownDataAgg '
	SELECT @strsql =  @strsql  + ')T '


	end
	print (@strsql)

	exec (@strsql)
end


END
