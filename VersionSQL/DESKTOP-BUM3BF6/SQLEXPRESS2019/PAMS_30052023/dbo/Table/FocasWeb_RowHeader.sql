/****** Object:  Table [dbo].[FocasWeb_RowHeader]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[FocasWeb_RowHeader](
	[RowID] [int] NULL,
	[RowHeader] [nvarchar](50) NULL,
	[Type] [nvarchar](50) NULL,
	[DisplayName] [nvarchar](50) NULL,
	[SortOrder] [int] NULL,
	[NavID] [nvarchar](50) NULL
) ON [PRIMARY]
