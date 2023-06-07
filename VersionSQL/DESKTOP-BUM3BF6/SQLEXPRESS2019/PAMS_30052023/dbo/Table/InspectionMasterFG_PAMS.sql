/****** Object:  Table [dbo].[InspectionMasterFG_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[InspectionMasterFG_PAMS](
	[RowID] [bigint] IDENTITY(1,1) NOT NULL,
	[Process] [nvarchar](2000) NULL,
	[ReportType] [nvarchar](2000) NULL,
	[ProcessType] [nvarchar](50) NULL,
	[ComponentID] [nvarchar](50) NULL,
	[OperationNo] [nvarchar](50) NULL,
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
	[IsMandatory] [bit] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

SET ANSI_PADDING ON

CREATE UNIQUE NONCLUSTERED INDEX [NonClusteredIndex-20230310-104625] ON [dbo].[InspectionMasterFG_PAMS]
(
	[Process] ASC,
	[ReportType] ASC,
	[ProcessType] ASC,
	[ComponentID] ASC,
	[OperationNo] ASC,
	[CharacteristicCode] ASC,
	[RevID] ASC,
	[RevNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
ALTER TABLE [dbo].[InspectionMasterFG_PAMS] ADD  DEFAULT ((0)) FOR [IsMandatory]
