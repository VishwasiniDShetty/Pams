/****** Object:  Table [dbo].[MODetails]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[MODetails](
	[MachineInterface] [nvarchar](50) NOT NULL,
	[MONumber] [nvarchar](50) NOT NULL,
	[MOQty] [int] NOT NULL,
	[MOTimeStamp] [datetime] NOT NULL,
	[ID] [bigint] IDENTITY(1,1) NOT NULL
) ON [PRIMARY]
