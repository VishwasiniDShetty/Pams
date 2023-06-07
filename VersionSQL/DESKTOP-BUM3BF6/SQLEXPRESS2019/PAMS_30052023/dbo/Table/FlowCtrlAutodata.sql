/****** Object:  Table [dbo].[FlowCtrlAutodata]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[FlowCtrlAutodata](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[MachineInterface] [nvarchar](50) NOT NULL,
	[PumpModel] [nvarchar](50) NOT NULL,
	[PumpSeries] [nvarchar](50) NOT NULL,
	[Operator] [nvarchar](50) NULL,
	[MinFlow] [float] NOT NULL,
	[MaxFlow] [float] NULL,
	[Starttime] [datetime] NOT NULL,
	[Endtime] [datetime] NULL,
	[Remarks] [varchar](max) NULL,
	[Loadunload] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
