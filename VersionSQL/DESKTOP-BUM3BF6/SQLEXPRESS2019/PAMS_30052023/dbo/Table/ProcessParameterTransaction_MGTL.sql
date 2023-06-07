/****** Object:  Table [dbo].[ProcessParameterTransaction_MGTL]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ProcessParameterTransaction_MGTL](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[MachineID] [nvarchar](50) NULL,
	[ParameterID] [int] NULL,
	[ParameterBitType] [nvarchar](50) NULL,
	[UpdatedtimeStamp] [datetime] NULL,
	[ParameterBitColumn] [nvarchar](50) NULL
) ON [PRIMARY]
