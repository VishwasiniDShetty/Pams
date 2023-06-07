/****** Object:  Table [dbo].[CalibrationHistoryDetails_IDM_Pams]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[CalibrationHistoryDetails_IDM_Pams](
	[AutoID] [bigint] IDENTITY(1,1) NOT NULL,
	[ItemCategory] [nvarchar](50) NULL,
	[IDMType] [nvarchar](50) NULL,
	[IDMItemType] [nvarchar](50) NULL,
	[ID_No] [nvarchar](50) NULL,
	[InstrumentName] [nvarchar](50) NULL,
	[InstrumentNo] [nvarchar](50) NULL,
	[CertificateNo] [nvarchar](100) NULL,
	[PartName] [nvarchar](50) NULL,
	[ObservedReadings] [float] NULL,
	[Error] [nvarchar](100) NULL,
	[DateOfCalibration] [date] NULL,
	[Next_CalibrationDueOn] [date] NULL,
	[Status] [nvarchar](50) NULL,
	[Remarks] [nvarchar](max) NULL,
	[CheckedBy] [nvarchar](50) NULL,
	[CheckedTS] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
