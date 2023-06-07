/****** Object:  Table [dbo].[FGOfferedQtyDetails_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[FGOfferedQtyDetails_Pams](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[PartID] [nvarchar](50) NULL,
	[PJCNo] [nvarchar](50) NULL,
	[PJCYear] [nvarchar](50) NULL,
	[Qty_OfferedToFG] [float] NULL,
	[OfferedDate] [date] NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[FGOfferedQtyDetails_Pams] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
