/****** Object:  Table [dbo].[MeasuringInstrumentMaster_IDM_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[MeasuringInstrumentMaster_IDM_Pams](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[ID_No] [nvarchar](2000) NULL,
	[Item] [nvarchar](2000) NULL,
	[Make] [nvarchar](50) NULL,
	[RangeMin] [float] NULL,
	[RangeMax] [float] NULL,
	[LeastCount] [nvarchar](50) NULL,
	[CalibrationFreq] [nvarchar](100) NULL,
	[PutToUseOn] [datetime] NULL,
	[Remarks] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
