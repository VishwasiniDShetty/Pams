/****** Object:  Table [dbo].[AlarmLastSyncDateTime]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[AlarmLastSyncDateTime](
	[MachineID] [nvarchar](50) NULL,
	[AlarmLastSyncTime] [datetime] NULL,
	[PreventiveLastSyncTime] [datetime] NULL,
	[PredictiveLastSyncTime] [datetime] NULL
) ON [PRIMARY]
