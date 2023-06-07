/****** Object:  Table [dbo].[ModuleScreenDetails_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ModuleScreenDetails_Pams](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[ModuleName] [nvarchar](100) NULL,
	[ModuleDisplayName] [nvarchar](100) NULL,
	[ScreenName] [nvarchar](100) NULL,
	[ScreenDisplayName] [nvarchar](100) NULL
) ON [PRIMARY]
