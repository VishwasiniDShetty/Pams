/****** Object:  Table [dbo].[ProcessedDocs]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ProcessedDocs](
	[MONumber] [nvarchar](50) NULL,
	[MachineId] [nvarchar](50) NULL,
	[ComponentId] [nvarchar](50) NULL,
	[Operation] [nvarchar](50) NULL,
	[Documents] [nvarchar](max) NULL,
	[flag] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
