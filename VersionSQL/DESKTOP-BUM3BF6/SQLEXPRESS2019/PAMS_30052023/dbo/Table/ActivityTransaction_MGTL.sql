/****** Object:  Table [dbo].[ActivityTransaction_MGTL]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ActivityTransaction_MGTL](
	[IDD] [bigint] IDENTITY(1,1) NOT NULL,
	[ActivityID] [int] NULL,
	[Frequency] [nvarchar](50) NULL,
	[ActivityTS] [datetime] NULL,
	[ActivityDoneTS] [datetime] NULL,
	[Machineid] [nvarchar](50) NULL
) ON [PRIMARY]
