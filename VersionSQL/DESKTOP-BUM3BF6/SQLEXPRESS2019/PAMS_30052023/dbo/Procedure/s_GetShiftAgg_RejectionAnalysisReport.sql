/****** Object:  Procedure [dbo].[s_GetShiftAgg_RejectionAnalysisReport]    Committed by VersionSQL https://www.versionsql.com ******/

/*****************************************************************************************
prodedure created by Mrudula on 20-Dec-2006
	to get Rejection  information for both machine and componentwise
Altered by Mrudula to include category on 12/jan/2007
mod 1 :- ER0182 By Kusuma M.H on 28-May-2009. Modify all the procedures to support unicode characters. Qualify with leading N.
Note:For ER0181 No component operation qualification found.
DR0292 - Karthikr - 23/Aug/2011 :: To Avoid Duplicate CO's In the Excel Report.
--s_GetShiftAgg_RejectionAnalysisReport '201-07-12','2011-07-13','','','','','','1','Componentwise',''
--s_GetShiftAgg_RejectionAnalysisReport '2019-12-04','2019-12-06','','','','','','1','Machinewise',''
exec [dbo].[s_GetShiftAgg_ProductionReport] @StartDate=N'2022-08-12 00:00:00',@EndDate=N'2022-08-12 00:00:00',@PlantID=N'',@OperatorID=N'pct',@ReportType=N'OperatorWise',@Parameter=N'ProdReport'

*****************************************************************************************/
CREATE   procedure [dbo].[s_GetShiftAgg_RejectionAnalysisReport]
	@StartTime datetime,
	@EndTime datetime,
	@MachineID nvarchar(max)= '',
	@GroupID As nvarchar(max) = '',
	---mod 1
	---Replaced varchar with nvarchar to support unicode characters.
--	@RejectionID varchar(8000)='',
--	@COmponentID varchar(50)='',
--	@OperationNo varchar(50)='',
	@RejectionID nvarchar(4000)='',
	@COmponentID nvarchar(50)='',
	@OperationNo nvarchar(50)='',
	---mod 1
	@PlantID Nvarchar(50)='',
	@Exclude int,
	@Reptype nvarchar(50),
	@RejCategory nvarchar(50)=''
AS
begin
---mod 1
---Replaced varchar with nvarchar to support unicode characters.
--DECLARE @strsql varchar(8000)
DECLARE @strsql nvarchar(4000)
---mod 1
DECLARE @strmachine nvarchar(max)
DECLARE @StrRejId NVARCHAR(200)
DECLARE @StrPlantID NVARCHAR(200)
declare @StrPlant nvarchar(200)
declare @StrCompID nvarchar(200)
declare @StrOpnno nvarchar(200)
declare @strcategory nvarchar(200)
declare @strsqlmid nvarchar(max)
Declare @StrGroupID AS NVarchar(max)

declare @StrMCJoined as nvarchar(max)
declare @StrGroupJoined as nvarchar(max)

Select @StrGroupID=''
Select @strmachine=''

Declare @StrTPMMachines AS nvarchar(500) 
SELECT @StrTPMMachines=''

IF ( SELECT TOP 1 ValueInText FROM  CockpitDefaults WHERE Parameter='TpmEnbMac')='E'  
BEGIN  
 SET  @StrTPMMachines = ' AND MachineInformation.TPMTrakEnabled = 1 '  
END  
ELSE  
BEGIN  
 SET  @StrTPMMachines = ' '  
END 

if isnull(@machineid,'') <> ''
begin
	select @StrMCJoined =  (case when (coalesce( +@StrMCJoined + ',''', '''')) = ''''  then 'N''' else @StrMCJoined+',N''' end) +item+'''' from [SplitStrings](@MachineID, ',')    
	if @StrMCJoined = 'N'''''  
	set @StrMCJoined = '' 
	select @MachineID = @StrMCJoined
end

If isnull(@GroupID ,'') <> ''
Begin
	select @StrGroupJoined =  (case when (coalesce( +@StrGroupJoined + ',''', '''')) = ''''  then 'N''' else @StrGroupJoined+',N''' end) +item+'''' from [SplitStrings](@GroupID, ',')    
	if @StrGroupJoined = 'N'''''  
	set @StrGroupJoined = '' 
	select @GroupID = @StrGroupJoined

	Select @StrGroupID = ' And ( PlantMachineGroups.GroupID IN (' + @GroupID + ')) '
End


create table #TempMchRejdata
(
	Machineid nvarchar(50),
	RejnID nvarchar(50),
	RejQty integer
)
create table #TempCOData
(
	ComponentID nvarchar(50),
	OperationNo integer,
	RjctID nvarchar(50),
	QtyR integer
)
create table #TempRejectionDataMc
(
	StartTime datetime,
	EndTime datetime,
	Machineid nvarchar(50) ,
	RejectID nvarchar(50) ,
	RejQty integer,
	RRejQty integer,
	McRejQty integer,
	RMRejQty integer,
	TotalRej integer
)
Create table #TempRejectionDataCO
(
	StTime datetime,
	NdTime datetime,
	Componentid nvarchar(50) ,
	OperationNo integer ,
	RjctionID varchar(50),
	RQty integer,
	RejRQty integer,
	CORejQty integer,
	SCoRejqty integer,
	TOtRej integer
)
select @StrPlant=''
IF ISNULL(@PlantID,'')<>''
BEGIN
---mod 1
--SELECT @StrPlant=' And PlantMachine.PlantID='''+ @PlantID +''''
SELECT @StrPlant=' And PlantMachine.PlantID= N'''+ @PlantID +''''
---mod 1
END

select @strsql=''
select @strsqlmid=''
if @RepType='Machinewise'
begin
select @strsql='insert into #TempMchRejdata(MachineID,RejnID,RejQty) select machineInformation.MachineID, '
select @strsql=@strsql+'rejectioncodeinformation.rejectionID,0 from MachineInformation cross join rejectioncodeinformation '
select @strsql=@strsql+' Left outer join PlantMachine ON PlantMachine.MachineID=Machineinformation.MachineID '
select @strsql=@strsql+ ' LEFT JOIN PlantMachineGroups on MachineInformation.machineid = PlantMachineGroups.machineid '

if isnull(@RejectionID, '') <> '' and isnull(@machineid,'') <> '' and @RejCategory<> '' and  @Exclude=0
	begin
	select @strsqlmid =  @strsqlmid + '  where rejectioncodeinformation.rejectionID in (' + @RejectionID + ')'
	---mod 1
--	select @strsqlmid =  @strsqlmid + ' and ( Machineinformation.machineid = ''' + @machineid + ''')'
--	select @strsqlmid=@strsqlmid+ 'and (rejectioncodeinformation.Catagory='''+@RejCategory+''')'
	--select @strsqlmid =  @strsqlmid + ' and ( Machineinformation.machineid = N''' + @machineid + ''')'
	select @strsqlmid =  @strsqlmid + ' and ( Machineinformation.machineid  in (' + @MachineID +') ) '
	select @strsqlmid=@strsqlmid+ 'and (rejectioncodeinformation.Catagory= N'''+@RejCategory+''')'
	---mod 1
	end
if isnull(@RejectionID, '') <> '' and isnull(@machineid,'') <> '' and @RejCategory='' and  @Exclude=0
	begin
	select @strsqlmid =  @strsqlmid + '  where rejectioncodeinformation.rejectionID in (' + @RejectionID + ')'
	---mod 1
--	select @strsqlmid =  @strsqlmid + ' and ( Machineinformation.machineid = ''' + @machineid + ''')'
	--select @strsqlmid =  @strsqlmid + ' and ( Machineinformation.machineid = N''' + @machineid + ''')'
	select @strsqlmid =  @strsqlmid + ' and ( Machineinformation.machineid in (' + @MachineID +') ) '
	---mod 1
	end
if isnull(@RejectionID, '') <> '' and isnull(@machineid,'') <> '' and @RejCategory<>'' and @Exclude=1
	begin
	select @strsqlmid =  @strsqlmid + '  where rejectioncodeinformation.rejectionID not in (' + @RejectionID + ')'
	---mod 1
--	select @strsqlmid =  @strsqlmid + ' and ( Machineinformation.machineid = ''' + @machineid + ''')'
--	select @strsqlmid=@strsqlmid+ 'and (rejectioncodeinformation.Catagory='''+@RejCategory+''')'
	--select @strsqlmid =  @strsqlmid + ' and ( Machineinformation.machineid = N''' + @machineid + ''')'
	select @strsqlmid =  @strsqlmid + ' and ( Machineinformation.machineid in (' + @MachineID +') ) '
	select @strsqlmid=@strsqlmid+ 'and (rejectioncodeinformation.Catagory = N'''+@RejCategory+''')'
	---mod 1
	end
if isnull(@RejectionID, '') <> '' and isnull(@machineid,'') <> '' and @RejCategory='' and @Exclude=1
	begin
	select @strsqlmid =  @strsqlmid + '  where rejectioncodeinformation.rejectionID not in (' + @RejectionID + ')'
	---mod 1
--	select @strsqlmid =  @strsqlmid + ' and ( Machineinformation.machineid = ''' + @machineid + ''')'
	--select @strsqlmid =  @strsqlmid + ' and ( Machineinformation.machineid = N''' + @machineid + ''')'
	select @strsqlmid =  @strsqlmid + ' and ( Machineinformation.machineid in (' + @MachineID +') ) '
	---mod 1
	end
--change
if isnull(@RejectionID, '') <> '' and isnull(@machineid,'') = '' and @RejCategory<>'' and @Exclude=0
	begin
	select @strsqlmid =  @strsqlmid + ' where rejectioncodeinformation.rejectionID in( ' + @RejectionID + ' )'
	---mod 1
--	select @strsqlmid=@strsqlmid+ 'and (rejectioncodeinformation.Catagory='''+@RejCategory+''')'
	select @strsqlmid=@strsqlmid+ 'and (rejectioncodeinformation.Catagory = N'''+@RejCategory+''')'
	---mod 1
	end
if isnull(@RejectionID, '') <> '' and isnull(@machineid,'') = '' and @RejCategory='' and @Exclude=0
	begin
	select @strsqlmid =  @strsqlmid + ' where rejectioncodeinformation.rejectionID in( ' + @RejectionID + ' )'
	end
--change
if isnull(@RejectionID, '') <> '' and isnull(@machineid,'') = '' and @RejCategory<>'' and @Exclude=1
	begin
	select @strsqlmid =  @strsqlmid + '  where rejectioncodeinformation.rejectionID not in( ' + @RejectionID + ')'
	---mod 1
--	select @strsqlmid=@strsqlmid+ 'and (rejectioncodeinformation.Catagory='''+@RejCategory+''')'
	select @strsqlmid=@strsqlmid+ 'and (rejectioncodeinformation.Catagory = N'''+@RejCategory+''')'
	---mod 1
	end
if isnull(@RejectionID, '') <> '' and isnull(@machineid,'') = '' and @RejCategory='' and @Exclude=1
	begin
	select @strsqlmid =  @strsqlmid + ' where  rejectioncodeinformation.rejectionID not in( ' + @RejectionID + ')'
	end
if isnull(@RejectionID, '') = '' and isnull(@machineid,'') <> '' and @RejCategory<>''
	begin
	---mod 1
--	select @strsqlmid =  @strsqlmid + ' where  ( Machineinformation.machineid = ''' + @machineid + ''')'
--	select @strsqlmid=@strsqlmid+ 'and (rejectioncodeinformation.Catagory='''+@RejCategory+''')'
	--select @strsqlmid =  @strsqlmid + ' where  ( Machineinformation.machineid = N''' + @machineid + ''')'
	select @strsqlmid =  @strsqlmid + ' where  ( Machineinformation.machineid in (' + @MachineID +') ) '
	select @strsqlmid=@strsqlmid+ 'and (rejectioncodeinformation.Catagory = N'''+@RejCategory+''')'
	---mod 1
	end
if isnull(@RejectionID, '') = '' and isnull(@machineid,'') <> '' and @RejCategory=''
	begin
	---mod 1
--	select @strsqlmid =  @strsqlmid + ' where ( Machineinformation.machineid = ''' + @machineid + ''')'
	--select @strsqlmid =  @strsqlmid + ' where ( Machineinformation.machineid = N''' + @machineid + ''')'
	select @strsqlmid =  @strsqlmid + ' where ( Machineinformation.machineid in (' + @MachineID +') ) '
	---mod 1
	end
if isnull(@RejectionID, '') = '' and isnull(@machineid,'') = '' and @RejCategory<>''
	begin
	---mod 1
--	select @strsqlmid=@strsqlmid+ ' where (rejectioncodeinformation.Catagory='''+@RejCategory+''')'
	select @strsqlmid=@strsqlmid+ ' where (rejectioncodeinformation.Catagory = N'''+@RejCategory+''')'
	---mod 1
	end
if isnull(@strsqlmid,'')=''
	begin
	select @StrPlant=''
	if isnull(@PlantID,'')<>''
	begin
		---mod 1
--		SELECT @StrPlant=' where PlantMachine.PlantID='''+ @PlantID +''''
		SELECT @StrPlant=' where PlantMachine.PlantID = N'''+ @PlantID +''''
		---mod 1
	END
	end
if isnull(@strsqlmid,'')<>''
	begin
	select @StrPlant=''
	if isnull(@PlantID,'')<>''
	begin
		---mod 1
--		SELECT @StrPlant=' and PlantMachine.PlantID='''+ @PlantID +''''
		SELECT @StrPlant=' and PlantMachine.PlantID = N'''+ @PlantID +''''
		---mod 1
	end
	END
	
select @strsql = @strsql +  @strsqlmid + @StrTPMMachines + @StrPlant + @StrGroupID + ' ORDER BY  rejectioncodeinformation.rejectionID, Machineinformation.MachineID'
print @strsqlmid
print @strsql

print @strsql
exec (@strsql)
--select * from #TempMchRejdata
end


if @RepType='Componentwise'
begin
select @strsqlmid=''
select @strcategory=''
if isnull(@RejCategory,'')<>''
begin
	---mod 1
--	select @strcategory=' AND  rejectioncodeinformation.Catagory='''+@RejCategory+''''
	select @strcategory=' AND  rejectioncodeinformation.Catagory = N'''+@RejCategory+''''
	---mod 1
end
	select @strsql=''

	--select @strsql='insert into #TempCOData(ComponentId,OperationNo,RjctID,QtyR) select CO.ComponentID,CO.OperationNO, ' --DR0292
	select @strsql='insert into #TempCOData(ComponentId,OperationNo,RjctID,QtyR) select distinct CO.ComponentID,CO.OperationNO, ' --DR0292
	select @strsql=@strsql+'rejectioncodeinformation.rejectionID,0 from componentoperationpricing CO cross join rejectioncodeinformation'
	if isnull(@RejectionID, '') <> '' and isnull(@ComponentId,'') <> '' and isnull(@OperationNo,'')<>'' and @Exclude=0
	begin
	select @strsqlmid =  @strsqlmid + ' where  rejectioncodeinformation.rejectionID in (' + @RejectionID + ')'
	---mod 1
--	select @strsqlmid =  @strsqlmid + ' and ( CO.ComponentId = ''' + @ComponentId + ''') and (CO.OperationNO=''' +@OperationNo+''' )'
	select @strsqlmid =  @strsqlmid + ' and ( CO.ComponentId = N''' + @ComponentId + ''') and (CO.OperationNO = N''' +@OperationNo+''' )'
	---mod 1
	end
	
	if isnull(@RejectionID, '') <> '' and isnull(@ComponentId,'') <> '' and (@OperationNO='') and @Exclude=0
	begin
	select @strsqlmid =  @strsqlmid + ' where  rejectioncodeinformation.rejectionID in (' + @RejectionID + ')'
	---mod 1
--	select @strsqlmid =  @strsqlmid + ' and ( CO.ComponentId = ''' + @ComponentId + ''')'
	select @strsqlmid =  @strsqlmid + ' and ( CO.ComponentId = N''' + @ComponentId + ''')'
	---mod 1
	end
	if isnull(@RejectionID, '') <> '' and isnull(@ComponentId,'') <> '' and isnull(@OperationNo,'')<>'' and @Exclude=1
	begin
	select @strsqlmid =  @strsqlmid + ' where  rejectioncodeinformation.rejectionID not in (' + @RejectionID + ')'
	---mod 1
--	select @strsqlmid =  @strsqlmid + ' and ( CO.ComponentId = ''' + @ComponentId + ''') and (CO.OperationNO=''' +@OperationNo+''' )'
	select @strsqlmid =  @strsqlmid + ' and ( CO.ComponentId = N''' + @ComponentId + ''') and (CO.OperationNO = N''' +@OperationNo+''' )'
	---mod 1
	end
	if isnull(@RejectionID, '') <> '' and isnull(@ComponentId,'') <> '' and (@OperationNO='') and @Exclude=1
	begin
	select @strsqlmid =  @strsqlmid + ' where  rejectioncodeinformation.rejectionID not in (' + @RejectionID + ')'
	---mod 1
--	select @strsqlmid =  @strsqlmid + ' and ( CO.ComponentId = ''' + @ComponentId + ''')'
	select @strsqlmid =  @strsqlmid + ' and ( CO.ComponentId = N''' + @ComponentId + ''')'
	---mod 1
	end
	
	if isnull(@RejectionID, '') <> '' and isnull(@ComponentId,'') = '' and @Exclude=0
	begin
	select @strsqlmid =  @strsqlmid + ' where rejectioncodeinformation.rejectionID in( ' + @RejectionID + ' )'
	end
	if isnull(@RejectionID, '') <> '' and isnull(@ComponentId,'') = '' and @Exclude=1
	begin
	select @strsqlmid =  @strsqlmid + ' where  rejectioncodeinformation.rejectionID not in( ' + @RejectionID + ')'
	end
	
	if isnull(@RejectionID, '') = '' and isnull(@ComponentId,'') <> '' and  isnull(@OperationNo,'')<>''
	begin
	---mod 1
--	select @strsqlmid =  @strsqlmid + ' where ( CO.Componentid = ''' + @ComponentId + ''') and (CO.OperationNO=''' +@OperationNo+''' )'
	select @strsqlmid =  @strsqlmid + ' where ( CO.Componentid = N''' + @ComponentId + ''') and (CO.OperationNO = N''' +@OperationNo+''' )'
	---mod 1
	end
	if isnull(@RejectionID, '') = '' and isnull(@ComponentId,'') <> '' and @OperationNo=''
	begin
	---mod 1
--	select @strsqlmid =  @strsqlmid + ' where ( CO.ComponentId = ''' + @ComponentId + ''') '
	select @strsqlmid =  @strsqlmid + ' where ( CO.ComponentId = N''' + @ComponentId + ''') '
	---mod 1
	end
	
	if isnull(@strsqlmid,'' )=''
	begin
	select @strcategory=''
	if isnull(@RejCategory,'')<>''
	begin
	---mod 1
--	select @strcategory=' WHERE rejectioncodeinformation.Catagory='''+@RejCategory+''''
	select @strcategory=' WHERE rejectioncodeinformation.Catagory = N'''+@RejCategory+''''
	---mod 1
	END
	end
	if isnull(@strsqlmid,'' )<>''
	begin
	select @strcategory=''
	if isnull(@RejCategory,'')<>''
	begin
	---mod 1
--	select @strcategory=' and rejectioncodeinformation.Catagory='''+@RejCategory+''''
	select @strcategory=' and rejectioncodeinformation.Catagory = N'''+@RejCategory+''''
	---mod 1
	END
	end
	select @strsql =  @strsql +@strsqlmid+ @strcategory + ' Order by rejectioncodeinformation.rejectionID,CO.ComponentID,CO.OperationNO'
print @strsql
exec (@strsql)
---select * from #TempCOData
end
select @StrPlantID=''
select @strmachine=''
select @StrRejId=''
select @StrCompID=''
select @StrOpnno=''
if isnull(@PlantID,'')<>''
begin
---mod 1
--select @StrPlantID=' AND (SPD.PlantID ='''+@PlantID+''')'
select @StrPlantID=' AND (SPD.PlantID = N'''+@PlantID+''')'	
---mod 1
end
if isnull(@MachineID,'')<>''
begin
---mod 1
--select @strmachine=' AND (SPD.MachineID ='''+@MachineID+''')'
--select @strmachine=' AND (SPD.MachineID = N'''+@MachineID+''')'
select @strmachine=' AND (SPD.MachineID in (' + @MachineID +') )'
---mod 1
end
IF ISNULL(@RejectionID,'')<>'' and @Exclude=0
BEGIN
SELECT @StrRejId=' AND (RC.rejectionid in ('+@RejectionID+' ))'
END
IF ISNULL(@RejectionID,'')<>'' and @Exclude=1
BEGIN
SELECT @StrRejId=' AND (RC.rejectionid not in ('+@RejectionID+' ))'
END
if isnull(@ComponentID,'')<>''
begin
---mod 1
--select @StrCompId='and (SPD.ComponentID='''+@ComponentID+''')'
select @StrCompId='and (SPD.ComponentID = N'''+@ComponentID+''')'
---mod 1
end
if isnull(@Operationno,'')<>''
begin
---mod 1
--select @StrOpnno='and (SPD.OperationNo='''+@Operationno+''')'
select @StrOpnno='and (SPD.OperationNo = N'''+@Operationno+''')'
---mod 1
end
if @RepType='Machinewise'
begin
	/*select @strsql=''
	select @StrSql='update #TempMchRejdata set RejQty= RejQty+t2.RQty from '
	SELECT @StrSql=@StrSql+ ' ( select SPD.MachineID as mchID,RC.rejectionid as RejID,sum(R.Rejection_Qty) as RQty '
	SELECT @StrSql=@StrSql+ 'From ShiftProductionDetails SPD Left Outer Join ShiftRejectionDetails R ON SPD.ID=R.ID'
	SELECT @StrSql=@StrSql+' inner join rejectioncodeinformation RC on R.Rejection_Reason=RC.rejectiondescription '
	SELECT @StrSql=@StrSql+ ' LEFT OUTER JOIN PlantMachine ON SPD.machineid = PlantMachine.MachineID '
	SELECT @StrSql=@StrSql+ ' inner join ComponentoperationPricing CO  on (SPD.Componentid=CO.Componentid and SPD.Operationno=CO.Operationno) '
	SELECT @StrSql=@StrSql+ ' WHERE SPD.pDate>='''+ Convert(Nvarchar(20),@starttime)+''' and SPD.pDate<='''+convert(nvarchar(20),@EndTime)+''' '
	SELECT @StrSql=@StrSql  +@StrPlantID+@StrMachine+@StrRejID+@StrCompId+@StrOpnno
	SELECT @StrSql=@StrSql  + 'group By SPD.Machineid ,RC.rejectionid ,SPD.ComponentID ,SPD.OperationNo ) '
	SELECT @StrSql=@StrSql  + 'as t2 inner join #TempMchRejdata on t2.mchID=#TempMchRejdata.MachineId and t2.RejID=#TempMchRejdata.RejnID '
	*/
	
	select @strsql=''
	select @Strsql='Update #TempMchRejdata set RejQty= isnull(RejQty,0) + isnull(t2.RQty,0) from '
	SELECT @StrSql=@StrSql+ ' ( select SPD.MachineID as mchID,RC.rejectionid as RejID,sum(R.Rejection_Qty) as RQty '
	SELECT @StrSql=@StrSql+ 'From ShiftProductionDetails SPD Left Outer Join ShiftRejectionDetails R ON SPD.ID=R.ID'
	SELECT @StrSql=@StrSql+' inner join rejectioncodeinformation RC on R.Rejection_Reason=RC.rejectionid '
	SELECT @StrSql=@StrSql+ ' LEFT OUTER JOIN PlantMachine ON SPD.machineid = PlantMachine.MachineID 
							LEFT JOIN PlantMachineGroups on spd.machineid = PlantMachineGroups.machineid '
	SELECT @StrSql=@StrSql+ ' WHERE SPD.pDate>='''+ Convert(Nvarchar(20),@starttime)+''' and SPD.pDate<='''+convert(nvarchar(20),@EndTime)+''' '
	SELECT @StrSql=@StrSql  +@StrPlantID+@StrMachine+@StrRejID+@StrCompId+@StrOpnno + @StrGroupID
	SELECT @StrSql=@StrSql  + 'group By RC.rejectionid ,SPD.MachineID ) '
	SELECT @StrSql=@StrSql  + 'as t2 inner join  #TempMchRejdata on  t2.RejID=#TempMchRejdata.RejnID and t2.mchID=#TempMchRejdata.MachineId'
	print (@StrSql)
	EXEC (@StrSql)
	
	INSERT INTO #TempRejectionDataMc (MachineID, RejectID,RejQty ,RRejQty,RMRejQty,McRejQty ,TotalRej )
		select  MachineID,RejnID,RejQty,0,0,0,0
		from #TempMchRejdata
	
	
		
	update #TempRejectionDataMc set
	RRejQty=(select sum(RejQty) from #TempRejectionDataMc as TR where TR.RejectID=#TempRejectionDataMc.RejectID),
	RMRejQty=(SELECT SUM(RejQty) FROM #TempRejectionDataMc as TR WHERE TR.machineID = #TempRejectionDataMc.machineid and TR.RejectID=#TempRejectionDataMc.RejectID),
	McRejQty=(SELECT SUM(RejQty) FROM #TempRejectionDataMc as TR WHERE TR.machineID = #TempRejectionDataMc.machineid),
	TotalRej=(select sum(RejQty) from #TempRejectionDataMc )
end
if @RepType='Componentwise'
begin
	select @strsql=''
	select @Strsql='Update #TempCOData set QtyR= QtyR+t2.RjQty from '
	SELECT @StrSql=@StrSql+ ' ( select SPD.MachineID as mchID,SPD.ComponentID as CompID,SPD.OperationNo as Opno,RC.rejectionid as RejID,sum(R.Rejection_Qty) as RjQty '
	SELECT @StrSql=@StrSql+ 'From ShiftProductionDetails SPD Left Outer Join ShiftRejectionDetails R ON SPD.ID=R.ID'
	SELECT @StrSql=@StrSql+' inner join rejectioncodeinformation RC on R.Rejection_Reason=RC.rejectionid '
	SELECT @StrSql=@StrSql+ ' LEFT OUTER JOIN PlantMachine ON SPD.machineid = PlantMachine.MachineID 
								LEFT JOIN PlantMachineGroups on spd.machineid = PlantMachineGroups.machineid '
	SELECT @StrSql=@StrSql+ ' WHERE SPD.pDate>='''+ Convert(Nvarchar(20),@starttime)+''' and SPD.pDate<='''+convert(nvarchar(20),@EndTime)+''' '
	SELECT @StrSql=@StrSql  +@StrPlantID+@StrMachine+@StrRejID+@StrCompId+@StrOpnno + @StrGroupID
	SELECT @StrSql=@StrSql  + 'group By SPD.ComponentID ,SPD.OperationNo,RC.rejectionid ,SPD.MachineID ) '
	SELECT @StrSql=@StrSql  + 'as t2 inner join  #TempCOData on  t2.RejID=#TempCOData.RjctID '
	SELECT @StrSql=@StrSql  + ' and t2.CompID=#TempCOData.Componentid and t2.Opno=#TempCOData.OperationNo'
	
	print (@StrSql)
	EXEC (@StrSql)
	
	insert into  #TempRejectionDataCO(Componentid,OperationNo,RjctionID,RQty,RejRQty,CORejQty,SCoRejqty,TOtRej)
	select ComponentID,OperationNo,RjctID,QtyR,0,0,0,0 from #TempCOData


update #TempRejectionDataCO set
RejRQty=(select sum(RQty) from #TempRejectionDataCO as TR where TR.RjctionID=#TempRejectionDataCO.RjctionID),
CORejQty=(select sum(RQty) from #TempRejectionDataCO as TR where TR.RjctionID=#TempRejectionDataCO.RjctionID and TR.Componentid=#TempRejectionDataCO.Componentid and TR.OperationNo=#TempRejectionDataCO.OperationNo),
SCoRejqty=(select sum(RQty) from #TempRejectionDataCO as TR where TR.Componentid=#TempRejectionDataCO.Componentid and TR.OperationNo=#TempRejectionDataCO.OperationNo),
TOtRej=	(select sum(RQty) from #TempRejectionDataCO )
end
---output
if @RepType='Machinewise'
select @StartTime as StartTime,
@EndTime as EndTime,
Machineid,
--RejectID as RejectionCode,	
rejectioncodeinformation.rejectiondescription as Rejectiondesc,
--Componentid,
--OperationNo,
RejQty ,
RRejQty,
RMRejQty,
McRejQty ,
--CORejQty ,
--SCoRejqty,
TotalRej
from #TempRejectionDataMc  inner join rejectioncodeinformation  on #TempRejectionDataMc.RejectID=rejectioncodeinformation.rejectionid
WHERE McRejQty>0 and  RRejQty>0
Order By  rejectioncodeinformation.rejectiondescription, machineid --g:
--Order By  RRejQty desc,rejectioncodeinformation.rejectiondescription, McRejQty desc,RMRejQty desc, machineid
else if @Reptype='Componentwise'
select @StartTime as Starttime,
@EndTime as EndTime,
rejectioncodeinformation.rejectiondescription as Rejectiondesc,
Componentid,
OperationNo,
RQty,
RejRQty,
CORejQty,
	SCoRejqty,
	TOtRej
	from #TempRejectionDataCO inner join rejectioncodeinformation  on #TempRejectionDataCO.RjctionID=rejectioncodeinformation.rejectionid
	where SCoRejqty>0 and RejRQty>0
	order by RejRQty desc,rejectioncodeinformation.rejectiondescription,SCoRejqty desc,ComponentId,Operationno,CORejQty desc
end
