/****** Object:  Table [dbo].[InvoiceFileDetails_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[InvoiceFileDetails_PAMS](
	[Supplier] [nvarchar](50) NULL,
	[PONumber] [nvarchar](50) NULL,
	[MaterialType] [nvarchar](50) NULL,
	[InvoiceNumber] [nvarchar](50) NULL,
	[FSUnique] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	[File1] [varbinary](max) FILESTREAM  NULL,
	[File1Name] [nvarchar](50) NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL,
	[InvoiceDate] [datetime] NULL,
	[FileID] [nvarchar](50) NULL,
UNIQUE NONCLUSTERED 
(
	[FSUnique] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] FILESTREAM_ON [FILESTREAM_grp]

SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-20230311-181853] ON [dbo].[InvoiceFileDetails_PAMS]
(
	[Supplier] ASC,
	[PONumber] ASC,
	[InvoiceNumber] ASC,
	[File1Name] ASC,
	[InvoiceDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
CREATE NONCLUSTERED COLUMNSTORE INDEX [NonClusteredColumnStoreIndex-20230511-125038] ON [dbo].[InvoiceFileDetails_PAMS]
(
	[Supplier],
	[PONumber],
	[InvoiceNumber],
	[File1Name],
	[InvoiceDate]
)WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0, DATA_COMPRESSION = COLUMNSTORE) ON [PRIMARY]
ALTER TABLE [dbo].[InvoiceFileDetails_PAMS] ADD  DEFAULT (newid()) FOR [FSUnique]
ALTER TABLE [dbo].[InvoiceFileDetails_PAMS] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
