/****** Object:  Table [dbo].[LoginInfo_Trelleborg]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[LoginInfo_Trelleborg](
	[DeviceID] [int] NULL,
	[Machine] [nvarchar](50) NULL,
	[Default] [nvarchar](50) NULL,
	[DeviceName] [nvarchar](max) NULL,
	[Message] [nvarchar](1000) NULL,
	[FormBackground] [nvarchar](50) NULL,
	[GridHeaderBackground] [nvarchar](50) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
