/****** Object:  Table [dbo].[ValidationDetails_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ValidationDetails_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[DisplayText] [nvarchar](max) NULL,
	[DisplayType] [nvarchar](50) NULL,
	[SortOrder] [int] NULL,
	[Flag] [bit] NULL,
	[Parameter] [nvarchar](50) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

ALTER TABLE [dbo].[ValidationDetails_PAMS] ADD  DEFAULT ((0)) FOR [Flag]
