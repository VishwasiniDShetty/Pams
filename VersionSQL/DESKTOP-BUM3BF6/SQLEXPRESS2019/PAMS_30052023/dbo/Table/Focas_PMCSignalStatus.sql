/****** Object:  Table [dbo].[Focas_PMCSignalStatus]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Focas_PMCSignalStatus](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[MachineID] [nvarchar](50) NOT NULL,
	[Address] [nvarchar](50) NOT NULL,
	[Value] [tinyint] NOT NULL,
	[InsertedTime] [datetime] NOT NULL
) ON [PRIMARY]
