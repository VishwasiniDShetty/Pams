/****** Object:  Table [dbo].[ItemsSentToVendor]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ItemsSentToVendor](
	[VendorName] [nvarchar](50) NOT NULL,
	[OrderNumber] [nvarchar](50) NOT NULL,
	[LineItem] [nvarchar](50) NOT NULL,
	[DCnumber] [nvarchar](50) NOT NULL,
	[DCdate] [datetime] NULL,
	[TotalQuantity] [int] NULL,
	[User] [nvarchar](50) NULL,
	[Remarks] [nvarchar](100) NULL,
 CONSTRAINT [PK_ItemsSentToVendor] PRIMARY KEY CLUSTERED 
(
	[VendorName] ASC,
	[OrderNumber] ASC,
	[LineItem] ASC,
	[DCnumber] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[ItemsSentToVendor]  WITH CHECK ADD  CONSTRAINT [FK_ItemsSentToVendor_VendorWorkOrder] FOREIGN KEY([VendorName], [OrderNumber], [LineItem])
REFERENCES [dbo].[VendorWorkOrder] ([VendorName], [OrderNumber], [LineItem])
ALTER TABLE [dbo].[ItemsSentToVendor] CHECK CONSTRAINT [FK_ItemsSentToVendor_VendorWorkOrder]
