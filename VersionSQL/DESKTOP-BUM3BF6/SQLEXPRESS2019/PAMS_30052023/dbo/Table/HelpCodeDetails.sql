/****** Object:  Table [dbo].[HelpCodeDetails]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[HelpCodeDetails](
	[Plantid] [nvarchar](50) NULL,
	[Machineid] [nvarchar](50) NOT NULL,
	[DataType] [numeric](18, 0) NULL,
	[HelpCode] [nvarchar](50) NOT NULL,
	[Action1] [nvarchar](50) NULL,
	[Action2] [nvarchar](50) NULL,
	[StartTime] [datetime] NOT NULL,
	[EndTime] [datetime] NULL,
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[Remarks] [nvarchar](500) NULL
) ON [PRIMARY]

CREATE UNIQUE CLUSTERED INDEX [IX_ID] ON [dbo].[HelpCodeDetails]
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
