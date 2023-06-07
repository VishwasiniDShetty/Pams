/****** Object:  Table [dbo].[Production_Summary_Jina]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Production_Summary_Jina](
	[Date] [datetime] NOT NULL,
	[Shift] [nvarchar](50) NOT NULL,
	[Machine] [nvarchar](50) NOT NULL,
	[WorkOrderNumber] [nvarchar](50) NOT NULL,
	[Component] [nvarchar](50) NOT NULL,
	[Operation] [nvarchar](50) NOT NULL,
	[Operator] [nvarchar](50) NOT NULL,
	[Qty] [int] NULL,
	[TextValue1] [nvarchar](50) NULL,
	[TextValue2] [nvarchar](50) NULL,
	[CreatedDate] [datetime] NULL,
	[ModifiedDate] [datetime] NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[cycles] [int] NULL,
	[ReworkPerformed] [int] NULL,
 CONSTRAINT [PK_Production_Summary_Jina] PRIMARY KEY CLUSTERED 
(
	[Date] ASC,
	[Shift] ASC,
	[Machine] ASC,
	[WorkOrderNumber] ASC,
	[Component] ASC,
	[Operation] ASC,
	[Operator] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[Production_Summary_Jina] ADD  DEFAULT ((0)) FOR [cycles]
ALTER TABLE [dbo].[Production_Summary_Jina] ADD  DEFAULT ((0)) FOR [ReworkPerformed]
