/****** Object:  Table [dbo].[HolidayShift]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[HolidayShift](
	[StartTime] [datetime] NULL,
	[EndTime] [datetime] NULL,
	[ShiftName] [nvarchar](50) NULL,
	[FromDay] [smallint] NULL,
	[ToDay] [smallint] NULL,
	[Shiftid] [nvarchar](20) NULL
) ON [PRIMARY]
