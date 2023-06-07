/****** Object:  Table [dbo].[autodata]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[autodata](
	[mc] [nvarchar](50) NULL,
	[comp] [nvarchar](50) NULL,
	[opn] [nvarchar](50) NULL,
	[opr] [nvarchar](50) NULL,
	[dcode] [nvarchar](50) NULL,
	[stdate] [datetime] NULL,
	[sttime] [datetime] NULL,
	[nddate] [datetime] NULL,
	[ndtime] [datetime] NULL,
	[datatype] [tinyint] NULL,
	[cycletime] [int] NULL,
	[loadunload] [int] NULL,
	[compslno] [int] NULL,
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[Remarks] [nvarchar](255) NULL,
	[post] [smallint] NULL,
	[msttime] [datetime] NULL,
	[PartsCount] [decimal](18, 5) NULL,
	[WorkOrderNumber] [nvarchar](50) NOT NULL,
	[PJCYear] [nvarchar](10) NULL,
 CONSTRAINT [PK_autodata1] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [IX_MCSTTIME] ON [dbo].[autodata]
(
	[mc] ASC,
	[sttime] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
ALTER TABLE [dbo].[autodata] ADD  CONSTRAINT [DF_autodata1_datatype]  DEFAULT ((0)) FOR [datatype]
ALTER TABLE [dbo].[autodata] ADD  CONSTRAINT [DF_autodata1_loadunload]  DEFAULT ((0)) FOR [loadunload]
ALTER TABLE [dbo].[autodata] ADD  CONSTRAINT [DF_autodata1_compslno]  DEFAULT ((0)) FOR [compslno]
ALTER TABLE [dbo].[autodata] ADD  CONSTRAINT [DF_autodata1_post]  DEFAULT ((0)) FOR [post]
ALTER TABLE [dbo].[autodata] ADD  CONSTRAINT [DF_AutoData1_PartsCount123]  DEFAULT ((0)) FOR [PartsCount]
ALTER TABLE [dbo].[autodata] ADD  DEFAULT ('0') FOR [WorkOrderNumber]
SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON


/**************************************************************************************
Shilpa to introduce trigger on autodata for
insert
dISABLING TRIGGER ON UPDATE. ER0102:01-Jan-08
mod 1:- by Mrudula M. Rao on 020-apr-2009 for DR0180
	(1) update the trigger on autodata(used to update autodata_maxtime) so that it updates
	autodata_maxtime only if the inserted record is of datatype 1 and 2
	2)Update the autodata_maxtime table only if the endtime in autodata_maxtime is less than the endtime of the record that is inserted in autodata.
***************************************************************************************/
CREATE        TRIGGER [dbo].[tr_autodata_maxtime] ON
[dbo].[autodata]
after insert
AS
Declare @Machineid as nvarchar(50)
	--Declare @Datatype as tinyint
	Declare @Starttime as datetime
	Declare @Endtime as datetime
	Declare @Error as int
	declare @count as int
	
BEGIN
	---mod 1(1)
	if  isnull((select mc from inserted Where datatype in (1,2)),'') <> ''
	BEGIN
	--mod 1(1)
		Select @Machineid=mc,@Starttime=sttime,@Endtime=ndtime from inserted
		---mod 1(1) select if datatype is 1 or 2
		Where datatype in (1,2)
		--mod 1(1)
		
		update autodata_maxtime set
		starttime=sttime,Endtime=ndtime from inserted
		where machineid=@machineid
		---mod 1(2)
		and Endtime<=ndtime
		---mod 1(2)
	
		set @count=@@rowcount
		Set @Error=@@Error
	
		If @Error <> 0 goto Err_Handler
		
		--mod 1(2)
		--If @count=0
		If @count=0 and (select count(*) from autodata_maxtime where  machineid=@machineid)= 0
		--mod 1(2)
		Begin
			Insert into autodata_maxtime (machineid,Starttime,Endtime)
			values(@Machineid,@Starttime,@Endtime)
			set @count=@@rowcount
		End
	END --mod 1(1)
	
--If @Error <> 0 goto Err_Handler
return
Err_Handler:
If @@trancount<> 0 rollback transaction
return
END


ALTER TABLE [dbo].[autodata] ENABLE TRIGGER [tr_autodata_maxtime]
