/****** Object:  Table [dbo].[VendorDetails_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[VendorDetails_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[VendorID] [nvarchar](100) NULL,
	[VendorName] [nvarchar](100) NULL,
	[Address] [nvarchar](max) NULL,
	[Place] [nvarchar](500) NULL,
	[ContactNumber] [nvarchar](100) NULL,
	[State] [nvarchar](100) NULL,
	[Country] [nvarchar](100) NULL,
	[PIN] [nvarchar](100) NULL,
	[Email] [nvarchar](max) NULL,
	[ContactPerson] [nvarchar](50) NULL,
	[IsActive] [bit] NULL,
	[Approval] [nvarchar](50) NULL,
	[Website] [nvarchar](1000) NULL,
	[Email_SysCapacity_Size] [nvarchar](1000) NULL,
	[Total_ManufacturingSpace] [nvarchar](1000) NULL,
	[Company_Status] [nvarchar](1000) NULL,
	[NumberOfSites] [nvarchar](1000) NULL,
	[Supplier_Rep] [nvarchar](1000) NULL,
	[DateOfAudit] [datetime] NULL,
	[AnnualSales_Value] [nvarchar](50) NULL,
	[Cuurency] [nvarchar](50) NULL,
	[PaymentTerms] [nvarchar](2000) NULL,
	[ShipmentTerms] [nvarchar](2000) NULL,
	[MajorCustomers] [nvarchar](500) NULL,
	[GSTNumber] [nvarchar](50) NULL,
	[PanNumber] [nvarchar](50) NULL,
	[FileName] [nvarchar](50) NULL,
	[FSUnique] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
	[File1] [varbinary](max) FILESTREAM  NULL,
	[PhoneNumber] [nvarchar](50) NULL,
	[Position] [nvarchar](50) NULL,
	[VendorType] [nvarchar](50) NULL,
UNIQUE NONCLUSTERED 
(
	[FSUnique] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY] FILESTREAM_ON [FILESTREAM_grp]

SET ANSI_PADDING ON

CREATE UNIQUE CLUSTERED INDEX [ClusteredIndex-20221109-165654] ON [dbo].[VendorDetails_PAMS]
(
	[VendorID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY] FILESTREAM_ON [FILESTREAM_grp]
ALTER TABLE [dbo].[VendorDetails_PAMS] ADD  DEFAULT ((0)) FOR [IsActive]
ALTER TABLE [dbo].[VendorDetails_PAMS] ADD  DEFAULT (newid()) FOR [FSUnique]
