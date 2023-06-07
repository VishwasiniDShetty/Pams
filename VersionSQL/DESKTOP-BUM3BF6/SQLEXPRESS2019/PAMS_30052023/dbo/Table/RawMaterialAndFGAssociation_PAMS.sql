/****** Object:  Table [dbo].[RawMaterialAndFGAssociation_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[RawMaterialAndFGAssociation_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[PartID] [nvarchar](100) NULL,
	[MaterialID] [nvarchar](100) NULL,
	[IsEnable] [int] NULL,
	[PartLength_mm] [float] NULL,
	[ConversionKGTo_1M] [float] NULL,
	[MaterialWeight_KG] [float] NULL,
	[CuttingAllowance] [float] NULL,
	[TotalLength] [float] NULL,
	[MaterialType] [nvarchar](50) NULL,
	[Remarks] [nvarchar](2000) NULL,
	[EndBitAllowance] [float] NULL
) ON [PRIMARY]

SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-20221109-165501] ON [dbo].[RawMaterialAndFGAssociation_PAMS]
(
	[PartID] ASC,
	[MaterialID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-20230124-091907] ON [dbo].[RawMaterialAndFGAssociation_PAMS]
(
	[PartID] ASC,
	[MaterialID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
ALTER TABLE [dbo].[RawMaterialAndFGAssociation_PAMS] ADD  DEFAULT ((1)) FOR [IsEnable]
