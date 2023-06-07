/****** Object:  Table [dbo].[Focas_MachineRunningStatus]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Focas_MachineRunningStatus](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Machineid] [nvarchar](50) NULL,
	[Datatype] [nvarchar](50) NULL,
	[LastCycleTS] [datetime] NULL,
	[AlarmStatus] [nvarchar](50) NULL,
	[SpindleStatus] [int] NULL,
	[SpindleCycleTS] [datetime] NULL,
	[PowerOnOrOff] [int] NULL,
	[MachineStatus] [nvarchar](50) NULL,
	[ProgramNo] [nvarchar](50) NULL
) ON [PRIMARY]
