/****** Object:  Table [dbo].[GaugeInformation]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[GaugeInformation](
	[GaugeID] [nvarchar](50) NOT NULL,
	[GaugeSlNo] [nvarchar](20) NOT NULL,
	[GaugeType] [nvarchar](50) NULL,
	[Manufacturer] [nvarchar](50) NULL,
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
	[Units] [nvarchar](50) NULL,
	[TimeStamp] [datetime] NULL
) ON [PRIMARY]
