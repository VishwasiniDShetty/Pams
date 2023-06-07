/****** Object:  Table [dbo].[GateEntryScreenDetails_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[GateEntryScreenDetails_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[Supplier] [nvarchar](500) NULL,
	[POId] [int] NULL,
	[PONumber] [nvarchar](100) NULL,
	[MaterialID] [nvarchar](500) NULL,
	[ReceivedQty] [float] NULL,
	[InvoiceNumber] [nvarchar](100) NULL,
	[GateID] [int] NULL,
	[GateEntryNumber] [nvarchar](100) NULL,
	[UpdatedTS] [datetime] NULL,
	[Vehicle] [nvarchar](100) NULL,
	[OrderedQty] [float] NULL,
	[Type] [nvarchar](50) NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[GateEntryDate] [datetime] NULL,
	[RiseIssue] [bit] NULL,
	[Remarks] [nvarchar](2000) NULL,
	[InvoiceDate] [datetime] NULL
) ON [PRIMARY]

SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-GateEntryScreenDetails_PAMS-20221109] ON [dbo].[GateEntryScreenDetails_PAMS]
(
	[Supplier] ASC,
	[POId] ASC,
	[PONumber] ASC,
	[MaterialID] ASC,
	[InvoiceNumber] ASC,
	[GateID] ASC,
	[GateEntryNumber] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
ALTER TABLE [dbo].[GateEntryScreenDetails_PAMS] ADD  CONSTRAINT [defau_Updatedts]  DEFAULT (getdate()) FOR [UpdatedTS]
ALTER TABLE [dbo].[GateEntryScreenDetails_PAMS] ADD  DEFAULT ((0)) FOR [RiseIssue]
