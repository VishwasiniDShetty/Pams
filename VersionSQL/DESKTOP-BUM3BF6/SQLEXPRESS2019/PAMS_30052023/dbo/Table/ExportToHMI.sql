/****** Object:  Table [dbo].[ExportToHMI]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ExportToHMI](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[MachineID] [nvarchar](50) NOT NULL,
	[datastring] [nvarchar](max) NOT NULL,
	[userid] [nvarchar](50) NOT NULL,
	[processedTimeStamp] [datetime] NULL,
	[createTimeStamp] [datetime] NOT NULL,
	[dataType] [int] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

ALTER TABLE [dbo].[ExportToHMI] ADD  CONSTRAINT [DF_ExportToHMI_createTimeStamp]  DEFAULT (getdate()) FOR [createTimeStamp]
ALTER TABLE [dbo].[ExportToHMI] ADD  CONSTRAINT [DF_ExportToHMI_dataType]  DEFAULT ((1)) FOR [dataType]
