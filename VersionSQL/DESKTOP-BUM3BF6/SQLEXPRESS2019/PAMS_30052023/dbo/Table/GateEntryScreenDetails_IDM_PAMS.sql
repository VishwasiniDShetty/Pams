/****** Object:  Table [dbo].[GateEntryScreenDetails_IDM_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[GateEntryScreenDetails_IDM_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[Supplier] [nvarchar](500) NULL,
	[POId] [int] NULL,
	[PONumber] [nvarchar](100) NULL,
	[ItemName] [nvarchar](500) NULL,
	[OrderedQty] [float] NULL,
	[ReceivedQty] [float] NULL,
	[InvoiceNumber] [nvarchar](100) NULL,
	[GateID] [int] NULL,
	[GateEntryNumber] [nvarchar](100) NULL,
	[GateEntryDate] [datetime] NULL,
	[Vehicle] [nvarchar](100) NULL,
	[Type] [nvarchar](50) NULL,
	[RiseIssue] [bit] NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL,
	[Remarks] [nvarchar](2000) NULL,
	[InvoiceDate] [datetime] NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[GateEntryScreenDetails_IDM_PAMS] ADD  DEFAULT ((0)) FOR [RiseIssue]
ALTER TABLE [dbo].[GateEntryScreenDetails_IDM_PAMS] ADD  CONSTRAINT [defau_Updatedts_idm]  DEFAULT (getdate()) FOR [UpdatedTS]
