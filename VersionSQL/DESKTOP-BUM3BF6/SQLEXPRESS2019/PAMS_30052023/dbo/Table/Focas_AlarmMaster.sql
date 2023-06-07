/****** Object:  Table [dbo].[Focas_AlarmMaster]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Focas_AlarmMaster](
	[Slno] [int] NULL,
	[AlarmNo] [bigint] NULL,
	[Flag] [smallint] NULL,
	[FilePath] [nvarchar](max) NULL,
	[Description] [nvarchar](max) NULL,
	[Cause] [nvarchar](max) NULL,
	[Solution] [nvarchar](max) NULL,
	[MTB] [nvarchar](50) NULL,
	[AddressTag] [nvarchar](100) NULL,
	[AlarmAddress] [nvarchar](50) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
