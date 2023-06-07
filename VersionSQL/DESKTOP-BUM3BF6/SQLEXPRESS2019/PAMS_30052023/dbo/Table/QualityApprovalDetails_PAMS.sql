/****** Object:  Table [dbo].[QualityApprovalDetails_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[QualityApprovalDetails_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[PONumber] [nvarchar](50) NULL,
	[MaterialID] [nvarchar](50) NULL,
	[InvoiceNumber] [nvarchar](50) NULL,
	[GRNNo] [nvarchar](50) NULL,
	[MaterialType] [nvarchar](50) NULL,
	[TCNo] [nvarchar](50) NULL,
	[Status] [nvarchar](100) NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL,
	[ApprovedBy] [nvarchar](50) NULL,
	[ApprovedTS] [nvarchar](50) NULL,
	[Remarks] [nvarchar](2000) NULL,
	[FSUnique] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	[File1] [varbinary](max) FILESTREAM  NULL,
	[File2] [varbinary](max) FILESTREAM  NULL,
	[File3] [varbinary](max) FILESTREAM  NULL,
	[File1Name] [nvarchar](50) NULL,
	[File2Name] [nvarchar](50) NULL,
	[File3Name] [nvarchar](50) NULL,
	[RejQty] [float] NULL,
	[File4] [varbinary](max) FILESTREAM  NULL,
	[File4Name] [nvarchar](100) NULL,
UNIQUE NONCLUSTERED 
(
	[FSUnique] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] FILESTREAM_ON [FILESTREAM_grp]

ALTER TABLE [dbo].[QualityApprovalDetails_PAMS] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
ALTER TABLE [dbo].[QualityApprovalDetails_PAMS] ADD  DEFAULT (newid()) FOR [FSUnique]
