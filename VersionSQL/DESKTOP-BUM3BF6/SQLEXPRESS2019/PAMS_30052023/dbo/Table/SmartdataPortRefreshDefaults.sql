/****** Object:  Table [dbo].[SmartdataPortRefreshDefaults]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[SmartdataPortRefreshDefaults](
	[ID] [decimal](18, 0) IDENTITY(1,1) NOT NULL,
	[port_refresh_interval_1] [decimal](18, 0) NULL,
	[port_refresh_interval_2] [decimal](18, 0) NULL,
	[port_refresh_interval_3] [decimal](18, 0) NULL,
	[port_refresh_minute_1] [varchar](50) NULL,
	[port_refresh_minute_2] [varchar](50) NULL,
	[port_refresh_minute_3] [varchar](50) NULL,
	[port_refresh_minute_4] [varchar](50) NULL,
	[wait_after_open] [varchar](1) NULL,
	[wait_after_close] [varchar](1) NULL,
	[CheckDupRec] [smallint] NULL,
	[errorprogramnumber] [nvarchar](20) NOT NULL,
	[waitforprogramsendtimer] [int] NOT NULL,
	[RunFromScript] [nvarchar](4) NULL,
	[SplitPalletRecord] [varchar](1) NULL,
	[SupportsICDnDowns] [varchar](1) NULL,
	[TPMStrings_Y_N] [varchar](1) NULL,
	[SDrestart1] [datetime] NULL,
	[SDrestart2] [datetime] NULL,
	[SDsleep] [tinyint] NULL,
	[SDautorestart] [bit] NULL,
	[SDDeviceRestart] [bit] NULL,
	[SDDeviceRestart_freq] [int] NULL,
	[SDHost] [nvarchar](50) NULL,
	[GroupSeperator1] [nvarchar](2) NULL,
	[GroupSeperator2] [nvarchar](2) NULL,
	[OperatorGrouping] [varchar](1) NULL,
	[STCSRestart1] [datetime] NULL,
	[STCSRestart2] [datetime] NULL,
	[WorkOrder] [nvarchar](1) NOT NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[SmartdataPortRefreshDefaults] ADD  DEFAULT ((60000)) FOR [port_refresh_interval_1]
ALTER TABLE [dbo].[SmartdataPortRefreshDefaults] ADD  DEFAULT ((10000)) FOR [port_refresh_interval_2]
ALTER TABLE [dbo].[SmartdataPortRefreshDefaults] ADD  DEFAULT ((1000)) FOR [port_refresh_interval_3]
ALTER TABLE [dbo].[SmartdataPortRefreshDefaults] ADD  DEFAULT ('no') FOR [port_refresh_minute_1]
ALTER TABLE [dbo].[SmartdataPortRefreshDefaults] ADD  DEFAULT ('no') FOR [port_refresh_minute_2]
ALTER TABLE [dbo].[SmartdataPortRefreshDefaults] ADD  DEFAULT ((30)) FOR [port_refresh_minute_3]
ALTER TABLE [dbo].[SmartdataPortRefreshDefaults] ADD  DEFAULT ((0)) FOR [port_refresh_minute_4]
ALTER TABLE [dbo].[SmartdataPortRefreshDefaults] ADD  DEFAULT ('y') FOR [wait_after_open]
ALTER TABLE [dbo].[SmartdataPortRefreshDefaults] ADD  DEFAULT ('y') FOR [wait_after_close]
ALTER TABLE [dbo].[SmartdataPortRefreshDefaults] ADD  DEFAULT ((0)) FOR [CheckDupRec]
ALTER TABLE [dbo].[SmartdataPortRefreshDefaults] ADD  DEFAULT ((9999)) FOR [errorprogramnumber]
ALTER TABLE [dbo].[SmartdataPortRefreshDefaults] ADD  DEFAULT ((10000)) FOR [waitforprogramsendtimer]
ALTER TABLE [dbo].[SmartdataPortRefreshDefaults] ADD  CONSTRAINT [DF_SmartdataPortRefreshDefaults_SplitPalletRecord]  DEFAULT ('y') FOR [SplitPalletRecord]
ALTER TABLE [dbo].[SmartdataPortRefreshDefaults] ADD  CONSTRAINT [DF_SmartdataPortRefreshDefaults_SupportsICDnDowns]  DEFAULT ('y') FOR [SupportsICDnDowns]
ALTER TABLE [dbo].[SmartdataPortRefreshDefaults] ADD  DEFAULT ('Pcthost') FOR [SDHost]
ALTER TABLE [dbo].[SmartdataPortRefreshDefaults] ADD  DEFAULT (':') FOR [GroupSeperator1]
ALTER TABLE [dbo].[SmartdataPortRefreshDefaults] ADD  DEFAULT ('/') FOR [GroupSeperator2]
ALTER TABLE [dbo].[SmartdataPortRefreshDefaults] ADD  DEFAULT ('N') FOR [OperatorGrouping]
ALTER TABLE [dbo].[SmartdataPortRefreshDefaults] ADD  DEFAULT ('N') FOR [WorkOrder]
