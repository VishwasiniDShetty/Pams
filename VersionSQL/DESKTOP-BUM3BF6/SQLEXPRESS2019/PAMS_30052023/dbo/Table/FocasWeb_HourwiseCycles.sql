/****** Object:  Table [dbo].[FocasWeb_HourwiseCycles]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[FocasWeb_HourwiseCycles](
	[PlantID] [nvarchar](50) NULL,
	[MachineID] [nvarchar](50) NULL,
	[Date] [datetime] NULL,
	[ShiftID] [int] NULL,
	[Shift] [nvarchar](50) NULL,
	[HourID] [int] NULL,
	[HourStart] [datetime] NULL,
	[HourEnd] [datetime] NULL,
	[ProgramID] [nvarchar](50) NULL,
	[PartCount] [float] NULL,
	[UpdatedTS] [datetime] NULL,
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[ProgramBlock] [nvarchar](4000) NULL,
	[Target] [int] NULL,
	[Cycletime] [float] NULL
) ON [PRIMARY]
