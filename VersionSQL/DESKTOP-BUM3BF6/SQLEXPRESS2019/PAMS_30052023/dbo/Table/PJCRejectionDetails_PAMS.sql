/****** Object:  Table [dbo].[PJCRejectionDetails_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[PJCRejectionDetails_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[Date] [datetime] NULL,
	[Shift] [nvarchar](50) NULL,
	[PartID] [nvarchar](50) NULL,
	[MjcNo] [nvarchar](50) NULL,
	[PJCNo] [nvarchar](50) NULL,
	[PJCYear] [nvarchar](50) NULL,
	[OperationNo] [nvarchar](50) NULL,
	[RejectionQty] [float] NULL,
	[RejectionReason] [nvarchar](100) NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL,
	[Process] [nvarchar](50) NULL,
	[Machineid] [nvarchar](50) NULL,
	[Rework_Rej_Bit] [int] NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[PJCRejectionDetails_PAMS] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
