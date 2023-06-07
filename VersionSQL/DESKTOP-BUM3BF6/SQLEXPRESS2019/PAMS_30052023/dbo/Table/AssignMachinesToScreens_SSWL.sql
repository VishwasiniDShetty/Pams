/****** Object:  Table [dbo].[AssignMachinesToScreens_SSWL]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[AssignMachinesToScreens_SSWL](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[UserID] [nvarchar](50) NULL,
	[ScreenName] [nvarchar](500) NULL,
	[MachineID] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL,
	[Status] [int] NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[AssignMachinesToScreens_SSWL] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
ALTER TABLE [dbo].[AssignMachinesToScreens_SSWL] ADD  DEFAULT ((1)) FOR [Status]
