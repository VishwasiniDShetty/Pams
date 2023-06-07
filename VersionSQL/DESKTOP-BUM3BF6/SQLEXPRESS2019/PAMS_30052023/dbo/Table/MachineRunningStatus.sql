/****** Object:  Table [dbo].[MachineRunningStatus]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[MachineRunningStatus](
	[MachineInterface] [nvarchar](50) NOT NULL,
	[sttime] [datetime] NULL,
	[ndtime] [datetime] NULL,
	[Datatype] [smallint] NULL,
	[ColorCode] [varchar](10) NULL,
 CONSTRAINT [PK_MachineRunningStatus] PRIMARY KEY CLUSTERED 
(
	[MachineInterface] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
