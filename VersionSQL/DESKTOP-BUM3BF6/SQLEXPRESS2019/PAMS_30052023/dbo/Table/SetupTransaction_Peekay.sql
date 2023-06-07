/****** Object:  Table [dbo].[SetupTransaction_Peekay]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[SetupTransaction_Peekay](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[mc] [nvarchar](50) NULL,
	[comp] [nvarchar](50) NULL,
	[opn] [nvarchar](50) NULL,
	[RecordType] [nvarchar](50) NULL,
	[EventID] [nvarchar](50) NULL,
	[EventTS] [datetime] NULL,
	[WorkOrderNo] [nvarchar](50) NULL,
	[Opr] [nvarchar](50) NULL
) ON [PRIMARY]
