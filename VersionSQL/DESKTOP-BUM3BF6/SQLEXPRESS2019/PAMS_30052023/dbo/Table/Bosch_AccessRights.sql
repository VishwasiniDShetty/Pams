/****** Object:  Table [dbo].[Bosch_AccessRights]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Bosch_AccessRights](
	[PlantID] [nvarchar](50) NULL,
	[MachineID] [nvarchar](50) NULL,
	[Flag] [bit] NULL,
	[Report] [nvarchar](200) NULL
) ON [PRIMARY]
