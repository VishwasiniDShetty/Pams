/****** Object:  Table [dbo].[QualityReworkDetails_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[QualityReworkDetails_Pams](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[PartID] [nvarchar](50) NULL,
	[OperationNo] [nvarchar](50) NULL,
	[MJCNo] [nvarchar](50) NULL,
	[PJCNo] [nvarchar](50) NULL,
	[PJCYear] [nvarchar](50) NULL,
	[MarkedForReworkQty] [float] NULL,
	[ReworkReason] [nvarchar](100) NULL,
	[RejectionQty] [float] NULL,
	[OkQty] [float] NULL,
	[UpdatedTSProduction] [datetime] NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL,
	[BatchBit] [int] NULL,
	[Process] [nvarchar](50) NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[QualityReworkDetails_Pams] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
