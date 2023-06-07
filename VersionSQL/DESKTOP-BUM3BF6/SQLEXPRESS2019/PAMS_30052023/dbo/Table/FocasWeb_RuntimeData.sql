/****** Object:  Table [dbo].[FocasWeb_RuntimeData]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[FocasWeb_RuntimeData](
	[PlantID] [nvarchar](50) NULL,
	[MachineID] [nvarchar](50) NULL,
	[Date] [datetime] NULL,
	[ShiftID] [int] NULL,
	[Shift] [nvarchar](50) NULL,
	[ShiftStart] [datetime] NULL,
	[ShiftEnd] [datetime] NULL,
	[BatchTS] [datetime] NULL,
	[BatchStart] [datetime] NULL,
	[BatchEnd] [datetime] NULL,
	[Stoppagetime] [int] NULL,
	[MachineStatus] [nvarchar](50) NULL,
	[Reason] [nvarchar](50) NULL,
	[AlarmStatus] [nvarchar](50) NULL,
	[TotalStoppage] [float] NULL
) ON [PRIMARY]
