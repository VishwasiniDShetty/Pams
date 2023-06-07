/****** Object:  Table [dbo].[ProcessJobCardHeaderCreation_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ProcessJobCardHeaderCreation_PAMS](
	[GRNNo] [nvarchar](50) NULL,
	[PartID] [nvarchar](50) NULL,
	[MJCNo] [nvarchar](50) NULL,
	[PJCNo] [int] NULL,
	[IssuedQty] [float] NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL,
	[PJCYear] [nvarchar](4) NULL,
	[PJCDate] [datetime] NULL,
	[PJCId] [int] NULL,
	[FinancialYear] [nvarchar](10) NULL,
	[PJCStatus] [nvarchar](50) NULL,
	[StoreIncharge_Approval] [nvarchar](50) NULL,
	[SQE_Approval] [nvarchar](50) NULL,
	[ProductionIncharge_Approval] [nvarchar](50) NULL,
	[ProductionRemarks] [nvarchar](2000) NULL,
	[InspectionRemarks] [nvarchar](2000) NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[ProcessJobCardHeaderCreation_PAMS] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
ALTER TABLE [dbo].[ProcessJobCardHeaderCreation_PAMS] ADD  DEFAULT ('Open') FOR [PJCStatus]
