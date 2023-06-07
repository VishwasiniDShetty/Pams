/****** Object:  Table [dbo].[MachineOnlineStatus]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[MachineOnlineStatus](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[MachineID] [nvarchar](50) NOT NULL,
	[LastDataArrivalTime] [datetime] NULL,
	[LastConnectionOKTime] [datetime] NULL,
	[LastConnectionFailedTime] [datetime] NULL,
	[LastPingOkTime] [datetime] NULL,
	[LastPingFailedTime] [datetime] NULL,
	[Remarks] [nvarchar](4000) NULL,
	[UpdatedTS] [datetime] NOT NULL,
	[LastPLCCommunicationOK] [datetime] NULL,
	[LastPLCCommunicationFailed] [datetime] NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[MachineOnlineStatus] ADD  CONSTRAINT [DF_MachineOnlineStatus_UpdatedTS]  DEFAULT (getdate()) FOR [UpdatedTS]
