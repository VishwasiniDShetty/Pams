/****** Object:  Table [dbo].[Alert_AssignRulesToUser]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Alert_AssignRulesToUser](
	[SlNo] [bigint] IDENTITY(1,1) NOT NULL,
	[MachineID] [nvarchar](50) NOT NULL,
	[RuleID] [nvarchar](500) NOT NULL,
	[UserID] [nvarchar](500) NOT NULL,
	[ChatID] [nvarchar](500) NULL
) ON [PRIMARY]
