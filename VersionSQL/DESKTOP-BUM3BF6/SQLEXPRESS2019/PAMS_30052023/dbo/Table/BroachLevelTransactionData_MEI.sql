/****** Object:  Table [dbo].[BroachLevelTransactionData_MEI]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[BroachLevelTransactionData_MEI](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[MachineId] [nvarchar](50) NULL,
	[BroachId] [nvarchar](50) NULL,
	[BatchId] [bigint] NULL,
	[OperationNo] [nvarchar](50) NULL,
	[Operator] [nvarchar](50) NULL,
	[CycleStart] [datetime] NULL,
	[CycleEnd] [datetime] NULL,
	[ParameterId] [nvarchar](50) NULL,
	[ParameterValue] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL
) ON [PRIMARY]
