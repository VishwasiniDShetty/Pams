/****** Object:  Table [dbo].[GaugeMovementStatus]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[GaugeMovementStatus](
	[GaugeId] [nvarchar](50) NOT NULL,
	[GaugeSlno] [nvarchar](50) NOT NULL,
	[Status] [nvarchar](50) NULL,
	[ProcessDate] [datetime] NULL,
	[Contact] [nvarchar](50) NULL,
	[Slno] [bigint] IDENTITY(1,1) NOT NULL
) ON [PRIMARY]
