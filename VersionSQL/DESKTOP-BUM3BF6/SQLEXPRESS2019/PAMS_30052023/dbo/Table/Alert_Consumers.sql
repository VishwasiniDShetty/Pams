/****** Object:  Table [dbo].[Alert_Consumers]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[Alert_Consumers](
	[SLNo] [bigint] IDENTITY(1,1) NOT NULL,
	[PlantID] [nvarchar](100) NOT NULL,
	[UserID] [nvarchar](500) NOT NULL,
	[Email1] [nvarchar](2000) NULL,
	[Email2] [nvarchar](500) NULL,
	[CountryCode1] [nvarchar](10) NULL,
	[Phone1] [nvarchar](2000) NULL,
	[CountryCode2] [nvarchar](10) NULL,
	[Phone2] [nvarchar](50) NULL,
	[ChatID] [nvarchar](500) NULL,
 CONSTRAINT [PK_Alert_Consumers] PRIMARY KEY CLUSTERED 
(
	[UserID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[Email1] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
