/****** Object:  Table [dbo].[DatabaseVersion]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[DatabaseVersion](
	[ScriptName] [nvarchar](100) NOT NULL,
	[ScriptDate] [datetime] NOT NULL,
	[DbVersionNumber] [nvarchar](50) NOT NULL,
	[SoftwareVersionNumber] [nvarchar](50) NULL,
	[Slno] [int] IDENTITY(1,1) NOT NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[DatabaseVersion] ADD  CONSTRAINT [DF_DatabaseVersion_ScriptDate]  DEFAULT (getdate()) FOR [ScriptDate]
