/****** Object:  Table [dbo].[EM_Machineinformation]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[EM_Machineinformation](
	[MachineId] [nvarchar](50) NULL,
	[interfaceid] [nvarchar](50) NULL,
	[IPAddress] [nvarchar](50) NULL,
	[PortNo] [nvarchar](50) NULL,
	[IsEnabled] [bit] NULL,
	[SortOrder] [int] NULL,
	[LowerPowerthreshold] [float] NULL,
	[description] [nvarchar](50) NULL,
	[MachineType] [nvarchar](50) NULL
) ON [PRIMARY]
