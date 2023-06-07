/****** Object:  Table [dbo].[FinalInspectionTransactionFG_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[FinalInspectionTransactionFG_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[Process] [nvarchar](2000) NULL,
	[ReportType] [nvarchar](50) NULL,
	[ProcessType] [nvarchar](50) NULL,
	[ComponentID] [nvarchar](50) NULL,
	[PJCNo] [nvarchar](50) NULL,
	[PJCYear] [nvarchar](50) NULL,
	[Status] [nvarchar](50) NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL,
	[Pams_DCNo] [nvarchar](50) NULL,
	[VendorDCNo] [nvarchar](50) NULL,
	[MJCNo] [nvarchar](50) NULL
) ON [PRIMARY]

SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-20230311-125122] ON [dbo].[FinalInspectionTransactionFG_PAMS]
(
	[Process] ASC,
	[ReportType] ASC,
	[ProcessType] ASC,
	[ComponentID] ASC,
	[PJCNo] ASC,
	[PJCYear] ASC,
	[Pams_DCNo] ASC,
	[VendorDCNo] ASC,
	[MJCNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
