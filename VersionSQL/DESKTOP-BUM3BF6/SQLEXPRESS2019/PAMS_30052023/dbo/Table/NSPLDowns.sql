/****** Object:  Table [dbo].[NSPLDowns]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[NSPLDowns](
	[EffFrom] [datetime] NULL,
	[EffTo] [datetime] NULL,
	[FromTime] [datetime] NULL,
	[ToTime] [datetime] NULL,
	[Today] [bit] NULL,
	[Tommorrow] [bit] NULL,
	[DownReason] [nvarchar](50) NULL,
	[Flag] [int] NULL
) ON [PRIMARY]
