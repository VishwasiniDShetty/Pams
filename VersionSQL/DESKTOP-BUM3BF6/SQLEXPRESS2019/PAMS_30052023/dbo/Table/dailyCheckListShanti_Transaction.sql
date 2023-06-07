/****** Object:  Table [dbo].[dailyCheckListShanti_Transaction]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[dailyCheckListShanti_Transaction](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[MachineID] [nvarchar](50) NULL,
	[Activity] [int] NULL,
	[UpdatedTS] [datetime] NULL
) ON [PRIMARY]
