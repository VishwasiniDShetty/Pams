/****** Object:  Table [dbo].[BusinessRules]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[BusinessRules](
	[slno] [bigint] IDENTITY(1,1) NOT NULL,
	[RuleAppliesTo] [nvarchar](50) NULL,
	[Resource] [nvarchar](50) NULL,
	[Track] [nvarchar](50) NULL,
	[Condition] [nvarchar](50) NULL,
	[TrackValue] [float] NULL,
	[Message] [nvarchar](max) NULL,
	[email] [int] NULL,
	[EmailID] [nvarchar](50) NULL,
	[mobile] [int] NULL,
	[MobileNo] [nvarchar](110) NULL,
	[MsgPerEvery] [int] NULL,
	[WriteLogFile] [smallint] NULL,
	[AlertUser] [smallint] NULL,
	[ProdIndicator] [smallint] NULL,
	[IndicatorColor] [nvarchar](6) NULL,
	[LampNumber] [int] NULL,
	[MaxTrackValue] [float] NULL,
	[MsgFormat] [nvarchar](100) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
