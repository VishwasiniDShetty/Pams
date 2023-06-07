/****** Object:  Table [dbo].[Focas_WearOffsetCorrection]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Focas_WearOffsetCorrection](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Focas_WearOffsetCorrectionID] [int] NOT NULL,
	[MeasuredDimension] [float] NOT NULL,
	[NewWearOffsetValue] [float] NOT NULL,
	[MeasuredTime] [datetime] NOT NULL,
	[WearoffsetValue] [float] NOT NULL,
	[Result] [nvarchar](1000) NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[Focas_WearOffsetCorrection] ADD  DEFAULT (getdate()) FOR [MeasuredTime]
