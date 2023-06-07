/****** Object:  Table [dbo].[IDMGeneralMaster_PAMS]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[IDMGeneralMaster_PAMS](
	[SLNo] [int] NULL,
	[ItemName] [nvarchar](50) NULL,
	[ItemDescription] [nvarchar](500) NULL,
	[Supplier] [nvarchar](50) NULL,
	[UOM] [nvarchar](50) NULL,
	[MinimumOrderQty] [float] NULL,
	[ShelfLife] [nvarchar](50) NULL,
	[AlertRequiredOrNot] [nvarchar](50) NULL,
	[Department] [nvarchar](50) NULL,
	[ItemCategory] [nvarchar](50) NULL,
	[unitrate] [float] NULL,
	[MinimumStockQty] [float] NULL,
	[Location] [nvarchar](50) NULL,
	[LeastCount] [decimal](18, 4) NULL,
	[LSLval] [decimal](18, 4) NULL,
	[USLval] [decimal](18, 4) NULL,
	[GaugeOwner] [nvarchar](50) NULL,
	[PurchaseDate] [datetime] NULL,
	[FirstCalDate] [datetime] NULL,
	[LastCalDate] [datetime] NULL,
	[CalFrequency] [int] NULL,
	[NextCalDue] [datetime] NULL,
	[CalNotes] [nvarchar](100) NULL,
	[ToolType] [nvarchar](500) NULL,
	[MachineType] [nvarchar](500) NULL
) ON [PRIMARY]
