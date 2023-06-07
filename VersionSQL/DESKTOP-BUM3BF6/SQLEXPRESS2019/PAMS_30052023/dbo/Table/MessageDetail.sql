/****** Object:  Table [dbo].[MessageDetail]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[MessageDetail](
	[MachineId] [nvarchar](50) NULL,
	[Message] [nvarchar](max) NULL,
	[Shift] [nvarchar](50) NULL,
	[DateTime] [datetime] NULL,
	[Flag] [int] NULL,
	[Date] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
