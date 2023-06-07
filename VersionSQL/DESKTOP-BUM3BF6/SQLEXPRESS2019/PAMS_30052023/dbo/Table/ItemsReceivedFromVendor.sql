/****** Object:  Table [dbo].[ItemsReceivedFromVendor]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ItemsReceivedFromVendor](
	[VendorName] [nvarchar](50) NOT NULL,
	[OrderNumber] [nvarchar](50) NOT NULL,
	[LineItem] [nvarchar](50) NOT NULL,
	[DCnumber] [nvarchar](50) NOT NULL,
	[VendorDCnumber] [nvarchar](50) NOT NULL,
	[VendorDCdate] [datetime] NULL,
	[TotalQuantity] [int] NULL,
	[AcceptedQuantity] [int] NULL,
	[RejectedQuantity] [int] NULL,
	[ReworkQuantity] [int] NULL,
	[User] [nvarchar](50) NULL,
	[Remarks] [nvarchar](100) NULL,
 CONSTRAINT [PK_ItemsReceivedFromVendor] PRIMARY KEY CLUSTERED 
(
	[VendorName] ASC,
	[OrderNumber] ASC,
	[LineItem] ASC,
	[DCnumber] ASC,
	[VendorDCnumber] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[ItemsReceivedFromVendor]  WITH CHECK ADD  CONSTRAINT [FK_ItemsReceivedFromVendor_ItemsSentToVendor] FOREIGN KEY([VendorName], [OrderNumber], [LineItem], [DCnumber])
REFERENCES [dbo].[ItemsSentToVendor] ([VendorName], [OrderNumber], [LineItem], [DCnumber])
ALTER TABLE [dbo].[ItemsReceivedFromVendor] CHECK CONSTRAINT [FK_ItemsReceivedFromVendor_ItemsSentToVendor]
