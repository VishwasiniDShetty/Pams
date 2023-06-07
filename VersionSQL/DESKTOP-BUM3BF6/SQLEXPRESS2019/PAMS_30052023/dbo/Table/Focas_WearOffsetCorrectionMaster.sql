/****** Object:  Table [dbo].[Focas_WearOffsetCorrectionMaster]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Focas_WearOffsetCorrectionMaster](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[MachineId] [nvarchar](50) NOT NULL,
	[ProgramNumber] [nvarchar](50) NOT NULL,
	[ToolNumber] [nvarchar](50) NOT NULL,
	[WearOffsetNumber] [nvarchar](50) NOT NULL,
	[OffsetLocation] [int] NOT NULL,
	[GaugeID] [nvarchar](50) NOT NULL,
	[DimensionId] [nvarchar](50) NOT NULL,
	[NominalDimension] [float] NOT NULL,
	[LowerLimit] [float] NOT NULL,
	[UpperLimit] [float] NOT NULL,
	[DefaultWearOffsetValue] [float] NOT NULL,
	[LastUpdatedTime] [datetime] NOT NULL,
 CONSTRAINT [PK_Focas_WearOffsetCorrectionMaster] PRIMARY KEY CLUSTERED 
(
	[MachineId] ASC,
	[ProgramNumber] ASC,
	[ToolNumber] ASC,
	[WearOffsetNumber] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[Focas_WearOffsetCorrectionMaster] ADD  DEFAULT (getdate()) FOR [LastUpdatedTime]
