/****** Object:  Table [dbo].[FocasWeb_Statistics]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[FocasWeb_Statistics](
	[Plantid] [nvarchar](50) NULL,
	[MachineID] [nvarchar](50) NULL,
	[Component] [nvarchar](50) NULL,
	[OperationNo] [nvarchar](50) NULL,
	[StdCycleTime] [float] NULL,
	[AvgCycleTime] [float] NULL,
	[MinCycleTime] [float] NULL,
	[MaxCycleTime] [float] NULL,
	[StdLoadUnload] [float] NULL,
	[AvgLoadUnload] [float] NULL,
	[MinLoadUnload] [float] NULL,
	[MaxLoadUnload] [float] NULL,
	[Date] [datetime] NULL,
	[ShiftID] [int] NULL,
	[Shift] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL
) ON [PRIMARY]
