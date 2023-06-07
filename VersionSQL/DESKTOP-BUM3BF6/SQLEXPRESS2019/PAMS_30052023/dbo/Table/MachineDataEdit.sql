/****** Object:  Table [dbo].[MachineDataEdit]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[MachineDataEdit](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[MachineID] [nvarchar](50) NULL,
	[UserID] [nvarchar](50) NULL,
	[OffsetChange] [bit] NULL,
	[ProgramEdit] [bit] NULL,
	[ParameterEdit] [bit] NULL,
	[Action] [nvarchar](50) NULL,
	[OffsetChangeStartTime] [datetime] NULL,
	[ProgramEditStartTime] [datetime] NULL,
	[ParameterEditStartTime] [datetime] NULL,
	[OffsetChangeEndTime] [datetime] NULL,
	[ProgramEditEndTime] [datetime] NULL,
	[ParameterEditEndTime] [datetime] NULL,
	[OffsetChangeExpectedEndTime] [datetime] NULL,
	[ProgramEditExpectedEndTime] [datetime] NULL,
	[ParameterEditExpectedEndTime] [datetime] NULL,
	[OffsetChangeTime] [nvarchar](50) NULL,
	[ProgramEditTime] [nvarchar](50) NULL,
	[ParameterEditTime] [nvarchar](50) NULL,
	[CNCTimeStamp] [datetime] NULL
) ON [PRIMARY]
