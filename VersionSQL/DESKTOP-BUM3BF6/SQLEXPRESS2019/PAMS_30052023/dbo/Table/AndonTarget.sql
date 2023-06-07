/****** Object:  Table [dbo].[AndonTarget]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[AndonTarget](
	[Plant] [nvarchar](50) NULL,
	[Machine] [nvarchar](50) NULL,
	[Target] [bigint] NULL,
	[TargetDate] [smalldatetime] NULL,
	[Targetshift] [nvarchar](20) NULL
) ON [PRIMARY]
