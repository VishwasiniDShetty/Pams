/****** Object:  Table [dbo].[SD_BUFFERS_PTrans]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[SD_BUFFERS_PTrans](
	[PortNo] [int] NULL,
	[Buffer] [varchar](8000) NULL,
	[Slno] [bigint] IDENTITY(1,1) NOT NULL
) ON [PRIMARY]
