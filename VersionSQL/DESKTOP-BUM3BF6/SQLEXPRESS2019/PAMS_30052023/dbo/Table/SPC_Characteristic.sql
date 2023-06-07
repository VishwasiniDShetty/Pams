/****** Object:  Table [dbo].[SPC_Characteristic]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[SPC_Characteristic](
	[MachineID] [nvarchar](50) NOT NULL,
	[ComponentID] [nvarchar](50) NOT NULL,
	[OperationNo] [int] NOT NULL,
	[CharacteristicCode] [nvarchar](50) NOT NULL,
	[CharacteristicID] [nvarchar](50) NOT NULL,
	[SpecificationMean] [nvarchar](50) NULL,
	[LSL] [nvarchar](50) NULL,
	[USL] [nvarchar](50) NULL,
	[UOM] [nvarchar](50) NULL,
	[SampleSize] [nvarchar](50) NULL,
	[Interval] [nvarchar](50) NULL,
	[InstrumentType] [nvarchar](50) NULL,
	[InProcessInterval] [nvarchar](50) NULL,
	[InspectionDrawing] [nvarchar](50) NULL,
	[Datatype] [nvarchar](50) NULL,
	[SetupApprovalInterval] [nvarchar](50) NULL,
	[Specification] [nvarchar](50) NULL,
	[MacroLocation] [int] NULL,
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[UpperOperatingZoneLimit ] [float] NULL,
	[LowerOperatingZoneLimit ] [float] NULL,
	[UpperWarningZoneLimit ] [float] NULL,
	[LowerWarningZoneLimit ] [float] NULL,
	[CuUSL] [decimal](18, 4) NULL,
	[CuLSL] [decimal](18, 4) NULL,
	[UTNO] [nvarchar](50) NULL,
	[BLNo] [nvarchar](50) NULL,
	[MPPNo] [nvarchar](50) NULL,
	[Model] [nvarchar](50) NULL,
	[CompInterfaceId] [nvarchar](50) NULL,
	[OpnInterfaceId] [nvarchar](50) NULL,
	[ToolNumber] [nvarchar](50) NULL,
	[InputMethod] [nvarchar](50) NULL,
	[Channel] [nvarchar](50) NULL,
	[WearOffsetNumber] [int] NULL,
	[ChannelID] [nvarchar](50) NULL,
	[IsEnabled] [bit] NULL,
	[InspectedBy] [nvarchar](100) NULL,
	[Product] [nvarchar](50) NULL,
	[VersionNo] [nvarchar](50) NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[SPC_Characteristic] ADD  DEFAULT ((0)) FOR [IsEnabled]
