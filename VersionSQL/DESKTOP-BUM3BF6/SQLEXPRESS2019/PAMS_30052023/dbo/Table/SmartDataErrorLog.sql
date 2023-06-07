/****** Object:  Table [dbo].[SmartDataErrorLog]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[SmartDataErrorLog](
	[RawdataID] [bigint] NULL,
	[IPAddress] [nvarchar](20) NULL,
	[Mc] [nvarchar](50) NULL,
	[ErrorMsg] [nvarchar](500) NULL,
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[TimeStamp] [datetime] NULL
) ON [PRIMARY]
