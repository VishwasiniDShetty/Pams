/****** Object:  Table [dbo].[CellFinishOperation]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[CellFinishOperation](
	[CellId] [nvarchar](50) NOT NULL,
	[ComponentId] [nvarchar](50) NOT NULL,
	[OperationNo] [smallint] NOT NULL,
	[Yield] [bigint] NOT NULL,
	[FromDate] [datetime] NULL,
	[ToDate] [datetime] NULL,
 CONSTRAINT [IX_CellFinishOperation] UNIQUE NONCLUSTERED 
(
	[CellId] ASC,
	[ComponentId] ASC,
	[OperationNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
