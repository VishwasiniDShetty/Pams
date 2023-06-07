/****** Object:  Table [dbo].[Service_Status]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Service_Status](
	[RequestType] [varchar](10) NULL,
	[Running] [tinyint] NOT NULL,
	[StartMc] [nvarchar](10) NULL,
	[StopMc] [nvarchar](10) NULL,
	[StartAll] [nvarchar](10) NULL,
	[StopAll] [nvarchar](10) NULL,
	[Application] [nvarchar](25) NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[Service_Status] ADD  CONSTRAINT [DF_Service_Status_Running]  DEFAULT ((0)) FOR [Running]
