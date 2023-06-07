/****** Object:  Table [dbo].[QualityRequestMaster]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[QualityRequestMaster](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[Datatype] [int] NULL,
	[mc] [nvarchar](50) NULL,
	[comp] [nvarchar](50) NULL,
	[opn] [nvarchar](50) NULL,
	[Slno] [nvarchar](50) NULL,
	[QualityStatus] [int] NULL,
	[Starttime] [datetime] NULL
) ON [PRIMARY]
