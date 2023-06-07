/****** Object:  Table [dbo].[ReworkDcDetails_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ReworkDcDetails_Pams](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[PartID] [nvarchar](50) NULL,
	[MJCNo] [nvarchar](50) NULL,
	[PJCNo] [nvarchar](50) NULL,
	[OperationNo] [nvarchar](50) NULL,
	[Process] [nvarchar](50) NULL,
	[Stage] [nvarchar](50) NULL,
	[PamsDCNo] [nvarchar](50) NULL,
	[Qty] [float] NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL,
	[PJCYear] [nvarchar](50) NULL
) ON [PRIMARY]
