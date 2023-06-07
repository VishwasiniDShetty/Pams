/****** Object:  Table [dbo].[Cell]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Cell](
	[CellId] [nvarchar](50) NOT NULL,
	[Discription] [nvarchar](150) NULL,
	[PEGreen] [smallint] NOT NULL,
	[PERed] [smallint] NOT NULL,
	[AEGreen] [smallint] NOT NULL,
	[AERed] [smallint] NOT NULL,
	[OEGreen] [smallint] NOT NULL,
	[OERed] [smallint] NOT NULL,
	[PlantID] [nvarchar](50) NULL,
 CONSTRAINT [PK_Cell] PRIMARY KEY CLUSTERED 
(
	[CellId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[Cell] ADD  CONSTRAINT [DF_Cell_PEGreen]  DEFAULT ((85)) FOR [PEGreen]
ALTER TABLE [dbo].[Cell] ADD  CONSTRAINT [DF_Cell_PERed]  DEFAULT ((70)) FOR [PERed]
ALTER TABLE [dbo].[Cell] ADD  CONSTRAINT [DF_Cell_AEGreen]  DEFAULT ((95)) FOR [AEGreen]
ALTER TABLE [dbo].[Cell] ADD  CONSTRAINT [DF_Cell_AERed]  DEFAULT ((85)) FOR [AERed]
ALTER TABLE [dbo].[Cell] ADD  CONSTRAINT [DF_Cell_OEGreen]  DEFAULT ((80)) FOR [OEGreen]
ALTER TABLE [dbo].[Cell] ADD  CONSTRAINT [DF_Cell_OERed]  DEFAULT ((65)) FOR [OERed]
