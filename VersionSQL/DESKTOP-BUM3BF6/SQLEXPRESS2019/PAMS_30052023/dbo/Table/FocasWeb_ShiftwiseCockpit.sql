/****** Object:  Table [dbo].[FocasWeb_ShiftwiseCockpit]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[FocasWeb_ShiftwiseCockpit](
	[PlantID] [nvarchar](50) NULL,
	[MachineID] [nvarchar](50) NULL,
	[Date] [datetime] NULL,
	[ShiftID] [int] NULL,
	[Shift] [nvarchar](50) NULL,
	[ShiftStart] [datetime] NULL,
	[ShiftEnd] [datetime] NULL,
	[MachineInterface] [nvarchar](50) NOT NULL,
	[ProductionEfficiency] [float] NULL,
	[AvailabilityEfficiency] [float] NULL,
	[QualityEfficiency] [float] NULL,
	[OverallEfficiency] [float] NULL,
	[Components] [float] NULL,
	[RejCount] [float] NULL,
	[TotalTime] [float] NULL,
	[UtilisedTime] [float] NULL,
	[ManagementLoss] [float] NULL,
	[DownTime] [float] NULL,
	[CN] [float] NULL,
	[Lastcycletime] [datetime] NULL,
	[PEGreen] [smallint] NULL,
	[PERed] [smallint] NULL,
	[AEGreen] [smallint] NULL,
	[AERed] [smallint] NULL,
	[OEGreen] [smallint] NULL,
	[OERed] [smallint] NULL,
	[QEGreen] [smallint] NULL,
	[QERed] [smallint] NULL,
	[MaxDownReason] [nvarchar](50) NULL,
	[LastCycleCO] [nvarchar](100) NULL,
	[LastCycleStart] [datetime] NULL,
	[LastCycleSpindleRunTime] [int] NULL,
	[RunningCycleUT] [float] NULL,
	[RunningCycleDT] [float] NULL,
	[RunningCycleAE] [float] NULL,
	[MachineStatus] [nvarchar](100) NULL,
	[NetDowntime] [float] NULL,
	[Operator] [nvarchar](50) NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[FocasWeb_ShiftwiseCockpit] ADD  DEFAULT ('') FOR [MaxDownReason]
