/****** Object:  Table [dbo].[PressureGuagesMaster_IDM_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[PressureGuagesMaster_IDM_Pams](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[ID_No] [nvarchar](2000) NULL,
	[Make] [nvarchar](50) NULL,
	[Location] [nvarchar](100) NULL,
	[Instrument_Range] [nvarchar](500) NULL,
	[Instrument_LSL] [float] NULL,
	[Instrument_USL] [float] NULL,
	[Category] [nvarchar](50) NULL,
	[Operating_MinValue] [float] NULL,
	[Operating_MaxValue] [float] NULL,
	[Tolerance] [float] NULL,
	[AcceptableCriteria] [float] NULL,
	[RequiredLeastCount] [float] NULL,
	[ActualLeastCount] [float] NULL,
	[Calibration_Freq] [nvarchar](100) NULL,
	[ErrorObserved] [nvarchar](50) NULL,
	[Status] [nvarchar](50) NULL,
	[PartID] [nvarchar](50) NULL,
	[PutToUseOn] [datetime] NULL
) ON [PRIMARY]
