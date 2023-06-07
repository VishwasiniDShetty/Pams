/****** Object:  Table [dbo].[RunningMachineDetails_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[RunningMachineDetails_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[MachineID] [nvarchar](50) NULL,
	[MachineInterface] [nvarchar](10) NULL,
	[ComponentID] [nvarchar](50) NULL,
	[CompInterface] [nvarchar](10) NULL,
	[OperationNo] [nvarchar](10) NULL,
	[OpnInterface] [nvarchar](10) NULL,
	[EmployeeID] [nvarchar](50) NULL,
	[OprInterfaceID] [nvarchar](10) NULL,
	[PJCNo] [nvarchar](20) NULL,
	[PJCYear] [nvarchar](10) NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL,
	[PalletNo] [int] NULL,
	[SyncedStatus] [int] NULL,
	[PalletPartsCount] [int] NULL,
	[PJCTargetQty] [int] NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[RunningMachineDetails_PAMS] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
ALTER TABLE [dbo].[RunningMachineDetails_PAMS] ADD  DEFAULT ((0)) FOR [PJCTargetQty]
