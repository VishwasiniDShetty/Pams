/****** Object:  Table [dbo].[PlannedDownListforLday]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[PlannedDownListforLday](
	[EffFrom] [datetime] NULL,
	[EffTo] [datetime] NULL,
	[FromTime] [datetime] NOT NULL,
	[ToTime] [datetime] NOT NULL,
	[Today] [int] NOT NULL,
	[Tommorrow] [int] NOT NULL,
	[DownReason] [nvarchar](50) NOT NULL,
	[MachineID] [nvarchar](50) NULL
) ON [PRIMARY]
