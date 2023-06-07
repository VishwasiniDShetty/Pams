/****** Object:  Table [dbo].[GeneratePODetails_IDM_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[GeneratePODetails_IDM_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[PONumber] [nvarchar](50) NULL,
	[MPRNo] [nvarchar](50) NULL,
	[ItemName] [nvarchar](50) NULL,
	[Department] [nvarchar](2000) NULL,
	[ItemCategory] [nvarchar](50) NULL,
	[OrderedQty] [float] NULL,
	[POQty] [float] NULL,
	[Supplier] [nvarchar](50) NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL,
	[Status] [nvarchar](50) NULL,
	[POId] [int] NULL,
	[PODate] [datetime] NULL,
	[UnitRate] [float] NULL,
	[Remarks] [nvarchar](2000) NULL,
	[QuotationRefNo] [nvarchar](100) NULL,
	[QuotationDate] [datetime] NULL,
	[HoldRemarks] [nvarchar](2000) NULL,
	[POAction] [nvarchar](50) NULL,
	[POCloseRemarks] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-20230311-125926] ON [dbo].[GeneratePODetails_IDM_PAMS]
(
	[PONumber] ASC,
	[MPRNo] ASC,
	[ItemName] ASC,
	[Department] ASC,
	[ItemCategory] ASC,
	[Supplier] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
ALTER TABLE [dbo].[GeneratePODetails_IDM_PAMS] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
