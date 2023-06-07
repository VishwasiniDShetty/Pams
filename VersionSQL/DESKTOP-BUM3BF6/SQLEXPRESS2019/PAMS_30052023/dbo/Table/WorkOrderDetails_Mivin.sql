/****** Object:  Table [dbo].[WorkOrderDetails_Mivin]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[WorkOrderDetails_Mivin](
	[DataType] [nvarchar](50) NULL,
	[Machineid] [nvarchar](50) NULL,
	[ComponentID] [nvarchar](50) NULL,
	[SlNo] [nvarchar](50) NULL,
	[slno2] [nvarchar](50) NULL,
	[updatedts] [datetime] NULL,
	[WorkOrder] [nvarchar](50) NULL,
	[operation] [nvarchar](50) NULL
) ON [PRIMARY]
