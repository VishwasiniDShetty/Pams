/****** Object:  Table [dbo].[InspectionAutodata]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[InspectionAutodata](
	[MC] [nvarchar](50) NULL,
	[COMP] [nvarchar](50) NULL,
	[OPN] [nvarchar](50) NULL,
	[FeatureID] [nvarchar](50) NULL,
	[ParameterID] [nvarchar](50) NULL,
	[ActualValue] [decimal](18, 4) NULL,
	[Actualtime] [datetime] NULL,
	[SampleID] [bigint] NULL,
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[MoNo] [nvarchar](25) NULL,
	[Remarks] [nchar](200) NULL,
	[Operator] [nvarchar](100) NULL,
	[IsProcessed] [int] NOT NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[InspectionAutodata] ADD  DEFAULT ((0)) FOR [IsProcessed]
