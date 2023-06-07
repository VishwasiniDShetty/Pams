/****** Object:  Table [dbo].[MachineUserAccess]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[MachineUserAccess](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[UserID] [nvarchar](50) NULL,
	[OffsetChange] [bit] NULL,
	[ParameterEdit] [bit] NULL,
	[ProgramEdit] [bit] NULL
) ON [PRIMARY]
