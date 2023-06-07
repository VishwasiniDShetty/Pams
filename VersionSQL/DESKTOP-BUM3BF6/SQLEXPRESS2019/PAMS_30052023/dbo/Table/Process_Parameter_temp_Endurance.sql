/****** Object:  Table [dbo].[Process_Parameter_temp_Endurance]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Process_Parameter_temp_Endurance](
	[Slno] [bigint] IDENTITY(1,1) NOT NULL,
	[MachineId] [nvarchar](50) NULL,
	[DateTime] [datetime] NULL,
	[Cycle] [int] NULL,
	[Status] [int] NULL,
	[Lo_V] [float] NULL,
	[Hi_V] [float] NULL,
	[V_rise] [int] NULL,
	[Intensify] [int] NULL,
	[P_rise] [int] NULL,
	[Biscuit_Thick] [int] NULL,
	[Cast_Pressure] [int] NULL
) ON [PRIMARY]
