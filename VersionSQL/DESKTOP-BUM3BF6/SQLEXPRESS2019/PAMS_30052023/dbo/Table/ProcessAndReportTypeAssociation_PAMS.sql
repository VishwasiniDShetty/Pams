/****** Object:  Table [dbo].[ProcessAndReportTypeAssociation_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ProcessAndReportTypeAssociation_PAMS](
	[RowID] [bigint] IDENTITY(1,1) NOT NULL,
	[Process] [nvarchar](2000) NULL,
	[ReportType] [nvarchar](2000) NULL,
	[Checked] [int] NULL,
	[InspectionMethod] [nvarchar](100) NULL
) ON [PRIMARY]

SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-20221109-165202] ON [dbo].[ProcessAndReportTypeAssociation_PAMS]
(
	[Process] ASC,
	[ReportType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-20230124-091829] ON [dbo].[ProcessAndReportTypeAssociation_PAMS]
(
	[Process] ASC,
	[ReportType] ASC,
	[InspectionMethod] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
ALTER TABLE [dbo].[ProcessAndReportTypeAssociation_PAMS] ADD  DEFAULT ((0)) FOR [Checked]
