/****** Object:  Table [dbo].[MachineNodeInformation]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[MachineNodeInformation](
	[MachineId] [nvarchar](50) NULL,
	[NodeInterface] [nvarchar](50) NULL,
	[NodeId] [nvarchar](50) NULL,
	[SortOrder] [int] NULL
) ON [PRIMARY]
