/****** Object:  Table [dbo].[DCNoGeneration_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[DCNoGeneration_PAMS](
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
	[Pams_DCNo] [nvarchar](50) NULL,
	[DCDate] [datetime] NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL,
	[MaterialType] [nvarchar](50) NULL,
	[Pams_DCID] [int] NULL,
	[DCStatus] [nvarchar](100) NULL,
	[DCType] [nvarchar](50) NULL,
	[JobCardType] [nvarchar](50) NULL,
	[MJCNo] [nvarchar](50) NULL,
	[PJCNo] [nvarchar](50) NULL,
	[Employee] [nvarchar](50) NULL,
	[MaterialRequestNo] [nvarchar](50) NULL,
	[PJCYear] [nvarchar](10) NULL,
	[RequestedBy] [nvarchar](50) NULL,
	[Price] [nvarchar](50) NULL,
	[DCCloseStatus] [nvarchar](50) NULL,
	[DCCloseRemarks] [nvarchar](max) NULL,
	[WithoutOperationQty_KG] [float] NULL,
	[WithoutOperationQty_Numbers] [float] NULL,
	[WithoutOperationQty_UOM] [nvarchar](50) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-20230311-124333] ON [dbo].[DCNoGeneration_PAMS]
(
	[Vendor] ASC,
	[GRNNo] ASC,
	[MaterialID] ASC,
	[PartID] ASC,
	[Process] ASC,
	[Pams_DCNo] ASC,
	[MJCNo] ASC,
	[PJCNo] ASC,
	[MaterialRequestNo] ASC,
	[PJCYear] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
ALTER TABLE [dbo].[DCNoGeneration_PAMS] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
