/****** Object:  Table [dbo].[Focas_OffsetVariables]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Focas_OffsetVariables](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[MachineID] [nvarchar](50) NOT NULL,
	[OffsetAxis] [nvarchar](50) NOT NULL,
	[StartLocation] [nvarchar](50) NOT NULL,
	[EndLocation] [nvarchar](50) NOT NULL
) ON [PRIMARY]
