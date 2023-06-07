/****** Object:  Table [dbo].[CellHistory]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[CellHistory](
	[CellId] [nvarchar](50) NOT NULL,
	[MachineId] [nvarchar](50) NOT NULL,
	[FromDate] [datetime] NULL,
	[ToDate] [datetime] NULL,
	[PlantID] [nvarchar](50) NULL,
 CONSTRAINT [IX_CellHistory] UNIQUE CLUSTERED 
(
	[CellId] ASC,
	[MachineId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
