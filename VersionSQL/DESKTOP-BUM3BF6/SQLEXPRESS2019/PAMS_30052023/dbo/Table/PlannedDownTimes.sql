/****** Object:  Table [dbo].[PlannedDownTimes]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[PlannedDownTimes](
	[ID] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[StartTime] [datetime] NULL,
	[EndTime] [datetime] NULL,
	[Machine] [nvarchar](50) NULL,
	[DownReason] [nvarchar](50) NULL,
	[SDTsttime] [datetime] NULL,
	[PDTstatus] [nvarchar](1) NULL,
	[Ignorecount] [int] NULL,
	[DownType] [nvarchar](10) NULL,
	[DayName] [nvarchar](50) NULL,
	[ShiftName] [nvarchar](50) NULL,
	[ShiftStart] [datetime] NULL,
	[ShiftEnd] [datetime] NULL
) ON [PRIMARY]

CREATE UNIQUE CLUSTERED INDEX [IX_Slno] ON [dbo].[PlannedDownTimes]
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [IX_MachineStarttime] ON [dbo].[PlannedDownTimes]
(
	[Machine] ASC,
	[StartTime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
ALTER TABLE [dbo].[PlannedDownTimes] ADD  DEFAULT ((0)) FOR [Ignorecount]
