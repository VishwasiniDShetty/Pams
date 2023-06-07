/****** Object:  Table [dbo].[SmartDataStrings]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[SmartDataStrings](
	[Sno] [bigint] IDENTITY(1,1) NOT NULL,
	[DataString] [nvarchar](4000) NULL,
	[InTime] [datetime] NULL
) ON [PRIMARY]
