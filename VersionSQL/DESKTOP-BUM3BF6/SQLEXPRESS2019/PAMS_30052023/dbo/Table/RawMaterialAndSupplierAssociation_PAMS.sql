/****** Object:  Table [dbo].[RawMaterialAndSupplierAssociation_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[RawMaterialAndSupplierAssociation_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[MaterialID] [nvarchar](50) NULL,
	[SupplierID] [nvarchar](50) NULL,
	[IsEnable] [bit] NULL
) ON [PRIMARY]

SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-20230124-091938] ON [dbo].[RawMaterialAndSupplierAssociation_PAMS]
(
	[MaterialID] ASC,
	[SupplierID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
ALTER TABLE [dbo].[RawMaterialAndSupplierAssociation_PAMS] ADD  DEFAULT ((1)) FOR [IsEnable]
