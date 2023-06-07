/****** Object:  Table [dbo].[ShiftRejectionDetails]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ShiftRejectionDetails](
	[ID] [bigint] NULL,
	[Rejection_Qty] [int] NULL,
	[Rejection_Reason] [nvarchar](150) NULL,
	[Slno] [bigint] IDENTITY(1,1) NOT NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[ShiftRejectionDetails] ADD  CONSTRAINT [DF_ShiftRejectionDetails_Rejection_Qty]  DEFAULT ((0)) FOR [Rejection_Qty]
ALTER TABLE [dbo].[ShiftRejectionDetails] ADD  DEFAULT ('pct') FOR [UpdatedBy]
ALTER TABLE [dbo].[ShiftRejectionDetails] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
ALTER TABLE [dbo].[ShiftRejectionDetails]  WITH CHECK ADD  CONSTRAINT [FK_ShiftRejectionDetails_ShiftProductionDetails] FOREIGN KEY([ID])
REFERENCES [dbo].[ShiftProductionDetails] ([ID])
ALTER TABLE [dbo].[ShiftRejectionDetails] CHECK CONSTRAINT [FK_ShiftRejectionDetails_ShiftProductionDetails]
