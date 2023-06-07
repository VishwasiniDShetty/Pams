/****** Object:  Table [dbo].[MaterialIssueDetails_IDM_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[MaterialIssueDetails_IDM_Pams](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[RequestDepartment] [nvarchar](50) NULL,
	[InchargeName] [nvarchar](50) NULL,
	[ItemName] [nvarchar](50) NULL,
	[ItemDescription] [nvarchar](500) NULL,
	[RequestedQty] [float] NULL,
	[RequestedTS] [datetime] NULL,
	[IssuedQty] [float] NULL,
	[IssuedBy] [nvarchar](50) NULL,
	[IssuedTS] [datetime] NULL,
	[IssuedLocation] [nvarchar](50) NULL,
	[ItemCategory] [nvarchar](50) NULL,
	[Remarks] [nvarchar](2000) NULL,
	[RequestToDepartment] [nvarchar](50) NULL
) ON [PRIMARY]

SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-20230311-141953] ON [dbo].[MaterialIssueDetails_IDM_Pams]
(
	[RequestDepartment] ASC,
	[ItemName] ASC,
	[ItemDescription] ASC,
	[IssuedLocation] ASC,
	[RequestToDepartment] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
ALTER TABLE [dbo].[MaterialIssueDetails_IDM_Pams] ADD  DEFAULT (getdate()) FOR [IssuedTS]
