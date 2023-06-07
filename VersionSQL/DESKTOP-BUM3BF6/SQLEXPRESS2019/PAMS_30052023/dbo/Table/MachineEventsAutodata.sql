/****** Object:  Table [dbo].[MachineEventsAutodata]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[MachineEventsAutodata](
	[RecordType] [nvarchar](50) NULL,
	[MachineInterface] [nvarchar](50) NULL,
	[Sttime] [datetime] NULL,
	[EventID] [nvarchar](50) NULL,
	[Starttime] [datetime] NULL,
	[Endtime] [datetime] NULL,
	[ID] [bigint] IDENTITY(1,1) NOT NULL
) ON [PRIMARY]
