/****** Object:  Table [dbo].[ShiftAggTrail]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ShiftAggTrail](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[Machineid] [nvarchar](50) NOT NULL,
	[Shift] [nvarchar](50) NOT NULL,
	[Aggdate] [datetime] NOT NULL,
	[Datatype] [int] NOT NULL,
	[Starttime] [datetime] NOT NULL,
	[Endtime] [datetime] NOT NULL,
	[AggregateTS] [datetime] NOT NULL,
	[Recordid] [bigint] NULL,
 CONSTRAINT [PK_ShiftAggTrail] PRIMARY KEY CLUSTERED 
(
	[Machineid] ASC,
	[Shift] ASC,
	[Aggdate] ASC,
	[Datatype] ASC,
	[Starttime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
