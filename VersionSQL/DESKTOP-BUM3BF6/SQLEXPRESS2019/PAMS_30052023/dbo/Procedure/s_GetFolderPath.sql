/****** Object:  Procedure [dbo].[s_GetFolderPath]    Committed by VersionSQL https://www.versionsql.com ******/

--select * from MoSchedule
--[dbo].[s_GetFolderPath]'CM05P','840200'
CREATE PROCEDURE [dbo].[s_GetFolderPath]
                @machineID nvarchar(50)='',
                @MoNumber nvarchar(50)=''
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

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
                declare @MOPathExt as nvarchar(4000);
                declare @DrawingPathExt as nvarchar(50);
                declare @ProgramNumberExt as nvarchar(50);
                declare @ControlPathExt as nvarchar(50);
                declare @ProcessSheetPath as nvarchar(4000);
                declare @ProcessSheetExt as nvarchar(4000);

                select @MOPath=''

                select @MOPath=folderpath,@MOPathExt =FileExtension from  FolderPathDefinition where FolderType='MOPath'
                select @ControlPath=folderpath,@ControlPathExt=FileExtension from FolderPathDefinition where FolderType='ControlPath'
                select @ProgramNumber=folderpath,@ProgramNumberExt=FileExtension from FolderPathDefinition where FolderType='ProgramPath'
                select @DrawingPath=folderpath,@DrawingPathExt=FileExtension from FolderPathDefinition where FolderType='DrawingPath'
                select @MacSel = isnull(folderpath,0) from FolderPathDefinition where FolderType='MachineSelected'
                select @ProcessSheetPath=folderpath,@ProcessSheetExt=FileExtension from FolderPathDefinition where FolderType='ProcessSheetPath'
                

                If @MacSel = 1
                                BEGIN
                                                SELECT top 1 @MOPath=@MOPath + '\' + RTRIM(lTRIM(@machineid)) +'\'+@MoNumber+@MOPathExt
                                                from [dbo].[MOSchedule] where machineid=@machineID and  MONumber=@MoNumber
                                                SELECT top 1  @DrawingPath=@DrawingPath + '\' + RTRIM(lTRIM(@machineid)) +'\'+ isnull(DrawingNumber, ' ')+@DrawingPathExt
                                                from [dbo].[MOSchedule] where machineid=@machineID and MONumber=@MoNumber
                                                SELECT top 1 @ProgramNumber=@ProgramNumber + '\' + RTRIM(lTRIM(@machineid)) +'\'+ isnull(ProgramNumber, ' ') +@ProgramNumberExt
                                                from [dbo].[MOSchedule] where machineid=@machineID and MONumber=@MoNumber
                                                --SELECT @ControlPath=@ControlPath + '\' + RTRIM(lTRIM(@machineid)) +'\'+'TSSFQACP'+ControlPlanning+@ControlPathExt --Swathi As on  6/Nov/2015
                                                SELECT top 1 @ControlPath=@ControlPath + '\' + RTRIM(lTRIM(@machineid)) +'\'+ isnull(ControlPlanning, '') +' '+'TSSFQACP*'+@ControlPathExt --Swathi As on  6/Nov/2015
                                                from [dbo].[MOSchedule] where machineid=@machineID and MONumber=@MoNumber
                                                SELECT top 1 @ProcessSheetPath=@ProcessSheetPath + '\' + RTRIM(lTRIM(@machineid)) +'\'+ isnull(REPLACE(LTRIM(REPLACE(ProcessSheet, '0', '')), '', '0'), '')+'*'+ +@ProcessSheetExt
                                                from [dbo].[MOSchedule] where machineid=@machineID and MONumber=@MoNumber

                                END
                else
                                BEGIN
                                                SELECT top 1 @MOPath=@MOPath + '\' +@MoNumber+@MOPathExt from [dbo].[MOSchedule] where machineid=@machineID and MONumber=@MoNumber
                                                SELECT top 1 @DrawingPath=@DrawingPath +'\'+isnull(DrawingNumber, ' ')+@DrawingPathExt from [dbo].[MOSchedule] where machineid=@machineID and MONumber=@MoNumber
                                                SELECT top 1 @ProgramNumber=@ProgramNumber + '\' +isnull(ProgramNumber, ' ')+@ProgramNumberExt from [dbo].[MOSchedule] where machineid=@machineID and MONumber=@MoNumber
                                    --SELECT @ControlPath=@ControlPath+'\'+'TSSFQACP'+ControlPlanning+@ControlPathExt from [dbo].[MOSchedule] where machineid=@machineID and MONumber=@MoNumber --Swathi As on  6/Nov/2015
                                                SELECT top 1 @ControlPath=@ControlPath+'\'+isnull(ControlPlanning, '')+' '+'TSSFQACP*'+@ControlPathExt from [dbo].[MOSchedule] where machineid=@machineID and MONumber=@MoNumber --Swathi As on  6/Nov/2015
												SELECT top 1 @ProcessSheetPath=@ProcessSheetPath + '\' +isnull(REPLACE(LTRIM(REPLACE(ProcessSheet, '0', '')), '', '0'), '')+'*'+@ProcessSheetExt from [dbo].[MOSchedule] where machineid=@machineID and MONumber=@MoNumber
                                END

                                insert into #temp(FileType,FilePath)
                                SELECT 'MOPath',@MOPath  
                                insert into #temp(FileType,FilePath)
                                SELECT 'DrawingPath',@DrawingPath  
                                insert into #temp(FileType,FilePath)
                                SELECT 'ProgramNumber',@ProgramNumber 
                                insert into #temp(FileType,FilePath)
                                SELECT 'ControlPath',@ControlPath  
				insert into #temp(FileType,FilePath)
                                SELECT 'ProcessSheetPath',@ProcessSheetPath  

select * from #temp;

   
END
