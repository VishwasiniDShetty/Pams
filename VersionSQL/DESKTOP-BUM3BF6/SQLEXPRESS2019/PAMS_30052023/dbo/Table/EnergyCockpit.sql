/****** Object:  Table [dbo].[EnergyCockpit]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[EnergyCockpit](
	[dDate] [datetime] NOT NULL,
	[dShift] [smallint] NOT NULL,
	[dHour] [smallint] NOT NULL,
	[Starttime] [datetime] NOT NULL,
	[Endtime] [datetime] NOT NULL,
	[MachineID] [nvarchar](50) NOT NULL,
	[ProdTime] [int] NOT NULL,
	[pCount] [int] NULL,
	[Energy] [float] NOT NULL,
	[Cost] [float] NOT NULL,
	[PF] [float] NOT NULL,
	[Ampere] [float] NOT NULL,
	[KW] [float] NOT NULL,
 CONSTRAINT [PK_EnergyCockpit] PRIMARY KEY CLUSTERED 
(
	[dDate] ASC,
	[dShift] ASC,
	[dHour] ASC,
	[MachineID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
