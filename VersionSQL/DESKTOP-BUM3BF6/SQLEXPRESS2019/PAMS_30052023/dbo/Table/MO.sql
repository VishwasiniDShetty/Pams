/****** Object:  Table [dbo].[MO]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[MO](
	[MONumber] [nvarchar](50) NULL,
	[MachineID] [nvarchar](50) NULL,
	[PartID] [nvarchar](50) NULL,
	[OperationNo] [nvarchar](50) NULL,
	[DateOfRequirement] [datetime] NULL,
	[MOStatus] [nvarchar](50) NULL,
	[FileModifiedDate] [datetime] NULL,
	[Status] [nvarchar](50) NULL,
	[LinkNo] [nvarchar](50) NULL,
	[Quantity] [nvarchar](50) NULL,
	[ProjectNumber] [nvarchar](50) NULL,
	[OpnDescription] [nvarchar](100) NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[MO] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
