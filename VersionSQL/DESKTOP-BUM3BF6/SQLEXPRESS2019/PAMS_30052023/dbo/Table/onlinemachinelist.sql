/****** Object:  Table [dbo].[onlinemachinelist]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[onlinemachinelist](
	[machineid] [nvarchar](50) NOT NULL,
	[portno] [smallint] NULL,
	[StartTime] [smalldatetime] NULL,
	[Settings] [nvarchar](50) NULL,
	[Status] [nvarchar](25) NULL,
 CONSTRAINT [PK_onlinemachinelist] PRIMARY KEY CLUSTERED 
(
	[machineid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[onlinemachinelist] ADD  CONSTRAINT [DF_onlinemachinelist_portno]  DEFAULT ((0)) FOR [portno]
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON





/* 

 by Shilpa to introduce trigger on onlinemachinelist for insert and delete*/
/* ER0102:01-Jan-08 */
CREATE       TRIGGER [dbo].[tr_OnlineMachineList] ON [dbo].[onlinemachinelist]
instead of delete
AS
	DECLARE @MachineID AS NVarChar(50)
	Declare @num as int
	declare @LogApp as nvarchar(50)
	declare @LogUser as nvarchar(50)
	declare @host as nvarchar(50)
	
	
BEGIN
	--SET @count=@@rowcount
	SET @LogApp=app_name()
	set @LogUser=host_name()
	select @host=SDHost from SmartdataPortRefreshDefaults
	If @host<>@LogUser and @host<> 'PCTHOST'
	 begin
	    --print 'delete request from other pc'
	    print @host
	    insert into tpmtraklog(Modulename,Username,Logdate,Remarks) Values('trying to delete,Access denied',@LogUser,Getdate(),@LogApp +  ' while delete')
	    return
         end	
        
	select @num=count(*) from deleted
	IF(@num=1)
	BEGIN
	 --print 'delete a single machine'
	 select @MachineID=machineid from deleted
	 delete from onlinemachinelist where machineid=@MachineID
	 insert into tpmtraklog(Modulename,Username,Logdate,Remarks) Values(@MachineID,@LogUser,Getdate(),@LogApp +  ' while delete')	
        end		
	else		
        begin
	--print 'delete all machines'
	 insert Into TPMTrakLog(ModuleName,Username,LogDate,Remarks) Values('Request to delete all machines',@LogUser,GetDate(),@LogApp + ' while deletion')	       
        -- delete from onlinemachinelist
	 end
		

END











ALTER TABLE [dbo].[onlinemachinelist] ENABLE TRIGGER [tr_OnlineMachineList]
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON






/* 
 Shilpa to introduce trigger on onlinemachinelist for insert and delete*/
/* ER0102:01-Jan-08 */
create    TRIGGER [dbo].[tr_OnlineMachineList_insert] ON [dbo].[onlinemachinelist]
after insert,update
AS
	DECLARE @MachineID AS NVarChar(50)
	DECLARE @count AS int
	Declare @num as int
	declare @LogApp as nvarchar(50)
	declare @LogUser as nvarchar(50)
declare @host as nvarchar(50)
	
BEGIN
	SET @count=@@rowcount
	SET @LogApp=app_name()
	set @LogUser=host_name()

	
	IF(@count=1)
	BEGIN
		select @MachineID=machineid from inserted
		begin
		     --print 'insert'
		     insert into tpmtraklog(modulename,Username,logdate,remarks) values(@machineid,@LogUser,Getdate(),@LogApp + ' while insertion')
		end
	END
		ELSE
	IF(@count>1)
	BEGIN
		
		--print 'insert all'
		insert into tpmtraklog(Modulename,Username,Logdate,remarks) values('all machines are online',@LogUser,Getdate(),@LogApp + ' while insertion')
		
	END
END







ALTER TABLE [dbo].[onlinemachinelist] ENABLE TRIGGER [tr_OnlineMachineList_insert]
