/****** Object:  Table [dbo].[RawMaterialDetails_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[RawMaterialDetails_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[MaterialID] [nvarchar](100) NOT NULL,
	[MaterialDescription] [nvarchar](2000) NULL,
	[Specification] [nvarchar](500) NULL,
	[UOM] [nvarchar](100) NULL,
	[UnitRate] [nvarchar](50) NULL,
	[MaterialType] [nvarchar](50) NULL,
	[HSNCode] [nvarchar](50) NULL,
	[PJCProcessType] [nvarchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[MaterialID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
