/****** Object:  Table [dbo].[Focas_info]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Focas_info](
	[MachineId] [nvarchar](1000) NOT NULL,
	[CNCData1] [nvarchar](1000) NULL,
	[LicType] [nvarchar](1000) NULL,
	[ExpDate] [datetime] NULL,
	[IsOEM] [bit] NULL
) ON [PRIMARY]
