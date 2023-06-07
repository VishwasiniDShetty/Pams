/****** Object:  Table [dbo].[ReworkPerformedSummary_Jina]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ReworkPerformedSummary_Jina](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[mc] [nvarchar](50) NULL,
	[comp] [nvarchar](50) NULL,
	[opn] [nvarchar](50) NULL,
	[opr] [nvarchar](50) NULL,
	[WorkOrderNumber] [nvarchar](50) NULL,
	[ReworkAccepted] [int] NULL,
	[ReworkRejected] [int] NULL,
	[ReworkPerformed] [int] NULL,
	[RejDate] [datetime] NULL,
	[RejShift] [nvarchar](15) NULL,
	[CreatedTS] [datetime] NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[ReworkPerformedSummary_Jina] ADD  DEFAULT ((0)) FOR [ReworkAccepted]
ALTER TABLE [dbo].[ReworkPerformedSummary_Jina] ADD  DEFAULT ((0)) FOR [ReworkRejected]
ALTER TABLE [dbo].[ReworkPerformedSummary_Jina] ADD  DEFAULT ((0)) FOR [ReworkPerformed]
