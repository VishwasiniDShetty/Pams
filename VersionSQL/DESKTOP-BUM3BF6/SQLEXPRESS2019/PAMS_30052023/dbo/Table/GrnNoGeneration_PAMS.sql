/****** Object:  Table [dbo].[GrnNoGeneration_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[GrnNoGeneration_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[POId] [int] NULL,
	[PONumber] [nvarchar](100) NULL,
	[MaterialID] [nvarchar](50) NULL,
	[InvoiceNumber] [nvarchar](100) NULL,
	[ReceivedQty] [float] NULL,
	[GrnNo] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL,
	[GrnID] [int] NULL,
	[Type] [nvarchar](50) NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[GRNDate] [datetime] NULL,
	[Supplier] [nvarchar](100) NULL,
	[OrderedQty] [float] NULL,
	[GRNStatus] [nvarchar](50) NULL,
	[QualityStatus] [nvarchar](50) NULL,
	[Location] [nvarchar](500) NULL,
	[ReceivedQty_NUmbers] [float] NULL,
	[UOM] [nvarchar](50) NULL,
	[PartID] [nvarchar](50) NULL
) ON [PRIMARY]

SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-20230311-130505] ON [dbo].[GrnNoGeneration_PAMS]
(
	[POId] ASC,
	[PONumber] ASC,
	[MaterialID] ASC,
	[InvoiceNumber] ASC,
	[GrnNo] ASC,
	[GrnID] ASC,
	[Location] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-GrnNoGeneration_PAMS-20221109] ON [dbo].[GrnNoGeneration_PAMS]
(
	[POId] ASC,
	[PONumber] ASC,
	[MaterialID] ASC,
	[InvoiceNumber] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
ALTER TABLE [dbo].[GrnNoGeneration_PAMS] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
