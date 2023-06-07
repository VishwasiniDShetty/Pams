/****** Object:  Table [dbo].[TempPlannedDownTimes]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[TempPlannedDownTimes](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
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
