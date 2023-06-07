/****** Object:  Table [dbo].[ActivityFreq_MGTL]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ActivityFreq_MGTL](
	[FreqID] [tinyint] IDENTITY(1,1) NOT NULL,
	[Frequency] [nvarchar](50) NOT NULL,
	[Freqvalue] [nvarchar](50) NULL,
	[Freqtype] [nvarchar](50) NULL,
	[SortOrder] [smallint] NOT NULL,
	[IsEnabled] [bit] NULL
) ON [PRIMARY]
