/****** Object:  Table [dbo].[Focas_CycleDetails]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Focas_CycleDetails](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[MachineID] [nvarchar](50) NOT NULL,
	[ProgramNo] [nvarchar](50) NOT NULL,
	[CycleTime] [int] NOT NULL,
	[CNCTimeStamp] [datetime] NOT NULL,
	[BatchTS] [datetime] NULL
) ON [PRIMARY]
