﻿/****** Object:  Table [dbo].[AttributeTypeMaster_IDM_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[AttributeTypeMaster_IDM_Pams](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[ID_No] [nvarchar](2000) NULL,
	[AttributeType] [nvarchar](50) NULL,
	[Range_Min] [nvarchar](50) NULL,
	[Range_Max] [nvarchar](50) NULL,
	[GOSide] [float] NULL,
	[Tolerance] [nvarchar](100) NULL,
	[NoGoSide] [nvarchar](50) NULL,
	[Specification] [nvarchar](50) NULL,
	[CalibrationFreq] [nvarchar](2000) NULL,
	[PartID] [nvarchar](50) NULL,
	[PutToUseOn] [datetime] NULL,
	[Remarks] [nvarchar](2000) NULL,
	[ItemCategory] [nvarchar](50) NULL,
	[IDMType] [nvarchar](50) NULL,
	[IDMItemType] [nvarchar](50) NULL,
	[Location] [nvarchar](100) NULL
) ON [PRIMARY]
