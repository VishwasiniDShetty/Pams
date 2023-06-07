/****** Object:  Table [dbo].[ToolStockManagement]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ToolStockManagement](
	[ToolCategory] [nvarchar](50) NOT NULL,
	[ToolID] [nvarchar](50) NOT NULL,
	[PONumber] [nvarchar](50) NOT NULL,
	[PurchaseDate] [datetime] NULL,
	[PurchaseQuantity] [int] NULL,
	[InStores-Good] [int] NULL,
	[Instores-Used] [int] NULL,
	[InShop] [int] NULL,
 CONSTRAINT [PK_ToolStockManagement] PRIMARY KEY CLUSTERED 
(
	[ToolCategory] ASC,
	[ToolID] ASC,
	[PONumber] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
