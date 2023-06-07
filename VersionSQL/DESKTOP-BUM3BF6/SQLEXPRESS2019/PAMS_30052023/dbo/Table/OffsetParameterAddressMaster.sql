/****** Object:  Table [dbo].[OffsetParameterAddressMaster]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[OffsetParameterAddressMaster](
	[MachineType] [nvarchar](50) NULL,
	[OffsetType] [nvarchar](50) NULL,
	[ParameterName] [nvarchar](50) NULL,
	[StartAddress] [nvarchar](50) NULL,
	[EndAddress] [nvarchar](50) NULL
) ON [PRIMARY]
