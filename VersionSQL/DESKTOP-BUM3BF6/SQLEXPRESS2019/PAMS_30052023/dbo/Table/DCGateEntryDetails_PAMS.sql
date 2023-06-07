/****** Object:  Table [dbo].[DCGateEntryDetails_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[DCGateEntryDetails_PAMS](
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
	[RiseIssue] [bit] NULL,
	[UpdatedBy_Gate] [nvarchar](50) NULL,
	[UpdatedTS_Gate] [datetime] NULL,
	[MJCNo] [nvarchar](50) NULL,
	[UOM] [nvarchar](50) NULL,
	[SettingScrap] [float] NULL,
	[GateID] [int] NULL,
	[DCGateEntryNumber] [nvarchar](50) NULL
) ON [PRIMARY]

SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-20230311-124156] ON [dbo].[DCGateEntryDetails_PAMS]
(
	[Vendor] ASC,
	[GRNNo] ASC,
	[MaterialID] ASC,
	[PartID] ASC,
	[PamsDCNo] ASC,
	[VendorDCNo] ASC,
	[VendorDCDate] ASC,
	[MJCNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
ALTER TABLE [dbo].[DCGateEntryDetails_PAMS] ADD  DEFAULT ((0)) FOR [RiseIssue]
