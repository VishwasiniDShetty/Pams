/****** Object:  Table [dbo].[ActivityMaster_MGTL]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ActivityMaster_MGTL](
	[ActivityID] [int] IDENTITY(1,1) NOT NULL,
	[Activity] [nvarchar](100) NULL,
	[FreqID] [int] NULL,
	[Filename] [nvarchar](200) NULL,
	[FSUnique] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	[ActivityFile] [varbinary](max) FILESTREAM  NULL,
	[MachineID] [nvarchar](50) NULL,
UNIQUE NONCLUSTERED 
(
	[FSUnique] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] FILESTREAM_ON [FILESTREAM_grp]

ALTER TABLE [dbo].[ActivityMaster_MGTL] ADD  DEFAULT (newid()) FOR [FSUnique]
