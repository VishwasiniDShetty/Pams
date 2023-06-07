/****** Object:  Table [dbo].[FinalInspectionTransactionFGLevel_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[FinalInspectionTransactionFGLevel_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[Process] [nvarchar](2000) NULL,
	[ReportType] [nvarchar](50) NULL,
	[ProcessType] [nvarchar](50) NULL,
	[ComponentID] [nvarchar](50) NULL,
	[OperationNo] [nvarchar](50) NULL,
	[PJCNo] [nvarchar](50) NULL,
	[PJCYear] [nvarchar](10) NULL,
	[Status] [nvarchar](50) NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL,
	[Date] [datetime] NULL,
	[BatchBit] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
