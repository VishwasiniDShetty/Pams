/****** Object:  Table [dbo].[MachineDataSettings]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[MachineDataSettings](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[MachineID] [nvarchar](50) NULL,
	[OffsetChangeTime] [int] NULL,
	[ParameterEditTime] [int] NULL,
	[ProgramEditTime] [int] NULL,
	[OffsetChangeRegister] [nvarchar](50) NULL,
	[ParameterEditRegister] [nvarchar](50) NULL,
	[ProgramEditRegister] [nvarchar](50) NULL,
	[OffsetChangeTimeoutRegister] [nvarchar](50) NULL,
	[ParameterEditTimeoutRegister] [nvarchar](50) NULL,
	[ProgramEditTimeoutRegister] [nvarchar](50) NULL
) ON [PRIMARY]
