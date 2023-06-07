/****** Object:  Table [dbo].[SmartAgentActions]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[SmartAgentActions](
	[LogFile] [nvarchar](200) NULL,
	[SmtpServer] [nvarchar](100) NULL,
	[SmtpPortNo] [nvarchar](50) NULL,
	[UserId] [nvarchar](100) NULL,
	[Pwd] [nvarchar](100) NULL,
	[SMSPortNO] [nvarchar](50) NULL,
	[SMSSettings] [nvarchar](50) NULL,
	[PIPortNO] [nvarchar](50) NULL,
	[PISettings] [nvarchar](50) NULL,
	[SmartAgentSW_TimerInterval] [int] NULL,
	[SmartAgentUD_TimerInterval] [int] NULL,
	[UDT_ReadDelay] [smallint] NULL,
	[LampColor_If_NoData] [smallint] NULL,
	[Combine_GsmMsg_Y_N] [bit] NULL,
	[ResendMinutes] [int] NULL,
	[HostName] [nvarchar](50) NULL,
	[NextRunTime_Hourly] [datetime] NULL,
	[MinuteMessage] [nvarchar](50) NULL,
	[MinMsgVal] [int] NULL,
	[SMSFlowControl] [nvarchar](50) NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[SmartAgentActions] ADD  CONSTRAINT [DF_SmartAgentActions_UDT_ReadDelay]  DEFAULT ((0)) FOR [UDT_ReadDelay]
ALTER TABLE [dbo].[SmartAgentActions] ADD  CONSTRAINT [DF_SmartAgentActions_LampColor_If_NoData]  DEFAULT ((0)) FOR [LampColor_If_NoData]
ALTER TABLE [dbo].[SmartAgentActions] ADD  CONSTRAINT [DF_SmartAgentActions_Combine_GsmMsg_Y_N]  DEFAULT ((0)) FOR [Combine_GsmMsg_Y_N]
ALTER TABLE [dbo].[SmartAgentActions] ADD  CONSTRAINT [AddResendMinutes]  DEFAULT ((120)) FOR [ResendMinutes]
