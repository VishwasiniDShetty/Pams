/****** Object:  Table [dbo].[TPMTrakLog]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[TPMTrakLog](
	[ModuleName] [nvarchar](50) NULL,
	[ComputerName] [nvarchar](100) NULL,
	[UserName] [nvarchar](100) NULL,
	[LogDate] [datetime] NULL,
	[Remarks] [nvarchar](250) NULL
) ON [PRIMARY]
