/****** Object:  Table [dbo].[RequestDetails_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[RequestDetails_Pams](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[Department] [nvarchar](50) NULL,
	[Vendor] [nvarchar](50) NULL,
	[Process] [nvarchar](2000) NULL,
	[MaterialID] [nvarchar](50) NULL,
	[PartID] [nvarchar](50) NULL,
	[RquestedID] [int] NULL,
	[RequestedNo] [nvarchar](50) NULL,
	[RequestedQty] [float] NULL,
	[RequestedBy] [nvarchar](50) NULL,
	[RequestedTS] [datetime] NULL,
	[ApprovedBy] [nvarchar](50) NULL,
	[ApprovedTS] [datetime] NULL,
	[Status] [nvarchar](50) NULL,
	[Remarks] [nvarchar](2000) NULL,
	[UOM] [nvarchar](50) NULL,
	[HoldRemarks] [nvarchar](2000) NULL,
	[ClosedRemarks] [nvarchar](2000) NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[RequestDetails_Pams] ADD  DEFAULT (getdate()) FOR [RequestedTS]
