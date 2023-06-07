/****** Object:  Table [dbo].[CompanywiseScreenAssignment]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[CompanywiseScreenAssignment](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[ScreenName] [nvarchar](100) NULL,
	[isEnable] [bit] NULL,
	[ScreenCode] [nvarchar](100) NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[CompanywiseScreenAssignment] ADD  DEFAULT ((1)) FOR [isEnable]
