/****** Object:  Table [dbo].[FolderPathDefinition]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[FolderPathDefinition](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[FolderType] [nvarchar](50) NULL,
	[FolderPath] [nvarchar](4000) NULL,
	[FileExtension] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
