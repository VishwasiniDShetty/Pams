/****** Object:  Table [dbo].[PlantMachineGroups]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[PlantMachineGroups](
	[PlantID] [nvarchar](50) NULL,
	[MachineID] [nvarchar](50) NULL,
	[GroupID] [nvarchar](50) NULL,
	[GroupOrder] [int] NULL,
	[description] [nvarchar](100) NULL,
	[EndOfLineMachine] [nvarchar](50) NULL,
	[EndOfGroupMachine] [nvarchar](50) NULL,
	[MachineSequence] [int] NULL
) ON [PRIMARY]
