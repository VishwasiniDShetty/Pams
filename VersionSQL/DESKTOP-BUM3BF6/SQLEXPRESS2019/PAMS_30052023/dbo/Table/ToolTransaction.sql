/****** Object:  Table [dbo].[ToolTransaction]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ToolTransaction](
	[Id] [tinyint] IDENTITY(1,1) NOT NULL,
	[ToolCategory] [nvarchar](50) NOT NULL,
	[ToolId] [nvarchar](50) NOT NULL,
	[PONumber] [nvarchar](50) NOT NULL,
	[TransactionDate] [datetime] NULL,
	[Quantity] [int] NULL,
	[Status] [nvarchar](50) NULL,
	[LoginUser] [nvarchar](50) NULL,
	[Remarks] [nvarchar](100) NULL,
 CONSTRAINT [PK_ToolTransaction] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[ToolTransaction]  WITH CHECK ADD  CONSTRAINT [FK_ToolTransaction_ToolStockManagement] FOREIGN KEY([ToolCategory], [ToolId], [PONumber])
REFERENCES [dbo].[ToolStockManagement] ([ToolCategory], [ToolID], [PONumber])
ALTER TABLE [dbo].[ToolTransaction] CHECK CONSTRAINT [FK_ToolTransaction_ToolStockManagement]
