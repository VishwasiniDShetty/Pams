﻿/****** Object:  Table [dbo].[ReportTypeMaster_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ReportTypeMaster_PAMS](
	[RowID] [bigint] IDENTITY(1,1) NOT NULL,
	[ReportID] [int] NULL,
	[ReportType] [nvarchar](2000) NULL
) ON [PRIMARY]

SET ANSI_PADDING ON

CREATE UNIQUE CLUSTERED INDEX [ClusteredIndex-20221109-165555] ON [dbo].[ReportTypeMaster_PAMS]
(
	[ReportID] ASC,
	[ReportType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
