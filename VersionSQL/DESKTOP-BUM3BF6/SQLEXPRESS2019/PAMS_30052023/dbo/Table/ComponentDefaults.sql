/****** Object:  Table [dbo].[ComponentDefaults]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[ComponentDefaults](
	[Mc] [nvarchar](50) NOT NULL,
	[Comp] [nvarchar](50) NOT NULL,
	[Opn] [nvarchar](50) NOT NULL,
	[Opr] [nvarchar](50) NOT NULL,
	[Dimension] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_ComponentDefaults] PRIMARY KEY CLUSTERED 
(
	[Mc] ASC,
	[Comp] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
