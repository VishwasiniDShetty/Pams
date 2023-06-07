/****** Object:  Table [dbo].[PJCMarkedForReworkDetails_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[PJCMarkedForReworkDetails_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[Date] [datetime] NULL,
	[Shift] [nvarchar](50) NULL,
	[PartID] [nvarchar](50) NULL,
	[MjcNo] [nvarchar](50) NULL,
	[PJCNo] [nvarchar](50) NULL,
	[PJCYear] [nvarchar](50) NULL,
	[OperationNo] [nvarchar](50) NULL,
	[MarkedForReworkQty] [float] NULL,
	[OKQty] [float] NULL,
	[RejectionQty] [float] NULL,
	[ReworkReason] [nvarchar](100) NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL,
	[Process] [nvarchar](50) NULL,
	[Machineid] [nvarchar](50) NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[PJCMarkedForReworkDetails_PAMS] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
