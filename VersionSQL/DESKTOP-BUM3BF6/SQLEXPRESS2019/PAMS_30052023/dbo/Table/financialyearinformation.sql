/****** Object:  Table [dbo].[financialyearinformation]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[financialyearinformation](
	[financialyear] [nvarchar](50) NOT NULL,
	[datefrom] [smalldatetime] NULL,
	[dateto] [smalldatetime] NULL,
	[target] [float] NULL,
 CONSTRAINT [PK_financialyearinformation] PRIMARY KEY CLUSTERED 
(
	[financialyear] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[financialyearinformation] ADD  CONSTRAINT [DF_financialyearinformation_target]  DEFAULT ((0)) FOR [target]
