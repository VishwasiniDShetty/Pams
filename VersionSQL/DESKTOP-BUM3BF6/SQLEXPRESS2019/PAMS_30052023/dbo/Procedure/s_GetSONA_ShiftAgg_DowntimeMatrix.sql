/****** Object:  Procedure [dbo].[s_GetSONA_ShiftAgg_DowntimeMatrix]    Committed by VersionSQL https://www.versionsql.com ******/

/****************************************************************************
Created by Mrudula Rao on 05/dec/2006
Procedure created to get down time details from shift aggregated data
NR0048 - KarthikG - 16-Jun-2008 - In SmartManager/Breakdown report give one more report type "MachineDownTime Matrix - 2" in excel sheet to show the downtimes at machine and category level.
mod 1 :- ER0182 By Kusuma M.H on 18-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
Note:For ER0181 No component operation qualification found.
ER0335 - SwathiKS - 02/Nov/2012 :: To include New Matrixtype "DTimeforOEETrend".
--[s_GetSONA_ShiftAgg_DowntimeMatrix] '2019-07-08','2019-07-08','','','DTime_By_Catagory','','0'
--[s_GetSONA_ShiftAgg_DowntimeMatrix] '2019-07-08','2019-07-08','','','DTime','','0'
--[s_GetSONA_ShiftAgg_DowntimeMatrix] '2019-07-08','2019-07-08','','','DTimeforOEETrend','','0'
--[s_GetSONA_ShiftAgg_DowntimeMatrix] '2019-07-08','2019-07-08','','','DFreq','','0'
--[s_GetSONA_ShiftAgg_DowntimeMatrix] '2019-Mar-01','2019-Apr-03','','','DTime_By_Catagory','','0'
*******************************************************************************/
CREATE            procedure [dbo].[s_GetSONA_ShiftAgg_DowntimeMatrix]
	@StartTime DateTime,
	@EndTime DateTime,
	---mod 1
	---To support unicode characters replaced varchar with nvarchar.
--	@MachineID  varchar(50) = '',
--	@DownID  varchar(8000) = '',
--	@MatrixType varchar(20) = 'DTime',
--	@PlantID varchar(50) = '',
	@MachineID  nvarchar(MAX) = '',
	@DownID  nvarchar(max) = '',
	@MatrixType nvarchar(20) = 'DTime',
	@PlantID nvarchar(50) = '',
	---mod 1
	@Exclude int = 0,
	@Groupid as nvarchar(MAX)='' 
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
declare @strsql nvarchar(max)
declare @strdownID nvarchar(max)
declare @strMachine nvarchar(4000)
declare @strcomponent nvarchar(255)
declare @strOperator nvarchar(255)
Declare @StrPlantID nvarchar(255)
declare @StrPlant nvarchar(255) 
Declare @StrGroup as nvarchar(MAX)     
Declare @StrGroupid as nvarchar(MAX)  
declare @StrMCJoined as nvarchar(max)
declare @StrGroupJoined as nvarchar(max)

--DECLARE @joined NVARCHAR(max)
---mod 1
-- Temporary Table
CREATE TABLE #DownTimeData
(
	MachineID nvarchar(50) not null,
    machineDescription NVarChar(50), 
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
    machineDescription NVarChar(150), 
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
select @StrGroup = ''
SELECT @strmachine=''
SELECT @StrDownId=''
select @StrPlant=''
Select @StrGroupid=''  

if isnull(@MachineID,'')<>''
begin
	---mod 1
	--select @strmachine=' AND (machineinformation.machineid ='''+@MachineID+''')'
	select @StrMCJoined =  (case when (coalesce( +@StrMCJoined + ',''', '''')) = ''''  then 'N''' else @StrMCJoined+',N''' end) +item+'''' from [SplitStrings](@MachineID, ',')    
	if @StrMCJoined = 'N'''''  
	set @StrMCJoined = '' 
	select @MachineID = @StrMCJoined
END


if isnull(@GroupID,'')<> ''
Begin
	select @StrGroupJoined =  (case when (coalesce( +@StrGroupJoined + ',''', '''')) = ''''  then 'N''' else @StrGroupJoined+',N''' end) +item+'''' from [SplitStrings](@GroupID, ',')    
	if @StrGroupJoined = 'N'''''  
	set @StrGroupJoined = '' 
	select @GroupID = @StrGroupJoined

END
IF ISNULL(@PlantID,'')<>''
BEGIN
---mdo 1
--SELECT @StrPlant=' And PlantMachine.PlantID='''+ @PlantID +''''
SELECT @StrPlant=' And PlantMachine.PlantID=N'''+ @PlantID +''''
---mod 1
END

If isnull(@Groupid,'') <> ''  
Begin  
 Select @StrGroup = ' And ( PlantMachineGroups.GroupID IN (' + @GroupID + '))'  
End 


--select @joined = coalesce(@joined + ',''', '''')+item+'''' from [SplitStrings](@machineid, ',')     
--if @joined = ''''''  
-- set @joined = ''  

DECLARE @joined1 NVARCHAR(max)  
select @joined1 =  (case when (coalesce( +@joined1 + ',''', '''')) = ''''  then 'N''' else @joined1+',N''' end) +item+'''' from [SplitStrings](@DownID, ',')     
if @joined1 = 'N'''''  
set @joined1 = '' 
select @DownID = @joined1


	SELECT @strsql='INSERT INTO #DownTimeData(MachineID,machineDescription,DownID,DownTime,DownFreq)'
	SELECT @strsql= @strsql+ 'SELECT Machineinformation.MachineID AS MachineID,Machineinformation.Description ,downcodeinformation.downid AS DownID, 0,0 FROM Machineinformation 
	CROSS JOIN downcodeinformation INNER JOIN PlantMachine ON PlantMachine.MachineID=Machineinformation.MachineID 
	LEFT OUTER JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID ' ---SWathi Commented
	--SELECT @strsql= @strsql+ 'SELECT Machineinformation.MachineID AS MachineID, downcodeinformation.downid AS DownID, 0,0 FROM Machineinformation CROSS JOIN downcodeinformation INNER JOIN PlantMachine ON PlantMachine.MachineID=Machineinformation.MachineID '


if isnull(@downid, '') <> '' and isnull(@machineid,'') <> '' and @Exclude=0
	begin
	select @strsql =  @strsql + ' where  downcodeinformation.downid in (' + @downid + ')'
	---mod 1
--	select @strsql =  @strsql + ' and ( Machineinformation.machineid = ''' + @machineid + ''')'
	--select @strsql =  @strsql + ' and ( Machineinformation.machineid = N''' + @machineid + ''')'
	select @strsql =  @strsql + ' and ( Machineinformation.machineid in (' + @MachineID + '))'
	
	---mod 1
	end
--change
if isnull(@downid, '') <> '' and isnull(@machineid,'') <> '' and @Exclude=1
	begin
	select @strsql =  @strsql + ' where  downcodeinformation.downid not in (' + @downid + ')'
	---mod 1
--	select @strsql =  @strsql + ' and ( Machineinformation.machineid = ''' + @machineid + ''')'
	--select @strsql =  @strsql + ' and ( Machineinformation.machineid = N''' + @machineid + ''')'
	select @strsql =  @strsql + ' and ( Machineinformation.machineid in (' + @MachineID + '))'
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
	--select @strsql =  @strsql + ' where ( Machineinformation.machineid = N''' + @machineid + ''')'
	select @strsql =  @strsql + ' and ( Machineinformation.machineid in (' + @MachineID + '))'
	---mod 1
	end
--============To handle 16 downs ==========--
IF (Select ValueInInt from CockpitDefaults WHERE Parameter = 'ExcludeTPMTrakDown') = 1
BEGIN
   IF isnull(@downid, '') = '' and isnull(@machineid,'') = ''
    BEGIN
      select @strsql = @strsql + ' WHERE downcodeinformation.DownID not in (select DownId from PredefinedDownCodeInfo ) '
	END
    IF isnull(@downid, '') <> '' and isnull(@machineid,'') <> '' 
	BEGIN
	 select @strsql = @strsql + ' AND downcodeinformation.DownID not in (select DownId from PredefinedDownCodeInfo ) '
	END
END 

select @strsql = @strsql + @StrPlant + @StrGroup + ' ORDER BY  downcodeinformation.downid, Machineinformation.MachineID'
print @strsql
exec (@strsql)
--return
-------------------------------------------------------------------------
if isnull(@PlantID,'')<>''
begin
---mod 1
--select @StrPlantID=' AND (SD.PlantID ='''+@PlantID+''')'
select @StrPlantID=' AND (SD.PlantID =N'''+@PlantID+''')'
---mod 1
end
 
If isnull(@Groupid,'') <> ''  
Begin  
 Select @StrGroupid = ' And ( SD.GroupID IN (' + @GroupID + '))'  
End 
 
if isnull(@MachineID,'')<>''
begin
---mod 1
--select @strmachine=' AND (SD.machineid ='''+@MachineID+''')'
--select @strmachine=' AND (SD.machineid =N'''+@MachineID+''')'
select @strmachine=' AND (SD.machineid in (' + @MachineID + '))' --ER0453 
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

select @strsql= ' update #DownTimeData set DownTime=isnull(DownTime,0) + isnull(t2.down,0) , '
select @strsql = @strsql+' DownFreq = isNull(downfreq,0) + isNull(t2.dwnfrq,0) '
select @strsql = @strsql + ' FROM'
select @strsql = @strsql + ' (select SD.Machineid as Machineid,count(SD.machineid) as dwnfrq,(Sum(SD.DownTime))As down,SD.downid as downid'    
		Select @Strsql = @Strsql + ' From ShiftDownTimeDetails SD 
		where convert(nvarchar(10),SD.dDate,120) >= '''+convert(varchar(10),@starttime,120)+''' And convert(nvarchar(10),SD.dDate,120) <= '''+convert(varchar(10),@EndTime,120)+''' 
		and SD.DownTime > 0 '    
		Select @Strsql = @Strsql+ @StrPlantID + @strmachine + @StrDownId + @StrGroupid
		Select @Strsql = @Strsql + ' Group By SD.MachineId,SD.downid  )'
select @strsql = @strsql + ' as t2 inner join #DownTimeData on t2.machineid=#DownTimeData.MachineId and t2.downid=#DownTimeData.downid'
print @strsql
exec (@strsql)

-----type 1
--select @strsql= ' update #DownTimeData set DownTime=isnull(DownTime,0) + isnull(t2.down,0) , '
--select @strsql = @strsql+' DownFreq = isNull(downfreq,0) + isNull(t2.dwnfrq,0) '
--select @strsql = @strsql + ' FROM'
--select @strsql = @strsql + ' (select SD.Machineid as Machineid,count(SD.machineid) as dwnfrq,sum(SD.downtime) as down,SD.downid as downid '
--select @strsql = @strsql + ' from ShiftDownTimeDetails SD where SD.starttime>='''+convert(varchar(20),@starttime)+''' and '
--select @strsql = @strsql + ' SD.EndTime<=''' +convert(varchar(20),@EndTime)+ ''' '
--select @strsql = @strsql + @StrPlantID + @strmachine + @StrDownId + @StrGroupid
--select @strsql = @strsql + ' group by SD.MachineId,SD.downid )'
--select @strsql = @strsql + ' as t2 inner join #DownTimeData on t2.machineid=#DownTimeData.MachineId and t2.downid=#DownTimeData.downid'
--print @strsql
--exec (@strsql)
----TYPE2
--select @strsql = ''
--select @strsql = @strsql+'update #DownTimeData set DownTime=isnull(DownTime,0) + isnull(t2.down,0) , '
--select @strsql = @strsql+' DownFreq = isNull(downfreq,0) + isNull(t2.dwnfrq,0) '
--select @strsql = @strsql + ' FROM'
--select @strsql = @strsql + ' (select SD.Machineid as Machineid,count(SD.machineid) as dwnfrq,sum(DateDiff(second, '''+convert(varchar(20),@StartTime)+''', SD.EndTime)) as down,SD.downid as downid '
--select @strsql = @strsql + ' from ShiftDownTimeDetails SD where SD.starttime<'''+convert(varchar(20),@starttime)+''' and '
--select @strsql = @strsql + ' SD.EndTime>''' +convert(varchar(20),@starttime)+ ''' and SD.EndTime<='''+convert(varchar(20),@endtime)+''''
--select @strsql = @strsql + @StrPlantID + @strmachine + @StrDownId + @StrGroupid
--select @strsql = @strsql + ' group by SD.MachineId,SD.downid )'
--select @strsql = @strsql + ' as t2 inner join #DownTimeData on t2.machineid=#DownTimeData.MachineId and t2.downid=#DownTimeData.downid'
--print @strsql
--exec (@strsql)
----type 3
--select @strsql = ''
--select @strsql = @strsql+'update #DownTimeData set DownTime=isnull(DownTime,0) + isnull(t2.down,0) , '
--select @strsql = @strsql+' DownFreq = isNull(downfreq,0) + isNull(t2.dwnfrq,0) '
--select @strsql = @strsql + ' FROM'
--select @strsql = @strsql + ' (select SD.Machineid as Machineid,count(SD.machineid) as dwnfrq,sum(DateDiff(second,SD.StartTime,'''+convert(varchar(20),@EndTime)+''' )) as down,SD.downid as downid '
--select @strsql = @strsql + ' from ShiftDownTimeDetails SD where SD.starttime>='''+convert(varchar(20),@starttime)+''' and '
--select @strsql = @strsql + ' SD.startTime<'''+convert(varchar(20),@endtime)+''' and SD.EndTime>'''+convert(varchar(20),@endtime)+''' '
--select @strsql = @strsql + @StrPlantID + @strmachine + @StrDownId + @StrGroupid
--select @strsql = @strsql + ' group by SD.MachineId,SD.downid )'
--select @strsql = @strsql + ' as t2 inner join #DownTimeData on t2.machineid=#DownTimeData.MachineId and t2.downid=#DownTimeData.downid'
--print @strsql
--exec (@strsql)
-----type 4
--select @strsql = ''
--select @strsql = @strsql+'update #DownTimeData set DownTime=isnull(DownTime,0) + isnull(t2.down,0) , '
--select @strsql = @strsql+' DownFreq = isNull(downfreq,0) + isNull(t2.dwnfrq,0) '
--select @strsql = @strsql + ' FROM'
--select @strsql = @strsql + ' (select SD.Machineid as Machineid,count(SD.machineid) as dwnfrq,sum(DateDiff(second, '''+convert(varchar(20),@StartTime)+''', '''+convert(varchar(20),@EndTime)+'''))as down,SD.downid as Downid '
--select @strsql = @strsql + ' from ShiftDownTimeDetails SD where SD.StartTime<'''+convert(varchar(20),@starttime)+''' and SD.EndTime>'''+convert(varchar(20),@endtime)+''' '
--select @strsql = @strsql + @StrPlantID + @strmachine + @StrDownId + @StrGroupid
--select @strsql = @strsql + ' group by SD.MachineId,SD.downid )'
--select @strsql = @strsql + ' as t2 inner join #DownTimeData on t2.machineid=#DownTimeData.MachineId and t2.downid=#DownTimeData.downid'
--print @strsql
--exec (@strsql)
INSERT INTO #FinalData (MachineID,machineDescription, DownID, DownTime,downfreq, TotalMachine, TotalDown)
	select MachineID,machineDescription, DownID, DownTime, downfreq,0,0
	from #DownTimeData
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
			    #FinalData.machineDescription, 
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
				TotalDownFreq as TotalDownFreq,
				downcodeinformation.[Owner]
				FROM #FinalData
				INNER JOIN downcodeinformation on #FinalData.DownID = Downcodeinformation.downid
				inner join (
				 select MachineID  Machine, sum(downtime) as Sumdowntime from #FinalData  
				 group by MachineID having sum(downtime) > 0
			    )as F  on F.Machine = #FinalData.MachineID  
			    inner join (
				 select DownID Down, sum(downtime) as Sumdowntime from #FinalData  
				 group by DownID  having sum(downtime) > 0
			     )as F1  on  F1.Down = #FinalData.DownID
			 Order By  TotalDown desc,downcodeinformation.DownID, TotalMachine desc, machineid  
  
END

--ER0335 Added From Here
if @MatrixType = 'DTimeforOEETrend'
Begin

		select @strsql = ''
		select @strsql = @strsql+' select #FinalData.MachineID,
		#FinalData.machineDescription, 
			DownDescription as DownID,
			round((DownTime/3600),2) as DownTime
		FROM #FinalData
		INNER JOIN downcodeinformation on #FinalData.DownID = Downcodeinformation.downid
		--LEFT join Plantmachine on Plantmachine.machineid=#FinalData.MachineID
		--LEFT JOIN PlantMachineGroups ON PlantMachineGroups.PlantID = PlantMachine.PlantID and PlantMachineGroups.machineid = PlantMachine.MachineID
		where 1=1'
		--select @strsql = @strsql + @StrPlant + @StrGroup
		select @strsql = @strsql + 'order by #FinalData.MachineID'
		print @strsql
		exec (@strsql)

End
--ER0335 Added Till Here

If @MatrixType = 'DTime_By_Catagory'--NR0048
Begin

			--select 	Isnull(downcodeinformation.Catagory,'Uncategorized') as Catagory, 	
			--MachineID,
			--#FinalData.machineDescription, 
			--sum(DownTime) as DownTime
			--from #FinalData
			--INNER JOIN downcodeinformation on #FinalData.DownID = downcodeinformation.downid
			--WHERE (TotalDown > 0) and (TotalMachine > 0)
			--AND  #FinalData.DownID not in (select DownId from PredefinedDownCodeInfo) 
			--group by downcodeinformation.Catagory,MachineID,#FinalData.machineDescription --Having sum(DownTime) > 0
			--order by downcodeinformation.Catagory ,MachineID

			select 	Isnull(downcodeinformation.Catagory,'Uncategorized') as Catagory,
			MachineID,machineDescription,
			sum(DownTime) as DownTime
			from #FinalData
			INNER JOIN downcodeinformation on #FinalData.DownID = downcodeinformation.downid
			WHERE (TotalDown > 0) and (TotalMachine > 0) and DownTime > 0
			group by downcodeinformation.Catagory,MachineID,machineDescription Order By  downcodeinformation.Catagory,MachineID 


END

if @MatrixType='DLoss_By_Catagory'
begin

			select 	Isnull(downcodeinformation.Catagory,'Uncategorized') as Catagory, 	
			#FinalData.DownID,
			Round(sum(DownTime)/60,2) as DownTime,
			sum(DownTime) as DowntimeInSeconds,
			downcodeinformation.[Owner]
			from #FinalData
			INNER JOIN downcodeinformation on #FinalData.DownID = downcodeinformation.downid
			WHERE (TotalDown > 0) and (TotalMachine > 0)
			group by downcodeinformation.Catagory,#FinalData.DownID,downcodeinformation.[Owner]
			Order By  downcodeinformation.Catagory,#FinalData.DownID 
end

--NR0048
if @MatrixType = 'DFreq'
Begin
		
			select 	MachineID,
			#FinalData.machineDescription, 
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
				TotalDownFreq as TotalDownFreq,
				downcodeinformation.[Owner]
			FROM #FinalData
			INNER JOIN downcodeinformation on #FinalData.DownID = Downcodeinformation.downid
			WHERE (TotalDownFreq > 0) and (TotalMachineFreq > 0)
			Order By  TotalDownFreq desc,downcodeinformation.DownID, TotalMachineFreq desc, machineid

End
END
