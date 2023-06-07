/****** Object:  Table [dbo].[MPRDetailsTransaction_PPC_IDM_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[MPRDetailsTransaction_PPC_IDM_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[MPRNo] [nvarchar](50) NULL,
	[MPRDate] [date] NULL,
	[ItemName] [nvarchar](50) NULL,
	[Department] [nvarchar](50) NULL,
	[Qty] [float] NULL,
	[UOM] [nvarchar](50) NULL,
	[RequiredDate] [date] NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTs] [datetime] NULL,
	[Inventory] [nvarchar](50) NULL,
	[ItemCategory] [nvarchar](50) NULL,
	[MPRId] [int] NULL,
	[PPCRemarks] [nvarchar](2000) NULL,
	[StoresRemarks] [nvarchar](2000) NULL,
	[MRRemarks] [nvarchar](2000) NULL,
	[PurchaseRemarks] [nvarchar](2000) NULL,
	[MPRStatus] [nvarchar](50) NULL
) ON [PRIMARY]

SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-20230311-182804] ON [dbo].[MPRDetailsTransaction_PPC_IDM_PAMS]
(
	[MPRNo] ASC,
	[MPRDate] ASC,
	[ItemName] ASC,
	[Department] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
ALTER TABLE [dbo].[MPRDetailsTransaction_PPC_IDM_PAMS] ADD  DEFAULT (getdate()) FOR [UpdatedTs]
