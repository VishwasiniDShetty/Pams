/****** Object:  Table [dbo].[MachineNodeAutodata]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[MachineNodeAutodata](
	[Datatype] [nvarchar](50) NULL,
	[NodeInterface] [nvarchar](50) NULL,
	[Starttime] [datetime] NULL,
	[ID] [bigint] IDENTITY(1,1) NOT NULL
) ON [PRIMARY]
