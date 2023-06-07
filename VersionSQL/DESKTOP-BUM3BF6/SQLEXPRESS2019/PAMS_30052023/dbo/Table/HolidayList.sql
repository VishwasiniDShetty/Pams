/****** Object:  Table [dbo].[HolidayList]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[HolidayList](
	[Holiday] [datetime] NOT NULL,
	[Reason] [nvarchar](50) NOT NULL,
	[MachineID] [nvarchar](50) NULL
) ON [PRIMARY]
