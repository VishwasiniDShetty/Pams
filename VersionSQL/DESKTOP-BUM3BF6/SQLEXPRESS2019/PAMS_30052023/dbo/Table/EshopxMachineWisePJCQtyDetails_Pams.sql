/****** Object:  Table [dbo].[EshopxMachineWisePJCQtyDetails_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[EshopxMachineWisePJCQtyDetails_Pams](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[MachineID] [nvarchar](50) NULL,
	[PJCNo] [nvarchar](50) NULL,
	[PJCYear] [nvarchar](20) NULL,
	[PalletNo] [nvarchar](50) NULL,
	[PJCTargetQty] [float] NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[EshopxMachineWisePJCQtyDetails_Pams] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
