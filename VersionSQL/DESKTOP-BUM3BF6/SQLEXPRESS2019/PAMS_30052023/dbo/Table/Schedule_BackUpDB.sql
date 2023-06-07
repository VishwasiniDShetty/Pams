/****** Object:  Table [dbo].[Schedule_BackUpDB]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Schedule_BackUpDB](
	[Slno] [bigint] IDENTITY(1,1) NOT NULL,
	[ServerName] [nvarchar](50) NULL,
	[StartDate] [nvarchar](12) NULL,
	[NextDate] [nvarchar](12) NULL,
	[StartTime] [datetime] NULL,
	[NextTime] [datetime] NULL,
	[Occurs] [int] NULL,
	[Frequency] [int] NULL,
	[BackUpPath] [nvarchar](80) NULL
) ON [PRIMARY]
