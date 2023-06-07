/****** Object:  Table [dbo].[IDMTypeMaster_IDM_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[IDMTypeMaster_IDM_Pams](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[ItemCategory] [nvarchar](50) NULL,
	[IDMType] [nvarchar](50) NULL,
	[IDMItemType] [nvarchar](50) NULL,
	[TableName] [nvarchar](100) NULL
) ON [PRIMARY]
