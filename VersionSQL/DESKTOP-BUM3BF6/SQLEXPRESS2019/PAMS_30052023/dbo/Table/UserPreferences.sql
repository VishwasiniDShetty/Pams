/****** Object:  Table [dbo].[UserPreferences]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[UserPreferences](
	[EmployeeId] [nvarchar](50) NULL,
	[ModuleName] [nvarchar](50) NULL,
	[FormName] [nvarchar](50) NULL,
	[ControlName] [nvarchar](50) NULL,
	[Parameter] [nvarchar](50) NULL,
	[ValueInText] [nvarchar](100) NULL
) ON [PRIMARY]
