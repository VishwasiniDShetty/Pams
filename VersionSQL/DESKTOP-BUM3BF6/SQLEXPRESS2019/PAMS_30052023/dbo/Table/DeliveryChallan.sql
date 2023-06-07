/****** Object:  Table [dbo].[DeliveryChallan]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[DeliveryChallan](
	[CustomerID] [nvarchar](50) NULL,
	[ComponentID] [nvarchar](50) NULL,
	[PONumber] [nvarchar](50) NOT NULL,
	[DCNumber] [nvarchar](50) NOT NULL,
	[Delivery_Date] [datetime] NULL,
	[Delivery_Qty] [int] NULL
) ON [PRIMARY]
