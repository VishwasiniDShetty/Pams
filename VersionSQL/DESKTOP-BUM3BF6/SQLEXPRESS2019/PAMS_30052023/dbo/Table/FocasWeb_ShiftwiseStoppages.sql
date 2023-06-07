/****** Object:  Table [dbo].[FocasWeb_ShiftwiseStoppages]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[FocasWeb_ShiftwiseStoppages](
	[PlantID] [nvarchar](50) NULL,
	[MachineID] [nvarchar](50) NULL,
	[Date] [datetime] NULL,
	[ShiftID] [int] NULL,
	[Shift] [nvarchar](50) NULL,
	[Batchstart] [datetime] NULL,
	[BatchEnd] [datetime] NULL,
	[StoppageTime] [float] NULL,
	[Reason] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL,
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL
) ON [PRIMARY]
