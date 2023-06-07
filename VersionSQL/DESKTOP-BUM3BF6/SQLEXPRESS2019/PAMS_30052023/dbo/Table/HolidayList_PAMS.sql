/****** Object:  Table [dbo].[HolidayList_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[HolidayList_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[Holiday] [datetime] NULL,
	[HolidayReason] [nvarchar](100) NULL
) ON [PRIMARY]
