/****** Object:  Table [dbo].[ProcessParameterTransaction_BaluAuto]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ProcessParameterTransaction_BaluAuto](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[MachineID] [nvarchar](50) NULL,
	[ParameterID] [nvarchar](100) NULL,
	[Value] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL
) ON [PRIMARY]
