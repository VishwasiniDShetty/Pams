/****** Object:  Table [dbo].[CountryCodes]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[CountryCodes](
	[Country] [nchar](10) NOT NULL,
	[Code] [nchar](10) NOT NULL,
 CONSTRAINT [PK_CountryCodes] PRIMARY KEY CLUSTERED 
(
	[Country] ASC,
	[Code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
