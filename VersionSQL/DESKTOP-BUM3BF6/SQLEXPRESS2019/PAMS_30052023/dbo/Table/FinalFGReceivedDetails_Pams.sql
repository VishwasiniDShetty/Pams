/****** Object:  Table [dbo].[FinalFGReceivedDetails_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[FinalFGReceivedDetails_Pams](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[PartID] [nvarchar](50) NULL,
	[PjcNo] [nvarchar](50) NULL,
	[PJCYear] [nvarchar](50) NULL,
	[FinalReceivedFGQty] [float] NULL,
	[Date] [datetime] NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL,
	[Remarks] [nvarchar](2000) NULL
) ON [PRIMARY]
