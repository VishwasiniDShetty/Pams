/****** Object:  Table [dbo].[InspectionTransactionRMLevel_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[InspectionTransactionRMLevel_PAMS](
	[RowID] [bigint] IDENTITY(1,1) NOT NULL,
	[Date] [datetime] NOT NULL,
	[Shift] [nvarchar](50) NULL,
	[Process] [nvarchar](2000) NULL,
	[ReportType] [nvarchar](2000) NULL,
	[ProcessType] [nvarchar](50) NULL,
	[RawMaterial] [nvarchar](50) NULL,
	[SpecialCharacteristic] [nvarchar](100) NULL,
	[CharacteristicCode] [nvarchar](2000) NULL,
	[Specification] [nvarchar](2000) NULL,
	[MeasuringMethod] [nvarchar](max) NULL,
	[RevID] [int] NULL,
	[RevNo] [nvarchar](50) NULL,
	[RevDate] [datetime] NULL,
	[NoOfSamples] [nvarchar](50) NULL,
	[MeasuringInstrument] [nvarchar](max) NULL,
	[MeasuredValue] [nvarchar](50) NULL,
	[ControlType] [nvarchar](50) NULL,
	[ControlValue] [nvarchar](2000) NULL,
	[LSL] [nvarchar](50) NULL,
	[USL] [nvarchar](50) NULL,
	[SortOrder] [int] NULL,
	[BatchID] [int] NULL,
	[BatchValue] [nvarchar](2000) NULL,
	[BatchTS] [datetime] NULL,
	[Status] [nvarchar](500) NULL,
	[Remarks] [nvarchar](2000) NULL,
	[MeasuringInstrumentTran] [nvarchar](max) NULL,
	[GRNNo] [nvarchar](50) NULL,
	[InvoiceNumber] [nvarchar](50) NULL,
	[UpdatedBy_Quality] [nvarchar](50) NULL,
	[UpdatedTs_Quality] [datetime] NULL,
	[UpdatedBy_MR] [nvarchar](50) NULL,
	[UpdatedTs_MR] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-20230311-131654] ON [dbo].[InspectionTransactionRMLevel_PAMS]
(
	[Process] ASC,
	[ReportType] ASC,
	[ProcessType] ASC,
	[RawMaterial] ASC,
	[CharacteristicCode] ASC,
	[RevNo] ASC,
	[BatchID] ASC,
	[GRNNo] ASC,
	[InvoiceNumber] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
