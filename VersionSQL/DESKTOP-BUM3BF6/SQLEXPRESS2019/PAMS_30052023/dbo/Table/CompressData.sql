/****** Object:  Table [dbo].[CompressData]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[CompressData](
	[SlNo] [int] IDENTITY(1,1) NOT NULL,
	[Date] [datetime] NULL,
	[Machine] [nvarchar](50) NULL,
	[SpindleData] [varbinary](max) NULL,
	[AxisNo] [nvarchar](5) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
