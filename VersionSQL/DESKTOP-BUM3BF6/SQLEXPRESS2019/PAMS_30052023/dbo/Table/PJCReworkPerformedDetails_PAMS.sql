/****** Object:  Table [dbo].[PJCReworkPerformedDetails_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[PJCReworkPerformedDetails_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[Date] [datetime] NULL,
	[Shift] [nvarchar](50) NULL,
	[Machineid] [nvarchar](50) NULL,
	[PartID] [nvarchar](50) NULL,
	[MJCNo] [nvarchar](50) NULL,
	[PJCNo] [nvarchar](50) NULL,
	[PJCYear] [nvarchar](50) NULL,
	[OperationNo] [nvarchar](50) NULL,
	[Process] [nvarchar](50) NULL,
	[ReworkPerformed_Ok] [float] NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL,
	[Remarks] [nvarchar](2000) NULL,
	[QualityReworkPerformedDetails_Pams] [nvarchar](2000) NULL,
	[ReworkDate] [datetime] NULL,
	[ReworkShift] [nvarchar](50) NULL,
	[ReworkOperator] [nvarchar](50) NULL,
	[ReworkPerformed_Qty] [nvarchar](50) NULL,
	[ReworkMachine] [nvarchar](50) NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[PJCReworkPerformedDetails_PAMS] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
