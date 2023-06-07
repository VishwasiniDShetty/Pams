/****** Object:  Table [dbo].[SPCAutodata]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[SPCAutodata](
	[Mc] [nvarchar](50) NOT NULL,
	[Comp] [nvarchar](50) NULL,
	[Opn] [nvarchar](50) NULL,
	[Opr] [nvarchar](50) NULL,
	[Dimension] [nvarchar](50) NOT NULL,
	[Value] [float] NOT NULL,
	[Timestamp] [datetime] NOT NULL,
	[BatchTS] [datetime] NULL,
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[WearOffSetNumber] [nvarchar](50) NULL,
	[MeasureDimension] [nvarchar](50) NULL,
	[CorrectionValue] [nvarchar](50) NULL,
	[MONumber] [nvarchar](50) NULL,
	[BatchID] [nvarchar](50) NULL,
	[InstrumentNo] [nvarchar](50) NULL,
	[Remarks] [nvarchar](50) NULL,
	[InspectionType] [nvarchar](50) NULL,
	[SerialNumber] [nvarchar](50) NULL,
	[LotNumber] [nvarchar](50) NULL,
	[OvalityMin] [nvarchar](50) NULL,
	[OvalityMax] [nvarchar](50) NULL,
	[ToolChangeTime] [datetime] NULL,
	[IgnoreForCPCPK] [bit] NULL
) ON [PRIMARY]

SET ANSI_PADDING ON

CREATE UNIQUE CLUSTERED INDEX [IX_SPCAutodata] ON [dbo].[SPCAutodata]
(
	[Mc] ASC,
	[Timestamp] DESC,
	[Dimension] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-20220113-SpcAutoData] ON [dbo].[SPCAutodata]
(
	[Mc] ASC,
	[Comp] ASC,
	[Opn] ASC,
	[Opr] ASC,
	[Dimension] ASC,
	[Timestamp] ASC,
	[BatchTS] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
