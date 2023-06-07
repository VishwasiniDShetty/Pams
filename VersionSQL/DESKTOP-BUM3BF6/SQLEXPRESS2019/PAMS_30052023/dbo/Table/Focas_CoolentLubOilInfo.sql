/****** Object:  Table [dbo].[Focas_CoolentLubOilInfo]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Focas_CoolentLubOilInfo](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[MachineId] [nvarchar](50) NOT NULL,
	[CNCTimeStamp] [datetime] NOT NULL,
	[CoolentLevel] [decimal](18, 3) NOT NULL,
	[LubOilLevel] [decimal](18, 3) NOT NULL,
	[PrevCoolentLevel] [int] NULL,
	[PrevLubOilLevel] [int] NULL,
 CONSTRAINT [PK_Focas_CoolentLubOilInfo] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
