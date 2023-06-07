/****** Object:  Table [dbo].[ProgramUploadToMachine]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ProgramUploadToMachine](
	[MachineID] [nvarchar](50) NOT NULL,
	[ProgramType] [nvarchar](50) NOT NULL,
	[ProgramName] [nvarchar](50) NOT NULL,
	[ComponentID] [nvarchar](50) NULL,
	[OperationNo] [int] NULL,
	[TimeStamp] [datetime] NOT NULL,
	[EmployeeID] [nvarchar](50) NULL
) ON [PRIMARY]
