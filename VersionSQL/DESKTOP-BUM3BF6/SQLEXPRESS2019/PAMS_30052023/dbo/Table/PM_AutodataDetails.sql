/****** Object:  Table [dbo].[PM_AutodataDetails]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[PM_AutodataDetails](
	[Machine] [nvarchar](50) NULL,
	[RecordType] [numeric](18, 0) NULL,
	[Starttime] [datetime] NULL,
	[Endtime] [datetime] NULL,
	[SelectionCode] [numeric](18, 0) NULL,
	[ID] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[MainCategory] [nvarchar](4) NULL,
	[SubCategory] [nvarchar](4) NULL,
	[OprInterfaceID] [nvarchar](50) NULL,
	[Target] [int] NULL,
	[Actual] [int] NULL,
	[Reason] [nvarchar](50) NULL
) ON [PRIMARY]
