/****** Object:  Table [dbo].[ss_UserAccessDefault]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ss_UserAccessDefault](
	[Domain] [nvarchar](50) NOT NULL,
	[DisplayText] [nvarchar](50) NULL,
	[Code] [nvarchar](50) NULL,
	[Isvisible] [bit] NULL,
	[WebColumn] [nvarchar](50) NULL,
	[DomainName] [nvarchar](50) NULL
) ON [PRIMARY]
