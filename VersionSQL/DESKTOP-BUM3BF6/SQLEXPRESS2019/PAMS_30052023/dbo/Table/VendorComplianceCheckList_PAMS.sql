/****** Object:  Table [dbo].[VendorComplianceCheckList_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[VendorComplianceCheckList_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[Code] [nvarchar](50) NULL,
	[Name] [nvarchar](100) NULL,
	[Particulars] [nvarchar](2000) NULL,
	[FileName] [nvarchar](50) NULL,
	[FSUnique] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	[File1] [varbinary](max) FILESTREAM  NULL,
	[Remarks] [nvarchar](1000) NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL,
	[Date] [datetime] NULL,
	[FinalRemarks] [nvarchar](50) NULL,
	[Type] [nvarchar](50) NULL,
	[Address] [nvarchar](max) NULL,
UNIQUE NONCLUSTERED 
(
	[FSUnique] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY] FILESTREAM_ON [FILESTREAM_grp]

ALTER TABLE [dbo].[VendorComplianceCheckList_PAMS] ADD  DEFAULT (newid()) FOR [FSUnique]
ALTER TABLE [dbo].[VendorComplianceCheckList_PAMS] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
ALTER TABLE [dbo].[VendorComplianceCheckList_PAMS] ADD  DEFAULT (getdate()) FOR [Date]
