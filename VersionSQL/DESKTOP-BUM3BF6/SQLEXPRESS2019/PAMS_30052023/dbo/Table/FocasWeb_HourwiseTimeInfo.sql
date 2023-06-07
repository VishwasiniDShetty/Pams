/****** Object:  Table [dbo].[FocasWeb_HourwiseTimeInfo]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[FocasWeb_HourwiseTimeInfo](
	[PlantID] [nvarchar](50) NULL,
	[MachineID] [nvarchar](50) NULL,
	[Date] [datetime] NULL,
	[ShiftID] [int] NULL,
	[Shift] [nvarchar](50) NULL,
	[HourID] [int] NULL,
	[HourStart] [datetime] NULL,
	[HourEnd] [datetime] NULL,
	[PowerOntime] [float] NULL,
	[OperatingTime] [float] NULL,
	[CuttingTime] [float] NULL,
	[UpdatedTS] [datetime] NULL,
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL
) ON [PRIMARY]
