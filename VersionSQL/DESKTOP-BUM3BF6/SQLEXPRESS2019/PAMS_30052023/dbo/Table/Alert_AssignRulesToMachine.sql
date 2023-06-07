/****** Object:  Table [dbo].[Alert_AssignRulesToMachine]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Alert_AssignRulesToMachine](
	[SlNo] [bigint] IDENTITY(1,1) NOT NULL,
	[MachineID] [nvarchar](50) NOT NULL,
	[RuleID] [nvarchar](500) NOT NULL
) ON [PRIMARY]
