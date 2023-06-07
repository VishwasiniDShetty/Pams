/****** Object:  Table [dbo].[AndonDefaults]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[AndonDefaults](
	[Parameter] [nvarchar](50) NOT NULL,
	[ValueInText] [nvarchar](50) NOT NULL,
	[ValueInText2] [nvarchar](100) NULL,
	[ValueInInt] [int] NULL,
	[ValueInBool] [int] NULL,
	[TextAlign] [nvarchar](50) NULL,
	[DataFontSize] [nvarchar](50) NULL,
	[LabelFontSize] [nvarchar](50) NULL,
	[User] [nvarchar](100) NULL
) ON [PRIMARY]
