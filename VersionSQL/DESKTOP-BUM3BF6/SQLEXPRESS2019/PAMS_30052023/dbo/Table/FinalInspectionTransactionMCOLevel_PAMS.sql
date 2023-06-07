/****** Object:  Table [dbo].[FinalInspectionTransactionMCOLevel_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[FinalInspectionTransactionMCOLevel_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[Date] [datetime] NULL,
	[Shift] [nvarchar](50) NULL,
	[Process] [nvarchar](2000) NULL,
	[ReportType] [nvarchar](50) NULL,
	[ProcessType] [nvarchar](50) NULL,
	[Machine] [nvarchar](50) NULL,
	[ComponentID] [nvarchar](50) NULL,
	[OperationNo] [nvarchar](50) NULL,
	[Status] [nvarchar](50) NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL,
	[PJCNo] [nvarchar](50) NULL,
	[PJCYear] [nvarchar](10) NULL
) ON [PRIMARY]

SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-20230311-125505] ON [dbo].[FinalInspectionTransactionMCOLevel_PAMS]
(
	[Date] ASC,
	[Shift] ASC,
	[Process] ASC,
	[ReportType] ASC,
	[ProcessType] ASC,
	[Machine] ASC,
	[ComponentID] ASC,
	[OperationNo] ASC,
	[PJCNo] ASC,
	[PJCYear] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
