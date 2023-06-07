/****** Object:  Table [dbo].[PODetailsTransactionSave_IDM_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[PODetailsTransactionSave_IDM_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[PONumber] [nvarchar](50) NULL,
	[Parameter] [nvarchar](100) NULL,
	[DisplayText] [nvarchar](4000) NULL,
	[DisplayType] [nvarchar](50) NULL,
	[Value] [nvarchar](100) NULL,
	[TextValue] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
