/****** Object:  Table [dbo].[InspectionReadyDetailsSave_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[InspectionReadyDetailsSave_Pams](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[PartID] [nvarchar](50) NULL,
	[OperationNo] [nvarchar](50) NULL,
	[PJCNo] [nvarchar](50) NULL,
	[PJCYear] [nvarchar](50) NULL,
	[AcceptedQty] [float] NULL,
	[RejQty] [float] NULL,
	[ReworkQty] [float] NULL,
	[UpdatedByProduction] [nvarchar](50) NULL,
	[UpdatedTSProduction] [datetime] NULL,
	[UpdatedByQuality] [nvarchar](50) NULL,
	[UpdatedTSQuality] [datetime] NULL,
	[BatchBit] [int] NULL,
	[AcptQtyForInspection] [float] NULL,
	[PendingQtyForInspection] [float] NULL,
	[MJCNo] [nvarchar](50) NULL,
	[AcceptedQtyFromInspection] [float] NULL,
	[ConfirmedReceiveQty] [float] NULL,
	[PJCAutoID] [bigint] NULL,
	[OfferedToFGQty] [float] NULL
) ON [PRIMARY]
