/****** Object:  Table [dbo].[DispatchDetails_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[DispatchDetails_Pams](
	[PartID] [nvarchar](50) NULL,
	[PJCNo] [nvarchar](50) NULL,
	[PJCYear] [nvarchar](10) NULL,
	[DispatchQty] [float] NULL,
	[InvoiceNo] [nvarchar](50) NULL,
	[Date] [datetime] NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL,
	[BatchBit] [int] NULL,
	[Remarks] [nvarchar](2000) NULL,
	[CustomerID] [nvarchar](50) NULL
) ON [PRIMARY]
