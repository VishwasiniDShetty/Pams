/****** Object:  Table [dbo].[FocasWeb_FrequencyWiseData]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[FocasWeb_FrequencyWiseData](
	[Date] [datetime] NULL,
	[PlantID] [nvarchar](50) NULL,
	[MachineID] [nvarchar](50) NULL,
	[Partscount] [float] NULL,
	[Downtime] [float] NULL,
	[RejectionCount] [int] NULL,
	[AvailabilityEfficiency] [float] NULL,
	[ProductionEfficiency] [float] NULL,
	[QualityEfficiency] [float] NULL,
	[OverallEfficiency] [float] NULL,
	[RunningPart] [nvarchar](50) NULL,
	[Frequency] [nvarchar](50) NULL,
	[UtilisedTime] [float] NULL
) ON [PRIMARY]
