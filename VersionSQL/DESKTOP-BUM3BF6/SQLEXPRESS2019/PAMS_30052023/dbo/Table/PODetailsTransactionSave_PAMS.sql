/****** Object:  Table [dbo].[PODetailsTransactionSave_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[PODetailsTransactionSave_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[PONumber] [nvarchar](50) NULL,
	[Parameter] [nvarchar](100) NULL,
	[DisplayText] [nvarchar](4000) NULL,
	[DisplayType] [nvarchar](50) NULL,
	[Value] [nvarchar](100) NULL,
	[TextValue] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-20221109-165029] ON [dbo].[PODetailsTransactionSave_PAMS]
(
	[PONumber] ASC,
	[Parameter] ASC,
	[DisplayText] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
