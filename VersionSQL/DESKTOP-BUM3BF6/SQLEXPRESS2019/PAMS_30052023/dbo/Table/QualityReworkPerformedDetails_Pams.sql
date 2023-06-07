/****** Object:  Table [dbo].[QualityReworkPerformedDetails_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[QualityReworkPerformedDetails_Pams](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[PartID] [nvarchar](50) NULL,
	[OperationNo] [nvarchar](50) NULL,
	[MJCNo] [nvarchar](50) NULL,
	[PJCNo] [nvarchar](50) NULL,
	[PJCYear] [nvarchar](50) NULL,
	[ReworkPerformed_Ok] [float] NULL,
	[UpdatedTSProduction] [datetime] NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL,
	[BatchBit] [bit] NULL,
	[Remarks] [nvarchar](2000) NULL,
	[ReworkDate] [datetime] NULL,
	[ReworkShift] [nvarchar](50) NULL,
	[ReworkOperator] [nvarchar](50) NULL,
	[ReworkPerformed_Qty] [nvarchar](50) NULL,
	[ReworkMachine] [nvarchar](50) NULL
) ON [PRIMARY]
