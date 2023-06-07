/****** Object:  Procedure [dbo].[SQLSerPath]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE PROCEDURE [dbo].[SQLSerPath] AS
DECLARE @data_dir varchar(500)
EXECUTE master.dbo.xp_instance_regread 'HKEY_LOCAL_MACHINE','SOFTWARE\Microsoft\MSSQLServer\Setup','SQLPath', @param = @data_dir OUTPUT
select @data_dir = @data_dir + '\BACKUP'
select @data_dir
DECLARE @path nvarchar(500)
select @path = 'mkdir' + ' "' + @data_dir + '"'
EXECUTE master.dbo.xp_cmdshell @path
