/****** Object:  Table [dbo].[Focas_PMCSignalMaster]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Focas_PMCSignalMaster](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[ControlID] [nvarchar](50) NULL,
	[Address] [nvarchar](50) NULL,
	[Symbol] [nvarchar](100) NULL,
	[Description] [nvarchar](200) NULL
) ON [PRIMARY]
