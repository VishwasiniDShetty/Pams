/****** Object:  Table [dbo].[MonthlyScheduleDetails_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[MonthlyScheduleDetails_Pams](
	[RowID] [bigint] IDENTITY(1,1) NOT NULL,
	[CustomerID] [nvarchar](50) NULL,
	[PartID] [nvarchar](50) NULL,
	[YearNo] [nvarchar](4) NULL,
	[MonthName] [nvarchar](50) NULL,
	[MonthVal] [nvarchar](4) NULL,
	[PlannedQty] [float] NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL
) ON [PRIMARY]

SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-20230311-182016] ON [dbo].[MonthlyScheduleDetails_Pams]
(
	[CustomerID] ASC,
	[PartID] ASC,
	[YearNo] ASC,
	[MonthName] ASC,
	[MonthVal] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
ALTER TABLE [dbo].[MonthlyScheduleDetails_Pams] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
