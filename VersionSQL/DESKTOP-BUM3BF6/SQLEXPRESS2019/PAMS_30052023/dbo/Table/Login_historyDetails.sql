/****** Object:  Table [dbo].[Login_historyDetails]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Login_historyDetails](
	[ID] [numeric](18, 0) IDENTITY(1,1) NOT NULL,
	[Machine] [nvarchar](50) NULL,
	[RecordType] [numeric](18, 0) NULL,
	[Login_TS] [datetime] NULL,
	[LogOut_TS] [datetime] NULL,
	[Operator] [nvarchar](50) NULL
) ON [PRIMARY]
