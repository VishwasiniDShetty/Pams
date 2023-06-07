/****** Object:  Table [dbo].[SD_BUFFERS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[SD_BUFFERS](
	[PortNo] [int] NULL,
	[Buffer] [nvarchar](4000) NULL,
	[Slno] [bigint] IDENTITY(1,1) NOT NULL,
	[MachineId] [nvarchar](50) NULL
) ON [PRIMARY]
