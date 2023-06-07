/****** Object:  Table [dbo].[CustomerPODetailsTransaction_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[CustomerPODetailsTransaction_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[PODate] [date] NULL,
	[PONo] [nvarchar](100) NULL,
	[PartID] [nvarchar](100) NULL,
	[PartDescription] [nvarchar](500) NULL,
	[Customer] [nvarchar](100) NULL,
	[POStatus] [nvarchar](50) NULL,
	[Quantity] [float] NULL,
	[UOM] [nvarchar](50) NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL
) ON [PRIMARY]

SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-20230311-124051] ON [dbo].[CustomerPODetailsTransaction_PAMS]
(
	[PONo] ASC,
	[PartID] ASC,
	[PartDescription] ASC,
	[Customer] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-CustomerPODetailsTransaction_PAMS-20221109] ON [dbo].[CustomerPODetailsTransaction_PAMS]
(
	[PODate] ASC,
	[PONo] ASC,
	[PartID] ASC,
	[Customer] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
ALTER TABLE [dbo].[CustomerPODetailsTransaction_PAMS] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
