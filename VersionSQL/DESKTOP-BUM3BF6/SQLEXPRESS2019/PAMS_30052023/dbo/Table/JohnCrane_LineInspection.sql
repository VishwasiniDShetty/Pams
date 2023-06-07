/****** Object:  Table [dbo].[JohnCrane_LineInspection]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[JohnCrane_LineInspection](
	[Datatype] [nvarchar](50) NULL,
	[MachineID] [nvarchar](50) NULL,
	[LineInspected] [nvarchar](50) NULL,
	[NCLines] [int] NULL,
	[EQP] [int] NULL,
	[IQP] [int] NULL,
	[EQPThreshold] [int] NULL,
	[IQPThreshold] [int] NULL,
	[TimeStamp] [datetime] NULL,
	[TransLinesInspected] [int] NULL,
	[TransNCLines] [int] NULL
) ON [PRIMARY]
