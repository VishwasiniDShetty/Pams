/****** Object:  Table [dbo].[VendorDCDetails_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[VendorDCDetails_PAMS](
	[Vendor] [nvarchar](50) NULL,
	[Pams_DcNo] [nvarchar](50) NULL,
	[MaterialType] [nvarchar](50) NULL,
	[VendorDCNo] [nvarchar](50) NULL,
	[FSUnique] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	[File1] [varbinary](max) FILESTREAM  NULL,
	[File1Name] [nvarchar](50) NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL,
	[FileID] [nvarchar](50) NULL,
UNIQUE NONCLUSTERED 
(
	[FSUnique] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] FILESTREAM_ON [FILESTREAM_grp]

ALTER TABLE [dbo].[VendorDCDetails_PAMS] ADD  DEFAULT (newid()) FOR [FSUnique]
ALTER TABLE [dbo].[VendorDCDetails_PAMS] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
