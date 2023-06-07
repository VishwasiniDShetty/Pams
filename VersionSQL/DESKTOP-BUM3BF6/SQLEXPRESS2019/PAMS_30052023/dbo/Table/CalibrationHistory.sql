/****** Object:  Table [dbo].[CalibrationHistory]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[CalibrationHistory](
	[GaugeId] [nvarchar](50) NOT NULL,
	[Serial number] [nvarchar](20) NOT NULL,
	[Calibration number] [bigint] NOT NULL,
	[CalibrationDueOn] [datetime] NOT NULL,
	[CalibrationDoneOn] [datetime] NOT NULL
) ON [PRIMARY]
