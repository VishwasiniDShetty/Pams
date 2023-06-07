/****** Object:  Table [dbo].[Autodata_MaxTime]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Autodata_MaxTime](
	[Machineid] [nvarchar](50) NOT NULL,
	[Starttime] [datetime] NULL,
	[Endtime] [datetime] NULL,
	[NPCy-TCS] [smalldatetime] NULL
) ON [PRIMARY]
