/****** Object:  Table [dbo].[AndonConfigurator]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[AndonConfigurator](
	[MachineID] [nvarchar](50) NOT NULL,
	[Threshold] [int] NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[AndonConfigurator]  WITH CHECK ADD  CONSTRAINT [FK_AndonConfigurator_machineinformation] FOREIGN KEY([MachineID])
REFERENCES [dbo].[machineinformation] ([machineid])
ALTER TABLE [dbo].[AndonConfigurator] CHECK CONSTRAINT [FK_AndonConfigurator_machineinformation]
