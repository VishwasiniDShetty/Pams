/****** Object:  Table [dbo].[processcapabilitydetails]    Committed by VersionSQL https://www.versionsql.com ******/

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
CREATE TABLE [dbo].[processcapabilitydetails](
	[slno] [bigint] IDENTITY(1,1) NOT NULL,
	[testid] [nvarchar](50) NULL,
	[measuredvalue] [float] NULL,
 CONSTRAINT [PK_processcapabilitydetails] PRIMARY KEY CLUSTERED 
(
	[slno] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[processcapabilitydetails] ADD  CONSTRAINT [DF_processcapabilitydetails_measuredvalue]  DEFAULT ((0)) FOR [measuredvalue]
