/****** Object:  Table [dbo].[programmanager]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[programmanager](
	[programid] [nvarchar](50) NOT NULL,
	[componentid] [nvarchar](50) NULL,
	[machineid] [nvarchar](50) NOT NULL,
	[updatedon] [smalldatetime] NULL,
	[operationno] [smallint] NULL,
	[programfile] [nvarchar](250) NULL,
	[Author] [nvarchar](50) NULL,
 CONSTRAINT [PK_Programmanager] PRIMARY KEY CLUSTERED 
(
	[programid] ASC,
	[machineid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[programmanager] ADD  CONSTRAINT [DF_programmanager_operationno]  DEFAULT ((0)) FOR [operationno]
