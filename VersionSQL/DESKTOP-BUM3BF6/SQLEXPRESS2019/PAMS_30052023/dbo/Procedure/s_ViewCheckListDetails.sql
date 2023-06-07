/****** Object:  Procedure [dbo].[s_ViewCheckListDetails]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[s_ViewCheckListDetails] '1','2015-09-29 10:15:00','CT-23','CNC Machine','Machine Bed and Bottom','Clean','Daily','DO','','Done','','View'
--select * from [dbo].[MacMaintSchedules]
--select * from MacMaintTransaction
CREATE PROCEDURE [dbo].[s_ViewCheckListDetails]
	@ActivityID int='',
	@Time datetime='',
	@Machine nvarchar(50)='',
	@SubSystem nvarchar(50)='',
	@PartName nvarchar(1000)='',
	@Activity nvarchar(1000)='',
	@frequency nvarchar(50)='',
	@Status nvarchar(50)='',
	@Remarks nvarchar(50)='',
	@Standards nvarchar(50)='',
	@Description nvarchar(1000)='',	
	@param nvarchar(50)=''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	create table #ShiftTemp
	(
	StartDate datetime,
	ShiftName nvarchar(50),
	Starttime datetime,
	EndTime datetime,
	ShiftID int
	)
--satya
Declare @CurrentTime datetime
if isnull(@Time,'')= ''
BEGIN
	SET @CurrentTime = GetDate();
END
ELSE
BEGIN
	SET @CurrentTime = @Time;
END
insert into #ShiftTemp(StartDate,Shiftname,Starttime,Endtime,Shiftid)
exec [s_GetCurrentShiftTime] @CurrentTime,''
declare @Dt as nvarchar(50)
declare @Shift nvarchar(50)
declare @ShiftName as nvarchar(50)
declare @CountMaster as nvarchar(50)
declare @countTransaction as nvarchar(50)
select @Dt= CONVERT(char(10), StartDate,126) from #ShiftTemp
select @Shift =Shiftid from #ShiftTemp 
select @ShiftName=shiftname from  #ShiftTemp 

	if @Shift='1'
		BEGIN
			select @CountMaster= count(*) from [MacMaintSchedules] where Machine=@Machine  and  Shift1=1
		END
	if @Shift='2'
		BEGIN
			select @CountMaster= count(*) from [MacMaintSchedules] where Machine=@Machine and  Shift2=1
		END
	if @Shift='3'
		BEGIN
			select @CountMaster= count(*) from [MacMaintSchedules] where Machine=@Machine  and  Shift3=1
		END

	select @countTransaction= count(*) from MacMaintTransaction where Machine=@Machine  and CONVERT(char(10),[Date],126)= @dt  and Shift=@ShiftName


	if @countTransaction >=1
		BEGIN
			select 'Enable' as 'Procced'
		END
	ELSE
		BEGIN
			select 'Disable' as 'Procced'
		END



if @param='View'
BEGIN
		declare @FolderPath as nvarchar(4000)
		declare @Extension as nvarchar(100)
		select @FolderPath= FolderPath from FolderPathDefinition where FolderType='SubSystemPath';
		SELECT @Extension = FileExtension  from FolderPathDefinition where  FolderType='SubSystemPath';


	if exists(select * from [dbo].[FolderPathDefinition] where [FolderPath]='1')
	BEGIN
	select distinct @FolderPath+'\'+LTRIM(RTRIM(@machine))+'\'+ImagePath+@Extension as ImagePath,ImageNotes from [MacMaintSchedules] where Machine=@Machine and SubSystem=@SubSystem 
	END
	else
	BEGIN
	select distinct @FolderPath+'\'+ImagePath+@Extension as ImagePath,ImageNotes from [MacMaintSchedules] where Machine=@Machine and SubSystem=@SubSystem 
	END
	
	if @Shift='1'
	BEGIN
	select  ROW_NUMBER() OVER(ORDER BY M.ActivityID)as ROWNUMBER ,M.ActivityID,M.Machine,M.PartNo,M.SubSystem,M.Activity,M.Frequency as Frequency,case when T.[TimeStamp]=''or T.[TimeStamp] is null then 'DO' else '' END as [Status],T.[TimeStamp],T.[Remarks]
	from [MacMaintSchedules] M left outer join 
	(select MC.ActivityID,MC.Machine,MC.PartNo,MC.SubSystem,MC.Activity,MC.Frequency as Frequency,case when MT.[TimeStamp]=''or MT.[TimeStamp] is null then 'DO' else '' END as [Status],MT.[TimeStamp],MT.[Remarks]
	 from [MacMaintSchedules] MC
	left outer join MacMaintTransaction MT on MC.ActivityID=MT.ActivityID and MC.Machine=MT.Machine and MC.SubSystem=MT.SubSystem
	where MC.Machine=@Machine and MC.SubSystem=@SubSystem and MT.Date=@dt  and MT.Shift=@ShiftName  and MC.Shift1=1)t on t.ActivityID=m.ActivityID 
	where M.Machine=@Machine and M.SubSystem=@SubSystem and  M.Shift1=1
	END
	if @Shift='2'
	BEGIN

	select ROW_NUMBER() OVER(ORDER BY M.ActivityID)as ROWNUMBER ,M.ActivityID,M.Machine,M.PartNo,M.SubSystem,M.Activity,M.Frequency as Frequency,case when T.[TimeStamp]=''or T.[TimeStamp] is null then 'DO' else '' END as [Status],T.[TimeStamp],T.[Remarks]
	from [MacMaintSchedules] M left outer join 
	(select MC.ActivityID,MC.Machine,MC.PartNo,MC.SubSystem,MC.Activity,MC.Frequency as Frequency,case when MT.[TimeStamp]=''or MT.[TimeStamp] is null then 'DO' else '' END as [Status],MT.[TimeStamp],MT.[Remarks]
	 from [MacMaintSchedules] MC
	left outer join MacMaintTransaction MT on MC.ActivityID=MT.ActivityID and MC.Machine=MT.Machine and MC.SubSystem=MT.SubSystem
	where MC.Machine=@Machine and MC.SubSystem=@SubSystem and MT.Date=@dt  and MT.Shift=@ShiftName and MC.Shift2=1)t on t.ActivityID=m.ActivityID 
	where M.Machine=@Machine and M.SubSystem=@SubSystem  and  M.Shift2=1
	END
	if @Shift='3'
	BEGIN
		select ROW_NUMBER() OVER(ORDER BY M.ActivityID)as ROWNUMBER ,M.ActivityID,M.Machine,M.PartNo,M.SubSystem,M.Activity,M.Frequency as Frequency,case when T.[TimeStamp]=''or T.[TimeStamp] is null then 'DO' else '' END as [Status],T.[TimeStamp],T.[Remarks]
	from [MacMaintSchedules] M left outer join 
	(select MC.ActivityID,MC.Machine,MC.PartNo,MC.SubSystem,MC.Activity,MC.Frequency as Frequency,case when MT.[TimeStamp]=''or MT.[TimeStamp] is null then 'DO' else '' END as [Status],MT.[TimeStamp],MT.[Remarks]
	 from [MacMaintSchedules] MC
	left outer join MacMaintTransaction MT on MC.ActivityID=MT.ActivityID and MC.Machine=MT.Machine and MC.SubSystem=MT.SubSystem
	where MC.Machine=@Machine and MC.SubSystem=@SubSystem and MT.Date=@dt  and MT.Shift=@ShiftName  and MC.Shift3=1)t on t.ActivityID=m.ActivityID 
	where M.Machine=@Machine and M.SubSystem=@SubSystem and M.Shift3=1
	END
		
		
	

END


if @param='Save'
BEGIN
	if not exists(select * from MacMaintTransaction where ActivityID=@ActivityID and Machine=@machine and SubSystem=@subSystem  and [Date]=@Dt and [Shift]=@ShiftName)
		BEGIN
			insert into MacMaintTransaction(ActivityID,Machine,SubSystem,PartNO,Activity,Frequency,[Status],Remarks,[TimeStamp],[Date],[Shift])
			select @ActivityID,@Machine,@SubSystem,@PartName,@Activity,@frequency,@Status,@Remarks,@time,@Dt,@ShiftName
		END
	else
		BEGIN
			update MacMaintTransaction set Date = @Dt, [TimeStamp]=@Time,Remarks=@Remarks where ActivityID=@ActivityID and Machine=@Machine and SubSystem=@SubSystem
			 and [Date]=@Dt and [Shift]=@ShiftName
		END
END

END
