/****** Object:  Table [dbo].[DeviceCategory]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[DeviceCategory](
	[id] [int] NOT NULL,
	[DeviceName] [nvarchar](50) NOT NULL,
	[DeviceDescription] [nvarchar](200) NULL
) ON [PRIMARY]
