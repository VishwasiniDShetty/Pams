/****** Object:  Table [dbo].[OnlinePPtranstlist]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[OnlinePPtranstlist](
	[Machineid] [nvarchar](50) NULL,
	[portno] [smallint] NULL,
	[StartTime] [smalldatetime] NULL,
	[Settings] [nvarchar](50) NULL,
	[Status] [nvarchar](25) NULL
) ON [PRIMARY]
