/****** Object:  Table [dbo].[TroubleShootingGuide]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[TroubleShootingGuide](
	[TSID] [int] NOT NULL,
	[Topic] [nvarchar](300) NOT NULL,
	[ParentID] [int] NULL,
	[HelpText] [nvarchar](50) NULL,
	[ValueInText] [nvarchar](50) NULL,
	[ValueInText1] [nvarchar](50) NULL,
 CONSTRAINT [PK_TroubleShootingGuide] PRIMARY KEY CLUSTERED 
(
	[TSID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
