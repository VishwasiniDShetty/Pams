/****** Object:  Table [dbo].[PlantEmployee]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[PlantEmployee](
	[PlantID] [nvarchar](50) NOT NULL,
	[EmployeeID] [nvarchar](25) NOT NULL,
	[FromTime] [datetime] NULL,
	[ToTime] [datetime] NULL,
	[SlNo] [int] IDENTITY(1,1) NOT NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[PlantEmployee]  WITH CHECK ADD  CONSTRAINT [FK_PlantEmployee_PlantInformation] FOREIGN KEY([PlantID])
REFERENCES [dbo].[PlantInformation] ([PlantID])
ALTER TABLE [dbo].[PlantEmployee] CHECK CONSTRAINT [FK_PlantEmployee_PlantInformation]
