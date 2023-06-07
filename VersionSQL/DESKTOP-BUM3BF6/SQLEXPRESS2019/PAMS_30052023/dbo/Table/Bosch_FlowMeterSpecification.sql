/****** Object:  Table [dbo].[Bosch_FlowMeterSpecification]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Bosch_FlowMeterSpecification](
	[IDD] [int] IDENTITY(1,1) NOT NULL,
	[PartNumber] [nvarchar](50) NULL,
	[TypeDia] [nvarchar](50) NULL,
	[Angle] [float] NULL,
	[Height] [float] NULL,
	[HeightGauge] [nvarchar](50) NULL,
	[Pr] [float] NULL,
	[HeadMinFlowValue] [float] NULL,
	[HeadMaxFlowValue] [float] NULL,
	[HeadMedianValue] [float] NULL,
	[ShaftMinFlowValue] [float] NULL,
	[ShaftMaxFlowValue] [float] NULL,
	[BarrelInscription] [nvarchar](100) NULL,
	[HeadRotaFlowRemarks] [nvarchar](10) NULL,
	[ShaftRemarks] [nvarchar](10) NULL,
	[IsTGGType] [bit] NULL
) ON [PRIMARY]
