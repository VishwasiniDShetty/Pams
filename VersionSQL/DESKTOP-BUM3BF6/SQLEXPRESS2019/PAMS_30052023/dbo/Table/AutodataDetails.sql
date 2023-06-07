/****** Object:  Table [dbo].[AutodataDetails]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[AutodataDetails](
	[Machine] [nvarchar](50) NULL,
	[RecordType] [numeric](18, 0) NULL,
	[Starttime] [datetime] NULL,
	[Endtime] [datetime] NULL,
	[DetailNumber] [numeric](18, 0) NULL,
	[ID] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[CompInterfaceID] [nvarchar](4) NULL,
	[OpnInterfaceID] [nvarchar](4) NULL,
	[SequenceNo] [nvarchar](50) NULL,
	[ToolActual] [int] NULL,
	[ToolTarget] [int] NULL
) ON [PRIMARY]

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON




/* 
 Shilpa to introduce trigger on autodatadetails table for 
insertion of dummy record into the table .
Mod 1:- altered by Mrudula for DR0158 on 05-jan-2008. The following error comes on insertion of record 
	in autodatadetails whoose record type is not 12 . Cannot insert the value NULL into 
	 column 'Machineid', table 'TPM.dbo.Autodata_MaxTime'; column does not allow nulls. 
	INSERT fails.The statement has been terminated. 
	This is because autodata_maxtime does not allow null values. Select statement in trigger will
	 return null if the recordtype is not 12 . Check for this condition also.

*/
/* NR0049:10-Nov-08 */
CREATE         TRIGGER [dbo].[tr_autodata_DummyRecords] ON [dbo].[AutodataDetails]

after insert 
	AS
		Declare @Machineid as nvarchar(50)
		Declare @Starttime as datetime
		Declare @Error as int
		declare @count as int
	
		
	BEGIN
	
	Select @Machineid=machine,@Starttime=Starttime from inserted where recordtype=12
	
	update autodata_maxtime set [Npcy-tcs]=@Starttime  
	where machineid=@machineid
	    
		set @count=@@rowcount
		Set @Error=@@Error
		If @Error <> 0 goto Err_Handler
		--mod 1
		---If @count=0
		if (@Machineid is not null) and  @count=0
		--mod 1
		begin
		   Insert into autodata_maxtime(machineid,[Npcy-tcs]) values(@Machineid,@Starttime)
		   set @count=@@rowcount
		End
		
	return
	Err_Handler:
	If @@trancount<> 0 rollback transaction
	return
	 
	END









ALTER TABLE [dbo].[AutodataDetails] ENABLE TRIGGER [tr_autodata_DummyRecords]
