/****** Object:  Table [dbo].[SpindleRuntimeDataInfo]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[SpindleRuntimeDataInfo](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[DataType] [int] NULL,
	[MachineID] [nvarchar](50) NULL,
	[Runtime] [float] NULL,
	[UpdatedTS] [datetime] NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[SpindleRuntimeDataInfo] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
