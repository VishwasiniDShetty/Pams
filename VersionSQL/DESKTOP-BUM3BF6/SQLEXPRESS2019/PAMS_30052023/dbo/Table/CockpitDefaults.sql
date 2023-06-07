/****** Object:  Table [dbo].[CockpitDefaults]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[CockpitDefaults](
	[Parameter] [nvarchar](50) NOT NULL,
	[ValueInText] [nvarchar](50) NOT NULL,
	[ValueInText2] [nvarchar](50) NULL,
	[ValueInInt] [int] NULL,
	[ValueInBool] [int] NULL,
	[LanguageSpecified] [nvarchar](50) NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[CockpitDefaults] ADD  CONSTRAINT [DF__CockpitDe__Value__5C229E14]  DEFAULT ((0)) FOR [ValueInBool]
