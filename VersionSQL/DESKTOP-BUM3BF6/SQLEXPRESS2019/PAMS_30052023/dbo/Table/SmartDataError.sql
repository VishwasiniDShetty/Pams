/****** Object:  Table [dbo].[SmartDataError]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[SmartDataError](
	[Winsock] [nvarchar](1000) NULL,
	[ErrNumber] [nvarchar](100) NULL,
	[ErrDescription] [nvarchar](100) NULL,
	[TimeStamp] [nvarchar](50) NULL,
	[Slno] [bigint] IDENTITY(1,1) NOT NULL
) ON [PRIMARY]
