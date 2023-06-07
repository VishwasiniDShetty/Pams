/****** Object:  Table [dbo].[UserRoleRights_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[UserRoleRights_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[Role] [nvarchar](50) NULL,
	[ModuleName] [nvarchar](100) NULL,
	[ScreenName] [nvarchar](100) NULL,
	[AccessType] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[UserRoleRights_PAMS] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
