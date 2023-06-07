/****** Object:  Table [dbo].[OperationDefinition]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[OperationDefinition](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[IconPath] [nvarchar](4000) NOT NULL,
	[DocType] [nvarchar](50) NULL
) ON [PRIMARY]
