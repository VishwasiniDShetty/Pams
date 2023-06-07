/****** Object:  Table [dbo].[MaterialRequestDetails_IDM_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[MaterialRequestDetails_IDM_PAMS](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[RequestDepartment] [nvarchar](50) NULL,
	[InchargeName] [nvarchar](50) NULL,
	[ItemName] [nvarchar](50) NULL,
	[ItemDescription] [nvarchar](500) NULL,
	[RequestedQty] [float] NULL,
	[RequestedTS] [datetime] NULL,
	[ItemCategory] [nvarchar](50) NULL,
	[Remarks] [nvarchar](2000) NULL,
	[ApprovedBy] [nvarchar](50) NULL,
	[RequestToDepartment] [nvarchar](50) NULL
) ON [PRIMARY]

SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-20230311-142050] ON [dbo].[MaterialRequestDetails_IDM_PAMS]
(
	[RequestDepartment] ASC,
	[ItemName] ASC,
	[ItemDescription] ASC,
	[ItemCategory] ASC,
	[RequestToDepartment] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
ALTER TABLE [dbo].[MaterialRequestDetails_IDM_PAMS] ADD  DEFAULT (getdate()) FOR [RequestedTS]
