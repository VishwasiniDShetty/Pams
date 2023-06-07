/****** Object:  Table [dbo].[OperatorMaintenanceChecklist]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[OperatorMaintenanceChecklist](
	[Slno] [int] NULL,
	[Description] [nvarchar](200) NULL,
	[Frequency] [nvarchar](200) NULL,
	[Mode] [nvarchar](200) NULL,
	[Language] [nvarchar](50) NULL
) ON [PRIMARY]
