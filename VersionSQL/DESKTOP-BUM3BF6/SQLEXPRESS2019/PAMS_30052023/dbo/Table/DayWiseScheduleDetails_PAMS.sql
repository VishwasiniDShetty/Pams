/****** Object:  Table [dbo].[DayWiseScheduleDetails_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[DayWiseScheduleDetails_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[CustomerID] [nvarchar](50) NULL,
	[PartID] [nvarchar](50) NULL,
	[Year] [nvarchar](4) NULL,
	[MonthValue] [nvarchar](4) NULL,
	[WeekNumber] [int] NULL,
	[Date] [datetime] NULL,
	[PlannedQty] [float] NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL,
	[ReasonForBackLog] [nvarchar](2000) NULL
) ON [PRIMARY]

SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-20230311-124119] ON [dbo].[DayWiseScheduleDetails_PAMS]
(
	[CustomerID] ASC,
	[PartID] ASC,
	[Year] ASC,
	[MonthValue] ASC,
	[WeekNumber] ASC,
	[Date] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
ALTER TABLE [dbo].[DayWiseScheduleDetails_PAMS] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
