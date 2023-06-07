/****** Object:  Table [dbo].[ProcessedDocuments]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ProcessedDocuments](
	[WoNumber] [int] NULL,
	[MachineID] [nvarchar](50) NULL,
	[Part] [nvarchar](50) NULL,
	[Operation] [nvarchar](50) NULL,
	[Status] [nvarchar](50) NULL,
	[ProcessedDocs] [nvarchar](50) NULL
) ON [PRIMARY]
