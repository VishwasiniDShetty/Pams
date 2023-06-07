/****** Object:  Table [dbo].[MOSchedule]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[MOSchedule](
	[MONumber] [nvarchar](50) NOT NULL,
	[MachineID] [nvarchar](50) NOT NULL,
	[PartID] [nvarchar](50) NOT NULL,
	[OperationNo] [nvarchar](50) NOT NULL,
	[Quantity] [nvarchar](50) NULL,
	[DateOfRequirement] [datetime] NULL,
	[MOStatus] [nvarchar](50) NULL,
	[FileName] [nvarchar](1000) NULL,
	[FileModifiedDate] [datetime] NULL,
	[Status] [nvarchar](50) NULL,
	[LinkNo] [nvarchar](50) NULL,
	[MOFlag] [nvarchar](50) NULL,
	[DrawingNumber] [nvarchar](1000) NULL,
	[ProgramNumber] [nvarchar](1000) NULL,
	[ControlPlanning] [nvarchar](1000) NULL,
	[LastModifiedDate] [datetime] NULL,
	[OperationInstruction] [nvarchar](100) NULL,
	[ProjectNumber] [nvarchar](50) NULL,
	[OpnDescription] [nvarchar](100) NULL,
	[ProcessSheet] [nvarchar](50) NULL
) ON [PRIMARY]
