/****** Object:  Table [dbo].[DCNoGenerationTemp_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[DCNoGenerationTemp_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[Pams_DCNo] [nvarchar](50) NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL,
	[Pams_DCID] [int] NULL,
	[DocumentType] [nvarchar](50) NULL,
	[DCType] [nvarchar](50) NULL,
	[JobCardType] [nvarchar](50) NULL
) ON [PRIMARY]
