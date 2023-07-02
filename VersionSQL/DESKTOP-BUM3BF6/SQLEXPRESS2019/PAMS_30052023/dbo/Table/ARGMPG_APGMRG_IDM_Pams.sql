/****** Object:  Table [dbo].[ARGMPG_APGMRG_IDM_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ARGMPG_APGMRG_IDM_Pams](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[ID_No] [nvarchar](2000) NULL,
	[Make] [nvarchar](50) NULL,
	[Stage] [nvarchar](50) NULL,
	[GuageSize] [nvarchar](100) NULL,
	[GuageSizeMin] [nvarchar](50) NULL,
	[GuageSizeMax] [nvarchar](50) NULL,
	[CalibrationFreq] [nvarchar](50) NULL,
	[PartID] [nvarchar](50) NULL,
	[PutToUseOn] [datetime] NULL,
	[Remarks] [nvarchar](max) NULL,
	[ItemCategory] [nvarchar](50) NULL,
	[IDMType] [nvarchar](50) NULL,
	[IDMItemType] [nvarchar](50) NULL,
	[Location] [nvarchar](max) NULL,
	[SetNo] [nvarchar](50) NULL,
	[MinimumOrderQty] [float] NULL,
	[ShelfLife] [float] NULL,
	[Uom] [nvarchar](50) NULL,
	[Type] [nvarchar](50) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
