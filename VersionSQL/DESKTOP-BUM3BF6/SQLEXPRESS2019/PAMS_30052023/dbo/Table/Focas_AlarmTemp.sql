/****** Object:  Table [dbo].[Focas_AlarmTemp]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Focas_AlarmTemp](
	[AlarmNo] [bigint] NULL,
	[AlarmGroupNo] [bigint] NULL,
	[AlarmMSG] [nvarchar](250) NULL,
	[AlarmAxisNo] [bigint] NULL,
	[AlarmTotAxisNo] [bigint] NULL,
	[AlarmGCode] [nvarchar](500) NULL,
	[AlarmOtherCode] [nvarchar](500) NULL,
	[AlarmMPos] [nvarchar](500) NULL,
	[AlarmAPos] [nvarchar](500) NULL,
	[AlarmTime] [datetime] NULL,
	[MachineId] [nvarchar](50) NULL
) ON [PRIMARY]
