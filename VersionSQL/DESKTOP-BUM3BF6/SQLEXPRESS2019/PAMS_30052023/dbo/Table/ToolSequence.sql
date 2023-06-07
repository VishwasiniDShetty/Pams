/****** Object:  Table [dbo].[ToolSequence]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ToolSequence](
	[MachineID] [nvarchar](50) NOT NULL,
	[ComponentID] [nvarchar](50) NOT NULL,
	[OperationNo] [int] NOT NULL,
	[SequenceNo] [int] NOT NULL,
	[ToolNo] [nvarchar](10) NULL,
	[IdealUsage] [int] NULL,
	[Offset] [nvarchar](5) NULL,
	[ToolDescription] [nvarchar](30) NULL,
	[ToolHolder] [nvarchar](30) NULL,
	[RPM] [int] NULL,
	[Notes] [nvarchar](100) NULL,
	[targetcount] [int] NULL,
	[downcode] [nvarchar](50) NULL,
 CONSTRAINT [PK_ToolSequence] PRIMARY KEY CLUSTERED 
(
	[MachineID] ASC,
	[ComponentID] ASC,
	[OperationNo] ASC,
	[SequenceNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
