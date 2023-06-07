/****** Object:  Table [dbo].[ARGMPG_APGMRG_IDM_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ARGMPG_APGMRG_IDM_Pams](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[ID_No] [nvarchar](2000) NULL,
	[Make] [nvarchar](50) NULL,
	[Stage] [nvarchar](50) NULL,
	[GuageSize] [nvarchar](100) NULL,
	[GuageSizeMin] [float] NULL,
	[GuageSizeMax] [float] NULL,
	[CalibrationFreq] [nvarchar](50) NULL,
	[PartID] [nvarchar](50) NULL,
	[PutToUseOn] [datetime] NULL,
	[Remarks] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
