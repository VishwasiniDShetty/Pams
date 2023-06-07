/****** Object:  Table [dbo].[ProcessAndFGAssociation_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ProcessAndFGAssociation_PAMS](
	[RowID] [bigint] IDENTITY(1,1) NOT NULL,
	[Process] [nvarchar](4000) NULL,
	[PartID] [nvarchar](50) NULL,
	[Checked] [int] NULL,
	[DCType] [nvarchar](50) NULL,
	[Sequence] [int] NULL,
	[DisplayPamsDCNo] [int] NULL
) ON [PRIMARY]

SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-20221109-165105] ON [dbo].[ProcessAndFGAssociation_PAMS]
(
	[Process] ASC,
	[PartID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-ProcessAndFGAssociation_PAMS-20230124] ON [dbo].[ProcessAndFGAssociation_PAMS]
(
	[Process] ASC,
	[PartID] ASC,
	[DCType] ASC,
	[Sequence] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
ALTER TABLE [dbo].[ProcessAndFGAssociation_PAMS] ADD  DEFAULT ((1)) FOR [Checked]
