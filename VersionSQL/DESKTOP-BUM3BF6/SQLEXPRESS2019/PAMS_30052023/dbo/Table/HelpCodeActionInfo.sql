/****** Object:  Table [dbo].[HelpCodeActionInfo]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[HelpCodeActionInfo](
	[ActionNo] [nvarchar](10) NULL,
	[Action] [nvarchar](50) NULL,
	[Description] [nvarchar](50) NULL,
	[id] [bigint] IDENTITY(1,1) NOT NULL
) ON [PRIMARY]
