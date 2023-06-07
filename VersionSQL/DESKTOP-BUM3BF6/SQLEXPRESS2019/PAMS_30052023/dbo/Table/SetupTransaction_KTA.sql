/****** Object:  Table [dbo].[SetupTransaction_KTA]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[SetupTransaction_KTA](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[mc] [nvarchar](50) NULL,
	[comp] [nvarchar](50) NULL,
	[opn] [nvarchar](50) NULL,
	[opr] [nvarchar](50) NULL,
	[SetupStartTime] [datetime] NULL,
	[SetupEndTime] [datetime] NULL
) ON [PRIMARY]
