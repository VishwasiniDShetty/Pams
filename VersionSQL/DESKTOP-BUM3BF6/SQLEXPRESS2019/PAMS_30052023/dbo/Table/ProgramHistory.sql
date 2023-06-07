/****** Object:  Table [dbo].[ProgramHistory]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ProgramHistory](
	[SlNo] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[RequestedDateTime] [datetime] NULL,
	[MachineID] [nvarchar](10) NULL,
	[ProgramID] [nvarchar](10) NULL,
	[PortNo] [int] NULL,
	[ServiceProvided] [smallint] NULL,
	[ServiceDateTime] [datetime] NULL,
	[RequestingModuleName] [nvarchar](50) NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[ProgramHistory] ADD  CONSTRAINT [DF_ProgramHistory_RequestedDateTimeS]  DEFAULT (getdate()) FOR [RequestedDateTime]
ALTER TABLE [dbo].[ProgramHistory] ADD  CONSTRAINT [DF_ProgramHistory_PortNoS]  DEFAULT ((0)) FOR [PortNo]
ALTER TABLE [dbo].[ProgramHistory] ADD  CONSTRAINT [DF_ProgramHistory_ServiceProvidedS]  DEFAULT ((0)) FOR [ServiceProvided]
