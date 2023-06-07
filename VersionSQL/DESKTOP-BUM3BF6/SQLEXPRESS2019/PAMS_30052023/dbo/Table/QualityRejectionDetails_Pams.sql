/****** Object:  Table [dbo].[QualityRejectionDetails_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[QualityRejectionDetails_Pams](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[PartID] [nvarchar](50) NULL,
	[OperationNo] [nvarchar](50) NULL,
	[MJCNo] [nvarchar](50) NULL,
	[PJCNo] [nvarchar](50) NULL,
	[PJCYear] [nvarchar](50) NULL,
	[RejectionQty] [float] NULL,
	[RejectionReason] [nvarchar](100) NULL,
	[UpdatedTSProduction] [datetime] NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL,
	[BatchBit] [int] NULL,
	[Rework_Rej_Bit] [bit] NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[QualityRejectionDetails_Pams] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
