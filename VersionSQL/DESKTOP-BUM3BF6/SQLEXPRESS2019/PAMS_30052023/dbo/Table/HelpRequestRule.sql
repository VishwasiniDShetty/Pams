/****** Object:  Table [dbo].[HelpRequestRule]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[HelpRequestRule](
	[PlantId] [nvarchar](50) NOT NULL,
	[HelpCode] [nvarchar](50) NOT NULL,
	[Action] [nvarchar](50) NOT NULL,
	[MobileNo] [nvarchar](1000) NOT NULL,
	[Level2Threshold] [int] NULL,
	[Level2MobNo] [nvarchar](1000) NULL,
	[Message] [nvarchar](500) NULL,
	[SlNo] [bigint] IDENTITY(1,1) NOT NULL,
	[MachineId] [nvarchar](50) NULL,
	[Level3Threshold] [int] NULL,
	[Level3MobNo] [nvarchar](1000) NULL,
	[Threshold] [int] NULL
) ON [PRIMARY]
