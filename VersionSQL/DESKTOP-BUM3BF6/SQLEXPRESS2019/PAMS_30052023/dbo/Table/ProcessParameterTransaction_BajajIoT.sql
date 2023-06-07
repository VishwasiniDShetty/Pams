/****** Object:  Table [dbo].[ProcessParameterTransaction_BajajIoT]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ProcessParameterTransaction_BajajIoT](
	[IDD] [bigint] IDENTITY(1,1) NOT NULL,
	[MachineID] [nvarchar](50) NULL,
	[ParameterID] [nvarchar](50) NULL,
	[ParameterValue] [nvarchar](500) NULL,
	[UpdatedtimeStamp] [datetime] NULL,
	[MinValue] [float] NULL,
	[MaxValue] [float] NULL,
	[ComponentID] [nvarchar](50) NULL,
	[OperatorID] [nvarchar](50) NULL,
	[DataType] [nvarchar](50) NULL,
	[MinRegister] [nvarchar](100) NULL
) ON [PRIMARY]
