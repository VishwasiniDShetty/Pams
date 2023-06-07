/****** Object:  Table [dbo].[FinalInspectionTransaction_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[FinalInspectionTransaction_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[Process] [nvarchar](2000) NULL,
	[ReportType] [nvarchar](50) NULL,
	[ProcessType] [nvarchar](50) NULL,
	[MaterialID] [nvarchar](50) NULL,
	[InvoiceNumber] [nvarchar](50) NULL,
	[GRNNo] [nvarchar](50) NULL,
	[Status] [nvarchar](50) NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL
) ON [PRIMARY]

SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-20230311-124950] ON [dbo].[FinalInspectionTransaction_PAMS]
(
	[Process] ASC,
	[ReportType] ASC,
	[ProcessType] ASC,
	[MaterialID] ASC,
	[InvoiceNumber] ASC,
	[GRNNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
