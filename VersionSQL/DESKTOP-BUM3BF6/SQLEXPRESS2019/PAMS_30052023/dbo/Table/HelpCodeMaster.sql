/****** Object:  Table [dbo].[HelpCodeMaster]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[HelpCodeMaster](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[Help_Code] [nvarchar](50) NULL,
	[Help_Description] [nvarchar](50) NULL
) ON [PRIMARY]
