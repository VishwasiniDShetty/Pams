/****** Object:  Table [dbo].[DCNoGeneration_NewTemp_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[DCNoGeneration_NewTemp_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[Vendor] [nvarchar](50) NULL,
	[GRNNo] [nvarchar](50) NULL,
	[MaterialID] [nvarchar](50) NULL,
	[PartID] [nvarchar](50) NULL,
	[Process] [nvarchar](2000) NULL,
	[Qty_KG] [float] NULL,
	[Qty_Numbers] [float] NULL,
	[HSNCode] [nvarchar](500) NULL,
	[UOM] [nvarchar](50) NULL,
	[Bin] [nvarchar](50) NULL,
	[Value] [float] NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL,
	[MaterialType] [nvarchar](50) NULL,
	[DCStatus] [nvarchar](100) NULL,
	[DCType] [nvarchar](50) NULL,
	[JobCardType] [nvarchar](50) NULL,
	[MJCNo] [nvarchar](50) NULL,
	[PJCNo] [nvarchar](50) NULL,
	[Employee] [nvarchar](50) NULL,
	[MaterialRequestNo] [nvarchar](50) NULL,
	[PJCYear] [nvarchar](10) NULL,
	[RequestedBy] [nvarchar](50) NULL,
	[UserID] [nvarchar](50) NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[DCNoGeneration_NewTemp_PAMS] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
