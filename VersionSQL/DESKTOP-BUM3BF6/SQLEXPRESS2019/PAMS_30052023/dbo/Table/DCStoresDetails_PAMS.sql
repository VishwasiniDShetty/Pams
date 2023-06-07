/****** Object:  Table [dbo].[DCStoresDetails_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[DCStoresDetails_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[Vendor] [nvarchar](50) NULL,
	[GRNNo] [nvarchar](50) NULL,
	[MaterialID] [nvarchar](50) NULL,
	[PartID] [nvarchar](50) NULL,
	[Qty_KG] [float] NULL,
	[Qty_Numbers] [float] NULL,
	[EndBitAllowances] [float] NULL,
	[PartingAllowances] [float] NULL,
	[PamsDCNo] [nvarchar](50) NULL,
	[VendorDCNo] [nvarchar](50) NULL,
	[VendorDCDate] [datetime] NULL,
	[VehicleNo] [nvarchar](50) NULL,
	[DC_Stores_Status] [nvarchar](50) NULL,
	[UpdatedBy_Stores] [nvarchar](50) NULL,
	[UpdatedTS_Stores] [datetime] NULL,
	[MJCNo] [nvarchar](50) NULL,
	[PJCNo] [nvarchar](50) NULL,
	[PJCYear] [nvarchar](10) NULL,
	[PJCQty] [nvarchar](50) NULL,
	[Quality_Status] [nvarchar](50) NULL,
	[UpdatedBy_Quality] [nvarchar](50) NULL,
	[UpdatedTS_Quality] [datetime] NULL,
	[UOM] [nvarchar](50) NULL,
	[RejQty] [float] NULL,
	[Process] [nvarchar](2000) NULL,
	[Remarks] [nvarchar](2000) NULL,
	[SettingScrap] [float] NULL,
	[FromProcess] [nvarchar](2000) NULL,
	[FSUnique] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	[Supplier_Report] [varbinary](max) FILESTREAM  NULL,
	[Supplier_ReportName] [nvarchar](100) NULL,
	[ReworkQty] [float] NULL,
UNIQUE NONCLUSTERED 
(
	[FSUnique] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] FILESTREAM_ON [FILESTREAM_grp]

SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-20230311-124443] ON [dbo].[DCStoresDetails_PAMS]
(
	[Vendor] ASC,
	[GRNNo] ASC,
	[MaterialID] ASC,
	[PartID] ASC,
	[PamsDCNo] ASC,
	[VendorDCNo] ASC,
	[MJCNo] ASC,
	[PJCNo] ASC,
	[PJCYear] ASC,
	[Process] ASC,
	[FromProcess] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
ALTER TABLE [dbo].[DCStoresDetails_PAMS] ADD  DEFAULT (newid()) FOR [FSUnique]
