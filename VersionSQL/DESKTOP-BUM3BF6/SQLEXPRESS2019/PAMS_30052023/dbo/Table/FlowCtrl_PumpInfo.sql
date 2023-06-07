/****** Object:  Table [dbo].[FlowCtrl_PumpInfo]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[FlowCtrl_PumpInfo](
	[SLNO] [bigint] IDENTITY(1,1) NOT NULL,
	[Model] [nvarchar](50) NOT NULL,
	[Interfaceid] [int] NOT NULL,
	[Description] [nvarchar](50) NOT NULL,
	[Customer] [nvarchar](50) NOT NULL,
	[Speed] [int] NOT NULL,
	[CCRV] [int] NOT NULL,
	[RotationType] [nvarchar](50) NOT NULL,
	[TestingCycleStart] [int] NOT NULL,
	[TestingCycleEnd] [int] NOT NULL,
	[CycleIgnoreThreshold] [int] NOT NULL,
	[SpecifiedFlow] [float] NOT NULL,
	[CycleTime] [int] NOT NULL,
 CONSTRAINT [PK_FlowCtrl_PumpInfo] PRIMARY KEY CLUSTERED 
(
	[Model] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
