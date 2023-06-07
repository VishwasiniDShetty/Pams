/****** Object:  Table [dbo].[MasterJobCardHeaderCreation_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[MasterJobCardHeaderCreation_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[GRNNo] [nvarchar](50) NULL,
	[MJCNo] [nvarchar](50) NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL,
	[MJCStatus] [nvarchar](50) NULL,
	[MJCCloseRemarks] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

ALTER TABLE [dbo].[MasterJobCardHeaderCreation_PAMS] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
ALTER TABLE [dbo].[MasterJobCardHeaderCreation_PAMS] ADD  DEFAULT ('Open') FOR [MJCStatus]
