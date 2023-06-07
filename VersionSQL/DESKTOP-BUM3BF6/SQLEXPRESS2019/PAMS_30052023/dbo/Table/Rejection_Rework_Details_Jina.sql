/****** Object:  Table [dbo].[Rejection_Rework_Details_Jina]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Rejection_Rework_Details_Jina](
	[Date] [datetime] NOT NULL,
	[Shift] [nvarchar](50) NOT NULL,
	[Machine] [nvarchar](50) NOT NULL,
	[WorkOrderNumber] [nvarchar](50) NOT NULL,
	[Component] [nvarchar](50) NOT NULL,
	[Operation] [nvarchar](50) NOT NULL,
	[Operator] [nvarchar](50) NOT NULL,
	[Rejection_Rework_flag] [nvarchar](50) NULL,
	[Person_flag] [nvarchar](50) NULL,
	[Code] [nvarchar](50) NULL,
	[Rejection_Rework_Qty] [int] NULL,
	[CreatedDate] [datetime] NULL,
	[ModifiedDate] [datetime] NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[ID] [int] IDENTITY(1,1) NOT NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[Rejection_Rework_Details_Jina]  WITH CHECK ADD  CONSTRAINT [FK] FOREIGN KEY([Date], [Shift], [Machine], [WorkOrderNumber], [Component], [Operation], [Operator])
REFERENCES [dbo].[Production_Summary_Jina] ([Date], [Shift], [Machine], [WorkOrderNumber], [Component], [Operation], [Operator])
ON UPDATE CASCADE
ON DELETE CASCADE
ALTER TABLE [dbo].[Rejection_Rework_Details_Jina] CHECK CONSTRAINT [FK]
