/****** Object:  Table [dbo].[MachineOEEFormula_Shanti]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[MachineOEEFormula_Shanti](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[MachineID] [nvarchar](50) NOT NULL,
	[OEEFormula] [nvarchar](50) NULL
) ON [PRIMARY]
