/****** Object:  Table [dbo].[Focas_DailyMaintenance]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Focas_DailyMaintenance](
	[id] [numeric](18, 0) NULL,
	[subsystem] [nvarchar](250) NULL,
	[checks] [nvarchar](250) NULL,
	[whnToCheck] [nvarchar](200) NULL,
	[Action] [varchar](50) NULL,
	[DateTime] [datetime] NULL,
	[Machineid] [nvarchar](50) NULL,
	[Shift] [nchar](12) NULL
) ON [PRIMARY]
