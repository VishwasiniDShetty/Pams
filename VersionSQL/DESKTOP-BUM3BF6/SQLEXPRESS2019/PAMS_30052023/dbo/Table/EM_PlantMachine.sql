/****** Object:  Table [dbo].[EM_PlantMachine]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[EM_PlantMachine](
	[PlantID] [nvarchar](50) NULL,
	[MachineID] [nvarchar](50) NULL,
	[SortOrder] [int] NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[EM_PlantMachine]  WITH CHECK ADD  CONSTRAINT [FK_EM_PlantMachine_PlantInformation1] FOREIGN KEY([PlantID])
REFERENCES [dbo].[PlantInformation] ([PlantID])
ALTER TABLE [dbo].[EM_PlantMachine] CHECK CONSTRAINT [FK_EM_PlantMachine_PlantInformation1]
