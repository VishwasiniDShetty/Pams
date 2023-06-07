/****** Object:  Table [dbo].[ProductionCountException]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ProductionCountException](
	[MachineID] [nvarchar](50) NULL,
	[ComponentID] [nvarchar](50) NULL,
	[OperationNo] [int] NULL,
	[StartTime] [datetime] NULL,
	[EndTime] [datetime] NULL,
	[IdealCount] [int] NULL,
	[ActualCount] [int] NULL,
	[SlNo] [numeric](19, 0) IDENTITY(1,1) NOT NULL
) ON [PRIMARY]
