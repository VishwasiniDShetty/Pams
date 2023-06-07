/****** Object:  Table [dbo].[PJCProductionEditedDetails_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[PJCProductionEditedDetails_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[PartID] [nvarchar](50) NULL,
	[OperationNo] [nvarchar](50) NULL,
	[PJCYear] [nvarchar](10) NULL,
	[PJCNo] [nvarchar](50) NULL,
	[Date] [datetime] NULL,
	[Prod_Qty] [float] NULL,
	[ReworkQty] [float] NULL,
	[RejQty] [float] NULL,
	[AcceptedQty] [float] NULL,
	[QualityIncharge] [nvarchar](50) NULL,
	[Quality_TS] [datetime] NULL,
	[LineIncharge] [nvarchar](50) NULL,
	[LineIncharge_TS] [datetime] NULL,
	[FinishedOpn] [nvarchar](50) NULL,
	[Shift] [nvarchar](50) NULL,
	[PendingQtyForInspection] [float] NULL,
	[MJCNo] [nvarchar](50) NULL,
	[QualityStatus] [nvarchar](50) NULL,
	[LineInchargeStatus] [nvarchar](50) NULL,
	[Process] [nvarchar](50) NULL,
	[Machineid] [nvarchar](50) NULL,
	[DummyCycle] [float] NULL
) ON [PRIMARY]
