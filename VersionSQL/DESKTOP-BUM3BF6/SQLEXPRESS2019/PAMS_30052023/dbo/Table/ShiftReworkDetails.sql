/****** Object:  Table [dbo].[ShiftReworkDetails]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ShiftReworkDetails](
	[ID] [bigint] NULL,
	[Rework_Qty] [int] NULL,
	[Rework_Reason] [nvarchar](150) NULL,
	[Slno] [bigint] IDENTITY(1,1) NOT NULL,
	[UpdatedBy] [nvarchar](50) NULL,
	[UpdatedTS] [datetime] NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[ShiftReworkDetails] ADD  CONSTRAINT [DF_ShiftReworkDetails_Rejection_Qty]  DEFAULT ((0)) FOR [Rework_Qty]
ALTER TABLE [dbo].[ShiftReworkDetails] ADD  DEFAULT ('pct') FOR [UpdatedBy]
ALTER TABLE [dbo].[ShiftReworkDetails] ADD  DEFAULT (getdate()) FOR [UpdatedTS]
ALTER TABLE [dbo].[ShiftReworkDetails]  WITH CHECK ADD  CONSTRAINT [FK_ShiftReworkDetails_ShiftProductionDetails] FOREIGN KEY([ID])
REFERENCES [dbo].[ShiftProductionDetails] ([ID])
ALTER TABLE [dbo].[ShiftReworkDetails] CHECK CONSTRAINT [FK_ShiftReworkDetails_ShiftProductionDetails]
