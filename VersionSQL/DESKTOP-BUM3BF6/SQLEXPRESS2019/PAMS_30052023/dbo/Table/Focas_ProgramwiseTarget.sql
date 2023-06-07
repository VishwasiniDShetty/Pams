/****** Object:  Table [dbo].[Focas_ProgramwiseTarget]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Focas_ProgramwiseTarget](
	[MachineID] [nvarchar](50) NULL,
	[ProgramNo] [nvarchar](50) NULL,
	[Target] [int] NULL,
	[comment] [nvarchar](100) NULL,
	[Cycletime] [float] NULL
) ON [PRIMARY]
