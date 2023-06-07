/****** Object:  Table [dbo].[Focas_LiveData]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Focas_LiveData](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[MachineID] [nvarchar](50) NOT NULL,
	[MachineStatus] [nvarchar](50) NULL,
	[MachineMode] [nvarchar](50) NULL,
	[ProgramNo] [nvarchar](100) NULL,
	[ToolNo] [int] NULL,
	[OffsetNo] [int] NULL,
	[SpindleStatus] [nvarchar](50) NULL,
	[SpindleSpeed] [bigint] NULL,
	[SpindleLoad] [decimal](18, 3) NULL,
	[Temperature] [decimal](18, 3) NULL,
	[SpindleTarque] [decimal](18, 3) NULL,
	[FeedRate] [decimal](18, 3) NULL,
	[AlarmNo] [int] NULL,
	[PowerOnTime] [float] NULL,
	[OperatingTime] [float] NULL,
	[CutTime] [float] NULL,
	[ServoLoad_XYZ] [nvarchar](500) NULL,
	[AxisPosition] [nvarchar](500) NULL,
	[ProgramBlock] [nvarchar](4000) NULL,
	[CNCTimeStamp] [datetime] NULL,
	[PartsCount] [int] NULL,
	[BatchTS] [datetime] NULL,
	[MachineUpDownStatus] [int] NULL,
	[MachineUpDownBatchTS] [datetime] NULL,
 CONSTRAINT [PK_Focas_LiveData] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

SET ANSI_PADDING ON

CREATE NONCLUSTERED INDEX [IX_MachineCNCTimestamp] ON [dbo].[Focas_LiveData]
(
	[MachineID] ASC,
	[CNCTimeStamp] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
ALTER TABLE [dbo].[Focas_LiveData] ADD  CONSTRAINT [DF_Focas_LiveData_PartsCount]  DEFAULT ((0)) FOR [PartsCount]
