/****** Object:  Procedure [dbo].[s_GetCOwiseFolderPath]    Committed by VersionSQL https://www.versionsql.com ******/

--[dbo].[s_GetCOwiseFolderPath]'MCV 320','ATH-16-16','7'
CREATE PROCEDURE [dbo].[s_GetCOwiseFolderPath]
                @machineID nvarchar(50),
				@ComponentID nvarchar(50),
                @OperationID nvarchar(50)
AS
BEGIN
                -- SET NOCOUNT ON added to prevent extra result sets from
                -- interfering with SELECT statements.
                SET NOCOUNT ON;

create table #temp
(
FileType nvarchar(50),
filePath nvarchar(4000)
)
declare @MacSel  as int;
declare @MOPath as nvarchar(4000);
declare @DrawingPath as nvarchar(4000);
declare @ProgramNumber as nvarchar(4000);
declare @ControlPath as nvarchar(4000);
declare @operationPath as nvarchar(4000);
declare @MOPathExt as nvarchar(4000);
declare @DrawingPathExt as nvarchar(50);
declare @ProgramNumberExt as nvarchar(50);
declare @ControlPathExt as nvarchar(50);
declare @OperationPathExt as nvarchar(50);

select @MOPath=''
select @MOPath=folderpath,@MOPathExt =FileExtension from  FolderPathDefinition where FolderType='MOPath'
select @ControlPath=folderpath,@ControlPathExt=FileExtension from FolderPathDefinition where FolderType='ControlPath'
select @ProgramNumber=folderpath,@ProgramNumberExt=FileExtension from FolderPathDefinition where FolderType='ProgramPath'
select @DrawingPath=folderpath,@DrawingPathExt=FileExtension from FolderPathDefinition where FolderType='DrawingPath'
select @MacSel = isnull(folderpath,0) from FolderPathDefinition where FolderType='MachineSelected'
select @OperationPath =folderpath,@OperationPathExt=FileExtension from  FolderPathDefinition where FolderType='OperationPath'


If @MacSel = 1
BEGIN
	SELECT @MOPath=@MOPath + '\' + RTRIM(lTRIM(@machineid)) +'\'+ RTRIM(lTRIM(@Componentid))+'_'+RTRIM(lTRIM(@Operationid))+@MOPathExt
	SELECT @DrawingPath=@DrawingPath + '\' + RTRIM(lTRIM(@machineid)) +'\'+ RTRIM(lTRIM(@Componentid))+'_'+RTRIM(lTRIM(@Operationid))+@DrawingPathExt
	SELECT @ProgramNumber=@ProgramNumber + '\' + RTRIM(lTRIM(@machineid)) +'\'+ RTRIM(lTRIM(@Componentid))+'_'+RTRIM(lTRIM(@Operationid)) +@ProgramNumberExt
	SELECT @ControlPath=@ControlPath + '\' + RTRIM(lTRIM(@machineid)) +'\'+ RTRIM(lTRIM(@Componentid))+'_'+RTRIM(lTRIM(@Operationid)) +@ControlPathExt 
	SELECT @OperationPath=@OperationPath + '\' + RTRIM(lTRIM(@machineid)) +'\'+ RTRIM(lTRIM(@Componentid))+'_'+RTRIM(lTRIM(@Operationid)) +@OperationPathExt 
END
else
BEGIN
	SELECT @MOPath=@MOPath + '\' + RTRIM(lTRIM(@Componentid))+'_'+RTRIM(lTRIM(@Operationid))+@MOPathExt 
	SELECT top 1 @DrawingPath=@DrawingPath +'\'+RTRIM(lTRIM(@Componentid))+'_'+RTRIM(lTRIM(@Operationid))+@DrawingPathExt 
	SELECT @ProgramNumber=@ProgramNumber + '\' +RTRIM(lTRIM(@Componentid))+'_'+RTRIM(lTRIM(@Operationid))+@ProgramNumberExt
	SELECT @ControlPath=@ControlPath+'\'+RTRIM(lTRIM(@Componentid))+'_'+RTRIM(lTRIM(@Operationid))+@ControlPathExt
	SELECT @OperationPath=@OperationPath+'\'+RTRIM(lTRIM(@Componentid))+'_'+RTRIM(lTRIM(@Operationid))+@OperationPathExt
END


	--insert into #temp(FileType,FilePath)
	--SELECT 'MOPath',@MOPath  
	insert into #temp(FileType,FilePath)
	SELECT 'DrawingPath',@DrawingPath  
	insert into #temp(FileType,FilePath)
	SELECT 'ProgramNumber',@ProgramNumber 
	insert into #temp(FileType,FilePath)
	SELECT 'ControlPath',@ControlPath  
	insert into #temp(FileType,FilePath)
	SELECT 'OperationPath',@Operationpath

	select * from #temp;

   
END
