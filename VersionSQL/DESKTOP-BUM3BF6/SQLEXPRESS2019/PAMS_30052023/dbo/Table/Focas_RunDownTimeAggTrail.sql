/****** Object:  Table [dbo].[Focas_RunDownTimeAggTrail]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Focas_RunDownTimeAggTrail](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[Machineid] [nvarchar](50) NOT NULL,
	[Shift] [nvarchar](50) NULL,
	[ShiftID] [int] NULL,
	[HourID] [int] NULL,
	[Aggdate] [datetime] NULL,
	[Starttime] [datetime] NOT NULL,
	[Endtime] [datetime] NULL,
	[RecordEndtime] [datetime] NOT NULL,
	[AggregateTS] [datetime] NULL,
 CONSTRAINT [PK_RunDownTimeAggTrail] PRIMARY KEY CLUSTERED 
(
	[Machineid] ASC,
	[Starttime] ASC,
	[RecordEndtime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
