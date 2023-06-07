/****** Object:  Table [dbo].[HourAggTrail]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[HourAggTrail](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[Machineid] [nvarchar](50) NOT NULL,
	[Shift] [nvarchar](50) NOT NULL,
	[HourStart] [datetime] NOT NULL,
	[HourEnd] [datetime] NOT NULL,
	[HourID] [nvarchar](50) NOT NULL,
	[Aggdate] [datetime] NOT NULL,
	[Starttime] [datetime] NOT NULL,
	[AggregateTS] [datetime] NOT NULL,
 CONSTRAINT [PK_HourAggTrail] PRIMARY KEY CLUSTERED 
(
	[Machineid] ASC,
	[Shift] ASC,
	[Aggdate] ASC,
	[HourID] ASC,
	[Starttime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
