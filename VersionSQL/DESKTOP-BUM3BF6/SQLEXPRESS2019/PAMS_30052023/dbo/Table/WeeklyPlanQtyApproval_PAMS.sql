/****** Object:  Table [dbo].[WeeklyPlanQtyApproval_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[WeeklyPlanQtyApproval_PAMS](
	[ROwid] [bigint] IDENTITY(1,1) NOT NULL,
	[CustomerID] [nvarchar](50) NULL,
	[PartID] [nvarchar](50) NULL,
	[Year] [nvarchar](4) NULL,
	[MonthValue] [nvarchar](4) NULL,
	[WeekNumber] [nvarchar](4) NULL,
	[RemarksByPPC] [nvarchar](2000) NULL,
	[RemarksByProduction] [nvarchar](2000) NULL,
	[RemarksByProductionSupervisor] [nvarchar](2000) NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[WeeklyPlanQtyApproval_PAMS] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
