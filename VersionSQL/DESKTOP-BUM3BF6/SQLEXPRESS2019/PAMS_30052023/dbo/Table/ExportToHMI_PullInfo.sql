/****** Object:  Table [dbo].[ExportToHMI_PullInfo]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ExportToHMI_PullInfo](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[MachineID] [nvarchar](50) NOT NULL,
	[RequestType] [smallint] NOT NULL,
	[RequestedTimeStamp] [datetime] NOT NULL,
	[Status] [smallint] NOT NULL,
	[ServicedTimeStamp] [datetime] NULL,
	[ComponentID] [nvarchar](50) NULL,
	[OperationNo] [nvarchar](50) NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[ExportToHMI_PullInfo] ADD  CONSTRAINT [DF_ExportToHMI_PullInfo_RequestType]  DEFAULT ((1)) FOR [RequestType]
ALTER TABLE [dbo].[ExportToHMI_PullInfo] ADD  CONSTRAINT [DF_ExportToHMI_PullInfo_RequestedTimeStamp]  DEFAULT (getdate()) FOR [RequestedTimeStamp]
ALTER TABLE [dbo].[ExportToHMI_PullInfo] ADD  CONSTRAINT [DF_ExportToHMI_PullInfo_Status]  DEFAULT ((0)) FOR [Status]
