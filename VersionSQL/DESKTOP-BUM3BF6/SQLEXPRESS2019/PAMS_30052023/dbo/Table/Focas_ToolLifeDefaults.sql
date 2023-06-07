/****** Object:  Table [dbo].[Focas_ToolLifeDefaults]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Focas_ToolLifeDefaults](
	[SlNo] [bigint] IDENTITY(1,1) NOT NULL,
	[GroupNumber] [nvarchar](100) NULL,
	[ToolNumber] [nvarchar](100) NULL,
	[DAreaForToolNumberLife] [smallint] NULL,
	[DAreaForToolNumberCount] [smallint] NULL,
	[DAreaForToolLife] [smallint] NULL,
	[DAreaForCount] [smallint] NULL,
	[DareaforReason] [smallint] NULL,
	[DareaforFlagsetting] [smallint] NULL,
	[MacrovariableforDate] [smallint] NULL,
	[Macrovariablefortime] [smallint] NULL,
	[MTB] [nvarchar](50) NULL
) ON [PRIMARY]
