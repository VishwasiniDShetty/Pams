/****** Object:  Table [dbo].[BroachLevelMasterData_MEI]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[BroachLevelMasterData_MEI](
	[MachineId] [nvarchar](50) NULL,
	[BroachId] [nvarchar](50) NULL,
	[OperationNo] [nvarchar](50) NULL,
	[ParameterId] [nvarchar](50) NULL,
	[ParameterDescription] [nvarchar](100) NULL,
	[MacroNo] [nvarchar](50) NULL,
	[Location] [nvarchar](50) NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL
) ON [PRIMARY]
