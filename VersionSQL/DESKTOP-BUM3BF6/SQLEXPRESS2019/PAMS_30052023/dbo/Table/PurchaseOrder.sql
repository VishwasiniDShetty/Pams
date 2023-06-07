/****** Object:  Table [dbo].[PurchaseOrder]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[PurchaseOrder](
	[CustomerID] [nvarchar](50) NULL,
	[ComponentID] [nvarchar](50) NOT NULL,
	[PONumber] [nvarchar](50) NOT NULL,
	[PODate] [datetime] NULL,
	[ReqDate] [datetime] NULL,
	[ReqQty] [int] NULL
) ON [PRIMARY]
