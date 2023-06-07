/****** Object:  Table [dbo].[RawData]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[RawData](
	[SlNo] [bigint] IDENTITY(1,1) NOT NULL,
	[DataType] [int] NULL,
	[IPAddress] [nvarchar](20) NULL,
	[Mc] [nvarchar](50) NULL,
	[Comp] [nvarchar](50) NULL,
	[Opn] [nvarchar](50) NULL,
	[Opr] [nvarchar](50) NULL,
	[SPLSTRING1] [int] NULL,
	[Sttime] [datetime] NULL,
	[Ndtime] [datetime] NULL,
	[SPLSTRING2] [nvarchar](4000) NULL,
	[Status] [int] NOT NULL,
	[WorkOrderNumber] [nvarchar](50) NOT NULL,
	[SPLString3] [nvarchar](500) NULL,
	[SPLString4] [nvarchar](50) NULL,
	[SPLString5] [nvarchar](50) NULL,
	[SPLString6] [nvarchar](50) NULL,
	[SPLString7] [nvarchar](50) NULL,
	[SPLString8] [nvarchar](50) NULL,
	[SPLString9] [nvarchar](50) NULL,
	[SPLString10] [nvarchar](50) NULL,
	[SPLString11] [bit] NULL
) ON [PRIMARY]

CREATE CLUSTERED INDEX [IX_RawdataSlno] ON [dbo].[RawData]
(
	[SlNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
ALTER TABLE [dbo].[RawData] ADD  DEFAULT ('0') FOR [WorkOrderNumber]
