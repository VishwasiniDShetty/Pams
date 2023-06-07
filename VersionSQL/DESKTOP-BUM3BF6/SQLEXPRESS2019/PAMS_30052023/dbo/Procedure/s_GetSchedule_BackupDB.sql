/****** Object:  Procedure [dbo].[s_GetSchedule_BackupDB]    Committed by VersionSQL https://www.versionsql.com ******/

/****************************************************************
Created By Sangeeta Kallur on 04-Dec-2006
--ER0263 - mod1: Modified By SyedArifM on 23-Aug-2010. To Store History Of Backup
To BackUp the TPM DataBase recursively as per user schedule
--DR0302 - Mod2: To Change DataBaseName Dynamically
******************************************************************/

CREATE         PROCEDURE [dbo].[s_GetSchedule_BackupDB]
	@ServerName NVarChar(50)='(local)',
	@StartDate  NVarChar(8),
	@EndDate  NVarChar(8)='99991231',
	@StartTime  NVarChar(6)='000000',
	@EndTime  NVarChar(6)='235959',
	@Occurs Integer,
	@Frequency Integer=0,
	@BackUpPath NVarChar(250)='C:',
	@DataBaseName NVarchar(25)
AS
BEGIN

Declare @CmdData As NVarChar(1000)
Declare @CmdLog As NVarChar(1000)
DECLARE @JobID BINARY(16) 
DECLARE @RetCode Int

DECLARE @FileOperation NVarchar(50)
Declare @JobName NVarchar(50) --Mod2

--Select @CmdData ='BACKUP DATABASE TPM TO DISK =''' + @BackUpPath + '\MyTPMBackup.dat_bak'' WITH  INIT'
--Select @CmdLog ='BACKUP LOG TPM TO DISK =''' + @BackUpPath + '\MyTPMBackup.log_bak'' WITH  INIT' ---Mod2
Select @CmdLog ='BACKUP LOG '+ @DataBaseName + ' TO DISK =''' + @BackUpPath + '\MyTPMBackup.log_bak'' WITH  INIT' ---Mod2


BEGIN TRANSACTION 
--Check SQLServerAgent Status
EXECUTE  @RetCode = master.dbo.xp_ServiceControl 'QUERYSTATE','SQLServerAgent'

--If Not Running Make it to Run
If @RetCode <> 0
BEGIN
	EXEC master.dbo.xp_ServiceControl 'START', 'SQLServerAgent'
END

-- Delete the job with the same name (if it exists)
  SELECT @JobID = job_id     
  FROM   msdb.dbo.sysjobs    WHERE (name = N'MyTPMBackup')    
   
  IF (@JobID IS NOT NULL)    
  BEGIN  
  -- Check if the job is a multi-server job  
  IF (EXISTS (SELECT  * 
              FROM    msdb.dbo.sysjobservers 
              WHERE   (job_id = @JobID) AND (server_id <> 0))) 
  BEGIN 
    -- There is, so abort the script 
    RAISERROR (N'Unable to import job ''MyTPMBackup'' since there is already a multi-server job with this name.', 16, 1) 
    GOTO EndSave  
  END 
  ELSE 
    -- Delete the [local] job 
    EXECUTE msdb.dbo.sp_delete_job @job_name = N'MyTPMBackup' 
    SELECT @JobID = NULL
  END 

--mod1: From Here
--select top 1 @FileOperation = valueintext from tpm.dbo.ShopDefaults where parameter like 'ScheduledBackup_File' ---Mod2
select top 1 @FileOperation = valueintext from ShopDefaults where parameter like 'ScheduledBackup_File' ---Mod2

if lower(@FileOperation) <> lower('overwriteFile') 
BEGIN
--Select @CmdData ='BACKUP DATABASE TPM TO DISK =''' + @BackUpPath + '\MyTPMBackup.dat_bak'' WITH  INIT' ---Mod2
Select @CmdData ='BACKUP DATABASE '+ @DataBaseName +' TO DISK =''' + @BackUpPath + '\MyTPMBackup.dat_bak'' WITH  INIT' ---Mod2
END
ELSE
BEGIN
--Select @CmdData ='BACKUP DATABASE TPM TO DISK =''' + @BackUpPath + '\MyTPMBackup1.dat_bak'' WITH  INIT' ---Mod2
Select @CmdData ='BACKUP DATABASE '+ @DataBaseName +' TO DISK =''' + @BackUpPath + '\MyTPMBackup1.dat_bak'' WITH  INIT' ---Mod2
END
--mod1: Till Here


-- Create job.
EXEC msdb.dbo.sp_add_job @job_name = 'MyTPMBackup',
     @description = 'MyTPMBackup',
     @owner_login_name = 'sa'
    

Select @JobName = 'Backup '+ @DataBaseName +' Data' --Mod2

-- Add job step (backup data).
EXEC msdb.dbo.sp_add_jobstep @job_name = 'MyTPMBackup',
    @step_name = @JobName,
    @subsystem = 'TSQL',
    @command = @CmdData,
    @on_success_action = 3,
    @retry_attempts = 5,
    @retry_interval = 5

---Mod2
Select @CmdData = ''
Select @CmdData = 'INSERT into '+ @DataBaseName +'.dbo.Schedule_BackUpDB (StartDate,StartTime,Occurs,Frequency,NextDate,NextTime,ServerName)
SELECT '+ @DataBaseName +'.dbo.f_GetTpmStrToDate(J1.last_run_date,getdate()) as StartDate,'+ @DataBaseName +'.dbo.f_GetTpmStrToTime(J1.last_run_time) as StartTime , 
J2.freq_type as Occurs,J2.freq_interval as Frequency,'+ @DataBaseName +'.dbo.f_GetTpmStrToDate(J2.next_run_date,getdate()) as NextRunDate,'+ @DataBaseName +'.dbo.f_GetTpmStrToTime(J2.next_run_time) as NextRunTime,
J3.Originating_server as Server
from msdb.dbo.sysjobsteps J1 
inner join msdb.dbo.sysjobschedules J2 on J1.Job_Id = J2.Job_Id
inner join  msdb.dbo.sysjobs J3 on J3.Job_Id = J2.Job_Id
where J3.name=''MyTPMBackup'' and J1.step_id =1'

---Mod2

----mod1: From Here
-- Add job step (backup data).
EXEC msdb.dbo.sp_add_jobstep @job_name = 'MyTPMBackup',
    @step_name = 'Insert Into Schedule_BackUpDB',
    @subsystem = 'TSQL',
    @command = 
/*'INSERT into tpm.dbo.Schedule_BackUpDB (StartDate,StartTime,Occurs,Frequency,NextDate,NextTime,ServerName)
SELECT  
tpm.dbo.f_GetTpmStrToDate(J1.last_run_date,getdate()) as StartDate,tpm.dbo.f_GetTpmStrToTime(J1.last_run_time) as StartTime , 
J2.freq_type as Occurs,J2.freq_interval as Frequency,tpm.dbo.f_GetTpmStrToDate(J2.next_run_date,getdate()) as NextRunDate,tpm.dbo.f_GetTpmStrToTime(J2.next_run_time) as NextRunTime,
J3.Originating_server as Server
from msdb.dbo.sysjobsteps J1 
inner join msdb.dbo.sysjobschedules J2 on J1.Job_Id = J2.Job_Id
inner join  msdb.dbo.sysjobs J3 on J3.Job_Id = J2.Job_Id
where J3.name=''MyTPMBackup'' and J1.step_id =1'*/ ---Mod2
@CmdData,---Mod2
 
   @on_success_action = 3,
    @retry_attempts = 5,
    @retry_interval = 5

---Mod2
Select @CmdData = ''
Select @CmdData = 'update '+ @DataBaseName +'.dbo.Schedule_BackUpDB set backuppath=

(select substring(
command,
charindex(''='',command)+2,
charindex(''_'',command,charindex('''''''',command))-charindex('''''''',command)-1
)
from msdb.dbo.sysjobsteps
where step_name=''Backup '+ @DataBaseName +' Data'')
 
where slno in (select max(slno) from '+ @DataBaseName +'.dbo.Schedule_BackUpDB)'
---Mod2

EXEC msdb.dbo.sp_add_jobstep @job_name = 'MyTPMBackup',
    @step_name = 'Update Schedule_BackUpDB',
    @subsystem = 'TSQL',
    @command = 
/*'update tpm.dbo.Schedule_BackUpDB set backuppath=

(select substring(
command,
charindex(''='',command)+2,
charindex(''_'',command,charindex('''''''',command))-charindex('''''''',command)-1
)
from msdb.dbo.sysjobsteps
where step_name=''Backup TPM Data'')
 
where slno in (select max(slno) from tpm.dbo.Schedule_BackUpDB)'*/ ---Mod2
@CmdData,
    @on_success_action = 3,
    @retry_attempts = 5,
    @retry_interval = 5


---Mod2
Select @CmdData = ''
Select @CmdData ='DECLARE @FolderName as nvarchar(50)
DECLARE @FileOperation NVarchar(50)

select top 1 @FileOperation = valueintext from '+ @DataBaseName +'.dbo.ShopDefaults where parameter like ''ScheduledBackup_File'' 
if lower(@FileOperation) <> lower(''overwriteFile'')  
BEGIN
DECLARE @Str NVarchar(500)

(select @FolderName = substring(
command,
charindex(''='',command)+2,
charindex(''MyTPMBackup.DAT'',command,charindex('''''''',command))-charindex('''''''',command)-1
)from msdb.dbo.sysjobsteps where step_name=''Backup '+ @DataBaseName +' Data'')

select @Str= ''RENAME '' + @FolderName + ''MyTPMBackup.dat_bak MyTPMBackup''+ replace(convert(varchar, getdate(),103),''/'','''') + replace(convert(varchar, getdate(),8),'':'','''')  +''.dat''
exec master.dbo.xp_cmdshell @str
END' 

EXEC msdb.dbo.sp_add_jobstep @job_name = 'MyTPMBackup',
    @step_name = 'Rename File',
    @subsystem = 'TSQL',
    @command = 
/*'DECLARE @FolderName as nvarchar(50)
DECLARE @FileOperation NVarchar(50)

select top 1 @FileOperation = valueintext from tpm.dbo.ShopDefaults where parameter like ''ScheduledBackup_File'' 
if lower(@FileOperation) <> lower(''overwriteFile'')  
BEGIN
DECLARE @Str NVarchar(500)

(select @FolderName = substring(
command,
charindex(''='',command)+2,
charindex(''MyTPMBackup.DAT'',command,charindex('''''''',command))-charindex('''''''',command)-1
)from msdb.dbo.sysjobsteps where step_name=''Backup TPM Data'')

select @Str= ''RENAME '' + @FolderName + ''MyTPMBackup.dat_bak MyTPMBackup''+ replace(convert(varchar, getdate(),103),''/'','''') + replace(convert(varchar, getdate(),8),'':'','''')  +''.dat''
exec master.dbo.xp_cmdshell @str
END'*/ ---Mod2
@CmdData,
    @on_success_action = 3, -- Quit with success.
    @retry_attempts = 5,
    @retry_interval = 5

/*
--From Arif --> To Move BackUpFile From One Folder To Another Folder
EXEC msdb.dbo.sp_add_jobstep @job_name = 'MyTPMBackup',
    @step_name = 'Move Folder',
    @subsystem = 'TSQL',
    @command = 
'DECLARE @FolderName as nvarchar(50)
DECLARE @FileOperation NVarchar(50)

select top 1 @FileOperation = valueintext from tpm.dbo.ShopDefaults where parameter like ''ScheduledBackup_File'' 
if @FileOperation <>''overwriteFile'' 
BEGIN
DECLARE @Str NVarchar(500)

(select @FolderName = substring(
command,
charindex(''='',command)+2,
charindex(''MyTPMBackup.DAT'',command,charindex('''''''',command))-charindex('''''''',command)-1
)from msdb.dbo.sysjobsteps where step_name=''Backup TPM Data'')

select @Str= ''Copy '' + @FolderName + ''MyTPMBackup.dat_bak MyTPMBackup''+ replace(convert(varchar, getdate(),103),''/'','''') + ''.dat  '' + @FolderName + ''MyTPMBackup.dat_bak MyTPMBackup''+ replace(convert(varchar, getdate(),103),''/'','''') + ''.dat''
exec master.dbo.xp_cmdshell @str
END
',
    @on_success_action = 1, -- Quit with success.
    @retry_attempts = 5,
    @retry_interval = 5
--To Arif 
*/



/*
-- Add job step (backup log).
EXEC msdb.dbo.sp_add_jobstep @job_name = 'MyTPMBackup',
    @step_name = 'Backup TPM Log',
    @subsystem = 'TSQL',
    @command = @CmdLog, --'BACKUP LOG TPM TO DISK = \MyTPMBackup.log_bak',
    @on_success_action = 1,
    @retry_attempts = 5,
    @retry_interval = 5
*/

----mod1: Till Here
-- Add the target servers.
EXEC msdb.dbo.sp_add_jobserver @job_name = 'MyTPMBackup', @server_name = @ServerName


-- Schedule job.
EXEC [msdb].dbo.sp_add_jobschedule @job_name = 'MyTPMBackup', 
    @name = 'ScheduledBackup_TPM',
    @freq_type = @Occurs, 
    @freq_interval = @Frequency, 
    @active_start_date =  @StartDate,  --'20060510',--YYYYMMDD
    @active_start_time = @StartTime,   --'180000', --(3:30 pm) 24hr HHMMSS.
    @active_end_date =   @EndDate,    --'20060515',
    @active_end_time =   @EndTime,    --'190000'
    @freq_recurrence_factor=1

    /*  @freq_type = 4 -> daily
                     1 -> Once
		     8 -> Weekly
		    16 -> Monthly
		    32 -> Monthly, relative to freq interval
     */

COMMIT TRANSACTION          
GOTO   EndSave              
EndSave: 
IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION 

END
