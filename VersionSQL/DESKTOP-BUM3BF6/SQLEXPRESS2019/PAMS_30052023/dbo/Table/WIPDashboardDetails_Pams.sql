/****** Object:  Table [dbo].[WIPDashboardDetails_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[WIPDashboardDetails_Pams](
	[PartId] [nvarchar](50) NULL,
	[Process] [nvarchar](50) NULL,
	[Customer] [nvarchar](50) NULL,
	[Qty] [float] NULL,
	[StoreQty] [float] NULL,
	[RejectionQty] [float] NULL,
	[ReworkQty] [float] NULL,
	[Color] [nvarchar](50) NULL,
	[PartName] [nvarchar](2000) NULL
) ON [PRIMARY]
