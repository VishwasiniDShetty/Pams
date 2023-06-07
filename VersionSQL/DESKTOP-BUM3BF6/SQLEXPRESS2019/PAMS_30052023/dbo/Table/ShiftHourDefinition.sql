/****** Object:  Table [dbo].[ShiftHourDefinition]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ShiftHourDefinition](
	[ShiftID] [int] NOT NULL,
	[HourName] [nvarchar](50) NULL,
	[HourID] [int] NOT NULL,
	[FromDay] [int] NULL,
	[ToDay] [int] NULL,
	[HourStart] [datetime] NULL,
	[HourEnd] [datetime] NULL,
	[Minutes] [int] NULL,
	[IsEnable] [bit] NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[ShiftHourDefinition] ADD  DEFAULT ((1)) FOR [IsEnable]
