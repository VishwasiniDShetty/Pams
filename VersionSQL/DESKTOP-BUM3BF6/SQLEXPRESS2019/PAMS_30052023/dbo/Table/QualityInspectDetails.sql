/****** Object:  Table [dbo].[QualityInspectDetails]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[QualityInspectDetails](
	[MachineId] [nvarchar](50) NULL,
	[ComponentID] [nvarchar](50) NULL,
	[OperationNO] [nvarchar](50) NULL,
	[WorkOrderNo] [nvarchar](50) NULL,
	[Status] [int] NULL,
	[CreatedTS] [datetime] NULL,
	[Date] [datetime] NULL,
	[Shift] [nvarchar](50) NULL
) ON [PRIMARY]
