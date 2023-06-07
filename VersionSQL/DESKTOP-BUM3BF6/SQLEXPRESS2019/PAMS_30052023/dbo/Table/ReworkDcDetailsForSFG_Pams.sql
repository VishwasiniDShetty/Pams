/****** Object:  Table [dbo].[ReworkDcDetailsForSFG_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ReworkDcDetailsForSFG_Pams](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[Vendor] [nvarchar](50) NULL,
	[PamsDCNo] [nvarchar](50) NULL,
	[MaterialID] [nvarchar](50) NULL,
	[PartID] [nvarchar](50) NULL,
	[VendorDCNo] [nvarchar](50) NULL,
	[MJCNo] [nvarchar](50) NULL,
	[PJCNo] [nvarchar](50) NULL,
	[MaterialRequestNo] [nvarchar](50) NULL,
	[RequestedQty] [float] NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL,
	[Process] [nvarchar](50) NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[ReworkDcDetailsForSFG_Pams] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
